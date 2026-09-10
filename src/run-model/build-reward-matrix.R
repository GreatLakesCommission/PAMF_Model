# Script to generate reward matrix in preparation for finding optimal
# management combinations. Rewards are made up of two opposing pieces:
#  * Satisfaction (reward increases with increased satisfaction)
#  * Cost (reward decreases with increased cost)
#
# Rewards are defined in a 16 x 6 matrix:
#     16 management combinations
#     6 states (3 % establishment x 2 stem density)
#
# NOTE: Whether cost_by_comb is provided by the 2017 PAMF Team's (DH and CM)
#       original ranking or whether it's derived from cost data, the number
#       associated with each management combination increases with increasing
#       combination cost.
#       e.g., in the ranking, the combination ranked '1' is the least costly.
#
#       ALSO! The a initial ranking is evenly spaced, i.e., the rank increases
#       by 1 for every management combination. The cost data
#       (will eventually) replace it with a ranking that reflects the
#       distance between combinations' median costs. This could affect
#       reward values! Illustration:
#
#       combination A    B  C    * With a reward based on cost, the jump
#       rank        1    2  3      between A and B will be less penalized
#       cost        0.1  1  10     in the reward and the jump between B
#                                  and C will be more penalized, compared
#                                  with rewards based on the rank
# ------------------------------------------------------------------------------
# Change to satisfaction
# ------------------------------------------------------------------------------
# From 2018-2022 the PAMF Model used a single satisfaction value for each
# invasion state. However, the model was over-recommending Rest-Rest-Rest as a
# management combination, and the model was updated to use a satisfaction matrix
# (i.e., a satisfaction value was assigned to each transition between invasion
# states) instead. Either version of the model can be run by changing the
# setting for "USE_SATISFACTION_MATRICES" below.
#
# If USE_SATISFACTION_MATRICES == TRUE
#   - Satisfaction matrices (satisfaction between invasion state transitions)
#     will be used (standard after 2022 model run)
# If USE_SATISFACTION_MATRICES == FALSE
#   - Single satisfaction values per invasion state will be used (standard
#     before 2023 model run)
#
# ------------------------------------------------------------------------------
#
# DEPENDENCIES
# * Global Constants
#     STATES : definitions of invasion states (data frame)
#     USE_SATISFACTION_MATRICES : T/F determines the satisfaction values to use
#
# ASSUMPTIONS
# * mean_sat-2018-08-16.csv exists in the initial-inputs directory and no
#   necessary information has been removed and its structure has not changed
#   since its creation

# * satisfaction_by_cost_2023 Satisfaction matrix data exists in the
#   initial-inputs directory and no necessary information has been removed and
#   its structure has not changed since its creation - as of January 2023 this
#   file has not been officially developed yet and we are currently using test
#   data.

# * Model runs from 2018-2022 used the a priori cost ranking
#   (initial-inputs/cost_rank_2017.csv), but after 2022,
#    initial-inputs/cost_rank_2023.csv should be used. Using either file, we
#    make the assumption that there are ties in the cost rank (e.g., two
#    management combinations have the same rank). If this is no longer the case,
#   re-configure the satisfaction to have the correct number of ranks (see
#   generators/interpolate-satisfaction-2023.R)
##

# ==============================================================================
#  Uncomment this section for script testing
# ==============================================================================
# message(">>> TEST BUILDING THE REWARD MATRICES <<<<")
# options(stringsAsFactors=FALSE)
#
# source("./src/global-constants.R")
# source("./src/run-model/optimizer-functions.R")

# ==============================================================================
# Get Data
# ==============================================================================

# Load in cost ranking

# NOTE: "cost_rank_2017.csv" was used in official model runs from 2018-2022.
# However, due to high costs observed for spading and cutting underwater, the
# ranking was changed in 2023 to move CRC and SRS to the most expensive end of
# the ranking. All other combinations remained in the same order as in 2017
# after SRS and CRC.

# To re-create runs from before 2023, load the old cost ranking:
# cost_by_comb <- read.csv("./src/run-model/initial-inputs/cost_rank_2017.csv")

