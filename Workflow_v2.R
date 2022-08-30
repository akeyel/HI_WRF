# Goal is to create a script to describe the desired HI workflow for WRF model
# data processing. First step is to generate pseudo-code, to lay out the steps,
# and make it easier to fill in the details

# Created 2021-12-14

# Authors: A.C. Keyel <akeyel@albany.edu> #**# Add others as needed. Need to think
# about how to acknowledge those who don't provide code, but do provide input
# about what should be coded!
# Acknowledgements:
#     - O. Elison Timm provided general guidance
#     - K. Fandrich provided guidance on processing the precipitation
#     - 


##### SET UP THE ANALYSIS #####
source("100_DevSettings.R") #**# May need to set working directory first

# Set working directory and load helper functions (adjust paths as needed)
setwd(code.dir)
source("Workflow_hlpr.R")

##### Process data from web-available sources ######
#### Process the Data #### 

# STEP 1: Make a data grid to export data values as points.
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
source("001_ExtractAnnual.R")

# STEP 3: Convert extracted variables into quantities of interest
source("002_ProcessAnnual.R")

# STEP 4: Export data to GIS-friendly format (GeoTiff snapped to HI Rainfall Atlas 250 m grid)
stop("003_ExportWRF.R has not been scripted yet")
##### Change projection from HI-specific projection to one that can be better joined
# to other data sets
# consider whether thiessan polygons and spatial joins will solve the problem here
# might be easier to work with vector than with raster, depending on the question.

# STEP 5: Move Data to a server location / provide server support
stop("This has not been scripted and likely will be done outside of R")

##### Move processed data sets to a server for external use #####
# where is the final data set going to be hosted?
