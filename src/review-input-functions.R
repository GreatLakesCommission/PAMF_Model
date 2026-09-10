# 2020-11-10
#
# Functions and constants to verify that the user inputs in the create-run
# and forecast-guidance interfaces contain the necessary information in order
# to proceed with the model run / guidance forecast. The server code for those
# interfaces can be found in the following scripts:
#   * ./src/create-new-run/review-user-inputs.R (create run)
#   * ./src/forecast-guidance/review-midcycle-inputs.R (forecast guidance)
#
# Functions
#   * checkCSV          : Verify that the user-provided file is (a) in .csv
#                         format and (b) has the necessary columns
#   * checkEnrollCols   : Verify that enrollment reports have all columns
#                         needed by the model
#   * checkMonitorCols  : Verify that monitoring reports have all columns needed
#                         by the model
#   * checkManageCols   : Verify that management reports have all columns needed
#                         by the model
#   * checkMndateCols   : Verify that applicationdate reports have all columns
#                         needed by the model
#   * checkMidcycleCols : Verify that midcycle reports have all necessary columns
#   * checkPrevRun      : Verify that the specified cumulative output files of
#                         the previous run  (a) exist, and (b) are .csv files
#                         with the necessary columns.
#   * checkOutputCols   : Verify that a file has all columns needed by the model
#   * extractDate       : Extract a date from a string using a regular
#                         expression requiring YYYY-MM-DD format
#   * filterFileExtension : Return file name only if it contains the desired
#                           extension
#   * checkDBPull : Determines whether all specified files originate from the
#                   same database pull
##

# ----------------------------------------------------------------------------
#  Functions
##

checkCSV <- function(which_file, file_name, file_path, cycleend) {
  # Verify that the user-provided file is (a) in .csv format and
  # (b) has the necessary columns
  #
  # INPUT
  # which_file : Which file needs checking; for allowed values, see ASSUMPTIONS
  #              below (character)
  # file_name  : User input from the interactive session (e.g. input$enroll)
  # file_path  : Path to input file (e.g. input$enroll$datapath)
  # cycleend   : The second/final year of the current PAMF cycle (numeric)
  #              This input is present for backwards compatibility to older data
  #              sets-- enroll and manage have columns that were added in the
  #              years after the initial model run
  #
  # OUTPUT
  # Named list whose elements are error and message
  # If the file does not exist, is not in .csv format, or has the wrong columns,
  # error is TRUE and message contains an non-empty character string. Otherwise,
  # error is FALSE and message is NULL
  #
  # ASSUMPTIONS
  # * The appropriate column-checking function is also sourced. one of:
  #     checkEnrollCols
  #     checkMonitorCols
  #     checkManageCols
  #     checkMndateCols
  #     checkMidcycleCols
  # * which_file contains one and only one of the following strings:
  #     enroll
  #     monitor
  #     manage
  #     mndates
  #     midcycle
  # * filterFileExtension() is sourced
  ##

  if (is.null(file_name)) {
    nullfile_msg <- switch(which_file,
      "enroll"   = "ERROR: Missing enrollment data",
      "monitor"  = "ERROR: Missing monitoring data",
      "manage"   = "ERROR: Missing management data",
      "mndates"  = "ERROR: Missing management dates",
      "midcycle" = "ERROR: Missing mid-cycle reports"
    )
    return(list(error = TRUE, message = nullfile_msg))
  } else {
    # File name isn't NULL, but does it have a .csv extension?
    # The function call below returns NULL if file_name does not end in .csv
    # (case insensitive)
    filtered <- filterFileExtension(file_name, ".csv")

    if (is.null(filtered)) {
      notcsv_msg <- switch(which_file,
        "enroll"   = "ERROR: Enrollment data not in .csv format",
        "monitor"  = "ERROR: Monitoring data not in .csv format",
        "manage"   = "ERROR: Management data not in .csv format",
        "mndates"  = "ERROR: Management dates not in .csv format",
        "midcycle" = "ERROR: Mid-Cycle reports not in .csv format"
      )
      return(list(error = TRUE, message = notcsv_msg))
    } else {
      # Open the file and verify that necessary columns are present:
      file_cols <- scan(file_path, what = "character", sep = ",",
                        nlines = 1, quiet = TRUE)

      col_msg <- switch(which_file,
        "enroll"   = checkEnrollCols(file_cols, cycleend),
        "monitor"  = checkMonitorCols(file_cols),
        "manage"   = checkManageCols(file_cols, cycleend),
        "mndates"  = checkMndateCols(file_cols),
        "midcycle" = checkMidcycleCols(file_cols)
      )

      if (!is.null(col_msg)) {
        # One or more necessary columns is missing
        return(list(error = TRUE, message = col_msg))
      } else {
        # All necessary columns are present
        return(list(error = FALSE, message = NULL))
      }
    }
  }
} # end checkCSV

