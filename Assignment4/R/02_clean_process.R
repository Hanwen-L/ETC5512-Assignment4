# ---------------------------------------------------------------------------
# 02_clean_process.R
# Clean BOTH buoys (Gold Coast + Tweed Heads), align them to calendar-2025,
# and write the processed datasets used by the blog. Run after 01_download.R.
#
#   data/raw/gold-coast-mk4-2025-waveverifieddata.csv
#   data/raw/tweed-heads-mk4-2025-waveverifieddata.csv
#     -> data/processed/waves_2025_clean.csv     (tidy half-hourly, both sites)
#     -> data/processed/waves_2025_monthly.csv   (monthly summary, site x month)
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(here)
})

dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
value_cols <- c("hs", "hmax", "tz", "tp", "dir", "sst")

# 1. READ each buoy -----------------------------------------------------------
# Read the timestamp as TEXT. If readr type-guesses it, every midnight reading
# ("...T00:00") silently loses its time and 365 rows/year fall into an NA bucket.
read_buoy <- function(path, site) {
  read_csv(path, col_types = cols(`Date/Time (AEST)` = col_character(),
                                  .default = col_double())) |>
    mutate(site = site, .before = 1)
}

raw <- bind_rows(
  read_buoy(here("data", "raw", "gold-coast-mk4-2025-waveverifieddata.csv"), "Gold Coast"),
  read_buoy(here("data", "raw", "tweed-heads-mk4-2025-waveverifieddata.csv"), "Tweed Heads")
)

# 2. TIDY NAMES + TYPES + RECODE MISSING --------------------------------------
waves <- raw |>
  rename(datetime = `Date/Time (AEST)`,
         hs = `Hs (m)`, hmax = `Hmax (m)`, tz = `Tz (s)`, tp = `Tp (s)`,
         dir = `Peak Direction (degrees)`, sst = `SST (degrees C)`) |>
  mutate(
    site     = factor(site, levels = c("Gold Coast", "Tweed Heads")),
    datetime = ymd_hms(datetime, truncated = 1, tz = "Australia/Brisbane")
  ) |>
  # -99.9 is the buoy's "no valid reading" sentinel -> NA
  mutate(across(all_of(value_cols), \(x) if_else(x == -99.9, NA_real_, x))) |>
  # 3. ALIGN both buoys to the same window. Tweed's file runs into 2026, so
  #    restrict both to calendar-2025 to make the comparison fair.
  filter(year(datetime) == 2025)

# 4. DERIVE time features -----------------------------------------------------
waves <- waves |>
  mutate(
    date      = as_date(datetime),
    month     = factor(month(datetime, label = TRUE, abbr = TRUE),
                       levels = month.abb, ordered = TRUE),
    month_num = month(datetime),
    season    = factor(case_when(            # Southern-Hemisphere seasons
      month_num %in% c(12, 1, 2) ~ "Summer",
      month_num %in% c(3, 4, 5)  ~ "Autumn",
      month_num %in% c(6, 7, 8)  ~ "Winter",
      TRUE                       ~ "Spring"),
      levels = c("Summer", "Autumn", "Winter", "Spring"))
  ) |>
  relocate(site, datetime, date, month, season)

# 5. SANITY CHECKS (per site) -------------------------------------------------
chk <- waves |>
  group_by(site) |>
  summarise(n = n(),
            all_parsed = !any(is.na(datetime)),
            no_dups    = !any(duplicated(datetime)),
            regular    = all(as.numeric(diff(sort(datetime)), units = "mins") == 30),
            .groups = "drop")
stopifnot(all(chk$n == 17520), all(chk$all_parsed), all(chk$no_dups), all(chk$regular))

# 6. MONTHLY SUMMARY (site x month) ------------------------------------------
monthly <- waves |>
  group_by(site, month, month_num, season) |>
  summarise(
    n_obs          = n(),
    valid_hs       = sum(!is.na(hs)),
    pct_missing_hs = round(100 * mean(is.na(hs)), 1),
    mean_hs        = mean(hs,  na.rm = TRUE),
    max_hs         = max(hs,   na.rm = TRUE),
    max_hmax       = max(hmax, na.rm = TRUE),
    mean_tp        = mean(tp,  na.rm = TRUE),
    mean_sst       = mean(sst, na.rm = TRUE),
    n_big_hs3      = sum(hs >= 3, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(site, month_num) |>
  mutate(across(where(is.numeric), \(x) round(x, 2)))

# 7. WRITE --------------------------------------------------------------------
write_csv(waves,   here("data", "processed", "waves_2025_clean.csv"))
write_csv(monthly, here("data", "processed", "waves_2025_monthly.csv"))

# 8. SHORT REPORT -------------------------------------------------------------
cat("\n--- processed/waves_2025_clean.csv ---\n")
cat("rows:", nrow(waves), " sites:", paste(levels(waves$site), collapse = ", "), "\n")
waves |>
  group_by(site) |>
  summarise(across(all_of(value_cols), \(x) round(100 * mean(is.na(x)), 2)),
            .groups = "drop") |>
  rename_with(\(n) paste0("%miss_", n), all_of(value_cols)) |>
  as.data.frame() |> print(row.names = FALSE)
cat("\nDone.\n")
