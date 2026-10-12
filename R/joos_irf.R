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
# ⛔⛔ THE PD100 RELEASE, DONE ONCE (2026-09-27 d). Until today every caller did
#   o <- ccx_irf(sp_ref, F_hold); o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR)
# -- ELEVEN copies, the app's review panel and test-pulse.R among them. But
# ccx_irf() adds the pulse at the FIRST row of F, i.e. at JOOS_REF_YEAR (2010),
# not at JOOS_PULSE_YR (2015). The shift therefore did not move the clock to the
# release; it DISCARDED the first five years after it, so every "IRF@20" was
# IRF@25 and every integrated IRF ran from 5 to TH+5, dropping the years in
# which the IRF is highest. Measured at hilda29l: TH 20/50/100 read
# 11.41/23.51/39.15 where the truth is 13.04/25.80/41.82 -- "at the floor"
# was the shift, not the model. The point IRF@100 barely moves (0.284 -> 0.288).
# The raw run proves it: IRF at the first row is 0.9995, the whole pulse.
#
# This now does what the comment at every call site SAID it did: hold the
# background to JOOS_PULSE_YR, then release, and measure t from the release.
# ---------------------------------------------------------------------
# A released pulse must read (almost) the WHOLE pulse at t = 0 -- conservation.
# The first output row is within one month of release, and the model's own
# one-month uptake is 1.25 % of the pulse (measured at hilda29l, 2026-09-27);
# 2 % bounds that. The shifted series this replaces started at 0.718 -- 14x
# outside. MUTATION-TESTED in test-pulse.R.
JOOS_IRF0_TOL <- 0.02
joos_release_check <- function(o) {
  if (!length(o$irf) || abs(o$t[1]) > 1 / 12 + 1e-9 || abs(o$irf[1] - 1) > JOOS_IRF0_TOL)
    stop(sprintf("PD100 release check: first row t = %.3f yr, IRF = %.4f; a pulse released at t = 0 must read ~1 (tol %.2f). Is the clock shifted?",
                 o$t[1], o$irf[1], JOOS_IRF0_TOL))
  invisible(o)
}
ccx_irf_pd <- function(sp_ref, F_hold, pulse = JOOS_PULSE, release = JOOS_PULSE_YR) {
  pre <- F_hold$t < release
  if (!any(pre) || all(pre)) stop("ccx_irf_pd: F_hold must span the release year (", release, ")")
  climate <- attr(F_hold, "pd_climate")
  # A table WITHOUT the stamp is a HELD-ERA call: test-pulse.R and the held-era diagnostics build
  # their own held table and were written for that protocol, so it means "held" -- said, not
  # assumed silently. The live consumers all go through ccx_pd100(), which stamps it.
  if (is.null(climate)) {
    message("ccx_irf_pd: no pd_climate on F_hold -- a held-era call, run HELD (ccx_pd100() is the live, free runner)")
    climate <- "held"
  }
  # T_deep is carried across the release seam too (2026-10-12; it was restarted at 0 here)
  sp_rel <- ccx_pulse_continue(sp_ref, F_hold[pre, , drop = FALSE])
  Fp <- F_hold[!pre, , drop = FALSE]
  pp <- ccx_pulse_pair(sp_rel, Fp, pulse, climate)
  b <- ccx_pd_co2(pp$b)
  joos_release_check(list(t = Fp$t - Fp$t[1], irf = (ccx_pd_co2(pp$q) - b) / (pulse / JOOS_PPM_PER),
                          base = b, b = pp$b, q = pp$q, dT = pp$dT, iter = pp$iter,
                          converged = pp$converged, climate = climate))
}

