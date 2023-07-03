library(terra)
library(rspat)

# Create standardized plots for Results output
create.qc.plots = function(data.folder, ref.folder, fig.folder, variable,
                           metric, use.ref, ref.type,
                           island, island.bit, scenario, outline,
                           do.main, do.supplement, do.extra, is.int = 1,
                           ppt.bit = "_ppt"
                           ){
  
  # data.folder = "F:/hawaii_local/Vars/hawaii/RAINNC_present"
  # ref.folder = NA # For now, need to add in HI Rainfall atlas data
  # ref.folder = "F:/hawaii_local/Rainfall_Atlas/HawaiiRFGrids_mm/"
  # fig.folder = "F:/hawaii_local/QC/hawaii/RAINNC_present"
  # use.ref = NA
  # use.ref = 1
  # variable = "RAINNC" # For both rain variables at this stage
  # outline = "F:/hawaii_local/Vector/hawaii_ne.shp"
  # ref.type = 'ppt'

  metric.bit = ""
  if (nchar(metric) > 0){ metric.bit = sprintf("%s_", metric)} # Add an underscore only if there is a non-blank metric
  
  int.bit = ""
  if (is.int == 1){ int.bit = "int_"}
  
  if (do.main == 1){
    # Fig. 1
    QC.Fig1(data.folder, ref.folder, fig.folder, variable, island, outline, use.ref, ref.type,
            metric.bit, is.int, int.bit, scenario = scenario)
    
    # Figs. 2 - 5
    QC.Fig.2to5(data.folder, ref.folder, fig.folder, variable, island, outline, use.ref, ref.type,
                metric.bit, is.int, int.bit, scenario = scenario)
  }
  
  if (do.supplement == 1){
    #warning("Supplemental figures are not using integer rasters, just FYI")
    #**# Annual means are currently not being produced as integer rasters, but climatologies apparently are? Should make this consistent.
    # Fig. S1
    QC.Fig.S1(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type,
              island, island.bit, metric.bit, is.int = is.int, int.bit = int.bit, header = TRUE, scenario = scenario, ppt.bit = ppt.bit)
    
    # Fig. S2
    QC.Fig.S2(data.folder, ref.folder, fig.folder, variable, outline, use.ref, ref.type,
              island, island.bit, metric.bit, is.int = is.int, int.bit = int.bit, header = TRUE, scenario = scenario, ppt.bit = ppt.bit)
  }
  
  if (do.extra == 1){
    # Plot as a percent of mean
    QC.percent.mean(data.folder, ref.folder, fig.folder, variable, island, outline,
                    ref.type, metric)
    
    # Plot as a percent of inter-annual variation
    QC.percent.variation(STUFF)
  }
  #**# NEED TO SCRIPT BELOW HERE
  # Fig. S3
  
  # Fig. S4
  
  # Table 1
    
  
}

#' Make Comparison Fig
#'
Comparison.Fig = function(data.file, ref.file, use.ref, outline,
                          header = FALSE, scenario = "",
                          header2 = "", is.int = 0){
  # Have option to just plot WRF if Reference is set to NA.
  # Plot WRF figure
  #**# Plot the data file with a standardized setting
  #**# Terra package? How to set break limits in R; this is usually something I do in Arc, but it'll go better if I can do it in R.
  r = rast(data.file) # How do we set break limits for the figure? probably not that hard, but for now, going with the defaults.
  if (is.int == 1){
    r = r / 100 # Convert back to original units
  }
  
  o = vect(outline)
  plot(r)
  polys(o)
  if (header == TRUE){ mtext(sprintf("WRF %s", scenario))}
  mtext(sprintf("%s%s",header2, paste(rep(" ", 70), collapse = "")), line = -3.5)
    
  if (!is.na(use.ref)){
    # Plot Reference figure
    ref = rast(ref.file)
    ref2 = crop(ref, r)
    #**# Plot the reference figure with a standardized setting
    plot(ref2)
    polys(o)
    if (header == TRUE){ mtext("REFERENCE")}
    
    # Plot difference figure
    #**# Plot the difference figure with a standardized setting
    r2 = crop(r, ref2) # Ensure extents match in both directions
    diff = r2 - ref2
    plot(r2 - ref2)
    polys(o)
    if (header == "TRUE"){ mtext("WRF - REF")}
  }
}

