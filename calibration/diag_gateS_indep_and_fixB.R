# =====================================================================
# diag_gateS_indep_and_fixB.R -- ONE PRODUCT, TWO OWED QUESTIONS
#
#   PART A  Is GATE S's target corroborated by an observation that never
#           passes through the model's own signature scalars?
#   PART B  The FIX B pre-test: is there a tropical outgassing reservoir
#           for ENSO to modulate, and can this model represent it?
#
# Pre-registered in notes/prereg_2026-09-04g_gateS_independent_and_fixB.md,
# written BEFORE this file existed. Handoff 2026-09-04 gate audit, sec.8 item 1.
#
# ⚠ pCO2 IS NOT FLUX. F = k * K0 * dpCO2, and neither the wind seasonality
# in k nor the temperature seasonality in K0 is in this product. Inherited
# verbatim from prereg 2026-08-27f; it still binds.
# ⚠ A CLIMATOLOGY HAS NO INTERANNUAL AXIS. It measures the RESERVOIR ENSO
# modulates; it cannot measure the modulation. Every ENSO number in PART B
# comes from GCB + Nino3.4, never from this file.
#
# THE ESTIMATOR IS THE ONE THIS REPO ALREADY USES: the magnitude of the MEAN
# harmonic vector, never the mean of per-month magnitudes ([[amp_definition_mismatch]]),
# and the band masks/fill-value handling are TAKEN FROM diag_so_pco2_phase.R
# rather than re-derived, so the two files cannot drift apart.
#
# Usage:  Rscript calibration/diag_gateS_indep_and_fixB.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- CONSTANTS AT THE TOP; EVERY LABEL BELOW DERIVES FROM THEM -------
GI_PCO2   <- "data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc"
GI_ERSST  <- "data-raw/downloads/ersst_v5_sst_mnmean.nc"
GI_WINDOW <- LIK_SEAS_WINDOW
# The gate's own target and CI, read from the SAME registry the gate reads.
# ⚠ These are the gate's target AS PRE-REGISTERED (09-04g): the inverted SPO
# ocean phase 8.52 [7.82, 9.20]. GATE S rebased the next day (09-04h) onto the
# [DG_S_LO, DG_S_HI] arc and lib_design_gates.R now carries the inversion only
# as DG_S_OBS_RETIRED, so the three old names no longer existed and this file
# could not run. Re-pointed 2026-09-12 to the SAME NUMBERS under their registry
# names; PART A corroborates the retired target, as pre-registered.
GI_S_OBS  <- DG_S_OBS_RETIRED
GI_S_LO   <- ccx_const("SPO_SEAS_OCEAN_PHASE_INV_LO")
GI_S_HI   <- ccx_const("SPO_SEAS_OCEAN_PHASE_INV_HI")
# The model's PRE-FIX SH ocean limb -- the defect gate S was created to catch.
# Two estimators, both carried so neither is silently preferred.
GI_PREFIX_LIMB <- 3.35    # lib_seas_limbs.R estimator, handoff 2026-09-03
GI_PREFIX_CHAN <- 4.16    # diag_seas_channel_decomp.R, "air-sea SH off"
# A first-order box lags its sinusoidal forcing by arctan(omega*tau), which is
# bounded above by a QUARTER CYCLE. This is the LAW the bracket rests on.
GI_LAG_MAX_MO  <- 3.0
# PART B masks. The equatorial-Pacific longitudes are a JUDGEMENT, declared in
# the prereg before the result; sec.B1b reports the sensitivity to widening it.
GI_TROPIC_LAT  <- c(-20, 20)
GI_EQP_LAT     <- c(-5, 5)
# ⚠ THIS GRID RUNS -180..180 AND THE MASK WRAPS THE DATE LINE. Written as
# 160E -> 80W it is `lon >= 160 OR lon <= -80`, NOT `160 <= lon <= 280`. The
# naive form silently selected 160-180E only -- 20 deg of WARM POOL, the LOWEST
# pCO2 part of the basin, at one SIXTH of the intended area -- and still printed
# a plausible-looking positive contrast. The mask is therefore given as
# (west edge, east edge) and resolved by `lon_mask()`, which gates its own span.
GI_EQP_LON     <- c(160, -80)          # 160E -> 80W, wrapping
GI_EQP_LON_W   <- c(140, -70)          # the widened control
# ⚠ A DECLARED NOMINAL, not a fitted or measured value: it enters only K0, which
# varies ~2 %/K, so a 2 K error moves the B3 swing ~4 % and cannot move a verdict
# that turns on a factor of several. Declared here rather than at its use.
GI_EQP_SST_C   <- 27.0
# Gate V's deficit, THROUGH GATE V'S OWN ESTIMATOR (dg_gateV_obs / dg_gateV), never a
# typed literal: the 0.911 / 0.698 that stood here were the 09-04 read and went stale
# when the gate moved to the residual dof (2026-09-12). Assigned after v_can exists.
GI_V_OBS_SD    <- NULL
GI_V_MOD_SD    <- NULL

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
harm <- function(x) {
  tt <- (seq_len(12) - 0.5) / 12
  c(a = 2 * mean(x * sin(2 * pi * tt)), b = 2 * mean(x * cos(2 * pi * tt)))
}
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[["a"]], v[["b"]]) / (2 * pi)) %% 1)
dmo    <- function(a, b) { d <- (a - b) %% 12; min(d, 12 - d) }
awt    <- function(lat, dlat) abs(sin((lat + dlat / 2) * pi / 180) -
                                  sin((lat - dlat / 2) * pi / 180))
