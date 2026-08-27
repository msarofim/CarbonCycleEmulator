# =====================================================================
# diag_npp_frac_anchor.R -- THE 1750 ANCHOR FOR npp_frac_NH, AND HOW
#                           CIRCULAR IT IS
#
# THE PROVENANCE OF A SHIPPED CONSTANT. `NPP_FRAC_NH_ANCHOR_1750` in
# R/constants.R is the centre of npp_frac_NH's prior. It is NOT an observation:
# MOD17 measures the MODERN NH share (0.594) and the parameter is a 1750 split,
# so the anchor is that observation walked BACK through the model's own
# hemispheric clearing. This script is where that number comes from, and it
# prices the circularity rather than waving at it.
#
# THE FIXED POINT, not the value at the incumbent's fit. The walk depends on the
# cleared FRACTION, cum_luc / land0, and land0 is proportional to npp0 -- which
# is npp_frac_NH itself. Evaluating the inversion at the fitted 0.4662 gives
# 0.6136; iterating to self-consistency gives 0.5986. The fixed point is the
# right number: it is the only value that reproduces MOD17 when the model is
# actually RUN at it.
#
# HOW CIRCULAR IS IT? The anchor rides on `luc_scale` and on the land turnover
# times, both of which are fitted. Marcus' criterion for this project is that a
# choice be physically reasonable and use the observations; the question is
# therefore whether the model-dependence is small against the observational
# uncertainty. It is, by an order of magnitude -- see the table this prints.
#
# Usage:  Rscript calibration/diag_npp_frac_anchor.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

AN_MODE <- ccx_mode_file()
AN_NPP  <- ccx_path("data", "obs_npp_hemispheric.rds")

md <- readRDS(AN_MODE)
p0 <- ccx_default_params(); for (n in names(md$par_mode)) p0[[n]] <- md$par_mode[[n]]
np <- readRDS(AN_NPP); q <- np$nh_share_mean
F0 <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
iw <- which(F0$year >= min(np$years) & F0$year <= max(np$years))

#' The 1750 share implied by the observed MODERN share q, given a candidate 1750
#' share `x` (which sets land0 and hence the cleared fractions) and a luc_scale.
anchor_at <- function(x, luc = p0$luc_scale, p = p0) {
  npp0 <- ccx_const("NPP_GLOBAL_PI") * c(NH = x, SH = 1 - x)
  tl <- p$npp_leaf_frac * p$tau_leaf + (1 - p$npp_leaf_frac) * p$tau_wood +
        (1 - p$litter_slow_frac) * p$tau_soil_fast + p$litter_slow_frac * p$tau_soil_slow
  land0 <- npp0 * tl
  a <- 1 - mean(F0$cum_luc_NH[iw]) * luc / land0[["NH"]]     # NH fraction UNcleared
  b <- 1 - mean(F0$cum_luc_SH[iw]) * luc / land0[["SH"]]
  q * b / (q * b + (1 - q) * a)
}
fixed_point <- function(luc = p0$luc_scale, p = p0, x0 = 0.5) {
  x <- x0
  for (i in 1:200) { xn <- anchor_at(x, luc, p); if (abs(xn - x) < 1e-12) break; x <- xn }
  stopifnot(abs(anchor_at(x, luc, p) - x) < 1e-10)          # it really is a fixed point
  x
}

A <- fixed_point()
cat(sprintf("MOD17 modern NH share            %.10f  (sd %.4f across %d-%d)\n",
            q, np$nh_share_sd, min(np$years), max(np$years)))
cat(sprintf("anchor evaluated at the FIT      %.6f   <- what the audit quoted\n",
            anchor_at(p0$npp_frac_NH)))
cat(sprintf("SELF-CONSISTENT 1750 ANCHOR      %.10f   <- NPP_FRAC_NH_ANCHOR_1750\n\n", A))

cat("=== CIRCULARITY: how far the anchor moves when the model does ===\n")
cat(sprintf("  %-40s %12s %10s\n", "perturbation", "anchor", "delta"))
show <- function(lab, v) cat(sprintf("  %-40s %12.6f %+10.6f\n", lab, v, v - A))
for (m in c(0.7, 0.85, 1.15, 1.3)) show(sprintf("luc_scale x %.2f", m), fixed_point(p0$luc_scale * m))
for (m in c(0.7, 1.3)) {
  p <- p0; p$tau_wood <- p0$tau_wood * m
  show(sprintf("tau_wood x %.2f (moves land0)", m), fixed_point(p = p))
}
for (m in c(0.7, 1.3)) {
  p <- p0; p$tau_soil_slow <- p0$tau_soil_slow * m
  show(sprintf("tau_soil_slow x %.2f (moves land0)", m), fixed_point(p = p))
}
cat(sprintf("\n  FOR SCALE: MOD17's own interannual sd on the share is %.4f, and the\n",
            np$nh_share_sd))
cat("  prior width is 0.04. Every model-dependence above is an order of magnitude\n")
cat("  below the width, which is what makes the inversion defensible rather than\n")
cat("  circular. NOT self-evident -- evaluated at the fit instead of the fixed\n")
cat(sprintf("  point, the same quantity moves %+.4f.\n", anchor_at(p0$npp_frac_NH) - A))
