# =====================================================================
# build_bomb_c14_source.R -- derive the bomb 14C input function to the
# TROPOSPHERE from Tans (1981) SCOPE 16 Tables 1 and 2, with sub-annual
# structure supplied by the observed Delta14C record where -- and only where --
# the inventory data are not themselves sub-annual.
#
# Run from repo root:  Rscript data-raw/build_bomb_c14_source.R
#
# WHY THIS EXISTS
# ---------------
# R/model.R gives each hemisphere one well-mixed troposphere and NO
# stratospheric box, so forc$c14_bomb is a DELIVERY rate to the troposphere,
# not a production rate. The superseded placeholder was shaped like production
# -- 54.0 % of all bomb 14C in 1961-62, 2.2 % in 1963 -- which delivers the big
# test series with no stratospheric residence at all. Telegadas' measurements
# say 56-60 % of the Naegler & Levin total was still IN THE STRATOSPHERE in
# Dec 62 - Feb 63, and that 1963 was the largest delivery year.
#
# THE GOVERNING PRINCIPLE (Marcus 2026-08-10)
# -------------------------------------------
# Inventory data set the TOTALS. Observed concentration supplies the SUB-ANNUAL
# PATTERN only where no sub-annual inventory exists. This confines any
# circularity with the likelihood to within-interval timescales; every
# interval total comes from Tans' independent compilation.
#
# Interval totals, in order of preference:
#   1963.04-1966.54  Table 2 QUARTERLY stratospheric decrease. Genuinely
#                    sub-annual inventory data -- used directly, no
#                    concentration input needed at this timescale. These
#                    quarters carry the spring stratosphere-troposphere
#                    intrusion (7 / 48 / 29 units released in the first three
#                    quarters of 1963), which an earlier smooth two-exponential
#                    fit destroyed by forcing the flux to peak at Dec-62.
#   1966.54-1969.54  one Table 2 interval (128 -> 86).
#   pre-1963.04      budget closure (below) sets the BLOCK total; the split
#                    between years comes from the observed concentration record,
#                    NOT from Table 1, which this script never reads.
#   post-1969.54     exponential tail. Its TOTAL is measured -- it is the last
#                    reported stratospheric burden, independent of
#                    BOMB_TOTAL_REF_KMOL -- and only its distribution in time
#                    comes from the fit to the late Table 2 points. (No value
#                    typed here: BOMB_T2_HIGH_BIAS scales it. The script prints
#                    it, and diag_bomb_delivery_tail.R recomputes it.)
#   NOTE            Table 2 is divided by BOMB_T2_HIGH_BIAS before any of this.
#
# Budget closure for the pre-1963 total: the Table 2 series says how much was
# still aloft at 1963.04; the rest of the Naegler & Levin total must already
# have reached the troposphere. No test-yield inventory is needed, so UNSCEAR
# 2000 Annex C is NOT required by this construction.
#
# Within pre-1963 years, and within each Table 2 interval, the shape comes from
# g(t) = dN14/dt + lambda*N14 evaluated on the OBSERVED monthly Delta14C
# (Hua et al. 2022, area-weighted to hemispheres) -- the tropospheric 14C
# inventory plus its removal, i.e. the delivery implied by the concentration
# record. Only its SHAPE is used; each interval is rescaled to the inventory
# total.
#
# Output: data/forcing_bomb_c14.rds -- monthly, unit-integral shape.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

MANUAL <- "data-raw/manual"
OUT    <- "data"

# ---- named constants: every choice in the derivation is declared here ----
BOMB_T1_FILE        <- file.path(MANUAL, "tans1981_scope16_table1_tropospheric_d14c.csv")
BOMB_T2_FILE        <- file.path(MANUAL, "tans1981_scope16_table2_stratospheric_inventory.csv")
BOMB_OUT_FILE       <- file.path(OUT, "forcing_bomb_c14.rds")

BOMB_TOTAL_REF_KMOL <- 102      # Naegler & Levin (2006) central, 1945-1980.
                                # Only sets the pre/post-1963 SPLIT; the model
                                # rescales the unit-integral shape by the
                                # calibrated bomb_total.
