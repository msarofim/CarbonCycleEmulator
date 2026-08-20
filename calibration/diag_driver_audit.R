# =====================================================================
# diag_driver_audit.R -- ARE WE USING ALL THE INFORMATION THE INPUT
# DRIVERS CARRY? (Marcus 2026-08-20, the first step on the seasonal
# amplitude deficit of handoff 2026-08-20c section 2.)
#
# THE QUESTION. The seasonal amplitude misfit has a hemispheric signature --
# NH undershoots, SH overshoots, in both species. Before decomposing the
# model's CHANNELS (that is the next test), ask the cheaper question about
# its INPUTS: for each driver of the seasonal cycle, is the model reading an
# observation, or is it fitting a free parameter to a quantity somebody has
# already measured? The worked example Marcus named is land versus ocean in
# the southern hemisphere: the SH is ocean-dominated, the SH seasonal cycle
# is carried by a LAND-ONLY term, and the ocean term next to it is fitted
# to zero.
#
# THIS SCRIPT MEASURES, IT DOES NOT FIT. Six blocks:
#   1. PRIOR-z AT THE MODE for every parameter, so "the fit blew through the
#      prior" is a number and not an impression.
#   2. THE HEMISPHERIC SURFACE-AREA BUDGET implied by the model's own ocean
#      areas, against the NPP split it fits. Land/ocean in the SH, in m2.
#   3. THE LAND SEASONAL CHANNEL as delivered: npp_h * (n(t) - 1) in GtC/yr,
#      per hemisphere, at the mode.
#   4. THE RESPIRATION SEASONAL CHANNEL as delivered, same units.
#   5. THE OCEAN SEASONAL CHANNEL priced in pCO2, which is the only way to
#      compare 0.089 K against 12 GtC/yr of land flux.
#   6. WHICH FORCING COLUMNS ACTUALLY CARRY WITHIN-YEAR STRUCTURE, measured
#      on the built table rather than read off the build scripts.
#
# BLOCK 11 WAS ADDED AFTER THE FIRST RUN (2026-08-20e). Blocks 0 and 5 found
# that nothing on disk could check the four seasonal temperature knobs; the
# products that can were then downloaded (CRU absolute + CRUTEM5 mask for land,
# ERSSTv5 for ocean; data-raw/build_seasonal_climatology.R). Block 11 is the
# comparison those downloads make possible, and it is now the payoff of the
# whole file. Blocks 0 and 5 are LEFT AS THEY WERE -- they are the record of
# what was true before the download, not a caveat to rewrite.
#
# WHAT IT CANNOT DO, and this is block 0's finding rather than a caveat: the
# repo holds NO absolute monthly climatology for either seasonal temperature
# driver. HadSST4 and CRUTEM5 are downloaded as ANNUAL hemispheric ANOMALY
# series, and the monthly summary series of both products are anomalies
# too -- the seasonal cycle is removed by construction in the anomaly
# definition. So `seas_T_amp_*` and `sst_seas_amp_*` cannot be checked
# against anything currently on disk. That is the gap, not a limitation of
# this script.
#
# Usage:  Rscript calibration/diag_driver_audit.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

AUDIT_MODE_FILE <- ccx_path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
AUDIT_ARM       <- "N"
AUDIT_YEARS     <- c(1750, 2024)
AUDIT_PROBE_YR  <- 2015          # the year block 6 measures within-year structure in
AUDIT_SEAS_PARS <- c("seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p",
                     "sst_seas_amp_NH", "sst_seas_amp_SH", "npp_frac_NH")
