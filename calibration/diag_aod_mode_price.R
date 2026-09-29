# =====================================================================
# diag_aod_mode_price.R -- price the AOD-background fix (aod_mode = "anomaly")
# at the phi = 0 + shape-prior mode (Marcus 2026-09-29: "apply any obvious
# fixes like the AOD background"). The fix is a switch whose default ("legacy")
# is bit-identical, so objective #13 and the registered modes are untouched;
# this measures what turning it on costs and moves.
#
# PROTOCOL, the audit screen's (CHANGELOG 09-29 e): U unrefitted; B beta_max,
# fert_k, kz re-optimised (the net-sink setters -- gamma_diff is not fitted).
# Futures vvH / vvL, GCB spliced. ⚠ A SCREEN; nothing registered or adopted.
#
# USAGE: Rscript calibration/diag_aod_mode_price.R   (~10 min, BLAS pinned)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

AP_MODE <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
AP_MODE_TAG  <- "hilda_csl3v0k basin 1 (scratch mode, 09-28 c)"
AP_INDICES   <- names(CCX_AOD_MODE_CODES)
AP_BROAD     <- c("beta_max", "fert_k", "kz")
AP_NM_MAXIT  <- c(B = 1200L)
AP_SCEN      <- c("vvH", "vvL")
AP_YEARS     <- c(2100L, 2300L)
AP_END_YEAR  <- 2300L
AP_TAG       <- format(Sys.Date(), "%Y%m%d")
AP_OUT       <- ccx_path("outputs", "diagnostics", sprintf("aod_mode_price_%s", AP_TAG))

md <- readRDS(ccx_mode_file(AP_MODE))
invisible(ccx_apply_pins(md$pins))
make_bp <- function(idx) {
  bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, md$struct, as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
  if (idx != "legacy") bp$aod_mode <- CCX_AOD_MODE_CODES[[idx]]
  bp
}
ib <- match(AP_BROAD, md$param_names)
stopifnot(!anyNA(ib))
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
spliced <- function(s) { e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
futures <- function(u, idx) {
  m2 <- md; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  if (idx != "legacy") p$aod_mode <- CCX_AOD_MODE_CODES[[idx]]
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  unlist(lapply(AP_SCEN, function(s) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, AP_END_YEAR), emissions = spliced(s),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))$out
    co2 <- tapply((r$co2_NH + r$co2_SH) / 2, floor(r$t), mean)
    setNames(as.numeric(co2[as.character(AP_YEARS)]), paste0(s, "_", AP_YEARS))
  }))
}
nm_fit <- function(lp, idx_cols, maxit) {
  f <- function(x) { u <- md$u_mode; u[idx_cols] <- x; v <- lp(u); if (!is.finite(v)) 1e12 else -v }
  o <- stats::optim(md$u_mode[idx_cols], f, method = "Nelder-Mead", control = list(maxit = maxit))
  u <- md$u_mode; u[idx_cols] <- o$par
  list(u = u, lp = -o$value, evals = o$counts[["function"]], conv = o$convergence)
}

sink(paste0(AP_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE ===\n  driver calibration/diag_aod_mode_price.R, commit %s, run %s\n",
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"),
            format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  mode %s\n    %s\n  stored logpost %.4f | spinup %s | BLAS threads pinned via env\n",
            AP_MODE_TAG, AP_MODE, md$logpost, ccx_mode_spinup(md)))
cat(sprintf("  B re-optimises {%s}; Nelder-Mead maxit %d; AOD e-fold (measured) %.3f yr; background window %d-%d\n",
            paste(AP_BROAD, collapse = ", "), AP_NM_MAXIT[["B"]], ccx_aod_efold_yr(), FORC_AOD_BG_WIN[1], FORC_AOD_BG_WIN[2]))
cat(sprintf("  futures: %s, GCB spliced, coupled, 1750-%d; units ppm (global mean); logpost in log units\n\n",
            paste(AP_SCEN, collapse = ", "), AP_END_YEAR))

f0 <- NULL; rows <- list()
for (idx in AP_INDICES) {
  lp <- ccx_make_logpost(base_params = make_bp(idx))
  lu <- lp(md$u_mode)
  if (idx == "legacy") {
    # IDENTITY GATE: the default index reproduces the stored mode exactly
    stopifnot(abs(lu - md$logpost) < 1e-6)
    cat(sprintf("  [gate] legacy reproduces the stored logpost: %.6f vs %.6f\n", lu, md$logpost))
  }
  B <- nm_fit(lp, ib, AP_NM_MAXIT[["B"]])
  fB <- futures(B$u, idx); if (is.null(f0)) f0 <- futures(md$u_mode, "legacy")
  fU <- futures(md$u_mode, idx)
  pB <- ccx_unc_to_par(B$u)
  rows[[idx]] <- data.frame(index = idx,
    d_U = lu - md$logpost, d_B = B$lp - md$logpost, B_evals = B$evals, B_conv = B$conv,
    # unlist: ccx_unc_to_par() returns a LIST, and a list column cannot be written
    t(setNames(unlist(pB[AP_BROAD]), paste0("B_", AP_BROAD))),
    t(fB), t(setNames(fU - f0, paste0("dU_", names(fB)))), t(setNames(fB - f0, paste0("dB_", names(fB)))), check.names = FALSE)
  cat(sprintf("  %-8s U %+8.3f | B %+8.3f (%d evals, conv %d) | B beta_max %.4f fert_k %.1f | vvH 2300 U %+.2f B %+.2f ppm\n",
              idx, lu - md$logpost, B$lp - md$logpost, B$evals, B$conv,
              pB[["beta_max"]], pB[["fert_k"]], fU[["vvH_2300"]] - f0[["vvH_2300"]], fB[["vvH_2300"]] - f0[["vvH_2300"]]))
}
R <- do.call(rbind, rows); rownames(R) <- NULL
cat(sprintf("\n=== MODE VECTOR (legacy, no re-optimisation) futures: %s ===\n",
            paste(sprintf("%s %.1f", names(f0), f0), collapse = ", ")))
cat("\n=== FULL TABLE (d_* logpost vs the stored mode; d_vv* ppm vs the mode vector's futures) ===\n")
print(R, digits = 4, row.names = FALSE)
cat("\n  NOTE: B is an upper bound on a full refit's cost; the Torch refit is the measurement.\n")
utils::write.csv(R, paste0(AP_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", AP_OUT))
sink()
