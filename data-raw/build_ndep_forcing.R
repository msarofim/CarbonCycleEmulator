# =====================================================================
# build_ndep_forcing.R -- N deposition onto LAND for D2 (a), by scenario
# (Marcus 2026-09-30: "definitely add non-CO2 contributors"; ruled the same day:
# "Emissions proxy").
#
# WHAT. data/forcing_ndep.rds: one ANNUAL series per scenario, 1750 onward,
#   scenario / year / dN_emis / ndep_land / ndep_NH / ndep_SH, in Tg N/yr ABOVE
#   1750. ccx_ndep_forcing() (R/forcing.R) reads it into the forcing columns
#   ndep_NH / ndep_SH; the model multiplies NPP by (1 + gamma_ndep * ndep_h).
#
# THE PROXY (lit note notes/lit_2026-09-30_nonco2_land_sink_drivers.md sec. 1d):
#   global deposition ~= NOx-N + NH3-N emission (dep/emission 0.94-0.99), so
#     dN_emis(t)   = N/NO2 * (NOx(t) - NOx(1750)) + N/NH3 * (NH3(t) - NH3(1750))
#     ndep_land(t) = NDEP_LAND_FRAC * dN_emis(t)
#     ndep_NH      = NDEP_NH_SHARE * ndep_land,  ndep_SH = the rest
#   every constant cited in R/constants.R. The land fraction is DEGENERATE with
#   gamma_ndep, whose prior carries that uncertainty.
#
# SOURCES (both checked by sha256; a different file is an error, not a warning):
#   CMIP7 ScenarioMIP v1.1.1 (van Vuuren et al.), Zenodo 10.5281/zenodo.20713982,
#     the SAME pinned copy build_vv_scenarios.R reads (its VV_PINNED_* constants).
#     History 1750-2023, identical across the seven markers; markers from 2024.
#   RCMIP v5.1.0 emissions (Nicholls et al.), data-raw/downloads, MANIFEST key
#     "ssp_rcmip": the SSPs the model also carries. CMIP6 history to 2014; the
#     scenario waypoints after 2015 (2020, 2030, ...) are LINEARLY interpolated.
#
# THE HISTORY IS CMIP7's FOR EVERY SCENARIO. The calibration's "historical" run is
# CMIP7 1750-2023, plus 2024 = the seven-marker mean (they part only from 2024).
# ⚠ SSP SEAM (ruled 2026-09-30, "SSPs ratio-harmonised to the CMIP7 history,
# converging by 2050"): CMIP6's history sits 8.4 Tg N/yr ABOVE CMIP7's at 2014
# (C, 2026-09-30). Per species, the SSP series after 2023 is multiplied by a ratio
# that equals CMIP7(2023) / SSP(2023) at 2023 and relaxes LINEARLY to 1 at
# NDEP_HARM_YEAR; the published SSP is used unchanged from then on.
# ⚠ Values may go slightly NEGATIVE late in the strongest-mitigation markers
# (vV VL: emissions below their 1750 level by 2300). Kept: the multiplier is then
# a hair below 1, which is what the proxy says.
#
# Usage: Rscript data-raw/build_ndep_forcing.R
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
suppressMessages(library(data.table))

