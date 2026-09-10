# FORECAST-GUIDANCE TEST-CASES PREVRUN-TEST

:exclamation: This directory contains test cases specific to mid-cycle forecasts. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

> :warning: **Warning:** Don't make changes to the .csv versions of files in this folder! Instead, edit the .xlsx files and 
re-save to .csv  


## DIRECTORIES  

- [prevrun-test](/src/forecast-guidance/test-cases/prevrun-test/)  
Test versions of files that MCFG needs from the previous run.  

## FILES  

- dataclean-tests.docx  
This document describes tests on the data cleaning step that occurs between
the file reads and the generation of MCFG. The conditions listed below assume
that all inputs (and combinations of inputs) are fine/valid, aside from the
one(s) specified.  

- file-read-tests.docx  
This document describes tests on the file reading UI & server for midcycle
guidance forecasting.  

- mcfg-tests.docx  
This document describes tests on MCFG generation.  

- midcycle-test.xlsx   
- midcycle-test.csv  
Test data for mid-cycle forecasts. To make changes to the test dataset, edit this
file and save as .csv.   

- midcycle-test2018-08-11.csv  
Test data for mid-cycle forecasts, formatted to be read by the PAMF model software. 
It's labeled with a fake date that's compatible with the fake dates in the file.
Don't edit this one-- instead, make changes to midcycle-test.xlsx and save as .csv.  

- midcycle-test2020-12-31.csv
Test data to verify that the user interface and the MCFG back-end work together 
smoothly. This is a set of fake mid-cycle reports based on real management units with real
monitoring data in 2020.  

HOW TO USE:  

* This file DOES NOT include test cases to check back-end functioning / correctness
  of outputs. For that, see the commented-out test sections in find-midcycle-issues.R
  and forecast-guidance.R  
* to prevent it from interacting with full-cycle sets of management reports, all
  *taken columns are set to zero.  
* to prevent conflicts between the information in the "mcombination" column and 
  the management restrictions given in the enrollment reports, the only values in 
  "mcombination" are 15 (SRS) and 16 (RRR).  

- midcycle-test2525-12-31.csv  
Test data for mid-cycle forecasts, formatted to be read by the PAMF model software. 
It's labeled with a fake date that's compatible with the fake dates in the file.
Don't edit this one-- instead, make changes to midcycle-test.xlsx and save as .csv.  

- pamf combination database key.txt  
Defines database codes for the 16 PAMF combinations (new for 2020-2021 cycle).  