checkEnrollCols <- function(enroll_cols, cycleend) {
  # Verify that enrollment reports have all columns needed by the model
  #
  # INPUT
  # enroll_cols : column names of enrollment reports (character)
  # cycleend    : the second/final year of the current PAMF cycle (numeric)
  #               This input is present for backwards compatibility to older
  #               data sets-- the 'active' column was added to the database in
  #               2019
  #
  # OUTPUT
  # If any columns are missing, returns a message for the user and displays
  # column names in the R console. Otherwise, returns NULL
  ##

  if (cycleend == 2018) {
    needed_cols <- c(
      "munitid", "name", "herbicide", "cut", "controlwater",
      "dateentered", "area", "userid"
    )
  } else {
    needed_cols <- c(
      "munitid", "name", "herbicide", "cut", "controlwater",
      "dateentered", "area", "active", "userid"
    )
  }

  missing_cols <- setdiff(needed_cols, enroll_cols)
  if (length(missing_cols) == 0) {
    # All necessary columns are present
    return(NULL)
  } else {
    # One or more necessary columns is missing
    message(paste("\nEnrollment data missing one or more columns: ",
      toString(missing_cols),
      sep = "\n"
    ))
    return("ERROR: One or more expected columns missing from enrollment data\n See R console for details")
  }
} # end checkEnrollCols

checkMonitorCols <- function(monitor_cols) {
  # Verify that monitoring reports have all columns needed by the model
  #
  # INPUT
  # monitor_cols : column names of monitoring reports (character)
  #
  # OUTPUT
  # If any columns are missing, returns a message for the user and displays
  # column names in the R console. Otherwise, returns NULL
  ##

  needed_cols <- c(
    "id", "munitid", "establishment", "q1stemcount", "q2stemcount",
    "q3stemcount", "q4stemcount", "q5stemcount", "dateentered",
    "monitoringdate", "notes", "userid"
  )

  missing_cols <- setdiff(needed_cols, monitor_cols)

  if (length(missing_cols) == 0) {
    # All necessary columns are present
    return(NULL)
  } else {
    # One or more necessary columns is missing
    message(paste("\nMonitoring data missing one or more columns: ",
      toString(missing_cols),
      sep = "\n"
    ))
    return("ERROR: One or more expected columns missing from monitoring data\n See R console for details")
  }
} # end checkMonitorCols

