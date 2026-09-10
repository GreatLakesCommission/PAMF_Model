# 2020-12-10
#
# This script creates a midcycle_issues dataframe, and populates it with any
# issues that may disqualify each report from midcycle forecast guidance or
# prompt a notification when contradiction occur that diminish the usefulness
# of MCFG.
#
# Whether these issues arise depends (in most cases) upon the information in the
# midcycle report as well as information in another set of reports (enrollment,
# monitoring, management).
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global constants
#    CYCLEEND      : the year of MCFG release (generally the final year of the
#                    current cycle)
#    PAMF_COMBS    : comprehensive map between different codes representing
#                    the management actions and combinations recognized by PAMF
#    TRANSLOCATING : translocating phase definition
#    DORMANT       : dormant phase definition
#    OTHER         : list with an element named db that contains the web hub's
#                    encoding of 'other' management action
# * Variables
#   * enroll     : enrollment reports (all years)
#   * midcycle   : current-year midcycle reports
#   * mon_issues : monitor-issues reports created during the previous model run
#                  (most recent monitoring only, not cumulative)
#
# * Functions
#   From midcycle-functions.R:
#
# ASSUMPTIONS
#  * midcycle only contains rows relevant to the current cycle
#  * manage only contains reports submitted after the August data pull
#
##

# # ==============================================================================
# #   Uncomment this section for script testing
# # ==============================================================================
# message(">>> USING TEST DATA FOR FIND-MIDCYCLE-ISSUES <<<")
# options(stringsAsFactors=FALSE)
#
# source("./src/global-constants.R")
# source("./src/format-functions.R")
# source("./src/forecast-guidance/midcycle-functions.R") sourced in app.R
#
# CYCLEEND = 2526
# PREVPATH = "./src/forecast-guidance/test-cases/prevrun-test/"
#
# # midcycle reports
# midcycle = read.csv("./src/forecast-guidance/test-cases/midcycle-test.csv")
#
# # run the formatting step
# midcycle = formatMidcycle(midcycle, CYCLEEND)
#
# # monitor issues
# mon_issues = read.csv(paste0(PREVPATH, "monitor_issues.csv"))
#
# # keep only reports from the end of the previous cycle
# mon_issues = mon_issues[mon_issues$cycle_end==CYCLEEND-1,]
#
# # Since the formatting process for the enrollment and management reports is
# # tested elsewhere, the supporting reports for the midcycle test cases are
# # pre-formatted
#
# # enrollment reports
# enroll = read.csv(paste0(PREVPATH, "enroll.csv"))
#
# # management reports
# manage = read.csv(paste0(PREVPATH, "manage.csv"))
#
# action_restrictions =  read.csv("./src/policy_definitions2018-07-31.csv")


# ==============================================================================
#  Create new empty midcycle_issues rows
#  (these will be appended to the cumulative history later on)
# ==============================================================================

n_rows <- nrow(midcycle) # each midcycle report is one row
cycle_rows <- data.frame(
  midcycleid = midcycle$midcycleid,
  munitid = midcycle$munitid,
  cycle_end = rep(CYCLEEND, n_rows),
  grow_report = rep(FALSE, n_rows),
  mon_missing = rep(FALSE, n_rows),
  mon_rejected = rep(FALSE, n_rows),
  incompatible_restrict = rep(FALSE, n_rows),
  incompatible_manage = rep(FALSE, n_rows),
  autoreject_guid = rep(FALSE, n_rows)
)
cycle_rows <- cycle_rows[order(cycle_rows$munitid), ] # sort by munitid


# ==============================================================================
# Check reports for the following issues:
#
# 1. A growing report has already been submitted for the current cycle
# 2. No monitoring report was submitted for the MU at the end of the previous
#    cycle
# 3. The monitoring report submitted for the MU at the end of the previous cycle
#    was rejected from guidance release due to quality problems
# 4. The planned combination is incompatible with the MU's management
#    restrictions
# 5. The planned combination is incompatible with action(s) that have already
#    been taken
# ==============================================================================

## 1. A growing report has already been submitted for the current cycle
#     This is an anomaly because at the usual time of the MCFG run (January),
#     the GROWING phase hasn't started yet. Set the grow_report column to TRUE
##
grow_reports <- midcycle[midcycle$growtaken == 1, "midcycleid"]
cycle_rows[cycle_rows$midcycleid %in% grow_reports, "grow_report"] <- TRUE


## 2. No monitoring report was submitted for the MU at the end of the previous
#    cycle
#    If so, we cannot generate MCFG
##
monitored_mus <- mon_issues[mon_issues$munitid %in% midcycle$munitid, "munitid"]
cycle_rows[
  !cycle_rows$munitid %in% monitored_mus,
  c("mon_missing", "autoreject_guid")
] <- TRUE


## 3. The monitoring report submitted for the MU at the end of the previous
#     cycle was rejected from guidance release due to quality problems
#     If so, we cannot generate MCFG
##
mon_rejected <- mon_issues[mon_issues$coordreject_guid == TRUE |
  mon_issues$autoreject_guid == TRUE, "munitid"]
cycle_rows[
  cycle_rows$munitid %in% mon_rejected,
  c("mon_rejected", "autoreject_guid")
] <- TRUE


## 4. The planned combination is incompatible with the MU's management
#     restrictions
#     If so, set incompatible_restrict to TRUE
##

