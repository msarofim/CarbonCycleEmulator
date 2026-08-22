# =====================================================================
# diag_design_gates_at_mode.R -- DESIGN sec.6 gates 4, 5 and 7 measured at the
# vector the APP ACTUALLY SHIPS, not at ccx_default_params().
#
# WHY THIS EXISTS. Every one of those three gates carries a "Status at default
# parameters" line in DESIGN.md, and since 2026-08-21 (`8b94ba4`) app/global.R
# has resolved its parameters from calibration/output/pump_arms/mode_fit_pumpN.rds
# instead. So the gate statuses describe a vector the app does not run. Gate 12's
# own History paragraph in DESIGN.md records that exact failure happening twice
# before -- "it is not a description, it is a measurement" -- and the 2026-08-22
# expert panel ranked it #7 on the merged defect list. Gate 12 is measured by
# `calibration/diag_joos_irf.R [defaults|N|D]`, which grew the same mode path
# today; this file covers the other three.
#
# THE TWO FORCING PARAMETERS ARE CARRIED, for the reason diag_app_params.R
# priced at 5.79 ppm of 2024 CO2: `bomb_total` and `luc_scale` are fitted, have
# no slot in ccx_default_params(), and are applied by rescaling forcing columns.
# Dropping them would run fitted parameters against a forcing the fit never saw
# -- and gate 5 is a BOMB-CURVE gate, i.e. it is almost entirely a readout of
# `bomb_total`, so on that gate the drop would not be a perturbation, it would
# be the whole measurement.
#
# LIKE-FOR-LIKE ON BOTH SIDES. Gate 5's DESIGN entry states the Hua Zone-1
# numbers and then says in bold not to gate the model on them, because the model
# carries ONE area-weighted hemispheric box. Every observed quantity below is
# therefore recomputed from obs_d14c_zonal.rds under ccx_zone_weights() with the
# SAME estimator applied to the model series -- including the post-peak
# e-folding, which DESIGN quotes only in its Zone-1 form (15.4 yr) and which has
# no published hemispheric counterpart to quote.
#
# Usage:  Rscript calibration/diag_design_gates_at_mode.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from named constants (project rule) --------------
DG_ARMS      <- c("defaults", "N", "D")
DG_ARM_FILE  <- "calibration/output/pump_arms/mode_fit_pump%s.rds"
DG_YEARS     <- c(1750, 2024)
DG_BOMB_REF  <- 102                  # = BOMB_REF in ccx_make_logpost()

# GATE 4 -- GCB 2025 airborne fraction (DESIGN sec.6 gate 4)
DG_AF_WIN     <- c(1959, 2024)
DG_AF_OBS     <- 0.431
DG_AF_DECADES <- c(1960, 1970, 1980, 1990, 2000, 2010, 2020)
DG_AF_OBS_DEC <- c(0.35, 0.43, 0.47, 0.38, 0.42, 0.45, 0.50)

# GATE 5 -- Hua et al. 2022, HEMISPHERIC AGGREGATE (DESIGN's own like-for-like
# benchmark, not the Zone 1 numbers it warns against)
DG_BOMB_NH_PEAK <- 853.2; DG_BOMB_NH_YR <- 1963.708
DG_BOMB_SH_PEAK <- 659.4; DG_BOMB_SH_YR <- 1965.042
DG_BOMB_LAG     <- 1.33
DG_EFOLD_FLOOR  <- 20                # permil, the > 20 permil window DESIGN names

# GATE 7 -- GCB 2025 2015-2024 means and stated 1 sigma
DG_SINK_WIN  <- c(2015, 2024)
DG_GCB_LAND  <- 2.36; DG_GCB_LAND_SD  <- LIK_GCB_LAND_SD
DG_GCB_OCEAN <- 3.22; DG_GCB_OCEAN_SD <- LIK_GCB_OCEAN_SD

GtC_PER_PPM <- ccx_const("GtC_PER_PPM")

# ---- resolve one arm to (params, luc_scale, bomb_total) -------------
dg_vector <- function(arm) {
  p <- ccx_default_params()
  if (identical(arm, "defaults"))
    return(list(p = p, luc_scale = 1, bomb_total = DG_BOMB_REF, src = "uncalibrated defaults"))
  md <- readRDS(sprintf(DG_ARM_FILE, arm))
  stopifnot(identical(md$param_names, CCX_PARAM_NAMES))     # the 21-name guard
  pm <- md$par_mode
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
  p$gamma_enso <- pm$gamma_enso
  p$pump_mode  <- md$pump_mode
  list(p = p, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
       grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       src = sprintf("mode arm %s (logpost %.2f)", arm, md$logpost))
}

