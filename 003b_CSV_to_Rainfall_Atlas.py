# -*- coding: utf-8 -*-
"""
Created on Sat Sep 10 13:15:01 2022

@author: ak697777
"""

import os
import sys
import arcpy


#csv_folder = sys.argv[1]
csv_file = sys.argv[1]
in_raster_template = sys.argv[2]

#csv_file = r'C:\hawaii_local\Vars\oahu\ProcessedPPT\Oahu_present_Precipitation_7day_SUM_1_1990.csv'
#in_raster_template = r'C:\hawaii_local\Vars\grids\rainfall_atlas_files\rf_mm_oa_ann'

csv_parts = csv_file.split(os.sep)
# Check if delimiter is forward slash if initial split does not yield multiple pieces
if len(csv_parts) == 1:
    csv_parts = csv_file.split("/")

#csv_folder = os.path.join(csv_parts[0:-1])
csv_folder = "/".join(csv_parts[0:-1])
in_csv = csv_parts[-1]

#arcpy.Message(csv_folder)
#arcpy.Message(in_csv)
#in_raster_template = r'C:\hawaii_local\Vars\grids\rainfall_atlas_files/rf_mm_oa_ann'

# Need to checkout spatial analyst!
arcpy.CheckOutExtension("Spatial")
# Set environment to snap to HI Rainfall atlas layer
arcpy.env.snapRaster = in_raster_template

def batch_process(csv_folder, in_raster_template, SOMETHING):
    
    # Loop through SOMETHING and process each csv
    
    # Or do we just process all the .csv's in the folder? That would be easy!

    raise ValueError("This has not been scripted yet!")

def CSV_to_Raster(csv_folder, in_csv, in_raster_template):
    # Pull in CSV file and Display XY data
    csv_file = "%s/%s" % (csv_folder, in_csv)
    out_layer = "%s" % in_csv
    arcpy.MakeXYEventLayer_management(csv_file, 'lon', 'lat', out_layer) # , {spatial_reference}, {in_z_field}
    
    # Interpolate to Hawaii Rainfall Grid file
    z_field = "values"
    outIDW = arcpy.sa.Idw(out_layer, z_field) # , {cell_size}, {power}, {search_radius}, {in_barrier_polyline_features}
    
    # Save
    idw_file = "%s/%s.tif" % (csv_folder, in_csv[:-4]) # Scrub off .csv from the file name
    outIDW.save(idw_file)

if __name__ == "__main__":
    CSV_to_Raster(csv_folder, in_csv, in_raster_template)
