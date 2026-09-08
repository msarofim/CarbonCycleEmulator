# =====================================================================
# T-hml (handoff 2026-09-08g §1): a 1-D log-posterior PROFILE in h_ml at the
# canonical hilda31 -- every other parameter HELD at the mode (a slice, not a
# profile likelihood).
#
# WHAT IT DECIDES. The Hessian at hilda31 found h_ml STEP-UNSTABLE (12.5 %
# disagreement between neighbouring steps vs the 2 % tolerance; ent26 1.2 %):
# its curvature reads -53.5 per u^2 at steps <= 3e-2, -57.7 at 3e-2, -87 at
# 0.1 and -38 at 0.3 (outputs/diagnostics/recompute_hessian_hilda31_20260908.log).
# The C1 remap (2026-08-29k) removed the h_ml kinks; post-adoption they must
# stay gone. A KINK is a jump in the FIRST derivative: on a fine grid it shows
# as an isolated spike in the second difference. A smooth but strongly
# non-quadratic slice gives the same eps-scan pattern WITHOUT a kink.
#
# PRE-REGISTERED: smooth, no kink. FALSIFIED IF: a kink -- then `hml_kinks`
# is wrong and the posterior route is blocked.
#
# GRID. The handoff's +/- 20 m at 2 m, PLUS an inner +/- 6 m at 0.25 m (an
# ADDITION, stated: the eps scan's instability sits at u-steps 0.1-0.3, which
# is 1.7-5 m in natural units, so the 2 m grid alone would straddle it with a
# handful of points). Kink criterion: |second difference| > TH_KINK_RATIO x
# the grid's median |second difference|, on the fine grid.
# Usage: Rscript calibration/diag_thml_profile.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

TH_COARSE_HALF <- 20; TH_COARSE_STEP <- 2
TH_FINE_HALF   <- 6;  TH_FINE_STEP   <- 0.25
TH_KINK_RATIO  <- 3
TH_EPS_U       <- c(1e-3, 3e-3, 1e-2, 3e-2, 1e-1, 3e-1)   # the Hessian's own eps grid, reproduced by central differences
TH_OUT <- ccx_path("outputs", "diagnostics", sprintf("thml_profile_%s.rds", format(Sys.Date(), "%Y%m%d")))

md <- readRDS(ccx_mode_file()); nm <- md$param_names
ccx_require_param_set(md, "diag_thml_profile.R")
# the band the mode was FOUND under -- only when it differs from the shipped one (recompute_hessian.R, 2026-09-08f)
if (!is.null(md$hml_bound) && !isTRUE(all.equal(md$hml_bound, c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)))) {
  CCX_PARAM_TABLE$h_ml$lo <- md$hml_bound[1]; CCX_PARAM_TABLE$h_ml$hi <- md$hml_bound[2]; CCX_PARAM_TABLE$h_ml$init <- mean(md$hml_bound)
  CCX_PARAM_TABLE$h_ml$prior <- local({ b <- md$hml_bound; function(x) stats::dunif(x, b[1], b[2], log = TRUE) })
}
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(base_params = bp)
u  <- ccx_par_to_unc(md$par_mode); lp0 <- lp(u)
cat(sprintf("GATE: the stored mode reproduces: log-post %.6f file %.6f diff %.3e\n", lp0, md$logpost, lp0 - md$logpost))
stopifnot(abs(lp0 - md$logpost) < 1e-6)
spec <- CCX_PARAM_TABLE$h_ml; i <- match("h_ml", nm); h0 <- md$par_mode$h_ml
cat(sprintf("h_ml at the mode %.3f m (u %.4f), band [%g, %g], transform %s; prior lognormal (median %.1f)\n", h0, u[[i]], spec$lo, spec$hi, spec$tr, exp(mean(log(c(59.7, 118))))))

lp_at_h <- function(h) { u2 <- u; u2[[i]] <- .to_unc(h, spec); lp(u2) }
grid_of <- function(half, step) { g <- h0 + seq(-half, half, by = step); g[g > spec$lo & g < spec$hi] }
t0 <- Sys.time()
coarse <- grid_of(TH_COARSE_HALF, TH_COARSE_STEP); lc <- vapply(coarse, lp_at_h, numeric(1))
fine   <- grid_of(TH_FINE_HALF, TH_FINE_STEP);     lf <- vapply(fine, lp_at_h, numeric(1))
cat(sprintf("%d + %d evaluations in %.0f s\n", length(coarse), length(fine), as.numeric(Sys.time() - t0, units = "secs")))

