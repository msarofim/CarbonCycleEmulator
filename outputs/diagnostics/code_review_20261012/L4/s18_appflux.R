t0 <- Sys.time()
suppressMessages(suppressWarnings(source("app/global.R", chdir = TRUE)))
cat("global.R sourced in", format(Sys.time() - t0), "\n")
cat("mode:", APP_SPINUP_LABEL, " w_enso_l2:", APP_PARAMS$w_enso_l2, " l2_on:", APP_SPIN$aux$l2_on, "\n")
fx <- APP_FLUX_NOW
cat("APP_FLUX_NOW year:", fx$year, "\n")
F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
keep <- list()
r <- suppressWarnings(ccx_run(APP_SPIN, F, fluxes = TRUE, edge_fn = function(fl, y, t) if (floor(t) == 2024) list(y = y, t = t, boxnet = fl$boxnet) else NULL))
fa <- ccx_flux_annual(r$fluxes); stopifnot(isTRUE(all.equal(fa[nrow(fa), ], APP_FLUX_NOW)))
# same land_enso / mix_g columns ccx_run builds
sp <- APP_SPIN; p <- sp$params
F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(p), sp$enso_hist)
F[["mix_g"]] <- if (ccx_mix_on(p)) as.numeric(ccx_mix_g_series(F$gmst, F$t, p, sp$tdeep0)) else NULL
idx <- which(floor(F$t) == 2024)
miss <- matrix(NA, 12, 2, dimnames = list(NULL, c("NH", "SH")))
for (m in seq_along(idx)) {
  e <- r$edge_trace[[idx[m]]]
  dy <- suppressWarnings(ccx_deriv(e$y, e$t, p, ccx_forcing_at(F, idx[m]), sp$grid, sp$aux, record = TRUE))
  for (h in c("NH", "SH")) { iml <- sp$aux$idx[[h]]$ml; miss[m, h] <- dy[iml, "C"] - attr(dy, "fluxes")$boxnet[iml] }
  # all untapped must sit on ml and oc[k_l2] only
  res <- dy[, "C"] - attr(dy, "fluxes")$boxnet
  ok <- setdiff(which(abs(res) > 1e-9), unlist(lapply(c("NH","SH"), function(h) c(sp$aux$idx[[h]]$ml, sp$aux$idx[[h]]$oc[sp$aux$k_l2]))))
  if (length(ok)) cat("untapped elsewhere at month", m, ":", ok, "\n")
}
L2 <- colMeans(miss)   # GtC/yr INTO the ML (positive = upward, the ml_int sign convention is down-positive)
cat(sprintf("(a) 2024 annual-mean L2 flux the trace misses, INTO the mixed layer: NH %.4f SH %.4f total %.4f GtC/yr\n", L2[1], L2[2], sum(L2)))
ml_int_new <- fx$ml_int - sum(L2)       # ml_int is ml->int positive; L2 into ML is int->ml
cat(sprintf("(b) now: pump %.4f, -ml_int %.4f, net %.4f  | printed: %.0f / %.0f / %.0f\n", fx$pump, -fx$ml_int, fx$ml_int + fx$pump, fx$pump, -fx$ml_int, fx$ml_int + fx$pump))
cat(sprintf("    with L2: pump %.4f, -ml_int %.4f, net %.4f | printed: %.0f / %.0f / %.0f\n", fx$pump, -ml_int_new, ml_int_new + fx$pump, fx$pump, -ml_int_new, ml_int_new + fx$pump))
cat(sprintf("    turnover: atm_out %.3f tau_turn %.3f (reads gpp + as_down only)\n", fx$atm_out, fx$tau_turn))
cat(sprintf("    aside: hs_hd_net %.4f hs_pump %.4f (inside ml_int + pump)\n", fx$hs_hd_net, fx$hs_pump))
