# =====================================================================
# diag_seas_slice_q10_pin.R -- DID THE CONDITIONAL SLICE LEAK THE LEVER
#                              THROUGH q10?  A SLICE-REPAIR CONTROL.
#
# PRE-REGISTERED: notes/prereg_2026-08-27p_q10_pin_slice_repair.md, committed
# (a92aa5f) BEFORE this file existed. Every gate below is copied from it
# unchanged. Do not edit a gate here without amending that note.
#
# THE FINDING THIS TESTS. 27o sec.7 called the (seas_T_amp_NH, q10) ridge a
# SLOWNESS problem. Reading 27n's stored rds says it is worse: the NH product
# seas_T_amp_NH * ln(q10) is held to 0.03 % across all four conditional points
# while its factors move 2.77x and 3.7x in ln-space -- and q10 is SHARED WITH
# THE SH, so riding that ridge cancels the SH perturbation. The SH product rose
# only 2.48x where a pinned q10 gives 6.83x: THE ARM DELIVERED 36 % OF ITS OWN
# LEVER, and seas_T_amp_NH ran to 79.35 K = 443 % of its measured HIGH end.
#
# R/model.R:194-195 already says only the product A_T * ln(q10) is identified at
# small amplitude. This is the DOCUMENTED degeneracy acting as an escape route.
#
# THE REPAIR. Pin q10 at the MODE and leave seas_T_amp_NH free. The NH product
# still spans its whole range through seas_T_amp_NH alone, so nothing the
# seasonal rows identify is removed; what is removed is q10's nonlinear part and
# its cross-timescale duty (model.R:1086), which the LEVEL rows and
# gcb_land_sink identify and a seasonal arm has no business dragging. S0 prices
# the pin; S5 is the pin's own risk.
#
# ⚠ THIS IS A CONTROL, NOT AN ARM. It cannot rehabilitate seas_T_amp_SH -- the
# FULL-FROZEN cost at bracket HI is -204.45 and that veto is untouched.
# ⚠ THE OFFSET IS NOW -1.5805, NOT -3.3223 (2026-08-28). Adopting the mode's
# own h_ml band removes the 1.7418 that was a WRONG DECODE; what remains is
# exactly the bounded refit's narrowed-prior constant, which is additive and
# cancels from every difference. [[ccx_hml_band_decode]]
# ⚠ NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE (offset -1.5805).
#
# Usage:  Rscript calibration/diag_seas_slice_q10_pin.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

QP_YEARS <- c(1750, 2024)
# --- the two slices. The ONLY difference is q10.
QP_SLICE_PIN  <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_lag_p")
QP_SLICE_FREE <- c(QP_SLICE_PIN, "q10")
QP_PROFILED   <- "seas_T_amp_SH"          # out of BOTH slices, as in 27n
QP_GRID       <- c(1.0391, 3.5915, 5.0502, 7.1012)   # 27n's TA_COND, unchanged
QP_LO <- ccx_const("SEAS_T_AMP_SH_OBS_LO"); QP_HI <- ccx_const("SEAS_T_AMP_SH_OBS_HI")
QP_NH_HI <- ccx_const("SEAS_T_AMP_NH_OBS_HI")        # 17.92 K, for the S2 label
QP_MAXIT <- 1500; QP_RESTARTS <- 6; QP_RESTOL <- 0.02
QP_OBS_SPO_LAND <- 0.683                  # inversion at the mode, 27h
QP_OFFSET <- -1.5805                      # [[ccx_mode_logpost_offset]]
QP_COST_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO",
                  "d13c_seasonal_SPO", "co2_level_MLO", "co2_level_SPO",
                  "d13c_level_MLO", "d13c_level_SPO", "gcb_land_sink",
                  "co2_gradient", "d13c_gradient")
