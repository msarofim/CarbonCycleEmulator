# =====================================================================
# diag_hml_c1_remap_price.R -- 2026-08-29.  PLAN ITEM (2), STEP 2: PRICE.
#
# Step 1 (diag_hml_c1_kinkmap.R) re-measured the C1 defect on the LIVE support
# [30,200] that the sigma-inflation adoption opened up: 26 kinks, not the 3 the
# retired [85,120] band showed, clustered on the 25 m GLODAP bin edges.
#
# THE CANDIDATE FIX. The kink is a BOX FILTER with hard edges: the stored shape
# is treated as piecewise-CONSTANT within each observed bin, so its antiderivative
# is only piecewise-linear and the layer mean (S(b)-S(a))/(b-a) has slope jumps
# wherever a layer boundary crosses a bin edge. Make the shape a CONTINUOUS
# function of depth and the antiderivative becomes C2, so the layer mean is C1
# in every layer boundary -- including h_ml.
#
# TWO CANDIDATES ARE PRICED, because the obvious one is not the right one.
#
#   MID  -- monotone cubic Hermite (Fritsch-Carlson, "monoH.FC") through the
#           observed BIN MIDPOINTS, integrated exactly. C1, but it REINTERPRETS
#           each bin AVERAGE as a point value at the midpoint, so on a curved
#           profile it stops reproducing the bin means. NOT conservative.
#
#   CUM  -- monotone C1 interpolation of the CUMULATIVE integral, which the bin
#           averages pin EXACTLY at every bin EDGE:
#               S(edge_j) = sum_{i<=j} (bot_i - top_i) * shape_i
#           then layer mean = (S(b) - S(a)) / (b - a). S is monotone because
#           shape >= 0, so monoH.FC applies to data that really are monotone.
#           This is C1 AND conservative: whenever a model layer spans whole
#           bins it reproduces the incumbent's answer exactly.
#
# CUM is the one that can honestly be called "a code fix, not a science change";
# MID is priced alongside it to show why that distinction is not free.
#
# ⚠ MEASURES AND PRICES ONLY. Defines the candidate remap LOCALLY; R/model.R is
#   NOT touched and nothing is adopted. Adoption is Marcus's call.
#
# Usage:  Rscript calibration/diag_hml_c1_remap_price.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
COMMIT <- ccx_git_stamp()

## ---- named constants --------------------------------------------------
BAND       <- c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)
PROBE_DZ   <- 0.01
KINK_MULT  <- 20
GL_N       <- 4                      # Gauss-Legendre points per knot interval
MODE_HML   <- 96.47                  # from90 / option-5 incumbent, ccx_hml_band_decode
REFIT_HML  <- 35.38                  # the ratified do-not-adopt option-5 refit
OUT_RDS    <- "outputs/diagnostics/hml_c1_remap_price.rds"

## ---- the candidate C1 remap ------------------------------------------
prof <- readRDS(ccx_path("data", "obs_glodap_deep.rds"))$dic_profile
zmid <- (prof$top + prof$bot) / 2
gl <- local({                                   # 4-pt Gauss-Legendre on [-1,1]
  x <- c(-0.8611363115940526, -0.3399810435848563, 0.3399810435848563, 0.8611363115940526)
  w <- c( 0.3478548451374538,  0.6521451548625461, 0.6521451548625461, 0.3478548451374538)
  list(x = x, w = w)
})

## -- candidate MID: monotone Hermite through bin midpoints -------------
fsh  <- stats::splinefun(zmid, prof$shape, method = "monoH.FC")
KNOT <- zmid
Sint_mid <- function(a, b) {
  if (b <= a) return(0)
  br <- sort(unique(c(a, b, KNOT[KNOT > a & KNOT < b]))); s <- 0
  for (i in seq_len(length(br) - 1)) {
    lo <- br[i]; hi <- br[i + 1]; hw <- (hi - lo) / 2; mid <- (hi + lo) / 2
    s <- s + hw * sum(gl$w * fsh(mid + hw * gl$x))
  }
  s
}
shape_mid <- function(grid) {
  zb <- c(0, cumsum(grid$dz))
  vapply(seq_along(grid$dz), function(k) Sint_mid(zb[k], zb[k + 1]) / (zb[k + 1] - zb[k]),
         numeric(1))
}

## -- candidate CUM: monotone C1 spline of the CUMULATIVE integral -------
# The bin averages pin S exactly at every bin EDGE. Interpolating S (not shape)
# is what keeps the remap conservative while making it C1.
EDGE   <- c(prof$top[1], prof$bot)
S_EDGE <- c(0, cumsum((prof$bot - prof$top) * prof$shape))
fS     <- stats::splinefun(EDGE, S_EDGE, method = "monoH.FC")
SH_TOP <- prof$shape[1]; SH_BOT <- prof$shape[nrow(prof)]
Sint_cum <- function(z) {                       # extrapolate flat outside the data
  if (z <= EDGE[1])              return(S_EDGE[1] + (z - EDGE[1]) * SH_TOP)
  if (z >= EDGE[length(EDGE)])   return(S_EDGE[length(S_EDGE)] +
                                          (z - EDGE[length(EDGE)]) * SH_BOT)
  fS(z)
}
shape_cum <- function(grid) {
  zb <- c(0, cumsum(grid$dz))
  vapply(seq_along(grid$dz), function(k)
    (Sint_cum(zb[k + 1]) - Sint_cum(zb[k])) / (zb[k + 1] - zb[k]), numeric(1))
}

