# Set up shared settings for HI WRF data processing

# Created 2021-04-13

# Authors: A.C. Keyel <akeyel@albany.edu>

##### LOAD REQUIRED PACKAGES #####
library(ncdf4)

# Code Directory
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'

source(sprintf("%s/workflow_hlpr.R",  code.dir))

# Data Directory
data.dir = "C:/hawaii_local"

# Set Island (and timepoint for Hawaii/Maui)
island = 'oahu'
scenario = 'present'

# Get a list of desired variables (see files in shared folder from Lauren)
var.vec = c("T2_present")

# Set years to download
#**# To start, just look at one year
first.year = 9 #1 #13 # Crashed mid-processing
last.year =  12 #13 

# Get a list of desired timescales (see file in shared folder from Lauren)
timescales = c('monthly', 'annual')

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

