# Set up shared settings for HI WRF data processing

# Created 2021-05-13

# Authors: A.C. Keyel <akeyel@albany.edu>

##### LOAD REQUIRED PACKAGES #####
library(ncdf4)

# Code Directory
code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'

# Data Directory
data.dir = "C:/hawaii_local"

setwd(code.dir)
source("Workflow_hlpr.R")

#**# CHANGE THIS
# Set years to download
first.year = 1
last.year = 20 #20 #**# FOR INITIAL TEST TO SEE IF IT WORKS 

#**# CHANGE TO FULL SUITE - CHECKING ONE FROM EACH FORMAT FOR COMPATIBILITY
#islands = c('oahu', 'kauai', 'hawaii', 'maui')
islands = c('oahu', 'kauai') #, 'hawaii')

# Set Island (and timepoint for Hawaii/Maui)
#island = 'oahu'
#scenario = 'present'
#scenarios = c('present', 'rcp45', 'rcp85')
scenarios = c('present') # Do not need to run for 3 scenarios, since each scenario is a variable for Oauh and Kauai. Need to Change this for Hawaii and Maui.

# Get a list of desired timescales (see file in shared folder from Lauren)
timescales = c('monthly', 'annual')

# Indicator for whether .csv grid indices should be generated for each island (only needs to be done once)
make.grid = 0

# Need to adjust for GMT to Local time
# HI is GMT -10, so timestep 1 is 12:00 GMT
# So need to start at 11, not 1 to get 12:00 local time
TimeZone.Offset = 10
TimeZone.Label = "GMT-10"

# January 1st 1990 and ends on December 31st 2009
# Identify leap years in the not-clever way, because I am tired
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.

start.time = Sys.time()
# Identify data file
data.files = c()
for (island in islands){
  message(island)
  for (scenario in scenarios){
    message(scenario)
    if (island == "oahu" | island == "kauai"){
      var.vec = c("T2_present", "T2_rcp45", "T2_rcp85", "RAIN_present", "RAINNC_present", "RAIN_rcp45", "RAINNC_rcp45", "RAIN_rcp85", "RAINNC_rcp85", "I_RAINNC")
    }else{
      var.vec = c("T2", "RAIN", "RAINNC")
    }
    
    data.file = get.data.file(island, scenario)
    #data.files = c(data.files, data.file)
    
    # Extract this set of data
    source(sprintf('%s/001_ExtractAnnual.R', code.dir))
  }
}

end.time = Sys.time()
elapsed.time = end.time - start.time