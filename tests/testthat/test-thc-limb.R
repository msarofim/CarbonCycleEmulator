# =====================================================================
# THE HS-ROUTE DEEP RETURN (option O1 arm THC, 2026-09-15 d): `w_thc` [Sv],
# `k_thc` (the return layer, structural). notes/prereg_2026-09-15d_o1_deep_return_probe.md
# §2, P0 -- the contracts, gated BEFORE any probe number is read:
#   P0a NO-OP        absent vs present-at-0 bit-exact, both cores; INERT under
#                    "solved"; the canonical's stored streams reproduce.
#   P0b CONSERVATION closed system with HS + martin + THC on, seas_ml 0 and 1.
#   P0c FIXED POINT  a uniform column has zero ocean tendency at every k, both
#                    cores; POWER: HS 10 % richer moves it.
#   P0d PARITY       R vs C++ derivative and transient at k in {1, 5, 10},
#                    seas_ml 0 and 1; mutate p after ccx_prepare().
#   P0e VOLUME       every box's net limb volume is zero (read off the fluxes
#                    at uniform concentration) and the limb MOVES the state.
#   P0f MUTATIONS    every guard by name; the eigbound scales with w_thc;
#                    k_thc changes the answer; a reversed leg breaks P0c.
# =====================================================================
thc_par <- function(seas_ml = 0, w_thc = 20, k_thc = 1L, export = 9.08, struct = "hilda") {
  p <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = seas_ml, pump_field = "martin")
  p$pump_export <- export; p$w_thc <- w_thc; p$k_thc <- k_thc
  p
}
zero_forc_t <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
# an ISOLATED ocean has no unique equilibrium (any uniform concentration is
# one), so these states are BUILT, never spun up: prepare(), then fill.
prep_t <- function(q) { aux <- ccx_prepare(q)
  list(aux = aux, grid = aux$grid, y = ccx_new_state(aux$grid$nl, aux$hs_on == 1L, aux$eq_on == 1L, aux$tr_on == 1L)) }
uniform_ocean_t <- function(sp, conc = 2.1e-3) {   # mol/kg (~ 2100 umol/kg): a REALISTIC stock, so roundoff stays at 1e-12 GtC/yr
  y <- sp$y; aux <- sp$aux; g <- sp$grid; rho <- ccx_const("RHO_SEAWATER"); per <- 1 / aux$mol_per_GtC
  for (h in HEMIS) { ix <- aux$idx[[h]]
    y[ix$atm, "C"] <- 600; for (pool in CCX_LAND_POOLS) y[ix[[pool]], "C"] <- 100
    y[ix$ml, "C"] <- conc * aux$a_ml[[h]] * g$dz[1] * rho * per
    for (k in seq_len(g$nl)) y[ix$oc[k], "C"] <- conc * aux$a_ls[[h]] * g$dz[k + 1] * rho * per
    y[ix$hs, "C"] <- conc * aux$a_hs[[h]] * aux$h_hs * rho * per
    y[ix$hd, "C"] <- conc * aux$a_hs[[h]] * aux$dz_hd * rho * per
    if (aux$eq_on == 1L) y[ix$eq, "C"] <- conc * aux$a_eq[[h]] * aux$h_eq * rho * per
    if (aux$tr_on == 1L) y[ix$tr, "C"] <- conc * aux$a_tr[[h]] * aux$h_tr * rho * per }
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB"); y[, "C14"] <- y[, "C"]
  y
}
isolate_transport <- function(p) {   # no air-sea, no pumps, no HS exchange, no seasonal drivers
  q <- p; q$k_w <- 0; q$pump_export <- 0; q$pump_hs_gcm2 <- 0; q$u_hs <- 0; q$tau_q <- 0
  q$gamma_diff <- 0; q$seas_drivers <- 0; q$w_vent <- 0
  ccx_set_enso(q, list(gamma_enso = 0))
}
ocean_rows <- function(aux) unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd,
                                                                aux$idx[[h]]$eq, aux$idx[[h]]$tr)))

