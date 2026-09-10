# Functions to compare between model outputs of the same type
#
# Functions
#   * transitionDiff
#   * partControlDiff
#   * policyDiff
#   * guidanceDiff
#   * guidanceDiffMU
#
##

# TRANSITION MATRICES ----------------------------------------------------------

transitionDiff <- function(path1, path2, cycleend, probs = FALSE, 
                           epsilon = 0.001, diffs.only = TRUE) {
  # Given two sets of transition matrices, find any differences
  # between between the two sets
  #
  # INPUT
  # path1 : file path to transition matrix data 1 (csv)
  # path2 : file path to transition matrix data 2 (csv)
  # cycleend   : end of the PAMF cycle in the transition matrix data 
  #
  # OUTPUT
  # Data frame containing which mnt_comb transition probabilities and 
  # concentrations have changed between the two files
  #
  # ASSUMPTIONS
  # * files at path1, path2 have the following columns:
  #   trans_prob
  #   concentration
  #   mnt_comb
  #   state_begin
  #   state_end
  #   cycle_used

  # --- THE CODE 
  tra1 <- read.csv(path1, stringsAsFactors = FALSE)
  tra2 <- read.csv(path2, stringsAsFactors = FALSE)

  # convert to state-state format, if necessary
  if ("est_before" %in% colnames(tra1)) {
    tra1 <- convertTransitions(tra1)
  }
  if ("est_before" %in% colnames(tra2)) {
    tra2 <- convertTransitions(tra2)
  }

  # Get rows from cycleend
  if (!"cycle_used" %in% colnames(tra1)) {
    # the old format-- only one cycle per file
    warning("No dates given in file")
  } else {
    # new format-- cumulative
    tra1 <- tra1[tra1$cycle_used == cycleend, ]
  }

  if (!"cycle_used" %in% colnames(tra2)) {
    # the old format-- only one cycle per file
    warning("No dates given in file")
  } else {
    # new format-- cumulative
    tra2 <- tra2[tra2$cycle_used == cycleend, ]
  }

  # rename probabilites and concentrations for easier interpretation
  colnames(tra1)[which(colnames(tra1) == "trans_prob")] <- "trans_prob1"
  colnames(tra2)[which(colnames(tra2) == "trans_prob")] <- "trans_prob2"
  colnames(tra1)[which(colnames(tra1) == "concentration")] <- "concentration1"
  colnames(tra2)[which(colnames(tra2) == "concentration")] <- "concentration2"

  merge_cols <- c("mnt_comb", "state_begin", "state_end")
  tra_both <- merge(tra1[, c(merge_cols, "trans_prob1", "concentration1")],
    tra2[, c(merge_cols, "trans_prob2", "concentration2")],
    by.x = merge_cols, by.y = merge_cols
  )

  if (probs == FALSE) { # show rows with differences in concentration
    if (diffs.only == TRUE) {
      return(tra_both[abs(tra_both$concentration1 - tra_both$concentration2) >
        epsilon, ])
    } else {
      return(tra_both)
    }
  } else { # show rows with appreciable differences in probability
    # Due to rounding errors, sometimes the differences are extremely small
    if (diffs.only == TRUE) {
      return(tra_both[abs(tra_both$probability1 - tra_both$probability2) > epsilon, ])
    } else {
      return(tra_both)
    }
  }
} # end transitionDiff

# PARTIAL CONTROLLABILITY ------------------------------------------------------

