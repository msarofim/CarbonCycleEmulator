# =====================================================================
# diag_joos_beta_scan.R -- diag_joos_irf.R, truncated after part 4, with
# beta overridable from the environment. WRITTEN 2026-08-14 for the
# architecture review (notes/review_2026-08-14_architecture.md sec.4.1).
#
# THE QUESTION: DESIGN sec.6 gate 12 is a HARD gate, its recorded status was
# measured at beta 0.38, and the default has moved twice since. At which beta
# does the gate actually pass?
#
# MEASURED (integrated IRF, yr, TH 20/50/100, against Joos Table 4's
# 5-95 % of 12.2-16.3 / 24.0-36.6 / 39.5-65.2):
#
#   beta 0.30   13.8  29.8  51.2   inside
#   beta 0.40   13.0  27.3  46.0   inside
#   beta 0.50   12.2  25.0  41.1   inside -- but TH20 is EXACTLY the 5th pct
#   beta 0.60   11.5  22.8  36.8   FAIL at all three
#   beta 0.75   10.4  19.9  31.2   FAIL at all three   <-- the shipped default
#
# The ceiling this puts on beta (~0.50) agrees with the INDEPENDENT ceiling
# the Pulse Lab's Revelle lesson puts on it (~0.53, handoff 13i sec.A1).
# Neither was used to set the default, which tracks the CO2 record alone.
#
# USAGE:  CCX_JOOS_BETA=0.50 Rscript calibration/diag_joos_beta_scan.R
#         (unset -> ccx_default_params()$beta).  RUNTIME ~4 min per beta.
#
# THIS IS A PROBE, NOT A REPLACEMENT. diag_joos_irf.R remains the canonical
# gate; it carries parts 5-6 and the full protocol discussion. Everything
# below this banner is that file verbatim through part 4.
# =====================================================================

