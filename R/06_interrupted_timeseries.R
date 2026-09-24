# 06_interrupted_timeseries.R
# The analytic step beyond description: quantify the COVID-era disruption with a
# counterfactual. A negative binomial GLM with a linear trend and harmonic
# seasonality is fit to the pre-pandemic years (2015 to 2019), then used to
# predict what 2020 to 2021 would have looked like without the interruption.
# Observed-versus-expected gives the size of the collapse.

if (!exists("path_processed")) source("R/utils.R")
suppressPackageStartupMessages({ library(dplyr); library(readr); library(ggplot2); library(lubridate); library(scales); library(MASS) })

weekly <- read_csv(path_processed("weekly_national.csv"), show_col_types = FALSE) |>
  arrange(date) |>
  mutate(
    w = 2 * pi * as.numeric(format(date, "%j")) / 365.25,  # annual angle from day-of-year
    sin1 = sin(w), cos1 = cos(w), sin2 = sin(2 * w), cos2 = cos(2 * w)
  )

train <- weekly |> filter(year >= 2015, year <= 2019)   # pre-pandemic baseline
eval  <- weekly |> filter(year >= 2015, year <= 2021)    # baseline + disruption

# Negative binomial handles the overdispersion typical of notification counts.
# We deliberately fit seasonality (harmonic terms) with no secular time trend:
# influenza notifications are episodic, not trending, so the counterfactual is
# "an average pre-pandemic season", and a linear trend would extrapolate the
# unusually large 2019 season into an implausible 2021 expectation.
fit <- glm.nb(notifications ~ sin1 + cos1 + sin2 + cos2, data = train)

pred <- predict(fit, newdata = eval, type = "link", se.fit = TRUE)
eval <- eval |>
  mutate(
    expected = exp(pred$fit),
    lo = exp(pred$fit - 1.96 * pred$se.fit),
    hi = exp(pred$fit + 1.96 * pred$se.fit)
  )

# --- observed vs counterfactual expected -----------------------------------
p_its <- ggplot(eval, aes(date)) +
  annotate("rect", xmin = as.Date("2020-03-15"), xmax = as.Date("2021-12-31"),
           ymin = -Inf, ymax = Inf, fill = pal$grey, alpha = 0.12) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = pal$blue, alpha = 0.18) +
  geom_line(aes(y = expected, colour = "Expected (no COVID)"), linewidth = 0.8) +
  geom_line(aes(y = notifications, colour = "Observed"), linewidth = 0.6) +
  scale_colour_manual(values = c("Observed" = pal$terra, "Expected (no COVID)" = pal$blue), name = NULL) +
  scale_y_continuous(labels = comma) +
  scale_x_date(date_breaks = "1 year", labels = date_format("%Y")) +
  labs(title = "Influenza ran far below its counterfactual through 2020 to 2021",
       subtitle = "Negative binomial seasonal model (average pre-pandemic season, 2015 to 2019), projected forward",
       x = NULL, y = "Weekly notifications", caption = SOURCE_CAPTION) +
  theme_flu()
save_fig(p_its, "08_interrupted_timeseries.png")

# --- quantify the reduction ------------------------------------------------
summary_tbl <- eval |>
  filter(year %in% c(2020, 2021)) |>
  group_by(year) |>
  summarise(observed = sum(notifications), expected = round(sum(expected)), .groups = "drop") |>
  mutate(reduction = 1 - observed / expected)
write_csv(summary_tbl, path_tab("its_observed_vs_expected.csv"))

# model coefficients for the record
coef_tbl <- as.data.frame(summary(fit)$coefficients)
coef_tbl$term <- rownames(coef_tbl)
write_csv(coef_tbl, path_tab("its_model_coefficients.csv"))

message("Interrupted time series complete.")
for (i in seq_len(nrow(summary_tbl))) {
  message("  ", summary_tbl$year[i], ": observed ", format(summary_tbl$observed[i], big.mark = ","),
          " vs expected ", format(summary_tbl$expected[i], big.mark = ","),
          " (", round(summary_tbl$reduction[i] * 100), "% lower)")
}
