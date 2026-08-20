# =====================================================================
# diag_seas_rectification.R -- WHICH FORM DOES THE OBSERVED SEASONAL
#                              PRODUCTIVITY SHAPE ACTUALLY WANT?
#
# THE QUESTION, and why it is worth answering BEFORE touching the model. The
# 8-day product (data/obs_npp_seasonal_shape.rds) showed that a bare insolation
# curve cannot reproduce the observed shape: 11 % (NH) and 13-14 % (SH) of the
# cycle is residual that NO single latitude explains, and shape and amplitude
# want DIFFERENT latitudes (NH 50 vs 55; SH -16 vs -30). Three repairs are on
# the table and each means something different physically:
#
#   A. ONE LATITUDE, AS IS.  n(t) = I(phi,t) / mean I.  "The hemisphere behaves
#      like one patch of land at phi, and its productivity tracks the sun angle
#      there." The residual is accepted as the cost of a one-patch idealisation.
#
#   B. RECTIFICATION.  Plants do not photosynthesise in proportion to light --
#      below some level (frozen soil, no leaves) they do nothing at all, and the
#      growing season SWITCHES ON. That off-switch is why phi = 75 ever worked:
#      polar night supplies one for free. Making it explicit SEPARATES where the
#      vegetation is (measurable, ~50 N) from how sharply it switches on (a
#      phenology property). Two families are tried, both NESTING form A:
#        B1 threshold  n ~ max(0, I - c*mean I)      c = 0 -> A
#        B2 power      n ~ (I / mean I)^gamma        gamma = 1 -> A
#
#   C. SHAPE AND SIZE SET SEPARATELY.  n = 1 + A*(I/mean I - 1). phi sets WHEN
#      the cycle peaks and how it is shaped; A sets HOW BIG the swing is. This
#      is what the existing `seas_npp_amp_{NH,SH}` switch already does (added
#      08-20f, identity default), so C is the only one of the three that needs
#      no new code. Physically it says: the productive land sits where the shape
#      says it does, but its swing is bigger (or smaller) than that latitude's
#      light cycle alone would drive -- which is exactly what a water-limited
#      wet/dry tropical cycle looks like from the atmosphere.
#
# THIS IS AN OFFLINE TEST ON DATA ALREADY ON DISK. No model runs, no rebuild,
# no calibration. It prices B before anyone writes the core change B needs, and
# it says whether C's extra freedom buys anything the data can see. What it
# CANNOT say is which form the CO2 and d13C records prefer -- that is
# diag_phi_eff_profile.R's job, and the two answers are independent.
#
# ALL FORMS ARE FITTED THE SAME WAY: window-integrated onto the 8-day
# composites (never point-sampled), with a FREE circular time shift, and scored
# by rms residual as a FRACTION of the observed peak-to-peak so the four
# hemisphere/variable cases are comparable to each other.
#
# Usage:  Rscript calibration/diag_seas_rectification.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

RC_IN     <- ccx_path("data", "obs_npp_seasonal_shape.rds")
RC_NGRID  <- 720
RC_SHIFTS <- seq(0, 11.75, by = 0.25)          # months
RC_PHI    <- seq(5, 89, by = 0.5)              # magnitude; sign from the hemisphere
RC_THRESH <- seq(0, 0.95, by = 0.025)          # c, as a fraction of the annual mean
RC_POWER  <- seq(0.4, 5, by = 0.1)             # gamma
RC_AMP    <- seq(0.3, 4, by = 0.025)           # A

ss <- readRDS(RC_IN)
tt <- (seq_len(RC_NGRID) - 0.5) / RC_NGRID
p2p <- function(x) max(x) - min(x)

