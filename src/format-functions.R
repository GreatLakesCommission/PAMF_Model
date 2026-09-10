# 2020-12-03
#
# Functions that format all types of reports for use by the model software,
# and functions that support them.
# Each report type has its own function because:
#   * Different sets of reports are read in for the model run vs. MCFG creation
#   * Each report type has its own backward compatibility issues that the
#     formatting function checks for and repairs. This gets confusing when
#     multiple report types are formatted at once
#
# Functions:
#   * fixLiterals    : Fixes syntax disagreements between R, SQL
#   * formatEnroll   : Prepare enrollment reports for use
#   * formatMonitor  : Prepare monitoring reports for use
#   * formatManage   : Prepare management reports for use
#   * formatMidcycle : Prepare midcycle reports for use
#   * vec2numeric    : Convert values in a vector to numeric, IF the
#                      conversion does not generate NAs
##

fixLiterals <- function(data) {
  # Converts "" to NA, True to TRUE, False to FALSE, "NULL" to NA
  # The model was built in 2018 to expect these defaults (NA for empty field;
  # TRUE, FALSE) from the database.
  #
  # In 2019, we changed the database pull method, resulting in slightly different
  # defaults ("" for empty field, "True", "False"). This function translates
  # them into the form that the model will recognize.
  #
  # In 2020, we used .csv files taken directly from the database, resulting in
  # more slight differences, i.e. the character string "NULL" for (I think)
  # empty strings.
  #
  # NOTE: if data is already in 2018 format, this function will not make any
  # changes
  #
  # INPUT
  # data : a data frame
  #
  # OUTPUT
  # a data frame where the substitutions described above have been made
  #
  # ASSUMPTIONS
  ##

  # Get row and column indices of empty string, "True", and "False"
  es_inds <- which(data == "", arr.ind = TRUE)
  t_inds <- which(data == "True" | data == "true", arr.ind = TRUE)
  f_inds <- which(data == "False" | data == "false", arr.ind = TRUE)
  null_inds <- which(data == "NULL" | data == "null" | data == "Null", arr.ind = TRUE)

  # make substitutions (only if needed)
  if (nrow(es_inds) > 0) { # empty string to NA
    for (i in 1:nrow(es_inds)) {
      data[es_inds[i, 1], es_inds[i, 2]] <- NA
    }
  }

  if (nrow(t_inds) > 0) { # True or true to TRUE
    for (i in 1:nrow(t_inds)) {
      data[t_inds[i, 1], t_inds[i, 2]] <- TRUE
    }
  }

  if (nrow(f_inds) > 0) { # False or false to FALSE
    for (i in 1:nrow(f_inds)) {
      data[f_inds[i, 1], f_inds[i, 2]] <- FALSE
    }
  }

  if (nrow(null_inds) > 0) { # NULL or null to NA
    for (i in 1:nrow(null_inds)) {
      data[null_inds[i, 1], null_inds[i, 2]] <- NA
    }
  }

  return(data)
} # end fixLiterals

