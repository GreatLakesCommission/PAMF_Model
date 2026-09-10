
# Create treatment_eff.csv -----------------------------------------------------
# # Uncomment this part of the script to transform the raw expert elicitation data
# # into the values needed for the rest of the code below. This originally was
# # done manually in Excel, but it has been replicated here for reproducibility.
# 
# treat <- read.csv("./src/run-model/initial-inputs/elicitation_data/treatment_eff_treat_raw.csv")
# posttreat <- read.csv("./src/run-model/initial-inputs/elicitation_data/treatment_eff_posttreat_raw.csv")
# 
# # NOTE: 
# # treatment_eff_treat_raw.csv represents efficacy as a percentage
# # treatment_eff_posttreat_raw.csv represents efficacy as a ranking, where 6 is 
# # the most effective, and 1 is the least effective. 
# 
# ## Calculate mean treat efficacy -----------------------------------------------
# treat <- treat %>% 
#   group_by(Treatment) %>% 
#   summarise(Mean_efficacy = mean(Herb_Percent_Efficacy, na.rm = TRUE))
# 
# ##  Calculate the post-treat efficacy ------------------------------------------
# posttreat <- posttreat %>% 
#   group_by(Treatment) %>% 
#   summarise(Mean_rank = mean(PostHerb_Efficacy_Rank, na.rm = TRUE))
# 
# # Substract by the RR score
# posttreat$Substract_RR_score <- posttreat$Mean_rank-posttreat$Mean_rank[which(posttreat$Treatment == "RR")]
# # Scale by RG score
# posttreat$Scale_by_RG_score <- posttreat$Substract_RR_score / posttreat$Substract_RR_score[which(posttreat$Treatment == "RG")]
# # Scale by G effectiveness in translocating phase
# posttreat$Scale_by_G_trans <- 0.01 * treat$Mean_efficacy[which(treat$Treatment == "G")] * posttreat$Scale_by_RG_score
# 
# ## Construct the final dataframe ----------------------------------------------
# treateff <- data.frame(
#   treatment = c(
#     "GRG", "G+PF", "GPF", "G+FF", "G+RR", "GFF", "G+LR",
#     "GLR", "G+BR", "IRR", "GBR", "GRR", "RPF", "RRR",
#     "CRC", "SRS"
#   ),
#   herb_eff = rep(NA, 16),
#   post_eff = rep(NA, 16)
# )
# 
# # Fill in herb_eff column
# treateff$herb_eff[which(treateff$treatment == "GRG")] <- treat$Mean_efficacy[which(treat$Treatment == "G")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "G+PF")] <- treat$Mean_efficacy[which(treat$Treatment == "G+")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "GPF")] <- treat$Mean_efficacy[which(treat$Treatment == "G")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "G+FF")] <- treat$Mean_efficacy[which(treat$Treatment == "G+")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "G+RR")] <- treat$Mean_efficacy[which(treat$Treatment == "G+")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "GFF")] <- treat$Mean_efficacy[which(treat$Treatment == "G")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "G+LR")] <- treat$Mean_efficacy[which(treat$Treatment == "G+")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "GLR")] <- treat$Mean_efficacy[which(treat$Treatment == "G")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "G+BR")] <- treat$Mean_efficacy[which(treat$Treatment == "G+")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "IRR")] <- treat$Mean_efficacy[which(treat$Treatment == "I")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "GBR")] <- treat$Mean_efficacy[which(treat$Treatment == "G")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "GRR")] <- treat$Mean_efficacy[which(treat$Treatment == "G")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "RPF")] <- 0
# treateff$herb_eff[which(treateff$treatment == "RRR")] <- 0
# treateff$herb_eff[which(treateff$treatment == "CRC")] <- treat$Mean_efficacy[which(treat$Treatment == "C")] * 0.01
# treateff$herb_eff[which(treateff$treatment == "SRS")] <- treat$Mean_efficacy[which(treat$Treatment == "S")] * 0.01
# # Round them to two places
# treateff$herb_eff <- round(treateff$herb_eff, 2)
# 
# # Fill in the post_eff column
# treateff$post_eff[which(treateff$treatment == "GRG")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "RG")]
# treateff$post_eff[which(treateff$treatment == "G+PF")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "PF")]
# treateff$post_eff[which(treateff$treatment == "GPF")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "PF")] 
# treateff$post_eff[which(treateff$treatment == "G+FF")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "FF")] 
# treateff$post_eff[which(treateff$treatment == "G+RR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "RR")] 
# treateff$post_eff[which(treateff$treatment == "GFF")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "FF")] 
# treateff$post_eff[which(treateff$treatment == "G+LR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "LR")] 
# treateff$post_eff[which(treateff$treatment == "GLR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "LR")] 
# treateff$post_eff[which(treateff$treatment == "G+BR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "BR")] 
# treateff$post_eff[which(treateff$treatment == "IRR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "RR")] 
# treateff$post_eff[which(treateff$treatment == "GBR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "BR")] 
# treateff$post_eff[which(treateff$treatment == "GRR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "RR")] 
# treateff$post_eff[which(treateff$treatment == "RPF")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "PF")]
# treateff$post_eff[which(treateff$treatment == "RRR")] <- posttreat$Scale_by_G_trans[which(posttreat$Treatment == "RR")] 
# treateff$post_eff[which(treateff$treatment == "CRC")] <- treat$Mean_efficacy[which(treat$Treatment == "C")] * 0.01
# treateff$post_eff[which(treateff$treatment == "SRS")] <- treat$Mean_efficacy[which(treat$Treatment == "S")] * 0.01
# # Round them to two places
# treateff$post_eff <- round(treateff$post_eff, 2)
# 
# write.csv(treateff, "./src/run-model/initial-inputs/elicitation_data/treatment_eff.csv")

