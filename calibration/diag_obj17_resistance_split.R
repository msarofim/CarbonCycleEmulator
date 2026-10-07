#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_resistance_split.R -- WHERE does #17's main objective resist the module's limb: in each row's INTERANNUAL
# part, or in its low-frequency part? (CHANGELOG 2026-10-07 b; the follow-on to diag_obj17_lowpass_ocean_price.R,
# which found `gcb_ocean_sink`'s share purely interannual and ~43 % of the whole at basin B.)
# Moving the module's four pins from stage 1's values (P0) to the one-pass check's (P1) costs the main objective
# -1.29 (B) / -2.18 (A) unrefitted (diag_obj17_iterate_price.R). For each of the rows that carry it, the residuals AS
# SCORED (ccx_loglik(residuals = TRUE), through dg_streams()) are split by the cut's own projector P onto
# [1, ns(year, LIK_LAND_LOWPASS_DF)]: the row = (its low-pass part) - |(I-P)e|^2 / (2 sd^2) (each coefficient series of
# a seasonal row separately). The change P0 -> P1 is then: its high part's cost (interannual) and its low-pass part.
# A PRICE of where the resistance lives. It proposes no objective: low-passing a CO2 LEVEL row is a design question
# (the levels are the model's main constraint), and the projector's df is the land row's, not tuned per row.
# GATES: the dg rows at P0 are the stored streams (tol 1e-5, the objective's ~1e-6 floor); each row's P0 -> P1 change
# is diag_obj17_iterate_price.R's (tol 1e-5); the residuals rebuild each row's value from its own sd (tol 1e-8).
# Usage: Rscript calibration/diag_obj17_resistance_split.R
# OUTPUTS: outputs/diagnostics/obj17_resistance_split_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
RS_DRIVER <- "calibration/diag_obj17_resistance_split.R"
RS_MODES  <- c(B = file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds"),
               A = file.path("calibration", "output", "refit_20261007_obj17_hilda_csl3v0kaidgbemw", "mode_fit_pumpN.rds"))
RS_CHECKS <- c(B = file.path("outputs", "diagnostics", "obj17_dryrun_20261006", "iav_module_check_DRYRUN.rds"),
               A = file.path("calibration", "output", "iav_module_20261007_refit_20261007_obj17_hilda_csl3v0kaidgbemw.rds"))
RS_PRICE  <- file.path("outputs", "diagnostics", "obj17_iterate_price_20261007.rds")
RS_DF     <- LIK_LAND_LOWPASS_DF
RS_ROWS   <- c("gcb_ocean_sink", "co2_level_MLO", "co2_level_SPO", "co2_seasonal_MLO", "co2_seasonal_SPO")
RS_TOL    <- 1e-5
RS_MODULE <- CCX_IAV_MODULE_NAMES
RS_OUT <- file.path("outputs", "diagnostics", sprintf("obj17_resistance_split_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(RS_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | projector df %d (LIK_LAND_LOWPASS_DF) for every row\n", RS_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), RS_DF))
OBS <- ccx_prepare_obs(); PRICE <- readRDS(RS_PRICE)

# each row's scored years and sd(s), one entry per coefficient series (ccx_loglik()'s own construction)
row_spec <- function(row) {
  if (row == "gcb_ocean_sink") return(NULL)                                      # years from the flux merge, below
  st <- sub("^co2_(level|seasonal)_", "", row)
  if (grepl("^co2_level_", row)) { o <- OBS$co2_ann[[st]]; return(list(list(year = o$year, sd = LIK_CO2_REP_ERR))) }
  o <- OBS$co2_seas[[st]]; list(list(year = o$year, sd = o$sd_a), list(year = o$year, sd = o$sd_b)) }
split_row <- function(res, row, gcb_years) {
  sp <- if (row == "gcb_ocean_sink") list(list(year = gcb_years, sd = LIK_GCB_OCEAN_SD)) else row_spec(row)
  if (length(sp) != length(res)) stop(row, ": ", length(res), " residual series, expected ", length(sp))
  parts <- mapply(function(e, s) {
    if (length(e) != length(s$year)) stop(row, ": ", length(e), " residuals for ", length(s$year), " years")
    if (length(s$sd) != 1L) stop(row, ": a per-year sd -- the scalar split does not apply")
    c(gauss = sum(stats::dnorm(e, 0, s$sd, log = TRUE)), high = ccx_land_highpass_cost(e, s$year, RS_DF, s$sd)) },
    res, sp, SIMPLIFY = TRUE)
  c(row = sum(parts["gauss", ]), high_cost = sum(parts["high", ]), lowpass = sum(parts["gauss", ]) + sum(parts["high", ])) }
