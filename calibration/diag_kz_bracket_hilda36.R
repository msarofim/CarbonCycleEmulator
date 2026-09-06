# =====================================================================
# diag_kz_bracket_hilda36.R -- RE-BISECT THE `kz` BRACKET ON THE 36-BOX
# STRUCTURE (2026-09-06/07; prereg_2026-09-07 sec.4, Marcus's ruling).
#
# The shipped [4379.1, 8109.9] was bisected (09-01) for the 32-box COLUMN,
# where `kz` alone sets the bottom box. With HILDA's structure ON the bottom
# box is set by K_deep = f * kz AND the conduit, so the same recipe is run
# with the structure DECLARED at its refit values and the two fitted
# structure parameters at their TABLE INITS (f = KB36_F_INIT, hs_asx_frac =
# KB36_ASX_INIT): default parameters otherwise, pump ON at the observed
# gradient, mode N, the SOURCED GLODAP bottom-box target at k = 1, 2, 3 sigma.
# ⚠ WHAT THIS IS: a bracket on `kz` AT FIXED f. In the refit f is free and the
# deep row pins the PRODUCT f*kz, so the bracket's job is the one it had
# before -- a support, not an identification -- and prediction R6 (kz lands
# INTERIOR) is the test of whether it is wide enough. Nothing adopted here;
# the k = 3 box is written into R/calibrate.R by hand, with this log as source.
#
# Usage:  Rscript calibration/diag_kz_bracket_hilda36.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
KB36_HS_FRAC <- 0.16; KB36_U_HS <- 38; KB36_TAU_Q <- 538; KB36_SST_HS <- 2; KB36_ZK <- 253; KB36_ATTACH <- 1
KB36_F_INIT <- 0.05; KB36_ASX_INIT <- 1.0
KB36_SIGMAS <- c(1, 2, 3); KB36_SEARCH <- c(500, 40000); KB36_TOL <- 0.5
KB36_GRID <- c(500, 1000, 2000, 4000, 6356, 8000, 12000, 20000, 40000)
KB36_OUT <- ccx_path("outputs", "diagnostics", "kz_bracket_hilda36_20260906.rds")
tg <- ccx_deep_d14c_target(); if (is.null(tg)) stop("deep target absent")
p0 <- ccx_default_params(); p0$pump_grad <- ccx_const("PUMP_GRAD_OBS"); p0$pump_mode <- "N"
p0$hs_frac <- KB36_HS_FRAC; p0$u_hs <- KB36_U_HS; p0$tau_q <- KB36_TAU_Q; p0$sst_hs <- KB36_SST_HS
p0$q_attach_from <- KB36_ATTACH; p0$kz_zscale <- KB36_ZK; p0$kz_deep_frac <- KB36_F_INIT; p0$hs_asx_frac <- KB36_ASX_INIT
deep_of <- function(kz) { q <- p0; q$kz <- kz
  sp <- tryCatch(ccx_spinup(q), error = function(e) NULL); if (is.null(sp)) NA_real_ else sp$diagnostics$d14c_bottom_box }
cat(sprintf("\n=== kz BRACKET ON THE 36-BOX STRUCTURE: f %.3f, hs_asx %.2f, z_K %g, attach %d; target %.2f +/- %.2f ===\n",
            KB36_F_INIT, KB36_ASX_INIT, KB36_ZK, KB36_ATTACH, tg$target, tg$sd))
mono <- vapply(KB36_GRID, deep_of, 0)
cat(sprintf("  kz    %s\n  d14C  %s\n", paste(sprintf("%8.0f", KB36_GRID), collapse = ""), paste(sprintf("%8.1f", mono), collapse = "")))
if (any(!is.finite(mono)) || any(diff(mono) <= 0)) stop("GATE FAILED: kz -> bottom box is not strictly increasing on the grid; bisection is meaningless")
cat("  GATE PASSED: strictly increasing.\n")
solve_kz <- function(target) { lo <- KB36_SEARCH[1]; hi <- KB36_SEARCH[2]
  g <- function(k) deep_of(k) - target; glo <- g(lo); ghi <- g(hi)
  if (!is.finite(glo) || !is.finite(ghi) || glo * ghi > 0) return(NA_real_)
  while (hi - lo > KB36_TOL) { mid <- 0.5 * (lo + hi); gm <- g(mid); if (!is.finite(gm)) return(NA_real_)
    if (glo * gm <= 0) { hi <- mid; ghi <- gm } else { lo <- mid; glo <- gm } }
  0.5 * (lo + hi) }
res <- do.call(rbind, lapply(KB36_SIGMAS, function(k) data.frame(k = k, d14_lo = tg$target - k * tg$sd, d14_hi = tg$target + k * tg$sd,
                                                                  kz_lo = solve_kz(tg$target - k * tg$sd), kz_hi = solve_kz(tg$target + k * tg$sd))))
cat(sprintf("\n  %4s %22s %22s\n", "k", "target +/- k sigma", "-> kz bracket"))
for (i in seq_len(nrow(res))) cat(sprintf("  %4d   [%8.2f, %8.2f]   [%8.1f, %8.1f]\n", res$k[i], res$d14_lo[i], res$d14_hi[i], res$kz_lo[i], res$kz_hi[i]))
cat(sprintf("\n  shipped column bracket [%.1f, %.1f]; the 09-06c working arm sits at kz %.0f (f 0.049)\n", CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi, ccx_default_params()$kz))
cat("  ⚠ Nothing adopted by this script; the k = 3 box goes into R/calibrate.R by hand.\n")
saveRDS(list(res = res, grid = KB36_GRID, mono = mono, p0 = p0, target = tg), KB36_OUT); cat(sprintf("  saved %s\n", KB36_OUT))
