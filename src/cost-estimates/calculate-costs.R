# This script calculates the cost of all PAMF actions with cost data reported in
# the current cycle.
#
# Sourced by: run-the-model.R
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND    : end year of PAMF cycle for this model run
#    CYCLE       : years defining the PAMF cycle
#    RUNPATH     : path to output directory for this model run
#    COST_CONSTS : constants defining per-unit cost of fuel, supplies, labor, etc
#    Definitions for individual PAMF actions (see global-constants.R)
#     Hard-coded actions include:
#       GLYPH, IMAZ, GLYPHPLUS, CUT, SPADING, PRECLEAR, MECHREMOVE, MECHLEAVE,
#       FLOOD
#
# * Variables
#     enroll_data : enrollment reports (all MUs, all years)
#     man_data    : management reports submitted since REPORTBEGIN. Taken from
#                   PAMFDATA before the model_phase column was added
#     man_issues  : issues reports for reports in man_data
#
# * Functions
#   From cost-helper-functions.R:
#     collapseCols
#     costRows
#   From cost-calculation-functions.R:
#     costOfContractor
#     costOfHerbicide
#     costOfBiomassWEquipment
#     costOfHandRemoval
#     costOfActiveFlood
#     costOfPassiveFlooding
#
# * Files in RUNPATH
#     cost_estimates-NOT-UPDATED.csv
##

# # ============================================================================
# #  Uncomment this section for script testing
# #
# #  Unlike some of the other scripts, this one has a couple of sections that
# #  you'll have to skip (denoted in the section headers). They deal with some
# #  unwieldy aspects of the real data that don't exist in the test data.
# #  Either comment those out before sourcing this script or copy/paste it in
# #  pieces
# # ============================================================================
# options(stringsAsFactors=FALSE)
# message(">>> USING TEST DATA FOR COST CALCULATION <<<")
# 
# # Get data - choose the "man_data" you want to use:
# man_data   = read.csv("./src/cost-estimates/test-cases/test-data-for-costs-new-columns.csv")
# # man_data   = read.csv("./src/cost-estimates/test-cases/test-data-for-costs.csv")
# man_issues = read.csv("./src/cost-estimates/test-cases/man-issues-for-cost-test.csv")
# 
# ## Get functions
# source("./src/cost-estimates/cost-calculation-functions.R") # the cost estimation equations
# source("./src/cost-estimates/cost-helper-functions.R")      # functions that support cost calculations
# 
# ## Get constants
# source("./src/global-constants.R")
# COST_CONSTS = read.csv("./src/cost-estimates/test-cases/test-constants-for-costs.csv")
# CYCLEEND=2000
# CYCLE = c(1999, 2000)

# ## Before starting, verify that collapseCols() works:
# #  The management reports from the database contain several sets of redundant
# #  columns where only one column has a non-NA value. For example, glyphjetmax,
# #  imazjetmax, and glyphplusjetmax define the upper range of the amount of jet
# #  fuel used. But they each refer to a different management action & there's
# #  only one of those per row. So we can collapse this set of columns into a
# #  single column, jetmax, without losing information.
# #  This step allows us to reduce the dataframe from > 150 columns to < 40
# #  columns.
# ##
#
# # Create some test data with redundant columns
# redundant = data.frame(glyphfuel1=c(1, NA, NA, 4), imazfuel1=c(NA, 2, NA, 5),
#                        gplusfuel1=c(NA, NA, 3, 6))
#
# # Paste into console to verify
# collapseCols(redundant)       # Expected behaviour: Error-- row 4 has more than one non-NA entry
# collapseCols(redundant[1:3,]) # Expected behaviour: return a vector containing 1 2 3


# ==============================================================================
# Get necessary information ----------------------------------------------------
# ==============================================================================

## Get IDs of reports whose cost was already calculated-- don't calculate twice!
#   This code doesn't execute when:
#     * CYCLEEND < 2019 (there were no cost calculations before 2019)
#     * A side effect of this is that old_costs is set to NULL for the test
#       cases-- which is good! don't compare test outputs to real output file
if (CYCLEEND > 2019) {
  old_costs <- read.csv(paste0(RUNPATH, "cost_estimates-NOT-UPDATED.csv"))
  old_ids <- old_costs$treatmentid
  rm(old_costs)
} else {
  old_ids <- NULL
}

