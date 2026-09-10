# Download files needed to replicate the official PAMF Model Runs --------------

# LIBRARY REQUIRED:
# install.packages("sbtools")
library(sbtools)

# This script can be used to automatically download the PAMF data from the
# PAMF data releases on ScienceBase and place the data in the correct folders
# in the PAMF Model repository.

# Follow the steps below to run the code and obtain/move the model files.

# NOTE: It is best practice that if the user has performed one model run and
# wishes to perform another to delete the files in the database-downloads folder
# and replace them with those from the next official run they wish to replicate.
# For example, if a user ran the model to replicate the 2020 official model run
# and then they wish to replicate the 2021 model run, all of the files in
# database-downloads from the 2020 run (e.g., "2018", "2019", and "2020"
# folders) should be deleted, then replaced with those same folders from the
# 2021 model run's database-downloads folder.

# Links to PAMF Data releases
# - Phragmites Adaptive Management Framework (PAMF) participant and model data
#   (2017-2021)
#   http://doi.org/10.5066/P92NZCYL
# - Phragmites Adaptive Management Framework (PAMF) participant and model data
#   (2021-most recent year)
#   http://doi.org/10.5066/P9RKEY74

# Step 1. User input -----------------------------------------------------------

# Change the variables in this section to help download the move the PAMF data.

# Autheticate for ScienceBase
authenticate_sb("YOUR USER NAME", "YOUR PASSWORD")

# USER INPUT: Set path to a folder where you would like to download the data
# (preferably one outside the PAMF Model repository):
download_path <- "C:/Your/Path/Here" # Do not add trailing "/"

# USER INPUT: Set the path to the PAMF Model repository
model_path <- "C:/Your/Path/Here/pamf-model/" # Add trailing "/"

# Step 2. Run all the code below -----------------------------------------------

# Run all of the code below. No user input needed.

## Download data from the data releases ----------------------------------------

# Make sure file paths are in the correct format / point to the correct place
# Make sure download path has no trailing slash
download_path <- gsub("^\\/|\\/$", "", download_path)
# Make sure model path does have a trailing slash
model_path <- sub("/?$", "/", model_path)
# Check to make sure the model_path actually contains the folders we need
if (all(c("database-downloads", "midcycle-forecasts", "model-runs") %in%
  list.dirs(model_path, full.names = F)) == FALSE) {
  stop(cat(
    "WARNING! One or more of the following folders is not present in the path specified in 'model_path':",
    "database-downloads, midcycle-forecasts, model-runs.",
    "Please make sure you have identified the correct path."
  ))
}

sb_ids <- c(
  release_2017 = "62e82160d34e749ac04cba33",
  release_2021 = "63b7076ed34e92aad3caf349"
)

for (i in seq_along(sb_ids)) {
  release_id <- sb_ids[i]
  if (names(release_id) == "release_2017") {
    append_year <- "2017"
  } else {
    append_year <- "2021"
  }
  # Download the zip file to your download path of choice
  item_file_download(
    sb_id = release_id, names = "PAMF-Model-data.zip",
    destinations = paste0(
      download_path, "/PAMF-Model-data-", append_year, ".zip"
      )
  )
  # Unzip the file in the download path
  unzip(zipfile = paste0(
    download_path, "/PAMF-Model-data-", append_year, ".zip"
    ), exdir = download_path)
  # rename the folder that is unzipped to the first year of the data release
  file.rename(
    paste0(download_path, "/PAMF-Model-data"), 
    paste0(download_path, "/PAMF-Model-data-", append_year)
    )
}

rm(sb_ids, append_year, release_id)

## Copy files to PAMF repository -----------------------------------------------

### Copy over all the yearly and midcycle model runs ---------------------------
dl_paths <- c("/PAMF-Model-data-2017/", "/PAMF-Model-data-2021/")
dl_paths <- list.files(
  paste0(download_path, dl_paths),
  pattern = "model-runs",
  include.dirs = T, full.names = T
)
dl_paths_mr <- list.files(
  paste0(dl_paths),
  pattern = "model-runs|midcycle-forecasts",
  include.dirs = T, full.names = T
)
# Remove the "empty" midcycle forecast folder from the 2021 data release - it
# was simply a placeholder
dl_paths_mr <- dl_paths_mr[!dl_paths_mr %in% 
                             dl_paths_mr[grepl(
                               "PAMF-Model-data-2021/2021-model-runs/midcycle-forecasts", 
                               dl_paths_mr)]]

for (k in unique(dl_paths_mr)) {
  dl_path <- k
  if (grepl("midcycle-forecasts", dl_path)) {
    j <- "midcycle-forecasts/"
  } else {
    j <- "model-runs/"
  }
  dbd_files <- list.files(dl_path, full.names = TRUE)
  for (i in 1:length(dbd_files)) {
    dbd_file <- dbd_files[i]
    file.rename(dbd_file, paste0(model_path, j, basename(dbd_file)))
  }
}

rm(download_path, dl_paths_mr)

### Copy over all the database downloads ---------------------------------------
split_path <- function(path) {
  rev(setdiff(strsplit(path, "/|\\\\")[[1]], ""))
}

for (k in unique(dl_paths)) {
  dl_path <- paste0(k, "/database-downloads/")
  dbd_files <- list.files(dl_path, full.names = TRUE)
  for (i in 1:length(dbd_files)) {
    dbd_file <- dbd_files[i]
    dbd_file_path <- split_path(dbd_file)
    R.utils::copyDirectory(
      dbd_file, paste0(
        model_path, "database-downloads/", 
        dbd_file_path[3], "/", dbd_file_path[1]
        )
      )
  }
}

rm(dbd_files, i, j, k, dbd_file, dl_path, dl_paths, dbd_file_path)

# Step 3. Input the year of the model run you want to reproduce ----------------

# USER INPUT: Input the year of the model run you would like to replicate
# As of 1/26/2023, the cycles available are: 2020, 2021, and 2022.
cycle <- 2020

cyclefolder <- paste0(model_path, "database-downloads/", cycle, "-model-runs")
cyclefolderfiles <- list.files(cyclefolder, full.names = T, recursive = T)
cyclefolderfiles_copy <- gsub(
  paste0(cycle, "-model-runs/"), "", cyclefolderfiles
  )
cyclefolders_copy <- setdiff(
  gsub(
    paste0(cycle, "-model-runs/"), "", 
    list.dirs(
      paste0(model_path, "database-downloads/", cycle, "-model-runs"))
    ), cyclefolder
  )

sapply(cyclefolders_copy,
  dir.create,
  recursive = TRUE, showWarnings = FALSE
)
file.copy(cyclefolderfiles, cyclefolderfiles_copy, recursive = TRUE)

rm(cycle, cyclefolder, cyclefolderfiles, cyclefolderfiles_copy, 
   cyclefolders_copy, split_path, model_path)

# Step 4. Check the files ------------------------------------------------------
# Confirm that all of the files in your download path are out of the folder
# and in the correct folders in the PAMF Model repository.

# Now you can run the PAMF Model!

# Note: If you want to run the model for another year, delete the folders named
# by year (e.g., "2020") in the database-downloads folder and run the script
# in Step 3 again for a different cycle.
