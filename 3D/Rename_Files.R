# Needs to be run on Linux computer, will not work on Windows

# Test that script will read through the files correctly
setwd("/media/owner/Elements") 
#setwd("/home/owner")
test_dir = "./hawaii_800m_present_1999/1999"
my.files = list.files(test_dir)
sink(file = "testnames2.txt")
for (a.file in my.files[1:3]){
  print(a.file)
  print(substr(a.file, 1,21))
}
sink()

# Run the renaming process
setwd("/media/owner/Elements") 
test_dir = "./hawaii_800m_present_1999/1999"
setwd(test_dir)
my_files = list.files()
for (a.file in my_files){ file.rename(a.file, substr(a.file, 1,21)) }

#Use ../.. to travel between directories. Ran manually for each year.

#Approach for Kauai/Oahu (check for odd files before running loop!)
setwd("/media/owner/Elements") 
setwd("./kauai_oahu_800m_present_1990-1996")
years = seq(1990,1996)
for(year in years){
  setwd(sprintf('../%s',year))
  my_files = list.files()
  for (a.file in my_files){ file.rename(a.file, substr(a.file, 1,21)) }
}

# Approach for Hawaii/Maui Hard Drive 4
setwd('/media/owner/Elements/hawaii_800m_present_1990-1991/1990')
years = seq(1990,1999)
bits = c("1990-1991", '1990-1991', '1992-1993', '1992-1993', '1994-1995', '1994-1995','1996-1997','1996-1997','1998-1999','1998-1999')
for (i in 1:length(years)){
  year = years[i]
  bit = bits[i]
  setwd(sprintf('../../hawaii_800m_present_%s/%s', bit, year))
  my_files = list.files()
  for(a.file in my_files){ file.rename(a.file, substr(a.file, 1,21)) }
}

#Kauai_oahu rcp85 followed the general approach of above for hard drive 4 – doing all the renaming in one set of nested loops.

#Similar for Kauai_oahu_rcp45

#And similar for hard-drives 6 -10