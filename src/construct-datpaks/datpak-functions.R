# Functions supporting construct-datpaks.R, assemble-datpaks.R, and
# find-datpak-issues.R
#
# Functions
# * getState        : Returns the invasion state(s) described by a (set of)
#                     monitoring report(s)
# * getDensProbs    : Returns the probability that the MU described by a
#                     monitoring report is in a high/low density state
# * hasAllPhases    : Returns TRUE if a set of management reports contains at
#                     least one report from each phase
# * getCycle        : For a single MU, returns all management reports within a
#                     cycle defined by phase/year information
# * getCycleByDate  : For a single MU, returns all management reports within a
#                     cycle defined by monitoring and/or reporting cutoff dates
# * getNotCycle     : Get management reports from the years cycleend, cycleend-1
#                     that DO NOT occur within the current PAMF cycle
#                     (based on getCycleByDate; used for testing)
# * getPhaseActions : Return all unique management actions carried out during a
#                     phase
# * getMntComb      : Returns the management combination in a data package
# * swapPLB         : Substitute between PRECLEAR, MECHREMOVE/MECHLEAVE actions
#                     where the substitution may convert the reported
#                     combination into a PAMF combination
# * getNotIntendedMU: Return munitid of every data package whose participant
#                     indicated that they never intended to follow guidance
# * getAAMP_MU: Return munitid of every data package whose participant
#                     indicated that they never intended to follow guidance
#                     because they were an Active Adaptive Management (AAMP) 
#                     participant 
# * pasteNoNA       : a paste function that ignores NA values
# * updatePhaseIssues : a function that updates the out_of_phase and
#                       unresolved_phase columns in manage_issues.csv
#
#
# Deprecated Functions
# * repairReportOOP : Reassigns out-of-phase management reports to the correct
#                     phase and back-fills the vacated phase with a Rest report,
#                     if necessary
# * repairReportGAM : Assigns growing-phase reports with post-monitoring actions
#                     to the translocating phase and back-fills the growing
#                     phase with a Rest report, if necessary
# * repairReportTBM : Assigns translocating-phase reports with pre-monitoring
#                     actions to the growing
#                   : phase and back-fills the translocating phase with a Rest
#                     report, if necessary
# * splitByMonitorDate : Separates rows of a management report by whether their
#                        applicationdate is before or after monitoring
##

getState <- function(monitor, dens_threshold) {
  # Given a set of monitoring reports, return the state describing the severity
  # of Phragmites invasion in each one.
  #
  # INPUT
  # monitor        : A set of monitoring reports (data frame)
  # dens_threshold : Maximum number of stems in the low density category (numeric)
  #
  # OUTPUT
  # A data frame containing the columns id, munitid, state
  #
  # ASSUMPTIONS
  # * The state structure is as follows:
  #   State 1: 0-10% establishment, low density
  #   State 2: 0-10% establishment, high density
  #   State 3: 11-50% establishment, low density
  #   State 4: 11-50% establishment, high density
  #   State 5: 51-100% establishment, low density
  #   State 6: 51-100% establishment, high density
  # * NOTE: there are 3 establishment categories and 2 density categories
  #         Stem density is based on the mean of a report's stem counts
  # * monitor has the following columns:
  #     monitorid
  #     munitid
  #     establishment (0: 0-10%, 1: 11-50%, 2: 51-100%)
  #     q1stemcount
  #     q2stemcount
  #     q3stemcount
  #     q4stemcount
  #     q5stemcount

  ## Create empty column to hold state information
  state <- rep(NA, nrow(monitor))

  ## Get mean of existing stem counts in each report
  dens <- rowMeans(monitor[, c(
    "q1stemcount", "q2stemcount", "q3stemcount",
    "q4stemcount", "q5stemcount"
  )], na.rm = TRUE)

  monitor <- cbind(monitor, dens, state)

  ## Populate the 'state' column
  monitor[!is.nan(monitor$dens) & monitor$establishment == 0 &
    monitor$dens <= dens_threshold, "state"] <- 1
  monitor[!is.nan(monitor$dens) & monitor$establishment == 0 &
    monitor$dens > dens_threshold, "state"] <- 2
  monitor[!is.nan(monitor$dens) & monitor$establishment == 1 &
    monitor$dens <= dens_threshold, "state"] <- 3
  monitor[!is.nan(monitor$dens) & monitor$establishment == 1 &
    monitor$dens > dens_threshold, "state"] <- 4
  monitor[!is.nan(monitor$dens) & monitor$establishment == 2 &
    monitor$dens <= dens_threshold, "state"] <- 5
  monitor[!is.nan(monitor$dens) & monitor$establishment == 2 &
    monitor$dens > dens_threshold, "state"] <- 6

  return(monitor[c("monitorid", "munitid", "state")])
} # end getState

