# 2020-11-09
#
# Functions defining the layout and interactive components for each screen
# of the PAMF model user interface
#
# Functions in this file:
#   * welcomePage      : Layout for the initial screen when the model is opened
#   * createNewRun     : Layout for the input fields to create a new model run
#   * chooseActiveRun  : Layout for the screen that resumes incomplete runs
#   * resolveIssues    : Layout for the checkbox screen
#   * modelRunning     : Progress screen indicating completed sections of run
#   * forecastGuidance : Layout for the input fields to create midcycle forecast
#                        guidance
#   * isActiveRun      : Determines whether the given directory name points to a
#                        directory containing an incomplete model run
#
##

welcomePage <- function() {
  ## Welcome page: Allows user to choose where to start

  imgUI <- tagList(
    titlePanel("Hello, PAMF Coordinator!",
      windowTitle = "PAMF Model"
    ),
    fluidRow(
      column(3),
      column(
        8,
        radioButtons("checkReports",
          label = h3("What would you like to do?"),
          choices = list(
            "Create a new model run" = 1,
            "Resolve data issues in an existing model run" = 2,
            "Generate mid-cycle forecast guidance" = 3
          ),
          selected = character(0)
        ),
        actionButton("leave_welcome", label = "Go!"),
        br()
      ),
      column(1)
    ),
    fluidRow(
      column(2),
      column(
        9,
        br(),
        img(
          src = "model-video-thumbnail.PNG", width = 156.1 * 4, height = 88.1 * 4,
          align = "center"
        )
      ),
      column(1)
    ),
    hr()
  ) # end taglist

  return(imgUI)
} # end welcomePage()

createNewRun <- function() {
  ## Input page for new model runs. Collects information from user:
  #    * Final year of the PAMF cycle they're interested in
  #    * Previous run to build off of
  #    * Which set of cost constants to use
  #    * Data tables: Enrollment, monitoring, management, management dates

  # show the current year as the default
  default_year <- as.numeric(format(Sys.time(), "%Y"))

  # create list of previous completed model runs by accessing the names of the
  # subdirectories of model-runs
  run_dirs <- list.files("./model-runs")

  # Only display complete runs. Ignore the documentation and extra subdirectories
  # (i.e. anything that doesn't start with a date stamp type format)
  is_active <- sapply(run_dirs, isActiveRun, USE.NAMES = FALSE)
  not_a_run <- setdiff(run_dirs, run_dirs[grep("....-..-..", run_dirs)])
  dont_display <- c(which(is_active), which(run_dirs %in% not_a_run))

  old_runs <- c("Select...", rev(run_dirs[-dont_display]))
  cost_files <- rev(list.files("./cost-constants",
    pattern = ".csv|.CSV|.Csv|.csV|.cSv|.cSV|.CsV|.CSv"
  ))

  revUI <- tagList(
    titlePanel("Create a New Model Run",
      windowTitle = "PAMF Model"
    ),
    hr(),
    fluidRow(
      column(
        6,
        h4("Load files from the appropriate database pull: "),
        em(helpText("located in the database-downloads folder")),
        fileInput("enroll", label = h5("Enrollment Reports"), accept = ".csv"),
        fileInput("monitor", label = h5("Monitoring Reports"), accept = ".csv"),
        fileInput("manage", label = h5("Management Reports"), accept = ".csv"),
        fileInput("mndates", label = h5("Management Dates"), accept = ".csv"),
        selectInput("costconst",
          label = h4("Select cost constants to use:"),
          choices = cost_files,
          selected = 1
        )
      ),
      column(
        6,
        numericInput("cycleend",
          label = h4("Final year of cycle you want to analyze:"),
          min = 2018, max = default_year, value = default_year
        ),
        em(helpText("e.g. enter 2020 for the 2019-2020 cycle")),
        selectInput("prevrun",
          label = h4("Select the previous model run:"),
          choices = old_runs,
          selected = 1
        ),
        em(helpText("Unless you're revisiting old calculations, this is last year's 'official' run")),
        br(),
        textInput("runname",
          label = h4("Add a label to the run directory (optional):"),
          placeholder = "e.g. official 2018"
        ),
        em(helpText("to help distinguish between runs later")),
        br(),
        verbatimTextOutput("review_messages"),
        tags$head(tags$style("#review_messages{color:red; font-size:12px; overflow-y:scroll; max-height: 700px}"))
      )
    ),
    br(),
    div(id = "slow_message"),
    column(4,
      offset = 7,
      actionButton("create_run", label = "Review Reports!")
    ),
    hr()
  )
  return(revUI)
} # end createNewRun

