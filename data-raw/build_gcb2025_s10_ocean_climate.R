#!/usr/bin/env Rscript
# =====================================================================
# build_gcb2025_s10_ocean_climate.R -- the GOBM ensemble's ocean-sink CLIMATE EFFECT, 1959-2024, DIGITISED from
# GCB 2025's Supplement Fig. S10 (global panel, the solid red "A-C, clim" ensemble-mean line). 2026-10-06.
#
# WHY. Marcus 2026-10-06: "Do the H2 diagnostic and test." The test (CHANGELOG 10-04 p: "the time shape against
# GCB Fig. S10") needs GCB's climate-effect TIME SERIES, and S10 is the only place GCB 2025 publishes it: the
# data files hold sim A only. So it is read off the figure, and the read is GATED on reproducing the one number
# GCB states in text for the same quantity: -0.20 GtC/yr over 2015-24 (GCB 2025 p. 3242; the ocean diagnostic's
# OC_GCB).
#
# INPUT: data-raw/downloads/gcb2025_supplement.pdf (download_data.R "gcb2025_supplement"; MANIFEST.csv), md5
# 93a7e289fb61849d31a0163ddbec8f45 -- the file calibration/diag_ocean_climate_gobm.R's protocol table was read
# from (OC_SUPP_MD5). This script NEVER downloads: an absent or different file is a stop.
# THE FIGURE: one embedded 720 x 504 JPEG on PDF page 70 (printed p. 69). Four panels; the GLOBAL panel is the
# top-left. Units GtC/yr, uptake POSITIVE; red = A - C (the climate effect), blue = C - B, grey = sim A; solid =
# the ensemble mean, dotted = the individual GOBMs.
#
# METHOD (base R; poppler's `pdfimages` writes the image as PPM, which base R reads):
#   1. CALIBRATION from the panel's own light-grey gridlines, DETECTED (a row or column of the panel interior
#      that is mostly gridline grey): y majors at 3 / 2 / 1 GtC/yr, x gridlines at 1960 / 1970 / 2010 / 2020 (the
#      others are crossed by the data lines and not detected). A straight-line fit through each set; the
#      residuals are printed and gated at half a pixel.
#   2. THE LINE: the solid mean line is DARK red, ~(150, 20, 20) after JPEG; the dotted per-model lines are pink
#      (G and B above ~0x80) and are excluded by colour, not position. Per pixel column, the redness-weighted mean
#      row of the line's pixels.
#   3. ANNUAL VALUES at each year's x (ggplot joins annual points), linearly between pixel columns.
#   4. THE GATE: the 2015-24 mean must reproduce GCB's -0.20 within S10_VALID_TOL (one pixel, 1/39 GtC/yr, plus
#      the published number's rounding, 0.005). The read's resolution is that pixel: ~0.026 GtC/yr.
# OUTPUT: data/gcb2025_s10_ocean_climate_global.rds (year, climate_effect_GtC, provenance attributes) and a QC
# overlay, outputs/diagnostics/gcb2025_s10_digitised_check.png. No RNG.
# Usage: Rscript data-raw/build_gcb2025_s10_ocean_climate.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants -------------------------------------------------------------------
S10_DRIVER    <- "data-raw/build_gcb2025_s10_ocean_climate.R"
S10_PDF       <- file.path("data-raw", "downloads", "gcb2025_supplement.pdf")
S10_MD5       <- "93a7e289fb61849d31a0163ddbec8f45"
S10_URL       <- "https://essd.copernicus.org/articles/18/3211/2026/essd-18-3211-2026-supplement.pdf"
S10_PAGE      <- 70L                                   # PDF page (printed p. 69)
S10_DIM       <- c(w = 720L, h = 504L)
S10_PANEL     <- list(rows = 62:250, cols = 70:365)    # the global panel's plotting area (below its strip)
S10_Y_MAJORS  <- c(`3` = 102, `2` = 141, `1` = 180)    # expected gridline rows (detected, then checked)
S10_X_LINES   <- c(`1960` = 81, `1970` = 125, `2010` = 299, `2020` = 343)
S10_GRID_TOL  <- 1                                     # px: a detected gridline must sit within 1 px of its row/col
S10_FIT_TOL   <- 0.5                                   # px: the calibration fit's largest residual
S10_RED       <- c(r_min = 100, gb_max = 80, contrast = 60)   # the solid line's colour (dotted lines are pink)
S10_YEARS     <- 1959:2024
S10_VALID     <- c(mean = -0.20, from = 2015, to = 2024)      # GCB 2025 p. 3242 (OC_GCB in diag_ocean_climate_gobm.R)
S10_VALID_TOL <- 1 / 39 + 0.005                        # one pixel + the published value's rounding
S10_END_PX    <- 2                                     # px a line END may fall short of its endpoint year (line caps +
                                                       # JPEG: measured 1.2 px at both ends); the end year takes the
                                                       # nearest drawn column's value
