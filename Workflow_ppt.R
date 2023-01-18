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
data.dir = "C:/hawaii_local"

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
source("0000_Data_Downloader_v2.R") #**# NEEDS UPDATING - FUNCTIONS ARE DEFINED AFTER THEY ARE CALLED. MOVE FUNCTIONS TO Workflow_hlpr.R

# STEP 3: Correct the present day scenario to account for the missing day
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
  for (scenario in scenarios){
    add.X.hours.ok(base.path, island, scenario, GMT.offset)
  }
}


# STEP 4: Extract variables for further processing locally on R
# NOTE: We lose 10 hours of the last day of the last year of the scenario run, due to the GMT offset
#**# ADD A CHECK IF THE FILES ALREADY EXIST, THAT CAN BE OVERRIDDEN
for (island in ok.vec){
  for (scenario in scenario.vec){
    source("001c_ExtractAnnual_ok.R")
  }
}

# Error for Kauai - just restarted the process where it left off. (careful with this - need to ensure the leap-year variable is reset)
#CURL Error: Failure when receiving data from the peer
#Error in Rsx_nc4_get_vara_double: NetCDF: DAP failure
#Var: RAINNC_rcp85  Ndims: 3   Start: 17579,0,0 Count: 8785,64,82
#Error in ncvar_get_inner(ncid2use, varid2use, nc$var[[li]]$missval, addOffset,  : 
#                           C function R_nc4_get_vara_double returned error

# Scenarios are in separate WRF files for Hawaii and Maui, need to extract data for those as well
for (island in hm.vec){
  stop("I ran this manually. Needs further adjustments to be run directly from this script. (mainly settings are hard-coded!")
  # Not set up to batch through scenarios
  # Data file starts out in present from sourcing 000b_PrecipSettings.R
  #timestep = 'present'
  source("001c_ExtractAnnual_hm.R")
  
}


# STEP 3: Convert extracted variables into quantities of interest
setwd(code.dir)
if (island == "oahu" | island == "kauai"){
  source("002b_ProcessAnnual_ppt_ko.R")
}
if (island == "maui" | island == "hawaii"){
  timescales = c(timescales, 'part')
  # Split into pieces, to allow it to be run and moved off the computer.
  timesteps = c("present")
  setwd(code.dir)
  source("002b_ProcessAnnual_ppt_hm.R")
  
  timesteps = c("rcp45")
  setwd(code.dir)
  source("002b_ProcessAnnual_ppt_hm.R")
  
  timesteps = c("rcp85")
  setwd(code.dir)
  source("002b_ProcessAnnual_ppt_hm.R")
  
}


# NOTE: File paths need to exist prior to running this script - need to adjust extract annual to create
# the DailyPPT directory as well. (currently this was manually created when I ran the script)

# NOTE: WRF RAINNC variable values exceeded 100 and I_RAIN was not present for all scenarios
# It was assumed that when the bucket dropped, any excess above 100 was carried over and not dropped
# If the excess was greater than the next day's reading, an NA value was assigned.
# We may want to reconsider this.

# Convert Climatologies to .csv file to move to HI Rainfall atlas grid in ArcGIS
setwd(code.dir)
my.var = "RAINNC"
source("003_Export_to_csv.R")


#**# BELOW HERE NOT YET COMPLETED

# STEP 4:Quality Control: Check a subset of data for plausibility
#     # REQUIRES THE FOLLOWING STEPS TO BE TAKEN IN ARCGIS:

# STEP 5: Quality Control: Compare present-day WRF to Hawaii Rainfall Atlas

