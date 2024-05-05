# Convert from WRF variables to estimate water extraction from clouds by vegetation

# V3 is adjusted to run for 16 TB hard drive data

# Created 2023-05-23 based on notes from December 2022

# From attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)


library(ncdf4)

#**# Need to adjust script to be more flexible for time
input.drive = "D" # "F" for Seagate, D for Elements
output.drive = 'F'
wind.drive = output.drive # Location of wind heights may on a different hard drive
#year = 2005
islands = 'hm' 
#islands = 'ok'
year.vec = seq(1999,2003)
in.dir.bits = c("1999", rep("2000-2001", 2), rep("2002-2003", 2))
for (m in 1:length(year.vec)){
  year = year.vec[m]
  in.dir.bit = in.dir.bits[m]
  #if ((year == 2004 | year == 2005) & islands == 'hm'){ in.dir.bit = "2004-2005" } # Likely move this to a lookup function to reduce clutter
  #if ((year >= 2004 & year <=2009) & islands == 'ok'){ in.dir.bit = '2004-2009' }
  #if ((year == 2006 | year == 2007) & islands == 'hm'){ in.dir.bit = "2006-2007" }
  #if (islands == 'hm'){ island.bit = 'hawaii_800m'} #**# check if this differs among runs
  
  # Read in 3D example file
  #data.dir = "C:/docs/hawaii_local/3D_Files"
  if (islands == 'hm'){  data.in.dir = sprintf("%s:/hawaii_800m_%s_%s/%s", input.drive, scenario, in.dir.bit, year)  }
  if (islands == 'ok'){  data.in.dir = sprintf("%s:/kauai_oahu_800m_%s_%s/%s", input.drive, scenario, in.dir.bit, year)  }
  
  data.dir = sprintf("%s:/hawaii_local", output.drive)
  setwd(data.in.dir)
  
  #code.dir = "C:/docs/science/HI_WRF"
  code.dir = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF"
  source(sprintf("%s/01_Workflow_hlpr.R", code.dir))
  if (islands == 'hm'){  height.dir = sprintf("%s:/wind_heights/hawaii_%s/%s", output.drive, scenario, year)  }
  if (islands == 'ok'){  height.dir = sprintf("%s:/wind_heights/kauai_oahu_%s/%s", output.drive, scenario, year)   }
  
  
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
  
    
  # Check that heights are available for each data file
  missing.vec = c()
  for (i in 1:length(data.files)){
    if (!file.exists(sprintf("%s/%s_wind_heights.nc", height.dir, data.files[i]))){
      missing.vec = c(missing.vec, data.files[i])
    }
  }
  if (length(missing.vec) > 0){
    message(paste(missing.vec, collapse = ' '))
    stop("one or or more data files do not have wind heights calculated. Please run Python script Extract_wind_level_height.py to calculate the 1st and 2nd layer wind heights")
  }
  start.days = c(1,91,182, 274)
  end.days = c(90, 181, 273, 365)
  # If it is a leap year, adjust the start/end days for the quarter
  if (year %% 4 == 0){
    start.days = c(1,92,183,275)
    end.days = c(91, 182, 274, 366)
  }
  chunk.labels = c("Q1", "Q2", "Q3", "Q4")
  
  
  for (k in 1:length(start.days)){
    start.day = start.days[k]
    end.day = end.days[k]
    chunk.label = chunk.labels[k]
    final.loc.file = sprintf("%s/CWI_HAN/%s/CWI_estimates_%s_%s_%s_%s.csv", data.dir, islands, islands,
                             scenario, year, chunk.label)
    
    count = 0
    for (i in start.day:end.day){
      # Do not attempt to process known missing files
      if (!data.files[i] %in% missing.vec){
        count = count + 1
        wrf = nc_open(data.files[i])
        # Create an empty data frame with the locations setup with indices
        loc.df.base = read.csv(loc.df.file)
        # Pull out just the needed values
        loc.df.base$island = islands
        loc.df.base$date = substr(data.files[i], 12,21)
        df.rows = nrow(loc.df.base) # Get number of rows
        loc.df.base$sort.order = seq(1,df.rows) # Get an index for sorting by site, then by time
        # Expand out so that there is an entry for every day
        loc.df = loc.df.base
        for (k in 1:23){
          loc.df = rbind(loc.df, loc.df.base)
        }
        loc.df = loc.df[order(loc.df$sort.order), ] # Put all site entries together
        loc.df$hour = rep(seq(1,24), df.rows)
        #loc.df$mean.wind = NA
        loc.df$level2.wind = NA
        loc.df$level2.height = NA
        loc.df$level1.wind = NA
        loc.df$level1.height = NA
        loc.df$wind10m = NA
        loc.df$canopy.estimated.wind.speed = NA
        loc.df$canopy.height = NA
        loc.df$LAI = NA
        #loc.df$N.Fog.Hours = NA
        loc.df$lcw = NA
        #loc.df$lcw.fog.only = NA
        loc.df$cwf = NA
        #loc.df$cwf.fog.hours = NA
        #loc.df$cwf.fog.only = NA
        loc.df$cwi = NA
        #loc.df$cwi.fog.only.lcw.def = NA
        #loc.df$cwi.fog.only.cwf.def = NA
        #for (j in 1:nrow(loc.df)){
        for (j in 1:df.rows){
          dim1_index = loc.df.base$dim1_index[j]
          dim2_index = loc.df.base$dim2_index[j]
          
          s.index = 24* (j - 1) + 1
          e.index = 24 * j
          
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
          lcw.threshold = 0.05 #**# 0.05 is from: https://en.wikipedia.org/wiki/Liquid_water_content
          #lcw.foggy = liquid.cloud.water[liquid.cloud.water > lcw.threshold] 
          #lcw.no.fog = liquid.cloud.water[liquid.cloud.water <= lcw.threshold]
          #n.foggy = length(lcw.foggy)
          #lcw.fog.mean = mean(lcw.foggy)
          #lcw.nonfog.mean = mean(lcw.no.fog)
          #loc.df$N.Fog.Hours[j] = n.foggy
          #loc.df$lcw.fog.only[j] = lcw.fog.mean
          
          # LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
          #lcw = mean(liquid.cloud.water) 
          #loc.df$lcw[j] = lcw
          loc.df$lcw[s.index:e.index] = liquid.cloud.water
          
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
          loc.df$canopy.height[s.index:e.index] = canopy.height #**# This is useful in the short term, but should be extracted differently, because it will be the same for the location across days/years
          max.roughness = veg.vec[2]
          min.roughness = veg.vec[3] # Not sure what to do with this! How do we get the seasonal dependence?
          
          roughness = NA
          if (roughness.type == "max"){ roughness = max.roughness }
          if (roughness.type == "min"){ roughness = min.roughness }
          if (roughness.type == "custom"){ roughness = 0.1 * canopy.height }
          #roughness = 0.1 * canopy.height # Per Han's email
          #0.75 #**# Wikipedia said brush/forest was often in the range of 0.5 - 1.0 m, I assumed vegetation was brush/forest.
          if (is.na(roughness)){ stop("Something went wrong during roughness assignment")}
          
          # Calculate wind speed by downscaling from higher levels
          stuff =get.wind.speed.v2(canopy.height, roughness, wrf, height.dir, data.files[i], dim1_index, dim2_index)
          wind.speed = stuff[[1]]
          level2.wind = stuff[[2]]
          level1.wind = stuff[[3]]
          wind.10m = stuff[[4]]
          level2.height = stuff[[5]]
          level1.height = stuff[[6]]
          #if (i == 1 & j == 1){
          #  warning("wind speeds using this downscaling method appear to be biased low. On one test day, by almost 50% on average")
          #  #**# But this is mostly a linear part of the equation, so we could potentially add a bias correction later?      
          #}
          #loc.df$mean.wind = mean(wind.speed)
          #**# need ALL the wind speeds now.
          loc.df$level2.wind[s.index:e.index] = level2.wind
          loc.df$level2.height[s.index:e.index] = level2.height
          loc.df$level1.wind[s.index:e.index] = level1.wind
          loc.df$level1.height[s.index:e.index] = level1.height
          loc.df$wind10m[s.index:e.index] = wind.10m
          loc.df$canopy.estimated.wind.speed[s.index:e.index] = wind.speed
          
          # CWF: cloud water flux: amount of cloud/fog water supplied by the atmosphere; proportional to windspeed * liquid water content; horizontal depth or flux (mm/hr)
          # U*p_air*qc in Katata et al. 2011 but different units
          cloud.water.flux = liquid.cloud.water * rho_water * wind.speed * 3.6 #**# Check if it is x rho_water or / rho_water
          #cwf = mean(cloud.water.flux)
          #CWF = (LWC / rho_water) * WS * 3.6
          #loc.df$cwf[j] = cwf
          loc.df$cwf[s.index:e.index] = cloud.water.flux
          #cwf.threshold = 0.01
          #cwf.foggy = cloud.water.flux[cloud.water.flux > cwf.threshold] # mm
          #cwf.fog.hours = length(cwf.foggy)
          #loc.df$cwf.fog.only[j] = mean(cwf.foggy)
          #loc.df$cwf.fog.hours[j] = cwf.fog.hours
          
          ## Calculate A
          # A canopy interception efficiency
          # slope of Vd that depend on vegetation characteristics in Katata et al. 2008
          # dimensionless, ratio of CWF converted to CWI; depends on characteristics of vegetation canopy
          # Katata et al. 2011 A = 0.0164 * (LAD)**-0.5, LAD = LAI/canopy height
          # bottom_top variable may give heights of different layers - should look at this one!
          # Land surface model documentation should describe this
          LAI = ncvar_get(wrf, "LAI", start = c(dim1_index,dim2_index, 1), count = c(1,1,24)) # LAI is in the 3D data set
          #loc.df$LAI[j] = mean(LAI)
          loc.df$LAI[s.index:e.index] = LAI
          #**# Does LAI change hourly??? - yes - first value is different than 2nd value!!!
          #**# but looks like the rest are all the same???
          
          LAD = LAI / canopy.height
          A = 0.0164 * (LAD)**(-0.5)
          
          # CWI = cloud water content; amount of cloud/fog water caught by vegetation, measured as vertical depth or flux mm/hr; = Fqc in Katata et al. 2011 equation, but there kg/m2s
          #CWI(mm/time) = A*CWF(mm/time)
          cloud.water.content = A * cloud.water.flux
          #cwi = sum(cloud.water.content)
          #cwi.fog.only.lcw.def = sum(cloud.water.content[liquid.cloud.water > lcw.threshold])
          #cwi.fog.only.cwf.def = sum(cloud.water.content[cloud.water.flux > cwf.threshold])
          # Convert to daily cloud water caught by vegetation
          #loc.df$cwi[j] = cwi
          #loc.df$cwi.fog.only.lcw.def[j] = cwi.fog.only.lcw.def
          #loc.df$cwi.fog.only.cwf.def[j] = cwi.fog.only.cwf.def
          
          loc.df$cwi[s.index:e.index] = cloud.water.content
          
          # Convert based on fraction of cell that is vegetated?
          shdmax = ncvar_get(wrf, "SHDMAX", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
          shdmin = ncvar_get(wrf, "SHDMIN", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
          vegfra = ncvar_get(wrf, "VEGFRA", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
          #loc.df$vegetation.fraction[j] = mean(vegfra) #**# Not currently used in calculation
          loc.df$vegetation.fraction[s.index:e.index] = vegfra
        }
        # Close the open wrf file
        nc_close(wrf)
      }
      
      # Do we want these as individual csvs or as a larger csv?
      if (count == 1){
        out.locs = loc.df
      }else{
        out.locs = rbind(out.locs, loc.df)
      }
    }
    
    # Write to file
    write.csv(out.locs, file = final.loc.file, row.names = FALSE)  
  }
}

if (length(missing.vec) > 0){
  message(paste(missing.vec, collapse = ' '))
  #stop("one or or more data files do not have wind heights calculated. Please run Python script Extract_wind_level_height.py to calculate the 1st and 2nd layer wind heights")
}

