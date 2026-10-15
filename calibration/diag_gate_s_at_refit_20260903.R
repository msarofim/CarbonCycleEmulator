# ===================================================================
# GATE S AT THE 2026-09-03 REFIT WINNER -- the SPO OCEAN limb's PHASE.
#
# WHY. The seasonal arc has carried "the SH ocean limb is 0.45x observed and
# ~5 months out of phase" for weeks, and NOTHING SCORED IT: the likelihood's
# co2_seasonal_SPO row scores the TOTAL, which the model already matches to
# ~1 % by canceling a 2.55x land limb against the deficient ocean one. GATE S
# (2026-09-03) is the missing bound. This is its FIRST measurement, and it is
# the PRE-REGISTRATION BASELINE for Fix A (freeing `ent_seas_amp_SH`).
#
# ⚠ NOTHING HERE CHANGES AN OBJECTIVE. No constant, prior, R/ or src/ is
# touched. It is a MEASUREMENT at an already-fitted vector, and that vector is
# NOT ADOPTED -- `CCX_MODE_CANONICAL` is still `from90`.
#
# Usage:  Rscript calibration/diag_gate_s_at_refit_20260903.R
# ===================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

GS_DIR <- "calibration/output/multistart_20260902_demean25"
GS_ENT <- 0        # the SHIPPED default: the channel is OFF and UNFITTED. This
                   # is the INCUMBENT arm, and naming it here is the point --
                   # the gate is measured at the model that ships today.

S  <- readRDS(file.path(GS_DIR, "survey_summary.rds"))
iA <- which(S$group == "A")[which.max(S$logpost[S$group == "A"])]
res <- readRDS(S$files[iA])
pm  <- res$par_mode
# ccx_overlay_par(), NOT the bare `intersect()` loop: on a 25-parameter
# ancestor that loop assigns NULL to `ent_seas_amp_SH` and DELETES it, and the
# run falls through to the absence contract with nothing said. Here that
# fallback happens to be right (0 = the channel the ancestor ran), which is
# precisely why it has to be made EXPLICIT rather than relied on.
pm_mig <- ccx_migrate_par_set(pm)
GS_MIG <- attr(pm_mig, "migrated")
p   <- ccx_overlay_par(ccx_default_params(), pm_mig)
p$pump_mode <- res$pump_mode
p$ent_seas_amp_SH <- GS_ENT
v <- list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
          src = sprintf("refit id %d (logpost %.4f)", res$id, res$logpost))

cat(sprintf("\n=== GATE S AT %s ===\n", v$src))
# ⚠ MIGRATE, THEN SAY SO -- dg_vector()'s rule, applied here. This vector was
# fitted on 25 names and this build fits 26.
if (length(GS_MIG))
  cat(sprintf("  MIGRATED %d -> %d, filled: %s\n",
              length(res$param_names), length(CCX_PARAM_NAMES),
              paste(GS_MIG, collapse = ", ")))
# ⭐ AND THE INVARIANT THAT MAKES THE MIGRATION HONEST, ASSERTED NOT ASSUMED:
# `ent_seas_amp_SH` entering the fitted set must not move a measurement AT an
# already-fitted vector, because the migration fills the state that vector RAN.
# Verified 2026-09-03: this driver's numbers are bit-identical across the
# 25 -> 26 change. If this stops holding, the migration invented a coordinate.
stopifnot(identical(p$ent_seas_amp_SH, GS_ENT))
cat(sprintf("  ent_seas_amp_SH = %g (shipped default -- channel OFF, NOT fitted)\n", GS_ENT))
cat(sprintf("  sst_seas_amp_SH = %.4f, prior-z %+.2f (the model's WORST prior violation)\n",
            p$sst_seas_amp_SH, ccx_prior_z("sst_seas_amp_SH", p$sst_seas_amp_SH)))
cat(sprintf("  sst_seas_amp_NH = %.4f, prior-z %+.2f\n",
            p$sst_seas_amp_NH, ccx_prior_z("sst_seas_amp_NH", p$sst_seas_amp_NH)))
cat(sprintf("  npp_frac_NH     = %.4f, prior-z %+.2f\n",
            p$npp_frac_NH, ccx_prior_z("npp_frac_NH", p$npp_frac_NH)))

