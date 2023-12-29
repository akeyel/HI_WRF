# Convert from WRF variables to estimate water extraction from clouds by vegetation

# V3 is adjusted to run for 16 TB hard drive data

# Created 2023-05-23 based on notes from December 2022

# From attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)


library(ncdf4)

input.drive = "F" # "F" for Seagate, D for Elements
output.drive = 'D'
# Note that wind is on output.drive still, so that is hardcoded below right now.
year = 1999
islands = 'hm' 
scenario = 'present'
#islands = 'ok'
#year.vec = seq(1999,2003)
#in.dir.bits = c("1999", rep("2000-2001", 2), rep("2002-2003", 2))
#for (m in 1:length(year.vec)){
  #year = year.vec[m]
  #in.dir.bit = in.dir.bits[m]
  in.dir.bit = '1999'

  # Read in 3D example file
  #data.dir = "C:/docs/hawaii_local/3D_Files"
  if (islands == 'hm'){  data.in.dir = sprintf("%s:/hawaii_800m_%s_%s/%s", input.drive, scenario, in.dir.bit, year)  }
  if (islands == 'ok'){  data.in.dir = sprintf("%s:/kauai_oahu_800m_%s_%s/%s", input.drive, scenario, in.dir.bit, year)  }
  
  data.dir = sprintf("%s:/hawaii_local", output.drive)
  setwd(data.in.dir)
  
  #code.dir = "C:/docs/science/HI_WRF"
  code.dir = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF"
  source(sprintf("%s/01_Workflow_hlpr.R", code.dir))
  if (islands == 'hm'){  height.dir = sprintf("%s:/wind_heights/hawaii_present/%s", output.drive, year)  }
  if (islands == 'ok'){  height.dir = sprintf("%s:/wind_heights/kauai_oahu/%s", output.drive, year)   } #**# Watch for changes to path, may be _present!
  
  
  vegetation.lookup = read.csv(sprintf("%s/3D/VEGPARMTBL_USGS.csv", code.dir))
  roughness.type = "max" # options are 'max', 'min', 'custom'
  
  # Path to netcdf file
  data.files = list.files(data.in.dir)

  #**# LEFT OFF HERE  
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
    final.loc.file = sprintf("%s/CWI_HAN/CWI_estimates_%s_%s_%s.csv", data.dir, islands, year, chunk.label)
    
    count = 0
    for (i in start.day:end.day){
      # Do not attempt to process known missing files
      if (!data.files[i] %in% missing.vec){
        count = count + 1
        wrf = nc_open(data.files[i])
        # dimensions of qcloud 455 435  50  24
        qcloud = ncvar_get(wrf, "QCLOUD", start = c(1,1, 1, 1), count = c(-1,-1,1,24))
        wrf.dims = dim(qcloud) # Arbitrarily pick one to get size of file
        dim1 = wrf.dims[1]
        dim2 = wrf.dims[2]

        # Convert QCLOUD to needed units
        # QCLOUD: Cloud water mixing ratio kg / kg
        # QVAPOR: Water vapor mixing ratio kg / kg
        # PSFC: SFC Pressure (Pa)
        PSFC = ncvar_get(wrf, "PSFC", start = c(1, 1, 1), count = c(-1,-1,24))
        T2 = ncvar_get(wrf, "T2", start = c(1, 1, 1), count = c(-1,-1,24))
        R = 287 # J / (kg * K)
        rho_air = PSFC / (R * T2)
          
        # LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
        liquid.cloud.water = rho_air * qcloud * 1000 # 1000 converts from kg to g
        #**# OK. How do we output these data? # netCDF might be the way to go here???
        
        ### CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)
        #rho_water = density of water (g/cm3)
        rho_water = 0.997045 # using this calculator at 25 C https://www.axeleratio.com/calc/water_density/form/Kell_equation.htm

        # IVGTYP gives dominant vegetation category
        vegetation.category = ncvar_get(wrf, "IVGTYP", start = c(1,1, 1), count = c(-1,-1,1)) # 24 works for the 3rd dimension, but I'm assuming this does not change within a day? Does it change across seasons?

        #veg.vec = get.canopy.height(vegetation.category, vegetation.lookup)
        #start.time = Sys.time()
        canopy.height = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'height') #**# Is this efficient??? Watch for code inefficiencies here.
        #elapsed = Sys.time() - start.time # 6 seconds, for 365 days * 3 scenarios * 20 years * 2 island tiles = 43800 seconds just from this step. So 12 hours right here. Ouch.
        #**# NEED TO FIX DIMENSIONS; LEFT OFF HERE - NEED TO GET NEXT BATCH RUNNING FOR CWI (?Do I? Is there actually a value to running more before we know what we're doing? Not really a harm to it)
        
          
        if (roughness.type == "max"){ 
          roughness = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'max') #**# Ditto on efficiency - this could be limiting.
        }
        if (roughness.type == 'min'){
          roughness = sapply(vegetation.category, get.veg.parameter, vegetation.lookup, 'min') #**# Ditto on efficiency - this could be limiting.
        }
        if (roughness.type == "custom"){ roughness = 0.1 * canopy.height }
        if (!exists('roughness')){ stop("Something went wrong during roughness assignment")}
          
          # Calculate wind speed by downscaling from higher levels
          stuff =get.wind.speed.v2(canopy.height, wrf, height.dir, data.files[i], dim1_index, dim2_index)
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

