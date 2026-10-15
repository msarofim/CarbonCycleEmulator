# =====================================================================
# OPTION D + E (2026-09-14 h): the PRESCRIBED-EXPORT pump (`pump_field =
# "martin"`, `pump_export`) and the MODE-WATER VENTILATION LOOP (`w_vent`,
# `gamma_vent`, layers k_e1..k_e2). notes/prereg_2026-09-14h_option_e_ventilation.md
# §4, P0 -- the contracts, gated BEFORE any science number is read:
#   P0a NO-OP        every registered mode bit-exact with the names absent and
#                    present at their defaults, both cores; the canonical's
#                    stored streams reproduce; the loop is INERT under "solved".
#   P0b CONSERVATION total C with E on, the model's own gate tolerance.
#   P0c FIXED POINT  a uniform column has zero tendency from E's limbs, cell off/on.
#   P0d PARITY       R and C++ with E on, transient and derivative.
#   P0e THE FIELD    sum(S) = E_h exactly; pump_export 0 -> NULL; pump_grad inert
#                    under "martin"; MARTIN_B is the constant the library reads.
#   P0f MUTATIONS    gamma sign, band depth, every guard by name.
#   N-E1 (re-scoped) at the export that reproduces the canonical's PI gradient,
#                    the ocean_grad_dic row moves at most about 1 log-unit (deep d13C reported).
# =====================================================================
e_par <- function(struct = "hilda", seas_ml = 0, w_vent = 20, gamma_vent = 0.5, export = 9.08) {
  p <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = seas_ml, pump_field = "martin")
  p$pump_export <- export; p$w_vent <- w_vent; p$gamma_vent <- gamma_vent
  p
}
zero_forc_e <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
uniform_ocean <- function(sp, conc = 2.0e-6) {   # GtC per m3 (~ 2000 umol/kg)
  y <- sp$y; aux <- sp$aux; g <- sp$grid
  for (h in HEMIS) { ix <- aux$idx[[h]]
    y[ix$ml, "C"] <- conc * aux$a_ml[[h]] * g$dz[1]
    for (k in seq_len(g$nl)) y[ix$oc[k], "C"] <- conc * aux$a_ls[[h]] * g$dz[k + 1]
    if (aux$hs_on == 1L) { y[ix$hs, "C"] <- conc * aux$a_hs[[h]] * aux$h_hs
                           y[ix$hd, "C"] <- conc * aux$a_hs[[h]] * aux$dz_hd }
    if (aux$eq_on == 1L) y[ix$eq, "C"] <- conc * aux$a_eq[[h]] * aux$h_eq
    if (aux$tr_on == 1L) y[ix$tr, "C"] <- conc * aux$a_tr[[h]] * aux$h_tr }
  y
}