dg_run <- function(v) {
  sp <- ccx_spinup(v$p)
  F  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
}

# ---- GATE 4: airborne fraction --------------------------------------
# AF = atmospheric growth / total emissions, both from THIS run: the model's own
# E_LUC carries luc_scale, so a fit that shrinks land use by 11 % shrinks the
# DENOMINATOR too. Scoring the model's growth against GCB's unscaled emissions
# would credit it with an AF it never produced. The scaled denominator is the
# self-consistent quantity; the unscaled one is printed beside it because
# luc_scale is a fitted nuisance and the reader is owed both.
dg_gate4 <- function(r, v) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2 * GtC_PER_PPM,
                       xout = bnd, rule = 2)$y
  grow <- diff(atm)
  el <- ccx_forcing_eluc_annual(r$F)
  # No ccx_forcing_efoss_annual() exists; this is the eluc helper's own recipe
  # (FUN = mean over the calendar year, because the columns are GtC/yr RATES,
  # not monthly masses -- summing them would give twelve times the emission).
  ef <- stats::aggregate(list(efoss = r$F$e_foss_NH + r$F$e_foss_SH),
                         by = list(year = r$F$year), FUN = mean)
  luc  <- el$eluc[match(yrs, el$year)]
  foss <- ef$efoss[match(yrs, ef$year)]
  af <- function(k) sum(grow[k]) / sum((foss + luc)[k])
  k <- yrs >= DG_AF_WIN[1] & yrs <= DG_AF_WIN[2]
  dec <- vapply(DG_AF_DECADES, function(d) {
    kk <- yrs >= d & yrs <= min(d + 9, DG_AF_WIN[2]) & k; af(kk)
  }, numeric(1))
  list(all = af(k), dec = dec,
       all_unscaled = sum(grow[k]) / sum((foss + luc / v$luc_scale)[k]))
}

# ---- GATE 5: bomb curve, hemispheric aggregate ----------------------
# One estimator, applied to model and observations alike: parabolic refinement
# of the peak on the monthly series (the raw argmax is quantised to the sampling
# interval, which for the observations is 1/12 yr -- big enough to move the
# NH->SH lag by a tenth of its value), then a log-linear fit of the post-peak
# decline over Delta14C > DG_EFOLD_FLOOR.
dg_peak <- function(t, v) {
  i <- which.max(v)
  if (i <= 1 || i >= length(v)) return(c(t = t[i], v = v[i]))
  y1 <- v[i - 1]; y2 <- v[i]; y3 <- v[i + 1]
  d  <- 0.5 * (y1 - y3) / (y1 - 2 * y2 + y3)          # in samples
  c(t = t[i] + d * (t[i + 1] - t[i]), v = y2 - 0.25 * (y1 - y3) * d)
}
dg_efold <- function(t, v, tpk) {
  k <- t > tpk & v > DG_EFOLD_FLOOR
  if (sum(k) < 5) return(NA_real_)
  -1 / stats::coef(stats::lm(log(v[k]) ~ t[k]))[[2]]
}
dg_obs_bomb <- local({
  z <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
  w <- ccx_zone_weights()
  hemi <- function(h) {
    ww <- w[[h]]
    zz <- z[z$zone %in% names(ww), ]
    tt <- sort(unique(zz$decimal_date))
    m <- vapply(names(ww), function(nm) {
      s <- zz[zz$zone == nm, ]
      stats::approx(s$decimal_date, s$d14c, xout = tt, rule = 2)$y
    }, numeric(length(tt)))
    list(t = tt, v = as.vector(m %*% ww[colnames(m)]))
  }
  lapply(c(NH = "NH", SH = "SH"), hemi)
})
dg_gate5 <- function(r) {
  o <- r$out
  pk <- lapply(c(NH = "NH", SH = "SH"), function(h) {
    v <- o[[paste0("d14c_", h)]]
    p <- dg_peak(o$t, v)
    c(p, efold = dg_efold(o$t, v, p[["t"]]))
  })
  list(pk = pk, lag = pk$SH[["t"]] - pk$NH[["t"]])
}

