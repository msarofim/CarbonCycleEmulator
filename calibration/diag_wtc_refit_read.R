#!/usr/bin/env Rscript
# =====================================================================
# diag_wtc_refit_read.R -- READING THE WTC REFIT (CHANGELOG 2026-10-12 ff; written while the wave ran, on
# diag_obj18_refit_read.R's skeleton). Label hilda_csl3v0kaidgbemwtc (the citation batch: every changed value + the two
# new fitted names bomb_share_NH U[0.77, 0.98] and seas_T_lag U[0, 6] months; ledger notes/citation_rulings_2026-10-12.md),
# seas_ml 1, hilda29e's pins (CCX_MODE_WTC_PINS = #18 pass 2's set), 31 free names; 24 starts on the Mac (wave 20261012ff),
# the incumbent hilda29e at its own model (0.90 / 2.0), the new basin the control, dispersed draws taking the two new names
# from their priors. Marcus, verbatim: "Carry module, then check (Recommended)".
#
# ⛔ THE NEW OBJECTIVE's LOGPOSTS ARE NOT COMPARABLE TO #18's. Every comparison here scores BOTH vectors on ONE objective:
#   0. Each vector reproduces its stored logpost in its OWN space (hilda29e under #18's label; the new mode under the
#      WTC label). The wave's survey, DISTINCT starts counted apart.
#   1. ON THE WTC ROWS: the new mode against REF = hilda29e's vector under the WTC label at its own model (bomb_share_NH
#      0.90, seas_T_lag 2.0) -- the incumbent START, id 1's. REF is GATED twice: its logpost against the wave's port
#      target (measured in the frozen tree) and its rows against the pricing's (diag_wtc_batch_price.R @9967a63, whose
#      total is +106.95 over hilda29e's own rows). Per row, the total, by group; and against the incumbent's own refit
#      (id 1), which shares the objective and pins, so the stored logposts compare too.
#   2. THE TWO NEW NAMES: their values, where they sit in their boxes, their spread across the wave's converged starts,
#      and -- when the promoted file carries its Hessian (recompute_hessian.R --update runs first in the chain) -- their
#      Laplace sd and their correlations with tau_ex and bomb_total: a PREVIEW of the identifiability check the ledger
#      rules for after adoption (posterior sd, correlation with tau_ex and bomb_total; a fixed proxy as the fallback).
#   3. THE PRIOR LEDGER (the same 31 names, both scored under the WTC label) and THE MOVES in hilda29e's marginal Laplace
#      sd (its 29 names; the two new names have no sd there and are shown in natural units).
#   4. THE FUTURES (br_futures(): SSP5-8.5 and vvH CO2 in 2300) at hilda29e (its own label), REF and the new mode: REF -
#      hilda29e is what the label alone does; new - REF is what the refit does. ⚠ No ridge width has been measured for
#      this objective (#18's was its own pricing's), so no move is read as a finding here.
#   5. THE LAND's NET CLIMATE EFFECT (br_net_climate()), the same three.
# The one-pass module check, the scorecard (GATE V) and the ocean-climate driver are separate; their commands are printed
# at the end. ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_wtc_refit_read.R
#   CCX_WTC_MODE=<path> and CCX_WTC_WAVE=<dir> override the promoted file and the wave (defaults: the UNIQUE matches of
#   WR_MODE_GLOB / WR_WAVE_GLOB under calibration/output/); CCX_WTC_PORT=<csv> overrides the port-target file (default:
#   the wave's port_targets_<label>.csv, which the land script copies in); CCX_WTC_TAG=<suffix> tags the outputs.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # = #18's read's (its pricing's)
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
WR_DRIVER       <- "calibration/diag_wtc_refit_read.R"
WR_INC          <- CCX_MODE_WTC_INCUMBENT                   # "hilda29e": the canonical at the ruling, a START here
WR_LABEL        <- CCX_MODE_WTC_STRUCT                      # "hilda_csl3v0kaidgbemwtc"
WR_PINS         <- CCX_MODE_WTC_PINS                        # hilda29e's: #16's ten + the module's four (#18 pass 2's)
WR_NEW_NAMES    <- names(CCX_PARAM_GATED_WTC)               # bomb_share_NH, seas_T_lag
WR_LEGACY       <- c(bomb_share_NH = FORC_BOMB_NH_SHARE, seas_T_lag = CCX_SEAS_T_LAG)   # what every older file ran
WR_ID_PARTNERS  <- c("tau_ex", "bomb_total")                # the ledger's identifiability partners for bomb_share_NH
WR_MODULE_REF   <- CCX_MODE_OBJ18P2_MODULE_FILE             # the module check's reference: the file the pins came from
WR_PRICE        <- file.path("outputs", "diagnostics", "wtc_batch_price_20261012", "price.rds")
WR_PRICE_COMMIT <- "9967a63"                                # diag_wtc_batch_price.R, CHANGELOG 10-12 (ee)
WR_NAMED        <- c(WR_NEW_NAMES, "tau_ex", "bomb_total", "luc_scale", "beta_max", "fert_k", "q10", "h_ml", "pump_grad", "kz")
WR_WAVE_GLOB    <- "multistart_20261012ff_hilda_csl3v0kaidgbemwtc_seasml1_pin_wtc_sd1.0452_prior_bomb_share_NH_seas_T_lag"
WR_MODE_GLOB    <- "refit_*_wtc_hilda_csl3v0kaidgbemwtc"
WR_BASIN_GAP    <- 0.05                                     # logpost; #18's read's O18_BASIN_GAP
WR_REPRO_TOL    <- 1e-5                                     # the objective's noise floor (objective_noise_floor_optimum_on_spike)
WR_TOP          <- 12L
WR_NET_WIN      <- c(2015L, 2024L); WR_NET_CLIM <- c(1901L, 1920L)   # GCB 2025 s. 3.7.2; TRENDY's held climate
WR_GCB_NET      <- c(mean = -0.8, sd = 0.7)                 # GtC/yr, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
WR_GROUPS       <- list(intcal = "^d14c_intcal$", bomb_c14 = "^d14c_(NH|SH)$", ice_cores = "icecore",
                        co2_levels = "^co2_level_", d13c_levels = "^d13c_level_", seasonal = "seasonal",
                        ocean = "^(ocean_grad|d14c_profile|excess_c14|hs_surf)", gcb_rows = "^gcb_")
