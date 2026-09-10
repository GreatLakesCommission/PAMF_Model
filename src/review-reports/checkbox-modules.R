# 2020-03-23
#
# This file contains the ui and server components of all Shiny app modules
# that display and collect information about data cleaning that requires human
# judgement.
#
# The total length of participant input varies from year to year: different
# numbers of MUs are active; the number of management reports per MU may vary.
# Consequently, the app needs to display an arbitrary number of repeats of the
# same interface fragment at both the MU and report levels. It uses a nested
# modular structure, where each MU-level module calls the monitoring and
# management sub-modules zero or more times. User input is collected in each
# report-level module, and saved to file at the MU level.
#
#
# CONTROL FLOW as of 2020-04-03
# each time the app server calls callModule(id, muDispServer):
#   * a muDispUI fragment is created that contains the "Management Unit ID"
#     heading and tagsindicating where to insert UI fragments for managment and
#     monitoring reports
#   * If the MU has flagged monitoring reports, display "Monitoring Reports"
#     heading and call the monDispServer module for each flagged report
#   * If the MU has flagged management reports, display "Management Reports"
#     heading and call the manDispServer module for each flagged report
#   * Within each report fragment: collect checkbox and text input from user.
#     Pass to MU fragment
#   * Within each MU fragment: Save/unsave information from checkboxes and text
#     input This is done by displaying a "Save Submissions" and a "Change
#     Submissions" button on alternate clicks, using a tabset.
#
# A note on nested module IDs:
# IDs are defined in each module, but inner module IDs are defined at run time
# and CANNOT be called by the ID assigned to them in the code. The reason is
# that the ID that the code gives to the inner module is appended to the ID of
# the outer module that it lives in. For example, suppose that you want to look
# at the module displaying Monitoring Report 22, which contains data for
# Management Unit 33. Instead of looking for module 22 (as you've defined it in
# the code), you need to look for module 33-22, because (I assume) sub-module 22
# wasn't created until called by module 33. This is discussed nowhere in any
# module documentation that I've seen. I figured it out by displaying module IDs
# to stderr using message()
#
#
# Sourced by: ResolveIssues (in interface-functions.R)
#
# DEPENDENCIES
# * Global Constants
#    RUNPATH : path to directory containing outputs of the ongoing model run
# * Files in RUNPATH
#    monitor_issues.csv
#    manage_issues.csv
##

## If running outside of app.R, uncomment the following:
# options(stringsAsFactors=FALSE)

## ====  OUTER MODULE : Managment Unit =========================================

muDispUI <- function(id) {
  # Creates display for each set of reports, grouped by MU

  ns <- NS(id)
  tagList(
    fluidRow(wellPanel(h3(strong(textOutput(ns("munitid")))))),
    div(id = paste("monitor_heading", id, sep = "")), # Monitoring report section
    div(id = paste("monitor", id, sep = "")),
    div(id = paste("manage_heading", id, sep = "")), # Management report section
    div(id = paste("manage", id, sep = "")),
    br(), hr(),

    ## Tab set for submit/undo buttons
    #  "Submit Selections" (save) and "Change selections" (undo) buttons appear on
    #  alternate clicks, so that the user can correct input mistakes and re-save
    #  selections as necessary.
    tagList(
      tags$style(paste("#", ns("submitUndo"), " {display:none;}", sep = "")),
      tabsetPanel(
        id = NS(id, "submitUndo"),
        tabPanel(
          "submit",
          actionButton(ns("submit"),
            label = paste("Save Selections for MU ",
              substr(id,
                start = 3,
                stop = nchar(id)
              ),
              sep = ""
            )
          ),
          # Prompt the user to enter their name at the
          # top of the page. output$name_msg is empty (i.e.
          # no display) when the name field is nonempty
          div(textOutput(ns("name_msg")), style = "color:red")
        ),
        tabPanel(
          "undo",
          tagList(
            actionButton(ns("undo"),
              label = "Change Selections"
            ),
            # Display the saved selections for each report:
            wellPanel(
              strong(htmlOutput(ns("monrej_msgs"))),
              strong(htmlOutput(ns("manrej_msgs")))
            )
          )
        )
      )
    ),
    br()
  )
} # end muDispUI

