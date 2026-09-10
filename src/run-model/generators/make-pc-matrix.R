# 8/6/2018
#
# Generate a partial controllability matrix The initial matrix going into the
# first year of the model will have ones on the diagonal and zeroes elsewhere,
# i.e. we start with the assumption that recommendations are always implemented.
#
# This prior can have any level of support; here it's coded to be equivalent to
# recommending each management combination once and observing that it was
# carried out as recommended each time. i.e., concentration = 1 for all cells on
# the diagonal and pseudocount = 0 elsewhere
#
# this is a totally arbitrary decision that can be adjusted downward for a less
# certain prior or upward for a more certain prior by dividing 'probabilities'
# by a number > 1 or a number < 1 respectively in line 52.


# ========================================================================
# Read files
# ========================================================================

# Set your working directory here:
# setwd(YOUR WORKING DIRECTORY)

# --- Definitions --------------------------------------------------------

mc_maps <- read.csv("./src/run-model/initial-inputs/management_combination_codes.csv")
pamf_combs <- mc_maps$mnt_code


# ========================================================================
# Create partial controllability matrix
# ========================================================================
n_combs <- 17 # number of PAMF combinations + OTHER
all_combs <- c(as.character(pamf_combs), "OTHER")

# --- Initial one for the model ------------------------------------------
# In matrix format:
pc_initial <- diag(1, n_combs, n_combs)
rownames(pc_initial) <- all_combs
colnames(pc_initial) <- all_combs

# Convert to data frame format for updating in future years:
mnt_intended <- rep(all_combs, times = 1, each = n_combs)
mnt_implemented <- rep(all_combs, times = n_combs)
probability <- as.vector(pc_initial)

# This column contains pseudocounts.
# Default decision is to give the weight of one observation to each row
# in the matrix (see above)
concentration <- probability

pc_initial_df <- data.frame(
  mnt_intended, mnt_implemented, probability,
  concentration
)


# --- Ones for Sensitivity Test ------------------------------------------

# SENSITIVITY 1
# Each recommended combination is implemented half of the time. The other
# half, all other combinations are chosen with equal probability
pr_rec <- 0.5
pr_other <- (1 - pr_rec) / (n_combs - 1)
pc_sens1 <- matrix(rep(pr_other, n_combs * n_combs), nrow = n_combs, ncol = n_combs)
pc_sens1 <- pc_sens1 + diag((pr_rec - pr_other), n_combs, n_combs)
rownames(pc_sens1) <- all_combs
colnames(pc_sens1) <- all_combs


# ========================================================================
# Write to File
# ========================================================================

write.csv(pc_initial, "./initial-inputs/pc_initial_matrix.csv")
write.csv(pc_initial_df, "./initial-inputs/pc_initial_table.csv", row.names = FALSE)

write.csv(pc_sens1, "./initial_inputs/pc_sens1.csv") # for sensitivity analysis only

# ========================================================================
# Clean up
# ========================================================================

# Remove variables
rm(
  wd, mc_maps, pamf_combs, n_combs, all_combs, pc_initial, mnt_intended,
  mnt_implemented, probability, pseudocount, pc_initial_df, pr_rec,
  pr_other, pc_sens1
)
