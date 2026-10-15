# =====================================================================
# The SOUTHERN-OCEAN ENTRAINMENT CHANNEL (2026-08-27g, version 4a).
#
# This file IS prereg `notes/prereg_2026-08-27g_so_entrainment_channel.md`
# P0 -- the METHOD CONTROL, which is scored FIRST and whose failure means no
# result from the channel is read at all. Its three clauses:
#
#   1. at zero amplitude the model is the shipped one BIT FOR BIT, both cores;
#   2. R and C++ agree with the channel ON, at test-parity.R's own tolerance;
#   3. seas_drivers = 0 kills it, like every other seasonal driver.
#
# Clause 3 is not decoration. `ccx_hold_climate()` CANNOT hold this channel --
# it freezes forcing COLUMNS, and this cycle is generated from a PARAMETER and
# `t`, exactly as the seasonal SST cycle is. That gap cost a day in 27c and is
# asserted here so the correct control (seas_drivers) is the one that is used.
# =====================================================================

ent_p <- local({ p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); p })

# ⛔ THE OFF-STATE IS NAMED, NOT INHERITED (2026-09-04). Until the `ent26`
# adoption `ccx_default_params()$ent_seas_amp_SH` was 0, so `ent_p` WAS the
# off-state and every "channel off" baseline in this file got it for free. The
# adoption flipped that default to the derived prior center and FIFTEEN
# assertions here failed at once -- none of them because the model changed: the
# identity they guard (absent == zero) was measured intact, bit for bit, in both
# cores and all five columns.
# ⚠ AND TWO ASSERTIONS DID NOT FAIL, WHICH IS THE WORSE HALF. P0.2's mutation
# guard and the rectification bound below both used `ent_p` as their OFF
# baseline; with the default at 10.95 they silently became ON-vs-ON comparisons
# and kept passing while measuring something smaller than they claimed. A
# control that depends on a DEFAULT'S VALUE is not a control -- so the off-state
# is now written down, and nothing in this file reads the default to find it.
ent_p_off <- local({ p <- ent_p; p$ent_seas_amp_SH <- 0; p })

# Twins of test-conservation.R's fixtures, which are local to that file. A
# closed system (no emissions, no 14C production) and a state deliberately OUT
# of equilibrium -- conservation must hold out of balance too.
ent_closed_forcing <- function() {
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
}

test_ent_state <- function(p = ccx_default_params()) {
  aux <- ccx_prepare(p); y <- ccx_new_state(); grid <- aux$grid
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- 300; y[i$leaf, "C"] <- 30; y[i$wood, "C"] <- 220
    y[i$soil_fast, "C"] <- 100; y[i$soil_slow, "C"] <- 600
    y[i$ml, "C"] <- 400
    y[i$oc, "C"] <- 1500 * grid$dz[-1] / sum(grid$dz[-1])
  }
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB")
  y[, "C14"] <- y[, "C"] * 1.0
  list(y = y, p = p, aux = aux, grid = grid)
}

ENT_P01_COLS <- c("co2_NH", "co2_SH", "d13c_SH", "ocean_C", "land_C")

# 20 umol/kg: inside the band the pre-check derives, and large enough that a
# dropped term or a sign error could not hide under the parity tolerance.
# ⚠ Named once, because three tests use it as "the channel ON".
ENT_P02_AMP <- 20

test_that("P0.1 -- at zero amplitude the channel is absent, bit for bit", {
  # THE CLAIM, and it is exactly one: `NULL` is how every pre-2026-08-27g
  # parameter list arrives; 0 is how a current one asks for the channel off.
  # They must be the SAME MODEL, or the absence contract is a silent model
  # change for every stored mode in the repo.
  # ⚠ The default run is NOT the reference any more. While the default was 0 it
  # was a third spelling of the same state, so two of this test's three
  # comparisons were one comparison written twice.
  p_absent <- ent_p_off; p_absent$ent_seas_amp_SH <- NULL
  sp <- ccx_spinup(ent_p_off)
  F  <- ccx_build_forcing("historical", c(1960, 1990), prod_c14 = sp$prod_c14)
  b  <- ccx_run(ccx_spinup(p_absent), F)$out
  cc <- ccx_run(sp, F)$out
  for (col in ENT_P01_COLS) expect_identical(b[[col]], cc[[col]])

  # MUTATION GUARD, so this cannot pass by the channel being dead everywhere:
  # an explicitly ON state must DIFFER from the off-state it was just compared
  # against. Without it, deleting the entrainment term entirely turns P0.1 green.
  p_on <- ent_p_off; p_on$ent_seas_amp_SH <- ENT_P02_AMP
  on   <- ccx_run(ccx_spinup(p_on), F)$out
  expect_gt(max(abs(on$co2_SH - cc$co2_SH)), 1e-6)
})

