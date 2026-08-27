# =====================================================================
# diag_tau_ex_seasonal_power.R -- DOES `tau_ex` HAVE ANY POWER OVER THE
#                                 NH SEASONAL IMPORT INTO SPO, AND AT
#                                 WHAT PRICE?
#
# WHY THIS RUNS BEFORE THE WIDER SLICE, NOT AFTER.
# Handoff 27h sec.4 recommends re-running the 27g P2 design with `tau_ex`
# added, on the hypothesis that P3 scored FAILED because the slice froze the
# only fittable lever on the 0.821 ppm of SPO's seasonal land component that
# arrives FROM THE NH. That is a good hypothesis. It is also one whose null is
# at risk of being STRUCTURALLY GUARANTEED: if the interhemispheric-gradient
# rows pin `tau_ex` to a few per cent, then "we freed tau_ex and P3 still
# failed" reports exactly what "we did not free it" reports, and neither is
# evidence about the physics. [[no_power_null]]
#
# THERE IS A SPECIFIC REASON TO EXPECT LOW POWER, AND IT IS ANALYTIC.
# For two well-mixed atmospheric boxes exchanging at `tau_ex`, a seasonal NH
# signal reaches the SH box attenuated by
#       |C_S / C_N| = (1/tau) / sqrt(om^2 + (1/tau)^2),   om = 2*pi / yr
# which for om*tau >> 1 (it is 7.3 at the mode) is ~ 1/(om*tau). So the
# SEASONAL import falls like 1/tau_ex: halving it needs tau_ex DOUBLED.
# But the MEAN interhemispheric gradient that `co2_gradient` scores rises
# ~LINEARLY in tau_ex. The same parameter therefore buys import reduction at a
# price set by a row whose sigma is 0.35 ppm on a ~3 ppm gradient. The whole
# question is the EXCHANGE RATE between those two, and it is measurable in
# minutes. [[orthogonality_bounds_efficiency]]
#
# ⚠ THIS IS NOT THE FIRST tau_ex PROFILE. `diag_tau_ex_leak_profile.R` (prereg
# 27e) already profiled it and EXONERATED it as a PARTITION lever: the SPO
# d13C-per-ppm ratio moves 4.2 % across a 5.7x range, because BOTH parts of the
# model's SPO cycle carry the LAND signature, so transport relabels WHERE the
# cycle was made rather than WHAT made it. Handoff 27h §4 accepts that and says
# the binding error is one of SIZE, not partition -- which 27e explicitly did
# not settle. THAT is what is new here, and it needs three things 27e's script
# says it does not have:
#   * 27e is FROZEN in the other 20 parameters and its header calls every cost
#     an OVERSTATEMENT. Here the gradient OFFSETS re-optimise at every node,
#     and diag_tau_ex_conditional_power.R re-optimises the whole 27h slice.
#   * 27e reads the d13C-per-ppm RATIO. The size question needs the SPO
#     component AMPLITUDES, which sec.3 differences at every node.
#   * 27e names the frozen `grad_off_co2` as a caveat. It is removed here.
# Do not read this as a replacement for 27e's finding. It is the second half.
#
# WHAT THIS SCRIPT IS AND IS NOT.
#   IS      a POWER measurement, run to make the wider slice's pre-registered
#           thresholds DERIVABLE from a measured exchange rate instead of
#           guessed. [[derive_gate_from_the_thing]]
#   IS NOT  the test itself. It re-optimises NOTHING but the two gradient
#           OFFSETS, so it cannot and does not score the 27h hypothesis. The
#           refit is a separate, separately pre-registered run.
#
# THE OFFSETS ARE RE-OPTIMISED AT EVERY GRID POINT, AND THAT IS NOT OPTIONAL.
# `grad_off_co2` / `grad_off_d13c` are the nuisance parameters that exist
# precisely to absorb the station-latitude representation constant
# (R/calibrate.R, the "interhemispheric-gradient offsets" block). Profiling
# tau_ex with them FROZEN would price every move of tau_ex at the full
# gradient miss and so OVERSTATE the cost -- reporting as unaffordable
# something the model is designed to pay for cheaply. Both profiles are
# printed: their difference IS the absorption, which is worth seeing.
#
# ⚠ NEVER QUOTE AN ABSOLUTE LOGPOST FROM THIS HARNESS AGAINST THE MODE FILE.
# ccx_make_logpost() sits -3.3223 below the stored mode logpost at the mode's
# own u_mode, pre-existing and undiagnosed (handoff 27h sec.6,
# [[ccx_mode_logpost_offset]]). Everything below is a DIFFERENCE against this
# harness's own value at the mode's tau_ex, so the offset cancels.
#
# Usage:  Rscript calibration/diag_tau_ex_seasonal_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

