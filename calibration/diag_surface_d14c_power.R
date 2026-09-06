# =====================================================================
# diag_surface_d14c_power.R -- DOES THE PREINDUSTRIAL LS-SURFACE D14C HAVE
#   POWER AS A GATE, BEFORE ANY TARGET IS SOURCED FOR IT?
#
# Pre-registered in notes/prereg_2026-09-05d_surface_d14c_power.md.
#
# ⛔ NO TARGET IS ASSERTED HERE. The -40 +/- 20 in play is PRESCRIBED in HILDA's
# Table 2 -- a model calibration paper -- attributed there to GEOSECS, and the
# primary has not been read. The right product (GLODAP's mapped NATURAL /
# pre-bomb D14C, Key et al. 2004 via Rubin & Key 2002) is not in this repo.
# So this script measures the thing that needs no target: a gate on a quantity
# with no power is worthless however well its threshold is sourced.
#
# SCOPE: the SHIPPED model, hs_frac = 0, 32 boxes. A gate is for the model that
# ships, not for the experimental HILDA structure.
#
# Usage:  Rscript calibration/diag_surface_d14c_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

SP_KW_SIGMA   <- 2            # scan k_w over +/- this many prior sigmas
SP_N_KW       <- 5
SP_N_KZ       <- 5
SP_TARGET_W   <- 20           # permil. ⚠ A STAND-IN FOR A TARGET WIDTH, taken
                              # from HILDA's stated +/-20 so the power question
                              # has a scale. NOT a sourced sigma, and it must
                              # not become one by appearing here.
SP_LOGPOST_TOL <- 2           # logpost units treated as "roughly equivalent"
SP_KW_HILDA   <- 906          # HILDA's gas exchange as our k_w (09-05c)

v0 <- dg_vector(CCX_MODE_CANONICAL)
md <- readRDS(ccx_mode_file())
# THE FITTED list, migrated the way dg_vector() migrates it -- ccx_par_to_unc()
# needs ALL 26 names, not the two being scanned, and it errors by name rather
# than filling a gap silently.
pm0 <- ccx_migrate_par_set(md$par_mode)

kwp <- CCX_PARAM_TABLE$k_w
kzp <- CCX_PARAM_TABLE$kz
kw_med <- 1500; kw_slog <- 0.40          # the prior's own parameters
KW <- exp(seq(log(kw_med) - SP_KW_SIGMA * kw_slog,
              log(kw_med) + SP_KW_SIGMA * kw_slog, length.out = SP_N_KW))
# ⚠ INSET FROM THE BRACKET, NOT ON IT. `kz` is fitted under a LOGIT transform,
# so its bounds encode to +/-Inf and ccx_par_to_unc() errors by name on them --
# [[runnable_is_not_encodable]], and the guard fired here exactly as designed. A
# value the model can RUN is not automatically a point of the FITTED space.
SP_KZ_INSET <- 0.02
KZ <- seq(kzp$lo + SP_KZ_INSET * (kzp$hi - kzp$lo),
          kzp$hi - SP_KZ_INSET * (kzp$hi - kzp$lo), length.out = SP_N_KZ)

cat("\n===============================================================\n")
cat("diag_surface_d14c_power.R -- power BEFORE target\n")
cat(sprintf("mode %s, hs_frac = 0 (32 boxes).  k_w over +/-%g prior sigma: %.0f..%.0f\n",
            CCX_MODE_CANONICAL, SP_KW_SIGMA, min(KW), max(KW)))
cat(sprintf("kz over its shipped bracket: %.1f..%.1f\n", min(KZ), max(KZ)))
cat(sprintf("⚠ HILDA's gas exchange is k_w = %g, which is %+.2f prior sigma -- INSIDE the prior.\n",
            SP_KW_HILDA, log(SP_KW_HILDA / kw_med) / kw_slog))
cat("===============================================================\n")

lp_fun <- ccx_make_logpost()

