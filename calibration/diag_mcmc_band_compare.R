# =====================================================================
# diag_mcmc_band_compare.R -- successive reads of the SAME MCMC chains, SIDE BY SIDE, with a held
# precedent beside them (handoff 2026-10-09 §3 item 2: "Put the three reads side by side: 50k / 100k /
# 200k, with hilda33d's held stage 1 as the precedent"; Marcus 10-09, "Extend to 200k").
#
# It READS what the landings already wrote and computes nothing about the model:
#   (1) the parameters (read_mcmc_check.R's diag csv): R-hat max and which, how many above the
#       reference, ESS bulk / tail min and which;
#   (2) the band at the key years (diag_mcmc_band_by_chain.R's csv), CO2 and GMST: the between-chain
#       range IN THE UNITS beside the width ([[rhat_denominator_forgives]]: a ratio forgives, a range in
#       ppm does not), the cells' R-hat and ESS, and late / early half width;
#   (3) between successive reads of the same chains: each cell's width ratio and median shift;
#   (4) the key cells' 5 / 50 / 95 %;
#   (5) the chain files: each earlier snapshot must be an exact PREFIX of the next one (kept samples,
#       their iterations, the log-posterior trace). For 100k -> 200k this is the extension's
#       bit-exactness on the real chains (00b1c09 showed it on a short chain only).
# ⚠ A read thinned within chain (--pool-thin) and an unthinned one differ in ESS-dependent noise; the
#   cells' R-hat / ESS come from the pooled draws, the parameters' from every sample. Compare widths and
#   quantiles across reads, not noise.
# ⚠ The precedent is a DIFFERENT mode's chains: it enters (1), (2) and (4) only, never (3) or (5).
#
# Usage (repo root):
#   Rscript calibration/diag_mcmc_band_compare.R \
#     --reads=50k@<snapshot dir>@<by-chain csv>,100k@...,200k@... \
#     [--precedent=stage1@<snapshot dir>@<by-chain csv>] --tag=hilda29e [--log=<path>.log; the csv sits beside it]
# Each snapshot dir holds chain_<k>.rds and exactly one diag_*_drop0.csv.
# =====================================================================
CMP_ARGS <- commandArgs(trailingOnly = TRUE)
cmp_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), CMP_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
CMP_VARS      <- c("co2_ppm", "gmst")
CMP_UNITS     <- c(co2_ppm = "ppm", gmst = "degC")
CMP_YEARS     <- c(2100L, 2150L)
CMP_RHAT_REF  <- 1.01                      # Vehtari et al. 2021's reference
CMP_KEY_CELLS <- data.frame(scenario = c("vvH", "vvLN", "vvVL", "vvM"),
                            var = c("co2_ppm", "co2_ppm", "co2_ppm", "gmst"),
                            year = c(2150L, 2150L, 2150L, 2100L), stringsAsFactors = FALSE)
CMP_PREFIX_FIELDS <- c("samples", "samples_iter", "samples_lp")
CMP_TAG  <- cmp_arg("tag", "hilda29e")
CMP_DATE <- format(Sys.Date(), "%Y%m%d")
CMP_LOG  <- cmp_arg("log", file.path("outputs", "diagnostics", sprintf("mcmc_band_compare_%s_%s.log", CMP_TAG, CMP_DATE)))
CMP_CSV  <- sub("\\.log$", ".csv", CMP_LOG)

cmp_parse <- function(s) {
  if (is.na(s) || !nzchar(s)) return(list())
  lapply(strsplit(strsplit(s, ",", fixed = TRUE)[[1]], "@", fixed = TRUE), function(p) {
    stopifnot(length(p) == 3L, dir.exists(p[2]), file.exists(p[3]))
    dg <- Sys.glob(file.path(p[2], "diag_*_drop0.csv"))
    if (length(dg) != 1L) stop(sprintf("%s: need exactly one diag_*_drop0.csv, found %d", p[2], length(dg)))
    list(label = p[1], dir = p[2], bychain = p[3], diag = dg)
  })
}
READS <- cmp_parse(cmp_arg("reads", NA))
PREC  <- cmp_parse(cmp_arg("precedent", NA))
if (length(READS) < 2L) stop("--reads needs at least two reads of the same chains")
ALL <- c(PREC, READS)
for (i in seq_along(ALL)) {
  ALL[[i]]$B <- utils::read.csv(ALL[[i]]$bychain, stringsAsFactors = FALSE)
  ALL[[i]]$D <- utils::read.csv(ALL[[i]]$diag, stringsAsFactors = FALSE)
}
PREC  <- ALL[seq_along(PREC)]; READS <- ALL[length(PREC) + seq_along(READS)]

dir.create(dirname(CMP_LOG), showWarnings = FALSE, recursive = TRUE)
sink(CMP_LOG, split = TRUE)
cat(sprintf("=== calibration/diag_mcmc_band_compare.R @%s, %s ===\n",
            system("git rev-parse --short HEAD", intern = TRUE), format(Sys.time(), "%Y-%m-%d %H:%M")))
