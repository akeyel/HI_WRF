# Goal is to take daily data by year, and convert to GeoTifs
#**# ack01: Need to change precipitation workflow - changed this.var to variable to be more consistent.
# also need to add var.label = "PPT" and metric.bit = ""
require(terra)

var = sprintf("%s_%s", variable, timestep)
island.grid = sprintf("%s/grids/wrf_grids/%s_xy_grid_index.csv", code.dir, island)
template.raster.file = sprintf("%s/grids/templates/%s_template.tif", code.dir, island)
template.raster = terra::rast(template.raster.file)

# Loop through year files
for (year in start.year:end.year){
  message(sprintf("Now processing %s", year))
  daily.path = sprintf("%s/%s/%s/Daily%s", base.path, island, var, var.label)
  out.folder = sprintf("%s/CSV_for_Tifs/%s", daily.path, year)
  tif.path = sprintf("%s/int_tif/%s", daily.path, year)
  if (!file.exists(out.folder)){
    dir.create(out.folder, recursive = TRUE)
  }
  if (!file.exists(tif.path)){
    dir.create(tif.path, recursive = TRUE)
  }
  
    
  # For each year
  in.file = sprintf("%s/Daily%s_%s%s_year_%s.rda", daily.path, var.label, metric.bit, var, year)
  
  load(in.file) # loads the day.ppt.array object
  
  # Loop through days in the year
  days = 365
  #if (year %in% leap.years){  days = 366  } # This was incorrect - used the index position rather than the actual year.
  if (year %% 4 == 0){ days = 366 } # This will give a bad result for 1900 and 2100, but those years aren't in the data set.
  for (day in 1:days){
    csv.file = sprintf("Daily%s_%s%s_%s_%03.f.csv", var.label, metric.bit, var, year, day)
    csv.file.full = sprintf("%s/%s",out.folder, csv.file)

    if (var.label == 'PPT'){
      # Subset out to that particular day
      current.values = day.ppt.array[,,day]
    }else{
      current.values = day.array[,,day]
    }
  
    # Export to .csv
    convert.to.csv(current.values, csv.file.full, island.grid, int100 = FALSE)
    # Originally, plan was to multiply by 100 and convert to integer to save space. However,
    # Rounding to nearest 100 is undone in ArcGIS during interpolation, and does not save much space in the .csv (<20%)
    # Also, .csv's can be deleted after the raster files are created if space is an issue.
    
    #**# Need to change the structuring - I don't like that the tif folder has to be nested in the .csv folder. Would rather they were parallel to each other.
    # Run interpolation
    run.interpolation(out.folder, tif.path, csv.file, template.raster, n.neighbors = 12, power = 2, to.integer = 1)
  }
}