TP_MODE_FILE <- ccx_mode_file()
TP_YEARS     <- c(1750, 2024)
# Log-spaced multipliers on the mode's tau_ex. The top end is set by the
# analytic 1/tau law above: 4x is what it takes to cut the NH import to ~a
# quarter, so anything the fit could plausibly want is inside the grid.
# FINE POINTS BETWEEN 1.00 AND 1.26 ARE NOT DECORATION. The first version of
# this grid went 1.00 -> 1.26 in one step, that step cost 77 log-units, and
# every affordability rung in sec.4 therefore resolved to "1.00x" and printed
# NA. A grid whose smallest step is 8x the largest budget being asked about
# cannot answer the question it was built to answer.
TP_MULT      <- c(0.50, 0.63, 0.79, 1.00, 1.03, 1.06, 1.09, 1.12, 1.19,
                  1.26, 1.59, 2.00, 2.52, 3.17, 4.00)
# The nuisance offsets re-optimised at each grid point, and nothing else.
TP_NUISANCE  <- c("grad_off_co2", "grad_off_d13c")
TP_NUIS_MAXIT <- 400
# Streams printed in the cost decomposition. The gradient pair is the
# hypothesised binding constraint; the rest are the rows that could plausibly
# object to an interhemispheric-transport move.
TP_COST_ROWS <- c("co2_gradient", "d13c_gradient", "co2_level_MLO",
                  "co2_level_SPO", "d13c_level_MLO", "d13c_level_SPO",
                  "d14c_NH", "d14c_SH", "co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")
TP_SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")
# The affordability rungs the power curve is read at. DERIVED, not chosen for
# feel: 11.62 is the ENTIRE net gain the 27g challenger banked (+16.78 prior,
# -5.17 likelihood), i.e. the largest budget the wider slice could possibly
# spend on tau_ex without ending up behind the incumbent; 2.0 is the
# conventional one-parameter scale; 5.0 sits between them.
TP_BUDGETS   <- c(2.0, 5.0, 11.62)
# The observed SPO seasonal components this is all aimed at (peak-to-peak ppm
# and peak month), from the 27f/27g inversion against the observed record.
TP_OBS_SPO_LAND  <- c(amp = 0.665, mo = NA)
TP_OBS_SPO_OCEAN <- c(amp = 0.522, mo = 8.52)

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(TP_MODE_FILE)
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
TAU0 <- md$par_mode$tau_ex
i_tau  <- match("tau_ex", CCX_PARAM_NAMES)
i_nuis <- match(TP_NUISANCE, CCX_PARAM_NAMES)
stopifnot(!is.na(i_tau), !anyNA(i_nuis))

cat(sprintf("mode %s (arm %s)\n", basename(TP_MODE_FILE), md$pump_mode))
cat(sprintf("tau_ex at the mode = %.4f yr (prior z %+.2f) | om*tau = %.2f\n",
            TAU0, ccx_prior_z("tau_ex", TAU0), 2 * pi * TAU0))
