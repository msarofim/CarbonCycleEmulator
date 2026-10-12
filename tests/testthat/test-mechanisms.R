# =====================================================================
# Gate: every counterfactual switch does something, does the right thing, and
# does not quietly do more than it says.
#
# A switch that silently did nothing would look exactly like a switch that
# worked, in the app. Undergraduates would draw a conclusion from it. So each
# one is checked for (a) a measurable effect, and (b) the SIGN of that effect,
# because a switch pointing the wrong way teaches the opposite of the physics.
# =====================================================================

# file-level memo keyed on (off, years, scen) (review B4, 2026-09-12): the base
# run was made five times and every single-switch run at least twice
mech_memo <- new.env()
mech_run <- function(off = character(), years = c(1750, 2100), scen = "ssp245") {
  k <- paste(c("off:", off, "yrs:", years, scen), collapse = "|")
  if (is.null(mech_memo[[k]])) mech_memo[[k]] <- mech_run_raw(off, years, scen)
  mech_memo[[k]]
}
mech_run_raw <- function(off = character(), years = c(1750, 2100), scen = "ssp245") {
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  F0 <- suppressWarnings(ccx_build_forcing(scen, years, prod_c14 = 0))
  m <- ccx_apply_mechanisms(p, F0, off)
  sp <- ccx_spinup(m$p)
  F <- m$F; F$c14_cosmo <- sp$prod_c14
  ccx_run_fast(sp, F)$out
}

# THE WIRING FLOOR, ppm. This gate asks "is the switch connected", so the bar
# must separate a real effect from numerical noise -- NOT rank the mechanisms by
# size. It is read against max|dCO2| over the whole series, because ONE of the
# six is oscillatory and an endpoint reads its phase rather than its amplitude.
#
# DERIVED, measured 2026-08-18 (notes/diag_2026-08-18_test_failures.md S3), as
# max|dCO2| vs base over 1750-2100, ssp245:
#   emissions 225.341 | fertilisation 201.185 | ocean_sink 116.211
#   revelle    34.107 | warming_feedback 18.140 | enso 0.537 (at 2032)
# The smallest true effect is ENSO's 0.537. MECH_WIRED_MIN sits ~500x below it
# and ~5 orders above the integrator's round-off in ppm, so a disconnected
# switch cannot clear it and no connected one can fail it.
#
# THE ENDPOINT BAR THIS REPLACED (0.5 ppm at 2100) was the wrong statistic, not
# a wrong number: ENSO reads 0.300 at 2100 purely because of where in its cycle
# 2100 falls. Its max, 0.537, was above the old bar all along. The five monotone
# mechanisms are unaffected -- they clear MECH_WIRED_MIN by 4-8 orders.
MECH_WIRED_MIN <- 1e-3

test_that("every switch is wired up and changes the answer", {
  skip_if_no_cpp()
  base <- mech_run()
  for (nm in names(CCX_MECHANISMS)) {
    alt <- mech_run(nm)
    expect_identical(nrow(alt), nrow(base),
              label = sprintf("switch '%s' must not change the time grid", nm))
    expect_gt(max(abs(alt$co2_NH - base$co2_NH)), MECH_WIRED_MIN,
              label = sprintf("switch '%s' must move CO2 somewhere in 1750-2100", nm))
  }
})

test_that("the emissions switch removes the rise, and dwarfs the warming feedback", {
  # THE TAB-6 COMPARISON, pinned. The argument that temperature drives the rise
  # is answered by two counterfactuals side by side, and it only works if BOTH
  # exist: turn the carbon cycle's response to warming off and the trend barely
  # moves; turn EMISSIONS off and it disappears. If these two ever came within
  # a factor of a few of each other, the lesson would be wrong.
  skip_if_no_cpp()
  hist <- c(1750, 2024)
  co2 <- function(off) {
    o <- mech_run(off, years = hist, scen = "historical")
    (o$co2_NH[nrow(o)] + o$co2_SH[nrow(o)]) / 2
  }
  base <- co2(character())
  pi_co2 <- ccx_const("CO2_PI_PPM")
  no_emis <- co2("emissions")
  no_warm <- co2("warming_feedback")
  expect_lt(no_emis, base - 100)                       # the rise goes
  expect_lt(abs(no_emis - pi_co2), 20)                 # back near preindustrial
  expect_lt(abs(no_warm - base), 30)                   # the trend barely moves
  expect_gt(abs(no_emis - base), 5 * abs(no_warm - base))
})

