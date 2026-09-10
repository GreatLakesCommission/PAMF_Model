# 2021-06-16
#
# This script handles timing mismatches within and between management reports,
# e.g.:
#   * management action reported as belonging to one phase but its
#     applicationdate is in another
#
# ASSUMPTIONS
# * Monitoring occurring in April or earlier is thrown out
# * There is no month that belongs to both GROWING$months and
#   TRANSLOCATING$months
#
# Sourced by: construct-datpaks.R
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND   : end year of PAMF cycle for this model run
#    CYCLE      : years defining the PAMF cycle
#    Definitions for PAMF actions (see global-constants.R)
#      Hard-coded actions include REST, FLOOD
#
# * Variables
#    mon_data    : monitoring reports within CYCLE
#    manage      : non-rejected management reports within CYCLE, merged with the
#                  date that the MU was monitored in manage_year
#    mon_issues  : monitoring issues reports within CYCLE
##

# # ============================================================================
# #  Uncomment this section for testing
# # ============================================================================
# options(stringsAsFactors=FALSE)
# 
# message(">>> USING TEST DATA FOR PHASE-DATE TIMING CHECKS <<<")
# source("./src/global-constants.R")
# 
# CYCLE    = c(2524, 2525)
# CYCLEEND = 2525
# 
# mon_data = read.csv("./src/construct-datpaks/timing-test-cases/monitor-test.csv")
# man_data  = read.csv("./src/construct-datpaks/timing-test-cases/manage-test.csv")
# mon_issues = read.csv("./src/construct-datpaks/timing-test-cases/monissues-test.csv")
# 
# mon_data$monitoringdate = as.Date(mon_data$monitoringdate)
# man_data$applicationdate = as.Date(man_data$applicationdate)
# 
# manage = man_data
# 
# manage <- merge(manage,
#                mon_data[, c("munitid", "monitor_year", "monitoringdate")],
#                by.x = c("munitid", "manage_year"),
#                by.y = c("munitid", "monitor_year"), all.x = TRUE
# )
# managementdate <- rep(NA, nrow(manage))
# manage <- cbind(manage, managementdate)
#
# ## To verify expected behaviour, compare man_changes to the descriptions in
# #  "timing test cases description.xlsx"
# #
# #  When subsetting by treatmentid or applicationid exclude NAs, e.g.
# #  man_changes[!is.na(man_changes$treatmentid) & man_changes$treatmentid==1,]
# #  or else it show a bunch of NA rows (due to the existence of NAs in those
# #  columns)
# ##

## =============================================================================
#    Set up
#
#    Create model_phase column (the phase that the model considers the
#    management action to be in)
## =============================================================================

model_phase <- rep(NA, nrow(manage))
manage <- cbind(manage, model_phase)

## =============================================================================
#    Reports WITHOUT application dates
## =============================================================================

## --- Pre-2020 cycles ---------------------------------------------------------
#  Before the summer of 2019, application dates were not required. During the
#  formatting step (formatManage(), format-functions.R), application dates for
#  all actions other than REST, FLOOD are assigned to be the same as
#  managementdate. Consequently, we don't need to add any backwards
#  compatibility here.

## --- REST reports ------------------------------------------------------------
#  Go with participant's intended phase. They can submit these reports at any
#  time in the cycle and there is no other information to indicate that the
#  phase is misreported
##
manage[manage$treatmethod == REST$db, "model_phase"] <-
  manage[manage$treatmethod == REST$db, "phase"]


## --- FLOOD reports -----------------------------------------------------------
#  Go with participant's intended phase. They can submit these reports at any
#  time in the cycle and while we can detect some flood issues (e.g. shorter
#  than a month, longer than a phase), without the start/end dates (which we
#  don't collect and the participants don't always know) we can't detect
#  phase-date disagreements in any reliable way.
##
manage[manage$treatmethod == FLOOD$db, "model_phase"] <-
  manage[manage$treatmethod == FLOOD$db, "phase"]


## =============================================================================
#    Reports WITH application dates
#
#    Get assigned_phase based on application date, using the state phase as a
#    tie breaker in the TRANSLOCATING/DORMANT and DORMANT/GROWING overlaps
## =============================================================================

## --- TRANSLOCATING -----------------------------------------------------------
#  Here, assign model phase for unambiguous dates only. We'll deal with August
#  and the TRANSLOCATING/DORMANT overlap later
##
t_months <- setdiff(TRANSLOCATING$months, c(8, DORMANT$months))

manage[manage$application_month %in% t_months, "model_phase"] <- TRANSLOCATING$code


## --- TRANSLOCATING/DORMANT overlap -------------------------------------------
#   Go with the participant's stated phase. But verify that the state phase is
#   either TRANSLOCATING or DORMANT: A GROWING report makes no sense here
#   and will be auto rejected
##
td_months <- intersect(TRANSLOCATING$months, DORMANT$months)

manage[manage$application_month %in% td_months, "model_phase"] <-
  manage[manage$application_month %in% td_months, "phase"]

