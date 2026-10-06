# =====================================================================
# diag_fert_profile.R -- WHAT DOES THE RECORD PAY TO PUT FERTILISATION IN THE
# LITERATURE BAND, AND WHO PAYS? (CHANGELOG 09-30 c; Marcus 2026-09-30: "Can we
# do anything to bring the fertilization rate down?")
#
# The fitted (beta_max 2.55, fert_k 868) is above the 09-28 (c) band (beta_max
# 1.3-2.0, K 500-750; notes/lit_2026-09-28_co2_fert_saturation.md). Both are
# PINNED at each FP_POINTS row and the other 9 of the 11 rebalanced names --
# q10 INCLUDED -- are re-optimised (NM, FP_MAXIT) from the CONTROL, the
# fixed-stock tau-500 rebalanced vector (the q10 profile's control, identity
# gated). Two kinds of row, PRE-REGISTERED to separate AMPLITUDE from SHAPE:
#   shape_*  K moved into the band with beta_max solved so the present-day
#            enhancement enh(FP_REF_PPM) equals the control's (a pure SHAPE
#            move; it lands inside the band at K 500-625);
#   amp_*    points that ALSO lower the present-day enhancement (CMIP6-GPP
#            central (1.34, 580), the band middle (1.65, 625)).
#   PREDICTION (written before running): shape rows cheap (|d_loglik| < ~5),
#   amp rows expensive, paid by the historical-sink streams. If the shape rows
#   are expensive too, the record constrains curvature and the story is wrong.
# Reported: d_loglik (fert_k carries the shape prior: a pinned LOGPOST is not
# comparable -- READ d_loglik), every stream's change, the 9 re-fitted names,
# modern NPP, and enh at FP_REF_PPM / 2x / 4x PI.
# Futures of these rows: diag_land_sink_trajectory.R with LS_FERT_PROFILE.
# ⚠ A SCREEN: costs are upper bounds (NM on 9 of 29). No RNG.
# USAGE: Rscript calibration/diag_fert_profile.R  (frozen copy; BLAS pinned to 1
#        by the caller; FP_SMOKE=1 for a smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
QP_DRIVER <- "calibration/diag_fert_profile.R"
QP_TAG    <- "fert_profile_fixedstock"
QP_DATE   <- format(Sys.Date(), "%Y%m%d")
QP_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
QP_STRUCT <- "hilda_csl3v0ka"
QP_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
QP_CTRL_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_20260929.rds")
QP_CTRL_VALUE   <- 500
QP_PARAM  <- c("beta_max", "fert_k")
FP_REF_PPM <- 410                     # present-day CO2 for the enhancement match (~2019)
FP_K_SHAPE <- c(625, 500)             # shape rows: K in the band, enh(FP_REF_PPM) held
FP_AMP     <- list(amp_cmip6c = c(beta_max = 1.34, fert_k = 580),   # 09-28 (c) CMIP6-GPP central
                   amp_mid    = c(beta_max = 1.65, fert_k = 625))   # band middle
QP_FREE11 <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
QP_FREE   <- setdiff(QP_FREE11, QP_PARAM)
QP_MAXIT  <- 3000L
QP_ID_TOL <- 1e-4
QP_CORES  <- 4L
QP_SMOKE  <- identical(Sys.getenv("FP_SMOKE"), "1")
QP_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", QP_TAG, QP_DATE))
COMMIT    <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(QP_MODE)); invisible(ccx_apply_pins(md$pins))
tg <- ccx_npp_modern_target()
iF <- match(QP_FREE, md$param_names); iq <- match(QP_PARAM, md$param_names); stopifnot(!anyNA(iF), !anyNA(iq))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, QP_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
cp <- readRDS(QP_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == QP_CTRL_VALUE)]]
for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]          # the control's structure (fixed stock, tau 500)
prev <- utils::read.csv(QP_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in QP_FREE11) p0[[n]] <- r1[[n]]
for (n in QP_FREE11) p0[[n]] <- ctrl$par[[n]]                   # the control's rebalanced 11
u_ctrl <- ccx_par_to_unc(unlist(p0)[md$param_names])
enh <- function(b, K, ppm) b * (ppm - ccx_const("CO2_PI_PPM")) / (K + ppm - ccx_const("CO2_PI_PPM"))
enh_ctrl <- enh(ctrl$par[["beta_max"]], ctrl$par[["fert_k"]], FP_REF_PPM)
POINTS <- c(setNames(lapply(FP_K_SHAPE, function(K)
              c(beta_max = enh_ctrl * (K + FP_REF_PPM - ccx_const("CO2_PI_PPM")) / (FP_REF_PPM - ccx_const("CO2_PI_PPM")), fert_k = K)),
              sprintf("shape_K%d", FP_K_SHAPE)), FP_AMP)
