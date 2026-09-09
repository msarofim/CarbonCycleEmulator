# =====================================================================
# GRAVEN vs HUA over the bomb window (2026-09-09; the isotopic-data audit).
#
# WHY. For 1950-1980 the repo had ONE atmospheric D14C product (Hua et al.
# 2022, data/obs_d14c_zonal.rds), and it is BOTH the scoring target
# (d14c_NH / d14c_SH) AND the sub-annual shape input to the bomb source
# function. This puts a second, independently compiled product beside it.
#
# ⚠ NOT AN INDEPENDENT OBSERVING SYSTEM. Graven's compilation draws on the same
# underlying station and tree-ring measurements. It tests COMPILATION, ZONAL
# AGGREGATION, BASELINE CONVENTION and VERSION DRIFT -- not sampling error.
# ⚠ VINTAGE: input4MIPs CMIP7/C4MIP ImperialCollege-3-0 v20250502 (1700-2023),
# the SUCCESSOR to the CMIP6 v1.2.0 (1850-2015) of Graven et al. 2017.
#
# LIKE-FOR-LIKE. Graven is an ANNUAL MEAN on calendar-year bounds; Hua is
# monthly. Both are reduced to area-weighted hemispheres and then to a plain
# CALENDAR-YEAR MEAN -- not the harmonic mid-year intercept, which estimates a
# different quantity. Graven's 4 bands are equal-area within a hemisphere
# (edges -90/-30/0/30/90 => 0.5 each), so its hemispheric mean is the simple
# two-band average; Hua's zones are weighted by ccx_zone_weights().
# [[like_for_like_forcing]]
#
# Usage: Rscript calibration/diag_graven_vs_hua.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressMessages(library(ncdf4))

GVH_NC     <- ccx_path("data-raw", "downloads",
  "Delta14co2_input4MIPs_atmosphericState_C4MIP_ImperialCollege-3-0_gz_1700-2023.nc")
GVH_WINDOW <- c(1950, 1980)      # the bomb window this audit is about
GVH_REF    <- c(1955, 1959)      # a pre-peak reference for a debiased shape comparison
GVH_OUT    <- ccx_path("outputs", "diagnostics",
                       sprintf("graven_vs_hua_%s.rds", format(Sys.Date(), "%Y%m%d")))

# ---- Graven: 4 equal-area bands -> hemispheres ----
nc <- nc_open(GVH_NC)
lb <- ncvar_get(nc, "lat_bnds"); g <- ncvar_get(nc, "Delta14co2"); nc_close(nc)
gyr <- 1700:2023
w   <- abs(sin(lb[2, ] * pi/180) - sin(lb[1, ] * pi/180))    # band area weights
sh_b <- which(lb[2, ] <= 0); nh_b <- which(lb[1, ] >= 0)
stopifnot(length(sh_b) == 2, length(nh_b) == 2,
          isTRUE(all.equal(sum(w[sh_b]), sum(w[nh_b]))))      # hemispheres equal area
G <- data.frame(year = gyr,
  NH = as.numeric(w[nh_b] %*% g[nh_b, ]) / sum(w[nh_b]),
  SH = as.numeric(w[sh_b] %*% g[sh_b, ]) / sum(w[sh_b]))

# ---- Hua: zonal monthly -> hemispheres -> calendar-year mean ----
d  <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
zw <- ccx_zone_weights()
hemi_series <- function(wts) {
  s <- d[d$zone %in% names(wts), c("decimal_date", "zone", "d14c")]
  wide <- reshape(s, idvar = "decimal_date", timevar = "zone", direction = "wide")
  zn <- sub("d14c\\.", "", names(wide)[-1]); M <- as.matrix(wide[, -1, drop = FALSE])
  ww <- wts[zn] / sum(wts[zn]); ok <- complete.cases(M)
  data.frame(t = wide$decimal_date[ok], x = as.numeric(M[ok, , drop = FALSE] %*% ww))
}
ann <- function(s) { y <- floor(s$t); a <- tapply(s$x, y, mean)
                     data.frame(year = as.integer(names(a)), x = as.numeric(a)) }
