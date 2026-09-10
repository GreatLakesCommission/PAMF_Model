# 2020-03-25
# Functions supporting the checkbox interface
#
# Functions
# * muFragment        : Calls the outer module (MU display) for MU with
#                       munitid=id and its appropriate data
# * getFlaggedMon     : Get the munitid of each MU with flagged monitoring
#                       report(s) in the PAMF cycle to be analyzed
# * getFlaggedMan     : Get the munitid of each MU with flagged monitoring
#                       report(s) in the PAMF cycle to be analyzed
# * getMonFlags       : Return all possible issues with a given monitoring report
# * getManFlags       : Return all possible issues with a given management report
# * getMAnotes        : Return all notes pertaining to the reported management
#                       action
# * getPEnotes        : Return all notes pertaining to the products and equipment
#                       listed in a management report
# * getGCnotes        : Return all notes pertaining to whether a management
#                       report complies with guidance
# * saveSelectionsMon : Write screener's selections into monissues and save
# * saveSelectionsMan : Write screener's selections into manissues and save
# * prettyMonitor     : Replace database codes with human-readable values
# * prettyManage      : Replace database codes with human-readable values
##


muFragment <- function(id, mon_data, man_data, monissues, manissues, cycleend,
                       screener_name) {
  ## Calls the outer module (MU display) for MU with munitid=id and its
  #  appropriate data
  #
  # INPUT
  # id        : The muDisp (outer module) ID. Appended "mu" to the munitid
  #             (character)
  # mon_data  : Monitoring reports (dataframe)
  # man_data  : Management reports (dataframe)
  # monissues : Possible issues with each monitoring report (dataframe)
  # manissues : Possible issues with each management report (dataframe)
  # cycleend  : The second year of the PAMF cycle being analyzed (numeric)
  # screener_name : Name of the person screening the reports for issues
  #                 (reactive)
  #
  # OUTPUT
  # the outer module
  #
  # ASSUMPTIONS
  #   * modules are sourced
  #   * All dataframes have the following column:
  #       munitid
  ##

  ## Separate the munitid from the module iD
  munitid <- substr(id, start = 3, stop = nchar(id))

  ## Get the IDs of the flagged reports within the current MU
  #  (MUs may have a combination of flagged, unflagged reports)
  flagged_mon <- getFlaggedMon(monissues[monissues$munitid == munitid, ], cycleend)
  flagged_man <- getFlaggedMan(manissues[manissues$munitid == munitid, ], cycleend)

  mondata_mu <- mon_data[mon_data$monitorid %in% flagged_mon$monitorid, ]
  mandata_mu <- man_data[man_data$treatmentid %in% flagged_man$treatmentid, ]

  callModule(muDispServer,
    id = id, mondata_mu, mandata_mu, monissues, manissues,
    screener_name
  )
}

getFlaggedMon <- function(monissues, cycleend) {
  # Get the munitid of each MU with flagged monitoring report(s) in the
  # PAMF cycle to be analyzed
  #
  # INPUT
  # monissues : dataframe with columns denoting which monitoring reports have
  #             which issues
  # cycleend  : the year ending the PAMF cycle analyzed in the current model run
  #
  # OUTPUT
  # MU and report IDs associated with each monitoring report that has at least
  # one issue (dataframe)
  #
  # ASSUMPTIONS
  # * monissues has the following columns:
  #     reviewed_date
  #     display
  #     monitorid
  #     munitid
  ##

  ## Display flagged reports with no prior decision, regardless of
  #  managementdate, dateentered
  ## Return reports that:
  #   * Don't have a coordinator decision yet (first and second lines of
  #     conditional)
  #   * Are flagged for one or more issues (third through fifth lines)
  return(unique(monissues[
    is.na(monissues$reviewed_date) &
      monissues$display == TRUE,
    c("monitorid", "munitid")
  ]))
} # end getFlaggedMon

getFlaggedMan <- function(manissues, cycleend) {
  # Get the munitid of each MU with flagged monitoring report(s) in the
  # PAMF cycle to be analyzed
  #
  # INPUT
  # manissues : dataframe with columns denoting which management reports have
  #             which issues
  # cycleend  : the year ending the PAMF cycle analyzed in the current model run
  #
  # OUTPUT
  # MU and report IDs associated with each management report that has at least
  # one issue (dataframe)
  #
  # ASSUMPTIONS
  # * manissues has the following columns:
  #     display
  #     reviewed_date
  #     treatmentid
  #     munitid
  ##

  ## Display flagged reports with no prior decision, regardless of
  #   managementdate, dateentered
  ## Return reports that:
  #   * Don't have a coordinator decision yet (first and second lines of
  #     conditional)
  #   * Are flagged for one or more issues (fifth and sixth lines)

  return(unique(manissues[
    is.na(manissues$reviewed_date) &
      manissues$display == TRUE,
    c("treatmentid", "munitid")
  ]))
} # end getFlaggedMan

