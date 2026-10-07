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
#   (11) OBJECTIVE #16's pins ARE the canonical's since 2026-10-06 (hilda33p adopted; its own
#       branch removed, Marcus: "Remove, re-express its test"): the first branch takes them, the
#       canonical as a MODE; the launch string resolves the same; MUTATION: refused with npp_tsens
#       off 0 and with a canonical pin moved or dropped; #15's nine are refused (no ruled set)
#   (12) OBJECTIVE #17's pins (2026-10-06 n, the interannual cut; Marcus: "Build: land + ocean module
#       (Recommended)"): #16's ten + the module's four at STAGE 1's values, tied bit for bit to the stage-1
#       file, under #17's label at seas_ml 1 -> the canonical (seeded at the pins: a start) / the control;
#       the launch string resolves the same; MUTATION: refused under #16's label, at seas_ml 0, with a module
#       value moved or a module name dropped, and the canonical's ten under #17's label (the module FREE)
#   (13) OBJECTIVE #18's pins (2026-10-07 f, the redesigned cut; Marcus: "Full redesign (Recommended)"): #16's ten +
#       the module's four at stage 1's values UNDER #18 at basin B, tied BIT FOR BIT to the stage-1 file, which is
#       itself the pricing mirror's answer exactly; under #18's label at seas_ml 1 -> #17's basin B, registered
#       `hilda29w` (RULED 10-07 i: "Register B, seed from it (Recommended)"; seeded at the pins: a start) / the
#       control; the launch string resolves the same; MUTATION: refused under #17's label, at seas_ml 0, with a
#       module value moved or dropped, and the ten under #18's label (the module FREE); #17's pins under #18's label
# =====================================================================
ms_cp <- CCX_MODE_CANONICAL_PINS
ms_ctl <- CCX_MODE_CONTROL_PINS

test_that("the control's pin set is the canonical's without the shim, and the control is registered and FREE", {
  expect_true(!is.null(ms_cp) && "ent_seas_amp_SH" %in% names(ms_cp))
  # 2026-09-20 (r): the canonical is the LIMB arm (fits w_enso_l2, pins the ocean ENSO pair); the
  # control has no limb (holds w_enso_l2 = 0) and fits the pair: the two sets differ by exactly those
  # 2026-10-06 (a): + npp_tsens -- the canonical hilda33p pins the greening term (objective #16); the control,
  # on a label that never opens the gate, does not carry it (Marcus 2026-10-06: "Approve all (Recommended)")
  expect_setequal(setdiff(names(ms_cp), names(ms_ctl)), c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "npp_tsens"))
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
  # 2026-10-06 (a): FOUR real pins since hilda33p -- the shim, the pair and npp_tsens (Marcus 2026-10-06: "Approve all (Recommended)")
  expect_setequal(names(fp), setdiff(names(CCX_MODE_CANONICAL_PINS), c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "npp_tsens")))   # the canonical's minus its four real pins
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

