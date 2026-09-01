# =====================================================================
# diag_q10_controlled_recovery.R -- THE CONTROLLED q10 TEST.
#   27q's SIX-ARM 2x2, byte-for-byte, with ONE axis moved: `q10` is FREE
#   in EVERY arm instead of pinned. Nothing else changes.
#
# PRE-REGISTERED: notes/prereg_2026-08-29_controlled_q10_recovery.md, committed
# (1f4f4ce) BEFORE this file existed. Every gate below is copied from it
# unchanged. Do not edit a gate here without amending that note.
#
# THE CONFOUND. The channel recovers 83.6 % of the land penalty in 27j and
# 42.9/43.7 % in 27q -- but TWO things differ: the SLICE (q10 free vs pinned)
# and the LEVER (seas_npp_amp_SH, a constant, vs seas_T_amp_SH, a calibrated
# parameter). This run holds the lever and moves the slice.
#
# ⚠ THE WHOLE GAP LIVES IN ONE ARM. Three of 27j's four arms already reproduce
# 27q's to within 0.05: INCUMBENT -1546.195/-1546.195, OCEAN -1533.627/-1533.660,
# LAND -1626.638/-1626.615. JOINT is -1546.790 vs -1579.610.
#
# ⚠ FOUR OF THE SIX ARMS ARE REPRODUCTION GATES, NOT RESULTS (C1): INCUMBENT and
# OCEAN_only are 27j's; LAND_mid/_hi are 27p's FREE-slice conditional points
# (seas_T_amp_sh_power.rds$cond). Only the two JOINTs are new. They are re-run
# anyway -- splicing three drivers' numbers is not a controlled comparison.
#
# ⚠ THE DENOMINATOR COLLAPSES. 27p measured the free-q10 land cost at 43.60 (hi)
# against the pinned 162.14, with SH_land barely moved (1.216 vs 0.859): with q10
# free the LAND arm LEAKS the defect instead of imposing it. So the recovered
# FRACTION is a fraction of a 3.7x smaller base and can exceed 100 % with nothing
# physical improving. The per-ppm statistic in sec.6 is the honest one --
# "a ratio is not a magnitude until you multiply its BASE" (~/.claude/CLAUDE.md).
#
# ⚠ THE OFFSET IS -1.5805. NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE.
#
# Usage:  Rscript calibration/diag_q10_controlled_recovery.R     # ~30 min, 6 arms
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

QC_YEARS <- c(1750, 2024)
# 27q's REPAIRED slice PLUS q10 -- the one axis this driver moves. `q10` is FREE
# in every arm; the mode's value is only its STARTING point.
QC_BASE     <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_lag_p", "q10")
QC_LAND_PAR <- "seas_T_amp_SH"      # free in INCUMBENT/OCEAN, PINNED in LAND/JOINT
QC_BR_LO <- ccx_const("SEAS_T_AMP_SH_OBS_LO")   # 3.5915 K, all SH land
QC_BR_HI <- ccx_const("SEAS_T_AMP_SH_OBS_HI")   # 7.1012 K, SH land >30S
QC_MID   <- sqrt(QC_BR_LO * QC_BR_HI)           # 5.0502, the prior's centre (27n's TA_INIT)
QC_PINS  <- c(mid = QC_MID, hi = QC_BR_HI)      # the two ends the prereg requires
QC_ENT_BOUNDS <- c(0.5, 60)         # BOUNDS, not a prior -- 27j's, unchanged
QC_ENT_INIT   <- 10                 # 27j's, unchanged
QC_MAXIT <- 1500; QC_RESTARTS <- 6; QC_RESTOL <- 0.02
# ---- THE PRE-REGISTERED GATES, copied from prereg 27q sec.2. Fixed here so they
# ---- cannot drift to meet the answer. P0-P6 are 27j's OWN gates, unchanged.
QC_P0_TOTAL  <- 1.141; QC_P0_SHLAND <- 1.308
QC_P0_NHORIG <- 0.821; QC_P0_RATIO  <- 1.930; QC_P0_OFFSET <- -1.5805
QC_P1_FRAC   <- 0.5                 # 27j's JR_P1_FRAC
QC_P2_BAND   <- c(5, 30)            # 27g's physical band
QC_P3_RATIO  <- 1.70                # 27g's own unmet gate
QC_P4_TOTAL  <- c(1.114, 1.222)
QC_P5_OCEAN  <- 0.75
QC_P6_MLO    <- c(0.90, 1.10)
QC_P7_SSTSH  <- 0.26                # midpoint of 27p's 0.1553 collapse and 0.3663
QC_P8_SHLAND <- 1.05                # 27p's S1, the ANTI-27n gate
QC_OBS_TOTAL <- 1.168; QC_OBS_LAND <- 0.683; QC_OBS_OCEAN <- 0.522
# ---- C1-C6, copied from prereg 2026-08-29 sec.2. MEASURED ELSEWHERE, not fitted here.
QC_C1_EXPECT <- c(INCUMBENT = -1546.195, OCEAN_only = -1533.627,    # 27j, q10 free
                  LAND_mid  = -1575.950, LAND_hi    = -1589.795)    # 27p cond, q10 free
