# =====================================================================
# diag_npp0_scan_resfree.R -- DOES A DIFFERENT LAND RESIDENCE STRUCTURE MAKE A
# LOWER NPP CHEAP? (NPP_GLOBAL_PI follow-up; handoff 2026-09-29 (b) item 1;
# Marcus 2026-09-29: "NPP0 rescan, residence free", "free, with the existing 11",
# no priors added)
#
# The 09-29 (k) scan (diag_npp0_scan.R) found lowering NPP_GLOBAL_PI x0.75
# (modern NPP 70 -> 55) costs ~-125, 57 % paid by NH bomb D14C. Hypothesis
# (untested there): the UNFITTED land residence times set the land's bomb-14C
# uptake, so a lower NPP may need a different residence structure, not a
# stronger row. This repeats that scan with RS_RES (the four-pool residence
# times + the passive-litter split) freed ALONGSIDE the same 11 names.
#
# DESIGN
#   * Same structure (arm A, hilda_csl3v0ka, v0k basin 1), same scales, same
#     NPP override route (in-process CCX_CONSTANTS, reset after).
#   * WARM START: each scale starts from the 09-29 (k) optimum for that scale
#     (RS_PREV csv) with the residence times at their defaults, so the new
#     optimum can only IMPROVE on the old one, and every gain is attributable
#     to the residence times (plus any extra NM progress on the 11 -- measured
#     by the RS_CTRL arm: the same restart with the residence times FIXED).
#   * Residence times enter as log (taus) / logit (litter_slow_frac). They are
#     base_params, not fitted coordinates, so no prior and no Jacobian; the
#     objective is logpost over the 29 fitted coords with the 5 overridden.
#   * ⚠ UNBOUNDED by ruling: an earlier free tau_soil_fast ran to +3.61 sigma
#     (quarantine 20260812b). Values are reported, not screened.
#   * The override is applied by swapping the closure's base_params
#     (ccx_make_logpost reads it per call; the forcing it pre-builds depends
#     only on enso_index / aod_mode, which are not touched).
# IDENTITY CHECKS (stop on failure):
#   (a) at each scale, the warm start with residence at defaults reproduces the
#       09-29 (k) d_opt-level logpost (|d| < RS_ID_TOL, CSV-precision);
#   (b) REACHED: doubling tau_wood at the scale-1 start changes the logpost.
# ⚠ A SCREEN: Nelder-Mead from a warm start, costs are UPPER BOUNDS. No RNG.
# DECADAL-ONLY MODE (CHANGELOG 09-29 v; Marcus "run all the cheap measurements"):
#   RS_RES_FREE (env, comma-separated) picks the residence names freed, and
#   RS_FIX_PASSIVE=1 holds the PI passive stock at its default (1500 GtC) at
#   EVERY scale by setting litter_slow_frac = default / scale, tau_soil_slow at
#   its default. This asks the (m) question without the passive runaway the
#   inventories reject. Identity (a) is still checked at the unmodified
#   defaults; the optimisation and the control start from the fixed-stock ones.
# q10 PIN (RS_PIN_Q10=<value>; CHANGELOG 09-29 v): the decadal-only run pushed
#   q10 below 1 at x0.75/x0.80 (respiration falling with warming, its seasonal
#   term sign-flipped) -- the shared-q10 escape of memory q10_recovery_is_escape.
#   This pins q10 at <value> for the optimisation and the control (removed from
#   the free names) so the escape is closed. Identity (a) still runs at the
#   unpinned warm start.
# USAGE: Rscript calibration/diag_npp0_scan_resfree.R  (from a FROZEN copy;
#        BLAS threads pinned to 1 by the caller's env; RS_SMOKE=1 for a smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
RS_DRIVER <- "calibration/diag_npp0_scan_resfree.R"
RS_TAG    <- "npp0_scan_resfree"
RS_DATE   <- "20260929"
RS_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
RS_STRUCT <- "hilda_csl3v0ka"
RS_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
RS_SCALES <- c(0.75, 0.80, 0.85, 0.90, 0.95, 1.00, 1.05)
RS_FREE   <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
RS_RES_ALL <- c("tau_leaf", "tau_wood", "tau_soil_fast", "tau_soil_slow", "litter_slow_frac")
RS_RES    <- if (nzchar(Sys.getenv("RS_RES_FREE"))) strsplit(Sys.getenv("RS_RES_FREE"), ",")[[1]] else RS_RES_ALL
stopifnot(all(RS_RES %in% RS_RES_ALL))
RS_FIX_PASSIVE <- identical(Sys.getenv("RS_FIX_PASSIVE"), "1")
stopifnot(!RS_FIX_PASSIVE || !any(c("tau_soil_slow", "litter_slow_frac") %in% RS_RES))
RS_LOGIT  <- "litter_slow_frac"
RS_PIN_Q10 <- as.numeric(Sys.getenv("RS_PIN_Q10", "NA"))
RS_FREE_ALL <- RS_FREE
if (!is.na(RS_PIN_Q10)) RS_FREE <- setdiff(RS_FREE, "q10")
RS_PIN_SEAS <- c("seas_T_amp_NH", "seas_T_amp_SH")   # reset to the scale-1 row when q10 is pinned
RS_MAXIT  <- 6000L
RS_CTRL_MAXIT <- 3000L
RS_ID_TOL <- 1e-4
RS_REACH_FACTOR <- 2
RS_CORES  <- 7L
RS_SMOKE  <- identical(Sys.getenv("RS_SMOKE"), "1")
if (RS_FIX_PASSIVE || !setequal(RS_RES, RS_RES_ALL)) RS_TAG <- paste0(RS_TAG, "_", paste(sub("^tau_", "", RS_RES), collapse = "-"), if (RS_FIX_PASSIVE) "_fixpassive" else "")
if (!is.na(RS_PIN_Q10)) RS_TAG <- paste0(RS_TAG, sprintf("_q10pin%g", RS_PIN_Q10))
if (RS_SMOKE) { RS_TAG <- paste0(RS_TAG, "_smoke"); RS_SCALES <- c(0.75, 1.00); RS_MAXIT <- 20L; RS_CTRL_MAXIT <- 10L }
RS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", RS_TAG, RS_DATE))
COMMIT    <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(RS_MODE)); invisible(ccx_apply_pins(md$pins))
tg <- ccx_npp_modern_target()
iF <- match(RS_FREE, md$param_names); stopifnot(!anyNA(iF))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, RS_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
stopifnot(all(RS_RES_ALL %in% names(bp)))
RES0 <- unlist(bp[RS_RES_ALL])                      # the unmodified defaults (identity a)
fixed_of <- function(s) { r <- RES0; if (RS_FIX_PASSIVE) r[["litter_slow_frac"]] <- RES0[["litter_slow_frac"]] / s; r }
prev <- utils::read.csv(RS_PREV, check.names = FALSE)
stopifnot(all(RS_SCALES %in% prev$scale), all(RS_FREE %in% names(prev)))

