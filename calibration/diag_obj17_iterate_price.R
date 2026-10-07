#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_iterate_price.R -- WHAT A SECOND PASS WOULD COST THE MAIN OBJECTIVE (CHANGELOG 2026-10-07 a). The one-pass
# check re-ran stage 1 at each basin's stage-2 vector and moved w_enso_l2 by more than the ruled 0.1 sigma (A +2.31,
# B +1.55). Before "iterate" is framed: score each basin's vector on #17's MAIN objective with the module's four pins
# at stage 1's values and at the check's re-run values, UNREFITTED. A near-zero cost would mean a second stage 2 has
# nothing to move; a cost means the main objective's own rows resist the limb the module wants.
# Also: the module's slope row and the model's ENSO ocean slope (ccx_enso_slope(), the row's own estimator) at the
# re-run pins. A preview: it prices, it refits nothing.
# Usage: Rscript calibration/diag_obj17_iterate_price.R
# OUTPUTS: outputs/diagnostics/obj17_iterate_price_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
IP_DRIVER <- "calibration/diag_obj17_iterate_price.R"
IP_MODES  <- c(A = file.path("calibration", "output", "refit_20261007_obj17_hilda_csl3v0kaidgbemw", "mode_fit_pumpN.rds"),
               B = file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds"))
IP_CHECKS <- c(A = file.path("calibration", "output", "iav_module_20261007_refit_20261007_obj17_hilda_csl3v0kaidgbemw.rds"),
               B = file.path("outputs", "diagnostics", "obj17_dryrun_20261006", "iav_module_check_DRYRUN.rds"))
IP_MODULE <- CCX_IAV_MODULE_NAMES
IP_TOP    <- 6L
IP_OUT <- file.path("outputs", "diagnostics", sprintf("obj17_iterate_price_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(IP_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n", IP_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
OBS <- ccx_prepare_obs()

# one vector on its OWN objective with `pins` (diag_obj17_basins.R's own(), the pins overridable)
score <- function(md, pins) { lab <- ccx_mode_struct(md)
  g <- ccx_apply_gate(lab); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_mode_base(md); for (n in names(pins)) bp[[n]] <- pins[[n]]; bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), obs = OBS)
  v <- lp(ccx_par_to_unc(ccx_mode_par_with_pins(md)))
  list(lp = as.numeric(v), lik = attr(v, "loglik"), st = unlist(attr(v, "streams"))) }
# the module's slope row and the model's ENSO ocean slope at a vector with the module's names at `vals`
slope_at <- function(F, vals) { V <- dg_vector(F)
  for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); R <- dg_run(V)
  ml <- ccx_iav_module_loglik(R$out, R$F, OBS, ssr_ref = 1)                 # the slope row does not read ssr_ref
  fl <- ccx_calendar_flux(R$out[R$out$t < LIK_IAV_SPAN_END + 1, , drop = FALSE])
  c(row = ml[["slope_row"]], slope = ccx_enso_slope(fl$year, fl$ocean, OBS$enso_idx)[["slope"]]) }

OUT <- list()
for (k in names(IP_MODES)) {
  md <- readRDS(IP_MODES[[k]]); ck <- readRDS(IP_CHECKS[[k]])
  P0 <- ccx_mode_pins(md); P0 <- stats::setNames(as.numeric(unclass(P0)), names(P0))
  stopifnot(all(IP_MODULE %in% names(P0)), all(IP_MODULE %in% names(ck$pins)))
  P1 <- P0; P1[IP_MODULE] <- as.numeric(ck$pins[IP_MODULE])
  a <- score(md, P0); b <- score(md, P1)
  if (abs(a$lp - md$logpost) > 1e-5) stop("basin ", k, " does not reproduce its stored logpost at its own pins")
  d <- b$st - a$st[names(b$st)]; d <- d[order(-abs(d))]
  s0 <- slope_at(IP_MODES[[k]], P0[IP_MODULE]); s1 <- slope_at(IP_MODES[[k]], P1[IP_MODULE])
  cat(sprintf("\n=== basin %s (%s, md5 %s) ===\n  the module's pins  %s\n  -> the check's     %s  (%s)\n", k, IP_MODES[[k]],
              unname(tools::md5sum(IP_MODES[[k]])), paste(sprintf("%s %.4f", IP_MODULE, P0[IP_MODULE]), collapse = ", "),
              paste(sprintf("%.4f", P1[IP_MODULE]), collapse = ", "), IP_CHECKS[[k]]))
  cat(sprintf("  MAIN objective, unrefitted: likelihood %+.4f, logpost %+.4f (stored logpost reproduced: %+.1e)\n",
              b$lik - a$lik, b$lp - a$lp, a$lp - md$logpost))
  cat(sprintf("  the %d largest rows: %s\n", IP_TOP, paste(sprintf("%s %+.3f", names(d)[seq_len(IP_TOP)], d[seq_len(IP_TOP)]), collapse = ", ")))
  cat(sprintf("  the module's slope row %+.4f -> %+.4f; the model's ENSO ocean slope %.4f -> %.4f (%.2fx -> %.2fx obs %.4f)\n",
              s0[["row"]], s1[["row"]], s0[["slope"]], s1[["slope"]], s0[["slope"]] / OBS$enso_slope[["slope"]],
              s1[["slope"]] / OBS$enso_slope[["slope"]], OBS$enso_slope[["slope"]]))
  OUT[[k]] <- list(pins0 = P0[IP_MODULE], pins1 = P1[IP_MODULE], d_lik = b$lik - a$lik, d_lp = b$lp - a$lp, rows = d,
                   slope0 = s0, slope1 = s1)
}
saveRDS(c(OUT, list(provenance = list(driver = IP_DRIVER, commit = COMMIT, modes = IP_MODES, checks = IP_CHECKS,
                                       date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none"))), paste0(IP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", IP_OUT))
sink()
