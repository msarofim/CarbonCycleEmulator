# =====================================================================
# THE TROPICAL SURFACE BOX `tr` (the equatorial cell's SECOND build, 2026-09-14f)
#
# notes/prereg_2026-09-14f_tr_box_build.md -- rulings R1-R4 of 09-14 (d), the
# D1 area choice extended to `tr` (a_ml = a_ls - a_eq - a_tr), choice D2 (the
# box carries its AREA SHARE of the LS pump export; measured before any PT
# number: without it a 40 %-of-area residual mixed layer drained to ~195 uatm
# and `tr` became the pump's outgassing window), and the P0 contracts this
# file holds. NOTHING here is read against the science (PT1-PT7 live in
# calibration/diag_tr_box_probe.R and the array).
#
#   P0a NO-OP        tr_frac = 0 is bit-exact with hilda_eq, both cores, and
#                    the canonical's stored streams reproduce.
#   P0b CONSERVATION closed-system sum(dC/dt) ~ 0 with eq + tr on, three enso.
#   P0c PARITY       R vs C++ derivative and transient, all three structures.
#   P0d READER NO-OP the surface reader is the ML alone at tr_frac = 0 and the
#                    three-box mass mixture with the box present.
#   P0e READER-DERIV the exported tr_pco2 column IS the derivative's value; B1
#                    is the four-box area contrast.
#   P0f MIRROR LINT  a mixed tr_frac pair errors by name; order, stride 20,
#                    the area partition; range checks by name; the D1 guard.
#   P0g FIXED POINT  a uniform column with eq AND tr at the same concentration
#                    has zero tendency from the loop, the tr interface and q_tr.
#   N-T1             tr_frac = 0 with hilda_eq's SSTs restored IS hilda_eq.
# + every limb MUTATION-TESTED ([[no_power_null]]).
# =====================================================================

tr_par <- function(seas_ml = 1, w_eq = 27, gamma_eq = 1) {
  p <- ccx_apply_structure(ccx_default_params(), "hilda_tr", seas_ml = seas_ml)
  p$w_eq <- w_eq; p$gamma_eq <- gamma_eq
  p
}
eq_par_tr <- function(seas_ml = 1, w_eq = 27, gamma_eq = 1) {
  p <- ccx_apply_structure(ccx_default_params(), "hilda_eq", seas_ml = seas_ml)
  p$w_eq <- w_eq; p$gamma_eq <- gamma_eq
  p
}
zero_forc_tr <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)

