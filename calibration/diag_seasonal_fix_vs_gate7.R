# =====================================================================
# diag_seasonal_fix_vs_gate7.R -- DOES THE SEASONAL FIX MOVE GATE 7?
#
# PRE-REGISTERED: notes/prereg_2026-08-29e_does_the_seasonal_fix_move_gate7.md
# (2ac40ce), BEFORE this file existed. Gates copied unchanged.
#
# ⚠ THE DIRECT PATH IS A STRUCTURALLY GUARANTEED NULL AND THAT IS NAMED FIRST.
# ccx_core.cpp:379-381 divides the seasonal respiration factor by seas_r_norm[h],
# which (lines 653-659) is the 720-point ANNUAL MEAN OF THAT SAME FACTOR. The
# Jensen rectification is removed EXACTLY, at every amplitude. So T1 is a
# MUTATION TEST of that code reading, not a measurement of a mechanism, and a
# null in T2 must not be read as "the seasonal fix was tried". [[no_power_null]]
#
# Usage:  Rscript calibration/diag_seasonal_fix_vs_gate7.R      # ~2 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

G7_YEARS    <- c(1750, 2024)
G7_SINK_WIN <- c(2015, 2023)          # diag_design_gates_at_mode.R's DG_SINK_WIN
G7_LAND_SD  <- 0.50; G7_OCEAN_SD <- 0.40
G7_T0_LAND  <- 3.56; G7_T0_OCEAN <- 2.97   # measured 2026-08-29, gates driver
G7_T0_TOL   <- 0.01
G7_T1_TOL   <- 0.001                  # the structural null, GtC/yr
G7_T2_MOVE  <- 0.25                   # half a target sigma = "MOVES"
G7_TA_SWEEP <- c(1.0391, 3.4945, 7.1012, 13.95)
G7_SLICE    <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_T_amp_SH")
G7_ARMS_RDS <- ccx_path("outputs", "diagnostics", "price_the_lag.rds")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(ccx_mode_file()); ccx_adopt_mode_band(md); pv0 <- ccx_mode_params(md)

# ---- dg_sinks(), copied from diag_design_gates_at_mode.R, not reinvented -----
run_of <- function(pv, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", G7_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  list(out = ccx_run_fast(sp, F)$out, F = F)
}
sinks <- function(r) {
  o <- as.data.frame(r$out); tt <- o$t; n <- length(tt)
  yrs <- floor(tt[1]):floor(tt[n]); bnd <- c(yrs, yrs[length(yrs)] + 1)
  stock <- function(v) {
    y  <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    if (any(hi)) y[hi] <- v[n] + (bnd[hi] - tt[n]) * (v[n] - v[n - 1]) / (tt[n] - tt[n - 1])
    diff(y)
  }
  el <- ccx_forcing_eluc_annual(r$F)
  k <- yrs >= G7_SINK_WIN[1] & yrs <= G7_SINK_WIN[2]
  list(ocean = mean(stock(o$ocean_C)[k]),
       land  = mean((stock(o$land_C) + el$eluc[match(yrs, el$year)])[k]))
}
tgt <- local({ g <- as.data.frame(ccx_prepare_obs()$gcb)
  k <- g$year >= G7_SINK_WIN[1] & g$year <= G7_SINK_WIN[2]
  list(land = mean(g$land_sink[k]), ocean = mean(g$ocean_sink[k])) })

sep("0. T0 -- CONTROL at the mode")
s0 <- sinks(run_of(pv0))
cat(sprintf("  land  %.3f  (gates driver %.2f)   ocean %.3f  (gates driver %.2f)\n",
            s0$land, G7_T0_LAND, s0$ocean, G7_T0_OCEAN))
cat(sprintf("  GCB target on %d-%d: land %.3f +/- %.2f, ocean %.3f +/- %.2f\n",
            G7_SINK_WIN[1], G7_SINK_WIN[2], tgt$land, G7_LAND_SD, tgt$ocean, G7_OCEAN_SD))
T0 <- abs(s0$land - G7_T0_LAND) < G7_T0_TOL && abs(s0$ocean - G7_T0_OCEAN) < G7_T0_TOL
cat(sprintf("  T0 -> %s\n", if (T0) "PASS" else "FAIL -- STOP"))
stopifnot(T0)

