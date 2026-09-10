Contains directories that each correspond to a model run.  

(Looking for a Mid-cycle Forecast Guidance run? Check the [midcycle-forecasts](/midcycle-forecasts/) 
folder.)  

View the PAMF Model [User Guide](user-guide/user-guide.md) to find instructions for setting up data files in this folder.  

Since the PAMF Model UI creates a new directory for each model run, it's easy to accumulate 
spurious model runs if you're testing the code. Consequently we've annotated the 
important ones by hand:  
  * OFFICIAL means that this is the model run we used for guidance in that cycle  
  * BASE means that this is a BASE run (see [Base run](/user-guide/base-runs.md) page for more info)  
  
Some things to know about these directories...  

- DIRECTORY NAME IS UNIQUE AND GENERATED AUTOMATICALLY by date and time stamp
  Any directory names containing more information (e.g. 'OFFICIAL') were 
  annotated by hand. When you annotate a model run directory name, it's a good 
  idea to go into the directory and write a README file explaining the 
  importance of that run. (It often isn't obvious later!)  

**EACH DIRECTORY CONTAINS THE FOLLOWING FILES:**  

- **Log Files:**

  - **user-input-log.txt**  
    All user choices that went into creating the model
    run (cycle years, data tables, cost constants)
    
  - **monitor_issues.csv**  
  All potential issues with each monitoring report throughout the history of 
  this model run and its predecessors. Also contains a record of decisions 
  regarding which problematic reports to withhold from the model  
  
  - **manage_issues.csv**  
    All potential issues with each management report throughout the history of this model run and its predecessors. Also contains a record of decisions regarding which problematic reports to withhold from the model
    
  - **datpak_issues.csv**  
    All potential issues with each data package throughout the history of this model run and its predecessors. Also contains a record of decisions regarding which problematic data packages to withhold from the model
    
  - **report-repairs.csv**  
  All resolutions to phase-date conflicts and swaps between PRECLEAR, MECHLEAVE, and MECHREMOVE throughout the history of this model run and its predecessors.

- **Auto-generated Reports:**
  - **Reports_to_Review.docx**  
  A human-readable version of the information in monitor_issues.csv and manage_issues.csv, for all new reports since the last model run.


- **Cumulative Outputs:**  
  - **datpak.csv**  
  Summary of all data packages (monitoring and management information for one MU in one cycle) ever submitted to the Web Hub
  - **transition_matrices.csv**  
  The entire history of transition probabilities and the weight of evidence behind them
  - **partcontrol_matrices.csv**  
    The entire history of partial controllability probabilities and the  weight of evidence behind them
  - **policies.csv**   
  Optimal and near-optimal management combinations for all combinations of state and management restriction. 
  (48 total: 6 states x 8 combinations of restrictions)
  - **guidance.csv**  
  Optimal and near-optimal recommendations, mapped to each active MU via its state and its management restrictions


- **Annual Outputs:** 
  - **guidance-YYYY.csv**  
  Contains only the current year's guidance.  
  Note to PAMF Staff: This is what goes to the Web Hub team for distribution to participants.

