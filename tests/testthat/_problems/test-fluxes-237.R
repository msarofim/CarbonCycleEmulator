# Extracted from test-fluxes.R:237

# prequel ----------------------------------------------------------------------
test_p <- function() {
  # the ENSO coefficients ARE in ccx_default_params(), at 0; set them non-zero
  # so the `enso` channel this file checks is actually exercised
  # explicitly (handoff 2026-08-13c sec.7). Set non-zero here so the ENSO
  # channel is genuinely exercised rather than silently absent.
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); p
}

# test -------------------------------------------------------------------------
p <- test_p()
s <- ccx_spinup(p)
F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = s$prod_c14))
dy <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux, record = TRUE)
fl <- attr(dy, "fluxes")
nb <- nrow(s$y)
expect_equal(dim(fl$edges), c(nb + 1L, nb + 1L))
expect_equal(colSums(fl$edges)[-1] - rowSums(fl$edges)[-1], unname(dy[, "C"]), tolerance = 1e-12)
expect_equal(sum(fl$pump_edges), fl$channels[["pump"]], tolerance = 1e-12)
hs0 <- ccx_flux_hs_derive(fl$edges, fl$pump_edges, s$aux)
expect_named(hs0, names(CCX_FLUX_HS))
expect_true(all(hs0 == 0))
ph <- ccx_apply_structure(test_p(), "hilda")
ph$pump_hs_gcm2 <- 50
sh <- ccx_spinup(ph)
Fh <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sh$prod_c14))
dyh <- ccx_deriv(sh$y, Fh$t[7], ph, ccx_forcing_at(Fh, 7), sh$grid, sh$aux, record = TRUE)
flh <- attr(dyh, "fluxes")
ch <- flh$channels
expect_equal(colSums(flh$edges)[-1] - rowSums(flh$edges)[-1], unname(dyh[, "C"]), tolerance = 1e-12)
hs <- ccx_flux_hs_derive(flh$edges, flh$pump_edges, sh$aux)
expect_gt(hs[["hs_as_down"]], 0)
expect_gt(hs[["hs_as_up"]], 0)
expect_gt(hs[["hs_pump"]], 0)
expect_lt(hs[["hs_as_down"]], ch[["as_down"]])
expect_lt(hs[["hs_as_up"]], ch[["as_up"]])
expect_lte(hs[["hs_pump"]], ch[["pump"]] + 1e-12)
expect_gte(hs[["hs_hd_net"]], hs[["hs_pump"]] - abs(hs[["hs_hd_net"]]) * 1e-9 - 1)
