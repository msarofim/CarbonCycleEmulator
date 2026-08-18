# =====================================================================
# joos_irf.R -- the Joos et al. (2013) impulse-response protocol.
#
# PROMOTED HERE 2026-08-18 from calibration/diag_joos_irf.R, where it lived
# alongside a byte-identical copy in calibration/diag_joos_beta_scan.R. Both
# copies were verified identical function-by-function before the move, and both
# diagnostics now read these definitions by sourcing R/ -- so their numbers are
# unchanged. The move was needed because tests/testthat/test-pulse.R has to run
# the PD100 protocol to state a Joos bar at the protocol Joos's numbers are for;
# a third copy in the test directory was the alternative and would have made the
# divergence risk worse rather than better.
#
# EVERYTHING IN THIS FILE IS PROTOCOL, NOT MODEL. It builds the background and
# the pulse Joos specifies; it does not change how the carbon cycle responds to
# them. The constants are Joos's, and are labelled with what they are for.
# =====================================================================

JOOS_PULSE     <- 100          # GtC, Joos's standard impulse
JOOS_PPM_PER   <- 2.123        # GtC per ppm, the conversion Joos states

# ---------------------------------------------------------------------
# A background held CONSTANT by diagnosed compatible emissions.
#
# At each month the atmospheric carbon tendency is evaluated with zero
# emissions, and the emission is set to exactly cancel it. That is Joos's run 1
# ("compatible emissions are diagnosed") done online rather than by iteration,
# and it uses ccx_deriv() itself so the controller cannot disagree with the
# model it is controlling.
# ---------------------------------------------------------------------
# Diagnosed compatible emissions, found by LEAST SQUARES ON A RELAXATION BASIS.
#
# TWO METHODS WERE TRIED AND FAILED FIRST, and both failures are instructive:
#
#  [1] An ONLINE CONTROLLER -- evaluate ccx_deriv() each month with zero
#      emissions and set the emission to cancel the atmospheric tendency
#      exactly. Correct, and Joos's run 1 done literally, but it needs
#      ccx_deriv() inside the stepping loop: ~60k pure-R derivative evaluations
#      per run, minutes each, and there are eight runs here.
#  [2] A NEWTON ITERATION on the monthly drift, e <- e - 12*d(CO2)*GtC_PER_PPM,
#      on the fast C++ path. IT DIVERGES -- to 2e34 ppm in 40 iterations. The
#      reason is worth recording because the step LOOKS exact: an emission added
#      in month i raises CO2 in EVERY later month, so the response operator is
#      lower-triangular, not diagonal, and correcting each month independently
#      compounds instead of contracting.
#
# WHAT WORKS. The model is very nearly LINEAR in emissions at these magnitudes,
# so the emission path is expanded on a basis of relaxation exponentials, each
# basis function is run once (cheap, C++), and the coefficients are solved by
# least squares against the target. Three passes handle the residual
# non-linearity. Nine basis functions, eight runs, ~0.3 s.
#
# A POLYNOMIAL BASIS WAS ALSO TRIED AND MUST NOT BE REINSTATED: adding t, t^2,
# t^3 alongside the exponentials makes the design matrix ill-conditioned and the
# passes diverge (562 -> 2364 -> 37221 ppm).
#
# The background is held to ~1 ppm in ~386, i.e. 0.26 %. That is not exact and
# the realised deviation is REPORTED rather than hidden; it perturbs the Revelle
# factor by ~0.3 %, far below anything the IRF comparison resolves.
JOOS_HOLD_TAUS <- c(2, 5, 10, 25, 50, 100, 200, 500)   # yr, relaxation basis
JOOS_HOLD_PASS <- 3L

ccx_set_emissions <- function(F, e) {
  F$e_foss_NH <- e * FORC_FOSS_NH_SHARE
  F$e_foss_SH <- e * (1 - FORC_FOSS_NH_SHARE)
  F
}

