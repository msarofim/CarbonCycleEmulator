setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0)); sp <- ccx_spinup(p)
cat(sprintf("defaults: hs_on %s pump %s seas_ml %s seas_drivers %s\n", ccx_hs_on(p), !is.null(sp$aux$pump), p$seas_ml, p$seas_drivers))
d <- sp$diagnostics; cat(sprintf("resid C %.3e C13 %.3e C14 %.3e ; co2 %.6f d13 %.6f d14 %.6f\n", d$max_abs_dCdt, d$max_abs_dC13dt, d$max_abs_dC14dt, d$co2_ppm, d$d13c_atm, d$d14c_atm))
zero <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0), gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = sp$prod_c14)
q <- sp$params; q <- ccx_set_enso(q, list(gamma_enso = 0)); q$seas_amp_NH <- 0; q$seas_amp_SH <- 0; q$seas_drivers <- 0
y <- sp$y; t <- 1750
for (m in seq_len(12 * 50)) { y <- ccx_step_rk4(y, t, 1 / 12, q, zero, sp$grid, sp$aux); t <- t + 1 / 12 }
atm <- c(sp$aux$idx$NH$atm, sp$aux$idx$SH$atm)
cat(sprintf("test-spinup metric at defaults, 50 yr: co2_drift %.3e (bound 1e-4)  d14 drift %.3e permil (bound 0.05)\n",
  sum(y[atm, "C"]) / sum(sp$y[atm, "C"]) - 1, 1000 * (sum(y[atm, "C14"]) / sum(y[atm, "C"]) - 1) - d$d14c_atm))
cat(sprintf("max rel box drift: C %.3e C13 %.3e C14 %.3e\n", max(abs(y[,"C"]-sp$y[,"C"])/abs(sp$y[,"C"])), max(abs(y[,"C13"]-sp$y[,"C13"])/abs(sp$y[,"C13"])), max(abs(y[,"C14"]-sp$y[,"C14"])/abs(sp$y[,"C14"]))))
