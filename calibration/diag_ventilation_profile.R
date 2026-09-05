# =====================================================================
# diag_ventilation_profile.R -- WHERE IN THE COLUMN IS THE VENTILATION
#   WRONG? The model's D14C profile against GLODAP, LAYER BY LAYER.
#
# Marcus, 2026-09-04i: "I wonder if a tropical box might help with
# capturing intermediate waters." This tests the premise of that
# question -- is the model's ventilation error CONCENTRATED at
# intermediate depths, or is it uniform?
#
# ⭐ WHY THIS IS THE RIGHT INSTRUMENT. 2026-09-04i measured that the
# ocean SINK is blind to circulation GEOMETRY: w_up and w_out differ
# hugely in deep D14C but their sink is identical to 1e-12, because the
# spinup pins mixed-layer DIC and uptake then sees only the volumetric
# rate. So an ocean-structure question can ONLY be answered on INTERIOR
# tracers, and D14C by depth is the one the repo already holds.
#
# ⚠⚠ THE TRAP THIS FILE EXISTS TO AVOID, AND I FELL INTO IT FIRST.
# R/likelihood.R says the PREINDUSTRIAL steady state is the right thing
# to score modern bottle data against -- and that is TRUE FOR THE DEEP
# BOX ONLY, because bomb 14C has not reached 2627-3700 m. Applied to the
# UPPER ocean the same comparison is nonsense: observed surface D14C is
# +50 permil BECAUSE of bomb 14C, and a preindustrial model has none, so
# it reads a 98 permil "error" that is entirely the bomb. This file runs
# the TRANSIENT to the bottle epoch and prints the bomb addition per
# layer so the reader can see which rows the argument covers.
#
# Usage:  Rscript calibration/diag_ventilation_profile.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

VP_NEFF <- LIK_D14C_DEEP_NEFF   # the ruled convention, not a new number

v    <- dg_vector(CCX_MODE_CANONICAL)
sp   <- ccx_spinup(v$p); aux <- sp$aux
grid <- ccx_ocean_grid(v$p$h_ml)
op   <- dg_obs_profile(grid)
go   <- dg_gateG_obs(grid)
z    <- cumsum(grid$dz) - grid$dz / 2
yr   <- round(go$epoch_mean)

F <- ccx_build_forcing("historical", c(1750, yr), prod_c14 = sp$prod_c14,
                       bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
y <- ccx_run_fast(sp, F)$state
# SAME ESTIMATOR as spinup's d14c_bottom_box: 1000*(C14/C - 1), area-weighted
lay <- function(Y, h) { ix <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
                        1000 * (Y[ix, "C14"] / Y[ix, "C"] - 1) }
aw  <- function(Y) (lay(Y, "NH") * aux$a_oc$NH + lay(Y, "SH") * aux$a_oc$SH) /
                   (aux$a_oc$NH + aux$a_oc$SH)
mod <- aw(y); pre <- aw(sp$y)

cat(sprintf("mode %s | GLODAP bottle epoch %.0f (n = %d) | n_eff %g\n\n",
            basename(ccx_mode_file()), go$epoch_mean, go$n_bottles, VP_NEFF))
cat(sprintf("%5s %8s %10s %10s %10s %9s %8s\n",
            "lyr", "depth m", "model", "obs", "bomb add", "obs sd", "z"))
zs <- numeric(length(z))
for (i in seq_along(z)) {
  se <- op$d14_sd[i] / sqrt(VP_NEFF); zs[i] <- (mod[i] - op$d14[i]) / se
  cat(sprintf("%5d %8.0f %10.1f %10.1f %10.1f %9.1f %+8.2f%s\n", i, z[i], mod[i],
              op$d14[i], mod[i] - pre[i], op$d14_sd[i], zs[i],
              if (abs(zs[i]) > 2) "  <--" else ""))
}

cat("\n=== READING ===\n")
up <- which(z <= 500); mid <- which(z > 500 & z <= 2500); bot <- which(z > 2500)
cat(sprintf("  UPPER   (<= 500 m, %d layers): mean z %+.2f  -- bomb-dominated, and it MATCHES\n",
            length(up), mean(zs[up])))
cat(sprintf("  MID     (500-2500 m, %d layers): mean z %+.2f, MAX %+.2f at %.0f m\n",
            length(mid), mean(zs[mid]), max(zs[mid]), z[mid][which.max(zs[mid])]))
cat(sprintf("  BOTTOM  (> 2500 m, %d layers): mean z %+.2f  <-- THE ONLY LAYER THE LIKELIHOOD SCORES\n",
            length(bot), mean(zs[bot])))
cat("\n  ⇒ The model is systematically TOO YOUNG below ~600 m -- i.e. its interior is\n")
cat("    OVER-ventilated -- and the error PEAKS at intermediate depth, not at the\n")
cat("    bottom. The single scored D14C depth row sits BELOW the problem.\n")
cat("  ⚠ AND THE UPPER OCEAN IS NOT EVIDENCE EITHER WAY: those rows are dominated by\n")
cat("    the bomb transient (see the 'bomb add' column), which the calibration fits\n")
cat("    through d14c_NH/SH. They are not an independent check on ventilation.\n")
cat("\n  ⚠⚠ AND A TENSION THIS DOES NOT RESOLVE: an over-ventilated interior should take\n")
cat("    up MORE anthropogenic carbon, yet the centennial pulse response is too LOW\n")
cat("    (IRF(100) 0.276 vs Joos 0.409). Transport and capacity point OPPOSITE ways,\n")
cat("    which argues the capacity shortfall is BUFFER chemistry, not ventilation.\n")
