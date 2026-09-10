# COST-ESTIMATES TEST-CASES  

:exclamation: This folder contains data for testing the cost calculation behavior. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

To run test, follow the instructions in [calculate-costs.R](/src/cost-estimates/calculate-costs.R).  
Note that the expected behaviors are embedded in the test data.  

> :warning: **Warning:** Don't make changes to the .csv versions of files in this folder! Instead, edit the .xlsx files and 
re-save to .csv  

## FILES

- man-issues-for-cost-test.csv  
The equivalent of the manage_issues file for these test cases, with the relevant columns and some notes. To make changes,
update the .xlsx file and re-save to .csv.  

- man-issues-for-cost-test.xlsx  
The equivalent of the manage_issues file for these test cases, with the relevant columns and some notes. Several of
the columns are linked to columns of test-data-for-costs.xlsx.  

- test-constants-for-costs.csv  
Cost constants for testing. Labor and fuel costs are simplified, while herbicide costs are taken from the 2018
data (except surfactant, which was added in 2023 and is a test number). To make changes, update the .xlsx file and re-save to .csv.  

- test-constants-for-costs.xlsx  
Cost constants for testing. Labor and fuel costs are simplified, while herbicide costs are taken from the 2018
data.  

- test-data-for-costs.csv  
Test data illustrating different situations that the cost calculations should (and should not) handle.
To make changes, update the .xlsx file and re-save to .csv.  

- test-data-for-costs.xlsx  
Test data illustrating different situations that the cost calculations should (and should not) handle.
To make changes, update the .xlsx file and re-save to .csv.  

- [tests-for-cost-calc-functions.R](/src/cost-estimates/test-cases/tests-for-cost-calc-functions.R)   
A set of test cases demonstrating the the cost calculation functions.  