## Get management reports whose *reject_cost designation is FALSE and that
#  don't yet have a cost estimate
cost_reports <- man_issues[man_issues$manage_year %in% CYCLE &
  !man_issues$autoreject_cost &
  !man_issues$coordreject_cost &
  !man_issues$treatmentid %in% old_ids, "treatmentid"]
man_costs <- man_data[man_data$treatmentid %in% cost_reports, ]

# Added 2025-09-17: 
# Remove multiple application dates - this was causing problems with duplicating
# cost for each application date. It seems like calculate-costs used to work
# okay before ~2022, but after that it started adding the costs together for
# multiple rows. I do not have commit history from before this time, so I am not
# sure what in the code changed. As a quick and easy fix, I will just reduce the
# dataframe to one row per management report.
man_costs <- do.call(rbind, lapply(split(man_costs, man_costs$treatmentid), head, 1))

## Define constants for labor cost, fuel cost ----------------------------------
#  (herbicide is more complicated, so it's getting merged into man_costs below
#  The database refers to herbicides with a code rather than a product name, and
#  some products have more than one code depending on whether they appear in
#  "imazproduct" or "glyphplusaddedproduct")
#
#  Since these constants are default values for the cost calculation functions
#  that go a couple layers deep, put them into the global environment so the
#  functions can find them. Not the best practice, but faster and more
#  immediately reliable than putting them into each function call as arguments.
#  If you move them back to the local scope, be sure to change the environment
#  argument in the call to rm()
##

# labor cost
cost.student <<- COST_CONSTS[
  COST_CONSTS$type == "human" &
    COST_CONSTS$name == "student",
  "cost_per_unit"
]
cost.volunteer <<- COST_CONSTS[
  COST_CONSTS$type == "human" &
    COST_CONSTS$name == "volunteer",
  "cost_per_unit"
]
cost.seasonal.employee <<- COST_CONSTS[
  COST_CONSTS$type == "human" &
    COST_CONSTS$name == "seasonal",
  "cost_per_unit"
]
cost.fulltime.employee <<- COST_CONSTS[
  COST_CONSTS$type == "human" &
    COST_CONSTS$name == "full",
  "cost_per_unit"
]
# Category not included: "Other". too vague for us to estimate cost

# fuel cost
cost.gas <<- COST_CONSTS[COST_CONSTS$type == "fuel" &
  COST_CONSTS$name == "gas", "cost_per_unit"]
cost.diesel <<- COST_CONSTS[COST_CONSTS$type == "fuel" &
  COST_CONSTS$name == "diesel", "cost_per_unit"]
cost.jetfuel <<- COST_CONSTS[COST_CONSTS$type == "fuel" &
  COST_CONSTS$name == "jet", "cost_per_unit"]
cost.avgas <<- COST_CONSTS[COST_CONSTS$type == "fuel" &
  COST_CONSTS$name == "avgas", "cost_per_unit"]
cost.electricity <<- COST_CONSTS[
  COST_CONSTS$type == "electricity" &
    COST_CONSTS$name == "electricity",
  "cost_per_unit"
]

# Surfactant cost
# We use a single cost estimate for surfactant since the product is not a 
# required field on the web hub. Note that surfactant costs were added to the 
# model code and cost constants between the the 2022 and 2023 model runs, so 
# this value was not added to costs from the official model runs conducted from
# 2018-2022. Here we add backward compatibility for the old model runs by 
# setting cost = 0 if it doesn't appear in the old cost constant files.  
if("surfactant" %in% COST_CONSTS$type){
  cost.surfactant <<- COST_CONSTS[
    COST_CONSTS$type == "surfactant" &
      COST_CONSTS$name == "surfactant",
    "cost_per_unit"
  ]
} else {
  cost.surfactant <- 0
}

# Note: find-manage-issues.R checked whether any of these values is missing when
#       the model run was created. All management reports whose costs depend
#       upon the missing values have been dropped from man_costs
#
#       Missing values should appear here as either an empty vector
#       ( numeric(0) ) or NA


# ==============================================================================
# Merge area & herbicide cost constants into man_costs
#
# SKIP THIS WHEN TESTING
# ==============================================================================

# MU area
man_costs <- merge(man_costs, enroll_data[, c("munitid", "area")],
  by.x = "munitid", by.y = "munitid", all.x = TRUE
)

# This has to happen before I collapse the herbicide trade names columns because
# those columns use codes to refer to the different trade names & the meaning of
# each code depends upon which column it's in

