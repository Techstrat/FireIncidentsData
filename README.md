# Exploring the Fire Incidents for the City of Cape Town

## Business Question

**What are the patterns in fire incidents in the City of Cape Town that could assist in planning capacity to supply water for firefighting?**

## Data Source

The city of Cape Town publishes data on their [Open Data Portal](https://odp-cctegis.opendata.arcgis.com/).  As the site explains:

**The City of Cape Town makes data available that has been approved for use in terms of the Open Data Policy. Access to City information helps to increase transparency, as well as benefit the wider community and other stakeholders.**

To address the business question, we’ve taken the raw data available on [Fire Incidents in the City of Cape Town from January 2009 to March 2018](https://odp-cctegis.opendata.arcgis.com/datasets/fire-incidences).  

## Answer to the business question

The Visualisation report highlights the use of water to respond to fire incidents over time, in different areas of the City of Cape Town, in different classes of fires as well as the relationship between Cause and Resolution of the fires.  

The Visualisation report also highlights issues with the clarity and reliability of the data, with questions for the City of Cape Town on how the incidents were recorded and classified.

## How was this done ? (Wrangling the Data)

First we applied the three steps of data wrangling

------------------------------------------------------------------------------------------------------------------------------------------

### 1.	Obtain the Data

In the Obtain step the zipped [Safety and Security – Fire Incidents](https://odp-cctegis.opendata.arcgis.com/datasets/fire-incidences) source files listed on the City of Cape Town Open Data Portal are downloaded, unzipped and merged into a single raw data file.  

------------------------------------------------------------------------------------------------------------------------------------------

When the City of Cape Town published the data, it was saved in an [ODS format](https://fileinfo.com/extension/ods) and zipped.  

To access the data, the Zipped source files are manually downloaded and unzipped.  Once unzipped, two scripts are applied:

1.	**WranglingFireData_ReadIn.R** in GitHub
    
This is a simple script that reads the ODS files and save them as R objects. It performs no other data manipulation. Reading all the ODS files takes over 2 hours, but once this script is run, the files are accessible for an r-script to read within seconds.
    
2.	**WranglingFireData_Merge.R** in GitHub

The aim of the script is to merge the different sourced files into a single raw data file. 
The script reads the data files saved in R objects.  Before merging the data files is lightly scrubbed, just enough so they can merge into a single file.  

The scrubbing includes:
    
*	Removing blank columns and rows from each file
    
*	Identify similar columns in the files and rename to match
    
*	Removing columns that is not common across the files
    
*	Converting Dates to a format common across the files
    
In the resulting FireData data frame, each incident contains 12 fields that were identified as common to all incidents:

| Field                 | Description                                                        |
| :---------------------| :------------------------------------------------------------------|
| A_CreatedAt           | The date of the incident.  For some incidents it includes the time |
| B_Service_Request     | The service request number                                         |
| C_WaterUsage	        | Liters of water used to resolve the incident                       |
| D_Category            | The category of the incident                                       |
| E_Sub_Category	      | The subcategory of the incident                                    |
| F_Suburb            	| The suburb where the incident occurred                             |
| F_Town              	| The town within the municipality where the incident occurred       |
| G_District          	| District of the fire station that responded                        |
| G_SubCouncil        	| One of 20 City of Cape Town sub councils the incident relates to   |
| H_Cause	              | Cause of the fire                                                  |
| I_Resolution	        | Resolution of the fire                                             |
| J_Temperature       	| The temperature interval for the day of the incident               |

The data is still raw.  

* Some data fields like the creation date have inconsistent formats.

* Manually entered fields like Suburb and Town has many spelling mistakes.

* There are many missing values that are either blank or populated with N/A.  

* The incidents for Q4 2016 did not have Cause and Sub-Council columns and the incidents for Q1 2017 did not have a Sub-Council column.  These columns were added with blank values to allow the joining of all the quarterly files. 

* Some columns have similar but different entries using different combinations of upper- and lower-case letters and abbreviations.

All these issues are addressed in the next step. 

------------------------------------------------------------------------------------------------------------------------------------------

### 2.	Scrub the Data

The scrubbing script (**WranglingFireData_Cleanup.R** in GitHub) is a time-consuming to develop.  Once developed, the script runs in a few seconds.  The script uses logic to determine the correct values, correcting spelling mistakes from correction input files, accepting missing values and discard corrupted entries.  It reads spelling correction and mapping information from three different comma delimited files.  

The Scrub script takes the Raw Data file as input and produces a Tidy Data file.

------------------------------------------------------------------------------------------------------------------------------------------

To get from Raw Data to Tidy Data, the script performs the following tasks :

1.	Align entries where case differs.

2.	Align entries where text is very similar.

3.	Discard the one entry that does not contain a date.

4.	Align the sub council entries (refer to the SubCouncils.csv file and [City of Cape Town list of subcouncils:](https://www.capetown.gov.za/Family%20and%20home/Meet-the-City/City-Council/find-your-councillor-ward-or-subcouncil/show-subcouncils))

Because Suburb and Town were completed manually resulting in many typos, missing data and miss matches, the scrubbing script needs to do several updates to these two columns.

5.	Correct spelling mistakes for Suburbs. (refer to SuburbsCorrect.csv)

6.	Remove special characters and correct spelling mistakes for Towns. (refer to TownsCorrection.csv)

7.	Apply iterative logic to correct and complete the Town and Suburb entries.  It assumes a town is an area that has more than 2000 entries in the original Town column.  All other entries are mapped as Suburbs within a town.  

The output is a tidy data table of over 105 000 incidents recorded over more than 9 years. 

*	The service request number is unique.

*	There are several N/A entries for specific fields (see the graphs in the Exploratory report).

The data formats are standardised

*	The date of the incident is recoded in the A_CreatedAt column as date/time.

*   The Total water used is recorded in the C_WaterUsage column as numeric.

*	The rest of the incident information is recorded in  10 columns as factors.

------------------------------------------------------------------------------------------------------------------------------------------

### 3.	Explore the Data

The exploration script makes no changes to the file. It investigates the quality of the data, identifying weaknesses that will impact the quality of the analysis results.  It recommends how the data can be applied and what to avoid.

The **FireIncidentsDataQuality.Rmd** script takes the Tidy Data file as input and produces the **FireIncidentsDataQuality.html** report.

------------------------------------------------------------------------------------------------------------------------------------------

These are the three data wrangling steps.  The data is now ready to be used as input to further Statistical inference, Regression analysis or Machine learning, most likely combining it with other tidy data files like dam levels or City growth.  

In this case the tidy data is pumped through an Interpretation script. The R script produce a Data Visualisation Report to address the business question.

------------------------------------------------------------------------------------------------------------------------------------------

## How was this done (Interpreting the Data)

Using the advice from the Data Quality Report the Interpretation script is used to read in the tidy data and produce the Data Visualisation report.

Where the Data Quality report looked at the completeness of the data, the Data Visualisation script demonstrate how the relationships in the data can be analised to address the business question.  

The **FireIncidentsDataVisualisation.Rmd** script available in GitHub takes the Tidy Data file as input and produces the **FireIncidentsDataVisualisation.html** report.

------------------------------------------------------------------------------------------------------------------------------------------

*This exercise of Data Wrangling and Data Visualisation was derived from data published on the City of Cape Town data portal without any further input from the City of Cape Town.*

*The analysis was done to demonstrate of the Data Dialect data wrangling framework and not applied for any commercial use.*
