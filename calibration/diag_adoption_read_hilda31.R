# =====================================================================
# diag_adoption_read_hilda31.R -- WHAT THE ADOPTED hilda31 CANONICAL IS, measured
# AT THE PROMOTED FILE through the resolvers the repo now uses (ccx_mode_base,
# dg_vector, sl_* with `struct`), against the COLUMN CONTROL ent26
# (CCX_MODE_COLUMN_CONTROL, quarantined). 2026-09-08f; Marcus: "adopt the round
# 5 winner as the canonical." Modeled on diag_adoption_read_ent26.R.
#
# What it checks: (1) the file's `struct` and that the resolver honors it (hs_frac
# 0.16 at the canonical, 0 at the control); (2) the streams PROVENANCE gate --
# dg_streams recomputed at the resolved vector equals the file's own `streams`
# (a column-resolved hilda vector fails this by ~200 on the profile rows);
# (3) the seasonal limbs like-for-like (GATE S; the SH-land knockout ratio), the
# link the whole-model scorecard could not measure; (4) the headline numbers.
# ⚠ 2026-09-12 (review A8): the limbs in (3) are read under EACH FILE'S OWN
# spinup and seas_ml (sl_score's `spinup` / `seas_ml`, from ccx_mode_spinup /
# ccx_mode_seas_ml); until then sl_run() spun up aseasonally with the mixed
# layer off, which at the periodic-fitted hilda31s is off-mode (the 2447
# log-unit mechanism) and drops the third SH ocean limb.
# Adopts nothing further. Usage: Rscript calibration/diag_adoption_read_hilda31.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_seas_limbs.R"))
AR_NEW <- CCX_MODE_CANONICAL; AR_OLD <- CCX_MODE_COLUMN_CONTROL
AR_STREAM_TOL <- 1e-6; AR_LAND_AMP_OBS <- ccx_const("SPO_SEAS_AMP_LAND_INV"); AR_LAND_KO <- SL_CASES$SH_land
AR_OUT <- ccx_path("outputs", "diagnostics", "adoption_read_hilda31_20260908.rds")
mdN <- readRDS(ccx_mode_file(AR_NEW)); mdO <- readRDS(ccx_mode_file(AR_OLD))
vN <- dg_vector(AR_NEW); vO <- dg_vector(AR_OLD)
cat(sprintf("NEW %s: %d par, struct '%s', logpost %.4f, promoted from id %d of %d (%s)\n", AR_NEW, length(mdN$param_names), ccx_mode_struct(mdN), mdN$logpost, mdN$promoted_from$id, mdN$promoted_from$n_starts, mdN$promoted_on))
cat(sprintf("OLD %s: %d par, struct '%s', logpost %.4f; MIGRATED %s\n", basename(dirname(AR_OLD)), length(mdO$param_names), ccx_mode_struct(mdO), mdO$logpost, paste(vO$migrated, collapse = ", ")))
cat("\n== 1. the resolver honours the structure ==\n")
cat(sprintf("  canonical: hs_frac %.2f  u_hs %.2f  tau_q %g  hs_asx_frac %.3f  h_hs %.1f  pump_hs %.1f  |  control: hs_frac %g  u_hs %g\n", vN$p$hs_frac, vN$p$u_hs, vN$p$tau_q, vN$p$hs_asx_frac, vN$p$h_hs, vN$p$pump_hs_gcm2, vO$p$hs_frac, vO$p$u_hs))
stopifnot(vN$p$hs_frac == 0.16, vO$p$hs_frac == 0)
cat("\n== 2. streams PROVENANCE: recomputed at the resolved vector vs the file's own ==\n")
rN <- dg_run(vN); stN <- dg_streams(rN, vN); fst <- unlist(mdN$streams); common <- intersect(names(stN), names(fst)); d <- stN[common] - fst[common]
# ⛔ THE NAME SET IS GATED FIRST, AND THIS IS THE POINT (2026-09-09w). Until then
# this check `intersect()`ed the two sets and reported max|diff| over the
# SURVIVORS, printing the leftovers with a ⚠ that no stopifnot read. A max|diff|
# over an intersection CANNOT FAIL ON A SUBSTITUTION, only on a movement -- and a
# substitution is exactly what a changed objective produces. The canonical file
# carried the retired `d14c_deep_ocean` where the objective scored three
# `d14c_profile_*` rows; this gate returned 1.4e-10 and PASSED at adoption, and
# 13 sites read the stale field for the next day. ⇒ [[intersect_is_a_silent_default]],
# calibration/diag_mode_streams_provenance.R (which mutation-tests the replacement).
ar_nameset_ok <- setequal(names(stN), names(fst))
cat(sprintf("  NAME SET: recomputed %d vs file %d -> %s\n", length(stN), length(fst),
            if (ar_nameset_ok) "PASS" else "FAIL"))
