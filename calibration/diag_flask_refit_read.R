#!/usr/bin/env Rscript
# =====================================================================
# diag_flask_refit_read.R -- READING THE FLASK REFIT (refit item 5, 2026-10-23; diag_wtc_refit_read.R's skeleton). Label
# hilda_csl3v0kaidgbemwtcf (every Mauna Loa CO2 row on Scripps flask, CHANGELOG 2026-10-22 g), seas_ml 1, the canonical's
# pins (CCX_MODE_FLASK_PINS = #18 pass 2's set, the interannual module's four carried), 31 free names. A LOCAL refit from
# three starts (Marcus 2026-10-22: "Local refit from T8c's point (Recommended)", "Add it as a third (Recommended)",
# "Carry module, then check (Recommended)"): id 1 = the canonical hilda31w scored under the flask label (a START), id 6 =
# T8c's block point, id 7 = T8f's Newton point (file starts, calibration/torch/file_starts_<label>.rds).
#
# ⛔ A LOGPOST UNDER THE FLASK LABEL IS NOT COMPARABLE TO AN IN SITU ONE ON THE THREE MLO CO2 ROWS. Every comparison here
# scores BOTH vectors on ONE objective:
#   0. Each vector reproduces its stored logpost in its OWN space (hilda31w under its own label; the new mode under the
#      flask label). The wave: each start's start and final values, and THE THREE-START AGREEMENT (the spread of the
#      finals against the optimiser's own bound, and the largest coordinate disagreement in hilda31w's Laplace sd). With
#      only fixed starts, this agreement is the run's check that it reached one optimum (handoff 2026-10-23 §3).
#   1. ON THE FLASK ROWS: the new mode against REF = hilda31w's vector under the flask label (id 1's start). REF is GATED
#      twice: against the wave's port target and, row by row, against T8f's canonical rows (an independent implementation
#      of the same objective). Per row, the total, by group; the new mode against T8f's Newton point (id 7's start), and
#      against id 1's own refit.
#   2. ON THE IN SITU ROWS: the new mode under hilda31w's own label against hilda31w, i.e. what the refit costs on the
#      objective the canonical was fitted to.
#   3. THE PRIOR LEDGER (the same 31 names under the flask label) and THE MOVES in hilda31w's marginal Laplace sd.
#   4. THE FUTURES (br_futures(): SSP5-8.5 and vvH CO2 in 2300) at hilda31w and the new mode. REF's must equal
#      hilda31w's exactly: the label changes the scoring, not the model (GATED).
#   5. THE LAND's NET CLIMATE EFFECT (br_net_climate()), the same.
# The interannual module check, the scorecard (GATE V) and the ocean-climate driver are separate; their commands are
# printed at the end. ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_flask_refit_read.R
#   CCX_FLASK_MODE=<path> and CCX_FLASK_WAVE=<dir> override the promoted file and the wave (defaults: the UNIQUE matches of
#   FR_MODE_GLOB / FR_WAVE_GLOB under calibration/output/); CCX_FLASK_PORT=<csv> overrides the port-target file (default:
#   the wave's port_targets_<label>.csv, which the land script copies in); CCX_FLASK_TAG=<suffix> tags the outputs.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # = the WTC read's
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
FR_DRIVER     <- "calibration/diag_flask_refit_read.R"
FR_INC        <- CCX_MODE_FLASK_INCUMBENT                   # "hilda31w": the canonical at the ruling, a START here
FR_INC_LABEL  <- CCX_MODE_WTC_STRUCT                        # hilda31w's own label, "hilda_csl3v0kaidgbemwtc"
FR_LABEL      <- CCX_MODE_FLASK_STRUCT                      # "hilda_csl3v0kaidgbemwtcf"
FR_PINS       <- CCX_MODE_FLASK_PINS                        # the canonical's: #16's ten + the module's four
FR_T8F        <- file.path("outputs", "diagnostics", "seas8_20261021_hilda31w", "t8f_allflask_forecast_hilda31w.rds")
FR_START_IDS  <- c(canonical = 1L, t8c_block = 6L, t8f_newton = 7L)   # the ruled three starts (the driver's ids)
FR_NAMED      <- c("tau_ex", "grad_off_co2", "npp_frac_NH", "seas_T_amp_NH", "seas_lag_p_NH", "h_ml", "beta_max",
                   "q10", "luc_scale", "imb_share_land")