# The judgment calls are environment-overridable so they can be measured:
#   CCX_BOMB_DROP_FIRST=0 CCX_BOMB_PREBOMB=-25 Rscript data-raw/build_bomb_c14_source.R
BOMB_T2_DROP_FIRST  <- as.logical(as.integer(Sys.getenv("CCX_BOMB_DROP_FIRST", "1")))
                                # Tans p.133 calls the 12/62-2/63 inventory
                                # "much too low" (early flights missed
                                # high-latitude 14C), so 356 is a FLOOR on the
                                # peak burden. When TRUE its value is replaced by
                                # kmol[2] + (kmol[2] - kmol[3]) -- i.e. the
                                # quarter before t0 is assumed to have released
                                # about as much as the quarter after it --
                                # raising the t0 burden to 397 units (+11.5 %).
                                # ⚠ NOT a back-extrapolation of the tail fit:
                                # that gives 36.2 kmol, 39 % BELOW the floor,
                                # because it decays a 1965-69 slope back through
                                # the peak. Checked 2026-09-08,
                                # calibration/diag_bomb_delivery_tail.R.
BOMB_T2_HIGH_BIAS   <- as.numeric(Sys.getenv("CCX_BOMB_T2_BIAS", "1.0"))
                                # Tans p.133, his SECOND caveat on this table:
                                # "Telegadas' aircraft data appear on average
                                # ~20 % too high" against ground-based CO2
                                # collections and against Ergin et al. (1970).
                                # Table 2 is DIVIDED by this.
                                # ⛔⛔ RULED APPLIED (1.20) by Marcus 2026-09-09,
                                # then REVERTED TO 1.0 by Marcus 2026-09-09f on
                                # the evidence the application itself produced.
                                # The mechanism is KEPT and is one env var away
                                # (CCX_BOMB_T2_BIAS=1.20); only the DEFAULT moved.
                                # WHY IT WAS REVERTED -- four measurements, of
                                # which the third is the one that decided it:
                                #  1. -92.74 loglik at hilda31 (fixed vector).
                                #  2. gate 5's newly-ruled TROUGH flips PASS ->
                                #     FAIL (z -1.80 -> -2.55); a SOFT flip.
                                #  3. ⭐ THE COST IS NOT WHERE THE FORCING MOVED.
                                #     Localized per year, 54 % of it (-49.9, of
                                #     which the SH is -45.4) falls AFTER 1970 --
                                #     OUTSIDE the bomb window, at sigma ~7 permil
                                #     not 25, in the years Graven and Hua AGREE
                                #     to 2-3 permil. The de-biasing degrades the
                                #     fit in the BEST-observed part of the record,
                                #     and deepens an SH deficit already at
                                #     z +4.31 in 1971 BEFORE it was applied.
                                #     calibration/diag_debias_penalty_by_year.R
                                #  4. Budget-closing lambda 0.1996 -> 0.3490 /yr,
                                #     so gross air-sea exchange at Tans' own
                                #     Broecker flux covers 75 % -> 43 % of it --
                                #     DATA.md sec.9 names that agreement as the
                                #     main evidence the closure step is sound.
                                # ⚠ WHAT DID *NOT* DECIDE IT: the -92.7 is NOT
                                # an artifact of an over-tight target. The bomb
                                # window is scored at sigma_eff 25.7 permil
                                # (LIK_D14C_REP_BOMB 25 + fitted sigma_d14c),
                                # ~7x Hua's own sd, and widening it to the full
                                # Graven-Hua spread removes only 21-25 % of the
                                # cost. calibration/diag_bomb_rep_sensitivity.R
                                # ⚠ AND THE CAVEAT REMAINS TANS' OWN. Reverting
                                # does not dispute that Telegadas may run ~20 %
                                # high; it declines to route that disagreement
                                # into the pre-1963 troposphere, which is the
                                # only channel available and is unobserved.
                                # Table 1 is NOT scaled: it is ground-based, and
                                # this script never reads it anyway.
                                # It does NOT change the 102 kmol total (Naegler
                                # & Levin's, absorbed by the fitted bomb_total)
                                # -- it changes the pre/post-1963 SPLIT, i.e.
                                # the delivery SHAPE.
BOMB_PREBOMB_D14C   <- as.numeric(Sys.getenv("CCX_BOMB_PREBOMB", "-30"))
                                # permil. Suess-depleted pre-bomb level, taken
                                # as the Dec-1954 SH value of Tans Table 1 (the
                                # SH had no detectable bomb signal then).
BOMB_EXCESS_ZERO_YR <- 1952.0   # bomb excess anchored to zero here: pre-1952
                                # atmospheric tests were small fission devices
                                # with negligible 14C yield next to the 1952
                                # (Ivy Mike) and later thermonuclear tests.
