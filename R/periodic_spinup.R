# =====================================================================
# periodic_spinup.R -- a PERIODIC (limit-cycle) spinup: the state y* with
#   Phi(y*) = y*,   Phi = the model's ONE-YEAR flow map,
# as against `ccx_spinup()`'s ASEASONAL fixed point, which solves dy/dt = 0 at a
# SINGLE instant with every seasonal driver switched off.
#
# WHY IT IS OWED (ruled by Marcus, 2026-09-09w). Review lead F2, confirmed
# 09-09v by `calibration/diag_f2_periodic_spinup.R`: started from the aseasonal
# spinup with the seasonal mixed layer ON, a QUIET preindustrial run jumps
# +19.94 ppm at 1750 and settles to a RECTIFIED LEVEL OFFSET of +2.45 ppm, flat
# within 0.07 ppm for 480 years, against a +0.021 ppm noise floor on the
# seas_ml = 0 arm -- a ratio of 855. The aseasonal state is therefore NOT a
# point on the seasonal orbit, 09-09j/k's "no periodic spinup is needed" is
# reversed, and a 20 ppm preindustrial shock is a defect in a PEDAGOGICAL model
# on its own terms ⇒ [[ccx_pedagogical_not_emulator]], [[ccx_f2_periodic_spinup_owed]].
#
# ⛔⛔ WHAT IS NOT ASSUMED HERE. Whether the limit cycle REMOVES that +2.45 ppm
# or merely RELOCATES it is the open question, and it is open in BOTH
# directions: the spinup PINS atmospheric CO2 at `CO2_PI_PPM`, so a periodic
# solve may absorb the offset into the OCEAN state instead of leaving it in the
# air. This file solves; `calibration/diag_periodic_spinup.R` measures. Nothing
# here prices round 6.
#
# ---- THE CONSTRUCTION, and why it is three solves and not one ---------
# 12C carries the nonlinearity (carbonate chemistry, the `f(t)` mixed layer), so
# it is shot with a Newton on the full carbon vector. Given that carbon orbit,
# BOTH isotopes enter the derivative LINEARLY -- and 12C's evolution does not
# depend on them -- so their one-year maps are AFFINE and are built exactly, one
# column per box, rather than iterated. That is the same split `ccx_spinup()`
# already makes (`iso_operator()`, R/spinup.R:246-256); the only change is that
# the operator is the MONODROMY matrix of the one-year map rather than the
# instantaneous Jacobian.
#
# ⚠ THE PINS ARE THE SAME PINS, moved from an instant to an annual mean:
#   12C   the ANNUAL-MEAN global atmospheric carbon = chi0's target. ⛔ NOT the
#         start-of-year value -- on a limit cycle those differ by the seasonal
#         amplitude, and pinning the instant would silently redefine chi0 as "CO2
#         in January" ⇒ [[verify_the_quantity_not_the_word]].
#   13C   the ANNUAL-MEAN atmospheric d13C, on the same grounds (the map is
#         singular without it: 13C is conserved).
#   14C   production solved to hit the ANNUAL-MEAN atmospheric Delta14C.
# ⛔ UNTIL 2026-09-12 ONLY THE 12C PIN WAS THE MEAN: the 13C row pinned the
# START-OF-PERIOD NH atmospheric 13C and the 14C scale the start-of-period
# total, so the preindustrial d13C level the level rows inherit was the JANUARY
# value (-6.4690 = D13C_PI at the instant, annual mean -6.4436, +0.025 permil
# at hilda31s). RULED (Marcus) and fixed: both isotope pins are now the annual
# mean of the atmospheric tracer over the 12 monthly rows of the orbit --
# affine in the initial isotope vector given the fixed carbon orbit, so the
# monodromy columns carry their year-means (`Mbar`, `bbar`) at no extra cost;
# 14C needs ONE extra one-year run (the unit-production orbit's mean).
#
# ⚠ `aux` IS PREPARED FROM THE SAME `p` THAT IS INTEGRATED. `ccx_spinup()`
# builds `aux` from `p` and then integrates with a mutated `p0`, which is the
# 09-09t leak's whole mechanism ⇒ [[two_gates_one_mechanism]]. Nothing is
# mutated here: one parameter list, one `ccx_prepare()`, one gate.
#
# ⭐⭐ PROMOTED INTO `R/` AND **ADOPTED AS THE OBJECTIVE'S SPINUP**, 2026-09-09x,
# ruled by Marcus after the three CHECK-FIRST items were measured
# (`calibration/diag_periodic_spinup_adoption.R`) ⇒ [[ccx_periodic_adoption_priced]].
# It was `calibration/lib_periodic_spinup.R` until then; `git log --follow` has the
# provenance. `ccx_make_logpost()`'s `spinup_fn` now DEFAULTS to this function.
#
# ⛔⛔ WHAT ADOPTION COST, MEASURED AND NOT ASSUMED:
#   * ~2.15x per objective evaluation at `seas_ml` = 0 and ~2.9-3.1x at
#     `seas_ml` = 1 (6 Newton iterations against 3), i.e. ~5.05 h for ONE refit
#     start priced off the mode file's own 36,569 evals / 99.2 min.
#   * EVERY STORED `logpost`, `prior_z`, PORT TARGET and checkpoint `ref_logpost`
#     IS NOW NON-COMPARABLE. At `hilda31` the likelihood moves
#     -1439.424788 -> -1449.582691 (-10.157904), concentrated in TWO of 25
#     streams with OPPOSITE signs (`d13c_level_SPO` -16.732,
#     `d13c_level_MLO` +8.282). ⚠ That is NOT evidence this spinup fits worse --
#     the mode was FITTED under the aseasonal one, so it is not a like-for-like
#     comparison ⇒ [[like_for_like_forcing]]. Only a refit under THIS spinup can
#     say. A refit under the aseasonal seed and one under this are NOT comparable.
#
# ⚠ AND THERE IS NO "BIT-IDENTICAL AT `seas_ml` = 0" GATE, because there cannot
# be. `ccx_spinup()` zeroes FOUR seasonal paths in its `p0` -- `seas_amp_NH`,
# `seas_amp_SH`, `seas_drivers` AND `seas_ml` -- so at `seas_ml` = 0 the model
# still has a full seasonal cycle to rectify. The gate that IS available, and is
# in `test-spinup-diagnostics.R`, is the one with ALL FOUR off: then there is no
# seasonality, the one-year map's fixed point and the instantaneous fixed point
# are the SAME STATE, and the two spinups must agree at solver tolerance.
# MEASURED: 2.1e-08 with all off, against -10.158 with the driver path live and
# -10.520 with the legacy sine live -- so the defect this file fixes is
# SEASONALITY ITSELF and PREDATES both round 6 and the 2026-08-18 driver path.
# =====================================================================

