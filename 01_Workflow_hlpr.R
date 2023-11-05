
#' Get a data file
#' 
get.data.file = function(island, scenario){
  if (island == 'oahu'){
    data.file = "https://cida.usgs.gov/thredds/dodsC/oahu"
  }
  if (island == 'kauai'){
    data.file = "https://cida.usgs.gov/thredds/dodsC/kauai"
  }
  if (island == 'hawaii'){
    data.file = sprintf("https://cida.usgs.gov/thredds/dodsC/hawaii_%s_%s", island, scenario)
  }
  if (island == 'maui'){
    data.file = sprintf("https://cida.usgs.gov/thredds/dodsC/hawaii_%s_%s", island, scenario)
  }
  return(data.file)  
}

load.file = function(variable, scenario, file.end){
  in.file = sprintf("%s_%s/hourly/%s_%s_%s_%s.rda", variable, scenario, island, variable, scenario, format(file.end, scientific = F))
  load(in.file) 
  return(hourly)
}

#' Create directories to store data
#' 
create.my.directories = function(main.path, ppt.offset){
  dir.create(main.path)
  dir.create(sprintf("%s/AnnualHourly", main.path))
  
  if (ppt.offset == 0){
    dir.create(sprintf("%s/DailyMaxs", main.path))
    dir.create(sprintf("%s/DailyMins", main.path))
    dir.create(sprintf("%s/DailyMeans", main.path))
  }else{
    dir.create(sprintf("%s/DailyPPT", main.path))
    dir.create(sprintf("%s/Climatology", main.path))
  }
  
  annual.path = sprintf("%s/AnnualMeans", main.path)
  dir.create(annual.path)
  monthly.path = sprintf("%s/MonthlyMeans", main.path)
  dir.create(monthly.path)
  
  # Create subpaths for monthly and annual paths
  for (this.path in c(monthly.path, annual.path)){
    if (ppt.offset == 0){
      dir.create(sprintf("%s/Maxs", this.path))
      dir.create(sprintf("%s/Mins", this.path))
      dir.create(sprintf("%s/Means", this.path))
    #}else{
    #  dir.create(sprintf("%s/Cumulative_PPT", this.path))
    }
  }
  
}

#' Create a Data Grid
#' 
make.data.grid = function(my.ncdf, island, grid.file){
  
  # Synthesized version
  if (island == "oahu" | island == "kauai"){
    dim1 = my.ncdf$var$T2_present$varsize[1]
    dim2 = my.ncdf$var$T2_present$varsize[2]
  }
  
  if (island == "hawaii" | island == "maui"){
    warning("looks like there is a bug in the HI/MAUI version - T2_present needs to be T2 I think")
    dim1 = my.ncdf$var$T2$varsize[1]
    dim2 = my.ncdf$var$T2$varsize[2]
  }
  
  # Create a simple data frame to store the grid # Just take first entry to be arbitrary 
  vals = ncvar_get(my.ncdf, "T2_present", start = c(1,1,1), count = c(dim1,dim2,1))
  lat = ncvar_get(my.ncdf, "XLAT", start = c(1,1), count = c(dim1,dim2))
  lon = ncvar_get(my.ncdf, "XLONG", start = c(1,1), count = c(dim1,dim2))
  xy.grid = data.frame(values = matrix(vals, ncol = 1), lat = matrix(lat, ncol = 1),
                       lon = matrix(lon, ncol = 1),
                       lat_index = sort(rep(seq(1,dim2), dim1)), lon_index = rep(seq(1,dim1), dim2))
  
  write.table(xy.grid, file = grid.file, sep = ',', row.names = FALSE, col.names = TRUE,
              append = FALSE)
}

#**# Currently this is just extracting albedo, and is not joining to the xy.grid
#**# Need to think about how this function will work.
extract.data.by.grid = function(my.ncdf, STUFF){
  # Try to export albedo to identify ocean vs. inland
  albedo = ncvar_get(my.ncdf, "ALBEDO_present", start = c(1,1,24), count = c(-1,-1,1))
  albedo.long = data.frame(values = matrix(albedo, ncol = 1), lat = matrix(lat, ncol = 1),
                           lon = matrix(lon,ncol = 1))
  write.table(albedo.long, file = "albedotest.csv", sep = ',', col.names = TRUE, row.names = FALSE)
  
}

