# Goal is to check Temperature Values for time of year, etc.

### Compare hourly data to observations

# Add function to identify leap years
get.leaps = function(year, base.year = 2002){

  year = as.numeric(year)
  #2004 # Leap will be calculated on the month offset for current year, so 2005 needs a +1 day, 2009 needs +2 days, etc.
  leap.days = 0
  if (year >= 2005 & year < 2009){ leap.days = 1 }
  if (year >= 2009 & year < 2013){ leap.days = 2 }
  if (year >= 2012 & year < 2017){ leap.days = 3 }
  if (year >= 2017 & year < 2021){ leap.days = 4 }
  if (year >= 2021 & year < 2025){ leap.days = 5}

  return(leap.days)
}

calculate.month.offset = function(month, year){
  is.leap = 0
  if (as.numeric(year) %% 4 == 0){ is.leap = 1 }
  
  cumulative.days = c(31,59,90,120,151,181,212,243,273,304,334,365)
  if (is.leap == 1){
    cumulative.days = c(31,60,91,121,152,182,213,244,274,305,335,366)
  }
  
  if (as.numeric(month) == 1){
    month.offset = 0
  }else{
    month.offset = cumulative.days[as.numeric(month) - 1]
  }
  return(month.offset)
}

# Add a function for converting time to an index. Make midnight 2002 an index value of 1
#**# WATCH FOR BUGS
time.to.index = function(this.station){
  this.station$YEAR = sapply(this.station$time, substr, 1,4)
  this.station$MONTH = sapply(this.station$time, substr, 6,7)
  this.station$DAY = sapply(this.station$time, substr, 9,10)
  this.station$HOUR = sapply(this.station$time, substr, 12,13)
  this.station$MINUTE = sapply(this.station$time, substr, 15,16)
  this.station$LEAPS = sapply(this.station$YEAR, get.leaps)
  this.station$MONTH_OFFSET = mapply( calculate.month.offset, this.station$MONTH, this.station$YEAR)
  this.station$LEAPS = sapply(this.station$YEAR, get.leaps)
  this.station$INDEX = (as.numeric(this.station$YEAR) - 2002) * 365 * 24 * 12 + this.station$MONTH_OFFSET * 24 * 12 +
    (as.numeric(this.station$DAY) - 1) * 24 * 12 + (as.numeric(this.station$HOUR) * 12) + (as.numeric(this.station$MINUTE) / 5) +
    this.station$LEAPS * 24 * 12
  
  return(this.station) 
}


# Check data is from 2002-2009 from XXXXX

# Need to extract data in order to check it.

# Configure settings
# If data are 1990 - 2009, then 2002 should be year 13. So extract year 13 to start.
setwd(code.dir)
source("200_b_CheckSettings1.R") # working directory needs to be set first
first = 0

# Run WRF data extraction
if (first == 1){
  source("001_ExtractAnnual.R") # Done - file created!
}

#**# NEED TO LOOK FOR OTHER YEARS BEYOND 2002. #**# DOES THE STATION LIST CHANGE FROM YEAR TO YEAR?

# Read in station data files
temp_path = "C:/hawaii_local/From_Keri"
t_file = sprintf("%s/temperature_oa_subdaily_2002.csv", temp_path)
t_data = read.csv(t_file)

# Map out station data for comparison purposes
stations = unique(t_data$Station.Name)

station.df = data.frame(station = NA, LAT = NA, LON = NA, ELEV.m. = NA)

for (station in stations){
  this.station = t_data[t_data$Station.Name == station, ]
  this.lat = this.station$LAT[1] # Should all be the same
  this.lon = this.station$LON[1] # Should all be the same
  this.elev = this.station$ELEV.m.[1]
  station.df = rbind(station.df, c(station, this.lat, this.lon, this.elev))
}
station.df = station.df[2:nrow(station.df), ]

write.table(station.df, file = "C:/hawaii_local/From_Keri/derived/stations.csv",
            sep = ',', row.names = FALSE, col.names = TRUE)

# Examined in ArcGIS, info manually extracted (could have used spatial join, but I wanted to look at the data)
# Closest matches should be as follows:
lat.index = c(44, 44, 46, 39, 40, 67, 68)
lon.index = c(12, 15, 16, 32, 44, 45, 50)
station.ids = c("MAKUA RANGE", "MAKUA VALLEY", "MAKUA RIDGE", "SCHOFIELD BARRACKS", "SCHOFIELD EAST",
            "KAHUKU TRAINING AREA", "KII")

