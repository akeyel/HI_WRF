# Assume there are 10 hours in a day
# Assume there are 10 days in a year
# So 1 - 10 are day 1
# 11 - 20 are day 2
# and 91 - 100 are day 3.

new.var.part = c()
for (k in 1:101){
  for (i in 1:5){
    for (j in 1:5){
      new.var.part = c(new.var.part, k)
    }
  }
}

#new.var.part = sort(rep(seq(1,100), 25))
new.var = array(new.var.part, dim = c(5,5,101))
new.var[1,1,]

lat = dim(new.var)[1]
lon = dim(new.var)[2]
n.steps = dim(new.var)[3]

total.hour.count = 0
day.count = 1
hour.count = 0 # Change 2022-10-28, formerly 1.
cum.precip = rep(0, lat * lon)
# First value of the precipitation data sets are the last hour of the previous year, to use for initialization
initial.values = matrix(new.var[ , , 1], nrow = 1)

# Iterate through new.var
for (k in 2:n.steps){
  
  # Convert the array to vector to allow differential processing
  this.precip = matrix(new.var[ , , k], nrow = 1)
  #Use a function to properly deal with negative values
  new.precip = mapply(calc.precip, this.precip, initial.values)
  initial.values = this.precip # update precipitation values for the next time step
  # update cumulative precipitation
  cum.precip = cum.precip + new.precip
  
  hour.count = hour.count + 1
  total.hour.count = total.hour.count + 1
  # If a new day is started, save off the values
  if (hour.count == 10){
    if (day.count == 1){
      day.ppt.array = cum.precip
    }else{
      # Adapt matrix test code from above to build out the correct length array
      day.ppt.array = array(c(day.ppt.array, cum.precip), dim = c(lat, lon, day.count))
    }
    cum.precip = rep(0, lat * lon)
    day.count = day.count + 1
    hour.count = 0
  }
}

# OK. This worked exactly as it as supposed to. So what is wrong with it when I use the more complicated numbers?
# Where am I going wrong?

# Are my timesteps off? How is it getting dim from new.var? What is new.var at this point? Wait, what?
# new.var needs to have 8761 entries in it.
# And 9 should be the first slice, because it should go
# 10 - 8769.
# 8770 - 17529
# etc. But need to grab one more.
# so:
# 9 - 8759
length(seq(9,8769))
# So this is the pattern we need. Double check this is the pattern being generated - I suspect something is slightly off.
