# Data fir incidents in Cape Town downloaded from site:
#  https://odp-cctegis.opendata.arcgis.com/datasets/fire-incidences


require(readODS)
#Find the file directory to read and write data from the correct subdirectories
filedir <- dirname(rstudioapi::getSourceEditorContext()$path)
###Read in raw data
setwd(paste(filedir,"SourceData",sep="/"))
#2018 incidents
raw_CTFire2018.df <- read_ods("Fire Incidence January - March 2018.ods")
#2017 incidents
zip_file2017 <- "Fire incidence January 2017 to December 2017.zip"
zip_dir2017 <- "Fire incidence January 2017 to December 2017/"
raw_CTFire20171.df <- read_ods(unzip(zip_file2017,paste(zip_dir2017,"Fire incidence January - March 2017.ods",sep = "")))
raw_CTFire20172.df <- read_ods(unzip(zip_file2017,paste(zip_dir2017,"Fire Incidence  April  - June  2017.ods",sep = "")))
raw_CTFire20173.df <- read_ods(unzip(zip_file2017,paste(zip_dir2017,"Fire Incidence July - September 2017.ods",sep = "")))
raw_CTFire20174.df <- read_ods(unzip(zip_file2017,paste(zip_dir2017,"Fire Incidence October - December 2017.ods",sep = "")))
# 2009 to 2016 incidents
zip_file0916 <- "Fire incidence January 2009 to December 2016.zip"
zip_dir0916 <- "Fire incidence January 2009 to December 2016/"
raw_CTFire20161.df <- read_ods(unzip(zip_file0916,paste(zip_dir0916,"Fire incidence Jan 2016 - Mar 2016.ods",sep = "")))
raw_CTFire20162.df <- read_ods(unzip(zip_file0916,paste(zip_dir0916,"Fire Incidence Apr 2016 - Jun 2016.ods",sep = "")))
raw_CTFire20163.df <- read_ods(unzip(zip_file0916,paste(zip_dir0916,"Fire incidence Jul16 - Sep16.ods",sep = "")))
raw_CTFire20164.df <- read_ods(unzip(zip_file0916,paste(zip_dir0916,"Fire incidence October 2016 - December 2016.ods",sep = "")))
raw_CTFire0915.df <- read_ods(unzip(zip_file0916,paste(zip_dir0916,"Fire incidence Jan 2009 - Jan 2016.ods",sep = "")))

###Backup unzipped raw data
setwd(paste(filedir,"RawData",sep="/"))
save(raw_CTFire2018.df,file=("raw_CTFire2018"))
save(raw_CTFire20171.df,file=("raw_CTFire20171"))
save(raw_CTFire20172.df,file=("raw_CTFire20172"))
save(raw_CTFire20173.df,file=("raw_CTFire20173"))
save(raw_CTFire20174.df,file=("raw_CTFire20174"))
save(raw_CTFire20161.df,file=("raw_CTFire20161"))
save(raw_CTFire20162.df,file=("raw_CTFire20162"))
save(raw_CTFire20163.df,file=("raw_CTFire20163"))
save(raw_CTFire20164.df,file=("raw_CTFire20164"))
save(raw_CTFire0915.df,file=("raw_CTFire0915"))


