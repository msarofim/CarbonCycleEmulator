suppressMessages({for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)})
source(ccx_path("calibration", "lib_design_gates.R"))
v <- readRDS(Sys.getenv("VFILE")); p <- v$p
sp <- dg_spinup(v)
pf <- ccx_pulse_forcings(sp, c(JOOS_REF_YEAR, JOOS_REF_YEAR + 120), v$bomb_total, v$luc_scale)
sp_ref <- ccx_pulse_ref_state(sp, pf$F_hist)
F_bkg <- ccx_pulse_background(sp_ref, pf$F_fwd, "free")
F_hold <- ccx_hold_forcing(sp_ref, F_bkg); attr(F_hold, "pd_climate") <- "free"
a <- ccx_irf_pd(sp_ref, F_hold, release = 2015); b <- ccx_irf_pd(sp_ref, F_hold, release = 2016)
at <- function(o, h) o$irf[which.min(abs(o$t - h))]
integ <- function(o, h) sum(o$irf[o$t < h]) / 12
for (h in c(20, 50, 100)) cat(sprintf("TH %3d: IRF %.5f vs %.5f (rel +1yr) ; integrated %.3f vs %.3f\n", h, at(a,h), at(b,h), integ(a,h), integ(b,h)))
