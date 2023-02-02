# Code modified based on the RSpatial tutorial here:
# https://rspatial.org/analysis/4-interpolation.html
# Cite rspat, gstat, and terra packages for this
# can also cite caret, but the RMSE calculation there is functionally identical to the one presented in the tutorial.

# Also this tutorial for saving the file:
# https://rspatial.org/spatial-terra/5-files.html

if (!require("rspat")) remotes::install_github('rspatial/rspat')
library(caret) # Used for RMSE calculation
library(gstat)

#**# LEFT OFF HERE - ADD PSEUDO-CODE AND THEN FILL IN PIECES.

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
run.interpolation = function(base.path, in.csv, template.raster, n.neighbors = 12, power = 2){
  # Setup stuff
  setwd(base.path)
  tif.path = "tifs/"
  if (!file.exists(tif.path)){  dir.create(tif.path)  }
  
  # Read in .csv file
  rainnc = read.csv(in.csv)
  rsp = vect(rainnc, c('lon', 'lat'), crs = "+proj=longlat +datum=WGS84")
  r = data.frame(geom(rsp)[, c('x','y')], as.data.frame(rsp)) #**# I feel like this just undid what was done above. Could we have started with rainnc? In the tutorial, they change the projection, so that's why they do it there. Here, I'm seeing if it'll work with Lat/Lon
  
  # Create the model object
  gs = gstat(formula=values~1, locations = ~x+y, data = r, nmax = n.neighbors, set = list(idp = power))
  
  # Use the template raster to guide the interpolation extent/resolution
  nn = interpolate(template.raster, gs, debug.level = 0)
  in.csv.base = substr(in.csv, 1, nchar(in.csv) - 4) # Scrub off the file extension
  out.file = sprintf("%s%s.tif", tif.path, in.csv.base)
  x <- writeRaster(nn, out.file, overwrite=TRUE)
  # Done!
}


# Test for Maui's annual climatology
base.path = "F:/hawaii_local/Vars/maui/RAINNC_present/Climatology"
setwd(base.path)

load("RAINNC_Annual.rda") #**# trying .csv approach first.

rainnc = read.csv("RAINNC_Annual.csv")

maui.shp = "F:/hawaii_local/GIS/maui/maui_ne_rfa.shp"
hi = vect(maui.shp)
hi.raster = rast(hi, res = 10000)
maui.template.file = "F:/hawaii_local/Vars/maui/RAINNC_present/Climatology/RAINNC_Annual.tif"
maui.raster = rast(maui.template.file)
plot(maui.raster, 1)
#**# LEFT OFF HERE - USING maui.raster to see if that will work better than the hi.raster, which was clipped.

rsp = vect(rainnc, c('lon', 'lat'), crs = "+proj=longlat +datum=WGS84")
#**# May want to get county outlines of HI (I feel like I have them somewhere!)
r = data.frame(geom(rsp)[, c('x','y')], as.data.frame(rsp)) #**# I feel like this just undid what was done above. Could we have started with rainnc? In the tutorial, they change the projection, so that's why they do it there. Here, I'm seeing if it'll work with Lat/Lon
gs = gstat(formula=values~1, locations = ~x+y, data = r, nmax = 5, set = list(idp = 0))
nn = interpolate(maui.raster, gs, debug.level = 0)
#Use a interpolated template that was already snapped to the rainfall atlas, but was not cropped to its extent.
#nnmsk = mask(nn, vr) #**# what was vr? Looks like it was a previous output, used here as a mask
#plot(nnmsk, 1)
plot(nn, 1)

test = maui.raster - nn
plot(test,1)


gs2 = gstat(formula=values~1, locations = ~x+y, data = r, nmax = 12, set = list(idp = 2))
nn2 = interpolate(maui.raster, gs2, debug.level = 0)
plot(nn2, 1)

test2 = maui.raster - nn2
plot(test2, 1)

test3 = nn - nn2
plot(test3, 1)

vr <- rasterize(vca, r, "prec")
plot(vr)


#**# So... before we can run the interpolation, we need a baseline raster.
# Should be able to read in the HI Rainfall atlas here?
# Or should I try it starting from a county outline, since that is what they do? Maybe start there? And THEN try to patch in the HI Rainfall atlas?

d <- data.frame(geom(dta)[,c("x", "y")], as.data.frame(dta))
head(d)
gs <- gstat(formula=prec~1, locations=~x+y, data=d, nmax=5, set=list(idp = 0))
nn <- interpolate(r, gs, debug.level=0)
nnmsk <- mask(nn, vr)
plot(nnmsk, 1)

