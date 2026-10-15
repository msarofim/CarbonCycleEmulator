# =====================================================================
# diag_unfitted_screen.R -- which UNFITTED parameters behave like phi?
# Asked by Marcus 2026-09-29: "Sweep the rest of the model for anything like phi
# that might be a parameter that doesn't make physical sense."
#
# THE PHI SIGNATURE, which this screen measures: the historical record can
# barely see it once the fitted parameters compensate, yet it moves projections
# a lot. (phi = npp_veg_frac: a refit at phi = 0 changed log-lik by +1.3 and CO2
# at 2300 under vvH by +219 ppm; diag_phi0_futures.R.)
#
# PROTOCOL. For each unfitted parameter at the canonical (hilda29l), each
# perturbation (x0.5, x2; fractions capped below 1):
#   (1) FROZEN cost: logpost with all 29 fitted coordinates at the mode.
#   (2) REBALANCED cost: re-optimize the three coordinates that set the NET
#       sinks -- beta_max, fert_k (land) and kz (ocean) -- Nelder-Mead from the
#       mode, SCR_NM_MAXIT iterations. A full refit could only do BETTER, so this
#       is an UPPER BOUND on what the record charges; the phi precedent (frozen
#       -11,615, 2-D rebalance -7.27, full refit +0.73) says the bound can be loose.
#   (3) FUTURE at the rebalanced vector: global CO2 at 2100 and 2300 under the
#       van Vuuren H and L markers, GCB history spliced as the app does.
# ⭐ POWER CONTROL: npp_veg_frac 0.5 -> 0 is run first. The screen is only worth
# reading if it flags phi (small rebalanced cost, large future effect).
# A parameter whose frozen cost is EXACTLY 0 and whose futures do not move is
# INERT in the canonical (its structure is switched off) and is reported so.
#
# ⚠ A SCREEN, NOT A VERDICT: one-at-a-time, three compensators, a local search.
# Candidates it raises are for a full refit (as phi got), not for adoption.
#
# USAGE: Rscript calibration/diag_unfitted_screen.R [param ...]   (~20-30 min for all)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
SCR_COMMIT <- ccx_git_stamp()
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
SCR_MODE       <- "hilda29l"
SCR_FACTORS    <- c(0.5, 2)
SCR_FRAC_CAP   <- 0.95          # a fraction is never pushed to or past 1
SCR_COMP       <- c("beta_max", "fert_k", "kz")
SCR_NM_MAXIT   <- 120
SCR_SCEN       <- c("vvH", "vvL")
SCR_YEARS      <- c(2100L, 2300L)
SCR_END_YEAR   <- 2300L         # standing end year
# Continuous, ACTIVE-looking unfitted scalars (zero-valued switches are left to
# the code audit: a x0.5/x2 perturbation of 0 is still 0).
SCR_PARAMS <- c("tau_leaf", "npp_leaf_frac", "tau_wood", "litter_slow_frac",
                "tau_soil_fast", "tau_soil_slow", "f_luc_perm",
                "pump_carb_frac", "tau_q", "sst_hs", "sst_scale", "gamma_diff",
                "kz_zscale", "conv_sink", "hs_frac", "alpha_photo_eps",
                "k_e1", "k_e2", "k_thc", "k_l2", "w0_l2", "k_eq", "kz_tr_frac",
                "seas_npp_amp_NH", "seas_npp_amp_SH", "seas_amp_NH", "seas_amp_SH",
                "sst_NH", "sst_SH", "beta")
SCR_FRACTIONS <- c("npp_leaf_frac", "litter_slow_frac", "f_luc_perm", "pump_carb_frac",
                   "hs_frac", "kz_tr_frac", "npp_veg_frac")
SCR_CONTROL <- list(name = "npp_veg_frac", values = 0)   # the phi knock-out
args <- commandArgs(TRUE)
if (length(args)) SCR_PARAMS <- intersect(SCR_PARAMS, args)

md <- readRDS(ccx_mode_file(SCR_MODE))
invisible(ccx_apply_pins(md$pins))
base0 <- ccx_default_params(); base0$pump_mode <- md$pump_mode
base0 <- ccx_apply_structure(base0, md$struct, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) base0[[n]] <- md$pins[[n]]
ic <- match(SCR_COMP, md$param_names)
stopifnot(!anyNA(ic))
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
spliced <- function(s) { e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }

mk_lp <- function(over) { bp <- base0; for (n in names(over)) bp[[n]] <- over[[n]]
  ccx_make_logpost(base_params = bp) }

lp_ctrl <- mk_lp(list())(md$u_mode)
cat(sprintf("=== PROVENANCE ===\n  driver calibration/diag_unfitted_screen.R, commit %s, %s\n",
            SCR_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  mode %s (struct %s), stored logpost %.4f, re-scored %.4f -> %s\n", SCR_MODE, md$struct,
            md$logpost, lp_ctrl, if (abs(lp_ctrl - md$logpost) < 1e-6) "CONTROL REPRODUCES" else "*** CONTROL FAILS ***"))
