# Interpolate satisfaction from the 2023 satisfaction elicitation

# This script takes the raw satisfaction data collected during the March 2023
# satisfaction elicitation for transitions between beginning invasion states 1
# and 6 and ending invasions states 1-6 (under three cost scenarios: no cost,
# low cost, and high cost) and uses a generalized additive model to predict the
# satisfaction with transitions between beginning states 2-5 and ending states
# 1-6 (under the three cost scenarios).

# Cost ranking interpolation
# Note that the PAMF model uses a reverse cost ranking in its optimization;
# there are 16 PAMF management combinations ranked 1-16 in their estimated
# overall cost, with 1 = the most expensive combination, and 16 = the least
# expensive combination. The last step in this code interpolates the predicted
# satisfaction for the low and high cost scenarios between 15 cost levels (ranks
# 1-15), while the "no cost" satisfaction predictions are used for cost level
# 16.

# Load in / mutate data --------------------------------------------------------

# LIBRARIES REQUIRED:
library(tidyverse) # for dplyr and ggplot
library(mgcv) # for GAMs
library(qpcR) # for AIC values

# Read in the raw data from the satisfaction elicitation
sat <- read.csv("./src/run-model/initial-inputs/elicitation_data/elicited_sat_2023.csv")

# Clean up the satisfaction data
sat <- sat %>%
  mutate(
    state_begin = as.factor(state_begin),
    Scenario = as.factor(Scenario),
    participant = as.factor(participant),
    satisfaction = satisfaction / 100
  ) %>%
  # mutate 0s and 1s to work with beta GAM
  mutate(satisfaction = ifelse(satisfaction == 1, 0.9999999999, satisfaction)) %>%
  mutate(satisfaction = ifelse(satisfaction == 0, 0.0000000001, satisfaction))

# Make a dataframe to hold the predictions
predict_df <- data.frame(
  state_begin = as.factor(rep(c(1, 6), each = 18)),
  Scenario = as.factor(rep(c(
    "No cost", "Low cost", "High cost",
    "No cost", "Low cost", "High cost"
  ), each = 6)), state_end = rep(c(1:6), 6)
)

hist(sat$satisfaction[sat$state_begin == 1])
hist(sat$satisfaction[sat$state_begin == 6])

# Make a list of GAMs for comparison -------------------------------------------
gam_list <- list()

gam_list[[1]] <- mgcv::gam(satisfaction ~ s(state_end, k = 6) +
  Scenario:state_begin, data = sat, family = betar(link = "logit"))
# summary(gam_list[[7]])
gam_list[[2]] <- mgcv::gam(satisfaction ~ s(state_end, k = 6) +
  Scenario + state_begin, data = sat, family = betar(link = "logit"))
# summary(gam_list[[2]])
gam_list[[3]] <- mgcv::gam(satisfaction ~ s(state_end, k = 6) +
  s(state_end, by = state_begin, k = 6) +
  state_begin + Scenario, data = sat, family = betar(link = "logit"))
# summary(gam_list[[3]])
gam_list[[4]] <- mgcv::gam(satisfaction ~ s(state_end, k = 6) +
  s(state_end, by = Scenario, k = 6) +
  state_begin + Scenario, data = sat, family = betar(link = "logit"))
# summary(gam_list[[4]])
gam_list[[5]] <- mgcv::gam(satisfaction ~ s(state_end, k = 6) +
  s(state_end, by = state_begin, k = 6) +
  state_begin + Scenario +
  s(state_end, by = Scenario, k = 6), data = sat, family = betar(link = "logit"))
# summary(gam_list[[5]])
gam_list[[6]] <- mgcv::gam(satisfaction ~ s(state_end, k = 6) +
  s(state_end, by = state_begin, k = 6) +
  state_begin + Scenario, data = sat, family = betar(link = "probit"))


## Get GAM statistics ----------------------------------------------------------

# Make a dataframe to hold the stats
GAM_eq_table <- data.frame(
  GAM_Num = paste0("GAM_", c(1:length(gam_list))), eq = NA, AIC = NA
)

# Predict the satisfaction and get stats for each model above
for (i in 1:length(gam_list)) {
  predict_df[[paste0("GAM_", i)]] <- predict(gam_list[[i]], predict_df, type = "response")
  form <- as.character(gam_list[[i]]["formula"])
  GAM_eq_table$eq[GAM_eq_table$GAM_Num == paste0("GAM_", i)] <- paste(strwrap(form, 40), collapse = "\n")
  GAM_eq_table$AIC[GAM_eq_table$GAM_Num == paste0("GAM_", i)] <- AIC(gam_list[[i]])
}

# Put an asterisk on the one with the log link to differentiate from the similar
# model
GAM_eq_table$eq[GAM_eq_table$GAM_Num == "GAM_6"] <- paste0(GAM_eq_table$eq[GAM_eq_table$GAM_Num == "GAM_6"], "*")

