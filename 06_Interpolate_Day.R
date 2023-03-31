# Interpolate the missing day for present day scenario

# Look at the data to come up with a solid approach to interpolation for this variable
#base.path = "F:/hawaii_local/Vars/maui"
precip.interpolation.exploration = function(base.path){
  setwd(base.path)
  # Find the missing day
  jan1 = 365*24*6 + 24 + 1 # 365 days in a year, 24 hours in a day, for 6 years (1996 is year 7), plus one leap day (1996 leap day hasn't happened yet) + 1 to move to the new day
  
  jan1.index = jan1 - 52000 
  # Pick a few focal evaluation points
  eval.rows = c(11,30,34,42,66)
  eval.cols = c(101,139,101,177,104)
  
  # Examine precipitation from corresponding time from RCP scenarios for Jan 1 & Jan 2
  
  pdf("F:/hawaii_local/Supporting/Day_Interpolation/Precip_Same_Day_Future_Scenarios.pdf")
  for (scenario in c("rcp45", "rcp85")){
    for (variable in c('I_RAINNC', 'RAINNC')){
      # Start with I_RAINNC
      load(sprintf("%s_%s/hourly_raw/maui_%s_%s_53000.rda", variable, scenario, variable, scenario))
      # loads the hourly object
      
      for (i in 1:length(eval.rows)){
        this.row = eval.rows[i]
        this.col = eval.cols[i]
        plot(hourly[this.col, this.row, (jan1.index):(jan1.index + 23 + 24)], ylab = variable)
        mtext(sprintf("Maui, %s %s Jan 1, 1996, row %s col %s", scenario, variable, this.row, this.col))
      }
    }
  }
  
  dev.off()
  
  # Examine precipitation from corresponding time from similar days of the year from present scenario
  #plot(hourly[this.col, this.row, (jan1.index - 24):(jan1.index - 1)])
  
  # Check if rainfall from present day simulation lines up with rainfall from the RCP scenarios
  n.days = 17 # days # Only 41 complete days within a file, so we'd need to parse a couple of files if we need more than that.
  pdf("F:/hawaii_local/Supporting/Day_Interpolation/Precipitation_Alignment_plot_longer.pdf")
  
  y.mins = c(0,0,0,0,0)
  y.maxs = c(250, 600, 210, 2500, 1200)
  # Loop through evaluation points  
  for (i in 1:length(eval.rows)){
    this.row = eval.rows[i]
    this.col = eval.cols[i]
    y.min = y.mins[i]
    y.max = y.maxs[i]
    
    # Set up RCP 4.5
    load("I_RAINNC_rcp45/hourly/maui_I_RAINNC_rcp45_53000.rda")
    #rcp45 = hourly[this.col, this.row, (jan1.index - 24*n.days):(jan1.index + 24*n.days)]
    rcp45.p1 = hourly[this.col, this.row, (jan1.index - 24*n.days):1000]
    load("I_RAINNC_rcp45/hourly/maui_I_RAINNC_rcp45_54000.rda")
    rcp45.p2 = hourly[this.col, this.row, 1:1000]
    rcp45 = c(rcp45.p1, rcp45.p2)
    rcp.min = min(rcp45)
    load("RAINNC_rcp45/hourly/maui_RAINNC_rcp45_53000.rda")
    rcp45.nc.p1 = hourly[this.col, this.row, (jan1.index - 24*n.days):1000]
    load("RAINNC_rcp45/hourly/maui_RAINNC_rcp45_54000.rda")
    rcp45.nc.p2 = hourly[this.col, this.row, 1:1000]
    
    rcp45 = (rcp45 - rcp.min)*100 + c(rcp45.nc.p1, rcp45.nc.p2)
    #rcp45 = (rcp45 - rcp.min) * 100  + hourly[this.col, this.row, (jan1.index - 24*n.days):(jan1.index + 24*n.days)]
    
    plot(seq(1,length(rcp45)), rcp45, ylab = "Precipitation", xlab = "time index (hours)",
         ylim = c(y.min, y.max))
    mtext(sprintf("Row: %s, Col %s, days: %s", this.row, this.col, n.days * 2))
    par(new = TRUE)
  
  # Set up RCP 8.5
    load("I_RAINNC_rcp85/hourly/maui_I_RAINNC_rcp85_53000.rda")
    #rcp85 = hourly[this.col, this.row, (jan1.index - 24*n.days):(jan1.index + 24*.days)]
    rcp85.p1 = hourly[this.col, this.row, (jan1.index - 24*n.days):1000]
    load("I_RAINNC_rcp85/hourly/maui_I_RAINNC_rcp85_54000.rda")
    rcp85.p2 = hourly[this.col, this.row, 1:1000]
    rcp85 = c(rcp85.p1, rcp85.p2)
    rcp.min = min(rcp85)
    load("RAINNC_rcp85/hourly/maui_RAINNC_rcp85_53000.rda")
    rcp85.nc.p1 = hourly[this.col, this.row, (jan1.index - 24*n.days):1000]
    load("RAINNC_rcp85/hourly/maui_RAINNC_rcp85_54000.rda")
    rcp85.nc.p2 = hourly[this.col, this.row, 1:1000]
    
    #rcp85 = (rcp85 - rcp.min) * 100  + hourly[this.col, this.row, (jan1.index - 24*n.days):(jan1.index + 24*n.days)]
    rcp85 = (rcp85 - rcp.min) * 100 + c(rcp85.nc.p1, rcp85.nc.p2)
    plot(seq(1,length(rcp85)), rcp85, ylab = "", xlab = "",col = 'red',
         ylim = c(y.min, y.max))
    
    par(new = TRUE)
    
  # Set up present time series
    load("I_RAINNC_present/hourly_raw/maui_I_RAINNC_present_53000.rda")
    present.p1 = hourly[this.col, this.row, (jan1.index - 24*n.days):(jan1.index - 1)]
    #present.p2 = hourly[this.col, this.row, (jan1.index + 24):(jan1.index + 24*n.days)]
    present.p2 = hourly[this.col, this.row, (jan1.index + 24):1000]
    load("I_RAINNC_present/hourly_raw/maui_I_RAINNC_present_54000.rda")
    present.p3 = hourly[this.col, this.row, 1:1000]
    rcp.min = min(c(present.p1, present.p2, present.p3))
    present = c(present.p1, rep(NA, 24), present.p2, present.p3)
    #length(present) == length(rcp85) # TRUE, checks that I got the correct number of elements when patching things together.
    load("RAINNC_present/hourly_raw/maui_RAINNC_present_53000.rda")
    present.p1.nc = hourly[this.col, this.row, (jan1.index - 24*n.days):(jan1.index - 1)]
    #present.p2.nc = hourly[this.col, this.row, (jan1.index + 24):(jan1.index + 24*n.days)]
    present.p2.nc = hourly[this.col, this.row, (jan1.index + 24):1000]
    load("RAINNC_present/hourly/maui_RAINNC_present_54000.rda")
    present.p3.nc = hourly[this.col, this.row, 1:1000]
    
    
    present.nc = c(present.p1.nc, rep(NA, 24), present.p2.nc, present.p3.nc)
    present = (present - rcp.min) * 100  + present.nc
    
    plot(seq(1,length(present)), present, ylab = "", xlab = "",col = 'blue',
         ylim = c(y.min, y.max))
    
    z.starts.1 = c(1380,1380,1380,1380,1380)
    z.ends.1 = c(1410,1410, 1410,1400,1400)
    z.starts.2 = c(1555,1555, 1555, 1490, 1490)
    z.ends.2 = c(1585,1585, 1585,1575, 1575)
    #if (i == 1){
      # Look zoomed in at rainfall events from i = 1 near 1400 and 1600
      z.start = z.starts.1[i]
      z.end = z.ends.1[i]
      plot(seq(1,length(rcp45))[z.start:z.end], rcp45[z.start:z.end],
           ylab = "", xlab = "",col = 'black',
           ylim = c(y.min, y.max))
      par(new = TRUE)
      plot(seq(1,length(rcp85))[z.start:z.end], rcp85[z.start:z.end],
           ylab = "", xlab = "",col = 'red',
           ylim = c(y.min, y.max))
      par(new = TRUE)
      plot(seq(1,length(present))[z.start:z.end], present[z.start:z.end],
           ylab = "", xlab = "",col = 'blue',
           ylim = c(y.min, y.max))
      mtext(sprintf("Zoom1: Row: %s, Col %s, days: %s", this.row, this.col, n.days * 2))
      
      
      z.start = z.starts.2[i]
      z.end = z.ends.2[i]
      plot(seq(1,length(rcp45))[z.start:z.end], rcp45[z.start:z.end],
           ylab = "", xlab = "",col = 'black',
           ylim = c(y.min, y.max))
      par(new = TRUE)
      plot(seq(1,length(rcp85))[z.start:z.end], rcp85[z.start:z.end],
           ylab = "", xlab = "",col = 'red',
           ylim = c(y.min, y.max))
      par(new = TRUE)
      plot(seq(1,length(present))[z.start:z.end], present[z.start:z.end],
           ylab = "", xlab = "",col = 'blue',
           ylim = c(y.min, y.max))
      mtext(sprintf("Zoom2: Row: %s, Col %s, days: %s", this.row, this.col, n.days * 2))
      
    #}
  }
  dev.off()
  
  
}


