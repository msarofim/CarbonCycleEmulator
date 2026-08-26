# =====================================================================
# diag_gates_at_landed_modes.R -- DESIGN gates 4 / 7 / 12 / 12b at whatever
# arms are named below.  Report-only.
#
# ARM LIST IS A NAMED CONSTANT (2026-08-25g). It used to be five hard-coded
# paths to the pre-fix `pump_arms` and `ridge_*` directories -- all of which
# are now in calibration/output/quarantine/20260825_seas_isotope_rectification/,
# so the file could not run at all. Editing the calls in place is how a chart
# ends up labelled with the wrong run, so the arms are declared once, up top,
# and every line below derives from them.
#
# THE PRE-FIX MODE IS INCLUDED DELIBERATELY, as the "before" row. Its LOGPOST is
# NOT comparable across the 2026-08-25f objective change and is never printed
# here -- but gates 4/7/12 are PHYSICAL diagnostics of a model run, not
# likelihood values, so comparing them across the fix is exactly right.
#
# Usage:  Rscript calibration/diag_gates_at_landed_modes.R
# =====================================================================
for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f)
ccx_load_cpp()
GATE_ARMS <- c(
  "pre-fix ref (BEFORE)" = "calibration/output/quarantine/20260825_seas_isotope_rectification/pump_arms/mode_fit_pumpN.rds",
  "ref (cycle 2, RUNNING)" = "calibration/output/refit_20260825f_ref/mode_fit_pumpN_progress.rds",
  "from90 FINAL"           = "calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds",
  "pin90 FINAL"            = "calibration/output/refit_20260825f_pin90/mode_fit_pumpN.rds")
