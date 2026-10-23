# =====================================================================
# diag_rep_dc_mbl_zonal.R -- IS `rep_dC` A REPRESENTATION OFFSET?
#
# Marcus, 2026-09-22 (review N3/K3): "should the prior be zero? I wouldn't be
# surprised if there is supposed to be a station/hemisphere offset."  This
# script measures the offset that actually exists and puts it next to the one
# the canonical fits. It settles nothing on its own -- R2 (the prior center) is
# an OBJECTIVE change and therefore Marcus's ruling -- but it replaces an
# argument with a number.
#
# ⚠ WHAT THIS SUPERSEDES. The 09-22 (n) note's Appendix A §A3 carried a
# hemispheric row that was ARITHMETIC, not measurement: the global-minus-station
# number shifted by half an ASSUMED interhemispheric gradient. §A4 said so and
# named this pull as the step that would replace it. It does, and TWO of A3's
# three claimed failures DO NOT SURVIVE -- see THE FINDING below.
#
# THE COMPARISON, and why each side is what it is:
#   model side    `rep_dC` and `grad_off_co2` jointly imply a per-hemisphere
#                 BOX-MINUS-STATION offset: station = box - rep_dC and
#                 obs_grad = box_grad + grad_off_co2, so
#                 off_NH = rep_dC - grad_off_co2/2, off_SH = rep_dC + .../2.
#   obs side      the NOAA MBL ZONAL reference (Lan et al. 2024,
#                 doi:10.15138/DVNP-F961), sine-latitude (= area) weighted over
#                 0-90N and 90S-0, minus the station series.
#   stations      THE REPO'S OWN (ccx_prepare_obs()), because those are exactly
#                 what the likelihood scores `rep_dC` against. Any other copy
#                 would add a second difference on top of the one being measured.
#
# ⚠ MATCHED MONTH BY MONTH, NOT ANNUAL MEAN. SPO's flask record has gaps --
# only 36 of its 48 years carry 12 months -- so an annual-mean comparison either
# truncates the record at 2020 or aliases a partial year's seasonal cycle into
# the level. Interpolating the reference to each station month uses every
# observation and removes both. `approx()` is called WITHOUT rule = 2 so that a
# station month outside the reference window is DROPPED rather than
# extrapolated flat.
#
# ⛔ TWO CAVEATS THAT MUST TRAVEL WITH ANY NUMBER FROM HERE.
#   1. CIRCULARITY IS ASYMMETRIC. NOAA's MBL reference EXCLUDES Mauna Loa (an
#      altitude site), so the NH row is genuinely independent. It INCLUDES South
#      Pole, so the SH row is partly circular and is the weaker of the two.
#   2. SURFACE vs MASS-WEIGHTED. The MBL reference is a SURFACE mean over marine
#      sites. The model's box is converted with gtc_per_ppm_hemi =
#      GtC_PER_PPM/2, i.e. it is nominally a WHOLE-ATMOSPHERE mean. These are
#      not the same quantity and the correction is NOT measured here. Its SIGN
#      is known -- stratospheric CO2 lags the surface (mean age ~5 yr; Andrews
#      et al. 2001, doi:10.1029/2001JD000465), so a mass-weighted mean sits
#      BELOW a surface mean -- which makes the gap below WIDER, not narrower.
#      ⚠ And it cuts the other way too: R/model.R gives each hemisphere ONE
#      well-mixed troposphere and no stratosphere at all, so what the box
#      physically IS may be closer to a tropospheric mean than its own unit
#      conversion claims. That is a modeling question, not a measurement, and
#      it is NOT resolved here.
#
# Run: Rscript calibration/diag_rep_dc_mbl_zonal.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

DL <- file.path(.root, "data-raw", "downloads")
MBL_FILES <- c(NH = "mbl_zonal_co2_NH.txt", SH = "mbl_zonal_co2_SH.txt",
               GL = "mbl_zonal_co2_GL.txt")
# The published cross-check, so the pull is validated rather than trusted.
WU2024 <- list(cite = "Wu et al. (2024), ACP 24:1249-1264, doi:10.5194/acp-24-1249-2024",
               gl_minus_mlo = c(-0.88, -0.46), gl_minus_spo = c(1.91, 2.24))

