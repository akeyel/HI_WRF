# Process HI Temperature data from server

# Created 2023-02-20 using the 00_Workflow_ppt.R as a template

# Authors: A.C. Keyel <akeyel@albany.edu>

# Acknowledgements:
#     - T. Giambelluca
#     - O. Elison Timm
#     - A. Frazier
#     - L. Kaiser
#     - K. Fandrich
#     - L. Fortini
#     - Xiao Luo

# Select Variable for analysis
variable = "T2" 
metrics = c('minimum', 'maximum', 'mean', 'median','midpoint')


#**# Change as needed
# Code Directory
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'
# Data Directory
data.dir = "F:/hawaii_local"

new.laptop = 1
if (new.laptop == 1){
  code.dir = "C:/docs/science/HI_WRF"
  #data.dir = "D:/hawaii_local"
  data.dir = "C:/docs/hawaii_local"
}

# Choose island (oahu, kauai, hawaii, maui) #**# Need to decide if running for all islands, or for each island separately - code is a mixture.
#island = 'kauai'

hm.vec = c('hawaii', 'maui')
ok.vec = c('oahu', 'kauai')
islands = c(ok.vec, hm.vec)
#scenarios = c('present', 'rcp45', 'rcp85') # equivalent to timesteps defined in precip settings

##### SET UP THE ANALYSIS #####
setwd(code.dir)

# STEP 1: Load helper functions (adjust paths as needed)
source("01_Workflow_hlpr.R")

# STEP 2: Load settings to run the precipitation analysis
source("Settings/Settings_T.R")

# Step 3: Load interpolation function
source("03_SpatialInterpolateFunction.R")

# Load the data download function
source("05_Data_Downloader_generic.R") # This version loads the Download_Var function. The ppt version is a script.
source("05.5_CopyData.R") # This allows automatic adjustment of the file paths

##### Process data from web-available sources ######
#### Process the Data #### 

# STEP 4: Make a data grid to export data values as points. (only needs to be run once)
if (make.grid == 1){
  for (island in islands){
    scenario = 'present'
    data.file = get.data.file(island, scenario)
    
    # Open the data file
    my.ncdf =ncdf4::nc_open(data.file)
    
    # This uses present temperature, and assumes all variables are on the same grid
    setwd(data.dir)
    grid.file = sprintf("%s_xy_grid_index.csv", island)
    make.data.grid(my.ncdf, island, grid.file)
    # close the netcdf
    nc_close(my.ncdf)
    
    setwd(code.dir)
  }
}

# STEP 5: Download data from USGS
# Currently set up to run for all 4 islands - may want to adjust options to select islands.
if (download.data == 1){
  for (island in islands){
    message(island)
    for (scenario in c('present', 'rcp45', 'rcp85')){
      if (island %in% ok.vec){
        var = sprintf("%s_%s", variable, scenario)
        base.path = sprintf("%s/Vars/%s/%s/hourly", data.dir, island, var)
        message(var)
        Download_Var(base.path, island, scenario, var)
      }
      if (island %in% hm.vec){
        base.path = sprintf("%s/Vars/%s/%s_%s/hourly", data.dir, island, variable, scenario)
        message(sprintf("%s_%s", variable, scenario))
        Download_Var(base.path, island, scenario, variable)
      }
    }
  }
}

# STEP 6: Correct the present day scenario to account for the missing day
if (interpolate.day == 1){
  setwd(code.dir)
  source("06_Interpolate_Day.R") # Loads the functions from this script
  for (island in islands){
    message(island)
    
    # Adjust paths to prepare to interpolate a day for the present-day scenario
    # From 05.5_CopyData.R by Kristen Sanfilippo
    copy.raw.data(data.dir, island, variable)
    
    # Add an interpolated day (present scenario only)
    base.path = sprintf("%s/Vars/%s", data.dir, island)
    insert.interpolated.day(base.path, island, variable)
    
    # Add interpolated hours to end of simulation (all scenarios, to adjust for GMT -> local time conversion)
    for (scenario in timesteps){
      add.X.hours.var(base.path, island, variable, scenario, GMT.offset) 
    }
  }
}


extract.variables = 1
do.corrections = 0
create.aggregates = 0
climatology.to.raster = 0

# STEP 7: Extract variables for further processing locally on R
if (extract.variables == 1){
  setwd(code.dir)
  source("07_ExtractAnnual_general.R") # now loads the extract.annual.data function, instead of being a script that is run when sourced as for precipitation
  for (island in islands){
    for (scenario in timesteps){
      message(sprintf("%s: %s", island, scenario))
      new.dir = "Daily"
      base.path = sprintf("%s/Vars", data.dir)
      extract.annual.data(base.path, island, variable, scenario, new.dir,
                          GMT.offset, leap.years)
    }
  }
  create.aggregates = 1
}

# STEP 8: Fix known errors in the daily data set
if (do.corrections == 1){
  #**# Watch for problems in Maui and HI for day 365 in year 2007
}