muDispServer <- function(input, output, session, monreps_mu, manreps_mu,
                         monissues, manissues, screener_name) {
  # Creates display for each set of reports, grouped by MU
  #
  # INPUT (additional to the standard input, output, session arguments)
  # monreps_mu  : Current-cycle monitoring reports associated with a single
  #               management unit (dataframe)
  # manreps_mu  : Current-cycle management reports associated with a single
  #               management unit (dataframe)
  # monissues   : Possible issues with each monitoring report (dataframe)
  # manissues   : Possible issues with each management report (dataframe)
  # screener_name : Name of the user screening reports for issues (reactive)
  #
  # OUTPUT
  #
  # ASSUMPTIONS
  # * All dataframe inputs have a "munitid" column
  # * monreps_mu has a "monitorid" column
  # * manreps_mu has a "treatmentid" column
  # * monissues has a "monitorid" column
  #   (same information as monreps_mu$monitorid)
  # * manissues has a "treatmentid" column
  # * CYCLEEND, RUNPATH are global constants
  # * These functions are sourced: SaveSelectionsMon, SaveSelectionsMan
  ##

  ## Make sure that the dataframes aren't reactive.
  #  This information comes from .csv files, not from user input
  stopifnot(!is.reactive(monreps_mu))
  stopifnot(!is.reactive(manreps_mu))
  stopifnot(!is.reactive(monissues))
  stopifnot(!is.reactive(manissues))

  ## Get the MU ID. It may appear in the monitoring
  #  reports, the management reports, or both
  #  It's used in the following places:
  #   * display MU ID
  #   * name the selectors in each outer module ui. If selectors aren't named
  #     uniquely, reports will be displayed at the first selector that matches
  #     the one in insertUI (i.e. they'd all end up associated with the first
  #     managment unit in the list)
  outer_munitid <- unique(c(monreps_mu$munitid, manreps_mu$munitid))

  ## Populate the section title with the Management Unit ID
  output$munitid <- renderText({
    paste("Management Unit", outer_munitid)
  })

  ## Reconstruct the outer module's ID
  #  The piece of CSS that's needed to conceal the tabs in the submit/undo
  #  tabset doesn't like module IDs that begin with a number. I got around this
  #  issue by appending "mu" to the ID before creating these modules. I need to
  #  reconstruct this ID in order to tell the sub-modules to appear in the
  #  correct MU module
  outer_id <- paste("mu", outer_munitid, sep = "")

  ## Populate and insert the ui pieces for monitoring reports
  if (nrow(monreps_mu) > 0) {
    ## Section headings
    insertUI(
      selector = paste("#monitor_heading", outer_id, sep = ""),
      ui = tagList(fluidRow(column(12, h3(strong(" Monitoring Reports")),
        offset = 0.1
      )), hr())
    )

    monreps_ids <- monreps_mu$monitorid

    ## Display monitoring report sub-module UI, using a locally defined function
    #  and lapply()
    displayMonitorReport <- function(rep_id, monreps_mu, monflags_mu) {
      # Create and insert one repeat of the monitoring report module
      selections <- callModule(monDisplayServer,
        id = as.character(rep_id),
        monreps_mu[monreps_mu$monitorid == rep_id, ],
        monflags_mu[monflags_mu$monitorid == rep_id, ]
      )
      insertUI(
        selector = paste("#monitor", outer_id, sep = ""), where = "beforeEnd",
        ui = monDisplayUI(paste(outer_id, "-", rep_id, sep = ""))
      )
      return(selections)
    } # end displayMonitorReport

    ## insert the monitoring report UIs and collect coordinator inputs into
    #  mon_choices, a list whose elements are all selections from each checkbox
    #  group + the text box
    mon_choices <- lapply(monreps_ids, displayMonitorReport,
      monreps_mu = monreps_mu,
      monflags_mu = monissues[monissues$munitid == outer_munitid, ]
    )
  } # End of monitoring report module calls

  ## Populate and insert the ui pieces for management reports
  if (nrow(manreps_mu) > 0) {
    ## Section headings
    insertUI(
      selector = paste("#manage_heading", outer_id, sep = ""),
      ui = tagList(fluidRow(column(12, h3(strong(" Management Reports")),
        offset = 0.1
      )), hr())
    )

    manreps_ids <- unique(manreps_mu$treatmentid)

    ## Display management report sub-module UI, using a locally defined function
    #  and lapply()
    displayManageReport <- function(rep_id, manreps_mu, manflags_mu) {
      selections <- callModule(manDisplayServer,
        id = as.character(rep_id),
        manreps_mu[manreps_mu$treatmentid == rep_id, ],
        manflags_mu[manflags_mu$treatmentid == rep_id, ]
      )
      insertUI(
        selector = paste("#manage", outer_id, sep = ""), where = "beforeEnd",
        ui = manDisplayUI(paste(outer_id, "-", rep_id, sep = ""))
      )
      return(selections)
    } # end displayManageReport

    ## insert the monitoring report UIs and collect coordinator inputs into
    #  man_choices, a list whose elements are all selections from each checkbox
    #  group + the text box
    man_choices <- lapply(
      manreps_ids, displayManageReport, manreps_mu,
      manissues[manissues$munitid == outer_munitid, ]
    )
  } # end of management report module calls

  ## ACTION BUTTONS: Save selections or undo the previous save
  #  Note that 'save' is only possible when the report is in its inital state
  #  (FALSE on all decisions, screener name and notes are empty) and 'undo' is
  #  only possible in the saved state. Because reports have to go through the
  #  'undo' button (which erases user inputs) before regaining the 'save'
  #  functionality, it isn't possible to partially overwrite the user's input.
  #  Note: The contents of the report may not reflect what's shown on the
  #        checkbox screen because undoing a save does not clear the interface

  ## Respond to a press of the submit ("Save Selections") button:
  #  * Make sure that the screener has entered a name
  #  * Get screener's selections for each report
  #  * Write the selections for each report into monitor_issues/manage_issues
  #  * Write monitor_issues/manage_issues to file
  #  * Switch to the "undo" tab
  observeEvent(input$submit, {
    ## Check that the person reviewing the reports has given a name. This allows
    #  us to keep track of who made what decisions. Do not save or proceed until
    #  a name is entered.
    if (trimws(screener_name()) == "") { # the screener has not provided a name
      ## NOTE: this conditional relies on default value="" hard-coded into
      #        top-level UI text entry widget. We only enforce the condition that
      #        the name contain non-whitespace characters.

      ## If no name has been provided, prompt the user for a name
      #  and do not save or display the "Change Selections" tab until one is
      #  entered
      output$name_msg <- renderText({
        "Selections not saved: Please enter your name at the top of this page"
      })
    } else { # The screener has provided a name
      output$name_msg <- renderText({
        ""
      }) # clear the name prompt message

      ## Now that the screener name is no longer empty, proceed with:
      #  1. Get screener's selections for each report in this MU
      #  2. Write the selections for each report into monitor_issues/manage_issues
      #  3. Write monitor_issues/manage_issues to file
      #  4. Switch to the "undo" tab

      ## Keep track of screener's choices, for display on the "undo" panel
      monrej_msgs <- NULL
      manrej_msgs <- NULL

      ## Save monitoring, management selections. If no reports of those types is
      #  displayed, skip that section. Note that the details are pushed into
      #  saveSelectionsMon() and saveSelectionsMan(), which can be found in
      #  functions.R
      if (nrow(monreps_mu) > 0) { # There is at least one monitoring report up for review
        monrej_msgs <- saveSelectionsMon(monreps_mu$monitorid, mon_choices,
          screener_name,
          file_path = RUNPATH
        )
      } # end monitoring report conditional

      if (nrow(manreps_mu) > 0) { # There is at least one management report up for review
        manrej_msgs <- saveSelectionsMan(unique(manreps_mu$treatmentid),
          man_choices, screener_name,
          file_path = RUNPATH
        )
      } # end conditional for management reports

      ## Send monrej_msgs and manrej_msgs to output
      if (is.null(monrej_msgs) & is.null(manrej_msgs)) {
        output$monrej_msgs <- renderText({
          "No Reports Excluded"
        })
      } else {
        output$monrej_msgs <- renderText({
          monrej_msgs
        })
        output$manrej_msgs <- renderText({
          manrej_msgs
        })
      }

      ## Display the "undo" tab panel
      updateTabsetPanel(session, "submitUndo", selected = "undo")
    } # end the 'else' block of the screener name conditional
  }) # end observeEvent for "Save Selections" button


  ## Respond to a press of the "undo" (Change Selections) button:
  #  * In *issues, return the relevant rows to their initial state (FALSE in all
  #    reject/keep
  #    columns; NA in coord_notes and reviewed_by)
  #  * Save both issues dataframes to file
  #  * Display the "save" tab ("Save Selections" button)
  observeEvent(input$undo, {

    ## Read monissues, manissues from file to ensure that we're working with the
    #  most updated versions
    #  This approach solves a couple of problems:
    #    1. File saves are done at the MU (outer module) level. None of the
    #       modules can see the changes that other modules have made to *issues,
    #       so in the absence of this step, each file save effectively undoes
    #       the last.
    #    2. Why not make monissues and manissues into global variables? Under
    #       that approach, we'd be maintaining two versions: one in memory, and
    #       one in the .csv files. These versions could differ if (a) processing
    #       stops before changes to *issues are written to file, or
    #       (b) either of *_issues.csv is edited manually. Reading from the file
    #       every time means that we only have one "source of truth"
    file_path <- RUNPATH
    monissues <- read.csv(paste(file_path, "monitor_issues.csv", sep = ""))
    manissues <- read.csv(paste(file_path, "manage_issues.csv", sep = ""))

    ## For reports in the current cycle only, do the following:

    # Change all 'reject' columns to FALSE
    monissues[
      monissues$munitid == outer_munitid & monissues$cycle_end == CYCLEEND,
      c("coordreject_model", "coordreject_guid", "coordreject_amu")
    ] <- FALSE
    manissues[
      manissues$munitid == outer_munitid & manissues$cycle_end == CYCLEEND,
      c("coordreject_model", "coordreject_cost", "coordreject_amu")
    ] <- FALSE

    ## Erase all rej Notes
    monissues[
      monissues$munitid == outer_munitid & monissues$cycle_end == CYCLEEND,
      "coordreject_note"
    ] <- NA
    manissues[
      manissues$munitid == outer_munitid & manissues$cycle_end == CYCLEEND,
      "coordreject_note"
    ] <- NA

    ## Erase the screener's name
    monissues[
      monissues$munitid == outer_munitid & monissues$cycle_end == CYCLEEND,
      "reviewed_by"
    ] <- NA
    manissues[
      manissues$munitid == outer_munitid & manissues$cycle_end == CYCLEEND,
      "reviewed_by"
    ] <- NA

    ## Erase date of review
    monissues[
      monissues$munitid == outer_munitid & monissues$cycle_end == CYCLEEND,
      "reviewed_date"
    ] <- NA
    manissues[
      manissues$munitid == outer_munitid & manissues$cycle_end == CYCLEEND,
      "reviewed_date"
    ] <- NA


    ## Save to file (all rows)
    write.csv(monissues, paste0(RUNPATH, "monitor_issues.csv"), row.names = FALSE)
    write.csv(manissues, paste0(RUNPATH, "manage_issues.csv"), row.names = FALSE)

    ## Display the "submit" tab panel
    updateTabsetPanel(session, "submitUndo", selected = "submit")
  }) # end observeEvent for "Change Selections" button
} # end muDispServer



