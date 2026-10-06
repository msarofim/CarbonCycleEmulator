#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_refit_read.R -- READING OBJECTIVE #17's STAGE-2 REFIT (2026-10-06 o; written while the refit ran, for
# notes/handoff_2026-10-06d_obj17_running.md §4 step 4, on the model of diag_obj16_refit_read.R).
# DRY-RUN 2026-10-06 on a SCRATCH #17 file (hilda33p with the module pinned at stage 1's values, i.e. the pricing's B1;
# an empty wave): every section ran. On #17's rows it reproduced B1 (-10.8609); on #16's rows -39.45 (the preview's
# -39.7 omitted the slope row's +0.24); the module +2.5622 = stage 1's. ⚠ The SURVEY and the promoted-id check had
# nothing to read: run it once more on the first finished REAL start before the landing (CCX_O17_MODE=<that start
# promoted to a scratch dest>, CCX_O17_TAG=_DRYRUN), as #16's was (CHANGELOG 10-05 j).
#
# THE REFIT (CHANGELOG 10-06 o): the label hilda_csl3v0kaidgbemw (the interannual cut: gcb_land_sink on its low-pass
# part, gcb_ocean_enso_slope moved to the module) with #16's ten pins + the module's four at stage 1's values
# (CCX_MODE_OBJ17_PINS). 29 free names, 24 dispersed starts on the Mac. Read against hilda33p (the canonical, #16).
#
# ⛔ THE TWO OBJECTIVES SCORE DIFFERENT ROWS (#17: the low-pass land row, no slope row) AND DIFFERENT FREE SETS (#17 pins
# four names #16 fits). So nothing here compares stored logposts; each comparison scores BOTH vectors on ONE objective:
#   0. Each vector reproduces its stored logpost in its OWN space. The wave's survey.
#   1. ON #17's ROWS: #17 against REF = hilda33p with its own module values (diag_obj17_price.R's REF), and against the
#      pricing's B1 (-10.86, unrefitted) and B2 (-10.25, five land names re-optimised).
#   2. ON #16's ROWS (the full land row and the slope row): #17's vector against hilda33p's -- the cut's price in #16's
#      own terms (the preview's raw-row land + ocean B2 was -39.2).
#   3. THE MODULE: its likelihood (ccx_iav_module_loglik) at hilda33p's module values and at #17's (stage 1's), each
#      on its own vector, against hilda33p's SSR. Stage 1 measured +2.56 at hilda33p's other names.
#   4. THE PRIOR LEDGER on the common names, and THE MOVES in hilda33p's marginal Laplace sd.
#   5. THE FUTURES (br_futures(): SSP5-8.5 and vvH in 2300) at hilda33p, at B1 (hilda33p + stage 1's module), at #17.
#   6. THE LAND's NET CLIMATE EFFECT (br_net_climate()), hilda33p and #17.
# The one-pass check (fit_iav_module.R --check), the scorecard and the ocean-climate driver are separate; their commands
# are printed at the end. ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_obj17_refit_read.R
#   CCX_O17_MODE=<path> and CCX_O17_WAVE=<dir> override the promoted file and the wave (defaults: the UNIQUE matches of
#   O17_MODE_GLOB / O17_WAVE_GLOB under calibration/output/). CCX_O17_TAG=<suffix> tags the outputs.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # the previews' futures
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
O17_DRIVER      <- "calibration/diag_obj17_refit_read.R"
O17_CANON       <- "hilda33p"
O17_LABEL_CANON <- CCX_MODE_OBJ16_STRUCT                    # "hilda_csl3v0kaidgbem"
O17_LABEL       <- CCX_MODE_OBJ17_STRUCT                    # "hilda_csl3v0kaidgbemw"
O17_PINS        <- CCX_MODE_OBJ17_PINS                      # #16's ten + the module's four
O17_MODULE      <- CCX_IAV_MODULE_NAMES
O17_STAGE1      <- CCX_MODE_OBJ17_MODULE_FILE
O17_NAMED       <- c("beta_max", "fert_k", "luc_scale", "imb_share_land", "ndep_ret", "k_w", "q10")   # always shown
O17_WAVE_GLOB   <- "multistart_20261006o_hilda_csl3v0kaidgbemw_seasml1_pin_obj17_sd1.0452"
O17_MODE_GLOB   <- "refit_*_obj17_hilda_csl3v0kaidgbemw"
O17_BASIN_GAP   <- 0.05                                     # logpost; diag_obj16_refit_read.R's O16_BASIN_GAP
O17_REPRO_TOL   <- 1e-5                                     # recompute_hessian.R's GATE 1 tolerance
O17_TOP         <- 12L
O17_NET_WIN     <- c(2015L, 2024L); O17_NET_CLIM <- c(1901L, 1920L)   # GCB 2025 s. 3.7.2; TRENDY's held climate
O17_GCB_NET     <- c(mean = -0.8, sd = 0.7)                 # GtC/yr, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
# THE PREVIEWS AND THE PRICING, with receipts (printed beside the refit, never gated)
O17_PRICE       <- c(b1 = -10.861, b2 = -10.252, b2_seasonal = -13.249)       # diag_obj17_price.R, CHANGELOG 10-06 (o)
O17_PREV_RAW_B2 <- -39.2                                    # CHANGELOG 10-06 (m): land + ocean, the land row as now
O17_PREV_FUT    <- c(ssp585 = -3.53, vvH = -1.78)           # 10-06 (o) pricing at B2
O17_STAGE1_DLL  <- 2.5622                                   # 10-06 (o): the module's gain at hilda33p's other names
O17_TAG <- Sys.getenv("CCX_O17_TAG", "")
O17_OUT <- file.path("outputs", "diagnostics", sprintf("obj17_refit_read_%s%s", format(Sys.Date(), "%Y%m%d"), O17_TAG))
one_match <- function(pattern, what) { m <- Sys.glob(file.path("calibration", "output", pattern))
  if (length(m) != 1L) stop(sprintf("%s: %d matches for calibration/output/%s; exactly one is required (or set the override)",
                                    what, length(m), pattern))
  m }