QC_C1_TOL    <- c(INCUMBENT = 0.10, OCEAN_only = 0.10, LAND_mid = 0.30, LAND_hi = 0.30)
QC_C2_PINNED <- c(INCUMBENT = -1546.195, LAND_mid = -1626.615, LAND_hi = -1708.338,
                  OCEAN_only = -1533.660, JOINT_mid = -1579.610, JOINT_hi = -1624.915)  # 27q
QC_C3_LNQ    <- 0.03                     # min |ln q10_fit / ln q10_pin - 1| in the LAND arms
QC_C3_PROD   <- 0.02                     # NH product within 2 % of INCUMBENT = the ridge is ridden
QC_C4_EXPLAINS <- 0.65                   # >= at either end  ==> q10 EXPLAINS the contrast
QC_C4_STABLE   <- c(0.33, 0.54)          # inside at BOTH ends ==> it does NOT
QC_C5_DROP   <- 0.05                     # land cost must fall >= 5 % at both ends
QC_C6_SHLAND <- 1.15                     # LAND_hi SH-land >= this (27p: 1.216) = defect NOT imposed
QC_PINNED_REC <- c(mid = 0.429, hi = 0.437)          # 27q, at the corrected h_ml depth
QC_PINNED_LC  <- c(mid = 80.420, hi = 162.142)       # 27q land costs
QC_PINNED_VAC <- c(mid = 0.305, hi = 0.449)          # 27q SH-land vacancies, ppm
QC_PINNED_INT <- c(mid = 34.470, hi = 70.887)        # 27q interactions
QC_REF_27J    <- c(rec = 0.836, lc = 80.443, inter = 67.280, vac = 0.3828)
QC_PERPPM_BAND <- c(110, 200)            # the REGISTERED prediction for the secondary statistic
QC_SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))                  # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

md <- readRDS(ccx_mode_file())
# ⚠ ADOPT THE MODE'S OWN h_ml BAND BEFORE DECODING ANYTHING (2026-08-28).
# The pump refits override h_ml's logit band IN PROCESS, so `ccx_unc_to_par()`
# -- a pure function of the SHIPPED table -- returns 85.73 m where this mode
# actually sits at 96.47 m, an 11 % shallower mixed layer. h_ml is frozen in
# this driver, so the effect is a WRONG CONSTANT in every arm, not a changed
# contrast; the arms below were previously all wrong together.
# See the note above ccx_mode_params() in R/paths.R. [[ccx_hml_band_decode]]
ccx_adopt_mode_band(md)
u0 <- md$u_mode                     # ⚠ SPELL IT OUT: md$u partial-matches this
names(u0) <- CCX_PARAM_NAMES
stopifnot(QC_LAND_PAR %in% CCX_PARAM_NAMES, "q10" %in% CCX_PARAM_NAMES,
          CCX_PARAM_TABLE[[QC_LAND_PAR]]$tr == "log")
stopifnot(!("ent_seas_amp_SH" %in% CCX_PARAM_NAMES))   # a base_param, not in `u`
i_at <- match(QC_LAND_PAR, CCX_PARAM_NAMES); i_q <- match("q10", CCX_PARAM_NAMES)
i_base <- match(QC_BASE, CCX_PARAM_NAMES); stopifnot(!anyNA(i_base))
stopifnot(!(i_at %in% i_base), i_q %in% i_base)   # ⚠ INVERTED vs 27q: q10 IS in the slice
pv0 <- ccx_unc_to_par(u0); Q10_PIN <- pv0$q10

