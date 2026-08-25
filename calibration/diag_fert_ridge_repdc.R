# =====================================================================
# diag_fert_ridge_repdc.R -- DOES `rep_dC` ABSORB THE COST OF A STRONGLY
#                            SATURATING FERTILISATION -- AND DOES IT FALL?
#                            (2026-08-25)
#
# diag_fert_ridge_streams.R located the 8657 log-units that a strongly
# saturating fertilisation costs, and the answer is unambiguous:
#
#   co2_level_MLO  -4144.2      93 % of the total, in TWO streams
#   co2_level_SPO  -3894.6
#   ...every sink and seasonal stream together    < 80
#   gcb_land_sink  -0.7,  gcb_ocean_sink  -1.0    i.e. the GCB terms DO NOT CARE
#
# The rejection is entirely the ABSOLUTE CO2 LEVEL at the two stations. And the
# model carries a fitted parameter whose ONLY job is that level: `rep_dC`, the
# shared station-minus-box offset (R/likelihood.R:1105 for CO2, :1251 for the
# d13C conversion), sitting at +5.566 ppm = 5.6 sigma from its prior and blocking
# the project since 2026-08-21.
#
# IT IS FROZEN IN THAT SCAN. So the 8657 is measured with the one parameter that
# could absorb it held at a value chosen for a DIFFERENT fertilisation shape.
# This file frees it, and the question is not only how much cost comes back but
# WHICH WAY rep_dC MOVES:
#
#   * if the saturating cell wants a SMALLER rep_dC, then gate 4's fix and the
#     rep_dC blocker are ONE problem, and the whole 08-23 -> 08-25 arc has been
#     hunting a mid-century mechanism for something the fertilisation SHAPE
#     explains;
#   * if it wants a LARGER one, the two are in conflict and the gate-4 fix makes
#     the blocker worse;
#   * if rep_dC barely moves, the cost is real and the objective and the gates
#     genuinely disagree.
#
# WHY A 1-D PROFILE IS LEGITIMATE HERE, and it is the same argument the P3
# diagnostic had to make: `rep_dC` enters NOTHING but those station terms and is
# additively separable from the rest, so at fixed model output its conditional
# optimum is exact -- no re-integration is needed and none is done. What this
# CANNOT do is let the other 19 parameters respond; the recovered cost is a
# LOWER bound on what a refit would recover, and rep_dC's landing point is
# conditional on the frozen rest.
#
# THE PRIOR IS NOT FLAT AND IS CARRIED. rep_dC ~ N(0, LIK_CO2_REP_ERR)
# (R/calibrate.R:426). The P3 diagnostic's first draft called this prior flat
# over the scanned range and it is not -- so the profile below is a POSTERIOR
# profile, and the likelihood-only argmax is printed beside it precisely because
# the two disagree ([[profile_beats_optimum]]).
#
# Usage:  Rscript calibration/diag_fert_ridge_repdc.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

FP_MODE_FILE <- "calibration/output/pump_arms/mode_fit_pumpN.rds"
FP_YEARS     <- c(1750, 2024)
FP_CHI_NOW   <- 420
FP_KGRID     <- c(60, 90, 120, 180, 250, 400)
FP_GRID      <- seq(-12, 12, by = 0.01)      # rep_dC, ppm
OUTDIR       <- ccx_path("calibration", "output", "fert_ridge_gates")
CHI0 <- ccx_const("CO2_PI_PPM")

md <- readRDS(ccx_path(FP_MODE_FILE))
stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
P0 <- ccx_default_params()
for (n in intersect(names(P0), CCX_PARAM_NAMES)) P0[[n]] <- md$par_mode[[n]]
P0$gamma_enso <- md$par_mode$gamma_enso
P0$pump_mode  <- md$pump_mode
LUC0 <- md$par_mode$luc_scale; BOMB0 <- md$par_mode$bomb_total
REP0 <- md$par_mode$rep_dC
SD_REP <- unlist(md$sd_unc)[["rep_dC"]]
OBS  <- ccx_prepare_obs()
d_now <- FP_CHI_NOW - CHI0
ENH0  <- P0$beta_max * d_now / (P0$fert_k + d_now)
lprior <- function(x) stats::dnorm(x, 0, LIK_CO2_REP_ERR, log = TRUE)