test_that("each switch moves CO2 in the physically correct direction", {
  skip_if_no_cpp()
  base <- mech_run()
  i <- nrow(base)
  co2 <- function(off) mech_run(off)$co2_NH[i]

  # No land sink -> carbon that plants would have taken stays airborne -> MORE
  expect_gt(co2("fertilisation"), base$co2_NH[i])
  # No ocean sink -> same argument
  expect_gt(co2("ocean_sink"), base$co2_NH[i])
  # No warming feedback -> the warming-driven RELEASE of carbon is removed -> LESS
  expect_lt(co2("warming_feedback"), base$co2_NH[i])
  # Frozen buffer -> ocean never saturates -> keeps absorbing -> LESS
  expect_lt(co2("revelle"), base$co2_NH[i])

  # NOT asserted: that switching off the ocean raises CO2 more than switching
  # off the land. Measured at defaults it is the other way (126 vs 184 ppm), and
  # neither ordering is a law -- removing one sink raises CO2, which partly
  # INCREASES the other, so these counterfactual differences are not sink sizes.
  # The sink sizes themselves are measured in the test below.
})

test_that("both sinks take up carbon, and the stocks say how much", {
  skip_if_no_cpp()
  # The honest version of "which sink is bigger": read the stocks, do not infer
  # it from a counterfactual difference.
  base <- mech_run()
  i <- nrow(base)
  ocean_gain <- base$ocean_C[i] - base$ocean_C[1]
  land_gain  <- base$land_C[i]  - base$land_C[1]
  expect_gt(ocean_gain, 0)
  expect_gt(land_gain, 0)
  # both should be a substantial fraction of cumulative emissions, neither
  # negligible nor larger than the total ever emitted
  expect_gt(ocean_gain, 100)
  expect_gt(land_gain, 50)
})

test_that("switching off the ocean really removes the ocean sink", {
  skip_if_no_cpp()
  base <- mech_run(); alt <- mech_run("ocean_sink")
  i <- nrow(base)
  gain_base <- base$ocean_C[i] - base$ocean_C[1]
  gain_alt  <- alt$ocean_C[i]  - alt$ocean_C[1]
  expect_gt(gain_base, 100)                   # the ocean normally takes a lot
  expect_lt(abs(gain_alt), 0.02 * gain_base)  # and essentially none with it off
})

test_that("ENSO affects variability but not the trend", {
  skip_if_no_cpp()
  base <- mech_run(); alt <- mech_run("enso")
  k <- base$t >= 1960 & base$t <= 2020
  # detrended scatter must fall
  dt <- function(x, tt) stats::residuals(stats::lm(x ~ poly(tt, 3)))
  expect_lt(stats::sd(dt(alt$co2_NH[k], alt$t[k])),
            stats::sd(dt(base$co2_NH[k], base$t[k])))
  # but the endpoint should barely move: ENSO's annual mean is near zero
  i <- nrow(base)
  expect_lt(abs(alt$co2_NH[i] - base$co2_NH[i]), 15)
})

test_that("the warming switch removes only the carbon cycle's response", {
  skip_if_no_cpp()
  # It must act on q10 and sst_scale (and npp_tsens). Until 2026-10-02 it also left the
  # temperature forcing untouched; since then it zeroes it too (see the re-pin below), and
  # the full run is what shows a warming world.
  p <- ccx_default_params()
  F <- suppressWarnings(ccx_build_forcing("ssp245", c(1750, 2100), prod_c14 = 0))
  m <- ccx_apply_mechanisms(p, F, "warming_feedback")
  expect_equal(m$p$q10, 1)
  expect_equal(m$p$sst_scale, 0)
  expect_equal(m$p$npp_tsens, 0)
  # Re-pinned 2026-10-02 (approved, with "Zero the index"): the temperature INPUT is zeroed
  # as well, so the driver chart draws what the carbon cycle effectively saw. The world still
  # warms in the full run; that this changes no number is the next test's job (the
  # canonical's run is BLIND to the temperature record under this switch).
  expect_true(all(m$F$gmst == 0))
})