# Is month `m` inside the CIRCULAR interval [lo, lo+w]? Months are an angle.
in_arc <- function(m, lo, w) ((m - lo) %% 12) <= w

# ---- pCO2 climatology, with the fill-value trap gated ----------------
# THE FILL VALUE IS NOT APPLIED BY ncdf4 AND LAND IS NOT NA: this file names
# the attribute `FillValue`, not the CF-standard `_FillValue`, and stores it as
# a CHARACTER STRING. Left unmasked, -999 dilutes every band MEAN -- which is
# exactly what PART B measures, so this gate matters more here than it did in
# diag_so_pco2_phase.R, where only amplitudes were hit. [[fillvalue_not_applied]]
nc <- nc_open(GI_PCO2)
plat <- ncvar_get(nc, "lat"); plon <- ncvar_get(nc, "lon")
pco2 <- ncvar_get(nc, "pco2")
patt <- ncatt_get(nc, "pco2")
nc_close(nc)
pdlat <- abs(diff(plat)[1])
stopifnot(!is.null(patt$FillValue) || !is.null(patt[["_FillValue"]]))
fv <- as.numeric(if (!is.null(patt[["_FillValue"]])) patt[["_FillValue"]] else patt$FillValue)
stopifnot(is.finite(fv), fv < 0)
pco2[pco2 <= fv + 1] <- NA_real_
fin <- mean(is.finite(pco2[, , 1]))
cat(sprintf("pCO2  %s: %d lon x %d lat x %d mo | FillValue %g masked -> %.1f%% ocean\n",
            basename(GI_PCO2), length(plon), length(plat), dim(pco2)[3], fv, 100 * fin))
if (fin < 0.55 || fin > 0.78)
  stop(sprintf("pCO2 land mask implausible: %.3f of cells finite", fin))
cat(sprintf("lon runs %.2f to %.2f (a %s grid)\n", min(plon), max(plon),
            if (min(plon) < 0) "-180..180" else "0..360"))

