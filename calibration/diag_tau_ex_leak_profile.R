# =====================================================================
# diag_tau_ex_leak_profile.R -- DOES `tau_ex` HAVE ANY POWER OVER THE
#                               SPO SEASONAL PARTITION?
#
# THE QUESTION (prereg 2026-08-27e; handoff 27d sec.5 item 2). 72 % of the
# model's SPO seasonal cycle is made in the NORTHERN hemisphere and arrives
# through `tau_ex`, and the model's SPO land component is 2.01x observed. So
# `tau_ex` looks like a lever on the partition. It is not obvious that it is
# one: BOTH parts of the model's SPO cycle carry the LAND signature -- the
# leak is NH land (0.0516 permil/ppm) and the local part is SH land (0.0583)
# -- so moving carbon between them relabels WHERE the cycle was made without
# changing WHAT made it. This profile measures whether that argument holds,
# rather than asserting it.
#
# TWO RUNS PER NODE. The leak is the VECTOR difference base - (all NH
# channels off), so it is differenced at every node rather than extrapolated
# from the fitted one. Costs a factor of two and removes an assumption.
#
# FROZEN IN THE OTHER 20 PARAMETERS, so every cost here is an OVERSTATEMENT
# (memory ccx_seas_q10_ridge: seas_T_amp x q10 is an exact ridge, and
# beta_max/fert_k absorb 85 % of a frozen cost). Read for SHAPE, DIRECTION
# and the RATIO between rows -- never as a refit's delta-logpost.
#
# THE GRADIENT CAVEAT, NAMED IN ADVANCE. `co2_grad` carries a FITTED offset
# (`grad_off_co2`) which, frozen, cannot re-absorb a shift. Its column here
# is therefore an UPPER bound on how much `tau_ex` costs the gradient.
#
# Usage:  Rscript calibration/diag_tau_ex_leak_profile.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

TL_YEARS  <- c(1750, 2024)
TL_GRID   <- exp(seq(log(0.7), log(4.0), length.out = 11))
TL_NH_OFF <- list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0)
# The two signatures, from diag_seas_signature_inversion.R sec.1. Named
# constants rather than literals in an expression, and re-derived there
# whenever the channels move.
TL_S_LAND  <- -0.04733
TL_S_OCEAN <- -0.00461
# NAMES CHECKED AGAINST THE LIKELIHOOD'S OWN add() CALLS, not guessed: the
# gradient rows are `<sp>_gradient` (R/likelihood.R:1285-1288), not `*_grad`.
# A missing name here is a subscript-out-of-bounds, which is loud -- but a
# name that exists and is the WRONG row would not be, so they are asserted
# against the run's actual stream list below.
TL_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO",
             "d13c_seasonal_SPO", "co2_gradient", "d13c_gradient",
             "co2_level_MLO", "co2_level_SPO")

sep    <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
gain   <- function(tau) (1 / tau) / sqrt((2 * pi)^2 + (1 / tau)^2)

md <- readRDS(ccx_mode_file())
p0 <- ccx_default_params(); for (n in names(md$par_mode)) p0[[n]] <- md$par_mode[[n]]
p0$pump_mode <- md$pump_mode
TAU0 <- p0$tau_ex
obs  <- ccx_prepare_obs()
YR   <- lapply(c(MLO = "MLO", SPO = "SPO"), function(st)
  intersect(obs$co2_seas[[st]]$year, obs$d13_seas[[st]]$year))
cat(sprintf("mode %s | tau_ex fitted %.4f yr | %d nodes over %.2f-%.2f\n",
            basename(ccx_mode_file()), TAU0, length(TL_GRID), min(TL_GRID), max(TL_GRID)))

tl_run <- function(tau, mods = list()) {
  p <- p0; p$tau_ex <- tau; for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", TL_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (p$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * p$luc_scale
  el <- ccx_forcing_eluc_annual(F)
  r  <- ccx_run_fast(sp, F)
  ms <- ccx_model_stats(r$out, obs)
  ll <- ccx_loglik(r$out, obs, list(sigma_d14c = p$sigma_d14c, rep_dC = p$rep_dC,
                                    grad_off_co2 = p$grad_off_co2,
                                    grad_off_d13c = p$grad_off_d13c),
                   luc = el, deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)
  list(ms = ms, ll = ll)
}
grab <- function(ms, st, sp_, yr) {
  h <- if (sp_ == "co2") ms$co2_seas[[st]] else ms$d13_seas[[st]]
  k <- match(yr, h$year); c(mean(h$a[k]), mean(h$b[k]))
}
invert <- function(co2, d13) {
  L <- (d13 - TL_S_OCEAN * co2) / (TL_S_LAND - TL_S_OCEAN); list(L = L, O = co2 - L)
}
# The prior on tau_ex, so a preference in the rows is never confused with one.
tl_prior <- function(tau) dlnorm(tau, log(1.3), 0.25, log = TRUE)