test_that("under the warming switch, the CANONICAL's run is blind to the temperature record", {
  # THE PROPERTY, not a parameter list (2026-10-01). The test above checks the
  # names the switch zeroes, and it runs at DEFAULTS, where every temperature
  # path a refit can open (npp_tsens, from the D2 canonical) is already 0, so it
  # could not see the switch leave one live. Here the canonical runs twice under
  # the switch, once with the whole climate record (gmst + both observed-SST
  # columns) 1 K warmer, and the carbon state must not move AT ALL.
  # MUTATION-TESTED 2026-10-01: without `p$npp_tsens <- 0` in the switch,
  # hilda33d moves CO2 by 1.39 ppm here and this fails; with it, the difference
  # is exactly 0.
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  p <- ccx_overlay_par(bp, md$par_mode)
  sp_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
  F0 <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
          bomb_total_kmol = md$par_mode$bomb_total, luc_scale = md$par_mode$luc_scale,
          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
  clim <- grep("^gmst$|^sst_anom_", names(F0), value = TRUE)
  expect_true("gmst" %in% clim)
  run <- function(F) {
    m <- ccx_apply_mechanisms(p, F, "warming_feedback")
    sp <- sp_fn(m$p); FF <- m$F; FF$c14_cosmo <- sp$prod_c14
    ccx_run_fast(sp, FF)$out
  }
  F1 <- F0; for (cc in clim) F1[[cc]] <- F1[[cc]] + 1
  a <- run(F0); b <- run(F1)
  for (cc in c("co2_NH", "co2_SH", "land_C", "ocean_C"))
    expect_identical(b[[cc]], a[[cc]],
                     label = sprintf("%s under the warming switch with the climate record +1 K", cc))
})

test_that("the warming caveat's 'third, smaller effect' (the mixing slowdown) holds at the CANONICAL", {
  # THE COPY MAKES A MEASURED CLAIM (2026-10-06, Marcus: "Caveat sentence (Recommended)"): the
  # switch "also removes a third, smaller effect", the stratification feedback (DESIGN §3.4a S).
  # Smaller than the two the blurb names: soil respiration (q10) and seawater (SST, both columns).
  # An ORDERING between measured quantities, on the app's estimator (CO2 at the last row of the
  # historical run), each path knocked out alone. A refit that made the mixing path the larger
  # one would make the copy false in silence; this is what stops it.
  # Measured at hilda33p (calibration/diag_warming_switch_split.R): mixing 0.151, soil 0.634,
  # seawater 4.903 ppm (this test's estimator reproduces the app's 426.120 exactly). MUTATION-TESTED
  # 2026-10-06: with mix_strat_s x 10 at the mode the mixing path is 1.253 ppm, past soil's 0.638,
  # and this FAILS; at x 3 it is 0.433 and still passes (CHANGELOG 10-06 c).
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  p <- ccx_overlay_par(bp, md$par_mode)
  skip_if(!isTRUE(p$mix_strat_s > 0), "the canonical carries no stratification feedback")
  sp_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
  F0 <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
          bomb_total_kmol = md$par_mode$bomb_total, luc_scale = md$par_mode$luc_scale,
          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
  today <- function(set) {
    pp <- p; for (n in names(set)) pp[[n]] <- set[[n]]
    sp <- sp_fn(pp); FF <- F0; FF$c14_cosmo <- sp$prod_c14
    o <- ccx_run_fast(sp, FF)$out; n <- nrow(o)
    (o$co2_NH[n] + o$co2_SH[n]) / 2
  }
  full <- today(list())
  d <- c(mixing   = full - today(list(mix_strat_s = 0)),
         soil     = full - today(list(q10 = 1)),
         seawater = full - today(list(sst_scale = 0, sst_obs = 0)))
  expect_gt(d[["mixing"]], 0)   # the feedback raises CO2: knocking it out lowers it
  expect_lt(d[["mixing"]], d[["soil"]])
  expect_lt(d[["mixing"]], d[["seawater"]])
})

test_that("under the emissions switch, the CANONICAL's carbon is blind to every human carbon input", {
  # The emissions twin of the test above (2026-10-01). INVENTORY first: every
  # forcing column is either a HUMAN CARBON INPUT, which "nature alone" must
  # remove, or something else. A new column is a decision about this switch,
  # and this is where it gets made (the same device as test-so-entrainment.R's
  # P0.3 for ccx_hold_climate()). Bomb and nuclear 14C are human-made but move
  # no carbon, and the isotope panels do not respond to switches (09-24 #19).
  # MUTATION-TESTED 2026-10-01: with ndep_NH/ndep_SH dropped from the switch,
  # hilda33d's state moves and this fails.
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  p <- ccx_overlay_par(bp, md$par_mode)
  sp_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
  F0 <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
          bomb_total_kmol = md$par_mode$bomb_total, luc_scale = md$par_mode$luc_scale,
          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
  human_carbon <- c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
                    "cum_luc_NH", "cum_luc_SH", "ndep_NH", "ndep_SH")
  # nuc_share_NH (2026-10-12, label hilda_csl3v0kaidgbemwtc; flagged to Marcus): OTHER -- the
  # hemispheric split of the nuclear 14C source, which moves no carbon (as c14_nuclear itself).
  other <- c("t", "year", "month", "gmst", "enso", "sst_anom_NH", "sst_anom_SH",
             "d13c_foss", "c14_bomb", "c14_nuclear", "c14_cosmo", "sink_ocean",
             "aod_NH", "aod_SH", "nuc_share_NH")
  expect_setequal(names(F0), c(human_carbon, other))
  # the deposition is live at the canonical, or this test has no power on it
  expect_gt(p$ndep_ret, 0); expect_gt(max(F0$ndep_NH), 0)
  run <- function(F) {
    m <- ccx_apply_mechanisms(p, F, "emissions")
    for (cc in human_carbon) expect_true(all(m$F[[cc]] == 0), label = sprintf("%s zeroed", cc))
    sp <- sp_fn(m$p); FF <- m$F; FF$c14_cosmo <- sp$prod_c14
    ccx_run_fast(sp, FF)$out
  }
  F1 <- F0; for (cc in human_carbon) F1[[cc]] <- 2 * F1[[cc]] + 1
  a <- run(F0); b <- run(F1)
  for (cc in c("co2_NH", "co2_SH", "land_C", "ocean_C"))
    expect_identical(b[[cc]], a[[cc]],
                     label = sprintf("%s under the emissions switch with every human carbon input doubled", cc))
})

