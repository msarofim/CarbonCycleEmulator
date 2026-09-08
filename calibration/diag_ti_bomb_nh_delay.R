# =====================================================================
# T-I (handoff 2026-09-08g §1): the NH bomb-14C TIMING probe at the canonical
# hilda31. Gate 5's NH peak is +2.17 sigma LATE (0.96 yr). Can a delay of the
# NH input alone -- what a stratospheric reservoir (option I) would do -- move
# it, or is the miss in the exchange (`tau_ex`, hemisphere-specific)?
#
# PRE-REGISTERED: a 1-yr delay moves the NH peak z from +2.17 to < +1.
# FALSIFIED IF: < 0.5 sigma of movement -- then it is tau_ex.
#
# HOW, without touching either core. The forcing has ONE bomb column split by
# aux$bomb_share_NH (0.9). The 14C state is LINEAR in its sources at a fixed
# 12C trajectory (14C is a tracer; every rate depends on C, not on C14), so the
# response to "NH limb delayed, SH limb as shipped" is a SUPERPOSITION of fast
# C++ runs:  x = x_A + share x (x_C1 - x_D1), with x = 1 + D14C/1000 (~ atm C14
# at fixed C), A the canonical, D1/C1 the WHOLE column into the NH at the
# original / delayed timing. GATED: the whole-column delay run must equal its
# four-part superposition to roundoff, or the premise is wrong.
# Two limb shapes: a PURE delay (the handoff's) and a first-order RESERVOIR of
# e-folding time tau (what a stratosphere is), mass-conserving.
# Usage: Rscript calibration/diag_ti_bomb_nh_delay.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
TI_DELAYS  <- seq(0, 2, by = 0.25)     # yr, pure delay of the NH limb (0 = identity)
TI_TAUS    <- c(0.5, 1, 1.5, 2)        # yr, first-order stratospheric reservoir on the NH limb
TI_P_DELAY <- 1.0; TI_P_Z <- 1.0       # prediction: at a 1-yr delay z_NH < +1
TI_FALS_DZ <- 0.5                      # falsified if the 1-yr delay moves z_NH by < 0.5
TI_LIN_TOL <- 1e-6                     # permil: the superposition gate
TI_OUT <- ccx_path("outputs", "diagnostics", sprintf("ti_bomb_nh_delay_%s.rds", format(Sys.Date(), "%Y%m%d")))

v <- dg_vector(CCX_MODE_CANONICAL); sp <- ccx_spinup(v$p)
F <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
share <- sp$aux$bomb_share_NH
cat(sprintf("T-I at %s: bomb_share_NH %.2f, tau_ex %.3f, bomb total %.1f kmol; forcing %d monthly rows %g-%g\n", CCX_MODE_CANONICAL, share, v$p$tau_ex, v$bomb_total, nrow(F), min(F$t), max(F$t)))
with_share <- function(s) { s2 <- sp; s2$aux$bomb_share_NH <- s; s2 }
run  <- function(spx, Fx) ccx_run_fast(spx, Fx)$out
x_of <- function(o, h) 1 + o[[paste0("d14c_", h)]] / 1000
shift_col <- function(k) { F2 <- F; n <- nrow(F); if (k > 0) F2$c14_bomb <- c(rep(0, k), F$c14_bomb[seq_len(n - k)]); F2 }
reservoir_col <- function(tau) { F2 <- F; dt <- 1 / 12; s <- 0; out <- numeric(nrow(F))
  for (i in seq_len(nrow(F))) { out[i] <- s / tau; s <- s + (F$c14_bomb[i] - s / tau) * dt }   # mass-conserving first-order box
  F2$c14_bomb <- out; F2 }
A  <- run(sp, F); D1 <- run(with_share(1), F); D0 <- run(with_share(0), F)
stopifnot(max(abs(D1$d14c_NH - A$d14c_NH)) > 1)          # the share IS read from aux by the core
# GATE: superposition, on a whole-column 1-yr delay
Fk <- shift_col(12L); B <- run(sp, Fk); C1 <- run(with_share(1), Fk); C0 <- run(with_share(0), Fk)
for (h in HEMIS) { err <- 1000 * max(abs(x_of(B, h) - (x_of(A, h) + share * (x_of(C1, h) - x_of(D1, h)) + (1 - share) * (x_of(C0, h) - x_of(D0, h)))))
  cat(sprintf("GATE superposition %s: whole-column delay vs its four-part sum, max |diff| %.2e permil (tol %g) -> %s\n", h, err, TI_LIN_TOL, if (err < TI_LIN_TOL) "PASS" else "FAIL")); stopifnot(err < TI_LIN_TOL) }