## ==== INNER MODULES: Monitoring/Management reports ===========================

monDisplayUI <- function(id) {
  # Creates display for each report

  ns <- NS(id)
  ## Create layout with monitoring information on the left and a well panel with
  #  a checkbox group on the right
  tagList(
    fluidRow(
      column(
        7,
        h4(strong(textOutput(ns("monitorid")))),
        br(),
        wellPanel(
          strong("Possible Issues:"),
          htmlOutput(ns("issues"))
        ),
        strong("Notes:"),
        textOutput(ns("notes")),
        br()
      ),
      column(
        5, br(), br(), # br(),br(),br(), br(), br(), br(), br(),br(),
        wellPanel(
          checkboxGroupInput(ns("checkGroup"),
            label = "",
            choices = list(
              "Exclude from Transition Matrix Update" = 1,
              "Exclude from Guidance and Transition Matrix Update" = 3,
              "Exclude from Annual Summary" = 4
            )
          ),
          textInput(ns("coordNote"), label = "Add Notes/Comments")
        )
      )
    ),
    fluidRow(tableOutput(ns("mutab")), br())
  )
} # end monDisplayUI


manDisplayUI <- function(id) {
  # creates display for each flagged management report

  ns <- NS(id)
  ## Create layout with management information on the left
  #  and a well panel with a checkbox group on the right
  tagList(
    fluidRow(
      column(
        7,
        h4(strong(textOutput(ns("treatmentid")))),
        # br(),
        wellPanel(
          strong("Possible Issues:"),
          htmlOutput(ns("issues"))
        ),
        br(),
        strong("Management Action Notes:"),
        htmlOutput(ns("ma_notes")),
        br(),
        strong("Product/Equipment Notes:"),
        htmlOutput(ns("pe_notes")),
        br(),
        strong("Guidance Compliance Notes:"),
        textOutput(ns("gc_notes")),
        br()
      ),
      column(
        5,
        br(), br(),
        wellPanel(
          checkboxGroupInput(ns("checkGroup"),
            label = "",
            choices = list(
              "Exclude from Transition Matrix Update" = 1,
              "Exclude from Cost Calculation" = 2,
              "Exclude from Annual Summary" = 4
            )
          ),
          textInput(ns("coordNote"), label = "Add Notes/Comments")
        ),
        br()
      )
    ),
    fluidRow(
      column(7, tableOutput(ns("mutab"))),
      column(5, tableOutput(ns("apptab")))
    ),
    br()
  )
} # end manDisplayUI


