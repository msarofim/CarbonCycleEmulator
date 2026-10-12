setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
p <- readRDS("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L1/p_canon.rds")
grid <- ccx_ocean_grid(p$h_ml)
cat("grid sum dz", sum(grid$dz), " vs depth", ccx_const("OCEAN_DEPTH"), "\n")
aux <- ccx_prepare(p, grid)
cat("aux names with area:\n"); print(grep("^a_", names(aux), value=TRUE))
for (h in HEMIS) {
  s <- sum(unlist(lapply(c("a_ml","a_hs","a_eq","a_tr"), function(n) { v <- aux[[n]]; if (is.null(v)) 0 else if (is.list(v)) v[[h]] else if (length(v)==2) v[[if(h=="NH")1 else 2]] else 0 })))
  cat(h, "a_ml+a_hs+a_eq+a_tr =", s, " a_oc =", aux$a_oc[[h]], " rel diff", s/aux$a_oc[[h]]-1, "\n")
}
cat("\n-- idx --\n"); str(aux$idx$NH); str(aux$idx$SH)
bn <- ccx_box_names(grid$nl, ccx_hs_on(p), ccx_eq_on(p), ccx_tr_on(p), ccx_inert_on(p))
cat("n boxes", length(bn), "\n"); print(bn)
cat("inert idx", ccx_inert_idx(aux), "\n")
# LUC shares
sh <- ccx_luc_pool_shares(p); cat("\nLUC shares", sh, " sum-1 =", sum(sh)-1, "\n")
for (h in HEMIS) {
  pools <- aux$npp0[[h]] * c(p$npp_leaf_frac*p$tau_leaf, (1-p$npp_leaf_frac)*p$tau_wood, (1-ccx_litter_slow_eff(p))*p$tau_soil_fast, ccx_litter_slow_eff(p)*p$tau_soil_slow)
  cat(h, "land0", aux$land0[[h]], " sum pools", sum(pools), " shares eq:", isTRUE(all.equal(pools/sum(pools), sh)), " soil_inert", aux$soil_inert[[h]],
      " inert+slow_exch =", aux$soil_inert[[h]] + pools[4], " uncarved slow =", aux$npp0[[h]]*p$litter_slow_frac*p$tau_soil_slow, "\n")
}
# fert factor at chi0
cat("\nfert at chi0 (MM):", ccx_fert_factor(aux$chi0, p, aux$chi0), " default chi0 arg == aux$chi0:", identical(ccx_const("CO2_PI_PPM"), aux$chi0), "\n")
pl <- p; pl$fert_form <- CCX_FERT_LOG; cat("fert at chi0 (LOG):", ccx_fert_factor(aux$chi0, pl), "\n")
# cache key test
cat("\n-- seas norm cache --\n")
stopifnot(!is.null(aux$seas_norm))
chk <- function(lab, p2) {
  a <- ccx_seas_norms_for(p2, aux); b <- ccx_seas_norms(p2)
  same <- isTRUE(all.equal(a$NH, b$NH)) && isTRUE(all.equal(a$SH, b$SH))
  cat(sprintf("%-28s cached==fresh: %s  (key hit: %s)\n", lab, same, identical(aux$seas_norm$key, ccx_seas_norm_key(p2))))
}
chk("unchanged", p)
p2 <- p; p2$q10 <- 2.5; chk("q10 changed", p2)
p2 <- p; p2$seas_T_amp_NH <- 20; chk("seas_T_amp_NH changed", p2)
p2 <- p; p2$seas_T_amp_SH <- 9; chk("seas_T_amp_SH changed", p2)
p2 <- p; p2$seas_lag_p_NH <- 3; chk("seas_lag_p_NH changed", p2)
p2 <- p; p2$seas_lag_p_SH <- 0.5; chk("seas_lag_p_SH changed", p2)
p2 <- p; p2$seas_npp_amp_NH <- 0.9; chk("seas_npp_amp_NH (not in norm)", p2)
# insol sanity
cat("\n-- insol --\n")
tt <- (seq_len(365)-0.5)/365
for (ph in c(0, 45, 75, -30, 90, -90)) { q <- ccx_insol(ph, tt); cat(sprintf("phi %4d: mean %.4f max at day %3d min at day %3d; min %.4f\n", ph, mean(q), which.max(q), which.min(q), min(q))) }
cat("dec at t=0:", -23.44*cos(2*pi*(0*365.25+10)/365.25), " at t=171.5/365.25:", -23.44*cos(2*pi*(171.5+10)/365.25), "\n")
cat("periodic: ", ccx_insol(75, 0.3) - ccx_insol(75, 2000.3), "\n")
# MLD fourier check
cat("\n-- mld fourier --\n")
co <- ccx_mld_shape("ls")
for (h in HEMIS) {
  tc <- (seq_len(12)-0.5)/12
  rec <- vapply(tc, function(t) ccx_mld_eval(co[[h]], t)$f, 0)
  cat(h, "max |rec - f_month| =", max(abs(rec - co[[h]]$f_month)), " continuous mean =", mean(vapply((seq_len(1e4)-0.5)/1e4, function(t) ccx_mld_eval(co[[h]], t)$f, 0)), "\n")
  e <- 1e-6; t0 <- 0.37
  num <- (ccx_mld_eval(co[[h]], t0+e)$f - ccx_mld_eval(co[[h]], t0-e)$f)/(2*e)
  cat("   dfdt analytic", ccx_mld_eval(co[[h]], t0)$dfdt, " numeric", num, "\n")
}
cat("canon ml_nh_cycle", p$ml_nh_cycle, "; aux mld shapes NH f_max", aux$mld_shape$NH$f_max, "\n")
print(grep("mld|shape", names(aux), value=TRUE))
# grid_at_h_ml conservation
g2 <- ccx_grid_at_h_ml(grid, grid$h_ml*1.3)
cat("\ngrid_at_h_ml share=1: dz1+dz2 before", sum(grid$dz[1:2]), " after", sum(g2$dz[1:2]), " total", sum(g2$dz)-sum(grid$dz), "\n")
cat("guard base", cumsum(grid$dz)[2], " h_ml*f_max NH/SH", grid$h_ml*co$NH$f_max, grid$h_ml*co$SH$f_max, "\n")
