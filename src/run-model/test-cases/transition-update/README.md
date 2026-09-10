# RUN-MODEL TEST-CASES TRANSITION-UPDATE   

:exclamation: This folder contains data for testing the run model behavior. It is not needed for regular running of the PAMF Model, and is only needed for debugging and testing purposes.  

Test data for transition matrix update.  
Other files are pulled in from where they live in the model.  

EXPECTED BEHAVIOR  

* Before the update, the matrix for each managment combination is an identity matrix
          (ones along the diagonal, zeroes elsewhere)  
* After updating it, there are changes to the RRR, IRR and GPF matrices only:  
  * RRR: 0.5 on the diagonal (except for 6,6) and 0.5 just above the diagonal
		     (transitions toward higher states)  
  * IRR: 0.5 on the diagonal (except for 1,1) and 0.5 just below the diagonal
		     (transitions toward lower states)  
  * GPF: In addition to the diagonal, nonzero values in (5,3), (5,4), (6,3), (6,4)  
  * GFF: In addition to the diagonal, nonzero values in (3,1), (3,2), (4,1), (4,2)  

To see the transition matrices in matrix format, use convertTP(). To see concentrations rather than transition probabilities, use the option probs=FALSE.  

## FILES  

- **datpak.csv**  
Test case data packages  

- **datpak-issues.csv**  
Issues file for datpak.csv. munitid column linked to datpak.csv  
Note that only the columns used by the update-transitions.R appear in this file.  

- **trans_probs_init.csv**  
An out-of-order data frame containing probabilities for all state-to-state transitions under each PAMF combination. Each state transitions to itself with probability 1, and to others with probability 0 (i.e., this is a set of identity matrices).  
