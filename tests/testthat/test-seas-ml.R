# =====================================================================
# ROUND 6 -- the SEASONAL MIXED LAYER (option A, ruled by Marcus 2026-09-09h).
#
# The mixed layer deepens and shoals on the Holte MLD climatology and ENTRAINS
# REAL WATER: carbon and both isotopes, at the source box's own ratio. This is
# what the retired pCO2-side `ent_seas_amp_SH` shim could NOT do -- it moved no
# carbon, so add_flux read the ML's unmodified signature and the mechanism had
# no isotopic signature in either isotope.
#
# ⚠ THE MECHANISM IS DEFAULTED OFF, so every test here sets `seas_ml = 1`
# EXPLICITLY. A mechanism defaulted off is untested where it matters.
# =====================================================================

closed_forcing_ml <- function() {
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
}

seas_ml_state <- function(h_ml = 49.153, seas_ml = 1) {
  p <- ccx_default_params()
  p$h_ml        <- h_ml
  p$seas_drivers <- 1
  p$seas_ml     <- seas_ml
  p <- ccx_set_enso(p, list(gamma_enso = 0))
  aux <- ccx_prepare(p)
  y   <- ccx_new_state()
  grid <- aux$grid
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- 300; y[i$leaf, "C"] <- 30; y[i$wood, "C"] <- 220
    y[i$soil_fast, "C"] <- 100; y[i$soil_slow, "C"] <- 600
    y[i$ml, "C"] <- 400
    y[i$oc, "C"] <- 1500 * grid$dz[-1] / sum(grid$dz[-1])
  }
  # A DELIBERATE vertical contrast, so entrainment has something to carry and a
  # sign error cannot hide behind a uniform column.
  for (h in HEMIS) y[aux$idx[[h]]$oc[1], "C"] <- y[aux$idx[[h]]$oc[1], "C"] * 1.25
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB")
  y[, "C14"] <- y[, "C"] * 1.0
  # layer 1 is isotopically LIGHT and 14C-DEPLETED, as the real subsurface is
  for (h in HEMIS) {
    i1 <- aux$idx[[h]]$oc[1]
    y[i1, "C13"] <- y[i1, "C"] * ccx_const("R13_VPDB") * 0.995
    y[i1, "C14"] <- y[i1, "C"] * 0.90
  }
  list(y = y, p = p, aux = aux, grid = grid)
}

# ---------------------------------------------------------------------
# 1. THE SHAPE: mean-preserving, and it is the OBSERVED cycle
# ---------------------------------------------------------------------
test_that("the seasonal shape has annual mean exactly 1 and the observed phases", {
  co <- ccx_mld_shape()
  for (h in HEMIS) {
    expect_equal(mean(co[[h]]$f_month), 1, tolerance = 1e-12)
    # the CONTINUOUS mean too, not merely the mean of the 12 samples: the ruling
    # is about the annual mean the model actually integrates
    tt <- seq(0, 1, length.out = 4001)[-4001]
    f  <- vapply(tt, function(t) ccx_mld_eval(co[[h]], t)$f, numeric(1))
    expect_equal(mean(f), 1, tolerance = 1e-8)
  }
  # NH deepest in February, SH in August -- ANTIPHASE, which is the whole reason
  # the per-hemisphere geometry may not leak across the deriv's loop iterations.
  expect_equal(which.max(ccx_mld_shape()$NH$f_month), 2L)
  expect_equal(which.max(ccx_mld_shape()$SH$f_month), 8L)
})

test_that("the Fourier series reproduces the monthly climatology to roundoff", {
  # Not a 1-2 harmonic fit: we have the real data, so we interpolate it. If the
  # Nyquist term were double-counted this would read ~2e-3, which would show up
  # downstream only as a spurious sub-monthly wiggle in dh/dt.
  for (h in HEMIS) {
    co  <- ccx_mld_shape()[[h]]
    tau <- (seq_len(12) - 0.5) / 12
    rec <- vapply(tau, function(t) ccx_mld_eval(co, t)$f, numeric(1))
    expect_lt(max(abs(rec - co$f_month)), 1e-12)
  }
})

test_that("dh/dt is periodic and integrates to zero over a year", {
  # A mixed layer that did not return to its own depth each year would be a
  # slow pump, not a seasonal cycle.
  for (h in HEMIS) {
    co <- ccx_mld_shape()[[h]]
    tt <- seq(0, 1, length.out = 20001)[-20001]
    expect_lt(abs(mean(vapply(tt, function(t) ccx_mld_eval(co, t)$dfdt, numeric(1)))), 1e-10)
    expect_equal(ccx_mld_eval(co, 0)$f, ccx_mld_eval(co, 1)$f, tolerance = 1e-12)
  }
})

