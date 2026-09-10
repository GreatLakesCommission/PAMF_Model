# This script contains functions that support the creation of new model runs
#
# Functions
#   * createRun           : Creates a new time-stamped directory in model-runs,
#                           containing a user input log and the cumulative
#                           outputs from the previous run
#   * priceCheck          : Finds management reports whose cost can't be
#                           calculated, due to missing constants
##

createRun <- function(cycleend, pulldate, prevrun, runname, costfile, enrollfile,
                      monitorfile, managefile, mndatefile) {
  # Creates a new time-stamped subdirectory of model-runs, writes a file
  # containing user input from the GUI (input current as of calling time), and
  # copies cumulative outpurs from previous run
  #
  # INPUT
  # cycleend    : Year ending the cycle that the current model run is to be
  #               based on
  # pulldate    : The date of the database pull that created enrollfile,
  #               monitorfile, managefile, mndatefile
  # prevrun     : Name of directory containing outputs to be updated from a
  #               previous model run
  # runname     : Label to append to the directory name of the new run
  # costfile    : Name of file containing cost constant information
  # enrollfile  : Name of file containing enrollment reports
  # monitorfile : Name of file containing monitoring reports
  # managefile  : Name of file containing management reports
  # mndatefile  : Name of file containing additional management dates
  #
  # OUTPUT
  # Writes a new directory and populates it with a log of user input. Returns
  # the path to the new directory.
  #
  # ASSUMPTIONS
  # The working directory is at the app/Rproj level, one level above the
  # model-runs directory
  ##

  ## Create model run directory
  # Create a directory to hold outputs from the model run. To ensure that the
  # directory name is unique, use a timestamp
  run_name <- trimws(runname)
  time_stamp <- strftime(Sys.time(), "%Y-%m-%d-%H.%M.%S")

  if (run_name != "") {
    run_path <- paste0(
      "./model-runs/", time_stamp, " ",
      run_name, "/"
    )
  } else {
    run_path <- paste0("./model-runs/", time_stamp, "/")
  }
  dir.create(run_path)

  ## Copy old cumulative files into the current run directory
  #  (unless cycleend is 2018, i.e. the first cycle)
  if (cycleend > 2018) {
    prev_path <- paste("./model-runs/", prevrun, sep = "/")

    ## Monitoring and Management Issues
    file.copy(
      paste(prev_path, "monitor_issues.csv", sep = "/"),
      paste(run_path, "monitor_issues-NOT-UPDATED.csv", sep = "/")
    )
    file.copy(
      paste(prev_path, "manage_issues.csv", sep = "/"),
      paste(run_path, "manage_issues-NOT-UPDATED.csv", sep = "/")
    )

    ## Repairs to management reports from previous cycles
    file.copy(
      paste(prev_path, "report-repairs.csv", sep = "/"),
      paste(run_path, "report-repairs-NOT-UPDATED.csv", sep = "/")
    )


    prev_files <- list.files(prev_path)

    ## Data packages
    datpak_file <- grep("datpak.", prev_files, fixed = TRUE, value = TRUE)
    file.copy(
      paste(prev_path, datpak_file, sep = "/"),
      paste(run_path, "datpak-NOT-UPDATED.csv", sep = "/")
    )

    ## Data package issues
    datpakissue_file <- grep("datpak_", prev_files, fixed = TRUE, value = TRUE)
    file.copy(
      paste(prev_path, datpakissue_file, sep = "/"),
      paste(run_path, "datpak_issues-NOT-UPDATED.csv", sep = "/")
    )

    ## Cost information
    cost_file <- grep("cost_estimates", prev_files, value = TRUE)
    file.copy(
      paste(prev_path, cost_file, sep = "/"),
      paste(run_path, "cost_estimates-NOT-UPDATED.csv", sep = "/")
    )

    ## Transition Matrices
    transitions_file <- grep("transition_matrices", prev_files, value = TRUE)
    file.copy(
      paste(prev_path, transitions_file, sep = "/"),
      paste(run_path, "transition_matrices-NOT-UPDATED.csv", sep = "/")
    )

    ## Partial controllability matrices
    partcontrol_file <- grep("partcontrol_matrices", prev_files, value = TRUE)
    file.copy(
      paste(prev_path, partcontrol_file, sep = "/"),
      paste(run_path, "partcontrol_matrices-NOT-UPDATED.csv", sep = "/")
    )

    ## Policies
    policy_file <- grep("policies", prev_files, value = TRUE)
    file.copy(
      paste(prev_path, policy_file, sep = "/"),
      paste(run_path, "policies-NOT-UPDATED.csv", sep = "/")
    )

    ## Guidance
    guidance_file <- grep("guidance.", prev_files, fixed = TRUE, value = TRUE)
    file.copy(
      paste(prev_path, guidance_file, sep = "/"),
      paste(run_path, "guidance-NOT-UPDATED.csv", sep = "/")
    )
  }

  ## Get the date of the previous run's database pull
  #  (to define beginning of reporting window for the cycle)
  #  and put it into the global environment for later use
  if (cycleend > 2018) {
    prev_log <- scan(paste0(prev_path, "/user-input-log.txt"),
      what = "character",
      quiet = TRUE
    )
    REPORTBEGIN <<- as.Date(prev_log[grep("end:", prev_log) + 1])
  } else {
    # it's the first model run. The earliest report I could find is from
    # 2017-08-07 but date reporting was a little bit iffy back then. let's call
    # it August 1st
    REPORTBEGIN <<- as.Date("2017-08-01")
  }


  ## Create user input log file
  #  Create a log file containing the user inputs that define this model run
  #  as well as the R and package versions that the run uses

  if (cycleend == 2018) {
    prevrun <- "None (2018 was the first run)"
  }

  cyclebegin <- cycleend - 1
  the_cycle <- paste(cyclebegin, cycleend, sep = "-")

  logtext <- paste("This model run is based on the following user inputs from the PAMF GUI:",
    "",
    paste("PAMF cycle: ", the_cycle),
    paste("Previous Model Run: ", prevrun),
    "",
    paste("Enrollment Reports: ", enrollfile),
    paste("Monitoring Reports: ", monitorfile),
    paste("Management Reports:", managefile),
    paste("Management Dates: ", mndatefile),
    "",
    "Report Submission Window",
    paste("begin:", REPORTBEGIN),
    paste("end:  ", REPORTEND),
    "",
    paste("Cost Constants: ", costfile),
    "",
    "Running with versions:",
    R.Version()$version.string,
    paste("Shiny", packageVersion("shiny")),
    paste("RMarkdown", packageVersion("rmarkdown")),
    paste("MDPToolbox", packageVersion("MDPtoolbox")),
    sep = "\n"
  )

  ## Write to log file
  file_path <- paste(run_path, "user-input-log.txt", sep = "/")
  sink(file_path)
  cat(logtext)
  sink()

  return(run_path)
} # end createRun