man_costs <- merge(man_costs, COST_CONSTS[
  COST_CONSTS$type == "glyphosate" & !is.na(COST_CONSTS$herb_code),
  c("herb_code", "cost_per_unit")
],
by.y = "herb_code", by.x = "glyphproduct", all.x = TRUE
)
colnames(man_costs)[which(colnames(man_costs) == "cost_per_unit")] <- "glyphprice"

man_costs <- merge(man_costs, COST_CONSTS[
  COST_CONSTS$type == "imazapyr" & !is.na(COST_CONSTS$herb_code),
  c("herb_code", "cost_per_unit")
],
by.y = "herb_code", by.x = "imazproduct", all.x = TRUE
)
colnames(man_costs)[which(colnames(man_costs) == "cost_per_unit")] <- "imazprice"

man_costs <- merge(man_costs, COST_CONSTS[
  COST_CONSTS$type == "glyphosate" & !is.na(COST_CONSTS$herb_code),
  c("herb_code", "cost_per_unit")
],
by.y = "herb_code", by.x = "glyphplusproduct", all.x = TRUE
)
colnames(man_costs)[which(colnames(man_costs) == "cost_per_unit")] <- "glyphplusprice"

man_costs <- merge(man_costs, COST_CONSTS[
  COST_CONSTS$type == "added",
  c("herb_code", "cost_per_unit")
],
by.y = "herb_code", by.x = "glyphplusaddedname", all.x = TRUE
)
colnames(man_costs)[which(colnames(man_costs) == "cost_per_unit")] <- "glyphplusaddedprice"

# ==============================================================================
# Collapse redundant columns ---------------------------------------------------
#
# Management reports for different actions include many of the same information
# types, e.g. notes, minimum amount of gasoline used. The database splits each
# of these response types into different columns (one for each action),
# e.g. "glyphnotes", "imaznotes", "glyphplusnotes", "restnotes", etc.
#
# This leads to an extremely wide data set with subsets of columns  (e.g. *notes)
# whose rows contain at most one non-NA value (per subset). From a cost
# calculation perspective, this configuration necessitates that we make
# different function calls to access the same equations (e.g. once with
# arguments glyphdieselmin & glyphdieselmax, once with imazdieselmin &
# imazdieselmax... and so forth).
#
# Here, I collapse the columns that are split across management actions into a
# single column per response type, so that we need fewer redundant function
# calls.
#
# SKIP THIS WHEN TESTING
# ==============================================================================

## Herbicide columns -----------------------------------------------------------
# Herbicide trade name
herbprod_cols <- c("glyphproduct", "imazproduct", "glyphplusproduct")
herbproduct <- collapseCols(man_costs[, herbprod_cols])

# Herbicide price
herbprice_cols <- c("glyphprice", "glyphplusprice", "imazprice")
herbprice <- collapseCols(man_costs[, herbprice_cols])

# Concentration of herbicide in final mix
conc_cols <- c(
  "glyphconcentrationpercent", "glyphplusconcentrationpercent",
  "imazconcentrationpercent"
)
herbconcentration <- collapseCols(man_costs[, conc_cols])

# Concentration of surfactant in the final mix
surf_cols <- c(
  "glyphsurfactantpercent", "glyphplussurfactantpercent",
  "imazsurfactantpercent"
)
surfconcentration <- collapseCols(man_costs[, surf_cols])

# Herbicide volumes
vol_cols <- c("glyphvolume", "imazvolume", "glyphplusvolume")
herbmixvolume <- collapseCols(man_costs[, vol_cols])

herb_question_cols <- c("glyphherbicidevalues", "imazherbicidevalues", "glyphplusherbicidevalues")
if(all(herb_question_cols %in% names(man_costs))){
  herbquestion <- collapseCols(man_costs[, herb_question_cols])
}

herb_acre_cols <- c("glyphvolumeherbicideacre", "imazvolumeherbicideacre", "glyphplusvolumeherbicideacre")
if(all(herb_acre_cols %in% names(man_costs))){
  herbacres <- collapseCols(man_costs[, herb_acre_cols])
}

surf_acre_cols <- c("glyphvolumesurfactantacre", "imazvolumesurfactantacre", "glyphplusvolumesurfactantacre")
if(all(surf_acre_cols %in% names(man_costs))){
  surfacres <- collapseCols(man_costs[, surf_acre_cols])
}

