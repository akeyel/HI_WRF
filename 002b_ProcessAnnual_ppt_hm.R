##### Convert from hourly data to desired timescales for precipitation #####

#**# Watch processing of leap-years

setwd(data.dir)

# Loop through scenarios
for (timestep in timesteps){

  # Loop through years
  for (i in first.year:last.year){
    
    for (j in 1:3){
      # For each variable, process it at each time scale
      #for (var in precip.vars){
      var = "RAINNC"
      
      main.var = sprintf("%s_%s", var, timestep)
      
      message(sprintf("Processing %s for year %s part %s", main.var, i, j))
      
      is.leap = 0
      #**# NEED CONTROL TO CHANGE TO LEAP YEAR DEPENDING ON VALUES OF i
      #**# Not needed for processing daily data
      
      # Read in this year's data for main variable
      in.file = sprintf("Vars/%s/%s/AnnualHourly/%s_year_%s_%s_%s.rda",island, main.var, main.var, i, j, TimeZone.Label)
      load(in.file)
      rainnc = new.var
      rm(new.var)
      
      # Create a table with daily precipitation
      initial.value = NA
      daily.stuff = create.daily.ppt.files(i, var, rainnc, timestep, island, j)
      
      # Process it to each timescale
      
      # Monthly should just be the sum of the time slice associated with a particular month
      #**# FIX
      #if ("monthly" %in% timescales){
      #  calculate.min.max.mean.monthly(daily.stuff, i, var) # Creates a file names XXXX
      #}
      
      # Annual should just be the average of the entire ncdf file
      #**# FIX
      #if ("annual" %in% timescales){
      #  calculate.min.max.mean.annual(daily.stuff, i, var)
      #}
      
    }
  }
}
