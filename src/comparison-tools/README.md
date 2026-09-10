# COMPARISON-TOOLS  

Functions that facilitate comparisons between output files.  This is useful in 
testing different versions of model code or model inputs. 

Example: The user wants to test how the Model reacts to an updated model input (e.g., a new cost ranking). The user would run the Model using one cost ranking, then run it again using a different version of the cost ranking, and then the user could use the functions and scripts in this folder to find any differences in the model outputs (i.e., guidance, policies, transition matricies, and partial controllability matrices). Similarly, the user could run the model with only some of the data, then run it again with a different subset of the data, and compare the model outputs with these functions. 

## DIRECTORIES  

- :file_folder: [test-cases](/src/comparison-tools/test-cases/)  
Folder containing test CSVs for use in **model-run-comparisons.R**.  

## FILES  

- [model-run-comparisons.R](/src/comparison-tools/recommend_diffs.R)   
Code that can be used to check for differences in model outputs between different versions of the same model run.    

- [comparison-functions.R](/src/comparison-tools/comparison-functions.R)  
Functions that find differences between output files for transition matrices, 
partial controllability matrices, policies, guidance. Also a function that 
converts between the old and new column configurations for the transition
matrix table.  

- 