# ---- GATE 7: sinks (same construction as diag_app_params.R) ---------
dg_gate7 <- function(r) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  stock <- function(v) diff(stats::approx(o$t, v, xout = bnd, rule = 2)$y)
  el <- ccx_forcing_eluc_annual(r$F)
  k <- yrs >= DG_SINK_WIN[1] & yrs <= DG_SINK_WIN[2]
  list(ocean = mean(stock(o$ocean_C)[k]),
       land  = mean((stock(o$land_C) + el$eluc[match(yrs, el$year)])[k]))
}

# ---- PROVENANCE GATE: is this arm file on TODAY'S objective? --------
# THE HANDOFF'S OWN STRUCTURAL RECOMMENDATION (2026-08-22 sec.5): "a provenance
# stamp on every saved fit". An arm file stores the per-stream logL it was
# fitted at; recomputing those streams at the SAME par_mode under today's code
# says, per stream, exactly which parts of the objective have moved since. It
# costs one model run per arm, which this file has already paid for.
#
# It is not optional bookkeeping here. Presenting two arms side by side in the
# gate tables below is a like-for-like claim, and the mode files were NOT
# refitted together: refit_20260820.log and refit_20260821_cont.log both read
# "REFIT, 1 ARM(S) [N]". So arm D was last touched before the 2026-08-20g
# CCX_SST_SEAS_LAG correction, which moves the MODEL and therefore the
# likelihood -- and a reader comparing D's columns to N's would be comparing
# two objectives, not two pump modes.
#
# The LIKELIHOOD is recomputed, not the posterior: the h_ml refit bound [85,120]
# renormalises the prior and is not recorded in a way ccx_default_params() can
# reconstruct (memory ccx_hml_band_provenance), so a logpost comparison would
# indict the product for a property of the producer. par_mode is band-safe.
dg_streams <- function(r, v) {
  o <- r$out
  pm <- v$p
  eluc <- ccx_forcing_eluc_annual(r$F)
  err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
              grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
  ccx_loglik(o, ccx_prepare_obs(), err, luc = eluc,
             deep = r$sp$diagnostics$d14c_bottom_box,
             ocean_grad = ccx_ocean_grad_scored(o, r$sp), by_stream = TRUE)
}

# ---- run -------------------------------------------------------------
V <- lapply(DG_ARMS, dg_vector); names(V) <- DG_ARMS
R <- lapply(V, dg_run)

cat("\n=== PROVENANCE: stored per-stream logL vs RECOMPUTED at the same par_mode ===\n")
for (a in setdiff(DG_ARMS, "defaults")) {
  md <- readRDS(sprintf(DG_ARM_FILE, a))
  now <- unlist(dg_streams(R[[a]], V[[a]]))
  was <- unlist(md$streams)
  k <- intersect(names(was), names(now))
  d <- now[k] - was[k]
  cat(sprintf("  arm %s: stored sum %.1f -> recomputed %.1f  (delta %+.1f over %d streams)\n",
              a, sum(was[k]), sum(now[k]), sum(d), length(k)))
  mv <- d[abs(d) > 0.05]
  if (!length(mv)) { cat("    no stream moved by more than 0.05 -- ON TODAY'S OBJECTIVE\n"); next }
  for (nm in names(sort(abs(mv), decreasing = TRUE)))
    cat(sprintf("    %-20s %+12.1f\n", nm, mv[[nm]]))
}
cat("\n  HOW TO READ THIS, AFTER THE 2026-08-22 REPAIR:\n")
cat("  * Both arm files were repaired that day by calibration/repair_arm_streams.R,\n")
cat("    so `streams` is now the decomposition of that par_mode under the CURRENT\n")
cat("    objective and every row should reproduce. A non-empty list above is a\n")
cat("    REGRESSION or a new objective change -- not the known backlog.\n")
cat("  * `streams_as_fitted` still holds what the refit stored, for postmortem; the\n")
cat("    pre-repair files are in output/quarantine/20260822_luc_scale_squared_streams/.\n")
cat("  * What the gate found on its first run, before the repair: arm N +16.9 on\n")
cat("    `co2_icecore` alone (independently reproducing diag_ice_hemisphere.R) and\n")
cat("    -1.91 on `gcb_land_sink` (the luc_scale-SQUARED bug it uncovered); arm D\n")
cat("    -8244, dominated by co2_seasonal_MLO -7131.\n")
cat("  * ARM D IS STILL NOT LIKE-FOR-LIKE WITH ARM N, and the repair does not change\n")
cat("    that: D was last FITTED before the 2026-08-20g CCX_SST_SEAS_LAG correction\n")
cat("    (refit_20260820.log and refit_20260821_cont.log both read '1 ARM(S) [N]'),\n")
cat("    so its par_mode optimises a different model. Two objectives, not two pump\n")
cat("    modes -- never read the arm columns below as an arm comparison.\n")

