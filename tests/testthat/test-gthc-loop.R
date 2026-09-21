# =====================================================================
# THE GLOBAL THERMOHALINE LOOP (2026-09-20 v): `w_gthc` [Sv, ONE global
# volume; NH sinks, SH upwells], `k_gthc` (the SH return layer, structural).
# notes/prereg_2026-09-20v_global_thc_probe.md §2, P0 -- the contracts, gated
# BEFORE any probe number is read:
#   P0a NO-OP        absent vs present-at-0 bit-exact, both cores; INERT under
#                    "solved"; the canonical's stored streams reproduce.
#   P0b CONSERVATION closed system with HS + martin + loop on, seas_ml 0 and 1.
#   P0c FIXED POINT  a uniform ocean has zero ocean tendency at every k, both
#                    cores; POWER: the SH HD box 10 % richer moves it, and
#                    HS_SH gains exactly what HD_SH loses.
#   P0d PARITY       R vs C++ derivative and transient at k in {10, 8},
#                    seas_ml 0 and 1; mutate p after ccx_prepare().
#   P0e VOLUME       every box's net loop volume is zero (P0c at uniform
#                    concentration reads it) and the loop MOVES the state.
#   P0f MUTATIONS    every guard by name; the eigbound scales with w_gthc;
#                    k_gthc changes the answer; THE ONE THAT MATTERS: at W = 15
#                    the SH cold box's D (gate D's own reader) FALLS, in level
#                    and relative to its own mixed layer.
# Both names are STRUCTURAL (not in CCX_PARAM_TABLE) for the probe -- prereg
# §2 states why; the refit tier registers them.
# =====================================================================
gthc_par <- function(seas_ml = 0, w = 15, k = 10L, export = 9.08, struct = "hilda") {
  p <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = seas_ml, pump_field = "martin")
  p$pump_export <- export; p$w_gthc <- w; p$k_gthc <- k
  p
}
zero_forc_g <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
prep_g <- function(q) { aux <- ccx_prepare(q)
  list(aux = aux, grid = aux$grid, y = ccx_new_state(aux$grid$nl, aux$hs_on == 1L, aux$eq_on == 1L, aux$tr_on == 1L)) }
uniform_ocean_g <- function(sp, conc = 2.1e-3) {   # mol/kg (~ 2100 umol/kg): a REALISTIC stock
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
isolate_transport_g <- function(p) {   # no air-sea, no pumps, no HS exchange, no seasonal drivers, no other limb
  q <- p; q$k_w <- 0; q$pump_export <- 0; q$pump_hs_gcm2 <- 0; q$u_hs <- 0; q$tau_q <- 0
  q$gamma_diff <- 0; q$seas_drivers <- 0; q$w_vent <- 0; q$w_thc <- 0
  ccx_set_enso(q, list(gamma_enso = 0))
}
ocean_rows_g <- function(aux) unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd,
                                                                  aux$idx[[h]]$eq, aux$idx[[h]]$tr)))

test_that("the names ship OFF and STRUCTURAL; no name prefixes another; the canonical file still carries the build", {
  p <- ccx_default_params()
  expect_identical(p$w_gthc, 0); expect_identical(p$k_gthc, N_INTERIOR)
  expect_identical(ccx_prepare(p)$gthc_on, 0L)
  expect_false("w_gthc" %in% CCX_PARAM_NAMES)                   # structural for the probe (prereg §2)
  expect_true("gthc_ih" %in% names(CCX_FLUX_CHANNELS))
  nm <- c(names(ccx_default_params()), CCX_PARAM_NAMES, names(ccx_prepare(p)))
  for (new in c("w_gthc", "k_gthc", "kn_gthc", "gthc_on")) {   # kn_gthc, not k_gthc_nh: a prefix of k_gthc would partial-match through `$` (the 09-19 m seas_ml trap)
    others <- setdiff(unique(nm), new)
    expect_false(any(startsWith(others, new)), info = new)
    expect_false(any(startsWith(new, others)), info = new)
  }
  md <- readRDS(ccx_mode_file())
  expect_true(ccx_mode_carries_build(md))
})