cat(sprintf("grid: %.3f to %.3f yr, %d points, log-spaced\n",
            TAU0 * min(TP_MULT), TAU0 * max(TP_MULT), length(TP_MULT)))

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(years = TP_YEARS, base_params = bp)
one <- lp(u0)
gap <- one - md$logpost
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f (known -3.3223)\n",
            one, md$logpost, gap))
if (abs(gap - (-3.3223)) > 0.5)
  cat("  ⚠ THE OFFSET HAS MOVED. Investigate BEFORE reading this run.\n")

# ---- the SPO channel decomposition, at an arbitrary parameter vector ----
# Same vector arithmetic as diag_seas_channel_decomp.R: a channel's
# contribution is the VECTOR difference of the harmonic (a,b) pair, because
# scalar amplitudes of out-of-phase parts do not subtract.
obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
amp    <- function(v) 2 * sqrt(sum(v^2))            # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

run_at <- function(pv, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", TP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  # ⚠ bomb_total AND luc_scale COME OFF `pv`, NOT `p`. Seven of the 21 calibrated
  # names (bomb_total, luc_scale, sigma_d14c, rep_dC, grad_off_*, ...) are
  # LIKELIHOOD-side and are NOT in ccx_default_params(), so the intersect() above
  # never copies them and `p$bomb_total` is NULL. NULL/102 is numeric(0) and
  # F$c14_bomb silently becomes a zero-length column -- which is how this failed,
  # loudly, three lines later. streams_at() below reads pv for the same reason.
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o  <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(o, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")))
}
# base - (NH channels off) at SPO = the NH-ORIGIN part; base - (SH land off) =
# the SH-LOCAL LAND part; base - (BOTH SH ocean limbs off) = the ocean limb.
# ⚠ the ocean case MUST kill both limbs -- killing sst_seas_amp_SH alone leaves
# the entrainment limb running, the bug found in the older scripts on 27g.
TP_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))

decomp_spo <- function(pv) {
  b <- run_at(pv)
  out <- lapply(TP_CASES, function(m) {
    d <- b$co2_SPO - run_at(pv, m)$co2_SPO
    c(amp = amp(d), mo = ang_mo(d))
  })
  c(list(total = c(amp = amp(b$co2_SPO), mo = ang_mo(b$co2_SPO))), out)
}

# ---- the grid --------------------------------------------------------
sep("1. THE PROFILE -- cost of moving tau_ex, offsets FROZEN and RE-OPTIMISED")
cat("  raw    = every other parameter frozen at the mode\n")
cat("  absorb = grad_off_co2 + grad_off_d13c re-optimised at that tau_ex\n")
cat("  Both are differences against THIS harness at the mode's tau_ex.\n\n")
cat(sprintf("  %6s %8s %7s | %9s %9s %8s | %9s %9s\n", "mult", "tau_ex", "prior z",
            "raw dlp", "absorb", "gained", "off_co2", "off_d13c"))

rows <- list()
for (m in TP_MULT) {
  tau <- TAU0 * m
  u_raw <- u0; u_raw[i_tau] <- log(tau)
  lp_raw <- lp(u_raw)
  obj <- function(v) { u <- u_raw; u[i_nuis] <- v; -lp(u) }
  ft <- optim(u_raw[i_nuis], obj, method = "Nelder-Mead",
              control = list(maxit = TP_NUIS_MAXIT, reltol = 1e-10))
  u_abs <- u_raw; u_abs[i_nuis] <- ft$par
  pv_abs <- ccx_unc_to_par(u_abs)
  rows[[sprintf("%.2f", m)]] <- list(
    mult = m, tau = tau, raw = lp_raw, abs = -ft$value,
    u = u_abs, pv = pv_abs, z = ccx_prior_z("tau_ex", tau))
  cat(sprintf("  %6.2f %8.4f %+7.2f | %+9.2f %+9.2f %8.2f | %+9.4f %+9.4f\n",
              m, tau, ccx_prior_z("tau_ex", tau), lp_raw - one, -ft$value - one,
              -ft$value - lp_raw, pv_abs$grad_off_co2, pv_abs$grad_off_d13c))
}