formatEnroll <- function(enroll_data, cycleend, trim.frame = TRUE) {
  # Formats enrollment reports for later use
  #
  # INPUT
  # enroll_data : enrollment reports (dataframe)
  # cycleend    : end year of the relevant cycle (numeric)
  # trim.frame  : if TRUE, return only the rows pertaining to the cycle defined
  #               by cycleend and the columns relevant to the model run.
  #               if FALSE, return the full table
  #
  # OUTPUT
  # A formatted version of enroll, with
  #   * formatting compatible with the R language's definitions of TRUE, FALSE,
  #     and missing values within large objects (NA). See to2018Format() for
  #     details
  #   * Conversion to numeric type of all columns where it's possible to do
  #     so cleanly. See vec2numeric() for details.
  #   * date columns converted to Date type
  #   * any backward compatibility issues repaired
  #   * if trim.frames==TRUE, only rows and columns relevant to the model run
  #     are returned
  #
  # ASSUMPTIONS
  #   * fixLiterals is sourced
  #   * vec2numeric is sourced
  #   * enroll contains the columns
  #       munitid
  #       name
  #       herbicide
  #       cut
  #       controlwater
  #       dateentered
  #       area
  #       userid
  ##

  ## --- Find and fix literals that have different meanings in SQL, R ---

  ## The unformatted reports may contain different assumptions about certain
  #  literals than is standard for R: The database is created and maintained in
  #  Microsoft SQL Server, and in some years (2019) the data are processed into
  #  .csv files using a third language (Python).
  #
  #  Check the reports for instances of "", True, False, and NULL; convert them
  #  into NA, TRUE, FALSE, and NA, respectively.
  ##
  enroll <- fixLiterals(enroll_data)

  ## In cases where NULL is used to denote a missing value within a table
  #  (e.g. those tables converted directly from the database to .csv format),
  #  R reads any column containing NULL as a character vector.
  #
  #  This is because in R, NULL denotes an empty object, not an empty value.
  #  Rather than collapsing the entire dataframe to NULL, read.csv() replaces
  #  NULL entries with the string "NULL" (which we then converted to NA above).
  #
  #  In many cases, the data in NULL-containing columns are intended to be numeric.
  #  Where columns contain only NA and values that can be converted cleanly to
  #  numeric, make the conversion.
  #  (Don't change the others-- they're correctly in character type)
  ##
  enrollnum <- lapply(enroll, vec2numeric)
  enroll <- do.call(data.frame, enrollnum)


  ## --- Format date information as necessary ---
  #  Set all date columns to the Date datatype
  enroll$dateentered <- as.Date(enroll$dateentered)


  ## --- Trim dataframe to relevant rows and columns ---

  ## Since MUs created during any year may be active, always keep all rows
  #  Also note that the 'inactive' column was not added until 2019
  if (trim.frame == TRUE) {
    if (cycleend == 2018) {
      enroll <- enroll[, c(
        "munitid", "name", "herbicide", "cut", "controlwater",
        "dateentered", "area", "userid"
      )]
    } else {
      enroll_names <- c(
        "munitid", "name", "herbicide", "cut", "controlwater",
        "dateentered", "area", "active", "userid"
      )
      # Select this column name only if it exists:
      # aamp = PAMF's Active Adaptive Management Grant Program
      if ("aamp" %in% names(enroll)) {
        enroll_names <- c(enroll_names, "aamp")
      }

      enroll <- enroll[, names(enroll) %in% enroll_names]
      rm(enroll_names)
    }
  }

  return(enroll)
} # end formatEnroll