# rm(posttreat, treat, treateff)

# Interpolate transitions ------------------------------------------------------ 

# This is a modification on a deprecated script. That script interpolated expert
# opinions across the 16 20x20 (20 = 10 * %est * 2* stem_dens) matrices.
# The final version of the model, however, uses 6x6 matrices (with only
# 3 different %est states).
#
# Here, I change the interpolation to generate the final model matrices.
# % est states are:
# 1. 0-10%
# 2. 11-50%
# 3. 51-100%
#
# REQUIRED LIBRARY
library(lme4)

# --- Read the data ------------------------------------------------------------

setwd("./src/run-model/")

# Read the data

# %est, dens, before & after treatments
elicitation <- read.csv("./initial-inputs/elicitation_data/trans_probs_elicitation.csv")

# The csv had column definitions next to the data-- get rid of those columns
elicitation <- elicitation[, 1:7]

# elicited values/rankings of treatment effectiveness
treatments <- read.csv("./initial-inputs/elicitation_data/treatment_eff.csv")
# NOTE: Sometimes the .csv saves with extra empty cells that get read in as
# NULL. I haven't automated their removal--for now just open .csv in a text
# editor and delete extra commas

# elicited stem density expectations, expressed as the probability that, given
# an initial state and a treatment, the post-treatment density will be high 
dens_after <- read.csv("./initial-inputs/elicitation_data/prob_dens.csv")

source("transition-update-functions.R") # need repairSums()

# --- Convert chip stacks to transition probability lists ----------------------
#
# HOW TO STORE THIS INFORMATION:
# PREDICTORS:
#     1. inital % established
#     2. inital stem density
#     3. treatment
#     4. respondent ID
# RESPONSE:
#     1. ending % est associated with EACH 5-point chip
#
# So store it in a 5-column data frame with 20 rows for each combination of
# predictors. Call it regression_cube
# EDIT: Trying it with 100 chips (some experts didn't play by the rules)
#       This means 100 rows per predictor combination

# Extract all unique combinations of predictors from the elicitation data frame
rows <- dim(elicitation)[1]
predictor_combinations <- NULL

for (r in 1:rows) { # get ALL predictor combinations
  init <- elicitation$est_before[r]
  dens <- as.character(elicitation$dens_before[r])
  trmt <- as.character(elicitation$treatment[r])
  resp <- elicitation$respondent[r]

  predictor_combinations <- c(predictor_combinations, list(c(init, dens, trmt, resp)))
} # end predictor extractions

# get rid of duplicates
predictor_combinations <- unique(predictor_combinations)

# build data frame with 100 rows per unique combination of predictors
total_chips <- 100
rows <- length(predictor_combinations) * total_chips
est_before <- NULL
dens_before <- NULL
treatment <- NULL
respondent <- NULL
pr_est_after <- NULL

