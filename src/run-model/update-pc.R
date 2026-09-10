# 30 April 2019
#
# This script updates the partial controllability matrix using the same 
# methodology as the transition matrix updates. Partial controllability
# quantifies the likelihood that participants carry out a particular management
# combination X, when the guidance recommended combination Y.
# Note the (hopefully) likely possibility that X==Y!
#
# This script compares each MU's current-cycle  reported actions against the
# guidance given at the end of the previous cycle. This is more reliable than 
# the 'treatbymodel' column responses, which are self-reported.
#
# NOTE: The partial controllability matrix only contains information about 
#        participants' ability to implement August guidance. Partial 
#        controllability (PC) in MCFG and lag-year guidance may respond to 
#        different factors, so we don't want to mix them into the same PC matrix.
#        Additionally, since MCFG and lag-year guidance are not meant to be used
#        widely, the increased complexity of including two more PC matrices is
#        not worth the gains at this time
#
#
# Sourced by: run-the-model.R
#
# DEPENDENCIES
# * Global Constants
#    CYCLEEND   : final year of the cycle being analyzed
#    PAMF_COMBS : management combination codes
#
# * Variables
#    datpak        : data packages from the cycle being analyzed
#    datpak_issues : potential issues with data packages belonging to datpak
#    prev_pc       : partial controllability matrix from previous cycle 
#                    (dataframe format)
#    prev_guidance : guidance released in the August priot to CYCLEEND
#
# * Functions
#   From general-functions.R:
#    repairSums
#   From pc-update-functions.R:
#    ma2mc
#    getCountsPC
#
# ASSUMPTIONS
# * No management combinations appear in the management reports that do not
#   also appear in the previous cycle's partial controllability matrix
##

# # ============================================================================
# #  Uncomment this section for script testing
# # ============================================================================
# message(">>> USING TEST DATA FOR PARTIAL CONTROLLABILITY UPDATE <<<")
# options(stringsAsFactors=FALSE)
# 
# ## Get functions, constants, and data
# source("./src/global-constants.R")
# source("./src/general-functions.R")
# source("./src/run-model/pc-update-functions.R")
# 
# CYCLEEND=2525
# 
# # table format of a matrix with all entries == 0
# prev_pc=read.csv("./src/run-model/test-cases/pc-update/pc-initial-table.csv")
# 
# # data packages
# datpak = read.csv("./src/run-model/test-cases/pc-update/datpak.csv")
# datpak_issues = read.csv("./src/run-model/test-cases/pc-update/datpak_issues.csv")
# prev_guidance = read.csv("./src/run-model/test-cases/pc-update/guidance.csv")
# 
# ## Run the script below.
# # Afterward, type convertPC(pc_table, transitions=FALSE) to display a matrix 
# # of concentration values.
# # If the script is working properly, it should have:
# #  * ones along the diagonal, except for
# #  * ones across the GRG row
# ##

# ==============================================================================
#  Get current-cycle data packages for MUs that received guidance at the end of
#  the previous cycle (i.e. datpak_issues$autoreject_partcontrol==FALSE)
# ==============================================================================

datpak_mus = datpak_issues[datpak_issues$cycle_end==CYCLEEND & 
                             !datpak_issues$autoreject_partcontrol, "munitid"]
observed = datpak[datpak$cycle_end==CYCLEEND & datpak$munitid %in% datpak_mus,]
observed = observed[order(observed$mnt_comb),]


# ==============================================================================
#  Compare implemented vs. recommended combinations
# ==============================================================================
# Build a data frame with the following information:
# * munitid
# * recommended combination (from previous August guidance)
# * implemented combination (what was actually done)
#
# This data frame will contain records for managment units that have complete 
# and valid data packages. This helps us keep track of participants' decisions 
# to use a different PAMF combination than the optimal one.
#
# The partial controllability matrix *does not* keep track of instances where 
# participants received guidance and did not implement a PAMF combination. 
# Since non-PAMF combinations are never recommended, 'OTHER' combinations would 
# pull probability weight off of the diagonal every time they're observed. With 
# enough observations, 'OTHER' can prevent PAMF combinations from appearing in 
# the optimal guidance (we learned the hard way)
##

mnt_comb = observed$mnt_comb
mu_ids   = observed$munitid

mnt_compare = data.frame(munitid=mu_ids, implemented=mnt_comb)

# Get optimal managment actions for each MU in observed
mu_guidance = prev_guidance[prev_guidance$munitid %in% datpak_mus & 
                              prev_guidance$optimal,]

# Get guidance (recommended combinations) for each management unit in recs
guid_comb = unlist(mapply(ma2mc, mu_guidance$transrec, mu_guidance$dormrec, 
                          mu_guidance$growrec, 
                         MoreArgs=list(PAMF_COMBS)))
