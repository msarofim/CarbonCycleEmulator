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
# the observations, built once per file (review B4): ccx_make_logpost()'s default
# rebuilds them on every closure
edm_obs <- local({ o <- NULL; function() { if (is.null(o)) o <<- ccx_prepare_obs(); o } })
edm_price <- function(md, spinups = c("periodic", "aseasonal")) {
  # a PINNED file (2026-09-13) is encoded on ITS reduced space: apply its pins,
  # and restore with the object ccx_apply_pins() returned (CCX_PINS is process-global)
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  # 2026-09-13i: the registered files lack the cell's pair (CCX_PARAM_ABSENT_OK);
  # ccx_mode_start() migrates (0 = what it ran), seeds the floor-sitting pair at
  # init and encodes -- the driver's own start path. The pair is INERT under the
  # files' "hilda" structure, and every assertion below is a GAP or subtracts the
  # prior leg at this very point, so the seed's prior term cancels.
  u0 <- ccx_mode_start(md, "edm_price")$u
  expect_true(all(is.finite(u0)))
  # THE FILE'S OWN STRUCTURE (2026-09-08f): on the column default the same
  # vector scores -2.3e7 and nothing below reproduces.
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  # by stream (2026-10-01 c): the scalar is the same sum; the streams are kept for the mutation guard
  sc <- function(dm, sf) { old <- FORC_ENSO_DEMEAN
    assign("FORC_ENSO_DEMEAN", dm, envir = globalenv())
    on.exit(assign("FORC_ENSO_DEMEAN", old, envir = globalenv()), add = TRUE)
    v <- ccx_make_logpost(obs = edm_obs(), base_params = bp, spinup_fn = sf, by_stream = TRUE)(u0)
    list(lp = as.numeric(v), st = attr(v, "streams")) }
  # FOUR distinct scorings, not eight (review B4, 2026-09-12): `own`/`other` are
  # ALIASES of the periodic/aseasonal pair, resolved from the spinup the file
  # RECORDS, and a caller that reads one vintage asks for only that one.
  own <- ccx_mode_spinup(md); other <- setdiff(c("periodic", "aseasonal"), own)
  stopifnot(own %in% spinups)
  r <- list(u0 = u0, bp = bp)
  for (s in spinups) {
    on <- sc(TRUE,  ccx_spinup_from_label(s)); off <- sc(FALSE, ccx_spinup_from_label(s))
    r[[paste0("on_",  s)]] <- on$lp;  r[[paste0("off_", s)]] <- off$lp
    r[[paste0("st_on_", s)]] <- on$st; r[[paste0("st_off_", s)]] <- off$st
  }
  r$on_own   <- r[[paste0("on_",  own)]];   r$off_own   <- r[[paste0("off_", own)]]
  r$on_other <- r[[paste0("on_",  other)]]; r$off_other <- r[[paste0("off_", other)]]
  r
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
# 2026-09-17 (h): the priors that READ THE STRUCTURE (u_hs's Sv-to-m/yr centre at the live hs_frac,
# 09-16 d) are evaluated on the base + the draw, exactly as ccx_make_logpost() does; the bare
# `s$prior(x)` form converted at the built 0.16 and missed a correct hilda_c point by 0.27.
edm_logprior <- function(u, bp) { names(u) <- CCX_PARAM_NAMES; pv <- ccx_unc_to_par(u)
  p_pr <- bp; for (n in names(pv)) p_pr[[n]] <- pv[[n]]
  lp <- 0; for (n in CCX_PARAM_NAMES) { s <- CCX_PARAM_TABLE[[n]]
    lp <- lp + .ccx_prior_eval(s, pv[[n]], p_pr) + .log_jac(u[[n]], s) }; lp }
edm_crosscheck <- function(md, r) {
  # the prior leg is summed over the file's OWN fitted names: a pinned file's
  # reduced set, under its pins (2026-09-13)
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  ed_lp  <- edm_logprior(r$u0, r$bp)
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

test_that("PRICED at the CANONICAL mode: the demean flag is worth -0.0053 under objective #14 with constant interpolation at hilda33d (0.0364 under spline; 9.0242 under #13 at hilda29l); 17.7499 at the seas_ml 0 control hilda31pe", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  # the canonical is a PERIODIC-era file, and says so (stamped 09-10 after GATE 5
  # had proved its streams periodic; calibration/stamp_mode_spinup.R)
  expect_identical(ccx_mode_spinup(md), "periodic")
  r <- edm_price(md)
  edm_crosscheck(md, r)
  # ⚠ TOLERANCE = the project's existing "does this point reproduce" precision
  # (recompute_hessian.R GATE 1, promote_multistart_mode.R GATE 4), not a new
  # number chosen here. Measured 2026-09-10 at `hilda31p` (CHANGELOG 09-10 (5)):
  # 45.1896. RE-PRICED 2026-09-11 (5) to 45.1848 (-0.0048) when the gradient and
  # HS-surface rows became ANNUAL MEANS over the box's mass at the time
  # ([[seasonal_box_observable_artefact]]) -- an objective move, priced -0.0957
  # at this mode and restamped into the file (calibration/restamp_mode_objective.R).
  # 2026-09-11 (8): the canonical is `hilda31s` (seasonal mixed layer ON); the flag is
  # worth 43.9113 there. The 45.1848 is kept as a pin at the seas_ml = 0 CONTROL, by
  # name -- a second point where the flag's price is asserted, not a lost baseline.
  # RE-PRICED 2026-09-12 (rulings 4+5+7, Marcus; CHANGELOG 09-12 (c)): 43.9113 ->
  # 32.5460 at hilda31s and 45.1848 -> 35.1749 at the control. The whole move is
  # RULING 4 -- the periodic spinup's 13C/14C pins became ANNUAL MEANS, shifting the
  # preindustrial d13C level by +0.025 permil, and the demean flag's ENSO-driven
  # d13C trajectory is priced against that level (the aseasonal price at the
  # quarantined hilda31 moved +0.0003 under the same rulings). Both files restamped.
  # 09-12 (d): +0.0023 at every file from review A12 (the D14C edge years 1941/2019 scored
  # over their OBSERVED months) -- 32.5460 -> 32.5483, 35.1749 -> 35.1773.
  # 2026-09-13: the canonical is `hilda31s2` (round 7, a MODE of the 09-12 objective):
  # 42.5817 -- the flag's price at a mode fitted under the annual-mean pins, vs 32.55 at
  # the restamped-but-unrefit hilda31s (the -10 was ruling 4's interaction with a mode
  # that had not yet moved; see 09-12 (c)). 35.1773 stays the pin at the control.
  # 2026-09-13 (d): the canonical is `hilda30c` (C′: the shim PINNED at 0, 30 free names; edm_price
  # applies the file's pins): 43.1079 -- +0.53 over the parent hilda31s2's 42.5817, measured, not
  # explained; the flag's price is a property of the ENSO-driven d13C trajectory, which the pin
  # barely touches. 42.5817 stays a fact about hilda31s2 (the registered free parent, no longer
  # asserted here); 35.1773 stays the pin at the control.
  # 2026-09-16 (d), the objective-hygiene batch: 43.1079 -> 49.7606 (+6.65) and the control
  # 35.1773 -> 41.6102 (+6.43). The move is the LAND-SINK sigma (GCB's 0.5, no x3): the flag
  # acts through the ENSO land term, whose row is now 3x stronger; the other four items
  # move it < 0.1 (hygiene_batch_price_20260916). Files restamped, history kept inside them.
  # 2026-09-17 (h): the canonical is `hilda30h` -- the FIRST mode FITTED under the batch's objective
  # (#12) and on hilda_c: 49.7606 -> 17.5455 (-32.2). MEASURED at the promoted file, not explained
  # in full: the flag acts through the ENSO coefficients, and the refit under the land-sink row at
  # GCB's bare sigma shrank gamma_enso_land NH/SH 0.70/0.40 -> 0.55/0.22 and put gamma_enso_ocn_SH
  # at 0 (the two-limb kink) -- roughly the (gamma)^2 scaling of a price on an ENSO-driven
  # trajectory -- and GATE V got worse (0.77 -> 0.59x). 49.7606 stays a fact about the quarantined
  # hilda30c; 41.6102 stays the pin at the control (unrefit under #12 -- its refit is owed).
  # 2026-09-18 (e): objective #13 adds the GCB ENSO ocean-slope row; the demean flag changes the
  # FORCING the model's ocean sink responds to, so the row differs by ~0.07 between the two
  # scorings: 17.5455 -> 17.4739 (canonical), 41.6102 -> 41.5433 (control). Files restamped.
  # 2026-09-19 (j): the canonical is `hilda30e` (the #13 REFIT: gamma_enso_ocn_NH 0.36 -> 0.45, SH 0 -> 0.015,
  # nothing else moved): 17.4739 -> 17.1138 (-0.36 -- the flag acts through the ENSO coefficients, and the
  # ocean pair grew). The CONTROL is now `hilda31pe` (the control's #13 refit on hilda_c, ML off, shim free):
  # 41.5433 (hilda31p, a `hilda` mode never refit under hilda_c) -> 17.8469 -- a DIFFERENT point on a
  # different structure, not a drift: its gamma_enso_land NH/SH 0.57/0.24 sit beside the canonical's 0.58/0.21
  # (hilda31p carried 0.69/0.43), and the demean price scales with the land pair. Both MEASURED at the promoted files.
  # 2026-09-20 (o): the canonical is `hilda30s` (hilda_cs: the ML's NH cycle flat; the ENSO pair 0.44/0.04):
  # 17.1138 -> 17.7133 (+0.60; the demean price now sits 0.13 from the control's 17.8469 -- the two arms'
  # ENSO coefficients are within a few percent of each other). MEASURED at the promoted file.
  # 2026-09-20 (r): the canonical is `hilda29l` -- the ocean ENSO SHIM PAIR is PINNED at 0 and the layer-3
  # LIMB (w_enso_l2 13.7) carries the ocean response: 17.7133 -> 9.0242. The demean flag acts through the
  # ENSO COEFFICIENTS the forcing multiplies; the limb's response is clipped by its floor and enters the
  # ocean as a volume exchange, not a coefficient on the index, so the flag's price halves (PA6's finding,
  # l2_array_read_csl3_20260920). MEASURED at the promoted file.
  # 2026-10-01 (c): the canonical is `hilda33d` (objective #14; D2/D3 fitted, phi = 0): 9.0242 -> 0.0364
  # (0.036416). NOT inert: the ENSO column's mean is 0 on and -0.061 off, and the streams move by up to
  # +-2.8 log-units (d13c_level_SPO +2.82, d13c_level_MLO -2.21, co2_icecore -1.06, co2_level_SPO -0.76,
  # co2_level_MLO +0.62, ...) -- in OPPOSITE directions, netting +0.036 where hilda29l's moved together.
  # MEASURED at the promoted file (re-pin approved by Marcus).
  # 2026-10-01 (k): the emissions interpolation spline -> constant (review 10-01c B6; no refit, the
  # registered files restamped at their priced moves): 0.0364 -> -0.0053 (-0.005260). A near-
  # cancellation either way: the streams' total |change| is 9.10 (was ~9.1), the net crosses zero.
  # MEASURED at the restamped file (re-pin approved by Marcus).
  # 2026-10-02 (objective #15: the ice d13C row reads 1948-77, where the index treatment acts; the
  # pre-1958 ice-CO2 cut; the W5 priors move no stream): -0.0053 -> +0.4790 (0.478982) at the
  # restamped file. MEASURED (re-pin approved by Marcus).
  # 2026-10-03 (h): the canonical is hilda34g (objective #15, the land ENSO lag fitted, 2.64 months):
  # +0.4790 -> +0.5673 (0.567266). MEASURED at the promoted file (Marcus 2026-10-03: "Approve all (Recommended)").
  expect_equal(r$on_periodic - r$off_periodic, 0.5673, tolerance = 1e-4, scale = 1)
  r0 <- edm_price(readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL)), spinups = "periodic")   # only its periodic pair is read
  # 2026-10-01 (k), the same flip: 17.8469 -> 17.7499 (17.749910) at the restamped control.
  # 2026-10-02 (objective #15): 17.7499 -> 20.5487 (20.548668) at the restamped control (approved by Marcus).
  expect_equal(r0$on_periodic - r0$off_periodic, 20.5487, tolerance = 1e-4, scale = 1)
  # MUTATION GUARD: the flag must actually do something, or the gap above could
  # be two identical scorings agreeing to any tolerance you like.
  # ⚠ RE-CUT 2026-10-01 (c): it read the NET price (> 1), which a canonical whose rows move in OPPOSITE
  # directions cancels (above). The flag's action is the streams' total |change| -- ~9.1 at hilda33d --
  # so that is what the guard reads now (approved by Marcus).
  expect_gt(sum(abs(unlist(r$st_on_periodic) - unlist(r$st_off_periodic))), 1)
  # ... and the two vintages must genuinely DIFFER, or `spinup_fn` is inert here
  # (27.04 under the aseasonal spinup, a cross-vintage number of no standing --
  # reported by the gap, not asserted as a value).
  expect_gt(abs((r$on_periodic - r$off_periodic) - (r$on_aseasonal - r$off_aseasonal)), 1)
})

