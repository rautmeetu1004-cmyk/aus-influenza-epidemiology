# 02_clean.R
# Reads the four line-list sheets from the NNDSS workbook, harmonises them into
# one tidy notification table, and writes small purpose-built aggregates to
# data/processed/. Those aggregates (a few hundred KB) are committed so the
# analysis and figures run without the 47 MB raw file.

if (!exists("path_raw")) source("R/utils.R")
suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr)
  library(readr); library(stringr); library(lubridate)
})

raw_file <- path_raw("nndss_influenza.xlsx")
if (!file.exists(raw_file)) stop("Raw file missing. Run R/01_download.R first.")

# Each sheet is one year range. Row 1 is a title banner, row 2 the real header,
# so skip = 1 and then take the first six columns positionally.
read_sheet <- function(sheet) {
  message("  reading sheet ", sheet)
  readxl::read_excel(raw_file, sheet = sheet, skip = 1,
                     col_types = "text", .name_repair = "minimal")[, 1:6] |>
    setNames(c("date", "state", "age", "sex", "indigenous", "type"))
}

sheets <- readxl::excel_sheets(raw_file)
raw <- bind_rows(lapply(sheets, read_sheet))
message("Read ", format(nrow(raw), big.mark = ","), " raw rows across ", length(sheets), " sheets.")

# --- harmonise -------------------------------------------------------------
clean <- raw |>
  mutate(
    # dates arrive as Excel serial numbers in text; convert robustly
    date = suppressWarnings(as.numeric(date)),
    date = as.Date(date, origin = "1899-12-30"),
    state = str_trim(state),
    age = str_trim(age),
    sex = str_to_title(str_trim(sex)),
    sex = case_when(sex %in% c("Male", "Female") ~ sex, TRUE ~ "Other/unknown"),
    indigenous = str_trim(indigenous),
    indigenous_known = indigenous %in% c("Indigenous", "Non-Indigenous"),
    type = str_trim(type),
    # broad type grouping: influenza A vs B vs other/untyped
    type_group = case_when(
      str_starts(type, "A") ~ "A",
      type == "B" ~ "B",
      TRUE ~ "Other/untyped"
    )
  ) |>
  filter(!is.na(date), state %in% STATE_LEVELS) |>
  mutate(
    age = factor(age, levels = AGE_LEVELS),
    state = factor(state, levels = STATE_LEVELS),
    year = year(date),
    epiweek = isoweek(date),
    month = month(date)
  ) |>
  filter(year >= 2008, year <= 2024)   # 2025 has a single partial week

message("Kept ", format(nrow(clean), big.mark = ","), " notifications, ",
        min(clean$year), " to ", max(clean$year), ".")

dir.create(path_processed(), showWarnings = FALSE, recursive = TRUE)

# --- aggregate 1: weekly national counts (TIME) ----------------------------
weekly_national <- clean |>
  count(date, year, epiweek, name = "notifications") |>
  arrange(date)
write_csv(weekly_national, path_processed("weekly_national.csv"))

# --- aggregate 2: weekly counts by state (PLACE) ---------------------------
weekly_state <- clean |>
  count(date, year, state, name = "notifications") |>
  arrange(date, state)
write_csv(weekly_state, path_processed("weekly_state.csv"))

# --- aggregate 3: annual counts by age and sex (PERSON) --------------------
annual_age_sex <- clean |>
  count(year, age, sex, name = "notifications") |>
  arrange(year, age, sex)
write_csv(annual_age_sex, path_processed("annual_age_sex.csv"))

# --- aggregate 4: season composition by influenza type (PERSON/agent) ------
annual_type <- clean |>
  count(year, type_group, name = "notifications") |>
  group_by(year) |>
  mutate(share = notifications / sum(notifications)) |>
  ungroup()
write_csv(annual_type, path_processed("annual_type.csv"))

# --- aggregate 5: data quality, completeness of Indigenous status ----------
indigenous_completeness <- clean |>
  group_by(year) |>
  summarise(
    total = n(),
    known = sum(indigenous_known),
    completeness = known / total,
    .groups = "drop"
  )
write_csv(indigenous_completeness, path_processed("indigenous_completeness.csv"))

message("Wrote 5 processed tables to data/processed/.")
