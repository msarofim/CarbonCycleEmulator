# =====================================================================
# download_gcb_luc_components.R -- GCB 2025's LAND-USE CHANGE EMISSIONS sheet,
# which UN-NETS the E_LUC series the model already burns.
#
# WHY THIS EXISTS (regrowth Tier 1, Marcus 2026-09-24): "adding forest regrowth"
# to CCX is not adding a process. The prescribed LUC input is GCB's NET
# bookkeeping flux -- gross clearing MINUS gross regrowth, already netted by the
# three bookkeeping models before CCX ever sees it. GCB publishes the
# decomposition; this script acquires it so regrowth can be REPORTED without
# touching the model.
#
# WHAT THE SHEET CARRIES, and it closes exactly:
#     Net = deforestation (total)
#         + forest regrowth (total)            <- NEGATIVE, the quantity wanted
#         + other transitions
#         + peat drainage & peat fires         <- GCB-mean file only
#         + wood harvest & other forest management
# The per-model files (BLUE / OSCAR / LUCE) carry the same columns WITHOUT a peat
# column -- but their Net INCLUDES peat all the same, because GCB adds one common
# peat estimate to each model rather than each model carrying its own. So a
# per-model file closes only once the MEAN file's peat column is added back, and
# that is exactly how the gate below tests it (it closes to 1e-5; testing it
# without peat leaves a residual of up to 0.72 GtC/yr, which is the peat term).
#
# *** THE CONVENTION TRAP -- READ BEFORE QUOTING ANY "REGROWTH" NUMBER. ***
# GCB's "forest regrowth (total)" is NOT the only gross-regrowth convention, and
# the conventions differ by a FACTOR OF THREE. OSCAR v3.1's own workbook (already
# in this directory as oscar_gcb2020_eluc.xlsx) splits E_luc into E_positive /
# E_negative, and its E_negative averages -3.12 GtC/yr over 1959-2018 against
# GCB 2025's OSCAR "forest regrowth (total)" of -1.04. They are different
# quantities, not different vintages of one: GCB reports "wood harvest & other
# forest management" NET of its own post-harvest regrowth, so the regrowth inside
# the harvest-rotation cycle never appears in GCB's regrowth column, while
# OSCAR's E_negative counts every negative flux in the bookkeeping. This is the
# same class of error as [[ccx_app_luc_budget_convention]]: state which
# convention a number is on, every time.
#
# COVERAGE, and it is the limit of Tier 1 as an OBSERVATION: this sheet starts
# 1959. CCX burns land-use carbon from 1750. The split therefore exists for 66 of
# the model's 275 land-use years; anything said about 1750-1958 regrowth is an
# assumption, not this dataset.
#
# Provenance chain is the one already used for gcb_global / gcb_hist /
# gcb_fossil_by_fuel: openclimatedata's tidy CSV mirror of the GCB workbook.
#
# Run from the repo root:  Rscript data-raw/download_gcb_luc_components.R
# UPSERTS into MANIFEST.csv (download_data.R owns the original entries).
# =====================================================================
GLC_DIR   <- "data-raw/downloads"
GLC_MAN   <- file.path(GLC_DIR, "MANIFEST.csv")
GLC_BASE  <- "https://openclimatedata.github.io/global-carbon-budget/data"
GLC_STEM  <- "global-carbon-budget-2025-land-use-change-emissions"
GLC_MIN_BYTES <- 5000     # the smallest of these is ~12 kB; a redirect page is not
GLC_PEAT_COL  <- "peat drainage & peat fires"   # mean file only; added to each model
GLC_CLOSURE_TOL <- 1e-4   # the sheet is printed to ~5 dp; it closes to ~1e-5
GLC_CITE  <- paste("Friedlingstein P, et al. (2026). Global Carbon Budget 2025.",
                   "Earth Syst. Sci. Data 18:3211. Data doi:10.18160/GCP-2025,",
                   "'Land-Use Change Emissions' sheet of",
                   "Global_Carbon_Budget_2025_v1.0.xlsx (tidy CSV mirror via",
                   "openclimatedata).")
GLC_COLS  <- paste("GtC/yr 1959-2024; columns Net / deforestation (total) /",
                   "forest regrowth (total) / other transitions /",
                   "wood harvest & other forest management")