# Area-weighted monthly mean over a lat band, optionally a lon window too.
# WRAP-AWARE longitude selector, with its own span gate. `w` is (west, east) in
# degrees east on a -180..180 grid; the mask wraps when west > east.
lon_mask <- function(lon, w) {
  i <- if (w[1] <= w[2]) which(lon >= w[1] & lon <= w[2])
       else which(lon >= w[1] | lon <= w[2])
  span_deg <- ((w[2] - w[1]) %% 360)
  got_deg  <- length(i) * abs(diff(lon)[1])
  if (abs(got_deg - span_deg) > 2 * abs(diff(lon)[1]))
    stop(sprintf("lon_mask(): asked for %.1f deg, selected %.1f -- the wrap is wrong",
                 span_deg, got_deg))
  i
}
band_clim <- function(fld, lat, dlat, lo, hi, lon = NULL, lonw = NULL) {
  j <- which(lat > lo & lat <= hi)
  i <- if (is.null(lonw)) seq_along(lon) else lon_mask(lon, lonw)
  if (!length(j) || !length(i)) return(rep(NA_real_, 12))
  w <- awt(lat[j], dlat)
  vapply(1:12, function(m) {
    s <- fld[i, j, m, drop = FALSE][, , 1, drop = TRUE]
    if (is.null(dim(s))) s <- matrix(s, nrow = length(i))
    ok <- is.finite(s)
    W  <- matrix(rep(w, each = length(i)), nrow = length(i))
    sum(s[ok] * W[ok]) / sum(W[ok])
  }, 0)
}
# OCEAN area of a mask, in m2 -- the area of the cells this product REPORTS.
EARTH_R <- 6.371e6
ocean_area_m2 <- function(lo, hi, lonw = NULL) {
  j <- which(plat > lo & plat <= hi)
  i <- if (is.null(lonw)) seq_along(plon) else lon_mask(plon, lonw)
  dlon <- abs(diff(plon)[1])
  w <- awt(plat[j], pdlat) * (dlon / 360) * 2 * pi * EARTH_R^2
  ok <- is.finite(pco2[i, j, 1, drop = FALSE][, , 1, drop = TRUE])
  if (is.null(dim(ok))) ok <- matrix(ok, nrow = length(i))
  sum(matrix(rep(w, each = length(i)), nrow = length(i))[ok])
}

# =====================================================================
sep("PART A -- GATE S's TARGET AGAINST AN OBSERVATION THAT AVOIDS THE MODEL")
cat("  Gate S's target is the observed SPO CO2 + d13C harmonics INVERTED through\n")
cat("  two scalars the MODEL supplies. This section rebuilds an interval for the\n")
cat("  same quantity from surface-ocean pCO2 alone, converting with a LAW and not\n")
cat("  a number: a first-order box lags its sinusoidal forcing by arctan(w*tau),\n")
cat(sprintf("  which is bounded above by a quarter cycle = %.1f months.\n", GI_LAG_MAX_MO))

obs <- ccx_prepare_obs()
oa  <- obs$co2_seas$SPO
atm <- c(a = mean(oa$a), b = mean(oa$b))
cat(sprintf("\n  atmospheric SPO harmonic (the dpCO2 subtrahend): amp %.3f ppm, peak mo %.2f, %d yr\n",
            amp(atm), ang_mo(atm), length(oa$year)))

GI_BANDS <- list(
  `SO 40-90S`        = c(-90, -40),
  `SO 60-90S`        = c(-90, -60),
  `SO 40-60S`        = c(-60, -40),
  `SH all (0-90S)`   = c(-90,   0),
  `SH subtrop 0-30S` = c(-30,   0),
  `NH all (0-90N)`   = c(  0,  90))

cat(sprintf("\n  %-18s %9s %9s | %-14s | %8s | %8s\n", "band",
            "dpCO2 amp", "peak mo", "bracket (mo)", "8.52 in?", "4.16 in?"))
A <- list()
for (nm in names(GI_BANDS)) {
  b  <- GI_BANDS[[nm]]
  hp <- harm(band_clim(pco2, plat, pdlat, b[1], b[2], lon = plon))
  d  <- hp - atm[c("a", "b")]; names(d) <- c("a", "b")
  m0 <- ang_mo(d)
  A[[nm]] <- list(d = d, m0 = m0,
                  in_target  = in_arc(GI_S_OBS,        m0, GI_LAG_MAX_MO),
                  in_prefixc = in_arc(GI_PREFIX_CHAN,  m0, GI_LAG_MAX_MO),
                  in_prefixl = in_arc(GI_PREFIX_LIMB,  m0, GI_LAG_MAX_MO))
  cat(sprintf("  %-18s %9.2f %9.2f | [%5.2f, %5.2f] | %8s | %8s\n", nm,
              amp(d), m0, m0, (m0 + GI_LAG_MAX_MO) %% 12,
              ifelse(A[[nm]]$in_target, "YES", "no"),
              ifelse(A[[nm]]$in_prefixc, "YES", "no")))
}

