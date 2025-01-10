# -*- coding: utf-8 -*-
"""
Modified script to copy select variables from 3D data set to be on a single hard drive

Created on 2016-11-16
Modified on 2023-12-01

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
in_drive = 'D' #G
island = 'hawaii' #   'kauai_oahu' # 
scenario = 'rcp85' #'rcp45' #'present' # 'present'
#variable = 'V'
# Wind is being extracted separately in full 3D resolution, use Extract_hourly_variable.py for U and V
# Get the variables, with an indicator to ensure proper handling of each variable
variables_3d = ["QCLOUD", "U", "V"] # Update logic below for each 3D variable to ensure it is extracted properly
variables_2d = ["PSFC", "T2", "IVGTYP", "LAI", "VEGFRA"] #**# Do we need U10 and V10??? skipping for now, since we have U and V. "U10", "V10", 
#var_dims = [3] * len(variables_3d) + [2] * len(variables_2d) 
variables = variables_3d + variables_2d

err_log_file = f'{out_drive}:/hawaii_local/hourly_vars/error_log_{island}_{scenario}.csv'
out_path_base = f'{out_drive}:/hawaii_local/hourly_vars/{island}_{scenario}' 
in_path_base = f'{in_drive}:/{island}_800m_{scenario}'

path_bits = ['1990-1996'] * 7 + ['1997-2003'] * 7 + ['2004-2009'] * 6
year_list = list(range(1990,2009+1))

#path_bits = ['1998-1999']*2 +  ['2000-2001'] * 2  + ['2002-2003'] * 2 + ['2004-2005'] * 2 #  + ['2006-2007'] * 2
#year_list = list(range(1998,2005 + 1)) # +1 is a reminder that the end range is not included.

#path_bits = ['1990-1991'] * 2 + ['1992-1993'] * 2 + ['1994-1995'] * 2 + ['1996-1997']*2 # + ['1998-1999'] * 2
#year_list = list(range(1990,1997+1))

#path_bits = ['2006-2007'] * 2 + ['2008-2009'] * 2
#year_list = list(range(2006,2009+1))

for k in range(len(variables)):
    variable = variables[k]
    #var_dim = var_dims[k]
    
    if variable == "U" or variable == "V":
        #raise ValueError("Please use Extract_hourly_variable.py for U and V. This script only takes the bottom level of 3D varaibles")
        print("Only first two levels extracted for U and V")

    for j in range(len(year_list)):
    #for j in range(1,2):    
        my_path = f'{in_path_base}_{path_bits[j]}/{year_list[j]}'
        out_path = f'{out_path_base}/{year_list[j]}/{variable}'
    
        if not os.path.exists(out_path):
            os.makedirs(out_path)
        my_files = os.listdir(my_path)
        
        for i in range(len(my_files)):
            outfile=f"{out_path}/{my_files[i]}_{variable}.nc"
            try:
                ncfile = Dataset(my_path + "/" + my_files[i])
                this_var = getvar(ncfile, variable, timeidx = ALL_TIMES)
    
                #if var_dim == 3:
                if variable in ["U", "V"]:
                    # Keep bottom two levels for U and V. For all levels for these variables, use Extract_hourly_variable.py script
                    this_var = this_var[:,0:2,:,:]
                if variable in ['QCLOUD']:
                    # Keep just the bottom level for 3D data
                    this_var = this_var[:,0:1,:,:]
                        
                this_var.attrs['projection']=str(this_var.attrs['projection']) # needed to correct type
            
                this_var.to_netcdf(outfile)
                print(f"Processed {outfile}")
                ncfile.close()
            except:
                # Try to close the file to avoid memory loss
                try:
                    ncfile.close()
                except:
                    pass
                print(f'FAILED: {outfile}')
                with open(err_log_file, 'a') as err_log:
                    err_log.write(f'{my_files[i]},{variable},{i},{j}\n')
                
            # Skip corrupted day from 1999 present. Need to remove this line later!!!
            #skip = 0
            #if i == 69 and j == 0:
            #    skip = 1
            #if skip == 0:
        
