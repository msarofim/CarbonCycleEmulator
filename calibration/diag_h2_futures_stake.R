#!/usr/bin/env Rscript
# =====================================================================
# diag_h2_futures_stake.R -- H2's DIAGNOSTIC: what is at stake for FUTURE CO2 if CCX's ocean thermal response
# were the size GCB's ocean models give? 2026-10-06, Marcus: "Do the H2 diagnostic and test."
#
# THE QUESTION. CCX's ocean-sink climate effect is 1.87x GCB's like-for-like (10-05 p), and its response per K of
# warming 1.63x (calibration/diag_h2_time_shape.R, M3). How much of the futures rides on that excess?
# THE KNOB, a DIAGNOSTIC ONLY (no model change): the ocean's SST ANOMALY, the one input every ocean thermal path
# reads (solubility and chemistry in the mixed layer and the high-latitude box), is scaled by f in a wrapper around
# ccx_sst_anom_from_gmst(), the ONE function that builds it for the history (R/forcing.R) and, in every coupled
# iteration, for the futures (R/climate.R). GMST, q10, the land and the stratification feedback are untouched.
#   ALL-TIME arms: the anomaly x f everywhere (history and futures).
#   FUTURES-ONLY arms: only the post-record INCREMENT is scaled -- seam + f x (anomaly - seam), the seam being the
#     builder's own last-decade observed level -- so 1750-2024 is bit-identical and there is no step at the seam.
# THE f VALUES. f_T = 0.613 brings the like-for-like 2015-24 effect to GCB's -0.20 if it scales linearly with the
# anomaly (its parts: SST -0.452, the ENSO limb +0.097, the feedback -0.020; the H2 spec); 0.502 / 0.724 are GCB's
# +-1 sigma. INDEPENDENTLY, M3's per-K ratio gives 1 / 1.63 = 0.61. f_W = 0.296 matches Bunsen's single-GOBM
# warming part (FESOM protocol, 2000-19; the H2 spec). 0 and 1 are the gates' ends. A GRID, not a fit: these are
# unrefitted counterfactuals, and the historical fit would move under any f < 1.
# THE GATES:
#   G1 f = 1 through the wrapper IS the unwrapped run (identical()), and SSP5-8.5 2300 reproduces 10-05 (p)'s
#      1461.53 ppm (obj16_refit_read_20261005.log, the same estimator, br_futures());
#   G2 f = 0 equals the model's OWN route to no SST warming (p$sst_obs = 0, p$sst_scale = 0, unwrapped), identical();
#   G3 a futures-only arm reproduces the f = 1 run over the history, identical(), as TWO exact checks (Marcus 2026-10-13:
#      "Both exact checks (Recommended)"):
#      G3a at the arms' OWN settings, over 1750 to the last year BOTH observed records cover (GMST and SST);
#      G3b with both runs forced to the coupled loop's cap (tol 0, CLIM_MAX_ITER iterations), over 1750 to the SST
#          record's last year, so the year the SST seam sits in is still tested exactly.
#      WHY TWO. The GMST record ends a year before the SST record (2024 vs 2025), so the SST-observed year runs on
#      MODELLED GMST, which carries the loop's convergence residual. Two arms whose futures differ can stop after
#      different iteration counts, and that year then differs at the residual (hilda31w: 6 vs 5 iterations, 8e-13 ppm
#      in 2025; outputs/diagnostics/h2_futures_stake_20261013_hilda31w_G3_FAILED.log). That is not a leak: forced to
#      one count the two are bit-identical through 2025. G3a alone would never see a leak INTO that year; G3b does.
# Outputs: CO2 and GMST at 2100 / 2150 / 2300 for the seven van Vuuren markers (spliced onto the historical
# emissions, as the app runs them) and SSP5-8.5 (unspliced, the record's anchor). No RNG.
# Usage: Rscript calibration/diag_h2_futures_stake.R   (CCX_HF_WORKERS=<n>, default 4)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) ------------------------------------
HF_DRIVER  <- "calibration/diag_h2_futures_stake.R"
HF_WORKERS <- as.integer(Sys.getenv("CCX_HF_WORKERS", "4"))
HF_MODE    <- CCX_MODE_CANONICAL
HF_SCEN    <- c(vvVL = TRUE, vvLN = TRUE, vvL = TRUE, vvML = TRUE, vvM = TRUE, vvHL = TRUE, vvH = TRUE, ssp585 = FALSE)  # spliced?
HF_YEARS   <- c(2100L, 2150L, 2300L)
HF_END     <- 2300L                                # the standing end year
# THE f VALUES ARE A PROPERTY OF THE MODE (2026-10-08 j). hilda33p's were typed (below, kept so 10-06 (j) reproduces);
# carried to hilda29e they mis-size every arm, because the cut shrank the ENSO limb's credit (+0.097 -> +0.047) and the
# GCB-sized f moves with it (0.613 -> ~0.49). For any mode with a registered diag_ocean_climate_gobm.R product they are
# DERIVED from it, md5-gated to the mode file, by the header's own definitions:
#   f_T = (GCB - other) / sst, other = effect - effect_sst_only (the ENSO limb + the feedback), sst = effect_sst_only
#   (ten-protocol means, 2015-24); f_T_lo / f_T_hi at GCB -/+ its 1 sigma; f_W = Bunsen's warming part / CCX's SST-only
#   effect under the FESOM protocol (2000-19).
HF_GCB      <- c(mean = -0.20, sd = 0.05)   # GCB 2025 p. 3242 (VERIFIED in diag_ocean_climate_gobm.R's header)
HF_BUNSEN_W <- 0.09                         # Bunsen, Nissen & Hauck 2024 GRL s3.1, FESOM 2000-19 warming part (as
                                            # diag_ocean_climate_gobm.R CHECK 3 cites it; section-cited, not marked verified)
