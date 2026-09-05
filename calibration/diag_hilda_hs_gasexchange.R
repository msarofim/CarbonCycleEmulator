# =====================================================================
# diag_hilda_hs_gasexchange.R -- IS THE GAS EXCHANGE THE ONLY TERM LEFT
#   IN HS's DEPLETION, AND DOES IT MOVE THE CROSSOVER?
#
# Pre-registered in notes/prereg_2026-09-05c_hs_gas_exchange.md, which also
# RETRACTS the thickness half of collect_2026-09-05's sec.2: in steady state
# HS's isotope ratio is a balance of rates PER UNIT VOLUME, and both the
# HS<->HD exchange (u / h_hs) and the air-sea equilibration (gx / (A h_hs))
# carry the same 1/h_hs, so the thickness cancels EXACTLY. Measured: 0.2 permil
# across a 2.7x change. That leaves the gas exchange as the only candidate.
#
# ⚠ THE k_w ARM IS A DIAGNOSTIC PROBE, NOT A PROPOSAL. k_w = 1787.8 is a FITTED
# parameter of the low-latitude column, carrying the bomb-14C uptake and the
# air-sea disequilibrium the likelihood scores. This arm answers "what would
# HILDA's own gas exchange give?" and nothing else. And note that HS having a
# DIFFERENT k_w from LS would depart from HILDA, who explicitly assume
# g_l = g_h (their Table 1).
#
# Usage:  Rscript calibration/diag_hilda_hs_gasexchange.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

HG_HS_FRAC <- 0.16
HG_U       <- 38
HG_TAU_Q   <- 538
HG_SST_HS  <- 2.0
HG_NEFF    <- LIK_D14C_DEEP_NEFF
HG_SCORED_MIN_DEPTH <- 1500
HG_UPPER_MAX_DEPTH  <- 500
HG_MEANZ_TOL <- 0.02
HG_HS_WINDOW <- c(-126, -96)   # prereg P1c: within 15 permil of HILDA's -111
HG_HD_P2C    <- -125
HG_LS_OBS    <- c(-40, 20)
HG_FLUX_HILDA <- 15.1          # mol m-2 yr-1 at 280 ppm, HILDA Table 1

v0   <- dg_vector(CCX_MODE_CANONICAL)
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2
SC   <- which(zmid > HG_SCORED_MIN_DEPTH)
UP   <- which(zmid <= HG_UPPER_MAX_DEPTH)

# k_w that reproduces HILDA's gross invasion, DERIVED here rather than typed:
# flux = k_w * K0(SST_HS) * rho * 280e-6 mol m-2 yr-1.
K0h    <- carb_constants(HG_SST_HS)$K0
flux_of <- function(kw) kw * K0h * ccx_const("RHO_SEAWATER") * 280e-6
KW_HILDA <- v0$p$k_w * HG_FLUX_HILDA / flux_of(v0$p$k_w)

