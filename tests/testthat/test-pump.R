# =====================================================================
# THE BIOLOGICAL PUMP (task 9, ported 2026-08-16 from calibration/pump_shim.R)
#
# The pump is the first mechanism in this model that makes the ocean interior
# NON-UNIFORM on purpose, so most of what these tests assert is the boundary
# between "off" and "on": off must be bit-reproduced, and on must deliver
# exactly the gradient it was asked for.
# =====================================================================

test_that("the pump SHIPS ON, at the observed gradient", {
  # Marcus 2026-08-16d, on calibration/diag_pump_grad_profile.R and
  # diag_pump_kz_degeneracy.R. Held as a test because it is a DECISION, not an
  # implementation detail: the default was 0 from the port until that call, and
  # a silent revert would change every result in the repo without changing a
  # line of model code.
  #
  # AND THE DEFAULT IS THE OBSERVATION, NOT THE FIT. The four-row objective
  # prefers ~274.5 at the pre-gradient mode, but that optimum is conditional on
  # a `kz` the refit will move; `PUMP_GRAD_OBS` is GLODAP's own gradient and
  # survives a refit. Asserting the tie to the constant is what stops the fit
  # from being laundered in here as a structural default.
  p <- ccx_default_params()
  expect_gt(p$pump_grad, 0)
  expect_identical(p$pump_grad, ccx_const("PUMP_GRAD_OBS"))
  expect_false(is.null(ccx_prepare(p)$pump))
})

test_that("pump_grad = 0 emits NOTHING -- the no-pump model is bit-reproduced", {
  skip_if_no_cpp()
  # NOT "small". The guard is `is.null(aux$pump)`, so with the pump off not one
  # line of pump code runs and the derivative is the same object it was before
  # the port. Same contract w_up = 0 carries.
  #
  # RE-EXPRESSED 2026-08-16e, WITHOUT WEAKENING WHAT IT ASSERTS. This read
  # `expect_equal(ccx_default_params()$pump_grad, 0)` and so tested the DEFAULT
  # rather than the property named in its own title; when the pump shipped ON it
  # failed for a reason that has nothing to do with bit-reproduction. The
  # default is now asserted deliberately in the test above, and the property is
  # tested by setting `pump_grad` explicitly -- and STRENGTHENED, because
  # "bit-reproduced" is now measured against a parameter list carrying no
  # `pump_grad` at all (the pre-port model), not merely inferred from the guard.
  p0 <- ccx_default_params(); p0$pump_grad <- 0
  expect_null(ccx_prepare(p0)$pump)
  p_on <- p0; p_on$pump_grad <- 100
  expect_false(is.null(ccx_prepare(p_on)$pump))

  # the pre-port model: no `pump_grad` in the list at all
  p_pre <- p0; p_pre$pump_grad <- NULL
  expect_null(ccx_prepare(p_pre)$pump)
  s0 <- ccx_spinup(p0); s_pre <- ccx_spinup(p_pre)
  expect_equal(s0$y, s_pre$y, tolerance = 0)
  F <- ccx_build_forcing("historical", c(1900, 1960), prod_c14 = s0$prod_c14)
  expect_equal(as.matrix(ccx_run_fast(s0, F)$out),
               as.matrix(ccx_run_fast(s_pre, F)$out), tolerance = 0)
})

test_that("the pump delivers EXACTLY the gradient it was asked for", {
  skip_if_no_cpp()
  # THE CONTRACT ON `pump_grad`: it is the model's preindustrial
  # bottom-box-minus-mixed-layer DIC gradient in umol/kg, directly comparable
  # with the target the likelihood scores. It is NOT "roughly the observed
  # shape scaled" -- the shape is re-normalised on each grid's own layers,
  # because a model layer averages several observed bins and the bottom layer's
  # mean shape is 1.011, not 1. Without that step a pump_grad of 233.1 lands at
  # 235.7, and the h_ml dependence would be invisible.
  for (h in c(85, 100, 120)) {
    for (want in c(120, 233.109, 280.2)) {
      p <- ccx_default_params(); p$h_ml <- h; p$pump_grad <- want
      sp <- ccx_spinup(p); aux <- sp$aux; grid <- sp$grid
      got <- vapply(HEMIS, function(hh) {
        d <- sp$y[c(aux$idx[[hh]]$ml, aux$idx[[hh]]$oc), "C"] * aux$mol_per_GtC /
               (aux$a_oc[[hh]] * grid$dz * ccx_const("RHO_SEAWATER")) * 1e6
        d[length(d)] - d[1]
      }, numeric(1))
      expect_equal(unname(got), rep(want, 2), tolerance = 1e-6)
    }
  }
})