# ---- named constants -------------------------------------------------
PS_TOL      <- 1e-9      # |Phi(y) - y| on carbon, GtC/yr-equivalent per box
PS_MAXIT    <- 40L       # Newton iterations on the carbon block
PS_FD_REL   <- 1e-7      # finite-difference step, relative
PS_FD_ABS   <- 1e-8      # ... and its floor
PS_MONTHS   <- 12L       # rows in the one-year forcing = months

#' The QUIET preindustrial one-year forcing, at a given 14C production
#'
#' Same construction `tests/testthat/test-conveyor.R` and
#' `calibration/diag_f2_periodic_spinup.R` use: zero fossil, zero LUC flux AND
#' stock, held climate, zero bomb/nuclear 14C, zero AOD. `years` spans ONE year
#' so `ccx_run_fast()` returns the state one period on.
#'
#' @param quiet an already-built quiet year (`ps_year_forcing(0)`) to COPY
#'   instead of rebuilding from disk. The three tables a spinup needs (at 0,
#'   1 and `prod` mol/yr) differ in the `c14_cosmo` column ONLY -- checked
#'   column by column on 2026-09-12 before this argument existed: `identical()`
#'   on every other column, and `identical()` on the whole table after the
#'   overwrite -- so the copy is the rebuild, byte for byte, without the three
#'   `ccx_build_forcing()` disk reads per evaluation (review B1).
ps_year_forcing <- function(prod_c14, year0 = 1750, quiet = NULL) {
  if (!is.null(quiet)) { quiet$c14_cosmo <- prod_c14; return(quiet) }
  F <- ccx_build_forcing("historical", c(year0, year0 + 1), prod_c14 = 0,
                         bomb_total_kmol = 0)
  F <- F[seq_len(PS_MONTHS), , drop = FALSE]      # exactly one period
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F <- ccx_hold_climate(F, value = 0)
  F$c14_bomb <- 0; F$c14_nuclear <- 0; F$c14_cosmo <- prod_c14
  F$aod_NH <- 0; F$aod_SH <- 0
  F
}