FR_WAVE_GLOB  <- "multistart_*_hilda_csl3v0kaidgbemwtcf_seasml1_pin_flask_sd1.0452_prior_bomb_share_NH_seas_T_lag"
FR_MODE_GLOB  <- "refit_*_flask_hilda_csl3v0kaidgbemwtcf"
FR_REPRO_TOL  <- CCX_REPRO_TOL                              # the objective's noise floor (RULED 2026-10-13 o)
FR_FUT_TOL    <- 0                                          # REF's futures vs hilda31w's: the same model, bit for bit
FR_TOP        <- 12L
FR_NET_WIN    <- c(2015L, 2024L); FR_NET_CLIM <- c(1901L, 1920L)   # GCB 2025 s. 3.7.2; TRENDY's held climate
FR_GCB_NET    <- c(mean = -0.8, sd = 0.7)                   # GtC/yr, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
FR_GROUPS     <- list(intcal = "^d14c_intcal$", bomb_c14 = "^d14c_(NH|SH)$", ice_cores = "icecore",
                      co2_levels = "^co2_level_", d13c_levels = "^d13c_level_", seasonal = "seasonal",
                      ocean = "^(ocean_grad|d14c_profile|excess_c14|hs_surf)", gcb_rows = "^gcb_")
FR_TAG <- Sys.getenv("CCX_FLASK_TAG", "")
FR_OUT <- file.path("outputs", "diagnostics", sprintf("flask_refit_read_%s%s", format(Sys.Date(), "%Y%m%d"), FR_TAG))
one_match <- function(pattern, what) { m <- Sys.glob(file.path("calibration", "output", pattern))
  if (length(m) != 1L) stop(sprintf("%s: %d matches for calibration/output/%s; exactly one is required (or set the override)",
                                    what, length(m), pattern))
  m }
FR_WAVE <- Sys.getenv("CCX_FLASK_WAVE", ""); if (!nzchar(FR_WAVE)) FR_WAVE <- one_match(FR_WAVE_GLOB, "the wave")
FR_MODE <- Sys.getenv("CCX_FLASK_MODE", "")
if (!nzchar(FR_MODE)) FR_MODE <- file.path(one_match(FR_MODE_GLOB, "the promoted mode"), "mode_fit_pumpN.rds")
FR_PORT <- Sys.getenv("CCX_FLASK_PORT", ""); if (!nzchar(FR_PORT)) FR_PORT <- file.path(FR_WAVE, sprintf("port_targets_%s.csv", FR_LABEL))
COMMIT <- ccx_git_stamp()
dir.create(dirname(FR_OUT), recursive = TRUE, showWarnings = FALSE)
sink(paste0(FR_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  incumbent %s (%s, md5 %s)\n  flask mode %s (md5 %s)\n  wave      %s\n  port      %s\n  T8f       %s\n",
            FR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), FR_INC, ccx_mode_file(FR_INC),
            unname(tools::md5sum(ccx_mode_file(FR_INC))), FR_MODE, unname(tools::md5sum(FR_MODE)), FR_WAVE, FR_PORT, FR_T8F))
if (nzchar(FR_TAG)) cat(sprintf("  ⚠ TAGGED '%s': read the provenance before quoting anything below\n", FR_TAG))

OBS <- ccx_prepare_obs()
MD_I <- readRDS(ccx_mode_file(FR_INC)); MD_N <- readRDS(FR_MODE); T8F <- readRDS(FR_T8F)
PIN_I <- ccx_mode_pins(MD_I); PIN_N <- ccx_mode_pins(MD_N)
same_pins <- function(a, b) setequal(names(a), names(b)) && isTRUE(all.equal(unname(unclass(a)[names(b)]), unname(b)))
stopifnot(identical(ccx_mode_struct(MD_I), FR_INC_LABEL), identical(ccx_mode_struct(MD_N), FR_LABEL),
          same_pins(PIN_I, FR_PINS), same_pins(PIN_N, FR_PINS), setequal(MD_I$param_names, MD_N$param_names))
if (!identical(T8F$provenance$mode_md5, unname(tools::md5sum(ccx_mode_file(FR_INC)))))
  stop("T8f was computed at another ", FR_INC, " file (md5 ", T8F$provenance$mode_md5, "): its rows are not REF's")