# ---- named constants -------------------------------------------------------
NDEP_VV_PINNED_SRC <- "~/Documents/2026/CodeProjects/FaIRtoFrEDI/data/vanvuuren/zenodo_v111_emissions_1750-2500.csv"
NDEP_VV_PINNED_SHA <- "1ada0d6089247fe79080a2744ed711502b97bbb3fd921cf9439aca88ea2a240a"   # = build_vv_scenarios.R VV_PINNED_SHA
NDEP_RCMIP_FILE    <- ccx_path("data-raw", "downloads", "rcmip-emissions-annual-means-v5-1-0.csv")
NDEP_RCMIP_SHA     <- "2af9f90c42f9baa813199a902cdd83513fff157a0f96e1d1e6c48b58ffb8b0c1"   # MANIFEST.csv "ssp_rcmip"
NDEP_VV_MARKERS    <- c(vvVL = "VL", vvLN = "LN", vvL = "L", vvML = "ML", vvM = "M", vvHL = "HL", vvH = "H")
NDEP_SSPS          <- c("ssp119", "ssp126", "ssp245", "ssp370", "ssp585")
NDEP_BASE_YEAR     <- 1750L     # "above 1750": the model's preindustrial
NDEP_HIST_LAST     <- 2023L     # last year the seven CMIP7 markers share
NDEP_HIST_RUN_END  <- 2024L     # the calibration's historical run ends here
NDEP_HARM_YEAR     <- 2050L     # the SSP ratio reaches 1 here (ruled)
NDEP_END_YEAR      <- 2300L     # standing end year (Marcus 2026-08-28); sources run to 2500
NDEP_UNITS_VV      <- c(NOx = "Mt NO2/yr", NH3 = "Mt NH3/yr")
NDEP_UNITS_RCMIP   <- c(NOx = "Mt NOx/yr", NH3 = "Mt NH3/yr")   # NO2 basis: see NDEP_N_PER_NO2's source
NDEP_OUT           <- ccx_path("data", CCX_NDEP_FILE)
N_NO2 <- ccx_const("NDEP_N_PER_NO2"); N_NH3 <- ccx_const("NDEP_N_PER_NH3")
LAND  <- ccx_const("NDEP_LAND_FRAC"); NHS  <- ccx_const("NDEP_NH_SHARE")
sha256 <- function(p) digest::digest(file = path.expand(p), algo = "sha256")
cat("\n=== build_ndep_forcing.R ===\n")

# ---- sources, checked ------------------------------------------------------
if (sha256(NDEP_VV_PINNED_SRC) != NDEP_VV_PINNED_SHA) stop("the pinned van Vuuren file's sha256 is not the recorded one")
if (sha256(NDEP_RCMIP_FILE) != NDEP_RCMIP_SHA) stop("the RCMIP file's sha256 is not MANIFEST's")
vv <- fread(path.expand(NDEP_VV_PINNED_SRC), header = TRUE)
rc <- fread(NDEP_RCMIP_FILE, header = TRUE)
years_out <- NDEP_BASE_YEAR:NDEP_END_YEAR

# van Vuuren: columns "1750.5", ... are annual means labelled at mid-year
vv_series <- function(marker, species) {
  r <- vv[scenario == marker & variable == species & region == "World"]
  if (nrow(r) != 1L) stop("vV: expected one row for ", marker, "/", species, ", got ", nrow(r))
  if (r$unit != NDEP_UNITS_VV[[species]]) stop("vV unit for ", species, " is '", r$unit, "'")
  as.numeric(unlist(r[, paste0(years_out, ".5"), with = FALSE]))
}
rc_series <- function(scen, species) {
  r <- rc[Region == "World" & Scenario == scen & Variable == paste0("Emissions|", species)]
  if (nrow(r) != 1L) stop("RCMIP: expected one row for ", scen, "/", species)
  if (r$Unit != NDEP_UNITS_RCMIP[[species]]) stop("RCMIP unit for ", species, " is '", r$Unit, "'")
  yc <- grep("^[0-9]{4}$", names(r), value = TRUE); v <- as.numeric(unlist(r[, yc, with = FALSE]))
  ok <- !is.na(v)
  stats::approx(as.integer(yc[ok]), v[ok], xout = years_out)$y   # linear between waypoints
}

# ---- the CMIP7 history, shared ---------------------------------------------
hist_of <- lapply(c(NOx = "NOx", NH3 = "NH3"), function(sp) {
  m <- sapply(NDEP_VV_MARKERS, vv_series, species = sp)
  k <- years_out <= NDEP_HIST_LAST
  spread <- max(apply(m[k, , drop = FALSE], 1, function(x) diff(range(x))))
  if (spread > 1e-9) stop("the seven markers' ", sp, " histories differ by ", spread, " before ", NDEP_HIST_LAST + 1)
  m
})
dN <- function(nox, nh3) N_NO2 * (nox - nox[1]) + N_NH3 * (nh3 - nh3[1])   # Tg N/yr above 1750
emit <- list()
# vV markers: their own series, 1750-2300
for (key in names(NDEP_VV_MARKERS))
  emit[[key]] <- dN(hist_of$NOx[, key], hist_of$NH3[, key])