# ---------------------------------------------------------------------
# 2. GEOMETRY: layer 1 absorbs the excursion, and dz_mid[1] is invariant
# ---------------------------------------------------------------------
test_that("moving the ML base conserves dz_ML + dz_1 and leaves the interior alone", {
  g  <- ccx_ocean_grid(49.153)
  g2 <- ccx_grid_at_h_ml(g, 82.7)
  expect_equal(g2$dz[1], 82.7)
  expect_equal(sum(g2$dz[1:2]), sum(g$dz[1:2]))          # conserved BY CONSTRUCTION
  expect_equal(g2$dz[-(1:2)], g$dz[-(1:2)])              # the interior does NOT move
  expect_equal(sum(g2$dz), sum(g$dz))                    # total depth unchanged
  # dz_mid[1] invariant, dz_mid[2] not -- the asymmetry the deriv relies on
  dzm  <- (g$dz[-length(g$dz)]  + g$dz[-1])  / 2
  dzm2 <- (g2$dz[-length(g2$dz)] + g2$dz[-1]) / 2
  expect_equal(dzm2[1], dzm[1])
  expect_false(isTRUE(all.equal(dzm2[2], dzm[2])))
})

# ---------------------------------------------------------------------
# 3. THE P8 GUARD -- MUTATION-TESTED: break what it guards, confirm it fails
# ---------------------------------------------------------------------
test_that("the P8 geometry guard passes at the canonical and FIRES past the bound", {
  p <- ccx_default_params(); p$seas_drivers <- 1; p$seas_ml <- 1
  p$h_ml <- 49.153
  expect_silent(invisible(ccx_prepare(p)))               # canonical: 27 m of margin
  # THE MUTATION: ent26 sat at 134.15 m, so this is a state the fitter can reach.
  p$h_ml <- 90
  expect_error(ccx_prepare(p), "winter mixed layer reaches")
  p$h_ml <- 134.15
  expect_error(ccx_prepare(p), "single-layer\\s+entrainment is INVALID")
  # and the guard must NOT fire when the mechanism is off, at any depth
  p$seas_ml <- 0
  expect_silent(invisible(ccx_prepare(p)))
})

# ---------------------------------------------------------------------
# 4. CONSERVATION -- the assertion the prereg asks for
# ---------------------------------------------------------------------
test_that("entrainment conserves C and C13 exactly, at every phase of the year", {
  s <- seas_ml_state()
  # sampled ACROSS the year: entrainment and detrainment are different limbs
  # drawing from different boxes, so one phase passing proves nothing about the
  # other. This is the 2026-08-25e seasonal-NEP lesson as a test.
  #
  # ⚠ C14 IS DELIBERATELY NOT ASSERTED HERE, and that is not a weakened test.
  # Total 14C has a non-zero derivative in ANY closed configuration because it
  # DECAYS -- test-conservation.R asserts C and C13 for the same reason. MEASURED
  # rather than assumed: the same imbalance is 1.2e-4 at seas_ml = 0 and 5.3e-5
  # at seas_ml = 1, i.e. it is the decay term and the seasonal mixed layer does
  # not add to it. ⛔ Do NOT "fix" a future failure here by adding C14 back.
  # That the entrainment limbs carry 14C CORRECTLY is asserted below, by testing
  # the direction the ML's 14C RATIO moves.
  for (t in seq(1900, 1900.99, by = 1 / 24)) {
    d <- ccx_deriv(s$y, t, s$p, closed_forcing_ml(), s$grid, s$aux)
    for (col in c("C", "C13"))
      expect_lt(abs(sum(d[, col])) / max(abs(d[, col])), 1e-12)
  }
})

test_that("a full entrain-detrain year returns the ML to its own thickness", {
  co <- ccx_mld_shape()$NH
  expect_equal(ccx_mld_eval(co, 1900)$f, ccx_mld_eval(co, 1901)$f, tolerance = 1e-12)
})

# ---------------------------------------------------------------------
# 5. THE MECHANISM ACTUALLY DOES SOMETHING (and nothing when off)
# ---------------------------------------------------------------------
test_that("seas_ml = 0 leaves the derivative bit-identical to the pre-round-6 model", {
  s_off <- seas_ml_state(seas_ml = 0)
  d_off <- ccx_deriv(s_off$y, 1900.3, s_off$p, closed_forcing_ml(), s_off$grid, s_off$aux)
  p_bare <- s_off$p; p_bare$seas_ml <- NULL      # a pre-round-6 parameter list
  aux_bare <- ccx_prepare(p_bare)
  d_bare <- ccx_deriv(s_off$y, 1900.3, p_bare, closed_forcing_ml(),
                      aux_bare$grid, aux_bare)
  expect_identical(d_off, d_bare)
})