# the quantity: preindustrial LS mixed-layer D14C, area-weighted over the two
# hemispheres. AREA-weighted, not a plain mean: the boxes differ by a third.
surf_d14c <- function(p) {
  sp <- ccx_spinup(p); a <- sp$aux
  v <- vapply(HEMIS, function(h) {
    i <- a$idx[[h]]$ml; 1000 * (sp$y[i, "C14"] / sp$y[i, "C"] - 1) }, numeric(1))
  aw <- vapply(HEMIS, function(h) a$a_ls[[h]], numeric(1))
  sum(v * aw) / sum(aw)
}

grid <- expand.grid(k_w = KW, kz = KZ)
grid$surf <- NA_real_; grid$lp <- NA_real_
for (i in seq_len(nrow(grid))) {
  pm <- pm0; pm$k_w <- grid$k_w[i]; pm$kz <- grid$kz[i]
  u  <- ccx_par_to_unc(pm)
  p <- v0$p; p$k_w <- grid$k_w[i]; p$kz <- grid$kz[i]
  grid$surf[i] <- surf_d14c(p)
  grid$lp[i]   <- lp_fun(u)
}
lp0 <- max(grid$lp, na.rm = TRUE)
grid$dlp <- lp0 - grid$lp

cat("\n=== THE SCAN: preindustrial LS-surface D14C (permil), and logpost cost ===\n\n")
cat(sprintf("  %10s", "k_w \\ kz")); for (z in KZ) cat(sprintf(" %14.0f", z)); cat("\n")
for (w in KW) {
  cat(sprintf("  %10.0f", w))
  for (z in KZ) {
    r <- grid[abs(grid$k_w - w) < 1e-6 & abs(grid$kz - z) < 1e-6, ]
    cat(sprintf(" %+7.1f/%6.1f", r$surf, r$dlp))
  }
  cat("\n")
}
cat("  (each cell: surface D14C permil / logpost units BELOW the scan's best)\n")

cat("\n=== THE SCORED PREDICTIONS (prereg 2026-09-05d) ===\n")
rng <- range(grid$surf, na.rm = TRUE)
cat(sprintf("  P1d -- RANGE across the prior support: %.1f to %.1f = %.1f permil (need > %g) -> %s\n",
            rng[1], rng[2], diff(rng), SP_TARGET_W,
            if (diff(rng) > SP_TARGET_W) "CONFIRMED" else "FALSIFIED -- no target worth acquiring"))

near <- grid[is.finite(grid$dlp) & grid$dlp < SP_LOGPOST_TOL, ]
sp_near <- if (nrow(near) > 1) diff(range(near$surf)) else 0
cat(sprintf("  P2d(slice) -- within %g logpost units of the 2-D SLICE, surface D14C spans\n",
            SP_LOGPOST_TOL))
cat(sprintf("          %.1f permil across %d of %d cells.\n", sp_near, nrow(near), nrow(grid)))
cat("  ⛔ AND THAT NUMBER MUST NOT BE READ AS THE ANSWER. It holds the other 24\n")
cat("     parameters FIXED, and this repo has already been wrong that way once:\n")
cat("     [[ccx_gates_priced]] measured that an iso-fit frontier which RE-OPTIMISES\n")
cat("     the others REVERSES what a one-at-a-time kz scan says. A slice through a\n")
cat("     correlated posterior OVERSTATES how pinned a quantity is.\n")

