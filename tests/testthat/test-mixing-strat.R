# =====================================================================
# THE STRATIFICATION FEEDBACK (DESIGN §3.4a S; RULED 2026-10-04, Marcus; CHANGELOG 10-04 m):
# K(z, t) = K_int - (1 - g(t)) K_up, g = (1 + s T_key)^(-q/2), T_key = max(0, T - T_deep),
# T_deep = T lagged at tau; the SOLVED export rescaled S = S_full - (1 - g) S_up. Label
# "hilda_csl3v0kaidgbem" (R/calibrate.R). Every gate below is a MUTATION test in the sense of
# [[mutation_test_gates]]: the property guarded is broken in the same test, and the gate must
# then fail -- or its mutation was run by hand and is recorded in CHANGELOG 10-04 (n).
#   S1 CONSTANTS   s re-derived from its data; tau tied to the climate module; the label's block
#   S2 THE SERIES  g = 1 exactly at T <= 0; the exact step response; mid-record refusal; a
#                  split run's g equals the unsplit run's
#   S3 OFF         hilda34g's stored likelihood reproduces row by row (absent, and at s = 0)
#   S4 SPINUP      bit-identical ON vs OFF (the spinup's climate is held at 0, so g = 1)
#   S5 PARITY / CONSERVATION, mechanism ON at g < 1
#   S6 THE PUMP    the rescaling identity, and its MUTATION: without it a held-zero-emission run
#                  under a forced key takes up natural carbon (the spurious, wrong-signed sink)
#   S7 DIRECTION   the ocean sink falls monotonically in s and in q; hilda34g's own number
#   S8 REFUSALS    tr box, martin field, uniform K, a point forcing without mix_g
# =====================================================================
# ⚠ THE FIXTURE IS hilda34g, NAMED (2026-10-06 a) (Marcus 2026-10-06: "Approve all (Recommended)"): the feedback-OFF canonical the mechanism was built
# and priced on (10-04 n/o). Every gate below contrasts ON with OFF from that base, and ms_on() switches it ON.
# From 10-06 the canonical hilda33p carries the feedback, so read as "the canonical" every contrast collapses.
MS_OFF_MODE <- "hilda34g"
ms_canon <- local({ cache <- NULL; function() {
  if (!is.null(cache)) return(cache)
  md <- readRDS(ccx_mode_file(MS_OFF_MODE))
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md)); attr(pm, "migrated_done") <- TRUE
  p  <- ccx_overlay_par(bp, pm)
  cache <<- list(md = md, p = p, spin = ccx_spinup_from_label(ccx_mode_spinup(md)))
  cache } })
ms_on <- function(p, s = ccx_const("MIX_STRAT_S"), q = ccx_const("MIX_STRAT_Q")) {
  p$mix_strat_s <- s; p$mix_strat_q <- q; p$mix_strat_tau <- ccx_const("MIX_TDEEP_TAU"); p }
ms_sink <- function(r, yrs = 2014:2024) {         # mean ocean uptake over the window, GtC/yr
  o <- tapply(r$out$ocean_C, floor(r$out$t), mean); mean(diff(o[as.character(yrs)])) }

