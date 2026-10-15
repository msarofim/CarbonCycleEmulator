#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_redesign_price.R -- THE REDESIGNED INTERANNUAL CUT, PRICED AT BASIN B (RULED 2026-10-07 c, Marcus: "Price a
# redesigned cut (Recommended)"; notes/handoff_2026-10-07b_obj17_landed.md s. 3). No build; stage 2 is not refitted.
#
# THE REDESIGN = objective #17 as landed (hilda_csl3v0kaidgbemw: the low-pass land row; the slope row in the module) +
#   (i)  the DETRENDED ENSO index (enso_index "detrend", the 09-29 f structure axis, CCX_ENSO_INDEX_CODES). The shipped
#        index trends +0.0083 K/yr over 1959-2024, and the limb carried that trend into the CO2 level rows at LOW
#        frequency (CHANGELOG 10-07 b; memory interannual_name_needs_trendless_forcing);
#   (ii) `gcb_ocean_sink` scored on its LOW-PASS part, the land row's construction (R/likelihood.R LIK_LAND_LOWPASS_DF):
#        row + |(I-P)e|^2 / (2 sd^2), P the projector onto [1, ns(year, 6)], at the row's own sd LIK_GCB_OCEAN_SD --
#        what diag_obj17_lowpass_ocean_price.R priced.
# BOTH ARE EMULATED, NOT BUILT. (i) is a switch the objective already reads (the base parameter `enso_index`; absent =
# the shipped index). (ii) wraps ccx_loglik() IN THIS PROCESS ONLY: with RP_OCEAN_LP on, the ocean row gains its high
# part's cost, computed from the row's OWN residuals as scored (ccx_loglik(residuals = TRUE)) -- no second copy of the
# row -- and the full row and the cost are kept (RP_LAST), so ONE run scores both definitions. Off, the wrapper hands the
# call to the shipped function untouched.
#
# THE FOUR PRICES (the handoff's s. 3 items), all at basin B's vector (RULED 10-07: "B: better likelihood (Recommended)"):
#   1 B1 / B2 / B3  the index switch at B's own module pins P0 (= #17's stage 1 at hilda33p), unrefitted (B1), then with
#                the five land names re-optimized (B2: diag_obj17_price.R's block and method, whitened by B's stored Hessian
#                block, BFGS + Nelder-Mead rounds), then with those five + the ocean pair (B3: pump_grad, kz), each scored
#                with the ocean row both ways;
#   2 STAGE 1    the module (lag, one land scale, w_enso_l2) refitted under the detrended index at B, and at hilda33p where
#                #17's stage 1 ran, by a MIRROR of fit_iav_module.R steps 0-4. (fit_iav_module.R cannot: its gate requires
#                the base to reproduce its stored rows, and a switched index does not. The mirror runs that gate on the
#                base AS STORED, then switches.) CONTROL: under the SHIPPED index the mirror must reproduce both stored
#                stage-1 runs, hilda33p's and the dry run's one-pass check at B;
#   3 RESISTANCE moving the module P0 -> P1 (the one-pass check at B: w 14.73 -> 16.71) and P0 -> P1d (item 2's answer at
#                B), unrefitted, on the WHOLE main objective, under {shipped, detrended} x {ocean row year by year,
#                low-pass}: the totals and every row;
#   3b RATCHET   the ocean pair (pump_grad, kz: 94 % of the slope's drop at B) re-optimized at P0 and at P1, under #17 as
#                landed and under the redesign: does a higher w make the main objective weaken the ocean's ENSO response
#                again (the mechanism behind the one-pass check's +1.55 sigma)? Read: the pair's move P0 -> P1 in B's own
#                sd, the resistance with the pair re-optimized, and the model's ENSO ocean slope at each optimum;
#   4 FUTURES    CO2 in 2300 (SSP5-8.5; vvH spliced on the historical emissions) at hilda33p, B, B1, B2 and B3 (br_futures()).
# GATES (the driver stops on any): B reproduces its stored logpost and rows under its own label; the wrapper changes ONLY
# the ocean row, and that row matches diag_obj17_lowpass_ocean_price.R's (dg path); the shipped index's 1959-2024 trend
# is the recorded +0.00831 K/yr; the objective path under the detrended index reproduces diag_obj17_resistance_split.R's
# detrend rows (dg path) at P0 and P1; the shipped resistance reproduces diag_obj17_iterate_price.R's row by row and
# diag_obj17_lowpass_ocean_price.R's low-pass total; the stage-1 mirror reproduces both stored runs (CONTROL).
# ⛔ ADOPTS NOTHING; nothing changes outside this process. No RNG.
# Usage: Rscript calibration/diag_iav_redesign_price.R   (CCX_RP_WORKERS, default 6; CCX_RP_SMOKE=1 tiny budgets, gates
#        that need a converged fit only reported; CCX_RP_OUTDIR overrides outputs/diagnostics)
# OUTPUTS: <outdir>/iav_redesign_price_<date>.{log,rds}
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
RP_DRIVER   <- "calibration/diag_iav_redesign_price.R"
RP_MODE_B   <- file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds")
RP_MODE_B_MD5 <- "081eb16f4fe718692004fb1cf9645891"          # CHANGELOG 10-07 (b) tables; the dry run's check base_md5
RP_CANON    <- "hilda33p"                                    # where #17's stage 1 ran
RP_S1       <- CCX_MODE_OBJ17_MODULE_FILE                    # #17's stage 1 at hilda33p (the shipped index)
RP_CHECK_B  <- file.path("outputs", "diagnostics", "obj17_dryrun_20261006", "iav_module_check_DRYRUN.rds")   # stage 1 at B
RP_LOWPASS  <- file.path("outputs", "diagnostics", "obj17_lowpass_ocean_price_20261007.rds")
RP_SPLIT_D  <- file.path("outputs", "diagnostics", "obj17_resistance_split_20261007_detrend.rds")
RP_ITER     <- file.path("outputs", "diagnostics", "obj17_iterate_price_20261007.rds")
RP_INDEX    <- "detrend"                                     # the redesign's index (CCX_ENSO_INDEX_CODES)
RP_SHIPPED  <- "demean"                                      # the shipped index (RULING A)
RP_OCEAN_DF <- LIK_LAND_LOWPASS_DF                           # the cut's own projector, applied unchanged to the ocean row
RP_OCEAN_SD <- LIK_GCB_OCEAN_SD                              # the ocean row's own sd
RP_OCEAN_ROW <- "gcb_ocean_sink"
RP_FIVE     <- c("gcb_ocean_sink", "co2_level_MLO", "co2_level_SPO", "co2_seasonal_MLO", "co2_seasonal_SPO")  # the split's
RP_REST     <- c("beta_max", "fert_k", "luc_scale", "imb_share_land", "ndep_ret")   # diag_obj17_price.R's B2 block
# THE OCEAN PAIR: the two names that carry 94 % of the model's ENSO ocean slope's drop at B (pump_grad 84.1 %, kz 9.7 %;
# diag_obj17_slope_attribution.R, CHANGELOG 10-07 a). h_ml (1.3 % at B) is left out: its Hessian entry is UNSTABLE at B.
RP_OCEAN_BLK <- c("pump_grad", "kz")
RP_SLOPE_TOL <- 1e-6           # the slope gate vs diag_obj17_iterate_price.R (GtC/yr per K; the obs se is 0.0246)
RP_REPRO_TOL <- 1e-5           # reproduce-gates: the objective's ~1e-6 noise floor (memory objective_noise_floor_optimum_on_spike)
RP_CTRL_TOL  <- 0.01           # CONTROL: each module name within 0.01 of #17's stage-1 sigma, 10x inside the RULED 0.1 check
RP_TREND_WIN <- c(1959L, 2024L)                              # the window CHANGELOG 10-07 (b) measured the trend on
RP_TREND_SHIPPED <- 0.00831; RP_TREND_DIGITS_TOL <- 5e-6     # K/yr as recorded there (3 s.f., so +/- half a unit)
RP_TOP      <- 8L                                            # rows printed per table, beyond the five
RP_SMOKE    <- identical(Sys.getenv("CCX_RP_SMOKE", ""), "1")
RP_WORKERS  <- as.integer(Sys.getenv("CCX_RP_WORKERS", "6"))
RP_OUTDIR   <- Sys.getenv("CCX_RP_OUTDIR", file.path("outputs", "diagnostics"))
# B2 = diag_obj17_price.R's P17_* values (= lib_block_reopt.R's defaults)
RP_MODE_TOL <- 0.1; RP_PULL_H <- 0.1; RP_NDEPS <- 0.01; RP_RELTOL <- 1e-12
RP_BFGS_MAXIT <- if (RP_SMOKE) 2L else 200L; RP_NM_MAXIT <- if (RP_SMOKE) 6L else 1500L; RP_ROUNDS <- if (RP_SMOKE) 1L else 3L
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # the refit read's futures (its s. 5)
# STAGE 1 = fit_iav_module.R's constants, VERBATIM at 60eba2a (the CONTROL below proves the mirror reproduces it)
IAV_GAMMA <- c("gamma_enso_land_NH", "gamma_enso_land_SH"); IAV_OCEAN <- "w_enso_l2"; IAV_LAG <- "lag_enso_land"
stopifnot(identical(CCX_IAV_MODULE_NAMES, c(IAV_LAG, IAV_GAMMA, IAV_OCEAN)))
IAV_RATIO_MODE <- "hilda33p"; IAV_RATIO_MD5 <- "525404989a20ece51ec8bd088c7d4638"
IAV_LAG_MAX  <- CCX_ENSO_LAG_MAX; IAV_W_MAX <- CCX_PARAM_TABLE[[IAV_OCEAN]]$hi   # read BEFORE any pin removes the name
IAV_LAGS_SUP <- seq(0.5, 10, by = 0.25); IAV_NM_MAXIT <- 400L; IAV_NM_RELTOL <- 1e-8
IAV_PROF_LAGS <- c(2, 3, 4, 4.5, 5, 5.5, 6.5, 7, 7.5, 8, 9, 10); IAV_PROF_MAXIT <- 150L
# IAV_REPRO_TOL RULED (Marcus 2026-10-13: "Use CCX_REPRO_TOL (Recommended)"; CHANGELOG 2026-10-13 o): was a literal 1e-5 (10-07 measured 1e-10 to 2.7e-10, so that record's verdicts stand)
IAV_SIG <- c(one = 0.5, two = 2); IAV_H_STEP <- c(L = 0.05, s = 0.01, w = 0.25); IAV_REPRO_TOL <- CCX_REPRO_TOL; IAV_XLAGS <- -6:18
if (RP_SMOKE) { IAV_LAGS_SUP <- c(1, 3, 6, 9); IAV_NM_MAXIT <- 8L; IAV_PROF_LAGS <- c(4, 7); IAV_PROF_MAXIT <- 4L }
RP_TAG  <- paste0(format(Sys.Date(), "%Y%m%d"), if (RP_SMOKE) "_SMOKE" else "")
RP_OUT  <- file.path(RP_OUTDIR, sprintf("iav_redesign_price_%s", RP_TAG))
COMMIT  <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))        # br_prec, br_u_of_par, br_futures
`%||%` <- function(a, b) if (is.null(a)) b else a
LOGCON <- file(paste0(RP_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | basin B %s | the redesign: ENSO index '%s' + %s low-pass (df %d, sd %g) | %d workers%s\n",
            RP_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), RP_MODE_B, RP_INDEX, RP_OCEAN_ROW, RP_OCEAN_DF,
            RP_OCEAN_SD, RP_WORKERS, if (RP_SMOKE) " | ⚠ SMOKE: tiny budgets, NOT A RESULT" else ""))

