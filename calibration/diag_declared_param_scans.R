# =====================================================================
# diag_declared_param_scans.R -- THE CAVEAT NUMBERS for the three parameters
# DECLARED at HILDA's values (2026-09-06; prereg_2026-09-07 sec.3, and
# notes/caveats_declared_parameters.md: "reported WHOLE and never scored by
# its best").
#
# The arm: HILDA's attachment (q_attach_from 1), K(z) at HILDA's z_K 253,
# hs_asx_frac 0.8 (the bomb-supported value), f solved so the bottom box hits
# GLODAP's -175.3 (09-06c sec.7 gives f 0.049, K_deep 309 -- reproduced here
# as a gate on the reconstruction). Then each declared parameter is moved
# one at a time, halved and doubled (z_K also to 150 and 500 as the design
# says), in TWO readings:
#   (a) everything else HELD, f included -- what the number does to the model;
#   (b) f RE-SOLVED to hold the deep -- what a refit would do with it, since
#       f is the parameter that trades against all three.
# Reported per point: the interior profile (slabs A, B, deep, the B - deep
# contrast at the 60-deg se), HS/HD, and the transient's stream deltas vs the
# arm (total, decadal, CO2 level, mid rows, bomb, sink). Nothing is chosen;
# the table IS the caveat.
#
# Usage:  Rscript calibration/diag_declared_param_scans.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

SP_HS_FRAC <- 0.16; SP_U_HS <- 38; SP_TAU_Q <- 538; SP_SST_HS <- 2.0; SP_ZK <- 253
SP_ATTACH  <- 1                        # HILDA's depth-independent q
SP_HS_ASX  <- 0.8                      # 09-06c sec.7 arm
SP_F_EXPECT <- 0.049; SP_F_TOL <- 0.005 # the reconstruction gate
SP_SCANS <- list(kz_zscale = c(150, 253, 500), u_hs = c(19, 38, 76), tau_q = c(269, 538, 1076))
SP_F_LO <- 1e-3; SP_F_GRID <- 16
SP_COV_FILE <- ccx_path("outputs", "diagnostics", "d14c_profile_covariance_20260906.rds")
SP_BLOCK <- "60"
SP_DECADAL <- c("d14c_NH", "d14c_SH", "gcb_ocean_sink"); SP_CO2LVL <- c("co2_level_MLO", "co2_level_SPO")
SP_MID <- c("d14c_mid_1500_2000", "d14c_mid_2000_2627"); SP_DEEP <- "d14c_deep_ocean"
SP_OUT <- ccx_path("outputs", "diagnostics", "declared_param_scans_20260906.rds")

v0 <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("\n=== DECLARED-PARAMETER SCANS -- mode %s (%s) ===\n", CCX_MODE_CANONICAL, v0$src))
cv <- readRDS(SP_COV_FILE); S <- cv$cov[[SP_BLOCK]]
se_bd <- sqrt(S[2, 2] + S[3, 3] - 2 * S[2, 3]); obs_bd <- cv$means[["B"]] - cv$means[["deep"]]
tg <- ccx_deep_d14c_target(); D_OBS <- tg$target
cat(sprintf("  deep target %.1f; observed B - deep %+.1f, se %.2f (%s-deg block)\n", D_OBS, obs_bd, se_bd, SP_BLOCK))

par_arm <- function() { p <- v0$p
  p$hs_frac <- SP_HS_FRAC; p$u_hs <- SP_U_HS; p$tau_q <- SP_TAU_Q; p$sst_hs <- SP_SST_HS
  p$q_attach_from <- SP_ATTACH; p$hs_asx_frac <- SP_HS_ASX; p$kz_zscale <- SP_ZK; p }
deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
solve_f <- function(p) {   # largest root, every sign change bracketed (diag_kz_profile_conduit.R's lesson)
  g <- function(lf) { q <- p; q$kz_deep_frac <- exp(lf); deep_of(q) - D_OBS }
  lfs <- seq(0, log(SP_F_LO), length.out = SP_F_GRID); gv <- vapply(lfs, g, 0)
  sc <- which(diff(sign(gv)) != 0)
  if (!length(sc)) return(list(f = NA_real_, n = 0L, gmin = min(abs(gv))))
  roots <- vapply(sc, function(i) exp(stats::uniroot(g, c(lfs[i], lfs[i + 1]), tol = 1e-6)$root), 0)
  list(f = roots[1], n = length(roots), all = roots)
}
mk_v <- function(p) { v <- v0; v$p <- p
  for (n in c("sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (is.null(v[[n]])) v[[n]] <- v0$pm[[n]]
  v }
tg7 <- dg_gcb_target(DG_SINK_WIN); ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread()
run_pt <- function(lbl, p) {
  vv <- mk_v(p); r <- dg_run(vv); st <- dg_streams(r, vv); sp <- r$sp
  sl <- ccx_model_d14c_slabs(sp); d <- sp$diagnostics
  g7 <- dg_gate7(r); v7 <- dg_gate7_verdict(g7, tg7); v5 <- dg_gate5_verdict(dg_gate5(r), ob5, sp5)
  list(lbl = lbl, p = p, st = st, A = sl[[1]], B = sl[[2]], deep = d$d14c_bottom_box,
       hs = d$d14c_hs[["NH"]], hd = d$d14c_hd[["NH"]], sink = g7$ocean, z7 = v7$z_ocean, z5 = v5$z[["nh_t"]])
}
sset <- function(x, s) sum(x$st[intersect(s, names(x$st))])

# ---- the arm, and the reconstruction gate ---------------------------------
p_arm <- par_arm(); s_arm <- solve_f(p_arm)
cat(sprintf("  arm: f solved = %.4f (K_deep %.0f), %d root(s); expected %.3f +/- %.3f -> %s\n",
            s_arm$f, s_arm$f * p_arm$kz, s_arm$n, SP_F_EXPECT, SP_F_TOL,
            if (is.finite(s_arm$f) && abs(s_arm$f - SP_F_EXPECT) <= SP_F_TOL) "PASS" else "FAIL (the arm is not 09-06c's)"))
p_arm$kz_deep_frac <- s_arm$f
RUNS <- list(arm = run_pt("arm (HILDA attach, hs_asx 0.8, f solved)", p_arm))
p_inc <- v0$p; p_inc$hs_frac <- 0
RUNS$ent26 <- run_pt("ent26 (32-box incumbent)", p_inc)

# ---- the scans ---------------------------------------------------------------
for (nm in names(SP_SCANS)) for (val in SP_SCANS[[nm]]) {
  if (val == p_arm[[nm]]) next
  p <- p_arm; p[[nm]] <- val
  RUNS[[sprintf("%s=%g|held", nm, val)]] <- run_pt(sprintf("%s = %g, f held %.3f", nm, val, s_arm$f), p)
  s <- solve_f(p)
  if (is.finite(s$f)) { q <- p; q$kz_deep_frac <- s$f
    RUNS[[sprintf("%s=%g|resolved", nm, val)]] <- run_pt(sprintf("%s = %g, f re-solved %.3f%s", nm, val, s$f,
                                                                if (s$n > 1) sprintf(" (%d roots: %s)", s$n, paste(signif(s$all, 3), collapse = ",")) else ""), q)
  } else cat(sprintf("  %s = %g: NO f holds the deep (closest %.1f permil)\n", nm, val, s$gmin))
}

# ---- the table: every point, whole -------------------------------------------
a <- RUNS$arm
cat(sprintf("\n  %-40s %7s %7s %7s %6s %6s %6s | %8s %7s %7s %7s %7s | %5s %5s %5s\n",
            "point", "A", "B", "deep", "B-D z", "HS", "HD", "dTOTAL", "dDECAD", "dCO2lv", "dMID", "dDEEP", "sink", "z7", "z5NH"))
for (k in names(RUNS)) { x <- RUNS[[k]]
  cat(sprintf("  %-40s %7.1f %7.1f %7.1f %+6.2f %6.1f %6.1f | %+8.1f %+7.1f %+7.1f %+7.1f %+7.1f | %5.2f %+5.2f %+5.2f\n",
              x$lbl, x$A, x$B, x$deep, ((x$B - x$deep) - obs_bd) / se_bd, x$hs, x$hd,
              sum(x$st) - sum(a$st), sset(x, SP_DECADAL) - sset(a, SP_DECADAL), sset(x, SP_CO2LVL) - sset(a, SP_CO2LVL),
              sset(x, SP_MID) - sset(a, SP_MID), sset(x, SP_DEEP) - sset(a, SP_DEEP), x$sink, x$z7, x$z5)) }
cat("\n  deltas are vs the ARM (not ent26); ent26's row shows the arm's own matched-parameter cost with the sign reversed.\n")
cat("  ⚠ Nothing adopted. These are the caveat register's numbers: 'if HILDA's value were 2x, ...'.\n")
saveRDS(list(runs = lapply(RUNS, function(x) x[setdiff(names(x), "p")]), arm_f = s_arm$f, se_bd = se_bd, obs_bd = obs_bd,
             scans = SP_SCANS, hs_asx = SP_HS_ASX), SP_OUT)
cat(sprintf("  saved %s\n", SP_OUT))
