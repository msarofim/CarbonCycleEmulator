# =====================================================================
# THE EQUATORIAL UPWELLING CELL (Fix B proper, built 2026-09-13g)
#
# notes/prereg_2026-09-13g_equatorial_cell_build.md -- the six rulings of
# 09-13g, design choice D1 (the cell takes its area from the MIXED LAYER only),
# and the P0 contracts this file holds. NOTHING here is read against the
# science (PE1-PE9, N1 live in calibration/diag_eq_cell_probe.R and the array):
# P0 is the set of statements that must be true BEFORE any PE number is read.
#
#   P0a NO-OP        eq_frac = 0 is bit-exact with the 09-13d model, both cores,
#                    and the canonical's stored logpost reproduces.
#   P0b CONSERVATION closed-system sum(dC/dt) ~ 0 with the cell on, at three
#                    Nino3.4 values including the floor's edge.
#   P0c PARITY       R vs C++ derivative and transient with the cell on.
#   P0d READER NO-OP the ocean_grad rows are identical at eq_frac = 0 (the
#                    area-weighted surface reader collapses to the ML alone).
#   P0e READER-DERIV the exported pCO2 columns ARE the derivative's own values.
#   P0f MIRROR LINT  a mixed eq_frac pair errors by name; box order and stride;
#                    a_ml + a_eq + a_hs == a_oc.
#   P0g FIXED POINT  a uniform-concentration column with the cell at the same
#                    concentration has ZERO advective tendency (contract (a)).
# + every limb MUTATION-TESTED (the HILDA file's discipline): switch it off on
#   its own and the model must move ([[no_power_null]]).
# =====================================================================

eq_par <- function(seas_ml = 1, w_eq = 27, gamma_eq = 1) {
  p <- ccx_apply_structure(ccx_default_params(), "hilda_eq", seas_ml = seas_ml)
  p$w_eq <- w_eq; p$gamma_eq <- gamma_eq
  p
}
zero_forc <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)

test_that("the cell ships OFF, off means ABSENT, and the geometry is READ not typed", {
  p <- ccx_default_params()
  expect_identical(p$eq_frac_NH, 0); expect_identical(p$eq_frac_SH, 0)
  expect_false(ccx_eq_on(p))
  expect_length(ccx_box_names(N_INTERIOR), 32L)
  expect_length(ccx_box_names(N_INTERIOR, TRUE), 36L)
  expect_length(ccx_box_names(N_INTERIOR, TRUE, TRUE), 38L)
  expect_length(ccx_box_names(N_INTERIOR, FALSE, TRUE), 34L)
  # a list from before 2026-09-13g has no eq_frac at all: absence == zero
  p$eq_frac_NH <- NULL; p$eq_frac_SH <- NULL
  expect_false(ccx_eq_on(p))
  expect_null(ccx_prepare(p)$idx$NH$eq)
  # the fitted names may be set and still emit nothing: eq_frac is the switch
  q <- ccx_default_params(); q$w_eq <- 27; q$gamma_eq <- 1
  expect_false(ccx_eq_on(q))
  # the structure's values are the PRODUCT's, through the one loader
  o  <- ccx_eq_cell_obs()
  pe <- ccx_apply_structure(ccx_default_params(), "hilda_eq")
  expect_identical(attr(pe, "struct"), "hilda_eq")
  expect_identical(pe$eq_frac_NH, unname(o$eq_frac$value[["NH"]]))
  expect_identical(pe$eq_frac_SH, unname(o$eq_frac$value[["SH"]]))
  expect_identical(pe$h_eq, o$h_eq$both$mean_dt)
  expect_identical(pe$sst_eq, o$sst_eq$both$annual_mean_C)
  expect_identical(pe$sst_eq_enso, o$sst_eq$both$beta_monthly)
  expect_identical(pe$alk_eq, o$alk_eq$both$target)
  expect_identical(pe$k_eq, 2L)                       # ruling 2: layer 2 alone
  expect_identical(pe$hs_frac, 0.16)                  # HILDA's block rides along
  # the fitted names are NOT set by the structure
  expect_identical(pe$w_eq, 0); expect_identical(pe$gamma_eq, 0)
})

