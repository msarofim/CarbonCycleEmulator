# =====================================================================
# test-dormant-fixes.R -- the six DORMANT bugs the 2026-10-15 pre-public code review reported
# (CHANGELOG 2026-10-15 (d), "NOT fixed, reported"), each fixed with this file's block as its gate.
#
# "Dormant" = on a path the canonical hilda31w and the app do not run, so no shipped number moves;
# test-canonical-contracts.R and test-parity.R hold that. Each block below FAILS on the pre-fix code
# (measured when written), so each has power. CHANGELOG 2026-10-15 (e).
# =====================================================================

test_that("a PINNED name with no model slot (bomb_total, luc_scale, the four likelihood names) is scored at its pinned value", {
  # ccx_make_logpost() read these six from `pv`, the FITTED names only, so a pinned one was NULL:
  # rep_dC scored as 0 (co2_level_MLO -70.84 -> -662.42 at hilda31w), a pinned grad_off_* dropped
  # its gradient row with nothing said, and a pinned bomb_total stopped in the forcing rebuild.
  skip_if_no_cpp()
  # the six ARE the fitted names the model list has no slot for; a seventh would need the same read
  expect_identical(CCX_NUISANCE_NAMES, setdiff(CCX_PARAM_NAMES, names(ccx_default_params())))
  md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
  expect_false(any(CCX_NUISANCE_NAMES %in% names(md$pins)))   # the canonical pins none of them
  score <- function(extra, in_base = TRUE) {
    pins <- c(md$pins, unlist(md$par_mode[extra]))
    attr(pins, "gate_struct") <- attr(ccx_mode_pins(md), "gate_struct")
    rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
    bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
    if (in_base) for (n in extra) bp[[n]] <- md$par_mode[[n]]
    invisible(utils::capture.output(u <- ccx_mode_start(md, "dormant-fixes")$u))   # its SEEDING notes
    v <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                          spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(u)
    attr(v, "streams")
  }
  st0 <- unlist(md$streams)
  # all six pinned AT the canonical's fitted values: every stored stream row reproduces, and none is lost
  st <- score(CCX_NUISANCE_NAMES)
  expect_true(all(names(st0) %in% names(st)))
  expect_lt(max(abs(st[names(st0)] - st0)), 1e-6)
  expect_true(all(c("co2_gradient", "d13c_gradient") %in% names(st)))
  # rep_dC alone, the case the review measured: the level row is the fitted one, not the rep_dC = 0 one
  st_r <- score("rep_dC")
  expect_equal(st_r[["co2_level_MLO"]], st0[["co2_level_MLO"]], tolerance = 1e-6, scale = 1)
  expect_gt(st_r[["co2_level_MLO"]], -100)
  # a pin whose value the base list does not carry is refused BY NAME, not scored as NULL
  expect_error(score("rep_dC", in_base = FALSE), "rep_dC")
  expect_true(all(CCX_NUISANCE_NAMES %in% CCX_PARAM_NAMES))   # the fitted set is restored
})
