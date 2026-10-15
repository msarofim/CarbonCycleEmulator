#!/usr/bin/env Rscript
# =====================================================================
# diag_obj18_dead13.R -- WAS #18's id 13 DEAD, or did a reproduce-gate fire inside the objective's noise floor?
# (CHANGELOG 2026-10-08 a). The driver's DEAD-TASK gate stopped id 13 (rc 1) with "the reported optimum -1249.1962 is
# not a finite point of the objective (lp_fun there = -1249.19620655218)": a FINITE value, so the gate fired on its
# OTHER branch, |re-evaluation - stored best| = 3.09e-5 > MS_EVAL_TOL 1e-8 x |best| = 1.25e-5, and the message names
# the wrong branch. Three converged ids also re-evaluate below their stored best (10: -5.1e-6; 9: -5.4e-7; 21:
# -6.6e-7), every one DOWN, while memory objective_noise_floor_optimum_on_spike records #17's end-of-run check as
# reproducing every start EXACTLY. Two readings, and the tests that separate them:
#   1. DETERMINISM, FRESH PROCESS: the objective at each stored u_mode, twice, against the stored best AND the
#      driver's own end-of-run re-evaluation (final_lp_check). Fresh == final_lp_check and twice-equal: the objective
#      is a function of u, and the stored best is not f(stored u) -- the best came from a point other than the u kept.
#      Fresh != final_lp_check: the value depends on the PROCESS's history, not on u alone.
#   2. THE LOCAL FLOOR at id 13 and at the top basin: 1e-12 single-name nudges of u_mode (the 10-07 a probe). A floor
#      of the gap's size there says the gate is tighter than the objective it checks, at that point.
#   3. THE MECHANISM (the hypothesis: optim() hands back a `par` that is not, bit for bit, the point whose `value` it
#      returns -- vmmin's "no change" test is `10 + X[i] == 10 + b[i]`). Short BFGS and Nelder-Mead runs from id 10's
#      u_mode with the driver's controls (maxit shortened to DD_MECH_MAXIT), recording EVERY evaluated point: is the
#      returned par among them, and is the returned value f(returned par)?
#   4. HISTORY: the objective at id 10's u_mode cold, then after evaluating OTHER points first (id 13's u_mode, a
#      nudged neighbor, id 0's u_mode). Unequal values = the objective carries state from one call to the next.
# Usage: Rscript calibration/diag_obj18_dead13.R
# OUTPUTS: outputs/diagnostics/obj18_dead13_<date>.{log,rds}. No RNG is used.
# ⛔ ADOPTS NOTHING, and changes no gate.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
DD_DRIVER   <- "calibration/diag_obj18_dead13.R"
DD_WAVE     <- file.path("calibration", "output", "multistart_20261007i_hilda_csl3v0kaidgbemwt_seasml1_pin_obj18_sd1.0452")
DD_IDS      <- c(13L, 10L, 9L, 21L, 0L)        # the dead id; the three converged ids with a non-zero gap; a zero-gap control
DD_NUDGE_IDS <- c(13L, 0L)                     # the dead id; the top basin's LP start
DD_REL      <- 1e-12                           # the 10-07 a nudge: u_i -> u_i (1 + DD_REL) + DD_ABS
DD_ABS      <- 1e-14
DD_NAMES    <- c("tau_ex", "hs_asx_frac", "h_hs", "kz", "u_hs", "h_ml", "beta_max", "q10")
DD_EVAL_TOL <- 1e-8                            # the driver's MS_EVAL_TOL (relative), the DEAD gate's bound
DD_MECH_ID  <- 10L                             # section 3's start: converged, gap -5.1e-6, ~0.37 CPU-s/eval
DD_MECH_RUNS <- list(BFGS = list(maxit = 3L, reltol = 1e-14),           # the driver's polish control, maxit shortened
                     `Nelder-Mead` = list(maxit = 300L, reltol = 1e-12)) # the driver's restart control, maxit shortened
DD_OUT <- file.path("outputs", "diagnostics", sprintf("obj18_dead13_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(DD_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | no RNG\n  wave %s\n", DD_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), DD_WAVE))
S <- lapply(DD_IDS, function(i) readRDS(file.path(DD_WAVE, sprintf("start_%03d.rds", i)))); names(S) <- DD_IDS
for (k in names(S)) cat(sprintf("  id %2s: md5 %s, stored logpost %.9f, final_lp_check %.9f, dead %s, out_of_time %s\n", k,
                                unname(tools::md5sum(file.path(DD_WAVE, sprintf("start_%03d.rds", as.integer(k))))),
                                S[[k]]$logpost, S[[k]]$final_lp_check, isTRUE(S[[k]]$dead), isTRUE(S[[k]]$out_of_time)))
# THE OBJECTIVE, built as promote_multistart_mode.R builds it (the starts' gate, pins, structure, seas_ml, pump field)
s0 <- S[[1]]
stopifnot(all(vapply(S, function(s) identical(s$struct, s0$struct) && identical(s$pins, s0$pins), TRUE)))
invisible(ccx_apply_gate(s0$struct)); invisible(ccx_apply_pins(s0$pins))
stopifnot(identical(s0$param_names, CCX_PARAM_NAMES))
bp <- ccx_apply_structure(ccx_default_params(), s0$struct, seas_ml = ccx_parse_seas_ml(s0$seas_ml),
                          pump_field = ccx_parse_pump_field(s0$pump_field))
