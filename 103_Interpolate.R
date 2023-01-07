## Goal is to take an input layer and convert it to the HI Rainfall atlas
# grid with minimal error.

# A.C. Keyel <akeyel@albany.edu>
# Created 2022-08-13

library(dplyr)

# Read in file of interest
load("C:/hawaii_local/Vars/oahu/RAINNC_present/DailyPPT/DailyPPT_RAINNC_year_1991")

# Use the WRF Grid index to convert grid indices into Lat/Lon
wrf.index = read.csv("C:/hawaii_local/xy_grid_index.csv")
wrf.index$join_index = sprintf("%s_%s", wrf.index$lat_index, wrf.index$lon_index)

# Reformat from array to a flat-file table format
# https://community.rstudio.com/t/fastest-way-to-convert-3d-array-to-matrix-or-data-frame/38398/5
#Error: 'as.tbl_cube' is not an exported object from 'namespace:dplyr'
#dimnames(day.ppt.array) = list("LAT" = sprintf("LAT%d", 1:dim(day.ppt.array)[1]),
#                               "LON" = sprintf("LON%d", 1:dim(day.ppt.array)[2]),
#                               "DAY" = sprintf("DAY%d", 1:dim(day.ppt.array)))
#test = dplyr::as.tbl_cube(day.ppt.array)
#test2 = as.tibble(test)

# Find a better test day
index.day = 1
best.value = 0
for (i in 1:365){
  
  test.value = sum(day.ppt.array[,,i], na.rm = TRUE)
  if (test.value > best.value){
    best.value = test.value
    index.day = i
  }
}

#**# TESTING WITH DAY 7 FOR NOW

# This is somewhat slow (1-3 s) and could likely be optimized
out.df = data.frame(COL.INDEX = NA, ROW.INDEX = NA, VALUE = NA, DAY = 7)
for (i in 1:dim(day.ppt.array)[1]){
  for (j in 1:dim(day.ppt.array)[2]){
    out.df = rbind(out.df, c(i, j, day.ppt.array[i,j,7], 7))
  }
}
out.df = out.df[2:nrow(out.df),]
out.df$join_index = sprintf("%s_%s", out.df$ROW.INDEX, out.df$COL.INDEX)

# Figure out error in join between out.df and wrf.index (only 5625 after merge.)

out.df2 = merge(out.df, wrf.index[ , c(2,3,6)])

# Create four data sets for testing and evaluation

criteria1 = out.df2$ROW.INDEX %% 2 == 0 & out.df2$COL.INDEX %% 2 == 0
base.set.1 = out.df2[!(criteria1), ]
test.set.1 = out.df2[criteria1, ]

write.table(base.set.1, file = "C:/hawaii_local/base_y2_d7_set1.csv",
            sep = ',', row.names = FALSE, col.names = TRUE)

write.table(test.set.1, file = "C:/hawaii_local/test_y2_d7_set1.csv",
            sep = ',', row.names = FALSE, col.names = TRUE)

# Interpolate
#day2 = day.ppt.array[ , , 2]

# GLM fit (don't bother - should not be a simple linear process)


# GAM fit
#**# SCRIPT, THIS SHOULD BE BETTER

#**# Change of plan - going to do IDW in ArcGIS to start, and calculate errors.

# Check error & report error statistics
# Jackknife error for known grid points across entire grid
# Can identify if there are hotspots where the interpolation is failing us.


# Read in Rainfall Atlas Grid file
rainfall.grid = read.csv("C:/hawaii_local/Rainfall_Atlas_Grid.csv")

# Finish interpolation by predicting for the Rainfall atlas




# Optional: Write output to raster file

# Scratch
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'
setwd(code.dir)
source("Workflow_hlpr.R")

island = 'oahu'
scenario = 'present'
data.file = get.data.file(island, scenario)
my.ncdf =ncdf4::nc_open(data.file)
# Says has 28 global attributes, but I don't know how to access these in R
ncatt_get(my.ncdf, 0) #**#HERE

ppt = ncvar_get(my.ncdf, "RAINNC_present", start = c(1,1,1), count = c(-1,-1, 1000))
nc_close(my.ncdf)


