# 2020-12-11
#
# Functions that support midcycle data cleaning and guidance forecast
#
# Functions:
# * createForecast : Creates a new time-stamped subdirectory of midcycle-forecasts,
#                    and writes a file  containing user input from the GUI
# * isAllowedComb  : Determine whether each element of planned_combs is a member
#                    of allowed_combs
# * collapseMultipleActions : Given a set of treatment reports from within a
#                             single cycle, find cases where there is more than
#                             one report for a given MU during a given phase,
#                             and collapse them into a single report.
# * tidyStates : Take a row containing a munitid and the probabilities decribing
#                its likelihood of occupying each invasion state, and convert to
#                a set of rows conveying the same information
# * getMCFGs   : Applies muMCFG to every management unit in mcfg_data
# * muMCFG     : Calculate MCFG weights for a given MU, with respect to a given
#                transition matrix and policy set.
##

createForecast <- function(cycleend, prevrun, prevcycle, runname, midcyclefile, enrollfile,
                           managefile, mndatefile, run_name) {
  # Creates a new time-stamped subdirectory of midcycle-forecasts, and writes a
  # file  containing user input from the GUI (input current as of calling time)
  #
  # INPUT
  # cycleend     : Year ending the cycle during which the midcycle reports are
  #                submitted
  # prevrun      : Name of directory containing outputs of the model run whose
  #                transition matrices and policies will be used to forecast
  #                guidance
  # runname      : Label to append to the directory name of the new run
  # prevcycle    : Year ending the cycle over which the previous model run was
  #                conducted
  # midcyclefile : Name of file containing midcycle reports
  # enrollfile   : Name of file containing enrollment reports
  # managefile   : Name of file containing management reports
  # mndatefile   : Name of file containing additional management dates
  #
  # OUTPUT
  # Writes a new directory and populates it with a log of user input. Returns
  # the path to the new directory.
  #
  # ASSUMPTIONS
  # The working directory is at the app/Rproj level, one level above the
  # midcycle-forecasts directory
  ##

  ## Create forecast directory
  #  The directory name is the time stamp, to ensure that it's unique
  run_name <- trimws(runname)
  time_stamp <- strftime(Sys.time(), "%Y-%m-%d-%H.%M.%S")

  if (run_name != "") {
    forecast_path <- paste0(
      "./midcycle-forecasts/", time_stamp, " ",
      run_name, "/"
    )
  } else {
    forecast_path <- paste0("./midcycle-forecasts/", time_stamp, "/")
  }

  dir.create(forecast_path)


  ## Create user input log file
  #  Create a log file containing the user inputs that define this set of
  #  guidance forecasts

  cyclebegin <- cycleend - 1
  the_cycle <- paste(cyclebegin, cycleend, sep = "-")

  prevbegin <- prevcycle - 1
  the_prevcycle <- paste(prevcycle, prevbegin, sep = "-")

  logtext <- paste("This guidance forecast is based on the following user inputs from the PAMF GUI:",
    "",
    paste("PAMF cycle: ", the_cycle),
    paste("Previous Model Run: ", prevrun),
    paste("Previous Model Run Cycle: ", the_prevcycle),
    "",
    paste("Midcycle Reports: ", midcyclefile),
    paste("Enrollment Reports: ", enrollfile),
    # paste("Monitoring Reports: ", monitorfile),
    paste("Management Reports:", managefile),
    paste("Management Dates: ", mndatefile),
    "",
    "Running with versions:",
    R.Version()$version.string,
    paste("Shiny", packageVersion("shiny")),
    paste("RMarkdown", packageVersion("rmarkdown")),
    paste("MDPToolbox", packageVersion("mdptoolbox")),
    sep = "\n"
  )


  ## Write to log file
  file_path <- paste(forecast_path, "user-input-log.txt", sep = "/")
  sink(file_path)
  cat(logtext)
  sink()

  return(forecast_path)
} # end createForecast

isAllowedComb <- function(planned_combs, allowed_combs) {
  # Determine whether each element of planned_combs is a member of allowed_combs
  #
  # INPUT
  # planned_combs : vector of planned management combinations
  # allowed_combs : vector of allowed management combinations
  #
  # OUTPUT
  # A logical vector with TRUE elements where the corresponding element of
  # planned_combs belongs to allowed_combs; FALSE otherwise
  ##

  return(planned_combs %in% allowed_combs)
} # end isAllowedComb