nodes <- lapply(TL_GRID, function(tau)
  list(tau = tau, full = tl_run(tau), nhoff = tl_run(tau, TL_NH_OFF)))
ref <- list(tau = TAU0, full = tl_run(TAU0), nhoff = tl_run(TAU0, TL_NH_OFF))
miss <- setdiff(TL_ROWS, names(ref$full$ll))
if (length(miss)) stop("TL_ROWS names not in the likelihood: ", paste(miss, collapse = ", "))

# ---------------------------------------------------------------------
sep("1. THE LEAK vs THE TWO-BOX TRANSFER FUNCTION  (prereg P1)")
cat("  'analytic' = gain(tau) x the model's own MLO peak-to-peak at that node.\n")
cat("  'damping'  = 1 - measured/analytic: what the SH sinks remove.\n\n")
cat(sprintf("  %8s %10s %9s %9s %9s %9s\n", "tau_ex", "leak ppm", "peak mo",
            "analytic", "damping", "SPO tot"))
for (nd in c(nodes, list(ref))) {
  lk <- grab(nd$full$ms, "SPO", "co2", YR$SPO) - grab(nd$nhoff$ms, "SPO", "co2", YR$SPO)
  an <- gain(nd$tau) * amp(grab(nd$full$ms, "MLO", "co2", YR$MLO))
  cat(sprintf("  %8.3f %10.3f %9.2f %9.3f %8.1f%% %9.3f%s\n", nd$tau, amp(lk),
              ang_mo(lk), an, 100 * (1 - amp(lk) / an),
              amp(grab(nd$full$ms, "SPO", "co2", YR$SPO)),
              if (identical(nd$tau, TAU0)) "   <- FITTED" else ""))
}

# ---------------------------------------------------------------------
sep("2. DOES THE PARTITION MOVE AT ALL?  (prereg P2)")
o_c <- grab(obs, "SPO", "co2", YR$SPO); o_d <- grab(obs, "SPO", "d13", YR$SPO)
o_sig <- amp(o_d) / amp(o_c)
oi <- invert(o_c, o_d)
cat(sprintf("  OBSERVED SPO: CO2 %.3f, d13C %.4f, sig %.5f permil/ppm\n", amp(o_c), amp(o_d), o_sig))
cat(sprintf("                land %.3f at mo %.2f | ocean %.3f at mo %.2f\n\n",
            amp(oi$L), ang_mo(oi$L), amp(oi$O), ang_mo(oi$O)))
cat(sprintf("  %8s %9s %10s %9s %9s %9s %9s\n", "tau_ex", "SPO sig", "ratio/obs",
            "land ppm", "land mo", "ocean ppm", "ocean mo"))
sigs <- c()
for (nd in c(nodes, list(ref))) {
  mc <- grab(nd$full$ms, "SPO", "co2", YR$SPO); mdd <- grab(nd$full$ms, "SPO", "d13", YR$SPO)
  iv <- invert(mc, mdd); rt <- (amp(mdd) / amp(mc)) / o_sig
  if (!identical(nd$tau, TAU0)) sigs <- c(sigs, rt)
  cat(sprintf("  %8.3f %9.5f %8.2fx %9.3f %9.2f %9.3f %9.2f%s\n", nd$tau,
              amp(mdd) / amp(mc), rt, amp(iv$L), ang_mo(iv$L), amp(iv$O), ang_mo(iv$O),
              if (identical(nd$tau, TAU0)) "   <- FITTED" else ""))
}
r0 <- (amp(grab(ref$full$ms, "SPO", "d13", YR$SPO)) /
       amp(grab(ref$full$ms, "SPO", "co2", YR$SPO))) / o_sig
