# =====================================================================
# diag_seas8_photo_eps_probe_20261021.R -- T8b follow-up: is the d13C seasonal
# misfit the SIZE of the land channel's isotopic fingerprint?
#
# WHY. T8b measured every land channel at hilda31w as a clean signed scalar of
# -0.042 permil/ppm (= -alpha_photo_eps / mean CO2 = -16.2 / 380), while the OBSERVED
# MLO station signature is 0.0524 [0.0504, 0.0545] permil/ppm. A land-dominated cycle
# whose land channels carry 0.042 cannot reach 0.052 by re-weighting land against
# ocean unless the antiphase ocean channel roughly doubles. This probe moves the one
# constant that sets the land fingerprint, alpha_photo_eps, ALL ELSE AT THE MODE
# (UNREFITTED), and reads the seasonal rows, the station signature, and what the
# move costs the NON-seasonal d13C rows (the land sink's isotopic signature moves too).
# It also bootstraps the OBSERVED phase offset between the d13C cycle and the
# antiphase of the CO2 cycle: the model's land channels are scalars (offset ~0), so
# an observed offset is a timing the land channels cannot carry.
#
# THE VALUES (permil), all from the registry or the sources its entries cite:
#   15.6  CCX_ALPHA_PHOTO_EPS_BIOSPHERE (labels 09-14 h .. #18)
#   16.2  ALPHA_PHOTO_EPS_STILL2003 (the canonical's label)
#   17.8  Lloyd & Farquhar (1994) C3 GPP-weighted (ALPHA_PHOTO_EPS's source string)
#   18    ALPHA_PHOTO_EPS ledger default (the C3-only value; ent26-era models ran it)
#   19.6  Lloyd & Farquhar (1994) cool deciduous forest, the top of their C3 range (same string)
#
# Usage: Rscript calibration/diag_seas8_photo_eps_probe_20261021.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8P_DRIVER <- "calibration/diag_seas8_photo_eps_probe_20261021.R"
S8P_COMMIT <- ccx_git_stamp()
S8P_EPS_LF_C3   <- 17.8   # Lloyd & Farquhar 1994, C3 GPP-weighted (cited in ALPHA_PHOTO_EPS's source)
S8P_EPS_LF_COOL <- 19.6   # Lloyd & Farquhar 1994, cool deciduous forest (same source string)
S8P_EPS <- c(biosphere_15.6 = CCX_ALPHA_PHOTO_EPS_BIOSPHERE,
             still2003_canonical = ccx_const("ALPHA_PHOTO_EPS_STILL2003"),
             lf1994_C3 = S8P_EPS_LF_C3, ledger_C3 = ccx_const("ALPHA_PHOTO_EPS"),
             lf1994_cool_deciduous = S8P_EPS_LF_COOL)
S8P_NBOOT <- 2000L
S8P_SEED  <- 20261022L     # applied immediately before the observed phase-offset bootstrap
S8P_D13_OTHER <- c("d13c_level_MLO", "d13c_level_SPO", "d13c_icecore", "d13c_gradient",
                   "ocean_grad_d13c", "hs_surf_d13c")
S8P_STEM <- file.path(S8_OUT_DIR, sprintf("t8b_photo_eps_probe_%s", S8_MODE))
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s ===\n", S8P_DRIVER, S8P_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))
S <- s8_setup(S8P_DRIVER)
L <- ccx_load_mode(S8_MODE)
obs <- ccx_prepare_obs()
YR <- lapply(stats::setNames(nm = S8_STATIONS), function(st)
  intersect(obs$co2_seas[[st]]$year, obs$d13_seas[[st]]$year))
if (!isTRUE(all.equal(L$p$alpha_photo_eps, S8P_EPS[["still2003_canonical"]])))
  stop("the canonical does not run alpha_photo_eps = ", S8P_EPS[["still2003_canonical"]])
obsv <- list()
for (st in S8_STATIONS) {
  k <- match(YR[[st]], obs$co2_seas[[st]]$year); j <- match(YR[[st]], obs$d13_seas[[st]]$year)
  obsv[[paste0("co2_", st)]] <- c(mean(obs$co2_seas[[st]]$a[k]), mean(obs$co2_seas[[st]]$b[k]))
  obsv[[paste0("d13_", st)]] <- c(mean(obs$d13_seas[[st]]$a[j]), mean(obs$d13_seas[[st]]$b[j]))
}
osig <- vapply(S8_STATIONS, function(st) s8_amp(obsv[[paste0("d13_", st)]]) / s8_amp(obsv[[paste0("co2_", st)]]), 0)

say("\n=== 1. THE OBSERVED PHASE OFFSET: d13C peak minus (CO2 peak + 6 months), bootstrap over years ===\n")
say("  (positive = the d13C cycle LAGS the antiphase of CO2). %d draws, seed %d applied immediately before.\n",
    S8P_NBOOT, S8P_SEED)