# Earth's total surface area, for the land residual in block 2. The model
# carries OCEAN_AREA_{NH,SH} but NO land area: land enters only through NPP.
AUDIT_EARTH_AREA <- 5.100656e14  # m2, WGS84 ellipsoid; NASA Earth Fact Sheet
# dpCO2/dT of seawater at fixed DIC/ALK -- the REPO'S OWN constant, not a
# number typed in here (SST_PCO2_SENSITIVITY, Takahashi). Used ONLY to price
# block 5 in comparable units; the model itself gets the full temperature
# dependence from carb_constants(), so this is a ruler, not a second physics
# path -- exactly the double-counting the constant's own note warns about.
AUDIT_DPCO2_DT   <- ccx_const("SST_PCO2_SENSITIVITY")
AUDIT_PCO2_REF   <- 400          # uatm, for turning the fraction into uatm
# Block 8 profiles npp_frac_NH. The mode's value plus two candidate observed
# NH shares of global terrestrial NPP -- SPANNING VALUES, deliberately NOT
# presented as a source: the whole point of block 8 is that this repo has no
# sourced number for the split. See the note printed under the table.
AUDIT_NPP_CASES  <- c(0.55, 0.60, 0.65)
AUDIT_PROFILE_YRS <- c(1750, 2024)
# Block 9's streams: the four scored seasonal rows, as (obs list, model list)
# key pairs into ccx_prepare_obs() / ccx_model_stats().
AUDIT_SEAS_STREAMS <- list(MLO = c(co2 = "co2_seas.MLO", d13 = "d13_seas.MLO"),
                           SPO = c(co2 = "co2_seas.SPO", d13 = "d13_seas.SPO"))
# Block 10: every HEMISPHERIC SPLIT the model applies, and where its number
# comes from. This is the completeness half of the audit -- block 2 asks
# whether ONE split is right, this asks whether any of them are sourced.
# name -> c(value, provenance). Values are read live where a live symbol
# exists, so this table cannot drift from the code the way a comment can.
AUDIT_SPLIT_SRC <- list(
  FORC_FOSS_NH_SHARE  = "MEASURED -- EDGAR v4.3.2 country aggregation (2026-08-15)",
  FORC_LUC_NH_SHARE   = "FALLBACK ONLY -- superseded by the OSCAR time series",
  FORC_NUC_NH_SHARE   = "PROVISIONAL -- 'the reporting countries are NH'",
  FORC_BOMB_NH_SHARE  = "PROVISIONAL -- 'tests were overwhelmingly NH'")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
p2p <- function(v) max(v) - min(v)              # peak-to-peak, ALWAYS. Never semi.

mf <- readRDS(AUDIT_MODE_FILE)
p  <- ccx_default_params()
for (nm in names(mf$par_mode)) p[[nm]] <- mf$par_mode[[nm]]
p$pump_mode <- mf$pump_mode

# ---------------------------------------------------------------------
sep("0. WHAT IS ON DISK FOR EACH SEASONAL DRIVER")
dl <- ccx_path("data-raw", "downloads")
man <- utils::read.csv(file.path(dl, "MANIFEST.csv"), stringsAsFactors = FALSE)
for (k in c("hadsst4_nhem", "hadsst4_shem", "crutem5_nh_land", "crutem5_sh_land")) {
  r <- man[man$key == k, ]
  if (!nrow(r)) { cat(sprintf("%-16s ABSENT from MANIFEST\n", k)); next }
  f <- file.path(ccx_path(), r$file[1])
  hdr <- if (file.exists(f)) readLines(f, n = 2) else "(file missing)"
  cat(sprintf("%-16s %s\n%16s header: %s\n%16s row 1 : %s\n",
              k, basename(r$file[1]), "", hdr[1], "", hdr[min(2, length(hdr))]))
}
cat("\nBoth products are ANOMALY series. An anomaly has its monthly climatology\n",
    "subtracted, so NEITHER the annual files on disk NOR the monthly summary\n",
    "series of the same products carry a seasonal cycle. Nothing here can\n",
    "check seas_T_amp_* or sst_seas_amp_*.\n", sep = "")

