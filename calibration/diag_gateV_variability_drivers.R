# =====================================================================
# GATE V: WHERE THE MODEL'S INTERANNUAL CO2 GROWTH VARIABILITY COMES FROM,
# AND WHETHER A SOLAR CYCLE WOULD HELP.
#
# GATE V (lib_design_gates.R, ruled 2026-09-04) says the model's interannual
# growth anomaly must match the observed 0.911 GtC/yr within the observation's
# own sampling error. It does not: the canonical mode reads ~0.70, about -2.7
# sigma. A gate that says "too smooth" and nothing else is not actionable, so
# this file decomposes the model's variance by KNOCKING OUT each driver Marcus
# named -- observed TEMPERATURE variability, VOLCANIC aerosol, and the direct
# ENSO links to land and ocean uptake -- and then answers the solar question.
#
# ⚠ KNOCKOUTS DO NOT ADD UP, and that is reported rather than hidden: the
# channels interact through the same sinks, so single-knockout deltas and the
# all-off residual are both printed and their gap is the interaction.
#
# ⚠ THE TEMPERATURE KNOCKOUT SMOOTHS, IT DOES NOT HOLD. `ccx_hold_climate()`
# freezes GMST at one value, which removes the TREND as well and would compare
# two different climates. What gate V is about is the VARIABILITY, so the
# temperature channels are replaced by their own G4V_SMOOTH_YR centred means --
# same trend, no interannual wiggle. Both TEMPERATURE columns are treated: `gmst`
# (the land/feedback path) and `sst_anom_NH/SH` (the ocean solubility path).
# ⚠ AOD IS NOT A TEMPERATURE CHANNEL HERE. The model has exactly one AOD pathway,
# diffuse light -> NPP; the volcanic COOLING is already inside the observed
# `gmst` record (R/forcing.R:979-988), so it is knocked out with TEMPERATURE, and
# `gamma_diff` is the separate, non-redundant volcanic channel.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
G4V_ARM        <- CCX_MODE_CANONICAL
G4V_SMOOTH_YR  <- 11        # yr, the centred mean that defines "not interannual"
G4V_T_COLS     <- c("gmst", "sst_anom_NH", "sst_anom_SH")
G4V_ENSO_PARS  <- c("gamma_enso_land_NH", "gamma_enso_land_SH",
                    "gamma_enso_ocn_NH",  "gamma_enso_ocn_SH")
G4V_SOLAR_PER  <- c(9, 13)  # yr, the band an 11-yr solar cycle would live in
G4V_SOLAR_GRID <- seq(G4V_SOLAR_PER[1], G4V_SOLAR_PER[2], by = 0.1)
G4V_MC_N       <- 2000      # draws for the multiple-comparison null on that band
G4V_MC_SEED    <- 20260904
G4V_OUT        <- ccx_path("calibration", "output", "gateV_variability_drivers")
dir.create(G4V_OUT, showWarnings = FALSE, recursive = TRUE)

sep <- function(s) cat(sprintf("\n%s\n%s\n%s\n", strrep("=", 74), s, strrep("=", 74)))

# 11-yr centred moving average on a MONTHLY column, ends held (rule = 2 in spirit)
g4v_smooth <- function(x, n_mo) {
  k <- rep(1 / n_mo, n_mo)
  y <- stats::filter(x, k, sides = 2)
  i <- which(!is.na(y)); y[seq_len(min(i) - 1)] <- y[min(i)]
  y[seq(max(i) + 1, length(y), length.out = max(0, length(y) - max(i)))] <- y[max(i)]
  as.numeric(y)
}

v <- dg_vector(G4V_ARM)
OV <- dg_gateV_obs()
cat(sprintf("ARM: %s\nOBS: sd %.3f GtC/yr, se %.3f, n %d, lag-1 rho %+.3f\n",
            v$src, OV$sd, OV$se, OV$n, OV$rho))

