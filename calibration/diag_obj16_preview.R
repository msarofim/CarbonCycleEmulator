#!/usr/bin/env Rscript
# =====================================================================
# diag_obj16_preview.R -- the numbers two PROPOSALS need before Marcus rules (2026-10-04 h):
#   T  "Draft a timing-row proposal" (the handoff's item 2): the land ENSO lag the rows set (2.64
#      months) vs the atmosphere's growth timing (5). WHERE WOULD AN AMPLITUDE-FREE GROWTH-SHAPE ROW
#      PUT THE LAG, at each candidate weight, and what would it cost and move?
#   G  "Revisit the npp_tsens prior" (the greening sign, CHANGELOG 10-04 e): WHAT EACH CANDIDATE PRIOR
#      DOES to npp_tsens and the futures, and how the model's NET CLIMATE EFFECT on the land sink
#      compares with GCB 2025's TRENDY value (-0.8 +/- 0.7 GtC/yr, 2015-24; lit note G3).
# Both are CONDITIONAL slices at hilda34g (26 or 27 names held): a refit gives the joint answer.
# ⛔ ADOPTS NOTHING; moves no stored value; changes no objective. No RNG.
#
# T. At the lag arm's base, lags L = 1, 2, 3, 4, 6, 8 months with the 8-name land block re-optimised
#    (lib_block_reopt.R's br_cell); L = 0, 2.644, 5 are READ from the 10-04 (e) run (both starts agreed
#    there). At each L: the existing rows' likelihood, the section-6 timing statistics, the futures. The
#    candidate row is the regression of the observed detrended growth on the model's with a FREE slope
#    and free variance, i.e. its profile log-likelihood -(n_eff / 2) log(1 - r^2), r the detrended
#    correlation (amplitude-free by construction: the 09-26 objection 3). n_eff is MEASURED (Bretherton
#    et al. 1999, J. Climate 12:1990, eq. 31: n (1 - r1x r1y) / (1 + r1x r1y), lag-1 autocorrelations of
#    the two detrended series) and the row's lag is read at multiples of it -- the WEIGHT is the ruling.
# G. At the lag arm's own lag, npp_tsens HELD at 0, -0.006 (MAGICC6's C4MIP mean, lit note G9) and
#    -0.012, the other 7 block names re-optimised; with the mode, a 4-point profile. At each: the
#    likelihood, futures and the net climate effect (br_net_climate()); the same effect at the control.
#    The profile is fitted as a quadratic (10-04 e found it quadratic: symmetric +/- deficits), and each
#    candidate prior's posterior mode follows analytically.
# Usage: Rscript calibration/diag_obj16_preview.R   (CCX_OP_WORKERS=<n>, default 3; CCX_OP_SMOKE=1)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
OP_DRIVER     <- "calibration/diag_obj16_preview.R"
OP_SMOKE      <- identical(Sys.getenv("CCX_OP_SMOKE", ""), "1")
OP_WORKERS    <- as.integer(Sys.getenv("CCX_OP_WORKERS", "3"))
BR_LABEL_LAG  <- "hilda_csl3v0kaidgbe"
BR_LABEL_ZERO <- "hilda_csl3v0kaidgb"
OP_BASES      <- c(LAG = ccx_mode_file("hilda34g"),
                   CTL = file.path("calibration", "output", "refit_20261003_obj15_hilda_csl3v0kaidgb", "mode_fit_pumpN.rds"))
OP_GREEN      <- "npp_tsens"
OP_BLOCK      <- c(OP_GREEN, "beta_max", "fert_k", "gamma_enso_land_NH", "gamma_enso_land_SH", "luc_scale", "imb_share_land", "ndep_ret")
OP_LAGS_NEW   <- c(1, 2, 3, 4, 6, 8)                     # months, run here
OP_GS_RUN     <- file.path("outputs", "diagnostics", "greening_lag_swap_20261004.rds")   # L = 0, 2.644, 5 (10-04 e)
OP_LAG_OBS    <- 5                                       # observed growth peaks 5 months after Nino 3.4 (10-02 x)
OP_W_MULT     <- c(1, 2, 5, 10)                          # the row's weight in multiples of the MEASURED n_eff
OP_NU_HOLD    <- c(0, -0.006, -0.012)                    # /K: 0; MAGICC6 C4MIP mean (lit G9); twice it
# candidate priors on npp_tsens, N(mean, sd), with their receipts
OP_PRIORS <- list(
  P0_sign_free   = c(mean = 0,      sd = ccx_const("NPP_TSENS_PRIOR_SD"), src = NA),   # ruled 09-30 (the status quo)
  P1_c4mip_mean  = c(mean = -0.006, sd = ccx_const("NPP_TSENS_PRIOR_SD"), src = NA),   # MAGICC6 Table B4 mean (lit G9)
  P2_cmip6_conv  = c(mean = -29.4 / (33 * 60), sd = 40.1 / (33 * 60), src = NA))       # Varney 2024 gamma_NPP / (tau0 33 yr x NPP0 60): MY conversion