checkManageCols <- function(manage_cols, cycleend) {
  # Verify that management reports have all columns needed by the model
  #
  # INPUT
  # manage_cols : column names of management reports (character)
  # cycleend    : the second/final year of the current PAMF cycle (numeric)
  #               This input is present for backwards compatibility to older
  #               data sets-- e.g. the 'dateentered' and 'percentcover' columns
  #               were not added until 2020
  #
  # OUTPUT
  # If any columns are missing, returns a message for the user and displays
  # column names in the R console. Otherwise, returns NULL
  ##

  # Since manage has ~170 columns, break them apart into functional categories:
  action_cols <- c(
    "id", "munitid", "managementdate", "phase", "treatmethod",
    "preremove", "pretechnique"
  )

  notes_cols <- c(
    "other", "glyphproduct", "glyphconcentrationpercent",
    "glyphsurfactantused", "glyphsurfactantpercent", "glyphnotes",
    "glyphplusproduct", "glyphplusconcentrationpercent",
    "glyphplussurfactantused", "imazproduct",
    "imazconcentrationpercent", "imazsurfactantused",
    "imazsurfactantpercent", "imaznotes", "cutdescribe", "floodtype",
    "floodmonths", "prenotes", "mechnotes", "removenotes",
    "munitcondition", "cutnotes", "spadenotes", "floodnotes",
    "othernotes", "restnotes", "glyphproductother",
    "glyphplusproductother", "imazproductother", "followdescribe"
  )

  cost_cols <- c(
    "costdetails", "treatarea", "totalareatreated", "hirecontractor",
    "contractorcost", "rentequipment", "rentcost", "totalhoursworked",
    "studenthours", "volunteerhours", "seasonalhours", "fullhours",
    "otherhours", "equipmenthours", "glyphvolume", "glyphgasmin",
    "glyphgasmax", "glyphdieselmin", "glyphdieselmax", "glyphjetmin",
    "glyphjetmax", "glyphavgasmin", "glyphavgasmax",
    "glyphplusvolume", "glyphplusgasmin", "glyphplusgasmax",
    "glyphplusdieselmin", "glyphplusdieselmax", "glyphplusjetmin",
    "glyphplusjetmax", "glyphplusavgasmin", "glyphplusavgasmax",
    "imazvolume", "imazgasmin", "imazgasmax", "imazdieselmin",
    "imazdieselmax", "imazjetmin", "imazjetmax", "imazavgasmin",
    "imazavgasmax", "floodcontrol", "floodgasmin", "floodgasmax",
    "flooddieselmin", "flooddieselmax", "floodwattagemin",
    "floodwattagemax", "glyphequipmodel", "glyphplusequipmodel",
    "imazequipmodel", "cutequipmodel", "cutgasmin", "cutgasmax",
    "cutdieselmin", "cutdieselmax", "preequipmodel", "pregasmin",
    "pregasmax", "predieselmin", "predieselmax", "predescribe",
    "removegasmax", "removedieselmin", "removedieselmax",
    "mechequipmodel", "mechgasmin", "mechgasmax", "mechdieselmin",
    "mechdieselmax", "floodpumphours"
  )

  cover_cols <- c(
    "floodcover", "glyphpercentcover", "glyphpluspercentcover",
    "imazpercentcover", "prepercentcover", "removepercentcover"
  )
  cols2020 <- c("dateentered", "percentcover")


  # find missing columns
  missing_action_cols <- setdiff(action_cols, manage_cols)
  missing_notes_cols <- setdiff(notes_cols, manage_cols)
  missing_cost_cols <- setdiff(cost_cols, manage_cols)

  if (cycleend < 2020) {
    missing_cover_cols <- setdiff(cover_cols, manage_cols)
  } else {
    missing_cover_cols <- setdiff("percentcover", manage_cols)
    missing_action_cols <- c(
      missing_action_cols,
      setdiff("dateentered", manage_cols)
    )
  }

  # Generate a message to the user
  the_message <- NULL
  if (length(missing_action_cols) > 0 | length(missing_notes_cols) > 0 |
    length(missing_cost_cols) > 0 | length(missing_cover_cols) > 0) {
    the_message <- "ERROR: One or more expected columns missing from management data \n See R console for details"

    if (length(missing_action_cols) > 0) {
      message(paste("\nManagement data missing one or more columns describing management actions: ",
        toString(missing_action_cols),
        sep = "\n"
      ))
    }
    if (length(missing_cover_cols) > 0) {
      message(paste("\nManagement data missing one or more columns describing management action coverage: ",
        toString(missing_cover_cols),
        sep = "\n"
      ))
    }
    if (length(missing_notes_cols) > 0) {
      message(paste("\nManagement data missing one or more columns of participant text input: ",
        toString(missing_notes_cols),
        sep = "\n"
      ))
    }
    if (length(missing_cost_cols) > 0) {
      message(paste("\nManagement data missing one or more columns of cost input: ",
        toString(missing_cost_cols),
        sep = "\n"
      ))
    }
  }
  return(the_message)
} # end checkManageCols

