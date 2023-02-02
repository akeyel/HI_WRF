# Code modified based on the RSpatial tutorial here:
# https://rspatial.org/analysis/4-interpolation.html
# Cite rspat, gstat, and terra packages for this
# can also cite caret, but the RMSE calculation there is functionally identical to the one presented in the tutorial.

# Also this tutorial for saving the file:
# https://rspatial.org/spatial-terra/5-files.html

if (!require("rspat")) remotes::install_github('rspatial/rspat')
library(caret) # Used for RMSE calculation
library(gstat)

#base.path = "F:/hawaii_local/Vars/maui/RAINNC_present/Climatology"
#in.csv = "RAINNC_Annual.csv"
#maui.template.file = "F:/hawaii_local/Vars/maui/RAINNC_present/Climatology/RAINNC_Annual.tif"
#template.raster = rast(maui.template.file)

#' Define a function to aggregate the interpolation steps
#' 
#' @param base.path the path containing the in.csv
#' @param in.csv the csv with values to be interpolated
#' @param template.raster A template for grid and spacing information. Use ArcGIS interpolated .tif snapped to the HI Rainfall atlas data
#' Needs to have the extent of the WRF data, so cannot use the clipped rainfall atlas files.
#' @param n.neighbors the number of neighboring points to use. ArcGIS defaults to 12, so this defaults to 12 to match
#' @param power The power to use. A standard IDW drops off with distance squared.
#' 
run.interpolation = function(csv.path, tif.path, in.csv, template.raster, n.neighbors = 12, power = 2){
  # Setup stuff
  #setwd(base.path)
  #tif.path = sprintf("%s/tif", base.path)
  
  #tif.path = "tifs/"
  if (!file.exists(tif.path)){  dir.create(tif.path)  }
  
  # Read in .csv file
  rainnc = read.csv(sprintf("%s/%s", csv.path, in.csv))
  rsp = vect(rainnc, c('lon', 'lat'), crs = "+proj=longlat +datum=WGS84")
  r = data.frame(geom(rsp)[, c('x','y')], as.data.frame(rsp)) #**# I feel like this just undid what was done above. Could we have started with rainnc? In the tutorial, they change the projection, so that's why they do it there. Here, I'm seeing if it'll work with Lat/Lon
  
  # Create the model object
  gs = gstat(formula=values~1, locations = ~x+y, data = r, nmax = n.neighbors, set = list(idp = power))
  
  # Use the template raster to guide the interpolation extent/resolution
  nn = interpolate(template.raster, gs, debug.level = 0)
  in.csv.base = substr(in.csv, 1, nchar(in.csv) - 4) # Scrub off the file extension
  out.file = sprintf("%s/%s.tif", tif.path, in.csv.base)
  x <- writeRaster(nn[[1]], out.file, overwrite=TRUE) # [[1]] makes it a single band raster with the interpolated values
  # Done!
}

