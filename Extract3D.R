# Extract variables of interest from 3D data distributed over multiple hard drives

# Author: A.C. Keyel <akeyel@albany.edu>
# Created 2022-12-01
library(ncdf4)

# Identify a directory
#in.dir = "D:/Science_Integrate/hawaii_local/3D_Files"
#out.dir = "D:/Science_Integrate/hawaii_local/3D_Extract"
in.dir = "F:/hawaii_local/3D_Files"
out.dir = "F:/hawaii_local/3D_Extract"
setwd(in.dir)

# Read in file names of all files in this directory
in.files = list.files(path = in.dir)
focal.vars = c("QVAPOR", "QCLOUD", "T2", "RAINNC", "I_RAINNC", "SMOIS", "U", "V", "W", "T","TSLB", "HGT")
var.dim.vec = c(4,4,3,3,3,4,4,4,4,4,4,3)
#**# Add P and PH? OTHERS?

scenario = "unknown" #**# Fix when we know. Is this coded in d01?

# Try getting Lat/Lon to make grid for export and joins
#**# LOOK UP HOW I DID THIS WITH THE MAKE GRID THE LAST TIME.
if (make.grid == 1){
  #**# REDO USING HGT instead of temperature - should be much clearer.
  #**# NO - it's worse, go back to T or pick a different variable.
  grid.file = "C:/hawaii_local/Vars/grids/wrf_grids/3d_grid_2.csv"
  my.file = in.files[1]
  my.c = nc_open(my.file)
  dim1 = my.c$var$HGT$varsize[1]
  dim2 = my.c$var$HGT$varsize[2]
  
  vals = ncvar_get(my.c, "HGT", start = c(1,1,1), count = c(-1,-1,1)) 
  lat = ncvar_get(my.c, "XLAT", start = c(1,1,1), count = c(-1,-1, 1)) #**# Why does this have 3 dimensions??? Probably to accommodate the vertical dimension
  lon = ncvar_get(my.c, "XLONG", start = c(1,1,1), count = c(-1,-1,1)) #**# Why does this have 3 dimensions?
  xy.grid = data.frame(values = matrix(vals, ncol = 1), lat = matrix(lat, ncol = 1),
                       lon = matrix(lon, ncol = 1),
                       lat_index = sort(rep(seq(1,dim2), dim1)), lon_index = rep(seq(1,dim1), dim2))
  
  write.table(xy.grid, file = grid.file, sep = ',', row.names = FALSE, col.names = TRUE,
              append = FALSE)
  nc_close(my.c)
}


start.time = Sys.time()
# Loop through files
for (my.file in in.files){

  date = substr(my.file, 12,21)
  
  # Open file
  my.c = nc_open(my.file)
  
  # Loop through variables
  for (i in 1:length(focal.vars)){
    var = focal.vars[i]
    var.dim = var.dim.vec[i]
    start = c(1,1,1,1)
    count = c(-1,-1,-1,-1) #**# use 2,2,2,2 when testing - will go faster
    start = start[1:var.dim] #**# Will need to adjust if need to put actual numbers here
    count = count[1:var.dim] #**# Will need to adjust this if need to put actual numbers in a particular order here.
    # Extract each variable into a temporary file
    this.var = ncvar_get(my.c, var, start = start, count = count) 
    out.file = sprintf("%s/%s_%s_%s_dim%s.rda", out.dir, scenario, date, var, length(start))
    save(this.var, file = out.file)
  }
  
  nc_close(my.c)
    
} # End loop over files

elapsed.time = Sys.time() - start.time
print(elapsed.time)
# Loop through variables again

# Merge temporary files into a single file for each year
#**# Do this at the end after all hard-drives have been extracted from?
# (for now, do based on GMT - can do a second extraction to adjust to HI time)


#**# NEED TO CONVERT VARIABLES - MAY REQUIRE OTHER VARIABLES
#**# NEED TO GET UNITS FOR EVERYTHING
# Still need to find lower level for simulation run

# For Han Tseng
# Cloud-water interception test
# Pick an example x,y location
#**# LEFT OFF HERE

