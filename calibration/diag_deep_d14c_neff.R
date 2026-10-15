# =====================================================================
# diag_deep_d14c_neff.R -- MEASURE the deep-D14C effective sample size instead
# of asserting it.  (Marcus 2026-08-16)
#
# WHAT IS BEING REPLACED. `LIK_D14C_DEEP_NEFF` = 20 is the one number in the
# deep-D14C term that was never measured. data-raw/build_glodap_deep_targets.R
# tabulated five candidate sigmas spanning 15x, said in terms that the spread is
# NOT the sigma and that n_eff "is of order the number of independent deep water
# masses, i.e. tens", and left the choice to Marcus. 20 was picked from that
# sentence. sigma = sd_w / sqrt(n_eff) = 45.88 / sqrt(20) = 10.26 permil.
#
# WHY IT MATTERS NOW AND DID NOT BEFORE. The choice was made for a 62.6 permil
# question -- does the term hold `kz` against the -112.7 permil runaway when the
# bracket is deleted -- and FOUR OF THE FIVE CANDIDATES ANSWER THAT IDENTICALLY
# (all > 3 sigma). Candidate A (diag_ocean_candidates.R) asks a 17.5 permil
# question instead, and there the candidates disagree by 240x: A's net score
# against the incumbent runs +16.2 log-units at sigma 3.00 and -0.46 at sigma
# 45.88. Same physics, same data, opposite decision. Part 4 below recomputes
# that table live rather than copying it.
#
# ---------------------------------------------------------------------
# WHAT n_eff MEANS HERE, WRITTEN DOWN BECAUSE THE ESTIMATORS ANSWER DIFFERENT
# QUESTIONS AND THE DIFFERENCE IS THE RESULT.
#
# The estimand is the volume-weighted mean xbar_w = sum(w x) / sum(w) over the
# model's own layer, 2627-3700 m. Its sampling variance under a spatially
# correlated field is
#
#     Var(xbar_w) = sigma^2 * [sum_i sum_j w_i w_j rho(d_ij)] / (sum w)^2
#
# so the definition that makes Var = sigma^2 / n_eff is
#
#     n_eff = (sum w)^2 / [sum_i sum_j w_i w_j rho(d_ij)]
#
# which collapses to Kish's (sum w)^2 / sum(w^2) when rho = delta. THAT is the
# quantity being measured, and it is a statement about how much INDEPENDENT
# INFORMATION the bottles carry about the global mean.
#
# IT IS NOT THE WHOLE SIGMA, AND THIS FILE DOES NOT PRETEND OTHERWISE. The
# residual the likelihood scores is (model box - observed mean), whose variance
# is Var(xbar_w) + REPRESENTATION^2 -- the second term being whether a ONE-BOX
# dynamical model can land on that mean at all. GLODAP cannot measure that; no
# estimator below touches it; and R/likelihood.R already records that it is
# deliberately zero. So a large measured n_eff does NOT license a small sigma on
# its own. Marcus has the representation question open separately.
#
# ---------------------------------------------------------------------
# FIVE ESTIMATORS, DELIBERATELY NOT AVERAGED. They bracket the answer and their
# DISAGREEMENT is informative:
#
#  1. KISH, weights only. Assumes cells are independent. An upper bound on
#     n_eff, and the number the current sigma would have to beat downwards.
#  2. CORRELOGRAM ESS. The formula above, with rho taken from the EMPIRICAL
#     binned correlogram -- not a fitted exponential, because the field is not
#     stationary and the far-field anticorrelation (young Atlantic against old
#     Pacific) is real signal that a parametric form would erase. Negative rho
#     is KEPT: antipodal anticorrelation genuinely makes the global mean better
#     determined, and flooring it at zero would be a thumb on the scale.
#  3. SPATIAL BLOCK BOOTSTRAP at four block sizes. Model-free. The sensitivity
#     to block size is itself the uncertainty on the answer.
#  4. LEAVE-ONE-BASIN-OUT. Interpretable rather than precise: it says which
#     basin the global mean is hostage to.
#  5. COVERAGE. How much of the layer is sampled at all.
#
# NO DETRENDING in the primary estimates. The basin-scale gradient is not
# nuisance structure to be removed -- it is exactly why more bottles in the
# Atlantic do not tell you the global mean. A detrended variant is reported
# because it answers the different question "what is the ESS of the residual
# field", and labeling which is which is the point.
#
# THIS FILE CHANGES NOTHING. It reports. `LIK_D14C_DEEP_NEFF` is Marcus'.
#
# RUNTIME ~1 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants ------------------------------------------------
NE_FILE     <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
NE_FLAG_OK  <- 2
NE_DLAT     <- 5; NE_DLON <- 10; NE_DZ <- 250   # the build script's cells
# THE SHIPPED TARGET IS "BELOW 2627.2 m", NOT "2627.2-3700 m", and the gate in
# part 0 is what caught me assuming otherwise. build_glodap_deep_targets.R calls
# gd_binned(..., zmax = 1e5), so bottles deeper than the model's 3700 m floor
# ARE in the target. Restricting to the model's actual box gives -177.81 permil
# against the shipped -175.26 -- 0.25 sigma, reported in part 0 as a property of
# the target rather than silently corrected here. n_eff MUST be measured for the
# shipped definition or it would be an n_eff for a different quantity.
NE_LAYER    <- c(2627.2, 1e5)                   # as the build script defines it
NE_LAYER_BOX <- c(2627.2, 3700)                 # the model's bottom box, for the note
NE_DBINS    <- c(0, 1, 250, 500, 1000, 1500, 2000, 3000, 4000, 5000,
                 6000, 8000, 10000, 12000, 15000, 20100)   # km
