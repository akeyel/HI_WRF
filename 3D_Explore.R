# 3D Explore

# Oliver requested quick plots of mapfac and other adjustment variables
library(ncdf4)
library(terra)

my.dir = "F:/hawaii_local/3D_Files/wrfout_d01_2006-01-03_000000"
test = nc_open(my.dir)


vars = c("MAPFAC_M", "MAPFAC_U", "MAPFAC_V", "MAPFAC_MX", "MAPFAC_MY",
         "MAPFAC_UX", "MAPFAC_UY", "MAPFAC_VX", "MF_VX_INV", "MAPFAC_VY",
         "SINALPHA","COSALPHA")

pdf("F:/hawaii_local/3D_Files/pdfs/mapfac.pdf")

# Run for T2 to get outline of islands and confirm that image is working as expected
t2 = ncvar_get(test, "T2")
image(t2[,,1]) # This is the image function from terra.
mtext("T2 for orientation")

for (var in vars){
  this.var = ncvar_get(test, var)
  #message(var)
  #message(paste(dim(this.var), collapse = ' '))
  first = this.var[,,i]
  first.test = paste(first, collapse = "")
  image(first)
  mtext(sprintf("%s layer 1; dim: %s", var, i, paste(dim(this.var), collapse = " ")), line = 2)
  mtext(sprintf("min: %s max: %s",  min(first), max(first)), line = 1)
  
  for (i in 2:dim(this.var)[3]){
    var.test = paste(this.var[,,i], collapse = "")
    if (var.test != first.test){
      image(this.var[,,i]) # constant in first dimension # uses terra's image, so hopefully not transposing it?
      mtext(sprintf("%s layer %s; dim: %s", var, i, paste(dim(this.var), collapse = " ")))
    }
  }
}


dev.off()

nc_close(test)
