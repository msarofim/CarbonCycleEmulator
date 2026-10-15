# =====================================================================
# diag_hml_seasonal_limbs.R -- IS THE REFIT'S 35.38 m MIXED LAYER A REPAIR
# OF THE SH OCEAN SEASONAL LIMB, OR AN ARTIFACT?
#
# WHY THIS EXISTS. The 2026-08-28 option-5 refit freed h_ml and it moved
# 96.47 -> 35.38 m, buying +4.06 logpost that is ENTIRELY prior credit
# (loglik -1.199) and relieving sst_seas_amp_SH from z -6.321 to -5.595 and
# sst_seas_amp_NH from -3.483 to -2.931. "SH ocean 0.45x too small" is the
# standing defect of the seasonal arc -- the one `ent` could not fix (vetoed),
# `tau_ex` was exonerated of, and the (phi_eff, amp) pair could not resolve
# (degenerate ridge). So the hypothesis was that the [85, 120] band had been
# BLOCKING a real lever on that limb, and option 5 handed it back.
#
# ⚠ THE PHYSICS THAT MOTIVATED THAT HYPOTHESIS WAS WRONG, AND IS RETRACTED HERE.
# I wrote that "a shallower mixed layer RAISES the ocean's seasonal amplitude
# response". diag_hml_sst_elasticity.R MEASURED the opposite: at a FIXED
# sst_seas_amp_SH, taking h_ml 96.47 -> 35.38 m takes the SPO ocean limb
# 0.3066 -> 0.2577, i.e. 59% -> 49% of observed, and rotates its phase from
# 4.15 to 3.90 months against obs 8.52. A shallow mixed layer makes this limb
# WORSE on both counts. The hypothesis below was therefore testing a lever that
# runs the wrong way; the test still stands, and it is REFUTED.
#
# The alternative is that 35.38 m is just where the seasonal priors dragged a
# soft direction, with no mechanism behind it. These predict different things
# about the LIMBS, which is why this measures limbs and not logposts.
#
# ⚠ NOTHING HERE CHANGES AN OBJECTIVE. No constant, prior, R/ or src/ is
# touched, and no refit is owed by anything it prints. It is a MEASUREMENT at
# two already-fitted vectors.
#
# METHOD IS diag_admissible_2x2_land_ocean.R's, COPIED NOT REINVENTED
# ([[match_incumbents_optim]]): the same knockout cases, the same PEAK-TO-PEAK
# amp() and the same ang_mo(), because semi-amplitude vs peak-to-peak has
# already inverted a conclusion on this arc ([[amp_definition_mismatch]]).
# ⚠ The ocean case must kill BOTH SH limbs -- zeroing sst_seas_amp_SH alone
# leaves the entrainment limb running (the 27g bug).
#
# ---------------------------------------------------------------------
# PREDICTIONS, WRITTEN BEFORE THE RUN.
#   P1  REPAIR: the SH_ocean limb amplitude is LARGER at the new mode than at
#       the old, moving toward obs 0.522. (Artifact -> unchanged or smaller.)
#   P2  PHASE: the SH_ocean limb rotates toward obs 8.52 months, away from the
#       ~3.35 the arc has recorded. A magnitude that grows while the phase
#       stays antiphase is NOT a repair -- it makes the cancellation worse
#       ([[ccx_seas_2x2_admissible]]'s own lesson: limbs are VECTORS).
#   P3  OBSERVABLE HELD: the SPO total stays near obs 1.168. If the total
#       breaks, a shallow h_ml has traded a matched observable for a mechanism.
#   P4  CONTROL, and this is the one that can kill it: h_ml is a GLOBAL ocean
#       parameter, not an SH one. If NH_origin moves as much as SH_ocean in
#       relative terms, nothing SH-specific has been repaired and P1 is a
#       side effect of a global amplitude change.
# ---------------------------------------------------------------------
# Usage:  Rscript calibration/diag_hml_seasonal_limbs.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

HL_YEARS     <- c(1750, 2024)
HL_OBS_TOTAL <- 1.168; HL_OBS_LAND <- 0.683; HL_OBS_OCEAN <- 0.522
HL_OBS_OCEAN_MO <- 8.52                      # obs ocean limb phase, months
HL_ENT       <- 0                            # the SHIPPED default; `ent` is not
                                             # one of the 21 and is NOT fitted here
HL_MODES     <- c(old = "calibration/output/quarantine/20260903_ent26_adopted/refit_20260825f_from90/mode_fit_pumpN.rds",
                  new = "calibration/output/refit_20260828_sigma_eff/mode_fit_pumpN.rds")

sep    <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))            # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

obs    <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params().
run_at <- function(pv, pump_mode, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv); p$pump_mode <- pump_mode
  p$ent_seas_amp_SH <- HL_ENT
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", HL_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")))
}
HL_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))

cat("h_ml AND THE SH SEASONAL LIMBS -- measurement at two fitted vectors\n")
cat(sprintf("obs: total %.3f | SH land %.3f | SH ocean %.3f @ mo %.2f\n",
            HL_OBS_TOTAL, HL_OBS_LAND, HL_OBS_OCEAN, HL_OBS_OCEAN_MO))
cat(sprintf("ent_seas_amp_SH = %g (shipped default, NOT fitted) in every arm\n", HL_ENT))

