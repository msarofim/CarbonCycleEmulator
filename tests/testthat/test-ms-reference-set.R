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
#   (10) a PRICE arm (2026-10-04, Marcus: "Canonical incumbent, Mac (Recommended)"):
#       the canonical's pins + ONE RULED name the structure READS (CCX_MS_PRICE_ARM_NAMES),
#       held -> the canonical (seeded at the pin) / the control; MUTATION: refused at
#       seas_ml 0, for an UNRULED read name (q10; (2)'s pump_grad stays refused), with
#       two held names, and with a canonical pin moved
# =====================================================================
ms_cp <- CCX_MODE_CANONICAL_PINS
ms_ctl <- CCX_MODE_CONTROL_PINS

test_that("the control's pin set is the canonical's without the shim, and the control is registered and FREE", {
  expect_true(!is.null(ms_cp) && "ent_seas_amp_SH" %in% names(ms_cp))
  # 2026-09-20 (r): the canonical is the LIMB arm (fits w_enso_l2, pins the ocean ENSO pair); the
  # control has no limb (holds w_enso_l2 = 0) and fits the pair: the two sets differ by exactly those
  expect_setequal(setdiff(names(ms_cp), names(ms_ctl)), c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH"))
  expect_identical(setdiff(names(ms_ctl), names(ms_cp)), "w_enso_l2")
  shared <- intersect(names(ms_ctl), names(ms_cp)); expect_equal(unname(ms_ctl[shared]), unname(ms_cp[shared]))
  expect_true(CCX_MODE_SEASML0_CONTROL %in% names(CCX_MODE_FILES))
  expect_false(CCX_MODE_PINNED[[CCX_MODE_SEASML0_CONTROL]], info = "the control is a FREE arm (its shim is fitted)")
  md <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL))
  expect_true(is.finite(md$par_mode[["ent_seas_amp_SH"]]) && md$par_mode[["ent_seas_amp_SH"]] > 0,
              info = "the control CARRIES the shim, non-zero")
  expect_identical(ccx_mode_base(md)$seas_ml, 0L)                     # the base through ccx_mode_base(): seas_ml OFF
})

test_that("the five branches return the ruled pairs", {
  withr::local_envvar(CCX_MS_STRUCT = ccx_mode_struct(readRDS(ccx_mode_file())), CCX_MS_PUMP_FIELD = "solved")   # the canonical's OWN structure (09-20 r: hilda_csl3)
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
  # 09-18: the control's pins EXTENDED by the limb's name (inert without the limb) were the control's arm;
  # 09-19 (m): the limb's name is now IN the canonical's (and so the control's) pins, so the same call is
  # the base set itself -- and under a structure WITH the limb that held name is not inert: refused
  expect_true("w_enso_l2" %in% names(ms_ctl))
  # ... and a pin set that IS a registered set resolves under any structure (same() reads no struct): under
  # hilda_cl3 the control's pins hold the limb OFF -- a limb-less arm by pin, the free parent's, not refused
  r5c <- ccx_ms_reference_set(ms_ctl, "1", struct = "hilda_cl3"); expect_identical(r5c, r5)
  for (r in list(r1, r2, r3, r4, r5)) {
    expect_true(all(c(r$incumbent, r$new_basin) %in% names(CCX_MODE_FILES)))
    expect_false(identical(r$incumbent, r$new_basin), info = "ids 1 and 2 must be different points")
  }
})

