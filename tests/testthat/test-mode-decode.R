# A mode file's `u_mode` is MEANINGLESS WITHOUT ITS BAND: the 2026-08 pump
# refits overrode `h_ml`'s logit band IN PROCESS, so decoding their `u_mode`
# under the SHIPPED CCX_PARAM_TABLE silently gave every diagnostic an 11 %
# shallower mixed layer. These tests pin the accessor and the gate that catch
# it. See the note above ccx_mode_params() in R/paths.R.
#
# ⭐ RESTRUCTURED 2026-09-04, AND THE REASON IS A RESULT. Until the `ent26`
# adoption all four assertions here were taken AT THE CANONICAL MODE, because
# the canonical mode HAD an override. `ent26` was fitted on the shipped support
# [30, 200] with no override at all, so its `u_mode` decodes to its `par_mode`
# exactly -- 134.150 m either way -- and every assertion that the trap is
# PRESENT became false at once.
#
# ⛔ THE WRONG REPAIR IS TO DELETE THEM. The trap-handling code in
# ccx_mode_params() / ccx_mode_bands() / ccx_check_mode_decode() is still live,
# still correct, and would then be exercised by NOTHING -- a mechanism that is
# off in every live file is untested exactly where it matters
# ([[default_off_hides_the_bug]]). So the trap half now runs against an EXPLICIT
# fixture carrying a band override, and the canonical file gets the assertion
# that is actually true of it: that it decodes cleanly.

# A mode file that WAS fitted under an overridden band, built from the canonical
# one so it stays a real file in every other respect. The band is the RETIRED
# [85, 120] the 08-25f pump refits genuinely used -- not an invented pair -- and
# `par_mode$h_ml` is set to what `u_mode` DECODES to under it, so the fixture is
# internally consistent in the same way a real overridden file is.
MD_OVERRIDE_BAND <- c(85, 120)
md_overridden <- local({
  md <- readRDS(ccx_mode_file())
  i  <- match("h_ml", md$param_names)   # the FILE's own names: a pinned file's u_mode is shorter than the table (09-13 (d))
  b  <- MD_OVERRIDE_BAND
  md$hml_bound <- b
  md$par_mode[["h_ml"]] <- unname(b[1] + (b[2] - b[1]) / (1 + exp(-md$u_mode[i])))
  md
})

test_that("the FIXTURE really is a mis-decoding file -- or nothing below is tested", {
  # MUTATION GUARD ON THE FIXTURE ITSELF. If the constructed band ever coincides
  # with the shipped one, every "the trap is caught" assertion below passes
  # vacuously. Asserted, not assumed.
  expect_false(isTRUE(all.equal(MD_OVERRIDE_BAND,
                               c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi))))
  i <- match("h_ml", md_overridden$param_names)
  u <- md_overridden$u_mode; names(u) <- md_overridden$param_names
  expect_gt(abs(ccx_unc_to_par(u)[["h_ml"]] - md_overridden$par_mode[["h_ml"]]), 10)
})

test_that("ccx_mode_params returns the depth the refit actually found", {
  # Both files, because the function has two branches and they are reached by
  # different inputs: `par_mode` present is an early return, absent goes through
  # the band-restoring path that is the whole point of the accessor.
  for (md in list(readRDS(ccx_mode_file()), md_overridden)) {
    expect_equal(ccx_mode_params(md)$h_ml, md$par_mode[["h_ml"]], tolerance = 1e-10)
    stripped <- md; stripped$par_mode <- NULL
    expect_equal(ccx_mode_params(stripped)$h_ml, md$par_mode[["h_ml"]],
                 tolerance = 1e-8)
  }
})

test_that("the band-blind idiom really is wrong, and only for h_ml", {
  u <- md_overridden$u_mode; names(u) <- md_overridden$param_names
  pv <- ccx_unc_to_par(u)
  differing <- Filter(function(n) {
    a <- pv[[n]]; b <- md_overridden$par_mode[[n]]
    is.numeric(a) && is.numeric(b) && length(a) == 1L && length(b) == 1L &&
      abs(a - b) > 1e-8 * max(abs(b), 1e-12)
  }, intersect(names(pv), names(md_overridden$par_mode)))
  # If this ever grows past h_ml, a SECOND parameter has acquired an in-process
  # band override and ccx_mode_params()'s fallback branch needs to learn about it.
  expect_identical(differing, "h_ml")
  expect_gt(abs(pv$h_ml - md_overridden$par_mode[["h_ml"]]), 10)
})

test_that("ccx_check_mode_decode ERRORS on a mis-decoding file", {
  expect_error(ccx_check_mode_decode(md_overridden),
               "does NOT decode to its own stored par_mode")
  # and it must pass when there is nothing to check against
  expect_true(ccx_check_mode_decode(list(u_mode = rep(0, length(CCX_PARAM_NAMES)))))
})

test_that("the CANONICAL mode decodes cleanly UNDER ITS RECORDED BAND; band-blind it does NOT, since the 09-16 floor", {
  # Until 2026-09-16 (b) this asserted that the canonical was fitted on the
  # SHIPPED band, so the band-blind idiom happened to be right for it. The h_ml
  # floor then moved 30 -> 42.5 m (CCX_HML_FLOOR_M) and every file fitted before
  # it records the OLD band -- so the band-blind decode of the canonical's
  # u_mode is now wrong by ~15 % in h_ml, exactly the trap this file exists to
  # kill, and the invariant is the stronger one: the recorded band is honored
  # (ccx_mode_params(), ccx_adopt_mode_band()) and the band-blind check ERRORS
  # rather than passing quietly. A future refit ON the shipped band records it
  # and takes the first branch.
  md <- readRDS(ccx_mode_file())
  ship <- c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)
  expect_equal(ccx_mode_params(md)[["h_ml"]], md$par_mode[["h_ml"]], tolerance = 1e-8)
  if (isTRUE(all.equal(md$hml_bound, ship))) {
    expect_true(ccx_check_mode_decode(md))
  } else {
    expect_error(ccx_check_mode_decode(md), "does NOT decode to its own stored par_mode")
    old <- ccx_adopt_mode_band(md)
    on.exit(for (nm in names(old)) CCX_PARAM_TABLE[[nm]] <<- old[[nm]], add = TRUE)
    expect_true(ccx_check_mode_decode(md))
    u <- md$u_mode; names(u) <- md$param_names
    expect_equal(ccx_unc_to_par(u)[["h_ml"]], md$par_mode[["h_ml"]], tolerance = 1e-8)
  }
})

test_that("decoding under the recorded band is what reproduces par_mode", {
  md <- md_overridden
  i <- match("h_ml", md$param_names)
  # ⚠ THROUGH THE CODE'S OWN TRANSFORM, not a formula typed here. Until
  # 2026-09-12 this block decoded with a local `inv()` that was the SAME formula
  # the fixture above is built with, so its first assertion could not fail
  # (review A15). `.from_unc()` is the decoder ccx_unc_to_par() applies: fed the
  # RECORDED band it must reproduce par_mode, and on the SHIPPED table it must not.
  s_rec <- CCX_PARAM_TABLE$h_ml; s_rec$lo <- md$hml_bound[1]; s_rec$hi <- md$hml_bound[2]
  expect_equal(unname(.from_unc(md$u_mode[i], s_rec)), md$par_mode[["h_ml"]], tolerance = 1e-8)
  u <- md$u_mode; names(u) <- md$param_names
  expect_false(isTRUE(all.equal(ccx_unc_to_par(u)[["h_ml"]], md$par_mode[["h_ml"]],
                                tolerance = 1e-6)))
})