fp_cell <- function(K) {
  p <- P0
  if (!is.na(K)) { p$fert_k <- K; p$beta_max <- ENH0 * (K + d_now) / d_now }
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", FP_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = BOMB0, luc_scale = LUC0)
  o  <- ccx_run_fast(sp, F)$out
  el <- ccx_forcing_eluc_annual(F); dp <- sp$diagnostics$d14c_bottom_box
  og <- ccx_ocean_grad_scored(o, sp)
  ll <- function(r) {
    e <- list(sigma_d14c = md$par_mode$sigma_d14c, rep_dC = r,
              grad_off_co2 = md$par_mode$grad_off_co2,
              grad_off_d13c = md$par_mode$grad_off_d13c)
    sum(unlist(ccx_loglik(o, OBS, e, luc = el, deep = dp, ocean_grad = og, by_stream = TRUE)))
  }
  v  <- vapply(FP_GRID, ll, numeric(1))
  vp <- v + lprior(FP_GRID)
  list(at_mode_rep = ll(REP0), lik_argmax = FP_GRID[which.max(v)], lik_max = max(v),
       post_argmax = FP_GRID[which.max(vp)], post_max = max(vp),
       beta_max = p$beta_max)
}

cat(sprintf("\n=== DOES rep_dC ABSORB THE SATURATION COST? ===\n"))
cat(sprintf("mode: fert_k %.1f  beta_max %.4f  rep_dC %.4f ppm (sd %.4f)\n",
            P0$fert_k, P0$beta_max, REP0, SD_REP))
cat(sprintf("ridge held at enh(%d ppm) = %.4f; rep_dC ~ N(0, %.3f) ppm\n\n", FP_CHI_NOW, ENH0, LIK_CO2_REP_ERR))
ref <- fp_cell(NA)
cat(sprintf("%7s %8s | %11s %11s %8s | %10s %9s %8s\n",
            "fert_k", "beta_max", "logL@rep0", "logL@best", "recovd",
            "rep_dC best", "d(sd)", "d post"))
R <- list()
for (K in c(P0$fert_k, FP_KGRID)) {
  c_ <- fp_cell(if (isTRUE(all.equal(K, P0$fert_k))) NA else K)
  R[[sprintf("%g", K)]] <- c_
  cat(sprintf("%7.1f %8.3f | %11.1f %11.1f %7.1f%% | %10.3f %+9.2f %+8.1f%s\n",
              K, c_$beta_max, c_$at_mode_rep - ref$at_mode_rep,
              c_$post_max - ref$post_max,
              if (c_$at_mode_rep - ref$at_mode_rep < -1e-9)
                100 * (1 - (c_$post_max - ref$post_max) / (c_$at_mode_rep - ref$at_mode_rep)) else NA,
              c_$post_argmax, (c_$post_argmax - REP0) / SD_REP,
              c_$post_max - ref$post_max,
              if (isTRUE(all.equal(K, P0$fert_k))) "  <- MODE" else ""))
}
cat(sprintf("\n  logL@rep0  = cost with rep_dC FROZEN at the mode's %.3f ppm\n", REP0))
cat("  logL@best  = cost after re-optimising rep_dC alone (posterior, prior carried)\n")
cat("  recovd     = share of the frozen cost that rep_dC alone gives back\n")
cat(sprintf("  d(sd)      = rep_dC's move in units of its own posterior sd (%.4f ppm)\n", SD_REP))
cat("\n  A 1-D conditional optimum is EXACT for rep_dC (it enters only the station\n")
cat("  terms, additively) but the other 19 parameters are frozen, so the recovered\n")
cat("  cost is a LOWER bound on a refit's and the landing point is conditional.\n")

saveRDS(list(ref = ref, R = R, rep0 = REP0, sd_rep = SD_REP, enh0 = ENH0,
             grid = range(FP_GRID)), file.path(OUTDIR, "fert_ridge_repdc.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "fert_ridge_repdc.rds")))
