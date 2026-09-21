# =====================================================================
# THE SOUTHERN OCEAN ONE-PASS WINDOW (2026-09-21 e, option B-minimal):
# `w_soc` [Sv, SH only], `k_soc_up` (the source layer), `k_soc_dn` (the return
# layer), `hs_h_fac_SH` (the SH cold box's thickness factor).
# notes/prereg_2026-09-21e_so_window_probe.md §2, P0 -- the contracts, gated
# BEFORE any probe number is read:
#   P0a NO-OP        absent vs present-at-0 (and factor-at-1) bit-exact, both
#                    cores; INERT under "solved"; the canonical's streams reproduce.
#   P0b CONSERVATION closed system with HS + martin + window on, seas_ml 0 and 1.
#   P0c FIXED POINT  a uniform ocean has zero ocean tendency at every (k_up,
#                    k_dn) geometry, both cores; POWER: HD_SH 10 % richer moves
#                    it, HS_SH gains exactly what HD_SH loses, the SH ML and
#                    every NH box are UNTOUCHED (the contract that distinguishes
#                    the window from the loop).
#   P0d PARITY       R vs C++ derivative and transient at (8,10) and (8,6),
#                    seas_ml 0 and 1, fac 1 and 1/2; mutate p after ccx_prepare().
#   P0e VOLUME       every box's net window volume is zero (P0c at uniform
#                    concentration reads it) and the window MOVES the state.
#   P0f MUTATIONS    every guard by name; the eigbound scales with w_soc and
#                    with 1 / hs_h_fac_SH; k_soc_dn and the factor change the
#                    answer; the factor halves the SH cold box's mass exactly;
#                    THE ONE THAT MATTERS: at W = 15 the SH cold box's D (gate
#                    D's own reader) FALLS and the SH ML's D barely moves.
# All four names are STRUCTURAL (not in CCX_PARAM_TABLE) for the probe.
# =====================================================================
soc_par <- function(seas_ml = 0, w = 15, ku = 8L, kd = 10L, fac = 1, export = 9.08, struct = "hilda") {
  p <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = seas_ml, pump_field = "martin")
  p$pump_export <- export; p$w_soc <- w; p$k_soc_up <- ku; p$k_soc_dn <- kd; p$hs_h_fac_SH <- fac
  p
}
zero_forc_s <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
prep_s <- function(q) { aux <- ccx_prepare(q)
  list(aux = aux, grid = aux$grid, y = ccx_new_state(aux$grid$nl, aux$hs_on == 1L, aux$eq_on == 1L, aux$tr_on == 1L)) }
uniform_ocean_s <- function(sp, conc = 2.1e-3) {   # mol/kg; the HS / HD boxes at their PER-HEMISPHERE thickness
  y <- sp$y; aux <- sp$aux; g <- sp$grid; rho <- ccx_const("RHO_SEAWATER"); per <- 1 / aux$mol_per_GtC
  for (h in HEMIS) { ix <- aux$idx[[h]]
    y[ix$atm, "C"] <- 600; for (pool in CCX_LAND_POOLS) y[ix[[pool]], "C"] <- 100
    y[ix$ml, "C"] <- conc * aux$a_ml[[h]] * g$dz[1] * rho * per
    for (k in seq_len(g$nl)) y[ix$oc[k], "C"] <- conc * aux$a_ls[[h]] * g$dz[k + 1] * rho * per
    y[ix$hs, "C"] <- conc * aux$a_hs[[h]] * aux$thick_hs[[h]] * rho * per
    y[ix$hd, "C"] <- conc * aux$a_hs[[h]] * aux$thick_hd[[h]] * rho * per
    if (aux$eq_on == 1L) y[ix$eq, "C"] <- conc * aux$a_eq[[h]] * aux$h_eq * rho * per
    if (aux$tr_on == 1L) y[ix$tr, "C"] <- conc * aux$a_tr[[h]] * aux$h_tr * rho * per }
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB"); y[, "C14"] <- y[, "C"]
  y
}
isolate_transport_s <- function(p) {   # no air-sea, no pumps, no HS exchange, no seasonal drivers, no other limb
  q <- p; q$k_w <- 0; q$pump_export <- 0; q$pump_hs_gcm2 <- 0; q$u_hs <- 0; q$tau_q <- 0
  q$gamma_diff <- 0; q$seas_drivers <- 0; q$w_vent <- 0; q$w_thc <- 0; q$w_gthc <- 0
  ccx_set_enso(q, list(gamma_enso = 0))
}
ocean_rows_s <- function(aux) unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd,
                                                                  aux$idx[[h]]$eq, aux$idx[[h]]$tr)))
