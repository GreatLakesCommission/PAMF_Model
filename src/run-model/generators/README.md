# RUN-MODEL GENERATORS  

This directory contains scripts that generate the original versions of several 
model inputs:

## FILES  

- [generate-policy-definitions.R](/src/run-model/generators/generate-policy-definitions.R)  
Codifies which management combinations are available when one or more actions 
is forbidden.  

- [interpolate-satisfaction.R](/src/run-model/generators/interpolate-satisfaction.R)  
Takes in satisfaction data from an expert elicitation exercise conducted in 2017, and estimates 
the mean satisfaction associated with each of the six PAMF states.  

- [interpolate-satisfaction-2023.R](/src/run-model/generators/interpolate-satisfaction-2023.R)  
Takes in satisfaction data from an expert elicitation exercise conducted in 2023, and estimates 
the mean satisfaction associated with transitions between each of the six PAMF states as well as cost level.  

- [interpolate-transitions.R](/src/run-model/generators/interpolate-transitions.R)  
Takes in satisfaction data from an expert elicitation exercise, and estimates 
the transition probability associated with each transition under each management
combination.  

- [make-pc-matrix.R](/src/run-model/generators/make_pc_matrix.R)  
Generates a partial controllability matrix under the assumption that the 
recommended management combination is always carried out.  

- [preference2.jags](/src/run-model/generators/preference2.jags)  
Sampling script that supports the reward matrix interpolation (called in [interpolate-satisfaction.R](/src/run-model/generators/interpolate-satisfaction.R)).  

- [repair-functions.R](/src/run-model/generators/repair-functions.R)  
functions that support repairs to priors.  

- [repair-priors.R](/src/run-model/generators/repair-priors.R)  
Converts the interpolated elicitation document (trans_probs_EXPERT-2018-08-13.csv),
converts it to the format that the model uses, and repairs the transition
probabilities and concentrations that don't sum to 1.  
