## 2020-12-04
#
#  Checks user input for issues (outlined below), and determines whether it's
#  possible to proceed to the midcycle forecast calculations
#
#  Sourced by: app.R
#
#  DEPENDENCIES
#  * Variables
#     input  : input from user interface
#     output : output to be displayed on user interface (Midcycle inputs screen)
#     oldmsg : the value of "messages" from the previous call to this function.
#             Needed for user override in case of errors==FALSE and
#             warnings==TRUE s.t. any warnings produced between button pushes
#             are shown before the user can move to the next page
#
#  * Functions
#    From review-input-functions.R
#     checkCSV
#     checkPrevRun
#     checkDBPull
#    extractDate
##

# ==============================================================================
#  Source functions
# ==============================================================================
# source("./src/review-input-functions.R") This is sourced in app.R

# ==============================================================================
# Define variables to keep track of whether there are issues &
# what the issues are
# ==============================================================================
proceed <- FALSE # don't proceed to next screen
errors <- FALSE # has the input produced errors?
warnings <- FALSE # has the input produced warnings?
messages <- NULL # tell the user about issues with inputs


# ==============================================================================
#  Conduct checks to make sure that inputs are valid:
# ==============================================================================
#  ISSUES THAT PRODUCE ERRORS
#  ~~~ Forecast guidance cannot be calculated if these issues are present ~~~
#  1.  cycleend < 2018 OR (cycleend > current_year OR cycleend > current_year + 1,
#      depending on when in the cycle this code is run); cycleend not a number
#  2.  No prior model run selected
#  3.  Enrollment file missing or wrong type
#  4.  Management file missing or wrong type
#  5.  Management dates file missing or wrong type
#  6.  Midcycle file missing or wrong type
#  8.  Necessary column(s) missing from enrollment data
#  9.  Necessary column(s) missing from management data
#  10. Necessary column(s) missing from management date data
#  11. Necessary column(s) missing from midcycle reports
#  12. Directory of prior model run is missing one or more necessary output files
#  13. One or more cumulative output files is missing necessary column(s)
#
#
#  ISSUES THAT PRODUCE WARNINGS
#  ~~~ Forecast guidance can be calculated but outputs may be wrong ~~~
#  14. Database files are not all from the same database pull
#  15. midcycle reports are pulled more than a year after the pull date of
#      monitoring reports used in the previous model run
#  16. midcycle reports are pulled before the pull date of the monitoring
#      reports used in the "previous" model run
#  17. The midcycle pull date does not belong to the cycle defined by cycleend
##

## 1.  cycleend < 2018 OR (cycleend > current_year OR cycleend > current_year + 1)
#
#      Don't try to do anything before 2018 or in the future.
#      What constitutes the future depends upon which cycle is current,
#      i.e. upon the time of year that this code is being run.
#      e.g. In January-July, the cycle ends in the current year
#           In September-December, the cycle ends next year
#      (August is an ambiguous case because the database pull- which divides one
#      cycle from the next- happens partway through the month. It's also not a
#      good time to generate a mid-cycle guidance forecast!)
#
#      NOTE: I've set max and min values for the numericInput() widget that
#            collects cycleend, those settings affect the widget's arrow buttons
#            but they don't limit keyboard input in the same way
#            Since it's still possible to type out-of-range years AND TEXT (!!),
#            we still have to check for those
##
current_year <- as.numeric(format(Sys.time(), "%Y"))
current_month <- as.numeric(format(Sys.time(), "%m"))

