# Data fir incidents in Cape Town downloaded from site:
#  https://odp-cctegis.opendata.arcgis.com/datasets/fire-incidences
####################################################
### Create a joined file with the following columns:
##   A_CreatedAt: Service request date.  For some incidents it includes the time
##   B_Service_Request: Service request number, not necessarily unique
##   C_WaterUsage: Liters of water used.
##   D_Category
##   E_Sub_Category
##   F_Suburb
##   F_Town
##   G_District
##   G_SubCouncil
##   H_Cause
##   I_Resolution
##   J_Temperature
####################################################
### Three groups of files has specific formats
##  GROUP 1: 2009 to September 2016
##  GROUP 2: October 2016 to 2018 data capture in the same format
##    Q4 2016: 
##     ADD EMPTY COLUMN H_Cause
##     ADD EMPTY COLUMN G_SubCouncil
##    Q1 2017: 
##     ADD EMPTY COLUMN G_SubCouncil
##  GROUP 3: October 2017 to 2018 data 
####################################################

library(dplyr)
library(lubridate)
library(tidyverse)
library(data.table)

#Find the file directory to read and write data from the correct subdirectories
filedir <- dirname(rstudioapi::getSourceEditorContext()$path)
###Set raw data directory
setwd(paste(filedir,"RawData",sep="/"))
####################################################
###GROUP 1: 2009 to September 2016 data capture in the same format
####################################################

load("raw_CTFire20161")
load("raw_CTFire20162")
load("raw_CTFire20163")
load("raw_CTFire0915")

#2016 data first 3 quarters
clean_CTFire20161.df <- raw_CTFire20161.df #copy the raw data
clean_CTFire20162.df <- raw_CTFire20162.df #copy the raw data
clean_CTFire20163.df <- raw_CTFire20163.df #copy the raw data
#2009-2015 data
clean_CTFire0915.df <- raw_CTFire0915.df
clean_CTFire0915.df <- clean_CTFire0915.df[,-c(ncol(clean_CTFire0915.df)-1,ncol(clean_CTFire0915.df))] #drop unneccesary columns / rows

## Compare columns
#Compare column names of first data types
cn0915<- colnames(clean_CTFire0915.df)
cn161<- colnames(clean_CTFire20161.df)
cn162<- colnames(clean_CTFire20162.df)
cn163<- colnames(clean_CTFire20163.df)
setdiff(cn162,cn161)
setdiff(cn162,cn163)
setdiff(cn0915,cn161)
setdiff(cn161,cn0915)
#check column types
ct0915<-sapply(clean_CTFire0915.df, class)
ct161<-sapply(clean_CTFire20161.df, class)
ct162<-sapply(clean_CTFire20162.df, class)
ct163<-sapply(clean_CTFire20163.df, class)
setdiff(ct162,ct161)
setdiff(ct162,ct163)
setdiff(ct0915,ct161)
setdiff(ct161,ct0915)

#2016 dfs are the same - merge and them compare with 2009 to 2015
Group1.df <- rbind(clean_CTFire20161.df,clean_CTFire20162.df,clean_CTFire20163.df)#,clean_CTFire0915.df)
#Update column names to be the same
colnames(clean_CTFire0915.df)[names(clean_CTFire0915.df) == "Water Used (Uncharged) MR"] <- "Water Used (Uncharged)MR"
colnames(clean_CTFire0915.df)[names(clean_CTFire0915.df) == "Vehicles - Elapsed TimesMT"] <- "Vehicles - Elapsed Times MT"
colnames(Group1.df)[79] <- colnames(clean_CTFire0915.df)[79]
clean_CTFire0915.df$`Pumping Time Hh:mm MT` <- hm(substr(clean_CTFire0915.df$`Pumping Time Hh:mm MT`,1,5))
Group1.df$`Pumping Time Hh:mm MT` <- hms(Group1.df$`Pumping Time Hh:mm MT`)
#Compare now
ct0915<-sapply(clean_CTFire0915.df, class)
ctG1<-sapply(Group1.df, class)
setdiff(ctG1,ct0915)
setdiff(ct0915,ctG1)
cn0915<- colnames(clean_CTFire0915.df)
cnG1<-colnames(Group1.df)
setdiff(cnG1,cn0915)
setdiff(cn0915,cnG1)
#Ready to join
Group1.df <- rbind(Group1.df,clean_CTFire0915.df)

