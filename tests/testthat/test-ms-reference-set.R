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
#   (15) THE WTC REFIT (2026-10-12; Marcus: "Carry module, then check (Recommended)"): hilda29e's pins (#18 pass 2's set)
#       under the citation batch's label at seas_ml 1 -> hilda29e (a start, at its own model) / the control, while the
#       canonical is not of that label; MUTATION: refused at seas_ml 0, with #18 pass 1's pins, a module value moved or
#       dropped, and under #17's label; the canonical's own label still takes the canonical as a MODE
# =====================================================================
ms_cp <- CCX_MODE_CANONICAL_PINS
ms_ctl <- CCX_MODE_CONTROL_PINS
# 2026-10-08 (e; Marcus: "Approve all five"): hilda29e's adoption -- the canonical's pins are #16's ten + the interannual
# module's four. Premises that read "the canonical's" for #16's ten NAME them (the hilda33p ledger's lesson).
ms_cp16 <- CCX_MODE_OBJ16_PINS
ms_cs   <- ccx_mode_struct(readRDS(ccx_mode_file()))       # the canonical's own label (hilda_csl3v0kaidgbemwt)

test_that("the control's pin set is the canonical's without the shim, and the control is registered and FREE", {
  expect_true(!is.null(ms_cp) && "ent_seas_amp_SH" %in% names(ms_cp))
  # 2026-09-20 (r): the canonical is the LIMB arm (fits w_enso_l2, pins the ocean ENSO pair); the
  # control has no limb (holds w_enso_l2 = 0) and fits the pair: the two sets differ by exactly those
  # 2026-10-06 (a): + npp_tsens -- the canonical hilda33p pins the greening term (objective #16); the control,
  # on a label that never opens the gate, does not carry it (Marcus 2026-10-06: "Approve all (Recommended)")
  # 2026-10-08 (e): stated against #16's ten (the canonical's until hilda29e); the canonical = those ten + the module's four
  expect_setequal(setdiff(names(ms_cp16), names(ms_ctl)), c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "npp_tsens"))
  expect_identical(setdiff(names(ms_ctl), names(ms_cp16)), "w_enso_l2")
  shared <- intersect(names(ms_ctl), names(ms_cp16)); expect_equal(unname(ms_ctl[shared]), unname(ms_cp16[shared]))
  expect_identical(setdiff(names(ms_cp), names(ms_cp16)), CCX_IAV_MODULE_NAMES)
  expect_identical(ms_cp[names(ms_cp16)], ms_cp16)
  expect_true(CCX_MODE_SEASML0_CONTROL %in% names(CCX_MODE_FILES))
  expect_false(CCX_MODE_PINNED[[CCX_MODE_SEASML0_CONTROL]], info = "the control is a FREE arm (its shim is fitted)")
  md <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL))
  expect_true(is.finite(md$par_mode[["ent_seas_amp_SH"]]) && md$par_mode[["ent_seas_amp_SH"]] > 0,
              info = "the control CARRIES the shim, non-zero")
  expect_identical(ccx_mode_base(md)$seas_ml, 0L)                     # the base through ccx_mode_base(): seas_ml OFF
})

