# 2020-08-12
#
# This script executes "the model run", i.e. what we mean when we talk
# colloquially about "running the model":
#   * Transition matrix updates
#   * Estimate management costs
#   * Build reward matrix
#   * Update partial controllability matrix
#   * Find optimal and near-optimal policies
#   * Map policies onto individual MUs (i.e. produce guidance)
#
# Because this amounts to quite a bit of code, each of these pieces takes place
# in its own script. Many of these have a commented-out section that reads test
# data. To verify that they work as expected, uncomment that section, run the
# script in isolation, and compare the outputs to the expectations.
#
# This script also generates snippets of UI that update the user on the model's
# progress.
#
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global Constants
#     CYCLEEND   : The the second/final year in the cycle being analyzed
#     RUNPATH    : The location of the model run directory
#     STATES     : definitions of the PAMF invasion states
#     PAMF_COMBS : Data frame that maps between management actions and managment
#                  combinations
#     DISCOUNT   : The discounting factor (describes how urgent it is to clear
#                  Phragmites)
#     RESPATH    : Path to location of policy_definitions2018-07-31.csv
#
# * Variables
#     append        : Logical value denoting whether to append outputs to an
#                     existing cumulative file
#     datpak        : data packages from the cycle being analyzed
#     datpak_issues : potential issues with data packages belonging to datpak
#
# * Functions
#   From general-functions.R:
#     writeOutput
#   From file-io-special-cases.R:
#     readPreviousOutputs
#     readTransitions2018
#     readPreUpdateGuidance
#     readPCmatrix2018
#     writePreUpdateGuidance
#
# * Files in RUNPATH (when running with CYCLEEND==2019 or later)
#    transition_matrices.csv
#    cost_estimates.csv
#    guidance.csv (if running base runs after 2018, from the OFFICIAL runs must
#    also be included)
#
#
# ASSUMPTIONS
# * default stringsAsFactors value has already been set to FALSE
# * source code directory structure has not changed since this script was
#   last updated
##

## The matrix updates depend upon past outputs. The way that we pull those files
#  in depends upon:
#   * the type of output
#   * the year they were generated
#  file-io-special-cases.R gathers all of this variation in one place
##
source("./src/run-model/file-io-special-cases.R")

# Display progress status
insertUI("#matrix_update",
  ui = wellPanel(h5(strong("Updating matrices..."))),
  immediate = TRUE
)

# Update Transition Matrices ---------------------------------------------------
#
#   * Get the previous run's transition matrices (or the expert-elicited
#     prior if CYCLEEND is 2018)
#   * Incorporate data from datpak and re-calculate transition probabilities
#
# Regardless of CYCLEEND, the code below produces the following variable:
#   * transitions : A data frame where each row describes the probability
#                   of a single transition (state to state, under a given
#                   management combination), and the total observations
#                   supporting it

message("updating transition matrices...")

# Get the transition matrices to be updated
if (CYCLEEND > 2018) {
  transitions <- readPreviousOutputs("transition_matrices", CYCLEEND, RUNPATH)
} else {
  transitions <- readTransitions2018()
}

## Update transition matrices
#  This script modifies the transitions variable
##

# oldtransitions<<-transitions # uncomment to make visible after app exits
source("./src/run-model/update-transitions.R", local = TRUE)
# transitions<<-transitions # uncomment to make visible after app exits
writeOutput(transitions, "transition_matrices", RUNPATH, append)

#  Calculate Management Costs --------------------------------------------------
#
#  Build a new empty cost file (2018, first run) or calculate management
#  costs and append to the existing file (2019 onward)

message("calculating management costs...")

if (CYCLEEND == 2018) {
  # First model run, no costs reported. But we'll need something to update from
  # in subsequent years.
  current_costs <- data.frame(
    treatmentid = numeric(0), munitid = numeric(0),
    treatmethod = numeric(0), contract = logical(0),
    rent = logical(0), total_cost = numeric(0),
    cost_per_acre = numeric(0), pamf_cycle = numeric(0)
  )
} else {
  #  Calculate costs for new reports since the last calculation
  #  This script creates the following variable:
  #  current_costs : estimated costs (total & per_acre) for each management
  #                  report that contains cost data for actions other than REST,
  #                  OTHER

  source("./src/cost-estimates/cost-calculation-functions.R") # the cost estimation equations
  source("./src/cost-estimates/cost-helper-functions.R") # functions that support cost calculations
  source("./src/cost-estimates/calculate-costs.R", local = TRUE)
}
writeOutput(current_costs, "cost_estimates", RUNPATH, append)
rm(current_costs) # not used for the rest of the model run (we don't have enough
# information to produce a full ranking as of 2020)

#  Build Reward Matrix ---------------------------------------------------------
#
# The reward matrix quantifies tradeoffs between:
#   (a) the quality of (or satisfaction with) a state, and
#   (b) the cost of the action that led to that state.
#
# Satisfaction values are from a one-time expert elicitation (2017);
# costs are updated intermittently
#
# Cost values are currently (as of 2020) expressed as an a prior ranking based
# on how much effort we expect each combination to take, e.g. GPF requires more
# effort than GRR, which requires more effort than RRR. Hopefully we can
# refine these soon, using the cost data!
#
# The code below produces the following variable:
#   * reward_matrix : Satisfaction/cost balanced values for each invasion
#                     state and management combination (matrix)