test_that("P0.1 -- and bit for bit in the C++ core too", {
  skip_if_no_cpp()
  p_absent <- ent_p_off; p_absent$ent_seas_amp_SH <- NULL
  sp <- ccx_spinup(ent_p_off)
  F  <- ccx_build_forcing("historical", c(1960, 1990), prod_c14 = sp$prod_c14)
  b  <- ccx_run_fast(ccx_spinup(p_absent), F)$out
  cc <- ccx_run_fast(sp, F)$out
  for (col in ENT_P01_COLS) expect_identical(b[[col]], cc[[col]])
})

test_that("P0.2 -- R and C++ are the same model with the channel ON", {
  skip_if_no_cpp()
  p <- ent_p_off; p$ent_seas_amp_SH <- ENT_P02_AMP
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1960, 1990), prod_c14 = sp$prod_c14)
  rR <- ccx_run(sp, F); rC <- ccx_run_fast(sp, F)
  expect_lt(max(abs(rR$out$co2_SH - rC$out$co2_SH)) / max(abs(rR$out$co2_SH)), 1e-13)
  expect_lt(max(abs(rR$out$co2_NH - rC$out$co2_NH)) / max(abs(rR$out$co2_NH)), 1e-13)
  expect_lt(max(abs(rR$out$d13c_SH - rC$out$d13c_SH)), 1e-9)
  expect_lt(max(abs(rR$out$ocean_C - rC$out$ocean_C)) / max(abs(rR$out$ocean_C)), 1e-13)
})

test_that("P0.2 -- and the channel is not a no-op in EITHER core", {
  # A parity test between two cores that both ignore the parameter would pass.
  # MUTATION GUARD: this is the assertion that makes P0.2 mean something.
  # ⚠ `ent_p_off`, NOT `ent_p`: with the post-adoption default this compared
  # 10.95 against 20 -- two ON states -- and still passed, measuring a fraction
  # of what it claims to.
  sp0 <- ccx_spinup(ent_p_off)
  F   <- ccx_build_forcing("historical", c(1960, 1990), prod_c14 = sp0$prod_c14)
  p   <- ent_p_off; p$ent_seas_amp_SH <- ENT_P02_AMP
  sp  <- ccx_spinup(p)
  expect_gt(max(abs(ccx_run(sp, F)$out$co2_SH - ccx_run(sp0, F)$out$co2_SH)), 1e-6)
  skip_if_no_cpp()
  expect_gt(max(abs(ccx_run_fast(sp, F)$out$co2_SH -
                    ccx_run_fast(sp0, F)$out$co2_SH)), 1e-6)
})

test_that("P0.3 -- seas_drivers = 0 kills the channel, hold_climate does NOT", {
  F0 <- NULL
  run <- function(amp, drivers) {
    p <- ent_p_off; p$ent_seas_amp_SH <- amp; p$seas_drivers <- drivers
    sp <- ccx_spinup(p)
    if (is.null(F0)) F0 <<- ccx_build_forcing("historical", c(1960, 1990),
                                              prod_c14 = sp$prod_c14)
    ccx_run(sp, F0)$out
  }
  # under the aseasonal switch the amplitude is inert
  expect_identical(run(20, 0)$co2_SH, run(0, 0)$co2_SH)
  # and under seas_drivers = 1 it is not -- so the switch is the control, and
  # the test above is not passing because the channel is dead everywhere
  expect_gt(max(abs(run(20, 1)$co2_SH - run(0, 1)$co2_SH)), 1e-6)
})