getMonFlags <- function(monitorid, mon_issues) {
  # Return all possible issues with a given monitoring report
  #
  # INPUT
  # monitorid  : ID of a monitoring report (numeric)
  # mon_issues : Monitoring reports with possible issues (dataframe)
  #
  # OUTPUT
  # A character string with descriptions of each flagged issue,
  # separated by the HTML character <br>
  #
  # ASSUMPTIONS
  # * monitorid appears in mon_issues$monitorid
  # * no two reports share a monitorid value (monitiorid is unique)
  # * mon_issues has the following columns:
  #     monitorid
  #     multiple_reports
  #     has_notes
  #     near_window
  #     stems_missing
  #     stems_zero
  #     stems_high
  ##

  flags <- list() # variable to hold all flags
  mi_row <- mon_issues[mon_issues$monitorid == monitorid, ] # pull up report monitorid

  if (mi_row$wrongyear_mon == TRUE) {
    flags <- paste(flags, "Monitoring date does not match end year of current cycle",
      "<br>",
      sep = ""
    )
  }
  if (mi_row$year_mismatch == TRUE) {
    flags <- paste(flags, "Monitoring date differs from year of report submission",
      "<br>",
      sep = ""
    )
  }
  if (mi_row$month_mismatch == TRUE) {
    flags <- paste(flags, "Monitoring report was submitted during the summer, with a non-summer monitoring date",
      "<br>",
      sep = ""
    )
  }
  if (mi_row$near_manage == TRUE) {
    flags <- paste(flags, "MU monitored less than a month after management",
      "<br>",
      sep = ""
    )
  }
  if (mi_row$near_window == TRUE) {
    flags <- paste(flags, "Monitoring occurred in June or August",
      "<br>",
      sep = ""
    )
  }
  # I'm skipping out_of_window because that is checked in a later step
  if (mi_row$stems_missing == TRUE) {
    flags <- paste(flags, "One or more stem counts may be missing",
      "<br>",
      sep = ""
    )
  }
  if (mi_row$stems_zero == TRUE) {
    flags <- paste(flags, "One or more stem counts is zero", "<br>", sep = "")
  }
  if (mi_row$stems_high == TRUE) {
    flags <- paste(flags, "One or more stem counts is unexpectedly high",
      "<br>",
      sep = ""
    )
  }
  if (mi_row$has_notes == TRUE) {
    flags <- paste(flags, "There are notes to review", "<br>", sep = "")
  }

  return(flags)
} # end getMonFlags

getManFlags <- function(treatmentid, man_issues) {
  # Return all possible issues with a given management report
  #
  # INPUT
  # monitorid  : ID of a management report (numeric)
  # mon_issues : Management reports with possible issues (dataframe)
  #
  # OUTPUT
  # A character string with descriptions of each flagged issue,
  # separated by the HTML character <br>
  #
  # ASSUMPTIONS
  # * treatmentid appears in man_issues$treatmentid
  # * man_issues has the following columns:
  #     treatmentid
  #     wrongyear_man
  #     year_mismatch
  #     out_of_phase
  #     short_flood
  #     long_flood
  #     hydro_mismatch
  ##

  flags <- NULL # variable to hold all flags
  mi_row <- man_issues[man_issues$treatmentid == treatmentid, ] # report monitorid

  if (any(mi_row$wrongyear_man == TRUE)) {
    flags <- paste(flags, "One or more application dates not in current cycle",
      "<br>",
      sep = ""
    )
  }
  if (any(mi_row$out_of_phase == TRUE)) {
    flags <- paste(flags, "Management/Application date(s) are not in the reported phase",
      "<br>",
      sep = ""
    )
  }
  if (any(mi_row$long_flood == TRUE)) {
    flags <- paste(flags, "Flood outlasted the reported phase. There may be additional Flood reports on the Web Hub",
      "<br>",
      sep = ""
    )
  }
  if (any(mi_row$hydro_mismatch == TRUE)) {
    flags <- paste(flags, "Management action is incompatible with hydrologic condition",
      "<br>",
      sep = ""
    )
  }
  if (any(mi_row$has_notes == TRUE)) {
    flags <- paste(flags, "There are notes to review", "<br>", sep = "")
  }

  return(flags)
} # end getManFlags

