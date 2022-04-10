# Goal is to create a script to describe the desired HI workflow for WRF model
# data processing. First step is to generate pseudo-code, to lay out the steps,
# and make it easier to fill in the details

# Created 2021-12-14

# Authors: A.C. Keyel <akeyel@albany.edu> #**# Add others as needed. Need to think
# about how to acknowledge those who don't provide code, but do provide input
# about what should be coded!

##### LOAD REQUIRED PACKAGES #####
library(ncdf4)
setwd("C:/hawaii_local")
source('C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/Hawaii/Workflow_hlpr.R')

##### Process data from web-available sources ######

# https://cida.usgs.gov/thredds/ncss/oahu/dataset.html
# Testing T2 for present, Rcp4.5 and RCP 8.5 from CIDA THREADS

# URL from the webpage - may be able to use this to be more systematic
# https://cida.usgs.gov/thredds/ncss/oahu?var=T2_present&var=T2_rcp45&var=T2_rcp85&disableLLSubset=on&disableProjSubset=on&horizStride=1&time_start=1990-01-01T00%3A00%3A00Z&time_end=2009-12-31T23%3A00%3A00Z&timeStride=1


data.file = "https://cida.usgs.gov/thredds/dodsC/oahu"

my.ncdf =ncdf4::nc_open(data.file)
#names(my.ncdf$var)
#[1] "ACLHF_present"  "XLAT"           "XLONG"          "Times"          "time_bnds"      "ALBBCK_present"
#[7] "ALBEDO_present" "GLW_present"    "HFX_present"    "LH_present"     "OLR_present"    "PSFC_present"  
#[13] "Q2_present"     "QFX_present"    "RAIN_present"   "I_RAINNC"       "RAINNC_present" "SFROFF_present"
#[19] "SMOIS_present"  "DZS"            "SNOW_present"   "SNOWH_present"  "T2_present"     "TH2_present"   
#[25] "Times_present"  "XTIME"          "TSLB_present"   "U10_present"    "UDROFF_present" "V10_present"   
#[31] "VEGFRA_present" "ACLHF_rcp45"    "ALBBCK_rcp45"   "ALBEDO_rcp45"   "GLW_rcp45"      "HFX_rcp45"     
#[37] "LH_rcp45"       "OLR_rcp45"      "PSFC_rcp45"     "Q2_rcp45"       "QFX_rcp45"      "RAIN_rcp45"    
#[43] "RAINNC_rcp45"   "SFROFF_rcp45"   "SMOIS_rcp45"    "SNOW_rcp45"     "SNOWH_rcp45"    "T2_rcp45"      
#[49] "TH2_rcp45"      "Times_rcp45"    "TSLB_rcp45"     "U10_rcp45"      "UDROFF_rcp45"   "V10_rcp45"     
#[55] "VEGFRA_rcp45"   "ACLHF_rcp85"    "ALBBCK_rcp85"   "ALBEDO_rcp85"   "GLW_rcp85"      "HFX_rcp85"     
#[61] "LH_rcp85"       "OLR_rcp85"      "PSFC_rcp85"     "Q2_rcp85"       "QFX_rcp85"      "RAIN_rcp85"    
#[67] "RAINNC_rcp85"   "SFROFF_rcp85"   "SMOIS_rcp85"    "SNOW_rcp85"     "SNOWH_rcp85"    "T2_rcp85"      
#[73] "TH2_rcp85"      "Times_rcp85"    "TSLB_rcp85"     "U10_rcp85"      "UDROFF_rcp85"   "V10_rcp85"     
#[79] "VEGFRA_rcp85"

print(my.ncdf) # This shows the associated metadata

# January 1st 1990 and ends on December 31st 2009
# Identify leap years in the not-clever way, because I am tired
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.


length(my.ncdf$dim$Time$vals)
#[1] 175320
years = length(my.ncdf$dim$Time$vals) / (365 * 24)
years # 20.0137 (because it doesn't account for leap years yet)
# Single file is 2.6 MB for one time step for everything
# ~455 GB for entire file
# individual variables are ~9 GB

# Check time variable #**# In minutes, so doesn't answer the GMT question
#new.var = ncvar_get(my.ncdf, "XTIME", start = c(1,1,1), count = c(-1,-1,34))
#test = ncvar_get(my.ncdf, "DZS") # This only has four values, does not seem to be a gridded data set.



# Get a list of desired variables (see files in shared folder from Lauren)
var.vec = c("T2_present", "T2_rcp45", "T2_rcp85")

# How big of a chunk can I get? #**# Looks to be somewhere between 1 and 2 years. 2 years has been crashing the code

warning("Need to figure out timezone issue before extracting a lot of data. If it is starting at timestep 11, it will need to continue into the next simulation year")
#**# If we change the extraction procedure, then the day.start for the daily compilation can be changed back to 1.
warning("Check that day.start is set appropriatly to match the extraction approach used")

