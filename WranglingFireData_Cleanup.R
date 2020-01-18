################################################
# Data for incidents in Cape Town downloaded from site:
#  https://odp-cctegis.opendata.arcgis.com/datasets/fire-incidences
# Steps:
#  Initial exploration
#  Correct each column:
################################################
# Category 
#  Delete six lines where Category is NA
#  Update similar entries to be the same by setting all to capital
################################################
## Sub Category
# Update entries that are similar to be the same:
# "PEDESTRIAN VEHICLE ACCIDENT (PVA )" :="PEDESTRIAN VEHICLE ACCIDENT (PVA)"
# "RUBBISH", "RUBBISH/GRASS", "RUBBISH/GRASSS/BUSH" :="RUBBISH/GRASS/BUSH"
################################################
# Created Date
#   Only one entry with NA Created date - Created_At must be populated - delete one line
################################################
## Temperature - change factor entries to be consistent using Deg instead of Degrees
################################################
## Resolution - use consistent resolution description
################################################
## Cause - no corrections needed
################################################
## Subcouncil 
#     Where subcouncil is referred to with list of suburbs, pick up the first suburb
#     Then refer to SubCouncils.csv to map to Subcouncil number 
#     Find mapping at: 
#      https://www.capetown.gov.za/Family%20and%20home/Meet-the-City/City-Council/find-your-councillor-ward-or-subcouncil/show-subcouncils
################################################
## District
#     Very small amount is not assigned to a specific district - simplify by taking the first district if more than one is listed
################################################
## Clean up Suburb and Town together as the two relates
################################################
## Suburb - manual entries requires cleanup
## - Correct spelling mistakes - refer to file SuburbsCorrect.csv
################################################
## Town - manual entries requires cleanup
## - Remove special characters "'",".","?","\\"
## - Correct spelling mistakes - refer to file TownsCorrection.csv
## - If Town is NA, get a value usign three steps in order
##      refer most common town the suburb refers to 
##      refer to SubCouncil and find most common town in the SubCouncil
##      set town to Cape Town
## - If a suburb is listed in the Town colunm, replace the Town entry with that suburb's most common town.
##   An entry in the town column is accepted as a Town if it has more than 2000 entries
################################################
## Clean up Suburb based on the most common suburb for a town
## - If the Suburb is listed as NA, update the suburb with the town name
## - If a suburbs is linked to more than one town - associate the suburb with the most common town for that suburb
################################################
## Service_Request and WaterUsage
## Manage duplicates:
##  Duplicate lines have the same service request number
##  Remove duplicate lines, checking that the only difference is the water usage, sum the water usage for the combined line
################################################

#Find the file directory to read and write data from the correct subdirectories
filedir <- dirname(rstudioapi::getSourceEditorContext()$path)
###Set working data directory
setwd(paste(filedir,"WorkingData",sep="/"))

library(dplyr)
library(lubridate)
library(tidyverse)
library(data.table)
library(readxl)

load("FireData")

#################################
# Initial exploration
#################################
# Create DF of column names and their NAs
NACount<-cbind(colnames(FireData.df),colSums(is.na(FireData.df))) #matrix
NACount.df <- as.data.frame(NACount) #data frame
NACount.df[,2] <- as.numeric(as.character(NACount.df[,2])) #change count column to numeric
rm(NACount,NACount.df)

################################################
################################################
# Check data quality and clean up
################################################
################################################
# Category - Delete six lines where Category is NA
################################################
D_NA.df<- FireData.df[is.na(FireData.df$D_Category),] #only 6 entries from October 2016 with NA for Category and Sub Category
# - more analysis shows it is False Alarm & Special Service -> delete
FireData.df <- FireData.df[!is.na(FireData.df$D_Category),] #Remove row where the Category is NA

################################################
# Created Date
# Only one entry with NA Created date - Created_At must be populated - delete one line
################################################
D_NA.df<- FireData.df[is.na(FireData.df$A_CreatedAt),]
FireData.df <- FireData.df[!is.na(FireData.df$A_CreatedAt),] #Remove row where the Category is NA
rm(D_NA.df)

FireData.dt <- as.data.table(FireData.df)