#' One period of the flow, from an arbitrary state
#'
#' `ccx_run_fast()` reads only `$y`, `$params`, `$aux`, `$grid` off its first
#' argument, so a shim is the whole wrapper -- no second copy of the runner,
#' which is what the marshalling gate exists to protect.
#'
#' With `prep` (a `ccx_run_prepare()` of the SAME `p`/`aux`/`grid`) the call
#' goes through `ccx_run_prepared()`: the same core entry point, the same
#' NA-retry, the same marshal gate (taken once, when `prep` was built), without
#' re-marshalling `p`/`aux` and re-resolving the substep count on every one of
#' the ~300 one-year calls a solve makes (review 2026-09-12, B1). `F` may be a
#' forcing table or a `ccx_cpp_forcing_prep()` of one.
ps_phi <- function(y, p, aux, grid, F, prep = NULL) {
  # retry_na = FALSE (2026-09-16 d): every one-year call of a solve must run at
  # the SAME count, or the fixed point being solved for is a mixture of maps
  # (review finding 3). An NA here is a spinup failure and surfaces as one.
  if (is.null(prep)) return(ccx_run_fast(list(y = y, params = p, aux = aux, grid = grid), F, retry_na = FALSE))
  ccx_run_prepared(y, prep, F, retry_na = FALSE)
}

#' The full-year trajectory, for the annual means the pins are stated on
ps_year_out <- function(y, p, aux, grid, F) ps_phi(y, p, aux, grid, F)$out

