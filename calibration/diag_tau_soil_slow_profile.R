# =====================================================================
# diag_tau_soil_slow_profile.R -- IS THE PASSIVE-SOIL RUNAWAY REAL? (09-29 (m)
# follow-up; Marcus 2026-09-29 "run the tau_soil_slow-only test")
#
# In the residence-free NPP0 rescan (diag_npp0_scan_resfree.R) every one of 7
# independent optima moved tau_soil_slow 500 -> 1000-1800 yr (PI passive soil
# 2.6-5.6k GtC vs the 1.5k the default was designed for). At scale 1.00 the
# gain was bought by d14c_NH and d14c_intcal. This isolates it: a PROFILE over
# TS_VALUES with ONLY tau_soil_slow moved among the residence times (the other
# four at their defaults), NPP_GLOBAL_PI unscaled.
#   frozen: the 29 fitted coords at the 09-29 (k) scale-1 optimum;
#   rebal : re-optimise the same 11 names (NM, TS_MAXIT) from that optimum.
# Reported: d_logpost vs the default (500) row, every stream's change, the
# implied PI passive-soil stock, modern NPP.
# IDENTITY: the TS_DEFAULT row, frozen, reproduces the 09-29 (k) scale-1
# optimum's logpost (|d| < TS_ID_TOL).
# ⚠ A SCREEN: costs are upper bounds (NM on 11 of 29). No RNG.
# FIXED-STOCK MODE (TS_FIXED_STOCK=1; CHANGELOG 09-29 q, "T1"): AGE vs STOCK.
# litter_slow_frac is co-varied as TS_LSF_DEFAULT * TS_DEFAULT / tau, so the PI
# passive stock stays at NPP0 * 0.05 * 500 = 1500 GtC at every tau. If the
# +5.7 of the default mode survives, the pool's AGE buys it; if it vanishes,
# its STOCK does (which the inventories contradict). ⚠ The responsive-soil
# input (1 - litter_slow_frac) moves slightly with it (0.90-0.99 of NPP).
# CARVE-OUT PROXY (TS_STOCK_FRAC=<f_ex>, requires TS_FIXED_STOCK=1; CHANGELOG
# 09-29 v): an INERT soil pool carved out of the inventory-matched 1500 GtC
# exchanges nothing, so dynamically it is a SMALLER exchanging passive pool.
# litter_slow_frac is multiplied by f_ex = 1 - (inert fraction), holding the
# exchanging passive stock at 1500 * f_ex. TS_VALUES (env, comma-separated)
# overrides the tau grid. The identity check then compares against the stored
# fixed-stock profile's default row (TS_ID_REF), because the carved default row
# is not the (k) structure.
# USAGE: Rscript calibration/diag_tau_soil_slow_profile.R  (frozen copy; BLAS
#        pinned to 1 by the caller; TS_SMOKE=1 for a smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
TS_DRIVER <- "calibration/diag_tau_soil_slow_profile.R"
TS_TAG    <- "tau_soil_slow_profile"
TS_DATE   <- "20260929"
TS_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
TS_STRUCT <- "hilda_csl3v0ka"
TS_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
TS_PARAM  <- "tau_soil_slow"
TS_DEFAULT <- 500
TS_VALUES <- c(250, 500, 750, 1000, 1500, 2000, 3000, 5000)   # yr
TS_LSF_PARAM   <- "litter_slow_frac"
TS_LSF_DEFAULT <- 0.05
TS_FIXED_STOCK <- identical(Sys.getenv("TS_FIXED_STOCK"), "1")
if (TS_FIXED_STOCK) TS_TAG <- paste0(TS_TAG, "_fixedstock")
TS_STOCK_FRAC <- as.numeric(Sys.getenv("TS_STOCK_FRAC", "1"))   # exchanging share of the passive stock
stopifnot(TS_STOCK_FRAC > 0, TS_STOCK_FRAC <= 1, TS_STOCK_FRAC == 1 || TS_FIXED_STOCK)
if (TS_STOCK_FRAC != 1) TS_TAG <- paste0(TS_TAG, sprintf("_stock%04d", round(1e4 * TS_STOCK_FRAC)))
if (nzchar(Sys.getenv("TS_VALUES"))) TS_VALUES <- as.numeric(strsplit(Sys.getenv("TS_VALUES"), ",")[[1]])
TS_ID_REF <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_20260929.rds")
TS_FREE   <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
TS_MAXIT  <- 3000L
TS_ID_TOL <- 1e-4
TS_CORES  <- 8L
TS_SMOKE  <- identical(Sys.getenv("TS_SMOKE"), "1")
if (TS_SMOKE) { TS_TAG <- paste0(TS_TAG, "_smoke"); TS_VALUES <- c(500, 2000); TS_MAXIT <- 10L }
TS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", TS_TAG, TS_DATE))
COMMIT    <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
DIRTY     <- tryCatch(length(system("git status --porcelain -- R src data calibration", intern = TRUE)) > 0, error = function(e) NA)

