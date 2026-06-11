# ETC5512 Assignment 4 — When do the big waves come?

## Author and publishing date

This report was created by **Hanwen Liu (36506370)** for ETC5512 Assignment 4.
First published in June 2026.

A blog post and fully reproducible analysis of one year (2025) of half-hourly wave and
sea-temperature records from **two** wave-monitoring buoys — **Gold Coast** (QLD, primary)
and **Tweed Heads** (NSW, ~27 km south, used as a cross-check). The post asks: *how did wave
conditions and sea temperature change through 2025, when did the biggest-wave events arrive,
how does wave height relate to wave period — and does a second buoy tell the same story?*

## Data origin

Both raw datasets are the **"Wave data – 2025"** resource of a *Coastal Data System – Waves*
dataset, published by the Department of Environment, Tourism, Science and Innovation
(Queensland Government) on the Queensland Open Data Portal, and are licensed under
**Creative Commons Attribution 4.0 International (CC BY 4.0)**:

- Gold Coast: <https://www.data.qld.gov.au/dataset/coastal-data-system-waves-gold-coast>
- Tweed Heads: <https://www.data.qld.gov.au/dataset/coastal-data-system-waves-tweed-heads>
- Field definitions: <https://www.qld.gov.au/waves>

Raw files are stored verbatim under `Assignment4/data/raw/` and are never edited by hand;
all cleaning happens in code. Full provenance (resource ids, MD5 checksums, buoy
coordinates, instruments, ethics) is documented in `Assignment4/docs/metadata.md`, and every
variable is defined in `Assignment4/docs/data_dictionary.csv`. Australian state outlines for
the location map come from the `ozmaps`/`sf` R packages.

## File structure of this repository

```
ETC5512-Assignment4
├── README.md                                  -> this file
├── .gitignore
└── Assignment4
    ├── Assignment4.Rproj                      -> RStudio project (open this first)
    ├── assignment4_template_HanwenLiu.qmd     -> main submission: Data / Blog post / Behind the Scenes tabs
    ├── assignment4_template_HanwenLiu.html    -> rendered report
    ├── R
    │   ├── 01_download.R                      -> downloads both buoys (offline fallback) + integrity checks
    │   ├── 02_clean_process.R                 -> cleaning pipeline: raw -> processed, with assertions
    │   └── 00_eda.R                           -> scratch exploration (not part of the pipeline)
    ├── data
    │   ├── raw                                -> original CSVs as downloaded (untouched)
    │   └── processed
    │       ├── waves_2025_clean.csv           -> tidy half-hourly data, both sites, -99.9 -> NA
    │       └── waves_2025_monthly.csv         -> monthly summary, site x month
    └── docs
        ├── metadata.md                        -> provenance, licences, coverage, ethics (both buoys)
        └── data_dictionary.csv                -> variable definitions, units, ranges, missing code
```

## How to reproduce

Open `Assignment4/Assignment4.Rproj` in RStudio (R ≥ 4.3), then:

```r
source("R/01_download.R")        # fetch/verify both raw files
source("R/02_clean_process.R")   # raw -> processed datasets
quarto::quarto_render("assignment4_template_HanwenLiu.qmd")
```

**Packages:** `tidyverse`, `lubridate`, `scales`, `here`, `sf`, `ozmaps` (the last two only
for the buoy-location map). The `.qmd` sources the same cleaning script, so rendering
re-creates every figure and every number in the text directly from `data/raw/`.

## Iteration record (Task 3, Q9)

This repository's git history is the record of the work's iterations — four commits:
**add template and data** → **Task 1** (download + cleaning pipeline and data documentation)
→ **Task 2** (the blog post and figures) → **Task 3** (reflections and final polish).
The reflection on what changed between commits is in the *Behind the Scenes* tab of the
report.

## Usage of data

The data adapted in this repository remains under **CC BY 4.0**; reuse is free with
attribution to the Queensland Government sources above. This is a student analysis, not a
marine-safety product — use official forecasts for any decision on the water.
