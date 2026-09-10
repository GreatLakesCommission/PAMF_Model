# 2020-08-04
# Last updated: 2020-12-23 (removed deprecated functions)
#
# Functions that are used in more than one part of the software
#
# Functions:
#   * writeOutput        : Writes output & replaces old versions of cumulative
#                          files where necessary
#   * writeOutputChanges : Writes changes to an existing output file without
#                          appending new lines
#   * repairSums         : Fix rounding errors so that input values sum to 1
##

writeOutput <- function(data, file_name, run_path, append = FALSE, old_file = NULL) {
  # For model runs after 2018, read the 'NOT-UPDATED' version of the desired
  # file, append new rows, and replace the old file with the new one. For 2018,
  # just write the file (first PAMF cycle; nothing to update)
  #
  # INPUT
  # data      : Data to be written to file (data frame)
  # file_name : Name of file to be written (character)
  # run_path  : The path to a model run directory (character)
  # append    : whether to append to old_file
  # old_file  : Name of file to append current data to (character)
  #             If not specified, defaults to the 'NOT-UPDATED' version of
  #             file_name.
  #
  # OUTPUT
  # none
  #
  # ASSUMPTIONS
  # 1. data has the same columns as the table in run_path/[old_file].csv
  # 2. file_name does not contain the "." character
  ##

  # Strip off any extensions on file_name
  fn <- strsplit(file_name, ".", fixed = TRUE)
  file_name <- fn[[1]][1]

  if (!append == TRUE) {
    # Don't append to any previous files; just write the data.
    write.csv(data, paste0(run_path, file_name, ".csv"), row.names = FALSE)
  } else { #  Append new data to existing data.
    # Check for default value on old_file
    if (is.null(old_file)) {
      # Default; assume a "-NOT-UPDATED" file
      old_file <- paste0(run_path, file_name, "-NOT-UPDATED.csv")
    }

    # Read the old data file
    past_data <- read.csv(old_file, stringsAsFactors = FALSE)

    # append new rows generated during this model run
    all_data <- rbind(past_data, data)

    # Write new file and delete old file
    write.csv(all_data, paste0(run_path, file_name, ".csv"), row.names = FALSE)
    unlink(old_file)
  }
} # end writeOutput

writeOutputChanges <- function(data, file_name, run_path) {
  # Overwrite part of a file with new information (OTHER THAN changes to unique
  # values like IDs)
  #
  # INPUT
  # data      : Data to be written to file (data frame)
  # file_name : Name of file to be updated (character)
  # run_path  : The path to a model run directory (character)
  #
  # OUTPUT
  # None
  #
  # ASSUMPTIONS
  # * The pre-existing saved version of the data contains at least one column
  #   containing unique values (e.g. ID numbers)
  # * The 'data' argument does not contain changes to columns with unique values
  #   (e.g. IDs)
  # * Entries in the unique-valued columns of the 'data' argument are a subset
  #   of the corresponding values in the pre-existing saved version
  #
  # KNOWN ISSUES
  # * this function is slow! This is a consequence of its generality: because
  #   we don't know which columns have unique values beforehand, we can't use
  #   subsetting. And the apply functions don't play well with operators. Which
  #   leaves us with loops. Although honestly the other parts are slow too.
  ##
  old_data <- read.csv(paste0(run_path, file_name))

  ## Ignore all rows of data that are unchanged from old_data
  old_rows <- split(old_data, 1:nrow(old_data))
  data_rows <- split(data, 1:nrow(data))

  update_rows <- which(!data_rows %in% old_rows)
  if (length(update_rows) > 0) {
    update_data <- data[update_rows, ]

    ## Find columns with unique values in old_data.
    #  Since this function is meant to update the file, assume that data has
    #  unique values in the same columns (e.g. IDs).
    #
    #  Use these columns to find the rows of old_data that correspond to the rows
    #  of update_data
    ##
    old_cols <- split.default(old_data, 1:ncol(old_data))
    is_duplicated <- lapply(old_cols, duplicated)
    unique_cols <- which(lapply(is_duplicated, any) == FALSE)
    uc_names <- colnames(old_data[unique_cols])


    ## For each entry in update_data, find its corresponding row in old_data.
    #  Overwrite the row of old_data with the one from update_data
    ##
    old_unique_rows <- split(old_data[, uc_names], 1:nrow(old_data))
    new_unique_rows <- split(update_data[, uc_names], 1:nrow(update_data))
    update_rows <- split(update_data, 1:nrow(update_data))

    for (i in 1:nrow(update_data)) {
      # Use a loop because:
      #  * subsetting only works when you know the column names beforehand
      #  * lapply can only apply named functions (not operators)
      row_index <- which(old_unique_rows %in% new_unique_rows[i])
      old_data[row_index, ] <- update_rows[[i]]
    }

    write.csv(old_data, paste0(run_path, file_name), row.names = FALSE)
  } # end the conditional checking that one or more rows needs updating
  # there is no 'else' because if no rows need updating, then do nothing
} # end writeOutputChanges

repairSums <- function(matrix_row) {
  # Each row of a transition matrix sums to 1. However, the calculations
  # that result in each transition probability may be off at precision
  # (e.g. 10^-9) that doesn't affect most further calculations but DOES
  # trigger an error during the optimization in mdp_check(). This function
  # finds these small errors and distributes them evenly across all
  # outcomes (when error > 0) or all outcomes > |error| when error < 0
  # (to prevent negative transition probabilities)
  #
  # INPUT
  # matrix_row : values corresponding to the row of a transition matrix
  #              (vector, double)
  #
  # OUTPUT
  # A new matrix row that sums to 1
  #
  # ASSUMPTIONS
  #  * This function always reduces epsilon. infinite recursion will not occur
  ##

  epsilon <- 1 - sum(matrix_row)

  if (epsilon == 0) {
    return(matrix_row)
  } else {
    if (epsilon > 0) {
      # distribute evenly across all entries in the row
      add_this <- epsilon / length(matrix_row)
      matrix_row <- matrix_row + add_this
    } else {
      if (epsilon < 0) {
        # distribute evenly across all entries > |epsilon|
        # (without this step we could get negative transition probabilities)
        positive_enough <- which(matrix_row > abs(epsilon))
        add_this <- epsilon / length(positive_enough)
        matrix_row[positive_enough] <- matrix_row[positive_enough] + add_this
      }
    }
  }

  if ((sum(matrix_row) - 1) != 0) {
    # Sometimes the repair process itself gives a small rounding error
    warning("Matrix row not repaired. Trying again...")
    matrix_row <- repairSums(matrix_row)
  }
  return(matrix_row)
} # end repairSums
