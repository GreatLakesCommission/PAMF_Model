# 2021-06-08
#
# This script handles report filtering and calls to subordinate scripts that
#   1. Ensure that the model uses a phase for each management application that
#      aligns with its application date (phase-date-agreement.R)
#   2. Build data packages from non-rejected reports (assemble-datpaks.R)
#   3. Document all possible issues with newly constructed data packages
#      (find-datpak-issues.R)
#
# Sourced by: app.R
#
# DEPENDENCIES:
# * Global Constants
#    RUNPATH  : path to output directory for this model run
#    CYCLEEND : end year of PAMF cycle for this model run
#    CYCLE    : years defining the PAMF cycle
#
# * Variables
#    mon_data    : monitoring reports within CYCLE
#    man_data    : management reports within CYCLE
#    enroll_data : enrollment reports, all years
#    mon_issues  : monitoring issues reports within CYCLE
#    man_issues  : management issues reports within CYCLE
#
# * Functions
#    several from datpak-functions.R (see subordinate scripts for details)
#
# * Files in RUNPATH
#    datpak-NOT-UPDATED.csv
##

## Source functions needed to construct data packages
source("./src/construct-datpaks/datpak-functions.R")


# # ============================================================================
# #  Uncomment this section for script testing
# # ============================================================================
# options(stringsAsFactors=FALSE)
# 
# message(">>> USING TEST DATA FOR DATA PACKAGES <<<")
# source("./src/global-constants.R")
# source("./src/construct-datpaks/datpak-functions.R")
# 
# CYCLEEND = 2525
# CYCLE = c(2524, 2525)
# REPORTBEGIN = as.Date("2524-08-10")
# REPORTEND = as.Date("2525-08-10")
# RUNPATH = "./src/construct-datpaks/test-cases/"
# 
# mon_data=read.csv("./src/construct-datpaks/test-cases/monitor-test-2021.csv")
# mon_data$monitoringdate = as.Date(mon_data$monitoringdate)
# 
# man_data  = read.csv("./src/construct-datpaks/test-cases/manage-test-2021.csv")
# man_data$applicationdate = as.Date(man_data$applicationdate)
# man_data$dateentered  = as.Date(man_data$dateentered)
# if("dateentered" %in% colnames(man_data)){man_data$dateentered  =
#   as.Date(man_data$dateentered)}
# 
# mon_issues = read.csv("./src/construct-datpaks/test-cases/monissues-test-2021.csv")
# man_issues = read.csv("./src/construct-datpaks/test-cases/manissues-test-2021.csv")


# ==============================================================================
#  Get relevant data for the cycle
#
#  Data packages are built from:
#
# * Monitoring reports from CYCLE whose coordreject_guid and autoreject_guid are
#   both FALSE
#   * Where either of these quantities is true, the report contains an issue
#     that prevents it from determining the MU's invasion state (e.g.
#     monitoring in the wrong month). This report then cannot be used to find
#     guidance for the MU, nor can it be included in the data package used in
#     the transition matrix update.
#   * It IS possible, however, to have reports that can be used for guidance but
#     not the matrix updates. See header of assemble-datpaks.R for an example.
#     Thus monitoring reports where *reject_model==TRUE are filtered out later.
#
# * Management reports from CYCLE and whose coordreject_model and
#   autoreject_model are FALSE.
#
# ==============================================================================

mon_for_datpak <- mon_issues[(mon_issues$coordreject_guid == FALSE &
  mon_issues$autoreject_guid == FALSE) &
  mon_issues$monitor_year %in% CYCLE, "monitorid"]

man_for_datpak <- man_issues[(man_issues$coordreject_model == FALSE &
                                man_issues$autoreject_model == FALSE) &
                               man_issues$manage_year %in% CYCLE, "treatmentid"]

monitor <- mon_data[mon_data$monitorid %in% mon_for_datpak, ]
manage <- man_data[man_data$treatmentid %in% man_for_datpak, ]

# Determine number of rows needed for datpak, datpak_issues data frames
mu_ids <- union(monitor$munitid, manage$munitid)
mu_ids <- mu_ids[order(mu_ids)]
n_rows <- length(mu_ids)

## --- Merge relevant monitoring dates to manage -------------------------------
#  This lets us determine whether management happened before monitoring in
#  manage_year
#
#  drop:
#   * out_of_window monitoring dates (autoreject_model is always TRUE in this
#     case)
#   * near_window monitoring dates with coordreject_guid==TRUE
#     These monitoring reports have a date issue AND have been designated as
#     not defining a usable state. Although the state's unusability may be due
#     to other factors (e.g. problems with stem counts), assume that there's a
#     problem with the date.
#
#  NOTE : coordinator-rejected reports without date issues DO contribute
#       their date information to these comparisons. That's because we know in
#       this case that the report was not rejected due to timing problems.
#       (Note also that this results in a different subset of reports than is
#       used by construct-datpaks.R)
#
##
ignore_mon <- mon_issues[
  (mon_issues$out_of_window == TRUE) |
    (mon_issues$near_window == TRUE &
      mon_issues$coordreject_guid == TRUE),
  "monitorid"
]