#' Figure 1. Pattern for annual climatology
QC.Fig1 = function(data.folder, ref.folder, fig.folder, variable, island, outline,
                   use.ref, ref.type, metric.bit, is.int, int.bit,
                   header = TRUE, scenario = "present"){
  data.file = sprintf("%s/Climatology/%stif/%s%s_Annual.tif", data.folder, int.bit, metric.bit, variable)
  
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
  out.file = sprintf("%s/%s_%s_%s_%sannual_climatology_plot.tif", fig.folder, island, variable, scenario, metric.bit) 
  tiff(filename = out.file, height = 1200, width = plot.width, res = c(300), compression = c('lzw'))
  #pdf(out.file)
  par(mfrow = c(1,n.cols))
  Comparison.Fig(data.file, ref.file, use.ref, outline, header, scenario, is.int = is.int)
  dev.off()
  message(sprintf("Fig %s created", out.file))
}

#' Fig. 2 Pattern for monthly climatology
QC.Fig.2to5 = function(data.folder, ref.folder, fig.folder, variable, island, outline,
                       use.ref, ref.type, metric.bit, is.int, int.bit, scenario){
 
  months = c('Jan','Feb','Mar',"Apr", 'May', "Jun", "Jul","Aug","Sep", "Oct", "Nov", "Dec")
  
  n.cols = 1
  if (!is.na(use.ref)){ n.cols = 3  }
  plot.width = 1400 * n.cols
  
  count = 1 
  for (group in 1:4){
    out.file = sprintf("%s/%s_%s_%s_%sclimatology_months_%0.2d_%0.2d_plot.tif", fig.folder, island, variable, scenario, metric.bit, count, count + 2)
    tiff(filename = out.file, height = 3600, width = plot.width, res = c(300), compression = c('lzw'))
    par(mfrow = c(3,n.cols))
    
    for (row in 1:3){
      data.file = sprintf("%s/Climatology/%stif/%s%s_month_%s.tif", data.folder, int.bit, metric.bit, variable, count)
      
      ref.file = "" 
      if (!is.na(use.ref)){
        if (ref.type == 'ppt'){
          ref.file = sprintf("%s/Climatology/Month_%0.2d_1990_2009.tif", ref.folder, count)        
        }
      }

      header = FALSE
      if (row == 1){ header = TRUE }
      
      Comparison.Fig(data.file, ref.file, use.ref, outline, header = header, scenario = scenario, header2 = months[count], is.int = is.int)
      count = count + 1
    }
    dev.off()
    message(sprintf("Plot %s of 4 completed", group))
  }
}

# Fig. S1 Pattern for each individual year (1 * 20 = 20 plots)
QC.Fig.S1 = function(data.folder, ref.folder, fig.folder, variable, outline,
                     use.ref, ref.type, island, island.bit, metric.bit, is.int, int.bit, header, scenario, ppt.bit){
  n.cols = 1
  if (!is.na(use.ref)){ n.cols = 3  }
  plot.width = 1400 * n.cols
  
  out.file = sprintf("%s/%s_%s_%s_%sannual_plots.pdf", fig.folder, island, variable, scenario, metric.bit)
  pdf(out.file)
  for (count in 1:20){
  #for (group in 1:5){
    par(mfrow = c(1,n.cols))
    
    data.file = sprintf("%s/AnnualMeans/%stif/%s%s_%s_mean%s.tif", data.folder, int.bit, metric.bit, variable, count, ppt.bit)
    ref.file = ""
    if (!is.na(use.ref)){
      if (ref.type == 'ppt'){ 
        ref.file = sprintf("%s/Month_Rasters_%s_mm/Annual/%sann_%s_mm", ref.folder, island, island.bit, count + 1989)
      }
    }
    
    Comparison.Fig(data.file, ref.file, use.ref, outline, header, scenario, is.int = is.int)
    message(sprintf("Plot %s of 20 completed", count))
  }
  dev.off()
}

