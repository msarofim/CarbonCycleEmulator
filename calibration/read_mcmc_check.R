# =====================================================================
# read_mcmc_check.R -- read the MCMC check's chains (calibration/run_mcmc_check.R):
# convergence diagnostics for every fitted name and the log-posterior, the burn-in
# seen in each chain's log-posterior trace, the posterior against the Laplace
# approximation it checks, and the pooled draws as the u-matrix that
# `build_futures_ribbons.R --draws=` takes.
#
# IT REPORTS; IT DOES NOT RULE. Whether the chains have converged, how much more to
# discard, and whether a band ships are Marcus's calls (handoff 10-01e, step 7).
# The reference thresholds printed beside the numbers are Vehtari et al. (2021)'s
# recommendations, labeled as theirs: R-hat < 1.01, bulk- and tail-ESS > 100 per
# chain. The diagnostics are calibration/lib_mcmc_diag.R (tests/testthat/test-mcmc-diag.R).
#
# PARTIAL CHAINS (the staged plan, 10-01 q: stage 1 stops every chain by wall time,
# so they stop at different iterations). All chains are read over ONE iteration
# window, (adapt + drop, the shortest chain's last kept iteration], so R-hat compares
# equal lengths. The window is printed and recorded with the draws.
#
# Usage (repo root, on the Mac, with the chain files brought home from Torch):
#   Rscript calibration/read_mcmc_check.R [--dir=outputs/mcmc_check] [--drop=0] [--pool-thin=1] [--out=<dir>/pooled_u.rds]
# --drop: post-adaptation ITERATIONS to discard as further burn-in; read it off the
#   log-posterior blocks this script prints. Default 0.
# --pool-thin: keep every k-th kept sample of each chain in the POOLED DRAWS only (the band's input;
#   Marcus 2026-10-09: "Thin x2 within chain"). The diagnostics always read every kept sample. The pooled
#   draws stay chain by chain in iteration order; the rule is recorded in their provenance.
# =====================================================================
RD_ARGS <- commandArgs(trailingOnly = TRUE)
rd_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), RD_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_mcmc_diag.R"))

# ---- named constants: every label and filename derives from these --------
RD_DRIVER   <- "calibration/read_mcmc_check.R"
RD_DIR      <- rd_arg("dir", file.path("outputs", "mcmc_check"))
RD_DROP     <- as.integer(rd_arg("drop", 0L))
RD_POOL_THIN <- as.integer(rd_arg("pool-thin", 1L))
RD_OUT      <- rd_arg("out", file.path(RD_DIR, if (RD_POOL_THIN == 1L) "pooled_u.rds" else
                                                 sprintf("pooled_u_thin%d.rds", RD_POOL_THIN)))
RD_DATE     <- format(Sys.Date(), "%Y%m%d")
RD_LOG      <- file.path(RD_DIR, sprintf("read_%s_drop%d%s.log", RD_DATE, RD_DROP,
                                         if (RD_POOL_THIN == 1L) "" else sprintf("_pool%d", RD_POOL_THIN)))
RD_CSV      <- file.path(RD_DIR, sprintf("diag_%s_drop%d.csv", RD_DATE, RD_DROP))
RD_RHAT_REF <- 1.01        # Vehtari et al. 2021's recommendation, printed as theirs
RD_ESS_REF_PER_CHAIN <- 100L   # ditto, for bulk- and tail-ESS
RD_LP_BLOCK <- 5000L       # iterations per block in the log-posterior burn-in view
RD_SHOW     <- 10L         # rows shown in each worst-first list
RD_COMMIT <- ccx_git_stamp()
stopifnot(RD_DROP >= 0L, RD_POOL_THIN >= 1L)
sink(RD_LOG, split = TRUE)
cat(sprintf("=== %s @%s, %s: %s, drop %d ===\n", RD_DRIVER, RD_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            RD_DIR, RD_DROP))

