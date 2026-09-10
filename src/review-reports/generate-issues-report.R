# Render an RMarkdown version of the display shown on the checkbox screen of the
# PAMF model interface.
#
# Generating this file allows the user to take as much time as needed to
# review possible issues with monitoring and management reports, contact
# participants, and make decisions without having to keep the PAMF UI open the
# entire time.
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND      : the final year of the PAMF cycle being analyzed
#    RUNPATH       : path to directory of the ongoing model run
#    TRANSLOCATING : definition of the translocating phase
# * Variables
#    mon_data   : monitoring reports from the years CYCLEEND, CYCLEEND-1
#                 (unmodified from PAMFDATA$monitor)
#    man_data   : management reports from the years CYCLEEND, CYCLEEND-1
#                 (unmodified from PAMFDATA$manage)
#    mon_issues : possible issues associated with each monitoring report
#    man_issues : possible issues associated with each management report
#
# * Functions
#   From checkbox-functions.R:
#    getFlaggedMon
#    getFlaggedMan
#    getMAnotes
#    getPEnotes
#    getGCnotes
#    prettyMonitor
#    prettyManage
##

# #=============================================================================
# # Uncomment this section for script testing
# #=============================================================================
# options(stringsAsFactors=FALSE)
# message(">>> USING TEST DATA TO GENERATE OFFLINE ISSUES REPORT <<<")
#
# # Get functions
# source("./src/review-reports/checkbox-functions.R")
#
# # Define Constants
# source("./src/global-constants.R")
# CYCLEEND = 2018
# RUNPATH = "./src/review-reports/test-cases/" # Save output into the folder containing the test data
#
# # Get data
# mon_data = read.csv("./src/review-reports/test-cases/monitorTEST.csv")
# man_data = read.csv("./src/review-reports/test-cases/merged_manageTEST.csv")
#
# mon_issues = read.csv("./src/review-reports/test-cases/monitor_issues.csv")
# man_issues = read.csv("./src/review-reports/test-cases/manage_issues.csv")

# ==============================================================================
#  Format data and render the report
# ==============================================================================

## Replace some of the database codes for establishment, stem density
#  with human-readable values
##
monitor <- prettyMonitor(mon_data)
manage <- prettyManage(man_data)

## order everything by munitid
monitor <- monitor[order(monitor$munitid), ]
manage <- manage[order(manage$munitid), ]
mon_issues <- mon_issues[order(mon_issues$munitid), ]
man_issues <- man_issues[order(man_issues$munitid), ]

## Knit report.Rmd
rmarkdown::render("./src/review-reports/report.Rmd",
  params = list(
    mond = monitor, mand = manage, moni = mon_issues,
    mani = man_issues, ce = CYCLEEND
  ),
  output_file = "Reports_To_Review.docx", output_dir = RUNPATH,
  quiet = TRUE
)