OP_GCB_NET    <- c(mean = -0.8, sd = 0.7)                # GtC/yr, 2015-24, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
OP_NET_WIN    <- c(2015L, 2024L); OP_NET_CLIM <- c(1901L, 1920L)
BR_WIN <- c(1980L, 2024L); BR_TREND_DF <- 5L; BR_XLAGS <- -6:18
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
OP_ANNUAL_OBS <- file.path("data", "mbl_global_growth.rds")   # NOAA MBL, the app's estimator (09-26)
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
if (OP_SMOKE) { BR_BFGS_MAXIT <- 2L; BR_NM_MAXIT <- 10L; BR_ROUNDS <- 1L }
OP_TAG  <- paste0(format(Sys.Date(), "%Y%m%d"), if (OP_SMOKE) "_SMOKE" else "")
OP_OUT  <- file.path("outputs", "diagnostics", sprintf("obj16_preview_%s", OP_TAG))
COMMIT  <- ccx_git_stamp()
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))      # objective #15
source(file.path("calibration", "lib_block_reopt.R"))
LOGCON <- file(paste0(OP_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | %d workers%s\n", OP_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), OP_WORKERS,
            if (OP_SMOKE) " | ⚠ SMOKE: tiny optimiser budget, NOT A RESULT" else ""))

BR_OBS <- ccx_prepare_obs()
BR_MD  <- lapply(OP_BASES, readRDS)
stopifnot(identical(ccx_mode_struct(BR_MD$LAG), BR_LABEL_LAG), identical(ccx_mode_struct(BR_MD$CTL), BR_LABEL_ZERO))
BR_PINS <- stats::setNames(as.numeric(BR_MD$LAG$pins), names(BR_MD$LAG$pins))
BR_SPF <- lapply(BR_MD, function(md) ccx_spinup_from_label(ccx_mode_spinup(md)))
BR_VB  <- lapply(OP_BASES, dg_vector)
L_LAG  <- BR_MD$LAG$par_mode[["lag_enso_land"]]
OBS_G  <- br_obs_growth()
ANN    <- readRDS(OP_ANNUAL_OBS)$growth

# ---- 0. identity: the base reproduces, and its runs reproduce the 10-04 (e) record ------------------
cat("\n=== 0. IDENTITY ===\n")
GS <- readRDS(OP_GS_RUN)
id0 <- br_cell("LAG", L_LAG, OP_BLOCK, max_rounds = 0L)
cat(sprintf("  LAG at L %.4f: logpost %.6f (stored %.6f); max |whitened slope| %.4f\n", L_LAG, id0$logpost, BR_MD$LAG$logpost, max(abs(id0$slope))))
if (abs(id0$logpost - BR_MD$LAG$logpost) > 1e-6 || !id0$converged) stop("the base does not reproduce")
run_of <- function(b, block, L) { v <- br_vec(b, block, L); r <- dg_run(v); tm <- br_timing(r$out, r$F, OBS_G)
  fu <- br_futures(v, r$sp)
  # the ANNUAL estimator (the app's, 09-26): the model's difference of annual means vs NOAA MBL's
  co2 <- tapply((r$out$co2_NH + r$out$co2_SH) / 2, floor(r$out$t), mean)
  gm <- data.frame(year = as.integer(names(co2))[-1], g_mod = diff(as.numeric(co2)))
  A <- merge(gm, stats::setNames(ANN[, 1:2], c("year", "g_obs")), by = "year")
  A <- A[A$year >= BR_WIN[1] & A$year <= BR_WIN[2], ]
  dA <- function(g) stats::residuals(stats::lm(g ~ splines::ns(A$year, df = BR_TREND_DF)))
  am <- dA(A$g_mod); ao <- dA(A$g_obs)
  list(timing = tm$stats, detr_mod = tm$detr_mod, detr_obs = tm$detr_obs, ann_mod = am, ann_obs = ao,
       r_annual = stats::cor(am, ao), futures = stats::setNames(fu, sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR)), v = v) }