mkp <- function(kw) {
  p <- v0$p
  p$hs_frac <- HG_HS_FRAC; p$u_hs <- HG_U; p$tau_q <- HG_TAU_Q
  p$sst_hs <- HG_SST_HS; p$k_w <- kw
  p
}
deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
prof_of <- function(sp) {
  a <- sp$aux
  l <- function(h) { ix <- c(a$idx[[h]]$ml, a$idx[[h]]$oc)
                     1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (l("NH") * a$a_ls$NH + l("SH") * a$a_ls$SH) / (a$a_ls$NH + a$a_ls$SH)
}
d0 <- ccx_spinup(v0$p)$diagnostics$d14c_bottom_box

cat("\n===============================================================\n")
cat("diag_hilda_hs_gasexchange.R -- is k_w the whole of HS's shortfall?\n")
cat(sprintf("ent26 k_w = %.1f -> %.2f mol/m2/yr at 280 ppm and %.1f degC\n",
            v0$p$k_w, flux_of(v0$p$k_w), HG_SST_HS))
cat(sprintf("HILDA %.1f +/- 1.2 mol/m2/yr  =>  k_w = %.0f m/yr  (DERIVED, not typed)\n",
            HG_FLUX_HILDA, KW_HILDA))
cat("⚠ A DIAGNOSTIC PROBE. k_w is FITTED; nothing here proposes moving it.\n")
cat("===============================================================\n")

solve_kz <- function(kw) {
  f <- function(lk) { p <- mkp(kw); p$kz <- exp(lk); deep_of(p) - d0 }
  lo <- log(v0$p$kz); hi <- lo
  n <- 0; while (f(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (f(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (f(lo) > 0 || f(hi) < 0) return(NA_real_)
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
arms <- c(`ent26 k_w` = v0$p$k_w, `HILDA k_w` = KW_HILDA,
          `half HILDA` = KW_HILDA / 2)
res <- list()
for (nm in names(arms)) {
  kw <- arms[[nm]]
  kz <- solve_kz(kw)
  if (is.na(kz)) { cat(sprintf("  %-12s NO kz holds the deep age -- CEILING\n", nm)); next }
  p <- mkp(kw); p$kz <- kz
  sp <- ccx_spinup(p)
  pr <- prof_of(sp)
  res[[nm]] <- list(kw = kw, kz = kz, sp = sp, prof = pr, d = sp$diagnostics,
                    z = (pr - op$d14) / (op$d14_sd / sqrt(HG_NEFF)),
                    ml = 1000 * (sp$y[sp$aux$idx$NH$ml, "C14"] /
                                 sp$y[sp$aux$idx$NH$ml, "C"] - 1))
}
cat(sprintf("\n  %-12s %8s %9s %9s %9s %9s %8s %8s\n",
            "arm", "k_w", "flux", "kz", "HS D14C", "HD D14C", "mean|z|", "LS ml"))
for (nm in names(res)) { r <- res[[nm]]
  cat(sprintf("  %-12s %8.0f %9.2f %9.0f %+9.1f %+9.1f %8.3f %+8.1f\n",
              nm, r$kw, flux_of(r$kw), r$kz, r$d$d14c_hs[["NH"]],
              r$d$d14c_hd[["NH"]], mean(abs(r$z[SC])), r$ml)) }

cat("\n=== THE CROSSOVER: HD minus interior (positive = q YOUNGENS the layer) ===\n")
cat(sprintf("  %8s", "depth m")); for (nm in names(res)) cat(sprintf(" %12s", nm)); cat("\n")
cross <- setNames(rep(NA_real_, length(res)), names(res))
for (i in seq_along(zmid)) {
  cat(sprintf("  %8.0f", zmid[i]))
  for (nm in names(res)) { dd <- res[[nm]]$d$d14c_hd[["NH"]] - res[[nm]]$prof[i]
    cat(sprintf(" %+12.1f", dd)); if (dd > 0 && is.na(cross[nm])) cross[nm] <- zmid[i] }
  cat("\n")
}
cat(sprintf("\n  %-8s", "crossover")); for (nm in names(res)) cat(sprintf(" %12.0f", cross[nm]))
cat("  m\n")

cat("\n=== THE SCORED PREDICTIONS (prereg 2026-09-05c) ===\n")
b <- res[["ent26 k_w"]]; h <- res[["HILDA k_w"]]
cat(sprintf("  P1c -- HS in [%g, %g]?  HS %+.1f (ent26 k_w: %+.1f) -> %s\n",
            HG_HS_WINDOW[1], HG_HS_WINDOW[2], h$d$d14c_hs[["NH"]], b$d$d14c_hs[["NH"]],
            if (h$d$d14c_hs[["NH"]] >= HG_HS_WINDOW[1] &&
                h$d$d14c_hs[["NH"]] <= HG_HS_WINDOW[2]) "CONFIRMED" else "FALSIFIED"))
cat(sprintf("  P2c -- HD below %g AND the crossover deeper than 1160 m?\n", HG_HD_P2C))
cat(sprintf("        HD %+.1f -> %s ; crossover %.0f m -> %s\n",
            h$d$d14c_hd[["NH"]],
            if (h$d$d14c_hd[["NH"]] < HG_HD_P2C) "CONFIRMED" else "FALSIFIED",
            cross[["HILDA k_w"]],
            if (!is.na(cross[["HILDA k_w"]]) && cross[["HILDA k_w"]] > 1160)
              "CONFIRMED" else "FALSIFIED"))
mzb <- mean(abs(b$z[SC])); mzh <- mean(abs(h$z[SC]))
cat(sprintf("  P4c -- mean|z| below %.4f by more than %.2f?  %.4f (delta %+.4f) -> %s\n",
            mzb, HG_MEANZ_TOL, mzh, mzh - mzb,
            if (mzh < mzb - HG_MEANZ_TOL) "CONFIRMED" else "FALSIFIED"))
cat(sprintf("  O1  -- LS surface inside GEOSECS %+.0f +/- %.0f?\n", HG_LS_OBS[1], HG_LS_OBS[2]))
for (nm in names(res))
  cat(sprintf("        %-12s LS ml %+7.1f   %s\n", nm, res[[nm]]$ml,
              if (res[[nm]]$ml >= HG_LS_OBS[1]-HG_LS_OBS[2] &&
                  res[[nm]]$ml <= HG_LS_OBS[1]+HG_LS_OBS[2]) "inside" else "OUTSIDE -- EXCLUDED"))
cat("\n⚠ The `half HILDA` arm is an EXTRAPOLATION well outside any fitted or\n")
cat("  published gas exchange, present only to show the direction and slope.\n\n")