SOC_NEW <- c("w_soc", "k_soc_up", "k_soc_dn", "hs_h_fac_SH", "soc_on", "thick_hs", "thick_hd")

test_that("the names ship OFF and STRUCTURAL; no name prefixes another; the canonical file still carries the build", {
  p <- ccx_default_params()
  expect_identical(p$w_soc, 0); expect_identical(p$k_soc_up, 8L); expect_identical(p$k_soc_dn, N_INTERIOR); expect_identical(p$hs_h_fac_SH, 1)
  aux <- ccx_prepare(p)
  expect_identical(aux$soc_on, 0L)
  expect_identical(aux$thick_hs, list(NH = aux$h_hs, SH = aux$h_hs)); expect_identical(aux$thick_hd, list(NH = aux$dz_hd, SH = aux$dz_hd))
  for (n in c("w_soc", "k_soc_up", "k_soc_dn", "hs_h_fac_SH")) expect_false(n %in% CCX_PARAM_NAMES, info = n)
  nm <- c(names(ccx_default_params()), CCX_PARAM_NAMES, names(aux))
  for (new in SOC_NEW) {   # hs_h_fac_SH, not h_hs_fac_SH: a name beginning with h_hs would partial-match p$h_hs through `$` (the 09-19 m trap)
    others <- setdiff(unique(nm), new)
    expect_false(any(startsWith(others, new)), info = new)
    expect_false(any(startsWith(new, others)), info = new)
  }
  md <- readRDS(ccx_mode_file())
  expect_true(ccx_mode_carries_build(md))
})

