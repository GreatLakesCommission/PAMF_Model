
# This script creates the monitor_issues dataframe, and populates it with any
# issues that may disqualify each report from use in the transition matrix
# update, partial controllability matrix update, or guidance.
# Most of the possible issues are at the report level, although in some cases
# (e.g. monitoring too soon after management) they drive report-level decisions
# but are affected by cross-report information.
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global constants:
#     CYCLEEND           : The second/final year of the current cycle to analyze
#     RUNPATH            : Path to the current run directory
#     MONITOR_MONTHS     : The months making up the monitoring window
#     NEARMONITOR_MONTHS : Months on either side of the monitoring window
#     MINAREA            : The minimum area needed to place 5 quadrats at 11%
#                          establishment
#     GROWING            : code and months for growing phase
#     FLOOD              : codes for FLOOD action
#     OTHER              : codes for OTHER action
#     STEMHI             : upper bound on reasonable stem count
#
# * Variables:
#     enroll_data  : formatted enrollment reports (data frame)
#     mon_data     : formatted monitoring reports (data frame)
#     man_data     : formatted management reports (data frame)
#
# * Files in RUNPATH:
#    monitor-issues-NOT-UPDATED.csv
#
# Additionally, assume that mon_data has the following columns:
#     monitorid
#     munitid
#     notes
#     dateentered
#     monitoringdate
#     establishment
#     q1stemcount, q2stemcount, q3stemcount, q4stemcount, q5stemcount
#     monitor_year (e.g. assigned by earlier call to formatReports)
#     monitor_month  (e.g. assigned by earlier call to formatReports)
#
# Assume that enroll_data has the following columns:
#     munitid
#     area
#
# Assume that man_data has the following columns:
#   munitid
#   treatmethod
#   phase
#   managementdate (IF data pull from 2019 or earlier)
#   dateentered (IF data pull is from 2020 or later)
#   applicationdate
##

# # ============================================================================
#  Uncomment this section for testing ------------------------------------------
# # ============================================================================
# options(stringsAsFactors=FALSE)
# message(">>> FIND-MONITOR-ISSUES RUNNING USING TEST DATA <<<")
# 
# # Constants
# source("./src/global-constants.R")
# 
# CYCLEEND = 2525
# RUNPATH  = "./src/create-new-run/test-cases/"
# 
# # These test cases are already formatted with derived columns,
# # e.g. monitor_month
# enroll_data  = read.csv("./src/create-new-run/test-cases/enroll.csv")
# mon_data = read.csv("./src/create-new-run/test-cases/monitor.csv")
# man_data = read.csv("./src/create-new-run/test-cases/manage.csv")
# 
# # Format their date columns
# mon_data$dateentered     = as.Date(mon_data$dateentered)
# mon_data$monitoringdate  = as.Date(mon_data$monitoringdate)
# man_data$dateentered     = as.Date(man_data$dateentered)
# man_data$applicationdate = as.Date(man_data$applicationdate)
# 
# # TO TEST:
# # Run this script either by sourcing with this section uncommented, or by
# # copy/pasting.
# # Compare cycle_rows against the expectations listed test-cases/monitor.xlsx
# 

# ==============================================================================
#  Remove monitoring reports that:
#    (a) Already appear in a previous year's monitor_issues table
#    (b) Belong to inactive MUs
# ==============================================================================

# Reports that already appear in monitor_issues.csv
if (CYCLEEND > 2018) {
  # Get IDs of existing reports
  mon_issues <- read.csv(paste0(RUNPATH, "monitor_issues-NOT-UPDATED.csv"))
  mon_ids <- mon_issues$monitorid

  # Get reports that do not correspond to an existing ID
  monitor <- mon_data[!mon_data$monitorid %in% mon_ids, ]

  rm(mon_issues) # might be large and we don't need it for the rest of the script
} else {
  # else, the year is 2018 and nothing has been reviewed yet. keep all reports.
  monitor <- mon_data
}

# Reports that belong to inactive MUs
if (CYCLEEND > 2018) {
  # The 'active' column in the enrollment reports was only added in 2019
  active_mu <- enroll_data[enroll_data$active == TRUE, "munitid"]
  monitor <- monitor[monitor$munitid %in% active_mu, ]
}