rmsenn <- rep(NA, 5)
for (k in 1:5) {
  test <- d[kf == k, ]
  train <- d[kf != k, ]
  gscv <- gstat(formula=prec~1, locations=~x+y, data=train, nmax=5, set=list(idp = 0))
  p <- predict(gscv, test, debug.level=0)$var1.pred
  rmsenn[k] <- RMSE(test$prec, p)
}
rmsenn


#**# Do we want another projection for interpolation? I feel like I may have done that for ArcGIS?


##### FROM TUTORIAL ######
if (!require("rspat")) remotes::install_github('rspatial/rspat')
library(gstat)
d <- spat_data('precipitation')
head(d)

mnts <- toupper(month.abb)
d$prec <- rowSums(d[, mnts])
plot(sort(d$prec), ylab="Annual precipitation (mm)", las=1, xlab="Stations")

dsp <- vect(d, c("LONG", "LAT"), crs="+proj=longlat +datum=NAD83")
CA <- spat_data("counties")
# define groups for mapping
cuts <- c(0,200,300,500,1000,3000)
# set up a palette of interpolated colors
blues <- colorRampPalette(c('yellow', 'orange', 'blue', 'dark blue'))
plot(CA, col="light gray", lwd=4, border="dark gray")
plot(dsp, "prec", type="interval", col=blues(10), legend=TRUE, cex=2,
     breaks=cuts, add=TRUE, plg=list(x=-117.27, y=41.54))
lines(CA)

TA <- "+proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=WGS84 +units=m"
dta <- project(dsp, TA)
cata <- project(CA, TA)

RMSE <- function(observed, predicted) {
  sqrt(mean((predicted - observed)^2, na.rm=TRUE))
}
null <- RMSE(mean(dsp$prec), dsp$prec)
null

v <- voronoi(dta)
plot(v)
points(dta)

vca <- crop(v, cata)
plot(vca, "prec")
r <- rast(vca, res=10000)
vr <- rasterize(vca, r, "prec")
plot(vr)

set.seed(5132015)
kf <- sample(1:5, nrow(dta), replace=TRUE)
rmse <- rep(NA, 5)
for (k in 1:5) {
  test <- dta[kf == k, ]
  train <- dta[kf != k, ]
  v <- voronoi(train)
  p <- extract(v, test)
  rmse[k] <- RMSE(test$prec, p$prec)
}
rmse
## [1] 192.0568 203.1304 183.5556 177.5523 205.6921
mean(rmse)
## [1] 192.3974
# relative model performance
perf <- 1 - (mean(rmse) / null)
round(perf, 3)
## [1] 0.558

library(gstat)
d <- data.frame(geom(dta)[,c("x", "y")], as.data.frame(dta))
head(d)
gs <- gstat(formula=prec~1, locations=~x+y, data=d, nmax=5, set=list(idp = 0))
nn <- interpolate(r, gs, debug.level=0)
nnmsk <- mask(nn, vr)
plot(nnmsk, 1)

rmsenn <- rep(NA, 5)
for (k in 1:5) {
  test <- d[kf == k, ]
  train <- d[kf != k, ]
  gscv <- gstat(formula=prec~1, locations=~x+y, data=train, nmax=5, set=list(idp = 0))
  p <- predict(gscv, test, debug.level=0)$var1.pred
  rmsenn[k] <- RMSE(test$prec, p)
}
rmsenn
## [1] 215.0993 209.5838 197.0604 177.1946 189.8130
mean(rmsenn)
## [1] 197.7502
1 - (mean(rmsenn) / null)

library(gstat)
gs <- gstat(formula=prec~1, locations=~x+y, data=d)
idw <- interpolate(r, gs, debug.level=0)
idwr <- mask(idw, vr)
plot(idwr, 1)

rmse <- rep(NA, 5)
for (k in 1:5) {
  test <- d[kf == k, ]
  train <- d[kf != k, ]
  gs <- gstat(formula=prec~1, locations=~x+y, data=train)
  p <- predict(gs, test, debug.level=0)
  rmse[k] <- RMSE(test$prec, p$var1.pred)
}
rmse
## [1] 243.3255 212.6270 206.8982 180.1829 207.5789
mean(rmse)
## [1] 210.1225
1 - (mean(rmse) / null)

# [ #**# SKIPPED KRIGING: NOT READY TO TRY INCLUDING COVARIATES INTO THE INTERPOLATION AT THIS STAGE ]
# Actually all of the remaining is on a different data set, so skipped the rest of the tutorial for now. But can come back to it.


