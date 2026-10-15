# =====================================================================
# build_climate_module.R -- turn the FaIR SSP export into the two fitted
# objects the emulator needs to compute its OWN temperature.
#
# Source: data-raw/downloads/fair_<tag>_ssp/fair_<tag>_<ssp>.csv, written by
# FaIRtoFrEDI/run_fair_ssps_for_ccx.py (FaIR 2.2.4, 841 configs, ensemble mean,
# GMST relative to 1850-1900). Checksums in that directory's MANIFEST.csv;
# re-stamped here so the emulator can verify the file it actually read.
#
# THE CALIBRATION IS AN ARGUMENT (2026-09-24). calib 1.6.0 has been the project
# standard since 2026-08-28; this module was still on 1.4.5, built 2026-08-10,
# eighteen days before the migration. ⭐ Rebuilding it needs NO REFIT: the
# objective runs 1750-2024 on OBSERVED IGCC GMST and never calls
# ccx_climate_module() -- grep says it appears only in R/climate.R and
# app/global.R. So this moves the Futures and Pulse tabs and nothing else.
#
#     Rscript data-raw/build_climate_module.R           # calib 1.6.0
#     Rscript data-raw/build_climate_module.R 145       # the superseded one
#
# WHY A FITTED MODULE AND NOT A PRESCRIBED GMST PATH. The app's Futures tab has
# to answer "what if we emitted 100 GtC in 2050" and "what does a pulse do", on
# scenarios FaIR was never run on. A prescribed temperature path cannot respond
# to a pulse -- it would show a pulse changing CO2 while leaving the climate
# untouched, which is exactly the misconception the tab exists to dispel. So
# temperature is REBUILT from the emulator's own CO2:
#
#     erf_total(t) = erf_co2(CO2_emulator(t)) + erf_nonco2_scenario(t)
#     T(t)         = impulse_response(erf_total)
#
# The non-CO2 half -- aerosols, CH4, N2O, ozone, volcanic, solar -- stays
# PRESCRIBED at FaIR's values for the chosen background scenario, because the
# emulator models none of it. That is a real limitation and the app must say so:
# the user is changing CO2 only.
#
# TWO FITS, BOTH CHECKED AGAINST THE DATA THEY COME FROM:
#   (1) CO2 -> ERF. Least squares in u = ln(CO2/CO2_PI), quadratic, no intercept
#       so F(CO2_PI) = 0 exactly. NOT a pure log law: FaIR uses Meinshausen et
#       al. (2020), whose band correction shows up as the quadratic term. Fitting
#       degree 1 instead costs 3x the error (RMSE 0.078 vs 0.024 W/m2) and moves
#       F_2x from 3.889 to 4.003.
#
#       An earlier version INTERPOLATED through every pooled (CO2, erf_co2) pair.
#       That was wrong twice over. The pairs are ENSEMBLE MEANS, and the 841
#       configs carry different CO2 forcing scale factors, so mean(erf_co2) is
#       not f(mean(CO2)) and the cloud has real width (0.025 W/m2 at 900 ppm).
#       Worse, CO2 is not monotone in time -- SSP1-1.9 and SSP1-2.6 peak and
#       decline -- so sorting by CO2 interleaves the rising and falling limbs and
#       produced 334 descending steps, worst -0.147 W/m2, which monoH.FC cannot
#       repair because it is monotone only for monotone INPUT. The residual
#       printed at the time was 0.000, but that diagnostic was vacuous: a spline
#       through every point interpolates by construction and can never show
#       scatter. The real test is the cross-scenario spread at matched CO2.
#   (2) ERF -> T. A 3-timescale impulse response, fitted to FaIR's own GMST.
#       FaIR's temperature model IS a 3-layer energy balance, so this is fitting
#       a known functional form, not hoping one exists.
#
# Usage: Rscript data-raw/build_climate_module.R
# =====================================================================

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