test_that("the names ship OFF and their defaults are the 09-14 g model; the field axis parses by name", {
  p <- ccx_default_params()
  expect_identical(p$pump_field, "solved"); expect_identical(p$pump_export, 0)
  expect_identical(p$w_vent, 0); expect_identical(p$gamma_vent, 0)
  expect_identical(p$k_e1, 1L); expect_identical(p$k_e2, 3L)
  expect_identical(ccx_prepare(p)$e_on, 0L)
  expect_identical(CCX_PUMP_FIELDS, c("solved", "martin"))
  expect_error(ccx_apply_structure(p, "hilda", pump_field = "glodap"), "pump_field")
  q <- ccx_apply_structure(p, "hilda_eq", pump_field = "martin")
  expect_identical(attr(q, "pump_field"), "martin"); expect_identical(q$pump_field, "martin")
  expect_true(ccx_eq_on(q))                                       # the axis composes with every label
  expect_identical(ccx_const("MARTIN_B"), 0.858)
  expect_identical(CCX_CONSTANTS$MARTIN_B$status, "cited")
  expect_setequal(intersect(CCX_PARAM_NAMES, c("pump_export", "w_vent", "gamma_vent")),
                  c("pump_export", "w_vent", "gamma_vent"))
  expect_true(all(c("pump_export", "w_vent", "gamma_vent") %in% CCX_PARAM_ABSENT_OK))
  # the table's init REPEATS the product's median (the table is built before ccx_path exists)
  expect_equal(CCX_PARAM_TABLE$pump_export$init, ccx_pump_export_prior()$centre_gtc, tolerance = 5e-3)
  expect_equal(CCX_PARAM_TABLE$pump_export$prior(9.08), dlnorm(9.08, log(ccx_pump_export_prior()$centre_gtc),
                                                               ccx_pump_export_prior()$log_sd, log = TRUE))
  # ... and w_vent's init repeats ITS product's median (the subduction-rate bracket, 09-14 h)
  expect_equal(CCX_PARAM_TABLE$w_vent$init, ccx_w_vent_prior()$centre_sv, tolerance = 5e-3)
  expect_equal(CCX_PARAM_TABLE$w_vent$prior(200), dlnorm(200, log(ccx_w_vent_prior()$centre_sv), ccx_w_vent_prior()$log_sd, log = TRUE))
  expect_gt(ccx_w_vent_prior()$log_sd, 0.5)                          # wide by design: two readings a factor 3 apart
  expect_identical(c(CCX_PARAM_TABLE$w_vent$lo, CCX_PARAM_TABLE$w_vent$hi), c(0, 1500))
})

test_that("P0a NO-OP: names absent vs present at defaults is BIT-EXACT, and the loop is INERT under the solved field, both cores", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  q <- p; q$pump_field <- NULL; q$pump_export <- NULL; q$w_vent <- NULL; q$gamma_vent <- NULL; q$k_e1 <- NULL; q$k_e2 <- NULL
  r <- p; r$w_vent <- 20; r$gamma_vent <- 0.5; r$pump_export <- 9.08     # "solved": all three inert
  a <- ccx_spinup(p); b <- ccx_spinup(q); d <- ccx_spinup(r)
  expect_identical(a$y, b$y); expect_identical(a$y, d$y)
  expect_identical(a$aux$pump, d$aux$pump); expect_identical(d$aux$e_on, 0L)
  expect_identical(ccx_e_loop_eigbound(r, a$grid), 0)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(r))
  F0 <- zero_forc_e(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  expect_identical(ccx_deriv(a$y, 1900.2, r, F0, d$grid, d$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14)
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F); rd <- ccx_run_fast(d, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$state, rd$state)
  expect_identical(ra$out, rb$out); expect_identical(ra$out, rd$out)
})

test_that("P0a (canonical): the canonical's stored LIKELIHOOD reproduces row by row; the three names are the ONLY new fitted names", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  expect_identical(ccx_mode_pump_field(md), "solved")             # no field recorded = the solved one, a FACT
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  expect_identical(bp$pump_field, "solved")
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  new_names <- setdiff(CCX_PARAM_NAMES, c(md$param_names, names(md$pins)))
  # 2026-09-17 (h): absent (a hilda file) or PINNED (hilda30h) -- not fitted either way
  # 2026-09-20 (r): DERIVED -- the names inert under the canonical's own structure / field (w_enso_l2 is
  # FITTED under hilda_csl3, so it is not among them; it was, under hilda_c)
  six <- ccx_inert_names(ccx_mode_pump_field(md), ccx_mode_struct(md))   # + the layer-2 limb w_enso_l2 (2026-09-17 k)   # + O1 arm THC (2026-09-15 d)
  expect_setequal(union(new_names, intersect(names(md$pins), six)), six)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-e"))
  if ("w_vent" %in% new_names) expect_identical(pm$w_vent, CCX_PARAM_TABLE$w_vent$init)   # seeded: 0 is on the floor
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  st <- attr(sc, "streams")
  expect_identical(st[names(md$streams)], md$streams)              # 25 rows, bit-exact
})