source("./src/run-model/optimizer-functions.R")
source("./src/run-model/build-reward-matrix.R", local = TRUE)
# reward_matrix<<-reward_matrix # uncomment to make visible after app exits

# Update Partial Controllability Matrix ----------------------------------------
#
# The partial controllability matrix keeps track of participants' tendency to
# carry out management combination X after receiving guidance recommending
# combination Y. When participants follow guidance, X==Y.
#
# Regardless of CYCLEEND, the code below produces the following variable:
#   * pc_matrix : up-to-date partial controllability matrix (matrix format)
#                 to be used in the optimization
#   * pc_table  : up-to-date partial controllability matrix (table format)
#                 to be appended to pc history and saved for next year's update

message("updating partial controllability matrix...")

## First, get the previous partial controllability matrix and the previous
#  guidance.
##
if (CYCLEEND > 2018) {
  
  # Get the previous cycle's partial controllability matrix
  prev_pc <- readPreviousOutputs(
    "partcontrol_matrices",
    CYCLEEND,
    RUNPATH
  )
  
  # To update the partial controllability matrix, compare observed
  # management with guidance from the previous cycle.
  #
  # For cycles covered by GUIDANCE_FILES, use the official guidance
  # that participants actually saw. After that, use the cumulative
  # guidance history.
  
  last_base_year <- max(as.integer(names(GUIDANCE_FILES)))
  
  if ((CYCLEEND - 1) <= last_base_year) {
    
    print("run-the-model.R - Base run detected - Using previous year's OFFICIAL guidance to update the partial controllability matrix")
    
    prev_file <- GUIDANCE_FILES[as.character(CYCLEEND - 1)]
    
    if (is.na(prev_file)) {
      stop(
        "WARNING: No guidance file defined for cycle ",
        CYCLEEND - 1
      )
    }
    
    prev_guidance <- readPreUpdateGuidance(
      prev_file,
      CYCLEEND,
      RUNPATH
    )
    
  } else {
    print("run-the-model.R - Using previous year's guidance to update the partial controllability matrix")
    
    prev_guidance <- readPreviousOutputs(
      "guidance",
      CYCLEEND,
      RUNPATH
    )
    
  }
  
  # Run the partial controllability update script
  source("./src/run-model/pc-update-functions.R")
  source("./src/run-model/update-pc.R", local = TRUE)
  
  # Write the partial controllability table to file
  writeOutput(
    pc_table,
    "partcontrol_matrices",
    RUNPATH,
    append
  )
  
  # pc_table <<- pc_table # uncomment to make visible after app exits
  
  # Clean up
  rm(prev_pc, prev_guidance, pc_table)
  
} else {
  
  # It's 2018, the first model run!
  # Get initial partial controllability matrix and save its table
  # format to RUNPATH for updating next year.
  pc_matrix <- readPCmatrix2018()
  
}
# pc_matrix<<-pc_matrix # uncomment to make visible after app exits

# Run Optimizations ------------------------------------------------------------
#
# Find optimal and near-optimal managmenent combinations for every state and
# every category/combination of management restrictions (no herbicide, no cut
# underwater, no flood)
#
# Thie code below produced the follwing variable:
#   * opnop_actions : Optimal and near-optimal management combinations
#     (data frame)

message("finding optimal guidance...")

# Display progress status
insertUI("#guidance_update",
  ui = wellPanel(h5(strong("Generating guidance..."))),
  immediate = TRUE
)

# Get functions and files used to find optimal, near-optimal management
# combinations
source("./src/run-model/suboptimal-functions.R")
action_restrictions <- read.csv(RESPATH)

# Run optimizer script and write output
source("./src/run-model/optimizer.R", local = TRUE)
writeOutput(opnop_actions, "policies", RUNPATH, append)

# opnop_actions<<-opnop_actions # uncomment to make visible after app exits

# Assign Guidance to MUs -------------------------------------------------------
#
# The optimization step finds the optimal management combination for each state.
# Now find optimal and near-optimal combinations for each MU
#
# This script creates the following variables:
#  * guidance : Optimal and near-optimal management combinations for
#               each MU

message("assigning guidance to MUs...")

source("./src/run-model/policy2guidance.R", local = TRUE)

last_base_year <- max(as.integer(names(GUIDANCE_FILES)))

if (CYCLEEND == 2018 || CYCLEEND > last_base_year + 1) {
  # 2018  : no previous guidance to incorporate
  # Beyond the last base-run year: the correct guidance history is already cumulative and is in guidance-NOT-UPDATED.csv
  writeOutput(guidance, "guidance", RUNPATH, append) # cumulative
  writeOutput(guidance, paste0("guidance-", CYCLEEND), RUNPATH) # current year only
} else {
  # Base-run years: Incorporate the actual released guidance into the guidance
  # history. This is often NOT the same as the guidance generated by a base run
  writePreUpdateGuidance(guidance, CYCLEEND, RUNPATH)
  writeOutput(guidance, paste0("guidance-", CYCLEEND), RUNPATH) # current year only
}

rm(last_base_year)

# guidance<<-guidance # uncomment to make visible after app exits
