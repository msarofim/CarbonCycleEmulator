# =====================================================================
# T-hml follow-up (2026-09-08g): WHERE does the h_ml slice's feature come from?
# diag_thml_profile.R found a ~1.5 m wide feature at h_ml 49.9-51.2 m (0.75-2 m
# above the 49.15 mode), on the GLODAP profile's 50 m bin edge -- the place the
# C1 remap (2026-08-29k) acted. Suspicious uniformity of place = a code path
# until disproven. Three arms on the SAME fine grid: the pump SHAPE frozen at
# the mode's grid, the integrator's SUBSTEP count frozen at the mode's, both.
# Whichever arm removes the feature names the path. Nothing is adopted.
# Usage: Rscript calibration/diag_thml_kink_source.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
TK_FINE_HALF <- 4; TK_FINE_STEP <- 0.25; TK_KINK_RATIO <- 3
TK_OUT <- ccx_path("outputs", "diagnostics", sprintf("thml_kink_source_%s.rds", format(Sys.Date(), "%Y%m%d")))

md <- readRDS(ccx_mode_file()); nm <- md$param_names; ccx_require_param_set(md, "diag_thml_kink_source.R")
if (!is.null(md$hml_bound) && !isTRUE(all.equal(md$hml_bound, c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)))) {
  CCX_PARAM_TABLE$h_ml$lo <- md$hml_bound[1]; CCX_PARAM_TABLE$h_ml$hi <- md$hml_bound[2]; CCX_PARAM_TABLE$h_ml$init <- mean(md$hml_bound)
  CCX_PARAM_TABLE$h_ml$prior <- local({ b <- md$hml_bound; function(x) stats::dunif(x, b[1], b[2], log = TRUE) }) }
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(base_params = bp); u <- ccx_par_to_unc(md$par_mode); lp0 <- lp(u)
stopifnot(abs(lp0 - md$logpost) < 1e-6)
spec <- CCX_PARAM_TABLE$h_ml; i <- match("h_ml", nm); h0 <- md$par_mode$h_ml
p_mode <- ccx_overlay_par(bp, md$par_mode)
fine <- h0 + seq(-TK_FINE_HALF, TK_FINE_HALF, by = TK_FINE_STEP)

cat("=== 1. What changes with h_ml on the fine grid: the substep count and the first three layer-mean shape values ===\n")
sub_of <- function(h) ccx_substeps_for(p_mode, ccx_ocean_grid(h))
.shape0 <- ccx_pump_shape
for (h in fine) { g <- ccx_ocean_grid(h); sh <- .shape0(g)
  cat(sprintf("  h_ml %6.2f  substeps %3d  shape L1 %.5f L2 %.5f L3 %.5f  (layer 1 = %.2f-%.2f m)\n", h, sub_of(h), sh[2], sh[3], sh[4], g$dz[1], g$dz[1] + g$dz[2])) }
sub0 <- sub_of(h0); sh0 <- .shape0(ccx_ocean_grid(h0))

lp_at_h <- function(h) { u2 <- u; u2[[i]] <- .to_unc(h, spec); lp(u2) }
arms <- list(
  baseline      = function() NULL,
  shape_frozen  = function() { ccx_pump_shape <<- function(grid) sh0 },
  substeps_frozen = function() { ccx_substeps_for <<- function(p, grid, dt = 1 / 12) sub0 },
  both_frozen   = function() { ccx_pump_shape <<- function(grid) sh0; ccx_substeps_for <<- function(p, grid, dt = 1 / 12) sub0 })
.sub_orig <- ccx_substeps_for
RES <- list()
for (a in names(arms)) {
  ccx_pump_shape <- .shape0; ccx_substeps_for <- .sub_orig; arms[[a]]()
  l <- vapply(fine, lp_at_h, numeric(1)); d2 <- diff(l, differences = 2) / TK_FINE_STEP^2
  med <- stats::median(abs(d2)); sp <- abs(d2) > TK_KINK_RATIO * med
  RES[[a]] <- list(lp = l, d2 = d2, spike = sp, lp_mode = lp_at_h(h0))
}
ccx_pump_shape <- .shape0; ccx_substeps_for <- .sub_orig
cat("\n=== 2. THE SLICE by arm (log-post minus the arm's OWN value at the mode; d2 per m^2) ===\n")
cat(sprintf("  %7s", "h_ml")); for (a in names(arms)) cat(sprintf(" | %9s %8s", a, "d2")); cat("\n")
for (k in seq_along(fine)) { cat(sprintf("  %7.2f", fine[k]))
  for (a in names(arms)) cat(sprintf(" | %+9.4f %s", RES[[a]]$lp[k] - RES[[a]]$lp_mode, if (k > 1 && k < length(fine)) sprintf("%+8.4f%s", RES[[a]]$d2[k - 1], if (RES[[a]]$spike[k - 1]) "*" else " ") else "         ")); cat("\n") }
cat("\n=== 3. VERDICT ===\n")
for (a in names(arms)) cat(sprintf("  %-16s mode value %.4f (baseline %+.4f); spikes %d; d2 range [%+.3f, %+.3f]\n", a, RES[[a]]$lp_mode, RES[[a]]$lp_mode - lp0, sum(RES[[a]]$spike), min(RES[[a]]$d2), max(RES[[a]]$d2)))
src <- if (!any(RES$shape_frozen$spike) && any(RES$baseline$spike)) "THE PUMP SHAPE (ccx_pump_shape's layer means on the GLODAP bins)" else if (!any(RES$substeps_frozen$spike) && any(RES$baseline$spike)) "THE SUBSTEP COUNT (ccx_substeps_for)" else if (!any(RES$both_frozen$spike) && any(RES$baseline$spike)) "BOTH together" else "NEITHER -- look elsewhere (grid geometry, K(z), the shim)"
cat(sprintf("  the feature is removed by freezing: %s\n", src))
saveRDS(list(fine = fine, arms = RES, sub0 = sub0, sh0 = sh0, h0 = h0, lp0 = lp0, date = Sys.time()), TK_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TK_OUT))