GLC_SETS <- list(
  gcb_luc_components = list(
    slug  = "gcb",
    notes = paste("GCB 2025 3-model-mean LUC decomposition --", GLC_COLS,
                  "+ peat drainage & peat fires. Its Net column is IDENTICAL to",
                  "the luc column of gcb2025_historical_budget.csv, which is what",
                  "CCX burns, so the split un-nets the model's own input.")),
  gcb_luc_components_blue = list(
    slug  = "blue",
    notes = paste("BLUE (Hansis et al. 2015) LUC decomposition --", GLC_COLS,
                  "(no peat term; GCB adds peat once to the mean).",
                  "Carried for the 3-model SPREAD on regrowth.")),
  gcb_luc_components_oscar = list(
    slug  = "oscar",
    notes = paste("OSCAR (Gasser et al. 2020) LUC decomposition as run for GCB",
                  "2025 --", GLC_COLS, "(no peat term).",
                  "NOT the same convention as oscar_gcb2020_eluc.xlsx's",
                  "E_positive/E_negative, which is ~3x larger; see header.")),
  gcb_luc_components_luce = list(
    slug  = "luce",
    notes = paste("LUCE (Qin et al. 2024) LUC decomposition --", GLC_COLS,
                  "(no peat term). Carried for the 3-model SPREAD on regrowth."))
)

dir.create(GLC_DIR, showWarnings = FALSE, recursive = TRUE)
options(timeout = 600)
rows <- list()
glc_peat <- NULL          # the mean file fills this; per-model files need it
for (key in names(GLC_SETS)) {
  s    <- GLC_SETS[[key]]
  url  <- sprintf("%s/%s-%s.csv", GLC_BASE, GLC_STEM, s$slug)
  dest <- file.path(GLC_DIR, sprintf("gcb2025_luc_components_%s.csv", s$slug))
  cat(sprintf("  ... %-24s %s\n", key, url))
  res <- try(utils::download.file(url, dest, quiet = TRUE, mode = "wb"), silent = TRUE)
  if (inherits(res, "try-error") || !file.exists(dest) || file.info(dest)$size < GLC_MIN_BYTES)
    stop(sprintf("FAILED to download %s from %s", key, url))

  # Refuse to record a file whose own components do not reproduce its Net column:
  # the whole point of the acquisition is that the split closes. The mean file is
  # fetched first and supplies the common peat term the per-model files omit.
  d <- utils::read.csv(dest, comment.char = "#", check.names = FALSE)
  if (!("Net" %in% names(d)) || !("forest regrowth (total)" %in% names(d)))
    stop(sprintf("%s: expected columns 'Net' and 'forest regrowth (total)'; got %s",
                 key, paste(names(d), collapse = " / ")))
  parts <- setdiff(names(d), c("Year", "Net"))
  sum_parts <- rowSums(d[, parts, drop = FALSE])
  if (identical(s$slug, "gcb")) {
    if (!(GLC_PEAT_COL %in% parts))
      stop("the mean file has no '", GLC_PEAT_COL, "' column to supply the per-model files")
    glc_peat <<- setNames(d[[GLC_PEAT_COL]], d$Year)
  } else {
    if (is.null(glc_peat))
      stop(key, ": the mean file must be fetched first -- it supplies the peat term")
    if (!all(as.character(d$Year) %in% names(glc_peat)))
      stop(key, ": years outside the mean file's peat coverage")
    sum_parts <- sum_parts + glc_peat[as.character(d$Year)]
  }
  resid <- max(abs(sum_parts - d$Net))
  if (!is.finite(resid) || resid > GLC_CLOSURE_TOL)
    stop(sprintf("%s: components (+ common peat) do not sum to Net (max |resid| = %.3g GtC/yr)",
                 key, resid))

  rows[[key]] <- data.frame(
    key = key, file = dest, source = url, citation = GLC_CITE, accessed = format(Sys.Date()),
    bytes = file.info(dest)$size, sha256 = tools::sha256sum(dest)[[1]], notes = s$notes,
    stringsAsFactors = FALSE)
  cat(sprintf("  [ok] %-24s %6.1f kB  %d-%d  closure %.1e  sha256 %s\n",
              key, file.info(dest)$size / 1024, min(d$Year), max(d$Year), resid,
              substr(rows[[key]]$sha256, 1, 12)))
}

man <- utils::read.csv(GLC_MAN, stringsAsFactors = FALSE)
new <- do.call(rbind, rows)
man <- rbind(man[!(man$key %in% new$key), ], new)
utils::write.csv(man, GLC_MAN, row.names = FALSE)
cat(sprintf("\nmanifest now %d entries (%s)\n", nrow(man), GLC_MAN))
