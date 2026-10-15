# =====================================================================
# build_sst_seas_amp_bracket.R -- MEASURE the weighting ambiguity on
# sst_seas_amp_{NH,SH}, so its prior width stops being a JUDGMENT.
#
# THE PROBLEM. `SST_SEAS_LOGSD` = 0.25 is a chosen number, labeled as chosen at
# R/calibrate.R:23: it stands in for the gap between the AREA-weighted
# hemispheric SST amplitude we can compute and the GAS-EXCHANGE-weighted one the
# parameter actually is. R/constants.R says outright "Nothing measures that gap
# today. Replacing this with a flux-weighted estimate would be a real
# improvement." The 2026-09-01 prior screen made it the live question: at the
# 25-parameter mode `sst_seas_amp_SH` is the largest flag at -4.71 -- and that z
# is partly a statement about a width nobody measured.
#
# ⛔ AND THE AMPLITUDE FACTORS ARE NOT TRUE OBSERVABLES (Marcus, 2026-09-01).
# That rules out the tempting move -- recompute a flux-weighted number and
# recenter the prior on it as if it were the truth. There is no observation of
# this parameter. What CAN be measured is the SPREAD ACROSS DEFENSIBLE
# WEIGHTINGS, and that spread is the width. So this file mirrors the LAND pair
# exactly: `ccx_bracket_lnorm()` over a LO/HI bracket whose width is the
# measured weighting ambiguity (see SEAS_T_AMP_*_OBS_LO/HI in R/constants.R --
# same product, two defensible masks). Nothing here asserts which weighting is
# right, and the bracket is deliberately wide enough to contain them all.
#
# ⚠ WEIGHT THE SERIES, THEN FIT -- NEVER FIT, THEN AVERAGE THE AMPLITUDES.
# The SH hemispheric mean is a ~76 % CANCELLATION between a subtropical limb
# peaking ~month 1.4 and a Southern Ocean limb peaking ~month 7.5. Those are
# VECTORS: a weighted mean of their AMPLITUDES is not the amplitude of their
# weighted MEAN, and the arc has already paid once for treating two limbs as
# scalars. Every number below is the harmonic fit OF the weighted-mean monthly
# series, which is also what build_seasonal_climatology.R does.
#
# THE WEIGHTS, and what each is honestly worth:
#   AREA   cos(lat)                    -- what is measurable. The incumbent
#                                          anchor; reproducing it is GATE 1.
#   FLUX   cos(lat) x |CT2022 ocean flux|  -- where carbon actually crosses the
#                                          interface, from an independent
#                                          product.
#   SOLU   cos(lat) x K0(SST) x pCO2   -- the LAW-shaped weight: dF/dT runs
#                                          through solubility and pCO2, both of
#                                          which we have.
# ⚠ NONE OF THESE IS k.K0, THE QUANTITY THE PHYSICS ACTUALLY WANTS. The gas
# transfer velocity k goes as wind^2 and NO WIND FIELD IS ON DISK, so k's
# spatial pattern is the one term none of these three carries. |CT2022 flux|
# additionally carries dpCO2, which is not part of the weight either -- it is a
# PROXY for exchange intensity, not a measurement of it. Both gaps are stated
# here rather than buried, and both widen rather than narrow the honest bracket.
#
# ⛔ WRITES NOTHING INTO R/constants.R. It prints the bracket and saves a
# provenance file; editing the constants is a separate, deliberate act.
#
# Usage:  Rscript data-raw/build_sst_seas_amp_bracket.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

DL <- "data-raw/downloads"
BR_ERSST <- file.path(DL, "ersst_v5_sst_mnmean.nc")
BR_CT    <- file.path(DL, "CT2022.flux1x1-monthly.nc")
BR_PCO2  <- file.path(DL, "MPI-ULB-SOM_FFN_clim.nc")
BR_OUT   <- "data-raw/downloads/sst_seas_amp_bracket.rds"

# MATCHES build_seasonal_climatology.R's SC_SST_WIN, which matches
# LIK_SEAS_WINDOW. A different window would measure a different thing and the
# gate below would fail -- which is the point of gating on the incumbent value.
BR_WIN <- c(1975, 2024)
# The incumbent AREA-weighted anchors, as GATE TARGETS. ⛔ These are read from
# the constants registry, NOT retyped: a gate that hardcodes its own target
# stops testing the thing it names the moment the constant moves.
BR_GATE_REL <- 1e-4     # relative; a pure re-computation of the same quantity