PT <- utils::read.csv(FR_PORT, stringsAsFactors = FALSE, colClasses = c(commit = "character", pins = "character"))
if (!identical(PT$struct[1], FR_LABEL) || !identical(PT$pins[1], ccx_pin_label(FR_PINS)))
  stop("the port-target file ", FR_PORT, " was measured under another objective (struct '", PT$struct[1], "')")
PT_INC <- as.numeric(PT$logpost[PT$name == "incumbent"])

#' ONE mode file's vector (par_mode with pins), scored under `label` with `pins` applied in process. `base`: NULL builds
#' the base BY HAND under `label` (make_port_targets.R's construction, so REF is the port target's point); a file in its
#' OWN space passes ccx_mode_base(md).
score_on <- function(md, label, pins, base = NULL) {
  g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- if (is.null(base)) ccx_apply_structure(ccx_default_params(), label, seas_ml = ccx_mode_seas_ml(md),
                                               pump_field = ccx_mode_pump_field(md)) else base
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), obs = OBS)
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  u <- ccx_par_to_unc(pm); v <- lp(u)
  list(logpost = as.numeric(v), lik = attr(v, "loglik"), streams = unlist(attr(v, "streams")), u = u, bp = bp,
       migrated = attr(pm, "migrated"))
}
# each free name's prior log-density and log-Jacobian at u (the objective's own two terms, R/calibrate.R)
ledger <- function(u, bp) { par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  t(vapply(names(u), function(n) { s <- CCX_PARAM_TABLE[[n]] %||% CCX_PARAM_GATED_ALL[[n]]
    c(value = par[[n]], prior = .ccx_prior_eval(s, par[[n]], p_pr), jac = .log_jac(u[[n]], s)) }, numeric(3))) }
group_sums <- function(d) vapply(FR_GROUPS, function(rx) sum(d[grep(rx, names(d))]), 0)
row_table <- function(a, b, la, lb) { rows <- names(a); stopifnot(setequal(rows, names(b)))
  t <- data.frame(row = rows, a = a[rows], b = b[rows], row.names = NULL); t$d <- t$b - t$a; t <- t[order(-abs(t$d)), ]
  for (i in seq_len(nrow(t))) cat(sprintf("  %-22s %s %10.3f | %s %+8.3f%s\n", t$row[i], la, t$a[i], lb, t$d[i],
                                          if (t$row[i] %in% LIK_CO2_FLASK_ROWS) "   <- a flask row" else ""))
  names(t)[2:3] <- c(la, lb); t }
#' hilda31w as a FLASK-label FILE (a temp copy: struct only; the same 31 names and values), for the dg path
ref_file <- local({ f <- NULL; function() {
  if (is.null(f)) { md <- MD_I; md$struct <- FR_LABEL; md$hessian <- md$cov <- md$sd_unc <- NULL
    f <<- tempfile("flask_ref_", fileext = ".rds"); saveRDS(md, f) }
  f } })