getMAnotes <- function(report) {
  # Return all notes pertaining to the reported management action
  #
  # INPUT
  # report : a management report (dataframe)
  #
  # OUTPUT
  # A character string representation of each notes field, separated by the HTML
  # tag <br>
  #
  # ASSUMPTIONS
  # * report is a dataframe with a single row
  # * report has the following columns:
  #     glyphnotes
  #     glyphplusnotes
  #     imaznotes
  #     prenotes
  #     mechnotes
  #     removenotes
  #     cutnotes
  #     spadenotes
  #     floodnotes
  #     restnotes
  #     othernotes
  #     cutdescribe
  #     predescribe
  #     other
  ##

  ma_notes <- NULL
  if (nrow(report) > 0) {
    if (!is.na(report$glyphnotes)) {
      ma_notes <- paste(ma_notes, report$glyphnotes, "<br>", sep = "")
    }
    if (!is.na(report$glyphplusnotes)) {
      ma_notes <- paste(ma_notes, report$glyphplusnotes, "<br>", sep = "")
    }
    if (!is.na(report$imaznotes)) {
      ma_notes <- paste(ma_notes, report$imaznotes, "<br>", sep = "")
    }
    if (!is.na(report$prenotes)) {
      ma_notes <- paste(ma_notes, report$prenotes, "<br>", sep = "")
    }
    if (!is.na(report$mechnotes)) {
      ma_notes <- paste(ma_notes, report$mechnotes, "<br>", sep = "")
    }
    if (!is.na(report$removenotes)) {
      ma_notes <- paste(ma_notes, report$removenotes, "<br>", sep = "")
    }
    if (!is.na(report$cutnotes)) {
      ma_notes <- paste(ma_notes, report$cutnotes, "<br>", sep = "")
    }
    if (!is.na(report$spadenotes)) {
      ma_notes <- paste(ma_notes, report$spadenotes, "<br>", sep = "")
    }
    if (!is.na(report$floodnotes)) {
      ma_notes <- paste(ma_notes, report$floodnotes, "<br>", sep = "")
    }
    if (!is.na(report$other)) {
      ma_notes <- paste(ma_notes, report$other, "<br>", sep = "")
    }
    if (!is.na(report$restnotes)) {
      ma_notes <- paste(ma_notes, report$restnotes, "<br>", sep = "")
    }
    if (!is.na(report$othernotes)) {
      ma_notes <- paste(ma_notes, report$othernotes, "<br>", sep = "")
    }
    if (!is.na(report$cutdescribe)) {
      ma_notes <- paste(ma_notes, report$cutdescribe, "<br>", sep = "")
    }
    if (!is.na(report$predescribe)) {
      ma_notes <- paste(ma_notes, report$predescribe, "<br>", sep = "")
    }
    if (is.null(ma_notes)) {
      ma_notes <- NA
    }
  }

  return(ma_notes)
} # end getMAnotes