br_harm <- function(v) {
  phi <- (seq_len(12) - 0.5) / 12
  a1 <- 2 * mean(v * sin(2 * pi * phi)); b1 <- 2 * mean(v * cos(2 * pi * phi))
  list(half_amp = sqrt(a1^2 + b1^2), mean = mean(v),
       peak_month = 12 * ((atan2(a1, b1) / (2 * pi)) %% 1), clim = v)
}

# ⛔ A FINITE-FRACTION GATE IS NOT ENOUGH, AND THIS FILE PROVED IT ON ITS FIRST
# RUN. `fillvalue_not_applied` records ncdf4 leaving -999 over every land cell
# because the attribute was `FillValue` (no underscore) and stored as a STRING.
# I gated the finite fraction -- and MPI-ULB's pco2 came back "100.0 % finite,
# range [-999, 693]". ⚠ -999 IS FINITE. The gate reported a pass on poisoned
# data, which is the silent-gate family exactly.
# ⇒ EVERY READ DECLARES ITS PHYSICAL RANGE. Values outside it become NA and the
# removed fraction is PRINTED; a read that declares no range is refused outright
# if it contains anything sentinel-shaped. The bound now matches the claim being
# made -- "these are pCO2 values in uatm", not "these are numbers".
BR_SENTINELS <- c(-999, -9999, -1e30, 1e20, 9.96921e36)
br_get <- function(nc, v, tag, valid = NULL, ..., min_finite = 0.05) {
  x <- ncvar_get(nc, v, ...)
  n0 <- length(x)
  sent <- any(vapply(BR_SENTINELS, function(s) any(abs(x - s) < abs(s) * 1e-6, na.rm = TRUE),
                     logical(1)))
  if (is.null(valid)) {
    if (sent) stop(tag, ": contains a SENTINEL value and declares no `valid` range. ",
                   "ncdf4 did not apply the fill (see [[fillvalue_not_applied]]); ",
                   "give this read its physical range.")
  } else {
    bad <- is.finite(x) & (x < valid[1] | x > valid[2])
    if (any(bad)) {
      cat(sprintf("    %-22s ⚠ %.2f %% OUTSIDE [%g, %g] -> NA (unapplied fill?)\n",
                  tag, 100 * mean(bad), valid[1], valid[2]))
      x[bad] <- NA
    }
  }
  f <- mean(is.finite(x)); rng <- range(x[is.finite(x)])
  cat(sprintf("    %-22s finite %5.1f %%  range [%.4g, %.4g]%s\n", tag, 100 * f,
              rng[1], rng[2], if (sent) "   [sentinel found and handled]" else ""))
  if (f < min_finite)
    stop(tag, ": only ", round(100 * f, 2), " % finite -- check the fill value.")
  x
}

cat(sprintf("\n%s\nsst_seas_amp BRACKET -- the weighting ambiguity, MEASURED\n%s\n",
            strrep("=", 76), strrep("=", 76)))

# ---- ERSSTv5 monthly climatology on its own 2 deg grid ---------------
cat("\n[1] ERSSTv5\n")
nc  <- nc_open(BR_ERSST)
tim <- ncvar_get(nc, "time")
elat <- ncvar_get(nc, "lat"); elon <- ncvar_get(nc, "lon")
tt  <- as.POSIXlt(as.Date(tim, origin = "1800-01-01"))
yr  <- tt$year + 1900; mo <- tt$mon + 1
k   <- which(yr >= BR_WIN[1] & yr <= BR_WIN[2])
sst <- br_get(nc, "sst", "sst", valid = c(-2.5, 40),
              start = c(1, 1, min(k)), count = c(-1, -1, length(k)))
nc_close(nc)
sst[sst < -100 | sst > 100] <- NA
# monthly climatology field [lon, lat, 12]
SSTC <- array(NA_real_, c(length(elon), length(elat), 12))
for (m in 1:12) {
  kk <- which(mo[k] == m)
  SSTC[, , m] <- apply(sst[, , kk, drop = FALSE], c(1, 2), mean, na.rm = TRUE)
}
SSTC[!is.finite(SSTC)] <- NA
cat(sprintf("    climatology cells with data: %d of %d\n",
            sum(is.finite(SSTC[, , 1])), length(SSTC[, , 1])))

