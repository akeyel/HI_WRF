copy.raw.data=function(data.dir, island, variable){
  # Current name of the folder 
  old.folder.name <- sprintf("%s/Vars/%s/%s_present/hourly", data.dir, island, variable)
  # New name of the folder 
  new.folder.name <- sprintf("%s/Vars/%s/%s_present/hourly_raw", data.dir, island, variable)
  # Use the file.rename() function to change the name of the folder 
  file.rename(old.folder.name, new.folder.name) 
  
  #make new folder called hourly
  variable.path=sprintf("%s/Vars/%s/%s_present/", data.dir, island, variable)
  dir.create(paste0(variable.path, "hourly"))
  
  #define current and new location
  current.location <- paste0(variable.path, "hourly_raw")
  new.location=paste0(variable.path, "hourly")
  #list the files we want to copy
  my.files <- paste0(sprintf("/%s_%s_present_", island, variable), seq(from=1000,to=52000,by=1000),".rda")
  #copy files to new location
  file.copy(from = paste0(current.location, my.files),
            to = paste0(new.location, my.files))
}