cost_by_comb <- read.csv("./src/run-model/initial-inputs/cost_rank_2023.csv")
# Make sure that cost_by_comb is in the right order
cost_by_comb <- cost_by_comb[order(cost_by_comb$cost_rank_inc), ]

# Load in and interpolate / format satisfaction values
if (USE_SATISFACTION_MATRICES == FALSE) {
  # Load in satisfaction by state
  satisfaction_by_state <- read.csv("./src/run-model/initial-inputs/mean_sat-2018-08-16.csv")
  # Sort satisfaction by state ID
  satisfaction_by_state <- satisfaction_by_state[order(satisfaction_by_state$state), ]

  } else {
  # USE_SATISFACTION_MATRICES == TRUE
  # In this case, there is a lot of processing to do to make the satisfaction
  # interact with the cost rankings.
    
  # Load in satisfaction by state transition / cost scenario
  sat <- read.csv("./src/run-model/initial-inputs/satisfaction_by_cost_2023.csv")

  # Interpolate the between low and high cost scenarios ------------------------

  ## Assign ranks to cost scenarios --------------------------------------------

  # Note that the 2017 cost ranking has only 15 costs for 16 combos. This is
  # because CRC and SRS both have reverse_rank = 13. So, we will set the rest
  # rank at maximum instead of 16. This way if there is a cost ranking
  # with no ties, then this will adjust automatically.

  rest_rank <- max(cost_by_comb$reverse_rank) # (no cost)
  max_rank <- rest_rank - 1 # (low cost)
  min_rank <- min(cost_by_comb$reverse_rank) # (high cost)

  sat$cost_level[sat$cost_scenario == "High cost"] <- min_rank
  sat$cost_level[sat$cost_scenario == "Low cost"] <- max_rank
  sat$cost_level[sat$cost_scenario == "No cost"] <- rest_rank
  sat <- sat[, c("cost_level", "satisfaction", "state_begin", "state_end")]

  ## Interpolate the satisfaction by cost rankings -----------------------------
  # Isolate just the costs
  sat_cost <- sat[which(sat$cost_level %in% c(min_rank, max_rank)), ]

  interp_results <- list()
  # Ending invasion states
  for (i in c(1:6)) {
    # Beginning invasion states
    for (j in c(1:6)) {
      # Each cost ranking inbetween the min and max
      for (k in c((min_rank + 1):(max_rank - 1))) {
        interp <- approx(
          sat_cost$cost_level[sat_cost$state_begin == j & sat_cost$state_end == i],
          sat_cost$satisfaction[sat_cost$state_begin == j & sat_cost$state_end == i],
          xout = k
        )
        interp <- as.data.frame(interp)
        interp$state_begin <- j
        interp$state_end <- i
        interp_results[[paste(i, j, k)]] <- interp
      }
    }
  }

  interp_results <- do.call(rbind, interp_results)

  names(interp_results)[1:2] <- c("cost_level", "satisfaction")

  satisfaction_by_state <- rbind(sat, interp_results)
  satisfaction_by_state <- satisfaction_by_state[order(
    satisfaction_by_state$cost_level, 
    satisfaction_by_state$state_begin, 
    satisfaction_by_state$state_end
    ), ]
  
  # Cleanup temporary variables 
  rm(sat, interp_results, interp, i, j, k, sat_cost, rest_rank, min_rank,
     max_rank)
  
  # For testing use:
  # satisfaction_by_state <- read.csv("./src/run-model/test-cases/satisfaction-matrices/Test_satisfaction_matrices.csv")

  # Convert the dataframe into arrays for each cost ranking 
  satisfaction_by_state <- lapply(
    1:max(cost_by_comb$reverse_rank), convertSATArray, satisfaction_by_state,
    STATES
  )
}

# ==============================================================================
# Generate reward matrix
# ==============================================================================

