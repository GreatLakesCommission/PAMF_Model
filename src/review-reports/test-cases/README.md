# REVIEW-REPORTS TEST CASES  

:exclamation: This folder contains data for testing the review report construction. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

Files containing fake data defining each test case. These have the same 
structure as the 'real' data inputs, but for readability we've dropped the 
columns that aren't used in this section of the program.  

To verify that things are working properly,  

1. Run generate-issues-report.R with the test section un-commented. This 
   generates a copy of Reports_to_Review.docx in offline-reviews/test-cases. 
   Check the output against the expected_behaviour columns of the monitor/manage
   test inputs and/or Reports_To_ReviewVERIFIED.docx.  
2. Run the PAMF model app with the test section of display-flagged-reports.R 
   uncommented. To do so:  
	* Start a new model run. it doesn't matter which data pull you use
          because the test script will overwrite the data.  
        * If the model crashes before the checkbox window comes up, you can 
          use 'Resolve data issues in an existing model run' to re-try the test.  
	* Compare the display against expected_behaviour columns of the 
          monitor/manage test inputs and/or Reports_To_ReviewVERIFIED.docx.  

## FILES

- **manage_issues.csv**
- **manage_issuesTEST.csv**  
Management issues document to go with the management test reports. Also has 
testnote and expected_behavior columns for reference (machine readable-- don't 
edit this one directly).  

- **manage_issuesTEST.xlsx**  
Management issues document to go with the management test reports. Also has 
testnote and expected_behavior columns for reference. Several columns are linked 
to merged_manageTEST.xlsx (human readable-- edit this one and export to csv).  

- **merged_manageTEST.csv**  
Management reports created to illustrate each test case. For a list of test 
cases and expected behaviours, see the testnote and expected_behavior column.
(human readable-- edit this one and  export to csv).  

- **merged_manageTEST.xlsx**  
Management reports created to illustrate each test case. For a list of test 
cases and expected behaviours, see the testnote and expected_behavior column. 
(human readable-- edit this one and export to csv).  

- **monitor_issues.csv**  
- **monitor_issuesTEST.csv**  
Monitoring issues document to go with the monitoring test reports. Also has 
testnote and expected_behavior columns for reference   
(machine readable-- don't edit this one directly).  

- **monitor_issuesTEST.xlsx**  
Monitoring issues document to go with the monitoring test reports. Also has 
testnote and expected_behavior columns for reference (human readable-- edit this
 one and  export to csv).  

- **monitorTEST.csv**  
Monitoring reports created to illustrate each test case. For a list of test 
cases and expected behaviors, see the testnote and expected_behavior column. 
(machine readable-- don't edit this one directly).  

- **monitorTEST.xlsx**  
Monitoring reports created to illustrate each test case. For a list of test 
cases and expected behaviors, see the testnote and expected_behavior column. 
(human readable-- edit this one and export to csv).  

- **Reports_To_Review_VERIFIED.docx**  
Word document output from RMarkdown, verified by author as the correct output based
on test cases in 2021.  

- **user-input-expectations.docx**  
Lists the expected behaviors of the checkbox interface in response to user input.  

