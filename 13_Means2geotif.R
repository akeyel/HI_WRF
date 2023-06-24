# Goal is to take daily data by year, and convert to GeoTifs
require(terra)

mean2geotif = function(base.path, island, variable, timestep,
                       start.year, end.year, time.period, extra.bit,
                       metric_bit = ""){
  if (time.period == 'annual'){
    data.path = sprintf("%s/%s/%s_%s/AnnualMeans", base.path, island, variable, timestep)
  }
  if (time.period == "monthly"){
    data.path = sprintf("%s/%s/%s_%s/MonthlyMeans", base.path, island, variable, timestep)
  }
  tif.path = sprintf("%s/tif", data.path)
  csv.path = sprintf("%s/csv", data.path)
  if (!file.exists(tif.path)){  dir.create(tif.path, recursive = TRUE)  }
  if (!file.exists(csv.path)){  dir.create(csv.path, recursive = TRUE)  }
  
  island.grid = sprintf("%s/grids/wrf_grids/%s_xy_grid_index.csv", base.path, island)
  template.raster.file = sprintf("%s/grids/templates/%s_template.tif", base.path, island)
  template.raster = terra::rast(template.raster.file)
  # For each year
  for (year in start.year:end.year){
    message(sprintf("Now processing %s", year))
    
    # For each month # (Break early if doing annual)    
    for (month in 1:12){
      if (time.period == 'annual'){
        in.file = sprintf("%s/%s%s_%s_mean%s.rda", data.path, metric.bit, variable, year - 1989, extra.bit)
        csv.file = sprintf("%s%s_%s_mean%s.csv", metric.bit, variable, year - 1989, extra.bit)
      }
      if (time.period == 'monthly'){
        in.file = sprintf("%s/%s%s_%s_%s_mean%s.rda", data.path, metric.bit, variable, year - 1989, month, extra.bit)
        csv.file = sprintf("%s%s_%s_%s_mean%s.csv", metric.bit, variable, year - 1989, month, extra.bit)
      }
      load(in.file) # loads the mean.annual.array for annual and mean.month.array for monthly
      if (time.period == 'annual'){current.values = mean.annual.array  }
      if (time.period == 'monthly'){ current.values = mean.month.array }
      csv.file.full = sprintf("%s/%s",csv.path, csv.file)
      convert.to.csv(current.values, csv.file.full, island.grid, int100 = FALSE)
      run.interpolation(csv.path, tif.path, csv.file, template.raster, n.neighbors = 12, power = 2, to.integer = 1)
      # Stop iterating through months if running for annual timestep
      if (time.period == 'annual'){
        break
      }
    }
  }
}