#base.path = "F:/hawaii_local/Vars/maui"

# Create tests to see if the interpolation function works properly
#interpolate.day.rainfall(100, 101, 50, 60)
#interpolate.day.rainfall(100, 100, 50, 60)
#interpolate.day.rainfall(100,105, 1,80)
#interpolate.day.rainfall(100,101,99,1)
#interpolate.day.rainfall(100,99,1,80)
#interpolate.day.rainfall(100,100, 60,40)

interpolate.day.rainfall = function(i.rain.start, i.rain.end, rainnc.start, rainnc.end){
    
  # Use NA for a default, but this should not actually be output
  i_rain = c()
  rainnc = c()
  
  # Find the starting I_RAIN and ending I_RAIN. If same, no need to change the I_RAIN variable.
  #if (i.rain.start == i.rain.end){
  #  i_rain = rep(i.rain.start, 24)
  #}

  # If there is an error - stop the process  (this is now redundant with the check at the bottom)
  if (i.rain.end < i.rain.start){
    stop("Somehow I_RAIN DECREASED over time. This is not possible, and the data need to be investigated for accuracy")
  }
  # If different, find where I_RAIN should be incremented, and increment it there
  #if (i.rain.end > i.rain.start){
  # Add to the rainnc difference
  i.rain.diff = i.rain.end - i.rain.start
  
  #**# Probably going to have to relax this - I think I already saw problems with this in the data set.
  if (i.rain.diff != round(i.rain.diff, 0)){
    stop("Something went wrong, i_rain should be integers, not fractions")
  }
  
  rainnc.end = rainnc.end + i.rain.diff*100
  #message(rainnc.end)
  
  # Do RAINNC interpolation
  rainnc.diff = rainnc.end - rainnc.start
  #message(rainnc.diff)
  hourly.increment = rainnc.diff / 24
  rain.amount = rainnc.start
  i.rain.amount = i.rain.start
  for (i in 1:24){
    rain.amount = rain.amount + hourly.increment
    if (rain.amount > 100 & i.rain.diff > 0){
      i.rain.diff = i.rain.diff - 1
      rain.amount = rain.amount - 100
      i.rain.amount = i.rain.amount + 1
    }
    
    rainnc = c(rainnc, rain.amount)
    i_rain = c(i_rain, i.rain.amount)
  }
  
  # Check that all i.rains have been assigned
  if (i.rain.diff > 0){
    stop("There is leftover rainfall, and this should not have happened. Please look to see what went wrong.")
  }
#  }
  
  if (length(i_rain) != 24 | length(rainnc) != 24){
    stop("There should be 24 entries for rainfall variables")
  }
  
  if ((i_rain[1]*100 + rainnc[1]) > (i_rain[24]*100 + rainnc[24])){
    stop("Rainfall at the beginning of the interpolated series was larger than at the end. Something went wrong, likely with the input values")
  }
  
  # Round RAINNC to avoid weird fractions
  return(list(i_rain, round(rainnc,5)))
}


