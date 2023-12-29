##### Convert from daily data to desired aggregates #####


ProcessAnnual = function(base.path, metric, variable, timestep,
                         first.year, last.year, leap.years, is.cumulative = 0){
  setwd(base.path)
  var = sprintf("%s_%s", variable, timestep)
  
  # Loop through years
  for (i in (first.year):(last.year)){
    
    message(sprintf("Processing %s for year %s", var, i))
    
    is.leap = 0
    if (i %in% leap.years){  is.leap = 1  }

        
    # Read in the daily file
    if (is.cumulative == 0){
      daily.file = sprintf("Daily_%ss_%s_%s_year_%s.rda", metric, variable, timestep, i + 1989)
    }
    # Naming convention is a bit different for cumulative variables, because we want a daily total, not an hourly mean.
    if (is.cumulative == 1){
      daily.file = sprintf("Daily_total_%s_%s_year_%s.rda", variable, timestep, i + 1989)
    }
    
    if (!file.exists(daily.file)){
      stop(sprintf("%s file not found, this file must exist to process the mean %s %s", daily.file, metric, variable)) 
    }
    
    load(daily.file) # loads the day.array object
    daily.stuff = day.array
    rm(day.array)
    
    # Process it to monthly and annual aggregates
    # Monthly should just be the sum of the time slice associated with a particular month
    calculate.mean.monthly.var(daily.stuff, i, variable, timestep, is.leap, island, data.dir, metric)
    
    # Annual should just be the average of the entire ncdf file
    #year.path = sprintf("Vars/%s/%s_%s/AnnualPPT/AnnualPPT_%s_%s_year_%s.rda", island, variable, timestep, variable, timestep, i + 1989)
    calculate.mean.annual.var(daily.stuff, i, variable, timestep, is.leap, island, data.dir, metric)
  }
  
  # Create mean climatologies for cumulative and non-cumulative variables
  calculate.monthly.climatologies(first.year, last.year, variable, timestep, island, data.dir, metric, is.cumulative = 0)
  calculate.annual.climatologies(first.year, last.year, variable, timestep, island, data.dir, metric, is.cumulative = 0)
  
  # create total climatologies for just the cumulative variables
  if (is.cumulative == 1){
    # output file names will have 'total' in the path, rather than the input metric 'mean', if is.cumulative is set to 1.
    calculate.monthly.climatologies(first.year, last.year, variable, timestep, island, data.dir, metric, is.cumulative = 1)
    calculate.annual.climatologies(first.year, last.year, variable, timestep, island, data.dir, metric, is.cumulative = 1)
  }
  
}

