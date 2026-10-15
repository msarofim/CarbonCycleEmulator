#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_cut_preview.R -- Marcus's SPLIT CALIBRATION of the interannual parameters, PREVIEWED (2026-10-06).
#
# WHY. Marcus 2026-10-06, verbatim: "I still find it odd that there is a pattern in the data that ENSO causes
# a lagged effect on CO2 and that we can't somehow make our ENSO parameter do a better job of reproducing that
# lag. What about having a 12-month smoothed CO2 growth that is used only for calibrating the ENSO and volcanic
# aerosol parameters? E.g., the parameters that only care about interannual variability and not the regular
# annual cycle or the long term trend which is what all the other parameters in the model care about."
# In the statistics literature this is a MODULAR ("cut") calibration: a module's data inform only that
# module's parameters, so a suspect module cannot pull them (Liu, Bayarri & Berger 2009, Bayesian Analysis
# 4:119, doi:10.1214/09-BA404; Plummer 2015, Stat. Comput. 25:37, doi:10.1007/s11222-014-9503-z). It is NOT
# the growth row declined 09-26 and 10-04 (memory ccx_growth_objective_declined): that row was added to the
# JOINT objective, where the existing rows outvote it; here the existing rows get no vote on these names.
#
# PART A -- THE GROWTH MODULE (the cut's stage 1). The interannual names fitted to the detrended monthly
#   growth ALONE, every other name at the canonical:
#   - the land ENSO lag L; a common scale s on the two land amplitudes (the GLOBAL growth sees only their
#     sum, so the NH:SH split stays the canonical's); the diffuse-light gamma_diff (FIXED at 0.25 by the
#     canonical, not a fitted name; free here, >= 0);
#   - the estimator is the refit read's s. 6 one (lib_block_reopt.R br_timing): NOAA MBL global, centered
#     12-month difference, 1980-2024, both series detrended by a natural spline (df 5). The centered
#     difference removes the annual cycle and the spline the long-term trend: the two things Marcus named;
#   - by SUPERPOSITION at each L (both terms are additive fluxes on the land), then CHECKED by direct runs
#     and polished by a direct Nelder-Mead on real runs;
#   - A2, a check arm: the ocean ENSO limb w_enso_l2 freed too. The growth record splits land from ocean ENSO
#     only by timing, and the ocean has its own interannual row (gcb_ocean_enso_slope), so A2 is scored
#     with that row added to the module and, for contrast, without it.
# PART B -- THE COST (the cut's stage 2, approximated). At A1's optimum, the main objective row by row:
#   B1 unrefitted; B2 the rest of the land block re-optimized; B3 B2 + the seasonal-cycle block and tau_ex.
#   A real stage 2 is a full refit of the other names (24 starts, hours); B2/B3 bound what it can recover.
# PART C -- WHY THE JOINT FIT HOLDS THE LAG SHORT. Two tests that separate "the seasonal rows carry real phase
#   information" from "the two-box model absorbing its seasonal errors through the lag":
#   C1 the lag profile WITHOUT the four seasonal rows (10-06's 7-name land block re-optimized per lag),
#      against 10-06's profile WITH them (read from its rds, gated on the identity cell);
#   C2 each seasonal row's preference split EXACTLY (Gaussian rows, fixed sigma) into INFORMATION, I(L) =
#      sum r0 E(L) / sd^2 (the no-land-ENSO residual projected on the model's land-ENSO signature), and
#      VISIBILITY, V(L) = sum E(L)^2 / (2 sd^2) (the signature's own size): row(L) - row(no land ENSO) = I - V.
#      The information is split again into its decadal (natural spline, df 5) and interannual parts.
#   C3 the per-year ledger of the seasonal rows' cost of moving the lag to the record's 5 months.
# ⛔ ADOPTS NOTHING; moves no stored value; changes no objective. No RNG.
# Usage: Rscript calibration/diag_iav_cut_preview.R   (CCX_CUT_WORKERS=<n>, default 4; CCX_CUT_SMOKE=1)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
CUT_DRIVER  <- "calibration/diag_iav_cut_preview.R"
CUT_SMOKE   <- identical(Sys.getenv("CCX_CUT_SMOKE", ""), "1")
CUT_WORKERS <- as.integer(Sys.getenv("CCX_CUT_WORKERS", "4"))
CUT_MODE    <- CCX_MODE_CANONICAL
CUT_GAMMA   <- c("gamma_enso_land_NH", "gamma_enso_land_SH")   # scaled together by s
CUT_OCEAN   <- "w_enso_l2"                                     # the ocean ENSO limb (A2 only)
CUT_VOLC    <- "gamma_diff"                                    # diffuse light: a FIXED base parameter
CUT_SLOPE_ROW <- "gcb_ocean_enso_slope"                        # the ocean's own interannual row (A2)
TR_BLOCK    <- c("beta_max", "fert_k", CUT_GAMMA, "luc_scale", "imb_share_land", "ndep_ret")  # 10-06's, verbatim
CUT_REST    <- setdiff(TR_BLOCK, CUT_GAMMA)                     # B2: the land block without the ENSO amplitudes
CUT_SEASB   <- c("seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p_NH", "seas_lag_p_SH",
                 "sst_seas_amp_NH", "sst_seas_amp_SH", "tau_ex")   # B3: + the seasonal cycle and transport
SEAS_ROWS   <- c("co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO", "d13c_seasonal_SPO")
CUT_LAGS_A  <- seq(0.5, 10, by = 0.25)     # the growth module's profile (superposition)
CUT_LAGS_C1 <- c(1, 2, 3, 4, 5, 6, 8)       # + the mode lag: 10-06's grid
CUT_LAGS_C2 <- seq(0.5, 10, by = 0.5)       # the information / visibility split
CUT_LAG_OBS <- 5                            # the record's growth peak after Nino 3.4 (10-02 x)
CUT_NM_MAXIT <- 120L                        # the direct polish of A1 / A2 (real runs, ~1 s each)
CUT_SIG     <- c(one = 0.5, two = 2)        # profile drops for the 1- and 2-sigma lag ranges
BR_WIN <- c(1980L, 2024L); BR_TREND_DF <- 5L; BR_XLAGS <- -6:18
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
CUT_ANNUAL_OBS <- file.path("data", "mbl_global_growth.rds")    # NOAA MBL, the app's estimator
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
CUT_REC_1006 <- file.path("outputs", "diagnostics", "timing_row_reread_20261006_hilda33p.rds")  # WITH the rows
if (CUT_SMOKE) { BR_BFGS_MAXIT <- 2L; BR_NM_MAXIT <- 10L; BR_ROUNDS <- 1L; CUT_NM_MAXIT <- 6L
  CUT_LAGS_A <- c(1, 2.5, 5, 8); CUT_LAGS_C1 <- c(2, 5); CUT_LAGS_C2 <- c(1, 2.5, 5, 8) }
