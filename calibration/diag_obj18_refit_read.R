#!/usr/bin/env Rscript
# =====================================================================
# diag_obj18_refit_read.R -- READING OBJECTIVE #18's STAGE-2 REFIT (handoff notes/handoff_2026-10-07d_obj18_stage2_running.md
# s. 3.3; written 2026-10-07 while the refit ran, on diag_obj17_refit_read.R). DRY-RUN on the wave's first finished start
# (CCX_O18_TAG=_DRYRUN) before the landing.
#
# THE REFIT (CHANGELOG 2026-10-07 h/i): the label hilda_csl3v0kaidgbemwt (#17 + the DETRENDED ENSO index + gcb_ocean_sink
# on its LOW-PASS part) with #16's ten pins + the module's four at stage 1's values under #18 at basin B
# (CCX_MODE_OBJ18_PINS). 29 free names, 24 dispersed starts on the Mac, seeded at hilda29w (= #17's basin B, the
# incumbent and stage 1's base). Read against hilda29w and the pricing (diag_obj18_price.R @570d194).
#
# ⛔ #17 AND #18 SCORE DIFFERENT ROWS (#18: the detrended index, the low-pass ocean row) WITH THE SAME 29 FREE NAMES BUT
# DIFFERENT MODULE PINS (#17's stage 1 = P0 vs #18's = S18). So nothing compares stored logposts ACROSS objectives; each
# comparison scores both vectors on ONE objective:
#   0. Each vector reproduces its stored logpost in its OWN space. The wave's survey, DISTINCT starts counted apart
#      (under the cut's pins ids 3 / 4 / 5 re-run 1 / 2 / 2 bit for bit: [[pinned_name_seed_vanishes]], RULED 10-07 k).
#   1. ON #18's ROWS: #18 against REF (= the pricing's REF: hilda29w's vector under #18 minus the index, the module at
#      P0), beside the pricing's cells (B1 / B1s unrefitted, B2 / B2s five land names re-fitted, B2f / B2fs beta_max
#      held), and against B1s (the stage-2 SEED: same objective, same pins, so the stored logposts compare too). Does
#      the full refit recover the ICE CORES (the pricing's B2 paid -7.7 there)?
#   2. ON #17's ROWS: #18's vector against hilda29w's -- the redesign's cost in #17's own terms; and #18's free names
#      with #17's module values (P0), which separates the module's move.
#   3. THE MODULE (ccx_iav_module_loglik, on stage 1's own ssr_ref): at stage 1's point (hilda29w's vector, S18, under
#      #18; it must reproduce stage 1's optimum) and at #18's vector. Stage 2 has no slope row: did it move what the
#      slope depends on (under #17 it fell +2.79 -> +1.85 at B)?
#   4. THE PRIOR LEDGER (the same 29 names) and THE MOVES in hilda29w's marginal Laplace sd; the module's P0 -> S18 move
#      in stage 1's own sd.
#   5. THE FUTURES (br_futures(): SSP5-8.5 and vvH CO2 in 2300) at hilda33p, hilda29w, B1s and #18, READ AGAINST THE
#      RIDGE: the pricing's measured natural-space 1-sigma width along beta_max / fert_k (~+/-35 ppm); a move inside it
#      is not a finding ([[block_refit_futures_can_be_ridge_position]]).
#   6. THE LAND's NET CLIMATE EFFECT (br_net_climate()), hilda33p, hilda29w and #18.
# The one-pass check (fit_iav_module.R --check), the scorecard (GATE V) and the ocean-climate driver are separate; their
# commands are printed at the end. ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_obj18_refit_read.R
#   CCX_O18_MODE=<path> and CCX_O18_WAVE=<dir> override the promoted file and the wave (defaults: the UNIQUE matches of
#   O18_MODE_GLOB / O18_WAVE_GLOB under calibration/output/). CCX_O18_TAG=<suffix> tags the outputs.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # = the pricing's
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
O18_DRIVER      <- "calibration/diag_obj18_refit_read.R"
O18_INC         <- CCX_MODE_OBJ18_INCUMBENT                 # "hilda29w": #17's basin B, stage 1's base, the seed
O18_INC_MD5     <- "081eb16f4fe718692004fb1cf9645891"       # the file the pricing, the tests and stage 1 name
O18_CANON       <- "hilda33p"                               # the canonical (#16): the futures' outside reference
O18_LABEL_17    <- CCX_MODE_OBJ17_STRUCT                    # "hilda_csl3v0kaidgbemw"
O18_LABEL       <- CCX_MODE_OBJ18_STRUCT                    # "hilda_csl3v0kaidgbemwt"
O18_PINS        <- CCX_MODE_OBJ18_PINS                      # #16's ten + stage 1's four under #18 at basin B
O18_MODULE      <- CCX_IAV_MODULE_NAMES
O18_STAGE1      <- CCX_MODE_OBJ18_MODULE_FILE
O18_PRICE       <- file.path("outputs", "diagnostics", "obj18_price_20261007.rds")
O18_PRICE_COMMIT <- "570d194"                               # diag_obj18_price.R, CHANGELOG 10-07 (h)
O18_NAMED       <- c("beta_max", "fert_k", "luc_scale", "imb_share_land", "ndep_ret", "k_w", "q10", "h_ml", "pump_grad")
O18_WAVE_GLOB   <- "multistart_20261007i_hilda_csl3v0kaidgbemwt_seasml1_pin_obj18_sd1.0452"
O18_MODE_GLOB   <- "refit_*_obj18_hilda_csl3v0kaidgbemwt"
O18_BASIN_GAP   <- 0.05                                     # logpost; diag_obj17_refit_read.R's O17_BASIN_GAP
O18_REPRO_TOL   <- 1e-5                                     # the objective's noise floor (objective_noise_floor_optimum_on_spike)
O18_FUT_TOL     <- 1e-6                                     # ppm: a bit-identical vector's futures (the pricing's)
O18_TOP         <- 12L
O18_NET_WIN     <- c(2015L, 2024L); O18_NET_CLIM <- c(1901L, 1920L)   # GCB 2025 s. 3.7.2; TRENDY's held climate
O18_GCB_NET     <- c(mean = -0.8, sd = 0.7)                 # GtC/yr, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
O18_GROUPS      <- list(ice_cores = "icecore", co2_levels = "^co2_level_", seasonal = "seasonal",
                        gcb_rows = "^gcb_(ocean|land)_sink$")