CLIM_SSPS      <- c("ssp119", "ssp126", "ssp245", "ssp370", "ssp585")
# ⚠ A 1.4.5 RESULT KEEPS ITS LABEL and is never relabeled 1.6.0 (standing
# rule). Both the directory and the provenance string derive from the tag, so
# a rebuilt module cannot claim a calibration it was not built from.
CLIM_ARGS      <- commandArgs(trailingOnly = TRUE)
CLIM_CALIB     <- if (length(CLIM_ARGS)) CLIM_ARGS[1] else "160"
CLIM_VER       <- c("145" = "1.4.5", "160" = "1.6.0")[[CLIM_CALIB]]
CLIM_TAG       <- paste0("v", CLIM_CALIB)
CLIM_SRC_DIR   <- ccx_path("data-raw", "downloads", paste0("fair_", CLIM_TAG, "_ssp"))
CLIM_OUT       <- ccx_path("data", "climate_module.rds")
CLIM_SSP_OUT   <- ccx_path("data", "forcing_climate_ssp.rds")
CLIM_N_BOX     <- 3L          # impulse-response timescales
CLIM_BASE      <- c(1850, 1900)   # FaIR's GMST baseline; ours must match
CLIM_PROVENANCE <- sprintf(
  "FaIR 2.2.4 (calib%s), RCMIP SSP emissions, 841 configs, ensemble mean", CLIM_VER)

# ---------------------------------------------------------------------
# 1. read the export
# ---------------------------------------------------------------------
read_one <- function(ssp) {
  p <- file.path(CLIM_SRC_DIR, paste0("fair_", CLIM_TAG, "_", ssp, ".csv"))
  if (!file.exists(p)) stop("missing FaIR export: ", p,
                            "\nRun FaIRtoFrEDI/run_fair_ssps_for_ccx.py first.")
  d <- utils::read.csv(p)
  d$scenario <- ssp
  d
}
all <- do.call(rbind, lapply(CLIM_SSPS, read_one))
cat(sprintf("read %d scenarios, %d-%d\n", length(CLIM_SSPS),
            min(all$year), max(all$year)))

sha <- vapply(CLIM_SSPS, function(s) {
  p <- file.path(CLIM_SRC_DIR, paste0("fair_", CLIM_TAG, "_", s, ".csv"))
  if (requireNamespace("digest", quietly = TRUE))
    digest::digest(file = p, algo = "sha256") else NA_character_
}, character(1))

# ---------------------------------------------------------------------
# 2. CO2 -> ERF, monotone interpolation through the pooled pairs
# ---------------------------------------------------------------------
# Pool every (CO2, erf_co2) pair across scenarios and years. They must collapse
# onto ONE curve -- erf_co2 in FaIR is a function of concentration alone -- so
# the scatter about that curve is a direct test that the export is what we think
# it is. If scenarios disagreed at equal CO2, something else would be in there.
CO2_PI <- ccx_const("CO2_PI_PPM")
uu <- log(all$co2_ppm / CO2_PI)
X  <- cbind(uu, uu^2)                      # no intercept -> F(CO2_PI) = 0 exactly
co2_erf_beta <- qr.solve(X, all$erf_co2)
co2_erf_fun  <- function(ppm) {
  u <- log(ppm / CO2_PI); co2_erf_beta[1] * u + co2_erf_beta[2] * u^2
}
resid_pool <- all$erf_co2 - co2_erf_fun(all$co2_ppm)

CO2_ERF_RANGE <- range(all$co2_ppm)
cat(sprintf("CO2->ERF: quadratic in ln(CO2/%.1f), rmse %.4f  max|resid| %.4f W/m2\n",
            CO2_PI, sqrt(mean(resid_pool^2)), max(abs(resid_pool))))
cat(sprintf("          valid over CO2 %.1f - %.1f ppm; monotone over it: %s\n",
            CO2_ERF_RANGE[1], CO2_ERF_RANGE[2],
            all(diff(co2_erf_fun(seq(CO2_ERF_RANGE[1], CO2_ERF_RANGE[2], length.out = 2000))) > 0)))

# THE REAL CHECK that erf_co2 is a function of concentration alone: interpolate
# each scenario separately onto a common CO2 grid and compare. Residuals about a
# fitted curve cannot show this; agreement between scenarios can.
gr <- seq(320, 900, by = 20)
mat <- sapply(CLIM_SSPS, function(s) {
  k <- all$scenario == s; x <- all$co2_ppm[k]; y <- all$erf_co2[k]
  o <- order(x); x <- x[o]; y <- y[o]; d2 <- !duplicated(x)
  ifelse(gr >= min(x) & gr <= max(x), stats::approx(x[d2], y[d2], xout = gr)$y, NA)
})
spread <- apply(mat, 1, function(r) diff(range(r, na.rm = TRUE)))
cat(sprintf("          cross-scenario spread at matched CO2: max %.4f W/m2 at %d ppm\n",
            max(spread, na.rm = TRUE), gr[which.max(spread)]))

