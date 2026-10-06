# =====================================================================
# diag_obj15_price.R -- OBJECTIVE #15 PRICED at every registered mode (2026-10-02; D1 ruled
# "Every version, as objective #15"). #15 = #14 + W3 (the ice-core CO2 row cut to samples
# before LIK_ICE_CO2_END = 1958; Marcus 10-02 "Cut to pre-1958") + W2 (the Law Dome ice-core
# d13C row `d13c_icecore`, LIK_USE_ICE_D13C; the D4 rulings of 10-02: sigma = stated + 0.05
# permil, samples before 1977, every in-run sample from 1750). R/likelihood.R carries both.
#
# For every file in CCX_MODE_FILES -- PLUS the retired `hilda31` that test-enso-demean's
# ratification pin cross-checks (CCX_MODE_HILDA31_QUARANTINED), restamped at every objective change
# since 09-11 (CHANGELOG 10-01 k) -- it re-scores the file under its OWN structure, gate, pins
# and spinup -- restamp_mode_objective.R's own path (gate, pins, ccx_mode_start(), the
# objective by stream) -- twice, with the two #15 switches flipped IN-PROCESS:
#   #14  LIK_USE_ICE_D13C = FALSE, LIK_ICE_CO2_END = Inf -> must reproduce the STORED streams
#        identical() (the switches' absence contract, and the check that this harness scores
#        the file it read);
#   #15  the shipped values.
# The likelihood move (#15 - #14, a sum of streams) is the <expected_delta> that
# restamp_mode_objective.R gates on. #15 ALSO moves two PRIORS (W5, ruled 10-02: k_w
# lognormal(1500, 0.4) -> (1446, 0.2); tau_ex (1.3, 0.25) -> (0.8, 0.26); both log-transformed,
# so no Jacobian moves). The script prices that analytically at each file's own values and
# checks the IDENTITY  logpost(#15) - stored logpost(#14) = likelihood move + prior move.
# No RNG.
# Usage: Rscript calibration/diag_obj15_price.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
PR_DRIVER <- "calibration/diag_obj15_price.R"
PR_OUT    <- ccx_path("outputs", "diagnostics", sprintf("obj15_price_%s", format(Sys.Date(), "%Y%m%d")))
PR_ROWS   <- c("co2_icecore", "d13c_icecore")            # the two rows #15 touches
COMMIT <- ccx_git_stamp()
DIRTY  <- ccx_stamp_dirty(COMMIT)   # the rds keeps `dirty`: TRUE / FALSE / NA = git could not tell
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958), identical(LIK_ICE_D13C_END, 1977))
# the #14 priors, TRANSCRIBED from R/calibrate.R as of fa4636f (an independent copy is the check)
PR_PRIOR14 <- list(k_w = c(1500, 0.4), tau_ex = c(1.3, 0.25))
PR_PRIOR15 <- list(k_w = c(ccx_const("KW_PRIOR_CENTRE"), ccx_const("KW_PRIOR_LOGSD")),
                   tau_ex = c(ccx_const("TAU_EX_PRIOR_CENTRE"), ccx_const("TAU_EX_PRIOR_LOGSD")))
PR_LP_TOL <- 1e-8                                       # the identity: sums of identical terms
d_prior <- function(pm) sum(vapply(names(PR_PRIOR15), function(n)
  stats::dlnorm(pm[[n]], log(PR_PRIOR15[[n]][1]), PR_PRIOR15[[n]][2], log = TRUE) -
  stats::dlnorm(pm[[n]], log(PR_PRIOR14[[n]][1]), PR_PRIOR14[[n]][2], log = TRUE), 0))

# flip the two switches for ONE call, restoring them however it exits
with_obj <- function(obj, f) {
  old <- list(d = LIK_USE_ICE_D13C, c = LIK_ICE_CO2_END)
  on.exit({ assign("LIK_USE_ICE_D13C", old$d, envir = globalenv())
            assign("LIK_ICE_CO2_END", old$c, envir = globalenv()) }, add = TRUE)
  if (obj == 14) { assign("LIK_USE_ICE_D13C", FALSE, envir = globalenv())
                   assign("LIK_ICE_CO2_END", Inf, envir = globalenv()) }
  f()
}

sink(paste0(PR_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n", PR_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("#15 = #14 + co2_icecore cut to year < %g + d13c_icecore (sd = sqrt(err^2 + %.3f^2), year < %g, in-run)\n",
            LIK_ICE_CO2_END, LIK_ICE_D13C_REP_ERR, LIK_ICE_D13C_END))
cat(sprintf("      + priors k_w lognormal(%g, %g) -> (%g, %g), tau_ex (%g, %g) -> (%g, %g)\n\n",
            PR_PRIOR14$k_w[1], PR_PRIOR14$k_w[2], PR_PRIOR15$k_w[1], PR_PRIOR15$k_w[2],
            PR_PRIOR14$tau_ex[1], PR_PRIOR14$tau_ex[2], PR_PRIOR15$tau_ex[1], PR_PRIOR15$tau_ex[2]))