sep("A -- THE SCORED PREDICTIONS")
so <- A[["SO 40-90S"]]; sh <- A[["SH all (0-90S)"]]
cat(sprintf("  A1  8.52 inside the SOUTHERN OCEAN bracket [%.2f, %.2f]: %s -> %s\n",
            so$m0, (so$m0 + GI_LAG_MAX_MO) %% 12, ifelse(so$in_target, "YES", "NO"),
            ifelse(so$in_target, "CORROBORATED", "FALSIFIED -- gate S's target is not independent")))
cat(sprintf("  A2  POWER: that bracket is %.0f%% of the circle (random pass p = %.2f).\n",
            100 * GI_LAG_MAX_MO / 12, GI_LAG_MAX_MO / 12))
cat(sprintf("      It EXCLUDES the pre-fix limb?  channel %.2f: %s | limb %.2f: %s  -> %s\n",
            GI_PREFIX_CHAN, ifelse(so$in_prefixc, "inside", "EXCLUDED"),
            GI_PREFIX_LIMB, ifelse(so$in_prefixl, "inside", "EXCLUDED"),
            ifelse(!so$in_prefixc && !so$in_prefixl, "HAS POWER",
                   "NO POWER -- may not be used to upgrade any constant")))
cat(sprintf("  A3  the SH-MEAN bracket [%.2f, %.2f] excludes 8.52? %s -> %s\n",
            sh$m0, (sh$m0 + GI_LAG_MAX_MO) %% 12, ifelse(!sh$in_target, "YES", "NO"),
            ifelse(!sh$in_target, "DISCRIMINATES: the limb is Southern-Ocean, not SH-mean",
                   "CANNOT DISCRIMINATE between the two regimes")))
cat(sprintf("      and that SH-mean bracket CONTAINS the pre-fix channel %.2f: %s -- the model\n",
            GI_PREFIX_CHAN, ifelse(sh$in_prefixc, "YES", "no")))
cat("      was matching the SH AREA-MEAN regime, which is the 76 % cancellation of\n")
cat("      two antiphase limbs that 2026-08-27f measured. Same reading, independent route.\n")

sep("A4 -- THE NARROWED BRACKET (WEAKER BY CONSTRUCTION; NEVER FAILS THE GATE)")
v_can <- dg_vector(CCX_MODE_CANONICAL)
GI_V_OBS_SD <- dg_gateV_obs()$sd; GI_V_MOD_SD <- dg_gateV(dg_run(v_can))$sd_model
GI_ARM_LABEL <- sprintf("model, %s", CCX_MODE_CANONICAL)   # the arm v_can resolves; never a literal
tau_ex <- v_can$p$tau_ex
w_ang  <- 2 * pi / 12                            # per month
lag_tau <- atan(w_ang * tau_ex * 12) / (2 * pi) * 12
cat(sprintf("  tau_ex at %s = %.3f yr = %.1f mo  ->  arctan(w*tau) = %.2f mo\n",
            CCX_MODE_CANONICAL, tau_ex, tau_ex * 12, lag_tau))
m_tau <- (so$m0 + lag_tau) %% 12
cat(sprintf("  implied atmospheric phase %.2f mo, i.e. %+.2f mo from the gate's %.2f\n",
            m_tau, ((m_tau - GI_S_OBS + 6) %% 12) - 6, GI_S_OBS))
cat("  ⚠ tau_ex alone is an UPPER BOUND on the box's loss time (sinks also drain it),\n")
cat("  so this lag is biased LATE; and it carries none of the k / K0 seasonality.\n")
cat("  REPORTED ONLY. A1 is the scored row.\n")

# =====================================================================
sep("PART B -- THE FIX B PRE-TEST")
cat("  B0  The observable is a CONTRAST INTERNAL TO THE FIELD -- a band's annual\n")
cat("  area-weighted mean pCO2 minus the GLOBAL ocean mean -- so it needs neither\n")
cat("  an atmospheric field (this product has none) nor a reference year (this\n")
cat("  product states none). Absolute disequilibrium appears only in sec.B1c.\n\n")

