setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
lm <- ccx_load_mode(); p <- lm$p
cat("seas_ml:", p$seas_ml, " seas_drivers:", p$seas_drivers, " seas_amp_NH:", p$seas_amp_NH, "\n")
s1 <- ccx_spinup(p)
q <- p; q$seas_ml <- 0
s0 <- ccx_spinup(q)
cat(sprintf("ccx_spinup(seas_ml=1) vs (seas_ml=0): max|dy| C %.4e  ; CO2 diag %.6f vs %.6f\n", max(abs(s1$y[,"C"]-s0$y[,"C"])), s1$diagnostics$co2_ppm, s0$diagnostics$co2_ppm))
cat(sprintf("aseasonal seed residuals at canonical: dC %.3e dC13 %.3e dC14 %.3e\n", s1$diagnostics$max_abs_dCdt, s1$diagnostics$max_abs_dC13dt, s1$diagnostics$max_abs_dC14dt))
# derivative time-dependence at the aseasonal state with the spinup's own p0
p0 <- ccx_set_enso(p, list(gamma_enso = 0)); p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
zf <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0), gmst = 0, enso = 0, land_enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = s1$prod_c14)
dA <- ccx_deriv(s1$y, 1750, p0, zf, s1$grid, s1$aux)
dB <- ccx_deriv(s1$y, 1750.5, p0, zf, s1$grid, s1$aux)
cat(sprintf("aseasonal p0 derivative at t=1750 vs t=1750.5: max|ddC| %.4e (t-dependence => a seasonal path is still live in p0)\n", max(abs(dA[,"C"]-dB[,"C"]))))
cat(sprintf("max|dC/dt| at t=1750: %.3e ; at t=1750.5: %.3e\n", max(abs(dA[,"C"])), max(abs(dB[,"C"]))))
# periodic: decompose d13C / D14C diagnostics
sp <- ccx_periodic_spinup(p, seed = s1)
aux <- sp$aux; gpph <- aux$gtc_per_ppm_hemi; R13 <- ccx_const("R13_VPDB")
o <- ps_phi(sp$y, p, aux, sp$grid, ps_year_forcing(sp$prod_c14))$out
cat("out rows:", nrow(o), " first t:", if (!is.null(o$time)) o$time[1] else NA, "\n")
c13N <- (1+o$d13c_NH/1000)*R13*o$co2_NH*gpph; c13S <- (1+o$d13c_SH/1000)*R13*o$co2_SH*gpph
cat(sprintf("d13C: NH annual-mean %.6f | SH annual-mean %.6f | global annual-mean %.6f | global INSTANT (diag) %.6f | target %.6f\n",
  1000*(mean(c13N)/(mean(o$co2_NH)*gpph*R13)-1), 1000*(mean(c13S)/(mean(o$co2_SH)*gpph*R13)-1),
  1000*(mean(c13N+c13S)/(mean(o$co2_NH+o$co2_SH)*gpph*R13)-1), sp$diagnostics$d13c_atm, ccx_const("D13C_PI")))
atm <- c(aux$idx$NH$atm, aux$idx$SH$atm)
cat(sprintf("D14C: global annual-mean %.6f | global INSTANT (diag) %.6f | target %.6f\n",
  1000*(mean(o$atm_C14)/(mean(o$co2_NH+o$co2_SH)*gpph)-1), sp$diagnostics$d14c_atm, ccx_const("D14C_PI")))
cat(sprintf("CO2: annual mean (diag) %.6f | instant %.6f\n", sp$diagnostics$co2_ppm, sum(sp$y[atm,"C"])/ccx_const("GtC_PER_PPM")))
cat("gpph*2 == GtC_PER_PPM ?", all.equal(2*gpph, ccx_const("GtC_PER_PPM")), "\n")
