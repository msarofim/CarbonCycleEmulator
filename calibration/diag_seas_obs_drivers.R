# =====================================================================
# diag_seas_obs_drivers.R -- WHAT HAPPENS IF THE SEASONAL DRIVERS ARE SET
# TO THE VALUES THAT WERE JUST MEASURED?
#
# THE QUESTION. The 08-20e downloads gave observed values for all four seasonal
# temperature knobs and for the SST phase constant (data/obs_seasonal_clim.rds).
# The fit sits 25x below the observed ocean amplitudes and 3-4x above the
# observed land ones. On 08-20 the single test that was run -- raise
# sst_seas_amp_NH from 0.089 to 2.0, leave everything else -- cost 673 log-units,
# and that number has been the reason the ocean channel stays off.
#
# THAT TEST WAS AMPLITUDE-ONLY, AND HANDOFF 2026-08-20c SECTION 2d SAYS NOT TO
# TRUST ONE. Every seasonal row scores a sin AND a cos, so raising an amplitude
# at the wrong phase is penalised twice over. And we now know the phase IS
# wrong: CCX_SST_SEAS_LAG ships at 2.50 against an observed NH SST peak of 1.32
# -- 1.18 months late, and never fitted (R/model.R calls it "a prior belief",
# unidentifiable precisely because the amplitude it phases is ~0).
#
# SO THIS IS A 2 x 3 FACTORIAL, not a direction test. Amplitude and phase are
# varied SEPARATELY, because the whole point is that the 08-20 result cannot
# distinguish them:
#   phase:      CCX_SST_SEAS_LAG in {2.50 shipped, 1.32 observed}
#   amplitude:  {fitted, ocean observed, ocean AND land observed}
# The land amplitudes come along in the third column because seas_T_amp_* is
# ordinary parameter and costs nothing extra to set; the ocean/land split is
# what the whole arc is about, so moving one without the other would be its own
# amplitude-only trap.
#
# THE LAG IS A COMPILE-TIME CONSTANT with a hardcoded twin in
# src/ccx_core.cpp, so it cannot be varied inside one R session. Patched +
# rebuilt + run in a fresh process in a tempdir() COPY, never the working tree
# -- the idiom and most of the scaffolding are from diag_seas_lag_profile.R.
# The worker GATES that the patch took before spending a run: an unpatched
# constant returning the incumbent's number under a challenger's label is the
# worst failure available here.
#
# WHAT THIS DOES NOT DO. It does not refit. Every other parameter stays at the
# arm-N mode, which is a mode fitted UNDER the shipped constants -- so the
# challengers are being scored on the incumbent's home ground
# (match_incumbents_optim). A loss here is therefore weak evidence against, and
# a WIN is strong evidence for.
#
# Usage:  Rscript calibration/diag_seas_obs_drivers.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

OD_MODE_FILE <- file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
OD_CLIM      <- file.path("data", "obs_seasonal_clim.rds")
sc <- readRDS(ccx_path(OD_CLIM))
wk <- sprintf("%%s_%d-%d", sc$sst_window[1], sc$sst_window[2])
# EVERY observed number below is READ from the climatology product, never typed.
OD_SST_OBS  <- c(NH = sc$ocean[[sprintf(wk, "NH")]]$half_amp,
                 SH = sc$ocean[[sprintf(wk, "SH")]]$half_amp)
OD_LAND_OBS <- c(NH = sc$land[["NH_all"]]$half_amp, SH = sc$land[["SH_all"]]$half_amp)
OD_LAG_OBS  <- round(sc$ocean[[sprintf(wk, "NH")]]$model_lag, 2)
OD_LAGS     <- c(shipped = CCX_SST_SEAS_LAG, observed = OD_LAG_OBS)
OD_AMPS     <- c("fitted", "ocean=obs", "ocean+land=obs")

root <- ccx_root()
work <- file.path(tempdir(), "ccx_obs_drivers")
unlink(work, recursive = TRUE)
dir.create(file.path(work, dirname(OD_MODE_FILE)), recursive = TRUE, showWarnings = FALSE)
for (d in c("R", "src", "data")) file.copy(file.path(root, d), work, recursive = TRUE)
file.copy(file.path(root, "DESIGN.md"), work)
file.copy(file.path(root, OD_MODE_FILE), file.path(work, OD_MODE_FILE))

