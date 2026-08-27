# =====================================================================
# diag_tau_ex_conditional_power.R -- IS THE tau_ex PROFILE'S VERDICT
#                                    SURVIVED BY THE FULL SLICE?
#
# WHY A SECOND SCRIPT. diag_tau_ex_seasonal_power.R measures a PROFILE: it
# moves `tau_ex` with every other calibrated parameter frozen at the mode, and
# lets only the two gradient OFFSETS absorb. A profile is a LOWER BOUND on a
# lever's power. If some combination -- tau_ex up, and something else moving to
# pay the d13C-level and d14C bills the profile shows -- is much cheaper than
# tau_ex alone, then the profile understates what the 27h wider slice could do,
# and "the profile says no power" would be the wrong reason to skip that run.
# [[profile_beats_optimum]]
#
# THE CHECK. Fix `tau_ex` at each of a few multiples of its mode value and
# re-optimise THE ENTIRE 27h SLICE around it -- the six 27g seasonal parameters
# plus the two gradient offsets, eight free. The cost that survives THAT is the
# conditional cost, and it is the number the decision actually rests on.
#
# WHY ent_seas_amp_SH IS OFF HERE. The question is how much a move of `tau_ex`
# COSTS, and that price is paid by the same annual-mean rows in both arms. This
# is therefore run in the INCUMBENT configuration (no entrainment channel),
# which is also the cheaper arm and the one directly comparable to 27g's own
# incumbent. It is not a scoring of the 27h hypothesis and does not pretend to
# be one.
#
# ⚠ NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE -- the harness sits
# -3.3223 below it, pre-existing ([[ccx_mode_logpost_offset]]). Everything here
# is a difference against THIS script's own tau_ex = mode conditional optimum.
#
# Usage:  Rscript calibration/diag_tau_ex_conditional_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

CP_POWER_RDS <- ccx_path("outputs", "diagnostics", "tau_ex_seasonal_power.rds")
CP_YEARS     <- c(1750, 2024)
# The 27h slice: 27g's RF_BLOCK, plus the two nuisance offsets that exist to
# absorb the interhemispheric representation constant. tau_ex itself is FIXED
# at each grid point -- that is what makes this a conditional profile.
CP_BLOCK  <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH",
               "seas_T_amp_SH", "seas_lag_p", "q10",
               "grad_off_co2", "grad_off_d13c")
# 1.00 is the reference (the same slice's own optimum at the mode's tau_ex);
# 1.26 is where the PROFILE put the cost at -77 log-units. 1.12 fixes the shape.
CP_MULT   <- c(1.00, 1.12, 1.26)
# ⚠ CONVERGENCE IS LOAD-BEARING AND IN THE DIRECTION THAT FLATTERS THE ANSWER.
# An under-converged optimum at a fixed tau_ex reports the cost of that tau_ex
# as LARGER than it is -- i.e. it manufactures exactly the "tau_ex is
# unaffordable" verdict this script exists to test. The first run of this script
# hit maxit at all three points and had to be discarded. So: warm-start each
# tau_ex from the previous one (CONTINUATION -- the optima are close), polish
# with BFGS, and restart Nelder-Mead until it stops improving. Every point
# prints its restart count and final improvement so a silent maxit cannot
# recur. [[profile_beats_optimum]]
CP_MAXIT     <- 1500
CP_RESTARTS  <- 6
CP_RESTOL    <- 0.02      # log-units; below this a restart has found nothing
# The offsets' own scorecard. The measured station-latitude representation
# constant is -0.386 ppm at defaults / -0.549 at the MAP mode
# (diag_gradient_terms.R part 3), and the prior is N(0, 0.5) ppm. An offset
# that walks well past the measured value is ABSORBING MODEL ERROR, not
# representing a station's latitude -- so any tau_ex move bought that way is
# bought, not earned. THIS IS AN OBSERVATION, NOT A FEEL-CHOSEN GATE.
CP_OFF_MEASURED <- c(-0.386, -0.549)

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
stopifnot(file.exists(CP_POWER_RDS))
pw <- readRDS(CP_POWER_RDS)
md <- readRDS(ccx_mode_file())
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
TAU0  <- pw$tau0
i_tau <- match("tau_ex", CCX_PARAM_NAMES)
idx   <- match(CP_BLOCK, CCX_PARAM_NAMES)
stopifnot(!is.na(i_tau), !anyNA(idx))

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(years = CP_YEARS, base_params = bp)
one <- lp(u0)
cat(sprintf("mode %s | tau_ex %.4f | harness at u_mode %.4f (offset %+.4f)\n",
            basename(ccx_mode_file()), TAU0, one, one - md$logpost))
