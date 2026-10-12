source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp; F <- z$F
F <- ccx_fill_prod_c14(F, sp)
pp <- sp$params
F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(pp), sp$enso_hist)
F[["mix_g"]] <- if (ccx_mix_on(pp)) as.numeric(ccx_mix_g_series(F$gmst, F$t, pp, sp$tdeep0)) else NULL
# run the historical record to get a realistic transient state at 1998
r <- ccx_run(sp, F[F$t < 1998, ], substeps = "auto")
y98 <- r$state
L <- ccx_const("LAMBDA_C14")
chk <- function(y, i, label, zero_src = TRUE) {
  fi <- ccx_forcing_at(F, i)
  if (zero_src) { fi$e_foss <- list(NH=0,SH=0); fi$e_luc <- list(NH=0,SH=0); fi$c14_bomb <- 0; fi$c14_nuclear <- 0; fi$c14_cosmo <- 0 }
  d0 <- ccx_deriv(y, F$t[i], pp, fi, sp$grid, sp$aux, record = FALSE)
  d1 <- ccx_deriv(y, F$t[i], pp, fi, sp$grid, sp$aux, record = TRUE)
  fl <- attr(d1, "fluxes"); attr(d1, "fluxes") <- NULL
  cat(sprintf("\n[%s] t=%.4f enso=%.3f land_enso=%.3f mix_g=%.5f aod=%.4g ndep=%.4g\n", label, F$t[i], fi$enso, fi$land_enso, if (is.null(fi$mix_g)) NA else fi$mix_g, fi$aod_NH, fi$ndep_NH))
  cat(sprintf("  sum dC = %.3e  (max|dC| %.3e)\n", sum(d0[,"C"]), max(abs(d0[,"C"]))))
  cat(sprintf("  sum dC13 = %.3e  (max|dC13| %.3e)\n", sum(d0[,"C13"]), max(abs(d0[,"C13"]))))
  cat(sprintf("  sum dC14 + lambda*sum C14 = %.3e  (max|dC14| %.3e)\n", sum(d0[,"C14"]) + L*sum(y[,"C14"]), max(abs(d0[,"C14"]))))
  cat(sprintf("  record vs non-record max abs diff: %.3e\n", max(abs(d1 - d0))))
  cat(sprintf("  boxnet vs dC max abs diff: %.3e\n", max(abs(fl$boxnet - d0[,"C"]))))
  invisible(list(d0=d0, fl=fl, fi=fi))
}
i0 <- 1
a <- chk(sp$y, i0, "spun-up, 1750, sources zeroed")
i97 <- which(F$t >= 1997.95)[1]
b <- chk(y98, i97, "1998 state, El Nino 1997.9, sources zeroed")
# a strong La Nina month
iLN <- which.min(F$enso)
c1 <- chk(y98, iLN, "1998 state, min enso month, sources zeroed")
saveRDS(list(y98 = y98, F = F, pp = pp), file.path(SCR, "y98.rds"))
# with sources on: sum dC should equal e_foss
fi <- ccx_forcing_at(F, i97)
d <- ccx_deriv(y98, F$t[i97], pp, fi, sp$grid, sp$aux)
cat(sprintf("\nsources on: sum dC = %.10f, e_foss = %.10f, diff %.3e\n", sum(d[,"C"]), fi$e_foss$NH + fi$e_foss$SH, sum(d[,"C"]) - fi$e_foss$NH - fi$e_foss$SH))
