# =====================================================================
# test-ms-reference-set.R -- the dispersed multistart's REFERENCE SET is ONE rule
# (ccx_ms_reference_set, 2026-09-17 j), read by the driver and by
# make_port_targets.R; the two used to carry copies under a MUST-MATCH comment.
#   (1) the canonical's pins -> incumbent the canonical, new basin the control
#   (2) pins EXTENDING the canonical's by inert names -> the same
#   (3) no pins -> the free parent (the canonical is pinned) / the control
#   (4) the CONTROL's pins at seas_ml 0 -> the control / the free parent  (the
#       control refit's arm: the shim FREE -- a control with the shim pinned and
#       the ML off has no SPO seasonal mechanism, -368 by construction)
#   (5) the CONTROL's pins at seas_ml 1 -> the free parent / the control
#   (6) MUTATION: any other pin set, and the canonical's pins with the shim at a
#       different value, are REFUSED by name; seas_ml must be 0/1
#   (7) every name the rule returns is registered and the two differ
#   (8) the LAYER-2 LIMB's pins (2026-09-17 k: the canonical's + the shim at 0)
#       under a structure WITH the limb at seas_ml 1 -> the canonical / the
#       control; MUTATION: refused under a structure WITHOUT the limb (the shim
#       off and nothing in its place) and at seas_ml 0
# =====================================================================
ms_cp <- CCX_MODE_CANONICAL_PINS
ms_ctl <- CCX_MODE_CONTROL_PINS

test_that("the control's pin set is the canonical's without the shim, and the control is registered and FREE", {
  expect_true(!is.null(ms_cp) && "ent_seas_amp_SH" %in% names(ms_cp))
  expect_identical(names(ms_ctl), setdiff(names(ms_cp), "ent_seas_amp_SH"))
  expect_equal(unname(ms_ctl), unname(ms_cp[names(ms_ctl)]))
  expect_true(CCX_MODE_SEASML0_CONTROL %in% names(CCX_MODE_FILES))
  expect_false(CCX_MODE_PINNED[[CCX_MODE_SEASML0_CONTROL]], info = "the control is a FREE arm (its shim is fitted)")
  md <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL))
  expect_true(is.finite(md$par_mode[["ent_seas_amp_SH"]]) && md$par_mode[["ent_seas_amp_SH"]] > 0,
              info = "the control CARRIES the shim, non-zero")
  expect_identical(ccx_mode_base(md)$seas_ml, 0L)                     # the base through ccx_mode_base(): seas_ml OFF
})

test_that("the five branches return the ruled pairs", {
  withr::local_envvar(CCX_MS_STRUCT = "hilda_c", CCX_MS_PUMP_FIELD = "solved")
  r1 <- ccx_ms_reference_set(ms_cp, "1")
  expect_identical(r1$incumbent, CCX_MODE_CANONICAL); expect_identical(r1$new_basin, CCX_MODE_SEASML0_CONTROL)
  r1b <- ccx_ms_reference_set(ms_cp, "0")          # the canonical's pins at seas_ml 0: still the canonical
  expect_identical(r1b$incumbent, CCX_MODE_CANONICAL)
  # a REAL extension: under the martin field `pump_grad` is inert (the E array's case)
  r2 <- ccx_ms_reference_set(c(ms_cp, pump_grad = 314.1031), "1", pump_field = "martin")
  expect_identical(r2$incumbent, CCX_MODE_CANONICAL)
  expect_error(ccx_ms_reference_set(c(ms_cp, pump_grad = 314.1031), "1", pump_field = "solved"),
               "no registered incumbent")   # not inert under the solved field
  r3 <- ccx_ms_reference_set(NULL, "1")
  expect_identical(r3$incumbent, CCX_MODE_PINNED_PARENT); expect_identical(r3$new_basin, CCX_MODE_SEASML0_CONTROL)
  r4 <- ccx_ms_reference_set(ms_ctl, "0")
  expect_identical(r4$incumbent, CCX_MODE_SEASML0_CONTROL); expect_identical(r4$new_basin, CCX_MODE_PINNED_PARENT)
  r5 <- ccx_ms_reference_set(ms_ctl, "1")
  expect_identical(r5$incumbent, CCX_MODE_PINNED_PARENT); expect_identical(r5$new_basin, CCX_MODE_SEASML0_CONTROL)
  # 09-18: the control's pins EXTENDED by the limb's name (inert without the limb) are still the control's arm
  r5b <- ccx_ms_reference_set(c(ms_ctl, w_enso_l2 = 0), "1"); expect_identical(r5b, r5)
  r4b <- ccx_ms_reference_set(c(ms_ctl, w_enso_l2 = 0), "0"); expect_identical(r4b, r4)
  expect_error(ccx_ms_reference_set(c(ms_ctl, w_enso_l2 = 0), "1", struct = "hilda_cl3"), "no registered incumbent")   # not inert WITH the limb
  for (r in list(r1, r2, r3, r4, r5)) {
    expect_true(all(c(r$incumbent, r$new_basin) %in% names(CCX_MODE_FILES)))
    expect_false(identical(r$incumbent, r$new_basin), info = "ids 1 and 2 must be different points")
  }
})

