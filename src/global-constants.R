# Define constants accessible from anywhere in the code of the PAMF model and
# its GUI
# These include:
# * mappings of database values, e.g., '0' in the 'phase' column means
#   'translocating'
# * programmatic definitions, e.g., definitions of states
# * definitions that may not be constant though time, e.g., cost constants
#
# This script defines these values, and locks them in the global environment
# (i.e., they cannot be edited but they can be deleted)
# These values are used by several scripts/functions and it's helpful to only
# define them once. Locking is important because all scripts and functions will
# have access to them. At 10,000+ lines of code, it will not be easy to find
# accidental changes
##

# State Definitions ------------------------------------------------------------

#  Each state is characterized by a unique combination of %establishment and
#  stem density, and we consider invasion severity to increase with state ID#
#
#  These categories are encoded in the database (and here) as follows:
#  Establishment:
#     0 : 0-10% of management unit has live Phragmites
#     1 : 11-50%      "        "         "
#     2 : 51-100%     "        "         "
#  Stem density:
#     0: Low Density
#     1: High Density
#
##
STATES <- data.frame(
  stateid = c(1, 2, 3, 4, 5, 6),
  establishment = c(0, 0, 1, 1, 2, 2),
  stem_density = c(0, 1, 0, 1, 0, 1), stringsAsFactors = FALSE
)

LODENS_MAX <- 10 # maximum stem count for low stem density
STEMHI <- 50 # stem count threshold to trigger 'too many stems' warnings

# Timing Definitions -----------------------------------------------------------

# What months belong to monitoring, near-monitoring windows
MONITOR_MONTHS <- 7
NEARMONITOR_MONTHS <- c(6, 8)

# Phase names and timing
TRANSLOCATING <- list(code = 0, months = c(8, 9, 10)) # translocating
DORMANT <- list(code = 1, months = c(10, 11, 12, 1, 2, 3, 4)) # dormant
GROWING <- list(code = 2, months = c(4, 5, 6, 7)) # growing

# Management Actions and Combinations ------------------------------------------

## Management Actions ----------------------------------------------------------

# Map between the code sets used to define management actions in the database
# (numeric) and the code set used by the model (character strings)
# The model uses a different set of action codes than the database does for two
# reasons:
#   1. it took forever to get ahold of the database column names while i was
#      first writing the model
#   2. management combinations are represented in the model as a concatenation
#      of management actions that were carried out during a cycle. Due to the
#      presence of 10=OTHER in the database, and the possibility that
#      participants carry out more than one action, concatenating the numeric
#      codes results in ambiguity.
#      Changes to get rid of the character code set would require:
#        * if using concatenation: gather all non-PAMF combinations into a
#          single non-PAMF code at the time of concatenation
#        * be aware that adding any new actions to the list will add ambiguity
#          to the numeric code set because the new action WILL have a two-digit
#          code
##

# PAMF actions 
# Actions are encoded numerically in the database but as character strings in
# the model. (with character strings, I can concatenate actions into a PAMF
# combination with less ambiguity. e.g., note that 10 could  either be OTHER or
# GLYPH-IMAZ)
##
GLYPH <- list(db = 0, model = "G")
IMAZ <- list(db = 1, model = "I")
GLYPHPLUS <- list(db = 2, model = "G+")
REST <- list(db = 3, model = "R")
CUT <- list(db = 4, model = "C")
SPADING <- list(db = 5, model = "S")
PRECLEAR <- list(db = 6, model = "P")
MECHREMOVE <- list(db = 7, model = "B")
FLOOD <- list(db = 8, model = "F")
MECHLEAVE <- list(db = 9, model = "L")
OTHER <- list(db = 10, model = "OTHER")


## Management combinations -----------------------------------------------------

# Define PAMF combinations in terms of the actions defined above.
# Not very pretty, but prevent you from having to type any action code changes
# in more than one place
PAMF_COMBS <- data.frame(
  db_tloc = c(
    GLYPH$db, GLYPHPLUS$db, GLYPH$db, GLYPHPLUS$db,
    GLYPHPLUS$db, GLYPH$db, GLYPHPLUS$db, GLYPH$db,
    GLYPHPLUS$db, IMAZ$db, GLYPH$db, GLYPH$db,
    REST$db, REST$db, CUT$db, SPADING$db
  ),
  db_dorm = c(
    REST$db, PRECLEAR$db, PRECLEAR$db, FLOOD$db,
    REST$db, FLOOD$db, MECHLEAVE$db, MECHLEAVE$db,
    MECHREMOVE$db, REST$db, MECHREMOVE$db, REST$db,
    PRECLEAR$db, REST$db, REST$db, REST$db
  ),
  db_grow = c(
    GLYPH$db, FLOOD$db, FLOOD$db, FLOOD$db, REST$db,
    FLOOD$db, REST$db, REST$db, REST$db, REST$db,
    REST$db, REST$db, FLOOD$db, REST$db, CUT$db,
    SPADING$db
  ),
  tloc = c(
    GLYPH$model, GLYPHPLUS$model, GLYPH$model,
    GLYPHPLUS$model, GLYPHPLUS$model, GLYPH$model,
    GLYPHPLUS$model, GLYPH$model, GLYPHPLUS$model,
    IMAZ$model, GLYPH$model, GLYPH$model, REST$model,
    REST$model, CUT$model, SPADING$model
  ),
  dorm = c(
    REST$model, PRECLEAR$model, PRECLEAR$model,
    FLOOD$model, REST$model, FLOOD$model, MECHLEAVE$model,
    MECHLEAVE$model, MECHREMOVE$model, REST$model,
    MECHREMOVE$model, REST$model, PRECLEAR$model,
    REST$model, REST$model, REST$model
  ),
  grow = c(
    GLYPH$model, FLOOD$model, FLOOD$model, FLOOD$model,
    REST$model, FLOOD$model, REST$model, REST$model,
    REST$model, REST$model, REST$model, REST$model,
    FLOOD$model, REST$model, CUT$model, SPADING$model
  ),
  stringsAsFactors = FALSE
)
mnt_comb <- lapply(split(
  PAMF_COMBS[, c("tloc", "dorm", "grow")],
  1:nrow(PAMF_COMBS)
), paste0, collapse = "") # whole-cycle combination
PAMF_COMBS <- cbind(PAMF_COMBS,
  mnt_comb = do.call(rbind, mnt_comb),
  stringsAsFactors = FALSE
)

