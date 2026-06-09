# Metadata — Coastal Data System Waves (Gold Coast + Tweed Heads), 2025

Two wave-monitoring buoys from the **Queensland Government Open Data Portal**
(<https://www.data.qld.gov.au>), both the **"Wave data – 2025"** resource of a
*Coastal Data System – Waves* dataset, both **CC BY 4.0**. Gold Coast is the primary buoy;
Tweed Heads (≈ 27 km south, across the NSW border) is the comparison/robustness buoy.

## Dataset identity
| Field | Gold Coast (primary) | Tweed Heads (comparison) |
|---|---|---|
| Dataset page | [coastal-data-system-waves-gold-coast](https://www.data.qld.gov.au/dataset/coastal-data-system-waves-gold-coast) | [coastal-data-system-waves-tweed-heads](https://www.data.qld.gov.au/dataset/coastal-data-system-waves-tweed-heads) |
| 2025 resource id | `a8a12129-c99d-45f6-832b-a5cee4754b54` | `bc667055-aa5c-4449-ba26-3953e99ccf67` |
| Custodian | DETSI + City of Gold Coast | DETSI + Tweed River Sand Bypassing Project |
| Location | 27.9649° S, 153.44095° E | 28.17708° S, 153.57633° E |
| Water depth | ~17 m | ~22 m |
| Instrument | Datawell Directional Waverider | Datawell MK4 0.9 m Waverider |
| Operating since | 20 Feb 1987 | 13 Jan 1995 |
| Licence | CC BY 4.0 | CC BY 4.0 |
| Field definitions | <https://www.qld.gov.au/waves> | <https://www.qld.gov.au/waves> |

## What the data is
Measured and derived **wave parameters** plus **sea surface temperature** recorded by a
**Datawell Waverider buoy**. Each row is one 26.6-minute recording; records are written every
**30 minutes**. This is **observational instrument (sensor) data** — not a survey sample and
not an experiment. For each buoy it is effectively a **census** of every successful
half-hourly record in 2025.

## Coverage
| Dimension | Detail |
|---|---|
| Temporal | 1 Jan 2025 00:00 → 31 Dec 2025 23:30 (AEST), 30-min step. **Note:** the Tweed Heads file as published runs to 1 Jan 2026; the pipeline clips it to calendar-2025. |
| Rows (per site, 2025) | 17,520 (48 × 365), complete and regular |
| Timezone | AEST (UTC+10), constant — Queensland has no daylight saving |
| Distance apart | ≈ 27.1 km (haversine), computed in the report |

## Variables
7 columns in each raw file (`Date/Time (AEST)`, `Hs (m)`, `Hmax (m)`, `Tz (s)`, `Tp (s)`,
`Peak Direction (degrees)`, `SST (degrees C)`); a `site` column is added when the two files
are combined. See `data_dictionary.csv` for full definitions, units and valid ranges.

## Missing data
Unsuccessful/invalid readings use the sentinel **`-99.9`** (not blank). In 2025: Gold Coast
~4.53% missing for wave parameters (with a **~25% outage in March**); Tweed Heads ~0.1%
missing (near-complete). The cleaning step recodes `-99.9` to `NA`.

## Provenance / processing
`R/01_download.R` downloads both files from their portal URLs (with offline fallback to the
committed copies) and verifies structure. `R/02_clean_process.R` reads both, recodes the
sentinel, clips to 2025, binds them with a `site` label, derives time features, runs per-site
assertions, and writes the processed datasets. Raw data is never edited by hand.
Committed raw MD5s: Gold Coast `1b3f4607a1e72de005f21d445eb5ab8d`,
Tweed Heads `0a8a40a82ef29e951bcfadcd2f60264d`.

## Ethics, privacy & attribution
- **No personal data.** Both datasets measure the physical ocean only — no humans, vessels or
  identifiable subjects — so privacy/re-identification risk is negligible.
- **Licence obligation.** CC BY 4.0 permits reuse with **attribution** (cited in the report).
- **Responsible use.** Recreational/research analysis of two buoy-years; **not** a safety
  product — official marine forecasts and warnings should be used for decisions on the water.