test_that("P0a NO-OP: absent vs present-at-0 is BIT-EXACT; INERT under the solved field; the eigbound is exactly 0 off", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  q <- p; q$w_gthc <- NULL; q$k_gthc <- NULL
  r <- p; r$w_gthc <- 20; r$k_gthc <- 8L                    # "solved": inert
  a <- ccx_spinup(p); b <- ccx_spinup(q); d <- ccx_spinup(r)
  expect_identical(a$y, b$y); expect_identical(a$y, d$y)
  expect_identical(d$aux$gthc_on, 0L)
  expect_identical(ccx_gthc_eigbound(r, a$grid), 0)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(r))
  F0 <- zero_forc_g(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  expect_identical(ccx_deriv(a$y, 1900.2, r, F0, d$grid, d$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  # martin with w_gthc = 0 is the martin / no-loop model exactly, and k is inert there
  m0 <- gthc_par(seas_ml = 1, w = 0, k = 10L); m1 <- m0; m1$w_gthc <- NULL; m2 <- m0; m2$k_gthc <- 8L
  expect_identical(ccx_spinup(m0)$y, ccx_spinup(m1)$y); expect_identical(ccx_spinup(m0)$y, ccx_spinup(m2)$y)
  skip_if_no_cpp()
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14))
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F); rd <- ccx_run_fast(d, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$state, rd$state)
  expect_identical(ra$out, rb$out); expect_identical(ra$out, rd$out)
})

