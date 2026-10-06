#!/usr/bin/env Rscript
# =====================================================================
# fig_iav_cut_preview.R -- the four-panel figure for calibration/diag_iav_cut_preview.R (2026-10-06).
# Reads the driver's rds; recomputes only panel d's cross-correlation curves (the driver stored their peaks),
# from the same two data files, and GATES them against the driver's stored peaks.
#   a  the detrended monthly growth: observed, the canonical, the growth module's fit (A1)
#   b  the land ENSO lag profiles, each relative to its own best: the growth module; the main objective
#      with every row (10-06); without the four seasonal rows (C1). Likelihood throughout.
#   c  the four seasonal rows' preference split into information and visibility (C2), with the growth
#      record's own analogue
#   d  data only: GCB 2025's two land sinks against Nino 3.4 read k months late (C4)
# Usage: Rscript calibration/fig_iav_cut_preview.R [path/to/iav_cut_preview_<tag>.rds]
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants (every label below derives from these) -------------------------
FIG_DRIVER <- "calibration/fig_iav_cut_preview.R"
args <- commandArgs(trailingOnly = TRUE)
FIG_IN <- if (length(args)) args[1] else {
  c0 <- list.files(file.path("outputs", "diagnostics"), pattern = "^iav_cut_preview_[0-9]{8}_[a-z0-9]+[.]rds$", full.names = TRUE)
  if (!length(c0)) stop("no iav_cut_preview rds in outputs/diagnostics; pass a path"); sort(c0, decreasing = TRUE)[1] }
FIG_OUT <- sub("[.]rds$", ".png", FIG_IN)
FIG_C4_WIN <- c(1959L, 2024L)       # panel d's window (the driver's first C4 window)
FIG_C4_SHIFTS <- -6:18
FIG_GATE_TOL <- 0.005               # panel d's recomputed peaks against the driver's
COL <- c(ink = "#0b0b0b", ink2 = "#52514e", muted = "#8a8984", grid = "#e6e5e1", surface = "#fcfcfb",
         canonical = "#2a78d6", growth = "#eb6834", seasonal = "#1baf7a")   # reference palette slots 1-3

X <- readRDS(FIG_IN); P <- X$provenance
L0 <- setdiff(X$c1$L, P$lags_C1)                  # the canonical's lag: the one C1 cell off the driver's grid
stopifnot(length(L0) == 1L)
L_OBS <- 5
cat(sprintf("%s | input %s (%s @%s, mode %s%s)\n", FIG_DRIVER, FIG_IN, P$driver, P$commit, P$mode,
            if (isTRUE(P$smoke)) ", SMOKE" else ""))

# ---- panel d's curves, recomputed and gated -------------------------------------------
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
gcb$land_resid <- gcb$fossil + gcb$luc - gcb$atm_growth - gcb$ocean_sink - gcb$cement_carbonation
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
en$k <- as.integer(en$year) * 12L + en$month
g <- gcb[gcb$year >= FIG_C4_WIN[1] & gcb$year <= FIG_C4_WIN[2], ]
Xs <- stats::model.matrix(~ splines::ns(g$year, df = P$trend_df)); Qg <- function(v) { v <- as.numeric(v); as.numeric(v - Xs %*% qr.solve(Xs, v)) }
ann <- function(sh) { v <- en$nino34_anom[match(en$k - sh, en$k)]; m <- tapply(v, en$year, mean); as.numeric(m[as.character(g$year)]) }
XC <- sapply(FIG_C4_SHIFTS, function(sh) { x <- Qg(ann(sh))
  c(atm = stats::cor(Qg(-g$land_resid), x), dgvm = stats::cor(Qg(-g$land_sink), x)) })
win_lab <- sprintf("%d-%d", FIG_C4_WIN[1], FIG_C4_WIN[2])
for (nm in c("atm", "dgvm")) {
  st <- X$c4[X$c4$window == win_lab & X$c4$series == c(atm = "land_source_atm", dgvm = "land_source_dgvm")[[nm]], ]
  j <- which.max(abs(XC[nm, ]))
  cat(sprintf("  panel d gate, %s: peak %+d months r %.3f (driver: %+d, r %.3f)\n", nm, FIG_C4_SHIFTS[j], XC[nm, j], st$peak_shift, st$r_peak))
  if (FIG_C4_SHIFTS[j] != st$peak_shift || abs(XC[nm, j] - st$r_peak) > FIG_GATE_TOL) stop("panel d does not reproduce the driver's C4")
}

