# Goal is to take daily data by year, and convert to GeoTifs
require(terra)

var = sprintf("%s_%s", this.var, timestep)
island.grid = sprintf("%s/grids/wrf_grids/%s_xy_grid_index.csv", base.path, island)
template.raster.file = sprintf("%s/grids/templates/%s_template.tif", base.path, island)
template.raster = terra::rast(template.raster.file)

# Loop through year files
for (year in start.year:end.year){
  message(sprintf("Now processing %s", year))
  daily.path = sprintf("%s/%s/%s/DailyPPT", base.path, island, var)
  out.folder = sprintf("%s/CSV_for_Tifs/%s", daily.path, year)
  if (!file.exists(out.folder)){
    dir.create(out.folder, recursive = TRUE)
  }
  
  # For each year
  in.file = sprintf("%s/DailyPPT_%s_year_%s.rda", daily.path, var, year)
  
  load(in.file) # loads the day.ppt.array object
  
  # Loop through days in the year
  days = 365
  if (year %in% leap.years){  days = 366  }
  for (day in 1:days){
    csv.file = sprintf("DailyPPT_%s_%s_%03.f.csv", var, year, day)
    csv.file.full = sprintf("%s/%s",out.folder, csv.file)

    # Subset out to that particular day
    current.values = day.ppt.array[,,day]
  
    # Export to .csv
    convert.to.csv(current.values, csv.file.full, island.grid, int100 = FALSE)
    # Originally, plan was to multiply by 100 and convert to integer to save space. However,
    # Rounding to nearest 100 is undone in ArcGIS during interpolation, and does not save much space in the .csv (<20%)
    # Also, .csv's can be deleted after the raster files are created if space is an issue.
    
    #**# Need to change the structuring - I don't like that the tif folder has to be nested in the .csv folder. Would rather they were parallel to each other.
    # Run interpolation
    run.interpolation(out.folder, csv.file, template.raster, n.neighbors = 12, power = 2)
  }
}
