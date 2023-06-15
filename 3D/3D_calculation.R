# Goal is to script out the basics of the test equation for Tom and Han
# Also will help to identify where variables need their units changed.

# Created 2023-05-23 based on notes from December 2022

# Read in 3D example file

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

## Calculate CWF
LWC = "QCLOUD?" #**# Pull from QCLOUD variable? But probably needs unit transformations
# Will need density of air for unit transformation
WS = "WS" #**# Pull from vertical and horizontal wind components, except need 2 m windspeed - need to know what lowest wind level of the simulation is, and need to use another equation to adjust to estimated 2 m windspeed. 
# Oliver also said wind speeds were on an offset grid, so we'll need to think about that aspect as well - may need to interpolate to get the location of interest.

CWF = (LWC / p_water) * WS * 3.6

# Land surface model documentation should describe this
## Calculate A
LAI = "etwas"
canopy.height = "etwas"

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