HF_F_TYPED  <- list(hilda33p = c(f1 = 1, f_T_hi = 0.724, f_T = 0.613, f_T_lo = 0.502, f_W = 0.296, f0 = 0))
HF_OC_RDS   <- list(hilda29e = file.path("outputs", "diagnostics", "ocean_climate_gobm_20261008_obj18p2b1.rds"),
                    # hilda31w (2026-10-13): the WTC wave's stage-C product, made as `wtcid017` before the rename; md5-gated
                    hilda31w = file.path("outputs", "diagnostics", "ocean_climate_gobm_20261013_wtcid017.rds"))
hf_derive_f <- function(rds, mode_file) {
  x <- readRDS(rds)
  md5 <- sub("^md5 ", "", regmatches(x$provenance, regexpr("md5 [0-9a-f]{32}", x$provenance)))
  if (!identical(md5, unname(tools::md5sum(mode_file)))) stop("the ocean-climate product ", rds, " is not this mode file's")
  sst <- mean(x$table[, "effect_sst_only"]); other <- mean(x$table[, "effect"]) - sst
  fT <- function(g) (g - other) / sst
  c(f1 = 1, f_T_hi = fT(HF_GCB[["mean"]] - HF_GCB[["sd"]]), f_T = fT(HF_GCB[["mean"]]),
    f_T_lo = fT(HF_GCB[["mean"]] + HF_GCB[["sd"]]), f_W = HF_BUNSEN_W / abs(x$bunsen_window[["sst_only"]]), f0 = 0)
}
HF_ALL <- if (!is.null(HF_OC_RDS[[HF_MODE]])) hf_derive_f(HF_OC_RDS[[HF_MODE]], ccx_mode_file(HF_MODE)) else
  HF_F_TYPED[[HF_MODE]] %||% stop("no f values for ", HF_MODE, ": register its diag_ocean_climate_gobm.R product")