# ---- THE WRAPPER: the low-pass ocean row, emulated in this process -------------------
.ccx_loglik_shipped <- ccx_loglik
RP_OCEAN_LP <- FALSE
RP_LAST <- new.env()
ccx_loglik <- function(out, obs, err, luc = NULL, deep = NULL, ocean_grad = NULL, by_stream = FALSE, d14c_mid = NULL,
                       npp = NULL, residuals = FALSE) {
  if (!RP_OCEAN_LP)
    return(.ccx_loglik_shipped(out, obs, err, luc = luc, deep = deep, ocean_grad = ocean_grad, by_stream = by_stream,
                               d14c_mid = d14c_mid, npp = npp, residuals = residuals))
  st <- .ccx_loglik_shipped(out, obs, err, luc = luc, deep = deep, ocean_grad = ocean_grad, by_stream = TRUE,
                            d14c_mid = d14c_mid, npp = npp, residuals = TRUE)
  RES <- attr(st, "residuals")
  if (!RP_OCEAN_ROW %in% names(st) || length(RES[[RP_OCEAN_ROW]]) != 1L) stop("the wrapper: no single ", RP_OCEAN_ROW, " residual series")
  e <- RES[[RP_OCEAN_ROW]][[1]]
  # the row's own years, exactly as ccx_loglik() merges them (GCB x the calendar-year flux x E_LUC)
  lu <- if (is.null(luc)) data.frame(year = obs$gcb$year, eluc = obs$gcb$luc) else luc
  g  <- merge(merge(as.data.frame(obs$gcb)[, c("year", "ocean_sink", "land_sink")], ccx_calendar_flux(out), by = "year"), lu, by = "year")
  if (length(e) != nrow(g)) stop("the wrapper: ", length(e), " ocean residuals for ", nrow(g), " scored GCB years")
  full <- st[[RP_OCEAN_ROW]]
  if (abs(sum(stats::dnorm(e, 0, RP_OCEAN_SD, log = TRUE)) - full) > 1e-8) stop("the wrapper: the residuals do not rebuild the ocean row")
  hc <- ccx_land_highpass_cost(e, g$year, RP_OCEAN_DF, RP_OCEAN_SD)
  assign("full_row", full, envir = RP_LAST); assign("high_cost", hc, envir = RP_LAST); assign("n", length(e), envir = RP_LAST)
  st[[RP_OCEAN_ROW]] <- full + hc
  if (!isTRUE(residuals)) attr(st, "residuals") <- NULL
  if (by_stream) return(st)
  ll <- sum(unlist(st)); if (!is.finite(ll)) -Inf else ll
}