test_that("R3: w_eq and gamma_eq are FITTED (31 -> 33), the W0 prior is the PRODUCT's, and a 31-name ancestor migrates to 0 and is SEEDED at init", {
  # 2026-09-13i (the array-launch commit; ruled 09-13h). Adjacent, after u_hs --
  # the other overturning transport -- so the u-vector's tail is the two cells.
  expect_identical(length(CCX_PARAM_NAMES), 38L)   # + the layer-2 limb w_enso_l2 (2026-09-17 k)   # 36 + w_thc (O1 arm THC, 2026-09-15 d); 33 + option D+E's three (2026-09-14 h)
  i <- match(c("u_hs", "w_eq", "gamma_eq"), CCX_PARAM_NAMES)
  expect_identical(diff(i), c(1L, 1L))
  o <- ccx_eq_cell_obs()$w0_prior
  s <- CCX_PARAM_TABLE$w_eq
  expect_identical(s$tr, "logit"); expect_identical(c(s$lo, s$hi), c(5, 60))
  expect_identical(s$init, o$mean_sv)                          # literal vs product (ruling 4: 27 Sv)
  for (x in c(8, 21, 27, 33, 50))                              # the prior IS N(27, 3), read not typed
    expect_equal(s$prior(x), dnorm(x, o$mean_sv, o$sd_sv, log = TRUE))
  expect_equal(s$prior(8) - s$prior(27), -0.5 * ((8 - 27) / 3)^2)   # z -6.3 at the W0 that hits B1 alone
  g <- CCX_PARAM_TABLE$gamma_eq
  expect_identical(g$tr, "logit"); expect_identical(c(g$lo, g$hi), c(0, 2)); expect_identical(g$init, 1)
  expect_identical(g$prior(0.3), g$prior(1.7))                 # FLAT on the box
  expect_identical(g$prior(2.5), -Inf)
  # the migration: a vector without the pair (every registered mode) fills 0 =
  # what it RAN (no loop), says so, and cannot encode -- both sit on a floor
  anc <- ccx_unc_to_par(ccx_init_unc()); anc$w_eq <- NULL; anc$gamma_eq <- NULL
  mig <- ccx_migrate_par_set(anc)
  expect_setequal(attr(mig, "migrated"), c("w_eq", "gamma_eq"))
  expect_identical(mig$w_eq, 0); expect_identical(mig$gamma_eq, 0)
  expect_error(suppressWarnings(ccx_par_to_unc(mig)))
  out <- capture.output(sd <- suppressWarnings(ccx_seed_unencodable(mig, "test")))
  expect_true(any(grepl("SEEDING w_eq", out))); expect_true(any(grepl("SEEDING gamma_eq", out)))
  expect_identical(sd$w_eq, 27); expect_identical(sd$gamma_eq, 1)
  expect_true(all(is.finite(ccx_par_to_unc(sd))))
  # the round trip at the table init reproduces the probe's PE1 point
  back <- ccx_unc_to_par(ccx_init_unc())
  expect_equal(back$w_eq, 27, tolerance = 1e-10); expect_equal(back$gamma_eq, 1, tolerance = 1e-10)
  # and under "hilda" (eq_frac 0) the pair is inert: the deriv is bit-identical
  # whatever they hold -- they are identifiable ONLY under hilda_eq
  p0 <- ccx_apply_structure(ccx_default_params(), "hilda"); p1 <- p0; p1$w_eq <- 40; p1$gamma_eq <- 1.5
  sp <- ccx_spinup(p0); sp1 <- ccx_spinup(p1)
  expect_identical(sp1$y, sp$y)
  expect_identical(ccx_deriv(sp$y, 1750, p1, zero_forc(sp$prod_c14, enso = 1), sp1$grid, sp1$aux),
                   ccx_deriv(sp$y, 1750, p0, zero_forc(sp$prod_c14, enso = 1), sp$grid, sp$aux))
})