test_that("P0e THE FIELD: sum(S) = E_h exactly, Martin below the ML base, the seafloor remainder in the bottom layer; 0 -> NULL; pump_grad INERT", {
  p <- e_par(w_vent = 0)
  aux <- ccx_prepare(p); g <- ccx_ocean_grid(p$h_ml)
  a_tot <- aux$a_ls$NH + aux$a_ls$SH
  for (h in HEMIS) {
    S <- aux$pump[[h]]$org + aux$pump[[h]]$carb
    expect_equal(sum(S), 9.08 * aux$a_ls[[h]] / a_tot, tolerance = 1e-12)
    expect_true(all(S > 0))                                         # a remineralization field, never a divergence
    zi <- cumsum(g$dz); Fz <- (zi / zi[1])^(-ccx_const("MARTIN_B"))
    expect_equal(S[1] / sum(S), 1 - Fz[2], tolerance = 1e-12)      # layer 1 takes 1 - F(z_1)
    expect_equal(S[g$nl] / sum(S), Fz[g$nl] , tolerance = 1e-12)   # the bottom layer takes F(z_{nl-1}) - F(z_nl) + F(z_nl)
    expect_equal(aux$pump[[h]]$carb / S, rep(p$pump_carb_frac, g$nl), tolerance = 1e-12)
  }
  expect_equal(aux$pump$NH$org[1] / (aux$pump$NH$org[1] + aux$pump$SH$org[1]), aux$a_ls$NH / a_tot, tolerance = 1e-12)
  q <- p; q$pump_export <- 0; expect_null(ccx_prepare(q)$pump)
  q <- p; q$pump_grad <- 999; expect_identical(ccx_prepare(q)$pump, aux$pump)
  q <- p; q$pump_grad <- 0;   expect_identical(ccx_prepare(q)$pump, aux$pump)
  # the session library reads the constant, not a literal
  src <- readLines(ccx_path("calibration", "lib_martin_shape.R"))
  expect_true(any(grepl('MS_MARTIN_B <- ccx_const\\("MARTIN_B"\\)', src)))
})

test_that("P0c FIXED POINT: a uniform column has zero tendency from E's limbs, cell OFF and ON (D1), and the weights are thickness over the band", {
  for (struct in c("hilda", "hilda_eq")) {
    p <- e_par(struct = struct, w_vent = 20, gamma_vent = 0.5)
    if (struct == "hilda_eq") { p$w_eq <- 27; p$gamma_eq <- 1 }
    sp <- ccx_spinup(p); aux <- sp$aux
    expect_identical(aux$e_on, 1L)
    dzk <- sp$grid$dz[2:4]
    expect_equal(aux$e_w, c(dzk / sum(dzk), rep(0, sp$grid$nl - 3)), tolerance = 1e-14)
    expect_equal(aux$e_share$NH + aux$e_share$SH, 1, tolerance = 1e-14)
    y <- uniform_ocean(sp)
    F0 <- zero_forc_e(sp$prod_c14, enso = -0.8)
    q <- p; q$w_vent <- 0
    d1 <- ccx_deriv(y, 1900.2, p, F0, sp$grid, aux); d0 <- ccx_deriv(y, 1900.2, q, F0, sp$grid, ccx_prepare(q))
    W <- 20 * CCX_SV_TO_M3YR * 2.0e-6                               # the loop's gross carbon carriage, GtC/yr
    expect_lt(max(abs(d1[, "C"] - d0[, "C"])) / W, 1e-12)
  }
})

test_that("P0b CONSERVATION and P0d PARITY with E on, at both seasonal states; the loop MOVES the state (not a silent no-op)", {
  skip_if_no_cpp()
  for (seas in c(0, 1)) {
    p <- e_par(seas_ml = seas)
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
    # the loop is LIVE: the PI equilibrium with w_vent 20 differs from w_vent 0
    q <- p; q$w_vent <- 0
    expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  }
})

