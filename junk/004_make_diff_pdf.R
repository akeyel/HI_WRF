# Goal of this script is to put 3 panels on a page: WRF rainfall, HI Rainfall atlas, and difference

#**# FAILED. TRY AGAIN LATER, perhaps with a pre-processing step to make the rasters integers.

# Biggest problem will be with scale bars I think.
setwd("C:/hawaii_local/Vars/oahu/RAINNC_present/Climatology")

img = tiff::readTIFF("RAINNC_Annual.tif")
grid::grid.raster(img) # Didn't work
 
image(img) # Weird Transpose
image(t(img)) # Weirder transpose
#image(raster::rotate(image)) # didn't work, not a raster!
plot(img) # line, not sure why

b = raster::brick("RAINNC_Annual.tif")
#image(b) # didn't work, not a matrix
raster::plotRGB(b) # Didn't work.

img = readTIFF('RAINNC_Annual.tif', native=TRUE)
plot(NA,xlim=c(0,nrow(img)),ylim=c(0,ncol(img)))
rasterImage(img,0,0,nrow(img),ncol(img))

# Ah. The FLOAT is tripping up the normal raster image dispaly options.