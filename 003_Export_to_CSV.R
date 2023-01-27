# 

# Take the Climatologies and convert them to .csv

# save.out is from Workflow_hlpr.R. Some values need to be adapted to this context,
# as it was originally designed for the Shiny interface and a different export

#out.file = sprintf("%s/%s_%s_%s_%sday_%s_%s_%s.csv", out.path, Island, Scenario, Variable,
#                   TemporalRes, Aggregation, FirstDOY, current.year)

# this.var needs to be in the global namespace

setwd(data.dir)

island.grid = sprintf("%s/Vars/grids/wrf_grids/%s_xy_grid_index.csv", data.dir, island)
months = seq(1,12)

file.base = sprintf("Vars/%s/%s_%s/Climatology/%s_Annual", island, this.var, timestep, this.var) 
in.file = sprintf("%s.rda", file.base)
load(in.file)
# loads the climatology object
out.file = sprintf("%s.csv", file.base)
convert.to.csv(climatology, out.file, island.grid)

# Loop through months and process monthly climatologies
for (month in months){
  file.base = sprintf("Vars/%s/%s_%s/Climatology/%s_month_%s", island, this.var, timestep, this.var, month) 
  in.file = sprintf("%s.rda", file.base)
  load(in.file)
  # loads the climatology object
  out.file = sprintf("%s.csv", file.base)
  island.grid = sprintf("C:/hawaii_local/Vars/grids/wrf_grids/%s_xy_grid_index.csv", island)
  convert.to.csv(climatology, out.file, island.grid)
}

