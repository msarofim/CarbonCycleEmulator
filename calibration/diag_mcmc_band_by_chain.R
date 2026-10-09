# =====================================================================
# diag_mcmc_band_by_chain.R -- does the MCMC check's BAND depend on which chain its draws came from?
# (Marcus 2026-10-02, "Band test on the Mac (Recommended)": stage 1 read UNconverged on beta_max,
# R-hat 1.21 / ESS 14, so before more Torch time, ask whether that matters in the deliverable's units.)
#
# build_futures_ribbons.R --draws= keeps every draw's value at the key years (2050 / 2100 / 2150) with
# its draw index, and read_mcmc_check.R stores the pooled draws chain by chain in iteration order. So
# each key cell is M CHAINS of a derived quantity in ppm or degC. For every cell this reports:
#   - each chain's 5 / 50 / 95 % and the between-chain RANGE of each, in ppm / degC, beside the pooled
#     band's width ([[rhat_denominator_forgives]]: a ratio forgives, a range in the units does not);
#   - R-hat and bulk / tail ESS of the cell itself (calibration/lib_mcmc_diag.R);
#   - the pooled band against the held Laplace band (10-01 l) at the same cell.
# It REPORTS; Marcus rules. ⚠ Chains that AGREE cannot show a gap they all SHARE: stage 1's
# log-posterior was still drifting down (CHANGELOG 10-02 s), i.e. still spreading along the ridge.
#
# ⚠ The Laplace band must be the SAME MODE's (2026-10-09): its central line has to equal the ribbons'
# own, to the build's central-check tolerance, or the run stops. The default is hilda33d's, so at any
# other canonical pass --laplace=none (no Laplace band exists at hilda29e: its importance check failed,
# 10-08 i). The central line is always the ribbons' own -- it used to be read from the Laplace file.
#
# Usage (repo root):
#   Rscript calibration/diag_mcmc_band_by_chain.R --ribbons=<the MCMC ribbons rds> --draws=<the pooled_u.rds
#       they were run from> [--laplace=outputs/diagnostics/futures_ribbons_laplace_held_20261001.rds | none] [--tag=stage1]
# =====================================================================
DB_ARGS <- commandArgs(trailingOnly = TRUE)
db_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), DB_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
source(file.path("calibration", "lib_mcmc_diag.R"))

# ---- named constants: every label and filename derives from these --------
DB_DRIVER  <- "calibration/diag_mcmc_band_by_chain.R"
DB_RIBBONS <- db_arg("ribbons", "")
DB_DRAWS   <- db_arg("draws", "")
DB_LAPLACE <- db_arg("laplace", file.path("outputs", "diagnostics", "futures_ribbons_laplace_held_20261001.rds"))
DB_HAS_LAP <- !identical(DB_LAPLACE, "none")
DB_TAG     <- db_arg("tag", "stage1")
DB_DATE    <- format(Sys.Date(), "%Y%m%d")
DB_LOG     <- file.path("outputs", "diagnostics", sprintf("mcmc_band_by_chain_%s_%s.log", DB_TAG, DB_DATE))
DB_CSV     <- sub("\\.log$", ".csv", DB_LOG)
DB_PROBS   <- c(0.05, 0.50, 0.95)   # the ruled band, as build_futures_ribbons.R's RB_PROBS
DB_UNITS   <- c(co2_ppm = "ppm", gmst = "degC")
DB_SHOW    <- list(c("vvH", "co2_ppm", "2150"), c("vvVL", "co2_ppm", "2150"),   # the 10-01 (l) linearity cells
                   c("vvM", "gmst", "2100"))
for (.f in c("aaa_root.R", "provenance.R")) source(file.path("R", .f))   # the stamp only; this driver sources no other R/
DB_COMMIT <- ccx_git_stamp()
stopifnot(nzchar(DB_RIBBONS), nzchar(DB_DRAWS), file.exists(DB_RIBBONS), file.exists(DB_DRAWS),
          !DB_HAS_LAP || file.exists(DB_LAPLACE))
sink(DB_LOG, split = TRUE)
cat(sprintf("=== %s @%s, %s ===\nribbons %s\ndraws   %s\nlaplace %s\n", DB_DRIVER, DB_COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), DB_RIBBONS, DB_DRAWS, DB_LAPLACE))

