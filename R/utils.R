# utils.R
# Shared paths, a plotting theme, and small helpers used across scripts.

# Anchor every path at the project root so scripts run from anywhere.
# Walk up from the working directory until the .Rproj file is found.
if (!exists("PROJ_ROOT")) {
  .find_root <- function(start = getwd()) {
    d <- normalizePath(start, mustWork = FALSE)
    for (i in 1:10) {
      if (file.exists(file.path(d, "aus-influenza-epidemiology.Rproj"))) return(d)
      parent <- dirname(d)
      if (identical(parent, d)) break
      d <- parent
    }
    getwd()
  }
  PROJ_ROOT <- .find_root()
}
path_raw       <- function(...) file.path(PROJ_ROOT, "data", "raw", ...)
path_processed <- function(...) file.path(PROJ_ROOT, "data", "processed", ...)
path_fig       <- function(...) file.path(PROJ_ROOT, "outputs", "figures", ...)
path_tab       <- function(...) file.path(PROJ_ROOT, "outputs", "tables", ...)

# Palette shared with the portfolio site, so figures look of a piece.
pal <- list(
  ink   = "#15222c",
  teal  = "#0f6b6f",
  blue  = "#2f6fd0",
  indigo = "#34509c",
  terra = "#b8552f",
  ochre = "#b98a1f",
  green = "#2f8a5b",
  grey  = "#7a8591",
  rule  = "#d8e3f0"
)
state_colours <- c(
  NSW = "#34509c", Vic = "#0f6b6f", Qld = "#b8552f", WA = "#b98a1f",
  SA  = "#2f8a5b", Tas = "#7a8591", ACT = "#2f6fd0", NT = "#8a4f9e"
)

theme_flu <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = base_size + 3),
      plot.subtitle = ggplot2::element_text(colour = pal$grey, margin = ggplot2::margin(b = 8)),
      plot.caption  = ggplot2::element_text(colour = pal$grey, hjust = 0, size = base_size - 3),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = pal$rule, linewidth = 0.4),
      axis.title    = ggplot2::element_text(colour = pal$ink),
      legend.position = "bottom"
    )
}

SOURCE_CAPTION <- paste(
  "Source: NNDSS public dataset, influenza (laboratory confirmed), 2008 to 2024.",
  "Australian CDC. Notifications, not incidence: see README caveats."
)

save_fig <- function(plot, file, width = 9, height = 5.2, dpi = 200) {
  ggplot2::ggsave(path_fig(file), plot, width = width, height = height, dpi = dpi, bg = "white")
  message("  wrote ", file.path("outputs/figures", file))
}

# Order age groups the way the dataset presents them (youngest to oldest).
AGE_LEVELS <- c("00-04","05-09","10-14","15-19","20-24","25-29","30-34","35-39",
                "40-44","45-49","50-54","55-59","60-64","65-69","70-74","75-79","80-84","85+")
STATE_LEVELS <- c("NSW","Vic","Qld","SA","WA","Tas","ACT","NT")