test_that("P0.3 -- ccx_hold_climate() holds every climate FORCING COLUMN", {
  # The audit owed by handoff 27g sec.6. ccx_hold_climate() is COMPLETE over
  # the forcing columns that carry climate -- this asserts that, and fails if a
  # new climate column is ever added to ccx_build_forcing() without being
  # listed there. What it CANNOT hold is the seasonal cycle generated inside
  # ccx_deriv() from parameters and `t` (land T, NPP, SST, and now
  # entrainment); those are gated by seas_drivers, tested above, and that
  # division is the whole content of the gap found in 27c.
  sp <- ccx_spinup(ent_p)
  F  <- ccx_build_forcing("historical", c(1900, 1990), prod_c14 = sp$prod_c14)
  climate_cols <- c("gmst", "enso", "sst_anom_NH", "sst_anom_SH")
  H <- ccx_hold_climate(F, i = 1L)
  for (cc in climate_cols) {
    expect_true(!is.null(H[[cc]]), info = cc)
    expect_length(unique(H[[cc]]), 1L)
  }
  # INVENTORY GATE: every other column of a built forcing is an emission, an
  # isotope source, a time axis or the artificial-sink instrument -- none of
  # them climate. A new column outside this list is a DECISION about whether
  # ccx_hold_climate() should freeze it, and this is where it gets made.
  # aod_NH/aod_SH: NON-CLIMATE (Marcus 2026-08-29). The model's ONLY AOD pathway
  # is diffuse light -> NPP; the volcanic TEMPERATURE effect is already implicit
  # in the observed `gmst` this function holds, so AOD is a radiative driver and
  # holding gmst is what holds the volcanic climate signal. ⚠ The consequence is
  # that "climate held" does NOT imply "volcanically quiet" once gamma_diff != 0
  # -- see the note in ccx_hold_climate().
  # ndep_NH/ndep_SH: NON-CLIMATE (decided 2026-09-30, D2 (a); flagged to Marcus).
  # N deposition is an EMISSIONS-driven chemical input (NOx + NH3), like the CO2
  # emissions this list already holds, not a climate state; so a held-climate run
  # keeps it moving with its scenario. Same consequence as AOD: once ndep_ret != 0,
  # "climate held" does NOT mean "deposition held".
  # nuc_share_NH: NON-CLIMATE (decided 2026-10-12, label hilda_csl3v0kaidgbemwtc; flagged to Marcus).
  # It is the hemispheric SPLIT of the industrial 14C source (c14_nuclear, already listed here), a
  # property of where the reactors are, not a climate state.
  non_climate <- c("t", "year", "month", "e_foss_NH", "e_foss_SH",
                   "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH",
                   "d13c_foss", "c14_bomb", "c14_nuclear", "c14_cosmo",
                   "sink_ocean", "aod_NH", "aod_SH", "ndep_NH", "ndep_SH", "nuc_share_NH")
  expect_setequal(names(F), c(climate_cols, non_climate))
})

test_that("the entrainment channel is CONSERVATIVE, and rectifies no more than
           the seasonal SST term the model already accepts", {
  # TWO separate claims, and they are not the same claim.
  #
  # (1) CONSERVATION. The channel perturbs the DIC that enters the pCO2
  # calculation, so it changes a FLUX -- and every flux in ccx_deriv() goes
  # through add_flux() and is conservative by construction. Asserted on the
  # repo's own identity, ccx_total() in a CLOSED system, exactly as
  # test-conservation.R does it. (An out-columns identity is the wrong
  # instrument here: ocean_C + land_C + atm_C omits the wood/product pool.)
  s <- test_ent_state()
  s$p <- ccx_set_enso(s$p, list(gamma_enso = 0)); s$p$ent_seas_amp_SH <- 20
  y <- s$y; tot0 <- ccx_total(y); t <- 1900
  for (m in seq_len(12 * 40)) {
    y <- ccx_step_rk4(y, t, 1 / 12, s$p, ent_closed_forcing(), s$grid, s$aux)
    t <- t + 1 / 12
  }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
  expect_lt(abs(ccx_total(y, "C13") / ccx_total(s$y, "C13") - 1), 1e-10)

  # (2) RECTIFICATION. The driver is zero-mean; the response is not, because
  # carbonate chemistry is nonlinear in DIC. That is ACCEPTED AS PHYSICS -- the
  # same call already made for the seasonal SST term and the fertilization
  # rectifier -- so this BOUNDS it rather than denying it, against the SST
  # term's own rectification measured in the same run. Both are second order in
  # their driver amplitude through the same nonlinearity, which is why that is
  # the right comparison and not a tolerance picked to pass.
  # ⚠ THE BASELINE MUST BE THE OFF STATE. With the post-adoption default this
  # read `base` at ent = 10.95, so `d_ent` measured the step 10.95 -> 20 rather
  # than the channel's own rectification -- a bound quietly loosened by a factor
  # it never declared, and it kept passing.
  sp0  <- ccx_spinup(ent_p_off)
  F    <- ccx_build_forcing("historical", c(1960, 1990), prod_c14 = sp0$prod_c14)
  base <- ccx_run(sp0, F)$out
  p_e  <- ent_p_off; p_e$ent_seas_amp_SH <- ENT_P02_AMP
  ent  <- ccx_run(ccx_spinup(p_e), F)$out
  p_s  <- ent_p_off; p_s$sst_seas_amp_SH <- 0
  sst  <- ccx_run(ccx_spinup(p_s), F)$out
  d_ent <- abs(tail(ent$ocean_C, 1) - tail(base$ocean_C, 1))
  d_sst <- abs(tail(sst$ocean_C, 1) - tail(base$ocean_C, 1))
  expect_lt(d_ent, 10 * max(d_sst, 1e-6))
})
