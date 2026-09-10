# Functions that support the cost data cleaning and calculation scripts.
# DOES NOT CONTAIN the functions that calculate each cost:
# see cost-calculation-functions.R
#
# Functions:
#   * collapseCols  : collapse redundant columns into a single column
#   * costRows      : creates current_costs data frame
#   * colMedians    : calculate median of all columns in a data frame
#   * linearWeights : calculate weights for weighted moving average
#                     (not in use anywhere yet)
##

collapseCols <- function(data) {
  # Given a dataframe where there is at most one non-NA value per row,
  # collapse it into a single column of only the non-NA values
  #
  # INPUT
  # data    : data frame
  # new_col : name for the new column (character)
  #
  # OUTPUT
  # vector containing the non-NA value from each row of data where it exists;
  # NA otherwise
  #
  # ASSUMPTIONS
  # * there is at most one non-NA value per row
  # * WHAT HAPPENS WHEN 1 COL IN DATA?
  ##

  # convert any factor columns to strings
  # (otherwise the return values will be numeric levels)
  data <- rapply(data, as.character, classes = "factor", how = "replace")

  # split into list of rows in preparation for mapply()
  the_rows <- split(data, seq(nrow(data)))

  # Find index of non-NA value in each row
  logic_rows <- lapply(the_rows, is.na)
  logic_rows <- lapply(logic_rows, "!")
  nonna_indices <- lapply(logic_rows, which)

  # define a subsetting function to use with mapply
  getValue <- function(vec, index) {
    if (length(index) == 0) {
      # requested index does not exist
      return(NA)
    } else {
      if (length(index) > 1) {
        stop("collapseCols: more than one non-NA value in row")
      } else {
        return(vec[index])
      }
    }
  } # end getValue

  # Get the non-na values in vector format
  return(unlist(unname(mapply(getValue, the_rows, nonna_indices))))
} # end collapseCols

costRows <- function(costs, data, current_year) {
  # Creates a dataframe row in current_costs format for each value in costs
  #
  # INPUT
  # costs        : cost for each MU in data (numeric)
  # data         : cost data inputs for each MU in costs (dataframe)
  # current_year : the current year (numeric)
  #
  # OUTPUT
  # Dataframe containing costs and related information 0f length(costs)>0
  # NULL otherwise
  #
  # ASSUMPTIONS
  # * data contains the following columns:
  #   treatmentid
  #   munitid
  #   phase
  #   treatmethod
  #   hirecontractor
  #   rentequipment
  #   area
  # * length(costs) == nrow(data)
  ##

  if (length(costs) > 0) {
    return(data.frame(
      treatmentid = data$treatmentid, munitid = data$munitid,
      phase = data$phase, year_calculated = rep(
        current_year,
        nrow(data)
      ),
      treatmethod = data$treatmethod, contract = data$hirecontractor,
      rent = data$rentequipment, total_cost = costs,
      cost_per_acre = costs / data$area
    ))
  } else {
    return(NULL)
  }
} # end costRows

colMedians <- function(data) {
  # Calculate the median for all columns in a data frame
  #
  # INPUT
  # data : data frame
  #
  # OUTPUT
  # a named list containing the median of each column
  #
  # ASSUMPTIONS
  # * All values in data are numeric
  ##

  cols <- as.list(data)
  return(lapply(cols, median))
} # end colMedians


# ==============================================================================
# Possible weighting scheme for weighted moving average
# (multi-year cost aggregation)
# Weights decrease linearly with time; distance between weights corresponds to
# distance between the years when cost constants are updated
# ==============================================================================
linearWeights <- function(years) {
  # Calculates weights for weighted average, based on the spacing between years
  # when cost constants are updated. Weights decrease linearly with increasing
  # time, and the distance between weights corresponds to the distance between
  # the years when cost constants are updated
  #
  # INPUT
  # years: years when the cost constants file was updated (numeric vector)
  #
  # OUTPUT
  # A set of weights, each corresponding to a year (numeric vector). Weights
  # sum to 1.
  #
  # Suppose that constants are updated in years y_n > ... > y_2 > y_1
  # Weights are calculated using the following equation:
  # w_i = (y_i - y_1 + 1) / sum((y_j - y_1 + 1) for 1:j:n)
  #
  # The "+1" terms ensure that w_1 (the weight for y_1) is greater than zero.
  ##

  numerator <- years - min(years) + 1
  denominator <- rep(sum((years - min(years) + 1)), length(years))
  return(numerator / denominator)
}
