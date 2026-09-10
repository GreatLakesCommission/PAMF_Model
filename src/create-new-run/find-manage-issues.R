# This script creates the manage_issues dataframe, and populates it with any
# issues that may disqualify each report from use in the transition matrix
# update, partial controllability matrix update, or guidance. These issues exist
# at report level (not the application level or the data package level)
#
# Sourced by: app.R
#
# DEPENDENCIES
#   Global constants:
#     CYCLEEND : The second/final year of the current cycle being analyzed
#     RUNPATH  : Path to the current run directory
#     TRANSLOCATING : code and months for translocating phase
#     DORMANT       : code and months for dormant phase
#     GROWING       : code and months for growing phase
#     FLOOD         : codes for FLOOD action
#     CUT           : codes for CUT action
#     FLOODMIN      : minimum duration of a flood action
#                     (shorter floods don't count)
#     COST_CONSTS   : constants describing the cost per unit of supplies, labor,
#                     fuel, etc
#     OTHERHR_MAX   : maximum proportion of labor hours that may belong to the
#                     'other' category without forcing labor costs to be NA
#
#   Variables:
#     mon_data     : formatted monitoring reports (data frame)
#     enroll_data  : formatted enrollment reports (data frame)
#     man_data     : formatted management reports (data frame)
#
#   Functions:
#     From create-run-functions.R:
#      priceCheck
#
# Files in RUNPATH:
#  manage-issues-NOT-UPDATED.csv (2019 and later)
#
#
# Additionally, assume that man_data has the following columns:
#
# Assume that manage has the following columns:
#    treatmentid
#    applicationid
#    munitid
#    phase
#    manage_month      (e.g. assigned by earlier call to formatReports)
#    manage_year       (same)
#    application_month (same)
#    treatmethod
#    floodmonths
#    glyphnotes
#    glyphplusnotes
#    imaznotes
#    prenotes
#    mechnotes
#    removenotes
#    cutnotes
#    spadenotes
#    floodnotes
#    othernotes
#    restnotes
#    prenotes
#    cutdescribe
#    treatbymodel
#    followdescribe
#    predescribe
#    other
#    glyphsurfactantused
#    glyphplussurfactantused
#    imazsurfactantused
#    glyphproductother
#    glyphplusproductother
#    imazproductother
#    glyphplusaddedother
#    glyphequipmodel
#    glyphplusequipmodel
#    imazequipmodel
#    removeequipmodel
#    mechequipmodel
#    cutequipmodel
#    preequipmodel
#    munitcondition
# Data contains the following columns (AFTER 2022 model run):
#   * glyphherbicidevalues
#   * glyphtreatareaherb
#   * glyphacresvolume
#   * glyphvolumeherbicideacre
#   * glyphvolumesurfactantacre
#   * glyphplusherbicidevalues
#   * glyphplustreatareaherb
#   * glyphplusacresvolume
#   * glyphplusherbicideacre
#   * glyphplusvolumeaddedacre
#   * glyphplusvolumesurfactantacre
#   * imazherbicidevalues
#   * imaztreatareaherb
#   * imazacresvolume
#   * imazvolumeherbicideacre
#   * imazvolumesurfactantacre
#
# Assume that mon_data has the following columns:
#    monitor_year (e.g. assigned by earlier call to formatReports)
#    monitoringdate
##

# # ==============================================================================
# #  Uncomment this section for testing
# # ==============================================================================
# options(stringsAsFactors=FALSE)
# message(">>> FIND-MANAGE-ISSUES RUNNING USING TEST DATA <<<")
#
# # Constants
# source("./src/global-constants.R")
#
# CYCLEEND = 2525
# RUNPATH  = "./src/create-new-run/test-cases/"
# COST_CONSTS = read.csv("./cost-constants/cost_constants2018.csv")
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
# source("./src/create-new-run/create-run-functions.R")
#
# # TO TEST:
# # 1. Run find-monitor-issues.R with test data. This generates the mon_issues
# #    table that is used by the phase-date-agreement script call
# # 2. Run this script either by sourcing with this section uncommented, or by
# #    copy/pasting.
# # Compare cycle_rows against the expectations listed test-cases/manage.xlsx


# ==============================================================================
#  Remove management reports that:
#    (a) Already appear in a previous year's manage_issues dataframe
#    (b) Belong to inactive MUs
# ==============================================================================