collapseMultipleActions <- function(manage, other) {
  # Given a set of treatment reports from within a single cycle, find cases
  # where there is more than one report for a given MU during a given phase,
  # and collapse them into a single report. If the multiples describe different
  # management actions, replace treatmethod with a code indicating 'OTHER'
  #
  # INPUT
  # manage : a set of management reports (data frame)
  # other  : a value to write into the treatmethod column in the event that
  #          more than one action is reported for one MU in one phase (numeric)
  #
  # OUTPUT
  # A set of management reports for one phase, with one report for each MU
  # in the original report set (data frame)
  #
  # ASSUMPTIONS
  # * all reports in manage describe management actions taken during a single
  #   PAMF cycle
  # * all reports are submitted for the same phase
  # * manage has the following columns:
  #     munitid
  #     phase
  #     treatmethod
  ##

  # Verify that only one phase is represented
  if (length(unique(manage$phase)) != 1) {
    stop("collapseMultipleActions: All reports must describe actions in the
         same phase")
  }

  # Get munitids with more than one report
  mu_multiple <- manage$munitid[which(duplicated(manage$munitid))]

  # I'm going to bet that these cases are rare and that using a for loop
  # therefore won't slow processing down that much.
  replacement_rows <- NULL

  for (m in mu_multiple) {
    m_reports <- manage[manage$munitid == m, ]
    m_actions <- unique(m_reports$treatmethod)

    if (length(m_actions) == 1) {
      # one unique management action
      replacement_rows <- rbind(replacement_rows, m_reports[1, ])
    } else {
      # more than one unique managment action
      new_row <- m_reports[1, ]
      new_row$treatmethod <- other
      replacement_rows <- rbind(replacement_rows, new_row)
    }
  } # end for

  # Return new version of manage with all singleton reports
  manage_1row <- rbind(
    manage[!manage$munitid %in% mu_multiple, ],
    replacement_rows
  )
  return(manage_1row[order(manage_1row$munitid), ])
} # end collapse MultipleActions

tidyStates <- function(pr_row) {
  # Take a row containing a munitid and the probabilities decribing its
  # likelihood of occupying each invasion state, and convert to a set of rows
  # conveying the same information
  #
  # INPUT
  # pr_row : a row describing the probability that a MU is in any PAMF state
  #
  # OUTPUT
  # a data frame with the columns: munitid, state, pr_state
  #
  # ASSUMPTIONS
  # * pr_row has the columns:
  #     munitid
  # * The probability columns appear in order of increasing state, i.e. the
  #   probability of State 1 is furthest to the left; the probability of
  #   State 6 is furthest to the right
  ##

  n_states <- ncol(pr_row) - 1
  pr_cols <- which(colnames(pr_row) != "munitid")

  return(data.frame(
    munitid = rep(pr_row$munitid, n_states),
    state = 1:n_states,
    pr_state = as.numeric(pr_row[pr_cols])
  ))
} # end tidyStates

getMCFGs <- function(mcfg_data, transition_matrix, policies) {
  # Applies muMCFG to every management unit in mcfg_data
  #
  # INPUT
  # mcfg_data         : data needed for MCFG calculations sharing a planned
  #                     management combination (dataframe)
  # transition_matrix : transition probabilities for one management combination
  #                     (matrix)
  # policies          : optimal management combination for each state, per
  #                     management restriction (data frame)
  #
  # OUTPUT
  # A data frame containing MCFG information for all MUs in mcfg_data
  #
  # ASSUMPTIONS
  # * transition_matrix and policies each contain information from one model
  #   run (i.e. they are NOT cumulative)
  # * mcfg_data describes midcycle information during a single cycle
  # * All mcfg_data rows have the same value for mnt_planned
  # * mcfg data has the columns:
  #     munitid
  #     restr_id
  #     state
  #     pr_state
  # * transition_matrix is ordered such that state numbers correspond to their
  #   row/column positions. e.g. the transition probability for State3 -> State4
  #   is in position [3,4]
  # * policies has the columns:
  #     restr_id
  #     state
  #     mnt_comb
  #     optimal
  # * Policies are ordered by increasing state, within restr_id
  ##

  ## Get weighted MCFG combinations for each MU
  mcfg_by_mu <- split(mcfg_data, mcfg_data$munitid)
  mcfg_list <- lapply(mcfg_by_mu, muMCFG,
    transition_matrix = transition_matrix,
    policies = policies
  )
  names(mcfg_list) <- NULL # prevent row names from accumulating

  return(do.call(rbind, mcfg_list))
} # end getMCFGs

muMCFG <- function(mcfg_data, transition_matrix, policies) {
  # Calculate the MCFG weights for a given MU, with respect to a given
  # transition matrix and policy set.
  #
  # INPUT
  # mcfg_data         : data needed for MCFG calculation for one MU (dataframe)
  # transition_matrix : transition probabilities for one management combination
  #                     (matrix)
  # policies          : optimal management combination for each state, per
  #                     management restriction (data frame)
  #
  # OUTPUT
  # A data frame with three columns:
  #  munitid     : ID of the management unit given in mcfg_data
  #  mnt_comb    : ID of a managment combination that's optimal for one or more
  #                states & compatible with the MU's management restrictions
  #  mcfg_weight : The summed probabilities that the management combination
  #                would be optimal assuming no further learning
  #
  # ASSUMPTIONS
  # * transition_matrix and policies each contain information from one model
  #   run (i.e. they are NOT cumulative)
  # * mcfg_data describes midcycle information during a single cycle
  # * mcfg data has the columns:
  #     munitid
  #     restr_id
  #     state
  #     pr_state
  # * transition_matrix is ordered such that state numbers correspond to their
  #   row/column positions. e.g. the transition probability for State3 -> State4
  #   is in position [3,4]
  # * policies has the columns:
  #     restr_id
  #     state
  #     mnt_comb
  #     optimal
  # * Policies are ordered by increasing state, within restr_id
  ##

  # Verify that mcfg_data pertains only to one MU
  if (length(unique(mcfg_data$munitid)) > 1) {
    stop("muMCFG: data entered for more than one management unit")
  }

  ## Find the probability that the MU will be in each state at the end of the
  #  cycle.
  #
  #  First, multiply each row of the matrix by pr_state for its corresponding
  #  state in mcfg_data. Then sum the matrix columns.
  ##

  # Get the probability that the MU is currently in each state, sorted by state
  pr_state <- mcfg_data[order(mcfg_data$state), "pr_state"]

  end_state_probs <- colSums(pr_state * transition_matrix)
  forecast_states <- data.frame(
    munitid = mcfg_data$munitid,
    forecast_state = mcfg_data$state,
    pr_forecast = end_state_probs
  )


  ## Verify that the probability sums are close enough to 1
  #
  #  Rounding errors tend to perturb these values a little bit (on the order of
  #  1e-16 in the 2021 MCFG run). In this case, I'll ignore errors below a size
  #  threshold because:
  #    * This information is used to determine the weights of different MCFG
  #      combinations. The rounding error is unlikely to affect which combination
  #      has a greater weight
  #    * The information is only used in one cycle, i.e. rounding errors will
  #      not compound over time
  ##
  if (abs(sum(forecast_states$pr_forecast) - 1) > 1e-6) {
    warning(paste(
      "muMCFG: End-cycle state probabilities for MU",
      unique(mcfg_data$munitid), "do not sum to 1. Rounding error",
      sum(forecast_states$pr_forecast) - 1
    ))
  }


  ## Find the optimal management combination for each end-cycle state
  #  This depends on what management restrictions apply to the MU
  ##
  opt_comb <- policies[policies$restr_id == unique(mcfg_data$restr_id) &
    policies$optimal == 1, c(
    "mnt_comb", "db_tloc", "db_dorm",
    "db_grow"
  )]

  ## Calculate MCFG weights
  #
  #  This isn't a one-to-one mapping of pr(forecast state) to that state's
  #  optimal guidance because multiple states may have the same optimal
  #  combination
  ##
  forecast_states <- cbind(forecast_states, opt_comb)
  forecast_list <- split(forecast_states, forecast_states$mnt_comb)

  sumCombProbs <- function(forecast_frame) {
    n_rows <- length(unique(forecast_frame$mnt_comb))
    return(data.frame(
      munitid = rep(unique(forecast_frame$munitid), n_rows),
      mnt_comb = unique(forecast_frame$mnt_comb),
      db_tloc = unique(forecast_frame$db_tloc),
      db_dorm = unique(forecast_frame$db_dorm),
      db_grow = unique(forecast_frame$db_grow),
      mcfg_weight = sum(forecast_frame$pr_forecast)
    ))
  }

  weighted_combs <- lapply(forecast_list, sumCombProbs)
  names(weighted_combs) <- NULL # prevent row names from accumulating
  weighted_combs <- do.call(rbind, weighted_combs)

  # Sort by decreasing weight before returning
  return(weighted_combs[order(weighted_combs$mcfg_weight, decreasing = TRUE), ])
} # end muMCFG