WR_TAG <- Sys.getenv("CCX_WTC_TAG", "")
WR_OUT <- file.path("outputs", "diagnostics", sprintf("wtc_refit_read_%s%s", format(Sys.Date(), "%Y%m%d"), WR_TAG))
one_match <- function(pattern, what) { m <- Sys.glob(file.path("calibration", "output", pattern))
  if (length(m) != 1L) stop(sprintf("%s: %d matches for calibration/output/%s; exactly one is required (or set the override)",
                                    what, length(m), pattern))
  m }
WR_WAVE <- Sys.getenv("CCX_WTC_WAVE", ""); if (!nzchar(WR_WAVE)) WR_WAVE <- one_match(WR_WAVE_GLOB, "the wave")
WR_MODE <- Sys.getenv("CCX_WTC_MODE", "")
if (!nzchar(WR_MODE)) WR_MODE <- file.path(one_match(WR_MODE_GLOB, "the promoted mode"), "mode_fit_pumpN.rds")
WR_PORT <- Sys.getenv("CCX_WTC_PORT", ""); if (!nzchar(WR_PORT)) WR_PORT <- file.path(WR_WAVE, sprintf("port_targets_%s.csv", WR_LABEL))
COMMIT <- ccx_git_stamp()
dir.create(dirname(WR_OUT), recursive = TRUE, showWarnings = FALSE)
sink(paste0(WR_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  incumbent %s (%s, md5 %s)\n  WTC mode  %s (md5 %s)\n  wave      %s\n  port      %s\n  pricing   %s\n",
            WR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), WR_INC, ccx_mode_file(WR_INC),
            unname(tools::md5sum(ccx_mode_file(WR_INC))), WR_MODE, unname(tools::md5sum(WR_MODE)), WR_WAVE, WR_PORT, WR_PRICE))
