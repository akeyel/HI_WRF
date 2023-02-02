
# source("100_DevSettings.R") #**# May need to change working directory
# setwd(data.dir)
# # Make a plot for Oliver to confirm that data are in local time, not GMT
# # 13 lat, 54 lon (so 54, 13 in R grid) is the Honolulu airport.
# load("T2_present_year_1.rda") # Loads the new.var object (509 MB)
# plot(seq(1,120), new.var[54,13,1:(24 * 5)])
# plot(seq(1,24), new.var[54,13,1:24])
# plot(seq(1,(24*31)), new.var[54,13,1:(24*31)])
# plot(seq(182,(182 +24*31)), new.var[54,13,182:(182 + 24*31)])
# lines(seq(182,(182 +24*31)), new.var[54,13,182:(182 + 24*31)])

library(ncdf4)
# Read 3D file (if you can)
setwd("C:/hawaii_local/3D_Files")
# Test file from Lauren
# wrfout_d01_2006-01-04_000000
test = nc_open('test')


this.var = ncvar_get(my.ncdf, in.var, start = c(row.index,col.index,start.time), count = c(1,1,time.steps))
