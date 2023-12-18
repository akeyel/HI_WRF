# Convert from WRF variables to estimate water extraction from clouds by vegetation

# V3 is adjusted to run for 16 TB hard drive data

# Created 2023-05-23 based on notes from December 2022

# From attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)


library(ncdf4)

#**# Need to adjust script to be more flexible for time
year = 2004
islands = 'hm' 

if (year == 2004){ in.dir.bit = "2004-2005" } # Likely move this to a lookup function to reduce clutter
#if (islands == 'hm'){ island.bit = 'hawaii_800m'} #**# check if this differs among runs

# Read in 3D example file
#data.dir = "C:/docs/hawaii_local/3D_Files"
data.in.dir = sprintf("F:/hawaii_800m_present_%s/%s", in.dir.bit, year)
data.dir = "F:/hawaii_local"
setwd(data.in.dir)

#code.dir = "C:/docs/science/HI_WRF"
code.dir = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF"
source(sprintf("%s/01_Workflow_hlpr.R", code.dir))
if (islands == 'hm'){
  height.dir = sprintf("F:/wind_heights/hawaii_maui/%s", year)
}


vegetation.lookup = read.csv(sprintf("%s/3D/VEGPARMTBL_USGS.csv", code.dir))
roughness.type = "max" # options are 'max', 'min', 'custom'

# Path to netcdf file
data.files = list.files(data.in.dir)

# Get fixed locations from Han for test evaluation
loc.df.file = sprintf("%s/CWI_HAN/hanslocations_%s.csv", data.dir, islands)
if (!file.exists(loc.df.file)){
  grid.path = sprintf("%s/grids/wrf_grids", code.dir) # Put in the github, so it only has to be made once for anyone
  wrf = nc_open(data.files[1]) # use first data file to create the grid. They should all be the same within an island group
  make.loc.df(loc.df.file, islands, grid.path, wrf)
  nc_close(wrf)
}

final.loc.file = sprintf("%s/CWI_HAN/CWI_estimates_%s_%s.csv", data.dir, islands, year)
  
# Check that heights are available for each data file
missing.vec = c()
for (i in 1:length(data.files)){
  if (!file.exists(sprintf("%s/%s_wind_heights.nc", height.dir, data.files[i]))){
    missing.vec = c(missing.vec, data.files[i])
  }
}
if (length(missing.vec) > 0){
  message(paste(missing.vec, collapse = ' '))
  stop("one or or more data files do not have wind heights calculated. Please run Python script XXXX to calculate the 1st and 2nd layer wind heights")
  #**# Add reference to the correct Python script for calculating wind heights
}

