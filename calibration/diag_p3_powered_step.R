#!/usr/bin/env Rscript
# =====================================================================
# diag_p3_powered_step.R -- P3 WITH q10 FREED, WITH POWER (2026-10-04, a repair of the P3 preview's design).
#
# WHY. calibration/diag_p3_netclimate_preview.R (Marcus 10-04: "Preview P3 with q10 freed") frees q10 inside the
# 8-name land block, every other name held. MEASURED here from hilda34g's stored covariance: that 9-name block frees
# q10 to only 0.15 of its MARGINAL sd (npp_tsens: 0.93). q10's partners sit OUTSIDE it -- seas_lag_p_NH (r +0.80),
# npp_frac_NH (+0.68), seas_T_amp_SH (-0.59), tau_ex (+0.47) -- because q10 has a cross-timescale duty: the seasonal
# respiration is q10^(A_T sin/10), so the seasonal rows fix A_T * ln(q10) (R/model.R, the CCX_SEAS_PHI_EFF block).
# A held-seas_T_amp q10 profile therefore prices the SEASONAL RIDGE, not the GCB row: a probe at q10 1.25 cost
# -1708 on the #15 likelihood with seas_T_amp held and -22.5 with seas_T_amp rescaled along A_T*ln(q10) = const.
# So "freeing q10 moves nothing" was a no-power null there (memory no_power_null).
#
# WHAT THIS DOES. The P3 objective is the #15 logpost + the GCB net-climate row, N(-0.8, 0.7) GtC/yr on 2015-24
# (TRENDY S2 - S1; lib_block_reopt.R br_net_climate()). At hilda34g the #15 logpost is at its mode, so the P3 mode
# is ONE Newton step away to second order:  du_B = (P_BB + J_B J_B' / s^2)^-1 J_B * (mu - net0) / s^2,  with
# P = -(stored Hessian) and J = d net / d u by central differences. The row is weak (s = 0.7), so the step is small.
# Blocks (every other name held): the preview's 8 (q10 held: must reproduce the 10-04 (i) analytic +0.0066) and 9;
# a POWERED block (the 9 + every seasonal name + npp_frac_NH + tau_ex: q10 power ~0.87); and ALL fitted names
# (the P3 mode itself, to second order).
# ⚠ A Newton step is read ONLY after the objective is evaluated AT it (memory whitened_slope_gate_blind_off_base):
# each step's predicted gain is checked against the evaluated one.
# ⛔ A DIAGNOSTIC: adopts nothing, changes no objective, writes no mode file. No RNG.
# Usage: Rscript calibration/diag_p3_powered_step.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
PS_DRIVER    <- "calibration/diag_p3_powered_step.R"
PS_MODE      <- "hilda34g"
BR_LABEL_LAG <- "hilda_csl3v0kaidgbe"; BR_LABEL_ZERO <- "hilda_csl3v0kaidgb"
PS_ROW       <- c(mean = -0.8, sd = 0.7)               # GtC/yr, 2015-24, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
PS_NET_WIN   <- c(2015L, 2024L); PS_NET_CLIM <- c(1901L, 1920L)
PS_FD_FRAC   <- 0.1                                    # J's central-difference step, x each name's marginal sd in u
PS_BLOCK8    <- c("npp_tsens", "beta_max", "fert_k", "gamma_enso_land_NH", "gamma_enso_land_SH", "luc_scale", "imb_share_land", "ndep_ret")
PS_Q10       <- "q10"; PS_GREEN <- "npp_tsens"
PS_SHOW      <- c("q10", "npp_tsens", "beta_max", "seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p_NH", "npp_frac_NH", "tau_ex")
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
PS_OUT <- file.path("outputs", "diagnostics", sprintf("p3_powered_step_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- local({
  h <- suppressWarnings(tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), error = function(e) character(0)))
  d <- suppressWarnings(tryCatch(system2("git", c("status", "--porcelain", "--", "R", "src", "calibration", "data"), stdout = TRUE),
                                 error = function(e) NA_character_))
  if (length(h) != 1L) "?" else paste0(h, if (anyNA(d)) "+dirty?" else if (length(d)) "+dirty" else "")
})
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))      # objective #15
source(file.path("calibration", "lib_block_reopt.R"))
LOGCON <- file(paste0(PS_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | mode %s | the row N(%+.1f, %.1f) GtC/yr on the net climate effect, %d-%d vs %d-%d climate held\n",
            PS_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), PS_MODE, PS_ROW[["mean"]], PS_ROW[["sd"]],
            PS_NET_WIN[1], PS_NET_WIN[2], PS_NET_CLIM[1], PS_NET_CLIM[2]))