# ---- the ribbons must have been run from THESE draws ----------------------
rb <- readRDS(DB_RIBBONS); U <- readRDS(DB_DRAWS); pu <- attr(U, "provenance")
md5_draws <- unname(tools::md5sum(DB_DRAWS))
if (!grepl(md5_draws, rb$provenance$method, fixed = TRUE))
  stop("the ribbons were not run from ", DB_DRAWS, " (md5 ", md5_draws, " is not in their provenance)")
cat(sprintf("ribbons' mode %s (%s)\n", rb$provenance$mode, rb$provenance$struct))
# ---- GATE: a Laplace band is compared only at the SAME mode ---------------
if (DB_HAS_LAP) {
  lap <- readRDS(DB_LAPLACE)
  key <- function(b) paste(b$scenario, b$var, b$year)
  j <- match(key(rb$bands), key(lap$bands))
  if (anyNA(j)) stop("the Laplace band lacks ", sum(is.na(j)), " of the ribbons' cells")
  dcen <- max(abs(rb$bands$central - lap$bands$central[j]))
  cat(sprintf("Laplace band's mode %s; its central line vs the ribbons': max |diff| %.3g (tol %.3g)\n",
              lap$provenance$mode, dcen, rb$provenance$central_check_tol))
  if (!(dcen <= rb$provenance$central_check_tol))
    stop(sprintf("the Laplace band is not this mode's (central lines differ by up to %.3g): pass --laplace=none",
                 dcen))
}
M <- length(pu$chains); K <- pu$per_chain
stopifnot(nrow(U) == M * K, rb$provenance$n_draws == nrow(U))
cat(sprintf("%d chains x %d draws (window (%d, %d], drop %d); %d of %d draws ran, %d failed\n", M, K,
            pu$window[["lo"]], pu$window[["hi"]], pu$drop, rb$provenance$n_ok, rb$provenance$n_draws,
            rb$provenance$n_failed))
kd <- rb$key_draws
kd$chain <- (kd$draw - 1L) %/% K + 1L        # stored chain by chain: draw i belongs to chain ceiling(i / K)

# ---- one row per key cell -------------------------------------------------
cells <- unique(kd[, c("scenario", "var", "year")])
R <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  cc <- cells[i, ]
  d  <- kd[kd$scenario == cc$scenario & kd$var == cc$var & kd$year == cc$year, ]
  d  <- d[order(d$draw), ]
  per <- lapply(seq_len(M), function(k) d$value[d$chain == k])     # iteration order within each chain
  nmin <- min(lengths(per))
  X  <- vapply(per, function(v) v[seq_len(nmin)], numeric(nmin))   # equal lengths for R-hat
  qc <- vapply(per, function(v) stats::quantile(v, DB_PROBS, names = FALSE, type = 7), numeric(3))
  qp <- stats::quantile(d$value, DB_PROBS, names = FALSE, type = 7)
  sel <- function(b) b[b$scenario == cc$scenario & b$var == cc$var & b$year == cc$year, ]
  cb <- sel(rb$bands)
  lb <- if (DB_HAS_LAP) sel(lap$bands) else data.frame(q05 = NA_real_, q50 = NA_real_, q95 = NA_real_)
  stopifnot(nrow(cb) == 1L, nrow(lb) == 1L)
  # EARLY vs LATE half of every chain's window, pooled across chains: a band still WIDENING as the
  # chains run is the one sign of a gap they all share that this test can see
  wq <- function(v) diff(stats::quantile(v, DB_PROBS[c(1, 3)], names = FALSE, type = 7))
  early <- unlist(lapply(per, function(v) v[seq_len(length(v) %/% 2)]))
  late  <- unlist(lapply(per, function(v) v[(length(v) %/% 2 + 1L):length(v)]))
  data.frame(scenario = cc$scenario, var = cc$var, year = cc$year, units = DB_UNITS[[cc$var]], n = nrow(d),
             q05 = qp[1], q50 = qp[2], q95 = qp[3], width = qp[3] - qp[1],
             range_q05 = diff(range(qc[1, ])), range_q50 = diff(range(qc[2, ])), range_q95 = diff(range(qc[3, ])),
             rhat = mcd_rhat(X), ess_bulk = mcd_ess_bulk(X), ess_tail = mcd_ess_tail(X),
             lap_q05 = lb$q05, lap_q50 = lb$q50, lap_q95 = lb$q95, lap_width = lb$q95 - lb$q05,
             width_early = wq(early), width_late = wq(late),
             central = cb$central, chain_q50 =paste(sprintf("%.4g", qc[2, ]), collapse = " "),
             chain_q05 = paste(sprintf("%.4g", qc[1, ]), collapse = " "),
             chain_q95 = paste(sprintf("%.4g", qc[3, ]), collapse = " "), stringsAsFactors = FALSE)
}))
R$range_over_width <- pmax(R$range_q05, R$range_q50, R$range_q95) / R$width
R$width_over_laplace <- R$width / R$lap_width

