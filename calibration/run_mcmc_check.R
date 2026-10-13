# =====================================================================
# run_mcmc_check.R -- ONE CHAIN of the MCMC check on the Laplace ribbons
# (Marcus 2026-10-01, review 10-01c B7: "Laplace first, MCMC as the check";
# where: "Torch (Recommended)").
#
# WHAT. Adaptive Metropolis (Haario, Saksman & Tamminen 2001, Bernoulli 7:223)
# on the canonical's own objective -- its fitted names, its held values held,
# the file's own bands and spin-up: the space the mode and its Laplace
# covariance live in. (Written at hilda33d: 33 fitted, nine held. At hilda29e,
# 2026-10-08 j, Marcus "MCMC band": 29 fitted, 14 held -- the interannual cut's
# four module names among them, so the chains sample the MAIN FIT CONDITIONAL ON
# STAGE 1 AT ITS MODE; the module's move shifts the 2300 futures <= 0.6 ppm,
# CHANGELOG 10-07 h. Nothing below names a count.) The proposal starts as the Laplace covariance scaled by
# 2.38^2/d and adapts to the chain's running covariance until --adapt, then is
# FROZEN, so the samples after it are a valid (non-adaptive) Metropolis chain.
# Each chain starts OVERDISPERSED (u0 + 2 x a Laplace draw) so between-chain
# variance means something for R-hat.
#
# WHY NOT ccx_run_mcmc(). It starts at the parameter TABLE's inits, never
# applies the canonical's gate, pins or bands (it would sample the full 38-name
# table, not the 33-name space the mode lives in), and has no checkpoint -- and
# Torch's cpu_short wall (6 h) is shorter than one 1e5-evaluation chain
# (~9 h at the 0.33 s/eval measured on its nodes).
#
# CHECKPOINTED AND EXACTLY RESUMABLE. Every --ckpt iterations the whole state
# -- position, log-posterior, adaptation sums, stored samples, AND the RNG state
# (.Random.seed) -- is written to <out>/chain_<k>.rds. A re-run with the same
# arguments resumes from it, and an interrupted-then-resumed chain is the same
# chain an uninterrupted one would have been. --wall_min stops cleanly with a
# checkpoint before the scheduler kills the job.
#
# EXTENDABLE (2026-10-09, Marcus: "Extend to 200k"). A chain COMPLETE at its
# recorded n may be re-run with a LARGER --n and continues. Past --adapt the
# proposal is frozen, so n enters nothing but the stopping test, and the
# extended chain is the uninterrupted --n chain (bit-identity shown on a short
# chain, CHANGELOG 2026-10-09 b). Each extension is recorded in
# provenance$extended (from, to, commit); provenance$n becomes the new n.
#
# REPRODUCIBILITY: the chain's seed (MC_SEED_BASE + chain), the RNG kind and
# where the seed is applied are stored IN the output.
#
# Usage (from the repo root):
#   Rscript calibration/run_mcmc_check.R --chain=1 [--n=100000] [--adapt=30000]
#           [--thin=20] [--ckpt=500] [--wall_min=340] [--out=outputs/mcmc_check] [--commit=<sha>]
# =====================================================================
MC_ARGS <- commandArgs(trailingOnly = TRUE)
mc_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), MC_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
options(warn = 1)

# ---- named constants: every label and filename derives from these --------
MC_DRIVER     <- "calibration/run_mcmc_check.R"
MC_CHAIN      <- as.integer(mc_arg("chain", NA)); stopifnot(is.finite(MC_CHAIN), MC_CHAIN >= 1L)
MC_N          <- as.integer(mc_arg("n", 100000L))      # iterations (= log-posterior evaluations)
MC_ADAPT      <- as.integer(mc_arg("adapt", 30000L))   # adaptation stops here; samples after it are kept
MC_T0         <- as.integer(mc_arg("t0", min(1000L, MC_ADAPT %/% 3L)))   # iterations on the Laplace proposal before adapting
MC_THIN       <- as.integer(mc_arg("thin", 20L))
MC_CKPT       <- as.integer(mc_arg("ckpt", 500L))
MC_WALL_MIN   <- as.numeric(mc_arg("wall_min", Inf))
MC_OUT_DIR    <- mc_arg("out", file.path("outputs", "mcmc_check"))
MC_SEED_BASE  <- 20261001L
MC_RNG_KIND   <- c("Mersenne-Twister", "Inversion", "Rejection")
MC_OVERDISP   <- 2                                      # start = u0 + MC_OVERDISP x a Laplace draw
# REDRAW UNTIL FINITE (2026-10-13; Marcus: "Redraw until finite (Recommended)"). At hilda31w the h_ml mode (69.5 m) sits
# ~6 m under the P8 wall (75.48 m), where the model refuses, and chains 1-2's 2x draws landed past it (78.6, 82.9 m). The
# posterior has no mass there, so a start past the wall is redrawn from the SAME stream, up to MC_START_MAX_DRAWS, and the
# count is recorded. A chain whose first draw is finite starts exactly as before (hilda29e's chains are unchanged).
MC_START_MAX_DRAWS <- 50L
MC_EPS        <- 1e-8                                   # Haario's regulariser, u-space units^2
MC_LP_TOL     <- CCX_REPRO_TOL                          # the mode reproduces its stored logpost. RULED (Marcus 2026-10-13: "Use CCX_REPRO_TOL (Recommended)"; CHANGELOG 2026-10-13 o); was 1e-5, measured diff 0
# A copy that is not a checkout cannot stamp itself, so its commit is SUPPLIED, and labelled as
# supplied: on Torch the copy is make_bundle.sh's tar of the working tree, not a git archive.
MC_COMMIT <- if (nzchar(mc_arg("commit", ""))) paste(mc_arg("commit", ""), "(supplied by --commit: the running copy is not a checkout)") else
  ccx_git_stamp()