if (QP_SMOKE) { QP_TAG <- paste0(QP_TAG, "_smoke"); POINTS <- POINTS[1]; QP_MAXIT <- 10L
  QP_OUT <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", QP_TAG, QP_DATE)) }
npp_modern <- function(u) {
  pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(bp, pv)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  n <- ccx_run_fast(sp, F)$npp; k <- floor(n$t) >= tg$win[1] & floor(n$t) <= tg$win[2]
  mean(n$npp_NH[k] + n$npp_SH[k])
}
with_pin <- function(u, v) { p <- as.list(ccx_unc_to_par(u)); for (n in QP_PARAM) p[[n]] <- v[[n]]; ccx_par_to_unc(unlist(p)[md$param_names]) }
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
l_ctrl <- lp(u_ctrl)
id_d <- as.numeric(l_ctrl) - ctrl$opt
stopifnot(abs(id_d) < QP_ID_TOL)
one <- function(nm) {
  v <- POINTS[[nm]]; u0 <- with_pin(u_ctrl, v); l0 <- lp(u0)
  f <- function(x) { u <- u0; u[iF] <- x; w <- lp(u); if (!is.finite(w)) 1e12 else -as.numeric(w) }
  o <- stats::optim(u0[iF], f, method = "Nelder-Mead", control = list(maxit = QP_MAXIT))
  u <- u0; u[iF] <- o$par; l1 <- lp(u)
  list(value = nm, pin = v, over = ctrl$over, frozen = as.numeric(l0), opt = as.numeric(l1),
       ll0 = as.numeric(attr(l0, "loglik")), ll1 = as.numeric(attr(l1, "loglik")),
       s0 = attr(l0, "streams"), s1 = attr(l1, "streams"), npp = npp_modern(u),
       par = unlist(ccx_unc_to_par(u)[QP_FREE11]), evals = o$counts[["function"]], conv = o$convergence)
}
res <- parallel::mclapply(names(POINTS), one, mc.cores = QP_CORES, mc.preschedule = FALSE)
ok <- !vapply(res, inherits, logical(1), "try-error"); if (!all(ok)) { print(res[!ok]); stop("fork failure") }
ref <- list(value = "control", pin = unlist(ctrl$par[QP_PARAM]), over = ctrl$over, frozen = as.numeric(l_ctrl), opt = as.numeric(l_ctrl),
            ll0 = as.numeric(attr(l_ctrl, "loglik")), ll1 = as.numeric(attr(l_ctrl, "loglik")),
            s0 = attr(l_ctrl, "streams"), s1 = attr(l_ctrl, "streams"), npp = npp_modern(u_ctrl),
            par = unlist(ccx_unc_to_par(u_ctrl)[QP_FREE11]), evals = 0L, conv = 0L, control = TRUE)
res <- c(list(ref), res)

sink(paste0(QP_OUT, ".log"), split = TRUE)
X2 <- 2 * ccx_const("CO2_PI_PPM"); X4 <- 4 * ccx_const("CO2_PI_PPM")
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", QP_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  structure %s at v0k basin 1 + control overrides {%s}; control = %s value %g (rebalanced 11)\n",
  QP_STRUCT, paste(sprintf("%s=%g", names(ctrl$over), unlist(ctrl$over)), collapse = ", "), basename(QP_CTRL_PROFILE), QP_CTRL_VALUE))
