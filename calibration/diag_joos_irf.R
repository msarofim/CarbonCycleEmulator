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
# RUNTIME ~7 s (the ~40 s recorded here was measured before ccx_run_fast).
#
# USAGE:  Rscript calibration/diag_joos_irf.R [defaults|N|D]      (default: defaults)
#
# [E] AT THE SHIPPED MODE, ADDED 2026-08-22 -- AND THE GATE FAILS THERE.
#     app/global.R has run on mode_fit_pumpN.rds since 8b94ba4 (2026-08-21),
#     while this file was hardcoded to ccx_default_params(); the 2026-08-22
#     expert panel ranked that #7 on its merged defect list. Integrated IRF:
#       TH            20       50      100
#       defaults   12.43    25.53    41.86   (+1.92 / +6.39 / +5.96 % of floor)
#       arm N      11.74    23.97    39.36   (-3.73 / -0.13 / -0.35 %)
#     TH 20 is a substantive miss; TH 50 and TH 100 land ON the floor to within a
#     third of a percent and should be quoted as "at the floor". The mode's held
#     background is 394.4 ppm against the defaults' 387.6, and a HIGHER background
#     makes a pulse last LONGER (part 4 measures it), so the mode fails IN SPITE
#     of a background biasing it the other way. See DESIGN sec.6 gate 12.
#
#     AND [C] BELOW IS NOW STALE, which is the same failure the gate's own History
#     paragraph records: "the model is INSIDE BOTH" was measured at beta 0.38. At
#     today's defaults PI-held is 25.6 against Joos's 34-47, i.e. OUTSIDE; at the
#     mode it is 33.9, just below. The PI < PD ORDERING -- which is what DESIGN
#     actually gates -- still passes at both. Left in place and flagged rather
#     than quietly rewritten, because it is a claim about a measurement.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
# Joos's own numbers -- the protocol constants, the Table 5 IRF fit and the
# Table 4 integrated-IRF ranges -- are in R/joos_irf.R, sourced above. They were
# byte-identical in both diag_joos_* scripts before being promoted 2026-08-18.
JOOS_HORIZON   <- 300          # yr followed (Joos goes to 1000; the app does not)
JOOS_MARKS     <- c(20, 50, 100, 300)



# ---- WHICH PARAMETER VECTOR? (added 2026-08-22) ----------------------
# UNTIL TODAY THIS LINE READ `p0 <- ccx_default_params()` AND NOTHING ELSE, so
# gate 12's DESIGN sec.6 status line -- and every quotation of it -- described
# the DEFAULTS while `app/global.R` has shipped the posterior mode since
# 2026-08-21 (`8b94ba4`). That is the same failure the gate's own History
# paragraph records twice: "it is not a description, it is a measurement".
# The 2026-08-14 status line passes at TH 20 by 12.4 against a 12.2 floor --
# 1.6 %, the tightest of the three horizons and tighter than the 6 % at TH 100
# -- so the vector actually shipped had to be measured, not assumed.
#
# THE TWO FORCING PARAMETERS ARE THE TRAP, and it is the one `diag_app_params.R`
# already priced at 5.79 ppm of 2024 CO2. `bomb_total` and `luc_scale` are
# fitted but have no slot in ccx_default_params(); ccx_make_logpost() applies
# them by rescaling forcing COLUMNS. A mode path that overlays par_mode and then
# calls ccx_build_forcing() bare would run the fitted parameters against a
# forcing the fit never saw -- and here that forcing sets the 2010 background
# the whole Joos protocol is conditioned on, which is the Revelle lever the
# result is most sensitive to. Hence the wrapper below, the same construction
# and for the same reason as app_build_forcing() in app/global.R.
JOOS_ARM_DEFAULT <- "defaults"
JOOS_ARM_FILE    <- "calibration/output/pump_arms/mode_fit_pump%s.rds"
JOOS_ARM <- (function(a) if (length(a) && a[1] %in% c("N", "D", "defaults")) a[1]
             else JOOS_ARM_DEFAULT)(commandArgs(TRUE))

