# Extract variables to annual files
# This version requires the data to be pre-downloaded from the server in 1000 hour chunks

# A.C. Keyel
# From Workflow_v2.R that was created 2021-12-14, revised on 2023-01-02

# See 001b_ExtractAnnual.R for my previous approach. This one seems like it will be more robust.
#**# Do need to watch out for the e05 problem, where R changes the naming for one of the time steps instead of 100000 it is giving E05. I've been manually correcting those file names.
#**# Previous approach below here
island = "hawaii"
setwd(sprintf("F:/hawaii_local/vars/%s", island))
leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.


gmt.offset = 10 #**# Need to take this as an input from settings
scenario = 'present'
var = "rainnc_present"

# Set GMT offset
start = gmt.offset - 1 # because you need to use the last value of the previous day for the subtraction
end = start + 24 # Needs to include a full 24 hours worth of data
# Need one index to track time steps and one to track file position.
start.index = start
end.index = end 
file.end = 1000
total.timesteps = 175296

days = 365
day = 1
year = 1990

load.file = function(variable, scenario, file.end){
  in.file = sprintf("%s_%s/hourly/%s_%s_%s_%s.rda", variable, scenario, island, variable, scenario, file.end)
  # Correct for random sci notation instance
  if (file.end == "1e+05"){
    in.file = sprintf("%s_%s/hourly/%s_%s_%s_100000.rda", variable, scenario, island, variable, scenario)
  }
  
  load(in.file) 
  return(hourly)
}

rainnc = load.file("RAINNC", scenario, file.end)
irain = load.file("I_RAINNC", scenario, file.end)

# Get dimensions for array step
dim1 = dim(rainnc)[1] # should be long
dim2 = dim(rainnc)[2] # should be lat
  
# Get the amount of rainfall that fell since the beginning of the simulation. Assuming it starts at 0, but may need to confirm this!
do.wrap = 0
iwrap = irain[,,gmt.offset - 1]
ncwrap = rainnc[,,gmt.offset - 1]
wrap.amount = iwrap * 100 + ncwrap

while (start.index < total.timesteps){
  
  # update the files used and the file end variable if needed
  if (start.index > file.end){
    start = start.index - file.end 
    end = end.index - file.end 
    file.end = file.end + 1000
    
    # Make sure not to overshoot the last file
    if (file.end > total.timesteps){  file.end = total.timesteps  }
    
    rainnc = load.file("RAINNC", scenario, file.end)
    irain = load.file("I_RAINNC", scenario, file.end)
  }

  irain_start = irain[,,start]
  rainnc_start = rainnc[,,start]

  # May also need to update between start and end
  if (end.index > file.end){
    if (end.index > total.timesteps){
      do.wrap = 1
      end = 296 # Set end to the end of the last file, which is only a partial file
    }else{
      start = start.index - file.end 
      end = end.index - file.end 
      file.end = file.end + 1000
      if (file.end > total.timesteps){  file.end = total.timesteps  }
      rainnc = load.file("RAINNC", scenario, file.end)
      irain = load.file("I_RAINNC", scenario, file.end)
    }
  }  
  
  irain_end = irain[,,end]
  rainnc_end = rainnc[,,end]
  
  # Go through 24 hour periods
  # Wrap around for last year
  irain_diff = irain_end - irain_start
  rainnc_diff = rainnc_end - rainnc_start
  
  this.day = irain_diff * 100 + rainnc_diff
  
  # Add a check that a day's rainfall is not negative
  if (min(this.day) < 0){
    message(sprintf("Negative rainfall reported for %s %s", year, day))
  }
  
  if (do.wrap == 1){
    this.day = this.day + wrap.amount
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