getDensProbs <- function(monitor) {
  # Given a monitoring report, return the probability that it describes a low or
  # high density state
  #
  # INPUT
  # monitor : one or more monitoring reports
  #
  # OUTPUT
  # a dataframe containing the report's munitid and density probabilities
  #
  # ASSUMPTIONS
  #  * monitor has the columns:
  #    munitid
  #    q1stemcount
  #    q2stemcount
  #    q3stemcount
  #    q4stemcount
  #    q5stemcount
  #  * LODENS_MAX is a global constant
  ##

  mu_counts <- monitor[, c(
    "q1stemcount", "q2stemcount", "q3stemcount",
    "q4stemcount", "q5stemcount"
  )]
  non_na_counts <- mu_counts[which(!is.na(mu_counts))] # ignore NAs

  prob_hi <- sum(non_na_counts > LODENS_MAX) / length(non_na_counts)
  prob_lo <- 1 - prob_hi

  return(data.frame(munitid = monitor$munitid, prob_lo = prob_lo, prob_hi = prob_hi))
} # end getDensProbs

hasAllPhases <- function(reports) {
  # Given a set of management reports, determine whether all PAMF phases are
  # represented
  #
  # INPUT
  # reports : one or more management reports
  #
  # OUTPUT
  # TRUE if all phases are represented in reports$model_phase, FALSE otherwise
  #
  # ASSUMPTIONS
  # * reports has a 'model_phase' column
  # * TRANSLOCATING, DORMANT, GROWING are global constants
  ##

  phases <- c(TRANSLOCATING$code, DORMANT$code, GROWING$code)
  report_phases <- reports$model_phase

  if (setequal(phases, report_phases)) {
    return(TRUE)
  } else {
    return(FALSE)
  }
} # end hasAllPhases

