# Convert from WRF variables to estimate water extraction from clouds by vegetation

# Created 2023-05-23 based on notes from December 2022

# From attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)


library(ncdf4)

# Read in 3D example file
data.dir = "C:/docs/hawaii_local/3D_Files"
setwd(data.dir)

# Path to netcdf file
data.files = list.files(data.dir)
wrf.test.file = data.files[5] # Added a file!
wrf = nc_open(wrf.test.file)

# Identify selected points identified by Han as of interest
location.labels = c("Nakula", "ParkHQ", "Nahuku", "Laupahoehoe", "Kaala")
loc.lats = c(20.674650, 20.759800, 19.415200, 19.932000, 21.506875)
loc.lons = c(-156.233308, -156.248200, -155.238500, -155.291000, -158.145114)

loc.df = data.frame(location = location.labels, latitude = loc.lats, longitude = loc.lons)

# Make a grid lookup to help in identifying coordinates
make.grid = 0
grid.file = sprintf("%s_3D_xy_grid.csv", substr(wrf.test.file, 8,21))
if (make.grid == 1){
  dim1 = wrf$var$T2$varsize[1]
  dim2 = wrf$var$T2$varsize[2]
  vals = ncvar_get(wrf, "T2", start = c(1,1,1), count = c(dim1,dim2,1))
  lat = ncvar_get(wrf, "XLAT", start = c(1,1,1), count = c(dim1,dim2,1))
  lon = ncvar_get(wrf, "XLONG", start = c(1,1,1), count = c(dim1,dim2,1))
  xy.grid = data.frame(values = matrix(vals, ncol = 1), lat = matrix(lat, ncol = 1),
                       lon = matrix(lon, ncol = 1),
                       lat_index = sort(rep(seq(1,dim2), dim1)), lon_index = rep(seq(1,dim1), dim2))
  
  write.table(xy.grid, file = grid.file, sep = ',', row.names = FALSE, col.names = TRUE,
              append = FALSE)
  
  #**# Temporary hack: make the points appear as white NAN values to show their location
  plotvals = vals
  for (i in 1:nrow(loc.df)){
    if (i == 1){
      plotvals[loc.df$dim1_index[i], loc.df$dim2_index[i]] = 315
    }else{
      plotvals[loc.df$dim1_index[i], loc.df$dim2_index[i]] = 260
    }
  }
  image(plotvals)
  
  # Convert xy grid into a raster for plotting purposes
  
  # Plot the xy grid of temperature with the 5 points (actually 4, one will be outside the domain)
  
}else{
  xy.grid = read.csv(grid.file)
}

lats = unique(xy.grid$lat)
lons = unique(xy.grid$lon)
loc.df$dim1_index = NA
loc.df$dim2_index = NA
# Get row/col indices for locations
for (i in 1:nrow(loc.df)){
  # Calculate the distance to all latitudes
  this.lat = loc.df$latitude[i]
  this.lon = loc.df$longitude[i]
  
  # Calculate the distance to all longitudes
  lat.dist = abs(this.lat - lats)
  lon.dist = abs(this.lon - lons)
  
  # Use grid to look up nearest WRF coordinates
  # identify the lat/lon with shortest distance
  lat.min.pos = grep(min(lat.dist), lat.dist) # Assumes it is not equidistant - if this comes up modify the script!
  lon.min.pos = grep(min(lon.dist), lon.dist) # ditto
  if (length(max(c(lat.min.pos, lon.min.pos))) > 1){
    stop("More than one minimum found, better code needed!")
  }
  matching.lat = lats[lat.min.pos]
  matching.lon = lons[lon.min.pos]
  
  # Get position of the matching lat and lon
  possible.lats = grep(matching.lat, xy.grid$lat)
  possible.lons = grep(matching.lon, xy.grid$lon)
  row.position = intersect(possible.lats, possible.lons)
  
  # append the row indices to the data frame
  loc.df$dim1_index[i] = xy.grid$lon_index[row.position]
  loc.df$dim2_index[i] = xy.grid$lat_index[row.position]
}

stop("Visual inspection revealed that Kaala site is outside domain of wrf file")

#**# Confirm that coordinates are pulling the correct point from the grid
stop("Please check that the indices are actually pulling the correct values")