# STEP 10: Create daily, annual and monthly aggregates and climatologies
if (create.aggregates == 1){
  setwd(code.dir)
  source("10_ProcessAnnual_generic.R")
  
  # Determine whether to have a monthly total (e.g., monthly rainfall) or a monthly average (e.g., mean temperature)
  is.cumulative = 0
  if (variable == 'ppt'){ is.cumulative = 1  }
  
  for (island in islands){
    # Loop through scenarios
    for (timestep in timesteps){
      for (metric in metrics){
        message(sprintf("Running for %s %s %s", island, timestep, metric))
        base.path = sprintf("%s/Vars/%s/%s_%s/Daily", data.dir, island, variable, timestep)
        ProcessAnnual(base.path, metric, variable, timestep,
                                 first.year, last.year, leap.years, is.cumulative)
      }
    }
  }
  climatology.to.raster = 1
}

# STEP 11: Convert annual and monthly climatologies to CSV and Raster (tif)
if (climatology.to.raster == 1){
  for (island in islands){
    message(island)
    # Loop through scenarios
    for (timestep in timesteps){
      for (metric in metrics){
        metric.bit = sprintf("%s_", metric)
        message(timestep)
        setwd(code.dir)
        source("11_climatology2geotif.R") # Also converts to .tif using the run.interpolation function
      }
    }
  }
}

# STEP 12: Convert each day to csv, and then to raster
if (daily.to.raster == 1){
  for (island in islands){
    message(island)
    for(timestep in timesteps){
      for (metric in metrics){
        metric.bit = sprintf("%ss_", metric)
        message(timestep)
        message(metric)
        setwd(code.dir)
        base.path = sprintf("%s/Vars", data.dir)
        start.year = 1990
        end.year = 2009
        var.label = "" # PPT for precipitation run
        source("12_Daily2geotif.R")
      }
    }
  }
}

# STEP 12b
#if (check.daily.rasters == 1){
#  bad.file.log = sprintf("%s/Vars/%s_bad_int_files.csv", data.dir, variable)
#  for (island in islands){
#    message(island)
#    for (timestep in timesteps){
#      for (metric in metrics){
#        
#        #**# THE FOLDER STRUCTURE USED BELOW DOES NOT QUITE MATCH THAT DEVELOPED IN THE PREVIOUS STEP. THESE WILL NEED TO BE HARMONIZED TO WORK, BUT I'M GOING TO WAIT
#        #**# SINCE AT PRESENT THERE IS NO NEED FOR DAILY GEOTIFS FOR EACH VARIABLE.
#        
#        # From 03_SpatialInterpolateFunction.R, which might not be the most logical place to put this function, but I needed a script that was using the terra package
#        in.dir = sprintf("%s/Vars/%s/%s_%s/Daily/%s_int_tif", data.dir, island, variable, timestep, metric)
#        bad.files = check.raster.tifs(in.dir)
#        cat(paste(c(island, timestep, metric), paste = collapse = " "), file = bad.file.log, append = TRUE)
#        cat('\n', file = bad.file.log, append = TRUE)
#        cat(paste(bad.files, collapse = ', '), file = bad.file.log, append = TRUE)
#        cat('\n', file = bad.file.log, append = TRUE)
#      }
#    }
#  }
#}



# STEP 13: Convert monthly and annual data to GeoTif
means.to.raster = 0
setwd(code.dir)
source("13_Means2geotif.R")
if (means.to.raster == 1){
  for (island in islands){
    message(island)
    for (timestep in timesteps){
      for (metric in metrics){
        message(timestep)
        message(metric)
        base.path = sprintf("%s/Vars", data.dir)
        start.year = 1990
        end.year = 2009
        extra.bit = "" #**# 
        metric.bit = sprintf("%s_", metric)
        
        # Convert Annual means to geotif
        message('processing annual data')
        mean2geotif(base.path, code.dir, island, variable, timestep, start.year, end.year, 'annual', extra.bit, metric.bit)
        
        # Convert monthly means to geotif
        message("Processing monthly data")
        mean2geotif(base.path, code.dir, island, variable, timestep, start.year, end.year, 'monthly', extra.bit, metric.bit)
      }
    }
  }
}


# STEP 14: Final Quality Control: Compare present-day WRF to Hawaii Rainfall Atlas
do.qc = 0
if (do.qc == 1){
  setwd(code.dir)
  source("14_Quality_COntrol_Write_up_Figs.R")
  for (island in islands){
    message(island)
    for (timestep in timesteps){
      for (metric in metrics){
        message(timestep)
        message(metric)
        
        data.folder = sprintf("%s/Vars/%s/%s_%s", data.dir, island, variable, timestep)
        ref.folder = use.ref = ref.type = island.bit = NA
        #**# The reference is not yet set up - but would like to include this for T2 once it is finished.
        #if (variable == "T2"){
        #  use.ref = 1
        #  ref.folder = "FIXME!!!" #"F:/hawaii_local/Rainfall_Atlas/HawaiiRFGrids_mm/"
        #  ref.type = "T2"
        #}
        fig.folder = sprintf("%s/QC/%s/%s_%s", data.dir, island, variable, timestep)
        if (!file.exists(fig.folder)){
          dir.create(fig.folder, recursive = TRUE)
        }
        outline = sprintf("%s/gis/Vector/%s_ne.shp", code.dir, island)
        
        do.main = do.supplement = 1
        do.extra = 0 #**# The extra QC steps have not been scripted yet.
        ppt.bit = ""

        create.qc.plots(data.folder, ref.folder, fig.folder, variable, metric,
                                   use.ref, ref.type,
                                   island, island.bit, timestep, outline,
                                   do.main, do.supplement, do.extra, ppt.bit = ppt.bit)
      }
    }
  }
}
