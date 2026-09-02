# =====================================================================
# Gate: RULING A -- the ENSO index is demeaned, and the legacy path is exact.
#
# ADOPTED 2026-09-02 (Marcus) on the bake-off in
# `calibration/diag_enso_index_bakeoff.R`. Three things have to hold, and each
# is a different KIND of claim, so each gets its own kind of bound:
#
#   1. INTENT     -- the built column's mean over FORC_ENSO_DEMEAN_WIN is zero.
#                    That is what "demean" MEANS, so the bound is numerical
#                    tolerance, not a judgement call.
#   2. IDENTITY   -- with FORC_ENSO_DEMEAN = FALSE the column is BIT-identical
#                    to the pre-adoption one, and with it TRUE it differs from
#                    that by a CONSTANT. An identity claim gets an exact bound
#                    [[gate_bound_matches_its_claim]].
#   3. SPAN-INVARIANCE -- the offset is the same whatever `yrs` the caller asks
#                    for. This is the one that would fail silently: a mean taken
#                    over the requested window instead of the index's own record
#                    would make a 1750-2300 build and a 1948-2024 build see
#                    DIFFERENT ENSO, and every stored logpost would then depend
#                    on the span it was scored over.
#
# ⚠ NOTHING HERE ASSERTS THE ADOPTION WAS RIGHT. That is the bake-off's job and
# it re-optimised four gammas per candidate to do it. These are contract tests.
# =====================================================================

edm_enso <- function(yrs, demean) {
  old <- FORC_ENSO_DEMEAN
  assign("FORC_ENSO_DEMEAN", demean, envir = globalenv())
  on.exit(assign("FORC_ENSO_DEMEAN", old, envir = globalenv()), add = TRUE)
  F <- ccx_build_forcing("historical", yrs, prod_c14 = 0, bomb_total_kmol = 102)
  F[, c("year", "month", "enso")]
}

test_that("INTENT: the built ENSO column has zero mean over its stated window", {
  expect_true(FORC_ENSO_DEMEAN)                       # the adopted default
  F <- edm_enso(c(1750, 2024), TRUE)
  k <- F$year >= FORC_ENSO_DEMEAN_WIN[1] & F$year <= FORC_ENSO_DEMEAN_WIN[2]
  expect_lt(abs(mean(F$enso[k])), 1e-10)
})

test_that("IDENTITY: the legacy path is exact, and the change is a CONSTANT", {
  yrs <- c(1750, 2024)
  new <- edm_enso(yrs, TRUE)$enso
  old <- edm_enso(yrs, FALSE)$enso
  yr  <- edm_enso(yrs, TRUE)$year
  # Before 1948 BOTH are the FORC_ENSO_PRE1948 fill and must stay equal --
  # demeaning the index must not leak into the years the index does not cover.
  pre <- yr < 1948
  expect_equal(new[pre], old[pre], tolerance = 0)
  expect_true(all(new[pre] == FORC_ENSO_PRE1948))
  # Over the covered years the difference is ONE number, not a pattern.
  d <- (old - new)[!pre]
  expect_equal(max(d) - min(d), 0, tolerance = 1e-12)
  # ...and that number is the shipped index's own mean over the window, which
  # is what the bake-off priced. Independently recomputed from the rds here, so
  # this is not the builder checking its own arithmetic.
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  e <- e[!is.na(e$nino34_anom), ]
  kb <- e$year >= FORC_ENSO_DEMEAN_WIN[1] & e$year <= FORC_ENSO_DEMEAN_WIN[2]
  expect_equal(unname(d[1]), mean(e$nino34_anom[kb]), tolerance = 1e-12)
  # It is NOT zero -- if it were, this whole gate would pass vacuously.
  expect_gt(abs(d[1]), 0.1)
})

test_that("SPAN-INVARIANCE: the offset does not depend on the years requested", {
  # ⛔ THE OBVIOUS PAIR HERE HAS NO POWER, and a mutation test caught it on
  # 2026-09-02 before this file was committed. Comparing 1750-2024 against
  # 1948-2024 CANNOT fail: the ENSO index starts in 1948, so `year >= 1750` and
  # `year >= 1948` select exactly the same index rows, and a mutation that
  # demeaned over the REQUESTED window instead of the fixed one passed the gate
  # unchanged. The second span must therefore CUT INTO the index's own record.
  # [[no_power_null]] -- measure a test's power before believing its null.
  a <- edm_enso(c(1750, 2024), TRUE)
  b <- edm_enso(c(1980, 2024), TRUE)          # 1980 is INSIDE the index record
  k <- a$year >= 1980
  expect_equal(a$enso[k], b$enso, tolerance = 0)
  # And the two windows genuinely disagree about the mean, or the pair above is
  # still comparing a thing with itself.
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  e <- e[!is.na(e$nino34_anom), ]
  m_all <- mean(e$nino34_anom[e$year >= 1948 & e$year <= 2024])
  m_cut <- mean(e$nino34_anom[e$year >= 1980 & e$year <= 2024])
  expect_gt(abs(m_all - m_cut), 0.01)
})

test_that("PRICED: the shipped builder reproduces BOTH bake-off numbers", {
  # ⭐ THE ANCHOR. Everything above is a contract test -- this is the one that
  # says we shipped the thing that was TESTED. The bake-off and the baseline
  # diagnostic both scored their candidates through a WRAPPED ccx_build_forcing
  # that overwrote the enso column wholesale. This scores the LIVE builder at
  # the same 09-01 basin vector, with the flag on and off, and requires the two
  # published logposts back: asis -1568.4936, demean -1512.0151, a gain of
  # +56.4785 = 86 % of the one-way term's -65.74.
  basin <- ccx_path("calibration/output/multistart_20260901_enso25/start_000.rds")
  skip_if(!file.exists(basin), "the 09-01 basin vector is not on disk")
  # ⛔ NOT `skip_if(!exists("dg_vector"))`. Under test_dir() the calibration
  # libs are not on the search path, so that guard SKIPPED this gate in every
  # full-suite run -- a gate that cannot run reports nothing
  # [[broken_gate_reports_nothing]]. It sources what it needs instead, and only
  # skips if the lib is genuinely absent.
  lib <- ccx_path("calibration", "lib_design_gates.R")
  skip_if(!file.exists(lib), "lib_design_gates.R absent")
  if (!exists("dg_vector")) source(lib)
  pm <- ccx_migrate_par_set(readRDS(basin)$par_mode)
  u0 <- ccx_par_to_unc(pm)
  bp <- ccx_default_params(); bp$pump_mode <- dg_vector("from90")$md$pump_mode
  sc <- function(dm) { old <- FORC_ENSO_DEMEAN
    assign("FORC_ENSO_DEMEAN", dm, envir = globalenv())
    on.exit(assign("FORC_ENSO_DEMEAN", old, envir = globalenv()), add = TRUE)
    ccx_make_logpost(base_params = bp)(u0) }
  # ⚠ THE BOUND IS THE QUOTING PRECISION, not a tuned tolerance. Both
  # references are PRINTED to four decimals, so half an ulp of that print is
  # 5e-5 and nothing tighter is testing the model rather than the format. The
  # measured residuals are -2e-5 and +3e-5, i.e. inside the print itself.
  expect_equal(sc(FALSE), -1568.4936, tolerance = 1e-4, scale = 1)
  expect_equal(sc(TRUE),  -1512.0151, tolerance = 1e-4, scale = 1)
})
