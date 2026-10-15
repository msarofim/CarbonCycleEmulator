# =====================================================================
# diag_rep_dc_prior_centre_width.R -- R2, THE SIDE TEST (Marcus 2026-09-22):
# "what would changing the CENTRE and the WIDTH together do to the fit?"
#
# ⛔⛔ THIS IS A PROBE AND IT CHANGES NOTHING. The objective is NOT modified:
# the altered prior is applied by SUBTRACTING the shipped N(0, LIK_CO2_REP_ERR)
# term from the logpost and ADDING the trial one, per evaluation. `rep_dC` has
# `tr = "id"`, so its unconstrained coordinate IS its ppm value and the swap is
# exact. CCX_PARAM_TABLE is never mutated, no mode file is written, and nothing
# here is adoptable without the ruling and the restamp that §4.1 of the freeze
# record requires.
#
# WHY THE QUESTION IS NOT "WHERE DOES THE MODE GO". Re-centering alone was
# measured INERT in 2026-08-23 (diag_rep_dC_prior.R, at the arm-N mode): the
# likelihood was ~10x tighter than the prior, so the prior could not move the
# fit, only relabel it. ⚠ THAT MEASUREMENT PREDATES THIS CANONICAL -- it was
# taken at `rep_dC` = 5.18, and the mode has since moved to 3.52 -- so part 1
# RE-MEASURES it here rather than quoting it.
#
# The WIDTH is a different animal. At sigma = 0.2 ppm (the defensible floor for
# a station-representation term: Francey et al. 2019, ACP 19:14741, the
# inter-network sd on a station DIFFERENCE) the prior is COMPARABLE to the
# likelihood's own curvature, so it can move the fit -- and then the question is
# what the rest of the model does to absorb the move, and which observational
# streams pay for it.
#
# THREE PARTS, AND PART 3 IS THE ONE THAT COUNTS:
#   1. PROFILE  -- the likelihood-only optimum and curvature for `rep_dC`, with
#      its correlated partners re-optimized. Gives (xL, sL).
#   2. ANALYTIC -- the conjugate-normal prediction of the posterior mode for
#      each (mu, sigma): xp = (xL/sL^2 + mu/sg^2)/(1/sL^2 + 1/sg^2). Cheap, and
#      it assumes the likelihood is locally quadratic and that only the profiled
#      partners respond.
#   3. MEASURED -- an actual re-optimization at each corner, with a real free
#      set, and the analytic prediction CHECKED AGAINST IT. ⚠ A conjugate
#      formula on a 29-parameter posterior is an approximation, and the whole
#      point of tightening the prior is to make it bite; if the two disagree by
#      more than RPW_AGREE_TOL the analytic map is not to be quoted.
#
# Usage:  Rscript calibration/diag_rep_dc_prior_centre_width.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- the trial priors ------------------------------------------------
# mu = 0 is the shipped shrinkage center; RPW_MU_MEAS is the MEASURED
# station-vs-hemisphere offset, the mean of NH -MLO +0.738 and SH-SPO +0.814
# (calibration/diag_rep_dc_mbl_zonal.R, NOAA MBL zonal, doi:10.15138/DVNP-F961).
RPW_MU_MEAS  <- 0.776
RPW_MU       <- c(0, RPW_MU_MEAS)
# sigma: the shipped 1.0 (= LIK_CO2_REP_ERR), an intermediate, and the Francey
# floor. ⚠ 0.2 is a FLOOR for the representation term, not a measurement of
# this parameter's uncertainty -- it is the tightest defensible prior, which is
# what makes it the interesting corner.
RPW_SIGMA    <- c(1.0, 0.5, 0.2)
RPW_FRANCEY  <- 0.2
RPW_GRID     <- seq(2.6, 4.4, by = 0.2)   # around the canonical 3.52, for the curvature fit
RPW_NPART    <- 3                          # how many correlated partners to re-optimize in part 1
RPW_FREE_N   <- 8                          # part 3's free set: rep_dC + the 7 most correlated
RPW_NM_MAXIT <- 1200
RPW_AGREE_TOL <- 0.15                      # ppm; analytic vs measured mode
RPW_GATE_TOL <- 1e-3                       # harness must reproduce the stored logpost

md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
pins <- ccx_mode_pins(md)
rm_pins <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
for (n in names(pins)) bp[[n]] <- pins[[n]]
st <- ccx_mode_start(md, "rep_dc_prior_probe")
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                       spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))

