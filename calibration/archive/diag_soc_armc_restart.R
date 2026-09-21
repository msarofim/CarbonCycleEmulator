# ⛔ ARCHIVED 2026-09-21 (f) -- PROVENANCE ONLY, WILL NOT RUN AT HEAD. This harness ran at 206e3f0 (and earlier);
# the structural names it sets (w_gthc / k_gthc / kn_gthc, u_hs_fac_SH / tau_q_fac_SH / pump_hs_fac_SH / h_ml_fac_NH,
# k_w_fac_SH / k_w_fac_hs, w_soc / k_soc_up / k_soc_dn / hs_h_fac_SH) were PRUNED from both cores in the 09-21 (f)
# commit (CHANGELOG 09-21 f: the loop refuted as a class, the scans refuted, the window parked). Its outputs are in
# outputs/diagnostics/ under the names in its header. To re-run: `git checkout 206e3f0` (a worktree), not this tree.
# Sourced from calibration/ at the time; the relative paths below assume the repo root as cwd.
# Restart test: arm C at W = 0 STARTED FROM the W 5 (8,10) optimum -- is the +33.5 a window effect or an optimiser basin?
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp()
x <- readRDS("outputs/diagnostics/soc_martin_probe_20260921.rds")
md <- readRDS(ccx_mode_file()); pins <- ccx_mode_pins(md); rm <- ccx_apply_pins(pins)
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode; for (n in names(pins)) bp[[n]] <- pins[[n]]
bp$pump_field <- "martin"; bp$w_gthc <- 0; bp$k_soc_up <- 8L; bp$k_soc_dn <- 10L; bp$hs_h_fac_SH <- 1
ref_st <- x$ref_st; ARMC <- x$armc; idx <- match(ARMC, CCX_PARAM_NAMES)
run <- function(W, pm_start, lab) {
  b <- bp; b$w_soc <- W
  lp <- ccx_make_logpost(base_params = b, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  u <- ccx_par_to_unc(pm_start[setdiff(names(pm_start), names(pins))])
  fobj <- function(z) { uu <- u; uu[idx] <- z; v <- -as.numeric(lp(uu)); if (!is.finite(v)) 1e10 else v }
  v0 <- lp(u); cm <- intersect(names(attr(v0, "streams")), names(ref_st))
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = 1500, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = 100, reltol = 1e-12))
  best <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- best$par; v <- lp(uu); st <- attr(v, "streams")
  d <- st[cm] - ref_st[cm]
  cat(sprintf("%s: start dlik %+.1f -> %+.1f (%d evals); kz_deep_frac %.4f h_ml %.1f u_hs %.1f h_hs %.0f; d14prof %+.1f co2 %+.1f\n", lab,
              sum(attr(v0, "streams")[cm] - ref_st[cm]), sum(d), o1$counts[1] + o2$counts[1],
              ccx_unc_to_par(uu)$kz_deep_frac, ccx_unc_to_par(uu)$h_ml, ccx_unc_to_par(uu)$u_hs, ccx_unc_to_par(uu)$h_hs,
              sum(d[grep("^d14c_(profile|deep)", cm)]), sum(d[grep("^co2", cm)])))
  ccx_unc_to_par(uu)
}
pm5 <- x$S2[[2]]$pm; pm0 <- x$S2[[1]]$pm
cat("stored: W0 armC", x$S2[[1]]$dlik, " W5 (8,10) armC", x$S2[[2]]$dlik, "\n")
a <- run(0, pm5, "W0 from the W5 optimum")
b <- run(5, pm0, "W5 from the W0 optimum")
ccx_unpin_params(rm)