O17_WAVE <- Sys.getenv("CCX_O17_WAVE", ""); if (!nzchar(O17_WAVE)) O17_WAVE <- one_match(O17_WAVE_GLOB, "the wave")
O17_MODE <- Sys.getenv("CCX_O17_MODE", "")
if (!nzchar(O17_MODE)) O17_MODE <- file.path(one_match(O17_MODE_GLOB, "the promoted mode"), "mode_fit_pumpN.rds")
COMMIT <- ccx_git_stamp()
sink(paste0(O17_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  canonical %s (%s)\n  #17       %s (md5 %s)\n  wave      %s\n  stage 1   %s\n", O17_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), O17_CANON, ccx_mode_file(O17_CANON), O17_MODE, unname(tools::md5sum(O17_MODE)),
            O17_WAVE, O17_STAGE1))
if (nzchar(O17_TAG)) cat(sprintf("  ⚠ TAGGED '%s': read the provenance before quoting anything below\n", O17_TAG))

OBS <- ccx_prepare_obs()
MD_C <- readRDS(ccx_mode_file(O17_CANON)); MD_N <- readRDS(O17_MODE); S1 <- readRDS(O17_STAGE1)
PIN_N <- ccx_mode_pins(MD_N)
stopifnot(identical(ccx_mode_struct(MD_C), O17_LABEL_CANON), identical(ccx_mode_struct(MD_N), O17_LABEL),
          setequal(names(PIN_N), names(O17_PINS)), isTRUE(all.equal(unname(unclass(PIN_N)[names(O17_PINS)]), unname(O17_PINS))))
PINS_C <- stats::setNames(as.numeric(MD_C$pins), names(MD_C$pins))
MOD_C  <- unlist(MD_C$par_mode[O17_MODULE])               # hilda33p's own module values (FITTED there)
MOD_N  <- stats::setNames(as.numeric(unclass(PIN_N)[O17_MODULE]), O17_MODULE)   # #17's (PINNED: stage 1's)

