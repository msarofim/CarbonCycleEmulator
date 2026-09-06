# =====================================================================
# diag_q_attachment_scan.R -- THE DECOMPOSITION, THE BOUNDARY, THE PIN AT THE
# OBSERVATION, AND THE TWO-TIMESCALE TEST.
#
# Pre-registered in notes/prereg_2026-09-06_q_attachment_scan_and_obs_pin.md.
# Scores parts A-D in order. Every reference is RECOMPUTED in this run; no
# number is typed from a previous collect (handoff 2026-09-05 sec.8).
#
# WHAT IT ANSWERS.
#   A  the 09-05f matched-kz decomposition, which was POST HOC, now with its
#      predictions written first.
#   B  the attachment BOUNDARY, every layer, iso-deep, reported WHOLE and never
#      scored by its argmin.
#   C  the same arms with kz solved to hold the bottom box at the SOURCED
#      GLODAP target rather than at the incumbent's own value. The iso-deep
#      control pins a layer at z +1.85 against the observation, so a third of
#      every arm's score is that constant and no arm can reach DESIGN 3.4a's
#      |z| < 1 on every layer by construction. The observation exists; use it.
#      ⚠ Both controls are printed on every arm. Neither replaces the other.
#   D  the 1750-2024 transient at the obs-pinned kz, every other parameter at
#      ent26: does the structure hold the DECADAL ocean streams (bomb 14C, the
#      modern sink) while the deep is right? That is HILDA's actual claim, and
#      it is the question a steady-state profile cannot ask.
#
# ⛔ EVERY ARM WITH q_attach_from > 1 IS "HILDA HS/HD BOXES WITH q ATTACHED
# BELOW THE SURFACE" -- a deliberate departure from HILDA (Marcus 2026-09-05).
# It is NOT "HILDA's model". Nothing here is adopted, fitted or refit.
#
# Usage:  Rscript calibration/diag_q_attachment_scan.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

# ---- named constants (every label below derives from these) ------------
QS_HS_FRAC   <- 0.16         # HILDA: 16 % of the global ocean surface
QS_U_HILDA   <- 38           # m/yr over the HS area; HILDA Table 1, 38 +/- 17
QS_TAU_Q     <- 538          # HILDA Table 1: q^-1 = 538 +/- 510 yr
QS_SST_HS    <- 2.0          # degC; the carbonate tables' floor (Lueker 2000)
QS_LUEKER_FLOOR <- 2.0       # degC; below this the transient EXTRAPOLATES
QS_NEFF      <- LIK_D14C_DEEP_NEFF
QS_SCORED_MIN_DEPTH <- 1500  # bomb addition <= 4.5 permil below this
QS_ATTACH_REF  <- 1          # HILDA, depth-independent
QS_TOL_Z       <- 0.05       # mean|z| materiality; prereg sec.1 (a JUDGEMENT)
QS_TOL_KZ_REL  <- 1e-3       # solver tolerance for "kz did not decrease"
QS_B5_HD_PERMIL <- 5; QS_B5_KZ_REL <- 0.10
QS_C1_KZ <- c(4800, 6200)    # prereg C1: incumbent obs-pinned kz window
QS_C4_KZ <- c(1500, 2300)    # prereg C4: attach-bottom obs-pinned kz window
QS_D2_MARGIN <- 1            # log-units, prereg D2
QS_D5_MARGIN <- 2            # log-units, prereg D5
QS_DECADAL <- c("d14c_NH", "d14c_SH", "gcb_ocean_sink")
QS_DEEP    <- "d14c_deep_ocean"
QS_LAND_SEAS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO", "gcb_land_sink")
KZ_LO <- CCX_PARAM_TABLE$kz$lo; KZ_HI <- CCX_PARAM_TABLE$kz$hi   # read, not typed

v0   <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("\n=== q ATTACHMENT: SCAN, OBS PIN, TWO TIMESCALES -- mode %s ===\n",
            CCX_MODE_CANONICAL))
cat(sprintf("  source %s; migrated: %s\n", v0$src,
            if (length(v0$migrated)) paste(v0$migrated, collapse = ", ") else "none"))