O18_TAG <- Sys.getenv("CCX_O18_TAG", "")
O18_OUT <- file.path("outputs", "diagnostics", sprintf("obj18_refit_read_%s%s", format(Sys.Date(), "%Y%m%d"), O18_TAG))
one_match <- function(pattern, what) { m <- Sys.glob(file.path("calibration", "output", pattern))
  if (length(m) != 1L) stop(sprintf("%s: %d matches for calibration/output/%s; exactly one is required (or set the override)",
                                    what, length(m), pattern))
  m }
O18_WAVE <- Sys.getenv("CCX_O18_WAVE", ""); if (!nzchar(O18_WAVE)) O18_WAVE <- one_match(O18_WAVE_GLOB, "the wave")
O18_MODE <- Sys.getenv("CCX_O18_MODE", "")
if (!nzchar(O18_MODE)) O18_MODE <- file.path(one_match(O18_MODE_GLOB, "the promoted mode"), "mode_fit_pumpN.rds")
COMMIT <- ccx_git_stamp()
sink(paste0(O18_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  incumbent %s (%s)\n  #18       %s (md5 %s)\n  wave      %s\n  stage 1   %s\n  pricing   %s\n", O18_DRIVER,
            COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), O18_INC, ccx_mode_file(O18_INC), O18_MODE, unname(tools::md5sum(O18_MODE)),
            O18_WAVE, O18_STAGE1, O18_PRICE))
if (nzchar(O18_TAG)) cat(sprintf("  ⚠ TAGGED '%s': read the provenance before quoting anything below\n", O18_TAG))

