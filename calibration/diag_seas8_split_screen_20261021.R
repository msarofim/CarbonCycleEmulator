# =====================================================================
# diag_seas8_split_screen_20261021.R -- T8c step 1: the LOCAL picture before the
# three re-optimizations of the seasonal block ("does the fit split the
# difference between the CO2 and d13C seasonal cycles?").
#
# WHAT IT MEASURES, at the canonical (every non-seasonal parameter held at the mode):
#   - the gradient and Hessian, in the seasonal block's unconstrained coordinates,
#     of EVERY likelihood row and of the log-prior (+ Jacobian), by central
#     differences with one step per direction (S8C_EPS_FRAC x the direction's
#     conditional sd from the mode file's Hessian);
#   - which NON-seasonal rows pull on the block (if any do, a fit on the seasonal
#     rows alone cannot reproduce the mode, and gate (iii) would fail by design);
#   - the quadratic (Newton) prediction of where each fit lands and what each
#     tracer loses -- a cross-check for, and the perturbed STARTS of, the fits.
#
# THE ROW SETS (stated in every output):
#   variant A (Marcus's default): log-prior of the block + the seasonal rows only
#     (i) co2_seasonal_MLO + co2_seasonal_SPO   (ii) d13c_seasonal_MLO + d13c_seasonal_SPO
#     (iii) all four
#   variant B (used only if A cannot reproduce the mode): every row of the objective,
#     (i) minus the two d13C seasonal rows, (ii) minus the two CO2 seasonal rows,
#     (iii) all of them = the canonical objective restricted to the block.
# The non-block priors are constants here (their parameters are held) and are included.
#
# Usage: Rscript calibration/diag_seas8_split_screen_20261021.R   (no RNG)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8C_DRIVER   <- "calibration/diag_seas8_split_screen_20261021.R"
S8C_COMMIT   <- ccx_git_stamp()
S8C_EPS_FRAC <- 0.1        # FD step, as a fraction of each direction's conditional sd (CCX_HESS_EPS_FRAC's value)
S8C_GATE_SD_FRAC <- 0.1    # gate (iii): every block parameter within this fraction of its marginal sd
# THE BLOCK: every SEASONAL name the canonical could fit; the ones it FITS are those still in
# CCX_PARAM_NAMES after its pins are applied (ent_seas_amp_SH is pinned 0 at hilda31w).
S8C_SEAS_CANDIDATES <- c("npp_frac_NH", "seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p_NH", "seas_lag_p_SH",
                         "sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_lag", "ent_seas_amp_SH",
                         "tau_ex_seas_amp", "pump_seas_amp", "pump_hs_seas_amp")
