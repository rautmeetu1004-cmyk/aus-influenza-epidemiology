# Sanity checks on the processed aggregates. These guard against a broken clean
# step: right columns, plausible totals, no impossible values.
# Run with:  Rscript tests/testthat.R

library(testthat)
library(readr)

root <- normalizePath(file.path(dirname(dirname(getwd())), ".."), mustWork = FALSE)
pp <- function(f) {
  for (cand in c(file.path("data/processed", f),
                 file.path("../../data/processed", f))) if (file.exists(cand)) return(cand)
  file.path("data/processed", f)
}

test_that("weekly national series is well formed", {
  d <- read_csv(pp("weekly_national.csv"), show_col_types = FALSE)
  expect_true(all(c("date", "year", "epiweek", "notifications") %in% names(d)))
  expect_gt(nrow(d), 800)                    # ~17 years of weeks
  expect_true(all(d$notifications >= 0))
  expect_true(all(d$year >= 2008 & d$year <= 2024))
})

test_that("state series covers all eight jurisdictions", {
  d <- read_csv(pp("weekly_state.csv"), show_col_types = FALSE)
  expect_setequal(unique(d$state), c("NSW","Vic","Qld","SA","WA","Tas","ACT","NT"))
})

test_that("type shares sum to one within each year", {
  d <- read_csv(pp("annual_type.csv"), show_col_types = FALSE)
  agg <- tapply(d$share, d$year, sum)
  expect_true(all(abs(agg - 1) < 1e-6))
})

test_that("indigenous completeness is a proportion", {
  d <- read_csv(pp("indigenous_completeness.csv"), show_col_types = FALSE)
  expect_true(all(d$completeness >= 0 & d$completeness <= 1))
})
