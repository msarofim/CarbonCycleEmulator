# =====================================================================
# diag_rep_dc_d13c_marine.R -- N5's MARINE ARM, with the error bars the
# all-sites run never had.
#
# WHY THIS EXISTS (Marcus, 2026-09-22: "should we exclude the continental
# flasks?"). N5 was built on ALL 87 sites, per his earlier ruling, and it found
# (a) the d13C station offset is ~8x larger in the NH than the SH while the
# model's is common-mode, and (b) the CO2-d13C mass-balance tie needs a source
# signature of -35.1 permil north and -13.2 south against the model's single
# assumed -26.5. Both rest on offsets measured with an area weighting.
#
# THE OBJECTION IS ABOUT MASS, NOT CLEANLINESS. `rep_dC` compares a station
# against a MASS-WEIGHTED hemispheric box (`gtc_per_ppm_hemi = GtC_PER_PPM / 2`,
# R/model.R). Continental boundary-layer air is roughly 6 % of NH atmospheric
# mass (land fraction ~0.39 x BL mass fraction ~0.15); latitude-band-area
# weighting gives it its AREA share instead, several-fold more. NOAA's MBL
# product goes the other way and weights it at zero. The truth is between and
# nearer MBL -- so the two arms BRACKET the quantity the model wants, which is
# worth more than either arm arguing it is the answer.
#
# ⭐ AND IT MAY MOVE RESULT 2. -35.1 permil is close to what a CONTINENTAL LOCAL
# source mix would give (natural gas ~-44, fossil+respiration below -30) and
# outside anything hemispheric. If the NH offsets in BOTH species are being set
# by continental sites, -35.1 is measuring those sites and not the atmosphere,
# and the marine arm's implied signature should move toward -26.5. That is the
# test, and it is the reason to run it before the tie result is quoted anywhere.
#
# THREE THINGS THE ALL-SITES RUN DID NOT HAVE, all added here:
#   1. AN EXTERNAL CHECK. The marine arm's CO2 offset should reproduce the
#      published MBL zonal reference. ⚠ Computed over THE SAME MONTHS, not
#      against the published 47-year mean: the NH offset trends at -0.105
#      ppm/decade, so comparing a 1989-2014 window against a 1979-2025 mean
#      would manufacture a discrepancy. The gate prints INSIDE/OUTSIDE.
#   2. ERROR BARS. Nothing in the 09-22 (v) log carries one, and the SH implied
#      signature is a RATIO WHOSE NUMERATOR IS -0.011 permil. Whether the SH
#      half of "opposite directions" is a measurement or a near-zero numerator
#      is currently unanswered. Block bootstrap BY YEAR (the unit that carries
#      the seasonal cycle and most of the persistence), resampling the SAME
#      years for both species so the ratio keeps their covariance.
#   3. THE WEIGHTING SENSITIVITY OF THE SIGNATURE. (v) carried the d13C offset
#      under three weightings but the CO2 offset under one. The signature is
#      their ratio, so its sensitivity to the ruling's wording was never
#      measured. All three, both species, here.
#
# ⚠ THE SELF-INCLUSION ARM (`_mblx`). The all-sites NH mean CONTAINS Mauna Loa
# -- the station it is differenced against -- which pulls the mean toward the
# station and SHRINKS the offset. NOAA's selection drops MLO anyway, so the NH
# marine arm fixes it for free; it KEEPS South Pole, so `_mblx` is what measures
# it in the SH.
#
# ⛔ NOTHING IS ADOPTED HERE and the primary product is untouched: the build
# writes the marine columns BESIDE the all-sites ones and the all-sites values
# are bit-identical across the rebuild (gated).
#
# Usage:  Rscript calibration/diag_rep_dc_d13c_marine.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
MR_COMMIT <- ccx_git_stamp()
ccx_load_cpp()
.root <- normalizePath(".")