for (n in 1:length(predictor_combinations)) {
  eb <- as.numeric(predictor_combinations[[n]][1]) # est_before
  db <- predictor_combinations[[n]][2] # dens_before
  tr <- predictor_combinations[[n]][3] # treatment
  re <- predictor_combinations[[n]][4] # respondent

  # predictor columns
  est_before <- c(est_before, rep(eb, total_chips))
  dens_before <- c(dens_before, rep(db, total_chips))
  treatment <- c(treatment, rep(tr, total_chips))
  respondent <- c(respondent, rep(re, total_chips))

  # response column
  el <- elicitation[elicitation$est_before == eb & 
                      elicitation$dens_before == db & 
                      elicitation$treatment == tr & 
                      elicitation$respondent == re, ]
  outcomes <- el$pr_est_after

  # convert chip counts in bins to a vector of transition probabilities
  pea <- NULL # for pr_est_after
  bin_pr <- 0.05 # probability associated with the middle of the bin

  for (oc in outcomes) {
    # num_chips = oc / 5
    num_chips <- oc
    tr_probs <- rep(bin_pr, num_chips) # transition probabilities

    pea <- c(pea, tr_probs)
    bin_pr <- bin_pr + 0.1
  }
  pea <- pea[pea > 0]
  if (length(pea) == 0) {
    pea <- rep(0, total_chips)
  }
  # print(predictor_combinations[[n]])
  # print(length(pea))
  # if(length(pea) != total_chips) { print(pea) }

  pr_est_after <- c(pr_est_after, pea)
} # done making the columns

regression_cube <- data.frame(est_before, dens_before, treatment, 
                              respondent, pr_est_after)
# NOTE: This writes in 100 zeroes for the elicitations where experts 8 and 9
# did not respond

# spot checks on first and last scenarios (20 L RRR, 80 H RPF): looks like
# everything got calculated ok

# put est_before on 0-1 scale
# (currently est_before is 0-100, pr_est_after is on 0-1, Since logit is
# applied to values between 0 and 1, change the est_before values)
regression_cube$est_before <- regression_cube$est_before / 100


# --- Transform end state %est to logits ---------------------------------------

# Scenarios where experts 8 & 9 didn't answer have zeroes in the pr_est_after
# column --remove them!

regression_cube <- regression_cube[regression_cube$pr_est_after != 0, ]


# --- logit functions ----------------------------------------------------------

# define a function to calculate logits
logit <- function(n) {
  # use natural log
  return(log(n / (1 - n)))
} # end logit

empirical_logit <- function(n, epsilon) {
  # use natural log
  return(log((n + epsilon) / (1 - n + epsilon)))
}

# define a function to transform the results back
unlogit <- function(n) {
  # use natural log
  return(exp(n) / (1 + exp(n)))
} # end unlogit

empirical_unlogit <- function(n, epsilon) {
  # use natural log
  return(((1 + epsilon) * (exp(n)) - epsilon) / (1 + exp(n)))
}

# ------------------------------------------------------------------------------


# calculate logits for pr_est_after & add them as a column to regression_cube
logit_pea <- logit(regression_cube$pr_est_after)

regression_cube <- cbind(regression_cube, logit_pea)

# ------------------------------------------------------------------------------


# DEFINE HERB, DISTURB EFFECTVIENESS
# NOTE THAT:
#   THESE ARE INDEPENDENT OF INITIAL CONDITIONS (%est, stdens) Terminology
#   wrinkle: one of the "disturb" treatments includes Glyphosate 
#   DEFINITIONS ARE BASED ON EXPERT ELICITATION (sheets "Herbicide Treatment",
#   "Post-Herbicide treatment" in the "PAMF elicitation updated with standard
#   deviation" spreadsheet)

r_eff <- 0 # effectiveness of rest (in both herb and disturb)
g_eff <- 0.73 # mean of experts' estimations
pf_eff <- 0.65
# I calculated pf_eff from the averages of the reverse rankings in the
# "Post-Herbicide Treatment" sheet as follows: First, I subtracted the average
# effectiveness of Rest-Rest from the column of averages. Because I want to set
# Rest-Rest effectiveness == 0. Then I scaled everything by the effectiveness of
# the most effective treatment, to get all of the numbers on a range of 0-1. I
# further scaled it by 0.75, to set the effectiveness of glyphosate in the
# growing phase equal to the effectiveness of glyphosate in the translocating
# phase.