RUN0 <- run_of("LAG", id0$block, L_LAG)
# the 10-04 (e) IDENTITY cell (start "own" at the base's own lag, i.e. the mode itself) -- not the best-logpost
# row, which at this lag is the OTHER start's optimum (nu 0.008871 vs the mode's 0.008854; futures +0.06 ppm)
tg <- GS$cells[GS$cells$base == "LAG" & GS$cells$kind == "A" & GS$cells$start == "own" & abs(GS$cells$L - L_LAG) < 1e-3, ]
stopifnot(nrow(tg) == 1L)
cat(sprintf("  runs: growth peak %+d (10-04 e %+d), r_mod_obs %.6f (%.6f), ssp585 2300 %.4f (%.4f)\n",
            as.integer(RUN0$timing[["peak_mod"]]), as.integer(tg$peak), RUN0$timing[["r_mod_obs"]], tg$r_obs,
            RUN0$futures[[1]], tg$ssp585))
if (RUN0$timing[["peak_mod"]] != tg$peak || abs(RUN0$timing[["r_mod_obs"]] - tg$r_obs) > 1e-6 || abs(RUN0$futures[[1]] - tg$ssp585) > 1e-6)
  stop("the base's runs do not reproduce the 10-04 (e) record")

# ---- the cells, forked: T's lags and G's held values ---------------------------------------------
JOBS <- c(lapply(OP_LAGS_NEW, function(L) list(part = "T", L = L, hold = NULL)),
          lapply(OP_NU_HOLD, function(nu) list(part = "G", L = L_LAG, hold = stats::setNames(nu, OP_GREEN))))
cat(sprintf("\n=== cells: %d on %d forked workers ===\n", length(JOBS), OP_WORKERS))
flush(LOGCON)
RES <- parallel::mclapply(JOBS, function(j) { while (sink.number() > 0L) sink()
  free <- if (is.null(j$hold)) OP_BLOCK else setdiff(OP_BLOCK, names(j$hold))
  o <- br_cell("LAG", j$L, free, hold = j$hold)
  rr <- run_of("LAG", o$block, j$L)
  o$runs <- rr[c("timing", "detr_mod", "detr_obs", "ann_mod", "ann_obs", "r_annual", "futures")]
  if (j$part == "G") o$net <- br_net_climate(rr$v, OP_NET_WIN, OP_NET_CLIM)
  o$part <- j$part; o }, mc.cores = OP_WORKERS, mc.preschedule = FALSE)
bad <- vapply(RES, function(o) inherits(o, "try-error") || !is.list(o) || is.null(o$logpost), TRUE)
if (any(bad)) stop(sum(bad), " cell(s) FAILED")
saveRDS(list(jobs = JOBS, res = RES, commit = COMMIT), paste0(OP_OUT, "_cells.rds"))

# ---- T. the lag profile and the row ----------------------------------------------------------------------------
cat("\n=== T. THE LAG PROFILE at the lag arm's base (the 8-name land block re-optimised) and the candidate growth-shape row ===\n")
gsA <- Filter(function(o) o$kind == "A" && o$base == "LAG", GS$all)
best_gs <- function(L) { c <- Filter(function(o) abs(o$L - L) < 1e-6, gsA); c[[which.max(vapply(c, `[[`, 0, "logpost"))]] }
old <- lapply(c(0, L_LAG, OP_LAG_OBS), function(L) { o <- best_gs(L); rr <- run_of("LAG", o$block, L)
  c(o[c("L", "logpost", "lik", "block", "converged")], list(runs = rr[c("timing", "detr_mod", "detr_obs", "ann_mod", "ann_obs", "r_annual", "futures")], part = "T(10-04 e)")) })
TT <- c(old, Filter(function(o) o$part == "T", RES))
TT <- TT[order(vapply(TT, `[[`, 0, "L"))]
tabT <- do.call(rbind, lapply(TT, function(o) data.frame(L = o$L, lik = o$lik, d_lik = NA, npp_tsens = o$block[[OP_GREEN]],
  beta_max = o$block[["beta_max"]], peak = o$runs$timing[["peak_mod"]], r_monthly = o$runs$timing[["r_mod_obs"]],
  r_annual = o$runs$r_annual, ssp585 = o$runs$futures[[1]], vvH = o$runs$futures[[2]], conv = isTRUE(o$converged))))
