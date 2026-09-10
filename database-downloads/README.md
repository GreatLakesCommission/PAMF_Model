This directory is where unmodified downloaded tables from the PAMF Web Hub database, 
organized by year downloaded, should be saved. Folders should be named by year.

View the PAMF Model [User Guide](user-guide/user-guide.md) to find instructions for setting up data files in this folder.  

## FOLDERS  

**Example structure of /database-downloads/:**

- :file_folder: 2018  
	- enroll-[YYYY-MM-DD].csv  
	- manage-[YYYY-MM-DD].csv  
	- managedate-[YYYY-MM-DD].csv  
	- monitor-[YYYY-MM-DD].csv  
- :file_folder: 2019  
	- enroll-[YYYY-MM-DD].csv  
	- manage-[YYYY-MM-DD].csv  
	- managedate-[YYYY-MM-DD].csv  
	- monitor-[YYYY-MM-DD].csv  
- :file_folder: 2020  
	- enroll-[YYYY-MM-DD].csv  
	- manage-[YYYY-MM-DD].csv  
	- managedate-[YYYY-MM-DD].csv  
	- monitor-[YYYY-MM-DD].csv  
- :file_folder: 2021  
	- enroll-[YYYY-MM-DD].csv  
	- manage-[YYYY-MM-DD].csv  
	- managedate-[YYYY-MM-DD].csv  
	- monitor-[YYYY-MM-DD].csv  
	- midcycle-[YYYY-MM-DD].csv*   
- :file_folder: 2022
	- enroll-[YYYY-MM-DD].csv  
	- manage-[YYYY-MM-DD].csv  
	- managedate-[YYYY-MM-DD].csv  
	- monitor-[YYYY-MM-DD].csv  
	- midcycle-[YYYY-MM-DD].csv  
	
*2021 was the first year the "midcycle" CSV was available.  

## FILES  

- [download-data-release.R](/database-downloads/download-data-release.R)   
  This script can be used to help replicate past model runs by downloading and extracting data from the official PAMF data releases on [USGS Sciencebase](https://www.sciencebase.gov/). 
  
> :memo: **For PAMF Staff reference only.**  
> These files do not need to be used by other users of the PAMF Model.  

- [rename-files.R](/database-downloads/rename-files.R)   
   This script can be used as needed before running the PAMF model to rename and reformat CSVs downloaded directly from the PAMF Web Hub (for the August model run).  

- [rename-files-midcycle.R](/database-downloads/rename-files-midcycle.R)   
   This script can be used as needed before running the PAMF model to rename and reformat CSVs downloaded directly from the PAMF Web Hub (for the Mid-Cycle Forecasting Model run).   