# ---- P2d, DONE PROPERLY: how far can the quantity move INSIDE the posterior? --
# The Laplace covariance is already stored in the mode file (26x26, pd), so this
# costs 52 spinups rather than 25 refits. Linearise the observable in the
# UNCONSTRAINED coordinates, then sd = sqrt(g' Sigma g) is the spread the
# EXISTING objective still permits -- along the posterior's own directions, not
# along a coordinate axis.
cat("\n  P2d -- INDEPENDENCE, on the POSTERIOR's own directions (Laplace covariance)\n")
Sig <- md$cov
stopifnot(identical(colnames(Sig), CCX_PARAM_NAMES), isTRUE(md$pd))
u_mode <- ccx_par_to_unc(pm0)
surf_at_u <- function(u) {
  pv <- ccx_unc_to_par(stats::setNames(as.numeric(u), CCX_PARAM_NAMES))
  # ccx_overlay_par() rather than a bare intersect() copy loop: it migrates,
  # copies, and ASSERTS THE OVERLAY DELETED NOTHING. Here `pv` is built FROM
  # CCX_PARAM_NAMES, so it carries all 26 by construction and the assertion
  # cannot fire -- which is exactly why this conversion is numerically
  # identical (verified: mode -48.35, sd 0.93 unchanged to 2 dp). The idiom is
  # banned at NEW sites regardless of whether a given one is provably safe;
  # "safe here" is not a property a reader can check at a glance, and the next
  # copy of it would not be. See tests/testthat/test-overlay-idiom-lint.R.
  surf_d14c(ccx_overlay_par(v0$p, pv))
}
s0 <- surf_at_u(u_mode)
g  <- numeric(length(CCX_PARAM_NAMES))
names(g) <- CCX_PARAM_NAMES
for (j in seq_along(g)) {
  h <- max(1e-4, 1e-3 * abs(u_mode[[j]]))
  up <- u_mode; up[j] <- up[j] + h
  dn <- u_mode; dn[j] <- dn[j] - h
  g[j] <- (surf_at_u(up) - surf_at_u(dn)) / (2 * h)
}
sd_post <- sqrt(drop(t(g) %*% Sig %*% g))
cat(sprintf("          surface D14C at the mode: %+.2f permil\n", s0))
cat(sprintf("          sd induced by the posterior: %.2f permil (need > %g to be NEW) -> %s\n",
            sd_post, SP_TARGET_W,
            if (sd_post > SP_TARGET_W) "CONFIRMED -- NOT pinned; a gate would add information"
            else "FALSIFIED -- already pinned; a gate would be REDUNDANT"))
cn <- (g * (Sig %*% g))[, 1]
cn <- sort(cn[order(-abs(cn))][1:5], decreasing = TRUE)
cat("          top contributors to that variance (g_i * (Sigma g)_i):\n")
for (n in names(cn)) cat(sprintf("            %-20s %+8.2f\n", n, cn[[n]]))

# P3d: the sign of each partial, at the mode's own row/column
mid_kz <- KZ[ceiling(length(KZ) / 2)]; mid_kw <- KW[ceiling(length(KW) / 2)]
rw <- grid[abs(grid$kz - mid_kz) < 1e-6, ]; rw <- rw[order(rw$k_w), ]
rz <- grid[abs(grid$k_w - mid_kw) < 1e-6, ]; rz <- rz[order(rz$kz), ]
cat(sprintf("  P3d -- DIRECTION (reported, not gated):\n"))
cat(sprintf("          d(surface)/d(k_w) at kz %.0f : %+.1f permil over the scan -> %s\n",
            mid_kz, diff(range(rw$surf)) * sign(tail(rw$surf,1) - rw$surf[1]),
            if (tail(rw$surf, 1) > rw$surf[1]) "RISES with k_w, as predicted" else "FALLS -- against the prediction"))
cat(sprintf("          d(surface)/d(kz)  at k_w %.0f: %+.1f permil over the scan -> %s\n",
            mid_kw, diff(range(rz$surf)) * sign(tail(rz$surf,1) - rz$surf[1]),
            if (tail(rz$surf, 1) < rz$surf[1]) "FALLS with kz, as predicted" else "RISES -- against the prediction"))

cat("\n⛔ NO TARGET IS ASSERTED BY THIS SCRIPT AND NO GATE IS BUILT.\n")
cat("   The 20 permil above is a STAND-IN for a target width, not a sourced sigma.\n\n")