p0 <- ccx_default_params()
JOOS_LUC_SCALE  <- 1
JOOS_BOMB_TOTAL <- 102
JOOS_SRC <- "uncalibrated defaults"
if (JOOS_ARM != "defaults") {
  .md <- readRDS(sprintf(JOOS_ARM_FILE, JOOS_ARM))
  stopifnot(identical(.md$param_names, CCX_PARAM_NAMES))   # the 21-name guard
  .pm <- .md$par_mode
  for (n in intersect(names(p0), CCX_PARAM_NAMES)) p0[[n]] <- .pm[[n]]
  p0$gamma_enso <- .pm$gamma_enso
  p0$pump_mode  <- .md$pump_mode
  JOOS_LUC_SCALE  <- .pm$luc_scale
  JOOS_BOMB_TOTAL <- .pm$bomb_total
  JOOS_SRC <- sprintf("posterior mode, arm %s (%s, logpost %.2f)",
                      JOOS_ARM, basename(sprintf(JOOS_ARM_FILE, JOOS_ARM)), .md$logpost)
}

#' ccx_build_forcing() with THIS RUN'S fitted forcing parameters applied
#' Only fills what the caller left unset, so the protocol's own explicit
#' `bomb_total_kmol = 0` (14C is irrelevant to the IRF) still wins.
joos_build_forcing <- function(scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- JOOS_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- JOOS_LUC_SCALE
  do.call(ccx_build_forcing, c(list(scenario, years), args))
}
joos_run_coupled <- function(spin, scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- JOOS_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- JOOS_LUC_SCALE
  do.call(ccx_run_coupled, c(list(spin, scenario, years), args))
}

cat(sprintf("\n=== 0. PARAMETER VECTOR UNDER TEST ===\n  %s\n", JOOS_SRC))
cat(sprintf("  luc_scale %.4f   bomb_total %.2f kmol   pump_mode %s\n",
            JOOS_LUC_SCALE, JOOS_BOMB_TOTAL, p0$pump_mode))
cat(sprintf("  beta_max %.4f  fert_k %.1f  q10 %.3f  h_ml %.2f  kz %.0f\n",
            p0$beta_max, p0$fert_k, p0$q10, p0$h_ml, p0$kz))

spin <- ccx_spinup(p0)

# The Joos protocol helpers -- ccx_set_emissions, ccx_hold_forcing,
# ccx_pulse_state, ccx_irf, and the JOOS_PULSE / JOOS_PPM_PER / JOOS_HOLD_*
# constants -- now live in R/joos_irf.R and arrive via the source() loop above.
# They were duplicated here and in the other diag_joos_* script; the two copies
# were verified byte-identical before being promoted, so nothing this script
# prints has changed. Do NOT re-inline them: a local copy that drifts would
# silently make the two diagnostics disagree about the same protocol.

# Historical spin-up to the reference year, then the held background.
F_hist <- joos_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14)
sp_ref <- spin
sp_ref$y <- ccx_run_fast(spin, F_hist)$state

F_fwd <- suppressWarnings(
  joos_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + JOOS_HORIZON + 10),
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
# MARGIN TO THE FLOOR IS PRINTED, AND AT TWO DECIMALS, because this gate is
# decided in its last significant figure: at the posterior mode TH 50 lands on
# 24.0 against a floor of 24.0 and TH 100 on 39.4 against 39.5. A one-decimal
# table cannot be quoted for a pass/fail on those two rows, and this gate's
# recorded status has already been stale twice (see DESIGN sec.6 gate 12's own
# History paragraph). The margin is signed and relative to the FLOOR, since
# that is the bound the model is near -- it has never been near the ceiling.
cat("\n=== 3. TIME-INTEGRATED IRF vs JOOS TABLE 4 (yr) ===\n")
cat(sprintf("%6s %12s %12s %18s %10s  %s\n", "TH", "this model", "Joos best",
            "Joos 5-95 %", "vs floor", "verdict"))
for (i in seq_len(nrow(JOOS_T4))) {
  th <- JOOS_T4$th[i]; m <- integ(o_pd_shifted, th)
  cat(sprintf("%6.0f %12.2f %12.1f %8.1f - %-7.1f %+9.2f%%  %s\n", th, m, JOOS_T4$best[i],
              JOOS_T4$lo[i], JOOS_T4$hi[i], 100 * (m - JOOS_T4$lo[i]) / JOOS_T4$lo[i],
              if (m >= JOOS_T4$lo[i] && m <= JOOS_T4$hi[i]) "inside"
              else if (m < JOOS_T4$lo[i]) "BELOW -- decays too fast"
              else "ABOVE -- decays too slowly"))
}