ann <- function(lo, hi, lonw = NULL) mean(band_clim(pco2, plat, pdlat, lo, hi,
                                                    lon = plon, lonw = lonw))
glob <- ann(-90, 90)
trop <- ann(GI_TROPIC_LAT[1], GI_TROPIC_LAT[2])
eqp  <- ann(GI_EQP_LAT[1], GI_EQP_LAT[2], GI_EQP_LON)
eqpw <- ann(GI_EQP_LAT[1], GI_EQP_LAT[2], GI_EQP_LON_W)
so_a <- ann(-90, -40)
cat(sprintf("  %-34s %10s %12s\n", "mask", "pCO2 uatm", "minus global"))
cat(sprintf("  %-34s %10.2f %12s\n", "GLOBAL ocean", glob, "--"))
cat(sprintf("  %-34s %10.2f %+12.2f\n",
            sprintf("tropics %g-%g", GI_TROPIC_LAT[1], GI_TROPIC_LAT[2]), trop, trop - glob))
cat(sprintf("  %-34s %10.2f %+12.2f\n",
            sprintf("eq. Pacific %gE-%gE (wraps)", GI_EQP_LON[1], GI_EQP_LON[2]),
            eqp, eqp - glob))
cat(sprintf("  %-34s %10.2f %+12.2f\n", "Southern Ocean 40-90S", so_a, so_a - glob))

sep("B1 -- THE ORDERING (the scored row; magnitudes are reported, not gated)")
ok1 <- eqp > trop; ok2 <- trop > glob
cat(sprintf("  eq.Pacific (%.2f) > tropics (%.2f)?  %s\n", eqp, trop, ifelse(ok1, "YES", "NO")))
cat(sprintf("  tropics    (%.2f) > global  (%.2f)?  %s\n", trop, glob, ifelse(ok2, "YES", "NO")))
cat(sprintf("  B1 -> %s\n", ifelse(ok1 && ok2, "CONFIRMED -- the reservoir is there and it is equatorial",
                                   "FAILED -- read both halves above")))
cat(sprintf("\n  B1b widened mask %g-%gE: %.2f uatm (%+.2f vs global), a %+.1f%% change\n",
            GI_EQP_LON_W[1], GI_EQP_LON_W[2], eqpw, eqpw - glob,
            100 * ((eqpw - glob) / (eqp - glob) - 1)))

cat("\n  B1c ABSOLUTE disequilibrium, swept over the reference year (NOT gated).\n")
cat("  This product states no normalisation year, so the row is a SENSITIVITY:\n")
cat("  the equatorial contrast above is invariant to every line of it.\n")
co2 <- obs$co2_ann$MLO      # MLO annual level; a REFERENCE, not a global mean
for (y in c(2000, 2005, 2010, 2015)) {
  ch <- co2$level[which.min(abs(co2$year - y))]
  cat(sprintf("    ref %d (atm %.1f ppm): global %+7.2f | tropics %+7.2f | eq.Pac %+7.2f uatm\n",
              y, ch, glob - ch, trop - ch, eqp - ch))
}

sep("B2 -- WHAT THE MODEL CAN REPRESENT (a SOURCE reading, not a run)")
n_ml <- length(grep("^ml_C_", names(dg_run(v_can)$out)))
cat(sprintf("  mixed-layer carbon columns in the model's output: %d (%s)\n", n_ml,
            paste(grep("^ml_C_", names(dg_run(v_can)$out), value = TRUE), collapse = ", ")))
cat("  R/model.R computes ONE pco2_ml per hemisphere from ONE dic_ml; there is no\n")
cat("  zonal or equatorial box, so the model's representable tropical-minus-global\n")
cat("  pCO2 contrast is EXACTLY ZERO. Its ENSO ocean term is consequently an\n")
cat("  ADDITIVE FLUX with a free coefficient (src/ccx_core.cpp:528), not an\n")
cat("  upwelling response -- which is what its own comment says.\n")
cat(sprintf("  gamma_enso_ocn at %s: NH %+.4f  SH %+.4f  (GtC/yr per index unit)\n",
            CCX_MODE_CANONICAL, v_can$p$gamma_enso_ocn_NH, v_can$p$gamma_enso_ocn_SH))