# ---- report ---------------------------------------------------------------
cat("\n--- the 10-01 (l) cells, chain by chain (5 / 50 / 95 %) ---\n")
for (s in DB_SHOW) {
  r <- R[R$scenario == s[1] & R$var == s[2] & R$year == as.integer(s[3]), ]
  cat(sprintf("%s %s %s (%s): pooled %.4g / %.4g / %.4g, width %.4g;%s central %.4g\n",
              r$scenario, r$var, r$year, r$units, r$q05, r$q50, r$q95, r$width,
              if (DB_HAS_LAP) sprintf(" Laplace %.4g / %.4g / %.4g, width %.4g;", r$lap_q05, r$lap_q50,
                                      r$lap_q95, r$lap_width) else "", r$central))
  cat(sprintf("   chains q05 %s | q50 %s | q95 %s\n   between-chain range: q05 %.3g, q50 %.3g, q95 %.3g %s (%.0f %% of the width); R-hat %.3f, ESS bulk %.0f / tail %.0f\n",
              r$chain_q05, r$chain_q50, r$chain_q95, r$range_q05, r$range_q50, r$range_q95, r$units,
              100 * r$range_over_width, r$rhat, r$ess_bulk, r$ess_tail))
}
for (v in names(DB_UNITS)) {
  Rv <- R[R$var == v & R$year != min(R$year), ]   # 2100 and 2150, where the bands are wide enough to matter
  cat(sprintf("\n--- %s, all scenarios at %s ---\n", v, paste(sort(unique(Rv$year)), collapse = " and ")))
  cat(sprintf("between-chain range of a band edge or median: max %.3g %s (%s %s %d), median %.3g %s\n",
              max(pmax(Rv$range_q05, Rv$range_q50, Rv$range_q95)), DB_UNITS[[v]],
              Rv$scenario[which.max(pmax(Rv$range_q05, Rv$range_q50, Rv$range_q95))], v,
              Rv$year[which.max(pmax(Rv$range_q05, Rv$range_q50, Rv$range_q95))],
              stats::median(pmax(Rv$range_q05, Rv$range_q50, Rv$range_q95)), DB_UNITS[[v]]))
  cat(sprintf("  ... as a share of the pooled band's width: max %.0f %%, median %.0f %%\n",
              100 * max(Rv$range_over_width), 100 * stats::median(Rv$range_over_width)))
  cat(sprintf("R-hat of the cell: max %.3f, median %.3f; ESS bulk min %.0f, tail min %.0f [Vehtari et al. 2021's reference: R-hat < 1.01, ESS > %d]\n",
              max(Rv$rhat), stats::median(Rv$rhat), min(Rv$ess_bulk), min(Rv$ess_tail), 100L * M))
  if (DB_HAS_LAP)
    cat(sprintf("MCMC band width / Laplace band width: median %.2f, range %.2f-%.2f\n",
                stats::median(Rv$width_over_laplace), min(Rv$width_over_laplace), max(Rv$width_over_laplace)))
  # The ERROR BAR on that ratio: a 5-95 % width from ESS n has relative sd ~ 0.91 / sqrt(n) (two
  # near-independent quantile errors, each sqrt(p(1-p)/n) / phi(z_p)), so early / late halves of
  # ESS ~ n/2 each give a ratio sd of ~ 1.82 / sqrt(n). ⚠ No sign test across cells: every cell is
  # computed from the SAME draws, so cells widen or narrow TOGETHER and are not independent votes.
  lo <- Rv$width_late / Rv$width_early
  se <- 1.82 / sqrt(Rv$ess_tail)
  cat(sprintf("still WIDENING? late-half / early-half band width: median %.2f, range %.2f-%.2f; its own noise (1.82/sqrt(tail-ESS)) median %.2f, so median z %+.1f\n",
              stats::median(lo), min(lo), max(lo), stats::median(se), stats::median((lo - 1) / se)))
}
utils::write.csv(R, DB_CSV, row.names = FALSE)
cat(sprintf("\nwrote %s (%d cells)\n", DB_CSV, nrow(R)))
sink()