# One logpost builder per `ent`, which lives in base_params (not in CCX_PARAM_NAMES).
.cache <- new.env(parent = emptyenv())
lp_of <- function(ent) {
  k <- sprintf("%.6f", ent)
  if (is.null(.cache[[k]])) {
    bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode; bp$ent_seas_amp_SH <- ent
    .cache[[k]] <- ccx_make_logpost(years = QC_YEARS, base_params = bp)
  }
  .cache[[k]]
}
one <- lp_of(0)(u0); gap <- one - md$logpost
cat(sprintf("mode %s (arm %s)\n", basename(ccx_mode_file()), md$pump_mode))
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f (known %.4f)\n",
            one, md$logpost, gap, QC_P0_OFFSET))
cat(sprintf("q10 FREE in EVERY arm, starting at the mode's %.5f | base slice (%d): %s\n",
            Q10_PIN, length(QC_BASE), paste(QC_BASE, collapse = ", ")))
cat(sprintf("land lever %s: FREE in INCUMBENT/OCEAN, PINNED at %.4f (mid) / %.4f (hi)\n",
            QC_LAND_PAR, QC_PINS[["mid"]], QC_PINS[["hi"]]))
cat(sprintf("ent bounds %g-%g (BOUNDS, not a prior), init %g\n",
            QC_ENT_BOUNDS[1], QC_ENT_BOUNDS[2], QC_ENT_INIT))

obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
obsv <- list(co2_SPO = vec_of(pick(obs, "co2_seas.SPO")), d13_SPO = vec_of(pick(obs, "d13_seas.SPO")),
             co2_MLO = vec_of(pick(obs, "co2_seas.MLO")), d13_MLO = vec_of(pick(obs, "d13_seas.MLO")))

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
run_at <- function(pv, ent, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv); p$pump_mode <- md$pump_mode; p$ent_seas_amp_SH <- ent
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", QC_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o  <- ccx_run_fast(sp, F)$out; ms <- ccx_model_stats(o, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")), d13_SPO = vec_of(pick(ms, "d13_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")), d13_MLO = vec_of(pick(ms, "d13_seas.MLO")),
       ll = unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                           grad_off_co2 = pv$grad_off_co2,
                                           grad_off_d13c = pv$grad_off_d13c),
                              luc = ccx_forcing_eluc_annual(F),
                              deep = sp$diagnostics$d14c_bottom_box,
                              ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)))
}
# ⚠ the ocean case must kill BOTH SH limbs. sst_seas_amp_SH = 0 alone leaves the
# entrainment limb running -- the bug the channel exposed in the older scripts on 27g.
QC_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))
ratio_at <- function(b, st) {
  ao <- amp(obsv[[paste0("co2_", st)]]); do_ <- amp(obsv[[paste0("d13_", st)]])
  (amp(b[[paste0("d13_", st)]]) / amp(b[[paste0("co2_", st)]])) / (do_ / ao)
}
score <- function(pv, ent) {
  b <- run_at(pv, ent)
  d <- lapply(QC_CASES, function(m) { v <- b$co2_SPO - run_at(pv, ent, m)$co2_SPO
                                      c(amp = amp(v), mo = ang_mo(v)) })
  list(total = c(amp = amp(b$co2_SPO), mo = ang_mo(b$co2_SPO)), dec = d,
       r_SPO = ratio_at(b, "SPO"), r_MLO = ratio_at(b, "MLO"), ll = b$ll)
}
# 27j's fit_arm, unchanged. 27h had to discard a run for a silent maxit, so every
# arm prints its restarts and last gain.
fit_arm <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = QC_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200, reltol = 1e-12)),
              silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = QC_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < QC_RESTOL || n_re >= QC_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain, converged = gain < QC_RESTOL)
}
lo <- log(QC_ENT_BOUNDS[1]); hi <- log(QC_ENT_BOUNDS[2])

sep("0. P0 -- METHOD CONTROL. If this fails, nothing below is read.")
s0 <- score(pv0, 0)
p0  <- c(total = s0$total[["amp"]], shland = s0$dec$SH_land[["amp"]],
         nhorig = s0$dec$NH_origin[["amp"]], ratio = s0$r_SPO)
ex0 <- c(total = QC_P0_TOTAL, shland = QC_P0_SHLAND, nhorig = QC_P0_NHORIG, ratio = QC_P0_RATIO)
for (n in names(p0))
  cat(sprintf("  %-8s %8.3f  27j expected %8.3f  %s\n", n, p0[[n]], ex0[[n]],
              if (abs(p0[[n]] - ex0[[n]]) < 0.005 * abs(ex0[[n]])) "ok" else "⚠ MOVED"))
