
# Add a patch to fix Kauai to have 3 digit days (missed this for Oahu - will need a separate patch that acts on the tifs for Oahu)
base.path = "F:/hawaii_local/Vars/kauai"
# F:\hawaii_local\Vars\kauai\RAINNC_present\DailyPPT\CSV_for_Tifs\1990
for (var in c("present", "rcp45", "rcp85")){
  for (year in 1990:2009){
    year.path = sprintf('%s/RAINNC_%s/DailyPPT/CSV_for_Tifs/%s', base.path, var, year)
    for (day in 1:99){# 99
      in_file = sprintf('%s/DailyPPT_RAINNC_%s_%s_%s.csv', year.path, var, year, day)
      out_file = sprintf('%s/DailyPPT_RAINNC_%s_%s_%03.f.csv', year.path, var, year, day)
      file.rename(in_file, out_file)
      #message(in_file)
      #message(out_file)
    }
  }
}


# Goal is to create a folder-specific structure to correct placing all .csv files in one directory

base.path = "F:/hawaii_local/Vars"
#base.path = "C:/hawaii_local/Vars"
#island = 'oahu'
island = 'kauai'
var.vec = c("RAINNC_present", "RAINNC_rcp45", "RAINNC_rcp85") #**# Watch that Maui and HI switch over to this labeling convention!
#var.vec = c("RAINNC_rcp45", "RAINNC_rcp85")

for (var in var.vec){
  base.folder = sprintf("%s/%s/%s/DailyPPT/CSV_for_Tifs", base.path, island, var)
  # Loop through files
  my_files = list.files(base.folder)
  for (this_file in my_files){
    year = dfmip::splitter(this_file, "_", 4, 0)
    out.folder = sprintf("%s/%s", base.folder, year)
    if (!file.exists(out.folder)){
      dir.create(out.folder, recursive = TRUE)
    }
    
    # Move file
    in_file = sprintf('%s/%s', base.folder, this_file)
    out_file = sprintf("%s/%s", out.folder, this_file)
    file.rename(in_file, out_file)
  }
}


### 365 Day bug patch
base.path = "F:/hawaii_local/Vars"
#base.path = "C:/hawaii_local/Vars"
island = 'oahu'
#island = 'kauai'
#start.year = 1990
start.year = 1990
end.year = 2009
leap.years = c(1992,1996,2000, 2004, 2008)
var.vec = c("RAINNC_present", "RAINNC_rcp45", "RAINNC_rcp85") #**# Watch that Maui and HI switch over to this labeling convention!
#var.vec = c("RAINNC_rcp85")

island.grid = sprintf("%s/grids/wrf_grids/%s_xy_grid_index.csv", base.path, island)

for (var in var.vec){
  # Loop through year files
  for (year in start.year:end.year){
    
    out.folder = sprintf("%s/%s/%s/DailyPPT/CSV_for_Tifs/PATCH", base.path, island, var)
    if (!file.exists(out.folder)){
      dir.create(out.folder, recursive = TRUE)
    }
    
    # For each year
    in.file = sprintf("%s/%s/%s/DailyPPT/DailyPPT_%s_year_%s.rda", base.path, island, var, var, year)
    
    load(in.file) # loads the day.ppt.array object
    
    # Loop through days in the year
    day = 365
    out.file = sprintf("%s/DailyPPT_%s_%s_%s.csv",out.folder, var, year, day)
      
    # Skip the last day of the last year for now - requires interpolation, and need to decide on a method.
    skip = 0
    if (year == 2009){
      skip = 1
    }      
    if (skip == 0){
      
      # Subset out to that particular day
      current.values = day.ppt.array[,,day]
      
      # Export to .csv
      convert.to.csv(current.values, out.file, island.grid, int100 = FALSE)
      # Originally, plan was to multiply by 100 and convert to integer to save space. However,
      # Rounding to nearest 100 is undone in ArcGIS during interpolation, and does not save much space in the .csv (<20%)
      # Also, .csv's can be deleted after the raster files are created if space is an issue.
        
    }
  }
}


