# Assorted patches to bring data structure in line with code changes that occurred after processing

#' Wind speed and LAI plot based on a year's data to share with Tom and Han
#' 
#' V2 got coopted to just be January. This one is going back to being all of 2004 (assuming no more bugs!)
#' 
Wind.Speed.Plot3 = function(){
  require(lubridate)
  #Q1 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q1.csv")
  #Q2 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q2.csv")
  #Q3 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q3.csv")
  #Q4 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q4.csv")
  Y2004 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q4.csv") #**# BUG! Accidentally turned off the part where the file reset.
  #Y2004 = rbind(Q1,Q2,Q3,Q4)
  #rm(Q1, Q2, Q3, Q4)
  Y2004$date.temporary = sprintf("%s %s", Y2004$date, Y2004$hour - 1) # hour -1 so that it starts at 0
  Y2004$date.R = ymd_h(Y2004$date.temporary, tz = 'UTC')
  # OlsonNames() # Get a list of R-compatible time zones
  Y2004$date.R.HI = with_tz(Y2004$date.R, "HST")
  
  Y2004$color = as.numeric(as.factor(Y2004$location))
  plot(Y2004$date.R.HI, Y2004$LAI, col = as.factor(Y2004$location), ylab = "LAI", xlab = "Time")
  legend(par('usr')[1],2, fill = seq(1,4), legend = c("Laupahoehoe", "Nahuku", "Nakula", "ParkHQ"))
  
  NAK = Y2004[Y2004$location == "Nakula", ]
  plot(NAK$date.R.HI, NAK$level2.wind, col = 'white')
  lines(NAK$date.R.HI, NAK$level2.wind, col = 'blue')
  lines(NAK$date.R.HI, NAK$level1.wind, col = 'green')
  lines(NAK$date.R.HI, NAK$wind10m, col = 'black')
  lines(NAK$date.R.HI, NAK$canopy.estimated.wind.speed, col = 'purple')
  
  plot(NAK$date.R.HI, NAK$level2.wind - NAK$canopy.estimated.wind.speed, col = 'white', ylim = c(-4,7),
       ylab = "Wind Speed Difference", xlab = "Time")
  lines(NAK$date.R.HI, NAK$level2.wind - NAK$canopy.estimated.wind.speed, col = 'blue')
  lines(NAK$date.R.HI, NAK$level1.wind - NAK$canopy.estimated.wind.speed, col = 'green')
  lines(NAK$date.R.HI, NAK$wind10m - NAK$canopy.estimated.wind.speed, col = 'black')
  
  level2.bias = mean(NAK$level2.wind - NAK$canopy.estimated.wind.speed)
  level1.bias = mean(NAK$level1.wind - NAK$canopy.estimated.wind.speed)
  ws10m.bias = mean(NAK$wind10m - NAK$canopy.estimated.wind.speed)
  
  x = barplot(c(level2.bias, level1.bias, ws10m.bias), ylab = "Wind Speed difference", col = c('blue', 'green', 'black'))
  axis(side = 1, at = x, labels = c("Level2", "Level1", "10m"))
  
  bias.plot = function(in.data, location){
    level2.bias = mean(in.data$level2.wind - in.data$canopy.estimated.wind.speed)
    level1.bias = mean(in.data$level1.wind - in.data$canopy.estimated.wind.speed)
    ws10m.bias = mean(in.data$wind10m - in.data$canopy.estimated.wind.speed)
    
    x = barplot(c(level2.bias, level1.bias, ws10m.bias), ylab = "Wind Speed difference", col = c('blue', 'green', 'black'),
                main = location)
    axis(side = 1, at = x, labels = c("Level2", "Level1", "10m"))
  }
  
  # Are biases consistent across sites?
  PHQ = Y2004[Y2004$location == "ParkHQ", ]
  NAH = Y2004[Y2004$location == "Nahuku", ]
  LAU = Y2004[Y2004$location == "Laupahoehoe", ]
  
  par(mfrow = c(2,2))
  bias.plot(NAK, "Nakula")
  bias.plot(PHQ, "ParkHQ")
  bias.plot(NAH, "Nahuku")
  bias.plot(LAU, "Laupahoehoe")
  
  # Get mean height by site for each level - is ParkHQ 35 m lower than the others? That would suggest height above veg level. If it is the same, then it is height above ground level!
  NAK.l2 = mean(NAK$level2.height)
  PHQ.l2 = mean(PHQ$level2.height)
  NAH.l2 = mean(NAH$level2.height)
  LAU.l2 = mean(LAU$level2.height)
  
  NAK.l1 = mean(NAK$level1.height)
  PHQ.l1 = mean(PHQ$level1.height)
  NAH.l1 = mean(NAH$level1.height)
  LAU.l1 = mean(LAU$level1.height)
  
  # Get mean annual wind speeds
  NAK.l2.ws = mean(NAK$level2.wind)
  PHQ.l2.ws = mean(PHQ$level2.wind)
  NAH.l2.ws = mean(NAH$level2.wind)
  LAU.l2.ws = mean(LAU$level2.wind)

  NAK.l1.ws = mean(NAK$level1.wind)
  PHQ.l1.ws = mean(PHQ$level1.wind)
  NAH.l1.ws = mean(NAH$level1.wind)
  LAU.l1.ws = mean(LAU$level1.wind)

  NAK.10.ws = mean(NAK$wind10m)
  PHQ.10.ws = mean(PHQ$wind10m)
  NAH.10.ws = mean(NAH$wind10m)
  LAU.10.ws = mean(LAU$wind10m)
  
  NAK.ws = mean(NAK$canopy.estimated.wind.speed)
  PHQ.ws = mean(PHQ$canopy.estimated.wind.speed)
  NAH.ws = mean(NAH$canopy.estimated.wind.speed)
  LAU.ws = mean(LAU$canopy.estimated.wind.speed)
  
  # Calcualte for lcw, cwf, and cwi
  NAK.lcw = mean(NAK$lcw[NAK$cwf > 0.01])
  PHQ.lcw = mean(PHQ$lcw[PHQ$cwf > 0.01])
  NAH.lcw = mean(NAH$lcw[NAH$cwf > 0.01])
  LAU.lcw = mean(LAU$lcw[LAU$cwf > 0.01])
  
  # Get hours with fog
  NAK.n.fog = length(NAK$lcw[NAK$cwf > 0.01])
  PHQ.n.fog = length(PHQ$lcw[PHQ$cwf > 0.01])
  NAH.n.fog = length(NAH$lcw[NAH$cwf > 0.01])
  LAU.n.fog = length(LAU$lcw[LAU$cwf > 0.01])

  # cwf
  NAK.cwf = mean(NAK$cwf[NAK$cwf > 0.01])
  PHQ.cwf = mean(PHQ$cwf[PHQ$cwf > 0.01])
  NAH.cwf = mean(NAH$cwf[NAH$cwf > 0.01])
  LAU.cwf = mean(LAU$cwf[LAU$cwf > 0.01])
  
  # Get mean annual CWI
  NAK.cwi = sum(NAK$cwi)
  PHQ.cwi = sum(PHQ$cwi)
  NAH.cwi = sum(NAH$cwi)
  LAU.cwi = sum(LAU$cwi)
  
  
  
}