# ---- the figure -----------------------------------------------------------------------
grDevices::png(FIG_OUT, width = 1500, height = 1080, res = 130, bg = COL[["surface"]])
graphics::par(mfrow = c(2, 2), oma = c(1.1, 0, 0, 0), mar = c(4.2, 4.6, 3.4, 1.2), mgp = c(2.6, 0.7, 0), col.axis = COL[["ink2"]],
              col.lab = COL[["ink2"]], fg = COL[["muted"]], las = 1, cex.main = 0.98, font.main = 1)
vlines <- function(yl) { graphics::abline(v = c(L0, L_OBS), lty = 3, col = COL[["muted"]])
  graphics::text(c(L0, L_OBS), yl, c(sprintf("canonical %.1f", L0), sprintf("record %g", L_OBS)), pos = 4, cex = 0.72,
                 col = COL[["ink2"]], offset = 0.2) }
hgrid <- function() graphics::abline(h = graphics::axTicks(2), col = COL[["grid"]], lwd = 0.8)
leg <- function(...) graphics::legend(..., bty = "o", bg = grDevices::adjustcolor(COL[["surface"]], 0.88), box.col = NA,
                                      cex = 0.78, text.col = COL[["ink"]])

# a
S <- X$series; tt <- (S$k - 1) / 12
yr <- range(c(S$obs, S$canonical, S$A1)); yr[2] <- yr[2] + 0.45 * diff(yr)
graphics::plot(tt, S$obs, type = "n", ylim = yr, xlab = "", ylab = "detrended growth, ppm/yr",
               main = sprintf("a. CO2 growth, %d-%d: 12-month centred, trend removed (natural spline df %d)", P$window[1], P$window[2], P$trend_df))
hgrid()
graphics::lines(tt, S$canonical, col = COL[["canonical"]], lwd = 1.4)
graphics::lines(tt, S$A1, col = COL[["growth"]], lwd = 1.4)
graphics::lines(tt, S$obs, col = COL[["ink"]], lwd = 1.6)
r_c <- stats::cor(S$canonical, S$obs); r_a <- stats::cor(S$A1, S$obs)
leg("topleft", lwd = c(1.6, 1.4, 1.4), col = COL[c("ink", "canonical", "growth")],
                 legend = c("observed (NOAA MBL global)", sprintf("canonical: lag %.1f mo (r %.2f)", L0, r_c),
                            sprintf("growth-only fit: lag %.1f mo, amplitude x%.2f, gamma_diff %.2f (r %.2f)",
                                    X$A1[["L"]], X$A1[["s"]], X$A1[["d"]], r_a)))

# b
pa <- X$prof[X$prof$arm == "A1" & X$prof$est == "m", ]; pa <- pa[order(pa$L), ]
ll_g <- -(X$n_eff[["m"]] / 2) * log(pa$ssr / min(pa$ssr))
rw <- X$rec_1006; rw <- rw[order(rw$L), ]; ll_w <- rw$lik - max(rw$lik)
c1 <- X$c1[order(X$c1$L), ]; ll_n <- (c1$lik - c1$seas) - max(c1$lik - c1$seas)
YB <- c(-20, 1.5)
graphics::plot(NA, xlim = c(0, 10), ylim = YB, xlab = "land ENSO lag, months after Nino 3.4",
               ylab = "log-likelihood vs each curve's best", main = "b. Where each information source puts the lag")