getPEnotes <- function(report) {
  # Return all notes pertaining to the products and equipment listed in a
  # management report
  #
  # INPUT
  # report : a management report (dataframe)
  #
  # OUTPUT
  # A character string representation of each notes field, separated by the HTML
  # tag <br>
  #
  # ASSUMPTIONS
  # * report is a dataframe with a single row
  # * report has the following columns:
  #     glyphsurfactantused
  #     glyphplussurfactantused
  #     imazsurfactantused
  #     glyphproductother
  #     glyphplusproductother
  #     imazproductother
  #     glyphplusaddedother
  #     glyphequipmodel
  #     imazequipmodel
  #     removeequipmodel
  #     mechequipmodel
  #     cutequipmodel
  #     preequipmodel
  ##

  pe_notes <- NULL
  if (nrow(report) > 0) {
    if (!is.na(report$glyphsurfactantused)) {
      pe_notes <- paste(pe_notes, report$glyphsurfactantused, "<br>", sep = "")
    }
    if (!is.na(report$glyphplussurfactantused)) {
      pe_notes <- paste(pe_notes, report$glyphplussurfactantused, "<br>", sep = "")
    }
    if (!is.na(report$imazsurfactantused)) {
      pe_notes <- paste(pe_notes, report$imazsurfactantused, "<br>", sep = "")
    }
    if (!is.na(report$glyphproductother)) {
      pe_notes <- paste(pe_notes, report$glyphproductother, "<br>", sep = "")
    }
    if (!is.na(report$glyphplusproductother)) {
      pe_notes <- paste(pe_notes, report$glyphplusproductother, "<br>", sep = "")
    }
    if (!is.na(report$imazproductother)) {
      pe_notes <- paste(pe_notes, report$imazproductother, "<br>", sep = "")
    }
    if (!is.na(report$glyphplusaddedother)) {
      pe_notes <- paste(pe_notes, report$glyphplusaddedother, "<br>", sep = "")
    }
    if (!is.na(report$glyphequipmodel)) {
      pe_notes <- paste(pe_notes, report$glyphequipmodel, "<br>", sep = "")
    }
    if (!is.na(report$glyphplusequipmodel)) {
      pe_notes <- paste(pe_notes, report$glyphplusequipmodel, "<br>", sep = "")
    }
    if (!is.na(report$imazequipmodel)) {
      pe_notes <- paste(pe_notes, report$imazequipmodel, "<br>", sep = "")
    }
    if (!is.na(report$removeequipmodel)) {
      pe_notes <- paste(pe_notes, report$removeequipmodel, "<br>", sep = "")
    }
    if (!is.na(report$mechequipmodel)) {
      pe_notes <- paste(pe_notes, report$mechequipmodel, "<br>", sep = "")
    }
    if (!is.na(report$cutequipmodel)) {
      pe_notes <- paste(pe_notes, report$cutequipmodel, "<br>", sep = "")
    }
    if (!is.na(report$preequipmodel)) {
      pe_notes <- paste(pe_notes, report$preequipmodel, "<br>", sep = "")
    }
    if (is.null(pe_notes)) {
      pe_notes <- NA
    }
  }

  return(pe_notes)
} # end getPEnotes

getGCnotes <- function(report) {
  # Return all notes pertaining to whether a management report complies with
  # guidance
  #
  # INPUT
  # report : a management report (dataframe)
  #
  # OUTPUT
  # A character string representation of each notes field, separated by the HTML
  # tag <br>
  #
  # ASSUMPTIONS
  # * report has the following columns:
  #    followdescribe
  ##

  if (nrow(report) > 0) {
    return(report$followdescribe)
  } else {
    return(NULL)
  }
} # end getGCnotes

saveSelectionsMon <- function(monreps_ids, mon_choices, screener_name,
                              file_path = "./") {
  # Write screener's selections into monissues and save
  #
  # INPUT
  # monreps_ids   : IDs of all monitoring reports subject to a screening
  #                 decision (numeric)
  # mon_choices   : The screener's choices, input via checkbox (reactive)
  # screener_name : The name of the person deciding whether to send each report
  #                 to the model (reactive)
  # file_path     : Where to save monissues. default is current directory
  #                 (character)
  #
  # OUTPUT
  # monrej_msgs, a vector of messages describing which (if any) monitoring
  # reports were removed from consideration for various parts of the model
  #
  # ASSUMPTIONS
  # * mon_choices is a list that has an element named 'selections'
  # * monissues has the following columns:
  #     monitorid
  #     coordreject_model
  #     coordreject_guid
  #     coordreject_amu
  #     coordreject_note
  #     reviewed_by
  #     reviewed_date
  ##

  ## Read monissues from file rather than using the version in memory
  #  This approach solves a couple of problems:
  #    1. File saves are done at the MU (outer module) level. None of the
  #       modules can see the changes that other modules have made to monissues,
  #       so in the absence of this step, each file save effectively undoes the
  #       last.
  #    2. Why not make monissues a global variable? Under that approach, we'd be
  #       maintaining two versions of monissues: one in memory, and one in
  #       monitor_issues.csv. These versions could differ if (a) processing
  #       stops before changes to monissues are written to file, or
  #       (b) monitor_issues.csv is edited manually. Reading from the file every
  #       time means that we only have one "source of truth"
  monissues <- read.csv(paste(file_path, "monitor_issues.csv", sep = ""),
    stringsAsFactors = FALSE
  )

  ## Keep track of screener's choices, for display on the "undo" panel
  monrej_msgs <- NULL

  ## Since bracket subsetting doesn't play well with lapply and subset() doesn't
  #  play well with functions, use a loop to iterate over each checkbox group
  for (i in 1:length(mon_choices)) {
    if (!is.null(mon_choices[[i]]$selections())) {
      monrej_msgs <- paste(
        monrej_msgs, "Monitoring Report", monreps_ids[i],
        "excluded from:"
      )
      if ("1" %in% mon_choices[[i]]$selections()) {
        monrej_msgs <- paste(monrej_msgs, "Transition Matrix Update,")
        monissues[monissues$monitorid == monreps_ids[i], "coordreject_model"] <- TRUE
      }
      if ("3" %in% mon_choices[[i]]$selections()) {
        monrej_msgs <- paste(monrej_msgs, "Management Guidance,")
        monissues[monissues$monitorid == monreps_ids[i], "coordreject_guid"] <- TRUE
      }
      if ("4" %in% mon_choices[[i]]$selections()) {
        monrej_msgs <- paste(monrej_msgs, "Annual MU Report,")
        monissues[monissues$monitorid == monreps_ids[i], "coordreject_amu"] <- TRUE
      }
      # replace final comma with a line break
      monrej_msgs <- paste(substr(monrej_msgs, start = 1, stop = nchar(monrej_msgs) - 1),
        "<br>",
        sep = ""
      )
    }


    ## Also write any notes that the coordinator added
    if (mon_choices[[i]]$notes() != "") {
      monissues[monissues$monitorid == monreps_ids[i], "coordreject_note"] <-
        mon_choices[[i]]$notes()
    }

    ## write the screener's name and the date that the selections were made
    monissues[monissues$monitorid == monreps_ids[i], "reviewed_by"] <-
      screener_name()
    monissues[monissues$monitorid == monreps_ids[i], "reviewed_date"] <-
      as.character(Sys.Date())
  } # end of for loop


  ## Save monissues to file
  write.csv(monissues, paste(file_path, "monitor_issues.csv", sep = ""),
    row.names = FALSE
  )

  ## Return messages
  return(monrej_msgs)
} # end saveSelectionsMon