# Create a data frame that links the munitid of MUs in midcycle with:
#  * restrictions on actions possible in the MU (enroll)
#  * ID# of MU's combination of restrictions (action_restrictions)
#  * character code describing the planned management combination (PAMF_COMBS)
mu_restr <- midcycle[, c("munitid", "mcombination")]
mu_restr <- merge(mu_restr,
  enroll[, c("munitid", "herbicide", "cut", "controlwater")],
  by.x = "munitid", by.y = "munitid"
)

# Get one row from action_restrictions for each restr_id
restrictions <- unique(action_restrictions[, c(
  "restr_id", "herbicide", "cut",
  "controlwater"
)])
mu_restr <- merge(mu_restr,
  restrictions[, c("herbicide", "cut", "controlwater", "restr_id")],
  by = c("herbicide", "cut", "controlwater")
)
mu_restr <- merge(mu_restr, PAMF_COMBS[, c("mc_db", "mnt_comb")],
  by.x = "mcombination", by.y = "mc_db"
)


# split by restr_id into a list mnt_comb vectors.
# This allows us to iterate a maximum of 8 times (there are 8 management
# restrictions) instead of iterating over every MU in the midcycle report
# (there may be considerably more than 8)
#
# First, sort mu_restr to ensure that the order of management combinations is
# the same before and after the split
mu_restr <- mu_restr[order(mu_restr$restr_id), ]
mu_restrs <- split(mu_restr$mnt_comb, mu_restr$restr_id)

# Get restriction IDs that pertain to at least one MU with a midcycle report
restrs <- unique(mu_restr$restr_id)

# Iterate through the elements of mu_restrs. Does their planned combination
# appear in the list of combinations allowed under the given restrictions?
allowed_combs <- split(
  action_restrictions[
    action_restrictions$restr_id %in% restrs,
    "mnt_comb"
  ],
  action_restrictions[
    action_restrictions$restr_id %in% restrs,
    "restr_id"
  ]
)

is_allowed <- mapply(isAllowedComb, mu_restrs, allowed_combs, SIMPLIFY = FALSE)

# Unlist the results and add as column to mu_restrs
compatible_restrict <- unlist(is_allowed, use.names = FALSE)
mu_restr <- cbind(mu_restr, compatible_restrict)
mu_restr <- mu_restr[order(mu_restr$munitid), ] # sort by munitid

# populate cycle_rows$incompatible_restrict
cycle_rows$incompatible_restrict <- !mu_restr$compatible_restrict


## 5. The planned combination is incompatible with action(s) that have already
#    been taken
##

# Create a data frame that links the munitid of MUs in midcycle with:
#  * translocating and dormant actions of the planned combination (PAMF_COMBS)
#  * phase and treatmethod of reported actions (manage)
mu_act <- midcycle[, c("munitid", "mcombination")]
mu_act <- merge(mu_act, PAMF_COMBS[, c("mc_db", "db_tloc", "db_dorm")],
  by.x = "mcombination", by.y = "mc_db"
)

# Get any translocating and dormant actions reported for each MU
t_act <- manage[manage$phase == TRANSLOCATING$code & manage$munitid %in%
  mu_act$munitid, c("munitid", "phase", "treatmethod")]
d_act <- manage[manage$phase == DORMANT$code & manage$munitid %in%
  mu_act$munitid, c("munitid", "phase", "treatmethod")]

# If any MU has more than one management action reported within a single phase,
# change it to 10 (OTHER). These cases are automatically incompatible with
# the planned combination because all PAMF combinations have one unique action
# per phase.

# Add if statements just in case no one has turned in any of the specified
# reports (yes, this happens)
if (nrow(t_act > 0)) {
  t_act <- collapseMultipleActions(t_act, OTHER$db)
  # Incorporate treatmethod into mu_act (one column each for translocating, dormant)
  # Give each treatmethod column a phase-specific name, then merge into mu_act
  colnames(t_act)[which(colnames(t_act) == "treatmethod")] <- "trans_act"
  mu_act <- merge(mu_act, t_act[, c("munitid", "trans_act")], all.x = TRUE)
} else {
  mu_act$trans_act <- NA
}
if (nrow(d_act > 0)) {
  d_act <- collapseMultipleActions(d_act, OTHER$db)
  colnames(d_act)[which(colnames(d_act) == "treatmethod")] <- "dorm_act"
  mu_act <- merge(mu_act, d_act[, c("munitid", "dorm_act")], all.x = TRUE)
} else {
  mu_act$dorm_act <- NA
}

# Determine whether the planned combination in each midcycle report is compatible
# with actions that were already taken
incomp_mus <- mu_act[(mu_act$trans_act != mu_act$db_tloc) |
  (mu_act$dorm_act != mu_act$db_dorm), "munitid"]
cycle_rows[cycle_rows$munitid %in% incomp_mus, "incompatible_manage"] <- TRUE


# ==============================================================================
#  assign midcy_issues for use in later scripts
# ==============================================================================
midcy_issues <- cycle_rows


# ==============================================================================
#  clean up temporary variables
# ==============================================================================
suppressWarnings(rm(
  n_rows, cycle_rows, grow_reports, monitored_mus, mon_rejected,
  mu_restr, mu_restrs, allowed_combs, is_allowed, restrictions,
  compatible_restrict, mu_act, t_act, d_act, incomp_mus,
  cycle_rows
))
# some of these variables are created inside of conditionals & may not exist
# every time the script runs
