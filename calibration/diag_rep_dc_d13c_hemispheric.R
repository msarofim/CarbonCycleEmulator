# =====================================================================
# diag_rep_dc_d13c_hemispheric.R -- N5 (Marcus 2026-09-22): "do we expect
# isotope differences between Mauna Loa/SPO and hemispheric averages,
# particularly hemispheric SURFACE averages?"
#
# The d13C analog of diag_rep_dc_mbl_zonal.R, and it asks a sharper question
# than the CO2 one could. `rep_dC` is ONE parameter tied across species by mass
# balance (R/likelihood.R, LIK_REP_SOURCE_D13C): the d13C station offset is not
# fitted, it is DERIVED from the CO2 one as
#     box - station = rep_dC * (d_s - d13c_box) / co2_box
# with d_s the assumed signature of the excess carbon. So there are TWO things
# to test, and the second has never been tested at all:
#
#   1. Is the model's implied d13C offset the size of the observed one?
#   2. ⭐ IS THE MASS-BALANCE TIE ITSELF RIGHT? Feed the MEASURED CO2 offset
#      (+0.78 ppm, diag_rep_dc_mbl_zonal.R) through the same formula and ask
#      whether it predicts the MEASURED d13C offset. That tests
#      LIK_REP_SOURCE_D13C against observation instead of against itself --
#      and that constant is flagged PROVISIONAL and UNCITED in R/likelihood.R.
#
# ⚠ THE OBSERVED HEMISPHERIC MEAN IS BUILT, NOT DOWNLOADED. NOAA publishes no
# zonal d13C reference (measured: the MBL form offers CO2/CH4/N2O/SF6 and
# `ghg.php?param=C13` returns an empty fragment). data-raw/build_hemispheric_flask_means.R
# builds one from the flask network on Marcus's ruling -- all sites,
# latitude-band-area weighted, gaps dropped -- and its method attribute travels
# with the product.
#
# ⛔ AND IT IS A SURFACE MEAN OVER A SPARSE NETWORK, which the CO2 comparison
# was not: NOAA's MBL product is a fitted, smoothed reference surface, this is
# a monthly average over whichever sites reported. The SH carries a median of
# 17 sites against the NH's 41. Treat the SH row as the weaker one -- for a
# different reason than the CO2 case, where the weakness was circularity.
#
# Usage:  Rscript calibration/diag_rep_dc_d13c_hemispheric.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

D5_OBS    <- file.path(.root, "data", "obs_d13c_hemispheric.rds")
# ⭐ THE CO2 OFFSET FOR THE TIE TEST COMES FROM THE FLASK-BUILT MEAN, NOT FROM
# THE MBL REFERENCE. Both products are built by the same script, on the same 87
# sites, with the same weighting -- so a disagreement in part 2 is chemistry and
# not two different networks. ⚠ The MBL-based number (+0.738 / +0.814,
# diag_rep_dc_mbl_zonal.R) remains the headline CO2 result; it is the better
# product for the CO2 question on its own, being a fitted reference surface over
# a longer record. It is reported here alongside, as a cross-check on the
# flask-built one.
D5_CO2_OBS <- file.path(.root, "data", "obs_co2_hemispheric_flask.rds")
D5_CO2_MBL <- c(NH = 0.738, SH = 0.814)   # diag_rep_dc_mbl_zonal.R, for comparison
D5_WEIGHTS <- c("equalarea", "unweighted", "coslat")   # primary first

if (!file.exists(D5_OBS))
  stop("run data-raw/build_hemispheric_flask_means.R first")
hm <- readRDS(D5_OBS)
cat("=== the observed hemispheric mean ===\n")
cat(sprintf("  %s\n  %d sites; %s\n", attr(hm, "source"), attr(hm, "n_sites"),
            attr(hm, "method")))

# ---- the model's implied d13C offset, on its own state --------------
md <- ccx_load_mode(CCX_MODE_CANONICAL)
sp <- ccx_spinup_from_label(ccx_mode_spinup(md$md))(md$p)
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                        bomb_total_kmol = md$bomb_total, luc_scale = md$luc_scale)
o  <- ccx_run_fast(sp, F)$out
rep_dC <- md$err$rep_dC
stopifnot(is.numeric(rep_dC), length(rep_dC) == 1L)

