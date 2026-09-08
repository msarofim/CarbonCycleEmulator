# =====================================================================
# build_hs_surface_targets.R -- GLODAPv2.2023 HIGH-LATITUDE SURFACE targets for
# the HS box (objective change #11, 2026-09-07f, Marcus: "scored rows").
#
# Two rows: the HS box's DIC and d13C at the bottles' epoch. DIC uses the
# SOUTHERN hemisphere only: the model's cold box is one water type per
# hemisphere and the NH high-latitude surface (2069) differs from the SH (2163)
# by ~94 umol/kg, mostly alkalinity/freshwater (choice C8, not represented);
# the Southern Ocean is HILDA's cold box. d13C uses both hemispheres -- their
# medians agree (1.31 / 1.31 in the end-member probe). Same conventions as the
# end-member probe: flag 2, surface <= 50 m, |lat| >= 55.
#
# SIGMA: `sd` = sd(cluster means) / sqrt(n_clusters), clusters = distinct
# (year, 10-deg longitude) cells -- bottles within a cruise leg are not
# independent samples of the box mean. `sd_cluster` = sd(cluster means) is
# carried too: the likelihood's sigma_eff is sqrt(sd^2 + sd_cluster^2), one
# cluster's worth of REPRESENTATION error (a one-box, annual-mean cold surface
# against a zonal band sampled mostly in summer) -- DERIVED, not typed.
# ⚠ That makes the rows WEAK by construction (~2 log-units across the whole
# pump_hs_gcm2 box, 09-07f review); a tighter sigma is a RULING, not a default.
# Usage: Rscript data-raw/build_hs_surface_targets.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HST_LAT_HI <- 55; HST_SURF_M <- 50; HST_FLAG_OK <- 2; HST_LON_BIN <- 10
HST_DIC_CSV <- ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv")
HST_C13_CSV <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
d <- read.csv(HST_DIC_CSV); d <- d[d$tco2f == HST_FLAG_OK & d$depth <= HST_SURF_M & abs(d$lat) >= HST_LAT_HI & d$lat < 0, ]
c13 <- read.csv(HST_C13_CSV); c13 <- c13[c13$c13f == HST_FLAG_OK & c13$depth <= HST_SURF_M & abs(c13$lat) >= HST_LAT_HI, ]
row <- function(df, col) {
  x <- df[[col]]; cl <- paste(df$year, floor(df$lon / HST_LON_BIN))
  cm <- tapply(x, cl, mean)                       # cluster means: the unit of independence
  list(target = stats::median(x), mean = mean(x), sd_w = stats::sd(x), n = length(x),
       n_eff = length(cm), sd_cluster = stats::sd(cm), sd = stats::sd(cm) / sqrt(length(cm)),
       epoch = stats::median(df$year), year_range = range(df$year), hemis = sort(unique(ifelse(df$lat > 0, "NH", "SH"))))
}
out <- list(dic = row(d, "tco2"), d13c = row(c13, "c13"),
            consts = list(lat_hi = HST_LAT_HI, surf_m = HST_SURF_M, flag = HST_FLAG_OK, lon_bin = HST_LON_BIN),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
for (n in c("dic", "d13c")) { r <- out[[n]]
  cat(sprintf("%-5s target %.2f (mean %.2f), bottle sd %.2f, n %d, clusters %d, cluster sd %.2f => sd %.2f; epoch %.0f [%d-%d], hemis %s\n",
              n, r$target, r$mean, r$sd_w, r$n, r$n_eff, r$sd_cluster, r$sd, r$epoch, r$year_range[1], r$year_range[2], paste(r$hemis, collapse = "+"))) }
saveRDS(out, ccx_path("data", "obs_hs_surface.rds")); cat("saved data/obs_hs_surface.rds\n")