getCycle <- function(munitid, manage, cycleend, report_begin, report_end, out_cols,
                     phase_col = "model_phase", phase_defs = NULL,
                     restflood_defs = NULL) {
  # Given a 2-year window of management records for a single MU, return all
  # management reports within the cycle defined by the year and phase of the
  # report (reports with application dates) or the entry date and reporting
  # window (reports without application dates)
  #
  # INPUT
  # munitid      : ID of a management unit (numeric)
  # manage       : Management reports from a 2-year window (data frame)
  # cycleend     : The second/final year of the current cycle (numeric)
  # report_begin : The first day of the reporting window for the cycle (date)
  # report_end   : The last day of the reporting window for the cycle (date)
  # out_cols     : Names of columns to display (character)
  # phase_col    : Name of column containing phase information (character)
  #                may be either "model_phase" or any other string
  # phase_defs   : A named list of phases and how they appear in manage.
  #                Names must be "t", "d", and "g". If phase_defs is NULL,
  #                phase definitions sourced from global-constants.R will be used
  # restflood_defs : A named list describing how REST, FLOOD actions appear in
  #                  manage. names must be "r" and "f". If restflood_defs is
  #                  NULL, definitions sourced from global-constants.R will be
  #                  used
  #
  # OUTPUT
  # A data frame containing the management records for actions taking place
  # within the cycle ending in the year of cycleend. (numeric vector)
  #
  # ASSUMPTIONS
  #   * manage has already been trimmed to contain only the two years
  #     containing the cycle of interest
  #   * manage has the columns
  #       model_phase OR phase
  #       manage_year
  #       managementdate OR dateentered
  #     in addition to any columns listed in out_cols
  #   * if phase_col is NOT "model_phase", the cycle will be assembled based on
  #     the "phase" column
  #   * If phase_defs is NULL, phase definitions are located in global constants
  #     TRANSLOCATING$code, DORMANT$code, GROWING$code
  #   * if restflood_defs is NULL, definitions of those actions are located in
  #     REST$db, FLOOD$db
  ##

  cyclebegin <- cycleend - 1

  ## Get phase definitions
  if (is.null(phase_defs)) {
    # Use pre-defined global constants
    tloc <- TRANSLOCATING$code
    dorm <- DORMANT$code
    grow <- GROWING$code
  } else {
    if (length(setdiff(names(phase_defs), c("t", "d", "g")))) {
      stop("getCycle: Phase definitions not recognized")
    }
    tloc <- phase_defs$t
    dorm <- phase_defs$d
    grow <- phase_defs$g
  }

  ## Get REST, FLOOD definitions
  if (is.null(restflood_defs)) {
    rest <- REST$db
    flood <- FLOOD$db
  } else {
    if (length(setdiff(names(restflood_defs), c("r", "f")))) {
      stop("getCycle: Rest/Flood definitions not recognized")
    }
    rest <- restflood_defs$r
    rest <- restflood_defs$f
  }

  ## Get reports associated with the MU associated with munitid
  mu_manage <- manage[manage$munitid == munitid, ]

  ## Choose which date information to use (REST, FLOOD reports only)
  if ("dateentered" %in% colnames(mu_manage)) {
    use_this_date <- mu_manage$dateentered
  } else {
    use_this_date <- mu_manage$managementdate
  }
  mu_manage <- cbind(mu_manage, use_this_date)

  ## Due to the PAMF cycle's structure, management reports belong to the cycle
  #  if they meet one of the following criteria:
  #    * translocating action in cyclebegin
  #    * translocating REST or FLOOD within the reporting window for the cycle
  #      (participants have until August deadline to submit reports for cycle)
  #    * dormant action after REPORTBEGIN in either year
  #    * growing action in cycleend, before REPORTEND
  ##
  if (phase_col == "model_phase") {
    # Find phase information in model_phase column

    # split t reports into those that have applications and rest/flood
    t_apps <- mu_manage[!mu_manage$treatmethod %in% c(rest, flood) &
      mu_manage$model_phase == tloc &
      mu_manage$manage_year == cyclebegin, out_cols]
    t_rf <- mu_manage[mu_manage$treatmethod %in% c(rest, flood) &
      mu_manage$use_this_date >= report_begin &
      mu_manage$use_this_date < report_end, out_cols]
    t_reports <- rbind(t_apps, t_rf)

    d_reports <- mu_manage[mu_manage$model_phase == dorm &
      mu_manage$use_this_date >= report_begin, out_cols]

    g_reports <- mu_manage[mu_manage$model_phase == grow &
      mu_manage$manage_year == cycleend &
      mu_manage$use_this_date <= report_end, out_cols]
  } else {
    # Find phase information in phase column
    t_apps <- mu_manage[!mu_manage$treatmethod %in% c(rest, flood) &
      mu_manage$phase == tloc &
      mu_manage$manage_year == cyclebegin, out_cols]
    t_rf <- mu_manage[mu_manage$treatmethod %in% c(rest, flood) &
      mu_manage$use_this_date >= report_begin &
      mu_manage$use_this_date < report_end, out_cols]
    t_reports <- rbind(t_apps, t_rf)

    d_reports <- mu_manage[mu_manage$phase == dorm, out_cols]
    g_reports <- mu_manage[mu_manage$phase == grow &
      mu_$manage_year == cycleend &
      mu_manage$use_this_date <= report_end, out_cols]
  }

  return(rbind(t_reports, d_reports, g_reports))
} # end getCycle