# --- 27n's MEASURED free-slice results, the comparison set. NOT recomputed.
QP_FREE_RDS    <- ccx_path("outputs", "diagnostics", "seas_T_amp_sh_power.rds")
# --- THE PRE-REGISTERED GATES, copied from prereg 27p sec.3.
QP_S0_BAND     <- c(-5.00, 0.00)  # pinned minus free at the LANDED point
QP_S1_SHLAND   <- 1.05            # pinned SH-land at HI must be <= this
QP_S1_FROZEN   <- 0.8728          # the full-frozen SH-land at HI, 27n
QP_S1_FREE     <- 1.2256          # the free-slice SH-land at HI, 27n
QP_S2_NH       <- 30.0            # pinned seas_T_amp_NH at HI, K
QP_S2_FREE_NH  <- 79.3466
QP_S3_FREE_DLP <- -33.68          # 27n's free conditional dlp at HI
QP_S4_FRAC     <- 0.60            # co2_seasonal_SPO share of the pinned cost
QP_S5_FRAC     <- 0.25            # gcb_land_sink share, the pin's own risk

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
stopifnot(QP_PROFILED %in% CCX_PARAM_NAMES, "q10" %in% CCX_PARAM_NAMES)
stopifnot(CCX_PARAM_TABLE[[QP_PROFILED]]$tr == "log", CCX_PARAM_TABLE$q10$tr == "log")
i_at <- match(QP_PROFILED, CCX_PARAM_NAMES)
i_q  <- match("q10", CCX_PARAM_NAMES)
pv0  <- ccx_unc_to_par(u0)
Q10_PIN <- pv0$q10                  # the MODE's q10, not any conditional landing

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(years = QP_YEARS, base_params = bp)
u_at <- function(u, a) { u[i_at] <- log(a); u }
one  <- lp(u0)

cat(sprintf("mode %s (arm %s)\n", basename(ccx_mode_file()), md$pump_mode))
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f (known %.4f)\n",
            one, md$logpost, one - md$logpost, QP_OFFSET))
if (abs((one - md$logpost) - QP_OFFSET) > 0.5)
  cat("  ⚠ THE OFFSET HAS MOVED. Investigate BEFORE reading this run.\n")
cat(sprintf("q10 PINNED at the mode's %.5f | seas_T_amp_NH mode %.4f (measured HI %.4f = %.0f %%)\n",
            Q10_PIN, pv0$seas_T_amp_NH, QP_NH_HI, 100 * pv0$seas_T_amp_NH / QP_NH_HI))
cat(sprintf("pinned slice (%d free): %s\n", length(QP_SLICE_PIN),
            paste(QP_SLICE_PIN, collapse = ", ")))
cat(sprintf("27n free slice (%d free): %s\n", length(QP_SLICE_FREE),
            paste(QP_SLICE_FREE, collapse = ", ")))
cat(sprintf("profiled, out of BOTH: %s | grid %s\n", QP_PROFILED,
            paste(sprintf("%.4f", QP_GRID), collapse = ", ")))

obs  <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
.forcing_for <- function(pv, sp) {
  F <- ccx_build_forcing("historical", QP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  F
}
.params_for <- function(pv, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  p
}
run_at <- function(pv, mods = list()) {
  sp <- ccx_spinup(.params_for(pv, mods)); F <- .forcing_for(pv, sp)
  ms <- ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")), d13_SPO = vec_of(pick(ms, "d13_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")), d13_MLO = vec_of(pick(ms, "d13_seas.MLO")))
}
# ⚠ THE PER-STREAM BREAKDOWN COMES FROM ccx_loglik(by_stream = TRUE), NOT from an
# attribute on the logpost. 27n's first driver probed attr(lp(u), "streams"), got
# NULL, and SKIPPED its own diagnostic gate while printing a tidy "unavailable"
# line. A gate that silently declines to run is worse than one that fails.
# [[mutation_test_gates]]
streams_at <- function(pv) {
  sp <- ccx_spinup(.params_for(pv)); F <- .forcing_for(pv, sp)
  o  <- ccx_run_fast(sp, F)$out
  s <- unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                      grad_off_co2 = pv$grad_off_co2,
                                      grad_off_d13c = pv$grad_off_d13c),
                         luc = ccx_forcing_eluc_annual(F),
                         deep = sp$diagnostics$d14c_bottom_box,
                         ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
  stopifnot(is.numeric(s), length(s) > 1, all(QP_COST_ROWS %in% names(s)))  # gate it
  s
}
QP_CASES <- list(SH_land = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
                 SH_resp = list(seas_T_amp_SH = 0))