##Manipulate specific columns
#CreatedAt - combine date and time of incident
Group1.df[is.na(Group1.df$`Time of IncidentMT`),]$`Time of IncidentMT` <- "00:00"#replace NA with 00:00
Group1.df$`Time of IncidentMT` <- substr(Group1.df$`Time of IncidentMT`,1,5)
Group1.df$A_CreatedAt <- dmy_hm(paste(Group1.df$`Date of IncidentD`,Group1.df$`Time of IncidentMT`,tz="Africa/Johannesburg"))
#Sum up Water Usage (Charge and Uncharged)
Group1.df[is.na(Group1.df$`Water Used (Charged)MR`),]$`Water Used (Charged)MR` <- "0"#replace NA with 0
Group1.df$`Water Used (Charged)MR`<-trimws(str_extract(Group1.df$`Water Used (Charged)MR`, "[^|/\\[]+")) #first entry up to | or [ minus trailing spaces
Group1.df$`Water Used (Charged)MR` <- as.numeric(as.character(Group1.df$`Water Used (Charged)MR`))
Group1.df[is.na(Group1.df$`Water Used (Charged)MR`),]$`Water Used (Charged)MR` <- 0 #replace NA with 0
Group1.df[is.na(Group1.df$`Water Used (Uncharged)MR`),]$`Water Used (Uncharged)MR` <- "0"#replace NA with 0
Group1.df$`Water Used (Uncharged)MR` <- as.numeric(as.character(Group1.df$`Water Used (Uncharged)MR`))
Group1.df[is.na(Group1.df$`Water Used (Uncharged)MR`),]$`Water Used (Uncharged)MR` <- 0#replace NA with 0
Group1.df$C_WaterUsage <- Group1.df$`Water Used (Uncharged)MR` + Group1.df$`Water Used (Charged)MR`

#Change column names to match all groups
colnames(Group1.df)[names(Group1.df) == "Incident number"] <- "B_Service_Request"
colnames(Group1.df)[names(Group1.df) == "Incident category"] <- "D_Category"
colnames(Group1.df)[names(Group1.df) == "Incident sub-category"] <- "E_Sub_Category"
colnames(Group1.df)[names(Group1.df) == "Suburb"] <- "F_Suburb"
colnames(Group1.df)[names(Group1.df) == "Town"] <- "F_Town"
colnames(Group1.df)[names(Group1.df) == "District"] <- "G_District"
colnames(Group1.df)[names(Group1.df) == "Station/S Responded"] <- "G_SubCouncil"
colnames(Group1.df)[names(Group1.df) == "FPA Suspected Cause"] <- "H_Cause"
colnames(Group1.df)[names(Group1.df) == "FPA Classification"] <- "I_Resolution"
colnames(Group1.df)[names(Group1.df) == "Temperature"] <- "J_Temperature"

keep <- c("A_CreatedAt","B_Service_Request","C_WaterUsage","D_Category","E_Sub_Category","F_Suburb", 
          "F_Town","G_District", "G_SubCouncil", "H_Cause", "I_Resolution", "J_Temperature")
Group1.df <- Group1.df[,(names(Group1.df) %in% keep)]
Group1.df <- Group1.df[ ,order(names(Group1.df))]

################
rm(ct161,ct162,ct163,cn0915,cn161,cn162,cn163,cnG1,ct0915,ctG1,keep)
rm(clean_CTFire0915.df,clean_CTFire20161.df,clean_CTFire20162.df,clean_CTFire20163.df)
rm(raw_CTFire0915.df,raw_CTFire20161.df,raw_CTFire20162.df,raw_CTFire20163.df)

####################################################
###GROUP 2: October 2016 to 2018 data capture in the same format
### Q4 2016: 
###    ADD EMPTY COLUMN H_Cause
###    ADD EMPTY COLUMN G_SubCouncil
### Q1 2017: 
###    ADD EMPTY COLUMN G_SubCouncil
####################################################
load("raw_CTFire20171")
load("raw_CTFire20172")
load("raw_CTFire20173")
load("raw_CTFire20164")

#CleanUp data

