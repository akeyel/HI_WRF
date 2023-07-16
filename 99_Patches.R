# Assorted patches to bring data structure in line with code changes that occurred after processing

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