#' PERIODIC SPINUP
#'
#' @param p     parameter list. Integrated AS GIVEN -- nothing is zeroed.
#' @param chi0,d13c0,d14c0  the same preindustrial pins `ccx_spinup()` takes.
#' @param seed  a starting state; default the aseasonal spinup, which is the
#'   natural warm start and is within ~20 ppm by F2's own measurement.
#' @return a list with the SAME field contract `ccx_spinup()` returns, plus
#'   `$periodic` carrying the solve's own diagnostics.
ccx_periodic_spinup <- function(p = ccx_default_params(),
                                chi0  = ccx_const("CO2_PI_PPM"),
                                d13c0 = ccx_const("D13C_PI"),
                                d14c0 = ccx_const("D14C_PI"),
                                # ⛔ FALSE since adoption (09-09x): this is now
                                # called once per objective evaluation, and the
                                # per-iteration Newton trace would flood a refit
                                # of tens of thousands of evaluations.
                                seed = NULL, verbose = FALSE) {
  sp0  <- if (is.null(seed)) ccx_spinup(p, chi0, d13c0, d14c0) else seed
  aux  <- sp0$aux; grid <- sp0$grid
  # ⛔ THE ONE INVARIANT THIS FILE EXISTS TO KEEP: `aux` must be prepared from
  # the SAME p we integrate. ccx_spinup() returns the aux it prepared from its
  # OWN un-mutated `p`, so this holds when `seed` is its output -- assert it
  # rather than trust it ([[two_gates_one_mechanism]]).
  ccx_seas_ml_marshal_check(p, aux)
  if (xor(ccx_seas_ml_on(p), !is.null(aux$mld_coef)))
    stop("periodic spinup: `aux` was prepared from a DIFFERENT parameter list than `p` ",
         "(seas_ml on = ", ccx_seas_ml_on(p), ", aux$mld_coef present = ",
         !is.null(aux$mld_coef), "). That is the 2026-09-09t leak's exact mechanism.")

  nb    <- nrow(sp0$y)
  atm   <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  iatmN <- aux$idx$NH$atm
  c_atm_target <- chi0 * aux$gtc_per_ppm_hemi * length(atm)
  prod  <- sp0$prod_c14

  # Marshalled ONCE for the whole solve (review B1): one `p`, one `aux`, one
  # substep count, one marshal-gate verdict, for every one-year call below.
  # The quiet year is built from disk ONCE and copied for the three
  # productions the solve needs (see ps_year_forcing).
  prep <- ccx_run_prepare(list(y = sp0$y, params = p, aux = aux, grid = grid))
  Fq   <- ps_year_forcing(0)

  # ---- 1. CARBON: Newton on the one-year map ------------------------
  # residual = Phi(y)_C - y_C, one row replaced by the ANNUAL-MEAN atmospheric
  # carbon pin. Both isotopes ride along untouched; 12C does not read them.
  F <- ccx_cpp_forcing_prep(ps_year_forcing(prod, quiet = Fq))
  ps_resid_C <- function(cv) {
    yy <- sp0$y; yy[, "C"] <- cv
    r  <- ps_phi(yy, p, aux, grid, F, prep)
    res <- r$state[, "C"] - cv
    # the ANNUAL MEAN, not the endpoint: `out`'s co2_* columns are the monthly
    # trajectory over the period just integrated.
    mean_atm_C <- mean(r$out$co2_NH + r$out$co2_SH) * aux$gtc_per_ppm_hemi
    res[iatmN] <- mean_atm_C - c_atm_target
    res
  }
  cv <- sp0$y[, "C"]
  hist <- numeric(0)
  for (it in seq_len(PS_MAXIT)) {
    r0 <- ps_resid_C(cv); nr <- max(abs(r0)); hist <- c(hist, nr)
    if (verbose) cat(sprintf("  [carbon] it %2d  |resid| %.3e\n", it, nr))
    if (nr < PS_TOL) break
    J <- matrix(0, nb, nb)
    for (j in seq_len(nb)) {
      dh <- max(PS_FD_REL * abs(cv[j]), PS_FD_ABS)
      cp <- cv; cp[j] <- cp[j] + dh
      J[, j] <- (ps_resid_C(cp) - r0) / dh
    }
    step <- tryCatch(solve(J, -r0), error = function(e) NULL)
    if (is.null(step)) stop("periodic spinup: singular carbon Jacobian at iteration ", it)
    cv <- cv + step
  }
  resid_C <- max(abs(ps_resid_C(cv)))
  if (resid_C >= PS_TOL)
    warning(sprintf("periodic spinup: carbon did not converge, |resid| = %.3e", resid_C))
  y <- sp0$y; y[, "C"] <- cv

  # ---- 2. the ISOTOPE MONODROMY, built exactly ----------------------
  # Phi_iso(c) = M c + b, affine because the isotope enters ccx_deriv linearly
  # and the carbon orbit is now fixed. Same idiom as R/spinup.R's iso_operator(),
  # one period instead of one instant.
  # `atm_of(out)` is the tracer's ATMOSPHERIC MASS row by row over the year;
  # its year-mean is affine in the initial vector too, so the same runs that
  # build M and b build `Mbar` and `bbar` for the annual-mean pin.
  ps_monodromy <- function(tracer, Fm, atm_of) {
    y0 <- y; y0[, tracer] <- 0
    r0 <- ps_phi(y0, p, aux, grid, Fm, prep)
    b  <- r0$state[, tracer]; bbar <- mean(atm_of(r0$out))
    M  <- matrix(0, nb, nb); Mbar <- numeric(nb)
    for (j in seq_len(nb)) {
      yj <- y0; yj[j, tracer] <- 1
      rj <- ps_phi(yj, p, aux, grid, Fm, prep)
      M[, j] <- rj$state[, tracer] - b
      Mbar[j] <- mean(atm_of(rj$out)) - bbar
    }
    list(M = M, b = b, Mbar = Mbar, bbar = bbar, out0 = r0$out)
  }
  gpph <- aux$gtc_per_ppm_hemi; R13 <- ccx_const("R13_VPDB")
  # the NH atmospheric 13C mass, exactly, from the out columns: (1 + d/1000) R C
  atm13_NH <- function(o) (1 + o$d13c_NH / 1000) * R13 * o$co2_NH * gpph

  # 13C: (M - I) c = -b is singular (13C is conserved over the period), so pin
  # the scale on one row -- the ANNUAL MEAN of the NH atmospheric 13C over the
  # orbit, = R13 (1 + d13c0/1000) x the annual-mean NH atmospheric carbon.
  o13 <- ps_monodromy("C13", F, atm13_NH)
  A13 <- o13$M - diag(nb); rhs <- -o13$b
  target13 <- mean(o13$out0$co2_NH) * gpph * R13 * (1 + d13c0 / 1000)
  A13[iatmN, ] <- o13$Mbar; rhs[iatmN] <- target13 - o13$bbar
  y[, "C13"] <- solve(A13, rhs)

  # 14C: linear in production, so solve at unit production, run that periodic
  # orbit once, and scale production so its ANNUAL-MEAN total atmospheric 14C
  # is (1 + d14c0/1000) x the annual-mean atmospheric carbon.
  F1  <- ccx_cpp_forcing_prep(ps_year_forcing(1, quiet = Fq))
  o14 <- ps_monodromy("C14", F1, function(o) o$atm_C14)
  A14 <- o14$M - diag(nb)
  u   <- solve(A14, -o14$b)
  yu  <- y; yu[, "C14"] <- u
  ou  <- ps_phi(yu, p, aux, grid, F1, prep)$out
  c14_target_atm <- mean(ou$co2_NH + ou$co2_SH) * gpph * (1 + d14c0 / 1000)
  prod <- c14_target_atm / mean(ou$atm_C14)
  y[, "C14"] <- prod * u

  # ---- 3. diagnostics, from the SAME PRODUCER `ccx_spinup()` uses -----
  # ⛔ THIS USED TO INHERIT `sp0$diagnostics` AND OVERWRITE SIX FIELDS. Every
  # other row then silently carried the ASEASONAL SEED's value -- `d13c_atm`,
  # `d14c_atm`, all the deep/bottom/HS D14C rows, the land inventories, and
  # worst, `prod_c14_mol_yr`/`prod_ratio`, which contradicted this object's own
  # `$prod_c14` because production is RE-SOLVED above. Fixed 2026-09-09x by
  # routing both spinups through `ccx_spinup_diagnostics()`: one definition of
  # every state-derived row, and the two ESTIMATOR-DEPENDENT rows passed
  # explicitly, on THIS solve's own conventions
  # ⇒ [[two_gates_one_mechanism]], [[verify_the_quantity_not_the_word]].
  Ffin <- ps_year_forcing(prod, quiet = Fq)
  rfin <- ps_phi(y, p, aux, grid, Ffin, prep)
  per_resid <- max(abs(rfin$state - y))
  d <- ccx_spinup_diagnostics(
    y, prod, aux, grid,
    # |Phi(y) - y| over ONE PERIOD, not an instantaneous |dy/dt|: on a limit
    # cycle the instantaneous derivative is NOT zero and never becomes zero.
    residuals = list(C   = max(abs(rfin$state[, "C"]   - y[, "C"])),
                     C13 = max(abs(rfin$state[, "C13"] - y[, "C13"])),
                     C14 = max(abs(rfin$state[, "C14"] - y[, "C14"]))),
    # the ANNUAL MEAN over the orbit -- the quantity the 12C pin is stated on.
    # The start-of-year instant differs from it by the seasonal amplitude.
    co2_ppm   = mean(rfin$out$co2_NH + rfin$out$co2_SH) / 2)

  list(y = y, prod_c14 = prod, aux = aux, grid = grid, params = p,
       diagnostics = d,
       periodic = list(kind = "periodic", period_yr = 1,
                       resid_state = per_resid, resid_carbon = resid_C,
                       iterations = length(hist), resid_history = hist,
                       pin = "annual-mean atmospheric CO2, d13C and D14C",
                       seeded_from = if (is.null(seed)) "ccx_spinup" else "caller"))
}