#' THE PD100, END TO END: history to JOOS_REF_YEAR, the background held (CO2 by diagnosed
#' emissions) with its climate FREE or HELD, and the pulse released at JOOS_PULSE_YR. The one
#' runner card 5a, gate L / card 5b, the scorecard and diag_joos_irf.R share (2026-10-12).
ccx_pd100 <- function(spin, end_year, bomb_total_kmol, luc_scale, climate = CCX_PD_CLIMATE_DEFAULT,
                      pulse = JOOS_PULSE, verbose = FALSE) {
  pf <- ccx_pulse_forcings(spin, c(JOOS_REF_YEAR, end_year), bomb_total_kmol, luc_scale)
  sp_ref <- ccx_pulse_ref_state(spin, pf$F_hist)
  F_bkg <- ccx_pulse_background(sp_ref, pf$F_fwd, climate)
  F_hold <- ccx_hold_forcing(sp_ref, F_bkg, verbose = verbose)
  attr(F_hold, "pd_climate") <- climate
  o <- ccx_irf_pd(sp_ref, F_hold, pulse)
  o$hold_dev <- attr(F_hold, "dev"); o$target <- attr(F_hold, "target")
  o$bkg <- attr(F_bkg, "pd_bkg"); o$gmst_fwd <- F_hold$gmst; o$t_fwd <- F_hold$t
  o$sp_ref <- sp_ref
  o
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
# =====================================================================
# ⭐⭐ STATUS, RULED 2026-09-04 (Marcus): GATE 12 / 12a / 12b ARE A POST-MODEL
# COMPARISON, NOT A STRICT TEST. "We don't necessarily expect to meet it; the
# long lifetime should be an emergent behavior."
#
# WHY. Joos et al. 2013 is ANOTHER MODEL -- a multi-model mean, the last-resort
# class in the source hierarchy (~/.claude/CLAUDE.md: observation, then law, then
# another model). Every other gate in this project now rests on an observation or
# a law; this one cannot, because NO OBSERVATION CONSTRAINS A CO2 PERTURBATION
# LIFETIME. The bomb-14C record measures tracer transport, not the perturbation:
# 14C is already inert on this axis and the two are ~2.8x apart at 100 yr
# [[pulse_label_vs_perturb]]. So the comparison is worth MAKING and is not worth
# PASSING: a long tail that appears because the model was tuned to Joos's number
# is not evidence of anything, whereas a long tail that emerges from the ocean
# carbonate chemistry and the land sink is.
#
# ⇒ WHAT THIS CHANGES IN PRACTICE:
#   * The numbers are still computed and still PRINTED against Joos's ranges,
#     with "inside / BELOW / ABOVE" -- calibration/diag_joos_irf.R sections 3, 3b.
#   * NOTHING IS SCORED, GATED, OR CHASED IN A REFIT on this axis.
#   * ⚠ AND THE PRE-REGISTERED CLAIM P5 IS NO LONGER "FALSIFIED". IRF(100) = 0.276
#     against Joos's band is now a REPORTED DIFFERENCE -- a statement about where
#     the model's emergent lifetime sits, not a failed test. Every record that
#     says "P5 FALSIFIED" predates this ruling.
#   * The DISCRIMINATION the tail statistic provides is kept and is still
#     asserted, because it is a property of the ESTIMATOR and the REFERENCE, not
#     of our model: no single exponential, at any time constant, can reach the
#     band (test-joos-irf.R).
# =====================================================================
JOOS_T4 <- data.frame(
  th   = c(20, 50, 100),
  best = c(14.2, 30.3, 52.4),
  lo   = c(12.2, 24.0, 39.5),
  hi   = c(16.3, 36.6, 65.2))
# Joos sec. 4.4.1: across the 10 models that ran both, time-integrated IRF at
# year 100 is 34-47 yr for a PREINDUSTRIAL background and 45-62 for present-day.
JOOS_PI100_100 <- c(34, 47)
JOOS_PD100_100 <- c(45, 62)

# ---------------------------------------------------------------------
# THE TAIL TEST (gate 12b, added 2026-08-25 at Marcus's direction)
#
# WHY IT HAD TO EXIST. Gate 12 tested the time-integrated IRF at TH 20/50/100
# only, and calibration/../notes/lit_2026-08-25_co2_lifetime_confusion.R showed
# that test CANNOT DO ITS JOB: the two published single-exponential carbon-cycle
# models in current circulation both PASS it at all three horizons --
#
#   Spencer 2023      2.05 %/yr of the excess over 295 ppm  ->  16.4 / 31.3 / 42.5
#   Dengler & Reid    42-yr half-life                       ->  17.0 / 34.0 / 49.0
#   Joos T4 5-95 %                                              12.2-16.3 / 24.0-36.6 / 39.5-65.2
#
# -- while the quantity that actually separates them, the fraction still
# airborne at 300 yr, is 0.322 (Joos) against 0.002 and 0.007. The first century
# is where the wrong structure looks right.
#
# THE TEST IS A RATIO, AND THAT IS THE POINT. For ANY single exponential,
# whatever its time constant,
#     IRF(300)/IRF(100) = exp(-200/tau) = [exp(-100/tau)]^2 = IRF(100)^2
# exactly. So the single-exponential null is a PARAMETER-FREE LOCUS, not a
# number somebody chose, and a model with a genuine long tail must sit far above
# its own IRF(100)^2. Joos sits at 0.787 where its own locus value is 0.167.
JOOS_TAIL_TH   <- c(100, 300)            # the two horizons the ratio uses
# Joos Table 5's own tail ratio, computed from the published fit, not quoted:
JOOS_TAIL_REF  <- NULL                   # filled below, after joos_irf() exists
# CONSTRUCTED TOLERANCE, AND IT IS FLAGGED AS CONSTRUCTED. Joos publishes no
# 5-95 % range at TH 300, so the relative width of Table 4's TH-100 range
# (39.5/52.4 = 0.754 and 65.2/52.4 = 1.244) is borrowed. That is an assumption:
# it transfers a spread measured on a time-INTEGRAL at 100 yr onto a RATIO at
# 300. It is stated rather than silently adopted -- and the discrimination does
# not depend on it, because the single-exponential models sit 16-36x below even
# the loosest end (see the diagnostic's own printout).
JOOS_TAIL_RELBAND <- c(JOOS_T4$lo[JOOS_T4$th == 100] / JOOS_T4$best[JOOS_T4$th == 100],
                       JOOS_T4$hi[JOOS_T4$th == 100] / JOOS_T4$best[JOOS_T4$th == 100])

#' The single-exponential locus: what IRF(300)/IRF(100) MUST be for a one-box
#' model, given its own IRF(100). Parameter-free -- no time constant enters.
joos_tail_null <- function(irf100) irf100^2

#' Tail ratio of an IRF series, on the SAME estimator for model and benchmark
joos_tail_ratio <- function(t, irf) {
  at <- function(y) irf[which.min(abs(t - y))]
  at(JOOS_TAIL_TH[2]) / at(JOOS_TAIL_TH[1])
}

JOOS_TAIL_REF  <- joos_irf(JOOS_TAIL_TH[2]) / joos_irf(JOOS_TAIL_TH[1])
JOOS_TAIL_BAND <- JOOS_TAIL_REF * JOOS_TAIL_RELBAND

# The two published one-box models, carried so the gate PRINTS what it
# discriminates rather than merely asserting that it does.
JOOS_ONEBOX <- list(
  "Spencer 2023 (2.05 %/yr over 295 ppm)" = function(t) exp(-0.0205 * t),
  "Dengler & Reid 2023 (42-yr half-life)" = function(t) 0.5^(t / 42))


#' Hold a pulse experiment's N DEPOSITION (2026-10-01). The Joos protocol holds the background
#' (GMST at its reference value, emissions and ENSO zero), and N deposition is background too.
#' A "historical" table built past the data's end carries NONE (ccx_ndep_forcing() returns zeros
#' stamped "none ...", which ccx_ndep_check() refuses at ndep_ret != 0), so the hold is explicit:
#' at `F_ref`'s LAST year (the reference year of a present-day run), or at zero when `F_ref` is
#' NULL (a preindustrial run: deposition is defined as zero at 1750). Stamped, so the run reports
#' what it held. At ndep_ret 0 nothing reads these columns (bit-exact for every older label).
ccx_pulse_hold_ndep <- function(F, F_ref = NULL, label = "") {
  if (is.null(F_ref)) { F$ndep_NH <- 0; F$ndep_SH <- 0
    attr(F, "ndep_source") <- paste0("zero: the preindustrial pulse background", label)
    return(F) }
  last <- floor(F_ref$t) == max(floor(F_ref$t))
  F$ndep_NH <- mean(F_ref$ndep_NH[last]); F$ndep_SH <- mean(F_ref$ndep_SH[last])
  attr(F, "ndep_source") <- sprintf("%s, held at %d: the pulse background%s",
                                    attr(F_ref, "ndep_source"), max(floor(F_ref$t)), label)
  F
}

#' THE JOOS PULSE PROTOCOL'S TWO FORCINGS for a spun-up state (2026-10-01): the history to
#' JOOS_REF_YEAR, and the forward window with the background HELD -- emissions, ENSO and the 14C
#' sources zero; GMST and N deposition at their reference-year values. Both carry the STRUCTURE's
#' ENSO index and AOD mode (spin$params, the objective's own reads), so an aod-"anomaly" label
#' runs; before this, every pulse site built them bare and stopped at ccx_run_prepared()'s AOD
#' check for any label from hilda_csl3v0ka on. F_fwd is NOT yet held at constant CO2:
#' ccx_hold_forcing() does that, as before.
#' @param years_fwd c(JOOS_REF_YEAR, end) of the forward window
ccx_pulse_forcings <- function(spin, years_fwd, bomb_total_kmol, luc_scale) {
  p <- spin$params
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14,
                              bomb_total_kmol = bomb_total_kmol, luc_scale = luc_scale,
                              enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p),
                              nuc_share = ccx_nuc_share_of(p))
  # ⚠ THE FORWARD TABLE'S CLOCK RUNS ONE YEAR BEHIND REAL TIME (documented 2026-10-12, code review;
  # behaviour unchanged). F_hist ends at t = JOOS_REF_YEAR + 0.958 (Dec 2010), and the state continues
  # from the END of 2010; but years_fwd starts at JOOS_REF_YEAR, so F_fwd's first row is labelled
  # t = JOOS_REF_YEAR + 0.042 (Jan 2010). Every forward label is therefore one year early: the AOD
  # column (the only time-varying background column left after the holds below) enters a year early,
  # and ccx_irf_pd()'s "release at JOOS_PULSE_YR" happens at real time JOOS_PULSE_YR + 1 (2016.0, not
  # 2015.0). Measured negligible by the review: IRF(100) 0.37912 -> 0.37921 with the clock aligned.
  F_fwd <- suppressWarnings(ccx_build_forcing("historical", years_fwd, prod_c14 = spin$prod_c14,
                              bomb_total_kmol = 0, luc_scale = luc_scale,
                              enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p),
                              nuc_share = ccx_nuc_share_of(p)))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso", "c14_bomb", "c14_nuclear"))
    F_fwd[[cc]] <- 0
  # ⛔ FIXED 2026-10-12 (Marcus: "Fix both in the builder (Recommended)"). This line was
  # `F_fwd$gmst <- F_fwd$gmst[1]` -- the hand idiom ccx_hold_climate() exists to replace: it held
  # GMST and left the observed-SST columns running (NH 0.72 K in 2010 -> 1.29 K in 2024, then flat),
  # and the ocean reads SST, not GMST (sst_obs = 1). Card 5's "held" IRF was +0.20 % at 100 yr and
  # +0.30 % at 300 yr from it. This is the HELD background; ccx_pulse_background() frees it.
  F_fwd <- ccx_hold_climate(F_fwd)
  list(F_hist = F_hist, F_fwd = ccx_pulse_hold_ndep(F_fwd, F_hist))
}

