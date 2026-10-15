# =====================================================================
# diag_gates_in_the_new_basin.R -- RE-PRICE DESIGN sec.6 GATES 4, 5 AND 7 IN
# THE 08-31e BASIN, MATCHED AGAINST THE INCUMBENT.
#
# WHY THIS EXISTS. `handoff_2026-08-31e_the_basin.md` §8.6 closed with two open
# rulings carrying the same warning: "worth re-pricing IN THE NEW BASIN before
# ruling". Adopting the polished mode would move the canonical mode into a
# DIFFERENT basin, and every gate status, every priced trade and both open
# rulings were measured in the old one. This file measures what actually moved,
# so the adoption call is made on numbers rather than on the +52.0 alone.
#
# WHAT IT IS AND IS NOT. It ADOPTS NOTHING. `CCX_MODE_CANONICAL` is untouched;
# the polished mode is read by PATH. Adoption is Marcus's call and is a bigger
# one than it looks -- see the handoff.
#
# THE THREE VECTORS, and why each is here:
#   * incumbent   -- the 08-30 landed refit, the probe's own warm start. ⛔ NOT
#                    `CCX_MODE_CANONICAL`: the canonical file predates three of
#                    the four stacked objective changes and reproduces its own
#                    stored logpost only to -42.99, which would misprice the gap
#                    by 38. A 21-parameter ancestor, MIGRATED and labeled.
#   * new basin   -- the 08-31e polished mode, CONVERGED at -1496.01. 22
#                    parameters, recorded under the SHIPPED bands, so it carries
#                    no reparameterization constant at all.
#   * defaults    -- because every DESIGN sec.6 status line quotes a defaults
#                    value, and it is the only fixed point across both basins.
#
# LIKE-FOR-LIKE IS THE WHOLE POINT. One harness, one shipped CCX_PARAM_TABLE,
# one estimator per gate -- `calibration/lib_design_gates.R`, shared with
# `diag_design_gates_at_mode.R` so the two files cannot drift into reporting the
# same gate name at two different measurements.
#
# ⚠ GATE 12 IS NOT HERE. It has its own file and its own protocol; re-running it
# per basin is two commands, printed at the end, and duplicating the Joos
# machinery here is exactly the second copy this file's library exists to avoid.
#
# Usage:  Rscript calibration/diag_gates_in_the_new_basin.R      # ~15 s
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants: every label below derives from these ----------
NB_INCUMBENT <- "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds"
NB_NEWBASIN  <- "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds"
NB_INC_LAB   <- "incumbent"
NB_NEW_LAB   <- "new basin"
NB_DEF_LAB   <- "defaults"
NB_INC_SRC   <- "08-30 landed refit (the probe's warm start)"
NB_NEW_SRC   <- "08-31e polished mode, CONVERGED"
NB_ARM       <- "N"
NB_RT_TOL    <- 1e-8      # round-trip: an IDENTITY, so an exact bound
NB_STREAM_MIN<- 0.05      # log-units below which a stream move is not printed
NB_Z_FLAG    <- 3.0       # prior-sd distance at which a parameter is flagged,
                          # = ARM_FLAG_SIGMA in run_modefind_pump_arms.R
# The seasonal-tau_ex mechanism's best cell, in years of NH->SH bomb lag.
# ⚠ PROVENANCE, AND ITS LIMIT: measured by calibration/diag_seasonal_tau_ex.R
# and carried in memory INDEX_ccx, at a mode IN THE OLD BASIN. It is quoted here
# to re-price ruling #3's COVERAGE FRACTION, which is a ratio against gate 5's
# gap -- and the numerator has not been re-measured in this basin. So the new
# basin's coverage below is provisional in the numerator and measured in the
# denominator; re-run that diagnostic here before ruling.
NB_TAUEX_SEAS_LAG_GAIN <- 0.268

