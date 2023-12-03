# -*- coding: utf-8 -*-
"""
Created on 2016-11-16

@author: Oliver Elison Timm
"""

from __future__ import print_function

from netCDF4 import Dataset

from wrf import getvar

from wrf import g_geoht

import matplotlib.pyplot as plt

import os 

# exampl with a WRF model output for the HI domain,

# 3-d data monthly mean values, one time step is in the file, only)

# so index array operations may require extension

# when working with hourly 3-d data files, for example.

# (e.g. one can use keyword argument timeidx to get a specific time index)

# See https://wrf-python.readthedocs.io/en/develop/internal_api/generated/wrf.g_geoht.get_height_agl.html


#my_path = "D:/hawaii_local/3D_Files"
my_path = r"F:\hawaii_800m_present_2004-2005\2004"
my_files = os.listdir(my_path)

#ncfile=Dataset("wrfout_d02_monthly_mean_2005_12.nc")
ncfile = Dataset(my_path + "/" + my_files[0])

 

 

test=g_geoht.get_height_agl(ncfile)

sfc_hgt=getvar(ncfile,'HGT')

 

print(test)

#**# Looks like level 0 or level 1 should be sufficient. level 0 is generally 30 m, so that's probably the better one to try.
#**# So we need to do this for EACH file, so probably need a Python script callable by R and just do it when we run through.

# But this is good. This is working.

level=0# first level closest to surface
level=1

plt.pcolormesh(test[level,:,:])

plt.title(f"hgt of layer level {level} above surface")

plt.colorbar()

plt.show()

 

 

plt.scatter(sfc_hgt,test[level,:,:])

plt.title(f"hgt of layer level {level} above surface hgt")

plt.xlabel("surface height [m]")

plt.ylabel("layer height [m]")

plt.show()

 

# try to export the hgt data into a netcdf file

outfile=f"wrf_hgt_test_level{level}.nc"

test.attrs['projection']=str(test.attrs['projection']) # needed to correct type

 
test.to_netcdf(outfile)

 

print(f"wrote hgt data into local file {outfile}")
