# =====================================================================
# diag_hml_c1_kinkmap.R -- 2026-08-29.  PLAN ITEM (2), STEP 1: MEASURE.
#
# The C1 defect in `h_ml` was mapped 2026-08-18 over the REFIT'S BAND [85,120]
# and found 3 kinks -- "sparse, 5 of 3499 probe points", which is why it was
# recorded as a caveat rather than a blocker ([[ccx_hml_kink]]).
#
# ⚠ THAT BAND NO LONGER EXISTS. The sigma-inflation adoption of 2026-08-28
#   (`2153bd6`) RETIRED the [85,120] skip and gave `h_ml` an interior maximum
#   over its full prior support [30,200] ([[sigma_inflation_prices_the_band]]).
#   The sparsity verdict was measured on a band 5x narrower than the one the
#   sampler now explores, so it has to be RE-MEASURED before it is re-quoted.
#
# This driver measures ONLY. It changes no model code and adopts nothing.
# The fix (a C1 remap) is step 2 and is priced separately.
#
# Usage:  Rscript calibration/diag_hml_c1_kinkmap.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

## ---- named constants (all labels below derive from these) ------------
BAND_OLD   <- c(85, 120)      # the RETIRED refit band, ccx_hml_kink 08-18
BAND_NOW   <- c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)   # live prior support
PROBE_DZ   <- 0.01            # m, same probe spacing as diag_hess_eps_21par
KINK_MULT  <- 20              # detector: |2nd difference| > MULT x median
OUT_RDS    <- "outputs/diagnostics/hml_c1_kinkmap.rds"

kinkmap <- function(band) {
  kh <- seq(band[1], band[2], by = PROBE_DZ)
  KS <- t(sapply(kh, function(h) ccx_pump_shape(ccx_ocean_grid(h))))
  kt <- rowSums(abs(apply(KS, 2, function(v) diff(diff(v)))))
  kb <- which(kt > KINK_MULT * stats::median(kt) + 1e-14)
  if (!length(kb)) return(list(kinks = numeric(0), n_probe = length(kt), n_hit = 0, kh = kh, kt = kt))
  grp <- cumsum(c(TRUE, diff(kb) > 1))
  ks  <- vapply(split(kb, grp), function(ix) kh[ix[which.max(kt[ix])] + 1], numeric(1))
  list(kinks = unname(ks), n_probe = length(kt), n_hit = length(kb), kh = kh, kt = kt)
}

cat("=====================================================================\n")
cat("PLAN ITEM (2) STEP 1 -- IS THE h_ml C1 DEFECT STILL SPARSE?\n")
cat(sprintf("Detector: |2nd difference of pump shape| > %dx median, probe %.2f m\n",
            KINK_MULT, PROBE_DZ))
cat("=====================================================================\n\n")

res <- list()
for (nm in c("RETIRED refit band", "LIVE prior support")) {
  band <- if (nm == "RETIRED refit band") BAND_OLD else BAND_NOW
  r <- kinkmap(band); res[[nm]] <- r
  dens <- length(r$kinks) / diff(band)
  cat(sprintf("%-20s [%g, %g] m (%.0f m wide)\n", nm, band[1], band[2], diff(band)))
  cat(sprintf("   %d kink(s), %.3f per metre, %d of %d probe points carry one (%.2f%%)\n",
              length(r$kinks), dens, r$n_hit, r$n_probe, 100 * r$n_hit / r$n_probe))
  if (length(r$kinks) <= 12)
    cat(sprintf("   at h_ml = %s m\n", paste(sprintf("%.2f", r$kinks), collapse = ", ")))
  else
    cat(sprintf("   spacing: min %.2f m, median %.2f m, max %.2f m\n",
                min(diff(r$kinks)), stats::median(diff(r$kinks)), max(diff(r$kinks))))
  cat("\n")
}

old <- res[["RETIRED refit band"]]; now <- res[["LIVE prior support"]]
cat("VERDICT\n")
cat(sprintf("  The 08-18 reading (%d kinks, %.2f%% of probe points) was measured on a band\n",
            length(old$kinks), 100 * old$n_hit / old$n_probe))
cat(sprintf("  %.1fx narrower than the one the sampler now explores. On the LIVE support the\n",
            diff(BAND_NOW) / diff(BAND_OLD)))
cat(sprintf("  count is %d, i.e. %.1fx more kinks.\n", length(now$kinks),
            length(now$kinks) / max(1, length(old$kinks))))
# the honest statement of what changed: density, not just count
cat(sprintf("  DENSITY %.4f -> %.4f per metre (%.2fx) -- ", length(old$kinks)/diff(BAND_OLD),
            length(now$kinks)/diff(BAND_NOW),
            (length(now$kinks)/diff(BAND_NOW)) / (length(old$kinks)/diff(BAND_OLD))))
cat(if (abs((length(now$kinks)/diff(BAND_NOW)) / (length(old$kinks)/diff(BAND_OLD)) - 1) < 0.25)
      "the defect is UNIFORM; the band got wider, the density did not.\n"
    else "the density itself CHANGED across the band.\n")
mn <- if (length(now$kinks) > 1) min(diff(now$kinks)) else NA_real_
cat(sprintf("  Closest pair anywhere on the live support: %.3f m apart.\n", mn))
cat(sprintf("  ARM_HESS_EPS reaches ~2e-3 m, so the Hessian row is contaminated within\n"))
cat(sprintf("  ~2 mm of a kink: %.4f%% of the live support, vs %.4f%% of the retired band.\n",
            100 * length(now$kinks) * 4e-3 / diff(BAND_NOW),
            100 * length(old$kinks) * 4e-3 / diff(BAND_OLD)))

saveRDS(list(res = res, bands = list(old = BAND_OLD, now = BAND_NOW),
             constants = list(probe_dz = PROBE_DZ, kink_mult = KINK_MULT),
             provenance = list(when = "2026-08-29",
                               commit = system("git rev-parse --short HEAD", intern = TRUE))),
        OUT_RDS)
cat(sprintf("\nWrote %s\n", OUT_RDS))
