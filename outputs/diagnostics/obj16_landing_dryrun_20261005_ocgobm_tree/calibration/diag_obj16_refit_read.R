#!/usr/bin/env Rscript
# =====================================================================
# diag_obj16_refit_read.R -- READING OBJECTIVE #16's REFIT (2026-10-05 g; written while the refit ran, for handoff
# notes/handoff_2026-10-05b_obj16_running.md §5 steps 5-6, on the model of diag_kw1446_price_read.R).
#
# THE REFIT (CHANGELOG 10-05 f): the label hilda_csl3v0kaidgbem (the stratification feedback, DESIGN §3.4a S, ON and
# FIXED) with the canonical's 9 pins + npp_tsens = 0 (P4; Marcus 2026-10-05, "p4"). 33 free names, 24 dispersed starts
# on the Mac; promoted (GATES 1-5) and its Hessian recomputed. Read against hilda34g (the canonical, objective #15).
#
# WHAT IT READS:
#   0. Each vector reproduces its stored logpost in its OWN space (label, pins, spinup). The wave's survey.
#   1. THE FIT ON LIKELIHOOD, row by row, on the SAME rows. ⛔ Never on stored logposts: the pin removes npp_tsens's
#      prior term (2.57 at hilda34g, CHANGELOG 10-05 f). Beside it, the previews: P4's conditional slice (-0.26) and
#      the feedback unrefitted (-1.77).
#   2. THE PRIOR LEDGER: the stored-logpost difference split into likelihood, the common names' priors and
#      Jacobians, and npp_tsens's own term at hilda34g (absent under #16).
#   3. THE MOVES: each common name's move from hilda34g in hilda34g's MARGINAL Laplace sd, ranked. O16_NAMED are
#      always printed (the P4 slice put beta_max at 2.05; k_w ~1900 is a prior compromise, memory
#      ccx_kw_hemispheric_balance).
#   4. THE FUTURES: CO2 in BR_FUT_YEAR under SSP5-8.5 and vvH, by lib_block_reopt.R's br_futures(), the previews'
#      estimator, at five vectors. hilda34g; hilda34g + the pin (unrefitted); hilda34g + the feedback (unrefitted);
#      #16; and #16 with the feedback OFF (unrefitted). So #16's move splits into the feedback's direct part at #16
#      and the rest (the pin plus the refit's re-arrangement).
#   5. THE LAND's NET CLIMATE EFFECT, O16_NET_WIN, on GCB 2025's TRENDY definition (br_net_climate()). CO2 is
#      interactive here and prescribed in TRENDY (a -0.023 GtC/yr bias at hilda34g, measured 10-04). Under #16 the
#      held-GMST run also mixes the ocean harder, which lowers CO2 a little more.
# The ocean's climate effect (diag_ocean_climate_gobm.R, CCX_OC_MODE) and the scorecard (diag_whole_model_scorecard.R,
# CCX_SC_EXTRA_MODE) are separate drivers; their commands are printed at the end.
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_obj16_refit_read.R
#   CCX_O16_MODE=<path> and CCX_O16_WAVE=<dir> override the promoted file and the wave. The defaults are the UNIQUE
#   matches of O16_MODE_GLOB / O16_WAVE_GLOB under calibration/output/. CCX_O16_TAG=<suffix> tags the outputs, so a
#   dry run says so in its file name.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # the previews' futures (diag_obj16_preview.R)
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
O16_DRIVER      <- "calibration/diag_obj16_refit_read.R"
O16_CANON       <- "hilda34g"
O16_LABEL_CANON <- "hilda_csl3v0kaidgbe"
O16_LABEL       <- CCX_MODE_OBJ16_STRUCT                    # "hilda_csl3v0kaidgbem"
O16_PINS        <- CCX_MODE_OBJ16_PINS                      # the canonical's nine + npp_tsens = 0
O16_GREEN       <- "npp_tsens"
O16_MIX_NAMES   <- c("mix_strat_s", "mix_strat_q", "mix_strat_tau")
O16_NAMED       <- c("beta_max", "k_w", "fert_k", "q10")    # always in the moves table, whatever their rank
O16_WAVE_GLOB   <- "multistart_20261005f_hilda_csl3v0kaidgbem_seasml1_pin_*npp_tsens=0_sd1.0452"
O16_MODE_GLOB   <- "refit_*_obj16_hilda_csl3v0kaidgbem"
O16_BASIN_GAP   <- 0.05                                     # logpost; diag_kw1446_price_read.R's KR_BASIN_GAP
O16_REPRO_TOL   <- 1e-5                                     # recompute_hessian.R's GATE 1 tolerance
O16_TOP         <- 12L
O16_NET_WIN     <- c(2015L, 2024L); O16_NET_CLIM <- c(1901L, 1920L)   # GCB 2025 s. 3.7.2's window; TRENDY's held climate
O16_GCB_NET     <- c(mean = -0.8, sd = 0.7)                 # GtC/yr, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
# THE PREVIEWS, with receipts (each is CONDITIONAL or UNREFITTED; printed beside the refit, never gated)
O16_PREV_LIK  <- c(p4_slice = -0.26, feedback_unrefitted = -1.7668)   # CHANGELOG 10-05 d (obj16_preview §G); 10-04 n
O16_PREV_INC  <- c(pin = -53.93, feedback = -1.7668, interaction = -8.19, prior_removed = -2.57)   # 10-05 f: the START's -66.46
O16_PREV_FUT  <- c(canon_ssp585 = 1448.6, p4_ssp585 = 1462.2, p4_vvH_delta = 9.3, feedback_ssp585_delta = 5.5)  # 10-05 d; 10-04 o
O16_PREV_NET  <- c(canon = 0.12, p4 = -0.04)               # GtC/yr; 10-04 i (proposal) and 10-05 d
O16_PREV_BETA <- c(canon = 1.83, p4_slice = 2.05)           # 10-05 d
O16_TAG <- Sys.getenv("CCX_O16_TAG", "")
O16_OUT <- file.path("outputs", "diagnostics", sprintf("obj16_refit_read_%s%s", format(Sys.Date(), "%Y%m%d"), O16_TAG))
one_match <- function(pattern, what) { m <- Sys.glob(file.path("calibration", "output", pattern))
  if (length(m) != 1L) stop(sprintf("%s: %d matches for calibration/output/%s; exactly one is required (or set the override)",
                                    what, length(m), pattern))
  m }
