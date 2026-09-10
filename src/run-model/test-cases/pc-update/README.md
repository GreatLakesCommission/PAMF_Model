# RUN-MODEL TEST-CASES PC-UPDATE  

:exclamation: This folder contains data for testing the run model behavior. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

Fabricated inputs that are formatted in the same way as the cleaned PAMF data but that show clearer patterns.  

>:memo: NOTE: Only the relevant columns of each file are included.  

This data set has the following features:  

- MUs 1-16: Each PAMF combination was recommended and implemented  
	(these update the matrix diagonal once, except for the [OTHER,OTHER] cell
         If they update the diagonal twice, then the script is incorporating near-optimal guidance in addition to optimal guidance)  
- MUs 17-32 : Each PAMF combination except GRG implemented, while GRG was recommended
	(17-13 update the GRG row; 32 does not, due to lack of PAMF combination)  
- MUs 33-38: Incomplete management combination; SRS was recommended
	(these do not update the matrix, due to lack of PAMF combination)  
- MU 39: From another cycle (should NOT update [CRC, CRC])  
- MU 40: has no guidance from previous cycle (should NOT udpate [RRR, RRR])  

Also...
**DON'T OPEN THE .csv FILES IN EXCEL!**   

Opening the .csv files in Excel reassigns all dates to the default date format. This will break the script because R (and therefore the script)does not recognize Excel's default date format as a date! Admittedly, I don't know if this occurs on versions other than the ones on my Windows 10 machine. So the fixes I outline below could apply only to Windows 10; your mileage may vary.  

Ways around this problem:  

- (THE BEST WAY) Don't open the .csv files in Excel.
    You can prevent this from happening accidentally by right-clicking on the file's icon and going opening
    the "Open with" menu. Click "Choose another app". Choose Notepad and check the box that says 
    "Always use this app to open .csv files".  
- If you opened the .csv file in Excel, highlight all date cells, and right click.
    Choose "Format Cells..." from the menu
    Choose "Custom" from the bottom of the list on the left.
    In the text field of the main box, type yyyy-mm-dd
    Close out & never open .csv files in Excel again :) 

## FILES  

- **datpak.csv**  
Data packages- R readable  

- **datpak.xlsx**  
Data packages.  

- **datpak_issues.xlsx**  
Data package issues  
The only relevant column is autoreject_partcontrol  
MU IDs, year, test_notes are linked to datpak.xlsx  

- **datpak_issues.csv**  
Data package issues- R readable  
The only relevant column is autoreject_partcontrol  

- **guidance.csv**  
Management guidance issued at the beginning of the PAMF cycle- R readable  

- **guidance.xlsx**  
Management guidance issued at the beginning of the PAMF cycle.
MU IDs, year, test_notes are linked to datpak.xlsx  

- **pc_initial_table.csv**  
An empty partial controllability matrix with probabilities=concentrations=0 and 
all possible intended/implemented combinations  