herb_value_cols <- c("glyphareavolumeapplied", "imazareavolumeapplied", "glyphplusareavolumeapplied")
if(all(herb_value_cols %in% names(man_costs))){
treatareaherb <- collapseCols(man_costs[, herb_value_cols])
}

herb_acrestreated_cols <- c("glyphacresvolume", "imazacresvolume", "glyphplusacresvolume")
if(all(herb_acrestreated_cols %in% names(man_costs))){
herbacrestreated <- collapseCols(man_costs[, herb_acrestreated_cols])
}

## Gas columns -----------------------------------------------------------------
# Gasoline
gasmin_cols <- c(
  "glyphgasmin", "imazgasmin", "glyphplusgasmin", "floodgasmin",
  "pregasmin", "removegasmin", "mechgasmin", "cutgasmin"
)
gasmax_cols <- c(
  "glyphgasmax", "imazgasmax", "glyphplusgasmax", "floodgasmax",
  "pregasmax", "removegasmax", "mechgasmax", "cutgasmax"
)
gasmin <- collapseCols(man_costs[, gasmin_cols])
gasmax <- collapseCols(man_costs[, gasmax_cols])


# Diesel
dieselmin_cols <- c(
  "glyphdieselmin", "imazdieselmin", "glyphplusdieselmin",
  "flooddieselmin", "predieselmin", "removedieselmin",
  "mechdieselmin", "cutdieselmin"
)
dieselmax_cols <- c(
  "glyphdieselmax", "imazdieselmax", "glyphplusdieselmax",
  "flooddieselmax", "predieselmax", "removedieselmax",
  "mechdieselmax", "cutdieselmax"
)
dieselmin <- collapseCols(man_costs[, dieselmin_cols])
dieselmax <- collapseCols(man_costs[, dieselmax_cols])

# Jet Fuel
jetmin_cols <- c("glyphjetmin", "imazjetmin", "glyphplusjetmin")
jetmax_cols <- c("glyphjetmax", "imazjetmax", "glyphplusjetmax")
jetmin <- collapseCols(man_costs[, jetmin_cols])
jetmax <- collapseCols(man_costs[, jetmax_cols])

# Avgas
avgasmin_cols <- c("glyphavgasmin", "imazavgasmin", "glyphplusavgasmin")
avgasmax_cols <- c("glyphavgasmax", "imazavgasmax", "glyphplusavgasmax")
avgasmin <- collapseCols(man_costs[, avgasmin_cols])
avgasmax <- collapseCols(man_costs[, avgasmax_cols])


## Put together the more manageable dataset ------------------------------------
man_costs_temp <- cbind(
  man_costs[, c(
    "treatmentid", "munitid", "manage_year", "phase",
    "treatmethod", "treatarea", "area",
    "totalareatreated", "hirecontractor",
    "contractorcost", "rentequipment", "rentcost",
    "studenthours", "volunteerhours", "seasonalhours",
    "fullhours", "otherhours"
  )],
  herbproduct, herbconcentration, herbmixvolume, herbprice, surfconcentration,
  man_costs[, c(
    "glyphplusaddedname", "glyphplusaddedpercent",
    "glyphplusaddedprice"
  )],
  gasmin, gasmax, dieselmin, dieselmax, jetmin, jetmax, avgasmin,
  avgasmax,
  man_costs[, c(
    "floodtype", "floodcontrol", "floodwattagemin",
    "floodwattagemax", "floodpumphours"
  )]
)

# Add in the herbicide area columns if they exist in the dataset (post-2022)
if (all(herb_acre_cols %in% names(man_costs))) {
  man_costs_temp <- cbind(
    man_costs_temp,
    man_costs[, "glyphplusvolumeaddedacre"], herbacres, surfacres, 
    treatareaherb, herbacrestreated, herbquestion
  )
}

man_costs <- man_costs_temp

# ==============================================================================
# Correct data and update columns if needed ------------------------------------
# ==============================================================================

## Remove misplaced herbicide data 
# If a management web form is changed, the herbicide data in the columns added
# in March 2023 might be retained even if it is not supposed to be. To prevent
# duplicated data, remove data based on responses to *herbicidevalues column 
# (*name of herbicide):

# Choose the statement that best represents the information you have regarding herbicide application:
# 0 = I know the specific concentration and volume of herbicide and surfactant (PAMF's most preferred option)
# 1 = I know the volume of herbicide and surfactant applied per acre (PAMF's second best option)
# 2 = I do not know the rate at which herbicides were applied (PAMF's least preferred option)