O16_WAVE <- Sys.getenv("CCX_O16_WAVE", ""); if (!nzchar(O16_WAVE)) O16_WAVE <- one_match(O16_WAVE_GLOB, "the wave")
O16_MODE <- Sys.getenv("CCX_O16_MODE", "")
if (!nzchar(O16_MODE)) O16_MODE <- file.path(one_match(O16_MODE_GLOB, "the promoted mode"), "mode_fit_pumpN.rds")
COMMIT <- local({
  h <- suppressWarnings(tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), error = function(e) character(0)))
  d <- suppressWarnings(tryCatch(system2("git", c("status", "--porcelain", "--", "R", "src", "calibration", "data"), stdout = TRUE),
                                 error = function(e) NA_character_))
  if (length(h) != 1L) "?" else paste0(h, if (anyNA(d)) "+dirty?" else if (length(d)) "+dirty" else "") })
sink(paste0(O16_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  canonical %s (%s)\n  #16       %s (md5 %s)\n  wave      %s\n", O16_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            O16_CANON, ccx_mode_file(O16_CANON), O16_MODE, unname(tools::md5sum(O16_MODE)), O16_WAVE))
if (nzchar(O16_TAG)) cat(sprintf("  ⚠ TAGGED '%s': read the provenance before quoting anything below\n", O16_TAG))

OBS <- ccx_prepare_obs()
# one arm's own space (diag_kw1446_price_read.R's in_arm): its gate and pins, base, spinup and objective
in_arm <- function(md, f) {
  r <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit(ccx_unpin_params(r), add = TRUE)
  stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  lp  <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spf, obs = OBS)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "obj16 read")))
  stopifnot(length(st$absent) == 0L, st$logpost_shift == 0)
  f(lp, st$u, bp)
}
ev <- function(lp, u) { v <- lp(u); s <- unlist(attr(v, "streams")); list(logpost = as.numeric(v), streams = s, lik = sum(s)) }
# each free name's prior log-density and log-Jacobian at u (the objective's own two terms, R/calibrate.R)
ledger <- function(u, bp) { par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  t(vapply(names(u), function(n) { s <- CCX_PARAM_TABLE[[n]]
    c(value = par[[n]], prior = .ccx_prior_eval(s, par[[n]], p_pr), jac = .log_jac(u[[n]], s),
      z = tryCatch(ccx_prior_z(n, par[[n]], p = p_pr), error = function(e) NA_real_)) }, numeric(4))) }

