# Code modified based on the RSpatial tutorial here:
# https://rspatial.org/analysis/4-interpolation.html
# Cite rspat, gstat, and terra packages for this
# can also cite caret, but the RMSE calculation there is functionally identical to the one presented in the tutorial.

# Also this tutorial for saving the file:
# https://rspatial.org/spatial-terra/5-files.html

#if (!require("rspat")) remotes::install_github('rspatial/rspat')
library(terra)
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
run.interpolation = function(csv.path, tif.path, in.csv, template.raster, n.neighbors = 12, power = 2, to.integer = 0){
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
  #out.file = sprintf("%s/%s_test2.tif", tif.path, in.csv.base)
  if (to.integer == 0){
    # Save with full data resolution
    x <- writeRaster(nn[[1]], out.file, overwrite=TRUE) # [[1]] makes it a single band raster with the interpolated values
  }else{
    # Save as a 4byte unsigned integer to make the file size smaller
    out.rast = round(nn[[1]]*100, 0)
    x <- writeRaster(out.rast, out.file, overwrite=TRUE, datatype = "INT4U") # [[1]] makes it a single band raster with the interpolated values
  }
  # Done!
}


#' Function to check that tifs are valid raster files that can be read and manipulated
#'
#' There was a problem where several files from Hawaii and one from Maui were corrupted as integer tifs and would not open.
#' This script is intended to check that all files have opened and worked properly.
#' 
check.raster.tifs = function(in.dir){
  require(terra)
  # in.dir = "F:/hawaii_local/Supporting/check_raster_tifs_test"
  my.folders = list.files(in.dir)
  
  bad.files = c()
  for (folder in my.folders){
    my.files = list.files(sprintf("%s/%s", in.dir, folder))
    for (my.file in my.files){
      is.bad = 1
      
      out = tryCatch({
        max(rast(sprintf("%s/%s/%s", in.dir, folder, my.file)))
        is.bad = 0
      },
      error = function(cond){
        return(NA)
      },
      warning = function(cond){
        return(NA)
      })
      if (is.bad == 1){
        bad.files = c(bad.files, my.file)
      }
    }
  }
  return(bad.files)
}


