# =====================================================================
# THE TAGGED PULSE (R/c14_tag.R) -- 2026-10-12.
#
# Marcus 2026-10-12: a pulse "for a tracer to show how quickly the original carbon moves into
# different reservoirs (as versus the pulse)"; the form RULED "Side by side in pulse lab
# (Recommended)". The tag rides on the model's own 14C, which is an exact passive tracer.
#
# WHAT IS ASSERTED, and where each threshold comes from:
#   * PASSIVE: tagging changes no carbon and no climate -- IDENTITY (bit-for-bit).
#   * A ZERO TAG is the untagged run -- IDENTITY.
#   * PLACEMENT: each month's tag lands in each hemisphere exactly as the pulse's own carbon
#     does -- an identity of the 2x2 solve, at float tolerance.
#   * CONSERVATION with decay undone: the residual is the undo's own second-order term,
#     E[exp(lambda (s - s_mid))] - 1 <= lambda^2 var(s) / 2 <= lambda^2 Delta^2 / 8 for a release
#     inside one year of width Delta. A LAW, not a tolerance chosen to pass.
#   * LINEARITY: half the tagged carbon gives the same fractions -- float tolerance.
#   * THE LESSON is an ORDERING between two measured runs (tag air < perturbation air), never a
#     typed share.
# =====================================================================
skip_if_no_cpp()
skip_if_no_climate()
source(ccx_path("calibration", "lib_design_gates.R"))

TAG_TEST_SCEN  <- "vvM"                    # the pulse lab's default background (APP_SCENARIO_BG)
TAG_TEST_YEARS <- c(1750, 2150)            # short of 2300 to keep the file fast; the identities do not depend on it
TAG_TEST_PULSE <- c(year = 2050, gtc = 100)
TAG_TEST_LATER <- c(20, 50, 100)           # yr after the release at which the ordering is read
TAG_TEST_DELTA <- 1                        # yr: the release is spread over ONE calendar year
.lam <- ccx_const("LAMBDA_C14")
TAG_TEST_CLOSURE_BOUND <- .lam^2 * TAG_TEST_DELTA^2 / 8   # the undo's second-order term, max over any release shape

.v    <- dg_vector(CCX_MODE_CANONICAL)
.spin <- dg_spinup(.v)
.em_scen <- ccx_scenario_emissions(TAG_TEST_SCEN)
.yy <- seq(TAG_TEST_YEARS[1], TAG_TEST_YEARS[2])
# ANNUAL grid first (DESIGN §7b trap 1: a decadal knot would deliver ~10x the pulse)
.base_em <- data.frame(year = .yy,
                       fossil_GtC = stats::approx(.em_scen$year, .em_scen$fossil_GtC, xout = .yy, rule = 2)$y,
                       luc_GtC    = stats::approx(.em_scen$year, .em_scen$luc_GtC,    xout = .yy, rule = 2)$y)
.with_pulse <- function(em, gtc) { em$fossil_GtC[em$year == TAG_TEST_PULSE[["year"]]] <-
  em$fossil_GtC[em$year == TAG_TEST_PULSE[["year"]]] + gtc; em }
.pulse_em <- .with_pulse(.base_em, TAG_TEST_PULSE[["gtc"]])
.run <- function(em, tag_base = NULL)
  ccx_run_coupled(.spin, TAG_TEST_SCEN, TAG_TEST_YEARS, emissions = em,
                  bomb_total_kmol = .v$bomb_total, luc_scale = .v$luc_scale,
                  interp_method = "constant", c14_tag_base = tag_base)
.base   <- .run(.base_em)
.pulse  <- .run(.pulse_em)
.tagged <- .run(.pulse_em, tag_base = .base_em)
.C14_COLS <- c("atm_C14", "land_C14", "ocean_C14", "d14c_NH", "d14c_SH")

test_that("the tag is PASSIVE: the tagged run's carbon and climate are the pulse run's, bit for bit", {
  carbon <- setdiff(names(.pulse$out), .C14_COLS)
  expect_identical(.tagged$out[carbon], .pulse$out[carbon])
  expect_identical(.tagged$climate, .pulse$climate)
  # and the 14C columns DO differ, or nothing was tagged
  expect_false(identical(.tagged$out$atm_C14, .pulse$out$atm_C14))
})

test_that("a ZERO tag is the untagged run, bit for bit, and says so", {
  z <- .run(.pulse_em, tag_base = .pulse_em)
  expect_identical(z$out, .pulse$out)
  expect_identical(z$tag$gtc, 0)
  expect_null(.pulse$tag)                       # no tag asked for, none returned
})