NB_ORDER <- c(NB_DEF_LAB, NB_INC_LAB, NB_NEW_LAB)
NB_PATH  <- c("defaults", NB_INCUMBENT, NB_NEWBASIN); names(NB_PATH) <- NB_ORDER

cat(sprintf("\n%s\nRE-PRICING DESIGN sec.6 GATES 4 / 5 / 7 IN THE 08-31e BASIN\n  %s: %s\n  %s: %s\n  arm %s, SHIPPED CCX_PARAM_TABLE, %d parameters. ADOPTS NOTHING.\n%s\n",
            strrep("=", 74), NB_INC_LAB, NB_INC_SRC, NB_NEW_LAB, NB_NEW_SRC,
            NB_ARM, length(CCX_PARAM_NAMES), strrep("=", 74)))

V <- lapply(NB_PATH, dg_vector)
for (a in NB_ORDER)
  cat(sprintf("  %-10s %s\n", a, V[[a]]$src))

# =====================================================================
# SELF-GATES. Each one is MUTATION-TESTED below: a gate that passes is not
# the same as a gate that works.
# =====================================================================
.ship <- lapply(CCX_PARAM_TABLE, function(s) c(s$lo, s$hi))

# GATE 1 -- FEASIBILITY under the shipped table. An EXACT bound, because it is
# a containment claim: if either point is outside, the matched comparison is not
# defined for it.
nb_gate_feasible <- function(lab, p) {
  bad <- character(0)
  for (n in CCX_PARAM_NAMES) {
    b <- .ship[[n]]
    if (is.null(b) || any(!is.finite(b))) next
    if (p[[n]] <= b[1] || p[[n]] >= b[2])
      bad <- c(bad, sprintf("%s = %.6g outside [%g, %g]", n, p[[n]], b[1], b[2]))
  }
  if (length(bad))
    stop("GATE 1 FAILED -- ", lab, " is NOT feasible under the shipped table:\n  ",
         paste(bad, collapse = "\n  "))
  invisible(TRUE)
}
# GATE 2 -- par -> unc -> par is an IDENTITY, so the bound is exact.
# ⚠ FINITENESS IS CHECKED FIRST, AND SEPARATELY. A value outside its own band
# encodes to a non-finite `u`, and the relative-error line would then compare
# NaN against the tolerance -- which raises R's "missing value where TRUE/FALSE
# needed" from inside the gate instead of the gate's own message. That reads as
# a broken script rather than a rejected input, and it is the difference
# between a gate that fires and a gate that crashes.
nb_gate_roundtrip <- function(lab, p) {
  u  <- ccx_par_to_unc(p)
  if (!all(is.finite(u)))
    stop("GATE 2 FAILED -- ", lab, " does not ENCODE: ",
         paste(CCX_PARAM_NAMES[!is.finite(u)], collapse = ", "),
         " sit outside their own support, so no round-trip is defined.")
  rt <- ccx_unc_to_par(u)
  d  <- vapply(CCX_PARAM_NAMES, function(n)
                 abs(rt[[n]] - p[[n]]) / max(abs(p[[n]]), 1e-12), numeric(1))
  if (!all(is.finite(d)) || max(d) > NB_RT_TOL)
    stop("GATE 2 FAILED -- ", lab, " does not round-trip: worst ",
         names(which.max(d)), " at ", signif(max(d), 3))
  invisible(max(d))
}
# GATE 3 -- the two files were fitted under the SAME bands AS EACH OTHER, which
# is what makes their stored logposts comparable with one another.
#
# ⚠ NARROWED 2026-09-01, and the narrowing is the point. This used to require
# each file's bands to equal the SHIPPED table -- a strictly wider claim than
# this script needs, and the 09-01 `kz` re-bisection made it false for every file
# on disk, so the gate would have blocked the very re-pricing it guards. The
# MATCHED comparison below evaluates both `par_mode`s under the ONE live table,
# so any reparameterization constant cancels between them whatever the files
# record. What the recorded bands actually affect is the meaning of each file's
# OWN stored logpost, which is reported and gated on by nothing.
# [[gate_bound_matches_its_claim]].
nb_gate_bands <- function(lab, md, ref) {
  if (!isTRUE(all.equal(md$hml_bound, ref$hml_bound)) ||
      !isTRUE(all.equal(md$kz_bracket, ref$kz_bracket)))
    stop("GATE 3 FAILED -- ", lab, " was fitted under DIFFERENT bands from the ",
         "other vector under test (hml [", paste(md$hml_bound, collapse = ", "),
         "], kz [", paste(md$kz_bracket, collapse = ", "), "]). Their stored ",
         "logposts are then on different scales and the offsets printed below ",
         "would not be like-for-like.")
  invisible(TRUE)
}