if("herbquestion" %in% names(man_costs)){
  man_costs$herbconcentration <- ifelse(
    man_costs$herbquestion %in% c(1,2), NA, man_costs$herbconcentration
    )
  
  man_costs$surfconcentration <- ifelse(
    man_costs$herbquestion %in% c(1,2), NA, man_costs$surfconcentration
    )
  
  man_costs$glyphplusaddedpercent <- ifelse(
    man_costs$herbquestion %in% c(1,2), NA, man_costs$glyphplusaddedpercent
    )
  
  man_costs$herbmixvolume <- ifelse(
    man_costs$herbquestion %in% c(1,2), NA, man_costs$herbmixvolume
    )
  
  man_costs$herbacres <- ifelse(
    man_costs$herbquestion == 0, NA, man_costs$herbacres
    )
  
  man_costs$surfacres <- ifelse(
    man_costs$herbquestion == 0, NA, man_costs$surfacres
    )
  
  man_costs$glyphplusvolumeaddedacre <- ifelse(
    man_costs$herbquestion == 0, NA, man_costs$glyphplusvolumeaddedacre
    )
}

# "treatarea" (i.e. whether the participant treated the MU exactly vs. less/more
# area) is now a required question on the Web Hub but it wasn't always. repair
# any instances where this column is NA but "totalareatreated" exists.
# i.e. report 414 from 2018
man_costs[
  is.na(man_costs$treatarea) & !is.na(man_costs$totalareatreated),
  "treatarea"
] <- 2

## Combine the treatarea and treatareaherb columns if treatareaherb does exist
# treatareaherb added to the database in March 2023, ELSE 
# If the updated herbicide area columns are missing (e.g., pre-2023) then
# assume the area treated with herbicide is the same as the the size of the area
# treated for the rest of the costs and fill in "NA" for the rest of the data

if ("treatareaherb" %in% names(man_costs)) {
  man_costs$treatareaherb <- ifelse(is.na(man_costs$treatareaherb),
    man_costs$treatarea,
    man_costs$treatareaherb
  )
  man_costs$herbacrestreated <- ifelse(is.na(man_costs$herbacrestreated),
    man_costs$totalareatreated,
    man_costs$herbacrestreated
  )
} else {
  man_costs$treatareaherb <- man_costs$treatarea
  man_costs$herbacrestreated <- man_costs$totalareatreated
  man_costs$herbacres <- NA
  man_costs$surfacres <- NA
  man_costs$glyphplusvolumeaddedacre <- NA
}


# clean up
suppressWarnings(rm(
  man_costs_temp, herbprod_cols, vol_cols, herb_acre_cols, 
  herb_acrestreated_cols, herb_value_cols, conc_cols, gasmin_cols, gasmax_cols,
  dieselmin_cols, dieselmax_cols, jetmin_cols, jetmax_cols, avgasmin_cols,
  avgasmax_cols, herbproduct, herbconcentration, herbmixvolume, gasmin,
  gasmax, dieselmin, dieselmax, jetmin, jetmax, avgasmin, avgasmax, herbprice,
  herbprice_cols, herbacrestreated, treatareaherb, surfacres, herbacres,
  herbquestion
))

# ==============================================================================
# Create empty dataframe to store costs from the current cycle -----------------
# ==============================================================================

current_costs <- data.frame(
  treatmentid = numeric(0), munitid = numeric(0),
  phase = numeric(0), treatmethod = numeric(0),
  contract = logical(0), rent = logical(0),
  total_cost = numeric(0), cost_per_acre = numeric(0)
)


# ==============================================================================
# Divide up cost data by which equation needed to calculate cost ---------------
# ==============================================================================

# Contractor
contract_reports <- man_costs[!is.na(man_costs$hirecontractor) &
  man_costs$hirecontractor == 1, ]

# subset of data where hirecontractor!=1
other_reports <- man_costs[is.na(man_costs$hirecontractor) |
  man_costs$hirecontractor != 1, ]

# Herbicide reports
herb_reports <- other_reports[other_reports$treatmethod %in%
  c(GLYPH$db, IMAZ$db, GLYPHPLUS$db), ]