sw <- max(abs(sigs / r0 - 1))
cat(sprintf("\n  P2 -- ratio at the fitted tau_ex %.2fx; max excursion over the grid %.1f%%\n",
            r0, 100 * sw))
cat(sprintf("       predicted within +/-10%%  ->  %s\n",
            if (sw <= 0.10) "CONFIRMED: tau_ex is EXONERATED as a partition lever"
            else "FAILED: tau_ex DOES move the partition"))

# ---------------------------------------------------------------------
sep("3. WHICH ROWS WANT WHICH DIRECTION?  (prereg P3; logL, node minus FITTED)")
cat("  POSITIVE = that node fits BETTER than the fitted tau_ex does.\n")
cat("  'prior' is the tau_ex prior term, so a row preference is never read as a\n")
cat("  posterior preference. co2_grad's offset is FROZEN -> its column is an\n")
cat("  UPPER bound on the gradient's objection.\n\n")
hdr <- c(TL_ROWS, "prior", "TOTAL")
cat(sprintf("  %8s", "tau_ex")); for (h in hdr) cat(sprintf(" %11s", substr(h, 1, 11))); cat("\n")
for (nd in nodes) {
  d <- vapply(TL_ROWS, function(s) nd$full$ll[[s]] - ref$full$ll[[s]], 0)
  pr <- tl_prior(nd$tau) - tl_prior(TAU0)
  cat(sprintf("  %8.3f", nd$tau))
  for (v in c(d, pr, sum(unlist(nd$full$ll)) - sum(unlist(ref$full$ll)) + pr))
    cat(sprintf(" %+11.1f", v))
  cat("\n")
}
# ---------------------------------------------------------------------
sep("3b. DIRECTION AT THE FITTED VALUE -- SYMMETRIC central difference")
cat("  THE NEAREST GRID NODES CANNOT ANSWER THIS. The log-spaced grid puts 1.181\n")
cat("  eight times closer to the fitted 1.159 than 0.992 is, so comparing them\n")
cat("  reads the SPACING, not the model: every row then 'wants LONGER' because\n")
cat("  the longer node is barely a perturbation. Two SYMMETRIC runs at\n")
cat("  tau0 * exp(+/-h) give each row's slope d logL / d ln(tau) instead.\n\n")
TL_H <- 0.10
dm <- tl_run(TAU0 * exp(-TL_H)); dp <- tl_run(TAU0 * exp(+TL_H))
cat(sprintf("  h = %.2f in ln(tau): %.4f and %.4f yr\n\n", TL_H,
            TAU0 * exp(-TL_H), TAU0 * exp(+TL_H)))
cat(sprintf("  %-19s %10s %10s %12s %10s %s\n", "stream", "shorter", "longer",
            "slope", "curv", "wants"))
for (s in c(TL_ROWS, "gcb_land_sink")) {
  a <- dm$ll[[s]] - ref$full$ll[[s]]; b <- dp$ll[[s]] - ref$full$ll[[s]]
  sl <- (b - a) / (2 * TL_H); cv <- (a + b) / TL_H^2
  cat(sprintf("  %-19s %+10.2f %+10.2f %+12.1f %+10.1f %s\n", s, a, b, sl, cv,
              if (abs(sl) < 1) "flat" else if (sl > 0) "LONGER" else "SHORTER"))
}
a <- sum(unlist(dm$ll)) + tl_prior(TAU0 * exp(-TL_H)) -
     sum(unlist(ref$full$ll)) - tl_prior(TAU0)
b <- sum(unlist(dp$ll)) + tl_prior(TAU0 * exp(+TL_H)) -
     sum(unlist(ref$full$ll)) - tl_prior(TAU0)
cat(sprintf("  %-19s %+10.2f %+10.2f %+12.1f %+10.1f %s\n", "TOTAL (with prior)",
            a, b, (b - a) / (2 * TL_H), (a + b) / TL_H^2,
            if (abs((b - a) / (2 * TL_H)) < 1) "flat" else
              if (b > a) "LONGER" else "SHORTER"))
cat("\n  A frozen 1-D slope is NOT a posterior gradient -- the other 20 parameters\n")
cat("  cannot re-absorb here, so every |slope| is an OVERSTATEMENT. What it is\n")
cat("  read for is the SIGN, and whether two rows disagree on it.\n")

sep("DONE")