formatMonitor <- function(monitor_data, cycleend, trim.frame = TRUE) {
  # Formats monitoring reports for later use
  #
  # INPUT
  # monitor_data : monitoring reports (dataframe)
  # cycleend     : end year of the relevant cycle (numeric)
  # trim.frame   : if TRUE, return only the rows pertaining to the cycle defined
  #                by cycleend and the columns relevant to the model run.
  #                if FALSE, return the full table
  #
  # OUTPUT
  # A formatted version of monitor, with
  #   * formatting compatible with the R language's definitions of TRUE, FALSE,
  #     and missing values within large objects (NA). See to2018Format() for
  #     details
  #   * Conversion to numeric type of all columns where it's possible to do
  #     so cleanly. See vec2numeric() for details.
  #   * date columns converted to Date type
  #   * any backward compatibility issues repaired
  #   * if trim.frames==TRUE, only rows and columns relevant to the model run
  #     are returned
  #
  # ASSUMPTIONS
  #   * fixLiterals is sourced
  #   * vec2numeric is sourced
  #   * monitor contains the columns
  #       id
  #       munitid
  #       establishment
  #       q1stemcount-q5stemcount
  #       dateentered
  #       notes
  #       monitoringdate
  ##

  ## Re-name the 'id' column so that it's specific to the report type
  colnames(monitor_data)[1] <- "monitorid"


  ## --- Find and fix literals that have different meanings in SQL, R ---

  ## The unformatted reports may contain different assumptions about certain
  #  literals than is standard for R: The database is created and maintained in
  #  Microsoft SQL Server, and in some years (2019) the data are processed into
  #  .csv files using a third language (Python).
  #
  #  Check the reports for instances of "", True, False, and NULL; convert them
  #  into NA, TRUE, FALSE, and NA, respectively.
  ##
  monitor <- fixLiterals(monitor_data)

  ## In cases where NULL is used to denote a missing value within a table
  #  (e.g. those tables converted directly from the database to .csv format),
  #  R reads any column containing NULL as a character vector.
  #
  #  This is because in R, NULL denotes an empty object, not an empty value.
  #  Rather than collapsing the entire dataframe to NULL, read.csv() replaces
  #  NULL entries with the string "NULL" (which we then converted to NA above).
  #
  #  In many cases, the data in NULL-containing columns are intended to be numeric.
  #  Where columns contain only NA and values that can be converted cleanly to
  #  numeric, make the conversion.
  #  (Don't change the others-- they're correctly in character type)
  ##
  monnum <- lapply(monitor, vec2numeric)
  monitor <- do.call(data.frame, monnum)


  ## --- Backward Compatibility: Deleted MUs

  ## In 2018, several test MUs were deleted after monitoring/management
  #  reports were submitted. Those reports remain, but the enrollment reports
  #  do not. We have since changed the Web Hub functionality to designate MUs
  #  as 'inactive' rather than deleting them.
  #
  #   Remove monitoring information from deleted units:
  #   6  10  12  29  32  35  37 110 111 112  64 133 163  44  33
  ##
  deleted_mus <- c(6, 10, 12, 29, 32, 35, 37, 110, 111, 112, 64, 133, 163, 44, 33)
  monitor <- monitor[!monitor$munitid %in% deleted_mus, ]


  ## --- Format date information as necessary ---

  ## Set all date columns to the Date datatype
  monitor$monitoringdate <- as.Date(monitor$monitoringdate)

  ## Add columns describing the month/year that monitoring/management was done
  #  These facilitate several of the comparisons needed for QAQC, data cleaning,
  #  etc.
  ##
  monitor_year <- as.numeric(substr(monitor$monitoringdate, 1, 4))
  monitor_month <- as.numeric(substr(monitor$monitoringdate, 6, 7))
  monitor <- cbind(monitor, monitor_year, monitor_month)


  ## --- Trim dataframe to relevant rows and columns ---
  if (trim.frame == TRUE) {
    # Get relevant rows, columns from monitoring reports
    monitor <- monitor[
      monitor$monitor_year %in% c(cycleend - 1, cycleend) |
        monitor$dateentered %in% c(cycleend - 1, cycleend),
      c(
        "monitorid", "munitid", "establishment", "q1stemcount",
        "q2stemcount", "q3stemcount", "q4stemcount",
        "q5stemcount", "dateentered", "monitoringdate",
        "monitor_year", "monitor_month", "notes", "userid"
      )
    ]
  }

  return(monitor)
} # end formatMonitor

