suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total,
                       luc_scale = v$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(sp$params), sp$enso_hist)
F[["mix_g"]] <- if (ccx_mix_on(sp$params)) as.numeric(ccx_mix_g_series(F$gmst, F$t, sp$params, sp$tdeep0)) else NULL
for (yr in c(1750, 1963, 2020)) {
  i <- which(F$year == yr)[7]   # July
  y <- if (i > 1) ccx_run_fast(sp, F[seq_len(i - 1), ])$state else sp$y
  y <- y[rownames(sp$y), , drop = FALSE]
  dy <- ccx_deriv(y, F$t[i], sp$params, ccx_forcing_at(F, i), sp$grid, sp$aux, record = TRUE)
  fl <- attr(dy, "fluxes")
  netres <- max(abs(fl$boxnet - dy[, "C"]))
  ch <- ccx_flux_derive(fl$channels, y, sp$aux)
  atm <- unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]]$atm))
  datm <- sum(dy[atm, "C"])
  ident <- datm - (ch[["foss"]] - ch[["land_net"]] - ch[["ocean_net"]])
  land <- unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]]$land)); if (!is.null(sp$aux$idx$NH[[CCX_LAND_INERT]])) land <- c(land, unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]][[CCX_LAND_INERT]])))
  dland <- sum(dy[unique(land), "C"])
  cat(sprintf("%d-07: max|boxnet - dyC| %.2e ; atm' - (foss - land_net - ocean_net) = %.2e ; land' - land_net = %.2e ; total dC = %.3e vs foss %.4f\n",
              yr, netres, ident, dland - ch[["land_net"]], sum(dy[, "C"]), ch[["foss"]]))
  # 14C edges consistency: rec14 + sources/decay should equal dy C14
}
cat("land idx includes inert? ", CCX_LAND_INERT %in% names(sp$aux$idx$NH), " land idx:", paste(sp$aux$idx$NH$land, collapse=","), " inert:", sp$aux$idx$NH[[CCX_LAND_INERT]], "\n")