test_that("MUTATION: a foreign pin set, a moved shim value, and a bad seas_ml are refused by name", {
  withr::local_envvar(CCX_MS_STRUCT = ccx_mode_struct(readRDS(ccx_mode_file())), CCX_MS_PUMP_FIELD = "solved")   # the canonical's OWN structure (09-20 r: hilda_csl3)
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
  # 09-20 (r): the limb's arm IS the canonical's (hilda29l fits w_enso_l2 and pins the pair)
  expect_identical(ms_l2, ms_cp)
  expect_false("w_enso_l2" %in% names(ms_l2)); expect_true(all(c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH") %in% names(ms_l2)))
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
  # (09-20 r: the refusal is now the general one -- a pin set that leaves an inert name FREE)
  expect_error(ccx_ms_reference_set(ms_l2, "1", struct = "hilda_c"), "no layer-2 limb")
  expect_error(ccx_ms_reference_set(ms_l2, "1", struct = "hilda"), "no layer-2 limb")
  # the control's pins under a limb structure hold w_enso_l2 OFF -- allowed (nothing inert is free)
  expect_silent(ccx_ms_reference_set(ms_ctl, "0", struct = "hilda_cl2"))
  # (09-20 r: the limb's arm at seas_ml 0 resolves through the canonical branch now -- the seas_ml-1
  # prereg refusal lived in the L2 branch, which the canonical's own pins no longer reach)
  r8c <- ccx_ms_reference_set(ms_l2, "0", struct = "hilda_cl2"); expect_identical(r8c$incumbent, CCX_MODE_CANONICAL)
  # MUTATION: the shim pinned at a non-zero value is not the limb's arm
  moved <- ms_l2; moved[["gamma_enso_ocn_NH"]] <- 0.36
  expect_error(ccx_ms_reference_set(moved, "1", struct = "hilda_cl2"), "no registered incumbent")
  # the canonical's own pins under hilda_cl2 still take the canonical (the limb's name
  # is then FREE with the shim free too -- a legal, if unpreregistered, structure arm)
  r8c <- ccx_ms_reference_set(ms_cp, "1", struct = "hilda_cl2")
  expect_identical(r8c$incumbent, CCX_MODE_CANONICAL)
})

test_that("(9) the FREE PARENT of the limb canonical (2026-09-21 g): the six inert pins only, under a structure WITH the limb at seas_ml 1 -> the canonical / the control; refused without the limb and at seas_ml 0", {
  fp <- CCX_MODE_FREE_PARENT_PINS
  expect_setequal(names(fp), setdiff(names(CCX_MODE_CONTROL_PINS), "w_enso_l2"))           # the control's minus the limb's name
  expect_setequal(names(fp), setdiff(names(CCX_MODE_CANONICAL_PINS), c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH")))   # the canonical's minus its three real pins
  expect_equal(unname(fp), unname(CCX_MODE_CANONICAL_PINS[names(fp)]))
  r9 <- ccx_ms_reference_set(fp, "1", struct = "hilda_csl3")
  # 09-22 (k): the parent is registered (hilda32f) and is its own incumbent; the canonical seeded the wave that made it
  expect_identical(r9$incumbent, CCX_MODE_PINNED_PARENT); expect_identical(r9$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_identical(CCX_MODE_PINNED_PARENT, "hilda32f"); expect_false(CCX_MODE_PINNED[["hilda32f"]])
  expect_match(r9$why, "FREE PARENT")
  # MUTATION: without the limb it is not this parent; at seas_ml 0 it is not a ruled arm
  expect_error(ccx_ms_reference_set(fp, "1", struct = "hilda_cs"), "no layer-2 limb")
  expect_error(ccx_ms_reference_set(fp, "0", struct = "hilda_csl3"), "seas_ml 0 is not a ruled arm")
  # MUTATION: one inert pin moved is a foreign set
  moved <- fp; moved[["w_eq"]] <- 30
  expect_error(ccx_ms_reference_set(moved, "1", struct = "hilda_csl3"), "no registered incumbent")
})

test_that("(10) a PRICE arm (2026-10-04): the canonical's pins + ONE read name held -> the canonical (seeded) / the control; refused at seas_ml 0, with two held names, a moved canonical pin, or a non-parameter", {
  withr::local_envvar(CCX_MS_STRUCT = ccx_mode_struct(readRDS(ccx_mode_file())), CCX_MS_PUMP_FIELD = "solved")
  kw <- c(ms_cp, k_w = ccx_const("KW_PRIOR_CENTRE"))           # the first use: Naegler 2009's 1446 m/yr
  expect_false(ccx_pins_extend_canonical(kw, "solved"), info = "k_w is READ: not an inert extension")
  expect_true(ccx_pins_price_canonical(kw, "solved"))
  r10 <- ccx_ms_reference_set(kw, "1")
  expect_identical(r10$incumbent, CCX_MODE_CANONICAL); expect_identical(r10$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_match(r10$why, "PRICE arm.*k_w held at 1446")
  # MUTATION: only on the canonical's own objective (seas_ml 1)
  expect_error(ccx_ms_reference_set(kw, "0"), "PRICE arm")
  # MUTATION: an UNRULED read name is not a price arm (each name is added by a ruling)
  expect_false("q10" %in% CCX_MS_PRICE_ARM_NAMES)
  expect_false(ccx_pins_price_canonical(c(ms_cp, q10 = 2), "solved"))
  expect_error(ccx_ms_reference_set(c(ms_cp, q10 = 2), "1"), "no registered incumbent")
  # MUTATION: two held READ names price no single value
  expect_false(ccx_pins_price_canonical(c(kw, q10 = 2), "solved"))
  expect_error(ccx_ms_reference_set(c(kw, q10 = 2), "1"), "no registered incumbent")
  # MUTATION: a canonical pin moved is another objective
  moved <- kw; moved[["w_eq"]] <- 30
  expect_error(ccx_ms_reference_set(moved, "1"), "no registered incumbent")
  # MUTATION: a name that is no parameter of the build
  expect_false(ccx_pins_price_canonical(c(ms_cp, not_a_parameter = 1), "solved"))
  # an INERT extension still takes the first branch, as before
  inert1 <- setdiff(ccx_inert_names("solved", Sys.getenv("CCX_MS_STRUCT")), names(ms_cp))
  if (length(inert1)) {
    ri <- ccx_ms_reference_set(c(ms_cp, stats::setNames(0, inert1[1])), "1")
    expect_identical(ri$why, "the canonical, under this array's pins")
  }
})
