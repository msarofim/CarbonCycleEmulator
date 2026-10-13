#!/usr/bin/env Rscript
# =====================================================================
# run_price_profile.R -- a PRICE PROFILE at the canonical: ONE fitted name HELD at a value, every other fitted name
# re-optimised, from ONE named start. Two starts that agree are the convergence check.
#
# WHY (2026-10-13). Card 7 says of k_w: "The data slightly prefer the literature value [Naegler 2009's 1,446]; what
# holds it higher is the stated prior on how much gas exchange the cold high-latitude box gets". That was MEASURED at
# hilda33p (10-05 a, a 24-start wave with k_w pinned) and never at hilda31w. Marcus: "Two-start profile, Mac
# (Recommended)": start A at hilda31w's mode, start B warm from the 10-05 k_w = 1446 solution.
#
# WHAT IT REUSES, NOT RE-IMPLEMENTS: the objective is run_mcmc_check.R's harness exactly (the canonical's gate, pins,
# bands, structure, spin-up), with the held name ADDED to the pins, as run_dispersed_multistart.R holds one (CCX_MS_PIN;
# ccx_pins_price_canonical(): "the canonical's objective with one READ name held"). The optimiser follows that driver's
# recipe and constants (Nelder-Mead restarts, then a BFGS polish, per cycle; the cycle and restart stopping rules; a
# budget on the CPU clock; an infeasible step scored strictly worse than the start). It is a re-statement of the recipe,
# not the wave's code: the wave's start/reference machinery has no slot for a warm start from another objective's mode.
#
# GATES (stop on any): the canonical objective reproduces its stored logpost (CCX_REPRO_TOL); the start is finite; the
# returned point is re-EVALUATED (optim() can return a point it never evaluated -- the wave's claim-gap rule) and the
# best EVALUATED point is the one kept.
# Usage: Rscript calibration/run_price_profile.R --hold=k_w=1446 --start=canonical|<mode file> --tag=A
#                [--out-dir=outputs/diagnostics/price_profile_<date>_<mode>] [--budget-min=300]
#   (--cycles / --nm-maxit / --polish-maxit shrink the recipe for a SMOKE run; a real profile leaves them unset)
# Resumable: a checkpoint per restart; re-running the same command continues it. No RNG.
# =====================================================================
PP_ARGS <- commandArgs(trailingOnly = TRUE)
pp_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), PP_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and filename derives from these --------
PP_DRIVER   <- "calibration/run_price_profile.R"
PP_HOLD_STR <- pp_arg("hold", "")
PP_START    <- pp_arg("start", "")
PP_TAG      <- pp_arg("tag", "")
PP_BUDGET_MIN <- as.numeric(pp_arg("budget-min", 300))   # run_dispersed_multistart.R's runners export 300, CPU clock
PP_OUT_DIR  <- pp_arg("out-dir", file.path("outputs", "diagnostics",
                                           sprintf("price_profile_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL)))
# THE WAVE'S RECIPE (calibration/run_dispersed_multistart.R defaults and constants, as at 10-13)
PP_RESTARTS <- 3L                                            # CCX_MS_RESTARTS default
PP_CYCLES   <- as.integer(pp_arg("cycles", 6L))              # CCX_MS_CYCLES default; the args exist for a SMOKE run only
PP_NM_MAXIT <- as.integer(pp_arg("nm-maxit", 6000L))         # CCX_MS_MAXIT default
PP_TOL       <- 1e-4    # MS_TOL: a restart gaining less than this stops the cycle
PP_CYCLE_TOL <- 0.5     # MS_CYCLE_TOL: a cycle gaining less than this is CONVERGED
PP_POLISH_MAXIT <- as.integer(pp_arg("polish-maxit", 500L)) # MS_POLISH_MAXIT: BFGS iterations per polish
PP_PENALTY_MULT <- 10   # MS_PENALTY_MULT: an infeasible step scores 10 x |start| worse
PP_PENALTY_FLOOR <- 1e6 # a floor for that penalty (log-units)
PP_COMMIT   <- ccx_git_stamp()
stopifnot(grepl("^[A-Za-z_]+=[-0-9.eE+]+$", PP_HOLD_STR), nzchar(PP_START), nzchar(PP_TAG))
PP_HOLD <- stats::setNames(as.numeric(sub(".*=", "", PP_HOLD_STR)), sub("=.*", "", PP_HOLD_STR))
dir.create(PP_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
PP_STEM <- file.path(PP_OUT_DIR, sprintf("profile_%s_%s", names(PP_HOLD), PP_TAG))
PP_CKPT <- paste0(PP_STEM, "_ckpt.rds")
cpu_min <- function() { t <- proc.time(); (t[["user.self"]] + t[["sys.self"]]) / 60 }
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s: hold %s = %g, start %s, tag %s ===\n", PP_DRIVER, PP_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
    names(PP_HOLD), PP_HOLD, PP_START, PP_TAG)

# ---- phase 1: the CANONICAL objective, gated, and its likelihood (the profile's reference) ----
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
PINS0 <- ccx_mode_pins(md)
if (!names(PP_HOLD) %in% md$param_names) stop(names(PP_HOLD), " is not a fitted name of ", CCX_MODE_CANONICAL)
r0 <- ccx_apply_pins(PINS0)
ccx_require_param_set(md, PP_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
SPF <- ccx_spinup_from_label(ccx_mode_spinup(md))
bp0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp0$pump_mode <- md$pump_mode
lp_can <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = SPF)
u_can <- ccx_par_to_unc(md$par_mode)
v_can <- lp_can(u_can)
say("GATE: the canonical's logpost %.6f vs stored %.6f (diff %.2e, tol %g) -> %s; its likelihood %.6f\n", as.numeric(v_can),
    md$logpost, as.numeric(v_can) - md$logpost, CCX_REPRO_TOL,
    if (abs(as.numeric(v_can) - md$logpost) <= CCX_REPRO_TOL) "PASS" else "FAIL", attr(v_can, "loglik"))
if (!(abs(as.numeric(v_can) - md$logpost) <= CCX_REPRO_TOL)) stop("the canonical objective does not reproduce its mode")
CAN <- list(logpost = as.numeric(v_can), loglik = as.numeric(attr(v_can, "loglik")),
            logprior = as.numeric(attr(v_can, "logprior")), streams = unlist(attr(v_can, "streams")),
            par = md$par_mode)
ccx_unpin_params(r0)

# ---- phase 2: the SAME objective with the held name added to the pins ------
PINS <- c(stats::setNames(as.numeric(PINS0), names(PINS0)), PP_HOLD)
invisible(ccx_apply_pins(PINS))
stopifnot(!names(PP_HOLD) %in% CCX_PARAM_NAMES, length(CCX_PARAM_NAMES) == length(md$param_names) - 1L)
bp <- bp0; bp[[names(PP_HOLD)]] <- PP_HOLD[[1]]
lp  <- ccx_make_logpost(base_params = bp, spinup_fn = SPF)
lpS <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF)
lp_eval <- function(u) { v <- tryCatch(as.numeric(lp(u)), error = function(e) -Inf); if (is.finite(v)) v else -Inf }
say("held: %s = %g (%d pins); %d free names\n", names(PP_HOLD), PP_HOLD, length(PINS), length(CCX_PARAM_NAMES))

# ---- the start --------------------------------------------------------------
p_st <- md$par_mode; from <- stats::setNames(rep(CCX_MODE_CANONICAL, length(CCX_PARAM_NAMES)), CCX_PARAM_NAMES)
if (!identical(PP_START, "canonical")) {
  ms <- readRDS(PP_START)
  take <- intersect(intersect(names(ms$par_mode), CCX_PARAM_NAMES), names(p_st))
  for (n in take) p_st[[n]] <- ms$par_mode[[n]]
  from[take] <- basename(dirname(PP_START))
}
u_st <- ccx_par_to_unc(p_st[CCX_PARAM_NAMES])
if (!all(is.finite(unlist(u_st)))) stop("the start lies outside a band: ", paste(names(u_st)[!is.finite(unlist(u_st))], collapse = ", "))
u_st <- unlist(u_st)[CCX_PARAM_NAMES]
lp_st <- lp_eval(u_st)
say("start: %d names from %s, %d from %s; logpost %.4f\n", sum(from != CCX_MODE_CANONICAL), basename(dirname(PP_START)),
    sum(from == CCX_MODE_CANONICAL), CCX_MODE_CANONICAL, lp_st)
if (!is.finite(lp_st)) stop("the start is not finite under the held objective")
PENALTY <- max(PP_PENALTY_FLOOR, PP_PENALTY_MULT * abs(lp_st))
neg <- function(u) { names(u) <- CCX_PARAM_NAMES; v <- lp_eval(u); if (is.finite(v)) -v else PENALTY }

# ---- the optimisation: cycles of NM restarts then a BFGS polish, resumable ---------
PP_ID <- list(hold = PP_HOLD, start = PP_START, mode_md5 = unname(tools::md5sum(ccx_mode_file())))
S <- if (file.exists(PP_CKPT)) readRDS(PP_CKPT) else
  list(u = u_st, best = -lp_st, cycle = 0L, trace = data.frame(cycle = 0L, step = "start", logpost = lp_st, cpu_min = 0), id = PP_ID)
# a checkpoint continues only the SAME profile (hold, start, mode file); a changed recipe may continue it, a changed
# question may not
if (!identical(S$id, PP_ID)) stop(PP_CKPT, " belongs to another profile (hold / start / mode file differ): move it aside")
if (S$cycle > 0L) say("RESUMED at cycle %d, logpost %.4f\n", S$cycle, -S$best)
cpu0 <- cpu_min() - (if (nrow(S$trace)) max(S$trace$cpu_min) else 0)
used <- function() cpu_min() - cpu0
keep <- function(res, step) {          # re-EVALUATE what optim() returned; keep only an evaluated improvement
  v <- neg(res$par)
  S$trace <<- rbind(S$trace, data.frame(cycle = S$cycle, step = step, logpost = -v, cpu_min = used()))
  if (v < S$best) { S$u <<- stats::setNames(res$par, CCX_PARAM_NAMES); S$best <<- v }
  saveRDS(S, PP_CKPT)
}
converged <- FALSE
while (S$cycle < PP_CYCLES && used() < PP_BUDGET_MIN) {
  S$cycle <- S$cycle + 1L; c_start <- S$best
  for (r in seq_len(PP_RESTARTS)) {
    if (used() >= PP_BUDGET_MIN) break
    r_start <- S$best
    res <- stats::optim(S$u, neg, method = "Nelder-Mead", control = list(maxit = PP_NM_MAXIT, reltol = 1e-12))
    keep(res, sprintf("NM restart %d", r))
    say("  cycle %d NM %d: logpost %.4f (gain %.4f, %d evals, %.1f CPU-min)\n", S$cycle, r, -S$best, r_start - S$best,
        res$counts[["function"]], used())
    if (r_start - S$best < PP_TOL) break
  }
  if (used() < PP_BUDGET_MIN) {
    p_start <- S$best
    res <- stats::optim(S$u, neg, method = "BFGS", control = list(maxit = PP_POLISH_MAXIT, reltol = 1e-12))
    keep(res, "BFGS polish")
    say("  cycle %d BFGS: logpost %.4f (gain %.4f, convergence %d, %.1f CPU-min)\n", S$cycle, -S$best, p_start - S$best,
        res$convergence, used())
  }
  if (c_start - S$best < PP_CYCLE_TOL) { converged <- TRUE; say("cycle %d gained %.4f < %g: CONVERGED\n", S$cycle,
                                                                c_start - S$best, PP_CYCLE_TOL); break }
}
if (!converged) say("STOPPED %s without a converged cycle (%.1f CPU-min)\n",
                    if (S$cycle >= PP_CYCLES) "at the cycle cap" else "at the budget", used())

# ---- the result, read through the by-stream objective ------------------------
v <- lpS(S$u); par <- ccx_unc_to_par(S$u)
RES <- list(logpost = as.numeric(v), loglik = as.numeric(attr(v, "loglik")), logprior = as.numeric(attr(v, "logprior")),
            streams = unlist(attr(v, "streams")), u = S$u, par = par)
say("\nRESULT (%s): logpost %.4f, likelihood %.4f, log-prior %.4f\n", PP_TAG, RES$logpost, RES$loglik, RES$logprior)
say("vs the canonical (%s, %s free): likelihood %+.4f, logpost %+.4f (NOT comparable as a posterior: different held sets; compare on LIKELIHOOD)\n",
    CCX_MODE_CANONICAL, names(PP_HOLD), RES$loglik - CAN$loglik, RES$logpost - CAN$logpost)
u_can_free <- unlist(ccx_par_to_unc(md$par_mode[CCX_PARAM_NAMES]))[CCX_PARAM_NAMES]   # the canonical, in THIS fitted set
sd_can <- sqrt(diag(ccx_mode_fit_stats(md)$cov))[CCX_PARAM_NAMES]
mv <- (S$u[CCX_PARAM_NAMES] - u_can_free) / sd_can
say("largest moves from the canonical (in its Laplace u-sd): %s\n",
    paste(sprintf("%s %+.1f", names(sort(-abs(mv)))[1:8], mv[names(sort(-abs(mv)))[1:8]]), collapse = ", "))
saveRDS(list(result = RES, canonical = CAN, converged = converged, trace = S$trace, start_from = from,
             provenance = list(driver = PP_DRIVER, commit = PP_COMMIT, mode = CCX_MODE_CANONICAL,
                               mode_md5 = unname(tools::md5sum(ccx_mode_file())), hold = PP_HOLD, pins = PINS,
                               start = PP_START, start_md5 = if (file.exists(PP_START)) unname(tools::md5sum(PP_START)) else NA,
                               tag = PP_TAG, budget_cpu_min = PP_BUDGET_MIN, cpu_min = used(),
                               recipe = c(restarts = PP_RESTARTS, cycles = PP_CYCLES, nm_maxit = PP_NM_MAXIT, tol = PP_TOL,
                                          cycle_tol = PP_CYCLE_TOL, polish_maxit = PP_POLISH_MAXIT),
                               rng = "none (Nelder-Mead and BFGS are deterministic)",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(PP_STEM, ".rds"))
say("provenance: %s @%s; %s; hold %s = %g; start %s; no RNG\nwrote %s.rds\n", PP_DRIVER, PP_COMMIT, CCX_MODE_CANONICAL,
    names(PP_HOLD), PP_HOLD, PP_START, PP_STEM)
