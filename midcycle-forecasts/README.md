Contains directories that each correspond to a Midcycle Forecast Guidance (MCFG)
run.  

(Looking for an August model run? Check the [model-runs](/model-runs/) folder.)  

View the PAMF Model [User Guide](user-guide/user-guide.md) to find instructions for setting up data files in this folder.  

Since the PAMF Model UI creates a new directory for each MCFG run, it's easy to accumulate 
spurious model runs if you're testing the code. Consequently we've annotated the 
important ones by hand:  
  * OFFICIAL means that this is the model run we used for guidance in that cycle  

Some things to know about these directories...  

- DIRECTORY NAME IS UNIQUE AND GENERATED AUTOMATICALLY by date and time stamp
  Any directory names containing more information (e.g. 'OFFICIAL') were 
  annotated by hand. When you annotate a model run directory name, it's a good 
  idea to go into the directory and write a README file explaining the 
  importance of that run. (It often isn't obvious later!)  

**EACH DIRECTORY CONTAINS THE FOLLOWING FILES:**    

- **Log Files:**  

  - **user-input-log.txt**  
      All user choices that went into creating the model run (e.g., R package versions, cycle years, data tables, cost constants)  

- **Auto-generated Reports:**  

  - **midcycle-issues.csv**  
    All potential issues with each midcycle report throughout the history of this model run and its predecessors. 
    Also contains a record of decisions regarding which problematic reports to withhold from the MCFG run  

- **Annual Outputs:**  

  - **mcfgYYYY.csv**  
    Contains only the current cycle's midcycle forecast guidance.  
    Note to PAMF Staff: This is what goes to the Web Hub team to be displayed to participants.  