# ---- basin B, its pins, the references ---------------------------------------------
if (!identical(unname(tools::md5sum(RP_MODE_B)), RP_MODE_B_MD5)) stop("basin B's file is not the one the 10-07 tables name")
MD_B <- readRDS(RP_MODE_B); SPF_B <- ccx_spinup_from_label(ccx_mode_spinup(MD_B))
stopifnot(identical(ccx_mode_struct(MD_B), CCX_MODE_OBJ17_STRUCT))
OBS <- ccx_prepare_obs(); GRO <- ccx_iav_growth_obs()
P0  <- ccx_mode_pins(MD_B); P0 <- stats::setNames(as.numeric(unclass(P0)), names(P0))
S1  <- readRDS(RP_S1); CKB <- readRDS(RP_CHECK_B); LOWP <- readRDS(RP_LOWPASS); SPD <- readRDS(RP_SPLIT_D); ITER <- readRDS(RP_ITER)
if (!identical(CKB$provenance$base_md5, RP_MODE_B_MD5)) stop("the dry run's check was not run at basin B's file")
P1  <- P0; P1[CCX_IAV_MODULE_NAMES] <- as.numeric(CKB$pins[CCX_IAV_MODULE_NAMES])
SD1 <- S1$laplace$sd                                           # #17's stage-1 sigma: the RULED check's unit
mr <- readRDS(ccx_mode_file(IAV_RATIO_MODE))
if (!identical(unname(tools::md5sum(ccx_mode_file(IAV_RATIO_MODE))), IAV_RATIO_MD5)) stop("the ratio file is not the one the ruling names")
G0 <- vapply(IAV_GAMMA, function(n) mr$par_mode[[n]], 0)
cat(sprintf("basin B: struct %s, stored logpost %.6f; module pins P0 %s\n  P1 (the one-pass check at B, %s): %s\n",
            ccx_mode_struct(MD_B), MD_B$logpost, paste(sprintf("%s %.4f", CCX_IAV_MODULE_NAMES, P0[CCX_IAV_MODULE_NAMES]), collapse = ", "),
            RP_CHECK_B, paste(sprintf("%.4f", P1[CCX_IAV_MODULE_NAMES]), collapse = ", ")))

#' ONE evaluation of basin B's vector on #17's main objective with `pins`, the ENSO index `index` and the ocean row
#' low-passed or not; `over` overrides fitted names (natural values). Gate, pins and the wrapper's switch are undone on
#' exit. Returns the logpost, the likelihood, the rows as scored, and the ocean row both ways (full and low-pass).
with_objective <- function(pins, index, FUN) {
  g <- ccx_apply_gate(ccx_mode_struct(MD_B)); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_mode_base(MD_B); for (n in names(pins)) bp[[n]] <- pins[[n]]; bp$pump_mode <- MD_B$pump_mode
  if (index != RP_SHIPPED) bp$enso_index <- CCX_ENSO_INDEX_CODES[[index]]
  stopifnot(identical(ccx_enso_index_of(bp), index))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF_B, obs = OBS)
  old <- RP_OCEAN_LP; RP_OCEAN_LP <<- TRUE; on.exit(RP_OCEAN_LP <<- old, add = TRUE)
  ev <- function(over = NULL) {
    pm <- ccx_mode_par_with_pins(MD_B); for (n in names(over)) pm[[n]] <- over[[n]]
    for (k in c("full_row", "high_cost")) if (exists(k, envir = RP_LAST, inherits = FALSE)) rm(list = k, envir = RP_LAST)
    v <- lp(ccx_par_to_unc(pm))
    if (!is.finite(v)) return(list(logpost_lp = -Inf, logpost_full = -Inf))
    s <- attr(v, "streams"); s <- stats::setNames(as.numeric(s), names(s))
    hc <- get("high_cost", envir = RP_LAST); full <- get("full_row", envir = RP_LAST)
    st_full <- s; st_full[[RP_OCEAN_ROW]] <- full
    list(logpost_lp = as.numeric(v), lik_lp = attr(v, "loglik"), prior = as.numeric(v) - attr(v, "loglik"),
         lik_full = attr(v, "loglik") - hc, logpost_full = as.numeric(v) - hc, st_lp = s, st_full = st_full, high_cost = hc)
  }
  FUN(ev)
}
score <- function(pins, index, over = NULL) with_objective(pins, index, function(ev) ev(over))
# the module's four names at `vals` on a parameter list pair (fit_iav_module.R's vec_at, for the four names)
set_names <- function(V, vals) { for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V$luc_scale <- V$pm$luc_scale; V$bomb_total <- V$pm$bomb_total; V }
with_index <- function(V, index) { if (index != RP_SHIPPED) V$p$enso_index <- CCX_ENSO_INDEX_CODES[[index]]
  stopifnot(identical(ccx_enso_index_of(V$p), index)); V }
row_table <- function(d, keep = RP_FIVE, top = RP_TOP) {   # the five, then the largest of the rest
  rest <- setdiff(names(d), keep); rest <- rest[order(-abs(d[rest]))][seq_len(min(top, length(rest)))]
  d[c(keep, rest)] }

cat("\n=== 0. GATES ===\n")
R17 <- with_objective(P0, RP_SHIPPED, function(ev) {
  RP_OCEAN_LP <<- FALSE; off <- environment(ev)$lp(ccx_par_to_unc(ccx_mode_par_with_pins(MD_B))); RP_OCEAN_LP <<- TRUE
  list(off = off, on = ev()) })
off_st <- unlist(attr(R17$off, "streams"))
cat(sprintf("  B under its own label, the shipped index, the wrapper OFF: logpost %.6f vs stored %.6f (%+.1e); rows max |diff| %.1e\n",
            as.numeric(R17$off), MD_B$logpost, as.numeric(R17$off) - MD_B$logpost, max(abs(off_st[names(MD_B$streams)] - unlist(MD_B$streams)))))
if (abs(as.numeric(R17$off) - MD_B$logpost) > RP_REPRO_TOL || max(abs(off_st[names(MD_B$streams)] - unlist(MD_B$streams))) > RP_REPRO_TOL)
  stop("basin B does not reproduce its stored logpost / rows")
REF <- R17$on
oth <- setdiff(names(off_st), RP_OCEAN_ROW)
same_rest <- identical(REF$st_lp[oth], off_st[oth]); same_full <- identical(REF$st_full[[RP_OCEAN_ROW]], off_st[[RP_OCEAN_ROW]])
cat(sprintf("  the wrapper ON: the other %d rows identical() to OFF: %s; the full ocean row identical(): %s\n", length(oth), same_rest, same_full))
if (!same_rest || !same_full) stop("the wrapper changes more than the ocean row")
g_lp <- REF$st_lp[[RP_OCEAN_ROW]] - LOWP$B$r0[["ocean_lowpass"]]; g_hc <- REF$high_cost - LOWP$B$r0[["ocean_high_cost"]]
cat(sprintf("  the low-pass ocean row %.6f vs diag_obj17_lowpass_ocean_price.R's %.6f (%+.1e); its high part's cost %.6f vs %.6f (%+.1e)\n",
            REF$st_lp[[RP_OCEAN_ROW]], LOWP$B$r0[["ocean_lowpass"]], g_lp, REF$high_cost, LOWP$B$r0[["ocean_high_cost"]], g_hc))
