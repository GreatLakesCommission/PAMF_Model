# This is the Shiny application that provides a graphical interface
# for the PAMF model.
#
# The interface is meant to make the PAMF model usable by people without
# programming experience, and to protect us against data-input errors on our 
# end.
#
# The user experience flows as follows:
#
#                Welcome
#             _____|________________________
#            |           |                 |
#        Create        Resume           Forecast
#       Model Run    existing run       guidance
#            |           |                 |
#        (describe       |              (Done!)
#       data issues)*    |
#            |___________|
#                  |
#                Resolve
#                issues
#                  |
#       (construct data packages)*
#                  |
#              run model
#                  |
#                Done!
##

## ---- Start-Up Commands ------------------------------------------------------

## Set Defaults
#  Set stringsAsFactors to FALSE (This isn't a problem with R 4+? But older
#  versions of R default TRUE)
options(stringsAsFactors = FALSE)


## Source the necessary packages and functions to get the app started
#  Others will be sourced as needed

tryCatch(library(shiny), error = function(e) {
  message("Shiny is required to run the model UI. Installing... ")
  install.packages("shiny", version = "1.7.4")
}) # install if not found

tryCatch(library(rmarkdown), error = function(e) {
  message("RMarkdown is required to create data QA/QC reports. Installing... ")
  install.packages("rmarkdown", version = "2.20")
}) # install if not found

# Load MDPToolbox. if it isn't installed already, install it.
tryCatch(library(MDPtoolbox), error = function(e) {
  install.packages("MDPtoolbox", version = "4.0.3")
  message("MDPToolBox is required for the optimization. Installing....")
})


## Display package versions in the console
#  to help user/maintainer with troubleshooting

# Versions it was developed under:
message("\nThis version of the PAMF model (2023) was developed using the following versions:")
message("R 4.1.0")
message("Shiny 1.7.4")
message("RMarkdown 2.20")
message("MDPToolbox 4.0.3")

# Versions it's running with:
message("\nCurrently running with package versions:")
message(paste("Shiny", packageVersion("shiny")))
message(paste("RMarkdown", packageVersion("rmarkdown")))
message(paste("MDPToolbox", packageVersion("MDPtoolbox")))


## Source constants and functions

# Constants used by several scripts/functions
source("./src/global-constants.R")

# Functions that create user interface for each screen
source("./src/interface-functions.R")

# Functions that are used in more than one section of the code
source("./src/general-functions.R")
source("./src/format-functions.R")
source("./src/review-input-functions.R")


## --- User Interface ----------------------------------------------------------
#  Input widgets and output displays
##
ui <- fluidPage(

  # The interface will walk the user through several steps of running the model
  # (as in the diagram above) where each step takes place on one tab.
  tags$style("#PAMFsteps { display:none; }"), # hide tabs
  tabsetPanel(
    id = "PAMFsteps",
    tabPanel(
      "welcome",
      # Welcome & choose whether to initiate a new review of
      # PAMF data or resume an existing one
      welcomePage()
    ),
    tabPanel(
      "create",
      # Input choices and data necessary to set up a model run
      createNewRun()
    ),
    tabPanel(
      "revisit",
      # Select an existing run for QAQC resolution
      chooseActiveRun()
    ),
    tabPanel(
      "resolve",
      # Choose which management/monitoring reports
      # should be shown to different parts of the model
      resolveIssues()
    ),
    tabPanel(
      "modelrunning",
      # Status of data package construction, matrix updates,
      # optimization;
      # option to annotate the model run directory name
      modelRunning()
    ),
    tabPanel(
      "mcfg",
      # File input for mid-cycle forecast guidance (MCFG)
      forecastGuidance()
    )
  )
) # end of ui