cat(sprintf("  B2 -> %s\n", ifelse(n_ml == 2, "CONFIRMED as stated: two boxes, no tropical one",
                                   "FALSIFIED -- the premise is wrong")))

sep("B3 -- PRICING, WITH AN OBSERVATION ON EACH SIDE")
g <- obs$gcb
# ⚠ `forcing_enso.rds` IS MONTHLY (948 rows) AND GCB IS ANNUAL. Merging the two
# on `year` alone silently replicates each GCB row twelve times: n goes 66 -> 792,
# every residual is counted a dozen times and the slope's t-statistic inflates by
# ~sqrt(12). Annualise FIRST, and gate n against the year count.
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year")
mg <- mg[stats::complete.cases(mg), ]
stopifnot(nrow(mg) == length(unique(mg$year)))   # one row per year, or the merge fanned out
# DETREND both: the ocean sink's trend is the anthropogenic uptake, which has
# nothing to do with ENSO, and regressing on a trending predictor would price it.
fit <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg)
beta <- unname(coef(fit)["nino34_anom"]); se <- summary(fit)$coefficients["nino34_anom", 2]
cat(sprintf("  GCB ocean sink on Nino3.4 (with a linear year term), %d-%d, n=%d:\n",
            min(mg$year), max(mg$year), nrow(mg)))
cat(sprintf("    slope %+.4f +/- %.4f GtC/yr per index unit  (t = %+.2f)\n", beta, se, beta / se))
cat(sprintf("    r(sink residual, nino34) = %+.3f\n",
            stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom)))
# Convert with the MODEL's OWN air-sea prefactor: gx = A*rho/1e6/M * k_w * K0.
A_eqp <- ocean_area_m2(GI_EQP_LAT[1], GI_EQP_LAT[2], GI_EQP_LON)
K0_eqp <- carb_constants(GI_EQP_SST_C)$K0   # carb_constants takes degC, not K
gx_eqp <- A_eqp * ccx_const("RHO_SEAWATER") / 1e6 / ccx_const("MOL_C_PER_GtC") *
          v_can$p$k_w * K0_eqp
cat(sprintf("\n  eq.Pacific area %.3e m2 (%.1f%% of global ocean); at SST %.1f C the MODEL's own\n",
            A_eqp, 100 * A_eqp / ocean_area_m2(-90, 90), GI_EQP_SST_C))
cat(sprintf("  prefactor gives dF/d(dpCO2) = %.5f GtC/(yr uatm) with k_w = %.0f.\n",
            gx_eqp, v_can$p$k_w))
swing <- abs(beta) / gx_eqp
cat(sprintf("  => the observed ENSO ocean sensitivity needs a dpCO2 swing of %.2f uatm\n", swing))
cat(sprintf("     per index unit over that mask.\n"))
frac <- swing / (eqp - glob)
cat(sprintf("  B3 that is %.2f x the measured equatorial reservoir (%+.2f uatm) -> %s\n",
            frac, eqp - glob,
            ifelse(frac < 1, "CONFIRMED: a MODULATION of the reservoir, not larger than it",
                   "FALSIFIED: larger than the reservoir; Fix B is mis-specified as stated")))
cat("  ⚠ SST 27 C is a DECLARED NOMINAL for the equatorial Pacific, not a fitted or\n")
cat("  measured value; K0 varies ~2 %/K, so a 2 K error moves the swing ~4 %. It\n")
cat("  cannot move the verdict, which turns on a factor of several.\n")

cat("\n  REPORTED, NOT GATED -- what the observed sensitivity supplies to gate V:\n")
sd_supplied <- abs(beta) * stats::sd(mg$nino34_anom)
cat(sprintf("    sd(beta * nino34) = %.3f GtC/yr against gate V's deficit %.3f (%.0f%%)\n",
            sd_supplied, GI_V_OBS_SD - GI_V_MOD_SD, 100 * sd_supplied / (GI_V_OBS_SD - GI_V_MOD_SD)))
cat(sprintf("    the model's PATCH COEFFICIENT is |gamma_ocn_NH|+|gamma_ocn_SH| = %.3f GtC/yr\n",
            abs(v_can$p$gamma_enso_ocn_NH) + abs(v_can$p$gamma_enso_ocn_SH)))
