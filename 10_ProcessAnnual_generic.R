##### Convert from daily data to desired aggregates for precipitation #####


ProcessAnnual = function(base.path, metric, variable, timestep,
                         first.year, last.year, leap.years){
  setwd(base.path)
  var = sprintf("%s_%s", variable, timestep)
  
  # Loop through years
  for (i in (first.year):(last.year)){
    
    message(sprintf("Processing %s for year %s", var, i))
    
    is.leap = 0
    if (i %in% leap.years){  is.leap = 1  }
    
    # Read in the daily file
    daily.file = sprintf("Daily_%ss_%s_%s_year_%s.rda", metric, variable, timestep, i + 1989)
    if (!file.exists(daily.file)){
      stop(sprintf("%s file not found, this file must exist to process the mean %s %s", daily.file, metric, variable)) 
    }
    load(daily.file) # loads the day.array object
    daily.stuff = day.array
    rm(day.array)
    
    # Process it to monthly and annual aggregates
    #**# LEFT OFF HERE - NEED TO DETERMINE IF PPT VERSION WILL WORK FOR OTHER FILES (seems like it should? NEED TO CHECK)
    # Monthly should just be the sum of the time slice associated with a particular month
    calculate.mean.monthly.ppt(daily.stuff, i, variable, timestep, is.leap, island, data.dir)
    
    # Annual should just be the average of the entire ncdf file
    #year.path = sprintf("Vars/%s/%s_%s/AnnualPPT/AnnualPPT_%s_%s_year_%s.rda", island, variable, timestep, variable, timestep, i + 1989)
    calculate.mean.annual.ppt(daily.stuff, i, variable, timestep, is.leap, island, data.dir)
  }
  
  # Create climatologies
  calculate.monthly.climatologies(first.year, last.year, variable, timestep, island, data.dir)
  calculate.annual.climatologies(first.year, last.year, variable, timestep, island, data.dir)
}