# ---- the weighted-mean amplitude, one function for every weight ------
# W is a [lon, lat] weight on the ERSST grid; cells missing SST drop out.
br_amp <- function(W, hemi) {
  sel <- if (hemi == "NH") which(elat >= 0) else which(elat < 0)
  v <- vapply(1:12, function(m) {
    x <- SSTC[, sel, m]; w <- W[, sel]
    ok <- is.finite(x) & is.finite(w) & w > 0
    if (!any(ok)) return(NA_real_)
    sum(x[ok] * w[ok]) / sum(w[ok])
  }, 0)
  br_harm(v)
}
W_area <- outer(rep(1, length(elon)), cos(elat * pi / 180))

# ---- GATE 1: reproduce the incumbent AREA-weighted anchors ------------
# ⛔ THE FOUNDATION. If this pipeline cannot reproduce the number already in the
# registry under the SAME weighting, every other weight it computes is wrong in
# some way this file cannot see. The target is READ from the registry.
cat("\n[2] GATE 1 -- reproduce the incumbent area-weighted anchors\n")
gate_ok <- TRUE
for (hh in c("NH", "SH")) {
  got <- br_amp(W_area, hh)$half_amp
  tgt <- ccx_const(sprintf("SST_SEAS_AMP_%s_OBS", hh))
  rel <- abs(got - tgt) / abs(tgt)
  cat(sprintf("    %s  here %.5f  registry %.5f  rel %.2e  %s\n", hh, got, tgt, rel,
              if (rel <= BR_GATE_REL) "OK" else "*** MISMATCH ***"))
  if (rel > BR_GATE_REL) gate_ok <- FALSE
}
if (!gate_ok)
  stop("GATE 1 FAILED: this file does not reproduce the registry's area-weighted ",
       "anchor. Every weighted amplitude below would be wrong for the same ",
       "reason. STOP AND DIAGNOSE -- window, mask, or the weight-then-fit order.")

# ---- FLUX weight: CT2022 ocean flux, regridded 1 deg -> 2 deg --------
cat("\n[3] CT2022 ocean flux -> exchange-intensity weight\n")
nc <- nc_open(BR_CT)
ctlon <- ncvar_get(nc, "longitude"); ctlat <- ncvar_get(nc, "latitude")
# mol m-2 s-1; +/-1e-4 is far outside anything physical and catches a fill.
ocn <- br_get(nc, "ocn_flux_opt", "ocn_flux_opt", valid = c(-1e-4, 1e-4))
nc_close(nc)
# annual-mean |flux| over the record: a FIXED spatial weight. ⚠ THIS IS A
# METHODOLOGICAL CHOICE AND IT IS FLAGGED, NOT BURIED -- see the month-varying
# sensitivity in [5]. A fixed weight asks "which waters does exchange sample";
# a month-varying one also folds in "when does exchange happen", which is a
# different question and can manufacture amplitude out of the weight itself.
ct_w <- apply(abs(ocn), c(1, 2), mean, na.rm = TRUE)
cat(sprintf("    CT grid %d x %d, lon [%.1f, %.1f]\n", length(ctlon), length(ctlat),
            min(ctlon), max(ctlon)))

# Regrid onto the ERSST grid by nearest-cell lookup on both axes. ERSST longitudes
# run 0..358; CT may run -180..179. Wrapped explicitly rather than assumed.
br_to_ersst <- function(M, mlon, mlat) {
  lon360 <- mlon %% 360
  ilon <- vapply(elon %% 360, function(x) which.min(abs(((lon360 - x + 180) %% 360) - 180)), 1L)
  ilat <- vapply(elat, function(y) which.min(abs(mlat - y)), 1L)
  M[ilon, ilat, drop = FALSE]
}
W_flux <- W_area * br_to_ersst(ct_w, ctlon, ctlat)
cat(sprintf("    regridded weight finite %.1f %%, >0 in %.1f %% of cells\n",
            100 * mean(is.finite(W_flux)), 100 * mean(is.finite(W_flux) & W_flux > 0)))

# ---- SOLUBILITY x pCO2 weight: the law-shaped one --------------------
# dF/dT runs through K0 (Weiss 1974) and pCO2. Both are available; k is not.
cat("\n[4] K0(SST) x pCO2 -> law-shaped weight (missing only k)\n")
br_K0 <- function(tC, S = 35) {                     # mol/(L.atm), Weiss 1974
  Tk <- tC + 273.15
  exp(-58.0931 + 90.5069 * (100 / Tk) + 22.2940 * log(Tk / 100) +
      S * (0.027766 - 0.025888 * (Tk / 100) + 0.0050578 * (Tk / 100)^2))
}
nc <- nc_open(BR_PCO2)
plon <- ncvar_get(nc, "lon"); plat <- ncvar_get(nc, "lat")
pco2 <- br_get(nc, "pco2", "pco2", valid = c(50, 2000))   # uatm
nc_close(nc)
pco2_ann <- apply(pco2, c(1, 2), mean, na.rm = TRUE)
W_solu <- W_area * br_K0(apply(SSTC, c(1, 2), mean, na.rm = TRUE)) *
          br_to_ersst(pco2_ann, plon, plat)