test_that("P0a (canonical): the canonical's stored LIKELIHOOD reproduces row by row under this build", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-gthc"))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})

test_that("P0c FIXED POINT and P0e VOLUME: a uniform ocean has zero ocean tendency at every return layer, both cores; the loop MOVES a non-uniform state", {
  p <- isolate_transport_g(gthc_par(seas_ml = 0, w = 25))
  for (kg in c(10L, 8L, 5L, 1L)) {
    p$k_gthc <- kg; sp <- prep_g(p); y <- uniform_ocean_g(sp)
    oc <- ocean_rows_g(sp$aux)
    d <- ccx_deriv(y, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux)
    expect_lt(max(abs(d[oc, "C"])), 1e-12); expect_lt(max(abs(d[oc, "C13"])), 1e-12)
    dd <- ccx_deriv(y, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux, record = TRUE)
    fl <- attr(dd, "fluxes")
    expect_lt(max(abs(dd[oc, "C"])), 1e-12)
    expect_gt(fl$channels[["gthc_ih"]], 0)                     # the two interhemispheric legs are labelled and live
    # the recorder's per-box net reproduces dy exactly (the trace is the model's own fluxes)
    expect_lt(max(abs(fl$boxnet[oc] - dd[oc, "C"])), 1e-12)
    if (requireNamespace("Rcpp", quietly = TRUE)) {
      ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
      if (ok) { dC <- ccx_deriv_fast(y, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux)
                expect_lt(max(abs(dC[oc, "C"])), 1e-12); expect_lt(max(abs(dC - d)), 1e-14) }
    }
  }
  # POWER: the SH HD box 10 % richer is NOT a fixed point, and HS_SH gains exactly what HD_SH loses
  # (HD_SH is the only non-uniform box: its inflow leg 5b is at uniform conc, its outflow 5c carries the excess)
  p$k_gthc <- 8L; sp <- prep_g(p); y <- uniform_ocean_g(sp); y2 <- y
  ihd <- sp$aux$idx$SH$hd; ihs <- sp$aux$idx$SH$hs
  y2[ihd, ] <- y2[ihd, ] * 1.1
  d2 <- ccx_deriv(y2, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux)
  expect_gt(max(abs(d2[ocean_rows_g(sp$aux), "C"])), 1e-2)
  expect_lt(abs(d2[ihs, "C"] + d2[ihd, "C"]), 1e-12)
  expect_lt(d2[ihd, "C"], 0); expect_gt(d2[ihs, "C"], 0)
  # the NH cold box is untouched by an SH excess (the loop's NH legs are all at uniform conc)
  expect_lt(abs(d2[sp$aux$idx$NH$hs, "C"]), 1e-12)
  # under the cell + tr (D1) the same contract holds
  q <- isolate_transport_g(gthc_par(seas_ml = 0, w = 25, k = 8L, struct = "hilda_tr")); q$w_eq <- 0; q$q_tr <- 0
  sq <- prep_g(q); yq <- uniform_ocean_g(sq)
  dq <- ccx_deriv(yq, 1750.25, q, zero_forc_g(0), sq$grid, sq$aux)
  expect_lt(max(abs(dq[ocean_rows_g(sq$aux), "C"])), 1e-12)
})

test_that("P0b CONSERVATION and P0d PARITY with the loop on at k in {10, 8}, both seasonal states; the loop MOVES the equilibrium", {
  skip_if_no_cpp()
  for (seas in c(0, 1)) for (kg in c(10L, 8L)) {
    p <- gthc_par(seas_ml = seas, w = 15, k = kg)
    sp <- ccx_spinup(p)
    F  <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1903), prod_c14 = sp$prod_c14))
    for (i in c(1L, 7L)) { fr <- ccx_forcing_at(F, i)
      dR <- suppressWarnings(ccx_deriv(sp$y, F$t[i], p, fr, sp$grid, sp$aux))
      dC <- ccx_deriv_fast(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10) }
    r <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
    expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
    expect_identical(r$substeps, ccx_substeps_for(p))
    F0 <- F; for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F0[[cc]][] <- 0
    r0 <- ccx_run_fast(sp, F0)
    expect_lt(abs(sum(r0$state[, "C"]) - sum(sp$y[, "C"])) / sum(sp$y[, "C"]), 1e-10)
    expect_lt(abs(sum(r0$state[, "C13"]) - sum(sp$y[, "C13"])) / sum(sp$y[, "C13"]), 1e-10)
    q <- p; q$w_gthc <- 0
    expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  }
  # the 09-09t class: aux built with the loop ON, then p switched OFF -- both cores obey p
  p <- gthc_par(seas_ml = 1, w = 15, k = 8L); sp <- ccx_spinup(p)
  q <- p; q$w_gthc <- 0
  fr <- zero_forc_g(sp$prod_c14, enso = 0.3)
  dR <- ccx_deriv(sp$y, 1900.2, q, fr, sp$grid, sp$aux); dC <- ccx_deriv_fast(sp$y, 1900.2, q, fr, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)), 1e-9)
})

test_that("P0f MUTATIONS: every guard by name; the eigbound scales with w_gthc; k_gthc changes the answer", {
  p <- gthc_par(seas_ml = 0, w = 15, k = 8L)
  sp <- ccx_spinup(p)
  q <- p; q$w_gthc <- -5;                      expect_error(ccx_prepare(q), "w_gthc")
  q <- p; q$w_gthc <- NA_real_;                expect_error(ccx_prepare(q), "w_gthc")
  q <- p; q$k_gthc <- 11L;                     expect_error(ccx_prepare(q), "k_gthc")
  q <- p; q$k_gthc <- 0L;                      expect_error(ccx_prepare(q), "k_gthc")
  q <- p; q$hs_frac <- 0;                      expect_error(ccx_prepare(q), "hs_frac")   # no HS boxes: no legs
  q <- p; q$q_conv <- 10;                      expect_error(ccx_prepare(q), "q_conv")    # one overturning per column
  q <- p; q$w_thc <- 10;                       expect_error(ccx_prepare(q), "w_thc")
  # the stability bound is live and linear in the flux
  expect_gt(ccx_gthc_eigbound(p, sp$grid), 0)
  q <- p; q$w_gthc <- 30
  expect_equal(ccx_gthc_eigbound(q, sp$grid), 2 * ccx_gthc_eigbound(p, sp$grid), tolerance = 1e-12)
  # the return layer is load-bearing: k = 10 and k = 8 give different equilibria
  q <- p; q$k_gthc <- 10L
  expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  # a reversed within-column leg breaks the fixed point: P0c tests every leg's sign; here the k = 1 loop (every SH
  # interface upwelled) still closes
  r <- isolate_transport_g(p); r$k_gthc <- 1L; sr <- prep_g(r); yr <- uniform_ocean_g(sr)
  expect_lt(max(abs(ccx_deriv(yr, 1750.25, r, zero_forc_g(0), sr$grid, sr$aux)[ocean_rows_g(sr$aux), "C"])), 1e-12)
})