for (a in setdiff(NB_ORDER, NB_DEF_LAB)) {
  nb_gate_feasible(a, V[[a]]$pm)
  rt <- nb_gate_roundtrip(a, V[[a]]$pm)
  nb_gate_bands(a, V[[a]]$md, V[[NB_INC_LAB]]$md)
  cat(sprintf("GATE 1/2/3  %-10s feasible (all %d interior), round-trips (worst rel %.1e),\n            fitted under the same bands as the other vector. OK\n",
              a, length(CCX_PARAM_NAMES), rt))
}
# RECORDED, NOT GATED: whether those bands are the ones shipped TODAY. This is
# what makes each file's `stored` column readable, and it is loud because the
# 09-01 re-bisection made it true of every file on disk.
local({
  md <- V[[NB_INC_LAB]]$md
  if (!isTRUE(all.equal(md$kz_bracket, .ship$kz)) ||
      !isTRUE(all.equal(md$hml_bound, .ship$h_ml)))
    cat(sprintf("⚠ BOTH vectors were FITTED under kz [%s] / h_ml [%s]; the table SHIPPED\n  today is kz [%s] / h_ml [%s]. The MATCHED gap below is unaffected (one\n  table, both points, the constant cancels). Each file's own stored logpost\n  is NOT, so read the `stored` column as provenance, never as a score.\n",
                paste(md$kz_bracket, collapse = ", "), paste(md$hml_bound, collapse = ", "),
                paste(.ship$kz, collapse = ", "), paste(.ship$h_ml, collapse = ", ")))
})

# ---- MUTATION TEST: break what each gate guards, require it to fire ---
# [[mutation_test_gates]]. Three mutants, three gates, no gate exempt.
local({
  fired <- function(lab, expr) {
    ok <- inherits(tryCatch(expr, error = function(e) e), "error")
    cat(sprintf("  MUTATION %-34s %s\n", lab, if (ok) "gate FIRED. OK" else "*** GATE DID NOT FIRE"))
    if (!ok) stop("a self-gate failed its mutation test; every number below is unguarded.")
  }
  cat("\nMUTATION TESTS of the three self-gates:\n")
  fired("kz pushed past the bracket",
        { p <- V[[NB_NEW_LAB]]$pm; p$kz <- .ship$kz[2] + 1; nb_gate_feasible("mutant", p) })
  # suppressWarnings: qlogis() outside [0, 1] warns "NaNs produced" on its way to
  # the non-finite `u` the gate is testing for. The WARNING is not the gate.
  fired("h_ml outside its own support",
        suppressWarnings({ p <- V[[NB_NEW_LAB]]$pm; p$h_ml <- .ship$h_ml[2] + 1
                           nb_gate_roundtrip("mutant", p) }))
  fired("two files fitted under DIFFERENT kz brackets",
        { md <- V[[NB_NEW_LAB]]$md; md$kz_bracket <- c(3494.9, 13265.0)
          nb_gate_bands("mutant", md, V[[NB_INC_LAB]]$md) })
})