MD_C <- readRDS(ccx_mode_file(O16_CANON)); MD_N <- readRDS(O16_MODE)
PIN_N <- ccx_mode_pins(MD_N)
stopifnot(identical(ccx_mode_struct(MD_C), O16_LABEL_CANON), identical(ccx_mode_struct(MD_N), O16_LABEL),
          setequal(names(PIN_N), names(O16_PINS)), isTRUE(all.equal(unname(unclass(PIN_N)[names(O16_PINS)]), unname(O16_PINS))),
          !(O16_GREEN %in% names(ccx_mode_pins(MD_C))))

# ---- 0. reproduction and the survey ------------------------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST IN ITS OWN SPACE (tol %g); THE WAVE ===\n", O16_REPRO_TOL))
starts <- lapply(sort(list.files(O16_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)), readRDS)
conv   <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time), starts)
n_oot  <- sum(vapply(starts, function(s) isTRUE(s$out_of_time), TRUE))
lps    <- sort(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)
ids    <- vapply(conv, `[[`, 0L, "id")[order(vapply(conv, `[[`, 0, "logpost"), decreasing = TRUE)]
CLUS   <- split(lps, cumsum(c(TRUE, -diff(lps) > O16_BASIN_GAP)))
cat(sprintf("  survey: %d start files; %d CONVERGED in time, %d out of time; best %.6f (id %03d)\n", length(starts), length(conv), n_oot, lps[1], ids[1]))
cat(sprintf("  converged logposts in clusters split at gaps > %.2f: %s\n", O16_BASIN_GAP,
            paste(vapply(CLUS, function(x) sprintf("%.4f x%d", x[1], length(x)), ""), collapse = " | ")))