test_that("review 09-14: D1 refuses the older ML-touching limbs by name, and a NULL pair is a w_eq = 0 cell in the R core too", {
  # (1) w_up / w_out_* / q_conv book their ML leg over a_ml and the interior leg
  # over a_ls -- they do not close under D1 (0.192 GtC/yr leak at 1 m/yr, measured)
  q <- eq_par(seas_ml = 0)
  for (nm in c("w_up", "w_out_NH", "w_out_SH", "q_conv")) {
    q2 <- q; q2[[nm]] <- 1
    expect_error(ccx_prepare(q2), "do not close under D1", info = nm)
  }
  expect_silent(invisible(ccx_prepare(q)))               # 0 / NULL: the combination is legal
  # the cell OFF keeps every older limb usable
  q0 <- ccx_apply_structure(ccx_default_params(), "hilda"); q0$w_up <- 1
  expect_silent(invisible(ccx_prepare(q0)))
  # (2) absence contract mirrored: the pair deleted == the pair at 0, both cores
  qn <- q; qn$w_eq <- NULL; qn$gamma_eq <- NULL
  q0 <- q; q0$w_eq <- 0
  sp <- ccx_spinup(q0); F <- zero_forc(sp$prod_c14, enso = 1)
  expect_identical(ccx_deriv(sp$y, 1750, qn, F, sp$grid, ccx_prepare(qn)),
                   ccx_deriv(sp$y, 1750, q0, F, sp$grid, ccx_prepare(q0)))
})

test_that("P0f MIRROR LINT: a mixed pair errors by name; order, stride and the area partition", {
  p <- ccx_default_params(); p$eq_frac_NH <- 0.05
  expect_error(ccx_eq_on(p), "MIRROR CELLS")
  expect_error(ccx_prepare(p), "MIRROR CELLS")
  p$eq_frac_NH <- 0; p$eq_frac_SH <- 0.05
  expect_error(ccx_eq_on(p), "MIRROR CELLS")
  pe  <- eq_par()
  aux <- ccx_prepare(pe)
  expect_identical(aux$eq_on, 1L)
  bn <- ccx_box_names(aux$grid$nl, TRUE, TRUE)
  expect_identical(bn[aux$idx$NH$eq], "NH_eq")
  expect_identical(bn[aux$idx$SH$eq], "SH_eq")
  # ORDER IS LOAD-BEARING: after hs/hd, and no existing index moves
  expect_identical(aux$idx$NH$eq, aux$idx$NH$hd + 1L)
  expect_identical(aux$idx$SH$eq - aux$idx$NH$eq, 19L)              # the stride
  expect_identical(aux$idx$NH$hs, ccx_prepare(ccx_apply_structure(ccx_default_params(), "hilda"))$idx$NH$hs)
  # ... and after the interior column when HILDA is off
  q <- ccx_default_params(); q$eq_frac_NH <- 0.048; q$eq_frac_SH <- 0.0356
  q$h_eq <- 44.2; q$sst_eq <- 27; q$sst_eq_enso <- 1; q$alk_eq <- 2296
  aq <- ccx_prepare(q)
  expect_identical(aq$idx$NH$eq, max(aq$idx$NH$oc) + 1L)
  expect_identical(aq$idx$SH$eq - aq$idx$NH$eq, 17L)
  # D1: the cell's area comes out of the MIXED LAYER; the interior keeps a_ls
  for (h in HEMIS) {
    expect_equal(aux$a_ml[[h]] + aux$a_eq[[h]] + aux$a_hs[[h]], aux$a_oc[[h]])
    expect_equal(aux$a_ml[[h]] + aux$a_eq[[h]], aux$a_ls[[h]])
    expect_equal(aux$a_eq[[h]] / aux$a_oc[[h]], pe[[paste0("eq_frac_", h)]])
  }
  # equal upwelling VELOCITY in both cells by construction (prereg §1)
  v <- vapply(HEMIS, function(h) 27 * CCX_SV_TO_M3YR * aux$eq_w_share[[h]] / aux$a_eq[[h]], numeric(1))
  expect_equal(unname(v[1]), unname(v[2]))
  expect_gt(v[1], 50); expect_lt(v[1], 70)              # ~63 m/yr at 27 Sv (prereg); 57.6 here
  # the geometry is range-checked by NAME, never clamped
  bad <- pe; bad$k_eq <- 11L; expect_error(ccx_prepare(bad), "k_eq")
  bad <- pe; bad$h_eq <- 0;   expect_error(ccx_prepare(bad), "h_eq")
  bad <- pe; bad$sst_eq <- 40; expect_error(ccx_prepare(bad), "sst_eq")
  bad <- pe; bad$alk_eq <- -1; expect_error(ccx_prepare(bad), "alk_eq")
})

