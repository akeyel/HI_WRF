# Download hourly data for a variable in 1000 timestep chunks.

library(ncdf4)

Download_Var = function(base.path, island, scenario, variable){
  dir.create(base.path, recursive = TRUE)
  data.file = get.data.file(island, scenario)
  my.ncdf =ncdf4::nc_open(data.file)
  
  start = 1
  end = 1000
  total.timesteps = 175320 # For RCP runs.
  if (scenario == 'present'){ total.timesteps = 175296 }
  
  if (island %in% c('oahu','kauai')){
    Data.Download_ok(my.ncdf, base.path, island, variable, total.timesteps, start, end)
  }
  if (island %in% c('maui', 'hawaii')){
    Data.Download_hm(my.ncdf, base.path, island, variable, scenario, total.timesteps, start, end)
  }
  
  nc_close(my.ncdf)
}


# Use for each island to get the number of timesteps in the file
Get.Timesteps = function(my.ncdf, variable){
  # Do a test extract for a single data point to get the total dimensions of the data set #**# Probably a better way to do this
  test = ncvar_get(my.ncdf, variable, start = c(1,1,1), count = c(1,1,-1))
  total.timesteps = dim(test)
  return(total.timesteps)
}

#' Data downloader for Hawaii and Maui
#' 
Data.Download_hm = function(my.ncdf, base.path, island, variable, scenario, total.timesteps, start = 1, end = 1000){
  
  while(start < total.timesteps){
    timesteps = end - start + 1 # +1 because it is inclusive of start
    hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(-1,-1,timesteps))
    #hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(1,1,timesteps)) #**# TESTING VERSION - USE CODE ABOVE ONCE WORKING PROPERLY
    message(start)
    message(end)
    message(timesteps) # Should always be 1000, except at the very end
    save(hourly, file = sprintf("%s/%s_%s_%s_%s.rda", base.path, island, variable, scenario, format(end, scientific = F)))
    
    start = start + 1000
    end = end + 1000
    if (end > total.timesteps){
      end = total.timesteps
    }
    
    if (start > 200000){
      stop("Something appears to have gone wrong with the extraction - 200,000 timesteps reached, when the data set was expected to have <180,000")
    }
  }
}

#' Data downloader for Oahu and Kauai
#' 
Data.Download_ok = function(my.ncdf, base.path, island, variable, total.timesteps, start = 1, end = 1000){
  
  while(start < total.timesteps){
    timesteps = end - start + 1 # +1 because it is inclusive of start
    hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(-1,-1,timesteps))
    #hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(1,1,timesteps)) #**# TESTING VERSION - USE CODE ABOVE ONCE WORKING PROPERLY
    message(start)
    message(end)
    message(timesteps) # Should always be 1000, except at the very end
    save(hourly, file = sprintf("%s/%s_%s_%s.rda", base.path, island, variable, format(end, scientific = FALSE)))
    
    start = start + 1000
    end = end + 1000
    if (end > total.timesteps){
      end = total.timesteps
    }
    
    if (start > 200000){
      stop("Something appears to have gone wrong with the extraction - 200,000 timesteps reached, when the data set was expected to have <180,000")
    }
  }
}
