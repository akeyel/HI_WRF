# List Variable Names for the different Islands
# Created 2022-4-12 from Workflow_v2.R

# Open the data file
my.ncdf =ncdf4::nc_open(data.file)
#print(my.ncdf) # This shows the associated metadata

years = length(my.ncdf$dim$Time$vals) / (365 * 24)
years # 20.0137 (because it doesn't account for leap years yet)
# Single file is 2.6 MB for one time step for everything
# ~455 GB for entire file
# individual variables are ~9 GB


#length(my.ncdf$dim$Time$vals)
# 175320 for Oahu
# 175320 for Kauai
# 175296 for Hawaii
# Maui??

# Variable dimensions
# kauai$var$T2_present$varsize # 82 64 175320 # For Kauai
# my.ncdf$var$T2_present$varsize # 180 205 175296 # Why is this 24 timesteps shorter? For Hawaii Present


# Oahu
#names(my.ncdf$var)
#[1] "ACLHF_present"  "XLAT"           "XLONG"          "Times"          "time_bnds"      "ALBBCK_present"
#[7] "ALBEDO_present" "GLW_present"    "HFX_present"    "LH_present"     "OLR_present"    "PSFC_present"  
#[13] "Q2_present"     "QFX_present"    "RAIN_present"   "I_RAINNC"       "RAINNC_present" "SFROFF_present"
#[19] "SMOIS_present"  "DZS"            "SNOW_present"   "SNOWH_present"  "T2_present"     "TH2_present"   
#[25] "Times_present"  "XTIME"          "TSLB_present"   "U10_present"    "UDROFF_present" "V10_present"   
#[31] "VEGFRA_present" "ACLHF_rcp45"    "ALBBCK_rcp45"   "ALBEDO_rcp45"   "GLW_rcp45"      "HFX_rcp45"     
#[37] "LH_rcp45"       "OLR_rcp45"      "PSFC_rcp45"     "Q2_rcp45"       "QFX_rcp45"      "RAIN_rcp45"    
#[43] "RAINNC_rcp45"   "SFROFF_rcp45"   "SMOIS_rcp45"    "SNOW_rcp45"     "SNOWH_rcp45"    "T2_rcp45"      
#[49] "TH2_rcp45"      "Times_rcp45"    "TSLB_rcp45"     "U10_rcp45"      "UDROFF_rcp45"   "V10_rcp45"     
#[55] "VEGFRA_rcp45"   "ACLHF_rcp85"    "ALBBCK_rcp85"   "ALBEDO_rcp85"   "GLW_rcp85"      "HFX_rcp85"     
#[61] "LH_rcp85"       "OLR_rcp85"      "PSFC_rcp85"     "Q2_rcp85"       "QFX_rcp85"      "RAIN_rcp85"    
#[67] "RAINNC_rcp85"   "SFROFF_rcp85"   "SMOIS_rcp85"    "SNOW_rcp85"     "SNOWH_rcp85"    "T2_rcp85"      
#[73] "TH2_rcp85"      "Times_rcp85"    "TSLB_rcp85"     "U10_rcp85"      "UDROFF_rcp85"   "V10_rcp85"     
#[79] "VEGFRA_rcp85"

# Kauai
#names(kauai$var)
#[1] "ACLHF_present"  "XLAT"           "XLONG"          "Times"          "time_bnds"      "ALBBCK_present" "ALBEDO_present"
#[8] "GLW_present"    "HFX_present"    "LH_present"     "OLR_present"    "PSFC_present"   "Q2_present"     "QFX_present"   
#[15] "RAIN_present"   "I_RAINNC"       "RAINNC_present" "SFROFF_present" "SMOIS_present"  "DZS"            "SNOW_present"  
#[22] "SNOWH_present"  "T2_present"     "TH2_present"    "Times_present"  "XTIME"          "TSLB_present"   "U10_present"   
#[29] "UDROFF_present" "V10_present"    "VEGFRA_present" "ACLHF_rcp45"    "ALBBCK_rcp45"   "ALBEDO_rcp45"   "GLW_rcp45"     
#[36] "HFX_rcp45"      "LH_rcp45"       "OLR_rcp45"      "PSFC_rcp45"     "Q2_rcp45"       "QFX_rcp45"      "RAIN_rcp45"    
#[43] "RAINNC_rcp45"   "SFROFF_rcp45"   "SMOIS_rcp45"    "SNOW_rcp45"     "SNOWH_rcp45"    "T2_rcp45"       "TH2_rcp45"     
#[50] "Times_rcp45"    "TSLB_rcp45"     "U10_rcp45"      "UDROFF_rcp45"   "V10_rcp45"      "VEGFRA_rcp45"   "ACLHF_rcp85"   
#[57] "ALBBCK_rcp85"   "ALBEDO_rcp85"   "GLW_rcp85"      "HFX_rcp85"      "LH_rcp85"       "OLR_rcp85"      "PSFC_rcp85"    
#[64] "Q2_rcp85"       "QFX_rcp85"      "RAIN_rcp85"     "RAINNC_rcp85"   "SFROFF_rcp85"   "SMOIS_rcp85"    "SNOW_rcp85"    
#[71] "SNOWH_rcp85"    "T2_rcp85"       "TH2_rcp85"      "Times_rcp85"    "TSLB_rcp85"     "U10_rcp85"      "UDROFF_rcp85"  
#[78] "V10_rcp85"      "VEGFRA_rcp85"

# Hawaii Present
#names(my.ncdf$var) # for Hawaii Present
#[1] "HGT"      "LANDMASK" "XLAT"     "XLONG"    "CFRACL"   "CFRACT"   "FGDP"     "GLW"      "GRDFLX"   "GSW"      "HFX"     
#[12] "I_RAINNC" "LAI"      "LH"       "LU_INDEX" "LWP"      "PSFC"     "Q2"       "RAINNC"   "SNOW"     "SNOWC"    "SNOWH"   
#[23] "T2"       "TSK"      "U10"      "V10" 