# make a static copy of input$cycleend for use throughout this script
cycleend <- input$cycleend_fg
cycleend <- suppressWarnings(as.numeric(cycleend))
if (is.na(cycleend)) {
  # User has entered a non-numeric value for cycleend
  errors <- TRUE
  messages <- paste(messages, "ERROR: Invalid guidance release year")
} else {
  # cycleend is numeric. But is it a year after the beginning of PAMF and from
  # a cycle that has already begun?
  if (cycleend < 2018) {
    errors <- TRUE
    messages <- paste(messages, "ERROR: Cannot forecast guidance before start of PAMF",
      sep = "\n"
    )
  } else {
    if (current_month %in% 1:7) {
      # the current cycle ends this year
      if (cycleend > current_year) {
        errors <- TRUE
        messages <- paste(messages, "ERROR: Cannot forecast guidance for cycles not yet in progress",
          sep = "\n"
        )
      }
    } else {
      # the current cycle ends next year
      if (cycleend > (current_year + 1)) {
        errors <- TRUE
        messages <- paste(messages, "ERROR: Cannot forecast guidance for cycles not yet in progress",
          sep = "\n"
        )
      }
    }
  }
}


## 2.  No prior model run selected
#      Need to know which prior model run to update
##
if (input$prevrun_fg == "Select...") {
  errors <- TRUE
  messages <- paste(messages, "ERROR: No previous run selected", sep = "\n")
}


##  3, 8.  Enrollment file missing or wrong type
#          If neither is true, open file and verify that it's enrollment
##
isok <- checkCSV(
  "enroll", input$enroll_fg$name, input$enroll_fg$datapath,
  cycleend
)
if (isok$error == TRUE) {
  errors <- TRUE
}
if (!is.null(isok$message)) {
  messages <- paste(messages, isok$message, sep = "\n")
}


##  4, 9.  Management file missing or wrong type
#          If neither is true, open file and verify that it's management
##
isok <- checkCSV(
  "manage", input$manage_fg$name, input$manage_fg$datapath,
  cycleend
)
if (isok$error == TRUE) {
  errors <- TRUE
}
if (!is.null(isok$message)) {
  messages <- paste(messages, isok$message, sep = "\n")
}


##  5, 10.  Management dates file missing or wrong type
#           If neither is true, open file and verify that it's management dates
##
isok <- checkCSV(
  "mndates", input$mndates_fg$name, input$mndates_fg$datapath,
  cycleend
)
if (isok$error == TRUE) {
  errors <- TRUE
}
if (!is.null(isok$message)) {
  messages <- paste(messages, isok$message, sep = "\n")
}


##  6, 11.  Midcycle report file missing or wrong type
#           If neither is true, open file and verify that it's midcycle reports
##
isok <- checkCSV(
  "midcycle", input$midcycle_fg$name, input$midcycle_fg$datapath,
  cycleend
)
if (isok$error == TRUE) {
  errors <- TRUE
}
if (!is.null(isok$message)) {
  messages <- paste(messages, isok$message, sep = "\n")
}


##  12. Directory of prior model run is missing one or more necessary output files
##  13. One or more cumulative output files is missing necessary column(s)
#
#       2018 was the first model run; only check for runs after this
##

if (input$prevrun_fg != "Select...") {
  # Get the path to the previous run & define a list of files to check on
  prev_run <- input$prevrun_fg
  prev_path <- paste("./model-runs/", prev_run, "/", sep = "")

  expected_files <- c(
    "user-input-log.txt", "monitor_issues.csv", "policies.csv",
    "datpak.csv", "transition_matrices.csv"
  )

  # Check for problems 13 & 14 in the previous run
  isok <- checkPrevRun(prev_path, expected_files)
  if (isok$error == TRUE) {
    errors <- TRUE
  }
  if (!is.null(isok$message)) {
    messages <- paste(messages, isok$message, sep = "\n")
  }
}


##  14. data files are not all from the database pull
#       If so, newer data packages from the more recent files may be missing
#       pieces just because the older files don't cover the same years
#
#   NOTE: This section of code assumes that the name of each file from the
#         database pull contains the date that the pull was done (in YYYY-MM-DD
#         format) and that it contains no other dates
##

## Get the file names. These will persist past the end of the script and will be
#  used to generate guidance forecasts
enrollname <- input$enroll_fg$name
managename <- input$manage_fg$name
mndatename <- input$mndates_fg$name
midcyclename <- input$midcycle_fg$name
file_names <- c(enrollname, managename, mndatename, midcyclename)