#' ONE vector (a mode file's par_mode with pins, `over` overriding names) scored under `label` with `pins` applied in
#' process and written onto the base -- diag_obj17_price.R's score17(), generalised to either vector.
score_on <- function(md, label, pins, over = NULL) {
  g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_apply_structure(ccx_default_params(), label, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), obs = OBS)
  pm <- ccx_mode_par_with_pins(md); for (n in names(over)) pm[[n]] <- over[[n]]
  u <- ccx_par_to_unc(pm); v <- lp(u); s <- unlist(attr(v, "streams"))
  list(logpost = as.numeric(v), lik = attr(v, "loglik"), streams = s, u = u, bp = bp)
}
# each free name's prior log-density and log-Jacobian at u (the objective's own two terms, R/calibrate.R)
ledger <- function(u, bp) { par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  t(vapply(names(u), function(n) { s <- CCX_PARAM_TABLE[[n]] %||% CCX_PARAM_GATED_ALL[[n]]
    c(value = par[[n]], prior = .ccx_prior_eval(s, par[[n]], p_pr), jac = .log_jac(u[[n]], s)) }, numeric(3))) }

# ---- 0. reproduction and the survey ------------------------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST IN ITS OWN SPACE (tol %g); THE WAVE ===\n", O17_REPRO_TOL))
starts <- lapply(sort(list.files(O17_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)), readRDS)
conv   <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time), starts)
n_oot  <- sum(vapply(starts, function(s) isTRUE(s$out_of_time), TRUE))
lps    <- sort(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)
ids    <- vapply(conv, `[[`, 0L, "id")[order(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)]
CLUS   <- if (length(lps)) split(lps, cumsum(c(TRUE, -diff(lps) > O17_BASIN_GAP))) else list()
cat(sprintf("  survey: %d start files; %d CONVERGED in time, %d out of time; best %s\n", length(starts), length(conv), n_oot,
            if (length(lps)) sprintf("%.6f (id %03d)", lps[1], ids[1]) else "none"))
if (length(CLUS)) cat(sprintf("  converged logposts in clusters split at gaps > %.2f: %s\n", O17_BASIN_GAP,
                              paste(vapply(CLUS, function(x) sprintf("%.4f x%d", x[1], length(x)), ""), collapse = " | ")))