priceCheck <- function(prices, data) {
  # Find all management reports whose cost can't be calculated because the
  # necessary constants are missing
  #
  # INPUT
  # prices : data frame describing the prices of labor, fuel, etc
  # data   : management reports (data frame)
  #
  # OUTPUT
  # * vector of IDs of management reports whose cost can't be calculated due to
  #   missing constants
  #
  # ASSUMPTIONS
  # * data does not contain any rows where cost details were not provided
  # * If prices doesn't contain the expected cost types, warn but continue
  # prices contains the following columns:
  #   * type
  #   * name
  #   * cost_per_unit
  #   * herb_code
  # data contains the following columns:
  #   * glyphproduct
  #   * imazproduct
  #   * glyphplusproduct
  #   * glyphplusaddedname
  #   * studenthours
  #   * volunteerhours
  #   * seasonalhours
  #   * fullhours
  #   * glyphgasmin
  #   * glyphplusgasmin
  #   * imazgasmin
  #   * floodgasmin
  #   * cutgasmin
  #   * pregasmin
  #   * removegasmin
  #   * mechgasmin
  #   * glyphdieselmin
  #   * glyphplusdieselmin
  #   * imazdieselmin
  #   * flooddieselmin
  #   * cutdieselmin
  #   * predieselmin
  #   * removedieselmin
  #   * mechdieselmin
  #   * glyphjetmin
  #   * glyphplusjetmin
  #   * imazjetmin
  #   * glyphavgasmin
  #   * glyphplusavgasmin
  #   * imaxavgasmin
  #   * floodwattagemin
  ##

  # Verify that prices contains:
  # (a) the expected price types
  # (b) the expected sub-categories of labor, fuel, and electricity price
  # If the types and subcategories are different than expected, show a warning
  # and carry out the calculations as well as possible

  price_types <- c(
    "human", "glyphosate", "imazapyr", "added", "fuel", "electricity"
  )

  if (CYCLEEND >= 2022) {
    price_types <- c(price_types, "surfactant")
  }

  if (!setequal(prices$type, price_types)) {
    warning("priceCheck: Unexpected or missing price types in price input. May not identify all missing cost constants")
  }

  price_names <- c(
    "student", "volunteer", "seasonal", "full", "gas", "diesel",
    "jet", "avgas", "electricity"
  )
  if (!setequal(price_names, prices[prices$type %in%
    c("human", "fuel", "electricity"), "name"])) {
    warning("priceCheck: Unexpected or missing subcategories in labor and energy prices. May not identify all missing cost constants")
  }

  # Find all non-numeric price values
  numprices <- suppressWarnings(as.numeric(prices[, "cost_per_unit"]))
  badprice_rows <- which(is.na(numprices))
  badprices <- prices[badprice_rows, ]

  # create vector to hold IDs of reports whose cost can't be calculated due to
  # missing constants
  drop_these <- NULL

  # Find reports that rely on missing herbicide prices
  herb_bad <- badprices[badprices$type %in% c("glyphosate", "imazapyr", "added"), ]

  # glyphosate & glyphosate plus (glyphosate product)
  g_data <- data[data$hirecontractor != 1 & data$treatmethod %in%
    c(GLYPH$db, GLYPHPLUS$db), ]
  badcodes <- badprices[badprices$type == "glyphosate", "herb_code"]
  drop_these <- c(drop_these, g_data[
    g_data$glyphproduct %in% badcodes |
      g_data$glyphplusproduct %in% badcodes,
    "treatmentid"
  ])

  # imazapyr
  i_data <- data[data$hirecontractor != 1 & data$treatmethod == IMAZ$db, ]
  badcodes <- badprices[badprices$type == "imazapyr", "herb_code"]
  drop_these <- c(drop_these, i_data[i_data$imaz %in% badcodes, "treatmentid"])

  # glyphosate plus (added product)
  gplus_data <- data[data$hirecontractor != 1 & data$treatmethod == GLYPHPLUS$db, ]
  badcodes <- badprices[badprices$type == "added", "herb_code"]
  drop_these <- c(drop_these, gplus_data[gplus_data$glyphplusaddedname %in%
    badcodes, "treatmentid"])


  # Find reports that rely on missing labor, fuel, electricity prices
  badnames <- badprices[badprices$type %in%
    c("human", "fuel", "electricity"), "name"]

  # Missing labor prices
  if ("student" %in% badnames) {
    drop_these <- c(drop_these, data[!is.na(data$studenthours) &
      data$studenthours > 0, "treatmentid"])
  }
  if ("volunteer" %in% badnames) {
    drop_these <- c(drop_these, data[!is.na(data$volunteerhours) &
      data$volunteerhours > 0, "treatmentid"])
  }
  if ("seasonal" %in% badnames) {
    drop_these <- c(drop_these, data[!is.na(data$seasonalhours) &
      data$seasonalhours > 0, "treatmentid"])
  }
  if ("full" %in% badnames) {
    drop_these <- c(drop_these, data[
      !is.na(data$fullhours) & data$fullhours > 0,
      "treatmentid"
    ])
  }

  # Missing fuel, electricity prices
  # Only check the minimum amount used-- we know that the maximum is at least as
  # large
  if ("gas" %in% badnames) {
    drop_these <- c(
      drop_these,
      data[
        !is.na(data$glyphgasmin) & data$glyphgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$glyphplusgasmin) & data$glyphplusgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$imazgasmin) & data$imazgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$floodgasmin) & data$floodgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$cutgasmin) & data$cutgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$pregasmin) & data$pregasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$removegasmin) & data$removegasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$mechgasmin) & data$mechgasmin > 0,
        "treatmentid"
      ]
    )
  }
  if ("diesel" %in% badnames) {
    drop_these <- c(
      drop_these,
      data[
        !is.na(data$glyphdieselmin) & data$glyphdieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$glyphplusdieselmin) & data$glyphplusdieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$imazdieselmin) & data$imazdieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$flooddieselmin) & data$flooddieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$cutdieselmin) & data$cutdieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$predieselmin) & data$predieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$removedieselmin) & data$removedieselmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$mechdieselmin) & data$mechdieselmin > 0,
        "treatmentid"
      ]
    )
  }
  if ("jet" %in% badnames) {
    drop_these <- c(
      drop_these,
      data[
        !is.na(data$glyphjetmin) & data$glyphjetmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$glyphplusjetmin) & data$glyphpusjetmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$imazjetmin) & data$imazjetmin > 0,
        "treatmentid"
      ]
    )
  }
  if ("avgas" %in% badnames) {
    drop_these <- c(
      drop_these,
      data[
        !is.na(data$glyphavgasmin) & data$glyphavgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$glyphplusavgasmin) & data$glyphplusavgasmin > 0,
        "treatmentid"
      ],
      data[
        !is.na(data$imazavgasmin) & data$imazavgasmin > 0,
        "treatmentid"
      ]
    )
  }
  if ("electricity" %in% badnames) {
    drop_these <- c(drop_these, data[!is.na(data$floodwattagemin) &
      data$floodwattagemin > 0, "treatmentid"])
  }

  # return drop_these (IDs of all reports whose costs rely on missing constants)
  return(drop_these)
} # end priceCheck