with_module <- function(F, vals) { V <- dg_vector(F)
  for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V }
gcb_years_of <- function(r) { fl <- ccx_calendar_flux(r$out[r$out$t < LIK_IAV_SPAN_END + 1, , drop = FALSE])
  sort(intersect(intersect(OBS$gcb$year, fl$year), ccx_forcing_eluc_annual(r$F)$year)) }
rows_at <- function(V) { r <- dg_run(V); st <- dg_streams(r, V, obs = OBS, residuals = TRUE); RES <- attr(st, "residuals")
  gy <- gcb_years_of(r); s <- unlist(st)
  out <- t(vapply(RS_ROWS, function(row) split_row(RES[[row]], row, gy), numeric(3)))
  list(streams = s, split = out) }

OUT <- list()
for (k in names(RS_MODES)) {
  md <- readRDS(RS_MODES[[k]]); P0 <- ccx_mode_pins(md); P0 <- stats::setNames(as.numeric(unclass(P0)), names(P0))[RS_MODULE]
  P1 <- readRDS(RS_CHECKS[[k]])$pins[RS_MODULE]
  a <- rows_at(with_module(RS_MODES[[k]], P0)); b <- rows_at(with_module(RS_MODES[[k]], P1))
  cat(sprintf("\n=== basin %s (%s, md5 %s): pins %s -> %s ===\n", k, RS_MODES[[k]], unname(tools::md5sum(RS_MODES[[k]])),
              paste(sprintf("%.4f", P0), collapse = "/"), paste(sprintf("%.4f", P1), collapse = "/")))
  g0 <- max(abs(a$streams[names(md$streams)] - md$streams)); cat(sprintf("  GATE: the dg rows at P0 vs the stored streams, max |diff| %.1e\n", g0))
  if (g0 > RS_TOL) stop("basin ", k, ": the dg rows do not reproduce the stored streams")
  g1 <- max(abs(a$split[, "row"] - a$streams[RS_ROWS])); cat(sprintf("  GATE: the residuals rebuild each row from its sd, max |diff| %.1e\n", g1))
  if (g1 > 1e-8) stop("basin ", k, ": the residuals do not rebuild the rows (an offset or a per-year sd the split misses)")
  D <- b$split - a$split
  g2 <- max(abs(D[, "row"] - PRICE[[k]]$rows[RS_ROWS])); cat(sprintf("  GATE: each row's change vs diag_obj17_iterate_price.R, max |diff| %.1e\n", g2))
  if (g2 > RS_TOL) stop("basin ", k, ": the row changes disagree with the iterate price")
  cat(sprintf("  %-18s %10s %18s %16s\n", "row", "change", "interannual part", "low-pass part"))
  for (row in RS_ROWS) cat(sprintf("  %-18s %+10.4f %+18.4f %+16.4f\n", row, D[row, "row"], -D[row, "high_cost"], D[row, "lowpass"]))
  rest <- PRICE[[k]]$d_lik - sum(D[, "row"])
  cat(sprintf("  %-18s %+10.4f %+18.4f %+16.4f\n", "these five", sum(D[, "row"]), -sum(D[, "high_cost"]), sum(D[, "lowpass"])))
  cat(sprintf("  the other rows: %+.4f; in all %+.4f (diag_obj17_iterate_price.R)\n", rest, PRICE[[k]]$d_lik))
  OUT[[k]] <- list(p0 = P0, p1 = P1, split0 = a$split, split1 = b$split, change = D, rest = rest, total = PRICE[[k]]$d_lik)
}
saveRDS(c(OUT, list(provenance = list(driver = RS_DRIVER, commit = COMMIT, modes = RS_MODES, checks = RS_CHECKS, price = RS_PRICE,
                                       df = RS_DF, rows = RS_ROWS, date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none"))),
        paste0(RS_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", RS_OUT))
sink()