sep("1. T1 -- MUTATION TEST of the structural null: seas_T_amp_SH ALONE")
cat("  ccx_core.cpp:380 divides by seas_r_norm[h] = the annual mean of the SAME factor.\n")
cat("  PREDICTED: exactly zero movement. A non-zero here means the code reading is WRONG.\n\n")
cat(sprintf("  %14s %10s %10s %12s %12s\n", "seas_T_amp_SH", "land", "ocean", "d land", "d ocean"))
T1 <- TRUE
for (a in G7_TA_SWEEP) {
  s <- sinks(run_of(pv0, list(seas_T_amp_SH = a)))
  cat(sprintf("  %14.4f %10.4f %10.4f %12.2e %12.2e%s\n", a, s$land, s$ocean,
              s$land - s0$land, s$ocean - s0$ocean,
              if (abs(a - pv0$seas_T_amp_SH) < 1e-6) "   <- THE MODE" else ""))
  if (abs(s$land - s0$land) >= G7_T1_TOL) T1 <- FALSE
}
cat(sprintf("\n  T1 -> %s\n", if (T1)
  "PASS -- the null is STRUCTURAL, as the code says. A null in T2 is NOT evidence." else
  "⚠ FAIL -- seas_T_amp_SH DOES reach the annual budget. My code reading was WRONG; that is the finding."))

sep("2. T2 -- THE REAL QUESTION: gate 7 at the STORED seasonal-fix vectors")
if (!file.exists(G7_ARMS_RDS)) { cat("  price_the_lag.rds absent -- run diag_price_the_lag.R first\n")
} else {
  A <- readRDS(G7_ARMS_RDS)
  cat(sprintf("  %8s %10s %10s %9s %9s | %8s %10s\n",
              "lag", "land", "ocean", "land z", "ocean z", "d land", "sTaSH"))
  T2 <- TRUE; rows <- list()
  for (arm in A$shipped) {
    s <- sinks(run_of(arm$pv))
    dz <- s$land - s0$land
    cat(sprintf("  %8.4f %10.3f %10.3f %+9.2f %+9.2f | %+8.3f %10.4f%s\n", arm$lag, s$land, s$ocean,
                (s$land - tgt$land) / G7_LAND_SD, (s$ocean - tgt$ocean) / G7_OCEAN_SD, dz,
                arm$pv$seas_T_amp_SH, if (abs(arm$lag - pv0$seas_lag_p) < 1e-3) "   <- INCUMBENT" else ""))
    rows[[sprintf("%.4f", arm$lag)]] <- c(land = s$land, ocean = s$ocean, d = dz)
    if (abs(arm$lag - 2.25) < 1e-6 && abs(dz) >= G7_T2_MOVE) T2 <- FALSE
  }
  d225 <- rows[["2.2500"]][["d"]]
  cat(sprintf("\n  T2  land sink at lag 2.25 moves %+.3f GtC/yr (gate: MOVES if |d| >= %.2f) -> %s\n",
              d225, G7_T2_MOVE, if (abs(d225) >= G7_T2_MOVE) "IT MOVES" else "IT DOES NOT MOVE"))
  cat(sprintf("      gate 7 needs %+.3f to reach the GCB central value.\n", tgt$land - s0$land))
  cat(sprintf("\n  ⇒ %s\n", if (abs(d225) >= G7_T2_MOVE)
    "THE TWO DEFECTS ARE COUPLED -- attribute it (T3) before believing it." else
    "THE TWO DEFECTS ARE INDEPENDENT. Gate 7 needs its OWN arm; and note this is NOT\n        'the seasonal fix was tried and failed' -- T1 shows the path does not exist."))
  saveRDS(list(t0 = s0, target = tgt, sweep = G7_TA_SWEEP, arms = rows,
               verdicts = list(T0 = T0, T1 = T1, T2 = abs(d225) < G7_T2_MOVE)),
          ccx_path("outputs", "diagnostics", "seasonal_fix_vs_gate7.rds"))
}
cat("\n\n=== DONE ===\n")