#2016 October - December
clean_CTFire20164.df <- raw_CTFire20164.df #copy the raw data
clean_CTFire20164.df <- clean_CTFire20164.df[-c(1,2),] #drop unneccesary columns / rows
names(clean_CTFire20164.df) <- as.matrix(clean_CTFire20164.df[1, ]) #first row is column names
clean_CTFire20164.df <- clean_CTFire20164.df[-1, ] #remove first row
clean_CTFire20164.df$A_CreatedAt <- mdy_hms(clean_CTFire20164.df$`Created At`,tz="Africa/Johannesburg") # convert date
clean_CTFire20164.df[,'FPA - Details Of Cause'] <-as.character(NA) #ADD EMPTY COLUMN to line up with others in the group
clean_CTFire20164.df[,'Service Request - Sub Council'] <-as.character(NA) #ADD EMPTY COLUMN to line up with others in the group
colnames(clean_CTFire20164.df)[names(clean_CTFire20164.df) == "Responsible Entity - District"] <- "Service Request - Area" #Change column name to line up with other in the group

#2017 January-March
clean_CTFire20171.df <- raw_CTFire20171.df #copy the raw data
clean_CTFire20171.df <- clean_CTFire20171.df[-c(1,2),-c(1)] #drop unneccesary columns / rows
names(clean_CTFire20171.df) <- as.matrix(clean_CTFire20171.df[1, ]) #first row is column names
clean_CTFire20171.df <- clean_CTFire20171.df[-1, ] #remove first row
clean_CTFire20171.df$A_CreatedAt <- ymd_hms(clean_CTFire20171.df$`Created At`,tz="Africa/Johannesburg") #correct date
colnames(clean_CTFire20171.df)[names(clean_CTFire20171.df) == "Responsible Entity - District"] <- "Service Request - Area" #Change column name to line up with other in the group
clean_CTFire20171.df[,'Service Request - Sub Council'] <-as.character(NA) #ADD EMPTY COLUMN to line up with others in the group
#2017 April-June
clean_CTFire20172.df <- raw_CTFire20172.df #copy the raw data
clean_CTFire20172.df <- clean_CTFire20172.df[-c(1,2),-c(1)] #drop unneccesary columns / rows
names(clean_CTFire20172.df) <- as.matrix(clean_CTFire20172.df[1, ]) #first row is column names
clean_CTFire20172.df <- clean_CTFire20172.df[-1, ] #remove first row
clean_CTFire20172.df$A_CreatedAt <- ymd_hms(clean_CTFire20172.df$`Created At`,tz="Africa/Johannesburg") #correct date
#2017 July-September
clean_CTFire20173.df <- raw_CTFire20173.df #copy the raw data
clean_CTFire20173.df <- clean_CTFire20173.df[-c(1,2,3,4),] #drop unneccesary columns / rows
names(clean_CTFire20173.df) <- as.matrix(clean_CTFire20173.df[1, ]) #first row is column names
clean_CTFire20173.df <- clean_CTFire20173.df[-1, ] #remove first row

#Some discriptions fields caused a line break corrupting the rest of the line data
# decision to delete the corrupted data rather than clean it up
clean_CTFire20173.df <- clean_CTFire20173.df[!is.na(clean_CTFire20173.df$Service_Request),] #Remove row where the first column is NA
clean_CTFire20173.df <- clean_CTFire20173.df[substr(clean_CTFire20173.df$Service_Request,1,3)=="300",] #remove lines with invalid SR number
clean_CTFire20173.df$A_CreatedAt <- ymd_hm(clean_CTFire20173.df$`Created At`,tz="Africa/Johannesburg") # convert date

G2_keep <- c("A_CreatedAt","Service_Request","Water Source - Water Used Charged","Water Source - Water Used Un(Quantity)",
             "Temperature","Service Request - Category","Service Request - Area","Service Request - Sub Category","Suburb",
             "FPA - FPA classification:","FPA - Details Of Cause","FPA Comment","Service Request - Sub Council")
clean_CTFire20173.df <- clean_CTFire20173.df[,(names(clean_CTFire20173.df) %in% G2_keep)]
clean_CTFire20172.df <- clean_CTFire20172.df[,(names(clean_CTFire20172.df) %in% G2_keep)]
clean_CTFire20171.df <- clean_CTFire20171.df[,(names(clean_CTFire20171.df) %in% G2_keep)]
clean_CTFire20164.df <- clean_CTFire20164.df[,(names(clean_CTFire20164.df) %in% G2_keep)]