# Check for duplicate reports from the same MU / cycle If this happens, throw an
# error and stop the script. Technically the web hub shouldn't allow this to
# happen, but a glitch in the web hub in 2024 and 2025 let some slip through.
if (CYCLEEND > 2023) {
  duplicate_ids <- monitor[which(monitor$monitor_year > 2023), ]
  duplicate_ids <- duplicate_ids[duplicated(duplicate_ids[, c("munitid", "monitor_year")]), ]
  if (nrow(duplicate_ids) > 0) {
    stop("WARNING! Multiple monitoring reports for the same MU! Remove from data!")
  }
  rm(duplicate_ids)
}

# ==============================================================================
#  Create new empty monitor_issues rows
#  (these will be appended to the cumulative history later on)
# ==============================================================================

## There are three types of columns in this data frame:
#    * data columns     : Contain information taken from the report
#    * issues columns   : Contain information about whether each possible issue
#                         affects the quality of each report
#    * decision columns : Contain various keep/reject decisions
#
#  The default on all issues/rejections is FALSE. Assume reports are ok until
#  proven otherwise
##
n_rows <- nrow(monitor) # this works because all monitoring reports consist of one row
cycle_rows <- data.frame(
  monitorid = monitor$monitorid,
  munitid = monitor$munitid,
  cycle_end = rep(CYCLEEND, n_rows),
  run_date = rep(strftime(Sys.time(), "%Y-%m-%d"), n_rows),
  monitor_year = monitor$monitor_year,
  wrongyear_mon = rep(FALSE, n_rows),
  year_mismatch = rep(FALSE, n_rows),
  month_mismatch = rep(FALSE, n_rows),
  has_notes = rep(FALSE, n_rows),
  near_window = rep(FALSE, n_rows),
  out_of_window = rep(FALSE, n_rows),
  near_manage = rep(FALSE, n_rows),
  stems_missing = rep(FALSE, n_rows),
  stems_zero = rep(FALSE, n_rows),
  stems_high = rep(FALSE, n_rows),
  display = rep(FALSE, n_rows),
  coordreject_model = rep(FALSE, n_rows),
  coordreject_guid = rep(FALSE, n_rows),
  coordreject_amu = rep(FALSE, n_rows),
  coordreject_note = rep(NA, n_rows),
  reviewed_by = rep(NA, n_rows),
  reviewed_date = rep(NA, n_rows),
  autoreject_model = rep(FALSE, n_rows),
  autoreject_guid = rep(FALSE, n_rows)
)


# ==============================================================================
# Check reports for the following issues that require human judgement:
#
#  1. Does the monitoring report have notes?
#  2. Did monitoring occur in June or August?
#     (This could be close to the window or it may be a typo)
#  3. Is the year of monitoringdate different than cycleend?
#  4. Is the year of monitoringdate different than the year of dateentered?
#  5. Is the month of monitoringdate outside of the monitoring/near-monitoring
#     window (June-August) but the month of dateentered is in it?
#  6. Did monitoring take place within a month of the last managment action?
#  7. Does the monitoring report have establishment > 11%, at least
#     one stem count==0 and mu area > 11.36m^2 (see note below)?
#  8. Does the monitoring report have establishment > 11%, at least
#     one missing stem count, and a MU area > 11.36m^2 ?
#  9. Does the report have a stem count > 50?
#
# NOTE: 11.36m^2 is the minimum area of a MU that is large enough to
#       accommodate 5 quadrats at 11% establishment. We consider stem
#       count anomalies in MUs larger than this threshold to be
#       possibly erroneous and worth checking by hand.
# ==============================================================================

## 1. Does the monitoring report have notes?
#     If so, set has_notes to TRUE
##
notes_reports <- monitor[!is.na(monitor$notes), "monitorid"]
cycle_rows[cycle_rows$monitorid %in% notes_reports, "has_notes"] <- TRUE


## 2. Did monitoring occur in June or August?
#     If so, it's up to the coordinator whether to include the report.
#     Set the near_window column to TRUE
##
near_reports <- monitor[monitor$monitor_month %in% NEARMONITOR_MONTHS, "monitorid"]
cycle_rows[cycle_rows$monitorid %in% near_reports, "near_window"] <- TRUE