test_that("seas_ml = 1 CHANGES the mixed layer's tendency -- it is not a silent no-op", {
  # ⚠ The point of [[default_off_hides_the_bug]]: a mechanism that is off by
  # default must be shown to bite when turned on, at an EXPLICIT non-zero value.
  s_on  <- seas_ml_state(seas_ml = 1)
  s_off <- seas_ml_state(seas_ml = 0)
  # February: the NH mixed layer is at its deepest and entraining hardest.
  t_feb <- 1900 + 1.5 / 12
  d_on  <- ccx_deriv(s_on$y,  t_feb, s_on$p,  closed_forcing_ml(), s_on$grid,  s_on$aux)
  d_off <- ccx_deriv(s_off$y, t_feb, s_off$p, closed_forcing_ml(), s_off$grid, s_off$aux)
  i_ml <- s_on$aux$idx$NH$ml
  expect_false(isTRUE(all.equal(d_on[i_ml, "C"], d_off[i_ml, "C"])))
  # and it must move BOTH isotopes, which is the whole reason option A was ruled
  # over the pCO2-side shim
  expect_false(isTRUE(all.equal(d_on[i_ml, "C13"], d_off[i_ml, "C13"])))
  expect_false(isTRUE(all.equal(d_on[i_ml, "C14"], d_off[i_ml, "C14"])))
})

test_that("entrainment carries the SOURCE box's signature, in the right direction", {
  # ⚠ THIS MUST BE MEASURED ON THE ENTRAINMENT LIMB ALONE. The mixed layer's
  # TOTAL 13C tendency is dominated by air-sea exchange and the biological pump,
  # both of which move the ratio far harder than entrainment does -- a first
  # version of this test read the total and came out +0.13, i.e. it was measuring
  # the pump, not the mechanism. So every competing ocean flux is switched OFF
  # here and only the seasonal limbs remain.
  s <- seas_ml_state(seas_ml = 1)
  q <- s$p
  q$kz <- 0; q$w_up <- 0; q$w_out_NH <- 0; q$w_out_SH <- 0
  q$k_w <- 0                      # no air-sea exchange
  q$pump_grad <- 0                # no biological pump
  q$tau_q <- Inf                  # no conveyor limb into the ML
  aux <- ccx_prepare(q); grid <- aux$grid
  i_ml <- aux$idx$NH$ml; i_o1 <- aux$idx$NH$oc[1]

  co <- ccx_mld_shape()$NH
  t_deepen <- 1900 + 0.5 / 12                       # January: still deepening
  expect_gt(ccx_mld_eval(co, t_deepen)$dfdt, 0)     # the premise, asserted
  d <- ccx_deriv(s$y, t_deepen, q, closed_forcing_ml(), grid, aux)

  # The ML must GAIN carbon while deepening ...
  expect_gt(d[i_ml, "C"], 0)
  # ... and be pulled TOWARDS layer 1's signature: lighter in 13C, older in 14C.
  # d(13C)/dt - r_ml * d(C)/dt < 0  <=>  the ML's RATIO is falling. A signed-flux
  # bug reading the wrong source box would move it the other way.
  r13_ml <- s$y[i_ml, "C13"] / s$y[i_ml, "C"]
  r13_o1 <- s$y[i_o1, "C13"] / s$y[i_o1, "C"]
  expect_lt(r13_o1, r13_ml)                         # layer 1 IS the lighter box
  expect_lt(d[i_ml, "C13"] - r13_ml * d[i_ml, "C"], 0)
  r14_ml <- s$y[i_ml, "C14"] / s$y[i_ml, "C"]
  expect_lt(d[i_ml, "C14"] - r14_ml * d[i_ml, "C"], 0)

  # And the DETRAINING half-year must run the other way: the ML sheds its own
  # water, so its ratio is NOT pulled toward layer 1.
  t_shoal <- 1900 + 5.5 / 12
  expect_lt(ccx_mld_eval(co, t_shoal)$dfdt, 0)
  d2 <- ccx_deriv(s$y, t_shoal, q, closed_forcing_ml(), grid, aux)
  expect_lt(d2[i_ml, "C"], 0)
  expect_equal(d2[i_ml, "C13"] - r13_ml * d2[i_ml, "C"], 0, tolerance = 1e-10)
})