test_that("the box ships OFF, off means ABSENT, and the structure is READ from the product with its three SST overrides", {
  p <- ccx_default_params()
  expect_identical(p$tr_frac_NH, 0); expect_identical(p$tr_frac_SH, 0)
  expect_identical(p$q_tr, 0); expect_identical(p$kz_tr_frac, 1)
  expect_false(ccx_tr_on(p))
  expect_length(ccx_box_names(N_INTERIOR, TRUE, TRUE, TRUE), 40L)
  expect_length(ccx_box_names(N_INTERIOR, TRUE, FALSE, TRUE), 38L)
  expect_length(ccx_box_names(N_INTERIOR, FALSE, FALSE, TRUE), 34L)
  expect_length(ccx_box_names(N_INTERIOR, TRUE, TRUE, FALSE), 38L)
  p$tr_frac_NH <- NULL; p$tr_frac_SH <- NULL
  expect_false(ccx_tr_on(p))
  expect_null(ccx_prepare(p)$idx$NH$tr)
  # the labels the objective knows, in ONE place
  expect_identical(CCX_STRUCT_LABELS, c("", "hilda", "hilda_eq", "hilda_tr", "hilda_c", "hilda_cl2", "hilda_cl3", "hilda_csl3", "hilda_cs", "hilda_csl3v0", "hilda_csl3v0k", "hilda_csl3v0ka", "hilda_csl3v0kan", "hilda_csl3v0kai", "hilda_csl3v0kaidgb", "hilda_csl3v0kaidgbe", "hilda_csl3v0kaidgbem", "hilda_csl3v0kaidgbemw", "hilda_csl3v0kaidgbemwt"))  # + the redesigned cut (2026-10-07, objective #18; Marcus: "Full redesign (Recommended)", the name "hilda_csl3v0kaidgbemwt (Recommended)")   # + the interannual cut's main half (2026-10-06, objective #17; Marcus: "Build: land + ocean module (Recommended)", the name "hilda_csl3v0kaidgbemw (Recommended)")   # + the stratification feedback (2026-10-04; DESIGN §3.4a S; extension authorised by Marcus's ruling "History + futures, one #16 refit")   # + the land ENSO lag fitted, the second gate (2026-10-02, objective #15; the 10-02 plan's "extend the four label ledgers")   # + D2 / D3 fitted, the gate open (2026-09-30, objective #14; the 09-30c handoff's "extend the label ledgers deliberately")   # + the inert soil carve-out (2026-09-30; extension authorised by Marcus: "build the inert pool")   # + NPP option-4 arms A / B1 (2026-09-29; extension authorised by Marcus)   # + the veg-capacity loop OFF (2026-09-28)   # + the NH-flat seasonal ML (2026-09-19 l)   # + the constants batch (2026-09-14 h)
  expect_error(ccx_apply_structure(ccx_default_params(), "hilda_xx"), "unknown structure label")
  o  <- ccx_tr_box_obs(); e <- ccx_eq_cell_obs()
  pt <- ccx_apply_structure(ccx_default_params(), "hilda_tr")
  expect_identical(attr(pt, "struct"), "hilda_tr")
  expect_identical(pt$tr_frac_NH, unname(o$tr_frac$value[["NH"]]))
  expect_identical(pt$tr_frac_SH, unname(o$tr_frac$value[["SH"]]))
  expect_identical(pt$h_tr, o$h_tr$both$mean)
  expect_identical(pt$alk_tr, o$alk_tr$both$target)
  w <- o$tr_frac$value / sum(o$tr_frac$value)
  expect_equal(pt$sst_tr, unname(sum(w * o$sst$tr[c("NH", "SH")])))
  # R5 (09-14 g): the EXCESS slopes over the hemispheric anomaly, both boxes
  expect_equal(pt$sst_tr_enso, unname(sum(w * c(o$sst_excess$tr$NH$beta_annual, o$sst_excess$tr$SH$beta_annual))))
  expect_lt(abs(pt$sst_tr_enso), 0.05)                                  # the band warms WITH its hemisphere
  ew0 <- e$eq_frac$value / sum(e$eq_frac$value)
  expect_equal(pt$sst_eq_enso, unname(sum(ew0 * c(o$sst_excess$eq$NH$beta_annual, o$sst_excess$eq$SH$beta_annual))))
  expect_lt(pt$sst_eq_enso, ccx_apply_structure(ccx_default_params(), "hilda_eq")$sst_eq_enso)   # excess < absolute
  expect_gt(pt$sst_eq_enso, 0.5)
  # the three overrides: the residual ML's re-based SST and the re-based cell
  expect_identical(pt$sst_NH, unname(o$sst$ml[["NH"]]))
  expect_identical(pt$sst_SH, unname(o$sst$ml[["SH"]]))
  expect_lt(pt$sst_NH, 18); expect_lt(pt$sst_SH, 16)              # cooler than the typed values
  ew <- e$eq_frac$value / sum(e$eq_frac$value)
  expect_equal(pt$sst_eq, unname(sum(ew * o$sst$eq[c("NH", "SH")])))
  expect_lt(pt$sst_eq, ccx_apply_structure(ccx_default_params(), "hilda_eq")$sst_eq)   # re-based < un-re-based
  # the cell's block rides along unchanged but for sst_eq and sst_eq_enso; HILDA's too
  pe <- ccx_apply_structure(ccx_default_params(), "hilda_eq")
  for (n in c("eq_frac_NH", "eq_frac_SH", "h_eq", "alk_eq", "k_eq", "hs_frac", "tau_q"))
    expect_identical(pt[[n]], pe[[n]], info = n)
  # no duplicated name in the block (the c()-of-two-lists trap)
  expect_false(anyDuplicated(names(ccx_struct_hilda_tr())) > 0)
  # the fitted names are NOT set by the structure; q_tr stays 0 (R4)
  expect_identical(pt$w_eq, 0); expect_identical(pt$gamma_eq, 0); expect_identical(pt$q_tr, 0)
  expect_identical(length(CCX_PARAM_NAMES), 38L)   # + the layer-2 limb w_enso_l2 (2026-09-17 k)                     # no new fitted name from THIS build (37 = 36 + w_thc, O1 arm THC 2026-09-15 d; 36 = 33 + option D+E's three, 2026-09-14 h)
})