test_that("P0a NO-OP: eq_frac = 0 is BIT-EXACT with every cell parameter set, both cores", {
  # the HILDA / seas_ml 1 model (the canonical's space) with the cell OFF but
  # every one of its parameters set, against the same list without them
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  q <- p; q$eq_frac_NH <- 0; q$eq_frac_SH <- 0; q$h_eq <- 44.2; q$sst_eq <- 27
  q$sst_eq_enso <- 1; q$alk_eq <- 2296; q$k_eq <- 2L; q$w_eq <- 27; q$gamma_eq <- 1
  a <- ccx_spinup(p); b <- ccx_spinup(q)
  expect_identical(nrow(a$y), 36L); expect_identical(nrow(b$y), 36L)
  expect_identical(a$y, b$y)
  expect_identical(a$diagnostics$d14c_bottom_box, b$diagnostics$d14c_bottom_box)
  # the mixed layer's mass, exchange area and preindustrial carbon are the
  # SAME OBJECTS (a_ml IS a_ls), not a_ls - 0
  expect_identical(a$aux$ml_mass_kg, b$aux$ml_mass_kg)
  expect_identical(a$aux$asx, b$aux$asx)
  expect_identical(a$aux$ml_C0, b$aux$ml_C0)
  # the substep count -- and so every trajectory -- is unchanged
  expect_identical(ccx_eq_cell_eigbound(q), 0)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(q))
  skip_if_no_cpp()
  F  <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14)
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F)
  expect_identical(ra$state, rb$state)
  phys <- ccx_out_na_guard_cols(ra$out, p)
  expect_identical(ra$out[, phys], rb$out[, phys])
  # the eq_* columns are NA by contract, and the NaN guard did not double the substeps on them
  expect_true(all(is.na(ra$out$eq_C_NH))); expect_true(all(is.na(ra$out$eq_pco2_SH)))
  expect_identical(ra$substeps, rb$substeps)
})

test_that("P0a (canonical): the canonical's stored LIKELIHOOD reproduces row by row under this build, and its logpost moves by EXACTLY the two new priors", {
  skip_if_no_cpp()
  # 2026-09-13i: the table carries w_eq / gamma_eq (31 -> 33) and the registered
  # files do not, so the 31-name vector is MIGRATED (0 = what it ran) and SEEDED
  # at init (27 Sv, 1) -- the same path the array's incumbent start takes. Under
  # "hilda" the cell is absent and the pair is INERT, so every one of the 25
  # data rows must reproduce to the bit, and the whole shift in the logpost is
  # the two priors at init plus their Jacobians -- a KNOWN constant, asserted,
  # not a tolerance. (Until the array's mode is promoted the stored logpost
  # itself does not reproduce -- the ruled 09-08d situation; test-mode-file
  # says so for every registered file.)
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  expect_false(ccx_eq_on(bp))
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  new_names <- setdiff(CCX_PARAM_NAMES, c(md$param_names, names(md$pins)))   # w_eq, gamma_eq
  # 2026-09-17 (h): the canonical (hilda30h, hilda_c) PINS the six inert names instead of lacking
  # them -- either way none is FITTED at the canonical, and a pinned one contributes no prior leg
  # 2026-09-20 (r): DERIVED -- the names inert under the canonical's own structure / field (w_enso_l2 is
  # FITTED under hilda_csl3, so it is not among them; it was, under hilda_c)
  six <- ccx_inert_names(ccx_mode_pump_field(md), ccx_mode_struct(md))   # + the layer-2 limb w_enso_l2 (2026-09-17 k)   # + O1 arm THC (2026-09-15 d)   # + option D+E's three (2026-09-14 h)
  expect_setequal(union(new_names, intersect(names(md$pins), six)), six)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a"))
  expect_true(all(new_names %in% attr(pm, "migrated")))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  st <- attr(sc, "streams")
  expect_identical(st[names(md$streams)], md$streams)          # 25 rows, bit-exact
  expect_false("eq_b1" %in% names(st))                          # no B1 row without a cell
  shift <- sum(vapply(new_names, function(n) {
    s <- CCX_PARAM_TABLE[[n]]; s$prior(pm[[n]]) + .log_jac(u[[n]], s) }, numeric(1)))
  # 2026-09-16 b: plus the h_ml BAND TERM -- the file was fitted under [30, 200], the table's floor
  # is CCX_HML_FLOOR_M; the Jacobian difference is a KNOWN constant too (ccx_mode_start()$band_shift,
  # test-hml-floor.R), computed here by hand from the recorded band so the two cannot drift.
  s_h <- CCX_PARAM_TABLE$h_ml; s_rec <- s_h; s_rec$lo <- md$hml_bound[1]; s_rec$hi <- md$hml_bound[2]
  band <- .log_jac(u[["h_ml"]], s_h) - .log_jac(.to_unc(pm[["h_ml"]], s_rec), s_rec)
  expect_equal(as.numeric(sc) - md$logpost, shift + band, tolerance = 1e-8, scale = 1)   # -0.8236 on 09-13i, -0.362 more since 09-16 b
})

