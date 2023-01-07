# Create plots of rainfall to see what is going on with Oahu data


# # Set up island parameters
island = "oahu"
setwd("C:/hawaii_local/Vars/oahu")
TimeZone.Label = "GMT-10"
var = "RAIN"
i = 2 # look at 2nd year, to avoid any oddities associated with spin-up
timestep = 'present'

main.var = sprintf("%s_%s", var, timestep)
other.var = sprintf("%sNC_%s", var, timestep)

# Read in this year's data for main variable
load(sprintf("%s/AnnualHourly/%s_year_%s_%s.rda",main.var, main.var, i, TimeZone.Label))
rain = new.var
rm(new.var)
      
# Read in this year's data for the secondary variable
load(sprintf("%s/AnnualHourly/%s_year_%s_%s.rda",other.var, other.var, i, TimeZone.Label))
# Loads the new.var object
rainnc = new.var
rm(new.var)

load(sprintf("I_RAINNC/AnnualHourly/I_RAINNC_year_%s_%s.rda", i, TimeZone.Label))
irainnc = new.var
rm(new.var)


## Select 3 locations to give context
#(75, 97 are maximum index values)
#13, 54 is Honolulu 
#43, 58 is on NE side of mountains on the island
#42, 52 is on the SW side of the mountains (but still near the NE coast)


# Set up lat/lon for the 3 locations
loc.label = c("Honolulu", "Coast", "Inland")
loc.lats = c(13, 43, 42)
loc.lons = c(54, 58, 52)


####  Explore basic plots  ####

## RAINNC

pdf("C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/Hawaii/Rainfall_problem.pdf")

# Plot entire year for each location (Except the 'year' started 10 timesteps earlier)
par(mfrow = c(3,1))
par(mar = c(2,4,1,0))

for (j in 1:3){
  label = loc.label[j]
  lat = loc.lats[j]
  lon = loc.lons[j]
  
  plot(rainnc[lat, lon, 1:8670], xlab = "", ylab = "RAINNC (mm?)")
  mtext(label, side = 3, line = -1.5)
}

# Zoom in on transition between buckets
par(mfrow = c(3,1))
par(mar = c(2,4,1,0))

for (j in 1:3){
  label = loc.label[j]
  lat = loc.lats[j]
  lon = loc.lons[j]
  
  plot(rainnc[lat, lon, 1090:1200], xlab = "", ylab = "RAINNC (mm?)", xaxt = 'n')
  mtext(label, side = 3, line = -1.5)
}


## RAIN

# Plot entire year for each location (Except the 'year' started 10 timesteps earlier)
par(mfrow = c(3,1))
par(mar = c(2,4,1,0))

for (j in 1:3){
  label = loc.label[j]
  lat = loc.lats[j]
  lon = loc.lons[j]
  
  plot(rain[lat, lon, 1:8670], xlab = "", ylab = "RAIN (buckets?)")
  mtext(label, side = 3, line = -1.5)
}

# Zoom in on transition between buckets
par(mfrow = c(3,1))
par(mar = c(2,4,1,0))

for (j in 1:3){
  label = loc.label[j]
  lat = loc.lats[j]
  lon = loc.lons[j]
  
  plot(rain[lat, lon, 1090:1200], xlab = "", ylab = "RAIN (buckets?)", xaxt = 'n')
  mtext(label, side = 3, line = -1.5)
}

## I_RAINNC

# Plot entire year for each location (Except the 'year' started 10 timesteps earlier)
par(mfrow = c(3,1))
par(mar = c(2,4,1,0))

for (j in 1:3){
  label = loc.label[j]
  lat = loc.lats[j]
  lon = loc.lons[j]
  
  plot(irainnc[lat, lon, 1:8670], xlab = "", ylab = "IRAINNC (buckets?)")
  mtext(label, side = 3, line = -1.5)
}

# Zoom in on transition between buckets
par(mfrow = c(3,1))
par(mar = c(2,4,1,0))

for (j in 1:3){
  label = loc.label[j]
  lat = loc.lats[j]
  lon = loc.lons[j]
  
  plot(irainnc[lat, lon, 1090:1200], xlab = "", ylab = "IRAINNC (buckets?)", xaxt = 'n')
  mtext(label, side = 3, line = -1.5)
}

dev.off()

# Use a histogram to explore rainfall values
hist(rainnc)

threshold = function(x, threshold){
  out = 0
  if (x > threshold){
    out = 1
  }
}

df100 = data.frame(i = NA, j = NA, k = NA, value = NA, value_plus_one = NA)

# Find all examples where rainnc exceeds 100
for (i in 1:dim(rainnc)[1]){
  for (j in 1:dim(rainnc)[2]){
    for (k in 1:dim(rainnc)[3]){
      if (rainnc[i,j,k] > 100){
        k1 = NA
        if (k < dim(rainnc)[3]){
          k1 = rainnc[i,j,k+1]
        }
        df100 = rbind(df100, c(i,j,k, rainnc[i,j,k], k1))
      }
    }
  }
}
df100 = df100[2:nrow(df100), ]
df100$diff = NA
df100$diff[df100$value_plus_one < 100]= df100$value_plus_one[df100$value_plus_one < 100] - (df100$value[df100$value_plus_one < 100] - 100)
df100$diff[df100$value_plus_one < 100 & df100$value >=200]= df100$value_plus_one[df100$value_plus_one < 100 & df100$value >=200] - (df100$value[df100$value_plus_one < 100 & df100$value >=200] - 200)
df100$diff[df100$value_plus_one < 100 & df100$value >=300]= df100$value_plus_one[df100$value_plus_one < 100 & df100$value >=300] - (df100$value[df100$value_plus_one < 100 & df100$value >=300] - 300)

write.table(df100, file = "C:/hawaii_local/bucket_problem.csv", sep = ',',
            row.names = FALSE, col.names = TRUE)


# Find next time step
# Look at difference between last values

# Find largest delta between non-switch timesteps for context - how much rain falls in an hour?


```

```{r junk, include=FALSE}

      
      is.leap = 0
      #**# NEED CONTROL TO CHANGE TO LEAP YEAR DEPENDING ON VALUES OF i
      
      plot(rainnc[45,45,])

      #**# NEEDS DIFFERENT PROCESSING FOR PRECIP      
      # Create a table with daily tmin, tmax, tmean
      #day.start = 11 #**# CONFIRM WITH OLIVER AND RYAN ABOUT THIS!
      #daily.stuff = create.daily.files(i, var, leap.years, new.var, day.start)
      
      # Process it to each timescale
      
      # Monthly should just be the sum of the time slice associated with a particular month
      #**# FIX
      #if ("monthly" %in% timescales){
      #  calculate.min.max.mean.monthly(daily.stuff, i, var) # Creates a file names XXXX
      #}
      
      # Annual should just be the average of the entire ncdf file
      #**# FIX
      #if ("annual" %in% timescales){
      #  calculate.min.max.mean.annual(daily.stuff, i, var)
      #}
#    }
#  }
#}
```
