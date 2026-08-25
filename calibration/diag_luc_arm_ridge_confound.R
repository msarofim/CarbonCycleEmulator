# =====================================================================
# diag_luc_arm_ridge_confound.R -- IS THE `luc` ARM'S rep_dC RESULT CONFOUNDED
#                                  WITH THE FERTILISATION RIDGE?  (2026-08-25)
#
# 08-24c's headline: the `luc` arm -- a persistent mid-century sink carrying
# ocean-scale isotopes -- moved `rep_dC` by -5.014 sd, which was read as support
# for the PERSISTENCE hypothesis. `luc_arm_pin2` is running now to decide
# whether that move was bought by an inflated `sigma_d14c` (P3 fired at +1.671).
#
# TODAY'S RESULT PUTS A DIFFERENT QUESTION IN FRONT OF THAT ONE.
# diag_fert_ridge_repdc.R measured `rep_dC` as a MONOTONE function of position
# along the (beta_max, fert_k) ridge -- 5.566 at the mode's fert_k 554.5, rising
# to 4.98/3.87/2.87/1.37/0.15/-1.75 as fert_k FALLS to 400/250/180/120/90/60.
# So the ridge is a rep_dC lever in its own right, worth several sd.
#
# AND THE `luc` ARM MOVED ALONG EXACTLY THAT RIDGE. Its beta_max went 1.0112 ->
# 2.7254 (+9.16 sd) and fert_k 554.5 -> 1783.7 (+7.43 sd), while enh(420 ppm)
# changed by only 2.4 % (0.2074 -> 0.2024) -- the signature of travel ALONG a
# rho = +0.997 ridge, not across it. That is the second-largest coordinate move
# in the arm and it is in the direction that controls rep_dC.
#
# THE DECOMPOSITION. Three cells, all with the sink OFF, all other coordinates
# at the REFERENCE mode, rep_dC conditionally optimised in each (exact: it
# enters only the station terms, additively):
#
#   A  reference mode                      -- rep_dC = 5.566, by construction
#   B  reference mode + the arm's RIDGE     -- the ridge's contribution ALONE
#   C  reference mode + the arm's ridge AND its k_w / bomb_total moves
#
# The arm landed at rep_dC = 4.346. If B sits ABOVE 5.566 the ridge was pushing
# rep_dC UP and the sink did MORE work than -5.014 sd. If B sits near 4.346 the
# ridge explains the headline and the sink did little. Either way the -5.014 is
# not a clean reading of the mechanism, which is what pin2 was convened to
# adjudicate on a DIFFERENT axis.
#
# Usage:  Rscript calibration/diag_luc_arm_ridge_confound.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

LC_REF  <- "calibration/output/pump_arms/mode_fit_pumpN.rds"
LC_LUC  <- "calibration/output/luc_arm_pinluc/mode_fit_pumpN.rds"
LC_YEARS <- c(1750, 2024)
LC_GRID  <- seq(-12, 14, by = 0.01)
OUTDIR   <- ccx_path("calibration", "output", "fert_ridge_gates")

ref <- readRDS(ccx_path(LC_REF)); luc <- readRDS(ccx_path(LC_LUC))
stopifnot(!isTRUE(all.equal(unlist(ref$par_mode), unlist(luc$par_mode))))   # seed-copy trap
P0 <- ccx_default_params()
for (n in intersect(names(P0), CCX_PARAM_NAMES)) P0[[n]] <- ref$par_mode[[n]]
P0$gamma_enso <- ref$par_mode$gamma_enso; P0$pump_mode <- ref$pump_mode
SD  <- unlist(ref$sd_unc); REP0 <- ref$par_mode$rep_dC
OBS <- ccx_prepare_obs()

lc_rep <- function(p, luc_scale = ref$par_mode$luc_scale, bomb = ref$par_mode$bomb_total) {
  # SINK OFF: ccx_build_forcing is called with no sink args, so every cell here
  # is the unperturbed forcing. The arm's own sink is deliberately NOT applied --
  # the point is to price the ridge WITHOUT it.
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", LC_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = bomb, luc_scale = luc_scale)
  o  <- ccx_run_fast(sp, F)$out
  el <- ccx_forcing_eluc_annual(F); dp <- sp$diagnostics$d14c_bottom_box
  og <- ccx_ocean_grad_scored(o, sp)
  v <- vapply(LC_GRID, function(r) sum(unlist(ccx_loglik(o, OBS,
        list(sigma_d14c = ref$par_mode$sigma_d14c, rep_dC = r,
             grad_off_co2 = ref$par_mode$grad_off_co2,
             grad_off_d13c = ref$par_mode$grad_off_d13c),
        luc = el, deep = dp, ocean_grad = og, by_stream = TRUE))), numeric(1)) +
       stats::dnorm(LC_GRID, 0, LIK_CO2_REP_ERR, log = TRUE)
  LC_GRID[which.max(v)]
}

cat("\n=== IS THE luc ARM'S rep_dC MOVE CONFOUNDED WITH THE RIDGE? ===\n")
cat(sprintf("reference mode  beta_max %.4f  fert_k %8.2f  rep_dC %.3f\n",
            P0$beta_max, P0$fert_k, REP0))
cat(sprintf("luc arm         beta_max %.4f  fert_k %8.2f  rep_dC %.3f  (%+.3f sd)\n\n",
            luc$par_mode$beta_max, luc$par_mode$fert_k, luc$par_mode$rep_dC,
            (unlist(luc$u_mode)[["rep_dC"]] - unlist(ref$u_mode)[["rep_dC"]]) / SD[["rep_dC"]]))

A <- lc_rep(P0)
pB <- P0; pB$beta_max <- luc$par_mode$beta_max; pB$fert_k <- luc$par_mode$fert_k
B <- lc_rep(pB)
pC <- pB; pC$k_w <- luc$par_mode$k_w
C <- lc_rep(pC, bomb = luc$par_mode$bomb_total)

cat(sprintf("%-46s %10s %10s\n", "cell (sink OFF, rep_dC conditionally optimised)", "rep_dC", "vs ref"))
cat(sprintf("%-46s %10.3f %+10.2f sd\n", "A  reference mode", A, (A - REP0) / SD[["rep_dC"]]))
cat(sprintf("%-46s %10.3f %+10.2f sd\n", "B  + the arm's RIDGE only", B, (B - REP0) / SD[["rep_dC"]]))
cat(sprintf("%-46s %10.3f %+10.2f sd\n", "C  + its k_w and bomb_total too", C, (C - REP0) / SD[["rep_dC"]]))
cat(sprintf("%-46s %10.3f %+10.2f sd\n", "   the ARM ITSELF (sink ON, full vector)",
            luc$par_mode$rep_dC,
            (unlist(luc$u_mode)[["rep_dC"]] - unlist(ref$u_mode)[["rep_dC"]]) / SD[["rep_dC"]]))
cat("\n  A is a gate: it must reproduce the reference rep_dC or the machinery is wrong.\n")
cat(sprintf("  gate |A - %.3f| = %.4f ppm\n", REP0, abs(A - REP0)))
saveRDS(list(A = A, B = B, C = C, arm = luc$par_mode$rep_dC, ref = REP0,
             sd = SD[["rep_dC"]]), file.path(OUTDIR, "luc_arm_ridge_confound.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "luc_arm_ridge_confound.rds")))
