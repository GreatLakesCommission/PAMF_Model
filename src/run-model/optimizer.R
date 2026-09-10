# This script uses a Markov Decision Process (MDP) to find the optimal policy,
# (i.e. the action that best balances cost and reward), for PAMF, given our
# current knowledge of transition probabilities and cost.
#
# HOW AN MDP WORKS
# A Markov Decision Process uses the following information (Chades et al.
# 2014b in the development_resources/MDP directory):
#     * A finite set of states
#     * A finite set of actions
#     * The probability that each action A allowed in state S results in a
#       transition to state S' in a single time step
#     * A reward associated with each possible S->S' transition under
#       action A
#     * (AND USUALLY) a discount parameter 0<discount<1 defining the
#       relative value of present vs. future rewards
#
# The point here is to find a policy, i.e. a single action 'A' per state 'S'
# that maximizes the cumulative expected reward over a time horizon.
#
# In PAMF's case, the policy will consist of a single management combination
# per state, which we will distribute as guidance for every management unit
# in that state.
#
#
# Sourced by: run-the-model.R
#
# DEPENDENCIES
# * Global Constants
#    STATES     : definitions of invasion states, given in terms of
#                 %establishment and stem density (database encoding)
#    PAMF_COMBS : definitions of PAMF management combinations, including both
#                 the database and model encodings
#    DISCOUNT   : discount factor for the optimization
#    CYCLEEND   : the final year of the cycle being analyzed
#
# * Variables
#    transitions   : up-to-date set of transition matrices (dataframe format)
#    reward_matrix : reward value associated with each pair of state and
#                    management combination
#    pc_matrix     : partial controllability matrix, in matrix format
#                  : (not data frame format)
#
# * Functions
#   From optimizer-functions.R:
#     convertTP
#     probsByPolicy
#     rewardsByPolicy
#     pamfMDP
#     getCombsByPolicy
#     policy2action
#   From suboptimal-functions.R:
#     eval_policy_optimality_proportion
#     convertNOP
#     nop2action
##

#  Uncomment this section for script testing -----------------------------------

# message(">>> USING TEST DATA FOR OPTIMIZER <<<<")
# options(stringsAsFactors=FALSE)
#
# library(MDPtoolbox)
# source("./src/global-constants.R")
#
# # Functions used to prepare the MDP and find optimal management combinations
# source("./src/run-model/optimizer-functions.R")
#
# # Functions used to find near-optimal management combinations
# source("./src/run-model/suboptimal-functions.R")
#
# source("./src/run-model/build-reward-matrix.R", local=TRUE) # reward matrix
#
# CYCLEEND = 2525 # year doesn't matter for testing but we need to have one
#
# # Read & format the initial partial controllability matrix
# # Note that it assumes that guidance is implemented 100% of the time,
# # i.e. it's an identity matrix
# pc_matrix=read.csv("./src/run-model/initial-inputs/pc-initial-matrix.csv")
# mnt_combs = pc_matrix[,1]
# pc_matrix=pc_matrix[,2:ncol(pc_matrix)]
# colnames(pc_matrix)=mnt_combs
# rownames(pc_matrix)=mnt_combs
# pc_matrix=as.matrix(pc_matrix) # tell R it isn't a data frame
#
# # Transition matrices (as with the transition update test cases,
# # these are identity matrices)
# transitions = read.csv("./src/run-model/test-cases/transition-update/trans_probs_init.csv")
#
# action_restrictions =  read.csv("./src/policy_definitions2018-07-31.csv")

# PARTIAL CONTROLLABILITY ------------------------------------------------------

# First, account for partial controllability.
# Partial controllability refers to the possibility that managers don't
# implement the recommended set of actions. The partial controllability matrix
# stores the probability that any PAMF combination P will be implemented, given
# recommendation R.

# These probabilities can be incorporated into the transition matrices
# of the PAMF model by multiplying a vector corresponding to ONE transition
# across ALL actions by a column of the partial controllability matrix.

# dimensions of transition, PC arrays
n_states <- nrow(STATES)
n_combs <- nrow(PAMF_COMBS)

# put pc_matrix rows and columns in the same order as PAMF_COMBS$mnt_comb
pamf_combs <- PAMF_COMBS$mnt_comb
pc_matrix <- pc_matrix[
  match(c(pamf_combs), colnames(pc_matrix)),
  match(c(pamf_combs), colnames(pc_matrix))
]

# convert transitions from data frame format into a labeled list of matrices
# NOTE: the output will be in the same order as pamf_combs
transition_matrices <- lapply(
  pamf_combs, convertTP, transitions,
  STATES
)
names(transition_matrices) <- pamf_combs


## Convert to array format. Dimensions 1 and 2 are the IDs of initial and
#  final states. The third dimension corresponds to the management combination
#  (same order as pamf_combs)
##
probs_by_comb <- array(unlist(transition_matrices),
                       dim = c(n_states, n_states, n_combs)
)

