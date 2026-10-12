# =====================================================================
# test-gated-params.R -- the LABEL-GATED fitted names (2026-09-30; objective #14):
# D2's `ndep_ret` / `npp_tsens` and D3's `imb_share_land` / `imb_share_ocean_rest`
# (R/calibrate.R, CCX_PARAM_GATED and the "hilda_csl3v0kaidgb" structure).
#
# What has to hold before a refit may fit them:
#   1. TABLE: each entry is the RULED prior (09-30 l/m), its init is tied to its
#      source, and the two share priors ARE the flat simplex through the
#      stick-breaking map (read off the table, not restated).
#   2. GATE: closed by default (the table is today's 38 names, bit for bit); ONLY
#      the ledgered label opens it; apply / undo round-trips the table exactly; a
#      pinned gated name returns to its place.
#   3. GUARD: the objective refuses an open structure scored without the gate, a
#      holding structure scored with it (also when the gate moves AFTER the
#      objective was built), and an I(t) that disagrees with the label.
#   4. OFF-IDENTITY: the open label with all four PINNED at 0 is the kai label,
#      bit for bit -- the block changes nothing the model or the rows read.
#   5. MIGRATION: an older file read with the gate open fills 0 (what it RAN) and
#      is seeded only where 0 does not encode; read with the gate closed, it is
#      untouched.
#   6. SCREEN IDENTITY: at the D2/D3 screen's DNTb vector the open label's streams
#      ARE the screen's (the table path wires the four names to the same model and
#      rows as the screen's base_params path), and the logpost differs from the
#      screen's objective by exactly the shares' prior + logit Jacobians.
# Mutation-tested 2026-09-30 (CHANGELOG 09-30 p): each guard and wire broken in turn.
# =====================================================================

# the ledger: the labels that OPEN the gate. Extending it is a DELIBERATE edit.
# + "hilda_csl3v0kaidgbe" (2026-10-02, W1; objective #15): it opens THIS gate and the lag gate
#   (CCX_PARAM_GATES); the lag gate's own ledger is in test-enso-lag.R.
GP_OPEN_LABELS <- c("hilda_csl3v0kaidgb", "hilda_csl3v0kaidgbe", "hilda_csl3v0kaidgbem", "hilda_csl3v0kaidgbemw", "hilda_csl3v0kaidgbemwt", "hilda_csl3v0kaidgbemwtc")  # + the redesigned cut (2026-10-07, objective #18; Marcus: "Full redesign (Recommended)", the name "hilda_csl3v0kaidgbemwt (Recommended)")   # + the interannual cut's main half (2026-10-06, objective #17; Marcus: "Build: land + ocean module (Recommended)", the name "hilda_csl3v0kaidgbemw (Recommended)")   # + the stratification feedback (2026-10-04; DESIGN §3.4a S; extension authorised by Marcus's ruling "History + futures, one #16 refit")

.gp_restore <- function(gate = character(0), pins = list()) {
  ccx_unpin_params(pins); ccx_unapply_gate(gate)
}

