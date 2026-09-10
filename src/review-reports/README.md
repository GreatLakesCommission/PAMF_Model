# REVIEW-REPORTS  

Scripts that find monitoring and management reports with possible issues, and format them for display in either:  
	* a Word document  
	* a Shiny UI that collects checkbox input  

## DIRECTORIES  

- :file_folder: [test-cases](/src/review-reports/test-cases/)  
Test data to verify that the checkbox UI and RMarkdown scripts function as
expected.  

## FILES  

- [checkbox-functions.R](/src/review-reports/checkbox-functions.R)  
Functions supporting the scripts that generate the visual display of flagged 
reports (for both RMarkdown and Shiny UI).  

- [checkbox-modules.R](/src/review-reports/checkbox-modules.R)  
Definitions of modules to display monitoring and management issues, by management unit.  

- [display-flagged-reports.R](/src/review-reports/display-flagged-reports.R)  
Finds and displays reports that have been flagged for screening.  

- [find-unsaved-selections.R](/src/review-reports/find-unsaved-selections.R)  
Find reports without saved selections, for display upon returning to the 
checkbox UI after exiting the app.  

- [generate-issues-report.R](/src/review-reports/generate-issues-report.R)  
A script called by the server function to knit [report.Rmd](/src/review-reports/report.Rmd).  

- [report.Rmd](/src/review-reports/report.Rmd)  
File containg all of the formatting instructions to build "Reports_To_Review.docx".    

- [word-styles-reference.docx](/src/review-reports/word-styles-reference.docx)  
Word document that serves as a style template for "Reports_To_Review.docx". 
Version with default style settings generated using word-styles-reference.Rmd. 
Settings can be changed directly within Microsoft Word, and will be applied to 
maybeSomeIssues.docs the next time you render report.Rmd  

- [word-styles-reference.Rmd](/src/review-reports/word-styles-reference.Rmd)  
Contains formatting for word-styles-reference.docx.  
> :warning: **Warning:** Rendering this file without specifying a file name will overwrite 
word-style-reference.docx with a version that contains the default style 
settings. Any manual changes will be LOST!  