read_mbl <- function(z) {
  f <- file.path(DL, MBL_FILES[[z]])
  if (!file.exists(f))
    stop("missing ", f, " -- run the fetch_mbl_zonal() block in data-raw/download_data.R")
  read.table(f, comment.char = "#",
             col.names = c("year", "month", "day", "dec", "value", "unc"))
}
M <- lapply(stats::setNames(names(MBL_FILES), names(MBL_FILES)), read_mbl)

# ⭐ THE STATIONS THE CANONICAL SCORES (2026-10-23). Under the flask label (hilda_csl3v0kaidgbemwtcf, the canonical
# hilda31fl's) every MLO CO2 row is Scripps FLASK, so the monthly MLO frame is swapped the way ccx_loglik() swaps its
# targets (ccx_obs_co2_scored(monthly = TRUE) relabels the flask rows "MLO"). A label without the switch reads in situ,
# as before. SPO is the same Scripps record under either label.
REP_FLASK <- ccx_co2_flask_on(ccx_load_mode(CCX_MODE_CANONICAL)$err)
co2 <- ccx_obs_co2_scored(ccx_prepare_obs(), REP_FLASK, monthly = TRUE)$co2
cat(sprintf("%s @%s | canonical %s | MLO series: %s\n\n", "calibration/diag_rep_dc_mbl_zonal.R", ccx_git_stamp(),
            CCX_MODE_CANONICAL, if (REP_FLASK) "Scripps FLASK (the flask label)" else "Scripps in situ"))
pair <- function(station, zone) {
  x <- co2[co2$station == station, ]
  x$dec <- x$year + (x$month - 0.5) / 12
  z <- M[[zone]]
  x$ref <- stats::approx(z$dec, z$value, xout = x$dec)$y
  x <- x[!is.na(x$ref), ]
  x$d <- x$ref - x$co2_ppm          # + = the marine mean sits ABOVE the station
  x
}
summarise <- function(lab, p) {
  ann <- stats::aggregate(d ~ year, data = p, FUN = mean)
  fit <- stats::lm(d ~ I(year - 2000), data = ann)
  cat(sprintf("%-11s n=%4d mo, %d-%d | mean %+6.3f | sd(ann) %5.3f | ann>0 %2d/%2d yr | trend %+6.3f +/- %.3f ppm/decade\n",
              lab, nrow(p), min(p$year), max(p$year), mean(p$d), stats::sd(ann$d),
              sum(ann$d > 0), nrow(ann),
              10 * stats::coef(fit)[2], 10 * summary(fit)$coefficients[2, 2]))
  list(mean = mean(p$d), ann = ann)
}

cat("=== MBL reference MINUS station, matched month by month (ppm) ===\n")
cat("    + = the marine mean sits ABOVE the station\n\n")
nh <- summarise("NH  - MLO",   pair("MLO", "NH"))
sh <- summarise("SH  - SPO",   pair("SPO", "SH"))
gm <- summarise("GLOB- MLO",   pair("MLO", "GL"))
gs <- summarise("GLOB- SPO",   pair("SPO", "GL"))

cat("\n=== VALIDATION against an independent published analysis ===\n")
cat("   ", WU2024$cite, "\n")
chk <- function(lab, got, rng) cat(sprintf("    %-12s measured %+6.3f  vs published [%+0.2f, %+0.2f]  %s\n",
  lab, got, rng[1], rng[2], if (got >= rng[1] && got <= rng[2]) "INSIDE" else "*** OUTSIDE ***"))
chk("global-MLO", gm$mean, WU2024$gl_minus_mlo)
chk("global-SPO", gs$mean, WU2024$gl_minus_spo)