BOMB_SERIES_END_YR  <- 1980     # matches the range the forcing builder and
                                # tests/testthat/test-forcing.R assume.
BOMB_TAIL_FIT_FROM  <- 1965.0   # late Table 2 points used for the post-1969
                                # exponential tail
BOMB_STRAT_AIR_KG   <- 1.02e18  # Telegadas' stratosphere, quoted by Tans p.133
BOMB_TOTAL_AIR_KG   <- 5.20e18  # ... out of this total atmospheric mass
BOMB_M_AIR_KG_MOL   <- 28.96e-3 # mean molar mass of dry air
BOMB_GROSS_AS_FLUX  <- 19       # mol CO2 /m2/yr, Broecker et al. (1978), the
                                # value Tans himself used (p.134)
BOMB_SHAPE_FLOOR    <- 1e-6     # relative floor so a rescaled interval whose
                                # concentration-implied shape is entirely
                                # non-positive still receives its total
BOMB_SHAPE_SMOOTH_M <- as.integer(Sys.getenv("CCX_BOMB_SMOOTH", "5"))
                                # centered moving average, months, applied to the
                                # concentration-implied shape BEFORE the interval
                                # rescale (which still enforces exact totals).
                                # Observed atmospheric D14C carries a seasonal
                                # cycle from BOTH the spring stratospheric
                                # intrusion -- a real feature of the source, to
                                # be kept -- and seasonal biosphere/ocean
                                # exchange, which R/model.R already simulates and
                                # which would be DOUBLE-COUNTED if it entered the
                                # source. Unsmoothed, g swung 23.8 -> 39.2 -> 12.8
                                # kmol/yr in successive months of 1963. A 5-month
                                # average retains ~75 % of a 12-month cycle
                                # (sin(5*pi/12)/(5*sin(pi/12))) so the spring
                                # maximum survives, while damping the higher
                                # frequencies that differentiation amplifies.
NA_AVOGADRO         <- 6.02214076e23

cat("\n=== build_bomb_c14_source.R ===\n")
cat("Totals from Tans (1981) SCOPE 16 Tables 1-2; sub-annual shape from observed D14C\n")
cat(sprintf("Reference total: %.0f kmol (Naegler & Levin 2006)\n\n", BOMB_TOTAL_REF_KMOL))

MONTH_DT <- 1 / 12
mt <- seq(BOMB_EXCESS_ZERO_YR + MONTH_DT / 2, BOMB_SERIES_END_YR + 11.5 / 12, by = MONTH_DT)

# =====================================================================
# 1. Observed monthly Delta14C -> the concentration-implied delivery shape
# =====================================================================
d14 <- as.data.frame(readRDS(file.path(OUT, "obs_d14c_zonal.rds")))
zw  <- ccx_zone_weights()
agg_hemi <- function(wts) {
  s <- d14[d14$zone %in% names(wts), c("decimal_date", "zone", "d14c")]
  wide <- reshape(s, idvar = "decimal_date", timevar = "zone", direction = "wide")
  zn <- sub("d14c\\.", "", names(wide)[-1])
  M <- as.matrix(wide[, -1, drop = FALSE]); ww <- wts[zn] / sum(wts[zn])
  ok <- complete.cases(M)
  data.frame(t = wide$decimal_date[ok], x = as.numeric(M[ok, , drop = FALSE] %*% ww))
}
NHo <- agg_hemi(zw$NH); SHo <- agg_hemi(zw$SH)
tt  <- sort(intersect(NHo$t, SHo$t))
glob_obs <- 0.5 * (NHo$x[match(tt, NHo$t)] + SHo$x[match(tt, SHo$t)])   # equal-area hemispheres
d14c_ex <- stats::approx(tt, glob_obs, xout = mt, rule = 2)$y - BOMB_PREBOMB_D14C
d14c_ex[d14c_ex < 0] <- 0
d14c_ex[mt < BOMB_EXCESS_ZERO_YR] <- 0

# tropospheric 14C inventory on Telegadas' troposphere, ice-core CO2 spline
co2s <- as.data.frame(readRDS(file.path(OUT, "obs_icecore.rds"))$co2_spline)
chi  <- stats::approx(co2s$year, co2s$co2_ppm, xout = mt, rule = 2)$y
mol_air_trop <- (BOMB_TOTAL_AIR_KG - BOMB_STRAT_AIR_KG) / BOMB_M_AIR_KG_MOL
N14 <- (d14c_ex / 1000) * (mol_air_trop * chi * 1e-6) * ccx_const("R14_STD") / 1000  # kmol