MR_DATE    <- format(Sys.Date(), "%Y%m%d")
MR_OBS     <- file.path(.root, "data", "obs_d13c_hemispheric.rds")
MR_CO2_OBS <- file.path(.root, "data", "obs_co2_hemispheric_flask.rds")
MR_MBL_DIR <- file.path(.root, "data-raw", "downloads")
MR_MBL_Z   <- c(NH = "mbl_zonal_co2_NH.txt", SH = "mbl_zonal_co2_SH.txt")
MR_WEIGHTS <- c("equalarea", "unweighted", "coslat")     # primary first
# The three networks, in the order they are reported. Suffixes are the column
# suffixes the build writes; "" is the all-sites primary.
MR_ARMS <- c(`all sites (the ruling)` = "",
             `marine (NOAA MBL)`      = "_mbl",
             `marine, station out`    = "_mblx")
MR_NBOOT <- 2000
MR_SEED  <- 20260922      # stamped into the log; see the provenance block
# A gate on the external check needs a tolerance. This one is DERIVED: the
# published MBL offset's own year-to-year sd (Appendix B of the 09-22 review:
# NH 0.282, SH 0.209 ppm), which is the scatter of the very quantity being
# compared. An absolute ppm tolerance here would be a number chosen to pass.
MR_MBL_SD <- c(NH = 0.282, SH = 0.209)
# ⚠ AN INTERVAL THAT CONTAINS EVERYTHING IS NOT EVIDENCE. The implied signature
# is a RATIO, and where its denominator (the CO2 offset) approaches zero the
# interval explodes and then "CONTAINS -26.5" for the same reason it would
# contain any number at all. The width above which the test has no power is
# DERIVED from the quantity: plausible carbon source signatures span roughly
# -10 permil (carbonate/ocean-influenced) to -45 (CH4-rich natural gas), about
# 35 permil, so an interval wider than that cannot discriminate between them and
# says so instead of reporting a verdict.
MR_SIG_SPAN <- 35
MR_OUT <- file.path(.root, "outputs", "diagnostics",
                    sprintf("rep_dc_d13c_marine_%s.log", MR_DATE))

con <- file(MR_OUT, open = "wt")
say <- function(fmt, ...) {
  s <- if (length(list(...))) sprintf(fmt, ...) else fmt
  cat(s, "\n", sep = ""); cat(s, "\n", sep = "", file = con)
}

hm <- readRDS(MR_OBS)
cm <- readRDS(MR_CO2_OBS)
if (is.null(hm$equalarea_mbl))
  stop("the marine arm is not in the product -- re-run data-raw/build_hemispheric_flask_means.R")

say("=====================================================================")
say("N5, MARINE ARM -- does excluding the continental flasks change it?")
say("  run     %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
say("  mode    %s", CCX_MODE_CANONICAL)
say("  commit  %s", MR_COMMIT)
say("  seed    %d, applied immediately before the block bootstrap (%d draws)",
    MR_SEED, MR_NBOOT)
say("  sites   %d all / %d in NOAA's CO2 MBL selection", attr(hm, "n_sites"), attr(hm, "n_mbl"))
say("  arms    %s", attr(hm, "arms"))
say("=====================================================================")

# ---- the model's implied offset, unchanged from the all-sites run ----
md <- ccx_load_mode(CCX_MODE_CANONICAL)
sp <- ccx_spinup_from_label(ccx_mode_spinup(md$md))(md$p)
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                        bomb_total_kmol = md$bomb_total, luc_scale = md$luc_scale)
o  <- ccx_run_fast(sp, F)$out
rep_dC <- md$err$rep_dC
d13c_off <- function(d13c_box, co2_box, rdc) rdc * (LIK_REP_SOURCE_D13C - d13c_box) / co2_box

obs    <- ccx_prepare_obs()$d13
co2obs <- ccx_prepare_obs()$co2
arm <- list(NH = list(st = "MLO", box = "d13c_NH", co2 = "co2_NH"),
            SH = list(st = "SPO", box = "d13c_SH", co2 = "co2_SH"))

YR <- range(hm$year)
mod <- list()
for (h in names(arm)) {
  a <- arm[[h]]; k <- o$t >= 1990 & o$t <= 2014
  mod[[h]] <- mean(d13c_off(o[[a$box]][k], o[[a$co2]][k], rep_dC))
}
say("\nmodel implies (common-mode, one `rep_dC` = %+.3f ppm): NH %+.4f   SH %+.4f permil",
    rep_dC, mod$NH, mod$SH)

