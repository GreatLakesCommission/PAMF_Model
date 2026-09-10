# Code used to generate Mid-Cycle Forecast Guidance  

## DIRECTORIES  

- [test-cases](/src/forecast-guidance/test-cases/)  
Holds data that used to test the mid-cycle guidance inputs/calculations before 
the first mid-cycle database pull.  

## FILES  

- [find-midcycle-issues.R](/src/forecast-guidance/find-midcycle-issues.R)   
Finds and records any issues that may disqualify each MU from MCFG.   

- [forecast-guidance.R](/src/forecast-guidance/forecast-guidance.R)   
Script that generates MCFG.  

- [midcycle-functions.R](/src/forecast-guidance/midcycle-functions.R)  
Functions that support midcycle data cleaning and guidance forecast.  

- [review-midcycle-inputs.R](/src/forecast-guidance/review-midcycle-inputs.R)  
Checks user inputs (previous model run, names of data files) for inconsistencies and possible mistakes.
Generates errors/warnings where necessary and tells the calling script whether to proceed.  