PR_FILES <- c(vapply(stats::setNames(names(CCX_MODE_FILES), names(CCX_MODE_FILES)), ccx_mode_file, ""),
              hilda31_ratification = ccx_path(CCX_MODE_HILDA31_QUARANTINED))
res <- lapply(names(PR_FILES), function(a) {
  md <- readRDS(PR_FILES[[a]])
  gt <- ccx_apply_gate(ccx_mode_struct(md))
  rm <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rm); ccx_unapply_gate(gt) }, add = TRUE)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "obj15 price")))
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  score <- function(obj) with_obj(obj, function()
    ccx_make_logpost(base_params = bp, by_stream = TRUE,
                     spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(st$u))
  v14 <- score(14); v15 <- score(15)
  s14 <- unlist(attr(v14, "streams")); s15 <- unlist(attr(v15, "streams")); s_old <- unlist(md$streams)
  repro <- identical(names(s14), names(s_old)) && identical(unname(s14), unname(s_old))
  d_lik <- sum(s15) - sum(s14)
  d_pr  <- d_prior(md$par_mode)
  lp15  <- as.numeric(v15) - st$logpost_shift
  ident <- abs((lp15 - md$logpost) - (d_lik + d_pr)) < PR_LP_TOL
  common <- intersect(names(s15), names(s14))
  moved  <- c(common[s15[common] != s14[common]], setdiff(names(s15), names(s14)))   # + the NEW row
  cat(sprintf("%-10s %-20s #14 reproduces stored: %-5s | co2_icecore %10.4f -> %10.4f | d13c_icecore (new) %9.4f | lik %12.6f -> %12.6f (delta %+.4f) | rows that moved: %s\n",
              a, ccx_mode_struct(md), repro, s14[["co2_icecore"]], s15[["co2_icecore"]], s15[["d13c_icecore"]],
              sum(s14), sum(s15), d_lik, if (length(moved)) paste(moved, collapse = ",") else "none"))
  cat(sprintf("%-31s k_w %.1f, tau_ex %.4f -> prior move %+.4f | logpost %.6f -> %.6f (%+.4f = lik %+.4f + prior %+.4f: %s)\n",
              "", md$par_mode$k_w, md$par_mode$tau_ex, d_pr, md$logpost, lp15, lp15 - md$logpost, d_lik, d_pr,
              if (ident) "identity holds" else "IDENTITY FAILS"))
  data.frame(mode = a, struct = ccx_mode_struct(md), file = PR_FILES[[a]], n14 = length(s14), n15 = length(s15),
             repro14 = repro, co2_ice_14 = s14[["co2_icecore"]], co2_ice_15 = s15[["co2_icecore"]],
             d13c_ice_15 = s15[["d13c_icecore"]], lik14 = sum(s14), lik15 = sum(s15), delta = d_lik,
             only_touched_rows_moved = all(moved %in% PR_ROWS), d_prior = d_pr, logpost_stored = md$logpost,
             logpost15 = lp15, identity = ident, stringsAsFactors = FALSE)
})
tab <- do.call(rbind, res)
ok <- all(tab$repro14) && all(tab$only_touched_rows_moved) && all(tab$identity)
cat(sprintf("\nVERDICT: %s -- %d files (the registered modes + the hilda31 ratification file); #14 reproduced identical() %d/%d; only %s moved: %s\n",
            if (ok) "PRICED" else "FAIL", nrow(tab), sum(tab$repro14), nrow(tab),
            paste(PR_ROWS, collapse = " + "), all(tab$only_touched_rows_moved)))
cat("restamp commands (the delta to 4 dp is the gate restamp_mode_objective.R checks):\n")
for (i in seq_len(nrow(tab)))
  cat(sprintf("  Rscript calibration/restamp_mode_objective.R %s %.4f \"objective #15 (2026-10-02): ...\"\n",
              tab$file[i], tab$delta[i]))
saveRDS(list(table = tab, provenance = list(driver = PR_DRIVER, commit = COMMIT, dirty = DIRTY,
                                            co2_end = LIK_ICE_CO2_END, d13c_end = LIK_ICE_D13C_END,
                                            d13c_rep = LIK_ICE_D13C_REP_ERR, rng = "none",
                                            date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(PR_OUT, ".rds"))
cat(sprintf("provenance: %s @%s; R/paths.R CCX_MODE_FILES + CCX_MODE_HILDA31_QUARANTINED; each file's own spinup; no RNG\n",
            PR_DRIVER, COMMIT))
sink()
if (!ok) stop("objective #15 pricing FAILED its own checks")
