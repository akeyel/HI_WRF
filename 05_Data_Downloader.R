# Download hourly data for a variable in 1000 timestep chunks.

library(ncdf4)

source("C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF/Workflow_hlpr.R")

#**# Need to revert loop for hawaii/maui - should have left it and copied this, but I didn't. So will need to fix that.
for (island in c("oahu", "kauai")){
  message(island)
  for (variable in c('RAINNC_present', 'RAINNC_rcp45', 'RAINNC_rcp85')){
    message(variable)
    #for (variable in c('I_RAINNC', 'RAINNC')){
    #message(variable)
    base.path = sprintf("F:/hawaii_local/Vars/%s/%s/hourly", island, variable)
    dir.create(base.path, recursive = TRUE)
    data.file = get.data.file(island, scenario)
    my.ncdf =ncdf4::nc_open(data.file)

    start = 1
    end = 1000
    total.timesteps = 175320 # For RCP runs.
    if (variable == 'RAINNC_present'){ total.timesteps = 175296 }

    Data.Download_ok(base.path, island, variable, total.timesteps, start, end)
    
    nc_close(my.ncdf)
#    }   
  }
}

for (island in c("maui", "hawaii")){
  message(island)
  for (scenario in c('present', 'rcp45', 'rcp85')){
    message(scenario)
    for (variable in c('I_RAINNC', 'RAINNC')){
      message(variable)
      base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
      dir.create(base.path, recursive = TRUE)
      data.file = get.data.file(island, scenario)
      my.ncdf =ncdf4::nc_open(data.file)
      
      start = 1
      end = 1000
      total.timesteps = 175320 # For RCP runs.
      if (scenario == 'present'){ total.timesteps = 175296 }
      
      Data.Download_hm(base.path, island, variable, scenario, total.timesteps, start, end)
      
      nc_close(my.ncdf)
    }   
  }
}

# Use for each island to get the number of timesteps in the file
Get.Timesteps = function(my.ncdf, variable){
  # Do a test extract for a single data point to get the total dimensions of the data set #**# Probably a better way to do this
  test = ncvar_get(my.ncdf, variable, start = c(1,1,1), count = c(1,1,-1))
  total.timesteps = dim(test)
  return(total.timesteps)
}