# ---- the chains, and the provenance they must share -----------------------
fs <- sort(list.files(RD_DIR, pattern = "^chain_[0-9]+\\.rds$", full.names = TRUE))
if (length(fs) < 2L) stop("R-hat needs at least two chains; found ", length(fs), " in ", RD_DIR)
S <- lapply(fs, readRDS); M <- length(S)
P <- lapply(S, `[[`, "provenance"); p1 <- P[[1]]
# chain, seed and host differ by design; so does start_redraws (2026-10-13 j: the redraw-until-finite start rule records
# how many draws EACH chain's start took -- 2, 2, 0, 0 at hilda31w), found by the 10-13 dry run. Nothing else may.
RD_PER_CHAIN <- c("chain", "seed", "host", "start_redraws")
for (k in seq_len(M)[-1]) {
  same <- vapply(setdiff(names(p1), RD_PER_CHAIN),
                 function(n) identical(P[[k]][[n]], p1[[n]]), logical(1))
  if (!all(same)) stop(basename(fs[k]), " was not run like ", basename(fs[1]), ": ",
                       paste(names(same)[!same], collapse = ", "))
}
# build_futures_ribbons.R decodes supplied u-draws against the CURRENT canonical (its transforms, bands,
# structure and pins), so the draws are written only if that is still exactly what the chains sampled.
# The structure and pins come through the ONE resolver, ccx_mode_base() (test-mode-struct-lint.R).
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
mb <- ccx_mode_base(md)
held_now <- unlist(attr(mb, "pins")); held_ran <- unlist(p1$held)
same <- c(name = identical(p1$mode, CCX_MODE_CANONICAL), par_mode = identical(p1$mode_par, md$par_mode),
          struct = identical(attr(mb, "struct"), p1$struct),
          pins = identical(names(held_now), names(held_ran)) && all(held_now == held_ran))
same_mode <- all(same)
cat(sprintf("%d chains of mode %s (%s), commit %s; n %d, adapt %d, thin %d; canonical now %s%s\n", M, p1$mode,
            p1$struct, p1$commit, p1$n, p1$adapt, p1$thin, CCX_MODE_CANONICAL,
            if (same_mode) " (the same mode, structure and pins)" else
              paste0(" -- ⛔ NOT what the chains sampled (", paste(names(same)[!same], collapse = ", "),
                     "): no draws will be written")))
for (k in seq_len(M)) {
  s <- S[[k]]; pa <- s$iter - p1$adapt
  cat(sprintf("  %s: seed %d, %s; iter %d/%d%s; kept %d; acceptance %.3f, post-adapt %s; last logpost %.2f\n",
              basename(fs[k]), P[[k]]$seed, P[[k]]$host, s$iter, p1$n, if (s$iter < p1$n) " (PARTIAL)" else "",
              nrow(s$samples), s$n_acc / s$iter, if (pa > 0) sprintf("%.3f", s$n_acc_post / pa) else "-", s$lp))
}

# ---- the burn-in view: block means of every iteration's log-posterior -----
d <- length(p1$u0)
gq <- p1$mode_logpost - stats::qchisq(c(0.5, 0.975, 0.025), d) / 2
cat(sprintf("\nlog-posterior by %d-iteration block (adaptation ends at %d). If the posterior were the Laplace\n",
            RD_LP_BLOCK, p1$adapt))
cat(sprintf("Gaussian, a converged chain would sit at mode - chi2_%d/2: median %.1f, 95%% [%.1f, %.1f]\n", d, gq[1], gq[2], gq[3]))
nt <- max(vapply(S, function(s) length(s$lp_trace), integer(1)))
nb <- ceiling(nt / RD_LP_BLOCK)
B <- vapply(S, function(s) vapply(seq_len(nb), function(b) {
  i <- ((b - 1L) * RD_LP_BLOCK + 1L):(b * RD_LP_BLOCK); i <- i[i <= length(s$lp_trace)]
  if (length(i)) mean(s$lp_trace[i]) else NA_real_ }, numeric(1)), numeric(nb))
B <- matrix(B, nb, M, dimnames = list(sprintf("%6d-%6d", (seq_len(nb) - 1L) * RD_LP_BLOCK + 1L,
                                              pmin(seq_len(nb) * RD_LP_BLOCK, nt)),
                                      sprintf("chain_%d", vapply(P, `[[`, integer(1), "chain"))))
print(round(B, 1))

# ---- one iteration window for every chain ---------------------------------
lo  <- p1$adapt + RD_DROP
hi  <- min(vapply(S, function(s) max(c(s$samples_iter, 0L)), numeric(1)))
idx <- lapply(S, function(s) which(s$samples_iter > lo & s$samples_iter <= hi))
K   <- unique(lengths(idx))
stopifnot(length(K) == 1L)          # kept at adapt + j * thin in every chain, so the counts agree
if (K < 4L) stop(sprintf("only %d kept samples per chain in the window (%d, %d]: nothing to diagnose", K, lo, hi))
cat(sprintf("\nwindow: iterations (%d, %d], %d kept samples per chain (thin %d), %d pooled\n", lo, hi, K, p1$thin, K * M))