# Fig. S2 Pattern for each individual month (20 * 12 = 240 plots)
QC.Fig.S2 = function(data.folder, ref.folder, fig.folder, variable, outline,
                     use.ref, ref.type, island, island.bit, metric.bit, is.int, int.bit, header, scenario, ppt.bit){
  n.cols = 1
  if (!is.na(use.ref)){ n.cols = 3  }
  plot.width = 1400 * n.cols
  
  month.bits = c('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')
  
  out.file = sprintf("%s/%s_%s_%s_%smonthly_plots.pdf", fig.folder, island, variable, scenario, metric.bit)
  pdf(out.file)
  for (year in 1:20){
    for (month in 1:12){
      month.bit = month.bits[month]
      #for (group in 1:5){
      par(mfrow = c(1,n.cols))
      
      data.file = sprintf("%s/MonthlyMeans/%stif/%s%s_%s_%s_mean%s.tif", data.folder, int.bit, metric.bit, variable, year, month, ppt.bit)
      ref.file = ""
      if (!is.na(use.ref)){
        if (ref.type == 'ppt'){ 
          ref.file = sprintf("%s/Month_Rasters_%s_mm/%s_%0.2d%s/%s%s%s_mm", ref.folder, island, island.bit, month, month.bit, island.bit, month.bit, year + 1989)
        }
      }
      
      Comparison.Fig(data.file, ref.file, use.ref, outline, header, scenario, is.int = is.int)
      message(sprintf("Plot %s of 12 for year %s completed", month, year + 1989))
    }
  }
  dev.off()
}

QC.percent.mean = function(data.folder, ref.folder, fig.folder, variable, island, outline, ref.type, metric){
  
  data.file = sprintf("%s/Climatology/tif/%s_Annual.tif", data.folder, variable)
  out.raster = sprintf("%s/Climatology/tif/%s_WRFminusRFAoverRFA.tif", data.folder, variable)
  
  if (ref.type == 'ppt'){
    ref.file = sprintf("%s/Climatology/annual_1990_2009.tif", ref.folder)
  }
  if (is.na(ref.type)){ stop("Ref type must be defined and supported")} 
  plot.width = 1400
  
  #out.file = sprintf("%s/%s_annual_climatology_plot.pdf", fig.folder, variable)
  out.file = sprintf("%s/%s_%s_%s_annual_climatology_percent_mean_plot.tif", fig.folder, island, variable, scenario) 
  tiff(filename = out.file, height = 1200, width = plot.width, res = c(300), compression = c('lzw'))
  #pdf(out.file)
  #par(mfrow = c(1,2))
  #**# MODIFY TO PLOT THE DIFFERENCE SCALED BY VARIATION NEXT TO IT
  plot.percent.mean(data.file, ref.file, out.raster, outline)
  dev.off()
  message(sprintf("Fig %s created", out.file))
}

plot.percent.mean = function(data.file, ref.file, out.raster, outline,
                           header2 = ""){
  # Get WRF - RFA / RFA
  r = rast(data.file) # How do we set break limits for the figure? probably not that hard, but for now, going with the defaults.
  o = vect(outline)
    
  # Plot Standardized difference figure
  ref = rast(ref.file)
  ref2 = crop(ref, r)
  r2 = crop(r, ref2) # Ensure extents match in both directions
  std.diff = (r2 - ref2) / ref2
  writeRaster(std.diff, filename = out.raster, overwrite=TRUE) # , datatype = "INT4U" Need to decide if we want this as an integer raster x100
  plot(std.diff)
  polys(o)
  mtext("(WRF - RFA)/RFA")
  mtext(sprintf("%s%s",header2, paste(rep(" ", 70), collapse = "")), line = -3.5)
}

QC.percent.variation = function(STUFF){
  
  
  
}