# =====================================================================
# diag_gross_cancellation_geometry.R -- CAN THE (GROSS x CANCELLATION) PAIR
#   REACH THE OBSERVED SPO LAND ON AMPLITUDES ALONE, OR DOES THE 153 deg
#   CHANNEL GEOMETRY PUT A FLOOR ABOVE IT?
#
# PRE-REGISTERED: notes/prereg_2026-08-29c_gross_cancellation_geometry.md,
# committed (30320c1) BEFORE this file existed. Every gate below is copied from
# it unchanged. Do not edit a gate here without amending that note.
#
# THIS IS A PRE-CHECK, NOT AN ARM. It decides whether a (gross, respiration) 2x2
# is worth pre-registering at all -- exactly as 27h's tau_ex profile killed
# fork (a) before its prereg was written. [[no_power_null]]
#
# ⚠ TWO AUTHORISATIONS (Marcus 2026-08-29), both DIAGNOSTIC-ONLY:
#   1. a CMIP6 ENSEMBLE value for seas_npp_amp_SH may be USED here; it may NOT be
#      shipped, adopted, or called an observational constraint. The shipped
#      constant stays SEAS_NPP_AMP_SH = 0.5027, status="data".
#   2. a diagnostic arm MAY leave a parameter's bracket -- for MEASUREMENT ONLY.
#      27n showed the cancellation lever needs 1.56x its bracket HI to reach obs.
#
# THE TENSION. 27n measured NEP 1.3950 ppm @ mo 10.15 and respiration 0.0926 @
# 5.05 -- 5.10 months = 153 deg apart -- so the net has a HARD FLOOR
# a_NEP * sin(180-153) = 0.633 ppm, i.e. the model cannot cancel more than
# 1 - sin(27 deg) = 54.6 % at ANY respiration amplitude. CT2022 needs 74.9 %.
# Double the gross and the floor scales with it, to ~1.19 vs an observed 0.683.
#
# ⚠ THE OFFSET IS -1.5805. NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE.
#
# Usage:  Rscript calibration/diag_gross_cancellation_geometry.R    # ~10 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

GC_YEARS <- c(1750, 2024)
GC_STN   <- "SPO"
# ---- THE GATES, copied from prereg 29c sec.2. Fixed so they cannot drift.
GC_G0_NEP    <- c(amp = 1.3950, mo = 10.15)   # 27n, measured at the mode
GC_G0_RESP   <- c(amp = 0.0926, mo =  5.05)
GC_G0_SUM    <- c(amp = 1.313,  mo = 10.09)
GC_G0_KNOCK  <- 1.308                          # SH-land knockout, 27j/27q/08-29b
GC_G0_TOL    <- 0.01                           # 1 % on amplitudes
GC_G0_MOTOL  <- 0.05                           # months, on phases
GC_G1_FLOOR  <- 0.633                          # 27n's closed form at the shipped gross
GC_G1_TOL    <- 0.02
GC_G1_MEASTOL<- 0.03                           # closed form vs MEASURED minimum, 27n's P1 tol
GC_G2_LINTOL <- 0.02                           # linearity of a_NEP in A
GC_G2_MODRIFT<- 0.25                           # months of allowed NEP phase drift
GC_G3_OBS    <- 0.683                          # observed SPO land, the signature inversion at the mode
GC_G5_MOMIN  <- 0.10                           # a parameter "moves theta" if it moves it this much
# ---- the gross grid. 0.352 = 27j's GPP end (INADMISSIBLE as a configuration,
# ---- carried as a CONTROL point only); 0.5027 = shipped; 0.94 = CMIP6 median
# ---- at phi=-30, IQR 0.71-1.22 [[sh_land_undercancels]].
GC_A_SHIP    <- ccx_const("SEAS_NPP_AMP_SH")
GC_A_CMIP6   <- 0.94
GC_A_GRID    <- c(0.352, GC_A_SHIP, 0.70, GC_A_CMIP6, 1.22)
# ---- the respiration sweep. DELIBERATELY LEAVES THE BRACKET (authorisation 2):
# ---- 27n's floor sits at 13.95 K = 1.96x bracket HI and the profile turns there.
GC_TA_GRID   <- c(1.0391, 3.5915, 5.0502, 7.1012, 9.0, 11.08, 13.95, 17.0, 20.0)

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))                  # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
# separation of two harmonic vectors, in MONTHS (0-6) and DEGREES (0-180)
sep_mo <- function(u, v) { d <- abs(ang_mo(u) - ang_mo(v)); min(d, 12 - d) }
sep_dg <- function(u, v) sep_mo(u, v) * 30
# the FLOOR: min over b>=0 of |a + b*u_hat|, a the NEP vector, theta their separation
floor_of <- function(a_amp, theta_deg) a_amp * sin(pi * (180 - theta_deg) / 180)

