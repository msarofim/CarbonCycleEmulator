#!/usr/bin/env Rscript
# =====================================================================
# diag_timing_row_reread.R -- the 10-04 (i) TIMING-ROW preview's part T, re-read at the CANONICAL (2026-10-06).
#
# WHY. Marcus 2026-10-06 (carbotopecomments.10.2.26): "Card 4: re-measure the 'about three months'." The figure
# is what an amplitude-free growth-timing row, given the weight its year-to-year information supports, would do
# to the fitted land ENSO lag. 10-04 (i) measured it at hilda34g (calibration/diag_obj16_preview.R part T,
# outputs/diagnostics/obj16_preview_20261004.log): L* 2.75 months (monthly estimator) / 2.90 (annual) at 1x the
# measured n_eff, against the fitted 2.644. hilda33p is the canonical since 10-06 (a); this re-reads the same
# quantity there, by the same method:
#   - at lags L = 1, 2, 3, 4, 5, 6, 8 months the land block is RE-OPTIMISED (lib_block_reopt.R br_cell, the
#     10-04 machinery, its own tolerances); the mode's own lag is the identity cell (0 rounds);
#   - at each L: the existing rows' likelihood, the refit read's s. 6 timing statistics (monthly, centred
#     12-month growth, 1980-2024 against NOAA MBL), the ANNUAL detrended correlation (the app's estimator),
#     and the futures (SSP5-8.5 unspliced, vvH spliced, CO2 in 2300);
#   - the candidate row is -(w/2) log(1 - r^2), w a multiple of the measured n_eff (Bretherton et al. 1999,
#     J. Climate 12:1990, eq. 31); L* maximises [the profile + the row] on a natural spline through the cells.
# DIFFERENCES FROM 10-04, each forced by the canonical, none a choice:
#   - the block is SEVEN names: npp_tsens is PINNED at 0 in hilda33p (objective #16, P4), so it is held;
#   - no L = 0 cell: the lag-0 label of #16's structure does not exist (the stratification feedback's label
#     opens the lag gate); the profile's optimum and every L* sit in [2.6, 5.3], inside the grid.
# ⛔ A CONDITIONAL preview, as 10-04's was: the block is optimised WITHOUT the row. ADOPTS NOTHING; moves no
# stored value; changes no objective. No RNG.
# Usage: Rscript calibration/diag_timing_row_reread.R   (CCX_TR_WORKERS=<n>, default 4; CCX_TR_SMOKE=1)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
TR_DRIVER   <- "calibration/diag_timing_row_reread.R"
TR_SMOKE    <- identical(Sys.getenv("CCX_TR_SMOKE", ""), "1")
TR_WORKERS  <- as.integer(Sys.getenv("CCX_TR_WORKERS", "4"))
TR_MODE     <- CCX_MODE_CANONICAL
TR_BLOCK    <- c("beta_max", "fert_k", "gamma_enso_land_NH", "gamma_enso_land_SH", "luc_scale", "imb_share_land", "ndep_ret")
TR_LAGS     <- c(1, 2, 3, 4, 5, 6, 8)                  # months, re-optimised here
TR_W_MULT   <- c(1, 2, 5, 10)                          # the row's weight in multiples of the MEASURED n_eff
TR_LAG_OBS  <- 5                                       # the record's growth peak after Nino 3.4 (10-02 x; 10-06 g)
TR_REC_1004 <- c(monthly = 2.75, annual = 2.90, L_fit = 2.644)   # 10-04 (i) at hilda34g, for the comparison line
BR_WIN <- c(1980L, 2024L); BR_TREND_DF <- 5L; BR_XLAGS <- -6:18
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
TR_ANNUAL_OBS <- file.path("data", "mbl_global_growth.rds")   # NOAA MBL, the app's estimator
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
if (TR_SMOKE) { BR_BFGS_MAXIT <- 2L; BR_NM_MAXIT <- 10L; BR_ROUNDS <- 1L; TR_LAGS <- c(2, 4) }
TR_TAG  <- paste0(format(Sys.Date(), "%Y%m%d"), "_", TR_MODE, if (TR_SMOKE) "_SMOKE" else "")
TR_OUT  <- file.path("outputs", "diagnostics", sprintf("timing_row_reread_%s", TR_TAG))
COMMIT  <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))
LOGCON <- file(paste0(TR_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | canonical %s | %d workers%s\n", TR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), TR_MODE,
            TR_WORKERS, if (TR_SMOKE) " | ⚠ SMOKE: tiny optimiser budget, NOT A RESULT" else ""))