chooseActiveRun <- function() {
  ## Choose a model run that has been created but not completed

  # create list of active model runs by accessing the names of the
  # subdirectories of model-runs
  run_dirs <- list.files("./model-runs")

  is_active <- sapply(run_dirs, isActiveRun, USE.NAMES = FALSE)
  if (any(is_active) == TRUE) {
    active_runs <- c("Select...", rev(run_dirs[which(is_active)]))
    the_button <- actionButton("select_run", label = "Continue the Model Run!")
  } else {
    # no active runs
    active_runs <- c("There are no incomplete runs at this time!")
    the_button <- actionButton("gobackfromresume", label = "Go Back")
  }


  chooseActiveUI <- tagList(
    titlePanel("Resolve Data Issues in an Existing Model Run"),
    br(),
    fluidRow(
      column(3),
      column(
        6,
        selectInput("active_run",
          label = h4("Select an incomplete model run:"),
          choices = active_runs, selected = 1
        )
      ),
      column(3)
    ),
    br(),
    the_button,
    hr()
  )
  return(chooseActiveUI)
} # end chooseActiveRun

resolveIssues <- function() {
  # In order to display MU-specific information, this function depends on the
  # modules defined in modules.R
  source("./src/review-reports/checkbox-modules.R")

  resolveUI <- tagList(
    titlePanel("Screen Reports For Possible Issues"),

    # Display instructions to the user
    fluidRow(
      column(1, p("")),
      column(
        10,
        br(),
        strong("It takes a few moments to display the reports."),
        br(),
        p("To remove reports from consideration from certain parts of the model check the appropriate boxes. If no boxes are checked when you save your selections, the report will be included in all relevant parts of the model."),
        ("To save all selections for each MU, click the \'Save Selections\' button. Clicking \'Change Selections\' will discard your choices and notes, but they will still appear on the screen until you make changes or close this window. All MUs without saved changes (including those whose changes have been discarded and not re-saved) will reappear if you close this window and return later.")
      ),
      column(1, p(""))
    ),
    hr(),

    # Collect the user's name, in case any clarifying questions come up later
    # about a decision
    fluidRow(
      column(1, p("")),
      column(10, tagList(
        textInput("screener",
          label = "Please enter your name:",
          value = ""
        ),
        # don't change value="" without also changing the first conditional in the call to observeEvent in muDispServer
        em(helpText("For repeatability purposes, we keep track of who makes each decision"))
      ), align = "left"),
      column(1, p(""))
    ),
    hr(),

    # Display all reports with flags but no decision. Reports are shown by MU,
    # and grouped by monitoring vs. management
    div(id = "put_mu_modules_here"),
    hr(),

    ## Designate where to insert buttons that:
    #  (a) finalize the selections that have been saved and exit the checkbox UI
    #  (b) finalize all saved selections and move to the next step (auto QAQC)
    #
    # The buttons themselves are defined in the app server, within the
    # "PAMFsteps" event.
    ##
    fluidRow(
      column(2, p("")),
      column(8, div(id = "finalize_buttons")),
      column(2, p(""))
    )
  )
} # end resolveIssues

modelRunning <- function() {
  modrunUI <- tagList(
    titlePanel("The model is running!"),
    br(),
    fluidRow(
      column(6, br(), img(
        src = "learning.png", width = 680 * .7, height = 672 * .7,
        align = "left"
      )),
      column(
        6, br(), wellPanel(h5(strong("Constructing data packages... "))),
        br(),
        div(id = "matrix_update"),
        br(),
        div(id = "guidance_update")
      )
    ),
    fluidRow(column(1), column(10, br(), br(), div(id = "all_done"))), column(1),
    # put a 'quit' button here
    hr()
  )

  return(modrunUI)
} # end modelrunning

