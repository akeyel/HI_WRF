# Set up shared settings for HI WRF data processing

# Created 2021-04-13

# Authors: A.C. Keyel <akeyel@albany.edu>

##### LOAD REQUIRED PACKAGES #####
library(ncdf4)


setwd(code.dir)
source("Workflow_hlpr.R")

# Set Island (and timepoint for Hawaii/Maui)
scenario = 'present' #**# FLAG - needed for HI

# Get a list of desired variables (see files in shared folder from Lauren)
#var.vec = c("RAINNC_present", "RAINNC_rcp45", "RAINNC_rcp85")
#if (island == "maui" | island == "hawaii"){
#  var.vec = c("RAINNC")
#}

timesteps = c("present", "rcp45", "rcp85")

# , "RAIN_rcp45", "RAIN_rcp85", , "I_RAINNC"

#**# this will need to be adjusted for hawaii and maui

is.ppt = 1

# Set years to download
#**# For now, just testing with 5 years to get the code running properly
first.year = 1
last.year = 20 

# Get a list of desired timescales (see file in shared folder from Lauren)
timescales = c('daily', 'monthly', 'annual')

# Indicator for whether .csv grid indices should be generated for each island (only needs to be done once)
make.grid = 0

# Identify data file
#data.file = get.data.file(island, scenario)

# Need to adjust for GMT to Local time
# HI is GMT -10, so timestep 1 is 12:00 GMT
# So need to start at 11, not 1 to get 12:00 local time
GMT.offset = 10
TimeZone.Label = "GMT-10"

#**# IS THIS A DEV SETTING? OR JUST A SHARED VARIABLE?
# January 1st 1990 and ends on December 31st 2009
# Identify leap years in the not-clever way, because I am tired
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.