res_to_x <- function(v) ifelse(names(v) %in% RS_LOGIT, stats::qlogis(v), log(v))
x_to_res <- function(x) setNames(ifelse(RS_RES %in% RS_LOGIT, stats::plogis(x), exp(x)), RS_RES)
full_res <- function(s, x) { r <- fixed_of(s); r[RS_RES] <- x_to_res(x); r }
u_from_prev <- function(s) {
  r <- prev[prev$scale == s, ]; p <- as.list(ccx_unc_to_par(md$u_mode))
  for (n in RS_FREE_ALL) p[[n]] <- r[[n]]
  ccx_par_to_unc(unlist(p)[md$param_names])
}
CONST0 <- CCX_CONSTANTS
set_npp <- function(s) { cc <- CONST0; cc$NPP_GLOBAL_PI$value <- CONST0$NPP_GLOBAL_PI$value * s
  assign("CCX_CONSTANTS", cc, envir = globalenv()) }
bp_with <- function(res) { b <- bp; for (n in names(res)) b[[n]] <- res[[n]]; b }
npp_modern <- function(u, b) {
  pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(b, pv)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  n <- ccx_run_fast(sp, F)$npp; k <- floor(n$t) >= tg$win[1] & floor(n$t) <= tg$win[2]
  mean(n$npp_NH[k] + n$npp_SH[k])
}
one <- function(s) {
  set_npp(s)
  stopifnot(isTRUE(all.equal(ccx_const("NPP_GLOBAL_PI"), CONST0$NPP_GLOBAL_PI$value * s)))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE); E <- environment(lp)
  lp_at <- function(u, res) { E$base_params <- bp_with(res); on.exit(E$base_params <- bp); lp(u) }
  u0 <- u_from_prev(s)
  l_start <- lp_at(u0, RES0)                        # identity (a): unmodified defaults
  if (!is.na(RS_PIN_Q10)) { pp <- as.list(ccx_unc_to_par(u0)); pp$q10 <- RS_PIN_Q10
    # the (k) seasonal amplitudes were set for that scale's q10 (< 1 at x0.75): start from scale 1's, set for q10 1.10
    r1 <- prev[prev$scale == 1, ]; for (n in RS_PIN_SEAS) pp[[n]] <- r1[[n]]
    u0 <- ccx_par_to_unc(unlist(pp)[md$param_names]) }
  RSs <- fixed_of(s); l_base <- lp_at(u0, RSs)      # the fixed-passive baseline (== l_start unless RS_FIX_PASSIVE)
  reach <- if (s == 1) as.numeric(lp_at(u0, replace(RES0, "tau_wood", RES0[["tau_wood"]] * RS_REACH_FACTOR))) - as.numeric(l_start) else NA_real_
  nF <- length(iF)
  f <- function(x) { u <- u0; u[iF] <- x[seq_len(nF)]; v <- lp_at(u, full_res(s, x[-seq_len(nF)]))
    if (!is.finite(v)) 1e12 else -as.numeric(v) }
  x0 <- c(u0[iF], res_to_x(RSs[RS_RES]))
  o <- stats::optim(x0, f, method = "Nelder-Mead", control = list(maxit = RS_MAXIT))
  u <- u0; u[iF] <- o$par[seq_len(nF)]; rz <- full_res(s, o$par[-seq_len(nF)])
  l1 <- lp_at(u, rz)
  # CONTROL: same restart, residence FIXED -- extra NM progress on the 11 alone
  g <- function(x) { uu <- u0; uu[iF] <- x; v <- lp_at(uu, RSs); if (!is.finite(v)) 1e12 else -as.numeric(v) }
  oc <- stats::optim(u0[iF], g, method = "Nelder-Mead", control = list(maxit = RS_CTRL_MAXIT))
  list(scale = s, start = as.numeric(l_start), base = as.numeric(l_base), opt = as.numeric(l1), ctrl = -oc$value,
       loglik = as.numeric(attr(l1, "loglik")), streams = attr(l1, "streams"), streams0 = attr(l_start, "streams"),
       npp = npp_modern(u, bp_with(rz)), npp_start = npp_modern(u0, bp), npp_base = npp_modern(u0, bp_with(RSs)), reach = reach,
       par = unlist(ccx_unc_to_par(u)[RS_FREE_ALL]), res = rz,
       evals = o$counts[["function"]], conv = o$convergence, ctrl_conv = oc$convergence)
}
res <- parallel::mclapply(RS_SCALES, one, mc.cores = RS_CORES, mc.preschedule = FALSE)
set_npp(1)
ok <- !vapply(res, inherits, logical(1), "try-error"); if (!all(ok)) { print(res[!ok]); stop("fork failure") }
ref <- res[[which(RS_SCALES == 1)]]
# (a) the warm starts must reproduce the 09-29 (k) d_opt profile (relative to scale 1)
d_start <- sapply(res, `[[`, "start") - ref$start
d_prev  <- prev$d_opt[match(RS_SCALES, prev$scale)]
stopifnot(max(abs(d_start - d_prev)) < RS_ID_TOL)
# (b) the residence override is REACHED
stopifnot(is.finite(ref$reach), abs(ref$reach) > 0)

