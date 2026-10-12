suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total,
                       luc_scale = v$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(sp$params), sp$enso_hist)
F[["mix_g"]] <- if (ccx_mix_on(sp$params)) as.numeric(ccx_mix_g_series(F$gmst, F$t, sp$params, sp$tdeep0)) else NULL
cat("aux$l2_on:", sp$aux$l2_on, " k_l2:", sp$aux$k_l2, "\n")
for (yr in c(1998, 2016)) {
  res <- mlint <- numeric(12)
  for (m in 1:12) {
    i <- which(F$year == yr)[m]
    y <- ccx_run_fast(sp, F[seq_len(i - 1), ])$state[rownames(sp$y), , drop = FALSE]
    dy <- ccx_deriv(y, F$t[i], sp$params, ccx_forcing_at(F, i), sp$grid, sp$aux, record = TRUE)
    fl <- attr(dy, "fluxes")
    iml <- c(sp$aux$idx$NH$ml, sp$aux$idx$SH$ml)
    res[m] <- sum(dy[iml, "C"] - fl$boxnet[iml])     # carbon into the two MLs that the tap did not record
    mlint[m] <- fl$channels[["ml_int"]]
  }
  cat(yr, ": enso annual mean", round(mean(F$enso[F$year == yr]),2), " untapped L2 flux into ML (annual mean)", round(mean(res),3),
      "GtC/yr ; recorded ml_int channel", round(mean(mlint),3), " ; max monthly |untapped|", round(max(abs(res)),3), "\n")
}
# confirm: with w_enso_l2 = 0 the tap is complete
p0 <- sp$params; p0$w_enso_l2 <- 0; aux0 <- ccx_prepare(p0)
i <- which(F$year == 1963)[7]; y <- ccx_run_fast(sp, F[seq_len(i - 1), ])$state[rownames(sp$y), , drop = FALSE]
dy0 <- ccx_deriv(y, F$t[i], p0, ccx_forcing_at(F, i), sp$grid, aux0, record = TRUE)
cat("w_enso_l2 = 0 at the same state: max|boxnet - dyC|", max(abs(attr(dy0, "fluxes")$boxnet - dy0[, "C"])), "\n")
