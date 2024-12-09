# Script to harvest lake champlain temperature data from ERDAP
# EGD
# 2024 December 08
# 

# load libraries ----
library(dplyr)
library(ggplot2)

# Load bounding box data: data from Matt Futia github
bbox_data <- read.csv("RegionsBBox.csv")

# Date range
begin_d <- as.Date("2023-01-01")
end_d <- as.Date("2024-12-31")

# Base ERDDAP URL
base_url <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.csv"

# Show progress bar
prog.bar <- txtProgressBar(min = 0, max = nrow(bbox_data), style = 3)

# Loop through each region and download data
for (i in 1:nrow(bbox_data)) {
  # Region information
  region <- bbox_data$region[i]
  xmin <- bbox_data$xmin[i]
  xmax <- bbox_data$xmax[i]
  ymin <- bbox_data$ymin[i]
  ymax <- bbox_data$ymax[i]
  
  # Construct the query URL
  full_url <- paste0(
    base_url, "?analysed_sst",
    "[(", begin_d, "T00:00:00Z):1:(", end_d, "T23:59:59Z)]",
    "[(", ymin, "):1:(", ymax, ")]",
    "[(", xmin, "):1:(", xmax, ")]"
  )
  
  # Save the file locally
  write.path <- paste0("data/temperature/", region, ".csv")
  download.file(full_url, write.path, quiet = TRUE, method = "auto", mode = "wb")
  
  # Update progress bar
  setTxtProgressBar(prog.bar, i)
}

# Download complete
close(prog.bar)

# Read and concatenate the downloaded files
folder_path <- "data/temperature/"
file_list <- list.files(path = folder_path, pattern = "*.csv", full.names = TRUE)

# Function to read and label each CSV
read_and_label_csv <- function(file) {
  cname <- read.csv(file, nrow = 0)
  df <- read.csv(file, na.strings = "NaN", skip = 2)
  colnames(df) <- colnames(cname)
  df$region <- gsub(".csv", "", basename(file))
  return(df)
}

# Combine all files into one data frame
temperature_data <- bind_rows(lapply(file_list, read_and_label_csv))

# Save combined data
write.csv(temperature_data, "data/LakeChamplain_temperature.csv", row.names = FALSE)