## 3. Is the year of monitoringdate different than cycleend?
#     If so, the year may have been mis-entered. The coordinator should have a
#     look
#     NOTE: If you're running 2018, the 2017 reports will get this flag, simply
#           because there's no 2017 run and they consequently haven't been
#           reviewed yet. This flag isn't a basis to reject those specific ones.
#     NOTE: 'ooy' denotes "out of year"
##
ooy_reports <- monitor[monitor$monitor_year != CYCLEEND, "monitorid"]
cycle_rows[cycle_rows$monitorid %in% ooy_reports, "wrongyear_mon"] <- TRUE


## 4. Is the year of monitoringdate different than the year of dateentered?
#     If so, it's possible that monitoringdate was entered incorrectly.
#     Have a look
##
de_year <- as.numeric(substr(monitor$dateentered, start = 1, stop = 4))
monitor <- cbind(monitor, de_year)

mismatch_reports <- monitor[monitor$monitor_year != monitor$de_year, "monitorid"]
cycle_rows[cycle_rows$monitorid %in% mismatch_reports, "year_mismatch"] <- TRUE


## 5. Is the month of monitoringdate outside of the monitoring/near-monitoring
#     window (June-August) but the month of dateentered is in it?
#     If so, monitoringdate may have been mis-typed (in a way that we care about)
##
de_month <- as.numeric(substr(monitor$dateentered, start = 6, stop = 7)) # dateentered month
monitor <- cbind(monitor, de_month)

mismatch_reports <- monitor[
  monitor$de_month %in% union(
    MONITOR_MONTHS,
    NEARMONITOR_MONTHS
  ) &
    !monitor$monitor_month %in% union(
      MONITOR_MONTHS,
      NEARMONITOR_MONTHS
    ),
  "monitorid"
]
cycle_rows[cycle_rows$monitorid %in% mismatch_reports, "month_mismatch"] <- TRUE


## 6. Did monitoring take place within a month of the last management action?
#     If so, the monitoring report may underestimate invasion severity
##

# First, merge MU and date information
if ("dateentered" %in% colnames(man_data)) {
  date_compare <- merge(mon_data[, c("munitid", "monitorid", "monitoringdate")],
    man_data[, c(
      "munitid", "treatmethod", "phase",
      "applicationdate", "dateentered"
    )],
    all.x = TRUE
  )
} else {
  date_compare <- merge(mon_data[, c("munitid", "monitorid", "monitoringdate")],
    man_data[, c(
      "munitid", "treatmethod", "phase",
      "applicationdate", "managementdate"
    )],
    all.x = TRUE
  )
}

# Get MUs that were monitored between 0 and 30 days after a management
# application date
near_appdate_reports <- date_compare[
  !is.na(date_compare$applicationdate) &
    (date_compare$monitoringdate >
      date_compare$applicationdate) &
    (date_compare$monitoringdate -
      date_compare$applicationdate < 30),
  "monitorid"
]

# REST, FLOOD, AND OTHER don't have application dates.
# Since REST is the same as no action, ignore it. Find growing-phase FLOOD and
# OTHER actions with managementdate/dateentered within a month before monitoring
if ("dateentered" %in% colnames(man_data)) {
  near_de_reports <- date_compare[date_compare$phase == GROWING$code &
    date_compare$treatmethod %in% FLOOD$db &
    (date_compare$monitoringdate >
      date_compare$dateentered) &
    (date_compare$monitoringdate -
      date_compare$dateentered < 30), "monitorid"]
} else {
  near_de_reports <- date_compare[date_compare$phase == GROWING$code &
    date_compare$treatmethod %in% FLOOD$db &
    (date_compare$monitoringdate >
      date_compare$managementdate) &
    (date_compare$monitoringdate -
      date_compare$managementdate < 30), "monitorid"]
}

near_manage_reports <- c(near_appdate_reports, near_de_reports)
cycle_rows[cycle_rows$monitorid %in% near_manage_reports, "near_manage"] <- TRUE


## 7. Does the monitoring report have establishment > 11%, at least
#     one stem count==0 and mu area > 11.36m^2 ?
## 8. Does the monitoring report have establishment > 11%, at least
#     one missing stem count, and a MU area > 11.36m^2 ?
#  NOTE: establishment > 11% translates to monitor$establishment of 1 or 2
#        because the web hub records establishment responses in numbered
#        categories
#
#     Handle these together since they share the same complicated condition
#     If stem counts are zero or nonexistent in a large-enough MU, then
#     it's up to the coordinator to determine whether these entries are
#     reasonable. Set stems_zero or stems_missing to TRUE
mu_largeenough <- enroll_data[enroll_data$area > MINAREA, "munitid"]

