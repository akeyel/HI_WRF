# Convert from WRF variables to estimate water extraction from clouds by vegetation
# _points is designed to run for specific points
# _island is designed to run for every grid cell for a set of islands (Oahu/kauai or maui/hawaii)
#      Note: This version was never completely finished, and requires some additional coding.
# _island_many_nc_files is designed to run from individual netcdf files for individual variables extracted to a single hard drive

# Created 2023-05-23 based on notes from December 2022
# Adjusted to run on a subset of variables placed on a single hard drive.
# May be slower, due to a greater number of file read/writes

# From attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)

library(ncdf4)
require(SparseM) # for abind function used to combine arrays #Not sure if this is needed before the next line.
require(abind)

warning("The dimensions are different for U and V. This may be a problem for the extract to points,
        as the wrong U/V values may be combined! THIS MAY REQUIRE MORE CAREFUL EXTRACTION.
        For now, I just dropped the left-most or lower-most row, instead of interpolating between points" )


input.drive = "F" 
output.drive = 'F' # For this version, processing takes place on a single drive.
# Note that wind is on output.drive still, so that is hardcoded below right now.
GMT.offset = 10 # Technically minus 10, but this way is easier to code and consistent with what I did previously
islands = 'hm' # ok' # 'hm' # ok
island = 'hawaii' #**# Should this be hm? May want to rename the files when running the script.
scenario = 'present' # 'rcp45', 'rcp85'
#year.vec = seq(1999,2003)
#in.dir.bits = c("1999", rep("2000-2001", 2), rep("2002-2003", 2))
for (m in 1:length(year.vec)){
  year = year.vec[m]
  #year = 2000
  #in.dir.bit = in.dir.bits[m]

  # Read in 3D example file
  data.in.dir = sprintf("%s:/hawaii_local/hourly_vars/%s_%s/%s", input.drive, island, scenario, year)
  #data.dir = sprintf("%s:/hawaii_local/hourly_vars/%s_%s/%s/CW", output.drive) # data.in.dir should also work for data.dir
  setwd(data.in.dir)
  
  code.dir = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF"
  source(sprintf("%s/01_Workflow_hlpr.R", code.dir))
  if (islands == 'hm'){  height.dir = sprintf("%s:/wind_heights/hawaii_%s/%s", output.drive, scenario, year)  }
  if (islands == 'ok'){  height.dir = sprintf("%s:/wind_heights/kauai_oahu_%s/%s", output.drive, scenario, year)   } #**# Watch for changes to path, may be _present!
  
  vegetation.lookup = read.csv(sprintf("%s/wrf_tables/VEGPARMTBL_USGS.csv", code.dir))
  roughness.type = "max" # options are 'max', 'min', 'custom'
  
  # Use QCLOUD variable to identify files to run for this year
  data.files = list.files(sprintf("%s/QCLOUD", data.in.dir))
  missing.vec = check.for.missing.files(data.files, data.in.dir, height.dir)
  #**# With the current configuration, if files are out of order or missing from just one folder, things will get corrupted.
  #Should pull out day from the file name and then check it against subsequent file names!
  
  warning("Special processing needed for last day of year")
  #days = 365
  #if (year %% 4 == 0){ days = 366 } # Will give the wrong answer for 1900 and 2100

  for (i in 1:length(data.files)){
    
    # Need special processing for roll-over for last day of year (or just copy the first file of the next year into the same folder!)
    
    # Place for future directions: Adjust the file format and naming convention so that it comes out in a .rda that can be processed by the other scripts
    day = strsplit(strsplit(data.files[i], "_")[[1]][3], '-')[[1]][3] # Pull day from file name, because i may not match days if days are missing.
    cwi.path = sprintf("%s/CWI", data.in.dir)
    if (!file.exists(cwi.path)) dir.create(cwi.path)
    final.loc.file = sprintf("%s/CWI_%s_%s_%03.f_GMTminus%s.csv", cwi.path, islands, year, as.numeric(day), GMT.offset) #**# CHECK ON THIS!!!

    qcloud = read.this.var(data.in.dir, "QCLOUD", i, GMT.offset) 

    # Convert QCLOUD to needed units
    # QCLOUD: Cloud water mixing ratio kg / kg
    # QVAPOR: Water vapor mixing ratio kg / kg
    # PSFC: SFC Pressure (Pa)
    PSFC = read.this.var(data.in.dir, "PSFC", i, GMT.offset)

    T2 = read.this.var(data.in.dir, "T2", i, GMT.offset)
    R = 287 # J / (kg * K)
    rho_air = PSFC / (R * T2)
        
    # LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
    liquid.cloud.water = rho_air * qcloud * 1000 # 1000 converts from kg to g

    ### CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)
    #rho_water = density of water (g/cm3)
    rho_water = 0.997045 # using this calculator at 25 C https://www.axeleratio.com/calc/water_density/form/Kell_equation.htm

    # IVGTYP gives dominant vegetation category
    vegetation.category = read.this.var(data.in.dir, 'IVGTYP', i, GMT.offset)
    vegetation.category = vegetation.category[,,1] # I'm assuming this does not change within a day, and I don't think it changes across seasons, so could potentially just be read in once in the future.

    # Target for code optimization - this is a slow step
    start.time = Sys.time()
    canopy.height = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'height') 
    elapsed = Sys.time() - start.time # 6 seconds, for 365 days * 3 scenarios * 20 years * 2 island tiles = 43800 seconds just from this step. So 12 hours right here. Ouch.

    # Target for code optimization - this is also a slow step
    if (roughness.type == "max"){ 
      roughness = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'max') #**# Ditto on efficiency - this could be limiting.
    }
    if (roughness.type == 'min'){
      roughness = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'min') #**# Ditto on efficiency - this could be limiting.
    }
    if (roughness.type == "custom"){ roughness = 0.1 * canopy.height }
    if (!exists('roughness')){ stop("Something went wrong during roughness assignment")}
        
    # Calculate wind speed by downscaling from higher levels
    stuff =get.wind.speed.for.island(canopy.height, roughness, i, height.dir, data.files[i])
    wind.speed = stuff[[1]]
    wind.height = stuff[[2]]

    # CWF: cloud water flux: amount of cloud/fog water supplied by the atmosphere; proportional to windspeed * liquid water content; horizontal depth or flux (mm/hr)
    # U*p_air*qc in Katata et al. 2011 but different units
    cloud.water.flux = liquid.cloud.water * rho_water * wind.speed * 3.6 #**# Check if it is x rho_water or / rho_water

    ## Calculate A
    # A canopy interception efficiency
    # slope of Vd that depend on vegetation characteristics in Katata et al. 2008
    # dimensionless, ratio of CWF converted to CWI; depends on characteristics of vegetation canopy
    # Katata et al. 2011 A = 0.0164 * (LAD)**-0.5, LAD = LAI/canopy height
    # bottom_top variable may give heights of different layers - should look at this one!
    # Land surface model documentation should describe this
    # LAI changes hourly in the WRF model
    LAI = read.this.var(data.in.dir, 'LAI', i, GMT.offset)

    LAD = LAI / canopy.height
    A = 0.0164 * (LAD)**(-0.5)
        
    # CWI = cloud water content; amount of cloud/fog water caught by vegetation, measured as vertical depth or flux mm/hr; = Fqc in Katata et al. 2011 equation, but there kg/m2s
    #CWI(mm/time) = A*CWF(mm/time)
    cloud.water.content = A * cloud.water.flux

    # Convert based on fraction of cell that is vegetated?
    #shdmax = ncvar_get(wrf, "SHDMAX", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    #shdmin = ncvar_get(wrf, "SHDMIN", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    #vegfra = ncvar_get(wrf, "VEGFRA", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
    #loc.df$vegetation.fraction[j] = mean(vegfra) #**# Not currently used in calculation
    #loc.df$vegetation.fraction[s.index:e.index] = vegfra
    
    # NEED TO OUTPUT STUFF
    stop("NEED TO OUTPUT CALCULATED DAY AND ANY DESIRED INTERMEDIATES!!!")
  }
    
}


