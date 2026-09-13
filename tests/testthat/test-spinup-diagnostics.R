# =====================================================================
# test-spinup-diagnostics.R -- the CONTRACT of the ONE diagnostics producer
# shared by the two spinups (2026-09-09x), and the INERTNESS of the two new
# `ccx_make_logpost()` arguments.
#
# WHY. `ccx_periodic_spinup()` used to inherit `ccx_spinup()`'s `$diagnostics`
# list and overwrite six of its nineteen fields; the other thirteen silently
# carried the ASEASONAL SEED's value, including `prod_c14_mol_yr`, which then
# CONTRADICTED the same object's `$prod_c14`. Both now route through
# `ccx_spinup_diagnostics()` ⇒ [[two_gates_one_mechanism]]. Every gate below is
# mutation-tested ⇒ [[mutation_test_gates]].
# =====================================================================

# FILE-LEVEL FIXTURES (review B4, 2026-09-12): the default aseasonal spinup was
# built in three blocks and the canonical objective evaluated in two.
sd_sp <- local({ s <- NULL; function() { if (is.null(s)) s <<- ccx_spinup(ccx_default_params()); s } })
sd_mode <- local({ m <- NULL; function() {
  # the nearest FREE registered mode (09-13 (d)): these tests are about the objective's
  # spinup default and by_stream, not the canonical, and a PINNED canonical's u_mode is
  # 30 long -- it would need its pins applied for every call this fixture memoises
  if (is.null(m)) { md <- readRDS(ccx_mode_file(ccx_mode_free_name())); base <- ccx_mode_base(md)
    m <<- list(md = md, base = base, u = md$u_mode,
               plain = ccx_make_logpost(base_params = base)(md$u_mode)) }
  m } })

test_that("ccx_spinup_diagnostics() REFUSES the estimator-dependent rows it cannot default", {
  sp <- sd_sp()
  ok <- list(C = 0, C13 = 0, C14 = 0)
  # the happy path first, so a refusal below cannot be the state's fault
  expect_type(ccx_spinup_diagnostics(sp$y, sp$prod_c14, sp$aux, sp$grid, ok, 277), "list")
  # residuals: a MISSING element must stop, not silently become NULL. The two
  # spinups do not share a definition of a residual, so there is no default.
  expect_error(ccx_spinup_diagnostics(sp$y, sp$prod_c14, sp$aux, sp$grid,
                                      list(C = 0, C13 = 0), 277), "residuals")
  # co2_ppm: no default, and not a vector or a non-finite
  expect_error(ccx_spinup_diagnostics(sp$y, sp$prod_c14, sp$aux, sp$grid, ok, c(1, 2)),
               "co2_ppm")
  expect_error(ccx_spinup_diagnostics(sp$y, sp$prod_c14, sp$aux, sp$grid, ok, NA_real_),
               "co2_ppm")
})

test_that("ccx_spinup() itself goes through the producer, and has not diverged from it", {
  sp <- sd_sp()
  d  <- sp$diagnostics
  # rebuild from the producer on the SAME state, passing back the two rows the
  # producer cannot know. Every OTHER row must match exactly, or ccx_spinup()
  # has grown a second definition of one of them.
  d2 <- ccx_spinup_diagnostics(
    sp$y, sp$prod_c14, sp$aux, sp$grid,
    residuals = list(C = d$max_abs_dCdt, C13 = d$max_abs_dC13dt, C14 = d$max_abs_dC14dt),
    co2_ppm   = d$co2_ppm)
  expect_setequal(names(d), names(d2))
  for (n in names(d)) expect_identical(d[[n]], d2[[n]], info = n)
  # MUTATION: a producer row that drifts must be caught, so the loop has power.
  d3 <- d2; d3$ocean_C_GtC <- d3$ocean_C_GtC * (1 + 1e-12)
  expect_false(identical(d$ocean_C_GtC, d3$ocean_C_GtC))
})

