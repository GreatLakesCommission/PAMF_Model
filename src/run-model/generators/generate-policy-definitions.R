
# 7/30/2018
#
# This script generates the policy_definitions data frame and saves it to
# a .csv file.
#
# policy_definitions provides IDs for the different policy restrictions
# (e.g. no flood, no herbicide), and stores the management combinations
# (coded in the style of the model, not the database) associated with
# each policy restriction.
#
# THERE ARE CURRENTLY three types of policy restrictions (in addition to
# the unrestricted policy):
#  * No Flood : Flood control not possible
#  * No Herb  : Herbicide application not possible
#  * No Cut   : Cut Underwater not possible
#
# In addition, a management unit may be subject to any combination of these
# restrictions. Usable actions are represented in the management unit table
# of the PAMF database in the following columns:
#  * herbicide    (1=YES, 0=NO)
#  * cut          (1=YES, 0=NO)
#  * controlwater (1=YES, 0=NO)
#
# I'm including these columns in the policy definitions table to make
# it easy to look up which MUs are subject to which restriction type
#
# RUN THIS SCRIPT WHEN
#  * Management combinations are added or removed
#  * Policy restrictions are added or removed
#  * If management combinations change
#
# When policy restrictions are changed, however, add a section to this
# script that's analogous to the restrictions are already here. If
# policy restrictions are removed, comment out the relevant section(s).

# ========================================================================
# Read Files
# ========================================================================

# Get IDs of all management combinations
mc_maps <- read.csv("./src/run-model/initial-inputs/management_combination_codes.csv")
pamf_combs <- mc_maps$mnt_code

# ========================================================================
# Generate a data frame for each policy restriction
# ========================================================================
# Note that restriction IDs are zero indexed. That's to line them up with
# the way that other factors are coded in the PAMF database (e.g. management
# actions are assigned integers 0-9)


# --- Restriction 0: Unrestricted ----------------------------------------

# This policy restriction is for management units (MUs) where any of the
# PAMF combinations may be used.

# Create data frame columns
n_combs <- length(pamf_combs)
restr_id <- rep(0, n_combs) # ID column
herbicide <- rep(1, n_combs) # YES herbicide
cut <- rep(1, n_combs) # YES cut underwater
controlwater <- rep(1, n_combs) # YES control water
mnt_comb <- pamf_combs # allowed management combinations
mnt_index <- 1:n_combs # the index of each management
# combination WHERE IT APPEARS IN
# pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest0 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# --- Restriction 1: No Flood --------------------------------------------

# This policy restriction is for management units (MUs) where participants
# cannot conrol flooding

# Get available management combinations for this case
# i.e. those that do not include management action 8 (which corresponds
# to 'flood' in the management reports)
noflood_combs <- mc_maps[
  mc_maps$db_tr != 8 & mc_maps$db_do != 8 & mc_maps$db_gr != 8,
  "mnt_code"
]
noflood_indices <- which(mc_maps$db_tr != 8 & mc_maps$db_do != 8 & mc_maps$db_gr != 8)

# Create data frame columns
n_combs <- length(noflood_combs)
restr_id <- rep(1, n_combs) # ID column
herbicide <- rep(1, n_combs) # YES herbicide
cut <- rep(1, n_combs) # YES cut underwater
controlwater <- rep(0, n_combs) # NO control water
mnt_comb <- noflood_combs # allowed management combinations
mnt_index <- noflood_indices # the index of each management
# combination WHERE IT APPEARS IN pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest1 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# --- Restriction 2: No Herb ---------------------------------------------

# This policy restriction is for management units (MUs) where herbicide
# cannot be used, e.g. over water in Ontario

# Get available management combinations for this case
all_codes <- unique(c(unique(mc_maps$db_tr), unique(mc_maps$db_do), unique(mc_maps$db_gr)))
noherb_codes <- setdiff(all_codes, c(0, 1, 2))
noherb_combs <- mc_maps[mc_maps$db_tr %in% noherb_codes &
  mc_maps$db_do %in% noherb_codes &
  mc_maps$db_gr %in% noherb_codes, "mnt_code"]
noherb_indices <- which(mc_maps$db_tr %in% noherb_codes &
  mc_maps$db_do %in% noherb_codes &
  mc_maps$db_gr %in% noherb_codes)

# Create data frame columns
n_combs <- length(noherb_combs)
restr_id <- rep(2, n_combs) # ID column
herbicide <- rep(0, n_combs) # NO herbicide
cut <- rep(1, n_combs) # YES cut underwater
controlwater <- rep(1, n_combs) # YES control water
mnt_comb <- noherb_combs # allowed management combinations
mnt_index <- noherb_indices # the index of each management
# combination WHERE IT APPEARS IN pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest2 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# --- Restriction 3: No Cut ----------------------------------------------

# This policy restriction is for management units (MUs) where site
# conditions do not allow for cutting underwater

# Get available management combinations for this case
# 4 is the database code for 'cut underwater'
nocut_combs <- mc_maps[
  mc_maps$db_tr != 4 & mc_maps$db_do != 4 & mc_maps$db_gr != 4,
  "mnt_code"
] # 4 is the database code for 'cut underwater'
nocut_indices <- which(mc_maps$db_tr != 4 & mc_maps$db_do != 4 & mc_maps$db_gr != 4)