# ---- 0. reproduction, the wave, and the three-start agreement ------------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST IN ITS OWN SPACE (tol %g); THE WAVE ===\n", FR_REPRO_TOL))
OWN_I <- score_on(MD_I, FR_INC_LABEL, PIN_I, base = ccx_mode_base(MD_I))
OWN_N <- score_on(MD_N, FR_LABEL, FR_PINS, base = ccx_mode_base(MD_N))
for (r in list(list(sprintf("incumbent %s (in situ)", FR_INC), OWN_I, MD_I$logpost), list("flask mode", OWN_N, MD_N$logpost))) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-28s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows\n", r[[1]], r[[2]]$logpost, r[[3]], d,
              r[[2]]$lik, length(r[[2]]$streams)))
  if (!(abs(d) <= FR_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}
if (length(OWN_N$migrated)) stop("the flask mode file lacks ", paste(OWN_N$migrated, collapse = ", "), ": not a file of this objective")
FS     <- sort(list.files(FR_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE))
starts <- lapply(FS, readRDS)
sid    <- vapply(starts, function(s) as.integer(s$id), 0L)
if (!setequal(sid, FR_START_IDS))
  cat(sprintf("  ⚠ the wave's ids are %s, not the ruled three (%s)\n", paste(sid, collapse = ", "), paste(FR_START_IDS, collapse = ", ")))
for (s in starts[order(sid)])
  cat(sprintf("  id %03d %-10s start %.6f -> final %.6f (%+.4f)  %s%s, %.1f %s-min\n", s$id,
              if (identical(s$start_class, "file")) s$file_start_name else s$start_class, s$logpost_start, s$logpost,
              s$logpost - s$logpost_start, if (isTRUE(s$dead)) "DEAD" else if (isTRUE(s$converged)) "converged"
              else if (isTRUE(s$out_of_time)) "OUT OF TIME" else "restart budget spent",
              if (isTRUE(s$file_gate$checked)) sprintf(" (value gate |diff| %.1e)", s$file_gate$diff) else "",
              s$minutes, s$clock %||% "wall"))
conv <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time) && !isTRUE(s$dead), starts)
TOL  <- unique(vapply(starts, function(s) s$cycle_tol, 0)); stopifnot(length(TOL) == 1L)
FS_I <- ccx_mode_fit_stats(MD_I); sdI <- stats::setNames(as.numeric(FS_I$sd), FS_I$param_names)
AGREE <- NULL
if (length(conv) >= 2L) {
  lpc <- vapply(conv, `[[`, 0, "logpost"); idc <- vapply(conv, function(s) as.integer(s$id), 0L)
  U <- do.call(rbind, lapply(conv, function(s) s$u_mode[names(sdI)]))
  zmax <- apply(U, 2, function(x) diff(range(x))) / sdI
  AGREE <- list(ids = idc, spread = diff(range(lpc)), tol = TOL, z = zmax)
  cat(sprintf(paste0("  THE THREE-START AGREEMENT over the %d converged starts (ids %s): finals spread %.4f log-units against the ",
                     "optimiser's bound %g -> %s;\n    the largest coordinate disagreement %.3f of %s's Laplace sd (%s); next %s\n"),
              length(conv), paste(idc, collapse = ", "), AGREE$spread, TOL,
              if (AGREE$spread <= TOL) "they AGREE" else "they do NOT agree: read each before promoting one", max(zmax), FR_INC,
              names(zmax)[which.max(zmax)], paste(sprintf("%s %.3f", names(sort(-zmax))[2:4], sort(zmax, decreasing = TRUE)[2:4]), collapse = ", ")))
} else cat(sprintf("  ⚠ only %d converged start(s): no agreement to read\n", length(conv)))
pf <- MD_N$promoted_from
if (!is.null(pf$id)) cat(sprintf("  promoted: id %s at %.6f, chosen by %s\n", format(pf$id), MD_N$logpost, pf$chosen_by %||% "best_logpost"))

# ---- 1. ON THE FLASK ROWS ----------------------------------------------------------------------------------------
cat(sprintf("\n=== 1. ON THE FLASK ROWS: the new mode vs REF (%s under %s at the same pins: id 1's start) ===\n", FR_INC, FR_LABEL))
REF <- score_on(MD_I, FR_LABEL, FR_PINS)
if (length(REF$migrated)) stop("REF migrated ", paste(REF$migrated, collapse = ", "), ": hilda31w is in the flask label's space already")
t8_rows <- T8F$rows_canonical$all
if (length(setdiff(names(REF$streams), names(t8_rows)))) stop("T8f's canonical rows lack ", paste(setdiff(names(REF$streams), names(t8_rows)), collapse = ", "))
d_pt  <- REF$logpost - PT_INC
d_t8  <- max(abs(REF$streams - t8_rows[names(REF$streams)]))
cat(sprintf("  REF vs the wave's port target (incumbent %.10f): %+.1e; REF's rows vs T8f's canonical rows: max |diff| %.1e (tol %g)\n",
            PT_INC, d_pt, d_t8, FR_REPRO_TOL))
if (abs(d_pt) > FR_REPRO_TOL) stop("REF does not reproduce the wave's port target: it is not the incumbent's start point")
if (d_t8 > FR_REPRO_TOL) stop("REF's rows do not reproduce T8f's")
cat(sprintf("  the label alone at the incumbent (REF - %s's own rows): likelihood %+.4f, logpost %+.4f\n", FR_INC,
            REF$lik - OWN_I$lik, REF$logpost - OWN_I$logpost))
