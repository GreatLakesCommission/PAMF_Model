# 2020-08-12
#
# This script finds reports with unsaved selections
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global Constants
#     RUNPATH  : the location of the model run directory
# * Variables
# * Functions
#   From checkbox-functions.R
#     getFlaggedMon
#     getFlaggedMan
# * Files in RUNPATH
#     monitor_issues.csv
#     manage_issues.csv
##

## If running outside of app.R, uncomment the following:
# options(stringsAsFactors=FALSE)

## Verify that all MUs have saved selections and
#  get the latest versions of mon_issues, man_issues
##
mon_issues <- read.csv(paste(RUNPATH, "monitor_issues.csv", sep = ""))
man_issues <- read.csv(paste(RUNPATH, "manage_issues.csv", sep = ""))

# Get IDs of flagged MUs that do not yet have saved decisions
flagged_mon <- getFlaggedMon(mon_issues, cycleend)
flagged_man <- getFlaggedMan(man_issues, cycleend)
flagged_mu <- union(flagged_mon$munitid, flagged_man$munitid)
flagged_mu <- flagged_mu[order(flagged_mu)]
