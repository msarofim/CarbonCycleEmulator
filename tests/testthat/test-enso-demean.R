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

test_that("PRICED: the demean flag is still worth what Ruling A was ratified on", {
  # ⭐ THE ANCHOR. Everything above is a contract test -- this is the one that
  # says we shipped the thing that was TESTED.
  #
  # ⛔ REBUILT 2026-09-04, AND IT WAS BROKEN THREE WAYS AT ONCE. It scored a
  # MIGRATED 09-01 ancestor, which meant:
  #   1. it ENCODED a pre-26 vector -- `ent_seas_amp_SH = 0` has no image under
  #      `tr = "log"`, so `ccx_par_to_unc()` refused it and the test ERRORED
  #      (not failed: `as.data.frame(test_dir())$failed` does not count errors,
  #      which is how it went unreported for a day). [[runnable_is_not_encodable]]
  #   2. it asserted TWO ABSOLUTE LOGPOSTS (-1568.4936 / -1512.0151) which are
  #      meaningless once the space changes, and no fill repairs them -- seeded
  #      at the init the same pair reads -1880.10 / -1829.09.
  #      [[compare_gaps_not_absolute_logposts]]
  #   3. it called `dg_vector("from90")` for a pump_mode, and `from90` is now a
  #      RETIRED arm that errors by name.
  #
  # ⇒ It now scores at the CANONICAL mode -- a genuine point of the fitted space,
  # needing no migration and no ancestor -- and asserts the GAP, which is what
  # Ruling A actually claims. A gap between two scorings of the SAME vector by
  # the SAME harness in one session is objective-independent by construction;
  # that is the whole reason the absolute form kept going stale.
  #
  # ⚠ THE GAIN SHRANK, +56.4785 -> +45.1618, AND THAT IS THE EXPECTED DIRECTION,
  # not a regression: the 26-par refit absorbed part of the ENSO forcing's
  # non-zero mean into other coordinates, so the MARGINAL value of demeaning at
  # the refitted optimum is smaller than at the un-refitted ancestor it was
  # ratified on. The mechanism is still worth 45 log-units.
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  u0 <- ccx_par_to_unc(md$par_mode)     # no migration: this IS a 26-par vector
  expect_true(all(is.finite(u0)))
  bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
  sc <- function(dm) { old <- FORC_ENSO_DEMEAN
    assign("FORC_ENSO_DEMEAN", dm, envir = globalenv())
    on.exit(assign("FORC_ENSO_DEMEAN", old, envir = globalenv()), add = TRUE)
    ccx_make_logpost(base_params = bp)(u0) }
  off <- sc(FALSE); on <- sc(TRUE)
  # CROSS-CHECK, and it is what makes the gap trustworthy rather than circular:
  # with the flag ON -- the SHIPPED state -- the harness must reproduce the mode
  # file's OWN stored logpost. If it does not, the two scorings are not of the
  # vector this test claims.
  # ⚠ OBJECTIVE CHANGE #8 (2026-09-06): the two intermediate D14C rows were added
  # AFTER this mode was stored, so the stored logpost lacks them. The repair is
  # DERIVED, not re-baselined ([[stale_fixture_repair]]): score the same vector
  # with the rows switched off and require THAT to reproduce the file; then
  # require the difference to be exactly the two rows' own Gaussians.
  sc_nomid <- function() { old <- LIK_USE_D14C_MID
    assign("LIK_USE_D14C_MID", FALSE, envir = globalenv())
    on.exit(assign("LIK_USE_D14C_MID", old, envir = globalenv()), add = TRUE)
    ccx_make_logpost(base_params = bp)(u0) }
  on_nomid <- sc_nomid()
  expect_equal(on_nomid, md$logpost, tolerance = 1e-5, scale = 1)
  tgm <- ccx_mid_d14c_target()
  if (!is.null(tgm)) {
    pp  <- ccx_overlay_par(bp, ccx_unc_to_par(u0))
    mid <- ccx_model_d14c_slabs(ccx_spinup(pp))
    rows <- sum(stats::dnorm(tgm$slabs$target, mid[tgm$slabs$name], tgm$slabs$sd, log = TRUE))
    expect_equal(on - on_nomid, rows, tolerance = 1e-6, scale = 1)
  }
  # ⚠ TOLERANCE = the project's existing "does this point reproduce" precision
  # (recompute_hessian.R GATE 1, promote_multistart_mode.R GATE 4), not a new
  # number chosen here.
  expect_equal(on - off, 45.1618, tolerance = 1e-4, scale = 1)
  # MUTATION GUARD: the flag must actually do something, or the gap above could
  # be two identical scorings agreeing to any tolerance you like.
  expect_gt(on - off, 1)
})