# =====================================================================
# 2. Table 2 -> released-to-date, and the interval totals
# =====================================================================
t2 <- read.csv(BOMB_T2_FILE, comment.char = "#")
t2$kmol <- t2$inventory_1e26_atoms * 1e26 / NA_AVOGADRO / 1000
# Tans' ~20 % high bias, applied uniformly so that the burden, the
# quarter-on-quarter releases and the residual tail mass scale together and the
# budget still closes on BOMB_TOTAL_REF_KMOL.
t2$kmol <- t2$kmol / BOMB_T2_HIGH_BIAS
if (BOMB_T2_HIGH_BIAS != 1)
  cat(sprintf("Table 2 de-biased by /%.2f (Tans p.133, on average ~20 %% too high)\n",
              BOMB_T2_HIGH_BIAS))
t0 <- t2$t_mid[1]

# Exponential fit to the LATE points, used for the post-1969 tail's SHAPE only.
# (Its mass is not fitted: see the interval-totals block below -- what the Table 2
# series has not released by the last measurement is, identically, the last
# measured burden.) The first point's replacement does NOT use this fit; see
# BOMB_T2_DROP_FIRST above.
# ⚠ tau is weakly determined: 6.87 yr as built, 5.67 without the single 7/69 row
# (which supplies 66 % of the fit's time baseline), and 5.54-7.13 across
# BOMB_TAIL_FIT_FROM in [1964, 1966].
lateR <- t2$t_mid >= BOMB_TAIL_FIT_FROM
lf <- lm(log(t2$kmol[lateR]) ~ t2$t_mid[lateR])
tau_tail <- -1 / coef(lf)[2]
inv2 <- t2$kmol
if (BOMB_T2_DROP_FIRST) {
  # Replace, do not delete: the t0 burden is what sets the pre/post-1963 split.
  # The first three quarters (356, 349, 301) imply almost no release in
  # Dec62-Feb63 followed by a large one, which is the known undercount; the
  # 2nd point is retained and the 1st is raised to preserve monotonicity with
  # the quarter-on-quarter release rate that follows it.
  rel_next <- t2$kmol[2] - t2$kmol[3]                # kmol released in Mar-May 63
  inv2[1] <- t2$kmol[2] + rel_next                   # assume a comparable release before it
}
I_t0 <- inv2[1]
cat(sprintf("Table 2: t0 = %.3f, burden %.2f kmol", t0, I_t0))
cat(if (BOMB_T2_DROP_FIRST)
      sprintf(" (raw %.2f raised per Tans p.133 'much too low')\n", t2$kmol[1]) else "\n")
cat(sprintf("  late-point tail: tau = %.2f yr (fit from %.0f)\n", tau_tail, BOMB_TAIL_FIT_FROM))

# Cumulative released; enforce non-decreasing (the single 9/65-11/65 ->
# 12/65-2/66 reversal is seasonality Tans himself dismisses, and a negative
# source is unphysical).
rel <- I_t0 - inv2
rel <- cummax(rel)
D_pre <- BOMB_TOTAL_REF_KMOL - I_t0
cat(sprintf("\nBudget closure: %.2f kmol delivered pre-%.2f (%.0f %% of total)\n",
            D_pre, t0, 100 * D_pre / BOMB_TOTAL_REF_KMOL))
if (D_pre <= 0) stop("Budget closure failed: t0 burden exceeds the reference total.")

# =====================================================================
# 3. lambda, closed-form from the pre-1963 budget, then checked independently
# =====================================================================
pre <- mt < t0
intN <- sum(N14[pre]) * MONTH_DT
N14_t0 <- N14[max(which(pre))]
lambda <- (D_pre - (N14_t0 - N14[1])) / intN
cat(sprintf("  tropospheric burden at %.2f: %.2f kmol -> uptake %.2f kmol (%.0f %% of pre-1963)\n",
            t0, N14_t0, D_pre - N14_t0, 100 * (D_pre - N14_t0) / D_pre))
cat(sprintf("  budget-closing lambda = %.4f /yr (%.2f yr)\n", lambda, 1 / lambda))
A_oc <- ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")
lambda_as <- (BOMB_GROSS_AS_FLUX * A_oc * ccx_const("R14_STD") *
                (d14c_ex[max(which(pre))] / 1000) / 1000) / N14_t0