test_that("1. TABLE: the ruled priors, the inits tied to their sources, the flat simplex", {
  g <- CCX_PARAM_GATED
  expect_identical(names(g), c("ndep_ret", "npp_tsens", "imb_share_land", "imb_share_ocean_rest"))
  expect_identical(vapply(g, `[[`, "", "tr"),
                   c(ndep_ret = "log", npp_tsens = "id", imb_share_land = "logit", imb_share_ocean_rest = "logit"))
  # inits: the prior centres, and the flat simplex's CENTROID (1/3, 1/3, 1/3)
  expect_equal(g$ndep_ret$init, ccx_const("NDEP_RET_PRIOR_CENTRE"), tolerance = 1e-12)
  expect_identical(g$npp_tsens$init, 0)
  sh <- ccx_imb_shares(list(imb_share_land = g$imb_share_land$init, imb_share_ocean_rest = g$imb_share_ocean_rest$init))
  expect_equal(unname(c(sh, 1 - sum(sh))), rep(1 / 3, 3), tolerance = 1e-15)
  # the ruled priors, against the constants they must read
  x <- c(0.6, 3.9, 8.7, 15)
  expect_equal(vapply(x, g$ndep_ret$prior, 0),
               stats::dlnorm(x, log(ccx_const("NDEP_RET_PRIOR_CENTRE")), ccx_const("NDEP_RET_PRIOR_LOGSD"), log = TRUE),
               tolerance = 1e-14)
  expect_equal(ccx_const("NDEP_RET_PRIOR_LOGSD"), log(8.7 / 0.6) / 4, tolerance = 1e-14)     # "2-sigma spanning 0.6-8.7"
  t <- c(-0.06, 0, 0.029, 0.06)
  expect_equal(vapply(t, g$npp_tsens$prior, 0), stats::dnorm(t, 0, ccx_const("NPP_TSENS_PRIOR_SD"), log = TRUE),
               tolerance = 1e-14)
  expect_equal(g$npp_tsens$prior(0.02), g$npp_tsens$prior(-0.02), tolerance = 0)            # SIGN-FREE
  # the TABLE's share priors, pushed through the stick-breaking map, are CONSTANT on the
  # simplex: p(s_land, s_ocean) = p_land(s_land) p_rest(rest) / |d s_ocean / d rest|
  sl <- c(0.01, 0.2, 0.5, 0.8, 0.99); r <- c(0.1, 0.9, 0.5, 0.3, 0.7)
  dens <- exp(vapply(sl, g$imb_share_land$prior, 0) + vapply(r, g$imb_share_ocean_rest$prior, 0)) / (1 - sl)
  expect_equal(dens, rep(2, length(sl)), tolerance = 1e-12)
})

