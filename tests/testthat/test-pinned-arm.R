# =====================================================================
# test-pinned-arm.R -- a PIN holds a fitted name at a value and removes it from
# the fitted set (2026-09-13, for C': ent_seas_amp_SH pinned to 0).
#   (1) parse: name=value, several, bad forms error, empty = no pins
#   (2) apply/unpin: the set shrinks by exactly the pinned names, every consumer
#       sees the reduced set, unpin restores the ORIGINAL order (mode files'
#       param_names depend on it), and pinning an unknown name errors
#   (3) IDENTITY WITH POWER: the objective on the reduced set, with the shim
#       pinned AT THE CANONICAL'S OWN FITTED VALUE, reproduces the canonical's
#       stored LIKELIHOOD (streams) to 1e-6 -- and pinned at 0 it does NOT.
#       The pinned arm's logpost is NOT comparable (no prior term for the held
#       name): the test asserts that too, so nobody reads it as a comparison.
#   ⚠ (3) needs a FREE file that CARRIES the shim (2026-09-13, the promotion of
#       C' made the canonical itself the pinned arm): it reads the registered
#       free PARENT when the canonical is pinned, else the canonical.
# =====================================================================
# the free 31-name file the identity test is run against
pa_free_file <- function() ccx_mode_file(
  if (!is.null(CCX_MODE_PINNED_PARENT)) CCX_MODE_PINNED_PARENT else CCX_MODE_CANONICAL)

test_that("ccx_parse_pins reads name=value specs and refuses bad ones", {
  expect_null(ccx_parse_pins(""))
  expect_null(ccx_parse_pins(NA))
  expect_equal(ccx_parse_pins("ent_seas_amp_SH=0"), c(ent_seas_amp_SH = 0))
  expect_equal(ccx_parse_pins(" q10 = 2.1 , h_ml=60 "), c(q10 = 2.1, h_ml = 60))
  expect_error(ccx_parse_pins("ent_seas_amp_SH"), "name=value")
  expect_error(ccx_parse_pins("ent_seas_amp_SH=zero"), "non-numeric")
  expect_identical(ccx_pin_label(NULL), "")
  expect_identical(ccx_pin_label(c(ent_seas_amp_SH = 0)), "_pin_ent_seas_amp_SH=0")
})

test_that("ccx_apply_pins shrinks the fitted set for EVERY consumer, and ccx_unpin_params restores the original order", {
  n0 <- length(CCX_PARAM_NAMES); nm0 <- CCX_PARAM_NAMES
  expect_true("ent_seas_amp_SH" %in% nm0)
  rm <- ccx_apply_pins(c(ent_seas_amp_SH = 0))
  on.exit(ccx_unpin_params(rm), add = TRUE)
  expect_length(CCX_PARAM_NAMES, n0 - 1L)
  expect_false("ent_seas_amp_SH" %in% CCX_PARAM_NAMES)
  expect_false("ent_seas_amp_SH" %in% names(CCX_PARAM_TABLE))
  expect_equal(CCX_PINS, c(ent_seas_amp_SH = 0))
  # the consumers
  expect_length(ccx_init_unc(), n0 - 1L)
  md <- readRDS(pa_free_file())
  u <- ccx_par_to_unc(md$par_mode)            # the extra name in the file is simply ignored
  expect_length(u, n0 - 1L); expect_true(all(is.finite(u)))
  expect_false("ent_seas_amp_SH" %in% names(ccx_unc_to_par(u)))
  # unknown name errors; a base parameter is not a fitted name
  expect_error(ccx_apply_pins(c(seas_ml = 1)), "not a fitted parameter")
  expect_error(ccx_apply_pins(c(1, 2)), "NAMED")
  ccx_unpin_params(rm); on.exit()               # restore now, and check the ORDER
  expect_identical(CCX_PARAM_NAMES, nm0)
  expect_identical(names(CCX_PARAM_TABLE), nm0)
  expect_null(CCX_PINS)
})

test_that("pinned AT a free file's fitted shim the streams REPRODUCE; pinned at 0 they do not; the logpost is not comparable", {
  skip_if_no_cpp()
  md <- readRDS(pa_free_file())
  fitted <- md$par_mode$ent_seas_amp_SH
  expect_true(is.numeric(fitted) && fitted > 0)   # a FREE file carries the shim
  score <- function(pin) {
    rm <- ccx_apply_pins(c(ent_seas_amp_SH = pin)); on.exit(ccx_unpin_params(rm), add = TRUE)
    bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode; bp$ent_seas_amp_SH <- pin
    v <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                          spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(ccx_par_to_unc(md$par_mode))
    list(lp = as.numeric(v), st = attr(v, "streams"))
  }
  at_fit <- score(fitted); at_0 <- score(0)
  st0 <- unlist(md$streams)
  # identity on the LIKELIHOOD, at the fitted value
  expect_equal(sum(at_fit$st[names(st0)]), sum(st0), tolerance = 1e-6, scale = 1)
  expect_lt(max(abs(at_fit$st[names(st0)] - st0)), 1e-5)   # per row; the sum is at 1e-6 (the mode file was stamped through by_stream = TRUE, ~1e-6 per row)
  # ...and NOT on the logpost: the held name's own prior term is gone
  expect_false(isTRUE(all.equal(at_fit$lp, md$logpost, tolerance = 1e-6)))
  # POWER: pinned at 0 the likelihood MOVES (the shim was fitted, so removing it costs)
  expect_gt(abs(sum(at_0$st[names(st0)]) - sum(st0)), 0.5)
  expect_lt(sum(at_0$st[names(st0)]), sum(st0))
  # and the fitted set is intact afterwards
  expect_true("ent_seas_amp_SH" %in% CCX_PARAM_NAMES)
})