# ---- matched monthly pairs, per hemisphere / arm / weighting ---------
# Both species merged onto the SAME months so a bootstrap year resamples a
# matched pair, never one species' months against the other's.
pairs_for <- function(h, suffix, w) {
  a   <- arm[[h]]
  col <- paste0(w, suffix)
  ob  <- obs[obs$station == a$st, ]
  ob$year  <- floor(ob$decimal_date)
  ob$month <- pmin(12L, pmax(1L, as.integer(round((ob$decimal_date - ob$year) * 12 + 0.5))))
  d13 <- merge(ob[, c("year", "month", "d13c")],
               stats::setNames(hm[hm$hemi == h, c("year", "month", col)],
                               c("year", "month", "ref13")),
               by = c("year", "month"))
  co2 <- merge(co2obs[co2obs$station == a$st, c("year", "month", "co2_ppm")],
               stats::setNames(cm[cm$hemi == h, c("year", "month", col)],
                               c("year", "month", "ref2")),
               by = c("year", "month"))
  d <- merge(d13, co2, by = c("year", "month"))
  # ⚠ the d13C record stops in 2014; restrict CO2 to the same window so the two
  # species are compared over the same months as well as the same network.
  d <- d[d$year >= YR[1] & d$year <= YR[2], ]
  d <- d[is.finite(d$ref13) & is.finite(d$ref2) & is.finite(d$d13c) & is.finite(d$co2_ppm), ]
  d$off13 <- d$ref13 - d$d13c
  d$off2  <- d$ref2  - d$co2_ppm
  d
}

# The signature that would reconcile a (CO2, d13C) offset pair, on the model's
# own atmospheric state -- the same inversion the all-sites run printed.
sig_for <- function(h, off13, off2) {
  a <- arm[[h]]; k <- o$t >= YR[1] & o$t <= YR[2]
  mean(o[[a$box]][k]) + off13 * mean(o[[a$co2]][k]) / off2
}
#' The verdict on one implied-signature interval, with NO POWER separated from
#' NOT REFUTED -- the two look identical in a CONTAINS/EXCLUDES print and mean
#' opposite things (project rule: measure a test's power before believing its
#' null).
sig_verdict <- function(ci, long = FALSE) {
  if (!all(is.finite(ci)) || diff(ci) > MR_SIG_SPAN)
    return(sprintf("UNINFORMATIVE -- interval %.0f permil wide (near-zero CO2 offset); no power",
                   diff(ci)))
  inside <- ci[1] <= LIK_REP_SOURCE_D13C && LIK_REP_SOURCE_D13C <= ci[2]
  if (inside) if (long) "CONTAINS -26.5 -- the tie is NOT refuted on this arm" else "CONTAINS -26.5"
  else "EXCLUDES -26.5"
}

pred_for <- function(h, off2) {
  a <- arm[[h]]; k <- o$t >= YR[1] & o$t <= YR[2]
  mean(d13c_off(o[[a$box]][k], o[[a$co2]][k], off2))
}

