# RUN-MODEL TEST-CASES  

:exclamation: This folder contains data for testing the run model behavior. It 
is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

Test data for:  

  * Partial controllability matrix update  
  * Transition matrix update  

How to use:  

1. Choose the script you'd like to test. There's a section up top describing what data you'll need to run it.  
2. Load the relevant data from this folder instead of from the **data-downloads** folder. You may also need to define some of the usual constants.  
3. Run the script and compare its behavior to the expected behavior.  

## DIRECTORIES  

- :file_folder: [pc-update](/src/run-model/test-cases/pc-update/)  
Test data for partial controllability matrix update.   

- :file_folder: [transition-update](/src/run-model/test-cases/transition-update/)  
Test data for transition matrix update.  

- :file_folder: [satsifaction-matrices](/src/run-model/test-cases/satsifaction-matrices/)  
Test data for satisfaction matrices update.  

