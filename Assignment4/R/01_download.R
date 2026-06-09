# ---------------------------------------------------------------------------
# 01_download.R
# Acquire & verify the raw data for Assignment 4 (ETC5512).
#
# TWO wave-monitoring buoys from the Queensland Government Open Data Portal,
# both published under Creative Commons Attribution 4.0 (CC BY 4.0):
#   * Coastal Data System - Waves (Gold Coast)   -> "Wave data - 2025"
#   * Coastal Data System - Waves (Tweed Heads)  -> "Wave data - 2025"
# Custodian: Dept of Environment, Tourism, Science and Innovation (DETSI).
#
# The script downloads each file from its source URL, and FALLS BACK to the
# copy committed in data/raw/ if the portal is unreachable, so the pipeline
# reproduces either online or fully offline. It then verifies structure.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(here)
  library(readr)
})

raw_dir <- here("data", "raw")
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

# --- Provenance: dataset pages (human) + direct CSV URLs (machine) ----------
sources <- list(
  gold_coast = list(
    page = "https://www.data.qld.gov.au/dataset/coastal-data-system-waves-gold-coast",
    url  = paste0("https://www.data.qld.gov.au/dataset/d656d418-31b1-41fe-aae2-3d8a12588711/",
                  "resource/a8a12129-c99d-45f6-832b-a5cee4754b54/download/",
                  "gold-coast-mk4_2025-01-01t00_00-2025-12-31t23_30_waveverifieddata.csv"),
    dest = file.path(raw_dir, "gold-coast-mk4-2025-waveverifieddata.csv")
  ),
  tweed_heads = list(
    page = "https://www.data.qld.gov.au/dataset/coastal-data-system-waves-tweed-heads",
    url  = paste0("https://www.data.qld.gov.au/dataset/efc9b5dc-602e-49fc-ba66-45dfbaad9613/",
                  "resource/bc667055-aa5c-4449-ba26-3953e99ccf67/download/",
                  "tweed-heads-mk4_2025-01-01t00_00-2026-01-01t23_30_waveverifieddata.csv"),
    dest = file.path(raw_dir, "tweed-heads-mk4-2025-waveverifieddata.csv")
  )
)

# If a URL ever dies: open the dataset `page`, open the "Wave data - 2025"
# resource, click "Download", and save the CSV to data/raw/ under `dest`.

expected_cols <- c("Date/Time (AEST)", "Hs (m)", "Hmax (m)", "Tz (s)",
                   "Tp (s)", "Peak Direction (degrees)", "SST (degrees C)")

fetch_one <- function(s) {
  ok <- tryCatch({
    download.file(s$url, destfile = s$dest, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok && !file.exists(s$dest))
    stop("Download failed and no committed copy at ", s$dest)
  hdr  <- strsplit(readLines(s$dest, n = 1), ",")[[1]]
  nrow <- length(readLines(s$dest)) - 1L
  data.frame(
    file        = basename(s$dest),
    source      = if (ok) "downloaded" else "committed copy (offline)",
    rows        = nrow,
    cols_ok     = identical(hdr, expected_cols),
    md5         = unname(tools::md5sum(s$dest))
  )
}

report <- do.call(rbind, lapply(sources, fetch_one))
rownames(report) <- NULL
print(report)
stopifnot(all(report$cols_ok), all(report$rows > 17000))
cat("\nBoth raw files present and structurally valid.\n")