test_that("P0f MIRROR LINT: a mixed pair errors by name; order, stride and the area partition; checks by name; the D1 guard", {
  p <- ccx_default_params(); p$tr_frac_NH <- 0.4
  expect_error(ccx_tr_on(p), "MIRROR BOXES")
  expect_error(ccx_prepare(p), "MIRROR BOXES")
  p$tr_frac_NH <- 0; p$tr_frac_SH <- 0.2
  expect_error(ccx_tr_on(p), "MIRROR BOXES")
  pt  <- tr_par()
  aux <- ccx_prepare(pt)
  expect_identical(aux$tr_on, 1L); expect_identical(aux$eq_on, 1L)
  bn <- ccx_box_names(aux$grid$nl, TRUE, TRUE, TRUE)
  expect_identical(bn[aux$idx$NH$tr], "NH_tr"); expect_identical(bn[aux$idx$SH$tr], "SH_tr")
  # ORDER IS LOAD-BEARING: after eq, and no existing index moves
  expect_identical(aux$idx$NH$tr, aux$idx$NH$eq + 1L)
  expect_identical(aux$idx$SH$tr - aux$idx$NH$tr, 20L)                    # the stride
  ae <- ccx_prepare(eq_par_tr())
  expect_identical(aux$idx$NH$eq, ae$idx$NH$eq); expect_identical(aux$idx$NH$hs, ae$idx$NH$hs)
  # ... and in eq's slot when the cell is off (tr without eq is legal: a passive box)
  q <- ccx_apply_structure(ccx_default_params(), "hilda"); q$tr_frac_NH <- 0.4; q$tr_frac_SH <- 0.2
  q$h_tr <- 42; q$sst_tr <- 27; q$sst_tr_enso <- 0.2; q$alk_tr <- 2299
  aq <- ccx_prepare(q)
  expect_false(ccx_eq_on(q)); expect_true(ccx_tr_on(q))
  expect_identical(aq$idx$NH$tr, aq$idx$NH$hd + 1L)
  expect_identical(aq$idx$SH$tr - aq$idx$NH$tr, 19L)
  # D1 extended: the box's area comes out of the MIXED LAYER; the interior keeps a_ls
  for (h in HEMIS) {
    expect_equal(aux$a_ml[[h]] + aux$a_eq[[h]] + aux$a_tr[[h]] + aux$a_hs[[h]], aux$a_oc[[h]])
    expect_equal(aux$a_ml[[h]] + aux$a_eq[[h]] + aux$a_tr[[h]], aux$a_ls[[h]])
    expect_equal(aux$a_tr[[h]] / aux$a_oc[[h]], pt[[paste0("tr_frac_", h)]])
    expect_gt(aux$a_ml[[h]], 0)
    # D2: the ML's pump share is its share of the surface the column has
    expect_equal(aux$ml_pump_share[[h]], aux$a_ml[[h]] / (aux$a_ml[[h]] + aux$a_tr[[h]]))
    expect_identical(ae$ml_pump_share[[h]], 1)
  }
  expect_identical(aux$kz_tr, aux$kz_int[1])                              # kz_tr_frac 1 = the ML idiom
  # the geometry is range-checked by NAME, never clamped
  bad <- pt; bad$h_tr <- 0;      expect_error(ccx_prepare(bad), "h_tr")
  bad <- pt; bad$h_tr <- 500;    expect_error(ccx_prepare(bad), "h_tr")
  bad <- pt; bad$sst_tr <- 40;   expect_error(ccx_prepare(bad), "sst_tr")
  bad <- pt; bad$alk_tr <- -1;   expect_error(ccx_prepare(bad), "alk_tr")
  bad <- pt; bad$q_tr <- -1;     expect_error(ccx_prepare(bad), "q_tr")
  bad <- pt; bad$kz_tr_frac <- -1; expect_error(ccx_prepare(bad), "kz_tr_frac")
  bad <- pt; bad$tr_frac_NH <- 0.9; bad$tr_frac_SH <- 0.9
  expect_error(ccx_prepare(bad), "no area")
  # the D1 guard covers the box: the older ML-touching limbs are refused by name
  q <- ccx_apply_structure(ccx_default_params(), "hilda"); q$tr_frac_NH <- 0.4; q$tr_frac_SH <- 0.2
  q$h_tr <- 42; q$sst_tr <- 27; q$sst_tr_enso <- 0.2; q$alk_tr <- 2299
  for (nm in c("w_up", "w_out_NH", "w_out_SH", "q_conv")) {
    q2 <- q; q2[[nm]] <- 1
    expect_error(ccx_prepare(q2), "do not close under D1", info = nm)
  }
})

test_that("P0a NO-OP: tr_frac = 0 is BIT-EXACT with hilda_eq with every tr parameter set, both cores", {
  p <- eq_par_tr(seas_ml = 1)
  q <- p; q$tr_frac_NH <- 0; q$tr_frac_SH <- 0; q$h_tr <- 42.6; q$sst_tr <- 27.2
  q$sst_tr_enso <- 0.2; q$alk_tr <- 2299; q$q_tr <- 5; q$kz_tr_frac <- 0.3
  a <- ccx_spinup(p); b <- ccx_spinup(q)
  expect_identical(nrow(a$y), 38L); expect_identical(nrow(b$y), 38L)
  expect_identical(a$y, b$y)
  expect_identical(a$aux$ml_mass_kg, b$aux$ml_mass_kg)
  expect_identical(a$aux$asx, b$aux$asx)
  expect_identical(a$aux$a_ml, b$aux$a_ml)
  expect_identical(b$aux$ml_pump_share, list(NH = 1, SH = 1))
  expect_identical(ccx_tr_box_eigbound(q, a$grid), 0)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(q))
  F0 <- zero_forc_tr(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux),
                   ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  skip_if_no_cpp()
  F  <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14)
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F)
  expect_identical(ra$state, rb$state)
  phys <- ccx_out_na_guard_cols(ra$out, p)
  expect_false(any(grepl("^tr_", phys)))
  expect_identical(ra$out[, phys], rb$out[, phys])
  expect_true(all(is.na(ra$out$tr_C_NH))); expect_true(all(is.na(ra$out$tr_pco2_SH)))
  expect_identical(ra$substeps, rb$substeps)
})