# ---------------------------------------------------------------------
sep(sprintf("1. PRIOR-z AT THE ARM-%s MODE (sorted by |z|)", AUDIT_ARM))
z <- mf$prior_z
o <- order(-abs(z))
for (i in o) cat(sprintf("  %-16s %8.3f  %8.4g%s\n", names(z)[i], z[i],
                         mf$par_mode[[names(z)[i]]],
                         if (names(z)[i] %in% AUDIT_SEAS_PARS) "   <- seasonal" else ""))

# ---------------------------------------------------------------------
sep("2. HEMISPHERIC SURFACE-AREA BUDGET vs THE FITTED NPP SPLIT")
a_oc <- c(NH = ccx_const("OCEAN_AREA_NH"), SH = ccx_const("OCEAN_AREA_SH"))
a_hem <- AUDIT_EARTH_AREA / 2
a_ld  <- a_hem - a_oc
cat(sprintf("  %-4s ocean %.3fe14 m2   land %.3fe14 m2   land frac %.3f\n",
            names(a_oc), a_oc / 1e14, a_ld / 1e14, a_ld / a_hem))
cat(sprintf("\n  NH share of global LAND AREA        : %.3f\n", a_ld[["NH"]] / sum(a_ld)))
cat(sprintf("  NH share of global NPP, npp_frac_NH : %.3f  (prior: UNIFORM[0.4, 0.8])\n",
            p$npp_frac_NH))
cat(sprintf("  distance above the uniform floor    : %.3f of a 0.400-wide box\n",
            (p$npp_frac_NH - 0.4) / 0.4))
cat(sprintf("\n  Implied SH NPP: %.2f GtC/yr on %.3fe14 m2 of land\n",
            ccx_const("NPP_GLOBAL_PI") * (1 - p$npp_frac_NH), a_ld[["SH"]] / 1e14))
cat(sprintf("  Implied NH NPP: %.2f GtC/yr on %.3fe14 m2 of land\n",
            ccx_const("NPP_GLOBAL_PI") * p$npp_frac_NH, a_ld[["NH"]] / 1e14))
cat(sprintf("  => SH land is %.2fx as productive per m2 as NH land at this mode.\n",
            ((1 - p$npp_frac_NH) / a_ld[["SH"]]) / (p$npp_frac_NH / a_ld[["NH"]])))

# ---------------------------------------------------------------------
sep("3. LAND NEP SEASONAL CHANNEL AS DELIVERED (GtC/yr, peak-to-peak)")
tt <- (seq_len(720) - 0.5) / 720
nrm <- ccx_seas_norms(p)
npp_h <- c(NH = ccx_const("NPP_GLOBAL_PI") * p$npp_frac_NH,
           SH = ccx_const("NPP_GLOBAL_PI") * (1 - p$npp_frac_NH))
cat(sprintf("  phi_eff  NH %+.1f deg   SH %+.1f deg   (CCX_SEAS_PHI_EFF)\n",
            CCX_SEAS_PHI_EFF[["NH"]], CCX_SEAS_PHI_EFF[["SH"]]))
for (h in c("NH", "SH")) {
  shp <- ccx_insol(CCX_SEAS_PHI_EFF[[h]], tt - p$seas_lag_p / 12) / nrm[[h]]$n - 1
  cat(sprintf("  %-3s npp %5.2f GtC/yr  shape p2p %.3f (unit-mean)  =>  NEP p2p %6.2f GtC/yr\n",
              h, npp_h[[h]], p2p(shp), npp_h[[h]] * p2p(shp)))
}

