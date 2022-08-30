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

#**# Change as needed
# Code Directory
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'

# Data Directory
data.dir = "C:/hawaii_local"

# Choose island (oahu, kauai, hawaii, maui)
island = 'maui'

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

# STEP 2: Extract variables for further processing locally on R
# NOTE: We lose 10 hours of the last day of the last year of the scenario run, due to the GMT offset
if (island == 'oahu' | island == "kauai"){
  timestep = "present"
  source("001_ExtractAnnual.R")
}

# Error for Kauai - just restarted the process where it left off. (careful with this - need to ensure the leap-year variable is reset)
#CURL Error: Failure when receiving data from the peer
#Error in Rsx_nc4_get_vara_double: NetCDF: DAP failure
#Var: RAINNC_rcp85  Ndims: 3   Start: 17579,0,0 Count: 8785,64,82
#Error in ncvar_get_inner(ncid2use, varid2use, nc$var[[li]]$missval, addOffset,  : 
#                           C function R_nc4_get_vara_double returned error

# Scenarios are in separate WRF files for Hawaii and Maui, need to extract data for those as well
if (island == "hawaii" | island == "maui"){
  # Data file starts out in present from sourcing 000b_PrecipSettings.R
  timestep = 'present'
  source("001b_ExtractAnnual.R")
  
  setwd(code.dir)
  timestep = "rcp45"
  data.file = get.data.file(island, timestep)
  source("001b_ExtractAnnual.R")
  
  setwd(code.dir)
  timestep = "rcp85"
  data.file = get.data.file(island, timestep)
  source("001b_ExtractAnnual.R")
  
}


# STEP 3: Convert extracted variables into quantities of interest
setwd(code.dir)
if (island == "oahu" | island == "kauai"){
  source("002b_ProcessAnnual_ppt_ko.R")
}
if (island == "maui" | island == "hawaii"){
  source("002b_ProcessAnnual_ppt_hm.R")
}

# NOTE: File paths need to exist prior to running this script - need to adjust extract annual to create
# the DailyPPT directory as well. (currently this was manually created when I ran the script)

# NOTE: WRF RAINNC variable values exceeded 100 and I_RAIN was not present for all scenarios
# It was assumed that when the bucket dropped, any excess above 100 was carried over and not dropped
# If the excess was greater than the next day's reading, an NA value was assigned.
# We may want to reconsider this.


#**# BELOW HERE NOT YET COMPLETED

# STEP 4:Quality Control: Check a subset of data for plausibility
#     # REQUIRES THE FOLLOWING STEPS TO BE TAKEN IN ARCGIS:

# STEP 5: Quality Control: Compare present-day WRF to Hawaii Rainfall Atlas