getCycleByDate <- function(munitid, monitor, manage, cycleend, report_begin, report_end,
                           extra_cols = NULL) {
  # Given a management unit ID, and a 2-year window of its management and
  # monitoring records, returns all management reports within the cycle.
  #
  # INPUT
  # munitid : ID of management unit (numeric)
  # monitor : 2-year window of monitoring records for the MU (data frame)
  # manage  : 2-year window of merged (see below) management records for the MU
  #           (data frame)
  # cycleend     : The second/final year of the current cycle (numeric)
  # report_begin : The first day of the reporting window for the cycle (date)
  # report_end   : The last day of the reporting window for the cycle (date)
  # extra_cols   : Names of additional columns to display (character)
  #
  # OUTPUT
  # A data frame containing the management records for actions taking place
  # within the cycle defined by the monitoring dates listed in monitor
  # (numeric vector)
  #
  # ASSUMPTIONS
  #   * manage, monitor have already been trimmed to contain only the two years
  #     containing the cycle of interest
  #   * monitor has the columns:
  #       munitid
  #       monitoringdate
  #       monitor_year
  #   * manage has the columns
  #       applicationid
  #       treatmentid
  #       munitid
  #       model_phase OR phase
  #       treatmethod
  #       applicationdate
  #       managementdate OR dateentered
  #   * Non-NA values in the applicationdate, monitoringdate columns are
  #     'Date' data type
  #   * Any TRANSLOCATING/DORMANT reports without applicationdates that were
  #     submitted after cycleend monitoring but before the end of the reporting
  #     window are intended to belong to the next cycle
  ##

  ## Get data associated with munitid
  mon_mu <- monitor[monitor$munitid == munitid, ]
  man_mu <- manage[manage$munitid == munitid, ]

  ## Proceed based on whether the cycle is delimited by monitoring dates, the
  #  cycle threshold, or both
  mon_years <- unique(mon_mu$monitor_year)

  if (length(mon_years) == 2) { # The MU has monitoring reports for both years

    cycle_begin <- mon_mu[mon_mu$monitor_year == min(mon_years), "monitoringdate"]
    cycle_end <- mon_mu[mon_mu$monitor_year == max(mon_years), "monitoringdate"]
  } else {
    if (length(mon_years) == 0) { # MU has no monitoring report for either year

      cycle_begin <- report_begin
      cycle_end <- report_end
    } else {
      if (mon_years == cycleend - 1) { # MU has a monitoring report for cycle_begin only

        cycle_begin <- mon_mu[mon_mu$monitor_year == mon_years, "monitoringdate"]
        cycle_end <- report_end
      } else { # MU has a monitoring report for cycle_end only

        cycle_begin <- report_begin
        cycle_end <- mon_mu[mon_mu$monitor_year == mon_years, "monitoringdate"]
      }
    }
  }

  ## Define the columns needed to construct managment combinations--
  #  no need to return any others.
  #  Columns returned depends upon which columns appear in man_mu:
  #    * dateentered may not be present : earlier data pulls lack this column
  #    * model_phase may not be present : if the management reports in man_mu
  #                                       have not gone through phase-date
  #                                       agreement script
  cols <- colnames(man_mu)
  if ("dateentered" %in% cols) {
    if ("model_phase" %in% cols) {
      return_cols <- union(
        c(
          "applicationid", "treatmentid", "munitid",
          "model_phase", "treatmethod", "applicationdate",
          "dateentered", "managementdate"
        ),
        extra_cols
      )
    } else {
      return_cols <- union(
        c(
          "applicationid", "treatmentid", "munitid", "phase",
          "treatmethod", "applicationdate", "dateentered",
          "managementdate"
        ),
        extra_cols
      )
    }
  } else {
    if ("model_phase" %in% cols) {
      return_cols <- union(
        c(
          "applicationid", "treatmentid", "munitid",
          "model_phase", "treatmethod", "applicationdate",
          "managementdate"
        ),
        extra_cols
      )
    } else {
      return_cols <- union(
        c(
          "applicationid", "treatmentid", "munitid", "phase",
          "treatmethod", "applicationdate", "managementdate"
        ),
        extra_cols
      )
    }
  }

  # Get reports where management occurred between cycle_begin and cycle_end
  # Reports with application dates:
  man_ad <- man_mu[
    !is.na(man_mu$applicationdate) &
      (man_mu$applicationdate >= cycle_begin &
        man_mu$applicationdate < cycle_end),
    return_cols
  ]

  # Reports without application dates:
  if ("dateentered" %in% colnames(man_mu)) {
    man_de <- man_mu[
      is.na(man_mu$applicationdate) &
        (man_mu$dateentered >= report_begin &
          man_mu$dateentered < report_end),
      return_cols
    ]
    man_md <- NULL
  } else {
    man_de <- NULL
    man_md <- man_mu[
      is.na(man_mu$applicationdate) &
        (man_mu$managementdate >= report_begin &
          man_mu$managementdate < report_end),
      return_cols
    ]
  }

  return(rbind(man_ad, man_md, man_de))
} # end getCycleByDate

