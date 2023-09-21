## Create a PDF with the QC results summarized by island, metric and timeperiod

# Basically, what I was doing in PPT, but with more organization

qc.dir = 'etwas'
setwd(qc.dir)
pdf("QC_for_review.pdf")

#**# Need to look at what is used for PPT, might be NCRAIN in the end

variables = c("PPT", "T2", "Q2", "GLW", "GRDFLX", "GSW", "HFX", "LH", "LWP", "PSFC", "TSK", "UDROFF", "SFROFF", "U10", "V10")
#not.run = c("U10", "V10", 'SFROFF', "UDROFF")
not.run = c("PPT", "T2", "Q2", "GLW", "HFX", "LWP", "UDROFF", "SFROFF", "U10", "V10")
hm.only = c("GRDFLX", "GSW", "LWP", "TSK")
ok.only = c("SFROFF", "UDROFF")

for (variable in variables){
  #**# Watch for problems with this
  metrics = c('_minimum','_mean', '_maximum')
  if (variable == 'PPT'){
    metrics = c('')
  }
  islands = c('hawaii', 'maui', 'oahu', 'kauai')
  if (variable %in% hm.only){  islands = c('hawaii', 'maui')  }
  if (variable %in% ok.only){  islands = c('oahu', 'kauai')}
  n.metrics = length(metrics)
  n.islands = length(islands)
  
  # Only run if there is data for the variable
  if (!variable %in% not.run){
    
    for (scenario in scenarios){
      par(mfrow = c(n.metrics, n.islands))
      
      for (metric in metrics){
        for (island in islands){
          var.path = sprintf("%s/%s_%s/", island, variable, scenario)
          file.part = sprintf("%s_%s_%s%s_annual_climatology_plot.tif", island, variable, scenario, metric)
          this.file = sprintf("%s%s", var.path, file.part)
          
          plot(this.file)
        }
      }
    }
  }
}


dev.off()