# -*- coding: utf-8 -*-
"""
Created on Sat Sep 10 13:15:01 2022

@author: ak697777
"""

import os
import sys
import arcpy

#csv_folder = sys.argv[1]
csv_folder = sys.argv[1]
#out_folder = sys.argv[2]
in_raster_template = sys.argv[2]
has_subdir = sys.argv[3]

# Need to checkout spatial analyst!
arcpy.CheckOutExtension("Spatial")
# Set environment to snap to HI Rainfall atlas layer
arcpy.env.snapRaster = in_raster_template
arcpy.env.overwriteOutput = True

def CSV_to_Raster(out_folder, csv_folder, in_csv, in_raster_template):
    # Pull in CSV file and Display XY data
    csv_file = "%s/%s" % (csv_folder, in_csv)
    arcpy.AddMessage(csv_file)
    out_layer = "%s" % in_csv
    arcpy.MakeXYEventLayer_management(csv_file, 'lon', 'lat', out_layer) # , {spatial_reference}, {in_z_field}
    
    arcpy.FeatureClassToFeatureClass_conversion (out_layer, out_folder, 'temp.shp')
    new_field = 'values2' # Need to create a new one that is explicitly numeric, otherwise ArcGIS can decide to import the values as text and crash everything.
    #field_description = [['values2', 'FLOAT']]
    #arcpy.management.AddFields(out_layer, field_description)
    out_layer2 = out_folder + "/temp.shp"
    arcpy.AddField_management (out_layer2, new_field, "FLOAT", field_is_nullable = "NULLABLE") 
    
    arcpy.management.CalculateField(out_layer2, new_field, '!values!', 'PYTHON')

    # Interpolate to Hawaii Rainfall Grid file
    z_field = "values2"
    outIDW = arcpy.sa.Idw(out_layer2, z_field) # , {cell_size}, {power}, {search_radius}, {in_barrier_polyline_features}
    outIDW = outIDW * 100 #**# Will this work?
    outIDW = outIDW + 0.5 # Int works by truncation. This ensures truncation will round values relative to the original
    outIDW = arcpy.sa.Int(outIDW)
    
    # Save
    idw_file = "%s/%s.tif" % (out_folder, in_csv[:-4]) # Scrub off .csv from the file name
    outIDW.save(idw_file)

if __name__ == "__main__":

    if has_subdir == "NO":
        # Get all files in the folder
        all_files = os.listdir(csv_folder)
        out_folder = os.path.join(csv_folder, "tif")
        if not os.path.exists(out_folder):
            os.makedirs(out_folder)
        
        for this_file in all_files:
            CSV_to_Raster(out_folder, csv_folder, this_file, in_raster_template)

    if has_subdir == "YES":
        all_dirs = os.listdir(csv_folder)
        for this_dir in all_dirs:
            in_folder = os.path.join(csv_folder, this_dir)
            out_folder = os.path.join(csv_folder, this_dir + "_tif")
            if not os.path.exists(out_folder):
                os.makedirs(out_folder)
            all_files = os.listdir(in_folder)
            for this_file in all_files:
                CSV_to_Raster(out_folder, in_folder, this_file, in_raster_template)
                
    #for root, dirs, files in os.walk(csv_folder):
    #    for this_file in files:
    #        in_folder = root
    #        out_folder = root + "_tif" # Create a year-specific sub-folder
    #        #print(os.path.join(root, this_file))
    #        CSV_to_Raster(out_folder, csv_folder, this_file, in_raster_template)

 