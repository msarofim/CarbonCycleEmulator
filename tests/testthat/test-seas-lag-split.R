# =====================================================================
# test-seas-lag-split.R -- the NPP phenology lag went per-hemisphere 2026-08-31
# (Marcus's design call, option A of the 08-29 whole-model assessment).
#
# `seas_lag_p` was ONE SCALAR shifting the NPP phase in BOTH hemispheres while
# `seas_npp_amp` and `seas_T_amp` were already [2] arrays a few lines away. That
# asymmetry was measured to cost -838 conditional at lag 2.25, of which the NH
# paid 94 % (notes/collect_2026-08-29d).
#
# WHAT THIS FILE HAS TO HOLD:
#   1. THE ABSENCE CONTRACT, in BOTH CORES. A pre-split parameter list carries
#      only the legacy scalar; it must reach BOTH hemispheres and reproduce the
#      old model bit for bit. ⚠ And R and C++ must agree about that, because on
#      2026-08-30 `gamma_diff`'s two fallbacks had drifted apart for a
#      0.647 GtC/yr parity break that every test missed -- they all pinned
#      EXPLICIT values, and an explicit value never exercises a fallback.
#      A default has TWO contracts: the value, and what ABSENCE means.
#   2. THE MECHANISM IS REAL. Unequal lags must MOVE the answer, or the split
#      is decoration and test 1 passes vacuously.
#   3. PARITY AT UNEQUAL LAGS. An equal pair cannot distinguish `seas_lag_p[hi]`
#      from the old scalar, so equal-lag parity would be the vacuous version of
#      the very test that matters.
# =====================================================================

lag_p <- function(nh = NULL, sh = NULL, legacy = NULL) {
  p <- ccx_default_params()
  p$seas_lag_p_NH <- nh; p$seas_lag_p_SH <- sh; p$seas_lag_p <- legacy
  p
}

test_that("the split is declared, and both halves carry the ORIGINAL prior", {
  expect_true(all(c("seas_lag_p_NH", "seas_lag_p_SH") %in% CCX_PARAM_NAMES))
  expect_false("seas_lag_p" %in% CCX_PARAM_NAMES)
  # the split adds a degree of freedom; it must NOT smuggle in a new belief
  for (x in c(1.5, 2.25, 3.0))
    expect_equal(CCX_PARAM_TABLE$seas_lag_p_NH$prior(x),
                 CCX_PARAM_TABLE$seas_lag_p_SH$prior(x))
  expect_equal(CCX_PARAM_TABLE$seas_lag_p_NH$prior(2.25),
               dnorm(2.25, 2.25, 0.75, log = TRUE))
})

test_that("THE ABSENCE CONTRACT: a legacy scalar reaches BOTH hemispheres", {
  expect_equal(unname(ccx_seas_lag_p(lag_p(legacy = 1.9))), c(1.9, 1.9))
  # neither field and no legacy -> the named default, not a silent zero
  expect_equal(unname(ccx_seas_lag_p(lag_p())), rep(CCX_SEAS_LAG_P_DEFAULT, 2))
  # an explicit field WINS over the legacy scalar
  expect_equal(unname(ccx_seas_lag_p(lag_p(sh = 2.4, legacy = 1.9))), c(1.9, 2.4))
})

test_that("a pre-split parameter list is BIT-IDENTICAL to the explicit equal pair", {
  skip_if_no_cpp()
  s_leg <- ccx_spinup(lag_p(legacy = 1.7677))
  s_new <- ccx_spinup(lag_p(nh = 1.7677, sh = 1.7677))
  F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1980),
                                          prod_c14 = s_leg$prod_c14))
  a <- ccx_run_fast(s_leg, F)$out; b <- ccx_run_fast(s_new, F)$out
  expect_equal(a$co2_NH, b$co2_NH, tolerance = 0)
  expect_equal(a$co2_SH, b$co2_SH, tolerance = 0)
})

test_that("MUTATION TEST: unequal lags MOVE the answer", {
  skip_if_no_cpp()
  # If this fails, the two tests above are passing on a parameter that does
  # nothing -- the lesson of the 14C decay gate, inert for weeks.
  s_eq <- ccx_spinup(lag_p(nh = 1.7677, sh = 1.7677))
  s_un <- ccx_spinup(lag_p(nh = 1.7677, sh = 2.25))
  F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1980),
                                          prod_c14 = s_eq$prod_c14))
  a <- ccx_run_fast(s_eq, F)$out; b <- ccx_run_fast(s_un, F)$out
  expect_gt(max(abs(a$co2_SH - b$co2_SH)), 1e-3)
})

