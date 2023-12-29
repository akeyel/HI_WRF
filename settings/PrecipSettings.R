# Set up shared settings for HI WRF data processing

# Created 2021-04-13

# Authors: A.C. Keyel <akeyel@albany.edu>

##### LOAD REQUIRED PACKAGES #####
library(ncdf4)

timesteps = c("present", "rcp45", "rcp85")
is.ppt = 1

# Set years to download
first.year = 1
last.year = 20 

# Get a list of desired timescales (see file in shared folder from Lauren)
timescales = c('daily', 'monthly', 'annual')

# Indicator for whether .csv grid indices should be generated for each island (only needs to be done once)
make.grid = 0
download.data = 0
interpolate.day = 0
extract.variables = 0
do.corrections = 0
create.aggregates = 0
climatology.to.raster = 0


# Need to adjust for GMT to Local time
# HI is GMT -10, so timestep 1 is 12:00 GMT
# So need to start at 11, not 1 to get 12:00 local time
GMT.offset = 10
TimeZone.Label = "GMT-10"

# January 1st 1990 and ends on December 31st 2009
# Identify leap years
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.