test_that("P0a (canonical): the canonical's stored LIKELIHOOD reproduces row by row under this build", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  expect_false(ccx_tr_on(bp)); expect_false(ccx_eq_on(bp))
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  new_names <- setdiff(CCX_PARAM_NAMES, c(md$param_names, names(md$pins)))
  # 2026-09-17 (h): absent (a hilda file) or PINNED (hilda30h) -- not fitted either way
  # 2026-09-20 (r): DERIVED -- the names inert under the canonical's own structure / field (w_enso_l2 is
  # FITTED under hilda_csl3, so it is not among them; it was, under hilda_c)
  six <- ccx_inert_names(ccx_mode_pump_field(md), ccx_mode_struct(md))   # + the layer-2 limb w_enso_l2 (2026-09-17 k)
  expect_setequal(union(new_names, intersect(names(md$pins), six)), six)   # + O1 arm THC (2026-09-15 d)   # NO new fitted name from the tr build   # + option D+E's three (2026-09-14 h)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-tr"))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  st <- attr(sc, "streams")
  expect_identical(st[names(md$streams)], md$streams)          # 25 rows, bit-exact
  expect_false("eq_b1" %in% names(st))
})

test_that("N-T1: tr_frac = 0 with hilda_eq's SSTs restored IS hilda_eq; the mask change alone is a measured move, not a no-op", {
  # the bit-exact form: undo the three overrides and switch the box off
  pt <- tr_par(seas_ml = 0); pe <- eq_par_tr(seas_ml = 0)
  q <- pt; q$tr_frac_NH <- 0; q$tr_frac_SH <- 0
  q$sst_NH <- pe$sst_NH; q$sst_SH <- pe$sst_SH; q$sst_eq <- pe$sst_eq
  a <- ccx_spinup(pe); b <- ccx_spinup(q)
  expect_identical(a$y, b$y)
  # the MEASURED form (R3's read is the probe's; here only its sign): the
  # re-based, cooler SSTs alone move the PI state -- the mask change is real
  q2 <- pt; q2$tr_frac_NH <- 0; q2$tr_frac_SH <- 0
  c2 <- ccx_spinup(q2)
  expect_gt(max(abs(c2$y[, "C"] - a$y[, "C"])), 1e-3)
})

test_that("the spinup converges with eq + tr on; the box sits at its OWN Henry point when isolated", {
  pt <- tr_par(seas_ml = 0)
  sp <- ccx_spinup(pt)
  expect_identical(nrow(sp$y), 40L)
  expect_lt(sp$diagnostics$max_abs_dCdt, 1e-8)
  expect_lt(sp$diagnostics$max_abs_dC13dt, 1e-8)
  for (h in HEMIS) expect_gt(sp$y[sp$aux$idx[[h]]$tr, "C"], 0)
  # ISOLATED (no loop, no interface, no lateral exchange, no pump) the box can
  # only exchange with the atmosphere, so at PI its pCO2 IS the atmosphere's
  q <- pt; q$w_eq <- 0; q$kz_tr_frac <- 0; q$q_tr <- 0; q$pump_grad <- 0; q$pump_hs_gcm2 <- 0
  sq <- ccx_spinup(q)
  d <- ccx_deriv(sq$y, 1750, q, zero_forc_tr(sq$prod_c14), sq$grid, sq$aux, record = TRUE)
  fl <- attr(d, "fluxes")
  for (h in HEMIS) expect_equal(fl$pco2_tr[[h]], ccx_const("CO2_PI_PPM"), tolerance = 1e-6)
})

test_that("P0b CONSERVATION: closed system, eq + tr on, at three Nino3.4 values, and through a seasonal transient", {
  pt <- tr_par(); pt$q_tr <- 2                      # the lateral limb live too
  sp <- ccx_spinup(pt)
  for (en in c(-1.7, 0, 1.7)) {
    d <- ccx_deriv(sp$y, 1750.3, pt, zero_forc_tr(0, enso = en), sp$grid, sp$aux)
    expect_lt(abs(sum(d[, "C"])), 1e-9)
    expect_lt(abs(sum(d[, "C13"])), 1e-9)
  }
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1750, 1752), prod_c14 = sp$prod_c14)
  F$e_foss_NH[] <- 0; F$e_foss_SH[] <- 0; F$e_luc_NH[] <- 0; F$e_luc_SH[] <- 0
  F$cum_luc_NH[] <- 0; F$cum_luc_SH[] <- 0
  r <- ccx_run_fast(sp, F)
  tot0 <- sum(sp$y[, "C"]); tot1 <- sum(r$state[, "C"])
  expect_lt(abs(tot1 - tot0) / tot0, 1e-10)
})

