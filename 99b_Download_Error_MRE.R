# This script will run fine on one computer (Windows 10, RStudio X.XX, R X.XX)
# and hang on the other computer (Windows 11, RStudio X.XX, R X.XX)
# on the Windows 11 computer, I tried turning off the firewall and running the script
# following these steps:
# XXXXX

# And it still did not work.

require(ncdf4)
data.file = "https://cida.usgs.gov/thredds/dodsC/kauai"

my.ncdf =ncdf4::nc_open(data.file)

start = 1
end = 1000
timesteps = end - start + 1 # +1 because it is inclusive of start
hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(-1,-1,timesteps))
#hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(1,1,timesteps)) #**# TESTING VERSION - USE CODE ABOVE ONCE WORKING PROPERLY
message(start)
message(end)
message(timesteps) # Should always be 1000, except at the very end

nc_close(my.ncdf)