# ---- where the cost sits ---------------------------------------------
sep("2. WHICH ROWS PAY -- streams at each tau_ex, offsets re-optimised")
streams_at <- function(u) {
  pv <- ccx_unc_to_par(u)
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", TP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                 grad_off_co2 = pv$grad_off_co2,
                                 grad_off_d13c = pv$grad_off_d13c),
                    luc = ccx_forcing_eluc_annual(F),
                    deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
}
s_ref <- streams_at(u0)
cat(sprintf("  %6s", "mult"))
for (n in TP_COST_ROWS) cat(sprintf(" %10s", substr(n, 1, 10)))
cat(sprintf(" %10s\n", "prior tau"))
for (k in names(rows)) {
  r <- rows[[k]]
  s <- streams_at(r$u); r$streams <- s; rows[[k]] <- r
  cat(sprintf("  %6.2f", r$mult))
  for (n in TP_COST_ROWS) cat(sprintf(" %+10.2f", s[[n]] - s_ref[[n]]))
  cat(sprintf(" %+10.2f\n",
              CCX_PARAM_TABLE$tau_ex$prior(r$tau) + log(r$tau) -
              (CCX_PARAM_TABLE$tau_ex$prior(TAU0) + log(TAU0))))
}

# ---- the quantity the whole thing is about ---------------------------
sep("3. THE POWER CURVE -- what the NH import actually does")
cat(sprintf("  Observed SPO land %.3f ppm; ocean %.3f ppm at month %.2f.\n",
            TP_OBS_SPO_LAND[["amp"]], TP_OBS_SPO_OCEAN[["amp"]],
            TP_OBS_SPO_OCEAN[["mo"]]))
cat("  Contributions are VECTOR differences and need not sum to the total.\n\n")
cat(sprintf("  %6s %8s | %8s %6s | %8s %6s | %8s %6s | %8s %6s | %8s\n",
            "mult", "tau_ex", "NH-orig", "mo", "SH-land", "mo", "SH-ocn", "mo",
            "SPO tot", "mo", "dlogpost"))
two_box <- function(tau) (1 / tau) / sqrt((2 * pi)^2 + (1 / tau)^2)
for (k in names(rows)) {
  r <- rows[[k]]
  d <- decomp_spo(r$pv); rows[[k]]$decomp <- d
  cat(sprintf("  %6.2f %8.4f | %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %+8.2f\n",
              r$mult, r$tau, d$NH_origin[["amp"]], d$NH_origin[["mo"]],
              d$SH_land[["amp"]], d$SH_land[["mo"]],
              d$SH_ocean[["amp"]], d$SH_ocean[["mo"]],
              d$total[["amp"]], d$total[["mo"]], r$abs - one))
}
cat(sprintf("\n  ANALYTIC two-box gain (1/tau)/sqrt(om^2+1/tau^2), normalised to the mode:\n  %6s", "mult"))
for (k in names(rows)) cat(sprintf(" %7.2f", rows[[k]]$mult))
cat(sprintf("\n  %6s", "pred"))
for (k in names(rows)) cat(sprintf(" %7.3f", two_box(rows[[k]]$tau) / two_box(TAU0)))
cat(sprintf("\n  %6s", "actual"))
nh0 <- rows[[sprintf("%.2f", 1)]]$decomp$NH_origin[["amp"]]
for (k in names(rows)) cat(sprintf(" %7.3f", rows[[k]]$decomp$NH_origin[["amp"]] / nh0))
cat("\n  Agreement here says the import really is transport-limited and the\n")
cat("  1/tau law is the right model of this lever.\n")