test_that("the spinup with a pump is still an exact fixed point", {
  skip_if_no_cpp()
  # The analytic equilibrium is a UNIFORM column, which the pump destroys on
  # purpose, so ccx_spinup() has to fall through to the full-state Newton solve.
  # If that gate ever stops firing the spinup silently returns a state that is
  # not a fixed point and every transient starts with a step change.
  p <- ccx_default_params(); p$h_ml <- 100; p$pump_grad <- 233.109
  sp <- ccx_spinup(p)
  expect_lt(sp$diagnostics$max_abs_dCdt, 1e-6)
  expect_lt(sp$diagnostics$max_abs_dC13dt, 1e-6)
  expect_lt(sp$diagnostics$max_abs_dC14dt, 1e-6)
})

test_that("R and C++ agree with the pump on, in BOTH export modes", {
  skip_if_no_cpp()
  for (md in c("N", "D")) {
    p <- ccx_default_params(); p$h_ml <- 100; p$pump_grad <- 233.109; p$pump_mode <- md
    sp <- ccx_spinup(p)
    F  <- ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sp$prod_c14)
    fa <- ccx_forcing_at(F, 60)
    dR <- ccx_deriv(sp$y, 1755, p, fa, sp$grid, sp$aux)
    dC <- ccx_deriv_fast(sp$y, 1755, p, fa, sp$grid, sp$aux)
    expect_equal(max(abs(dR - dC)), 0, tolerance = 1e-12)
    # ...and the two modes must not be the same model, or the parity check above
    # is vacuous. WHERE that is asserted matters, and getting it wrong is how
    # this test first failed: at the PREINDUSTRIAL state the mixed layer holds
    # exactly `ml_C0`, so the DIC-limited scaling is 1 and the two modes are
    # IDENTICAL by construction. They diverge only once the mixed layer is
    # loaded -- which is the whole mechanism. So assert both halves.
    if (md == "D") {
      pN <- p; pN$pump_mode <- "N"
      at <- function(y) as.numeric(ccx_deriv(y, 1755, p, fa, sp$grid, sp$aux) -
                                     ccx_deriv(y, 1755, pN, fa, sp$grid, sp$aux))
      # Preindustrial: the SAME model -- but to the SPINUP's tolerance, not to
      # machine precision. The pump makes the column non-uniform, so the spinup
      # falls through to the Newton solve, which lands the mixed layer on
      # `ml_C0` to ~1e-7 GtC rather than exactly. The DIC-limited scaling is
      # therefore 1 + O(1e-11), not 1. Asserting exact equality here failed at
      # 1.8e-10 -- a solver residual, not a wiring difference.
      expect_lt(max(abs(at(sp$y))), 1e-8)                      # preindustrial: same
      loaded <- sp$y
      for (hh in HEMIS) loaded[sp$aux$idx[[hh]]$ml, "C"] <-
        loaded[sp$aux$idx[[hh]]$ml, "C"] * 1.03
      expect_gt(max(abs(at(loaded))), 1e-3)                    # loaded: different
    }
  }
})

test_that("a constant-mass pump adds EXACTLY ZERO uptake", {
  skip_if_no_cpp()
  # THE PRE-REGISTERED PROPERTY from calibration/diag_dic_gradient.R part 3, now
  # a standing gate on the ported code. The interior is a passive tracer and the
  # diffusion operator is linear, so a STATIC background profile superposes on
  # the anthropogenic perturbation and cannot change how it propagates. Mode N
  # must therefore leave the ocean sink untouched; mode D is the only channel
  # that can move it, and is asserted to actually do so.
  base <- ccx_default_params(); base$h_ml <- 100
  sink <- function(p) {
    sp <- ccx_spinup(p)
    F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
    o  <- ccx_run_fast(sp, F)$out
    yr <- floor(o$t + 1e-9); ann <- tapply(o$ocean_C, yr, mean)
    yy <- as.integer(names(ann)); k <- which(yy >= 2010 & yy <= 2019)
    mean(diff(ann[k]))
  }
  off <- sink(base)
  pN <- base; pN$pump_grad <- 233.109; pN$pump_mode <- "N"
  pD <- base; pD$pump_grad <- 233.109; pD$pump_mode <- "D"
  expect_equal(sink(pN), off, tolerance = 1e-6)
  expect_gt(abs(sink(pD) - off), 1e-3)
})

test_that("the pump moves the three gradient rows, and the alkalinity row is read off the run", {
  skip_if_no_cpp()
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg) || is.null(tg$alk), "GLODAPv2 gradient block absent")
  p <- ccx_default_params(); p$h_ml <- 100; p$pump_grad <- 233.109
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  og <- ccx_ocean_grad_scored(ccx_run_fast(sp, F)$out, sp)
  expect_false(is.null(og))
  # THE ALKALINITY ROW IS NO LONGER A CONSTANT. It is read from the SAME export
  # field the derivative integrated, so it cannot be scored against a pump the
  # run did not use.
  expect_gt(og$alk, 0)
  # ...and the carbonate share that the alkalinity gradient itself implied must
  # bring the row close to its target. 0.5 sigma is deliberately loose: the
  # inference used the total gradient while the model splits one shape.
  expect_lt(abs(og$alk - tg$alk$target) / tg$alk$sd, 0.5)
  # d13C must go NEGATIVE -- the organic limb dominates it
  expect_lt(og$d13c, 0)
})