monDisplayServer <- function(input, output, session, monreps_mu, monflags_mu) {
  # creates display for each flagged monitoring report
  #
  # INPUT (additional to the standard input, output, session argument)
  # monreps_mu  : Current-cycle monitoring reports for a single management unit
  #               (dataframe)
  # monflags_mu : Potential issues with the reports in monreps_mu (dataframe)
  #
  # OUTPUT
  # checkbox selections
  #
  # ASSUMPTIONS
  # * monreps_mu has the following columns:
  #     monitorid
  #     monitoringdate
  #     establishment
  #     q1stemcount, q2stemcount, q3stemcount, q4stemcount, q5stemcount
  #     userid
  #     notes
  # * the following functions are sourced:
  #     getMonFlags
  ##

  ## Define outputs that populate the ui
  monrep_id <- monreps_mu$monitorid # force it to evaluate the report id. Not sure why but without this, it gets lazy
  output$monitorid <- renderText({
    paste("Monitoring Report", monrep_id)
  })

  ## Re-name columns so that the entire table fits in the window
  display_cols <- monreps_mu[, c(
    "dateentered", "monitoringdate", "establishment",
    "q1stemcount", "q2stemcount", "q3stemcount",
    "q4stemcount", "q5stemcount", "userid"
  )]
  display_cols$dateentered <- as.character(display_cols$dateentered) # renderTable doesn't understand dates
  display_cols$monitoringdate <- as.character(display_cols$monitoringdate) # renderTable doesn't understand dates
  colnames(display_cols) <- c(
    "date entered", "monitoring date", "establishment",
    "stemct1", "stemct2", "stemct3",
    "stemct4", "stemct5", "userid"
  )

  output$mutab <- renderTable({
    display_cols
  })
  output$notes <- renderText({
    monreps_mu$notes
  })

  ## Get a list of possible issues, for display:
  output$issues <- renderText({
    getMonFlags(monrep_id, monflags_mu)
  })

  ## Get the checkbox and notes input
  return(list(
    selections = reactive(input$checkGroup),
    notes = reactive(input$coordNote)
  ))
} # end monDisplayServer


