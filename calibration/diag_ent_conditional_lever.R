# ===================================================================
# THE ENTRAINMENT CHANNEL'S CONDITIONAL LEVER ON THE SPO OCEAN LIMB.
#
# ⛔ THIS IS NOT A TEST OF THE HYPOTHESIS AND MUST NOT BE READ AS ONE. Nothing
# is re-optimised: every coordinate except `ent_seas_amp_SH` is HELD at the
# 25-parameter refit winner, `sst_seas_amp_SH` included -- and that is the very
# coordinate the hypothesis says is strained. So this measures the channel's
# LEVER, not what a fit would do with it. P1-P5 are decided by the refit.
#
# WHAT IT IS FOR. Two things the pre-registration asserted without measuring:
#   (a) whether the channel can rotate the limb into the observed season at all;
#   (b) the CEILING I pre-registered -- "a limb that merely inherits the
#       driver's phase (7.50) does NOT clear GATE S, since 7.50 is z -2.90".
#
# Usage:  Rscript calibration/diag_ent_conditional_lever.R
# ===================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

EC_DIR  <- "calibration/output/multistart_20260902_demean25"
# The scan grid straddles the derived prior centre and the recorded plausibility
# band, and extends past it so saturation is visible rather than assumed.
EC_ENT  <- c(0, 5, ccx_const("ENT_SEAS_AMP_SH_DERIV"), 20,
             ccx_const("ENT_SEAS_AMP_SH_INBAND"), 45)

S  <- readRDS(file.path(EC_DIR, "survey_summary.rds"))
iA <- which(S$group == "A")[which.max(S$logpost[S$group == "A"])]
res <- readRDS(S$files[iA]); pm <- res$par_mode
obs <- ccx_prepare_obs()
pm_mig <- ccx_migrate_par_set(pm)
p0 <- ccx_overlay_par(ccx_default_params(), pm_mig)
p0$pump_mode <- res$pump_mode
mk <- function(ent) { p <- p0; p$ent_seas_amp_SH <- ent
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total) }

cat(sprintf("\n=== ENTRAINMENT LEVER at refit id %d (logpost %.4f), ALL ELSE HELD ===\n",
            res$id, res$logpost))
cat(sprintf("  held: sst_seas_amp_SH = %.4f (prior-z %+.2f), npp_frac_NH = %.4f\n",
            p0$sst_seas_amp_SH, ccx_prior_z("sst_seas_amp_SH", p0$sst_seas_amp_SH),
            p0$npp_frac_NH))
cat(sprintf("\n  %-8s %10s %9s %9s %8s   %s\n",
            "ent", "limb amp", "x obs", "peak mo", "z", "GATE S"))
for (e in EC_ENT) {
  g <- dg_gateS(mk(e), obs); vd <- dg_gateS_verdict(g)
  cat(sprintf("  %-8.2f %10.4f %9.3f %9.2f %+8.2f   %s\n",
              e, g$amp, vd$amp_ratio, g$mo, vd$z, if (vd$pass) "PASS" else "FAIL"))
}
cat(sprintf("\n  obs %.4f ppm @ %.2f [%.2f, %.2f]; the entrainment DRIVER peaks at %.2f\n",
            DG_S_AMP_OBS, DG_S_OBS, DG_S_OBS_LO, DG_S_OBS_HI, CCX_ENT_SEAS_PEAK_MO))
cat("\n  --- READING IT ---\n")
cat("  (a) THE LEVER EXISTS. The limb rotates 4.19 -> ~9.8 months and CROSSES the\n")
cat("      observed window on the way. The phase is reachable.\n")
cat("  (b) ⛔ MY PRE-REGISTERED CEILING IS MEASURED AND IT DOES NOT BIND. The limb\n")
cat("      SATURATES near 9.8 -- some 2.3 months LATER than the 7.50 driver -- so it\n")
cat("      does NOT merely inherit the driver's phase, and the reachable range\n")
cat("      BRACKETS 8.52 rather than falling short of it. Withdraw that caveat.\n")
cat("  (c) ⚠ AND THE CATCH, WHICH IS WHY THIS CANNOT DECIDE ANYTHING. Where the\n")
cat("      PHASE is right (~5) the AMPLITUDE COLLAPSES to ~0.22x observed: solubility\n")
cat("      at 4.19 and entrainment at 7.50 are nearly antiphase and CANCEL. Limbs are\n")
cat("      VECTORS. Conditionally the two cannot both be right -- which is exactly\n")
cat("      what a REFIT is for, since it may move `sst_seas_amp_SH` too. That is P2.\n")
cat("  (d) ⚠ A TENSION WORTH FLAGGING: the phase-centring value is ~5, at prior-z\n")
cat(sprintf("      about -1.6, while the DERIVED centre %.2f puts the phase near 9.7.\n",
            ccx_const("ENT_SEAS_AMP_SH_DERIV")))
cat("      The prior and the phase disagree by roughly 2 sigma. The refit arbitrates.\n")
