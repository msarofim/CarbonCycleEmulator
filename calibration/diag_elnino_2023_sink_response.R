# =====================================================================
# diag_elnino_2023_sink_response.R -- DOES THE MODEL REPRODUCE THE 2023/24
# EL NINO CARBON ANOMALY, AND DOES IT GET THE OCEAN'S SIGN RIGHT?
#
# WHY THIS EXISTS. Ke et al. (2026), "Low latency global carbon budget reveals
# land sink decline during 2023 to 2024 El Nino", iScience 29(8):117053,
# doi:10.1016/j.isci.2026.117053 (open access; vintage 2026-08-21, i.e. two
# weeks old at the time of writing) quantifies the event our historical run now
# ends inside: CO2 growth of 3.66 +/- 0.09 ppm/yr over Jul2023-Jun2024, the
# highest July-to-July rate since 1979, driven by a 2.24 GtC/yr weakening of the
# NET LAND SINK -- 97.5 % of it tropical -- and PARTLY OFFSET by 0.38 GtC/yr of
# STRONGER OCEAN UPTAKE.
#
# ⛔ WHY THE EXISTING GATES CANNOT SEE THIS. DESIGN gate 7 scores the 2015-2023
# WINDOW MEAN of each sink. A mean over nine years is blind to a divergence
# concentrated in the last one or two: the model can pass on the mean while
# moving the wrong way in the years the literature is actually talking about.
# That is [[no_power_null]] in the shape of an averaging window -- this file
# gives the same quantity YEAR BY YEAR, which is where the event lives.
#
# ⚠ WHAT IS AND IS NOT COMPARED. The model is scored against the SAME GCB series
# the objective already uses, year by year. Ke et al.'s own headline numbers are
# printed for ORIENTATION ONLY and are NOT differenced against ours: their
# window is Jul-Jul, not the calendar year, and their land decomposition is not
# the `land_sink` column this file differences. Quoting their 2.24 against our
# annual delta would be precisely the like-for-like error the project rule
# forbids ([[like_for_like_forcing]]). What the paper supplies here is the
# MECHANISM and the SIGN, both of which are testable on our own obs.
#
# ⚠ The terminal year carries the half-month extrapolation documented at
# DG_SINK_WIN in lib_design_gates.R -- worth 0.65 GtC/yr on 2024's increment
# alone. 2024 is shown, and leaned on less than 2023.
#
# ⛔ ADOPTS NOTHING.
#
# Usage:  Rscript calibration/diag_elnino_2023_sink_response.R    # ~10 s
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants ------------------------------------------------
EN_MODES <- c(incumbent = "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds",
              `new basin` = "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds")
EN_YRS   <- 2015:2024
EN_EVENT <- c(2022, 2024)          # the years the anomaly is measured across
# Ke et al. 2026, iScience 29(8):117053 -- ORIENTATION ONLY, see the header.
EN_SRC          <- "Ke et al. 2026, iScience 29(8):117053"
EN_GROWTH       <- 3.66; EN_GROWTH_SD <- 0.09   # ppm/yr, Jul2023-Jun2024, MBL
EN_LAND_WEAKEN  <- 2.24                          # GtC/yr, their decomposition
EN_OCEAN_GAIN   <- 0.38                          # GtC/yr, STRONGER uptake

cat(sprintf("\n%s\nTHE 2023/24 EL NINO SINK RESPONSE, YEAR BY YEAR\n  benchmark for the mechanism and the SIGN: %s\n%s\n",
            strrep("=", 78), EN_SRC, strrep("=", 78)))