## Compare columns
#Compare column names of first data types
cn20164<- colnames(clean_CTFire20164.df)
cn20171<- colnames(clean_CTFire20171.df)
cn20172<- colnames(clean_CTFire20172.df)
cn20173<- colnames(clean_CTFire20173.df)
setdiff(cn20164,cn20171)
setdiff(cn20171,cn20172)
setdiff(cn20172,cn20173)
#check column types
ct20164<-sapply(clean_CTFire20164.df, class)
ct20171<-sapply(clean_CTFire20171.df, class)
ct20172<-sapply(clean_CTFire20172.df, class)
ct20173<-sapply(clean_CTFire20173.df, class)
setdiff(ct20164,ct20171)
setdiff(ct20171,ct20172)
setdiff(ct20172,ct20173)

#No difference - can join
Group2.df <- rbind(clean_CTFire20164.df,clean_CTFire20171.df,clean_CTFire20172.df,clean_CTFire20173.df)

#Sum up Water Usage (Charge and Uncharged)
Group2.df[is.na(Group2.df$`Water Source - Water Used Charged`),]$`Water Source - Water Used Charged` <- "0"#replace NA with 0
Group2.df$`Water Source - Water Used Charged` <- as.numeric(sub(",", ".", Group2.df$`Water Source - Water Used Charged`, fixed = TRUE))
Group2.df[is.na(Group2.df$`Water Source - Water Used Un(Quantity)`),]$`Water Source - Water Used Un(Quantity)` <- "0"#replace NA with 0
Group2.df$`Water Source - Water Used Un(Quantity)` <- as.numeric(as.character(Group2.df$`Water Source - Water Used Un(Quantity)` ))
Group2.df$C_WaterUsage <- Group2.df$`Water Source - Water Used Charged` + Group2.df$`Water Source - Water Used Un(Quantity)`

#Change column names to match all groups
colnames(Group2.df)[names(Group2.df) == "Service_Request"] <- "B_Service_Request"
colnames(Group2.df)[names(Group2.df) == "Service Request - Category"] <- "D_Category"
colnames(Group2.df)[names(Group2.df) == "Service Request - Sub Category"] <- "E_Sub_Category"
colnames(Group2.df)[names(Group2.df) == "Suburb"] <- "F_Suburb"
colnames(Group2.df)[names(Group2.df) == "Service Request - Area"] <- "G_District"
colnames(Group2.df)[names(Group2.df) == "Service Request - Sub Council"] <- "G_SubCouncil"
colnames(Group2.df)[names(Group2.df) == "FPA - Details Of Cause"] <- "H_Cause"
colnames(Group2.df)[names(Group2.df) == "FPA - FPA classification:"] <- "I_Resolution"
colnames(Group2.df)[names(Group2.df) == "Temperature"] <- "J_Temperature"

keep <- c("A_CreatedAt","B_Service_Request","C_WaterUsage","D_Category","E_Sub_Category","F_Suburb", 
          "F_Town","G_District", "G_SubCouncil","H_Cause", "I_Resolution", "J_Temperature")
Group2.df["F_Town"] <- NA 
Group2.df <- Group2.df[,(names(Group2.df) %in% keep)]
Group2.df <- Group2.df[ ,order(names(Group2.df))]

rm(cn20164,cn20171,cn20172,cn20173,ct20164,ct20171,ct20172,ct20173,keep,G2_keep)
rm(clean_CTFire20164.df,clean_CTFire20171.df,clean_CTFire20172.df,clean_CTFire20173.df)
rm(raw_CTFire20164.df,raw_CTFire20171.df,raw_CTFire20172.df,raw_CTFire20173.df)

####################################################
###GROUP 3: October 2017 to 2018 data capture in the same format
####################################################
load("raw_CTFire2018")
load("raw_CTFire20174")

#CleanUp data
#2018 data
clean_CTFire2018.df <- raw_CTFire2018.df #copy the raw data
# #inspect data
# View(clean_CTFire2018.df)
# head(clean_CTFire2018.df)
# tail(clean_CTFire2018.df)
# str(clean_CTFire2018.df)
clean_CTFire2018.df <- clean_CTFire2018.df[-c(1,2,3,4,nrow(clean_CTFire2018.df)),-c(1)] #drop unneccesary columns / rows
names(clean_CTFire2018.df) <- as.matrix(clean_CTFire2018.df[1, ]) #first row is column names
clean_CTFire2018.df <- clean_CTFire2018.df[-1, ] #remove first row

#2017 October-December
clean_CTFire20174.df <- raw_CTFire20174.df #copy the raw data
clean_CTFire20174.df <- clean_CTFire20174.df[-c(1,2,3,4,nrow(clean_CTFire20174.df)),-c(1)] #drop unneccesary columns / rows
names(clean_CTFire20174.df) <- as.matrix(clean_CTFire20174.df[1, ]) #first row is column names
clean_CTFire20174.df <- clean_CTFire20174.df[-1, ] #remove first row

