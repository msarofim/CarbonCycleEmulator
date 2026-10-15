# =====================================================================
# diag_tau_soil_slow_futures.R -- does the PASSIVE-SOIL STOCK move the future?
# (Marcus 2026-09-29: "run the 2300 futures at the 1000 and 1500 yr rows")
#
# The tau_soil_slow profile (diag_tau_soil_slow_profile.R, CHANGELOG 09-29 n)
# found the record is near-indifferent between a 1.5k and a 3-4.5k GtC PI
# passive pool (+5.7 log units), because the stock trades against luc_scale,
# kz and fert_k. This runs the REBALANCED vectors of TF_ROWS forward to 2300.
# The 500-yr row (the same rebalance at the default stock) is the like-for-like
# CONTROL; differences are read against it, not against the stored v0k mode.
#
# PROTOCOL: ccx_run_coupled (as diag_rep_dc_ladder_futures.R); vvH / vvL
# spliced onto GCB history, ssp585 unspliced (as 09-29 b). Parameters built
# exactly as the profile scored them: arm A (hilda_csl3v0ka) base + pins +
# tau_soil_slow override, 29 fitted coords = v0k mode with the 11 rebalanced.
# IDENTITY: the stored v0k mode through the ladder driver's route must give
# ssp585 2300 = TF_ID_SSP585 ppm (09-29 b / handoff).
# Also reported: the passive pool's own change 1750 -> 2300 (not just land_C).
# USAGE: Rscript calibration/diag_tau_soil_slow_futures.R   (~5 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
TF_DRIVER  <- "calibration/diag_tau_soil_slow_futures.R"
TF_TAG     <- "tau_soil_slow_futures"
TF_DATE    <- "20260929"
TF_MODE    <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
TF_STRUCT  <- "hilda_csl3v0ka"
# TF_PROFILE_TAG (env) reads another profile, e.g. "tau_soil_slow_profile_fixedstock"
TF_PROFILE_TAG <- Sys.getenv("TF_PROFILE_TAG", "tau_soil_slow_profile")
TF_PROFILE <- ccx_path("outputs", "diagnostics", sprintf("%s_20260929.rds", TF_PROFILE_TAG))
TF_PREV    <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
TF_PARAM   <- "tau_soil_slow"
# TF_ROWS (env, comma-separated) overrides the row set; 500 must stay in it (the control)
TF_ROWS    <- as.numeric(strsplit(Sys.getenv("TF_ROWS", "500,1000,1500"), ",")[[1]])
stopifnot(TF_ROWS[1] == 500)                # every "vs control" line reads row 1
# TF_OUT_SUFFIX (env) keeps an extended run from overwriting a shipped output
TF_OUT_SUFFIX <- Sys.getenv("TF_OUT_SUFFIX", "")
TF_FREE    <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
                "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
TF_SCEN    <- c("vvH", "vvL", "ssp585")
TF_SPLICE  <- c(vvH = TRUE, vvL = TRUE, ssp585 = FALSE)
TF_YEARS   <- c(2100L, 2300L)
TF_END_YEAR <- 2300L
TF_ID_SSP585 <- 1388.3
TF_ID_TOL  <- 0.05                          # ppm; the handoff value is printed to 0.1
if (TF_PROFILE_TAG != "tau_soil_slow_profile") TF_TAG <- paste0(TF_TAG, sub("^tau_soil_slow_profile", "", TF_PROFILE_TAG))
TF_OUT     <- ccx_path("outputs", "diagnostics", sprintf("%s%s_%s", TF_TAG, TF_OUT_SUFFIX, TF_DATE))
COMMIT     <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(TF_MODE)); invisible(ccx_apply_pins(md$pins))
iF <- match(TF_FREE, md$param_names); stopifnot(!anyNA(iF))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, TF_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
prof <- readRDS(TF_PROFILE); pv <- vapply(prof, `[[`, numeric(1), "value"); stopifnot(all(TF_ROWS %in% pv))
conv <- vapply(prof, function(x) if (is.null(x$conv)) NA_real_ else as.numeric(x$conv), numeric(1))
prev <- utils::read.csv(TF_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in TF_FREE) p0[[n]] <- r1[[n]]
u0 <- ccx_par_to_unc(unlist(p0)[md$param_names])
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!TF_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }

futures <- function(p, bomb, luc) {
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p); out <- list()
  for (s in TF_SCEN) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, TF_END_YEAR), emissions = emis(s),
                                          bomb_total_kmol = bomb, luc_scale = luc))$out
    yr <- floor(r$t); co2 <- tapply((r$co2_NH + r$co2_SH) / 2, yr, mean); ld <- tapply(r$land_C, yr, mean)
    for (y in TF_YEARS) { out[[paste0(s, "_co2_", y)]] <- as.numeric(co2[as.character(y)])
      out[[paste0(s, "_land_", y)]] <- as.numeric(ld[as.character(y)]) }
    out[[paste0(s, "_land_1750")]] <- as.numeric(ld[["1750"]])
    sl <- grep("soil_slow", names(r), value = TRUE)
    if (length(sl)) { ss <- tapply(rowSums(as.matrix(r[, sl, drop = FALSE])), yr, mean)
      out[[paste0(s, "_slow_1750")]] <- as.numeric(ss[["1750"]]); out[[paste0(s, "_slow_2300")]] <- as.numeric(ss[["2300"]]) }
  }
  unlist(out)
}
# ---- identity: stored v0k mode, the ladder driver's route ------------
pm0 <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
p_id <- ccx_overlay_par(ccx_mode_base(md), pm0); p_id$pump_mode <- md$pump_mode
fid <- futures(p_id, pm0$bomb_total, pm0$luc_scale)
id_d <- fid[["ssp585_co2_2300"]] - TF_ID_SSP585
stopifnot(abs(id_d) < TF_ID_TOL)
# ---- profile rows ----------------------------------------------------
rows <- list()
for (v in TF_ROWS) {
  x <- prof[[which(pv == v)]]; u <- u0
  pu <- as.list(ccx_unc_to_par(u)); for (n in TF_FREE) pu[[n]] <- x$par[[n]]
  u <- ccx_par_to_unc(unlist(pu)[md$param_names])
  ov <- if (!is.null(x$over)) x$over else setNames(list(v), TF_PARAM)   # older profile: tau only
  b <- bp; for (n in names(ov)) b[[n]] <- ov[[n]]; pr <- ccx_unc_to_par(u); p <- ccx_overlay_par(b, pr)
  f <- futures(p, pr$bomb_total, pr$luc_scale)
  rows[[as.character(v)]] <- data.frame(tau_soil_slow = v, litter_slow_frac = b$litter_slow_frac, d_logpost_profile = x$opt - prof[[which(pv == 500)]]$opt,
    profile_conv = conv[which(pv == v)],   # 1 = the profile optimizer hit maxit
    t(f), t(unlist(pr[TF_FREE])), check.names = FALSE)
}
R <- do.call(rbind, rows); rownames(R) <- NULL
R$provenance <- sprintf("%s @%s; %s v0k basin1 + tau_soil_slow override; 11 rebalanced (profile NM 3000); coupled 1750-%d; ssp585 unspliced, vv spliced", TF_DRIVER, COMMIT, TF_STRUCT, TF_END_YEAR)
sink(paste0(TF_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", TF_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  profile %s (litter_slow_frac per row: %s)\n", TF_PROFILE_TAG, paste(signif(R$litter_slow_frac, 3), collapse = ", ")))
cat(sprintf("  vectors: %s rows {%s} (500 = control); arm %s; scenarios %s (spliced %s); ppm global mean; land GtC (land_C)\n",
  basename(TF_PROFILE), paste(TF_ROWS, collapse = ", "), TF_STRUCT, paste(TF_SCEN, collapse = ", "), paste(TF_SPLICE, collapse = "/")))
cat(sprintf("  [identity] stored v0k ssp585 2300 = %.2f ppm (handoff %.1f; d %+.3f)\n\n", fid[["ssp585_co2_2300"]], TF_ID_SSP585, id_d))
for (i in seq_len(nrow(R))) with(R[i, ], cat(sprintf(
  "  tau %4g  dlp %+5.2f%s | ssp585 2300 %7.1f ppm land x%.2f | vvH 2300 %6.1f | vvL 2300 %6.1f | vvH 2100 %6.1f | luc %.3f kz %5.0f fert_k %4.0f q10 %.3f\n",
  tau_soil_slow, d_logpost_profile, ifelse(isTRUE(profile_conv == 1), " MAXIT", ""), ssp585_co2_2300, ssp585_land_2300 / ssp585_land_1750, vvH_co2_2300, vvL_co2_2300, vvH_co2_2100,
  luc_scale, kz, fert_k, q10)))
if ("ssp585_slow_1750" %in% names(R)) { cat("\n  passive pool 1750 -> 2300 (ssp585), GtC:\n")
  for (i in seq_len(nrow(R))) cat(sprintf("    tau %4g  %7.0f -> %7.0f  (%+.0f)\n", R$tau_soil_slow[i], R$ssp585_slow_1750[i], R$ssp585_slow_2300[i], R$ssp585_slow_2300[i] - R$ssp585_slow_1750[i])) }
cat("\n  vs control (tau 500), ppm:\n")
for (i in seq_len(nrow(R))) cat(sprintf("    tau %4g  ssp585 2300 %+7.1f  vvH 2300 %+7.1f  vvL 2300 %+6.1f  vvH 2100 %+6.1f\n", R$tau_soil_slow[i],
  R$ssp585_co2_2300[i] - R$ssp585_co2_2300[1], R$vvH_co2_2300[i] - R$vvH_co2_2300[1], R$vvL_co2_2300[i] - R$vvL_co2_2300[1], R$vvH_co2_2100[i] - R$vvH_co2_2100[1]))
utils::write.csv(R, paste0(TF_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", TF_OUT)); sink()