## --- Server ------------------------------------------------------------------
#  Contains all logic to process inputs from ui and implement actions
##
server <- function(input, output, session) {

  ## Define wrapper function to switch between tabs
  switch_tab <- function(page) {
    updateTabsetPanel(session, "PAMFsteps", selected = page)
  }

  ## The rest of the server consists of observeEvent() calls.
  #
  #  Most of them respond to clicks of different buttons:
  #    * leave_welcome, Welcome screen:
  #        Takes user to "create", "revisit", or  "mcfg" page, as per their
  #        choice
  #    * create_run, Review screen:
  #        Checks user input for issues. If no issues or issues overridden,
  #        create a new model run folder, run the report-level datacleaning
  #        script, and the take user to the "resolve" page
  #    * select_run, Resume screen:
  #        Prompts the user to select an incomplete model run from a list, then
  #        takes the user to the "resolve" page
  #    * quitfromcheckbox, Review Reports screen:
  #        Exits the PAMF UI, leaving all decisions in their saved/unsaved states
  #    * finalize, Review Reports screen:
  #        If all MUs have saved decisions, proceed to data package construction
  #        and model run. Otherwise, display a message
  #    * quitfromcomplete, Run Completion Screen:
  #        Exits the PAMF UI
  #
  # A last one contains code to be executed upon arrival at the following tabs:
  #    * if tab is changed to "resolve"
  #        Gets and displays flagged reports, within the "resolve" tab
  #    * if tab it changed to "modelrunning"
  #         Constructs data packages, updates matrices, generates guidance
  #
  #  In order to keep these blocks readable, most of the processing behind them
  #  is sourced from scripts.
  ##

  # ---- leave_welcome, Welcome screen: ----------------------------------------
  #  Takes user to "create", "revisit", or "mcfg" page, as per their choice.
  ##
  observeEvent(input$leave_welcome, {
    choice <- length(as.numeric(input$checkReports))
    if (choice > 0) {
      # only move to another step if a button is selected
      switch(input$checkReports,
        "1" = switch_tab("create"),
        "2" = switch_tab("revisit"),
        "3" = switch_tab("mcfg")
      )
    }
  })


  # ---- create_run, Create screen: --------------------------------------------
  #  Checks user input for issues. If no issues or issues overridden, create a
  #  new model run folder, runs the report-level data cleaning script, and takes
  #  user to the "resolve" page
  ##
  oldmsg <- "" # Keep track of the last set of errors/warnings about user input
  # Needed in order to allow user to override warnings if desired

  observeEvent(input$create_run, {
    source("./src/create-new-run/create-run-functions.R")

    ## Verify that the inputs can be used to create a new model run
    #
    #  The script below creates two variables that determine whether
    #  the event  moves the user to the next screen of the
    #  interface:
    #    proceed  : FALSE unless there are (a) no input issues or
    #               (b) the user overrides any existing warnings
    #    messages : Text of the warnings generated when
    #               review-user-inputs.R is sourced.
    #               When the same warnings appear twice in a row,
    #               the user has overridden them.
    #
    #  It also creates the variables:
    #    enrollname  : name of enrollment data file
    #    monitorname : name of monitoring data file
    #    managename  : name of management data file
    #    mndatename  : name of application date file
    #
    #    pull_date   : the date that the last of the above files
    #                  was pulled from the database
    ##
    source("./src/create-new-run/review-user-inputs.R", local = TRUE)

    if (proceed == FALSE) {
      # Display errors/warnings/etc
      output$review_messages <- renderText(messages)

      # force oldmsg out of event handler's scope so it will exist
      # for the next button push
      oldmsg <<- messages
    } else {
      ## proceed is TRUE! Create the model run
      #
      #  Since this step takes a few seconds, prevent extra clicks
      #  by replacing the button with a message. But first, start
      #  building the run so we can tell the user where it is!
      ##
      oldmsg <<- "" # re-set oldmsg to original value
      removeUI("#create_run", immediate = TRUE)
      REPORTEND <<- pull_date

      ## create the model run directory
      #  This function call also creates the global constant
      #  REPORTBEGIN, which defines be beginning of the reporting
      #  window for CYCLE
      run_path <- createRun(
        input$cycleend, input$pulldate,
        input$prevrun, input$runname,
        input$costconst, enrollname, monitorname,
        managename, mndatename
      )

      ## Generate a message telling the user where the new run is
      #  located, and to be patient
      the_message1 <- paste("Creating new model run in", run_path)
      the_message2 <- "This may take a minute..."
      insertUI("#slow_message",
        immediate = TRUE,
        ui = wellPanel(
          h5(the_message1), br(),
          h5(strong(the_message2))
        )
      )

      ## Set global constants for the remainder of the session:
      #  formatted data tables, run path, end year of current cycle
      ##
      message("Setting global constants...")
      RUNPATH <<- run_path
      CYCLEEND <<- input$cycleend
      CYCLE <<- c(CYCLEEND - 1, CYCLEEND)
      COST_CONSTS <<- cost_consts


      ## Read the data files
      message("reading data files...")
      enroll_raw <- read.csv(input$enroll$datapath)
      monitor_raw <- read.csv(input$monitor$datapath)
      manage_raw <- read.csv(input$manage$datapath)
      mndates_raw <- read.csv(input$mndates$datapath)


      ## Make sure that reports are in standard format and discard
      #  superfluous reports
      #
      #  Formatting involves things like:
      #    * converting date columns to date format
      #    * making sure that all TRUE/FALSE, NA, NULL etc. are
      #      recognized by R
      #    * splitting off monitoring/management months for later
      #      use
      #    * merging applicationdates onto management reports
      ##
      message("formatting reports...")
      enroll_data <- formatEnroll(enroll_raw, CYCLEEND)
      mon_data <- formatMonitor(monitor_raw, CYCLEEND)
      man_data <- formatManage(manage_raw, mndates_raw, CYCLEEND)


      ## Check all new reports for possible issues
      #
      #  These scripts create the following variables:
      #    * mon_issues
      #    * man_issues
      ##
      message("find potential issues with reports...")
      source("./src/create-new-run/find-monitor-issues.R",
        local = TRUE
      )
      source("./src/create-new-run/find-manage-issues.R",
        local = TRUE
      )

      ## write to file
      if (CYCLEEND > 2018) {
        # Not the first model run: Add rows to existing file
        writeOutput(mon_issues, "monitor_issues", RUNPATH,
          append = TRUE
        )
        writeOutput(man_issues, "manage_issues", RUNPATH,
          append = TRUE
        )
      } else {
        # The first model run: write a fresh file
        writeOutput(mon_issues, "monitor_issues", RUNPATH,
          append = FALSE
        )
        writeOutput(man_issues, "manage_issues", RUNPATH,
          append = FALSE
        )
      }

      # Push the formatted data to the global environment for use
      # after the handler ends
      PAMFDATA <<- list(
        enroll = enroll_data, monitor = mon_data,
        manage = man_data
      )

      # mon_issues<<-mon_issues # uncomment to make visible after app exits
      # man_issues<<-man_issues # uncomment to make visible after app exits

      ## Generate a word document summarizing possible ambiguous
      #  problems with the data, and write it into the run
      #  directory as Reports_to_Review.docx
      #
      # This script alters monitor, manage, mon_issues, man_issues
      # as follows:
      #  * replaces database codes for %establishment, etc with
      #    human-readable ones
      #  * orders each data frame by munitid
      # Note, however, that these variables only persist through the
      # checkbox screen. At the beginning of the data package
      # builder, they're replaced by the versions in PAMFDATA.
      ##
      message("generating RMarkdown report...")
      source("./src/review-reports/checkbox-functions.R")
      source("./src/review-reports/generate-issues-report.R",
        local = TRUE
      )


      ## Display the checkbox UI so that user can make decisions on
      #  reports
      #  This works somewhat differently than the UIs for the other
      #  screens, because this one is composed of nested modules.
      #    * switch_tab calls the screen's interface, which contains
      #      a set of instructions
      #      and the final buttons
      #    * lapply(flagged_mu... calls a module to display each MU
      #      with one or more flagged reports
      ##
      message("generating checkbox interface...")
      switch_tab("resolve")
    }
  })


  # ---- Select_run, Resume screen: --------------------------------------------
  #  Once the user selects an incomplete model run from the list, opens all 
  #  files specific to the chosen run, formats data, and takes the user to the 
  #  checkbox screen.
  ##
  observeEvent(input$select_run, { # Re-load data and move to the next step
    if (input$active_run != "Select...") {

      ## Disappear the button to prevent extra clicks
      removeUI("#select_run", immediate = TRUE)

      ## Get all information pertaining to the selected run
      #
      #  This script populates the global constants:
      #    * RUNPATH  : location of the current run directory
      #    * CYCLEEND : second/final year of PAMF cycle being
      #                 analyzed
      #    * CYCLE    : CYCLEEND and CYCLEEND-1
      #    * PAMFDATA    : reports from the databased from the
      #                    years in CYCLE
      #    * PULLDATE    : date of the database pull containing
      #                    the files used to generate PAMFDATA
      #    * COST_CONSTS : Constants used for cost calculations
      ##
      source("./src/resume-active-run/reload-run.R", local = TRUE)

      ## Move to the checkbox UI for decison making about reports
      message("generating checkbox interface...")
      switch_tab("resolve")
    }
  })


  # ---- finalize, Review Reports screen: --------------------------------------
  # If all MUs have saved decisions, proceed to data package construction and
  # model run. Otherwise, display a message
  ##
  flagged_mu <- NULL
  observeEvent(input$finalize, {

    ## Get munitids of all reports without saved selections & put into variable
    #  flagged_mu
    source("./src/review-reports/find-unsaved-selections.R", local = TRUE)

    ## If any MU doesn't have saved selections, display a message and do nothing
    #  Otherwise, proceed to the automated data cleaning step.
    if (length(flagged_mu > 0)) {
      output$finalize_msg <- renderText(
        {
          paste(
            "Please save selections for Management Unit ",
            flagged_mu, "before proceeding"
          )
        },
        sep = "<br>"
      )
    } else {
      ##  Move to the screen that describes the status of the model run
      switch_tab("modelrunning")
    }
  })

  # ----- get_forecast, Mid-cycle Screen ---------------------------------------
  # Checks user input for issues. If no issues or issues overridden,
  #   * call the data cleaning script
  #   * calculate forecasts
  #   * display location of forecast output
  ##

  # Keep track of the last set of error/warning messages about user input
  # Needed in order to allow user to override warnings if desired
  oldmsg <- ""

  observeEvent(input$get_forecast, {
    ## Verify that the inputs can be used to forecast guidance
    #
    #  The script below creates two variables that determine whether the event
    #  moves the user to the next screen of the interface:
    #    proceed  : FALSE unless there are (a) no input issues or (b) the user
    #               overrides any existing warnings. The user overrides warnings
    #               by clicking the button a second time without making other
    #               changes. i.e. the override condition occurs when the same
    #               set of warnings appears twice in a row
    #    messages : Text of the warnings generated when review-midcycle-inputs.R
    #               is sourced.
    #
    #    It additionally creates the following variables:
    #    midcyclename : name of midcycle report file
    #    enrollname   : name of enrollment data file
    #    managename   : name of management data file
    #    mndatename   : name of application date file
    #
    #    prev_path  : path to the directory containing outputs from the previous
    #                 model run (selected by user)
    #    prev_end   : the second year of the cycle for which the previous model
    #                 run was conducted
    #
    #   current_cycle_cutoff : Cutoff date for midcycle and management reports.
    #                          Reports submitted before this date will be
    #                          ignored
    ##
    source("./src/forecast-guidance/midcycle-functions.R")
    source("./src/forecast-guidance/review-midcycle-inputs.R", local = TRUE)

    if (proceed == FALSE) {
      # Display errors/warnings/etc
      output$review_messages_fg <- renderText(messages)

      # force oldmsg out of handler's scope so it will exist at the next button
      # push
      oldmsg <<- messages
    } else {
      ## proceed is TRUE! Generate guidance forecasts
      #  Since this step takes a few seconds, prevent extra clicks by replacing
      #  the button with a message. But first, start building the run so we can
      #  tell the user where it is!
      ##
      oldmsg <<- "" # re-set oldmsg to original value
      removeUI("#get_forecast", immediate = TRUE)

      ## Create the forecast directory and input log
      forecast_path <- createForecast(
        input$cycleend_fg, input$prevrun_fg,
        prev_end, input$runname_mcfg, midcyclename,
        enrollname, managename, mndatename
      )

      ## here's the message that replaces the button
      #  had to do those other things first in order to be able to display the
      #  run path
      the_message1 <- paste("Creating midcycle forecast guidance in", forecast_path)
      the_message2 <- "This may take a minute..."
      insertUI("#slow_message_fg",
        immediate = TRUE,
        ui = wellPanel(h5(the_message1), h5(strong(the_message2)))
      )

      ## Set global constants for the remainder of the session:
      #  formatted data tables, forecast path, end year of current cycle,
      #  path to previous run and the end year of the cycle it applies to
      ##
      FORECASTPATH <<- forecast_path
      CYCLEEND <<- input$cycleend

      PREVPATH <<- prev_path
      PREVCYCLE <<- prev_end

      ## Read and format the data files
      #  Formatting involves things like:
      #    * converting date columns to date format
      #    * making sure that all TRUE/FALSE, NA, NULL etc. are recognized by R
      #    * splitting off management months for later use
      #    * merging applicationdates onto management reports
      #    * dropping records from cycles not defined by CYCLEEND
      #
      # Why doesn't this section of the code read monitoring reports? Because
      # all relevant monitoring information can be found in the previous run.
      ##
      enroll_reports <- read.csv(input$enroll_fg$datapath)
      manage_reports <- read.csv(input$manage_fg$datapath)
      mndate_reports <- read.csv(input$mndates_fg$datapath)
      midcycle_reports <- read.csv(input$midcycle_fg$datapath)

      enroll <- formatEnroll(enroll_reports, CYCLEEND)
      manage <- formatManage(manage_reports, mndate_reports, CYCLEEND)
      midcycle <- formatMidcycle(midcycle_reports, CYCLEEND)

      ## Consider only reports that were submitted after the current cycle
      #  cutoff date or if the column is present, the cycleyear
      if("cycleyear" %in% colnames(manage)){
        manage <- manage[which(manage$cycleyear %in% CYCLEEND | manage$dateentered > current_cycle_cutoff), ]
      }else{
        manage <- manage[which(manage$dateentered > current_cycle_cutoff), ]
      }

      midcycle <- midcycle[midcycle$dateentered > current_cycle_cutoff, ]

      ## Push the formatted data to the global environment for use after the
      #  handler ends
      PAMFDATA <<- list(enroll = enroll, manage = manage, midcycle = midcycle)


      ## Read model outputs from the previous run & trim to previous run's cycle
      datpak <- read.csv(paste0(PREVPATH, "datpak.csv"))
      datpak <- datpak[datpak$cycle_end == PREVCYCLE, ]

      mon_issues <- read.csv(paste0(PREVPATH, "monitor_issues.csv"))
      mon_issues <- mon_issues[mon_issues$cycle_end == PREVCYCLE, ]

      transitions <- read.csv(paste0(PREVPATH, "transition_matrices.csv"))
      transitions <- transitions[transitions$cycle_used == PREVCYCLE, ]

      policies <- read.csv(paste0(PREVPATH, "policies.csv"))
      policies <- policies[policies$cycle_end == PREVCYCLE &
        policies$optimal == 1, ]

      ## Read definitions of action restrictions. This file lists the actions
      #  that are possible when herbicide/cut underwater/flood (or combinations
      #  thereof) cannot be used on an MU
      action_restrictions <- read.csv(RESPATH)


      ## Check all formatted reports for possible additional issues, e.g.:
      #   * Monitoring report for MU with a midcycle guidance request is either
      #     missing or was rejected due to quality issues
      #   * A growing report has already been submitted for the current cycle
      #   * The planned management combination is incompatible with either the
      #     MU's restrictions on actions or with actions that have already been
      #     reported
      #
      #   The script below creates the following variable(s):
      #   * midcy_issues : a dataframe containing potential issues with midcycle
      #                    information
      ##
      source("./src/forecast-guidance/find-midcycle-issues.R", local = TRUE)

      writeOutput(midcy_issues, "midcycle_issues", FORECASTPATH, append = FALSE)
      # midcy_issues<<-midcy_issues # uncomment to make visible after app exits


      ## Generate midcycle forecast guidance
      #
      #  When forecast-guidance.R is sourced, it generates:
      #    * mcfg : dataframe containing guidance for each MU that had a mcfg
      #             request and no issues
      ##
      source("./src/forecast-guidance/forecast-guidance.R", local = TRUE)
      writeOutput(mcfg, paste0("mcfg", Sys.Date()), FORECASTPATH,
                  append = FALSE)

      ## Notify the user that MCFG generation is complete & where to find the
      #  outputs
      insertUI("#mcfg_done",
        immediate = TRUE,
        ui = wellPanel(
          h5(strong("MCFG is complete!")),
          # h5(paste("You can find all outputs at", FORECASTPATH)),
          actionButton("quitfromforecast",
            label = "See you in August!"
          )
        )
      )
    }
  })


  # ----- go back buttons : ----------------------------------------------------
  # A dead end occurs when
  #  * the user tries to resume an active run but there aren't any
  observeEvent(input$gobackfromresume, {
    switch_tab("welcome")
  })


  # ----- quit buttons : -------------------------------------------------------
  # Review Reports screen; model complete screen
  # There are multiple 'quit' buttons because Shiny ignores all but the first
  # element with a particular name
  #
  # Each of these buttons exits the PAMF UI from a different screen
  ##
  # REMOVE all remaining VARIABLES
  observeEvent(input$quitfromcheckbox, {
    stopApp()
    rm(list = ls(all.names = TRUE))
  })
  observeEvent(input$quitfromcomplete, {
    stopApp()
    rm(list = ls(all.names = TRUE))
  })
  observeEvent(input$quitfromforecast, {
    stopApp()
    rm(list = ls(all.names = TRUE))
  })


  ## ==== END OF HANDLERS FOR BUTTON-GENERATED EVENTS ==========================
  #
  #  The next section is made up of code that executes upon arrival at a new
  #  tab/screen:
  #    * "resolve" (checkbox screen):
  #         Finds reports to be displayed for decision making & displays them
  #    * "modelrunning":
  #         Constructs data packages from reports
  #         Determines which data packages can go into:
  #            Transition matrix updates
  #            Partial controllability matrix update
  #            Guidance release
  #         Executes "the model run", i.e. what we mean when we talk 
  #         colloquially about "running the model":
  #            Transition matrix updates
  #            Estimate management costs
  #            Build reward matrix
  #            Update partial controllability matrix
  #            Find optimal and near-optimal policies
  #            Map policies onto individual MUs (i.e. produce guidance)
  ##

  # ----- TAB CHANGE EVENTS: ---------------------------------------------------
  #  Computations that take place upon arrival to a new tab
  ##
  observeEvent(input$PAMFsteps, {
    if (input$PAMFsteps == "resolve") {
      ## Find and display reports that have been flagged for screening
      #  Note: The calls that generate the UI modules defining the display and
      #        actions for each MU's reports are in here
      source("./src/review-reports/display-flagged-reports.R", local = TRUE)
    } # end "resolve"

    if (input$PAMFsteps == "modelrunning") {
      ## Get all data
      #  * Recall that previous instances of mon_data, man_data etc. existed in
      #    the scope of their event handler;
      #    pull down a new copy from the global constant PAMFDATA
      #  * The most recent version of mon_issues and man_issues is what was 
      #    saved to file at the end of the review
      #    process. Read that information from the files
      ##
      mon_data <- PAMFDATA$monitor
      man_data <- PAMFDATA$manage
      enroll_data <- PAMFDATA$enroll

      mon_issues <- read.csv(paste(RUNPATH, "monitor_issues.csv", sep = ""))
      man_issues <- read.csv(paste(RUNPATH, "manage_issues.csv", sep = ""))

      ## drop reports belonging to years not in CYCLE
      #  but note that some reports from the previous cycle will remain
      mon_issues <- mon_issues[mon_issues$monitor_year %in% CYCLE, ]
      man_issues <- man_issues[man_issues$manage_year %in% CYCLE, ]

      # mon_issues<<-mon_issues # uncomment to make visible after app exits
      # man_issues<<-man_issues # uncomment to make visible after app exits


      ## Append newly generated outputs to previous data?
      #    For 2018 (the first run), no
      #    For later runs, yes
      ##
      if (CYCLEEND == 2018) {
        append <- FALSE
      } else {
        append <- TRUE
      }


      ## Construct data packages
      #       This is the last data cleaning step. Build a data package from
      #       each MU's reports during CYCLE. Find and record any issues that
      #       would make the data package unusable for the transition matrix
      #       update, partial controllability update, or guidance release.
      #
      #  This script creates two variables:
      #    * datpak        : All data packages within CYCLE
      #    * datpak_issues : Possible issues/decisions for datpaks
      #
      #  It also updates  the following variables:
      #  manage      : adds model_phase column
      #  man_changes : records any changes between equivalent management actions
      #                (i.e. where P/LB swaps occur)
      ##
      source("./src/construct-datpaks/construct-datpaks.R", local = TRUE)

      writeOutput(datpak, "datpak", RUNPATH, append)
      writeOutput(datpak_issues, "datpak_issues", RUNPATH, append)
      writeOutput(man_changes, "report-repairs", RUNPATH, append)
      updatePhaseIssues(man_issues, RUNPATH)

      PAMFDATA$manage <<- manage # push updated management data to GlobalEnv

      ## Reproduce Manual Changes from 2018-2019
      #
      #  Prior to the UI, we did some data cleaning by hand when needed. The
      #  scripts calls below reproduce those changes whenever you rebuild a
      #  model run from either year. Note that they'll override any changes
      #  you made in the checkbox step for the affected MUs.
      #
      #  datamod_2018 modifies the following variables:
      #    * mon_issues
      #    * man_issues
      #    * datpak
      #    * datpak_issues
      #
      #  datamod_2019 modifies the following variables:
      #    * datpak_issues
      #    * mon_issues
      #
      # (in all of the following file writes, append is FALSE)
      ##
      if (CYCLEEND == 2018) {
        source("./src/construct-datpaks/datamod_2018.R", local = TRUE)
        writeOutput(mon_issues, "monitor_issues", RUNPATH)
        writeOutput(man_issues, "manage_issues", RUNPATH)
        writeOutput(datpak, "datpak", RUNPATH)
        writeOutput(datpak_issues, "datpak_issues", RUNPATH)
        writeOutput(man_changes, "report-repairs", RUNPATH)
      }
      if (CYCLEEND == 2019) {
        source("./src/construct-datpaks/datamod_2019.R", local = TRUE)

        # writeOutputChanges(datpak,"datpak.csv",RUNPATH)
        # commented because no changes made
        writeOutputChanges(datpak_issues, "datpak_issues.csv", RUNPATH)
        writeOutputChanges(mon_issues, "monitor_issues.csv", RUNPATH)
        writeOutputChanges(man_issues, "manage_issues.csv", RUNPATH)
        writeOutputChanges(datpak, "datpak.csv", RUNPATH)
        # Appends new rows (use writeOutput):
        writeOutput(man_changes, "report-repairs.csv", RUNPATH)
        # Trim datpak_issues so that it contains only the 2018-19 cycle
        datpak_issues <- datpak_issues[datpak_issues$cycle_end == 2019, ]
      }


      ## Display MUs with complete and valid data packages (i.e. those that
      #  will contribute to the transition matrix update)
      message("MUs with complete and valid data packages:")
      message(cat(datpak_issues[!datpak_issues$autoreject_model, "munitid"]))
      message("")

      # uncomment to make visible after app exits
      # datpak<<-datpak
      # datpak_issues<<-datpak_issues


      ## --- This is the beginning of what we often refer to as "the model", 
      #      i.e., the part of the software that updates the transition and 
      #      partial controllability matrices, calculates costs, and runs an
      #      optimization routine to find the highest-value guidance for each MU
      ##
      source("./src/run-model/run-the-model.R", local = TRUE)

      ## Notify the user that the model run is complete & where to find the
      #  outputs also add a 'quit' button
      insertUI("#all_done",
        immediate = TRUE,
        ui = tagList(
          h5(strong("The model run is complete!")),
          h5(paste("You can find all outputs at", RUNPATH)),
          actionButton("quitfromcomplete", label = "See you next year!")
        )
      )

      message("model run is complete!")
    } # end "modelrunning"
  })
} # end of server


## --- Run the Application -----------------------------------------------------
shinyApp(ui = ui, server = server)