# ⚠ ABSENCE ASSERTS. A cell with SST but no pCO2 leaves the SOLU average with no
# announcement -- the silent-omission shape of [[intersect_is_a_silent_default]].
# Counted and named, because "which cells did this weighting quietly not see" is
# part of what the weighting IS.
has_sst  <- is.finite(SSTC[, , 1])
drop_ssto <- has_sst & !(is.finite(W_solu) & W_solu > 0)
cat(sprintf("    regridded weight finite %.1f %%\n", 100 * mean(is.finite(W_solu))))
cat(sprintf("    ⚠ SOLU drops %d of %d SST-bearing cells (%.1f %%): NH %d, SH %d\n",
            sum(drop_ssto), sum(has_sst), 100 * sum(drop_ssto) / sum(has_sst),
            sum(drop_ssto[, elat >= 0]), sum(drop_ssto[, elat < 0])))
drop_flux <- has_sst & !(is.finite(W_flux) & W_flux > 0)
cat(sprintf("    ⚠ FLUX drops %d of %d SST-bearing cells (%.1f %%): NH %d, SH %d\n",
            sum(drop_flux), sum(has_sst), 100 * sum(drop_flux) / sum(has_sst),
            sum(drop_flux[, elat >= 0]), sum(drop_flux[, elat < 0])))

# ---- the three weightings --------------------------------------------
cat(sprintf("\n%s\nTHE WEIGHTINGS -- half-amplitude, K, and the peak month\n%s\n",
            strrep("=", 76), strrep("=", 76)))
WS <- list(AREA = W_area, FLUX = W_flux, SOLU = W_solu)
res <- list()
cat(sprintf("  %-6s %10s %10s %10s %10s\n", "weight", "NH amp", "NH peak", "SH amp", "SH peak"))
for (w in names(WS)) {
  a <- br_amp(WS[[w]], "NH"); b <- br_amp(WS[[w]], "SH")
  res[[w]] <- list(NH = a, SH = b)
  cat(sprintf("  %-6s %10.4f %10.2f %10.4f %10.2f\n",
              w, a$half_amp, a$peak_month, b$half_amp, b$peak_month))
}

# ---- [5] the month-varying sensitivity, as a FLAG not a result -------
cat(sprintf("\n%s\n[5] SENSITIVITY -- month-varying flux weight (the choice flagged in [3])\n%s\n",
            strrep("-", 76), strrep("-", 76)))
ct_m <- array(NA_real_, c(dim(ct_w), 12))
ctmo <- rep(1:12, length.out = dim(ocn)[3])
for (m in 1:12) ct_m[, , m] <- apply(abs(ocn[, , ctmo == m, drop = FALSE]), c(1, 2), mean, na.rm = TRUE)
for (hh in c("NH", "SH")) {
  sel <- if (hh == "NH") which(elat >= 0) else which(elat < 0)
  v <- vapply(1:12, function(m) {
    W <- W_area * br_to_ersst(ct_m[, , m], ctlon, ctlat)
    x <- SSTC[, sel, m]; w <- W[, sel]
    ok <- is.finite(x) & is.finite(w) & w > 0
    sum(x[ok] * w[ok]) / sum(w[ok])
  }, 0)
  h <- br_harm(v); res[[paste0("FLUXMO_", hh)]] <- h
  cat(sprintf("  %s month-varying: half-amp %.4f K (fixed-weight FLUX %.4f) -> %+.1f %%\n",
              hh, h$half_amp, res$FLUX[[hh]]$half_amp,
              100 * (h$half_amp / res$FLUX[[hh]]$half_amp - 1)))
}
cat("\n  ⛔ THIS IS NOT A BRACKET ENDPOINT AND IS DELIBERATELY EXCLUDED BELOW.\n")
cat("     Two reasons, either sufficient. (1) THE BOX MODEL CANNOT REPRESENT IT:\n")
cat("     the parameter multiplies ONE prescribed cycle on ONE box, so its honest\n")
cat("     analogue is sum_i wbar_i T'_i(t) with a FIXED wbar. A time-varying w_i(t)\n")
cat("     adds a rectification term the box has no way to carry, so this number\n")
cat("     answers a question the parameter does not ask. (2) THE WEIGHT COVARIES\n")
cat("     WITH WHAT IT WEIGHTS: |flux| carries dpCO2, and dpCO2's seasonality is\n")
cat("     itself partly driven by the SST cycle being measured. That is circular,\n")
cat("     and it is the likelier explanation of a -84 % collapse than any physics.\n")
cat("     ⇒ Reported because it is large and someone will otherwise compute it and\n")
cat("     believe it. NOT interpretable as either a bracket end or a clean\n")
cat("     rectification estimate without a k field.\n")