checkMndateCols <- function(mndate_cols) {
  # Verify that applicationdate reports have all columns needed by the model
  #
  # INPUT
  # mndate_cols : column names of application dates table (character)
  #
  # OUTPUT
  # If any columns are missing, returns a message for the user and displays
  # column names in the R console. Otherwise, returns NULL
  ##

  needed_cols <- c("id", "treatmentid", "applicationdate")
  missing_cols <- setdiff(needed_cols, mndate_cols)

  if (length(missing_cols) == 0) {
    # All necessary columns are present
    return(NULL)
  } else {
    # One or more necessary columns is missing

    message(paste("\nApplication date data missing one or more columns: ",
      toString(missing_cols),
      sep = "\n"
    ))
    return("ERROR: One or more expected columns missing from management dates\n See R console for details")
  }
} # end checkMndateCols

checkMidcycleCols <- function(midcy_cols) {
  # Verify that midcycle reports have all necessary columns
  #
  # INPUT
  # midcy_cols : column names of midcycle reports (character)
  #
  # OUTPUT
  # If any columns are missing, returns a message for the user and displays
  # column names in the R console. Otherwise, returns NULL
  ##

  needed_cols <- c(
    "id", "munitid", "mcombination", "transtaken", "dormtaken",
    "growtaken", "userid", "dateentered"
  )
  missing_cols <- setdiff(needed_cols, midcy_cols)

  if (length(missing_cols) == 0) {
    # All necessary columns are present
    return(NULL)
  } else {
    # One or more necessary columns is missing

    message(paste("\nMidcycle Reports missing one or more columns: ",
      toString(missing_cols),
      sep = "\n"
    ))
    return("ERROR: One or more expected columns missing from midcycle reports\n See R console for details")
  }
} # end checkMidcycleCols

checkPrevRun <- function(prev_path, expected_files) {
  # Verify that the specified cumulative files (i.e. outputs) of the previous run
  # (a) exist, and (b) are .csv files with the necessary columns.
  #
  # INPUT
  # prev_path      : File path to the previous model run (character)
  # expected_files : Names of output files to check (character vector)
  #
  # OUTPUT
  # Named list whose elements are error and message
  # If the run does not exist, is not in .csv format, or has the wrong columns,
  # error is TRUE and message contains an non-empty character string. Otherwise,
  # error is FALSE and message is NULL
  #
  # ASSUMPTIONS
  # * checkOutputCols() is sourced
  # * filterFileExtension() is sourced
  ##

  prev_files <- list.files(prev_path)
  missing_files <- setdiff(expected_files, prev_files)

  if (length(missing_files) == 0) {
    # All output files exist, but do they have the correct columns?
    # First, ignore any non-CSV files
    expected_csv <- unlist(lapply(expected_files, filterFileExtension, ".csv"))

    col_messages <- lapply(expected_csv, checkOutputCols, prev_path)
    col_messages <- do.call(c, col_messages) # convert to vector & drop any NULLs

    if (length(col_messages) > 0) {
      # At least one file is missing a necessary column
      return(list(error = TRUE, message = paste(col_messages, collapse = "\n")))
    } else {
      # All csv files have the correct columns
      return(list(error = FALSE, message = NULL))
    }
  } else {
    # One or more files is missing. Return message for UI & show details on
    # console
    message(paste("\nFile(s) missing from the previous model run: ",
      toString(missing_files),
      sep = "\n"
    ))
    return(list(error = TRUE, message = "ERROR: One or more files missing from previous model run. \n See R console for details"))
  }
} # end checkPrevRun

