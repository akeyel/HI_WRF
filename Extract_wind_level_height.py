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

# Code set up for batching across years - could use an os.walk function, but this seems simpler and more controlled, somehow.
out_drive = 'D'
in_drive = 'F'
island = 'hawaii' #  'kauai_oahu' # 
scenario = 'rcp85' # 'rcp85' #'present'
out_path_base = f'{out_drive}:/wind_heights/{island}_{scenario}' # formerly F, but changed drives
in_path_base = f'{in_drive}:/{island}_800m_{scenario}'
path_bits = ['1998-1999']*1 +  ['2000-2001'] * 2  + ['2002-2003'] * 2 + ['2004-2005'] * 2
year_list = list(range(1999,2005 + 1)) # +1 is a reminder that the end range is not included.
#path_bits = ['2002-2003']
#year_list = ['2003']

#path1 = f"F:/{island}_800m_{scenario}_1990-1996" # Formerly D, but it mapped the drives opposite
#path2 = f"F:/{island}_800m_{scenario}_1997-2003"
#path3 = f'F:/{island}_800m_{scenario}_2004-2009'

#path_list = [path1] * 7 + [path2] * 7 + [path3]*6
#year_list = list(range(2006,2009+1)) # Does not include last number!

for j in range(len(year_list)):
    my_path = f'{in_path_base}_{path_bits[j]}/{year_list[j]}'
    #my_path = f'{path_list[j]}/{year_list[j]}'
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
