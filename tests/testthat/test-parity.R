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

# THE DERIVATIVE TOLERANCES, DERIVED FROM THE FLUX COUNT RATHER THAN FITTED TO A
# MEASUREMENT (2026-08-16e).
#
# These were a single hard-coded 1e-15 relative, which was really an operation
# count in disguise: it was sized on a pump-OFF derivative, where the two cores
# happen to accumulate the mixed-layer tendency in nearly the same order and
# agree to 5.1e-18. Wiring the biological pump ON took it to 8.5e-15 and the gate
# fired -- NOT a parity break, and re-baselining the constant to the number that
# passed would have destroyed the gate's meaning.
#
# THE DERIVATION. The pump emits through `add_flux` into each of the `nl` = 10
# interior boxes, on both the organic and the carbonate limb: 2 * nl = 20 extra
# terms accumulating into the mixed layer, carrying 18.83 GtC/yr in total. R and
# C++ walk that loop in different orders, so the reassociation error is bounded
# by n_terms * eps * throughput = 20 * 2.22e-16 * 18.83 = 8.36e-14 GtC/yr.
# MEASURED: 8.53e-14, i.e. 1.02x the bound -- the disagreement is exactly
# floating-point reassociation of the pump's own fluxes and nothing else. Divided
# by max|dR| = 10.05 that is 8.5e-15 relative.
#
# So the tolerance below is 4x the DERIVED bound, not a round number above the
# measurement -- and if a future mechanism raises the flux count, the right move
# is to re-derive this line, not to raise it again.
PARITY_REL_TOL <- 5e-14
# ...and the pump-OFF arm keeps the ORIGINAL tolerance, unweakened. Without it,
# loosening the constant above would let a genuine parity break in any pre-pump
# code path hide inside the pump's roundoff budget. Measured 5.1e-18.
PARITY_REL_TOL_OFF <- 1e-15

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
  expect_lt(max(abs(dR - dC)) / max(abs(dR)), PARITY_REL_TOL)
  # THE PUMP-OFF ARM at the original tolerance -- see the derivation above. This
  # is what stops PARITY_REL_TOL from being a place for a real disagreement in
  # the pre-pump code paths to hide.
  p0 <- pf$p; p0$pump_grad <- 0
  # seas_drivers = 0 for the same reason as the frozen-Revelle arm below: this
  # is the STRICT 1e-15 gate on the PRE-pump (hence pre-driver) code paths.
  # The driver path's transcendentals sit at ~2e-15 and are gated by the
  # derived PARITY_REL_TOL three lines up, which runs WITH drivers on.
  p0$seas_drivers <- 0
  sp0 <- ccx_spinup(p0); f0 <- forc; f0$c14_cosmo <- sp0$prod_c14
  d0R <- ccx_deriv(sp0$y, 1980.5, p0, f0, sp0$grid, sp0$aux)
  d0C <- ccx_deriv_fast(sp0$y, 1980.5, p0, f0, sp0$grid, sp0$aux)
  expect_lt(max(abs(d0R - d0C)) / max(abs(d0R)), PARITY_REL_TOL_OFF)
})

test_that("the pro-rata land-use debit agrees to roundoff", {
  skip_if_no_cpp()
  # f_luc_wood < 1 is a SECOND code path in both cores (R/model.R's emissions
  # block, ccx_core.cpp's), and the default 1 never reaches it -- so the gate
  # above cannot see a porting error in it. The weights are re-derived from the
  # six land parameters on each side rather than shared, precisely so that this
  # test is the thing that catches a disagreement.
  p <- pf$p; p$f_luc_wood <- 0
  sp <- ccx_spinup(p)
  forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
               cum_luc = list(NH = 120, SH = 80),
               gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
               c14_cosmo = sp$prod_c14, d13c_foss = -27.6)
  dR <- ccx_deriv(sp$y, 1980.5, p, forc, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, 1980.5, p, forc, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)) / max(abs(dR)), PARITY_REL_TOL)
  # and it must actually be a different model from the WOOD-ONLY one, or the
  # test above would be passing for the wrong reason. Stated as an explicit
  # f_luc_wood = 1, NOT as `pf$p`: the default moved 1 -> 0 on 2026-08-13 and a
  # comparison against the default silently became a comparison with itself.
  pw <- pf$p; pw$f_luc_wood <- 1
  dW <- ccx_deriv(sp$y, 1980.5, pw, forc, sp$grid, sp$aux)
  expect_gt(max(abs(dR - dW)), 1e-6)
  # the pro-rata weights sum to 1: the debit is a split, not a leak
  expect_equal(sum(ccx_luc_pool_shares(p)), 1, tolerance = 1e-12)
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
  # Mixed-layer and bottom-box C and 13C, per hemisphere: a SEPARATE emission in
  # each implementation, positionally named from CCX_OCEAN_BOX_COLS on the C++
  # side, and the ocean gradient likelihood terms read them. A transposed pair
  # here would be invisible to every gate above, so they get their own.
  for (cc in CCX_OCEAN_BOX_COLS)
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13)
  # ...and they must actually differ from each other, or a column-order bug that
  # filled all four with the same box would pass the line above.
  expect_gt(abs(rC$out$deep_C_NH[1] - rC$out$ml_C_NH[1]), 1)
  expect_gt(abs(rC$out$ml_C_SH[1]   - rC$out$ml_C_NH[1]), 1e-6)
  # and the final state as a whole
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
})