H <- merge(setNames(ann(hemi_series(zw$NH)), c("year","NH")),
           setNames(ann(hemi_series(zw$SH)), c("year","SH")), by = "year")

M <- merge(G, H, by = "year", suffixes = c("_grv", "_hua"))
M <- M[M$year >= GVH_WINDOW[1] & M$year <= GVH_WINDOW[2], ]
for (h in c("NH", "SH")) M[[paste0("d_", h)]] <- M[[paste0(h,"_grv")]] - M[[paste0(h,"_hua")]]

cat(sprintf("\n=== GRAVEN (IC-3-0 v20250502) vs HUA 2022, %d-%d, area-weighted hemispheres ===\n",
            GVH_WINDOW[1], GVH_WINDOW[2]))
cat("  year   NH_grv   NH_hua     diff |   SH_grv   SH_hua     diff\n")
for (i in seq_len(nrow(M))) if (M$year[i] %in% c(1955:1958, 1961:1968, 1972, 1976, 1980))
  cat(sprintf("  %4d %8.1f %8.1f %8.1f | %8.1f %8.1f %8.1f\n", M$year[i],
      M$NH_grv[i], M$NH_hua[i], M$d_NH[i], M$SH_grv[i], M$SH_hua[i], M$d_SH[i]))

hua_sd <- median(d$d14c_sd[d$decimal_date >= GVH_WINDOW[1] & d$decimal_date <= GVH_WINDOW[2]],
                 na.rm = TRUE)
cat(sprintf("\n  Hua's own median zonal sd in the window: %.1f permil\n", hua_sd))
for (h in c("NH", "SH")) {
  dd <- M[[paste0("d_", h)]]
  cat(sprintf("  %s: mean %+7.2f  rms %6.2f  max|d| %6.2f at %d  (= %.1f x Hua's sd)\n",
      h, mean(dd), sqrt(mean(dd^2)), max(abs(dd)), M$year[which.max(abs(dd))],
      max(abs(dd)) / hua_sd))
}
# peak and gradient -- the two things the model is actually scored on
for (nm in c("grv","hua")) {
  i <- which.max(M[[paste0("NH_",nm)]]); j <- which.max(M[[paste0("SH_",nm)]])
  cat(sprintf("  %-5s NH peak %6.1f @ %d ; SH peak %6.1f @ %d\n", nm,
      M[[paste0("NH_",nm)]][i], M$year[i], M[[paste0("SH_",nm)]][j], M$year[j]))
}
gr <- data.frame(year = M$year, grv = M$NH_grv - M$SH_grv, hua = M$NH_hua - M$SH_hua)
pk <- gr[which.max(gr$hua), ]
cat(sprintf("  NH-SH gradient at its Hua maximum (%d): Graven %.1f vs Hua %.1f (%+.1f)\n",
            pk$year, pk$grv, pk$hua, pk$grv - pk$hua))

# debiased shape: remove each product's own pre-peak reference level
rr <- M$year >= GVH_REF[1] & M$year <= GVH_REF[2]
cat(sprintf("\n  debiased on %d-%d (each product minus its own reference mean):\n",
            GVH_REF[1], GVH_REF[2]))
for (h in c("NH","SH")) {
  a <- M[[paste0(h,"_grv")]] - mean(M[[paste0(h,"_grv")]][rr])
  b <- M[[paste0(h,"_hua")]] - mean(M[[paste0(h,"_hua")]][rr])
  cat(sprintf("    %s: rms(diff) %6.2f permil, corr %.5f\n", h, sqrt(mean((a-b)^2)), cor(a,b)))
}
saveRDS(list(merged = M, gradient = gr, hua_sd = hua_sd, window = GVH_WINDOW,
             vintage = "input4MIPs CMIP7/C4MIP ImperialCollege-3-0 v20250502 (1700-2023)",
             date = Sys.time()), GVH_OUT)
cat(sprintf("\nsaved %s\n", GVH_OUT))