#' Wind speed and LAI plot based on a year's data to share with Tom and Han
#' 
Wind.Speed.Plot2 = function(){
  require(lubridate)
  Q1 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Jan_test.csv") #**# Update when everything is finished processing - re-running for 2004.
  #Q2 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q2.csv")
  #Q3 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q3.csv")
  #Q4 = read.csv("F:/hawaii_local/CWI_HAN/CWI_estimates_hm_2004_Q4.csv")
  #Y2004 = rbind(Q1,Q2,Q3,Q4)
  Y2004 = Q1 #**# Temporary
  Y2004$date.temporary = sprintf("%s %s", Y2004$date, Y2004$hour - 1) # hour -1 so that it starts at 0
  Y2004$date.R = ymd_h(Y2004$date.temporary, tz = 'UTC')
  # OlsonNames() # Get a list of R-compatible time zones
  Y2004$date.R.HI = with_tz(Y2004$date.R, "HST")
  
  plot(Y2004$date.R.HI, Y2004$LAI, col = as.factor(Y2004$location))

  NAK = Y2004[Y2004$location == "Nakula", ]
  plot(NAK$date.R.HI, NAK$level2.wind, col = 'white')
  lines(NAK$date.R.HI, NAK$level2.wind, col = 'blue')
  lines(NAK$date.R.HI, NAK$level1.wind, col = 'green')
  lines(NAK$date.R.HI, NAK$wind10m, col = 'black')
  lines(NAK$date.R.HI, NAK$canopy.estimated.wind.speed, col = 'purple')
  
  plot(NAK$date.R.HI, NAK$level2.wind - NAK$canopy.estimated.wind.speed, col = 'white', ylim = c(-4,7),
       ylab = "Wind Speed Difference", xlab = "Time")
  lines(NAK$date.R.HI, NAK$level2.wind - NAK$canopy.estimated.wind.speed, col = 'blue')
  lines(NAK$date.R.HI, NAK$level1.wind - NAK$canopy.estimated.wind.speed, col = 'green')
  lines(NAK$date.R.HI, NAK$wind10m - NAK$canopy.estimated.wind.speed, col = 'black')
  
  level2.bias = mean(NAK$level2.wind - NAK$canopy.estimated.wind.speed)
  level1.bias = mean(NAK$level1.wind - NAK$canopy.estimated.wind.speed)
  ws10m.bias = mean(NAK$wind10m - NAK$canopy.estimated.wind.speed)
  
  x = barplot(c(level2.bias, level1.bias, ws10m.bias), ylab = "Wind Speed difference", col = c('blue', 'green', 'black'))
  axis(side = 1, at = x, labels = c("Level2", "Level1", "10m"))
  
  bias.plot = function(in.data, location){
    level2.bias = mean(in.data$level2.wind - in.data$canopy.estimated.wind.speed)
    level1.bias = mean(in.data$level1.wind - in.data$canopy.estimated.wind.speed)
    ws10m.bias = mean(in.data$wind10m - in.data$canopy.estimated.wind.speed)
    
    x = barplot(c(level2.bias, level1.bias, ws10m.bias), ylab = "Wind Speed difference", col = c('blue', 'green', 'black'),
                main = location)
    axis(side = 1, at = x, labels = c("Level2", "Level1", "10m"))
  }
  
  # Are biases consistent across sites?
  PHQ = Y2004[Y2004$location == "ParkHQ", ]
  NAH = Y2004[Y2004$location == "Nahuku", ]
  LAU = Y2004[Y2004$location == "Laupahoehoe", ]

  par(mfrow = c(2,2))
  bias.plot(NAK, "Nakula")
  bias.plot(PHQ, "ParkHQ")
  bias.plot(NAH, "Nahuku")
  bias.plot(LAU, "Laupahoehoe")

  # Get mean height by site for each level - is ParkHQ 35 m lower than the others? That would suggest height above veg level. If it is the same, then it is height above ground level!
  NAK.l2 = mean(NAK$level2.height)
  PHQ.l2 = mean(PHQ$level2.height)
  NAH.l2 = mean(NAH$level2.height)
  LAU.l2 = mean(LAU$level2.height)
  
  NAK.l1 = mean(NAK$level1.height)
  PHQ.l1 = mean(PHQ$level1.height)
  NAH.l1 = mean(NAH$level1.height)
  LAU.l1 = mean(LAU$level1.height)
  
}