checkOutputCols <- function(file_name, prev_path) {
  # Verify that the file given by file_name has all columns needed by the model
  #
  # INPUT
  # file_name : the name of the file to be checked (character)
  # prev_path  : path to directory containing previous run's outputs (character)
  #
  # OUTPUT
  # If any columns are missing, returns a message for the user and displays
  # column names in the R console. Otherwise, returns NULL
  #
  # ASSUMPTIONS
  # * file_name points to a file in prev_path, as is the case when this function
  #   is called from
  #   review-user-inputs.R
  ##

  # Get the column names
  cols <- scan(paste0(prev_path, file_name),
    what = "character", sep = ",", nlines = 1,
    quiet = TRUE
  )


  # Define the necessary column names
  if (file_name == "monitor_issues.csv") {
    needed_cols <- c(
      "monitorid", "munitid", "cycle_end", "run_date", "monitor_year",
      "wrongyear_mon", "year_mismatch", "month_mismatch", "has_notes",
      "near_window", "out_of_window", "stems_missing", "stems_zero",
      "stems_high", "display", "coordreject_model", "coordreject_guid",
      "coordreject_amu", "coordreject_note", "reviewed_by",
      "reviewed_date", "autoreject_model", "autoreject_guid"
    )
  } else {
    if (file_name == "manage_issues.csv") {
      needed_cols <- c(
        "treatmentid", "munitid", "cycle_end", "run_date",
        "manage_year", "wrongyear_man", "has_notes", "out_of_phase",
        "short_flood", "long_flood", "hydro_mismatch", "low_coverage",
        "no_cost_data", "duplicated_cost", "old_cost_qaqc",
        "labor_other", "missing_constant", "display",
        "coordreject_model", "coordreject_cost", "coordreject_amu",
        "coordreject_note", "reviewed_by", "reviewed_date",
        "autoreject_model", "autoreject_cost"
      )
    } else {
      if (file_name == "report-repairs.csv") {
        needed_cols <- c(
          "munitid", "treatmentid", "applicationid", "datpakid",
          "model_cycle", "phase_reassign", "model_phase",
          "created_rest", "action_reassign", "model_action"
        )
      } else {
        if (file_name == "datpak.csv") {
          needed_cols <- c(
            "datpakid", "munitid", "cycle_begin", "cycle_end",
            "state_begin", "state_end", "pr_est0_begin",
            "pr_est1_begin", "pr_est2_begin", "pr_lo_begin",
            "pr_hi_begin", "pr_est0_end", "pr_est1_end", "pr_est2_end",
            "pr_lo_end", "pr_hi_end", "t_actions", "d_actions",
            "g_actions", "mnt_comb"
          )
        } else {
          if (file_name == "datpak_issues.csv") {
            needed_cols <- c(
              "datpakid", "munitid", "cycle_begin", "cycle_end",
              "mon_begin_missing", "mon_begin_rej_model",
              "mon_begin_rej_guid", "mon_end_missing",
              "mon_end_rej_model", "mon_end_rej_guid",
              "t_act_missing", "t_act_extra", "d_act_missing",
              "d_act_extra", "g_act_missing", "g_act_extra",
              "has_rej_man", "wrong_comb", "no_guidance",
              "never_intended", "autoreject_model", "autoreject_partcontrol"
            )
          } else {
            if (file_name == "transition_matrices.csv") {
              needed_cols <- c(
                "mnt_comb", "state_begin", "state_end", "trans_prob",
                "concentration", "cycle_used"
              )
            } else {
              if (file_name == "partcontrol_matrices.csv") {
                needed_cols <- c(
                  "mnt_intended", "mnt_implemented", "probability",
                  "concentration", "cycle_used"
                )
              } else {
                if (file_name == "cost_estimates.csv") {
                  needed_cols <- c(
                    "treatmentid", "munitid", "treatmethod", "contract",
                    "rent", "total_cost", "cost_per_acre", "pamf_cycle"
                  )
                } else {
                  if (file_name == "policies.csv") {
                    needed_cols <- c(
                      "cycle_end", "restr_id", "state", "db_tloc",
                      "db_dorm", "db_grow", "mnt_comb", "optimal"
                    )
                  } else {
                    if (file_name == "guidance.csv") {
                      needed_cols <- c(
                        "munitid", "state", "transrec", "dormrec",
                        "growrec", "optimal", "recommend_cycle"
                      )
                    } else {
                      warning(paste("checkOutputCols: unknown file name", file_name))
                      needed_cols <- NULL
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # Set messages according to whether any necessary columns are missing from the
  # file
  missing_cols <- setdiff(needed_cols, cols)
  if (length(missing_cols) == 0) {
    # All necessary columns are present
    return(NULL)
  } else {
    # One or more necessary columns is missing
    message(paste0(
      "\n", prev_path, file_name, " missing the following columns:\n",
      toString(missing_cols)
    ))
    return(paste0(
      "ERROR: One or more expected columns missing from ", file_name,
      "\n See R console for details"
    ))
  }
} # end checkOutputCols

extractDate <- function(s) {
  # Extract a date from a string using a regular expression requiring:
  #    YYYY-MM-DD format
  #    year, month, day are separated by hyphens
  #    year begins with 2 and contains three other digits
  #    month begins with 0 or 1 and contains one other digit
  #    day begins with 0,1,2, or 3 and contains one other digit
  ##

  return(regmatches(
    s,
    regexpr(
      "2[[:digit:]]{3}-[01][[:digit:]]-[0123][[:digit:]]",
      s
    )
  ))
} # end extractDate

filterFileExtension <- function(file_name, extension) {
  # If file_name ends in the given extension (case-insensitive matching),
  # return file_name otherwise, return NULL
  #
  # INPUT
  # file_name : character string representing a file name
  # extension : the file extension to match (character)
  #
  # OUTPUT
  # as described above
  #
  # ASSUMPTIONS
  #  * File extensions are made up of alphabetical characters only
  ##

  ## Match a dot and all following alphabetical characters until the end of
  #  the string
  file_ext <- regmatches(
    file_name,
    regexpr("\\.[[:alpha:]]*$", file_name)
  )

  if (nchar(file_ext) == 0) {
    # file_name has no alphabetical file extension
    return(NULL)
  } else {
    # Are the file extensions the same? Ignore case
    if (tolower(file_ext) == tolower(extension)) {
      return(file_name)
    } else {
      return(NULL)
    }
  }
} # end filterFileExtension

checkDBPull <- function(file_names) {
  # Determines whether all specified files originate from the same database pull
  #
  # INPUT
  # file_names : Named list of files from database pull (list)
  #
  # OUTPUT
  # Named list whose elements are warning and message
  # If any element in file_names does not contain a date or if two or more
  # elements contain different dates, warning is TRUE and message contains an
  # non-empty character string. Otherwise, warning is FALSE and message is NULL
  #
  # ASSUMPTIONS
  # * Each element of file_names contains the date that the database pull
  #   was done (in YYYY-MM-DD format) and no other dates
  # * extractDate() is sourced
  ##

  ## Create variables to keep track of the warnings and messages that this
  #  function may generate
  wrn <- FALSE
  msg <- NULL

  ## Get all unique pull dates
  pull_dates <- unique(lapply(file_names, extractDate))

  ## Check for zero-lengh pull dates. These indicate that the file name does not
  #  contain a date & is therefore nonstandard
  date_length <- lapply(pull_dates, length)
  if (any(date_length == 0)) {
    wrn <- TRUE
    msg <- paste(msg, "WARNING: One or more files not labeled with pull date",
      sep = "\n"
    )
  }

  ## Check for multiple distinct pull dates (including empty ones)
  if (length(pull_dates) > 1) {
    msg <- paste(msg, "WARNING: Files may come from more than one database pull",
      sep = "\n"
    )
    return(list(warning = TRUE, message = msg))
  } else {
    return(list(warning = wrn, message = msg))
  }
} # end checkDBPull