set.seed(S8P_SEED)
off_obs <- list()
for (st in S8_STATIONS) {
  hc <- obs$co2_seas[[st]]; hd <- obs$d13_seas[[st]]
  kc <- match(YR[[st]], hc$year); kd <- match(YR[[st]], hd$year); n <- length(YR[[st]])
  bs <- replicate(S8P_NBOOT, { j <- sample.int(n, n, replace = TRUE)
    s8_dmo(s8_ang_mo(c(mean(hd$a[kd][j]), mean(hd$b[kd][j]))), s8_ang_mo(-c(mean(hc$a[kc][j]), mean(hc$b[kc][j])))) })
  pt <- s8_dmo(s8_ang_mo(obsv[[paste0("d13_", st)]]), s8_ang_mo(-obsv[[paste0("co2_", st)]]))
  ci <- stats::quantile(bs, c(0.025, 0.975), names = FALSE)
  say("  %s: observed offset %+.3f mo [%+.3f, %+.3f]; excludes 0: %s\n", st, pt, ci[1], ci[2],
      if (ci[1] > 0 || ci[2] < 0) "YES" else "NO")
  off_obs[[st]] <- list(point = pt, ci = ci)
}

say("\n=== 2. alpha_photo_eps PROBE (unrefitted; every fitted value at the mode) ===\n")
say("  %-24s %6s | %-34s | %-34s | %9s %9s %9s %9s | %10s\n", "case", "eps", "MLO sig (ratio) d13 amp/obs, off",
    "SPO sig (ratio) d13 amp/obs, off", "co2 MLO", "co2 SPO", "d13 MLO", "d13 SPO", "other d13C")
res <- list()
for (nm in names(S8P_EPS)) {
  r <- s8_run(L, S$spf, obs, list(alpha_photo_eps = S8P_EPS[[nm]]), YR)
  if (r$retried || (is.finite(r$resid_carbon) && r$resid_carbon >= PS_TOL)) say("  ! %s: spinup/run flag\n", nm)
  cell <- function(st) {
    c_ <- r$v[[paste0("co2_", st)]]; d_ <- r$v[[paste0("d13_", st)]]
    sig <- s8_amp(d_) / s8_amp(c_)
    sprintf("%.5f (%.2fx) %.3f, %+.2f", sig, sig / osig[[st]], s8_amp(d_) / s8_amp(obsv[[paste0("d13_", st)]]),
            s8_dmo(s8_ang_mo(d_), s8_ang_mo(-c_)))
  }
  oth <- sum(unlist(r$ll)[S8P_D13_OTHER])
  say("  %-24s %6.2f | %-34s | %-34s | %9.3f %9.3f %9.3f %9.3f | %10.3f\n", nm, S8P_EPS[[nm]], cell("MLO"),
      cell("SPO"), r$ll[["co2_seasonal_MLO"]], r$ll[["co2_seasonal_SPO"]], r$ll[["d13c_seasonal_MLO"]],
      r$ll[["d13c_seasonal_SPO"]], oth)
  res[[nm]] <- list(eps = S8P_EPS[[nm]], v = r$v, ll = r$ll, other_d13 = oth)
}
b <- res[["still2003_canonical"]]
say("\n  CHANGE vs the canonical (log-units): seasonal d13C rows | the other d13C rows | total likelihood\n")
for (nm in names(res)) {
  say("  %-24s d13c_seasonal %+8.3f | other d13C %+9.3f | all rows %+9.3f\n", nm,
      res[[nm]]$ll[["d13c_seasonal_MLO"]] + res[[nm]]$ll[["d13c_seasonal_SPO"]] -
        b$ll[["d13c_seasonal_MLO"]] - b$ll[["d13c_seasonal_SPO"]],
      res[[nm]]$other_d13 - b$other_d13, sum(unlist(res[[nm]]$ll)) - sum(unlist(b$ll)))
}
# the eps at which the MLO station signature equals the observed, by linear interpolation in eps
sigM <- vapply(res, function(x) s8_amp(x$v$d13_MLO) / s8_amp(x$v$co2_MLO), 0)
epsv <- vapply(res, `[[`, 0, "eps")
o <- order(epsv)
eps_star <- stats::approx(sigM[o], epsv[o], xout = osig[["MLO"]], rule = 1)$y
say("\n  MLO station signature is linear in eps (%s); it equals the observed %.5f at eps = %s permil\n",
    paste(sprintf("%.2f->%.5f", epsv[o], sigM[o]), collapse = ", "), osig[["MLO"]],
    if (is.finite(eps_star)) sprintf("%.2f", eps_star) else "beyond the probed range")

saveRDS(list(probe = res, obs_sig = osig, obs_offset = off_obs, eps_star_MLO = eps_star, years = YR,
             provenance = list(driver = S8P_DRIVER, lib = "calibration/lib_seas8_20261021.R", commit = S8P_COMMIT,
                               mode = S8_MODE, mode_file = S$mode_file, mode_md5 = S$mode_md5,
                               eps = S8P_EPS, unrefitted = TRUE, seed = S8P_SEED, rng_kind = RNGkind(),
                               seed_applied = "set.seed() immediately before the observed phase-offset bootstrap (sec.1)",
                               nboot = S8P_NBOOT, units = "permil; permil per ppm; months; log-units",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8P_STEM, ".rds"))
say("\nwrote %s.rds\n=== DONE ===\n", S8P_STEM)