## Compare columns
#Compare column names of first data types
cn20174<- colnames(clean_CTFire20174.df)
cn2018<- colnames(clean_CTFire2018.df)
setdiff(cn2018,cn20174)
setdiff(cn20174,cn2018)
#check column types
ct20174<-sapply(clean_CTFire20174.df, class)
ct2018<-sapply(clean_CTFire2018.df, class)
setdiff(ct2018,ct20174)
setdiff(ct20174,ct2018)

#No difference - can join
Group3.df <- rbind(clean_CTFire20174.df,clean_CTFire2018.df)
#Creation date
Group3.df$A_CreatedAt <- ymd_h(paste(Group3.df$`Sr Posting Date 1`,"14"),tz="Africa/Johannesburg") #correct date
#Sum up Water Usage (Charge and Uncharged)
Group3.df[is.na(Group3.df$WaterCharged),]$WaterCharged <- "0"#replace NA with 0
Group3.df$WaterCharged <- as.numeric(as.character(Group3.df$WaterCharged))
Group3.df[is.na(Group3.df$WaterNotCharged ),]$WaterNotCharged  <- "0"#replace NA with 0
Group3.df$WaterNotCharged <- as.numeric(as.character(Group3.df$WaterNotCharged ))
Group3.df$C_WaterUsage <- Group3.df$WaterNotCharged + Group3.df$WaterCharged

#Change column names to match all groups
colnames(Group3.df)[names(Group3.df) == "Service Request"] <- "B_Service_Request"
colnames(Group3.df)[names(Group3.df) == "Sr Category"] <- "D_Category"
colnames(Group3.df)[names(Group3.df) == "Sr Sub Category"] <- "E_Sub_Category"
colnames(Group3.df)[names(Group3.df) == "Sr Suburb Town"] <- "F_Suburb"
colnames(Group3.df)[names(Group3.df) == "Sr Area"] <- "G_District"
colnames(Group3.df)[names(Group3.df) == "Sr Sub Council"] <- "G_SubCouncil"
colnames(Group3.df)[names(Group3.df) == "FPA Cause"] <- "H_Cause"
colnames(Group3.df)[names(Group3.df) == "Text Resolution"] <- "I_Resolution"
colnames(Group3.df)[names(Group3.df) == "Temperature"] <- "J_Temperature"
Group3.df["F_Town"] <- NA 

keep <- c("A_CreatedAt","B_Service_Request","C_WaterUsage","D_Category","E_Sub_Category","F_Suburb", 
          "F_Town","G_District", "G_SubCouncil","H_Cause", "I_Resolution", "J_Temperature")
Group3.df <- Group3.df[,(names(Group3.df) %in% keep)]
Group3.df <- Group3.df[ ,order(names(Group3.df))]

rm(cn20174,cn2018,ct20174,ct2018,keep)
rm(clean_CTFire20174.df,clean_CTFire2018.df)
rm(raw_CTFire20174.df,raw_CTFire2018.df)

#############################################################
### Compare 3 groups, Join and Investigate full DB 
#############################################################

## Compare columns
#Compare column names 
cnG1<- colnames(Group1.df)
cnG2<- colnames(Group2.df)
cnG3<- colnames(Group3.df)
setdiff(cnG1,cnG2)
setdiff(cnG2,cnG1)
setdiff(cnG1,cnG3)
setdiff(cnG3,cnG1)
setdiff(cnG3,cnG2)
setdiff(cnG2,cnG3)
#Compare column types
ctG1<-sapply(Group1.df, class)
ctG2<-sapply(Group2.df, class)
ctG3<-sapply(Group3.df, class)
setdiff(ctG1,ctG2)
setdiff(ctG2,ctG1)
setdiff(ctG1,ctG3)
setdiff(ctG3,ctG1)
setdiff(ctG3,ctG2)
setdiff(ctG2,ctG3)

rm(cnG1,cnG2,cnG3,ctG1,ctG2,ctG3)

#No more differences - join
FireData.df <- rbind(Group1.df,Group2.df,Group3.df)
rm(Group1.df,Group2.df,Group3.df)

###Set working data directory and save
setwd(paste(filedir,"WorkingData",sep="/"))
save(FireData.df,file=("FireData"))