test_that("(11) OBJECTIVE #16's pins ARE the canonical's since 2026-10-06 (hilda33p; Marcus: \"Remove, re-express its test\"): the FIRST branch takes them, the canonical as a MODE; npp_tsens off 0, a pin moved or dropped, and #15's nine are refused", {
  withr::local_envvar(CCX_MS_STRUCT = CCX_MODE_OBJ16_STRUCT, CCX_MS_PUMP_FIELD = "solved")
  p16 <- CCX_MODE_OBJ16_PINS
  expect_identical(p16, ms_cp, info = "the canonical holds #16's ten")
  expect_identical(names(p16), c(names(CCX_MODE_OBJ15_PINS), "npp_tsens"))
  expect_identical(p16[["npp_tsens"]], 0)
  expect_identical(p16[["npp_tsens"]], CCX_NPP_TSENS_DEFAULT, info = "the pin IS the term's absent default")
  expect_true(CCX_MODE_OBJ16_STRUCT %in% CCX_STRUCT_LABELS)
  expect_identical(ccx_mode_struct(readRDS(ccx_mode_file())), CCX_MODE_OBJ16_STRUCT, info = "the canonical runs #16's label")
  r11 <- ccx_ms_reference_set(p16, "1")
  expect_identical(r11$incumbent, CCX_MODE_CANONICAL); expect_identical(r11$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_identical(r11$why, "the canonical, under this array's pins")    # a MODE of #16, not a start
  # the LAUNCH STRING, through the driver's own parser, resolves the same
  launch <- paste0("ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,",
                   "gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0")
  expect_identical(ccx_ms_reference_set(ccx_parse_pins(launch), "1"), r11)
  # MUTATION: npp_tsens held OFF 0 is not the ruled pin
  off <- p16; off[["npp_tsens"]] <- 0.004
  expect_error(ccx_ms_reference_set(off, "1"), "no registered incumbent")
  off2 <- p16; off2[["npp_tsens"]] <- 0.0089                 # hilda34g's own value, held
  expect_error(ccx_ms_reference_set(off2, "1"), "no registered incumbent")
  # MUTATION: a canonical pin moved, or dropped
  moved <- p16; moved[["w_eq"]] <- 30
  expect_error(ccx_ms_reference_set(moved, "1"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(p16[setdiff(names(p16), "w_thc")], "1"), "no registered incumbent")
  # #15's nine (npp_tsens FITTED) have no ruled reference set since the adoption: a #15 re-run rules its own
  expect_error(ccx_ms_reference_set(CCX_MODE_OBJ15_PINS, "1"), "no registered incumbent")
})

test_that("(12) OBJECTIVE #17's pins (2026-10-06 n, the interannual cut): #16's ten + the module's four at stage 1's values, under #17's label at seas_ml 1 -> the canonical (seeded) / the control; refused under #16's label, at seas_ml 0, a module value moved or dropped, and with the module free", {
  withr::local_envvar(CCX_MS_STRUCT = CCX_MODE_OBJ17_STRUCT, CCX_MS_PUMP_FIELD = "solved")
  p17 <- CCX_MODE_OBJ17_PINS
  expect_identical(names(p17), c(names(CCX_MODE_OBJ16_PINS), CCX_IAV_MODULE_NAMES))
  expect_identical(p17[names(CCX_MODE_OBJ16_PINS)], CCX_MODE_OBJ16_PINS)
  # the four literals ARE stage 1's result (calibration/fit_iav_module.R at hilda33p, not a smoke): R's parser is not
  # correctly rounded at 17 digits, so they are what its %.17g string PARSES to -- within 2 ulps of the double, and
  # identical to what the launch string gives (MUTATION-checked by the 1-ulp case: w_enso_l2 is not bit-identical)
  s1 <- readRDS(ccx_path(CCX_MODE_OBJ17_MODULE_FILE)); x1 <- s1$pins[CCX_IAV_MODULE_NAMES]
  expect_identical(unname(p17[CCX_IAV_MODULE_NAMES]), as.numeric(sprintf("%.17g", x1)))
  expect_true(all(abs(p17[CCX_IAV_MODULE_NAMES] - x1) <= 2 * .Machine$double.eps * abs(x1)))
  expect_false(identical(unname(p17[["w_enso_l2"]]), unname(x1[["w_enso_l2"]])), info = "the documented 1-ulp case")
  expect_identical(s1$provenance$base, "hilda33p"); expect_false(s1$provenance$smoke)
  expect_identical(s1$provenance$n_eff, LIK_IAV_NEFF)
  # the two land amplitudes sit at hilda33p's NH : SH ratio (one scale, as ruled)
  expect_equal(p17[["gamma_enso_land_NH"]] / p17[["gamma_enso_land_SH"]], s1$ratio[[1]] / s1$ratio[[2]], tolerance = 1e-14)
  expect_true(CCX_MODE_OBJ17_STRUCT %in% CCX_STRUCT_LABELS)
  expect_false(ccx_pins_extend_canonical(p17, "solved"), info = "the module's names are READ under #17: not an inert extension")
  expect_false(ccx_pins_price_canonical(p17, "solved"), info = "#17 is an objective, not a price arm")
  r12 <- ccx_ms_reference_set(p17, "1")
  expect_identical(r12$incumbent, CCX_MODE_CANONICAL); expect_identical(r12$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_match(r12$why, "OBJECTIVE #17.*seeded at the pins")
  # the LAUNCH STRING (the values at %.17g, as the launch writes them), through the driver's own parser
  launch <- paste(sprintf("%s=%.17g", names(p17), p17), collapse = ",")
  expect_identical(ccx_parse_pins(launch), p17)
  expect_identical(ccx_ms_reference_set(ccx_parse_pins(launch), "1"), r12)
  # MUTATION: under #16's label, and at seas_ml 0
  expect_error(ccx_ms_reference_set(p17, "1", struct = CCX_MODE_OBJ16_STRUCT), "ruled under")
  expect_error(ccx_ms_reference_set(p17, "0"), "OBJECTIVE #17")
  # MUTATION: a module value moved, or a module name dropped
  moved <- p17; moved[["lag_enso_land"]] <- 6
  expect_error(ccx_ms_reference_set(moved, "1"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(p17[setdiff(names(p17), "w_enso_l2")], "1"), "no registered incumbent")
  # MUTATION: the canonical's ten under #17's label leave the module FREE -- refused at launch, by name
  expect_error(ccx_ms_reference_set(ms_cp, "1"), "interannual CUT.*lag_enso_land")
  # ... while under #16's label the ten still take the first branch, as before
  expect_identical(ccx_ms_reference_set(ms_cp, "1", struct = CCX_MODE_OBJ16_STRUCT)$why, "the canonical, under this array's pins")
})

test_that("(13) OBJECTIVE #18's pins (2026-10-07 f, the redesigned cut): #16's ten + the module's four at stage 1's values under #18 at basin B, tied bit for bit to the stage-1 file and the mirror, under #18's label at seas_ml 1 -> hilda29w (basin B, seeded) / the control; refused under #17's label, at seas_ml 0, a module value moved or dropped, the module free", {
  p18 <- CCX_MODE_OBJ18_PINS
  expect_identical(names(p18), c(names(CCX_MODE_OBJ16_PINS), CCX_IAV_MODULE_NAMES))
  expect_identical(p18[names(CCX_MODE_OBJ16_PINS)], CCX_MODE_OBJ16_PINS)
  s1 <- readRDS(ccx_path(CCX_MODE_OBJ18_MODULE_FILE)); x1 <- s1$pins[CCX_IAV_MODULE_NAMES]
  expect_identical(unname(p18[CCX_IAV_MODULE_NAMES]), unname(x1))                  # bit for bit: no ulp case here
  expect_identical(unname(p18[CCX_IAV_MODULE_NAMES]), as.numeric(sprintf("%.17g", x1)))
  # the run: non-smoke, at #17's basin B file, the module fitted UNDER #18 (the switch), the detrended index
  pv <- s1$provenance
  expect_false(pv$smoke)
  expect_identical(pv$base_md5, "081eb16f4fe718692004fb1cf9645891")               # basin B (CHANGELOG 10-07 b / d)
  expect_identical(pv$base_struct, CCX_MODE_OBJ17_STRUCT)
  expect_identical(pv$struct, CCX_MODE_OBJ18_STRUCT); expect_true(pv$struct_switched)
  expect_identical(pv$struct_added, c("enso_index", "gcb_ocean_lowpass_df"))
  expect_identical(pv$enso_index, "detrend"); expect_identical(pv$n_eff, LIK_IAV_NEFF)
  # ... and it IS the pricing's stage-1 mirror (diag_iav_redesign_price.R @e891fa9), exactly
  em <- readRDS(ccx_path("outputs", "diagnostics", "iav_redesign_price_20261007.rds"))
  expect_identical(em$provenance$commit, "e891fa9")
  expect_identical(s1$pins, em$stage1$B_detrend$pins); expect_identical(s1$ssr_ref, em$stage1$B_detrend$ssr_ref)
  # the land pair at hilda33p's NH : SH ratio (one scale, as ruled)
  expect_equal(p18[["gamma_enso_land_NH"]] / p18[["gamma_enso_land_SH"]], s1$ratio[[1]] / s1$ratio[[2]], tolerance = 1e-14)
  expect_true(CCX_MODE_OBJ18_STRUCT %in% CCX_STRUCT_LABELS)
  withr::local_envvar(CCX_MS_STRUCT = CCX_MODE_OBJ18_STRUCT, CCX_MS_PUMP_FIELD = "solved")
  expect_false(ccx_pins_extend_canonical(p18, "solved")); expect_false(ccx_pins_price_canonical(p18, "solved"))
  # RULED 2026-10-07 (i), Marcus: "Register B, seed from it (Recommended)": the incumbent is #17's basin B, registered as
  # hilda29w (the file stage 1 was fitted at), seeded at #18's pins; the new basin is the control
  expect_identical(CCX_MODE_OBJ18_INCUMBENT, "hilda29w")
  expect_identical(unname(tools::md5sum(ccx_mode_file(CCX_MODE_OBJ18_INCUMBENT))), pv$base_md5)   # = stage 1's base
  expect_true(CCX_MODE_PINNED[[CCX_MODE_OBJ18_INCUMBENT]])
  expect_identical(ccx_mode_struct(ccx_mode_file(CCX_MODE_OBJ18_INCUMBENT)), CCX_MODE_OBJ17_STRUCT)
  r13 <- ccx_ms_reference_set(p18, "1")
  expect_identical(r13$incumbent, CCX_MODE_OBJ18_INCUMBENT); expect_identical(r13$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_match(r13$why, "OBJECTIVE #18.*seeded at the pins")
  expect_true(all(c(r13$incumbent, r13$new_basin) %in% names(CCX_MODE_FILES)))
  # the LAUNCH STRING (the values at %.17g, as the launch writes them), through the driver's own parser
  launch <- paste(sprintf("%s=%.17g", names(p18), p18), collapse = ",")
  expect_identical(ccx_parse_pins(launch), p18)
  expect_identical(ccx_ms_reference_set(ccx_parse_pins(launch), "1"), r13)
  # MUTATION: under #17's label, and at seas_ml 0
  expect_error(ccx_ms_reference_set(p18, "1", struct = CCX_MODE_OBJ17_STRUCT), "ruled under")
  expect_error(ccx_ms_reference_set(p18, "0"), "OBJECTIVE #18")
  # MUTATION: a module value moved (to #17's), or a module name dropped
  moved <- p18; moved[["w_enso_l2"]] <- CCX_MODE_OBJ17_PINS[["w_enso_l2"]]
  expect_error(ccx_ms_reference_set(moved, "1"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(p18[setdiff(names(p18), "lag_enso_land")], "1"), "no registered incumbent")
  # MUTATION: the canonical's ten under #18's label leave the module FREE -- refused at launch, by name
  expect_error(ccx_ms_reference_set(ms_cp, "1"), "interannual CUT.*lag_enso_land")
  # ... and #18's label does not take #17's pins (ruled under #17's own label only)
  expect_error(ccx_ms_reference_set(CCX_MODE_OBJ17_PINS, "1"), "ruled under")
})