test_that("2. GATE: closed by default, opened only by the ledgered labels, undone exactly", {
  expect_length(intersect(names(CCX_PARAM_GATED), CCX_PARAM_NAMES), 0L)
  expect_identical(CCX_PARAM_NAMES, names(CCX_PARAM_TABLE))
  expect_length(CCX_PARAM_NAMES, 38L)                                   # today's fitted set, unchanged
  opened <- CCX_STRUCT_LABELS[vapply(CCX_STRUCT_LABELS, ccx_gate_open, logical(1))]
  expect_identical(opened, GP_OPEN_LABELS)
  expect_false(ccx_gate_open(ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kai", seas_ml = "1")))
  expect_true(ccx_gate_open(ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kaidgb", seas_ml = "1")))
  expect_error(ccx_gate_open("hilda_xx"), "unknown structure label")
  # the open label is kai's block PLUS the gate flag and the recorded I(t), nothing else
  kai <- ccx_struct_block("hilda_csl3v0kai"); dgb <- ccx_struct_block("hilda_csl3v0kaidgb")
  expect_identical(dgb[names(kai)], kai)
  expect_identical(setdiff(names(dgb), names(kai)), c(CCX_GATE_FLAG, "imb_treatment", "imb_with_cement"))
  # the recorded I(t) is the RULED one ("Smooth + cement"), as a NUMERIC code decoded by name
  expect_identical(names(LIK_IMB_TREATMENT_CODES), LIK_IMB_TREATMENTS)
  expect_identical(names(LIK_IMB_TREATMENT_CODES)[match(dgb$imb_treatment, LIK_IMB_TREATMENT_CODES)], "smooth")
  expect_identical(dgb$imb_with_cement, 1L)
  expect_true(all(vapply(dgb, is.numeric, logical(1))))                # a model-list field is numeric
  # a holding label is a no-op; the open one appends the four, in order, and undoes exactly
  tab0 <- CCX_PARAM_TABLE; nm0 <- CCX_PARAM_NAMES
  expect_length(ccx_apply_gate("hilda_csl3v0kai"), 0L)
  expect_identical(CCX_PARAM_TABLE, tab0)
  h <- ccx_apply_gate("hilda_csl3v0kaidgb"); on.exit(.gp_restore(h), add = TRUE)
  expect_identical(CCX_PARAM_NAMES, c(nm0, names(CCX_PARAM_GATED)))
  expect_identical(CCX_PARAM_TABLE[names(CCX_PARAM_GATED)], CCX_PARAM_GATED)
  expect_error(ccx_apply_gate("hilda_csl3v0kaidgb"), "applied ONCE")
  # a PINNED gated name comes back to its own place; undoing the gate under it is refused
  r <- ccx_apply_pins(c(npp_tsens = 0, w_eq = 27))
  expect_false("npp_tsens" %in% CCX_PARAM_NAMES)
  expect_error(ccx_unapply_gate(h), "PINNED")
  ccx_unpin_params(r)
  expect_identical(CCX_PARAM_NAMES, c(nm0, names(CCX_PARAM_GATED)))
  ccx_unapply_gate(h); h <- character(0)
  expect_identical(CCX_PARAM_TABLE, tab0); expect_identical(CCX_PARAM_NAMES, nm0)
})

test_that("3. GUARD: the objective refuses a gate that does not match the structure", {
  skip_if_no_cpp()
  bk <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kai", seas_ml = "1")
  bd <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kaidgb", seas_ml = "1")
  # open structure, gate closed: refused when built
  expect_error(ccx_make_logpost(base_params = bd, spinup_fn = ccx_spinup), "OPENS the gate")
  h <- ccx_apply_gate("hilda_csl3v0kaidgb"); on.exit(.gp_restore(h), add = TRUE)
  # holding structure, gate open: refused when built
  expect_error(ccx_make_logpost(base_params = bk, spinup_fn = ccx_spinup), "HOLDS them")
  # ... and PER DRAW: an objective built before the gate moved still refuses
  lp_d <- ccx_make_logpost(base_params = bd, spinup_fn = ccx_spinup)
  u <- ccx_init_unc()
  ccx_unapply_gate(h); h <- character(0)
  expect_error(lp_d(u[setdiff(names(u), names(CCX_PARAM_GATED))]), "OPENS the gate")
  lp_k <- ccx_make_logpost(base_params = bk, spinup_fn = ccx_spinup)
  h <- ccx_apply_gate("hilda_csl3v0kaidgb")
  expect_error(lp_k(ccx_init_unc()), "HOLDS them")
  # the recorded I(t): a draw under disagreeing globals is refused
  old <- LIK_IMB_TREATMENT; on.exit(assign("LIK_IMB_TREATMENT", old, envir = globalenv()), add = TRUE)
  assign("LIK_IMB_TREATMENT", "raw", envir = globalenv())
  expect_error(lp_d(ccx_init_unc()), "ONE objective")
  assign("LIK_IMB_TREATMENT", old, envir = globalenv())
  oc <- LIK_IMB_WITH_CEMENT; on.exit(assign("LIK_IMB_WITH_CEMENT", oc, envir = globalenv()), add = TRUE)
  assign("LIK_IMB_WITH_CEMENT", !oc, envir = globalenv())
  expect_error(lp_d(ccx_init_unc()), "ONE objective")
})

test_that("4. OFF-IDENTITY: the open label with all four PINNED at 0 is the kai label, bit for bit", {
  skip_if_no_cpp()
  bk <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kai", seas_ml = "1")
  bd <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kaidgb", seas_ml = "1")
  u  <- ccx_init_unc()
  a  <- ccx_make_logpost(base_params = bk, spinup_fn = ccx_spinup, by_stream = TRUE)(u)
  off <- stats::setNames(rep(0, length(CCX_PARAM_GATED)), names(CCX_PARAM_GATED))
  h <- ccx_apply_gate("hilda_csl3v0kaidgb"); r <- ccx_apply_pins(off)
  on.exit(.gp_restore(h, r), add = TRUE)
  expect_identical(CCX_PARAM_NAMES, names(u))                           # the pinned table IS the closed one
  bd0 <- bd; for (n in names(off)) bd0[[n]] <- off[[n]]                 # a pin holds its value in the base
  b  <- ccx_make_logpost(base_params = bd0, spinup_fn = ccx_spinup, by_stream = TRUE)(u)
  expect_identical(attr(b, "streams"), attr(a, "streams"))
  expect_identical(as.numeric(b), as.numeric(a))
})

test_that("5. MIGRATION: an older file under an open gate fills 0 and seeds only what does not encode", {
  # the fixture is named for what it IS (an older, holding-label file), not "the canonical": the
  # canonical became the open-label hilda33d on 2026-10-01 (the test-param-absent-ok lesson)
  md <- readRDS(ccx_mode_file("hilda29l"))
  # gate CLOSED: the file carries this build, nothing is absent, nothing migrates
  rm0 <- ccx_apply_pins(ccx_mode_pins(md))
  st0 <- ccx_mode_start(md, "test"); ccx_unpin_params(rm0)
  expect_length(intersect(st0$absent, names(CCX_PARAM_GATED)), 0L)
  # gate OPEN: the four are absent, filled with 0 = what the file RAN
  h <- ccx_apply_gate("hilda_csl3v0kaidgb"); on.exit(.gp_restore(h), add = TRUE)
  expect_true(ccx_mode_carries_build(md))                               # via ccx_param_absent_ok()
  # ... but a file whose OWN structure opens the gate must CARRY all four
  md_bad <- md; md_bad$struct <- "hilda_csl3v0kaidgb"
  expect_false(ccx_mode_carries_build(md_bad))
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  expect_identical(unlist(pm[names(CCX_PARAM_GATED)]), stats::setNames(rep(0, 4), names(CCX_PARAM_GATED)))
  expect_true(all(names(CCX_PARAM_GATED) %in% attr(pm, "migrated")))
  r <- ccx_apply_pins(ccx_mode_pins(md))
  invisible(utils::capture.output(st <- ccx_mode_start(md, "test")))
  ccx_unpin_params(r)
  # seeded at init where 0 does not encode (log; the logit floor); npp_tsens encodes 0
  expect_identical(st$p$ndep_ret, CCX_PARAM_GATED$ndep_ret$init)
  expect_identical(st$p$imb_share_land, CCX_PARAM_GATED$imb_share_land$init)
  expect_identical(st$p$imb_share_ocean_rest, CCX_PARAM_GATED$imb_share_ocean_rest$init)
  expect_identical(st$p$npp_tsens, 0)
  expect_setequal(intersect(st$absent, names(CCX_PARAM_GATED)), names(CCX_PARAM_GATED))
  # every other coordinate is the file's own
  for (n in md$param_names) expect_identical(st$p[[n]], md$par_mode[[n]], info = n)
  # the shift is the four names' prior + log-Jacobian at those values, and nothing else
  g <- CCX_PARAM_GATED
  jac <- function(v, s) .log_jac(.to_unc(v, s), s)
  want <- sum(vapply(names(g), function(n) .ccx_prior_eval(g[[n]], st$p[[n]]) + jac(st$p[[n]], g[[n]]), 0))
  expect_equal(st$logpost_shift - st0$logpost_shift, want, tolerance = 1e-12)
  # an OPEN-label file read with the gate CLOSED is refused for the right reason
  ccx_unapply_gate(h); h <- character(0)
  md_open <- md; md_open$struct <- "hilda_csl3v0kaidgb"
  md_open$param_names <- c(md$param_names, names(CCX_PARAM_GATED))
  expect_error(ccx_mode_start(md_open, "test"), "OPENS the gate")
  expect_error(ccx_require_param_set(md_open, "test"), "OPENS the gate")
})

test_that("6. SCREEN IDENTITY: the open label reproduces the D2/D3 screen's DNTb streams", {
  skip_if_no_cpp()
  # the screen (calibration/diag_alignment_screen.R at 58cd91c; CHANGELOG 09-30 n) built its
  # base exactly so: the 09-28c promoted file's base, the kai label, the file's pins, the
  # control's overrides with the proxy's litter share rescaled; D2 and the shares in the BASE
  ds <- readRDS(ccx_path("outputs", "diagnostics", "alignment_screen_d2ret_20260930.rds"))
  a  <- ds$arms[[which(vapply(ds$arms, `[[`, "", "arm") == "DNTb")]]
  md <- readRDS(ccx_path("calibration", "output",
    "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
    "promoted_basin1", "mode_fit_pumpN.rds"))
  cp <- readRDS(ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_stock8053_20260929.rds"))
  ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == 500)]]
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, "hilda_csl3v0kaidgb", as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
  for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]
  bp$litter_slow_frac <- ctrl$over$litter_slow_frac / 0.8053
  bp$ra_ratio <- 0
  h <- ccx_apply_gate("hilda_csl3v0kaidgb"); r <- ccx_apply_pins(md$pins)
  on.exit(.gp_restore(h, r), add = TRUE)
  expect_identical(CCX_PARAM_NAMES, c(md$param_names, names(CCX_PARAM_GATED)))
  sl <- a$imb_share[["land"]]; rest <- a$imb_share[["ocean"]] / (1 - sl)
  g_par <- list(ndep_ret = a$d2[["ndep_ret"]], npp_tsens = a$d2[["npp_tsens"]],
                imb_share_land = sl, imb_share_ocean_rest = rest)
  u <- c(a$u, vapply(names(g_par), function(n) .to_unc(g_par[[n]], CCX_PARAM_GATED[[n]]), 0))
  # ⚠ UNDER THE SCREEN'S OWN INTERPOLATION (2026-10-01): the screen ran under "spline", before the
  # 10-01 (k) flip to "constant" (review 10-01c B6), so the method is an INPUT of the artifact this
  # identity reproduces. Re-supplied, not re-pinned: under "constant" the streams move by up to 0.338
  # (the seasonal rows) and the identity would have to become a pin on the code under test.
  # ... and UNDER ITS OWN OBJECTIVE (2026-10-02, objective #15): the screen predates the d13c_icecore
  # row and the pre-1958 ice-CO2 cut, so #14's two ice rows are re-supplied the same way (approved by Marcus).
  v <- ccx_with_obj14_ice(ccx_with_emis_method("spline", ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)))
  st <- attr(v, "streams")
  expect_identical(names(st), names(a$streams))
  d <- unlist(st) - unlist(a$streams)
  expect_lt(max(abs(d)), 1e-8)
  # the logpost = the screen's objective (streams + the 29 names' priors + its D2 penalty)
  # + the shares' Beta(1,2) x U(0,1) prior and their logit Jacobians, which the screen's
  # maximum-likelihood treatment of the shares left out -- nothing else
  pv <- ccx_unc_to_par(u)
  pri29 <- sum(vapply(md$param_names, function(n) { s <- CCX_PARAM_TABLE[[n]]
    .ccx_prior_eval(s, pv[[n]], bp) + .log_jac(u[[n]], s) }, 0))
  screen_obj <- sum(unlist(a$streams)) + pri29 + a$pen_d2[[1]]
  extra <- stats::dbeta(sl, 1, 2, log = TRUE) + stats::dunif(rest, log = TRUE) +
           log(sl) + log(1 - sl) + log(rest) + log(1 - rest)
  expect_equal(as.numeric(v) - screen_obj, extra, tolerance = 1e-8)
})

