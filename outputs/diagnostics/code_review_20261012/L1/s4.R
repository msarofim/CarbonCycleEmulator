setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
cat("ENT INBAND", ccx_const("ENT_SEAS_AMP_SH_INBAND"), " DERIV", ccx_const("ENT_SEAS_AMP_SH_DERIV"), " table init", CCX_PARAM_TABLE$ent_seas_amp_SH$init, "\n")
cat(".ENT_SO_SST_AMP", .ENT_SO_SST_AMP, " .ENT_SO_PCO2_AMP", .ENT_SO_PCO2_AMP, "\n")
d <- ccx_default_params()
# fert_k / beta partial match hazard demonstration
p <- d; p$beta <- NULL; p$fert_form <- CCX_FERT_LOG
cat("LOG form with `beta` absent: p$beta resolves to", p$beta, "(beta_max) -> factor at 400 ppm =", ccx_fert_factor(400, p), "\n")
p <- d; p$fert_k <- NULL; p$fert_k_prior <- 1
cat("MM with fert_k absent, fert_k_prior=1: p$fert_k ->", p$fert_k, " factor at 400 =", ccx_fert_factor(400, p), " vs fert_k=120:", ccx_fert_factor(400, d), "\n")
p <- d; p$sst_eq <- NULL; cat("sst_eq absent: p$sst_eq ->", p$sst_eq, "(sst_eq_enso)\n")
# seas_lag_p legacy + split error
p <- d; p$seas_lag_p <- 1.0; r <- tryCatch(ccx_seas_lag_p(p), error=function(e) "ERROR (by design)"); print(r)
# tau_ex_rate peak timing
p <- d; p$tau_ex_seas_amp <- 0.3; p$tau_ex_seas_phase <- 4
tt <- seq(0, 1, length.out=1201); r <- vapply(tt, function(t) ccx_tau_ex_rate(p, t), 0)
cat("tau_ex_seas_phase = 4 months -> rate peaks at month", 12*tt[which.max(r)], "\n")
# sine-path seas_phase label: seas = amp sin(2pi(t - phase/12)) -> peak uptake (atm->leaf positive)
ph <- d$seas_phase_NH; s <- sin(2*pi*(tt - ph/12)); cat("seas_phase_NH =", ph, " -> sine-path uptake peaks at month", 12*tt[which.max(s)], "\n")
# alpha_as at HS SST and NH ML
md <- readRDS(ccx_mode_file()); p <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_par_with_pins(md))
aux <- ccx_prepare(p, ccx_ocean_grid(p$h_ml))
cat("aux$sst_hs", aux$sst_hs, " sst_NH", p$sst_NH, " sst_SH", p$sst_SH, " sst_seas_amp", p$sst_seas_amp_NH, p$sst_seas_amp_SH, "\n")
for (T in c(aux$sst_hs, 5, 21, p$sst_NH + p$sst_seas_amp_NH + 1.2)) { a <- ccx_alpha_as(T, aux); cat(sprintf("T=%6.2f  eps_down %.4f  eps_up %.4f permil\n", T, (a$down-1)*1000, (a$up-1)*1000)) }
cat("mld_coef NH f_max/min (ml_nh_cycle=0):", aux$mld_coef$NH$f_max, aux$mld_coef$NH$f_min, " SH:", aux$mld_coef$SH$f_max, "\n")
# enso lag tests
set.seed(1); x <- rnorm(40)
cat("int lag 3 exact:", identical(ccx_enso_lagged(x, 3, hist = rep(0, 13))[10], x[7]), "\n")
L <- 5.9293432; full <- ccx_enso_lagged(x, L, hist = rep(0,13))
k <- 17; a <- ccx_enso_lagged(x[1:k], L, hist = rep(0,13)); b <- ccx_enso_lagged(x[(k+1):40], L, hist = ccx_enso_hist_after(x[1:k], rep(0,13)))
cat("split-run identical:", identical(c(a,b), full), "\n")
# causality: perturb x[i] and check lagged series before i unchanged
x2 <- x; x2[20] <- x2[20] + 10; d2 <- ccx_enso_lagged(x2, 0.3, rep(0,13)) - ccx_enso_lagged(x, 0.3, rep(0,13))
cat("perturb row 20, L=0.3: first affected row", which(d2 != 0)[1], "\n")
cat("L=12 ok:", length(ccx_enso_lagged(x, 12, rep(0,13))), " L=11.5 ok:", length(ccx_enso_lagged(x, 11.5, rep(0,13))), "\n")
# norms symmetric sign claim
mid <- (seq_len(720)-0.5)/720; q <- 2; A <- 7
cat("q10 norm sign symmetry:", mean(q^(A*sin(2*pi*(mid-0.4))/10)) - mean(q^(-A*sin(2*pi*(mid-0.4))/10)), "\n")
