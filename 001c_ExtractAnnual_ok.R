# Extract variables to annual files
# This version requires the data to be pre-downloaded from the server in 1000 hour chunks

# A.C. Keyel
# Modified from 001c_ExtractAnnual_hm.R beginning on 2023-01-16
# See 001b_ExtractAnnual.R for my previous approach. This one seems like it will be more robust.
#**# Do need to watch out for the e05 problem, where R changes the naming for one of the time steps instead of 100000 it is giving E05. I've been manually correcting those file names.

# Variables defined in settings and passed implicitly to this script #**# Think about making this a function to make the pass explicit.
#island = "oahu"
#leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.
#scenario = 'present'
#var = "rainnc_present" #**# Watch this one - will differ between sets of islands
# variable = 'rainnc_present'
#gmt.offset = 10 #**# Need to take this as an input from settings

setwd(sprintf("F:/hawaii_local/vars/%s", island))

# Set GMT offset
start = gmt.offset # because you need to use the last value of the previous day for the subtraction. Timestep 10 corresponds to 9am, which is 11 pm the previous day.
end = start + 24 # Needs to include a full 24 hours worth of data
# Need one index to track time steps and one to track file position.
start.index = start
end.index = end 
file.end = 1000
total.timesteps = 175320 + gmt.offset # Present scenario needs the extra day interpolated before running
# All scenarios need an extra few hours to account for the gmt difference.

days = 365
day = 1
year = 1990

#**# Consider moving this to workflow_hlpr.R
load.file = function(variable, scenario, file.end){
  in.file = sprintf("%s_%s/hourly/%s_%s_%s_%s.rda", variable, scenario, island, variable, scenario, file.end)
  # Correct for random sci notation instance
  if (file.end == "1e+05" & !file.exists(in.file)){
    in.file = sprintf("%s_%s/hourly/%s_%s_%s_100000.rda", variable, scenario, island, variable, scenario)
  }
  
  load(in.file) 
  return(hourly)
}

rainnc = load.file("RAINNC", scenario, file.end)

# Get dimensions for array step
dim1 = dim(rainnc)[1] # should be long
dim2 = dim(rainnc)[2] # should be lat

last.hour = rainnc[,,start]
  
while (start.index < total.timesteps){

  this.day = array(0, dim = c(dims[1],dims[2], 1))
  for (this.step in (start + 1):end){
    # If you run out of data, get more
    if (this.step > file.end){
      this.step = this.step - file.end
      start = start - file.end
      end = end - file.end
      file.end = file.end + 1000
      if (file.end > total.timesteps){ file.end = total.timesteps }
      rainnc = load.file("RAINNC", scenario, file.end)
    }
    this.hour = rainnc[,,this.step]
    this.delta = this.hour - last.hour
    this.day = this.day + this.delta
    # update the last.hour object (can't just use rainnc[,,(this.step - 1)]) because that will fail when the file rolls over.
    last.hour = this.hour
  }
    
  # # Add a check that a day's rainfall is not negative
  if (min(this.day) < 0){
    message(sprintf("Negative rainfall reported for %s %s", year, day))
  }

  if (day == 1){
    day.ppt.array = this.day
  }else{
    day.ppt.array = array(c(day.ppt.array, this.day), dim = c(dim1, dim2, day)) #**# This may be a slow inefficient step - may want to think about faster ways if it's limiting.
  }
    
  # If this is the last day of the year
  if (day == days){
    # save the day file
    daily.file = sprintf("%s/DailyPPT/DailyPPT_%s_year_%s.rda",var, var, year)
    save(day.ppt.array, file = daily.file)
    message(sprintf("Year %s completed", year))
    
    # reset the annual counters
    day = 0 # This will immediately increment to 1 below.
    year = year + 1
    days = 365
    if ((year - 1989) %in% leap.years){
      # Leap years object is defined in 000b_PrecipSettings.R
      days = 366
    }
  }
  
  # update counters
  start = start + 24
  end = end + 24
  start.index = start.index + 24
  end.index = end.index + 24
  day = day + 1
    
  #**# For testing purposes
  #if (year == 1993){
  #  break
  #}
}