# ---- the bracket ------------------------------------------------------
cat(sprintf("\n%s\nTHE BRACKET -- LO/HI over the defensible weightings\n%s\n",
            strrep("=", 76), strrep("=", 76)))
cat("⛔ NOT a claim that any one weighting is correct. The amplitude factors are\n")
cat("   NOT observables; what is measured here is the SPREAD they span.\n\n")
brk <- list()
for (hh in c("NH", "SH")) {
  v <- vapply(names(WS), function(w) res[[w]][[hh]]$half_amp, 0)
  lo <- min(v); hi <- max(v)
  brk[[hh]] <- c(lo = lo, hi = hi)
  eff <- log(hi / lo) / 2      # the sd ccx_bracket_lnorm() implies
  cat(sprintf("  %s  LO %.5f  HI %.5f  centre(geo) %.5f  implied log-sd %.4f  (vs SST_SEAS_LOGSD %.2f)\n",
              hh, lo, hi, sqrt(lo * hi), eff, SST_SEAS_LOGSD))
}
# ---- WHAT THE MEASURED BRACKET WOULD DO TO THE SCREEN -----------------
# ⛔ A PROJECTION, NOT AN ADOPTION. Printed because the whole point of measuring
# the width was to find out whether -4.71 is real, and the answer is the
# opposite of the hoped-for one -- so it must not be left for someone to
# discover later.
# ⚠ TWO SEPARATE DECISIONS, AND ONLY THE FIRST WAS ASKED FOR: replacing the
# WIDTH, and moving the CENTER. The bracket's geometric center is NOT the
# incumbent anchor, and since the amplitude factors are not observables, moving
# the center asserts something new about where the parameter should sit. Both
# are shown; neither is taken.
MODE_FILE <- "calibration/output/multistart_20260901_enso25/start_000.rds"
if (file.exists(MODE_FILE)) {
  pm <- readRDS(MODE_FILE)$par_mode
  cat(sprintf("\n%s\nPROJECTED EFFECT ON THE SCREEN (25-par mode, cluster rep A)\n%s\n",
              strrep("=", 76), strrep("=", 76)))
  cat(sprintf("  %-6s %9s %11s %11s %11s\n", "hemi", "fitted",
              "z NOW", "z new WIDTH", "z new W+CENTRE"))
  for (hh in c("NH", "SH")) {
    x   <- pm[[paste0("sst_seas_amp_", hh)]]
    anc <- ccx_const(sprintf("SST_SEAS_AMP_%s_OBS", hh))
    lo  <- brk[[hh]][["lo"]]; hi <- brk[[hh]][["hi"]]
    sd_new <- log(hi / lo) / 2; ctr_new <- sqrt(lo * hi)
    cat(sprintf("  %-6s %9.4f %11.2f %11.2f %11.2f\n", hh, x,
                ccx_prior_z(paste0("sst_seas_amp_", hh), x),
                log(x / anc) / sd_new, log(x / ctr_new) / sd_new))
  }
  cat("\n  ⇒ THE MEASURED AMBIGUITY IS NARROWER THAN THE JUDGEMENT IT REPLACES, so\n")
  cat("    measuring the width makes the flag BIGGER, not smaller. The 0.25 was\n")
  cat("    GENEROUS to the fit, not harsh on it.\n")
}

saveRDS(list(res = res, bracket = brk, window = BR_WIN,
             built = Sys.time(), note = "ADOPTS NOTHING; R/constants.R unedited"),
        BR_OUT)
cat(sprintf("\n  written to %s\n⛔ R/constants.R IS NOT EDITED BY THIS FILE.\n%s\n",
            BR_OUT, strrep("=", 76)))
