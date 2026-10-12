suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
pf <- ccx_pulse_forcings(sp, c(JOOS_REF_YEAR, JOOS_REF_YEAR + 120), v$bomb_total, v$luc_scale)
cat("F_hist last t:", tail(pf$F_hist$t, 1), " F_fwd first t:", pf$F_fwd$t[1], " F_fwd years:", range(pf$F_fwd$year), "\n")
cat("F_fwd held gmst:", unique(pf$F_fwd$gmst), " = F_hist gmst of Jan 2010:", pf$F_hist$gmst[pf$F_hist$year==2010][1], " annual 2010:", mean(pf$F_hist$gmst[pf$F_hist$year==2010]), "\n")
cat("F_fwd AOD NH first 2 / at label 2025.5 / last:", signif(pf$F_fwd$aod_NH[c(1,2)],3), signif(pf$F_fwd$aod_NH[which.min(abs(pf$F_fwd$t-2025.5))],3), signif(tail(pf$F_fwd$aod_NH,1),3), "\n")
sp_ref <- ccx_pulse_ref_state(sp, pf$F_hist)
F_bkg <- ccx_pulse_background(sp_ref, pf$F_fwd, "free")
F_hold <- ccx_hold_forcing(sp_ref, F_bkg)
cat("free bkg: c_hold (co2_end) =", sp_ref$pd_hist$co2_end, " hold target =", attr(F_hold, "target"),
    " diff ppm =", attr(F_hold, "target") - sp_ref$pd_hist$co2_end, " hold dev =", attr(F_hold,"dev"), "\n")
cat("free bkg gmst yr1..3:", round(unique(F_bkg$gmst)[1:3],4), " hist gmst 2008-2010:", round(tail(sp_ref$pd_hist$gmst,3),4), "\n")
attr(F_hold, "pd_climate") <- "free"
o <- ccx_irf_pd(sp_ref, F_hold)
cat("IRF first row:", o$irf[1], " expected from units:", JOOS_PPM_PER/ccx_const("GtC_PER_PPM"), "\n")
# airborne mass directly from model units at first row
cat("first-row airborne fraction (model GtC/ppm):", (ccx_pd_co2(o$q)[1]-o$base[1])*ccx_const("GtC_PER_PPM")/JOOS_PULSE, "\n")
cat("iter", o$iter, "converged", o$converged, " dT at yr 1,10,50:", round(o$dT[c(1,10,50)],4), "\n")
# pulse placement: NH share of atm carbon at release
iN <- sp_ref$aux$idx$NH$atm
cat("pulse state NH share:", sp_ref$y[iN,"C"]/(sp_ref$y[iN,"C"]+sp_ref$y[sp_ref$aux$idx$SH$atm,"C"]), "\n")