isok <- checkDBPull(file_names)
if (isok$warning == TRUE) {
  warnings <- TRUE
}
if (!is.null(isok$message)) {
  messages <- paste0(messages, isok$message, sep = "\n")
}


##  15, 16. Midcycle reports are pulled more than a year after the pull date of
#           monitoring reports used in the previous model run
#           i.e. state information may be out of date
#
#           Midcycle reports are pulled before the pull date of the monitoring
#           reports used in the "previous" model run
#
#           2018 was the first model run; only check for runs after this
#
#           Additionally, set a cutoff date for midcycle reports and management
#           reports to consider in MCFG (ignore reports not belonging to the
#           current cycle)
##
if (length(midcyclename) > 0 & input$prevrun_fg != "Select..." & cycleend > 2018) {
  
  ## Other parts of this script verify that necessary selections are made
  #  Assume that the previous run has been selected & midcycle reports have been
  #  chosen & user-input-log exists.
  ##

  if (is.na(suppressWarnings(as.numeric(substr(input$prevrun_fg, 1, 4))))) {
    # If the first four characters of input$prevrun_fg aren't numeric, warn the
    # user that this violates naming conventions
    warnings <- TRUE
    messages <- paste(messages, "WARNING: Previous run has nonstandard name \n Run names should begin with the year that the run was conducted",
      sep = "\n"
    )
  }

  ## Extract the following information from user-input-log.txt:
  #  1. The year ending the previous cycle
  #  2. The pull date of monitoring reports
  #
  #  These values help us determine whether the cycle that the user designated
  #  as 'previous' is consecutive with the cycle for which MCFG is requested.
  ##
  midcycle_date <- as.Date(extractDate(midcyclename))

  run_log <- scan(paste0(prev_path, "user-input-log.txt"),
    what = "character",
    quiet = TRUE
  )
  prev_cycle <- run_log[grep("cycle", run_log) + 1]
  prev_monitor <- run_log[grep("monitor.*csv", run_log)]
  prevmonitor_date <- as.Date(extractDate(prev_monitor))
  current_cycle_cutoff <- NULL

  ## Does prev-cycle exist, and:
  #  * does it consist of two hyphen-separated parts?
  #  * is it numeric?
  ##
  if (length(prev_cycle) > 0) {
    prev_cycle <- strsplit(prev_cycle, "-")
    prev_cycle <- suppressWarnings(as.numeric(prev_cycle[[1]]))

    if (length(prev_cycle) != 2) {
      # prev_cycle is not made up to two hyphen-separated numbers
      errors <- TRUE
      messages <- paste(messages, "ERROR: Cannot determine years defining previous cycle from user-input-log.txt",
        sep = "\n"
      )
    } else {
      prev_end <- prev_cycle[2]
    }
  } else {
    errors <- TRUE
    messages <- paste(messages, "ERROR: Years defining previous cycle are missing from user-input-log.txt",
      sep = "\n"
    )
  }

  ## Does monitoring date exist, and is it:
  #   * older than one year?
  #   * newer than the midcycle reports?
  #
  # The pull date for monitoring data is important here because we get our
  # monitoring information for the midcycle forecasts from the previous run's
  # cleaned outputs (datpak, monitor_issues)
  #
  # Additionally, set the cutoff dates for reports pertaining to the MCFG request.
  # This prevents us from considering old management and midcycle reports.
  #   * If the current and previous cycles are consecutive, the cutoff date is
  #     the previous run's database pull date
  #     (assumed to be the same as prevmonitor_date)
  #   * Otherwise, the cutoff date is the first day of the current cycle's
  #     translocating phase
  ##
  if (length(midcycle_date) > 0 & length(prevmonitor_date) > 0) {
    # Both file names contain dates. Check whether monitoring reports were
    # pulled within a year prior to the midcycle guidance request

    if (midcycle_date - prevmonitor_date >= 365) {
      warnings <- TRUE
      messages <- paste(messages, "WARNING: Monitoring data are over a year old",
        sep = "\n"
      )
      current_cycle_cutoff <- as.Date(paste(cycleend - 1, TRANSLOCATING$months[1],
        "01",
        sep = "-"
      ))
    } else {
      if (midcycle_date - prevmonitor_date < 0) {
        warnings <- TRUE
        messages <- paste(messages, "WARNING: Previous run monitoring is newer than midcycle reports",
          sep = "\n"
        )
        current_cycle_cutoff <- as.Date(paste(cycleend - 1, TRANSLOCATING$months[1],
          "01",
          sep = "-"
        ))
      } else {
        # midcycle_date - prevmonitor_date is between 0 and 365
        current_cycle_cutoff <- prevmonitor_date
      }
    }
  } else {
    # One or both of the file names is missing a date
    warnings <- TRUE
    paste(messages, "WARNING: Cannot assess whether monitoring occurred less than a year before midcycle reports were submitted",
      sep = "\n"
    )
    current_cycle_cutoff <- as.Date(paste(cycleend - 1, TRANSLOCATING$months[1],
      "01",
      sep = "-"
    ))
  }
}


