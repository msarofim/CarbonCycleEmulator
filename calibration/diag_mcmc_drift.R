# =====================================================================
# diag_mcmc_drift.R -- are the MCMC check's chains still SPREADING, and does the direction that
# has not converged move the FUTURES? (2026-10-09, the 100k read at hilda29e.)
#
# The 100k read (read_mcmc_check.R) showed three signs pointing one way: the worst R-hat is h_ml
# (1.098), h_ml's posterior sits further below the mode than at 50k, and every chain's log-posterior
# blocks sit lower after ~65k. diag_mcmc_band_by_chain.R's late/early band-width ratio was > 1 in
# every cell (median 1.08). This driver REPORTS, per chain:
#   (1) the drift: the median and 5 / 95 % of each DRIFT_NAMES name by DRIFT_BLOCK-iteration block,
#       in physical units, and the share of h_ml draws within DRIFT_FLOOR_NEAR of its band's floor;
#   (2) the log-posterior's mean in the window's first and second halves;
#   (3) the leverage: across the pooled draws, each name's linear effect on the futures key cells
#       (ppm or degC per posterior sd, from one multiple regression in standardized names), and the
#       cells' late-minus-early median shift beside the shift that leverage x name drift predicts.
# ⚠ Cells and names are computed from the SAME draws, so they co-move: not independent votes.
# It REPORTS; Marcus rules.
#
# Usage (repo root):
#   Rscript calibration/diag_mcmc_drift.R --dir=<snapshot with chain_*.rds> --ribbons=<the band built from the
#       pooled draws> [--pooled=<dir>/pooled_u.rds] [--tag=hilda29e_final] [--names=h_ml,beta_max,...]
# The pooled draws may be thinned within each chain (read_mcmc_check.R --pool-thin): the join applies the
# reader's own rule, read from their provenance. The drift sections (1)-(2) read every kept sample.
# =====================================================================
DR_ARGS <- commandArgs(trailingOnly = TRUE)
dr_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), DR_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants: every label and filename derives from these --------
DR_DRIVER  <- "calibration/diag_mcmc_drift.R"
DR_DIR     <- dr_arg("dir", "")
DR_RIBBONS <- dr_arg("ribbons", "")
DR_POOLED  <- dr_arg("pooled", file.path(DR_DIR, "pooled_u.rds"))
DR_TAG     <- dr_arg("tag", "hilda29e_final")
DR_DATE    <- format(Sys.Date(), "%Y%m%d")
DR_LOG     <- file.path("outputs", "diagnostics", sprintf("mcmc_drift_%s_%s.log", DR_TAG, DR_DATE))
DR_RDS     <- sub("\\.log$", ".rds", DR_LOG)
# --names=a,b,...: the names to follow. Default: hilda29e's five worst R-hats at 100k (its record reproduces).
# hilda31w's five worst (2026-10-14 a) include the seasonal-lag triplet, which is collinear (r +0.96 between
# seas_T_lag and seas_lag_p_NH): the leverage regression's per-name coefficients then trade off between them, and
# only their combined predicted shift is well determined. h_ml is required (the floor share reads it).
DRIFT_NAMES <- strsplit(dr_arg("names", "h_ml,beta_max,ndep_ret,fert_k,luc_scale"), ",", fixed = TRUE)[[1]]
stopifnot("h_ml" %in% DRIFT_NAMES, !anyDuplicated(DRIFT_NAMES))
DRIFT_BLOCK <- 10000L                      # iterations per block
DRIFT_FLOOR_NEAR <- 5                      # m: "near the floor" (as the 50k read, CHANGELOG 10-08 k)
DR_PROBS   <- c(0.05, 0.50, 0.95)
DR_CELLS   <- list(c("vvH", "co2_ppm", 2150L), c("vvLN", "co2_ppm", 2150L), c("vvHL", "co2_ppm", 2100L),
                   c("vvLN", "gmst", 2150L), c("vvM", "gmst", 2100L))   # the 10-01 (l) cell + the worst by share
DR_COMMIT  <- ccx_git_stamp()
stopifnot(nzchar(DR_DIR), nzchar(DR_RIBBONS), file.exists(DR_RIBBONS))
sink(DR_LOG, split = TRUE)
cat(sprintf("=== %s @%s, %s ===\ndir %s\nribbons %s\n", DR_DRIVER, DR_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            DR_DIR, DR_RIBBONS))

