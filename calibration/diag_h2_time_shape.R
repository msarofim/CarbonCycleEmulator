#!/usr/bin/env Rscript
# =====================================================================
# diag_h2_time_shape.R -- H2's TEST: the TIME SHAPE of CCX's ocean-sink climate effect against GCB 2025's GOBM
# ensemble (Fig. S10), 1959-2024. 2026-10-06, Marcus: "Do the H2 diagnostic and test."
#
# H2 (CHANGELOG 10-04 p): "CCX's vertical exchange (kz ~27x diapycnal) returns unwarmed DIC to a uniformly warmed
# surface, defeating the surface-DIC damping Bunsen describes" -- so CCX's climate effect is too strong (1.87x GCB
# like-for-like at hilda33p, 10-05 p). The record's test: "the time shape against GCB Fig. S10" (10-04 p, which
# noted by eye that "CCX goes negative about two decades before GCB's ensemble").
#
# THE TWO SERIES, like for like:
#   CCX: the like-for-like emulation of GCB's protocol (sim A - C, CO2 prescribed), the mean over GCB's ten GOBM
#        protocols, at hilda33p: outputs/diagnostics/ocean_climate_gobm_20261005_obj16.rds `series` (its mode md5
#        is checked against the canonical's file). The ten protocols' spread is shown beside it.
#   GCB: Fig. S10's global ensemble mean, digitised and gated (data/gcb2025_s10_ocean_climate_global.rds, from
#        data-raw/build_gcb2025_s10_ocean_climate.R: 2015-24 reproduces GCB's stated -0.20 within one pixel).
# THE METRICS (none was recorded with the test; each is stated here before it is read):
#   M1 decade means, each with its uncertainty: GCB's stated 1 sigma (0.05, the GOBM spread over 2015-24, applied
#      to every decade -- an assumption, stated) and the digitisation's one pixel (0.026); CCX's protocol range.
#   M2 EMERGENCE: the first year after which the 11-yr centred mean stays below H2_EMERGE (half of GCB's 2015-24
#      value), with the threshold moved +-20 % as its own sensitivity.
#   M3 THE H2 SIGNATURE: each series regressed on the global SST anomaly (HadSST4, the model's own forcing, mean
#      of the two hemispheres, relative to 1959-68). H2 predicts a LARGER per-K response in CCX, with the gap
#      growing with the warming; a constant offset would instead point to an emulation artefact, and a gap that
#      opens only after ~2000 to the wind term CCX lacks. OLS se (the residuals are autocorrelated, so the se is a
#      floor), and the same fit on decade means as a robustness check.
#   M4 SHAPE: the correlation of the year-to-year anomalies (each series minus its 11-yr running mean).
# Nothing here changes the model. No RNG. Run from the repo root: Rscript calibration/diag_h2_time_shape.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants (every label below derives from these) -------------------------------
H2_DRIVER   <- "calibration/diag_h2_time_shape.R"
# the CCX series: diag_ocean_climate_gobm.R's `series` AT THE CANONICAL (the md5 gate below refuses any other).
# CCX_H2_SERIES overrides it (2026-10-08 i: hilda29e's is ocean_climate_gobm_20261008_obj18p2b1.rds); the default
# stays the 10-06 (j) run's, hilda33p's, so that record still reproduces from this file.
H2_CCX_RDS  <- Sys.getenv("CCX_H2_SERIES", file.path("outputs", "diagnostics", "ocean_climate_gobm_20261005_obj16.rds"))
H2_GCB_RDS  <- file.path("data", "gcb2025_s10_ocean_climate_global.rds")
H2_SST_RDS  <- file.path("data", "forcing_sst.rds")
H2_YEARS    <- 1959:2024
H2_BASE     <- 1959:1968                      # the SST anomaly's reference: the record's first decade
H2_GCB_SD   <- 0.05                           # GCB 2025 p. 3242: 1 sigma over the 10 GOBMs, 2015-24
H2_PX       <- 1 / 39                         # the digitisation's pixel, GtC/yr
H2_EMERGE   <- -0.10                          # half of GCB's stated 2015-24 value
H2_RUN      <- 11L                            # the running mean's width, years (an odd, centred window)
H2_DECADES  <- list(`1960s` = 1960:1969, `1970s` = 1970:1979, `1980s` = 1980:1989, `1990s` = 1990:1999,
                    `2000s` = 2000:2009, `2010-14` = 2010:2014, `2015-24` = 2015:2024)