# Create vectors to hold herb, disturb effectivenesses (initial values = 0)
herb <- rep(0, dim(regression_cube)[1])
post_herb <- herb

regression_cube <- cbind(regression_cube, herb, post_herb)

# step through treatments GRR, RPF, GPF
# (RRR are already correctly populated)
for (t in c("GRR", "RPF", "GPF")) {
  print(t)

  # subset out rows with treatment t
  # trmnt = regression_cube[which(regression_cube$treatment==t),]

  # calculate herb, disturb effectivenesses
  if (t == "GRR") {
    h_eff <- g_eff # herbicide effectiveness
    d_eff <- r_eff # disturbance effectiveness
  }
  if (t == "RPF") {
    h_eff <- r_eff
    d_eff <- pf_eff
  }
  if (t == "GPF") {
    h_eff <- g_eff
    d_eff <- pf_eff
  }

  # write effectivenesses into herb, disturb columns
  # of the rows with treatment t
  regression_cube[which(regression_cube$treatment == t), "herb"] <- h_eff
  regression_cube[which(regression_cube$treatment == t), "post_herb"] <- d_eff
} # end loop through treatment types


# --- THE REGRESSION ITSELF ----------------------------------------------------

# linear model with:
#     1. random effect on respondent
#     2. logit transform
#     3. treatment effectiveness determined by herb + post_herb + herb*post_herb

# OLD REGRESSION
# No longer using this one because it predicts post-herb rests are more effective
# than post-herb management actions. This seems to be a consequence of the
# herb:post_herb interaction coefficient fitting to a positive value.
# rc_fit = lmer(logit_pea ~ est_before*dens_before*herb*post_herb + (1|respondent), data=regression_cube, REML = FALSE)

# NEW REGRESSION
# Regression with herb:post_herb interactions removed. See compare_regressions.R for
# tests and graphs showing that this version makes more sense
rc_fit <- lmer(logit_pea ~ (est_before + dens_before + herb + post_herb)^3 - herb:post_herb
  - est_before:herb:post_herb - dens_before:herb:post_herb
  + (1 | respondent), data = regression_cube)


# --- DIAGNOSTICS --------------------------------------------------------------

# look at residuals

# plot predicted against data
# plot(regression_cube$logit_pea, predict(rc_fit, regression_cube), 
# xlim = c(-3, 3), ylim = c(-3,3), xlab = "logit(final %est)", 
# ylab = "predicted logit(fina l%est)")
# abline(0,1, col = 'red')

# plot residuals
# plot(regression_cube$logit_pea- predict(rc_fit, regression_cube))
# abline(0,0, col = 'red')

# histogram of residuals
# hist(regression_cube$logit_pea- predict(rc_fit, regression_cube))

# Are the residuals normally distributed?
res <- regression_cube$logit_pea - predict(rc_fit, regression_cube)
qqnorm(res)
qqline(res, col = "red") # mostly ok, maybe a bit light-tailed


# --- ESTIMATING NON-ELICITED TRANSITION PROBABILITIES! -----------------------

# For non-elicited rows in matrices with elicited values... AND for matrices
# with no elicited values at all!

# Recall that the regression gives the most likely post-treatment state for each
# combination of inputs (start %est, density, herb, post-herb). To capture
# transition probabilities across the entire possible range, I bootstrap the 9
# predicted responses for several values in each starting-state bin.

# How this is going to work:
# 1. Choose bin sizes: bins at 0-10%, 11-50%, 51-100%
# 2. for each scenario (density, treatment effectiveness), for each est_before:
# 3. pull 9 samples with replacement; calculate mean est_after
# 4.     repeat a lot of times to get a distribution
#        (9 = number of experts who gave opinions)
# 5. impose bins on the outputs (0-10%, 11-50%, 51-100%)


# --- 1. make binning decisions ---

# use bins with 10% width for both est_before (in) and est_after (out)
in_bins_up <- c(0.1, 0.5, 1) # UPPER BOUND of each bin
out_bins_up <- c(0.1, 0.5, 1)
in_bins_lo <- c(0, 0.11, 0.51) # LOWER BOUND of each bin
out_bins_lo <- c(0, 0.11, 0.51)