#Delete specific problematic and duplicated line
FireData.dt<-FireData.dt[!(is.na(J_Temperature) & B_Service_Request == "F1510/1620")]
#check the unique entries per column
FDLevels.dt <- FireData.dt[,.(D_Category,E_Sub_Category,F_Suburb,F_Town,G_District,G_SubCouncil,H_Cause,I_Resolution,J_Temperature)]
unique_values <- sapply(FDLevels.dt, unique)

################################################
## Temperature - change factor entries to be consistent using Deg instead of Degrees
################################################
#Temperature <- unique_values$J_Temperature
FireData.dt[J_Temperature=="10 - 15 Degrees", J_Temperature :="10 - 15 Deg"] 
FireData.dt[J_Temperature=="00 - 10 Degrees", J_Temperature :="0 - 10 Deg"] 
FireData.dt[J_Temperature=="15 - 20 Degrees", J_Temperature :="15 - 20 Deg"] 
FireData.dt[J_Temperature=="20 - 25 Degrees", J_Temperature :="20 - 25 Deg"] 
FireData.dt[J_Temperature=="25 - 30 Degrees", J_Temperature :="25 - 30 Deg"] 
FireData.dt[J_Temperature=="26", J_Temperature :="25 - 30 Deg"] 
FireData.dt[J_Temperature=="Over 30 Degrees", J_Temperature :="Over 30 Deg"] 
FireData.dt[is.na(J_Temperature), J_Temperature :="N/A"] 
#table(FireData.dt$J_Temperature,useNA="ifany") #Check pivot

################################################
## Resolution - use consistent resolution description
################################################
#table(FireData.dt$I_Resolution ,useNA="ifany") #Check pivot
FireData.dt[grepl("[Mm]anual",FireData.dt[,I_Resolution]), I_Resolution :="Fire - Manually Extinguished"]
FireData.dt[I_Resolution=="Complete - no further action", I_Resolution :="Complete - No Further Action"]
FireData.dt[I_Resolution=="Fire - automatically extinguished", I_Resolution :="Fire - Automatically Extinguished"]
FireData.dt[is.na(I_Resolution), I_Resolution :="N/A"] 

################################################
## Cause
################################################
#table(FireData.dt$H_Cause ,useNA="ifany") #Check pivot
FireData.dt[is.na(H_Cause), H_Cause :="N/A"] 