ccx_hold_forcing <- function(sp, F, verbose = FALSE) {
  co2_of <- function(o) (o$co2_NH + o$co2_SH) / 2
  tt <- F$t - F$t[1]
  B  <- cbind(1, vapply(JOOS_HOLD_TAUS, function(z) exp(-tt / z), numeric(length(tt))))
  c0 <- co2_of(ccx_run_fast(sp, ccx_set_emissions(F, rep(0, nrow(F))))$out)
  R  <- vapply(seq_len(ncol(B)),
               function(k) co2_of(ccx_run_fast(sp, ccx_set_emissions(F, B[, k]))$out) - c0,
               numeric(length(tt)))
  target <- c0[1]
  e <- rep(0, nrow(F)); cur <- c0
  for (pass in seq_len(JOOS_HOLD_PASS)) {
    e   <- e + as.vector(B %*% qr.solve(R, target - cur))
    cur <- co2_of(ccx_run_fast(sp, ccx_set_emissions(F, e))$out)
  }
  dev <- max(abs(cur - target))
  if (verbose)
    cat(sprintf("    background held to %.3f ppm of %.2f (%.2f %%); mean diagnosed emission %.2f GtC/yr\n",
                dev, target, 100 * dev / target, mean(e)))
  F <- ccx_set_emissions(F, e)
  attr(F, "target") <- target; attr(F, "dev") <- dev
  F
}

#' Add a mass pulse to a spinup state at its own isotopic ratios
ccx_pulse_state <- function(sp, pulse) {
  iN <- sp$aux$idx$NH$atm; iS <- sp$aux$idx$SH$atm
  sh <- sp$y[iN, "C"] / (sp$y[iN, "C"] + sp$y[iS, "C"])
  for (k in c(iN, iS)) {
    add <- pulse * if (k == iN) sh else 1 - sh
    r13 <- sp$y[k, "C13"] / sp$y[k, "C"]; r14 <- sp$y[k, "C14"] / sp$y[k, "C"]
    sp$y[k, "C"]   <- sp$y[k, "C"]   + add
    sp$y[k, "C13"] <- sp$y[k, "C13"] + add * r13
    sp$y[k, "C14"] <- sp$y[k, "C14"] + add * r14
  }
  sp
}

#' IRF from a paired baseline/pulse run on a given background forcing
ccx_irf <- function(sp, F) {
  co2_of <- function(o) (o$co2_NH + o$co2_SH) / 2
  b <- co2_of(ccx_run_fast(sp, F)$out)
  q <- co2_of(ccx_run_fast(ccx_pulse_state(sp, JOOS_PULSE), F)$out)
  list(t = F$t - F$t[1], irf = (q - b) / (JOOS_PULSE / JOOS_PPM_PER), base = b)
}

# ---------------------------------------------------------------------
# WHAT JOOS SAYS -- protocol years, and the published reference values the
# model is scored against. Promoted 2026-08-18 from the two diag_joos_*
# scripts, where they were byte-identical duplicates.
# ---------------------------------------------------------------------
JOOS_REF_YEAR  <- 2010         # Joos run 1: CO2 held fixed after this year
JOOS_PULSE_YR  <- 2015         # Joos run 3: pulse released here
JOOS_TH        <- c(20, 50, 100)
# Joos et al. 2013 Table 5, multi-model mean IRF_CO2, fit for 0 < t < 1000 yr:
#   IRF(t) = a0 + a1 exp(-t/tau1) + a2 exp(-t/tau2) + a3 exp(-t/tau3)
JOOS_T5 <- list(a0 = 0.2173,
                a = c(0.2240, 0.2824, 0.2763),
                tau = c(394.4, 36.54, 4.304))
joos_irf <- function(t) JOOS_T5$a0 + colSums(outer(JOOS_T5$a, t, function(a, tt) a) *
                                             exp(-outer(JOOS_T5$tau, t, function(s, tt) tt / s)))
# Joos et al. 2013 Table 4, time-integrated IRF_CO2 in years, PD100:
# best estimate from the fit, and the 5-95 % confidence range.
JOOS_T4 <- data.frame(
  th   = c(20, 50, 100),
  best = c(14.2, 30.3, 52.4),
  lo   = c(12.2, 24.0, 39.5),
  hi   = c(16.3, 36.6, 65.2))
# Joos sec. 4.4.1: across the 10 models that ran both, time-integrated IRF at
# year 100 is 34-47 yr for a PREINDUSTRIAL background and 45-62 for present-day.
JOOS_PI100_100 <- c(34, 47)
JOOS_PD100_100 <- c(45, 62)