cat("    per index unit -- which is NOT comparable to the GCB slope above, because\n")
cat("    the model's NET response is the patch minus a wrong-sign solubility path.\n")
cat("    The like-for-like number is in sec.B4; read that one, not a ratio of these.\n")
cat("  ⚠ Gate V's own record says a FAIL there IS NOT A BLOCKER (Marcus 2026-09-04f).\n")
cat("  No number in B3 may be read as a requirement.\n")

sep("B4 -- THE MODEL'S **NET** ENSO OCEAN SENSITIVITY, BY THE SAME REGRESSION")
cat("  The patch coefficient is NOT comparable to a GCB slope on its own: the\n")
cat("  model's net ocean response is the patch PLUS the SST-solubility path, which\n")
cat("  the code comment says carries the WRONG SIGN. Quoting gamma alone against a\n")
cat("  NET observed sink is not like-for-like ([[like_for_like_forcing]]), so the\n")
cat("  model side is measured the way the observation was: regress the model's own\n")
cat("  annual ocean uptake on the SAME index with the SAME year term.\n\n")
# Model ocean uptake, sign +ve = uptake, to match GCB ocean_sink -- THE
# SCORECARD'S ESTIMATOR, dg_annual_sinks(): the ocean stock differenced Jan 1 ->
# Jan 1, i.e. the CALENDAR-YEAR sink GCB reports. ⛔ Until 2026-09-12 (review
# A9) this differenced ANNUAL-MEAN stocks -- an increment centred at y - 0.5 and
# labelled y, half a year early against the index -- and read the solubility-
# only r at ent26 as -0.432 where the calendar-year estimator reads -0.52. The
# two ENSO estimators differed in NOTHING else (assessment option N, resolved).
mod_sink <- function(v) {
  a <- dg_annual_sinks(dg_run(v))
  data.frame(year = a$year, ocean_sink = a$ocean)
}
slope_on_enso <- function(df) {
  m <- merge(df, en_ann, by = "year")
  m <- m[m$year >= min(mg$year) & m$year <= max(mg$year), ]
  m <- m[stats::complete.cases(m), ]
  stopifnot(nrow(m) == length(unique(m$year)))
  f <- stats::lm(ocean_sink ~ year + nino34_anom, data = m)
  c(beta = unname(coef(f)["nino34_anom"]),
    se   = summary(f)$coefficients["nino34_anom", 2],
    r    = stats::cor(residuals(stats::lm(ocean_sink ~ year, m)), m$nino34_anom),
    n    = nrow(m))
}
v_off <- v_can
v_off$p$gamma_enso_ocn_NH <- 0; v_off$p$gamma_enso_ocn_SH <- 0
arms <- list(`GCB (observed)` = c(beta = beta, se = se,
                                  r = stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)),
                                                 mg$nino34_anom), n = nrow(mg)))
arms[[GI_ARM_LABEL]]       <- slope_on_enso(mod_sink(v_can))   # was the literal `model, ent26` (09-12)
arms[["model, patch OFF"]] <- slope_on_enso(mod_sink(v_off))
cat(sprintf("  %-20s %12s %10s %8s %5s\n", "arm", "slope", "se", "r", "n"))
for (nm in names(arms)) {
  a <- arms[[nm]]
  cat(sprintf("  %-20s %+12.4f %10.4f %+8.3f %5.0f\n", nm, a[["beta"]], a[["se"]],
              a[["r"]], a[["n"]]))
}
b_on <- arms[[GI_ARM_LABEL]][["beta"]]; b_off <- arms[["model, patch OFF"]][["beta"]]
cat(sprintf("\n  the SOLUBILITY-ONLY path (patch off): r %+.3f -- the code comment's\n",
            arms[["model, patch OFF"]][["r"]]))
cat("  WRONG-SIGN claim, re-measured at the CURRENT mode rather than recalled.\n")
cat(sprintf("  the patch moves the net slope %+.4f -> %+.4f against an observed %+.4f,\n",
            b_off, b_on, beta))
cat(sprintf("  i.e. the NET model sensitivity is %.2f x the observed one.\n", b_on / beta))

sep("DONE")