test_that("7. a mode file under an open label carries its gate WITH ITS PINS (the adoption idiom)", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file("hilda33d"))
  expect_true(ccx_gate_open(ccx_mode_struct(md)))
  nm0 <- CCX_PARAM_NAMES; tab0 <- CCX_PARAM_TABLE
  # the gate CLOSED: the file still carries this build FOR ITS STRUCTURE, and decodes
  expect_true(ccx_mode_carries_build(md)); expect_length(ccx_mode_absent(md), 0L)
  expect_silent(ccx_check_mode_decode(md))
  pins <- ccx_mode_pins(md)
  expect_identical(attr(pins, "gate_struct"), "hilda_csl3v0kaidgb")
  expect_identical(ccx_pin_label(pins), ccx_pin_label(md$pins))     # names / values / label unchanged
  # the idiom opens the gate, then pins: the table IS the file's fitted set
  rm <- ccx_apply_pins(pins); on.exit(.gp_restore(pins = rm), add = TRUE)
  expect_identical(CCX_PARAM_NAMES, md$param_names)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "test")))
  expect_length(st$absent, 0L); expect_identical(st$logpost_shift, 0)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  v <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(st$u)
  expect_identical(attr(v, "streams"), md$streams)                    # the stored streams reproduce
  expect_equal(as.numeric(v), md$logpost, tolerance = 1e-10)
  # unpinning closes the gate again, exactly
  ccx_unpin_params(rm); rm <- list()
  expect_identical(CCX_PARAM_NAMES, nm0); expect_identical(CCX_PARAM_TABLE, tab0)
  # a gate ALREADY open (an open-label array) is left open by the file's pins
  h <- ccx_apply_gate("hilda_csl3v0kaidgb"); on.exit(.gp_restore(h), add = TRUE)
  r2 <- ccx_apply_pins(pins); expect_length(attr(r2, "gate"), 0L); ccx_unpin_params(r2)
  expect_true(all(names(CCX_PARAM_GATED) %in% CCX_PARAM_NAMES))
  # an OLDER file's pins carry no gate
  expect_null(attr(ccx_mode_pins(readRDS(ccx_mode_file("hilda29l"))), "gate_struct"))
})
