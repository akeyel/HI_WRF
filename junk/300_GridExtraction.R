# Script to work with the GRID

# Created 2022-04-12

#**# IN PROGRESS

# Extract data for a variable based on grid coordinates (testing for Albedo)
extract.data.by.grid(STUFF) #**# IN PROGRESS - NOT QUITE SURE WHAT THE OBJECTIVE IS OR THE DATA FLOW
#**# MAY WANT TO REPLACE WITH SHINY INTERFACE - THINK ABOUT THIS

extract.data.by.location(my.ncdf, row.index, col.index, start.time, end.time)

# Test for a time series
row.index = 1 #**# Adjust
col.index = 1 #**# Adjust
start.time = 1
end.time = 24
out.test = extract.data.by.location(my.ncdf, var.vec[1], row.index, col.index, start.time, end.time)
#**# Do something with out.test
