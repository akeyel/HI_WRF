# -*- coding: utf-8 -*-
"""
Modified script to copy select variables from 3D data set to be on a single hard drive

Created on 2016-11-16
Modified on 2024-03-23

@author: Oliver Elison Timm and Alexander Keyel
"""

from __future__ import print_function
from netCDF4 import Dataset
from wrf import getvar
from wrf import g_geoht
from wrf import ALL_TIMES
import os 

# See https://wrf-python.readthedocs.io/en/develop/internal_api/generated/wrf.g_geoht.get_height_agl.html

# Code set up for batching across years - could use an os.walk function, but this seems simpler and more controlled, somehow.
out_drive = 'F'
in_drive = 'D'
island = 'hawaii' #  'kauai_oahu' # 
scenario = 'present' # 'rcp85' #'present'
variable = 'U'
out_path_base = f'{out_drive}:/hawaii_local/hourly_vars/{island}_{scenario}' 
in_path_base = f'{in_drive}:/{island}_800m_{scenario}'
path_bits = ['1999']*1 +  ['2000-2001'] * 2  + ['2002-2003'] * 2 + ['2004-2005'] * 2 + ['2006-2007'] * 2
year_list = list(range(1999,2007 + 1)) # +1 is a reminder that the end range is not included.

for j in range(len(year_list)):
    my_path = f'{in_path_base}_{path_bits[j]}/{year_list[j]}'
    out_path = f'{out_path_base}/{year_list[j]}/{variable}'

    if not os.path.exists(out_path):
        os.makedirs(out_path)
    my_files = os.listdir(my_path)
    
    #for i in range(119,len(my_files)): # Bug on hawaii_present 3/16/1999, needed to be bypassed
    #for i in range(70,len(my_files)): # Bug on hawaii_present 3/16/1999, needed to be bypassed
    #for i in range(len(my_files)): #**# MAIN LINE OF CODE
    for i in range(3): #**# Temporary for testing purposes
        
        # Skip corrupted day from 1999 present. Need to remove this line later!!!
        #if i != 69 & j != 0:
    
        ncfile = Dataset(my_path + "/" + my_files[i])
        this_var = getvar(ncfile, variable, timeidx = ALL_TIMES)
        this_var.attrs['projection']=str(this_var.attrs['projection']) # needed to correct type


        outfile=f"{out_path}/{my_files[i]}_{variable}.nc"
        this_var.to_netcdf(outfile)
        
        
        #heights = g_geoht.get_height_agl(ncfile)
        #heights.shape # (50, 435, 455)
        
        # Keep just the bottom two heights
        #heights2 = heights[0:2,:,:]
        #heights2.attrs['projection']=str(heights.attrs['projection']) # needed to correct type
        #sfc_hgt=getvar(ncfile,'HGT')
        
        #level=0# first level closest to surface
        #level=1
        
        # Export the hgt data into netcdf files
        #outfile=f"{out_path}/{my_files[i]}_wind_heights.nc"
        #heights2.to_netcdf(outfile)
        print(f"Processed {outfile}")


'''
This did not provide any space savings. Looking for whether there is a compression option, or a way to join two different variables
# check whether concatenating files saves space
test_files = [Dataset(my_path + "/" + my_files[0]), Dataset(my_path + "/" + my_files[1]), Dataset(my_path + "/" + my_files[2])]
test_cat = getvar(test_files, "V", timeidx = ALL_TIMES, method = 'cat')

test_cat.attrs['projection']=str(test_cat.attrs['projection']) # needed to correct type


outfile=f"{out_path}/test_cat_3.nc"
test_cat.to_netcdf(outfile)
'''
