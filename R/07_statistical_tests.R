# 07_statistical_tests.R
# A set of classical statistical tests applied to the influenza data. The point
# is not only the p-values (with ~2 million records almost everything is
# "significant") but the effect sizes and the model justification. Each test is
# written out to outputs/tables/ so the numbers on the study page are reproducible.

if (!exists("path_processed")) source("R/utils.R")
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tidyr); library(MASS) })

results <- list()

# ---------------------------------------------------------------------------
# 1. Overdispersion: is a negative binomial justified over Poisson?
#    Fit both seasonal models to the weekly national series and compare with a
#    likelihood ratio test, plus the Pearson dispersion statistic.
# ---------------------------------------------------------------------------
weekly <- read_csv(path_processed("weekly_national.csv"), show_col_types = FALSE) |>
  mutate(
    w = 2 * pi * as.numeric(format(as.Date(date), "%j")) / 365.25,
    sin1 = sin(w), cos1 = cos(w), sin2 = sin(2 * w), cos2 = cos(2 * w)
  ) |>
  filter(year >= 2015, year <= 2019)

pois <- glm(notifications ~ sin1 + cos1 + sin2 + cos2, family = poisson, data = weekly)
nb   <- glm.nb(notifications ~ sin1 + cos1 + sin2 + cos2, data = weekly)

pearson_disp <- sum(residuals(pois, type = "pearson")^2) / pois$df.residual
# LRT: 2 * (logLik_nb - logLik_pois), 1 df for the extra dispersion parameter
lrt_stat <- as.numeric(2 * (logLik(nb) - logLik(pois)))
lrt_p <- pchisq(lrt_stat, df = 1, lower.tail = FALSE)

results$overdispersion <- data.frame(
  test = "Poisson vs negative binomial (LRT)",
  pearson_dispersion = round(pearson_disp, 2),
  lrt_statistic = round(lrt_stat, 1),
  df = 1,
  p_value = signif(lrt_p, 3),
  conclusion = "negative binomial justified"
)
message("1. Overdispersion: Pearson dispersion = ", round(pearson_disp, 1),
        " (>> 1), LRT p = ", signif(lrt_p, 3))

# ---------------------------------------------------------------------------
# 2. Chi-square test of independence: influenza type (A vs B) x age group.
#    With effect size (Cramer's V), because n is enormous.
# ---------------------------------------------------------------------------
age_type <- read_csv(path_processed("age_type.csv"), show_col_types = FALSE) |>
  filter(type_group %in% c("A", "B"), !is.na(age))
tab_age <- xtabs(notifications ~ age + type_group, data = age_type)
chi_age <- suppressWarnings(chisq.test(tab_age))
n_age <- sum(tab_age)
cramer_age <- sqrt(as.numeric(chi_age$statistic) / (n_age * (min(dim(tab_age)) - 1)))

results$chisq_age_type <- data.frame(
  test = "Chi-square independence: type (A/B) x age",
  chi_square = round(as.numeric(chi_age$statistic), 1),
  df = as.integer(chi_age$parameter),
  p_value = signif(chi_age$p.value, 3),
  n = n_age,
  cramers_v = round(cramer_age, 3),
  effect = ifelse(cramer_age < 0.1, "negligible", ifelse(cramer_age < 0.3, "small", "moderate+"))
)
message("2. Chi-square type x age: X2 = ", round(as.numeric(chi_age$statistic)),
        ", p = ", signif(chi_age$p.value, 3), ", Cramer's V = ", round(cramer_age, 3))

# ---------------------------------------------------------------------------
# 3. Chi-square test of independence: influenza type (A vs B) x sex.
# ---------------------------------------------------------------------------
sex_type <- read_csv(path_processed("sex_type.csv"), show_col_types = FALSE) |>
  filter(type_group %in% c("A", "B"), sex %in% c("Female", "Male"))
tab_sex <- xtabs(notifications ~ sex + type_group, data = sex_type)
chi_sex <- suppressWarnings(chisq.test(tab_sex))
n_sex <- sum(tab_sex)
phi_sex <- sqrt(as.numeric(chi_sex$statistic) / n_sex)   # phi = Cramer's V for 2x2

results$chisq_sex_type <- data.frame(
  test = "Chi-square independence: type (A/B) x sex",
  chi_square = round(as.numeric(chi_sex$statistic), 1),
  df = as.integer(chi_sex$parameter),
  p_value = signif(chi_sex$p.value, 3),
  n = n_sex,
  phi = round(phi_sex, 3),
  effect = ifelse(phi_sex < 0.1, "negligible", ifelse(phi_sex < 0.3, "small", "moderate+"))
)
message("3. Chi-square type x sex: X2 = ", round(as.numeric(chi_sex$statistic)),
        ", p = ", signif(chi_sex$p.value, 3), ", phi = ", round(phi_sex, 3))

# ---------------------------------------------------------------------------
# 4. Incidence rate ratio: 2020 versus the pre-pandemic baseline (2015-2019),
#    with an exact Poisson 95% confidence interval on the annual counts.
# ---------------------------------------------------------------------------
annual <- read_csv(path_processed("weekly_national.csv"), show_col_types = FALSE) |>
  group_by(year) |> summarise(n = sum(notifications), .groups = "drop")
base_years <- annual |> filter(year >= 2015, year <= 2019)
base_rate <- mean(base_years$n)            # mean annual notifications, baseline
obs_2020 <- annual$n[annual$year == 2020]
# treat baseline mean as the expected count; exact Poisson test of observed vs expected
irr_test <- poisson.test(x = obs_2020, T = 1, r = base_rate)
results$rate_ratio_2020 <- data.frame(
  test = "Rate ratio 2020 vs 2015-2019 baseline (exact Poisson)",
  observed_2020 = obs_2020,
  expected_baseline = round(base_rate),
  rate_ratio = round(irr_test$estimate / base_rate, 3),
  ci_low = round(irr_test$conf.int[1] / base_rate, 3),
  ci_high = round(irr_test$conf.int[2] / base_rate, 3),
  p_value = signif(irr_test$p.value, 3)
)
message("4. Rate ratio 2020 vs baseline: RR = ", round(obs_2020 / base_rate, 3),
        " (95% CI ", round(irr_test$conf.int[1] / base_rate, 3), " to ",
        round(irr_test$conf.int[2] / base_rate, 3), ")")

# ---------------------------------------------------------------------------
# write everything out
# ---------------------------------------------------------------------------
out <- bind_rows(lapply(names(results), function(nm) {
  df <- results[[nm]]
  tidyr::pivot_longer(df, cols = -test, names_to = "quantity", values_to = "value",
                      values_transform = as.character)
}))
write_csv(out, path_tab("statistical_tests.csv"))
message("\nWrote outputs/tables/statistical_tests.csv (", nrow(out), " rows).")