## Multiply the rows of pc_matrix by 1-D slices of probs_by_comb (each slice
#  representing one possible transition across ALL management combinations)
#  Result: Stack of matrices in the same order as the transition matrix stack,
#          where each element corresponds to the product of:
#          (a) the probability that action B was implemented when A was
#               recommended, and
#          (b) a state-to-state transition probability corresponding to action B
#  e.g. assuming that everything is ordered the same as pamf_combs (as it should
#       be) then the value of the first cell on the top slice of the stack is
#       the product of:
#          (a) Pr(implemented==GRG | intended==GRG), and
#          (b) Pr(current state == 1 | previous state == 1), from the GRG matrix
#       And the value of the first cell in the second slice from the top of the
#       stack is the product of:
#          (a) Pr(implemented==G+PF | intended==GRG), and
#          (b) Pr(current state == 1 | previous state == 1), from the G+PF
#              matrix
#  etc.
#  NOTE: this example uses the '|' character in the statistical sense ('given'),
#        NOT the programming sense ('or')
##
pc_tp <- array(NA, dim = c(n_states, n_states, n_combs))
for (i in 1:n_states) {
  for (j in 1:n_states) {
    pc_tp[i, j, ] <- pc_matrix %*% probs_by_comb[i, j, ]
  }
} # adapted from the example in the development resources directory


# pc_tp is an array of the transition matrices for ALL pamf_combs + OTHER
#
# BUT different action restrictions make use of different sets of management
# combinations (e.g. if it isn't possible to control water levels on a MU, FLOOD
# actions should not be recommended). So each combination of restrictions will
# be paired only with the transition matrices that correspond to combinations
# allowed by that set of restrictions.

transition_arrays <- lapply(
  unique(action_restrictions$restr_id),
  probsByPolicy, pc_tp, action_restrictions
)

# Format reward data for MDP ---------------------------------------------------

# The columns of rewards should be in the same order as pamf_combs
#
# In 2018 but not 2019, the '+' character got converted to '.' in
# the arrays. The following commented lines help deal with that. If this
# issue comes up again, uncomment them:
# combs_dot = do.call(gsub, list(pattern="+", replacement=".", x=pamf_combs,
#                                fixed=TRUE))
# rewards   = rewards[,match(combs_dot, colnames(rewards))]

if (USE_SATISFACTION_MATRICES == FALSE) {
  # re-order the columns (comment out if using combs_dot)
  reward_matrix <- reward_matrix[, match(pamf_combs, colnames(reward_matrix))]
}

# Generate a reward array for set of restrictions, containing only the
# actions allowed under that restriction set
reward_arrays <- lapply(
  unique(action_restrictions$restr_id), rewardsByPolicy,
  reward_matrix, action_restrictions
)

# THE OPTIMIZATION -------------------------------------------------------------

# Find the optimal management combination by MU state and policy restriction!
# There's a small possibility that this command could throw an error, if
# the MDPtoolbox algorithm finds that the problem formulation isn't valid, so
# this function is wrapped in tryCatch to stop the script and app if there is
# an error

policies <- tryCatch(
  {
    mapply(pamfMDP, transition_arrays, reward_arrays,
           MoreArgs = list(DISCOUNT), SIMPLIFY = FALSE
    )
  },
  error = function(cond) {
    message("pamfMDP returned an error.")
    message("Here's the error message:")
    message(cond)
    return(NA)
    # Stop the app.
    break()
    stopApp()
  },
  warning = function(cond) {
    message("pamfMDP returned a warning.")
    message("Here's the warning message:")
    message(cond)
    # Choose a return value in case of warning
    return(policies)
  },
  finally = {
    message("Ran pamfMDP successfully (MDPSolve solver).")
  }
)

# Format Optimal Policies for Output -------------------------------------------

# All policies are vectors of integers, where each entry is the INDEX of
# the recommended management combination, pulled from the vector of combinations
# allowed by the restriction that the policy adheres to
# NOTE ALSO that policy restriction IDs are zero-indexed, i.e. policy_id=0
#           goes with policies[[1]] and comb_list[[1]].
#
# Map this information back into the codes defined for the model and database.
comb_list <- lapply(
  unique(action_restrictions$restr_id), getCombsbyPolicy,
  action_restrictions
)

policies_actions <- mapply(
  policy2action,
  policies,
  unique(action_restrictions$restr_id),
  comb_list,
  MoreArgs = list(PAMF_COMBS),
  SIMPLIFY = FALSE
)

policies_actions <- do.call(rbind, policies_actions)

# Find Optimal Policy Values ---------------------------------------------------

# Value iteration from pamfMDP above returns the optimal policy but it does NOT
# return the optimal V. The value iteration algorithm uses a fast stopping
# criteria - policy$V is the value calculated when the algorithm stops, not the
# optimal value function. This function, mdp_eval_policy_matrix, will find the
# optimal V values that we need to inform eval_policy_optimality_proportion
# below to find near-optimal policies.

