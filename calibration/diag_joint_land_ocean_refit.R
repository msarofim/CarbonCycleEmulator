# =====================================================================
# diag_joint_land_ocean_refit.R -- IS THE SPO SEASONAL PARTITION ONE FIX?
#                                  A 2x2 WITH A PARAMETER-BALANCED
#                                  INTERACTION TERM.
#
# PRE-REGISTERED: notes/prereg_2026-08-27j_joint_land_ocean_arm.md, written and
# committed (fa83faa) BEFORE this file existed. Every gate below is copied from
# it unchanged. Do not edit a gate in this file without amending that note.
#
# THE CLAIM. Two experiments have each moved ONE half of SPO's seasonal cycle
# and each been charged for breaking a cancellation: 27g moved the OCEAN (the
# entrainment channel worked, but the fit spent it as a counterweight, +11.62)
# and 27i moved the LAND (the GPP end closes 67 % of the land excess and the
# d13C row IMPROVES +2.99, but it costs -79.01, essentially all of it in
# `co2_seasonal_SPO`). The model's SPO total is right BY CANCELLATION -- 1.141
# against an observed 1.168, from land 1.92x too big and ocean 0.45x too small,
# ~5 months apart. So: ONE fix, not two, and the joint arm should beat the sum.
#
# ⇒ THE HEADLINE IS THE INTERACTION, AND IT IS PARAMETER-BALANCED:
#     INTERACTION = JOINT - LAND_only - OCEAN_only + INCUMBENT
#   counts 7 - 6 - 7 + 6 = 0. A bare challenger-minus-incumbent Dlogpost is NOT
#   a model comparison here -- `ent_seas_amp_SH` is a free scalar with no prior,
#   which is exactly why 27g refused to read one. This contrast holds the count
#   fixed and IS interpretable. It is the reason for four arms instead of two.
#
# ⚠ `seas_npp_amp_SH` IS FIXED, NOT FITTED, in every arm. It is a MEASURED
# CONSTANT moved to the far end of its own measured bracket (PsnNet 0.5027 sd
# 0.087 vs GPP 0.352 = -1.73 sd). It adds no degree of freedom. Whether the
# model is ENTITLED to that end of a 1.4x product disagreement is a separate
# question Marcus has flagged and this run does not settle.
#
# ⚠ NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE. The harness sits
# -3.3223 below it, pre-existing ([[ccx_mode_logpost_offset]]). Everything here
# is a difference within this harness.
#
# Usage:  Rscript calibration/diag_joint_land_ocean_refit.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

JR_YEARS <- c(1750, 2024)
# 27g's RF_BLOCK, UNCHANGED, so the arms are comparable to that run. tau_ex is
# deliberately absent: 27h measured it inert on the SPO total (-1.7 % over an 8x
# range) and unaffordable. So are the gradient offsets, for the same reason.
JR_BLOCK <- c("sst_seas_amp_NH", "sst_seas_amp_SH",
              "seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p", "q10")
