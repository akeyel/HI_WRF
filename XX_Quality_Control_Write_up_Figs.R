library(terra)
library(rspat)

# Create standardized plots for Results output
create.qc.plots = function(data.folder, ref.folder, fig.folder, variable,
                           use.ref, ref.type,
                           island, island.bit, outline,
                           do.main, do.supplement){
  
  # data.folder = "F:/hawaii_local/Vars/hawaii/RAINNC_present"
  # ref.folder = NA # For now, need to add in HI Rainfall atlas data
  # ref.folder = "F:/hawaii_local/Rainfall_Atlas/HawaiiRFGrids_mm/"
  # fig.folder = "F:/hawaii_local/QC/hawaii/RAINNC_present"
  # use.ref = NA
  # use.ref = 1
  # variable = "RAINNC" # For both rain variables at this stage
  # outline = "F:/hawaii_local/Vector/hawaii_ne.shp"
  # ref.type = 'ppt'

  if (do.main == 1){
    # Fig. 1
    QC.Fig1(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type)
    
    # Figs. 2 - 5
    QC.Fig.2to5(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type)
  }
  
  if (do.supplement == 1){
    # Fig. S1
    QC.Fig.S1(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type,
              island, island.bit)
    
    # Fig. S2
    QC.Fig.S2(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type,
              island, island.bit)
  }
  
  #**# NEED TO SCRIPT BELOW HERE
  # Fig. S3
  
  # Fig. S4
  
  # Table 1
    
  
}

#' Make Comparison Fig
#'
Comparison.Fig = function(data.file, ref.file, use.ref, outline){
  # Have option to just plot WRF if Reference is set to NA.
  # Plot WRF figure
  #**# Plot the data file with a standardized setting
  #**# Terra package? How to set break limits in R; this is usually something I do in Arc, but it'll go better if I can do it in R.
  r = rast(data.file) # How do we set break limits for the figure? probably not that hard, but for now, going with the defaults.
  o = vect(outline)
  plot(r)
  polys(o)
    
  if (!is.na(use.ref)){
    # Plot Reference figure
    ref = rast(ref.file)
    ref2 = crop(ref, r)
    #**# Plot the reference figure with a standardized setting
    plot(ref2)
    polys(o)
    
    # Plot difference figure
    #**# Plot the difference figure with a standardized setting
    diff = r - ref2
    plot(r - ref2)
    polys(o)
  }
}

#' Figure 1. Pattern for annual climatology
QC.Fig1 = function(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type){
  data.file = sprintf("%s/Climatology/tif/%s_Annual.tif", data.folder, variable)
  
  ref.file = ""
  n.cols = 1
  if (!is.na(use.ref)){
    #ref.file = sprintf("%s/Climatology/tif/%s_Annual.tif", ref.folder, variable)
    if (ref.type == 'ppt'){
      ref.file = sprintf("%s/Climatology/annual_1990_2009.tif", ref.folder)
    }
    if (is.na(ref.type)){ stop("Ref type must be defined and supported")} 
    n.cols = 3
  }
  plot.width = 1400 * n.cols
  
  #out.file = sprintf("%s/%s_annual_climatology_plot.pdf", fig.folder, variable)
  out.file = sprintf("%s/%s_annual_climatology_plot.tif", fig.folder, variable) 
  tiff(filename = out.file, height = 1200, width = plot.width, res = c(300), compression = c('lzw'))
  #pdf(out.file)
  par(mfrow = c(1,n.cols))
  Comparison.Fig(data.file, ref.file, use.ref, outline)
  dev.off()
  message(sprintf("Fig %s created", out.file))
}

#' Fig. 2 Pattern for monthly climatology
QC.Fig.2to5 = function(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type){
 
  n.col = 1
  if (!is.na(use.ref)){ n.col = 3  }
  plot.width = 1400 * n.cols
  
  count = 1 
  for (group in 1:4){
    out.file = sprintf("%s/%s_climatology_months_%0.2d_%0.2d_plot.tif", fig.folder, variable, count, count + 2)
    tiff(filename = out.file, height = 3600, width = plot.width, res = c(300), compression = c('lzw'))
    par(mfrow = c(3,n.cols))
    
    for (row in 1:3){
      data.file = sprintf("%s/Climatology/tif/%s_month_%s.tif", data.folder, variable, count)
      
      ref.file = "" 
      if (!is.na(use.ref)){
        if (ref.type == 'ppt'){
          ref.file = sprintf("%s/Climatology/Month_%0.2d_1990_2009.tif", ref.folder, count)        
        }
      }

      Comparison.Fig(data.file, ref.file, use.ref, outline)
      count = count + 1
    }
    dev.off()
    message(sprintf("Plot %s of 4 completed", group))
  }
}

# Fig. S1 Pattern for each individual year (1 * 20 = 20 plots)
QC.Fig.S1 = function(data.folder, ref.folder, fig.folder, variable, outline,
                     use.ref, ref.type, island, island.bit){
  n.col = 1
  if (!is.na(use.ref)){ n.col = 3  }
  plot.width = 1400 * n.cols
  
  out.file = sprintf("%s/%s_annual_plots.pdf", fig.folder, variable)
  pdf(out.file)
  for (count in 1:20){
  #for (group in 1:5){
    par(mfrow = c(1,n.cols))
    
    data.file = sprintf("%s/AnnualMeans/tif/%s_%s_mean_ppt.tif", data.folder, variable, count)
    ref.file = ""
    if (!is.na(use.ref)){
      if (ref.type == 'ppt'){ 
        ref.file = sprintf("%s/Month_Rasters_%s_mm/Annual/%sann_%s_mm", ref.folder, island, island.bit, count + 1989)
      }
    }
    
    Comparison.Fig(data.file, ref.file, use.ref, outline)
    message(sprintf("Plot %s of 20 completed", count))
  }
  dev.off()
}

# Fig. S2 Pattern for each individual month (20 * 12 = 240 plots)
QC.Fig.S2 = function(data.folder, ref.folder, fig.folder, variable, outline,
                     use.ref, ref.type, island, island.bit){
  n.col = 1
  if (!is.na(use.ref)){ n.col = 3  }
  plot.width = 1400 * n.cols
  
  month.bits = c('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')
  
  out.file = sprintf("%s/%s_monthly_plots.pdf", fig.folder, variable)
  pdf(out.file)
  for (year in 1:20){
    for (month in 1:12){
      #for (group in 1:5){
      par(mfrow = c(1,n.cols))
      
      data.file = sprintf("%s/MonthlyMeans/tif/%s_%s_%s_mean_ppt.tif", data.folder, variable, year, month)
      ref.file = ""
      if (!is.na(use.ref)){
        if (ref.type == 'ppt'){ 
          ref.file = sprintf("%s/Month_Rasters_%s_mm/%s_%0.2d%s/%sann_%s_mm", ref.folder, island, island.bit, month, month.bit, island.bit, count + 1989)
        }
      }
      
      Comparison.Fig(data.file, ref.file, use.ref, outline)
      message(sprintf("Plot %s of 12 for year %s completed", month, year + 1989))
    }
  }
  dev.off()
}

