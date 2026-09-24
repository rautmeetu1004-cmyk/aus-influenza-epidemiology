# 01_download.R
# Fetches the raw NNDSS influenza workbook and its caveats document into
# data/raw/. The raw file is ~47 MB and is gitignored; this script makes the
# repository reproducible without committing it.

if (!exists("path_raw")) source("R/utils.R")

# Stable URLs published by the Australian CDC (captured 2025). If the CDC moves
# the files, update these two lines; the landing page is:
#   https://www.cdc.gov.au/resources/collections/nndss-public-datasets
URL_DATA <- "https://www.cdc.gov.au/system/files/2025-10/nndss-public-dataset-influenza-laboratory-confirmed.xlsx"
URL_CAVEATS <- "https://www.cdc.gov.au/system/files/2025-10/influenza_laboratory_confirmed_public_dataset_2008_to_2024_data_caveats_0.pdf"

dir.create(path_raw(), showWarnings = FALSE, recursive = TRUE)

download_if_absent <- function(url, dest, required = TRUE, quiet = FALSE) {
  if (file.exists(dest)) {
    message("Already present: ", basename(dest))
    return(invisible(dest))
  }
  message("Downloading ", basename(dest), " ...")
  ok <- tryCatch({
    utils::download.file(url, dest, mode = "wb", quiet = quiet)
    TRUE
  }, error = function(e) { message("  download failed: ", conditionMessage(e)); FALSE })
  if (!ok || !file.exists(dest) || file.info(dest)$size < 1000) {
    if (file.exists(dest)) unlink(dest)
    msg <- paste0("Could not download ", url,
                  "\nThe CDC may have moved the file. Update the URL in R/01_download.R, ",
                  "or download it manually into data/raw/.")
    if (required) stop(msg) else { warning(msg, call. = FALSE); return(invisible(NULL)) }
  }
  message("  saved ", basename(dest), " (", round(file.info(dest)$size / 1e6, 1), " MB)")
  invisible(dest)
}

# The workbook is required; the caveats PDF is supplementary reading, so a
# failure there only warns.
download_if_absent(URL_DATA, path_raw("nndss_influenza.xlsx"), required = TRUE)
download_if_absent(URL_CAVEATS, path_raw("nndss_influenza_caveats.pdf"), required = FALSE)

message("Download step complete.")