#' QC for wind speed calculation - we  seem not to be getting results consistent with the simulation with the downscaling equation
#' 
Wind.Speed.Plot = function(){
  speeds = read.csv("F:/hawaii_local/Supporting/WS_check/WindSpeed_problem.csv")
  
  plot(speeds$Hour, speeds$H_10, col = 'white')
  lines(speeds$Hour, speeds$H_10, col = 'black')
  lines(speeds$Hour, speeds$C10_H1, col = 'green')
  lines(speeds$Hour, speeds$C10_H2, col = 'blue')
  
  # Wind Speed Bias (absolute difference)
  speeds$C10_H1_bias = speeds$H_10 - speeds$C10_H1
  speeds$C10_H2_bias = speeds$H_10 - speeds$C10_H2
  plot(speeds$Hour, speeds$C10_H1_bias, col = 'white')
  lines(speeds$Hour, speeds$C10_H1_bias, col = 'green')
  lines(speeds$Hour, speeds$C10_H2_bias, col = 'blue')
  mean(speeds$C10_H1_bias) # 0.96, so basically a 1 m/s bias too slow!
  mean(speeds$C10_H2_bias) # 0.96, so basically a 1 m/s bias too slow!
  # But variable - some hours it is up to 3 m/s too slow.
  
  # Wind Speed Bias (percent)
  speeds$C10_H1_bias_percent = (speeds$C10_H1_bias / speeds$H_10) * 100
  speeds$C10_H2_bias_percent = (speeds$C10_H2_bias / speeds$H_10) * 100
  plot(speeds$Hour, speeds$C10_H1_bias_percent, col = 'white', ylim = c(-50,100))
  lines(speeds$Hour, speeds$C10_H1_bias_percent, col = 'green')
  lines(speeds$Hour, speeds$C10_H2_bias_percent, col = 'blue')
  mean(speeds$C10_H1_bias_percent) # 46% too low!
  mean(speeds$C10_H2_bias_percent) # 38% too low!
  
  # Plot wind speed across dimensions
  plot(speeds$Hour, speeds$H2_102.8, col = 'white', ylim = c(0,7),
       xlab = "Hour", ylab = "Wind Speed (m/s)")
  lines(speeds$Hour, speeds$H2_102.8, col = 'blue')
  lines(speeds$Hour, speeds$C35_H2, col = 'purple')
  lines(speeds$Hour, speeds$H1_29.9, col = 'green')
  lines(speeds$Hour, speeds$H_10, col = 'black')
  legend(par('usr')[1],par('usr')[4], legend = c('H102', 'Est35', 'H30', 'H10'), fill = c('blue', 'purple', 'green', 'black'))
  
  # Should we just use a 30 m height wind for the 35 m canopy??? That would be simple, and relatively straight forward, as long as the heights don't change that much.
  # Email sent to Han, hope she's not out on vacation this week!
}


