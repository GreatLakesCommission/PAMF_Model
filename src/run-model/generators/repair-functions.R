# 2021-07-23
#
# Functions to support repairs to priors
#
# Functions
# * convertTransitions
# * fixAlphas
#
##

convertTransitions <- function(transitions) {
  # Converts between the transitions format in 2018-2019 and the format
  # from 2020 onward. it isn't ideal that it doesn't use STATES, but there's no
  # need for the old definitions (0.1, 0.5, 1.0, "H", "L") to show up anywere
  # but here
  #
  # INPUT
  # transitions : a data frame
  #
  # OUTPUT
  #
  #
  # ASSUMPTIONS
  # 1. transitions has the following columns:
  #      * mnt_comb
  #      * trans_prob
  #      * concentration
  # 2. transitions has EITHER of the two following sets of columns:
  #      * state_begin ] set 1: 2020 onward
  #      * state_end   ]
  #      * est_before  } set 2: 2018-2019
  #      * dens_before }
  #      * est_after   }
  #      * dens_after  }
  ##

  if ("state_begin" %in% colnames(transitions)) {
    est_before <- rep(NA, nrow(transitions))
    dens_before <- rep(NA, nrow(transitions))
    est_after <- rep(NA, nrow(transitions))
    dens_after <- rep(NA, nrow(transitions))

    est_before[which(transitions$state_begin == 1)] <- 0.1
    dens_before[which(transitions$state_begin == 1)] <- "L"
    est_after[which(transitions$state_end == 1)] <- 0.1
    dens_after[which(transitions$state_end == 1)] <- "L"

    est_before[which(transitions$state_begin == 2)] <- 0.1
    dens_before[which(transitions$state_begin == 2)] <- "H"
    est_after[which(transitions$state_end == 2)] <- 0.1
    dens_after[which(transitions$state_end == 2)] <- "H"

    est_before[which(transitions$state_begin == 3)] <- 0.5
    dens_before[which(transitions$state_begin == 3)] <- "L"
    est_after[which(transitions$state_end == 3)] <- 0.5
    dens_after[which(transitions$state_end == 3)] <- "L"

    est_before[which(transitions$state_begin == 4)] <- 0.5
    dens_before[which(transitions$state_begin == 4)] <- "H"
    est_after[which(transitions$state_end == 4)] <- 0.5
    dens_after[which(transitions$state_end == 4)] <- "H"

    est_before[which(transitions$state_begin == 5)] <- 1.0
    dens_before[which(transitions$state_begin == 5)] <- "L"
    est_after[which(transitions$state_end == 5)] <- 1.0
    dens_after[which(transitions$state_end == 5)] <- "L"

    est_before[which(transitions$state_begin == 6)] <- 1.0
    dens_before[which(transitions$state_begin == 6)] <- "H"
    est_after[which(transitions$state_end == 6)] <- 1.0
    dens_after[which(transitions$state_end == 6)] <- "H"

    transitions <- cbind(
      mnt_comb = transitions$mnt_comb, est_before, dens_before,
      est_after, dens_after,
      transitions[, c("trans_prob", "concentration")]
    )
  } else {
    if ("est_before" %in% colnames(transitions)) {
      state_begin <- rep(NA, nrow(transitions))
      state_end <- rep(NA, nrow(transitions))

      state_begin[transitions$est_before == 0.1 & transitions$dens_before == "L"] <- 1
      state_end[transitions$est_after == 0.1 & transitions$dens_after == "L"] <- 1

      state_begin[transitions$est_before == 0.1 & transitions$dens_before == "H"] <- 2
      state_end[transitions$est_after == 0.1 & transitions$dens_after == "H"] <- 2

      state_begin[transitions$est_before == 0.5 & transitions$dens_before == "L"] <- 3
      state_end[transitions$est_after == 0.5 & transitions$dens_after == "L"] <- 3

      state_begin[transitions$est_before == 0.5 & transitions$dens_before == "H"] <- 4
      state_end[transitions$est_after == 0.5 & transitions$dens_after == "H"] <- 4

      state_begin[transitions$est_before == 1.0 & transitions$dens_before == "L"] <- 5
      state_end[transitions$est_after == 1.0 & transitions$dens_after == "L"] <- 5

      state_begin[transitions$est_before == 1.0 & transitions$dens_before == "H"] <- 6
      state_end[transitions$est_after == 1.0 & transitions$dens_after == "H"] <- 6

      transitions <- cbind(
        mnt_comb = transitions$mnt_comb, state_begin, state_end,
        transitions[, c("trans_prob", "concentration")]
      )
    }
  }


  return(transitions)
} # end convertTransitions


fixAlphas <- function(conc, alpha_min) {
  # Given a vector of concentration values, redistribute element concentrations
  # so that no element has a concentration of zero but the total concentration
  # does not change
  #
  # INPUT
  # conc      : vector of concentrations (numeric)
  # alpha_min : minimum alpha value allowed to populate conc (numeric)
  #
  # OUTPUT
  # A vector of concentrations with the same length as conc, whose zero values
  # have been replaced by alpha_min and whose nonzero values have been reduced
  # proportionately
  #
  # ASSUMPTIONS
  ##

  ## Return if conc does not contain zeroes
  if (all(conc > 0)) {
    return(conc)
  }

  ## Make sure that conc values are all >= 0
  if (any(conc < 0)) {
    stop("fixAlphas: conc cannot contain negative values")
  }

  ## Make sure that alpha_min is a usable value
  if (alpha_min <= 0) {
    stop("fixAlphas: alpha_min must be greater than 0")
  }
  if (alpha_min > (sum(conc) / length(conc))) {
    # All elements cannnot be >= alpha_min without exceeding cont's current sum
    stop(paste0(
      "fixAlphas: alpha_min exceeds maximum (",
      (sum(conc) / length(conc)), ")"
    ))
  }
  if (alpha_min > min(conc[which(conc > 0)])) {
    stop("fixAlphas: alpha_min cannot be larger than any existing positive value")
  }

  ## Calculate how much of total value to redistribute
  alpha_needed <- length(which(conc == 0)) * alpha_min

  ## Deduct proportionally from nonzero elements
  deduct <- alpha_needed * (conc / sum(conc))
  conc <- conc - deduct

  ## Add alpha_min to zeroes
  conc[which(conc == 0)] <- alpha_min

  return(conc)
} # end fixAlphas