# Find IDs of reports with incoherent phase reporting
td_incoherent <- manage[
  (manage$application_month %in% td_months) &
    manage$phase == GROWING$code,
  "treatmentid"
]


## --- DORMANT -----------------------------------------------------------------
#  Unambiguous dates only.
##
d_months <- setdiff(DORMANT$months, c(TRANSLOCATING$months, GROWING$months))

manage[manage$application_month %in% d_months, "model_phase"] <- DORMANT$code


## --- DORMANT/GROWING overlap -------------------------------------------------
#   Go with the participant's stated phase. But verify that the stated phase is
#   either DORMANT or GROWING: A TRANSLOCATING report makes no sense here
#   and will be auto-rejected
#
#   It's technically possible for a GROWING report to occur after monitoring,
#   but any monitoring done earlier than June is rejected outright, and
#   therefore won't appear in the merged data set. So it's safe to keep
#   participants' GROWING designation in this case.
##

dg_months <- intersect(DORMANT$months, GROWING$months)

manage[manage$application_month %in% dg_months, "model_phase"] <-
  manage[manage$application_month %in% dg_months, "phase"]

# Find IDs of reports with incoherent phase reporting
dg_incoherent <- manage[
  (manage$application_month %in% dg_months) &
    manage$phase == TRANSLOCATING$code,
  "treatmentid"
]


## --- GROWING -----------------------------------------------------------------
#  Unambiguous dates (with respect to the GROWING phase definition) only.
#  Explicitly exclude August, even though it's technically in TRANSLOCATING
##
g_months <- setdiff(GROWING$months, c(DORMANT$months, 8))

## Application before monitoring
#  Application occurred before the end of the cycle and is therefore GROWING
##

manage[
  !is.na(manage$monitoringdate) & (manage$application_month %in% g_months) &
    (manage$applicationdate < manage$monitoringdate),
  "model_phase"
] <- GROWING$code


## Application after monitoring
#  Application occurred after the end of the cycle and is therefore 
# TRANSLOCATING
#  If both occur on the same day, assume that monitoring happened first, bumping
#  the report into the next cycle
##
manage[
  !is.na(manage$monitoringdate) & (manage$application_month %in% g_months) &
    (manage$applicationdate >= manage$monitoringdate),
  "model_phase"
] <- TRANSLOCATING$code


## --- AUGUST ------------------------------------------------------------------
# Technically TRANSLOCATING, but complicated by monitoring and data pull dates.
# Reports with August management may be from:
#  1. CYCLEEND-1, but submitted after REPORTBEGIN
#     (those that were submitted before REPORTBEGIN were dealt with last year)
#  2. CYCLEEND, submitted before REPORTEND
#     (anything submitted after the data pull will be part of next year's run)
#
# IN EITHER CASE: the management-monitoringdate merge in construct-datpaks.R
# ensures that application dates will be compared against monitoring dates in
# the same year (if those monitoring reports exist & haven't been rejected for
# timing issues)
##

## Application before monitoring: GROWING
manage[
  manage$application_month %in% 8 & !is.na(manage$monitoringdate) &
    (manage$applicationdate < manage$monitoringdate),
  "model_phase"
] <- GROWING$code


## Application after monitoring: TRANSLOCATING
#  If both occur on the same day, assume that monitoring happened first, bumping
#  the report into the next cycle
manage[
  manage$application_month %in% 8 & !is.na(manage$monitoringdate) &
    (manage$applicationdate >= manage$monitoringdate),
  "model_phase"
] <- TRANSLOCATING$code


## --- Growing/August Without Monitoring ---------------------------------------
#  model_phase for applications done in the GROWING months (and August)
#  depends upon whether the management application was done before monitoring.
#  But what about cases where the monitoring report is missing or rejected?
#
#  Assign the phase suggested by the application date
##

## Apparently, this can't be done by simple subsetting, due to the NAs in
#  monitoringdate.
#  Instead:
#   1. Put all rows with monitoringdate NAs at the end of the data frame
#   2. Working with just that set of rows, subset by GROWING, August
#      and assign the phase. This doesn't overwrite any previously assigned
#      TRANSLOCATING, DORMANT model_phases
#   3. Replace just this subset of model_phase with the results
#   4. Sort the data frame by MU, treatmentid, and applicationid
##

manage <- manage[order(manage$monitoringdate, na.last = TRUE), ]
nomonitor <- manage[is.na(manage$monitoringdate), ]

# Growing phase
nomonitor[
  nomonitor$application_month %in% g_months,
  "model_phase"
] <- GROWING$code

# Translocating phase
nomonitor[
  nomonitor$application_month %in% 8,
  "model_phase"
] <- TRANSLOCATING$code

nm_rows <- nrow(nomonitor)
m_rows <- nrow(manage)
manage$model_phase[(m_rows - nm_rows + 1):m_rows] <- nomonitor$model_phase