test_that("P0f, THE MUTATION THAT MATTERS: with the loop on, the SH cold box's air-sea d13C disequilibrium D FALLS (gate D's own reader)", {
  skip_if_no_cpp()
  GATES_LIB <- ccx_path("calibration", "lib_design_gates.R")
  skip_if_not(file.exists(GATES_LIB), "lib_design_gates.R not present")
  source(GATES_LIB, local = TRUE)
  D_hs <- function(w) {
    p <- gthc_par(seas_ml = 1, w = w, k = 10L); sp <- ccx_spinup(p)
    F  <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sp$prod_c14))
    r  <- list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
    bx <- dg_gateD_box_years(r, NULL)
    c(NH = mean(bx$NH_hs$D[bx$NH_hs$years == 1755]), SH = mean(bx$SH_hs$D[bx$SH_hs$years == 1755]),
      NH_ml = mean(bx$NH_ml$D[bx$NH_ml$years == 1755]), SH_ml = mean(bx$SH_ml$D[bx$SH_ml$years == 1755]))
  }
  d0 <- D_hs(0); d15 <- D_hs(15)
  expect_lt(d15[["SH"]], d0[["SH"]] - 0.1)          # the SH cold box goes LIGHTER (un-equilibrated upwelled water)
  expect_lt(d15[["SH"]] - d15[["SH_ml"]], d0[["SH"]] - d0[["SH_ml"]])   # ... and lighter RELATIVE to its own mixed layer
  # ⚠ MEASURED AT THE DEFAULT STRUCTURE (09-20 v, this test's first run): the NH cold box ALSO lightens, by as
  # much (-0.28 vs -0.25 at W = 15), because leg 1 brings mixed-layer water (lighter than the export-enriched HS
  # box) into HS_NH. Whether the NH box holds at the CANONICAL is prereg P1's question, read by the probe -- not
  # asserted here, where the structure is uncalibrated. What IS asserted: the loop is not a symmetric no-op.
  expect_gt(abs(d15[["NH"]] - d0[["NH"]]) + abs(d15[["SH"]] - d0[["SH"]]), 0.2)
})

# ---- T2 (2026-09-21 b, prereg s5): the NH sink fed from an aged interior layer, kn_gthc ----
test_that("T2: kn_gthc = 0 is the (v) loop BIT-EXACT; the switch ships 0; guards by name; the eigbound gains layer k", {
  p <- gthc_par(seas_ml = 1, w = 15, k = 10L)
  expect_identical(ccx_default_params()$kn_gthc, 0L)
  q <- p; q$kn_gthc <- NULL
  a <- ccx_spinup(p); b <- ccx_spinup(q)
  expect_identical(a$y, b$y); expect_identical(a$aux$kn_gthc, 0L)
  F0 <- zero_forc_g(a$prod_c14, enso = 0.4)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  q <- p; q$kn_gthc <- 11L;  expect_error(ccx_prepare(q), "kn_gthc")
  q <- p; q$kn_gthc <- -1L;  expect_error(ccx_prepare(q), "kn_gthc")
  q <- p; q$kn_gthc <- 3L
  expect_gt(ccx_gthc_eigbound(q, a$grid), 0); expect_gte(ccx_gthc_eigbound(q, a$grid), ccx_gthc_eigbound(p, a$grid))
  # the switch is load-bearing: k_nh 3 and 0 give different equilibria
  expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - a$y[, "C"])), 1e-3)
  skip_if_no_cpp()
  F <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14))
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$out, rb$out)
})