mu_guidance = cbind(mu_guidance, guid_comb)

# Add recommended combinations to mnt_compare
mnt_compare = merge(mnt_compare, mu_guidance[,c("munitid", "guid_comb")])

# clean up
rm(mu_ids, mnt_comb, mu_guidance, guid_comb)


# ==============================================================================
# Update pc_matrix$concentrations with the number of times that each
# intended/implemented pair appears in mnt_compare
# ==============================================================================

# The partial controllability matrix is updated using the same method as we used
# to update the transition matrices. In this case, guidance is analogous to
# starting state, and the implemented management combination is analogous to the
# ending state.
#
# This is a simpler case than the transition matrices, however, because:
#   * There's only one matrix
#   * No recorded uncertainty --> each observation only updates one concentration
#                                 value
#
# As in the transition matrix updates, I'm using a loop to move observations
# into the data frame where I use them. The reason for this is that I haven't
# come up with an elegant way to use lapply() (or mapply()) to make these updates.
#
# If I take a direct approach, the maximum number of iterations in the loop
# is the number of observations. But R loops are slow, and the number of
# observations will increase as PAMF grows.
#
# To reduce the number of iterations, I'll count the number of times each type
# of observation appears using faster methods before implementing the loop.
# This will limit the number of iterations to the number of observation
# types, which <= the number of observations.
#
# The upper limit on iterations is the number of rows in pc_table. It's unlikely
# that we'll hit this maximum, however, because it's unlikely see permutations of
# every recommendation with every possible PAMF combination in the data.
##

# First, replace all implemented non-PAMF combinations with OTHER
mnt_compare[which(! mnt_compare$implemented %in% PAMF_COMBS$mnt_comb), 
            "implemented"] = "OTHER"

# Count the number of times that each pair of intended/implemented combinations
# appears in mnt_compare.
# Drop extraneous columns and sort mnt_compare into blocks of identical rows
mc2 = mnt_compare[order(mnt_compare$guid_comb, mnt_compare$implemented), 
                  c("guid_comb", "implemented")]

# get indices of the rows where each block of counts starts and ends
block_starts = which(!duplicated(mc2))
block_ends   = c(block_starts[2:length(block_starts)], nrow(mc2)+1)-1

# Count the number of rows in each block & keep track of which intended/implemented
# combinations those counts go with
counts_list = mapply(getCountsPC, block_starts, block_ends, MoreArgs = list(mc2), 
                     SIMPLIFY = FALSE)
counts_df   = data.frame(do.call(rbind, counts_list))

# update the cycle column
pc_table = prev_pc
pc_table$cycle_used = CYCLEEND

# Update the concentrations in the partial controllability matrix
for(i in 1:nrow(counts_df)) {
  guid_comb    = counts_df$guid_comb[i]
  implemented  = counts_df$implemented[i]
  counts       = counts_df$count[i]
  
  pc_table[pc_table$mnt_intended==guid_comb & 
             pc_table$mnt_implemented==implemented, "concentration"] = 
    pc_table[pc_table$mnt_intended==guid_comb & 
               pc_table$mnt_implemented==implemented, "concentration"] + counts
} # end for


# Now update the probability that, given a recommended (intended) combination,
# each of the possible combinations will be implemented

# The partial controllability matrix is like a transition matrix between 
# recommended and implemented management combinations & its rows are defined by 
# what was recommended. As in the transition piece, each matrix row corresponds 
# to a block of rows in the data frame, each comprising one entry in the matrix. 
# Probabilities are updated row by row.
#
# Get vector of all recommended combinations that appear in the observed data
# (no need to do updates on ones that don't)
intended = unique(counts_df$guid_comb)

# update the probabilities
for(i in intended) {
  pc_row = pc_table[pc_table$mnt_intended==i,]
  
  # probability = concentration / (sum of concentrations)
  probs = pc_row$concentration / sum(pc_row$concentration)
  
  # repair the sum (rounding errors may bump it off of 1)
  probs = suppressWarnings(repairSums(probs))
  
  # Verify that repairSums did not succumb to its own rounding errors
  if(sum(probs)-1 != 0){
    warning("update-pc.R: Failure of repairSums!")
  }
  
  
  # write into the pc table
  pc_table[pc_table$mnt_intended==i,"probability"] = probs
  
}

# convert from data frame format to matrix format
pc_matrix = convertPC(pc_table)


# ==============================================================================
#  Clean up
# ==============================================================================

rm(mc2, block_starts, block_ends, counts_list, counts_df, intended, implemented, 
   counts, pc_row, probs, mnt_compare)