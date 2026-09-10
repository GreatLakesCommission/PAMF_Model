# Scripts and functions supporting the creation of new model runs  

## DIRECTORIES

- :file_folder: [test-cases](/src/create-new-run/test-cases/)  
Test data for report-level quality checks.  

## FILES

- [create-run-functions.R](/src/create-new-run/create-run-functions.R)  
Functions supporting the run creation scripts

- [find-manage-issues.R](/src/create-new-run/find-manage-issues.R)  
Checks new management reports for quality issues that either (a) need human 
attention in order to be resolved or (b) can be resolved automatically. 
Records all issues and automated decisions.  

- [find-monitor-issues.R](/src/create-new-run/find-monitor-issues.R)  
Checks new monitoring reports for quality issues that either (a) need human 
attention in order to be resolved or (b) can be resolved automatically. 
Records all issues and automated decisions.  

- [review-user-inputs.R](/src/create-new-run/review-user-inputs.R)  
Checks user inputs (previous model run, names of data files, cost constants) for
inconsistencies and possible mistakes. Generates errors/warnings where necessary
and tells the calling script whether to proceed.  