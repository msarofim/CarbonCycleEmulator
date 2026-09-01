# =====================================================================
# diag_stream_neff.R -- EFFECTIVE SAMPLE SIZE OF EVERY ANNUAL STREAM, AND WHAT
#                       AN n_eff CORRECTION DOES TO THE RIDGE VERDICT.
#                       (2026-08-25c)
#
# WHY THIS FILE EXISTS AND WHY IT IS NOT THE ONE THE HANDOFF ASKED FOR.
#
# handoff_2026-08-25b sec.4 named "price the station-level streams' effective
# n" the single highest-value unrun diagnostic, on the frozen-scan finding that
# 93 % of pin90's 86.7 log-unit penalty lives in co2_level_MLO + co2_level_SPO.
# diag_landed_gap_streams.R measured that share AT THE LANDED MODES and it is
# -0.1 %. The station levels are exonerated: they contribute +0.09 log-units
# NET (MLO +2.49, SPO -2.40). The gap is carried by
#
#     d13c_seasonal_SPO  -38.16   (44 %)
#     d13c_seasonal_MLO  -24.22   (28 %)
#     gcb_land_sink      -24.00   (28 %)
#
# So the effective-n question RELOCATES rather than dies, and it relocates onto
# streams nobody has priced. This file prices ALL of them -- memory
# audit_every_target: audit every target, not just the suspect one, because
# which ones were already fine is what decides the conclusion.
#
# ---------------------------------------------------------------------
# THE ESTIMAND, WRITTEN DOWN BECAUSE THE TWO CORRECTIONS ANSWER DIFFERENT
# QUESTIONS AND THEIR DISAGREEMENT IS THE RESULT.
#
# Every stream here scores a year-indexed residual r_i with a stated sd, as if
# the rows were independent:  logL = -0.5 sum (r_i/sd_i)^2 + const. The rows are
# not independent -- these residuals are dominated by slowly varying MODEL
# DISCREPANCY, which is the same fact that killed the AR(1) scheme in 2026-08-11
# (design note 1 of R/likelihood.R). Two ways to price that, and they are not
# the same operation:
#
#   A. SCALAR n_eff, the ice-term precedent (memory ccx_d13c_neff, 12.7 -> 5.1
#      sigma). Multiply the whole stream by f = n_eff/N. It is a WEIGHT change:
#      it forgives everything in the stream in equal proportion.
#
#   B. GLS with an estimated correlation matrix R. Score
#      -0.5 z' R^-1 z with z_i = r_i/sd_i. It is a SHAPE change: it forgives a
#      SMOOTH residual and forgives a high-frequency one hardly at all. The
#      log|R| term cancels in every difference taken here.
#
# B is the principled one and A is what the project has done before. They are
# BOTH reported and NOT averaged. Where they disagree, the disagreement says
# whether the penalty being repriced is smooth structure or year-to-year detail.
#
# AND THE THIRD DECOMPOSITION IS THE ONE THAT DECIDES IT: BIAS vs SCATTER.
# R/likelihood.R's own `sigma_d13c` retirement block records the trap --
# "the d13C residual is BIAS, not scatter, and a free scale cannot tell the two
# apart ... that is a robustness valve venting the signal". An n_eff correction
# is exactly such a valve. A penalty that is a change in the residual MEAN is a
# real disagreement about a level, and forgiving it via n_eff is the same
# mistake in a new coordinate; a penalty that is a change in SCATTER about the
# mean is what n_eff legitimately addresses. Part 4 splits every stream's delta
# both ways.
#
# ---------------------------------------------------------------------
# FOUR n_eff ESTIMATORS, DELIBERATELY NOT AVERAGED:
#   1. INDEPENDENT (n_eff = N). The incumbent. An upper bound.
#   2. GEYER initial-positive-sequence ESS, N / (1 + 2 sum_k rho_k) truncated at
#      the first non-positive rho. Model-free, standard, and the one that most
#      nearly matches what "effective sample size" means elsewhere in the repo.
#   3. AR(1) closed form, N (1-rho1)/(1+rho1). The cheapest, and it is reported
#      because it is what a reader will compute by hand from a lag-1 number.
#   4. BATCH MEANS at three batch lengths. Model-free, and its SENSITIVITY to
#      the batch length is the uncertainty on the answer.
#
# GAPS AND IRREGULAR SAMPLING. SPO's CO2 record has 3 missing years and the ice
# core is irregular by construction. The autocorrelation is computed on the
# series placed on its own YEAR grid with gaps as NA, so a 16-month hole is not
# treated as a one-step lag -- the same defect design note 1 records the AR(1)
# scheme having. Streams whose median year spacing exceeds NEFF_MAX_SPACING are
# reported but FLAGGED, because a lag-1 autocorrelation is not a year-1
# autocorrelation there.
#
# EVERY RESIDUAL IS GATED. Part 1 reconstructs each stream's residual vector
# outside ccx_loglik() and requires sum(dnorm(r, 0, sd, log)) to reproduce that
# stream's `by_stream` value to NEFF_GATE_TOL. A stream that fails is reported
# UNGATED and EXCLUDED from the repricing rather than silently carried -- memory
# mutation_test_gates: a gate that cannot fail certifies nothing, and this one
# fails loudly if a reconstruction drifts from the objective.
#
# THIS FILE CHANGES NOTHING. It reports. An n_eff correction is a change to the
# OBJECTIVE and belongs to Marcus.
#
# RUNTIME ~10 s.  Usage: Rscript calibration/diag_stream_neff.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants ------------------------------------------------
NEFF_YEARS        <- c(1750, 2024)
NEFF_GATE_TOL     <- 1e-6      # log-units, per stream, recomputed vs by_stream
NEFF_MAX_SPACING  <- 1.5       # yr; above this the year-lag reading is flagged
NEFF_BATCH_LENS   <- c(5, 10, 20)
NEFF_ACF_MAXLAG   <- 40
NEFF_REF          <- "ref"
NEFF_FOCUS        <- "pin90"
NEFF_SHOW_MIN     <- 0.50      # log-units of |delta| worth printing
OUTDIR            <- ccx_path("calibration", "output", "landed_gap")
OUTFILE           <- file.path(OUTDIR, "stream_neff.rds")
# ccx_mode_file() returns an ABSOLUTE path; the ridge arms are made absolute
# here so the vector is uniform and readRDS() below needs no wrapper. The three
# `ridge_*` arms are PRE-FIX and quarantined -- this file fails loudly on them,
# which is the intended behaviour until they are refit.
NEFF_ARMS <- c(ref    = ccx_mode_file(),
               pin120 = ccx_path("calibration", "output", "ridge_pin120", "mode_fit_pumpN.rds"),
               pin90  = ccx_path("calibration", "output", "ridge_pin90",  "mode_fit_pumpN.rds"),
               pin60  = ccx_path("calibration", "output", "ridge_pin60",  "mode_fit_pumpN.rds"))
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