if (abs(lp_ctrl - md$logpost) > 1e-6) stop("the unperturbed objective does not reproduce the mode")
cat(sprintf("  rebalance: %s, Nelder-Mead maxit %d | futures: %s, GCB spliced, to %d\n\n",
            paste(SCR_COMP, collapse = "+"), SCR_NM_MAXIT, paste(SCR_SCEN, collapse = ", "), SCR_END_YEAR))

futures <- function(over, u) {
  m2 <- md; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  for (n in names(over)) p[[n]] <- over[[n]]
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  unlist(lapply(SCR_SCEN, function(s) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, SCR_END_YEAR), emissions = spliced(s),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))$out
    co2 <- tapply((r$co2_NH + r$co2_SH) / 2, floor(r$t), mean)
    setNames(as.numeric(co2[as.character(c(2024L, SCR_YEARS))]),
             paste0(s, "_", c(2024L, SCR_YEARS)))
  }))
}

one <- function(name, val) {
  over <- setNames(list(val), name)
  lp <- mk_lp(over)
  frozen <- lp(md$u_mode)
  f <- function(x) { u <- md$u_mode; u[ic] <- x; v <- lp(u); if (!is.finite(v)) 1e12 else -v }
  o <- stats::optim(md$u_mode[ic], f, method = "Nelder-Mead", control = list(maxit = SCR_NM_MAXIT))
  u <- md$u_mode; u[ic] <- o$par
  pr <- ccx_unc_to_par(u)
  c(list(param = name, base = base0[[name]], value = val,
         d_frozen = frozen - md$logpost, d_rebal = -o$value - md$logpost,
         beta_max = pr[["beta_max"]], fert_k = pr[["fert_k"]], kz = pr[["kz"]]),
    as.list(futures(over, u)))
}

t0 <- Sys.time()
ref <- c(list(param = "(canonical)", base = NA, value = NA, d_frozen = 0, d_rebal = 0,
              beta_max = md$par_mode$beta_max, fert_k = md$par_mode$fert_k, kz = md$par_mode$kz),
         as.list(futures(list(), md$u_mode)))
rows <- list(ref, one(SCR_CONTROL$name, SCR_CONTROL$values))
for (nm in SCR_PARAMS) {
  b <- base0[[nm]]
  if (is.null(b) || !is.numeric(b) || b == 0) { cat(sprintf("  skip %s (absent or zero)\n", nm)); next }
  for (fa in SCR_FACTORS) {
    v <- b * fa
    if (nm %in% SCR_FRACTIONS) v <- min(v, SCR_FRAC_CAP)
    if (v == b) next
    rows[[length(rows) + 1]] <- one(nm, v)
    r <- rows[[length(rows)]]
    cat(sprintf("  %-17s %8.4g -> %-8.4g frozen %+10.2f  rebal %+8.2f | vvH 2100 %6.1f 2300 %6.1f | %.1f min\n",
                nm, b, v, r$d_frozen, r$d_rebal, r$vvH_2100, r$vvH_2300,
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }
}
R <- do.call(rbind, lapply(rows, as.data.frame))
for (s in SCR_SCEN) for (y in SCR_YEARS) {
  k <- paste0(s, "_", y); R[[paste0("d_", k)]] <- R[[k]] - R[[k]][1]
}
R$inert <- R$d_frozen == 0 & abs(R$d_vvH_2300) < 1e-6
R$inert[1] <- FALSE          # the canonical is the reference row, not a perturbation
out <- ccx_path("outputs", "diagnostics", sprintf("unfitted_screen_%s.csv", format(Sys.Date(), "%Y%m%d")))
utils::write.csv(R, out, row.names = FALSE)

cat("\n=== SCREEN (frozen = everything else at the mode; rebal = beta_max+fert_k+kz re-fitted) ===\n")
cat(sprintf("%-17s %9s %9s %10s %9s | %7s %7s | %7s %7s | %s\n", "param", "base", "value",
            "d_frozen", "d_rebal", "H2100", "H2300", "L2100", "L2300", "note"))
for (i in seq_len(nrow(R))) with(R[i, ], cat(sprintf(
  "%-17s %9.4g %9.4g %+10.2f %+9.2f | %+7.1f %+7.1f | %+7.1f %+7.1f | %s\n",
  param, base, value, d_frozen, d_rebal, d_vvH_2100, d_vvH_2300, d_vvL_2100, d_vvL_2300,
  if (isTRUE(inert)) "INERT in canonical" else "")))
cat(sprintf("\n  columns H/L = CO2 change (ppm) vs the canonical under vvH / vvL; canonical 2024 %.1f ppm\n",
            R$vvH_2024[1]))
cat(sprintf("  saved %s\n  ⛔ A screen: candidates go to a full refit, nothing is adopted.\n", out))