partControlDiff <- function(path1, path2, cycleend, probs = FALSE, 
                            epsilon = 0.001, diffs.only = TRUE) {
  # Given two sets of partial controllability matrices, find any differences
  # between between the two sets
  #
  # INPUT
  # path1 : file path to partial controllability matrix data 1 (csv)
  # path2 : file path to partial controllability matrix data 2 (csv)
  # cycleend  : end of the PAMF cycle in the partial controllability matrix data 
  #
  # OUTPUT
  # Data frame containing which partial controllability probabilities and 
  # concentrations have changed between the two files for the intended vs. 
  # implemented management combinations
  #
  # ASSUMPTIONS
  # * files at path1, path2 have the following columns:
  #   probability
  #   concentration
  #   mnt_intended
  #   mnt_implemented
  #   cycle_used
  
  # --- THE CODE 
  pc1 <- read.csv(path1, stringsAsFactors = FALSE)
  pc2 <- read.csv(path2, stringsAsFactors = FALSE)

  # Get rows from cycleend
  if (!"cycle_used" %in% colnames(pc1)) {
    # the old format-- only one cycle per file
    warning("No dates given in file")
  } else {
    # new format-- cumulative
    pc1 <- pc1[pc1$cycle_used == cycleend, ]
  }

  if (!"cycle_used" %in% colnames(pc2)) {
    # the old format-- only one cycle per file
    warning("No dates given in file")
  } else {
    # new format-- cumulative
    pc2 <- pc2[pc2$cycle_used == cycleend, ]
  }

  # rename probabilites and concentrations for easier interpretation
  colnames(pc1)[which(colnames(pc1) == "probability")] <- "probability1"
  colnames(pc2)[which(colnames(pc2) == "probability")] <- "probability2"
  colnames(pc1)[which(colnames(pc1) == "concentration")] <- "concentration1"
  colnames(pc2)[which(colnames(pc2) == "concentration")] <- "concentration2"

  pc_both <- merge(
    pc1[, c(
      "mnt_intended", "mnt_implemented", "probability1",
      "concentration1"
    )],
    pc2[, c(
      "mnt_intended", "mnt_implemented", "probability2",
      "concentration2"
    )],
    all.x = TRUE, all.y = TRUE
  )

  if (probs == FALSE) { # show rows with differences in concentration
    if (diffs.only == TRUE) {
      return(pc_both[is.na(pc_both$mnt_implemented) | is.na(pc_both$mnt_intended) |
        (pc_both$concentration1 != pc_both$concentration2), ])
    } else {
      return(pc_both)
    }
  } else { # show rows with appreciable differences in probability
    # Due to rounding errors, sometimes the differences are extremely small
    if (diffs.only == TRUE) {
      return(pc_both[is.na(pc_both$mnt_implemented) | is.na(pc_both$mnt_implemented) |
        abs(pc_both$probability1 - pc_both$probability2) > epsilon, ])
    } else {
      return(pc_both)
    }
  }
} # end partControlDiff

# POLICIES ---------------------------------------------------------------------

policyDiff <- function(path1, path2, cycleend, diffs.only = TRUE) {
  # Given two sets of model policies, find any differences
  # between between the two sets
  #
  # INPUT
  # path1 : file path to model policies data 1 (csv)
  # path2 : file path to model policies data 2 (csv)
  # cycleend  : end of the PAMF cycle in the model policies data 
  #
  # OUTPUT
  # Data frame containing which mnt_comb transition probabilities and 
  # concentrations have changed between the two files
  #
  # ASSUMPTIONS
  # * files at path1, path2 have the following columns:
  #   optimal
  #   mnt_comb
  #   restr_id
  #   state
  # 
  # --- THE CODE 
  pols1 <- read.csv(path1, stringsAsFactors = FALSE)
  pols2 <- read.csv(path2, stringsAsFactors = FALSE)

  # Get optimal rows from cycleend
  # non-optimal solutions are not part of any policy in the MDP sense
  if (!"cycle_end" %in% colnames(pols1)) {
    # the old format-- only one cycle per file
    warning("No dates given in file")
    pols1 <- pols1[pols1$optimal == 1, ]
    # rename mnt_code for easier comparison
    colnames(pols1)[which(colnames(pols1) == "mnt_code")] <- "policy1"
  } else {
    # new format-- cumulative
    pols1 <- pols1[pols1$cycle_end == cycleend & pols1$optimal == 1, ]
    # rename mnt_code for easier comparison
    colnames(pols1)[which(colnames(pols1) == "mnt_comb")] <- "policy1"
  }

  if (!"cycle_end" %in% colnames(pols2)) {
    # the old format-- only one cycle per file
    warning("No dates given in file")
    pols2 <- pols2[pols2$optimal == 2, ]
    colnames(pols2)[which(colnames(pols2) == "mnt_code")] <- "policy2"
  } else {
    # new format-- cumulative
    pols2 <- pols2[pols2$cycle_end == cycleend & pols2$optimal == 1, ]
    # rename mnt_code for easier comparison
    colnames(pols2)[which(colnames(pols2) == "mnt_comb")] <- "policy2"
  }

  merge_cols <- c("restr_id", "state")
  policies <- merge(pols1[, c(merge_cols, "policy1")],
    pols2[, c(merge_cols, "policy2")],
    all.x = TRUE, all.y = TRUE
  )

  if (diffs.only == TRUE) {
    return(policies[is.na(policies$policy1) | is.na(policies$policy2) |
      (policies$policy1 != policies$policy2), ])
  } else {
    return(policies)
  }
} # end policyDiff