saveSelectionsMan <- function(manreps_ids, man_choices, screener_name,
                              file_path = "./") {
  # Write screener's selections into manissues and save
  #
  # INPUT
  # manreps_ids   : IDs of all management reports subject to a screening
  #                 decision (numeric)
  # man_choices   : The screener's choices, input via checkbox (reactive)
  # screener_name : The name of the person deciding whether to send each report
  #                 to the model (reactive)
  # file_path     : Where to save manissues. default is current directory
  #                (character)
  #
  # OUTPUT
  # manrej_msgs, a vector of messages describing which (if any) management
  # reports were removed from consideration for various parts of the model
  #
  # ASSUMPTIONS
  # * man_choices is a list that has an element named 'selections'
  # * manissues has the following columns:
  #     treatmentid
  #     coordreject_model
  #     coordreject_cost
  #     coordreject_amu
  #     coordreject_note
  #     reviewed_by
  #     reviewed_date
  ##

  ## Read manissues from file rather than using the version in memory
  #  This approach solves a couple of problems:
  #    1. File saves are done at the MU (outer module) level. None of the
  #       modules can see the changes that other modules have made to manissues,
  #       so in the absence of this step, each file save effectively undoes the
  #       last.
  #    2. Why not make manissues a global variable? Under that approach, we'd be
  #       maintaining two versions of manissues: one in memory, and one in
  #       manage_issues.csv. These versions could differ if (a) processing stops
  #       before changes to manissues are written to file, or
  #       (b) manage_issues.csv is edited manually. Reading from the file every
  #       time means that we only have one "source of truth"
  manissues <- read.csv(paste(file_path, "manage_issues.csv", sep = ""),
    stringsAsFactors = FALSE
  )

  ## Keep track of screener's choices, for display on the "undo" panel
  manrej_msgs <- NULL

  ## Since bracket subsetting doesn't play well with lapply and subset() doesn't
  #  play well with functions, use a loop to iterate over each checkbox group
  for (i in 1:length(man_choices)) {
    if (!is.null(man_choices[[i]]$selections())) {
      manrej_msgs <- paste(
        manrej_msgs, "Management Report", manreps_ids[i],
        "excluded from: "
      )
      if ("1" %in% man_choices[[i]]$selections()) {
        manrej_msgs <- paste(manrej_msgs, "Transition Matrix Update,")
        manissues[
          manissues$treatmentid == manreps_ids[i],
          "coordreject_model"
        ] <- TRUE
      }
      if ("2" %in% man_choices[[i]]$selections()) {
        manrej_msgs <- paste(manrej_msgs, "Cost Calculations,")
        # manissues[manissues$munitid==outer_munitid & manissues$treatmentid==manreps_ids[i],
        manissues[
          manissues$treatmentid == manreps_ids[i],
          "coordreject_cost"
        ] <- TRUE
      }
      if ("4" %in% man_choices[[i]]$selections()) {
        manrej_msgs <- paste(manrej_msgs, "Annual MU Report,")
        manissues[
          manissues$treatmentid == manreps_ids[i],
          "coordreject_amu"
        ] <- TRUE
      }
      # replace final comma with a line break
      manrej_msgs <- paste(substr(manrej_msgs, start = 1, stop = nchar(manrej_msgs) - 1),
        "<br>",
        sep = ""
      )
    }

    ## Also write any notes from the screener
    if (man_choices[[i]]$notes() != "") {
      manissues[manissues$treatmentid == manreps_ids[i], "coordreject_note"] <-
        man_choices[[i]]$notes()
    }

    ## write the screener's name and the date that the selections were made
    manissues[manissues$treatmentid == manreps_ids[i], "reviewed_by"] <-
      screener_name()
    manissues[manissues$treatmentid == manreps_ids[i], "reviewed_date"] <-
      as.character(Sys.Date())
  } # end loop over management report checkbox groups

  ## Save manissues to file
  write.csv(manissues, paste(file_path, "manage_issues.csv", sep = ""),
    row.names = FALSE
  )

  ## Return messages
  return(manrej_msgs)
} # end saveSelectionsMan

