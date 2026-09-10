# RECONSTRUCT THE 2019 MODEL RUN -----------------------------------------------
#
# Note: Much of this script is defunct, and report rejections are now dealt with
# via the coordinator rejections in the QA/QC process that was implemented in
# 2020. In order to prevent conflicts between report rejections by the
# coordinator and this code, I (TRT) am commenting out all of the code used in
# 2019 only.
#

# Get the necessary data -------------------------------------------------------

man_changes <- read.csv(paste(RUNPATH, "report-repairs.csv", sep = ""))
datpak_issues <- read.csv(paste(RUNPATH, "datpak_issues.csv", sep = ""))
mon_issues <- read.csv(paste(RUNPATH, "monitor_issues.csv", sep = ""))
man_issues <- read.csv(paste(RUNPATH, "manage_issues.csv", sep = ""))

# Reconstruct the 2019 data ----------------------------------------------------
# NOTE: CODE IS DEFUNCT AND HERE FOR POSTERITY, SUPERCEDED BY COORDINATOR 
# DECISIONS IMPLEMENTED IN 2020
#
# In order to reconstruct the 2019 data, it's necessary to include some of the
# things we did manually:
#   * Some data packages (referred to as MUs since there's one data package per
#     MU in each cycle) were withheld from the model manually either by Sam or
#     myself.
#     e.g. I withheld MU 144's reports from the cost update due to information
#          in the notes section, which isn't machine readable. ("Costs are
#          in CAD")
#
# This script does not, however, keep data packages that have issues detectable
# by the 2020 data cleaning algorithms but not the 2018-19 algorithms. These
# issues include:
#   * Management action covered < 76% of live Phragmites 
#   * Out-of-phase reports
#
# For more details, see compare-to-2019.R in the construct-dpkg R project.
# # Note: Above project is internal use only.
#
# Sourced by: app.R
#
# DEPENDENCIES
# Global constants:
#   RUNPATH  : Directory path to the current model run. This must be a 2019
#              model run.
#   PAMFDATA : Formatted reports from the database
#   CYCLEEND : Year of the current model run (i.e. 2019)
#
# Variables:
#   mon_data    : monitoring reports from the current cycle (i.e. 2019-2020)
#   enroll_data : all enrollment reports
#
# functions:
#   writeOutput (from general-functions.R)
##

# UNCOMMENT THIS IF RUNNING SCRIPT OUTSIDE OF THE APP:
# options(stringsAsFactors=FALSE)
# 
# # Exclude from transition matrix -----------------------------------------------
# ## Make sure that model-excluded data packages don't go to the transition
# # matrix update
# 
# # Management unit ids of units to exclude from the model
# exclude_tm <- c(97, 102, 132, 143, 145, 154, 252)
# 
# # For testing:
# # message("")
# # message("exclude 2019")
# # message(cat(exclude_tm))
# # message("")
# datpak_issues[
#   datpak_issues$munitid %in% exclude_tm & datpak_issues$cycle_end == 2019,
#   "autoreject_model"
# ] <- TRUE
# 
# # Exclude from guidance --------------------------------------------------------
# #   Make sure that guidance-excluded data packages don't get assigned guidance
# #   In 2020 onward, guidance exclusions are recorded at the level of
# #   monitoring reports, because:
# #      (a) Monitoring reports define the MU's state. Without usable state
# #          information in CYCLEEND, there is no guidance that applies to the MU
# #      (b) There is only one monitoring report per MU per year.
# ##
# 
# # Management unit ids to exclude from guidance 
# exclude_gu <- c(75, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 
#                 395, 396, 397, 398, 399, 400, 401, 402, 403, 404)
# 
# exclude_mon <- mon_data[mon_data$munitid %in% exclude_gu &
#   mon_data$monitor_year == CYCLEEND, "monitorid"]
# 
# mon_issues[
#   mon_issues$monitorid %in% exclude_mon,
#   c("coordreject_guid")
# ] <- TRUE
# mon_issues[
#   mon_issues$monitorid %in% exclude_mon,
#   c("reviewed_by")
# ] <- "datmod_2019 script"
# mon_issues[
#   mon_issues$monitorid %in% exclude_mon,
#   c("coordreject_note")
# ] <- "see datamod_2019.R"