n_inbins <- length(in_bins_up)

# STARTING STATES!
# Resample several starting %est values across each in_bin. WHY?
#     * If I were a field ecologist and I marked down that sites x, y, and z
#       all belong to the 20-30%est bin, I would not expect any single value
#       (e.g.25%) to describe all three of them equally well
#     * Using starting states from across each bin helps make
#       prediction quality more uniform, regardless of where the site's %est is
#       in the bin
#     * It isn't that hard resample multiple starting states within each bin

start_states <- seq(0, 1, 0.01)
n_startstates <- length(start_states)

# --- a couple more things to set up before the bootstrapping step ---

n_treatments <- 16 # number of treatment options
n_dens_cats <- 2 # number of stem density categories

# keep track of the 32 'scenarios' i.e. combinations of dens_before & treatment
n_scenarios <- n_treatments * n_dens_cats

# Build a data frame containing all scenarios
# first, the density vector (note: here I'm assuming n_dens_cats will always be
# 2)
dens_before <- c(rep("H", n_treatments), rep("L", n_treatments))

# this is where the information from treatment_eff.csv comes in!
scenarios <- rbind(treatments, treatments) # duplicate all treatment information
# again assumes only 2 density categories
scenarios <- cbind(scenarios, dens_before) # append densities

# how many times to resample
# large n_resample to reduce differences between runs. watch out it'll take
# a while
n_resamples <- 10000

# --- the bootstrap simulations ---

# create a structure to hold histograms of post-treatment %est by scenario
# I'll be adding scenario information to it as I go
transitions_est <- NULL

scenarios <- scenarios[order(scenarios$dens_before), ] # group high, low starting states

for (j in 1:n_inbins) {

  # re-set the structure that holds histogram information
  # the scenarios loop generates chunks of transitions for all scenarios from
  # a single starting state
  post_trmt_ests <- NULL

  # get all starting states within the current in_bin
  binned_start <- start_states[which(start_states >= in_bins_lo[j] & 
                                       start_states <= in_bins_up[j])]
  n_starts <- length(binned_start)

  # feed them to the resampling loop
  for (i in 1:n_scenarios) {
    print(scenarios[i, ])

    # define / re-set bs_means to NULL
    bs_means <- NULL

    for (k in 1:n_starts) {
      # loop through start states
      # print(paste("k: ", k))
      print(paste("binned starts: ", binned_start[k]))

      # create new_data dataframe to use for predict()
      new_data <- data.frame(
        est_before = binned_start[k],
        dens_before = scenarios$dens_before[i],
        treatment = scenarios$treatment[i],
        herb = scenarios$herb_eff[i],
        post_herb = scenarios$post_eff[i]
      )

      # Plug scenario & state into regression
      # to get predicted outcomes
      predicted <- unlogit(unique(predict(rc_fit, new_data)))
      # rc_fit is defined in line 252

      # bootstrapped values are the means of each resample

      for (m in 1:n_resamples) {
        # resample loop

        # Draw 9 values at random from predicted, with replacement 9 == number
        # of experts. Although there are scenarios where not all 9 contributed,
        # there regression creates 9 random effects for each scenario
        resampled <- sample(predicted, 9, replace = TRUE)

        # get mean est_after
        bs_means <- c(bs_means, mean(resampled))
      } # end resample loop
    } # end starting state loop

    # create histogram based on out_bins and extract counts
    out_counts <- hist(bs_means,
      breaks = c(0, out_bins_up),
      main = paste(
        in_bins_up[j], new_data$dens_before,
        new_data$treatment
      ), xlab = "% est after"
    )$counts

    # Note that the y-axis is NOT frequency (# counts). That's because the bins
    # aren't the same width.. so R automatically displays the output in terms of
    # 'density' instead. In this case, the area of each rectangle represents the
    # proportion of points in each bin. That doesn't explain the y-axis height
    # but oh well??
    # out_counts still contains counts though

    # Convert out_counts to proportions, and cbind to a column containing
    # treatment information
    est_after <- out_counts / sum(out_counts)

    scen_cols <- NULL # scenario columns to go with out_props
    for (p in 1:length(est_after)) {
      scen_cols <- rbind(scen_cols, scenarios[i, ])
    }

    out_cols <- cbind.data.frame(scen_cols, est_after)

    # collect with outcomes of other treatments applied to the same starting
    # state
    post_trmt_ests <- rbind(post_trmt_ests, out_cols)
  } # end scenarios loop

  # append a starting bin column to post_trmt_ests
  est_before <- rep(in_bins_up[j], dim(post_trmt_ests)[1])
  post_trmt_ests <- cbind(est_before, post_trmt_ests)

  # Now we have all of the resampled values from the current in_bin, for every
  # scenario

  # append post_trmt_ests with scenario information to transitions data frame
  # current_block = cbind(scenarios, post_trmt_ests) # comment out this line
  print(post_trmt_ests)
  transitions_est <- rbind(transitions_est, post_trmt_ests)
} # end in_bins loop