HF_FUT     <- c(fut_f_T = HF_ALL[["f_T"]], fut_f_W = HF_ALL[["f_W"]])
# G1b's reference: SSP5-8.5 (unspliced) CO2 in 2300 at the MODE, produced by ANOTHER path. Keyed by mode (2026-10-08 j):
#   hilda33p 1461.53 -- 10-05 (p), obj16_refit_read_20261005.log l. 83;
#   hilda29e 1475.29 -- the APP's own params + spin-up (app_params(), app_spinup()), calibration/diag_app_ssp585_ref.R,
#                       outputs/diagnostics/app_ssp585_ref_20261008_hilda29e.log (1475.2878);
#   hilda31w 1486.85 -- the same app path, outputs/diagnostics/app_ssp585_ref_20261013_hilda31w.log (1486.8484 @6ddf4b2).
HF_REC_BY_MODE <- list(hilda33p = c(ssp585_2300 = 1461.53), hilda29e = c(ssp585_2300 = 1475.29),
                       hilda31w = c(ssp585_2300 = 1486.85))
if (is.null(HF_REC_BY_MODE[[HF_MODE]])) stop("no independent SSP5-8.5 2300 reference recorded for ", HF_MODE, ": G1b cannot run")
HF_REC     <- HF_REC_BY_MODE[[HF_MODE]]
HF_REC_TOL <- 0.005                                # half its printed last digit
HF_FROM    <- Sys.getenv("CCX_HF_FROM_RUNS", "")   # a saved _runs.rds: rebuild the tables without re-running
HF_OUT     <- file.path("outputs", "diagnostics", sprintf("h2_futures_stake_%s_%s", format(Sys.Date(), "%Y%m%d"), HF_MODE))
COMMIT     <- ccx_git_stamp()

LOGCON <- file(paste0(HF_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s | %s | canonical %s | %d workers\n", HF_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), HF_MODE, HF_WORKERS))
cat(sprintf("f values (%s): %s\n", if (!is.null(HF_OC_RDS[[HF_MODE]])) paste("DERIVED from", HF_OC_RDS[[HF_MODE]]) else "typed (10-06 j)",
            paste(sprintf("%s %.4f", names(HF_ALL), HF_ALL), collapse = ", ")))

# ---- the vector, the spinup, the scenarios -------------------------------------------------------------------
MODE_FILE <- ccx_mode_file(HF_MODE)
V  <- dg_vector(MODE_FILE)
SP <- dg_spinup(V)
HE <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
SO <- as.data.frame(readRDS(ccx_path("data", "forcing_sst.rds")))
SEAM <- c(NH = mean(SO$sst_anom_NH[SO$year > max(SO$year) - CCX_SST_SPLICE_YR]),
          SH = mean(SO$sst_anom_SH[SO$year > max(SO$year) - CCX_SST_SPLICE_YR]))   # the builder's own seam level
LAST_OBS <- max(SO$year)                           # the SST record's last year: the futures-only seam
HF_TODAY <- max(HE$year)                           # the emissions record's last year: "today" in the tables
cat(sprintf("mode file %s (md5 %s); SST record ends %d, seam (last %d yr) NH %.3f SH %.3f K\n", MODE_FILE,
            unname(tools::md5sum(MODE_FILE)), LAST_OBS, CCX_SST_SPLICE_YR, SEAM[["NH"]], SEAM[["SH"]]))

# ---- the wrapper ------------------------------------------------------------------------------------------
ORIG_SST <- ccx_sst_anom_from_gmst
use_sst_scale <- function(f, mode = c("all", "future")) {
  mode <- match.arg(mode)
  ccx_sst_anom_from_gmst <<- function(F) {
    G <- ORIG_SST(F)
    for (h in c("NH", "SH")) { col <- paste0("sst_anom_", h)
      if (mode == "all") G[[col]] <- f * G[[col]]
      else { b <- G$year > LAST_OBS; G[[col]][b] <- SEAM[[h]] + f * (G[[col]][b] - SEAM[[h]]) } }
    G }
}
reset_sst <- function() ccx_sst_anom_from_gmst <<- ORIG_SST

# ⚠ THE RUN TAKES ITS PARAMETERS FROM THE SPINUP (`spin$params`), not from `v`: v supplies only bomb_total and
# luc_scale. A changed vector needs its OWN spinup -- the first G2 passed v0 with the canonical's spinup and so
# ran the canonical (it reproduced f = 1 to the digit, which is how the gate caught it).
run_scen <- function(v, s, spliced, sp = SP, ...) {
  em <- if (!spliced) NULL else { e <- ccx_scenario_emissions(s)
    rbind(HE, e[e$year > max(HE$year), c("year", "fossil_GtC", "luc_GtC")]) }
  rr <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, HF_END), emissions = em,
                                         bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale, ...))
  yr <- floor(rr$out$t)
  co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, yr, mean)
  gm  <- if (!is.null(rr$climate$gmst)) stats::setNames(rr$climate$gmst, rr$climate$year) else rep(NA_real_, length(co2))
  list(co2 = co2, gmst = gm)
}
arm_run <- function(f, mode, s, spliced, v = V, sp = SP, ...) {
  if (is.na(f)) reset_sst() else use_sst_scale(f, mode)
  on.exit(reset_sst(), add = TRUE)
  run_scen(v, s, spliced, sp, ...)
}
at <- function(x, y) unname(x[as.character(y)])