manDisplayServer <- function(input, output, session, manreps_mu, manflags_mu) {
  # creates display for each flagged management report
  #
  # INPUT (additional to the standard input, output, session argument)
  # manreps_mu  : Current-cycle management reports for a single management unit
  #               (dataframe)
  # manflags_mu : Potential issues with the reports in manreps_mu (dataframe)
  #
  # OUTPUT
  # Checkbox selections
  #
  # ASSUMPTIONS
  # * manreps_mu has the following columns:
  #     treatmentid
  #     managementdate
  #     applicationdate
  #     manage_month
  #     application_month
  #     phase
  #     floodmonths
  # * the following functions are sourced:
  #     getManFlags
  ##

  ## Display the management report ID
  manrep_id <- unique(manreps_mu$treatmentid) # force it to evaluate the report id. Not sure why but without this, it gets lazy
  output$treatmentid <- renderText({
    paste("Management Report", manrep_id)
  })

  ## There may be more than one application date per report. The database deals
  #  with them in a related table, with one row per application date and as many
  #  rows as needed per management report. manreps_mu is derived from a
  #  dataframe where those two tables are merged, with the consequence that
  #  treatment reports may be made up of more than one row. Since all
  #  information aside from application dates is constant between rows, extract
  #  it from just the first row
  #
  #  Display using dateentered or managementdate, as appropriate
  #
  manreps_mu1 <- manreps_mu[1, ]

  if (max(manreps_mu1$manage_year) < 2020) {
    display_cols <- manreps_mu1[, c(
      "managementdate", "treatmethod", "phase",
      "munitcondition", "floodmonths"
    )]
    display_cols$managementdate <- as.character(manreps_mu1$managementdate) # renderTable doesn't understand dates
    colnames(display_cols) <- c(c(
      "management date", "action", "phase",
      "hydro condition", "flood months"
    ))
  } else {
    display_cols <- manreps_mu1[, c(
      "dateentered", "treatmethod", "phase",
      "munitcondition", "floodmonths"
    )]
    display_cols$dateentered <- as.character(manreps_mu1$dateentered) # renderTable doesn't understand dates
    colnames(display_cols) <- c(c(
      "date entered", "action", "phase",
      "hydro condition", "flood months"
    ))
  }

  output$mutab <- renderTable({
    display_cols
  })

  appcol <- data.frame(applicationdate = as.character(manreps_mu[, "applicationdate"]))
  appcol$applicationdate <- as.character(manreps_mu$applicationdate) # renderTable doesn't understand dates
  colnames(appcol) <- "application date"
  output$apptab <- renderTable({
    appcol
  })

  ## get a list of possible issues
  output$issues <- renderText({
    getManFlags(manrep_id, manflags_mu)
  })

  ## Get notes pertaining to managment actions
  output$ma_notes <- renderText({
    getMAnotes(manreps_mu1[manreps_mu1$treatmentid == manrep_id, ])
  })

  ## Get notes pertaining to compliance with guidance
  output$pe_notes <- renderText({
    getPEnotes(manreps_mu1[manreps_mu1$treatmentid == manrep_id, ])
  })

  ## Get notes about products and equipment
  output$gc_notes <- renderText({
    getGCnotes(manreps_mu1[manreps_mu1$treatmentid == manrep_id, ])
  })

  ## Get the checkbox and notes input
  return(list(
    selections = reactive({
      input$checkGroup
    }),
    notes = reactive({
      input$coordNote
    })
  ))
} # end manDisplayServer