# GUIDANCE ---------------------------------------------------------------------
guidanceDiff <- function(path1, path2, cycleend) {
  # wrapper for guidanceDiffMU (see function below) so you can just type in the
  # file paths
  #
  # INPUT
  # path1 : file path to guidance recommendation data 1 (csv)
  # path2 : file path to guidance recommendation data 2 (csv)
  # cycleend   : end of the cycle from the guidance recommendation data (csvs)
  #
  # OUTPUT
  # See output from guidanceDiffMU
  #
  # ASSUMPTIONS
  # path1 and path2 are CSV files
  # See assumptions for guidanceDiffMU
  
  # --- THE CODE 
  recs1 <- read.csv(path1, stringsAsFactors = FALSE)
  recs2 <- read.csv(path2, stringsAsFactors = FALSE)
  
  # Verify that the guidance is from the same cycle
  if ("recommenddate" %in% colnames(recs1)) {
    # the old format-- only one cycle per file
    cycle_recs1 <- substr(recs1$recommenddate[1], 1, 4)
    if (cycle_recs1 != cycleend) {
      error(paste("incorrect cycle:", recs1))
    }
  } else {
    if ("recommend_cycle" %in% colnames(recs1)) {
      # new format-- cumulative
      if (cycleend %in% recs1$recommend_cycle) {
        recs1 <- recs1[recs1$recommend_cycle == cycleend, ]
      } else {
        error(paste("incorrect cycle:", recs1))
      }
    }
  }
  
  if ("recommenddate" %in% colnames(recs2)) {
    # the old format-- only one cycle per file
    cycle_recs2 <- substr(recs2$recommenddate[1], 1, 4)
    if (cycle_recs2 != cycleend) {
      error(paste("incorrect cycle:", recs2))
    }
  } else {
    if ("recommend_cycle" %in% colnames(recs2)) {
      # new format-- cumulative
      if (cycleend %in% recs2$recommend_cycle) {
        recs2 <- recs2[recs2$recommend_cycle == cycleend, ]
      } else {
        error(paste("incorrect cycle:", recs2))
      }
    }
  }
  
  # Verify that management combinations are present
  if (!"mnt_comb" %in% colnames(recs1)) {
    mnt_comb <- apply(recs1[, c("transrec", "dormrec", "growrec")], 1, paste,
                      sep = "", collapse = ""
    )
    recs1 <- cbind(recs1, mnt_comb, stringsAsFactors = FALSE)
  }
  if (!"mnt_comb" %in% colnames(recs2)) {
    mnt_comb <- apply(recs2[, c("transrec", "dormrec", "growrec")], 1, paste,
                      sep = "", collapse = ""
    )
    recs2 <- cbind(recs2, mnt_comb, stringsAsFactors = FALSE)
  }
  
  # Get all MUs thare are represented in the data
  mu_ids <- union(recs1$munitid, recs2$munitid)
  diffs <- lapply(mu_ids, guidanceDiffMU, recs1, recs2)
  
  return(do.call(rbind, diffs))
} # end guidanceDiff

