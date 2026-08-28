# The canonical mode's `u_mode` does NOT decode to its own `par_mode` under the
# SHIPPED CCX_PARAM_TABLE, because the pump refits override `h_ml`'s logit band
# in process. That is not a bug in the refit -- the band is a property of the
# refit -- but it silently gave every diagnostic an 11 % shallower mixed layer.
# These tests pin the accessor and the gate that now catch it. See the note
# above ccx_mode_params() in R/paths.R.

test_that("ccx_mode_params returns the depth the refit actually found", {
  md <- readRDS(ccx_mode_file())
  expect_equal(ccx_mode_params(md)$h_ml, md$par_mode[["h_ml"]], tolerance = 1e-10)
})

test_that("the band-blind idiom really is wrong, and only for h_ml", {
  md <- readRDS(ccx_mode_file())
  u <- md$u_mode; names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  differing <- Filter(function(n) {
    a <- pv[[n]]; b <- md$par_mode[[n]]
    is.numeric(a) && is.numeric(b) && length(a) == 1L && length(b) == 1L &&
      abs(a - b) > 1e-8 * max(abs(b), 1e-12)
  }, intersect(names(pv), names(md$par_mode)))
  # If this ever grows past h_ml, a SECOND parameter has acquired an in-process
  # band override and ccx_mode_params()'s fallback branch needs to learn about it.
  expect_identical(differing, "h_ml")
  expect_gt(abs(pv$h_ml - md$par_mode[["h_ml"]]), 10)   # ~10.74 m, not roundoff
})

test_that("ccx_check_mode_decode ERRORS rather than warning", {
  expect_error(ccx_check_mode_decode(), "does NOT decode to its own stored par_mode")
  # and it must pass when there is nothing to check against
  expect_true(ccx_check_mode_decode(list(u_mode = rep(0, length(CCX_PARAM_NAMES)))))
})

test_that("decoding under the recorded band reduces the mode's logpost offset", {
  md <- readRDS(ccx_mode_file())
  i <- match("h_ml", CCX_PARAM_NAMES)
  inv <- function(u, lo, hi) lo + (hi - lo) / (1 + exp(-u))
  # the recorded band reproduces par_mode; the shipped one does not
  expect_equal(unname(inv(md$u_mode[i], md$hml_bound[1], md$hml_bound[2])),
               md$par_mode[["h_ml"]], tolerance = 1e-8)
  expect_false(isTRUE(all.equal(unname(inv(md$u_mode[i], CCX_PARAM_TABLE$h_ml$lo,
                                          CCX_PARAM_TABLE$h_ml$hi)),
                                md$par_mode[["h_ml"]], tolerance = 1e-6)))
})
