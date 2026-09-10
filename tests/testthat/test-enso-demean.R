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

# ---------------------------------------------------------------------
# THE PRICE OF THE FLAG, AND WHY IT IS ASSERTED AT TWO MODES (2026-09-10).
#
# ⭐ THE ANCHOR. Everything above is a contract test -- these are the ones that
# say we shipped the thing that was TESTED. Ruling A (the ENSO demeaning) was
# ratified on a GAP: the objective with the flag ON minus the SAME vector with it
# OFF, scored by the SAME harness in one session. A gap is objective-independent
# by construction, which is why the absolute form of this test kept going stale
# (rebuilt 2026-09-04 after it broke THREE ways at once: it encoded a pre-26
# ancestor, asserted two absolute logposts, and named a retired arm --
# [[runnable_is_not_encodable]], [[compare_gaps_not_absolute_logposts]]).
#
# THE SERIES, every value a measurement at a named mode under a named spinup:
#   56.4785  the un-refitted 09-01 ancestor (ratified there first)
#   45.1618  `ent26`, aseasonal            (the 26-par refit absorbed part of the
#                                           forcing's non-zero mean elsewhere)
#   43.8367  `hilda31`, aseasonal          (re-derived at the 09-08f adoption)
#   63.7282  `hilda31`, PERIODIC           (the 09-09x adoption "re-priced" it --
#                                           but at a mode fitted under the OTHER
#                                           spinup: a STALE-MODE ARTIFACT)
#   45.1896  `hilda31p`, PERIODIC          (the mode REFITTED under the adopted
#                                           objective: back beside 43.84)
# ⇒ RULING A'S RATIFICATION IS NOT THREATENED ⇒ [[ruling_a_repricing_was_a_stale_mode]].
# The excursion is the one point that was never refitted, and the mechanism is
# the one this file has described since 09-04: a refit absorbs part of the
# forcing's non-zero mean elsewhere, so the MARGINAL value of demeaning at a
# refitted optimum is smaller than at an un-refitted point.
#
# ⛔ NEVER PRICE A MECHANISM AT A MODE FITTED UNDER A DIFFERENT OBJECTIVE. The
# difference between "worth 45" and "worth 64" was entirely whether the
# parameters had been allowed to re-adapt ⇒ [[like_for_like_forcing]].
#
# So: the CANONICAL mode carries the live price (45.1896) and the cross-check
# under ITS OWN vintage; the retired `hilda31` -- by PATH, it has left the
# registry -- carries the ratification pin (43.8367) and the artifact (63.7282),
# both still TRUE facts about that file. Each mode's streams must reproduce
# under the spinup the file RECORDS (ccx_mode_spinup) and NOT under the other,
# or `spinup_fn` is not reaching the model and the vintage distinction is
# decoration.
# ---------------------------------------------------------------------
edm_price <- function(md) {
  u0 <- ccx_par_to_unc(md$par_mode)     # no migration: a vector of the fitted space
  expect_true(all(is.finite(u0)))
  # THE FILE'S OWN STRUCTURE (2026-09-08f): on the column default the same
  # vector scores -2.3e7 and nothing below reproduces.
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  sc <- function(dm, sf) { old <- FORC_ENSO_DEMEAN
    assign("FORC_ENSO_DEMEAN", dm, envir = globalenv())
    on.exit(assign("FORC_ENSO_DEMEAN", old, envir = globalenv()), add = TRUE)
    ccx_make_logpost(base_params = bp, spinup_fn = sf)(u0) }
  own   <- ccx_spinup_from_label(ccx_mode_spinup(md))
  other <- ccx_spinup_from_label(setdiff(c("periodic", "aseasonal"), ccx_mode_spinup(md)))
  list(u0 = u0, bp = bp,
       on_own = sc(TRUE, own), off_own = sc(FALSE, own),
       on_other = sc(TRUE, other), off_other = sc(FALSE, other),
       on_periodic  = sc(TRUE, ccx_periodic_spinup), off_periodic  = sc(FALSE, ccx_periodic_spinup),
       on_aseasonal = sc(TRUE, ccx_spinup),          off_aseasonal = sc(FALSE, ccx_spinup))
}
# CROSS-CHECK, and it is what makes the gap trustworthy rather than circular:
# with the flag ON -- the SHIPPED state -- the harness, scored under the file's
# OWN spinup, must reproduce the file's stored per-stream LIKELIHOOD: harness
# logpost MINUS the log-prior at the same point == sum(md$streams). That pins
# 25 rows' sum, is immune to any PRIOR move (09-09w's -0.811 broke the absolute
# form -- the THIRD instance of [[compare_gaps_not_absolute_logposts]]) and to
# an OBJECTIVE move so long as the vintage is the file's (09-09x's -10.158
# broke it again -- the FOURTH ⇒ [[stale_fixture_repair]]). It still fails
# the moment the harness scores a different vector.
# ⚠ The prior leg is TRANSCRIBED rather than imported, deliberately, as in
# test-ent-seas-fitted.R: an independent copy is what makes this a check.
# `ccx_make_logpost()`'s own prior leg is these three lines.
edm_logprior <- function(u) { names(u) <- CCX_PARAM_NAMES; pv <- ccx_unc_to_par(u)
  lp <- 0; for (n in CCX_PARAM_NAMES) { s <- CCX_PARAM_TABLE[[n]]
    lp <- lp + s$prior(pv[[n]]) + .log_jac(u[[n]], s) }; lp }
