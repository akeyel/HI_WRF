# -*- coding: utf-8 -*-
"""
Created on Sat Sep 10 13:15:01 2022

@author: ak697777
"""

import os
import sys
import arcpy

#csv_folder = sys.argv[1]
raster_folder = sys.argv[1]
rfa_folder = sys.argv[2]
island_code = sys.argv[3]
variable = "RAINNC" #sys.argv[3]
repetitions = 13

# Need to checkout spatial analyst!
arcpy.CheckOutExtension("Spatial")
# Set environment to snap to HI Rainfall atlas layer
#arcpy.env.snapRaster = in_raster_template
#arcpy.env.overwriteOutput = True

for i in range(repetitions):
    wrf_file = raster_folder + "/%s_month_%s.tif" % (variable, i)
    rfa_file = rfa_folder + "/rf_mm_%s_%s" % (island_code, str(i).zfill(2))
    out_file = raster_folder + "/%s_month_%s_diff.tif" % (variable, i)
    if i == 0:
        wrf_file = raster_folder + "/%s_Annual.tif" % variable
        rfa_file = rfa_folder + "/rf_mm_%s_ann" % island_code
        out_file = raster_folder + "/%s_annual_diff.tif" % (variable)
    
    diff = arcpy.sa.Minus(wrf_file, rfa_file) #, out_file
    diff.save(out_file)