# ---- HARNESS GATE: the rebuilt objective must reproduce the stored logpost --
# Without this every number below could be describing a different posterior.
v_s <- lp(st$u)
got <- as.numeric(v_s) - st$logpost_shift
cat(sprintf("=== HARNESS GATE ===\n  rebuilt %.4f (shift %+.4f) vs stored %.4f -> %s\n",
            got, st$logpost_shift, md$logpost,
            if (abs(got - md$logpost) < RPW_GATE_TOL) "PASS" else "FAIL"))
if (abs(got - md$logpost) >= RPW_GATE_TOL)
  stop("harness does not reproduce the stored logpost; every number below would be meaningless")

u0 <- st$u
x0 <- u0[["rep_dC"]]
stopifnot(identical(CCX_PARAM_TABLE$rep_dC$tr, "id"))   # u IS ppm for this name

#' The logpost with `rep_dC`'s prior SWAPPED, exactly and without mutating
#' anything: subtract the shipped term, add the trial one.
lp_mu_sg <- function(u, mu, sg) {
  as.numeric(lp(u)) -
    stats::dnorm(u[["rep_dC"]], 0, LIK_CO2_REP_ERR, log = TRUE) +
    stats::dnorm(u[["rep_dC"]], mu, sg, log = TRUE)
}
# ⚠ THE LIKELIHOOD COMES FROM THE OBJECTIVE'S OWN ATTRIBUTE, not from
# logpost-minus-a-reconstructed-prior. `by_stream = TRUE` makes
# ccx_make_logpost() return `attr(, "loglik")` and `attr(, "logprior")`
# alongside the streams, so there is no second implementation of the prior to
# drift from the first. (The first version of this line called a
# `ccx_logprior()` that does not exist, which is the honest failure that
# question deserved.)
loglik_of <- function(u) as.numeric(attr(lp(u), "loglik"))

cat(sprintf("\n=== 0. WHERE THE FIT IS NOW (%s) ===\n", CCX_MODE_CANONICAL))
cat(sprintf("  rep_dC = %.4f ppm; prior N(0, %.2f) => z = %+.2f\n",
            x0, LIK_CO2_REP_ERR, x0 / LIK_CO2_REP_ERR))
cat(sprintf("  MEASURED station-vs-hemisphere offset = %+.3f ppm (MBL zonal)\n", RPW_MU_MEAS))

# ---- part 1: the likelihood's own optimum and curvature --------------
cv <- md$cov
partners <- if (!is.null(cv) && "rep_dC" %in% rownames(cv)) {
  r <- stats::cov2cor(cv)["rep_dC", ]
  names(sort(abs(r[setdiff(names(r), "rep_dC")]), decreasing = TRUE))[seq_len(RPW_NPART)]
} else c("k_w", "bomb_total")
cat(sprintf("\n=== 1. PROFILE (re-optimising %s) ===\n", paste(partners, collapse = ", ")))
idxp <- match(partners, names(u0))
LL <- vapply(RPW_GRID, function(x) {
  u <- u0; u[["rep_dC"]] <- x
  op <- stats::optim(u0[idxp],
                     function(v) { uu <- u; uu[idxp] <- v; z <- -as.numeric(lp(uu))
                                   if (!is.finite(z)) 1e10 else z },
                     method = "Nelder-Mead", control = list(maxit = 500, reltol = 1e-10))
  ll <- -op$value - stats::dnorm(x, 0, LIK_CO2_REP_ERR, log = TRUE)
  cat(sprintf("  rep_dC %6.2f   loglik %14.4f\n", x, ll)); ll
}, numeric(1))
cf <- stats::coef(stats::lm(LL ~ poly(RPW_GRID, 2, raw = TRUE)))
xL <- -cf[2] / (2 * cf[3]); sL <- sqrt(-1 / (2 * cf[3]))
cat(sprintf("\n  LIKELIHOOD-only optimum %.3f ppm, curvature sd %.3f ppm\n", xL, sL))
cat(sprintf("  the data are %.1fx %s than the shipped %.1f ppm prior\n",
            max(LIK_CO2_REP_ERR / sL, sL / LIK_CO2_REP_ERR),
            if (sL < LIK_CO2_REP_ERR) "TIGHTER" else "LOOSER", LIK_CO2_REP_ERR))