test_that("P0c PARITY: R and C++ agree with all three structures on -- derivative, transient, the pCO2 columns, and the DIC-limited pump", {
  skip_if_no_cpp()
  for (mode in c("N", "D")) {
    pt <- tr_par(); pt$q_tr <- 2; pt$pump_mode <- mode
    sp <- ccx_spinup(pt)
    F  <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = sp$prod_c14)
    for (i in c(1L, 7L)) {
      fr <- ccx_forcing_at(F, i)
      dR <- ccx_deriv(sp$y, F$t[i], pt, fr, sp$grid, sp$aux)
      dC <- ccx_deriv_fast(sp$y, F$t[i], pt, fr, sp$grid, sp$aux)
      expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10)
    }
    r  <- ccx_run_fast(sp, F)
    rR <- suppressWarnings(ccx_run(sp, F))
    expect_false(anyNA(r$out))                        # every column live: all structures on
    expect_identical(ncol(r$out), 1L + 11L + length(CCX_OCEAN_BOX_COLS))
    for (cc in setdiff(names(r$out), "t"))
      expect_lt(max(abs(rR$out[[cc]] - r$out[[cc]])) / max(abs(r$out[[cc]])), 1e-12,
                label = paste("R vs C++ transient column", cc, "pump", mode))
    expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
    expect_identical(rownames(r$state)[sp$aux$idx$SH$tr], "SH_tr")
  }
})

test_that("P0e READER-DERIV PARITY: tr_pco2 is the derivative's own value; B1 is the four-box area contrast", {
  skip_if_no_cpp()
  pt <- tr_par()
  sp <- ccx_spinup(pt)
  F  <- ccx_build_forcing("historical", c(1900, 1901), prod_c14 = sp$prod_c14)
  r  <- ccx_run_fast(sp, F)
  d <- ccx_deriv(sp$y, F$t[1], pt, ccx_forcing_at(F, 1L), sp$grid, sp$aux, record = TRUE)
  fl <- attr(d, "fluxes")
  for (h in HEMIS) {
    expect_equal(r$out[[paste0("tr_pco2_", h)]][1], fl$pco2_tr[[h]], tolerance = 1e-9)
    expect_equal(r$out[[paste0("eq_pco2_", h)]][1], fl$pco2_eq[[h]], tolerance = 1e-9)
    expect_equal(r$out[[paste0("ml_pco2_", h)]][1], fl$pco2_ml[[h]], tolerance = 1e-9)
  }
  o <- r$out[1:24, ]; o$t <- 2014 + (seq_len(24) - 0.5) / 12
  for (h in HEMIS) { o[[paste0("ml_pco2_", h)]] <- 300; o[[paste0("hs_pco2_", h)]] <- 300
                     o[[paste0("eq_pco2_", h)]] <- 360; o[[paste0("tr_pco2_", h)]] <- 320 }
  m <- ccx_model_eq_b1(o, sp$aux, years = c(2014L, 2015L))
  a <- sp$aux
  a_all <- sum(unlist(a$a_ml), unlist(a$a_hs), unlist(a$a_eq), unlist(a$a_tr))
  all_m <- (300 * (sum(unlist(a$a_ml)) + sum(unlist(a$a_hs))) + 360 * sum(unlist(a$a_eq)) +
            320 * sum(unlist(a$a_tr))) / a_all
  expect_equal(m$value, 360 - all_m)
})