test_that("R and C++ agree at UNEQUAL lags, and on the legacy absence path", {
  skip_if_no_cpp()
  frc_at <- function(F, i) list(
    e_foss = list(NH = F$e_foss_NH[i], SH = F$e_foss_SH[i]),
    e_luc  = list(NH = F$e_luc_NH[i],  SH = F$e_luc_SH[i]),
    cum_luc = list(NH = F$cum_luc_NH[i], SH = F$cum_luc_SH[i]),
    gmst = F$gmst[i], enso = F$enso[i], c14_bomb = F$c14_bomb[i],
    c14_nuclear = F$c14_nuclear[i], c14_cosmo = F$c14_cosmo[i],
    d13c_foss = F$d13c_foss[i], aod_NH = F$aod_NH[i], aod_SH = F$aod_SH[i])
  for (p in list(lag_p(nh = 1.7677, sh = 2.25),   # explicit, UNEQUAL
                 lag_p(legacy = 1.9))) {          # the fallback path
    s <- ccx_spinup(p)
    F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1961),
                                            prod_c14 = s$prod_c14))
    fy <- frc_at(F, 1)
    dR <- ccx_deriv(s$y, 1960, p, fy, s$grid, s$aux)
    dC <- ccx_deriv_fast(s$y, 1960, p, fy, s$grid, s$aux)
    for (tr in CCX_TRACERS)
      expect_lt(max(abs(dR[, tr] - dC[, tr])), 1e-9 * max(abs(dR[, tr])) + 1e-12)
  }
})

test_that("a stored vector decodes under ITS OWN names, not the build's", {
  # The split broke ccx_unc_to_par()/ccx_adopt_mode_band(), which named a
  # STORED u_mode with the LIVE CCX_PARAM_NAMES -- fine until the parameter set
  # moves, then a bare "names attribute must be the same length" from three
  # frames down. Same defect class as the CCX_FORCING_COLS length trap.
  u <- structure(as.list(rep(0, length(CCX_PARAM_NAMES))), names = CCX_PARAM_NAMES)
  expect_named(ccx_unc_to_par(u), CCX_PARAM_NAMES)
  # a vector carrying a name this build retired must say SO, not fall over
  u_old <- u[setdiff(names(u), c("seas_lag_p_NH", "seas_lag_p_SH"))]
  u_old$seas_lag_p <- 0
  expect_error(ccx_unc_to_par(u_old), "different parameter set")
})

test_that("a stored vector ENCODES with a named refusal, not an index from vapply", {
  # The MIRROR of the test above, and the half left unhardened on 2026-08-31.
  # ccx_par_to_unc() iterates the BUILD's names, so a 21-parameter par_mode hit
  # .to_unc(NULL, ...) and died as "values must be length 1, but FUN(X[[12]])
  # result is length 0". That is the WARM-START path of the owed 22-parameter
  # refit: the failure would have arrived seconds into a 14 h run, naming an
  # index and no cause.
  # ⚠ the FITTED list, not ccx_default_params(): the two carry different names
  # and merging them silently drops bomb_total/luc_scale (memory
  # ccx_two_param_lists). Encoding is defined on the fitted set.
  p <- ccx_mode_params(ccx_mode_free_name())   # a FREE file: an ancestor built from the PINNED canonical would carry the shim at 0 and not encode (09-13 (d))
  p_old <- p[setdiff(names(p), c("seas_lag_p_NH", "seas_lag_p_SH"))]
  p_old$seas_lag_p <- 1.7502

  err <- tryCatch(ccx_par_to_unc(p_old), error = conditionMessage)
  expect_match(err, "different parameter set")
  expect_match(err, "seas_lag_p_NH")
  expect_match(err, "seas_lag_p_SH")
})