# ---------------------------------------------------------------------
# 3b. GATE 12b -- THE TAIL. Added 2026-08-25 (Marcus).
#
# Section 3 cannot do its job alone: BOTH published single-exponential
# carbon-cycle models pass it at all three horizons (see R/joos_irf.R's
# JOOS_TAIL block for the numbers and notes/lit_2026-08-25_co2_lifetime_
# confusion.md for the provenance). The first century is where the wrong
# STRUCTURE looks right, so the gate has to reach past it.
#
# The statistic is IRF(300)/IRF(100). For any single exponential this equals
# IRF(100)^2 EXACTLY, whatever the time constant -- a parameter-free null. A
# model with a real long tail sits far above its own locus value.
# ---------------------------------------------------------------------
cat("\n=== 3b. GATE 12b: THE TAIL, IRF(300)/IRF(100) ===\n")
tail_m  <- joos_tail_ratio(irf_t, irf)
null_m  <- joos_tail_null(at_yr(irf, irf_t, JOOS_TAIL_TH[1]))
cat(sprintf("  %-44s %8s %10s %s\n", "", "ratio", "own null", "verdict"))
cat(sprintf("  %-44s %8.4f %10.4f %s\n", "THIS MODEL", tail_m, null_m,
            if (tail_m >= JOOS_TAIL_BAND[1] && tail_m <= JOOS_TAIL_BAND[2]) "inside"
            else if (tail_m < JOOS_TAIL_BAND[1]) "BELOW -- tail too thin"
            else "ABOVE -- tail too fat"))
cat(sprintf("  %-44s %8.4f %10.4f %s\n", "Joos et al. 2013 Table 5", JOOS_TAIL_REF,
            joos_tail_null(joos_irf(JOOS_TAIL_TH[1])), "-- the benchmark"))
for (nm in names(JOOS_ONEBOX)) { f <- JOOS_ONEBOX[[nm]]
  cat(sprintf("  %-44s %8.4f %10.4f %s\n", nm, f(300) / f(100), f(100)^2,
              "ON its own null, by construction")) }
cat(sprintf("\n  band [%.4f, %.4f] -- CONSTRUCTED: Joos publishes no 5-95%% range at\n",
            JOOS_TAIL_BAND[1], JOOS_TAIL_BAND[2]))
cat("  TH 300, so Table 4's TH-100 relative width is borrowed. That is an\n")
cat("  assumption and it is stated, not silently adopted. The DISCRIMINATION does\n")
cat(sprintf("  not rest on it: the one-box models sit %.0fx and %.0fx below even the\n",
            JOOS_TAIL_BAND[1] / (JOOS_ONEBOX[[1]](300) / JOOS_ONEBOX[[1]](100)),
            JOOS_TAIL_BAND[1] / (JOOS_ONEBOX[[2]](300) / JOOS_ONEBOX[[2]](100))))
cat("  loosest end, and every single exponential lies ON the null by construction.\n")
cat(sprintf("\n  MUTATION TEST of this gate, because passing is not the same as working:\n"))
cat(sprintf("    a single exponential tuned to THIS MODEL's own IRF(100) = %.4f\n",
            at_yr(irf, irf_t, JOOS_TAIL_TH[1])))
cat(sprintf("    would score %.4f and the gate must REJECT it: %s\n", null_m,
            if (null_m < JOOS_TAIL_BAND[1]) "REJECTED. OK" else "*** NOT REJECTED -- GATE IS BROKEN ***"))
stopifnot(null_m < JOOS_TAIL_BAND[1])
cat(sprintf("\n  and the ASYMPTOTE, which is what the ratio is really testing:\n"))
cat(sprintf("    fraction still airborne at 300 yr: model %.3f vs Joos T5 %.3f\n",
            at_yr(irf, irf_t, 300), joos_irf(300)))
cat(sprintf("    Joos T5's t -> infinity limit is a0 = %.4f; a single exponential's is 0.\n",
            JOOS_T5$a0))