sink(paste0(RS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", RS_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  structure %s at v0k basin 1; warm start = %s optimum per scale\n", RS_STRUCT, basename(RS_PREV)))
cat(sprintf("  free {%s} + residence {%s} (log / logit[%s], UNBOUNDED, no prior); NM maxit %d; control (residence fixed) maxit %d\n",
  paste(RS_FREE, collapse = ", "), paste(RS_RES, collapse = ", "), RS_LOGIT, RS_MAXIT, RS_CTRL_MAXIT))
cat(sprintf("  NPP_GLOBAL_PI x {%s}; logpost natural-log units; NPP GtC/yr mean %d-%d; no RNG\n",
  paste(RS_SCALES, collapse = ", "), tg$win[1], tg$win[2]))
cat(sprintf("  [identity a] warm-start profile vs 09-29 (k) d_opt: max |diff| %.2e (tol %.0e)\n", max(abs(d_start - d_prev)), RS_ID_TOL))
cat(sprintf("  [identity b] tau_wood x%g at scale-1 start moves logpost %+.3f (REACHED)\n\n", RS_REACH_FACTOR, ref$reach))
cat("  Costs relative to scale 1.00's OWN arm. d_old = 09-29 (k) (11 free); d_ctrl = restart, residence fixed; d_new = residence free.\n")
cat(sprintf("  %-6s %9s %9s %9s %8s %8s %5s %6s | %s\n", "scale", "d_old", "d_ctrl", "d_new", "NPPold", "NPPnew", "conv", "evals",
  paste(sprintf("%10s", RS_RES_ALL), collapse = "")))
