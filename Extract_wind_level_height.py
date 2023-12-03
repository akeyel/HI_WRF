# -*- coding: utf-8 -*-
"""
Created on 2016-11-16
Modified on 2023-12-01

@author: Oliver Elison Timm and Alexander Keyel
"""

from __future__ import print_function
from netCDF4 import Dataset
#from wrf import getvar
from wrf import g_geoht
import os 

# See https://wrf-python.readthedocs.io/en/develop/internal_api/generated/wrf.g_geoht.get_height_agl.html

#**# Adjust when running on 16 TB hard drives
#**# Add loop to walk up folders
my_path = r"F:\hawaii_800m_present_2004-2005\2004"
out_path = 'F:/wind_heights/hawaii_maui/2004'
if not os.path.exists(out_path):
    os.makedirs(out_path)
my_files = os.listdir(my_path)
for i in range(len(my_files)):
    ncfile = Dataset(my_path + "/" + my_files[i])
    heights = g_geoht.get_height_agl(ncfile)
    heights.shape # (50, 435, 455)
    
    # Keep just the bottom two heights
    heights2 = heights[0:2,:,:]
    heights2.attrs['projection']=str(heights.attrs['projection']) # needed to correct type
    #sfc_hgt=getvar(ncfile,'HGT')
    
    #level=0# first level closest to surface
    #level=1
    
    # Export the hgt data into netcdf files
    outfile=f"{out_path}/{my_files[i]}_wind_heights.nc"
    heights2.to_netcdf(outfile)
    print(f"Processed {outfile}")