# Mechanical (includes cut underwater, spading)
mcs_reports <- other_reports[other_reports$treatmethod %in% c(
  CUT$db, SPADING$db,
  PRECLEAR$db,
  MECHREMOVE$db,
  MECHLEAVE$db
), ]

handmcs_reports <- mcs_reports[(is.na(mcs_reports$gasmin & mcs_reports$gasmax) |
  (mcs_reports$gasmin == 0 & mcs_reports$gasmax == 0)) &
  (is.na(mcs_reports$dieselmin &
    mcs_reports$dieselmax) |
    (mcs_reports$dieselmin == 0 &
      mcs_reports$dieselmax == 0)), ]

fuelmcs_reports <- mcs_reports[((!is.na(mcs_reports$gasmin) & mcs_reports$gasmin > 0) &
  (!is.na(mcs_reports$gasmax) & mcs_reports$gasmax > 0)) |
  ((!is.na(mcs_reports$dieselmin) &
    mcs_reports$dieselmin > 0) &
    (!is.na(mcs_reports$dieselmax) &
      mcs_reports$dieselmax > 0)), ]

# Flooding
flood_reports <- other_reports[other_reports$treatmethod == FLOOD$db, ]

floodpassive_reports <- flood_reports[(!is.na(flood_reports$floodtype == 1) &
  flood_reports$floodtype == 1) |
  (!is.na(flood_reports$floodcontrol) &
    flood_reports$floodcontrol == 0), ]
floodactive_reports <- flood_reports[!is.na(flood_reports$floodcontrol) &
  flood_reports$floodcontrol > 0, ]

# The only remaining treatmethods are:
# * 3  : Rest
# * 10 : OTHER
# and we've already dropped then from the data set because we don't calculate
# costs for either


# ==============================================================================
# Apply cost functions and build up current_costs ------------------------------
# ==============================================================================

## Contractor ------------------------------------------------------------------

contract_cost <- mapply(
  costOfContractor, contract_reports$contractorcost,
  contract_reports$treatarea, contract_reports$area,
  contract_reports$totalareatreated
)

current_costs <- rbind(
  current_costs,
  costRows(contract_cost, contract_reports, CYCLEEND)
)


## Herbicide -------------------------------------------------------------------

# Note that the herbicide concentrations refer to the concentration of a product
# in the total mix, not the concentration of the chemical in the product. So the
# costs of the two products in glyphosate+ actions are calculated off of the
# same total mix volume.

herb_cost <- mapply(costOfHerbicide, 
  cost_product = herb_reports$herbprice,
  concentration = herb_reports$herbconcentration,
  volume_mix = herb_reports$herbmixvolume, 
  cost_add_product = herb_reports$glyphplusaddedprice,
  concentration_add = herb_reports$glyphplusaddedpercent,
  volume_add_mix = herb_reports$herbmixvolume, 
  surf_concentration = herb_reports$surfconcentration, 
  volume_surf_mix = herb_reports$herbmixvolume,
  volume_acre = herb_reports$herbacres,
  volume_acre_add = herb_reports$glyphplusvolumeaddedacre, 
  volume_acre_surf = herb_reports$surfacres, 
  min_gas = herb_reports$gasmin,
  max_gas = herb_reports$gasmax, 
  min_diesel = herb_reports$dieselmin,
  max_diesel = herb_reports$dieselmax, 
  min_jet = herb_reports$jetmin,
  max_jet = herb_reports$jetmax, 
  min_avgas = herb_reports$avgasmin,
  max_avgas = herb_reports$avgasmax, 
  cost_equip_rental = herb_reports$rentcost,
  hours_student = herb_reports$studenthours, 
  hours_volunteer = herb_reports$volunteerhours,
  hours_seasonal_employee = herb_reports$seasonalhours,
  hours_fulltime_employee = herb_reports$fullhours,
  treat_area = herb_reports$treatarea,
  MU_area = herb_reports$area,
  total_area = herb_reports$totalareatreated, 
  treat_area_herb = herb_reports$treatareaherb,
  total_area_herb = herb_reports$herbacrestreated,
  MoreArgs = list(
    cost_gas = cost.gas, cost_diesel = cost.diesel,
    cost_jet = cost.jetfuel, cost_avgas = cost.avgas,
    cost_student = cost.student,
    cost_volunteer = cost.volunteer,
    cost_seasonal_employee = cost.seasonal.employee,
    cost_fulltime_employee = cost.fulltime.employee,
    cost_surfactant = cost.surfactant
  )
)

