# Goal is to perform descriptive analyses of initial measurements of CWI
# for Han's locations.

base.path = 'D:/hawaii_local/CWI_Han'

# Look at CWI for different years for Hawaii/Maui
years = c(2000, 2001, 2002, 2004, 2005, 2006, 2007)
for (year in years){
  for (quarter in c('Q1', 'Q2', 'Q3', 'Q4')){
    this.quarter = read.csv(sprintf("%s/hm/CWI_estimates_hm_%s_%s.csv",base.path, year, quarter))
    if (quarter == 'Q1' & year == 2000){
      hm.df = this.quarter
    }else{
      hm.df = rbind(hm.df, this.quarter)
    }
  }
}

write.csv(hm.df, file = sprintf("%s/hm_combined.csv", base.path), row.names = FALSE)
hm.df$year = substr(hm.df$date, 1,4)

# Create annual sums
hm.summary = data.frame(site = NA, year = NA, cwi = NA)
sites = unique(hm.df$location)
for (year in years){
  year.df = hm.df[hm.df$year == year, ]
  for (site in sites){
    site.df = year.df[year.df$location == site, ]
    this.summary = c(site, year, sum(site.df$cwi))
    hm.summary = rbind(hm.summary, this.summary)
  }
}
hm.summary = hm.summary[2:nrow(hm.summary), ]
write.csv(hm.summary, file = sprintf("%s/hm_summary.csv", base.path), row.names = FALSE)


##### Look at CWI for different years and different scenarios for Kauai/Oahu #####
years = seq(1990,2009)
scenarios = c('', '_rcp45', '_rcp85')
for (year in years){
  for (quarter in c('Q1', 'Q2', 'Q3', 'Q4')){
    for (scenario in scenarios){
      this.quarter = read.csv(sprintf("%s/ok/CWI_estimates_ok%s_%s_%s.csv",base.path, scenario, year, quarter))
      this.quarter$year = year
      this.quarter$scenario = 'present'
      if (scenario != ''){
        this.quarter$scenario = substr(scenario, 2,6)
      }
      if (quarter == 'Q1' & year == min(years) & scenario == ''){
        ok.df = this.quarter
      }else{
        ok.df = rbind(ok.df, this.quarter)
      }
      
    }
  }
}
write.csv(ok.df, file = sprintf("%s/ok_combined.csv", base.path), row.names = FALSE)

# Create annual sums
scenarios = c('present', 'rcp45', 'rcp85')
ok.summary = data.frame(site = NA, year = NA, cwi = NA, scenario = NA)
site = unique(ok.df$location)
for (year in years){
  year.df = ok.df[ok.df$year == year, ]
  for (scenario in scenarios){
    scn.df = year.df[year.df$scenario == scenario, ]

    this.summary = c(site, year, sum(scn.df$cwi, na.rm = TRUE), scenario)
    ok.summary = rbind(ok.summary, this.summary)
  }
}
ok.summary = ok.summary[2:nrow(ok.summary), ]
write.csv(ok.summary, file = sprintf("%s/ok_summary.csv", base.path), row.names = FALSE)

# Quick check for sig. difference
t.test(as.numeric(ok.summary$cwi[ok.summary$scenario == 'present']), as.numeric(ok.summary$cwi[ok.summary$scenario == 'rcp85']))
t.test(as.numeric(ok.summary$cwi[ok.summary$scenario == 'present']), as.numeric(ok.summary$cwi[ok.summary$scenario == 'rcp45']))
# If these are the correct values, there is no significant difference in future cloud water interception (but individual years do seem to vary)