# ⭐⭐ THE ONE NAME FOR "THE SPINUP THE OBJECTIVE USES", and it exists because
# adoption broke four tests that had each hard-coded `ccx_spinup()` in a
# hand-built reconstruction of the objective's scoring path. Every such path --
# `ccx_make_logpost()`'s own default included -- now reads THIS, so flipping the
# objective's spinup cannot silently desync a reconstruction from the thing it
# reconstructs ⇒ [[two_gates_one_mechanism]]. A test or diagnostic that
# deliberately wants the ASEASONAL spinup names `ccx_spinup` explicitly, which
# then reads as the deliberate choice it is.
# ⛔ Defined HERE and not in `calibrate.R`: the alphabetical `list.files("R")`
# bootstrap sources `calibrate.R` FIRST, so a binding to `ccx_periodic_spinup`
# made there would be evaluated before the function exists. `ccx_make_logpost()`
# can still DEFAULT to it because a default argument is resolved at CALL time.
CCX_OBJECTIVE_SPINUP <- ccx_periodic_spinup

#' The LABEL of a spinup function, for RECORDING into a mode file (2026-09-10).
#' A promoted mode's `streams` are computed under `CCX_OBJECTIVE_SPINUP`, and a
#' consumer that wants to reproduce them like-for-like must score the vector
#' the way the file was fitted ⇒ [[like_for_like_forcing]]. Until 09-10 nothing
#' in the file said which spinup that was, and test-enso-demean.R had to hard-
#' code `ccx_spinup` for the aseasonal-era canonical; the label makes the file
#' self-describing. Two admissible values, matched by identity of the function.
ccx_spinup_label <- function(fn = CCX_OBJECTIVE_SPINUP) {
  if (identical(fn, ccx_periodic_spinup)) return("periodic")
  if (identical(fn, ccx_spinup))          return("aseasonal")
  stop("ccx_spinup_label(): not one of the two admissible spinups (ccx_periodic_spinup, ccx_spinup).")
}
ccx_spinup_from_label <- function(label) {
  switch(as.character(label), periodic = ccx_periodic_spinup, aseasonal = ccx_spinup,
         stop("ccx_spinup_from_label(): unknown spinup label '", label, "'."))
}