for (i in 1:length(data.files)){
  wrf = nc_open(data.files[i])
  # Create an empty data frame with the locations setup with indices
  loc.df = read.csv(loc.df.file)
  # Pull out just the needed values
  loc.df$island = islands
  loc.df$date = substr(data.files[i], 12,21) #**# check that this is right (it probably isn't!)
  loc.df$lcw = NA
  loc.df$cwf = NA
  loc.df$cwi = NA
  for (j in 1:nrow(loc.df)){
    dim1_index = loc.df$dim1_index[j]
    dim2_index = loc.df$dim2_index[j]
    # dimensions of qcloud 455 435  50  24
    # just get the selected data point for all time points for the selected location
    
    # Convert QCLOUD to needed units
    # QCLOUD: Cloud water mixing ratio kg / kg
    # QVAPOR: Water vapor mixing ratio kg / kg
    # PSFC: SFC Pressure (Pa)
    qcloud = ncvar_get(wrf, "QCLOUD", start = c(dim1_index,dim2_index, 1, 1), count = c(1,1,1,24))
    PSFC = ncvar_get(wrf, "PSFC", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    T2 = ncvar_get(wrf, "T2", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    R = 287 # J / (kg * K)
    rho_air = PSFC / (R * T2) # and rho_air is QCLOUD?
    
    liquid.cloud.water = rho_air * qcloud * 1000 # 1000 converts from kg to g
    
    # LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
    lcw = mean(liquid.cloud.water) 
    loc.df$lcw[i] = lcw
    #test = ncvar_get(wrf, "QCLOUD", start = c(1,1,1,10), count = c(dim1, dim2, 1,1))
    #max(test) = 0.0008700828 Is this plausible? Recall, our test date is early January.
    
    ### CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)
    #rho_water = density of water (g/cm3)
    rho_water = 0.997045 # using this calculator at 25 C https://www.axeleratio.com/calc/water_density/form/Kell_equation.htm
    #if (i == 1){
    #  warning("Should adjust rho_water calculation to be calculated as a function of temperature and pressure") # Oliver said OK to just use a single value - differences are slight
    #} #**# Said this isn't necessary
  
    # HGT gives terrain height. How do we get vegetation height?
    # IVGTYP gives dominant vegetation category - does this determine vegetation height?
    # VEGFRA gives vegetation fraction - is this relevant?
    # See 99_Patches.R script to get a list of numeric vegetation classes Get.Veg.Types
    vegetation.category = ncvar_get(wrf, "IVGTYP", start = c(dim1_index,dim2_index, 1), count = c(1,1,1)) # 24 works for the 3rd dimension, but I'm assuming this does not change within a day? Does it change across seasons?
    veg.vec = get.canopy.height(vegetation.category, vegetation.lookup)
    canopy.height = veg.vec[1]
    max.roughness = veg.vec[2]
    min.roughness = veg.vec[3] # Not sure what to do with this! How do we get the seasonal dependence?
    
    roughness = NA
    if (roughness.type == "max"){ roughness = max.roughness }
    if (roughness.type == "min"){ roughness = min.roughness }
    if (roughness.type == "custom"){ roughness = 0.1 * canopy.height }
    #roughness = 0.1 * canopy.height # Per Han's email
    #0.75 #**# Wikipedia said brush/forest was often in the range of 0.5 - 1.0 m, I assumed vegetation was brush/forest.
    if (is.na(roughness)){ stop("Something went wrong during roughness assignment")}

    #**# LEFT OFF HERE - NEED TO EDIT LOOP TO ADD IN HEIGHTS
    wind.speed = get.wind.speed(STUFF)
    
    # CWF: cloud water flux: amount of cloud/fog water supplied by the atmosphere; proportional to windspeed * liquid water content; horizontal depth or flux (mm/hr)
    # U*p_air*qc in Katata et al. 2011 but different units
    cloud.water.flux = liquid.cloud.water * rho_water * wind.speed * 3.6 #**# Check if it is x rho_water or / rho_water
    cwf = mean(cloud.water.flux)
    #CWF = (LWC / rho_water) * WS * 3.6
    loc.df$cwf = cwf
    
    ## Calculate A
    # A canopy interception efficiency
    # slope of Vd that depend on vegetation characteristics in Katata et al. 2008
    # dimensionless, ratio of CWF converted to CWI; depends on characteristics of vegetation canopy
    # Katata et al. 2011 A = 0.0164 * (LAD)**-0.5, LAD = LAI/canopy height
    # bottom_top variable may give heights of different layers - should look at this one!
    # Land surface model documentation should describe this
    LAI = ncvar_get(wrf, "LAI", start = c(dim1_index,dim2_index, 1), count = c(1,1,24)) # LAI is in the 3D data set
    #**# Does LAI change hourly??? - yes - first value is different than 2nd value!!!
    
    LAD = LAI / canopy.height
    A = 0.0164 * (LAD)**(-0.5)
    
    # CWI = cloud water content; amount of cloud/fog water caught by vegetation, measured as vertical depth or flux mm/hr; = Fqc in Katata et al. 2011 equation, but there kg/m2s
    #CWI(mm/time) = A*CWF(mm/time)
    cloud.water.content = A * cloud.water.flux
    cwi = sum(cloud.water.content)
    # Convert to daily cloud water caught by vegetation
    loc.df$cwi = cwi
    
    # Convert based on fraction of cell that is vegetated?
    shdmax = ncvar_get(wrf, "SHDMAX", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    shdmin = ncvar_get(wrf, "SHDMIN", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    vegfra = ncvar_get(wrf, "VEGFRA", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
  }
  
  # Do we want these as individual csvs or as a larger csv?
  if (i == 1){
    out.locs = loc.df
  }else{
    out.locs = rbind(out.locs, loc.df)
  }
}

# Write to file #**# probably one per year?
write.csv(out.locs, file = final.loc.file, row.names = FALSE)  



