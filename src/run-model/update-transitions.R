# Created in summer of 2018
#
# This script updates the transition matrices with the current year's data.
#
# Updates take a Bayesian approach, using Dirichlet distributions.
# Essentially, we count the number of times that each transition is observed,
# adding new counts to the cumulative total every year. We group all counts by 
# their initial state, i.e. each row of each transition matrix. We divide the 
# number of counts in each cell of the row by the row's total counts to get 
# transition probabilities.
#
# PAMF STAFF ONLY: For an interactive example of this approach, see the Excel
# sheets in ../../DOCUMENTATION/development_resources/updating transition
# matrix/
# 
# The updates here are a bit more complicated than those in the demonstration
# because:
#   * We have one transition matrix per management combination (16 total)
#   * Since we have quantifiable uncertainty about stem density, our
#     knowledge of initial/final states is probabilistic. Instead of dropping
#     each observation into a cell of the transition matrix (as we would if we
#     were certain of the initial/final states), we smear it across the possible
#     initial and final states (up to 4 cells).
#
#
# Sourced by: run-the-model.R
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND : the final year of the cycle being analyzed
#
# * Variables
#    datpak        : data packages from the cycle being analyzed
#    datpak_issues : potential issues with data packages belonging to datpak
#    transitions   : up-to-date set of transition matrices (dataframe format)
#
# * Functions
#   From general-functions.R:
#    repairSums
#   From transition-update-functions.R:
#    getTotalPseudocounts
#    getTransProbs
#
# ASSUMPTIONS
##

# # ============================================================================
# #  Uncomment this section for script testing
# # ============================================================================
# message(">>> USING TEST DATA FOR TRANSITION MATRIX UPDATE <<<")
# options(stringsAsFactors=FALSE)
#
# source("./src/global-constants.R")
# source("./src/general-functions.R")
# 
# CYCLEEND = 2018
# datpak = read.csv("./src/run-model/test-cases/transition-update/datpak.csv")
# datpak_issues = read.csv("./src/run-model/test-cases/transition-update/datpak_issues.csv")
# transitions = read.csv("./src/run-model/test-cases/transition-update/trans_probs_init.csv")


# ==============================================================================
#  Get Functions
# ==============================================================================
source("./src/run-model/transition-update-functions.R")

# ==============================================================================
#  Updating the Matrices
# ==============================================================================
## Get transitions observed during current cycle that are not withheld from the 
#  transition matrix update, and sort by PAMF combination
##
datpak_mus = datpak_issues[datpak_issues$cycle_end==CYCLEEND & 
                             !datpak_issues$autoreject_model, "munitid"]
observed   = datpak[datpak$cycle_end==CYCLEEND & datpak$munitid %in% datpak_mus,]
observed   = observed[order(observed$mnt_comb),] 

## Get total observations for all transitions, under each management combination
obs_list = split(observed, observed$mnt_comb)
p_counts = lapply(obs_list, getTotalPseudocounts)


## Add each set of p_counts to the appropriate rows in transitions
#  A for loop is a more natural fit conceptually, but for loops are slow in R.
#  I've designed this loop to iterate only as many times as unique management 
#  combinations were reported-- that's a maximum of 16 but in most years it'll 
#  be fewer.
##
# First, make sure that the rows of transitions are in the standard order
transitions = transitions[order(transitions$mnt_comb, transitions$state_begin, 
                                transitions$state_end),]


for(pc in p_counts){
  mc = unique(pc$mnt_comb) # get management combination
  
  # Add pseudocounts to concentrations for transitions under the mangement 
  # combination mc
  transitions[transitions$mnt_comb==mc, "concentration"] = 
    transitions[transitions$mnt_comb==mc, "concentration"] + pc$pseudocount
  
  # Calculate new transition probabilities based on new concentrations of all 
  # transitions out of each state, and write into transitions
  out_counts = split(transitions[transitions$mnt_comb==mc, "concentration"], 
                          transitions[transitions$mnt_comb==mc,"state_begin"])
  new_probs = lapply(out_counts, getTransProbs)
  new_probs = unlist(new_probs, use.names=FALSE) # turn it into a vector
  
  transitions[transitions$mnt_comb==mc, "trans_prob"] = new_probs
  
} # end for

# now update the cycle_used column
transitions$cycle_used = rep(CYCLEEND, nrow(transitions))

# ==============================================================================
# Clean up temporary variables
# ==============================================================================
suppressWarnings(rm(datpak_mus, observed, obs_list, p_counts, mc, out_counts, 
                    new_probs))
# warnings suppressed because it's possible that p_counts will have no elements.
# in this case, mc, out_counts, and new_probs would not be created