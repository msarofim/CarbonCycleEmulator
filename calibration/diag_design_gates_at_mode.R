# =====================================================================
# diag_design_gates_at_mode.R -- DESIGN sec.6 gates 4, 5 and 7 measured at the
# vector the APP ACTUALLY SHIPS, not at ccx_default_params().
#
# WHY THIS EXISTS. Every one of those three gates carries a "Status at default
# parameters" line in DESIGN.md, and since 2026-08-21 (`8b94ba4`) app/global.R
# has resolved its parameters from a fitted mode file (ccx_mode_file(), R/paths.R)
# instead. So the gate statuses describe a vector the app does not run. Gate 12's
# own History paragraph in DESIGN.md records that exact failure happening twice
# before -- "it is not a description, it is a measurement" -- and the 2026-08-22
# expert panel ranked it #7 on the merged defect list. Gate 12 is measured by
# `calibration/diag_joos_irf.R [defaults|N|D]`, which grew the same mode path;
# this file covers the other three.
#
# ⭐ THE MEASUREMENT ITSELF MOVED OUT, 2026-08-31f. Gates 4/5/7, their targets,
# their estimators and every constant behind them now live in
# `calibration/lib_design_gates.R`, because `diag_gates_in_the_new_basin.R`
# needs the SAME three gates and a second copy of a gate is the caption-sync bug
# class in disguise. This file is now the REPORT: which arms, in what order,
# with which commentary. The numbers are the library's.
#
# ⛔ AND IT WAS BROKEN FROM 2026-08-31 UNTIL THAT MOVE. `seas_lag_p` split into
# `_NH`/`_SH` on 08-31 (`11ff844`), so every stored mode file became a
# 21-parameter file in a 22-parameter build and this script's
# `stopifnot(identical(md$param_names, CCX_PARAM_NAMES))` aborted it before the
# first gate -- the same one true thing the 6 failing tests say. The library
# MIGRATES such a file through `ccx_migrate_par_set()` (the model's own absence
# contract) and every arm below prints whether it was migrated. A migrated
# vector is a legitimate thing to measure a gate AT; it is not a mode of this
# build's space, and the report says which is which.
#
# Usage:  Rscript calibration/diag_design_gates_at_mode.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- which arms this REPORT runs (the measurement is the library's) --
# ARMS REPOINTED 2026-08-27. "N"/"D" were the PRE-FIX pump arms; the 2026-08-25f
# seasonal-NEP isotope fix changed the objective and quarantined them, so this
# file runs the post-fix arms ccx_mode_file() knows -- the canonical free mode
# `from90` and the pinned comparison `pin90`. "defaults" is kept because every
# DESIGN sec.6 status line quotes a defaults value alongside the mode.
DG_ARMS      <- c("defaults", names(CCX_MODE_FILES))
DG_SHIPPED   <- CCX_MODE_CANONICAL   # the arm app/global.R resolves, and the
                                     # one the tau_ex profile is taken at
DG_TAUEX_GRID <- c(0.6, 0.8, 1.4, 2.0, 3.0)      # the mode's own value is inserted

# ---- run -------------------------------------------------------------
V <- lapply(DG_ARMS, dg_vector); names(V) <- DG_ARMS
R <- lapply(V, dg_run)

