# =====================================================================
# diag_land_sink_trajectory.R -- DOES THE LAND EVER TURN FROM SINK TO SOURCE,
# AND IS THAT A PROPERTY OF THE DESIGN OR OF THE FITTED q10? (CHANGELOG 09-29 v,
# measurement B; Marcus 2026-09-29: "run all the cheap measurements")
#
# Koven et al. 2022 (ESD 13:885, Sect. 3.2, via notes/lit_2026-09-29_land_c_2300_
# benchmark.md): under SSP5-8.5 every CMIP6 extension model turns from net land
# sink to neutral or source between ~2100 and ~2220; ensemble cumulative land
# sink 264 +/- 172 (2015-2100), -29 +/- 264 (2100-2200), -178 +/- 251 (2200-2300)
# PgC, CONCENTRATION-driven at 2162 ppm in 2300. CCX is emission-driven, so the
# CO2 paths differ; the windows are printed for orientation, not as a gate.
#
# Hypotheses: H1 the design cannot flip (no permafrost, etc.); H2 it can, but
# the FIT's weak q10 (~1.10) and strong fertilisation keep it a sink.
#   B1  the land trajectory at the stored v0k mode and the fixed-stock tau-500
#       control (what the model does now);
#   B2  the control with q10 forced to LS_Q10 (FROZEN: nothing else moves);
#   B3  the q10-profile rows (q10 pinned, 10 names REBALANCED on the record;
#       diag_q10_profile.R), if LS_Q10_PROFILE exists.
#   B2f the control with (beta_max, fert_k) set to LS_FERT (env "b,K"; FROZEN) at
#       the control q10 and at each LS_Q10. First run (09-29 v) showed NPP
#       x2.3 by 2200 under SSP5-8.5 at the control's (2.55, 868), which no q10
#       <= 2 can overcome (a flip needs q10^(dT/10) > NPP/NPP0). LS_FERT is the
#       09-28 (c) literature-band point (1.34, 580; notes/lit_2026-09-28_co2_
#       fert_saturation.md), a HYPOTHESIS from mostly-GPP evidence.
#   B4  the fertilisation-profile rows ((beta_max, fert_k) pinned in the 09-28 c
#       band, 9 names REBALANCED incl. q10; diag_fert_profile.R), if
#       LS_FERT_PROFILE exists (added 2026-09-30).
# If B2 at q10 2.0 does not flip by 2300, H1 holds for this structure AT THE
# FITTED FERTILISATION; B2f says whether it holds at the literature's. B3 says
# what the record charges for the q10 that would.
# NET land flux = d(land_C)/dt (land_C includes the LUC debit, R/model.R ~1174),
# i.e. NBP-like. Also reported: E_LUC-free "natural" flux is NOT separated here.
# PROTOCOL: ccx_run_coupled as diag_tau_soil_slow_futures.R (vv spliced onto GCB
# history, ssp585 unspliced), 1750-2300.
# IDENTITY: v0k ssp585 2300 = LS_ID_V0K (handoff); control ssp585 2300 equals
# tau_soil_slow_futures_fixedstock_ext_20260929.csv's 500 row to LS_ID_TOL_CTRL.
# No RNG. USAGE: Rscript calibration/diag_land_sink_trajectory.R  (~10-15 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
LS_DRIVER <- "calibration/diag_land_sink_trajectory.R"
LS_TAG    <- "land_sink_trajectory"
LS_DATE   <- format(Sys.Date(), "%Y%m%d")
LS_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
LS_STRUCT <- "hilda_csl3v0ka"
LS_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
LS_CTRL_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_20260929.rds")
LS_CTRL_VALUE   <- 500
LS_CTRL_FUT     <- ccx_path("outputs", "diagnostics", "tau_soil_slow_futures_fixedstock_ext_20260929.csv")
LS_Q10_PROFILE  <- Sys.getenv("LS_Q10_PROFILE", "")
LS_FERT_PROFILE <- Sys.getenv("LS_FERT_PROFILE", "")
LS_Q10    <- c(1.5, 2.0)
LS_FERT   <- if (nzchar(Sys.getenv("LS_FERT"))) setNames(as.numeric(strsplit(Sys.getenv("LS_FERT"), ",")[[1]]), c("beta_max", "fert_k")) else NULL
LS_FREE   <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
LS_SCEN   <- c("ssp585", "vvH", "vvL")
LS_SPLICE <- c(ssp585 = FALSE, vvH = TRUE, vvL = TRUE)
LS_END    <- 2300L
LS_RUNMEAN <- 11L                               # yr; centred running mean for the onset test
LS_ONSET_FROM <- 2030L
LS_WINDOWS <- list(c(2015L, 2100L), c(2100L, 2200L), c(2200L, 2300L))   # Koven 2022's reporting windows
LS_ID_V0K <- 1388.3; LS_ID_TOL_V0K <- 0.05; LS_ID_TOL_CTRL <- 1e-6
LS_CORES  <- 6L
LS_OUT_SUFFIX <- Sys.getenv("LS_OUT_SUFFIX", "")
LS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s%s_%s", LS_TAG, LS_OUT_SUFFIX, LS_DATE))
COMMIT    <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(LS_MODE)); invisible(ccx_apply_pins(md$pins))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, LS_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
prev <- utils::read.csv(LS_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in LS_FREE) p0[[n]] <- r1[[n]]
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!LS_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
vec_of <- function(over, par11) {        # the profile drivers' route: base + overrides, 29 coords with the 11 replaced
  pr <- p0; for (n in LS_FREE) pr[[n]] <- par11[[n]]
  pu <- ccx_unc_to_par(ccx_par_to_unc(unlist(pr)[md$param_names]))
  b <- bp; for (n in names(over)) b[[n]] <- over[[n]]
  list(p = ccx_overlay_par(b, pu), bomb = pu$bomb_total, luc = pu$luc_scale)
}
cp <- readRDS(LS_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == LS_CTRL_VALUE)]]
V <- list()
pm0 <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
p_id <- ccx_overlay_par(ccx_mode_base(md), pm0); p_id$pump_mode <- md$pump_mode
V[["v0k_stored"]] <- list(p = p_id, bomb = pm0$bomb_total, luc = pm0$luc_scale, kind = "B1", q10 = pm0$q10, dlp = NA_real_)
v <- vec_of(ctrl$over, ctrl$par); V[["ctrl_tau500"]] <- c(v, kind = "B1", q10 = ctrl$par[["q10"]], dlp = 0)
qp <- if (nzchar(LS_Q10_PROFILE)) readRDS(LS_Q10_PROFILE) else NULL
qv <- if (is.null(qp)) numeric(0) else vapply(qp, `[[`, numeric(1), "value")
for (q in LS_Q10) { pq <- ctrl$par; pq[["q10"]] <- q; v <- vec_of(ctrl$over, pq)
  dl <- if (any(abs(qv - q) < 1e-12)) qp[[which(abs(qv - q) < 1e-12)]]$ll0 - qp[[1]]$ll1 else NA_real_   # frozen loglik, scored by the profile
  V[[sprintf("frozen_q10_%.1f", q)]] <- c(v, kind = "B2", q10 = q, dlp = dl) }