NE_BLOCKS   <- c(10, 20, 30, 60)                # degrees of latitude per block
NE_NBOOT    <- 4000
NE_R_EARTH  <- 6371                             # km
NE_ISO_RDS  <- ccx_path("calibration", "output", "ocean_candidates",
                        "diag_ocean_candidates.rds")
NE_OUTDIR   <- ccx_path("calibration", "output", "deep_d14c_neff")

dir.create(NE_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
set.seed(20260816)   # Date.now()-free: a fixed seed, stated, so this reproduces

# ---- the cells, EXACTLY as data-raw/build_glodap_deep_targets.R makes them --
# Same binning and same cos(lat) weighting, so that sigma = sd_w / sqrt(n_eff)
# below is the SHIPPED formula with a measured denominator, not a new estimator
# with a new numerator. Verified against the built rds at the end of part 0.
d  <- utils::read.csv(NE_FILE)
ok <- is.finite(d$c14) & d$c14 > -900 & is.finite(d$c14f) & d$c14f == NE_FLAG_OK &
      d$depth >= NE_LAYER[1] & d$depth <= NE_LAYER[2]
x  <- d[ok, ]
id <- paste(floor(x$lat / NE_DLAT), floor(x$lon / NE_DLON), floor(x$depth / NE_DZ))
cell <- data.frame(
  v   = as.numeric(tapply(x$c14,   id, mean)),
  lat = as.numeric(tapply(x$lat,   id, mean)),
  lon = as.numeric(tapply(x$lon,   id, mean)),
  z   = as.numeric(tapply(x$depth, id, mean)))
cell$w <- cos(cell$lat * pi / 180)
n  <- nrow(cell); w <- cell$w; v <- cell$v
mu <- sum(w * v) / sum(w)
sd_w <- sqrt(sum(w * (v - mu)^2) / sum(w))

sep("PART 0. THE CELLS, AND A GATE AGAINST THE SHIPPED TARGET")
g  <- readRDS(ccx_path("data", "obs_glodap_deep.rds"))
tg <- ccx_deep_d14c_target()
cat(sprintf("bottles %d -> cells %d (%g deg lat x %g deg lon x %g m)\n",
            nrow(x), n, NE_DLAT, NE_DLON, NE_DZ))
cat(sprintf("volume-weighted mean  here %.4f   built rds %.4f   |d| %.2e\n",
            mu, g$d14c$deep$vw, abs(mu - g$d14c$deep$vw)))
cat(sprintf("weighted sd           here %.4f   built rds %.4f   |d| %.2e\n",
            sd_w, g$d14c$deep$sd_w, abs(sd_w - g$d14c$deep$sd_w)))
if (abs(mu - g$d14c$deep$vw) > 1e-6 || abs(sd_w - g$d14c$deep$sd_w) > 1e-6)
  stop("cells do not reproduce the built target -- the n_eff below would be for a different quantity")
cat("PASS -- these are the same cells the shipped target is built from.\n")
cat(sprintf("\nIN USE NOW: n_eff = %d (ASSERTED) -> sigma = %.2f permil\n",
            tg$n_eff, tg$sd))
# A property of the target worth stating once, since the gate above surfaced it.
okb <- ok & d$depth <= NE_LAYER_BOX[2]
xb  <- d[okb, ]
idb <- paste(floor(xb$lat / NE_DLAT), floor(xb$lon / NE_DLON), floor(xb$depth / NE_DZ))
vb  <- as.numeric(tapply(xb$c14, idb, mean))
wb  <- cos(as.numeric(tapply(xb$lat, idb, mean)) * pi / 180)
cat(sprintf("\nFOR THE RECORD: the target is everything BELOW %.1f m, so bottles deeper\n",
            NE_LAYER[1]))
cat(sprintf("than the model's %g m floor are in it. Restricting to the model's actual\n",
            NE_LAYER_BOX[2]))
cat(sprintf("box gives %.2f permil over %d cells against the shipped %.2f -- %.2f sigma.\n",
            sum(wb * vb) / sum(wb), length(vb), mu,
            abs(sum(wb * vb) / sum(wb) - mu) / tg$sd))
cat("Flagged, not changed: it is a target definition, and it is Marcus'.\n")

# ---- great-circle distance, km, cells x cells ------------------------
# Same horizontal cell at a different depth bin gives d = 0 and lands in the
# first bin, so the near-perfect vertical correlation inside one column is
# CARRIED by the correlogram rather than assumed away.
rad <- pi / 180
la <- cell$lat * rad; lo <- cell$lon * rad
D <- outer(sin(la), sin(la)) +
     outer(cos(la), cos(la)) * cos(outer(lo, lo, "-"))
D <- NE_R_EARTH * acos(pmin(pmax(D, -1), 1))
diag(D) <- 0

sep("PART 1. THE EMPIRICAL CORRELOGRAM (no detrending -- see the header)")
cnt <- v - mu
CV  <- outer(cnt, cnt)                       # covariance contributions
C0  <- sd_w^2
off <- upper.tri(D)
db  <- cut(D[off], NE_DBINS, right = FALSE)
cv  <- CV[off]
rho_bin <- tapply(cv, db, mean) / C0
npair   <- tapply(cv, db, length)
mid     <- (NE_DBINS[-length(NE_DBINS)] + NE_DBINS[-1]) / 2
cat(sprintf("%16s %10s %9s\n", "distance km", "pairs", "rho"))
for (k in seq_along(rho_bin)) {
  if (is.na(rho_bin[k])) next
  cat(sprintf("%16s %10d %+9.3f", levels(db)[k], npair[k], rho_bin[k]))
  if (k == 1) cat("   <- same column, different depth bin")
  cat("\n")
}
first_neg <- mid[which(!is.na(rho_bin) & rho_bin < 0)[1]]
half      <- mid[which(!is.na(rho_bin) & rho_bin < 0.5)[1]]
cat(sprintf("\nrho falls below 0.5 by ~%.0f km and goes NEGATIVE by ~%.0f km.\n",
            half, first_neg))
cat("The negative tail is the young Atlantic against the old Pacific. It is\n")
cat("real, it is KEPT, and it is why the global mean is better determined than\n")
cat("a positive-only correlation model would say.\n")

# ---- the double sum --------------------------------------------------
rho_of <- approxfun(mid[!is.na(rho_bin)], rho_bin[!is.na(rho_bin)],
                    rule = 2, yleft = rho_bin[!is.na(rho_bin)][1])
R <- matrix(rho_of(D), n, n); diag(R) <- 1
S <- sum(w * (R %*% w))
n_corr <- sum(w)^2 / S
n_kish <- sum(w)^2 / sum(w^2)
# THE NEGATIVE TAIL DOES REAL WORK IN THAT DOUBLE SUM, so measure how much
# rather than leave it implicit: the same calculation with rho floored at 0.
# If the two answers are far apart, the estimate rests on the anticorrelation
# being a real feature of the ocean and not an artifact of nonstationarity.
Rf <- pmax(R, 0); diag(Rf) <- 1
Sf <- sum(w * (Rf %*% w))
n_corr_floor <- sum(w)^2 / Sf

sep("PART 2. ESTIMATORS 1-2: KISH AND THE CORRELOGRAM ESS")
cat(sprintf("%-46s %10s %10s\n", "estimator", "n_eff", "sigma"))
cat(sprintf("%-46s %10.0f %10.2f\n", "1. Kish, weights only (rho = delta)",
            n_kish, sd_w / sqrt(n_kish)))
cat(sprintf("%-46s %10.1f %10.2f\n", "2. correlogram ESS (empirical rho)",
            n_corr, sd_w / sqrt(n_corr)))
if (S <= 0) cat("   NOTE: the double sum went non-positive -- do not use row 2.\n")
cat(sprintf("%-46s %10.1f %10.2f\n", "2b. same, rho floored at 0 (no anticorrelation)",
            n_corr_floor, sd_w / sqrt(n_corr_floor)))
cat(sprintf("\n   THE NEGATIVE TAIL DOES ALL THE WORK: flooring rho at 0 moves n_eff\n"))
cat(sprintf("   %.1f -> %.1f, a factor of %.0f. Row 2 is therefore NOT a point estimate;\n",
            n_corr, n_corr_floor, n_corr / n_corr_floor))
cat("   rows 2 and 2b are a BRACKET, and which end is right is a question about\n")
cat("   the ocean, not about the arithmetic:\n")
cat("     * the deep Atlantic (-108.5) really is young and the deep Pacific\n")
cat("       (-211.5) really is old, and they really are on opposite sides of the\n")
cat("       globe. If that contrast is DETERMINISTIC STRUCTURE WE HAVE SAMPLED,\n")
cat("       the global mean is well determined and row 2 (n_eff ~110) is right.\n")
cat("     * if the basins are better thought of as a handful of exchangeable\n")
cat("       water masses whose values we happen to know, row 2b (n_eff ~6) is.\n")
cat("   The correlated-mean formula is a RANDOM-FIELD formula; applying it to a\n")
cat("   field with large deterministic structure is exactly where it stops being\n")
cat("   well posed. This is the residual ambiguity the measurement does NOT\n")
cat("   remove, and part 6 shows it straddles the decision.\n")
# The same thing on the DETRENDED field, which answers a DIFFERENT question and
# is labeled as such: the ESS of the residual after the basin-scale structure
# is removed. Larger by construction; it is NOT the estimand.
fit  <- stats::lm(v ~ poly(lat, 2) + sin(lon * rad) + cos(lon * rad), data = cell,
                  weights = w)
rs   <- stats::resid(fit)
CVr  <- outer(rs - sum(w * rs) / sum(w), rs - sum(w * rs) / sum(w))
rb   <- tapply(CVr[off], db, mean) / (sum(w * (rs - sum(w * rs) / sum(w))^2) / sum(w))
rf   <- approxfun(mid[!is.na(rb)], rb[!is.na(rb)], rule = 2)
Rr   <- matrix(rf(D), n, n); diag(Rr) <- 1
Sd <- sum(w * (Rr %*% w))
n_det <- sum(w)^2 / Sd
# GUARD, and it fired on the first run: with the basin structure regressed out,
# the residual correlogram's negative tail drives the double sum NEGATIVE and
# n_eff comes back as -4630. A negative effective sample size is not a small
# n_eff, it is a broken estimator -- the correlated-mean formula assumes a valid
# (positive semi-definite) correlation function, and a binned empirical rho
# interpolated across a nonstationary field is not guaranteed to be one.
# Reported as unusable rather than printed as a number.
cat(sprintf("%-46s %10s %10s\n", "   (detrended residual -- NOT the estimand)",
            if (Sd > 0) sprintf("%.1f", n_det) else "UNUSABLE", "--"))
if (Sd <= 0)
  cat("   detrended double sum went NEGATIVE -- the interpolated empirical rho is\n   not positive semi-definite on that field. Estimator dropped, not reported.\n")
cat(sprintf("   R^2 of the removed large-scale trend: %.2f\n",
            summary(fit)$r.squared))

sep("PART 3. ESTIMATOR 3: SPATIAL BLOCK BOOTSTRAP")
cat("Model-free. Resample whole spatial blocks with replacement and recompute\n")
cat("the volume-weighted mean. The spread ACROSS block sizes is the honest\n")
cat("uncertainty on n_eff, so all four are reported and none is preferred.\n\n")
cat("READ THIS AGAINST PART 1: a block bootstrap is only valid when the block\n")
cat("EXCEEDS the decorrelation scale, and part 1 puts rho = 0.5 at ~5500 km and\n")
cat("rho = 0 at ~7000 km. 60 deg of latitude is ~6700 km, 10 deg is ~1100 km. So\n")
cat("the small-block rows BREAK correlation inside their own blocks and are\n")
cat("biased HIGH; the 30-60 deg rows are the methodologically valid ones, and\n")
cat("they are also the noisiest (33 and 16 blocks). Monotone decline with block\n")
cat("size is the expected signature, not a defect.\n\n")
cat(sprintf("%-22s %8s %10s %10s %10s\n", "block", "blocks", "SE permil",
            "n_eff", "sigma"))
boot <- list()
for (B in NE_BLOCKS) {
  bid  <- paste(floor(cell$lat / B), floor(cell$lon / (2 * B)))
  ub   <- unique(bid); nb <- length(ub)
  idxs <- split(seq_len(n), bid)
  m <- vapply(seq_len(NE_NBOOT), function(i) {
    k <- unlist(idxs[sample.int(nb, nb, replace = TRUE)], use.names = FALSE)
    sum(w[k] * v[k]) / sum(w[k])
  }, numeric(1))
  se <- stats::sd(m); ne <- (sd_w / se)^2
  boot[[as.character(B)]] <- list(nb = nb, se = se, n_eff = ne)
  cat(sprintf("%-22s %8d %10.3f %10.1f %10.2f\n",
              sprintf("%g deg lat x %g lon", B, 2 * B), nb, se, ne,
              sd_w / sqrt(ne)))
}

sep("PART 4. ESTIMATOR 4: LEAVE-ONE-BASIN-OUT")
cat("Crude longitude/latitude masks, stated as crude. This is interpretable,\n")
cat("not precise: it says which basin the global mean is hostage to.\n\n")
bas <- with(cell, ifelse(lat > 66, "Arctic",
             ifelse(lat < -35, "Southern",
             ifelse(lon > -70 & lon <= 20, "Atlantic",
             ifelse(lon > 20 & lon <= 120, "Indian", "Pacific")))))
cat(sprintf("%-12s %8s %10s %12s %12s\n", "basin", "cells", "mean", "wt share %",
            "mean w/o it"))
for (b in sort(unique(bas))) {
  k <- bas == b
  cat(sprintf("%-12s %8d %10.1f %12.1f %12.2f\n", b, sum(k),
              sum(w[k] * v[k]) / sum(w[k]), 100 * sum(w[k]) / sum(w),
              sum(w[!k] * v[!k]) / sum(w[!k])))
}
lo1 <- vapply(sort(unique(bas)), function(b)
  sum(w[bas != b] * v[bas != b]) / sum(w[bas != b]), numeric(1))
cat(sprintf("\nfull mean %.2f; leave-one-out range %.2f to %.2f (span %.2f permil)\n",
            mu, min(lo1), max(lo1), diff(range(lo1))))

sep("PART 5. ESTIMATOR 5: COVERAGE")
hcell <- unique(paste(floor(cell$lat / NE_DLAT), floor(cell$lon / NE_DLON)))
cat(sprintf("horizontal 5x10 cells sampled: %d\n", length(hcell)))
cat(sprintf("depth bins per sampled column, median %.1f (max %d)\n",
            stats::median(table(paste(floor(cell$lat / NE_DLAT),
                                      floor(cell$lon / NE_DLON)))),
            max(table(paste(floor(cell$lat / NE_DLAT), floor(cell$lon / NE_DLON))))))
cat("\nWHAT THIS CANNOT SAY, and it is a real gap: the DENOMINATOR -- how many\n")
cat("5x10 cells contain ocean deeper than 2627 m -- needs bathymetry this repo\n")
cat("does not carry. So coverage is reported as a count, not a fraction, and\n")
cat("the unsampled-volume contribution to Var(xbar_w) is NOT in any number\n")
cat("above. It would push n_eff DOWN.\n")

# =====================================================================
# PART 6. WHAT EACH ANSWER DOES TO THE DECISION IN FRONT OF MARCUS
# =====================================================================
sep("PART 6. THE CONSEQUENCE, RECOMPUTED LIVE")
cat("Candidate A's iso-sink rows, re-read from diag_ocean_candidates.R rather\n")
cat("than copied, so this table cannot go stale against them.\n")
if (!file.exists(NE_ISO_RDS)) {
  cat("\ndiag_ocean_candidates.rds absent -- run it first for this part.\n")
} else {
  iso  <- readRDS(NE_ISO_RDS)$iso
  dInf <- iso[["Inf"]]$deep; d50 <- iso[["5000"]]$deep; d12 <- iso[["1200"]]$deep
  # Non-deep streams cost A a FIXED amount, independent of this sigma: back it
  # out at the sigma actually used, then re-price only the deep term.
  pen  <- function(dev, s) dev^2 / (2 * s^2)
  gain <- function(s) pen(dInf - tg$target, s) - pen(d50 - tg$target, s)
  netA <- iso[["5000"]]$total - iso[["Inf"]]$total
  other <- netA - gain(tg$sd)
  cat(sprintf("\nA's measured net at the sigma in use: %+.2f log-units, of which\n", netA))
  cat(sprintf("the deep term supplies %+.2f and everything else %+.2f (sigma-independent).\n",
              gain(tg$sd), other))
  cand <- c("1. Kish (weights only)" = n_kish,
            "2. correlogram ESS"     = n_corr,
            setNames(vapply(boot, function(b) b$n_eff, numeric(1)),
                     sprintf("3. block bootstrap, %s deg", names(boot))),
            "   -- asserted n_eff = 20 (incumbent)" = 20)
  cat(sprintf("\n%-40s %8s %8s %12s %10s\n", "estimator", "n_eff", "sigma",
              "A net logL", "A adopted?"))
  for (k in seq_along(cand)) {
    s <- sd_w / sqrt(cand[k]); nt <- gain(s) + other
    cat(sprintf("%-40s %8.1f %8.2f %+12.2f %10s\n", names(cand)[k], cand[k], s,
                nt, if (nt > 0) "yes" else "no"))
  }
  # THE CROSSOVER. Net(sigma) = 303-ish/(2 sigma^2) + other = 0 has a closed form,
  # so state the threshold rather than leaving it to be read off the table.
  dev2 <- (dInf - tg$target)^2 - (d50 - tg$target)^2
  sig_x <- sqrt(dev2 / (-2 * other)); nx <- (sd_w / sig_x)^2
  cat(sprintf("\nCROSSOVER: A is adopted for any sigma < %.2f permil, i.e. n_eff > %.1f.\n",
              sig_x, nx))
  cat("THE MEASUREMENT BRACKETS THAT THRESHOLD RATHER THAN CLEARING IT.\n")
  cat(sprintf("  defensible range: n_eff ~%.1f (correlogram, rho floored) to ~%.0f\n",
              n_corr_floor, boot[["30"]]$n_eff))
  cat("  (30-degree blocks), against a crossover at 7.9. The asserted 20 sits\n")
  cat("  inside it and on the ADOPTING side.\n")
  cat("  Ruled OUT by the measurement: the full-spread sigma 45.88 (n_eff = 1),\n")
  cat("  which was the only one of the five original candidates that rejected A,\n")
  cat("  and Kish's 3408, which assumes an independence the correlogram refutes.\n")
  cat("  So the range narrows from 15x asserted to ~4x measured -- but it lands\n")
  cat("  ACROSS the threshold, not clear of it.\n")
  cat(sprintf("\nkz-runaway check (the job the sigma was ORIGINALLY chosen for):\n"))
  cat(sprintf("%-40s %8s %10s\n", "estimator", "sigma", "z vs -112.7"))
  for (k in seq_along(cand)) {
    s <- sd_w / sqrt(cand[k])
    cat(sprintf("%-40s %8.2f %10.1f %s\n", names(cand)[k], s,
                abs(g$kz_runaway_d14c - tg$target) / s,
                if (abs(g$kz_runaway_d14c - tg$target) / s > 3) "HOLDS" else "does not hold"))
  }
}

cat("\n\nSTILL NOT MEASURED BY ANY OF THIS, and both push sigma UP:\n")
cat(" * model REPRESENTATION error -- a one-box deep ocean against a field\n")
cat("   spanning -234 to -87 permil. R/likelihood.R records it as deliberately\n")
cat("   zero. It is Marcus' open question, not settled here.\n")
cat(" * UNSAMPLED VOLUME -- part 5 has no bathymetry denominator.\n")
cat("A measured n_eff therefore sets a CEILING on the term's weight, not the\n")
cat("weight itself. Do not read the largest n_eff as licence for the smallest\n")
cat("sigma.\n")

saveRDS(list(n = n, mu = mu, sd_w = sd_w, rho_bin = rho_bin, mid = mid,
             npair = npair, n_kish = n_kish, n_corr = n_corr, n_detrended = n_det,
             n_corr_floor = n_corr_floor, boot = boot, basin_leave1 = lo1,
             seed = 20260816),
        file.path(NE_OUTDIR, "diag_deep_d14c_neff.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(NE_OUTDIR, "diag_deep_d14c_neff.rds")))