cat(sprintf("  promoted: id %s at %.6f (GATE 3's best is id %03d at %.6f)\n", format(MD_N$promoted_from$id), MD_N$logpost, ids[1], lps[1]))
if (!identical(as.integer(MD_N$promoted_from$id), as.integer(ids[1]))) stop("the promoted id is not the wave's best converged start")
EC <- in_arm(MD_C, function(lp, u, bp) c(ev(lp, u), list(u = u, led = ledger(u, bp))))
EN <- in_arm(MD_N, function(lp, u, bp) c(ev(lp, u), list(u = u, led = ledger(u, bp))))
for (r in list(list(sprintf("canonical %s", O16_CANON), EC, MD_C$logpost), list("objective #16", EN, MD_N$logpost))) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-22s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows  prior+Jacobian %.4f\n",
              r[[1]], r[[2]]$logpost, r[[3]], d, r[[2]]$lik, length(r[[2]]$streams), r[[2]]$logpost - r[[2]]$lik))
  if (!(abs(d) <= O16_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}
rows <- names(EC$streams)
if (!setequal(rows, names(EN$streams))) stop("the two objectives score DIFFERENT rows: likelihoods are not comparable")

# ---- 1. the fit on likelihood ------------------------------------------------------------------------
cat(sprintf("\n=== 1. #16 vs %s ON LIKELIHOOD (the same %d rows; > 0 = #16 fits BETTER) ===\n", O16_CANON, length(rows)))
ST <- data.frame(row = rows, canonical = EC$streams[rows], obj16 = EN$streams[rows], row.names = NULL)
ST$d <- ST$obj16 - ST$canonical; ST <- ST[order(-abs(ST$d)), ]
for (i in seq_len(nrow(ST))) cat(sprintf("  %-22s canonical %10.3f | #16 %+8.3f\n", ST$row[i], ST$canonical[i], ST$d[i]))
D_LIK <- EN$lik - EC$lik
cat(sprintf("  TOTAL %+.4f (canonical %.4f; #16 %.4f)\n", D_LIK, EC$lik, EN$lik))
FAM <- c(CO2 = "^co2", d13C = "^d13c", atm_d14C = "^d14c_(intcal|NH|SH)$", ocean_14C = "^excess_c14|^d14c_profile", GCB = "^gcb",
         ocean_grad_surface = "^ocean_grad|^hs_surf", other = "^(?!co2|d13c|d14c_(intcal|NH|SH)$|excess_c14|d14c_profile|gcb|ocean_grad|hs_surf)")
fam_hit <- vapply(FAM, function(pat) grepl(pat, ST$row, perl = TRUE), logical(nrow(ST)))
if (!all(rowSums(fam_hit) == 1L)) stop("a row sits in no family or in two: ", paste(ST$row[rowSums(fam_hit) != 1L], collapse = ", "))
cat(sprintf("  by family: %s\n", paste(sprintf("%s %+.3f", names(FAM), vapply(FAM, function(p) sum(ST$d[grepl(p, ST$row, perl = TRUE)]), 0)),
                                     collapse = " | ")))
cat(sprintf("  THE PREVIEWS (each conditional or unrefitted, so not a bound on the joint refit): P4's slice %+.2f; the feedback %+.4f; their sum %+.2f\n",
            O16_PREV_LIK[["p4_slice"]], O16_PREV_LIK[["feedback_unrefitted"]], sum(O16_PREV_LIK)))
cat(sprintf("  the START (hilda34g seeded at npp_tsens 0, under #16's label) sat %+.2f below on logpost: pin %+.2f, feedback %+.2f, interaction %+.2f, prior removed %+.2f\n",
            sum(O16_PREV_INC), O16_PREV_INC[["pin"]], O16_PREV_INC[["feedback"]], O16_PREV_INC[["interaction"]], O16_PREV_INC[["prior_removed"]]))

# ---- 2. the prior ledger -----------------------------------------------------------------------------
cat("\n=== 2. THE PRIOR LEDGER (natural-scale prior log-density + log-Jacobian, the objective's own terms) ===\n")
common <- intersect(rownames(EC$led), rownames(EN$led))
if (!setequal(setdiff(rownames(EC$led), common), O16_GREEN) || length(setdiff(rownames(EN$led), common)))
  stop("the free sets differ by more than ", O16_GREEN, ": ", paste(setdiff(union(rownames(EC$led), rownames(EN$led)), common), collapse = ", "))
dP <- EN$led[common, "prior"] - EC$led[common, "prior"]; dJ <- EN$led[common, "jac"] - EC$led[common, "jac"]
o <- order(-abs(dP))
cat(sprintf("  %-20s %12s %12s %9s %9s %9s %9s\n", "name", "canonical", "#16", "z canon", "z #16", "d prior", "d jac"))
for (n in common[o][seq_len(min(O16_TOP, length(common)))])
  cat(sprintf("  %-20s %12.5g %12.5g %9.2f %9.2f %+9.3f %+9.3f\n", n, EC$led[n, "value"], EN$led[n, "value"], EC$led[n, "z"],
              EN$led[n, "z"], dP[[n]], dJ[[n]]))
GREEN_TERM <- EC$led[O16_GREEN, "prior"] + EC$led[O16_GREEN, "jac"]
SPLIT <- c(d_logpost_stored = MD_N$logpost - MD_C$logpost, d_likelihood = D_LIK, d_other_priors = sum(dP), d_other_jac = sum(dJ),
           green_term_at_canonical = GREEN_TERM)
SPLIT_RESID <- SPLIT[["d_logpost_stored"]] - (SPLIT[["d_likelihood"]] + SPLIT[["d_other_priors"]] + SPLIT[["d_other_jac"]] - SPLIT[["green_term_at_canonical"]])
cat(sprintf("  logpost difference %+.4f = likelihood %+.4f + the other names' priors %+.4f + their Jacobians %+.4f - %s's own term at the canonical (%.4f at %.5f)  [check %+.1e]\n",
            SPLIT[["d_logpost_stored"]], SPLIT[["d_likelihood"]], SPLIT[["d_other_priors"]], SPLIT[["d_other_jac"]], O16_GREEN, GREEN_TERM,
            EC$led[O16_GREEN, "value"], SPLIT_RESID))
if (!(abs(SPLIT_RESID) <= 1e-6)) stop("the ledger does not close: a term is missing from the split")

# ---- 3. the moves --------------------------------------------------------------------------------------
cat(sprintf("\n=== 3. THE MOVES: each common name's move from %s, in %s's MARGINAL Laplace sd (u-space) ===\n", O16_CANON, O16_CANON))
FS_C <- ccx_mode_fit_stats(MD_C); sdC <- stats::setNames(as.numeric(FS_C$sd), FS_C$param_names)
FS_N <- tryCatch(ccx_mode_fit_stats(MD_N), error = function(e) NULL)
sdN  <- if (is.null(FS_N)) NULL else stats::setNames(as.numeric(FS_N$sd), FS_N$param_names)
Z <- (EN$u[common] - EC$u[common]) / sdC[common]; Z <- Z[order(-abs(Z))]
cat(sprintf("  %s itself: %.5f -> 0 (pinned) = %+.2f marginal sd\n", O16_GREEN, EC$led[O16_GREEN, "value"],
            (0 - EC$u[[O16_GREEN]]) / sdC[[O16_GREEN]]))
show <- unique(c(names(Z)[seq_len(min(O16_TOP, length(Z)))], intersect(O16_NAMED, names(Z))))
for (n in show) cat(sprintf("  %-20s %12.5g -> %12.5g  %+6.2f sd%s%s\n", n, EC$led[n, "value"], EN$led[n, "value"], Z[[n]],
                            if (is.null(sdN)) "" else sprintf("   (#16's own sd %.3g, u-space)", sdN[[n]]),
                            if (n %in% O16_NAMED && !(n %in% names(Z)[seq_len(O16_TOP)])) "   [named]" else ""))
cat(sprintf("  beside the P4 slice: beta_max %.2f -> %.2f there (canonical %.2f here, #16 %.3f)\n", O16_PREV_BETA[["canon"]],
            O16_PREV_BETA[["p4_slice"]], EC$led["beta_max", "value"], EN$led["beta_max", "value"]))
if (is.null(FS_N)) cat("  ⚠ #16's file carries no Hessian yet: run recompute_hessian.R --update before quoting its sds\n")

# ---- 4. the futures --------------------------------------------------------------------------------------
cat(sprintf("\n=== 4. THE FUTURES: CO2 (ppm) in %d, %s (br_futures(), the previews' estimator) ===\n", BR_FUT_YEAR,
            paste(sprintf("%s%s", names(BR_FUT_SPLICE), ifelse(BR_FUT_SPLICE, " (spliced onto the historical emissions)", "")), collapse = ", ")))
V_C <- dg_vector(O16_CANON); V_N <- dg_vector(O16_MODE)
MIX_BLK <- ccx_struct_block(O16_LABEL)
# a vector with model values overridden: the model list `p`, and the fitted list `pm` where the name is fitted there
with_p <- function(v, kv) { for (n in names(kv)) { v$p[[n]] <- kv[[n]]; if (n %in% names(v$pm)) v$pm[[n]] <- kv[[n]] }; v }
FUT_V <- list(
  canonical          = V_C,
  canonical_pin      = with_p(V_C, stats::setNames(list(0), O16_GREEN)),
  canonical_feedback = with_p(V_C, MIX_BLK[O16_MIX_NAMES]),
  obj16              = V_N,
  obj16_feedback_off = with_p(V_N, list(mix_strat_s = 0)))   # 0 = OFF bit for bit (R/model.R ccx_mix_on())
stopifnot(ccx_mix_on(FUT_V$obj16$p), !ccx_mix_on(FUT_V$obj16_feedback_off$p), ccx_mix_on(FUT_V$canonical_feedback$p),
          !ccx_mix_on(FUT_V$canonical$p), FUT_V$obj16$p[[O16_GREEN]] == 0)
FUT <- t(vapply(names(FUT_V), function(a) { v <- FUT_V[[a]]; br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
for (a in rownames(FUT)) cat(sprintf("  %-20s %s\n", a, paste(sprintf("%s %8.2f (%+7.2f)", colnames(FUT), FUT[a, ], FUT[a, ] - FUT["canonical", ]), collapse = " | ")))
cat(sprintf("  cross-checks (printed, not gated): canonical ssp585 %.2f vs the preview's %.1f; the feedback at the canonical %+.2f vs 10-04 (o)'s %+.1f\n",
            FUT["canonical", "ssp585"], O16_PREV_FUT[["canon_ssp585"]], FUT["canonical_feedback", "ssp585"] - FUT["canonical", "ssp585"],
            O16_PREV_FUT[["feedback_ssp585_delta"]]))
cat(sprintf("  #16's move %s = the feedback's direct part at #16 %s + the pin and the refit's re-arrangement %s\n",
            paste(sprintf("%s %+.2f", colnames(FUT), FUT["obj16", ] - FUT["canonical", ]), collapse = ", "),
            paste(sprintf("%+.2f", FUT["obj16", ] - FUT["obj16_feedback_off", ]), collapse = "/"),
            paste(sprintf("%+.2f", FUT["obj16_feedback_off", ] - FUT["canonical", ]), collapse = "/")))
cat(sprintf("  the previews: P4 (land block re-optimised) ssp585 %+.1f, vvH %+.1f; the pin UNREFITTED here %s\n",
            O16_PREV_FUT[["p4_ssp585"]] - O16_PREV_FUT[["canon_ssp585"]], O16_PREV_FUT[["p4_vvH_delta"]],
            paste(sprintf("%s %+.2f", colnames(FUT), FUT["canonical_pin", ] - FUT["canonical", ]), collapse = ", ")))

# ---- 5. the land's net climate effect ---------------------------------------------------------------
cat(sprintf("\n=== 5. THE LAND's NET CLIMATE EFFECT, %d-%d (TRENDY S2 - S1: climate varying vs held at its %d-%d mean), GtC/yr ===\n",
            O16_NET_WIN[1], O16_NET_WIN[2], O16_NET_CLIM[1], O16_NET_CLIM[2]))
NET <- t(vapply(c("canonical", "obj16"), function(a) br_net_climate(FUT_V[[a]], O16_NET_WIN, O16_NET_CLIM), numeric(3)))
for (a in rownames(NET)) cat(sprintf("  %-10s land gain %.4f (climate held %.4f) -> net climate effect %+.4f, z %+.2f against GCB 2025's %+.1f +/- %.1f\n",
                                     a, NET[a, "full"], NET[a, "held"], NET[a, "net_climate"], (NET[a, "net_climate"] - O16_GCB_NET[["mean"]]) / O16_GCB_NET[["sd"]],
                                     O16_GCB_NET[["mean"]], O16_GCB_NET[["sd"]]))
cat(sprintf("  the previews: the canonical %+.2f (10-04 i), P4 %+.2f (10-05 d)\n", O16_PREV_NET[["canon"]], O16_PREV_NET[["p4"]]))

# ---- the separate drivers ---------------------------------------------------------------------------------
cat("\n=== THE SEPARATE DRIVERS (run from a frozen copy; each writes its own log) ===\n")
cat(sprintf("  CCX_OC_MODE=\"obj16=%s\" Rscript calibration/diag_ocean_climate_gobm.R\n", O16_MODE))
cat(sprintf("  CCX_SC_EXTRA_MODE=\"obj16=%s\" CCX_SC_TAG_SUFFIX=_obj16 Rscript calibration/diag_whole_model_scorecard.R\n", O16_MODE))

sink()
saveRDS(list(streams = ST, d_lik = D_LIK, survey = list(n_starts = length(starts), n_converged = length(conv), n_out_of_time = n_oot,
                                                         logposts = lps, ids = ids, clusters = CLUS),
             ledger_canonical = EC$led, ledger_obj16 = EN$led, split = SPLIT, moves = Z, futures = FUT, net_climate = NET,
             previews = list(lik = O16_PREV_LIK, start = O16_PREV_INC, futures = O16_PREV_FUT, net = O16_PREV_NET, beta = O16_PREV_BETA),
             provenance = sprintf("%s @%s; canonical %s (%s); #16 %s (md5 %s); wave %s; futures %s to %d; net climate %d-%d vs %d-%d; tag '%s'; no RNG; %s",
                                  O16_DRIVER, COMMIT, O16_CANON, ccx_mode_file(O16_CANON), O16_MODE, unname(tools::md5sum(O16_MODE)), O16_WAVE,
                                  paste(names(BR_FUT_SPLICE), collapse = "+"), BR_FUT_YEAR, O16_NET_WIN[1], O16_NET_WIN[2], O16_NET_CLIM[1],
                                  O16_NET_CLIM[2], O16_TAG, format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(O16_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", O16_OUT))
