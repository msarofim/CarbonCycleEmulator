# =====================================================================
# O5b -- THE HIGH-LATITUDE PUMP ON THE DATA'S RECTIFIED BLOOM (2026-09-16 b):
# `pump_hs_seas_amp` [0, 1], `pump_hs_seas_lag` [months] -- STRUCTURAL names,
# multiplying the HS pump (only) by
#   s_hs,h(t) = 1 + amp x (F_h(t - lag/12) - 1),
# F_h = ccx_mld_fourier() of the CMIP6 ensemble-median unit-mean HS shape
# (data/obs_export_seasonal_shape_cmip6.rds), replacing O5's sine on the HS
# pump when amp > 0. notes/prereg_2026-09-16b_o5b_hs_seasonal_export.md §0 P0,
# gated BEFORE any probe number is read:
#   P0a NO-OP        absent vs present-at-0 bit-exact, both cores; the canonical's
#                    stored streams reproduce; inert with seas_drivers 0.
#   P0b ANNUAL MEAN  the factor's continuous mean is 1; the HS pump's whole-year
#                    tendency at amp 1 equals the constant export's.
#   P0c PARITY       R vs C++ derivative and transient at amp {0.5, 1} x lag {0, 2}
#                    x pump_seas_amp {0, 0.5}; mutate p after ccx_prepare().
#   P0d CONSERVATION closed system with the factor on.
#   P0e SHAPE        SH HS export peaks in January and is ~0 in July; NH the
#                    reverse; the LS pump is UNTOUCHED; precedence over the sine.
#   P0f MUTATIONS    every guard by name; lag 6 moves the SH minimum by six months;
#                    the continuous minimum at amp 1 is > 0.
# =====================================================================
phs_par <- function(amp = 1, lag = 0, ls_amp = 0, ls_lag = 0, seas_ml = 1, field = "martin", export = 9.08, hs_gcm2 = 86.6) {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = seas_ml, pump_field = field)
  if (identical(field, "martin")) p$pump_export <- export
  p$pump_hs_gcm2 <- hs_gcm2
  p$pump_seas_amp <- ls_amp; p$pump_seas_lag <- ls_lag
  p$pump_hs_seas_amp <- amp; p$pump_hs_seas_lag <- lag
  p
}
phs_spinup <- function(p) suppressWarnings(ccx_spinup(p))   # the HS box's SST sits at the carbonate table's edge
zero_forc_h <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
tt12 <- 1900 + (0:11 + 0.5) / 12

test_that("the names ship OFF and are structural; no name prefixes another; the shape loads unit-mean and positive", {
  p <- ccx_default_params()
  expect_identical(p$pump_hs_seas_amp, 0); expect_identical(p$pump_hs_seas_lag, 0)
  expect_false("pump_hs_seas_amp" %in% CCX_PARAM_NAMES); expect_false("pump_hs_seas_lag" %in% CCX_PARAM_NAMES)
  # `aux$pump_hs` (the HS pump's solved fluxes) is a PREFIX of the new names. It
  # is an EXACT element of aux whenever the HS pump is on and ABSENT when off --
  # and the shape coefficients deliberately live under `hs_export_seas_coef`,
  # NOT `pump_hs_*`, so `aux$pump_hs` can never partial-match onto them when
  # the pump is off; p never carries `pump_hs`. That is why "pump_hs" joins
  # "pump" in the exclusions, and the next line asserts the aux name directly.
  nm <- c(names(ccx_default_params()), CCX_PARAM_NAMES, names(ccx_prepare(phs_par(amp = 0))))
  expect_setequal(grep("^pump_hs", unique(nm), value = TRUE), c("pump_hs", "pump_hs_gcm2", "pump_hs_seas_amp", "pump_hs_seas_lag"))
  off <- ccx_prepare(phs_par(amp = 0, hs_gcm2 = 0)); expect_null(off$pump_hs); expect_null(off$hs_export_seas_coef)
  for (new in c("pump_hs_seas_amp", "pump_hs_seas_lag")) {
    others <- setdiff(unique(nm), c(new, "pump", "pump_hs"))
    expect_false(any(startsWith(others, new))); expect_false(any(startsWith(new, others)))
  }
  co <- ccx_export_hs_seas_shape()
  for (h in HEMIS) {
    expect_lt(abs(mean(co[[h]]$f_month) - 1), 1e-12)               # renormalized to mean 1
    expect_gt(co[[h]]$f_min, 0)                                     # the export never reverses at amp 1
    expect_gt(co[[h]]$f_max, 2.5)                                   # a RECTIFIED bloom, not a sine
  }
  expect_equal(which.max(co$SH$f_month), 1L)                        # SH peaks in January
  expect_equal(which.max(co$NH$f_month), 6L)                        # NH in June
})