if (!is.null(LS_FERT)) for (q in c(ctrl$par[["q10"]], LS_Q10)) { pf <- ctrl$par; pf[["q10"]] <- q
  pf[["beta_max"]] <- LS_FERT[["beta_max"]]; pf[["fert_k"]] <- LS_FERT[["fert_k"]]; v <- vec_of(ctrl$over, pf)
  V[[sprintf("fertlit_q10_%.2f", q)]] <- c(v, kind = "B2f", q10 = q, dlp = NA_real_) }
if (!is.null(qp)) { stopifnot(isTRUE(qp[[1]]$control))
  for (x in qp) if (!isTRUE(x$control)) { v <- vec_of(x$over, x$par)
    V[[sprintf("rebal_q10_%.1f", x$value)]] <- c(v, kind = "B3", q10 = x$value, dlp = x$ll1 - qp[[1]]$ll1) } }
fp <- if (nzchar(LS_FERT_PROFILE)) readRDS(LS_FERT_PROFILE) else NULL
if (!is.null(fp)) { stopifnot(isTRUE(fp[[1]]$control))
  for (x in fp) if (!isTRUE(x$control)) { v <- vec_of(x$over, x$par)
    V[[sprintf("rebal_fert_%s", x$value)]] <- c(v, kind = "B4", q10 = x$par[["q10"]], dlp = x$ll1 - fp[[1]]$ll1) } }