test_that("S1 CONSTANTS: s re-derived from its own data, tau tied to the climate module, the label adds exactly three names", {
  g <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
  tau <- readRDS(ccx_path("data", "climate_module.rds"))$irf_d[3]
  expect_equal(ccx_const("MIX_TDEEP_TAU"), tau, tolerance = 1e-8)
  yrs <- 1750:max(g$year); T <- ifelse(yrs < 1850, 0, g$gmst_anom[match(yrs, g$year)])
  a <- exp(-1 / tau); Td <- Reduce(function(prev, x) a * prev + (1 - a) * x, T, accumulate = TRUE, 0)[-1]
  key <- pmax(0, T - Td); w <- yrs >= 1960 & yrs <= 2024
  b <- 10 * unname(stats::coef(stats::lm(key[w] ~ yrs[w]))[2])            # K/decade
  expect_equal(ccx_const("MIX_STRAT_S"), 0.008 / b, tolerance = 1e-5)     # Cheng 2025's 0.8 %/decade
  expect_identical(ccx_const("MIX_STRAT_Q"), 1)
  expect_lt(ccx_const("MIX_STRAT_Q_LO"), ccx_const("MIX_STRAT_Q")); expect_gt(ccx_const("MIX_STRAT_Q_HI"), ccx_const("MIX_STRAT_Q"))
  blk_m <- ccx_struct_block("hilda_csl3v0kaidgbem"); blk_e <- ccx_struct_block("hilda_csl3v0kaidgbe")
  expect_identical(setdiff(names(blk_m), names(blk_e)), c("mix_strat_s", "mix_strat_q", "mix_strat_tau"))
  expect_identical(blk_m[names(blk_e)], blk_e)                            # nothing else differs
  expect_identical(ccx_gates_open("hilda_csl3v0kaidgbem"), ccx_gates_open("hilda_csl3v0kaidgbe"))
  # the feedback is ON under #16's label and every label chained from it + the interannual cut's main half (2026-10-06, objective #17; Marcus: "Build: land + ocean module (Recommended)", the name "hilda_csl3v0kaidgbemw (Recommended)")
  # 2026-10-22: + hilda_csl3v0kaidgbemwtcf, the flask label (...wtc's model and blocks, plus a likelihood switch)
  MIX_ON_LABELS <- c("hilda_csl3v0kaidgbem", "hilda_csl3v0kaidgbemw", "hilda_csl3v0kaidgbemwt", "hilda_csl3v0kaidgbemwtc", "hilda_csl3v0kaidgbemwtcf")  # + the redesigned cut (2026-10-07, objective #18; Marcus: "Full redesign (Recommended)", the name "hilda_csl3v0kaidgbemwt (Recommended)")
  for (lab in MIX_ON_LABELS) expect_true(ccx_mix_on(ccx_apply_structure(ccx_default_params(), lab, seas_ml = "1")), info = lab)
  for (lab in setdiff(CCX_STRUCT_LABELS, MIX_ON_LABELS))                # every other label: OFF
    expect_false(ccx_mix_on(ccx_apply_structure(ccx_default_params(), lab, seas_ml = "1")), info = lab)
})

test_that("S2 THE SERIES: g = 1 exactly at T <= 0, the exact step response, the cap, mid-record refused, split = unsplit", {
  p <- ms_on(list(), s = 0.05, q = 1); tau <- ccx_const("MIX_TDEEP_TAU")
  t <- 1850 + (seq_len(1213) - 0.5) / 12
  expect_identical(as.numeric(ccx_mix_g_series(rep(0, 1213), t, p)), rep(1, 1213))
  expect_identical(as.numeric(ccx_mix_g_series(rep(-1, 1213), t, p)), rep(1, 1213))      # the cap: cooling never raises K
  expect_identical(ccx_mix_g_series(rnorm(10), (1:10) / 12, list(mix_strat_s = 0)), rep(1, 10))   # OFF
  T <- c(rep(0, 13), rep(2, 1200)); g <- ccx_mix_g_series(T, t, p)
  n <- seq_len(1200); a <- exp(-(1 / 12) / tau)
  expect_equal(as.numeric(g[13 + n]), (1 + 0.05 * 2 * a^n)^(-1 / 2), tolerance = 1e-12)  # key = dT a^n, exactly
  expect_true(all(g <= 1))
  # MUTATION of the cap: an uncapped key under cooling WOULD raise g above 1
  key_uncapped <- -1 - attr(ccx_mix_g_series(rep(-1, 1213), t, p), "tdeep")
  expect_gt(max((1 + 0.05 * key_uncapped)^(-1 / 2)), 1)
  Tv <- c(rep(0, 13), seq(0, 1, length.out = 20), rep(1, 87))     # a constant run-in, as from a spinup
  expect_error(ccx_mix_g_series(Tv[5:120], t[5:120], p), "OPENS MID-RECORD")
  gA <- ccx_mix_g_series(Tv, t[seq_along(Tv)], p)
  td <- ccx_mix_tdeep_after(Tv[1:60], t[1:60], p)
  gB <- c(ccx_mix_g_series(Tv[1:60], t[1:60], p), ccx_mix_g_series(Tv[61:120], t[61:120], p, tdeep0 = td))
  expect_equal(as.numeric(gB), as.numeric(gA), tolerance = 1e-15)
})