test_that("P0a NO-OP: absent vs present-at-0 is BIT-EXACT in both cores; inert under seas_drivers 0", {
  p <- phs_par(amp = 0, lag = 2)
  q <- p; q$pump_hs_seas_amp <- NULL; q$pump_hs_seas_lag <- NULL
  a <- phs_spinup(p); b <- phs_spinup(q)
  expect_identical(a$y, b$y)
  F0 <- zero_forc_h(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  r <- p; r$pump_hs_seas_amp <- 1; r$seas_drivers <- 0; s <- p; s$seas_drivers <- 0
  expect_identical(ccx_deriv(a$y, 1900.2, r, F0, a$grid, a$aux), ccx_deriv(a$y, 1900.2, s, F0, a$grid, a$aux))
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = a$prod_c14)
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$out, rb$out)
  fr <- ccx_forcing_at(F, 3L)
  expect_identical(ccx_deriv_fast(a$y, F$t[3], r, fr, a$grid, a$aux), ccx_deriv_fast(a$y, F$t[3], s, fr, a$grid, a$aux))
})

test_that("P0a (canonical): hilda30c's stored LIKELIHOOD reproduces row by row under this build", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-pump-hs-seas"))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})

# the HS pump's tendency on the HS box: derivative with the HS pump on minus off
hs_pump_d <- function(sp, p, t) {
  q <- p; q$pump_hs_gcm2 <- 0; q$pump_hs_seas_amp <- 0
  aux0 <- ccx_prepare(q)
  dp <- ccx_deriv(sp$y, t, p, zero_forc_h(sp$prod_c14), sp$grid, sp$aux)
  d0 <- ccx_deriv(sp$y, t, q, zero_forc_h(sp$prod_c14), sp$grid, aux0)
  vapply(HEMIS, function(h) dp[sp$aux$idx[[h]]$hs, "C"] - d0[sp$aux$idx[[h]]$hs, "C"], numeric(1))
}

test_that("P0b ANNUAL MEAN and P0e SHAPE: the factor's continuous mean is 1; the HS pump follows the shape; the LS pump is untouched", {
  co <- ccx_export_hs_seas_shape()
  fine <- (seq_len(2400) - 0.5) / 2400
  for (h in HEMIS) for (lag in c(-1, 0, 2))
    expect_lt(abs(mean(vapply(fine, function(t) ccx_mld_eval(co[[h]], t - lag / 12)$f, numeric(1))) - 1), 1e-12)
  p1 <- phs_par(amp = 1); p0 <- phs_par(amp = 0); sp <- phs_spinup(p1)
  ratio <- sapply(tt12, function(t) hs_pump_d(sp, p1, t) / hs_pump_d(sp, p0, t))
  for (h in HEMIS) expect_lt(max(abs(ratio[h, ] - co[[h]]$f_month)), 1e-9)   # exact at the month centers
  for (h in HEMIS) expect_lt(abs(mean(ratio[h, ]) - 1), 1e-9)                 # zero-mean anomaly
  expect_equal(which.max(ratio["SH", ]), 1L); expect_lt(ratio["SH", 7], 0.05)  # January bloom, July ~0
  expect_equal(which.max(ratio["NH", ]), 6L); expect_lt(ratio["NH", 1], 0.05)
  # amp 0.5 = half the anomaly
  ph <- phs_par(amp = 0.5)
  rh <- sapply(tt12, function(t) hs_pump_d(sp, ph, t) / hs_pump_d(sp, p0, t))
  for (h in HEMIS) expect_lt(max(abs(rh[h, ] - (1 + 0.5 * (co[[h]]$f_month - 1)))), 1e-9)
  # the LS pump never reads the HS names: the ML tendency is identical at amp 0 and 1
  d_ml <- function(p) sapply(tt12, function(t) ccx_deriv(sp$y, t, p, zero_forc_h(sp$prod_c14), sp$grid, sp$aux)[sp$aux$idx$SH$ml, "C"])
  expect_identical(d_ml(p1), d_ml(p0))
  # PRECEDENCE: with the LS sine on and the HS amp 0, the HS pump carries the SINE (O5 as built); with amp > 0, the SHAPE
  ps <- phs_par(amp = 0, ls_amp = 1, ls_lag = 0); pb <- phs_par(amp = 1, ls_amp = 1, ls_lag = 0)
  sine <- function(h, t) 1 + (if (h == "NH") 1 else -1) * sin(2 * pi * (t - 3.5 / 12))
  rs <- sapply(tt12, function(t) hs_pump_d(sp, ps, t) / hs_pump_d(sp, p0, t))
  rb <- sapply(tt12, function(t) hs_pump_d(sp, pb, t) / hs_pump_d(sp, p0, t))
  for (h in HEMIS) { expect_lt(max(abs(rs[h, ] - sine(h, tt12))), 1e-9); expect_lt(max(abs(rb[h, ] - co[[h]]$f_month)), 1e-9) }
})

test_that("P0c PARITY and P0d CONSERVATION at amp {0.5, 1} x lag {0, 2} x pump_seas_amp {0, 0.5}; the factor MOVES the transient", {
  skip_if_no_cpp()
  for (ls_amp in c(0, 0.5)) for (amp in c(0.5, 1)) for (lag in c(0, 2)) {
    p <- phs_par(amp = amp, lag = lag, ls_amp = ls_amp, ls_lag = -1)
    sp <- phs_spinup(p)
    F  <- ccx_build_forcing("historical", c(1900, 1903), prod_c14 = sp$prod_c14)
    for (i in c(1L, 7L)) { fr <- ccx_forcing_at(F, i)
      dR <- ccx_deriv(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      dC <- ccx_deriv_fast(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10) }
    r <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
    expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
    F0 <- F; for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F0[[cc]][] <- 0
    r0 <- ccx_run_fast(sp, F0)
    expect_lt(abs(sum(r0$state[, "C"]) - sum(sp$y[, "C"])) / sum(sp$y[, "C"]), 1e-10)
    q <- p; q$pump_hs_seas_amp <- 0
    expect_gt(max(abs(r$out$hs_pco2_SH - ccx_run_fast(phs_spinup(q), F)$out$hs_pco2_SH)), 1e-2)
  }
  # the 09-09t class: aux built with amp 1, then p switched to 0 -- both cores obey p
  p <- phs_par(amp = 1); sp <- phs_spinup(p)
  q <- p; q$pump_hs_seas_amp <- 0
  fr <- zero_forc_h(sp$prod_c14, enso = 0.3)
  dR <- ccx_deriv(sp$y, 1900.2, q, fr, sp$grid, sp$aux); dC <- ccx_deriv_fast(sp$y, 1900.2, q, fr, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)), 1e-9)
  expect_identical(dR, ccx_deriv(sp$y, 1900.2, q, fr, sp$grid, ccx_prepare(q)))   # aux's coefficients are inert at amp 0
})

