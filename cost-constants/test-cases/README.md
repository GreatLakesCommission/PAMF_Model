This directory contains cost constant test files. These files exist to test the
error checking code that is applied when the program reads the cost constant
data. To test, run the app, select each of these files in the menu and verify
that the behavior is as expected.  

## FILES  

- **cost_constants_ColumnTest1.csv**   
cost constants file with incorrect name replacing "type"  
Expected behavior: "Error: Incorrect cost constant file"

- **cost_constants_ColumnTest2.csv**  
cost constants file with incorrect name replacing "name"  
Expected behavior: "Error: Incorrect cost constant file"  

- **cost_constants_ColumnTest3.csv**  
cost constants file with incorrect name replacing "unit"  
Expected behavior: "Error: Incorrect cost constant file"  
 
- **cost_constants_ColumnTest4.csv**  
cost constants file with incorrect name replacing "cost_per_unit"  
Expected behavior: "Error: Incorrect cost constant file"  

- **cost_constants_ColumnTest5.csv**  
cost constants file with incorrect name replacing "herb_code"  
Expected behavior: "Error: Incorrect cost constant file"  

- **cost_constants_ColumnTest6.csv**  
cost constants file with incorrect name replacing "cost_year"  
Expected behavior: "Error: Incorrect cost constant file"  

- **cost_constants_ColumnTest7.csv**  
cost constants file with an extra column.  
Expected behavior: "Program accepts the file as one with valid columns"  

- **cost_constants_OldCosts.csv**  
cost constants file with cost estimates from a previous year  
Expected behavior: "Warning: Cost constants at least one year old"  

- **cost_constants_FutureCosts.csv**  
cost constants file with cost estimates from a future year  
Expected behavior: "Warning: Cost constants created after end of cycle to be
analyzed"  

- **cost_constants_MultiYear.csv**  
cost constants file with cost estimates from more than one year  
Expected behavior: "Warning: cost constants are from multiple years"
(note that this doesn't trigger the past/future year warnings. This
is okay because any set of multiple years will involve at least one past and/or
future year)  