S10_OUT       <- file.path("data", "gcb2025_s10_ocean_climate_global.rds")
S10_PNG       <- file.path("outputs", "diagnostics", "gcb2025_s10_digitised_check.png")

stopifnot(file.exists(S10_PDF) || {
  stop("missing ", S10_PDF, ". Fetch ", S10_URL, " (download_data.R entry 'gcb2025_supplement'); this script never downloads.")
})
md5 <- unname(tools::md5sum(S10_PDF))
if (!identical(md5, S10_MD5)) stop("the supplement's md5 is ", md5, ", not ", S10_MD5, ": a different file; stop.")
cat(sprintf("%s @%s | %s (md5 %s) page %d\n", S10_DRIVER, ccx_git_stamp(exclude = S10_OUT), S10_PDF, md5, S10_PAGE))

# ---- 0. the image ---------------------------------------------------------------------------------------
td <- tempfile("s10_"); dir.create(td)
rc <- system2("pdfimages", c("-f", S10_PAGE, "-l", S10_PAGE, shQuote(S10_PDF), shQuote(file.path(td, "img"))))
ppm <- list.files(td, pattern = "\\.ppm$", full.names = TRUE)
if (rc != 0L || length(ppm) != 1L) stop("pdfimages did not give exactly one image on page ", S10_PAGE)
read_ppm <- function(f) {
  con <- file(f, "rb"); on.exit(close(con))
  hdr <- character(0)
  while (length(hdr) < 4L) { l <- readLines(con, n = 1L); if (!startsWith(l, "#")) hdr <- c(hdr, strsplit(trimws(l), "\\s+")[[1]]) }
  stopifnot(hdr[1] == "P6", hdr[4] == "255")
  w <- as.integer(hdr[2]); h <- as.integer(hdr[3])
  a <- array(as.integer(readBin(con, "raw", n = w * h * 3L)), dim = c(3L, w, h))
  list(R = t(a[1, , ]), G = t(a[2, , ]), B = t(a[3, , ]), w = w, h = h)     # matrices indexed [row, col]
}
im <- read_ppm(ppm)
if (!identical(c(im$w, im$h), unname(S10_DIM))) stop("unexpected image size ", im$w, " x ", im$h)

# ---- 1. calibration from the detected gridlines -------------------------------------------------------------
pr <- S10_PANEL$rows; pc <- S10_PANEL$cols
grey <- abs(im$R - im$G) < 6 & abs(im$G - im$B) < 6 & im$R > 200 & im$R < 245
row_hits <- which(rowSums(grey[pr, pc]) > 0.65 * length(pc)) + min(pr) - 1L
col_hits <- which(colSums(grey[pr, pc]) > 0.6 * length(pr)) + min(pc) - 1L
match_lines <- function(expected, hits, what) vapply(names(expected), function(k) {
  d <- abs(hits - expected[[k]]); if (!length(d) || min(d) > S10_GRID_TOL) stop("the ", what, " gridline for ", k, " was not detected near ", expected[[k]])
  hits[which.min(d)] }, 0)
y_rows <- match_lines(S10_Y_MAJORS, row_hits, "y"); x_cols <- match_lines(S10_X_LINES, col_hits, "x")
fy <- stats::lm(v ~ row, data.frame(v = as.numeric(names(y_rows)), row = y_rows))
fx <- stats::lm(col ~ yr, data.frame(col = x_cols, yr = as.numeric(names(x_cols))))
res_y <- max(abs(stats::residuals(stats::lm(row ~ v, data.frame(v = as.numeric(names(y_rows)), row = y_rows)))))
res_x <- max(abs(stats::residuals(fx)))
cat(sprintf("calibration: y gridlines %s -> %.4f GtC/yr per px, 0 at row %.2f (max residual %.2f px); x gridlines %s -> %.4f px per year, 1960 at col %.2f (max residual %.2f px)\n",
            paste(sprintf("%s@%g", names(y_rows), y_rows), collapse = " "), -stats::coef(fy)[["row"]],
            -stats::coef(fy)[["(Intercept)"]] / stats::coef(fy)[["row"]], res_y,
            paste(sprintf("%s@%g", names(x_cols), x_cols), collapse = " "), stats::coef(fx)[["yr"]],
            stats::predict(fx, data.frame(yr = 1960)), res_x))
if (res_y > S10_FIT_TOL || res_x > S10_FIT_TOL) stop("the gridlines are not evenly spaced to half a pixel: calibration refused")
val_of_row <- function(r) stats::predict(fy, data.frame(row = r))
col_of_year <- function(y) stats::predict(fx, data.frame(yr = y))

