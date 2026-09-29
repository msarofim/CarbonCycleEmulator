# =====================================================================
# diag_enso_index_price.R -- price the three ENSO indices at the phi = 0 +
# shape-prior mode, BEFORE choosing one for a Torch refit.
#
# WHY (CHANGELOG 2026-09-29 d, item 3; Marcus 2026-09-29): the shipped index is
# demeaned but not detrended (+0.0082 degC/yr), so gamma_enso_land carries a
# land source that rises through the record and vanishes in every projection --
# the phi pattern. Marcus ruled: start from phi = 0 + shape prior (hilda_csl3v0k),
# build BOTH detrend routes as values of ccx_build_forcing(enso_index =), price
# each here, then pick one for Torch.
#
# PROTOCOL, per index (CCX_ENSO_INDEX_CODES):
#   U  unrefitted: the mode vector, only the index swapped.
#   E  the ENSO coordinates re-optimised (EP_ENSO). This ranks INDEX, not
#      AMPLITUDE -- the 09-02 bake-off's rule; relsst_lp is a different
#      product's Nino 3.4 with 9 % more amplitude, so U alone would mis-rank it.
#   B  EP_ENSO + the q10 ridge + the net-sink setters (EP_BROAD) re-optimised: a
#      PREVIEW of where the refit goes, q10 above all. An UPPER BOUND on a full
#      refit's cost; Nelder-Mead, not converged by construction at EP_NM_MAXIT.
# Futures at each B point: vvH / vvL, GCB spliced (the app's splice).
# ⚠ A SCREEN, NOT A FIT. Nothing is registered or adopted.
#
# USAGE: Rscript calibration/diag_enso_index_price.R   (~30 min, BLAS pinned)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

EP_MODE <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
EP_MODE_TAG  <- "hilda_csl3v0k basin 1 (scratch mode, 09-28 c)"
EP_INDICES   <- names(CCX_ENSO_INDEX_CODES)
EP_ENSO      <- c("gamma_enso_land_NH", "gamma_enso_land_SH", "w_enso_l2")
EP_BROAD     <- c(EP_ENSO, "q10", "seas_T_amp_NH", "seas_T_amp_SH", "beta_max", "fert_k", "kz")
EP_NM_MAXIT  <- c(E = 400L, B = 1200L)
EP_SCEN      <- c("vvH", "vvL")
EP_YEARS     <- c(2100L, 2300L)
EP_END_YEAR  <- 2300L
EP_TAG       <- format(Sys.Date(), "%Y%m%d")
EP_OUT       <- ccx_path("outputs", "diagnostics", sprintf("enso_index_price_%s", EP_TAG))

md <- readRDS(ccx_mode_file(EP_MODE))
invisible(ccx_apply_pins(md$pins))
make_bp <- function(idx) {
  bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, md$struct, as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
  if (idx != "demean") bp$enso_index <- CCX_ENSO_INDEX_CODES[[idx]]
  bp
}
ie <- match(EP_ENSO, md$param_names); ib <- match(EP_BROAD, md$param_names)
stopifnot(!anyNA(ie), !anyNA(ib))
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
spliced <- function(s) { e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
futures <- function(u, idx) {
  m2 <- md; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  if (idx != "demean") p$enso_index <- CCX_ENSO_INDEX_CODES[[idx]]
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  unlist(lapply(EP_SCEN, function(s) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, EP_END_YEAR), emissions = spliced(s),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))$out
    co2 <- tapply((r$co2_NH + r$co2_SH) / 2, floor(r$t), mean)
    setNames(as.numeric(co2[as.character(EP_YEARS)]), paste0(s, "_", EP_YEARS))
  }))
}
nm_fit <- function(lp, idx_cols, maxit) {
  f <- function(x) { u <- md$u_mode; u[idx_cols] <- x; v <- lp(u); if (!is.finite(v)) 1e12 else -v }
  o <- stats::optim(md$u_mode[idx_cols], f, method = "Nelder-Mead", control = list(maxit = maxit))
  u <- md$u_mode; u[idx_cols] <- o$par
  list(u = u, lp = -o$value, evals = o$counts[["function"]], conv = o$convergence)
}

sink(paste0(EP_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE ===\n  driver calibration/diag_enso_index_price.R, commit %s, run %s\n",
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"),
            format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  mode %s\n    %s\n  stored logpost %.4f | spinup %s | BLAS threads pinned via env\n",
            EP_MODE_TAG, EP_MODE, md$logpost, ccx_mode_spinup(md)))
cat(sprintf("  E re-optimises {%s}; B re-optimises {%s}; Nelder-Mead maxit E %d, B %d\n",
            paste(EP_ENSO, collapse = ", "), paste(EP_BROAD, collapse = ", "), EP_NM_MAXIT[["E"]], EP_NM_MAXIT[["B"]]))
cat(sprintf("  futures: %s, GCB spliced, coupled, 1750-%d; units ppm (global mean); logpost in log units\n\n",
            paste(EP_SCEN, collapse = ", "), EP_END_YEAR))

f0 <- NULL; rows <- list()
for (idx in EP_INDICES) {
  lp <- ccx_make_logpost(base_params = make_bp(idx))
  lu <- lp(md$u_mode)
  if (idx == "demean") {
    # IDENTITY GATE: the default index reproduces the stored mode exactly
    stopifnot(abs(lu - md$logpost) < 1e-6)
    cat(sprintf("  [gate] demean reproduces the stored logpost: %.6f vs %.6f\n", lu, md$logpost))
  }
  E <- nm_fit(lp, ie, EP_NM_MAXIT[["E"]])
  B <- nm_fit(lp, ib, EP_NM_MAXIT[["B"]])
  fB <- futures(B$u, idx); if (is.null(f0)) f0 <- futures(md$u_mode, "demean")
  pB <- ccx_unc_to_par(B$u); pE <- ccx_unc_to_par(E$u)
  rows[[idx]] <- data.frame(index = idx,
    d_U = lu - md$logpost, d_E = E$lp - md$logpost, d_B = B$lp - md$logpost,
    E_evals = E$evals, E_conv = E$conv, B_evals = B$evals, B_conv = B$conv,
    t(setNames(pE[EP_ENSO], paste0("E_", EP_ENSO))),
    t(setNames(pB[EP_BROAD], paste0("B_", EP_BROAD))),
    t(fB), t(setNames(fB - f0, paste0("d_", names(fB)))), check.names = FALSE)
  cat(sprintf("  %-9s U %+8.2f | E %+8.2f (%d evals, conv %d) | B %+8.2f (%d evals, conv %d) | B q10 %.3f beta_max %.3f fert_k %.0f\n",
              idx, lu - md$logpost, E$lp - md$logpost, E$evals, E$conv, B$lp - md$logpost, B$evals, B$conv,
              pB[["q10"]], pB[["beta_max"]], pB[["fert_k"]]))
}
R <- do.call(rbind, rows); rownames(R) <- NULL
cat(sprintf("\n=== MODE VECTOR (demean, no re-optimisation) futures: %s ===\n",
            paste(sprintf("%s %.1f", names(f0), f0), collapse = ", ")))
cat("\n=== FULL TABLE (d_* logpost vs the stored mode; d_vv* ppm vs the mode vector's futures) ===\n")
print(R, digits = 4, row.names = FALSE)
cat("\n  NOTE: B is an upper bound on a full refit's cost; the Torch refit is the measurement.\n")
utils::write.csv(R, paste0(EP_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", EP_OUT))
sink()