## ---- gate A: does the kink signature vanish? -------------------------
kinkcount <- function(fn, band) {
  kh <- seq(band[1], band[2], by = PROBE_DZ)
  KS <- t(sapply(kh, function(h) fn(ccx_ocean_grid(h))))
  kt <- rowSums(abs(apply(KS, 2, function(v) diff(diff(v)))))
  kb <- which(kt > KINK_MULT * stats::median(kt) + 1e-14)
  if (!length(kb)) return(list(n = 0L, hit = 0L, ratio = NA_real_, kt = kt))
  grp <- cumsum(c(TRUE, diff(kb) > 1))
  list(n = length(unique(grp)), hit = length(kb),
       ratio = max(kt) / stats::median(kt), kt = kt)
}
cat("=====================================================================\n")
cat("PLAN ITEM (2) STEP 2 -- PRICING THE C1 REMAP (monotone Hermite, exact GL)\n")
cat(sprintf("Band [%g, %g] m, probe %.2f m, detector %dx median\n", BAND[1], BAND[2],
            PROBE_DZ, KINK_MULT))
cat("=====================================================================\n\n")
cat("GATE A -- does the kink signature vanish?\n")
kA <- kinkcount(ccx_pump_shape, BAND)
kM <- kinkcount(shape_mid,      BAND)
kC <- kinkcount(shape_cum,      BAND)
rr <- function(k) if (is.na(k$ratio)) max(k$kt)/stats::median(k$kt) else k$ratio
cat(sprintf("  incumbent (clamped overlap)      : %2d kinks, %2d probe hits, max/median = %.3g\n",
            kA$n, kA$hit, rr(kA)))
cat(sprintf("  MID (Hermite thru bin midpoints) : %2d kinks, %2d probe hits, max/median = %.3g\n",
            kM$n, kM$hit, rr(kM)))
cat(sprintf("  CUM (C1 cumulative, conservative): %2d kinks, %2d probe hits, max/median = %.3g\n",
            kC$n, kC$hit, rr(kC)))
gateA <- kC$n == 0L
cat(sprintf("  => GATE A (on CUM) %s\n\n", if (gateA) "PASS -- C1 restored" else "FAIL -- kinks survive"))

## ---- gate B: how far does the pump field move? -----------------------
# TOLERANCE IS SCALED TO THE QUANTITY, not hand-picked: the shape spans 0->1 by
# construction, and the layer-to-layer STEP is the scale the pump actually uses
# (the export is a difference of adjacent layers), so the change is reported as
# a fraction of the median |layer step| at the same h_ml.
cat("GATE B -- how far does the remapped field move? (scaled to the layer step)\n")
cat(sprintf("  %8s %6s %11s %11s %11s %11s\n", "h_ml", "nl", "med|step|",
            "MID max|d|", "MID % step", "CUM % step"))
movetab <- do.call(rbind, lapply(c(REFIT_HML, 50, 75, MODE_HML, 100, 150), function(h) {
  g <- ccx_ocean_grid(h); s0 <- ccx_pump_shape(g)
  dM <- max(abs(shape_mid(g) - s0)); dC <- max(abs(shape_cum(g) - s0))
  st <- stats::median(abs(diff(s0)))
  cat(sprintf("  %8.2f %6d %11.3e %11.3e %10.2f%% %10.2f%%\n", h, g$nl, st, dM,
              100 * dM / st, 100 * dC / st))
  data.frame(h_ml = h, nl = g$nl, step = st, dmid = dM, dcum = dC,
             frac_mid = dM / st, frac_cum = dC / st)
}))

## ---- gate C: conservation, and a CORRECTLY SPECIFIED overshoot test ----
# ⚠ The first version of this gate tested the INTERPOLANT for monotonicity and
#   "failed". That was a mis-specified gate, not a finding: the observed shape is
#   itself NON-monotone at depth (bins 27-29 read 1.0083, 1.0116, 1.0000), so a
#   monotone-preserving interpolant reproducing that is CORRECT. The property a
#   remap must actually have is NO OVERSHOOT beyond the local data range.
cat("\nGATE C -- conservation, and overshoot beyond the observed range\n")
zz  <- seq(EDGE[1], EDGE[length(EDGE)], length.out = 8001)
rng <- range(prof$shape)
ovs <- function(v) max(max(v) - rng[2], rng[1] - min(v), 0)
sh_mid_z <- fsh(zz)
sh_cum_z <- fS(zz, deriv = 1)                   # ANALYTIC dS/dz -- the reconstructed shape
cat(sprintf("  observed shape range            : [%.4f, %.4f]\n", rng[1], rng[2]))
# TOLERANCE SCALED TO THE QUANTITY, not hand-picked: the natural yardstick for
# "does the reconstruction invent structure" is the observed profile's own
# bin-to-bin step, since that is the finest real feature the data resolve.
BIN_STEP <- stats::median(abs(diff(prof$shape)))
cat(sprintf("  observed median |bin-to-bin step|: %.4f  (the tolerance scale)\n", BIN_STEP))
cat(sprintf("  MID overshoot beyond that range : %.3e  = %.2f%% of a bin step\n",
            ovs(sh_mid_z), 100 * ovs(sh_mid_z) / BIN_STEP))
