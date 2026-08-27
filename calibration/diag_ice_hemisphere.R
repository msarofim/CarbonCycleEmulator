# =====================================================================
# diag_ice_hemisphere.R -- THE ICE TERM IS SCORED AGAINST THE WRONG BOX
#
# R/likelihood.R scores the Law Dome ice CO2 record against the model's NH box,
# on a comment that reads "SH-cored but globally well mixed pre-1900". Law Dome
# is at 66.7 S. The well-mixed argument is sound for the 87 pre-1900 rows and
# progressively less so after that: 159 of 255 scored rows are post-1900 and 52
# are post-1958, where the model's own NH-SH gradient is no longer negligible.
#
# diag_co2_level_swing.R:66 already uses co2_SH, with the comment "Law Dome is
# ANTARCTIC: the like-for-like model series is the SH box." So the OBJECTIVE and
# the DIAGNOSTIC that produced the swing table disagree about which model series
# the same observations should be compared to, and the two have been quoted
# interchangeably across handoffs 21c and 21d.
#
# This measures what the disagreement is worth, in three currencies:
#   GATE 1 -- the model's NH-SH gradient over the years the ice rows occupy.
#   GATE 2 -- the ice term's log-likelihood under each box.
#   GATE 3 -- the era table of handoff sec.4 GATE D under each box, i.e. how
#             much of the "9 ppm swing" is this choice rather than the model.
#
# CHANGING THIS CHANGES THE OBJECTIVE. Nothing fitted under the NH scoring is
# comparable across it. This script measures the size of the change so that
# decision is made on a number.
#
# Usage:  Rscript calibration/diag_ice_hemisphere.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

IH_MODE_FILE <- ccx_mode_file()
IH_YEARS     <- c(1750, 2024)
IH_ERAS      <- list(c(1750, 1800), c(1800, 1850), c(1850, 1900), c(1900, 1940),
                     c(1940, 1960), c(1958, 1980), c(1980, 2000), c(2000, 2025))
IH_GRAD_WIN  <- list(c(1850, 1900), c(1900, 1940), c(1940, 1958), c(1958, 1997))

md <- readRDS(IH_MODE_FILE); pm <- md$par_mode
p <- ccx_default_params()
for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
p$pump_mode <- md$pump_mode
sp <- ccx_spinup(p)
F  <- ccx_build_forcing("historical", IH_YEARS, prod_c14 = sp$prod_c14,
                        bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
o  <- ccx_run_fast(sp, F)$out

ann <- function(col) { v <- tapply(o[[col]], floor(o$t + 1e-9), mean)
                       list(t = as.numeric(names(v)), v = as.numeric(v)) }
NH <- ann("co2_NH"); SH <- ann("co2_SH")
at <- function(s, yr) stats::approx(s$t, s$v, xout = yr)$y

ice <- as.data.frame(ccx_prepare_obs()$ice)
cat(sprintf("mode %s   n_ice %d over %d-%d\n",
            basename(IH_MODE_FILE), nrow(ice), min(ice$year), max(ice$year)))
cat(sprintf("  rows pre-1900 %d   post-1900 %d   post-1958 %d\n\n",
            sum(ice$year < 1900), sum(ice$year >= 1900), sum(ice$year >= 1958)))

# ---- GATE 1: the model's own NH-SH gradient where the ice rows are ----
cat("GATE 1 -- model NH-SH gradient over the scored ice years, ppm\n")
for (w in IH_GRAD_WIN) {
  k <- ice$year >= w[1] & ice$year < w[2]
  if (!any(k)) next
  g <- at(NH, ice$year[k]) - at(SH, ice$year[k])
  cat(sprintf("  %d-%d  n=%3d   mean %+6.3f   max %+6.3f\n",
              w[1], w[2], sum(k), mean(g), max(g)))
}
g24 <- at(NH, 2015:2024) - at(SH, 2015:2024)
cat(sprintf("  (2015-2024, for scale)      mean %+6.3f\n\n", mean(g24)))

# ---- GATE 2: what the ice term is worth under each box ----------------
# Reproduces R/likelihood.R's own comparison EXACTLY: approx() on the raw
# sub-annual series with rule = 2, not on the annual means used for the tables
# above. rule = 2 is why the 15 pre-1750 rows score at all.
lik_interp <- function(col, tt) stats::approx(o$t, o[[col]], xout = tt, rule = 2)$y
ll <- function(col) sum(stats::dnorm(ice$CO2ppm, lik_interp(col, ice$year),
                                     ice$sd, log = TRUE))
ll_nh <- ll("co2_NH"); ll_sh <- ll("co2_SH")
cat("GATE 2 -- ice-term log-likelihood by model box\n")
cat(sprintf("  co2_NH (SHIPPED)  %10.1f\n", ll_nh))
cat(sprintf("  co2_SH (correct)  %10.1f\n", ll_sh))
cat(sprintf("  SH - NH           %+10.1f log-units\n\n", ll_sh - ll_nh))

# ---- GATE 3: how much of the swing is the hemisphere choice ----------
cat("GATE 3 -- era table (model - ice), ppm, under each box\n")
cat(sprintf("  %-11s %5s %9s %9s %8s\n", "era", "n", "vs NH", "vs SH", "diff"))
res <- list(NH = c(), SH = c())
for (e in IH_ERAS) {
  k <- ice$year >= e[1] & ice$year < e[2]
  if (!any(k)) next
  rn <- mean(at(NH, ice$year[k]) - ice$CO2ppm[k])
  rs <- mean(at(SH, ice$year[k]) - ice$CO2ppm[k])
  res$NH <- c(res$NH, rn); res$SH <- c(res$SH, rs)
  cat(sprintf("  %d-%-6d %5d %+9.2f %+9.2f %+8.2f\n", e[1], e[2], sum(k), rn, rs, rs - rn))
}
sw <- function(r) max(r) - min(r)
cat(sprintf("\n  swing (max-min era)      %9.2f %9.2f %+8.2f\n", sw(res$NH), sw(res$SH),
            sw(res$SH) - sw(res$NH)))
cat(sprintf("  => the hemisphere choice inflates the swing by %.2f ppm (%.0f %% of %.2f)\n",
            sw(res$NH) - sw(res$SH), 100 * (sw(res$NH) - sw(res$SH)) / sw(res$NH), sw(res$NH)))