# =====================================================================
# THE MATCHED LOGPOST, and the per-stream decomposition of the gap
# =====================================================================
bp <- ccx_default_params(); bp$pump_mode <- NB_ARM
lp <- ccx_make_logpost(base_params = bp)
ev <- function(p) lp(ccx_par_to_unc(p))
LP <- vapply(setdiff(NB_ORDER, NB_DEF_LAB), function(a) ev(V[[a]]$pm), numeric(1))
if (!identical(ev(V[[NB_NEW_LAB]]$pm), LP[[NB_NEW_LAB]]))
  stop("GATE 4 FAILED -- the objective is not a pure function of u; every ",
       "difference below is then noise of unknown size.")
cat("GATE 4      determinism: the objective is bit-reproducible on repeat. OK\n")

cat(sprintf("\n%s\nMATCHED LOGPOST, both under the SHIPPED table\n", strrep("-", 74)))
for (a in setdiff(NB_ORDER, NB_DEF_LAB))
  cat(sprintf("  %-10s %14.4f   (its file stores %.4f, offset %+.4f)\n",
              a, LP[[a]], V[[a]]$md$logpost, LP[[a]] - V[[a]]$md$logpost))
cat(sprintf("  %-10s %+13.4f log-units\n", "gap", LP[[NB_NEW_LAB]] - LP[[NB_INC_LAB]]))

R <- lapply(V, dg_run)
ST <- lapply(setdiff(NB_ORDER, NB_DEF_LAB), function(a) unlist(dg_streams(R[[a]], V[[a]])))
names(ST) <- setdiff(NB_ORDER, NB_DEF_LAB)
cat(sprintf("\n%s\nWHICH STREAMS BOUGHT THE GAP (loglik only; the prior is not here)\n",
            strrep("-", 74)))
local({
  k <- intersect(names(ST[[NB_INC_LAB]]), names(ST[[NB_NEW_LAB]]))
  d <- ST[[NB_NEW_LAB]][k] - ST[[NB_INC_LAB]][k]
  cat(sprintf("  total loglik %.2f -> %.2f  (%+.2f over %d streams)\n",
              sum(ST[[NB_INC_LAB]][k]), sum(ST[[NB_NEW_LAB]][k]), sum(d), length(k)))
  cat(sprintf("  %-20s %12s %12s %10s\n", "stream", NB_INC_LAB, NB_NEW_LAB, "delta"))
  for (nm in names(sort(abs(d), decreasing = TRUE))) {
    if (abs(d[[nm]]) < NB_STREAM_MIN) next
    cat(sprintf("  %-20s %12.2f %12.2f %+10.2f\n", nm,
                ST[[NB_INC_LAB]][[nm]], ST[[NB_NEW_LAB]][[nm]], d[[nm]]))
  }
  cat(sprintf("  (streams moving less than %.2f are not printed)\n", NB_STREAM_MIN))
  cat(sprintf("  loglik gap %+.2f vs logpost gap %+.2f => the PRIOR contributes %+.2f\n",
              sum(d), LP[[NB_NEW_LAB]] - LP[[NB_INC_LAB]],
              (LP[[NB_NEW_LAB]] - LP[[NB_INC_LAB]]) - sum(d)))
  cat("  ⚠ READ THE PRIOR ROW. `hml_shallow_is_prior_credit` rejected a landed\n")
  cat("    refit whose gain was PRIOR rather than likelihood; the split is the\n")
  cat("    test, and it is printed here rather than assumed either way.\n")
})

# =====================================================================
# THE GATES
# =====================================================================
G4 <- Map(dg_gate4, R, V); G5 <- lapply(R, dg_gate5); G7 <- lapply(R, dg_gate7)

cat(sprintf("\n%s\nGATE 4: AIRBORNE FRACTION, %d-%d (GCB 2025 = %.3f)\n",
            strrep("-", 74), DG_AF_WIN[1], DG_AF_WIN[2], DG_AF_OBS))
cat(sprintf("  %-10s %8s %10s %8s | %s\n", "vector", "AF", "unscaled", "|err|",
            paste(sprintf("%6ss", DG_AF_DECADES), collapse = "")))
