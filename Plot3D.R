# Goal is to make descriptive plots of the variables in the HI data set

# A.C. Keyel <akeyel@albany.edu>

library(ncdf4)

# Define focal variables
#in.dir = "D:/Science_Integrate/hawaii_local/3D_Files"
in.dir = "C:/hawaii_local/3D_FIles"
setwd(in.dir)

in.files = list.files(path = in.dir)
focal.vars = c("QVAPOR", "QCLOUD", "T2", "RAINNC", "I_RAINNC", "SMOIS",
               "U", "V", "W", "T","TSLB", "HGT", "DFGDP")
var.dim.vec = c(4,4,3,3,3,4,4,4,4,4,4,3,3)

#**# Add the fog deposition variables to the list. Also, add P and PB
#**# Add PH and PHB for geopotential height
#**# Add these back to Extract3D.R

# pick a focal file (or can loop over files if desired)
my.c = nc_open(in.files[2])


for (i in 1:length(focal.vars)){
  
  this.var = focal.vars[i]
  this.dim = var.dim.vec[i]
  pdf(file = sprintf("pdfs/%s_DescriptivePlots.pdf", this.var))
  
  start = c(1,1,1,1)
  #count = c(-1,-1,-1,-1) #**# use 2,2,2,2 when testing - will go faster
  count = c(10,10,10,10)
  if (this.var == "SMOIS" | this.var == "TSLB"){ count[3] = 4}
  start = start[1:this.dim]
  count = count[1:this.dim]
  
  var.vals = ncvar_get(my.c, this.var, start = start, count = count)
  var.dims = dim(var.vals)
  
  # Spot check for different times of day
  x.checks = c(1,50,100,150,200,250)
  y.checks = c(1,50,100,150,200,250)
  time.checks = c(1,6,12,18,24)
  level.checks = c(1,10,20,30,40,50) #**# What was the maximum? I think it was 50.

  #**# Fix - used for testing purposes
  x.checks = c(1,5,10)
  y.checks = c(1,5,10)
  time.checks = c(1,5,10)
  level.checks = c(1,5,10)
  
  if (this.var == "SMOIS" | this.var == "TSLB"){
    level.checks = c(1,2,4)
  }
  
  if (this.dim == 3){level.checks = c(1)}
  
  for (time.check in time.checks){
    # Plot variables spatially (x,y)
    #**# How many plots to do? 
    for (level.check in level.checks){
      if (this.dim == 4){  image(var.vals[,,level.check,time.check])  }
      if (this.dim == 3){  image(var.vals[,,time.check])    }
      mtext(side = 3, sprintf("%s time %s level %s", this.var, time.check, level.check))    
    }
  }
  
  for (x.check in x.checks){
    for (y.check in y.checks){
      # Plot variables temporally (time values for a given x,y)
      for (level.check in level.checks){
        if (this.dim == 4){
          plot(seq(1:var.dims[4]), var.vals[x.check,y.check,level.check ,])
        }
        if (this.dim == 3){
          plot(seq(1:var.dims[3]), var.vals[x.check,y.check, ])
        }
        mtext(side = 3, sprintf("%s x y %s %s, level %s", this.var, x.check, y.check, level.check))    
      }
      # Plot variables vertically (z values for a given x,y)
      if (this.dim == 4){
        for (time.check in time.checks){
          plot(seq(1,var.dims[3]), var.vals[x.check, y.check, , time.check])
          mtext(side = 3, sprintf("%s x y %s %s, time %s", this.var, x.check, y.check, time.check))    
        }  
      }
    }
  }
  dev.off()
  
}

#**# Do something with maximum and minimum values. Think of a good way to put those into the pdf - not sure if there are text or table commands that would work


nc_close(my.c)

#**# Consider adding map insets to show where the plot is coming from (probably more than I need to do, but it's an idea)