if (nzchar(WR_TAG)) cat(sprintf("  ⚠ TAGGED '%s': read the provenance before quoting anything below\n", WR_TAG))

OBS <- ccx_prepare_obs()
MD_I <- readRDS(ccx_mode_file(WR_INC)); MD_N <- readRDS(WR_MODE); PX <- readRDS(WR_PRICE)
PIN_I <- ccx_mode_pins(MD_I); PIN_N <- ccx_mode_pins(MD_N)
same_pins <- function(a, b) setequal(names(a), names(b)) && isTRUE(all.equal(unname(unclass(a)[names(b)]), unname(b)))
stopifnot(identical(ccx_mode_struct(MD_I), CCX_MODE_OBJ18_STRUCT), identical(ccx_mode_struct(MD_N), WR_LABEL),
          same_pins(PIN_I, WR_PINS), same_pins(PIN_N, WR_PINS), all(WR_NEW_NAMES %in% MD_N$param_names))
if (!identical(PX$provenance$commit, WR_PRICE_COMMIT) || !identical(PX$provenance$mode, WR_INC) ||
    !identical(PX$provenance$label, WR_LABEL) || !identical(PX$provenance$held, WR_LEGACY))
  stop("the pricing rds is not diag_wtc_batch_price.R @", WR_PRICE_COMMIT, " on ", WR_INC, " under ", WR_LABEL, " at the legacy values")
PT <- utils::read.csv(WR_PORT, stringsAsFactors = FALSE)
if (!identical(PT$struct[1], WR_LABEL) || !identical(PT$pins[1], ccx_pin_label(WR_PINS)))
  stop("the port-target file ", WR_PORT, " was measured under another objective (struct '", PT$struct[1], "')")
PT_INC <- as.numeric(PT$logpost[PT$name == "incumbent"])

#' ONE mode file's vector (par_mode with pins, MIGRATED in this process -- an older file under the WTC label fills the
#' legacy values it ran, exactly as the wave's start did), scored under `label` with `pins` applied in process. `base`:
#' NULL builds the base BY HAND under `label` (make_port_targets.R's construction, so REF is the port target's point); a
#' file in its OWN space passes ccx_mode_base(md).
score_on <- function(md, label, pins, base = NULL) {
  g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- if (is.null(base)) ccx_apply_structure(ccx_default_params(), label, seas_ml = md$seas_ml,
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
group_sums <- function(d) vapply(WR_GROUPS, function(rx) sum(d[grep(rx, names(d))]), 0)
#' hilda29e as a WTC-label FILE at the legacy values (a temp copy: struct, par_mode, param_names), for the dg path
ref_file <- local({ f <- NULL; function() {
  if (is.null(f)) { md <- MD_I; md$struct <- WR_LABEL
    for (n in WR_NEW_NAMES) md$par_mode[[n]] <- WR_LEGACY[[n]]
    md$param_names <- c(md$param_names, WR_NEW_NAMES); md$hessian <- md$cov <- md$sd_unc <- NULL
    f <<- tempfile("wtc_ref_", fileext = ".rds"); saveRDS(md, f) }
  f } })

# ---- 0. reproduction and the survey ------------------------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST IN ITS OWN SPACE (tol %g); THE WAVE ===\n", WR_REPRO_TOL))
FS     <- sort(list.files(WR_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE))
starts <- lapply(FS, readRDS)
conv   <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time) && !isTRUE(s$dead), starts)
n_oot  <- sum(vapply(starts, function(s) isTRUE(s$out_of_time), TRUE))
n_dead <- sum(vapply(starts, function(s) isTRUE(s$dead), TRUE))
key    <- vapply(starts, function(s) paste(sprintf("%a", unlist(s$par_mode)), collapse = "|"), "")
sid    <- vapply(starts, function(s) as.integer(s$id), 0L)
TWIN   <- stats::setNames(sid[match(key, key)], sid)
lps    <- sort(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)
ids    <- vapply(conv, `[[`, 0L, "id")[order(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)]
CLUS   <- if (length(lps)) split(seq_along(lps), cumsum(c(TRUE, -diff(lps) > WR_BASIN_GAP))) else list()
cat(sprintf("  survey: %d start files; %d CONVERGED in time and live, %d out of time, %d dead; best %s\n", length(starts),
            length(conv), n_oot, n_dead, if (length(lps)) sprintf("%.6f (id %03d)", lps[1], ids[1]) else "none"))