cat(sprintf("  CUM overshoot beyond that range : %.3e  = %.2f%% of a bin step\n",
            ovs(sh_cum_z), 100 * ovs(sh_cum_z) / BIN_STEP))
# conservation: does the remap reproduce the bin means when a layer spans whole bins?
whole <- which(prof$top >= 100)[1:8]
err_mid <- max(abs(vapply(whole, function(i)
  Sint_mid(prof$top[i], prof$bot[i]) / (prof$bot[i] - prof$top[i]) - prof$shape[i], 0)))
err_cum <- max(abs(vapply(whole, function(i)
  (Sint_cum(prof$bot[i]) - Sint_cum(prof$top[i])) / (prof$bot[i] - prof$top[i]) - prof$shape[i], 0)))
cat(sprintf("  reproduce a whole observed bin's own mean (8 bins, max |err|):\n"))
cat(sprintf("     MID %.3e   CUM %.3e   (incumbent is 0 BY CONSTRUCTION)\n", err_mid, err_cum))
# ⚠ THE GLOBAL RANGE TEST IS TOO WEAK TO DECIDE THIS. What a remap really does
#   between bin edges is a SUB-BIN MODEL, and the data do not contain one. Check
#   each bin interval against its own LOCAL 3-bin range.
loc <- vapply(seq_len(length(EDGE) - 1), function(k) {
  sel <- zz >= EDGE[k] & zz <= EDGE[k + 1]
  nb  <- prof$shape[max(1, k - 1):min(nrow(prof), k + 1)]
  max(max(sh_cum_z[sel]) - max(nb), min(nb) - min(sh_cum_z[sel]), 0)
}, 0)
cat(sprintf("  SUB-BIN STRUCTURE (local 3-bin range): %d of %d intervals exceed it,\n",
            sum(loc > 1e-12), length(loc)))
cat(sprintf("     worst %.3e = %.1f%% of a bin step, near z = %.0f m (the thermocline)\n",
            max(loc), 100 * max(loc) / BIN_STEP, EDGE[which.max(loc)]))
cat("     ⚠ The INCUMBENT has a sub-bin model too -- piecewise CONSTANT -- which is\n")
cat("       equally absent from the data and is exactly what makes it kinked. Neither\n")
cat("       remap is 'the observations'; they are two different sub-bin assumptions.\n")
gateC <- err_cum < 1e-12 && ovs(sh_cum_z) < 0.05 * BIN_STEP
cat(sprintf("  => GATE C (on CUM) %s -- conservative to machine precision; overshoot under\n",
            if (gateC) "PASS" else "FAIL"))
cat(sprintf("     5%% of a bin step (%.4f)\n", 0.05 * BIN_STEP))

## ---- mutation test -----------------------------------------------------
cat("\nMUTATION TEST -- break what gate A guards\n")
shape_box <- function(grid) ccx_pump_shape(grid)                  # known-kinked
shape_lin <- function(grid) {                                     # C0-but-not-C1 control
  zb <- c(0, cumsum(grid$dz))
  fl <- stats::approxfun(zmid, prof$shape, rule = 2)
  vapply(seq_along(grid$dz), function(k) {
    zz <- seq(zb[k], zb[k + 1], length.out = 65); mean(fl(zz))
  }, numeric(1))
}
for (nm in c("incumbent box filter", "linear interp (C0 shape)", "CUM (candidate)")) {
  fn <- switch(nm, "incumbent box filter" = shape_box,
                   "linear interp (C0 shape)" = shape_lin,
                   shape_cum)
  kk <- kinkcount(fn, c(90, 110))
  cat(sprintf("   %-30s %2d kink(s) in [90,110]  GATE A %s\n", nm, kk$n,
              if (kk$n == 0L) "PASS" else "FAIL"))
}

saveRDS(list(gateA = list(incumbent = kA[c("n","hit","ratio")], mid = kM[c("n","hit","ratio")],
                          cum = kC[c("n","hit","ratio")], pass = gateA),
             gateB = movetab, gateC = list(err_mid = err_mid, err_cum = err_cum,
                                           overshoot_cum = ovs(sh_cum_z), bin_step = BIN_STEP,
                                           subbin_local = loc, pass = gateC),
             constants = list(band = BAND, probe_dz = PROBE_DZ, kink_mult = KINK_MULT, gl_n = GL_N),
             provenance = list(when = "2026-08-29",
                               commit = COMMIT)),
        OUT_RDS)
cat(sprintf("\nWrote %s\n", OUT_RDS))