for (r in ALL) cat(sprintf("%-8s %s | %s | %s%s\n", r$label, r$dir, basename(r$diag), r$bychain,
                           if (r$label %in% vapply(PREC, `[[`, "", "label")) "  [precedent: another mode]" else ""))

# ---- (1) the parameters ----------------------------------------------------
cat(sprintf("\n--- (1) the parameters (every kept sample; reference R-hat < %.2f) ---\n", CMP_RHAT_REF))
cat(sprintf("%-8s %6s %-10s %9s %10s %-10s %9s %-10s\n", "read", "n/ch", "", "R-hat max", "> ref", "", "ESS bulk", "tail min"))
P1 <- do.call(rbind, lapply(ALL, function(r) {
  D <- r$D
  i <- which.max(D$rhat); jb <- which.min(D$ess_bulk); jt <- which.min(D$ess_tail)
  n_ch <- nrow(readRDS(file.path(r$dir, "chain_1.rds"))$samples)
  cat(sprintf("%-8s %6d R-hat %.3f (%s); %d of %d > %.2f; ESS bulk min %.0f (%s), tail min %.0f (%s)\n",
              r$label, n_ch, D$rhat[i], D$name[i], sum(D$rhat > CMP_RHAT_REF), nrow(D), CMP_RHAT_REF,
              D$ess_bulk[jb], D$name[jb], D$ess_tail[jt], D$name[jt]))
  data.frame(read = r$label, section = "params", key = "summary", rhat_max = D$rhat[i], rhat_max_name = D$name[i],
             n_above = sum(D$rhat > CMP_RHAT_REF), ess_bulk_min = D$ess_bulk[jb], ess_tail_min = D$ess_tail[jt],
             stringsAsFactors = FALSE)
}))
WATCH <- c("h_ml", "beta_max", "ndep_ret", "fert_k", "luc_scale", "logpost")
cat("\nthe slow names, R-hat / ESS bulk by read:\n")
for (nm in WATCH) {
  cat(sprintf("  %-10s", nm))
  for (r in ALL) {
    k <- match(nm, r$D$name)
    cat(if (is.na(k)) sprintf(" | %-8s  --", r$label) else sprintf(" | %-8s %.3f / %4.0f", r$label, r$D$rhat[k], r$D$ess_bulk[k]))
  }
  cat("\n")
}

# ---- (2) the band at the key years -----------------------------------------
cat(sprintf("\n--- (2) the band at %s: between-chain range IN THE UNITS beside the width ---\n",
            paste(CMP_YEARS, collapse = " and ")))
sel_years <- function(B, v) B[B$var == v & B$year %in% CMP_YEARS, ]
rng <- function(B) pmax(B$range_q05, B$range_q50, B$range_q95)
P2 <- NULL
for (v in CMP_VARS) {
  cat(sprintf("%s (%s):\n", v, CMP_UNITS[[v]]))
  for (r in ALL) {
    B <- sel_years(r$B, v); g <- rng(B); lo <- B$width_late / B$width_early
    imax <- which.max(g)
    cat(sprintf("  %-8s draws/cell %5d | range max %.3g (%s %d), median %.3g | share max %.0f %%, median %.0f %% | cell R-hat max %.3f, median %.3f | ESS bulk min %.0f | late/early median %.2f (%.2f-%.2f)\n",
                r$label, B$n[1], g[imax], B$scenario[imax], B$year[imax], stats::median(g),
                100 * max(B$range_over_width), 100 * stats::median(B$range_over_width),
                max(B$rhat), stats::median(B$rhat), min(B$ess_bulk), stats::median(lo), min(lo), max(lo)))
    P2 <- rbind(P2, data.frame(read = r$label, section = "band", key = v, range_max = g[imax],
                               range_max_cell = sprintf("%s %d", B$scenario[imax], B$year[imax]),
                               range_median = stats::median(g), share_max = max(B$range_over_width),
                               share_median = stats::median(B$range_over_width), cell_rhat_max = max(B$rhat),
                               cell_rhat_median = stats::median(B$rhat), cell_ess_bulk_min = min(B$ess_bulk),
                               late_early_median = stats::median(lo), stringsAsFactors = FALSE))
  }
}

# ---- (3) successive reads of the same chains -------------------------------
cat("\n--- (3) successive reads of the SAME chains: per-cell width ratio and median shift ---\n")
P3 <- NULL
for (i in seq_len(length(READS) - 1L)) {
  a <- READS[[i]]; b <- READS[[i + 1L]]
  for (v in CMP_VARS) {
    A <- sel_years(a$B, v); Bb <- sel_years(b$B, v)
    m <- merge(A, Bb, by = c("scenario", "var", "year"), suffixes = c(".a", ".b"))
    stopifnot(nrow(m) == nrow(A), nrow(m) == nrow(Bb))
    wr <- m$width.b / m$width.a; sh <- m$q50.b - m$q50.a; k <- which.max(abs(sh))
    cat(sprintf("  %s -> %s, %s: width x%.3f median (%.2f-%.2f); median shift %+.3g median, max |%.3g| %s (%s %d)\n",
                a$label, b$label, v, stats::median(wr), min(wr), max(wr), stats::median(sh), abs(sh[k]),
                CMP_UNITS[[v]], m$scenario[k], m$year[k]))
    P3 <- rbind(P3, data.frame(read = sprintf("%s->%s", a$label, b$label), section = "successive", key = v,
                               width_ratio_median = stats::median(wr), width_ratio_min = min(wr),
                               width_ratio_max = max(wr), shift_median = stats::median(sh),
                               shift_absmax = abs(sh[k]), shift_absmax_cell = sprintf("%s %d", m$scenario[k], m$year[k]),
                               stringsAsFactors = FALSE))
  }
}

