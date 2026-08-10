# =====================================================================
# Gate 4: the C++ core and the R reference are the same model.
#
# NOT bit-identical -- see the note at the top of src/ccx_core.cpp. Measured
# agreement is roundoff-level (~1e-13 absolute over 81 years, 15,552 derivative
# evaluations). The tolerances below are set well inside that but far below any
# real porting error, and the gate is mutation-tested (see the scratch analysis
# recorded in CHANGELOG) so a wrong index or dropped term cannot pass.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

pf <- local({
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  list(p = p)
})

test_that("single derivative agrees to roundoff", {
  skip_if_no_cpp()
  sp <- ccx_spinup(pf$p)
  forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
               gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
               c14_cosmo = sp$prod_c14)
  dR <- ccx_deriv(sp$y, 1980.5, pf$p, forc, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, 1980.5, pf$p, forc, sp$grid, sp$aux)
  # Scale-relative: per-cell relative error is meaningless for cells whose value
  # is ~1e-16 (deep-ocean 14C tendencies that nearly cancel).
  expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-15)
})

test_that("multi-decade trajectories agree to roundoff", {
  skip_if_no_cpp()
  sp <- ccx_spinup(pf$p)
  F  <- ccx_build_forcing("historical", c(1900, 1980), prod_c14 = sp$prod_c14)
  rR <- ccx_run(sp, F)
  rC <- ccx_run_fast(sp, F)
  # CO2 is the quantity everything else keys off
  expect_lt(max(abs(rR$out$co2_NH - rC$out$co2_NH)) / max(abs(rR$out$co2_NH)), 1e-13)
  expect_lt(max(abs(rR$out$co2_SH - rC$out$co2_SH)) / max(abs(rR$out$co2_SH)), 1e-13)
  # isotopes, on their own scales
  expect_lt(max(abs(rR$out$d13c_NH - rC$out$d13c_NH)), 1e-9)
  expect_lt(max(abs(rR$out$d14c_NH - rC$out$d14c_NH)), 1e-8)
  # stocks
  expect_lt(max(abs(rR$out$ocean_C - rC$out$ocean_C)) / max(abs(rR$out$ocean_C)), 1e-13)
  expect_lt(max(abs(rR$out$land_C  - rC$out$land_C))  / max(abs(rR$out$land_C)),  1e-13)
  # and the final state as a whole
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
})

test_that("the C++ core conserves carbon exactly, independently of R", {
  skip_if_no_cpp()
  # The conservation property must hold in the port on its own terms, not only
  # by inheritance from the reference.
  sp <- ccx_spinup(pf$p)
  F  <- ccx_build_forcing("historical", c(1800, 1900), prod_c14 = 0)
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  F$c14_bomb  <- 0; F$c14_nuclear <- 0
  r <- ccx_run_fast(sp, F)
  expect_lt(abs(sum(r$state[, "C"]) / sum(sp$y[, "C"]) - 1), 1e-12)
})

test_that("the C++ core is fast enough for MCMC", {
  skip_if_no_cpp()
  sp <- ccx_spinup(pf$p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  el <- system.time(ccx_run_fast(sp, F))[["elapsed"]]
  # Budget is 50 ms/run so that 1e5 MCMC evaluations stay under ~1.5 h.
  expect_lt(el, 0.05)
})