g <- as.data.frame(ccx_prepare_obs()$gcb)
en_annual <- function(path) {
  v <- dg_vector(path); r <- dg_run(v); o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  tt <- o$t; n <- length(tt)
  stock <- function(x) {                    # = dg_gate7()'s construction, shared
    y  <- stats::approx(tt, x, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- x[1] + (bnd[lo]-tt[1]) * (x[2]-x[1]) / (tt[2]-tt[1])
    if (any(hi)) y[hi] <- x[n] + (bnd[hi]-tt[n]) * (x[n]-x[n-1]) / (tt[n]-tt[n-1])
    diff(y)
  }
  el <- ccx_forcing_eluc_annual(r$F)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH)/2, xout = bnd, rule = 2)$y
  list(yrs = yrs, land = stock(o$land_C) + el$eluc[match(yrs, el$year)],
       ocean = stock(o$ocean_C), grow = diff(atm), src = v$src)
}
M <- lapply(EN_MODES, en_annual)

for (nm in names(M)) {
  m <- M[[nm]]
  cat(sprintf("\n%s  (%s)\n", toupper(nm), m$src))
  cat(sprintf("%6s %9s %9s %8s | %9s %9s %8s | %9s\n",
              "year", "land mod", "land obs", "diff", "ocn mod", "ocn obs", "diff", "CO2 grow"))
  for (y in EN_YRS) {
    i <- match(y, m$yrs); j <- match(y, g$year)
    cat(sprintf("%6d %9.2f %9.2f %+8.2f | %9.2f %9.2f %+8.2f | %9.2f%s\n", y,
                m$land[i], g$land_sink[j], m$land[i] - g$land_sink[j],
                m$ocean[i], g$ocean_sink[j], m$ocean[i] - g$ocean_sink[j], m$grow[i],
                if (y >= EN_EVENT[1]) "  <- the event" else ""))
  }
}

cat(sprintf("\n%s\nTHE ANOMALY ACROSS %d -> %d\n%s\n",
            strrep("-", 78), EN_EVENT[1], EN_EVENT[2], strrep("-", 78)))
d  <- function(x, yrs) x[match(EN_EVENT[2], yrs)] - x[match(EN_EVENT[1], yrs)]
dg <- function(col) g[[col]][match(EN_EVENT[2], g$year)] - g[[col]][match(EN_EVENT[1], g$year)]
obs_land <- dg("land_sink"); obs_ocean <- dg("ocean_sink")
cat(sprintf("  %-12s %12s %12s %12s\n", "", "land", "ocean", "land captured"))
cat(sprintf("  %-12s %+12.2f %+12.2f %12s\n", "observed", obs_land, obs_ocean, "--"))
for (nm in names(M)) {
  m <- M[[nm]]
  cat(sprintf("  %-12s %+12.2f %+12.2f %11.0f %%\n", nm, d(m$land, m$yrs),
              d(m$ocean, m$yrs), 100 * d(m$land, m$yrs) / obs_land))
}
# THE BOUND IS A SIGN, NOT A MAGNITUDE -- which is the claim the paper actually
# licenses here, and the only one that survives the window mismatch.
cat("\n  VERDICT, stated as the SIGN because that is what is like-for-like:\n")
for (nm in names(M)) {
  mo <- d(M[[nm]]$ocean, M[[nm]]$yrs)
  cat(sprintf("    %-12s ocean response %s the observed sign (%+.2f vs %+.2f)%s\n", nm,
              if (sign(mo) == sign(obs_ocean)) "MATCHES" else "*** CONTRADICTS ***",
              mo, obs_ocean,
              if (sign(mo) != sign(obs_ocean)) "  <- the finding" else ""))
}
cat(sprintf("\n  %s reports the ocean sink STRENGTHENING by %.2f GtC/yr while the land\n  sink weakens by %.2f, with CO2 growth %.2f +/- %.2f ppm/yr (Jul-Jul).\n",
            EN_SRC, EN_OCEAN_GAIN, EN_LAND_WEAKEN, EN_GROWTH, EN_GROWTH_SD))
cat("  ⚠ ORIENTATION ONLY -- Jul-Jul window, different land decomposition. The\n")
cat("    comparison scored above is model vs the GCB series the objective uses.\n")
cat(sprintf("\n⛔ NOTHING ADOPTED.\n%s\n", strrep("=", 78)))