cat(sprintf("  %-10s %8.3f %10s %8s | %s\n", "GCB 2025", DG_AF_OBS, "--", "--",
            paste(sprintf("%6.2f", DG_AF_OBS_DEC), collapse = "")))
for (a in NB_ORDER)
  cat(sprintf("  %-10s %8.3f %10.3f %8.3f | %s\n", a, G4[[a]]$all, G4[[a]]$all_unscaled,
              abs(G4[[a]]$all - DG_AF_OBS),
              paste(sprintf("%6.2f", G4[[a]]$dec), collapse = "")))
cat(sprintf("  ⛔ %s\n", DG_G4_RETIRED))
cat("  Decadal spread (sd), REPORTED not judged:\n")
cat(sprintf("    GCB 2025 %.3f", stats::sd(DG_AF_OBS_DEC)))
for (a in NB_ORDER) cat(sprintf("   %s %.3f", a, stats::sd(G4[[a]]$dec)))
cat("\n")

cat(sprintf("\n%s\nGATE V: INTERANNUAL CO2 GROWTH VARIABILITY, %d-%d\n",
            strrep("-", 74), DG_V_WIN[1], DG_V_WIN[2]))
NB_OV <- dg_gateV_obs()
cat(sprintf("  GCB 2025  sd %.3f GtC/yr, se %.3f (n = %d)\n", NB_OV$sd, NB_OV$se, NB_OV$n))
cat(sprintf("  %-10s %10s %8s %8s  %s\n", "vector", "sd GtC/yr", "ratio", "z", "verdict"))
for (a in NB_ORDER) {
  vd <- dg_gateV_verdict(dg_gateV(R[[a]]), NB_OV)
  cat(sprintf("  %-10s %10.3f %8.2f %8.2f  %s\n", a, vd$sd_model, vd$ratio, vd$z,
              if (vd$pass) "PASS" else "FAIL (too SMOOTH)"))
}

cat(sprintf("\n%s\nGATE 5: BOMB CURVE, HEMISPHERIC AGGREGATE (Hua et al. 2022)\n", strrep("-", 74)))
ob <- dg_obs_gate5()
OBS_LAG <- ob$SH[["t"]] - ob$NH[["t"]]
cat(sprintf("  %-10s %10s %10s %10s %10s %8s %9s\n", "vector",
            "NH peak", "NH yr", "SH peak", "SH yr", "lag yr", "NH efold"))
cat(sprintf("  %-10s %10.1f %10.3f %10.1f %10.3f %8.2f %9.1f   DESIGN table\n",
            "obs", DG_BOMB_NH_PEAK, DG_BOMB_NH_YR, DG_BOMB_SH_PEAK, DG_BOMB_SH_YR,
            DG_BOMB_LAG, NA_real_))
cat(sprintf("  %-10s %10.1f %10.3f %10.1f %10.3f %8.2f %9.1f   recomputed here\n",
            "obs", ob$NH[["v"]], ob$NH[["t"]], ob$SH[["v"]], ob$SH[["t"]],
            OBS_LAG, ob$NH[["efold"]]))
for (a in NB_ORDER) {
  g <- G5[[a]]
  cat(sprintf("  %-10s %10.1f %10.3f %10.1f %10.3f %8.2f %9.1f   lag miss %+.2f\n", a,
              g$pk$NH[["v"]], g$pk$NH[["t"]], g$pk$SH[["v"]], g$pk$SH[["t"]],
              g$lag, g$pk$NH[["efold"]], g$lag - OBS_LAG))
}
cat(sprintf("  tau_ex: %s\n", paste(vapply(setdiff(NB_ORDER, NB_DEF_LAB), function(a)
  sprintf("%s %.3f yr", a, V[[a]]$pm$tau_ex), character(1)), collapse = "   ")))
cat("  ⚠ gate 5's lag is a MONOTONE readout of tau_ex (diag_design_gates_at_mode.R's\n")
cat("    frozen profile), so a basin that moves tau_ex moves this gate mechanically.\n")