# historical: CMIP7 to 2023, 2024 the marker mean, then nothing (the historical run ends in 2024)
hist_nox <- hist_of$NOx[, 1]; hist_nh3 <- hist_of$NH3[, 1]
i24 <- which(years_out == NDEP_HIST_RUN_END)
hist_nox[i24] <- mean(hist_of$NOx[i24, ]); hist_nh3[i24] <- mean(hist_of$NH3[i24, ])
keep_h <- years_out <= NDEP_HIST_RUN_END
emit[["historical"]] <- dN(hist_nox, hist_nh3)[keep_h]
# SSPs: CMIP7 history to 2023, then the RCMIP scenario ratio-harmonised to it, ratio -> 1 by 2050
harm <- function(ssp_v, hist_v) {
  i0 <- which(years_out == NDEP_HIST_LAST)
  r0 <- hist_v[i0] / ssp_v[i0]
  w  <- pmax(0, pmin(1, (NDEP_HARM_YEAR - years_out) / (NDEP_HARM_YEAR - NDEP_HIST_LAST)))
  out <- ssp_v * (1 + (r0 - 1) * w)
  out[years_out <= NDEP_HIST_LAST] <- hist_v[years_out <= NDEP_HIST_LAST]
  out
}
harm_ratio <- list()
for (s in NDEP_SSPS) {
  nox <- harm(rc_series(s, "NOx"), hist_of$NOx[, 1]); nh3 <- harm(rc_series(s, "NH3"), hist_of$NH3[, 1])
  i0 <- which(years_out == NDEP_HIST_LAST)
  harm_ratio[[s]] <- c(NOx = unname(hist_of$NOx[i0, 1]) / rc_series(s, "NOx")[i0], NH3 = unname(hist_of$NH3[i0, 1]) / rc_series(s, "NH3")[i0])
  emit[[s]] <- dN(nox, nh3)
}

# ---- to land, per hemisphere; assemble --------------------------------------
tab <- rbindlist(lapply(names(emit), function(key) {
  yy <- if (key == "historical") years_out[keep_h] else years_out
  e <- emit[[key]]
  data.table(scenario = key, year = yy, dN_emis = e, ndep_land = LAND * e,
             ndep_NH = NHS * LAND * e, ndep_SH = (1 - NHS) * LAND * e)
}))

# ---- gates ------------------------------------------------------------------
stopifnot(all(abs(tab[year == NDEP_BASE_YEAR, ndep_land]) < 1e-12))           # zero at 1750 by construction
stopifnot(all(abs(tab$ndep_NH + tab$ndep_SH - tab$ndep_land) < 1e-12))
h <- tab[scenario == "historical" & year <= NDEP_HIST_LAST]
for (key in c(names(NDEP_VV_MARKERS), NDEP_SSPS)) {                            # every scenario shares the history
  x <- tab[scenario == key & year <= NDEP_HIST_LAST]
  if (max(abs(x$ndep_land - h$ndep_land)) > 1e-9) stop(key, " does not carry the CMIP7 history")
}
for (s in NDEP_SSPS) {                                                         # the seam is continuous and releases by 2050
  x <- tab[scenario == s]
  if (abs(x[year == NDEP_HIST_LAST + 1, ndep_land] - x[year == NDEP_HIST_LAST, ndep_land]) > 5)
    stop(s, ": a jump of more than 5 Tg N/yr at the seam")
}

setattr(tab, "source", sprintf("NOx+NH3 emissions proxy x land %.2f, NH %.2f (CMIP7 vV v1.1.1 + RCMIP v5.1.0 SSPs harmonised to 2050)", LAND, NHS))
setattr(tab, "provenance", sprintf(paste("data-raw/build_ndep_forcing.R @%s, built %s; vV sha256 %s; RCMIP sha256 %s;",
                                         "Tg N/yr of deposition onto LAND above %d; constants NDEP_* in R/constants.R"),
                                   tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"),
                                   format(Sys.time(), "%Y-%m-%d %H:%M"), NDEP_VV_PINNED_SHA, NDEP_RCMIP_SHA, NDEP_BASE_YEAR))
saveRDS(tab, NDEP_OUT)

# ---- report -----------------------------------------------------------------
show <- c(1850, 1900, 1950, 1980, 2000, 2014, 2023, 2050, 2100, 2150, 2200, 2300)
w <- dcast(tab[year %in% show], scenario ~ year, value.var = "ndep_land")
cat("ndep_land, Tg N/yr onto land above 1750 (NH share", NHS, "):\n"); print(w, digits = 3)
cat("\nSSP harmonisation ratios at", NDEP_HIST_LAST, "(CMIP7 / SSP, per species):\n")
print(round(do.call(rbind, harm_ratio), 3))
cat("\nsaved", NDEP_OUT, "\n", attr(tab, "provenance"), "\n")