if (!ar_nameset_ok) cat(sprintf("    in RECOMPUTED only: %s\n    in FILE only      : %s\n",
                                paste(setdiff(names(stN), names(fst)), collapse = " "),
                                paste(setdiff(names(fst), names(stN)), collapse = " ")))
cat(sprintf("  max |recomputed - file| over %d rows: %.2e  -> %s (sum recomputed %.4f, file %.4f)\n", length(d), max(abs(d)), if (max(abs(d)) < AR_STREAM_TOL) "PASS" else "FAIL", sum(stN), sum(unlist(mdN$streams))))
# A stale `streams` field is a REPAIR obligation (calibration/repair_canonical_streams.R),
# not something to read past. Fail loudly on EITHER leg.
if (!ar_nameset_ok || max(abs(d)) >= AR_STREAM_TOL)
  stop("the canonical mode file's `streams` field does not match a recomputation at its own ",
       "resolved vector. Run calibration/diag_mode_streams_provenance.R to say WHICH of the two ",
       "failures this is -- a stale reporting field (repairable) or a logpost on a different ",
       "objective (a refit obligation).")
pcol <- ccx_apply_structure(ccx_default_params(), ""); pcol$pump_mode <- mdN$pump_mode; pcol <- ccx_overlay_par(pcol, mdN$par_mode)
vcol <- vN; vcol$p <- pcol; stC <- dg_streams(dg_run(vcol), vcol)
cat(sprintf("  the SAME vector resolved as a COLUMN (the failure the resolver prevents): likelihood %.2f vs %.2f (%+.1f); profile rows %+.1f\n", sum(stC), sum(stN), sum(stC) - sum(stN), sum(stC[grep("d14c_profile", names(stC))]) - sum(stN[grep("d14c_profile", names(stN))])))
cat("\n== 3. the seasonal link, like-for-like ==\n")
obs <- ccx_prepare_obs()
for (lab in c("NEW", "OLD")) { v <- if (lab == "NEW") vN else vO; md <- if (lab == "NEW") mdN else mdO
  g <- dg_gateS(v, obs); vd <- dg_gateS_verdict(g)
  cat(sprintf("  %s GATE S: SPO ocean limb %.3f ppm @ month %.2f, bracket [%.2f, %.2f] -> %s\n", lab, g$amp, g$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else "FAIL"))
  pv <- v$pm; obsv <- sl_obs_vectors(obs)
  sc <- tryCatch(sl_score(pv, pv$ent_seas_amp_SH, md$pump_mode, obs, obsv, DG_YEARS, struct = ccx_mode_struct(md),
                          seas_ml = ccx_mode_seas_ml(md), spinup = ccx_spinup_from_label(ccx_mode_spinup(md))),
                 error = function(e) { cat("  sl_score failed:", conditionMessage(e), "\n"); NULL })
  if (!is.null(sc)) { l <- sc$dec$SH_land; o <- sc$dec$SH_ocean; cat(sprintf("  %s SPO total %.3f ppm @ %.2f; SH-land limb %.4f @ %.2f = %.2fx the inverted land %.3f; SH-ocean limb %.4f @ %.2f; d13C-per-ppm ratio SPO %.2f MLO %.2f\n", lab, sc$total[["amp"]], sc$total[["mo"]], l[["amp"]], l[["mo"]], l[["amp"]] / AR_LAND_AMP_OBS, AR_LAND_AMP_OBS, o[["amp"]], o[["mo"]], sc$r_SPO, sc$r_MLO)) } }
cat("\n== 4. headline ==\n")
zN <- mdN$prior_z; big <- names(zN)[abs(zN) > 2]
cat(sprintf("  strained priors (|z| > 2): %s\n", paste(sprintf("%s %+.2f", big, zN[big]), collapse = ", ")))
cat(sprintf("  hml_bound %s (shipped [%g, %g]); kz_bracket %s\n", paste(mdN$hml_bound, collapse = "-"), CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi, paste(mdN$kz_bracket, collapse = "-")))
saveRDS(list(new = list(file = ccx_mode_file(AR_NEW), struct = ccx_mode_struct(mdN), logpost = mdN$logpost, streams = stN, lik = sum(stN), lik_as_column = sum(stC), prior_z = zN), old = list(file = ccx_mode_file(AR_OLD), logpost = mdO$logpost)), AR_OUT)
cat(sprintf("  saved %s\n  ⛔ Adopts nothing further; the repoint is in R/paths.R.\n", AR_OUT))