if (abs(g_lp) > RP_REPRO_TOL || abs(g_hc) > RP_REPRO_TOL) stop("the emulated low-pass ocean row is not the priced one")
tr_of <- function(index) { Fx <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF, enso_index = index)
  k <- Fx$year >= RP_TREND_WIN[1] & Fx$year <= RP_TREND_WIN[2]; tt <- Fx$t[k]
  c(trend = unname(stats::coef(stats::lm(Fx$enso[k] ~ tt))[2]), mean = mean(Fx$enso[k])) }
TR <- rbind(shipped = tr_of(RP_SHIPPED), redesign = tr_of(RP_INDEX))
cat(sprintf("  the ENSO index over %d-%d: shipped trend %+.6f K/yr, mean %+.4f K | %s trend %+.6f K/yr, mean %+.4f K\n", RP_TREND_WIN[1],
            RP_TREND_WIN[2], TR["shipped", "trend"], TR["shipped", "mean"], RP_INDEX, TR["redesign", "trend"], TR["redesign", "mean"]))
if (abs(TR["shipped", "trend"] - RP_TREND_SHIPPED) > RP_TREND_DIGITS_TOL) stop("the shipped index's trend is not the recorded one")
D0 <- score(P0, RP_INDEX); D1 <- score(P1, RP_INDEX)
g_d <- max(abs(c(D0$st_full[RP_FIVE] - SPD$B$split0[RP_FIVE, "row"], D1$st_full[RP_FIVE] - SPD$B$split1[RP_FIVE, "row"])))
g_dh <- max(abs(c(D0$high_cost - SPD$B$split0[RP_OCEAN_ROW, "high_cost"], D1$high_cost - SPD$B$split1[RP_OCEAN_ROW, "high_cost"])))
cat(sprintf("  the objective under '%s' vs diag_obj17_resistance_split.R's detrend run (dg path), P0 and P1: the five rows max |diff| %.1e; the ocean's high-part cost %.1e\n",
            RP_INDEX, g_d, g_dh))
if (g_d > RP_REPRO_TOL || g_dh > RP_REPRO_TOL) stop("the objective path and the dg path disagree under the switched index")

cat(sprintf("\n=== 1. THE INDEX SWITCH AT B, module at P0: B1 unrefitted; B2 %s re-optimised; B3 + %s ===\n",
            paste(RP_REST, collapse = ", "), paste(RP_OCEAN_BLK, collapse = ", ")))
B1 <- D0
d1_lp <- B1$st_lp - REF$st_lp[names(B1$st_lp)]; d1_full <- B1$st_full - REF$st_full[names(B1$st_full)]
cat(sprintf("  B1 likelihood: %+.4f on the redesign's rows (ocean low-pass) | %+.4f on #17's rows (ocean year by year)\n",
            B1$lik_lp - REF$lik_lp, B1$lik_full - REF$lik_full))
