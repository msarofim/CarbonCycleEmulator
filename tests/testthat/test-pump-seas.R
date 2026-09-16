# =====================================================================
# THE SEASONAL EXPORT (option O5, 2026-09-15 f): `pump_seas_amp` [0, 1],
# `pump_seas_lag` [months] -- STRUCTURAL names (the k_thc idiom), multiplying
# every pump limb (LS org + carb from both surface boxes; the HS pump) by
#   s_h(t) = 1 + amp x sigma_h x sin(2 pi (t - (3.5 + lag)/12)),  sigma NH +1 / SH -1.
# notes/prereg_2026-09-15f_o5_seasonal_export.md §1, P0 -- gated BEFORE any
# probe number is read:
#   P0a NO-OP        absent vs present-at-0 bit-exact, both cores; the canonical's
#                    stored streams reproduce; inert with seas_drivers 0.
#   P0b ANNUAL MEAN  the whole-year integral of every pump limb at amp 1 equals
#                    the constant export (zero-mean by construction).
#   P0c PARITY       R vs C++ derivative and transient at amp {0.5, 1} x lag {0, 2}
#                    x seas_ml {0, 1}; mutate p after ccx_prepare().
#   P0d CONSERVATION closed system with the factor on, both fields.
#   P0e SIGN         SH peaks in January, NH in July; the factor MOVES the state.
#   P0f MUTATIONS    every guard by name; a flipped sigma_SH moves the phase 6 mo.
# =====================================================================
ps_par <- function(amp = 1, lag = 0, seas_ml = 1, field = "martin", export = 9.08) {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = seas_ml, pump_field = field)
  if (identical(field, "martin")) p$pump_export <- export
  p$pump_seas_amp <- amp; p$pump_seas_lag <- lag
  p
}
zero_forc_s <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)

test_that("the names ship OFF and are structural; no name prefixes another", {
  p <- ccx_default_params()
  expect_identical(p$pump_seas_amp, 0); expect_identical(p$pump_seas_lag, 0)
  expect_false("pump_seas_amp" %in% CCX_PARAM_NAMES); expect_false("pump_seas_lag" %in% CCX_PARAM_NAMES)
  # `aux$pump` is an EXACT element of aux (never of p), and p already carries
  # six `pump_*` names, so `$` partial matching on p is ambiguous and returns
  # NULL -- the trap cannot fire on `pump`; every other name is checked.
  nm <- c(names(ccx_default_params()), CCX_PARAM_NAMES, names(ccx_prepare(p)))
  for (new in c("pump_seas_amp", "pump_seas_lag")) {
    others <- setdiff(unique(nm), c(new, "pump"))
    expect_false(any(startsWith(others, new))); expect_false(any(startsWith(new, others)))
  }
})

test_that("P0a NO-OP: absent vs present-at-0 is BIT-EXACT in both cores; inert under seas_drivers 0", {
  p <- ps_par(amp = 0, lag = 2)
  q <- p; q$pump_seas_amp <- NULL; q$pump_seas_lag <- NULL
  a <- ccx_spinup(p); b <- ccx_spinup(q)
  expect_identical(a$y, b$y)
  F0 <- zero_forc_s(a$prod_c14, enso = 0.7)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux))
  # seas_drivers 0: amp 1 must emit nothing (the aseasonal spinup's contract)
  r <- p; r$pump_seas_amp <- 1; r$seas_drivers <- 0; s <- p; s$seas_drivers <- 0
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
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-pump-seas"))
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})