for (r in res) cat(sprintf("  %-6.2f %+9.2f %+9.2f %+9.2f %8.2f %8.2f %5d %6d | %s\n", r$scale, r$start - ref$start, r$ctrl - ref$ctrl,
  r$opt - ref$opt, r$npp_start, r$npp, r$conv, r$evals, paste(sprintf("%10.4g", r$res), collapse = "")))
cat(sprintf("  defaults %s\n", paste(sprintf("%s=%g", RS_RES_ALL, RES0), collapse = ", ")))
cat("\n  within-scale gain from freeing residence (opt - base) and from NM restart alone (ctrl - base); base = fixed-passive start:\n")
for (r in res) cat(sprintf("  %-6.2f  base-start %+8.2f  resfree %+8.2f   ctrl %+8.2f   NPP base %6.2f\n", r$scale, r$base - r$start, r$opt - r$base, r$ctrl - r$base, r$npp_base))
S <- do.call(rbind, lapply(res, function(r) r$streams - ref$streams)); rownames(S) <- sprintf("x%.2f", RS_SCALES)
big <- names(sort(apply(abs(S), 2, max), decreasing = TRUE))[1:min(10, ncol(S))]
cat("\n=== WHO PAYS (residence free): stream change vs scale 1.00 (10 largest |max|) ===\n"); print(round(S[, big, drop = FALSE], 2))
cat("\n=== 11 fitted names at the residence-free optimum ===\n")
print(signif(do.call(rbind, lapply(res, `[[`, "par")), 4))
R <- data.frame(scale = RS_SCALES, d_old = d_start, d_ctrl = sapply(res, `[[`, "ctrl") - ref$ctrl,
                d_new = sapply(res, `[[`, "opt") - ref$opt, npp_old = sapply(res, `[[`, "npp_start"),
                npp_new = sapply(res, `[[`, "npp"), conv = sapply(res, `[[`, "conv"),
                ctrl_conv = sapply(res, `[[`, "ctrl_conv"), do.call(rbind, lapply(res, `[[`, "res")),
                do.call(rbind, lapply(res, `[[`, "par")), S, check.names = FALSE,
                d_base = sapply(res, `[[`, "base") - ref$base, npp_base = sapply(res, `[[`, "npp_base"),
                provenance = sprintf("%s @%s; %s at v0k basin1; warm start %s; free res {%s}; fix_passive %s; NM %d; no RNG", RS_DRIVER, COMMIT, RS_STRUCT, basename(RS_PREV), paste(RS_RES, collapse = ","), RS_FIX_PASSIVE, RS_MAXIT))
utils::write.csv(R, paste0(RS_OUT, ".csv"), row.names = FALSE); saveRDS(res, paste0(RS_OUT, ".rds"))
cat(sprintf("  saved %s.{log,csv,rds}\n", RS_OUT)); sink()
