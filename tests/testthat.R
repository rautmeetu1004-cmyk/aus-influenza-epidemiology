# Entry point for the test suite:  Rscript tests/testthat.R
library(testthat)
testthat::test_dir("tests/testthat", reporter = "summary", stop_on_failure = TRUE)