test_that("the spinup converges with the cell on, and the cell sits ABOVE the mixed layer in pCO2", {
  # seas_ml = 0 HERE: the aseasonal ccx_spinup() under a seasonal mixed layer
  # is a known non-fixed-point at any single instant (the periodic spinup is
  # the objective's for that reason), and this test reads the ML's pCO2 at one
  pe <- eq_par(seas_ml = 0)
  sp <- ccx_spinup(pe)
  expect_identical(nrow(sp$y), 38L)
  expect_lt(sp$diagnostics$max_abs_dCdt, 1e-8)
  expect_lt(sp$diagnostics$max_abs_dC13dt, 1e-8)
  expect_gt(sp$y[sp$aux$idx$NH$eq, "C"], 0)
  # the preindustrial reservoir: at 27 Sv the cell's pCO2 is ABOVE the ML's
  # (upwelled thermocline water is DIC-rich); the size is PE-territory, the
  # sign is a contract
  d <- ccx_deriv(sp$y, 1750, pe, zero_forc(sp$prod_c14), sp$grid, sp$aux, record = TRUE)
  fl <- attr(d, "fluxes")
  for (h in HEMIS) expect_gt(fl$pco2_eq[[h]], fl$pco2_ml[[h]])
})

test_that("P0b CONSERVATION: closed system, cell on, at three Nino3.4 values", {
  pe <- eq_par()
  sp <- ccx_spinup(pe)
  p0 <- ccx_set_enso(pe, list(gamma_enso = 0)); p0$seas_drivers <- 0
  for (en in c(-1.7, 0, 1.7)) {
    d <- ccx_deriv(sp$y, 1750.3, pe, zero_forc(0, enso = en), sp$grid, sp$aux)
    expect_lt(abs(sum(d[, "C"])), 1e-9)
    expect_lt(abs(sum(d[, "C13"])), 1e-9)
    # the floor: at enso = 1.7 with gamma_eq = 1 the loop is OFF (W = 0) and
    # the cell still exchanges with the atmosphere -- both cores agree below
  }
  # ... and through a transient with the seasonal drivers on
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1750, 1752), prod_c14 = sp$prod_c14)
  F$e_foss_NH[] <- 0; F$e_foss_SH[] <- 0; F$e_luc_NH[] <- 0; F$e_luc_SH[] <- 0
  F$cum_luc_NH[] <- 0; F$cum_luc_SH[] <- 0
  r <- ccx_run_fast(sp, F)
  tot0 <- sum(sp$y[, "C"]); tot1 <- sum(r$state[, "C"])
  expect_lt(abs(tot1 - tot0) / tot0, 1e-10)
})

