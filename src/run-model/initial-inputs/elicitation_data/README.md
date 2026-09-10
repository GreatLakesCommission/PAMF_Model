# INITIAL-INPUTS ELICITATION DATA

Files containing data collected from experts during expert elicitation exercises, including "Satisfaction" data about how satisfied experts might be with management units (MU) in particular states (used to build the reward matrix for the optimization) and transition probabilities--expert opinions about the likelihood of a MU jumping from one state to any other, given a combination of management actions (used to generate the state-transition model for PAMF's first year). Raw data and examples of the spreadsheets used in these elicitations can be found in the PAMF Data Release (https://doi.org/10.5066/P92NZCYL).    

> :memo: NOTE: The files indicated with a ":globe_with_meridians:" symbol and their associated metadata are present in the PAMF ScienceBase data release. These files are duplicated here as 'convenience copies' for running the model. 

## FILES  

### Satisfaction data  

- **elicited_sat_2017.csv** :globe_with_meridians:    
Expert elicitation satisfaction responses by stem count ("dens" column) and by percent establishment ("est" column). Data were collected in 2017. This is the long form of "preference_2017.csv". See [interpolate-satisfaction.R](/src/run-model/generators/interpolate-satisfaction.R) for details.     

- **elicited_sat_2023.csv** :globe_with_meridians:   
Raw satisfaction responses per participant (expert) by beginning invasion state. Data collected in 2023. See [interpolate-satisfaction-2023.R](/src/run-model/generators/interpolate-satisfaction-2023.R) for details. 

- **preference_2017.csv** 
Combined raw responses to satisfaction elicitation exercise (by stem density and percent establishment). This is the condensed form of "elicited_sat_2017.csv". See [interpolate-satisfaction.R](/src/run-model/generators/interpolate-satisfaction.R) for details. 

### Transition matrix data  

See [interpolate-transitions.R](/src/run-model/generators/interpolate-transitions.R) for details about each of the following files.  

- **prob_dens.csv** :globe_with_meridians:   
Transition probability elicitation data with stem density information expressed as the probability that each elicited transition will end in a low-density or high-density state.  

- **trans_probs_elicitation.csv** :globe_with_meridians:    
Elicitation data (transition probabilities) used as input in the initial interpolation step.  

- **treatment_eff.csv** :globe_with_meridians:   
Treatment effectiveness estimates for each management combination derived from "treatment_eff_herb_raw.csv" and "treatment_eff_postherb_raw.csv".  

- **treatment_eff_treat_raw.csv** :globe_with_meridians:   
Treatment effectiveness elicited data for each type of herbicide and for cut underwater and spading.   

- **treatment_eff_posttreat_raw.csv** :globe_with_meridians:   
Treatment effectiveness elicited data for each type of post-treatment combination.  


