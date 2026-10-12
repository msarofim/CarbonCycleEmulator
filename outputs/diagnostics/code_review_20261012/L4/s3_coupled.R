suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
cat("spin$tdeep0:", format(sp$tdeep0), " enso_hist null:", is.null(sp$enso_hist), "\n")
# emissions: GCB history to 2024 + vvM after (as app_splice_history does)
h <- as.data.frame(readRDS("data/forcing_emissions_historical.rds"))
s <- ccx_scenario_emissions("vvM")
yy <- 2025:2100
em <- rbind(h[h$year <= 2024, c("year","fossil_GtC","luc_GtC")],
            data.frame(year = yy, fossil_GtC = approx(s$year, s$fossil_GtC, yy, rule=2)$y,
                       luc_GtC = approx(s$year, s$luc_GtC, yy, rule=2)$y))
t0 <- Sys.time()
rc <- ccx_run_coupled(sp, "vvM", c(1750, 2100), emissions = em, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
cat("coupled: iter", rc$iterations, "converged", rc$converged, " time", format(Sys.time()-t0), "\n")
cl <- rc$climate
cat("coupled climate$gmst 1750,1800,1849,1850:", cl$gmst[cl$year %in% c(1750,1800,1849,1850)], "\n")
cat("names(rc):", paste(names(rc), collapse=","), "\n")
# historical-tab equivalent
Fh <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total,
                        luc_scale = v$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
cat("historical build gmst 1750,1849:", Fh$gmst[Fh$year==1750][1], Fh$gmst[Fh$year==1849][1], "\n")
rh <- ccx_run_fast(sp, Fh)
g <- function(o) (o$co2_NH + o$co2_SH)/2
co2c <- tapply(g(rc$out), floor(rc$out$t), mean); co2h <- tapply(g(rh$out), floor(rh$out$t), mean)
for (yy2 in c(1800, 1849, 1900, 1960, 2000, 2024)) cat(yy2, " coupled", round(co2c[as.character(yy2)],4), " hist", round(co2h[as.character(yy2)],4), " diff", round(co2c[as.character(yy2)]-co2h[as.character(yy2)],4), "\n")
# Now: the same coupled run with pre-1850 GMST forced to 0 (patched local copy of the splice)
rc0_fun <- ccx_run_coupled
body_txt <- deparse(body(rc0_fun))
i <- grep("tnew <- spliced", body_txt, fixed = TRUE)
body_txt <- append(body_txt, "      tnew[yrs < min(obs_g$year)] <- FORC_GMST_PRE1850", after = i)
body(rc0_fun) <- parse(text = paste(body_txt, collapse = "\n"))[[1]]
rc0 <- rc0_fun(sp, "vvM", c(1750, 2100), emissions = em, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
co2c0 <- tapply(g(rc0$out), floor(rc0$out$t), mean)
cat("patched pre-1850=0: gmst 1750:", rc0$climate$gmst[1], "\n")
for (yy2 in c(1849, 1900, 2024, 2100)) cat(yy2, " shipped-minus-patched CO2", round(co2c[as.character(yy2)]-co2c0[as.character(yy2)],4), " patched-minus-hist", if (yy2<=2024) round(co2c0[as.character(yy2)]-co2h[as.character(yy2)],4) else NA, "\n")
cat("2100 gmst shipped vs patched:", tail(cl$gmst,1), tail(rc0$climate$gmst,1), "\n")
saveRDS(list(rc=rc, em=em), file.path(dirname(Sys.getenv("VFILE")), "rc.rds"))
