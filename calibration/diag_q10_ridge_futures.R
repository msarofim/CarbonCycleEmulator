# =====================================================================
# diag_q10_ridge_futures.R -- is q10 phi-like? (Marcus 2026-09-29 sweep)
#
# THE CONCERN (code audit, 09-29 d). q10 enters twice: q10^(gmst/10) on soil
# respiration (the century-scale climate-carbon feedback) and q10^(A_T sin/10)
# for the seasonal cycle. Only A_T * ln(q10) is identified by the seasonal rows,
# and the fit sits at q10 1.094 (prior LN(2, 0.25), z -2.41) on that ridge. So a
# value SET BY THE SEASONAL CYCLE is used for the LONG-TERM feedback -- the
# coupling-by-side-effect that made phi a problem.
#
# THE TEST (the unfitted screen's protocol, applied to a FITTED coordinate).
# Fix q10 at each value in Q10_VALUES and re-optimise the coordinates that can
# compensate: its seasonal ridge partners seas_T_amp_NH/SH, and the net-sink
# setters beta_max, fert_k, kz. Report the log-post cost (an UPPER BOUND on a
# full refit's) and CO2 at 2100 / 2300 under vvH and vvL, GCB spliced.
# ⚠ q10 = 2 sits at the prior's centre, so part of any cost is the
# likelihood and part is NOT paid (the prior improves); both are printed.
#
# USAGE: Rscript calibration/diag_q10_ridge_futures.R   (~5 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

Q10_MODE     <- "hilda29l"
Q10_VALUES   <- c(1.5, 2.0)
Q10_COMP     <- c("seas_T_amp_NH", "seas_T_amp_SH", "beta_max", "fert_k", "kz")
Q10_NM_MAXIT <- 400
Q10_SCEN     <- c("vvH", "vvL")
Q10_YEARS    <- c(2100L, 2300L)
Q10_END_YEAR <- 2300L

md <- readRDS(ccx_mode_file(Q10_MODE))
invisible(ccx_apply_pins(md$pins))
bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, md$struct, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
lp <- ccx_make_logpost(base_params = bp)
stopifnot(abs(lp(md$u_mode) - md$logpost) < 1e-6)
iq <- match("q10", md$param_names); ic <- match(Q10_COMP, md$param_names)
stopifnot(!is.na(iq), !anyNA(ic))
q_prior <- CCX_PARAM_TABLE$q10$prior
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
spliced <- function(s) { e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
u_at_q10 <- function(u, q) { p <- as.list(ccx_unc_to_par(u)); p$q10 <- q
  u2 <- ccx_par_to_unc(unlist(p)[md$param_names]); u2 }
futures <- function(u) {
  m2 <- md; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  unlist(lapply(Q10_SCEN, function(s) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, Q10_END_YEAR), emissions = spliced(s),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))$out
    co2 <- tapply((r$co2_NH + r$co2_SH) / 2, floor(r$t), mean)
    setNames(as.numeric(co2[as.character(Q10_YEARS)]), paste0(s, "_", Q10_YEARS))
  }))
}

cat(sprintf("=== PROVENANCE ===\n  commit %s, %s | mode %s logpost %.4f (control reproduces)\n",
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"),
            format(Sys.time(), "%Y-%m-%d %H:%M"), Q10_MODE, md$logpost))
cat(sprintf("  q10 fixed at {%s}; re-optimised: %s (Nelder-Mead, maxit %d); futures %s, GCB spliced\n\n",
            paste(Q10_VALUES, collapse = ", "), paste(Q10_COMP, collapse = ", "), Q10_NM_MAXIT,
            paste(Q10_SCEN, collapse = ", ")))
f0 <- futures(md$u_mode)
rows <- list(c(q10 = md$par_mode$q10, d_logpost = 0, d_prior_q10 = 0,
               unlist(md$par_mode[Q10_COMP]), f0 - f0))
for (q in Q10_VALUES) {
  u0 <- u_at_q10(md$u_mode, q)
  f <- function(x) { u <- u0; u[ic] <- x; v <- lp(u); if (!is.finite(v)) 1e12 else -v }
  o <- stats::optim(u0[ic], f, method = "Nelder-Mead", control = list(maxit = Q10_NM_MAXIT))
  u <- u0; u[ic] <- o$par; pr <- ccx_unc_to_par(u)
  rows[[length(rows) + 1]] <- c(q10 = q, d_logpost = -o$value - md$logpost,
    d_prior_q10 = q_prior(q) - q_prior(md$par_mode$q10), pr[Q10_COMP], futures(u) - f0)
  cat(sprintf("  q10 %.2f done (%d evals)\n", q, o$counts[["function"]]))
}
R <- as.data.frame(do.call(rbind, lapply(rows, function(r) as.numeric(unlist(r)))))
names(R) <- names(unlist(rows[[1]]))
# DECOMPOSITION (sign check): q10 = 2 with EVERYTHING else at the mode. Higher q10
# means a stronger respiration feedback, so on its own it must RAISE future CO2;
# a lower CO2 in the re-optimised row then has to come from the compensators.
dec <- futures(u_at_q10(md$u_mode, 2)) - f0
cat("\n=== q10 FIXED, ridge partners + sinks RE-OPTIMISED ===\n")
print(R, digits = 4, row.names = FALSE)
cat(sprintf("\n  DECOMPOSITION, q10 = 2 alone (nothing re-optimised): %s\n", paste(sprintf("%s %+.1f", names(dec), dec), collapse = ", ")))
cat(sprintf("\n  d_logpost includes the q10 prior's own change (d_prior_q10); the likelihood cost is d_logpost - d_prior_q10.\n"))
cat(sprintf("  futures columns: CO2 change (ppm) vs the canonical; canonical vvH 2100 %.1f, 2300 %.1f\n", f0[1], f0[2]))
out <- ccx_path("outputs", "diagnostics", sprintf("q10_ridge_futures_%s.csv", format(Sys.Date(), "%Y%m%d")))
utils::write.csv(R, out, row.names = FALSE); cat(sprintf("  saved %s\n", out))
