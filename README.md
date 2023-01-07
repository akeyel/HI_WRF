# HI_WRF
Data processing code for Hawaii WRF Model data processing. Take data from
on-line HI WRF model outputs and put them into a format that can be used by
GIS users.

# To Do
- Need to update code to be annual on local time, rather than on GMT time
- Need to process out for Temperature
  * Present
  * RCP 4.5
  * RCP 8.5
- Need to adjust code to calculate precipitation
  * Present
  * RCP 4.5
  * RCP 8.5

- Check that the function that creates the xy-grids works
  - It worked when it was initially run, but it was run separately for each island
- Need to adjust interface to make it more user friendly
- Need to compare temperature against present-day values
  * Data series from Tom
- Need to compare precipitation against present-day HI rainfall atlas values

- Need to process 3D data to look at surface water interception
  * Waiting on an external hard-drive for this 
  
- Need to look into using Python to convert rasters from Lambert projection to WGS84

- Need to look into options for making data available to GIS users