cat(sprintf("\n=== 1. COARSE SLICE, +/- %g m at %g m (log-post minus the mode's) ===\n", TH_COARSE_HALF, TH_COARSE_STEP))
for (k in seq_along(coarse)) cat(sprintf("  h_ml %7.2f  %+9.3f%s\n", coarse[k], lc[k] - lp0, if (abs(coarse[k] - h0) < 1e-9) "  <- mode" else ""))
imax <- which.max(c(lc, lf)); hmax <- c(coarse, fine)[imax]
cat(sprintf("  argmax on the union grid: h_ml %.2f (mode %.3f; %+.3f log-units above the mode)\n", hmax, h0, max(c(lc, lf)) - lp0))

cat(sprintf("\n=== 2. FINE SLICE, +/- %g m at %g m: value, first and second differences (per m, per m^2) ===\n", TH_FINE_HALF, TH_FINE_STEP))
d1 <- diff(lf) / TH_FINE_STEP; d2 <- diff(lf, differences = 2) / TH_FINE_STEP^2
med2 <- stats::median(abs(d2)); spike <- abs(d2) > TH_KINK_RATIO * med2
for (k in seq_along(fine)) cat(sprintf("  h_ml %7.2f  %+9.4f  %s  %s%s\n", fine[k], lf[k] - lp0,
  if (k < length(fine)) sprintf("d1 %+8.4f", d1[k]) else "           ", if (k > 1 && k < length(fine)) sprintf("d2 %+8.4f", d2[k - 1]) else "", if (k > 1 && k < length(fine) && spike[k - 1]) "  <-- SPIKE" else ""))
cat(sprintf("  second difference: median |d2| %.4f, range [%+.4f, %+.4f], %d point(s) above %g x the median\n", med2, min(d2), max(d2), sum(spike), TH_KINK_RATIO))

cat("\n=== 3. THE HESSIAN'S OWN EPS SCAN, reproduced (central second difference in u at the mode) ===\n")
du_dh <- (.from_unc(u[[i]] + 1e-6, spec) - .from_unc(u[[i]] - 1e-6, spec)) / 2e-6
curv_u <- vapply(TH_EPS_U, function(e) { u2 <- u; u2[[i]] <- u[[i]] + e; u3 <- u; u3[[i]] <- u[[i]] - e; (lp(u2) - 2 * lp0 + lp(u3)) / e^2 }, numeric(1))
for (k in seq_along(TH_EPS_U)) cat(sprintf("  eps %5.0e (reach %+.3f m / %+.3f m): d2/du2 %+9.3f   (Hessian log: -53.5 at <= 3e-2, -57.7, -87.1, -37.8 at 3e-2, 1e-1, 3e-1)\n", TH_EPS_U[k],
  .from_unc(u[[i]] + TH_EPS_U[k], spec) - h0, .from_unc(u[[i]] - TH_EPS_U[k], spec) - h0, curv_u[k]))
d2h_mode <- d2[which.min(abs(fine[-c(1, length(fine))] - h0))]
cat(sprintf("  fine-grid second difference at the mode %+.4f per m^2 = %+.2f per u^2 (x (dh/du)^2, dh/du = %.3f)\n", d2h_mode, d2h_mode * du_dh^2, du_dh))

cat("\n=== 4. VERDICT ===\n")
kink <- any(spike)
cat(sprintf("  prediction 'smooth, no kink': %s\n", if (!kink) "CONFIRMED -- no isolated spike in the second difference on the 0.25 m grid" else sprintf("FALSIFIED -- spike(s) at h_ml %s", paste(sprintf("%.2f", fine[-c(1, length(fine))][spike]), collapse = ", "))))
cat(sprintf("  the eps-scan instability is %s\n", if (!kink && (max(curv_u) - min(curv_u)) / abs(stats::median(curv_u)) > 0.1) "a smooth but NON-QUADRATIC slice (the central difference at eps 0.1-0.3 in u, 1.7-5 m, mixes the higher derivatives), not a kink" else if (kink) "a kink" else "not reproduced here"))
saveRDS(list(coarse = data.frame(h_ml = coarse, lp = lc), fine = data.frame(h_ml = fine, lp = lf), d2 = d2, spike = spike, eps = TH_EPS_U, curv_u = curv_u, lp0 = lp0, h0 = h0, du_dh = du_dh, kink = kink, consts = list(kink_ratio = TH_KINK_RATIO), mode = CCX_MODE_CANONICAL, date = Sys.time()), TH_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TH_OUT))