# The window operator, rebuilt here from the product's own midpoints so this
# script does not have to trust a saved matrix.
window_op <- function(mid, days, ndays) {
  half <- (days / ndays) / 2
  W <- matrix(0, nrow = length(mid), ncol = RC_NGRID)
  for (i in seq_along(mid)) {
    inw <- ((tt - (mid[i] - half[i])) %% 1) <= ((2 * half[i]) %% 1)
    W[i, inw] <- 1 / sum(inw)
  }
  W
}
# Best fit of a BANK of candidate shapes (columns) to one target, over a free
# circular shift. Same roll direction as build_npp_seasonal_shape.R -- the
# columns advance, they do not retreat.
best_over_shift <- function(W, bank, target) {
  best <- list(sse = Inf)
  for (s in RC_SHIFTS) {
    k <- round(s / 12 * RC_NGRID) %% RC_NGRID
    M <- (if (k == 0) W else W[, c((k + 1):RC_NGRID, seq_len(k)), drop = FALSE]) %*% bank
    e <- colSums((M - target)^2); j <- which.min(e)
    if (e[j] < best$sse) best <- list(sse = e[j], j = j, shift_mo = s)
  }
  best
}
unitmean <- function(v) v / mean(v)

cat(sprintf("observed shape product: %d years, %s\n\n", length(ss$years),
            paste(ss$years, collapse = " ")))

# Window geometry: taken from the product; every year has the same 8-day layout
# except a leap year's final composite, and the fit is done per year anyway.
mk_geom <- function(mid) {
  d <- round(diff(c(mid, mid[1] + 1)) * 365)   # days per window, from the midpoints
  list(mid = mid, days = d, ndays = sum(d))
}

rows <- list()
for (nm in names(ss$fits)) {
  x   <- ss$fits[[nm]]
  sgn <- if (x$hemisphere == "NH") 1 else -1
  g   <- mk_geom(x$mid)
  W   <- window_op(g$mid, g$days, g$ndays)
  # Candidate banks. Each column is one unit-mean shape on the 720-point grid.
  I   <- vapply(RC_PHI * sgn, function(phi) ccx_insol(phi, tt), numeric(RC_NGRID))
  bankA <- apply(I, 2, unitmean)
  bankB1 <- do.call(cbind, lapply(RC_THRESH, function(c0)
    apply(I, 2, function(v) { r <- pmax(0, v - c0 * mean(v)); if (mean(r) <= 0) v * NA else unitmean(r) })))
  bankB2 <- do.call(cbind, lapply(RC_POWER, function(gm)
    apply(I, 2, function(v) unitmean(unitmean(v)^gm))))
  bankC <- do.call(cbind, lapply(RC_AMP, function(A)
    apply(I, 2, function(v) 1 + A * (unitmean(v) - 1))))
  for (b in c("bankB1", "bankB2", "bankC")) {
    m <- get(b); m[!is.finite(m)] <- 1e6; assign(b, m)
  }

  for (iy in seq_along(x$years)) {
    tgt <- x$shape_by_year[, iy]; amp <- p2p(tgt)
    fa  <- best_over_shift(W, bankA,  tgt)
    fb1 <- best_over_shift(W, bankB1, tgt)
    fb2 <- best_over_shift(W, bankB2, tgt)
    fc  <- best_over_shift(W, bankC,  tgt)
    idx <- function(j) c(phi = RC_PHI[((j - 1) %% length(RC_PHI)) + 1] * sgn,
                         k   = (j - 1) %/% length(RC_PHI) + 1)
    rows[[length(rows) + 1]] <- data.frame(
      case = nm, year = x$years[iy], obs_p2p = amp,
      A_res   = sqrt(fa$sse  / nrow(W)) / amp, A_phi = idx(fa$j)[["phi"]],
      B1_res  = sqrt(fb1$sse / nrow(W)) / amp, B1_phi = idx(fb1$j)[["phi"]],
      B1_c    = RC_THRESH[idx(fb1$j)[["k"]]],
      B2_res  = sqrt(fb2$sse / nrow(W)) / amp, B2_phi = idx(fb2$j)[["phi"]],
      B2_g    = RC_POWER[idx(fb2$j)[["k"]]],
      C_res   = sqrt(fc$sse  / nrow(W)) / amp, C_phi = idx(fc$j)[["phi"]],
      C_A     = RC_AMP[idx(fc$j)[["k"]]],
      stringsAsFactors = FALSE)
  }
}
d <- do.call(rbind, rows)

cat("=== UNEXPLAINED RESIDUAL, rms as a FRACTION of the observed peak-to-peak ===\n")
cat("(mean over years; lower is better. A is the incumbent form.)\n\n")
cat(sprintf("  %-12s %8s | %8s %7s %7s | %8s %7s %7s | %8s %7s %7s\n",
            "case", "A", "B1", "phi", "c", "B2", "phi", "gamma", "C", "phi", "A"))