# ---- read the exchange rate off the curve ----------------------------
sep("4. THE EXCHANGE RATE -- import bought per log-unit spent")
cat("  For each budget: the largest tau_ex whose cost is within it, and the NH\n")
cat("  import there. THIS IS WHAT THE WIDER SLICE'S THRESHOLDS DERIVE FROM.\n\n")
dlp <- vapply(rows, function(r) r$abs - one, 0)
nhi <- vapply(rows, function(r) r$decomp$NH_origin[["amp"]], 0)
sli <- vapply(rows, function(r) r$decomp$SH_land[["amp"]], 0)
toti <- vapply(rows, function(r) r$decomp$total[["amp"]], 0)
tau <- vapply(rows, function(r) r$tau, 0)
cat(sprintf("  NH import at the mode: %.3f ppm  (observed TOTAL SPO land %.3f)\n",
            nh0, TP_OBS_SPO_LAND[["amp"]]))
cat("  INTERPOLATED on the tau >= mode branch, where cost is monotone in tau.\n")
cat("  Read off the MEASURED curve, not off the 1/tau law.\n\n")
up <- which(tau >= TAU0)
up <- up[order(-dlp[up])]                       # increasing cost
at <- function(y, b) approx(-dlp[up], y[up], xout = b, rule = 2)$y
for (b in TP_BUDGETS)
  cat(sprintf("  budget %5.2f log-units -> tau_ex %.4f (%.3fx) | NH import %.3f ppm (%.0f %% of mode) | SPO total %.3f\n",
              b, at(tau, b), at(tau, b) / TAU0, at(nhi, b),
              100 * at(nhi, b) / nh0, at(toti, b)))
bmax <- TP_BUDGETS[length(TP_BUDGETS)]
cat(sprintf("\n  EXCHANGE RATE at the %.2f-log-unit budget: %.4f ppm of NH import\n",
            bmax, (nh0 - at(nhi, bmax)) / bmax))
cat("  removed per log-unit of posterior spent.\n")

# ---- and the question the exchange rate does NOT answer ---------------
cat("\n  ⚠ THE EXCHANGE RATE IS NOT THE WHOLE ANSWER, AND IT IS THE SMALLER HALF.\n")
cat("  `tau_ex` reallocates the SPO cycle between NH-origin and SH-local. It\n")
cat("  barely changes the cycle. Over the WHOLE grid, at any price:\n\n")
cat(sprintf("  %-26s %9s %9s %9s\n", "quantity", "at mode", "at 4.00x", "change"))
k1 <- sprintf("%.2f", 1); kN <- sprintf("%.2f", max(TP_MULT))
for (q in list(c("NH-origin at SPO", "NH_origin"), c("SH-LOCAL LAND at SPO", "SH_land"),
               c("SPO total", "total"))) {
  a <- rows[[k1]]$decomp[[q[2]]][["amp"]]; b <- rows[[kN]]$decomp[[q[2]]][["amp"]]
  cat(sprintf("  %-26s %9.3f %9.3f %+8.1f%%\n", q[1], a, b, 100 * (b / a - 1)))
}
cat(sprintf("\n  Observed TOTAL SPO land component: %.3f ppm. The SH-LOCAL land\n",
            TP_OBS_SPO_LAND[["amp"]]))
cat(sprintf("  channel ALONE is %.2fx that at the mode and %.2fx at 4.00x tau_ex --\n",
            sli[[k1]] / TP_OBS_SPO_LAND[["amp"]], sli[[kN]] / TP_OBS_SPO_LAND[["amp"]]))
cat("  so deleting the ENTIRE NH import, at ANY price, does not fix SH land.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(mode = basename(TP_MODE_FILE), tau0 = TAU0, mult = TP_MULT,
             harness_at_u_mode = one, harness_offset = gap,
             budgets = TP_BUDGETS, rows = rows, streams_ref = s_ref,
             obs_spo = list(land = TP_OBS_SPO_LAND, ocean = TP_OBS_SPO_OCEAN)),
        file.path(OUTDIR, "tau_ex_seasonal_power.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "tau_ex_seasonal_power.rds")))