test_that("P0c PARITY: R and C++ agree with the cell on -- derivative, transient, and the pCO2 columns", {
  skip_if_no_cpp()
  pe <- eq_par()
  sp <- ccx_spinup(pe)
  F  <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = sp$prod_c14)
  for (i in c(1L, 7L)) {          # two months: the ML is thin in one, deep in the other
    fr <- ccx_forcing_at(F, i)
    dR <- ccx_deriv(sp$y, F$t[i], pe, fr, sp$grid, sp$aux)
    dC <- ccx_deriv_fast(sp$y, F$t[i], pe, fr, sp$grid, sp$aux)
    expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10)
  }
  r  <- ccx_run_fast(sp, F)
  rR <- suppressWarnings(ccx_run(sp, F))
  live <- ccx_out_na_guard_cols(r$out, pe)          # every column live but the tropical box's (NA by contract under hilda_eq, 2026-09-14f)
  expect_false(anyNA(r$out[, live]))
  expect_true(all(is.na(r$out$tr_C_NH)))
  for (cc in setdiff(live, "t"))
    expect_lt(max(abs(rR$out[[cc]] - r$out[[cc]])) / max(abs(r$out[[cc]])), 1e-12,
              label = paste("R vs C++ transient column", cc))
  expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
  expect_identical(rownames(r$state)[sp$aux$idx$SH$eq], "SH_eq")
})

test_that("P0e READER-DERIV PARITY: the exported pCO2 columns are the derivative's own values", {
  skip_if_no_cpp()
  pe <- eq_par()
  sp <- ccx_spinup(pe)
  F  <- ccx_build_forcing("historical", c(1900, 1901), prod_c14 = sp$prod_c14)
  r  <- ccx_run_fast(sp, F)
  # row 1 is the opening state (= the spinup) at F$t[1] under forcing row 1:
  # recompute the derivative there with the recorder and compare, both cores
  d <- ccx_deriv(sp$y, F$t[1], pe, ccx_forcing_at(F, 1L), sp$grid, sp$aux, record = TRUE)
  fl <- attr(d, "fluxes")
  for (h in HEMIS) {
    expect_equal(r$out[[paste0("ml_pco2_", h)]][1], fl$pco2_ml[[h]], tolerance = 1e-9)
    expect_equal(r$out[[paste0("hs_pco2_", h)]][1], fl$pco2_hs[[h]], tolerance = 1e-9)
    expect_equal(r$out[[paste0("eq_pco2_", h)]][1], fl$pco2_eq[[h]], tolerance = 1e-9)
  }
  # and the B1 reader is an area-weighted average of those columns: with a
  # hand-built `out` of constants it must return exactly the contrast implied
  o <- r$out[1:24, ]; o$t <- 2014 + (seq_len(24) - 0.5) / 12
  for (h in HEMIS) { o[[paste0("ml_pco2_", h)]] <- 300; o[[paste0("hs_pco2_", h)]] <- 300
                     o[[paste0("eq_pco2_", h)]] <- 360 }
  m <- ccx_model_eq_b1(o, sp$aux, years = c(2014L, 2015L))
  a_all <- sum(unlist(sp$aux$a_ml), unlist(sp$aux$a_hs), unlist(sp$aux$a_eq))
  a_eq  <- sum(unlist(sp$aux$a_eq))
  expect_equal(m$value, 360 - (300 * (a_all - a_eq) + 360 * a_eq) / a_all)
  expect_equal(unname(m$by_hemi[["NH"]]), unname(m$by_hemi[["SH"]]))
  # a run that ends before the window: ABSENT with a warning, never a held endpoint
  expect_warning(expect_null(ccx_model_eq_b1(r$out, sp$aux)), "ABSENT")
})

