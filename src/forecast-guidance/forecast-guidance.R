# 2020-12-09
#
# Script that generates forecast guidance
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global constants:
#    CYCLEEND  : the year of MCFG release (generally the final year of the
#                current cycle)
# * Variables:
#    midcycle     : midcycle reports from current cycle
#    midcy_issues : problems with midcycle reports
#    enroll       : enrollment reports
#    datpak       : data packages constructed during the previous model run
#    policies     : optimal guidance outcomes from previous model run
#    transition   : most recent transition information from previous model run
#                   (i.e. not cumulative), in dataframe format
#    action_restrictions : data frame describing which management actions can
#                          be taken under each management restriction
#
# * Functions
#   From midcycle-functions.R:
#    tidyStates
#    getMCFGs
#   From optimizer.R:
#    convertTP
#
# ASSUMPTIONS
# * All MUs in midcycle have a usable monitoring report from the beginning
#   of the current cycle
##

# # ============================================================================
# #   Uncomment this section for script testing
# # ============================================================================
# message(">>> USING TEST DATA FOR GUIDANCE FORECAST <<<")
# options(stringsAsFactors=FALSE)
#
# ## DO THIS FIRST!
# #  In order to get midcycle, midcy_issues, and enroll, run find-midcycle-issues.R
# #  in test mode before running this script!
# ##
#
# CYCLEEND  = 2526
# PREVCYCLE = 2525
# PREVPATH  = "./src/forecast-guidance/test-cases/prevrun-test"
#
# datpak = read.csv("./src/forecast-guidance/test-cases/prevrun-test/datpak.csv")
# datpak = datpak[datpak$cycle_end==PREVCYCLE,]
#
# transitions = read.csv("./src/forecast-guidance/test-cases/prevrun-test/transition_matrices.csv")
# transitions = transitions[transitions$cycle_used==PREVCYCLE,]
#
# policies    = read.csv("./src/forecast-guidance/test-cases/prevrun-test/policies.csv")
# policies=policies[policies$cycle_end==PREVCYCLE,]
#
# action_restrictions =  read.csv("./src/policy_definitions2018-07-31.csv")
##

# ==============================================================================
#   Source optimization functions
# ==============================================================================
source("./src/run-model/optimizer-functions.R")
# optimizer.R contains functions that:
#   * convert transition matrices between table and matrix format
#   * find management combinations allowed under each policy restriction


# ==============================================================================
#  Build a data frame containing MU-specific information necessary to
#  generate MCFG:
#
#  * munitid      : MU ID number
#  * mcombination : planned management combination
#  * restr_id     : ID of managment restriction that applies to the MU (database
#                   encoding)
#  * mnt_planned  : same but with model encoding
#  * state        : ID of possible state
#  * pr_state     : probability that MU is in that state
#
#  Recall that we use the multiple stem counts to assess uncertainty around the
#  MU's state at the time of monitoring, but that there is no uncertainty in
#  percent establishment (which is recorded in one observation only).
#  Consequently, a MU may be in one of two states, with a probability based on
#  the number of quadrats with high/low stem density.
#  We incorporate both of these possibilities into MCFG.
# ==============================================================================

# MU IDs
munitid <- midcy_issues[midcy_issues$autoreject_guid == FALSE, "munitid"]


# Planned management combination (model encoding)
mcombination <- midcycle[
  midcycle$munitid %in% munitid,
  c("munitid", "mcombination")
]
comb_key <- merge(data.frame(mcombination), PAMF_COMBS[, c("mc_db", "mnt_comb")],
  by.x = "mcombination", by.y = "mc_db"
)
colnames(comb_key)[which(colnames(comb_key) == "mnt_comb")] <- "mnt_planned"


# Management Restrictions
mu_restr <- enroll[enroll$munitid %in% munitid, c(
  "munitid", "herbicide", "cut",
  "controlwater"
)]

# Pull one row defining each restriction combination from action_restrictions to
# use in merge
restrictions <- unique(action_restrictions[, c(
  "restr_id", "herbicide", "cut",
  "controlwater"
)])
mu_restr <- merge(mu_restr,
  restrictions[, c("herbicide", "cut", "controlwater", "restr_id")],
  by = c("herbicide", "cut", "controlwater")
)


# Probability that MU is in any given state
# use the *end columns of datpak because they describe the most recent monitoring
# outcomes
datpak <- datpak[datpak$munitid %in% munitid, ] # keep only non-rejected MU data
pr_s1 <- datpak$pr_est0_end * datpak$pr_lo_end # probability of low est, low dens
pr_s2 <- datpak$pr_est0_end * datpak$pr_hi_end # probability of low est, high dens
pr_s3 <- datpak$pr_est1_end * datpak$pr_lo_end # etc
pr_s4 <- datpak$pr_est1_end * datpak$pr_hi_end
pr_s5 <- datpak$pr_est2_end * datpak$pr_lo_end
pr_s6 <- datpak$pr_est2_end * datpak$pr_hi_end