tabT$d_lik <- tabT$lik - tabT$lik[which.min(abs(tabT$L - L_LAG))]
print(tabT, digits = 5, row.names = FALSE)
# n_eff (Bretherton 1999 eq. 31) of the detrended series, at the base
r1 <- function(x) stats::acf(x, lag.max = 1, plot = FALSE)$acf[2]
neff <- function(x, y) length(x) * (1 - r1(x) * r1(y)) / (1 + r1(x) * r1(y))
B0 <- TT[[which.min(abs(vapply(TT, `[[`, 0, "L") - L_LAG))]]$runs
NE <- c(monthly = neff(B0$detr_mod, B0$detr_obs), annual = neff(B0$ann_mod, B0$ann_obs))
cat(sprintf("  n_eff at the base (Bretherton 1999 eq. 31): monthly %.1f of %d points (lag-1 r: model %.3f, obs %.3f); annual %.1f of %d (%.3f, %.3f)\n",
            NE[["monthly"]], length(B0$detr_mod), r1(B0$detr_mod), r1(B0$detr_obs), NE[["annual"]], length(B0$ann_mod), r1(B0$ann_mod), r1(B0$ann_obs)))
# the row's lag at each weight: spline through the profile, maximise lik + row on a fine grid
fine <- seq(min(tabT$L), max(tabT$L), by = 0.05)
sp_lik <- stats::splinefun(tabT$L, tabT$lik, method = "natural")
ROWS <- list()
for (est in c("monthly", "annual")) {
  rr <- if (est == "monthly") tabT$r_monthly else tabT$r_annual
  sp_r <- stats::splinefun(tabT$L, rr, method = "natural")
  for (m in OP_W_MULT) { w <- m * NE[[est]]
    tot <- sp_lik(fine) - (w / 2) * log(1 - pmax(sp_r(fine), 0)^2)
    Ls <- fine[which.max(tot)]
    ROWS[[length(ROWS) + 1L]] <- data.frame(estimator = est, weight = sprintf("%g x n_eff = %.1f", m, w), L_star = Ls,
      lik_cost = sp_lik(Ls) - sp_lik(L_LAG), row_gain = -(w / 2) * (log(1 - pmax(sp_r(Ls), 0)^2) - log(1 - pmax(sp_r(L_LAG), 0)^2)),
      ssp585 = stats::splinefun(tabT$L, tabT$ssp585, method = "natural")(Ls), npp_tsens = stats::splinefun(tabT$L, tabT$npp_tsens, method = "natural")(Ls)) }
}
ROWT <- do.call(rbind, ROWS)
cat("  where the row would put the lag (a conditional preview: the land block was optimised WITHOUT the row):\n")
print(ROWT, digits = 4, row.names = FALSE)
cat(sprintf("  (L_star = the lag maximising [existing rows + the row]; lik_cost = what the existing rows lose vs L %.3f; observed timing %g months)\n", L_LAG, OP_LAG_OBS))

# ---- G. the greening prior ----------------------------------------------------------------------------------
cat("\n=== G. THE GREENING PRIOR: npp_tsens held at the lag arm's lag (the other 7 names re-optimised) ===\n")
GG <- c(list(c(id0[c("L", "logpost", "lik", "block", "converged")], list(runs = RUN0[c("timing", "futures")], net = br_net_climate(RUN0$v, OP_NET_WIN, OP_NET_CLIM), part = "mode"))),
        Filter(function(o) o$part == "G", RES))
tabG <- do.call(rbind, lapply(GG, function(o) data.frame(npp_tsens = o$block[[OP_GREEN]], beta_max = o$block[["beta_max"]],
  logpost = o$logpost, lik = o$lik, ssp585 = o$runs$futures[[1]], vvH = o$runs$futures[[2]], net_climate = o$net[["net_climate"]],
  conv = isTRUE(o$converged))))
