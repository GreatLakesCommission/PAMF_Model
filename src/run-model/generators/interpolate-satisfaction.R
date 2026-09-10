# This script takes in satisfaction data from an expert elicitation
# exercise, and estimates the mean satisfaction associated with each of
# the six PAMF states.
#
# LIBRARY REQUIRED:
library(R2jags)
# Note that R2jags also requires an installation of JAGS outside of R:
# http://www.sourceforge.net/projects/mcmc-jags/files

# Convert data to satisfaction matrix ------------------------------------------
# This only needs to be performed once. This code chunk creates
# "preference_2017.csv" used in the code below to derive the mean satisfaction
# associated with each invasion state

# # LIBRARY REQUIRED:
# library(tidyverse)
# 
# sat_2017 <- read.csv("./src/run-model/initial-inputs/elicitation_data/elicited_sat_2017.csv")
# 
# # Keep only the satisfaction values for 0.25, 0.50, and 0.75
# sat_2017 <- sat_2017 %>% 
#   rename(A = est, B = dens) %>% 
#   filter(satisfaction %in% c(0.25, 0.50, 0.75)) %>%
#   mutate(satisfaction = formatC(as.numeric(satisfaction), format = 'f', flag='0', digits = 2)) %>%
#   mutate(satisfaction = gsub("0.", "c", satisfaction)) %>%
#     pivot_longer(cols = c("A", "B"), names_to = "type", values_to = "values") %>%
#   mutate(satisfaction = paste0( type, satisfaction)) %>%
#   arrange(type) %>%
#   select(-type) %>%
#   pivot_wider(id_cols = respondent, names_from = satisfaction, values_from = values)
# names(sat_2017) <- gsub("A","",names(sat_2017))
# names(sat_2017) <- gsub("B","",names(sat_2017))
# 
# write.csv(
#   sat_2017, 
#   "./src/run-model/initial-inputs/elicitation_data/preference_2017.csv"
#   )

# Read Files -------------------------------------------------------------------

# Read elicited satisfaction values
pref <- read.csv(
  "./src/run-model/initial-inputs/elicitation_data/preference_2017.csv"
  )

# Interpolate satisfaction from est, dens --------------------------------------

n.obs <- length(pref$respondent)

# Divide % cover values by 100, convert n.obs x 3 matrix to a vector
# (elicitation was over a range of 0-100% cover)
x_pc <- as.matrix(pref[, 2:4] / 100)
x_pc <- matrix(t(x_pc), nrow = n.obs * 3, ncol = 1, byrow = TRUE)

# Divide stem density values by 200, convert n.obs x 3 matrix to a vector
# (elicitation was over a range of 0-200 stems per square meter)
x_sd <- as.matrix(pref[, 5:7] / 200)
x_sd <- matrix(t(x_sd), nrow = n.obs * 3, ncol = 1, byrow = TRUE)

# % cover and stem density now expressed as proportions, take logits of each
x_pc.l <- as.vector(log(x_pc / (1 - x_pc)))
x_sd.l <- as.vector(log(x_sd / (1 - x_sd)))

# Create vector (length n.obs*3) of preference values, then take logits
y0 <- matrix(rep(c(0.25, 0.5, 0.75), n.obs), nrow = n.obs * 3, ncol = 1, byrow = TRUE)
y0.l <- as.vector(log(y0 / (1 - y0)))

# Create vector of respondent codes
resp <- rep(pref$respondent, each = 3)

## Limits for state definitions (states in rows)
##    col 1: lower %cover limit (expressed as proportion)
##    col 2: width of %cover range (upper limit = lower limit + range)
##    col 3: number of steps over range
##    col 4-6: same variables for stem density (expressed as proportion of 200 stems)
##  State 1: %cover (0 - 10%), SD (0/200 - 10/200)
##  State 2: %cover (0 - 10%), SD (11/200 - 200/200)
##  State 3: %cover (11 - 50%), SD (0/200 - 10/200)
##  State 4: %cover (11 - 50%), SD (11/200 - 200/200)
##  State 5: %cover (51 - 100%), SD (0/200 - 10/200)
##  State 6: %cover (51 - 100%), SD (11/200 - 200/200)
statelims <- matrix(c(
  0.0, 0.1, 11, 0.0, 0.05, 11,
  0.0, 0.1, 11, 0.055, 0.945, 190,
  0.11, 0.39, 40, 0.0, 0.05, 11,
  0.11, 0.39, 40, 0.055, 0.945, 190,
  0.51, 0.49, 50, 0.0, 0.05, 11,
  0.51, 0.49, 50, 0.055, 0.945, 190
), nrow = 6, ncol = 6, byrow = TRUE)


## Bayesian model using JAGS
# Bundle data
#  (for prediction, 'nudge' is a tiny amount to pull proportions away from 0/1
#  prior to logit transformation)
jags.data <- list(
  n.obs = n.obs * 3, x1 = x_pc.l, x2 = x_sd.l, y = y0.l, resp = as.integer(resp),
  n.resp = n.obs, nudge = 0.00001, S = statelims
)

# Initial values
inits <- function() {
  list(
    b0 = rnorm(1, 0, 0.1), b1 = rnorm(1, 0, 0.1), b2 = rnorm(1, 0, 0.1),
    sd = runif(1, 0, 1), re.sd = runif(1, 0, 1)
  )
}

# Parameters monitored
parameters <- c(
  "b0", "b1", "b2", "b12", "re.sd", "sd", # "p.mu",
  "mp"
)

# MCMC settings: ni = number of iterations, nt = thinning rate, nb = burn-in, nc
# = number of chains
ni <- 100000
nt <- 1
nb <- 500
nc <- 3
mod.file <- c("preference2.jags")

## Call JAGS
out <- jags(
  data = jags.data, inits = inits, parameters.to.save = parameters,
  model.file = mod.file, n.chains = nc, n.thin = nt, n.iter = ni, n.burnin = nb,
  parallel = TRUE
)

state_means <- out$summary[7:12, "mean"]


# Save & clean up --------------------------------------------------------------

# save as a data frame
sat_by_state <- data.frame(state = 1:6, satisfaction = state_means)

sat_path <- "./initial-inputs"
sat_file <- paste("mean_sat-", Sys.Date(), ".csv", sep = "")
write.csv(sat_by_state, paste(sat_path, sat_file, sep = ""), row.names = FALSE)

# remove temporary variables
rm(
  pref, n.obs, x_pc, x_sd, x_pc.l, x_sd.l, y0, y0.l, resp, statelims,
  jags.data, inits, parameters, ni, nt, nb, nc, mod.file, out, state_means,
  sat_path, sat_file, sat_by_state, wd
)
