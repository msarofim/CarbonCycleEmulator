# =====================================================================
# THE HS BOX'S SHARE OF ITS HEMISPHERE'S SST ANOMALY (DESIGN §3.4a T; RULED 2026-10-05, Marcus "Yes, test";
# CHANGELOG 10-05): SST_hs = sst_hs + frac x (the anomaly), frac = hs_sst_anom_frac, ABSENT = 1. The H1
# diagnostic of the ocean thermal effect (10-04 p). Not fitted, in no label.
#   T1 ABSENT = 1   bit-identical state and outputs in both cores; the canonical's stored likelihood
#                   reproduces row by row with the name absent AND at 1
#   T2 SPINUP       the periodic spinup is bit-identical at frac 0 and 1 (its anomaly is 0)
#   T3 PARITY       R vs C++ at frac 1/2: the derivative to 5e-14 and a short transient; the name is LIVE
#   T4 DIRECTION    frac 0 holds the HS box at its climatology: in a warm decade its pCO2 is lower and the
#                   ocean takes up MORE, monotonically in frac; the low-latitude box's derivative is untouched
#   T5 REFUSALS     negative, NA, a vector
# Mutations M1-M5 (CHANGELOG 10-05) are each caught by their own test.
# =====================================================================
hf_canon <- local({ cache <- NULL; function() {
  if (!is.null(cache)) return(cache)
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md)); attr(pm, "migrated_done") <- TRUE
  p  <- ccx_overlay_par(bp, pm)
  cache <<- list(md = md, p = p, spin = ccx_spinup_from_label(ccx_mode_spinup(md)))
  cache } })
hf_with <- function(p, f) { p$hs_sst_anom_frac <- f; p }
# a warm window opening mid-record, carried the way a continuation would (test-mixing-strat S5's idiom)
hf_forcing <- function(p, sp, yrs = c(1996, 1999)) {
  # the mid-record window's land-use start-up warning is expected here and muffled by its own words only
  withCallingHandlers(ccx_build_forcing("historical", yrs, prod_c14 = sp$prod_c14,
                                        enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)),
                      warning = function(w) if (grepl("Expect a start-up transient", conditionMessage(w))) invokeRestart("muffleWarning")) }

test_that("T1 ABSENT = 1: bit-identical in both cores, and the canonical's stored likelihood reproduces (absent and at 1)", {
  skip_if_no_cpp()
  C <- hf_canon(); p0 <- C$p; expect_null(p0[["hs_sst_anom_frac"]]); p1 <- hf_with(p0, 1)
  s0 <- C$spin(p0); s0$enso_hist <- "hold"; F <- hf_forcing(p0, s0)
  rA <- ccx_run_fast(s0, F)
  s1 <- C$spin(p1); s1$enso_hist <- "hold"; rC <- ccx_run_fast(s1, F)
  expect_identical(rC$state, rA$state); expect_identical(rC$out, rA$out)
  rRA <- suppressWarnings(ccx_run(s0, F)); rRC <- suppressWarnings(ccx_run(s1, F))
  expect_identical(rRC$state, rRA$state)
  md <- C$md
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  g <- ccx_apply_gate(ccx_mode_struct(md)); rp <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rp); ccx_unapply_gate(g) }, add = TRUE)
  u <- ccx_par_to_unc(ccx_mode_par_with_pins(md))
  for (b in list(bp, hf_with(bp, 1))) {
    sc <- ccx_make_logpost(base_params = b, by_stream = TRUE, spinup_fn = C$spin)(u)
    expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
  }
})

test_that("T2 SPINUP: the periodic spinup is bit-identical at frac 0 and 1 (the spinup's anomaly is 0)", {
  skip_if_no_cpp()
  C <- hf_canon()
  expect_identical(C$spin(hf_with(C$p, 0))$y, C$spin(C$p)$y)
})

test_that("T3 PARITY: R vs C++ at frac 1/2 -- the derivative to 5e-14 and a short transient; the name is LIVE", {
  skip_if_no_cpp()
  C <- hf_canon(); p5 <- hf_with(C$p, 0.5)
  s5 <- C$spin(p5); s5$enso_hist <- "hold"; F <- hf_forcing(p5, s5)
  Fp <- F; Fp$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(p5), "hold")
  for (i in c(1L, 30L)) { fr <- ccx_forcing_at(Fp, i)
    dR <- ccx_deriv(s5$y, F$t[i], p5, fr, s5$grid, s5$aux)
    dC <- ccx_deriv_fast(s5$y, F$t[i], p5, fr, s5$grid, s5$aux)
    expect_lt(max(abs(dR - dC)) / max(abs(dR)), 5e-14)                 # test-parity.R's PARITY_REL_TOL
    expect_false(identical(ccx_deriv(s5$y, F$t[i], C$p, fr, s5$grid, s5$aux), dR)) }   # the name is read
  r <- ccx_run_fast(s5, F); rR <- suppressWarnings(ccx_run(s5, F))
  expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
})

test_that("T4 DIRECTION: frac 0 holds the HS box at climatology -- lower pCO2, MORE uptake, monotone; the low-latitude box untouched", {
  skip_if_no_cpp()
  C <- hf_canon(); s <- C$spin(C$p); s$enso_hist <- "hold"; F <- hf_forcing(C$p, s)
  run_f <- function(f) { sf <- s; sf$params <- hf_with(C$p, f); ccx_run_fast(sf, F) }
  fr <- c(0, 0.5, 1); R <- lapply(fr, run_f)
  oc_end <- vapply(R, function(r) utils::tail(r$out$ocean_C, 1), 0)
  expect_true(all(diff(oc_end) < 0))                                    # more warmth on the HS box, less uptake
  pco2 <- vapply(R, function(r) mean(r$out$hs_pco2_NH + r$out$hs_pco2_SH), 0)
  expect_true(all(diff(pco2) > 0))
  # the derivative at ONE state: frac moves the HS box, never the low-latitude mixed layer
  Fp <- F; Fp$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(C$p), "hold"); frow <- ccx_forcing_at(Fp, 30L)
  d1 <- ccx_deriv_fast(s$y, F$t[30], C$p, frow, s$grid, s$aux)
  d0 <- ccx_deriv_fast(s$y, F$t[30], hf_with(C$p, 0), frow, s$grid, s$aux)
  for (h in c("NH", "SH")) {
    expect_identical(d0[s$aux$idx[[h]]$ml, ], d1[s$aux$idx[[h]]$ml, ])
    expect_gt(abs(d0[s$aux$idx[[h]]$hs, "C"] - d1[s$aux$idx[[h]]$hs, "C"]), 1e-6)
  }
})

test_that("T5 REFUSALS: a negative, NA or vector frac is refused by name; absent is 1", {
  expect_identical(ccx_hs_sst_frac(list()), 1)
  expect_identical(ccx_hs_sst_frac(list(hs_sst_anom_frac = 0)), 0)
  for (bad in list(-0.1, NA_real_, c(1, 0.5), Inf))
    expect_error(ccx_hs_sst_frac(list(hs_sst_anom_frac = bad)), "hs_sst_anom_frac")
})