md <- readRDS(ccx_mode_file())
ccx_adopt_mode_band(md)                       # ⚠ before decoding anything
# ⛔ MIGRATE, 2026-09-02, AND THIS FILE'S OWN G0 GATE IS WHAT CAUGHT ITS ABSENCE.
# `ccx_mode_params()` returns the file's par_mode RAW, and `from90` is a PRE-SPLIT
# 21-parameter ancestor, so it has the legacy `seas_lag_p` scalar and NEITHER
# `seas_lag_p_NH` nor `_SH`. gc_run()'s copy loop below is
#     for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv0[[n]]
# and ASSIGNING NULL DELETES THE ELEMENT, so both split names vanished from a
# ccx_default_params() that carries no legacy scalar either -- and
# ccx_seas_lag_p() fell all the way through to the NAMED DEFAULT, 2.25.
# ⇒ EVERY RUN IN THIS FILE USED LAG 2.25 WHILE ITS OWN HEADER PRINTED 1.7677,
# read off pv0 rather than off the parameters the model actually got. A
# caption-sync bug sitting on top of a silent-default bug.
# [[intersect_is_a_silent_default]]
#
# ⭐ AND THE 27n FIXTURE WAS NOT STALE -- THE CODE WAS WRONG. Forcing
# seas_lag_p_NH = _SH = 1.7677 reproduces 27n's NEP at 1.3970 @ 10.15 mo against
# its recorded 1.3950 @ 10.15 (0.14 %, 0.00 months). The 1.3807 @ 10.66 the file
# was reporting is exactly the lag-2.25 row of that same profile. The failing
# gate was RIGHT, which is the [[explained_away_test]] lesson: a "the fixture is
# stale" label would have buried a live defect.
pv0 <- ccx_migrate_par_set(ccx_mode_params(md))   # ⚠ NEVER ccx_unc_to_par(md$u_mode)
cat(sprintf("migrated: %s\n", paste(attr(pv0, "migrated"), collapse = ", ")))
cat(sprintf("mode %s (arm %s) | shipped SEAS_NPP_AMP_SH %.4f | CMIP6 %.2f\n",
            basename(ccx_mode_file()), md$pump_mode, GC_A_SHIP, GC_A_CMIP6))
# ⚠ THE LAG IS PRINTED THROUGH THE RESOLVER, not off a field. Printing
# `pv0$seas_lag_p` is what let the header disagree with the run for a fortnight.
cat(sprintf("seas_T_amp_SH at the mode %.4f K | seas_lag_p NH %.4f / SH %.4f | q10 %.5f\n",
            pv0$seas_T_amp_SH, ccx_seas_lag_p(pv0)[["NH"]],
            ccx_seas_lag_p(pv0)[["SH"]], pv0$q10))

obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
gc_run <- function(mods = list()) {
  p <- ccx_overlay_par(ccx_default_params(), pv0)   # migrate, copy, repair, ASSERT
  p$pump_mode <- md$pump_mode
  # ⭐ THE GUARD THAT WOULD HAVE CAUGHT THE 2.25 (2026-09-02). It runs BEFORE
  # `mods` are applied, so it asserts the BASELINE is the mode's -- which is the
  # thing that was silently wrong -- and does not fight a sweep that is
  # deliberately moving the lag.
  stopifnot(isTRUE(all.equal(unlist(ccx_seas_lag_p(p)), unlist(ccx_seas_lag_p(pv0)))))
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GC_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv0$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv0$luc_scale
  attr(F, "luc_scale") <- pv0$luc_scale
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
  vec_of(pick(ms, paste0("co2_seas.", GC_STN)))
}
# a CHANNEL is the VECTOR difference base - (channel off). Never a scalar.
chan <- function(base, off_mods, mods = list())
  base - gc_run(utils::modifyList(mods, off_mods))