forecastGuidance <- function() {
  ## Input page for mid-cycle guidance forecasting. Collects information from
  #  user:
  #    * Data tables: Enrollment, monitoring, management, management dates,
  #      mid-cycle reports
  #    * Previous run to build off of (up-to-date transition matrices, policies)

  # If the current month is before November, display the current year as the
  # default. Otherwise, show the next year
  default_year <- as.numeric(format(Sys.time(), "%Y"))
  if (as.numeric(format(Sys.time(), "%m")) %in%
    c(11, 12)) {
    default_year <- default_year + 1
  }

  # create list of previous completed model runs by accessing the names of the
  # subdirectories of model-runs
  run_dirs <- list.files("./model-runs")

  # Only display complete runs. Ignore the documentation and extra subdirectories
  # (i.e. anything that doesn't start with a date stamp type format)
  is_active <- sapply(run_dirs, isActiveRun, USE.NAMES = FALSE)
  not_a_run <- setdiff(run_dirs, run_dirs[grep("....-..-..", run_dirs)])
  dont_display <- c(which(is_active), which(run_dirs %in% not_a_run))

  old_runs <- c("Select...", rev(run_dirs[-dont_display]))

  mcfgUI <- tagList(
    titlePanel("Create Mid-Cycle Forecast Guidance",
      windowTitle = "PAMF Model"
    ),
    hr(),
    fluidRow(
      column(
        6,
        h4("Load files from the mid-cycle database pull: "),
        em(helpText("located in the database-downloads folder")),
        fileInput("enroll_fg", label = h5("Enrollment Reports"), accept = ".csv"),
        fileInput("manage_fg", label = h5("Management Reports"), accept = ".csv"),
        fileInput("mndates_fg", label = h5("Management Dates"), accept = ".csv"),
        fileInput("midcycle_fg", label = h5("Mid-Cycle Reports"), accept = ".csv")
      ),
      column(
        6,
        numericInput("cycleend_fg",
          label = h4("Year of guidance release:"),
          min = 2018, max = default_year, value = default_year
        ),
        em(helpText("e.g. enter 2020 for the 2019-2020 cycle")),
        selectInput("prevrun_fg",
          label = h4("Select the previous model run:"),
          choices = old_runs,
          selected = 1
        ),
        em(helpText("Forecasts will be based on the data packages, transition matrices, and optimal guidance generated during this run")),
        br(),
        textInput("runname_mcfg",
          label = h4("Add a label to the run directory (optional):"),
          placeholder = "e.g. official 2021"
        ),
        em(helpText("to help distinguish between runs later")),
        br(),
        verbatimTextOutput("review_messages_fg"),
        tags$head(tags$style("#review_messages_fg{color:red; font-size:12px; overflow-y:scroll; max-height: 700px}"))
      )
    ),
    div(id = "slow_message_fg"),
    column(4, offset = 7, actionButton("get_forecast",
      label = "Forecast Guidance!"
    )),
    div(id = "mcfg_done"),
    # put a 'quit' button here
    hr()
  )
  return(mcfgUI)
} # end forecastGuidance

isActiveRun <- function(dir_name) {
  # Determines whether the given directory name points to a directory containing
  # an incomplete model run
  #
  # INPUT
  # dir_name : name of a subdirectory of model_runs
  #
  #
  # ASSUMPTIONS
  ##

  path <- paste0("./model-runs/", dir_name)
  files <- list.files(path)

  ## The run is active/incomplete if either:
  #  * one or more files is labeled in path "NOT-UPDATED" (2018-2019+ cycles)
  #  * the directory contains a user input log but no guidance (2017-2018 cycle,
  #    various other files and folders)
  if ((length(grep("NOT-UPDATED", files)) > 0 |
    (length(grep("guidance", files)) == 0 & length(grep("user-input-log", files)) > 0))) {
    return(TRUE)
  } else {
    return(FALSE)
  }
} # end isActiveRun