cat(sprintf("  HS: hs_frac %.2f  u_hs %g  tau_q %g  sst_hs %.1f   kz0 %.1f  h_ml %.2f\n",
            QS_HS_FRAC, QS_U_HILDA, QS_TAU_Q, QS_SST_HS, v0$p$kz, v0$p$h_ml))
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2
NL   <- grid$nl
SC      <- which(zmid > QS_SCORED_MIN_DEPTH)
PIN     <- length(zmid)                      # the bottom box, pinned by every control
SC_FREE <- setdiff(SC, PIN)
QS_ATTACH_TEST <- NL
QS_SCAN <- seq_len(NL)
cat(sprintf("  layers: %s\n  scored (>%g m): %s;  FREE: %s;  PINNED: %.0f m\n",
            paste(round(zmid), collapse = " "), QS_SCORED_MIN_DEPTH,
            paste(round(zmid[SC]), collapse = "/"),
            paste(round(zmid[SC_FREE]), collapse = "/"), zmid[PIN]))
cat(sprintf("  GLODAP at scored depths: %s  (se at n_eff %d: %s)\n",
            paste(sprintf("%.1f", op$d14[SC]), collapse = " / "), QS_NEFF,
            paste(sprintf("%.1f", op$d14_sd[SC] / sqrt(QS_NEFF)), collapse = " / ")))

