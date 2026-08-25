for (f in list.files("R", pattern="[.]R$", full.names=TRUE)) source(f)
ccx_load_cpp()
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
cat(sprintf("GATE 4 / GATE 7 AT THE LANDED MODES (target trend %+.4f, sd %.4f, land 0, ocean 0)\n", TR, sd(afo)))
ev("calibration/output/pump_arms/mode_fit_pumpN.rds","reference mode")
ev("calibration/output/ridge_free_from90/mode_fit_pumpN.rds","free arm (LANDED)")
ev("calibration/output/ridge_pin120/mode_fit_pumpN.rds","pin120 (LANDED)")