DG_TGT <- dg_gcb_target(DG_SINK_WIN)
cat(sprintf("\n%s\nGATE 7: SINKS %d-%d (GCB land %.3f+/-%.2f, ocean %.3f+/-%.2f; n = %d yr)\n",
            strrep("-", 74), DG_SINK_WIN[1], DG_SINK_WIN[2], DG_TGT$land, DG_GCB_LAND_SD,
            DG_TGT$ocean, DG_GCB_OCEAN_SD, DG_TGT$n))
cat(sprintf("  %-10s %10s %9s %10s %9s  %s\n", "vector", "land", "(sigma)", "ocean", "(sigma)", "verdict"))
NB_Z <- list()
for (a in NB_ORDER) {
  g <- G7[[a]]
  # ⭐ ONE VERDICT, BOTH CALLERS (2026-09-02). This block used to recompute the
  # z-scores and the pass rule inline, in parallel with the other caller.
  vd <- dg_gate7_verdict(g, DG_TGT)
  NB_Z[[a]] <- c(land = vd$z_land, ocean = vd$z_ocean)
  cat(sprintf("  %-10s %10.2f %+9.2f %10.2f %+9.2f  %s\n", a, g$land, vd$z_land,
              g$ocean, vd$z_ocean,
              if (vd$pass) "PASS" else sprintf("FAIL (|z| > %g)", DG_G7_NSD)))
}
cat(sprintf("  JUDGED at the OBJECTIVE's sigmas (land %.2f, ocean %.2f), |z| <= %g;\n",
            DG_G7_LAND_SD, DG_G7_OCEAN_SD, DG_G7_NSD))
cat(sprintf("  GCB's BARE stated sigmas (%.2f / %.2f) are what the header prints and\n",
            DG_GCB_LAND_SD, DG_GCB_OCEAN_SD))
cat("  what every pre-2026-09-02 result reported. ⚠ NB_Z BELOW IS NOW ON THE\n")
cat("  OBJECTIVE'S SIGMAS, so its numbers are not comparable with a stored one.\n")
# TIED BACK TO THE PUBLISHED NUMBER rather than drifting away from it silently.
local({
  pub <- dg_gcb_target(DG_GCB_PUB_WIN)
  cat(sprintf("  target CHECK on GCB's published window %d-%d: land %.3f / ocean %.3f\n",
              DG_GCB_PUB_WIN[1], DG_GCB_PUB_WIN[2], pub$land, pub$ocean))
  cat(sprintf("  against the published %.2f / %.2f -- %s\n",
              DG_GCB_PUB_LAND, DG_GCB_PUB_OCEAN,
              if (max(abs(c(pub$land - DG_GCB_PUB_LAND,
                            pub$ocean - DG_GCB_PUB_OCEAN))) < 0.01) "AGREES" else "*** DIVERGED ***"))
})

# =====================================================================
# WHAT THIS MEANS FOR THE TWO OPEN TRADES -- reported, never ruled
# =====================================================================
cat(sprintf("\n%s\nTHE OPEN RULINGS, RE-PRICED (handoff 08-31e §5, §8.6). NOTHING IS RULED HERE.\n",
            strrep("=", 74)))
cat(sprintf("\n  RULING #2 -- buy gate 7 by putting the deep ocean young?\n"))
cat(sprintf("    gate 7 land   %+.2f sigma -> %+.2f sigma   (the axis the trade pays on)\n",
            NB_Z[[NB_INC_LAB]][["land"]], NB_Z[[NB_NEW_LAB]][["land"]]))
cat(sprintf("    gate 7 ocean  %+.2f sigma -> %+.2f sigma\n",
            NB_Z[[NB_INC_LAB]][["ocean"]], NB_Z[[NB_NEW_LAB]][["ocean"]]))
