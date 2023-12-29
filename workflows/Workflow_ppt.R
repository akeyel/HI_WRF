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

new.laptop = 1

#NOTE: Change as needed
# Code Directory
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'

# Data Directory
data.dir = "F:/hawaii_local"

if (new.laptop == 1){
  code.dir = "C:/docs/science/HI_WRF"
  data.dir = "D:/hawaii_local"
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
source("settings/PrecipSettings.R")

# Step 3: Load interpolation function
source("03_SpatialInterpolateFunction.R")

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
  source("05_Data_Downloader.R")
}

# STEP 6: Correct the present day scenario to account for the missing day
if (interpolate.day == 1){
  setwd(code.dir)
  source("06_Interpolate_Day.R") # Loads the functions from this script
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


# STEP 7: Extract variables for further processing locally on R
if (extract.variables == 1){
  for (island in ok.vec){
    for (scenario in timesteps){
      setwd(code.dir)
      message(sprintf("%s: %s", island, scenario))
      source("07_ExtractAnnual_ok_ppt.R")
    }
  }
  
  # Scenarios are in separate WRF files for Hawaii and Maui, need to extract data for those as well
  for (island in hm.vec){
    for (scenario in timesteps){
      setwd(code.dir)
      source("07_ExtractAnnual_hm_ppt.R")
    }
  }
}

# STEP 8: Fix known errors in the daily data set
if (do.corrections == 1){
  base.path = "F:/hawaii_local/Vars/maui/RAINNC_rcp45/DailyPPT"
  fix.ppt.2007.365(base.path)
  # Same problem with negative values occurred in the Hawaii data set
  base.path = "F:/hawaii_local/Vars/hawaii/RAINNC_rcp45/DailyPPT"
  fix.ppt.2007.365(base.path)
}

# STEP 9: Do basic quality control to check for unrealistic values
# All QC done at end

# STEP 10: Create daily, annual and monthly aggregates and climatologies
if (create.aggregates == 1){
  for (island in islands){
    # Loop through scenarios
    for (timestep in timesteps){
      message(sprintf("Running for %s %s", island, timestep))
      setwd(code.dir)
      base.path = sprintf("%s/Vars/%s/RAINNC_%s/DailyPPT", data.dir, island, timestep)
      source("10_ProcessAnnual_ppt.R")
    }
  }
}

# STEP 11: Convert annual and monthly climatologies to CSV and Raster (tif)
if (climatology.to.raster == 1){
  for (island in islands){
    message(island)
    # Loop through scenarios
    for (timestep in timesteps){
      message(timestep)
      setwd(code.dir)
      this.var = "RAINNC"
      source("11_climatology2geotif.R") # Also converts to .tif using the run.interpolation function
    }
  }
}

# STEP 12: Convert each day to csv, and then to raster
if (daily.to.raster == 1){
  for (island in islands){
    message(island)
    for(timestep in timesteps){
      message(timestep)
      setwd(code.dir)
      this.var = "RAINNC"
      base.path = sprintf("%s/Vars", data.dir)
      start.year = 1990
      end.year = 2009
      source("12_Daily2geotif.R")
    }
  }
}

# STEP 13: Convert monthly and annual data to GeoTif
means.to.raster = 0
setwd(code.dir)
source("13_Means2geotif.R")
if (means.to.raster == 1){
  for (island in islands){
    message(island)
    for (timestep in timesteps){
      message(timestep)
      variable = "RAINNC"
      base.path = sprintf("%s/Vars", data.dir)
      start.year = 1990
      end.year = 2009
      extra.bit = "_ppt"
      
      # Convert Annual means to geotif
      message('processing annual data')
      mean2geotif(base.path, island, variable, timestep, start.year, end.year, 'annual', extra.bit)
      
      # Convert monthly means to geotif
      message("Processing monthly data")
      mean2geotif(base.path, island, variable, timestep, start.year, end.year, 'monthly', extra.bit)
    }
  }
}

# STEP 13: Final Quality Control: Compare present-day WRF to Hawaii Rainfall Atlas
island.bits = c('oa', 'ka', 'bi', 'ma')
source("XX_Quality_Control_Write_up_Figs.R")
for (i in 1:length(islands)){
  island = islands[i]
  island.bit = island.bits[i]
  
  variable = "RAINNC" # For both rain variables at this stage
  for (scenario in timesteps){
    data.folder = sprintf("%s/Vars/%s/%s_%s", data.dir, island, variable, scenario)
    ref.folder = sprintf("%s/Rainfall_Atlas/%sRFGrids_mm/", data.dir, island)
    fig.folder = sprintf("%s/QC/%s/%s_%s", data.dir, island,  variable, scenario)
    if(!file.exists(fig.folder)){
      dir.create(fig.folder, recursive = TRUE)
    }
    
    use.ref = 1
    if (scenario %in% c('rcp45', 'rcp85')){ use.ref = NA }
    outline = sprintf("%s/Vector/%s_ne.shp", data.dir, island)
    ref.type = 'ppt'
    
    create.qc.plots(data.folder, ref.folder, fig.folder, variable, use.ref, ref.type,
                    island, island.bit, scenario, outline, do.main = 1, do.supplement = 1,
                    do.extra = 1)
  }  
}
