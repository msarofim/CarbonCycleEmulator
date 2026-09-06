# =====================================================================
# diag_kz_profile_conduit.R -- DEPTH-DEPENDENT K *WITH* THE CONDUIT.
# DESIGN sec.3.4a's B2, "A and B together", the last untested candidate.
#
# Pre-registered in notes/prereg_2026-09-06b_kz_profile_with_conduit.md.
# Scores E0-E7 in order. Every reference is RECOMPUTED in this run.
#
# THE CLAIM. 09-04k measured K(z) WITHOUT a conduit: counterproductive. 09-06
# measured the conduit WITHOUT K(z): it gets the deep right by starving the
# thermocline (sink 3.07 -> 2.54 GtC/yr, CO2 rows -2200). Each half failed for
# the reason the other exists. HILDA has both: K = 465 + 7096 exp(-(z-75)/253)
# m2/yr WITH the HS/HD boxes (Siegenthaler & Joos 1992, Table 1, as read in
# collect_2026-09-04k). Here `kz` (6356, ent26's thermocline value) is HELD
# and the ONE solved number per arm is the deep floor f = kz_deep_frac, chosen
# so the LS bottom box hits the SOURCED GLODAP target. z_K is DECLARED
# (HILDA's 253 m); a z_K scan is reported WHOLE, never scored by its best.
#
# ⛔ EVERY HS/HD ARM IS "HILDA HS/HD BOXES WITH K(z) AND q ATTACHED AT ..." --
# NOT "HILDA's model". Nothing here is adopted, fitted or refit.
#
# Usage:  Rscript calibration/diag_kz_profile_conduit.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

# ---- named constants (every label below derives from these) ------------
KP_HS_FRAC   <- 0.16; KP_U_HILDA <- 38; KP_TAU_Q <- 538; KP_SST_HS <- 2.0
KP_LUEKER_FLOOR <- 2.0
KP_NEFF      <- LIK_D14C_DEEP_NEFF
KP_SCORED_MIN_DEPTH <- 1500
KP_ZK_PRIMARY <- 253                  # m; HILDA's z0, DECLARED not solved
KP_ZK_SCAN    <- c(253, 500, 1000, 2000)
KP_HILDA_K0   <- 465                  # m2/yr; HILDA's deep floor, for the label only
KP_F_LO <- 1e-3                       # floor of the f scan (log scale)
KP_F_GRID <- 16                       # points in the log-f scan that brackets the roots
KP_E1_F <- c(0.05, 0.30)              # prereg E1
KP_E3_FRAC <- 0.5                     # prereg E3: at least HALVE R2's decadal loss
KP_E4_CO2  <- 500                     # prereg E4: CO2-level rows lose < this
KP_E7_TOL  <- 0.05                    # prereg E7: NH bomb-peak z tolerance
KP_TOL_Z   <- 0.05                    # mean|z| materiality (09-06 prereg sec.1)
KP_DECADAL <- c("d14c_NH", "d14c_SH", "gcb_ocean_sink")
KP_DEEP    <- "d14c_deep_ocean"
KP_CO2LVL  <- c("co2_level_MLO", "co2_level_SPO")
KZ_LO <- CCX_PARAM_TABLE$kz$lo; KZ_HI <- CCX_PARAM_TABLE$kz$hi

v0   <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("\n=== K(z) WITH THE CONDUIT -- mode %s ===\n", CCX_MODE_CANONICAL))
cat(sprintf("  source %s; migrated: %s\n", v0$src,
            if (length(v0$migrated)) paste(v0$migrated, collapse = ", ") else "none"))
cat(sprintf("  kz HELD at %.1f (thermocline); HS: hs_frac %.2f u_hs %g tau_q %g sst_hs %.1f; h_ml %.2f\n",
            v0$p$kz, KP_HS_FRAC, KP_U_HILDA, KP_TAU_Q, KP_SST_HS, v0$p$h_ml))
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2
zint <- cumsum(grid$dz)[seq_len(grid$nl)]
NL   <- grid$nl
SC   <- which(zmid > KP_SCORED_MIN_DEPTH); PIN <- length(zmid); SC_FREE <- setdiff(SC, PIN)
ATT_H <- 1; ATT_B <- NL
cat(sprintf("  interfaces (m): %s\n", paste(round(zint), collapse = " ")))
cat(sprintf("  K/kz at z_K = %g, f = 0.1: %s\n", KP_ZK_PRIMARY,
            paste(sprintf("%.2f", 0.1 + 0.9 * exp(-(zint - grid$h_ml) / KP_ZK_PRIMARY)), collapse = " ")))
