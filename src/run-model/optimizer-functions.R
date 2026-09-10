# Some functions to support the optimizer.R script
#
#  Functions:
#  * convertTP        : Converts a set (i.e. one management combination's worth)
#                       of transition probabilities from data frame format to
#                       matrix format (with row and column names)
#  * probsByPolicy    : Returns the an array of transition matrices containing
#                       only those actions that are allowed under the given
#                       policy restriction
#  * rewardsByPolicy  : Returns the reward matrices containing only those
#                       actions that are allowed under the given policy
#                       restriction, in the array format used by MDPtoolbox
#  * pamfMDP          : Runs MDPSolve solver for optimal management combination
#                       per MU state, given a list containing a P array and an R
#                       array (sensu MDPtoolbox)
#  * getCombsByPolicy : Given the ID of a policy restriction, return all
#                       management combinations that are possible under that
#                       policy
#  * policy2action    : Converts MDP policy outputs to a set of management
#                       actions recognizable by the database
#  * getV             : Return the value vector from a policy
#
# * convertSATArray   : Convert the 2023 satisfaction (USE_SATISFACTION_MATRICES 
#                       == TRUE) to arrays
##


convertTP <- function(mnt_comb, transitions, states, probs = TRUE) {
  # Converts a set (i.e. one management combination's worth) of transition
  # probabilities from data frame format to  matrix format
  # (with row and column names)
  #
  # INPUT
  # mnt_comb    : ID of a management combination (character)
  # transitions : transitions for one or more management combinations
  #               (data frame)
  # states      : Data frame defining which %establishment and stem
  #               density values map to which state IDs (data frame)
  # probs       : if TRUE, display the transition probabilities
  #               if FALSE, display concentrations (logical)
  #
  # OUTPUT
  # A matrix whose rows and columns are named by state (matrix)
  #
  # ASSUMPTIONS
  # * transitions has the following columns:
  #    state_begin
  #    state_end
  #    trans_prob
  # * states has the following columns:
  #    stateid
  # * establishment and density categories are consistent between states,
  #   transitions
  # * transitions contains information for all possible initial, final states
  ##

  # Extract the rows from transitions that correspond to mnt_comb
  transitions <- transitions[transitions$mnt_comb == mnt_comb, ]

  ## Since matrix() builds matrices by columns, order the data frame by end state.
  #  The trans_prob column in the result is then a concatenation of all columns
  #  in the matrix representation of the transition probabilities.
  ##
  transitions <- transitions[order(
    transitions$state_end,
    transitions$state_begin
  ), ]

  # Build a matrix out of it
  n_states <- nrow(states)
  if (probs) {
    transition_matrix <- matrix(transitions$trans_prob,
      nrow = n_states,
      ncol = n_states
    )
  } else {
    transition_matrix <- matrix(transitions$concentration,
      nrow = n_states,
      ncol = n_states
    )
  }

  # Assign state IDs to the rows and columns of the matrix & return it
  rownames(transition_matrix) <- STATES$stateid[order(STATES$stateid)]
  colnames(transition_matrix) <- STATES$stateid[order(STATES$stateid)]

  return(transition_matrix)
} # end convertTP

probsByPolicy <- function(policy_id, transitions, policy_definitions) {
  # Returns the an array of transition matrices containing only those
  # actions that are allowed under the given policy restriction
  #
  # INPUT
  # policy_id          : ID of policy restriction (integer)
  # transitions        : Transition matrices for ALL possible actions, where
  #                      each [,,a] slice contains transitions for one action
  #                      (array)
  # policy_definitions : All policy restriction types, along with the management
  #                      actions that are allowed under each (data frame)
  #
  # OUTPUT
  # A transition array whose slices [,,a] denote the reward value of each
  # state under action a, for all a allowed under the given policy
  #
  # ASSUMPTIONS
  # * policy_definitions has the following columns:
  #   restr_id
  #   mnt_comb
  #   mnt_index
  # * policy_id appears in the restr_id column of policy_definitions
  ##

  # Extract the correct policy restriction from policy_definitions
  restriction <- policy_definitions[policy_definitions$restr_id == policy_id, ]
  comb_indices <- restriction$mnt_index # These indices correspond to the position
  # of allowed combinations for the current
  # policy restriction, as they appear in
  # the FULL set of management combinations.
  # Indices are needed to deal with reward
  # matrix

  return(transitions[, , comb_indices])
} # end probsByPolicy