# =====================================================================
# ⭐ THE PD100 CLIMATE: FREE (Joos's protocol, the default) OR HELD -- 2026-10-12
#
# RULED (Marcus 2026-10-12): "free everywhere" -- "if climate/carbon feedbacks are relevant for
# Card 5, they'd also be relevant for the Futures tab", which already runs them (app_run_coupled
# -> ccx_run_coupled). Scope "Builder + live consumers": card 5a, gate L / card 5b, the scorecard,
# tl_land_share and diag_joos_irf.R. Gate L releases at JOOS_PULSE_YR like card 5a ("Release at
# 2015"). Joos et al. 2013 p. 2798: "the climate is evolving freely". The HELD mode is kept, with
# the two fixes above and below, for decompositions and the held-era diagnostics.
#
# FREE, built so that a held-forcing world gets the MODEL's climate after the reference year:
#  * the background GMST comes from the FaIR-fitted climate module, integrated FROM 1750 (so the
#    committed warming is there) on this run's own historical CO2 + FaIR's non-CO2 ERF, then on the
#    HELD CO2 + the non-CO2 ERF held at its reference-year value; spliced to observed GMST over the
#    last CCX_PD_GMST_SPLICE_YR years of the history, as ccx_run_coupled() splices;
#  * the SST columns follow that GMST by ccx_sst_anom_from_gmst()'s ratio rule, seam-matched at the
#    reference year. NOT ccx_sst_anom_from_gmst() itself: it keeps OBSERVED SST through the record's
#    end (2024), i.e. real 2010-2024 warming driven by forcing this experiment holds;
#  * the pulse's OWN warming is iterated to convergence (CLIM_TOL, CLIM_MAX_ITER), as the coupled
#    runner iterates, with GMST piecewise-constant within the year (causal; the spline rings);
#  * T_deep (the stratification lag) is CARRIED across every seam. Without it a free run STOPS
#    (ccx_mix_g_series refuses a varying opening), and a held run silently restarts T_deep at 0
#    (0.148 K at 2010 at hilda29e) -- the second fix.
# Measured at hilda29e (prototype, 2026-10-11): free vs held IRF +4.9 % at 100 yr, +8.3 % at 300;
# almost all of it the pulse's own +0.15 K, the background's warming alone <= 0.2 %.
# =====================================================================
CCX_PD_CLIMATES        <- c("free", "held")
CCX_PD_CLIMATE_DEFAULT <- "free"
CCX_PD_GMST_SPLICE_YR  <- 11L   # = ccx_run_coupled()'s obs splice window (`last - 10 .. last`)

