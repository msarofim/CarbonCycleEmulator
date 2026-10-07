#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_lowpass_ocean_price.R -- IS THE MAIN OBJECTIVE's RESISTANCE TO THE MODULE's LIMB INTERANNUAL?
# (RULED 2026-10-07, Marcus: "Test low-pass ocean row first (Recommended)"; CHANGELOG 2026-10-07 a/b.)
# Moving the module's four pins from stage 1's values to the one-pass check's (w_enso_l2 14.73 -> 16.71 at basin B,
# 17.68 at A) costs #17's main objective -1.29 (B) / -2.18 (A) unrefitted, led by `gcb_ocean_sink`
# (diag_obj17_iterate_price.R). The cut scores `gcb_land_sink` on its LOW-PASS part (LIK_LAND_LOWPASS_DF; the
# projector P onto [1, ns(year, df)]: row + |(I-P)e|^2 / (2 sd^2)) but `gcb_ocean_sink` year by year. This prices the
# ocean row the same way, at both pin sets, on each basin's vector (basin B is the representative, RULED 10-07):
#   the full row, its HIGH part's cost |(I-P)e|^2/(2 sd^2), and the low-pass row = full + that cost;
#   how much of the P0 -> P1 change is in the high part (what a low-pass ocean row would stop seeing);
#   what then remains of the main objective's resistance (the other rows, unchanged).
# The rows are rebuilt from a dg run on the OBJECTIVE's span with ccx_loglik()'s own construction (targets moved by the
# fitted imbalance shares; ccx_calendar_flux()). A PRICE: no objective changes, nothing refits.
# GATES: at stage 1's pins the rebuilt full ocean row is the stored `gcb_ocean_sink`, and the SAME code on the land row
# (+ E_LUC, the inflated sd, the cut's projector) is the stored low-pass `gcb_land_sink` (tol 1e-5; the dg path
# carries the objective's ~1e-6 floor, [[objective_noise_floor_optimum_on_spike]]).
# Usage: Rscript calibration/diag_obj17_lowpass_ocean_price.R
# OUTPUTS: outputs/diagnostics/obj17_lowpass_ocean_price_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
LO_DRIVER <- "calibration/diag_obj17_lowpass_ocean_price.R"
LO_MODES  <- c(B = file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds"),
               A = file.path("calibration", "output", "refit_20261007_obj17_hilda_csl3v0kaidgbemw", "mode_fit_pumpN.rds"))
LO_CHECKS <- c(B = file.path("outputs", "diagnostics", "obj17_dryrun_20261006", "iav_module_check_DRYRUN.rds"),
               A = file.path("calibration", "output", "iav_module_20261007_refit_20261007_obj17_hilda_csl3v0kaidgbemw.rds"))
LO_PRICE  <- file.path("outputs", "diagnostics", "obj17_iterate_price_20261007.rds")   # the main objective's P0 -> P1 change
LO_DF     <- LIK_LAND_LOWPASS_DF            # the cut's own projector, applied unchanged to the ocean row
LO_SD_O   <- LIK_GCB_OCEAN_SD               # the ocean row's own sd
LO_TOL    <- 1e-5
LO_MODULE <- CCX_IAV_MODULE_NAMES
LO_OUT <- file.path("outputs", "diagnostics", sprintf("obj17_lowpass_ocean_price_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(LO_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | projector df %d (LIK_LAND_LOWPASS_DF), ocean sd %g GtC/yr (LIK_GCB_OCEAN_SD)\n", LO_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), LO_DF, LO_SD_O))
OBS <- ccx_prepare_obs(); PRICE <- readRDS(LO_PRICE)

# the two GCB rows rebuilt as ccx_loglik() builds them, on one dg run of vector `v` (objective span)
gcb_rows <- function(v) {
  R <- dg_run(v); out <- R$out[R$out$t < LIK_IAV_SPAN_END + 1, , drop = FALSE]
  fl <- ccx_calendar_flux(out)
  luc <- ccx_forcing_eluc_annual(R$F)                                    # the model's own E_LUC (luc_scale applied)
  g <- merge(as.data.frame(OBS$gcb)[, c("year", "ocean_sink", "land_sink")], fl, by = "year")
  g <- merge(g, luc, by = "year")
  tgt_o <- g$ocean_sink; tgt_l <- g$land_sink
  sh <- ccx_imb_shares(v$pm)
  if (!is.null(sh)) { im <- ccx_imb_series(OBS$gcb); I <- im$I[match(g$year, im$year)]
    tgt_o <- tgt_o + sh[["ocean"]] * I; tgt_l <- tgt_l + sh[["land"]] * I }
  e_o <- tgt_o - g$ocean; e_l <- tgt_l - (g$land + g$eluc); sd_l <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE
  full_o <- sum(stats::dnorm(tgt_o, g$ocean, LO_SD_O, log = TRUE))
  high_o <- ccx_land_highpass_cost(e_o, g$year, LO_DF, LO_SD_O)
  land_lp <- sum(stats::dnorm(tgt_l, g$land + g$eluc, sd_l, log = TRUE)) + ccx_land_highpass_cost(e_l, g$year, LO_DF, sd_l)
  c(ocean_full = full_o, ocean_high_cost = high_o, ocean_lowpass = full_o + high_o, land_lowpass = land_lp, n = nrow(g)) }