manage <- manage[order(manage$munitid, manage$treatmentid, manage$applicationid), ]


## =============================================================================
#   Create REST reports to back fill vacated phases
#
#   When the phase and model_phase columns differ for all applications within a
#   management report, there are no actions left in the participant's intended
#   phase. Since we assume that participants report all actions taken, it
#   follows that they did nothing during the reported phase, i.e. they performed
#   a REST.
#
#   In these cases, create a REST report for that phase. Leaving the phase empty
#   will always prevent the management combination from being a PAMF
#   combination, but back-filling with REST may allow us to salvage the data
#   package.
#
#   e.g. consider a MU whose participant carried out GRG, but applied the
#        growing-phase GLYPHOSATE action after monitoring. That action cannot
#        contribute to the MU's end-cycle state, so we call it a translocating
#        action. The management combination is now GR instead of GRG, and GR
#        isn't a PAMF combination. But since the participant reported no other
#        actions during the growing phase, we can reasonably consider the
#        combination to be GRR-- which IS a PAMF combination
## =============================================================================

## Find management reports where phase always differs from model_phase. These
#  are the ones that leave behind an empty phase
vacate_ids <- setdiff(
  manage[manage$phase != manage$model_phase, "treatmentid"],
  manage[manage$phase == manage$model_phase, "treatmentid"]
)

## Now get munitid and timing information for these reports
#  Recall that earlier data pulls do not have a 'dateentered' column
if ("dateentered" %in% colnames(manage)) {
  vacate <- manage[
    manage$treatmentid %in% vacate_ids,
    c(
      "treatmentid", "munitid", "phase", "manage_year",
      "managementdate", "dateentered"
    )
  ]
} else {
  vacate <- manage[
    manage$treatmentid %in% vacate_ids,
    c(
      "treatmentid", "munitid", "phase", "manage_year",
      "managementdate"
    )
  ]
}

vacate <- vacate[!duplicated(vacate[, c("treatmentid", "munitid")]), ]

## Create REST reports for the vacated phases
new_rests <- as.data.frame(matrix(nrow = nrow(vacate), ncol = ncol(manage)))
colnames(new_rests) <- colnames(manage)

new_rests$munitid <- vacate$munitid
new_rests$treatmethod <- rep(REST$db, nrow(new_rests))
new_rests$dateentered <- vacate$dateentered
new_rests$managementdate <- vacate$managementdate
new_rests$manage_year <- vacate$manage_year
new_rests$phase <- vacate$phase
new_rests$model_phase <- vacate$phase

## Append new rest reports to manage and order by munitid
manage <- rbind(manage, new_rests)
manage <- manage[order(manage$munitid), ]

## =============================================================================
#    Change Log
#
#    Keep track of
#     * Mismatches between phase, model_phase
#     * created REST reports
## =============================================================================

## Create a row in man_changes for every management report
#  Why not for reports with changes only? Because this table will also keep
#  track of P/LB changes when data packages are constructed. Reports requiring
#  those changes may not belong to the set of reports that have phase/date
#  disagreement
nrow_manage <- nrow(manage)


## Create data frame to hold change information, INCLUDING data package
#  information and action reassignments. We'll get to those once we put together
#  the data packages
man_changes <- data.frame(
  munitid = manage$munitid,
  treatmentid = manage$treatmentid,
  applicationid = manage$applicationid,
  model_cycle = rep(CYCLEEND, nrow_manage),
  phase_reassign = rep(FALSE, nrow_manage),
  model_phase = manage$model_phase,
  created_rest = rep(FALSE, nrow_manage),
  action_reassign = rep(FALSE, nrow_manage),
  model_action = manage$treatmethod
)

## Change rows with phase reassignment to TRUE (phase_reassign column)
# ... for actions that don't have application records
phase_changed_rep_id <- manage[
  is.na(manage$applicationid) &
    (manage$phase != manage$model_phase),
  "treatmentid"
]
man_changes[
  man_changes$treatmentid %in% phase_changed_rep_id,
  "phase_reassign"
] <- TRUE

# ... for actions that do have application records
phase_changed_app_id <- manage[
  !is.na(manage$applicationid) &
    (manage$phase != manage$model_phase),
  "applicationid"
]
man_changes[
  man_changes$applicationid %in% phase_changed_app_id,
  "phase_reassign"
] <- TRUE

## Change rows describing created REST actions to TRUE (created_rest column)
man_changes[is.na(man_changes$treatmentid), "created_rest"] <- TRUE


# Set up incoherent phase information to go back to find-manage-issues.R
incoherent_phase_reports <- c(td_incoherent, dg_incoherent)


## =============================================================================
#    Clean up
## =============================================================================
suppressWarnings(rm(
  model_phase, t_months, td_months, td_incoherent, d_months,
  dg_months, dg_incoherent, g_months, nomonitor, nm_rows,
  m_rows, vacate_ids, vacate, new_rests, nrow_manage,
  phase_changed_rep_id, phase_changed_app_id
))

