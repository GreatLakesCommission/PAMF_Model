# 2021-06-08
#
# Builds data packages from a given set of non-rejected reports.

# Process for constructing data packages:
# 1. Create a data frame with a row for every MU that has at least one
#    non-rejected report* and populate with munitids, cycle years
# 2. Add columns: begin/end state, establishment and density probabilities
# 3. Add columns: management actions in each phase
# 4. Swap equivalent actions between PRECLEAR, MECHLEAVE, MECHREMOVE wherever
#    doing so will turn a non-PAMF combination into a PAMF combination
#    Record these changes in man_changes
# 4. Add columns: management combination
#
# * What constitutes a non-rejected report depends upon the report type
# For monitoring reports:
#   Non-rejected reports are those with coordreject_guid==FALSE and
#   autoreject_guid==FALSE. It's possible for reports to be high enough quality
#   to receive guidance but not high enough quality to be included in the model
#   update.
#     e.g. monitoring report 1569
#          Establishment is 51-100%, and stem counts are 9, 2, 0, 11, 10
#          The zero stem count suggests that the participant did not follow
#          protocol, however, for this MU to have high density, the relocated
#          quadrat 3 would need to have a stem count of 18 or higher. So the MU
#          is probably in State 5, although there's a chance that it's in
#          State 6 and the guidance for State 5 may not be aggressive enough.
#          In this case, the coordinator decided that this is not sufficient
#          reason to withhold guidance from the MU.
#   For management reports:
#     Non-rejected reports are those with coordreject_model==FALSE and
#     autoreject_model==FALSE
#     i.e. those that contribute to the matrix updates
#
#
# Sourced by: construct-datpaks.R
#
# DEPENDENCIES:
# * Global Constants
#    CYCLEEND   : end year of PAMF cycle for this model run
#    CYCLE      : years defining the PAMF cycle
#    LODENS_MAX : Maximum quadrat-scale stem count for low density states
#    RUNPATH    : path to output directory for this model run
#    REPORTEND  : final date of reporting window (i.e. the database pull date
#                 in CYCLEEND)
#    REPORTBEGIN : First date or reporting window (i.e. the day after the
#                  database pull date in CYCLEEND-1)
#    Definitions for PAMF actions (see global-constants.R)
#      Hard-coded actions include REST, FLOOD, PRECLEAR, MECHLEAVE, MECHREMOVE
#
# * Variables
#    mon_data    : monitoring reports within CYCLE
#    man_data    : management reports within CYCLE
#    enroll_data : enrollment reports, all years
#    mon_issues  : monitoring issues reports within CYCLE
#    man_issues  : management issues reports within CYCLE
#    monitor     : non-rejected monitoring reports within CYCLE
#    manage      : non-rejected management reports within CYCLE, merged with the
#                  date that the MU was monitored in manage_year
#    mu_ids      : IDs of all MUs with at least one non-rejected report within
#                  CYCLE
#    n_rows      : number of rows to create for datpak, datpak_issues
#
# * Functions:
#    from datpak-functions.R:
#      getState
#      getDensProbs
#      getCycle
#      getMntComb
#      swapPLB
##

# ==============================================================================
#  WANT TO TEST THIS SCRIPT?
#  Uncomment the file reads for test data in construct-datpaks.R and run all
#  lines prior to the source command for this script
# ==============================================================================

# ==============================================================================
#  Create dataframe to store new data packages
# ==============================================================================
datpak <- data.frame(
  munitid = mu_ids,
  cycle_begin = rep(CYCLEEND - 1, n_rows),
  cycle_end = rep(CYCLEEND, n_rows)
)


# ==============================================================================
#  Add state information from monitoring reports
#    * states at the start/end of CYCLE
#    * % establishment, stem density probabilities
#
#  NOTE: The approach below assumes that there is at most one monitoring report
#        per MU per year.
#        VERIFIED FOR 2018: only deleted MUs had more than one monitoring report
#        VERIFIED FOR 2019: Only MU 269 has more than one monitoring report.
#                           But we're already ignoring it because it's inactive
#        2020 ONWARD: WebHub does not allow participants to submit more than one
#                     monitoring report per year. If they need to update
#                     monitoring data, they are able to edit the existing report
#                     until the August deadline.
# ==============================================================================

## Get each MU's beginning and end state
states_begin <- getState(
  monitor[monitor$monitor_year == CYCLEEND - 1, ], LODENS_MAX
  )