CUT_TAG <- paste0(format(Sys.Date(), "%Y%m%d"), "_", CUT_MODE, if (CUT_SMOKE) "_SMOKE" else "")
CUT_OUT <- file.path("outputs", "diagnostics", sprintf("iav_cut_preview_%s", CUT_TAG))
COMMIT  <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))
LOGCON <- file(paste0(CUT_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | canonical %s | %d workers%s\n", CUT_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            CUT_MODE, CUT_WORKERS, if (CUT_SMOKE) " | ⚠ SMOKE: tiny budgets and grids, NOT A RESULT" else ""))

# ---- the base: the canonical, its own structure, its own pins ------------------------------------------------
BR_OBS <- ccx_prepare_obs()
MODE_FILE <- ccx_mode_file(CUT_MODE)
BR_MD  <- list(BASE = readRDS(MODE_FILE)); md <- BR_MD$BASE
MODE_MD5 <- unname(tools::md5sum(MODE_FILE))
BR_LABEL_LAG <- ccx_mode_struct(md); BR_LABEL_ZERO <- NA_character_
BR_PINS <- stats::setNames(as.numeric(md$pins), names(md$pins))
stopifnot(all(c(TR_BLOCK, CUT_SEASB, CUT_OCEAN, "lag_enso_land") %in% md$param_names), !any(TR_BLOCK %in% names(BR_PINS)),
          !CUT_VOLC %in% md$param_names)
BR_SPF <- list(BASE = ccx_spinup_from_label(ccx_mode_spinup(md)))
BR_VB  <- list(BASE = dg_vector(MODE_FILE))
L0 <- md$par_mode[["lag_enso_land"]]
G0 <- vapply(CUT_GAMMA, function(n) md$par_mode[[n]], 0)
W0 <- md$par_mode[[CUT_OCEAN]]
D0 <- BR_VB$BASE$p[[CUT_VOLC]]
OBS_G <- br_obs_growth()
ANN   <- readRDS(CUT_ANNUAL_OBS)$growth
cat(sprintf("mode file %s (md5 %s); struct %s; %d pins\n", MODE_FILE, MODE_MD5, BR_LABEL_LAG, length(BR_PINS)))
cat(sprintf("canonical interannual set: lag %.4f months; %s = %.4f / %.4f GtC/yr per index unit; %s = %.3f; %s = %.2f (fixed)\n",
            L0, paste(CUT_GAMMA, collapse = " / "), G0[[1]], G0[[2]], CUT_OCEAN, W0, CUT_VOLC, D0))

# ---- runs at an interannual setting, every other name at the canonical ----------------------------------------
#' s scales both land amplitudes; d is gamma_diff itself; w is w_enso_l2. The vector is br_vec's (the block's
#' natural values and the lag), with gamma_diff written onto the MODEL list (it has no fitted slot).
vec_at <- function(L, s = 1, d = D0, w = W0, block = NULL) {
  blk <- c(stats::setNames(s * G0, CUT_GAMMA), stats::setNames(w, CUT_OCEAN), block)
  v <- br_vec("BASE", blk, L); v$p[[CUT_VOLC]] <- d; v }
run_at <- function(...) { v <- vec_at(...); r <- dg_run(v); r$v <- v; r }

# the monthly growth estimator (br_timing's), and the annual one (the app's), on a run
growth_m <- function(r) {
  m <- data.frame(k = r$F$year * 12L + r$F$month, g = br_cen12((r$out$co2_NH + r$out$co2_SH) / 2))
  M <- merge(m, OBS_G, by = "k", suffixes = c("_mod", "_obs"))
  M[M$k >= BR_WIN[1] * 12L + 1L & M$k <= BR_WIN[2] * 12L + 12L & stats::complete.cases(M), ] }
growth_a <- function(r) {
  co2 <- tapply((r$out$co2_NH + r$out$co2_SH) / 2, floor(r$out$t), mean)
  gm <- data.frame(year = as.integer(names(co2))[-1], g_mod = diff(as.numeric(co2)))
  A <- merge(gm, stats::setNames(ANN[, 1:2], c("year", "g_obs")), by = "year")
  A[A$year >= BR_WIN[1] & A$year <= BR_WIN[2], ] }
# the detrending operators: residual-maker of [1, ns(t, df)] on each estimator's own time axis (linear, so
# superposition survives it exactly)
qmaker <- function(tt) { X <- stats::model.matrix(~ splines::ns(tt, df = BR_TREND_DF)); function(g) as.numeric(g - X %*% qr.solve(X, g)) }
r1 <- function(x) stats::acf(x, lag.max = 1, plot = FALSE)$acf[2]
neff <- function(x, y) length(x) * (1 - r1(x) * r1(y)) / (1 + r1(x) * r1(y))   # Bretherton et al. 1999 eq. 31

cat("\n=== 0. IDENTITY: the canonical at its own lag, 0 rounds, must reproduce its stored logpost ===\n")
id0 <- br_cell("BASE", L0, TR_BLOCK, max_rounds = 0L)
cat(sprintf("  logpost %.6f (stored %.6f, diff %.1e); likelihood %.6f\n", id0$logpost, md$logpost, id0$logpost - md$logpost, id0$lik))
if (abs(id0$logpost - md$logpost) > 1e-6) stop("the base does not reproduce its stored logpost")
# base_over is new today: gamma_diff at its own value must reproduce to the digit, and moving it must MOVE the answer
idv <- br_cell("BASE", L0, CUT_REST[1], max_rounds = 0L, base_over = stats::setNames(list(D0), CUT_VOLC))
idm <- br_cell("BASE", L0, CUT_REST[1], max_rounds = 0L, base_over = stats::setNames(list(0), CUT_VOLC))
cat(sprintf("  base_over %s = %.2f reproduces: diff %.1e; = 0 moves the logpost by %+.4f (must be nonzero)\n",
            CUT_VOLC, D0, idv$logpost - id0$logpost, idm$logpost - id0$logpost))
if (!identical(idv$logpost, id0$logpost) || abs(idm$logpost - id0$logpost) < 1e-6) stop("base_over gate failed")
# dg_run + dg_streams must score the canonical exactly as the objective does (C2 reads rows off dg_streams)
RC <- run_at(L0); SC <- unlist(dg_streams(RC, RC$v, obs = BR_OBS))
dmax <- max(abs(SC[names(id0$streams)] - id0$streams))
cat(sprintf("  dg_run + dg_streams reproduce the objective's %d rows: max |diff| %.1e\n", length(id0$streams), dmax))
if (dmax > 1e-6) stop("dg_streams does not reproduce the objective's rows")

# =====================================================================
cat("\n=== A. THE GROWTH MODULE: the interannual names fitted to the detrended growth ALONE ===\n")
# the superposition bases: everything interannual OFF (R000), then each term alone
R000 <- run_at(L0, s = 0, d = 0, w = 0)
RV   <- run_at(L0, s = 0, d = D0, w = 0)
RO   <- run_at(L0, s = 0, d = 0, w = W0)
M000 <- growth_m(R000); k_ref <- M000$k; Qm <- qmaker((k_ref - 1) / 12)
A000 <- growth_a(R000); y_ref <- A000$year; Qa <- qmaker(y_ref)
gm <- function(r) { M <- growth_m(r); stopifnot(identical(M$k, k_ref)); M$g_mod }
ga <- function(r) { A <- growth_a(r); stopifnot(identical(A$year, y_ref)); A$g_mod }
B <- list(m = list(obs = Qm(M000$g_obs), g000 = Qm(M000$g_mod), V = Qm(gm(RV) - M000$g_mod), O = Qm(gm(RO) - M000$g_mod)),
          a = list(obs = Qa(A000$g_obs), g000 = Qa(A000$g_mod), V = Qa(ga(RV) - A000$g_mod), O = Qa(ga(RO) - A000$g_mod)))
EL <- lapply(CUT_LAGS_A, function(L) { r <- run_at(L, s = 1, d = 0, w = 0)
  list(m = Qm(gm(r) - M000$g_mod), a = Qa(ga(r) - A000$g_mod)) })
# the superposition check: the canonical against the sum of its parts at its own lag
Ecan <- run_at(L0, s = 1, d = 0, w = 0)
sup_m <- B$m$g000 + Qm(gm(Ecan) - M000$g_mod) + B$m$V + B$m$O
can_m <- Qm(gm(RC))
cat(sprintf("  superposition check at the canonical: rms(sum of parts - direct) %.2e ppm/yr against rms(direct) %.3f\n",
            sqrt(mean((sup_m - can_m)^2)), sqrt(mean(can_m^2))))

#' non-negative least squares for <= 3 columns: every subset, unconstrained, keep the best feasible
nnls_small <- function(y, X) {
  best <- list(b = rep(0, ncol(X)), ssr = sum(y^2))
  for (k in seq_len(ncol(X))) for (S in utils::combn(ncol(X), k, simplify = FALSE)) {
    b <- qr.solve(X[, S, drop = FALSE], y); if (any(b < 0)) next
    bb <- rep(0, ncol(X)); bb[S] <- b; ssr <- sum((y - X %*% bb)^2)
    if (ssr < best$ssr) best <- list(b = bb, ssr = ssr) }
  best }
#' one arm at one lag, on one estimator: which terms are free, the rest held at the canonical
arm_fit <- function(i, est, free) {
  b <- B[[est]]; E <- EL[[i]][[est]]
  cols <- list(s = E, d = b$V, w = b$O)
  held <- c(s = 1, d = 1, w = 1)[setdiff(c("s", "d", "w"), free)]
  y <- b$obs - b$g000 - Reduce(`+`, Map(function(n, x) x * cols[[n]], names(held), held), 0)
  X <- do.call(cbind, cols[free]); fit <- nnls_small(y, X)
  cf <- stats::setNames(fit$b, free)
  pred <- b$g000 + Reduce(`+`, Map(function(n) cols[[n]] * c(cf, held)[[n]], c("s", "d", "w")), 0)
  list(coef = cf, ssr = fit$ssr, r = stats::cor(pred, b$obs), sd_ratio = stats::sd(pred) / stats::sd(b$obs)) }
ARMS <- list(A0 = "s", A1 = c("s", "d"), A2g = c("s", "d", "w"))
PROF <- do.call(rbind, lapply(names(ARMS), function(a) do.call(rbind, lapply(c("m", "a"), function(est)
  do.call(rbind, lapply(seq_along(CUT_LAGS_A), function(i) { o <- arm_fit(i, est, ARMS[[a]])
    data.frame(arm = a, est = est, L = CUT_LAGS_A[i], ssr = o$ssr, r = o$r, sd_ratio = o$sd_ratio,
               s = o$coef[["s"]], d = if ("d" %in% names(o$coef)) o$coef[["d"]] * D0 else D0,
               w = if ("w" %in% names(o$coef)) o$coef[["w"]] * W0 else W0) }))))))
# the canonical on each estimator, for the comparison lines
can_a <- Qa(ga(RC))
CAN <- c(ssr_m = sum((can_m - B$m$obs)^2), r_m = stats::cor(can_m, B$m$obs), sdr_m = stats::sd(can_m) / stats::sd(B$m$obs),
         ssr_a = sum((can_a - B$a$obs)^2), r_a = stats::cor(can_a, B$a$obs), sdr_a = stats::sd(can_a) / stats::sd(B$a$obs))
NE <- c(m = neff(can_m, B$m$obs), a = neff(can_a, B$a$obs))
cat(sprintf("  n_eff at the canonical (Bretherton 1999 eq. 31): monthly %.1f of %d; annual %.1f of %d\n",
            NE[["m"]], length(can_m), NE[["a"]], length(can_a)))
cat(sprintf("  the canonical: monthly r %.3f, sd ratio %.2f; annual r %.3f, sd ratio %.2f\n", CAN[["r_m"]], CAN[["sdr_m"]], CAN[["r_a"]], CAN[["sdr_a"]]))
OPT <- do.call(rbind, lapply(split(PROF, list(PROF$arm, PROF$est), drop = TRUE), function(P) {
  P <- P[order(P$L), ]; n_e <- NE[[P$est[1]]]
  ll <- -(n_e / 2) * log(P$ssr / min(P$ssr))
  fine <- seq(min(P$L), max(P$L), by = 0.01); sp <- stats::splinefun(P$L, ll, method = "natural")(fine)
  rng <- function(dl) range(fine[sp >= -dl])
  j <- which.min(P$ssr); ssr_can <- if (P$est[1] == "m") CAN[["ssr_m"]] else CAN[["ssr_a"]]
  data.frame(arm = P$arm[1], est = P$est[1], L_star = fine[which.max(sp)], L_grid = P$L[j],
             lo1 = rng(CUT_SIG[["one"]])[1], hi1 = rng(CUT_SIG[["one"]])[2], lo2 = rng(CUT_SIG[["two"]])[1], hi2 = rng(CUT_SIG[["two"]])[2],
             s = P$s[j], gamma_NH = P$s[j] * G0[[1]], gamma_SH = P$s[j] * G0[[2]], d = P$d[j], w = P$w[j],
             r = P$r[j], sd_ratio = P$sd_ratio[j], ssr_vs_canonical = P$ssr[j] / ssr_can,
             dll_vs_canonical = -(n_e / 2) * log(P$ssr[j] / ssr_can)) }))
rownames(OPT) <- NULL
cat(sprintf("  the profile, %d lags from %g to %g months; the optimum per arm (A0 s only, A1 s + %s, A2g s + %s + %s on the growth ALONE):\n",
            length(CUT_LAGS_A), min(CUT_LAGS_A), max(CUT_LAGS_A), CUT_VOLC, CUT_VOLC, CUT_OCEAN))
print(OPT, digits = 4, row.names = FALSE)

# A1 polished on REAL runs (monthly estimator): Nelder-Mead on (L, log s, d) from the superposition optimum
o1 <- OPT[OPT$arm == "A1" & OPT$est == "m", ]
ssr_direct <- function(L, s, d, w = W0) { r <- run_at(L, s = s, d = d, w = w); sum((Qm(gm(r)) - B$m$obs)^2) }
nm_a1 <- stats::optim(c(o1$L_star, log(max(o1$s, 1e-3)), o1$d), function(x) {
  if (x[1] < 0 || x[1] > 12 || x[3] < 0) return(1e10); ssr_direct(x[1], exp(x[2]), x[3]) },
  method = "Nelder-Mead", control = list(maxit = CUT_NM_MAXIT, reltol = 1e-8))
A1 <- c(L = nm_a1$par[1], s = exp(nm_a1$par[2]), d = nm_a1$par[3], ssr = nm_a1$value)
cat(sprintf("  A1 on REAL runs (Nelder-Mead, %d evaluations, convergence %d): L %.3f months, s %.3f (gammas %.3f / %.3f), %s %.3f; ssr %.4f (superposition said %.4f at L %.2f)\n",
            nm_a1$counts[["function"]], nm_a1$convergence, A1[["L"]], A1[["s"]], A1[["s"]] * G0[[1]], A1[["s"]] * G0[[2]],
            CUT_VOLC, A1[["d"]], A1[["ssr"]], min(PROF$ssr[PROF$arm == "A1" & PROF$est == "m"]), o1$L_star))

# A2 with the ocean's own row: the module's log-likelihood at the measured monthly n_eff + gcb_ocean_enso_slope
a2_obj <- function(x) { if (x[1] < 0 || x[1] > 12 || x[3] < 0 || x[4] < 0) return(1e10)
  r <- run_at(x[1], s = exp(x[2]), d = x[3], w = x[4])
  ssr <- sum((Qm(gm(r)) - B$m$obs)^2); row <- unlist(dg_streams(r, r$v, obs = BR_OBS))[[CUT_SLOPE_ROW]]
  -(-(NE[["m"]] / 2) * log(ssr / CAN[["ssr_m"]]) + row) }
nm_a2 <- stats::optim(c(A1[["L"]], log(A1[["s"]]), A1[["d"]], W0), a2_obj, method = "Nelder-Mead",
                      control = list(maxit = 2L * CUT_NM_MAXIT, reltol = 1e-8))
R_A2 <- run_at(nm_a2$par[1], s = exp(nm_a2$par[2]), d = nm_a2$par[3], w = nm_a2$par[4])
A2 <- c(L = nm_a2$par[1], s = exp(nm_a2$par[2]), d = nm_a2$par[3], w = nm_a2$par[4],
        ssr = sum((Qm(gm(R_A2)) - B$m$obs)^2), slope_row = unlist(dg_streams(R_A2, R_A2$v, obs = BR_OBS))[[CUT_SLOPE_ROW]])
cat(sprintf("  A2 (+ %s, with %s in the module; %d evaluations, convergence %d): L %.3f, s %.3f, %s %.3f, %s %.2f (canonical %.2f); ssr %.4f; %s %+.3f (canonical %+.3f)\n",
            CUT_OCEAN, CUT_SLOPE_ROW, nm_a2$counts[["function"]], nm_a2$convergence, A2[["L"]], A2[["s"]], CUT_VOLC, A2[["d"]],
            CUT_OCEAN, A2[["w"]], W0, A2[["ssr"]], CUT_SLOPE_ROW, A2[["slope_row"]], id0$streams[[CUT_SLOPE_ROW]]))

# the growth statistics at A1's optimum on REAL runs: timing, both estimators, the What-if readout's RMS
R_A1 <- run_at(A1[["L"]], s = A1[["s"]], d = A1[["d"]])
whatif <- function(r) { A <- growth_a(r); sqrt(mean((A$g_mod - A$g_obs)^2)) }   # the readout's miss: annual, NOT detrended
off_of <- function(L, s, d, block = NULL) run_at(L, s = 0, d = d, w = 0, block = block)   # the app's switch: index zeroed
gstats <- function(r, r_off) { tm <- br_timing(r$out, r$F, OBS_G)$stats; ma <- Qa(ga(r))
  c(peak = tm[["peak_mod"]], r_xc = tm[["r_mod"]], peak_obs = tm[["peak_obs"]], r_m = tm[["r_mod_obs"]],
    sdr_m = stats::sd(Qm(gm(r))) / stats::sd(B$m$obs), r_a = stats::cor(ma, B$a$obs), sdr_a = stats::sd(ma) / stats::sd(B$a$obs),
    rms = whatif(r), rms_off = whatif(r_off), enso_gain_pct = 100 * (whatif(r_off) / whatif(r) - 1)) }
GS <- rbind(canonical = gstats(RC, off_of(L0, 1, D0)), A1 = gstats(R_A1, off_of(A1[["L"]], A1[["s"]], A1[["d"]])))
cat("  growth statistics on real runs (peak = months after Nino 3.4; r_m / r_a detrended monthly / annual; rms = the What-if\n",
    "  readout's annual miss, ppm/yr; enso_gain_pct = how much worse it gets with the index zeroed):\n", sep = "")
print(round(GS, 4))

# B1 ATTRIBUTED: the canonical, then one change at a time towards A1, every row off dg_streams (gated above)
STEPS <- list(canonical = RC, lag = run_at(A1[["L"]]), lag_amp = run_at(A1[["L"]], s = A1[["s"]]), lag_amp_volc = R_A1)
ST <- vapply(STEPS, function(r) unlist(dg_streams(r, r$v, obs = BR_OBS))[names(id0$streams)], numeric(length(id0$streams)))
DST <- cbind(lag = ST[, "lag"] - ST[, "canonical"], amplitude = ST[, "lag_amp"] - ST[, "lag"],
             volcanic = ST[, "lag_amp_volc"] - ST[, "lag_amp"])
cat(sprintf("\n  A1's names in the MAIN objective, unrefitted, one step at a time: lag %.2f -> %.2f %+.2f | amplitude x%.2f %+.2f | %s %.2f -> %.2f %+.2f | total %+.2f\n",
            L0, A1[["L"]], sum(DST[, "lag"]), A1[["s"]], sum(DST[, "amplitude"]), CUT_VOLC, D0, A1[["d"]], sum(DST[, "volcanic"]), sum(DST)))
print(round(DST[order(-apply(abs(DST), 1, max))[1:10], ], 3))
# the land-sink row year by year (its own residuals; sigma as the objective's)
res_of <- function(r, row) unlist(attr(dg_streams(r, r$v, obs = BR_OBS, residuals = TRUE), "residuals")[[row]])
SD_LAND <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE
GCB_YRS <- sort(BR_OBS$gcb$year)
LS <- data.frame(year = GCB_YRS, canonical = res_of(RC, "gcb_land_sink"), lag_amp = res_of(STEPS$lag_amp, "gcb_land_sink"),
                 A1 = res_of(R_A1, "gcb_land_sink"))
LS$d_enso <- -0.5 * (LS$lag_amp^2 - LS$canonical^2) / SD_LAND^2
LS$d_volc <- -0.5 * (LS$A1^2 - LS$lag_amp^2) / SD_LAND^2
LS$d <- LS$d_enso + LS$d_volc
LS$nino_ann <- as.numeric(tapply(RC$F$enso, RC$F$year, mean)[as.character(LS$year)])
cat(sprintf("  gcb_land_sink year by year (sd %.2f GtC/yr; residual = GCB target - model): %+.2f in all, %+.2f from the ENSO steps, %+.2f from %s; the eight worst years:\n",
            SD_LAND, sum(LS$d), sum(LS$d_enso), sum(LS$d_volc), CUT_VOLC))
print(head(LS[order(LS$d), c("year", "canonical", "A1", "d_enso", "d_volc", "d", "nino_ann")], 8), digits = 3, row.names = FALSE)

# =====================================================================
cat("\n=== B / C1. THE COST of A1's interannual names in the MAIN objective, and the lag profile WITHOUT the seasonal rows ===\n")
HOLD1 <- as.list(stats::setNames(A1[["s"]] * G0, CUT_GAMMA)); BO1 <- stats::setNames(list(A1[["d"]]), CUT_VOLC)
TASKS <- c(list(list(id = "B1", L = A1[["L"]], free = CUT_REST, hold = HOLD1, bo = BO1, rounds = 0L, drop = NULL),
                list(id = "B2", L = A1[["L"]], free = CUT_REST, hold = HOLD1, bo = BO1, rounds = BR_ROUNDS, drop = NULL),
                list(id = "B3", L = A1[["L"]], free = c(CUT_REST, CUT_SEASB), hold = HOLD1, bo = BO1, rounds = BR_ROUNDS, drop = NULL)),
           lapply(sort(c(CUT_LAGS_C1, L0)), function(L) list(id = sprintf("C1_%g", L), L = L, free = TR_BLOCK, hold = NULL,
                                                              bo = NULL, rounds = BR_ROUNDS, drop = SEAS_ROWS)))
flush(LOGCON)
RES <- parallel::mclapply(TASKS, function(tk) { while (sink.number() > 0L) sink()
  o <- try(br_cell("BASE", tk$L, tk$free, hold = tk$hold, max_rounds = tk$rounds, drop = tk$drop, base_over = tk$bo))
  if (!inherits(o, "try-error")) o$id <- tk$id
  o }, mc.cores = CUT_WORKERS, mc.preschedule = FALSE)
bad <- vapply(RES, function(o) inherits(o, "try-error") || is.null(o$L), logical(1))
if (any(bad)) stop("a cell failed: ", paste(vapply(RES[bad], function(o) as.character(o)[1], ""), collapse = " | "))
names(RES) <- vapply(RES, `[[`, "", "id")
saveRDS(list(res = RES, prof = PROF, opt = OPT, A1 = A1, A2 = A2, commit = COMMIT), paste0(CUT_OUT, "_cells.rds"))

# B: row by row against the canonical
rowtab <- do.call(cbind, lapply(c("B1", "B2", "B3"), function(b) RES[[b]]$streams[names(id0$streams)] - id0$streams))
colnames(rowtab) <- c("B1", "B2", "B3")
cat(sprintf("  likelihood change vs the canonical: B1 (unrefitted) %+.2f | B2 (+ %d land names) %+.2f | B3 (+ %d seasonal/transport names) %+.2f\n",
            sum(rowtab[, "B1"]), length(CUT_REST), sum(rowtab[, "B2"]), length(CUT_SEASB), sum(rowtab[, "B3"])))
cat(sprintf("  (prior part, B1/B2/B3: %+.2f / %+.2f / %+.2f; the slope gate passed: %s)\n",
            RES$B1$logpost - RES$B1$lik - (id0$logpost - id0$lik), RES$B2$logpost - RES$B2$lik - (id0$logpost - id0$lik),
            RES$B3$logpost - RES$B3$lik - (id0$logpost - id0$lik), paste(c(RES$B2$converged, RES$B3$converged), collapse = "/")))
big <- order(-apply(abs(rowtab), 1, max))[seq_len(min(12, nrow(rowtab)))]
print(round(rowtab[big, , drop = FALSE], 3))
cat("  the re-optimised names (natural units; canonical first):\n")
nmB <- unique(c(CUT_REST, CUT_SEASB))
print(round(rbind(canonical = unlist(md$par_mode[nmB]), B2 = c(RES$B2$block[CUT_REST], unlist(md$par_mode[CUT_SEASB])),
                  B3 = RES$B3$block[nmB]), 4))
# growth statistics and futures at each B vector
vec_B <- function(b) vec_at(A1[["L"]], s = A1[["s"]], d = A1[["d"]], block = RES[[b]]$block[setdiff(names(RES[[b]]$block), CUT_GAMMA)])
FUT <- rbind(canonical = br_futures(RC$v, RC$sp), t(vapply(c("B1", "B2", "B3"), function(b) { v <- vec_B(b); r <- dg_run(v)
  br_futures(v, r$sp) }, numeric(length(BR_FUT_SPLICE)))))
colnames(FUT) <- sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR)
GSB <- t(vapply(c("B2", "B3"), function(b) { v <- vec_B(b); r <- dg_run(v); r$v <- v
  blk <- RES[[b]]$block[setdiff(names(RES[[b]]$block), CUT_GAMMA)]
  gstats(r, off_of(A1[["L"]], A1[["s"]], A1[["d"]], block = blk)) }, numeric(ncol(GS))))
cat("  CO2 in 2300 (ppm):\n"); print(round(FUT, 2))
cat("  growth statistics with the re-optimised blocks (the cut's stage 1 is not re-run against them):\n"); print(round(GSB, 4))

# C1: the no-seasonal-rows profile, against 10-06's WITH-rows profile
c1 <- RES[grepl("^C1_", names(RES))]
C1T <- do.call(rbind, lapply(c1, function(o) data.frame(L = o$L, obj = o$obj, lik = o$lik, seas = sum(o$streams[SEAS_ROWS]),
  gamma_NH = o$block[[CUT_GAMMA[1]]], gamma_SH = o$block[[CUT_GAMMA[2]]], conv = isTRUE(o$converged), rounds = o$rounds,
  minutes = round(o$minutes, 1))))
C1T <- C1T[order(C1T$L), ]; C1T$d_obj <- C1T$obj - C1T$obj[which.min(abs(C1T$L - L0))]
fine <- seq(min(C1T$L), max(C1T$L), by = 0.01)
sp1 <- stats::splinefun(C1T$L, C1T$obj, method = "natural")(fine)
L_noseas <- fine[which.max(sp1)]
cat(sprintf("  C1: WITHOUT the four seasonal rows the land block's lag profile peaks at %.2f months (re-optimised cells):\n", L_noseas))
print(C1T, digits = 5, row.names = FALSE)
if (!all(C1T$conv)) cat("  ⚠ NOT every C1 cell passed the whitened-slope gate (curvature-blind off the base; memory whitened_slope_gate_blind_off_base)\n")
REC <- readRDS(CUT_REC_1006)
stopifnot(identical(REC$provenance$mode_md5, MODE_MD5))
rec_id <- REC$tabT$lik[which.min(abs(REC$tabT$L - L0))]
cat(sprintf("  10-06's WITH-rows profile (%s): its identity cell's likelihood %.6f vs today's %.6f (diff %.1e)\n",
            CUT_REC_1006, rec_id, id0$lik, rec_id - id0$lik))
if (abs(rec_id - id0$lik) > 1e-6) stop("10-06's profile is not comparable with today's objective")
spw <- stats::splinefun(REC$tabT$L, REC$tabT$lik, method = "natural")
L_with <- fine[which.max(spw(fine))]
cat(sprintf("  WITH the rows the peak is %.2f months (10-06); WITHOUT them %.2f; the record's growth peak is %g months\n",
            L_with, L_noseas, CUT_LAG_OBS))
c1a <- c1[[which.min(abs(vapply(c1, `[[`, 0, "L") - L0))]]; c1b <- c1[[which.min(abs(vapply(c1, `[[`, 0, "L") - CUT_LAG_OBS))]]
dC1 <- c1b$streams - c1a$streams
cat(sprintf("  without the seasonal rows, what lag %g costs against lag %.2f, by row (each cell's block re-optimised):\n", c1b$L, c1a$L))
print(round(dC1[order(dC1)][1:8], 3))

# =====================================================================
cat("\n=== C2. EACH SEASONAL ROW'S LAG PREFERENCE, SPLIT EXACTLY INTO INFORMATION AND VISIBILITY ===\n")
keep_t <- function(out) out[out$t < DG_SINK_LAST + 1, ]
seas_of <- function(r) { ms <- ccx_model_stats(keep_t(r$out), BR_OBS)
  list(co2_seasonal_MLO = ms$co2_seas$MLO, co2_seasonal_SPO = ms$co2_seas$SPO,
       d13c_seasonal_MLO = ms$d13_seas$MLO, d13c_seasonal_SPO = ms$d13_seas$SPO) }
obs_seas <- list(co2_seasonal_MLO = BR_OBS$co2_seas$MLO, co2_seasonal_SPO = BR_OBS$co2_seas$SPO,
                 d13c_seasonal_MLO = BR_OBS$d13_seas$MLO, d13c_seasonal_SPO = BR_OBS$d13_seas$SPO)
R0L <- run_at(L0, s = 0)                                    # no land ENSO; the ocean limb and diffuse light as canonical
S0 <- seas_of(R0L); SS0 <- unlist(dg_streams(R0L, R0L$v, obs = BR_OBS))
decomp <- function(Sm, row) { o <- obs_seas[[row]]; m0 <- S0[[row]]; m <- Sm[[row]]
  k0 <- match(o$year, m0$year); k <- match(o$year, m$year); ok <- !is.na(k0) & !is.na(k)
  yrs <- o$year[ok]; Qy <- qmaker(yrs)
  parts <- lapply(c("a", "b"), function(cf) { sdv <- o[[paste0("sd_", cf)]]
    r0 <- o[[cf]][ok] - m0[[cf]][k0[ok]]; E <- m[[cf]][k[ok]] - m0[[cf]][k0[ok]]
    hp_r <- Qy(r0); hp_E <- Qy(E)
    c(I = sum(r0 * E) / sdv^2, V = sum(E^2) / (2 * sdv^2), I_hp = sum(hp_r * hp_E) / sdv^2,
      I_lp = sum((r0 - hp_r) * (E - hp_E)) / sdv^2) })
  Reduce(`+`, parts) }
C2 <- do.call(rbind, lapply(sort(unique(c(CUT_LAGS_C2, L0))), function(L) { r <- if (abs(L - L0) < 1e-12) RC else run_at(L)
  Sm <- seas_of(r)
  do.call(rbind, lapply(SEAS_ROWS, function(row) { d <- decomp(Sm, row)
    data.frame(L = L, row = row, I = d[["I"]], V = d[["V"]], net = d[["I"]] - d[["V"]], I_hp = d[["I_hp"]], I_lp = d[["I_lp"]]) })) }))
# the gate: at the canonical's lag, I - V must equal the row's own change from the no-land-ENSO run
gate <- vapply(SEAS_ROWS, function(row) C2$net[abs(C2$L - L0) < 1e-12 & C2$row == row] - (SC[[row]] - SS0[[row]]), 0)
cat(sprintf("  gate: I - V reproduces each row's own change (canonical minus no land ENSO): max |diff| %.1e\n", max(abs(gate))))
if (max(abs(gate)) > 1e-6) stop("the information/visibility split does not reproduce the rows")
C2S <- stats::aggregate(cbind(I, V, net, I_hp, I_lp) ~ L, data = C2, FUN = sum)
argL <- function(x) C2S$L[which.max(x)]
cat("  summed over the four seasonal rows (log-likelihood units, relative to NO land ENSO):\n")
print(round(C2S, 3), row.names = FALSE)
cat(sprintf("  peaks: net (what the rows score) at %g months; information alone at %g; interannual information at %g; decadal at %g\n",
            argL(C2S$net), argL(C2S$I), argL(C2S$I_hp), argL(C2S$I_lp)))
for (row in SEAS_ROWS) { X <- C2[C2$row == row, ]
  cat(sprintf("  %-18s net peaks at %4.1f | I at %4.1f | I_hp at %4.1f | at L = %g vs %.2f: net %+.2f = I %+.2f - V %+.2f\n", row,
              X$L[which.max(X$net)], X$L[which.max(X$I)], X$L[which.max(X$I_hp)], CUT_LAG_OBS, L0,
              X$net[X$L == CUT_LAG_OBS] - X$net[abs(X$L - L0) < 1e-12], X$I[X$L == CUT_LAG_OBS] - X$I[abs(X$L - L0) < 1e-12],
              X$V[X$L == CUT_LAG_OBS] - X$V[abs(X$L - L0) < 1e-12])) }
# the growth analog, on the module's own monthly estimator (sigma = the canonical's residual sd; n_eff-scaled)
sig_g <- stats::sd(can_m - B$m$obs); y0g <- B$m$obs - (B$m$g000 + B$m$V + B$m$O)
G2 <- do.call(rbind, lapply(seq_along(CUT_LAGS_A), function(i) { E <- EL[[i]]$m
  data.frame(L = CUT_LAGS_A[i], I = sum(y0g * E) / sig_g^2 * NE[["m"]] / length(E), V = sum(E^2) / (2 * sig_g^2) * NE[["m"]] / length(E)) }))
G2$net <- G2$I - G2$V
cat(sprintf("  the growth record's own analogue (canonical amplitudes): information peaks at %g months, net at %g\n",
            G2$L[which.max(G2$I)], G2$L[which.max(G2$net)]))

cat(sprintf("\n=== C3. THE PER-YEAR LEDGER: the seasonal rows' change, lag %.2f -> %g months, canonical amplitudes ===\n", L0, CUT_LAG_OBS))
R5 <- run_at(CUT_LAG_OBS); S5 <- seas_of(R5); SM <- seas_of(RC)
nino_ann <- tapply(RC$F$enso, RC$F$year, mean)
PY <- do.call(rbind, lapply(SEAS_ROWS, function(row) { o <- obs_seas[[row]]
  ka <- match(o$year, SM[[row]]$year); kb <- match(o$year, S5[[row]]$year); ok <- !is.na(ka) & !is.na(kb)
  d <- -0.5 * (((o$a[ok] - S5[[row]]$a[kb[ok]])^2 - (o$a[ok] - SM[[row]]$a[ka[ok]])^2) / o$sd_a^2 +
               ((o$b[ok] - S5[[row]]$b[kb[ok]])^2 - (o$b[ok] - SM[[row]]$b[ka[ok]])^2) / o$sd_b^2)
  data.frame(row = row, year = o$year[ok], d = d) }))
PYY <- stats::aggregate(d ~ year, data = PY, FUN = sum)
PYY$nino_ann <- as.numeric(nino_ann[as.character(PYY$year)]); PYY$nino_prev <- as.numeric(nino_ann[as.character(PYY$year - 1)])
PYY <- PYY[order(PYY$d), ]
tot <- sum(PYY$d); neg <- sum(PYY$d[PYY$d < 0])
cat(sprintf("  total %+.2f over %d years (%d years pay, %+.2f; %d gain, %+.2f); the five worst years carry %+.2f (%.0f %% of what is paid):\n",
            tot, nrow(PYY), sum(PYY$d < 0), neg, sum(PYY$d > 0), sum(PYY$d[PYY$d > 0]), sum(head(PYY$d, 5)), 100 * sum(head(PYY$d, 5)) / neg))
print(head(PYY, 8), digits = 3, row.names = FALSE)

# =====================================================================
cat("\n=== C4. DATA ONLY: does GCB's own budget carry the atmosphere's ENSO timing and size? ===\n")
# The land-sink row scores GCB's S_LAND, a DGVM ensemble. The atmosphere's own land sink is the budget residual
# fossil + luc - atm_growth - ocean_sink - cement_carbonation; the two differ by GCB's imbalance, exactly.
# Annual resolution: the monthly index read k months late, then calendar-year means. Detrended as the growth is.
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
gcb$land_resid <- gcb$fossil + gcb$luc - gcb$atm_growth - gcb$ocean_sink - gcb$cement_carbonation
cat(sprintf("  identity: residual sink - S_LAND - imbalance, max |.| %.1e GtC/yr\n", max(abs(gcb$land_resid - gcb$land_sink - gcb$imbalance))))
CUT_C4_SHIFTS <- -6:18; CUT_C4_WINS <- list(c(1959L, 2024L), BR_WIN)
kk <- RC$F$year * 12L + RC$F$month
ann_idx <- function(sh) { v <- RC$F$enso[match(kk - sh, kk)]; tapply(v, RC$F$year, mean) }
IDX <- sapply(CUT_C4_SHIFTS, function(sh) ann_idx(sh))
C4 <- do.call(rbind, lapply(CUT_C4_WINS, function(win) { g <- gcb[gcb$year >= win[1] & gcb$year <= win[2], ]
  Qg <- qmaker(g$year); X <- IDX[as.character(g$year), , drop = FALSE]
  series <- list(atm_growth = g$atm_growth, land_source_atm = -g$land_resid, land_source_dgvm = -g$land_sink,
                 imbalance = g$imbalance)
  do.call(rbind, lapply(names(series), function(nm) { y <- Qg(series[[nm]])
    rr <- apply(X, 2, function(x) stats::cor(y, Qg(x)))
    j <- which.max(abs(rr)); xs <- Qg(X[, j])
    data.frame(window = sprintf("%d-%d", win[1], win[2]), series = nm, peak_shift = CUT_C4_SHIFTS[j], r_peak = rr[j],
               r_0 = rr[CUT_C4_SHIFTS == 0], r_5 = rr[CUT_C4_SHIFTS == CUT_LAG_OBS],
               slope = unname(stats::coef(stats::lm(y ~ xs - 1))[1]), sd = stats::sd(y)) })) }))
cat("  correlation with Nino 3.4 read 'peak_shift' months late (annual means; sources positive), and the slope there (GtC/yr per index unit):\n")
print(C4, digits = 3, row.names = FALSE)
for (win in CUT_C4_WINS) { g <- gcb[gcb$year >= win[1] & gcb$year <= win[2], ]; Qg <- qmaker(g$year)
  a <- Qg(g$land_resid); d <- Qg(g$land_sink)
  cat(sprintf("  %d-%d: the atmosphere's land sink regressed on the DGVMs' (detrended): slope %.2f, r %.2f; sd %.3f vs %.3f GtC/yr\n",
              win[1], win[2], unname(stats::coef(stats::lm(a ~ d - 1))[1]), stats::cor(a, d), stats::sd(a), stats::sd(d))) }

sink()
saveRDS(list(id0 = id0[c("logpost", "lik", "streams")], prof = PROF, opt = OPT, A1 = A1, A2 = A2, gs = GS, gsb = GSB,
             rowtab = rowtab, B = lapply(RES[c("B1", "B2", "B3")], `[`, c("L", "block", "logpost", "lik", "streams", "converged", "rounds", "minutes")),
             futures = FUT, c1 = C1T, L_noseas = L_noseas, L_with = L_with, rec_1006 = REC$tabT[, c("L", "lik")],
             c2 = C2, c2_sum = C2S, g2 = G2, per_year = PYY, n_eff = NE, canonical = CAN,
             b1_steps = DST, land_sink_years = LS, c1_rows_at_obs_lag = dC1, c4 = C4,
             series = list(k = k_ref, obs = B$m$obs, canonical = can_m, A1 = Qm(gm(R_A1)), A2 = Qm(gm(R_A2)), year = y_ref,
                           obs_a = B$a$obs, canonical_a = can_a, A1_a = Qa(ga(R_A1))),
             provenance = list(driver = CUT_DRIVER, commit = COMMIT, mode = CUT_MODE, mode_file = MODE_FILE, mode_md5 = MODE_MD5,
                               window = BR_WIN, trend_df = BR_TREND_DF, obs_weekly = BR_OBS_WEEKLY, obs_annual = CUT_ANNUAL_OBS,
                               lags_A = CUT_LAGS_A, lags_C1 = CUT_LAGS_C1, lags_C2 = CUT_LAGS_C2, rest = CUT_REST, seas_block = CUT_SEASB,
                               seas_rows = SEAS_ROWS, rec_1006 = CUT_REC_1006, rng = "none", smoke = CUT_SMOKE,
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(CUT_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", CUT_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