guidanceDiffMU <- function(munitid, recs1, recs2) {
  # Given a MU ID and two sets of guidance, find any differences
  # between recommendations for that MU between the two sets
  #
  # INPUT
  # munitid : management unit ID (numeric)
  # recs1   : Recommendation data 1 (data frame)
  # recs2   : Recommendation data 2(data frame)
  #
  # OUTPUT
  # Data frame containing management combinations that are recommended in
  # one data set but not the other. with a column to indicate
  # optimal / not optimal.
  #
  # ASSUMPTIONS
  # * recs1, recs2 have the following columns:
  #   munitid
  #   optimal
  #   mnt_comb
  #   recommenddate
  # * the transrec, dormrec, and growrec columns use the database encoding
  #   (0-10) for managment actions
  # *munitid appears in at least one of recs1, recs2
  #

  # --- THE CODE 

  # pull out the rows corresponding to munitid
  rows1 <- recs1[recs1$munitid == munitid, ]
  rows2 <- recs2[recs2$munitid == munitid, ]

  # If either rows1 or rows2 is empty, then all recommendations are different
  # between the two data sets
  if (nrow(rows1) == 0) {
    # the MU doesn't exist in recs1

    # build output data frame with all rows from rows2 and NA representing
    # rows1. from rows2:
    diffs <- rows2[, c("munitid", "mnt_comb", "optimal")]
    colnames(diffs) <- c("munitid", "rec2", "optimal")
    # from rows1:
    rec1 <- rep(NA, nrow(diffs))

    diffs <- cbind(diffs, rec1)
    return(diffs[, c("munitid", "rec1", "rec2", "optimal")])
  } else {
    if (nrow(rows2) == 0) {
      # the MU doesn't exist in recs2

      # build output data frame with all rows from rows1 and NA representing
      # rows1 from rows1
      diffs <- rows1[, c("munitid", "mnt_comb", "optimal")]
      colnames(diffs) <- c("munitid", "rec1", "optimal")
      # from rows2
      rec2 <- rep(NA, nrow(diffs))

      diffs <- cbind(diffs, rec2)
      return(diffs[, c("munitid", "rec1", "rec2", "optimal")])
    }
  } # end check for nonexistent MU in one data set

  # IF processing gets this far then the MU is present in both data sets
  # create object to hold output
  diffs <- NULL

  # check for different optimal recommendation
  if (as.numeric(rows1[rows1$optimal == 1, "mnt_comb"]) !=
    as.numeric(rows2[rows2$optimal == 1, "mnt_comb"])) {
    # optimal recommendations are different!!
    rec1 <- rows1[rows1$optimal == 1, "mnt_comb"]
    rec2 <- rows2[rows2$optimal == 1, "mnt_comb"]

    diff_row1 <- data.frame(munitid = munitid, rec1 = rec1, rec2 = NA, optimal = 1)
    diff_row2 <- data.frame(munitid = munitid, rec1 = NA, rec2 = rec2, optimal = 1)
    diffs <- rbind(diffs, diff_row1, diff_row2)
  }

  # check for different non-optimal recommendations
  # in data set 1 but not data set 2
  nonop1 <- setdiff(
    rows1[rows1$optimal == 0, "mnt_comb"],
    rows2[rows2$optimal == 0, "mnt_comb"]
  )
  # in data set 2 but not in data set 1
  nonop2 <- setdiff(
    rows2[rows2$optimal == 0, "mnt_comb"],
    rows1[rows1$optimal == 0, "mnt_comb"]
  )

  # pull the rows corresponding to the recommendations in nonop1, nonop2
  nonop1_rows <- rows1[rows1$mnt_comb %in% nonop1, ]
  nonop2_rows <- rows2[rows2$mnt_comb %in% nonop2, ]

  # For each of these, check whether it has any rows, and if so,
  # pad the other data set's columns with NA & append to diffs
  if (nrow(nonop1_rows) > 0) {
    diff <- nonop1_rows[, c("munitid", "mnt_comb", "optimal")]
    colnames(diff) <- c("munitid", "rec1", "optimal")
    # from rows2
    rec2 <- rep(NA, nrow(diff))

    diff <- cbind(diff, rec2)
    diff <- diff[, c("munitid", "rec1", "rec2", "optimal")]

    diffs <- rbind(diffs, diff)
  }

  if (nrow(nonop2_rows) > 0) {
    diff <- nonop2_rows[, c("munitid", "mnt_comb", "optimal")]
    colnames(diff) <- c("munitid", "rec2", "optimal")
    # from rows2
    state1 <- rep(NA, nrow(diff))
    rec1 <- rep(NA, nrow(diff))

    diff <- cbind(diff, rec1)
    diff <- diff[, c("munitid", "rec1", "rec2", "optimal")]

    diffs <- rbind(diffs, diff)
  }

  return(diffs)
} # end guidanceDiffMU





