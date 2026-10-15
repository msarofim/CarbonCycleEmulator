# =====================================================================
# diag_npp0_scan.R -- WHAT HOLDS THE MODEL'S MODERN NPP AT 70? (NPP_GLOBAL_PI
# option 4, follow-up 1; Marcus 2026-09-29 "run option 1")
#
# The modern-NPP row was DECORATIVE at sigma 7.76: arm B1 moved modern NPP
# -0.01 GtC/yr (npp_row_power_20260929). So the record, not the row, sets it.
# This asks WHICH streams: scan NPP_GLOBAL_PI by NS_SCALES (in-process constant
# override, the audit screen's route, reset after), re-optimize NS_FREE at
# each, and report modern NPP and every stream's change vs the unscaled point.
# If the payer is the SEASONAL CO2 amplitude, the model's NPP is a quantity
# tied to the seasonal parameters (a phi-like coupling) rather than one
# comparable to observed NPP; if it is the CO2 LEVEL / sinks, it is the
# fertilization integral.
# Structure: arm A ("hilda_csl3v0ka") at the v0k basin-1 vector -- the baseline
# the NPP arms compare against. No npp_modern row is scored here.
# ⚠ A SCREEN: Nelder-Mead on NS_FREE (not all 29), so costs are UPPER BOUNDS.
# USAGE: Rscript calibration/diag_npp0_scan.R   (~40 min on NS_CORES forks)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
NS_COMMIT <- ccx_git_stamp()
ccx_load_cpp()
NS_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
NS_STRUCT <- "hilda_csl3v0ka"
NS_SCALES <- c(0.75, 0.80, 0.85, 0.90, 0.95, 1.00, 1.05)
NS_FREE   <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
NS_MAXIT  <- 3000L
NS_CORES  <- 7L
NS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("npp0_scan_%s", format(Sys.Date(), "%Y%m%d")))
md <- readRDS(ccx_mode_file(NS_MODE)); invisible(ccx_apply_pins(md$pins))
tg <- ccx_npp_modern_target()
iF <- match(NS_FREE, md$param_names); stopifnot(!anyNA(iF))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, NS_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
CONST0 <- CCX_CONSTANTS
set_npp <- function(s) { cc <- CONST0; cc$NPP_GLOBAL_PI$value <- CONST0$NPP_GLOBAL_PI$value * s
  assign("CCX_CONSTANTS", cc, envir = globalenv()) }
npp_modern <- function(u) {
  pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(bp, pv)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  n <- ccx_run_fast(sp, F)$npp; k <- floor(n$t) >= tg$win[1] & floor(n$t) <= tg$win[2]
  mean(n$npp_NH[k] + n$npp_SH[k])
}
one <- function(s) {
  set_npp(s)
  stopifnot(isTRUE(all.equal(ccx_const("NPP_GLOBAL_PI"), CONST0$NPP_GLOBAL_PI$value * s)))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
  l0 <- lp(md$u_mode)
  f <- function(x) { u <- md$u_mode; u[iF] <- x; v <- lp(u); if (!is.finite(v)) 1e12 else -as.numeric(v) }
  o <- stats::optim(md$u_mode[iF], f, method = "Nelder-Mead", control = list(maxit = NS_MAXIT))
  u <- md$u_mode; u[iF] <- o$par; l1 <- lp(u)
  list(scale = s, frozen = as.numeric(l0), opt = as.numeric(l1), loglik = attr(l1, "loglik"),
       streams = attr(l1, "streams"), npp = npp_modern(u), par = unlist(ccx_unc_to_par(u)[NS_FREE]),
       evals = o$counts[["function"]], conv = o$convergence)
}
res <- parallel::mclapply(NS_SCALES, one, mc.cores = NS_CORES, mc.preschedule = FALSE)
set_npp(1)
ok <- !vapply(res, inherits, logical(1), "try-error"); if (!all(ok)) print(res[!ok])
ref <- res[[which(NS_SCALES == 1)]]
sink(paste0(NS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver calibration/diag_npp0_scan.R, commit %s, run %s\n  structure %s at v0k basin 1; free {%s}; NM maxit %d; NPP_GLOBAL_PI x {%s}; logpost units; NPP GtC/yr %d-%d\n",
  NS_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), NS_STRUCT,
  paste(NS_FREE, collapse = ", "), NS_MAXIT, paste(NS_SCALES, collapse = ", "), tg$win[1], tg$win[2]))
cat(sprintf("  [control] scale 1.00 re-optimised gain %+.3f over the stored vector (arm A adds aod anomaly)\n\n", ref$opt - ref$frozen))
cat(sprintf("  %-6s %9s %9s %8s %5s %6s | %s\n", "scale", "d_frozen", "d_opt", "NPPmod", "conv", "evals", paste(sprintf("%8s", NS_FREE), collapse = "")))
for (r in res) cat(sprintf("  %-6.2f %+9.2f %+9.2f %8.2f %5d %6d | %s\n", r$scale, r$frozen - ref$frozen, r$opt - ref$opt, r$npp, r$conv, r$evals,
                           paste(sprintf("%8.3g", r$par), collapse = "")))
S <- do.call(rbind, lapply(res, function(r) r$streams - ref$streams))
rownames(S) <- sprintf("x%.2f", NS_SCALES)
big <- names(sort(apply(abs(S), 2, max), decreasing = TRUE))[1:min(10, ncol(S))]
cat("\n=== WHO PAYS: stream change vs scale 1.00, re-optimised (10 largest |max|) ===\n")
print(round(S[, big, drop = FALSE], 2))
R <- data.frame(scale = NS_SCALES, d_frozen = sapply(res, `[[`, "frozen") - ref$frozen,
                d_opt = sapply(res, `[[`, "opt") - ref$opt, npp_modern = sapply(res, `[[`, "npp"),
                conv = sapply(res, `[[`, "conv"), do.call(rbind, lapply(res, `[[`, "par")), S, check.names = FALSE)
utils::write.csv(R, paste0(NS_OUT, ".csv"), row.names = FALSE); cat(sprintf("  saved %s.{log,csv}\n", NS_OUT)); sink()
