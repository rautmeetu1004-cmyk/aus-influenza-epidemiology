# run_all.R
# Reproduce the whole analysis end to end:
#   Rscript run_all.R
# Steps are ordered; each writes its outputs to data/processed, outputs/figures
# and outputs/tables. The raw download (step 01) and the workbook read (step 02)
# are the slow parts; later steps read the small processed CSVs.

source("R/utils.R")
source("R/00_setup.R")

steps <- c(
  "R/01_download.R",
  "R/02_clean.R",
  "R/03_descriptive_time.R",
  "R/04_descriptive_person.R",
  "R/05_descriptive_place.R",
  "R/06_interrupted_timeseries.R"
)

for (s in steps) {
  message("\n=== ", s, " ===")
  source(s)
}
message("\nAll steps complete. See outputs/figures and outputs/tables.")
