# This script re-loads all relevant data from a model run that has not yet been
# completed
#
# Sourced by: app.R
#
# DEPENDENCIES
# * Global Constants
#    RUNPATH : path to directory containing outputs of the current model run
# * Variables
#    input : user input values from GUI
#
# ASSUMPTIONS
# * files in RUNPATH's directory have not been modified since the run was
#   created
##

# ==============================================================================
# Load the data set that was used to create the model run, along with
#  global constants for the session etc
# ==============================================================================

# Make a static copy of the run directory's name and push to global scope
# for later use
the_run <- input$active_run
RUNPATH <<- paste0("./model-runs/", the_run, "/")
# lockBinding("RUNPATH", .GlobalEnv)


# ==============================================================================
# Access the log that recorded the user's original selections
#  Extract CYCLEEND, the names of the data files, year of data pull etc
# ==============================================================================
run_log <- scan(paste0(RUNPATH, "/user-input-log.txt"),
  what = "character",
  quiet = TRUE
)

# Get CYCLEEND
cycle_years <- run_log[grep("cycle:", run_log) + 1]
CYCLEEND <<- as.numeric(substr(
  cycle_years, nchar(cycle_years) - 3,
  nchar(cycle_years)
))
CYCLE <<- c(CYCLEEND - 1, CYCLEEND)


# Get the names of the data files and the year of the data pull where each can
# be found
data_files <- grep(".csv", run_log, ignore.case = TRUE, value = TRUE)

enroll_name <- grep("enroll", data_files, value = TRUE)
monitor_name <- grep("monitor", data_files, value = TRUE)
manage_name <- grep("manage-", data_files, value = TRUE)
mndate_name <- grep("managedate", data_files, value = TRUE)

enroll_year <- regmatches(enroll_name, regexpr("2[[:digit:]]{3}", enroll_name))
monitor_year <- regmatches(monitor_name, regexpr("2[[:digit:]]{3}", monitor_name))
manage_year <- regmatches(manage_name, regexpr("2[[:digit:]]{3}", manage_name))
mndate_year <- regmatches(mndate_name, regexpr("2[[:digit:]]{3}", mndate_name))


# Read and format the data files
enroll_raw <- read.csv(paste0(
  "./database-downloads/", enroll_year, "/",
  enroll_name
))
monitor_raw <- read.csv(paste0(
  "./database-downloads/", monitor_year, "/",
  monitor_name
))
manage_raw <- read.csv(paste0(
  "./database-downloads/", manage_year, "/",
  manage_name
))
mndates_raw <- read.csv(paste0(
  "./database-downloads/", mndate_year, "/",
  mndate_name
))

# Get the dates defining the reporting window
REPORTBEGIN <<- as.Date(run_log[grep("begin:", run_log) + 1])
REPORTEND <<- as.Date(run_log[grep("end:", run_log) + 1])

# Convert data to expected format and force into global environment
enroll_data <- formatEnroll(enroll_raw, CYCLEEND)
mon_data <- formatMonitor(monitor_raw, CYCLEEND)
man_data <- formatManage(manage_raw, mndates_raw, CYCLEEND)

PAMFDATA <<- list(
  enroll = enroll_data, monitor = mon_data,
  manage = man_data
)
# lockBinding("PAMFDATA", .GlobalEnv)

# Get the cost constants file name & read the file
const_file <- run_log[grep("cost_constants", run_log)]
COST_CONSTS <<- read.csv(paste0("./cost-constants/", const_file))


# ==============================================================================
# clean up temporary variables
# ==============================================================================
# unnecessary: the event handler ends right after this script is sourced
# and all local vars will be destroyed then