JR_LAND_PSNNET <- ccx_const("SEAS_NPP_AMP_SH")   # 0.5027, shipped
JR_LAND_GPP    <- 0.352                          # the other end of the bracket
JR_ENT_BOUNDS  <- c(0.5, 60)                     # BOUNDS, not a prior
JR_ENT_INIT    <- 10
JR_MAXIT       <- 1500
JR_RESTARTS    <- 6
JR_RESTOL      <- 0.02
# ---- THE PRE-REGISTERED GATES, copied from prereg 27j. Fixed here so they
# ---- cannot drift to meet the answer.
JR_P0_TOTAL   <- 1.141    # incumbent SPO total, measured 27h/27i
JR_P0_SHLAND  <- 1.308
JR_P0_NHORIG  <- 0.821
JR_P0_RATIO   <- 1.930
JR_P0_OFFSET  <- -3.3223
JR_P1_FRAC    <- 0.5      # interaction >= this x |LAND-only cost|
JR_P2_BAND    <- c(5, 30) # the 27g physical pre-check band for the channel
JR_P3_RATIO   <- 1.70     # 27g's OWN unmet P4 gate, reused unchanged
JR_P4_TOTAL   <- c(1.114, 1.222)   # 2x the incumbent's own 0.027 miss
JR_P5_OCEAN   <- 0.75     # ocean ratio, from 0.45x at the mode
JR_P6_MLO     <- c(0.90, 1.10)     # 27g's own MLO control gate
JR_OBS_TOTAL  <- 1.168
JR_OBS_LAND   <- 0.683
JR_OBS_OCEAN  <- 0.522
JR_SEAS_ROWS  <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                   "d13c_seasonal_MLO", "d13c_seasonal_SPO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(ccx_mode_file())
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
idx <- match(JR_BLOCK, CCX_PARAM_NAMES); stopifnot(!anyNA(idx))
stopifnot(!("seas_npp_amp_SH" %in% CCX_PARAM_NAMES),
          !("ent_seas_amp_SH" %in% CCX_PARAM_NAMES))

cat(sprintf("mode %s (arm %s) | slice: %s\n", basename(ccx_mode_file()), md$pump_mode,
            paste(JR_BLOCK, collapse = ", ")))
cat(sprintf("land: PsnNet %.4f vs GPP %.4f (%+.2f sd at sd 0.087) | ent bounds %g-%g\n",
            JR_LAND_PSNNET, JR_LAND_GPP, (JR_LAND_GPP - JR_LAND_PSNNET) / 0.087,
            JR_ENT_BOUNDS[1], JR_ENT_BOUNDS[2]))

# One logpost builder per (land, ent) pair; both live in base_params because
# neither is in CCX_PARAM_NAMES and so neither can ride in `u`.
.cache <- new.env(parent = emptyenv())
lp_of <- function(land, ent) {
  k <- sprintf("%.6f_%.6f", land, ent)
  if (is.null(.cache[[k]])) {
    bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
    bp$seas_npp_amp_SH <- land; bp$ent_seas_amp_SH <- ent
    .cache[[k]] <- ccx_make_logpost(years = JR_YEARS, base_params = bp)
  }
  .cache[[k]]
}
one <- lp_of(JR_LAND_PSNNET, 0)(u0)
gap <- one - md$logpost
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f\n",
            one, md$logpost, gap))

obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
amp    <- function(v) 2 * sqrt(sum(v^2))          # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
obsv <- list(co2_SPO = vec_of(pick(obs, "co2_seas.SPO")),
             d13_SPO = vec_of(pick(obs, "d13_seas.SPO")),
             co2_MLO = vec_of(pick(obs, "co2_seas.MLO")),
             d13_MLO = vec_of(pick(obs, "d13_seas.MLO")))

# ⚠ bomb_total / luc_scale off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
run_at <- function(pv, land, ent, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  p$seas_npp_amp_SH <- land; p$ent_seas_amp_SH <- ent
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", JR_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o  <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(o, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")), d13_SPO = vec_of(pick(ms, "d13_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")), d13_MLO = vec_of(pick(ms, "d13_seas.MLO")),
       ll = unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                           grad_off_co2 = pv$grad_off_co2,
                                           grad_off_d13c = pv$grad_off_d13c),
                              luc = ccx_forcing_eluc_annual(F),
                              deep = sp$diagnostics$d14c_bottom_box,
                              ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)))
}
# ⚠ the ocean case kills BOTH SH limbs. sst_seas_amp_SH = 0 alone leaves the
# entrainment limb running -- the bug found in the older scripts on 27g.
JR_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))
ratio_at <- function(b, st) {
  ao <- amp(obsv[[paste0("co2_", st)]]); do_ <- amp(obsv[[paste0("d13_", st)]])
  am <- amp(b[[paste0("co2_", st)]]);    dm  <- amp(b[[paste0("d13_", st)]])
  (dm / am) / (do_ / ao)
}
score <- function(pv, land, ent) {
  b <- run_at(pv, land, ent)
  d <- lapply(JR_CASES, function(m) { v <- b$co2_SPO - run_at(pv, land, ent, m)$co2_SPO
                                      c(amp = amp(v), mo = ang_mo(v)) })
  list(total = c(amp = amp(b$co2_SPO), mo = ang_mo(b$co2_SPO)), dec = d,
       r_SPO = ratio_at(b, "SPO"), r_MLO = ratio_at(b, "MLO"), ll = b$ll)
}

