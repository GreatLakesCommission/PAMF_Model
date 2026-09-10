# CREATE-NEW-RUN TEST-CASES  

Test data for find-monitor-issues.R and find-manage-issues.R.  

:exclamation: This directory contains test cases specific to find-monitor-issues.R and find-manage-issues.R. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

> :memo: NOTE: management test cases are for 2020+ data cleaning only.
      (prior years had different / more complicated relationship between the 
      dates listed on the report)

> :memo: NOTE: in the cases that require comparison between monitoring and management 
      dates, these two data sets interact

> :memo: NOTE: If you make changes to any of the files, Excel may reformat the dates in 
      a way that R doesn't recognize. Before saving, select the date column(s), 
      right click and choose Format Cells, choose Custom at the lower left,
      then under Type, enter yyyy-mm-dd

> :memo: NOTE: This test dataset does not contain the full range of possible phase/date
      agreement situations. Those are explored in more detail in the 
      timing-test-cases directory

## FILES

- cost-test.csv  
A file of incorrect const constants, to verify that all parts of the priceCheck() 
function is working (NOT IN USE).  

- enroll.csv  
Relevant enrollment information (i.e. active/inactive) for each test MU
To update test cases, change enroll.xlsx and export to .csv.

- enroll.csv  
- enroll.xlsx  
Relevant enrollment information (i.e. active/inactive) for each test MU
To update test cases, change enroll.xlsx and export to .csv.  

- manage_issues-NOT-UPDATED.csv  
- manage_issues-NOT-UPDATED.xlsx  
Information supporting the test of management report 55.  

- manage.csv  
- manage.xlsx  
Test management reports and the expected behaviour of find-manage-issues.R
To update test cases, change manage.xlsx and export to .csv.  

- monitor_issues-NOT-UPDATED.csv  
- monitor_issues-NOT-UPDATED.xlsx  
- monitor_issues.csv  
Information supporting the test of monitoring report 24.  

- monitor.csv  
- monitor.xlsx  
Test monitoring reports and the expected behavior of find-monitor-issues.R
To update test cases, change monitor.xlsx and export to .csv  