test_that("parity holds with the frozen-Revelle switch engaged", {
  skip_if_no_cpp()
  # A mechanism switch adds a SECOND code path through the air-sea term, in both
  # implementations. The default parity tests exercise only the first, so a
  # porting error on the frozen branch would be invisible to them.
  p <- pf$p; p$revelle_frozen <- 1
  # seas_drivers = 0: this arm carries the STRICT 1e-15 gate on the pre-driver
  # code paths. The driver path's extra transcendentals (acos/pow, evaluated in
  # different order by R and C++) sit at ~2e-15 and are gated by the main arm's
  # DERIVED tolerance above -- letting them into this arm would force weakening
  # the one gate that keeps old-path disagreements from hiding.
  p$seas_drivers <- 0
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
  # seas_drivers = 0: the 1850-agreement gate below rests on "the buffer has
  # barely moved, so the ONLY difference between the arms is buffer
  # stretching". The frozen branch pins pco2_ml to the linearised-DIC form with
  # NO temperature dependence, so under the driver model the seasonal SST cycle
  # drives a seasonal pCO2 cycle on the LIVE arm only, and the rectification
  # difference alone accumulates 0.38 ppm by 1850 -- nothing to do with what
  # this test guards. Both arms run seasonless, preserving the gate's premise.
  # sst_obs = 0 for the same reason as seas_drivers: the frozen branch's pCO2
  # has no T-dependence, so REAL 1850s SST anomalies (not just the seasonal
  # cycle) move the live arm only -- 0.12 ppm at the 0.1-ppm 1850 gate.
  p_on  <- pf$p;  p_on$seas_drivers <- 0;  p_on$sst_obs <- 0
  p_off <- pf$p; p_off$revelle_frozen <- 1; p_off$seas_drivers <- 0; p_off$sst_obs <- 0
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

test_that("the single-step flat forcing vector is complete, and AOD reaches the core", {
  skip_if_no_cpp()
  # ⚠ REGRESSION, 2026-08-29k. ccx_deriv_fast() builds a FLAT forcing vector that
  # the C++ indexes BY POSITION against CCX_FORCING_COLS. When aod_NH/aod_SH were
  # appended (08-29g) the matrix builder ccx_cpp_forcing() was extended and this
  # single-step builder was NOT, so the core read TWO SLOTS PAST THE END of a
  # 15-element vector. Nothing errored in either language. It stayed invisible
  # because `gamma_diff` defaulted to 0 and the out-of-bounds value was
  # multiplied by zero; ADOPTING gamma_diff = 0.25 is what exposed it, as a
  # ~0.07 GtC/yr parity break in the NPP-fed pools.
  p  <- ccx_default_params()
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)

  # 1. THE STRUCTURAL PROPERTY. Pin the builder's length to the declared layout,
  #    so the NEXT appended column cannot repeat this by being forgotten here.
  fa <- ccx_forcing_at(F, 1900)
  flat <- local({
    cl <- ccx_forcing_cum_luc(fa)
    c(fa$e_foss$NH, fa$e_foss$SH, fa$e_luc$NH, fa$e_luc$SH, fa$gmst, fa$enso,
      fa$c14_bomb, fa$c14_nuclear, fa$c14_cosmo, ccx_forcing_d13c_foss(fa),
      cl$NH, cl$SH, fa$sst_anom_NH, fa$sst_anom_SH, fa$sink_ocean,
      fa$aod_NH, fa$aod_SH)
  })
  expect_identical(length(flat), length(CCX_FORCING_COLS))

  # 2. PARITY AT NON-ZERO gamma_diff -- the configuration the bug lived in.
  #    Pinned at explicit values so this coverage does not move if the default
  #    ever moves, which is exactly how the bug survived.
  for (gd in c(0, 0.25, 0.97)) {
    p$gamma_diff <- gd
    for (yr in c(1800, 1900, 2000)) {
      fy <- ccx_forcing_at(F, yr)
      expect_equal(ccx_deriv(sp$y, yr, p, fy, sp$grid, sp$aux),
                   ccx_deriv_fast(sp$y, yr, p, fy, sp$grid, sp$aux),
                   tolerance = 1e-12)
    }
  }

  # 3. MUTATION TEST -- a guard that passes is not a guard that works. Drive the
  #    AOD to a value the record never reaches and confirm BOTH paths move
  #    TOGETHER and by a lot. Under the bug the C++ read a slot the R path never
  #    saw, so this is precisely what could not hold.
  p$gamma_diff <- 0.25
  fy <- ccx_forcing_at(F, 1900)
  loud <- fy; loud$aod_NH <- 1.0; loud$aod_SH <- 1.0
  dq <- ccx_deriv_fast(sp$y, 1900, p, fy,   sp$grid, sp$aux)
  dl <- ccx_deriv_fast(sp$y, 1900, p, loud, sp$grid, sp$aux)
  expect_gt(max(abs(dl - dq)), 1)                      # the core really sees it
  expect_equal(ccx_deriv(sp$y, 1900, p, loud, sp$grid, sp$aux), dl, tolerance = 1e-12)

  # 4. THE ABSENCE CONTRACT: a forcing with no AOD columns must equal aod = 0,
  #    not garbage, in both paths.
  none <- fy; none$aod_NH <- NULL; none$aod_SH <- NULL
  zero <- fy; zero$aod_NH <- 0;    zero$aod_SH <- 0
  expect_equal(ccx_deriv_fast(sp$y, 1900, p, none, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, 1900, p, zero, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv(sp$y, 1900, p, none, sp$grid, sp$aux),
               ccx_deriv(sp$y, 1900, p, zero, sp$grid, sp$aux), tolerance = 1e-12)
})