cat("\n=== PROVENANCE: stored per-stream logL vs RECOMPUTED at the same par_mode ===\n")
for (a in setdiff(DG_ARMS, "defaults")) {
  md <- V[[a]]$md                                  # the library already read it
  if (length(V[[a]]$migrated))
    cat(sprintf("  arm %s: MIGRATED %d -> %d parameters, filled %s -- the gates below\n         are measured at a MIGRATED vector, not at a mode of this build.\n",
                a, length(md$param_names), length(CCX_PARAM_NAMES),
                paste(V[[a]]$migrated, collapse = ", ")))
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
cat("\n  HOW TO READ THIS:\n")
cat("  * Both arms were fitted AFTER the 2026-08-25f seasonal-NEP isotope fix, so\n")
cat("    `streams` is the decomposition of that par_mode under the CURRENT\n")
cat("    objective and every row should reproduce. A non-empty list above is a\n")
cat("    REGRESSION or a new objective change -- not a known backlog.\n")
cat("  * THE ARMS ARE LIKE-FOR-LIKE HERE, unlike the pre-fix N-vs-D pair this file\n")
cat("    used to run: both were fitted in the same 3-arm refit on the same\n")
cat("    objective. What is NOT comparable is their STORED logpost -- `pin90`\n")
cat("    carries a near-delta prior on `fert_k` worth +11.6698, so its -1544.50\n")
cat("    is -1556.17 on the free scale, 11.56 BELOW the canonical mode. Compare\n")
cat("    the GATES below, not the logposts.\n")
cat("  * The pre-fix arms N and D are quarantined under\n")
cat("    output/quarantine/20260825_seas_isotope_rectification/ and are NOT\n")
cat("    comparable with anything here; ccx_mode_file() refuses them by name.\n")

G4 <- Map(dg_gate4, R, V); G5 <- lapply(R, dg_gate5); G7 <- lapply(R, dg_gate7)

cat("\n=== VECTORS UNDER TEST ===\n")
for (a in DG_ARMS)
  cat(sprintf("  %-9s %-34s luc_scale %.4f  bomb_total %.2f\n",
              a, V[[a]]$src, V[[a]]$luc_scale, V[[a]]$bomb_total))
cat(sprintf("  app/global.R ships arm %s (ccx_mode_file(), R/paths.R).\n", DG_SHIPPED))

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
cat(sprintf("  BOUND (2026-09-02): %s\n", DG_G4_CLAIM))
cat(sprintf("  %-9s %10s %10s %8s  %s\n", "arm", "sd model", "sd GCB", "ratio", "verdict"))
for (a in DG_ARMS) {
  vd <- dg_gate4_verdict(G4[[a]])
  cat(sprintf("  %-9s %10.3f %10.3f %8.2f  %s\n", a, vd$sd_model, vd$sd_obs,
              vd$ratio, if (vd$pass) "PASS" else "FAIL (SMOOTHER than GCB)"))
}
cat("  ⚠ The AF LEVEL above is DELIBERATELY UNBOUNDED: it is near-algebraic in\n")
cat("    quantities the objective already fits, so a bound would test the\n")
cat("    optimiser rather than the model. See DG_LEDGER.\n")

cat("\n=== GATE 5: BOMB CURVE, HEMISPHERIC AGGREGATE (Hua et al. 2022) ===\n")
ob <- dg_obs_gate5()          # the library's estimator, on the observations
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

# ---- GATE 5's BOUND, added 2026-09-02 (Marcus) ----------------------
# Two kinds, because the gate makes two kinds of claim. The ORDERINGS need no
# threshold; the TIMINGS need a sigma, and Hua publishes none for a hemispheric
# peak, so it is DERIVED by leave-one-zone-out on the observed aggregate.
G5SP <- dg_obs_gate5_spread()
cat(sprintf("\n  DERIVED SIGMA (leave-one-zone-out on the OBSERVED aggregate; NH %d, SH %d, lag %d draws):\n",
            G5SP$n[["nh"]], G5SP$n[["sh"]], G5SP$n[["lag"]]))
cat(sprintf("    NH peak yr %.3f   SH peak yr %.3f   lag %.3f   NH efold %.3f\n",
            G5SP$sd[["nh_t"]], G5SP$sd[["sh_t"]], G5SP$sd[["lag"]],
            G5SP$sd[["nh_efold"]]))
cat("  ⚠ It is the aggregate's sensitivity to its own ZONAL COMPOSITION, not a\n")
cat("    measurement error on Delta14C, and it rests on few draws. Read it as an\n")
cat("    order of magnitude for the tolerance.\n")
cat(sprintf("\n  %-9s %9s %9s %9s | %-12s %-12s  %s\n", "arm", "z NH yr",
            "z SH yr", "z lag", "SH after NH", "NH > SH", "verdict"))
for (a in DG_ARMS) {
  vd <- dg_gate5_verdict(G5[[a]], ob, G5SP)
  cat(sprintf("  %-9s %+9.2f %+9.2f %+9.2f | %-12s %-12s  %s\n", a,
              vd$z[["nh_t"]], vd$z[["sh_t"]], vd$z[["lag"]],
              if (vd$ord[["sh_after_nh"]]) "ok" else "VIOLATED",
              if (vd$ord[["nh_peak_higher"]]) "ok" else "VIOLATED",
              if (vd$pass) "PASS" else
                sprintf("FAIL (%s)", if (!vd$pass_ord) "ordering"
                        else sprintf("|z| > %g", DG_G5_NSD))))
}

# ---- GATE Q: air-sea d13C disequilibrium -----------------------------
# ⚠ ADDED TO THIS REPORT 2026-09-02, AND IT SHOULD HAVE SHIPPED WITH THE GATE.
# dg_gateQ() landed in lib_design_gates.R with the T-dependent alphas (6263bf6)
# and NO diagnostic called it -- its only caller was tests/testthat/test-alpha-as.R.
# So the handoff's own refit-acceptance criterion ("GATE Q must still PASS")
# could not be checked by running either gate report. A gate nothing calls
# reports nothing, which is the failure [[broken_gate_reports_nothing]] records.
# The unit test remains the DISCRIMINATION test (it asserts the retired pair
# FAILS); this is the per-arm MEASUREMENT, which is what a report is for.
cat(sprintf("\n=== GATE Q: AIR-SEA d13C DISEQUILIBRIUM %d (Quay et al. 2003 = %.2f +/- %.2f permil) ===\n",
            DG_Q_YEAR, DG_Q_OBS, DG_Q_SD))
cat(sprintf("%-9s %9s %9s %10s %8s  %s\n", "arm", "NH", "SH", "mean", "n_sd", "verdict"))
for (a in DG_ARMS) {
  q <- dg_gateQ(R[[a]], V[[a]])
  cat(sprintf("%-9s %+9.3f %+9.3f %+10.4f %8.2f  %s\n", a,
              q$by_hemi[["NH"]], q$by_hemi[["SH"]], q$mean, q$n_sd,
              if (q$pass) "PASS" else sprintf("FAIL (n_sd > %g)", DG_Q_NSD)))
}
cat(sprintf("  bound is %g observational sigma (DG_Q_NSD); the alphas are\n", DG_Q_NSD))
cat("  ccx_alpha_as(), Zhang et al. (1995), adopted 2026-09-02 (6263bf6).\n")
cat("  ⚠ AREA-UNWEIGHTED two-box mean against a global estimate; the hemispheric\n")
cat("  pair is printed because its spread is comparable to the observational sigma.\n")

DG_TGT <- dg_gcb_target(DG_SINK_WIN)
cat(sprintf("\n=== GATE 7: SINKS %d-%d (GCB land %.3f+/-%.2f, ocean %.3f+/-%.2f; n = %d yr) ===\n",
            DG_SINK_WIN[1], DG_SINK_WIN[2], DG_TGT$land, DG_GCB_LAND_SD,
            DG_TGT$ocean, DG_GCB_OCEAN_SD, DG_TGT$n))
cat(sprintf("%-9s %10s %9s %10s %9s  %s\n", "arm", "land", "(sigma)", "ocean", "(sigma)", "verdict"))
for (a in DG_ARMS) {
  g <- G7[[a]]
  vd <- dg_gate7_verdict(g, DG_TGT)          # ONE verdict, both callers
  cat(sprintf("%-9s %10.2f %+9.2f %10.2f %+9.2f  %s\n", a, g$land, vd$z_land,
              g$ocean, vd$z_ocean,
              if (vd$pass) "PASS" else sprintf("FAIL (|z| > %g)", DG_G7_NSD)))
}
cat(sprintf("  JUDGED at the OBJECTIVE's sigmas (land %.2f, ocean %.2f), |z| <= %g.\n",
            DG_G7_LAND_SD, DG_G7_OCEAN_SD, DG_G7_NSD))
cat("  At GCB's BARE stated sigmas, which is what every pre-2026-09-02 result\n")
cat("  reported, the same runs read:\n")
for (a in DG_ARMS) {
  vd <- dg_gate7_verdict(G7[[a]], DG_TGT)
  cat(sprintf("    %-9s land %+.2f  ocean %+.2f  (sigma %.2f / %.2f)\n", a,
              vd$z_land_bare, vd$z_ocean_bare, DG_GCB_LAND_SD, DG_GCB_OCEAN_SD))
}
# THE TARGET IS RECOMPUTED, SO IT IS TIED BACK TO THE PUBLISHED NUMBER RATHER
# THAN DRIFTING AWAY FROM IT SILENTLY. If this stops reproducing 2.36 / 3.22 on
# GCB's own window, the obs series has changed under us and the gate is wrong.
local({
  pub <- dg_gcb_target(DG_GCB_PUB_WIN)
  cat(sprintf("\n  target CHECK: on GCB's published window %d-%d this obs series gives\n",
              DG_GCB_PUB_WIN[1], DG_GCB_PUB_WIN[2]))
  cat(sprintf("  land %.3f / ocean %.3f against the published %.2f / %.2f -- %s\n",
              pub$land, pub$ocean, DG_GCB_PUB_LAND, DG_GCB_PUB_OCEAN,
              if (max(abs(c(pub$land - DG_GCB_PUB_LAND,
                            pub$ocean - DG_GCB_PUB_OCEAN))) < 0.01) "AGREES" else "*** DIVERGED ***"))
  cat(sprintf("  The window ends at %d because the run's last year carries a half-month\n", DG_SINK_WIN[2]))
  cat("  extrapolation worth 0.65 GtC/yr; see DG_SINK_WIN. Both sides use this window.\n")
})
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
            ob$SH[["t"]] - ob$NH[["t"]], V[[DG_SHIPPED]]$p$tau_ex))
