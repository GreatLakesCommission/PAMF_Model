# 2020-08-12
#
# Finds and displays reports that have been flagged for screening, organized by
# MU
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global Constants
#     PAMFDATA : named list containing enrollment, monitoring and management
#                reports for the current cycle
#     RUNPATH  : the location of the model run directory
#     CYCLEEND : the final year of the current cycle
#     REPORTBEGIN : The beginning of the reporting window for the cycle being
#                   analyzed
#     REPORTEND   : The end of the reporting window for the cycle being analyzed
# * Variables
# * Functions
#   from checkbox-functions.R:
#     prettyMonitor
#     prettyManage
#     getFlaggedMon
#     getFlaggedMan
#     muFragment
# * Files in RUNPATH:
#     monitor-issues.csv
#     manage-issues.csv
##

# =============================================================================
# Uncomment this section for script testing
#
# # TO DEBUG THE CHECKBOX DISPLAY: Run the app with this section of this
# # script uncommented. For details, see ./src/review-reports/test-cases/README.txt
# #=============================================================================
# options(stringsAsFactors=FALSE)
# message(">>> USING TEST DATA TO IDENTIFY FLAGGED REPORTS <<<")
#
# # Define Constants
# CYCLEEND = 2018
# REPORTBEGIN = as.Date("2017-08-01")
# REPORTEND   = as.Date("2018-08-01")
# RUNPATH = "./src/review-reports/test-cases/" # Save output into the folder containing the test data
#
# # Get data
# mon_data = read.csv("./src/review-reports/test-cases/monitorTEST.csv")
# man_data = read.csv("./src/review-reports/test-cases/merged_manageTEST.csv")
# mon_data$dateentered = as.Date(mon_data$dateentered)
# man_data$dateentered = as.Date(man_data$dateentered)
#
# PAMFDATA = list(monitor=mon_data, manage=man_data)


# ==============================================================================
#   Get data and functions
# ==============================================================================
source("./src/review-reports/checkbox-functions.R")

mon_data <- PAMFDATA$monitor
man_data <- PAMFDATA$manage

mon_issues <- read.csv(paste0(RUNPATH, "monitor_issues.csv"))
man_issues <- read.csv(paste0(RUNPATH, "manage_issues.csv"))

# Update 2025-08-26 - This section has been removed. It causes bugs when there
# are reports for the current cycle that have been added to the web hub in later
# cycles. For example, a monitoring report was submitted for 2018 in 2019, so
# when re-running the model for previous cycles, this report gets ignored here,
# but then it is still flagged and there is a mismatch between what appears in
# the decision screen and what is in the issues files. An error message appears
# when trying to run the model. The next section just chooses ANY flagged
# reports in the current issues file. It makes more sense that the monitoring
# and management data files used will contain the correct data for each cycle,
# rather than filtering it here.

## Only display issues for reports that were submitted within the current
#  reporting window
# # Get IDs of reports submitted between REPORTBEGIN and REPORTEND
# monrep_ids <- mon_data[mon_data$dateentered >= REPORTBEGIN &
#   mon_data$dateentered < REPORTEND, "monitorid"]
# 
# if ("dateentered" %in% colnames(man_data)) {
#   manrep_ids <- man_data[man_data$dateentered >= REPORTBEGIN &
#     man_data$dateentered < REPORTEND, "treatmentid"]
# } else {
#   # data were submitted before the 'dateentered' column existed in management
#   # reports. use managementdate instead
#   manrep_ids <- man_data[man_data$managementdate >= REPORTBEGIN &
#     man_issues$managementdate < REPORTEND, "treatmentid"]
# }
## Get *issues reports corresponding to reports in monrep_ids, manrep_ids
# mon_issues <- mon_issues[mon_issues$monitorid %in% monrep_ids, ]
# man_issues <- man_issues[man_issues$treatmentid %in% manrep_ids, ]

# Subset the issues that have not yet been removed and have been flagged for 
# display
mon_issues <- mon_issues[mon_issues$display == TRUE & is.na(mon_issues$reviewed_date), ]
man_issues <- man_issues[man_issues$display == TRUE & is.na(man_issues$reviewed_date), ]

# ==============================================================================
#  Format data, then get all MUs with monitoring and management reports
#  that have been flagged for human review
# ==============================================================================

# Replace some of the database codes with human-readable values
monitor <- prettyMonitor(mon_data)
manage <- prettyManage(man_data)

# get MUs with flagged reports
flagged_mon <- getFlaggedMon(mon_issues, CYCLEEND)
flagged_man <- getFlaggedMan(man_issues, CYCLEEND)

flagged_mu <- union(flagged_mon$munitid, flagged_man$munitid)
flagged_mu <- flagged_mu[order(flagged_mu)]

flagged_mu <- paste("mu", flagged_mu, sep = "")
# Fun Fact: It's only possible to hide the submit/undo tabs when the ID starts
# with a non-numeric character


# ==============================================================================
#   Display flagged reports and action buttons
# ==============================================================================
## Call a UI module for each MU, containing its flagged reports
insertUI("#put_mu_modules_here", ui = lapply(as.character(flagged_mu), muDispUI))
lapply(
  flagged_mu, muFragment, monitor, manage, mon_issues, man_issues, CYCLEEND,
  reactive(input$screener)
)

## Once all of the information is displayed, add the 'finalize' buttons.
#  Displaying these last prevents premature button pushes before the reports are
#  finished loading
insertUI("#finalize_buttons",
  ui = tagList(
    wellPanel(
      actionButton("quitfromcheckbox", label = "Finalize Saved Selections and Close"),
      em(helpText("Saved selections will be finalized and will not reappear next time.")),
      em(helpText("Re-set any selections that you do not want to finalize by clicking Change Selections.")),
      br(),
      actionButton("finalize", label = "Finalize All Selections and Run Model"),
      em(helpText("Selections must be saved for all management units beforehand.")),
      div(htmlOutput("finalize_msg"), style = "color:red")
    ),
    hr()
  )
)

# ==============================================================================
#   Clean up temporary variables
# ==============================================================================
rm(flagged_mon, flagged_man, flagged_mu, monitor, manage)
# rm(monrep_ids, manrep_ids, flagged_mon, flagged_man, flagged_mu, monitor, manage)