# Create data frame columns
n_combs <- length(nocut_combs)
restr_id <- rep(3, n_combs) # ID column
herbicide <- rep(1, n_combs) # YES herbicide
cut <- rep(0, n_combs) # NO cut underwater
controlwater <- rep(1, n_combs) # YES control water
mnt_comb <- nocut_combs # allowed management combinations
mnt_index <- nocut_indices # the index of each management
# combination WHERE IT APPEARS IN
# pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest3 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# --- Restriction 4: No Flood No Herb ------------------------------------

# This policy restriction is for management units (MUs) where neither
# flood nor herbicide is possible

# Get available management combinations for this case
nofloodherb_combs <- intersect(noflood_combs, noherb_combs)
nofloodherb_indices <- intersect(noflood_indices, noherb_indices)

# Create data frame columns
n_combs <- length(nofloodherb_combs)
restr_id <- rep(4, n_combs) # ID column
herbicide <- rep(0, n_combs) # NO herbicide
cut <- rep(1, n_combs) # YES cut underwater
controlwater <- rep(0, n_combs) # NO control water
mnt_comb <- nofloodherb_combs # allowed management combinations
mnt_index <- nofloodherb_indices # the index of each management
# combination WHERE IT APPEARS IN
# pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest4 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# --- Restriction 5: No Flood No Cut -------------------------------------

# This policy restriction is for management units (MUs) where neither
# flood nor cut underwater is possible

# Get available management combinations for this case
nofloodcut_combs <- intersect(noflood_combs, nocut_combs)
nofloodcut_indices <- intersect(noflood_indices, nocut_indices)

# Create data frame columns
n_combs <- length(nofloodcut_combs)
restr_id <- rep(5, n_combs) # ID column
herbicide <- rep(1, n_combs) # YES herbicide
cut <- rep(0, n_combs) # NO cut underwater
controlwater <- rep(0, n_combs) # NO control water
mnt_comb <- nofloodcut_combs # allowed management combinations
mnt_index <- nofloodcut_indices # the index of each management
# combination WHERE IT APPEARS IN
# pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest5 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# --- Restriction 6: No Herb No Cut --------------------------------------

# This policy restriction is for management units (MUs) where neither
# herb nor cut underwater is possible

# Get available management combinations for this case
noherbcut_combs <- intersect(noherb_combs, nocut_combs)
noherbcut_indices <- intersect(noherb_indices, nocut_indices)

# Create data frame columns
n_combs <- length(noherbcut_combs)
restr_id <- rep(6, n_combs) # ID column
herbicide <- rep(0, n_combs) # NO herbicide
cut <- rep(0, n_combs) # NO cut underwater
controlwater <- rep(1, n_combs) # YES control water
mnt_comb <- noherbcut_combs # allowed management combinations
mnt_index <- noherbcut_indices # the index of each management
# combination WHERE IT APPEARS IN pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest6 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)

# --- Restriction 7: No Flood No Herb No Cut -----------------------------

# This policy restriction is for management units (MUs) where neither
# flood, herb, nor cut underwater is possible

# Get available management combinations for this case
nofloodherbcut_combs <- intersect(noflood_combs, noherbcut_combs)
nofloodherbcut_indices <- intersect(noflood_indices, noherbcut_indices)

# Create data frame columns
n_combs <- length(nofloodherbcut_combs)
restr_id <- rep(7, n_combs) # ID column
herbicide <- rep(0, n_combs) # NO herbicide
cut <- rep(0, n_combs) # NO cut underwater
controlwater <- rep(0, n_combs) # NO control water
mnt_comb <- nofloodherbcut_combs # allowed management combinations
mnt_index <- nofloodherbcut_indices # the index of each management
# combination WHERE IT APPEARS IN
# pamf_combs.
# mnt_index is necessary because the optimization.R uses MDPtoolbox,
# which requires data to be in array format. Matrices and arrays can't
# be subsetted using column names, only indices.

rest7 <- data.frame(restr_id, herbicide, cut, controlwater, mnt_comb, mnt_index)


# ========================================================================
# Combine data frames save to .csv
# ========================================================================

rest_all <- rbind(rest0, rest1, rest2, rest3, rest4, rest5, rest6, rest7)

write.csv(rest_all, paste("./src/run-model/initial-inputs/",
  Sys.Date(), ".csv",
  sep = ""
), row.names = FALSE)

# Final file to be used in the model should be moved to ./pamf-model/src/


# ========================================================================
# Clean up
# ========================================================================

# delete all variables created in this script
rm(
  wd, mc_maps, pamf_combs, n_combs, restr_id, herbicide, cut, controlwater,
  mnt_comb, mnt_index, noflood_combs, noflood_indices, noherb_combs,
  noherb_indices, nocut_combs, nocut_indices, nofloodherb_combs,
  nofloodherb_indices, nofloodcut_combs, nofloodcut_indices, noherbcut_combs,
  noherbcut_indices, nofloodherbcut_combs, nofloodherbcut_indices, rest0,
  rest1, rest2, rest3, rest4, rest5, rest6, rest7, rest_all
)