# ---- the frame: hilda34g's objective, exactly as br_cell() builds it ------------------------
BR_OBS <- ccx_prepare_obs()
BR_MD  <- list(LAG = readRDS(ccx_mode_file(PS_MODE))); md <- BR_MD$LAG
stopifnot(identical(ccx_mode_struct(md), BR_LABEL_LAG))
BR_PINS <- stats::setNames(as.numeric(md$pins), names(md$pins))
BR_SPF  <- list(LAG = ccx_spinup_from_label(ccx_mode_spinup(md)))
BR_VB   <- list(LAG = dg_vector(ccx_mode_file(PS_MODE)))
L_LAG   <- md$par_mode[["lag_enso_land"]]
g <- ccx_apply_gate(BR_LABEL_LAG); rp <- ccx_apply_pins(BR_PINS)
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode; bp[[CCX_GATE_FLAG_ENSO_LAG]] <- 1L
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = BR_SPF$LAG, obs = BR_OBS)
pm0 <- ccx_mode_par_with_pins(md); u0 <- ccx_par_to_unc(pm0)
PN  <- md$param_names
stopifnot(identical(names(u0), CCX_PARAM_NAMES), identical(PN, names(u0)), "lag_enso_land" %in% PN)
P  <- -md$hessian; dimnames(P) <- list(PN, PN); S <- md$cov; dimnames(S) <- list(PN, PN)
sdu <- sqrt(diag(S))

# the model vector u implies: br_vec() writes the lag AFTER the block, so the lag is passed from u itself (it is fitted)
vec_u <- function(u) { par <- ccx_unc_to_par(u); br_vec("LAG", unlist(par[PN]), par[["lag_enso_land"]]) }
net_u <- function(u) br_net_climate(vec_u(u), PS_NET_WIN, PS_NET_CLIM)[["net_climate"]]
row_of <- function(net) stats::dnorm(net, PS_ROW[["mean"]], PS_ROW[["sd"]], log = TRUE)
ev <- function(u) { v <- lp(u); n <- net_u(u)
  c(logpost = as.numeric(v), lik = sum(unlist(attr(v, "streams"))), net = n, row = row_of(n)) }

cat("\n=== ID. the frame ===\n")
e0 <- ev(u0)
cat(sprintf("  logpost %.6f (stored %.6f); likelihood %.4f; net climate effect %+.4f GtC/yr -> the row %.4f (z %+.2f)\n",
            e0[["logpost"]], md$logpost, e0[["lik"]], e0[["net"]], e0[["row"]], (e0[["net"]] - PS_ROW[["mean"]]) / PS_ROW[["sd"]]))
if (abs(e0[["logpost"]] - md$logpost) > 1e-6) stop("the frame's identity gate fails")
cat(sprintf("  P = -(stored Hessian): max |S P - I| = %.1e\n", max(abs(S %*% P - diag(length(PN))))))

# ---- J = d net / d u, every fitted name ------------------------------------------------------
cat(sprintf("\n=== J. d(net climate effect)/du by central differences, step %.2f x the marginal sd ===\n", PS_FD_FRAC))
J <- vapply(PN, function(n) { h <- PS_FD_FRAC * sdu[[n]]; e <- stats::setNames(rep(0, length(PN)), PN); e[[n]] <- h
  (net_u(u0 + e) - net_u(u0 - e)) / (2 * h) }, 0)
lev <- J * sdu                                         # GtC/yr per marginal sd
o <- order(-abs(lev)); cat("  the leverage (GtC/yr per marginal sd), the ten largest:\n")
cat(sprintf("    %-20s %+.4f\n", PN[o][1:10], lev[o][1:10]), sep = "")

# ---- the steps ----------------------------------------------------------------------------------
power <- function(B, i) if (!i %in% B) 0 else sqrt(solve(solve(S)[B, B, drop = FALSE])[i, i]) / sqrt(S[i, i])
SEAS <- grep("^seas_|^sst_seas_", PN, value = TRUE)
BLOCKS <- list(
  B8_q10_held  = PS_BLOCK8,
  B9_preview   = c(PS_BLOCK8, PS_Q10),
  B17_powered  = unique(c(PS_BLOCK8, PS_Q10, SEAS, "npp_frac_NH", "tau_ex")),
  ALL          = PN)