# # Exclude from costs -----------------------------------------------------------
# # Make sure that cost-excluded data don't contribute to the cost calculations
# # There's only one of these-- Report 573 has a note that costs are given in
# # Canadian dollars (we ask for USD)
# 
# man_issues[man_issues$treatmentid == 573, "coordreject_cost"] <- TRUE
# man_issues[man_issues$treatmentid == 573, "reviewed_by"] <- "datmod_2019 script"
# man_issues[man_issues$treatmentid == 573, "coordreject_note"] <- "see datamod_2019.R"

# Add datpak for MU 80 ---------------------------------------------------------
# MU 80 had three treatment reports (treatmentid = c(426, 427, 428) that were
# not getting rolled up into a cycle because of the date associated with the
# reports not aligning with the report_begin and report_end dates. The PAMF
# coordinator had been to the site, and said these three reports should be from
# translocating (phase = 0) of cycle_end = 2019. However, the dates were all
# 2018-06-15 for all three reports for managementdate and dateentered.
# dateentered was not yet a column in the database though, so dateentered became
# whatever they put for managementdate. Based on the high numbers of the
# treatmentids (which are added sequentially to the web hub), these reports were
# likely entered some time in late 2018 or early 2019. Additionally, these
# reports only appear in the 2019 datapull, not the 2018 data pull. In short,
# these reports should have been added to the 2019 datapak with a single action=
# flood, and report-repairs needs the reports appended to show which cycle they
# go to, as they were previously not accounted for in report-repairs.

# Update the 2019 datpak
# Translocating action - flood
datpak[datpak$munitid == 80 & datpak$cycle_end == 2019, "t_actions"] <- "F"
#update management combo - flood
datpak[datpak$munitid == 80 & datpak$cycle_end == 2019, "mnt_comb"] <- "F"

# Update the 2019 datpak_issues
datpak_issues$t_act_missing[which(
  datpak_issues$munitid == 80 & datpak_issues$cycle_end == 2019
  )] <- FALSE

# Add to man_changes (report-repairs)
mu_80_man_changes <- 
  data.frame(
    munitid = rep(80, 3),
    treatmentid = c(426, 427, 428),
    applicationid = rep(NA, 3),
    model_cycle =	rep(2019, 3),
    phase_reassign = rep(FALSE, 3),
    model_phase = rep(0, 3),
    created_rest = rep(FALSE, 3),
    action_reassign = rep(FALSE, 3),
    model_action = rep(8, 3),
    datpakid = rep(
      datpak$datpakid[which(datpak$munitid == 80 & datpak$cycle_end == 2019)], 3
      )
  )

man_changes <- rbind(man_changes, mu_80_man_changes)

# add notes to man_issues directing user to this script
man_issues[man_issues$treatmentid == 426, "reviewed_by"] <- paste(
  man_issues[man_issues$treatmentid == 426, "reviewed_by"], 
  "; see datmod_2019 script"
  )
man_issues[man_issues$treatmentid == 426, "coordreject_note"] <- paste(
  man_issues[man_issues$treatmentid == 426, "coordreject_note"],
  "; see datamod_2019.R"
)
man_issues[man_issues$treatmentid == 427, "reviewed_by"] <- paste(
  man_issues[man_issues$treatmentid == 427, "reviewed_by"], 
  "; see datmod_2019 script"
)
man_issues[man_issues$treatmentid == 427, "coordreject_note"] <- paste(
  man_issues[man_issues$treatmentid == 427, "coordreject_note"],
  "see datamod_2019.R"
)
man_issues[man_issues$treatmentid == 428, "reviewed_by"] <- paste(
  man_issues[man_issues$treatmentid == 428, "reviewed_by"], 
  "; see datmod_2019 script"
)
man_issues[man_issues$treatmentid == 428, "coordreject_note"] <- paste(
  man_issues[man_issues$treatmentid == 428, "coordreject_note"],
  "see datamod_2019.R"
)

# Clean Up ---------------------------------------------------------------------
suppressWarnings(rm(mu_80_man_changes, exclude_gu, exclude_mon, exclude_tm))