combine <- function(Fx) { Cx <- run(with_share(1), Fx); o <- A
  for (h in HEMIS) o[[paste0("d14c_", h)]] <- 1000 * (x_of(A, h) + share * (x_of(Cx, h) - x_of(D1, h)) - 1); o }
ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread()
score <- function(o) { g <- dg_gate5(list(out = o)); vd <- dg_gate5_verdict(g, ob5, sp5)
  c(nh_t = g$pk$NH[["t"]], nh_v = g$pk$NH[["v"]], sh_t = g$pk$SH[["t"]], sh_v = g$pk$SH[["v"]], lag = g$lag, z_nh = vd$z[["nh_t"]], z_sh = vd$z[["sh_t"]], z_lag = vd$z[["lag"]], pass = as.numeric(vd$pass)) }
cat(sprintf("\nobserved: NH peak %.3f (%.0f permil), SH %.3f (%.0f), lag %.3f; sd nh_t %.3f sh_t %.3f lag %.3f\n", ob5$NH[["t"]], ob5$NH[["v"]], ob5$SH[["t"]], ob5$SH[["v"]], ob5$SH[["t"]] - ob5$NH[["t"]], sp5$sd[["nh_t"]], sp5$sd[["sh_t"]], sp5$sd[["lag"]]))
cat("\n=== 1. PURE DELAY of the NH limb ===\n"); cat(sprintf("  %6s %9s %6s %9s %6s %6s | %6s %6s %6s %s\n", "delay", "NH peak", "permil", "SH peak", "permil", "lag", "z NH", "z SH", "z lag", "gate 5"))
PD <- t(vapply(TI_DELAYS, function(d) score(combine(shift_col(as.integer(round(d * 12))))), numeric(9)))
for (k in seq_along(TI_DELAYS)) cat(sprintf("  %6.2f %9.3f %6.0f %9.3f %6.0f %6.3f | %+6.2f %+6.2f %+6.2f %s\n", TI_DELAYS[k], PD[k, "nh_t"], PD[k, "nh_v"], PD[k, "sh_t"], PD[k, "sh_v"], PD[k, "lag"], PD[k, "z_nh"], PD[k, "z_sh"], PD[k, "z_lag"], if (PD[k, "pass"] == 1) "PASS" else "FAIL"))
cat("\n=== 2. FIRST-ORDER RESERVOIR on the NH limb (e-folding tau) ===\n")
PR <- t(vapply(TI_TAUS, function(tau) score(combine(reservoir_col(tau))), numeric(9)))
for (k in seq_along(TI_TAUS)) cat(sprintf("  tau %4.2f %9.3f %6.0f %9.3f %6.0f %6.3f | %+6.2f %+6.2f %+6.2f %s\n", TI_TAUS[k], PR[k, "nh_t"], PR[k, "nh_v"], PR[k, "sh_t"], PR[k, "sh_v"], PR[k, "lag"], PR[k, "z_nh"], PR[k, "z_sh"], PR[k, "z_lag"], if (PR[k, "pass"] == 1) "PASS" else "FAIL"))
cat("\n=== 3. VERDICT ===\n")
z0 <- PD[1, "z_nh"]; z1 <- PD[which.min(abs(TI_DELAYS - TI_P_DELAY)), "z_nh"]
cat(sprintf("  identity (delay 0) reproduces the canonical's z NH %+.2f (scorecard +2.17)\n", z0))
cat(sprintf("  prediction 'a %.0f-yr NH delay moves z NH to < %+.0f': z %+.2f -> %+.2f (moved %+.2f) -> %s\n", TI_P_DELAY, TI_P_Z, z0, z1, z1 - z0,
            if (z1 < TI_P_Z) "CONFIRMED (timing CAN carry the miss)" else if (abs(z1 - z0) < TI_FALS_DZ) "FALSIFIED (< 0.5 sigma: the miss is the exchange, tau_ex)" else if (z1 > z0) "FALSIFIED IN SIGN: the peak is sensitive to input timing (~1 yr per yr) but the model's peak is ALREADY LATE, so a reservoir -- which can only DELAY -- moves it the wrong way. Option I is ruled out as built; what the miss needs is FASTER early removal from the NH atmosphere (the exchange), not later input." else "moved, but not to < +1"))
cat(sprintf("  the direction: a LATER NH input makes the NH peak %s; the SH peak moves %+.3f yr per yr of NH delay, the lag %+.3f\n", if (z1 > z0) "LATER (worse)" else "EARLIER (toward the observation)", (PD[which.min(abs(TI_DELAYS - 1)), "sh_t"] - PD[1, "sh_t"]), (PD[which.min(abs(TI_DELAYS - 1)), "lag"] - PD[1, "lag"])))
saveRDS(list(delay = data.frame(delay = TI_DELAYS, PD), reservoir = data.frame(tau = TI_TAUS, PR), obs = list(ob5 = ob5, sp5 = sp5), share = share, mode = CCX_MODE_CANONICAL, date = Sys.time()), TI_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TI_OUT))