# Fix present time series for Hawaii and Maui for present-day precipitation
# Need a separate function for Oahu/Kauai
# missing I_RAIN variable actually makes this approach rather problematic, as there is no way to know what the total amount of missing rainfall was.
# That may look more like a temperature interpolation.
fix.hm.ppt.timeseries = function(base.path, island){
  # base.path = "F:/hawaii_local/Vars/maui"
  # island = 'maui'
  setwd(base.path)
  # Assumes data have been downloaded in chunks of 1000
  # Note that this will shift all files after Jan 1, 1996
  # Copy the RAINNC_present and I_RAINNC_present directories for backup purposes
  
  vars = c("RAINNC", "I_RAINNC")
  for (var in vars){
    main.folder.nc = sprintf("%s_present/hourly", var)
    new.folder.nc = sprintf("%s_present/hourly_raw", var)
    
    #**# Add a check for e05 problem, if so, stop and have user rename files.
    
    if (!file.exists(new.folder.nc)){
      stop("Please rename the hourly folder hourly_raw. Please copy files 1000 - 53000 into a new hourly folder. The rest of the files will be filled in by the script.")
      # https://www.r-bloggers.com/2014/11/copying-files-with-r/
      # Faster to do this outside of R, than with the current implementation. But have it do this by default in case the user forgets.
      #dir.create(new.folder.nc)
      #message("Copying files into a backup folder. This implementation is slow, (>5 minutes)
      #        and you would be better off creating the backup copy in hourly_raw folder yourself before running this script.")
      #
      #files = list.files(main.folder.nc)
      #files = sprintf("%s/%s", main.folder.nc, files)
      #file.copy(files, new.folder.nc)
    }
  }

  # Find location of Jan 1, 1996
  jan1 = 365*24*6 + 24 + 1 # 365 days in a year, 24 hours in a day, for 6 years (1996 is year 7), plus one leap day (1996 leap day hasn't happened yet) + 1 to move to the new day
  
  # Read in the files
  # load present day I_RAIN
  load(sprintf("I_RAINNC_present/hourly_raw/%s_I_RAINNC_present_53000.rda", island)) # loads the hourly object
  irain.var = hourly
  rm(hourly)

  dims = dim(irain.var)
  
  # load present day RAINNC
  load(sprintf("RAINNC_present/hourly_raw/%s_RAINNC_present_53000.rda", island)) # loads the hourly object
  rainnc.var = hourly
  rm(hourly)

  # Get the indices for the interpolation
  dec31 = (jan1 - 1) - 52000
  jan2 = (jan1) - 52000
  # Add an index for jan2 post-interpolation
  jan2.post = jan2 + 24
  
  # Create an array to contain everything
  i.array = array(data = rep(NA), dim = c(dims[1],dims[2],dims[3]))
  nc.array = array(data = rep(NA), dim = c(dims[1],dims[2],dims[3]))

  # Fill in part BEFORE the patch
  i.array[1:dims[1],1:dims[2],1:dec31] = irain.var[1:dims[1], 1:dims[2], 1:dec31]
  nc.array[1:dims[1],1:dims[2],1:dec31] = rainnc.var[1:dims[1], 1:dims[2], 1:dec31]
  
  #patch.array.i = array(data = rep(NA), dim = c(dims[1],dims[2],24))
  #patch.array.nc = array(data = rep(NA), dim = c(dims[1],dims[2], 24))
  
  # Check accuracy for 167 42 for a time period with rain to confirm things are going into the array correctly.
  # rainnc.var[167:172, 42:47,127:132]
  # nc.array[167:172, 42:47, 127:132]
  
  # Fill in AFTER the patch
  i.array[1:dims[1],1:dims[2],jan2.post:1000] = irain.var[1:dims[1], 1:dims[2], jan2:(1000 - 24)]
  nc.array[1:dims[1], 1:dims[2], jan2.post:1000] =  rainnc.var[1:dims[1], 1:dims[2], jan2:(1000 - 24)]
  
  # Check the after array part
  # nc.array[167:168, 42:43,977:1000] #  Full last day, but hard to look at in R!
  # rainnc.var[167:168,42:43,953:976]
  #nc.array[167:168, 42:43,977:978]
  #rainnc.var[167:168,42:43,953:955]
  #nc.array[167:168, 42:43,999:1000]
  #rainnc.var[167:168,42:43,975:976]
  # Above check is not useful - no rainfall, so no way to know if it's working especially
  
  #rainnc.var[167,42, 799:804]
  #nc.array[167,42,823:828]
    
  # Check that the patch section was NOT filled in.
  #nc.array[167,42,jan2:(jan2.post - 1)]
  
  # RUN THE INTERPOLATION
  for (i in 1:dims[1]){
    for (j in 1:dims[2]){

      # Get i.rain.start, i.rain.end, rainnc.start and rainnc.end for this set of indices
      i.rain.start = irain.var[i,j, dec31] # Since Jan 1 is missing, need the time step immediately before it.
      i.rain.end = irain.var[i,j, jan2] # Since Jan 1 is missing, this is the start of the next day

      rainnc.start = rainnc.var[i,j,dec31]
      rainnc.end = rainnc.var[i,j,jan2]
      
      # Run the interpolation
      stuff = interpolate.day.rainfall(i.rain.start, i.rain.end, rainnc.start, rainnc.end)  
      irains = stuff[[1]]
      rainncs = stuff[[2]]
      
      # Add this set to the arrays under construction
      #patch.array.i[i,j,1:24] = irains
      #patch.array.nc[i,j,1:24] = rainncs
      i.array[i,j,jan2:(jan2.post - 1)] = irains
      nc.array[i,j,jan2:(jan2.post - 1)] = rainncs
      
      # Check that now the interpolated day is filled in.
      # nc.array[1,1,jan2:(jan2.post - 1)] # Switched to 1,1 compared to above, because that one hadn't been filled in yet during testing!
    }
  }

  # Check that things look right. Looks OK now.
  #plot(i.array[167,42,1:1000])
  #plot(irain.var[167,42,1:1000])
  #plot(nc.array[167,42,1:1000])
  #plot(rainnc.var[167,42,1:1000])
  
  #plot(i.array[167,42,580:620])
  #plot(irain.var[167,42,580:620])

  #plot(nc.array[167,42,560:620])
  #plot(rainnc.var[167,42,560:620])
  
  
  # Save updated arrays to file (this is a slow step)
  hourly = i.array
  save(hourly, file = sprintf("I_RAINNC_present/hourly/%s_I_RAINNC_present_53000.rda", island)) # saves the hourly object
  rm(hourly)
  hourly = nc.array
  save(hourly, file = sprintf("RAINNC_present/hourly/%s_RAINNC_present_53000.rda", island))

  # Update remaining files
  for (var in vars){
    # Repeat until no files are left.
    for (i in 54:175){
      print(i)
      
      # Create blank arrays to contain everything
      this.array = array(data = NA, dim = c(dims[1],dims[2],1000))
      #nc.array = array(data = NA, dim = c(dims[1],dims[2],1000))
      
      # Extract last 24 hours
      # Load previous file
      load(sprintf("%s_present/hourly_raw/%s_%s_present_%s000.rda", var, island, var, (i- 1)))
      this.array[1:dims[1], 1:dims[2],1:24] = hourly[1:dims[1],1:dims[2],977:1000]
      
      # Quick visual check that things are going OK for i = 54
      #this.array[1:2,1:2,1:25]
      # hourly[1:2,1:2,977:1000]
      
      # Load current file
      # Extract all but last 24 hours
      load(sprintf("%s_present/hourly_raw/%s_%s_present_%s000.rda", var, island, var, i))
      this.array[1:dims[1], 1:dims[2],25:1000] = hourly[1:dims[1],1:dims[2],1:976]
      
      # Basic check - does it make a plot? Yes - looks normal, but I did not check the specific numbers.
      # plot(this.array[167,42,1:1000])

      # Save merged file
      rm(hourly) # Make sure we're saving the right thing
      hourly = this.array
      save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_%s000.rda", var, island, var, i))
      rm(hourly)
    }
    
    # Special handling for the very last file
    this.array = array(data = NA, dim = c(dims[1],dims[2],320))
    load(sprintf("%s_present/hourly_raw/%s_%s_present_175000.rda", var, island, var))
    this.array[1:dims[1], 1:dims[2],1:24] = hourly[1:dims[1],1:dims[2],977:1000]
    load(sprintf("%s_present/hourly_raw/%s_%s_present_175296.rda", var, island, var))
    this.array[1:dims[1], 1:dims[2],25:320] = hourly[1:dims[1],1:dims[2],1:296]
    # Save merged file
    rm(hourly) # Make sure we're saving the right thing
    hourly = this.array
    save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_175320.rda", var, island, var))
    rm(hourly)
  }
}