test_that("S3 OFF: hilda34g's stored likelihood reproduces row by row, absent AND at s = 0; the aux carries nothing", {
  skip_if_no_cpp()
  C <- ms_canon(); md <- C$md
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  g <- ccx_apply_gate(ccx_mode_struct(md)); rp <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rp); ccx_unapply_gate(g) }, add = TRUE)
  u <- ccx_par_to_unc(ccx_mode_par_with_pins(md))
  for (b in list(bp, within(bp, mix_strat_s <- 0))) {
    sc <- ccx_make_logpost(base_params = b, by_stream = TRUE, spinup_fn = C$spin)(u)
    expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
  }
  expect_false(ccx_mix_on(C$p)); a <- ccx_prepare(C$p)
  expect_identical(a$mix_on, 0L); expect_null(a$kz_up); expect_null(a$pump_up)
})

test_that("S4 SPINUP, S5 PARITY and CONSERVATION with the mechanism ON at g < 1; ON MOVES the transient", {
  skip_if_no_cpp()
  C <- ms_canon(); p0 <- C$p; p1 <- ms_on(p0)
  s0 <- C$spin(p0); s1 <- C$spin(p1)
  expect_identical(s1$y, s0$y)                                            # S4: g = 1 throughout the spinup
  expect_identical(s1$aux$mix_on, 1L); expect_identical(ccx_substeps_for(p1), ccx_substeps_for(p0))
  expect_true(all(s1$aux$kz_up > 0)); expect_true(all(s1$aux$kz_up <= s1$aux$kz_int))
  # the ABYSSAL FLOOR is untouched: K_int - K_up is f kz at EVERY interface (the ruling: thermocline
  # mixing only). A K_up that took the whole profile would weaken the deep tidal mixing too.
  expect_equal(s1$aux$kz_int - s1$aux$kz_up, rep(p1$kz * p1$kz_deep_frac, length(s1$aux$kz_int)),
               tolerance = 1e-9)
  F <- ccx_build_forcing("historical", c(1996, 1999), prod_c14 = s1$prod_c14,
                         enso_index = ccx_enso_index_of(p1), aod_mode = ccx_aod_mode_of(p1))
  # a window opening mid-record: carry the histories the way a continuation would
  s1$enso_hist <- "hold"; s1$tdeep0 <- 0.15
  Fp <- F; Fp$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(p1), "hold")
  Fp$mix_g <- as.numeric(ccx_mix_g_series(F$gmst, F$t, p1, tdeep0 = 0.15))
  expect_lt(max(Fp$mix_g), 1)
  for (i in c(1L, 30L)) { fr <- ccx_forcing_at(Fp, i)
    dR <- ccx_deriv(s1$y, F$t[i], p1, fr, s1$grid, s1$aux)
    dC <- ccx_deriv_fast(s1$y, F$t[i], p1, fr, s1$grid, s1$aux)
    expect_lt(max(abs(dR - dC)) / max(abs(dR)), 5e-14)                    # test-parity.R's PARITY_REL_TOL
    # the mechanism is LIVE in the derivative at g < 1
    fr1 <- fr; fr1$mix_g <- 1
    expect_false(identical(ccx_deriv(s1$y, F$t[i], p1, fr1, s1$grid, s1$aux), dR)) }
  r <- ccx_run_fast(s1, F); rR <- suppressWarnings(ccx_run(s1, F))
  expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)   # S5 parity, transient
  F0 <- F; for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F0[[cc]][] <- 0
  r0 <- ccx_run_fast(s1, F0)
  for (tr in c("C", "C13"))                                               # S5 conservation
    expect_lt(abs(sum(r0$state[, tr]) - sum(s1$y[, tr])) / sum(s1$y[, tr]), 1e-10)
  s0$enso_hist <- "hold"; s0$tdeep0 <- 0.15
  expect_gt(max(abs(r$state[, "C"] - ccx_run_fast(s0, F)$state[, "C"])), 1e-6)
})