OBS <- ccx_prepare_obs(); GRO <- ccx_iav_growth_obs()
if (!identical(unname(tools::md5sum(ccx_mode_file(O18_INC))), O18_INC_MD5)) stop(O18_INC, "'s file is not the one the pricing read")
MD_B <- readRDS(ccx_mode_file(O18_INC)); MD_N <- readRDS(O18_MODE); S1 <- readRDS(O18_STAGE1); PX <- readRDS(O18_PRICE)
PIN_N <- ccx_mode_pins(MD_N)
stopifnot(identical(ccx_mode_struct(MD_B), O18_LABEL_17), identical(ccx_mode_struct(MD_N), O18_LABEL),
          setequal(names(PIN_N), names(O18_PINS)), isTRUE(all.equal(unname(unclass(PIN_N)[names(O18_PINS)]), unname(O18_PINS))))
if (!identical(PX$provenance$commit, O18_PRICE_COMMIT) || isTRUE(PX$provenance$smoke) || !identical(PX$provenance$mode_b_md5, O18_INC_MD5) ||
    !identical(PX$provenance$stage1_md5, unname(tools::md5sum(O18_STAGE1))))
  stop("the pricing rds is not the non-smoke run @", O18_PRICE_COMMIT, " on ", O18_INC, " and this stage-1 file")
PINS_B  <- stats::setNames(as.numeric(unclass(ccx_mode_pins(MD_B))), names(MD_B$pins))
MOD_P0  <- PINS_B[O18_MODULE]                                    # hilda29w's own module values: #17's stage 1
MOD_S18 <- stats::setNames(as.numeric(unclass(PIN_N)[O18_MODULE]), O18_MODULE)   # #18's: stage 1 under #18 at B
stopifnot(identical(MOD_S18, S1$pins[O18_MODULE]), identical(unname(MOD_P0), unname(PX$pins$mod_p0[O18_MODULE])))
TEN <- PINS_B[setdiff(names(PINS_B), O18_MODULE)]

#' ONE vector (a mode file's par_mode with pins, `over` overriding names) scored under `label` with `pins` applied in
#' process and written onto the base (diag_obj17_refit_read.R's score_on()). `base`: NULL builds it BY HAND under
#' `label`, deliberately, to score a vector under ANOTHER objective; a file in its OWN space passes ccx_mode_base(md).
#' `strip` removes structure fields from a hand-built base (REF: #18 minus the index).
score_on <- function(md, label, pins, over = NULL, base = NULL, strip = NULL) {
  g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- if (is.null(base)) ccx_apply_structure(ccx_default_params(), label, seas_ml = md$seas_ml,
                                               pump_field = ccx_mode_pump_field(md)) else base
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  for (n in strip) bp[[n]] <- NULL
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
group_sums <- function(d) vapply(O18_GROUPS, function(rx) sum(d[grep(rx, names(d))]), 0)
#' hilda29w's dg vector rebuilt under `label` (the file's own vector and pins, dg_vector()'s resolver) with `vals`
#' overriding names: diag_obj18_price.R's vec_under(), line for line, so its futures can be gated against the pricing's.
vec_under <- function(label, vals = NULL) {
  V <- dg_vector(ccx_mode_file(O18_INC))
  if (!identical(label, ccx_mode_struct(MD_B))) {
    md_l <- MD_B; md_l$struct <- label
    p_l <- ccx_overlay_par(ccx_mode_base(md_l), V$pm); p_l$pump_mode <- MD_B$pump_mode
    moved <- Filter(function(n) !identical(p_l[[n]], V$p[[n]]), union(names(p_l), names(V$p)))
    added <- setdiff(names(ccx_struct_block(label)), names(ccx_struct_block(ccx_mode_struct(MD_B))))
    if (!setequal(moved, added)) stop("vec_under(): the rebuilt list moved ", paste(moved, collapse = ", "))
    V$p <- p_l
  }
  for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V$luc_scale <- V$pm$luc_scale; V
}

# ---- 0. reproduction and the survey ------------------------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST IN ITS OWN SPACE (tol %g); THE WAVE ===\n", O18_REPRO_TOL))
FS     <- sort(list.files(O18_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE))
starts <- lapply(FS, readRDS)
conv   <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time) && !isTRUE(s$dead), starts)
n_oot  <- sum(vapply(starts, function(s) isTRUE(s$out_of_time), TRUE))
n_dead <- sum(vapply(starts, function(s) isTRUE(s$dead), TRUE))
key    <- vapply(starts, function(s) paste(sprintf("%a", unlist(s$par_mode)), collapse = "|"), "")
sid    <- vapply(starts, function(s) as.integer(s$id), 0L)
TWIN   <- stats::setNames(sid[match(key, key)], sid)             # each start's first bit-identical twin (itself if none)
lps    <- sort(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)
ids    <- vapply(conv, `[[`, 0L, "id")[order(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)]
CLUS   <- if (length(lps)) split(seq_along(lps), cumsum(c(TRUE, -diff(lps) > O18_BASIN_GAP))) else list()
cat(sprintf("  survey: %d start files; %d CONVERGED in time and live, %d out of time, %d dead; best %s\n", length(starts),
            length(conv), n_oot, n_dead, if (length(lps)) sprintf("%.6f (id %03d)", lps[1], ids[1]) else "none"))