writeLines(c(
'for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)',
'ccx_load_cpp()',
'a  <- commandArgs(TRUE); slag <- as.numeric(a[1]); which_amp <- a[2]',
'so <- as.numeric(c(a[3], a[4])); lo <- as.numeric(c(a[5], a[6]))',
'stopifnot(abs(CCX_SST_SEAS_LAG - slag) < 1e-9)   # the patch took',
'md <- readRDS(file.path("calibration","output","pump_arms","mode_fit_pumpN.rds"))',
'p <- ccx_default_params(); p$pump_mode <- md$pump_mode',
# EVERY name from par_mode, NOT intersect(names(p), ...). The fitted vector
# carries parameters that ccx_default_params() has no field for -- bomb_total,
# rep_dC, sigma_d14c, grad_off_* -- and intersect() drops them SILENTLY. The
# first version of this file used the intersect idiom borrowed from
# diag_seas_lag_profile.R (which never reads those fields, so never noticed)
# and every case died on `F$c14_bomb * NULL` = numeric(0).
'for (n in names(md$par_mode)) p[[n]] <- md$par_mode[[n]]',
'stopifnot(is.numeric(p$bomb_total), is.numeric(p$rep_dC), is.numeric(p$sigma_d14c))',
'if (which_amp != "fitted") { p$sst_seas_amp_NH <- so[1]; p$sst_seas_amp_SH <- so[2] }',
'if (which_amp == "ocean+land=obs") { p$seas_T_amp_NH <- lo[1]; p$seas_T_amp_SH <- lo[2] }',
'obs <- ccx_prepare_obs()',
'sp <- ccx_spinup(p)',
'F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)',
'F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (p$bomb_total / 102)',
'for (cc in c("e_luc_NH","e_luc_SH","cum_luc_NH","cum_luc_SH")) F[[cc]] <- F[[cc]] * p$luc_scale',
'attr(F, "luc_scale") <- p$luc_scale',
'el <- ccx_forcing_eluc_annual(F); el$eluc <- el$eluc * p$luc_scale',
'r <- ccx_run_fast(sp, F); out <- r$out',
'bs <- ccx_loglik(out, obs, list(sigma_d14c = p$sigma_d14c, rep_dC = p$rep_dC,',
'        grad_off_co2 = p$grad_off_co2, grad_off_d13c = p$grad_off_d13c),',
'        luc = el, deep = sp$diagnostics$d14c_bottom_box,',
'        ocean_grad = ccx_ocean_grad_scored(out, sp), by_stream = TRUE)',
'ms <- ccx_model_stats(out, obs)',
'amp <- function(x) 2 * sqrt(mean(x$a)^2 + mean(x$b)^2)',
'sq <- c("co2_seasonal_MLO","co2_seasonal_SPO","d13c_seasonal_MLO","d13c_seasonal_SPO")',
'cat(sprintf("RESULT %.2f %s %.1f %.1f %.3f %.3f %.5f %.5f %s\\n", slag, which_amp,',
'  sum(unlist(bs)), sum(unlist(bs[sq])),',
'  amp(ms$co2_seas$MLO), amp(ms$co2_seas$SPO),',
'  amp(ms$d13_seas$MLO)/amp(ms$co2_seas$MLO), amp(ms$d13_seas$SPO)/amp(ms$co2_seas$SPO),',
'  paste(sprintf("%.1f", unlist(bs[sq])), collapse = ",")))'),
con = file.path(work, "one_case.R"))

patch_lag <- function(sl) {
  m <- readLines(file.path(work, "R", "model.R"))
  m <- sub("^CCX_SST_SEAS_LAG <- [0-9.]+", sprintf("CCX_SST_SEAS_LAG <- %s", sl), m)
  writeLines(m, file.path(work, "R", "model.R"))
  cc <- readLines(file.path(work, "src", "ccx_core.cpp"))
  cc <- sub("^static const double SST_SEAS_LAG = [0-9.]+;",
            sprintf("static const double SST_SEAS_LAG = %s;", sl), cc)
  writeLines(cc, file.path(work, "src", "ccx_core.cpp"))
  stopifnot(any(grepl(sprintf("SST_SEAS_LAG = %s;", sl), cc, fixed = TRUE)))
}
run_case <- function(sl, wa) {
  # stderr is CAPTURED, not discarded: a swallowed worker error shows up here
  # as a row of NAs with no explanation, which cost one debugging cycle.
  o <- suppressWarnings(system2("Rscript",
        c("one_case.R", sl, wa, OD_SST_OBS[["NH"]], OD_SST_OBS[["SH"]],
          OD_LAND_OBS[["NH"]], OD_LAND_OBS[["SH"]]), stdout = TRUE, stderr = TRUE))
  r <- grep("^RESULT", o, value = TRUE)
  if (!length(r)) {
    cat(sprintf("\n*** worker failed at lag %s, amps %s:\n", sl, wa))
    cat(paste0("    ", utils::tail(o, 8), collapse = "\n"), "\n")
    sprintf("RESULT %s %s FAILED", sl, wa)
  } else r[1]
}

owd <- setwd(work); on.exit(setwd(owd))
cat(sprintf("observed, read from %s:\n  sst half-amp NH %.3f SH %.3f K | land half-amp NH %.2f SH %.2f K | SST lag %.2f mo\n",
            OD_CLIM, OD_SST_OBS[["NH"]], OD_SST_OBS[["SH"]],
            OD_LAND_OBS[["NH"]], OD_LAND_OBS[["SH"]], OD_LAG_OBS))
cat(sprintf("shipped CCX_SST_SEAS_LAG %.2f | observed MLO CO2 p2p 6.754, SPO 1.170;",
            CCX_SST_SEAS_LAG))
cat(" signatures 0.0528 / 0.0288 permil/ppm\n")
cat("\nEvery cell is the arm-N mode with ONLY the named quantities changed.\n")

rows <- list()
for (ln in names(OD_LAGS)) {
  patch_lag(OD_LAGS[[ln]])
  for (wa in OD_AMPS) rows[[length(rows) + 1]] <- c(ln, run_case(OD_LAGS[[ln]], wa))
}
cat(sprintf("\n%-9s %-9s %-16s %11s %11s %9s %9s %9s %9s\n", "SST lag", "value",
            "amplitudes", "total logL", "seas logL", "MLO p2p", "SPO p2p",
            "sig MLO", "sig SPO"))
for (rr in rows) {
  f <- strsplit(sub("^RESULT ", "", rr[2]), " ")[[1]]
  cat(sprintf("%-9s %-9s %-16s %11s %11s %9s %9s %9s %9s   [%s]\n",
              rr[1], f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8], f[9]))
}
cat("\nper-stream order: co2_MLO, co2_SPO, d13c_MLO, d13c_SPO\n")
cat("sig = seasonal d13C amplitude per ppm of seasonal CO2 amplitude. Observed\n")
cat("0.0528 (MLO) / 0.0288 (SPO); the mode gives 0.0809 / 0.0963. LOWER IS BETTER.\n")