current_costs <- rbind(current_costs, costRows(herb_cost, herb_reports, CYCLEEND))


## Mechanical, Cut Underwater, Spading -----------------------------------------

fuelmcs_cost <- mapply(costOfBiomassWEquipment, fuelmcs_reports$gasmin,
  fuelmcs_reports$gasmax, fuelmcs_reports$dieselmin,
  fuelmcs_reports$dieselmax, fuelmcs_reports$jetmin,
  fuelmcs_reports$jetmax, fuelmcs_reports$avgasmin,
  fuelmcs_reports$avgasmax, fuelmcs_reports$rentcost,
  fuelmcs_reports$studenthours,
  fuelmcs_reports$volunteerhours,
  fuelmcs_reports$seasonalhours, fuelmcs_reports$fullhours,
  fuelmcs_reports$treatarea, fuelmcs_reports$area,
  fuelmcs_reports$totalareatreated,
  MoreArgs = list(
    cost_gas = cost.gas, cost_diesel = cost.diesel,
    cost_jet = cost.jetfuel,
    cost_avgas = cost.avgas,
    cost_student = cost.student,
    cost_volunteer = cost.volunteer,
    cost_seasonal_employee = cost.seasonal.employee,
    cost_fulltime_employee = cost.fulltime.employee
  )
)

# now write into the data frame
current_costs <- rbind(current_costs, costRows(
  fuelmcs_cost, fuelmcs_reports,
  CYCLEEND
))


handmcs_cost <- mapply(
  costOfHandRemoval, handmcs_reports$studenthours,
  handmcs_reports$volunteerhours,
  handmcs_reports$seasonalhours,
  handmcs_reports$fullhours, handmcs_reports$treatarea,
  handmcs_reports$area, handmcs_reports$totalareatreated
)

# now write into the data frame
current_costs <- rbind(current_costs, costRows(
  handmcs_cost, handmcs_reports,
  CYCLEEND
))


## Flood -----------------------------------------------------------------------

# costOfActiveFlood possibly affected by fuel update
active_cost <- mapply(costOfActiveFlood, floodactive_reports$gasmin,
  floodactive_reports$gasmax, floodactive_reports$dieselmin,
  floodactive_reports$dieselmax, floodactive_reports$jetmin,
  floodactive_reports$jetmax, floodactive_reports$avgasmin,
  floodactive_reports$avgasmax,
  floodactive_reports$floodpumphours,
  floodactive_reports$floodwattagemin,
  floodactive_reports$floodwattagemax,
  floodactive_reports$studenthours,
  floodactive_reports$volunteerhours,
  floodactive_reports$seasonalhours,
  floodactive_reports$fullhours,
  floodactive_reports$treatarea, floodactive_reports$area,
  floodactive_reports$totalareatreated,
  MoreArgs = list(
    cost_gas = cost.gas, cost_diesel = cost.diesel,
    cost_jet = cost.jetfuel, cost_avgas = cost.avgas,
    cost_electricity = cost.electricity,
    cost_student = cost.student,
    cost_volunteer = cost.volunteer,
    cost_seasonal_employee = cost.seasonal.employee,
    cost_fulltime_employee = cost.fulltime.employee
  )
)

# now write into the data frame
current_costs <- rbind(current_costs, costRows(
  active_cost, floodactive_reports,
  CYCLEEND
))


passive_cost <- mapply(
  costOfPassiveFlooding, floodpassive_reports$studenthours,
  floodpassive_reports$volunteerhours,
  floodpassive_reports$seasonalhours,
  floodpassive_reports$fullhours
)

# now write into the data frame
current_costs <- rbind(current_costs, costRows(
  passive_cost, floodpassive_reports,
  CYCLEEND
))
current_costs <- current_costs[order(current_costs$munitid), ]


# Drop all rows whose cost is zero.
# Possible reasons why cost may be zero:
# * contractor charges $0
# * area managed = 0 acres
# * labor cost, herbicide cost, rental cost and fuel cost are all zero
# * natural flood
# The first three cases are unrealistic with regards to invasive species
# management. The fourth (natural flood) will always have zero cost, so it
# doesn't need to be in there either
current_costs <- current_costs[current_costs$total_cost > 0, ]