cat(sprintf("  independent check, gross air-sea alone: %.4f /yr (%.2f yr) = %.0f %% of it\n",
            lambda_as, 1 / lambda_as, 100 * lambda_as / lambda))

# the concentration-implied delivery, used for SHAPE only
g <- c(diff(N14), NA) / MONTH_DT
g[length(g)] <- g[length(g) - 1]
g <- g + lambda * N14

# Smooth before use as a shape (see BOMB_SHAPE_SMOOTH_M). Edges are handled by
# reflection so the 1952 and 1980 ends are not pulled toward zero.
if (BOMB_SHAPE_SMOOTH_M > 1) {
  h <- (BOMB_SHAPE_SMOOTH_M - 1) %/% 2
  pad <- c(rev(g[2:(h + 1)]), g, rev(g[(length(g) - h):(length(g) - 1)]))
  g <- stats::filter(pad, rep(1 / BOMB_SHAPE_SMOOTH_M, BOMB_SHAPE_SMOOTH_M),
                     sides = 2)[(h + 1):(h + length(mt))]
  g <- as.numeric(g)
  cat(sprintf("  shape smoothed with a %d-month centred average\n", BOMB_SHAPE_SMOOTH_M))
}

# =====================================================================
# 4. Assemble: interval totals from inventory, within-interval shape from g
# =====================================================================
# Breakpoints are ANNUAL throughout, anchored on t0 so the Table 2 series is
# read Dec-to-Dec.
#
# WHY NOT QUARTERLY, when Table 2 is quarterly: because its quarterly
# DIFFERENCES are not resolved. Telegadas reports inventories to ~3 figures, and
# the 14 quarter-on-quarter releases are 7, 48, 29, 17, 30, 42, 13, 0, 14, 5, 7,
# -2, 15, 3 -- the small ones are rounding, not physics. The 0 comes from "170"
# being reported twice in succession, and it produced three months of EXACTLY
# zero delivery whose notch pinned the modeled NH peak at 1964.625 in every run
# of a k_w / kz / h_ml / tau_ex sweep spanning 2-4x. Annual sums (1963: 101,
# 1964: 85, 1965: 24 units) sit far above that noise floor. So we do not in
# practice have sub-annual EMISSION data, and the concentration record supplies
# the sub-annual pattern throughout -- which is the stated principle, applied
# consistently rather than only before 1963.
brk <- c(rev(seq(t0, BOMB_EXCESS_ZERO_YR, by = -1)), seq(t0 + 1, BOMB_SERIES_END_YR + 1, by = 1))
brk <- sort(unique(brk[brk >= BOMB_EXCESS_ZERO_YR & brk <= BOMB_SERIES_END_YR + 1]))

# total delivered in each interval
tot <- numeric(length(brk) - 1)
for (k in seq_along(tot)) {
  a <- brk[k]; b <- brk[k + 1]
  if (b <= t0) {
    # pre-1963: annual share of D_pre, apportioned by the concentration-implied
    # delivery (the only information available at this timescale)
    sel <- mt >= a & mt < b & pre
    tot[k] <- sum(pmax(g[sel], 0)) * MONTH_DT
  } else if (a >= max(t2$t_mid)) {
    tot[k] <- NA                                   # exponential tail, filled below
  } else {
    # Table 2 stratospheric decrease over the year. `rel` is interpolated
    # linearly in time rather than snapped to the nearest reported quarter, so a
    # year boundary that falls between reported quarters is not rounded onto one.
    ra <- stats::approx(t2$t_mid, rel, xout = a, rule = 2)$y
    rb <- stats::approx(t2$t_mid, rel, xout = min(b, max(t2$t_mid)), rule = 2)$y
    tot[k] <- rb - ra
  }
}
# normalize the pre-1963 block so it sums exactly to the budget-closed total
ipre <- which(brk[-1] <= t0)
tot[ipre] <- tot[ipre] * D_pre / sum(tot[ipre])
# tail: whatever the Table 2 series has not yet released, decaying at tau_tail
remaining <- BOMB_TOTAL_REF_KMOL - D_pre - sum(tot[!is.na(tot) & brk[-1] > t0])
itail <- which(is.na(tot))
if (length(itail)) {
  a <- brk[itail]; b <- brk[itail + 1]
  wgt <- exp(-(a - max(t2$t_mid)) / tau_tail) - exp(-(b - max(t2$t_mid)) / tau_tail)
  tot[itail] <- remaining * wgt / sum(wgt)
}
cat(sprintf("  post-%.2f tail carries %.2f kmol at tau = %.2f yr\n",
            max(t2$t_mid), remaining, tau_tail))

