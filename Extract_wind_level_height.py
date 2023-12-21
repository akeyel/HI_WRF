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

# Code for running a year individually
#my_path = r"F:\hawaii_800m_present_2004-2005\2004"
#out_path = 'F:/wind_heights/hawaii_maui/2004'
#my_path = r"F:\kauai_oahu_800m_present_2004-2009\2004"
#out_path = 'F:/wind_heights/kauai_oahu/2004'
#my_path = r"D:\hawaii_800m_present_2002-2003/2002"
#out_path = 'F:/wind_heights/hawaii_present/2003'

# Code set up for batching across years - could use an os.walk function, but this seems simpler and more controlled, somehow.
out_path_base = 'F:/wind_heights/hawaii_present'
path1 = r"D:\hawaii_800m_present_2004-2005"
path2 = r"D:\hawaii_800m_present_2006-2007"

path_list = [path1, path1, path2, path2]
year_list = [2004, 2005, 2006, 2007]

for j in range(len(path_list)):
    my_path = f'{path_list[j]}/{year_list[j]}'
    out_path = f'{out_path_base}/{year_list[j]}'

    if not os.path.exists(out_path):
        os.makedirs(out_path)
    my_files = os.listdir(my_path)
    #my_files = my_files[70:]# Patch because it errored on 1999-03-16, which is file 69. May need to interpolate here for completeness.
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