sep("0. G0 -- REPRODUCTION AT THE MODE. If this fails, nothing below is read.")
t0 <- Sys.time()
b0    <- gc_run()
nep0  <- chan(b0, list(seas_npp_amp_SH = 0))
resp0 <- chan(b0, list(seas_T_amp_SH   = 0))
land0 <- chan(b0, list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0))
vsum0 <- nep0 + resp0
rows <- list(NEP = list(v = nep0,  e = GC_G0_NEP),
             resp = list(v = resp0, e = GC_G0_RESP),
             `vector sum` = list(v = vsum0, e = GC_G0_SUM))
cat(sprintf("  %-12s %8s %7s | %8s %7s | %s\n", "channel", "amp", "mo", "27n amp", "27n mo", "verdict"))
G0 <- c()
for (nm in names(rows)) {
  v <- rows[[nm]]$v; e <- rows[[nm]]$e
  ok <- abs(amp(v) - e[["amp"]]) <= GC_G0_TOL * e[["amp"]] &&
        abs(ang_mo(v) - e[["mo"]]) <= GC_G0_MOTOL
  cat(sprintf("  %-12s %8.4f %7.2f | %8.4f %7.2f | %s\n", nm, amp(v), ang_mo(v),
              e[["amp"]], e[["mo"]], if (ok) "ok" else "⚠ MOVED"))
  G0[nm] <- ok
}
ok_k <- abs(amp(land0) - GC_G0_KNOCK) <= GC_G0_TOL * GC_G0_KNOCK
cat(sprintf("  %-12s %8.4f %7.2f | %8.4f %7s | %s\n", "SH-land k/o", amp(land0), ang_mo(land0),
            GC_G0_KNOCK, "", if (ok_k) "ok" else "⚠ MOVED"))
G0["knockout"] <- ok_k
theta0 <- sep_dg(nep0, resp0)
cat(sprintf("\n  SEPARATION %.2f mo = %.1f deg   (27n: 5.10 mo = 153 deg)\n",
            sep_mo(nep0, resp0), theta0))
cat(sprintf("  G0 -> %s\n", if (all(G0)) "PASS" else "FAIL -- STOP, do not read below"))
stopifnot(all(G0))

sep("1. G1 -- THE FLOOR AT THE SHIPPED GROSS, CLOSED FORM vs MEASURED")
f0 <- floor_of(amp(nep0), theta0)
cat(sprintf("  closed form  a_NEP * sin(180 - %.1f) = %.4f * %.4f = %.4f   (27n %.3f)  %s\n",
            theta0, amp(nep0), sin(pi * (180 - theta0) / 180), f0, GC_G1_FLOOR,
            if (abs(f0 - GC_G1_FLOOR) <= GC_G1_TOL * GC_G1_FLOOR) "ok" else "⚠ MOVED"))
cat(sprintf("\n  the MEASURED profile (⚠ leaves the bracket [%.4f, %.4f] by authorisation 2):\n",
            ccx_const("SEAS_T_AMP_SH_OBS_LO"), ccx_const("SEAS_T_AMP_SH_OBS_HI")))
cat(sprintf("  %10s %10s %8s\n", "seas_T_amp_SH", "SH-land net", "mo"))
prof <- vapply(GC_TA_GRID, function(a) {
  v <- chan(gc_run(list(seas_T_amp_SH = a)),
            list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0), list(seas_T_amp_SH = a))
  c(amp = amp(v), mo = ang_mo(v)) }, c(amp = 0, mo = 0))
for (i in seq_along(GC_TA_GRID))
  cat(sprintf("  %10.4f %10.4f %8.2f%s\n", GC_TA_GRID[i], prof["amp", i], prof["mo", i],
              if (i == which.min(prof["amp", ])) "   <- MEASURED MINIMUM" else ""))
fmin <- min(prof["amp", ])
G1 <- abs(f0 - GC_G1_FLOOR) <= GC_G1_TOL * GC_G1_FLOOR &&
      abs(fmin - f0) <= GC_G1_MEASTOL * f0
cat(sprintf("\n  measured min %.4f vs closed form %.4f -> %+.1f %%   G1 -> %s\n",
            fmin, f0, 100 * (fmin / f0 - 1), if (G1) "PASS" else "FAIL"))
cat(sprintf("  ⇒ the model cannot cancel more than %.1f %% of its gross at ANY respiration\n",
            100 * (1 - f0 / amp(nep0))))
cat("    amplitude. CT2022 needs 74.9 %. [[sh_land_undercancels]]\n")