# Nelder-Mead, BFGS polish, restarts until the improvement dies. 27h had to
# discard a run for a silent maxit; every arm prints its restarts and last gain.
fit_arm <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead",
              control = list(maxit = JR_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS",
                    control = list(maxit = 200, reltol = 1e-12)), silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead",
                control = list(maxit = JR_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < JR_RESTOL || n_re >= JR_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain,
       converged = gain < JR_RESTOL)
}
lo <- log(JR_ENT_BOUNDS[1]); hi <- log(JR_ENT_BOUNDS[2])

sep("0. P0 -- METHOD CONTROL. If this fails, nothing below is read.")
s0 <- score(ccx_unc_to_par(u0), JR_LAND_PSNNET, 0)
p0 <- c(total = s0$total[["amp"]], shland = s0$dec$SH_land[["amp"]],
        nhorig = s0$dec$NH_origin[["amp"]], ratio = s0$r_SPO)
exp0 <- c(total = JR_P0_TOTAL, shland = JR_P0_SHLAND, nhorig = JR_P0_NHORIG,
          ratio = JR_P0_RATIO)
for (n in names(p0))
  cat(sprintf("  %-8s %8.3f  expected %8.3f  %s\n", n, p0[[n]], exp0[[n]],
              if (abs(p0[[n]] - exp0[[n]]) < 0.005 * abs(exp0[[n]])) "ok" else "⚠ MOVED"))
cat(sprintf("  %-8s %8.4f  expected %8.4f  %s\n", "offset", gap, JR_P0_OFFSET,
            if (abs(gap - JR_P0_OFFSET) < 0.5) "ok" else "⚠ MOVED"))
P0 <- all(abs(p0 - exp0) < 0.005 * abs(exp0)) && abs(gap - JR_P0_OFFSET) < 0.5
cat(sprintf("\n  P0 -> %s\n", if (P0) "PASS" else "FAIL -- STOP, do not read below"))

sep("1. THE FOUR ARMS")
ARMS <- list(
  INCUMBENT  = list(land = JR_LAND_PSNNET, ent_free = FALSE),
  LAND_only  = list(land = JR_LAND_GPP,    ent_free = FALSE),
  OCEAN_only = list(land = JR_LAND_PSNNET, ent_free = TRUE),
  JOINT      = list(land = JR_LAND_GPP,    ent_free = TRUE))
cat(sprintf("  %-11s %8s %6s | %10s | %8s %8s | %2s %8s\n", "arm", "land", "ent",
            "logpost", "vs u_mode", "npar", "re", "lastgain"))