# ---- the chains' space: the canonical resolved as run_mcmc_check.R ran them ---------
# Converted 2026-10-10 (Marcus: "Convert the driver (Recommended)"; test-mode-struct-lint.R). This
# driver runs NO model, so the base is not run: it is read for the values the chains HELD, below.
fs <- sort(list.files(DR_DIR, pattern = "^chain_[0-9]+\\.rds$", full.names = TRUE))
S <- lapply(fs, readRDS); M <- length(S)
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
DR_BASE <- ccx_mode_base(md)               # the file's OWN structure, with its pins in the base
invisible(ccx_apply_gate(ccx_mode_struct(md)))
DR_PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(DR_PINS))
ccx_require_param_set(md, DR_DRIVER)
invisible(ccx_adopt_mode_band(md))         # the file's h_ml / kz bands, before any decode (as build_futures_ribbons.R)
ccx_check_mode_decode(md)                  # GATE: u_mode decodes to the file's own par_mode
# GATE: every chain ran in THIS space -- the mode and its structure, the fitted names in order, its
# par_mode, and held values equal to what the resolved base carries for each held name.
dr_held_ok <- function(h) identical(names(h), names(DR_PINS)) &&
  identical(as.numeric(h), vapply(names(h), function(n) as.numeric(DR_BASE[[n]]), numeric(1), USE.NAMES = FALSE))
for (k in seq_len(M)) {
  pv_k <- S[[k]]$provenance
  if (!(identical(pv_k$mode, CCX_MODE_CANONICAL) && identical(pv_k$struct, ccx_mode_struct(md)) &&
        identical(colnames(S[[k]]$samples), CCX_PARAM_NAMES) && identical(pv_k$mode_par, md$par_mode) &&
        dr_held_ok(pv_k$held)))
    stop(basename(fs[k]), " was not run in ", CCX_MODE_CANONICAL, "'s space (mode, structure, fitted names, ",
         "par_mode or held values differ): its samples would decode wrongly here")
}
hml_floor <- md$hml_bound[1]
cat(sprintf("mode %s; h_ml band [%g, %g] (mode %.2f m)\n", CCX_MODE_CANONICAL, md$hml_bound[1], md$hml_bound[2],
            md$par_mode$h_ml))
dec <- lapply(seq_len(M), function(k) {
  s <- S[[k]]
  P <- t(apply(s$samples, 1, function(u) unlist(ccx_unc_to_par(stats::setNames(u, colnames(s$samples)))[DRIFT_NAMES])))
  data.frame(chain = k, iter = s$samples_iter, lp = s$samples_lp, P, check.names = FALSE)
})
D <- do.call(rbind, dec)
adapt <- S[[1]]$provenance$adapt; n_it <- S[[1]]$provenance$n
mid <- adapt + (n_it - adapt) / 2

# ---- (1) the drift, block by block ------------------------------------------
D$block <- adapt + DRIFT_BLOCK * ((D$iter - adapt - 1L) %/% DRIFT_BLOCK)
cat(sprintf("\n--- (1) the drift: per-chain median [5 %%, 95 %%] by %d-iteration block (window (%d, %d]) ---\n",
            DRIFT_BLOCK, adapt, n_it))
for (n in DRIFT_NAMES) {
  cat(sprintf("%s (mode %.4g):\n", n, md$par_mode[[n]]))
  for (b in sort(unique(D$block))) {
    q <- vapply(seq_len(M), function(k) {
      v <- D[[n]][D$chain == k & D$block == b]; stats::quantile(v, DR_PROBS, names = FALSE)
    }, numeric(3))
    pq <- stats::quantile(D[[n]][D$block == b], DR_PROBS, names = FALSE)
    cat(sprintf("  (%6d, %6d]  pooled %.4g [%.4g, %.4g]   chains %s\n", b, b + DRIFT_BLOCK, pq[2], pq[1], pq[3],
                paste(sprintf("%.4g", q[2, ]), collapse = " ")))
  }
}
near <- function(sel) mean(D$h_ml[sel] < hml_floor + DRIFT_FLOOR_NEAR)
cat(sprintf("h_ml within %g m of the %g floor: first half %.1f %%, second half %.1f %%; per chain (second half) %s\n",
            DRIFT_FLOOR_NEAR, hml_floor, 100 * near(D$iter <= mid), 100 * near(D$iter > mid),
            paste(sprintf("%.1f %%", 100 * vapply(seq_len(M), function(k) near(D$chain == k & D$iter > mid), 0)),
                  collapse = " ")))

# ---- (2) the log-posterior, half by half ------------------------------------
cat(sprintf("\n--- (2) the log-posterior's mean, iterations (%d, %g] vs (%g, %d] ---\n", adapt, mid, mid, n_it))
lph <- t(vapply(seq_len(M), function(k) c(mean(D$lp[D$chain == k & D$iter <= mid]),
                                           mean(D$lp[D$chain == k & D$iter > mid])), numeric(2)))