#' Extract data for a variable for a single location by row/column index
#' 
#' #**# NEED TO WATCH THAT I GET THE ROW/COLUMN INDICES CORRECT
extract.data.by.location = function(my.ncdf, in.var, row.index, col.index, start.time, end.time){
  #**# CHECK IF I REVERSET ROW/COLUMN
  time.steps = end.time - start.time + 1 # Needs to be at least 1 to include end point
  this.var = ncvar_get(my.ncdf, in.var, start = c(row.index,col.index,start.time), count = c(1,1,time.steps))
  
  return(this.var) #**# This is a vector of timestep values, correct?
}


#' Figure out arrays
#' 
array.test = function(){
  matrix1 = matrix(rep(seq(1,10), 10), ncol = 10)
  matrix2 = matrix(rep(seq(11,20), 10), ncol = 10)
  array1 = array(c(matrix1, matrix2), dim = c(10,10,2))
  
  matrix3 = matrix(rep(seq(21,30), 10), ncol = 10)
  array2 = array(c(array1, matrix3), dim = c(10,10,3))
  # Ha this works perfectly!
}


#' Calculate daily Tmin, Tmax, and Tmean for each day in a year
#' 
#' Files will be saved into folders for easy organization
#' 
#' 
#' @param day.start 1 sets it to start with the first record of the simulation.
#' I think 1 would correspond to midnight GMT
#' inspection of the data suggests that it is likely GMT, so probably want the day to start at
#' 11 (11 - 10 = 1). If another daily rhythm is desired, adjust day.start as needed.
#' 
create.daily.files = function(i, var, leap.years, new.var, day.start){

  warning("NEEDS TESTING")
  # Identify the day, month, year (watch for leap years)
  # NOTE: Not needed, will go by day of year for index
    
  #day.start = 1 # 1 is midnight
  day.end = day.start + 23 #  24 #**# 24 is 11 pm GMT?
  
  count = 1
  
  # https://www.geeksforgeeks.org/create-3d-array-using-the-dim-function-in-r/
  # https://www.tutorialspoint.com/r/r_arrays.htm
  
  #warning("LAT & LONG COULD BE REVERSED - NEED TO CHECK!") #**# FLAG
  long = dim(new.var)[1]
  lat = dim(new.var)[2]
  
  # For every 24 hours, calculate a minimum, maximum, and mean
  
  # Iterate through new.var
  while (day.end <= dim(new.var)[3]){

    today = new.var[,,day.start:day.end]
    today.min = apply(today, c(1,2), min)
    today.max = apply(today, c(1,2), max)
    # In weather, a mean is the (min + max) / 2, not the actual mean of the hourly temperatures
    today.mean = (today.min + today.max) / 2
    
    # update the output data frame
    if (count == 1){
      min.day.array = today.min
      max.day.array = today.max
      mean.day.array = today.mean
    }else{
      # Adapt matrix test code from above to build out the correct length array
      min.day.array = array(c(min.day.array, today.min), dim = c(long, lat, count))
      max.day.array = array(c(max.day.array, today.max), dim = c(long, lat, count))
      mean.day.array = array(c(mean.day.array, today.mean), dim = c(long, lat, count))
    }
    
    # Increment starting and ending points
    day.start = day.end + 1
    day.end = day.end + 24
    count = count + 1
  }
  
  # Save the array as a data file with an array for each day
  save(min.day.array, file = sprintf("Vars/%s/DailyMins/DailyMin_%s_year_%s.rda", var, var, i + 1989))
  save(max.day.array, file = sprintf("Vars/%s/DailyMaxs/DailyMax_%s_year_%s.rda", var, var, i + 1989))
  save(mean.day.array, file = sprintf("Vars/%s/DailyMeans/DailyMean_%s_year_%s.rda", var, var, i + 1989))
  
  # Return array objects
  return(list(min.day.array, max.day.array, mean.day.array))
}

