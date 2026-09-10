# FORECAST-GUIDANCE TEST-CASES PREVRUN-TEST

This folder contains test versions of the files that forecast-guidance.R needs 
from the previous run in order to generate forecast guidance.

:exclamation: This directory contains test cases specific to mid-cycle forecasts. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

> :warning: **Warning:** Don't make changes to the .csv versions of files in this folder! Instead, edit the .xlsx files and 
re-save to .csv  

## FILES

- datpak.csv  
Datpak file corresponding to the examples in ../midcycle-test.csv
Relevant columns only.
To change this file, edit the corresponding .xlsx file and re-save it as .csv.  

- datpak.xlsx  
Datpak file corresponding to the examples in ../midcycle-test.csv
Relevant columns only. Columns also appearing in midcycle-test are linked to 
the corresponding columns in that file.  

- enroll.csv  
Enrollment reports corresponding to the examples in ../midcycle-test.csv
Relevant columns only.
To change this file, edit the corresponding .xlsx file and re-save it as .csv.  

- enroll.xlsx  
Enrollment reports corresponding to the examples in ../midcycle-test.xlsx
Columns also appearing in midcycle-test are linked to the corresponding columns 
in that file.  

- monitor_issues.csv  
Monitor issues file corresponding to the examples in ../midcycle-test.csv
Relevant columns only.
To change this file, edit the corresponding .xlsx file and re-save it as .csv.  

- monitor_issues.xlsx  
Monitor issues file corresponding to the examples in ../midcycle-test.xlsx
Columns also appearing in midcycle-test are linked to the corresponding
columns in that file.  

- policies.csv  
Test "output of previous model run" describing the optimal management combination
for MUs in a given state and with given management restrictions
To change this file, edit the corresponding .xlsx file and re-save it as .csv.  

- policies.xlsx  
Test "output of previous model run" describing the optimal management combination
for MUs in a given state and with given management restrictions.  

- test case planning notes.txt  
Planning notes for performing MCFG tests.  

- transition_matrices.csv  
Test case transition matrices for all PAMF combinations. These are simplified
and more predictable than the data-driven matrices.
To change this file, edit the corresponding .xlsx file and re-save it as .csv.  

- transition_matrices.xlsx   
Test case transition matrices for all PAMF combinations. These are simplified
and more predictable than the data-driven matrices.
