# =====================================================================
# diag_hilda_hs_thickness.R -- DOES HS AT HILDA'S OWN 75 m CLOSE THE GAP
#   THAT calibration/diag_hilda_boxes.R LEFT OPEN?
#
# Pre-registered in notes/prereg_2026-09-05b_hs_thickness.md. ONE parameter
# moves -- `h_hs` -- and it moves to the value the source uses.
#
# WHY. 2026-09-05's collect note explained P1's shortfall quantitatively: our
# gross air-sea invasion is 1.97x HILDA's and our HS is 1.79x thicker, so the
# residence-to-equilibration ratio is ~1.97x theirs and HS gets about twice as
# far toward atmospheric equilibrium (-80.3 against their -111). Cutting HS to
# 75 m removes the 1.79 and should leave ~1.10x. `k_w` is NOT touched: it is a
# fitted parameter of the low-latitude column, and moving it here would be
# tuning rather than testing.
#
# Usage:  Rscript calibration/diag_hilda_hs_thickness.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

HT_HS_FRAC <- 0.16
HT_U       <- 38            # HILDA Table 1
HT_TAU_Q   <- 538           # HILDA Table 1
HT_SST_HS  <- 2.0
HT_H_ARMS  <- c(0, 100, 75, 50)      # 0 = follow h_ml (the 09-05 build)
HT_H_HILDA <- 75
HT_NEFF    <- LIK_D14C_DEEP_NEFF
HT_SCORED_MIN_DEPTH <- 1500
HT_UPPER_MAX_DEPTH  <- 500
HT_BASE_MEANZ  <- 2.05      # the 09-05 build at h_hs = h_ml
HT_BASE_UPPER  <- 3.98
HT_BASE_HS     <- -80.3
HT_BASE_HD     <- -109.2
HT_SHIM_MEANZ  <- 1.81      # 09-04k2's reduced form
HT_HS_P1B      <- -95       # prereg P1b: HS must fall BELOW this
HT_HD_P2B      <- -125      # prereg P2b: HD must fall BELOW this
HT_LS_OBS      <- c(-40, 20)   # GEOSECS via HILDA Table 2; O1
HT_CROSSOVER_0 <- 1160         # the 09-05 crossover depth, in meters
# A MATERIALITY TOLERANCE, so a no-change arm cannot pass on the fourth decimal.
HT_MEANZ_TOL   <- 0.02
# HILDA's own gas exchange expressed as OUR k_w: their Table 1 gives 15.1 mol
# m-2 yr-1 at 280 ppm and ent26 gives 29.80 at the same pCO2 and temperature, so
# k_w = 1787.8 * 15.1 / 29.80. ⚠ A DIAGNOSTIC PROBE, NOT A PROPOSAL -- k_w is a
# FITTED parameter of the low-latitude column and nothing here moves it there.
HT_KW_HILDA    <- 906

v0   <- dg_vector(CCX_MODE_CANONICAL)
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2
SC   <- which(zmid > HT_SCORED_MIN_DEPTH)
UP   <- which(zmid <= HT_UPPER_MAX_DEPTH)

