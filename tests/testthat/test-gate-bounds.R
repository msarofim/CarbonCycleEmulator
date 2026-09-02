# =====================================================================
# test-gate-bounds.R -- MUTATION TESTS for the DESIGN gate bounds.
#
# WHY THIS FILE EXISTS. On 2026-09-02 the gate ledger found that gates 4 and 5
# printed tables and no verdict, so neither could fail, and that gate 7 judged a
# fitted stream three times more strictly than the objective that fitted it.
# Marcus ruled that all three get proper bounds. A BOUND THAT HAS NEVER BEEN
# BROKEN IS NOT A BOUND -- "a gate that passes is not a gate that works"
# ([[mutation_test_gates]]) -- so every one of them is exercised here in BOTH
# directions: it must FAIL when the thing it guards is broken, and PASS when it
# is not. A gate that can only ever fail is as uninformative as one that can only
# ever pass, and gates 4 and 5 both currently FAIL at every shipped arm, which is
# exactly the situation where the pass direction has to be demonstrated.
#
# ⚠ THESE MUTATE THE KERNEL'S OUTPUT, NOT THE MODEL. The bounds are functions of
# the kernel output, so that is the right surface to mutate: it tests the BOUND.
# Mutating the model tests the KERNEL, which was done separately for gate 7 (the
# beta_max walk, 2026-09-02: land 1.663 -> 6.697 monotone across beta_max x0.5 to
# x2.0). Both are needed and neither substitutes for the other.
# =====================================================================

skip_if_no_gates <- function() {
  f <- ccx_path("calibration", "lib_design_gates.R")
  skip_if_not(file.exists(f), "lib_design_gates.R not present")
  f
}

test_that("GATE 4's ordering fails a smoother model and passes a rougher one", {
  source(skip_if_no_gates(), local = TRUE)
  so <- stats::sd(DG_AF_OBS_DEC)
  # The bound is an ORDERING with no threshold, so the mutation is a scale on the
  # spread about its own mean -- which changes the variability and nothing else.
  spread <- function(f) {
    m <- mean(DG_AF_OBS_DEC); list(dec = m + f * (DG_AF_OBS_DEC - m))
  }
  expect_false(dg_gate4_verdict(spread(0.5))$pass)   # smoother than GCB -> FAIL
  expect_true( dg_gate4_verdict(spread(1.5))$pass)   # rougher  than GCB -> PASS
  # AT the observation it must pass: the claim is ">=", not ">".
  expect_true( dg_gate4_verdict(spread(1.0))$pass)
  expect_equal(dg_gate4_verdict(spread(1.0))$ratio, 1)
  expect_equal(dg_gate4_verdict(spread(1.0))$sd_obs, so)
})

test_that("GATE 5's derived sigma is positive, finite, and rests on stated draws", {
  source(skip_if_no_gates(), local = TRUE)
  sp <- dg_obs_gate5_spread()
  expect_true(all(is.finite(sp$sd)))
  expect_true(all(sp$sd > 0))
  # ⚠ THE DRAW COUNTS ARE PART OF THE CLAIM. The NH aggregate has 3 zones and the
  # SH 2, so leave-one-out gives 4 and 3 draws; the lag is a function of both, so
  # it gets the 12 combinations. If the zone definitions change, this must fail
  # rather than silently re-scale every gate-5 tolerance.
  expect_identical(unname(sp$n[["nh"]]), 4L)
  expect_identical(unname(sp$n[["sh"]]), 3L)
  expect_identical(unname(sp$n[["lag"]]), 12L)
  # And the hemispheric spreads must NOT be taken over the 12 combinations: that
  # repeats each value and biases the sd about 10 % low, making the gate stricter
  # than the data warrants. Guard the property rather than the number.
  expect_gt(sp$sd[["nh_t"]], 0.9 * stats::sd(vapply(sp$nh, function(x) x[["t"]],
                                                    numeric(1))) - 1e-12)
})

test_that("GATE 5 fails a shifted peak and an inverted ordering, and passes the truth", {
  source(skip_if_no_gates(), local = TRUE)
  ob <- dg_obs_gate5(); sp <- dg_obs_gate5_spread()
  # A synthetic gate-5 result built FROM the observation: the model that is
  # exactly right must pass, which is the direction a failing gate cannot show.
  mk <- function(dnh = 0, dsh = 0, vnh = ob$NH[["v"]], vsh = ob$SH[["v"]])
    list(pk = list(NH = c(t = ob$NH[["t"]] + dnh, v = vnh),
                   SH = c(t = ob$SH[["t"]] + dsh, v = vsh)),
         lag = (ob$SH[["t"]] + dsh) - (ob$NH[["t"]] + dnh))
  expect_true(dg_gate5_verdict(mk(), ob, sp)$pass)

  # push the NH peak out past the bound and it must fail, on the z and not the
  # ordering -- a mutation that trips the wrong clause is not a test of this one
  big <- (DG_G5_NSD + 1) * sp$sd[["nh_t"]]
  v <- dg_gate5_verdict(mk(dnh = big, dsh = big), ob, sp)
  expect_false(v$pass); expect_false(v$pass_z); expect_true(v$pass_ord)

  # ORDERING CLAUSE, which needs no sigma: put the SH peak BEFORE the NH one.
  # The bomb source was northern, so this is unphysical at any tolerance.
  v <- dg_gate5_verdict(mk(dsh = -2 * (ob$SH[["t"]] - ob$NH[["t"]])), ob, sp)
  expect_false(v$ord[["sh_after_nh"]]); expect_false(v$pass)

  # ... and make the SH peak the higher one, likewise unphysical.
  v <- dg_gate5_verdict(mk(vsh = ob$NH[["v"]] * 2), ob, sp)
  expect_false(v$ord[["nh_peak_higher"]]); expect_false(v$pass)
})

test_that("GATE 7 judges at the objective's sigmas, and can still fail", {
  source(skip_if_no_gates(), local = TRUE)
  # THE SIGMAS ARE THE OBJECTIVE'S, NOT THIS FILE'S. If R/likelihood.R changes
  # either one, this must fail rather than let the gate drift away from the fit.
  expect_equal(DG_G7_LAND_SD, LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE)
  expect_equal(DG_G7_OCEAN_SD, LIK_GCB_OCEAN_SD)
  # The three distributional gates share one strictness, ruled 2026-09-02.
  expect_identical(DG_G7_NSD, DG_Q_NSD)
  expect_identical(DG_G5_NSD, DG_Q_NSD)

  tgt <- list(land = 2.41, ocean = 3.20)
  ok  <- dg_gate7_verdict(list(land = tgt$land, ocean = tgt$ocean), tgt)
  expect_true(ok$pass); expect_equal(ok$z_land, 0); expect_equal(ok$z_ocean, 0)

  # break each half in turn, just past the bound
  bad_l <- dg_gate7_verdict(
    list(land = tgt$land + (DG_G7_NSD + 0.5) * DG_G7_LAND_SD, ocean = tgt$ocean), tgt)
  expect_false(bad_l$pass)
  bad_o <- dg_gate7_verdict(
    list(land = tgt$land, ocean = tgt$ocean - (DG_G7_NSD + 0.5) * DG_G7_OCEAN_SD), tgt)
  expect_false(bad_o$pass)

  # and the BARE-sigma readout, which every pre-2026-09-02 result used, must
  # still be reported and must be the stricter of the two
  expect_gt(abs(bad_l$z_land_bare), abs(bad_l$z_land))
})
