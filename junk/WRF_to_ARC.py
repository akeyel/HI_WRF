'''
This script is intended to support an ArcGIS toolbox that can convert from the
Hawaii WRF format to a format with a projection that can be read by ArcGIS.

It is a modified version of module_3.py, which is a script that was shared
by Richard Lader (#**# original author unknown to me)

It was adapted to HI and to an ArcGIS toolbox by Alexander Keyel <akeyel@albany.edu>
with support from the PI-CASC grant <#**# GRANT NUMBER HERE>

#**# LICENSE FOR REUSE

#**# LEFT OFF HERE - SHOULD SWITCH TO PYTHON 2 FOR FURTHER DEVELOPMENT - THIS VERSION IS NOT COMPATIBLE WITH ARCGIS.

'''


if __name__ == '__main__':
    import arcpy
    import sys
    
    # Input parameters
    island = sys.argv[1]
    in_file = sys.argv[2]
    out_folder = sys.argv[3]
    out_file = sys.argv[4]
    proj4_file = sys.argv[5] # In case someone needs to override the set parameters


    in_features = "C:/hawaii_local/GIS/Oahu/OahuGridIndex.shp"
    value_field = "values"
    out_rasterdataset = "C:/hawaii_local/GIS/scratch/Oahutest1.tif"
    cell_assignment= "MEAN"

    if proj4_file != "" and proj4_file != "NA":
        raise ValueError("%s; proj4_file is not yet supported. Please edit the underlying code to add this functionality" % proj4_file)

    if island != "Oahu":
        raise ValueError("Currently Oahu is the only supported island")

    if island == "Oahu":
        arcpy.conversion.PointToRaster(in_features, value_field, out_rasterdataset, cell_assignment)