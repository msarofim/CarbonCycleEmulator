# =====================================================================
# diag_rep_dc_shelf_v0k.R -- THE R2 SHELF AT phi = 0 (CHANGELOG 2026-09-30 f).
# The 09-23 T4p shelf (diag_rep_dc_prior_profile.R) was measured at hilda29l and
# EXPIRED with the phi = 0 structure change (handoff 09-30 §4.4). This re-reads
# it from the phi = 0 ladder that already exists
# (outputs/diagnostics/rep_dc_product_ladder_v0k_20260929/, 09-29 k), with the
# same argument: at fixed rep_dC the inner optimum over the other 28 names does
# not depend on rep_dC's prior, so REST(r) = logpost(r) - logprior_shipped(r) is
# the prior-free profile, and any candidate prior's answer is
# argmax_r [REST(r) + logprior_candidate(r)]. No model run, no objective change.
# GATE SHAPE (bound from OUTSIDE the ladder, as in T4p): the shipped N(0, 1) prior
# pulls toward 0, so the prior-free optimum lies ABOVE the top rung (the fitted
# value); below it, loglik and REST must be strictly increasing and concave.
# Also reports beta_max / fert_k along the ladder (the fertilization side effect).
# No RNG (the ladder's replicate seed is recorded in its own artifacts).
# USAGE: Rscript calibration/diag_rep_dc_shelf_v0k.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
RS_LADDER   <- ccx_path("outputs", "diagnostics", "rep_dc_product_ladder_v0k_20260929")
RS_OUT      <- ccx_path("outputs", "diagnostics", "rep_dc_shelf_v0k_20260930")
RS_MU_MEAS  <- 0.776     # measured station-vs-hemisphere offset (NOAA MBL zonal), as in T4p
RS_MU_MASSW <- -0.215    # T3's mass-weighted expectation, as in T4p
RS_MU_GRID  <- c(0, RS_MU_MEAS, RS_MU_MASSW)
RS_SIG_GRID <- c(1.0, 0.5, 0.2)      # shipped / midpoint / Francey 2019 floor, as in T4p
RS_GRID_N   <- 20001L
RS_EDGE     <- 0.01
COMMIT      <- ccx_git_stamp()

lad  <- lapply(sort(list.files(RS_LADDER, pattern = "[.]rds$", full.names = TRUE)), readRDS)
prof <- lad[vapply(lad, function(x) x$job$rep, 0L) == 0L]
prof <- prof[order(vapply(prof, function(x) x$job$rung, 0))]
stopifnot(all(vapply(prof, `[[`, 0L, "conv") == 0L),
          length(unique(vapply(prof, function(x) x$provenance$mode, ""))) == 1L)
rr   <- vapply(prof, function(x) x$job$rung, 0)
lpst <- vapply(prof, function(x) x$products$scalar[["logpost"]], 0)
llik <- vapply(prof, function(x) x$products$scalar[["loglik"]], 0)
pri  <- CCX_PARAM_TABLE$rep_dC$prior; stopifnot(is.function(pri))
rest <- lpst - vapply(rr, pri, 0)
pn   <- md_names <- names(prof[[1]]$u)
par_of <- function(x, nm) { v <- ccx_unc_to_par(x$u); v[[nm]] }
bmax <- vapply(prof, par_of, 0, "beta_max"); fk <- vapply(prof, par_of, 0, "fert_k")
enh410 <- bmax * (410 - ccx_const("CO2_PI_PPM")) / (fk + 410 - ccx_const("CO2_PI_PPM"))

shape_bad <- function(y) { sl <- diff(y) / diff(rr); cv <- diff(sl)
  c(not_increasing = sum(sl <= 0), not_concave = sum(cv > 0)) }
g <- rbind(loglik = shape_bad(llik), REST = shape_bad(rest))

f   <- stats::splinefun(rr, rest, method = "monoH.FC")
xg  <- seq(min(rr), max(rr), length.out = RS_GRID_N)
tab <- expand.grid(sigma = RS_SIG_GRID, mu = RS_MU_GRID)
tab$rep_dC <- NA_real_; tab$d_loglik <- NA_real_; tab$note <- ""
fl  <- stats::splinefun(rr, llik, method = "monoH.FC")
for (i in seq_len(nrow(tab))) {
  s <- tab$sigma[i]; m <- tab$mu[i]
  obj <- f(xg) + stats::dnorm(xg, m, s, log = TRUE); k <- which.max(obj); x <- xg[k]
  if (x > max(rr) - RS_EDGE * diff(range(rr))) { tab$note[i] <- "ladder top: prior inert"; next }
  tab$rep_dC[i] <- x; tab$d_loglik[i] <- fl(x) - llik[which.max(rr)]
}

sink(paste0(RS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === calibration/diag_rep_dc_shelf_v0k.R @%s, run %s; ladder %s (mode %s, spinup %s, objective %s); no RNG\n",
            COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), basename(RS_LADDER), prof[[1]]$provenance$mode,
            prof[[1]]$provenance$spinup, prof[[1]]$provenance$objective))
cat(sprintf("  REST identity: %.2e (an identity, not evidence)\n", max(abs(rest + vapply(rr, pri, 0) - lpst))))
cat("  GATE SHAPE (counts of violations; 0 = PASS):\n"); print(g)
cat("\n  the ladder: rung, d_loglik vs top, beta_max, fert_k, enh(410 ppm)\n")
print(data.frame(rep_dC = rr, d_loglik = round(llik - llik[which.max(rr)], 2), beta_max = round(bmax, 3),
                 fert_k = round(fk, 1), enh410 = round(enh410, 4)), row.names = FALSE)
cat("\n  THE SHELF at phi = 0 (fitted rep_dC, d_loglik vs the canonical rung; READ LIKELIHOOD):\n")
print(tab, row.names = FALSE, digits = 4)
sink()
utils::write.csv(tab, paste0(RS_OUT, ".csv"), row.names = FALSE)