# ---- part 2: the analytic map ---------------------------------------
cat("\n=== 2. ANALYTIC (conjugate) PREDICTION OF THE POSTERIOR MODE ===\n")
cat("  xp = (xL/sL^2 + mu/sg^2) / (1/sL^2 + 1/sg^2)\n\n")
cat(sprintf("  %8s %8s %14s %10s %12s\n", "mu", "sigma", "predicted", "shift", "new z"))
pred <- list()
for (mu in RPW_MU) for (sg in RPW_SIGMA) {
  xp <- (xL / sL^2 + mu / sg^2) / (1 / sL^2 + 1 / sg^2)
  pred[[paste(mu, sg)]] <- xp
  cat(sprintf("  %8.2f %8.2f %14.3f %+10.3f %12.2f\n", mu, sg, xp, xp - x0, (xp - mu) / sg))
}

# ---- part 3: MEASURED, by actual re-optimization ---------------------
free <- if (!is.null(cv) && "rep_dC" %in% rownames(cv)) {
  r <- stats::cov2cor(cv)["rep_dC", ]
  c("rep_dC", names(sort(abs(r[setdiff(names(r), "rep_dC")]), decreasing = TRUE))[seq_len(RPW_FREE_N - 1)])
} else c("rep_dC", "k_w", "bomb_total")
free <- intersect(free, names(u0))
idxf <- match(free, names(u0))
cat(sprintf("\n=== 3. MEASURED: re-optimise %d parameters at each corner ===\n", length(free)))
cat(sprintf("  free: %s\n", paste(free, collapse = ", ")))
cat(sprintf("  ⚠ NOT all %d -- the rest are held at the canonical, so a measured shift here\n", length(u0)))
cat( "    is a LOWER bound on what a full refit would do.\n\n")
cat(sprintf("  %6s %6s %12s %10s %12s %14s %12s\n",
            "mu", "sigma", "rep_dC", "shift", "vs analytic", "loglik", "d(loglik)"))
ll0 <- loglik_of(u0)
res <- list()
for (mu in RPW_MU) for (sg in RPW_SIGMA) {
  fobj <- function(z) { uu <- u0; uu[idxf] <- z; v <- -lp_mu_sg(uu, mu, sg)
                        if (!is.finite(v)) 1e10 else v }
  o1 <- stats::optim(u0[idxf], fobj, method = "Nelder-Mead",
                     control = list(maxit = RPW_NM_MAXIT, reltol = 1e-11))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = 200, reltol = 1e-12))
  best <- if (o2$value < o1$value) o2 else o1
  uu <- u0; uu[idxf] <- best$par
  xm <- uu[["rep_dC"]]; llm <- loglik_of(uu)
  res[[paste(mu, sg)]] <- list(u = uu, x = xm, ll = llm)
  cat(sprintf("  %6.2f %6.2f %12.3f %+10.3f %12.3f %14.3f %+12.3f\n",
              mu, sg, xm, xm - x0, xm - pred[[paste(mu, sg)]], llm, llm - ll0))
}

# ---- the agreement check --------------------------------------------
dis <- vapply(names(res), function(k) abs(res[[k]]$x - pred[[k]]), numeric(1))
cat(sprintf("\n  analytic vs measured: worst |difference| %.3f ppm (tolerance %.2f) -> %s\n",
            max(dis), RPW_AGREE_TOL,
            if (max(dis) < RPW_AGREE_TOL) "the conjugate map is usable"
            else "⚠ THE CONJUGATE MAP IS NOT USABLE -- quote the MEASURED column only"))

# ---- which streams pay, at the operative corner ----------------------
key <- paste(RPW_MU_MEAS, RPW_FRANCEY)
cat(sprintf("\n=== 4. WHO PAYS, at mu = %+.3f / sigma = %.2f (the defensible corner) ===\n",
            RPW_MU_MEAS, RPW_FRANCEY))
s0 <- attr(lp(u0), "streams"); s1 <- attr(lp(res[[key]]$u), "streams")
if (!is.null(s0) && !is.null(s1)) {
  nm <- intersect(names(s0), names(s1))
  d <- vapply(nm, function(n) as.numeric(s1[[n]]) - as.numeric(s0[[n]]), numeric(1))
  d <- sort(d)
  cat(sprintf("  %-22s %12s\n", "stream", "d(logL)"))
  for (n in names(d)) if (abs(d[[n]]) > 0.05)
    cat(sprintf("  %-22s %+12.2f\n", n, d[[n]]))
  cat(sprintf("  %-22s %+12.2f\n", "TOTAL", sum(d)))
}
cat(sprintf("\n  rep_dC %.3f -> %.3f ppm; likelihood %+.2f log-units.\n",
            x0, res[[key]]$x, res[[key]]$ll - ll0))
cat("\n⛔ NOTHING HERE IS ADOPTED. Changing this prior is an OBJECTIVE change:\n")
cat("   freeze record §4.1 -- a ruling, then a restamp of every mode.\n")