for (k in seq_len(M)) cat(sprintf("  chain %d: %.2f -> %.2f (%+.2f)\n", k, lph[k, 1], lph[k, 2], lph[k, 2] - lph[k, 1]))
cat(sprintf("  pooled: %.2f -> %.2f (%+.2f)\n", mean(lph[, 1]), mean(lph[, 2]), mean(lph[, 2] - lph[, 1])))

# ---- (3) the leverage on the futures ---------------------------------------
rb <- readRDS(DR_RIBBONS)
pu <- DR_POOLED
if (!grepl(unname(tools::md5sum(pu)), rb$provenance$method, fixed = TRUE))
  stop("the ribbons were not run from ", pu)
U <- readRDS(pu); pv <- attr(U, "provenance"); K <- pv$per_chain
pt <- if (is.null(pv$pool_thin)) 1L else pv$pool_thin      # draws pooled before --pool-thin existed: every sample
thin <- S[[1]]$provenance$thin
# the reader's rule (read_mcmc_check.R): the window (lo, hi], and a sample kept at iteration adapt + thin * j is
# pooled when j mod pool_thin == 0; the pooled draws are chain by chain in iteration order
in_pool <- function(it) it > pv$window[["lo"]] & it <= pv$window[["hi"]] & ((it - adapt) %/% thin) %% pt == 0L
D <- D[order(D$chain, D$iter), ]
DP <- D[in_pool(D$iter), ]; DP$draw <- seq_len(nrow(DP))
stopifnot(M * K == nrow(U), nrow(DP) == nrow(U))
# GATE: the pooled draws ARE those samples in that order, so draw i's futures belong to DP's row i
X <- do.call(rbind, lapply(S, function(s) s$samples[in_pool(s$samples_iter), , drop = FALSE]))
if (!(identical(dim(U), dim(X)) && identical(colnames(U), colnames(X)) && identical(as.vector(U), as.vector(X))))
  stop(basename(pu), " is not the chains' samples under the reader's rule: the draw-to-row join would be wrong")
cat(sprintf("\npooled draws %s: %d per chain (pool thin %d), joined to their samples\n", pu, K, pt))
Z <- scale(as.matrix(DP[, DRIFT_NAMES]))
cat("\n--- (3) leverage: each name's effect per posterior sd (one regression, standardised names), and the late - early shift ---\n")
LV <- do.call(rbind, lapply(DR_CELLS, function(cl) {
  kd <- rb$key_draws[rb$key_draws$scenario == cl[1] & rb$key_draws$var == cl[2] & rb$key_draws$year == as.integer(cl[3]), ]
  y <- kd$value[match(DP$draw, kd$draw)]
  fit <- stats::lm(y ~ Z)
  b <- stats::coef(fit)[-1]; names(b) <- DRIFT_NAMES
  late <- DP$iter > mid
  dz <- colMeans(Z[late, , drop = FALSE]) - colMeans(Z[!late, , drop = FALSE])
  dy <- stats::median(y[late]) - stats::median(y[!late])
  units <- if (cl[2] == "gmst") "degC" else "ppm"
  w <- diff(stats::quantile(y, DR_PROBS[c(1, 3)], names = FALSE))
  cat(sprintf("%s %s %s (%s): 5-95 %% width %.4g; R2 %.2f\n   per posterior sd: %s\n   late - early median %+.4g; predicted from the names' mean drift %+.4g (%s)\n",
              cl[1], cl[2], cl[3], units, w, summary(fit)$r.squared,
              paste(sprintf("%s %+.3g", DRIFT_NAMES, b), collapse = ", "), dy, sum(b * dz),
              paste(sprintf("%s %+.3g", DRIFT_NAMES, b * dz), collapse = ", ")))
  data.frame(scenario = cl[1], var = cl[2], year = as.integer(cl[3]), units = units, width = w,
             r2 = summary(fit)$r.squared, t(b), late_minus_early = dy, predicted = sum(b * dz),
             stringsAsFactors = FALSE, check.names = FALSE)
}))
saveRDS(list(blocks = D, leverage = LV, lp_halves = lph,
             provenance = list(driver = DR_DRIVER, commit = DR_COMMIT, dir = DR_DIR, ribbons = DR_RIBBONS,
                               pooled = pu, pooled_md5 = unname(tools::md5sum(pu)), pool_thin = pt, mode = CCX_MODE_CANONICAL,
                               names = DRIFT_NAMES, block = DRIFT_BLOCK, floor_near = DRIFT_FLOOR_NEAR)), DR_RDS)
cat(sprintf("\nwrote %s\n", DR_RDS))
sink()
