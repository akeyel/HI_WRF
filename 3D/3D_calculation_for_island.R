# Convert from WRF variables to estimate water extraction from clouds by vegetation
# _points is designed to run for specific points
# _island is designed to run for every grid cell for a set of islands (Oahu/kauai or maui/hawaii)

# Created 2023-05-23 based on notes from December 2022

# From attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)

library(ncdf4)
require(SparseM) # for abind function used to combine arrays #Not sure if this is needed before the next line.
require(abind)

input.drive = "D" # "F" for Seagate, D for Elements
output.drive = 'F'
# Note that wind is on output.drive still, so that is hardcoded below right now.
islands = 'ok' # 'hm' # ok
scenario = 'present' # 'rcp45', 'rcp85'
#islands = 'ok'
#year.vec = seq(1999,2003)
#in.dir.bits = c("1999", rep("2000-2001", 2), rep("2002-2003", 2))
#for (m in 1:length(year.vec)){
  #year = year.vec[m]
  year = 1999
  #in.dir.bit = in.dir.bits[m]
  in.dir.bit = '1997-2003'  #'1999'

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
  if (islands == 'ok'){  height.dir = sprintf("%s:/wind_heights/kauai_oahu_%s/%s", output.drive, scenario, year)   } #**# Watch for changes to path, may be _present!
  
  vegetation.lookup = read.csv(sprintf("%s/wrf_tables/VEGPARMTBL_USGS.csv", code.dir))
  roughness.type = "max" # options are 'max', 'min', 'custom'
  
  # Path to netcdf file
  data.files = list.files(data.in.dir)

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
  
  #**# LEFT OFF HERE  
  # What are we pulling out island wide? daily sum? Monthly sum? annual sum?
  #**# Is there a way to just push it into the same daily .rda format and then use the existing scripts on the .RDA data array?
  #**# For now, make a spatial daily aggregate, and let others adjust from there.
  
  #**# Except with the GMT offset, we'll need to pull from two files at once to process each day. Fun times.
  GMT.offset = 10 # Technically minus 10, but this way is easier to code and consistent with what I did previously
  days = 365
  if (year %% 4 == 0){ days = 366 } # Will give the wrong answer for 1900 and 2100

  for (i in 1:days){
    # Place for future directions: Adjust the file format and naming convention so that it comes out in a .rda that can be processed by the other scripts
    final.loc.file = sprintf("%s/CWI_TIF/CWI_%s_%s_%03.f_GMTminus%s.csv", data.dir, islands, year, day, GMT.offset) #**# CHECK ON THIS!!!

    day.part.1 = data.files[i] # Read in the present day, but ignore the first GMT offset number of hours
    day.part.2 = data.files[i + 1]   # Add remaining hours from next day
    #**# Needs special processing for the last day of the year - even though there IS a file for the next year, for the test example of 1999 for Oahu and Kauai Present, it had only a single hour's value, which is not enough.
    day1.start.index = GMT.offset + 1 #**# is it plus 1? Double check this!!!
    day1.count.index = 24 - GMT.offset #**# Is this right? DOUBLE CHECK THIS!!!
    day2.start.index = 1
    day2.count.index = GMT.offset #**# Is there a -1 here to account for the first entry? Except I think that's included in count, so no.
    
    #**# For code efficiency, could adjust the script to have it remember the 2nd half of days, instead of doing two read/writes.

    #**# Add a check that files exist. I think there is an extra little bit into the new year, probably for exactly this problem.
    proceed = TRUE
    #**# CHECK NOT CODED
                
    # Do not attempt to process known missing files
    if (proceed){
      wrf1 = nc_open(day.part.1)
      wrf2 = nc_open(day.part.2)
      # dimensions of qcloud 455 435  50  24
      qcloud1 = ncvar_get(wrf1, "QCLOUD", start = c(1,1, 1, day1.start.index), count = c(-1,-1,1,day1.count.index))
      qcloud2 = ncvar_get(wrf2, "QCLOUD", start = c(1,1, 1, day2.start.index), count = c(-1,-1,1,day2.count.index))
      qcloud = abind::abind(qcloud1, qcloud2) # Checked on 2024-01-03, looks like array joined correctly.
      wrf.dims = dim(qcloud) 
      dim1 = wrf.dims[1]
      dim2 = wrf.dims[2]

      # Convert QCLOUD to needed units
      # QCLOUD: Cloud water mixing ratio kg / kg
      # QVAPOR: Water vapor mixing ratio kg / kg
      # PSFC: SFC Pressure (Pa)
      PSFC1 = ncvar_get(wrf1, "PSFC", start = c(1, 1, day1.start.index), count = c(-1,-1,day1.count.index))
      PSFC2 = ncvar_get(wrf2, "PSFC", start = c(1, 1, day2.start.index), count = c(-1,-1,day2.count.index))
      PSFC = abind::abind(PSFC1, PSFC2)
      
      T2.1 = ncvar_get(wrf1, "T2", start = c(1, 1, day1.start.index), count = c(-1,-1,day1.count.index))
      T2.2 =  ncvar_get(wrf2, "T2", start = c(1, 1, day2.start.index), count = c(-1,-1,day2.count.index))
      T2 = abind::abind(T2.1, T2.2)
      R = 287 # J / (kg * K)
      rho_air = PSFC / (R * T2)
        
      # LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
      liquid.cloud.water = rho_air * qcloud * 1000 # 1000 converts from kg to g
      #**# OK. How do we output these data? # netCDF might be the way to go here???
      
      ### CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)
      #rho_water = density of water (g/cm3)
      rho_water = 0.997045 # using this calculator at 25 C https://www.axeleratio.com/calc/water_density/form/Kell_equation.htm

      # IVGTYP gives dominant vegetation category
      vegetation.category = ncvar_get(wrf1, "IVGTYP", start = c(1,1, 1), count = c(-1,-1,1)) # 24 works for the 3rd dimension, but I'm assuming this does not change within a day? Does it change across seasons?

      #veg.vec = get.canopy.height(vegetation.category, vegetation.lookup)
      #start.time = Sys.time()
      canopy.height = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'height') #**# Is this efficient??? Watch for code inefficiencies here.
      #elapsed = Sys.time() - start.time # 6 seconds, for 365 days * 3 scenarios * 20 years * 2 island tiles = 43800 seconds just from this step. So 12 hours right here. Ouch.

      if (roughness.type == "max"){ 
        roughness = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'max') #**# Ditto on efficiency - this could be limiting.
      }
      if (roughness.type == 'min'){
        roughness = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'min') #**# Ditto on efficiency - this could be limiting.
      }
      if (roughness.type == "custom"){ roughness = 0.1 * canopy.height }
      if (!exists('roughness')){ stop("Something went wrong during roughness assignment")}
        
        # Calculate wind speed by downscaling from higher levels
        stuff =get.wind.speed.for.island(canopy.height, roughness, wrf, height.dir, data.files[i], dim1_index, dim2_index)
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

    # Write to file
    write.csv(out.locs, file = final.loc.file, row.names = FALSE)  
  }
#}

if (length(missing.vec) > 0){
  message(paste(missing.vec, collapse = ' '))
  #stop("one or or more data files do not have wind heights calculated. Please run Python script Extract_wind_level_height.py to calculate the 1st and 2nd layer wind heights")
}