################################################
## Subcouncil 
## Where subcouncil is referred to with list of suburbs, pick up the first suburb
## Then refer to SubCouncils.csv to map to Subcouncil number 
## Find mapping at: 
##   https://www.capetown.gov.za/Family%20and%20home/Meet-the-City/City-Council/find-your-councillor-ward-or-subcouncil/show-subcouncils
################################################
FireData.dt$G_SubCouncil <- as.character(lapply(FireData.dt$G_SubCouncil, function(v) {toupper(v)}))
FireData.dt[is.na(G_SubCouncil), G_SubCouncil :="N/A"] 
FireData.dt$G_SubCouncil<-trimws(str_extract(FireData.dt$G_SubCouncil, "[^|]+")) #first entry up to | minus trailing spaces
subCouncils.df <- read.csv("SubCouncils.csv",stringsAsFactors = FALSE,na.strings = "")
for (k in 1:nrow(subCouncils.df))
{
  FireData.dt[G_SubCouncil %in% c(subCouncils.df[k,2]), G_SubCouncil := subCouncils.df[k,1]]
}
rm(subCouncils.df)
FireData.dt[G_SubCouncil=="SUBCOUNCIL 1", G_SubCouncil := "SUBCOUNCIL 01"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 2", G_SubCouncil := "SUBCOUNCIL 02"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 3", G_SubCouncil := "SUBCOUNCIL 03"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 4", G_SubCouncil := "SUBCOUNCIL 04"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 5", G_SubCouncil := "SUBCOUNCIL 05"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 6", G_SubCouncil := "SUBCOUNCIL 06"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 7", G_SubCouncil := "SUBCOUNCIL 07"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 8", G_SubCouncil := "SUBCOUNCIL 08"]
FireData.dt[G_SubCouncil=="SUBCOUNCIL 9", G_SubCouncil := "SUBCOUNCIL 09"]

################################################
## District
## table(FireData.dt$G_District,useNA="ifany", exclude = c("East","South","North","West")) #Check pivot
## Very small amount is not assigned to a specific district - simplify by taking the first district if more than one is listed
################################################
FireData.dt[is.na(G_District), G_District :="N/A"] 
FireData.dt[substr(G_District,1,5)=="North", G_District := "North"]
FireData.dt[substr(G_District,1,5)=="South", G_District := "South"]
FireData.dt[substr(G_District,1,4)=="East", G_District := "East"]
FireData.dt[substr(G_District,1,4)=="West", G_District := "West"]
#table(FireData.dt$G_SubCouncil, FireData.dt$G_District, exclude=c("N/A","NIL - NO RESPONSE","OTHER - SEE REMARKS")) #Check pivot

################################################
## Category
#  Update similar entries to be the same by setting all to capital
################################################
#table(FireData.dt$D_Category, useNA="ifany") #Check pivot
FireData.dt$D_Category <-  as.character(lapply(FireData.dt$D_Category, function(v) {toupper(v)}))

################################################
## Sub Category
# Update entries that are similar to be the same:
# "PEDESTRIAN VEHICLE ACCIDENT (PVA )" :="PEDESTRIAN VEHICLE ACCIDENT (PVA)"
# "RUBBISH", "RUBBISH/GRASS", "RUBBISH/GRASSS/BUSH" :="RUBBISH/GRASS/BUSH"
################################################
#table(FireData.dt$E_Sub_Category ,useNA="ifany") #Check pivot
#FireData.dt[is.na(E_Sub_Category), ] #No NAs
FireData.dt$E_Sub_Category <-  as.character(lapply(FireData.dt$E_Sub_Category, function(v) {toupper(v)}))
FireData.dt[E_Sub_Category=="PEDESTRIAN VEHICLE ACCIDENT (PVA )", E_Sub_Category :="PEDESTRIAN VEHICLE ACCIDENT (PVA)"]
FireData.dt[E_Sub_Category=="RUBBISH", E_Sub_Category :="RUBBISH/GRASS/BUSH"]
FireData.dt[E_Sub_Category=="RUBBISH/GRASS", E_Sub_Category :="RUBBISH/GRASS/BUSH"]
FireData.dt[E_Sub_Category=="RUBBISH/GRASSS/BUSH", E_Sub_Category :="RUBBISH/GRASS/BUSH"]

################################################
################################################
## Clean up Suburb and Town together as the two relates
################################################
## Suburb - manual entries requires cleanup
## - Correct spelling mistakes - refer to file SuburbsCorrect.csv
################################################
# table(FireData.dt$F_Suburb ,useNA="ifany") #Check pivot
FireData.dt[is.na(F_Suburb), F_Suburb :="N/A"] 
FireData.dt[F_Suburb %like% " gccnbc", F_Suburb :="N/A"] #NA the entry "+¦c +¦c gccnbc"
#Change all to upper case
FireData.dt$F_Suburb <-  as.character(lapply(FireData.dt$F_Suburb, function(v) {toupper(v)}))
#Correct entries
## corrections based on file - SuburbsCorrection.csv
burbs.df <- read.csv("SuburbsCorrection.csv",stringsAsFactors = FALSE,na.strings = "")
for (k in 1:nrow(burbs.df))
{
  FireData.dt[F_Suburb %in% c(burbs.df[k,2]), F_Suburb := burbs.df[k,1]]
}

################################################
## Town - manual entries requires cleanup
## - Remove special characters "'",".","?","\\"
## - Correct spelling mistakes - refer to file TownsCorrection.csv
## - If Town is NA, get a value usign three steps in order
##      refer most common town the suburb refers to 
##      refer to SubCouncil and find most common town in the SubCouncil
##      set town to Cape Town
## - If a suburb is listed in the Town colunm, replace the Town entry with that suburb's most common town.
##   An entry in the town column is accepted as a Town if it has more than 2000 entries
################################################
# table(FireData.dt$F_Town ,useNA="ifany") #Check pivot
FireData.dt[is.na(F_Town), F_Town :="N/A"]
FireData.dt[F_Town %in% c("'",".","?","\\"), F_Town :="N/A"]
#Change all to upper case
FireData.dt$F_Town <-  as.character(lapply(FireData.dt$F_Town, function(v) {toupper(v)}))
#Correct spelling mistakes
## corrections based on file - TownsUpdate.csv
towns.df <- read.csv("TownsCorrection.csv",stringsAsFactors = FALSE,na.strings = "")
for (k in 1:nrow(towns.df))
{
  FireData.dt[F_Town %in% c(towns.df[k,2]), F_Town := towns.df[k,1]]
}

## If Town is NA, refer most common town the suburb refers to 
# Seperate out entries where Town is not NA
  FireDataTown.dt <- FireData.dt[F_Town != "N/A",]
  FDSubTownMatch.dt <-FireDataTown.dt[,.(count = .N), by=list(F_Suburb,F_Town)] %>%
    setorder(F_Suburb,-count) #will use these suburb/town matches to find Town matches for unmatched suburbs
  # Seperate out entries where Town is NA
  FireDataNATown.dt <- FireData.dt[F_Town == "N/A",]
  FireDataNATown.dt <- FireDataNATown.dt[,F_Town:=NULL] #remove the Town column
  FireDataNATown.dt <- FDSubTownMatch.dt[FireDataNATown.dt,mult="first",on="F_Suburb",nomatch=NA] #find matches for Suburbs
  FireDataNATown.dt <- FireDataNATown.dt[,count:=NULL] #remove the count column
  #Merge NAs that now has a Town entry and No NAS back together
  setcolorder(FireDataNATown.dt,colnames(FireDataTown.dt)) #Prepare column order to join the two sets again
  FireData.dt<-rbindlist(list(FireDataTown.dt,FireDataNATown.dt))%>%
    setorder() #join the two sets again  
  FireData.dt[is.na(F_Town), F_Town :="N/A"]

## If town is still NA, refer to SubCouncil and find most common town
  FireDataTown.dt <- FireData.dt[F_Town != "N/A",]
  FireDataSC.dt <- FireDataTown.dt[!(G_SubCouncil %in% c('N/A','NIL - NO RESPONSE','OTHER - SEE REMARKS')),] #fire data where Town and SubCouncil has a value
  FDSCTownMatch.dt <-FireDataSC.dt[,.(count = .N), by=list(G_SubCouncil,F_Town)] %>%
    setorder(G_SubCouncil,-count) #will use these suburb/town matches to find Town matches for unmatched suburbs
  ## LOOKUP the SUBCOUNCIL and take the TOWN Match
  FireDataNATown.dt <- FireData.dt[F_Town == "N/A",]
  FireDataNATown.dt <- FireDataNATown.dt[,F_Town:=NULL] #remove the Town column
  FireDataNATown.dt <- FDSCTownMatch.dt[FireDataNATown.dt,mult="first",on="G_SubCouncil",nomatch=NA] #find matches for Sub Council
  FireDataNATown.dt <- FireDataNATown.dt[,count:=NULL] #remove the count column
  #Merge NAs that now has a Town entry and No NAS back together
  setcolorder(FireDataNATown.dt,colnames(FireDataTown.dt)) #Prepare column order to join the two sets again
  FireData.dt<-rbindlist(list(FireDataTown.dt,FireDataNATown.dt))%>%
    setorder() #join the two sets again  
  #If still NA, set town to Cape Town
  FireData.dt <- FireData.dt[is.na(F_Town),F_Town:="CAPE TOWN"] #if town is still NA, copy the Suburb to the Town

#Get rid of suburbs in the Town column  
# If suburb is listed as a Town, set the Town to that suburb's most common town
## Entry is qualified as a Town if it has more than 2000 entries

  FDTowns.dt <-FireData.dt[,.(count = .N), by=list(F_Town)] %>%
    setorder(count) #will use these town matches to find low count Towns 
  FDSubTownMatch.dt <-FireData.dt[,.(count = .N), by=list(F_Suburb,F_Town)] %>%
    setorder(F_Suburb,-count) #will use these suburb/town matches to find Town matches 
  names(FDSubTownMatch.dt) <- c("F_Town","NewTown","count")
  FDSubTownMatch.dt <- FDSubTownMatch.dt[F_Town %in% FDTowns.dt[count<2000,]$F_Town,] #update town where there are less than 5000 entries for that town
  FireDataNewTown.dt <- FDSubTownMatch.dt[FireData.dt,mult="first",on="F_Town",nomatch=NA] #find possible new value for Town
  #Manipulate the set where town was not found in suburb
  FireDataOldTown.dt <- FireDataNewTown.dt[is.na(NewTown),]
  FireDataOldTown.dt <- FireDataOldTown.dt[,':='(count=NULL,NewTown=NULL)] #remove the count and NewTown columns  
  setcolorder(FireDataOldTown.dt,colnames(FireData.dt)) #Reset column order to join 
  #Manipulate the set where town was found in suburb  
  FireDataNewTown.dt <- FireDataNewTown.dt[!(is.na(NewTown)),]
  FireDataNewTown.dt <- FireDataNewTown.dt[,':='(count=NULL,F_Town=NULL)] #remove the count and F_Town columns  
  colnames(FireDataNewTown.dt)[names(FireDataNewTown.dt) == "NewTown"] <- "F_Town"  
  setcolorder(FireDataNewTown.dt,colnames(FireData.dt)) #Reset column order to join 
  #Merge the two back together
  FireData.dt<-rbindlist(list(FireDataNewTown.dt,FireDataOldTown.dt))%>%
    setorder() #join the two sets again 
## If a Town is in the Suburb column, make sure the Town is set to that suburb
  FireData.dt[F_Suburb %in% FireData.dt$F_Town,F_Town:=F_Suburb]
################################################
## Clean up Suburb based on the most common suburb for a town
## - If the Suburb is listed as NA, update the suburb with the town name
## - If a suburbs is linked to more than one town - associate the suburb with the most common town for that suburb
################################################
#If Suburb is NA, update the suburb with the most common suburb for that town
  FireData.dt[F_Suburb =='N/A',F_Suburb:=F_Town]

#If suburbs is linked to more than one town - associate the suburb with the most common town for that suburb
 colNames <- colnames(FireData.dt)
 FDSubTownMatch.dt <-FireData.dt[,.(count = .N), by=list(F_Suburb,F_Town)] %>%
   setorder(F_Suburb,-count) #will use these suburb/town matches to link to the most common town match
 FireData.dt <- FDSubTownMatch.dt[FireData.dt,mult="first",on="F_Suburb",nomatch=NA] #find matches for Suburbs
 
  #Restore column order and remove unecessary join columns
  setcolorder(FireData.dt,colNames) #Restore column order
  FireData.dt <- FireData.dt[,c("i.F_Town","count"):=NULL] #remove the old Town and count columns
  FireData.dt[is.na(F_Town), F_Town :="N/A"]
  
################################################
## Manage duplicates:
##  Duplicate lines have the same service request number
##  Remove duplicate lines, checking that the only difference is the water usage, sum the water usage for the combined line
################################################
FireDataDup <- FireData.dt[B_Service_Request %in% FireData.dt[duplicated(FireData.dt$B_Service_Request),B_Service_Request]]
G2xt <- xtabs(C_WaterUsage~B_Service_Request, FireData.dt) #Only difference between duplicate is in the water usage > sum 
UniqueWater.dt <- as.data.table(G2xt) #Create a data table from resulted sums
names(UniqueWater.dt) <- c("B_Service_Request","C_WaterUsage")
FireData.dt <- FireData.dt[,-c("C_WaterUsage")] #Drop water usage from FireData.dt
FireData.dt <-unique(FireData.dt) #Get unique lines without water usage
FireDataDup <- FireData.dt[B_Service_Request %in% FireData.dt[duplicated(FireData.dt$B_Service_Request),B_Service_Request]] #check that FireDataDup is empty now
FireData.dt <- merge(x=FireData.dt,y=UniqueWater.dt, by="B_Service_Request", all.x=TRUE) #left outer join with summed water usage
setcolorder (FireData.dt, sort(colnames(FireData.dt)))

################################################
## Sort, create factor columns and save data frame
################################################
FireData.dt <- FireData.dt[order(A_CreatedAt,B_Service_Request)]
changeCols <- c("B_Service_Request","D_Category","E_Sub_Category","F_Suburb","F_Town","G_District","G_SubCouncil","H_Cause","I_Resolution","J_Temperature")
FireData.dt[,(changeCols):= lapply(.SD, as.factor), .SDcols = changeCols]

FireDataClean.df <- as.data.frame(FireData.dt)
#Save clean data frame
save(FireDataClean.df,file=("FireDataClean"))

################################################
## Clean up the variables
################################################
rm(unique_values,FDLevels.dt)
rm(FireDataDup,UniqueWater.dt,G2xt)
rm(burbs.df,FDSubTownMatch.dt)
rm(FireDataNATown.dt,FireDataTown.dt,towns.df,k)
rm(FDSCTownMatch.dt,FireDataSC.dt)
rm(FDTowns.dt,FireDataNewTown.dt,FireDataOldTown.dt)
rm(colNames)