#' Look at vegetation fraction across Hawaii/Maui
#' 
View.Veg.Fraction = function(){
  dim1 = wrf$var$T2$varsize[1]
  dim2 = wrf$var$T2$varsize[2]
  
  vegfra = ncvar_get(wrf, "VEGFRA", start = c(1, 1, 1), count = c(dim1,dim2,24))
  image(vegfra[,,1])
  max(vegfra) #   [1] 98.00356
  min(vegfra) # 0
  
  
}


#' Get vegetation types for Hawaii/Maui
#' 
#' Not really a patch, but information I needed in a one-off manner
Get.Veg.Types = function(){
  library(ncdf4)
  library(terra)
  data.dir = "C:/docs/hawaii_local/3D_Files"
  setwd(data.dir)
  
  # Path to netcdf file
  data.files = list.files(data.dir)
  #wrf.test.file = data.files[4] # Oahu/Kauai
  wrf.test.file = data.files[5]
  wrf = nc_open(wrf.test.file)
  
  sink(file = "WRF_info.txt")
  print(wrf)
  sink()
  
  dim1 = wrf$var$IVGTYP$varsize[1]
  dim2 = wrf$var$IVGTYP$varsize[2]
  dim3 = wrf$var$IVGTYP$varsize[3]
  
  IVGTYP = ncvar_get(wrf, "IVGTYP", start = c(1,1,1), count = c(dim1,dim2, dim3))
  image(IVGTYP[,,1])
  veg.classes = unique(as.vector(IVGTYP))
  table(as.vector(IVGTYP))
  # Hawaii/Maui
  # 16  2  8 19  7 13  9  3  1 11 18
  # 16 is water
  
  #    1       2       3       7       8       9      11      13      16      18      19 
  # 8976   78288   18024   23736  183552    4200      24  158592 4175736     240   98832 
  
  # Oahu/Kauai
  # 16  1  8  2 13  9 19  3 18 11  7
  # Table of values. 7 is relatively rare. 16 is dominant.
  #  1          2       3       7       8       9      11      13      16      18      19 
  #  17568    9384   13008      72   19776    3504     288   64200 1804368     960    1872   
  
  # Same vegetation types for Hawaii/Maui as Oahu/Kauai

  #**# LEFT OFF HERE - maybe just save out lat/lon with point value joined  
  # Write out vegetation for identification with NLCD
  IVGTYP.out = ncvar_get(wrf, "IVGTYP", start = c(1,1,1), count = c(dim1,dim2, 1)) # assume dim3 is constant for now.
  grid.file = sprintf("%s_3D_xy_grid.csv", substr(wrf.test.file, 8,21))  
  csv.file = "HM_Landcover.csv"
  convert.to.csv(IVGTYP.out, csv.file, grid.file)
  
}