test_that("P0d READER NO-OP: the ocean_grad rows are identical at eq_frac = 0", {
  # a synthetic `out` with the eq columns NA (the structure-off contract) must
  # give the SAME surface as the mixed layer alone -- to 0.0, not to a tolerance
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
  ep <- list(surf = 2000, deep = 2001)
  ml_only <- ccx_box_annual_conc(o, sp$aux, sp$grid, "ml", ep$surf)
  surf    <- ccx_surface_annual_conc(o, sp$aux, sp$grid, ep$surf)
  expect_identical(unname(surf[["dic"]]),  unname(ml_only[["dic"]]))
  expect_identical(unname(surf[["d13c"]]), unname(ml_only[["d13c"]]))
  g <- ccx_model_ocean_gradient(o, sp$aux, sp$grid, ep)
  deep <- ccx_box_annual_conc(o, sp$aux, sp$grid, "deep", ep$deep)
  expect_identical(g$dic,  unname(deep[["dic"]]  - ml_only[["dic"]]))
  expect_identical(g$d13c, unname(deep[["d13c"]] - ml_only[["d13c"]]))
  # ... and with the cell PRESENT the surface is the mass-weighted mixture:
  # a cell 100 umol/kg richer than the ML must lift the surface by its mass share
  pe <- eq_par(seas_ml = 0); spe <- ccx_spinup(pe)
  oe <- o
  for (h in HEMIS) {
    m_ml <- ccx_box_mass_at(spe$aux, spe$grid, "ml", h, 2000)
    m_eq <- ccx_box_mass_at(spe$aux, spe$grid, "eq", h, 2000)
    dic  <- 2.0e-3
    oe[[paste0("ml_C_", h)]]   <- dic * m_ml / spe$aux$mol_per_GtC
    oe[[paste0("ml_C13_", h)]] <- oe[[paste0("ml_C_", h)]] * ccx_const("R13_VPDB")
    oe[[paste0("eq_C_", h)]]   <- (dic + 100e-6) * m_eq / spe$aux$mol_per_GtC
    oe[[paste0("eq_C13_", h)]] <- oe[[paste0("eq_C_", h)]] * ccx_const("R13_VPDB")
  }
  s <- ccx_surface_annual_conc(oe, spe$aux, spe$grid, 2000)
  M_ml <- sum(vapply(HEMIS, function(h) ccx_box_mass_at(spe$aux, spe$grid, "ml", h, 2000), numeric(1)))
  M_eq <- sum(vapply(HEMIS, function(h) ccx_box_mass_at(spe$aux, spe$grid, "eq", h, 2000), numeric(1)))
  expect_equal(unname(s[["dic"]]), 2000 + 100 * M_eq / (M_ml + M_eq), tolerance = 1e-9)
  expect_equal(unname(s[["d13c"]]), 0, tolerance = 1e-9)
})

test_that("P0g FIXED POINT: a uniform column with the cell at the same concentration has zero advective tendency", {
  pe <- eq_par(seas_ml = 0)
  aux <- ccx_prepare(pe); grid <- aux$grid
  y <- ccx_new_state(grid$nl, TRUE, TRUE)
  conc <- 2.1e-3                                    # mol/kg, any value
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- 600
    y[i$ml, "C"] <- conc * aux$ml_mass_kg[[h]] / aux$mol_per_GtC
    y[i$oc, "C"] <- conc * aux$a_ls[[h]] * grid$dz[-1] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    y[i$eq, "C"] <- conc * aux$eq_mass_kg[[h]] / aux$mol_per_GtC
    y[i$hs, "C"] <- conc * aux$hs_mass_kg[[h]] / aux$mol_per_GtC
    y[i$hd, "C"] <- conc * aux$a_hs[[h]] * aux$dz_hd * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    for (pool in CCX_LAND_POOLS) y[i[[pool]], "C"] <- 100
  }
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB"); y[, "C14"] <- y[, "C"]
  # isolate the ADVECTIVE loop: no air-sea (k_w 0), no pumps, no diffusion, no
  # HS exchange, no land -- what remains is the cell's three limbs and nothing else
  q <- pe; q$k_w <- 0; q$kz <- 0; q$kz_deep_frac <- 1; q$pump_grad <- 0; q$pump_hs_gcm2 <- 0
  q$u_hs <- 0; q$tau_q <- 0; q$w_up <- 0; q$w_out_NH <- 0; q$w_out_SH <- 0
  q <- ccx_set_enso(q, list(gamma_enso = 0)); q$seas_drivers <- 0; q$gamma_diff <- 0
  aq <- ccx_prepare(q)
  d <- ccx_deriv(y, 1750.25, q, zero_forc(0, enso = -0.8), aq$grid, aq)
  ocean <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$eq)))
  expect_lt(max(abs(d[ocean, "C"])), 1e-12)
  expect_lt(max(abs(d[ocean, "C13"])), 1e-12)
  # POWER: the same state with the cell 10 % richer is NOT a fixed point
  y2 <- y; for (h in HEMIS) y2[aux$idx[[h]]$eq, ] <- y2[aux$idx[[h]]$eq, ] * 1.1
  d2 <- ccx_deriv(y2, 1750.25, q, zero_forc(0, enso = -0.8), aq$grid, aq)
  expect_gt(max(abs(d2[ocean, "C"])), 1e-3)
  # ... and the diffusive ML / layer-1 interface under D1 is flux-free at
  # uniform concentration too (the effective-thickness form)
  q$kz <- pe$kz; aq <- ccx_prepare(q)
  d3 <- ccx_deriv(y, 1750.25, q, zero_forc(0, enso = -0.8), aq$grid, aq)
  expect_lt(max(abs(d3[ocean, "C"])), 1e-12)
})

