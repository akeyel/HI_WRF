# Extract variables to annual files

# A.C. Keyel
# From Workflow_v2.R that was created 2021-12-14

# Set working directory
setwd(data.dir)

# Open the data file
my.ncdf =ncdf4::nc_open(data.file)

# Extract Variable Information
normal.year = 8760

ppt.offset = 0
if (is.ppt == 1){
  # Need an extra hour point to calculate the difference relative to the prior hour in computing rainfall
  normal.year = 8761
  ppt.offset = -1
}

# check if island path exists, if not, stop and confirm the user has selected the correct path
island.path = sprintf("Vars/%s", island)
if (!file.exists(island.path)){
  stop(sprintf("Please check that %s exists and that the correct directory has been selected", island.path))
}


for (var in var.vec){

    
  # Check if a directory exists for this variable, if not, create it and the associated sub-directories
  main.path = sprintf("Vars/%s/%s", island, var)
  if (island == "maui" | island == "hawaii"){
    stop("Please use 001b_ExtractAnnual.R to avoid memory issues with the extraction process
         and for correct processing of the data structure")
  }
  
  if (!file.exists(main.path)){
    create.my.directories(main.path, ppt.offset)
  }
  message(var)
  # Extract Annual hourly data
  n.leap.years = 0
  for (i in first.year:last.year){
    message(sprintf("Year %s", i + 1989))
    year.start = (i - 1) * normal.year + 1 + n.leap.years * 24 + TimeZone.Offset + ppt.offset  # Add 24 hours for each the leap day
    year.timesteps = normal.year
    
    # Adjust for leap years (update within calculations, because a leap year will need an adjustment to the end, but not the start)
    if (i %in% leap.years){
      n.leap.years = n.leap.years + 1
      year.timesteps = normal.year + 24 # Add an extra day
    }
    year.end = i * normal.year + n.leap.years * 24  + TimeZone.Offset # + ppt.offset # Should not be included - that was to get an extra hour at the beginning!
    
    
    if (year.end > length(my.ncdf$dim$Time$vals)){
      year.end = length(my.ncdf$dim$Time$vals)
      year.timesteps = year.end - year.start  # ODD - a +1 worked for most variables, but not for rainfall.
      warning("The end of the year is beyond the last data timestep. Timestep truncated to last available data. Extrapolation likely needed to finish out the data set")
    }
    
    new.var = ncvar_get(my.ncdf, var, start = c(1,1,year.start), count = c(-1,-1,year.timesteps))

    message(year.start)
    message(year.end)
    message(year.timesteps)
    save(new.var, file = sprintf("%s/AnnualHourly/%s_year_%s_%s.rda",main.path, var, i, TimeZone.Label))
    
  }
}

# close the netcdf
nc_close(my.ncdf)