GATE_ARMS <- GATE_ARMS[file.exists(vapply(GATE_ARMS, ccx_path, character(1)))]
stopifnot(length(GATE_ARMS) > 0)
DEC <- c(1960,1970,1980,1990,2000,2010,2020); WIN <- c(1959,2024)
g <- as.data.frame(readRDS(ccx_path("data","gcb_budget.rds"))$historical)
g <- g[g$year>=WIN[1] & g$year<=WIN[2],]
afo <- vapply(DEC, function(d){k<-g$year>=d&g$year<=min(d+9,WIN[2]); sum(g$atm_growth[k])/sum((g$fossil+g$luc)[k])},numeric(1))
TR <- unname(coef(lm(afo~DEC))[2])*10
GtC <- ccx_const("GtC_PER_PPM")
ev <- function(file,lab){
  m <- readRDS(file); p <- ccx_default_params()
  for (n in intersect(names(p),CCX_PARAM_NAMES)) p[[n]] <- m$par_mode[[n]]
  p$gamma_enso <- m$par_mode$gamma_enso; p$pump_mode <- m$pump_mode
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical",c(1750,2024),prod_c14=sp$prod_c14,
        bomb_total_kmol=m$par_mode$bomb_total, luc_scale=m$par_mode$luc_scale)
  o <- ccx_run_fast(sp,F)$out
  yrs <- sort(unique(floor(o$t+1e-9))); bnd <- c(yrs,max(yrs)+1L)
  atm <- approx(o$t,(o$co2_NH+o$co2_SH)/2*GtC,xout=bnd,rule=2)$y; gr <- diff(atm)
  el <- ccx_forcing_eluc_annual(F)
  ef <- aggregate(list(e=F$e_foss_NH+F$e_foss_SH),by=list(year=F$year),FUN=mean)
  luc<-el$eluc[match(yrs,el$year)]; fo<-ef$e[match(yrs,ef$year)]
  af<-function(k) sum(gr[k])/sum((fo+luc)[k]); kw<-yrs>=WIN[1]&yrs<=WIN[2]
  dec<-vapply(DEC,function(d) af(yrs>=d&yrs<=min(d+9,WIN[2])&kw),numeric(1))
  stock<-function(v) diff(approx(o$t,v,xout=bnd,rule=2)$y); ks<-yrs>=2015&yrs<=2024
  cat(sprintf("  %-20s AF %.3f  sd %.4f  trend %+.4f  r %+.2f | land %+.2fs ocean %+.2fs | fert_k %6.1f enh420 %.3f\n",
    lab, af(kw), sd(dec), unname(coef(lm(dec~DEC))[2])*10, cor(dec,afo),
    (mean((stock(o$land_C)+luc)[ks])-2.36)/LIK_GCB_LAND_SD,
    (mean(stock(o$ocean_C)[ks])-3.22)/LIK_GCB_OCEAN_SD,
    m$par_mode$fert_k, m$par_mode$beta_max*(420-ccx_const("CO2_PI_PPM"))/(m$par_mode$fert_k+420-ccx_const("CO2_PI_PPM"))))
}
# ---- GATE 12 / 12b, PD100 protocol, same as diag_joos_irf.R -------
irf_at <- function(file){
  m <- readRDS(file); p <- ccx_default_params()
  for (n in intersect(names(p),CCX_PARAM_NAMES)) p[[n]] <- m$par_mode[[n]]
  p$gamma_enso <- m$par_mode$gamma_enso; p$pump_mode <- m$pump_mode
  spin <- ccx_spinup(p)
  Fh <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14=spin$prod_c14,
        bomb_total_kmol=m$par_mode$bomb_total, luc_scale=m$par_mode$luc_scale)
  sp <- spin; sp$y <- ccx_run_fast(spin, Fh)$state
  Ff <- suppressWarnings(ccx_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR+310),
        prod_c14=spin$prod_c14, bomb_total_kmol=0, luc_scale=m$par_mode$luc_scale))
  for (cc in c("e_foss_NH","e_foss_SH","e_luc_NH","e_luc_SH","enso","c14_bomb","c14_nuclear")) Ff[[cc]] <- 0
  Ff$gmst <- Ff$gmst[1]
  o <- ccx_irf(sp, ccx_hold_forcing(sp, Ff))
  o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR); k <- o$t >= 0
  tt <- o$t[k]; vv <- o$irf[k]
  ig <- function(th){kk<-tt<=th; sum(diff(tt[kk])*(head(vv[kk],-1)+tail(vv[kk],-1))/2)}
  list(int=vapply(JOOS_T4$th, ig, numeric(1)), tail=joos_tail_ratio(tt,vv),
       null=joos_tail_null(vv[which.min(abs(tt-100))]), at300=vv[which.min(abs(tt-300))])
}
gate12 <- function(file,lab){
  r <- irf_at(file)
  cat(sprintf("  %-20s TH20 %6.2f%s TH50 %6.2f%s TH100 %6.2f%s | tail %.4f (null %.4f) %s | @300 %.3f\n",
    lab, r$int[1], ifelse(r$int[1]>=JOOS_T4$lo[1],"*"," "), r$int[2], ifelse(r$int[2]>=JOOS_T4$lo[2],"*"," "),
    r$int[3], ifelse(r$int[3]>=JOOS_T4$lo[3],"*"," "), r$tail, r$null,
    ifelse(r$tail>=JOOS_TAIL_BAND[1] & r$tail<=JOOS_TAIL_BAND[2],"IN ","OUT"), r$at300))
}

cat(sprintf("GATE 4 / GATE 7 AT THE LANDED MODES (target trend %+.4f, sd %.4f, land 0, ocean 0)\n", TR, sd(afo)))
for (nm in names(GATE_ARMS)) ev(GATE_ARMS[[nm]], nm)

cat(sprintf("\nGATE 12 / 12b AT THE LANDED MODES  (* = at or above the Joos 5-95%% floor %s; 12b band [%.3f, %.3f])\n",
            paste(JOOS_T4$lo,collapse="/"), JOOS_TAIL_BAND[1], JOOS_TAIL_BAND[2]))
for (nm in names(GATE_ARMS)) gate12(GATE_ARMS[[nm]], nm)