# Reports that already appear in manage_issues.csv
if (CYCLEEND > 2018) {
  # Get IDs of existing reports
  man_issues <- read.csv(paste0(RUNPATH, "manage_issues-NOT-UPDATED.csv"))
  man_ids <- man_issues$treatmentid

  # Get reports that do not correspond to an existing ID
  manage <- man_data[!man_data$treatmentid %in% man_ids, ]

  rm(man_issues) # this might be large and we don't need it for the rest of the script
} else {
  # else, the year is 2018 and nothing has been reviewed yet. keep all reports.
  manage <- man_data
}

# Reports that belong to inactive MUs
if (CYCLEEND > 2018) { # The 'active' column was added in 2019
  active_mu <- enroll_data[enroll_data$active == TRUE, "munitid"]
  manage <- manage[manage$munitid %in% active_mu, ]
}


# ==============================================================================
#  Create new empty manage_issues rows
#  (these will be appended to the cumulative history later on)
# ==============================================================================

# Unlike monitoring reports, management reports may consist of several rows,
# where each row corresponds to a single application date. This is a consequence
# of the merge between manage and mndates in formatReports(). So we can't treat
# each row as a unique report.

# Get unique management report information:
unique_reports <- manage[
  !duplicated(manage$treatmentid),
  c("treatmentid", "munitid", "manage_year")
]
# If a report has more than one application date, the application_year for the
# first row of the report becomes application_year in unique_reports. Dormant
# reports may have application dates in different years but it shouldn't be too
# much of an issue

## There are three types of columns in this data frame:
#    * data columns     : Contain information taken from the report
#    * issues columns   : Contain information about whether each possible issue
#                         affects the quality of each report
#    * decision columns : Contain various keep/reject decisions
#
#  The default on all issues/rejections is FALSE. Assume reports are ok until
#  proven otherwise
##
n_rows <- nrow(unique_reports)
cycle_rows <- data.frame(
  treatmentid = unique_reports$treatmentid,
  munitid = unique_reports$munitid,
  cycle_end = rep(CYCLEEND, n_rows),
  run_date = rep(strftime(Sys.time(), "%Y-%m-%d"), n_rows),
  manage_year = unique_reports$manage_year,
  wrongyear_man = rep(FALSE, n_rows),
  has_notes = rep(FALSE, n_rows),
  out_of_phase = rep(FALSE, n_rows),
  unresolved_phase = rep(FALSE, n_rows),
  short_flood = rep(FALSE, n_rows),
  long_flood = rep(FALSE, n_rows),
  hydro_mismatch = rep(FALSE, n_rows),
  low_coverage = rep(FALSE, n_rows),
  duplicated_cost = rep(FALSE, n_rows),
  no_cost_data = rep(FALSE, n_rows),
  old_cost_qaqc = rep(FALSE, n_rows),
  labor_other = rep(FALSE, n_rows),
  missing_constant = rep(FALSE, n_rows),
  display = rep(FALSE, n_rows),
  coordreject_model = rep(FALSE, n_rows),
  coordreject_cost = rep(FALSE, n_rows),
  coordreject_amu = rep(FALSE, n_rows),
  coordreject_note = rep(NA, n_rows),
  reviewed_by = rep(NA, n_rows),
  reviewed_date = rep(NA, n_rows),
  autoreject_model = rep(FALSE, n_rows),
  autoreject_cost = rep(FALSE, n_rows)
)


# ==============================================================================
# Check reports for the following issues requiring human judgement:
#
#  1. Does the management report have notes?
#  2. Is the year that management occurred not in c(cycleend, cycleend-1)?
#  3. If Flood is reported, is the duration longer than the phase?
#  4. Is the reported action incompatible with the MU's hydrologic condition?
#
# ==============================================================================

## 1. Does the management report have notes?
#     If so, set has_notes to TRUE.
#     There are 30 fields in the management report entry forms that allow
#     participants to enter free text. Set has_notes to TRUE if ANY of them
#     has a non-NA value
##
notes_reports <- manage[
  !is.na(manage$glyphnotes) |
    !is.na(manage$glyphplusnotes) |
    !is.na(manage$imaznotes) |
    !is.na(manage$prenotes) |
    !is.na(manage$mechnotes) |
    !is.na(manage$removenotes) |
    !is.na(manage$cutnotes) |
    !is.na(manage$spadenotes) |
    !is.na(manage$floodnotes) |
    !is.na(manage$restnotes) |
    !is.na(manage$othernotes) |
    !is.na(manage$cutdescribe) |
    !is.na(manage$predescribe) |
    !is.na(manage$followdescribe) |
    !is.na(manage$other) |
    !is.na(manage$glyphsurfactantused) |
    !is.na(manage$glyphplussurfactantused) |
    !is.na(manage$imazsurfactantused) |
    !is.na(manage$glyphproductother) |
    !is.na(manage$glyphplusproductother) |
    !is.na(manage$imazproductother) |
    !is.na(manage$glyphplusaddedother) |
    !is.na(manage$glyphequipmodel) |
    !is.na(manage$glyphplusequipmodel) |
    !is.na(manage$imazequipmodel) |
    !is.na(manage$removeequipmodel) |
    !is.na(manage$mechequipmodel) |
    !is.na(manage$cutequipmodel) |
    !is.na(manage$preequipmodel),
  "treatmentid"
]
cycle_rows[cycle_rows$treatmentid %in% notes_reports, "has_notes"] <- TRUE


