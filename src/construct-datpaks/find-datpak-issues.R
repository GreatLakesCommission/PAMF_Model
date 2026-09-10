# 2021-07-02
#
# This script creates the datpak_issues dataframe, and populates it with any
# issues that may disqualify each data package from use in the transition
# matrix updates, partial controllability updates, or guidance assignment.
#
# Sourced by: construct-datpaks.R
#
# ASSUMPTIONS
# * The list of possible management actions has not changed since this script
#   was created
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND    : end year of PAMF cycle for this model run
#    CYCLE       : years defining the PAMF cycle
#    RUNPATH     : path to output directory for this model run
#    REPORTEND   : final date of reporting window (i.e. the database pull date
#                  in CYCLEEND)
#    REPORTBEGIN : First date or reporting window (i.e. the day after the
#                  database pull date in CYCLEEND-1)
#    Definitions for individual PAMF actions (see global-constants.R)
#
# * Variables
#    mon_data   : monitoring reports within CYCLE
#    mon_issues : monitoring issues reports within CYCLE
#    man_issues : management issues reports within CYCLE
#    mu_ids     : IDs of all MUs with at least one non-rejected report within
#    datpak     : data packages from the PAMF cycle
#
# * Functions
#    from datpak-functions.R:
#      getCycleByDate
#      pasteNoNA
#      
#      getNotIntendedMU
#    from file-io-special-cases.R:
#      readPreUpdateGuidance
#
# * Files in RUNPATH 
#    (the exact files needed depend on what cycle you're running)
#      guidance-NOT-UPDATED.csv
#      guidance-2018-10-05.csv
#      guidance-2019-08-22.csv
#      guidance-2020-09-15.csv
#      guidance-2021-08-25.csv
#      guidance-2022-08-23.csv
#      guidance-2023-08-15.csv
#      guidance-2024-08-21.csv
##

# ==============================================================================
#  WANT TO TEST THIS SCRIPT?
#  Uncomment the file reads for test data in construct-datpaks.R and run all
#  lines prior to the source command for this script
# ==============================================================================

# ==============================================================================
#  Create and populate dataframe to store issues associated with new data
#  packages
# ==============================================================================
datpak_issues <- data.frame(
  munitid = mu_ids,
  cycle_begin = rep(CYCLEEND - 1, n_rows),
  cycle_end = rep(CYCLEEND, n_rows),
  mon_begin_missing = rep(FALSE, n_rows),
  mon_begin_rej_model = rep(FALSE, n_rows),
  mon_begin_rej_guid = rep(FALSE, n_rows),
  mon_end_missing = rep(FALSE, n_rows),
  mon_end_rej_model = rep(FALSE, n_rows),
  mon_end_rej_guid = rep(FALSE, n_rows),
  t_act_missing = rep(FALSE, n_rows),
  t_act_extra = rep(FALSE, n_rows),
  d_act_missing = rep(FALSE, n_rows),
  d_act_extra = rep(FALSE, n_rows),
  g_act_missing = rep(FALSE, n_rows),
  g_act_extra = rep(FALSE, n_rows),
  has_rej_man = rep(FALSE, n_rows),
  wrong_comb = rep(FALSE, n_rows),
  no_guidance = rep(FALSE, n_rows),
  never_intended = rep(FALSE, n_rows),
  autoreject_model = rep(FALSE, n_rows),
  autoreject_partcontrol = rep(FALSE, n_rows)
)

# ==============================================================================
#  Check for and record the following data quality issues, along with any
#  'rejections' that they necessitate:
#
#   1.  Monitoring report missing, CYCLEEND-1
#   2.  Monitoring report rejected, CYCLEEND-1
#   3.  Monitoring report missing, CYCLEEND)
#   4.  Monitoring report rejected, CYCLEEND
#   5.  Management report missing, one or more phases
#   6.  Management report rejected, one or more phases
#   7.  One or more phases has more than one non-rest action reported
#   8.  Not a PAMF combination
#   9.  The MU did not receive guidance at the beginning of the cycle
#   10. The participant never intended to follow guidance for at least one
#       management action
#   11. The participant never intended to follow guidance because they are
#       following a management combo from PAMF Active Adaptive Management
#       (program starting in 2024)
#
# ==============================================================================

