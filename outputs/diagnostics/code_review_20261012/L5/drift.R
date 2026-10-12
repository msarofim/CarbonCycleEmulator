setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
lm <- ccx_load_mode()
p <- lm$p
cat("struct:", p$struct %||% NA, "\n")
t0 <- proc.time()[["elapsed"]]
sp <- withCallingHandlers(ccx_periodic_spinup(p), warning = function(w) { cat("WARNING:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })
cat(sprintf("periodic spinup: %.2f s\n", proc.time()[["elapsed"]] - t0))
str(sp$periodic)
d <- sp$diagnostics
for (n in c("max_abs_dCdt","max_abs_dC13dt","max_abs_dC14dt","co2_ppm","d13c_atm","d14c_atm","prod_c14_mol_yr","prod_ratio","ocean_C_GtC","land_C_GtC"))
  cat(sprintf("  %-18s %.10g\n", n, d[[n]]))
cat(sprintf("  targets: CO2_PI %.6f  D13C_PI %.6f  D14C_PI %.6f\n", ccx_const("CO2_PI_PPM"), ccx_const("D13C_PI"), ccx_const("D14C_PI")))
aux <- sp$aux; grid <- sp$grid
atm <- c(aux$idx$NH$atm, aux$idx$SH$atm)
nb <- nrow(sp$y); cat("boxes:", nb, "\n")
Fq <- ps_year_forcing(0)
F  <- ps_year_forcing(sp$prod_c14, quiet = Fq)
prep <- ccx_run_prepare(list(y = sp$y, params = p, aux = aux, grid = grid))
Fp <- ccx_cpp_forcing_prep(F)
y0 <- sp$y; y <- y0
inv0 <- colSums(y0)
cat(sprintf("inventory0: C %.6f  C13 %.6f  C14 %.6f\n", inv0[["C"]], inv0[["C13"]], inv0[["C14"]]))
R13 <- ccx_const("R13_VPDB"); gpph <- aux$gtc_per_ppm_hemi
NY <- 50
rows <- list()
for (k in seq_len(NY)) {
  r <- ps_phi(y, p, aux, grid, Fp, prep)
  o <- r$out
  co2m <- mean(o$co2_NH + o$co2_SH)/2
  d13N <- 1000*(mean((1+o$d13c_NH/1000)*o$co2_NH)/mean(o$co2_NH) - 1)
  d14m <- 1000*(mean(o$atm_C14)/(mean(o$co2_NH+o$co2_SH)*gpph) - 1)
  y <- r$state
  dd <- y - y0
  inv <- colSums(y)
  rows[[k]] <- data.frame(yr=k, co2_ann=co2m, d13N_ann=d13N, d14_ann=d14m,
    maxabs_C=max(abs(dd[,"C"])), maxrel_C=max(abs(dd[,"C"])/abs(y0[,"C"]), na.rm=TRUE),
    maxabs_C13=max(abs(dd[,"C13"])), maxrel_C13=max(abs(dd[,"C13"])/abs(y0[,"C13"]), na.rm=TRUE),
    maxabs_C14=max(abs(dd[,"C14"])), maxrel_C14=max(abs(dd[,"C14"])/abs(y0[,"C14"]), na.rm=TRUE),
    dinv_C=inv[["C"]]-inv0[["C"]], dinv_C13=inv[["C13"]]-inv0[["C13"]], dinv_C14=inv[["C14"]]-inv0[["C14"]])
}
res <- do.call(rbind, rows)
options(width=250)
print(res[c(1,2,3,5,10,20,50),], digits=6)
# per-box worst at 50 yr
dd <- y - y0
for (tr in c("C","C13","C14")) { j <- which.max(abs(dd[,tr])/abs(y0[,tr])); cat(sprintf("%s worst box %d rel %.3e abs %.3e (y0 %.4g)\n", tr, j, abs(dd[j,tr])/abs(y0[j,tr]), dd[j,tr], y0[j,tr])) }
# atm drift over 50 yr in the test-spinup metric
co2_drift <- sum(y[atm,"C"])/sum(y0[atm,"C"]) - 1
d14_drift <- 1000*(sum(y[atm,"C14"])/sum(y[atm,"C"]) - 1) - 1000*(sum(y0[atm,"C14"])/sum(y0[atm,"C"]) - 1)
cat(sprintf("test-spinup metric at canonical, 50 yr: co2_drift %.3e (bound 1e-4); d14_drift %.3e permil (bound 0.05)\n", co2_drift, d14_drift))
# 14C production vs decay balance (in state units)
c14_to_state <- 1/(aux$mol_per_GtC*ccx_const("R14_STD"))
cat(sprintf("14C balance: production %.6e  decay %.6e  (state units/yr); ratio %.12f\n", sp$prod_c14*c14_to_state, ccx_const("LAMBDA_C14")*sum(sp$y[,"C14"]), sp$prod_c14*c14_to_state/(ccx_const("LAMBDA_C14")*sum(sp$y[,"C14"]))))
# NH vs global d13C at the pin
saveRDS(list(res=res, sp_periodic=sp$periodic, diag=d), file.path("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L5", "drift.rds"))