test_that("P0b ANNUAL MEAN and P0e SIGN: the factor integrates to 1 over a year; SH peaks in January, NH in July", {
  fac <- function(h, t, amp, lag) 1 + amp * (if (h == "NH") 1 else -1) * sin(2 * pi * (t - (3.5 + lag) / 12))
  tt <- 1900 + (0:11 + 0.5) / 12
  for (lag in c(-2, 0, 2)) for (h in HEMIS) expect_lt(abs(mean(fac(h, tt, 1, lag)) - 1), 1e-12)
  expect_equal(which.max(fac("SH", tt, 1, 0)), 1L)     # January
  expect_equal(which.max(fac("NH", tt, 1, 0)), 7L)     # July
  # the model applies exactly that factor: the pump's ML tendency at amp 1 vs 0, read off the derivative of an isolated pump
  p1 <- ps_par(amp = 1); p0 <- ps_par(amp = 0)
  sp <- ccx_spinup(p1)
  d_pump <- function(p, t) {   # the pump's contribution: derivative with the pump on minus with the pump off, ML C rows
    q <- p; q$pump_export <- 0; q$pump_hs_gcm2 <- 0
    aux0 <- ccx_prepare(q)
    dp <- ccx_deriv(sp$y, t, p, zero_forc_s(sp$prod_c14), sp$grid, sp$aux)
    d0 <- ccx_deriv(sp$y, t, q, zero_forc_s(sp$prod_c14), sp$grid, aux0)
    vapply(HEMIS, function(h) dp[sp$aux$idx[[h]]$ml, "C"] - d0[sp$aux$idx[[h]]$ml, "C"], numeric(1))
  }
  ratio <- sapply(tt, function(t) d_pump(p1, t) / d_pump(p0, t))
  for (h in HEMIS) expect_lt(max(abs(ratio[h, ] - fac(h, tt, 1, 0))), 1e-9)
  expect_lt(abs(mean(ratio["SH", ]) - 1), 1e-9)
})

test_that("P0c PARITY and P0d CONSERVATION at amp {0.5, 1} x lag {0, 2} x seas_ml {0, 1}, both fields; the factor MOVES the transient", {
  skip_if_no_cpp()
  for (field in c("martin", "solved")) for (seas in c(0, 1)) for (amp in c(0.5, 1)) for (lag in c(0, 2)) {
    p <- ps_par(amp = amp, lag = lag, seas_ml = seas, field = field)
    sp <- ccx_spinup(p)
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
    q <- p; q$pump_seas_amp <- 0
    expect_gt(max(abs(r$out$co2_SH - ccx_run_fast(ccx_spinup(q), F)$out$co2_SH)), 1e-4)
  }
  # the 09-09t class: aux built with amp 1, then p switched to 0 -- both cores obey p
  p <- ps_par(amp = 1, seas_ml = 1); sp <- ccx_spinup(p)
  q <- p; q$pump_seas_amp <- 0
  fr <- zero_forc_s(sp$prod_c14, enso = 0.3)
  dR <- ccx_deriv(sp$y, 1900.2, q, fr, sp$grid, sp$aux); dC <- ccx_deriv_fast(sp$y, 1900.2, q, fr, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)), 1e-9)
})

test_that("P0f MUTATIONS: every guard by name; a flipped SH sign moves the SH phase by six months", {
  p <- ps_par()
  q <- p; q$pump_seas_amp <- 1.2; expect_error(ccx_prepare(q), "pump_seas_amp")
  q <- p; q$pump_seas_amp <- -0.1; expect_error(ccx_prepare(q), "pump_seas_amp")
  q <- p; q$pump_seas_amp <- NA_real_; expect_error(ccx_prepare(q), "pump_seas_amp")
  q <- p; q$pump_seas_lag <- Inf; expect_error(ccx_prepare(q), "pump_seas_lag")
  # the sign convention has POWER: lag 6 on the SH is the NH's sign; a sign error would show as a 6-month phase shift.
  # Read the PUMP's seasonal anomaly (amp 1 minus amp 0), not the ML's whole derivative, which the seasonal ML dominates.
  sp <- ccx_spinup(p); tt <- 1900 + (0:11 + 0.5) / 12
  ml_c <- function(lag, amp = 1) { q <- p; q$pump_seas_lag <- lag; q$pump_seas_amp <- amp
    sapply(tt, function(t) ccx_deriv(sp$y, t, q, zero_forc_s(sp$prod_c14), sp$grid, sp$aux)[sp$aux$idx$SH$ml, "C"]) }
  base <- ml_c(0, amp = 0); a <- ml_c(0) - base; b <- ml_c(6) - base
  expect_equal(which.min(a), 1L)                        # the SH ML loses carbon fastest in January
  expect_equal(which.min(b), 7L)                        # ... and in July under a 6-month lag (= a flipped sign)
  expect_lt(abs(mean(a)), 1e-6 * max(abs(a)))           # zero-mean
})
