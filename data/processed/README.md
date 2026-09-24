# Processed data

Small tidy aggregates written by `R/02_clean.R` from the raw NNDSS line list.
These are committed so figures and tests run without the 47 MB raw workbook.

| File | Grain | Columns |
|---|---|---|
| `weekly_national.csv` | one row per ISO week | date, year, epiweek, notifications |
| `weekly_state.csv` | week x state | date, year, state, notifications |
| `annual_age_sex.csv` | year x age x sex | year, age, sex, notifications |
| `annual_type.csv` | year x influenza type | year, type_group, notifications, share |
| `indigenous_completeness.csv` | year | total, known, completeness |

All counts are notifications, not incidence. See the top-level README for caveats.