res <- list()
for (nm in names(ARMS)) {
  A <- ARMS[[nm]]
  if (A$ent_free) {
    objf <- function(v) {
      le <- v[length(v)]
      if (le < lo || le > hi) return(1e12)      # BOUNDS, not a prior
      -lp_of(A$land, round(exp(le), 6))(replace(u0, idx, v[-length(v)]))
    }
    ft <- fit_arm(objf, c(u0[idx], log(JR_ENT_INIT)))
    ent <- exp(ft$par[length(ft$par)]); u_h <- replace(u0, idx, ft$par[-length(ft$par)])
    npar <- length(idx) + 1
  } else {
    objf <- function(v) -lp_of(A$land, 0)(replace(u0, idx, v))
    ft <- fit_arm(objf, u0[idx])
    ent <- 0; u_h <- replace(u0, idx, ft$par); npar <- length(idx)
  }
  pv <- ccx_unc_to_par(u_h)
  res[[nm]] <- list(land = A$land, ent = ent, lp = -ft$value, u = u_h, pv = pv,
                    npar = npar, converged = ft$converged, restarts = ft$restarts,
                    s = score(pv, A$land, ent))
  cat(sprintf("  %-11s %8.4f %6.2f | %10.3f | %+8.2f %8d | %2d %8.4f%s\n", nm, A$land, ent,
              -ft$value, -ft$value - one, npar, ft$restarts, ft$last_gain,
              if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}

sep("2. P1 -- THE INTERACTION, and it is parameter-balanced")
L <- vapply(res, function(r) r$lp, 0)
inter <- L[["JOINT"]] - L[["LAND_only"]] - L[["OCEAN_only"]] + L[["INCUMBENT"]]
land_cost <- L[["INCUMBENT"]] - L[["LAND_only"]]
gate <- JR_P1_FRAC * abs(land_cost)
cat(sprintf("  npar: JOINT %d - LAND %d - OCEAN %d + INCUMBENT %d = %d  (must be 0)\n",
            res$JOINT$npar, res$LAND_only$npar, res$OCEAN_only$npar, res$INCUMBENT$npar,
            res$JOINT$npar - res$LAND_only$npar - res$OCEAN_only$npar + res$INCUMBENT$npar))
cat(sprintf("\n  LAND-only  vs incumbent: %+9.2f\n", L[["LAND_only"]]  - L[["INCUMBENT"]]))
cat(sprintf("  OCEAN-only vs incumbent: %+9.2f\n", L[["OCEAN_only"]] - L[["INCUMBENT"]]))
cat(sprintf("  JOINT      vs incumbent: %+9.2f\n", L[["JOINT"]]      - L[["INCUMBENT"]]))
cat(sprintf("  sum of the two singles : %+9.2f\n",
            (L[["LAND_only"]] - L[["INCUMBENT"]]) + (L[["OCEAN_only"]] - L[["INCUMBENT"]])))
cat(sprintf("\n  INTERACTION = %+.2f   (gate: >= %.2f = %.1f x the %.2f land-only cost)\n",
            inter, gate, JR_P1_FRAC, land_cost))
P1 <- inter >= gate
cat(sprintf("  P1 -> %s\n", if (P1) "CONFIRMED -- the two corrections ARE one fix" else
  "FALSIFIED -- the channel cannot supply what the land reduction vacates.\n        THAT IS THE FINDING: 4b becomes the live question."))

sep("3. P2-P6 -- THE PHYSICAL SCORECARD")
J <- res$JOINT$s
cat(sprintf("  %-34s %10s %10s %s\n", "prediction", "value", "gate", "verdict"))
vg <- function(lab, v, ok, gate) {
  cat(sprintf("  %-34s %10.3f %10s %s\n", lab, v, gate, if (ok) "PASS" else "FAIL")); ok }
P2 <- vg("P2  ent_seas_amp_SH in band", res$JOINT$ent,
         res$JOINT$ent >= JR_P2_BAND[1] && res$JOINT$ent <= JR_P2_BAND[2],
         sprintf("%g-%g", JR_P2_BAND[1], JR_P2_BAND[2]))
P3 <- vg("P3  SPO d13C-per-ppm", J$r_SPO, J$r_SPO <= JR_P3_RATIO,
         sprintf("<= %.2f", JR_P3_RATIO))
P4 <- vg("P4  SPO total (obs 1.168)", J$total[["amp"]],
         J$total[["amp"]] >= JR_P4_TOTAL[1] && J$total[["amp"]] <= JR_P4_TOTAL[2],
         sprintf("%.3f-%.3f", JR_P4_TOTAL[1], JR_P4_TOTAL[2]))
P5 <- vg("P5  SPO ocean ratio", J$dec$SH_ocean[["amp"]] / JR_OBS_OCEAN,
         J$dec$SH_ocean[["amp"]] / JR_OBS_OCEAN >= JR_P5_OCEAN,
         sprintf(">= %.2f", JR_P5_OCEAN))
P6 <- vg("P6  MLO control d13C-per-ppm", J$r_MLO,
         J$r_MLO >= JR_P6_MLO[1] && J$r_MLO <= JR_P6_MLO[2],
         sprintf("%.2f-%.2f", JR_P6_MLO[1], JR_P6_MLO[2]))

sep("4. WHERE EVERY ARM LANDS")
cat(sprintf("  %-11s %8s %6s | %8s %6s | %8s %6s | %8s %6s | %7s %7s\n", "arm", "total",
            "mo", "SH-land", "mo", "SH-ocn", "mo", "NH-orig", "mo", "SPO r", "MLO r"))
for (nm in names(res)) {
  s <- res[[nm]]$s
  cat(sprintf("  %-11s %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %7.3f %7.3f\n",
              nm, s$total[["amp"]], s$total[["mo"]], s$dec$SH_land[["amp"]], s$dec$SH_land[["mo"]],
              s$dec$SH_ocean[["amp"]], s$dec$SH_ocean[["mo"]],
              s$dec$NH_origin[["amp"]], s$dec$NH_origin[["mo"]], s$r_SPO, s$r_MLO))
}
cat(sprintf("  %-11s %8.3f %6s | %8.3f %6s | %8.3f %6.2f | %8s %6s | %7.3f %7s\n",
            "OBSERVED", JR_OBS_TOTAL, "", JR_OBS_LAND, "", JR_OBS_OCEAN, 8.52, "", "", 1.000, ""))

cat("\n  the scored seasonal rows, each arm minus the incumbent:\n")
cat(sprintf("  %-11s", "arm")); for (n in JR_SEAS_ROWS) cat(sprintf(" %13s", substr(n, 1, 13)))
cat("\n")
for (nm in names(res)) {
  cat(sprintf("  %-11s", nm))
  for (n in JR_SEAS_ROWS)
    cat(sprintf(" %+13.2f", res[[nm]]$s$ll[[n]] - res$INCUMBENT$s$ll[[n]]))
  cat("\n")
}

sep("5. SCORED")
cat(sprintf("  P0 %s | P1 %s | P2 %s | P3 %s | P4 %s | P5 %s | P6 %s\n",
            ifelse(P0, "PASS", "FAIL"), ifelse(P1, "PASS", "FAIL"), ifelse(P2, "PASS", "FAIL"),
            ifelse(P3, "PASS", "FAIL"), ifelse(P4, "PASS", "FAIL"), ifelse(P5, "PASS", "FAIL"),
            ifelse(P6, "PASS", "FAIL")))
cat(sprintf("\n  ⇒ %s\n", if (!P0) "P0 FAILED -- the run is not readable." else
  if (P1 && P2 && P3 && P4 && P5 && P6) "ONE FIX, CONFIRMED on every pre-registered gate." else
  if (P1) "The INTERACTION holds; not every physical gate does. Read sec.3 and 4 before quoting." else
  "P1 FALSIFIED. The channel cannot supply what the land reduction vacates -- 4b is now the live question."))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(block = JR_BLOCK, land = c(psnnet = JR_LAND_PSNNET, gpp = JR_LAND_GPP),
             harness_at_u_mode = one, harness_offset = gap, res = res,
             interaction = inter, land_cost = land_cost, gate = gate,
             verdicts = c(P0 = P0, P1 = P1, P2 = P2, P3 = P3, P4 = P4, P5 = P5, P6 = P6)),
        file.path(OUTDIR, "joint_land_ocean_refit.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "joint_land_ocean_refit.rds")))