## 2. Is the year that management occurred not in c(cycleend, cycleend-1)?
#     If so, set wrongyear_man to TRUE
##
app_ooc <- manage[!manage$manage_year %in% c(CYCLEEND, CYCLEEND - 1) &
  !is.na(manage$manage_year), "treatmentid"]
cycle_rows[cycle_rows$treatmentid %in% app_ooc, "wrongyear_man"] <- TRUE


## 3. If Flood is reported, is the duration longer than the phase?
#     If so, the MU was flooded during another phase as well. Alert the
#     coordinator of floods that spill into another phase
##
flood_tloc <- manage[!is.na(manage$floodmonths) &
  manage$floodmonths > length(TRANSLOCATING$months) &
  manage$phase == TRANSLOCATING$code, "treatmentid"]
flood_dorm <- manage[!is.na(manage$floodmonths) &
  manage$floodmonths > length(DORMANT$months) &
  manage$phase == DORMANT$code, "treatmentid"]
flood_grow <- manage[!is.na(manage$floodmonths) &
  manage$floodmonths > length(GROWING$months) &
  manage$phase == GROWING$code, "treatmentid"]
cycle_rows[
  cycle_rows$treatmentid %in% c(flood_tloc, flood_dorm, flood_grow),
  "long_flood"
] <- TRUE


## 4. Is the reported action incompatible with the MU's hydrologic condition?
#     * Is Cut Underwater reported on a dry MU?
#     * Is Flood reported on a dry or moist MU?
#       NOTE: none of the hydrologic condition choices is technically compatible
#             with flood. but 'wet' is the closest
##
# NOTE: 2 corresponds to the dry hydrological condition
#       1 is 'moist'
#       0 is 'wet'
cut_incompatible <- manage[manage$treatmethod == CUT$db &
  manage$munitcondition == 2, "treatmentid"]
flood_incompatible <- manage[manage$treatmethod == FLOOD$db &
  manage$munitcondition %in% c(1, 2), "treatmentid"]
cycle_rows[
  cycle_rows$treatmentid %in% c(cut_incompatible, flood_incompatible),
  "hydro_mismatch"
] <- TRUE


# ==============================================================================
# Check reports for the following issues that can be resolved automatically:
#
#  7.  If Flood is reported, is the duration < 1 month?
#  8.  Is percentcover less than 76% (for all actions other than rest)?
#
#  For reports that include cost information:
#  9. Were cost details not provided?
#  10. Is the report from 2019 and was it rejected due to a data entry issue
#      that has since been resolved by the web hub? (this only applies to
#      reports 415 and 426)
#  11. Is the report a duplicate for the purposes of cost reporting?
#  12. Does "otherhours" make up over a quarter of total labor hours?
#  13. Does cost calculation of the reported action rely on a missing constant?
#
#
#  Note that any appropriate autoreject designations are made here, but they
#  do NOT prevent the display of other issues in the same report that require
#  human judgement.
#
#  The coordinator may encourage re-submission of any flagged reports. The
#  inputs that triggered auto-reject designations may also change if a report is
#  updated.
#
#  NOTE ALSO that management reports may have issues with agreement between
#  their reported phase and application date. These issues are dealt with in
#  phase-date-agreement.R, which is called right before data package
#  construction.
#
# ==============================================================================

## 7. If Flood is reported, is the duration < 1 month?
#     If so, set short_flood to TRUE
##
flood_reports <- manage[!is.na(manage$floodmonths) &
  manage$floodmonths < FLOODMIN, "treatmentid"]
cycle_rows[
  cycle_rows$treatmentid %in% flood_reports,
  c("short_flood", "autoreject_model")
] <- TRUE