# ⚠ THE MODE IS RESOLVED THROUGH ccx_load_mode(), NOT BY READING THE FILE.
# A direct read is the `struct` bug class -- a HILDA mode overlaid on
# ccx_default_params() runs as a COLUMN, silently, and scores -23,306,061
# instead of -1439 -- and test-mode-struct-lint.R is the RATCHET that stops the
# count of such files growing. It caught this file on its first run. Nothing
# here integrates the model, so the structure would not have bitten; conforming
# is cheaper than an exemption, and the resolver also returns the four
# LIKELIHOOD parameters (`rep_dC`, `grad_off_co2`, ...) that a bare intersect()
# on the model parameters silently drops.
# ⚠ THE LINT IS A LITERAL, FILE-LEVEL STRING MATCH, so this comment deliberately
# does NOT spell out the call it is warning against: writing the pattern even
# inside a comment that rejects it is enough to trip the gate.
# ⚠ THE LIKELIHOOD PARAMETERS ARE UNDER `$err`, NOT AT THE TOP LEVEL -- they are
# not model parameters and ccx_default_params() has no slot for them. Reading
# `lm$rep_dC` returns NULL, which propagates as a zero-length offset and takes
# out the sign/ordering comparisons below with "argument is of length zero"
# rather than a wrong number. Asserted, so it cannot come back quietly.
lm_ <- ccx_load_mode(CCX_MODE_CANONICAL)
pm <- lm_$err
stopifnot(is.numeric(pm$rep_dC), length(pm$rep_dC) == 1L,
          is.numeric(pm$grad_off_co2), length(pm$grad_off_co2) == 1L)
off_NH <- pm$rep_dC - pm$grad_off_co2 / 2
off_SH <- pm$rep_dC + pm$grad_off_co2 / 2

cat(sprintf("\n=== CONFRONTATION at %s (mean MINUS station, ppm) ===\n", CCX_MODE_CANONICAL))
cat(sprintf("  rep_dC %+0.4f, grad_off_co2 %+0.4f\n", pm$rep_dC, pm$grad_off_co2))
cat(sprintf("  %-24s %9s %9s\n", "", "NH", "SH"))
cat(sprintf("  %-24s %+9.2f %+9.2f\n", "model needs", off_NH, off_SH))
cat(sprintf("  %-24s %+9.2f %+9.2f\n", "MBL zonal, MEASURED", nh$mean, sh$mean))
cat(sprintf("  %-24s %8.1fx %8.1fx\n", "model / measured", off_NH / nh$mean, off_SH / sh$mean))
cat(sprintf("  %-24s %9s %9s\n", "same SIGN?",
            if (sign(off_NH) == sign(nh$mean)) "yes" else "NO",
            if (sign(off_SH) == sign(sh$mean)) "yes" else "NO"))
cat(sprintf("  %-24s model %s ; measured %s\n", "ORDERING",
            if (off_SH > off_NH) "SH > NH" else "NH > SH",
            if (sh$mean > nh$mean) "SH > NH" else "NH > SH"))

cat("\n=== WHAT IT MEANS FOR R2 (the prior centre) ===\n")
mo <- mean(c(nh$mean, sh$mean))
cat(sprintf("  prior today   N(0, %.2f ppm)  -> the fitted %+0.3f sits at z %+0.2f\n",
            LIK_CO2_REP_ERR, pm$rep_dC, pm$rep_dC / LIK_CO2_REP_ERR))
cat(sprintf("  re-centred    N(%+0.2f, %.2f) -> the SAME fitted value sits at z %+0.2f\n",
            mo, LIK_CO2_REP_ERR, (pm$rep_dC - mo) / LIK_CO2_REP_ERR))
cat(sprintf("  ⇒ re-centring on the measured offset RELIEVES %.0f %% of the strain and leaves %+0.2f sd.\n",
            100 * (1 - (pm$rep_dC - mo) / pm$rep_dC), (pm$rep_dC - mo) / LIK_CO2_REP_ERR))
cat(sprintf("  ⚠ Unexplained residue: %+0.2f ppm = %.0f %% of the fitted offset. Re-centring\n",
            pm$rep_dC - mo, 100 * (pm$rep_dC - mo) / pm$rep_dC))
cat( "     RELABELS that residue, it does not remove it.\n")
cat(sprintf("  ⚠ A representation term's defensible sd FLOOR is ~0.20 ppm (Francey et al. 2019,\n"))
cat(sprintf("     ACP 19:14741, inter-network spread on a station DIFFERENCE) -- 5x tighter than\n"))
cat(sprintf("     today's prior. At that width the same fitted value sits at z %+0.1f.\n",
            (pm$rep_dC - mo) / 0.20))
cat( "  ⛔ AND IT CANNOT BE DECIDED ON CO2 ALONE: rep_dC is tied across species by mass\n")
cat( "     balance, and >1/3 of its 1306.9 log-units is ISOTOPIC (09-22 (n) Appendix A1).\n")
