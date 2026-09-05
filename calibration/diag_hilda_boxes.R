# =====================================================================
# diag_hilda_boxes.R -- DOES THE HILDA HIGH-LATITUDE STRUCTURE (HS + HD),
#   BUILT AS REAL BOXES, FIX THE INTERMEDIATE-DEPTH D14C PROFILE?
#
# Pre-registered in notes/prereg_2026-09-05_hilda_boxes.md. Scores P0-P5 and
# the negative control N1, in that order, and stops at the first P0 failure.
#
# ⚠ THIS IS NOT A SHIM. 2026-09-04k tested the conduit's GEOMETRY by wrapping
# ccx_deriv_fast(); this runs the STRUCTURE -- two extra boxes per hemisphere,
# in both cores, with their own air-sea exchange at their own temperature. The
# switch is `hs_frac`, and 0 means the boxes are ABSENT: 32 boxes, not 36.
#
# THE CONTROL IS ISO-DEEP, as in 2026-09-04k: `kz` is re-solved per arm to hold
# the LS bottom box at the incumbent's D14C, so the question is purely whether
# the intermediate profile improves AT THE SAME DEEP AGE. An iso-sink control
# would have no power -- 2026-09-04i measured that the ocean sink cannot
# discriminate ocean structures at all.
#
# Usage:  Rscript calibration/diag_hilda_boxes.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

# ---- named constants: every label below derives from these ------------
HB_HS_FRAC  <- 0.16          # HILDA: 16 % of the global ocean surface
HB_TAU_Q    <- 538           # HILDA Table 1: q^-1 = 538 +/- 510 yr
HB_SST_HS   <- 2.0           # degC; the carbonate tables' floor (see prereg C7)
HB_U        <- c(0, 9.5, 19, 38, 76)      # m/yr over the HS area; HILDA 38 +/- 17
HB_U_HILDA  <- 38
HB_TAU_Q_ARMS <- c(28, 268, 538, 1048)    # HILDA's own +/- 510, plus a midpoint
HB_NEFF     <- LIK_D14C_DEEP_NEFF
HB_SCORED_MIN_DEPTH <- 1500  # bomb addition <= 4.5 permil below this
HB_UPPER_MAX_DEPTH  <- 500   # N1's control band: the layers that already MATCH
HB_HS_TARGET <- c(-120, 30)  # HILDA Table 2, from GEOSECS: HS = -120 +/- 30
HB_HD_HILDA  <- -136         # HILDA Table 2, THEIR MODEL's value, not an obs
HB_SHIM_MEANZ <- 1.81        # 2026-09-04k2's reduced form, the thing to beat
HB_INCUMBENT_MEANZ <- 2.55

v0   <- dg_vector(CCX_MODE_CANONICAL)
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2

par_hs <- function(u, tau_q = HB_TAU_Q, frac = HB_HS_FRAC) {
  p <- v0$p
  p$hs_frac <- frac; p$u_hs <- u; p$tau_q <- tau_q; p$sst_hs <- HB_SST_HS
  p
}
deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
prof_of <- function(sp) {
  aux <- sp$aux
  lay <- function(h) { ix <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
                       1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (lay("NH") * aux$a_ls$NH + lay("SH") * aux$a_ls$SH) / (aux$a_ls$NH + aux$a_ls$SH)
}
zs_of <- function(prof) (prof - op$d14) / (op$d14_sd / sqrt(HB_NEFF))
SC <- which(zmid > HB_SCORED_MIN_DEPTH)
UP <- which(zmid <= HB_UPPER_MAX_DEPTH)

cat("\n===============================================================\n")
cat("diag_hilda_boxes.R -- the HILDA HS/HD structure, scored\n")
cat(sprintf("mode %s;  HS = %.0f %% of each hemisphere at %.1f degC;  tau_q = %g yr\n",
            CCX_MODE_CANONICAL, 100 * HB_HS_FRAC, HB_SST_HS, HB_TAU_Q))
cat("===============================================================\n")

# ---- P0: THE NO-OP, CONSERVATION AND PARITY, scored FIRST -------------
cat("\n=== P0: NO-OP, CONSERVATION, PARITY ===\n")
sp_off <- ccx_spinup(v0$p)
d0 <- sp_off$diagnostics$d14c_bottom_box
p_off <- par_hs(HB_U_HILDA, frac = 0)      # every HL parameter set, structure OFF
sp_off2 <- ccx_spinup(p_off)
ok_noop <- identical(sp_off$y, sp_off2$y)
cat(sprintf("  hs_frac = 0 is a NO-OP   : %d boxes, states identical %s   %s\n",
            nrow(sp_off2$y), ok_noop, if (ok_noop) "PASS (bit-exact)" else "FAIL"))

sp_on <- ccx_spinup(par_hs(HB_U_HILDA))
ok_bite <- abs(sp_on$diagnostics$d14c_bottom_box - d0) > 1e-6
cat(sprintf("  hs_frac = %.2f BITES      : %d boxes, deep %.6f vs %.6f   %s\n",
            HB_HS_FRAC, nrow(sp_on$y), sp_on$diagnostics$d14c_bottom_box, d0,
            if (ok_bite) "PASS" else "FAIL -- the structure is INERT"))

# conservation and parity at the fixed point, with NOTHING external
zf <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
           gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0,
           c14_cosmo = sp_on$prod_c14)