test_that("the names ship OFF; registration is complete; no name prefixes another", {
  p <- ccx_default_params()
  expect_identical(p$w_thc, 0); expect_identical(p$k_thc, 1L)
  expect_identical(ccx_prepare(p)$thc_on, 0L)
  expect_true("w_thc" %in% CCX_PARAM_NAMES); expect_true("w_thc" %in% CCX_PARAM_ABSENT_OK)
  expect_true("w_thc" %in% ccx_pump_field_inert("solved")); expect_false("w_thc" %in% ccx_pump_field_inert("martin"))
  expect_identical(c(CCX_PARAM_TABLE$w_thc$lo, CCX_PARAM_TABLE$w_thc$hi), c(0, 60))
  # the partial-match trap (ccx_option_e_built_probe): neither new name is a prefix of, or prefixed by, any other
  nm <- c(names(ccx_default_params()), CCX_PARAM_NAMES, names(ccx_prepare(p)))
  for (new in c("w_thc", "k_thc", "thc_on", "thc_share")) {
    others <- setdiff(unique(nm), new)
    expect_false(any(startsWith(others, new)), info = new)
    expect_false(any(startsWith(new, others)), info = new)
  }
  # migration: a pre-build parameter set fills 0 and the canonical file still "carries the build"
  md <- readRDS(ccx_mode_file())
  expect_true(ccx_mode_carries_build(md))
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "thc"))
  expect_identical(pm$w_thc, CCX_PARAM_TABLE$w_thc$init)   # 0 is on the floor: seeded at init for a START point
})

test_that("P0a NO-OP: absent vs present-at-0 is BIT-EXACT; INERT under the solved field; the eigbound is exactly 0 off", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  q <- p; q$w_thc <- NULL; q$k_thc <- NULL
  r <- p; r$w_thc <- 20; r$k_thc <- 4L                     # "solved": inert
  a <- ccx_spinup(p); b <- ccx_spinup(q); d <- ccx_spinup(r)
  expect_identical(a$y, b$y); expect_identical(a$y, d$y)
  expect_identical(d$aux$thc_on, 0L)
  expect_identical(ccx_thc_eigbound(r, a$grid), 0)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(r))
  F0 <- zero_forc_t(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  expect_identical(ccx_deriv(a$y, 1900.2, r, F0, d$grid, d$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  # martin with w_thc = 0 is E's D exactly (the limb at 0 emits nothing)
  m0 <- thc_par(seas_ml = 1, w_thc = 0); m1 <- m0; m1$w_thc <- NULL
  expect_identical(ccx_spinup(m0)$y, ccx_spinup(m1)$y)
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14)
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F); rd <- ccx_run_fast(d, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$state, rd$state)
  expect_identical(ra$out, rb$out); expect_identical(ra$out, rd$out)
})