test_that("ccx_migrate_par_set reproduces the LEGACY reading exactly", {
  # The migration must not hold its own opinion about what an absent split
  # means -- it reads ccx_seas_lag_p(), the one resolver both cores go through.
  # So a migrated legacy list must encode IDENTICALLY to one whose hemispheres
  # were set to the legacy scalar by hand. Not "close": identical.
  # ⚠ ccx_mode_params() is a POST-split 31-parameter list -- the canonical
  # carries seas_lag_p_NH/SH AND the four gamma_enso_* names (this comment said
  # it predated both splits until 2026-09-12) -- so "an ancestor current in every
  # other respect" has to be CONSTRUCTED from it by dropping the pair, or this
  # test has nothing to migrate.
  # UPDATED 2026-09-01: it used to migrate straight from ccx_mode_params(), which
  # made `migrated` exactly the lag pair only while the lag was the ONLY split.
  p <- ccx_migrate_par_set(ccx_mode_params(ccx_mode_free_name())); attr(p, "migrated") <- NULL
  p_old <- p[setdiff(names(p), c("seas_lag_p_NH", "seas_lag_p_SH"))]
  p_old$seas_lag_p <- 1.7502

  mig <- ccx_migrate_par_set(p_old)
  expect_setequal(attr(mig, "migrated"), c("seas_lag_p_NH", "seas_lag_p_SH"))
  expect_identical(mig$seas_lag_p_NH, 1.7502)
  expect_identical(mig$seas_lag_p_SH, 1.7502)

  p_hand <- p_old
  p_hand$seas_lag_p_NH <- p_hand$seas_lag_p_SH <- 1.7502
  expect_identical(ccx_par_to_unc(mig), ccx_par_to_unc(p_hand))

  p_cur <- mig; attr(p_cur, "migrated") <- NULL
  expect_identical(attr(ccx_migrate_par_set(p_cur), "migrated"), character(0))
})

test_that("migration REFUSES a list that carries no lag at all", {
  # Filling from CCX_SEAS_LAG_P_DEFAULT would turn a warm start into an
  # invented coordinate wearing a fitted vector's name.
  p <- ccx_migrate_par_set(ccx_mode_params(ccx_mode_free_name())); attr(p, "migrated") <- NULL
  p_none <- p[setdiff(names(p), c("seas_lag_p_NH", "seas_lag_p_SH", "seas_lag_p"))]
  expect_error(ccx_migrate_par_set(p_none), "not a fitted ancestor")
})

test_that("the REAL 08-30 arm files MIGRATE, and REFUSE to encode", {
  # ⛔ THE ENCODE ASSERTION IS GONE, 2026-09-04. This read
  #     u <- ccx_par_to_unc(mig); expect_true(all(is.finite(u)))
  # and called it "the end-to-end claim the refit rests on". It stopped being
  # true the moment `ent_seas_amp_SH` was freed (25 -> 26, `88ee23c`): a 21-par
  # ancestor migrates to `ent_seas_amp_SH = 0`, and 0 has NO IMAGE under
  # `tr = "log"`. The vector can be RUN and MEASURED at; it is not a point of
  # the FITTED space, and under a lognormal prior it has probability ZERO --
  # so asserting it encodes was asserting something FALSE about the model, not
  # something true about the migration. [[runnable_is_not_encodable]]
  #
  # ⭐ WHAT REPLACES IT IS THE OPPOSITE ASSERTION, and it is a real one: the
  # encoder must REFUSE, and refuse BY NAME. That guard was hardened on purpose
  # on 09-03 (`ccx_par_to_unc()` reports the offending coordinate rather than
  # returning a silent -Inf), and nothing was testing it.
  #
  # MIGRATION -- this file's actual subject -- is asserted exactly as before.
  root <- file.path(.root, "calibration/output/refit_20260830_gamma_diff_remap")
  for (arm in c("from90", "pin90")) {
    f <- file.path(root, arm, "mode_fit_pumpN.rds")
    if (!file.exists(f)) { skip(paste("no", arm, "arm file")) }
    prev <- readRDS(f)
    expect_length(prev$param_names, 21L)
    mig <- ccx_migrate_par_set(prev$par_mode)
    expect_length(intersect(names(mig), CCX_PARAM_NAMES), length(CCX_PARAM_NAMES))
    # the legacy contract: BOTH hemispheres take the stored scalar
    expect_identical(mig$seas_lag_p_NH, prev$par_mode$seas_lag_p)
    expect_identical(mig$seas_lag_p_SH, prev$par_mode$seas_lag_p)
    # ...and the migrated vector is RUNNABLE but NOT ENCODABLE, by name.
    expect_identical(mig$ent_seas_amp_SH, 0)
    expect_error(ccx_par_to_unc(mig), "ent_seas_amp_SH")
    # SEEDED at its table init, the same vector encodes finitely -- which is the
    # separation `ccx_seed_unencodable()` exists to make: the migration says what
    # the ancestor RAN, the seeder says where a SEARCH begins.
    seeded <- mig; seeded$ent_seas_amp_SH <- CCX_PARAM_TABLE$ent_seas_amp_SH$init
    expect_true(all(is.finite(ccx_par_to_unc(seeded))))
  }
})