stopifnot(MC_ADAPT < MC_N, MC_T0 < MC_ADAPT)
dir.create(MC_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
MC_FILE <- file.path(MC_OUT_DIR, sprintf("chain_%d.rds", MC_CHAIN))
t_start <- Sys.time()

# ---- the space: the canonical's gate, pins, bands, spin-up ----------------
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(PINS))
ccx_require_param_set(md, MC_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
u0  <- ccx_par_to_unc(md$par_mode)
Sig <- ccx_mode_fit_stats(md)$cov
stopifnot(identical(names(u0), md$param_names), identical(rownames(Sig), names(u0)))
d   <- length(u0)
bp  <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
lp_eval <- function(u) { v <- tryCatch(as.numeric(lpf(u)), error = function(e) -Inf)
  if (is.finite(v)) v else -Inf }

# ---- GATE: the objective reproduces the mode's stored logpost --------------
lp0 <- lp_eval(u0)
cat(sprintf("[%s chain %d @%s] mode %s logpost: recomputed %.6f, stored %.6f (diff %.2e)\n",
            MC_DRIVER, MC_CHAIN, MC_COMMIT, CCX_MODE_CANONICAL, lp0, md$logpost, lp0 - md$logpost))
if (!(abs(lp0 - md$logpost) < MC_LP_TOL)) stop("the objective does not reproduce the mode: not sampling it")

# ---- start, or resume -----------------------------------------------------
sd_scale <- 2.38^2 / d
if (file.exists(MC_FILE)) {
  S <- readRDS(MC_FILE)
  # EXTENSION (header): only a chain that finished its recorded n, with adaptation already over
  if (MC_N > S$provenance$n) {
    if (!(S$iter == S$provenance$n && S$provenance$n > S$provenance$adapt))
      stop(sprintf("chain %d: --n %d > its recorded n %d, but it is at iteration %d (adapt %d): only a COMPLETE, post-adaptation chain extends",
                   MC_CHAIN, MC_N, S$provenance$n, S$iter, S$provenance$adapt))
    S$provenance$extended <- c(S$provenance$extended,
                               list(list(from = S$provenance$n, to = MC_N, commit = MC_COMMIT)))
    cat(sprintf("extending chain %d: %d -> %d iterations\n", MC_CHAIN, S$provenance$n, MC_N))
    S$provenance$n <- MC_N
  }
  # t0 and ckpt are checked too: the proposal is refreshed AT checkpoints inside [t0, adapt], so a
  # resume under either one changed is not the uninterrupted chain
  stopifnot(identical(S$provenance$mode_par, md$par_mode), S$provenance$n == MC_N,
            S$provenance$adapt == MC_ADAPT, S$provenance$thin == MC_THIN,
            identical(S$provenance$t0, MC_T0), identical(S$provenance$ckpt, MC_CKPT))
  if (S$iter >= MC_N) { cat(sprintf("chain %d already complete (%d iterations)\n", MC_CHAIN, S$iter)); quit(save = "no") }
  RNGkind(MC_RNG_KIND[1], MC_RNG_KIND[2], MC_RNG_KIND[3])
  assign(".Random.seed", S$rng_state, envir = globalenv())
  cat(sprintf("resuming chain %d at iteration %d\n", MC_CHAIN, S$iter))
} else {
  RNGkind(MC_RNG_KIND[1], MC_RNG_KIND[2], MC_RNG_KIND[3])
  set.seed(MC_SEED_BASE + MC_CHAIN)       # immediately before the first draw this chain makes
  L0 <- chol(Sig)
  draw_start <- function() { u <- u0 + MC_OVERDISP * as.vector(stats::rnorm(d) %*% L0); names(u) <- names(u0); u }
  u_start <- draw_start(); lp_start <- lp_eval(u_start); n_redraw <- 0L
  while (!is.finite(lp_start) && n_redraw < MC_START_MAX_DRAWS - 1L) {
    n_redraw <- n_redraw + 1L
    cat(sprintf("chain %d: start draw %d has a non-finite log-posterior (h_ml %.2f); redrawing from the same stream\n",
                MC_CHAIN, n_redraw, ccx_unc_to_par(u_start)$h_ml))
    u_start <- draw_start(); lp_start <- lp_eval(u_start)
  }
  S <- list(iter = 0L, u = u_start, lp = lp_start, n_acc = 0L, n_acc_post = 0L,
            sum_u = numeric(d), sum_uu = matrix(0, d, d), n_sum = 0L, C = Sig,
            samples = matrix(NA_real_, 0, d, dimnames = list(NULL, names(u0))), samples_lp = numeric(0),
            samples_iter = integer(0), lp_trace = numeric(0),
            provenance = list(driver = MC_DRIVER, commit = MC_COMMIT, mode = CCX_MODE_CANONICAL,
              struct = ccx_mode_struct(md), mode_par = md$par_mode, mode_logpost = md$logpost,
              u0 = u0, laplace_cov = Sig, held = PINS, chain = MC_CHAIN, n = MC_N, adapt = MC_ADAPT,
              t0 = MC_T0, thin = MC_THIN, ckpt = MC_CKPT, overdispersion = MC_OVERDISP, eps = MC_EPS,
              host = Sys.info()[["nodename"]], r_version = R.version.string,
              proposal = sprintf("adaptive Metropolis (Haario et al. 2001): N(u, %.4f x C), C = the Laplace covariance until iteration %d, then the chain's running covariance + eps I, FROZEN from iteration %d", sd_scale, MC_T0, MC_ADAPT),
              seed = MC_SEED_BASE + MC_CHAIN, rng_kind = MC_RNG_KIND,
              seed_applied = "set.seed() immediately before the start draw; the RNG state is carried through every checkpoint, so a resumed chain is the uninterrupted chain",
              start_redraws = n_redraw,
              start_rule = sprintf("u0 + %g x a Laplace draw, redrawn from the same stream while its log-posterior is non-finite (at most %d draws)",
                                   MC_OVERDISP, MC_START_MAX_DRAWS),
              emis_method = CCX_EMIS_METHOD_DEFAULT, spinup = ccx_mode_spinup(md)))
  if (!is.finite(S$lp)) stop(sprintf("the overdispersed start has a non-finite log-posterior after %d draws", MC_START_MAX_DRAWS))
  cat(sprintf("chain %d starts at logpost %.3f (mode %.3f) after %d redraw(s)\n", MC_CHAIN, S$lp, lp0, n_redraw))
}

save_state <- function() {
  S$rng_state <<- get(".Random.seed", envir = globalenv())
  tmp <- paste0(MC_FILE, ".tmp"); saveRDS(S, tmp); file.rename(tmp, MC_FILE)   # never a half-written file
}

# ---- the chain ------------------------------------------------------------
Lp <- chol(sd_scale * S$C + sd_scale * MC_EPS * diag(d))
while (S$iter < MC_N) {
  it <- S$iter + 1L
  # the proposal factor follows the adaptation schedule: the Laplace proposal until MC_T0, the
  # running covariance after it (refreshed each checkpoint), frozen from MC_ADAPT
  prop <- S$u + as.vector(stats::rnorm(d) %*% Lp); names(prop) <- names(S$u)
  lpp <- lp_eval(prop)
  if (log(stats::runif(1)) < lpp - S$lp) {
    S$u <- prop; S$lp <- lpp; S$n_acc <- S$n_acc + 1L
    if (it > MC_ADAPT) S$n_acc_post <- S$n_acc_post + 1L
  }
  S$iter <- it
  S$lp_trace[it] <- S$lp
  if (it <= MC_ADAPT) {            # the adaptation's running moments
    S$sum_u <- S$sum_u + S$u; S$sum_uu <- S$sum_uu + tcrossprod(S$u); S$n_sum <- S$n_sum + 1L
  }
  if (it > MC_ADAPT && (it - MC_ADAPT) %% MC_THIN == 0L) {
    S$samples <- rbind(S$samples, S$u); S$samples_lp <- c(S$samples_lp, S$lp)
    S$samples_iter <- c(S$samples_iter, it)
  }
  if (it %% MC_CKPT == 0L || it == MC_N) {
    if (it >= MC_T0 && it <= MC_ADAPT && S$n_sum > d + 1L) {
      m <- S$sum_u / S$n_sum
      S$C <- (S$sum_uu - S$n_sum * tcrossprod(m)) / (S$n_sum - 1L)
      Lp <- chol(sd_scale * S$C + sd_scale * MC_EPS * diag(d))
    }
    save_state()
    el <- as.numeric(difftime(Sys.time(), t_start, units = "mins"))
    cat(sprintf("chain %d iter %d/%d  logpost %.3f  acceptance %.3f%s  (%.1f min)\n", MC_CHAIN, it, MC_N, S$lp,
                S$n_acc / it, if (it > MC_ADAPT) sprintf(", post-adapt %.3f", S$n_acc_post / (it - MC_ADAPT)) else "", el))
    if (el > MC_WALL_MIN) { cat(sprintf("wall %.0f min reached: checkpointed at %d, resume with the same command\n",
                                        MC_WALL_MIN, it)); quit(save = "no") }
  }
}
cat(sprintf("chain %d COMPLETE: %d iterations, %d kept samples, acceptance %.3f (post-adapt %.3f)\n",
            MC_CHAIN, S$iter, nrow(S$samples), S$n_acc / S$iter, S$n_acc_post / (S$iter - MC_ADAPT)))