zeroes_reports <- monitor[
  monitor$establishment %in% c(1, 2) &
    monitor$munitid %in% mu_largeenough &
    ((!is.na(monitor$q1stemcount) & monitor$q1stemcount == 0) |
      (!is.na(monitor$q2stemcount) & monitor$q2stemcount == 0) |
      (!is.na(monitor$q3stemcount) & monitor$q3stemcount == 0) |
      (!is.na(monitor$q4stemcount) & monitor$q4stemcount == 0) |
      (!is.na(monitor$q5stemcount) & monitor$q5stemcount == 0)),
  "monitorid"
]
cycle_rows[cycle_rows$monitorid %in% zeroes_reports, "stems_zero"] <- TRUE

nostem_reports <- monitor[monitor$establishment %in% c(1, 2) &
  monitor$munitid %in% mu_largeenough &
  (is.na(monitor$q1stemcount) |
    is.na(monitor$q2stemcount) |
    is.na(monitor$q3stemcount) |
    is.na(monitor$q4stemcount) |
    is.na(monitor$q5stemcount)), "monitorid"]
cycle_rows[cycle_rows$monitorid %in% nostem_reports, "stems_missing"] <- TRUE


## 9. Does the report have a suspiciously high stem count?
#     This suggests that participant may have counted dead stems or accidentally
#     included other species in the count
#     If so, set the stems_high column to TRUE
stemshi_reports <- monitor[
  (!is.na(monitor$q1stemcount) &
    monitor$q1stemcount > STEMHI) |
    (!is.na(monitor$q2stemcount) &
      monitor$q2stemcount > STEMHI) |
    (!is.na(monitor$q3stemcount) &
      monitor$q3stemcount > STEMHI) |
    (!is.na(monitor$q4stemcount) &
      monitor$q4stemcount > STEMHI) |
    (!is.na(monitor$q5stemcount) &
      monitor$q5stemcount > STEMHI),
  "monitorid"
]
cycle_rows[cycle_rows$monitorid %in% stemshi_reports, "stems_high"] <- TRUE


# ==============================================================================
# Check reports for the following issues that can be resolved automatically:
#
#  Note that any appropriate autoreject designations are also made here, but
#  they do NOT prevent the display of other issues in the same report that
#  require human judgement. The reason for this is that the coordinator may
#  encourage re-submission of any flagged reports. The inputs that triggered
#  auto-reject designations may also change if a report is updated.
# ==============================================================================

## 10. Are monitoringdate and dateentered both outside of the monitoring window
#      (July) and the near-monitoring window (June, August)?
#
oow_reports <- monitor[
  !monitor$monitor_month %in% union(
    MONITOR_MONTHS,
    NEARMONITOR_MONTHS
  ) &
    !monitor$de_month %in% union(
      MONITOR_MONTHS,
      NEARMONITOR_MONTHS
    ),
  "monitorid"
]
cycle_rows[
  cycle_rows$monitorid %in% oow_reports,
  c("out_of_window", "autoreject_model")
] <- TRUE
# why not autoreject_guid also? Because although out_of_window monitoring might
# not reflect the MU's state in July (which is why we don't want to build it
# into the posteriors), it's still a good idea to give the participant the best
# guidance that we can.

# ==============================================================================
#  Determine which reports to display in the RMarkdown output and the checboxUI
# ==============================================================================
cycle_rows[
  (cycle_rows$wrongyear_mon |
    cycle_rows$year_mismatch | cycle_rows$month_mismatch |
    cycle_rows$has_notes | cycle_rows$near_window |
    cycle_rows$near_manage | cycle_rows$stems_missing |
    cycle_rows$stems_zero | cycle_rows$stems_high),
  "display"
] <- TRUE

mon_issues <- cycle_rows

# ==============================================================================
#  clean up temporary variables
# ==============================================================================
suppressWarnings(rm(
  mon_ids, active_mu, n_rows, notes_reports, near_reports,
  ooy_reports, de_year, mismatch_reports, date_compare,
  near_appdate_reports, near_de_reports, near_manage_reports,
  de_month, mu_largeenough, zeroes_reports, nostem_reports,
  stemshi_reports, oow_reports, cycle_rows, monitor
))
# some of these variables are created inside of conditionals & may not exist
# every time the script runs
