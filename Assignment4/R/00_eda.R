# 00_eda.R — exploratory analysis to surface the real findings
# (scratch script; not part of the final reproducible pipeline)
suppressPackageStartupMessages(library(tidyverse))

raw <- read_csv("data/raw/gold-coast-mk4-2025-waveverifieddata.csv",
                col_types = cols(`Date/Time (AEST)` = col_character(), .default = col_double()))

cat("==== DIMENSIONS & NAMES ====\n")
cat("rows:", nrow(raw), " cols:", ncol(raw), "\n")
print(names(raw))

# Tidy names
df <- raw |>
  rename(
    datetime = `Date/Time (AEST)`,
    hs   = `Hs (m)`,
    hmax = `Hmax (m)`,
    tz   = `Tz (s)`,
    tp   = `Tp (s)`,
    dir  = `Peak Direction (degrees)`,
    sst  = `SST (degrees C)`
  ) |>
  mutate(datetime = ymd_hms(datetime, truncated = 1, tz = "Australia/Brisbane"))

cat("\n==== DATETIME RANGE & SPACING ====\n")
cat("min:", format(min(df$datetime)), " max:", format(max(df$datetime)), "\n")
gaps <- as.numeric(diff(df$datetime), units = "mins")
cat("modal spacing (mins):", as.numeric(names(sort(table(gaps), decreasing=TRUE))[1]), "\n")
cat("any duplicated timestamps:", any(duplicated(df$datetime)), "\n")
cat("expected half-hour rows for 2025:", as.integer(difftime(max(df$datetime), min(df$datetime), units="mins")/30 + 1), "\n")

cat("\n==== SENTINEL -99.9 COUNTS (raw, before recode) ====\n")
val_cols <- c("hs","hmax","tz","tp","dir","sst")
for (c in val_cols) {
  n <- sum(df[[c]] == -99.9, na.rm = TRUE)
  cat(sprintf("%-5s  n=-99.9: %5d  (%.2f%%)\n", c, n, 100*n/nrow(df)))
}

# Recode sentinel -> NA
df <- df |> mutate(across(all_of(val_cols), ~ if_else(.x == -99.9, NA_real_, .x)))

cat("\n==== VALID RANGES (after recode) ====\n")
df |>
  summarise(across(all_of(val_cols),
                   list(min = ~min(.x, na.rm=TRUE),
                        max = ~max(.x, na.rm=TRUE),
                        mean = ~mean(.x, na.rm=TRUE),
                        na = ~sum(is.na(.x))))) |>
  pivot_longer(everything()) |>
  separate(name, into = c("var","stat"), sep = "_(?=[^_]+$)") |>
  pivot_wider(names_from = stat, values_from = value) |>
  print(n = 50)

# Derive month + season (Southern Hemisphere)
df <- df |>
  mutate(
    month = month(datetime, label = TRUE),
    month_num = month(datetime),
    season = case_when(
      month_num %in% c(12,1,2) ~ "Summer",
      month_num %in% c(3,4,5)  ~ "Autumn",
      month_num %in% c(6,7,8)  ~ "Winter",
      TRUE                      ~ "Spring"
    )
  )

cat("\n==== MONTHLY SUMMARY ====\n")
monthly <- df |>
  group_by(month) |>
  summarise(
    n = n(),
    valid_hs = sum(!is.na(hs)),
    pct_missing_hs = round(100*mean(is.na(hs)),1),
    mean_hs = round(mean(hs, na.rm=TRUE),2),
    max_hs = round(max(hs, na.rm=TRUE),2),
    max_hmax = round(max(hmax, na.rm=TRUE),2),
    mean_tp = round(mean(tp, na.rm=TRUE),2),
    mean_sst = round(mean(sst, na.rm=TRUE),2),
    .groups="drop"
  )
print(monthly, n = 20)

cat("\n==== SEASONAL SUMMARY ====\n")
df |>
  group_by(season) |>
  summarise(mean_hs = round(mean(hs,na.rm=TRUE),2),
            max_hs = round(max(hs,na.rm=TRUE),2),
            mean_sst = round(mean(sst,na.rm=TRUE),2),
            mean_tp = round(mean(tp,na.rm=TRUE),2),
            .groups="drop") |>
  print()

cat("\n==== BIG-WAVE EVENTS ====\n")
# percentiles of Hs
q <- quantile(df$hs, c(.5,.9,.95,.99), na.rm=TRUE)
cat("Hs quantiles (50/90/95/99):", round(q,2), "\n")
thr <- 3
cat(sprintf("Half-hours with Hs >= %.1f m: %d (%.2f%% of valid)\n",
            thr, sum(df$hs >= thr, na.rm=TRUE),
            100*mean(df$hs >= thr, na.rm=TRUE)))
cat("Big-wave half-hours (Hs>=3) by month:\n")
df |> filter(hs >= thr) |> count(month) |> print(n=20)

cat("\nTop 5 single largest Hs readings:\n")
df |> slice_max(hs, n=5) |>
  select(datetime, hs, hmax, tp, tz, dir, sst) |> print()

cat("\nTop 5 single largest Hmax readings:\n")
df |> slice_max(hmax, n=5) |>
  select(datetime, hs, hmax, tp, tz, dir, sst) |> print()

cat("\n==== Hs vs Tp & correlations ====\n")
cc <- df |> filter(!is.na(hs), !is.na(tp))
cat("cor(Hs, Tp) pearson:", round(cor(cc$hs, cc$tp),3), "\n")
cat("cor(Hs, Tp) spearman:", round(cor(cc$hs, cc$tp, method="spearman"),3), "\n")
cs <- df |> filter(!is.na(hs), !is.na(sst))
cat("cor(Hs, SST):", round(cor(cs$hs, cs$sst),3), "\n")
# monthly-mean correlation Hs vs SST (seasonal)
mm <- monthly |> filter(is.finite(mean_hs), is.finite(mean_sst))
cat("cor(monthly mean Hs, monthly mean SST):", round(cor(mm$mean_hs, mm$mean_sst),3), "\n")

# Wave steepness proxy: Hs / (Tp^2) — wind sea is steeper
cat("\n==== wave 'steepness' deciles of Tp ====\n")
df |> filter(!is.na(hs),!is.na(tp)) |>
  mutate(tp_bin = cut(tp, breaks=c(0,6,8,10,12,14,30))) |>
  group_by(tp_bin) |>
  summarise(n=n(), mean_hs=round(mean(hs),2), .groups="drop") |> print()

cat("\nDONE\n")
