# Since beginning to analyze the outputs, it has become clear that it's helpful
# to have a repaired version of the priors saved, so that we don't have to
# readjust the sums every time (the calculations put some of them slightly off
# of 1).
#
# This script repairs the priors (transition probabilities AND concentrations)
# once and for all, and saves the result
##
options(stringsAsFactors = FALSE)

# source("./src/comparison-tools/comparison-functions.R") # convertTransitions()
source("./src/run-model/generators/repair-functions.R")
source("./src/general-functions.R") # get the repairSums() function

## --- Read and format elicited priors ------------------------------------------
trans_inits <- read.csv("./src/run-model/initial-inputs/trans_probs_EXPERT-2018-08-13.csv")

# Make sure that it's in standardized order (all transitions out of each state
# grouped together; starting states grouped within management combinations
trans_inits <- trans_inits[order(
  trans_inits$mnt_comb, trans_inits$est_before,
  rev(trans_inits$dens_before),
  trans_inits$est_after,
  rev(trans_inits$dens_after)
), ]

# Before 2020, the transitions table used four columns (est_before,
# dens_before, est_after, dens_after), to describe state transitions. From
# 2020 onward, the table simply uses state_begin and state_end.
# Convert between the two formats.
transitions <- convertTransitions(trans_inits)
transitions <- transitions[order(
  transitions$mnt_comb, transitions$state_begin,
  transitions$state_end
), ]

## you can verify that this worked correctly. The following commands should
#  all give FALSE
##
# any(transitions$mnt_comb != trans_inits$mnt_comb)
# any(transitions$state_begin==1 & trans_inits$est_before !=0.1)
# any(transitions$state_begin==1 & trans_inits$dens_before=="H")
# any(transitions$state_begin==2 & trans_inits$est_before !=0.1)
# any(transitions$state_begin==2 & trans_inits$dens_before=="L")
#
# any(transitions$state_begin==3 & trans_inits$est_before !=0.5)
# any(transitions$state_begin==3 & trans_inits$dens_before=="H")
# any(transitions$state_begin==4 & trans_inits$est_before !=0.5)
# any(transitions$state_begin==4 & trans_inits$dens_before=="L")
#
# any(transitions$state_begin==5 & trans_inits$est_before !=1.0)
# any(transitions$state_begin==5 & trans_inits$dens_before=="H")
# any(transitions$state_begin==6 & trans_inits$est_before !=1.0)
# any(transitions$state_begin==6 & trans_inits$dens_before=="L")
#
# any(transitions$trans_prob != trans_inits$trans_prob) # this will change after the next step
# any(transitions$concentration != trans_inits$concentration)

## --- Repair sums -------------------------------------------------------------

## Transition probabilities
# transitions contains rounding errors that cause some sets of transitions out
# of a single state not to sum to 1. Repair these by distributing the
# discrepancy evenly across all transitions out of that state
trans_by_comb <- split(transitions, transitions$mnt_comb)
row_list <- NULL
for (tbc in trans_by_comb) {
  row_list <- c(row_list, split(tbc, tbc$state_begin))
}

repaired <- NULL
for (r in row_list) {
  repaired <- c(repaired, repairSums(r$trans_prob))
}

## Verify that all rows have been repaired, since repairSums may create its own
#  rounding errors

# Group by row
repaired_rows <- split(repaired, ceiling(seq_along(repaired) / 6))

if (sum((unlist(lapply(repaired_rows, sum)) - 1)) != 0) {
  warning("Repairs Failed")
} else {
  message("Repairs Successful")
}


## For the priors, probability and concentration are the same. Each transition
# probability has support between 0 and 1 inclusive.
transitions$trans_prob <- repaired
transitions$concentration <- repaired


## --- Save Results -------------------------------------------------------------
write.csv(transitions, "./src/run-model/initial-inputs/repaired_priors.csv",
  row.names = FALSE
)