obs <- ccx_prepare_obs()
g   <- dg_gateS(v, obs)
vd  <- dg_gateS_verdict(g)

cat(sprintf("\n  SPO TOTAL      : amp %.4f ppm @ month %.2f   (obs %.3f @ ~-- )\n",
            g$amp_total, g$mo_total, ccx_const("SPO_SEAS_AMP_OBS")))
cat(sprintf("  SH OCEAN limb  : amp %.4f ppm @ month %.2f\n", g$amp, g$mo))
cat(sprintf("  observed       : amp %.4f ppm @ month %.2f  [%.2f, %.2f]\n",
            DG_S_AMP_OBS, DG_S_OBS, DG_S_OBS_LO, DG_S_OBS_HI))
cat(sprintf("\n  VERDICT: phase miss %+.2f months, sigma %.4f, z %+.2f  ->  %s\n",
            vd$d_mo, vd$sd, vd$z, if (vd$pass) "PASS" else "FAIL"))
cat(sprintf("  bound: months [%.3f, %.3f] at |z| <= %g\n", vd$lo, vd$hi, vd$n_sd))
cat(sprintf("  amplitude (REPORTED, NOT BOUNDED): %.3fx observed\n", vd$amp_ratio))

# ⛔ THE RECORDED NUMBERS ARE STALE FOR THIS VECTOR, AND THE CORRECTION IS
# PRINTED RATHER THAN QUIETLY ABSORBED. The arc (and the 09-03 handoff) carries
# the SH ocean limb at "3.35 months, 0.45x observed, a 5.17 month miss". Measured
# HERE at the refit winner with the SHARED estimator it is 4.19 months and 0.632x
# -- a 4.33 month miss. Those recorded values belong to EARLIER vectors (the
# h_ml arc walked this limb 4.15 -> 3.90 across h_ml 96.47 -> 35.38 m), not to
# the vector the handoff attributed them to. The DIRECTION and the verdict are
# unchanged -- the limb is still very nearly antiphase, at z -12.3 -- but any
# ratio quoted against 3.35 or 0.45x is quoting a model that no longer exists.
# ⚠ VERIFIED, not asserted: the GATE S kernel reproduces lib_seas_limbs.R's
# sl_score() at this vector to 4e-16 (amp) and 4e-14 (phase).
GS_REC_MO  <- 3.35   # the RECORDED phase, kept so the drift is visible
GS_REC_AMP <- 0.45   # the RECORDED amplitude ratio, same
cat(sprintf("\n  ⛔ RECORDED vs MEASURED at this vector: phase %.2f -> %.2f mo,",
            GS_REC_MO, g$mo))
cat(sprintf(" amp %.2fx -> %.3fx\n", GS_REC_AMP, vd$amp_ratio))
cat("     The recorded pair belongs to an EARLIER vector. Quote the measured one.\n")

cat("\n  --- PRE-REGISTERED BASELINE FOR FIX A ---\n")
cat("  P1 predicts this limb's phase moves TOWARD 8.52 and its amplitude toward 1x.\n")
cat("  ⛔ P1 is NOT the acceptance test. P2 is: does `sst_seas_amp_SH`'s prior-z\n")
cat("     RELAX from the value printed above? A mechanism that improves a fit is\n")
cat("     not thereby right -- judge it on the STRAINED PRIOR it releases.\n")
cat(sprintf("  ⚠ THE ENTRAINMENT DRIVER PEAKS AT %.2f, itself z %+.2f on this gate.\n",
            CCX_ENT_SEAS_PEAK_MO,
            dg_mo_diff(CCX_ENT_SEAS_PEAK_MO, DG_S_OBS) / DG_S_SD))
cat("  ⛔ I PRE-REGISTERED THAT AS A CEILING ON FIX A AND IT IS WITHDRAWN --\n")
cat("     diag_ent_conditional_lever.R MEASURED the limb saturating near month 9.8,\n")
cat("     ~2.3 months LATER than the driver, so the reachable range BRACKETS 8.52.\n")
cat("     ⚠ What binds instead is AMPLITUDE: where the phase is right the two SH\n")
cat("     limbs nearly cancel. Limbs are VECTORS; only the refit can resolve it.\n")