# ==============================================================================
# Check for Multiples ----------------------------------------------------------
# i.e. sets of more than one treatment report referring to the same MU, phase,
# and treatmethod
# This is possible because we have told participants that it's totally fine to
# do as many reports as they feel are necessary. Since this spreads the cost of
# the management action across several reports, the costs in each report aren't
# comparable to the costs in a single-report management action. Aggregate all
# multiples for each MU/phase/action combination into a single cost
# ==============================================================================

# Split the data frame by MU, phase, and treatmethod. Calculate the column sums
# of each piece, and pull out the cost sums. For MU/phase/treatmethod with one
# report, this cost will be the same as before. For those with multiples, cost
# will be summed across the multiples.
cost_split <- split(current_costs, current_costs[, c(
  "munitid", "phase",
  "treatmethod"
)])
col_sums <- lapply(cost_split, colSums, na.rm = TRUE)
sums_frame <- data.frame(do.call(rbind, col_sums))
summed_totals <- sums_frame$total_cost[which(sums_frame$total_cost > 0)]
summed_peracre <- sums_frame$cost_per_acre[which(sums_frame$cost_per_acre > 0)]
# Since all 0 costs have been removed, any summed_costs==0 indicate an empty
# list element

# Re-create current_costs with each set of multiples represented by one row
cc2_rows <- lapply(cost_split, head, n = 1)
cc2 <- data.frame(do.call(rbind, cc2_rows), row.names = c())

cc2$total_cost <- summed_totals
cc2$cost_per_acre <- summed_peracre

current_costs <- cc2[, colnames(cc2)[colnames(cc2) != "phase"]]
current_costs <- current_costs[order(current_costs$munitid), ]

## Create a column designating the cycle for which the cost was calculated
pamf_cycle <- rep(CYCLEEND, nrow(current_costs))
current_costs <- cbind(current_costs, pamf_cycle)

# Round the final costs to 2 decimal places
current_costs$total_cost <- round(current_costs$total_cost, 2)
current_costs$cost_per_acre <- round(current_costs$cost_per_acre, 2)

# ==============================================================================
# FOR TESTING - COMPARE RESULTS ------------------------------------------------
# ==============================================================================

# # UNCOMMENT TO SEE HOW TESTS PERFORMED
# check_tests <- merge(man_data[, c(1:4)], current_costs, all.x = TRUE)
# check_tests$all_expected_behaviour <- check_tests$expected_behaviour
# check_tests <- within(
#   check_tests, expected_behaviour <- data.frame(
#     do.call("rbind", strsplit(
#       as.character(expected_behaviour), ", ",
#       fixed = TRUE
#     ))
#   )
# )
# check_tests$Expected_Total_cost <- check_tests$expected_behaviour$X1
# check_tests$Expected_Per_acre_cost <- check_tests$expected_behaviour$X2
# check_tests$expected_behaviour <- NULL
# check_tests$Expected_Total_cost <- as.numeric(regmatches(
#   check_tests$Expected_Total_cost,
#   gregexpr(
#     "[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?",
#     check_tests$Expected_Total_cost
#   )
# ))
# check_tests$Expected_Per_acre_cost <- as.numeric(regmatches(
#   check_tests$Expected_Per_acre_cost,
#   gregexpr(
#     "[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?",
#     check_tests$Expected_Per_acre_cost
#   )
# ))
# check_tests$Diff_Total_cost <- ifelse(
#   check_tests$Expected_Total_cost == check_tests$total_cost, 0, 1
# )
# check_tests$Diff_Cost_per_acre <- ifelse(
#   check_tests$Expected_Per_acre_cost == check_tests$cost_per_acre, 0, 1
# )
# # Investigate check_tests
# rm(check_tests)

# ==============================================================================
# Clean up temporary variables -------------------------------------------------
# ==============================================================================
rm(
  other_reports, mcs_reports, flood_reports, contract_cost, contract_reports,
  herb_cost, herb_reports, fuelmcs_cost, fuelmcs_reports, handmcs_cost,
  handmcs_reports, passive_cost, floodpassive_reports, active_cost,
  floodactive_reports, cost_split, col_sums, sums_frame, summed_totals,
  summed_peracre, cc2_rows, cc2, pamf_cycle
)

suppressWarnings(rm(cost.avgas, cost.diesel, cost.electricity, cost.fulltime.employee, cost.gas,
  cost.jetfuel, cost.seasonal.employee, cost.student, cost.volunteer, 
  cost.surfactant, envir = .GlobalEnv
))