##  17. The midcycle pull date does not belong to the cycle defined by cycleend
#
#       This check takes into account the time of year that MCFG is generated
##
if (length(midcyclename) > 0) {
  # Only check on midcycle_date if it exists. (it's only created when
  # midcyclename isn't empty)

  midcycle_month <- as.numeric(format(midcycle_date, "%m"))
  midcycle_year <- as.numeric(format(midcycle_date, "%Y"))
  if (midcycle_month %in% c(11, 12)) {
    # Midcycle reports are pulled near the end of the first year of the cycle
    if (midcycle_year != (cycleend - 1)) {
      warnings <- TRUE
      messages <- paste(messages, "WARNING: Midcycle reports are not from the chosen cycle",
        sep = "\n"
      )
    }
  } else {
    # Midcycle reports are pulled near the beginning of the second year of the cycle
    if (midcycle_year != cycleend) {
      warnings <- TRUE
      messages <- paste(messages, "WARNING: Midcycle reports are not from the chosen cycle",
        sep = "\n"
      )
    }
  }
}


# ==============================================================================
#  END OF ERROR CHECKING ON USER INPUTS
#   Change proceed to TRUE if either of these cases is TRUE:
#   * errors and warnings are both FALSE
#     (i.e. no issues in inputs)
#   * errors is FALSE, warnings is TRUE, and messages == oldmsg
#     (i.e. the user has had a chance to view the warnings, and
#      has decided to proceed by hitting the button again)
#
#  If proceed==TRUE, create guidance forecast
# ==============================================================================

## If messages is no longer null, strip the leading '\n', which was added
#  during the first call to paste()
if (!is.null(messages)) {
  messages <- substr(messages, 2, nchar(messages))
}

# set proceed
if (errors == FALSE & warnings == FALSE) {
  # No issues with any of the inputs
  proceed <- TRUE
} else {
  if (errors == FALSE & warnings == TRUE) {
    # the only issues are warnings-- user may proceed with caution
    messages <- paste(messages, "", "*** To proceed without changes, click 'Review Reports' again ***",
      sep = "\n"
    )

    # If messages==oldmsg, no changes were made since the last warning-only
    # attempt
    # Allow processing to move to next step
    if (messages == oldmsg) {
      proceed <- TRUE
    }
  }
}


# ==============================================================================
#  Clean up temporary variables
# ==============================================================================
suppressWarnings(rm(
  current_year, current_month, cycleend, selectend, cost_path,
  prev_run, expected_files, isok, prevyear, midcycle_year,
  midcycle_month, run_log, prev_cycle_years, prev_run_year,
  prev_cycle
))
# Some of these variables are created inside of conditional and may not exist
# every time this script is run
