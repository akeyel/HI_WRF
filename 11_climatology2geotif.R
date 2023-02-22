# Take the Climatologies and convert them to .csv then to .tif

# save.out is from Workflow_hlpr.R. Some values need to be adapted to this context,
# as it was originally designed for the Shiny interface and a different export

#out.file = sprintf("%s/%s_%s_%s_%sday_%s_%s_%s.csv", out.path, Island, Scenario, Variable,
#                   TemporalRes, Aggregation, FirstDOY, current.year)

# this.var needs to be in the global namespace
require(terra)

setwd(data.dir)

#One raster for each island was interpolated using the HI Rainfall atlas grid
template.raster.file = sprintf("%s/Vars/grids/templates/%s_template.tif", data.dir, island)
island.grid = sprintf("Vars/grids/wrf_grids/%s_xy_grid_index.csv", island)
months = seq(1,12)
base.path = sprintf("Vars/%s/%s_%s/Climatology",island, this.var, timestep)
tif.path = sprintf("%s/int_tif", base.path)
if (!file.exists(tif.path)){dir.create(tif.path)}
file.base = sprintf("%s_Annual", this.var) 
in.file = sprintf("%s/%s.rda", base.path, file.base)
load(in.file)
# loads the climatology object
csv.in.file = sprintf("%s/%s.csv", base.path, file.base)
csv.file = sprintf("%s.csv", file.base) # Only the file, no path
convert.to.csv(climatology, csv.in.file, island.grid)

# Placed AFTER .csv conversion to allow the .csv to be generated for manual conversion.
if (!file.exists(template.raster.file)){
  stop(sprintf("%s must exist. Please create one interpolation manually in ArcGIS per island to use as a template", template.raster.file))
}

# Convert FROM .csv to .tif using spatial interpolation
# template.raster 
template.raster = terra::rast(template.raster.file)
run.interpolation(base.path, tif.path, csv.file, template.raster, n.neighbors = 12, power = 2) # base.path, 


# Loop through months and process monthly climatologies
for (month in months){
  file.base = sprintf("%s_month_%s", this.var, month) 
  in.file = sprintf("%s/%s.rda", base.path, file.base)
  load(in.file)
  # loads the climatology object
  csv.file = sprintf("%s.csv", file.base)
  csv.in.file = sprintf("%s/%s", base.path, csv.file)
  convert.to.csv(climatology, csv.in.file, island.grid)
  run.interpolation(base.path, csv.file, template.raster, n.neighbors = 12, power = 2, to.integer = 1)
}

