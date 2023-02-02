# Goal is to take daily data by year, and convert to GeoTifs

code.dir = "C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF"
setwd(code.dir)
source("Workflow_hlpr.R") # Needs convert.to.csv function. May want to consider a more efficient implementation, or one that automatically multiplies by 100 and converts to integer.

# set up parameters
base.path = "F:/hawaii_local/Vars"
#base.path = "C:/hawaii_local/Vars"
island = 'oahu'
#island = 'kauai'
#start.year = 1990
start.year = 2009
end.year = 2009
leap.years = c(1992,1996,2000, 2004, 2008)
var.vec = c("RAINNC_present", "RAINNC_rcp45", "RAINNC_rcp85") #**# Watch that Maui and HI switch over to this labeling convention!
#var.vec = c("RAINNC_rcp85")

island.grid = sprintf("%s/grids/wrf_grids/%s_xy_grid_index.csv", base.path, island)

for (var in var.vec){
  # Loop through year files
  for (year in start.year:end.year){

    out.folder = sprintf("%s/%s/%s/DailyPPT/CSV_for_Tifs/%s", base.path, island, var, year)
    if (!file.exists(out.folder)){
      dir.create(out.folder, recursive = TRUE)
    }
    
    # For each year
    in.file = sprintf("%s/%s/%s/DailyPPT/DailyPPT_%s_year_%s.rda", base.path, island, var, var, year)
    
    load(in.file) # loads the day.ppt.array object
    
    # Loop through days in the year
    days = 365
    if (year %in% leap.years){  days = 366  }
    for (day in 1:days){
      out.file = sprintf("%s/DailyPPT_%s_%s_%03.f.csv",out.folder, var, year, day)

      # Skip the last day of the last year for now - requires interpolation, and need to decide on a method.
      skip = 0
      if (year == 2009 & day == 365){
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
}



# Launch Python Script (or just launch separately, to avoid coding headaches of getting the softwares to work together)
#**# Need to make sure the Python script is ready.

stop("Please run the CSV to Raster (Daily) tool from the HI_WRF toolbox.
     You will need to run it separately for each island, scenario and variable")