cat("  per row (redesign's rows):\n"); print(round(row_table(d1_lp), 3))
#' Re-optimize `block` at basin B's vector with the module at `pins` under `index`, maximizing the logpost with the ocean
#' row low-passed (rows "lp", the redesign's) or year by year (rows "full", #17's). Whitened by B's stored Hessian block,
#' BFGS + Nelder-Mead rounds until every whitened slope < RP_MODE_TOL: diag_obj17_price.R's B2 method, for any block.
reopt <- function(pins, index, block, rows, what) {
  U <- chol(br_prec(MD_B, block)); u0 <- br_u_of_par(MD_B, block); key <- if (rows == "lp") "logpost_lp" else "logpost_full"
  par_of_z <- function(z) { uu <- u0 + backsolve(U, z)
    stats::setNames(as.list(vapply(block, function(n) .from_unc(uu[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)), block) }
  t0 <- Sys.time()
  o <- with_objective(pins, index, function(ev) {
    f <- function(z) { v <- tryCatch(ev(par_of_z(z))[[key]], error = function(e) -Inf); if (is.finite(v)) -v else 1e10 }
    slope <- function(z) vapply(seq_along(z), function(i) { e <- rep(0, length(z)); e[i] <- RP_PULL_H
      (f(z + e) - f(z - e)) / (2 * RP_PULL_H) }, 0)
    z <- rep(0, length(block)); s <- slope(z); s_start <- s; rounds <- 0L
    while (max(abs(s)) >= RP_MODE_TOL && rounds < RP_ROUNDS) {
      rounds <- rounds + 1L
      o1 <- stats::optim(z, f, method = "BFGS", control = list(ndeps = rep(RP_NDEPS, length(z)), reltol = RP_RELTOL, maxit = RP_BFGS_MAXIT))
      o2 <- stats::optim(rep(0, length(z)), function(w) f(o1$par + w), method = "Nelder-Mead", control = list(reltol = RP_RELTOL, maxit = RP_NM_MAXIT))
      z <- o1$par + o2$par; s <- slope(z)
    }
    list(z = z, s = s, s_start = s_start, rounds = rounds, at = ev(par_of_z(z))) })
  o$par <- unlist(par_of_z(o$z)); o$u <- u0 + backsolve(U, o$z); o$converged <- max(abs(o$s)) < RP_MODE_TOL
  o$block <- block; o$rows <- rows; o$index <- index; o$minutes <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  cat(sprintf("  %-34s %d round(s), %.1f min, max whitened slope %.3f -> %.3f (converged < %.1f: %s)\n", what, o$rounds, o$minutes,
              max(abs(o$s_start)), max(abs(o$s)), RP_MODE_TOL, o$converged))
  o
}
show_block <- function(o) cat(sprintf("    the block: %s\n", paste(sprintf("%s %.5g (B %.5g)", o$block, o$par,
                                                                       vapply(o$block, function(n) MD_B$par_mode[[n]], 0)), collapse = "; ")))
show_rows <- function(d) { cat("    per row (the redesign's rows):\n"); print(round(row_table(d), 3))
  SEAS <- grep("seasonal", names(d), value = TRUE)
  cat(sprintf("    of which the seasonal rows %+.3f, the CO2 level rows %+.3f, the two GCB rows %+.3f, the ice cores %+.3f\n", sum(d[SEAS]),
              sum(d[grep("^co2_level_", names(d))]), sum(d[c("gcb_ocean_sink", "gcb_land_sink")]), sum(d[grep("icecore", names(d))]))) }
O2 <- reopt(P0, RP_INDEX, RP_REST, "lp", "B2 (the five land names)")
O3 <- reopt(P0, RP_INDEX, c(RP_REST, RP_OCEAN_BLK), "lp", "B3 (B2's five + the ocean pair)")
B2 <- O2$at; B3 <- O3$at; parB2 <- as.list(O2$par); B2_CONV <- O2$converged
d2_lp <- B2$st_lp - REF$st_lp[names(B2$st_lp)]; d3_lp <- B3$st_lp - REF$st_lp[names(B3$st_lp)]
for (k in c("B2", "B3")) { o <- if (k == "B2") O2 else O3; at <- o$at
  cat(sprintf("  %s likelihood: %+.4f on the redesign's rows | %+.4f on #17's rows; prior part %+.4f\n", k, at$lik_lp - REF$lik_lp,
              at$lik_full - REF$lik_full, at$prior - REF$prior))
  show_block(o); show_rows(if (k == "B2") d2_lp else d3_lp) }

cat("\n=== 2. STAGE 1 UNDER THE DETRENDED INDEX: the mirror of fit_iav_module.R, at B and at hilda33p ===\n")
#' fit_iav_module.R steps 0-4 at `base_file` under `index`: GATE 0 on the base AS STORED, then the switch, then the basin
#' scan, the optimum, the lag's profile and the Laplace Hessian, line for line. Returns the optimum and its read.
stage1 <- function(base_file, index, what) {
  t0 <- Sys.time(); md <- readRDS(base_file); VB <- dg_vector(base_file)
  if (!identical(VB$p[["gamma_diff"]], 0.25)) stop(what, ": gamma_diff is not the held 0.25 on this base")
  B0 <- c(L = VB$p[[IAV_LAG]], s = VB$p[[IAV_GAMMA[1]]] / G0[[1]], w = VB$p[[IAV_OCEAN]])
  vec_at <- function(V, L, s, w) { blk <- c(stats::setNames(s * G0, IAV_GAMMA), stats::setNames(w, IAV_OCEAN))
    for (n in names(blk)) { if (n %in% names(V$p)) V$p[[n]] <- blk[[n]]; V$pm[[n]] <- blk[[n]] }
    V$p[[IAV_LAG]] <- L; V$pm[[IAV_LAG]] <- L; V$p <- ccx_set_enso(V$p, V$pm); V$luc_scale <- V$pm$luc_scale; V }
  R_ST <- { v <- vec_at(VB, B0[["L"]], B0[["s"]], B0[["w"]]); r <- dg_run(v); r$v <- v; r }
  st0 <- unlist(dg_streams(R_ST, R_ST$v, obs = OBS)); ms0 <- unlist(md$streams); dmax <- max(abs(st0[names(ms0)] - ms0))
  cat(sprintf("\n  --- %s: %s under '%s' ---\n  GATE 0 on the base AS STORED (before the switch): its %d rows through the dg path, max |diff| %.1e (tol %g)\n",
              what, base_file, index, length(ms0), dmax, IAV_REPRO_TOL))
  if (dmax > IAV_REPRO_TOL || !identical(sort(names(st0)), sort(names(ms0)))) stop(what, ": the base does not reproduce its stored rows")
  VS <- with_index(VB, index)
  run_at <- function(L, s, w) { v <- vec_at(VS, L, s, w); r <- dg_run(v); r$v <- v; r }
  R_BASE <- if (index == RP_SHIPPED) R_ST else run_at(B0[["L"]], B0[["s"]], B0[["w"]])
  if (!identical(attr(R_BASE$F, "enso_index"), index)) stop(what, ": the run's forcing does not carry the '", index, "' index")
  GP_BASE <- ccx_iav_growth_pair(R_BASE$out, R_BASE$F, GRO$monthly); SSR_REF <- sum((GP_BASE$mod - GP_BASE$obs)^2)
  mod_ll <- function(r) ccx_iav_module_loglik(r$out, r$F, OBS, ssr_ref = SSR_REF, obs_g = GRO$monthly)
  LL_BASE <- mod_ll(R_BASE)
  f_mod <- function(x) {
    if (!is.finite(sum(x)) || x[1] <= 0 || x[1] >= IAV_LAG_MAX || x[3] <= 0 || x[3] >= IAV_W_MAX) return(1e10)
    v <- tryCatch(mod_ll(run_at(x[1], exp(x[2]), x[3]))[["loglik"]], error = function(e) NA_real_)
    if (is.finite(v)) -v else 1e10 }
  gp_of <- function(r) ccx_iav_growth_pair(r$out, r$F, GRO$monthly)
  R0 <- run_at(B0[["L"]], 0, B0[["w"]]); PP0 <- gp_of(R0)
  sup <- parallel::mclapply(IAV_LAGS_SUP, function(L) { while (sink.number() > 0L) sink()
    gp_of(run_at(L, 1, B0[["w"]]))$mod - PP0$mod }, mc.cores = RP_WORKERS)
  if (any(vapply(sup, inherits, logical(1), "try-error"))) stop(what, ": a superposition run failed")
  SUP <- do.call(rbind, lapply(seq_along(IAV_LAGS_SUP), function(i) { E <- sup[[i]]; y <- PP0$obs - PP0$mod
    s <- max(0, sum(E * y) / sum(E^2)); data.frame(L = IAV_LAGS_SUP[i], s = s, ssr = sum((y - s * E)^2)) }))
  j <- which.min(SUP$ssr)
  sup_dir <- gp_of(run_at(SUP$L[j], SUP$s[j], B0[["w"]]))$mod
  sup_err <- sqrt(mean((PP0$mod + SUP$s[j] * sup[[j]] - sup_dir)^2)); sup_sig <- sqrt(mean(sup_dir^2))
  if (sup_err > 1e-2 * sup_sig) stop(what, ": superposition does not hold at the scan's best")
  x0 <- c(SUP$L[j], log(max(SUP$s[j], 1e-3)), B0[["w"]])
  nm <- stats::optim(x0, f_mod, method = "Nelder-Mead", control = list(maxit = IAV_NM_MAXIT, reltol = IAV_NM_RELTOL))
  OPT <- c(L = nm$par[1], s = exp(nm$par[2]), w = nm$par[3])
  R_OPT <- run_at(OPT[["L"]], OPT[["s"]], OPT[["w"]]); LL_OPT <- mod_ll(R_OPT)
  if (nm$convergence != 0L && !RP_SMOKE) stop(what, ": Nelder-Mead did not converge within ", IAV_NM_MAXIT, " evaluations")
  timing <- function(r) { gp <- gp_of(r); m <- data.frame(k = r$F$year * 12L + r$F$month, nino = r$F$enso)
    xc <- sapply(IAV_XLAGS, function(Lg) { n <- m$nino[match(gp$k - Lg, m$k)]
      c(mod = stats::cor(gp$mod, n, use = "complete.obs"), obs = stats::cor(gp$obs, n, use = "complete.obs")) })
    c(peak_mod = IAV_XLAGS[which.max(xc["mod", ])], peak_obs = IAV_XLAGS[which.max(xc["obs", ])]) }
  TM <- rbind(base = timing(R_BASE), optimum = timing(R_OPT))
  PL <- sort(unique(c(IAV_PROF_LAGS, OPT[["L"]])))
  prof <- parallel::mclapply(PL, function(L) { while (sink.number() > 0L) sink()
    if (abs(L - OPT[["L"]]) < 1e-12) return(c(L = L, s = OPT[["s"]], w = OPT[["w"]], ll = LL_OPT[["loglik"]], conv = 0, n = 0))
    o <- stats::optim(c(log(OPT[["s"]]), OPT[["w"]]), function(y) f_mod(c(L, y[1], y[2])), method = "Nelder-Mead",
                      control = list(maxit = IAV_PROF_MAXIT, reltol = IAV_NM_RELTOL))
    c(L = L, s = exp(o$par[1]), w = o$par[2], ll = -o$value, conv = o$convergence, n = o$counts[["function"]]) }, mc.cores = RP_WORKERS)
  if (any(vapply(prof, inherits, logical(1), "try-error"))) stop(what, ": a profile cell failed")
  PROF <- as.data.frame(do.call(rbind, prof)); PROF$dll <- PROF$ll - LL_OPT[["loglik"]]
  fine <- seq(min(PROF$L), max(PROF$L), by = 0.01); spf <- stats::splinefun(PROF$L, PROF$dll, method = "natural")(fine)
  rng <- function(dl) { k <- fine[spf >= -dl]; c(min(k), max(k)) }
  RNG1 <- rng(IAV_SIG[["one"]]); RNG2 <- rng(IAV_SIG[["two"]])
  th0 <- c(L = OPT[["L"]], s = OPT[["s"]], w = OPT[["w"]]); h <- IAV_H_STEP
  if (floor(th0[["L"]] - h[["L"]]) != floor(th0[["L"]] + h[["L"]]))
    warning(what, ": the lag's steps straddle a whole month (the stencil's kink): the L curvature mixes two segments")
  ll_th <- function(th) { if (th[["L"]] <= 0 || th[["L"]] >= IAV_LAG_MAX || th[["w"]] <= 0 || th[["w"]] >= IAV_W_MAX || th[["s"]] <= 0) return(NA_real_)
    mod_ll(run_at(th[["L"]], th[["s"]], th[["w"]]))[["loglik"]] }
  pts <- list(c0 = th0)
  for (a in names(th0)) { e <- th0; e[[a]] <- e[[a]] + h[[a]]; pts[[paste0(a, "+")]] <- e
                          e <- th0; e[[a]] <- e[[a]] - h[[a]]; pts[[paste0(a, "-")]] <- e }
  for (pr in utils::combn(names(th0), 2, simplify = FALSE)) for (sg in list(c(1, 1), c(1, -1), c(-1, 1), c(-1, -1))) {
    e <- th0; e[[pr[1]]] <- e[[pr[1]]] + sg[1] * h[[pr[1]]]; e[[pr[2]]] <- e[[pr[2]]] + sg[2] * h[[pr[2]]]
    pts[[sprintf("%s%s%s%s", pr[1], if (sg[1] > 0) "+" else "-", pr[2], if (sg[2] > 0) "+" else "-")]] <- e }
  LLP <- unlist(parallel::mclapply(pts, function(th) { while (sink.number() > 0L) sink(); ll_th(th) }, mc.cores = RP_WORKERS))
  names(LLP) <- names(pts); if (anyNA(LLP)) stop(what, ": a Hessian point left the support")
  H <- matrix(0, 3, 3, dimnames = list(names(th0), names(th0)))
  for (a in names(th0)) H[a, a] <- (LLP[[paste0(a, "+")]] - 2 * LLP[["c0"]] + LLP[[paste0(a, "-")]]) / h[[a]]^2
  for (pr in utils::combn(names(th0), 2, simplify = FALSE)) { a <- pr[1]; b <- pr[2]; k <- function(x, y) LLP[[sprintf("%s%s%s%s", a, x, b, y)]]
    H[a, b] <- H[b, a] <- (k("+", "+") - k("+", "-") - k("-", "+") + k("-", "-")) / (4 * h[[a]] * h[[b]]) }
  ev <- eigen(H, symmetric = TRUE, only.values = TRUE)$values
  if (any(ev >= 0) && !RP_SMOKE) stop(what, ": the module's Hessian is not negative definite at the optimum")
  SD <- if (all(ev < 0)) sqrt(diag(solve(-H))) else c(L = NA_real_, s = NA_real_, w = NA_real_)
  PINS <- c(lag_enso_land = OPT[["L"]], gamma_enso_land_NH = OPT[["s"]] * G0[[1]], gamma_enso_land_SH = OPT[["s"]] * G0[[2]], w_enso_l2 = OPT[["w"]])
  cat(sprintf("  basin scan: L %.2f, s %.3f (superposition rms %.1e of %.3f); Nelder-Mead %d evaluations, convergence %d\n",
              SUP$L[j], SUP$s[j], sup_err, sup_sig, nm$counts[["function"]], nm$convergence))
  cat(sprintf("  OPTIMUM: L %.4f months, s %.5f, w %.4f | module loglik %+.4f vs the base (SSR %.4f -> %.4f; growth r %.4f -> %.4f; slope row %+.4f -> %+.4f)\n",
              OPT[["L"]], OPT[["s"]], OPT[["w"]], LL_OPT[["loglik"]] - LL_BASE[["loglik"]], LL_BASE[["ssr"]], LL_OPT[["ssr"]],
              LL_BASE[["r"]], LL_OPT[["r"]], LL_BASE[["slope_row"]], LL_OPT[["slope_row"]]))
  cat(sprintf("  the lag: 1-sigma %.2f-%.2f, 2-sigma %.2f-%.2f months%s; Laplace 1-sigma L %.3f, s %.4f, w %.3f (eigenvalues %s); growth peak %+d months (record %+d) | %.1f min\n",
              RNG1[1], RNG1[2], RNG2[1], RNG2[2], if (RNG2[1] <= min(fine) || RNG2[2] >= max(fine)) " (⚠ 2-sigma reaches the grid's end: a bound)" else "",
              SD[["L"]], SD[["s"]], SD[["w"]], paste(signif(ev, 3), collapse = "/"), TM["optimum", "peak_mod"], TM["optimum", "peak_obs"],
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  list(what = what, base_file = base_file, base_md5 = unname(tools::md5sum(base_file)), index = index, base_values = B0,
       ssr_ref = SSR_REF, x0 = x0, optimum = OPT, pins = PINS, loglik = rbind(base = LL_BASE, optimum = LL_OPT), nm = nm[c("par", "value", "counts", "convergence")],
       scan = SUP, profile = PROF, lag_1sigma = RNG1, lag_2sigma = RNG2, laplace_sd = SD, hessian = H, hess_eigen = ev, timing = TM)
}
ST <- list(canon_shipped = stage1(ccx_mode_file(RP_CANON), RP_SHIPPED, "CONTROL hilda33p, shipped"),
           B_shipped     = stage1(RP_MODE_B, RP_SHIPPED, "CONTROL basin B, shipped"),
           canon_detrend = stage1(ccx_mode_file(RP_CANON), RP_INDEX, "hilda33p, detrended"),
           B_detrend     = stage1(RP_MODE_B, RP_INDEX, "basin B, detrended"))
zmove <- function(a, b) (a - b) / SD1[names(a)]                 # in #17's stage-1 sigma (the RULED check's unit)
ctl <- rbind(canon = zmove(ST$canon_shipped$optimum, S1$optimum), B = zmove(ST$B_shipped$optimum, CKB$optimum))
cat("\n  CONTROL: the mirror under the shipped index vs the stored stage-1 runs, in #17's stage-1 sigma:\n"); print(signif(ctl, 3))
cat(sprintf("  (stored: hilda33p %s @%s; basin B %s @%s)\n", RP_S1, S1$provenance$commit, RP_CHECK_B, CKB$provenance$commit))
if (max(abs(ctl)) > RP_CTRL_TOL && !RP_SMOKE) stop("the stage-1 mirror does not reproduce the stored runs (CONTROL)")
cat("\n  THE INDEX SWITCH's MOVE on stage 1 (detrended - shipped, same base), in #17's stage-1 sigma:\n")
mv <- rbind(hilda33p = zmove(ST$canon_detrend$optimum, ST$canon_shipped$optimum), basin_B = zmove(ST$B_detrend$optimum, ST$B_shipped$optimum),
            `B detrended vs #17's stage 1` = zmove(ST$B_detrend$optimum, S1$optimum))
print(round(mv, 3))
tab <- t(vapply(ST, function(x) c(x$optimum, x$lag_1sigma, x$laplace_sd), numeric(8)))
colnames(tab) <- c("L", "s", "w", "L_1sig_lo", "L_1sig_hi", "sd_L", "sd_s", "sd_w"); print(round(tab, 4))
P1d <- P0; P1d[CCX_IAV_MODULE_NAMES] <- as.numeric(ST$B_detrend$pins[CCX_IAV_MODULE_NAMES])

cat("\n=== 3. THE RESISTANCE TO THE MODULE's MOVE, on the WHOLE main objective at B, unrefitted ===\n")
S <- list(shipped = list(P0 = REF, P1 = score(P1, RP_SHIPPED), P1d = score(P1d, RP_SHIPPED)),
          detrend = list(P0 = D0, P1 = D1, P1d = score(P1d, RP_INDEX)))
res_of <- function(ix, to, rows) { a <- S[[ix]]$P0; b <- S[[ix]][[to]]; k <- if (rows == "lp") "st_lp" else "st_full"; b[[k]] - a[[k]][names(b[[k]])] }
RS <- list()
for (to in c("P1", "P1d")) for (ix in names(S)) for (rows in c("full", "lp")) RS[[paste(to, ix, rows, sep = "_")]] <- res_of(ix, to, rows)
g_it <- max(abs(RS$P1_shipped_full[names(ITER$B$rows)] - ITER$B$rows)); g_tot <- sum(RS$P1_shipped_full) - ITER$B$d_lik
g_lpt <- sum(RS$P1_shipped_lp) - LOWP$B$resistance_lowpass
g_sp <- max(abs(RS$P1_detrend_full[RP_FIVE] - SPD$B$change[RP_FIVE, "row"]))
g_spl <- RS$P1_detrend_lp[[RP_OCEAN_ROW]] - SPD$B$change[RP_OCEAN_ROW, "lowpass"]
cat(sprintf("  GATES (P0 -> P1): shipped, year by year, vs diag_obj17_iterate_price.R: rows max |diff| %.1e, total %+.1e; shipped, low-pass total vs diag_obj17_lowpass_ocean_price.R %+.1e;\n    detrended, the five rows vs diag_obj17_resistance_split.R %.1e, its low-pass ocean change %+.1e\n",
            g_it, g_tot, g_lpt, g_sp, g_spl))
if (max(abs(c(g_it, g_tot, g_lpt, g_sp, g_spl))) > RP_REPRO_TOL) stop("the resistance does not reproduce the stored prices")
for (to in c("P1", "P1d")) {
  pins_to <- if (to == "P1") P1 else P1d
  cat(sprintf("\n  P0 -> %s (%s): %s\n", to, if (to == "P1") "the one-pass check at B, shipped index" else "item 2's stage 1 at B, detrended",
              paste(sprintf("%s %.4f -> %.4f", CCX_IAV_MODULE_NAMES, P0[CCX_IAV_MODULE_NAMES], pins_to[CCX_IAV_MODULE_NAMES]), collapse = ", ")))
  M <- sapply(c("shipped_full", "shipped_lp", "detrend_full", "detrend_lp"), function(k) RS[[paste(to, k, sep = "_")]])
  ordr <- c(RP_FIVE, setdiff(rownames(M), RP_FIVE)[order(-abs(M[setdiff(rownames(M), RP_FIVE), "detrend_lp"]))])
  cat(sprintf("  %-20s %13s %13s %13s %13s\n", "row", "shipped/yby", "shipped/lp", "detrend/yby", "REDESIGN"))
  for (rw in ordr[seq_len(min(length(ordr), length(RP_FIVE) + RP_TOP))])
    cat(sprintf("  %-20s %+13.4f %+13.4f %+13.4f %+13.4f\n", rw, M[rw, 1], M[rw, 2], M[rw, 3], M[rw, 4]))
  cat(sprintf("  %-20s %+13.4f %+13.4f %+13.4f %+13.4f\n", "the five", colSums(M[RP_FIVE, ])[1], colSums(M[RP_FIVE, ])[2],
              colSums(M[RP_FIVE, ])[3], colSums(M[RP_FIVE, ])[4]))
  cat(sprintf("  %-20s %+13.4f %+13.4f %+13.4f %+13.4f\n", "the other rows", colSums(M[setdiff(rownames(M), RP_FIVE), ])[1],
              colSums(M[setdiff(rownames(M), RP_FIVE), ])[2], colSums(M[setdiff(rownames(M), RP_FIVE), ])[3], colSums(M[setdiff(rownames(M), RP_FIVE), ])[4]))
  cat(sprintf("  %-20s %+13.4f %+13.4f %+13.4f %+13.4f   (the WHOLE main objective)\n", "ALL", colSums(M)[1], colSums(M)[2], colSums(M)[3], colSums(M)[4]))
}

cat("\n=== 3b. THE RATCHET TEST: re-optimise the ocean pair at P0 and at P1 -- does a higher w push it further? ===\n")
cat(sprintf("  (the pair: %s; #17's own stage 2 moved pump_grad -0.88 hilda33p-sd at B, which is why the check wanted w higher)\n",
            paste(RP_OCEAN_BLK, collapse = ", ")))
VB_B <- dg_vector(RP_MODE_B); VB_C <- dg_vector(ccx_mode_file(RP_CANON))
ocean_slope <- function(index, pins, vals = NULL) {     # the model's ENSO ocean slope, the row's own estimator on the objective's span
  V <- set_names(with_index(VB_B, index), pins[CCX_IAV_MODULE_NAMES]); if (length(vals)) V <- set_names(V, vals)
  R <- dg_run(V); fl <- ccx_calendar_flux(R$out[R$out$t < LIK_IAV_SPAN_END + 1, , drop = FALSE])
  ccx_enso_slope(fl$year, fl$ocean, OBS$enso_idx)[["slope"]] }
g_s <- c(ocean_slope(RP_SHIPPED, P0) - ITER$B$slope0[["slope"]], ocean_slope(RP_SHIPPED, P1) - ITER$B$slope1[["slope"]])
cat(sprintf("  GATE: the slope at B (shipped) vs diag_obj17_iterate_price.R, P0 %+.1e, P1 %+.1e (tol %g)\n", g_s[1], g_s[2], RP_SLOPE_TOL))
if (max(abs(g_s)) > RP_SLOPE_TOL) stop("the ENSO ocean slope does not reproduce the iterate price's")
RT <- list(obj17_P0 = reopt(P0, RP_SHIPPED, RP_OCEAN_BLK, "full", "#17 as landed, P0"),
           obj17_P1 = reopt(P1, RP_SHIPPED, RP_OCEAN_BLK, "full", "#17 as landed, P1"),
           redesign_P0 = reopt(P0, RP_INDEX, RP_OCEAN_BLK, "lp", "the redesign, P0"),
           redesign_P1 = reopt(P1, RP_INDEX, RP_OCEAN_BLK, "lp", "the redesign, P1"),
           redesign_P1d = reopt(P1d, RP_INDEX, RP_OCEAN_BLK, "lp", "the redesign, P1d"))
SDU <- MD_B$sd_unc[RP_OCEAN_BLK]                               # B's own marginal sd in u (its Laplace)
pins_of <- list(obj17_P0 = P0, obj17_P1 = P1, redesign_P0 = P0, redesign_P1 = P1, redesign_P1d = P1d)
RTT <- t(vapply(names(RT), function(k) { o <- RT[[k]]; key <- if (o$rows == "lp") "logpost_lp" else "logpost_full"
  c(o$par, (o$u - MD_B$u_mode[RP_OCEAN_BLK]) / SDU, logpost = o$at[[key]],
    slope = ocean_slope(o$index, pins_of[[k]], o$par)) }, numeric(2 * length(RP_OCEAN_BLK) + 2)))
colnames(RTT) <- c(RP_OCEAN_BLK, paste0(RP_OCEAN_BLK, "_vsB_sd"), "logpost", "slope")
RTT <- cbind(RTT, slope_x_obs = RTT[, "slope"] / OBS$enso_slope[["slope"]])
print(signif(RTT, 6))
unref <- c(obj17 = sum(RS$P1_shipped_full), redesign = sum(RS$P1_detrend_lp))
for (v in c("obj17", "redesign")) {
  a <- RTT[paste0(v, "_P0"), ]; b <- RTT[paste0(v, "_P1"), ]
  cat(sprintf("  %-9s P0 -> P1: the pair moves %s; the resistance, the pair re-optimised %+.4f (unrefitted %+.4f); the slope at the P1 optimum %.2fx obs\n",
              v, paste(sprintf("%s %+.3f sd", RP_OCEAN_BLK, b[paste0(RP_OCEAN_BLK, "_vsB_sd")] - a[paste0(RP_OCEAN_BLK, "_vsB_sd")]), collapse = ", "),
              b[["logpost"]] - a[["logpost"]], unref[[v]], b[["slope_x_obs"]]))
}

cat(sprintf("\n=== 4. THE FUTURES: CO2 (ppm) in %d (br_futures()) ===\n", BR_FUT_YEAR))
FUT_V <- list(hilda33p = VB_C, B = VB_B, B1 = with_index(VB_B, RP_INDEX), B2 = set_names(with_index(VB_B, RP_INDEX), unlist(parB2)),
              B2_at_P1d = set_names(set_names(with_index(VB_B, RP_INDEX), unlist(parB2)), P1d[CCX_IAV_MODULE_NAMES]),
              B3 = set_names(with_index(VB_B, RP_INDEX), O3$par))
for (a in c("B1", "B2", "B2_at_P1d", "B3")) if (!identical(ccx_enso_index_of(dg_spinup(FUT_V[[a]])$params), RP_INDEX)) stop(a, ": the spinup does not carry the index")
FUT <- t(vapply(names(FUT_V), function(a) { v <- FUT_V[[a]]; br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
for (a in rownames(FUT)) cat(sprintf("  %-10s %s\n", a, paste(sprintf("%s %8.2f (vs B %+7.2f, vs hilda33p %+7.2f)", colnames(FUT), FUT[a, ],
                                                                     FUT[a, ] - FUT["B", ], FUT[a, ] - FUT["hilda33p", ]), collapse = " | ")))
cat("  (the refit read, 10-07 a: B vs hilda33p SSP5-8.5 -4.33, vvH -3.04)\n")

saveRDS(list(ref = REF, b1 = B1, b2 = B2, b2_block = unlist(parB2), b2_converged = B2_CONV, reopt_b2 = O2, reopt_b3 = O3, b3 = B3,
             d1 = list(lp = d1_lp, full = d1_full), d2 = d2_lp, d3 = d3_lp, trend = TR, stage1 = ST, control = ctl, stage1_move = mv,
             pins = list(P0 = P0, P1 = P1, P1d = P1d), scores = S, resistance = RS, ratchet = RT, ratchet_table = RTT, futures = FUT,
             provenance = list(driver = RP_DRIVER, commit = COMMIT, date = format(Sys.time(), "%Y-%m-%d %H:%M"), smoke = RP_SMOKE,
                               mode_b = RP_MODE_B, mode_b_md5 = RP_MODE_B_MD5, canon = RP_CANON, canon_md5 = unname(tools::md5sum(ccx_mode_file(RP_CANON))),
                               stage1_ref = RP_S1, check_b = RP_CHECK_B, lowpass_ref = RP_LOWPASS, split_ref = RP_SPLIT_D, iterate_ref = RP_ITER,
                               index = RP_INDEX, ocean_df = RP_OCEAN_DF, ocean_sd = RP_OCEAN_SD, block = RP_REST, ocean_block = RP_OCEAN_BLK,
                               b2_tols = c(mode = RP_MODE_TOL, pull_h = RP_PULL_H, ndeps = RP_NDEPS, reltol = RP_RELTOL, bfgs = RP_BFGS_MAXIT, nm = RP_NM_MAXIT, rounds = RP_ROUNDS),
                               stage1_consts = list(lags = IAV_LAGS_SUP, nm_maxit = IAV_NM_MAXIT, nm_reltol = IAV_NM_RELTOL, prof = IAV_PROF_LAGS,
                                                    prof_maxit = IAV_PROF_MAXIT, h = IAV_H_STEP, workers = RP_WORKERS),
                               futures = paste(names(BR_FUT_SPLICE), collapse = "+"), fut_year = BR_FUT_YEAR, rng = "none",
                               units = "log-likelihood units; L months; s x hilda33p's land pair; w_enso_l2 as the table; CO2 ppm")),
        paste0(RP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds} | %.1f min\n⛔ ADOPTS NOTHING.\n", RP_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
sink(); close(LOGCON)
