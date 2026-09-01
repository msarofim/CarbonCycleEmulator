# =====================================================================
# diag_admissible_2x2_land_ocean.R -- THE 2x2 WITH THE ADMISSIBLE LEVER
#   seas_T_amp_SH x ent_seas_amp_SH, on the REPAIRED (q10-pinned) slice.
#
# PRE-REGISTERED: notes/prereg_2026-08-27q_admissible_2x2_land_ocean.md, committed
# (36e4051) BEFORE this file existed. Every gate below is copied from it unchanged.
# Do not edit a gate here without amending that note.
#
# THE CLAIM. 27j got INTERACTION +64.99 with `seas_npp_amp_SH`, which 27l then
# ruled INADMISSIBLE. 27p supplies the admissible replacement and shows the two
# levers produce the SAME DEFECT AT THE SAME PRICE: vacated 0.4489 vs 0.3828 ppm,
# marginal cost 193.0 vs 206.8 per ppm, sst_seas_amp_SH driven to z -9.68 vs -9.18.
# So this is a REPLICATION: does the channel repair the collapse the ADMISSIBLE
# lever causes, as it repaired the inadmissible one's?
#
# ⚠ 27o sec.6's motivation ("P6 -- the ocean limb still has room") is DEAD and is
# NOT reused. 27p falsified it: that room was the q10 leak.
#
# ⚠ UNLIKE 27j THE LAND LEVER IS A CALIBRATED PARAMETER, so pinning it REMOVES a
# d.o.f. The interaction still balances (5-4-6+5 = 0) -- that is why it is the
# statistic -- but the single-arm gaps are NOT comparable to 27j line for line.
#
# ⚠ THE BRACKET END IS A METHODOLOGICAL CHOICE, so it is MEASURED, not picked:
# LAND and JOINT run at BOTH the prior centre 5.0502 and HI 7.1012.
#
# ⚠ THE OFFSET IS NOW -1.5805, NOT -3.3223 (2026-08-28). Adopting the mode's
# own h_ml band removes the 1.7418 that was a WRONG DECODE; what remains is
# exactly the bounded refit's narrowed-prior constant, which is additive and
# cancels from every difference. [[ccx_hml_band_decode]]
# ⚠ NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE (offset -1.5805).
#
# Usage:  Rscript calibration/diag_admissible_2x2_land_ocean.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

AQ_YEARS <- c(1750, 2024)
# The REPAIRED slice: 27n's minus q10 (27p) and minus the profiled land lever.
AQ_BASE     <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_lag_p")
AQ_LAND_PAR <- "seas_T_amp_SH"      # free in INCUMBENT/OCEAN, PINNED in LAND/JOINT
AQ_BR_LO <- ccx_const("SEAS_T_AMP_SH_OBS_LO")   # 3.5915 K, all SH land
AQ_BR_HI <- ccx_const("SEAS_T_AMP_SH_OBS_HI")   # 7.1012 K, SH land >30S
AQ_MID   <- sqrt(AQ_BR_LO * AQ_BR_HI)           # 5.0502, the prior's centre (27n's TA_INIT)
AQ_PINS  <- c(mid = AQ_MID, hi = AQ_BR_HI)      # the two ends the prereg requires
AQ_ENT_BOUNDS <- c(0.5, 60)         # BOUNDS, not a prior -- 27j's, unchanged
AQ_ENT_INIT   <- 10                 # 27j's, unchanged
AQ_MAXIT <- 1500; AQ_RESTARTS <- 6; AQ_RESTOL <- 0.02
# ---- THE PRE-REGISTERED GATES, copied from prereg 27q sec.2. Fixed here so they
# ---- cannot drift to meet the answer. P0-P6 are 27j's OWN gates, unchanged.
AQ_P0_TOTAL  <- 1.141; AQ_P0_SHLAND <- 1.308
AQ_P0_NHORIG <- 0.821; AQ_P0_RATIO  <- 1.930; AQ_P0_OFFSET <- -1.5805
AQ_P1_FRAC   <- 0.5                 # 27j's JR_P1_FRAC
AQ_P2_BAND   <- c(5, 30)            # 27g's physical band
AQ_P3_RATIO  <- 1.70                # 27g's own unmet gate
AQ_P4_TOTAL  <- c(1.114, 1.222)
AQ_P5_OCEAN  <- 0.75
AQ_P6_MLO    <- c(0.90, 1.10)
AQ_P7_SSTSH  <- 0.26                # midpoint of 27p's 0.1553 collapse and 0.3663
AQ_P8_SHLAND <- 1.05                # 27p's S1, the ANTI-27n gate
AQ_OBS_TOTAL <- 1.168; AQ_OBS_LAND <- 0.683; AQ_OBS_OCEAN <- 0.522
AQ_SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
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
stopifnot(AQ_LAND_PAR %in% CCX_PARAM_NAMES, "q10" %in% CCX_PARAM_NAMES,
          CCX_PARAM_TABLE[[AQ_LAND_PAR]]$tr == "log")