hgrid(); vlines(YB[2] - 0.3)
graphics::lines(pa$L, pmax(ll_g, YB[1] - 1), col = COL[["growth"]], lwd = 1.6)
graphics::lines(rw$L, pmax(ll_w, YB[1] - 1), col = COL[["canonical"]], lwd = 1.6, type = "o", pch = 16, cex = 0.7)
graphics::lines(c1$L, pmax(ll_n, YB[1] - 1), col = COL[["canonical"]], lwd = 1.6, lty = 2, type = "o", pch = 1, cex = 0.7)
leg("bottomleft", lwd = 1.6, lty = c(1, 1, 2), pch = c(NA, 16, 1),
                 col = COL[c("growth", "canonical", "canonical")],
                 legend = c(sprintf("growth record alone (n_eff %.1f)", X$n_eff[["m"]]), "main objective, every row (10-06)",
                            "main objective without the 4 seasonal rows"))

# c
cs <- X$c2_sum[order(X$c2_sum$L), ]; g2 <- X$g2[order(X$g2$L), ]
yc <- range(c(cs$net, cs$I, -cs$V, g2$net), na.rm = TRUE); yc[1] <- yc[1] - 0.15 * diff(yc); yc[2] <- yc[2] + 0.08 * diff(yc)
graphics::plot(NA, xlim = c(0, 10), ylim = yc, xlab = "land ENSO lag, months after Nino 3.4",
               ylab = "log-likelihood vs no land ENSO", main = "c. The seasonal rows: information, not visibility")
hgrid(); vlines(yc[2] - 0.04 * diff(yc))
graphics::abline(h = 0, col = COL[["muted"]], lwd = 0.8)
graphics::lines(cs$L, cs$I, col = COL[["seasonal"]], lwd = 1.4, lty = 2)
graphics::lines(cs$L, -cs$V, col = COL[["seasonal"]], lwd = 1.4, lty = 3)
graphics::lines(cs$L, cs$net, col = COL[["seasonal"]], lwd = 1.8)
graphics::lines(g2$L, g2$net, col = COL[["growth"]], lwd = 1.8)
leg("bottomleft", lwd = c(1.8, 1.4, 1.4, 1.8), lty = c(1, 2, 3, 1),
                 col = COL[c("seasonal", "seasonal", "seasonal", "growth")],
                 legend = c("4 seasonal rows: what they score (= I - V)", "  information I: residual on the ENSO signature",
                            "  visibility -V: the signature's own size", "growth record, same split (net)"))

# d
yd <- range(XC)
graphics::plot(NA, xlim = range(FIG_C4_SHIFTS), ylim = c(min(0, yd[1]), max(yd) + 0.32),
               xlab = "Nino 3.4 read k months late", ylab = "correlation (detrended, annual)",
               main = sprintf("d. GCB 2025's two land sinks vs ENSO, %s (data only)", win_lab))
hgrid(); graphics::abline(v = L_OBS, lty = 3, col = COL[["muted"]])
for (nm in c("atm", "dgvm")) { cl <- COL[[c(atm = "growth", dgvm = "seasonal")[[nm]]]]
  graphics::lines(FIG_C4_SHIFTS, XC[nm, ], col = cl, lwd = 1.8)
  j <- which.max(XC[nm, ]); graphics::points(FIG_C4_SHIFTS[j], XC[nm, j], pch = 16, col = cl, cex = 1.1)
  graphics::text(FIG_C4_SHIFTS[j], XC[nm, j], sprintf("%+d", FIG_C4_SHIFTS[j]), pos = 3, cex = 0.75, col = COL[["ink"]]) }
sd_a <- stats::sd(Qg(g$land_resid)); sd_d <- stats::sd(Qg(g$land_sink))
leg("topright", lwd = 1.8, col = COL[c("growth", "seasonal")],
                 legend = c(sprintf("land source the ATMOSPHERE implies (sd %.2f GtC/yr)", sd_a),
                            sprintf("DGVM land source, S_LAND: what gcb_land_sink scores (sd %.2f)", sd_d)))
graphics::mtext(sprintf("%s @%s | %s, mode md5 %s | %s", P$driver, P$commit, P$mode, substr(P$mode_md5, 1, 8), FIG_DRIVER),
                side = 1, line = 0.1, adj = 1, cex = 0.55, col = COL[["muted"]], outer = TRUE)
grDevices::dev.off()
cat(sprintf("saved %s\n", FIG_OUT))