colnames(states_begin)[which(
  colnames(states_begin) == "state"
  )] <- "state_begin"
states_end <- getState(monitor[monitor$monitor_year == CYCLEEND, ], LODENS_MAX)
colnames(states_end)[which(colnames(states_end) == "state")] <- "state_end"


## Merge beginning, end states onto datpak
datpak <- merge(datpak, states_begin[, c("munitid", "state_begin")],
  by = "munitid",
  all.x = TRUE
)
datpak <- merge(datpak, states_end[, c("munitid", "state_end")],
  by = "munitid",
  all.x = TRUE
)


## Transition matrix updates are based on the probability that the MU is in each
#  state at the end of the cycle. States are defined by %establishment and
#  stem density.
#  Populate and add columns to hold the probabilities that:
#   * Establishment is in the 0-10%, 11-50%, or 51-100% category
#   * Stem density is high or low
#  at both the beginning and the end of the cycle.
##
state_probs <- data.frame(
  munitid = datpak$munitid,
  pr_est0_begin = rep(NA, n_rows),
  pr_est1_begin = rep(NA, n_rows),
  pr_est2_begin = rep(NA, n_rows),
  pr_lo_begin = rep(NA, n_rows),
  pr_hi_begin = rep(NA, n_rows),
  pr_est0_end = rep(NA, n_rows),
  pr_est1_end = rep(NA, n_rows),
  pr_est2_end = rep(NA, n_rows),
  pr_lo_end = rep(NA, n_rows),
  pr_hi_end = rep(NA, n_rows)
)


## Establishment Probabilities
#  There is no quantifiable uncertainty around %establishment because it is
#  only measured once per report. Consequently, all %establishment columns
#  contain either 0 or 1.
##

# Establishment at the beginning of the cycle
est0_begin <- monitor[which(monitor$establishment == 0 & monitor$monitor_year ==
  (CYCLEEND - 1)), "munitid"]
est1_begin <- monitor[which(monitor$establishment == 1 & monitor$monitor_year ==
  (CYCLEEND - 1)), "munitid"]
est2_begin <- monitor[which(monitor$establishment == 2 & monitor$monitor_year ==
  (CYCLEEND - 1)), "munitid"]

state_probs[state_probs$munitid %in% est0_begin, "pr_est0_begin"] <- 1
state_probs[state_probs$munitid %in% est0_begin, "pr_est1_begin"] <- 0
state_probs[state_probs$munitid %in% est0_begin, "pr_est2_begin"] <- 0

state_probs[state_probs$munitid %in% est1_begin, "pr_est0_begin"] <- 0
state_probs[state_probs$munitid %in% est1_begin, "pr_est1_begin"] <- 1
state_probs[state_probs$munitid %in% est1_begin, "pr_est2_begin"] <- 0

state_probs[state_probs$munitid %in% est2_begin, "pr_est0_begin"] <- 0
state_probs[state_probs$munitid %in% est2_begin, "pr_est1_begin"] <- 0
state_probs[state_probs$munitid %in% est2_begin, "pr_est2_begin"] <- 1

# Establishment at the end of the cycle
est0_end <- monitor[which(monitor$establishment == 0 & monitor$monitor_year ==
  (CYCLEEND)), "munitid"]
est1_end <- monitor[which(monitor$establishment == 1 & monitor$monitor_year ==
  (CYCLEEND)), "munitid"]
est2_end <- monitor[which(monitor$establishment == 2 & monitor$monitor_year ==
  (CYCLEEND)), "munitid"]

state_probs[state_probs$munitid %in% est0_end, "pr_est0_end"] <- 1
state_probs[state_probs$munitid %in% est0_end, "pr_est1_end"] <- 0
state_probs[state_probs$munitid %in% est0_end, "pr_est2_end"] <- 0

state_probs[state_probs$munitid %in% est1_end, "pr_est0_end"] <- 0
state_probs[state_probs$munitid %in% est1_end, "pr_est1_end"] <- 1
state_probs[state_probs$munitid %in% est1_end, "pr_est2_end"] <- 0

state_probs[state_probs$munitid %in% est2_end, "pr_est0_end"] <- 0
state_probs[state_probs$munitid %in% est2_end, "pr_est1_end"] <- 0
state_probs[state_probs$munitid %in% est2_end, "pr_est2_end"] <- 1