GAM_eq_table <- GAM_eq_table %>% arrange(AIC)
GAM_eq_table$eq <- gsub("\n", "", GAM_eq_table$eq)
GAM_eq_table <- cbind(GAM_eq_table, as.data.frame(qpcR::akaike.weights(GAM_eq_table$AIC)))
GAM_eq_table <- GAM_eq_table %>% arrange(desc(weights))
GAM_eq_table$AIC <- round(GAM_eq_table$AIC, 1)
GAM_eq_table$deltaAIC <- round(GAM_eq_table$deltaAIC, 1)
GAM_eq_table$rel.LL <- round(GAM_eq_table$rel.LL, 5)
GAM_eq_table$weights <- round(GAM_eq_table$weights, 3)

# Check out the table --find best-forming model with lowest AIC
GAM_eq_table

# get the best-performing GAM
best_GAM <- GAM_eq_table$GAM_Num[1]
best_GAM

## Plot the GAMS ---------------------------------------------------------------
# Plot the predicted values for the GAMS

cols_pivot <- names(predict_df)[c(4:length(names(predict_df)))]
predict_df <- predict_df %>%
  pivot_longer(
    cols = all_of(cols_pivot), names_to = "GAM_Num",
    values_to = "PredSat"
  )

# Make color scale
scolors <- c("#a61e07", "#fcad03", "#91bfdb")
names(scolors) <- c("High cost", "Low cost", "No cost")

ggplot(predict_df) +
  geom_point(aes(x = state_end, y = PredSat, color = Scenario, 
                 shape = as.factor(state_begin))) +
  geom_line(aes(x = state_end, y = PredSat, color = Scenario,
                linetype = as.factor(state_begin))) +
  facet_wrap(~GAM_Num) +
  theme_bw() +
  ylab("Satisfaction") +
  xlab("End state") +
  scale_y_continuous(expand = c(0, 0)) +
  geom_text(data = GAM_eq_table, aes(x = Inf, y = Inf, hjust = 1, 
                                     vjust = 1, label = eq), size = 4) +
  theme(legend.position = "top") +
  scale_color_manual(values = scolors)

rm(cols_pivot)

# Interpolate best_GAM sat for beginning invasion states 2-5 -------------------

best_GAM <- predict_df %>%
  filter(GAM_Num == best_GAM) %>%
  dplyr::select(-GAM_Num)
best_GAM$state_begin <- as.numeric(as.character(best_GAM$state_begin))

interp_results <- list()
for (i in c(1:6)) {
  for (j in c("No cost", "Low cost", "High cost")) {
    for (k in c(2:5)) {
      interp <- approx(best_GAM$state_begin[best_GAM$Scenario == j & best_GAM$state_end == i],
        best_GAM$PredSat[best_GAM$Scenario == j & best_GAM$state_end == i],
        xout = k
      )
      interp <- as.data.frame(interp)
      interp$Scenario <- j
      interp$state_end <- i
      interp_results[[paste(i, j, k)]] <- interp
    }
  }
}

interp_results <- data.table::rbindlist(interp_results)
names(interp_results)[1:2] <- c("state_begin", "PredSat")

best_GAM <- bind_rows(best_GAM, interp_results)
rm(interp_results, interp, i, j, k)

## Plot interpolated satisfaction ----------------------------------------------

ggplot(best_GAM) +
  geom_point(aes(
    x = state_end, y = PredSat,
    color = state_begin, shape = as.factor(state_begin)
  )) +
  geom_line(aes(
    x = state_end, y = PredSat,
    color = state_begin, linetype = as.factor(state_begin)
  )) +
  facet_wrap(~Scenario) +
  theme_bw() +
  ylab("Satisfaction") +
  xlab("End state") +
  scale_y_continuous(expand = c(0, 0)) +
  theme(legend.position = "top")

# Save CSV of final data for the model -----------------------------------------
best_GAM_cost_save <- best_GAM %>%
  rename(
    cost_scenario = Scenario, state_begin = state_begin,
    state_end = state_end, satisfaction = PredSat
  ) %>%
  dplyr::select(cost_scenario, state_begin, state_end, satisfaction) %>%
  arrange(cost_scenario, state_begin, state_end)

# This CSV will contain the predicted satisfaction levels between states for all
# three cost levels. This data will be interpolated along the cost ranking scale
# in "build-reward-matrix.R"

write.csv(best_GAM_cost_save,
          "./src/run-model/initial-inputs/satisfaction_by_cost_2023.csv",
          row.names = F)

# Clean-up ---------------------------------------------------------------------

rm(best_GAM, best_GAM_cost_save, GAM_eq_table, gam_list, predict_df, sat, form, 
   scolors)