cat(sprintf("  %-8s %8.4f  27j expected %8.4f  %s\n", "offset", gap, QC_P0_OFFSET,
            if (abs(gap - QC_P0_OFFSET) < 0.5) "ok" else "⚠ MOVED"))
P0 <- all(abs(p0 - ex0) < 0.005 * abs(ex0)) && abs(gap - QC_P0_OFFSET) < 0.5
cat(sprintf("\n  P0 -> %s\n", if (P0) "PASS" else "FAIL -- STOP, do not read below"))

sep("1. THE SIX ARMS")
# free_land: is seas_T_amp_SH in the slice?  pin: its value when it is not.
ARMS <- list(
  INCUMBENT  = list(free_land = TRUE,  pin = NA,             ent_free = FALSE),
  LAND_mid   = list(free_land = FALSE, pin = QC_PINS[["mid"]], ent_free = FALSE),
  LAND_hi    = list(free_land = FALSE, pin = QC_PINS[["hi"]],  ent_free = FALSE),
  OCEAN_only = list(free_land = TRUE,  pin = NA,             ent_free = TRUE),
  JOINT_mid  = list(free_land = FALSE, pin = QC_PINS[["mid"]], ent_free = TRUE),
  JOINT_hi   = list(free_land = FALSE, pin = QC_PINS[["hi"]],  ent_free = TRUE))
cat(sprintf("  %-11s %8s %7s | %10s | %9s %5s | %2s %8s\n", "arm", "a_t", "ent",
            "logpost", "vs u_mode", "npar", "re", "lastgain"))