obsv <- list(co2_SPO = vec_of(pick(obs, "co2_seas.SPO")),
             d13_SPO = vec_of(pick(obs, "d13_seas.SPO")))
ratio_SPO <- function(b) (amp(b$d13_SPO)/amp(b$co2_SPO)) / (amp(obsv$d13_SPO)/amp(obsv$co2_SPO))

fit_block <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = QP_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200, reltol = 1e-12)),
              silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = QP_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < QP_RESTOL || n_re >= QP_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain, converged = gain < QP_RESTOL)
}

# ---------------------------------------------------------------------
sep("0. THE FREE-SLICE RESULT BEING COMPARED TO -- read, not recomputed")
stopifnot(file.exists(QP_FREE_RDS))
fr <- readRDS(QP_FREE_RDS)
lp_free_ref <- fr$cond[["1.0391"]]$lp
cat(sprintf("  %8s | %11s %9s %8s | %9s %9s %11s\n", "a_t", "free dlp", "SH-land",
            "xobs", "q10", "sTaNH", "SH product"))
for (k in names(fr$cond)) { c1 <- fr$cond[[k]]; p <- c1$pv
  cat(sprintf("  %8s | %+11.2f %9.4f %8.2f | %9.5f %9.4f %11.5f\n", k, c1$lp - lp_free_ref,
              c1$sl, c1$sl / QP_OBS_SPO_LAND, p$q10, p$seas_T_amp_NH,
              p$seas_T_amp_SH * log(p$q10))) }
nhprod <- vapply(fr$cond, function(c1) c1$pv$seas_T_amp_NH * log(c1$pv$q10), 0)
cat(sprintf("\n  NH product held to %.5f +/- %.5f = %.3f %% while its factors move %.2fx and %.2fx\n",
            mean(nhprod), sd(nhprod), 100 * sd(nhprod) / mean(nhprod),
            max(vapply(fr$cond, function(c1) c1$pv$seas_T_amp_NH, 0)) /
            min(vapply(fr$cond, function(c1) c1$pv$seas_T_amp_NH, 0)),
            max(vapply(fr$cond, function(c1) log(c1$pv$q10), 0)) /
            min(vapply(fr$cond, function(c1) log(c1$pv$q10), 0))))
shp_free <- vapply(fr$cond, function(c1) c1$pv$seas_T_amp_SH * log(c1$pv$q10), 0)
shp_pin  <- QP_GRID * log(Q10_PIN)
cat(sprintf("  SH product delivered  %.5f -> %.5f = %.2fx\n", shp_free[1], shp_free[length(shp_free)],
            shp_free[length(shp_free)] / shp_free[1]))
cat(sprintf("  SH product AT PINNED  %.5f -> %.5f = %.2fx\n", shp_pin[1], shp_pin[length(shp_pin)],
            shp_pin[length(shp_pin)] / shp_pin[1]))
cat(sprintf("  ⇒ THE FREE SLICE DELIVERED %.1f %% OF ITS OWN LEVER (in product terms)\n",
            100 * (shp_free[length(shp_free)]/shp_free[1]) / (shp_pin[length(shp_pin)]/shp_pin[1])))

sep("1. THE PINNED CONDITIONAL PROFILE -- q10 held at the mode")
idx <- match(QP_SLICE_PIN, CCX_PARAM_NAMES)
stopifnot(!anyNA(idx), !(i_at %in% idx), !(i_q %in% idx))
cat(sprintf("  %8s | %11s %11s | %9s %8s %9s | %9s %11s | %2s %8s\n", "a_t",
            "pinned dlp", "27n free", "SH-land", "xobs", "SPO tot", "sTaNH", "SPO d13/ppm",
            "re", "lastgain"))