## Density Probabilities
#  Each time a MU is monitored, participants count stems in five quadrats. The
#  probability that the MU has high density is the number of quadrats whose
#  count exceeds LODENS_MAX, divided by the total number of quadrats with stem
#  counts (There may be fewer than 5 of these: Participants can leave them
#  blank)
##

## Convert each year's monitoring data to a list of reports, ordered by munitid
#  Note: because only one monitoring report can be filed per MU per year,
#  elements of these lists never contain more than one report
monitor_begin <- split(
  monitor[monitor$monitor_year == CYCLEEND - 1, ],
  monitor[monitor$monitor_year == CYCLEEND - 1, "munitid"]
)
monitor_end <- split(
  monitor[monitor$monitor_year == CYCLEEND, ],
  monitor[monitor$monitor_year == CYCLEEND, "munitid"]
)

## Get density probabilities and convert to data frame
dens_begin <- lapply(monitor_begin, getDensProbs)
dens_begin <- do.call(rbind, dens_begin)
dens_end <- lapply(monitor_end, getDensProbs)
dens_end <- do.call(rbind, dens_end)

state_probs[
  state_probs$munitid %in% dens_begin$munitid,
  "pr_lo_begin"
] <- dens_begin$prob_lo
state_probs[
  state_probs$munitid %in% dens_begin$munitid,
  "pr_hi_begin"
] <- dens_begin$prob_hi

state_probs[
  state_probs$munitid %in% dens_end$munitid,
  "pr_lo_end"
] <- dens_end$prob_lo
state_probs[
  state_probs$munitid %in% dens_end$munitid,
  "pr_hi_end"
] <- dens_end$prob_hi

datpak <- cbind(
  datpak, state_probs[, setdiff(colnames(state_probs), "munitid")])


# ==============================================================================
#   Add management information to data packages:
#    * All actions performed in each phase
#    * Management combination
# ==============================================================================

## Define the columns needed to populate the management side of datpak
#  Note: the "dateentered" column was not introduced until 2020
if ("dateentered" %in% colnames(manage)) {
  cycle_cols <- c(
    "applicationid", "treatmentid", "munitid", "model_phase",
    "treatmethod", "applicationdate", "dateentered", "managementdate",
    "pretechnique", "preremove", "followreason"
  )
} else {
  cycle_cols <- c(
    "applicationid", "treatmentid", "munitid", "model_phase",
    "treatmethod", "applicationdate", "managementdate",
    "pretechnique", "preremove", "followreason"
  )
}

## Get all (non-rejected) management reports within CYCLE, for each MU
cycle_list <- lapply(
  datpak$munitid, getCycle, manage, CYCLEEND, REPORTBEGIN,
  REPORTEND, cycle_cols
)

# cycle_list<<-cycle_list # uncomment to make visible after app exits

## --- Remove all reports not from the current cycle from man_changes ----------
cycle_reports <- do.call(rbind, cycle_list)

# Add temporary id column-- an inner merge on these two columns will not work
# for some reason
cycle_reports$treatappid <- paste0(
  cycle_reports$treatmentid, "_", cycle_reports$applicationid
  )
man_changes$treatappid <- paste0(
  man_changes$treatmentid, "_", man_changes$applicationid
  )

man_changes <- man_changes[which(
  man_changes$treatappid %in% cycle_reports$treatappid
), ]

man_changes$treatappid <- NULL

## --- Build management combinations -------------------------------------------
#  Get the management actions (model code) in each data package by phase &
#  append to datpak
#  The commands below rely on the fact that cycle_list is in the same order as
#  datpak$munitid
##
act_by_phase <- lapply(cycle_list, getMntComb)
act_by_phase <- do.call(rbind, act_by_phase)
datpak <- cbind(datpak, act_by_phase)


# =============================================================================
#  Convert between PRECLEAR, MECHLEAVE, and MECHREMOVE actions
#
#  Some non-PAMF combinations are equivalent to PAMF combinations. These may
#  arise when:
#   * PRECLEAR is followed by REST
#   * Either mechanical action is followed by FLOOD
#
#  The reason this happens is that FLOOD (or lack thereof) can be unpredictable.
#  Since each Mechanical action is essentially a special case of PRECLEAR
#  AND the management reports contain the information that tells us which,
#  we can reconstruct a PAMF combination from PRECLEAR if FLOOD
#  doesn't happen (or from either mechanical action if it does unexpectedly)
#  Doing so prevents us from throwing away valid data!
# ==============================================================================