#' Fix corrupted int rasters based on feedback from Xiao
#' 
#' 2023-06-15
#' 
Fix.Ints = function(){
  require(terra)
  
  bad.hi.tifs = seq(187,191)
  good.tifs = "D:/hawaii_local/Vars/hawaii/RAINNC_present/DailyPPT/tif/1994"
  int.path = "D:/hawaii_local/Vars/hawaii/RAINNC_present/DailyPPT/int_tif/1994"
  
  for (bad.tif in bad.hi.tifs[2:length(bad.hi.tifs)]){ # 1 was run manually
    good.tif = sprintf("%s/DailyPPT_RAINNC_present_1994_%s.tif", good.tifs, bad.tif)
    out.file = sprintf("%s/DailyPPT_RAINNC_present_1994_%s.tif", int.path, bad.tif)
    nn = rast(good.tif)
    out.rast = round(nn[[1]]*100, 0)
    x <- writeRaster(out.rast, out.file, overwrite=TRUE, datatype = "INT4U") # [[1]] makes it a single band raster with the interpolated values
    
    
  }

  bad.m.tif = "040"
  good.tif = sprintf("D:/hawaii_local/Vars/maui/RAINNC_present/DailyPPT/tif/1994/DailyPPT_RAINNC_present_1994_%s.tif", bad.m.tif)
  out.file = sprintf("D:/hawaii_local/Vars/maui/RAINNC_present/DailyPPT/int_tif/1994/DailyPPT_RAINNC_present_1994_%s.tif", bad.m.tif)

  nn = rast(good.tif)
  out.rast = round(nn[[1]]*100, 0)
  x <- writeRaster(out.rast, out.file, overwrite=TRUE, datatype = "INT4U") # [[1]] makes it a single band raster with the interpolated values
  
    
}