T1 <- row_table(REF$streams, OWN_N$streams, "REF", "flask")
D1 <- OWN_N$lik - REF$lik; G1 <- group_sums(OWN_N$streams - REF$streams[names(OWN_N$streams)])
cat(sprintf("  TOTAL likelihood %+.4f (REF %.4f; flask %.4f); stored logpost %+.4f (same objective and pins: comparable)\n",
            D1, REF$lik, OWN_N$lik, OWN_N$logpost - REF$logpost))
cat(sprintf("  by group: %s\n", paste(sprintf("%s %+.3f", names(G1), G1), collapse = ", ")))
t8n <- T8F$rows$all_at_allN; names(t8n) <- T8F$rows$row
N7 <- sum(t8n)
cat(sprintf("  against T8f's Newton point (id 7's start, %.6f; measured %+.4f over REF): the refit %+.4f beyond it, %+.4f over REF\n",
            N7, N7 - REF$logpost, MD_N$logpost - N7, MD_N$logpost - REF$logpost))
for (k in names(FR_START_IDS)) { s <- Filter(function(s) identical(as.integer(s$id), FR_START_IDS[[k]]), starts)
  if (length(s)) cat(sprintf("  the refit from id %d (%s): stored logpost %.6f (%s); the promoted mode %+.4f against it\n", FR_START_IDS[[k]], k,
                             s[[1]]$logpost, if (isTRUE(s[[1]]$converged)) "converged" else "NOT converged", MD_N$logpost - s[[1]]$logpost)) }

# ---- 2. ON THE IN SITU ROWS ----------------------------------------------------------------------------------------
cat(sprintf("\n=== 2. ON THE IN SITU ROWS: the new mode under %s (%s's own label) vs %s ===\n", FR_INC_LABEL, FR_INC, FR_INC))
INS <- score_on(MD_N, FR_INC_LABEL, FR_PINS)
T2 <- row_table(OWN_I$streams, INS$streams, "hilda31w", "flask")
D2 <- INS$lik - OWN_I$lik
cat(sprintf("  TOTAL likelihood %+.4f, logpost %+.4f: what the refit costs on the in situ objective\n", D2, INS$logpost - OWN_I$logpost))

# ---- 3. the prior ledger and the moves -----------------------------------------------------------------------
cat(sprintf("\n=== 3. THE PRIOR LEDGER (the same %d free names, both under %s) and THE MOVES in %s's marginal Laplace sd ===\n",
            length(OWN_N$u), FR_LABEL, FR_INC))
LR <- ledger(REF$u, REF$bp); LN <- ledger(OWN_N$u, OWN_N$bp)
if (!identical(rownames(LR), rownames(LN))) stop("the free sets differ")
dP <- LN[, "prior"] - LR[, "prior"]; dJ <- LN[, "jac"] - LR[, "jac"]
cat(sprintf("  priors %+.4f, Jacobians %+.4f (flask - REF)\n", sum(dP), sum(dJ)))
Z <- (OWN_N$u - REF$u[names(OWN_N$u)]) / sdI[names(OWN_N$u)]
Zo <- Z[order(-abs(Z))]
show <- unique(c(names(Zo)[seq_len(min(FR_TOP, length(Zo)))], intersect(FR_NAMED, names(Z))))
for (n in show) cat(sprintf("  %-20s %12.5g -> %12.5g  %+6.2f sd\n", n, LR[n, "value"], LN[n, "value"], Z[[n]]))