test_that("P0d READER NO-OP: the surface reader is the ML alone at tr_frac = 0, and the three-box mass mixture with the box present", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 0)
  sp <- ccx_spinup(p)
  n <- 36; tt <- 1999 + (seq_len(n) - 0.5) / 12
  o <- data.frame(t = tt)
  for (cc in CCX_OCEAN_BOX_COLS) o[[cc]] <- NA_real_
  for (h in HEMIS) {
    o[[paste0("ml_C_", h)]]   <- sp$y[sp$aux$idx[[h]]$ml, "C"] * (1 + 0.01 * sin(2 * pi * tt))
    o[[paste0("ml_C13_", h)]] <- sp$y[sp$aux$idx[[h]]$ml, "C13"] * (1 + 0.01 * sin(2 * pi * tt))
    o[[paste0("deep_C_", h)]]   <- sp$y[tail(sp$aux$idx[[h]]$oc, 1), "C"]
    o[[paste0("deep_C13_", h)]] <- sp$y[tail(sp$aux$idx[[h]]$oc, 1), "C13"]
  }
  ml_only <- ccx_box_annual_conc(o, sp$aux, sp$grid, "ml", 2000)
  surf    <- ccx_surface_annual_conc(o, sp$aux, sp$grid, 2000)
  expect_identical(unname(surf[["dic"]]),  unname(ml_only[["dic"]]))
  expect_identical(unname(surf[["d13c"]]), unname(ml_only[["d13c"]]))
  # with eq AND tr present: ml at 2000, eq +100, tr -50 umol/kg -> the mass mixture
  pt <- tr_par(seas_ml = 0); spt <- ccx_spinup(pt)
  ot <- o; M <- list()
  for (b in c("ml", "eq", "tr")) for (h in HEMIS) {
    m <- ccx_box_mass_at(spt$aux, spt$grid, b, h, 2000); M[[paste(b, h)]] <- m
    dic <- 2.0e-3 + switch(b, ml = 0, eq = 100e-6, tr = -50e-6)
    ot[[paste0(b, "_C_", h)]]   <- dic * m / spt$aux$mol_per_GtC
    ot[[paste0(b, "_C13_", h)]] <- ot[[paste0(b, "_C_", h)]] * ccx_const("R13_VPDB")
  }
  s <- ccx_surface_annual_conc(ot, spt$aux, spt$grid, 2000)
  Mv <- unlist(M); is <- function(b) grepl(paste0("^", b, " "), names(Mv))
  expect_equal(unname(s[["dic"]]),
               2000 + (100 * sum(Mv[is("eq")]) - 50 * sum(Mv[is("tr")])) / sum(Mv), tolerance = 1e-9)
  expect_equal(unname(s[["d13c"]]), 0, tolerance = 1e-9)
  # the box's mass is its own, constant
  for (h in HEMIS) expect_identical(ccx_box_mass_at(spt$aux, spt$grid, "tr", h, 2000.4), spt$aux$tr_mass_kg[[h]])
})

test_that("P0g FIXED POINT: a uniform column with eq and tr at the same concentration has zero tendency (loop + interface + q_tr)", {
  pt <- tr_par(seas_ml = 0); pt$q_tr <- 3
  aux <- ccx_prepare(pt); grid <- aux$grid
  y <- ccx_new_state(grid$nl, TRUE, TRUE, TRUE)
  conc <- 2.1e-3
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- 600
    y[i$ml, "C"] <- conc * aux$ml_mass_kg[[h]] / aux$mol_per_GtC
    y[i$oc, "C"] <- conc * aux$a_ls[[h]] * grid$dz[-1] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    y[i$eq, "C"] <- conc * aux$eq_mass_kg[[h]] / aux$mol_per_GtC
    y[i$tr, "C"] <- conc * aux$tr_mass_kg[[h]] / aux$mol_per_GtC
    y[i$hs, "C"] <- conc * aux$hs_mass_kg[[h]] / aux$mol_per_GtC
    y[i$hd, "C"] <- conc * aux$a_hs[[h]] * aux$dz_hd * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    for (pool in CCX_LAND_POOLS) y[i[[pool]], "C"] <- 100
  }
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB"); y[, "C14"] <- y[, "C"]
  # isolate the transport: no air-sea, no pumps, no HS exchange, no land; kz ON
  # (the tr / layer-1 interface and the column's diffusion are both flux-free
  # at uniform concentration)
  q <- pt; q$k_w <- 0; q$pump_grad <- 0; q$pump_hs_gcm2 <- 0
  q$u_hs <- 0; q$tau_q <- 0; q$w_up <- 0; q$w_out_NH <- 0; q$w_out_SH <- 0
  q <- ccx_set_enso(q, list(gamma_enso = 0)); q$seas_drivers <- 0; q$gamma_diff <- 0
  aq <- ccx_prepare(q)
  ocean <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$eq, aux$idx[[h]]$tr)))
  d <- ccx_deriv(y, 1750.25, q, zero_forc_tr(0, enso = -0.8), aq$grid, aq)
  expect_lt(max(abs(d[ocean, "C"])), 1e-12)
  expect_lt(max(abs(d[ocean, "C13"])), 1e-12)
  skip_if_no_cpp()
  dC <- ccx_deriv_fast(y, 1750.25, q, zero_forc_tr(0, enso = -0.8), aq$grid, aq)
  expect_lt(max(abs(dC[ocean, "C"])), 1e-12)
  # POWER: the same state with the box 10 % richer is NOT a fixed point
  y2 <- y; for (h in HEMIS) y2[aux$idx[[h]]$tr, ] <- y2[aux$idx[[h]]$tr, ] * 1.1
  d2 <- ccx_deriv(y2, 1750.25, q, zero_forc_tr(0, enso = -0.8), aq$grid, aq)
  expect_gt(max(abs(d2[ocean, "C"])), 1e-3)
  # ... and the loop carries the 10 % away from the box: tr's own tendency is negative
  for (h in HEMIS) expect_lt(d2[aux$idx[[h]]$tr, "C"], 0)
})