sep("2. G2 -- IS THE GROSS LINEAR, AND DOES ITS PHASE HOLD?")
cat(sprintf("  %8s %10s %8s %10s %10s %10s\n", "A", "a_NEP", "mo", "a_NEP/A", "theta deg", "floor"))
G <- lapply(GC_A_GRID, function(A) {
  bb <- gc_run(list(seas_npp_amp_SH = A))
  ne <- chan(bb, list(seas_npp_amp_SH = 0), list(seas_npp_amp_SH = A))
  re <- chan(bb, list(seas_T_amp_SH   = 0), list(seas_npp_amp_SH = A))
  th <- sep_dg(ne, re)
  list(A = A, a = amp(ne), mo = ang_mo(ne), th = th, fl = floor_of(amp(ne), th)) })
for (g in G)
  cat(sprintf("  %8.4f %10.4f %8.2f %10.4f %10.1f %10.4f%s\n", g$A, g$a, g$mo, g$a / g$A, g$th, g$fl,
              if (isTRUE(all.equal(g$A, GC_A_SHIP))) "   <- SHIPPED" else
              if (g$A == GC_A_CMIP6) "   <- CMIP6" else
              if (g$A == 0.352) "   <- 27j GPP end (INADMISSIBLE, control only)" else ""))
slopes <- vapply(G, function(g) g$a / g$A, 0)
mos    <- vapply(G, function(g) g$mo, 0)
lin_ok <- (max(slopes) - min(slopes)) / mean(slopes) <= GC_G2_LINTOL
mo_ok  <- (max(mos) - min(mos)) <= GC_G2_MODRIFT
cat(sprintf("\n  a_NEP/A spread %.2f %% (gate %.0f %%) -> %s | NEP phase drift %.3f mo (gate %.2f) -> %s\n",
            100 * (max(slopes) - min(slopes)) / mean(slopes), 100 * GC_G2_LINTOL,
            if (lin_ok) "PASS" else "FAIL", max(mos) - min(mos), GC_G2_MODRIFT,
            if (mo_ok) "PASS" else "FAIL"))
G2 <- lin_ok && mo_ok

sep("3. G3 -- THE STATISTIC: THE FLOOR AT THE CMIP6 GROSS vs THE OBSERVATION")
gC <- G[[which(vapply(G, function(g) g$A, 0) == GC_A_CMIP6)]]
cat(sprintf("  a_NEP(A=%.2f) = %.4f @ %.2f mo | theta %.1f deg | FLOOR %.4f\n",
            gC$A, gC$a, gC$mo, gC$th, gC$fl))
cat(sprintf("  observed SPO land %.3f\n", GC_G3_OBS))
G3_unreachable <- gC$fl > GC_G3_OBS
cat(sprintf("\n  floor %.4f %s obs %.3f  (registered prediction: ~1.19, UNREACHABLE)\n",
            gC$fl, if (G3_unreachable) ">" else "<=", GC_G3_OBS))
cat(sprintf("  G3 -> %s\n", if (G3_unreachable)
  "AMPLITUDES ALONE CANNOT CLOSE IT. The pair must be (gross, PHASE); a (gross, respiration)\n        2x2 is a GUARANTEED NULL and must NOT be pre-registered as one." else
  "REACHABLE on amplitudes -- the (gross, respiration) 2x2 is the next step as proposed."))

sep("4. G4 -- WHAT SEPARATION WOULD BE NEEDED (reported either way)")
need <- function(a) { s <- GC_G3_OBS / a
  if (s >= 1) NA else 180 - asin(s) * 180 / pi }
cat(sprintf("  %-28s %10s %10s %10s\n", "gross", "a_NEP", "theta need", "= mo apart"))
for (g in G[c(2, 4)]) {
  th <- need(g$a)
  cat(sprintf("  A = %-24.4f %10.4f %10.1f %10.2f\n", g$A, g$a, th, th / 30)) }
cat(sprintf("\n  the model HAS %.1f deg = %.2f mo. The gap is the specification for the next arm.\n",
            theta0, theta0 / 30))