# =====================================================================
# diag_joos_irf.R -- the model's CO2 pulse response against the Joos et al.
# (2013) multi-model mean. HEADLINE: THE MODEL'S PULSE DECAYS TOO FAST, AND IT
# DOES SO IN THE DIRECTION THAT UNDERSTATES THE ARGUMENT THE APP IS BUILT ON.
#
# WRITTEN 2026-08-13 on Marcus' instruction, discharging recommendation R7 of
# notes/expertpanel_2026-08-13_structure_for_pedagogy.md: DESIGN sec.6's eleven
# sanity gates score sinks, seasonality, the bomb curve and the interhemispheric
# gradient -- but NOTHING scores the pulse response, which is the quantity the
# app's flagship "How long does it last?" panel reports. That was a hole in the
# gate list independent of which way the comparison came out.
#
# THE BENCHMARK. Joos F, et al. (2013), "Carbon dioxide and climate impulse
# response functions for the computation of greenhouse gas metrics: a
# multi-model analysis", Atmos. Chem. Phys. 13:2793-2825,
# doi:10.5194/acp-13-2793-2013. 15 models + 3 model ensembles. PDF in
# ~/Documents/2026/ClaudeDocs/Papers/ (Marcus, 2026-08-13).
#
#   Table 5 gives the multi-model-mean IRF as a sum of exponentials (fit valid
#   0 < t < 1000 yr, mean relative error 0.6 %), and Table 4 the time-integrated
#   IRF with 5-95 % ranges. Both are for PD100: 100 GtC onto a background held
#   at 389 ppm.
#
# THE PROTOCOL MATTERS AND IS REPRODUCED, NOT APPROXIMATED. Joos's run 1 holds
# atmospheric CO2 FIXED after 2010 and diagnoses the compatible emissions; run 3
# adds the pulse to that. A baseline that is instead left to DECAY (emissions
# cut to zero) is a different experiment: the ocean and land keep drawing down,
# the Revelle factor keeps falling, and the pulse decays into a background that
# is itself emptying. This file therefore diagnoses compatible emissions online
# -- at each month the emission is set to exactly cancel the atmospheric
# tendency -- so the background really is constant. Part 4 measures what that
# choice is worth, because it is not small.
#
# RESULT (default parameters, NOT the posterior mode). TWO ANSWERS, and they
# point different ways, so both are reported and neither is buried:
#
#   [A] POINT IRF -- the model is BELOW the multi-model mean at every horizon:
#       yr                20      50     100     300
#       this model     0.531   0.397   0.313   0.212
#       Joos Table 5   0.596   0.487   0.409   0.322
#       So the recollection recorded in the panel note as an UNVERIFIED test to
#       run ("~0.4 at year 100") is CONFIRMED BY THE PAPER: 0.409. The model's
#       pulse does decay faster than the multi-model mean.
#
#   [B] TIME-INTEGRATED IRF -- the quantity Joos actually puts ranges on -- is
#       INSIDE the 5-95 % confidence range at every horizon:
#       TH               20      50     100
#       this model     12.6    26.2    43.6
#       Joos best      14.2    30.3    52.4
#       Joos 5-95 % 12.2-16.3 24.0-36.6 39.5-65.2
#
# THE HONEST HEADLINE IS [B] WITH [A] AS THE CAVEAT: the model sits on the LOW
# SIDE of the literature but within it. An earlier draft of the panel note said
# flatly that the pulse "decays too fast"; that overstates it. What is true is
# that the model is low at every horizon and increasingly so with time -- 0.212
# against 0.322 at 300 yr -- which is where its lack of an ocean-sediment /
# weathering module tells, since Joos's multi-millennial asymptote a0 = 0.217 is
# a route this model does not have.
#
# THE DIRECTION IS CONSERVATIVE FOR THE APP'S ARGUMENT, and that must be said
# rather than left for a reader to find: the app argues that added carbon
# persists for centuries, and a model on the low side of the literature makes
# that case WEAKER than the literature supports, not stronger.
#
# [C] THE BACKGROUND PROTOCOL IS WORTH MORE THAN THE MODEL-VS-JOOS GAP.
#       PD held 46.3 yr | PD decaying 44.3 | PI held 39.2 | PI decaying 39.2
#     Joos sec.4.4.1 across the 10 models that ran both: PI 34-47, PD 45-62.
#     THE MODEL IS INSIDE BOTH AND REPRODUCES THE PI < PD ORDERING, which is a
#     Revelle result -- a fuller ocean buffers less, so a pulse lasts longer.
#     (PI held and PI decaying are IDENTICAL because a preindustrial background
#     with zero emissions is already at steady state, so the diagnosed holding
#     emissions are ~0. That is a free internal consistency check, not a bug.)
#
# [D] FUTURE BACKGROUNDS (Marcus asked). 100 GtC in 2050, COUPLED climate:
#       ssp126  IRF@100 0.342, int 49.6 | ssp245 0.397, 54.3
#       ssp370  IRF@100 0.480, int 59.7 | ssp585 0.512, 62.8
#     Monotonic in background, and IRF@20 = 0.62-0.71 against Joos's statement
#     that IRF falls to ~70 % within two decades in EVERY scenario. The ORDERING
#     is the testable claim; the level is out of sample for a model calibrated
#     to the historical record, which is Marcus' own caveat.
#
# RUNTIME ~40 s.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
JOOS_PULSE     <- 100          # GtC, Joos's standard impulse
JOOS_PPM_PER   <- 2.123        # GtC per ppm, the conversion Joos states
JOOS_REF_YEAR  <- 2010         # Joos run 1: CO2 held fixed after this year
JOOS_PULSE_YR  <- 2015         # Joos run 3: pulse released here
JOOS_HORIZON   <- 300          # yr followed (Joos goes to 1000; the app does not)
JOOS_TH        <- c(20, 50, 100)
JOOS_MARKS     <- c(20, 50, 100, 300)

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

p0 <- ccx_default_params()
p0$beta <- as.numeric(Sys.getenv("CCX_JOOS_BETA", unset = as.character(p0$beta)))
cat(sprintf("\n########## diag_joos_beta_scan: beta = %.3f ##########\n", p0$beta))
spin <- ccx_spinup(p0)

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