# --- Incorporate stem density ------------------------------------------------

# Now I want to interpolate the probability that a management unit with any
# particular initial state and under any treatment will move to a high-density
# state.
#
# Note that this is somewhat different than what the data record (i.e. that the
# MU will undergo a change in stem density)


# Use dens_after data frame (contains initial state information & elicited
# values of the probability that a management unit will be in a high/low density
# state post-treatment)
#
# dens_after does not yet have columns for treatment effectiveness. start by
# adding those
#
# Treatment effectiveness is defined in lines 194-196

# Create vectors to hold herb, disturb effectiveness (initial values = 0)
herb_eff <- rep(0, dim(dens_after)[1])
post_eff <- herb_eff

dens_after <- cbind(dens_after, herb_eff, post_eff)

# step through treatments GRR, RPF, GPF
# (RRR are already correctly populated)
for (t in c("GRR", "RPF", "GPF")) {
  print(t)

  # calculate herb, disturb effectivenesses
  if (t == "GRR") {
    h_eff <- g_eff # herbicide effectiveness
    d_eff <- r_eff # disturbance effectiveness
  }
  if (t == "RPF") {
    h_eff <- r_eff
    d_eff <- pf_eff
  }
  if (t == "GPF") {
    h_eff <- g_eff
    d_eff <- pf_eff
  }

  # write effectivenesses into herb, disturb columns
  # of the rows with treatment t
  dens_after[which(dens_after$treatment == t), "herb_eff"] <- h_eff
  dens_after[which(dens_after$treatment == t), "post_eff"] <- d_eff
} # end loop through treatment types


# Now add a column to dens_after containing the empirical logit of prop_H

# As mentioned above, the values elicited for change_dens contain zeros and
# ones. ie. the logit transform I used to get the %est component of
# post-treatment state will not work (logit(0) = -Inf; logit(1) = Inf)
#
# I haven't found any great solutions to this, so I'm going to start with the
# most intuitive, which (to me) is the empirical logit, which multiplies the
# odds ratio by 1 = epsilon/epsilon, where epsilon is a small value (e.g. the
# smallest nonzero in the data set OR the distance between the largest value and
# 1):
#
# empirical logit (n) = ln((n + epsilon)/(1 - n + epsilon))
#
# Function defined above, line 159

# print(dens_after$prop_H[order(dens_after$prop_H)])
# smallest nonzero value is 0.03
# largest non-one value is 0.95
# Therefore:
epsilon <- 0.03
el_propH <- empirical_logit(dens_after$prop_H, epsilon)
dens_after <- cbind(dens_after, el_propH)

# --- THE DENSITY REGRESSION ---------------------------------------------------

# Although the 9-expert structure still holds, I'm not using random effects
# (for now?) because I only need the expected value of density (unlike %est)

# OMIT herb_eff:post_eff (same as herb:post_herb) in this regression too
# dens_fit = lm(el_propH ~ est_before*dens_before*herb_eff*post_eff, data=dens_after)
dens_fit <- lm(el_propH ~ (est_before + dens_before + herb_eff + post_eff)^3 -
  herb_eff:post_eff - est_before:herb_eff:post_eff -
  dens_before:herb_eff:post_eff, data = dens_after)

# --- DIAGNOSTICS --------------------------------------------------------------

# look at residuals

# plot predicted against data
# plot(dens_after$el_propH, predict(dens_fit, dens_after), xlim = c(-4, 4), 
# ylim = c(-4,4), xlab = "logit(final %est)", 
# ylab = "predicted logit(fina l%est)")
# abline(0,1, col = 'red')

