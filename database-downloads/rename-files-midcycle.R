# Updates
# * Added conditionals for different report types, so that this script can be
#   used on partial data pulls
#
# This script re-names the database tables and appends the data pull date.
# it also removes the file-begin character appended by the database software
# when the .csv files were created
#
# To re-use this script for other years, change the 'path' and 'pull_date'
# variables as needed
##

path <- "./database-downloads/2024/"
pull_date <- as.Date("2024-01-08")
table_names <- list.files(path)

if ("tbl_managementunit.csv" %in% table_names) {
  enroll <- read.csv(paste0(path, "tbl_managementunit.csv"),
    fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
  )
  write.csv(enroll, paste0(path, "enroll-", pull_date, ".csv"), row.names = FALSE)
  rm(enroll)
} else {
  warning("Enrollment reports not found")
}

if ("TBL_fieldsheet.csv" %in% table_names) {
  monitor <- read.csv(paste0(path, "TBL_fieldsheet.csv"),
    fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
  )
  write.csv(monitor, paste0(path, "monitor-", pull_date, ".csv"),
    row.names = FALSE
  )
  rm(monitor)
} else {
  warning("Monitoring reports not found")
}

if ("TBL_treatmentreport.csv" %in% table_names) {
  manage <- read.csv(paste0(path, "TBL_treatmentreport.csv"),
    fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
  )
  write.csv(manage, paste0(path, "manage-", pull_date, ".csv"), row.names = FALSE)
  rm(manage)
} else {
  warning("Management reports not found")
}

if ("treatmentreportXapplicationdate.csv" %in% table_names) {
  managedate <- read.csv(paste0(path, "treatmentreportXapplicationdate.csv"),
    fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
  )
  write.csv(managedate, paste0(path, "managedate-", pull_date, ".csv"),
    row.names = FALSE
  )
  rm(managedate)
} else {
  warning("Management dates not found")
}

if ("TBL_mid_guidance_req.csv" %in% table_names) {
  midcycle <- read.csv(paste0(path, "TBL_mid_guidance_req.csv"),
    fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE
  )
  write.csv(midcycle, paste0(path, "midcycle-", pull_date, ".csv"),
    row.names = FALSE
  )
  rm(midcycle)
} else {
  warning("Midcycle reports not found")
}

rm(path, pull_date, table_names)

library(anytime)
manage <- read.csv(paste0(path, "manage-2023-01-17.csv"))
manage$managementdate <- anydate(manage$managementdate)
manage$dateentered <- anydate(manage$dateentered)
manage <- manage[-which(manage$munitid == "NULL"), ]
write.csv(manage, paste0(path, "manage-2023-01-17.csv"), row.names = FALSE)
rm(manage)

managedate <- read.csv(paste0(path, "managedate-2023-01-17.csv"))
managedate$applicationdate <- anydate(managedate$applicationdate)
write.csv(managedate, paste0(path, "managedate-2023-01-17.csv"), row.names = FALSE)
rm(managedate)

monitor <- read.csv(paste0(path, "monitor-2023-01-17.csv"))
monitor$monitoringdate <- anydate(monitor$monitoringdate)
write.csv(monitor, paste0(path, "monitor-2023-01-17.csv"), row.names = FALSE)
rm(monitor)

midcycle <- read.csv(paste0(path, "midcycle-2024-01-08.csv"))
midcycle$dateentered <- anydate(midcycle$dateentered)
write.csv(midcycle, paste0(path, "midcycle-2024-01-08.csv"), row.names = FALSE)
rm(midcycle)