# Historical spin-up to the reference year, then the held background.
F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14)
sp_ref <- spin
sp_ref$y <- ccx_run_fast(spin, F_hist)$state

F_fwd <- suppressWarnings(
  ccx_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + JOOS_HORIZON + 10),
                    prod_c14 = spin$prod_c14, bomb_total_kmol = 0))
for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
             "c14_bomb", "c14_nuclear")) F_fwd[[cc]] <- 0
F_fwd$gmst <- F_fwd$gmst[1]          # climate held at the reference year

F_hold <- ccx_hold_forcing(sp_ref, F_fwd, verbose = TRUE)
o_pd   <- ccx_irf(sp_ref, F_hold)
# Joos releases the pulse 5 yr after the reference year, on an already-settled
# background; shift the clock so t = 0 is the release.
shift  <- JOOS_PULSE_YR - JOOS_REF_YEAR
o_pd$t <- o_pd$t - shift
keep   <- o_pd$t >= 0
irf    <- o_pd$irf[keep]; irf_t <- o_pd$t[keep]

cat(sprintf("\n=== 1. BACKGROUND CHECK (Joos run 1: CO2 held constant) ===\n"))
cat(sprintf("  target %.2f ppm; max deviation over %d yr: %.3f ppm (%.2f %%)\n",
            attr(F_hold, "target"), JOOS_HORIZON, attr(F_hold, "dev"),
            100 * attr(F_hold, "dev") / attr(F_hold, "target")))
cat(sprintf("  Joos's PD100 background is 389 ppm; this model's is %.0f ppm at %d.\n",
            attr(F_hold, "target"), JOOS_REF_YEAR))

at_yr <- function(v, tt, y) v[which.min(abs(tt - y))]
cat("\n=== 2. POINT IRF vs JOOS TABLE 5 (multi-model mean) ===\n")
cat(sprintf("%8s %12s %12s %10s\n", "yr", "this model", "Joos T5", "diff"))
for (y in JOOS_MARKS) {
  m <- at_yr(irf, irf_t, y); j <- joos_irf(y)
  cat(sprintf("%8.0f %12.3f %12.3f %+10.3f\n", y, m, j, m - j))
}

integ <- function(o, th) { k <- o$t <= th & o$t >= 0
  sum(diff(o$t[k]) * (utils::head(o$irf[k], -1) + utils::tail(o$irf[k], -1)) / 2) }
o_pd_shifted <- list(t = irf_t, irf = irf)
cat("\n=== 3. TIME-INTEGRATED IRF vs JOOS TABLE 4 (yr) ===\n")
cat(sprintf("%6s %12s %12s %18s  %s\n", "TH", "this model", "Joos best", "Joos 5-95 %", "verdict"))
for (i in seq_len(nrow(JOOS_T4))) {
  th <- JOOS_T4$th[i]; m <- integ(o_pd_shifted, th)
  cat(sprintf("%6.0f %12.1f %12.1f %8.1f - %-7.1f  %s\n", th, m, JOOS_T4$best[i],
              JOOS_T4$lo[i], JOOS_T4$hi[i],
              if (m >= JOOS_T4$lo[i] && m <= JOOS_T4$hi[i]) "inside"
              else if (m < JOOS_T4$lo[i]) "BELOW -- decays too fast"
              else "ABOVE -- decays too slowly"))
}

# ---------------------------------------------------------------------
# 4. What the BACKGROUND PROTOCOL is worth -- held vs decaying, PD vs PI.
# Joos sec. 4.4.1 reports 34-47 yr (PI) against 45-62 yr (PD) at TH = 100.
# ---------------------------------------------------------------------
F_pi <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1750 + JOOS_HORIZON + 10),
                                           prod_c14 = spin$prod_c14, bomb_total_kmol = 0))
for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
             "c14_bomb", "c14_nuclear")) F_pi[[cc]] <- 0