one <- function(nm) {
  v <- V[[nm]]; sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(v$p); out <- list()
  for (s in LS_SCEN) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, LS_END), emissions = emis(s), bomb_total_kmol = v$bomb, luc_scale = v$luc))
    o <- r$out; yr <- floor(o$t)
    ann <- function(x) as.numeric(tapply(x, yr, mean))
    Y <- sort(unique(yr)); land <- ann(o$land_C); co2 <- ann((o$co2_NH + o$co2_SH) / 2)
    npp <- as.numeric(tapply(r$npp$npp_NH + r$npp$npp_SH, floor(r$npp$t), mean))[seq_along(Y)]
    gm <- r$climate$gmst[match(Y, r$climate$year)]
    out[[s]] <- data.frame(vector = nm, scenario = s, year = Y, co2 = co2, land_C = land,
                           net_flux = c(NA, diff(land)), npp = npp, gmst = gm)
  }
  do.call(rbind, out)
}
res <- parallel::mclapply(names(V), one, mc.cores = LS_CORES, mc.preschedule = FALSE)
bad <- vapply(res, inherits, logical(1), "try-error"); if (any(bad)) { print(res[bad]); stop("fork failure") }
TR <- do.call(rbind, res)
at <- function(v, s, y, col) TR[[col]][TR$vector == v & TR$scenario == s & TR$year == y]
id_v0k <- at("v0k_stored", "ssp585", LS_END, "co2")
fut <- utils::read.csv(LS_CTRL_FUT); id_ctrl_ref <- fut$ssp585_co2_2300[fut$tau_soil_slow == LS_CTRL_VALUE]
id_ctrl <- at("ctrl_tau500", "ssp585", LS_END, "co2")
stopifnot(abs(id_v0k - LS_ID_V0K) < LS_ID_TOL_V0K, abs(id_ctrl - id_ctrl_ref) < LS_ID_TOL_CTRL)
# summaries
rm_c <- function(x, k) { h <- (k - 1) %/% 2; n <- length(x); vapply(seq_len(n), function(i) if (i - h < 1 || i + h > n) NA_real_ else mean(x[(i - h):(i + h)]), 0) }
S <- do.call(rbind, lapply(split(TR, list(TR$vector, TR$scenario), drop = TRUE), function(d) {
  d <- d[order(d$year), ]; rmf <- rm_c(d$net_flux, LS_RUNMEAN); k <- d$year >= LS_ONSET_FROM & !is.na(rmf)
  onset <- if (any(rmf[k] < 0)) d$year[k][which(rmf[k] < 0)[1]] else NA_integer_
  dl <- function(w) d$land_C[d$year == w[2]] - d$land_C[d$year == w[1]]
  data.frame(vector = d$vector[1], kind = V[[d$vector[1]]]$kind, q10 = V[[d$vector[1]]]$q10, d_loglik = V[[d$vector[1]]]$dlp,
             scenario = d$scenario[1], co2_2300 = d$co2[d$year == LS_END], gmst_2300 = d$gmst[d$year == LS_END],
             land_1750 = d$land_C[d$year == 1750], land_peak = max(d$land_C), peak_year = d$year[which.max(d$land_C)],
             land_2300 = d$land_C[d$year == LS_END], flux_2090s = mean(d$net_flux[d$year %in% 2090:2099]),
             flux_2190s = mean(d$net_flux[d$year %in% 2190:2199]), flux_2290s = mean(d$net_flux[d$year %in% 2290:2299]),
             dland_2015_2100 = dl(LS_WINDOWS[[1]]), dland_2100_2200 = dl(LS_WINDOWS[[2]]), dland_2200_2300 = dl(LS_WINDOWS[[3]]),
             source_onset = onset)
}))
S <- S[order(S$scenario, match(S$vector, names(V))), ]; rownames(S) <- NULL
prov <- sprintf("%s @%s; %s v0k basin1; ctrl = %s value %g; coupled 1750-%d; ssp585 unspliced, vv spliced; net flux = d(land_C)/dt; no RNG",
  LS_DRIVER, COMMIT, LS_STRUCT, basename(LS_CTRL_PROFILE), LS_CTRL_VALUE, LS_END)
