# =====================================================================
# diag_emis_constant_price.R -- PRICE the model-wide flip of the emissions
# interpolation, spline -> piecewise-constant, on every registered mode.
#
# WHY (Marcus 2026-10-01, review 10-01c B6: "I think apply it now: I don't expect
# another refit anytime soon"). The flip was ruled 09-24 ("option 1", branch
# `emissions-interp-constant`, 35f38dc) to ride with the next refit; it missed
# the #14 refit, and is now applied WITHOUT a refit. Every stored logpost and
# stream set was produced under "spline", so each registered file is RESTAMPED
# (calibration/restamp_mode_objective.R) -- and that script refuses any move it
# was not told to expect. This driver produces those expected moves: the
# LIKELIHOOD delta per file, to the 4 dp the restamp gate checks, with the rows
# that carry it.
#
# HOW. Each file is scored the restamp tool's own way (its gate, its pins,
# ccx_mode_start(), its own spin-up label, the objective by stream) twice, with
# CCX_EMIS_METHOD_DEFAULT bound to "spline" and then "constant" for the call.
# The "spline" pass must reproduce the STORED streams exactly (identical(), the
# obj14 bit-exact check) -- a file that does not reproduce cannot be priced.
# Run it BEFORE the constant in R/constants.R flips (it binds both methods
# itself, so it also runs after; the spline pass then still has to reproduce).
#
# Output: outputs/diagnostics/emis_constant_price_<date>.{log,csv}, stamped with
# the commit and a dirty marker. No RNG.
# Usage: Rscript calibration/diag_emis_constant_price.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
EP_DRIVER  <- "calibration/diag_emis_constant_price.R"
EP_DATE    <- format(Sys.Date(), "%Y%m%d")
EP_OUT     <- ccx_path("outputs", "diagnostics", sprintf("emis_constant_price_%s", EP_DATE))
EP_METHODS <- c(before = "spline", after = "constant")
EP_ROW_TOL <- 1e-9    # a row "moved" above this (identical() decides reproduction)
EP_COMMIT  <- tryCatch({
  h <- system("git rev-parse --short HEAD", intern = TRUE)
  d <- length(system("git status --porcelain --untracked-files=no", intern = TRUE)) > 0
  paste0(h, if (d) "+dirty" else "")
}, error = function(e) "?")

score_with <- function(md, method) {
  old <- CCX_EMIS_METHOD_DEFAULT
  assign("CCX_EMIS_METHOD_DEFAULT", method, envir = globalenv())
  on.exit(assign("CCX_EMIS_METHOD_DEFAULT", old, envir = globalenv()), add = TRUE)
  gt <- ccx_apply_gate(ccx_mode_struct(md))
  rm <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rm); ccx_unapply_gate(gt) }, add = TRUE)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "emis price")))
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  v <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                        spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(st$u)
  list(lp = as.numeric(v) - st$logpost_shift, streams = attr(v, "streams"))
}

sink(paste0(EP_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === %s @%s, run %s; CCX_EMIS_METHOD_DEFAULT in R/constants.R at run time: \"%s\"\n",
            EP_DRIVER, EP_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), CCX_EMIS_METHOD_DEFAULT))
cat(sprintf("  registered modes (R/paths.R CCX_MODE_FILES): %s; each under its own structure, pins and spin-up; no RNG\n\n",
            paste(names(CCX_MODE_FILES), collapse = ", ")))
rows <- list(); res <- list()
for (a in names(CCX_MODE_FILES)) {
  md <- readRDS(ccx_mode_file(a))
  s0 <- score_with(md, EP_METHODS[["before"]]); s1 <- score_with(md, EP_METHODS[["after"]])
  old <- unlist(md$streams); b <- unlist(s0$streams); n <- unlist(s1$streams)
  repro <- identical(names(b), names(old)) && identical(unname(b), unname(old))
  if (!identical(names(n), names(b))) stop(a, ": the two methods produced different ROW SETS")
  d <- n - b
  lik_b <- sum(b); lik_n <- sum(n)
  res[[a]] <- data.frame(mode = a, struct = ccx_mode_struct(md), spline_reproduces_stored = repro,
                         lik_spline = lik_b, lik_constant = lik_n, d_lik = lik_n - lik_b,
                         logpost_stored = md$logpost, logpost_spline = s0$lp, logpost_constant = s1$lp,
                         d_logpost = s1$lp - s0$lp, n_rows = length(n), n_rows_moved = sum(abs(d) > EP_ROW_TOL),
                         commit = EP_COMMIT, stringsAsFactors = FALSE)
  mv <- d[abs(d) > EP_ROW_TOL]; mv <- mv[order(-abs(mv))]
  rows[[a]] <- data.frame(mode = a, row = names(mv), d = unname(mv), stringsAsFactors = FALSE)
  cat(sprintf("%-10s spline reproduces stored: %-5s | likelihood %.6f -> %.6f  (d %+.6f, restamp expects %+.4f) | logpost %+.6f | rows moved %d/%d\n",
              a, repro, lik_b, lik_n, lik_n - lik_b, round(lik_n - lik_b, 4), s1$lp - s0$lp, length(mv), length(n)))
  if (length(mv)) cat("            ", paste(sprintf("%s %+.5f", names(mv), mv), collapse = ", "), "\n")
}
tab <- do.call(rbind, res); rownames(tab) <- NULL
utils::write.csv(tab, paste0(EP_OUT, ".csv"), row.names = FALSE)
utils::write.csv(do.call(rbind, rows), paste0(EP_OUT, "_rows.csv"), row.names = FALSE)
cat(sprintf("\nVERDICT: %s; |d likelihood| max %.4f (%s)\n",
            if (all(tab$spline_reproduces_stored)) "every registered file REPRODUCES under spline -> priceable"
            else "a file does NOT reproduce under spline -> do not restamp it",
            max(abs(tab$d_lik)), tab$mode[which.max(abs(tab$d_lik))]))
cat(sprintf("saved %s.{log,csv} and %s_rows.csv\n", EP_OUT, EP_OUT))
sink()