stopifnot(!("ent_seas_amp_SH" %in% CCX_PARAM_NAMES))   # a base_param, not in `u`
i_at <- match(AQ_LAND_PAR, CCX_PARAM_NAMES); i_q <- match("q10", CCX_PARAM_NAMES)
i_base <- match(AQ_BASE, CCX_PARAM_NAMES); stopifnot(!anyNA(i_base))
stopifnot(!(i_at %in% i_base), !(i_q %in% i_base))
pv0 <- ccx_unc_to_par(u0); Q10_PIN <- pv0$q10

# One logpost builder per `ent`, which lives in base_params (not in CCX_PARAM_NAMES).
.cache <- new.env(parent = emptyenv())
lp_of <- function(ent) {
  k <- sprintf("%.6f", ent)
  if (is.null(.cache[[k]])) {
    bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode; bp$ent_seas_amp_SH <- ent
    .cache[[k]] <- ccx_make_logpost(years = AQ_YEARS, base_params = bp)
  }
  .cache[[k]]
}
one <- lp_of(0)(u0); gap <- one - md$logpost
cat(sprintf("mode %s (arm %s)\n", basename(ccx_mode_file()), md$pump_mode))
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f (known %.4f)\n",
            one, md$logpost, gap, AQ_P0_OFFSET))
cat(sprintf("q10 PINNED at the mode's %.5f in EVERY arm | base slice (%d): %s\n",
            Q10_PIN, length(AQ_BASE), paste(AQ_BASE, collapse = ", ")))
cat(sprintf("land lever %s: FREE in INCUMBENT/OCEAN, PINNED at %.4f (mid) / %.4f (hi)\n",
            AQ_LAND_PAR, AQ_PINS[["mid"]], AQ_PINS[["hi"]]))
cat(sprintf("ent bounds %g-%g (BOUNDS, not a prior), init %g\n",
            AQ_ENT_BOUNDS[1], AQ_ENT_BOUNDS[2], AQ_ENT_INIT))

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
  F  <- ccx_build_forcing("historical", AQ_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
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
AQ_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))
ratio_at <- function(b, st) {
  ao <- amp(obsv[[paste0("co2_", st)]]); do_ <- amp(obsv[[paste0("d13_", st)]])
  (amp(b[[paste0("d13_", st)]]) / amp(b[[paste0("co2_", st)]])) / (do_ / ao)
}
score <- function(pv, ent) {
  b <- run_at(pv, ent)
  d <- lapply(AQ_CASES, function(m) { v <- b$co2_SPO - run_at(pv, ent, m)$co2_SPO
                                      c(amp = amp(v), mo = ang_mo(v)) })
  list(total = c(amp = amp(b$co2_SPO), mo = ang_mo(b$co2_SPO)), dec = d,
       r_SPO = ratio_at(b, "SPO"), r_MLO = ratio_at(b, "MLO"), ll = b$ll)
}
# 27j's fit_arm, unchanged. 27h had to discard a run for a silent maxit, so every
# arm prints its restarts and last gain.
fit_arm <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = AQ_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200, reltol = 1e-12)),
              silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = AQ_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < AQ_RESTOL || n_re >= AQ_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain, converged = gain < AQ_RESTOL)
}
lo <- log(AQ_ENT_BOUNDS[1]); hi <- log(AQ_ENT_BOUNDS[2])

sep("0. P0 -- METHOD CONTROL. If this fails, nothing below is read.")
s0 <- score(pv0, 0)
p0  <- c(total = s0$total[["amp"]], shland = s0$dec$SH_land[["amp"]],
         nhorig = s0$dec$NH_origin[["amp"]], ratio = s0$r_SPO)
ex0 <- c(total = AQ_P0_TOTAL, shland = AQ_P0_SHLAND, nhorig = AQ_P0_NHORIG, ratio = AQ_P0_RATIO)
for (n in names(p0))
  cat(sprintf("  %-8s %8.3f  27j expected %8.3f  %s\n", n, p0[[n]], ex0[[n]],
              if (abs(p0[[n]] - ex0[[n]]) < 0.005 * abs(ex0[[n]])) "ok" else "⚠ MOVED"))