R <- list()
for (nm in names(HL_MODES)) {
  md <- readRDS(ccx_path(HL_MODES[[nm]]))
  # ccx_mode_params() -- NEVER ccx_unc_to_par(md$u_mode): the old mode's u_mode
  # decodes under ITS OWN band and gives 85.73 m instead of 96.47 ([[ccx_hml_band_decode]]).
  pv <- ccx_mode_params(md)
  sep(sprintf("%s mode -- h_ml = %.2f m, sst_seas_amp_SH = %.4f (z %.3f)",
              toupper(nm), pv$h_ml, pv$sst_seas_amp_SH, md$prior_z[["sst_seas_amp_SH"]]))
  b  <- run_at(pv, md$pump_mode)
  d  <- lapply(HL_CASES, function(m) {
          v <- b$co2_SPO - run_at(pv, md$pump_mode, m)$co2_SPO
          c(amp = amp(v), mo = ang_mo(v)) })
  cat(sprintf("  %-10s %8s %8s\n", "limb", "amp", "mo"))
  cat(sprintf("  %-10s %8.4f %8.2f   (obs %.3f)\n", "TOTAL",
              amp(b$co2_SPO), ang_mo(b$co2_SPO), HL_OBS_TOTAL))
  for (k in names(d))
    cat(sprintf("  %-10s %8.4f %8.2f%s\n", k, d[[k]][["amp"]], d[[k]][["mo"]],
        if (k == "SH_ocean") sprintf("   (obs %.3f @ %.2f)", HL_OBS_OCEAN, HL_OBS_OCEAN_MO)
        else if (k == "SH_land") sprintf("   (obs %.3f)", HL_OBS_LAND) else ""))
  R[[nm]] <- list(pv = pv, total = c(amp = amp(b$co2_SPO), mo = ang_mo(b$co2_SPO)), dec = d)
}

sep("THE PREDICTIONS, SCORED")
o <- R$old; n <- R$new
vg <- function(tag, val, pass, note) cat(sprintf("  %-4s %-46s %10.4f  %s  %s\n",
       tag, note, val, if (pass) "PASS" else "FAIL", ""))
d_oc  <- n$dec$SH_ocean[["amp"]] - o$dec$SH_ocean[["amp"]]
d_nh  <- n$dec$NH_origin[["amp"]] - o$dec$NH_origin[["amp"]]
vg("P1", d_oc, d_oc > 0, "SH_ocean amp GREW (new - old)")
cat(sprintf("       %.4f -> %.4f, obs %.3f: %.0f%% -> %.0f%% of observed\n",
            o$dec$SH_ocean[["amp"]], n$dec$SH_ocean[["amp"]], HL_OBS_OCEAN,
            100*o$dec$SH_ocean[["amp"]]/HL_OBS_OCEAN, 100*n$dec$SH_ocean[["amp"]]/HL_OBS_OCEAN))
d_mo <- abs(n$dec$SH_ocean[["mo"]] - HL_OBS_OCEAN_MO) -
        abs(o$dec$SH_ocean[["mo"]] - HL_OBS_OCEAN_MO)
vg("P2", d_mo, d_mo < 0, "SH_ocean phase moved TOWARD obs (neg = better)")
cat(sprintf("       mo %.2f -> %.2f, obs %.2f\n",
            o$dec$SH_ocean[["mo"]], n$dec$SH_ocean[["mo"]], HL_OBS_OCEAN_MO))
vg("P3", n$total[["amp"]], abs(n$total[["amp"]] - HL_OBS_TOTAL) < 0.10,
   "SPO TOTAL still near obs 1.168 (+-0.10)")
cat(sprintf("       total %.4f -> %.4f\n", o$total[["amp"]], n$total[["amp"]]))
rel_oc <- d_oc / max(o$dec$SH_ocean[["amp"]], 1e-9)
rel_nh <- d_nh / max(o$dec$NH_origin[["amp"]], 1e-9)
vg("P4", rel_nh, abs(rel_nh) < abs(rel_oc) / 2,
   "CONTROL: NH moved <1/2 as much, relatively")
cat(sprintf("       SH_ocean %+.1f%% vs NH_origin %+.1f%% -- if comparable, the\n",
            100*rel_oc, 100*rel_nh))
cat("       change is a GLOBAL amplitude effect, not an SH repair.\n")
cat(sprintf("\n  SH_land %.4f -> %.4f (obs %.3f): %.2fx -> %.2fx observed\n",
            o$dec$SH_land[["amp"]], n$dec$SH_land[["amp"]], HL_OBS_LAND,
            o$dec$SH_land[["amp"]]/HL_OBS_LAND, n$dec$SH_land[["amp"]]/HL_OBS_LAND))
saveRDS(list(R = R, obs = c(total = HL_OBS_TOTAL, land = HL_OBS_LAND,
                            ocean = HL_OBS_OCEAN, ocean_mo = HL_OBS_OCEAN_MO),
             cases = HL_CASES, ent = HL_ENT),
        ccx_path("outputs", "diagnostics", "hml_seasonal_limbs.rds"))
cat(sprintf("\nwritten: outputs/diagnostics/hml_seasonal_limbs.rds\n"))