getNotCycle <- function(munitid, monitor, manage) {
  # The opposite of getCycleByDate. For testing purposes.
  #
  # INPUT
  # munitid : ID of management unit (numeric)
  # monitor : 2-year window of monitoring records for the MU (data frame)
  # manage  : 2-year window of merged (see below) management records for the MU
  #           (data frame)
  #
  # OUTPUT
  # A data frame containing the management records for actions taking place
  # within the cycle defined by the monitoring dates listed in monitor
  # (numeric vector)
  #
  # ASSUMPTIONS
  #   * manage, monitor have already been trimmed to contain only the two years
  #     containing the cycle of interest
  #     necessary columns: munitid, monitoringdate, monitor_year
  #   * MUs that are missing monitoring reports for either year in this cycle
  #     are already trimmed out of monitor, manage
  #   * Non-NA values in the applicationdate, monitoringdate columns are
  #     'Date' data type
  #   * managementdate is a good approximation of the timing of the management
  #     (in)action when no applicationdate exists
  #   * manage contains monitoring dates from the same year as manage_year
  #     Necessary columns: munitid, phase, applicationdate
  #   * Each MU has a maximum of one monitoring report per year
  #

  # Get dates to begin, end the cycle for the MU
  mon_recs <- monitor[monitor$munitid == munitid, ]
  mon_years <- unique(mon_recs$monitor_year)

  # The "applicationdate" column is more precise than "managementdate", but not
  # all records have an applicationdate value (e.g. those with rest,
  # natural flood). Split the munitid records of manage by whether there's an
  # application date
  man_ad <- manage[manage$munitid == munitid & !is.na(manage$applicationdate), ] # applicationdate
  man_md <- manage[manage$munitid == munitid & is.na(manage$applicationdate), ] # managementdate


  print(paste("cycle start:", cycle_start))
  print(paste("cycle end:", cycle_end))
  print(rbind(
    man_ad[man_ad$applicationdate < cycle_start |
      man_ad$applicationdate >= cycle_end, ],
    man_md[man_md$managementdate < cycle_start |
      man_md$managementdate > cycle_end, ]
  ))
  # Return records where applicationdate (where it exists) or, alternately, managementdate
  # is between cycle_start and cycle_end
  return(rbind(
    man_ad[man_ad$applicationdate < cycle_start |
      man_ad$applicationdate >= cycle_end, ],
    man_md[man_md$managementdate < cycle_start |
      man_md$managementdate > cycle_end, ]
  ))
} # end getNotCycle