# ---------------------------------------------------------------------
sep("4. SOIL RESPIRATION SEASONAL CHANNEL AS DELIVERED")
cat(sprintf("  q10 = %.4f\n", p$q10))
for (h in c("NH", "SH")) {
  a_t <- if (h == "NH") p$seas_T_amp_NH else p$seas_T_amp_SH
  sgn <- if (h == "NH") 1 else -1
  fac <- p$q10^(sgn * a_t * sin(2 * pi * (tt - (3.5 + CCX_SEAS_T_LAG) / 12)) / 10) / nrm[[h]]$r
  cat(sprintf("  %-3s seas_T_amp %6.2f K  =>  q10 factor ranges %.3f - %.3f (p2p %.3f, mean %.3f)\n",
              h, a_t, min(fac), max(fac), p2p(fac), mean(fac)))
}
cat("\n  A half-amplitude of 48 K means the NH soil is being told its seasonal\n",
    "  temperature swings +/-48 K about the annual mean. No land surface does that.\n", sep = "")

# ---------------------------------------------------------------------
sep("5. OCEAN SEASONAL CHANNEL, PRICED IN pCO2")
for (h in c("NH", "SH")) {
  a_s <- if (h == "NH") p$sst_seas_amp_NH else p$sst_seas_amp_SH
  init <- if (h == "NH") 2.0 else 1.2
  cat(sprintf("  %-3s fitted %.4f K -> %5.2f uatm p2p | prior centre %.2f K -> %5.1f uatm p2p | ratio %5.1fx\n",
              h, a_s, 2 * a_s * AUDIT_DPCO2_DT * AUDIT_PCO2_REF,
              init, 2 * init * AUDIT_DPCO2_DT * AUDIT_PCO2_REF, init / a_s))
}
cat("\n  CCX_SST_SEAS_LAG is a PRIOR BELIEF, not a fitted value (model.R ~line 222),\n",
    "  and it is unidentifiable precisely because the amplitude it phases is ~0.\n", sep = "")

# ---------------------------------------------------------------------
sep(sprintf("6. WITHIN-YEAR STRUCTURE OF THE BUILT FORCING TABLE (%d)", AUDIT_PROBE_YR))
F <- ccx_build_forcing("historical", AUDIT_YEARS)
i <- which(floor(F$t) == AUDIT_PROBE_YR)
stopifnot(length(i) == 12)
num <- names(F)[vapply(F, is.numeric, TRUE)]
cat(sprintf("  %-20s %12s %12s %10s\n", "column", "annual mean", "p2p", "p2p/|mean|"))
for (nm in setdiff(num, c("t", "year", "month"))) {
  v <- F[[nm]][i]
  if (!all(is.finite(v))) next
  mu <- mean(v); r <- p2p(v)
  cat(sprintf("  %-20s %12.5g %12.5g %10s\n", nm, mu, r,
              if (abs(mu) > 0) sprintf("%.4f", r / abs(mu)) else "-"))
}
cat("\n  A ratio of ~0 is a driver reaching the model with NO seasonal cycle.\n")

# ---------------------------------------------------------------------
sep("7. IS THE WITHIN-YEAR STRUCTURE OF THE CLIMATE COLUMNS A SEASONAL CYCLE?")
# gmst and the two sst_anom columns come from ANNUAL series through
# ccx_annual_to_monthly(method = "spline"). Block 6 shows they wiggle within a
# year. That wiggle is interpolation between annual knots, not a seasonal
# cycle -- but "not a seasonal cycle" is a claim, so project it onto the
# annual harmonic the likelihood scores and see what is actually there.
kk <- F$year >= LIK_SEAS_WINDOW[1] & F$year <= LIK_SEAS_WINDOW[2]
for (nm in c("gmst", "sst_anom_NH", "sst_anom_SH")) {
  hh <- ccx_year_harmonic(F$t[kk], F[[nm]][kk], min_months = 12L)
  amp <- 2 * mean(sqrt(hh$a^2 + hh$b^2))          # peak-to-peak, first harmonic
  raw <- mean(tapply(F[[nm]][kk], F$year[kk], p2p))
  cat(sprintf("  %-12s mean within-year p2p %.4f K | 12-mo harmonic p2p %.4f K | harmonic/raw %.3f\n",
              nm, raw, amp, amp / raw))
}
cat(sprintf("\n  For scale: the FITTED sst_seas_amp_NH is %.4f K half-amplitude,\n", p$sst_seas_amp_NH))
cat(sprintf("  i.e. %.4f K peak-to-peak -- the same order as the interpolation wiggle\n",
            2 * p$sst_seas_amp_NH))