## Get the indices of packages in cycle_list which meet the above criteria, and
#  run those packages through swapPLB. Repair the dormant action to improve the
#  chance that the management combination is a PAMF combination
#
#  Do this for both the model (character) and database (numeric) encodings:
#  We'll use the former in datpak and the latter in manage_changes
##
plb_reports <- which(
  (datpak$d_actions %in% c(MECHREMOVE$model, MECHLEAVE$model) &
  datpak$g_actions == FLOOD$model) |
  (datpak$d_actions == PRECLEAR$model & datpak$g_actions !=
    FLOOD$model))
dorm_repaired_model <- unlist(lapply(cycle_list[plb_reports], swapPLB,
  code = "character"
))
dorm_repaired_db <- unlist(lapply(cycle_list[plb_reports], swapPLB,
  code = "numeric"
))

datpak[plb_reports, "d_actions"] <- dorm_repaired_model


## Record any changes in management action to man_changes
#  Recall that man_changes was created during find-manage-issues, when
#  phase-date-agreement.R was sourced. It contains a record of all repairs made
#  to management reports.
##

# Create a data frame containing the reports that underwent a P/LB swap. Note
# that the swap applies to dormant actions only
plb_reports_df <- do.call(rbind, cycle_list[plb_reports])
plb_reports_df <- plb_reports_df[plb_reports_df$model_phase == DORMANT$code, ]


## There may be more than one dormant report per MU (e.g. two PRECLEAR reports)
#  duplicate dorm_repaired where necessary
if (!is.null(plb_reports_df)) {
  if (nrow(plb_reports_df) > length(dorm_repaired_db)) {
    actions_to_duplicate <- dorm_repaired_db[which(
      duplicated(plb_reports_df$munitid)) - 1]

    dr2 <- rep(NA, nrow(plb_reports_df))
    dr2[which(!duplicated(plb_reports_df$munitid))] <- dorm_repaired_db
    dr2[which(duplicated(plb_reports_df$munitid))] <- actions_to_duplicate

    dorm_repaired_db <- dr2
    rm(dr2, actions_to_duplicate)
  }
}

## Now populate the treatmethod column with the repaired reports
plb_reports_df[, "treatmethod"] <- dorm_repaired_db

## Write information to man_changes
man_changes[
  man_changes$applicationid %in% plb_reports_df$applicationid,
  "action_reassign"
] <- TRUE
man_changes[
  man_changes$applicationid %in% plb_reports_df$applicationid,
  "model_action"
] <- plb_reports_df$treatmethod


# ==============================================================================
#  Add management combination column to data packages
#
#  This information will be used in transition matrix update and partial
#  controllability update
# ==============================================================================

mnt_combs <- split(
  datpak[, c("t_actions", "d_actions", "g_actions")],
  datpak$munitid)
mnt_comb <- lapply(mnt_combs, pasteNoNA)
mnt_comb <- do.call(rbind, mnt_comb)
datpak <- cbind(datpak, mnt_comb)

# ==============================================================================
#  Clean up empty data packages
#   
#  "Empty" data packages do not have state_begin, state_end, or management
#   action information and were only created because some management reports
#   were in the manage years but not in the cycle for those years (e.g., cycle =
#   2019-2020, there is a management report for July 2019 but it was in the
#   2018-2019 cycle based on the date of the monitoring report, and no other
#   reports were turned in after that.)
# ==============================================================================

datpak <- datpak[!with(datpak, is.na(state_begin) & 
                       is.na(state_end) & 
                       is.na(t_actions) & 
                       is.na(d_actions) & 
                       is.na(g_actions)), ]

# Update mu_ids and n_rows so that only the correct munitids are used in 
# find_datpak_issues.R
mu_ids <- datpak$munitid
n_rows <- length(mu_ids)

# ==============================================================================
# Clean up
# ==============================================================================

# Remove temporary variables (datpak)
rm(
  cycle_reports, states_begin, states_end, state_probs, est0_begin, est1_begin,
  est2_begin, est0_end, est1_end, est2_end, monitor_begin, monitor_end, 
  dens_begin, dens_end, act_by_phase, plb_reports, dorm_repaired_model, 
  cycle_cols, dorm_repaired_db, plb_reports_df, mnt_combs, mnt_comb
)
