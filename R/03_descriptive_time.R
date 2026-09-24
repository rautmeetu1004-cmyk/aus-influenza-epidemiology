# 03_descriptive_time.R
# TIME arm of the descriptive triad: the weekly epidemic curve across 17 years,
# and the winter seasonality that defines Australian influenza.

if (!exists("path_processed")) source("R/utils.R")
suppressPackageStartupMessages({ library(dplyr); library(readr); library(ggplot2); library(lubridate); library(scales) })

weekly <- read_csv(path_processed("weekly_national.csv"), show_col_types = FALSE)

# --- epidemic curve, 2008 to 2024 -----------------------------------------
p_curve <- ggplot(weekly, aes(date, notifications)) +
  annotate("rect", xmin = as.Date("2020-03-15"), xmax = as.Date("2021-12-31"),
           ymin = -Inf, ymax = Inf, fill = pal$grey, alpha = 0.12) +
  annotate("text", x = as.Date("2020-11-01"), y = Inf, vjust = 1.6, hjust = 0.5,
           label = "COVID-19\nrestrictions", size = 3, colour = pal$grey) +
  geom_line(colour = pal$teal, linewidth = 0.5) +
  scale_x_date(date_breaks = "2 years", labels = date_format("%Y")) +
  scale_y_continuous(labels = comma) +
  labs(title = "Australian influenza notifications collapsed under COVID-19 measures",
       subtitle = "Weekly laboratory-confirmed notifications, NNDSS, 2008 to 2024",
       x = NULL, y = "Weekly notifications", caption = SOURCE_CAPTION) +
  theme_flu()
save_fig(p_curve, "01_epidemic_curve.png")

# --- seasonality: median notifications by ISO week, pre-pandemic ------------
seasonal <- weekly |>
  filter(year >= 2015, year <= 2019) |>
  group_by(epiweek) |>
  summarise(median = median(notifications),
            lo = quantile(notifications, 0.25),
            hi = quantile(notifications, 0.75), .groups = "drop")

p_season <- ggplot(seasonal, aes(epiweek, median)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = pal$teal, alpha = 0.18) +
  geom_line(colour = pal$teal, linewidth = 0.9) +
  annotate("text", x = 32, y = max(seasonal$hi), label = "August peak",
           colour = pal$ink, size = 3.4, vjust = 1) +
  scale_x_continuous(breaks = seq(1, 52, 4)) +
  scale_y_continuous(labels = comma) +
  labs(title = "A sharp southern-hemisphere winter season",
       subtitle = "Median weekly notifications by ISO week, pre-pandemic baseline 2015 to 2019 (band: IQR)",
       x = "ISO week of year", y = "Notifications", caption = SOURCE_CAPTION) +
  theme_flu()
save_fig(p_season, "02_seasonality.png")

# --- annual totals table ---------------------------------------------------
annual <- weekly |> group_by(year) |> summarise(notifications = sum(notifications), .groups = "drop")
write_csv(annual, path_tab("annual_totals.csv"))
message("Time arm complete. 2019 total: ", format(annual$notifications[annual$year==2019], big.mark=","),
        " | 2020 total: ", format(annual$notifications[annual$year==2020], big.mark=","))