md <- readRDS(ccx_mode_file(TS_MODE)); invisible(ccx_apply_pins(md$pins))
tg <- ccx_npp_modern_target()
iF <- match(TS_FREE, md$param_names); stopifnot(!anyNA(iF))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, TS_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
stopifnot(isTRUE(all.equal(bp[[TS_PARAM]], TS_DEFAULT)), TS_DEFAULT %in% TS_VALUES,
          isTRUE(all.equal(bp[[TS_LSF_PARAM]], TS_LSF_DEFAULT)))
# base-parameter overrides for a profile value (recorded in the output so the
# futures driver rebuilds EXACTLY the scored structure)
over_of <- function(v) { o <- setNames(list(v), TS_PARAM)
  if (TS_FIXED_STOCK) o[[TS_LSF_PARAM]] <- TS_LSF_DEFAULT * TS_DEFAULT / v * TS_STOCK_FRAC; o }
prev <- utils::read.csv(TS_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in TS_FREE) p0[[n]] <- r1[[n]]
u0 <- ccx_par_to_unc(unlist(p0)[md$param_names])
stock_slow <- function(b) ccx_const("NPP_GLOBAL_PI") * b$litter_slow_frac * b[[TS_PARAM]]
npp_modern <- function(u, b) {
  pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(b, pv)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  n <- ccx_run_fast(sp, F)$npp; k <- floor(n$t) >= tg$win[1] & floor(n$t) <= tg$win[2]
  mean(n$npp_NH[k] + n$npp_SH[k])
}
one <- function(v) {
  b <- bp; ov <- over_of(v); for (n in names(ov)) b[[n]] <- ov[[n]]
  lp <- ccx_make_logpost(base_params = b, by_stream = TRUE)
  l0 <- lp(u0)
  f <- function(x) { u <- u0; u[iF] <- x; w <- lp(u); if (!is.finite(w)) 1e12 else -as.numeric(w) }
  o <- stats::optim(u0[iF], f, method = "Nelder-Mead", control = list(maxit = TS_MAXIT))
  u <- u0; u[iF] <- o$par; l1 <- lp(u)
  list(value = v, over = ov, frozen = as.numeric(l0), opt = as.numeric(l1), s0 = attr(l0, "streams"), s1 = attr(l1, "streams"),
       stock = stock_slow(b), npp = npp_modern(u, b), par = unlist(ccx_unc_to_par(u)[TS_FREE]),
       evals = o$counts[["function"]], conv = o$convergence)
}
res <- parallel::mclapply(TS_VALUES, one, mc.cores = TS_CORES, mc.preschedule = FALSE)
ok <- !vapply(res, inherits, logical(1), "try-error"); if (!all(ok)) { print(res[!ok]); stop("fork failure") }
ref <- res[[which(TS_VALUES == TS_DEFAULT)]]
# identity: the 09-29 (k) scan's scale-1 optimum was scored under the same structure and vector
lp_chk <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
id_ref <- if (TS_STOCK_FRAC == 1) ref$frozen else {
  st <- readRDS(TS_ID_REF); st[[which(vapply(st, `[[`, numeric(1), "value") == TS_DEFAULT)]]$frozen }