S$provenance <- prov; TR$provenance <- prov

sink(paste0(LS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", LS_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  vectors: %s\n", paste(sprintf("%s[%s]", names(V), vapply(V, `[[`, "", "kind")), collapse = ", ")))
cat(sprintf("  scenarios %s (spliced %s); GtC, ppm, K; net flux = d(land_C)/dt incl. LUC; onset = first yr >= %d with %d-yr centred mean net flux < 0\n",
  paste(LS_SCEN, collapse = ", "), paste(LS_SPLICE, collapse = "/"), LS_ONSET_FROM, LS_RUNMEAN))
cat(sprintf("  B2f fertilisation (beta_max, fert_k): %s\n", if (is.null(LS_FERT)) "(none)" else paste(LS_FERT, collapse = ", ")))
cat(sprintf("  q10 profile: %s\n", if (nzchar(LS_Q10_PROFILE)) LS_Q10_PROFILE else "(none -- B3 not run)"))
cat(sprintf("  fert profile: %s\n", if (nzchar(LS_FERT_PROFILE)) LS_FERT_PROFILE else "(none -- B4 not run)"))
cat(sprintf("  [identity] v0k ssp585 2300 %.2f (handoff %.1f); control %.4f vs %s %.4f\n", id_v0k, LS_ID_V0K, id_ctrl, basename(LS_CTRL_FUT), id_ctrl_ref))
cat("  Koven 2022 SSP5-8.5 (conc.-driven, 2162 ppm in 2300) cumulative land sink: 264+/-172 (2015-2100), -29+/-264 (2100-2200), -178+/-251 (2200-2300) PgC\n\n")
for (s in LS_SCEN) { cat(sprintf("--- %s ---\n", s))
  cat(sprintf("  %-16s %4s %5s %8s | %6s %5s | %6s %5s %6s | %6s %6s %6s | %6s %6s %6s | %6s\n", "vector", "kind", "q10", "dLL", "CO2", "dT",
    "peak", "pkyr", "L2300", "f2090s", "f2190s", "f2290s", "dL1521", "dL2122", "dL2223", "onset"))
  for (i in which(S$scenario == s)) with(S[i, ], cat(sprintf("  %-16s %4s %5.2f %8s | %6.0f %5.2f | %6.0f %5d %6.0f | %+6.2f %+6.2f %+6.2f | %+6.0f %+6.0f %+6.0f | %6s\n",
    vector, kind, q10, if (is.na(d_loglik)) "" else sprintf("%+.1f", d_loglik), co2_2300, gmst_2300, land_peak, peak_year, land_2300,
    flux_2090s, flux_2190s, flux_2290s, dland_2015_2100, dland_2100_2200, dland_2200_2300, if (is.na(source_onset)) "none" else source_onset)))
  cat("\n") }
utils::write.csv(S, paste0(LS_OUT, ".csv"), row.names = FALSE); utils::write.csv(TR, paste0(LS_OUT, "_annual.csv"), row.names = FALSE)
cat(sprintf("  saved %s{.log,.csv,_annual.csv}\n", LS_OUT)); sink()