# ---------------------------------------------------------------------
# 3. ERF -> T, a 3-timescale impulse response fitted to FaIR's GMST
# ---------------------------------------------------------------------
# Discrete recursion, the standard form:
#   S_i(t) = S_i(t-1) exp(-1/d_i) + q_i F(t) (1 - exp(-1/d_i));  T = sum_i S_i
# Fitted on log(d) and log(q) so the optimizer is unconstrained and the
# timescales cannot cross zero or reorder into a degenerate solution.
irf_temp <- function(erf, q, d) {
  n <- length(erf); S <- numeric(length(q)); T <- numeric(n)
  decay <- exp(-1 / d); gain <- q * (1 - decay)
  for (i in seq_len(n)) {
    S <- S * decay + gain * erf[i]
    T[i] <- sum(S)
  }
  T
}

rebaseline <- function(t, years) t - mean(t[years >= CLIM_BASE[1] & years <= CLIM_BASE[2]])

sse <- function(par) {
  q <- exp(par[seq_len(CLIM_N_BOX)])
  d <- exp(par[CLIM_N_BOX + seq_len(CLIM_N_BOX)])
  s <- 0
  for (ssp in CLIM_SSPS) {
    k <- all$scenario == ssp
    pred <- rebaseline(irf_temp(all$erf_total[k], q, d), all$year[k])
    s <- s + sum((pred - all$gmst_C[k])^2)
  }
  s
}

# Start from a spread of timescales spanning the ocean's mixed-layer to
# deep-ocean response: ~1 yr, ~10 yr, ~250 yr.
par0 <- c(log(c(0.3, 0.4, 0.3)), log(c(1, 10, 250)))
fit <- stats::optim(par0, sse, method = "Nelder-Mead",
                    control = list(maxit = 20000, reltol = 1e-12))
fit <- stats::optim(fit$par, sse, method = "BFGS", control = list(maxit = 2000))
q_fit <- exp(fit$par[seq_len(CLIM_N_BOX)])
d_fit <- exp(fit$par[CLIM_N_BOX + seq_len(CLIM_N_BOX)])
o <- order(d_fit); q_fit <- q_fit[o]; d_fit <- d_fit[o]

cat("\nERF->T impulse response fitted to FaIR GMST:\n")
for (i in seq_len(CLIM_N_BOX))
  cat(sprintf("  box %d: q = %.4f K/(W/m2), d = %8.2f yr\n", i, q_fit[i], d_fit[i]))
f2x <- co2_erf_fun(2 * CO2_PI) - co2_erf_fun(CO2_PI)
cat(sprintf("  equilibrium sensitivity sum(q) = %.3f K/(W/m2)\n", sum(q_fit)))
cat(sprintf("  -> 2xCO2 ERF %.2f W/m2, ECS-equivalent %.2f K\n", f2x, sum(q_fit) * f2x))

cat("\nfit quality vs FaIR, per scenario (deg C):\n")
cat(sprintf("%-8s %9s %9s %9s %9s\n", "scenario", "rmse", "max|err|", "err@2100", "err@2300"))
for (ssp in CLIM_SSPS) {
  k <- all$scenario == ssp
  pred <- rebaseline(irf_temp(all$erf_total[k], q_fit, d_fit), all$year[k])
  e <- pred - all$gmst_C[k]; yy <- all$year[k]
  cat(sprintf("%-8s %9.4f %9.4f %9.4f %9.4f\n", ssp, sqrt(mean(e^2)), max(abs(e)),
              e[yy == 2100], e[yy == 2300]))
}

# ---------------------------------------------------------------------
# 4. write
# ---------------------------------------------------------------------
mod <- list(
  co2_erf_beta = co2_erf_beta,
  co2_erf_range = CO2_ERF_RANGE,
  co2_erf_rmse = sqrt(mean(resid_pool^2)),
  co2_erf_max_resid = max(abs(resid_pool)),
  co2_erf_scenario_spread = max(spread, na.rm = TRUE),
  irf_q = q_fit, irf_d = d_fit, n_box = CLIM_N_BOX,
  baseline = CLIM_BASE,
  co2_pi = CO2_PI,
  provenance = CLIM_PROVENANCE,
  source_sha256 = sha,
  built = as.character(Sys.Date())
)
saveRDS(mod, CLIM_OUT)

ssp_tab <- all[, c("scenario", "year", "gmst_C", "gmst_p05", "gmst_p95",
                   "co2_ppm", "erf_total", "erf_co2", "erf_nonco2")]
attr(ssp_tab, "provenance") <- CLIM_PROVENANCE
saveRDS(ssp_tab, CLIM_SSP_OUT)

cat(sprintf("\nwrote %s and %s\n", CLIM_OUT, CLIM_SSP_OUT))
