# RECONSTRUCT THE 2018 MODEL RUN -----------------------------------------------
#
# In order to reconstruct the 2018 data, it's necessary to include some of the
# things we did manually:
#  * Added MUs 135, 136, 156 to the model run data, despite late monitoring.
#    (Participants were not yet allowed to monitor when these reports were
#    created. Monitoring was done instead by PAMF staff, who are confident in
#    the validity of the data)
#  * Added incomplete reports
#    (MUs 69, 70, 71, 102, 103, 104, 108, 116, 125, 126, 127, 145, 148, 149,
#     151, 154, 155)

#    In 2017-2018, GLC staff had to take most of the reports by phone,
#    using open-ended conversations. The ones listed here resulted in 'reports'
#    that contained enough information to be useful for the model update but not
#    enough to be submitted to the Web Hub (certain required values didn't come
#    up in conversation) As of 2021, incomplete reports ARE in the PAMF
#    database, and part of the code below is not run if these reports are
#    present in the data.
#
# This script does not, however, keep data packages that have issues detectable
# by the 2020 data cleaning algorithms but not the 2018-19 algorithms. These
# issues include:
#   * Management action covered < 76% of live Phragmites (MUs 77, 97)
#   * Out-of-phase reports
#
# For more details, see compare-to-2018.R in the construct-dpkg R project.
#
#
# Sourced by: app.R
#
# DEPENDENCIES
# Global Constants:
#   RUNPATH  : Directory path to the current model run. This must be a 2018
#              model run.
#   PAMFDATA : Formatted reports from the database
#   CYCLEEND : Year of the current model run (i.e. 2018)
#
# Functions:
#   writeOutput (from general-functions.R)
#   pasteNoNA   (from datpak-functions.R)
##

## ---- Get the necessary data -------------------------------------------------
#
#  If running in the app, this is all already in memory except for man_add
##
# options(stringsAsFactors=FALSE)
# monitor = PAMFDATA$monitor

# mon_issues = read.csv(paste(RUNPATH, "monitor_issues.csv", sep =""))
# man_issues = read.csv(paste(RUNPATH, "manage_issues.csv", sep =""))

# datpak = read.csv(paste(RUNPATH, "datpak.csv", sep =""))
# datpak_issues = read.csv(paste(RUNPATH, "datpak_issues.csv", sep =""))

# the most recent version of the incomplete reports

# mon_add = read.csv("./database-downloads/2018/incomplete-reports/monitoring_TOADD_2017_2018_2018-10-05.csv")
# These reports are redundant with existing monitoring reports

# These are the management treatmentids for the incomplete reports.
incomplete_treatids <- c(
  100, 104, 105, 106, 107, 108, 109, 110, 115, 116,
  117, 118, 121, 122, 123, 124, 125
)

# Check if these data are present, and if so, don't run parts of the code
# below. Provides either TRUE or FALSE:
incomplete_present <- all(incomplete_treatids %in% man_data$treatmentid)

# Note: in a the model runs 2018-2021, the following CSV was used:
# man_add <- read.csv("./database-downloads/2018/incomplete-reports/management_TOADD_2017_2018_2018-10-05.csv")

# However, from 2022 on base runs were created with this CSV:
if (incomplete_present == FALSE) {
man_add <- read.csv("./database-downloads/2018/incomplete-reports/management_TOADD_2017_2018_2022-03-24.csv")
}

# The only difference is the applicationids, which have been updated to match
# those used in the Web Hub (the incomplete reports were added to the PAMF
# Web Hub in January 2021). While incomplete treatment reports have the same
# treatmentids as in this spreadsheet, the applicationids differ. This
# difference has no implications for the model, other than that the
# report-repairs (generated below) for these reports should have the correct
# applicationids that match those in the Web Hub.

## ---- Un-reject data packages for MUs 135, 136 --------------------------
#
# This section needs to be run regardless of whether the incomplete management
# reports are present. 
#
#  Note about MU 136: We investigated the decrease in invasion state from 4 to 1
#  and confirmed that no management action took place in 2017 (2023-02-08)
# 
# 2026-02-13 - After further investigation, the datpak from MU 156 from 2018
# should have been rejected since their translocating report was rejected in
# the more recent data QA/QC in 2020. This code was creating a "RR" datapackage
# erroneously and thus MU 156 has been removed from this section of code.
#
#   1. Un-reject monitoring reports 99, 113
#   2. Write the management combinations from 2018 into datpak
#      (this can be found by running getCycle() on the cleaned data sets from
#       2018.)
#      (for a ready-to-go version of this, see compare-to-2018.R in the
#       construct-dpkg R project.
#   3. Un-reject the data packages for MUs 135, 136
##

