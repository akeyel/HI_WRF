# Check whether I_RAIN variable is necessary, or whether looking at differences
# between days is sufficient

# Maui and Hawaii have both variables, Oahu and Kauai have just RAINNC.

# Use Maui, because it is smaller


code.dir = 'C:/Users/ak697777/University at Albany - SUNY/Elison Timm, Oliver - CCEID/HI_WRF'
setwd(code.dir)
source("Workflow_hlpr.R")
data.dir = "C:/hawaii_local"
#setwd(data.dir)

island = "maui"

data.file = get.data.file('maui', 'present')
my.ncdf =ncdf4::nc_open(data.file)

# Year 2, to avoid spin-up effects, just pick a month to keep the data set size small.
rainnc = ncvar_get(my.ncdf, "RAINNC", start = c(50, 50, 8760), count = c(1,1,744)) #117 by 197
irain = ncvar_get(my.ncdf, "I_RAINNC", start = c(50, 50, 8760), count = c(1,1,744))

plot(seq(1,744), rainnc)
plot(seq(1,744), irain)

# Zoom in on incrementing event
plot(seq(600,700), rainnc[600:700])
plot(seq(600,700), irain[600:700])


# I_RAINNC method
irain.method = (irain[744] * 100 + rainnc[744]) - (irain[1] *100 + rainnc[1])
# Says 136.32 mm


# DELTA METHOD
n.steps = 744
cum.precip = 0
# First value of the precipitation data sets are the last hour of the previous year, to use for initialization
initial.value = rainnc[1]

# Iterate through new.var
for (k in 2:n.steps){
  
  # Convert the array to vector to allow differential processing
  this.precip = rainnc[k]
  #Use a function to properly deal with negative values
  new.precip = calc.precip(this.precip, initial.value)
  initial.value = this.precip # update precipitation values for the next time step
  # update cumulative precipitation
  cum.precip = cum.precip + new.precip
}



delta.method = cum.precip

delta.method == irain.method
# TRUE

# First check passed, including a value over 100. Let's see if we can find any of the weird values in the Maui data set.

rainnc2 = ncvar_get(my.ncdf, "RAINNC", start = c(1, 1, 8760), count = c(-1,-1,4000)) #117 by 197
irain2 = ncvar_get(my.ncdf, "I_RAINNC", start = c(1, 1, 8760), count = c(-1,-1,4000))

df100 = data.frame(i = NA, j = NA, k = NA, value = NA, value_plus_one = NA)

# Find all examples where rainnc exceeds 100
for (i in 1:dim(rainnc2)[1]){
  for (j in 1:dim(rainnc2)[2]){
    for (k in 1:dim(rainnc2)[3]){
      if (rainnc2[i,j,k] > 100){
        k1 = NA
        if (k < dim(rainnc2)[3]){
          k1 = rainnc2[i,j,k+1]
        }
        df100 = rbind(df100, c(i,j,k, rainnc2[i,j,k], k1))
      }
    }
  }
}
df100 = df100[2:nrow(df100), ]

write.table(df100, file = "C:/hawaii_local/bucket_problem_maui_version_802.csv", sep = ',',
            row.names = FALSE, col.names = TRUE)


test = rainnc2[165, 48, 1501:1600]
plot(seq(1,100), test)

test2 = rainnc2[165, 48, 1570:1600]
plot(seq(1,31), test2)

test2i = irain2[165, 48, 1570:1600]
plot(seq(1,31), test2i)

irain.method = (irain2[165, 48, 1600] * 100 + rainnc2[165, 48, 1600]) - (irain2[165, 48, 1570] *100 + rainnc2[165, 48, 1570])
#1531.397 1.5 m in 24 hours! Is that real?

# DELTA METHOD
n.steps = 31
cum.precip = 0
# First value of the precipitation data sets are the last hour of the previous year, to use for initialization
initial.value = rainnc2[165, 48, 1570]

# Iterate through new.var
for (k in 2:n.steps){
  
  # Convert the array to vector to allow differential processing
  this.precip = rainnc2[165, 48, (1569 + k)]
  #Use a function to properly deal with negative values
  new.precip = calc.precip(this.precip, initial.value)
  initial.value = this.precip # update precipitation values for the next time step
  # update cumulative precipitation
  cum.precip = cum.precip + new.precip
}

delta.method = cum.precip
