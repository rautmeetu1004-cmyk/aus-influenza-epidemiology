# 05_descriptive_place.R
# PLACE arm of the triad: how notifications distribute across states and
# territories, and how the seasonal peak times differ between jurisdictions.
# Counts only (not rates): see README on why denominators matter here.

if (!exists("path_processed")) source("R/utils.R")
suppressPackageStartupMessages({ library(dplyr); library(readr); library(ggplot2); library(lubridate); library(scales) })

weekly_state <- read_csv(path_processed("weekly_state.csv"), show_col_types = FALSE) |>
  mutate(state = factor(state, levels = STATE_LEVELS))

# --- annual notifications by state (small multiples) -----------------------
annual_state <- weekly_state |>
  group_by(year, state) |>
  summarise(notifications = sum(notifications), .groups = "drop")

p_state <- ggplot(annual_state, aes(year, notifications, colour = state)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = state_colours, name = NULL) +
  scale_y_continuous(labels = comma) +
  scale_x_continuous(breaks = seq(2008, 2024, 4)) +
  facet_wrap(~state, scales = "free_y", ncol = 4) +
  labs(title = "Every jurisdiction shows the 2020 collapse and 2022 rebound",
       subtitle = "Annual laboratory-confirmed influenza notifications by state and territory",
       x = NULL, y = "Notifications (free y scale)", caption = SOURCE_CAPTION) +
  theme_flu() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))
save_fig(p_state, "06_state_trends.png", height = 5.6)

# --- timing of the seasonal peak, pre-pandemic -----------------------------
peak_week <- weekly_state |>
  filter(year >= 2015, year <= 2019) |>
  group_by(year, state) |>
  slice_max(notifications, n = 1, with_ties = FALSE) |>
  mutate(peak_week = isoweek(date)) |>
  group_by(state) |>
  summarise(median_peak_week = median(peak_week),
            earliest = min(peak_week), latest = max(peak_week), .groups = "drop") |>
  arrange(median_peak_week)

p_peak <- ggplot(peak_week, aes(median_peak_week, reorder(state, -median_peak_week))) +
  geom_segment(aes(x = earliest, xend = latest, yend = state), colour = pal$rule, linewidth = 3) +
  geom_point(colour = pal$terra, size = 3.4) +
  scale_x_continuous(breaks = seq(20, 48, 4)) +
  labs(title = "The season peaks later in the south than the north",
       subtitle = "Median ISO week of the annual peak, 2015 to 2019 (bar: earliest to latest peak week)",
       x = "ISO week of seasonal peak", y = NULL, caption = SOURCE_CAPTION) +
  theme_flu()
save_fig(p_peak, "07_peak_timing.png", height = 4.4)

write_csv(annual_state, path_tab("annual_by_state.csv"))
write_csv(peak_week, path_tab("peak_timing_by_state.csv"))
message("Place arm complete.")
