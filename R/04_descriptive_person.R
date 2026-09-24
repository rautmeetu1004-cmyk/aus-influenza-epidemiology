# 04_descriptive_person.R
# PERSON arm of the triad: who is notified (age, sex), what subtype circulates,
# and an honest look at how complete the Indigenous-status field is.

if (!exists("path_processed")) source("R/utils.R")
suppressPackageStartupMessages({ library(dplyr); library(readr); library(tidyr); library(ggplot2); library(scales) })

age_sex <- read_csv(path_processed("annual_age_sex.csv"), show_col_types = FALSE) |>
  mutate(age = factor(age, levels = AGE_LEVELS))

# --- age profile (all years pooled) ---------------------------------------
age_profile <- age_sex |>
  filter(sex %in% c("Male", "Female")) |>
  group_by(age, sex) |>
  summarise(notifications = sum(notifications), .groups = "drop")

p_age <- ggplot(age_profile, aes(age, notifications, fill = sex)) +
  geom_col(position = "dodge", width = 0.75) +
  scale_fill_manual(values = c(Female = pal$terra, Male = pal$blue), name = NULL) +
  scale_y_continuous(labels = comma) +
  labs(title = "The very young carry the highest notification counts",
       subtitle = "Total laboratory-confirmed influenza notifications by age group and sex, 2008 to 2024",
       x = "Age group (years)", y = "Notifications", caption = SOURCE_CAPTION) +
  theme_flu() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_fig(p_age, "03_age_sex_profile.png")

# --- subtype composition over time ----------------------------------------
type <- read_csv(path_processed("annual_type.csv"), show_col_types = FALSE)
p_type <- ggplot(type, aes(year, share, fill = type_group)) +
  geom_area(alpha = 0.9) +
  scale_fill_manual(values = c(A = pal$indigo, B = pal$ochre, `Other/untyped` = pal$grey), name = "Type") +
  scale_y_continuous(labels = percent) +
  scale_x_continuous(breaks = seq(2008, 2024, 4)) +
  labs(title = "Influenza A dominates, but B surges in some seasons",
       subtitle = "Share of annual notifications by influenza type",
       x = NULL, y = "Share of notifications", caption = SOURCE_CAPTION) +
  theme_flu()
save_fig(p_type, "04_type_composition.png")

# --- data-quality panel: Indigenous-status completeness --------------------
comp <- read_csv(path_processed("indigenous_completeness.csv"), show_col_types = FALSE)
p_comp <- ggplot(comp, aes(year, completeness)) +
  geom_col(fill = pal$teal, alpha = 0.85, width = 0.7) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = pal$terra) +
  scale_y_continuous(labels = percent, limits = c(0, 1)) +
  scale_x_continuous(breaks = seq(2008, 2024, 4)) +
  labs(title = "A real limitation: Indigenous status is often not recorded",
       subtitle = "Share of notifications with a usable Indigenous status (Indigenous or Non-Indigenous)",
       x = NULL, y = "Completeness",
       caption = paste(SOURCE_CAPTION, "Dashed line at 50%. Analyses of this field must not be over-interpreted.")) +
  theme_flu()
save_fig(p_comp, "05_indigenous_completeness.png")

write_csv(age_profile, path_tab("age_sex_profile.csv"))
message("Person arm complete. Mean Indigenous-status completeness: ",
        round(mean(comp$completeness) * 100, 1), "%")