## Mapping combos --------------------------------------------------------------
## Map between model (character) and PAMF Web Hub (numeric) encodings.
#
#  Encodings for management combinations appear only in the mid-cycle reports.
#  These are detailed in this file:
#  "src/forecast-guidance/test-cases/pamf combination database key.txt"
mc_db <- c(5, 10, 1, 8, 11, 3, 9, 4, 7, 12, 2, 6, 13, 16, 14, 15)
PAMF_COMBS <- cbind(PAMF_COMBS, mc_db)

# remove temporary variables
rm(mnt_comb, mc_db)


# Cost Definitions -------------------------------------------------------------

OTHERHR_MAX <- 0.25 # Withhold management reports from cost calculations if the
#                    "otherhours" column is above this threshold. Why: we have
#                    no idea how much this category costs per hour

# Satisfaction values ----------------------------------------------------------

# If USE_SATISFACTION_MATRICES = TRUE
#   - Satisfaction matrices (satisfaction between invasion state transitions)
#     will be used (standard after 2022 model run)
# If USE_SATISFACTION_MATRICES = FALSE
#   - Single satisfaction values per invasion state will be used (standard 
#     before 2023 model run)
USE_SATISFACTION_MATRICES <- TRUE

# Optimization Constants -------------------------------------------------------

# DISCOUNT = 0.875 # 2018 discounting factor
DISCOUNT <- 0.7 # 2019 discounting factor

## Path to definitions of action restrictions
RESPATH <- "./src/policy_definitions2018-07-31.csv"

## MISC
MINAREA <- 11.36 / 4046.86 # 11.36 m^2 converted to acres (the area unit in
#                           enrollment table)
# NOTE: 11.36m^2 is the minimum area of a MU that is large enough to
#       accommodate 5 quadrats at 11% establishment. We consider stem
#       count anomalies in MUs larger than this threshold to be
#       possibly erroneous and worth checking by hand.

FLOODMIN <- 1 # Minimum flood duration (months)

# Guidance files ---------------------------------------------------------------

# If base runs need to be run, add the names of all official guidance files from
# previous years here, and the model code will account for the rest:

GUIDANCE_FILES <- c(
  `2018` = "guidance-2018-10-05.csv",
  `2019` = "guidance-2019-08-22.csv",
  `2020` = "guidance-2020-09-15.csv",
  `2021` = "guidance-2021-08-25.csv",
  `2022` = "guidance-2022-08-23.csv",
  `2023` = "guidance-2023-08-15.csv",
  `2024` = "guidance-2024-08-21.csv"
)

# Lock variables ---------------------------------------------------------------

# Lock variables in the Global environment 
lockBinding("CUT", .GlobalEnv)
lockBinding("DISCOUNT", .GlobalEnv)
lockBinding("DORMANT", .GlobalEnv)
lockBinding("FLOOD", .GlobalEnv)
lockBinding("FLOODMIN", .GlobalEnv)
lockBinding("GLYPH", .GlobalEnv)
lockBinding("GLYPHPLUS", .GlobalEnv)
lockBinding("GROWING", .GlobalEnv)
lockBinding("IMAZ", .GlobalEnv)
lockBinding("LODENS_MAX", .GlobalEnv)
lockBinding("MECHLEAVE", .GlobalEnv)
lockBinding("MECHREMOVE", .GlobalEnv)
lockBinding("MINAREA", .GlobalEnv)
lockBinding("MONITOR_MONTHS", .GlobalEnv)
lockBinding("NEARMONITOR_MONTHS", .GlobalEnv)
lockBinding("OTHER", .GlobalEnv)
lockBinding("OTHERHR_MAX", .GlobalEnv)
lockBinding("PAMF_COMBS", .GlobalEnv)
lockBinding("PRECLEAR", .GlobalEnv)
lockBinding("RESPATH", .GlobalEnv)
lockBinding("REST", .GlobalEnv)
lockBinding("SPADING", .GlobalEnv)
lockBinding("STATES", .GlobalEnv)
lockBinding("STEMHI", .GlobalEnv)
lockBinding("TRANSLOCATING", .GlobalEnv)
lockBinding("USE_SATISFACTION_MATRICES", .GlobalEnv)
lockBinding("GUIDANCE_FILES", .GlobalEnv)