S8C_STEM <- file.path(S8_OUT_DIR, sprintf("t8c_screen_%s", S8_MODE))
dir.create(S8_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s ===\n", S8C_DRIVER, S8C_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))
S <- s8_setup(S8C_DRIVER)
BLOCK <- intersect(S8C_SEAS_CANDIDATES, CCX_PARAM_NAMES)
say("BLOCK (fitted seasonal names, %d): %s\n", length(BLOCK), paste(BLOCK, collapse = ", "))
say("seasonal candidates NOT fitted at %s: %s\n", S8_MODE,
    paste(sprintf("%s (%s)", setdiff(S8C_SEAS_CANDIDATES, BLOCK),
                  ifelse(setdiff(S8C_SEAS_CANDIDATES, BLOCK) %in% names(S$pins), "pinned", "not a fitted name")),
          collapse = ", "))

fs <- ccx_mode_fit_stats(S$md)
pn <- S$md$param_names
sd_cond <- stats::setNames(fs$sd_conditional, pn)[BLOCK]
sd_marg <- stats::setNames(fs$sd, pn)[BLOCK]
eps <- S8C_EPS_FRAC * sd_cond
u0 <- S$u0
say("steps (u): %s\n", paste(sprintf("%s %.3g", BLOCK, eps), collapse = ", "))

ev <- function(du) {
  u <- u0; u[BLOCK] <- u[BLOCK] + du
  v <- S$lp(u)
  c(logprior = attr(v, "logprior"), unlist(attr(v, "streams")))
}
t0 <- proc.time()
f0 <- ev(rep(0, length(BLOCK)))
comp <- names(f0); nb <- length(BLOCK)
E1p <- E1m <- matrix(NA_real_, nb, length(comp), dimnames = list(BLOCK, comp))
for (i in seq_len(nb)) {
  d <- rep(0, nb); d[i] <- eps[i]; E1p[i, ] <- ev(d); E1m[i, ] <- ev(-d)
}
E2 <- array(NA_real_, c(nb, nb, 4, length(comp)))
for (i in seq_len(nb - 1)) for (j in (i + 1):nb) {
  k <- 0
  for (si in c(1, -1)) for (sj in c(1, -1)) {
    k <- k + 1; d <- rep(0, nb); d[i] <- si * eps[i]; d[j] <- sj * eps[j]; E2[i, j, k, ] <- ev(d)
  }
}
say("%d evaluations in %.1f s\n", 1 + 2 * nb + 2 * nb * (nb - 1), (proc.time() - t0)[["elapsed"]])

G <- (E1p - E1m) / (2 * eps)                                     # nb x comp
Hc <- array(NA_real_, c(nb, nb, length(comp)), dimnames = list(BLOCK, BLOCK, comp))
for (c_ in seq_along(comp)) {
  for (i in seq_len(nb)) Hc[i, i, c_] <- (E1p[i, c_] - 2 * f0[c_] + E1m[i, c_]) / eps[i]^2
  for (i in seq_len(nb - 1)) for (j in (i + 1):nb) {
    h <- (E2[i, j, 1, c_] - E2[i, j, 2, c_] - E2[i, j, 3, c_] + E2[i, j, 4, c_]) / (4 * eps[i] * eps[j])
    Hc[i, j, c_] <- Hc[j, i, c_] <- h
  }
}
rows_all <- setdiff(comp, "logprior")
SETS <- list(
  A_i   = c("logprior", S8_SEAS_ROWS$co2),
  A_ii  = c("logprior", S8_SEAS_ROWS$d13),
  A_iii = c("logprior", S8_SEAS_ROWS$co2, S8_SEAS_ROWS$d13),
  B_i   = c("logprior", setdiff(rows_all, S8_SEAS_ROWS$d13)),
  B_ii  = c("logprior", setdiff(rows_all, S8_SEAS_ROWS$co2)),
  B_iii = c("logprior", rows_all))
gH <- function(set) list(g = rowSums(G[, set, drop = FALSE]), H = apply(Hc[, , set, drop = FALSE], c(1, 2), sum))

# ---- 1. which rows pull on the block at the mode ----------------------------
say("\n=== 1. GRADIENT AT THE MODE, per row (log-units per canonical marginal sd of the parameter) ===\n")
say("  Only rows with max |g x sd| > 0.01 are listed. A non-seasonal row listed here PULLS the block.\n")
GS <- sweep(G, 1, sd_marg, `*`)
show <- comp[apply(abs(GS), 2, max) > 0.01]
say("  %-22s %s\n", "row", paste(sprintf("%10s", substr(BLOCK, 1, 10)), collapse = ""))
for (c_ in show) say("  %-22s %s\n", c_, paste(sprintf("%10.3f", GS[, c_]), collapse = ""))
say("  %-22s %s\n", "SUM (full objective)", paste(sprintf("%10.3f", rowSums(GS)), collapse = ""))
say("  %-22s %s\n", "SUM seasonal+prior", paste(sprintf("%10.3f", rowSums(GS[, SETS$A_iii])), collapse = ""))
say("  %-22s %s\n", "SUM non-seasonal", paste(sprintf("%10.3f", rowSums(GS[, setdiff(rows_all, unlist(S8_SEAS_ROWS))])), collapse = ""))

# ---- 2. quadratic predictions --------------------------------------------------
say("\n=== 2. QUADRATIC (NEWTON) PREDICTION of each fit, from the mode ===\n")
pred <- list()
for (s in names(SETS)) {
  q <- gH(SETS[[s]])
  ev_ <- eigen(q$H, symmetric = TRUE, only.values = TRUE)$values
  nd <- all(ev_ < 0)
  du <- if (nd) -solve(q$H, q$g) else rep(NA_real_, nb)
  msd <- if (nd) sqrt(diag(solve(-q$H))) else rep(NA_real_, nb)
  gain <- if (nd) -0.5 * sum(q$g * solve(q$H, q$g)) else NA_real_
  pred[[s]] <- list(du = stats::setNames(du, BLOCK), marg_sd = stats::setNames(msd, BLOCK), gain = gain,
                    neg_def = nd, eig = ev_, g = q$g, H = q$H)
  say("  %-6s neg-def %-5s gain %8.3f | du/marg_sd(own): %s\n", s, nd, gain,
      paste(sprintf("%s %+.2f", substr(BLOCK, 1, 12), du / msd), collapse = ", "))
}
say("\n  Predicted (iii) displacement from the mode, in its own marginal sd (gate tolerance %.2f):\n", S8C_GATE_SD_FRAC)
for (s in c("A_iii", "B_iii")) {
  z <- pred[[s]]$du / pred[[s]]$marg_sd
  say("    %-6s max |du/sd| %.3f (%s) -> %s\n", s, max(abs(z)), BLOCK[which.max(abs(z))],
      if (isTRUE(max(abs(z)) <= S8C_GATE_SD_FRAC)) "would REPRODUCE the mode" else "would NOT reproduce the mode")
}

# ---- 3. predicted tracer losses --------------------------------------------------
say("\n=== 3. PREDICTED LOSSES (quadratic): each tracer's seasonal rows, joint fit vs its solo fit ===\n")
trq <- function(set_rows, du) { q <- gH(set_rows); sum(q$g * du) + 0.5 * sum(du * (q$H %*% du)) }
for (v in c("A", "B")) {
  pi_ <- pred[[paste0(v, "_i")]]$du; pii <- pred[[paste0(v, "_ii")]]$du; piii <- pred[[paste0(v, "_iii")]]$du
  if (anyNA(c(pi_, pii, piii))) { say("  variant %s: a Hessian is not negative definite; no prediction\n", v); next }
  lc_solo <- trq(S8_SEAS_ROWS$co2, pi_); lc_joint <- trq(S8_SEAS_ROWS$co2, piii)
  ld_solo <- trq(S8_SEAS_ROWS$d13, pii); ld_joint <- trq(S8_SEAS_ROWS$d13, piii)
  say("  variant %s: CO2 rows  solo %+8.3f joint %+8.3f -> loss %8.3f | d13C rows solo %+8.3f joint %+8.3f -> loss %8.3f (relative to the mode)\n",
      v, lc_solo, lc_joint, lc_joint - lc_solo, ld_solo, ld_joint, ld_joint - ld_solo)
}

saveRDS(list(block = BLOCK, eps = eps, sd_cond = sd_cond, sd_marg = sd_marg, f0 = f0, G = G, H = Hc,
             sets = SETS, pred = pred, u0 = u0,
             provenance = list(driver = S8C_DRIVER, lib = "calibration/lib_seas8_20261021.R",
                               commit = S8C_COMMIT, mode = S8_MODE, mode_file = S$mode_file,
                               mode_md5 = S$mode_md5, eps_frac = S8C_EPS_FRAC,
                               units = "u = the objective's unconstrained coordinates; log-units",
                               rng = "none", built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8C_STEM, ".rds"))
say("\nwrote %s.rds\n=== DONE ===\n", S8C_STEM)