# ---- the gates (serial, before anything is read) ------------------------------------------------------------
cat("\n=== GATES ===\n")
g_ref  <- arm_run(NA, "all", "ssp585", FALSE)
g_f1   <- arm_run(1, "all", "ssp585", FALSE)
g1a <- identical(g_ref$co2, g_f1$co2)
g1b <- abs(at(g_ref$co2, HF_END) - HF_REC[["ssp585_2300"]]) <= HF_REC_TOL
cat(sprintf("G1 f = 1 through the wrapper vs unwrapped: identical() %s; ssp585 %d %.3f vs the recorded reference %.2f -> %s\n", g1a, HF_END,
            at(g_ref$co2, HF_END), HF_REC[["ssp585_2300"]], if (g1a && g1b) "PASS" else "FAIL"))
v0 <- V; v0$p$sst_obs <- 0; v0$p$sst_scale <- 0
g_own0 <- arm_run(NA, "all", "ssp585", FALSE, v = v0, sp = dg_spinup(v0))
g_f0   <- arm_run(0, "all", "ssp585", FALSE)
g2 <- identical(g_own0$co2, g_f0$co2)
cat(sprintf("G2 f = 0 vs the model's own route (sst_obs = 0, sst_scale = 0): identical() %s (ssp585 %d %.3f vs %.3f) -> %s\n", g2, HF_END,
            at(g_f0$co2, HF_END), at(g_own0$co2, HF_END), if (g2) "PASS" else "FAIL"))
g_fut <- arm_run(0.613, "future", "ssp585", FALSE)
LAST_BOTH <- min(LAST_OBS, max(as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))$year))  # both records observed
hist_a <- as.character(1750:LAST_BOTH)
g3a <- identical(g_fut$co2[hist_a], g_ref$co2[hist_a])
cat(sprintf("G3a a futures-only arm vs f = 1 over 1750-%d (both records observed), the arms' own settings: identical() %s -> %s\n",
            LAST_BOTH, g3a, if (g3a) "PASS" else "FAIL"))
g_ref_c <- arm_run(NA, "all", "ssp585", FALSE, tol = 0, max_iter = CLIM_MAX_ITER)
g_fut_c <- arm_run(0.613, "future", "ssp585", FALSE, tol = 0, max_iter = CLIM_MAX_ITER)
hist_b <- as.character(1750:LAST_OBS)
g3b <- identical(g_fut_c$co2[hist_b], g_ref_c$co2[hist_b])
cat(sprintf("G3b the same pair, both forced to %d coupled iterations (tol 0), over 1750-%d (the SST record): identical() %s -> %s\n",
            CLIM_MAX_ITER, LAST_OBS, g3b, if (g3b) "PASS" else "FAIL"))
g3 <- g3a && g3b
if (!(g1a && g1b && g2 && g3)) stop("a gate failed; nothing is read")