# Pull out just the needed values
loc.df$lcw = NA
loc.df$cwf = NA
loc.df$cwi = NA
for (i in 1:nrow(loc.df)){
  dim1_index = loc.df$dim1_index[i]
  dim2_index = loc.df$dim2_index[i]
  # dimensions of qcloud 455 435  50  24
  # just get the selected data point for all time points for the selected location
  
  # Convert QCLOUD to needed units
  # QCLOUD: Cloud water mixing ratio kg / kg
  # QVAPOR: Water vapor mixing ratio kg / kg
  # PSFC: SFC Pressure (Pa)
  qcloud = ncvar_get(wrf, "QCLOUD", start = c(dim1_index,dim2_index, 1, 1), count = c(1,1,1,24))
  PSFC = ncvar_get(wrf, "PSFC", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
  T2 = ncvar_get(wrf, "T2", start = c(dim1_index, dim2_index, 1), count = c(1,1,24))
  R = 287 # J / (kg * K)
  rho_air = PSFC / (R * T2) # and rho_air is QCLOUD?
  
  liquid.cloud.water = rho_air * qcloud * 1000 # 1000 converts from kg to g
  
  # LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
  lcw = mean(liquid.cloud.water) 
  loc.df$lcw[i] = lcw
  #test = ncvar_get(wrf, "QCLOUD", start = c(1,1,1,10), count = c(dim1, dim2, 1,1))
  #max(test) = 0.0008700828 Is this plausible? Recall, our test date is early January.
  
  ### CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)
  #rho_water = density of water (g/cm3)
  rho_water = 0.997045 # using this calculator at 25 C https://www.axeleratio.com/calc/water_density/form/Kell_equation.htm
  if (i == 1){
    warning("Should adjust rho_water calculation to be calculated as a function of temperature and pressure") # Oliver said OK to just use a single value - differences are slight
  }

  # HGT gives terrain height. How do we get vegetation height?
  # IVGTYP gives dominant vegetation category - does this determine vegetation height?
  # VEGFRA gives vegetation fraction - is this relevant?
  vegetation.category = ncvar_get(wrf, "IVGTYP", start = c(dim1_index,dim2_index, 1), count = c(1,1,1)) # 24 works for the 3rd dimension, but I'm assuming this does not change within a day? Does it change across seasons?
  roughness = 0.75 #**# Wikipedia said brush/forest was often in the range of 0.5 - 1.0 m, I assumed vegetation was brush/forest.
  # https://www2.mmm.ucar.edu/wrf/users/tutorial/tutorial_presentations_2021.htm
  # Tutorial on WRF Physics - Surface says roughness is in WRF based on land cover type. So we *SHOULD* be able to look this up.
  # But I can't find it in the list of variables, and I can't find a table to define the land cover classes!
  canopy.height = 1 #**# used 1 as a placeholder. But what happens if it is 30 m? Seems like a conceptual flaw in the calculation
  
  # See 99_Patches.R script to get a list of numeric vegetation classes Get.Veg.Types
  # Still need to relate these to canopy.height and surface roughness.
  
  #WS = wind speed (m/s)
  # Oliver also said wind speeds were on an offset grid, so we'll need to think about that aspect as well - may need to interpolate to get the location of interest.
  U10 = ncvar_get(wrf, "U10", start = c(dim1_index,dim2_index, 1), count = c(1,1,24))
  V10 = ncvar_get(wrf, "V10", start = c(dim1_index,dim2_index, 1), count = c(1,1,24))
  wind.speed.10m = sqrt(U10^2 + V10^2)
  wind.speed.10m.mean = mean(wind.speed.10m) # Convert to daily mean windspeed.
  
  # Tried:
  # https://www.grc.nasa.gov/www/k-12/airplane/reynolds.html
  # but this has a length, bulk viscosity, and a density, and I'm not really sure how to use those parameters.
  
  # This says we can use log wind profile and surface roughness to calculate it:
  # https://www.researchgate.net/post/Is-that-possible-to-convert-wind-speed-measured-in-10-m-height-to-a-possible-2-m-height-wind-speed
  # https://en.wikipedia.org/wiki/Log_wind_profile
  if (i == 1){
    warning("Wind speed was downscaled using a log wind profile in a Wikipedia article referenced in a ResearchGate question's answer and some bad assumptions about surface roughness")
  }
  # uz2 = uz1 * (ln(z2 - d) / z0) / (ln(z1 - d) / z0) 
  # d = zero plane displacement
  # the height in meters above the ground at which zero mean wind speed is achieved as a result of flow obstacles such as trees or buildings. This displacement can be approximated as 2/3 to 3/4 of the average height of the obstacles
  d = canopy.height * (2/3) # Could also be 3/4 #**# CHECK WITH TOM and HAN
  wind.speed = wind.speed.10m * log((10 - d)/roughness) / log((2 - d)/roughness)
  wind.speed = wind.speed.10m * log((2 - d)/roughness) / log((10 - d)/roughness) 
  #**# changed not to use mean wind.speed - want to do calculations as fine-scale as possible
  
  wind.speed.bug = 1
  if (wind.speed.bug == 1){
    wind.speed = wind.speed.10m
    warning("Using 10 m wind speed, because 2 m wind speed calculation is currently not working")
  }
  
  # CWF: cloud water flux: amount of cloud/fog water supplied by the atmosphere; proportional to windspeed * liquid water content; horizontal depth or flux (mm/hr)
  # U*p_air*qc in Katata et al. 2011 but different units
  cloud.water.flux = liquid.cloud.water * rho_water * wind.speed * 3.6 #**# Check if it is x rho_water or / rho_water
  cwf = mean(cloud.water.flux)
  #CWF = (LWC / rho_water) * WS * 3.6
  loc.df$cwf = cwf

  ## Calculate A
  # A canopy interception efficiency
  # slope of Vd that depend on vegetation characteristics in Katata et al. 2008
  # dimensionless, ratio of CWF converted to CWI; depends on characteristics of vegetation canopy
  # Katata et al. 2011 A = 0.0164 * (LAD)**-0.5, LAD = LAI/canopy height
  # bottom_top variable may give heights of different layers - should look at this one!
  # Land surface model documentation should describe this
  LAI = ncvar_get(wrf, "LAI", start = c(dim1_index,dim2_index, 1), count = c(1,1,24)) # LAI is in the 3D data set
  #**# Does LAI change hourly??? - yes - first value is different than 2nd value!!!
  
  LAD = LAI / canopy.height
  A = 0.0164 * (LAD)**(-0.5)
  
  # CWI = cloud water content; amount of cloud/fog water caught by vegetation, measured as vertical depth or flux mm/hr; = Fqc in Katata et al. 2011 equation, but there kg/m2s
  #CWI(mm/time) = A*CWF(mm/time)
  cloud.water.content = A * cloud.water.flux
  cwi = sum(cloud.water.content)
  # Convert to daily cloud water caught by vegetation
  loc.df$cwi = cwi
}