prettyMonitor <- function(monitor) {
  # Replace database codes with human-readable values
  #
  # INPUT
  # mon_data : monitoring reports (data frame)
  #
  # OUTPUT
  # The same monitoring reports, with human-readable values replacing
  # database codes in the establishment column
  #
  # ASSUMPTIONS
  # * monitor has the columns:
  #     establishment
  # * definitions of establishment categories have not changed from those
  #   recorded below
  ##

  monitor[which(monitor$establishment == 0), "establishment"] <- "0-10%"
  monitor[which(monitor$establishment == 1), "establishment"] <- "11-50%"
  monitor[which(monitor$establishment == 2), "establishment"] <- "51-100%"

  return(monitor)
} # end prettyMonitor

prettyManage <- function(manage) {
  # Replace database codes with human-readable values
  #
  # INPUT
  # manage : management reports (data frame)
  #
  # OUTPUT
  # The same management reports, with human-readable values replacing
  # database codes of the phase and treatmethod columns
  #
  # ASSUMPTIONS
  # * Manage has the columns:
  #     phase
  #     treatmethod
  # * The global constants are defined:
  #   TRANSLOCATING, DORMANT, GROWING: definitions of the biological phases
  #   (data frame)
  ##

  manage[which(manage$phase == TRANSLOCATING$code), "phase"] <- "Translocating"
  manage[which(manage$phase == DORMANT$code), "phase"] <- "Dormant"
  manage[which(manage$phase == GROWING$code), "phase"] <- "Growing"

  manage[which(manage$treatmethod == GLYPH$db), "treatmethod"] <- "Glyphosate"
  manage[which(manage$treatmethod == IMAZ$db), "treatmethod"] <- "Imazapyr"
  manage[which(manage$treatmethod == GLYPHPLUS$db), "treatmethod"] <- "Glyphosate+"
  manage[which(manage$treatmethod == REST$db), "treatmethod"] <- "Rest"
  manage[which(manage$treatmethod == CUT$db), "treatmethod"] <- "Cut Underwater"
  manage[which(manage$treatmethod == SPADING$db), "treatmethod"] <- "Spading"
  manage[which(manage$treatmethod == PRECLEAR$db), "treatmethod"] <- "Pre-Flood Clearing"
  manage[which(manage$treatmethod == MECHREMOVE$db), "treatmethod"] <- "Remove Biomass"
  manage[which(manage$treatmethod == FLOOD$db), "treatmethod"] <- "Flood"
  manage[which(manage$treatmethod == MECHLEAVE$db), "treatmethod"] <- "Mechanical & Leave Biomass"
  manage[which(manage$treatmethod == OTHER$db), "treatmethod"] <- "Other"

  manage[which(manage$munitcondition == 0), "munitcondition"] <- "Wet"
  manage[which(manage$munitcondition == 1), "munitcondition"] <- "Moist"
  manage[which(manage$munitcondition == 2), "munitcondition"] <- "Dry"

  return(manage)
} # end prettyManage