res <- list()
for (nm in names(ARMS)) {
  A <- ARMS[[nm]]
  idx <- if (A$free_land) c(i_base, i_at) else i_base
  ua  <- u0                                              # ⚠ q10 is FREE: u0 is only its START
  if (!A$free_land) ua[i_at] <- log(A$pin)               # the land pin
  v0  <- ua[idx]
  t0  <- Sys.time()
  if (A$ent_free) {
    objf <- function(v) {
      le <- v[length(v)]
      if (le < lo || le > hi) return(1e12)               # BOUNDS, not a prior
      u <- ua; u[idx] <- v[-length(v)]; -lp_of(round(exp(le), 6))(u)
    }
    ft  <- fit_arm(objf, c(v0, log(QC_ENT_INIT)))
    ent <- exp(ft$par[length(ft$par)]); u_h <- ua; u_h[idx] <- ft$par[-length(ft$par)]
    npar <- length(idx) + 1
  } else {
    objf <- function(v) { u <- ua; u[idx] <- v; -lp_of(0)(u) }
    ft  <- fit_arm(objf, v0); ent <- 0; u_h <- ua; u_h[idx] <- ft$par; npar <- length(idx)
  }
  pv <- ccx_unc_to_par(u_h)
  stopifnot(i_q %in% idx)                                # q10 free in EVERY arm, not assumed
  if (!A$free_land) stopifnot(abs(pv[[QC_LAND_PAR]] - A$pin) < 1e-9)
  res[[nm]] <- list(pin = A$pin, ent = ent, lp = -ft$value, u = u_h, pv = pv, npar = npar,
                    converged = ft$converged, restarts = ft$restarts, s = score(pv, ent),
                    secs = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  cat(sprintf("  %-11s %8.4f %7.3f | %10.3f | %+9.2f %5d | %2d %8.4f%s\n", nm,
              pv[[QC_LAND_PAR]], ent, -ft$value, -ft$value - one, npar, ft$restarts,
              ft$last_gain, if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}
cat(sprintf("\n  wall clock per arm (s): %s\n",
            paste(sprintf("%.0f", vapply(res, function(x) x$secs, 0)), collapse = ", ")))

sep("1b. C1-C3 -- REPRODUCTION, NESTING, AND POWER. Read these BEFORE the statistic.")
Lc <- vapply(res, function(r) r$lp, 0)

cat("  C1  four arms were MEASURED by other drivers; this is a reproduction, not a result\n")
cat(sprintf("  %-11s %11s %11s %9s %7s  %s\n", "arm", "here", "expected", "diff", "tol", "src"))
C1 <- c()
for (nm in names(QC_C1_EXPECT)) {
  d <- Lc[[nm]] - QC_C1_EXPECT[[nm]]; ok <- abs(d) <= QC_C1_TOL[[nm]]
  cat(sprintf("  %-11s %11.3f %11.3f %+9.3f %7.2f  %-4s %s\n", nm, Lc[[nm]], QC_C1_EXPECT[[nm]],
              d, QC_C1_TOL[[nm]], if (grepl("LAND", nm)) "27p" else "27j",
              if (ok) "ok" else "⚠ MISS"))
  C1[nm] <- ok
}
cat(sprintf("  C1 -> %s\n", if (all(C1)) "PASS" else
  "FAIL -- an OPTIMISER verdict, not a physical one; the missed arm(s) are VOID"))

cat("\n  C2  nesting: the 27q PINNED point is FEASIBLE here, so no arm may be worse\n")
cat(sprintf("  %-11s %11s %11s %9s  %s\n", "arm", "free", "27q pinned", "gain", "verdict"))
C2 <- c()
for (nm in names(QC_C2_PINNED)) {
  g <- Lc[[nm]] - QC_C2_PINNED[[nm]]; ok <- g >= -QC_RESTOL
  cat(sprintf("  %-11s %11.3f %11.3f %+9.3f  %s\n", nm, Lc[[nm]], QC_C2_PINNED[[nm]], g,
              if (ok) "ok" else "⚠ OPTIMISER FAILURE"))
  C2[nm] <- ok
}
cat(sprintf("  C2 -> %s\n", if (all(C2)) "PASS" else "FAIL -- do not read C4 from a failed fit"))

cat("\n  C3  POWER: q10 must MOVE and the NH ridge must be RIDDEN, or C4's null means nothing\n")
lnq0 <- log(Q10_PIN); prod_inc <- res$INCUMBENT$pv$seas_T_amp_NH * log(res$INCUMBENT$pv$q10)
cat(sprintf("  %-11s %9s %9s %9s | %9s %8s  %s\n",
            "arm", "q10", "ln q10", "d ln q10", "sTaNH", "product", "vs INC"))
C3 <- c()
for (nm in names(res)) {
  q <- res[[nm]]$pv$q10; pr <- res[[nm]]$pv$seas_T_amp_NH * log(q)
  dq <- abs(log(q) / lnq0 - 1); dp <- abs(pr / prod_inc - 1)
  cat(sprintf("  %-11s %9.5f %9.5f %+9.2f%% | %9.3f %8.4f  %+7.2f%%%s\n", nm, q, log(q),
              100 * (log(q) / lnq0 - 1), res[[nm]]$pv$seas_T_amp_NH, pr, 100 * (pr / prod_inc - 1),
              if (grepl("LAND", nm)) sprintf("   moved %s | ridge %s",
                if (dq >= QC_C3_LNQ) "ok" else "⚠ NO", if (dp <= QC_C3_PROD) "ok" else "⚠ NO") else ""))
  if (grepl("LAND", nm)) C3[nm] <- (dq >= QC_C3_LNQ) && (dp <= QC_C3_PROD)
}
cat(sprintf("  C3 -> %s\n", if (all(C3)) "PASS -- the leak is operating; C4 has power" else
  "FAIL -- q10 did not ride the ridge. C4 is a NO-POWER NULL and is NOT evidence."))


sep("2. P1 -- THE TWO INTERACTIONS, both parameter-balanced")
L <- vapply(res, function(r) r$lp, 0)
P1 <- c(); INT <- c(); LC <- c()
for (e in c("mid", "hi")) {
  ln <- paste0("LAND_", e); jn <- paste0("JOINT_", e)
  inter <- L[[jn]] - L[[ln]] - L[["OCEAN_only"]] + L[["INCUMBENT"]]
  nb <- res[[jn]]$npar - res[[ln]]$npar - res$OCEAN_only$npar + res$INCUMBENT$npar
  lc <- L[["INCUMBENT"]] - L[[ln]]; gt <- QC_P1_FRAC * abs(lc)
  cat(sprintf("\n  --- a_t = %.4f (%s) ---\n", res[[ln]]$pin, e))
  cat(sprintf("  npar: %d - %d - %d + %d = %d  (must be 0)\n", res[[jn]]$npar, res[[ln]]$npar,
              res$OCEAN_only$npar, res$INCUMBENT$npar, nb))
  cat(sprintf("  LAND  vs incumbent: %+9.2f | OCEAN vs incumbent: %+9.2f | JOINT: %+9.2f\n",
              L[[ln]] - L[["INCUMBENT"]], L[["OCEAN_only"]] - L[["INCUMBENT"]],
              L[[jn]] - L[["INCUMBENT"]]))
  cat(sprintf("  sum of the two singles: %+9.2f\n",
              (L[[ln]] - L[["INCUMBENT"]]) + (L[["OCEAN_only"]] - L[["INCUMBENT"]])))
  cat(sprintf("  INTERACTION = %+.2f   (gate >= %.2f = %.1f x the %.2f land cost)  -> %s\n",
              inter, gt, QC_P1_FRAC, lc, if (inter >= gt) "PASS" else "FAIL"))
  stopifnot(nb == 0)
  P1[e] <- inter >= gt; INT[e] <- inter; LC[e] <- lc
}
cat(sprintf("\n  P1 -> %s\n", if (all(P1))
  "CONFIRMED at BOTH bracket ends -- the two corrections ARE one fix, with the ADMISSIBLE lever." else
  if (any(P1)) "⚠ SPLIT -- the two ends DISAGREE. That is the finding; neither is quoted alone." else
  "FALSIFIED -- the channel cannot supply what the ADMISSIBLE lever vacates.\n        See prereg sec.4: that localises the coupling in the SHAPE of the vacancy."))

sep("3. P2-P8 -- THE PHYSICAL SCORECARD, scored on JOINT at each bracket end")
vg <- function(lab, v, ok, gate) {
  cat(sprintf("  %-36s %10.3f %10s %s\n", lab, v, gate, if (ok) "PASS" else "FAIL")); ok }
V <- list()
for (e in c("mid", "hi")) {
  jn <- paste0("JOINT_", e); J <- res[[jn]]$s
  cat(sprintf("\n  --- JOINT at a_t = %.4f (%s) ---\n", res[[jn]]$pin, e))
  cat(sprintf("  %-36s %10s %10s %s\n", "prediction", "value", "gate", "verdict"))
  v <- c()
  v["P2"] <- vg("P2  ent_seas_amp_SH in band", res[[jn]]$ent,
                res[[jn]]$ent >= QC_P2_BAND[1] && res[[jn]]$ent <= QC_P2_BAND[2],
                sprintf("%g-%g", QC_P2_BAND[1], QC_P2_BAND[2]))
  v["P3"] <- vg("P3  SPO d13C-per-ppm", J$r_SPO, J$r_SPO <= QC_P3_RATIO,
                sprintf("<= %.2f", QC_P3_RATIO))
  v["P4"] <- vg("P4  SPO total (obs 1.168)", J$total[["amp"]],
                J$total[["amp"]] >= QC_P4_TOTAL[1] && J$total[["amp"]] <= QC_P4_TOTAL[2],
                sprintf("%.3f-%.3f", QC_P4_TOTAL[1], QC_P4_TOTAL[2]))
  v["P5"] <- vg("P5  SPO ocean ratio", J$dec$SH_ocean[["amp"]] / QC_OBS_OCEAN,
                J$dec$SH_ocean[["amp"]] / QC_OBS_OCEAN >= QC_P5_OCEAN,
                sprintf(">= %.2f", QC_P5_OCEAN))
  v["P6"] <- vg("P6  MLO control d13C-per-ppm", J$r_MLO,
                J$r_MLO >= QC_P6_MLO[1] && J$r_MLO <= QC_P6_MLO[2],
                sprintf("%.2f-%.2f", QC_P6_MLO[1], QC_P6_MLO[2]))
  v["P7"] <- vg("P7  sst_seas_amp_SH recovered", res[[jn]]$pv$sst_seas_amp_SH,
                res[[jn]]$pv$sst_seas_amp_SH >= QC_P7_SSTSH, sprintf(">= %.2f", QC_P7_SSTSH))
  v["P8"] <- vg("P8  JOINT SH-land (anti-27n)", J$dec$SH_land[["amp"]],
                J$dec$SH_land[["amp"]] <= QC_P8_SHLAND, sprintf("<= %.2f", QC_P8_SHLAND))
  V[[e]] <- v
}

sep("4. WHERE EVERY ARM LANDS")
cat(sprintf("  %-11s %8s %6s | %8s %6s | %8s %6s | %8s %6s | %7s %7s | %8s %8s\n", "arm",
            "total", "mo", "SH-land", "mo", "SH-ocn", "mo", "NH-orig", "mo", "SPO r", "MLO r",
            "sstSH", "sTaNH"))
for (nm in names(res)) { s <- res[[nm]]$s; p <- res[[nm]]$pv
  cat(sprintf("  %-11s %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %7.3f %7.3f | %8.4f %8.3f\n",
              nm, s$total[["amp"]], s$total[["mo"]], s$dec$SH_land[["amp"]], s$dec$SH_land[["mo"]],
              s$dec$SH_ocean[["amp"]], s$dec$SH_ocean[["mo"]], s$dec$NH_origin[["amp"]],
              s$dec$NH_origin[["mo"]], s$r_SPO, s$r_MLO, p$sst_seas_amp_SH, p$seas_T_amp_NH)) }
cat(sprintf("  %-11s %8.3f %6s | %8.3f %6s | %8.3f %6.2f | %8s %6s | %7.3f\n",
            "OBSERVED", QC_OBS_TOTAL, "", QC_OBS_LAND, "", QC_OBS_OCEAN, 8.52, "", "", 1.000))
cat("\n  the scored seasonal rows, each arm minus the INCUMBENT:\n")
cat(sprintf("  %-11s", "arm")); for (n in QC_SEAS_ROWS) cat(sprintf(" %13s", substr(n, 1, 13)))
cat("\n")
for (nm in names(res)) { cat(sprintf("  %-11s", nm))
  for (n in QC_SEAS_ROWS) cat(sprintf(" %+13.2f", res[[nm]]$s$ll[[n]] - res$INCUMBENT$s$ll[[n]]))
  cat("\n") }

sep("5. SCORED")
for (e in c("mid", "hi"))
  cat(sprintf("  a_t %.4f (%s): P1 %s | %s\n", res[[paste0("JOINT_", e)]]$pin, e,
              ifelse(P1[[e]], "PASS", "FAIL"),
              paste(sprintf("%s %s", names(V[[e]]), ifelse(V[[e]], "PASS", "FAIL")), collapse = " | ")))
cat(sprintf("\n  P0 %s | INTERACTION mid %+.2f, hi %+.2f\n",
            ifelse(P0, "PASS", "FAIL"), INT[["mid"]], INT[["hi"]]))
cat(sprintf("\n  ⇒ %s\n", if (!P0) "P0 FAILED -- the run is not readable." else
  if (all(P1) && all(V$hi)) "ONE FIX, CONFIRMED WITH THE ADMISSIBLE LEVER on every gate at bracket HI." else
  if (all(P1)) "The INTERACTION holds at BOTH ends; not every physical gate does. Read sec.3 and 4." else
  if (any(P1)) "⚠ THE TWO BRACKET ENDS DISAGREE. Prereg sec.1: that is the finding; quote neither alone." else
  "P1 FALSIFIED at both ends -- see prereg sec.4."))
cat("\n  ⚠ A PASS IS NOT ADOPTION. `ent_seas_amp_SH` has no prior and `seas_T_amp_SH` sits at a\n")
cat("    PINNED bracket value; adopting either is a provenance call, not a consequence of a gate.\n")


sep("6. C4-C6 -- THE CONTROLLED COMPARISON, AND THE PER-PPM STATISTIC")
VAC <- c(); REC <- c(); PPM <- c(); C5 <- c(); C6 <- c()
for (e in c("mid", "hi")) {
  ln <- paste0("LAND_", e)
  VAC[e] <- res$INCUMBENT$s$dec$SH_land[["amp"]] - res[[ln]]$s$dec$SH_land[["amp"]]
  REC[e] <- INT[[e]] / LC[[e]]
  PPM[e] <- INT[[e]] / VAC[[e]]
}
cat(sprintf("  %-5s | %9s %9s %7s | %9s %9s %7s | %8s %8s\n", "end",
            "lc free", "lc pin", "drop", "rec free", "rec pin", "delta", "vac ppm", "per-ppm"))
for (e in c("mid", "hi")) {
  drop <- 1 - LC[[e]] / QC_PINNED_LC[[e]]
  C5[e] <- drop >= QC_C5_DROP
  cat(sprintf("  %-5s | %9.2f %9.2f %6.1f%% | %8.1f%% %8.1f%% %+6.1f | %8.3f %8.1f\n", e,
              LC[[e]], QC_PINNED_LC[[e]], 100 * drop, 100 * REC[[e]],
              100 * QC_PINNED_REC[[e]], 100 * (REC[[e]] - QC_PINNED_REC[[e]]), VAC[[e]], PPM[[e]]))
}
cat(sprintf("  %-5s | %9.2f %9s %7s | %8.1f%% %9s %7s | %8.3f %8.1f   (27j, q10 free, npp lever)\n",
            "27j", QC_REF_27J[["lc"]], "", "", 100 * QC_REF_27J[["rec"]], "", "",
            QC_REF_27J[["vac"]], QC_REF_27J[["inter"]] / QC_REF_27J[["vac"]]))
cat(sprintf("\n  C5  land cost falls >= %.0f%% at both ends -> %s\n", 100 * QC_C5_DROP,
            if (all(C5)) "PASS -- the leak is operating" else "FAIL -- the leak is NOT operating"))
C6 <- res$LAND_hi$s$dec$SH_land[["amp"]] >= QC_C6_SHLAND
cat(sprintf("  C6  LAND_hi SH-land %.3f (27p 1.216, 27q PINNED 0.859, gate >= %.2f) -> %s\n",
            res$LAND_hi$s$dec$SH_land[["amp"]], QC_C6_SHLAND, if (C6) "PASS" else "FAIL"))
cat("      a PASS means the defect is NOT IMPOSED, not that it was repaired.\n")

expl <- any(REC >= QC_C4_EXPLAINS)
stab <- all(REC >= QC_C4_STABLE[1] & REC <= QC_C4_STABLE[2])
cat(sprintf("\n  C4  recovered free %.1f%% / %.1f%%  vs pinned %.1f%% / %.1f%%  vs 27j %.1f%%\n",
            100 * REC[["mid"]], 100 * REC[["hi"]], 100 * QC_PINNED_REC[["mid"]],
            100 * QC_PINNED_REC[["hi"]], 100 * QC_REF_27J[["rec"]]))
cat(sprintf("      gates: EXPLAINS if >= %.0f%% at either end | STABLE if inside %.0f-%.0f%% at BOTH\n",
            100 * QC_C4_EXPLAINS, 100 * QC_C4_STABLE[1], 100 * QC_C4_STABLE[2]))
verdict <- if (!all(C3)) "NO POWER -- C3 failed; C4 is not evidence either way." else
  if (expl) "q10 EXPLAINS the contrast: the recovery fraction is a SLICE artefact, 42.9 % survives." else
  if (stab) "q10 does NOT explain it: the fraction is stable under the slice, so the 83.6-vs-42.9 gap belongs to the LEVER -- the SHAPE of the vacancy." else
  "INTERMEDIATE -- neither branch fires. Both ends quoted, neither alone."
cat(sprintf("      C4 -> %s\n", verdict))
ppm_ok <- all(PPM >= QC_PERPPM_BAND[1] & PPM <= QC_PERPPM_BAND[2])
cat(sprintf("\n  SECONDARY (the honest one -- the denominator moved %.1fx): per-ppm %.1f / %.1f,\n",
            QC_PINNED_LC[["hi"]] / max(LC[["hi"]], 1e-9), PPM[["mid"]], PPM[["hi"]]))
cat(sprintf("      27q pinned %.1f / %.1f, 27j %.1f. REGISTERED band %g-%g -> %s\n",
            QC_PINNED_INT[["mid"]] / QC_PINNED_VAC[["mid"]],
            QC_PINNED_INT[["hi"]] / QC_PINNED_VAC[["hi"]],
            QC_REF_27J[["inter"]] / QC_REF_27J[["vac"]], QC_PERPPM_BAND[1], QC_PERPPM_BAND[2],
            if (ppm_ok) "INSIDE" else "OUTSIDE"))
cat("      ⚠ A ratio is not a magnitude until you multiply its BASE: the recovered FRACTION\n")
cat("        and the per-ppm rate can move in OPPOSITE directions here. Quote both.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(base = QC_BASE, land_par = QC_LAND_PAR, pins = QC_PINS, q10_start = Q10_PIN,
             q10_free = TRUE, harness_at_u_mode = one, harness_offset = gap, res = res,
             interaction = INT, land_cost = LC, vacancy = VAC, recovered = REC, per_ppm = PPM,
             ref_pinned = list(rec = QC_PINNED_REC, lc = QC_PINNED_LC, vac = QC_PINNED_VAC),
             ref_27j = QC_REF_27J,
             verdicts = list(P0 = P0, P1 = P1, phys = V,
                             C1 = C1, C2 = C2, C3 = C3, C4 = verdict, C5 = C5, C6 = C6)),
        file.path(OUTDIR, "q10_controlled_recovery.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "q10_controlled_recovery.rds")))