##  1. The monitoring report in the year CYCLEEND-1 is missing
#
##  2. The monitoring report in the year CYCLEEND-1 was withheld due to quality
#      issues
#
#   In each of these cases, we don't have enough information to determine which
#   row of the transition matrix to update. Withhold this data package from the
#   transition matrix update.
#
#   Note that rejected reports appear in mon_issues, but missing reports do
#   not appear anywhere (as they do not exist). To determine which data packages
#   have missing reports, first find the rejected reports.
##
rej_guid_begin <- mon_issues[mon_issues$monitor_year == (CYCLEEND - 1) &
  (mon_issues$coordreject_guid == TRUE |
    mon_issues$autoreject_guid == TRUE), "munitid"]
rej_mod_begin <- mon_issues[mon_issues$monitor_year == (CYCLEEND - 1) &
  (mon_issues$coordreject_model == TRUE |
    mon_issues$autoreject_model == TRUE), "munitid"]


# Only check against guidance rejections, because those are the ones that
# prevent the report from getting into the data package
nomonitor_begin <- setdiff(
  setdiff(mu_ids, rej_guid_begin),
  monitor[monitor$monitor_year == (CYCLEEND - 1), "munitid"]
)

# Record missing, rejected reports to datpak_issues
datpak_issues[
  datpak_issues$munitid %in% nomonitor_begin,
  c("mon_begin_missing", "autoreject_model")
] <- TRUE
datpak_issues[
  datpak_issues$munitid %in% rej_mod_begin,
  c("mon_begin_rej_model", "autoreject_model")
] <- TRUE
datpak_issues[
  datpak_issues$munitid %in% rej_guid_begin,
  c("mon_begin_rej_guid", "autoreject_model")
] <- TRUE


##  3. The monitoring report in the year CYCLEEND is missing
#
##  4. The monitoring report in the year CYCLEEND was withheld due to quality
#      issues
#
#   In each of these cases, we don't have enough information to determine which
#   column of the transition matrix to update. Withhold this data package from
#   the transition matrix update.
#
#   Note that rejected reports appear in mon_issues, but missing reports do
#   not appear anywhere (as they do not exist). To determine which data packages
#   have missing reports, first find the rejected reports.
##
rej_guid_end <- mon_issues[mon_issues$monitor_year == (CYCLEEND) &
  (mon_issues$coordreject_guid == TRUE |
    mon_issues$autoreject_guid == TRUE), "munitid"]
rej_mod_end <- mon_issues[mon_issues$monitor_year == (CYCLEEND) &
  (mon_issues$coordreject_model == TRUE |
    mon_issues$autoreject_model == TRUE), "munitid"]

# only check against guidance rejections, because those are the ones that
# prevent the report from getting into the data package
nomonitor_end <- setdiff(
  setdiff(mu_ids, rej_guid_end),
  monitor[monitor$monitor_year == (CYCLEEND), "munitid"]
)

# Record missing, rejected reports to datpak_issues
datpak_issues[
  datpak_issues$munitid %in% nomonitor_end,
  c("mon_end_missing", "autoreject_model")
] <- TRUE
datpak_issues[
  datpak_issues$munitid %in% rej_mod_end,
  c("mon_end_rej_model", "autoreject_model")
] <- TRUE
datpak_issues[
  datpak_issues$munitid %in% rej_guid_end,
  c("mon_end_rej_guid", "autoreject_model")
] <- TRUE


##  5. No management report exists for one or more phases of the cycle, either
#      because no report was submitted or because all reports for that phase
#      were rejected due to quality issues.
#
#   The reported combination is not a PAMF combination because it does not have
#   a reported action for every phase.
#
#   NOTE: the operations done in phase-date-agreement.R do NOT cause existing
#         management reports to be mislabeled as missing via phase reassignment.
#         Any report whose application dates all fall outside of the reported
#         phase is given a companion report with REST in that phase.
#
#   NOTE: the *reject columns in datpak_issues will be set once "wrong_comb"
#         is built out later on
##
man_missing <- unique(datpak[is.na(datpak$t_actions) | is.na(datpak$d_actions) |
  is.na(datpak$g_actions), "munitid"])