r0 <- (PS_ROW[["mean"]] - e0[["net"]]) / PS_ROW[["sd"]]^2
cat(sprintf("\n=== STEPS. du_B = (P_BB + J_B J_B'/s^2)^-1 J_B (mu - net0)/s^2; (mu - net0)/s^2 = %+.4f ===\n", r0))
STEP <- lapply(names(BLOCKS), function(k) { B <- BLOCKS[[k]]
  A <- P[B, B, drop = FALSE] + tcrossprod(J[B]) / PS_ROW[["sd"]]^2
  du <- stats::setNames(rep(0, length(PN)), PN); du[B] <- solve(A, J[B] * r0)
  pred_net <- e0[["net"]] + sum(J * du)
  pred_gain <- (row_of(pred_net) - e0[["row"]]) - 0.5 * drop(crossprod(du[B], P[B, B] %*% du[B]))
  e1 <- ev(u0 + du)
  par0 <- ccx_unc_to_par(u0); par1 <- ccx_unc_to_par(u0 + du)
  list(block = k, names = B, n = length(B), power_q10 = power(B, PS_Q10), power_green = power(B, PS_GREEN), du = du,
       pred_net = pred_net, pred_gain = pred_gain, eval = e1,
       real_gain = (e1[["logpost"]] + e1[["row"]]) - (e0[["logpost"]] + e0[["row"]]),
       show = rbind(at_mode = unlist(par0[PS_SHOW]), at_step = unlist(par1[PS_SHOW])),
       z_shift = du[PS_SHOW] / sdu[PS_SHOW], u = u0 + du) })
names(STEP) <- names(BLOCKS)
for (s in STEP) {
  cat(sprintf("\n  %s (%d names; frees q10 to %.2f and npp_tsens to %.2f of their marginal sds)\n", s$block, s$n, s$power_q10, s$power_green))
  cat(sprintf("    net climate effect %+.4f -> %+.4f predicted, %+.4f evaluated (GtC/yr)\n", e0[["net"]], s$pred_net, s$eval[["net"]]))
  cat(sprintf("    objective + row: gain %+.4f predicted, %+.4f EVALUATED (logpost %+.4f, likelihood %+.4f, row %+.4f)\n",
              s$pred_gain, s$real_gain, s$eval[["logpost"]] - e0[["logpost"]], s$eval[["lik"]] - e0[["lik"]], s$eval[["row"]] - e0[["row"]]))
  for (n in PS_SHOW) if (s$du[[n]] != 0)
    cat(sprintf("    %-15s %.5f -> %.5f  (%+.3f marginal sd)\n", n, s$show["at_mode", n], s$show["at_step", n], s$z_shift[[n]]))
}

# ---- the futures at the full step ---------------------------------------------------------------
cat("\n=== FUTURES (CO2 ppm in 2300) ===\n")
fut_u <- function(u) { v <- vec_u(u)
  stats::setNames(br_futures(v, dg_spinup(v)), sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR)) }
FUT <- rbind(mode = fut_u(u0), ALL_step = fut_u(STEP$ALL$u), B17_step = fut_u(STEP$B17_powered$u))
print(round(FUT, 1))

ccx_unpin_params(rp); ccx_unapply_gate(g)
cat("  ⚠ SECOND ORDER from the mode: the step is exact for a quadratic objective and a linear net effect; the evaluated\n",
    "    gain is the check. CO2 is interactive here and prescribed in TRENDY (bias measured -0.023 GtC/yr at hilda34g).\n", sep = "")
sink(); close(LOGCON)
saveRDS(list(identity = e0, J = J, leverage = lev, steps = lapply(STEP, function(s) s[setdiff(names(s), "u")]), futures = FUT,
             provenance = sprintf("%s @%s; mode %s (%s) at L %.4f; the row N(%g, %g) on %d-%d vs %d-%d climate held; objective #15; FD step %.2f marginal sd; no RNG; %s",
                                  PS_DRIVER, COMMIT, PS_MODE, ccx_mode_file(PS_MODE), L_LAG, PS_ROW[["mean"]], PS_ROW[["sd"]],
                                  PS_NET_WIN[1], PS_NET_WIN[2], PS_NET_CLIM[1], PS_NET_CLIM[2], PS_FD_FRAC, format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(PS_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", PS_OUT))