# ---- the base: the canonical, its own structure, its own pins ------------------------------------------------
BR_OBS <- ccx_prepare_obs()
MODE_FILE <- ccx_mode_file(TR_MODE)
BR_MD  <- list(BASE = readRDS(MODE_FILE))
md <- BR_MD$BASE
BR_LABEL_LAG  <- ccx_mode_struct(md)
BR_LABEL_ZERO <- NA_character_                         # never used: no L = 0 cell (see the header)
BR_PINS <- stats::setNames(as.numeric(md$pins), names(md$pins))   # WITHOUT gate_struct: the cell opens its own gate
stopifnot(identical(names(BR_PINS), names(ccx_mode_pins(md))), "npp_tsens" %in% names(BR_PINS),
          !any(TR_BLOCK %in% names(BR_PINS)), all(TR_BLOCK %in% md$param_names), "lag_enso_land" %in% md$param_names)
BR_SPF <- list(BASE = ccx_spinup_from_label(ccx_mode_spinup(md)))
BR_VB  <- list(BASE = dg_vector(MODE_FILE))
L_MODE <- md$par_mode[["lag_enso_land"]]
OBS_G  <- br_obs_growth()
ANN    <- readRDS(TR_ANNUAL_OBS)$growth
cat(sprintf("mode file %s (md5 %s); struct %s; %d pins incl. npp_tsens = %g; fitted lag %.4f months\n",
            MODE_FILE, unname(tools::md5sum(MODE_FILE)), BR_LABEL_LAG, length(BR_PINS), BR_PINS[["npp_tsens"]], L_MODE))
cat(sprintf("block (%d, re-optimised at each lag): %s\n", length(TR_BLOCK), paste(TR_BLOCK, collapse = ", ")))

# the preview's run_of(), verbatim but for the base name
run_of <- function(b, block, L) { v <- br_vec(b, block, L); r <- dg_run(v); tm <- br_timing(r$out, r$F, OBS_G)
  fu <- br_futures(v, r$sp)
  co2 <- tapply((r$out$co2_NH + r$out$co2_SH) / 2, floor(r$out$t), mean)
  gm <- data.frame(year = as.integer(names(co2))[-1], g_mod = diff(as.numeric(co2)))
  A <- merge(gm, stats::setNames(ANN[, 1:2], c("year", "g_obs")), by = "year")
  A <- A[A$year >= BR_WIN[1] & A$year <= BR_WIN[2], ]
  dA <- function(g) stats::residuals(stats::lm(g ~ splines::ns(A$year, df = BR_TREND_DF)))
  am <- dA(A$g_mod); ao <- dA(A$g_obs)
  list(timing = tm$stats, detr_mod = tm$detr_mod, detr_obs = tm$detr_obs, ann_mod = am, ann_obs = ao,
       r_annual = stats::cor(am, ao), futures = stats::setNames(fu, sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR)), v = v) }

cat("\n=== 0. IDENTITY: the canonical at its own lag, 0 rounds, must reproduce its stored logpost ===\n")
id0 <- br_cell("BASE", L_MODE, TR_BLOCK, max_rounds = 0L)
cat(sprintf("  logpost %.6f (stored %.6f, diff %.1e); max |whitened slope| %.4f\n", id0$logpost, md$logpost,
            id0$logpost - md$logpost, max(abs(id0$slope))))
if (abs(id0$logpost - md$logpost) > 1e-6) stop("the base does not reproduce its stored logpost")
RUN0 <- run_of("BASE", id0$block, L_MODE)
cat(sprintf("  at the mode: growth peak %+d months (r %.3f; the record's %+d, r %.3f); annual detrended r %.4f; ssp585 2300 %.2f ppm\n",
            as.integer(RUN0$timing[["peak_mod"]]), RUN0$timing[["r_mod"]], as.integer(RUN0$timing[["peak_obs"]]),
            RUN0$timing[["r_obs"]], RUN0$r_annual, RUN0$futures[[1]]))

cat(sprintf("\n=== T. THE LAG PROFILE (the %d-name land block re-optimised at each lag) ===\n", length(TR_BLOCK)))
flush(LOGCON)
RES <- parallel::mclapply(TR_LAGS, function(L) { while (sink.number() > 0L) sink()
  o <- br_cell("BASE", L, TR_BLOCK)
  rr <- run_of("BASE", o$block, L)
  o$runs <- rr[c("timing", "detr_mod", "detr_obs", "ann_mod", "ann_obs", "r_annual", "futures")]
  o }, mc.cores = TR_WORKERS, mc.preschedule = FALSE)
bad <- vapply(RES, function(o) inherits(o, "try-error") || is.null(o$L), logical(1))
if (any(bad)) stop("a cell failed: ", paste(vapply(RES[bad], function(o) as.character(o)[1], ""), collapse = " | "))
saveRDS(list(res = RES, id0 = id0, run0 = RUN0[c("timing", "r_annual", "futures")], commit = COMMIT), paste0(TR_OUT, "_cells.rds"))