cat(sprintf("  %-8s %8.4f  27j expected %8.4f  %s\n", "offset", gap, AQ_P0_OFFSET,
            if (abs(gap - AQ_P0_OFFSET) < 0.5) "ok" else "⚠ MOVED"))
P0 <- all(abs(p0 - ex0) < 0.005 * abs(ex0)) && abs(gap - AQ_P0_OFFSET) < 0.5
cat(sprintf("\n  P0 -> %s\n", if (P0) "PASS" else "FAIL -- STOP, do not read below"))

sep("1. THE SIX ARMS")
# free_land: is seas_T_amp_SH in the slice?  pin: its value when it is not.
ARMS <- list(
  INCUMBENT  = list(free_land = TRUE,  pin = NA,             ent_free = FALSE),
  LAND_mid   = list(free_land = FALSE, pin = AQ_PINS[["mid"]], ent_free = FALSE),
  LAND_hi    = list(free_land = FALSE, pin = AQ_PINS[["hi"]],  ent_free = FALSE),
  OCEAN_only = list(free_land = TRUE,  pin = NA,             ent_free = TRUE),
  JOINT_mid  = list(free_land = FALSE, pin = AQ_PINS[["mid"]], ent_free = TRUE),
  JOINT_hi   = list(free_land = FALSE, pin = AQ_PINS[["hi"]],  ent_free = TRUE))
cat(sprintf("  %-11s %8s %7s | %10s | %9s %5s | %2s %8s\n", "arm", "a_t", "ent",
            "logpost", "vs u_mode", "npar", "re", "lastgain"))