# calc.precip(90,30) # 60 - as expected
# calc.precip(30,90) # 40 - this is as desired - 30 for current day, and 10 for roll-over
# calc.precip(30,110) # 20 - this is as designed - it assumes all the prior rainfall rolled over, and 10 was from prior rainfall.

#' Calculate Precipitation
#'
#'@param x The current precipitation value
#'@param y The precipitation value from the prior timestep
#' 
calc.precip = function(x, y){
  
  # If x or y is NA, assign NA
  if (is.na(y) | is.na(x)){ out = NA  }
  
  # Otherwise:
  if (!is.na(y) & !is.na(x)){
    # Try subtraction
    out = x - y
    
    # 8/23/2022 We think the value may be carried over to the next day.
    # It's unclear, because there are examples where the next day is less than the carry-over,
    # but these are relatively infrequent.
    
    ## If it's negative, just use the value of x
    #if (out < 0){
    #  out = x
    #}
    
    # If it is negative, drop the 100's and subtract the excess from x
    count = 0
    while(out < 0){
      y = y - 100
      out = x - y
      # Create an upper limit for the number of while loops. This should never be reached.
      count = count + 1
      if (count == 100){
        out = NA
        message("Counter exceeded 100 for rainnc, and that means either an error occurred, or the rainnc vale was >10000, which should not happen")
        break
      }
    }
  }
  
  return(out)
}

#' Calculate daily Tmin, Tmax, and Tmean for each day in a year
#' 
#' Files will be saved into folders for easy organization
#' 
#' 
#' @param day.start 1 sets it to start with the first record of the simulation.
#' I think 1 would correspond to midnight GMT
#' inspection of the data suggests that it is likely GMT, so probably want the day to start at
#' 11 (11 - 10 = 1). If another daily rhythm is desired, adjust day.start as needed.
#' 
create.daily.ppt.files = function(i, var, new.var, timestep, island, part = 0){
  
  # https://www.geeksforgeeks.org/create-3d-array-using-the-dim-function-in-r/
  # https://www.tutorialspoint.com/r/r_arrays.htm
  
  lat = dim(new.var)[1]
  lon = dim(new.var)[2]
  n.steps = dim(new.var)[3]

  total.hour.count = 0
  day.count = 1
  hour.count = 0 # Change 2022-10-28, formerly 1.
  cum.precip = rep(0, lat * lon)
  # First value of the precipitation data sets are the last hour of the previous year, to use for initialization
  initial.values = matrix(new.var[ , , 1], nrow = 1)
  
    # Iterate through new.var
  for (k in 2:n.steps){
    
    # Convert the array to vector to allow differential processing
    this.precip = matrix(new.var[ , , k], nrow = 1)
    #Use a function to properly deal with negative values
    new.precip = mapply(calc.precip, this.precip, initial.values)
    initial.values = this.precip # update precipitation values for the next time step
    # update cumulative precipitation
    cum.precip = cum.precip + new.precip
    
    hour.count = hour.count + 1
    total.hour.count = total.hour.count + 1
    # If a new day is started, save off the values
    if (hour.count == 24){
      if (day.count == 1){
        day.ppt.array = cum.precip
      }else{
        # Adapt matrix test code from above to build out the correct length array
        day.ppt.array = array(c(day.ppt.array, cum.precip), dim = c(lat, lon, day.count))
      }
      cum.precip = rep(0, lat * lon)
      day.count = day.count + 1
      hour.count = 0
    }
  }
    
  # Save the array as a data file with an array for each day
  outfile = sprintf("Vars/%s/%s_%s/DailyPPT/DailyPPT_%s_%s_year_%s.rda",island, var, timestep, var, timestep, i + 1989)
  if (part != 0){
    outfile = sprintf("Vars/%s/%s_%s/DailyPPT/DailyPPT_%s_%s_year_%s_part_%s.rda",island, var, timestep, var, timestep, i + 1989, part)
  }
  save(day.ppt.array, file = outfile)

  # Return array objects
  return(day.ppt.array)
}