test_that("EVERY limb is mutation-tested: break it and the model must move", {
  skip_if_no_cpp()
  # seas_ml = 0 here (the aseasonal ccx_spinup() is the fixed point of THIS
  # model, so the transient is clean); the seasonal parity is P0c's job
  base <- eq_par(seas_ml = 0)
  sp0  <- ccx_spinup(base)
  F    <- ccx_build_forcing("historical", c(1960, 1962), prod_c14 = sp0$prod_c14)
  ref  <- ccx_run_fast(sp0, F)
  eqp  <- function(r) mean(r$out$eq_pco2_NH, na.rm = TRUE)
  # (a) the loop: w_eq = 0 leaves a cell that is a second mixed layer at its
  #     own temperature -- its pCO2 excess over the ATMOSPHERE must COLLAPSE
  #     (the B1 row's power on W0)
  q <- base; q$w_eq <- 0; r <- ccx_run_fast(ccx_spinup(q), F)
  expect_lt(abs(eqp(r) - mean(r$out$co2_NH)), 0.1 * abs(eqp(ref) - mean(ref$out$co2_NH)))
  # (b) the modulation: gamma_eq = 0 at the SAME spinup (the spinup runs at
  #     enso = 0, so it is identical) must change the transient
  q <- base; q$gamma_eq <- 0; sp <- ccx_spinup(q)
  expect_identical(sp$y, sp0$y)
  r <- ccx_run_fast(sp, F)
  expect_gt(max(abs(r$out$eq_pco2_NH - ref$out$eq_pco2_NH)), 0.5)
  # (c) the cell's own solubility term: sst_eq_enso = 0 must move the cell's pCO2
  q <- base; q$sst_eq_enso <- 0; r <- ccx_run_fast(ccx_spinup(q), F)
  expect_gt(max(abs(r$out$eq_pco2_NH - ref$out$eq_pco2_NH)), 0.1)
  # (d) the return depth: k_eq = 1 (the T-A1 layer) must move the cell
  q <- base; q$k_eq <- 1L; r <- ccx_run_fast(ccx_spinup(q), F)
  expect_gt(abs(eqp(r) - eqp(ref)), 1)
  # (e) the floor form: at enso = +2 with gamma_eq = 1 the loop is OFF and the
  #     cell's tendency equals the w_eq = 0 cell's -- on BOTH cores
  q <- base; q$w_eq <- 0
  fr <- zero_forc(sp0$prod_c14, enso = 2)
  dA <- ccx_deriv(sp0$y, 1960, base, fr, sp0$grid, sp0$aux)
  dB <- ccx_deriv(sp0$y, 1960, q, fr, sp0$grid, ccx_prepare(q))
  expect_equal(dA, dB, tolerance = 1e-12)
  dC <- ccx_deriv_fast(sp0$y, 1960, base, fr, sp0$grid, sp0$aux)
  expect_equal(dA, dC, tolerance = 1e-10)
  # the stability bound sees the cell, and only when it is on
  expect_gt(ccx_eq_cell_eigbound(base), 0)
  expect_identical(ccx_eq_cell_eigbound(ccx_apply_structure(ccx_default_params(), "hilda")), 0)
})