# ---- helpers -----------------------------------------------------------
par_q <- function(attach, tau_q = QS_TAU_Q, u = QS_U_HILDA) {
  p <- v0$p
  p$hs_frac <- QS_HS_FRAC; p$u_hs <- u; p$tau_q <- tau_q
  p$sst_hs <- QS_SST_HS;   p$q_attach_from <- attach
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
zs_of <- function(prof) (prof - op$d14) / (op$d14_sd / sqrt(QS_NEFF))
stat_of <- function(prof) {
  z <- zs_of(prof)
  list(z = z, band = mean(abs(z[SC])), free = mean(abs(z[SC_FREE])), pin = z[PIN])
}
solve_kz <- function(mk, target, kz0) {
  f <- function(lk) { p <- mk(); p$kz <- exp(lk); deep_of(p) - target }
  lo <- log(kz0); hi <- log(kz0)
  n <- 0; while (f(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (f(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (f(lo) > 0 || f(hi) < 0) return(NA_real_)
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
arm <- function(lbl, mk, target, kz0 = v0$p$kz) {
  kz <- solve_kz(mk, target, kz0)
  if (is.na(kz)) { cat(sprintf("  %-30s NO kz holds the deep at %.3f -- CEILING\n", lbl, target))
                   return(NULL) }
  p <- mk(); p$kz <- kz
  sp <- ccx_spinup(p)
  pr <- prof_of(sp)
  d  <- sp$diagnostics
  hs <- if (!is.null(d$d14c_hs)) d$d14c_hs[["NH"]] else NA_real_
  hd <- if (!is.null(d$d14c_hd)) d$d14c_hd[["NH"]] else NA_real_
  c(list(lbl = lbl, kz = kz, p = p, sp = sp, prof = pr, hs = hs, hd = hd), stat_of(pr))
}
fixed <- function(p) { sp <- ccx_spinup(p); pr <- prof_of(sp)
                       c(list(p = p, sp = sp, prof = pr, bottom = sp$diagnostics$d14c_bottom_box),
                         stat_of(pr)) }
verdict <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
d0     <- deep_of(par_inc())
tg     <- ccx_deep_d14c_target()
if (is.null(tg)) stop("the deep target file is absent -- part C cannot run")
D_OBS  <- tg$target

# =====================================================================
# PART B FIRST: the full iso-deep scan. Its endpoints are part A's diagonal.
# =====================================================================
cat(sprintf("\n=== PART B: THE BOUNDARY, EVERY LAYER, ISO-DEEP (bottom box held at %.3f) ===\n", d0))
cat("  attach   zmid     kz    kz/kz0      HS       HD    LSml   z1622   z2268   band    free\n")
B <- list(); kz_prev <- v0$p$kz
for (k in QS_SCAN) {
  a <- arm(sprintf("attach from layer %d", k),
           local({ kk <- k; function() par_q(kk) }), d0, kz_prev)
  if (is.null(a)) next
  B[[as.character(k)]] <- a; kz_prev <- a$kz
  cat(sprintf("  %4d  %6.0f  %7.0f  %6.3f  %7.1f  %7.1f  %6.1f  %+6.2f  %+6.2f  %6.3f  %6.3f\n",
              k, zmid[k + 1], a$kz, a$kz / v0$p$kz, a$hs, a$hd, a$prof[1],
              a$z[SC_FREE[1]], a$z[SC_FREE[2]], a$band, a$free))
}
cat(sprintf("  (pinned layer %.0f m contributes |z| = %.3f to EVERY band score -- dead weight)\n",
            zmid[PIN], abs(B[[1]]$pin)))
solved <- names(B); kzv <- vapply(B, `[[`, 0, "kz"); fr <- vapply(B, `[[`, 0, "free")
hdv <- vapply(B, `[[`, 0, "hd")
b4 <- length(B) == NL
b1 <- all(diff(kzv) >= -QS_TOL_KZ_REL * kzv[-length(kzv)])
best <- which.min(fr)
b2 <- all(fr[-length(fr)] >= fr[length(fr)] - QS_TOL_Z)
i7 <- which(as.integer(solved) >= 7)
b3 <- all(diff(fr[i7]) <= QS_TOL_Z)
b5 <- TRUE
for (i in seq_len(length(B) - 1)) {
  if (abs(kzv[i + 1] / kzv[i] - 1) < QS_B5_KZ_REL && abs(hdv[i + 1] - hdv[i]) > QS_B5_HD_PERMIL)
    b5 <- FALSE
}
cat(sprintf("\n  B1  kz monotone non-decreasing in attachment       : %s\n", verdict(b1)))
cat(sprintf("  B2  no interior optimum (free stat, tol %.2f)       : %s  (argmin = layer %s, %.3f vs bottom %.3f)\n",
            QS_TOL_Z, verdict(b2), solved[best], fr[best], fr[length(fr)]))
cat(sprintf("  B3  free stat non-increasing over layers 7..%d     : %s\n", NL, verdict(b3)))
cat(sprintf("  B4  every arm solves (no ceiling at tau_q %g)      : %s  (%d/%d)\n",
            QS_TAU_Q, verdict(b4), length(B), NL))
cat(sprintf("  B5  HD moves with kz, not the attachment          : %s\n", verdict(b5)))
cat("  ⛔ The scan is REPORTED. Its argmin is not a decision.\n")

# =====================================================================
# PART A: the decomposition at MATCHED kz, pre-registered
# =====================================================================
ref <- B[[as.character(QS_ATTACH_REF)]]; tst <- B[[as.character(QS_ATTACH_TEST)]]
if (is.null(ref) || is.null(tst)) stop("an endpoint arm did not solve -- part A cannot run")
cat(sprintf("\n=== PART A: DECOMPOSITION at MATCHED kz (%.0f = iso-deep attach %d; %.0f = iso-deep attach %d) ===\n",
            ref$kz, QS_ATTACH_REF, tst$kz, QS_ATTACH_TEST))
cat("  kz      attach   bottom     control?   z1622   z2268   band     FREE\n")
A <- list()
for (kz in c(ref$kz, tst$kz)) for (at in c(QS_ATTACH_REF, QS_ATTACH_TEST)) {
  p <- par_q(at); p$kz <- kz
  x <- fixed(p); on_ctl <- abs(x$bottom - d0) < 1e-3
  A[[sprintf("%.0f_%d", kz, at)]] <- x
  cat(sprintf("  %5.0f   %-8s %8.1f   %-9s %+6.2f  %+6.2f  %6.3f   %6.3f\n", kz,
              if (at == QS_ATTACH_REF) "indep" else "bottom", x$bottom,
              if (on_ctl) "on" else "OFF", x$z[SC_FREE[1]], x$z[SC_FREE[2]], x$band, x$free))
}
fA <- function(kz, at) A[[sprintf("%.0f_%d", kz, at)]]$free
d_att_ref <- fA(ref$kz, QS_ATTACH_REF) - fA(ref$kz, QS_ATTACH_TEST)
d_att_tst <- fA(tst$kz, QS_ATTACH_REF) - fA(tst$kz, QS_ATTACH_TEST)
d_kz_ref  <- fA(tst$kz, QS_ATTACH_REF)  - fA(ref$kz, QS_ATTACH_REF)
d_kz_tst  <- fA(tst$kz, QS_ATTACH_TEST) - fA(ref$kz, QS_ATTACH_TEST)
me_att <- mean(c(d_att_ref, d_att_tst)); me_kz <- mean(c(d_kz_ref, d_kz_tst))
inter  <- d_att_tst - d_att_ref
a1 <- d_att_ref > QS_TOL_Z && d_att_tst > QS_TOL_Z
a2 <- abs(me_att) > abs(me_kz)
a3 <- abs(inter) < min(abs(me_att), abs(me_kz))
cat(sprintf("\n  attachment effect (indep - bottom) on FREE: %+.3f at kz %.0f, %+.3f at kz %.0f\n",
            d_att_ref, ref$kz, d_att_tst, tst$kz))
cat(sprintf("  kz effect (%.0f -> %.0f) on FREE          : %+.3f at indep, %+.3f at bottom\n",
            ref$kz, tst$kz, d_kz_ref, d_kz_tst))
cat(sprintf("  main effects: attachment %+.3f, kz %+.3f; interaction %+.3f\n", me_att, me_kz, inter))
cat(sprintf("  A1  bottom beats indep at BOTH kz (> %.2f)  : %s\n", QS_TOL_Z, verdict(a1)))
cat(sprintf("  A2  |attachment effect| > |kz effect|       : %s\n", verdict(a2)))
cat(sprintf("  A3  interaction < smaller main effect       : %s\n", verdict(a3)))
cat("  ⚠ Off-control cells' BAND stat is not a score; only FREE is comparable across the 2x2.\n")

# =====================================================================
# PART C: kz solved to hold the bottom box at the SOURCED OBSERVATION
# =====================================================================
cat(sprintf("\n=== PART C: kz SOLVED TO THE OBSERVATION -- bottom box at %.1f (%s, n_eff %d) ===\n",
            D_OBS, "d14c_deep_ocean target", tg$n_eff))
cat(sprintf("  binned GLODAP on the pinned layer is %.1f +/- %.1f, so the pinned z is %+.2f in every arm\n",
            op$d14[PIN], op$d14_sd[PIN] / sqrt(QS_NEFF),
            (D_OBS - op$d14[PIN]) / (op$d14_sd[PIN] / sqrt(QS_NEFF))))
Cc <- list(
  inc = arm("incumbent (32 boxes)", par_inc, D_OBS, v0$p$kz),
  a1  = arm(sprintf("attach %d (HILDA, depth-indep)", QS_ATTACH_REF),
            function() par_q(QS_ATTACH_REF), D_OBS, ref$kz),
  a10 = arm(sprintf("attach %d (BOTTOM ONLY)", QS_ATTACH_TEST),
            function() par_q(QS_ATTACH_TEST), D_OBS, tst$kz))
cat("\n  arm                               kz   in bracket?      HS       HD    LSml   band    free\n")
for (x in Cc) if (!is.null(x))
  cat(sprintf("  %-30s %7.0f   %-12s %7.1f  %7.1f  %6.1f  %6.3f  %6.3f\n", x$lbl, x$kz,
              if (x$kz >= KZ_LO && x$kz <= KZ_HI) "yes" else
                sprintf("NO [%.0f,%.0f]", KZ_LO, KZ_HI), x$hs, x$hd, x$prof[1], x$band, x$free))
cat("\n  per-layer z (model - GLODAP)/se:\n")
cat(sprintf("  %-30s %s\n", "depth (m)", paste(sprintf("%6.0f", zmid), collapse = " ")))
cat(sprintf("  %-30s %s\n", "GLODAP", paste(sprintf("%6.1f", op$d14), collapse = " ")))
for (x in Cc) if (!is.null(x)) {
  cat(sprintf("  %-30s %s\n", x$lbl, paste(sprintf("%6.1f", x$prof), collapse = " ")))
  cat(sprintf("  %-30s %s\n", "   z", paste(sprintf("%+6.2f", x$z), collapse = " ")))
}
cat("  ⚠ layers above ~1500 m are compared to BOMB-CONTAMINATED bottles from a preindustrial\n")
cat("    state; their z is printed for shape only and is not evidence either way.\n")
ci <- Cc$inc; ca <- Cc$a1; cb <- Cc$a10
c1 <- !is.null(ci) && ci$kz >= QS_C1_KZ[1] && ci$kz <= QS_C1_KZ[2] && ci$kz >= KZ_LO && ci$kz <= KZ_HI
c2 <- !is.null(ci) && ci$z[SC_FREE[1]] > 1
c3 <- !is.null(cb) && all(abs(cb$z[SC]) < 1)
c4 <- !is.null(cb) && cb$kz >= QS_C4_KZ[1] && cb$kz <= QS_C4_KZ[2] && (cb$kz < KZ_LO || cb$kz > KZ_HI)
c5 <- !is.null(ca) && !all(abs(ca$z[SC]) < 1) && ca$z[SC_FREE[1]] > 1 && ca$kz < cb$kz
cat(sprintf("\n  C1  incumbent kz in [%g, %g] and inside the bracket : %s  (%.0f)\n",
            QS_C1_KZ[1], QS_C1_KZ[2], verdict(c1), if (!is.null(ci)) ci$kz else NA))
cat(sprintf("  C2  incumbent z(%.0f m) > +1, shape too steep        : %s  (%+.2f)\n",
            zmid[SC_FREE[1]], verdict(c2), if (!is.null(ci)) ci$z[SC_FREE[1]] else NA))
cat(sprintf("  C3  ⭐ BOTTOM: every scored layer inside |z| < 1     : %s  (%s)\n", verdict(c3),
            if (!is.null(cb)) paste(sprintf("%+.2f", cb$z[SC]), collapse = " / ") else "-"))
cat(sprintf("  C4  bottom kz in [%g, %g], OUTSIDE the bracket     : %s  (%.0f)\n",
            QS_C4_KZ[1], QS_C4_KZ[2], verdict(c4), if (!is.null(cb)) cb$kz else NA))
cat(sprintf("  C5  HILDA attach does NOT reach all-inside; 1622 young : %s  (%s; kz %.0f)\n", verdict(c5),
            if (!is.null(ca)) paste(sprintf("%+.2f", ca$z[SC]), collapse = " / ") else "-",
            if (!is.null(ca)) ca$kz else NA))
cat("  ⛔ These arms are 'HILDA HS/HD boxes with q attached at the BOTTOM' -- NOT HILDA's model.\n")

# =====================================================================
# PART D: the two-timescale test -- the 1750-2024 transient at the obs-pinned
# kz, every other parameter at ent26. NO refit.
# =====================================================================
cat(sprintf("\n=== PART D: TWO TIMESCALES -- transient %d-%d, ent26 parameters, kz from part C ===\n",
            DG_YEARS[1], DG_YEARS[2]))
mk_v <- function(p) { v <- v0; v$p <- p
  for (n in c("sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c"))
    if (is.null(v[[n]])) v[[n]] <- v0$pm[[n]]
  v }
runs <- list(R0 = list(lbl = "R0 incumbent, own kz",     p = par_inc()),
             R1 = list(lbl = "R1 incumbent, obs-pinned", p = local({ p <- par_inc(); p$kz <- ci$kz; p })),
             R2 = list(lbl = sprintf("R2 attach %d, obs-pinned", QS_ATTACH_TEST),
                       p = local({ p <- par_q(QS_ATTACH_TEST); p$kz <- cb$kz; p })),
             R3 = list(lbl = sprintf("R3 attach %d, obs-pinned", QS_ATTACH_REF),
                       p = local({ p <- par_q(QS_ATTACH_REF); p$kz <- ca$kz; p })))
ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread(); tg7 <- dg_gcb_target(DG_SINK_WIN)
D <- list()
for (nm in names(runs)) {
  rr <- runs[[nm]]; vv <- mk_v(rr$p)
  r  <- dg_run(vv)
  st <- dg_streams(r, vv)
  g5 <- dg_gate5(r); g7 <- dg_gate7(r)
  v5 <- dg_gate5_verdict(g5, ob5, sp5); v7 <- dg_gate7_verdict(g7, tg7)
  sst_min <- if (rr$p$hs_frac > 0)
    QS_SST_HS + min(c(r$F$sst_anom_NH, r$F$sst_anom_SH), na.rm = TRUE) else NA_real_
  D[[nm]] <- list(lbl = rr$lbl, kz = rr$p$kz, st = st, g5 = g5, g7 = g7, v5 = v5, v7 = v7,
                  sst_min = sst_min, deep = r$sp$diagnostics$d14c_bottom_box)
  cat(sprintf("  %-28s kz %7.0f  deep %7.1f  logL %9.2f  sink %5.2f (z %+.2f)  NH peak z %+.2f  min sst_hs %s\n",
              rr$lbl, rr$p$kz, D[[nm]]$deep, sum(st), g7$ocean, v7$z_ocean, v5$z[["nh_t"]],
              if (is.na(sst_min)) "-" else sprintf("%.2f%s", sst_min,
                if (sst_min < QS_LUEKER_FLOOR) " EXTRAPOLATED below the Lueker floor" else "")))
}
st0 <- D$R0$st; nms <- names(st0)
cat("\n  per-stream log-likelihood, DELTA vs R0:\n")
cat(sprintf("  %-22s %9s %9s %9s %9s\n", "stream", "R0", "R1-R0", "R2-R0", "R3-R0"))
for (n in nms)
  cat(sprintf("  %-22s %9.2f %+9.2f %+9.2f %+9.2f\n", n, st0[[n]],
              D$R1$st[[n]] - st0[[n]], D$R2$st[[n]] - st0[[n]], D$R3$st[[n]] - st0[[n]]))
cat(sprintf("  %-22s %9.2f %+9.2f %+9.2f %+9.2f\n", "TOTAL", sum(st0),
            sum(D$R1$st) - sum(st0), sum(D$R2$st) - sum(st0), sum(D$R3$st) - sum(st0)))
absent <- setdiff(c(QS_DECADAL, QS_DEEP, QS_LAND_SEAS), nms)
if (length(absent)) cat(sprintf("  ⚠ streams named in the prereg but ABSENT here: %s\n",
                                paste(absent, collapse = ", ")))
sset <- function(x, s) sum(x$st[intersect(s, nms)])
dec <- vapply(D, function(x) sset(x, QS_DECADAL) - sset(D$R0, QS_DECADAL), 0)
dee <- vapply(D, function(x) sset(x, QS_DEEP)    - sset(D$R0, QS_DEEP), 0)
lnd <- vapply(D, function(x) max(abs(x$st[intersect(QS_LAND_SEAS, nms)] -
                                     D$R0$st[intersect(QS_LAND_SEAS, nms)])), 0)
cat(sprintf("\n  decadal set (%s) delta vs R0: R1 %+.2f  R2 %+.2f  R3 %+.2f\n",
            paste(QS_DECADAL, collapse = " + "), dec[["R1"]], dec[["R2"]], dec[["R3"]]))
cat(sprintf("  deep term (%s) delta vs R0    : R1 %+.2f  R2 %+.2f  R3 %+.2f\n",
            QS_DEEP, dee[["R1"]], dee[["R2"]], dee[["R3"]]))
d1 <- -dec[["R1"]] > dee[["R1"]]
d2 <- dec[["R2"]] > dec[["R1"]] + QS_D2_MARGIN
d3 <- isTRUE(D$R2$v7$pass) || abs(D$R2$v7$z_ocean) <= DG_G7_NSD
d4 <- D$R2$v5$z[["nh_t"]] <= D$R0$v5$z[["nh_t"]]
d5 <- all(lnd[c("R1", "R2", "R3")] < QS_D5_MARGIN)
cat(sprintf("  D1  pure column: decadal loss (%.2f) > deep gain (%.2f)      : %s\n",
            -dec[["R1"]], dee[["R1"]], verdict(d1)))
cat(sprintf("  D2  ⭐ bottom keeps more decadal than the column (by > %g)  : %s  (R2 %+.2f vs R1 %+.2f)\n",
            QS_D2_MARGIN, verdict(d2), dec[["R2"]], dec[["R1"]]))
cat(sprintf("  D3  R2 ocean sink inside gate 7's bound (|z| <= %g)        : %s  (z %+.2f; R0 %+.2f)\n",
            DG_G7_NSD, verdict(d3), D$R2$v7$z_ocean, D$R0$v7$z_ocean))
cat(sprintf("  D4  R2 NH bomb peak no later than R0                       : %s  (z %+.2f vs %+.2f)\n",
            verdict(d4), D$R2$v5$z[["nh_t"]], D$R0$v5$z[["nh_t"]]))
cat(sprintf("  D5  land/seasonal streams move < %g in every run           : %s  (max %.2f / %.2f / %.2f)\n",
            QS_D5_MARGIN, verdict(d5), lnd[["R1"]], lnd[["R2"]], lnd[["R3"]]))
cat("\n  ⚠ MATCHED-PARAMETER, NOT A REFIT: k_w, bomb_total, pump_grad, h_ml are ent26's 32-box values.\n")
cat("  ⚠ Every HS/HD arm is a deliberate departure from HILDA. NOT HILDA's model. Nothing adopted.\n")
