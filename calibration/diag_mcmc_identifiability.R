#!/usr/bin/env Rscript
# =====================================================================
# diag_mcmc_identifiability.R -- the hilda31w MCMC read's two owed checks (handoff 2026-10-13b §4 step 2), on the
# pooled draws read_mcmc_check.R writes:
#   (1) IDENTIFIABILITY of the WTC label's two new names against their Laplace partners: bomb_share_NH vs tau_ex and
#       bomb_total (Laplace r -0.31 / -0.06 at id 17), seas_T_lag vs seas_lag_p_NH (Laplace r +0.955; seas_T_lag sat
#       within 1 sd of its 0 floor). Posterior sd against the Laplace sd (u-space, as read_mcmc_check.R reports
#       it), posterior vs Laplace correlations, and where the mass sits against each name's own band.
#   (2) h_ml AGAINST THE P8 WALL. The mode (69.5 m) sits ~6 m under the depth past which the model refuses (75.48 m,
#       CHANGELOG 10-13 j). The wall is MEASURED here, by bisection on the objective's finiteness along h_ml with every
#       other name at the mode -- so it is the wall AT THE MODE: P8 judges the deeper hemisphere's layer, which other
#       names move, so a draw's own wall can differ. Then the share of draws past it and within each of H_NEAR_M
#       below it, and of the 42.5 m floor.
#       ⚠ MEASURED 2026-10-13 (CHANGELOG 10-13 p): the objective's wall at the mode is NOT P8. At kz 13790 the
#       spin-up's stability bound needs 249 substeps at 75.02 m and 270.5 at 75.03 m, past CCX_SUBSTEPS_MAX (256), so
#       the SUBSTEP CAP refuses first; P8 itself fires a little higher. Both are reported, each with its own message.
# IT REPORTS; IT DOES NOT RULE. The cut-offs below are descriptive bins, not thresholds; whether either name is
# identified, and what the wall means for the band, are Marcus's calls.
# The objective is run_mcmc_check.R's own harness (gate, pins, bands, spin-up), GATED to reproduce the stored logpost.
# Usage: Rscript calibration/diag_mcmc_identifiability.R --draws=<pooled_u.rds> [--out-dir=outputs/diagnostics]
# No RNG.
# =====================================================================
ID_ARGS <- commandArgs(trailingOnly = TRUE)
id_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), ID_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants: every label and filename derives from these --------
ID_DRIVER   <- "calibration/diag_mcmc_identifiability.R"
ID_DRAWS    <- id_arg("draws", "")
ID_OUT_DIR  <- id_arg("out-dir", file.path("outputs", "diagnostics"))
ID_FOCUS    <- list(bomb_share_NH = c("tau_ex", "bomb_total"), seas_T_lag = c("seas_lag_p_NH"))
ID_WALL_NAME <- "h_ml"
ID_WALL_TOL  <- 0.01        # m: the bisection's bracket width when it stops
H_NEAR_M     <- c(1, 2, 5)  # m: descriptive bins below the wall and above the floor, not thresholds
ID_EDGE_FRAC <- c(0.01, 0.05)  # descriptive bins: the share of draws in the outer 1 % / 5 % of a name's band
ID_PROBS     <- c(0.025, 0.5, 0.975)
ID_COMMIT    <- ccx_git_stamp()
if (!nzchar(ID_DRAWS) || !file.exists(ID_DRAWS)) stop("--draws=<pooled_u.rds from read_mcmc_check.R> is required")
dir.create(ID_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
ID_STEM <- file.path(ID_OUT_DIR, sprintf("mcmc_identifiability_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
sink(paste0(ID_STEM, ".log"), split = TRUE)
cat(sprintf("=== %s @%s, %s ===\n", ID_DRIVER, ID_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))

# ---- the space: run_mcmc_check.R's harness, exactly -------------------------
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
invisible(ccx_apply_pins(ccx_mode_pins(md)))
ccx_require_param_set(md, ID_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
u0  <- ccx_par_to_unc(md$par_mode)
Sig <- ccx_mode_fit_stats(md)$cov
bp  <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
# the spin-up is wrapped only to RECORD why a point is refused (lp_eval below swallows the error); the value is untouched
ID_SPIN0 <- ccx_spinup_from_label(ccx_mode_spinup(md)); ID_LAST_REFUSAL <- NA_character_
id_spin <- function(p) tryCatch(ID_SPIN0(p), error = function(e) { ID_LAST_REFUSAL <<- conditionMessage(e); stop(e) })
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = id_spin)
lp_eval <- function(u) { v <- tryCatch(as.numeric(lpf(u)), error = function(e) -Inf); if (is.finite(v)) v else -Inf }
spec <- function(n) if (!is.null(CCX_PARAM_TABLE[[n]])) CCX_PARAM_TABLE[[n]] else CCX_PARAM_GATED_ALL[[n]]

U <- readRDS(ID_DRAWS); up <- attr(U, "provenance")
stopifnot(identical(colnames(U), md$param_names), all(is.finite(U)))
cat(sprintf("mode %s (md5 %s); draws %s (md5 %s): %d x %d, from %s @%s, window (%s], per chain %s\n",
            CCX_MODE_CANONICAL, unname(tools::md5sum(ccx_mode_file())), ID_DRAWS, unname(tools::md5sum(ID_DRAWS)),
            nrow(U), ncol(U), up$reader %||% "?", up$reader_commit %||% "?",
            paste(up$window %||% NA, collapse = ", "), up$per_chain %||% "?"))
if (!identical(up$mode, CCX_MODE_CANONICAL)) stop("the draws are of ", up$mode, ", not the canonical ", CCX_MODE_CANONICAL)

# GATE: the harness reproduces the stored logpost (the reproduce tolerance every such gate reads)
lp0 <- lp_eval(u0)
cat(sprintf("GATE: recomputed logpost %.6f vs stored %.6f (diff %.2e, tol %g) -> %s\n", lp0, md$logpost,
            lp0 - md$logpost, CCX_REPRO_TOL, if (abs(lp0 - md$logpost) <= CCX_REPRO_TOL) "PASS" else "FAIL"))
if (!(abs(lp0 - md$logpost) <= CCX_REPRO_TOL)) stop("the objective does not reproduce the mode")

# the draws on the parameter scale, decoded through the same transforms the sampler used
P <- do.call(rbind, lapply(seq_len(nrow(U)), function(i) unlist(ccx_unc_to_par(U[i, ]))))
Lcor <- stats::cov2cor(Sig)

# ---- (1) identifiability of the two new names ------------------------------
cat("\n=== (1) THE WTC LABEL'S TWO NEW NAMES ===\n")
out_focus <- list()
for (n in names(ID_FOCUS)) {
  s <- spec(n); x <- P[, n]; q <- stats::quantile(x, ID_PROBS, names = FALSE)
  w <- s$hi - s$lo
  edge <- vapply(ID_EDGE_FRAC, function(e) c(lo = mean(x < s$lo + e * w), hi = mean(x > s$hi - e * w)), numeric(2))
  sdr <- stats::sd(U[, n]) / sqrt(Sig[n, n])
  cat(sprintf("%-14s band [%g, %g] (%s); mode %.4f; posterior mean %.4f sd %.4f, %g/%g/%g %% %.4f / %.4f / %.4f\n",
              n, s$lo, s$hi, s$tr, md$par_mode[[n]], mean(x), stats::sd(x), 100 * ID_PROBS[1], 100 * ID_PROBS[2],
              100 * ID_PROBS[3], q[1], q[2], q[3]))
  cat(sprintf("               u-space posterior sd / Laplace sd %.3f; share in the band's outer %s: low %s, high %s\n",
              sdr, paste0(100 * ID_EDGE_FRAC, "%", collapse = " / "),
              paste(sprintf("%.3f", edge["lo", ]), collapse = " / "), paste(sprintf("%.3f", edge["hi", ]), collapse = " / ")))
  pr <- do.call(rbind, lapply(ID_FOCUS[[n]], function(m) data.frame(name = n, partner = m,
    laplace_r = Lcor[n, m], posterior_r_u = stats::cor(U[, n], U[, m]), posterior_r_par = stats::cor(x, P[, m]))))
  for (i in seq_len(nrow(pr)))
    cat(sprintf("               vs %-14s r: Laplace %+.3f, posterior %+.3f (u) / %+.3f (parameter scale)\n",
                pr$partner[i], pr$laplace_r[i], pr$posterior_r_u[i], pr$posterior_r_par[i]))
  out_focus[[n]] <- list(band = c(lo = s$lo, hi = s$hi), tr = s$tr, mode = md$par_mode[[n]], mean = mean(x),
                         sd = stats::sd(x), q = setNames(q, ID_PROBS), sd_over_laplace_u = sdr, edge = edge, partners = pr)
}

# ---- (2) h_ml against the P8 wall -------------------------------------------
cat(sprintf("\n=== (2) %s AGAINST THE P8 WALL (measured at the mode, every other name held) ===\n", ID_WALL_NAME))
sw <- spec(ID_WALL_NAME)
at_h <- function(h) { p <- md$par_mode; p[[ID_WALL_NAME]] <- h; lp_eval(ccx_par_to_unc(p)) }
lo_h <- md$par_mode[[ID_WALL_NAME]]; hi_h <- sw$hi - 1e-6; n_ev <- 0L
if (!is.finite(at_h(lo_h))) stop("the mode itself is not finite along ", ID_WALL_NAME)
if (is.finite(at_h(hi_h))) {
  wall <- NA_real_; cat(sprintf("no wall below the band's top (%g m): the objective is finite all the way\n", sw$hi))
} else {
  while (hi_h - lo_h > ID_WALL_TOL) { mid <- (lo_h + hi_h) / 2; n_ev <- n_ev + 1L
    if (is.finite(at_h(mid))) lo_h <- mid else hi_h <- mid }
  wall <- (lo_h + hi_h) / 2
  ID_LAST_REFUSAL <- NA_character_; invisible(at_h(hi_h)); why_wall <- ID_LAST_REFUSAL
  cat(sprintf("the OBJECTIVE's wall at the mode: %.2f m (finite at %.3f, refused at %.3f; %d bisection evaluations)\n",
              wall, lo_h, hi_h, n_ev))
  cat(sprintf("  refused by: %s\n", if (is.na(why_wall)) "<no spin-up error: a later -Inf exit>" else substr(why_wall, 1, 160)))
}
# P8 ALONE: the geometry guard on the label's own grid (the full parameter list, base + fitted), every other name at
# the mode. The objective can refuse BELOW it (the substep cap); this says where the geometry itself stops.
p8_ok <- function(h) { pf <- bp; for (n in intersect(names(pf), names(md$par_mode))) pf[[n]] <- md$par_mode[[n]]
  pf[[ID_WALL_NAME]] <- h; isTRUE(tryCatch({ ccx_seas_ml_guard(ccx_grid_of(pf)); TRUE }, error = function(e) FALSE)) }
p8_lo <- md$par_mode[[ID_WALL_NAME]]; p8_hi <- sw$hi - 1e-6
p8 <- if (p8_ok(p8_hi)) NA_real_ else { while (p8_hi - p8_lo > ID_WALL_TOL) { mid <- (p8_lo + p8_hi) / 2
  if (p8_ok(mid)) p8_lo <- mid else p8_hi <- mid }; (p8_lo + p8_hi) / 2 }
pf0 <- bp; for (n in intersect(names(pf0), names(md$par_mode))) pf0[[n]] <- md$par_mode[[n]]
cat(sprintf("P8 alone (ccx_seas_ml_guard on the label's grid, depth %.1f m): %s\n", sum(ccx_grid_of(pf0)$dz),
            if (is.na(p8)) "never fires below the band's top" else sprintf("%.2f m", p8)))
h <- P[, ID_WALL_NAME]; qh <- stats::quantile(h, c(ID_PROBS, 0.99, 1), names = FALSE)
cat(sprintf("posterior %s: mode %.2f; mean %.2f sd %.2f; %g/%g/%g %% %.2f / %.2f / %.2f; 99 %% %.2f; max %.2f m\n",
            ID_WALL_NAME, md$par_mode[[ID_WALL_NAME]], mean(h), stats::sd(h), 100 * ID_PROBS[1], 100 * ID_PROBS[2],
            100 * ID_PROBS[3], qh[1], qh[2], qh[3], qh[4], qh[5]))
past_wall  <- if (is.na(wall)) NA_real_ else mean(h > wall)
near_wall  <- if (is.na(wall)) setNames(rep(NA_real_, length(H_NEAR_M)), H_NEAR_M) else
  setNames(vapply(H_NEAR_M, function(m) mean(h > wall - m & h <= wall), 0), H_NEAR_M)
near_floor <- setNames(vapply(H_NEAR_M, function(m) mean(h < sw$lo + m), 0), H_NEAR_M)
cat(sprintf("share of draws PAST the wall-at-mode (an MCMC draw there is finite, so its own wall is higher): %.3f\n", past_wall))
cat(sprintf("share of draws within %s m BELOW the wall-at-mode: %s\n", paste(H_NEAR_M, collapse = " / "),
            paste(sprintf("%.3f", near_wall), collapse = " / ")))
cat(sprintf("share of draws within %s m ABOVE the %.1f m floor: %s\n", paste(H_NEAR_M, collapse = " / "), sw$lo,
            paste(sprintf("%.3f", near_floor), collapse = " / ")))
cat(sprintf("u-space posterior sd / Laplace sd for %s: %.3f\n", ID_WALL_NAME, stats::sd(U[, ID_WALL_NAME]) / sqrt(Sig[ID_WALL_NAME, ID_WALL_NAME])))

saveRDS(list(focus = out_focus,
             wall = list(name = ID_WALL_NAME, wall_at_mode = wall, refused_by = if (exists("why_wall")) why_wall else NA,
                         p8_at_mode = p8, past_wall = past_wall, bisection_tol = ID_WALL_TOL, n_eval = n_ev,
                         q = setNames(qh, c(ID_PROBS, 0.99, 1)), near_wall = near_wall, near_floor = near_floor,
                         floor = sw$lo),
             provenance = list(driver = ID_DRIVER, commit = ID_COMMIT, mode = CCX_MODE_CANONICAL,
                               mode_md5 = unname(tools::md5sum(ccx_mode_file())), draws = ID_DRAWS,
                               draws_md5 = unname(tools::md5sum(ID_DRAWS)), draws_provenance = up,
                               n_draws = nrow(U), bins_m = H_NEAR_M, edge_frac = ID_EDGE_FRAC, rng = "none",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(ID_STEM, ".rds"))
cat(sprintf("\nprovenance: %s @%s; mode %s; draws %s (%d); no RNG\nwrote %s.{log,rds}\n", ID_DRIVER, ID_COMMIT,
            CCX_MODE_CANONICAL, basename(ID_DRAWS), nrow(U), ID_STEM))
sink()