ccx_pd_co2 <- function(o) (o$co2_NH + o$co2_SH) / 2
ccx_pd_annual <- function(t, x) {
  y <- floor(t + 1e-9)
  as.numeric(tapply(x, y, mean))
}

#' Advance a state over a forcing table, carrying T_deep with it
ccx_pulse_continue <- function(sp, F) {
  s2 <- sp
  s2$y <- ccx_run_fast(sp, F)$state
  if (ccx_mix_on(sp$params)) s2$tdeep0 <- ccx_mix_tdeep_after(F$gmst, F$t, sp$params, sp$tdeep0)
  s2
}

#' The reference state at the end of the history, with T_deep and the annual history the free
#' background needs (CO2 from this run, GMST and SST from the table it ran on)
ccx_pulse_ref_state <- function(spin, F_hist) {
  r <- ccx_run_fast(spin, F_hist)
  sp <- spin
  sp$y <- r$state
  if (ccx_mix_on(spin$params)) sp$tdeep0 <- ccx_mix_tdeep_after(F_hist$gmst, F_hist$t, spin$params, spin$tdeep0)
  co2 <- ccx_pd_co2(r$out)
  sp$pd_hist <- list(year = sort(unique(floor(F_hist$t + 1e-9))),
                     # ⚠ (documented 2026-10-12, code review) `co2_end` is the LAST OUTPUT ROW, i.e.
                     # the instantaneous state at t = 2010.958 -- the OPENING state of December 2010,
                     # before that month's step (392.86 ppm at the canonical). The CO2 that
                     # ccx_hold_forcing() then holds is the end-of-history state, 393.62 ppm: the free
                     # background's climate is computed for a CO2 0.76 ppm below the one held.
                     co2 = ccx_pd_annual(r$out$t, co2), co2_end = co2[length(co2)],
                     gmst = ccx_pd_annual(F_hist$t, F_hist$gmst),
                     sst_NH = ccx_pd_annual(F_hist$t, F_hist$sst_anom_NH),
                     sst_SH = ccx_pd_annual(F_hist$t, F_hist$sst_anom_SH))
  sp
}