rewardsByPolicy <- function(policy_id, rewards, policy_definitions) {
  # Returns the reward matrices containing only those actions that are allowed
  # under the given policy restriction, in the array format used by MDPtoolbox.
  # If USE_SATISFACTION_MATRICES == TRUE then the award matrix will use the
  # satisfaction matrices (e.g., satisfaction with the transition between
  # states) and if == FALSE then it will use the satisfaction per state.
  #
  # INPUT
  # policy_id          : ID of policy restriction (integer)
  # rewards            : The full rewards matrix (matrix)
  # policy_definitions : All policy restriction types, along with the management
  #                      actions that are allowed under each (data frame)
  # USE_SATISFACTION_MATRICES : True / False
  #
  # OUTPUT
  # If USE_SATISFACTION_MATRICES == TRUE: 
  # A rewards array whose columns denote the reward value of each
  # transition between states under action a, for all a allowed under the given
  # policy
  #
  # If USE_SATISFACTION_MATRICES == FALSE: 
  # A rewards array whose columns [,a] denote the reward value of each
  # state under action a, for all a allowed under the given policy
  #
  # ASSUMPTIONS
  # * policy_definitions has the following columns:
  #    restr_id
  #    mnt_comb
  #    mnt_index
  # * USE_SATISFACTION_MATRICES exists
  # * policy_id appears in the restr_id column of policy_definitions
  ##

  # --- Get transitions, rewards of actions conforming to the given policy --

  # Extract the correct policy restriction from policy_definitions
  restriction <- policy_definitions[policy_definitions$restr_id == policy_id, ]

  # These indices correspond to the position of allowed combinations for the
  # current policy restriction, as they appear in the FULL set of management
  # combinations. Indices are needed to deal with reward matrix
  comb_indices <- restriction$mnt_index

  # Get number of states, number of transition matrices needed
  if (USE_SATISFACTION_MATRICES == TRUE) {
    n_states <- dim(rewards[[1]])[1] # one reward value per transition
  } else {
    n_states <- dim(rewards)[1] # one reward value per state
  }

  n_combs <- length(comb_indices)

  # adjust rewards matrix to keep only information for the combinations in combs
  if (USE_SATISFACTION_MATRICES == TRUE) {
    rewards <- rewards[comb_indices]
    return(array(unlist(rewards), dim = c(n_states, n_states, n_combs)))
  } else {
    rewards <- rewards[, comb_indices]
    return(array(rewards, dim = c(n_states, n_combs)))
  }
} # end rewardsByPolicy

pamfMDP <- function(probs_by_action, rewards_by_action, discount) {
  # Runs MDPSolve solver for optimal management combination per MU state,
  # given a list containing a P array and an R array (sensu MDPtoolbox)
  #
  # INPUT
  # probs_by_action   : Array of transition matrices where each [,,a] slice
  #                     contains transitions under action a (array)
  # rewards_by_action : Array of reward matrices where each [,,a] slice
  #                     contains rewards under action a
  # discount          : discount rate. ~1 = no discount (double)
  #
  # OUTPUT
  # The result of the call to mdp_value_iteration() function in MDPtoolbox.
  # (labeled list)
  #
  # ASSUMPTIONS
  # * MDPtoolbox is installed and loaded
  # * P and R are in a the format recognized by MDPtoolbox.
  ##

  # Check the validity of the problem as described by probs_by_action,
  # rewards_by_action, d
  mdpcheck_msg <- mdp_check(probs_by_action, rewards_by_action)
  if (mdpcheck_msg != "") {
    stop_msg <- paste0(mdpcheck_msg, ".")
    stop(stop_msg)
  }

  # find optimal policy
  return(mdp_value_iteration(probs_by_action, rewards_by_action, discount))
} # end pamfMDP

getCombsbyPolicy <- function(policy_id, policy_definitions) {
  # Given the ID of a policy restriction, return all management combinations
  # that are possible under that policy
  #
  # INPUT
  # policy_id          : ID of policy restriction (integer)
  # policy_definitions : All policy restriction types, along with the management
  #                      actions that are allowed under each (data frame)
  #
  # OUTPUT
  # the section of policy_definitions$mnt_comb corresponding to policy_id
  # (vector)
  #
  # ASSUMPTIONS
  # * policy_id appears in the restr_id column of policy_definitions
  # * policy_definitions has the following columns:
  #    restr_id
  #    mnt_comb
  ##

  return(policy_definitions[policy_definitions$restr_id == policy_id, "mnt_comb"])
} # end getCombsbyPolicy

