# Set up shared settings for HI WRF data processing

# Created 2021-04-13

# Authors: A.C. Keyel <akeyel@albany.edu>

##### LOAD REQUIRED PACKAGES #####
library(ncdf4)

# Set Island (and timepoint for Hawaii/Maui)
island = 'oahu'
scenario = 'present'

# Get a list of desired variables (see files in shared folder from Lauren)
var.vec = c("T2_present", "T2_rcp45", "T2_rcp85")
#**# this will need to be adjusted for hawaii and maui

# Set years to download
first.year = 1
last.year = 20 

# Get a list of desired timescales (see file in shared folder from Lauren)
timescales = c('daily', 'monthly', 'annual')

# Indicator for whether .csv grid indices should be generated for each island (only needs to be done once)
make.grid = 0

# Identify data file
data.file = get.data.file(island, scenario)

# Need to adjust for GMT to Local time
# HI is GMT -10, so timestep 1 is 12:00 GMT
# So need to start at 11, not 1 to get 12:00 local time
TimeZone.Offset = 10
TimeZone.Label = "GMT-10"

#**# IS THIS A DEV SETTING? OR JUST A SHARED VARIABLE?
# January 1st 1990 and ends on December 31st 2009
# Identify leap years in the not-clever way, because I am tired
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.