dup <- TWIN[names(TWIN) != as.character(TWIN)]
cat(sprintf("  DUPLICATES (optimum bit-identical to a lower id): %s\n",
            if (length(dup)) paste(sprintf("id %s = id %d", names(dup), dup), collapse = "; ") else "none"))
if (length(CLUS)) cat(sprintf("  converged logposts in clusters split at gaps > %.2f: %s\n", WR_BASIN_GAP,
  paste(vapply(CLUS, function(k) sprintf("%.4f x%d (ids %s)", lps[k[1]], length(k), paste(sprintf("%d", ids[k]), collapse = ",")), ""),
        collapse = " | ")))
pf <- MD_N$promoted_from
if (!is.null(pf$id)) {
  cat(sprintf("  promoted: id %s at %.6f, chosen by %s%s\n", format(pf$id), MD_N$logpost, pf$chosen_by %||% "best_logpost",
              if (identical(pf$chosen_by, "id")) sprintf(" -- %.6f below the best (id %s); why: %s", pf$gap_to_best, format(pf$best_id), pf$why) else ""))
  if (!identical(pf$chosen_by, "id") && length(ids) && !identical(as.integer(pf$id), as.integer(ids[1])))
    stop("the promoted id is not the wave's best converged start, and it was not chosen by --id")
}
S1 <- Filter(function(s) identical(as.integer(s$id), 1L), starts)      # the incumbent's own refit (same objective, pins)
OWN_I <- score_on(MD_I, CCX_MODE_OBJ18_STRUCT, PIN_I, base = ccx_mode_base(MD_I))
OWN_N <- score_on(MD_N, WR_LABEL, WR_PINS, base = ccx_mode_base(MD_N))
for (r in list(list(sprintf("incumbent %s (#18)", WR_INC), OWN_I, MD_I$logpost), list("WTC mode", OWN_N, MD_N$logpost))) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-26s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows\n", r[[1]], r[[2]]$logpost, r[[3]], d,
              r[[2]]$lik, length(r[[2]]$streams)))
  if (!(abs(d) <= WR_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}
if (length(OWN_N$migrated)) stop("the WTC mode file lacks ", paste(OWN_N$migrated, collapse = ", "), ": not a file of this objective")
d_own <- max(abs(OWN_I$streams[names(PX$streams_18)] - PX$streams_18))
cat(sprintf("  %s's rows vs the pricing's streams_18: max |diff| %.1e (tol %g)\n", WR_INC, d_own, WR_REPRO_TOL))
if (d_own > WR_REPRO_TOL) stop(WR_INC, "'s own rows do not reproduce the pricing's")

# ---- 1. ON THE WTC ROWS ----------------------------------------------------------------------------------------
cat(sprintf("\n=== 1. ON THE WTC ROWS: the new mode vs REF (%s under %s at bomb_share_NH %g, seas_T_lag %g: the incumbent START) ===\n",
            WR_INC, WR_LABEL, WR_LEGACY[["bomb_share_NH"]], WR_LEGACY[["seas_T_lag"]]))
REF <- score_on(MD_I, WR_LABEL, WR_PINS)
if (!setequal(REF$migrated, WR_NEW_NAMES)) stop("REF migrated ", paste(REF$migrated, collapse = ", "), ", not exactly the two new names")
stopifnot(isTRUE(all.equal(unlist(ccx_unc_to_par(REF$u)[WR_NEW_NAMES]), WR_LEGACY, tolerance = 1e-12)))   # a logit round trip
d_pt  <- REF$logpost - PT_INC
d_prx <- max(abs(REF$streams[names(PX$streams_all)] - PX$streams_all))
cat(sprintf("  REF vs the wave's port target (incumbent %.10f): %+.1e; REF's rows vs the pricing's streams_all: max |diff| %.1e (tol %g)\n",
            PT_INC, d_pt, d_prx, WR_REPRO_TOL))
if (abs(d_pt) > WR_REPRO_TOL) stop("REF does not reproduce the wave's port target: it is not the incumbent's start point")
if (d_prx > WR_REPRO_TOL) stop("REF's rows do not reproduce the pricing's")
cat(sprintf("  the label alone at the incumbent (REF - %s's own rows): %+.4f (the pricing's ALL row: %+.4f)\n", WR_INC,
            REF$lik - OWN_I$lik, PX$table$d_loglik[PX$table$item == "ALL (sum of streams)"]))
rows <- names(REF$streams); stopifnot(setequal(rows, names(OWN_N$streams)))
T1 <- data.frame(row = rows, ref = REF$streams[rows], wtc = OWN_N$streams[rows], row.names = NULL)
T1$d <- T1$wtc - T1$ref; T1 <- T1[order(-abs(T1$d)), ]
for (i in seq_len(nrow(T1))) cat(sprintf("  %-22s REF %10.3f | WTC %+8.3f\n", T1$row[i], T1$ref[i], T1$d[i]))
D1 <- OWN_N$lik - REF$lik
G1 <- group_sums(OWN_N$streams[rows] - REF$streams[rows])
cat(sprintf("  TOTAL likelihood %+.4f (REF %.4f; WTC %.4f); stored logpost %+.4f (same objective and pins: comparable)\n",
            D1, REF$lik, OWN_N$lik, OWN_N$logpost - REF$logpost))
cat(sprintf("  by group: %s\n", paste(sprintf("%s %+.3f", names(G1), G1), collapse = ", ")))
if (length(S1)) cat(sprintf("  the incumbent's own refit (id 1, from REF): stored logpost %.6f (%s); the WTC mode %+.4f against it\n",
                            S1[[1]]$logpost, if (isTRUE(S1[[1]]$converged)) "converged" else "NOT converged",
                            MD_N$logpost - S1[[1]]$logpost))

# ---- 2. the two new names ----------------------------------------------------------------------------------
cat("\n=== 2. THE TWO NEW NAMES: values, box position, spread across the wave, identifiability PREVIEW ===\n")
LN <- ledger(OWN_N$u, OWN_N$bp)
FSN <- ccx_mode_fit_stats(MD_N)
has_h <- !is.null(FSN$cov) && identical(length(FSN$param_names), nrow(FSN$cov)) && all(WR_NEW_NAMES %in% FSN$param_names)
for (n in WR_NEW_NAMES) {
  s <- CCX_PARAM_GATED_WTC[[n]]; x <- LN[n, "value"]; frac <- (x - s$lo) / (s$hi - s$lo)
  sd_nat <- if (has_h) { i <- match(n, FSN$param_names); sqrt(FSN$cov[i, i]) * (x - s$lo) * (s$hi - x) / (s$hi - s$lo) } else NA_real_
  edge <- if (is.finite(sd_nat)) min(x - s$lo, s$hi - x) / sd_nat else NA_real_
  cat(sprintf("  %-14s %.5f (legacy %g)  box [%g, %g] at %.3f of its width%s\n", n, x, WR_LEGACY[[n]], s$lo, s$hi, frac,
              if (is.finite(sd_nat)) sprintf("; Laplace sd %.4g (natural, delta method); nearer bound %.2f sd away%s", sd_nat, edge,
                                             if (edge < 1) " -- WITHIN 1 sd OF A BOUND" else "") else "; no Hessian in the file yet"))
}
if (length(conv)) {
  VAL <- t(vapply(conv, function(s) c(id = as.integer(s$id), logpost = s$logpost, unlist(s$par_mode[WR_NEW_NAMES])), numeric(2 + length(WR_NEW_NAMES))))
  VAL <- VAL[order(-VAL[, "logpost"]), , drop = FALSE]
  for (k in seq_along(CLUS)) { m <- VAL[CLUS[[k]], , drop = FALSE]
    cat(sprintf("  cluster %d (%.4f, %d starts): %s\n", k, m[1, "logpost"], nrow(m), paste(vapply(WR_NEW_NAMES, function(n)
      sprintf("%s %.4f-%.4f", n, min(m[, n]), max(m[, n])), ""), collapse = "; "))) }
}
CORR <- NULL
if (has_h) {
  sdv <- sqrt(diag(FSN$cov)); CORR <- FSN$cov / outer(sdv, sdv); dimnames(CORR) <- list(FSN$param_names, FSN$param_names)
  for (n in WR_NEW_NAMES) {
    r <- CORR[n, setdiff(FSN$param_names, n)]; top <- r[order(-abs(r))][seq_len(min(5L, length(r)))]
    cat(sprintf("  corr(%s, .) in u: %s%s\n", n, paste(sprintf("%s %+.3f", names(top), top), collapse = ", "),
                if (n == "bomb_share_NH") sprintf("; the ledger's partners: %s", paste(sprintf("%s %+.3f", WR_ID_PARTNERS,
                                                                                               CORR[n, WR_ID_PARTNERS]), collapse = ", ")) else ""))
  }
  cat("  ⚠ A PREVIEW: the ruled identifiability check is the MCMC's posterior sd and correlations, after adoption.\n")
}

# ---- 3. the prior ledger and the moves -----------------------------------------------------------------------
cat(sprintf("\n=== 3. THE PRIOR LEDGER (the same %d free names, both under %s) and THE MOVES in %s's marginal Laplace sd ===\n",
            length(OWN_N$u), WR_LABEL, WR_INC))
LR <- ledger(REF$u, REF$bp)
if (!identical(rownames(LR), rownames(LN))) stop("the free sets differ: ", paste(setdiff(union(rownames(LR), rownames(LN)),
                                                                                   intersect(rownames(LR), rownames(LN))), collapse = ", "))
dP <- LN[, "prior"] - LR[, "prior"]; dJ <- LN[, "jac"] - LR[, "jac"]
cat(sprintf("  priors %+.4f, Jacobians %+.4f (WTC - REF); the two new names' share: priors %+.4f, Jacobians %+.4f\n",
            sum(dP), sum(dJ), sum(dP[WR_NEW_NAMES]), sum(dJ[WR_NEW_NAMES])))
FS_I <- ccx_mode_fit_stats(MD_I); sdI <- stats::setNames(as.numeric(FS_I$sd), FS_I$param_names)
Z <- (OWN_N$u - REF$u[names(OWN_N$u)]) / sdI[names(OWN_N$u)]
Zo <- Z[is.finite(Z)]; Zo <- Zo[order(-abs(Zo))]
show <- unique(c(names(Zo)[seq_len(min(WR_TOP, length(Zo)))], intersect(WR_NAMED, names(Z))))
for (n in show) cat(sprintf("  %-20s %12.5g -> %12.5g  %s\n", n, LR[n, "value"], LN[n, "value"],
                            if (is.finite(Z[[n]])) sprintf("%+6.2f sd", Z[[n]]) else "(no sd at the incumbent: a new name)"))

# ---- 4. the futures ------------------------------------------------------------------------------------------
cat(sprintf("\n=== 4. THE FUTURES: CO2 (ppm) in %d (br_futures()) ===\n", BR_FUT_YEAR))
FUT_V <- list(inc = dg_vector(ccx_mode_file(WR_INC)), ref = dg_vector(ref_file()), wtc = dg_vector(WR_MODE))
stopifnot(identical(ccx_nuc_share_of(FUT_V$ref$p), "per_year"), identical(unlist(FUT_V$ref$p[WR_NEW_NAMES]), WR_LEGACY))
FUT <- t(vapply(names(FUT_V), function(a) { v <- FUT_V[[a]]; br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
for (a in rownames(FUT)) cat(sprintf("  %-4s %s\n", a, paste(sprintf("%s %8.2f", colnames(FUT), FUT[a, ]), collapse = " | ")))
cat(sprintf("  the label alone (REF - inc): %s\n  the refit (WTC - REF):       %s\n",
            paste(sprintf("%s %+7.2f", colnames(FUT), FUT["ref", ] - FUT["inc", ]), collapse = " | "),
            paste(sprintf("%s %+7.2f", colnames(FUT), FUT["wtc", ] - FUT["ref", ]), collapse = " | ")))
cat("  ⚠ No ridge width is measured for this objective: a move here is not a finding until it is compared with one.\n")

# ---- 5. the land's net climate effect ---------------------------------------------------------------------
cat(sprintf("\n=== 5. THE LAND's NET CLIMATE EFFECT, %d-%d (TRENDY S2 - S1), GtC/yr ===\n", WR_NET_WIN[1], WR_NET_WIN[2]))
NET <- t(vapply(names(FUT_V), function(a) br_net_climate(FUT_V[[a]], WR_NET_WIN, WR_NET_CLIM), numeric(3)))
for (a in rownames(NET)) cat(sprintf("  %-4s net climate effect %+.4f, z %+.2f against GCB 2025's %+.1f +/- %.1f\n", a, NET[a, "net_climate"],
                                     (NET[a, "net_climate"] - WR_GCB_NET[["mean"]]) / WR_GCB_NET[["sd"]], WR_GCB_NET[["mean"]], WR_GCB_NET[["sd"]]))

# ---- the separate drivers ---------------------------------------------------------------------------------
cat("\n=== THE SEPARATE DRIVERS (each writes its own log) ===\n")
cat(sprintf("  THE ONE-PASS CHECK: Rscript calibration/fit_iav_module.R --base=%s --check=%s\n", WR_MODE, WR_MODULE_REF))
cat("    ⚠ The 10-12 ruling's option text says a second pass \"only if a module name moves > 0.01 sigma\"; fit_iav_module.R's\n")
cat("      IAV_CHECK_TOL is the 0.1 sigma ruled for #17 / #18. Read the z values against both; the choice is Marcus's.\n")
cat(sprintf("  CCX_SC_EXTRA_MODE=\"wtc=%s\" CCX_SC_TAG_SUFFIX=_wtc Rscript calibration/diag_whole_model_scorecard.R\n", WR_MODE))
cat(sprintf("  CCX_OC_MODE=\"wtc=%s\" Rscript calibration/diag_ocean_climate_gobm.R\n", WR_MODE))

sink()
saveRDS(list(on_wtc = T1, d_wtc = D1, groups = G1, label_alone = REF$lik - OWN_I$lik,
             vs_id1 = if (length(S1)) MD_N$logpost - S1[[1]]$logpost else NA_real_,
             new_names = LN[WR_NEW_NAMES, , drop = FALSE], corr = CORR,
             survey = list(n_starts = length(starts), n_converged = length(conv), n_out_of_time = n_oot, n_dead = n_dead,
                           logposts = lps, ids = ids, clusters = CLUS, twins = TWIN, promoted_from = pf),
             ledger_ref = LR, ledger_wtc = LN, moves = Z, futures = FUT, net_climate = NET,
             gates = list(port = d_pt, pricing_all = d_prx, pricing_own = d_own),
             provenance = list(driver = WR_DRIVER, commit = COMMIT, incumbent = WR_INC,
                               incumbent_md5 = unname(tools::md5sum(ccx_mode_file(WR_INC))), mode = WR_MODE,
                               mode_md5 = unname(tools::md5sum(WR_MODE)), wave = WR_WAVE, port = WR_PORT,
                               pricing = WR_PRICE, pricing_commit = WR_PRICE_COMMIT, label = WR_LABEL, pins = ccx_pin_label(WR_PINS),
                               legacy = WR_LEGACY, futures = sprintf("%s to %d", paste(names(BR_FUT_SPLICE), collapse = "/"), BR_FUT_YEAR),
                               tag = WR_TAG, rng = "none", date = format(Sys.time(), "%Y-%m-%d %H:%M"),
                               units = "log-density units; CO2 ppm; net climate effect GtC/yr")),
        paste0(WR_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}. ⛔ ADOPTS NOTHING.\n", WR_OUT))
