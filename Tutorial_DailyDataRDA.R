# Tutorial on how to use the Daily Data .rda Files and export processed data 
# to a georeferenced format viewable in ArcGIS

# Step 0: Download R and RStudio (Free!)
# Step 0B: install the terra package:
if (!require('terra')){install.packages('terra')}
if (!require('gstat')){install.packages('gstat')}
if (!require('caret')){install.packages('caret')}

# Step 0C: Load required functions
source('01_Workflow_hlpr.R') # Loads convert.to.csv function
#**# (among many others, we may want to split it out for end users of the scripts
#* vs. those doing the primary processing)
source('03_SpatialInterpolateFUnction.R') # Loads run interpolation function

# Step one: Load the .rda file
load("DailyPPT_rainnc_present_year_1990.rda")
# This loads the day.ppt.array object.
# load loads it with whatever object name it was saved with.
# Please DO NOT put day.ppt.array = load("DailyPPT_rainnc_present_year_1990.rda"),'
# or you will get NULL! (it's an easy mistake to make and a hard one to catch!)
dim(day.ppt.array) # Get the dimensions

# Step two: Compute the statistic of interest.
# For the sake of example, we will make a map of the maximum daily rainfall for Kauai
ppt.array.max = apply(day.ppt.array, c(1,2), max)
dim(ppt.array.max)

# Step three: Export the data using the WRF Grid files to convert from
# rows/columns to lat/long, and then interpolate from lat/long to the HI
# Rainfall Atlas grid resolution for ease of comparison with existing data sets.
# Note: this is an interpolation beyond the original resolution of the model.
# Some GIS best practices would recommend aggregating any finer resolution data
# sets to the resolution of the WRF model.
# loads the climatology object

# These are the paths on the data hard drive
#island.grid = "F:/hawaii_local/Vars/grids/wrf_grids/kauai_xy_grid_index.csv"
#template.raster.file = "F:/hawaii_local/Vars/grids/templates/kauai_template.tif"
island.grid = "kauai_xy_grid_index.csv"
template.raster.file = "kauai_template.tif"

csv.path = 'csv/'
if (!file.exists(csv.path)){dir.create(csv.path)}
# yes, it says file.exists, but it works for directories too! And the ! is for NOT
# So the above reads: If csv.path doesn't exist, create it.

csv.in.file = "csv/Example1.csv" # File plus full path
csv.file = "Example1.csv" # Just the file name
convert.to.csv(ppt.array.max, csv.in.file, island.grid)

# Placed AFTER .csv conversion to allow the .csv to be generated for manual conversion.
if (!file.exists(template.raster.file)){
  stop(sprintf("%s must exist. Please create one interpolation manually in ArcGIS per island to use as a template", template.raster.file))
}

# Convert FROM .csv to .tif using spatial interpolation
# template.raster 
tif.path = 'tif/'
if (!file.exists(tif.path)){dir.create(tif.path)}
template.raster = terra::rast(template.raster.file)
run.interpolation(csv.path, tif.path, csv.file, template.raster, n.neighbors = 12, power = 2) # base.path, 


### Example 2: Get the minimum value from all years for a selected point on the map
#**# Not scripted, but may be a useful feature
