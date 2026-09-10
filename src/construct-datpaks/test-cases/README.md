# Test cases for data package construction  

:exclamation: This folder contains data for testing the data package construction behavior. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

When running this set of test cases, make sure that data reads in 
[phase-date-agreement.R](/src/construct-datpaks/phase-date-agreement.R) are commented out! Those pull in a different set of 
cases.  

> :warning: **Warning:** Don't make changes to the .csv versions of files in this folder! Instead, edit the .xlsx files and 
re-save to .csv  

## FILES  

- **datpak.csv**  
- **datpak_issues.csv**  
- **datpak-2020test.csv**  
Test datpak and issues files.  

- **datpak-NOT-UPDATED.csv**  
- **datpak-NOT-UPDATED.xlsx**  
Test data for prior cycles. Its only purpose is to provide a starting point for
datpak IDs. File name is not labeled with 'test' due to required naming conventions
for files carried over from previous runs  
'NOT-UPDATED' is the naming convention for files that are carried over from previous
model runs and that haven't yet been modified by the current run.  

- **guidance-NOT-UPDATED.csv**  
- **guidance-NOT-UPDATED.xlsx**  
beginning-of-cycle guidance for test cases.  
'NOT-UPDATED' is the naming convention for files that are carried over from previous
model runs and that haven't yet been modified by the current run.  

- **manage_issues.csv**  
- **manage-test-2021.csv**  
- **manage-test-2021.xlsx**  
management data for test cases  

- **manissues-test-2021.csv**  
- **manissues-test-2021.xlsx**  
manage-issues file for test cases  

- **monissues-test-2021.csv**  
- **monissues-test-2021.xlsx**  
monitor-issues file for test cases  

- **monitor-test-2021.csv**  
- **monitor-test-2021.xlsx**  
monitoring data for test cases  

- **report-repairs.csv**  
Testing version of report-repairs.csv  

- **test case key 2021.xlsx**   
Description of all test cases, expected behavior, and a little bit of context  