cat("  in the annual SST column it is meant to sit on top of.\n")

# ---------------------------------------------------------------------
sep("8. WHICH STREAMS BUY npp_frac_NH = 0.466? (profile, per-stream)")
cat("The mode puts 53 % of global NPP on the 19 %-land hemisphere. Block 2 says\n")
cat("that is implausible; this block asks the objective WHY it is there. Every\n")
cat("other parameter is held at the mode, so this is a PROFILE, not a refit --\n")
cat("the streams' response is an upper bound on what npp_frac_NH is buying.\n\n")
obs <- ccx_prepare_obs()
audit_eval <- function(pp) {
  sp <- ccx_spinup(pp)
  Fp <- ccx_build_forcing("historical", AUDIT_PROFILE_YRS, prod_c14 = 0,
                          bomb_total_kmol = 102)
  Fp$c14_cosmo <- sp$prod_c14
  Fp$c14_bomb  <- Fp$c14_bomb * (pp$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    Fp[[cc]] <- Fp[[cc]] * pp$luc_scale
  attr(Fp, "luc_scale") <- pp$luc_scale
  el <- ccx_forcing_eluc_annual(Fp); el$eluc <- el$eluc * pp$luc_scale
  r <- ccx_run_fast(sp, Fp)
  ccx_loglik(r$out, obs, list(sigma_d14c = pp$sigma_d14c, rep_dC = pp$rep_dC,
                              grad_off_co2 = pp$grad_off_co2,
                              grad_off_d13c = pp$grad_off_d13c),
             luc = el, deep = sp$diagnostics$d14c_bottom_box,
             ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)
}
base <- audit_eval(p)
cases <- lapply(AUDIT_NPP_CASES, function(v) { pp <- p; pp$npp_frac_NH <- v; audit_eval(pp) })
names(cases) <- sprintf("%.2f", AUDIT_NPP_CASES)
nmz <- names(base)
cat(sprintf("  %-20s %10s %s\n", "stream", sprintf("%.3f", p$npp_frac_NH),
            paste(sprintf("%12s", paste0("d @ ", names(cases))), collapse = "")))
for (s in nmz) {
  d <- vapply(cases, function(cc) unname(cc[[s]] - base[[s]]), 0)
  if (max(abs(d)) < 1) next                       # only rows that move
  cat(sprintf("  %-20s %10.1f %s\n", s, base[[s]],
              paste(sprintf("%+12.1f", d), collapse = "")))
}
cat(sprintf("  %-20s %10.1f %s\n", "TOTAL loglik", sum(base),
            paste(sprintf("%+12.1f", vapply(cases, function(cc) sum(cc) - sum(base), 0)),
                  collapse = "")))
cat("\n  Rows moving < 1 log-unit are suppressed. A row with a large POSITIVE\n")
cat("  delta is a row that would PREFER the higher NH share, i.e. a row that is\n")
cat("  paying for the fitted value rather than buying it.\n")
cat("\n  NOTE: this repo carries NO sourced NH/SH split of terrestrial NPP. The\n")
cat("  three cases above are spanning values, not a measurement, and the prior\n")
cat("  on npp_frac_NH is UNIFORM[0.4, 0.8] -- zero observational content on a\n")
cat("  quantity that global NPP products resolve directly.\n")

# ---------------------------------------------------------------------
sep("9. THE PARTITION DIAGNOSTIC THAT NEEDS NO NEW DATA: d13C PER ppm")
# Block 8 says raising NH NPP fixes co2_seasonal_MLO (+197) and breaks
# d13c_seasonal_MLO (-463). Two rows pulling opposite ways through one
# parameter is a PARTITION statement, and there is a unit-free way to read
# it: photosynthesis moves CO2 with a -18 permil fractionation, air-sea
# exchange with -2 (invasion) / -10 (evasion). So the RATIO of the seasonal
# d13C amplitude to the seasonal CO2 amplitude says how photosynthetic the
# modelled cycle is, with no absolute amplitude and no new dataset involved.
#
# BOTH SIDES COMPUTED HERE, IN ONE EXPRESSION, from the likelihood's own
# harmonic estimator -- the amp_definition_mismatch rule. Peak-to-peak
# throughout, obs and model alike.
amp_of <- function(h) if (is.null(h)) NA_real_ else 2 * mean(sqrt(h$a^2 + h$b^2))
pickk  <- function(ms, key) { k <- strsplit(key, ".", fixed = TRUE)[[1]]
                              ms[[k[1]]][[k[2]]] }
sp0 <- ccx_spinup(p)
F0  <- ccx_build_forcing("historical", AUDIT_PROFILE_YRS, prod_c14 = 0,
                         bomb_total_kmol = 102)
F0$c14_cosmo <- sp0$prod_c14
ms0 <- ccx_model_stats(ccx_run_fast(sp0, F0)$out, obs)
cat(sprintf("  %-5s %10s %10s %10s   %10s %10s %8s\n", "stn",
            "CO2 obs", "CO2 mod", "err", "d13/CO2 obs", "d13/CO2 mod", "ratio"))
for (st in names(AUDIT_SEAS_STREAMS)) {
  ks <- AUDIT_SEAS_STREAMS[[st]]
  ac_o <- amp_of(pickk(obs, ks[["co2"]])); ac_m <- amp_of(pickk(ms0, ks[["co2"]]))
  ad_o <- amp_of(pickk(obs, ks[["d13"]])); ad_m <- amp_of(pickk(ms0, ks[["d13"]]))
  cat(sprintf("  %-5s %10.3f %10.3f %+9.1f%%   %10.4f %10.4f %7.2fx\n",
              st, ac_o, ac_m, 100 * (ac_m / ac_o - 1),
              ad_o / ac_o, ad_m / ac_m, (ad_m / ac_m) / (ad_o / ac_o)))
}
cat("\n  d13/CO2 in permil per ppm. A ratio > 1 in the last column means the\n")
cat("  modelled seasonal cycle is MORE isotopically depleted per ppm than the\n")
cat("  observed one -- too much of it is photosynthetic, not enough air-sea.\n")
cat("  This is measured against the SAME observations the fit already uses, so\n")
cat("  it costs nothing to act on and does not wait on a download.\n")

# ---------------------------------------------------------------------
sep("10. EVERY HEMISPHERIC SPLIT IN THE MODEL, AND ITS PROVENANCE")
for (nm in names(AUDIT_SPLIT_SRC))
  cat(sprintf("  %-22s %8.4f   %s\n", nm, get(nm), AUDIT_SPLIT_SRC[[nm]]))
lsh <- ccx_luc_nh_share(AUDIT_PROFILE_YRS[1]:AUDIT_PROFILE_YRS[2])
cat(sprintf("  %-22s %8s   %s\n", "luc NH share (t)",
            sprintf("%.2f-%.2f", min(lsh), max(lsh)),
            "SOURCED -- OSCAR v3.1 regional E_LUC, time-varying (2026-08-15)"))
cat(sprintf("  %-22s %8.4f   %s\n", "npp_frac_NH",  p$npp_frac_NH,
            "FITTED, prior UNIFORM[0.4, 0.8] -- NO SOURCE (block 2, block 8)"))
cat(sprintf("  %-22s %8.4f   %s\n", "enso_share NH", 0.5,
            "HARDCODED 50/50 in ccx_aux() -- NO SOURCE, no comment"))
cat(sprintf("  %-22s %8.3g   %-12s %s\n", "OCEAN_AREA_NH", ccx_const("OCEAN_AREA_NH"),
            CCX_CONSTANTS$OCEAN_AREA_NH$status, "-- NEEDS a cited geographic source"))
cat(sprintf("  %-22s %8.3g   %-12s %s\n", "OCEAN_AREA_SH", ccx_const("OCEAN_AREA_SH"),
            CCX_CONSTANTS$OCEAN_AREA_SH$status, "-- NEEDS a cited geographic source"))
cat(sprintf("  %-22s %8.1f   %s\n", "sst_NH (degC)", p$sst_NH,
            "FIXED default, no source cited -- sets K0/K1/K2 and the Revelle factor"))
cat(sprintf("  %-22s %8.1f   %s\n", "sst_SH (degC)", p$sst_SH, "as above"))
cat(sprintf("  %-22s %8.1f   %s\n", "CCX_SEAS_PHI_EFF NH", CCX_SEAS_PHI_EFF[["NH"]],
            "FITTED OFFLINE to MLO -- an effective knob, not a measured centroid"))
cat(sprintf("  %-22s %8.1f   %s\n", "CCX_SEAS_PHI_EFF SH", CCX_SEAS_PHI_EFF[["SH"]],
            "UNFITTED, 'SH land centroid' -- asserted, no source (model.R ~195)"))
cat("\n  ENSO is the one that is easy AND unsourced: GFED4.1s is already on disk\n")
cat("  (data-raw/downloads/gfed/), and the interannual land-flux anomaly it\n")
cat("  drives is overwhelmingly tropical, not 50/50.\n")

# ---------------------------------------------------------------------
sep("11. THE FITTED SEASONAL AMPLITUDES AGAINST THE OBSERVED ONES")
scf <- ccx_path("data", "obs_seasonal_clim.rds")
if (!file.exists(scf)) {
  cat("  data/obs_seasonal_clim.rds ABSENT -- run data-raw/build_seasonal_climatology.R\n")
} else {
  sc <- readRDS(scf)
  cat(sprintf("  land : %s\n  ocean: %s\n", sc$land_source, sc$ocean_source))
  cat(sprintf("  land mask %s, %d-%d, >= %d months; %.1f %% of global area\n\n",
              sc$land_mask$source, sc$land_mask$window[1], sc$land_mask$window[2],
              sc$land_mask$min_months, 100 * sc$land_mask$area_frac))
  cat("  HALF-AMPLITUDES, which is the model's parameter convention (K):\n")
  cat(sprintf("  %-18s %9s %9s %9s %9s %8s\n",
              "parameter", "fitted", "prior mid", "OBSERVED", "obs/fitted", "prior-z"))
  wk <- sprintf("%%s_%d-%d", sc$sst_window[1], sc$sst_window[2])
  cmp <- list(
    list("seas_T_amp_NH",   p$seas_T_amp_NH,   12,  sc$land[["NH_all"]]$half_amp,
         sprintf("NH land, all cells (>30N %.1f, >45N %.1f)",
                 sc$land[["NH_>30"]]$half_amp, sc$land[["NH_>45"]]$half_amp)),
    list("seas_T_amp_SH",   p$seas_T_amp_SH,    6,  sc$land[["SH_all"]]$half_amp,
         sprintf("SH land, all cells (>30S %.1f, >45S %.1f)",
                 sc$land[["SH_>30"]]$half_amp, sc$land[["SH_>45"]]$half_amp)),
    list("sst_seas_amp_NH", p$sst_seas_amp_NH, 2.0, sc$ocean[[sprintf(wk, "NH")]]$half_amp,
         "NH ocean, area-weighted"),
    list("sst_seas_amp_SH", p$sst_seas_amp_SH, 1.2, sc$ocean[[sprintf(wk, "SH")]]$half_amp,
         "SH ocean, area-weighted"))
  for (r in cmp)
    cat(sprintf("  %-18s %9.4f %9.2f %9.3f %9.1fx %+8.2f   %s\n",
                r[[1]], r[[2]], r[[3]], r[[4]], r[[4]] / r[[2]], z[[r[[1]]]], r[[5]]))
  cat("\n  The two PRIORS were close to right (12 vs 11.4; 2.0 vs 2.24; 1.2 vs 1.75).\n")
  cat("  The fit rejected them anyway. seas_T_amp_NH is 4.2x the observed value\n")
  cat("  even against the most boreal-weighted bracket; both ocean amplitudes are\n")
  cat("  ~25x too SMALL. This is not a prior that was mis-set.\n")

  cat("\n  PHASE, converted into the model's own LAG units (months past the\n")
  cat("  zero-lag mid-July peak, the (3.5 + LAG)/12 convention):\n")
  cat(sprintf("  %-18s %9s %9s   %s\n", "constant", "shipped", "OBSERVED", "driver measured"))
  cat(sprintf("  %-18s %9.2f %9.2f   %s\n", "CCX_SEAS_T_LAG", CCX_SEAS_T_LAG,
              sc$land[["NH_all"]]$model_lag, "NH land AIR temperature"))
  cat("      -> NOT a discrepancy. This constant multiplies SOIL respiration, which\n")
  cat("         lags air T; R/model.R says so and the 18,944-logL profile confirms it.\n")
  cat("         The observed air-T lag is the value that profile REJECTS. Leave it.\n")
  cat(sprintf("  %-18s %9.2f %9.2f   %s\n", "CCX_SST_SEAS_LAG", CCX_SST_SEAS_LAG,
              sc$ocean[[sprintf(wk, "NH")]]$model_lag, "NH sea-surface temperature"))
  cat("      -> A REAL discrepancy, and this one is checkable: sst_seas_amp modulates\n")
  cat("         SST ITSELF, not a lagged flux, so the observed SST phase IS its phase.\n")
  cat(sprintf("         Shipped 2.50 is %.2f months LATE. It was never fitted -- model.R\n",
              CCX_SST_SEAS_LAG - sc$ocean[[sprintf(wk, "NH")]]$model_lag))
  cat("         calls it 'a prior belief', unidentifiable because the amplitude it\n")
  cat("         phases is ~0. Now it does not have to be identified from the fit.\n")

  cat("\n  TWO STRUCTURAL ASSUMPTIONS THE CLIMATOLOGY ALSO TESTS:\n")
  dsep <- function(a, b) abs(((a - b + 0.5) %% 1 - 0.5) * 12)
  cat(sprintf("   - hemispheres exactly antiphase (model: sgn = -1, i.e. 6.00 mo):\n"))
  cat(sprintf("     observed separation %.2f mo (land), %.2f mo (SST). Small, real, not urgent.\n",
              dsep(sc$land[["NH_all"]]$peak_frac, sc$land[["SH_all"]]$peak_frac),
              dsep(sc$ocean[[sprintf(wk,"NH")]]$peak_frac, sc$ocean[[sprintf(wk,"SH")]]$peak_frac)))
  cat(sprintf("   - the drivers are pure SINES (model has no 2nd harmonic). Observed\n"))
  cat(sprintf("     amp2/amp1: NH land %.3f, SH land %.3f, NH SST %.3f, SH SST %.3f --\n",
              sc$land[["NH_all"]]$amp2_over_amp1, sc$land[["SH_all"]]$amp2_over_amp1,
              sc$ocean[[sprintf(wk,"NH")]]$amp2_over_amp1, sc$ocean[[sprintf(wk,"SH")]]$amp2_over_amp1))
  cat("     small, so the sawtooth really does have to come from Q10 and the growing\n")
  cat("     season, as designed. The drivers are not hiding it.\n")
}

sep("DONE")