formatManage <- function(manage_data, mndate_data, cycleend, trim.frame = TRUE) {
  # Formats management reports for later use
  #
  # INPUT
  # manage_data : management reports (dataframe)
  # mndate_data : management dates   (dataframe)
  # cycleend    : end year of the relevant cycle (numeric)
  # trim.frame  : if TRUE, return only the rows pertaining to the cycle defined
  #               by cycleend and the columns relevant to the model run.
  #               if FALSE, return the full table
  #
  # OUTPUT
  # A formatted version of manage, with
  #   * data from manage and mndates
  #   * formatting compatible with the R language's definitions of TRUE, FALSE,
  #     and missing values within large objects (NA). See to2018Format() for
  #     details
  #   * Conversion to numeric type of all columns where it's possible to do
  #     so cleanly. See vec2numeric() for details.
  #   * date columns converted to Date type
  #   * any backward compatibility issues repaired
  #   * if trim.frames==TRUE, only rows and columns relevant to the model run
  #     are returned
  #
  # ASSUMPTIONS
  #   * fixLiterals is sourced
  #   * vec2numeric is sourced
  #   * manage contains the column
  #       managementdate
  #   * mndates contains the column
  #        applicationdate
  ##

  ## Re-name the 'id' column so that it's specific to the report type
  colnames(manage_data)[1] <- "treatmentid" # the same data as mndates$treatmentid
  colnames(mndate_data)[1] <- "applicationid"

  ## --- Find and remove application dates for rest and flood reports ---
  
  # The web hub is not supposed to be able to record application dates for flood
  # or rest reports. However, if a report is filled out for a different 
  # treatment method (e.g., glyphosate), then changed later edited to be a rest
  # or flood report, then it will retain the application date in the database. 
  # To prevent any errors associated with this, remove the erroneous application
  # dates.
  
  rest_and_flood_treatmentids <- manage_data$treatmentid[which(manage_data$treatmethod %in% c(3,8))]
  erroneous_applicationids <- mndate_data$applicationid[which(mndate_data$treatmentid %in% rest_and_flood_treatmentids & !is.na(mndate_data$applicationdate))] 
  if(length(erroneous_applicationids) > 0){
    mndate_data$applicationdate[which(mndate_data$applicationid %in% erroneous_applicationids)] <- NA
  }
  rm(rest_and_flood_treatmentids, erroneous_applicationids)
  
  ## Merge manage and mndates so that it's possible to look up application dates
  #  along with other management information.
  #
  #  From this point forward, management reports are made up of one or more
  #  rows, where each row consists of one application of the management action
  ##
  manage <- merge(manage_data, mndate_data,
    by.x = "treatmentid", by.y = "treatmentid",
    all.x = TRUE
  )

  ## --- Find and fix literals that have different meanings in SQL, R ---

  ## The unformatted reports may contain different assumptions about certain
  #  literals than is standard for R: The database is created and maintained in
  #  Microsoft SQL Server, and in some years (2019) the data are processed into
  #  .csv files using a third language (Python).
  #
  #  Check the reports for instances of "", True, False, and NULL; convert them
  #  into NA, TRUE, FALSE, and NA, respectively.
  ##
  manage <- fixLiterals(manage)


  ## In cases where NULL is used to denote a missing value within a table
  #  (e.g. those tables converted directly from the database to .csv format),
  #  R reads any column containing NULL as a character vector.
  #
  #  This is because in R, NULL denotes an empty object, not an empty value.
  #  Rather than collapsing the entire dataframe to NULL, read.csv() replaces
  #  NULL entries with the string "NULL" (which we then converted to NA above).
  #
  #  In many cases, the data in NULL-containing columns are intended to be numeric.
  #  Where columns contain only NA and values that can be converted cleanly to
  #  numeric, make the conversion.
  #  (Don't change the others-- they're correctly in character type)
  ##
  mannum <- lapply(manage, vec2numeric)
  manage <- do.call(data.frame, mannum)


  ## --- Backward Compatibility: Deleted MUs

  ## In 2018, several test MUs were deleted after monitoring/management
  #  reports were submitted. Those reports remain, but the enrollment reports
  #  do not. We have since changed the Web Hub functionality to designate MUs
  #  as 'inactive' rather than deleting them.
  #
  #   Remove management information from deleted units:
  #   6  10  12  29  32  35  37 110 111 112  64 133 163  44  33 360
  ##
  deleted_mus <- c(6, 10, 12, 29, 32, 33, 35, 37, 44, 64, 110,
                   111, 112, 133, 163, 360)
  manage <- manage[!manage$munitid %in% deleted_mus, ]


  ## --- Format date information as necessary ---

  ## Incorporate 'cycleyear' column 
  # To add more confusion to the date columns in the management reports, in 2021
  # the column 'cycleyear' was added to the management data to help the 
  # Web Hub display Rest and Flood reports in the correct cycle since they
  # don't require a date, and dateentered can be ambiguous (e.g., someone might
  # enter a rest report far after the intended phase/cycle and it won't get
  # sorted into the correct cycle). This is rare, but can happen. To prevent
  # this, if the cycleyear column is present, use it to determine the correct
  # cycle of the report. We do this in a bit of a hacky way to work with the 
  # rest of the model code by assigning a standardized dateentered and/or 
  # managementdate based on the cycleyear that the model can then use to make 
  # determinations about phase date agreements with other reports. This also 
  # allows backwards compatibility with previous versions of the data. Note
  # that 'cycleyear' == NA from 2017-2021 was backfilled in 2023 for each
  # management report based on report-repairs from the Model and manual checking
  # of reports, so when running base runs in the future we can pull from that
  # information.  
  #
  # Standardized dates per phase:
  #   - Translocating: October 1, YYYY (cycle year 1; cycleyear - 1)
  #   - Dormant: January 1, YYYY (cycle year 2, cycleyear + 0)
  #   - Growing: May 1, YYYY (cycle year 2, cycleyear + 0)

  if ("cycleyear" %in% colnames(manage)) {
    # Translocating - dateentered
    tr_exp_de <- expression(which(!is.na(manage$dateentered) & manage$phase == 0 & manage$treatmethod %in% c(3, 8) & !is.na(manage$cycleyear)))
    if (length(manage$dateentered[eval(tr_exp_de)] > 0)) {
      manage$dateentered[eval(tr_exp_de)] <- paste0((manage$cycleyear[eval(tr_exp_de)] - 1), "-10-01")
    }
    rm(tr_exp_de)
    # Translocating -  management date
    tr_exp_md <- expression(which(!is.na(manage$managementdate) & manage$phase == 0 & manage$treatmethod %in% c(3, 8) & !is.na(manage$cycleyear)))
    if (length(manage$managementdate[eval(tr_exp_md)] > 0)) {
      manage$managementdate[eval(tr_exp_md)] <- paste0((manage$cycleyear[eval(tr_exp_md)] - 1), "-10-01")
    }
    rm(tr_exp_md)
    # Dormant - dateentered
    dr_exp_de <- expression(which(!is.na(manage$dateentered) & (manage$phase == 1) & (manage$treatmethod %in% c(3, 8)) & !is.na(manage$cycleyear)))
    if (length(manage$dateentered[eval(dr_exp_de)] > 0)) {
      manage$dateentered[eval(dr_exp_de)] <- paste0(manage$cycleyear[eval(dr_exp_de)], "-01-01")
    }
    rm(dr_exp_de)
    # Dormant - management date
    dr_exp_md <- expression(which(!is.na(manage$managementdate) & (manage$phase == 1) & (manage$treatmethod %in% c(3, 8)) & !is.na(manage$cycleyear)))
    if (length(manage$managementdate[eval(dr_exp_md)] > 0)) {
      manage$managementdate[eval(dr_exp_md)] <- paste0(manage$cycleyear[eval(dr_exp_md)], "-01-01")
    }
    rm(dr_exp_md)
    # Growing - dateentered
    gr_exp_de <- expression(which(!is.na(manage$dateentered) & (manage$phase == 2) & (manage$treatmethod %in% c(3, 8)) & !is.na(manage$cycleyear)))
    if (length(manage$dateentered[eval(gr_exp_de)] > 0)) {
      manage$dateentered[eval(gr_exp_de)] <- paste0(manage$cycleyear[eval(gr_exp_de)], "-05-01")
    }
    rm(gr_exp_de)
    # Growing - management date
    gr_exp_md <- expression(which(!is.na(manage$managementdate) & (manage$phase == 2) & (manage$treatmethod %in% c(3, 8)) & !is.na(manage$cycleyear)))
    if (length(manage$managementdate[eval(gr_exp_md)] > 0)) {
      manage$managementdate[eval(gr_exp_md)] <- paste0(manage$cycleyear[eval(gr_exp_md)], "-05-01")
    }
    rm(gr_exp_md)
  }
  ## Backward Compatibility: Optional Application Dates
  #
  # Application dates were optional until summer 2019. Prior to that, we used
  # managementdate as a stand-in for missing application dates.The last such
  # report has a managementdate of 2019-10-28.
  #
  # In reports made through the translocating phase of 2019, there may be
  # application dates/years/months that are NA for actions other than REST or
  # FLOOD (the REST, FLOOD forms don't collect application dates and we'll deal
  # with that in a little while)
  # Replace these with the corresponding management date/year/month
  ##
  if (cycleend <= 2020) {
    manage[!manage$treatmethod %in% c(REST$db, FLOOD$db), "applicationdate"] <-
      ifelse(is.na(manage[
        !manage$treatmethod %in% c(REST$db, FLOOD$db),
        "applicationdate"
      ]),
      as.character(manage[!manage$treatmethod %in%
        c(REST$db, FLOOD$db), "managementdate"]),
      as.character(manage[!manage$treatmethod %in%
        c(REST$db, FLOOD$db), "applicationdate"])
      )
  }


  ## Backward Compatibility: Year that management was carried out (All actions)
  #
  # In 2018-2020, the Web Hub had a mandatory question that populated the
  # "managementdate" column, which was in some places used to describe the date
  # of management, and in other places used to describe the date that the report
  # was submitted. We resolved this ambiguity in summer 2020 by eliminating that
  # question, deprecating the "managementdate" column, and adding the 
  # dateentered column. Dateentered is populated automatically with the date 
  # that the report was submitted.
  #
  #  CONSEQUENTLY: In the 2018-2019 datasets, we take the timing of FLOOD and
  #                REST actions from the managementdate column.
  #                In 2020, we incorporate it from dateentered where possible,
  #                and managementdate otherwise
  ##
  if (cycleend < 2020) {
    manage_year <- ifelse(
      is.na(manage$applicationdate),
      as.numeric(substr(manage$managementdate, 1, 4)),
      as.numeric(substr(manage$applicationdate, 1, 4))
    )
  }

  ## Year that management was carried out (All actions) (2020-2021 cycle onward)
  #
  #  From 2020 onward, get manage_year from applicationdate or dateentered,
  #  depending on the management action. Actions without applicationdates get
  #  the year of dateentered. get actions with applicationdates get the year
  #  that the action was carried out.
  ##
  if (cycleend >= 2020) {
    manage_year <- ifelse(
      is.na(manage$applicationdate),
      as.numeric(substr(manage$dateentered, 1, 4)),
      as.numeric(substr(manage$applicationdate, 1, 4))
    )
  }

  ## Set all date columns to the Date datatype
  manage$managementdate <- as.Date(manage$managementdate)
  manage$applicationdate <- as.Date(manage$applicationdate)
  # dateentered was introduced in 2020
  if ("dateentered" %in% colnames(manage)) { 
    manage$dateentered <- as.Date(manage$dateentered)
  }

  ## Add columns describing the month/year that management was done
  #  These facilitate several of the comparisons needed for QAQC, data cleaning,
  #  etc.
  #
  #  application_year differs from manage_year for two reasons:
  #  * actions (rest, flood) that do not have an application date don't have
  #    an application_year but they do have a manage_year
  #  * Management reports in the dormant phase may contain applications in both
  #    years of the cycle. Since manage_year is constant across the entire
  #    report, it may differ from the application_year of particular rows
  #    within the report.
  ##
  application_year <- as.numeric(substr(manage$applicationdate, 1, 4))
  application_month <- as.numeric(substr(manage$applicationdate, 6, 7))
  manage <- cbind(manage, application_year, application_month, manage_year)


  ## --- Trim dataframe to relevant rows and columns ---

  if (trim.frame == TRUE) {
    ## Get relevant rows of management reports
    #  I'm not trimming out columns here because there are 168+ and we use most
    #  of them at one time or another
    manage <- manage[manage$manage_year %in% c(cycleend - 1, cycleend), ]
  }

  return(manage)
} # end formatManage