sep("5. G5 -- IS THERE A LEVER ON THETA AT ALL?")
cat("  ⚠ CCX_SEAS_PHI_EFF['SH'] is a COMPILE-TIME constant in src/ccx_core.cpp -- reported,\n")
cat("    not swept. If nothing free moves theta, the phase is STRUCTURAL, not fittable.\n\n")
# ⛔ FIXED 2026-09-02: THIS BLOCK STILL SWEPT THE RETIRED SCALAR. `95e97ab` fixed
# section 5b's grid and MISSED G5's lever list, which named `seas_lag_p` -- a name
# `ccx_migrate_par_set()` now DROPS, so `pv0[["seas_lag_p"]]` is NULL and
# `prior_span()` died on a length-zero argument. (Before the migration was added
# above it did not die; it swept a legacy scalar beside a complete split, which
# the 09-02 contract now hard-errors on.) A LEVER IS A SETTER, NOT A NAME: each
# entry below says which FIELDS it writes and which parameter-table entry supplies
# its prior, so a split name can never be confused with a retired one again.
# [[split_name_must_hard_error]], [[intersect_is_a_silent_default]]
GC_LEVERS <- list(
  # the lag is swept NH = SH: the scalar SLICE through the split, which is the
  # pre-split model's one degree of freedom and the right slice for "is there a
  # lever at all". Its prior comes from _NH, and _SH carries the identical one.
  seas_lag_p = list(tab = "seas_lag_p_NH", at = function() ccx_seas_lag_p(pv0)[["NH"]],
                    set = function(x) list(seas_lag_p_NH = x, seas_lag_p_SH = x)),
  q10        = list(tab = "q10", at = function() pv0$q10,
                    set = function(x) list(q10 = x)))
# range from the PRIOR itself: where logprior falls 2 units off its own mode
prior_span <- function(lv) {
  tr <- CCX_PARAM_TABLE[[lv$tab]]$tr; pf <- CCX_PARAM_TABLE[[lv$tab]]$prior
  x_at <- lv$at()
  stopifnot(length(x_at) == 1L, is.finite(x_at))   # the length-zero this file hit
  x0 <- if (tr == "log") log(x_at) else x_at
  gr <- seq(x0 - 3, x0 + 3, length.out = 601); lp <- vapply(gr, pf, 0)
  keep <- gr[lp >= max(lp) - 2]
  v <- range(keep); if (tr == "log") exp(v) else v
}
cat(sprintf("  %-12s %10s %10s %10s %10s\n", "parameter", "value", "theta deg", "d theta", "d mo"))
G5 <- c()
for (nm in names(GC_LEVERS)) {
  lv <- GC_LEVERS[[nm]]; sp2 <- prior_span(lv); dth <- c()
  for (x in sp2) {
    mm <- lv$set(x)
    bb <- gc_run(mm)
    ne <- chan(bb, list(seas_npp_amp_SH = 0), mm)
    re <- chan(bb, list(seas_T_amp_SH   = 0), mm)
    th <- sep_dg(ne, re); dth <- c(dth, th)
    cat(sprintf("  %-12s %10.4f %10.1f %10.1f %10.3f\n", nm, x, th, th - theta0, (th - theta0) / 30))
  }
  G5[nm] <- (max(dth) - min(dth)) / 30 >= GC_G5_MOMIN
}
cat(sprintf("\n  moves theta by >= %.2f mo across its prior span: %s\n", GC_G5_MOMIN,
            paste(sprintf("%s %s", names(G5), ifelse(G5, "YES", "no")), collapse = " | ")))
cat(sprintf("  G5 -> %s\n", if (any(G5)) "a lever EXISTS -- name it in the next prereg" else
  "NO FREE PARAMETER MOVES THETA. The phase separation is STRUCTURAL: the next step is a\n        MODEL change (the SH land channels' timing), not a fit."))