test_that("MUTATION: a foreign pin set, a moved shim value, and a bad seas_ml are refused by name", {
  withr::local_envvar(CCX_MS_STRUCT = "hilda_c", CCX_MS_PUMP_FIELD = "solved")
  expect_error(ccx_ms_reference_set(c(q10 = 2), "0"), "no registered incumbent")
  moved <- ms_cp; moved[["ent_seas_amp_SH"]] <- 5
  expect_error(ccx_ms_reference_set(moved, "1"), "no registered incumbent")
  # the control's pins WITH a stray extra name that is NOT inert is not the control's arm
  expect_error(ccx_ms_reference_set(c(ms_ctl, q10 = 2), "0"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(ms_ctl, NA_character_), "must be 0")
  expect_error(ccx_ms_reference_set(ms_ctl, "2"), "must be 0")
})

test_that("the layer-2 limb's arm: the canonical / the control under hilda_cl2 at seas_ml 1; refused without the limb or at seas_ml 0", {
  ms_l2 <- CCX_MODE_L2_ARM_PINS
  expect_identical(names(ms_l2), c(names(ms_cp), "gamma_enso_ocn_NH", "gamma_enso_ocn_SH"))
  expect_equal(unname(ms_l2[names(ms_cp)]), unname(ms_cp))
  expect_equal(unname(ms_l2[c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH")]), c(0, 0))
  withr::local_envvar(CCX_MS_STRUCT = "hilda_cl2", CCX_MS_PUMP_FIELD = "solved")
  r8 <- ccx_ms_reference_set(ms_l2, "1")
  expect_identical(r8$incumbent, CCX_MODE_CANONICAL); expect_identical(r8$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_true(all(c(r8$incumbent, r8$new_basin) %in% names(CCX_MODE_FILES)))
  expect_false(identical(r8$incumbent, r8$new_basin))
  # the struct argument, not only the env
  r8b <- ccx_ms_reference_set(ms_l2, "1", struct = "hilda_cl2")
  expect_identical(r8b, r8)
  # MUTATION: the same pins under a structure WITHOUT the limb are an unruled arm
  expect_error(ccx_ms_reference_set(ms_l2, "1", struct = "hilda_c"), "no layer-2 limb")
  expect_error(ccx_ms_reference_set(ms_l2, "1", struct = "hilda"), "no layer-2 limb")
  # MUTATION: the limb's arm at seas_ml 0 is not preregistered
  expect_error(ccx_ms_reference_set(ms_l2, "0", struct = "hilda_cl2"), "seas_ml 1")
  # MUTATION: the shim pinned at a non-zero value is not the limb's arm
  moved <- ms_l2; moved[["gamma_enso_ocn_NH"]] <- 0.36
  expect_error(ccx_ms_reference_set(moved, "1", struct = "hilda_cl2"), "no registered incumbent")
  # the canonical's own pins under hilda_cl2 still take the canonical (the limb's name
  # is then FREE with the shim free too -- a legal, if unpreregistered, structure arm)
  r8c <- ccx_ms_reference_set(ms_cp, "1", struct = "hilda_cl2")
  expect_identical(r8c$incumbent, CCX_MODE_CANONICAL)
})