# Get Temperature data (for 5 years for testing)
normal.year = 8760
n.leap.years = 0
for (var in var.vec){
  
  # Check if a directory exists for this variable, if not, create it and the associated sub-directories
  main.path = sprintf("Vars/%s", var)
  if (!file.exists(main.path)){
    dir.create(main.path)
    dir.create(sprintf("%s/AnnualHourly", main.path))
    dir.create(sprintf("%s/DailyMaxs", main.path))
    dir.create(sprintf("%s/DailyMins", main.path))
    dir.create(sprintf("%s/DailyMeans", main.path))

    annual.path = sprintf("%s/AnnualMeans", main.path)
    dir.create(annual.path)
    monthly.path = sprintf("%s/MonthlyMeans", main.path)
    dir.create(monthly.path)
    
    # Create subpaths for monthly and annual paths
    for (this.path in c(monthly.path, annual.path)){
      dir.create(sprintf("%s/Maxs", this.path))
      dir.create(sprintf("%s/Mins", this.path))
      dir.create(sprintf("%s/Means", this.path))
    }
  }
  
  for (i in 1:5){
    year.start = (i - 1) * normal.year + 1 + n.leap.years * 24  # Add 24 hours for each the leap day

    # Adjust for leap years (update within calculations, because a leap year will need an adjustment to the end, but not the start)
    if (i %in% leap.years){
      n.leap.years = n.leap.years + 1
    }
    year.end = i * normal.year + n.leap.years * 24
    
    new.var = ncvar_get(my.ncdf, var, start = c(1,1,year.start), count = c(-1,-1,normal.year))
    message(year.start)
    message(year.end)
    save(new.var, file = sprintf("Vars/%s/AnnualHourly/%s_year_%s.rda",var, var, i))
  }
}


# Create lat/long grid for spatial joins to point/polygon layers
# Slice off just the first time point to get lat/long # wait, we just have index here, where are lat long - probably should be working with the original netcdf
length(my.ncdf$var$XLAT$dim[[1]][[8]]) #97
length(my.ncdf$var$XLONG$dim[[1]][[8]]) # 97?? (???)
#**# NOT FINDING THE ACTUAL LAT/LONG VALUES. The documentation suggests they should be there, but I just see values from 1:97 and 1:75.

# X & Y are missing right now, how do I want to do this? Output an ArcGIS file with LAT ID, LONG ID,
# and a value, so that you can make a map to see where each cell falls.
# Negative is South, Negative is West. So... should be 1:75 for LAT, 1:97 for LONG

# Create a simple data frame to store the grid # Just take first entry to be arbitrary 
vals = ncvar_get(my.ncdf, "T2_present", start = c(1,1,1), count = c(97,75,1))
lat = ncvar_get(my.ncdf, "XLAT", start = c(1,1), count = c(97,75))
lon = ncvar_get(my.ncdf, "XLONG", start = c(1,1), count = c(97,75))
xy.grid = data.frame(values = matrix(vals, ncol = 1), lat = matrix(lat, ncol = 1),
                     lon = matrix(lon, ncol = 1),
                     lat_index = sort(rep(seq(1,75), 97)), lon_index = rep(seq(1,97), 75))


write.table(xy.grid, file = "xy_grid_index.csv", sep = ',', row.names = FALSE, col.names = TRUE,
            append = FALSE)
#**# CHECK FOR ERRORS - IF I SWAPPED THINGS AROUND, THAT'S A PROBLEM, AND IT WOULD BE AN EASY MISTAKE TO MAKE.
# But I think this is right.

# Try to export albedo to identify ocean vs. inland
albedo = ncvar_get(my.ncdf, "ALBEDO_present", start = c(1,1,24), count = c(-1,-1,1))
albedo.long = data.frame(values = matrix(albedo, ncol = 1), lat = matrix(lat, ncol = 1),
                         lon = matrix(lon,ncol = 1))
write.table(albedo.long, file = "albedotest.csv", sep = ',', col.names = TRUE, row.names = FALSE)


# close the netcdf
nc_close(my.ncdf)

##### Process data from hard drive-only sources ######


##### Convert from hourly data to desired timescales #####
# Processing may need to be unique to variables - what works for temperature may not work for precipitation
# group variables based on how they can be aggregated - process variables with similar
# aggregations at a similar time, so the easy ones can be served first.


# Get a list of desired timescales (see file in shared folder from Lauren)
timescales = c('monthly', 'annual')

warning("Not currently accounting for leap years!")
# For each variable, process it at each time scale
for (var in var.vec){
  
  if (length(grep("T2", var)) != 0){
    warning('values look like they are Celsius times 10, check if they need to be scaled by a factor')
  }
  
  #for (scale in timescales){
    for (i in 1:5){
      
      is.leap = 0
      
      # Read in this year's data for this variable
      load(sprintf("%s_year_%s.rda", var, i))
      # Loads the new.var object
      
      # Create a table with daily tmin, tmax, tmean
      day.start = 11 #**# CONFIRM WITH OLIVER AND RYAN ABOUT THIS!
      daily.stuff = create.daily.files(i, var, leap.years, new.var, day.start)
      
      # Process it to each timescale

      # Monthly should just be the average of the time slice associated with a particular month
      if ("monthly" %in% timescales){
        calculate.min.max.mean.monthly(daily.stuff, i, var) # Creates a file names XXXX
        
      }
      # Annual should just be the average of the entire ncdf file
      if ("annual" %in% timescales){
        calculate.min.max.mean.annual(daily.stuff, i, var)
      }
      
      
    }
#  }
}


# Make a plot for Oliver to confirm that data are in local time, not GMT
# 13 lat, 54 lon (so 54, 13 in R grid) is the Honolulu airport.
load("T2_present_year_1.rda") # Loads the new.var object (509 MB)
plot(seq(1,120), new.var[54,13,1:(24 * 5)])
plot(seq(1,24), new.var[54,13,1:24])
plot(seq(1,(24*31)), new.var[54,13,1:(24*31)])
plot(seq(182,(182 +24*31)), new.var[54,13,182:(182 + 24*31)])
lines(seq(182,(182 +24*31)), new.var[54,13,182:(182 + 24*31)])

##### Change format from netCDF to GIS-friendly format (raster? vector?) #####


##### Change projection from HI-specific projection to one that can be better joined
# to other data sets
# consider whether thiessan polygons and spatial joins will solve the problem here
# might be easier to work with vector than with raster, depending on the question.

##### Move processed data sets to a server for external use #####
# where is the final data set going to be hosted?