# ---- the knockout runner: one spinup per PARAMETER change only ------
g4v_run <- function(kill_T = FALSE, kill_V = FALSE, kill_E = FALSE) {
  p <- v$p
  if (kill_V) p$gamma_diff <- 0
  if (kill_E) for (nm in G4V_ENSO_PARS) p[[nm]] <- 0
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  if (kill_T) {
    n_mo <- G4V_SMOOTH_YR * 12
    for (cc in G4V_T_COLS) if (!is.null(F[[cc]])) F[[cc]] <- g4v_smooth(F[[cc]], n_mo)
  }
  dg_gateV(list(out = ccx_run_fast(sp, F)$out, F = F))
}

sep("A. THE KNOCKOUT DECOMPOSITION")
CASES <- list(
  "all drivers on" = c(FALSE, FALSE, FALSE),
  "no TEMPERATURE" = c(TRUE,  FALSE, FALSE),
  "no VOLCANIC"    = c(FALSE, TRUE,  FALSE),
  "no ENSO"        = c(FALSE, FALSE, TRUE),
  "none of them"   = c(TRUE,  TRUE,  TRUE))
t0 <- Sys.time()
K <- lapply(CASES, function(z) g4v_run(z[1], z[2], z[3]))
cat(sprintf("  %d runs in %.1f s\n\n", length(K), as.numeric(Sys.time() - t0, units = "secs")))
ref <- K[["all drivers on"]]$sd; base <- K[["none of them"]]$sd
cat(sprintf("  %-16s %10s %9s %14s\n", "case", "sd GtC/yr", "z vs obs", "variance lost"))
for (nm in names(CASES)) {
  s <- K[[nm]]$sd
  cat(sprintf("  %-16s %10.3f %9.2f %13s\n", nm, s,
              dg_gateV_verdict(K[[nm]], OV)$z,
              if (nm == "all drivers on") "--"
              else sprintf("%+.1f %%", 100 * (s^2 - ref^2) / ref^2)))
}
cat(sprintf("\n  ⇒ driver-free residual %.3f = %.0f %% of the run's variance;\n",
            base, 100 * base^2 / ref^2))
cat(sprintf("    the three named drivers together supply %.0f %% of it.\n",
            100 * (ref^2 - base^2) / ref^2))
ind <- vapply(names(CASES)[2:4], function(nm) ref^2 - K[[nm]]$sd^2, 0)
cat(sprintf("    single-knockout variances sum to %.3f against the %.3f the\n",
            sum(ind), ref^2 - base^2))
cat("    all-off run says: the difference IS the interaction, not an error.\n")
cat(sprintf("\n  THE GAP TO CLOSE: obs var %.3f - model var %.3f = %.3f (GtC/yr)^2,\n",
            OV$sd^2, ref^2, OV$sd^2 - ref^2))
cat(sprintf("    i.e. the named drivers would have to supply %.2fx their present\n",
            (OV$sd^2 - base^2) / (ref^2 - base^2)))
cat("    combined variance for gate V to close at this residual.\n")

sep("B. IS THE ESTIMATOR STABLE? (the smoothing is a CHOICE)")
cat(sprintf("  %-16s %s\n", "series", paste(sprintf("  df=%d", 2:5), collapse = "")))
cat(sprintf("  %-16s %s\n", "GCB 2025",
            paste(sprintf("%7.3f", vapply(2:5, function(d) dg_gateV_obs(df = d)$sd, 0)), collapse = "")))

sep("C. WOULD AN OBSERVED SOLAR CYCLE HELP? -- ASKED OF THE OBSERVATIONS FIRST")
# ⛔ THE PHYSICAL HALF FIRST, BECAUSE IT BOUNDS WHAT THE STATISTICS CAN MEAN.
cat("  1. THE SOLAR CYCLE'S TEMPERATURE SIGNATURE IS ALREADY IN THE MODEL.\n")
cat("     CCX is driven with the OBSERVED GMST record, which contains whatever\n")
cat("     the solar cycle did to temperature -- exactly the argument R/forcing.R\n")
cat("     :979-988 already makes for volcanic cooling. A solar -> temperature\n")
cat("     term would DOUBLE-COUNT. The only non-redundant addition would be a\n")
cat("     DIRECT irradiance -> photosynthesis path, the solar analogue of\n")
cat("     `gamma_diff` -- and that is a new mechanism, not a new forcing column.\n\n")
# ⭐ THEN THE OBSERVATIONAL HALF: is there 11-yr power in the observed anomaly?
e  <- dg_v_anom(DG_AF_OBS_ANNUAL)
yr <- DG_AF_OBS_ANNUAL$year[DG_AF_OBS_ANNUAL$year >= DG_V_WIN[1] &
                            DG_AF_OBS_ANNUAL$year <= DG_V_WIN[2]]