# Split missing reports out by phase and record to datpak_issues
t_missing <- datpak[
  datpak$munitid %in% man_missing & is.na(datpak$t_actions),
  "munitid"
]
d_missing <- datpak[
  datpak$munitid %in% man_missing & is.na(datpak$d_actions),
  "munitid"
]
g_missing <- datpak[
  datpak$munitid %in% man_missing & is.na(datpak$g_actions),
  "munitid"
]

datpak_issues[datpak_issues$munitid %in% t_missing, "t_act_missing"] <- TRUE
datpak_issues[datpak_issues$munitid %in% d_missing, "d_act_missing"] <- TRUE
datpak_issues[datpak_issues$munitid %in% g_missing, "g_act_missing"] <- TRUE


##  6. The MU originating the data package has one or more management reports
#      within the cycle that were rejected due to quality issues.
#
#   These reports are not recorded by phase in datpak_issues because:
#     * They may have conflicting phase-date information (they are not assigned
#       a model_phase because they don't go into the matrix updates)
#     * The existence of a rejected management report doesn't mean that the
#       data package doesn't have a PAMF combination-- that will depend upon
#       what other reports (if any) are submitted for each phase
#
#   Because a participant may submit any number of reports within a phase, we
#   can't tell by looking at *_actions whether any rejected management reports
#   have been prevented from appearing in that column
##

## To detect any rejected management reports that would otherwise be associated
#  with each data package, reconstruct each MU's cycle from man_data, by pulling
#  up all management reports between the monitoring dates that define the
#  beginning and end of the cycle
mr_cycles <- lapply(
  datpak$munitid, getCycleByDate,
  mon_data[mon_data$monitor_year %in% c(CYCLEEND - 1, CYCLEEND), ],
  man_data[man_data$manage_year %in% c(CYCLEEND - 1, CYCLEEND), ],
  CYCLEEND, REPORTBEGIN, REPORTEND
)

# Pull up all rejected management reports within the cycle, by MU
mr_reports <- do.call(rbind, mr_cycles)
mr_reports <- mr_reports[!is.na(mr_reports$treatmentid), "treatmentid"]
rej_ids <- man_issues[man_issues$treatmentid %in% mr_reports &
  (man_issues$coordreject_model == TRUE |
    man_issues$autoreject_model == TRUE), "munitid"]

datpak_issues[datpak_issues$munitid %in% rej_ids, c("has_rej_man")] <- TRUE

##  7. One or more phases has more than one non-rest actions reported
#      The reported combination is not a PAMF combination, i.e. we don't have a
#      transition matrix for it
#
# NOTE: The *reject columns will be set once "wrong_comb" is built out later on
##
all_actions <- c(
  GLYPH$model, IMAZ$model, GLYPHPLUS$model, REST$model, CUT$model,
  SPADING$model, PRECLEAR$model, MECHREMOVE$model, FLOOD$model,
  MECHLEAVE$model, OTHER$model, NA
)

t_extra <- datpak[!datpak$t_actions %in% all_actions, "munitid"]
d_extra <- datpak[!datpak$d_actions %in% all_actions, "munitid"]
g_extra <- datpak[!datpak$g_actions %in% all_actions, "munitid"]

datpak_issues[datpak_issues$munitid %in% t_extra, "t_act_extra"] <- TRUE
datpak_issues[datpak_issues$munitid %in% d_extra, "d_act_extra"] <- TRUE
datpak_issues[datpak_issues$munitid %in% g_extra, "g_act_extra"] <- TRUE

##  8. The management reports do not comprise a PAMF combination
#
#      The simplest way to compare implemented combinations against PAMF
#      combinations at the cycle level is to first condense each to a character
#      string. This works because PAMF combinations have only one action per
#      phase-- consequently there's no ambiguity about which action occurred
#      when.
#
#      Data packages with non-PAMF combinations are withheld from:
#        * Transition matrix update: transition matrices only exist for PAMF
#          combinations
#        * Partial controllability update: we only keep track of substitutions
#          for combinations that we can recommend as guidance.
##
combination_list <- split(
  datpak[, c("t_actions", "d_actions", "g_actions")],
  1:nrow(datpak)
)

mnt_comb <- lapply(combination_list, pasteNoNA)
wrong_comb <- !unlist(mnt_comb) %in% PAMF_COMBS$mnt_comb
datpak_issues[
  which(wrong_comb),
  c("wrong_comb", "autoreject_model", "autoreject_partcontrol")
] <- TRUE