H2_OUT      <- file.path("outputs", "diagnostics", sprintf("h2_time_shape_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
COMMIT      <- ccx_git_stamp()

LOGCON <- file(paste0(H2_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s | %s\n", H2_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))

# ---- the two series ----------------------------------------------------------------------------------------
X <- readRDS(H2_CCX_RDS)
# the FIRST md5 in the provenance is the mode file's ("mode <name> (<path>, md5 ...)"); the supplement's comes later
mode_md5 <- sub("^md5 ", "", regmatches(X$provenance, regexpr("md5 [0-9a-f]{32}", X$provenance)))
canon_md5 <- unname(tools::md5sum(ccx_mode_file(CCX_MODE_CANONICAL)))
cat(sprintf("CCX: %s (protocol mean of %d GOBM protocols); its mode md5 %s, the canonical %s's %s -> %s\n", H2_CCX_RDS,
            ncol(X$series), mode_md5, CCX_MODE_CANONICAL, canon_md5, if (identical(mode_md5, canon_md5)) "SAME FILE" else "DIFFERENT"))
if (!identical(mode_md5, canon_md5)) stop("the stored series is not the canonical's")
S <- X$series[as.character(H2_YEARS), , drop = FALSE]
ccx <- rowMeans(S); ccx_lo <- apply(S, 1, min); ccx_hi <- apply(S, 1, max)
G <- readRDS(H2_GCB_RDS); gp <- attr(G, "provenance")
gcb <- G$climate_effect_GtC[match(H2_YEARS, G$year)]
stopifnot(!anyNA(gcb), !anyNA(ccx))
cat(sprintf("GCB: %s (%s; its gate: 2015-24 %.3f vs stated %.2f)\n", H2_GCB_RDS, gp$figure, gp$validation$digitised,
            gp$validation$target[["mean"]]))
so <- as.data.frame(readRDS(H2_SST_RDS))
sst <- (so$sst_anom_NH + so$sst_anom_SH) / 2; names(sst) <- so$year
dsst <- sst[as.character(H2_YEARS)] - mean(sst[as.character(H2_BASE)])
stopifnot(!anyNA(dsst))

# ---- M1 decade means ---------------------------------------------------------------------------------------
cat("\n=== M1. DECADE MEANS (GtC/yr, uptake positive; negative = warming reduces the sink) ===\n")
m1 <- do.call(rbind, lapply(names(H2_DECADES), function(d) { i <- H2_YEARS %in% H2_DECADES[[d]]
  data.frame(period = d, ccx = mean(ccx[i]), ccx_lo = mean(ccx_lo[i]), ccx_hi = mean(ccx_hi[i]), gcb = mean(gcb[i]),
             gap = mean(ccx[i]) - mean(gcb[i]), z = (mean(ccx[i]) - mean(gcb[i])) / sqrt(H2_GCB_SD^2 + H2_PX^2),
             dsst_K = mean(dsst[i])) }))
print(format(m1, digits = 3), row.names = FALSE)
cat(sprintf("  (z = gap / sqrt(GCB's %.2f^2 + the pixel %.3f^2); CCX's lo/hi = the range over its %d protocols)\n",
            H2_GCB_SD, H2_PX, ncol(S)))

# ---- M2 emergence ------------------------------------------------------------------------------------------
run_mean <- function(x, k = H2_RUN) { h <- (k - 1L) / 2L; n <- length(x)
  vapply(seq_len(n), function(i) if (i <= h || i > n - h) NA_real_ else mean(x[(i - h):(i + h)]), 0) }
emerge <- function(x, thr) { r <- run_mean(x); ok <- which(is.finite(r))
  below <- r[ok] < thr; if (!below[length(below)]) return(NA_integer_)
  last_above <- max(c(0L, which(!below))); as.integer(H2_YEARS[ok][last_above + 1L]) }
cat(sprintf("\n=== M2. EMERGENCE: first year after which the %d-yr centred mean stays below the threshold ===\n", H2_RUN))
m2 <- do.call(rbind, lapply(H2_EMERGE * c(0.8, 1, 1.2), function(t)
  data.frame(threshold = t, ccx = emerge(ccx, t), gcb = emerge(gcb, t))))
m2$lead_yr <- m2$gcb - m2$ccx
print(m2, row.names = FALSE)

# ---- M3 the H2 signature: the response per K of SST warming ------------------------------------------------
fit <- function(y, x) { f <- stats::lm(y ~ x); s <- summary(f)$coefficients
  c(a = s[1, 1], a_se = s[1, 2], b = s[2, 1], b_se = s[2, 2], r2 = summary(f)$r.squared) }
cat("\n=== M3. THE H2 SIGNATURE: each series regressed on the global SST anomaly (HadSST4, K vs 1959-68) ===\n")
m3 <- rbind(ccx = fit(ccx, dsst), gcb = fit(gcb, dsst), gap = fit(ccx - gcb, dsst))
print(round(m3, 4))
dm <- do.call(rbind, lapply(H2_DECADES, function(yy) { i <- H2_YEARS %in% yy; c(c = mean(ccx[i]), g = mean(gcb[i]), t = mean(dsst[i])) }))
m3d <- rbind(ccx = stats::coef(stats::lm(dm[, "c"] ~ dm[, "t"])), gcb = stats::coef(stats::lm(dm[, "g"] ~ dm[, "t"])))
colnames(m3d) <- c("a", "b")
cat("  on decade means (robustness):\n"); print(round(m3d, 4))
ratio <- m3["ccx", "b"] / m3["gcb", "b"]
ratio_se <- abs(ratio) * sqrt((m3["ccx", "b_se"] / m3["ccx", "b"])^2 + (m3["gcb", "b_se"] / m3["gcb", "b"])^2)
cat(sprintf("  per-K response: CCX %.3f +/- %.3f, GCB %.3f +/- %.3f GtC/yr per K; ratio %.2f +/- %.2f (OLS se: a floor, the residuals are autocorrelated)\n",
            m3["ccx", "b"], m3["ccx", "b_se"], m3["gcb", "b"], m3["gcb", "b_se"], ratio, ratio_se))
cat(sprintf("  the gap's intercept %.3f +/- %.3f GtC/yr at no warming (H2: ~0; an artefact: a constant offset)\n",
            m3["gap", "a"], m3["gap", "a_se"]))

# ---- M4 shape ---------------------------------------------------------------------------------------------
anom <- function(x) x - run_mean(x)
ok <- is.finite(anom(ccx)) & is.finite(anom(gcb))
r4 <- stats::cor(anom(ccx)[ok], anom(gcb)[ok])
cat(sprintf("\n=== M4. SHAPE: correlation of the year-to-year anomalies (minus each series' %d-yr running mean), %d years: r = %.2f ===\n",
            H2_RUN, sum(ok), r4))
cat(sprintf("  their sd: CCX %.3f, GCB %.3f GtC/yr\n", stats::sd(anom(ccx)[ok]), stats::sd(anom(gcb)[ok])))

# ---- the figure -------------------------------------------------------------------------------------------
grDevices::png(paste0(H2_OUT, ".png"), width = 900, height = 520, res = 110)
graphics::par(mar = c(4.2, 4.6, 3.2, 1))
yl <- range(c(ccx_lo, ccx_hi, gcb, 0))
graphics::plot(H2_YEARS, ccx, type = "n", ylim = yl, xlab = "Year",
               ylab = "Ocean sink climate effect (GtC/yr)",
               main = sprintf("H2 test: the ocean sink's climate effect, CCX %s vs GCB 2025 GOBMs (Fig. S10)", CCX_MODE_CANONICAL),
               cex.main = 0.95)
graphics::polygon(c(H2_YEARS, rev(H2_YEARS)), c(ccx_lo, rev(ccx_hi)), col = grDevices::adjustcolor("firebrick", 0.18), border = NA)
graphics::abline(h = 0, col = "grey60")
graphics::lines(H2_YEARS, ccx, col = "firebrick", lwd = 2)
graphics::lines(H2_YEARS, gcb, col = "navy", lwd = 2)
graphics::legend("bottomleft", bty = "n", cex = 0.85, lwd = c(2, 2, 8), col = c("firebrick", "navy", grDevices::adjustcolor("firebrick", 0.18)),
                 legend = c(sprintf("CCX, mean of GCB's %d GOBM protocols (like for like, CO2 prescribed)", ncol(S)),
                            "GCB 2025 GOBM ensemble mean (Fig. S10, digitised)", "CCX, range over the protocols"))
graphics::mtext(sprintf("A - C, uptake positive. %s @%s", H2_DRIVER, COMMIT), side = 1, line = 3, adj = 1, cex = 0.6, col = "grey40")
grDevices::dev.off()

sink()
saveRDS(list(years = H2_YEARS, ccx = ccx, ccx_lo = ccx_lo, ccx_hi = ccx_hi, gcb = gcb, dsst = dsst, m1 = m1, m2 = m2,
             m3 = m3, m3_decades = m3d, ratio = c(ratio = ratio, se = ratio_se), m4 = r4,
             provenance = list(driver = H2_DRIVER, commit = COMMIT, ccx = H2_CCX_RDS, ccx_mode_md5 = mode_md5,
                               gcb = H2_GCB_RDS, gcb_provenance = gp$commit, sst = H2_SST_RDS, rng = "none",
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(H2_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds,png}\n", H2_OUT))
