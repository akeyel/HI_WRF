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
extract.annual.data = function(base.path, island, variable, scenario, new.dir,
                               GMT.offset, leap.years){
  setwd(sprintf("%s/%s", base.path, island))
  var = sprintf("%s_%s", variable, scenario)
  
  # Make sure the daily directory exists, if not, create it
  day.path = sprintf("%s/%s", var, new.dir)
  if (!file.exists(day.path)){
    dir.create(day.path) # recursive not changed to true - if the previous path doesn't exist, there was a typo somewhere because this should be the same folder as hourly.
  }
  
  # Set GMT offset
  start = GMT.offset # because you need to use the last value of the previous day for the subtraction. Timestep 10 corresponds to 9am, which is 11 pm the previous day.
  end = start + 24 # Needs to include a full 24 hours worth of data
  # Need one index to track time steps and one to track file position.
  start.index = start
  end.index = end 
  file.end = 1000
  total.timesteps = 175320 + GMT.offset # Present scenario needs the extra day interpolated before running
  # All scenarios need an extra few hours to account for the gmt difference.
  
  days = 365
  day = 1
  year = 1990
  
  #**# Consider moving this to workflow_hlpr.R - repeated in 001c_ExtractAnnual_hm.R
  load.file = function(variable, scenario, file.end){
    in.file = sprintf("%s_%s/hourly/%s_%s_%s_%s.rda", variable, scenario, island, variable, scenario, format(file.end, scientific = F))
    
    load(in.file) 
    return(hourly)
  }
  
  rainnc = load.file("RAINNC", scenario, file.end)
  
  # Get dimensions for array step
  dim1 = dim(rainnc)[1] # should be long
  dim2 = dim(rainnc)[2] # should be lat
  
  # Run on a smaller area subset for testing purposes
  testing = 0 # Can set testing to 1 and then it only runs for a 4 x 4 array. Unfortunately this is over the ocean, as it would be more useful to some purposes over land in a high or low rainfall area.
  if (testing == 1){
    dim1 = 4
    dim2 = 4
  }
  
  last.hour = as.matrix(rainnc[1:dim1,1:dim2,start], nrow = 1) # Convert to vector for subtraction
  file.length = 1000
  
  start.time = Sys.time()  
  while (start.index < total.timesteps){
    
    roll.over = 0
    
    this.day = array(0, dim = c(dim1,dim2, 1))
    for (this.step in (start + 1):end){
      # If the file rolled over, the remaining steps need to be adjusted until the loop is finished.
      if (roll.over == 1){
        this.step = this.step - file.length
      }
      
      # If you run out of data, get more
      if (this.step > file.length){ # file.end
        file.end = file.end + file.length
        # For last file, change file end to correspond to the file end point.
        if (file.end > total.timesteps){
          file.end = total.timesteps
          #file.length = total.timesteps - 175000
        }
        
        roll.over = 1
        this.step = this.step - file.length #file.end
        start = start - file.length #file.end
        end = end - file.length #file.end
        rainnc = load.file("RAINNC", scenario, file.end)
      }
      this.hour = matrix(rainnc[1:dim1,1:dim2,this.step], nrow = 1)
      if (is.na(min(this.hour))){
        break
      }
      this.delta = mapply(calc.precip, this.hour, last.hour)
      if (is.na(min(this.delta))){
        break
      }
      
      this.delta = array(this.delta, dim = c(dim1, dim2, 1))
      
      this.day = this.day + this.delta
      # update the last.hour object (can't just use rainnc[,,(this.step - 1)]) because that will fail when the file rolls over.
      last.hour = this.hour
    }
    
    # Check for missing data
    
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
    # day 42 is where the first file rolls over
    #if (day == 42){
    #  break
    #}
  }
  end.time = Sys.time()
  message(sprintf("Elapsed time: %s", (end.time - start.time)))
}
