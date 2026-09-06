# Extracted from test-likelihood.R:806

# prequel ----------------------------------------------------------------------
skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}
lik_fixture <- function() {
  obs <- ccx_prepare_obs()
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  list(obs = obs, out = ccx_run_fast(sp, F)$out,
       err = list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5))
}
.lik_co2_level_ll <- function(f, sd) {
  # The CO2 level terms, recomputed from the residual with an explicit sd.
  # Derived here rather than stored, so it cannot go stale against the model.
  ms <- ccx_model_stats(f$out, f$obs)
  sum(vapply(c("MLO", "SPO"), function(st) {
    o <- f$obs$co2_ann[[st]]; m <- ms$co2[[st]]
    k <- match(o$year, m$year); g <- !is.na(k)
    sum(stats::dnorm(o$level[g], m$level[k[g]], sd, log = TRUE))
  }, numeric(1)))
}
.lik_co2_level_parts <- function(f, err) {
  ps <- ccx_loglik(f$out, f$obs, err, by_stream = TRUE)
  ps[["co2_level_MLO"]] + ps[["co2_level_SPO"]]
}

# test -------------------------------------------------------------------------
tg <- ccx_deep_d14c_target()
skip_if(is.null(tg), "GLODAPv2 build product absent")
p <- ccx_default_params()
p$kz <- 10686
runaway <- ccx_spinup(p)$diagnostics$d14c_bottom_box
expect_gt(abs(runaway - tg$target) / tg$sd, 2)
lo <- ccx_spinup(within(ccx_default_params(),
                          kz <- CCX_PARAM_TABLE$kz$lo))$diagnostics$d14c_bottom_box
hi <- ccx_spinup(within(ccx_default_params(),
                          kz <- CCX_PARAM_TABLE$kz$hi))$diagnostics$d14c_bottom_box
expect_lt((hi - lo) / 2, 3 * tg$sd)