#' box - station, in permil, EXACTLY as R/likelihood.R derives it
d13c_off <- function(d13c_box, co2_box, rdc) rdc * (LIK_REP_SOURCE_D13C - d13c_box) / co2_box

obs <- ccx_prepare_obs()$d13
arm <- list(NH = list(st = "MLO", box = "d13c_NH", co2 = "co2_NH"),
            SH = list(st = "SPO", box = "d13c_SH", co2 = "co2_SH"))

cat(sprintf("\n=== the model's IMPLIED d13C offset (derived from rep_dC = %+.3f ppm) ===\n", rep_dC))
mod <- list()
for (h in names(arm)) {
  a <- arm[[h]]
  k <- o$t >= 1990 & o$t <= 2014
  v <- d13c_off(o[[a$box]][k], o[[a$co2]][k], rep_dC)
  mod[[h]] <- mean(v)
  cat(sprintf("  %s (%s): %+0.4f permil   [range %+0.4f to %+0.4f over 1990-2014]\n",
              h, a$st, mean(v), min(v), max(v)))
}

# ---- the measured offset, matched month by month --------------------
cat("\n=== MEASURED: hemispheric mean MINUS station (permil) ===\n")
cat("    + = the hemispheric mean is HEAVIER (less negative) than the station\n\n")
meas <- list()
for (w in D5_WEIGHTS) {
  cat(sprintf("  weighting: %-11s", w))
  for (h in names(arm)) {
    a <- arm[[h]]
    ob <- obs[obs$station == a$st, ]
    ob$year <- floor(ob$decimal_date)
    ob$month <- pmin(12L, pmax(1L, as.integer(round((ob$decimal_date - ob$year) * 12 + 0.5))))
    hh <- hm[hm$hemi == h, c("year", "month", w)]
    names(hh)[3] <- "ref"
    d <- merge(ob[, c("year", "month", "d13c")], hh, by = c("year", "month"))
    d <- d[is.finite(d$ref) & is.finite(d$d13c), ]
    v <- d$ref - d$d13c
    if (w == D5_WEIGHTS[1]) meas[[h]] <- list(mean = mean(v), n = length(v),
                                              sd = stats::sd(v), years = range(d$year))
    cat(sprintf("   %s %+0.4f (n %d)", h, mean(v), length(v)))
  }
  cat("\n")
}
cat(sprintf("\n  primary = %s. ⚠ spread across the three weightings is the",
            D5_WEIGHTS[1]))
cat(" sensitivity to\n     the ruling's wording, not an uncertainty on the atmosphere.\n")

# ---- confrontation 1: size ------------------------------------------
cat("\n=== 1. DOES THE MODEL'S IMPLIED OFFSET MATCH THE MEASURED ONE? ===\n")
cat(sprintf("  %-28s %12s %12s\n", "", "NH", "SH"))
cat(sprintf("  %-28s %+12.4f %+12.4f\n", "model implies", mod$NH, mod$SH))
cat(sprintf("  %-28s %+12.4f %+12.4f\n", "MEASURED", meas$NH$mean, meas$SH$mean))
cat(sprintf("  %-28s %12s %12s\n", "same sign?",
            if (sign(mod$NH) == sign(meas$NH$mean)) "yes" else "NO",
            if (sign(mod$SH) == sign(meas$SH$mean)) "yes" else "NO"))
cat(sprintf("  %-28s %12.1f %12.1f\n", "model / measured",
            mod$NH / meas$NH$mean, mod$SH / meas$SH$mean))