# ---- diagnostics: every fitted name, then the log-posterior ----------------
nm  <- colnames(S[[1]]$samples)
ext <- function(get) vapply(seq_len(M), function(k) get(k)[idx[[k]]], numeric(K))
D <- do.call(rbind, c(lapply(nm, function(n) mcd_summary(ext(function(k) S[[k]]$samples[, n]), n)),
                      list(mcd_summary(ext(function(k) S[[k]]$samples_lp), "logpost"))))
lsd <- sqrt(diag(p1$laplace_cov))[nm]
D$laplace_sd    <- c(lsd, NA)
D$sd_over_laplace <- D$sd / D$laplace_sd                          # u-space
D$shift_in_laplace_sd <- c((D$mean[seq_along(nm)] - p1$u0[nm]) / lsd, NA)
ess_ref <- RD_ESS_REF_PER_CHAIN * M
cat(sprintf("\nR-hat: max %.4f (%s); %d of %d quantities above %.2f [Vehtari et al. 2021's reference]\n",
            max(D$rhat), D$name[which.max(D$rhat)], sum(D$rhat > RD_RHAT_REF), nrow(D), RD_RHAT_REF))
cat(sprintf("ESS: min bulk %.0f (%s), min tail %.0f (%s); %d below %d in either [their reference: %d per chain]\n",
            min(D$ess_bulk), D$name[which.min(D$ess_bulk)], min(D$ess_tail), D$name[which.min(D$ess_tail)],
            sum(pmin(D$ess_bulk, D$ess_tail) < ess_ref), ess_ref, RD_ESS_REF_PER_CHAIN))
fmt <- function(x) { x[] <- lapply(x, function(v) if (is.numeric(v)) signif(v, 4) else v); x }
cat("\nworst R-hat first:\n"); print(fmt(head(D[order(-D$rhat), c("name", "rhat", "ess_bulk", "ess_tail")], RD_SHOW)), row.names = FALSE)
cat("\nthe posterior against the Laplace approximation (u-space), largest departures first:\n")
Dp <- D[seq_along(nm), ]
print(fmt(head(Dp[order(-abs(log(Dp$sd_over_laplace))), c("name", "sd_over_laplace", "shift_in_laplace_sd", "rhat", "ess_bulk")],
               RD_SHOW)), row.names = FALSE)
utils::write.csv(D, RD_CSV, row.names = FALSE)
cat(sprintf("\nwrote %s\n", RD_CSV))

# ---- the pooled draws, for build_futures_ribbons.R --draws= -----------------
if (same_mode) {
  # --pool-thin: a sample kept at iteration adapt + thin * j is pooled when j %% pool_thin == 0 -- one grid for
  # every chain, so the per-chain counts agree
  pidx <- lapply(seq_len(M), function(k) {
    i <- idx[[k]]; i[((S[[k]]$samples_iter[i] - p1$adapt) %/% p1$thin) %% RD_POOL_THIN == 0L] })
  KP <- unique(lengths(pidx)); stopifnot(length(KP) == 1L, KP >= 1L)
  if (RD_POOL_THIN > 1L)
    cat(sprintf("pooled draws thinned x%d within each chain: %d of %d kept samples per chain\n", RD_POOL_THIN, KP, K))
  U <- do.call(rbind, lapply(seq_len(M), function(k) S[[k]]$samples[pidx[[k]], , drop = FALSE]))
  stopifnot(identical(colnames(U), md$param_names), all(is.finite(U)))
  attr(U, "provenance") <- list(reader = RD_DRIVER, reader_commit = RD_COMMIT, date = RD_DATE,
    chains = basename(fs), chain_md5 = unname(tools::md5sum(fs)), chain_seeds = vapply(P, `[[`, integer(1), "seed"),
    chain_commit = p1$commit, chain_extended = p1$extended, mode = p1$mode, window = c(lo = lo, hi = hi),
    drop = RD_DROP, per_chain = KP, pool_thin = RD_POOL_THIN, thin = p1$thin, adapt = p1$adapt,
    pool_rule = "a sample kept at iteration adapt + thin * j is pooled when j mod pool_thin == 0",
    order = "chain by chain, iteration order within each")
  saveRDS(U, RD_OUT)
  cat(sprintf("wrote %s: %d draws x %d names (md5 %s)\n", RD_OUT, nrow(U), ncol(U), unname(tools::md5sum(RD_OUT))))
} else cat("⛔ no draws written: build_futures_ribbons.R would decode them against a different canonical\n")
sink()
