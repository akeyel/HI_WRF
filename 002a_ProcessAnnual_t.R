##### Convert from hourly data to desired timescales #####
# Processing may need to be unique to variables - what works for temperature may not work for precipitation
# group variables based on how they can be aggregated - process variables with similar
# aggregations at a similar time, so the easy ones can be served first.


stop("This script is in progress of being reorganized. Fix before running!")
warning('values look like they are Celsius times 10, check if they need to be scaled by a factor')

setwd(data.dir)

## RUN BLOCK OF CODE FOR OAHU/KAUAI
if (island == "oahu" | island == "kauai"){

  # For each variable, process it at each time scale
  for (var in var.vec){
    
    #for (scale in timescales){
    for (i in first.year:last.year){

      message(sprintf("Processing %s for year %s", var, i))
      is.leap = 0
      if (i %in% leap.years){  is.leap = 1  }
      
      if ('daily' %in% timescales){
        #**# LEFT OFF HERE - NEED TO DO WALK-THROUGH AND ALSO CHECK PROCESSING
        # Read in this year's data for this variable
        load(sprintf("%s_year_%s.rda", var, i))
        # Loads the new.var object
        
        # Create a table with daily tmin, tmax, tmean
        day.start = 11 #**# CONFIRM WITH OLIVER AND RYAN ABOUT THIS!
        daily.stuff = create.daily.files(i, var, leap.years, new.var, day.start)
      }else{
        #**# JUST LOAD THE DAILY FILE
      }
      
      # Process it to each timescale
      
      # Monthly should just be the average of the time slice associated with a particular month
      if ("monthly" %in% timescales){
        calculate.min.max.mean.monthly(daily.stuff, i, var) # Creates a file names XXXX
        
      }
      # Annual should just be the average of the entire ncdf file
      if ("annual" %in% timescales){
        calculate.min.max.mean.annual(daily.stuff, i, var)
      }
    } # End of loop over years
    
    # Create climatologies #**# COPIED AND PASTED FOR PPT - CHECK IF IT NEEDS ADAPTATION FOR T
    if ("monthly" %in% timescales){
      calculate.monthly.climatologies(first.year, last.year, var, timestep, island)
    }
    if ('annual' %in% timescales){
      calculate.annual.climatologies(first.year, last.year, var, timestep, island)
    }
  } #End of loop over variables
} # End of Oahu/Kauai

## RUN BLOCK OF CODE FOR MAUI/HAWAII
if (island == "maui" | island == "hawaii"){
  stop("Copy/Paste code from above, and adjust to Maui/Hawaii situation")
  
  
}

