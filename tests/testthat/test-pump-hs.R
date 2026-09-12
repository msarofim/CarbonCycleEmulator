# =====================================================================
# THE HS PUMP -- `pump_hs_gcm2` (2026-09-07d; pays choice C9 of the HILDA boxes)
#
# Export from the high-latitude surface box, remineralised in HD, sized as a
# per-area fraction of the LS pump's net export. The end-member probe showed
# HS's DIC is already the observed high-latitude surface and the deep under it
# lacks +116-185 umol/kg of regenerated carbon; this is the mechanism that
# supplies it.
#
# WHAT THESE TESTS GUARD:
#   * 0 -- and ABSENCE -- reproduce the 09-05 structure bit for bit; with the
#     HS boxes OFF the parameter is inert.
#   * the SIZE means what it says: E = gcm2 * a_hs / 1e15 GtC/yr per hemisphere,
#     split by pump_carb_frac.
#   * MUTATION: 60 gC/m2/yr enriches HD in DIC relative to HS and lightens its d13C;
#     a knob that only touched a diagnostic would be silent.
#   * both cores emit it: R deriv vs C++ transient parity at 60 gC/m2/yr.
#   * invalid values error by name.
# =====================================================================

HP_G <- 60                                  # gC m-2 yr-1, the tested export
hp_par <- function(g = NULL, hs = TRUE) {
  p <- ccx_default_params()
  if (hs) p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12) }
  if (!is.null(g)) p$pump_hs_gcm2 <- g
  p
}
conc <- function(sp, box, h) {              # umol/kg of one box
  aux <- sp$aux; grid <- sp$grid; rho <- ccx_const("RHO_SEAWATER")
  i <- aux$idx[[h]][[box]]
  m <- switch(box, hs = aux$hs_mass_kg[[h]], hd = aux$a_hs[[h]] * aux$dz_hd * rho,
              ml = aux$ml_mass_kg[[h]])
  sp$y[i, "C"] * aux$mol_per_GtC / m * 1e6
}
d13 <- function(sp, box, h) { i <- sp$aux$idx[[h]][[box]]
  1000 * (sp$y[i, "C13"] / sp$y[i, "C"] / ccx_const("R13_VPDB") - 1) }

test_that("the default is 0, and 0 / absence reproduce the structure bit for bit", {
  expect_identical(ccx_default_params()$pump_hs_gcm2, 0)
  a <- ccx_spinup(hp_par(0)); pab <- hp_par(); pab$pump_hs_gcm2 <- NULL; b <- ccx_spinup(pab)
  expect_identical(a$y, b$y)
  expect_null(a$aux$pump_hs); expect_null(b$aux$pump_hs)
  # HS off: nothing to export from
  off1 <- ccx_spinup(hp_par(HP_G, hs = FALSE)); off0 <- ccx_spinup(hp_par(0, hs = FALSE))
  expect_null(off1$aux$pump_hs); expect_identical(off1$y, off0$y)
  # and its SIZE does not depend on the LS pump: strip the LS field from a
  # prepared aux and the HS export is unchanged. (A spinup with the LS pump OFF
  # and the HS pump ON is not a supported state -- its conveyor 12C Newton
  # reports a singular Jacobian; noted in CHANGELOG 2026-09-07e, not chased.)
  sp <- ccx_spinup(hp_par(HP_G)); aux <- sp$aux; aux$pump <- NULL
  expect_equal(ccx_pump_export_hs(sp$params, aux, sp$grid), sp$aux$pump_hs)
})

test_that("the size is gcm2 x a_hs / 1e15 GtC/yr per hemisphere, split by pump_carb_frac", {
  sp <- ccx_spinup(hp_par(HP_G)); aux <- sp$aux
  for (h in HEMIS) {
    E <- aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb
    expect_equal(E, HP_G * aux$a_hs[[h]] / 1e15, tolerance = 1e-12)
    expect_equal(aux$pump_hs[[h]]$carb / E, sp$params$pump_carb_frac, tolerance = 1e-12)
    expect_gt(E, 0)
  }
  expect_equal(sum(vapply(HEMIS, function(h) aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb, 0)),
               HP_G * (aux$a_hs$NH + aux$a_hs$SH) / 1e15, tolerance = 1e-12)
  sp2 <- ccx_spinup(hp_par(2 * HP_G))
  expect_equal(sp2$aux$pump_hs$NH$org, 2 * sp$aux$pump_hs$NH$org, tolerance = 1e-12)
})

test_that("MUTATION: 60 gC/m2/yr enriches HD in DIC relative to HS and lightens HD's d13C", {
  a <- ccx_spinup(hp_par(0)); b <- ccx_spinup(hp_par(HP_G))
  for (h in HEMIS) {
    expect_gt(conc(b, "hd", h) - conc(b, "hs", h), conc(a, "hd", h) - conc(a, "hs", h) + 20)
    expect_lt(d13(b, "hd", h), d13(a, "hd", h) - 0.1)
  }
  # and the conservative construction: the spinup still converges
  expect_lt(b$diagnostics$max_abs_dCdt, 1e-6)
})

test_that("both cores emit it: R deriv vs C++ transient at 60 gC/m2/yr", {
  skip_if_no_cpp()
  sp <- ccx_spinup(hp_par(HP_G))
  F  <- ccx_build_forcing("historical", c(1750, 1765), prod_c14 = sp$prod_c14)
  rR <- ccx_run(sp, F)$out; rC <- ccx_run_fast(sp, F)$out
  for (cc in c("co2_NH", "d13c_SH", "d14c_NH", "ocean_C"))
    expect_equal(rR[[cc]], rC[[cc]], tolerance = 1e-7)
  # and the C++ transient is not identical to the off one (the flux is live there too)
  sp0 <- ccx_spinup(hp_par(0)); F0 <- ccx_build_forcing("historical", c(1750, 1765), prod_c14 = sp0$prod_c14)
  expect_false(identical(ccx_run_fast(sp0, F0)$state, ccx_run_fast(sp, F)$state))
})

test_that("invalid values error by name", {
  expect_error(ccx_spinup(hp_par(-1)), "pump_hs_gcm2")
  expect_error(ccx_spinup(hp_par(NA_real_)), "pump_hs_gcm2")
})

test_that("the table's init and prior are TIED to the literature build product", {
  pr <- readRDS(ccx_path("data", "obs_hs_export_prior.rds")); s <- CCX_PARAM_TABLE$pump_hs_gcm2
  expect_equal(s$init, pr$centre_gcm2, tolerance = 0.05 / pr$centre_gcm2)   # literal vs computed, to 0.05
  for (x in c(7, 22.9, 60)) expect_equal(s$prior(x), dlnorm(x, log(pr$centre_gcm2), pr$log_sd, log = TRUE))
  expect_gt(s$prior(pr$centre_gcm2), s$prior(60))                            # 60 is the probe point, not the centre
  expect_true(all(c("L25", "A19") %in% names(pr$sources)))
})