#' Run just the climatology part of 10_ProcessAnnual_generic's ProcessAnnual function
#' to correct bug where mean temperature was being multiplied by days in month or days in year.
#' 
fix.climatologies = function(code.dir, variable){
  metrics = c('minimum', 'maximum', 'mean', 'median','midpoint') #**# Move to settings?
  
  #variable = "T2"
  setwd(code.dir)
  source("10_ProcessAnnual_generic.R")
  source("01_Workflow_hlpr.R")
  
  is.cumulative = 0
  for (island in islands){
    # Loop through scenarios
    for (timestep in timesteps){
      for (metric in metrics){
        message(sprintf("Running for %s %s %s", island, timestep, metric))
        base.path = sprintf("%s/Vars/%s/%s_%s/Daily", data.dir, island, variable, timestep)
        
        setwd(base.path)
        var = sprintf("%s_%s", variable, timestep)
        
        # Create climatologies
        calculate.monthly.climatologies(first.year, last.year, variable, timestep, island, data.dir, metric, is.cumulative)
        calculate.annual.climatologies(first.year, last.year, variable, timestep, island, data.dir, metric, is.cumulative)
      }
    }
  }
}

#' Create HI Rainfall Atlas climatologies that are comparable to the WRF climatologies
#' 
#' 2023-03-26
#' 
#' Individual Month-year rasters were downloaded from http://rainfall.geography.hawaii.edu/downloads.html
#' Sub-heading Month-Year Maps 1920-2012
#' ESRI Grid Format
#' Hawaii, Kauai, Oahu and Maui, in mm
#' 
Custom.Climatologies = function(RF.path, out.path, island, island.bit){
  require(terra)
  require(rspat)
  # Make Annual climatology
  ann.clim = rast(sprintf("%s/Annual/%sann_1990_mm", RF.path, island.bit))
  for (year in 1991:2009){
    this.rast = rast(sprintf("%s/Annual/%sann_%s_mm", RF.path, island.bit, year))
    ann.clim = ann.clim + this.rast
  }
  ann.clim = ann.clim / 20
  out.file = sprintf("%s/annual_1990_2009.tif", out.path)
  x <- writeRaster(ann.clim, out.file, overwrite=TRUE, datatype = "INT4U")
  
  # Make Monthly climatologies
  month.bits = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  for (i in 1:12){
    month.bit = month.bits[i]
    month.clim = rast(sprintf("%s/%s_%0.2d%s/%s%s1990_mm", RF.path, island.bit, i, month.bit, island.bit, month.bit))
    for (year in 1991:2009){
      this.rast = rast(sprintf("%s/%s_%0.2d%s/%s%s%s_mm", RF.path, island.bit, i, month.bit, island.bit, month.bit, year))
      month.clim = month.clim + this.rast
    }
    month.clim = month.clim / 20
    out.file = sprintf("%s/Month_%0.2d_1990_2009.tif", out.path, i)
    x <- writeRaster(month.clim, out.file, overwrite=TRUE, datatype = "INT4U")
  }
}

make.climatologies = 0
if (make.climatologies == 1){
  #islands = c('hawaii', 'oahu', 'maui', 'kauai')
  islands = c('oahu', 'maui', 'kauai')
  #island.bits = c('bi', 'oa', 'ma', 'ka')
  island.bits = c('oa', 'ma', 'ka') # Hawaii already run as a test
  for (i in 1:length(islands)){
    island = islands[i]
    island.bit = island.bits[i]
    out.path = sprintf("F:/hawaii_local/Rainfall_Atlas/%sRFGrids_mm/Climatology", island)
    if (!file.exists(out.path)){ dir.create(out.path)}
    RF.path = sprintf('F:/hawaii_local/Rainfall_Atlas/%sRFGrids_mm/Month_Rasters_%s_mm', island, island) # Note: folders were manually renamed during the unzipping process.
    Custom.Climatologies(RF.path, out.path, island, island.bit)
  }
}


