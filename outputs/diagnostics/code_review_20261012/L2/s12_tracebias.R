source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2/setup.R")
z <- readRDS(file.path(SCR, "spin_F.rds")); sp <- z$sp
w <- readRDS(file.path(SCR, "y98.rds")); y <- w$y98; F <- w$F; pp <- w$pp
aux <- sp$aux; grid <- sp$grid
sub <- ccx_resolve_substeps("auto", pp, grid); cat("substeps:", sub, "\n")
idx <- which(F$t >= 2023 & F$t < 2025)
oc <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd)))
la <- unlist(lapply(HEMIS, function(h) aux$idx[[h]]$land))
iml <- c(aux$idx$NH$ml, aux$idx$SH$ml)
# integrate 1998 -> 2023 first
for (i in which(F$t >= 1998 & F$t < 2023)) { fi <- ccx_forcing_at(F, i); y <- ccx_step_rk4(y, F$t[i], 1/12, pp, fi, grid, aux, sub) }
for (yr in c(2023, 2024)) {
  ii <- which(floor(F$t) == yr)
  oc0 <- sum(y[oc, "C"]); la0 <- sum(y[la, "C"]); ml0 <- sum(y[iml, "C"])
  tr_oc <- 0; tr_ml <- 0; fine_ml <- 0; nfine <- 0
  for (i in ii) {
    fi <- ccx_forcing_at(F, i)
    k1 <- ccx_deriv(y, F$t[i], pp, fi, grid, aux, record = TRUE)
    fl <- attr(k1, "fluxes"); attr(k1, "fluxes") <- NULL
    v <- ccx_flux_derive(fl$channels, y, aux)
    tr_oc <- tr_oc + v[["ocean_net"]] / 12; tr_ml <- tr_ml + sum(k1[iml, "C"]) / 12
    # fine sampling: 24 sub-intervals per month, evaluate the derivative at each sub-interval start
    yy <- y; tt <- F$t[i]; hstep <- (1/12) / 24
    for (s in 1:24) { kk <- ccx_deriv(yy, tt, pp, fi, grid, aux); fine_ml <- fine_ml + sum(kk[iml, "C"]); nfine <- nfine + 1
      yy <- ccx_step_rk4(yy, tt, hstep, pp, fi, grid, aux, 1L); tt <- tt + hstep }
    y <- ccx_step_rk4(y, F$t[i], 1/12, pp, fi, grid, aux, sub, k1 = k1)
  }
  cat(sprintf("%d: ocean C change %.3f vs trace ocean_net %.3f | ML change %.3f vs trace-mean dML %.3f vs fine-sampled dML %.3f\n",
              yr, sum(y[oc, "C"]) - oc0, tr_oc, sum(y[iml, "C"]) - ml0, tr_ml, fine_ml / nfine))
}