mdp_eval_policy_matrix_results <- mapply(
  function(P, R, pol) {
    mdp_eval_policy_matrix(P, R, DISCOUNT, pol$policy)
  },
  transition_arrays,
  reward_arrays,
  policies,
  SIMPLIFY = FALSE
)

for (i in seq_along(policies)) {
  policies[[i]]$V <- mdp_eval_policy_matrix_results[[i]]
}

rm(mdp_eval_policy_matrix_results)

# Find near-optimal policies ---------------------------------------------------

# Find near-optimal actions within a certain percentage of the value of
# the action recommended by the optimal policy.

threshold <- 0.05 # return all actions within 5% of the optimal value

nop_results <- mapply(
  eval_policy_optimality_proportion,
  transition_arrays,
  reward_arrays,
  policies,
  MoreArgs = list(
    discount = DISCOUNT,
    proportion = threshold
  ),
  SIMPLIFY = FALSE
)

opnop_actions <- lapply(
  nop_results,
  function(x) {
    convertNOP(
      nop_matrix = x$optimal_actions,
      Q = x$Q,
      V = x$V
    )
  }
)

opnop_actions <- mapply(
  nop2action,
  opnop_actions,
  unique(action_restrictions$restr_id),
  comb_list,
  MoreArgs = list(PAMF_COMBS),
  SIMPLIFY = FALSE
)

opnop_actions <- do.call(rbind, opnop_actions)

## Double-check optimal and near_optimal outputs -------------------------------

# We will only use the outputs from opnop_actions above and not
# policies_actions, so let's make sure they are the same mnt_comb for the
# optimal values before discarding policies_actions

# Subset only the optimal values from the list of near/optimal/NA values
opt_nop <- subset(opnop_actions, optimal == 1)

check_opt_nop <- merge(
  opt_nop[, c("restr_id", "state", "mnt_comb")],
  policies_actions[, c("restr_id", "state", "mnt_comb")],
  by = c("restr_id", "state"),
  suffixes = c("_nop", "_policy")
)

if (!all(check_opt_nop$mnt_comb_nop == check_opt_nop$mnt_comb_policy)) {
  bad_opt_nop <- check_opt_nop[check$mnt_comb_nop != check_opt_nop$mnt_comb_policy, ]
  
  stop(
    paste(
      "ERROR: optimizer.R - Optimal actions from ",
      "eval_policy_optimality_proportion do not match the optimal policy output ",
      "from policies_actions"
    )
  )
}

## Confirm that optimal Q = V --------------------------------------------------
# the differences are very small (10^-16), so round to 10)
Q_V_diff <- round(
  subset(opnop_actions, optimal == 1)$Q -
    subset(opnop_actions, optimal == 1)$V,
  10
)

if (any(Q_V_diff != 0)) {
  stop(
    paste(
      "ERROR: optimizer.R found that the MDP's Q and V differ for optimal actions.",
      "Maximum absolute difference:",
      max(abs(Q_V_diff))
    )
  )
}

## Confirm near-optimal selection logic ----------------------------------------
# We can also confirm that the near-optimal selection logic is working
# correctly-- all near-optimals should be < 1 - THRESHOLD 

theshold_diff <- 1 - threshold

check_sl <- opnop_actions[!is.na(opnop_actions$optimal),]

check_sl$top_Q <- ave(
  check_sl$Q,
  check_sl$restr_id,
  check_sl$state,
  FUN = max
)

check_sl$pct_of_top <- check_sl$Q / check_sl$top_Q

if (any(check_sl$pct_of_top < theshold_diff, na.rm = TRUE)) {
  
  bad_rows <- check_sl[check_sl$pct_of_top < theshold_diff, ]
  
  stop(
    paste0(
      "ERROR: optimizer.R found actions with pct_of_top < ", theshold_diff,
      ". Minimum value:",
      min(check_sl$pct_of_top, na.rm = TRUE)
    )
  )
}

# Finalize policies ------------------------------------------------------------

# After confirming that V and Q look okay, remove V
opnop_actions$V <- NULL

# Move Q to the end of the dataframe
opnop_actions <- opnop_actions[, c(setdiff(names(opnop_actions), "Q"), "Q")]

# Add cycle as the first column of results
opnop_actions <- cbind(cycle_end = CYCLEEND, opnop_actions)

# Clean up ---------------------------------------------------------------------

# Remove temporary variables
suppressWarnings(rm(
  n_states, n_combs, pamf_combs, pc_matrix, probs_by_comb, pc_tp,
  transition_matrices, transition_arrays, reward_matrix, reward_arrays,
  comb_list, policies, policies_actions, threshold, optimal,
  optimal_and_not, cycle_end, i, j, nop_results, Q_V_diff,
  check_opt_nop, opt_nop, check_sl, theshold_diff
))