policy2action <- function(policy, policy_id, restr_combs, mc_maps) {
  # Converts MDP policy outputs to a set of management actions
  # recognizable by the database
  #
  # INPUT
  # policy        : A policy output by MDPSolve (policy object)
  # policy_id     : The ID of the restriction type used to generate
  #                 policy, as listed in policy_definitions (integer)
  # restr_combs   : Vector of management combinations as recognized
  #                 by the model & allowed by the restrictions used when
  #                 policy was created (character)
  # mc_maps       : Defines the mapping between the model and database
  #                 management action codes (data frame)
  #
  # OUTPUT
  # The managment actions by phase recommended for each state of the
  # PAMF model, in the database coding (data frame)
  #
  # ASSUMPTIONS
  # * policy contains $policy element
  # * mnt_combs contains management combinations as recognized by the
  #   model, e.g., "GPF", "GRR", etc
  # * Management combinations in mnt_combs are in the same order as they
  #   were when the MDP solver was run to generate policy
  # * mc_maps has the following columns:
  #     db_tloc
  #     db_dorm
  #     db_grow
  #     mnt_code
  ##

  # Extract the actual policy and number of states from the policy object
  p <- policy$policy
  n_states <- length(p)

  # create data frame for output
  restr_id <- rep(policy_id, n_states)
  state <- rep(NA, n_states)
  db_tloc <- rep(NA, n_states) # 'database translocating'
  db_dorm <- rep(NA, n_states) # 'database dormant'
  db_grow <- rep(NA, n_states) # 'database growing'
  mnt_comb <- (rep(NA, n_states))
  policy_out <- data.frame(restr_id, state, db_tloc, db_dorm, db_grow, mnt_comb)

  for (s in 1:n_states) {
    # Get the recommended management combination
    recommendation <- restr_combs[p[s]]
    rec_row <- mc_maps[mc_maps$mnt_comb == recommendation, ]

    policy_out$state[s] <- s
    policy_out[s, c("db_tloc", "db_dorm", "db_grow", "mnt_comb")] <-
      rec_row[c("db_tloc", "db_dorm", "db_grow", "mnt_comb")]
  } # end for

  return(policy_out)
} # end policy2action()

getV <- function(policy) {
  # Return the value vector from policy
  #
  # INPUT
  # policy : a labeled list (list)
  #
  # OUTPUT
  # the V vector from policy

  # ASSUMTIONS
  # * policy contains an element named V
  ##

  return(policy$V)
} # end of getV

convertSATArray <- function(costrows, satisfaction, states) {
  # Converts a set (i.e., one cost ranking's worth) of satisfaction data from 
  # data frame format to  matrix format (with row and column names)
  #
  # INPUT
  # costrows    : Row number IDs in cost ranking dataframe (numeric)
  # satisfaction : Satisfaction data for all management combinations, where 
  #                cost_level = 1 is low cost and cost_level = 16 is high cost
  #               (data frame)
  # states      : Data frame defining which %establishment and stem
  #               density values map to which state IDs (data frame)
  #
  # OUTPUT
  # A matrix whose rows and columns are named by state (matrix)
  #
  # ASSUMPTIONS
  # * satisfaction has the following columns:
  #    cost_level
  #    state_begin
  #    state_end
  #    satisfaction
  # * states has the following columns:
  #    stateid
  # * satisfaction contains information for all possible initial, final states
  ##

  # Extract the rows from satisfaction that correspond to mnt_comb
  satisfaction <- satisfaction[which(satisfaction$cost_level == costrows), ]

  ## Since matrix() builds matrices by columns, order the data frame by end state.
  #  The satisfaction column in the result is then a concatenation of all columns
  #  in the matrix representation of the satisfaction values.
  ##
  satisfaction <- satisfaction[order(
    satisfaction$state_end,
    satisfaction$state_begin
  ), ]

  # Build a matrix out of it
  n_states <- nrow(states)
  satisfaction_matrix <- matrix(satisfaction$satisfaction,
    nrow = n_states,
    ncol = n_states
  )

  # Assign state IDs to the rows and columns of the matrix & return it
  rownames(satisfaction_matrix) <- STATES$stateid[order(STATES$stateid)]
  colnames(satisfaction_matrix) <- STATES$stateid[order(STATES$stateid)]

  return(satisfaction_matrix)
} # end convertSATArray