test_that("the PERIODIC spinup's diagnostics are its OWN, not the seed's", {
  # in R/ since adoption 09-09x; the bootstrap has already sourced it.
  p  <- ccx_default_params()
  sp_ase <- sd_sp()
  sp_per <- ccx_periodic_spinup(p, seed = sp_ase, verbose = FALSE)

  # the field SET must be identical, or the objective could read a row off one
  # spinup that the other does not carry.
  expect_setequal(names(sp_ase$diagnostics), names(sp_per$diagnostics))

  # PRECONDITION for the mutation below: the two solves must actually disagree
  # about production, else the check has nothing to separate and would pass
  # vacuously ⇒ [[no_power_null]].
  expect_false(identical(sp_ase$prod_c14, sp_per$prod_c14))

  # THE ROW THAT WAS STALE: production, which the periodic solve RE-SOLVES.
  expect_identical(sp_per$diagnostics$prod_c14_mol_yr, sp_per$prod_c14)
  expect_identical(sp_per$diagnostics$prod_ratio,
                   sp_per$prod_c14 / sp_per$diagnostics$prod_canonical)
  # MUTATION: the pre-fix inherit-and-overwrite form carried the SEED's value,
  # and that form must FAIL this check.
  expect_false(identical(sp_ase$diagnostics$prod_c14_mol_yr, sp_per$prod_c14))

  # ⛔ CONVERGENCE IS `resid_carbon`, NOT the state residual. `PS_TOL` is the
  # CARBON NEWTON's absolute tolerance and `resid_carbon` the residual of the
  # vector it drives (one row of which is the ANNUAL-MEAN PIN). `max_abs_dCdt` is
  # the raw one-period change with no pin substitution, so the atmosphere row's
  # own return is in it and is constrained only in annual mean -- it can exceed
  # PS_TOL on a fully converged solve, purely from floating point on a 4e+04 GtC
  # box. An earlier cut of this line asserted the absolute form and would have
  # ratified the guard bug that broke test-luc-scale.R
  # ⇒ [[verify_the_quantity_not_the_word]].
  expect_lt(sp_per$periodic$resid_carbon, PS_TOL)
  # and the state residual judged RELATIVE to the inventory it sits on. The bound
  # is DERIVED from two measured quantities, not chosen: PS_TOL / (carbon
  # inventory) is the relative floor the solver's own absolute tolerance implies
  # (1e-9 / 3.9e4 = 2.6e-14), and the one-year map adds ~12 months of RK4
  # accumulation on top, so 100x that floor is the bound and the measured value
  # is 3.5e-14 ⇒ [[threshold_from_obs_or_law]], [[tolerance_scaled_to_spread]].
  inv_C <- sum(abs(sp_per$y[, "C"]))
  rel_floor <- 100 * PS_TOL / inv_C
  expect_lt(sp_per$diagnostics$max_abs_dCdt / inv_C, rel_floor)
  # MUTATION: the bound must be able to fail, or it is decoration. ⚠ 1e3 was NOT
  # enough -- the measured relative residual sits ~1300x BELOW the floor, so a
  # 1000x mutation still passed and the first cut of this line was itself a
  # no-power assertion ⇒ [[no_power_null]]. Sized off the measured headroom.
  expect_gt(1e6 * sp_per$diagnostics$max_abs_dCdt / inv_C, rel_floor)
})

test_that("`spinup_fn` DEFAULTS to the PERIODIC spinup since adoption (09-09x)", {
  m <- sd_mode(); base <- m$base; u <- m$u
  # ⭐ THE ADOPTION ITSELF, asserted. Ruled by Marcus 09-09x; before that the
  # default was `ccx_spinup`. Naming the new default must be a no-op...
  plain <- m$plain
  named <- ccx_make_logpost(base_params = base, spinup_fn = ccx_periodic_spinup)(u)
  expect_identical(plain, named)
  # ...and the ASEASONAL spinup must give a DIFFERENT, still-reachable number, or
  # `spinup_fn` is not actually reaching the model and this gate has no power.
  ase <- ccx_make_logpost(base_params = base, spinup_fn = ccx_spinup)(u)
  expect_false(identical(as.numeric(plain), as.numeric(ase)))
  # a non-function must be refused rather than failing deep inside the closure
  expect_error(ccx_make_logpost(spinup_fn = "ccx_spinup"), "spinup_fn")
})

test_that("`by_stream` does not move the scalar, and its parts sum to the whole", {
  m <- sd_mode(); base <- m$base; u <- m$u; plain <- m$plain
  v     <- ccx_make_logpost(base_params = base, by_stream = TRUE)(u)
  expect_equal(as.numeric(v), as.numeric(plain), tolerance = 0)
  st <- attr(v, "streams")
  expect_true(length(st) > 1L)
  expect_equal(sum(st), attr(v, "loglik"), tolerance = 1e-10)
  expect_equal(attr(v, "loglik") + attr(v, "logprior"), as.numeric(v), tolerance = 1e-10)
})

test_that("THE NO-OP GATE THAT IS AVAILABLE: with NO seasonality the two spinups agree", {
  # ⛔ THERE IS NO "BIT-IDENTICAL AT `seas_ml` = 0" GATE AND THERE CANNOT BE.
  # `ccx_spinup()` zeroes FOUR seasonal paths in its `p0` (`seas_amp_NH`,
  # `seas_amp_SH`, `seas_drivers`, `seas_ml`), so at `seas_ml` = 0 alone the model
  # still has a full seasonal cycle to rectify and the aseasonal state is still
  # not a point on the orbit ⇒ [[verify_the_quantity_not_the_word]]. The gate that
  # IS available is the one with ALL FOUR off: no seasonality, so the one-year
  # map's fixed point and the instantaneous fixed point are THE SAME STATE. An
  # IDENTITY at the solver's own tolerance, not an invented bound
  # ⇒ [[threshold_from_obs_or_law]].
  p <- ccx_default_params()
  p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0; p$seas_ml <- 0
  sp_ase <- ccx_spinup(p)
  sp_per <- ccx_periodic_spinup(p, seed = sp_ase)
  expect_lt(max(abs(sp_per$y - sp_ase$y)), 1e-6)
  expect_equal(sp_per$prod_c14, sp_ase$prod_c14, tolerance = 1e-9)

  # MUTATION: turn ONE seasonal path back on and the agreement must BREAK, or the
  # gate would pass on a model that ignored `seas_drivers` entirely
  # ⇒ [[mutation_test_gates]], [[no_power_null]].
  q <- p; q$seas_drivers <- 1
  sq_ase <- ccx_spinup(q)
  sq_per <- ccx_periodic_spinup(q, seed = sq_ase)
  expect_gt(max(abs(sq_per$y - sq_ase$y)), 1e-6)
})