# ---- 1. THE ARMS, primary weighting ---------------------------------
say("\n---------------------------------------------------------------------")
say("1. THE OFFSETS AND THE IMPLIED SIGNATURE, BY ARM (weighting: %s)", MR_WEIGHTS[1])
say("---------------------------------------------------------------------")
say("  %-22s %4s %6s %8s %9s %9s %9s", "arm", "hem", "n_mo", "CO2 ppm", "d13C", "implied", "model")
set.seed(MR_SEED)                     # immediately before the RNG is consumed
boot <- list()
for (nm in names(MR_ARMS)) {
  sfx <- MR_ARMS[[nm]]
  for (h in names(arm)) {
    d <- pairs_for(h, sfx, MR_WEIGHTS[1])
    o2 <- mean(d$off2); o13 <- mean(d$off13)
    # BLOCK BOOTSTRAP BY YEAR: resample whole years with replacement, both
    # species together. The year is the block because it contains the seasonal
    # cycle entire and most of the month-to-month persistence.
    yrs <- unique(d$year)
    bs <- vapply(seq_len(MR_NBOOT), function(i) {
      pick <- sample(yrs, length(yrs), replace = TRUE)
      dd <- do.call(rbind, lapply(pick, function(y) d[d$year == y, ]))
      c(mean(dd$off2), mean(dd$off13),
        sig_for(h, mean(dd$off13), mean(dd$off2)))
    }, numeric(3))
    q <- function(i) stats::quantile(bs[i, ], c(0.025, 0.975), names = FALSE)
    boot[[paste(nm, h)]] <- list(o2 = o2, o13 = o13, sig = sig_for(h, o13, o2),
                                 pred = pred_for(h, o2),
                                 ci2 = q(1), ci13 = q(2), cisig = q(3),
                                 n = nrow(d), nyr = length(yrs))
    b <- boot[[paste(nm, h)]]
    say("  %-22s %4s %6d %+8.3f %+9.4f %+9.1f %+9.4f",
        if (h == "NH") nm else "", h, b$n, o2, o13, b$sig, mod[[h]])
  }
}
say("\n  95%% CI (block bootstrap by year, %d draws):", MR_NBOOT)
for (nm in names(MR_ARMS)) for (h in names(arm)) {
  b <- boot[[paste(nm, h)]]
  say("    %-22s %s  CO2 [%+.3f, %+.3f]  d13C [%+.4f, %+.4f]  signature [%+.1f, %+.1f]  (%d yr)",
      if (h == "NH") nm else "", h, b$ci2[1], b$ci2[2], b$ci13[1], b$ci13[2],
      b$cisig[1], b$cisig[2], b$nyr)
}

# ---- 2. THE EXTERNAL CHECK ------------------------------------------
# The marine arm is only worth preferring if it reproduces the product whose
# site selection it borrowed. Matched month by month over THIS window.
say("\n---------------------------------------------------------------------")
say("2. EXTERNAL CHECK -- does the marine arm reproduce NOAA's MBL reference?")
say("---------------------------------------------------------------------")
read_mbl <- function(z) {
  f <- file.path(MR_MBL_DIR, MR_MBL_Z[[z]])
  d <- utils::read.table(f, comment.char = "#",
                         col.names = c("year", "month", "day", "dec", "value", "unc"))
  d[is.finite(d$value), ]
}
for (h in names(arm)) {
  a <- arm[[h]]
  ob <- co2obs[co2obs$station == a$st, c("year", "month", "decimal_date", "co2_ppm")]
  z  <- read_mbl(h)
  ob$ref <- stats::approx(z$dec, z$value, xout = ob$decimal_date)$y   # no rule = 2
  ob <- ob[is.finite(ob$ref) & ob$year >= YR[1] & ob$year <= YR[2], ]
  mbl_win <- mean(ob$ref - ob$co2_ppm)
  for (nm in names(MR_ARMS)[2:3]) {
    b <- boot[[paste(nm, h)]]
    inside <- b$ci2[1] <= mbl_win && mbl_win <= b$ci2[2]
    say("  %s %-22s flask-marine %+.3f  vs  MBL zonal %+.3f over the same months (n %d)  %s",
        h, nm, b$o2, mbl_win, nrow(ob),
        if (inside) "INSIDE the arm's 95% CI" else "OUTSIDE the arm's 95% CI")
  }
  b0 <- boot[[paste(names(MR_ARMS)[1], h)]]
  say("  %s %-22s all-sites    %+.3f  vs  MBL zonal %+.3f                        %s",
      h, "(for contrast)", b0$o2, mbl_win,
      if (b0$ci2[1] <= mbl_win && mbl_win <= b0$ci2[2]) "INSIDE" else "OUTSIDE")
  say("    ⚠ the published 47-yr means are NH +0.738 / SH +0.814; this window's")
  say("      value differs because the NH offset TRENDS (-0.105 ppm/decade).")
}

# ---- 3. THE TIE, BY ARM ---------------------------------------------
say("\n---------------------------------------------------------------------")
say("3. THE MASS-BALANCE TIE, BY ARM (d_s = LIK_REP_SOURCE_D13C = %.1f permil)",
    LIK_REP_SOURCE_D13C)