getPhaseActions <- function(reports) {
  # Given a set of management reports from a single MU & phase, get the
  # management actions that were carried out during the phase
  #
  # INPUT
  # reports : a set of management reports from a single MU in a single phase
  #
  # OUTPUT
  # A dataframe containing the phase ID and the management combination
  #
  # ASSUMPTIONS
  # * All possible PAMF actions are defined as global constants, where each
  #   constant is a named list containing codes that refer to the action in the
  #   database (db) and the model (model)
  # * The order of management actions doesn't matter. We only care that they're
  #   from the same phase.
  # * Reports contains a column named 'model_phase'
  ##

  ## Before finding the management combination:
  #   * Ignore repeated actions (we consider multiple reports of the same action
  #     in one phase to be equivalent to one report)
  #   * Get rid of any rests that are accompanied by another action (a
  #     participant can't have done nothing and something in the same phase)
  actions <- unique(reports$treatmethod)
  if (length(actions) > 1) {
    # more than one action was applied. If REST is in here, so is something else
    actions <- setdiff(actions, REST$db)
  }

  ## build the combination of actions within the phase
  phase_combination <- NULL
  if (GLYPH$db %in% actions) {
    phase_combination <- paste0(phase_combination, GLYPH$model)
  }
  if (IMAZ$db %in% actions) {
    phase_combination <- paste0(phase_combination, IMAZ$model)
  }
  if (GLYPHPLUS$db %in% actions) {
    phase_combination <- paste0(phase_combination, GLYPHPLUS$model)
  }
  if (REST$db %in% actions) {
    phase_combination <- paste0(phase_combination, REST$model)
  }
  if (CUT$db %in% actions) {
    phase_combination <- paste0(phase_combination, CUT$model)
  }
  if (SPADING$db %in% actions) {
    phase_combination <- paste0(phase_combination, SPADING$model)
  }
  if (PRECLEAR$db %in% actions) {
    phase_combination <- paste0(phase_combination, PRECLEAR$model)
  }
  if (MECHREMOVE$db %in% actions) {
    phase_combination <- paste0(phase_combination, MECHREMOVE$model)
  }
  if (FLOOD$db %in% actions) {
    phase_combination <- paste0(phase_combination, FLOOD$model)
  }
  if (MECHLEAVE$db %in% actions) {
    phase_combination <- paste0(phase_combination, MECHLEAVE$model)
  }
  if (OTHER$db %in% actions) {
    phase_combination <- paste0(phase_combination, OTHER$model)
  }

  return(data.frame(
    phase = unique(reports$model_phase),
    actions = phase_combination, stringsAsFactors = FALSE
  ))
} # end getPhaseActions


getMntComb <- function(reports) {
  # From a dataframe of management reports that were submitted for a single MU
  # in a single cycle, extract the management combination
  #
  # INPUT
  # reports : a set of management reports from a single MU across one cycle
  #
  # OUTPUT
  # A data frame containing the actions reported during each phase
  #
  # ASSUMPTIONS
  # * reports has the columns:
  #     model_phase
  #     treatmethod
  # * The following global constants are defined:
  #     TRANSLOCATING, DORMANT, GROWING : definitions of the biological phases
  ##

  ## Split the reports by phase
  reports <- reports[order(reports$model_phase), ]
  report_list <- split(reports, reports$model_phase)

  ## Get the set of unique actions in each phase
  phase_actions <- lapply(report_list, getPhaseActions)
  phase_actions <- do.call(rbind, phase_actions)

  ## Fill in NA actions for missing phases
  all_phases <- c(TRANSLOCATING$code, DORMANT$code, GROWING$code)
  na_rows <- data.frame(
    phase = setdiff(all_phases, phase_actions$phase),
    actions = rep(NA, length(setdiff(
      all_phases,
      phase_actions$phase
    )))
  )
  phase_actions <- rbind(phase_actions, na_rows)

  # Return results as a dataframe
  return(data.frame(
    t_actions = phase_actions[phase_actions$phase ==
      TRANSLOCATING$code, "actions"],
    d_actions = phase_actions[phase_actions$phase ==
      DORMANT$code, "actions"],
    g_actions = phase_actions[phase_actions$phase ==
      GROWING$code, "actions"],
    stringsAsFactors = FALSE
  ))
} # end getMntComb