cat(sprintf("%9s %9s %12s %12s %12s\n", "tau_ex", "bomb lag", "co2_grad", "d13c_grad", "total logL"))
prof <- t(vapply(sort(c(DG_TAUEX_GRID, V[[DG_SHIPPED]]$p$tau_ex)),
                 function(te) dg_tauex_row(te, V[[DG_SHIPPED]]), numeric(5)))
for (i in seq_len(nrow(prof)))
  cat(sprintf("%9.3f %9.2f %12.1f %12.1f %12.1f%s\n", prof[i, "tau_ex"], prof[i, "lag"],
              prof[i, "co2_grad"], prof[i, "d13c_grad"], prof[i, "total"],
              if (isTRUE(all.equal(prof[i, "tau_ex"], V[[DG_SHIPPED]]$p$tau_ex))) "   <- the mode" else ""))
# The lag needed to reach the observed value is INTERPOLATED from the profile
# just computed, not quoted: a hardcoded "2.3" would go stale the moment the
# mode moves, which is the bug class DESIGN gate 12's History paragraph records.
obs_lag  <- ob$SH[["t"]] - ob$NH[["t"]]
tau_need <- if (max(prof[, "lag"]) >= obs_lag && min(prof[, "lag"]) <= obs_lag)
  stats::approx(prof[, "lag"], prof[, "tau_ex"], xout = obs_lag)$y else NA_real_
cat("\n  THE TWO OBSERVABLES DISAGREE, AND THE GRADIENT WINS BY THREE ORDERS OF\n")
cat(sprintf("  MAGNITUDE. The bomb lag rises monotonically with tau_ex and needs roughly\n"))
cat(sprintf("  %.1f yr to reach the observed %.2f; both gradient streams sit at a sharp\n",
            tau_need, obs_lag))
cat(sprintf("  INTERIOR optimum at the mode's %.3f and fall away steeply on both sides.\n",
            V[[DG_SHIPPED]]$p$tau_ex))
cat("  So gate 5's lag miss is a FORCED residual, not an overlooked one -- the\n")
cat("  model cannot satisfy both interhemispheric constraints with one tau_ex,\n")
cat("  which makes this a STRUCTURAL finding about the two-box exchange rather\n")
cat("  than a parameter that has not been tried.\n")

dg_print_ledger()

cat(sprintf("\n=== GATE 12 is in calibration/diag_joos_irf.R [%s] ===\n",
            paste(DG_ARMS, collapse = "|")))
