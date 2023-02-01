# Extract variables to annual files
# This version requires the data to be pre-downloaded from the server in 1000 hour chunks

# A.C. Keyel
# From Workflow_v2.R that was created 2021-12-14, revised on 2023-01-02

# See 001b_ExtractAnnual.R for my previous approach. This one seems like it will be more robust.

# Settings should already be in memory
#island = "maui"
# leap.years = c(3, 7, 11, 15, 19) # 1992, 1996, 2000, 2004, 2008; 2000 is a leap year because of the millennium.
# GMT.offset = 10 #**# Need to take this as an input from settings
# scenario = 'present'

setwd(sprintf("F:/hawaii_local/vars/%s", island))
var = sprintf("rainnc_%s", scenario) # Sets it so it only outputs the extracted rainfall to the RAINNC folder

# Set GMT offset
start = GMT.offset # because you need to use the last value of the previous day for the subtraction. Timestep 10 corresponds to 9am, which is 11 pm the previous day.
end = start + 24 # Needs to include a full 24 hours worth of data
# Need one index to track time steps and one to track file position.
start.index = start
end.index = end 
file.end = 1000
total.timesteps = 175320 + GMT.offset
# Present scenario needs the extra day interpolated before running.
# All scenarios need an extra 10 hours appended to the end to complete the last day in December.

days = 365
day = 1
year = 1990

load.file = function(variable, scenario, file.end){
  in.file = sprintf("%s_%s/hourly/%s_%s_%s_%s.rda", variable, scenario, island, variable, scenario, format(file.end, scientific = F))
  
  load(in.file) 
  return(hourly)
}

rainnc = load.file("RAINNC", scenario, file.end)
irain = load.file("I_RAINNC", scenario, file.end)

# Get dimensions for array step
dim1 = dim(rainnc)[1] # should be long
dim2 = dim(rainnc)[2] # should be lat
  
# Get the amount of rainfall that fell since the beginning of the simulation. Assuming it starts at 0, but may need to confirm this!
#do.wrap = 0
#iwrap = irain[,,GMT.offset] # not -1, 
#ncwrap = rainnc[,,GMT.offset] #  not - 1, see logic above
#wrap.amount = iwrap * 100 + ncwrap
#**# No longer needed - wrapping was replaced with interpolation prior to this script.

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
      #do.wrap = 1
      end = 320 + GMT.offset
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
  irain_diff = irain_end - irain_start
  rainnc_diff = rainnc_end - rainnc_start
  
  this.day = irain_diff * 100 + rainnc_diff
  
  # Add a check that a day's rainfall is not negative
  if (min(this.day) < 0){
    # Some minuscule negative values were found, probably due to rounding in the interpolation, allow these to pass without error.
    #**# To find and replace, pull the data out of an array, fix the values, then put the data back into an array in the correct order
    #**# NOT DONE - Decided I didn't want to trouble-shoot fixing the array, and the values will be corrected at a later step anyhow.
    message(sprintf("Small negative rainfall reported for %s %s. These are likely just a rounding error", year, day))
    if (min(this.day) < -0.0001){
      message(sprintf("Additional negative rainfall reported for %s %s. This is likely more serious than a rounding error", year, day))
    }
  }
  
  #if (do.wrap == 1){
  #  this.day = this.day + wrap.amount
  #}

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

    #if (year == 2007){
    #  stop("Trying to figure out the negative rainfall thing.")
    #}
        
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