test_that("P0a NO-OP: absent vs present-at-0 / factor-at-1 is BIT-EXACT; INERT under the solved field; the eigbound is exactly 0 off", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  q <- p; for (n in c("w_soc", "k_soc_up", "k_soc_dn", "hs_h_fac_SH")) q[[n]] <- NULL
  r <- p; r$w_soc <- 20; r$k_soc_dn <- 6L                    # "solved": inert
  a <- ccx_spinup(p); b <- ccx_spinup(q); d <- ccx_spinup(r)
  expect_identical(a$y, b$y); expect_identical(a$y, d$y)
  expect_identical(d$aux$soc_on, 0L)
  expect_identical(ccx_soc_eigbound(r, a$grid), 0)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(r))
  F0 <- zero_forc_s(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  expect_identical(ccx_deriv(a$y, 1900.2, r, F0, d$grid, d$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  # martin with w_soc = 0 is the martin / no-window model exactly, and the layers are inert there
  m0 <- soc_par(seas_ml = 1, w = 0); m1 <- m0; m1$w_soc <- NULL; m2 <- m0; m2$k_soc_dn <- 6L; m2$k_soc_up <- 3L
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
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-soc"))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})

test_that("P0c FIXED POINT and P0e VOLUME: a uniform ocean has zero ocean tendency at every geometry, both cores; the window MOVES a non-uniform state and touches ONLY the SH cell boxes", {
  p <- isolate_transport_s(soc_par(seas_ml = 0, w = 25))
  for (geo in list(c(8L, 10L), c(8L, 6L), c(6L, 6L), c(1L, 10L), c(10L, 1L))) {
    for (fac in c(1, 0.5)) {
      p$k_soc_up <- geo[1]; p$k_soc_dn <- geo[2]; p$hs_h_fac_SH <- fac; sp <- prep_s(p); y <- uniform_ocean_s(sp)
      oc <- ocean_rows_s(sp$aux)
      d <- ccx_deriv(y, 1750.25, p, zero_forc_s(0), sp$grid, sp$aux)
      expect_lt(max(abs(d[oc, "C"])), 1e-12); expect_lt(max(abs(d[oc, "C13"])), 1e-12)
      dd <- ccx_deriv(y, 1750.25, p, zero_forc_s(0), sp$grid, sp$aux, record = TRUE)
      fl <- attr(dd, "fluxes")
      expect_lt(max(abs(fl$boxnet[oc] - dd[oc, "C"])), 1e-12)          # the recorder's per-box net reproduces dy
      if (requireNamespace("Rcpp", quietly = TRUE)) {
        ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
        if (ok) { dC <- ccx_deriv_fast(y, 1750.25, p, zero_forc_s(0), sp$grid, sp$aux)
                  expect_lt(max(abs(dC[oc, "C"])), 1e-12); expect_lt(max(abs(dC - d)), 1e-14) }
      }
    }
  }
  # POWER: HD_SH 10 % richer is NOT a fixed point; HS_SH gains exactly what HD_SH loses (HD_SH is the only
  # non-uniform box: its inflow leg 2 is at uniform conc, its outflow leg 3 carries the excess); the SH ML and
  # EVERY NH box are untouched -- the window has no ML leg and no NH leg
  p$k_soc_up <- 8L; p$k_soc_dn <- 10L; p$hs_h_fac_SH <- 1; sp <- prep_s(p); y <- uniform_ocean_s(sp); y2 <- y
  ihd <- sp$aux$idx$SH$hd; ihs <- sp$aux$idx$SH$hs
  y2[ihd, ] <- y2[ihd, ] * 1.1
  d2 <- ccx_deriv(y2, 1750.25, p, zero_forc_s(0), sp$grid, sp$aux)
  expect_gt(max(abs(d2[ocean_rows_s(sp$aux), "C"])), 1e-2)
  expect_lt(abs(d2[ihs, "C"] + d2[ihd, "C"]), 1e-12)
  expect_lt(d2[ihd, "C"], 0); expect_gt(d2[ihs, "C"], 0)
  expect_lt(abs(d2[sp$aux$idx$SH$ml, "C"]), 1e-12)
  nh <- c(sp$aux$idx$NH$ml, sp$aux$idx$NH$oc, sp$aux$idx$NH$hs, sp$aux$idx$NH$hd)
  expect_lt(max(abs(d2[nh, "C"])), 1e-12)
  # and HS_SH 10 % richer drains ONLY into layer k_dn (leg 4), the ML untouched
  y3 <- y; y3[ihs, ] <- y3[ihs, ] * 1.1
  d3 <- ccx_deriv(y3, 1750.25, p, zero_forc_s(0), sp$grid, sp$aux)
  ikd <- sp$aux$idx$SH$oc[10]
  expect_lt(d3[ihs, "C"], 0); expect_lt(abs(d3[ihs, "C"] + d3[ikd, "C"]), 1e-12)
  expect_lt(abs(d3[sp$aux$idx$SH$ml, "C"]), 1e-12)
  # under the cell + tr (D1) the same contract holds
  q <- isolate_transport_s(soc_par(seas_ml = 0, w = 25, kd = 6L, struct = "hilda_tr")); q$w_eq <- 0; q$q_tr <- 0
  sq <- prep_s(q); yq <- uniform_ocean_s(sq)
  dq <- ccx_deriv(yq, 1750.25, q, zero_forc_s(0), sq$grid, sq$aux)
  expect_lt(max(abs(dq[ocean_rows_s(sq$aux), "C"])), 1e-12)
})

test_that("P0b CONSERVATION and P0d PARITY with the window on at (8,10) and (8,6), both seasonal states, fac 1 and 1/2; the window MOVES the equilibrium", {
  skip_if_no_cpp()
  for (seas in c(0, 1)) for (kd in c(10L, 6L)) for (fac in c(1, 0.5)) {
    p <- soc_par(seas_ml = seas, w = 15, kd = kd, fac = fac)
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
    q <- p; q$w_soc <- 0
    expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  }
  # the 09-09t class: aux built with the window ON, then p switched OFF -- both cores obey p
  p <- soc_par(seas_ml = 1, w = 15, kd = 6L); sp <- ccx_spinup(p)
  q <- p; q$w_soc <- 0
  fr <- zero_forc_s(sp$prod_c14, enso = 0.3)
  dR <- ccx_deriv(sp$y, 1900.2, q, fr, sp$grid, sp$aux); dC <- ccx_deriv_fast(sp$y, 1900.2, q, fr, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)), 1e-9)
})

test_that("P0f MUTATIONS: every guard by name; the eigbound scales with w_soc and 1/fac; k_soc_dn and the factor change the answer; the factor halves the SH cold box's mass exactly", {
  p <- soc_par(seas_ml = 0, w = 15, kd = 10L)
  sp <- ccx_spinup(p)
  q <- p; q$w_soc <- -5;                       expect_error(ccx_prepare(q), "w_soc")
  q <- p; q$w_soc <- NA_real_;                 expect_error(ccx_prepare(q), "w_soc")
  q <- p; q$k_soc_up <- 11L;                   expect_error(ccx_prepare(q), "k_soc_up")
  q <- p; q$k_soc_up <- 0L;                    expect_error(ccx_prepare(q), "k_soc_up")
  q <- p; q$k_soc_dn <- 11L;                   expect_error(ccx_prepare(q), "k_soc_dn")
  q <- p; q$k_soc_dn <- 0L;                    expect_error(ccx_prepare(q), "k_soc_dn")
  q <- p; q$hs_frac <- 0;                      expect_error(ccx_prepare(q), "hs_frac")   # no HS boxes: no legs
  q <- p; q$q_conv <- 10;                      expect_error(ccx_prepare(q), "q_conv")    # one overturning per column
  q <- p; q$w_thc <- 10;                       expect_error(ccx_prepare(q), "w_thc")
  q <- p; q$w_gthc <- 10;                      expect_error(ccx_prepare(q), "w_gthc")
  q <- p; q$hs_h_fac_SH <- 0;                  expect_error(ccx_prepare(q), "hs_h_fac_SH")
  q <- p; q$hs_h_fac_SH <- -1;                 expect_error(ccx_prepare(q), "hs_h_fac_SH")
  q <- p; q$hs_h_fac_SH <- NA_real_;           expect_error(ccx_prepare(q), "hs_h_fac_SH")
  q <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1); q$seas_ml <- 2; q$hs_h_fac_SH <- 0.5; expect_error(ccx_prepare(q), "seas_ml 2")   # option B is set by hand (ccx_apply_structure admits 0/1 only)
  # the stability bound is live, linear in the flux, and grows as the SH cold box thins
  expect_gt(ccx_soc_eigbound(p, sp$grid), 0)
  q <- p; q$w_soc <- 30
  expect_equal(ccx_soc_eigbound(q, sp$grid), 2 * ccx_soc_eigbound(p, sp$grid), tolerance = 1e-12)
  q <- p; q$hs_h_fac_SH <- 0.5
  expect_gt(ccx_soc_eigbound(q, sp$grid), ccx_soc_eigbound(p, sp$grid))
  # the factor: the SH cold box's mass halves exactly, HD gains the thickness, the NH is untouched
  aq <- ccx_prepare(q)
  expect_equal(aq$hs_mass_kg$SH, 0.5 * sp$aux$hs_mass_kg$SH, tolerance = 1e-15); expect_identical(aq$hs_mass_kg$NH, sp$aux$hs_mass_kg$NH)
  expect_equal(aq$thick_hs$SH + aq$thick_hd$SH, sum(sp$grid$dz), tolerance = 1e-12); expect_identical(aq$thick_hs$NH, sp$aux$h_hs)
  expect_identical(aq$h_hs, sp$aux$h_hs)                     # the scalar nominal is untouched (the test helpers' read)
  # the return layer and the factor are load-bearing: (8,10), (8,6) and fac 1/2 give different equilibria
  q <- p; q$k_soc_dn <- 6L
  expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  q <- p; q$hs_h_fac_SH <- 0.5
  expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  # the factor ALONE (window off) also moves the SH state and only the SH state's cold-box partition
  q <- p; q$w_soc <- 0; q$hs_h_fac_SH <- 0.5; s0 <- ccx_spinup(p); s0$y <- ccx_spinup({ r <- p; r$w_soc <- 0; r })$y
  sq <- ccx_spinup(q)
  expect_gt(abs(sq$y[sq$aux$idx$SH$hs, "C"] - s0$y[s0$aux$idx$SH$hs, "C"]), 1e-3)
})