patch.kauai.folders = 0
if (patch.kauai.folders == 1){
  base.path = "F:/hawaii_local/Vars/kauai/RAINNC_present/DailyPPT"
  new.path = sprintf("%s/tif", base.path)
  dir.create(new.path)

  for (i in 1990:2009){
    year.path = sprintf("%s/%s", new.path, i)
    dir.create(year.path, showWarnings = FALSE)
    this.dir = sprintf("%s/CSV_for_Tifs/%s/tif", base.path, i)
    
    # Read in files that need to be moved and rename them.
    for (a.file in list.files(this.dir)){
      in.file = sprintf("%s/%s", this.dir, a.file)
      out.file = sprintf("%s/%s", year.path, a.file)
      file.rename(in.file, out.file)
    }
  }
}


#' Look at the timing between re-interpolating from .csv vs. reading in, rounding and saving from raster.
#' I expect the latter to be faster, by a reasonable amount, but if it's not, I'll just re-process everything.
timing.run = 0
if (timing.run == 1){
  
  base.path = 'F:/hawaii_local/Vars/kauai/RAINNC_present/DailyPPT'
  
  # Timing loop
  for (task in c('interpolate', 'read_round')){
    print(task)
    start = Sys.time()
    numbs = numbs = c(1,2) # seq(1,10)
    for (i in numbs){
      #in.file = sprintf("%s/")      
      # Interpolation loop
      if (task == 'interpolate'){
        csv.path = sprintf("%s/CSV_for_Tifs/1990", base.path)
        tif.path = sprintf("%s/time_test_%s", base.path, task)
        in.csv = sprintf("DailyPPT_RAINNC_present_1990_0%02.f.csv", i)
        template.raster = rast("F:/hawaii_local/Vars/grids/templates/kauai_template.tif")
        run.interpolation(csv.path, tif.path, in.csv, template.raster, n.neighbors = 12, power = 2, to.integer = 1)
      }
      # read and write loop
      if (task == 'read_round'){
        in.file = sprintf("%s/tif/1990/DailyPPT_RAINNC_present_1990_0%02.f.tif", base.path, i)
        out.rast = rast(in.file)
        out.file = sprintf("%s/time_test_read_round/DailyPPT_RAINNC_present_1990_0%02.f.tif", base.path, i)
        out.rast = round(out.rast[[1]]*100, 0)
        x <- writeRaster(out.rast, out.file, overwrite=TRUE, datatype = "INT4U") # [[1]] makes it a single band raster with the interpolated values
      }
    }
    end = Sys.time()
    elapsed = end - start
    print(elapsed)
  }
}

# Fill in the missing leap days that were accidentally left off the initial csv processing run due to a bug in the leap year processing
# Copied and pasted from 12_Daily2geotif.R then modified.
#**# LEFT OFF ADAPTING THIS - NEED TO ADJUST IT TO JUST RUN FOR THE LEAP DAYS
add.leap.days = 0
if (add.leap.days == 1){
  base.path = "F:/hawaii_local/Vars"
  this.var = "RAINNC"
  islands = c("kauai", 'oahu', 'maui', 'hawaii')
  timesteps = c("present", 'rcp45', 'rcp85')
  years = c(1992, 1996, 2000, 2004, 2008)
  for (island in islands){
    for (timestep in timesteps){
      var = sprintf("%s_%s", this.var, timestep)
      island.grid = sprintf("%s/grids/wrf_grids/%s_xy_grid_index.csv", base.path, island)
      template.raster.file = sprintf("%s/grids/templates/%s_template.tif", base.path, island)
      template.raster = terra::rast(template.raster.file)
      
      # Loop through year files
      for (year in years){
        message(sprintf("Now processing %s", year))
        daily.path = sprintf("%s/%s/%s/DailyPPT", base.path, island, var)
        out.folder = sprintf("%s/CSV_for_Tifs/%s", daily.path, year)
        tif.path = sprintf("%s/tif/%s", daily.path, year)
        if (!file.exists(out.folder)){
          dir.create(out.folder, recursive = TRUE)
        }
        if (!file.exists(tif.path)){
          dir.create(tif.path, recursive = TRUE)
        }
        
        
        # For each year
        in.file = sprintf("%s/DailyPPT_%s_year_%s.rda", daily.path, var, year)
        
        load(in.file) # loads the day.ppt.array object
        
        # Loop through days in the year
        day = 366
        csv.file = sprintf("DailyPPT_%s_%s_%03.f.csv", var, year, day)
        csv.file.full = sprintf("%s/%s",out.folder, csv.file)
        
        # Subset out to that particular day
        current.values = day.ppt.array[,,day]
        
        # Export to .csv
        convert.to.csv(current.values, csv.file.full, island.grid, int100 = FALSE)
        # Originally, plan was to multiply by 100 and convert to integer to save space. However,
        # Rounding to nearest 100 is undone in ArcGIS during interpolation, and does not save much space in the .csv (<20%)
        # Also, .csv's can be deleted after the raster files are created if space is an issue.
        
        #**# Need to change the structuring - I don't like that the tif folder has to be nested in the .csv folder. Would rather they were parallel to each other.
        # Run interpolation
        run.interpolation(out.folder, tif.path, csv.file, template.raster, n.neighbors = 12, power = 2) # , to.integer = 1 This is patching the original run, so that I can systematically convert those files to the integer.
      }
    }
  }
}