# ---- confrontation 2: is the mass-balance TIE right? ----------------
# ---- the CO2 offset, from the SAME product family --------------------
cm <- readRDS(D5_CO2_OBS)
# THE MLO CO2 SERIES THE CANONICAL SCORES (2026-10-23): Scripps flask under the flask label (the same flasks as the
# MLO d13C above), swapped as ccx_loglik() swaps its targets; in situ under any other label.
D5_FLASK <- ccx_co2_flask_on(md$err)
co2obs <- ccx_obs_co2_scored(ccx_prepare_obs(), D5_FLASK, monthly = TRUE)$co2
cat(sprintf("\n(%s @%s | canonical %s | MLO CO2 series: %s)\n", "calibration/diag_rep_dc_d13c_hemispheric.R",
            ccx_git_stamp(), CCX_MODE_CANONICAL, if (D5_FLASK) "Scripps FLASK" else "Scripps in situ"))
co2off <- list()
cat("\n=== the CO2 station offset, from the SAME 87 sites and weighting ===\n")
for (h in names(arm)) {
  a <- arm[[h]]
  ob <- co2obs[co2obs$station == a$st, c("year", "month", "co2_ppm")]
  hh <- cm[cm$hemi == h, c("year", "month", D5_WEIGHTS[1])]; names(hh)[3] <- "ref"
  d <- merge(ob, hh, by = c("year", "month"))
  # ⚠ RESTRICTED TO THE d13C ERA so the two species are compared over the same
  # months as well as the same sites -- the CO2 flask record runs to 2025 and
  # the d13C one stops in 2014.
  d <- d[d$year >= min(hm$year) & d$year <= max(hm$year), ]
  v <- d$ref - d$co2_ppm
  co2off[[h]] <- mean(v)
  cat(sprintf("  %s (%s): %+0.4f ppm over %d months, %d-%d   [MBL reference: %+0.3f]\n",
              h, a$st, mean(v), nrow(d), min(d$year), max(d$year), D5_CO2_MBL[[h]]))
}

cat("\n=== 2. ⭐ THE MASS-BALANCE TIE, TESTED AGAINST OBSERVATION ===\n")
cat("  Feed the MEASURED CO2 offset through the model's own formula\n")
cat(sprintf("  (d_s = LIK_REP_SOURCE_D13C = %.1f permil, PROVISIONAL and UNCITED):\n\n",
            LIK_REP_SOURCE_D13C))
cat(sprintf("  %-34s %12s %12s\n", "", "NH", "SH"))
pred <- list(); implied <- list()
for (h in names(arm)) {
  a <- arm[[h]]
  k <- o$t >= min(hm$year) & o$t <= max(hm$year)
  pred[[h]] <- mean(d13c_off(o[[a$box]][k], o[[a$co2]][k], co2off[[h]]))
  # what source signature WOULD reconcile the two measured offsets?
  implied[[h]] <- mean(o[[a$box]][k]) +
    meas[[h]]$mean * mean(o[[a$co2]][k]) / co2off[[h]]
}
cat(sprintf("  %-34s %+12.4f %+12.4f\n", "predicted from the MEASURED CO2 offset",
            pred$NH, pred$SH))
cat(sprintf("  %-34s %+12.4f %+12.4f\n", "MEASURED d13C offset", meas$NH$mean, meas$SH$mean))
cat(sprintf("  %-34s %12.1f %12.1f\n", "measured / predicted",
            meas$NH$mean / pred$NH, meas$SH$mean / pred$SH))
cat(sprintf("\n  %-34s %12.1f %12.1f\n", "source signature that WOULD reconcile",
            implied$NH, implied$SH))
cat(sprintf("  %-34s %12.1f %12.1f\n", "  (the model assumes)",
            LIK_REP_SOURCE_D13C, LIK_REP_SOURCE_D13C))
cat("\n  ⇒ If these agree, the mass-balance tie is corroborated by observation and\n")
cat("    the d13C side of `rep_dC` is over-large for the SAME reason the CO2 side\n")
cat("    is. If they disagree, the TIE is the defect, not just the magnitude --\n")
cat("    and d_s is the uncited constant in it.\n")
cat(sprintf("\n  n = %d (NH) / %d (SH) matched months, %d-%d.\n",
            meas$NH$n, meas$SH$n, meas$NH$years[1], meas$NH$years[2]))