tabG <- tabG[order(tabG$npp_tsens), ]
# the prior's own term, so the profile can be read on the likelihood alone (the sign-free prior sits in the logpost)
pr0 <- function(nu) stats::dnorm(nu, OP_PRIORS$P0_sign_free[["mean"]], OP_PRIORS$P0_sign_free[["sd"]], log = TRUE)
tabG$lik_plus_rest <- tabG$logpost - pr0(tabG$npp_tsens)       # the logpost without npp_tsens's own prior
print(tabG, digits = 6, row.names = FALSE)
ctl_net <- br_net_climate(BR_VB$CTL, OP_NET_WIN, OP_NET_CLIM)
cat(sprintf("  the net climate effect on the land sink, %d-%d vs %d-%d climate held (GCB 2025 TRENDY: %+.1f +/- %.1f GtC/yr): lag arm %+.3f, control %+.3f GtC/yr\n",
            OP_NET_WIN[1], OP_NET_WIN[2], OP_NET_CLIM[1], OP_NET_CLIM[2], OP_GCB_NET[["mean"]], OP_GCB_NET[["sd"]],
            tabG$net_climate[which.max(tabG$npp_tsens)], ctl_net[["net_climate"]]))
q <- stats::lm(lik_plus_rest ~ npp_tsens + I(npp_tsens^2), data = tabG)
a2 <- stats::coef(q)[[3]]; a1 <- stats::coef(q)[[2]]
nu_d <- -a1 / (2 * a2); sd_d <- sqrt(-1 / (2 * a2))
cat(sprintf("  the profile WITHOUT npp_tsens's prior, quadratic through %d points: optimum %+.5f /K, sd %.5f (max |residual| %.3f log-units)\n",
            nrow(tabG), nu_d, sd_d, max(abs(stats::residuals(q)))))
sp_fut <- stats::splinefun(tabG$npp_tsens, tabG$ssp585, method = "natural"); sp_net <- stats::splinefun(tabG$npp_tsens, tabG$net_climate, method = "natural")
PR <- do.call(rbind, lapply(names(OP_PRIORS), function(k) { p <- OP_PRIORS[[k]]
  prec <- 1 / sd_d^2 + 1 / p[["sd"]]^2; nu <- (nu_d / sd_d^2 + p[["mean"]] / p[["sd"]]^2) / prec
  data.frame(prior = k, mean = p[["mean"]], sd = p[["sd"]], nu_mode = nu, nu_sd = sqrt(1 / prec), ssp585_2300 = sp_fut(nu), net_climate = sp_net(nu)) }))
# the GCB net-climate ROW instead of a prior: Gaussian on the model's net effect, through its dependence on nu
net_row <- function(nu) stats::dnorm(sp_net(nu), OP_GCB_NET[["mean"]], OP_GCB_NET[["sd"]], log = TRUE)
fine_nu <- seq(-0.02, 0.02, by = 1e-5)
tot <- -0.5 * ((fine_nu - nu_d) / sd_d)^2 + pr0(fine_nu) + net_row(fine_nu)
nu_r <- fine_nu[which.max(tot)]
PR <- rbind(PR, data.frame(prior = "P3_gcb_net_row (+ the sign-free prior)", mean = NA, sd = NA, nu_mode = nu_r, nu_sd = NA,
                           ssp585_2300 = sp_fut(nu_r), net_climate = sp_net(nu_r)))
cat("  each candidate's posterior mode (analytic on the quadratic profile; futures and net effect interpolated from the 4 points):\n")
print(PR, digits = 4, row.names = FALSE)
cat("  ⚠ P2 is MY conversion of Varney 2024's gamma_NPP (Pg C/K) with tau0 = C/NPP ~ 33 yr and NPP0 = 60; not a published number.\n")
cat("  ⚠ P3 attributes the whole net effect to npp_tsens with q10 HELD at the canonical's: q10 is its partner (lit note G15, rho -0.89).\n")

sink(); close(LOGCON)
saveRDS(list(timing = list(table = tabT, n_eff = NE, row = ROWT), greening = list(table = tabG, quad = c(nu_d = nu_d, sd_d = sd_d),
             priors = PR, ctl_net = ctl_net), cells = RES,
             provenance = sprintf("%s @%s; base hilda34g (%s); control %s; block %s; lags %s (+ 0/%.3f/5 from %s); nu held %s; objective #15; no RNG; %s",
                                  OP_DRIVER, COMMIT, OP_BASES[["LAG"]], OP_BASES[["CTL"]], paste(OP_BLOCK, collapse = ","),
                                  paste(OP_LAGS_NEW, collapse = ","), L_LAG, OP_GS_RUN, paste(OP_NU_HOLD, collapse = ","), format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(OP_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", OP_OUT))