test_that("S6 THE PUMP: the rescaled export IS the export solved against the weakened K; WITHOUT it the ocean takes up natural carbon", {
  skip_if_no_cpp()
  C <- ms_canon(); p1 <- ms_on(C$p); a <- ccx_prepare(p1)
  for (gg in c(0.9, 0.6)) {
    S_g <- ccx_pump_export(p1, a, ccx_ocean_grid(p1$h_ml), kz_override = a$kz_int - (1 - gg) * a$kz_up)
    for (h in HEMIS) for (lim in c("org", "carb"))
      expect_equal(a$pump[[h]][[lim]] - (1 - gg) * a$pump_up[[h]][[lim]], S_g[[h]][[lim]],
                   tolerance = 1e-12 * max(abs(a$pump[[h]][[lim]])))
  }
  # the natural state HELD: zero emissions, every other temperature path OFF, the key forced
  # by a 2 K step in 1850 -- only g sees the warming. Ocean carbon drift over 1850-1950, the
  # mechanism (rescaled) vs OFF vs the MUTANT (rescaling removed).
  p0 <- C$p; p0$q10 <- 1; p0$npp_tsens <- 0; p0$sst_obs <- 0; p0$sst_scale <- 0
  pm <- ms_on(p0); s0 <- C$spin(p0); s1 <- C$spin(pm)
  F <- ccx_build_forcing("historical", c(1750, 1950), prod_c14 = s0$prod_c14,
                         enso_index = ccx_enso_index_of(p0), aod_mode = ccx_aod_mode_of(p0))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]][] <- 0
  F$gmst <- ifelse(F$t >= 1850, 2, 0)
  drift <- function(sp) { r <- ccx_run_fast(sp, F); o <- tapply(r$out$ocean_C, floor(r$out$t), mean)
    o[["1950"]] - o[["1850"]] }
  sm <- s1; sm$aux$pump_up <- NULL                                         # THE MUTANT
  d_off <- drift(s0); d_on <- drift(s1); d_mut <- drift(sm)
  expect_gt(d_mut - d_off, 0)                                             # the spurious sink: the ocean GAINS carbon
  expect_lt(abs(d_on - d_off), abs(d_mut - d_off))                        # the ORDERING the rescaling must deliver
})

test_that("S7 DIRECTION: the historical ocean sink falls monotonically in s and in q, and hilda34g's own effect is small", {
  skip_if_no_cpp()
  C <- ms_canon(); p0 <- C$p
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = C$spin(p0)$prod_c14,
                         enso_index = ccx_enso_index_of(p0), aod_mode = ccx_aod_mode_of(p0))
  sink_at <- function(s, q) { p <- if (s == 0) p0 else ms_on(p0, s, q); ms_sink(ccx_run_fast(C$spin(p), F)) }
  S0 <- sink_at(0, 1); s <- ccx_const("MIX_STRAT_S")
  Ss <- c(sink_at(s / 2, 1), sink_at(s, 1)); Sq <- c(sink_at(s, ccx_const("MIX_STRAT_Q_LO")), Ss[2], sink_at(s, ccx_const("MIX_STRAT_Q_HI")))
  expect_true(S0 > Ss[1] && Ss[1] > Ss[2])
  expect_true(Sq[1] > Sq[2] && Sq[2] > Sq[3])
  # hilda34g's own number (CHANGELOG 10-04 n): -0.0149 GtC/yr over 2015-24, i.e. what a
  # static kz cut of the same size does (elasticity 0.149). A 3x departure is a bug first.
  expect_gt(S0 - Ss[2], 0.0149 / 3); expect_lt(S0 - Ss[2], 0.0149 * 3)
})

test_that("S8 REFUSALS: the tropical box, the martin field, a uniform K, and a point forcing without mix_g", {
  C <- ms_canon(); p1 <- ms_on(C$p)
  pt <- p1; pt$kz_deep_frac <- 1
  expect_error(ccx_prepare(pt), "needs kz_deep_frac < 1")
  pmar <- p1; pmar$pump_field <- "martin"; pmar$pump_export <- 9.08
  expect_error(ccx_prepare(pmar), "SOLVED pump field only")
  ptr <- ccx_apply_structure(ccx_default_params(), "hilda_tr", seas_ml = "0")
  ptr$kz_deep_frac <- 0.5; ptr$kz_zscale <- 300
  expect_error(ccx_prepare(ms_on(ptr)), "tropical box")
  expect_error(ccx_mix_on(within(p1, mix_strat_q <- -1)), "mix_strat_q")
  expect_error(ccx_mix_on(within(p1, mix_strat_tau <- 0)), "mix_strat_tau")
  expect_error(ccx_mix_on(within(p1, mix_strat_s <- -0.1)), "mix_strat_s")
  expect_identical(ccx_point_mix_g(list(gmst = 0.7), C$p), 1)              # OFF: never refused
  expect_identical(ccx_point_mix_g(list(gmst = -0.2), p1), 1)              # ON at T <= 0: exact
  expect_identical(ccx_point_mix_g(list(gmst = 0.7, mix_g = 0.95), p1), 0.95)
  expect_error(ccx_point_mix_g(list(gmst = 0.7), p1), "carries no `mix_g`")
})