cat(sprintf("  (beta_max, fert_k) PINNED per row; rebal = NM maxit %d on the other 9 {%s}\n", QP_MAXIT, paste(QP_FREE, collapse = ", ")))
cat(sprintf("  shape rows hold enh(%g ppm) = control's %.4f; CO2_PI %.2f; 2x/4x = %.1f/%.1f ppm\n", FP_REF_PPM, enh_ctrl, ccx_const("CO2_PI_PPM"), X2, X4))
cat(sprintf("  logpost / loglik natural-log units (fert_k carries the shape prior: READ d_loglik); NPP GtC/yr mean %d-%d; no RNG\n", tg$win[1], tg$win[2]))
cat(sprintf("  [identity] control rescored vs stored $opt: %.2e (tol %.0e)\n\n", id_d, QP_ID_TOL))
cat(sprintf("  %-12s %8s %7s %8s %8s %8s %10s %10s %8s %5s %6s\n", "row", "beta_max", "fert_k", "enh_ref", "enh_2x", "enh_4x",
            "d_ll_froz", "d_ll_rebal", "NPPmod", "conv", "evals"))
for (r in res) { b <- r$pin[["beta_max"]]; K <- r$pin[["fert_k"]]
  cat(sprintf("  %-12s %8.3f %7.1f %8.4f %8.4f %8.4f %+10.2f %+10.2f %8.2f %5d %6d\n", r$value, b, K,
    enh(b, K, FP_REF_PPM), enh(b, K, X2), enh(b, K, X4), r$ll0 - ref$ll1, r$ll1 - ref$ll1, r$npp, r$conv, r$evals)) }
labs <- sapply(res, `[[`, "value")
for (w in c("s0", "s1")) {
  S <- do.call(rbind, lapply(res, function(r) r[[w]] - ref$s1)); rownames(S) <- labs
  big <- names(sort(apply(abs(S), 2, max), decreasing = TRUE))[1:min(10, ncol(S))]
  cat(sprintf("\n=== streams vs control, %s (10 largest |max|) ===\n", if (w == "s0") "FROZEN" else "REBALANCED"))
  print(round(S[, big, drop = FALSE], 2))
}
cat("\n=== 11 names (beta_max, fert_k pinned; 9 rebalanced) ===\n"); P <- do.call(rbind, lapply(res, `[[`, "par")); rownames(P) <- labs; print(signif(P, 4))
S1 <- do.call(rbind, lapply(res, function(r) r$s1 - ref$s1))
R <- data.frame(row = labs,
                enh_ref = sapply(res, function(r) enh(r$pin[["beta_max"]], r$pin[["fert_k"]], FP_REF_PPM)),
                d_lp_frozen = sapply(res, `[[`, "frozen") - ref$opt, d_lp_rebal = sapply(res, `[[`, "opt") - ref$opt,
                d_ll_frozen = sapply(res, `[[`, "ll0") - ref$ll1, d_ll_rebal = sapply(res, `[[`, "ll1") - ref$ll1,
                npp_modern = sapply(res, `[[`, "npp"), conv = sapply(res, `[[`, "conv"), P, S1, check.names = FALSE,
                provenance = sprintf("%s @%s; %s v0k basin1 + fixed-stock tau500 control; (beta_max, fert_k) pinned, NM %d on 9; enh ref %g ppm; no RNG",
                                     QP_DRIVER, COMMIT, QP_STRUCT, QP_MAXIT, FP_REF_PPM))
utils::write.csv(R, paste0(QP_OUT, ".csv"), row.names = FALSE); saveRDS(res, paste0(QP_OUT, ".rds"))
cat(sprintf("  saved %s.{log,csv,rds}\n", QP_OUT)); sink()