#' Write an ANNUAL GMST path into a forcing table, with SST following it by the ratio rule
#' seam-matched to the history (or to zero, for a preindustrial background with no history)
ccx_pulse_set_climate <- function(F, g, hist = NULL) {
  ny <- length(g)
  if (nrow(F) != 12L * ny) stop("ccx_pulse_set_climate: ", nrow(F), " rows for ", ny, " years")
  mon <- function(a) ccx_annual_to_monthly(seq_len(ny), a, seq_len(ny), method = "constant")
  if (is.null(hist)) { so <- c(NH = 0, SH = 0); sg <- 0 } else {
    k <- hist$year > max(hist$year) - CCX_SST_SPLICE_YR
    so <- c(NH = mean(hist$sst_NH[k]), SH = mean(hist$sst_SH[k])); sg <- mean(hist$gmst[k])
  }
  F$gmst <- mon(g)
  F$sst_anom_NH <- mon(so[["NH"]] + CCX_SST_RATIO_NH * (g - sg))
  F$sst_anom_SH <- mon(so[["SH"]] + CCX_SST_RATIO_SH * (g - sg))
  F
}

#' The background's climate, FREE or HELD, stamped on the table (attr "pd_climate").
#' `F` is a HELD forward table (ccx_pulse_forcings()$F_fwd, or a preindustrial one at GMST 0).
#' Free with a history: the module's response to the held CO2 (`co2_held`, default the state's
#' own CO2 at the end of the history -- what ccx_hold_forcing() then holds) and the non-CO2 ERF held
#' at its last historical value. ⚠ (2026-10-12, code review) Not quite: the default, `pd_hist$co2_end`,
#' is the Dec-2010 OPENING state (392.86 ppm at the canonical), while ccx_hold_forcing() holds the
#' end-of-history state (393.62) -- 0.76 ppm apart; see ccx_pulse_ref_state(). Free with NO history (a preindustrial background): the forcing
#' anomaly is zero, so the background stays at GMST 0 -- only the pulse warms.
#' `coupled = TRUE` is for a background whose CO2 is NOT held (diag_joos_irf.R's "decaying" rows):
#' its GMST must follow its OWN CO2, so the run and the climate are iterated as ccx_run_coupled()
#' iterates. A preindustrial background (no history) is the spun-up equilibrium and stays at GMST 0
#' either way: with zero emissions its CO2 does not move.
ccx_pulse_background <- function(sp_ref, F, climate = CCX_PD_CLIMATE_DEFAULT, co2_held = NULL,
                                 coupled = FALSE) {
  climate <- match.arg(climate, CCX_PD_CLIMATES)
  if (climate == "free") {
    h <- sp_ref$pd_hist
    ny <- nrow(F) / 12
    if (is.null(h)) {
      if (any(F$gmst != 0)) stop("ccx_pulse_background: no history and a non-zero GMST -- not a preindustrial background")
      F <- ccx_pulse_set_climate(F, rep(0, ny), NULL)
    } else {
      mod <- ccx_climate_module()
      nh <- length(h$year)
      nc <- ccx_erf_nonco2("historical", h$year)
      w <- h$year > max(h$year) - CCX_PD_GMST_SPLICE_YR
      gmst_of <- function(co2_fwd) {             # annual forward CO2 -> annual forward GMST
        erf <- c(ccx_erf_co2(h$co2, mod) + nc, ccx_erf_co2(co2_fwd, mod) + nc[nh])
        Tm <- ccx_temperature_from_erf(erf, seq(h$year[1], length.out = length(erf)), mod)
        off <- mean(h$gmst[w]) - mean(Tm[seq_len(nh)][w])
        list(g = Tm[nh + seq_len(ny)] + off, off = off)
      }
      c_hold <- if (is.null(co2_held)) h$co2_end else co2_held
      gg <- gmst_of(rep(c_hold, ny)); it <- 0L; delta <- 0
      if (isTRUE(coupled)) repeat {
        it <- it + 1L
        r <- ccx_run_fast(sp_ref, ccx_pulse_set_climate(F, gg$g, h))$out
        new <- gmst_of(ccx_pd_annual(r$t, ccx_pd_co2(r)))
        delta <- max(abs(new$g - gg$g)); gg <- new
        if (delta < CLIM_TOL || it >= CLIM_MAX_ITER) break
      }
      if (isTRUE(coupled) && delta >= CLIM_TOL)
        warning(sprintf("ccx_pulse_background: the coupled background did not converge (%.2e K)", delta), call. = FALSE)
      F <- ccx_pulse_set_climate(F, gg$g, h)
      attr(F, "pd_bkg") <- list(co2_held = if (isTRUE(coupled)) NA_real_ else c_hold, coupled = isTRUE(coupled),
                                iter = it, erf_nonco2_held = nc[nh], splice_offset = gg$off)
    }
  }
  attr(F, "pd_climate") <- climate
  F
}

