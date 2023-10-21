# Convert from WRF variables to estimate water extraction from clouds by vegetation

# Created 2023-05-23 based on notes from December 2022

library(ncdf4)

# Read in 3D example file
data.dir = "C:/docs/hawaii_local/3D_Files"
setwd(data.dir)

# Path to netcdf file
data.files = list.files(data.dir)
wrf.test.file = data.files[4]
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
  #**# How?? This shouldn't be hard, but my brain is running like molasses today
  #**# here is a stupid solution. I know there is a better one, but not getting there at the moment
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
  
  loc.df$lcw[i] = mean(liquid.cloud.water) 
  #test = ncvar_get(wrf, "QCLOUD", start = c(1,1,1,10), count = c(dim1, dim2, 1,1))
  #max(test) = 0.0008700828 Is this plausible? Recall, our test date is early January.
  
   
  #**# NOTE: Descriptive plots don't show much in the way of values for QCLOUD. Do we want QVAPOR instead? That has variation.
  # Likely due to units - kg/kg can lead to small values for quantities that are in terms of grams.
  
  # OK. Start here for update to Tom, Oliver, and Han.
}



# Extract required variables from 3D example file
# The notes are not very informative compared to what I recollect from the conversation:
#Wind * liquid water content
#QCLOUD * Windspeed
#Windspeed = sqrt(U2 + V2)
#Kg/kg -> g/m3
#Want 2 m or vegetation height wind speed
#Want stability or Reynolds

# See instead attachment from Han:
#CWI(mm/time) = A*CWF(mm/time)
#CWF(mm/hr) = (LWC(g/m3) / rho_water(g/cm3) ) * WS(m/s) * 3.6 (mm3/cm3 * m2/mm2 * s/hr)

#rho_water = density of water (g/cm3)
#WS = wind speed (m/s)
# CWI = cloud water content; amount of cloud/fog water caught by vegetation, measured as vertical depth or flux mm/hr; = Fqc in Katata et al. 2011 equation, but there kg/m2s
# CWF: cloud water flux: amount of cloud/fog water supplied by the atmosphere; proportional to windspeed * liquid water content; horizontal depth or flux (mm/hr)
# U*p_air*qc in Katata et al. 2011 but different units
# LWC = cloud liquid water content; amount of water in liquid form in the air, g/m3, qc in Katata et al. 2011, but different units
# A canopy interception efficiency
# slope of Vd that depend on vegetation characteristics in Katata et al. 2008
# dimensionless, ratio of CWF converted to CWI; depends on characteristics of vegetation canopy
# Katata et al. 2011 A = 0.0164 * (LAD)**-0.5, LAD = LAI/canopy height

# NEED TO FIND DOCUMENTATION FOR THESE - may just reach out to Chunxi?

# bottom_top variable may give heights of different layers - should look at this one!

# Assume liquid water cloud content kg / kg dry air
# Can use density of dry air to get kg / m3 of dry air
# Calculate air density based on ideal gas law - use temperature and pressure there

# How do we know if cloud is at ground level for interception?
# Vertical information on cloud layer for whether to call a cloud or not.

## Calculate CWF
# QCLOUD is Cloud Water Mixing Ratio, in kg / kg
# CFRACT is the Total cloud fraction
# LWP Is Liquid cloud water path
# LWC needs to be in grams of water per cubic meter of air
LWC = "QCLOUD?" #**# Pull from QCLOUD variable? But probably needs unit transformations
# Will need density of air for unit transformation

WindSpeed.10m = sqrt("U10"^2 + "V10"^2)
WS = "etwas" # need to convert from 10 m windspeed to 2 m windspeed. May need HGT variable, which is the vegetation height.
WS = "WS" #**# Pull from vertical and horizontal wind components, except need 2 m windspeed - need to know what lowest wind level of the simulation is, and need to use another equation to adjust to estimated 2 m windspeed. 
# Oliver also said wind speeds were on an offset grid, so we'll need to think about that aspect as well - may need to interpolate to get the location of interest.


rho_water = 0.997045 # using this calculator at 25 C https://www.axeleratio.com/calc/water_density/form/Kell_equation.htm
warning("Should adjust rho_water calculation to be calculated as a function of temperature and pressure") # Oliver said OK to just use a single value - differences are slight

CWF = (LWC / rho_water) * WS * 3.6

# Land surface model documentation should describe this
## Calculate A
LAI = "LAI" # LAI is in the 3D data set
canopy.height = "HGT"

LAD = LAI / canopy.height
A = 0.0164 * (LAD)**(-0.5)

## Put it together
CWI = A * CWF

# Process required variables to be in the correct units

# Apply equation to processed variables #**# or do they want to do this part?

# Save final output in corrected format

# Examine values at test locations
test.lats = c(20.67465, 20.7598, 19.4152, 19.932, 21.506875)
test.longs = c(-156.233308, -156.2482, -155.2385, -155.291, -158.145114)
test.labels = c("Nakula", "ParkHQ", "Nahuku", "Laupaho ehoe", "Kaala")

# Extract values from 3D data set at these locations and make basic plots
