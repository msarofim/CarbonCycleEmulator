suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
v <- readRDS(Sys.getenv("VFILE"))
p <- v$p
yrs <- c(1750, 2025)
for (meth in c("constant","spline")) {
  F <- suppressWarnings(ccx_build_forcing("historical", yrs, prod_c14 = 1, bomb_total_kmol = v$bomb_total,
        luc_scale = v$luc_scale, emis_method = meth, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)))
  e <- as.data.frame(readRDS("data/forcing_emissions_historical.rds"))
  ann <- aggregate(cbind(foss = F$e_foss_NH + F$e_foss_SH, luc = F$e_luc_NH + F$e_luc_SH) ~ year, data = F, FUN = mean)
  m <- match(ann$year, e$year); k <- !is.na(m)
  cat(meth, ": max |annual foss - GCB| =", max(abs(ann$foss[k] - e$fossil_GtC[m[k]])),
      " max |annual luc - luc_scale*GCB| =", max(abs(ann$luc[k] - v$luc_scale * e$luc_GtC[m[k]])), "\n")
  # NH share of fossil per year
  shN <- aggregate(e_foss_NH ~ year, F, mean)$e_foss_NH / ann$foss
  cat("   fossil NH share range:", range(shN, na.rm=TRUE), "\n")
  cat("   cum_luc end vs integral:", tail(F$cum_luc_NH + F$cum_luc_SH, 1), sum(e$luc_GtC[e$year < 1750]*v$luc_scale, na.rm=TRUE) + sum(F$e_luc_NH + F$e_luc_SH)/12, "\n")
  cat("   cum_luc first month:", F$cum_luc_NH[1]+F$cum_luc_SH[1], " = first-month flux/12:", (F$e_luc_NH[1]+F$e_luc_SH[1])/12, "\n")
}
# bomb integral
b <- readRDS("data/forcing_bomb_c14.rds"); cat("bomb shape integral (sum/12):", sum(b$shape_per_yr)/12, " years", range(b$year), "\n")
cat("bomb total placed in F (kmol):", sum(F$c14_bomb)/12/1000, " vs bomb_total", v$bomb_total, "\n")
# GMST in 2025 (held year) monthly
cat("GMST 2024 annual obs:", tail(readRDS("data/forcing_gmst.rds")$gmst_anom,1), "\n")
cat("F gmst 2025 months (spline extrapolation + hold):", round(F$gmst[F$year==2025],3), "\n")
cat("F gmst 2024 months:", round(F$gmst[F$year==2024],3), "\n")
cat("sst NH 2025:", round(F$sst_anom_NH[F$year==2025],3), "\n")
cat("enso first post-record months:", round(F$enso[F$year>=2025][1:6],3), "\n")
cat("aod NH 2024-2025:", signif(F$aod_NH[F$year %in% 2024:2025],3), "\n")
cat("ndep source:", attr(F,"ndep_source"), "\n")