## 9. No guidance given at the beginning of the cycle
#     We do not have the information needed to choose which row of the partial
#     controllability matrix to update. Withhold this data package from the PC
#     matrix update.
#
#     This situation arises for new management units that didn't exist at the
#     time of the previous guidance release, and for management units that
#     didn't have enough state information for guidance to be assigned at the
#     end of the previous cycle.
#
#     This code checks the last year we have an official guidance file from.
#     Additions to the list "GUIDANCE_FILES" in global-constants.R mean that
#     base_runs were conducted and official guidance will need to be pulled in.
#     For example, if you are running the model in 2026 and plan to run base
#     runs for all the previous years, you you will add the guidance file from
#     2025 to the list in GUIDANCE_FILES and the model will pull in all guidance
#     from 2025. However, if you are running the model then in 2027 and will NOT
#     be running base runs, you will NOT add the 2026 guidance file to
#     GUIDANCE_FILES and instead this code will pull in the guidance the normal
#     way, from last year's official run (2026 in this example).

# source function to handle special-case file reads
source("./src/run-model/file-io-special-cases.R")

if (CYCLEEND == 2018) {
  # Special case: first model run has no previous guidance
  
  datpak_issues$no_guidance <- TRUE
  datpak_issues$autoreject_partcontrol <- TRUE
  
} else {
  
  # Check the year of the last file in GUIDANCE_FILES
  last_base_year <- max(as.integer(names(GUIDANCE_FILES)))
  
  if ((CYCLEEND - 1) <= last_base_year) {
    # Previous guidance comes from an official guidance file
    
    print("find-datapak-issues.R - Base run detected - Using previous year's OFFICIAL guidance set autoreject_partcontrol")
    
    # Read the guidance that was actually released. When building from base runs,
    # this is generally not the same as the guidance in the previous base run.
    
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
    # Previous guidance comes from cumulative guidance history
    
    print("find-datapak-issues.R - Using previous year's guidance set autoreject_partcontrol")
    
    old_guidance <- read.csv(
      paste0(RUNPATH, "guidance-NOT-UPDATED.csv")
    )
    
    # Get the previous cycle's guidance
    prev_guidance <- old_guidance[
      old_guidance$recommend_cycle == CYCLEEND - 1,
    ]
    
    rm(old_guidance)
  }
  
  # Find MUs that did not receive guidance in the previous cycle
  pg_mus <- prev_guidance$munitid
  
  # Set autoreject_partcontrol to TRUE for MUs that did not receive guidance in
  # the previous cycle
  datpak_issues[
    !datpak_issues$munitid %in% pg_mus,
    c("no_guidance", "autoreject_partcontrol")
  ] <- TRUE
  
  rm(prev_guidance, pg_mus)
}

## 10. The participant never intended to follow guidance for at least one
#      management action
#
#      It is not uncommon for participants to join PAMF with the intent of
#      contributing to collective learning without using the guidance themselves.
#
#      In cases where participants never intended to follow guidance for at least
#      one action in their data package, don't use their data for partial
#      controllability
##

not_intended <- unlist(lapply(cycle_list, getNotIntendedMU))
datpak_issues[
  datpak_issues$munitid %in% not_intended,
  c("never_intended", "autoreject_partcontrol")
] <- TRUE

## 11. The participant is part of the PAMF Active Adaptive Management Program
#      (AAMP) starting in 2024 and will not be following guidance because 
#      they are following only the combination they signed up to follow

AAMP_MUs <- getAAMP_MU(PAMFDATA$enroll)
datpak_issues[
  datpak_issues$munitid %in% AAMP_MUs,
  c("never_intended", "autoreject_partcontrol")
] <- TRUE

# ==============================================================================
# Clean up
# ==============================================================================
rm(
  rej_mod_begin, rej_guid_begin, nomonitor_begin, rej_mod_end, rej_guid_end,
  nomonitor_end, man_missing, t_missing, d_missing, g_missing, mr_cycles,
  mr_reports, rej_ids, t_extra, d_extra, g_extra, combination_list, mnt_comb,
  wrong_comb, not_intended, all_actions, AAMP_MUs
)