pin <- list(); v_warm <- u0[idx]
for (a in QP_GRID) {
  ua <- u_at(u0, a); ua[i_q] <- log(Q10_PIN)      # the pin, explicit in u-space
  objf <- function(v) { u <- ua; u[idx] <- v; -lp(u) }
  t0 <- Sys.time(); ft <- fit_block(objf, v_warm); v_warm <- ft$par
  u_h <- ua; u_h[idx] <- ft$par; pvh <- ccx_unc_to_par(u_h)
  stopifnot(abs(pvh$q10 - Q10_PIN) < 1e-9)        # the pin held, not asserted
  b  <- run_at(pvh); sl <- amp(b$co2_SPO - run_at(pvh, QP_CASES$SH_land)$co2_SPO)
  pin[[sprintf("%.4f", a)]] <- list(a = a, lp = -ft$value, pv = pvh, sl = sl,
                                    tot = amp(b$co2_SPO), r = ratio_SPO(b),
                                    mo = ang_mo(b$co2_SPO), converged = ft$converged,
                                    secs = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  cat(sprintf("  %8.4f | %+11.2f %+11.2f | %9.4f %8.2f %9.4f | %9.4f %11.3f | %2d %8.4f%s\n",
              a, -ft$value - pin[[1]]$lp, fr$cond[[sprintf("%.4f", a)]]$lp - lp_free_ref,
              sl, sl / QP_OBS_SPO_LAND, amp(b$co2_SPO), pvh$seas_T_amp_NH, ratio_SPO(b),
              ft$restarts, ft$last_gain, if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}
cat(sprintf("\n  wall clock per point (s): %s\n",
            paste(sprintf("%.0f", vapply(pin, function(x) x$secs, 0)), collapse = ", ")))

sep("2. THE PRE-REGISTERED GATES")
kL <- sprintf("%.4f", QP_GRID[1]); kH <- sprintf("%.4f", QP_HI)
dlp_pin_L <- pin[[kL]]$lp - one
dlp_free_L <- fr$cond[[kL]]$lp - one
d_S0 <- dlp_pin_L - dlp_free_L
dlp_pin_H <- pin[[kH]]$lp - pin[[kL]]$lp
vg <- function(lab, v, ok, gate) {
  cat(sprintf("  %-46s %10.4f %14s %s\n", lab, v, gate, if (ok) "PASS" else "FAIL")); ok }
cat(sprintf("  %-46s %10s %14s %s\n", "gate", "value", "band", "verdict"))
S0 <- vg("S0  price of the pin (pinned - free, landed)", d_S0,
         d_S0 <= QP_S0_BAND[2] && d_S0 >= QP_S0_BAND[1],
         sprintf("[%.2f, %.2f]", QP_S0_BAND[1], QP_S0_BAND[2]))
S1 <- vg("S1  pinned SH-land at bracket HI", pin[[kH]]$sl, pin[[kH]]$sl <= QP_S1_SHLAND,
         sprintf("<= %.2f", QP_S1_SHLAND))
S2 <- vg("S2  pinned seas_T_amp_NH at HI (K)", pin[[kH]]$pv$seas_T_amp_NH,
         pin[[kH]]$pv$seas_T_amp_NH <= QP_S2_NH, sprintf("<= %.1f", QP_S2_NH))
S3 <- vg("S3  pinned cond dlp at HI (vs 27n free)", dlp_pin_H,
         dlp_pin_H < QP_S3_FREE_DLP, sprintf("< %.2f", QP_S3_FREE_DLP))

sep("3. S4/S5 -- WHICH ROW PAYS, at bracket HI")
s_ref <- streams_at(pin[[kL]]$pv); s_hi <- streams_at(pin[[kH]]$pv)
dtot <- sum(s_hi) - sum(s_ref)
cat(sprintf("  total likelihood change, landed -> HI: %+.2f  (conditional dlp %+.2f = + prior)\n\n",
            dtot, dlp_pin_H))
cat(sprintf("  %-20s %11s %9s\n", "stream", "delta", "share"))
for (n in QP_COST_ROWS) {
  d <- s_hi[[n]] - s_ref[[n]]
  cat(sprintf("  %-20s %+11.2f %8.1f %%\n", n, d, 100 * d / dtot))
}
f_spo <- (s_hi[["co2_seasonal_SPO"]] - s_ref[["co2_seasonal_SPO"]]) / dtot
f_gcb <- abs(s_hi[["gcb_land_sink"]] - s_ref[["gcb_land_sink"]]) / abs(dtot)
cat("\n")
S4 <- vg("S4  co2_seasonal_SPO share of the cost", f_spo, f_spo >= QP_S4_FRAC,
         sprintf(">= %.2f", QP_S4_FRAC))
S5 <- vg("S5  |gcb_land_sink| share (the pin's risk)", f_gcb, f_gcb < QP_S5_FRAC,
         sprintf("< %.2f", QP_S5_FRAC))

sep("4. THE REACH THE 2x2 MUST BE BUILT ON")
cat(sprintf("  full-frozen  SH-land at HI  %.4f   (no refit at all)\n", QP_S1_FROZEN))
cat(sprintf("  PINNED slice SH-land at HI  %.4f   <- the honest conditional reach\n", pin[[kH]]$sl))
cat(sprintf("  27n free     SH-land at HI  %.4f   <- ATTENUATED by the q10 leak\n", QP_S1_FREE))
cat(sprintf("\n  SH-land VACATED, pinned : %.4f ppm   (27j's productivity lever vacated 0.416)\n",
            pin[[kL]]$sl - pin[[kH]]$sl))
cat(sprintf("  SH-land VACATED, 27n    : %.4f ppm\n", fr$cond[[kL]]$sl - fr$cond[[kH]]$sl))
cat(sprintf("  excess closed, pinned   : %.1f %%   (27n reported 15.3 %%)\n",
            100 * (pin[[kL]]$sl - pin[[kH]]$sl) / (pin[[kL]]$sl - QP_OBS_SPO_LAND)))

sep("5. SCORED")
cat(sprintf("  S0 %s | S1 %s | S2 %s | S3 %s | S4 %s | S5 %s\n",
            ifelse(S0,"PASS","FAIL"), ifelse(S1,"PASS","FAIL"), ifelse(S2,"PASS","FAIL"),
            ifelse(S3,"PASS","FAIL"), ifelse(S4,"PASS","FAIL"), ifelse(S5,"PASS","FAIL")))
cat(sprintf("\n  ⇒ %s\n", if (!S0 || !S3)
  "S0/S3 are EXACT gates. A failure is a BUG in this harness, not a finding -- stop." else
  if (S1) paste0("S1 CONFIRMED -- the q10 leak was real and 27n's lever was ATTENUATED.\n",
                 "       The 2x2 of 27o sec.6 must be built on the PINNED slice, and its reach\n",
                 "       re-derived from the vacated ppm in sec.4 above.") else
  "S1 FALSIFIED -- the leak is NOT mainly q10. 27n stands as written and the\n       150-min points are a pure SPEED problem."))
cat("\n  ⚠ This does NOT rehabilitate seas_T_amp_SH. The FULL-FROZEN cost at bracket HI is\n")
cat("    -204.45, of which co2_seasonal_SPO carries -187.21. The 27o sec.6 veto stands.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(slice_pin = QP_SLICE_PIN, slice_free = QP_SLICE_FREE, profiled = QP_PROFILED,
             q10_pin = Q10_PIN, grid = QP_GRID, pin = pin, harness_at_u_mode = one,
             harness_offset = one - md$logpost, streams_landed = s_ref, streams_hi = s_hi,
             free_from = QP_FREE_RDS,
             verdicts = c(S0 = S0, S1 = S1, S2 = S2, S3 = S3, S4 = S4, S5 = S5)),
        file.path(OUTDIR, "seas_slice_q10_pin.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n", file.path(OUTDIR, "seas_slice_q10_pin.rds")))