# NEED TO PULL UP THE DATA BY GRID INDEX, PLOT IT, AND COMPARE IT TO THE CORRESPONDING STATION DATA

this.id = station.ids[1]
this.lat = lat.index[1]
this.lon = lon.index[1]

# Pull up WRF data

# Pull up station data
this.station = t_data[t_data$Station.Name == this.id, ]
this.station = time.to.index(this.station)
# Makua Range only goes from April - September. So we'll need to plot the time dimension in some manner.
# Looks like it is only selected days in that range. This could be a problem.
plot(this.station$INDEX, this.station$value)
#**# REMOVED 5 ISOLATED VALUES AND THEN LOOK AT APRIL VALUES
plot(this.station$INDEX, this.station$value, xlim = c(27225,28800))
#**# NOTE: Fairly large data gaps for Makua range

# PRIMARILY LOOKING FOR PLAUSIBILITY AND OFFSETS BY AN HOUR OR MORE
load("Vars/T2_Present/AnnualHourly/T2_Present_year_13_GMT-10.rda")
# Desired object is new.var
this.wrf = new.var[this.lon, this.lat, ] # Get all time steps

hours = seq(1,length(this.wrf))

# EACH TIMESTEP IS AN HOUR, need to put on same scale as the index above.
index.vals = (hours - 1) * 12 + 1
wrf.df = data.frame(WRF.VALUES = this.wrf - 273.15, INDEX = index.vals)

# Get y limits
y.min = min(wrf.df$WRF.VALUES, this.station$value)
y.max = max(wrf.df$WRF.VALUES, this.station$value)

plot(this.station$INDEX, this.station$value, xlim = c(27225,28800), ylim = c(y.min, y.max))
par(new = TRUE)
# Try undoing the GMT offset
plot(wrf.df$INDEX + 10*12, wrf.df$WRF.VALUES, xlim = c(27225, 28800), ylim = c(y.min, y.max), col = 'red')

#**# So... based on this first test, it looks like the values are in the plausible range, and there IS NOT a GMT offset.
#**# TRY FOR REMAINING PLOTS
pdf("TempCheck_2002_2009.pdf")

new.stations = c()
for (this.year in seq(2002,2009)){
  t_file = sprintf("%s/temperature_oa_subdaily_%s.csv", temp_path, this.year)
  t_data = read.csv(t_file)
  
  year.stations = unique(t_data$Station.Name)
  # Check if station.id changes from year to year
  for (year.station in year.stations){
    if (!year.station %in% station.ids){
      new.stations = c(new.stations, year.station)
    }
  }

  year.index = this.year - 1989
  load(sprintf("Vars/T2_Present/AnnualHourly/T2_Present_year_13_GMT-10.rda", year.index))
  # Desired object is new.var
  
    
  for (i in 1:length(station.ids)){
    this.id = station.ids[i]
    this.lat = lat.index[i]
    this.lon = lon.index[i]
    if (this.id %in% year.stations){
      this.station = t_data[t_data$Station.Name == this.id, ]
      this.station = time.to.index(this.station)
      
      this.wrf = new.var[this.lon, this.lat, ] # Get all time steps
      hours = seq(1,length(this.wrf))
      index.vals = (hours - 1) * 12 + 1
      wrf.df = data.frame(WRF.VALUES = this.wrf - 273.15, INDEX = index.vals)
      
      # Get y limits
      y.min = min(wrf.df$WRF.VALUES, this.station$value)
      y.max = max(wrf.df$WRF.VALUES, this.station$value)
      
      # Get x limits
      x.min = min(this.station$INDEX)
      x.max = max(this.station$INDEX)
      spread = 3000
      x.lower = x.min
      x.upper = x.min + spread
      count = 1
      while ((x.max - x.lower) > spread){
        plot(this.station$INDEX, this.station$value, xlim = c(x.lower,x.upper), ylim = c(y.min, y.max))
        par(new = TRUE)
        # Try undoing the GMT offset
        plot(wrf.df$INDEX + 10*12, wrf.df$WRF.VALUES, xlim = c(x.lower, x.upper), ylim = c(y.min, y.max), col = 'red')
        mtext(sprintf("%s: %s vs %s LAT %s LON PART %s", this.year, this.id, this.lat, this.lon, count), side = 3)
        count = count + 1
        
        x.lower = x.lower + spread
        x.upper = x.upper + spread
      }      
    }
  }  
}

dev.off()