test_that("P0f MUTATIONS: the Nino3.4 sign, the band's depth, and every guard by name", {
  p <- e_par(w_vent = 20, gamma_vent = 0.5)
  sp <- ccx_spinup(p)
  d_nino <- ccx_deriv(sp$y, 1900.2, p, zero_forc_e(sp$prod_c14, enso = 1), sp$grid, sp$aux)
  d_nina <- ccx_deriv(sp$y, 1900.2, p, zero_forc_e(sp$prod_c14, enso = -1), sp$grid, sp$aux)
  d_zero <- ccx_deriv(sp$y, 1900.2, p, zero_forc_e(sp$prod_c14, enso = 0), sp$grid, sp$aux)
  iml <- sp$aux$idx$NH$ml
  # El Nino SUPPRESSES the loop (less DIC-rich return to the ML); La Nina strengthens it -- opposite signs about 0
  expect_lt((d_nino[iml, "C"] - d_zero[iml, "C"]) * (d_nina[iml, "C"] - d_zero[iml, "C"]), 0)
  # the floor: at enso >= 1/gamma the loop is OFF and equals w_vent = 0
  q <- p; q$w_vent <- 0
  expect_identical(ccx_deriv(sp$y, 1900.2, p, zero_forc_e(sp$prod_c14, enso = 2), sp$grid, sp$aux),
                   ccx_deriv(sp$y, 1900.2, q, zero_forc_e(sp$prod_c14, enso = 2), sp$grid, ccx_prepare(q)))
  # the band: ventilating only layer 1 vs layers 1-3 changes the deep state
  q <- p; q$k_e2 <- 1L
  expect_gt(max(abs(ccx_spinup(q)$y[, "C"] - sp$y[, "C"])), 1e-3)
  # guards
  q <- p; q$pump_field <- "glodap";       expect_error(ccx_prepare(q), "pump_field")
  q <- p; q$pump_export <- -1;            expect_error(ccx_prepare(q), "pump_export")
  q <- p; q$w_vent <- -5;                 expect_error(ccx_prepare(q), "w_vent")
  q <- p; q$gamma_vent <- -0.1;           expect_error(ccx_prepare(q), "gamma_vent")
  q <- p; q$k_e2 <- 11L;                  expect_error(ccx_prepare(q), "k_e1..k_e2")
  q <- p; q$k_e1 <- 3L; q$k_e2 <- 2L;     expect_error(ccx_prepare(q), "k_e1..k_e2")
  # the stability bound is live and scales with the flux
  expect_gt(ccx_e_loop_eigbound(p, sp$grid), 0)
  q <- p; q$w_vent <- 40
  expect_equal(ccx_e_loop_eigbound(q, sp$grid), 2 * ccx_e_loop_eigbound(p, sp$grid), tolerance = 1e-12)
})