# Fix present time series for Hawaii and Maui for present-day precipitation
# Need a separate function for Oahu/Kauai
# missing I_RAIN variable actually makes this approach rather problematic, as there is no way to know what the total amount of missing rainfall was.
# That may look more like a temperature interpolation.
fix.ok.ppt.timeseries = function(base.path, island){
  #base.path = "F:/hawaii_local/Vars/oahu"
  #island = 'oahu'
  setwd(base.path)
  # Assumes data have been downloaded in chunks of 1000
  # Note that this will shift all files after Jan 1, 1996

  var = "RAINNC"
  main.folder.nc = sprintf("%s_present/hourly", var)
  new.folder.nc = sprintf("%s_present/hourly_raw", var)
  if (!file.exists(new.folder.nc)){
    stop("Please rename the hourly folder hourly_raw. Please copy files 1000 - 53000 into a new hourly folder. The rest of the files will be filled in by the script.")
  }
  
  if ("oahu_RAINNC_present_1e+05.rda" %in% list.files(new.folder.nc)){
    stop("Please rename 1e05 file to be 100000. R is being annoying about this.")
  }
  
  # Find location of Jan 1, 1996
  jan1 = 365*24*6 + 24 + 1 # 365 days in a year, 24 hours in a day, for 6 years (1996 is year 7), plus one leap day (1996 leap day hasn't happened yet) + 1 to move to the new day
  
  # Read in the file
  # load present day RAINNC
  load(sprintf("RAINNC_present/hourly_raw/%s_RAINNC_present_53000.rda", island)) # loads the hourly object
  rainnc.var = hourly
  rm(hourly)
  dims = dim(rainnc.var)
  
  # Get the indices for the interpolation
  dec31 = (jan1 - 1) - 52000
  jan2 = (jan1) - 52000
  # Add an index for jan2 post-interpolation
  jan2.post = jan2 + 24
  
  # Create an array to contain everything
  nc.array = array(data = rep(NA), dim = c(dims[1],dims[2],dims[3]))
  
  # Fill in part BEFORE the patch
  nc.array[1:dims[1],1:dims[2],1:dec31] = rainnc.var[1:dims[1], 1:dims[2], 1:dec31]
  
  # Fill in AFTER the patch
  nc.array[1:dims[1], 1:dims[2], jan2.post:1000] =  rainnc.var[1:dims[1], 1:dims[2], jan2:(1000 - 24)]
  #plot(nc.array[1,1,])
  #plot(nc.array[1,1,580:610])

  # RUN THE INTERPOLATION
  for (i in 1:dims[1]){
    for (j in 1:dims[2]){
    
      rainnc.start = rainnc.var[i,j,dec31]
      # Add this set to the arrays under construction
      nc.array[i,j,jan2:(jan2.post - 1)] = rep(rainnc.start, 24)
    }
  }
  
  # Save updated arrays to file (this is a slow step)
  hourly = nc.array
  save(hourly, file = sprintf("RAINNC_present/hourly/%s_RAINNC_present_53000.rda", island))
  
  # Repeat until no files are left.
  for (i in 54:175){
    print(i)
    
    # Create blank arrays to contain everything
    this.array = array(data = NA, dim = c(dims[1],dims[2],1000))

    # Extract last 24 hours
    # Load previous file
    load(sprintf("%s_present/hourly_raw/%s_%s_present_%s000.rda", var, island, var, (i- 1)))
    this.array[1:dims[1], 1:dims[2],1:24] = hourly[1:dims[1],1:dims[2],977:1000]
    
    # Load current file
    # Extract all but last 24 hours
    load(sprintf("%s_present/hourly_raw/%s_%s_present_%s000.rda", var, island, var, i))
    this.array[1:dims[1], 1:dims[2],25:1000] = hourly[1:dims[1],1:dims[2],1:976]
    
    # Save merged file
    rm(hourly) # Make sure we're saving the right thing
    hourly = this.array
    save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_%s000.rda", var, island, var, i))
    rm(hourly)
  }
  
  # Special handling for the very last file
  this.array = array(data = NA, dim = c(dims[1],dims[2],320))
  load(sprintf("%s_present/hourly_raw/%s_%s_present_175000.rda", var, island, var))
  this.array[1:dims[1], 1:dims[2],1:24] = hourly[1:dims[1],1:dims[2],977:1000]
  load(sprintf("%s_present/hourly_raw/%s_%s_present_175296.rda", var, island, var))
  this.array[1:dims[1], 1:dims[2],25:320] = hourly[1:dims[1],1:dims[2],1:296]
  # Save merged file
  rm(hourly) # Make sure we're saving the right thing
  hourly = this.array
  save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_175320.rda", var, island, var))
  rm(hourly)
}