#' Baseline and pulse runs on one background. FREE: the pulse's own warming is fed back, iterated
#' to convergence; HELD: both runs see the background's climate. Returns the two full outputs.
ccx_pulse_pair <- function(sp, F, pulse = JOOS_PULSE, climate = attr(F, "pd_climate")) {
  if (is.null(climate)) stop("ccx_pulse_pair: the table carries no pd_climate; build it with ccx_pulse_background()")
  climate <- match.arg(climate, CCX_PD_CLIMATES)
  b <- ccx_run_fast(sp, F)$out
  spp <- ccx_pulse_state(sp, pulse)
  if (climate == "held")
    return(list(b = b, q = ccx_run_fast(spp, F)$out, dT = NULL, iter = 0L, converged = TRUE))
  mod <- ccx_climate_module()
  ny <- nrow(F) / 12
  if (ny != round(ny)) stop("ccx_pulse_pair: the table is not whole years")
  mon <- function(a) ccx_annual_to_monthly(seq_len(ny), a, seq_len(ny), method = "constant")
  erf_b <- ccx_erf_co2(ccx_pd_annual(b$t, ccx_pd_co2(b)), mod)
  dT <- rep(0, ny); it <- 0L
  repeat {
    it <- it + 1L
    dm <- mon(dT); Fq <- F
    Fq$gmst <- F$gmst + dm
    Fq$sst_anom_NH <- F$sst_anom_NH + CCX_SST_RATIO_NH * dm
    Fq$sst_anom_SH <- F$sst_anom_SH + CCX_SST_RATIO_SH * dm
    q <- ccx_run_fast(spp, Fq)$out
    new <- ccx_climate_irf_filter(ccx_erf_co2(ccx_pd_annual(q$t, ccx_pd_co2(q)), mod) - erf_b, mod)
    delta <- max(abs(new - dT)); dT <- new
    if (delta < CLIM_TOL || it >= CLIM_MAX_ITER) break
  }
  if (delta >= CLIM_TOL)
    warning(sprintf("ccx_pulse_pair: the pulse's warming did not converge (%.2e K after %d passes)", delta, it),
            call. = FALSE)
  list(b = b, q = q, dT = dT, iter = it, converged = delta < CLIM_TOL)
}
