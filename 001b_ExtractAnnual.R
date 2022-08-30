# Extract variables to annual files

# A.C. Keyel
# From Workflow_v2.R that was created 2021-12-14

warning("Data for Hawaii and Maui are extracted in three 4-month intervals. These will need to be stitched together at some point")
#**# Would it be better to patch together during the daily computations? Don't know that that would be any easier
#**# Or could do monthly files - need to think about how to stitch together across years anyhow.


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
    main.path = sprintf("Vars/%s/%s_%s", island, var, timestep)
  }
  
  if (!file.exists(main.path)){
    create.my.directories(main.path, ppt.offset)
  }
  message(var)
  # Extract Annual hourly data
  n.leap.years = 0
  for (i in first.year:last.year){
    
    # Break year into thirds to avoid memory error
    for (j in 1:3){
      # How many hours in the first 6 months of the year?
      #days =  31 + 28 + 31 + 30 +  31 + 30 + 31 + 31
      #hours = 24 * days
      hours1 = 2880
      hours2 = 2952
      #hours = 4344 # for Jan 1 - June 30
      
      message(sprintf("Year %s", i + 1989))
    
      if (j == 1){
        year.start = (i - 1) * normal.year + 1 + n.leap.years * 24 + TimeZone.Offset + ppt.offset  # Add 24 hours for each the leap day
        year.timesteps = hours1  }
      if (j == 2){
        year.start = (i - 1) * normal.year + 1 + n.leap.years * 24 + TimeZone.Offset + ppt.offset + hours1  # Add 24 hours for each the leap day
        year.timesteps = hours2}
      if (j == 3){
        year.start = (i - 1) * normal.year + 1 + n.leap.years * 24 + TimeZone.Offset + ppt.offset + hours1 + hours2  # Add 24 hours for each the leap day
        year.timesteps = normal.year - hours1 - hours2        
      }

      # Adjust for leap years (update within calculations, because a leap year will need an adjustment to the end, but not the start)
      if (i %in% leap.years & j == 1){
        n.leap.years = n.leap.years + 1
        if (j == 1){  year.timesteps = year.timesteps + 24 } # Add an extra day 
        #if (j == 2 | j == 3){  year.start = year.start + 24 } # add an extra day before starting # Not needed - leap year has already incremented on j = 1
      }
      if (j == 1){ year.end = (i - 1) * normal.year + n.leap.years * 24 + TimeZone.Offset + hours1   }
      if (j == 2){ year.end = (i - 1) * normal.year + n.leap.years * 24  + TimeZone.Offset + hours1 + hours2  }
      if (j == 3){ year.end = i * normal.year + n.leap.years * 24 + TimeZone.Offset }
      
      if (year.end > length(my.ncdf$dim$Time$vals)){
        year.end = length(my.ncdf$dim$Time$vals)
        year.timesteps = year.end - year.start  # ODD - a +1 worked for most variables, but not for rainfall.
        warning("The end of the year is beyond the last data timestep. Timestep truncated to last available data. Extrapolation likely needed to finish out the data set")
      }
      
      new.var = ncvar_get(my.ncdf, var, start = c(1,1,year.start), count = c(-1,-1,year.timesteps))

      message(year.start)
      message(year.end)
      message(year.timesteps)
      save(new.var, file = sprintf("%s/AnnualHourly/%s_%s_year_%s_%s_%s.rda",main.path, var, timestep, i, j, TimeZone.Label))
    }
  }
}

# close the netcdf
nc_close(my.ncdf)