test_that("T2: P0c fixed point + P0e volume at k_nh in {1, 3, 6, 10}, both cores; POWER: layer k richer moves HS_NH and nothing else", {
  p <- isolate_transport_g(gthc_par(seas_ml = 0, w = 25, k = 10L))
  for (kn in c(1L, 3L, 6L, 10L)) {
    p$kn_gthc <- kn; sp <- prep_g(p); y <- uniform_ocean_g(sp); oc <- ocean_rows_g(sp$aux)
    d <- ccx_deriv(y, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux)
    expect_lt(max(abs(d[oc, "C"])), 1e-12); expect_lt(max(abs(d[oc, "C13"])), 1e-12)
    if (requireNamespace("Rcpp", quietly = TRUE)) {
      ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
      if (ok) { dC <- ccx_deriv_fast(y, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux)
                expect_lt(max(abs(dC[oc, "C"])), 1e-12); expect_lt(max(abs(dC - d)), 1e-14) }
    }
  }
  p$kn_gthc <- 3L; p$kz <- 0; sp <- prep_g(p); y <- uniform_ocean_g(sp); y2 <- y   # kz 0: layer 3's diffusive neighbours would otherwise share the excess
  ik <- sp$aux$idx$NH$oc[3]; ihs <- sp$aux$idx$NH$hs
  y2[ik, ] <- y2[ik, ] * 1.1
  d2 <- ccx_deriv(y2, 1750.25, p, zero_forc_g(0), sp$grid, sp$aux)
  expect_lt(abs(d2[ihs, "C"] + d2[ik, "C"]), 1e-12); expect_gt(d2[ihs, "C"], 0)   # HS_NH gains what layer k loses through (1b)
  expect_lt(abs(d2[sp$aux$idx$NH$ml, "C"]), 1e-12)                                # the ML's legs are all at uniform conc
})

test_that("T2: P0b conservation and P0d parity with k_nh = 3 and 6, both seasonal states", {
  skip_if_no_cpp()
  for (seas in c(0, 1)) for (kn in c(3L, 6L)) {
    p <- gthc_par(seas_ml = seas, w = 15, k = 10L); p$kn_gthc <- kn
    sp <- ccx_spinup(p)
    F  <- suppressWarnings(ccx_build_forcing("historical", c(1900, 1903), prod_c14 = sp$prod_c14))
    for (i in c(1L, 7L)) { fr <- ccx_forcing_at(F, i)
      dR <- suppressWarnings(ccx_deriv(sp$y, F$t[i], p, fr, sp$grid, sp$aux))
      dC <- ccx_deriv_fast(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10) }
    r <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
    expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
    F0 <- F; for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F0[[cc]][] <- 0
    r0 <- ccx_run_fast(sp, F0)
    expect_lt(abs(sum(r0$state[, "C"]) - sum(sp$y[, "C"])) / sum(sp$y[, "C"]), 1e-10)
  }
})

test_that("T2, the read that motivates it: at 15 Sv the NH cold box's PI D14C is OLDER when the sink is fed from layer 6 than from the ML", {
  d14 <- function(sp, h) { i <- sp$aux$idx[[h]]$hs; 1000 * (sp$y[i, "C14"] / sp$y[i, "C"] - 1) }
  p0 <- gthc_par(seas_ml = 0, w = 15, k = 10L); p6 <- p0; p6$kn_gthc <- 6L
  s0 <- ccx_spinup(p0); s6 <- ccx_spinup(p6)
  expect_lt(d14(s6, "NH"), d14(s0, "NH") - 5)
})