say("---------------------------------------------------------------------")
say("  %-22s %4s %11s %11s %9s", "arm", "hem", "predicted", "measured", "meas/pred")
for (nm in names(MR_ARMS)) for (h in names(arm)) {
  b <- boot[[paste(nm, h)]]
  say("  %-22s %4s %+11.4f %+11.4f %9.1f",
      if (h == "NH") nm else "", h, b$pred, b$o13, b$o13 / b$pred)
}
say("\n  Does the assumed %.1f permil sit inside each arm's 95%% CI on the", LIK_REP_SOURCE_D13C)
say("  signature that would reconcile the two MEASURED offsets?")
for (nm in names(MR_ARMS)) for (h in names(arm)) {
  b <- boot[[paste(nm, h)]]
  say("    %-22s %s  [%+.1f, %+.1f]  %s", if (h == "NH") nm else "", h,
      b$cisig[1], b$cisig[2],
      sig_verdict(b$cisig, long = TRUE))
}

# ---- 4. WEIGHTING SENSITIVITY OF THE SIGNATURE ----------------------
say("\n---------------------------------------------------------------------")
say("4. THE SIGNATURE UNDER ALL THREE WEIGHTINGS (the gap (v) left)")
say("---------------------------------------------------------------------")
say("  both species re-measured under each weighting, so the RATIO is consistent")
say("  %-22s %4s %11s %11s %11s", "arm", "hem", MR_WEIGHTS[1], MR_WEIGHTS[2], MR_WEIGHTS[3])
for (nm in names(MR_ARMS)) for (h in names(arm)) {
  v <- vapply(MR_WEIGHTS, function(w) {
    d <- pairs_for(h, MR_ARMS[[nm]], w)
    sig_for(h, mean(d$off13), mean(d$off2))
  }, numeric(1))
  say("  %-22s %4s %+11.1f %+11.1f %+11.1f", if (h == "NH") nm else "", h, v[1], v[2], v[3])
}

# ---- 5. WHAT THE CONTINENTAL SITES THEMSELVES ADD -------------------
# The arms differ by the continental sites, so the DIFFERENCE between them is
# the air those sites contribute. Running the same inversion on that difference
# asks what signature the continental increment carries -- a Keeling-type
# reading of one network against the other. This is the section that explains
# the DIRECTION the marine arm moves, which was not the predicted one.
say("\n---------------------------------------------------------------------")
say("5. THE CONTINENTAL INCREMENT -- all-sites MINUS marine, as its own air mass")
say("---------------------------------------------------------------------")
set.seed(MR_SEED + 1L)
for (h in names(arm)) {
  da <- pairs_for(h, "", MR_WEIGHTS[1])
  dm <- pairs_for(h, "_mbl", MR_WEIGHTS[1])
  d  <- merge(da[, c("year", "month", "off2", "off13")],
              dm[, c("year", "month", "off2", "off13")],
              by = c("year", "month"), suffixes = c("_all", "_mbl"))
  d$i2  <- d$off2_all  - d$off2_mbl
  d$i13 <- d$off13_all - d$off13_mbl
  yrs <- unique(d$year)
  bs <- vapply(seq_len(MR_NBOOT), function(i) {
    dd <- do.call(rbind, lapply(sample(yrs, length(yrs), replace = TRUE),
                                function(y) d[d$year == y, ]))
    sig_for(h, mean(dd$i13), mean(dd$i2))
  }, numeric(1))
  ci <- stats::quantile(bs, c(0.025, 0.975), names = FALSE)
  say("  %s  increment: CO2 %+.3f ppm   d13C %+.4f permil   signature %+.1f  [%+.1f, %+.1f]  %s",
      h, mean(d$i2), mean(d$i13), sig_for(h, mean(d$i13), mean(d$i2)), ci[1], ci[2],
      sig_verdict(ci))
}
say("\n  ⇒ read this against section 3. If the increment CONTAINS -26.5 while the")
say("    marine residual EXCLUDES it, then the continental sites are the part of")
say("    the network that OBEYS the model's tie, and removing them leaves the")
say("    part that does not -- which is the opposite of the expected direction.")

say("\n=====================================================================")
say("⛔ NOTHING ADOPTED. The all-sites arm is Marcus's ruling and remains the")
say("primary in the product; this measures what the other arm says. The two")
say("arms BRACKET what the model's mass-weighted box wants -- all-sites weights")
say("continental air above its mass share, MBL weights it at zero.")
say("=====================================================================")
close(con)
cat("\nwritten: ", MR_OUT, "\n", sep = "")