## 8. Is percentcover less than 76%?
#     If so, set low_coverage to TRUE. Additionally, set autoreject_model and
#     autoreject_cost to TRUE because low-coverage reports likely don't reflect
#     treatment effectiveness or cost in a way that's comparable to high-coverage
#     reports.
#
#     NOTE: percentcover (or its variants) may be NA, either because of changes
#           to the Web Hub (e.g. percentcover replaced the other cover columns
#           in 2020, but was not fully implemented for pre-flood clearing and
#           mechanical & remove until after the data pull) or because the report
#           is for an action that legitimately does not have a percentcover
#           value (i.e. REST)
#
#     Before mid-2020, coverage was only recorded for the GLYPHOSATE,
#     GLYPHOSATE+, IMAZAPYR, PRE-FLOOD CLEARING, and MECHREMOVE actions. For
#     2018-2019 data, assume full coverage on all other non-rest actions.
##
# NOTE: the database encodes 76-100% coverage as 3; lower numbers refer to lower
#       coverage
if (CYCLEEND <= 2021) {
  ## The model run for the current cycle uses data from 2020 or earlier
  #
  # Get percentcoverage wherever it exists.  This method takes advantage of the
  # fact that the action-specific columns are mutually exclusive (each report
  # only populates cover for one type of action)
  ##
  pre2021_coverage <- manage[
    !(is.na(manage$glyphpercentcover) &
      is.na(manage$glyphpluspercentcover) &
      is.na(manage$imazpercentcover) &
      is.na(manage$prepercentcover) &
      is.na(manage$removepercentcover)),
    c(
      "treatmentid", "treatmethod", "glyphpercentcover",
      "imazpercentcover", "glyphpluspercentcover",
      "prepercentcover", "removepercentcover"
    )
  ]

  pre2021cover <- rowSums(pre2021_coverage[, c(
    "glyphpercentcover",
    "imazpercentcover",
    "glyphpluspercentcover",
    "prepercentcover",
    "removepercentcover"
  )], na.rm = TRUE)

  pre2021_coverage <- cbind(pre2021_coverage, pre2021cover)

  low_cover <- pre2021_coverage[
    !is.na(pre2021_coverage$pre2021cover) &
      pre2021_coverage$pre2021cover < 3,
    "treatmentid"
  ]
  
  if ("percentcover" %in% colnames(manage)) {
    # If a "percentcover" column exists (i.e. data pulled in 2020 or later),
    # check it for low cover instead
    
    low_cover <- manage[
      !is.na(manage$percentcover) & manage$percentcover < 3,
      "treatmentid"
    ]
    # Previous version of this code combined low_cover from above with low_cover
    # generated here, but really it should just replace it since we can't edit 
    # the defunct column values in the database but CAN update percentcover.
    # For example, in 2025-12-11 I just noticed an issue where column 
    # glyphpluspercentcover == 1, and we had corrected the updated column 
    # percentcover == 3, but it was still rejected from the model runs because
    # it was pulling low coverage from the old columns!
    # Previous version:
    # low_cover <- c(low_cover, manage[manage$percentcover < 3, "treatmentid"])
  }
} else {
  ## 2021-2022 cycle or later. manage has had an active "percentcover" column
  #  for the entire cycle
  low_cover <- manage[
    !is.na(manage$percentcover) & manage$percentcover < 3,
    "treatmentid"
  ]
}
cycle_rows[
  cycle_rows$treatmentid %in% low_cover,
  c("low_coverage", "autoreject_model", "autoreject_cost")
] <- TRUE


## The following set of checks looks at whether cost calculations are possible

## 9. Were cost details not provided? This may be the case for actions where:
#        * Cost questions are not asked (REST, OTHER)
#        * The participant chose not to answer cost questions
#        * They did not have herbicide application details
#      If so, don't calculate cost!
##
# Column "herbicidevalues" was added to the web hub in March 2023 and asks
# herbicide values are available, 2 = they don't know the rate of herbicide
# application  

if("herbicidevalues" %in% names(manage)){
  no_cost <- manage[
    is.na(manage$costdetails) | manage$costdetails == 0 | 
      manage$herbicidevalues == 2,
    "treatmentid"
  ]
} else {
  no_cost <- manage[
    is.na(manage$costdetails) | manage$costdetails == 0,
    "treatmentid"
  ]
}

cycle_rows[
  cycle_rows$treatmentid %in% no_cost,
  c("no_cost_data", "autoreject_cost")
] <- TRUE


## For the rest of the cost checks, look only at reports that were not
#  identified by check #12
man_costs <- manage[!manage$treatmentid %in% no_cost, ]

## 10. Is the report from 2019 and was it rejected due to a cost-related data
#      entry issue that has since been resolved by the web hub? (this only
#      applies to reports 415 and 426)
#      This check is included to preserve backwards compatibility with data that
#      were submitted before repairs were made (summer 2019) to the Web Hub QAQC
#      for cost questions
##
cycle_rows[
  cycle_rows$treatmentid %in% c(415, 426),
  c("old_cost_qaqc", "autoreject_cost")
] <- TRUE


