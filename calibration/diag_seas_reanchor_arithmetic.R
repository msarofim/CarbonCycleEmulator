for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
md <- readRDS(ccx_mode_file())
r  <- readRDS("calibration/output/seas_T_amp_q10_ridge_q10_partial.rds")
rr <- Filter(function(x) x$tier == "land", r$res); rr <- rr[order(sapply(rr, function(x) x$amp))]
CCX_PARAM_TABLE$h_ml$lo <- md$hml_bound[1]; CCX_PARAM_TABLE$h_ml$hi <- md$hml_bound[2]
CCX_PARAM_TABLE$h_ml$prior <- local({b<-md$hml_bound; function(x) dunif(x,b[1],b[2],log=TRUE)})

# DAMPING as sec.2 proposes it, applied to BOTH land amplitude priors -- the
# bracket ends scale, so the lognormal's center scales and its WIDTH does not.
DAMP <- md$par_mode$seas_T_amp_NH * log(md$par_mode$q10) / log(2.0) /
        ccx_const("SEAS_T_AMP_NH_OBS_LO")
mk <- function(damp) {
  tb <- CCX_PARAM_TABLE
  for (h in c("NH","SH")) {
    lo <- damp*ccx_const(sprintf("SEAS_T_AMP_%s_OBS_LO",h))
    hi <- damp*ccx_const(sprintf("SEAS_T_AMP_%s_OBS_HI",h))
    tb[[paste0("seas_T_amp_",h)]]$prior <-
      local({a<-lo;b<-hi; function(x) dlnorm(x, log(sqrt(a*b)), log(b/a)/2, log=TRUE)})
  }
  tb
}
lpri <- function(pv, tb) sum(vapply(CCX_PARAM_NAMES, function(n)
  tb[[n]]$prior(pv[[n]]) + .log_jac(.to_unc(pv[[n]], tb[[n]]), tb[[n]]), numeric(1)))
full <- function(x, tb) {
  pv <- md$par_mode
  for (n in names(x$par)) pv[[n]] <- x$par[[n]]
  pv[["q10"]] <- x$amp
  x$loglik_bystream + lpri(pv, tb)
}
TB0 <- CCX_PARAM_TABLE; TB1 <- mk(DAMP)
cat(sprintf("damping implied by the mode's product at the literature q10: %.4f\n", DAMP))
cat(sprintf("re-anchored prior centres: NH %.3f K (was %.3f), SH %.3f K (was %.3f)\n\n",
  DAMP*sqrt(ccx_const("SEAS_T_AMP_NH_OBS_LO")*ccx_const("SEAS_T_AMP_NH_OBS_HI")),
  sqrt(ccx_const("SEAS_T_AMP_NH_OBS_LO")*ccx_const("SEAS_T_AMP_NH_OBS_HI")),
  DAMP*sqrt(ccx_const("SEAS_T_AMP_SH_OBS_LO")*ccx_const("SEAS_T_AMP_SH_OBS_HI")),
  sqrt(ccx_const("SEAS_T_AMP_SH_OBS_LO")*ccx_const("SEAS_T_AMP_SH_OBS_HI"))))
a <- vapply(rr, full, numeric(1), tb = TB0); b <- vapply(rr, full, numeric(1), tb = TB1)
cat(sprintf("%7s %9s %9s %12s %10s %12s %10s\n","q10","A_T","T_amp_SH",
            "logpost NOW","d","logpost DAMPED","d"))
for (i in seq_along(rr)) cat(sprintf("%7.4f %9.3f %9.4f %12.2f %10.2f %12.2f %10.2f%s\n",
  rr[[i]]$amp, rr[[i]]$A_T, rr[[i]]$par$seas_T_amp_SH, a[i], a[i]-a[1], b[i], b[i]-b[1],
  if (isTRUE(all.equal(rr[[i]]$amp, 2.0))) "  <- LITERATURE q10" else ""))
cat(sprintf("\nunder the CURRENT priors  q10=2.0 loses by %.1f log-units\n", a[1]-a[length(a)]))
cat(sprintf("under the DAMPED  priors  q10=2.0 %s by %.1f log-units\n",
            if (b[length(b)] > b[1]) "WINS" else "loses", abs(b[length(b)]-b[1])))