cat(sprintf("slice (%d free, tau_ex FIXED): %s\n\n",
            length(CP_BLOCK), paste(CP_BLOCK, collapse = ", ")))

obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

# Twin of diag_tau_ex_seasonal_power.R's run_at, INCLUDING its bomb_total /
# luc_scale lesson: those names are likelihood-side and absent from
# ccx_default_params(), so they must be read off `pv`.
run_at <- function(pv, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", CP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
  vec_of(pick(ms, "co2_seas.SPO"))
}
# base - (NH channels off) at SPO = the NH-ORIGIN part of the SH cycle.
CP_NH_OFF <- list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0)
CP_SH_LAND_OFF <- list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0)

sep("1. CONDITIONAL PROFILE -- tau_ex fixed, the whole 27h slice re-optimised")
cat(sprintf("  %6s %8s | %11s %11s | %10s %10s | %2s %8s\n", "mult", "tau_ex",
            "cond dlp", "profile dlp", "off_co2", "off_d13c", "re", "lastgain"))
# Nelder-Mead, BFGS polish, then NM restarts until the improvement dies.
fit_block <- function(obj, v0) {
  v <- v0; best <- obj(v0); n_re <- 0; gain <- Inf
  ft <- optim(v, obj, method = "Nelder-Mead",
              control = list(maxit = CP_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value
  repeat {
    bf <- try(optim(v, obj, method = "BFGS",
                    control = list(maxit = 200, reltol = 1e-12)), silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, obj, method = "Nelder-Mead",
                control = list(maxit = CP_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < CP_RESTOL || n_re >= CP_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain,
       converged = gain < CP_RESTOL)
}

res <- list(); v_warm <- u0[idx]
for (m in CP_MULT) {
  tau <- TAU0 * m
  u_fix <- u0; u_fix[i_tau] <- log(tau)
  obj <- function(v) { u <- u_fix; u[idx] <- v; -lp(u) }
  ft <- fit_block(obj, v_warm)      # CONTINUATION from the previous tau_ex
  v_warm <- ft$par
  u_hat <- u_fix; u_hat[idx] <- ft$par
  pv <- ccx_unc_to_par(u_hat)
  prof <- pw$rows[[sprintf("%.2f", m)]]
  pc <- if (is.null(prof)) NA_real_ else prof$abs - pw$harness_at_u_mode
  res[[sprintf("%.2f", m)]] <- list(mult = m, tau = tau, lp = -ft$value,
                                    u = u_hat, pv = pv, prof_cost = pc,
                                    restarts = ft$restarts, last_gain = ft$last_gain,
                                    converged = ft$converged)
  cat(sprintf("  %6.2f %8.4f | %+11.2f %+11.2f | %+10.4f %+10.4f | %2d %8.4f%s\n",
              m, tau, -ft$value - one, pc, pv$grad_off_co2, pv$grad_off_d13c,
              ft$restarts, ft$last_gain,
              if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}
ref <- res[["1.00"]]$lp
cat(sprintf("\n  Reference = this slice's own optimum at tau_ex = %.4f: %+.2f vs u_mode.\n",
            TAU0, ref - one))
cat("  The COST of a tau_ex move is the drop from THAT, not from u_mode.\n\n")
cat(sprintf("  %6s %8s | %13s %13s | %8s\n", "mult", "tau_ex",
            "cost vs ref", "profile cost", "ratio"))
for (k in names(res)) {
  r <- res[[k]]
  cat(sprintf("  %6.2f %8.4f | %+13.2f %+13.2f | %7s\n", r$mult, r$tau,
              r$lp - ref, r$prof_cost,
              if (is.na(r$prof_cost) || abs(r$prof_cost) < 1e-6) "--"
              else sprintf("%.2fx", (r$lp - ref) / r$prof_cost)))
}
cat("\n  ratio < 1 = the slice BOUGHT BACK part of the profile's cost, which is\n")
cat("  the whole reason a profile alone could not settle this.\n")

sep("2. WHAT IT BOUGHT -- the NH import at the conditional optimum")
cat(sprintf("  Observed TOTAL SPO land component: %.3f ppm.\n\n",
            pw$obs_spo$land[["amp"]]))
cat(sprintf("  %6s %8s | %9s %6s | %9s %6s | %9s %6s | %11s\n", "mult", "tau_ex",
            "NH-orig", "mo", "SH-land", "mo", "SPO tot", "mo", "cost vs ref"))
for (k in names(res)) {
  r <- res[[k]]
  b  <- run_at(r$pv)
  nh <- b - run_at(r$pv, CP_NH_OFF)
  sl <- b - run_at(r$pv, CP_SH_LAND_OFF)
  res[[k]]$nh <- c(amp = amp(nh), mo = ang_mo(nh))
  res[[k]]$sl <- c(amp = amp(sl), mo = ang_mo(sl))
  res[[k]]$tot <- c(amp = amp(b), mo = ang_mo(b))
  cat(sprintf("  %6.2f %8.4f | %9.3f %6.2f | %9.3f %6.2f | %9.3f %6.2f | %+11.2f\n",
              r$mult, r$tau, amp(nh), ang_mo(nh), amp(sl), ang_mo(sl),
              amp(b), ang_mo(b), r$lp - ref))
}

sep("3. THE OFFSETS -- earned or bought?")
cat(sprintf("  Measured representation constant: %.3f (defaults) / %.3f (MAP) ppm.\n",
            CP_OFF_MEASURED[1], CP_OFF_MEASURED[2]))
cat("  An offset beyond that range is absorbing MODEL ERROR, not a latitude.\n\n")
for (k in names(res)) {
  r <- res[[k]]
  flag <- if (r$pv$grad_off_co2 < min(CP_OFF_MEASURED) * 1.5)
    "  ⚠ PAST the measured constant -- bought, not earned" else ""
  cat(sprintf("  mult %.2f : grad_off_co2 %+.4f ppm (prior z %+.2f)%s\n",
              r$mult, r$pv$grad_off_co2,
              ccx_prior_z("grad_off_co2", r$pv$grad_off_co2), flag))
}

sep("4. THE VERDICT ON POWER")
c126 <- res[["1.26"]]
d_nh <- c126$nh[["amp"]] - res[["1.00"]]$nh[["amp"]]
cat(sprintf("  At tau_ex = 1.26x the conditional cost is %.2f log-units and the NH\n",
            -(c126$lp - ref)))
cat(sprintf("  import moves %+.3f ppm (%.3f -> %.3f), i.e. %.4f ppm per log-unit.\n",
            d_nh, res[["1.00"]]$nh[["amp"]], c126$nh[["amp"]],
            abs(d_nh) / max(1e-9, -(c126$lp - ref))))
cat(sprintf("  The 27g challenger's ENTIRE net gain was +11.62 log-units. At this\n"))
cat(sprintf("  exchange rate that whole budget buys %.3f ppm of import.\n",
            11.62 * abs(d_nh) / max(1e-9, -(c126$lp - ref))))
cat(sprintf("  The model's SPO land component exceeds the observed by ~%.3f ppm.\n",
            1.364 - pw$obs_spo$land[["amp"]]))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(block = CP_BLOCK, mult = CP_MULT, tau0 = TAU0,
             harness_at_u_mode = one, ref = ref, res = res),
        file.path(OUTDIR, "tau_ex_conditional_power.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "tau_ex_conditional_power.rds")))