test_that("P0g-tr FIXED POINT with the CELL OFF (audit 2026-09-15 d): tr-only shrinks a_ml, so the ML/layer-1 interface, the seasonal excursion and entrainment must read a_ml too", {
  # The 09-15 (d) flux audit: a_ml = a_ls - a_eq - a_tr is formed under
  # eq_on || tr_on, but three sites gated the a_ls/a_ml correction on eq_on
  # ALONE (the ML/layer-1 diffusion thickness, the seasonal-ML volume share,
  # entrainment). With tr on and the cell off a uniform column was NOT
  # flux-free (a permanent oc1 -> ml diffusive flux ~ K conc (a_ls - a_ml) /
  # dz_mid) and the seasonal ML created a_tr dh/dt of water each half-year.
  # Carbon stayed conserved (antisymmetric), so no conservation gate saw it.
  pt <- tr_par(seas_ml = 1, w_eq = 0, gamma_eq = 0)
  pt$eq_frac_NH <- 0; pt$eq_frac_SH <- 0; pt$q_tr <- 3
  expect_false(ccx_eq_on(pt)); expect_true(ccx_tr_on(pt))
  q <- pt; q$k_w <- 0; q$pump_grad <- 0; q$pump_hs_gcm2 <- 0
  q$u_hs <- 0; q$tau_q <- 0; q$w_up <- 0; q$w_out_NH <- 0; q$w_out_SH <- 0
  q <- ccx_set_enso(q, list(gamma_enso = 0)); q$gamma_diff <- 0
  aq <- ccx_prepare(q); grid <- aq$grid
  expect_lt(aq$a_ml$NH, aq$a_ls$NH)   # the partition IS reduced with the cell off
  uni <- function(aux, conc = 2.1e-3) {
    y <- ccx_new_state(grid$nl, TRUE, FALSE, TRUE)
    for (h in HEMIS) {
      i <- aux$idx[[h]]
      y[i$atm, "C"] <- 600
      y[i$ml, "C"] <- conc * aux$ml_mass_kg[[h]] / aux$mol_per_GtC
      y[i$oc, "C"] <- conc * aux$a_ls[[h]] * grid$dz[-1] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
      y[i$tr, "C"] <- conc * aux$tr_mass_kg[[h]] / aux$mol_per_GtC
      y[i$hs, "C"] <- conc * aux$hs_mass_kg[[h]] / aux$mol_per_GtC
      y[i$hd, "C"] <- conc * aux$a_hs[[h]] * aux$dz_hd * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
      for (pool in CCX_LAND_POOLS) y[i[[pool]], "C"] <- 100
    }
    y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB"); y[, "C14"] <- y[, "C"]
    y
  }
  ocean <- unlist(lapply(HEMIS, function(h) c(aq$idx[[h]]$ml, aq$idx[[h]]$oc, aq$idx[[h]]$tr)))
  # (i) at the annual-mean ML (seasonal drivers off) the interface is flux-free
  q0 <- q; q0$seas_drivers <- 0; a0 <- ccx_prepare(q0)
  y  <- uni(a0)
  d  <- ccx_deriv(y, 1750.25, q0, zero_forc_tr(0), a0$grid, a0)
  expect_lt(max(abs(d[ocean, "C"])), 1e-12)
  # (ii) with the seasonal ML on, at a mid-excursion instant, a uniform
  #      column STAYS uniform: the only non-zero ocean tendency is the
  #      entrainment pair, and it is exactly conc x (the volume that moved)
  #      = conc x a_ml x dh/dt -- booked over a_ml, not a_ls. (Before the fix
  #      it was conc x a_ls x dh/dt plus a spurious diffusive term: 595 GtC/yr
  #      off at this instant.) The diffusion and the tr interface are silent.
  a1 <- ccx_prepare(q); y1 <- uni(a1)
  want <- numeric(nrow(y1))
  for (h in HEMIS) {   # re-scale the ML and layer 1 to the mass AT THE TIME
    i <- a1$idx[[h]]
    ev <- ccx_mld_eval(a1$mld_coef[[h]], 1750.25)
    expect_gt(abs(ev$f - 1), 0.05)   # a real excursion, not the mean
    expect_gt(abs(ev$dfdt), 0.05)    # and a real rate
    h_t <- grid$h_ml * ev$f
    y1[i$ml, ] <- y1[i$ml, ] * ev$f
    y1[i$oc[1], ] <- y1[i$oc[1], ] * (grid$dz[2] + (grid$dz[1] - h_t) * a1$a_ml[[h]] / a1$a_ls[[h]]) / grid$dz[2]
    ent <- 2.1e-3 * a1$a_ml[[h]] * grid$h_ml * ev$dfdt * ccx_const("RHO_SEAWATER") / a1$mol_per_GtC
    want[i$ml] <- ent; want[i$oc[1]] <- -ent
  }
  d1 <- ccx_deriv(y1, 1750.25, q, zero_forc_tr(0), a1$grid, a1)
  expect_lt(max(abs(d1[ocean, "C"] - want[ocean])), 1e-9)
  expect_gt(max(abs(want[ocean])), 1)   # POWER: the pair is not trivially small
  skip_if_no_cpp()
  dC0 <- ccx_deriv_fast(y, 1750.25, q0, zero_forc_tr(0), a0$grid, a0)
  expect_lt(max(abs(dC0[ocean, "C"])), 1e-12)
  dC1 <- ccx_deriv_fast(y1, 1750.25, q, zero_forc_tr(0), a1$grid, a1)
  expect_lt(max(abs(dC1[ocean, "C"] - want[ocean])), 1e-9)
  expect_lt(max(abs(dC1 - d1)), 1e-10)
})