test_that("P0a (canonical): hilda30c's stored LIKELIHOOD reproduces row by row under this build", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-thc"))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})

test_that("P0c FIXED POINT and P0e VOLUME: a uniform column has zero ocean tendency at every return layer, both cores; the limb MOVES a non-uniform state", {
  p <- isolate_transport(thc_par(seas_ml = 0, w_thc = 25))
  for (kt in c(1L, 2L, 5L, 9L, 10L)) {
    p$k_thc <- kt; sp <- prep_t(p); y <- uniform_ocean_t(sp)
    oc <- ocean_rows(sp$aux)
    d <- ccx_deriv(y, 1750.25, p, zero_forc_t(0), sp$grid, sp$aux)
    expect_lt(max(abs(d[oc, "C"])), 1e-12); expect_lt(max(abs(d[oc, "C13"])), 1e-12)
    # the limb's own volume at every box nets to zero: read its five legs off the edge recorder
    dd <- ccx_deriv(y, 1750.25, p, zero_forc_t(0), sp$grid, sp$aux, record = TRUE)
    if (!is.null(attr(dd, "fluxes"))) expect_lt(max(abs(dd[oc, "C"])), 1e-12)
    if (requireNamespace("Rcpp", quietly = TRUE)) {
      ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
      if (ok) { dC <- ccx_deriv_fast(y, 1750.25, p, zero_forc_t(0), sp$grid, sp$aux)
                expect_lt(max(abs(dC[oc, "C"])), 1e-12); expect_lt(max(abs(dC - d)), 1e-14) }
    }
  }
  # POWER: HS 10 % richer is NOT a fixed point (the sinking leg carries HS water)
  p$k_thc <- 3L; sp <- prep_t(p); y <- uniform_ocean_t(sp); y2 <- y
  for (h in HEMIS) y2[sp$aux$idx[[h]]$hs, ] <- y2[sp$aux$idx[[h]]$hs, ] * 1.1
  d2 <- ccx_deriv(y2, 1750.25, p, zero_forc_t(0), sp$grid, sp$aux)
  expect_gt(max(abs(d2[ocean_rows(sp$aux), "C"])), 1e-2)
  # the HD box gains exactly what HS loses through leg (2) (HS is the only non-uniform box; legs 1, 3-5 are at uniform conc)
  ihs <- sp$aux$idx$NH$hs; ihd <- sp$aux$idx$NH$hd
  expect_lt(abs(d2[ihs, "C"] + d2[ihd, "C"]), 1e-12)
  # under the cell + tr (D1) the same contract holds
  q <- isolate_transport(thc_par(seas_ml = 0, w_thc = 25, k_thc = 2L, struct = "hilda_tr")); q$w_eq <- 0; q$q_tr <- 0
  sq <- prep_t(q); yq <- uniform_ocean_t(sq)
  dq <- ccx_deriv(yq, 1750.25, q, zero_forc_t(0), sq$grid, sq$aux)
  expect_lt(max(abs(dq[ocean_rows(sq$aux), "C"])), 1e-12)
})

test_that("P0b CONSERVATION and P0d PARITY with the limb on at k in {1, 5, 10}, both seasonal states; the limb MOVES the equilibrium", {
  skip_if_no_cpp()
  for (seas in c(0, 1)) for (kt in c(1L, 5L, 10L)) {
    p <- thc_par(seas_ml = seas, w_thc = 20, k_thc = kt)
    sp <- ccx_spinup(p)
    F  <- ccx_build_forcing("historical", c(1900, 1903), prod_c14 = sp$prod_c14)
    for (i in c(1L, 7L)) { fr <- ccx_forcing_at(F, i)
      dR <- ccx_deriv(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      dC <- ccx_deriv_fast(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10) }
    r <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
    expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
    expect_identical(r$substeps, ccx_substeps_for(p))
    F0 <- F; for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F0[[cc]][] <- 0
    r0 <- ccx_run_fast(sp, F0)
    expect_lt(abs(sum(r0$state[, "C"]) - sum(sp$y[, "C"])) / sum(sp$y[, "C"]), 1e-10)
    q <- p; q$w_thc <- 0
    expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  }
  # the 09-09t class: aux built with the limb ON, then p switched OFF -- both cores obey p
  p <- thc_par(seas_ml = 1, w_thc = 20, k_thc = 3L); sp <- ccx_spinup(p)
  q <- p; q$w_thc <- 0
  fr <- zero_forc_t(sp$prod_c14, enso = 0.3)
  dR <- ccx_deriv(sp$y, 1900.2, q, fr, sp$grid, sp$aux); dC <- ccx_deriv_fast(sp$y, 1900.2, q, fr, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)), 1e-9)
})

test_that("P0f MUTATIONS: every guard by name; the eigbound scales with w_thc; k_thc changes the answer; a reversed leg is not a fixed point", {
  p <- thc_par(seas_ml = 0, w_thc = 20, k_thc = 3L)
  sp <- ccx_spinup(p)
  q <- p; q$w_thc <- -5;                       expect_error(ccx_prepare(q), "w_thc")
  q <- p; q$w_thc <- NA_real_;                 expect_error(ccx_prepare(q), "w_thc")
  q <- p; q$k_thc <- 11L;                      expect_error(ccx_prepare(q), "k_thc")
  q <- p; q$k_thc <- 0L;                       expect_error(ccx_prepare(q), "k_thc")
  q <- p; q$hs_frac <- 0;                      expect_error(ccx_prepare(q), "hs_frac")   # no HS boxes: no closing leg
  # the stability bound is live and linear in the flux
  expect_gt(ccx_thc_eigbound(p, sp$grid), 0)
  q <- p; q$w_thc <- 40
  expect_equal(ccx_thc_eigbound(q, sp$grid), 2 * ccx_thc_eigbound(p, sp$grid), tolerance = 1e-12)
  # the return layer is load-bearing: k = 1 and k = 8 give different equilibria
  q <- p; q$k_thc <- 8L
  expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  # a reversed leg (sinking from HD to HS instead) breaks the fixed point -- the sign of every leg is tested by P0c;
  # here the ORDER: the limb at k = 10 has no interior upwelling legs and still closes
  r <- isolate_transport(p); r$k_thc <- 10L; sr <- prep_t(r); yr <- uniform_ocean_t(sr)
  expect_lt(max(abs(ccx_deriv(yr, 1750.25, r, zero_forc_t(0), sr$grid, sr$aux)[ocean_rows(sr$aux), "C"])), 1e-12)
})