res <- list()
for (nm in names(ARMS)) {
  A <- ARMS[[nm]]
  idx <- if (A$free_land) c(i_base, i_at) else i_base
  ua  <- u0; ua[i_q] <- log(Q10_PIN)                     # the q10 pin, every arm
  if (!A$free_land) ua[i_at] <- log(A$pin)               # the land pin
  v0  <- ua[idx]
  t0  <- Sys.time()
  if (A$ent_free) {
    objf <- function(v) {
      le <- v[length(v)]
      if (le < lo || le > hi) return(1e12)               # BOUNDS, not a prior
      u <- ua; u[idx] <- v[-length(v)]; -lp_of(round(exp(le), 6))(u)
    }
    ft  <- fit_arm(objf, c(v0, log(AQ_ENT_INIT)))
    ent <- exp(ft$par[length(ft$par)]); u_h <- ua; u_h[idx] <- ft$par[-length(ft$par)]
    npar <- length(idx) + 1
  } else {
    objf <- function(v) { u <- ua; u[idx] <- v; -lp_of(0)(u) }
    ft  <- fit_arm(objf, v0); ent <- 0; u_h <- ua; u_h[idx] <- ft$par; npar <- length(idx)
  }
  pv <- ccx_unc_to_par(u_h)
  stopifnot(abs(pv$q10 - Q10_PIN) < 1e-9)                # the pins HELD, not assumed
  if (!A$free_land) stopifnot(abs(pv[[AQ_LAND_PAR]] - A$pin) < 1e-9)
  res[[nm]] <- list(pin = A$pin, ent = ent, lp = -ft$value, u = u_h, pv = pv, npar = npar,
                    converged = ft$converged, restarts = ft$restarts, s = score(pv, ent),
                    secs = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  cat(sprintf("  %-11s %8.4f %7.3f | %10.3f | %+9.2f %5d | %2d %8.4f%s\n", nm,
              pv[[AQ_LAND_PAR]], ent, -ft$value, -ft$value - one, npar, ft$restarts,
              ft$last_gain, if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}
cat(sprintf("\n  wall clock per arm (s): %s\n",
            paste(sprintf("%.0f", vapply(res, function(x) x$secs, 0)), collapse = ", ")))

sep("2. P1 -- THE TWO INTERACTIONS, both parameter-balanced")
L <- vapply(res, function(r) r$lp, 0)
P1 <- c(); INT <- c()
for (e in c("mid", "hi")) {
  ln <- paste0("LAND_", e); jn <- paste0("JOINT_", e)
  inter <- L[[jn]] - L[[ln]] - L[["OCEAN_only"]] + L[["INCUMBENT"]]
  nb <- res[[jn]]$npar - res[[ln]]$npar - res$OCEAN_only$npar + res$INCUMBENT$npar
  lc <- L[["INCUMBENT"]] - L[[ln]]; gt <- AQ_P1_FRAC * abs(lc)
  cat(sprintf("\n  --- a_t = %.4f (%s) ---\n", res[[ln]]$pin, e))
  cat(sprintf("  npar: %d - %d - %d + %d = %d  (must be 0)\n", res[[jn]]$npar, res[[ln]]$npar,
              res$OCEAN_only$npar, res$INCUMBENT$npar, nb))
  cat(sprintf("  LAND  vs incumbent: %+9.2f | OCEAN vs incumbent: %+9.2f | JOINT: %+9.2f\n",
              L[[ln]] - L[["INCUMBENT"]], L[["OCEAN_only"]] - L[["INCUMBENT"]],
              L[[jn]] - L[["INCUMBENT"]]))
  cat(sprintf("  sum of the two singles: %+9.2f\n",
              (L[[ln]] - L[["INCUMBENT"]]) + (L[["OCEAN_only"]] - L[["INCUMBENT"]])))
  cat(sprintf("  INTERACTION = %+.2f   (gate >= %.2f = %.1f x the %.2f land cost)  -> %s\n",
              inter, gt, AQ_P1_FRAC, lc, if (inter >= gt) "PASS" else "FAIL"))
  stopifnot(nb == 0)
  P1[e] <- inter >= gt; INT[e] <- inter
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
                res[[jn]]$ent >= AQ_P2_BAND[1] && res[[jn]]$ent <= AQ_P2_BAND[2],
                sprintf("%g-%g", AQ_P2_BAND[1], AQ_P2_BAND[2]))
  v["P3"] <- vg("P3  SPO d13C-per-ppm", J$r_SPO, J$r_SPO <= AQ_P3_RATIO,
                sprintf("<= %.2f", AQ_P3_RATIO))
  v["P4"] <- vg("P4  SPO total (obs 1.168)", J$total[["amp"]],
                J$total[["amp"]] >= AQ_P4_TOTAL[1] && J$total[["amp"]] <= AQ_P4_TOTAL[2],
                sprintf("%.3f-%.3f", AQ_P4_TOTAL[1], AQ_P4_TOTAL[2]))
  v["P5"] <- vg("P5  SPO ocean ratio", J$dec$SH_ocean[["amp"]] / AQ_OBS_OCEAN,
                J$dec$SH_ocean[["amp"]] / AQ_OBS_OCEAN >= AQ_P5_OCEAN,
                sprintf(">= %.2f", AQ_P5_OCEAN))
  v["P6"] <- vg("P6  MLO control d13C-per-ppm", J$r_MLO,
                J$r_MLO >= AQ_P6_MLO[1] && J$r_MLO <= AQ_P6_MLO[2],
                sprintf("%.2f-%.2f", AQ_P6_MLO[1], AQ_P6_MLO[2]))
  v["P7"] <- vg("P7  sst_seas_amp_SH recovered", res[[jn]]$pv$sst_seas_amp_SH,
                res[[jn]]$pv$sst_seas_amp_SH >= AQ_P7_SSTSH, sprintf(">= %.2f", AQ_P7_SSTSH))
  v["P8"] <- vg("P8  JOINT SH-land (anti-27n)", J$dec$SH_land[["amp"]],
                J$dec$SH_land[["amp"]] <= AQ_P8_SHLAND, sprintf("<= %.2f", AQ_P8_SHLAND))
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
            "OBSERVED", AQ_OBS_TOTAL, "", AQ_OBS_LAND, "", AQ_OBS_OCEAN, 8.52, "", "", 1.000))
cat("\n  the scored seasonal rows, each arm minus the INCUMBENT:\n")
cat(sprintf("  %-11s", "arm")); for (n in AQ_SEAS_ROWS) cat(sprintf(" %13s", substr(n, 1, 13)))
cat("\n")
for (nm in names(res)) { cat(sprintf("  %-11s", nm))
  for (n in AQ_SEAS_ROWS) cat(sprintf(" %+13.2f", res[[nm]]$s$ll[[n]] - res$INCUMBENT$s$ll[[n]]))
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

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(base = AQ_BASE, land_par = AQ_LAND_PAR, pins = AQ_PINS, q10_pin = Q10_PIN,
             harness_at_u_mode = one, harness_offset = gap, res = res,
             interaction = INT, verdicts = list(P0 = P0, P1 = P1, phys = V)),
        file.path(OUTDIR, "admissible_2x2_land_ocean.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "admissible_2x2_land_ocean.rds")))
