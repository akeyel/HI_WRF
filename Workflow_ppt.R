# Process HI Rainfall data from server

# Created 2021-12-14

# Authors: A.C. Keyel <akeyel@albany.edu>
#**# Add others as appropriate

# Acknowledgements:
#     - T. Giambelluca
#     - O. Elison Timm
#     - A. Frazier
#     - L. Kaiser
#     - K. Fandrich
#     - L. Fortini
#     - Xiao Luo

#**# TO DO
# Need to update ppt_hm file
# Need to update and check temperature files
# Need to auto-generate climatology folder when making directories

#**# Change as needed
# Code Directory
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'

# Data Directory
data.dir = "F:/hawaii_local"

# Choose island (oahu, kauai, hawaii, maui) #**# Need to decide if running for all islands, or for each island separately - code is a mixture.
#island = 'kauai'

hm.vec = c('hawaii', 'maui')
ok.vec = c('oahu', 'kauai')
islands = c(ok.vec, hm.vec)
#scenarios = c('present', 'rcp45', 'rcp85') # equivalent to timesteps defined in precip settings

##### SET UP THE ANALYSIS #####
setwd(code.dir)

# Load helper functions (adjust paths as needed)
source("Workflow_hlpr.R")

# Load settings to run the precipitation analysis
source("000b_PrecipSettings.R")

# Load interpolation function
source("007_Spatial_Interpolate.R")

##### Process data from web-available sources ######
#### Process the Data #### 

# STEP 1: Make a data grid to export data values as points. (only needs to be run once)
if (make.grid == 1){
  for (island in islands){
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

# STEP 2: Download data from USGS
# Currently set up to run for all 4 islands - may want to adjust options to select islands.
download.data = 0 #**# Move this to settings
if (download.data == 1){
  source("0000_Data_Downloader_v2.R") #**# 
}

# STEP 3: Correct the present day scenario to account for the missing day
interpolate.day = 0
if (interpolate.day == 1){

  setwd(code.dir)
  source("0000_Interpolate_Day.R") # Loads the functions from this script
  for (island in hm.vec){
    base.path = sprintf("F:/hawaii_local/Vars/%s", island)
    fix.hm.ppt.timeseries(base.path, island)
    for (scenario in timesteps){
      add.X.hours.hm(base.path, island, scenario, GMT.offset)
    }
  }
  
  for (island in ok.vec){
    base.path = sprintf("F:/hawaii_local/Vars/%s", island)
    fix.ok.ppt.timeseries(base.path, island)
    for (scenario in timesteps){
      add.X.hours.ok(base.path, island, scenario, GMT.offset)
    }
  }
}

# STEP 3B: Replace e05 data files with 100000
#**# NEEDS SCRIPTING - I've just done this manually, while looking through the folders to make sure everything was correct.
#**# Can script it out for temperature
#**# Instead, backfill format(file.end, scientific = F) to the generator scripts, and prevent it from being generated in the first place

# STEP 4: Extract variables for further processing locally on R
for (island in ok.vec){
  for (scenario in timesteps){
    setwd(code.dir)
    message(sprintf("%s: %s", island, scenario))
    source("001c_ExtractAnnual_ok.R")
  }
}

# Scenarios are in separate WRF files for Hawaii and Maui, need to extract data for those as well
for (island in hm.vec){
  for (scenario in timesteps){
    setwd(code.dir)
    source("001c_ExtractAnnual_hm.R")
  }
}

# STEP 5: Fix known errors in the daily data set
do.corrections = 0
if (do.corrections == 1){
  base.path = "F:/hawaii_local/Vars/maui/RAINNC_rcp45/DailyPPT"
  fix.ppt.2007.365(base.path)
  # Same problem with negative values occurred in the Hawaii data set
  base.path = "F:/hawaii_local/Vars/hawaii/RAINNC_rcp45/DailyPPT"
  fix.ppt.2007.365(base.path)
}

# STEP 5B: Do basic quality control to check for unrealistic values
#**# NEEDS SCRIPTING/THINKING

# STEP 6: Create annual and monthly aggregates and climataologies
#**# Watch for file path issues - need to make sure required folders are created as needed
for (island in islands){
  # Loop through scenarios
  for (timestep in timesteps){
    message(sprintf("Running for %s %s", island, timestep))
    setwd(code.dir)
    base.path = sprintf("%s/Vars/%s/RAINNC_%s/DailyPPT", data.dir, island, timestep)
    source("002b_ProcessAnnual_ppt.R")
  }
}

# STEP 7: Convert annual and monthly climatologies to CSV to convert to Raster
for (island in islands){
  message(island)
  # Loop through scenarios
  for (timestep in timesteps){
    message(timestep)
    setwd(code.dir)
    this.var = "RAINNC"
    source("003_Export_to_csv.R") # Also converts to .tif using the run.interpolation function
  }
}

# STEP 8: Convert each day to csv, and then to raster
for (island in islands){
  message(island)
  for(timestep in timesteps){
    message(timestep)
    setwd(code.dir)
    this.var = "RAINNC"
    base.path = "F:/hawaii_local/Vars"
    start.year = 1990
    end.year = 2009
    source("Daily_to_geotif.R")
  }
}



# STEP 5: Quality Control: Compare present-day WRF to Hawaii Rainfall Atlas