# distribute each interval's total over its months using g's shape
flux <- numeric(length(mt))
for (k in seq_along(tot)) {
  sel <- which(mt >= brk[k] & mt < brk[k + 1])
  if (!length(sel) || !is.finite(tot[k]) || tot[k] <= 0) next
  w <- pmax(g[sel], 0)
  if (sum(w) <= 0) w <- rep(BOMB_SHAPE_FLOOR, length(sel))   # fall back to flat
  flux[sel] <- tot[k] * (w / sum(w)) / MONTH_DT
}

released <- sum(flux) * MONTH_DT
cat(sprintf("\nAssembled: %.2f kmol on %.0f-%.0f (%.1f %% of reference retained)\n",
            released, BOMB_EXCESS_ZERO_YR, BOMB_SERIES_END_YR,
            100 * released / BOMB_TOTAL_REF_KMOL))

shape <- flux / released
out <- data.frame(t = mt, year = floor(mt),
                  month = as.integer(round((mt - floor(mt)) * 12 + 0.5)),
                  shape_per_yr = shape)
attr(out, "provenance") <- list(
  source = "Tans (1981) SCOPE 16 Tables 1-2 (Table 2 after Telegadas 1971); sub-annual shape from Hua et al. 2022 observed D14C",
  method = "interval totals from inventory data (Table 2 quarterly where available, budget-closed annual before 1963, apportioned by the concentration record; Table 1 is NOT read by this script); within-interval shape from concentration-implied delivery dN14/dt + lambda*N14",
  t0 = t0, burden_t0_kmol = I_t0, tau_tail = tau_tail,
  dropped_first_point = BOMB_T2_DROP_FIRST,
  t2_high_bias_divisor = BOMB_T2_HIGH_BIAS,
  pre1963 = list(delivered_kmol = D_pre, lambda_per_yr = lambda,
                 lambda_ocean_only = lambda_as,
                 prebomb_baseline_permil = BOMB_PREBOMB_D14C,
                 zero_anchor_year = BOMB_EXCESS_ZERO_YR),
  total_ref_kmol = BOMB_TOTAL_REF_KMOL, built = Sys.Date())
saveRDS(out, BOMB_OUT_FILE)
cat(sprintf("wrote %s (%d months)\n", BOMB_OUT_FILE, nrow(out)))

# =====================================================================
# 5. Diagnostics
# =====================================================================
f_kmol <- shape * BOMB_TOTAL_REF_KMOL
cat("\nDelivery across the 1962-63 transition (kmol/yr) -- the old join region:\n")
for (i in which(mt > 1962.4 & mt < 1963.9))
  cat(sprintf("  %8.3f %8.2f%s\n", mt[i], f_kmol[i],
              if (mt[i] >= t0 && mt[i] < t0 + 1/12) "  <- first Table 2 month" else ""))
j <- which(mt >= t0)[1]
cat(sprintf("\njoin step: %.2f -> %.2f kmol/yr = %.2fx in one month\n",
            f_kmol[j - 1], f_kmol[j], f_kmol[j] / f_kmol[j - 1]))
ann <- tapply(shape, out$year, function(z) sum(z) * MONTH_DT)
old_sh <- c(0.2,0.3,0,0.4,0.2,0,0.9,1.2,0.9,4,2,3.5,3,8,0,0.2,15,22,1.5,0.4,0.3,
            0.6,0.5,0.6,0.3,0.5,0.3,0.2,0.3,0.4,0.1,0.3,0.1,0.1,0,0.2)
old_yr <- 1945:1980; old_w <- old_sh / sum(old_sh)
cat("\nAnnual share of total delivered:\n")
cat(sprintf("%6s %8s %8s\n", "year", "NEW", "OLD"))
for (y in 1959:1967) {
  n <- if (as.character(y) %in% names(ann)) ann[[as.character(y)]] else 0
  cat(sprintf("%6d %7.1f%% %7.1f%%\n", y, 100 * n, 100 * old_w[old_yr == y]))
}
cat(sprintf("\nPeak delivery month: %.3f\n", mt[which.max(shape)]))
cat(sprintf("Pre-1963 share: NEW %.0f %%, OLD %.0f %%\n",
            100 * sum(shape[pre]) * MONTH_DT, 100 * sum(old_w[old_yr < 1963])))