dup <- TWIN[names(TWIN) != as.character(TWIN)]
cat(sprintf("  DUPLICATES (optimum bit-identical to a lower id): %s\n",
            if (length(dup)) paste(sprintf("id %s = id %d", names(dup), dup), collapse = "; ") else "none"))
if (length(CLUS)) cat(sprintf("  converged logposts in clusters split at gaps > %.2f: %s\n", O18_BASIN_GAP,
  paste(vapply(CLUS, function(k) sprintf("%.4f x%d (%d distinct)", lps[k[1]], length(k), length(unique(TWIN[as.character(ids[k])]))), ""),
        collapse = " | ")))
pf <- MD_N$promoted_from
if (!is.null(pf$id)) {
  cat(sprintf("  promoted: id %s at %.6f, chosen by %s%s\n", format(pf$id), MD_N$logpost, pf$chosen_by %||% "best_logpost (pre-10-07 k file)",
              if (identical(pf$chosen_by, "id")) sprintf(" -- %.6f below the best (id %s); why: %s", pf$gap_to_best, format(pf$best_id), pf$why) else ""))
  if (!identical(pf$chosen_by, "id") && length(ids) && !identical(as.integer(pf$id), as.integer(ids[1])))
    stop("the promoted id is not the wave's best converged start, and it was not chosen by --id")
}
OWN_B <- score_on(MD_B, O18_LABEL_17, PINS_B, base = ccx_mode_base(MD_B))
OWN_N <- score_on(MD_N, O18_LABEL, O18_PINS, base = ccx_mode_base(MD_N))
for (r in list(list(sprintf("incumbent %s", O18_INC), OWN_B, MD_B$logpost), list("objective #18", OWN_N, MD_N$logpost))) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-22s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows\n", r[[1]], r[[2]]$logpost, r[[3]], d,
              r[[2]]$lik, length(r[[2]]$streams)))
  if (!(abs(d) <= O18_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}

# ---- 1. ON #18's rows ----------------------------------------------------------------------------------------
cat("\n=== 1. ON #18's ROWS (the detrended index, the low-pass ocean row): #18 vs REF and the pricing's cells ===\n")
REF <- score_on(MD_B, O18_LABEL, c(TEN, MOD_P0), strip = "enso_index")
d_ref <- c(logpost = REF$logpost - PX$ref$logpost, rows = max(abs(REF$streams[names(PX$ref$streams)] - PX$ref$streams)))
cat(sprintf("  REF (%s's vector under #18 minus the index, module at P0) vs the pricing's: logpost %+.1e, rows max |diff| %.1e (tol %g)\n",
            O18_INC, d_ref[["logpost"]], d_ref[["rows"]], O18_REPRO_TOL))
if (any(abs(d_ref) > O18_REPRO_TOL)) stop("REF does not reproduce the pricing's REF")
B1S <- score_on(MD_B, O18_LABEL, c(TEN, MOD_S18))                # the stage-2 SEED (the incumbent at #18's pins)
if (abs(B1S$logpost - PX$b1s$logpost) > O18_REPRO_TOL) stop("B1s does not reproduce the pricing's B1s")
rows18 <- names(REF$streams); stopifnot(setequal(rows18, names(OWN_N$streams)))
T1 <- data.frame(row = rows18, ref = REF$streams[rows18], obj18 = OWN_N$streams[rows18], row.names = NULL)
T1$d <- T1$obj18 - T1$ref; T1 <- T1[order(-abs(T1$d)), ]
for (i in seq_len(nrow(T1))) cat(sprintf("  %-22s REF %10.3f | #18 %+8.3f\n", T1$row[i], T1$ref[i], T1$d[i]))
D18 <- OWN_N$lik - REF$lik
CELLS <- c(B1 = PX$b1$lik, B1s = PX$b1s$lik, vapply(PX$refits, function(o) o$at$lik, 0)) - PX$ref$lik
cat(sprintf("  TOTAL %+.4f (REF %.4f; #18 %.4f). The pricing against the same REF: %s\n", D18, REF$lik, OWN_N$lik,
            paste(sprintf("%s %+.3f", names(CELLS), CELLS), collapse = ", ")))
G18 <- group_sums(OWN_N$streams[rows18] - REF$streams[rows18])
G2s <- group_sums(PX$refits$B2s$at$streams[rows18] - REF$streams[rows18])
cat(sprintf("  by group, #18 vs REF (the pricing's B2s, five land names re-fitted at #18's pins): %s\n",
            paste(sprintf("%s %+.3f (%+.3f)", names(G18), G18, G2s), collapse = ", ")))
cat(sprintf("  against its SEED B1s (%s at #18's pins: the same objective and pins): likelihood %+.4f, stored logpost %+.4f\n",
            O18_INC, OWN_N$lik - B1S$lik, OWN_N$logpost - B1S$logpost))

# ---- 2. ON #17's rows ----------------------------------------------------------------------------------------
cat(sprintf("\n=== 2. ON #17's ROWS (the shipped index, the year-by-year ocean row): #18's vector vs %s's ===\n", O18_INC))
ON17   <- score_on(MD_N, O18_LABEL_17, O18_PINS)                  # #18's vector, its module at S18, on #17's objective
ON17P0 <- score_on(MD_N, O18_LABEL_17, c(TEN, MOD_P0))            # ... with #17's module values (P0)
rows17 <- names(OWN_B$streams); stopifnot(setequal(rows17, names(ON17$streams)))
T2 <- data.frame(row = rows17, inc = OWN_B$streams[rows17], obj18 = ON17$streams[rows17], row.names = NULL)
T2$d <- T2$obj18 - T2$inc; T2 <- T2[order(-abs(T2$d)), ]
for (i in seq_len(min(O18_TOP, nrow(T2)))) cat(sprintf("  %-22s %s %10.3f | #18 %+8.3f\n", T2$row[i], O18_INC, T2$inc[i], T2$d[i]))
D17 <- ON17$lik - OWN_B$lik; D17P0 <- ON17P0$lik - OWN_B$lik
cat(sprintf("  TOTAL %+.4f on #17's %d rows (#18's free names with #17's module values P0: %+.4f, so the module's move P0 -> S18 there %+.4f)\n",
            D17, length(rows17), D17P0, D17 - D17P0))

# ---- 3. the module ------------------------------------------------------------------------------------------
cat("\n=== 3. THE MODULE's likelihood (the detrended monthly growth + the slope row) on stage 1's own ssr_ref ===\n")
mod_ll <- function(V) { r <- dg_run(V); ccx_iav_module_loglik(r$out, r$F, OBS, ssr_ref = S1$ssr_ref, obs_g = GRO$monthly) }
V_S1 <- vec_under(O18_LABEL, MOD_S18)                             # stage 1's point: hilda29w's vector, S18, under #18
V_N  <- dg_vector(O18_MODE)
for (k in list(list("stage 1's point", V_S1), list("#18", V_N)))
  if (!identical(ccx_enso_index_of(dg_spinup(k[[2]])$params), "detrend")) stop(k[[1]], ": the vector does not carry the detrended index")
ML_S1 <- mod_ll(V_S1); ML_N <- mod_ll(V_N)
d_s1 <- ML_S1[["loglik"]] - S1$loglik["optimum", "loglik"]
cat(sprintf("  stage 1's point reproduces stage 1's optimum: module loglik diff %+.1e (tol %g)\n", d_s1, O18_REPRO_TOL))
if (abs(d_s1) > O18_REPRO_TOL) stop("the module at stage 1's point does not reproduce stage 1's optimum")
cat(sprintf("  stage 1's point: SSR %.4f, slope row %+.4f, growth r %.4f\n  #18:            SSR %.4f, slope row %+.4f, growth r %.4f -> module %+.4f against stage 1's optimum\n",
            ML_S1[["ssr"]], ML_S1[["slope_row"]], ML_S1[["r"]], ML_N[["ssr"]], ML_N[["slope_row"]], ML_N[["r"]],
            ML_N[["loglik"]] - ML_S1[["loglik"]]))

# ---- 4. the prior ledger and the moves -----------------------------------------------------------------------
cat(sprintf("\n=== 4. THE PRIOR LEDGER (the same %d free names) and THE MOVES in %s's marginal Laplace sd ===\n", length(OWN_N$u), O18_INC))
LB <- ledger(OWN_B$u, OWN_B$bp); LN <- ledger(OWN_N$u, OWN_N$bp)
if (!identical(rownames(LB), rownames(LN))) stop("the free sets differ: ", paste(setdiff(union(rownames(LB), rownames(LN)),
                                                                                   intersect(rownames(LB), rownames(LN))), collapse = ", "))
dP <- LN[, "prior"] - LB[, "prior"]; dJ <- LN[, "jac"] - LB[, "jac"]
cat(sprintf("  priors %+.4f, Jacobians %+.4f (#18 - %s)\n", sum(dP), sum(dJ), O18_INC))
FS_B <- ccx_mode_fit_stats(MD_B); sdB <- stats::setNames(as.numeric(FS_B$sd), FS_B$param_names)
Z <- (OWN_N$u - OWN_B$u[names(OWN_N$u)]) / sdB[names(OWN_N$u)]; Z <- Z[order(-abs(Z))]
show <- unique(c(names(Z)[seq_len(min(O18_TOP, length(Z)))], intersect(O18_NAMED, names(Z))))
for (n in show) cat(sprintf("  %-20s %12.5g -> %12.5g  %+6.2f sd\n", n, LB[n, "value"], LN[n, "value"], Z[[n]]))
SD4 <- sqrt(diag(S1$laplace$cov4))[O18_MODULE]
for (n in O18_MODULE) cat(sprintf("  %-20s %12.5g -> %12.5g  (PINNED: P0 -> S18, %+6.2f of stage 1's own sd %.4g)\n", n, MOD_P0[[n]],
                                  MOD_S18[[n]], (MOD_S18[[n]] - MOD_P0[[n]]) / SD4[[n]], SD4[[n]]))

# ---- 5. the futures, read against the ridge ------------------------------------------------------------------
cat(sprintf("\n=== 5. THE FUTURES: CO2 (ppm) in %d (br_futures()), read against the ridge's measured 1-sigma width ===\n", BR_FUT_YEAR))
FUT_V <- list(canonical = dg_vector(ccx_mode_file(O18_CANON)), B = vec_under(ccx_mode_struct(MD_B)), B1s = V_S1, obj18 = V_N)
FUT <- t(vapply(names(FUT_V), function(a) { v <- FUT_V[[a]]; br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
d_fut <- c(B = max(abs(FUT["B", ] - PX$futures["B", ])), B1s = max(abs(FUT["B1s", ] - PX$futures["B1s", ])))
cat(sprintf("  B and B1s vs the pricing's futures: max |diff| %.1e / %.1e ppm (tol %g)\n", d_fut[["B"]], d_fut[["B1s"]], O18_FUT_TOL))
if (any(d_fut > O18_FUT_TOL)) stop("the futures do not reproduce the pricing's: the vectors are not built the same way")
HALF <- pmin(abs(PX$ridge_width["lo", ]), abs(PX$ridge_width["hi", ]))   # the narrower side: the conservative width
cat(sprintf("  the ridge's 1-sigma (the pricing's, natural space, the narrower side): SSP5-8.5 %.1f, vvH %.1f ppm\n", HALF[1], HALF[2]))
for (a in rownames(FUT)) { dB <- FUT[a, ] - FUT["B", ]
  cat(sprintf("  %-10s %s%s\n", a, paste(sprintf("%s %8.2f (%+7.2f vs B)", colnames(FUT), FUT[a, ], dB), collapse = " | "),
              if (a %in% c("canonical", "B")) "" else sprintf("  = %.2f / %.2f of the width%s", abs(dB[1]) / HALF[1], abs(dB[2]) / HALF[2],
                                                               if (all(abs(dB) < HALF)) " -- INSIDE: not a finding" else ""))) }
cat(sprintf("  the pricing's re-fit cells vs B: %s\n", paste(sprintf("%s %+.2f / %+.2f", c("B2s", "B2fs"),
            PX$futures[c("B2s", "B2fs"), 1] - PX$futures["B", 1], PX$futures[c("B2s", "B2fs"), 2] - PX$futures["B", 2]), collapse = "; ")))

# ---- 6. the land's net climate effect ---------------------------------------------------------------------
cat(sprintf("\n=== 6. THE LAND's NET CLIMATE EFFECT, %d-%d (TRENDY S2 - S1), GtC/yr ===\n", O18_NET_WIN[1], O18_NET_WIN[2]))
NET <- t(vapply(c("canonical", "B", "obj18"), function(a) br_net_climate(FUT_V[[a]], O18_NET_WIN, O18_NET_CLIM), numeric(3)))
for (a in rownames(NET)) cat(sprintf("  %-10s net climate effect %+.4f, z %+.2f against GCB 2025's %+.1f +/- %.1f\n", a, NET[a, "net_climate"],
                                     (NET[a, "net_climate"] - O18_GCB_NET[["mean"]]) / O18_GCB_NET[["sd"]], O18_GCB_NET[["mean"]], O18_GCB_NET[["sd"]]))

# ---- the separate drivers ---------------------------------------------------------------------------------
cat("\n=== THE SEPARATE DRIVERS (run from a frozen copy; each writes its own log) ===\n")
cat(sprintf("  THE ONE-PASS CHECK (RULED 0.1 sigma): Rscript calibration/fit_iav_module.R --base=%s --check=%s\n", O18_MODE, O18_STAGE1))
cat(sprintf("  CCX_SC_EXTRA_MODE=\"obj18=%s\" CCX_SC_TAG_SUFFIX=_obj18 Rscript calibration/diag_whole_model_scorecard.R\n", O18_MODE))
cat(sprintf("  CCX_OC_MODE=\"obj18=%s\" Rscript calibration/diag_ocean_climate_gobm.R\n", O18_MODE))

sink()
saveRDS(list(on18 = T1, d18 = D18, cells = CELLS, groups = rbind(obj18 = G18, B2s = G2s), vs_seed = c(lik = OWN_N$lik - B1S$lik,
             logpost = OWN_N$logpost - B1S$logpost), on17 = T2, d17 = D17, d17_p0 = D17P0,
             module = rbind(stage1 = ML_S1, obj18 = ML_N), survey = list(n_starts = length(starts), n_converged = length(conv),
             n_out_of_time = n_oot, n_dead = n_dead, logposts = lps, ids = ids, clusters = CLUS, twins = TWIN, promoted_from = pf),
             ledger_inc = LB, ledger_obj18 = LN, moves = Z, futures = FUT, ridge_half = HALF, net_climate = NET,
             gates = list(ref = d_ref, stage1_module = d_s1, futures = d_fut),
             provenance = sprintf("%s @%s; incumbent %s (%s, md5 %s); #18 %s (md5 %s); wave %s; stage 1 %s (md5 %s); pricing %s @%s; futures %s to %d; tag '%s'; no RNG; %s",
                                  O18_DRIVER, COMMIT, O18_INC, ccx_mode_file(O18_INC), O18_INC_MD5, O18_MODE, unname(tools::md5sum(O18_MODE)),
                                  O18_WAVE, O18_STAGE1, unname(tools::md5sum(O18_STAGE1)), O18_PRICE, O18_PRICE_COMMIT,
                                  paste(names(BR_FUT_SPLICE), collapse = "+"), BR_FUT_YEAR, O18_TAG, format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(O18_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", O18_OUT))