test_that("the five branches return the ruled pairs", {
  # 2026-10-08 (e): the NULL / control branches run under #16's label (under the canonical's -- the CUT -- a pin set that
  # leaves the module free is refused, by design); the canonical's own pins under its own label
  withr::local_envvar(CCX_MS_STRUCT = CCX_MODE_OBJ16_STRUCT, CCX_MS_PUMP_FIELD = "solved")
  r1 <- ccx_ms_reference_set(ms_cp, "1", struct = ms_cs)
  expect_identical(r1$incumbent, CCX_MODE_CANONICAL); expect_identical(r1$new_basin, CCX_MODE_SEASML0_CONTROL)
  # the canonical's pins at seas_ml 0: the canonical while it had no cut (hilda33p); since hilda29e its module values were
  # fitted at seas_ml 1, so seas_ml 0 is REFUSED (10-08 e; Marcus: "Approve all five")
  expect_error(ccx_ms_reference_set(ms_cp, "0", struct = ms_cs), "fitted at seas_ml 1")
  # a REAL extension: under the martin field `pump_grad` is inert (the E array's case)
  r2 <- ccx_ms_reference_set(c(ms_cp, pump_grad = 314.1031), "1", pump_field = "martin", struct = ms_cs)
  expect_identical(r2$incumbent, CCX_MODE_CANONICAL)
  expect_error(ccx_ms_reference_set(c(ms_cp, pump_grad = 314.1031), "1", pump_field = "solved", struct = ms_cs),
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

test_that("the layer-2 limb's arm (2026-10-08 e): its constant is the limb arm's OWN nine and no ruled reference set takes it; the CUT canonical's pins are refused under hilda_cl2", {
  ms_l2 <- CCX_MODE_L2_ARM_PINS
  # 10-08 (e; Marcus: "Approve all five"): no longer the canonical's alias (hilda29e pins w_enso_l2) -- the limb arm's own
  # 09-20 (r) set: w_enso_l2 FITTED, the ENSO pair pinned at 0
  expect_identical(ms_l2, CCX_MODE_OBJ15_PINS)
  expect_false("w_enso_l2" %in% names(ms_l2)); expect_true(all(c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH") %in% names(ms_l2)))
  expect_equal(unname(ms_l2[c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH")]), c(0, 0))
  # the limb branch is REMOVED (unreachable by design since 09-20 r): a nine-pin array is refused under ANY structure and
  # seas_ml, as the 10-06 ruling refuses a #15 re-run until its reference set is ruled
  for (st in c("hilda_cl2", "hilda_c", "hilda")) for (sm in c("0", "1"))
    expect_error(ccx_ms_reference_set(ms_l2, sm, pump_field = "solved", struct = st), "no registered incumbent")
  # the control's pins under a limb structure hold w_enso_l2 OFF -- allowed (nothing inert is free)
  expect_silent(ccx_ms_reference_set(ms_ctl, "0", struct = "hilda_cl2"))
  # MUTATION: the shim pinned at a non-zero value is not the limb's arm
  moved <- ms_l2; moved[["gamma_enso_ocn_NH"]] <- 0.36
  expect_error(ccx_ms_reference_set(moved, "1", struct = "hilda_cl2"), "no registered incumbent")
  # the canonical's own pins under hilda_cl2: a legal structure arm while the canonical had no cut; since hilda29e its
  # module values belong to its own label, so REFUSED (10-08 e)
  expect_error(ccx_ms_reference_set(ms_cp, "1", struct = "hilda_cl2"), "is not that label")
})

test_that("(9) the FREE PARENT of the limb canonical (2026-09-21 g): the six inert pins only, under a structure WITH the limb at seas_ml 1 -> the canonical / the control; refused without the limb and at seas_ml 0", {
  fp <- CCX_MODE_FREE_PARENT_PINS
  expect_setequal(names(fp), setdiff(names(CCX_MODE_CONTROL_PINS), "w_enso_l2"))           # the control's minus the limb's name
  # 2026-10-06 (a): FOUR real pins since hilda33p -- the shim, the pair and npp_tsens (Marcus 2026-10-06: "Approve all (Recommended)")
  # 10-08 (e): against #16's ten (the canonical's until hilda29e, whose four module names are not the free parent's either)
  expect_setequal(names(fp), setdiff(names(ms_cp16), c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "npp_tsens")))   # #16's minus its four real pins
  expect_equal(unname(fp), unname(ms_cp16[names(fp)]))
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
  # 2026-10-08 (e): #16's ten WERE the canonical's (hilda33p, 10-06 -> 10-08); hilda29e's are those ten + the module's four
  expect_identical(ms_cp[names(p16)], p16, info = "the canonical's pins extend #16's ten")
  expect_identical(setdiff(names(ms_cp), names(p16)), CCX_IAV_MODULE_NAMES)
  expect_identical(names(p16), c(names(CCX_MODE_OBJ15_PINS), "npp_tsens"))
  expect_identical(p16[["npp_tsens"]], 0)
  expect_identical(p16[["npp_tsens"]], CCX_NPP_TSENS_DEFAULT, info = "the pin IS the term's absent default")
  expect_true(CCX_MODE_OBJ16_STRUCT %in% CCX_STRUCT_LABELS)
  # 2026-10-13 (g): the canonical runs the WTC label since hilda31w (Marcus: "Approve all (Recommended)"); its pins are still
  # #16's ten + the module's four (#18 pass 2's, carried: no second pass)
  # 2026-10-23 (m): the flask label since hilda31fl (Marcus: "Approve all (Recommended)"); the same pins, carried again
  expect_identical(ccx_mode_struct(readRDS(ccx_mode_file())), CCX_MODE_FLASK_STRUCT, info = "the canonical runs the flask label (hilda31fl)")
  # since hilda29e NO ruled reference set takes #16's ten: a #16 re-run rules its own, as #15's nine since 10-06
  expect_error(ccx_ms_reference_set(p16, "1"), "no registered incumbent")
  # the LAUNCH STRING, through the driver's own parser, resolves the same
  launch <- paste0("ent_seas_amp_SH=0,w_eq=27,gamma_eq=1,pump_export=9.08,w_vent=0,gamma_vent=0,w_thc=0,",
                   "gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0,npp_tsens=0")
  expect_identical(ccx_parse_pins(launch), p16)
  expect_error(ccx_ms_reference_set(ccx_parse_pins(launch), "1"), "no registered incumbent")
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
  # (10-08 e) #16's ten match no ruled set since hilda29e, so they are refused before the cut's check; the cut's refusal of
  # a REGISTERED set that leaves the module free is exercised on NULL pins (the free-parent branch)
  expect_error(ccx_ms_reference_set(ms_cp16, "1"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(NULL, "1"), "interannual CUT.*lag_enso_land")
  # ... and under #16's label the ten took the first branch while they were the canonical's; since hilda29e (10-08 e) no
  # ruled set takes them
  expect_error(ccx_ms_reference_set(ms_cp16, "1", struct = CCX_MODE_OBJ16_STRUCT), "no registered incumbent")
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
  # (10-08 e) #16's ten match no ruled set since hilda29e, so they are refused before the cut's check; the cut's refusal of
  # a REGISTERED set that leaves the module free is exercised on NULL pins (the free-parent branch)
  expect_error(ccx_ms_reference_set(ms_cp16, "1"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(NULL, "1"), "interannual CUT.*lag_enso_land")
  # ... and #18's label does not take #17's pins (ruled under #17's own label only)
  expect_error(ccx_ms_reference_set(CCX_MODE_OBJ17_PINS, "1"), "ruled under")
})

test_that("(14) #18 PASS 2's pins (2026-10-08 d; Marcus: \"Basin 1, run the second pass, adopt if it passes\"): #16's ten + the module at the one-pass check's values at basin 1, tied bit for bit to the check file, under #18's label at seas_ml 1 -> hilda29a0 (basin 1) / hilda29a6 (basin 2), both seeded; refused under #17's label, at seas_ml 0, a module value moved back to pass 1's, a module name dropped", {
  p2 <- CCX_MODE_OBJ18P2_PINS
  expect_identical(names(p2), c(names(CCX_MODE_OBJ16_PINS), CCX_IAV_MODULE_NAMES))
  expect_identical(p2[names(CCX_MODE_OBJ16_PINS)], CCX_MODE_OBJ16_PINS)
  s2 <- readRDS(ccx_path(CCX_MODE_OBJ18P2_MODULE_FILE)); x2 <- s2$pins[CCX_IAV_MODULE_NAMES]
  expect_identical(unname(p2[CCX_IAV_MODULE_NAMES]), unname(x2))                  # bit for bit
  expect_identical(unname(p2[CCX_IAV_MODULE_NAMES]), as.numeric(sprintf("%.17g", x2)))
  # the run: the landing's one-pass check at #18's basin 1, under #18's own label (no switch), the detrended index
  pv <- s2$provenance
  expect_false(pv$smoke)
  expect_identical(pv$base_md5, unname(tools::md5sum(ccx_mode_file(CCX_MODE_OBJ18P2_INCUMBENT))))   # = basin 1's file
  expect_identical(pv$base_struct, CCX_MODE_OBJ18_STRUCT); expect_identical(pv$struct, CCX_MODE_OBJ18_STRUCT)
  expect_identical(pv$enso_index, "detrend"); expect_identical(pv$n_eff, LIK_IAV_NEFF)
  # pass 2 is a MOVE from pass 1's values: every module name differs, and w_enso_l2 moved up (the check's +0.126 sigma)
  expect_true(all(p2[CCX_IAV_MODULE_NAMES] != CCX_MODE_OBJ18_PINS[CCX_IAV_MODULE_NAMES]))
  expect_gt(p2[["w_enso_l2"]], CCX_MODE_OBJ18_PINS[["w_enso_l2"]])
  # both references are #18's LANDED basins, registered and PINNED at pass 1's values, under #18's label
  expect_identical(c(CCX_MODE_OBJ18P2_INCUMBENT, CCX_MODE_OBJ18P2_NEW), c("hilda29a0", "hilda29a6"))
  for (n in c(CCX_MODE_OBJ18P2_INCUMBENT, CCX_MODE_OBJ18P2_NEW)) {
    expect_true(CCX_MODE_PINNED[[n]])
    expect_identical(ccx_mode_struct(ccx_mode_file(n)), CCX_MODE_OBJ18_STRUCT)
    expect_identical(ccx_pin_label(ccx_mode_pins(ccx_mode_file(n))), ccx_pin_label(CCX_MODE_OBJ18_PINS))
  }
  expect_identical(readRDS(ccx_mode_file(CCX_MODE_OBJ18P2_INCUMBENT))$promoted_from$id, 0L)
  expect_identical(readRDS(ccx_mode_file(CCX_MODE_OBJ18P2_NEW))$promoted_from$id, 6L)
  # 2026-10-08 (e): pass 2 PASSED and its basin-1 refit was the canonical, hilda29e -- pass 2's pins became the canonical's;
  # pass 2's own branch was removed (the hilda33p precedent).
  # 2026-10-13 (g) (Marcus: "Approve all (Recommended)"): the canonical is hilda31w, which CARRIES pass 2's pins (no second
  # pass) under the WTC label. The first branch takes them under the CANONICAL's label, the canonical as a MODE; under #18's
  # own label (hilda29e's) the cut canonical's guard now refuses them, as it refuses any other label: a #18 re-run rules its own.
  # 2026-10-23 (m) (Marcus: "Approve all (Recommended)"): the canonical is hilda31fl, which carries the same pins under the
  # flask label; under the WTC label (hilda31w's) the guard now refuses them, as it refuses #18's.
  expect_identical(p2, CCX_MODE_CANONICAL_PINS); expect_identical(CCX_MODE_CANONICAL, "hilda31fl")
  expect_identical(ccx_mode_struct(ccx_mode_file()), CCX_MODE_FLASK_STRUCT)
  r14 <- ccx_ms_reference_set(p2, "1", pump_field = "solved", struct = CCX_MODE_FLASK_STRUCT)
  expect_identical(r14$incumbent, CCX_MODE_CANONICAL); expect_identical(r14$new_basin, CCX_MODE_SEASML0_CONTROL)
  expect_identical(r14$why, "the canonical, under this array's pins")
  # the LAUNCH STRING, through the driver's own parser
  launch <- paste(sprintf("%s=%.17g", names(p2), p2), collapse = ",")
  expect_identical(ccx_parse_pins(launch), p2)
  expect_identical(ccx_ms_reference_set(ccx_parse_pins(launch), "1", pump_field = "solved", struct = CCX_MODE_FLASK_STRUCT), r14)
  # MUTATION (the cut canonical's guard): under the WTC label (the previous canonical's, 2026-10-23 m), #18's and #17's, at
  # seas_ml 0; then a module value moved back to pass 1's, and a module name dropped
  expect_error(ccx_ms_reference_set(p2, "1", pump_field = "solved", struct = CCX_MODE_WTC_STRUCT), "is not that label")
  expect_error(ccx_ms_reference_set(p2, "1", pump_field = "solved", struct = CCX_MODE_OBJ18_STRUCT), "is not that label")
  expect_error(ccx_ms_reference_set(p2, "1", pump_field = "solved", struct = CCX_MODE_OBJ17_STRUCT), "is not that label")
  expect_error(ccx_ms_reference_set(p2, "0", pump_field = "solved", struct = CCX_MODE_FLASK_STRUCT), "fitted at seas_ml 1")
  back <- p2; back[["w_enso_l2"]] <- CCX_MODE_OBJ18_PINS[["w_enso_l2"]]
  expect_error(ccx_ms_reference_set(back, "1", pump_field = "solved", struct = CCX_MODE_FLASK_STRUCT), "no registered incumbent")
  expect_error(ccx_ms_reference_set(p2[setdiff(names(p2), "w_enso_l2")], "1", pump_field = "solved", struct = CCX_MODE_FLASK_STRUCT),
               "no registered incumbent")
})

# (15) THE WTC REFIT's branch (2026-10-12) was REMOVED with its test at hilda31w's adoption (2026-10-13 f): the canonical is a
# file of that label, so its pins take the first branch, the canonical as a MODE -- the hilda33p / hilda29e precedent.

# (16) THE FLASK REFIT's branch (2026-10-22) was REMOVED with its test at hilda31fl's adoption (2026-10-23 k): the canonical is
# a file of that label, so its pins take the first branch, the canonical as a MODE -- the WTC refit's precedent (15).