with_module <- function(F, vals) { V <- dg_vector(F)
  for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V }

OUT <- list()
for (k in names(LO_MODES)) {
  md <- readRDS(LO_MODES[[k]]); P0 <- ccx_mode_pins(md); P0 <- stats::setNames(as.numeric(unclass(P0)), names(P0))[LO_MODULE]
  P1 <- readRDS(LO_CHECKS[[k]])$pins[LO_MODULE]
  r0 <- gcb_rows(with_module(LO_MODES[[k]], P0)); r1 <- gcb_rows(with_module(LO_MODES[[k]], P1))
  cat(sprintf("\n=== basin %s (%s, md5 %s), %d GCB years ===\n", k, LO_MODES[[k]], unname(tools::md5sum(LO_MODES[[k]])), r0[["n"]]))
  g_o <- r0[["ocean_full"]] - md$streams$gcb_ocean_sink; g_l <- r0[["land_lowpass"]] - md$streams$gcb_land_sink
  cat(sprintf("  GATES at stage 1's pins: the rebuilt ocean row %.6f vs stored %.6f (%+.1e); the low-pass land row %.6f vs stored %.6f (%+.1e)\n",
              r0[["ocean_full"]], md$streams$gcb_ocean_sink, g_o, r0[["land_lowpass"]], md$streams$gcb_land_sink, g_l))
  if (abs(g_o) > LO_TOL || abs(g_l) > LO_TOL) stop("basin ", k, ": the rebuilt GCB rows do not reproduce the stored ones")
  d <- r1 - r0; tot <- PRICE[[k]]$d_lik; d_o_row <- PRICE[[k]]$rows[["gcb_ocean_sink"]]
  if (abs(d_o_row - d[["ocean_full"]]) > LO_TOL) stop("basin ", k, ": the ocean row's change disagrees with diag_obj17_iterate_price.R's")
  cat(sprintf("  pins %s -> %s\n", paste(sprintf("%.4f", P0), collapse = "/"), paste(sprintf("%.4f", P1), collapse = "/")))
  cat(sprintf("  gcb_ocean_sink, year by year (as scored): %+.4f -> %+.4f  (change %+.4f)\n", r0[["ocean_full"]], r1[["ocean_full"]], d[["ocean_full"]]))
  cat(sprintf("    its HIGH part's cost:                    %+.4f -> %+.4f  (change %+.4f: the interannual part)\n",
              r0[["ocean_high_cost"]], r1[["ocean_high_cost"]], d[["ocean_high_cost"]]))
  cat(sprintf("    its LOW-PASS part (df %d):                %+.4f -> %+.4f  (change %+.4f: what a low-pass row would see)\n",
              LO_DF, r0[["ocean_lowpass"]], r1[["ocean_lowpass"]], d[["ocean_lowpass"]]))
  cat(sprintf("  the main objective's resistance (diag_obj17_iterate_price.R): %+.4f in all; with a low-pass ocean row it would be %+.4f\n",
              tot, tot - d[["ocean_full"]] + d[["ocean_lowpass"]]))
  oth <- PRICE[[k]]$rows[setdiff(names(PRICE[[k]]$rows), "gcb_ocean_sink")]; oth <- oth[order(-abs(oth))]
  cat(sprintf("    what remains is the other rows: %s\n", paste(sprintf("%s %+.3f", names(oth)[1:4], oth[1:4]), collapse = ", ")))
  OUT[[k]] <- list(p0 = P0, p1 = P1, r0 = r0, r1 = r1, d = d, resistance = tot, resistance_lowpass = tot - d[["ocean_full"]] + d[["ocean_lowpass"]])
}
saveRDS(c(OUT, list(provenance = list(driver = LO_DRIVER, commit = COMMIT, modes = LO_MODES, checks = LO_CHECKS, price = LO_PRICE,
                                       df = LO_DF, sd_ocean = LO_SD_O, date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none"))),
        paste0(LO_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", LO_OUT))
sink()
