# Wind speed R calculation
get.wind.speed.v2 = function(canopy.height, roughness, wrf, height.dir, file.base, dim1_index, dim2_index){
  
  # Something odd is going on with windspeed and heights, so we're returning everything for now, so that alternative calculations can be made.
  d = canopy.height * 0.65 # Per Han's email
  
  # Check canopy height vs. wind speed height
  # If canopy height <= 10m, use 10m wind speed
  U10 = ncvar_get(wrf, "U10", start = c(dim1_index,dim2_index, 1), count = c(1,1,24))
  V10 = ncvar_get(wrf, "V10", start = c(dim1_index,dim2_index, 1), count = c(1,1,24))
  wind.speed.10m = sqrt(U10^2 + V10^2)
  #wind.speed.10m.mean = mean(wind.speed.10m) # Convert to daily mean windspeed.
  if (canopy.height <= 10){
    height = 10
    height.wind.speed = wind.speed.10m
  }
  
  # If canopy height > 10 m, use 1st wind speed layer.
  # Read in wind heights for first 2 layers
  layer.winds = nc_open(sprintf("%s/%s_wind_heights.nc", height.dir, file.base))
  heights = ncvar_get(layer.winds, 'height_agl', start = c(dim1_index,dim2_index,1), count = c(1,1,-1))
  dim(heights) # 455, 435, 2. No time variation - assumes that heights are constant within a day (within the entire simulation???)
  nc_close(layer.winds)
  
  # Check 1st wind speed layer height
  l1.U = ncvar_get(wrf, "U", start = c(dim1_index, dim2_index, 1, 1), count = c(1,1,1,24)) # (dim1, dim2, layer, time)
  l2.V = ncvar_get(wrf, "V", start = c(dim1_index, dim2_index, 1, 1), count = c(1,1,1,24))
  
  level1.wind.speed = sqrt(l1.U^2 + l2.V^2)
  
  l2.U = ncvar_get(wrf, "U", start = c(dim1_index, dim2_index, 2, 1), count = c(1,1,1,24)) # (dim1, dim2, layer, time)
  l2.V = ncvar_get(wrf, "V", start = c(dim1_index, dim2_index, 2, 1), count = c(1,1,1,24))
  
  level2.wind.speed = sqrt(l2.U^2 + l2.V^2)
  
  if (canopy.height > 10){
    if (canopy.height <= heights[1]){
      height = heights[1]
      height.wind.speed = level1.wind.speed
    }else{
      height = heights[2]
      height.wind.speed = level2.wind.speed
    }
  }
  
  wind.speed = height.wind.speed * log((canopy.height - d)/roughness) / log((height - d)/roughness) 
  if (d > height){
    warning(sprintf("Wind height scaling did not work. Wind speed is below assumed 0 wind speed! Using wind speed for height %s instead", height))
    wind.speed = height.wind.speed
  }
  
  return(list(wind.speed, level2.wind.speed, level1.wind.speed, wind.speed.10m, heights[2], heights[1]))
}
