# =====================================================================
# diag_npp_row_power.R -- does the modern-NPP row (arm B1, "hilda_csl3v0kan")
# have the POWER to move anything, before it goes to Torch?
# WHY: at sigma 7.76 the row prices the model's 70.0 at only ~1.6 log units
# below its centre (56.06), while the audit screen priced NPP0 x0.8 at ~-297
# through the seasonal record. [[no_power_null]]: measure the power first.
# PROTOCOL: at the v0k basin-1 vector, re-optimise PW_FREE under arm A and under
# arm B1 (same start, same budget) and compare modern NPP, the free names, and
# the row. A B1-minus-A shift in NPP of << sigma says the row is decorative at
# this width. A SCREEN, Nelder-Mead; nothing registered.
# USAGE: Rscript calibration/diag_npp_row_power.R  (~20 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
PW_MODE <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
PW_ARMS  <- c(A = "hilda_csl3v0ka", B1 = "hilda_csl3v0kan")
PW_FREE  <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH", "kz")
PW_MAXIT <- 2000L
PW_OUT   <- ccx_path("outputs", "diagnostics", sprintf("npp_row_power_%s", format(Sys.Date(), "%Y%m%d")))
md <- readRDS(ccx_mode_file(PW_MODE)); invisible(ccx_apply_pins(md$pins))
tg <- ccx_npp_modern_target()
iF <- match(PW_FREE, md$param_names); stopifnot(!anyNA(iF))
# the mode's OWN base (ccx_mode_base, per the mode-struct lint), then the arm's structure on top
bp_of <- function(struct) { bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, struct, as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]; bp }
npp_modern <- function(u, bp) {
  pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(bp, pv)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  n <- ccx_run_fast(sp, F)$npp; k <- floor(n$t) >= tg$win[1] & floor(n$t) <= tg$win[2]
  mean(n$npp_NH[k] + n$npp_SH[k])
}
sink(paste0(PW_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver calibration/diag_npp_row_power.R, commit %s, run %s\n  mode v0k basin 1; free {%s}; NM maxit %d; target %.3f +/- %.3f GtC/yr over %d-%d\n\n",
  system("git rev-parse --short HEAD", intern = TRUE), format(Sys.time(), "%Y-%m-%d %H:%M"),
  paste(PW_FREE, collapse = ", "), PW_MAXIT, tg$centre, tg$sd, tg$win[1], tg$win[2]))
rows <- list()
for (a in names(PW_ARMS)) {
  bp <- bp_of(PW_ARMS[[a]]); lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
  l0 <- lp(md$u_mode)
  f <- function(x) { u <- md$u_mode; u[iF] <- x; v <- lp(u); if (!is.finite(v)) 1e12 else -as.numeric(v) }
  o <- stats::optim(md$u_mode[iF], f, method = "Nelder-Mead", control = list(maxit = PW_MAXIT))
  u <- md$u_mode; u[iF] <- o$par; l1 <- lp(u); pv <- ccx_unc_to_par(u)
  s1 <- attr(l1, "streams"); row <- if ("npp_modern" %in% names(s1)) s1[["npp_modern"]] else NA
  rows[[a]] <- data.frame(arm = a, struct = PW_ARMS[[a]], logpost_start = as.numeric(l0), logpost_opt = as.numeric(l1),
    gain = as.numeric(l1) - as.numeric(l0), npp_start = npp_modern(md$u_mode, bp), npp_opt = npp_modern(u, bp),
    npp_row = row, evals = o$counts[["function"]], conv = o$convergence,
    t(unlist(pv[PW_FREE])), check.names = FALSE)
  cat(sprintf("  %-2s gain %+7.3f (%d evals, conv %d) | modern NPP %.2f -> %.2f | beta_max %.3f fert_k %.0f luc_scale %.3f q10 %.3f\n",
    a, rows[[a]]$gain, rows[[a]]$evals, o$convergence, rows[[a]]$npp_start, rows[[a]]$npp_opt,
    pv$beta_max, pv$fert_k, pv$luc_scale, pv$q10))
}
R <- do.call(rbind, rows); rownames(R) <- NULL
cat(sprintf("\n  B1 - A modern NPP at optimum: %+.2f GtC/yr (= %.2f target sigma)\n",
  R$npp_opt[2] - R$npp_opt[1], (R$npp_opt[2] - R$npp_opt[1]) / tg$sd))
print(R, digits = 5, row.names = FALSE)
utils::write.csv(R, paste0(PW_OUT, ".csv"), row.names = FALSE); cat(sprintf("  saved %s.{log,csv}\n", PW_OUT)); sink()