test_that("N-E1 (re-scoped): at the export reproducing the canonical's PI bottom-minus-ML gradient the ocean_grad_dic row moves at most about 1 log-unit; the shape and the deep d13C shift are REPORTED", {
  skip_if_no_cpp()
  # ⚠ AT hilda34g, NAMED (2026-10-06 a) (Marcus 2026-10-06: "Approve all (Recommended)"). From 10-06 the canonical hilda33p carries the stratification
  # feedback, which the martin field cannot carry (DESIGN §3.4a S: the prescribed export does not read K), so
  # "the canonical under the martin field" is no longer one model. Option E is CLOSED; this is provenance, and
  # hilda34g is the last canonical the construction applies to (its recorded 0.38 below stands).
  md <- readRDS(ccx_mode_file("hilda34g"))
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "N-E1"))
  p0 <- bp; for (n in names(pm)) p0[[n]] <- pm[[n]]
  for (n in names(md$pins)) p0[[n]] <- md$pins[[n]]
  prof_of <- function(p) { sp <- ccx_spinup(p); ix <- sp$aux$idx$NH; g <- sp$grid
    c(sp$y[ix$ml, "C"] / (sp$aux$a_ml$NH * g$dz[1]),
      vapply(seq_len(g$nl), function(k) sp$y[ix$oc[k], "C"] / (sp$aux$a_ls$NH * g$dz[k + 1]), numeric(1))) *
      sp$aux$mol_per_GtC / ccx_const("RHO_SEAWATER") * 1e6 }                       # umol/kg, ML then layers
  pr0 <- prof_of(p0); g0 <- pr0[length(pr0)] - pr0[1]
  pm1 <- p0; pm1$pump_field <- "martin"; pm1$w_vent <- 0
  f <- function(E) { pm1$pump_export <- E; pr <- prof_of(pm1); pr[length(pr)] - pr[1] - g0 }
  E_match <- uniroot(f, c(1, 200), tol = 1e-4)$root
  pm1$pump_export <- E_match; pr1 <- prof_of(pm1)
  st0 <- attr(ccx_make_logpost(base_params = bp, by_stream = TRUE)(ccx_par_to_unc(pm)), "streams")
  bp1 <- bp; bp1$pump_field <- "martin"
  # the loop OFF is a PIN, not a point of the fitted space (0 sits on w_vent's floor)
  # (only the names still FITTED: at a canonical that already pins them (hilda30h) there is nothing to hold)
  rm2 <- ccx_apply_pins(c(w_vent = 0, gamma_vent = 0)[c("w_vent", "gamma_vent") %in% CCX_PARAM_NAMES])
  pm1u <- pm; pm1u$pump_export <- E_match; pm1u$w_vent <- NULL; pm1u$gamma_vent <- NULL
  bp1$w_vent <- 0; bp1$gamma_vent <- 0
  st1 <- attr(ccx_make_logpost(base_params = bp1, by_stream = TRUE)(ccx_par_to_unc(pm1u)), "streams")
  ccx_unpin_params(rm2)
  # THE RECORD: at hilda30c (09-14 h, where N-E1 was re-scoped) the row moved < 1 log-unit at the
  # matched export. At hilda30h (09-17 h; the canonical's own ocean_grad_dic row is -8.0, z +3.1 on
  # the gradient, WORSE than hilda30c's) the same construction moves it 3.1: a MEASURED value at
  # the new canonical, recorded here as such -- option E is CLOSED (refuted 09-15 b), so this is
  # provenance of the matched-export read, not a bound on a live candidate.
  # At hilda30s (09-20 (o), hilda_cs: the ML's NH cycle flat, pump_grad 330 / pump_hs_gcm2 81 / h_ml 58):
  # the same construction moves the row 0.43 -- back under 1, as at hilda30c. MEASURED, recorded.
  # At hilda33d (2026-10-01 c, the D2/D3 canonical): 1.05 -- just over 1. MEASURED, recorded (re-pin approved
  # by Marcus); option E stays CLOSED, so this remains provenance, not a bound.
  # At hilda34g (2026-10-03 h, the land ENSO lag fitted): 0.38 (0.3777) -- back under 1. MEASURED, recorded
  # (Marcus 2026-10-03: "Approve all (Recommended)"); the test's name now says "at most about 1", which is true at every canonical recorded here
  # bar hilda30h's 3.1.
  expect_equal(abs(st1[["ocean_grad_dic"]] - st0[["ocean_grad_dic"]]), 0.38, tolerance = 0.15, scale = 1)
  cat(sprintf("\n  N-E1: export matching the canonical's PI bottom-minus-ML gradient (%.1f umol/kg): %.2f GtC/yr (the solved field: %.1f);\n        ocean_grad_dic %+.2f, ocean_grad_d13c %+.2f log-units vs the canonical\n",
              g0, E_match, sum(ccx_prepare(p0)$pump$NH$org + ccx_prepare(p0)$pump$NH$carb + ccx_prepare(p0)$pump$SH$org + ccx_prepare(p0)$pump$SH$carb),
              st1[["ocean_grad_dic"]] - st0[["ocean_grad_dic"]], st1[["ocean_grad_d13c"]] - st0[["ocean_grad_d13c"]]))
  cat("        DIC minus ML, solved | martin, umol/kg by layer:\n        ",
      paste(sprintf("%.0f|%.0f", pr0[-1] - pr0[1], pr1[-1] - pr1[1]), collapse = "  "), "\n")
})
