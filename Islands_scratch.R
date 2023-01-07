# Try to test out reading other on-line files

library(ncdf4)
setwd("C:/hawaii_local")

# For Kauai
data.file = "https://cida.usgs.gov/thredds/dodsC/kauai"
kauai =ncdf4::nc_open(data.file)


print(kauai)
length(kauai$dim$Time$vals)
#175320

kauai$var$T2_present$varsize # 82 64 175320

dim1 = kauai$var$T2_present$varsize[1]
dim2 = kauai$var$T2_present$varsize[2]

# Create a simple data frame to store the grid # Just take first entry to be arbitrary 
vals = ncvar_get(kauai, "T2_present", start = c(1,1,1), count = c(dim1,dim2,1))
lat = ncvar_get(kauai, "XLAT", start = c(1,1), count = c(dim1,dim2))
lon = ncvar_get(kauai, "XLONG", start = c(1,1), count = c(dim1,dim2))
xy.grid = data.frame(values = matrix(vals, ncol = 1), lat = matrix(lat, ncol = 1),
                     lon = matrix(lon, ncol = 1),
                     lat_index = sort(rep(seq(1,dim2), dim1)), lon_index = rep(seq(1,dim1), dim2))


write.table(xy.grid, file = "kauai_xy_grid_index.csv", sep = ',', row.names = FALSE, col.names = TRUE,
            append = FALSE)

nc_close(kauai)
warning("GRID STILL NEEDS TO BE CHECKED FOR ACCURACY!!!")
# OK. Now try Maui and Hawaii

# Separate files for present, RCP 4.5, and RCP 8.5
place.labels = c("hawaii", "maui")
time.labels = c("present", "rcp45", "rcp85")

for (place.label in place.labels){
  # This probably doesn't need to be looped across time, just place
  # Should all use the same grid, otherwise it's not really going to work very well.
  time.label = time.labels[1]
  #for (time.label in time.labels){
    data.file = sprintf("https://cida.usgs.gov/thredds/dodsC/hawaii_%s_%s", place.label, time.label)
    my.ncdf =ncdf4::nc_open(data.file)
    
    
    #names(my.ncdf$var) # for Hawaii Present
    #[1] "HGT"      "LANDMASK" "XLAT"     "XLONG"    "CFRACL"   "CFRACT"   "FGDP"     "GLW"      "GRDFLX"   "GSW"      "HFX"     
    #[12] "I_RAINNC" "LAI"      "LH"       "LU_INDEX" "LWP"      "PSFC"     "Q2"       "RAINNC"   "SNOW"     "SNOWC"    "SNOWH"   
    #[23] "T2"       "TSK"      "U10"      "V10" 
    my.ncdf$var$T2_present$varsize # 180 205 175296 # Why is this 24 timesteps shorter?
    
    dim1 = my.ncdf$var$T2$varsize[1]
    dim2 = my.ncdf$var$T2$varsize[2]
    
    # Create a simple data frame to store the grid # Just take first entry to be arbitrary 
    vals = ncvar_get(my.ncdf, "T2", start = c(1,1,1), count = c(dim1,dim2,1))
    lat = ncvar_get(my.ncdf, "XLAT", start = c(1,1), count = c(dim1,dim2))
    lon = ncvar_get(my.ncdf, "XLONG", start = c(1,1), count = c(dim1,dim2))
    xy.grid = data.frame(values = matrix(vals, ncol = 1), lat = matrix(lat, ncol = 1),
                         lon = matrix(lon, ncol = 1),
                         lat_index = sort(rep(seq(1,dim2), dim1)), lon_index = rep(seq(1,dim1), dim2))
    
    
    write.table(xy.grid, file = sprintf("%s_xy_grid_index.csv", place.label),
                sep = ',', row.names = FALSE, col.names = TRUE,
                append = FALSE)
    
    
    nc_close(my.ncdf)
}

