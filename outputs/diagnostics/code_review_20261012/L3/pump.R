source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
rp <- readRDS(file.path(S, "rp.rds")); p <- rp$p
grid <- ccx_ocean_grid(p$h_ml); aux <- ccx_prepare(p, grid)
nl <- grid$nl
shape <- ccx_pump_shape(grid); prof <- (shape - shape[1]) / (shape[nl + 1] - shape[1]) * p$pump_grad
diffop <- function(K, dz, dzm) { J <- matrix(0, nl + 1, nl + 1)
  for (k in seq_len(nl)) { a <- k; b <- k + 1
    J[a, a] <- J[a, a] - K[k] / (dz[a] * dzm[k]); J[a, b] <- J[a, b] + K[k] / (dz[b] * dzm[k])
    J[b, a] <- J[b, a] + K[k] / (dz[a] * dzm[k]); J[b, b] <- J[b, b] - K[k] / (dz[b] * dzm[k]) }; J }
for (h in HEMIS) {
  kappa <- aux$a_ls[[h]] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
  yprof <- kappa * prof * 1e-6 * grid$dz                      # GtC per box carrying the profile ANOMALY
  Sx <- aux$pump[[h]]$org + aux$pump[[h]]$carb
  Su <- aux$pump_up[[h]]$org + aux$pump_up[[h]]$carb
  for (g in c(1, 0.9, 0.5)) {
    K <- aux$kz_int - (1 - g) * aux$kz_up
    src <- c(-sum(Sx - (1 - g) * Su), Sx - (1 - g) * Su)       # ML loses the export, layer k gains S_k
    res <- diffop(K, grid$dz, aux$dz_mid) %*% yprof + src
    cat(sprintf("%s g=%.1f: export %.4f GtC/yr; max|D(K_g) y + S_g| = %.3e (rel to export %.1e); neg layers: %d\n",
                h, g, sum(Sx - (1 - g) * Su), max(abs(res)), max(abs(res)) / sum(Sx), sum(Sx - (1 - g) * Su < 0)))
  }
  cat(h, " S by layer:", signif(Sx, 4), "\n")
  cat(h, " carb frac realised:", sum(aux$pump[[h]]$carb) / sum(Sx), " HS pump org+carb:", aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb,
      " expected:", p$pump_hs_gcm2 * aux$a_hs[[h]] / 1e15, "\n")
}
cat("realised gradient check: prof[nl+1]-prof[1] =", prof[nl+1] - prof[1], " pump_grad =", p$pump_grad, "\n")
# record vs no-record identity of the R derivative at canonical
x <- readRDS(file.path(S, "s2.rds")); s2 <- x$s2; Fb <- x$Fb
Fb$land_enso <- ccx_land_enso(Fb$enso, ccx_enso_lag_of(p), s2$enso_hist)
Fb$mix_g <- as.numeric(ccx_mix_g_series(Fb$gmst, Fb$t, p, s2$tdeep0))
for (i in c(1L, 8L, 100L)) { fi <- ccx_forcing_at(Fb, i)
  d0 <- suppressWarnings(ccx_deriv(s2$y, Fb$t[i], p, fi, s2$grid, s2$aux))
  d1 <- suppressWarnings(ccx_deriv(s2$y, Fb$t[i], p, fi, s2$grid, s2$aux, record = TRUE)); attr(d1, "fluxes") <- NULL
  dC <- ccx_deriv_fast(s2$y, Fb$t[i], p, fi, s2$grid, s2$aux)
  cat(sprintf("row %d t=%.4f: identical(record, no-record) %s; R vs C++ max rel %.2e\n", i, Fb$t[i], identical(d0, d1), max(abs(d0 - dC)) / max(abs(d0))))
}
