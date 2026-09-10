# =====================================================================
# lib_periodic_spinup.R -- a PERIODIC (limit-cycle) spinup: the state y* with
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
#
# ⚠ `aux` IS PREPARED FROM THE SAME `p` THAT IS INTEGRATED. `ccx_spinup()`
# builds `aux` from `p` and then integrates with a mutated `p0`, which is the
# 09-09t leak's whole mechanism ⇒ [[two_gates_one_mechanism]]. Nothing is
# mutated here: one parameter list, one `ccx_prepare()`, one gate.
#
# Sourced by calibration/diag_periodic_spinup.R. Promotion into R/ is a separate
# step and is NOT taken here.
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
ps_year_forcing <- function(prod_c14, year0 = 1750) {
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
#' argument (R/cpp.R:348-353), so a shim is the whole wrapper -- no second copy
#' of the runner, which is what the marshalling gate exists to protect.
ps_phi <- function(y, p, aux, grid, F) {
  ccx_run_fast(list(y = y, params = p, aux = aux, grid = grid), F)
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
                                seed = NULL, verbose = TRUE) {
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

  # ---- 1. CARBON: Newton on the one-year map ------------------------
  # residual = Phi(y)_C - y_C, one row replaced by the ANNUAL-MEAN atmospheric
  # carbon pin. Both isotopes ride along untouched; 12C does not read them.
  F <- ps_year_forcing(prod)
  ps_resid_C <- function(cv) {
    yy <- sp0$y; yy[, "C"] <- cv
    r  <- ps_phi(yy, p, aux, grid, F)
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
  ps_monodromy <- function(tracer, Fm) {
    y0 <- y; y0[, tracer] <- 0
    b  <- ps_phi(y0, p, aux, grid, Fm)$state[, tracer]
    M  <- matrix(0, nb, nb)
    for (j in seq_len(nb)) {
      yj <- y0; yj[j, tracer] <- 1
      M[, j] <- ps_phi(yj, p, aux, grid, Fm)$state[, tracer] - b
    }
    list(M = M, b = b)
  }

  # 13C: (M - I) c = -b is singular (13C is conserved over the period), so pin
  # the scale on one row, exactly as the aseasonal solve does.
  o13 <- ps_monodromy("C13", F)
  A13 <- o13$M - diag(nb); rhs <- -o13$b
  target13 <- y[iatmN, "C"] * ccx_const("R13_VPDB") * (1 + d13c0 / 1000)
  A13[iatmN, ] <- 0; A13[iatmN, iatmN] <- 1; rhs[iatmN] <- target13
  y[, "C13"] <- solve(A13, rhs)

  # 14C: linear in production, so solve at unit production and rescale.
  o14 <- ps_monodromy("C14", ps_year_forcing(1))
  A14 <- o14$M - diag(nb)
  u   <- solve(A14, -o14$b)
  c14_target_atm <- sum(y[atm, "C"]) * (1 + d14c0 / 1000)
  prod <- c14_target_atm / sum(u[atm])
  y[, "C14"] <- prod * u

  # ---- 3. diagnostics, on the SAME contract ccx_spinup() returns -----
  Ffin <- ps_year_forcing(prod)
  rfin <- ps_phi(y, p, aux, grid, Ffin)
  per_resid <- max(abs(rfin$state - y))
  ocean_idx <- unlist(lapply(HEMIS, function(h)
    c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd)))
  bot_idx <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 1)))
  d <- sp0$diagnostics
  d$max_abs_dCdt   <- max(abs(rfin$state[, "C"]   - y[, "C"]))
  d$max_abs_dC13dt <- max(abs(rfin$state[, "C13"] - y[, "C13"]))
  d$max_abs_dC14dt <- max(abs(rfin$state[, "C14"] - y[, "C14"]))
  d$co2_ppm        <- mean(rfin$out$co2_NH + rfin$out$co2_SH) / 2
  d$d14c_bottom_box <- 1000 * (sum(y[bot_idx, "C14"]) / sum(y[bot_idx, "C"]) - 1)
  d$ocean_C_GtC    <- sum(y[ocean_idx, "C"])

  list(y = y, prod_c14 = prod, aux = aux, grid = grid, params = p,
       diagnostics = d,
       periodic = list(kind = "periodic", period_yr = 1,
                       resid_state = per_resid, resid_carbon = resid_C,
                       iterations = length(hist), resid_history = hist,
                       pin = "annual-mean atmospheric CO2, d13C and D14C",
                       seeded_from = if (is.null(seed)) "ccx_spinup" else "caller"))
}