# convert from wide format to long format
all_probs <- data.frame(munitid, pr_s1, pr_s2, pr_s3, pr_s4, pr_s5, pr_s6)
prob_rows <- split(all_probs, all_probs$munitid)

pr_by_state <- lapply(prob_rows, tidyStates)
pr_by_state <- do.call(rbind, pr_by_state)


# Assemble all columns into dataframe
manage_cols <- merge(comb_key, mu_restr[, c("munitid", "restr_id")], by = "munitid")

mcfg_data <- merge(pr_by_state, manage_cols, by = "munitid", all.x = TRUE)

# ==============================================================================
#  Generate MCFG
#  i.e. Get a set of management combinations that are weighted by the likelihood
#       of being optimal in August if no new information were incorporated*.
#       The highest-weighed combination is MCFG; the others are possible back-up
#       options.
#
#  The guidance that we send to participants depends upon:
#  (1) The MU's state at the end of the current cycle. Because that information
#      is not known at midcycle, we make a guess based on the most recent set
#      of transition matrices:
#
#                    pr(Si_end) = sum(pr(Sj_begin)*t_ji, over all j)
#
#      i.e. the probability that the MU will be in state_i at the end of the
#           cycle depends upon the probability that it's currently in state j,
#           and on the probability of transition between states j and i.
#  (2) Which management combination is optimal for each final state. This
#      is follows from (a) the most recent optimization and (b) the management
#      restrictions that apply to the MU
#
#                    pr(mcfg) = sum(pr(Si_end)*optimal(Si), over all i)
#
#      i.e. The probability that a combination is the one you want to recommend
#           (i.e. the combination's MCFG weight)* is the sum of the probabilities
#           of states where that combination is optimal in the most recent policy
#           set.
#
# * The MCFG weight is NOT the same as the probability that the combination will
#   be the optimal guidance in August, because the transition probabilities may
#   change during the next model run and may therefore affect the outcomes of
#   the August optimization
# ==============================================================================

## The MCFG calculations iterate first over the planned management combination
#  then by munitid within each planned combination. This means that we only
#  have to pull up each transition matrix once
##

## Sort mcfg_data by mnt_planned so that the transition matrices and the split
#  come out in the same order
mcfg_data <- mcfg_data[order(mcfg_data$mnt_planned), ]

## Convert transitions to matrix format. This approach is a bit simpler to
#  follow than keeping it in table format
##
mnt_planned <- unique(mcfg_data$mnt_planned)
transition_matrices <- lapply(mnt_planned, convertTP, transitions, STATES)
names(transition_matrices) <- mnt_planned

# Split mcfg_data into a list of data frames with one planned combination each
mcfg_list <- split(mcfg_data, mcfg_data$mnt_planned)


## Get MCFG: For the MUs within each management combination group, find the
#  probability that each possible management combination will be optimal
#  (assuming no further learning-- next year's learning may affect the transition
#  probabilities in ways we can't predict here)
##
mcfg <- mapply(getMCFGs, mcfg_list, transition_matrices,
  MoreArgs = list(policies),
  SIMPLIFY = FALSE
)
names(mcfg) <- NULL
mcfg <- do.call(rbind, mcfg)
mcfg <- mcfg[mcfg$mcfg_weight > 0, ]
mcfg <- mcfg[order(mcfg$munitid), ]

## Format mfg for output
#  Remove mnt_comb and add date columns
#  Rename the guidance columns
##
recommend_cycle <- rep(CYCLEEND, nrow(mcfg))
recommenddate <- as.character(Sys.Date())

mcfg <- cbind(
  mcfg[, setdiff(colnames(mcfg), "mnt_comb")],
  recommend_cycle, recommenddate
)

colnames(mcfg)[which(colnames(mcfg) == "db_tloc")] <- "transrec"
colnames(mcfg)[which(colnames(mcfg) == "db_dorm")] <- "dormrec"
colnames(mcfg)[which(colnames(mcfg) == "db_grow")] <- "growrec"

mcfg$mcfg_weight <- round(mcfg$mcfg_weight, 4)


# ==============================================================================
#  Clean up temporary variables
# ==============================================================================
suppressWarnings(rm(
  transitions, policies, action_restrictions, datpak, munitid,
  mcombination, comb_key, mu_restr, restrictions,
  pr_s1, pr_s2, pr_s3, pr_s4, pr_s5, pr_s6, all_probs,
  prob_rows, pr_by_state, manage_cols, mnt_planned, mcfg_data,
  transition_matrices, mcfg_list
))
# Some of these variables are created inside of conditional and may not exist
# every time this script is run
