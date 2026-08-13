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
  # cum_luc is deliberately NON-ZERO: at zero the converted-land term collapses
  # to (1 - 0) and a porting error in it would be invisible to this gate.
  forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
               cum_luc = list(NH = 120, SH = 80),
               gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
               c14_cosmo = sp$prod_c14, d13c_foss = -27.6)
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
  # 14C inventories: a separate accumulation in each implementation, and the
  # ocean excess-14C likelihood term reads them, so they get their own gate
  # rather than riding on the D14C ratios above.
  for (cc in c("ocean_C14", "land_C14", "atm_C14"))
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13)
  # and the final state as a whole
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
})

test_that("parity holds with the frozen-Revelle switch engaged", {
  skip_if_no_cpp()
  # A mechanism switch adds a SECOND code path through the air-sea term, in both
  # implementations. The default parity tests exercise only the first, so a
  # porting error on the frozen branch would be invisible to them.
  p <- pf$p; p$revelle_frozen <- 1
  sp <- ccx_spinup(p)
  # cum_luc is deliberately NON-ZERO: at zero the converted-land term collapses
  # to (1 - 0) and a porting error in it would be invisible to this gate.
  forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
               cum_luc = list(NH = 120, SH = 80),
               gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
               c14_cosmo = sp$prod_c14, d13c_foss = -27.6)
  dR <- ccx_deriv(sp$y, 1980.5, p, forc, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, 1980.5, p, forc, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-15)

  F  <- ccx_build_forcing("historical", c(1900, 1980), prod_c14 = sp$prod_c14)
  rR <- ccx_run(sp, F)
  rC <- ccx_run_fast(sp, F)
  expect_lt(max(abs(rR$out$co2_NH - rC$out$co2_NH)) / max(abs(rR$out$co2_NH)), 1e-13)
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
})

test_that("frozen Revelle does what it claims, and only that", {
  skip_if_no_cpp()
  p_on  <- pf$p
  p_off <- pf$p; p_off$revelle_frozen <- 1
  sp_on  <- ccx_spinup(p_on)
  sp_off <- ccx_spinup(p_off)

  # The preindustrial buffer factor is an EMERGENT check on the carbonate
  # system, not a tuned input: observed surface-ocean Revelle factors run ~8-10.
  expect_gt(sp_on$aux$revelle0$NH, 7); expect_lt(sp_on$aux$revelle0$NH, 11)
  expect_gt(sp_on$aux$revelle0$SH, 7); expect_lt(sp_on$aux$revelle0$SH, 11)

  F <- suppressWarnings(
    ccx_build_forcing("ssp245", c(1750, 2100), prod_c14 = sp_on$prod_c14))
  a <- ccx_run_fast(sp_on, F)$out
  b <- ccx_run_fast(sp_off, F)$out

  # 1850: the buffer has barely moved, so the two paths must still agree
  i0 <- which.min(abs(F$t - 1850.5))
  expect_lt(abs(a$co2_NH[i0] - b$co2_NH[i0]), 0.1)

  # 2100: frozen buffer -> the ocean never loses efficiency -> MORE ocean carbon
  # and LESS airborne CO2. The sign is the whole pedagogical point; if it ever
  # flips, the switch is telling students the opposite of the physics.
  i <- which.min(abs(F$t - 2100.5))
  expect_lt(b$co2_NH[i], a$co2_NH[i])
  expect_gt(b$ocean_C[i], a$ocean_C[i])
  expect_gt(a$co2_NH[i] - b$co2_NH[i], 10)      # measured ~46 ppm

  # carbon is still conserved on the frozen path
  Fz <- ccx_build_forcing("historical", c(1800, 1900), prod_c14 = 0)
  Fz$e_foss_NH <- 0; Fz$e_foss_SH <- 0; Fz$e_luc_NH <- 0; Fz$e_luc_SH <- 0
  Fz$c14_bomb <- 0; Fz$c14_nuclear <- 0
  r <- ccx_run_fast(sp_off, Fz)
  expect_lt(abs(sum(r$state[, "C"]) / sum(sp_off$y[, "C"]) - 1), 1e-12)
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