F_pi$gmst <- 0

cases <- list(
  "PD, background HELD"     = list(sp = sp_ref, F = ccx_hold_forcing(sp_ref, F_fwd)),
  "PD, background decaying" = list(sp = sp_ref, F = F_fwd),
  "PI, background HELD"     = list(sp = spin,   F = ccx_hold_forcing(spin, F_pi)),
  "PI, background decaying" = list(sp = spin,   F = F_pi))
cat("\n=== 4. THE BACKGROUND PROTOCOL IS NOT A DETAIL ===\n")
cat(sprintf("%-26s %8s %8s %8s | %14s\n", "case", "IRF@20", "IRF@100", "IRF@300",
            "int IRF @100"))
for (nm in names(cases)) {
  cc <- cases[[nm]]; o <- ccx_irf(cc$sp, cc$F)
  cat(sprintf("%-26s %8.3f %8.3f %8.3f | %14.1f\n", nm,
              at_yr(o$irf, o$t, 20), at_yr(o$irf, o$t, 100),
              at_yr(o$irf, o$t, 300), integ(o, 100)))
}
cat(sprintf("  Joos sec.4.4.1, integrated IRF at TH=100 across 10 models:\n"))
cat(sprintf("    preindustrial background %d-%d yr ; present-day %d-%d yr\n",
            JOOS_PI100_100[1], JOOS_PI100_100[2], JOOS_PD100_100[1], JOOS_PD100_100[2]))
cat("  The PI-lower-than-PD ordering is Joos's own and the model must reproduce\n")
cat("  the SIGN of it: a fuller ocean buffers less, so a pulse lasts longer.\n")

# ---------------------------------------------------------------------
# 5. FUTURE BACKGROUNDS -- Marcus' question.
# Joos explored this with ONE model (Bern3D-LPJ, RCP2.6-8.5, their Fig. 5) and
# found IRF_CO2 rises again after ~2 decades under the high scenarios, staying
# above 80 % at year 1000 for RCP8.5. The point of repeating it here is NOT to
# match Joos -- a model tuned to the historical record cannot be expected to
# match complex models out of sample, which is Marcus' own caveat -- but to
# establish whether the model reproduces the ORDERING and the mechanism.
# ---------------------------------------------------------------------
SSPS         <- c("ssp126", "ssp245", "ssp370", "ssp585")
PULSE_YR_FUT <- 2050
FUT_END      <- 2300

# THE CLIMATE IS COUPLED HERE, and it has to be. ccx_build_forcing() holds GMST
# FLAT at the last observation, so a bare SSP5-8.5 run to 2300 would take CO2 to
# ~530 ppm while pinning the temperature at its 2024 value -- suppressing the
# q10 respiration and ocean-solubility feedbacks entirely. Those feedbacks are
# precisely the mechanism Joos's Fig. 5 attributes the rising IRF to, so holding
# them off would have been measuring the wrong thing. ccx_run_coupled()
# (R/climate.R) computes temperature from the model's own CO2 via a FaIR-fitted
# module and overwrites the column.
#
# THE PULSE IS PAIRED THROUGH THE COUPLING, not applied to a fixed-climate
# baseline: pulse and baseline are each run coupled, so the pulse's own warming
# feeds back on its own decay. That is what Joos's models do.
# THE SSP EMISSIONS TABLE IS DECADAL, NOT ANNUAL, AND THAT IS A TRAP.
# data/ssp_emissions.rds carries ~5-yearly points early and 10-yearly later.
# Adding `pulse` to the 2050 ROW and letting ccx_annual_to_monthly() interpolate
# spreads it as a triangle over 2046-2054 and delivers TEN TIMES the intended
# mass -- measured: 1000.0 GtC for a nominal 100, and the resulting IRF came out
# at 6.9, i.e. impossible-by-inspection (an IRF cannot exceed 1). The table is
# therefore DENSIFIED TO ANNUAL first, so the pulse occupies exactly one year and
# the linear interpolation on either side integrates to exactly `pulse`.
