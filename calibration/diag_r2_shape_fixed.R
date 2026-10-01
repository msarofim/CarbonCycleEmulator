# =====================================================================
# diag_r2_shape_fixed.R -- IS R2's LEVERAGE ON THE FUTURE ALL THROUGH THE
# FERTILISATION SHAPE? (CHANGELOG 2026-09-30 g; notes/r2_explained_2026-09-30.md §5)
# The phi = 0 rep_dC ladder is a pure fert-SHAPE path (enh(410) fixed, K falls
# 865 -> 644 at the measured 0.776). HYPOTHESIS (pre-registered in the note):
# with (beta_max, fert_k) held at the control's values, pinning rep_dC at the
# measured offset moves SSP5-8.5 2300 CO2 by little; with them free it moves it
# by tens of ppm (the ladder's +63 at rep_dC 1.0).
# Rows, on arm A's fixed-stock tau-500 control (the fert profile's control):
#   R_shape_fixed  rep_dC = RS_R, beta_max and fert_k = control -> 8 names rebalanced
#   R_free         rep_dC = RS_R only                           -> 10 names rebalanced
# Reported: d_loglik (record), the rebalanced names, SSP5-8.5 2300 CO2 and vs
# control. PASS for the hypothesis: |dCO2(R_shape_fixed)| < RS_FRAC x |dCO2(R_free)|.
# ⚠ A SCREEN: NM, costs upper bounds. No RNG.
# USAGE: Rscript calibration/diag_r2_shape_fixed.R  (frozen copy; BLAS pinned)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
RS_DRIVER <- "calibration/diag_r2_shape_fixed.R"
RS_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
RS_STRUCT <- "hilda_csl3v0ka"
RS_CTRL_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_20260929.rds")
RS_CTRL_VALUE   <- 500
RS_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
RS_FREE11 <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
RS_R      <- 0.776                   # the measured station-vs-hemisphere offset (NOAA MBL zonal)
RS_ROWS   <- list(R_shape_fixed = c("rep_dC", "beta_max", "fert_k"), R_free = "rep_dC")
RS_FRAC   <- 0.25                    # hypothesis threshold, stated before the run
RS_MAXIT  <- 3000L
RS_ID_TOL <- 1e-4
RS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("r2_shape_fixed_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT    <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(RS_MODE)); invisible(ccx_apply_pins(md$pins))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, RS_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
cp <- readRDS(RS_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == RS_CTRL_VALUE)]]
for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]
prev <- utils::read.csv(RS_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in RS_FREE11) p0[[n]] <- r1[[n]]
for (n in RS_FREE11) p0[[n]] <- ctrl$par[[n]]
u_ctrl <- ccx_par_to_unc(unlist(p0)[md$param_names])
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
l_ctrl <- lp(u_ctrl); id_d <- as.numeric(l_ctrl) - ctrl$opt; stopifnot(abs(id_d) < RS_ID_TOL)

co2_2300 <- function(u) {
  pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(bp, pv); sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  r <- suppressWarnings(ccx_run_coupled(sp, "ssp585", c(1750L, 2300L), bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale))$out
  co2 <- tapply((r$co2_NH + r$co2_SH) / 2, floor(r$t), mean); co2[["2300"]]
}
one <- function(nm) {
  pins <- RS_ROWS[[nm]]; pv0 <- as.list(ccx_unc_to_par(u_ctrl)); pv0$rep_dC <- RS_R
  u0 <- ccx_par_to_unc(unlist(pv0)[md$param_names])
  iF <- match(setdiff(RS_FREE11, pins), md$param_names)
  f <- function(x) { u <- u0; u[iF] <- x; w <- lp(u); if (!is.finite(w)) 1e12 else -as.numeric(w) }
  o <- stats::optim(u0[iF], f, method = "Nelder-Mead", control = list(maxit = RS_MAXIT))
  u <- u0; u[iF] <- o$par; l1 <- lp(u)
  list(row = nm, pins = pins, u = u, d_ll = as.numeric(attr(l1, "loglik")) - as.numeric(attr(l_ctrl, "loglik")),
       streams = attr(l1, "streams") - attr(l_ctrl, "streams"), conv = o$convergence, evals = o$counts[["function"]],
       par = unlist(ccx_unc_to_par(u)[RS_FREE11]), co2_2300 = co2_2300(u))
}
res <- parallel::mclapply(names(RS_ROWS), one, mc.cores = length(RS_ROWS), mc.preschedule = FALSE)
bad <- vapply(res, inherits, logical(1), "try-error"); if (any(bad)) { print(res[bad]); stop("fork failure") }
c_ctrl <- co2_2300(u_ctrl)
d <- setNames(vapply(res, function(r) r$co2_2300 - c_ctrl, 0), vapply(res, `[[`, "", "row"))

sink(paste0(RS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === %s @%s, run %s; %s v0k basin1 + fixed-stock tau-500 control (identity %.1e); rep_dC pinned %.3f; NM %d; no RNG\n",
            RS_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), RS_STRUCT, id_d, RS_R, RS_MAXIT))
cat(sprintf("  control: SSP5-8.5 2300 CO2 %.2f ppm; beta_max %.3f fert_k %.1f rep_dC %.3f\n", c_ctrl, ctrl$par[["beta_max"]], ctrl$par[["fert_k"]], ctrl$par[["rep_dC"]]))
for (r in res) cat(sprintf("  %-14s pinned {%s}: d_loglik %+8.2f  beta_max %.3f fert_k %6.1f  SSP5-8.5 2300 %.2f (%+.2f ppm)  conv %d evals %d\n",
  r$row, paste(r$pins, collapse = ","), r$d_ll, r$par[["beta_max"]], r$par[["fert_k"]], r$co2_2300, r$co2_2300 - c_ctrl, r$conv, r$evals))
ok <- abs(d[["R_shape_fixed"]]) < RS_FRAC * abs(d[["R_free"]])
cat(sprintf("  HYPOTHESIS |dCO2(shape fixed)| < %.2f x |dCO2(free)|: %.2f vs %.2f -> %s\n", RS_FRAC, abs(d[["R_shape_fixed"]]),
            RS_FRAC * abs(d[["R_free"]]), if (ok) "HOLDS" else "FAILS"))
cat("  streams vs control (8 largest):\n")
S <- do.call(rbind, lapply(res, `[[`, "streams")); rownames(S) <- names(RS_ROWS)
print(round(S[, names(sort(apply(abs(S), 2, max), decreasing = TRUE))[1:8], drop = FALSE], 2))
sink()
saveRDS(list(control = list(u = u_ctrl, co2_2300 = c_ctrl), rows = res), paste0(RS_OUT, ".rds"))
