# Update cost constants and produce new cost constants file --------------------

# Step 1. Copy the newest version of "cost_constant_raw_data_[YEAR].csv" and
# rename to the current year for which costs are being updated.

# Step 2. Update the costs using the sources provided, or find new sources if
# needed / desired. Update the year in the "cost_year" column.

# Step 3. Run this script to save a new version of the cost constant CSV.

# LIBRARY REQUIRED:
library(tidyverse)

# Example using most recent file:
cc <- read.csv("./cost-constants/update-constants/cost_constant_raw_data_2025.csv")

# Remove unnecessary columns
cc <- cc[,c("type", "name", "unit", "cost_per_unit", "herb_code", "cost_year")]
# Save the order of the columns names for later
cc_names <- names(cc) 

# Get the average costs of herbicides to fill in NA values
cc$cost_per_unit[which(cc$type == "glyphosate" & is.na(cc$cost_per_unit))] <- mean(cc$cost_per_unit[cc$type == "glyphosate" & !is.na(cc$cost_per_unit)])

## Subset the data to be summarized per "name" ---------------------------------

# Get the mean per "name"
name_cols <- c("human", "fuel", "electricity", "imazapyr", "added")
cc_summ <- cc[which(cc$type %in% name_cols), ]
cc <- cc[-which(cc$type %in% name_cols), ]

# summarize the data by group
cc_summ <- cc_summ %>% 
  group_by(type, name, unit, herb_code, cost_year) %>%
  summarise(cost_per_unit = mean(cost_per_unit, na.rm=TRUE)) %>% as.data.frame()

rm(name_cols)

## Subset the data to be summarized per "type" ---------------------------------

# Get the mean per "type"
type_cols <- c("surfactant")
cc_type_summ <- cc[which(cc$type %in% type_cols), ]
cc <- cc[-which(cc$type %in% type_cols), ]

# summarize the data by group
cc_type_summ <- cc_type_summ %>% 
  group_by(type, unit, herb_code, cost_year) %>%
  summarise(cost_per_unit = mean(cost_per_unit, na.rm=TRUE)) %>% as.data.frame() %>% 
  mutate(name = "surfactant")

rm(type_cols)

## Volunteers ------------------------------------------------------------------

# Get the data for volunteers. We made the assumption that a volunteer's time
# is worth approximately half of a student (i.e., there are still costs
# associated with training them, etc.)
cc_volunteer <- cc_summ[which(cc_summ$name == "student"), ]
cc_volunteer$cost_per_unit <- cc_volunteer$cost_per_unit/2
cc_volunteer$name <- "volunteer"

## Combine all costs -----------------------------------------------------------

# Put all back together
cc <- bind_rows(cc, cc_summ, cc_type_summ, cc_volunteer)
cc <- cc[, cc_names]

# Round the money
cc$cost_per_unit <- round(cc$cost_per_unit, 2)

write.csv(cc, "./cost-constants/cost_constants_2025.csv", row.names = F)
rm(cc, cc_summ, cc_type_summ, cc_volunteer)
  