# ---------------------------------------------------------------------
# 4. What the BACKGROUND PROTOCOL is worth -- held vs decaying, PD vs PI.
# Joos sec. 4.4.1 reports 34-47 yr (PI) against 45-62 yr (PD) at TH = 100.
# ---------------------------------------------------------------------
F_pi <- suppressWarnings(joos_build_forcing("historical", c(1750, 1750 + JOOS_HORIZON + 10),
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
# The delivered mass is ASSERTED below, not trusted.
JOOS_PULSE_TOL <- 0.5           # GtC, tolerance on the delivered pulse mass

fut_emissions <- function(sc, pulse = 0) {
  em <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
  em <- em[em$scenario == sc, c("year", "fossil_GtC", "luc_GtC")]
  yrs <- seq(min(em$year), max(em$year))
  d <- data.frame(year = yrs,
                  fossil_GtC = stats::approx(em$year, em$fossil_GtC, yrs)$y,
                  luc_GtC    = stats::approx(em$year, em$luc_GtC,    yrs)$y)
  if (pulse != 0) d$fossil_GtC[d$year == PULSE_YR_FUT] <-
                    d$fossil_GtC[d$year == PULSE_YR_FUT] + pulse
  d
}

fut_irf <- function(sc, pulse = 0) {
  em <- fut_emissions(sc, pulse)
  if (pulse != 0) {
    delivered <- local({
      f0 <- suppressWarnings(joos_build_forcing(sc, c(1750, FUT_END), prod_c14 = 0,
                                               emissions = fut_emissions(sc, 0)))
      f1 <- suppressWarnings(joos_build_forcing(sc, c(1750, FUT_END), prod_c14 = 0,
                                               emissions = em))
      sum((f1$e_foss_NH + f1$e_foss_SH) - (f0$e_foss_NH + f0$e_foss_SH)) / 12
    })
    if (abs(delivered - pulse) > JOOS_PULSE_TOL)
      stop(sprintf("pulse mass wrong: %.1f GtC delivered for a nominal %.1f (%s)",
                   delivered, pulse, sc))
  }
  r <- joos_run_coupled(spin, scenario = sc, years = c(1750, FUT_END), emissions = em)
  o <- r$out
  list(t = o$t - PULSE_YR_FUT, co2 = (o$co2_NH + o$co2_SH) / 2,
       clim = r$climate, converged = r$converged)
}

cat("\n=== 5. PULSES ON FUTURE BACKGROUNDS (100 GtC in 2050, COUPLED climate) ===\n")
cat(sprintf("%-9s %9s %8s %8s %8s %8s | %12s\n", "scenario", "CO2@2050",
            "T@2100", "IRF@20", "IRF@50", "IRF@100", "int IRF @100"))
for (sc in SSPS) {
  b <- try(fut_irf(sc), silent = TRUE)
  if (inherits(b, "try-error")) { cat(sprintf("%-9s  unavailable\n", sc)); next }
  q <- fut_irf(sc, JOOS_PULSE)
  o <- list(t = b$t, irf = (q$co2 - b$co2) / (JOOS_PULSE / JOOS_PPM_PER))
  k <- o$t >= 0; o <- list(t = o$t[k], irf = o$irf[k])
  # GUARD. sprintf() with a ZERO-LENGTH argument returns character(0) and cat()
  # then prints NOTHING -- so a mistyped field name drops the row silently
  # rather than erroring. That happened here (r$gmst vs r$climate$gmst) and the
  # table came out empty with exit status 0. Never let a row vanish quietly.
  vals <- list(co2 = b$co2[which.min(abs(b$t))],
               t21 = b$clim$gmst[b$clim$year == 2100],
               i20 = at_yr(o$irf, o$t, 20), i50 = at_yr(o$irf, o$t, 50),
               i100 = at_yr(o$irf, o$t, 100), int = integ(o, 100))
  if (any(lengths(vals) != 1L))
    stop("diag_joos_irf part 5: zero-length value(s) for ", sc, ": ",
         paste(names(vals)[lengths(vals) != 1L], collapse = ", "))
  cat(sprintf("%-9s %9.0f %8.2f %8.3f %8.3f %8.3f | %12.1f%s\n", sc,
              vals$co2, vals$t21, vals$i20, vals$i50, vals$i100, vals$int,
              if (isTRUE(b$converged)) "" else "  [climate loop NOT converged]"))
}
cat("\n  Joos (Bern3D-LPJ, Fig. 5): IRF_CO2 falls to ~70 % within two decades in\n")
cat("  EVERY scenario, then keeps falling for RCP2.6 and the 389 ppm standard but\n")
cat("  turns back UP for the higher pathways as CO2 and warming continue to rise;\n")
cat("  for RCP8.5 the airborne fraction of the pulse is still above 80 % at year\n")
cat("  1000. THE ORDERING IS THE TESTABLE CLAIM HERE, NOT THE LEVEL -- a model\n")
cat("  calibrated to the historical record is out of sample in these futures, and\n")
cat("  Marcus made exactly that caveat when asking for the comparison.\n")
