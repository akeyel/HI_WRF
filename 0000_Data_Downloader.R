# Download hourly data for a variable in 1000 timestep chunks.

library(ncdf4)

# Not positive this is doing me any favors, but the downloading has been a major bottleneck, and I've been struggling with the indexing.
source("C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF/Workflow_hlpr.R")
#island = 'maui'
island = 'hawaii'
scenario = "rcp85" # 'present' # "rcp85" # 'rcp45'
variable = "I_RAINNC" #"RAINNC" # 
base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
dir.create(base.path, recursive = TRUE)
data.file = get.data.file(island, scenario)
my.ncdf =ncdf4::nc_open(data.file)

# Use for each island to get the number of timesteps in the file (#**# Shouldn't this be the same for all of them???)
Get.Timesteps = function(my.ncdf, variable){
  # Do a test extract for a single data point to get the total dimensions of the data set #**# Probably a better way to do this
  test = ncvar_get(my.ncdf, variable, start = c(1,1,1), count = c(1,1,-1))
  total.timesteps = dim(test)
  return(total.timesteps)
}

# For Maui
# Move start and end to allow this to be run in pieces.
#start = 1
#end = 1000 
#total.timesteps = 100000

#start = 100001 # 1
#end = 101000 # 1000 
#total.timesteps = 175296 # Run for 5000 to test how it goes. (went well, trying for full series)
# total.timesteps = 175320 # For RCP runs.

# For Hawaii
start = 1
end = 1000
total.timesteps = 175320 # For RCP runs.
#total.timesteps = 50000

#start = 50001
#end = 51000
#total.timesteps = 100000

#start = 100001
#end = 101000
#total.timesteps = 150000

# start = 150001
# end = 151000
#total.timesteps = 175296

Data.Download(base.path, island, variable, scenario, total.timesteps, start, end)

nc_close(my.ncdf)

#**# REFORMAT THIS ALL TO BE IN A LOOP

scenario = 'rcp45'
start = 1
end = 1000
total.timesteps = 175296
data.file = get.data.file(island, scenario)
base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
dir.create(base.path, recursive = TRUE)
my.ncdf =ncdf4::nc_open(data.file)
Data.Download(base.path, island, variable, scenario, total.timesteps, start, end)
nc_close(my.ncdf)

scenario = 'rcp85'
start = 1
end = 1000
total.timesteps = 175296
data.file = get.data.file(island, scenario)
base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
dir.create(base.path, recursive = TRUE)
my.ncdf =ncdf4::nc_open(data.file)

# Now run for RAINNC
variable = "RAINNC"

scenario = 'present'
start = 1
end = 1000
total.timesteps = 175296
data.file = get.data.file(island, scenario)
base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
dir.create(base.path, recursive = TRUE)
my.ncdf =ncdf4::nc_open(data.file)
Data.Download(base.path, island, variable, scenario, total.timesteps, start, end)
nc_close(my.ncdf)

scenario = 'rcp45'
start = 1
end = 1000
total.timesteps = 175296
data.file = get.data.file(island, scenario)
base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
dir.create(base.path, recursive = TRUE)
my.ncdf =ncdf4::nc_open(data.file)
Data.Download(base.path, island, variable, scenario, total.timesteps, start, end)
nc_close(my.ncdf)

scenario = 'rcp85'
start = 1
end = 1000
total.timesteps = 175296
data.file = get.data.file(island, scenario)
base.path = sprintf("F:/hawaii_local/Vars/%s/%s_%s/hourly", island, variable, scenario)
dir.create(base.path, recursive = TRUE)
my.ncdf =ncdf4::nc_open(data.file)
Data.Download(base.path, island, variable, scenario, total.timesteps, start, end)
nc_close(my.ncdf)

#**# SHOULD ADD A CONVERTER TO STANDARDIZE VARIABLE NAMES
Data.Download = function(base.path, island, variable, scenario, total.timesteps, start = 1, end = 1000){
  
  
  
  while(start < total.timesteps){
    timesteps = end - start + 1 # +1 because it is inclusive of start
    hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(-1,-1,timesteps))
    #hourly = ncvar_get(my.ncdf, variable, start = c(1,1,start), count = c(1,1,timesteps)) #**# TESTING VERSION - USE CODE ABOVE ONCE WORKING PROPERLY
    message(start)
    message(end)
    message(timesteps) # Should always be 1000, except at the very end
    save(hourly, file = sprintf("%s/%s_%s_%s_%s.rda", base.path, island, variable, scenario, end))
    
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