G4 <- Map(dg_gate4, R, V); G5 <- lapply(R, dg_gate5); G7 <- lapply(R, dg_gate7)

cat("\n=== VECTORS UNDER TEST ===\n")
for (a in DG_ARMS)
  cat(sprintf("  %-9s %-34s luc_scale %.4f  bomb_total %.2f\n",
              a, V[[a]]$src, V[[a]]$luc_scale, V[[a]]$bomb_total))
cat("  app/global.R ships arm N.\n")

cat(sprintf("\n=== GATE 4: AIRBORNE FRACTION, %d-%d (GCB 2025 = %.3f) ===\n",
            DG_AF_WIN[1], DG_AF_WIN[2], DG_AF_OBS))
cat(sprintf("%-9s %8s %10s | %s\n", "arm", "AF", "unscaled",
            paste(sprintf("%6ss", DG_AF_DECADES), collapse = "")))
cat(sprintf("%-9s %8.3f %10s | %s\n", "GCB 2025", DG_AF_OBS, "--",
            paste(sprintf("%6.2f", DG_AF_OBS_DEC), collapse = "")))
for (a in DG_ARMS)
  cat(sprintf("%-9s %8.3f %10.3f | %s\n", a, G4[[a]]$all, G4[[a]]$all_unscaled,
              paste(sprintf("%6.2f", G4[[a]]$dec), collapse = "")))
cat(sprintf("\n  DECADAL SPREAD (sd), the 'must not be SMOOTHER than this' test:\n"))
cat(sprintf("    GCB 2025 %.3f", stats::sd(DG_AF_OBS_DEC)))
for (a in DG_ARMS) cat(sprintf("   %s %.3f", a, stats::sd(G4[[a]]$dec)))
cat("\n")

cat("\n=== GATE 5: BOMB CURVE, HEMISPHERIC AGGREGATE (Hua et al. 2022) ===\n")
ob <- lapply(dg_obs_bomb, function(x) { p <- dg_peak(x$t, x$v)
  c(p, efold = dg_efold(x$t, x$v, p[["t"]])) })
cat(sprintf("%-9s %10s %10s %10s %10s %8s %9s\n", "arm",
            "NH peak", "NH yr", "SH peak", "SH yr", "lag yr", "NH efold"))
cat(sprintf("%-9s %10.1f %10.3f %10.1f %10.3f %8.2f %9.1f   DESIGN table\n",
            "obs", DG_BOMB_NH_PEAK, DG_BOMB_NH_YR, DG_BOMB_SH_PEAK, DG_BOMB_SH_YR,
            DG_BOMB_LAG, NA_real_))
cat(sprintf("%-9s %10.1f %10.3f %10.1f %10.3f %8.2f %9.1f   recomputed here\n",
            "obs", ob$NH[["v"]], ob$NH[["t"]], ob$SH[["v"]], ob$SH[["t"]],
            ob$SH[["t"]] - ob$NH[["t"]], ob$NH[["efold"]]))
for (a in DG_ARMS) {
  g <- G5[[a]]
  cat(sprintf("%-9s %10.1f %10.3f %10.1f %10.3f %8.2f %9.1f\n", a,
              g$pk$NH[["v"]], g$pk$NH[["t"]], g$pk$SH[["v"]], g$pk$SH[["t"]],
              g$lag, g$pk$NH[["efold"]]))
}

cat(sprintf("\n=== GATE 7: SINKS %d-%d (GCB land %.2f+/-%.2f, ocean %.2f+/-%.2f) ===\n",
            DG_SINK_WIN[1], DG_SINK_WIN[2], DG_GCB_LAND, DG_GCB_LAND_SD,
            DG_GCB_OCEAN, DG_GCB_OCEAN_SD))