mkp <- function(h_hs, frac = HT_HS_FRAC) {
  p <- v0$p
  p$hs_frac <- frac; p$u_hs <- HT_U; p$tau_q <- HT_TAU_Q
  p$sst_hs <- HT_SST_HS; p$h_hs <- h_hs
  p
}
deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
prof_of <- function(sp) {
  a <- sp$aux
  l <- function(h) { ix <- c(a$idx[[h]]$ml, a$idx[[h]]$oc)
                     1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (l("NH") * a$a_ls$NH + l("SH") * a$a_ls$SH) / (a$a_ls$NH + a$a_ls$SH)
}

cat("\n===============================================================\n")
cat("diag_hilda_hs_thickness.R -- HS at HILDA's own 75 m\n")
cat(sprintf("mode %s;  u = %g m/yr, tau_q = %g yr, SST_HS = %.1f degC, HS = %g %%\n",
            CCX_MODE_CANONICAL, HT_U, HT_TAU_Q, HT_SST_HS, 100 * HT_HS_FRAC))
cat("===============================================================\n")

# ---- P0b: h_hs = 0 must still be the 2026-09-05 build, bit for bit ----
cat("\n=== P0b: h_hs = 0 IS THE 09-05 BUILD, BIT-EXACT ===\n")
p_new <- mkp(0); p_old <- mkp(0); p_old$h_hs <- NULL   # a list from before today
a <- ccx_spinup(p_new); b <- ccx_spinup(p_old)
cat(sprintf("  h_hs = 0 vs h_hs ABSENT : states identical %s   %s\n",
            identical(a$y, b$y), if (identical(a$y, b$y)) "PASS" else "FAIL"))
cat(sprintf("  and h_hs = h_ml explicit: %s\n",
            identical(ccx_spinup(mkp(grid$h_ml))$y, a$y)))
c0 <- ccx_spinup(mkp(0, frac = 0))
cat(sprintf("  hs_frac = 0 still 32 boxes and bit-exact: %s\n",
            identical(c0$y, ccx_spinup(v0$p)$y)))
if (!identical(a$y, b$y)) stop("P0b FAILED")

d0 <- ccx_spinup(v0$p)$diagnostics$d14c_bottom_box    # the iso-deep target

# ---- iso-deep per thickness ------------------------------------------
cat(sprintf("\n=== ISO-DEEP: kz re-solved per arm to hold the LS bottom box at %.3f ===\n", d0))
solve_kz <- function(h) {
  f <- function(lk) { p <- mkp(h); p$kz <- exp(lk); deep_of(p) - d0 }
  lo <- log(v0$p$kz); hi <- lo
  n <- 0; while (f(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (f(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (f(lo) > 0 || f(hi) < 0) return(NA_real_)
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
res <- list()
for (h in HT_H_ARMS) {
  kz <- solve_kz(h)
  lbl <- if (h == 0) sprintf("h_ml (%.1f m)", grid$h_ml) else sprintf("%g m", h)
  if (is.na(kz)) { cat(sprintf("  %-16s NO kz holds the deep age -- CEILING\n", lbl)); next }
  p <- mkp(h); p$kz <- kz
  sp <- ccx_spinup(p)
  res[[lbl]] <- list(h = if (h == 0) grid$h_ml else h, kz = kz, sp = sp,
                     prof = prof_of(sp), d = sp$diagnostics,
                     ml = 1000 * (sp$y[sp$aux$idx$NH$ml, "C14"] /
                                  sp$y[sp$aux$idx$NH$ml, "C"] - 1))
}
cat(sprintf("\n  %-16s %8s %9s %9s %9s %9s %8s %8s\n",
            "HS thickness", "kz", "HS D14C", "HD D14C", "LS ml", "residence",
            "mean|z|", "upper"))
for (nm in names(res)) {
  r <- res[[nm]]
  z <- (r$prof - op$d14) / (op$d14_sd / sqrt(HT_NEFF))
  r$z <- z; res[[nm]] <- r
  cat(sprintf("  %-16s %8.0f %+9.1f %+9.1f %+9.1f %8.2f yr %8.2f %8.2f\n",
              nm, r$kz, r$d$d14c_hs[["NH"]], r$d$d14c_hd[["NH"]], r$ml,
              r$h / HT_U, mean(abs(z[SC])), mean(abs(z[UP]))))
}

# ---- the crossover ----------------------------------------------------
cat("\n=== P2b: WHERE DOES q's WATER STOP BEING YOUNGER THAN THE INTERIOR? ===\n")
cat("  (HD minus interior; positive = q YOUNGENS that layer, which is the wrong\n")
cat("   direction in the scored band, where the model is already too young)\n\n")
cat(sprintf("  %8s", "depth m")); for (nm in names(res)) cat(sprintf(" %12s", nm)); cat("\n")
cross <- setNames(rep(NA_real_, length(res)), names(res))
for (i in seq_along(zmid)) {
  cat(sprintf("  %8.0f", zmid[i]))
  for (nm in names(res)) {
    dd <- res[[nm]]$d$d14c_hd[["NH"]] - res[[nm]]$prof[i]
    cat(sprintf(" %+12.1f", dd))
    if (dd > 0 && is.na(cross[nm])) cross[nm] <- zmid[i]
  }
  cat("\n")
}
cat(sprintf("\n  %-16s", "crossover")); for (nm in names(res)) cat(sprintf(" %12.0f", cross[nm]))
cat("  m (first YOUNGENED layer)\n")

# ---- scored predictions ----------------------------------------------
cat("\n=== THE SCORED PREDICTIONS (prereg 2026-09-05b) ===\n")
hn <- names(res)[vapply(res, function(r) isTRUE(all.equal(r$h, HT_H_HILDA)), TRUE)]
if (!length(hn)) { cat("  HILDA's 75 m arm did not solve -- nothing below is scored\n") } else {
  r <- res[[hn]]
  cat(sprintf("  P1b -- HS below %g?   HS %+.1f  (09-05 build %+.1f)  -> %s\n",
              HT_HS_P1B, r$d$d14c_hs[["NH"]], HT_BASE_HS,
              if (r$d$d14c_hs[["NH"]] < HT_HS_P1B) "CONFIRMED" else "FALSIFIED"))
  cat(sprintf("        inside HILDA's %+.0f +/- %.0f?  %s\n", -120, 30,
              if (r$d$d14c_hs[["NH"]] >= -150 && r$d$d14c_hs[["NH"]] <= -90)
                "YES" else "NO -- still outside"))
  cat(sprintf("  P2b -- HD below %g, and the crossover DEEPER than %g m?\n",
              HT_HD_P2B, HT_CROSSOVER_0))
  cat(sprintf("        HD %+.1f (09-05 %+.1f) -> %s ; crossover %.0f m -> %s\n",
              r$d$d14c_hd[["NH"]], HT_BASE_HD,
              if (r$d$d14c_hd[["NH"]] < HT_HD_P2B) "CONFIRMED" else "FALSIFIED",
              cross[hn], if (!is.na(cross[hn]) && cross[hn] > HT_CROSSOVER_0)
                "CONFIRMED" else "FALSIFIED"))
  mz <- mean(abs(r$z[SC]))
  # ⛔ GATED ON THE BASELINE ARM RECOMPUTED IN THIS RUN, NOT ON A CONSTANT TYPED
  # FROM THE PREVIOUS RUN'S PRINTOUT. The first version of this line compared
  # against HT_BASE_MEANZ = 2.05, rounded to 2 dp, and a fourth-decimal
  # difference cleared it -- so an arm that changed NOTHING was reported as
  # CONFIRMED. See notes/prereg_2026-09-05c_hs_gas_exchange.md sec.1.
  bn <- names(res)[vapply(res, function(q) isTRUE(all.equal(q$h, grid$h_ml)), TRUE)]
  mz0 <- mean(abs(res[[bn]]$z[SC]))
  cat(sprintf("  P4b -- mean|z| below the h_ml arm's %.4f?  %.4f (delta %+.4f, tol %.2f) -> %s\n",
              mz0, mz, mz - mz0, HT_MEANZ_TOL,
              if (mz < mz0 - HT_MEANZ_TOL) "CONFIRMED" else "FALSIFIED (no material change)"))
  cat(sprintf("        (the reduced form's %.2f was NOT predicted; reached: %s)\n",
              HT_SHIM_MEANZ, if (mz < HT_SHIM_MEANZ) "YES" else "no"))
  uz <- mean(abs(r$z[UP]))
  cat(sprintf("  N1b -- upper <= %d m within 0.5 z of %.2f?  %.2f (delta %+.2f) -> %s\n",
              HT_UPPER_MAX_DEPTH, HT_BASE_UPPER, uz, uz - HT_BASE_UPPER,
              if (uz - HT_BASE_UPPER < 0.5) "PASSES" else "FAILS"))
  cat(sprintf("        ⚠ the LEVEL is a bomb-spike artefact at a preindustrial state;\n"))
  cat(sprintf("          only this DELTA is interpretable (collect 2026-09-05 sec.4)\n"))
  cat(sprintf("  O1  -- LS surface inside GEOSECS %+.0f +/- %.0f?\n", HT_LS_OBS[1], HT_LS_OBS[2]))
  for (nm in names(res))
    cat(sprintf("        %-16s LS ml %+7.1f   %s\n", nm, res[[nm]]$ml,
                if (res[[nm]]$ml >= HT_LS_OBS[1] - HT_LS_OBS[2] &&
                    res[[nm]]$ml <= HT_LS_OBS[1] + HT_LS_OBS[2]) "inside" else "OUTSIDE -- arm EXCLUDED"))
}
cat("\n")
