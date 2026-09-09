# =====================================================================
# THE DE-BIASING'S IMPACT (ruling 4, Marcus 2026-09-09): score the canonical
# hilda31 under the PRE- and POST-de-biasing bomb forcing, per stream.
#
# ⚠ THIS IS A MATCHED COMPARISON AT A FIXED PARAMETER VECTOR. It is NOT a
# refit: hilda31 was fitted under the PRE forcing, so the POST arm is that
# vector evaluated on a changed input, not a mode of the new objective. It
# bounds the SIZE of the change; it cannot say where the new mode goes.
#
# The forcing file is swapped on disk and restored via on.exit(). Both arms are
# recoverable regardless: PRE is committed at 6f2870a, POST is
# `Rscript data-raw/build_bomb_c14_source.R`.
# Usage: Rscript calibration/diag_bomb_debias_impact.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

SCRATCH  <- Sys.getenv("CCX_SCRATCH", unset = tempdir())
BDI_LIVE <- ccx_path("data", "forcing_bomb_c14.rds")
BDI_ARMS <- c(post = file.path(SCRATCH, "forcing_bomb_c14_POST_debias.rds"),
              pre  = file.path(SCRATCH, "forcing_bomb_c14_PRE_debias.rds"))
BDI_OUT  <- ccx_path("outputs", "diagnostics",
                     sprintf("bomb_debias_impact_%s.rds", format(Sys.Date(), "%Y%m%d")))
stopifnot(all(file.exists(BDI_ARMS)))

keep <- file.path(SCRATCH, "forcing_bomb_c14_LIVE_backup.rds")
file.copy(BDI_LIVE, keep, overwrite = TRUE)
keep_sha <- tools::sha256sum(keep)[[1]]
# ⛔ NOT on.exit(): at the TOP LEVEL of an Rscript on.exit() NEVER FIRES (it is a
# function-frame facility). The first version of this script used it, the restore
# silently did not happen, and the live forcing file was left as whatever the LAST
# loop arm staged -- a silent state leak that git status alone did not reveal,
# because that arm happened to be the one matching HEAD. Use tryCatch(finally=),
# which does fire at top level, and then ASSERT the restore. [[silent-gate family]]
restore <- function() {
  file.copy(keep, BDI_LIVE, overwrite = TRUE)
  got <- tools::sha256sum(BDI_LIVE)[[1]]
  if (!identical(got, keep_sha))
    stop(sprintf("RESTORE FAILED: live forcing is %s, expected %s", substr(got,1,12), substr(keep_sha,1,12)))
  cat(sprintf("\n[restored the live forcing file; sha256 %s verified]\n", substr(got, 1, 12)))
}

v <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("mode: %s (%s)\n", CCX_MODE_CANONICAL, v$src))

RES <- list()
tryCatch({
for (a in names(BDI_ARMS)) {
  stopifnot(file.copy(BDI_ARMS[[a]], BDI_LIVE, overwrite = TRUE))
  pv <- attr(readRDS(BDI_LIVE), "provenance")
  div <- if (is.null(pv$t2_high_bias_divisor)) 1 else pv$t2_high_bias_divisor
  # dg_streams() returns the per-stream contributions INSTEAD of the total
  # (ccx_loglik's by_stream contract), so the total is taken from the same run
  # with a second, cheap call -- dg_run() is the expensive part and is not repeated.
  t0 <- Sys.time(); r <- dg_run(v); st <- dg_streams(r, v)
  eluc <- ccx_forcing_eluc_annual(r$F)
  err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
              grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
  tot <- ccx_loglik(r$out, ccx_prepare_obs(), err, luc = eluc,
                    deep = r$sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(r$out, r$sp),
                    by_stream = FALSE, d14c_mid = ccx_model_d14c_slabs(r$sp))
  stopifnot(isTRUE(all.equal(unname(sum(unlist(st))), unname(as.numeric(tot)))))
  RES[[a]] <- list(divisor = div, streams = unlist(st), total = as.numeric(tot),
                   lambda = pv$pre1963$lambda_per_yr, D_pre = pv$pre1963$delivered_kmol,
                   secs = as.numeric(Sys.time() - t0, units = "secs"))
  cat(sprintf("  %-4s divisor %.2f  loglik %12.4f  (lambda %.4f, D_pre %.2f)  %.0f s\n",
              a, div, as.numeric(tot), pv$pre1963$lambda_per_yr, pv$pre1963$delivered_kmol,
              RES[[a]]$secs))
}
}, finally = restore())

nm <- union(names(RES$pre$streams), names(RES$post$streams))
d  <- vapply(nm, function(k) {
  as.numeric(RES$post$streams[[k]] %||% NA) - as.numeric(RES$pre$streams[[k]] %||% NA) },
  numeric(1))
cat(sprintf("\n=== TOTAL loglik: pre %.4f -> post %.4f (%+.4f) ===\n",
            RES$pre$total, RES$post$total, RES$post$total - RES$pre$total))
cat("per-stream change (post minus pre), largest first:\n")
for (k in names(sort(abs(d), decreasing = TRUE))) {
  if (!is.finite(d[[k]]) || abs(d[[k]]) < 1e-6) next
  cat(sprintf("  %-24s %+12.4f   (%.4f -> %.4f)\n", k, d[[k]],
              RES$pre$streams[[k]], RES$post$streams[[k]]))
}
saveRDS(list(arms = RES, delta = d, mode = CCX_MODE_CANONICAL, date = Sys.time()), BDI_OUT)
cat(sprintf("\nsaved %s\n", BDI_OUT))
cat("⛔ A matched evaluation, not a refit. Nothing adopted.\n")