# THE h_ml OVERRIDE IS GONE, 2026-08-28. This file used to narrow h_ml to
# LIK_OCEAN_GRAD_HML_OK_RETIRED = [85, 120] to match the refit. Under option 5
# the refit is UNBOUNDED, so matching it now means leaving the shipped table
# alone. This is the safest of the four band mirrors to widen, on this file's
# own evidence: the override existed only for the PRIOR, and the comment that
# stood here said in as many words that this file does not use it.
NEFF_HML_SUPPORT <- c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)
cat(sprintf("h_ml on its SHIPPED support [%g, %g]; the table is UNTOUCHED.\n",
            NEFF_HML_SUPPORT[1], NEFF_HML_SUPPORT[2]))
OBS <- ccx_prepare_obs()

# =====================================================================
# PART 1 -- residual reconstruction, one gate per stream
# =====================================================================
# Each block MIRRORS the corresponding block of ccx_loglik(). The mirror is the
# liability and the gate is the mitigation: nothing below is trusted because it
# looks right, only because sum(dnorm(.)) reproduces the objective's own number.
neff_residuals <- function(file) {
  md <- readRDS(ccx_path(file))
  ccx_require_param_set(md, "the per-stream n_eff diagnostic")
  pv <- md$par_mode
  p  <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv)
  p$pump_mode  <- md$pump_mode
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", NEFF_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale)
  o  <- ccx_run_fast(sp, F)$out
  err <- list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
              grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c)
  eluc <- ccx_forcing_eluc_annual(F)
  ST <- unlist(ccx_loglik(o, OBS, err, luc = eluc,
                          deep = sp$diagnostics$d14c_bottom_box,
                          ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
  ms <- ccx_model_stats(o, OBS)
  R  <- list()
  put <- function(nm, year, r, sd) R[[nm]] <<- list(year = year, r = r, sd = sd)

  for (st in c("MLO", "SPO")) {                      # CO2 annual level
    ob <- OBS$co2_ann[[st]]; m <- ms$co2[[st]]
    k <- match(ob$year, m$year); g <- !is.na(k)
    put(paste0("co2_level_", st), ob$year[g],
        ob$level[g] - (m$level[k[g]] - err$rep_dC), LIK_CO2_REP_ERR)
  }
  for (st in c("MLO", "SPO")) {                      # d13C annual level
    ob <- OBS$d13_ann[[st]]; m <- ms$d13[[st]]
    k <- match(ob$year, m$year); g <- !is.na(k)
    pred <- m$level[k[g]]
    cbox <- ms$co2[[st]]$level[match(ob$year[g], ms$co2[[st]]$year)]
    pred <- pred - err$rep_dC * ((LIK_REP_SOURCE_D13C - pred) / cbox)
    put(paste0("d13c_level_", st), ob$year[g], ob$level[g] - pred, LIK_D13C_REP_ERR)
  }
  # SEASONAL: two harmonic coefficients per year, stacked. The year index is
  # therefore DUPLICATED, and the autocorrelation in part 2 is taken on the two
  # coefficient series SEPARATELY and pooled -- stacking them into one vector
  # would put an artificial lag-N/2 structure in the acf.
  for (fam in c("co2", "d13c")) for (st in c("MLO", "SPO")) {
    ob <- if (fam == "co2") OBS$co2_seas[[st]] else OBS$d13_seas[[st]]
    m  <- if (fam == "co2") ms$co2_seas[[st]]  else ms$d13_seas[[st]]
    if (is.null(ob) || is.null(m)) next
    k <- match(ob$year, m$year); g <- !is.na(k)
    put(paste0(fam, "_seasonal_", st), c(ob$year[g], ob$year[g]),
        c(ob$a[g] - m$a[k[g]], ob$b[g] - m$b[k[g]]),
        c(rep(ob$sd_a, sum(g)), rep(ob$sd_b, sum(g))))
  }
  # GCB: the objective's own end-EXTRAPOLATING stock differencing, not
  # approx(rule = 2). Copying rule = 2 here missed the two GCB gates by 0.34.
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  tt <- o$t; nT <- length(tt)
  stock_at <- function(v) {
    y <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[nT]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    if (any(hi)) y[hi] <- v[nT] + (bnd[hi] - tt[nT]) * (v[nT] - v[nT - 1]) /
                                    (tt[nT] - tt[nT - 1])
    y
  }
  flux <- data.frame(year = utils::head(bnd, -1),
                     ocean = diff(stock_at(o$ocean_C)), land = diff(stock_at(o$land_C)))
  gg <- merge(as.data.frame(OBS$gcb)[, c("year", "ocean_sink", "land_sink")], flux, by = "year")
  gg <- merge(gg, eluc, by = "year")
  put("gcb_ocean_sink", gg$year, gg$ocean_sink - gg$ocean, LIK_GCB_OCEAN_SD)
  put("gcb_land_sink",  gg$year, gg$land_sink - (gg$land + gg$eluc),
      LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE)
  for (q in list(list(nm = "co2",  og = OBS$co2_grad,  mod = ms$co2,
                      off = err$grad_off_co2,  sd = LIK_GRAD_CO2_SD),
                 list(nm = "d13c", og = OBS$d13c_grad, mod = ms$d13,
                      off = err$grad_off_d13c, sd = LIK_GRAD_D13C_SD))) {
    A <- q$mod$MLO; B <- q$mod$SPO
    mg <- A$level[match(q$og$year, A$year)] - B$level[match(q$og$year, B$year)]
    g <- is.finite(mg)
    put(paste0(q$nm, "_gradient"), q$og$year[g], q$og$grad[g] - (mg[g] + q$off), q$sd)
  }
  put("co2_icecore", OBS$ice$year,
      OBS$ice$CO2ppm - stats::approx(o$t, o$co2_SH, xout = OBS$ice$year, rule = 2)$y,
      OBS$ice$sd)
  for (hh in c("NH", "SH")) {
    ob <- if (hh == "NH") OBS$d14_nh_ann else OBS$d14_sh_ann
    m  <- ms$d14[[hh]]
    k <- match(ob$year, m$year); g <- !is.na(k)
    put(paste0("d14c_", hh), ob$year[g], ob$value[g] - m$mean[k[g]],
        sqrt(ob$sd[g]^2 + err$sigma_d14c^2))
  }
  list(R = R, streams = ST)
}

A <- lapply(NEFF_ARMS, neff_residuals)

cat("=== PART 1: GATE -- reconstructed residuals reproduce the objective ===\n")
cat(sprintf("%-22s %5s | %s\n", "stream", "n",
            paste(sprintf("%12s", names(A)), collapse = "")))
GATED <- character(0)
for (nm in names(A[[NEFF_REF]]$R)) {
  d <- vapply(A, function(a) {
    x <- a$R[[nm]]; abs(sum(stats::dnorm(x$r, 0, x$sd, log = TRUE)) - a$streams[[nm]])
  }, numeric(1))
  ok <- all(d < NEFF_GATE_TOL)
  if (ok) GATED <- c(GATED, nm)
  cat(sprintf("%-22s %5d | %s  %s\n", nm, length(A[[NEFF_REF]]$R[[nm]]$r),
              paste(sprintf("%12.1e", d), collapse = ""), if (ok) "PASS" else "*** UNGATED ***"))
}
stopifnot(length(GATED) > 0)
cat(sprintf("%d/%d streams gated to %.0e.\n", length(GATED),
            length(A[[NEFF_REF]]$R), NEFF_GATE_TOL))
ungated <- setdiff(names(A[[NEFF_REF]]$R), GATED)
if (length(ungated))
  cat(sprintf("EXCLUDED from the repricing (ungated): %s\n", paste(ungated, collapse = ", ")))

# =====================================================================
# PART 2 -- n_eff, four ways
# =====================================================================
# STREAM KIND IS DECLARED, NOT INFERRED. A first draft detected the seasonal
# streams' stacked (a, b) coefficient vectors by anyDuplicated(year) -- and the
# ICE CORE has 255 rows over 136 unique years (up to 7 samples in one year), so
# it took the seasonal branch and was silently halved, twice. Duplicated years
# mean two different things in this objective and only a declaration separates
# them.
#
#   "annual"    one value per year, regular grid, gaps allowed.
#   "paired"    TWO scalar series stacked on a duplicated year index (the
#               harmonic a and b). Estimated SEPARATELY and pooled by summing N
#               and n_eff -- rho is AVERAGED, never summed.
#   "irregular" clustered, unevenly spaced samples where a lag is not a year
#               (the ice core). REPORTED AND EXCLUDED from the repricing: its
#               n_eff is an air-age-spectral-width question, which is memory
#               ccx_d13c_neff's subject and not this file's.
NEFF_KIND <- c(co2_level_MLO = "annual",   co2_level_SPO = "annual",
               d13c_level_MLO = "annual",  d13c_level_SPO = "annual",
               co2_seasonal_MLO = "paired", co2_seasonal_SPO = "paired",
               d13c_seasonal_MLO = "paired", d13c_seasonal_SPO = "paired",
               gcb_ocean_sink = "annual",  gcb_land_sink = "annual",
               co2_gradient = "annual",    d13c_gradient = "annual",
               co2_icecore = "irregular",
               d14c_NH = "annual",         d14c_SH = "annual")
stopifnot(setequal(names(NEFF_KIND), names(A[[NEFF_REF]]$R)))

neff_on_year_grid <- function(year, v) {
  u <- seq(min(year), max(year))
  out <- rep(NA_real_, length(u))
  out[match(year, u)] <- v
  out
}
# One scalar series on a year grid. Returns rho as a VECTOR so callers can
# average it; every count is per-series and gets summed by the pooler.
neff_one <- function(year, z) {
  N <- length(z)
  g <- neff_on_year_grid(year, z - mean(z))
  ac <- stats::acf(g, lag.max = min(NEFF_ACF_MAXLAG, length(g) - 2L),
                   plot = FALSE, na.action = stats::na.pass)$acf[, 1, 1]
  rho <- ac[-1]
  rho[!is.finite(rho)] <- 0
  rho <- pmax(pmin(rho, 1), -1)     # na.pass can return |rho| > 1; it is not an
                                    # autocorrelation then, and clipping is
                                    # visible where silently using it is not.
  kstop <- which(rho <= 0)[1]
  kstop <- if (is.na(kstop)) length(rho) else kstop - 1L
  s <- if (kstop >= 1) sum(rho[seq_len(kstop)]) else 0
  r1 <- rho[1]
  bm <- vapply(NEFF_BATCH_LENS, function(L) {
    if (N < 3 * L) return(NA_real_)
    idx <- split(seq_len(N), ceiling(seq_len(N) / L))
    idx <- idx[lengths(idx) == L]
    if (length(idx) < 3) return(NA_real_)
    mb <- vapply(idx, function(i) mean(z[i]), numeric(1))
    v <- stats::var(z)
    if (!is.finite(v) || v <= 0 || stats::var(mb) <= 0) return(NA_real_)
    max(N * v / (L * stats::var(mb)), 1)
  }, numeric(1))
  list(N = N, rho1 = r1, geyer = N / max(1 + 2 * s, 1e-6),
       ar1 = N * (1 - r1) / (1 + r1), bm = bm)
}
neff_series <- function(nm, arm = NEFF_REF) {
  x <- A[[arm]]$R[[nm]]; z <- x$r / x$sd
  if (NEFF_KIND[[nm]] == "paired") {
    h <- length(z) / 2L
    yr <- x$year[seq_len(h)]
    list(list(year = yr, z = z[seq_len(h)]), list(year = yr, z = z[h + seq_len(h)]))
  } else list(list(year = x$year, z = z))
}
neff_pool <- function(nm, arm = NEFF_REF) {
  e <- lapply(neff_series(nm, arm), function(s) neff_one(s$year, s$z))
  list(N = sum(vapply(e, `[[`, numeric(1), "N")),
       rho1 = mean(vapply(e, `[[`, numeric(1), "rho1")),        # AVERAGED
       geyer = sum(vapply(e, `[[`, numeric(1), "geyer")),
       ar1 = sum(vapply(e, `[[`, numeric(1), "ar1")),
       bm = rowSums(vapply(e, `[[`, numeric(length(NEFF_BATCH_LENS)), "bm")),
       rho_each = vapply(e, `[[`, numeric(1), "rho1"))
}

cat(sprintf("\n\n=== PART 2: EFFECTIVE SAMPLE SIZE (reference-mode residuals) ===\n"))
cat("rho1 flagged `~0` when |rho1| < 2/sqrt(N_series), i.e. inside the white-noise band:\n")
cat("a correction driven by an insignificant rho is fitting the sampling error of an acf.\n\n")
cat(sprintf("%-22s %-9s %5s %7s %8s %8s %s\n", "stream", "kind", "N", "rho1",
            "geyer", "ar(1)",
            paste(sprintf("%8s", paste0("bm", NEFF_BATCH_LENS)), collapse = "")))
EST <- list()
for (nm in GATED) {
  e <- neff_pool(nm)
  nser <- length(e$rho_each)
  e$rho_band <- 2 / sqrt(e$N / nser)
  e$rho_sig  <- abs(e$rho1) > e$rho_band
  EST[[nm]] <- e
  cat(sprintf("%-22s %-9s %5d %7s %8.1f %8.1f %s\n", nm, NEFF_KIND[[nm]], e$N,
              sprintf("%+.2f%s", e$rho1, if (e$rho_sig) " " else "~"),
              e$geyer, e$ar1,
              paste(sprintf("%8.1f", e$bm), collapse = "")))
}
cat("  (` ~ ` after rho1 = inside the white-noise band, treated as ZERO below.)\n")

# =====================================================================
# PART 3 -- reprice the gap, two ways
# =====================================================================
# A: scalar f = min(n_eff/N, 1) per stream, Geyer. The ice-term precedent.
# B: GLS under AR(1) at the reference arm's own rho1, exact; log|R| cancels in
#    every difference, and an INSIGNIFICANT rho1 is set to zero so B reduces to
#    the naive score rather than to the sampling noise of an acf.
#
# GAPS BREAK THE CHAIN. The quadratic form is accumulated over runs of
# CONSECUTIVE YEARS only. A first draft split on the residual's own index, which
# is contiguous by construction, so it never split at all -- exactly the defect
# design note 1 records the retired AR(1) having (it lagged on OBSERVATION
# INDEX, so a 16-month SPO gap was a 1-month step).
neff_ar1_quad <- function(year, z, rho) {
  if (!is.finite(rho) || rho == 0 || abs(rho) >= 1) return(sum(z^2))
  o <- order(year); year <- year[o]; z <- z[o]
  runs <- split(seq_along(z), cumsum(c(1, diff(year) != 1)))
  d <- 1 - rho^2
  q <- 0
  for (i in runs) {
    v <- z[i]; n <- length(v)
    if (n == 1L) { q <- q + v^2; next }
    q <- q + (v[1]^2 + v[n]^2) / d +
             sum(v[-c(1, n)]^2) * (1 + rho^2) / d -
             2 * rho * sum(v[-n] * v[-1]) / d
  }
  q
}
neff_gls_delta <- function(nm, arm) {
  rho <- if (isTRUE(EST[[nm]]$rho_sig)) EST[[nm]]$rho1 else 0
  qq <- function(a) sum(vapply(neff_series(nm, a),
                               function(s) neff_ar1_quad(s$year, s$z, rho), numeric(1)))
  -0.5 * (qq(arm) - qq(NEFF_REF))
}
neff_bias_scatter <- function(nm, arm) {
  s0 <- neff_series(nm, NEFF_REF); s1 <- neff_series(nm, arm)
  b <- 0; sc <- 0
  for (j in seq_along(s0)) {
    z0 <- s0[[j]]$z; z1 <- s1[[j]]$z; n <- length(z0)
    b  <- b  - 0.5 * n * (mean(z1)^2 - mean(z0)^2)
    sc <- sc - 0.5 * (sum((z1 - mean(z1))^2) - sum((z0 - mean(z0))^2))
  }
  c(bias = b, scatter = sc)
}

PRICED <- GATED[NEFF_KIND[GATED] != "irregular"]
alt  <- setdiff(names(A), NEFF_REF)
DEL  <- vapply(A[alt], function(a) a$streams[GATED] - A[[NEFF_REF]]$streams[GATED],
               numeric(length(GATED)))
rownames(DEL) <- GATED
FRAC <- vapply(GATED, function(nm) min(EST[[nm]]$geyer / EST[[nm]]$N, 1), numeric(1))
DELA <- DEL * FRAC
DELB <- vapply(alt, function(arm) vapply(GATED, neff_gls_delta, numeric(1), arm = arm),
               numeric(length(GATED)))
rownames(DELB) <- GATED

cat(sprintf("\n\n=== PART 3: THE %s GAP REPRICED ===\n", NEFF_FOCUS))
cat("A = scalar n_eff/N (Geyer).  B = AR(1) GLS at a SIGNIFICANT reference rho1.\n")
cat("bias/scatter split the NAIVE delta: how much is a change in the residual MEAN\n")
cat("(which n_eff forgives wrongly -- R/likelihood.R's own sigma_d13c block) vs in\n")
cat("its scatter (which n_eff legitimately addresses).\n\n")
cat(sprintf("%-22s %9s %6s %9s %9s | %9s %9s\n", "stream", "naive", "f", "A", "B",
            "bias", "scatter"))
for (nm in PRICED[order(DEL[PRICED, NEFF_FOCUS])]) {
  if (abs(DEL[nm, NEFF_FOCUS]) < NEFF_SHOW_MIN) next
  bs <- neff_bias_scatter(nm, NEFF_FOCUS)
  cat(sprintf("%-22s %+9.2f %6.3f %+9.2f %+9.2f | %+9.2f %+9.2f\n", nm,
              DEL[nm, NEFF_FOCUS], FRAC[[nm]], DELA[nm, NEFF_FOCUS], DELB[nm, NEFF_FOCUS],
              bs[["bias"]], bs[["scatter"]]))
}
cat(sprintf("%-22s %+9.2f %6s %+9.2f %+9.2f\n", "PRICED TOTAL",
            sum(DEL[PRICED, NEFF_FOCUS]), "", sum(DELA[PRICED, NEFF_FOCUS]),
            sum(DELB[PRICED, NEFF_FOCUS])))
for (nm in setdiff(GATED, PRICED))
  cat(sprintf("%-22s %+9.2f %6s %9s %9s   (irregular: reported, not repriced)\n",
              nm, DEL[nm, NEFF_FOCUS], "-", "-", "-"))

# ---- GATE 2: the priced streams account for the whole likelihood gap -------
# A repricing that quietly covers 80 % of a gap reads exactly like one that
# covers all of it. This states the residue in log-units instead.
cat("\n")
for (arm in alt) {
  full <- sum(A[[arm]]$streams) - sum(A[[NEFF_REF]]$streams)
  cat(sprintf("GATE 2 %-7s full likelihood delta %+9.2f = gated %+9.2f + ungated/absent %+6.2f\n",
              arm, full, sum(DEL[, arm]), full - sum(DEL[, arm])))
}

cat(sprintf("\nALL ARMS, priced-stream likelihood total:\n"))
cat(sprintf("%-10s %10s %10s %10s\n", "arm", "naive", "A (n_eff)", "B (GLS)"))
for (arm in alt)
  cat(sprintf("%-10s %+10.2f %+10.2f %+10.2f\n", arm,
              sum(DEL[PRICED, arm]), sum(DELA[PRICED, arm]), sum(DELB[PRICED, arm])))

# =====================================================================
# PART 4 -- WHAT THE BIAS IS
# =====================================================================
# Parts 2-3 say the veto is a shift in three streams' residual MEANS, on
# essentially white residuals. That makes it a physical claim, so name it.
#
# THE STATISTIC IS THE SEASONAL d13C-PER-ppm RATIO, which is the partition test
# memory ccx_seas_partition already runs: how depleted the seasonal CO2 swing is
# per ppm of it. Too depleted = too much of the seasonal flux is photosynthetic
# and too little is ocean solubility. The model is ALREADY on the depleted side
# at the reference mode, so the question is only which way saturation moves it.
#
# AMPLITUDE IS THE FIRST-HARMONIC SEMI-AMPLITUDE sqrt(a^2 + b^2), on BOTH sides,
# from the same ccx_year_harmonic() estimator (design note 1b). Stated because
# memory amp_definition_mismatch records a semi-amplitude-vs-peak-to-peak mixup
# inverting a CCX conclusion.
neff_amp <- function(arm) {
  md <- readRDS(NEFF_ARMS[[arm]]); pv <- md$par_mode
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv); p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", NEFF_YEARS, prod_c14 = sp$prod_c14,
                         bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale)
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, OBS)
  do.call(rbind, lapply(c("MLO", "SPO"), function(st) {
    oc <- OBS$co2_seas[[st]]; mc <- ms$co2_seas[[st]]
    od <- OBS$d13_seas[[st]]; mm <- ms$d13_seas[[st]]
    A_o <- mean(sqrt(oc$a^2 + oc$b^2))
    A_m <- mean(sqrt(mc$a[match(oc$year, mc$year)]^2 + mc$b[match(oc$year, mc$year)]^2))
    D_o <- mean(sqrt(od$a^2 + od$b^2))
    D_m <- mean(sqrt(mm$a[match(od$year, mm$year)]^2 + mm$b[match(od$year, mm$year)]^2))
    data.frame(station = st, co2_ratio = A_m / A_o, d13c_ratio = D_m / D_o,
               perppm_obs = D_o / A_o, perppm_mod = D_m / A_m,
               perppm_ratio = (D_m / A_m) / (D_o / A_o))
  }))
}
cat("\n\n=== PART 4: WHAT THE BIAS IS -- the seasonal partition test ===\n")
cat("semi-amplitude sqrt(a^2+b^2), same estimator both sides; >1 = too depleted per ppm\n\n")
cat(sprintf("%-8s %-5s %10s %10s %12s %12s %10s\n", "arm", "stn", "CO2 mod/obs",
            "d13C m/o", "per-ppm obs", "per-ppm mod", "ratio"))
AMP <- list()
for (arm in names(NEFF_ARMS)) {
  AMP[[arm]] <- neff_amp(arm)
  for (i in seq_len(nrow(AMP[[arm]]))) with(AMP[[arm]][i, ],
    cat(sprintf("%-8s %-5s %10.2f %10.2f %12.4f %12.4f %9.2fx\n",
                arm, station, co2_ratio, d13c_ratio, perppm_obs, perppm_mod, perppm_ratio)))
}

saveRDS(list(amp = AMP, resid = lapply(A, function(a) a$R), est = EST, gated = GATED,
             priced = PRICED, ungated = ungated, kind = NEFF_KIND,
             delta = DEL, delta_A = DELA, delta_B = DELB, frac = FRAC,
             arms = NEFF_ARMS), OUTFILE)
cat(sprintf("\nwritten: %s\n", OUTFILE))