# ---- the arms ---------------------------------------------------------------------------------------------
JOBS <- c(do.call(c, lapply(names(HF_ALL), function(a) lapply(names(HF_SCEN), function(s) list(arm = a, f = HF_ALL[[a]], mode = "all", s = s)))),
          do.call(c, lapply(names(HF_FUT), function(a) lapply(names(HF_SCEN), function(s) list(arm = a, f = HF_FUT[[a]], mode = "future", s = s)))))
cat(sprintf("\n=== %d runs (%d arms x %d scenarios) on %d forked workers ===\n", length(JOBS), length(HF_ALL) + length(HF_FUT),
            length(HF_SCEN), HF_WORKERS)); flush(LOGCON)
# CHECKPOINTED before any table is built (2026-10-06: the first full run lost its 64 runs to a table bug)
RES <- if (nzchar(HF_FROM)) readRDS(HF_FROM) else parallel::mclapply(JOBS, function(j) { while (sink.number() > 0L) sink()
  r <- arm_run(j$f, j$mode, j$s, HF_SCEN[[j$s]]); c(j, list(co2 = r$co2, gmst = r$gmst)) },
  mc.cores = HF_WORKERS, mc.preschedule = FALSE)
if (!nzchar(HF_FROM)) saveRDS(RES, paste0(HF_OUT, "_runs.rds"))
bad <- vapply(RES, function(o) inherits(o, "try-error") || is.null(o$co2), logical(1))
if (any(bad)) stop("a run failed: ", paste(vapply(RES[bad], function(o) as.character(o)[1], ""), collapse = " | "))

tab <- do.call(rbind, lapply(RES, function(o) data.frame(arm = o$arm, f = o$f, mode = o$mode, scenario = o$s,
  co2_today = at(o$co2, HF_TODAY), co2_2100 = at(o$co2, 2100), co2_2150 = at(o$co2, 2150), co2_2300 = at(o$co2, 2300),
  gmst_2100 = at(o$gmst, 2100), gmst_2300 = at(o$gmst, 2300))))
ref <- tab[tab$arm == "f1", ]
for (k in c("today", HF_YEARS)) {
  ck <- paste0("co2_", k); stopifnot(ck %in% names(tab))
  tab[[paste0("d_", k)]] <- tab[[ck]] - ref[[ck]][match(tab$scenario, ref$scenario)] }
tab$d_2300_since_today <- tab$d_2300 - tab$d_today
cat(sprintf("\n=== CO2 (ppm, global annual mean) at f = 1, the canonical (\"today\" = %d) ===\n", HF_TODAY))
print(format(ref[, c("scenario", "co2_today", "co2_2100", "co2_2150", "co2_2300", "gmst_2100", "gmst_2300")], digits = 5), row.names = FALSE)
cat("\n=== THE STAKE: CO2 change against f = 1 (ppm); negative = less CO2 with a weaker ocean thermal response ===\n")
for (a in c(names(HF_ALL)[-1], names(HF_FUT))) {
  x <- tab[tab$arm == a, ]
  cat(sprintf("-- %s (f = %.3f, %s)\n", a, x$f[1], if (x$mode[1] == "all") "all-time" else "futures only"))
  print(format(x[, c("scenario", "d_today", "d_2100", "d_2150", "d_2300", "d_2300_since_today")], digits = 3), row.names = FALSE)
}
sink()
saveRDS(list(table = tab, arms_all = HF_ALL, arms_future = HF_FUT, scenarios = HF_SCEN, seam = SEAM, last_obs = LAST_OBS, today = HF_TODAY,
             gates = c(G1 = g1a && g1b, G2 = g2, G3 = g3, G3a = g3a, G3b = g3b),
             provenance = list(driver = HF_DRIVER, commit = COMMIT, mode = HF_MODE, mode_file = MODE_FILE,
                               mode_md5 = unname(tools::md5sum(MODE_FILE)), rng = "none",
                               knob = "ccx_sst_anom_from_gmst() wrapped: the SST anomaly x f (all-time) or its post-record increment x f",
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(HF_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", HF_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