test_that("RATIFICATION PIN at `hilda31` (retired, by path): 50.1629 aseasonal, and the 59.8552 artifact (#13, constant interpolation)", {
  skip_if_no_cpp()
  md <- readRDS(ccx_path(CCX_MODE_HILDA31_QUARANTINED))
  expect_identical(ccx_mode_spinup(md), "aseasonal")   # unrecorded = pre-09-09x = a fact
  r <- edm_price(md)
  edm_crosscheck(md, r)
  # 43.8367 is what Ruling A was ratified on at the 09-08f adoption (45.1618 at
  # ent26 before it); it still reproduces exactly, which is what makes 63.7282
  # a measured MOVE rather than a lost baseline -- and 45.1896 above a RETURN.
  # 43.8367 / 63.7282 until 2026-09-11 (5); -0.0049 each under the annual-mean
  # read (the file restamped, likelihood -0.0937, with its history kept inside it).
  # 2026-09-12 (rulings 4+5+7): the ASEASONAL price moved +0.0003 (43.8318 -> 43.8321
  # -- rulings 5+7 barely touch it; ruling 4 cannot, the aseasonal spinup has no
  # orbit to pin) while the PERIODIC artifact moved 63.7234 -> 53.5199: that -10.2 IS
  # ruling 4's interaction with the demean flag, the same -10/-11 the two registered
  # files show. The file is restamped (+30.6090, history kept).
  # 09-12 (d): +0.0023 each from review A12 (observed-month D14C edge years).
  # 09-16 (d): +6.5590 / +6.5633 from the hygiene batch (the land-sink sigma; file restamped -21.6168 on the likelihood).
  # 09-18 (e): -0.0672 / -0.0671 from objective #13's ENSO-slope row (file restamped +0.3630 on the likelihood).
  # 10-01 (k): -0.1633 / -0.1632 from the emissions-interpolation flip (spline -> constant; the file
  # restamped -0.0378 on the likelihood, history kept): 50.3262 -> 50.1629, 60.0184 -> 59.8552.
  # 10-02 (objective #15): +2.7443 / +2.7289 (the file restamped +213.1080 on the likelihood, history
  # kept): 50.1629 -> 52.9072, 59.8552 -> 62.5841 (re-pin approved by Marcus).
  expect_equal(r$on_aseasonal - r$off_aseasonal, 52.9072, tolerance = 1e-4, scale = 1)
  expect_equal(r$on_periodic  - r$off_periodic,  62.5841, tolerance = 1e-4, scale = 1)
  expect_gt(r$on_aseasonal - r$off_aseasonal, 1)
  expect_gt(abs((r$on_periodic - r$off_periodic) - (r$on_aseasonal - r$off_aseasonal)), 1)
})