# ---- 2. the solid line, column by column ------------------------------------------------------------------
redness <- im$R - pmax(im$G, im$B)
line <- im$R >= S10_RED[["r_min"]] & im$G <= S10_RED[["gb_max"]] & im$B <= S10_RED[["gb_max"]] & redness >= S10_RED[["contrast"]]
ycol <- rep(NA_real_, im$w)
for (cc in pc) { rr <- pr[line[pr, cc]]; if (length(rr)) ycol[cc] <- stats::weighted.mean(rr, redness[rr, cc]) }
have <- which(is.finite(ycol))
cat(sprintf("the line: %d of %d panel columns carry it (cols %d-%d = years %.2f-%.2f)\n", length(have), length(pc),
            min(have), max(have), (min(have) - stats::coef(fx)[[1]]) / stats::coef(fx)[[2]],
            (max(have) - stats::coef(fx)[[1]]) / stats::coef(fx)[[2]]))

# ---- 3. annual values ---------------------------------------------------------------------------------------
xc <- col_of_year(S10_YEARS)
if (min(xc) < min(have) - S10_END_PX || max(xc) > max(have) + S10_END_PX)
  stop("the line does not span ", min(S10_YEARS), "-", max(S10_YEARS), " (cols ", round(min(xc), 1), "-", round(max(xc), 1), ")")
yr_row <- stats::approx(have, ycol[have], xout = xc, rule = 2)$y
out <- data.frame(year = S10_YEARS, climate_effect_GtC = round(as.numeric(val_of_row(yr_row)), 4))

# ---- 4. the gate ---------------------------------------------------------------------------------------------
w <- out$year >= S10_VALID[["from"]] & out$year <= S10_VALID[["to"]]
m <- mean(out$climate_effect_GtC[w])
ok <- abs(m - S10_VALID[["mean"]]) <= S10_VALID_TOL
cat(sprintf("GATE: the digitised %g-%g mean %.3f vs GCB's stated %.2f, |d| %.3f vs tolerance %.3f -> %s\n", S10_VALID[["from"]],
            S10_VALID[["to"]], m, S10_VALID[["mean"]], abs(m - S10_VALID[["mean"]]), S10_VALID_TOL, if (ok) "PASS" else "FAIL"))
if (!ok) stop("the digitised series does not reproduce GCB's stated 2015-24 value; not saved")
dec <- tapply(out$climate_effect_GtC, pmin(floor(out$year / 10) * 10, 2010), mean)
cat("decade means (2010s = 2010-2024):", paste(sprintf("%ss %+.3f", names(dec), dec), collapse = ", "), "\n")

# ---- QC overlay -------------------------------------------------------------------------------------------
grDevices::png(S10_PNG, width = 2 * length(pc), height = 2 * length(pr))
op <- graphics::par(mar = c(0, 0, 0, 0)); on.exit(graphics::par(op), add = TRUE)
ras <- grDevices::rgb(im$R[pr, pc], im$G[pr, pc], im$B[pr, pc], maxColorValue = 255)
graphics::plot.new(); graphics::plot.window(xlim = range(pc), ylim = rev(range(pr)), xaxs = "i", yaxs = "i")
graphics::rasterImage(as.raster(matrix(ras, nrow = length(pr))), min(pc), max(pr), max(pc), min(pr), interpolate = FALSE)
graphics::points(xc, yr_row, pch = 3, col = "cyan3", cex = 1.2, lwd = 1.5)
grDevices::dev.off()

attr(out, "provenance") <- list(
  driver = S10_DRIVER, commit = ccx_git_stamp(exclude = S10_OUT), source = S10_URL, pdf_md5 = md5, page = S10_PAGE,
  figure = "GCB 2025 Supplement Fig. S10, GLOBAL panel, solid red 'A-C, clim' (ensemble mean of the GOBMs)",
  units = "GtC/yr, uptake positive (the ocean sink's climate effect; negative = warming reduces uptake)",
  calibration = list(y_rows = y_rows, x_cols = x_cols, gtc_per_px = -stats::coef(fy)[["row"]],
                     px_per_year = stats::coef(fx)[["yr"]], max_resid_px = c(y = res_y, x = res_x)),
  line_colour = S10_RED, validation = list(target = S10_VALID, digitised = m, tol = S10_VALID_TOL),
  ends = sprintf("the drawn line spans cols %d-%d against endpoints %.1f-%.1f; the end years take the nearest drawn column's value (<= %g px)",
                 min(have), max(have), min(xc), max(xc), S10_END_PX),
  resolution = "one pixel = ~0.026 GtC/yr; annual values interpolated between pixel columns (4.37 px per year)",
  date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none")
saveRDS(out, S10_OUT)
cat(sprintf("saved %s (%d years) and %s\n", S10_OUT, nrow(out), S10_PNG))