test_that("P0f MUTATIONS: every guard by name; lag 6 moves the SH minimum by six months; the annual mean survives a lag", {
  p <- phs_par()
  q <- p; q$pump_hs_seas_amp <- 1.2; expect_error(ccx_prepare(q), "pump_hs_seas_amp")
  q <- p; q$pump_hs_seas_amp <- -0.1; expect_error(ccx_prepare(q), "pump_hs_seas_amp")
  q <- p; q$pump_hs_seas_amp <- NA_real_; expect_error(ccx_prepare(q), "pump_hs_seas_amp")
  q <- p; q$pump_hs_seas_lag <- Inf; expect_error(ccx_prepare(q), "pump_hs_seas_lag")
  q <- p; q$pump_hs_gcm2 <- 0; expect_error(ccx_prepare(q), "needs the HS pump")
  q <- phs_par(hs_gcm2 = 0); q <- ccx_apply_structure(q, "", seas_ml = 1); q$pump_hs_seas_amp <- 1
  expect_error(ccx_prepare(q), "pump_hs_seas_amp|hs_frac")
  sp <- phs_spinup(p); p0 <- phs_par(amp = 0)
  hs <- function(lag) { q <- p; q$pump_hs_seas_lag <- lag; sapply(tt12, function(t) (hs_pump_d(sp, q, t) / hs_pump_d(sp, p0, t))[["SH"]]) }
  a <- hs(0); b <- hs(6)
  expect_equal(which.min(a), 7L)                        # the SH bloom is off in July
  expect_equal(which.min(b), 1L)                        # ... and in January under a 6-month lag
  expect_equal(which.max(b), 7L)
  expect_lt(abs(mean(a) - 1), 1e-9); expect_lt(abs(mean(b) - 1), 1e-9)
})