# Patch to correct naming bug (these are the mistakes that kill my progress as a scientist!)
remove_test2 = 0
if (remove_test2 == 1){
  base.path = "F:/hawaii_local/Vars"
  this.var = "RAINNC"
  islands = c("kauai", 'oahu', 'maui', 'hawaii')
  timesteps = c("present", 'rcp45', 'rcp85')
  years = c(1992, 1996, 2000, 2004, 2008)
  for (island in islands){
    for (timestep in timesteps){
      var = sprintf("%s_%s", this.var, timestep)

      # Loop through year files
      for (year in years){
        message(sprintf("Now processing %s", year))
        daily.path = sprintf("%s/%s/%s/DailyPPT", base.path, island, var)
        tif.path = sprintf("%s/tif/%s", daily.path, year)
        day = 366
        old_name = sprintf("%s/DailyPPT_RAINNC_%s_%s_%s_test2.tif", tif.path, timestep, year, day)
        correct_name = sprintf("%s/DailyPPT_RAINNC_%s_%s_%s.tif", tif.path, timestep, year, day)
        file.rename(old_name, correct_name)
      }
    }
  }
}


#**# RE-RUN THIS AFTER THE LEAP-DAY PATCH ABOVE
# Create integer rasters for each of the islands and scenarios
patch.int.rasters = 0
if (patch.int.rasters == 1){
  require(rspat)
  base.dir = "F:/hawaii_local/Vars"
  islands = c('kauai', 'oahu', 'maui', 'hawaii') 
  timesteps = c('present', 'rcp45', 'rcp85')
  for (island in islands){
    message(island)
    for (year in 1990:2009){ # 1990:2009
      message(year)
      for (scenario in timesteps){
        message(scenario)
        this.dir = sprintf("%s/%s/RAINNC_%s/DailyPPT/tif/%s", base.dir, island, scenario, year)
        out.dir = sprintf("%s/%s/RAINNC_%s/DailyPPT/int_tif/%s", base.dir, island, scenario, year)
        if (!file.exists(out.dir)){
          dir.create(out.dir, recursive = TRUE)
        }
        days = 365
        if (year %% 4 == 0){
          days = 366
        }
        for (day in 1:days){
          a.file = sprintf("DailyPPT_RAINNC_%s_%s_%03.f.tif", scenario, year, day)
          in.file = sprintf("%s/%s", this.dir, a.file)
          out.file = sprintf("%s/%s", out.dir, a.file) #**# Do we want to label them as integer rasters?
          out.rast = rast(in.file)
          out.rast = round(out.rast[[1]]*100, 0)
          x <- writeRaster(out.rast, out.file, overwrite=TRUE, datatype = "INT4U") # [[1]] makes it a single band raster with the interpolated values
        }
      }
    }
  }
}