for (nm in unique(d$case)) {
  z <- d[d$case == nm, ]
  cat(sprintf("  %-12s %7.1f%% | %7.1f%% %7.1f %7.3f | %7.1f%% %7.1f %7.2f | %7.1f%% %7.1f %7.2f\n",
              nm, 100 * mean(z$A_res),
              100 * mean(z$B1_res), mean(z$B1_phi), mean(z$B1_c),
              100 * mean(z$B2_res), mean(z$B2_phi), mean(z$B2_g),
              100 * mean(z$C_res), mean(z$C_phi), mean(z$C_A)))
}
cat("\n  A  = insolation at one latitude (the incumbent)\n")
cat("  B1 = thresholded insolation, max(0, I - c*mean I)      -- c = 0 recovers A\n")
cat("  B2 = powered insolation, (I/mean I)^gamma              -- gamma = 1 recovers A\n")
cat("  C  = amplitude-rescaled, 1 + A*(I/mean I - 1)          -- A = 1 recovers A\n")
cat("       C is what seas_npp_amp_{NH,SH} ALREADY does; the others need core edits.\n")

cat("\n=== HOW MUCH EACH REPAIR BUYS, as a fraction of the incumbent's residual ===\n")
for (nm in unique(d$case)) {
  z <- d[d$case == nm, ]
  cat(sprintf("  %-12s B1 %5.0f%%   B2 %5.0f%%   C %5.0f%%   of A's residual remains\n", nm,
              100 * mean(z$B1_res) / mean(z$A_res),
              100 * mean(z$B2_res) / mean(z$A_res),
              100 * mean(z$C_res)  / mean(z$A_res)))
}
cat("\nA form that leaves ~100 % of the residual has bought nothing the shape can see.\n")
cat("Each of B1, B2, C adds exactly ONE parameter, so they are directly comparable.\n")
# ---------------------------------------------------------------------
# IS FORM C's LATITUDE ACTUALLY DETERMINED? -- the question that decides
# whether "phi = 75 with the amplitude halved" is a finding or an artefact
# ---------------------------------------------------------------------
# C adds a free amplitude, so it MUST beat A; the useful question is whether the
# residual is sharply minimised at one phi or nearly flat across a wide range.
# If it is flat, (phi = 50, A ~ 1.2) is as good as (phi = 75, A ~ 0.5) and the
# less exotic one wins on every other ground. This profiles C's residual with A
# re-optimised at EVERY phi, which is the only fair way to read it.
cat("\n=== FORM C: residual vs phi, with A re-optimised at each phi ===\n")
for (nm in names(ss$fits)) {
  x <- ss$fits[[nm]]; sgn <- if (x$hemisphere == "NH") 1 else -1
  g <- mk_geom(x$mid); W <- window_op(g$mid, g$days, g$ndays)
  show_phi <- if (sgn > 0) c(38.35, 45, 50, 55, 65, 75, 85) else c(-15.75, -20, -25, -30, -40, -50)
  cat(sprintf("  %-12s", nm))
  for (ph in show_phi) {
    v <- unitmean(ccx_insol(ph, tt))
    bank <- vapply(RC_AMP, function(A) 1 + A * (v - 1), numeric(RC_NGRID))
    r <- vapply(seq_along(x$years), function(iy) {
      tgt <- x$shape_by_year[, iy]
      f <- best_over_shift(W, bank, tgt)
      c(res = sqrt(f$sse / nrow(W)) / p2p(tgt), A = RC_AMP[f$j])
    }, numeric(2))
    cat(sprintf("  %g:%.1f%%/A%.2f", ph, 100 * mean(r["res", ]), mean(r["A", ])))
  }
  cat("\n")
}
cat("  Read as phi : residual / fitted amplitude factor. A FLAT row means the\n")
cat("  latitude is NOT determined once amplitude is free, and the choice should\n")
cat("  be made on other grounds (the fit, or interpretability).\n")

cat("\nNOTE: this scores the SHAPE only. Whether the CO2 and d13C records prefer the\n")
cat("same form is a separate question and belongs to diag_phi_eff_profile.R.\n")