formatMidcycle <- function(midcycle_data, cycleend, trim.frame = TRUE) {
  # Formats management reports for later use
  #
  # INPUT
  # midcycle_data : midcycle reports (dataframe)
  # trim.frame    : if TRUE, return only the rows pertaining to the cycle defined
  #                 by cycleend and the columns relevant to the model run.
  #                 if FALSE, return the full table
  #
  # OUTPUT
  # A formatted version of midcycle, with
  #   * formatting compatible with the R language's definitions of TRUE, FALSE,
  #     and missing values within large objects (NA). See to2018Format() for
  #     details
  #   * Conversion to numeric type of all columns where it's possible to do
  #     so cleanly. See vec2numeric() for details.
  #   * date columns converted to Date type
  #   * any backward compatibility issues repaired
  #   * if trim.frames==TRUE, only rows and columns relevant to the model run
  #     are returned
  #
  # ASSUMPTIONS
  #   * fixLiterals is sourced
  #   * vec2numeric is sourced
  #   * midcycle contains the columns
  #       * id (must be the first column)
  #       * dateentered
  ##

  ## Re-name the 'id' column so that it's specific to the report type
  colnames(midcycle_data)[1] <- "midcycleid"


  ## --- Find and fix literals that have different meanings in SQL, R ---

  ## The unformatted reports may contain different assumptions about certain
  #  literals than is standard for R: The database is created and maintained in
  #  Microsoft SQL Server, and in some years (2019) the data are processed into
  #  .csv files using a third language (Python).
  #
  #  Check the reports for instances of "", True, False, and NULL; convert them
  #  into NA, TRUE, FALSE, and NA, respectively.
  ##
  midcycle <- fixLiterals(midcycle_data)

  ## In cases where NULL is used to denote a missing value within a table
  #  (e.g. those tables converted directly from the database to .csv format),
  #  R reads any column containing NULL as a character vector.
  #
  #  This is because in R, NULL denotes an empty object, not an empty value.
  #  Rather than collapsing the entire dataframe to NULL, read.csv() replaces
  #  NULL entries with the string "NULL" (which we then converted to NA above).
  #
  #  In many cases, the data in NULL-containing columns are intended to be numeric.
  #  Where columns contain only NA and values that can be converted cleanly to
  #  numeric, make the conversion.
  #  (Don't change the others-- they're correctly in character type)
  ##
  midcyclenum <- lapply(midcycle, vec2numeric)
  midcycle <- do.call(data.frame, midcyclenum)


  ## --- Format date information as necessary ---

  ## Set all date columns to the Date datatype
  midcycle$dateentered <- as.Date(midcycle$dateentered)

  ## Add columns describing the month/year that the midcycle report was submitted
  midcycle_year <- as.numeric(substr(midcycle$dateentered, 1, 4))
  midcycle_month <- as.numeric(substr(midcycle$dateentered, 6, 7))
  manage <- cbind(midcycle, midcycle_year, midcycle_month)


  ## --- Trim dataframe to relevant rows and columns ---

  if (trim.frame == TRUE) {
    ## Get relevant rows of midcycle reports
    #  Since these reports are submitted at either the end of the first year
    #  of the cycle or the beginning of the second year, ignore any reports
    #  outside of these time frames
    #  (thresholds are hard-coded at August and March, for now)
    ##
    midcycle <- midcycle[(midcycle_year == cycleend - 1 & midcycle_month > 8) |
      (midcycle_year == cycleend & midcycle_month < 3), ]
  }

  return(midcycle)
} # formatMidcycle

vec2numeric <- function(v) {
  # Converts a vector to numeric type when it meets the following
  # conditions:
  #   * There are no non-NA values that can't be converted to numeric without
  #     generating warnings
  #   * vector is not a factor type
  #
  # INPUT
  # v : a vector
  #
  # OUTPUT
  # If conditions are met, return a numeric form of v
  # Otherwise return the original v
  ##

  if (is.factor(v)) {
    next
  } else {
    vnum <- tryCatch(as.numeric(v), warning = function(w) {
      v
    })
    v <- vnum
  }
  return(v)
} # end vec2numeric