p0 <- ccx_set_enso(par_hs(HB_U_HILDA), list(gamma_enso = 0))
p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
dC <- ccx_deriv_fast(sp_on$y, 1750, p0, zf, sp_on$grid, sp_on$aux)
dR <- ccx_deriv(sp_on$y, 1750, p0, zf, sp_on$grid, sp_on$aux)
clo <- sum(abs(dC[, "C"])) / sum(sp_on$y[, "C"])
cat(sprintf("  carbon closure           : sum|dC/dt| / total C = %.3e   %s\n",
            clo, if (clo < 1e-9) "PASS" else "FAIL"))
par_abs <- max(abs(dR - dC))
cat(sprintf("  R vs C++ single deriv    : max abs %.3e  (structure OFF: %.3e)\n",
            par_abs, max(abs(
              ccx_deriv(sp_off$y, 1750, p0, zf, sp_off$grid, sp_off$aux) -
              ccx_deriv_fast(sp_off$y, 1750, p0, zf, sp_off$grid, sp_off$aux)))))
if (!ok_noop || !ok_bite || clo >= 1e-9)
  stop("P0 FAILED -- nothing below this line is interpretable")

# ---- iso-deep solve ---------------------------------------------------
cat(sprintf("\n=== ISO-DEEP: kz re-solved per arm to hold the LS bottom box at %.3f ===\n", d0))
solve_kz <- function(mk) {
  f <- function(lk) { p <- mk(); p$kz <- exp(lk); deep_of(p) - d0 }
  lo <- log(v0$p$kz); hi <- log(v0$p$kz)
  n <- 0; while (f(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (f(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (f(lo) > 0 || f(hi) < 0) return(NA_real_)
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
arm <- function(lbl, mk) {
  kz <- solve_kz(mk)
  if (is.na(kz)) { cat(sprintf("  %-22s NO kz holds the deep age -- CEILING\n", lbl))
                   return(NULL) }
  p <- mk(); p$kz <- kz
  sp <- ccx_spinup(p)
  list(lbl = lbl, kz = kz, sp = sp, prof = prof_of(sp),
       d = sp$diagnostics)
}

res <- list()
res[["incumbent"]] <- local({
  sp <- sp_off
  list(lbl = "incumbent (no HS)", kz = v0$p$kz, sp = sp, prof = prof_of(sp),
       d = sp$diagnostics)
})
for (u in HB_U) {
  lbl <- sprintf("u = %-5g", u)
  a <- arm(lbl, function() par_hs(u))
  if (!is.null(a)) res[[lbl]] <- a
}
for (tq in setdiff(HB_TAU_Q_ARMS, HB_TAU_Q)) {
  lbl <- sprintf("u = %g, tau_q = %g", HB_U_HILDA, tq)
  a <- arm(lbl, function() par_hs(HB_U_HILDA, tau_q = tq))
  if (!is.null(a)) res[[lbl]] <- a
}

cat(sprintf("\n  %-22s %10s %10s %9s %9s %9s\n",
            "arm", "kz", "kz/kz(0)", "HS D14C", "HD D14C", "LS ml"))
for (nm in names(res)) {
  r <- res[[nm]]
  hs <- r$d$d14c_hs[["NH"]]; hd <- r$d$d14c_hd[["NH"]]
  ml <- 1000 * (r$sp$y[r$sp$aux$idx$NH$ml, "C14"] / r$sp$y[r$sp$aux$idx$NH$ml, "C"] - 1)
  cat(sprintf("  %-22s %10.0f %10.3f %9s %9s %+9.1f\n", r$lbl, r$kz,
              r$kz / res[["incumbent"]]$kz,
              if (is.na(hs)) "--" else sprintf("%+.1f", hs),
              if (is.na(hd)) "--" else sprintf("%+.1f", hd), ml))
}

# ---- the profile ------------------------------------------------------
cat(sprintf("\n=== PREINDUSTRIAL D14C z AGAINST GLODAP (scored band > %d m) ===\n\n",
            HB_SCORED_MIN_DEPTH))
zmat <- lapply(res, function(r) zs_of(r$prof))
cat(sprintf("  %8s", "depth m")); for (nm in names(res)) cat(sprintf(" %11s", substr(nm, 1, 11)))
cat("  scored\n")
for (i in seq_along(zmid)) {
  cat(sprintf("  %8.0f", zmid[i]))
  for (nm in names(res)) cat(sprintf(" %+11.2f", zmat[[nm]][i]))
  cat(sprintf("  %s\n", if (zmid[i] > HB_SCORED_MIN_DEPTH) "YES" else "no"))
}
mz <- vapply(zmat, function(z) mean(abs(z[SC])), 0)
uz <- vapply(zmat, function(z) mean(abs(z[UP])), 0)
cat(sprintf("\n  %-8s", "mean|z|")); for (nm in names(res)) cat(sprintf(" %11.2f", mz[[nm]])); cat("   scored band\n")
cat(sprintf("  %-8s", "upper"));   for (nm in names(res)) cat(sprintf(" %11.2f", uz[[nm]])); cat(sprintf("   <= %d m (N1 control)\n", HB_UPPER_MAX_DEPTH))

# ---- the scored predictions -------------------------------------------
cat("\n=== THE SCORED PREDICTIONS (prereg 2026-09-05) ===\n")
hil <- res[[sprintf("u = %-5g", HB_U_HILDA)]]
p2_ok <- !is.null(hil)
cat(sprintf("  P2 -- does a kz EXIST at HILDA's own u = %g?  %s\n", HB_U_HILDA,
            if (p2_ok) sprintf("YES, kz = %.0f  -> CONFIRMED", hil$kz) else
              "NO -- FALSIFIED; the 09-04k2 ceiling was not the missing box"))
if (p2_ok) {
  hs <- hil$d$d14c_hs[["NH"]]
  ml <- 1000 * (hil$sp$y[hil$sp$aux$idx$NH$ml, "C14"] / hil$sp$y[hil$sp$aux$idx$NH$ml, "C"] - 1)
  cat(sprintf("  P1 -- HS under-equilibrates?  HS %+.1f vs LS ml %+.1f = %.1f permil split\n",
              hs, ml, ml - hs))
  cat(sprintf("        HILDA/GEOSECS HS %+.0f +/- %.0f; prereg window [-160, -80] -> %s\n",
              HB_HS_TARGET[1], HB_HS_TARGET[2],
              if (hs >= -160 && hs <= -80) "CONFIRMED" else "OUTSIDE THE WINDOW"))
  cat(sprintf("        prereg falsifier is a split < 20 permil -> %s\n",
              if ((ml - hs) < 20) "FALSIFIED" else "survives"))
  cat(sprintf("  P3 -- kz below the shim's 3177?  kz = %.0f (%.3fx incumbent) -> %s\n",
              hil$kz, hil$kz / res[["incumbent"]]$kz,
              if (hil$kz < 3177) "CONFIRMED" else "FALSIFIED"))
  cat(sprintf("  P4 -- mean|z| below the shim's %.2f?  %.2f (incumbent %.2f) -> %s\n",
              HB_SHIM_MEANZ, mz[[hil$lbl]], HB_INCUMBENT_MEANZ,
              if (mz[[hil$lbl]] < HB_SHIM_MEANZ) "CONFIRMED" else "FALSIFIED"))
  cat(sprintf("  P5 -- HD near HILDA's %+.0f?  HD %+.1f  (model-to-model, REPORTED not gated)\n",
              HB_HD_HILDA, hil$d$d14c_hd[["NH"]]))
  cat(sprintf("        falsifier is HD WARMER than the LS mixed layer -> %s\n",
              if (hil$d$d14c_hd[["NH"]] > ml) "FALSIFIED" else "survives"))
  cat(sprintf("  N1 -- upper <= %d m degrades by < 1 z?  %.2f vs %.2f (delta %+.2f) -> %s\n",
              HB_UPPER_MAX_DEPTH, uz[[hil$lbl]], uz[["incumbent"]],
              uz[[hil$lbl]] - uz[["incumbent"]],
              if (abs(uz[[hil$lbl]] - uz[["incumbent"]]) < 1) "PASSES" else "FAILS"))
  cat(sprintf("  unscored peak at %.0f m: %+.2f -> %+.2f  (shim reached +1.98)\n",
              zmid[which.max(abs(zmat[["incumbent"]]))],
              zmat[["incumbent"]][which.max(abs(zmat[["incumbent"]]))],
              zmat[[hil$lbl]][which.max(abs(zmat[["incumbent"]]))]))
}
cat("\n")