test_that("EVERY limb is mutation-tested: break it and the model must move", {
  skip_if_no_cpp()
  base <- tr_par(seas_ml = 0)
  sp0  <- ccx_spinup(base)
  F    <- ccx_build_forcing("historical", c(1960, 1962), prod_c14 = sp0$prod_c14)
  ref  <- ccx_run_fast(sp0, F)
  trp  <- function(r) mean(r$out$tr_pco2_NH, na.rm = TRUE)
  eqp  <- function(r) mean(r$out$eq_pco2_NH, na.rm = TRUE)
  # (a) the loop's re-routing: with tr on, w_eq = 0 must move BOTH boxes
  q <- base; q$w_eq <- 0; r <- ccx_run_fast(ccx_spinup(q), F)
  expect_gt(abs(trp(r) - trp(ref)), 0.5); expect_gt(abs(eqp(r) - eqp(ref)), 5)
  # (b) the interface: kz_tr_frac 0 must move the box (R6's lever)
  q <- base; q$kz_tr_frac <- 0; r <- ccx_run_fast(ccx_spinup(q), F)
  expect_gt(abs(trp(r) - trp(ref)), 1)
  # (c) the lateral exchange: q_tr 0 -> 20 Sv must move the box
  q <- base; q$q_tr <- 20; r <- ccx_run_fast(ccx_spinup(q), F)
  expect_gt(abs(trp(r) - trp(ref)), 0.1)
  # (d) the box's own solubility term (R5): the excess slope is ~0 as built,
  #     so the mutation SETS one (0.2, the absolute slope) at the SAME spinup
  q <- base; q$sst_tr_enso <- 0.2; sp <- ccx_spinup(q)
  expect_identical(sp$y, sp0$y)                     # the spinup runs at enso = 0
  r <- ccx_run_fast(sp, F)
  expect_gt(max(abs(r$out$tr_pco2_NH - ref$out$tr_pco2_NH)), 0.05)
  # (e) D2, the pump share: the box pump-free (its share forced onto the ML)
  #     must move the box -- measured as the ML-only pump via ml_pump_share
  aux1 <- sp0$aux; aux1$ml_pump_share <- list(NH = 1, SH = 1)
  sp1 <- sp0; sp1$aux <- aux1
  d0 <- ccx_deriv(sp0$y, 1960, base, ccx_forcing_at(F, 1L), sp0$grid, sp0$aux)
  d1 <- ccx_deriv(sp0$y, 1960, base, ccx_forcing_at(F, 1L), sp1$grid, sp1$aux)
  for (h in HEMIS) expect_gt(abs(d1[sp0$aux$idx[[h]]$tr, "C"] - d0[sp0$aux$idx[[h]]$tr, "C"]), 0.1)
  # (f) the stability bound sees the box, and only when it is on
  expect_gt(ccx_tr_box_eigbound(base, sp0$grid), 0)
  expect_identical(ccx_tr_box_eigbound(eq_par_tr(), sp0$grid), 0)
  expect_gte(ccx_substeps_for(base), ccx_substeps_for(eq_par_tr(seas_ml = 0)))
  # (g) the flux trace classifies the box as a SURFACE box and books q_tr on its own channel
  q <- base; q$q_tr <- 5; aq <- ccx_prepare(q)
  d <- ccx_deriv(sp0$y, 1960, q, ccx_forcing_at(F, 1L), aq$grid, aq, record = TRUE)
  ch <- attr(d, "fluxes")$channels
  expect_gt(ch[["tr_ml"]], 0)
  d0 <- ccx_deriv(sp0$y, 1960, base, ccx_forcing_at(F, 1L), sp0$grid, sp0$aux, record = TRUE)
  expect_identical(attr(d0, "fluxes")$channels[["tr_ml"]], 0)
  expect_gt(attr(d0, "fluxes")$channels[["eq_ml"]], 0)
})