# plot residuals
# plot(dens_after$el_propH - predict(dens_fit, dens_after))
# abline(0,0, col = 'red')

# histogram of residuals
# hist(dens_after$el_propH- predict(dens_fit, dens_after))

# Are the residuals normally distributed?
res <- dens_after$el_propH - predict(dens_fit, dens_after)
qqnorm(res)
qqline(res, col = "red") # ok

# --- UN-TRANSFORMED PREDICTIONS -----------------------------------------------

# Predict the expected proportion of management units with high density
# post-treatment for all initial states and treatments

prop_H_after <- empirical_unlogit(predict(dens_fit, transitions_est), epsilon)
# NOTE the back-transform here
#
# NOTE ALSO: prop_H_after is predicted off of the largest est_before value
# in each bin. In rcube_stdens (lines 623-677), I looked at how prop_H_after
# changes across the entire range of est_before. In all cases, this change was
# at least an order of magnitude smaller than the minimum value of prop_H_after
# of any treatment. So I'm not going to do anything special to adjust for
# the (very slight) relationship between est_before and prop_H_after


transitions_est <- cbind(transitions_est, prop_H_after)


# --- CREATE FULL POST-TREATMENT STATES ----------------------------------------

# Step through the rows of transitions, and:
#     1. Convert histogram counts to proportions (columns V2-V11)
#     2. Split each line into high-density and low-density states, where the
#        probability of each occurring is prop_H_after or 1-prop_H_after

# new data frame to hold full set of transition information
transitions <- NULL

for (i in 1:dim(transitions_est)[1]) {
  # Get working row
  the_row <- transitions_est[i, ]

  # Get probability that post-treatment state will be high/low density
  pH <- the_row$prop_H_after
  pL <- 1 - pH

  # Split the_row into a high-density and a low_density row
  the_row_h <- the_row
  the_row_h$est_after <- the_row$est_after * pH # multiply by the chance of
  # being high-density after
  # treatment
  the_row_h <- cbind(the_row_h, dens_after = "H")

  the_row_l <- the_row
  the_row_l$est_after <- the_row$est_after * pL # multiply by the chance of
  # being low-density after
  # treatment
  the_row_l <- cbind(the_row_l, dens_after = "L")

  # rbind to transitions data frame
  transitions <- rbind(transitions, the_row_l)
  transitions <- rbind(transitions, the_row_h)
}

# --- Clean up the data frame --------------------------------------------------
# 1. get rid of extra information (treatment effectiveness columns, prop_H_after)
# 2. add a column describing the est_after state (right now the est_after column 
#    contains transition probabilities)
# 3. rename est_after column to trans_prob
# 4. rename treament to mnt_comb (some participants found the 'treatment'
#    terminology confusing and we are now using 'management combination'
#    instead)
# 5. Add a concentration column for updating later
# 6. reorder columns
# 7. Make sure all transition probabilities out of each state sum to 1

transitions <- transitions[, c(1, 2, 5, 6, 8)]

colnames(transitions)[2] <- "mnt_comb"
colnames(transitions)[4] <- "trans_prob"

est_after <- rep(c(0.1, 0.1, 0.5, 0.5, 1.0, 1.0), 96)
transitions <- cbind(transitions, est_after)

concentration <- transitions$trans_prob
transitions <- cbind(transitions, concentration)

transitions <- transitions[c(2, 1, 3, 6, 5, 4, 7)]

# The above calculations may have bumped the sums of the matrix rows
# slightly off of 1. Repair that, in order not to run into problems with
# the optimizer later
transitions <- transitions[order(transitions$mnt_comb), ]

n_states <- length(unique(transitions$est_before)) * length(
  unique(transitions$dens_before)
  )
n_transitions <- nrow(transitions)
matrix_rows <- split(
  transitions$trans_prob,
  rep(1:ceiling(n_transitions / n_states), each = n_states)
)
repaired_rows <- lapply(matrix_rows, repairSums)
repaired_rows <- unlist(repaired_rows)
transitions$trans_prob <- repaired_rows

# write output to csv
# trans_path <- "./initial-inputs/"
# write.csv(transitions, paste(trans_path, "trans_probs_EXPERT", Sys.Date(),
#                             ".csv", sep = ""), row.names = FALSE
# )

# Saved as "trans_probs_EXPERT-2018-08-13.csv"