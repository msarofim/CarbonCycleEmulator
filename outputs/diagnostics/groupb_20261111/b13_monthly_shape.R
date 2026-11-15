# outputs/diagnostics/groupb_20261111/b13_monthly_shape.R (B13, Marcus's question 2026-11-15): what option (b) would show. Measured MLO and the model's NH box, 2000-2024
# (APP_SEAS_WINDOW): each year detrended by its own level + linear trend (ccx_year_harmonic's regression),
# residuals averaged by calendar month -> 12 points; then how much of that 12-point shape one annual wave misses.
setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator/app")
suppressMessages(source("global.R"))
W <- APP_SEAS_WINDOW
setwd("..")
cat(sprintf("b13_monthly_shape.R | commit %s | mode %s md5 %s | app APP_HIST$out (co2_NH box), APP_OBS MLO | no RNG\n",
            ccx_git_stamp(), CCX_MODE_CANONICAL, unname(tools::md5sum(ccx_mode_file()))))
clim <- function(t, v) {
  ok <- is.finite(t) & is.finite(v); t <- t[ok]; v <- v[ok]; yr <- floor(t + 1e-9)
  r <- do.call(rbind, lapply(sort(unique(yr[yr >= W[1] & yr <= W[2]])), function(y) {
    k <- yr == y; if (sum(k) < 12) return(NULL)
    tt <- t[k]; vv <- v[k]; phi <- tt - y
    X <- cbind(1, tt - (y + 0.5), sin(2*pi*phi), cos(2*pi*phi)); cf <- qr.solve(X, vv)
    data.frame(year = y, mo = floor(phi * 12) + 1, res = vv - cf[1] - cf[2] * (tt - (y + 0.5)))
  }))
  m <- tapply(r$res, r$mo, mean)
  ph <- (seq_len(12) - 0.5) / 12
  h1 <- lm(m ~ sin(2*pi*ph) + cos(2*pi*ph)); h2 <- lm(m ~ sin(2*pi*ph) + cos(2*pi*ph) + sin(4*pi*ph) + cos(4*pi*ph))
  list(m = m, years = length(unique(r$year)), p2p = diff(range(m)), amp1 = sqrt(sum(coef(h1)[2:3]^2)),
       amp2 = sqrt(sum(coef(h2)[4:5]^2)), rms_miss = sqrt(mean(resid(h1)^2)), max_miss = max(abs(resid(h1))),
       peak = which.max(m), trough = which.min(m))
}
o <- APP_OBS$co2[APP_OBS$co2$station == "MLO", ]
mo <- clim(o$decimal_date, o$co2_ppm)
md <- clim(APP_HIST$out$t, APP_HIST$out$co2_NH)
cat(sprintf("window %d-%d; MLO %d years, model %d years\n", W[1], W[2], mo$years, md$years))
for (nm in c("MLO", "model")) { x <- if (nm == "MLO") mo else md
  cat(sprintf("%-6s peak-to-peak %.2f ppm | one-wave half-amplitude %.2f | 2nd harmonic %.2f | one wave misses: rms %.2f, max %.2f ppm | peak month %d, trough month %d\n",
              nm, x$p2p, x$amp1, x$amp2, x$rms_miss, x$max_miss, x$peak, x$trough)) }
cat("monthly means (ppm, Jan..Dec)\n MLO  ", sprintf("%+.2f", mo$m), "\n model", sprintf("%+.2f", md$m), "\n")
