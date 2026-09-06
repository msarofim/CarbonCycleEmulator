# Extracted from test-likelihood.R:665

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
expect_false("rho" %in% CCX_PARAM_NAMES)
expect_length(CCX_PARAM_NAMES, 28L)
expect_true(all(c("kz_deep_frac", "hs_asx_frac") %in% CCX_PARAM_NAMES))
expect_true("ent_seas_amp_SH" %in% CCX_PARAM_NAMES)
expect_true(all(CCX_ENSO_PARAMS %in% CCX_PARAM_NAMES))
expect_false("gamma_enso" %in% CCX_PARAM_NAMES)
expect_true(all(c("seas_T_amp_NH", "seas_T_amp_SH",
                    "seas_lag_p_NH", "seas_lag_p_SH",
                    "sst_seas_amp_NH", "sst_seas_amp_SH") %in% CCX_PARAM_NAMES))
expect_false("seas_lag_p" %in% CCX_PARAM_NAMES)
expect_false(any(c("seas_amp_NH", "seas_phase_NH") %in% CCX_PARAM_NAMES))
expect_true("pump_grad" %in% CCX_PARAM_NAMES)
expect_equal(CCX_PARAM_TABLE$pump_grad$init, ccx_const("PUMP_GRAD_OBS"),
               tolerance = 1e-12)
expect_false("sigma_co2" %in% CCX_PARAM_NAMES)
expect_true(all(c("grad_off_co2", "grad_off_d13c") %in% CCX_PARAM_NAMES))
expect_equal(CCX_PARAM_TABLE$npp_frac_NH$init,
               ccx_const("NPP_FRAC_NH_ANCHOR_1750"), tolerance = 1e-12)
a <- ccx_const("NPP_FRAC_NH_ANCHOR_1750")
expect_gt(CCX_PARAM_TABLE$npp_frac_NH$prior(a),
            CCX_PARAM_TABLE$npp_frac_NH$prior(a + 0.01))
expect_gt(CCX_PARAM_TABLE$npp_frac_NH$prior(a),
            CCX_PARAM_TABLE$npp_frac_NH$prior(a - 0.01))
expect_gt(a, ccx_const("NPP_FRAC_NH_OBS"))
expect_lt(a - ccx_const("NPP_FRAC_NH_OBS"), 0.05)
expect_equal(CCX_PARAM_TABLE$grad_off_co2$init,  0)
expect_equal(CCX_PARAM_TABLE$grad_off_d13c$init, 0)
for (n in c("grad_off_co2", "grad_off_d13c")) {
    pr <- CCX_PARAM_TABLE[[n]]$prior
    expect_equal(pr(0.3), pr(-0.3), tolerance = 1e-12)   # symmetric about 0
    expect_gt(pr(0), pr(0.3))                            # and peaked there
  }
expect_true("luc_scale" %in% CCX_PARAM_NAMES)
expect_true(all(c("beta_max", "fert_k") %in% CCX_PARAM_NAMES))
expect_false("beta" %in% CCX_PARAM_NAMES)
expect_true("beta" %in% names(ccx_default_params()))
expect_false("luc_scale" %in% names(ccx_default_params()))
for (n in c("tau_soil_fast", "tau_soil_slow", "tau_leaf", "tau_wood",
              "npp_leaf_frac", "litter_slow_frac"))
    expect_false(n %in% CCX_PARAM_NAMES, info = n)
expect_identical(CCX_PARAM_TABLE$kz$tr, "logit")
expect_gte(CCX_PARAM_TABLE$kz$lo, 3500)