test_that("the tag IS the pulse: its mass, and its release inside the release year", {
  expect_equal(.tagged$tag$gtc, TAG_TEST_PULSE[["gtc"]], tolerance = 1e-12)
  expect_gte(.tagged$tag$s_mid, TAG_TEST_PULSE[["year"]])
  expect_lt(.tagged$tag$s_mid, TAG_TEST_PULSE[["year"]] + TAG_TEST_DELTA)
})

test_that("PLACEMENT: every month's tag lands in each hemisphere exactly as the pulse's carbon does", {
  # synthetic months, including NH shares OUTSIDE [0.90, 0.95], where one column's rate goes negative
  n <- 24; tt <- 2050 + (seq_len(n) - 0.5) / 12
  Fb <- data.frame(t = tt, e_foss_NH = 9, e_foss_SH = 1, e_luc_NH = 0.5, e_luc_SH = 0.5, c14_bomb = 0, c14_nuclear = 0)
  F  <- Fb; F$e_foss_NH <- F$e_foss_NH + c(rep(c(80, 99, 50), 4), rep(0, 12))
  F$e_foss_SH <- F$e_foss_SH + c(rep(c(20, 1, 50), 4), rep(0, 12))
  r <- ccx_c14_tag_rates(F, Fb, .spin$aux)
  k <- .spin$aux$mol_per_GtC * ccx_const("R14_STD")
  sb <- .spin$aux$bomb_share_NH; sn <- .spin$aux$nuc_share_NH
  expect_equal(r$bomb * sb + r$nuclear * sn,             (F$e_foss_NH - Fb$e_foss_NH) * k, tolerance = 1e-12)
  expect_equal(r$bomb * (1 - sb) + r$nuclear * (1 - sn), (F$e_foss_SH - Fb$e_foss_SH) * k, tolerance = 1e-12)
  expect_true(any(r$bomb < 0) || any(r$nuclear < 0))    # the case the solve must still get right
  expect_equal(r$gtc, sum(F$e_foss_NH + F$e_foss_SH - Fb$e_foss_NH - Fb$e_foss_SH) * diff(tt[1:2]), tolerance = 1e-12)
  # MUTATION: swapping the two columns' shares puts the tag in the wrong hemisphere -- caught
  aux_bad <- .spin$aux; aux_bad$bomb_share_NH <- sn; aux_bad$nuc_share_NH <- sb
  rb <- ccx_c14_tag_rates(F, Fb, aux_bad)
  expect_gt(max(abs(rb$bomb * sb + rb$nuclear * sn - (F$e_foss_NH - Fb$e_foss_NH) * k)), 1)
})

.tp <- ccx_tag_partition(.tagged$out, .pulse$out, .tagged$tag)
.after <- .tp$t >= TAG_TEST_PULSE[["year"]] + TAG_TEST_DELTA

test_that("CONSERVATION: with decay undone the tag sums to the pulse, to the undo's own bound", {
  expect_lt(max(abs(.tp$total[.after] - 1)), TAG_TEST_CLOSURE_BOUND)
  # MUTATION: without the decay undone, the same sum misses by ~lambda t -- far outside the bound
  raw <- with(.tagged$out, (atm_C14 + land_C14 + ocean_C14)) - with(.pulse$out, (atm_C14 + land_C14 + ocean_C14))
  expect_gt(max(abs(raw[.after] / .tagged$tag$gtc - 1)), 100 * TAG_TEST_CLOSURE_BOUND)
  # each reservoir's share is a share: inside [0, 1] after the release
  for (r in c("air", "land", "ocean")) expect_true(all(.tp[[r]][.after] >= 0 & .tp[[r]][.after] <= 1), info = r)
})

test_that("LINEARITY: tagging half the pulse gives the same fractions", {
  half <- .run(.pulse_em, tag_base = .with_pulse(.base_em, TAG_TEST_PULSE[["gtc"]] / 2))
  expect_equal(half$tag$gtc, TAG_TEST_PULSE[["gtc"]] / 2, tolerance = 1e-12)
  th <- ccx_tag_partition(half$out, .pulse$out, half$tag)
  for (r in c("air", "land", "ocean")) expect_equal(th[[r]][.after], .tp[[r]][.after], tolerance = 1e-9, info = r)
})

test_that("THE LESSON, as an ordering: the pulse's own atoms leave the air faster than the extra CO2", {
  g <- function(o) (o$co2_NH + o$co2_SH) / 2          # each hemisphere holds half the atmosphere
  pert_air <- (g(.pulse$out) - g(.base$out)) * ccx_const("GtC_PER_PPM") / TAG_TEST_PULSE[["gtc"]]
  for (h in TAG_TEST_LATER) {
    i <- which.min(abs(.tp$t - (TAG_TEST_PULSE[["year"]] + h)))
    expect_lt(.tp$air[i], pert_air[i])
  }
})
