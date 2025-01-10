# Completeness Check for CWI Variables

years = seq(1990,2009)
vars = c("IVGTYP", "LAI", "PSFC", "QCLOUD", "T2", "U", "V", "VEGFRA")
islands = c("hawaii", "kauai_oahu")
scenarios = c("present", "rcp45", "rcp85")

year.df = data.frame(island = NA, scenario = NA, year = NA)
file.df = data.frame(island = NA, scenario = NA, var = NA,  year = NA,
                     month = NA, day = NA, file.size = NA, is.missing = NA)

base.dir = "F:/hawaii_local/hourly_vars"
months = seq(1,12)

for (island in islands){
  for (scenario in scenarios){
    for (year in years){
      month.days = c(31,28,31,30,31,30,31,31,30,31,30,31)
      if (year %% 4 == 0){ month.days[2] = 29 }
      # Check that year was run, if not, do not continue rest of loop
      year.dir = sprintf("%s/%s_%s/%s", base.dir, island, scenario, year)
      if (!file.exists(year.dir)){
        year.df = rbind(year.df, c(island, scenario, year))
      }else{
        for (var in vars){
          for (i in 1:length(months)){
            month = months[i]
            day.of.month = month.days[i]
            for (day in 1:day.of.month){
              # Check if file exists
              day.file = sprintf("%s/%s/wrfout_d01_%s-%02.f-%02.f_%s.nc",
                                 year.dir, var,
                                 year, month, day, var)
              
              if (file.exists(day.file)){
                # Extract file size
                file.size = file.info(day.file)$size
                file.df = rbind(file.df, c(island, scenario, var, year, month, day, file.size, FALSE))
              }else{
                file.df = rbind(file.df, c(island, scenario,var, year, month, day, NA, TRUE))
              }
            }
          }
        }
      }
    }
  }
  year.df = year.df[2:nrow(year.df), ]
  file.df = file.df[2:nrow(file.df), ]
  
  write.csv(year.df, file = sprintf("CWI_QC_Year_%s.csv", island), row.names = FALSE)
  write.csv(file.df, file = sprintf("CWI_QC_Files_%s.csv", island), row.names = FALSE)
  
}


# Check for abnormal file sizes for fixing
