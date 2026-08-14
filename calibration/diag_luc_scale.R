# =====================================================================
# probe_luc_scale.R -- can the ~32 ppm "CO2 level vs GCB budget" residual be
# bought from the LUC INPUT instead of from beta?
#
# THE SETUP. At beta 0.40 the model's 2015-2024 gross land (2.49) and ocean
# (2.96) sinks both sit inside GCB's stated uncertainty, the Joos IRF gate
# passes, and the Pulse Lab's Revelle lesson holds -- but atmospheric CO2 is
# ~32.5 ppm TOO HIGH. The default beta 0.75 buys that 32 ppm by nearly
# doubling the land sink (4.57 vs GCB 2.36) and starving the ocean.
#
# THE ALTERNATIVE HYPOTHESIS. The model closes its carbon budget exactly;
# GCB's does not (+35.6 GtC over 1959-2024 alone, handoff 13i sec.2). The
# largest single uncertainty in the input side is E_LUC: DATA.md sec.3a
# records GCB 2025 at 239.8 GtC over 1850-2018 against OSCAR v3.1's 178.9
# for the SAME period -- a 34 % product spread -- and OSCAR's own paper
# headline is 206 +/- 57 PgC (1750-2018). 57-76 GtC is 27-36 ppm. The
# discrepancy is INSIDE the input's own error bar.
#
# THE TEST. Hold beta at a Joos-passing value, scale the whole LUC forcing
# (and cum_luc with it, since the converted-land term reads it), and see
# whether a scale factor inside the published spread zeroes the CO2 bias
# while leaving the sinks inside GCB. If yes, beta is currently paying for
# an input error and the "structural misfit" has a cheaper explanation.
# =====================================================================


for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

LS_YEARS   <- c(1750, 2024)
LS_WIN     <- c(2015, 2024)
LS_BETAS   <- c(0.40, 0.50, 0.75)
LS_SCALES  <- c(1.00, 0.85, 0.75, 0.65, 0.55)
LS_GCB_LAND  <- 2.36
LS_GCB_OCEAN <- 3.22

obs <- ccx_prepare_obs()
F0  <- ccx_build_forcing("historical", LS_YEARS, prod_c14 = 0, bomb_total_kmol = 102)

LS_ELUC <- local({
  em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  mean(em$luc_GtC[em$year >= LS_WIN[1] & em$year <= LS_WIN[2]])
})
LS_CUM <- max(F0$cum_luc_NH + F0$cum_luc_SH)

cat(sprintf("\nLUC in the shipped forcing: cumulative %.1f GtC to %d; 2015-2024 mean %.3f GtC/yr\n",
            LS_CUM, LS_YEARS[2], LS_ELUC))
cat(sprintf("GCB 2015-2024: land %.2f  ocean %.2f GtC/yr\n\n", LS_GCB_LAND, LS_GCB_OCEAN))

ls_bias <- function(o, m) {
  k <- match(o$year, m$year)
  g <- !is.na(k) & o$year >= LS_WIN[1] & o$year <= LS_WIN[2]
  mean(o$level[g] - m$level[k[g]])
}

cat(sprintf("%6s %7s %10s %10s %11s %11s %11s\n",
            "beta", "LUCx", "cumLUC", "CO2 bias", "gross land", "ocean", "d13C bias"))
for (b in LS_BETAS) {
  for (s in LS_SCALES) {
    p <- ccx_default_params(); p$beta <- b
    F <- F0
    for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * s
    sp <- ccx_spinup(p); F$c14_cosmo <- sp$prod_c14
    out <- ccx_run_fast(sp, F)$out
    ms  <- ccx_model_stats(out, obs)
    cb  <- ls_bias(obs$co2_ann$MLO, ms$co2$MLO)
    db  <- ls_bias(obs$d13_ann$MLO, ms$d13$MLO)
    yr  <- floor(out$t + 1e-9)
    ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
    ann <- ann[order(ann$yr), ]
    k   <- ann$yr[-1] >= LS_WIN[1]
    net <- mean(diff(ann$land_C)[k]); oc <- mean(diff(ann$ocean_C)[k])
    cat(sprintf("%6.2f %7.2f %10.1f %+10.2f %11.2f %11.2f %+11.3f\n",
                b, s, LS_CUM * s, cb, net + LS_ELUC * s, oc, db))
  }
  cat("\n")
}