## 11. Is the report a duplicate for the purposes of cost calculations?
#      If duplicates aren't removed, the costs of duplicated reports will be
#      over represented
#
# Since we're only looking for duplicated sets of cost data, we don't want to
# compare the values of all columns, just the ones that may indicate that the
# same costs are reported twice
##

compare_cols <- c(
  "munitid", "manage_year", "phase", "treatmethod",
  "applicationdate", "application_month", "floodmonths",
  "munitcondition", "percentcover", "costdetails", "hirecontractor",
  "otherhours", "totalhoursworked", "glyphproduct",
  "glyphplusproduct", "imazproduct", "glyphplusaddedname",
  "studenthours", "volunteerhours", "seasonalhours", "fullhours",
  "glyphgasmin", "glyphplusgasmin", "imazgasmin", "floodgasmin",
  "cutgasmin", "pregasmin", "removegasmin", "mechgasmin",
  "glyphdieselmin", "glyphplusdieselmin", "imazdieselmin",
  "flooddieselmin", "cutdieselmin", "predieselmin", "removedieselmin",
  "mechdieselmin", "glyphjetmin", "glyphplusjetmin", "imazjetmin",
  "glyphavgasmin", "glyphplusavgasmin", "imazavgasmin",
  "floodwattagemin", "glyphsurfactantpercent", "glyphplussurfactantpercent",
  "imazsurfactantpercent"
)

# Add checks for herbicide values added to web hub in March 2023
if ("glyphherbicidevalues" %in% names(man_costs)) {
  compare_cols <- c(
    compare_cols, "glyphtreatareaherb", "glyphacresvolume", 
    "glyphvolumeherbicideacre", "glyphvolumesurfactantacre", 
    "glyphplustreatareaherb", "glyphplusacresvolume", "glyphplusherbicideacre", 
    "glyphplusvolumeaddedacre", "glyphplusvolumesurfactantacre", 
    "imaztreatareaherb", "imazacresvolume", "imazvolumeherbicideacre",
    "imazvolumesurfactantacre"
  )
}

dup_rows <- which(duplicated(man_costs[, colnames(man_costs) %in% compare_cols]))
# note that duplicated() doesn't return the first instance of any duplicate

if (length(dup_rows) > 0) {
  # there are some duplicate management reports!
  dup_ids <- man_costs[dup_rows, "treatmentid"]
  cycle_rows[
    cycle_rows$treatmentid %in% dup_ids,
    c("duplicated_cost", "autoreject_cost")
  ] <- TRUE
}


## 12. Does "otherhours" make up over a quarter (OTHERHR_MAX) of total labor
#      hours?
#      If so, we have no way of discerning cost for a large proportion of the
#      total hours worked
##
otherhr <- man_costs[
  !is.na(man_costs$otherhours) &
    (man_costs$otherhours >
      OTHERHR_MAX * man_costs$totalhoursworked),
  "treatmentid"
]
cycle_rows[
  cycle_rows$treatmentid %in% otherhr,
  c("labor_other", "autoreject_cost")
] <- TRUE


## 13. Does cost calculation of the reported action rely on a missing constant?
#      if so, the cost cannot be calculated
##
cc_missing <- priceCheck(COST_CONSTS, man_costs)
cycle_rows[
  cycle_rows$treatmentid %in% cc_missing,
  c("missing_constant", "autoreject_cost")
] <- TRUE


# ==============================================================================
#  Determine which reports to display in the RMarkdown output and the checkboxUI
# ==============================================================================

## Determine which reports to display in RMarkdown output and checkbox UI
cycle_rows[
  (cycle_rows$wrongyear_man | cycle_rows$has_notes |
    cycle_rows$long_flood |
    cycle_rows$hydro_mismatch),
  "display"
] <- TRUE


man_issues <- cycle_rows

# ==============================================================================
#  clean up temporary variables
# ==============================================================================
suppressWarnings(rm(
  man_ids, active_mu, unique_reports, notes_reports, ap_ooc,
  phase_reports, phase_starts, early_reports, flood_tloc,
  flood_dorm, flood_grow, cut_incompatible, flood_incompatible,
  flood_reports, pre2021_coverage, pre2021_cover, low_cover,
  grow_dates, app_after_monitor, mdate_after_monitor,
  gam_reports, tloc_dates, tbm_reports, no_cost, man_costs,
  compare_cols, dup_rows, dup_ids, otherhr, cc_missing,
  cycle_rows, manage
))
# Several of these variables are created in conditionals and may not exist every
# time the script is run