id_d <- as.numeric(lp_chk(u0)) - id_ref
stopifnot(abs(id_d) < TS_ID_TOL)

sink(paste0(TS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s%s, run %s\n", TS_DRIVER, COMMIT, if (isTRUE(DIRTY)) " (DIRTY)" else "", format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  structure %s at v0k basin 1, 11 names at the %s scale-1 optimum; NPP_GLOBAL_PI unscaled (%g GtC/yr)\n",
  TS_STRUCT, basename(TS_PREV), ccx_const("NPP_GLOBAL_PI")))
cat(sprintf("  profile %s in {%s} yr (default %g); other residence times at defaults; rebal = NM maxit %d on {%s}\n",
  TS_PARAM, paste(TS_VALUES, collapse = ", "), TS_DEFAULT, TS_MAXIT, paste(TS_FREE, collapse = ", ")))
cat(sprintf("  mode: %s\n", if (TS_FIXED_STOCK) sprintf("FIXED STOCK -- %s = %g * %g / tau (PI passive stock held)", TS_LSF_PARAM, TS_LSF_DEFAULT, TS_DEFAULT)
  else sprintf("default -- %s fixed at %g (stock grows with tau)", TS_LSF_PARAM, TS_LSF_DEFAULT)))
if (TS_STOCK_FRAC != 1) cat(sprintf("  CARVE-OUT PROXY: exchanging passive stock x%g (= %.0f GtC); identity vs %s default row frozen\n",
  TS_STOCK_FRAC, stock_slow(bp) * TS_STOCK_FRAC, basename(TS_ID_REF)))
cat(sprintf("  logpost natural-log units; stock GtC (PI passive soil); NPP GtC/yr mean %d-%d; no RNG\n", tg$win[1], tg$win[2]))
cat(sprintf("  [identity] default row frozen vs independent rescore: %.2e (tol %.0e)\n\n", id_d, TS_ID_TOL))
cat(sprintf("  %8s %9s %9s %9s %8s %5s %6s\n", TS_PARAM, "stock", "d_frozen", "d_rebal", "NPPmod", "conv", "evals"))
for (r in res) cat(sprintf("  %8g %9.0f %+9.2f %+9.2f %8.2f %5d %6d\n", r$value, r$stock, r$frozen - ref$frozen, r$opt - ref$opt, r$npp, r$conv, r$evals))
for (w in c("s0", "s1")) {
  S <- do.call(rbind, lapply(res, function(r) r[[w]] - ref[[w]])); rownames(S) <- sprintf("%g", TS_VALUES)
  big <- names(sort(apply(abs(S), 2, max), decreasing = TRUE))[1:min(8, ncol(S))]
  cat(sprintf("\n=== streams vs default, %s (8 largest |max|) ===\n", if (w == "s0") "FROZEN" else "REBALANCED"))
  print(round(S[, big, drop = FALSE], 2))
}
cat("\n=== 11 fitted names, rebalanced ===\n"); P <- do.call(rbind, lapply(res, `[[`, "par")); rownames(P) <- TS_VALUES; print(signif(P, 4))
S1 <- do.call(rbind, lapply(res, function(r) r$s1 - ref$s1))
R <- data.frame(value = TS_VALUES, stock = sapply(res, `[[`, "stock"), d_frozen = sapply(res, `[[`, "frozen") - ref$frozen,
                d_rebal = sapply(res, `[[`, "opt") - ref$opt, npp_modern = sapply(res, `[[`, "npp"),
                conv = sapply(res, `[[`, "conv"), P, S1, check.names = FALSE,
                provenance = sprintf("%s @%s; %s v0k basin1; NPP unscaled; fixed_stock %s; stock_frac %g; NM %d on 11; no RNG", TS_DRIVER, COMMIT, TS_STRUCT, TS_FIXED_STOCK, TS_STOCK_FRAC, TS_MAXIT))
utils::write.csv(R, paste0(TS_OUT, ".csv"), row.names = FALSE); saveRDS(res, paste0(TS_OUT, ".rds"))
cat(sprintf("  saved %s.{log,csv,rds}\n", TS_OUT)); sink()