## Un-reject monitoring reports 99, 113
#  Get the state of each MU, ignoring the monitoring date cutoff
#  Set coordreject_model and auto_reject model to FALSE
#  Set reviewed_by to "datmod_2018 script"
##

# Get states
monitor <- mon_data[mon_data$monitorid %in% c(99, 113), ]
mean_dens <- rowMeans(monitor[, c(
  "q1stemcount", "q2stemcount", "q3stemcount",
  "q4stemcount", "q5stemcount"
)])

# MU 135: establishment is 2, mean dens is 12 (STATE 6)
# MU 136: establishment is 1, mean dens is 13 (STATE 4)
datpak[datpak$munitid %in% c(135, 136), "state_begin"] <- c(6, 4)

datpak[datpak$munitid %in% c(135, 136), "pr_est0_begin"] <- c(0, 0)
datpak[datpak$munitid %in% c(135, 136), "pr_est1_begin"] <- c(0, 1)
datpak[datpak$munitid %in% c(135, 136), "pr_est2_begin"] <- c(1, 0)

datpak[datpak$munitid %in% c(135, 136), "pr_lo_begin"] <- c(0.4, 0.4)
datpak[datpak$munitid %in% c(135, 136), "pr_hi_begin"] <- c(0.6, 0.6)

# Un-reject
mon_issues[
  mon_issues$monitorid %in% c(99, 113),
  c("coordreject_model", "autoreject_model")
] <- FALSE
mon_issues[
  mon_issues$monitorid %in% c(99, 113),
  "reviewed_by"
] <- "datmod_2018 script"
mon_issues[
  mon_issues$monitorid %in% c(99, 113),
  "coordreject_note"
] <- "see datamod_2018.R"


## Write the management combinations from 2018 into the data package
##
datpak[datpak$munitid == 135, "t_actions"] <- "G+"
datpak[datpak$munitid == 135, "d_actions"] <- "R"
datpak[datpak$munitid == 135, "g_actions"] <- "R"

datpak[datpak$munitid == 136, "t_actions"] <- "R"
datpak[datpak$munitid == 136, "d_actions"] <- "R"
datpak[datpak$munitid == 136, "g_actions"] <- "R"

## Un-reject the data packages for MUs 135, 136
##
datpak_issues[
  datpak_issues$munitid %in% c(135, 136),
  c("wrong_comb", "mon_begin_rej_model", "autoreject_model")
] <- FALSE