# This is where we'll use cost information once we have estimates for all
# PAMF combinations (because we use a ranking, we need cost information for
# all actions. As of the end of the 2022 cycle, the data we've collected do not
# yet address all PAMF actions).
# Until then, we assume that effort is a good proxy for cost.
#
# In all cases we use reverse the ranking so that satisfaction increases with
# rank, and that even rank spacing is preserved

if (USE_SATISFACTION_MATRICES == FALSE) {
  
  # Create reward matrix with evenly spaced cost ranking
  reward_matrix <- outer(
    satisfaction_by_state$satisfaction,
    cost_by_comb$reverse_rank
  )
  rownames(reward_matrix) <- STATES$stateid
  colnames(reward_matrix) <- cost_by_comb$mnt_comb

} else {
  
  # Reward matrix for USE_SATISFACTION_MATRICES = TRUE -------------------------
  
  # IMPORTANT: There are three possible methods for creating the reward matrix
  # Method 1 is the accepted method starting for the 2023 model run with
  #          cost_rank_2023.csv
  # Method 2 is experimental and has only been used for testing
  # Method 3 is experimental and has only been used for testing
  
  ## Method 1 ------------------------------------------------------------------
  # This method uses the satisfaction scaled by cost from above
  
  reward_matrix <- satisfaction_by_state
  reward_matrix_list <- list()
  for (i in 1:nrow(cost_by_comb)) {
    rank <- cost_by_comb$reverse_rank[[i]]
    name <- cost_by_comb$mnt_comb[[i]]
    reward_matrix <- satisfaction_by_state[[rank]]
    reward_matrix_list[[name]] <- reward_matrix
  }
  reward_matrix <- reward_matrix_list[order(names(reward_matrix_list))]
  rm(reward_matrix_list, rank, name)

  ## Method 2 ------------------------------------------------------------------
  # Experimental - not used
  # This method uses the outer product of the satisfaction and the reverse
  # rank (similar to the old standard method used when 
  # USE_SATISFACTION_MATRICES = FALSE). This was deemed not necessary since
  # using method 1 already incorporates the rank--this method compounds the 
  # effect of using rank

  # } else {
  #   reward_matrix_list <- list()
  #   for (i in 1:nrow(cost_by_comb)) {
  #     reverse_rank_matrix <- cost_by_comb$reverse_rank[[i]]
  #     reward_matrix <- outer(
  #       satisfaction_by_state[[reverse_rank_matrix]],
  #       cost_by_comb$reverse_rank[[i]]
  #     )
  #     reward_matrix_list[[paste(i)]] <- reward_matrix
  #   }
  #     names(reward_matrix_list) <- cost_by_comb$mnt_comb
  #     reward_matrix <- reward_matrix_list[order(names(reward_matrix_list))]
  #     rm(reward_matrix_list, reverse_rank_matrix)

  ## Method 3 ------------------------------------------------------------------
  # Experimental - not used
  # This method uses the outer product of the satisfaction and a TEST SCALED
  # rank (similar to Method 2 except as opposed to using the ranks spaced by
  # one, the ranks are spaced by a decimal < 1)
  
  # } else {
  #   # I picked a small random number for the start since we don't want the lower
  #   # end of the scale to = 0
  #   cost_by_comb$scaled_reverse_rank <- scales::rescale(cost_by_comb$reverse_rank, to = c(.01, 1))
  #   reward_matrix_list <- list()
  #   for (i in 1:nrow(cost_by_comb)) {
  #     reverse_rank_matrix <- cost_by_comb$reverse_rank[[i]]
  #     reward_matrix <- outer(
  #       satisfaction_by_state[[reverse_rank_matrix]],
  #       cost_by_comb$scaled_reverse_rank[[i]]
  #     )
  #     reward_matrix_list[[paste(i)]] <- reward_matrix
  #   }
  #     names(reward_matrix_list) <- cost_by_comb$mnt_comb
  #     reward_matrix <- reward_matrix_list[order(names(reward_matrix_list))]
  #     rm(reward_matrix_list, reverse_rank_matrix)
}

# ==============================================================================
# Clean up temporary variables
# ==============================================================================
rm(satisfaction_by_state, cost_by_comb)