# Interpolate last 10 (or X) hours
add.X.hours.hm = function(base.path, island, scenario, GMT.offset){

  new.ending = 175320 + GMT.offset
  
  # open existing file (or files)
  load(sprintf("%s/I_RAINNC_%s/hourly/%s_I_RAINNC_%s_175320.rda", base.path, scenario, island, scenario))
  irain = hourly
  rm(hourly)
  load(sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_175320.rda", base.path, scenario, island, scenario))
  rainnc = hourly
  rm(hourly)
  
  dims = dim(irain)
  # Add extra space for the interpolated values
  new.dim = dims[3] + GMT.offset
  i.array = array(data = rep(NA), dim = c(dims[1],dims[2],new.dim))
  nc.array = array(data = rep(NA), dim = c(dims[1],dims[2],new.dim))
  
  i.array[,,1:dims[3]] = irain[,,1:dims[3]]
  i.array[,,(dims[3] + 1): new.dim] = i.array[,,dims[3]] # Just repeat the last hour's read for i_rain - all interpolated values will be added to the rainnc array.
  nc.array[,,1:dims[3]] = rainnc[,,1:dims[3]]
  
  # Read value for corresponding timesteps for interpolation
  # Currently using the previous day's value, to maintain the same synoptic pattern
  baseline = 321 - 25
  #i.precip = i.array[,,dims[3]] # This will just stay constant
  cumulative.precip = nc.array[,,dims[3]] # Start with the last recorded hour for rainnc. All additional rainfall will be added to this.
  #prior.step = 321 - 24
  for (i in 1:GMT.offset){
    prior.step = baseline + 1
    i.delta = irain[,,prior.step] - irain[,,baseline]
    nc.delta = rainnc[,,prior.step] - rainnc[,,baseline]
    delta = i.delta * 100 + nc.delta
    cumulative.precip = cumulative.precip + delta

    # Assign values to the next spot in the array
    # Just adjusting rainnc for convenience. The data files already have it exceed 100, so there is no data type benefit here, and it will make this part easier.
    nc.array[,,dims[3] + i] = cumulative.precip
    baseline = prior.step
  }
  
  # Delete the existing file #**# FOR NOW, just renaming it - afraid of file corruption
  original = sprintf("%s/I_RAINNC_%s/hourly/%s_I_RAINNC_%s_175320.rda", base.path, scenario, island, scenario)
  renamed = sprintf("%s/I_RAINNC_%s/hourly/%s_I_RAINNC_%s_175320_deleteme.rda", base.path, scenario, island, scenario)
  file.rename(original, renamed)
  original = sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_175320.rda", base.path, scenario, island, scenario)
  renamed = sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_175320_deleteme.rda", base.path, scenario, island, scenario)
  file.rename(original, renamed)
  
  # Save the file out with the correct number of time steps
  hourly = i.array
  save(hourly, file = sprintf("%s/I_RAINNC_%s/hourly/%s_I_RAINNC_%s_%s.rda", base.path, scenario, island, scenario, new.ending))
  rm(hourly)
  hourly = nc.array
  save(hourly, file = sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_%s.rda", base.path, scenario, island, scenario, new.ending))
  rm(hourly)
}  
  
  
add.X.hours.ok = function(base.path, island, scenario, GMT.offset){
  new.ending = 175320 + GMT.offset
  
  # open existing file (or files)
  load(sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_175320.rda", base.path, scenario, island, scenario))
  rainnc = hourly
  rm(hourly)
  
  dims = dim(rainnc)
  # Add extra space for the interpolated values
  new.dim = dims[3] + GMT.offset
  nc.array = array(data = rep(NA), dim = c(dims[1],dims[2],new.dim))
  nc.array[,,1:dims[3]] = rainnc[,,1:dims[3]]
  
  # Read value for corresponding timesteps for interpolation
  # Currently using the previous day's value, to maintain the same synoptic pattern
  baseline = 321 - 25
  #i.precip = i.array[,,dims[3]] # This will just stay constant
  cumulative.precip = nc.array[,,dims[3]] # Start with the last recorded hour for rainnc. All additional rainfall will be added to this.
  #prior.step = 321 - 24
  for (i in 1:GMT.offset){
    prior.step = baseline + 1
    delta = rainnc[,,prior.step] - rainnc[,,baseline]
    cumulative.precip = cumulative.precip + delta
    
    # Assign values to the next spot in the array
    # Just adjusting rainnc for convenience. The data files already have it exceed 100, so there is no data type benefit here, and it will make this part easier.
    nc.array[,,dims[3] + i] = cumulative.precip
    baseline = prior.step
  }
  
  # Delete the existing file #**# FOR NOW, just renaming it - afraid of file corruption
  original = sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_175320.rda", base.path, scenario, island, scenario)
  renamed = sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_175320_deleteme.rda", base.path, scenario, island, scenario)
  file.rename(original, renamed)
  
  # Save the file out with the correct number of time steps
  hourly = nc.array
  save(hourly, file = sprintf("%s/RAINNC_%s/hourly/%s_RAINNC_%s_%s.rda", base.path, scenario, island, scenario, new.ending))
  rm(hourly)
  
}


#' This is a simple version for non-cumulative variables
#' 
#' (i.e. not for precipitation, where values are cumulative)
add.X.hours.var = function(base.path, island, variable, scenario, GMT.offset){
  new.ending = 175320 + GMT.offset
  
  # open existing file (or files)
  load(sprintf("%s/%s_%s/hourly/%s_%s_%s_175320.rda", base.path, variable, scenario, island, variable, scenario))
  var.data = hourly
  rm(hourly)
  
  dims = dim(var.data)
  # Add extra space for the interpolated values
  new.dim = dims[3] + GMT.offset
  nc.array = array(data = rep(NA), dim = c(dims[1],dims[2],new.dim))
  nc.array[,,1:dims[3]] = var.data[,,1:dims[3]]
  
  # Read value for corresponding timesteps for interpolation
  # Currently using the previous day's value, to maintain the same synoptic pattern
  current.step = 320
  for (i in 1:GMT.offset){
    current.step = current.step + 1
    # Assign values to the next spot in the array
    nc.array[,,current.step] = var.data[,,current.step - 24]
  }
  
  # Delete the existing file #**# FOR NOW, just renaming it - afraid of file corruption
  original = sprintf("%s/%s_%s/hourly/%s_%s_%s_175320.rda", base.path, variable, scenario, island, variable, scenario)
  renamed = sprintf("%s/%s_%s/hourly/%s_%s_%s_175320_deleteme.rda", base.path, variable, scenario, island, variable, scenario)
  file.rename(original, renamed)
  
  # Save the file out with the correct number of time steps
  hourly = nc.array
  save(hourly, file = sprintf("%s/%s_%s/hourly/%s_%s_%s_%s.rda", base.path, variable, scenario, island, variable, scenario, new.ending))
  rm(hourly)
}

# Fix present time series for Hawaii and Maui for present-day precipitation
# Need a separate function for Oahu/Kauai
# missing I_RAIN variable actually makes this approach rather problematic, as there is no way to know what the total amount of missing rainfall was.
# That may look more like a temperature interpolation.
# Currently hard-coded to fix Jan 1, 1996
insert.interpolated.day = function(base.path, island, var){
  setwd(base.path)
  # Assumes data have been downloaded in chunks of 1000
  # Note that this will shift all files after Jan 1, 1996
  
  main.folder.nc = sprintf("%s_present/hourly", var)
  new.folder.nc = sprintf("%s_present/hourly_raw", var)
  #**# Fix this on download!
  if (!file.exists(new.folder.nc)){
    stop("Please rename the hourly folder hourly_raw. Please copy files 1000 - 52000 into a new hourly folder. The rest of the files will be filled in by the script.")
  }
  
  #**# Should fix this so this issue does not arise in the first place.
  if (sprintf("%s_RAINNC_%s_1e+05.rda", island, var) %in% list.files(new.folder.nc)){
    stop("Please rename 1e05 file to be 100000. R is being annoying about this.")
  }
  
  # Find location of Jan 1, 1996
  jan1 = 365*24*6 + 24 + 1 # 365 days in a year, 24 hours in a day, for 6 years (1996 is year 7), plus one leap day (1996 leap day hasn't happened yet) + 1 to move to the new day
  
  # Read in the file
  # load present day RAINNC
  load(sprintf("%s_present/hourly_raw/%s_%s_present_53000.rda", var, island, var)) # loads the hourly object
  var.data = hourly
  rm(hourly)
  dims = dim(var.data)
  
  # Get the indices for the interpolation
  dec31 = (jan1 - 1) - 52000
  jan2 = (jan1) - 52000
  # Add an index for jan2 post-interpolation
  jan2.post = jan2 + 24
  
  # Create an array to contain everything
  nc.array = array(data = rep(NA), dim = c(dims[1],dims[2],dims[3]))
  
  # Fill in part BEFORE the patch
  nc.array[1:dims[1],1:dims[2],1:dec31] = var.data[1:dims[1], 1:dims[2], 1:dec31]
  
  # Patch with prior day's values (only works for non-cumulative variables)
  nc.array[1:dims[1],1:dims[2],jan2:(jan2.post - 1)] = var.data[1:dims[1],1:dims[2],(dec31 + 1):(dec31 + 24)]
  
  # Fill in AFTER the patch
  nc.array[1:dims[1], 1:dims[2], jan2.post:1000] =  var.data[1:dims[1], 1:dims[2], jan2:(1000 - 24)]
  #plot(nc.array[1,1,])
  #plot(nc.array[1,1,580:610])
  
  # Save updated arrays to file (this is a slow step)
  hourly = nc.array
  save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_53000.rda", var, island, var))
  
  # Repeat until no files are left.
  for (i in 54:175){
    print(i)
    
    # Create blank arrays to contain everything
    this.array = array(data = NA, dim = c(dims[1],dims[2],1000))
    
    # Extract last 24 hours
    # Load previous file
    load(sprintf("%s_present/hourly_raw/%s_%s_present_%s000.rda", var, island, var, (i- 1)))
    this.array[1:dims[1], 1:dims[2],1:24] = hourly[1:dims[1],1:dims[2],977:1000]
    
    # Load current file
    # Extract all but last 24 hours
    load(sprintf("%s_present/hourly_raw/%s_%s_present_%s000.rda", var, island, var, i))
    this.array[1:dims[1], 1:dims[2],25:1000] = hourly[1:dims[1],1:dims[2],1:976]
    
    # Save merged file
    rm(hourly) # Make sure we're saving the right thing
    hourly = this.array
    save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_%s000.rda", var, island, var, i))
    rm(hourly)
  }
  
  # Special handling for the very last file
  this.array = array(data = NA, dim = c(dims[1],dims[2],320))
  load(sprintf("%s_present/hourly_raw/%s_%s_present_175000.rda", var, island, var))
  this.array[1:dims[1], 1:dims[2],1:24] = hourly[1:dims[1],1:dims[2],977:1000]
  load(sprintf("%s_present/hourly_raw/%s_%s_present_175296.rda", var, island, var))
  this.array[1:dims[1], 1:dims[2],25:320] = hourly[1:dims[1],1:dims[2],1:296]
  # Save merged file
  rm(hourly) # Make sure we're saving the right thing
  hourly = this.array
  save(hourly, file = sprintf("%s_present/hourly/%s_%s_present_175320.rda", var, island, var))
  rm(hourly)
}


