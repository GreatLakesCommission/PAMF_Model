Using monitoring and management reports that were not rejected by either the human
or automated QAQC steps, construct all data packages for the current cycle.  

This process incorporates code that looks for ways to salvage usable data,
including:  

  * Management reports whose reported phase and date disagree   
  * Non-PAMF combinations that are equivalent to PAMF combinations, e.g., GLF,
    GBF, GPR (Substitute between MECHLEAVE, MECHREMOVE, and PRECLEAR)  

    Consequently, the configuration of a data package may not be clear from its 
    monitoring/management reports alone! If something seems off, refer to 
    report-repairs.csv, where these changes are recorded.  


## DIRECTORIES  

- :file_folder: [test-cases](/src/construct-datpaks/test-cases/)  
Data for testing the data package construction behavior. 
When running this set of test cases, make sure that data reads in 
[phase-date-agreement.R](/src/construct-datpaks/phase-date-agreement.R) are commented out! Those pull in a different set of 
cases.  

- :file_folder: [timing-test-cases](/src/construct-datpaks/timing-test-cases/)  
Data for testing [phase-date-agreement.R](/src/construct-datpaks/phase-date-agreement.R) specifically.
(This one gets its own test cases because there's a large set of timing
possibilities).  


## FILES  

- [assemble-datpaks.R](/src/construct-datpaks/assemble-datpaks.R)  
Script that builds data packages for a given cycle. Unifies monitoring, management
information into the form used by the matrix updates.  
Populates the datpaks.csv output.  

- [construct-datpaks.R](/src/construct-datpaks/construct-datpaks.R)  
Controller script that calls [phase-date-agreement.R](/src/construct-datpaks/phase-date-agreement.R), [assemble-datpaks.R](/src/construct-datpaks/assemble-datpaks.R), and 
[find-datpak-issues.R](/src/construct-datpaks/find-datpak-issues.R). This script makes it simple to use the same set of test cases
for the entire process of preparing data packages.   

- [datamod_2018.R](/src/construct-datpaks/datamod_2018.R)  
Reconstructs the manual data cleaning done in 2018.  
Only used when redoing the 2018 model run.  

- [datamod_2019.R](/src/construct-datpaks/datamod_2019.R)  
Reconstructs the manual data cleaning done in 2019.  
Only used when redoing the 2019 model run.  

- [datpak-functions.R](/src/construct-datpaks/datpak-functions.R)  
Functions called by construct-datpaks.R

- [find-datpak-issues.R](/src/construct-datpaks/find-datpak-issues.R)  
Identify issues that make a data package unusable for the transition matrix
and/or partial controllability matrix update.   
Populates the datpak-issues.csv output.  

- [phase-date-agreement.R](/src/construct-datpaks/phase-date-agreement.R)  
Determine which phase each management report belongs to (reports contain two pieces
of information that may conflict).  
Populates the report-repairs.csv output.   