# Only run the below if the incomplete reports are NOT in the dataframe
if (incomplete_present == FALSE) {
  
  ## ---- Construct data packages for incomplete reports -----------------------
  #
  #  The only information in mon_add and man_add that isn't redundant with
  #  PAMFDATA is the translocating reports in man_add. Write those actions in to
  #  datpak and repair datpak_issues accordingly
  ##

  ## Monitoring
  #  Do nothing-- all added reports are redundant with existing reports in
  #  PAMFDATA$monitor

  ## Management
  #  The dormant and growing actions are redundant with the information in
  #  PAMFDATA$manage
  #  Focus on translocating actions only


  for (mu in intersect(datpak$munitid, man_add$munitid)) {
    datpak[datpak$munitid == mu, "t_actions"] <-
      unique(man_add[man_add$munitid == mu & man_add$phase == 0, "mnt_act"])
  }

  # Re-generate mnt_comb column
  datpak <- datpak[, colnames(datpak)[which(colnames(datpak) != "mnt_comb")]] # get rid of the old version of the column
  mntcomb_list <- split(
    datpak[, c("t_actions", "d_actions", "g_actions")],
    datpak$munitid
  )
  mnt_comb <- lapply(mntcomb_list, pasteNoNA)
  mnt_comb <- do.call(rbind, mnt_comb)
  datpak <- cbind(datpak, mnt_comb)


  ## Un-reject reports UNLESS they've also been rejected by the coordinator
  drop_these_mon <- mon_issues[mon_issues$munitid %in% man_add$munitid &
    mon_issues$coordreject_model, "munitid"]
  drop_these_man <- man_issues[man_issues$munitid %in% man_add$munitid &
    man_issues$coordreject_model, "munitid"]

  # Undo datpak_issues that were set to TRUE without incomplete reports
  add_mu <- setdiff(man_add$munitid, drop_these_man)
  datpak_issues[
    datpak_issues$munitid %in% add_mu,
    c("t_act_missing", "wrong_comb")
  ] <- FALSE
  # only update the t_act_missing column because the others are redundant (see
  # above)

  # Undo rejection for MUs with no coordinator-rejected reports
  drop_these <- c(drop_these_mon, drop_these_man)
  add_mu <- setdiff(man_add$munitid, drop_these)
  datpak_issues[datpak_issues$munitid %in% add_mu, "autoreject_model"] <- FALSE

  ### Construct report-repairs for "incomplete reports" ------------------------
  #
  # This code adds report-repairs entries for the incomplete reports. These
  # reports are loaded into the model by a CSV separate from the PAMF Web Hub
  # data download, but these reports were added to the Web Hub database in
  # January 2021.

  man_add <- man_add[which(man_add$treatmentid %in% incomplete_treatids), ]
  man_rows <- nrow(man_add)

  # Add a column for the numerical db codes
  man_add$mnt_act_num <- ifelse(man_add$mnt_act == "G", GLYPH$db,
    ifelse(man_add$mnt_act == "G+", GLYPHPLUS$db,
      NA
    )
  )

  man_changes_incomplete <-
    data.frame(
      munitid = man_add$munitid,
      treatmentid = man_add$treatmentid,
      applicationid = man_add$applicationid,
      model_cycle = rep(2018, man_rows),
      phase_reassign = rep(FALSE, man_rows),
      model_phase = man_add$phase,
      created_rest = rep(FALSE, man_rows),
      action_reassign = rep(FALSE, man_rows),
      model_action = man_add$mnt_act_num,
      datpakid = rep(NA, man_rows)
    )

  # Add the datpak ID
  for (mu in unique(man_add$munitid)) {
    man_changes_incomplete[man_changes_incomplete$munitid == mu, "datpakid"] <-
      unique(datpak[datpak$munitid == mu, "datpakid"])
  }


  man_changes <- rbind(man_changes, man_changes_incomplete)


  ### Construct manage_issues for "incomplete reports" -------------------------

  # Remove the applicationids and date so there aren't duplicate treatmentids
  man_add$applicationid <- NULL
  man_add$applicationdate <- NULL
  man_add <- man_add[!duplicated(man_add), ]
  man_rows <- nrow(man_add)

  # Constrct the man_issues for incomplete reports
  man_issues_incomplete <-
    data.frame(
      treatmentid = man_add$treatmentid,
      munitid = man_add$munitid,
      cycle_end = rep(2018, man_rows),
      run_date = rep(strftime(Sys.time(), "%Y-%m-%d"), man_rows),
      manage_year = rep(2017, man_rows),
      wrongyear_man = rep(FALSE, man_rows),
      has_notes = rep(FALSE, man_rows),
      out_of_phase = rep(FALSE, man_rows),
      short_flood = rep(FALSE, man_rows),
      long_flood = rep(FALSE, man_rows),
      hydro_mismatch = rep(FALSE, man_rows),
      low_coverage = rep(FALSE, man_rows),
      duplicated_cost = rep(FALSE, man_rows),
      no_cost_data = rep(TRUE, man_rows),
      old_cost_qaqc = rep(FALSE, man_rows),
      labor_other = rep(FALSE, man_rows),
      missing_constant = rep(FALSE, man_rows),
      display = rep(FALSE, man_rows),
      coordreject_model = rep(FALSE, man_rows),
      coordreject_cost = rep(TRUE, man_rows),
      coordreject_amu = rep(FALSE, man_rows),
      coordreject_note = rep("see datamod_2018.R", man_rows),
      reviewed_by = rep("see datamod_2018.R", man_rows),
      reviewed_date = rep(strftime(Sys.time(), "%Y-%m-%d"), man_rows),
      autoreject_model = rep(FALSE, man_rows),
      autoreject_cost = rep(TRUE, man_rows),
      unresolved_phase = rep(FALSE, man_rows)
    )

  man_issues <- rbind(man_issues, man_issues_incomplete)
}

## Construct report-repairs for report that was in the wrong cycle (2017) ------
#
# This code adds an entry in report-repairs for a single report for munitid =
# 161 / treatmentid = 328 that was in in the incorrect cycle due to its timing:
# it was reported as a translocating action for 2017/2018 cycle, but it occurred
# before the 2017 monitoring report, pushing it back into the 2016/2017 cycle,
# which doesn't exist. It back filled a rest report for 2017/2018 translocating
# which appears in the report-repairs, but this report does not appear in
# report-repairs since the cycle it matches up with doesn't exist, so we will
# add it back in manually so there is a record of how it was handled by the
# model.

man_changes_2017 <-
  data.frame(
    munitid = 161,
    treatmentid = 328,
    applicationid = 146,
    model_cycle = 2017,
    phase_reassign = TRUE,
    model_phase = 2,
    created_rest = FALSE,
    action_reassign = FALSE,
    model_action = 0,
    datpakid = NA
  )

man_changes <- rbind(man_changes_2017, man_changes)

# ---- Clean Up ----------------------------------------------------------------
suppressWarnings(rm(
  man_add, mu, mntcomb_list, mnt_comb, man_changes_2017, man_changes_incomplete,
  man_rows, man_issues_incomplete
))