# ---- (4) the key cells -----------------------------------------------------
cat("\n--- (4) the key cells, pooled 5 / 50 / 95 % (width) | chain medians | between-chain range ---\n")
P4 <- NULL
for (j in seq_len(nrow(CMP_KEY_CELLS))) {
  kc <- CMP_KEY_CELLS[j, ]
  cat(sprintf("%s %s %d (%s):\n", kc$scenario, kc$var, kc$year, CMP_UNITS[[kc$var]]))
  for (r in ALL) {
    x <- r$B[r$B$scenario == kc$scenario & r$B$var == kc$var & r$B$year == kc$year, ]
    if (nrow(x) != 1L) { cat(sprintf("  %-8s (no such cell)\n", r$label)); next }
    cat(sprintf("  %-8s %.4g / %.4g / %.4g (%.3g); central %.4g | chains %s | range %.3g (%.0f %% of width); R-hat %.3f\n",
                r$label, x$q05, x$q50, x$q95, x$width, x$central, x$chain_q50, max(x$range_q05, x$range_q50, x$range_q95),
                100 * x$range_over_width, x$rhat))
    P4 <- rbind(P4, data.frame(read = r$label, section = "cell", key = sprintf("%s %s %d", kc$scenario, kc$var, kc$year),
                               q05 = x$q05, q50 = x$q50, q95 = x$q95, width = x$width, central = x$central,
                               range = max(x$range_q05, x$range_q50, x$range_q95), rhat = x$rhat,
                               stringsAsFactors = FALSE))
  }
}

# ---- (5) the chain files: each earlier read an exact prefix of the next ----
cat(sprintf("\n--- (5) the chain files: is each earlier read an exact PREFIX of the next? (%s, lp_trace) ---\n",
            paste(CMP_PREFIX_FIELDS, collapse = ", ")))
P5 <- NULL; prefix_ok <- TRUE
for (i in seq_len(length(READS) - 1L)) {
  a <- READS[[i]]; b <- READS[[i + 1L]]
  for (k in 1:4) {
    A <- readRDS(file.path(a$dir, sprintf("chain_%d.rds", k))); Bb <- readRDS(file.path(b$dir, sprintf("chain_%d.rds", k)))
    na <- length(A$samples_iter)
    same <- c(samples = identical(A$samples, Bb$samples[seq_len(na), , drop = FALSE]),
              samples_iter = identical(A$samples_iter, Bb$samples_iter[seq_len(na)]),
              samples_lp = identical(A$samples_lp, Bb$samples_lp[seq_len(na)]),
              lp_trace = identical(A$lp_trace[seq_len(A$iter)], Bb$lp_trace[seq_len(A$iter)]),
              seed = identical(A$provenance$seed, Bb$provenance$seed))
    ok <- all(same); prefix_ok <- prefix_ok && ok
    cat(sprintf("  %s -> %s chain %d: iter %d -> %d, kept %d -> %d; %s%s\n", a$label, b$label, k, A$iter, Bb$iter,
                na, length(Bb$samples_iter), if (ok) "IDENTICAL prefix" else "DIFFERS in ",
                if (ok) "" else paste(names(same)[!same], collapse = ", ")))
    P5 <- rbind(P5, data.frame(read = sprintf("%s->%s", a$label, b$label), section = "prefix", key = sprintf("chain_%d", k),
                               identical = ok, stringsAsFactors = FALSE))
  }
}
cat(sprintf("prefix check: %s\n", if (prefix_ok) "PASS (every chain)" else "FAIL"))

cols <- unique(unlist(lapply(list(P1, P2, P3, P4, P5), names)))
pad <- function(d) { for (cc in setdiff(cols, names(d))) d[[cc]] <- NA; d[cols] }
OUT <- do.call(rbind, lapply(list(P1, P2, P3, P4, P5), pad))
OUT$provenance <- sprintf("calibration/diag_mcmc_band_compare.R @%s; reads %s; precedent %s",
                          system("git rev-parse --short HEAD", intern = TRUE),
                          paste(sprintf("%s=%s", vapply(READS, `[[`, "", "label"), vapply(READS, `[[`, "", "dir")), collapse = " "),
                          if (length(PREC)) paste(sprintf("%s=%s", vapply(PREC, `[[`, "", "label"), vapply(PREC, `[[`, "", "dir")), collapse = " ") else "none")
utils::write.csv(OUT, CMP_CSV, row.names = FALSE)
cat(sprintf("\nwrote %s (%d rows)\n", CMP_CSV, nrow(OUT)))
sink()
if (!prefix_ok) quit(status = 2)