test_that("switches compose, and unknown names are refused", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  F <- suppressWarnings(ccx_build_forcing("ssp245", c(1750, 2100), prod_c14 = 0))
  m <- ccx_apply_mechanisms(p, F, c("fertilisation", "revelle"))
  expect_equal(m$p$beta, 0)
  expect_equal(m$p$revelle_frozen, 1)
  expect_length(m$caveats, 2)
  expect_error(ccx_apply_mechanisms(p, F, "no_such_switch"), "unknown mechanism")
})

test_that("every switch carries user-facing copy", {
  for (nm in names(CCX_MECHANISMS)) {
    m <- CCX_MECHANISMS[[nm]]
    for (fld in c("label", "blurb", "caveat")) {
      expect_true(is.character(m[[fld]]) && nzchar(m[[fld]]),
                  info = sprintf("%s$%s", nm, fld))
    }
  }
  ch <- ccx_mechanism_choices()
  expect_equal(length(ch), length(CCX_MECHANISMS))
  expect_true(all(nzchar(names(ch))))
})

test_that("the ocean switch is RUN-ONLY: the combinations that crashed spin up and run at the CANONICAL", {
  # Marcus 2026-10-11 (CarboTopecomments.10.11.26): "I get an error when selecting warming, ENSO,
  # volcanoes, and ocean sink." With the ocean switch applied IN THE SPIN-UP, the periodic carbon
  # solve did not converge and the 13C solve was singular: 16 of 127 combinations crashed, every one
  # with ocean_sink plus warming_feedback or revelle (R/mechanisms.R, CCX_MECH_RUN_ONLY). The fix spins
  # up with the ocean open and closes it for the run (ccx_mechanism_spinup(), which the app calls).
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  p <- ccx_overlay_par(bp, md$par_mode)
  sp_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
  F0 <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
          bomb_total_kmol = md$par_mode$bomb_total, luc_scale = md$par_mode$luc_scale,
          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
  expect_identical(CCX_MECH_RUN_ONLY, "ocean_sink")
  # the reported combination, and the two minimal pairs the 127-combination sweep found
  for (off in list(c("warming_feedback", "enso", "volcanic", "ocean_sink"),
                   c("warming_feedback", "ocean_sink"), c("ocean_sink", "revelle"))) {
    ms <- ccx_mechanism_spinup(p, F0, off, sp_fn)
    expect_identical(ms$spin$params, ms$m$p)              # the RUN carries every switch ...
    expect_identical(ms$spin$params$k_w, OCEAN_OFF_K_W)   # ... the ocean's included
    FF <- ms$m$F; FF$c14_cosmo <- ms$spin$prod_c14
    out <- ccx_run_fast(ms$spin, FF)$out
    expect_true(all(is.finite(out$co2_NH)) && all(is.finite(out$co2_SH)), label = paste(off, collapse = "+"))
  }
  # the start state is the OPEN-ocean one: exactly the spin-up without the ocean switch
  a <- ccx_mechanism_spinup(p, F0, c("warming_feedback", "ocean_sink"), sp_fn)$spin
  b <- sp_fn(ccx_apply_mechanisms(p, F0, "warming_feedback")$p)
  expect_identical(a$y, b$y)
  expect_identical(a$prod_c14, b$prod_c14)
  # POWER: the old construction (the switch inside the spin-up) still fails on the minimal pair, so
  # the assertions above are not passing vacuously. If a model change ever makes this converge, the
  # test has lost its power, not the app its fix -- re-measure before deleting it.
  expect_error(suppressWarnings(sp_fn(ccx_apply_mechanisms(p, F0, c("warming_feedback", "ocean_sink"))$p)),
               "singular")
})