for (n in names(s0$pins)) bp[[n]] <- s0$pins[[n]]
attr(bp, "pins") <- s0$pins; bp$pump_mode <- s0$pump_mode
lpf <- ccx_make_logpost(base_params = bp)

cat("\n=== 1. DETERMINISM, FRESH PROCESS: the objective at each stored u_mode, twice ===\n")
cat("  id | fresh - stored best | fresh - driver's final_lp_check | twice | the DEAD gate's bound\n")
R1 <- lapply(S, function(s) {
  a <- lpf(s$u_mode); a2 <- lpf(s$u_mode)
  c(fresh = a, vs_best = a - s$logpost, vs_final = a - s$final_lp_check, twice = a2 - a,
    bound = DD_EVAL_TOL * max(1, abs(s$logpost)))
})
for (k in names(R1)) cat(sprintf("  %2s | %+.3e | %+.3e | %+.1e | %.2e\n", k, R1[[k]][["vs_best"]], R1[[k]][["vs_final"]],
                                 R1[[k]][["twice"]], R1[[k]][["bound"]]))

cat(sprintf("\n=== 2. THE LOCAL FLOOR: %g single-name nudges of u_mode (%s) ===\n", DD_REL, paste(DD_NAMES, collapse = ", ")))
nudge <- function(u, n) { u[[n]] <- u[[n]] * (1 + DD_REL) + DD_ABS; u }
R2 <- lapply(as.character(DD_NUDGE_IDS), function(k) {
  u0 <- S[[k]]$u_mode; b <- lpf(u0)
  d <- vapply(DD_NAMES, function(n) lpf(nudge(u0, n)) - b, 0)
  cat(sprintf("  id %2s base %.9f | d: %s | %d+ / %d- / %d zero | max |d| %.1e\n", k, b,
              paste(sprintf("%+.1e", d), collapse = " "), sum(d > 0), sum(d < 0), sum(d == 0), max(abs(d))))
  list(base = b, d = d)
}); names(R2) <- DD_NUDGE_IDS
cat(sprintf("\n=== 3. THE MECHANISM: optim() from id %d's u_mode, every evaluated point recorded ===\n", DD_MECH_ID))
R3 <- lapply(names(DD_MECH_RUNS), function(meth) {
  E <- new.env(); E$u <- list(); E$v <- numeric(0)
  fn <- function(u) { v <- lpf(u); val <- if (is.finite(v)) -v else 1e10; E$u[[length(E$u) + 1L]] <- u; E$v <- c(E$v, val); val }
  o <- stats::optim(S[[as.character(DD_MECH_ID)]]$u_mode, fn, method = meth, control = DD_MECH_RUNS[[meth]])
  hit <- which(vapply(E$u, function(x) identical(unname(x), unname(o$par)), TRUE))
  fpar <- lpf(o$par); kbest <- which.min(E$v)
  dmin <- min(vapply(E$u, function(x) max(abs(unname(x) - unname(o$par))), 0))
  cat(sprintf("  %-11s %d evals | returned par EVALUATED bit for bit: %s | f(par) - (-value) %+.3e | value == min evaluated: %s | nearest evaluated point max|du| %.1e\n",
              meth, length(E$v), if (length(hit)) sprintf("yes (eval %s)", paste(hit, collapse = ",")) else "NO",
              fpar - (-o$value), isTRUE(o$value == E$v[kbest]), dmin))
  list(method = meth, control = DD_MECH_RUNS[[meth]], n_eval = length(E$v), par_evaluated = length(hit) > 0,
       gap = fpar - (-o$value), value_is_min = isTRUE(o$value == E$v[kbest]), nearest_du = dmin)
}); names(R3) <- names(DD_MECH_RUNS)
cat(sprintf("\n=== 4. HISTORY: the objective at id %d's u_mode after evaluating other points first ===\n", DD_MECH_ID))
uM <- S[[as.character(DD_MECH_ID)]]$u_mode
pre <- list(cold = NULL, after_id13 = S[["13"]]$u_mode, after_nudge = nudge(uM, "h_ml"), after_id0 = S[["0"]]$u_mode)
R4 <- vapply(names(pre), function(k) { if (!is.null(pre[[k]])) lpf(pre[[k]]); lpf(uM) }, 0)
for (k in names(R4)) cat(sprintf("  %-12s %.12f  (vs cold %+.3e)\n", k, R4[[k]], R4[[k]] - R4[["cold"]]))
saveRDS(list(driver = DD_DRIVER, commit = COMMIT, wave = DD_WAVE, ids = DD_IDS, rel = DD_REL, abs = DD_ABS,
             names = DD_NAMES, eval_tol = DD_EVAL_TOL, determinism = R1, floor = R2, mechanism = R3, history = R4),
        paste0(DD_OUT, ".rds"))
cat(sprintf("\n  written %s.{log,rds}\n", DD_OUT))
sink()
