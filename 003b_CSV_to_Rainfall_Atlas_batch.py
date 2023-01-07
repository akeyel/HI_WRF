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
template_string = sys.argv[2]
repetitions = int(sys.argv[3])
in_raster_template = sys.argv[4]

# Need to checkout spatial analyst!
arcpy.CheckOutExtension("Spatial")
# Set environment to snap to HI Rainfall atlas layer
arcpy.env.snapRaster = in_raster_template
arcpy.env.overwriteOutput = True

def CSV_to_Raster(csv_folder, in_csv, in_raster_template):
    # Pull in CSV file and Display XY data
    csv_file = "%s/%s" % (csv_folder, in_csv)
    arcpy.AddMessage(csv_file)
    out_layer = "%s" % in_csv
    arcpy.MakeXYEventLayer_management(csv_file, 'lon', 'lat', out_layer) # , {spatial_reference}, {in_z_field}
    
    arcpy.FeatureClassToFeatureClass_conversion (out_layer, csv_folder, 'temp.shp')
#    arcpy.management.Copy(out_layer, out_layer2)
    
    
    new_field = 'values2' # Need to create a new one that is explicitly numeric, otherwise ArcGIS can decide to import the values as text and crash everything.
    #field_description = [['values2', 'FLOAT']]
    #arcpy.management.AddFields(out_layer, field_description)
    out_layer2 = csv_folder + "/temp.shp"
    arcpy.AddField_management (out_layer2, new_field, "FLOAT", field_is_nullable = "NULLABLE") 
    
#    expression = "DO_CALC(!values!)"
#    codeblock = '''
#def DO_CALC(x):
#    if x == "NA":
#        y = '<Null>'
#    else:
#        y = float(x)
#    return(y)
#'''
#    arcpy.management.CalculateField(out_layer2, new_field, expression, 'PYTHON', codeblock)
    arcpy.management.CalculateField(out_layer2, new_field, '!values!', 'PYTHON')
    # Interpolate to Hawaii Rainfall Grid file
    z_field = "values2"
    outIDW = arcpy.sa.Idw(out_layer2, z_field) # , {cell_size}, {power}, {search_radius}, {in_barrier_polyline_features}
    #z_field = 'values'
    #outIDW = arcpy.sa.Idw(out_layer, z_field) # , {cell_size}, {power}, {search_radius}, {in_barrier_polyline_features}
    
    # Save
    idw_file = "%s/%s.tif" % (csv_folder, in_csv[:-4]) # Scrub off .csv from the file name
    outIDW.save(idw_file)

if __name__ == "__main__":

    # Also process the annual climatology
    in_csv = template_string[:-6] + "Annual.csv" # Drop month_ from the template
    CSV_to_Raster(csv_folder, in_csv, in_raster_template)

    for i in range(repetitions):
        arcpy.AddMessage(template_string)
        in_csv = template_string + str(i + 1) + ".csv"
        arcpy.AddMessage(in_csv)
        CSV_to_Raster(csv_folder, in_csv, in_raster_template)

 