edm_crosscheck <- function(md, r) {
  ed_lp  <- edm_logprior(r$u0)
  ed_lik <- sum(unlist(md$streams))
  # OBJECTIVE CHANGE #8 (2026-09-06): the two intermediate D14C rows were added
  # AFTER the pre-09-08f files were stored; a file that RECORDS its structure
  # was promoted after #8/#9 and its streams already carry the rows.
  expect_false(is.null(md$struct))
  expect_equal(r$on_own - ed_lp, ed_lik, tolerance = 1e-5, scale = 1)
  # MUTATION: the identity must FAIL on a moved likelihood and on a moved
  # prior-leg, or it is not a check ([[mutation_test_gates]]).
  expect_false(isTRUE(all.equal(r$on_own - ed_lp, ed_lik + 1, tolerance = 1e-5, scale = 1)))
  expect_false(isTRUE(all.equal(r$on_own - (ed_lp + 1), ed_lik, tolerance = 1e-5, scale = 1)))
  # ⭐ AND THE OTHER vintage must NOT reproduce it, or `spinup_fn` is not
  # reaching the model.
  expect_false(isTRUE(all.equal(r$on_other - ed_lp, ed_lik, tolerance = 1e-5, scale = 1)))
  # the stored logpost is reported as PROVENANCE, not gated: it carries whatever
  # prior/objective drift has happened since the file was fitted.
  expect_true(is.finite(md$logpost))
}

test_that("PRICED at the CANONICAL mode: the demean flag is worth 45.1896 under the adopted objective", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  # the canonical is a PERIODIC-era file, and says so (stamped 09-10 after GATE 5
  # had proved its streams periodic; calibration/stamp_mode_spinup.R)
  expect_identical(ccx_mode_spinup(md), "periodic")
  r <- edm_price(md)
  edm_crosscheck(md, r)
  # ⚠ TOLERANCE = the project's existing "does this point reproduce" precision
  # (recompute_hessian.R GATE 1, promote_multistart_mode.R GATE 4), not a new
  # number chosen here. Measured 2026-09-10 at `hilda31p` (CHANGELOG 09-10 (5)).
  expect_equal(r$on_periodic - r$off_periodic, 45.1896, tolerance = 1e-4, scale = 1)
  # MUTATION GUARD: the flag must actually do something, or the gap above could
  # be two identical scorings agreeing to any tolerance you like.
  expect_gt(r$on_periodic - r$off_periodic, 1)
  # ... and the two vintages must genuinely DIFFER, or `spinup_fn` is inert here
  # (27.04 under the aseasonal spinup, a cross-vintage number of no standing --
  # reported by the gap, not asserted as a value).
  expect_gt(abs((r$on_periodic - r$off_periodic) - (r$on_aseasonal - r$off_aseasonal)), 1)
})

test_that("RATIFICATION PIN at `hilda31` (retired, by path): 43.8367 aseasonal, and the 63.7282 artifact", {
  skip_if_no_cpp()
  md <- readRDS(ccx_path(CCX_MODE_HILDA31_QUARANTINED))
  expect_identical(ccx_mode_spinup(md), "aseasonal")   # unrecorded = pre-09-09x = a fact
  r <- edm_price(md)
  edm_crosscheck(md, r)
  # 43.8367 is what Ruling A was ratified on at the 09-08f adoption (45.1618 at
  # ent26 before it); it still reproduces exactly, which is what makes 63.7282
  # a measured MOVE rather than a lost baseline -- and 45.1896 above a RETURN.
  expect_equal(r$on_aseasonal - r$off_aseasonal, 43.8367, tolerance = 1e-4, scale = 1)
  expect_equal(r$on_periodic  - r$off_periodic,  63.7282, tolerance = 1e-4, scale = 1)
  expect_gt(r$on_aseasonal - r$off_aseasonal, 1)
  expect_gt(abs((r$on_periodic - r$off_periodic) - (r$on_aseasonal - r$off_aseasonal)), 1)
})