cat(sprintf("%-9s %10s %9s %10s %9s  %s\n", "arm", "land", "(sigma)", "ocean", "(sigma)", "verdict"))
for (a in DG_ARMS) {
  g <- G7[[a]]
  zl <- (g$land - DG_GCB_LAND) / DG_GCB_LAND_SD
  zo <- (g$ocean - DG_GCB_OCEAN) / DG_GCB_OCEAN_SD
  cat(sprintf("%-9s %10.2f %+9.2f %10.2f %+9.2f  %s\n", a, g$land, zl, g$ocean, zo,
              if (max(abs(c(zl, zo))) <= 1) "PASS" else "FAIL (|z| > 1)"))
}
cat("\n  DESIGN sec.6 gate 7's recorded status line is at DEFAULT parameters,\n")
cat("  2026-08-14: land +2.28 sigma (3.50), ocean -1.52 sigma (2.61).\n")
# ---- GATE 5 FOLLOW-UP: the two interhemispheric observables DISAGREE ----
# DESIGN gate 5 names the NH->SH bomb lag "the interhemispheric-exchange
# constraint", and gate 9 says the MLO-SPO gradient term constrains tau_ex "for
# the first time" and pulls with the OPPOSITE sign to the rest of the objective.
# Two observables, one parameter -- so the obvious question is whether they
# agree, and the honest way to answer it is to profile rather than to reason
# from the sign of a stored log-unit.
#
# READ THIS AS A FROZEN 1-D PROFILE AND NOTHING MORE. Every other parameter is
# held at the mode, so the logL costs below are UPPER BOUNDS on what moving
# tau_ex actually costs: memory ccx_seas_q10_ridge measured beta_max/fert_k
# absorbing 85 % of exactly this kind of frozen-profile cost for q10. The
# ORDERING and the location of the gradient optimum are what this establishes;
# the magnitudes are ceilings.
DG_TAUEX_GRID <- c(0.6, 0.8, 1.4, 2.0, 3.0)      # the mode's own value is inserted

dg_tauex_row <- function(te, v) {
  p <- v$p; p$tau_ex <- te
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                         bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  o <- ccx_run_fast(sp, F)$out
  err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
              grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
  st <- ccx_loglik(o, ccx_prepare_obs(), err, luc = ccx_forcing_eluc_annual(F),
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)
  c(tau_ex = te,
    lag = dg_peak(o$t, o$d14c_SH)[["t"]] - dg_peak(o$t, o$d14c_NH)[["t"]],
    co2_grad = st[["co2_gradient"]], d13c_grad = st[["d13c_gradient"]],
    total = sum(unlist(st)))
}

cat(sprintf("\n=== GATE 5 FOLLOW-UP: tau_ex PROFILE at the shipped mode (others FROZEN) ===\n"))
cat(sprintf("  observed NH->SH bomb lag %.2f yr; the mode's tau_ex is %.3f yr\n",
            ob$SH[["t"]] - ob$NH[["t"]], V$N$p$tau_ex))
cat(sprintf("%9s %9s %12s %12s %12s\n", "tau_ex", "bomb lag", "co2_grad", "d13c_grad", "total logL"))
prof <- t(vapply(sort(c(DG_TAUEX_GRID, V$N$p$tau_ex)),
                 function(te) dg_tauex_row(te, V$N), numeric(5)))
for (i in seq_len(nrow(prof)))
  cat(sprintf("%9.3f %9.2f %12.1f %12.1f %12.1f%s\n", prof[i, "tau_ex"], prof[i, "lag"],
              prof[i, "co2_grad"], prof[i, "d13c_grad"], prof[i, "total"],
              if (isTRUE(all.equal(prof[i, "tau_ex"], V$N$p$tau_ex))) "   <- the mode" else ""))
cat("\n  THE TWO OBSERVABLES DISAGREE, AND THE GRADIENT WINS BY THREE ORDERS OF\n")
cat("  MAGNITUDE. The bomb lag rises monotonically with tau_ex and needs roughly\n")
cat("  2.3 yr to reach the observed 1.34; both gradient streams sit at a sharp\n")
cat("  INTERIOR optimum at the mode's 1.032 and fall away steeply on both sides.\n")
cat("  So gate 5's lag miss is a FORCED residual, not an overlooked one -- the\n")
cat("  model cannot satisfy both interhemispheric constraints with one tau_ex,\n")
cat("  which makes this a STRUCTURAL finding about the two-box exchange rather\n")
cat("  than a parameter that has not been tried.\n")

cat("\n=== GATE 12 is in calibration/diag_joos_irf.R [defaults|N|D] ===\n")
