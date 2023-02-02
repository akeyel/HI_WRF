##### Convert from daily data to desired aggregates for precipitation #####

#**# Watch processing of leap-years

setwd(base.path)


# For each variable, process it at each time scale
#for (var in precip.vars){
var = "RAINNC"

main.var = sprintf("%s_%s", var, timestep)

# Loop through years
for (i in (first.year):(last.year)){
  
  message(sprintf("Processing %s for year %s", main.var, i))
  
  is.leap = 0
  if (i %in% leap.years){  is.leap = 1  }

  # Read in the daily file
  daily.file = sprintf("DailyPPT_rainnc_%s_year_%s.rda", timestep, i + 1989)
  if (!file.exists(daily.file)){
    stop(sprintf("%s file not found, this file must exist to process the mean annual precipitation", daily.file)) 
  }
  load(daily.file) # loads the day.ppt.array object
  daily.stuff = day.ppt.array
  rm(day.ppt.array)

  # Process it to monthly and annual aggregates
  
  # Monthly should just be the sum of the time slice associated with a particular month
  calculate.mean.monthly.ppt(daily.stuff, i, var, timestep, is.leap, island, data.dir)

  # Annual should just be the average of the entire ncdf file
  #year.path = sprintf("Vars/%s/%s_%s/AnnualPPT/AnnualPPT_%s_%s_year_%s.rda", island, var, timestep, var, timestep, i + 1989)
  calculate.mean.annual.ppt(daily.stuff, i, var, timestep, is.leap, island, data.dir)
}

# Create climatologies
calculate.monthly.climatologies(first.year, last.year, var, timestep, island, data.dir)
calculate.annual.climatologies(first.year, last.year, var, timestep, island, data.dir)