local({
  k <- c("deep_d14c", "excess_c14_ocean", "d14c_NH", "d14c_SH", "d14c_intcal")
  k <- intersect(k, names(ST[[NB_INC_LAB]]))
  for (nm in k)
    cat(sprintf("    stream %-18s %10.2f -> %10.2f  (%+.2f)\n", nm,
                ST[[NB_INC_LAB]][[nm]], ST[[NB_NEW_LAB]][[nm]],
                ST[[NB_NEW_LAB]][[nm]] - ST[[NB_INC_LAB]][[nm]]))
})
cat(sprintf("\n  RULING #3 -- seasonal tau_ex adoption\n"))
cat(sprintf("    tau_ex        %.4f -> %.4f yr\n",
            V[[NB_INC_LAB]]$pm$tau_ex, V[[NB_NEW_LAB]]$pm$tau_ex))
cat(sprintf("    bomb lag      %.2f -> %.2f yr against the observed %.2f\n",
            G5[[NB_INC_LAB]]$lag, G5[[NB_NEW_LAB]]$lag, OBS_LAG))
local({
  cov <- function(a) 100 * NB_TAUEX_SEAS_LAG_GAIN / abs(G5[[a]]$lag - OBS_LAG)
  cat(sprintf("    the mechanism's best cell is worth %+.3f yr of lag, so it covers\n",
              NB_TAUEX_SEAS_LAG_GAIN))
  cat(sprintf("      %.0f %% of the gap in the %s and %.0f %% in the %s\n",
              cov(NB_INC_LAB), NB_INC_LAB, cov(NB_NEW_LAB), NB_NEW_LAB))
  cat("    ⚠ NUMERATOR NOT RE-MEASURED HERE (see NB_TAUEX_SEAS_LAG_GAIN). The gap\n")
  cat("      GREW, so the mechanism is being asked to cover more than when it was\n")
  cat("      priced; re-run diag_seasonal_tau_ex.R in this basin before ruling.\n")
})

cat(sprintf("\n%s\nPRIOR-TAIL POSITION, |z| > %.1f flagged (ccx_prior_z, the refit's own screen)\n",
            strrep("-", 74), NB_Z_FLAG))
local({
  z <- lapply(setdiff(NB_ORDER, NB_DEF_LAB), function(a)
    vapply(CCX_PARAM_NAMES, function(n)
      tryCatch(ccx_prior_z(n, V[[a]]$pm[[n]]), error = function(e) NA_real_), numeric(1)))
  names(z) <- setdiff(NB_ORDER, NB_DEF_LAB)
  d <- z[[NB_NEW_LAB]] - z[[NB_INC_LAB]]
  cat(sprintf("  %-18s %10s %10s %10s\n", "parameter", NB_INC_LAB, NB_NEW_LAB, "move"))
  for (n in names(sort(abs(d), decreasing = TRUE))[1:8])
    cat(sprintf("  %-18s %+10.2f %+10.2f %+10.2f\n", n, z[[NB_INC_LAB]][[n]],
                z[[NB_NEW_LAB]][[n]], d[[n]]))
  for (a in setdiff(NB_ORDER, NB_DEF_LAB)) {
    fl <- CCX_PARAM_NAMES[which(abs(z[[a]]) > NB_Z_FLAG)]
    cat(sprintf("  FLAGGED in %-10s %s\n", a,
                if (length(fl)) paste(fl, collapse = ", ") else "none"))
  }
})

cat(sprintf("\n%s\nGATE 12 IS A SEPARATE FILE AND A SEPARATE PROTOCOL. Re-price it with:\n", strrep("=", 74)))
cat(sprintf("  Rscript calibration/diag_joos_irf.R %s\n", NB_INCUMBENT))
cat(sprintf("  Rscript calibration/diag_joos_irf.R %s\n", NB_NEWBASIN))
cat("⛔ NOTHING HERE IS ADOPTED. CCX_MODE_CANONICAL is unchanged.\n")
cat(sprintf("%s\n", strrep("=", 74)))