sep("5b. G5 ANSWERED A MAGNITUDE QUESTION; THE QUESTION IS DIRECTIONAL")
# ⚠ NOT A GATE CHANGE. G5 stands exactly as pre-registered and is scored above.
# It asks whether theta MOVES; G4 shows what matters is whether theta can move UP,
# to >= 164.8 deg. Both prior-span ends came in BELOW the mode's 152.9, so this
# profiles the axis rather than inferring a direction from two points.
GC_LAG_GRID <- seq(0.5, 4.0, by = 0.25)
cat(sprintf("  %12s %10s %10s %10s %10s\n", "seas_lag_p", "theta deg", "a_NEP", "floor", "vs need"))
# ⛔ THIS SWEEP WAS FLAT UNTIL 2026-09-02 AND ITS PRINTED MAXIMUM WAS MEANINGLESS.
# It set the RETIRED scalar `seas_lag_p`, and ccx_seas_lag_p() resolved by silent
# PRECEDENCE -- the split fields, which ccx_default_params() always carries, won
# every time. So all 15 grid points ran at the same lag (2.25) and `x_max` below
# was read off a constant curve. ccx_seas_lag_p() now HARD-ERRORS on a list
# carrying both, so this can no longer happen quietly anywhere.
# ⚠ THE NUMBERS THIS FILE PRINTS FOR THE LAG AXIS THEREFORE CHANGED on 09-02.
# Every other section is untouched: they do not go through this assignment.
GC_LAG_SET <- GC_LEVERS$seas_lag_p$set   # ONE definition of "sweep the lag"
lagp <- lapply(GC_LAG_GRID, function(x) {
  bb <- gc_run(GC_LAG_SET(x))
  ne <- chan(bb, list(seas_npp_amp_SH = 0), GC_LAG_SET(x))
  re <- chan(bb, list(seas_T_amp_SH   = 0), GC_LAG_SET(x))
  th <- sep_dg(ne, re); list(x = x, th = th, a = amp(ne), fl = floor_of(amp(ne), th)) })
need_cmip6 <- 180 - asin(GC_G3_OBS / gC$a) * 180 / pi
for (g in lagp)
  cat(sprintf("  %12.2f %10.1f %10.4f %10.4f %10.1f%s\n", g$x, g$th, g$a, g$fl,
              g$th - need_cmip6,
              if (abs(g$x - ccx_seas_lag_p(pv0)[["NH"]]) < 0.13) "   <- THE MODE" else ""))
th_max <- max(vapply(lagp, function(g) g$th, 0))
x_max  <- lagp[[which.max(vapply(lagp, function(g) g$th, 0))]]$x
cat(sprintf("\n  max theta on this axis %.1f deg at seas_lag_p = %.2f; NEEDED at the CMIP6 gross %.1f\n",
            th_max, x_max, need_cmip6))
cat(sprintf("  ⇒ %s\n", if (th_max >= need_cmip6)
  "seas_lag_p CAN reach the needed separation -- it is the second member of the pair." else
  sprintf(paste("seas_lag_p CANNOT reach it -- short by %.1f deg (%.2f mo), and the mode already",
                "sits\n        within %.1f deg of this axis' maximum. The phase deficit is NOT",
                "reachable through\n        the fitted lag."), need_cmip6 - th_max,
          (need_cmip6 - th_max) / 30, th_max - theta0)))

sep("6. SCORED")
cat(sprintf("  G0 %s | G1 %s | G2 %s | G3 %s | G5 %s\n",
            ifelse(all(G0), "PASS", "FAIL"), ifelse(G1, "PASS", "FAIL"), ifelse(G2, "PASS", "FAIL"),
            ifelse(G3_unreachable, "UNREACHABLE", "reachable"),
            ifelse(any(G5), "lever exists", "NO LEVER")))
cat(sprintf("\n  ⇒ %s\n", if (G3_unreachable)
  "THE PAIR IS (GROSS, PHASE), NOT (GROSS, RESPIRATION AMPLITUDE)." else
  "THE PAIR IS (GROSS, RESPIRATION AMPLITUDE) -- pre-register the 2x2."))
cat("\n  ⚠ NOTHING HERE IS ADOPTED. seas_npp_amp_SH stays 0.5027 (status=\"data\"); every value\n")
cat("    outside a bracket is a MEASUREMENT under authorisation 2, not a fitted value.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(mode = basename(ccx_mode_file()), theta0 = theta0, nep0 = nep0, resp0 = resp0,
             land0 = land0, floor0 = f0, ta_grid = GC_TA_GRID, profile = prof,
             a_grid = GC_A_GRID, gross = G, cmip6 = gC, obs = GC_G3_OBS,
             unreachable = G3_unreachable, lever = G5, lag_profile = lagp,
             verdicts = list(G0 = G0, G1 = G1, G2 = G2, G3 = G3_unreachable, G5 = G5)),
        file.path(OUTDIR, "gross_cancellation_geometry.rds"))
cat(sprintf("\nwall clock %.1f min\nwritten: %s\n\n\n=== DONE ===\n",
            as.numeric(difftime(Sys.time(), t0, units = "mins")),
            file.path(OUTDIR, "gross_cancellation_geometry.rds")))