swapPLB <- function(reports, code = "character") {
  # Given a set of management actions for a single MU in a single cycle, find
  # situations where a substitution between P, L/B may turn a non-PAMF
  # combination into a PAMF combination
  # where P is PRECLEAR, L is MECHLEAVE, and B is MECHREMOVE
  #
  # INPUT
  # reports : Management reports for one MU in one cycle (dataframe)
  # code    : Type of code to use for output. Choices are:
  #            "character" : character encoding of management action (default)
  #            "numeric"   : numeric encoding of management action
  #
  # OUTPUT
  # A dormant action that may convert the reported combination to a PAMF
  # combination, if applicable
  #
  # ASSUMPTIONS
  # * reports has the columns:
  #    model_phase
  #    treatmethod
  #    pretechnique (allowed values: 0,1,2)
  #    preremove (allowed values: 0,1)
  # * reports$treatmethod has the numeric encoding
  # * reports does not contain any rows where percentcover is less than 76%
  #   (i.e. percentcover < 3)
  # * The following actions are defined as global constants (named list):
  #   PRECLEAR, MECHREMOVE, MECHLEAVE
  # * TRANSLOCATING, DORMANT, and GROWING are global constants
  # * getPhaseActions() is sourced
  ##

  dorm_act <- getPhaseActions(reports[reports$model_phase == DORMANT$code, ])$actions
  grow_act <- getPhaseActions(reports[reports$model_phase == GROWING$code, ])$actions

  if (code == "character") {
    # Return the character encoding of the management action

    if (dorm_act == PRECLEAR$model & grow_act != FLOOD$model) {
      ## The dormant action is pre-flood clearing and the growing action isn't flood
      #  This is equivalent to either B or L, but which?

      ## Did pre-flood clearing involve burning? Note that there may be different
      #  applications with differing techniques.
      #  If not, was the biomass removed?
      #  choose MECHREMOVE or MECHLEAVE based on the answers to these questions
      pretechnique <- reports[reports$model_phase == DORMANT$code, "pretechnique"]
      if (any(pretechnique %in% c(0, 2))) {
        # Burn on at least 76% of MU (see assumptions)
        return(MECHREMOVE$model)
      } else {
        if (all(pretechnique == 1)) {
          # No burn only
          preremove <- reports[reports$model_phase == DORMANT$code, "preremove"]
          if (any(preremove == 1)) {
            # Biomass removed from >76% of MU (see assumptions)
            return(MECHREMOVE$model)
          } else {
            if (all(preremove == 0)) {
              # Biomass not removed
              return(MECHLEAVE$model)
            } else {
              # unknown preremove code AND no other indication of biomass removal
              warning("swapPLB: preremove code out of range. Combination cannot be repaired")
              return(PRECLEAR$model)
            }
          }
        } else {
          # pretechnique not in 0,1,2 AND no other indication of biomass removal
          warning("swapPLB: Pre-Flood clearing technique out of range. Combination cannot be repaired")
          return(PRECLEAR$model)
        }
      }
    } else {
      if (dorm_act %in% c(MECHREMOVE$model, MECHLEAVE$model) & grow_act == FLOOD$model) {
        ## The dormant action is mechanical and the growing action is flood
        #  This is equivalent to PF
        return(PRECLEAR$model)
      } else {
        ## There's no equivalent dormant action that could turn the reported
        # combination into a PAMF combination
        return(dorm_act)
      }
    }
    # END of code=="character"
  } else {
    if (code == "numeric") {
      # Return the numeric encoding of the management action

      if (dorm_act == PRECLEAR$model & grow_act != FLOOD$model) {
        ## The dormant action is pre-flood clearing and the growing action isn't flood
        #  This is equivalent to either B or L, but which?

        ## Did pre-flood clearing involve burning? Note that there may be different
        #  applications with differing techniques.
        #  If not, was the biomass removed?
        #  choose MECHREMOVE or MECHLEAVE based on the answers to these questions
        pretechnique <- reports[reports$model_phase == DORMANT$code, "pretechnique"]
        if (any(pretechnique %in% c(0, 2))) {
          # Burn on at least 76% of MU (see assumptions)
          return(MECHREMOVE$db)
        } else {
          if (all(pretechnique == 1)) {
            # No burn only
            preremove <- reports[reports$model_phase == DORMANT$code, "preremove"]
            if (any(preremove == 1)) {
              # Biomass removed from >76% of MU (see assumptions)
              return(MECHREMOVE$db)
            } else {
              if (all(preremove == 0)) {
                # Biomass not removed
                return(MECHLEAVE$db)
              } else {
                # unknown preremove code AND no other indication of biomass removal
                warning("swapPLB: preremove code out of range. Combination cannot be repaired")
                return(PRECLEAR$db)
              }
            }
          } else {
            # pretechnique not in 0,1,2 AND no other indication of biomass removal
            warning("swapPLB: Pre-Flood clearing technique out of range. Combination cannot be repaired")
            return(PRECLEAR$db)
          }
        }
      } else {
        if (dorm_act %in% c(MECHREMOVE$model, MECHLEAVE$model) & grow_act == FLOOD$model) {
          ## The dormant action is mechanical and the growing action is flood
          #  This is equivalent to PF
          return(PRECLEAR$db)
        } else {
          ## There's no equivalent dormant action that could turn the reported
          # combination into a PAMF combination
          numeric_action <- unique(reports[
            reports$model_phase == DORMANT$code,
            "treatmethod"
          ])
          if (length(numeric_action) == 1) {
            return(numeric_action)
          } else {
            stop("SwapPLB: Cannot return numeric codes for more than one action")
          }
        }
      }

      # END of code=="numeric"
    } else {
      # code argument is neither "character" nor "numeric"
      stop("swapPLB: Invalid 'code' parameter. Options are: 'character',
           'numeric'")
    }
  }
} # end swapPLB

getNotIntendedMU <- function(manage) {
  # Given a set of management reports associated with a single MU, return the
  # munitid if the 'followreason' column includes either 'experience' or 'agree'
  #
  # INPUT
  # manage : one or more management reports (data frame)
  #
  # OUTPUT
  # munitid, if 'followreason' contains 'experience' or 'agree'
  # NA otherwise
  #
  # ASSUMPTIONS
  # * manage has the following columns:
  #     munitid
  #     followreason
  ##

  if ("experience" %in% manage$followreason | "agree" %in% manage$followreason) {
    return(unique(manage$munitid))
  } else {
    return(NULL)
  }
} # end getNotIntendedMU


getAAMP_MU <- function(enroll) {
  # Given the enrollment forms for all MUs, return the
  # munitid if the 'aamp' column  = 1 (meaning that they are a participant
  # in the PAMF Active Adaptive Management Program-AAMP starting in 2024)
  #
  # INPUT
  # enroll : all enrollment reports (data frame)
  #
  # OUTPUT
  # munitid, if column aamp exists and == 1
  #
  # ASSUMPTIONS
  # * enroll has the following columns:
  #     munitid
  ##
  if ("aamp" %in% names(enroll)) {
    if (any(enroll$aamp %in% 1)) {
      return(enroll$munitid[which(enroll$aamp == 1)])
    }
  } else {
    return(NULL)
  }
} # end getAAMP_MU

pasteNoNA <- function(strings, sep = "", collapse = "") {
  # Given a vector of character strings, paste the non-NA elements together
  #
  # INPUT
  # strings: a vector of character strings
  #
  # OUTPUT
  # a single character string consisting of the non-NA elements of strings
  #
  # ASSUMPTIONS
  ##

  return(paste(strings[which(!is.na(strings))], sep = sep, collapse = collapse))
} # end pasteNoNA

updatePhaseIssues <- function(mani, run_path) {
  # Update the out_of_phase and unresolved_phase columns in manage_issues.csv
  # with the values in man_issues
  #
  # INPUT
  # mani     : Management issues dataframe (dataframe)
  # run_path : File path leading to outputs from the current model run (character)
  #
  # OUTPUT
  # none
  #
  # ASSUMPTIONS
  # * mani and management_issues.csv have the columns
  #     out_of_phase
  #     unresolved_phase
  ##

  man_issues <- read.csv(paste0(run_path, "manage_issues.csv"),
    stringsAsFactors = FALSE
  )

  # Only update rows that exist in man_issues
  man_ids <- mani$treatmentid

  man_issues[
    man_issues$treatmentid %in% man_ids,
    "out_of_phase"
  ] <- mani$out_of_phase
  man_issues[
    man_issues$treatmentid %in% man_ids,
    "unresolved_phase"
  ] <- mani$unresolved_phase

  write.csv(man_issues, paste0(run_path, "manage_issues.csv"), row.names = FALSE)
} # end updatePhaseIssues