cat(sprintf("  GLODAP at scored depths: %s  (se: %s)\n",
            paste(sprintf("%.1f", op$d14[SC]), collapse = " / "),
            paste(sprintf("%.1f", op$d14_sd[SC] / sqrt(KP_NEFF)), collapse = " / ")))

# ---- helpers -----------------------------------------------------------
par_q <- function(attach) {
  p <- v0$p
  p$hs_frac <- KP_HS_FRAC; p$u_hs <- KP_U_HILDA; p$tau_q <- KP_TAU_Q
  p$sst_hs <- KP_SST_HS;   p$q_attach_from <- attach
  p
}
par_inc <- function() { p <- v0$p; p$hs_frac <- 0; p }
deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
prof_of <- function(sp) {
  aux <- sp$aux
  lay <- function(h) { ix <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
                       1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (lay("NH") * aux$a_ls$NH + lay("SH") * aux$a_ls$SH) / (aux$a_ls$NH + aux$a_ls$SH)
}
zs_of <- function(prof) (prof - op$d14) / (op$d14_sd / sqrt(KP_NEFF))
stat_of <- function(prof) { z <- zs_of(prof)
  list(z = z, band = mean(abs(z[SC])), free = mean(abs(z[SC_FREE])), pin = z[PIN]) }
finish <- function(lbl, p, extra = list()) {
  sp <- ccx_spinup(p); pr <- prof_of(sp); d <- sp$diagnostics
  c(list(lbl = lbl, p = p, sp = sp, prof = pr,
         hs = if (!is.null(d$d14c_hs)) d$d14c_hs[["NH"]] else NA_real_,
         hd = if (!is.null(d$d14c_hd)) d$d14c_hd[["NH"]] else NA_real_),
    extra, stat_of(pr))
}
# solve the deep floor f (log scale) so the bottom box hits `target`; kz held
#
# ⚠ THE DEEP IS NOT MONOTONE IN f -- found on the first run of this script
# (2026-09-06b), when an endpoint-sign bracket reported "no f holds the deep"
# for BOTH conduit arms while a probe showed the bottom-attached deep going
# -116 (f 1) -> -187 (f 0.03) -> -156 (f 0.001). As f -> 0 the layer above the
# bottom box is cut off and decays toward -1000 while the bottom itself is held
# near HD - 60 by the conduit, so the deep gets OLD and then YOUNG again and
# there can be TWO roots. The scan below brackets EVERY sign change; the root
# reported is the LARGEST f -- the branch continuous with the uniform model,
# whose intermediate water is alive -- and every other root is printed so a
# second solution is never silent. Post hoc relative to the prereg, which said
# "bisected on log f" and assumed one root; the QUESTION is unchanged.
solve_f <- function(mk, target, zK) {
  g <- function(lf) { p <- mk(); p$kz_zscale <- zK; p$kz_deep_frac <- exp(lf); deep_of(p) - target }
  lfs <- seq(0, log(KP_F_LO), length.out = KP_F_GRID)
  gv  <- vapply(lfs, g, 0)
  sc  <- which(diff(sign(gv)) != 0)
  if (!length(sc))
    return(list(f = NA_real_, f_all = numeric(0), n_roots = 0L, gmin = min(gv),
                why = if (gv[1] > 0) sprintf("deep TOO YOUNG at every f in [%g, 1]; oldest reached %+.1f permil from target", KP_F_LO, min(gv))
                      else "deep TOO OLD at every f"))
  roots <- vapply(sc, function(i) exp(stats::uniroot(g, c(lfs[i], lfs[i + 1]), tol = 1e-6)$root), 0)
  list(f = roots[1], f_all = roots, n_roots = length(roots), gmin = min(gv), why = "")
}
arm_f <- function(lbl, mk, target, zK) {
  s <- solve_f(mk, target, zK)
  if (is.na(s$f)) { cat(sprintf("  %-34s NO f holds the deep: %s\n", lbl, s$why)); return(NULL) }
  p <- mk(); p$kz_zscale <- zK; p$kz_deep_frac <- s$f
  finish(lbl, p, list(f = s$f, zK = zK, k_deep = s$f * p$kz, n_roots = s$n_roots, f_all = s$f_all))
}
# uniform-kz obs-pin solve, as diag_q_attachment_scan.R (the references)
solve_kz <- function(mk, target, kz0) {
  g <- function(lk) { p <- mk(); p$kz <- exp(lk); deep_of(p) - target }
  lo <- log(kz0); hi <- log(kz0)
  n <- 0; while (g(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (g(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (g(lo) > 0 || g(hi) < 0) return(NA_real_)
  exp(stats::uniroot(g, c(lo, hi), tol = 1e-6)$root)
}
verdict <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
tg <- ccx_deep_d14c_target(); if (is.null(tg)) stop("deep target absent")
D_OBS <- tg$target

# =====================================================================
# E0 -- the mechanism is wired, its off state is the model, both cores agree
# =====================================================================
cat("\n=== E0: ABSENCE, PARITY, CONSERVATION, MUTATION ===\n")
p_abs <- par_q(ATT_H); p_abs$kz_deep_frac <- NULL; p_abs$kz_zscale <- NULL
p_one <- par_q(ATT_H); p_one$kz_deep_frac <- 1
s_abs <- ccx_spinup(p_abs); s_one <- ccx_spinup(p_one)
ok_id <- identical(s_abs$y, s_one$y)
cat(sprintf("  absent == f 1 (the 09-05f structure)   : %s   max|d| %.3e\n", ok_id, max(abs(s_abs$y - s_one$y))))
p_half <- par_q(ATT_B); p_half$kz_deep_frac <- 0.5; p_half$kz_zscale <- KP_ZK_PRIMARY
p0 <- ccx_set_enso(p_half, list(gamma_enso = 0)); p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
s_t <- ccx_spinup(p0)
zf <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0), cum_luc = list(NH = 0, SH = 0),
           gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, d13c_foss = -27.6, c14_cosmo = s_t$prod_c14)
dC <- ccx_deriv_fast(s_t$y, 1750, p0, zf, s_t$grid, s_t$aux)
dR <- ccx_deriv(s_t$y, 1750, p0, zf, s_t$grid, s_t$aux)
clo <- sum(abs(dC[, "C"])) / sum(s_t$y[, "C"]); par_abs <- max(abs(dR - dC))
cat(sprintf("  carbon closure at f 0.5, attach %d     : %.3e   %s\n", ATT_B, clo, if (clo < 1e-9) "PASS" else "FAIL"))
cat(sprintf("  R vs C++ single deriv at f 0.5        : %.3e\n", par_abs))
mut <- c(deep_of(p_one), deep_of(local({ p <- p_one; p$kz_deep_frac <- 0.5; p })))
ok_mut <- abs(diff(mut)) > 1
cat(sprintf("  MUTATION f 1 -> 0.5, deep             : %.3f -> %.3f  %s\n", mut[1], mut[2], if (ok_mut) "PASS" else "FAIL"))
e0 <- ok_id && clo < 1e-9 && par_abs < 1e-9 && ok_mut
cat(sprintf("  E0 : %s\n", verdict(e0)))
if (!e0) stop("E0 FAILED -- nothing below this line is interpretable")

# =====================================================================
# THE REFERENCES, recomputed: R0 (ent26), R1/R2 (uniform kz, obs-pinned)
# =====================================================================
cat(sprintf("\n=== REFERENCES (uniform kz), bottom box at %.1f ===\n", D_OBS))
kz_r1 <- solve_kz(par_inc, D_OBS, v0$p$kz)
kz_r2 <- solve_kz(function() par_q(ATT_B), D_OBS, v0$p$kz * 0.3)
REF <- list(
  R0 = finish("R0 incumbent, own kz", par_inc()),
  R1 = finish("R1 incumbent, uniform kz obs-pinned", local({ p <- par_inc(); p$kz <- kz_r1; p })),
  R2 = finish(sprintf("R2 attach %d, uniform kz obs-pinned", ATT_B),
              local({ p <- par_q(ATT_B); p$kz <- kz_r2; p })))
for (r in REF) cat(sprintf("  %-38s kz %7.0f  z1622 %+5.2f  z2268 %+5.2f  free %.3f\n",
                           r$lbl, r$p$kz, r$z[SC_FREE[1]], r$z[SC_FREE[2]], r$free))

# =====================================================================
# THE K(z) ARMS: f solved per (structure, z_K), kz held
# =====================================================================
cat(sprintf("\n=== K(z) ARMS: f solved to hold the bottom box at %.1f; kz held at %.0f ===\n", D_OBS, v0$p$kz))
cat("  arm                                  z_K       f    K_deep      HS       HD    LSml   z1622   z2268   band    free\n")
ARMS <- list()
for (zK in KP_ZK_SCAN) {
  for (a in list(list(k = "H", lbl = sprintf("attach %d (HILDA q)", ATT_H), mk = function() par_q(ATT_H)),
                 list(k = "B", lbl = sprintf("attach %d (bottom q)", ATT_B), mk = function() par_q(ATT_B)),
                 list(k = "N", lbl = "no conduit (32 boxes)", mk = par_inc))) {
    x <- arm_f(sprintf("%s, z_K %g", a$lbl, zK), a$mk, D_OBS, zK)
    if (is.null(x)) next
    ARMS[[sprintf("%s_%g", a$k, zK)]] <- x
    cat(sprintf("  %-34s %5g  %6.3f  %8.0f  %7.1f  %7.1f  %6.1f  %+6.2f  %+6.2f  %6.3f  %6.3f%s\n",
                x$lbl, zK, x$f, x$k_deep, x$hs, x$hd, x$prof[1],
                x$z[SC_FREE[1]], x$z[SC_FREE[2]], x$band, x$free,
                if (x$n_roots > 1) sprintf("   ⚠ %d roots; also f = %s (dead intermediate branch, NOT used)",
                                           x$n_roots, paste(sprintf("%.4f", x$f_all[-1]), collapse = ", ")) else ""))
  }
}
cat(sprintf("  (HILDA's own deep floor K0 = %g m2/yr, for scale; pinned layer z = %+.2f in every arm)\n",
            KP_HILDA_K0, (D_OBS - op$d14[PIN]) / (op$d14_sd[PIN] / sqrt(KP_NEFF))))
getA <- function(k, zK) ARMS[[sprintf("%s_%g", k, zK)]]
H1 <- getA("H", KP_ZK_PRIMARY); B1 <- getA("B", KP_ZK_PRIMARY); N1 <- getA("N", KP_ZK_PRIMARY)

cat("\n  per-layer z at z_K = 253:\n")
cat(sprintf("  %-34s %s\n", "depth (m)", paste(sprintf("%6.0f", zmid), collapse = " ")))
cat(sprintf("  %-34s %s\n", "GLODAP", paste(sprintf("%6.1f", op$d14), collapse = " ")))
for (x in list(N1, H1, B1)) if (!is.null(x)) {
  cat(sprintf("  %-34s %s\n", x$lbl, paste(sprintf("%6.1f", x$prof), collapse = " ")))
  cat(sprintf("  %-34s %s\n", "   z", paste(sprintf("%+6.2f", x$z), collapse = " ")))
}
cat("  ⚠ layers above ~1500 m are bomb-contaminated bottles vs a preindustrial state: shape only.\n")

e1 <- !is.null(H1) && !is.null(B1) && all(c(H1$f, B1$f) >= KP_E1_F[1] & c(H1$f, B1$f) <= KP_E1_F[2])
e2 <- (!is.null(H1) && all(abs(H1$z[SC]) < 1)) || (!is.null(B1) && all(abs(B1$z[SC]) < 1))
e5 <- !is.null(N1) && !(abs(N1$z[SC_FREE[1]]) < 1) &&
      (is.null(H1) || N1$f > H1$f) && (is.null(B1) || N1$f > B1$f)
cat(sprintf("\n  E1  both conduit arms solve with f in [%g, %g]          : %s  (H %.3f, B %.3f)\n",
            KP_E1_F[1], KP_E1_F[2], verdict(e1), if (!is.null(H1)) H1$f else NA, if (!is.null(B1)) B1$f else NA))
cat(sprintf("  E2  ⭐ a conduit arm keeps every scored layer inside |z|<1: %s  (H %s; B %s)\n", verdict(e2),
            if (!is.null(H1)) paste(sprintf("%+.2f", H1$z[SC]), collapse = "/") else "-",
            if (!is.null(B1)) paste(sprintf("%+.2f", B1$z[SC]), collapse = "/") else "-"))
cat(sprintf("  E5  A-alone control: 1622 m NOT inside, and larger f      : %s  (z %+.2f; f %.3f)\n", verdict(e5),
            if (!is.null(N1)) N1$z[SC_FREE[1]] else NA, if (!is.null(N1)) N1$f else NA))

# =====================================================================
# THE TRANSIENT -- matched parameters, no refit
# =====================================================================
cat(sprintf("\n=== TRANSIENT %d-%d, ent26 parameters, f from above ===\n", DG_YEARS[1], DG_YEARS[2]))
mk_v <- function(p) { v <- v0; v$p <- p
  for (n in c("sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c"))
    if (is.null(v[[n]])) v[[n]] <- v0$pm[[n]]
  v }
ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread(); tg7 <- dg_gcb_target(DG_SINK_WIN)
run_t <- function(lbl, p) {
  vv <- mk_v(p); r <- dg_run(vv); st <- dg_streams(r, vv)
  g5 <- dg_gate5(r); g7 <- dg_gate7(r)
  v5 <- dg_gate5_verdict(g5, ob5, sp5); v7 <- dg_gate7_verdict(g7, tg7)
  sst_min <- if (p$hs_frac > 0) KP_SST_HS + min(c(r$F$sst_anom_NH, r$F$sst_anom_SH), na.rm = TRUE) else NA_real_
  list(lbl = lbl, st = st, g7 = g7, v5 = v5, v7 = v7, sst_min = sst_min, deep = r$sp$diagnostics$d14c_bottom_box)
}
TR <- list()
for (nm in names(REF)) TR[[nm]] <- run_t(REF[[nm]]$lbl, REF[[nm]]$p)
for (nm in names(ARMS)) TR[[nm]] <- run_t(ARMS[[nm]]$lbl, ARMS[[nm]]$p)
st0 <- TR$R0$st; nms <- names(st0)
sset <- function(x, s) sum(x$st[intersect(s, nms)])
cat(sprintf("  %-38s %9s %8s %8s %8s %8s %6s %8s  %s\n", "run", "logL", "dTOTAL", "dDECAD", "dCO2lvl", "dDEEP", "sink", "z7/z5NH", "min sst_hs"))
for (nm in names(TR)) { x <- TR[[nm]]
  cat(sprintf("  %-38s %9.2f %+8.1f %+8.1f %+8.1f %+8.2f %6.2f %+5.2f/%+5.2f  %s\n", x$lbl, sum(x$st),
              sum(x$st) - sum(st0), sset(x, KP_DECADAL) - sset(TR$R0, KP_DECADAL),
              sset(x, KP_CO2LVL) - sset(TR$R0, KP_CO2LVL), sset(x, KP_DEEP) - sset(TR$R0, KP_DEEP),
              x$g7$ocean, x$v7$z_ocean, x$v5$z[["nh_t"]],
              if (is.na(x$sst_min)) "-" else sprintf("%.2f%s", x$sst_min,
                if (x$sst_min < KP_LUEKER_FLOOR) " EXTRAP" else "")))
}
cat("\n  per-stream DELTA vs R0 at z_K = 253 (and the two uniform references):\n")
cols <- c("R1", "R2", sprintf("N_%g", KP_ZK_PRIMARY), sprintf("H_%g", KP_ZK_PRIMARY), sprintf("B_%g", KP_ZK_PRIMARY))
cols <- cols[cols %in% names(TR)]
cat(sprintf("  %-22s %9s %s\n", "stream", "R0", paste(sprintf("%9s", cols), collapse = "")))
for (n in nms)
  cat(sprintf("  %-22s %9.2f %s\n", n, st0[[n]],
              paste(sprintf("%+9.2f", vapply(cols, function(cn) TR[[cn]]$st[[n]] - st0[[n]], 0)), collapse = "")))

dec <- vapply(TR, function(x) sset(x, KP_DECADAL) - sset(TR$R0, KP_DECADAL), 0)
co2 <- vapply(TR, function(x) sset(x, KP_CO2LVL) - sset(TR$R0, KP_CO2LVL), 0)
kH <- sprintf("H_%g", KP_ZK_PRIMARY); kB <- sprintf("B_%g", KP_ZK_PRIMARY)
have <- c(kH, kB)[c(kH, kB) %in% names(TR)]
e3  <- length(have) == 2 && all(dec[have] > KP_E3_FRAC * dec[["R2"]])
e3b <- length(have) >= 1 && any(dec[have] > dec[["R1"]])
e4  <- length(have) == 2 && all(abs(vapply(have, function(k) TR[[k]]$v7$z_ocean, 0)) <= 1) &&
       all(co2[have] > -KP_E4_CO2)
z5 <- vapply(TR, function(x) x$v5$z[["nh_t"]], 0)
e7 <- all(abs(z5 - z5[["R0"]]) <= KP_E7_TOL)
cat(sprintf("\n  E3  ⭐⭐ decadal penalty at least halves vs R2 (%.1f): %s  (H %+.1f, B %+.1f; need > %+.1f)\n",
            dec[["R2"]], verdict(e3), dec[kH], dec[kB], KP_E3_FRAC * dec[["R2"]]))
cat(sprintf("  E3b stretch: a conduit arm beats R1 (%+.1f)              : %s\n", dec[["R1"]], verdict(e3b)))
if (length(have) == 2) {
  cat(sprintf("  E4  gate 7 |z| <= 1 and CO2-level loss < %g, both arms : %s  (z7 H %+.2f B %+.2f; CO2 H %+.0f B %+.0f)\n",
              KP_E4_CO2, verdict(e4), TR[[kH]]$v7$z_ocean, TR[[kB]]$v7$z_ocean, co2[kH], co2[kB]))
} else {
  cat(sprintf("  E4  NOT RUN as pre-registered -- conduit arm(s) missing at z_K %g (%s solved)\n",
              KP_ZK_PRIMARY, if (length(have)) paste(have, collapse = ", ") else "none"))
  for (k in have) cat(sprintf("      %s: gate 7 z %+.2f, CO2-level %+.0f\n", k, TR[[k]]$v7$z_ocean, co2[k]))
}
cat(sprintf("  E7  NH bomb-peak z within %.2f of R0 in every arm       : %s  (range %+.2f .. %+.2f)\n",
            KP_E7_TOL, verdict(e7), min(z5), max(z5)))

# ---- E6: the z_K trade-off, reported WHOLE ----------------------------
cat(sprintf("\n=== E6: THE z_K TRADE-OFF (conduit arms; reported whole, never scored by its best) ===\n"))
cat("  z_K    attach     f    K_deep   free   dDECAD   dCO2lvl   dTOTAL   sink   z7\n")
mono <- list()
for (k in c("H", "B")) {
  fr <- c(); dd <- c()
  for (zK in KP_ZK_SCAN) { x <- getA(k, zK); if (is.null(x)) next
    t <- TR[[sprintf("%s_%g", k, zK)]]
    fr <- c(fr, x$free); dd <- c(dd, dec[[sprintf("%s_%g", k, zK)]])
    cat(sprintf("  %5g  %-8s %6.3f  %7.0f  %6.3f  %+7.1f  %+8.1f  %+8.1f  %5.2f  %+5.2f\n", zK,
                if (k == "H") "HILDA" else "bottom", x$f, x$k_deep, x$free, dd[length(dd)],
                co2[[sprintf("%s_%g", k, zK)]], sum(t$st) - sum(st0), t$g7$ocean, t$v7$z_ocean))
  }
  # ⚠ A verdict on fewer than two arms is VACUOUS, not a pass: all(diff(x)) on an
  # empty vector is TRUE. The first run of this script printed PASS on NO arms.
  mono[[k]] <- list(n = length(dd), dec_up = all(diff(dd) >= -1), free_up = all(diff(fr) >= -KP_TOL_Z))
}
e6_ok  <- all(vapply(mono, function(m) m$n >= 2 && m$dec_up && m$free_up, TRUE))
e6_vac <- any(vapply(mono, function(m) m$n < 2, TRUE))
cat(sprintf("  E6  decadal loss shrinks AND free stat grows with z_K, both arms : %s\n",
            if (e6_vac) "VACUOUS (fewer than 2 arms on a branch -- no verdict)" else verdict(e6_ok)))
for (k in names(mono)) cat(sprintf("      %s: %d arms; decadal monotone %s, free monotone %s\n", k,
                                   mono[[k]]$n, mono[[k]]$dec_up, mono[[k]]$free_up))
cat("\n  ⚠ MATCHED-PARAMETER, NOT A REFIT: k_w, h_ml, pump_grad, bomb_total are ent26's 32-box values.\n")
cat("  ⚠ Every HS/HD arm is 'HILDA HS/HD boxes with K(z) and q attached at <layer>'. NOT HILDA's model.\n")
cat("  ⚠ Nothing adopted: kz_deep_frac ships 1, hs_frac ships 0, ent26 untouched.\n")