monitor_ok_timing <- mon_data[!mon_data$monitorid %in% ignore_mon, ]

manage <- merge(manage,
  monitor_ok_timing[, c("munitid", "monitor_year", "monitoringdate")],
  by.x = c("munitid", "manage_year"),
  by.y = c("munitid", "monitor_year"), all.x = TRUE
)


# ==============================================================================
#   Determine the phase of each non-rejected management report
#
#   Phase-relevant information appears twice in each report:
#     * the phase selected by the participant
#     * the date when the management action was carried out
#       (does not apply to REST, FLOOD reports)
#
#   For the purposes of the model, we consider application dates to be the more
#   reliable source of truth. To determine the report's phase, match the date
#   with its phase as defined in global-constants.R
#
#   This script call creates the following variables:
#     * man_changes : a record of reports with disagreements between the reported
#                     phase and reported date. Specifies the phase used by the
#                     model (data frame). man_changes will be appended to
#                     report-repairs.csv
#     * incoherent_phase_reports : treatmentid of reports whose phase cannot
#                                  be discerned from the information given (i.e.
#                                  applications done in a month where two phases
#                                  overlap and the reported phase belongs to
#                                  neither) (numeric)
#
#   It also makes the following changes to existing variables:
#     * adds 'model_phase' column to manage
#
# ==============================================================================
source("./src/construct-datpaks/phase-date-agreement.R", local = TRUE)

## Update man_issues with out_of_phase and unresolved_phase information
phase_differs <- unique(man_changes[
  man_changes$phase_reassign == TRUE,
  "treatmentid"
])

## Update man_issues with timing information
#  NOTE: Since man_changes pulls reports from a two-year window, each report
#        will appear in man_changes during the cycle it was submitted as well as
#        the following cycle. If the report is out of phase or has unresolved
#        phase, the corresponding column in man_issues will be updated each time
#        HOWEVER: any report that has one of these issues in one year will have
#        it in both years. Consequently we can write to these columns without
#        causing problems for repeatability.
man_issues[man_issues$treatmentid %in% phase_differs, "out_of_phase"] <- TRUE
man_issues[
  man_issues$treatmentid %in% incoherent_phase_reports,
  c("unresolved_phase", "autoreject_model")
] <- TRUE

## Remove any reports with unresolved phase from man_changes, manage
man_changes <- man_changes[!man_changes$treatmentid %in% incoherent_phase_reports, ]
manage <- manage[!manage$treatmentid %in% incoherent_phase_reports, ]

# man_changes<<-man_changes # uncomment to make visible after app exits


# ==============================================================================
#   Assemble data packages for non-rejected reports
#
#   Variables created in this script call:
#     datpak     : Data frame where each row records a data package, i.e. the
#                  unified state & transition information provided by the
#                  monitoring and management reports for each MU within the
#                  current cycle
#     cycle_list : A list whose elements contain all non-rejected management
#                  reports submitted for a single MU within the current cycle
# ==============================================================================
message("creating data packages...")

source("./src/construct-datpaks/assemble-datpaks.R", local = TRUE)


# ==============================================================================
#   Record all issues with each data package
#
#   Variables created in this script call:
#    datpak_issues : Data frame with a row for each newly created data package,
#                    detailing potential issues and whether the package should
#                    be used to update the transition and/or partial
#                    controllability matrices
# ==============================================================================
message("creating datpak_issues...")

source("./src/construct-datpaks/find-datpak-issues.R", local = TRUE)


# ==============================================================================
#   Assign data package ID numbers
# ==============================================================================
datpakid <- seq(1:nrow(datpak))
if (CYCLEEND > 2018) {
  # 2019 or later. Start with the ID after the last one in datpak
  old_datpak <- read.csv(paste0(RUNPATH, "datpak-NOT-UPDATED.csv"))
  old_max <- max(old_datpak$datpakid)
  datpakid <- datpakid + old_max
  rm(old_datpak, old_max)
}
datpak <- cbind(datpakid, datpak)
datpak_issues <- cbind(datpakid, datpak_issues)

# The datpakid associated with any application in man_changes is determined by
# the MU that the participant acted upon
man_changes <- merge(man_changes, datpak[, c("munitid", "datpakid")])


# ==============================================================================
# Clean up
# ==============================================================================
# Remove temporary variables
rm(
  mon_for_datpak, man_for_datpak, mu_ids, ignore_mon, monitor_ok_timing,
  incoherent_phase_reports, cycle_list, n_rows, datpakid
)
