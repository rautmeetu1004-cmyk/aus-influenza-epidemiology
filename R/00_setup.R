# 00_setup.R
# Installs (if needed) and loads every package the pipeline uses.
# Run this once, or source it at the top of each script.

pkgs <- c(
  "readxl",     # read the NNDSS Excel workbook
  "dplyr",      # data manipulation
  "tidyr",      # reshaping
  "readr",      # fast CSV IO
  "stringr",    # string cleaning
  "lubridate",  # dates
  "ggplot2",    # figures
  "scales",     # axis formatting
  "MASS"        # negative binomial GLM (glm.nb) for the interrupted time series
)

missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages(
  invisible(lapply(pkgs, library, character.only = TRUE))
)

# dplyr::select must win over MASS::select
if ("package:MASS" %in% search()) {
  select <- dplyr::select
}

message("Setup complete. Packages loaded: ", paste(pkgs, collapse = ", "))