if (!is.null(MD_N$promoted_from$id)) {
  cat(sprintf("  promoted: id %s at %.6f\n", format(MD_N$promoted_from$id), MD_N$logpost))
  if (length(ids) && !identical(as.integer(MD_N$promoted_from$id), as.integer(ids[1])))
    stop("the promoted id is not the wave's best converged start")
}
OWN_C <- score_on(MD_C, O17_LABEL_CANON, PINS_C)
OWN_N <- score_on(MD_N, O17_LABEL, O17_PINS)
for (r in list(list(sprintf("canonical %s", O17_CANON), OWN_C, MD_C$logpost), list("objective #17", OWN_N, MD_N$logpost))) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-22s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows\n", r[[1]], r[[2]]$logpost, r[[3]], d,
              r[[2]]$lik, length(r[[2]]$streams)))
  if (!(abs(d) <= O17_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}

# ---- 1. ON #17's rows ----------------------------------------------------------------------------------------
cat("\n=== 1. ON #17's ROWS (the low-pass land row, no slope row): #17 vs REF = hilda33p with its own module values ===\n")
REF <- score_on(MD_C, O17_LABEL, c(PINS_C, MOD_C))
rows17 <- names(REF$streams); stopifnot(setequal(rows17, names(OWN_N$streams)))
T1 <- data.frame(row = rows17, ref = REF$streams[rows17], obj17 = OWN_N$streams[rows17], row.names = NULL)
T1$d <- T1$obj17 - T1$ref; T1 <- T1[order(-abs(T1$d)), ]
for (i in seq_len(nrow(T1))) cat(sprintf("  %-22s REF %10.3f | #17 %+8.3f\n", T1$row[i], T1$ref[i], T1$d[i]))
D17 <- OWN_N$lik - REF$lik
cat(sprintf("  TOTAL %+.4f (REF %.4f; #17 %.4f). The pricing: B1 %+.3f unrefitted, B2 %+.3f (five land names), of which the seasonal rows %+.2f\n",
            D17, REF$lik, OWN_N$lik, O17_PRICE[["b1"]], O17_PRICE[["b2"]], O17_PRICE[["b2_seasonal"]]))

# ---- 2. ON #16's rows ----------------------------------------------------------------------------------------
cat("\n=== 2. ON #16's ROWS (the full land row and the slope row): #17's vector vs hilda33p's ===\n")
ON16 <- score_on(MD_N, O17_LABEL_CANON, O17_PINS)        # #17's vector, its module pinned, scored on #16's objective
rows16 <- names(OWN_C$streams); stopifnot(setequal(rows16, names(ON16$streams)))
T2 <- data.frame(row = rows16, canonical = OWN_C$streams[rows16], obj17 = ON16$streams[rows16], row.names = NULL)
T2$d <- T2$obj17 - T2$canonical; T2 <- T2[order(-abs(T2$d)), ]
for (i in seq_len(min(O17_TOP, nrow(T2)))) cat(sprintf("  %-22s canonical %10.3f | #17 %+8.3f\n", T2$row[i], T2$canonical[i], T2$d[i]))
D16 <- ON16$lik - OWN_C$lik
cat(sprintf("  TOTAL %+.4f on #16's %d rows (the preview's raw-row land + ocean B2: %+.1f)\n", D16, length(rows16), O17_PREV_RAW_B2))

# ---- 3. the module ------------------------------------------------------------------------------------------
cat("\n=== 3. THE MODULE's likelihood (the detrended monthly growth + the slope row), each on its own vector ===\n")
V_C <- dg_vector(O17_CANON); V_N <- dg_vector(O17_MODE)
R_C <- dg_run(V_C); R_N <- dg_run(V_N)
gpc <- ccx_iav_growth_pair(R_C$out, R_C$F); SSR_C <- sum((gpc$mod - gpc$obs)^2)
ML_C <- ccx_iav_module_loglik(R_C$out, R_C$F, OBS, ssr_ref = SSR_C)
ML_N <- ccx_iav_module_loglik(R_N$out, R_N$F, OBS, ssr_ref = SSR_C)
cat(sprintf("  hilda33p: SSR %.4f, slope row %+.4f, growth r %.4f\n  #17:      SSR %.4f, slope row %+.4f, growth r %.4f -> module %+.4f (stage 1 at hilda33p's other names: %+.4f)\n",
            ML_C[["ssr"]], ML_C[["slope_row"]], ML_C[["r"]], ML_N[["ssr"]], ML_N[["slope_row"]], ML_N[["r"]],
            ML_N[["loglik"]] - ML_C[["loglik"]], O17_STAGE1_DLL))

# ---- 4. the prior ledger and the moves -----------------------------------------------------------------------
cat("\n=== 4. THE PRIOR LEDGER (common names) and THE MOVES in hilda33p's marginal Laplace sd ===\n")
LC <- ledger(OWN_C$u, OWN_C$bp); LN <- ledger(OWN_N$u, OWN_N$bp)
common <- intersect(rownames(LC), rownames(LN))
if (!setequal(setdiff(rownames(LC), common), O17_MODULE) || length(setdiff(rownames(LN), common)))
  stop("the free sets differ by more than the module's names: ", paste(setdiff(union(rownames(LC), rownames(LN)), common), collapse = ", "))
dP <- LN[common, "prior"] - LC[common, "prior"]; dJ <- LN[common, "jac"] - LC[common, "jac"]
MODULE_TERM <- sum(LC[O17_MODULE, "prior"] + LC[O17_MODULE, "jac"])
cat(sprintf("  the common names' priors %+.4f, Jacobians %+.4f; the module's own terms at hilda33p (absent under #17) %.4f\n",
            sum(dP), sum(dJ), MODULE_TERM))
FS_C <- ccx_mode_fit_stats(MD_C); sdC <- stats::setNames(as.numeric(FS_C$sd), FS_C$param_names)
Z <- (OWN_N$u[common] - OWN_C$u[common]) / sdC[common]; Z <- Z[order(-abs(Z))]
show <- unique(c(names(Z)[seq_len(min(O17_TOP, length(Z)))], intersect(O17_NAMED, names(Z))))
for (n in show) cat(sprintf("  %-20s %12.5g -> %12.5g  %+6.2f sd\n", n, LC[n, "value"], LN[n, "value"], Z[[n]]))
# the module's names are PINNED under #17: their move is stage 1's, in STAGE 1's own Laplace sd (natural units, the
# four pinned names: S1$laplace$cov4), not in hilda33p's u-space sd
SD4 <- sqrt(diag(S1$laplace$cov4))[O17_MODULE]
for (n in O17_MODULE) cat(sprintf("  %-20s %12.5g -> %12.5g  (PINNED at stage 1's; %+6.2f of stage 1's own sd %.4g)\n", n, MOD_C[[n]],
                                  MOD_N[[n]], (MOD_N[[n]] - MOD_C[[n]]) / SD4[[n]], SD4[[n]]))

# ---- 5. the futures --------------------------------------------------------------------------------------------
cat(sprintf("\n=== 5. THE FUTURES: CO2 (ppm) in %d (br_futures()) ===\n", BR_FUT_YEAR))
with_p <- function(v, kv) { for (n in names(kv)) { v$p[[n]] <- kv[[n]]; if (n %in% names(v$pm)) v$pm[[n]] <- kv[[n]] }
  v$p <- ccx_set_enso(v$p, v$pm); v }
FUT_V <- list(canonical = V_C, b1 = with_p(V_C, as.list(MOD_N)), obj17 = V_N)
FUT <- t(vapply(names(FUT_V), function(a) { v <- FUT_V[[a]]; br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
for (a in rownames(FUT)) cat(sprintf("  %-10s %s\n", a, paste(sprintf("%s %8.2f (%+7.2f)", colnames(FUT), FUT[a, ], FUT[a, ] - FUT["canonical", ]), collapse = " | ")))
cat(sprintf("  the pricing at B2: ssp585 %+.2f, vvH %+.2f\n", O17_PREV_FUT[["ssp585"]], O17_PREV_FUT[["vvH"]]))

# ---- 6. the land's net climate effect ---------------------------------------------------------------------
cat(sprintf("\n=== 6. THE LAND's NET CLIMATE EFFECT, %d-%d (TRENDY S2 - S1), GtC/yr ===\n", O17_NET_WIN[1], O17_NET_WIN[2]))
NET <- t(vapply(c("canonical", "obj17"), function(a) br_net_climate(FUT_V[[a]], O17_NET_WIN, O17_NET_CLIM), numeric(3)))
for (a in rownames(NET)) cat(sprintf("  %-10s net climate effect %+.4f, z %+.2f against GCB 2025's %+.1f +/- %.1f\n", a, NET[a, "net_climate"],
                                     (NET[a, "net_climate"] - O17_GCB_NET[["mean"]]) / O17_GCB_NET[["sd"]], O17_GCB_NET[["mean"]], O17_GCB_NET[["sd"]]))

# ---- the separate drivers ---------------------------------------------------------------------------------
cat("\n=== THE SEPARATE DRIVERS (run from a frozen copy; each writes its own log) ===\n")
cat(sprintf("  THE ONE-PASS CHECK (RULED): Rscript calibration/fit_iav_module.R --base=%s --check=%s\n", O17_MODE, O17_STAGE1))
cat(sprintf("  CCX_OC_MODE=\"obj17=%s\" Rscript calibration/diag_ocean_climate_gobm.R\n", O17_MODE))
cat(sprintf("  CCX_SC_EXTRA_MODE=\"obj17=%s\" CCX_SC_TAG_SUFFIX=_obj17 Rscript calibration/diag_whole_model_scorecard.R\n", O17_MODE))

sink()
saveRDS(list(on17 = T1, d17 = D17, on16 = T2, d16 = D16, module = rbind(canonical = ML_C, obj17 = ML_N),
             survey = list(n_starts = length(starts), n_converged = length(conv), n_out_of_time = n_oot, logposts = lps, ids = ids,
                           clusters = CLUS),
             ledger_canonical = LC, ledger_obj17 = LN, module_term = MODULE_TERM, moves = Z, futures = FUT, net_climate = NET,
             provenance = sprintf("%s @%s; canonical %s (%s); #17 %s (md5 %s); wave %s; stage 1 %s; futures %s to %d; tag '%s'; no RNG; %s",
                                  O17_DRIVER, COMMIT, O17_CANON, ccx_mode_file(O17_CANON), O17_MODE, unname(tools::md5sum(O17_MODE)),
                                  O17_WAVE, O17_STAGE1, paste(names(BR_FUT_SPLICE), collapse = "+"), BR_FUT_YEAR, O17_TAG,
                                  format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(O17_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", O17_OUT))