TT <- c(list(c(id0[c("L", "logpost", "lik", "block", "converged", "rounds", "minutes")],
               list(runs = RUN0[c("timing", "detr_mod", "detr_obs", "ann_mod", "ann_obs", "r_annual", "futures")]))), RES)
TT <- TT[order(vapply(TT, `[[`, 0, "L"))]
tabT <- do.call(rbind, lapply(TT, function(o) data.frame(L = o$L, lik = o$lik, d_lik = NA, beta_max = o$block[["beta_max"]],
  peak = o$runs$timing[["peak_mod"]], r_monthly = o$runs$timing[["r_mod_obs"]], r_annual = o$runs$r_annual,
  ssp585 = o$runs$futures[[1]], vvH = o$runs$futures[[2]], conv = isTRUE(o$converged), rounds = o$rounds,
  minutes = round(o$minutes, 1))))
tabT$d_lik <- tabT$lik - tabT$lik[which.min(abs(tabT$L - L_MODE))]
print(tabT, digits = 5, row.names = FALSE)
if (!all(tabT$conv)) cat("  ⚠ NOT every cell passed the whitened-slope gate (curvature-blind off the base; memory whitened_slope_gate_blind_off_base)\n")

# n_eff (Bretherton 1999 eq. 31) of the detrended series, at the mode
r1 <- function(x) stats::acf(x, lag.max = 1, plot = FALSE)$acf[2]
neff <- function(x, y) length(x) * (1 - r1(x) * r1(y)) / (1 + r1(x) * r1(y))
B0 <- RUN0
NE <- c(monthly = neff(B0$detr_mod, B0$detr_obs), annual = neff(B0$ann_mod, B0$ann_obs))
cat(sprintf("  n_eff at the mode (Bretherton 1999 eq. 31): monthly %.1f of %d points (lag-1 r: model %.3f, obs %.3f); annual %.1f of %d (%.3f, %.3f)\n",
            NE[["monthly"]], length(B0$detr_mod), r1(B0$detr_mod), r1(B0$detr_obs), NE[["annual"]], length(B0$ann_mod),
            r1(B0$ann_mod), r1(B0$ann_obs)))
fine <- seq(min(tabT$L), max(tabT$L), by = 0.05)
sp_lik <- stats::splinefun(tabT$L, tabT$lik, method = "natural")
ROWS <- list()
for (est in c("monthly", "annual")) {
  rr <- if (est == "monthly") tabT$r_monthly else tabT$r_annual
  sp_r <- stats::splinefun(tabT$L, rr, method = "natural")
  for (m in TR_W_MULT) { w <- m * NE[[est]]
    tot <- sp_lik(fine) - (w / 2) * log(1 - pmax(sp_r(fine), 0)^2)
    Ls <- fine[which.max(tot)]
    ROWS[[length(ROWS) + 1L]] <- data.frame(estimator = est, weight = sprintf("%g x n_eff = %.1f", m, w), L_star = Ls,
      lik_cost = sp_lik(Ls) - sp_lik(L_MODE), row_gain = -(w / 2) * (log(1 - pmax(sp_r(Ls), 0)^2) - log(1 - pmax(sp_r(L_MODE), 0)^2)),
      ssp585 = stats::splinefun(tabT$L, tabT$ssp585, method = "natural")(Ls)) }
}
ROWT <- do.call(rbind, ROWS)
cat("  where the row would put the lag (a conditional preview: the land block was optimised WITHOUT the row):\n")
print(ROWT, digits = 4, row.names = FALSE)
s1 <- ROWT[grepl("^1 x", ROWT$weight), ]
cat(sprintf("\nCARD 4's 'about three months': at its MEASURED weight the row puts the lag at %.2f (monthly) / %.2f (annual) months,\n  from the fitted %.3f (10-04 (i) at hilda34g: %.2f / %.2f from %.3f). The record's growth peak: %g months.\n",
            s1$L_star[s1$estimator == "monthly"], s1$L_star[s1$estimator == "annual"], L_MODE,
            TR_REC_1004[["monthly"]], TR_REC_1004[["annual"]], TR_REC_1004[["L_fit"]], TR_LAG_OBS))
sink()
saveRDS(list(tabT = tabT, rows = ROWT, n_eff = NE, L_mode = L_MODE, run0 = RUN0[c("timing", "r_annual", "futures")],
             provenance = list(driver = TR_DRIVER, commit = COMMIT, mode = TR_MODE, mode_file = MODE_FILE,
                               mode_md5 = unname(tools::md5sum(MODE_FILE)), block = TR_BLOCK, lags = TR_LAGS,
                               weights = TR_W_MULT, rng = "none", smoke = TR_SMOKE,
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(TR_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", TR_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