test_that("P0f, THE MUTATION THAT MATTERS: with the window on, the SH cold box's air-sea d13C disequilibrium D FALLS and the SH ML's barely moves (gate D's own reader)", {
  skip_if_no_cpp()
  GATES_LIB <- ccx_path("calibration", "lib_design_gates.R")
  skip_if_not(file.exists(GATES_LIB), "lib_design_gates.R not present")
  source(GATES_LIB, local = TRUE)
  D_of <- function(w, fac = 1) {
    p <- soc_par(seas_ml = 1, w = w, fac = fac); sp <- ccx_spinup(p)
    F  <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sp$prod_c14))
    r  <- list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
    bx <- dg_gateD_box_years(r, NULL)
    c(NH = mean(bx$NH_hs$D[bx$NH_hs$years == 1755]), SH = mean(bx$SH_hs$D[bx$SH_hs$years == 1755]),
      NH_ml = mean(bx$NH_ml$D[bx$NH_ml$years == 1755]), SH_ml = mean(bx$SH_ml$D[bx$SH_ml$years == 1755]))
  }
  d0 <- D_of(0); d15 <- D_of(15); d15t <- D_of(15, fac = 1/3)
  expect_lt(d15[["SH"]], d0[["SH"]] - 0.1)                  # the SH cold box goes LIGHTER (un-equilibrated upwelled water)
  expect_lt(abs(d15[["SH_ml"]] - d0[["SH_ml"]]), 0.05)      # the SH ML is NOT in the cell (prereg P2's contract)
  expect_lt(abs(d15[["NH"]] - d0[["NH"]]), 0.05)            # no NH leg
  expect_lt(d15t[["SH"]], d15[["SH"]])                      # the shorter pass (fac 1/3) is lighter still
})
