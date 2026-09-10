
# This script can be used as needed. It re-names the database tables and appends
# the pull date. it also removes the file-begin character appended by the
# database software when the .csv files were created and fixes any date issues
# or non-UTF characters from notes. You can also diagnose or fix some issues
# that may arise, such as removing "test" MUs or finding MUs with multiple
# monitoring reports.
#
# To re-use this script for other years, change the 'path' and 'pull_date'
# variables as needed
##
library(anytime)
library(readr)
library(textclean)
library(tidyverse)

`%notin%` <- Negate(`%in%`)

path <- "./database-downloads/2025/"
pull_date <- as.Date("2025-08-11")
dir.files <- list.files(path)

# Rename files -----------------------------------------------------------------
enroll <- read.csv(paste0(path, "tbl_managementunit.csv"),
  fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
)
write.csv(enroll, paste0(path, "enroll-", pull_date, ".csv"), row.names = FALSE)
rm(enroll)

monitor <- read.csv(paste0(path, "TBL_fieldsheet.csv"),
  fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
)
write.csv(monitor, paste0(path, "monitor-", pull_date, ".csv"),
  row.names = FALSE
)
rm(monitor)

manage <- read.csv(paste0(path, "TBL_treatmentreport.csv"),
  fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
)
write.csv(manage, paste0(path, "manage-", pull_date, ".csv"), row.names = FALSE)
rm(manage)

managedate <- read.csv(paste0(path, "treatmentreportXapplicationdate.csv"),
  fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
)
write.csv(managedate, paste0(path, "managedate-", pull_date, ".csv"),
  row.names = FALSE
)
rm(managedate)
rm(path, pull_date)

# Clean files ------------------------------------------------------------------

# If there are warnings about dates being in an incorrect format that prevent
# you from running the model, try using the anydate function from the anytime
# package to parse the date. this sometimes happens if a CSV file is opened or
# viewed in Excel--the date column can become corrupted.

# This will also clean up any notes columns with weird characters that could
# cause the file to be read in incorrectly

path <- "./database-downloads/2024/"
pull_date <- as.Date("2024-08-21")
dir.files <- list.files(path)

# Enrollment
enroll_path <- dir.files[grep("enroll-", dir.files, fixed = T)]
enroll <- read_csv(paste0(path, enroll_path), guess_max = 10000)
enroll$dateentered <- anydate(enroll$dateentered)
enroll[names(enroll)] <- lapply(enroll[names(enroll)], replace_non_ascii)
write.csv(enroll, paste0(path, enroll_path),  row.names = FALSE)
# Confirm that file reads in okay now:
# enroll <- read.csv(paste0(path, enroll_path))

# Monitor 
monitor_path <- dir.files[grep("monitor-", dir.files, fixed = T)]
monitor <- read_csv(paste0(path, monitor_path), guess_max = 10000)
monitor[names(monitor)] <- lapply(monitor[names(monitor)], replace_non_ascii)
monitor$dateentered <- anydate(monitor$dateentered)
monitor$monitoringdate <- anydate(monitor$monitoringdate)
write.csv(monitor, paste0(path, monitor_path),  row.names = FALSE)
# Confirm that file reads in okay now:
# monitor <- read.csv(paste0(path, monitor_path))

# Management 
manage_path <- dir.files[grep("manage-", dir.files, fixed = T)]
manage <- read_csv(paste0(path, manage_path), guess_max = 10000)
manage[names(manage)] <- lapply(manage[names(manage)], replace_non_ascii)
manage$dateentered <- anydate(manage$dateentered)
manage$managementdate <- anydate(manage$managementdate)
write.csv(manage, paste0(path, manage_path),  row.names = FALSE)
# Confirm that file reads in okay now:
# manage <- read.csv(paste0(path, manage_path))

# Management Date
managedate_path <- dir.files[grep("managedate-", dir.files, fixed = T)]
managedate <- read_csv(paste0(path, managedate_path), guess_max = 10000)
managedate[names(managedate)] <- lapply(managedate[names(managedate)], replace_non_ascii)
managedate$applicationdate <- anydate(managedate$applicationdate)
write.csv(managedate, paste0(path, managedate_path),  row.names = FALSE)
# Confirm that file reads in okay now:
# managedate <- read.csv(paste0(path, managedate_path))

# Remove any test MUs ----------------------------------------------------------
# If there are any MUs created in the Web Hub with test data, remove them here.

# Enrollment
enroll_path <- dir.files[grep("enroll-", dir.files, fixed = T)]
enroll <- read_csv(paste0(path, enroll_path), guess_max = 10000)
enroll <- enroll[-which(enroll$munitid == 2675), ]
write.csv(enroll, paste0(path, enroll_path),  row.names = FALSE)

# Find multiple monitoring reports per MU --------------------------------------

monitor_path <- dir.files[grep("monitor-", dir.files, fixed = T)]
monitor <- read_csv(paste0(path, monitor_path), guess_max = 10000)
extras <- monitor %>% 
  mutate(year = year(monitoringdate)) %>% 
  group_by(munitid, year) %>% 
  summarise(n = n()) %>% 
  ungroup() %>% 
  filter(n > 1)
# Delete any extras in the Web Hub
# Delete extra reports here:
monitor <- monitor %>% 
  filter(id %notin% c(2190, 2191, 2132, 2272, 2143, 2144, 2145, 2146))

write.csv(monitor, paste0(path, monitor_path),  row.names = FALSE)