#' Calculate mean, min, and max temperature for a monthly interval
#' @param daily.stuff the three lists generated by the create.daily.files function
#' containing minimum, maximum, and mean daily temperatures
#' @param i the year being evaluated
#' @param var The variable being examined
#' 
calculate.min.max.mean.monthly = function(daily.stuff, i, var, leap.years){
  min.day.array = daily.stuff[[1]]
  max.day.array = daily.stuff[[2]]
  mean.day.array = daily.stuff[[3]]
  
  days.in.month = c(31,28,31,30,31,30,31,31,30,31,30,31) # Assuming Feb has 28 days - this will cause problems later if not fixed.
  if (i %in% leap.years){
    days.in.month[2] = 29 # Add an extra day in February
  }
  
  time.index = 1
  month.starts = c()
  month.ends = c()
  for (d in 1:length(days.in.month)){
    month.starts = c(month.starts, time.index)
    time.index = time.index + days.in.month[d]
    month.ends = c(month.ends, time.index - 1) # - 1 is to correct for the starting position
  }
  
  
  for (j in 1:12){
    mean.min.month.array = apply(min.day.array[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    mean.max.month.array = apply(max.day.array[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    mean.mean.month.array = apply(mean.day.array[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    save(mean.min.month.array, file = sprintf("Vars/%s/MonthlyMeans/Mins/%s_%s_%s_mean_min.rda", var, var, i, j))
    save(mean.max.month.array, file = sprintf("Vars/%s/MonthlyMeans/Maxs/%s_%s_%s_mean_max.rda", var, var, i, j))
    save(mean.mean.month.array, file = sprintf("Vars/%s/MonthlyMeans/Means/%s_%s_%s_mean_mean.rda", var, var, i, j))
  }
}

#' Calculate mean minimum, maximum, and mean annual values
#' 
#' @param daily.stuff the three lists generated by the create.daily.files function
#' containing minimum, maximum, and mean daily temperatures
#' @param i the year being evaluated
#' @param var The variable being examined
#' 
calculate.min.max.mean.annual = function(daily.stuff, i, var){
  min.day.array = daily.stuff[[1]]
  max.day.array = daily.stuff[[2]]
  mean.day.array = daily.stuff[[3]]

  mean.min.annual.array = apply(min.day.array[,,], c(1,2), mean)
  mean.max.annual.array = apply(max.day.array[,,], c(1,2), mean)
  mean.mean.annual.array = apply(mean.day.array[,,], c(1,2), mean)
  save(mean.min.annual.array, file = sprintf("Vars/%s/AnnualMeans/Mins/%s_%s_%s_mean_min.rda", var, var, i, j))
  save(mean.max.annual.array, file = sprintf("Vars/%s/AnnualMeans/Maxs/%s_%s_%s_mean_max.rda", var, var, i, j))
  save(mean.mean.annual.array, file = sprintf("Vars/%s/AnnualMeans/Means/%s_%s_%s_mean_mean.rda", var, var, i, j))
}


#' Calculate mean, min, and max temperature for an annual interval
#' 
calculate.min.max.mean.annual.didnt.work = function(i, new.var, leap.years, normal.year){
  stop("This function is in progress, and depends on the output of create.daily.files")
  #**# LEFT OFF HERE
  year.length = normal.year
  if (i %in% leap.years){
    year.length = normal.year + 24
  }
  
  #**# This approach really isn't going to work. We're going to need to make a daily tmin, tmax, tmean
  # data frame, and calculate statistics based on that. Same for monthly
  
  year.array = new.var[,,1]
  for (k in 2:dim(new.var)[3]){ # 3rd dimension is the number of timesteps in the year.
    year.array = year.array + new.var[,,k]
  }
  # Convert to average
  year.array = year.array / year.length #**# Except this will be 
  #end = Sys.time()
  # Loop is 1/3 s
  
  # Save the output result
  save(year.array, file = sprintf("AnnualMeans/%s_%s_mean.rda", var, i))
  
  
   
}


#' First attempt at a monthly average
#' 
#' Turns out they want Tmin, Tmax, and Tmean for the month, not just mean monthly temperature
do.raw.monthly.average = function(i, leap.years, new.var){
  # Do Monthly
  days.in.month = c(31,28,31,30,31,30,31,31,30,31,30,31) # Assuming Feb has 28 days - this will cause problems later if not fixed.
  if (i %in% leap.years){
    days.in.month[2] = 29 # Add an extra day in February
  }
  
  time.index = 1
  month.starts = c()
  month.ends = c()
  for (d in 1:length(days.in.month)){
    month.starts = c(month.starts, time.index)
    time.index = time.index + days.in.month[d]*24
    month.ends = c(month.ends, time.index - 1) # - 1 is to correct for the starting position
  }
  
  #**# NEED TO CONVERT TO AN AVERAGE OF DAILY MIN, MAX, & 'MEAN' TEMPS
  # In weather, a mean is the (min + max) / 2, not the actual mean of the hourly temperatures
  
  for (j in 1:12){
    month.array = new.var[,,month.starts[j]]
    for (k in (month.starts[j]+1):month.ends[j]){
      month.array = month.array + new.var[,,k]
    }
    month.array = month.array / (month.ends[j] - month.starts[j] + 1) # +1 accounts for inclusion of starting index
    save(month.array, file = sprintf("MonthlyMeans/%s_%s_%s_mean.rda", var, i, j))
  }
  
}


#' Calculate an annual mean temperature
#' 
#' NOTE: NOT ACTUALLY DESIRED - THEY WANT Tmin, Tmax, and Tmean by year
#'
#' #**# NOTE: normal.year does NOT account for leap years!
#'
do.annual = function(new.var, normal.year){
  # Do annual
  #Runs in ~1/3 s
  warning("Not currently adjusting for leap year above")
  #start = Sys.time()
  year.array = new.var[,,1]
  for (k in 2:dim(new.var)[3]){ # 3rd dimension is the number of timesteps in the year.
    year.array = year.array + new.var[,,k]
  }
  # Convert to average
  year.array = year.array / normal.year
  #end = Sys.time()
  # Loop is 1/3 s
  
  # Save the output result
  save(year.array, file = sprintf("AnnualMeans/%s_%s_mean.rda", var, i))
  
}


create.daily.df = function(STUFF){
  my.df = data.frame(YEAR = (i + 1989), MONTH = NA, DAY = NA,
                     TMIN = NA, TMAX = NA, TMEAN = NA, LAT = NA, LON = NA)
  #**# I'M NOT SURE THIS IS A GOOD IDEA - WE'D NEED TO DO THIS FOR _EVERY_ CELL
  # ABORTED.
}



#' Calculate mean, min, and max temperature for a monthly interval
#' @param daily.stuff the three lists generated by the create.daily.files function
#' containing minimum, maximum, and mean daily temperatures
#' @param i the year being evaluated
#' @param var The variable being examined
#' 
calculate.min.max.mean.monthly = function(daily.stuff, i, var, is.leap){
  min.day.array = daily.stuff[[1]]
  max.day.array = daily.stuff[[2]]
  mean.day.array = daily.stuff[[3]]
  
  days.in.month = c(31,28,31,30,31,30,31,31,30,31,30,31) # Assuming Feb has 28 days - this will cause problems later if not fixed.
  if (is.leap == 1){
    days.in.month[2] = 29 # Add an extra day in February
  }
  
  time.index = 1
  month.starts = c()
  month.ends = c()
  for (d in 1:length(days.in.month)){
    month.starts = c(month.starts, time.index)
    time.index = time.index + days.in.month[d]
    month.ends = c(month.ends, time.index - 1) # - 1 is to correct for the starting position
  }
  
  
  for (j in 1:12){
    mean.min.month.array = apply(min.day.array[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    mean.max.month.array = apply(max.day.array[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    mean.mean.month.array = apply(mean.day.array[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    save(mean.min.month.array, file = sprintf("Vars/%s/MonthlyMeans/Mins/%s_%s_%s_mean_min.rda", var, var, i, j))
    save(mean.max.month.array, file = sprintf("Vars/%s/MonthlyMeans/Maxs/%s_%s_%s_mean_max.rda", var, var, i, j))
    save(mean.mean.month.array, file = sprintf("Vars/%s/MonthlyMeans/Means/%s_%s_%s_mean_mean.rda", var, var, i, j))
  }
}

#' Calculate mean annual daily precipitation values
#' 
#' Can convert to total annual precipitation by multiplying by the number of days in the year
#' 
#' @param daily.stuff daily total rainfall
#' @param i the year being evaluated
#' @param var The variable being examined
#' @param is.leap an indicator, 1 for leap year, 0 for not a leap year.
#'
#' #**# THIS FUNCTION IS REDEFINED BELOW. NEED TO CONFIRM THAT IS THE CORRECT VERSION, THEN THIS ONE CAN BE DELETED. 
#calculate.mean.annual.ppt = function(daily.stuff, outpath){
#
#  #**# Doesn't actually matter, if calculating a mean  
#  #days = 365
#  #if (is.leap == 1){ days = 366  }
#  
#  mean.annual.ppt.array = apply(daily.stuff[,,], c(1,2), mean)
#  save(mean.annual.ppt.array, file = outpath)
#}

#' Calculate mean precipitation for a monthly interval
#' @param daily.stuff the daily precipitation file
#' @param i the year being evaluated
#' @param var The variable being examined
#' @param is.leap an indicator for whether or not the year is a leap year
#' 
calculate.mean.monthly.var = function(daily.stuff, i, var,timestep, is.leap, island, data.dir = "F:/hawaii_local",
                                      metric){

  month.path = sprintf("%s/Vars/%s/%s_%s/MonthlyMeans",data.dir, island, var, timestep)
  if (!file.exists(month.path)){
    dir.create(month.path)
  }
  
  days.in.month = c(31,28,31,30,31,30,31,31,30,31,30,31)
  if (is.leap == 1){
    days.in.month[2] = 29 # Add an extra day in February
  }
  
  time.index = 1
  month.starts = c()
  month.ends = c()
  for (d in 1:length(days.in.month)){
    month.starts = c(month.starts, time.index)
    time.index = time.index + days.in.month[d]
    month.ends = c(month.ends, time.index - 1) # - 1 is to correct for the starting position
  }

  metric.bit = ""
  if (metric != ""){ metric.bit = sprintf("%s_", metric)}
  
  for (j in 1:12){
    mean.month.array = apply(daily.stuff[,,month.starts[j]:month.ends[j]], c(1,2), mean)
    save(mean.month.array, file = sprintf("%s/%s%s_%s_%s_mean.rda", month.path, metric.bit, var, i, j))
  }
}

#' Calculate monthly climatology
calculate.monthly.climatologies = function(start.year, end.year, var, timestep,
                                           island, data.dir = "F:/hawaii_local",
                                           metric = "", is.cumulative = 1){
  
  clim.path = sprintf("%s/Vars/%s/%s_%s/Climatology", data.dir, island, var, timestep)
  if (!file.exists(clim.path)){
    dir.create(clim.path)
  }
  
  days.in.typical.month = c(31,28,31,30,31,30,31,31,30,31,30,31)
  
  metric.bit = ""
  if (metric != ""){metric.bit = sprintf("%s_", metric)}
  
  for (j in 1:12){
    mean.monthly.path = sprintf("%s/Vars/%s/%s_%s/MonthlyMeans/%s%s_%s_%s_mean.rda", data.dir, island, var, timestep, metric.bit, var, start.year, j)
    #print(mean.monthly.path)
    load(mean.monthly.path) # loads the mean.month.array object
    climatology = mean.month.array
    # Prevent accidental reuse of the object
    rm(mean.month.array)
    for (i in (start.year + 1):end.year){
      load(sprintf("%s/Vars/%s/%s_%s/MonthlyMeans/%s%s_%s_%s_mean.rda", data.dir, island, var, timestep, metric.bit, var, i, j)) # loads the mean.month.array object
      climatology = climatology + mean.month.array
      # Prevent accidental re-use of the object
      rm(mean.month.array)
    }
  
    climatology = climatology / (end.year - start.year + 1)
    if (is.cumulative == 1){
      climatology = climatology * days.in.typical.month[j]
    }
    
    # Replace NA values with interpolated values #**# Long-term - should look into why NA's are even happening in the first place.
    climatology = interpolate.nas(climatology)
    
    save(climatology, file = sprintf("%s/%s%s_month_%s.rda", clim.path, metric.bit, var, j))
  }
}

#' Interpolate NA values to be intermediate between the next two values in space.
#' 
#' #**# Seems like there has to be a smarter way to do this with an existing tool.
#' na.approx from the zoo package does it for a vector. But I didn't see something obvious for an array.
#' 
#' #**# More sophisticated approaches could be used here, but there are so few NA's it shouldn't actually matter much to the overall outcome.
#' BUT the NA's are causing downstream processing problems, so they need to be removed, and ArcGIS wasn't letting Null work.
interpolate.nas = function(climatology){
  # Note: does not interpolate for the first or last value. Assumes NA values are single values, and not series.
  dimensions = dim(climatology)
  for (i in (2:dimensions[1] -1)){
    for (j in (2:dimensions[2] - 1)){
      this.value = climatology[i,j]
      if (is.na(this.value)){
        climatology[i,j] = (climatology[i, j + 1] + climatology[i, j -1] + climatology[i +1, j] + climatology[i - 1, j]) / 4
      }
    }
  }
  return(climatology)
}

#' Calculate mean precipitation for a year
#' @param daily.stuff the daily precipitation file
#' @param i the year being evaluated
#' @param var The variable being examined
#' @param is.leap an indicator for whether or not the year is a leap year
#' 
calculate.mean.annual.var = function(daily.stuff, i, var, timestep, is.leap, island, data.dir = "F:/hawaii_local",
                                     metric = ""){
  
  ann.path = sprintf("%s/Vars/%s/%s_%s/AnnualMeans", data.dir, island, var, timestep)
  if (!file.exists(ann.path)){
    dir.create(ann.path)
  }
  
  days = 365
  if (is.leap == 1){
    days = 366
  }
  
  if (i == 20){
    if (dim(daily.stuff)[3] < days){
      stop("Fewer days in the daily file than expected")
      #days = dim(daily.stuff)[3]
      #warning(sprintf("Days adjusted for year %s to %s. One day's loss due to GMT offset was expected.", (i + 1989), days))
    }
  }
  metric.bit = ""
  if (metric != ""){ metric.bit = sprintf("%s_", metric)}
  
  mean.annual.array = apply(daily.stuff[,,1:days], c(1,2), mean)
  save(mean.annual.array, file = sprintf("%s/%s%s_%s_mean.rda", ann.path, metric.bit, var, i))
    
}

#' Calculate annual climatology
calculate.annual.climatologies = function(start.year, end.year, var, timestep, island,
                                          data.dir = "F:/hawaii_local", metric.bit = "",
                                          is.cumulative = 1){

  clim.path = sprintf("%s/Vars/%s/%s_%s/Climatology", data.dir, island, var, timestep)
  if (!file.exists(clim.path)){
    dir.create(clim.path)
  }
  
  metric.bit = ""
  if (metric != ""){ metric.bit = sprintf("%s_", metric)}
  
  load(sprintf("%s/Vars/%s/%s_%s/AnnualMeans/%s%s_%s_mean.rda", data.dir, island, var, timestep, metric.bit, var, start.year)) # loads the mean.annual.array object
  climatology = mean.annual.array
  # Prevent accidental reuse of the object
  rm(mean.annual.array)
  for (i in (start.year + 1):end.year){
    load(sprintf("%s/Vars/%s/%s_%s/AnnualMeans/%s%s_%s_mean.rda", data.dir, island, var, timestep, metric.bit, var, i)) # loads the mean.month.array object
    climatology = climatology + mean.annual.array
    # Prevent accidental re-use of the object
    rm(mean.annual.array)
  }
  
  climatology = climatology / (end.year - start.year + 1)
  
  if (is.cumulative == 1){
    # Multiply by number of days in a typical year
    climatology = climatology * 365
  }
  
  # Remove any NA values through interpolation to avoid problems later on.
  climatology = interpolate.nas(climatology)
  
  save(climatology, file = sprintf("%s/%s%s_Annual.rda", clim.path, metric.bit, var))
}


#' Save Out the result in the format of the user's choice
#' 
#' 
save.out = function(current.values, TemporalRes, Format, out.path,
                    Island, Scenario, Variable, Aggregation, FirstDOY, current.year,
                    rainfall.grid){
  
  saved = 0
  if (Format == "R Array and Native_WRF"){
    out.file = sprintf("%s/%s_%s_%s_%sday_%s_%s_%s.rda", out.path, Island, Scenario, Variable,
                       TemporalRes, Aggregation, FirstDOY, current.year)
    #**# Do we want to give current.values a different name?
    save(current.values, file = out.file)
    saved = 1
  }
  
  if (Format == "CSV"){
    out.file = sprintf("%s/%s_%s_%s_%sday_%s_%s_%s.csv", out.path, Island, Scenario, Variable,
                       TemporalRes, Aggregation, FirstDOY, current.year)
    island.grid = sprintf("C:/hawaii_local/Vars/grids/wrf_grids/%s_xy_grid_index.csv", Island) #**# FIX TO BE AN INPUT OR BE RELATIVE TO OUTPATH.
    convert.to.csv(current.values, out.file, island.grid)
    saved = 1
  }
  
  if (Format == "Raster and Hawaii Rainfall Atlas"){
    out.file = sprintf("%s/%s_%s_%s_%sday_%s_%s_%s", out.path, Island, Scenario, Variable,
                       TemporalRes, Aggregation, FirstDOY, current.year) #**# What is file extension?
    
    # Interpolate values to HI Rainfall Atlas Grid
    
    #Read in a separate Grid file template with Lat/Lon.
    
    # Calculate distance to each point in the lat/lon grid for the X closest points.
    
    # Interpolate the values for the new grid values
    
    # Save the interpolated values as a raster file with the correct orientation. 
    
    
    # Save in Raster format
    #**# How do we do this again?
    
    stop("Nothing was saved, that format is still being coded out!")
    saved = 1
  }
  
  # Since it is a drop-down choice, seems like the user should never get here.
  if (saved == 0){
    stop(sprintf("Support for %s has not yet been scripted", Format))
  }
}

#' Convert a 2D array into a .csv file with lat, lon, and value fields
convert.to.csv = function(current.values, out.file, island.grid, int100 = FALSE){
  
  this.grid = read.csv(island.grid)
  # Clear out default values
  this.grid$values = NA
  
  for (i in 1:nrow(this.grid)){
    lat_index = this.grid$lat_index[i]
    lon_index = this.grid$lon_index[i]
    this.value = current.values[lon_index, lat_index]
    
    # Convert to an integer value * 100 to preserve two decimal places
    if (int100 == TRUE){
      this.value = this.value * 100
      this.value = round(this.value, digits = 0)
    }
    
    this.grid$values[i] = this.value
  }
  
  write.table(this.grid, file = out.file, sep = ',', row.names = FALSE,
              col.names = TRUE)
  
}

#' Replace bad day in the daily data for Maui with prior day
#' 
fix.ppt.2007.365 = function(base.path){
  load(sprintf("%s/DailyPPT_rainnc_rcp45_year_2007.rda", base.path)) # Loads the day.ppt.array
  day.ppt.array[,,365] = day.ppt.array[,,364]
  save(day.ppt.array, file = sprintf("%s/DailyPPT_rainnc_rcp45_year_2007.rda", base.path))
}


#' Get Canopy Height
#' 
#' @param vegetation.category The category from the IVGTYP variable in the WRF model output
#' @param vegetation.lookup a lookup table with the vegetation heights and roughnesses by vegetation code
#' 
#' @return veg.vec a vector with canopy height, max surface roughness, and minimum surface roughness
#' 
get.canopy.height = function(vegetation.category, vegetation.lookup){
  
  veg.row = grep(sprintf("^%s$", vegetation.category), vegetation.lookup$LC_Code) # need ^ and $ to prevent 1 from matching 1 and 10, etc.
  
  veg.vec = c(vegetation.lookup$ZTOPV[veg.row], vegetation.lookup$Z0MAX[veg.row], vegetation.lookup$Z0MIN[veg.row])
  
  return(veg.vec)  
}