# ---- 4. the futures ------------------------------------------------------------------------------------------
cat(sprintf("\n=== 4. THE FUTURES: CO2 (ppm) in %d (br_futures()) ===\n", BR_FUT_YEAR))
FUT_V <- list(inc = dg_vector(ccx_mode_file(FR_INC)), ref = dg_vector(ref_file()), flask = dg_vector(FR_MODE))
FUT <- t(vapply(names(FUT_V), function(a) { v <- FUT_V[[a]]; br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
for (a in rownames(FUT)) cat(sprintf("  %-5s %s\n", a, paste(sprintf("%s %8.2f", colnames(FUT), FUT[a, ]), collapse = " | ")))
d_fut <- max(abs(FUT["ref", ] - FUT["inc", ]))
cat(sprintf("  REF - inc: max |diff| %.1e (tol %g: the label changes the scoring, not the model)\n  the refit (flask - inc): %s\n",
            d_fut, FR_FUT_TOL, paste(sprintf("%s %+7.2f", colnames(FUT), FUT["flask", ] - FUT["inc", ]), collapse = " | ")))
if (d_fut > FR_FUT_TOL) stop("REF's futures differ from hilda31w's: the flask label reached the model, not only the likelihood")
cat("  ⚠ No ridge width is measured for this objective: a move here is not a finding until it is compared with one.\n")

# ---- 5. the land's net climate effect ---------------------------------------------------------------------
cat(sprintf("\n=== 5. THE LAND's NET CLIMATE EFFECT, %d-%d (TRENDY S2 - S1), GtC/yr ===\n", FR_NET_WIN[1], FR_NET_WIN[2]))
NET <- t(vapply(c("inc", "flask"), function(a) br_net_climate(FUT_V[[a]], FR_NET_WIN, FR_NET_CLIM), numeric(3)))
for (a in rownames(NET)) cat(sprintf("  %-5s net climate effect %+.4f, z %+.2f against GCB 2025's %+.1f +/- %.1f\n", a, NET[a, "net_climate"],
                                     (NET[a, "net_climate"] - FR_GCB_NET[["mean"]]) / FR_GCB_NET[["sd"]], FR_GCB_NET[["mean"]], FR_GCB_NET[["sd"]]))

# ---- the separate drivers ---------------------------------------------------------------------------------
cat("\n=== THE SEPARATE DRIVERS (each writes its own log) ===\n")
cat(sprintf("  THE MODULE CHECK (RULED 0.1 sigma); the reference is Marcus's to choose (handoff 2026-10-23 §2), so both are run:\n    Rscript calibration/fit_iav_module.R --base=%s --check=%s   (hilda31w's own check)\n    Rscript calibration/fit_iav_module.R --base=%s --check=%s   (the file the pins came from)\n",
            FR_MODE, CCX_MODE_CANONICAL_MODULE_CHECK, FR_MODE, CCX_MODE_OBJ18P2_MODULE_FILE))
cat(sprintf("  CCX_SC_EXTRA_MODE=\"flask=%s\" CCX_SC_TAG_SUFFIX=_flask Rscript calibration/diag_whole_model_scorecard.R\n", FR_MODE))
cat(sprintf("  CCX_OC_MODE=\"flask=%s\" Rscript calibration/diag_ocean_climate_gobm.R\n", FR_MODE))

sink()
saveRDS(list(on_flask = T1, d_flask = D1, groups = G1, on_insitu = T2, d_insitu = D2,
             label_alone = c(lik = REF$lik - OWN_I$lik, logpost = REF$logpost - OWN_I$logpost),
             vs_newton = MD_N$logpost - N7, agreement = AGREE,
             survey = lapply(starts, function(s) s[c("id", "start_class", "logpost_start", "logpost", "converged", "out_of_time", "dead", "minutes")]),
             ledger_ref = LR, ledger_flask = LN, moves = Z, futures = FUT, net_climate = NET,
             gates = list(port = d_pt, t8f_rows = d_t8, futures_ref = d_fut),
             provenance = list(driver = FR_DRIVER, commit = COMMIT, incumbent = FR_INC,
                               incumbent_md5 = unname(tools::md5sum(ccx_mode_file(FR_INC))), mode = FR_MODE,
                               mode_md5 = unname(tools::md5sum(FR_MODE)), wave = FR_WAVE, port = FR_PORT,
                               t8f = FR_T8F, t8f_md5 = unname(tools::md5sum(FR_T8F)), label = FR_LABEL, pins = ccx_pin_label(FR_PINS),
                               futures = sprintf("%s to %d", paste(names(BR_FUT_SPLICE), collapse = "/"), BR_FUT_YEAR),
                               tag = FR_TAG, rng = "none", date = format(Sys.time(), "%Y-%m-%d %H:%M"),
                               units = "log-density units; posterior sd (hilda31w's Laplace); CO2 ppm; net climate effect GtC/yr")),
        paste0(FR_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}. ⛔ ADOPTS NOTHING.\n", FR_OUT))