amp_at <- function(res, years, per) {
  w <- 2 * pi / per
  f <- stats::lm(res ~ 0 + sin(w * years) + cos(w * years))
  sqrt(sum(stats::coef(f)^2))
}
amps <- vapply(G4V_SOLAR_GRID, function(p) amp_at(e, yr, p), 0)
best <- G4V_SOLAR_GRID[which.max(amps)]; a_best <- max(amps)
cat(sprintf("  2. BEST-FITTING PERIOD in %g-%g yr: %.1f yr, amplitude %.3f GtC/yr\n",
            G4V_SOLAR_PER[1], G4V_SOLAR_PER[2], best, a_best))
cat(sprintf("     = %.1f %% of the anomaly's sd (%.3f), i.e. %.1f %% of its VARIANCE.\n",
            100 * a_best / OV$sd, OV$sd, 100 * (a_best^2 / 2) / OV$sd^2))
# ⚠ AND THAT AMPLITUDE IS THE MAXIMUM OVER A BAND, so it must be judged against
# the maximum WHITE NOISE would produce over the SAME band -- otherwise the
# multiple comparison is smuggled in. [[no_power_null]]
set.seed(G4V_MC_SEED)
null_max <- replicate(G4V_MC_N, {
  r <- stats::rnorm(length(yr), 0, stats::sd(e))
  max(vapply(G4V_SOLAR_GRID, function(p) amp_at(r, yr, p), 0)) })
cat(sprintf("     WHITE-NOISE NULL over the same band: median %.3f, 95%% %.3f\n",
            stats::median(null_max), stats::quantile(null_max, 0.95)))
cat(sprintf("     ⇒ observed %.3f sits at the %.0fth percentile of the null.\n",
            a_best, 100 * mean(null_max < a_best)))
cat(sprintf("  3. FOR SCALE: closing gate V needs %.3f (GtC/yr)^2 of extra variance;\n",
            OV$sd^2 - ref^2))
cat(sprintf("     a harmonic of the observed amplitude carries %.3f, i.e. %.0f %% of it.\n",
            a_best^2 / 2, 100 * (a_best^2 / 2) / (OV$sd^2 - ref^2)))
# ⭐ MEASURE THE TEST'S POWER BEFORE BELIEVING ITS NULL. 66 years is ~6 solar
# cycles, so "not significant" has to come with what WOULD have been detected.
det <- stats::quantile(null_max, 0.95)
cat(sprintf("  4. POWER: the 95%% null cut is %.3f GtC/yr, so this test DETECTS any\n", det))
cat(sprintf("     harmonic in the band above that amplitude -- %.0f %% of the observed\n",
            100 * (det^2 / 2) / OV$sd^2))
cat(sprintf("     variance -- and CANNOT rule out smaller ones. On %d years (~%.1f\n",
            length(yr), length(yr) / 11))
cat("     cycles) that is the honest statement: a solar cycle big enough to matter\n")
cat("     for gate V would have shown; one too small to matter might not have.\n")

saveRDS(list(arm = v$src, obs = OV, knockouts = K, cases = CASES,
             solar = list(grid = G4V_SOLAR_GRID, amps = amps, best = best,
                          a_best = a_best, null_max = null_max),
             when = Sys.time()),
        file.path(G4V_OUT, "gateV_variability_drivers.rds"))
cat(sprintf("\nwrote %s\n", file.path(G4V_OUT, "gateV_variability_drivers.rds")))
