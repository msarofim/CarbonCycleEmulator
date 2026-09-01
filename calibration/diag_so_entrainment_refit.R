# =====================================================================
# diag_so_entrainment_refit.R -- P2: DOES A CORRECTLY-PHASED OCEAN
#                                CHANNEL LET sst_seas_amp_SH RISE
#                                WITHOUT THE SEASONAL ROWS OBJECTING?
#
# THE PREDICTION, STATED IN ADVANCE (prereg 27g P2, and handoff 27g sec.5.3):
# `sst_seas_amp_SH` sits at 0.360 against an observed 1.746 -- 20.6 %, and a
# -6.32 sigma prior flag, the largest in the model. The weighting account says
# the fit is not objecting to the AMPLITUDE of the SH ocean channel but to its
# PHASE: a solubility-only channel arrives in austral autumn, antiphase to the
# SPO cycle's real ocean component, so more of it makes the fit worse. Supply
# the missing austral-winter limb and the objection should lift.
#
#   PREDICT   sst_seas_amp_SH >= 0.60 and prior z better than -5.0, with
#             co2_seasonal_SPO + d13c_seasonal_SPO no worse than 287.2.
#   FALSIFIER sst_seas_amp_SH < 0.42, or it rises only by paying those rows.
#             THAT OUTCOME IS A REAL FINDING: it would mean the weighting
#             account is wrong, and it is to be reported as one.
#
# THE COMPARISON IS MATCHED (`match_incumbents_optim`, as
# diag_sst_seas_zeroing.R sec.1 sets out). The incumbent is NOT the stored
# mode -- it is the stored mode RE-OPTIMISED OVER THE SAME SLICE, so the
# challenger is not being credited with the freedom the slice gives both.
#
# ⚠ THE CHALLENGER HAS ONE MORE FREE PARAMETER AND NO PRIOR ON IT.
# `ent_seas_amp_SH` is deliberately not in CCX_PARAM_TABLE (adding it would
# change the length of the calibrated vector and invalidate the stored mode and
# its Hessian), so it enters here as a bounded free scalar with NO prior term.
# A Dlogpost between a 6- and a 7-parameter fit is therefore NOT a model
# comparison, and nothing below presents it as one. What IS comparable is
# WHERE THE PARAMETERS LAND relative to their observed values -- which is the
# question P2 actually asks.
#
# ⚠ THE q10 RIDGE IS IN THE SLICE ON PURPOSE. seas_T_amp x q10 is an EXACT
# ridge (product held to 0.2 % over a 2.5x q10 range, [[ccx_seas_q10_ridge]]);
# omitting q10 would make every seas_T_amp move look more expensive than it is.
#
# Usage:  Rscript calibration/diag_so_entrainment_refit.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RF_MODE_FILE <- ccx_mode_file()
RF_YEARS     <- c(1750, 2024)
# The seasonal block. sst/seas amplitudes and the phenology lag are the
# seasonal cycle's own knobs; q10 is here for the exact ridge above.
RF_BLOCK  <- c("sst_seas_amp_NH", "sst_seas_amp_SH",
               "seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p", "q10")
# umol/kg. Bounds, not a prior: below is indistinguishable from off, above is
# far outside the ~5-30 the prereg's pre-check derives for a mean over the SH
# box. Optimised in log space so the step is scale-free like every other
# amplitude in the model.
RF_ENT_BOUNDS <- c(0.5, 60)
RF_ENT_INIT   <- 10
RF_MAXIT      <- 1200
# The observed driver values the parameters are scored AGAINST (P5's second
# scorecard). Sources: sst_* from ERSSTv5 hemispheric climatology,
# seas_T_amp_* from the CRU/CRUTEM5 land bracket -- see ccx_seas_clim_obs.
RF_OBSERVED <- c(sst_seas_amp_NH = 2.237, sst_seas_amp_SH = 1.746)
RF_SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")
# P2's falsifiers, fixed here so they cannot drift to meet the answer.
RF_P2_PASS_AMP <- 0.60
RF_P2_FAIL_AMP <- 0.42
RF_P2_PASS_Z   <- -5.0
RF_P2_SPO_SUM  <- 287.2      # co2_seasonal_SPO + d13c_seasonal_SPO at the mode

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(RF_MODE_FILE)
# ⚠ ADOPT THE MODE'S OWN h_ml BAND BEFORE DECODING ANYTHING (2026-08-28).
# The pump refits override h_ml's logit band IN PROCESS, so `ccx_unc_to_par()`
# -- a pure function of the SHIPPED table -- returns 85.73 m where this mode
# actually sits at 96.47 m, an 11 % shallower mixed layer. h_ml is frozen in
# this driver, so the effect is a WRONG CONSTANT in every arm, not a changed
# contrast; the arms below were previously all wrong together.
# See the note above ccx_mode_params() in R/paths.R. [[ccx_hml_band_decode]]
ccx_adopt_mode_band(md)
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
idx <- match(RF_BLOCK, CCX_PARAM_NAMES)
stopifnot(!anyNA(idx))

cat(sprintf("mode %s (arm %s) | block: %s\n", basename(RF_MODE_FILE), md$pump_mode,
            paste(RF_BLOCK, collapse = ", ")))
cat(sprintf("stored logpost %.3f | sst_seas_amp_SH %.3f (%.1f %% of observed)\n\n",
            md$logpost, md$par_mode$sst_seas_amp_SH,
            100 * md$par_mode$sst_seas_amp_SH / RF_OBSERVED[["sst_seas_amp_SH"]]))

# One logpost builder per entrainment amplitude: base_params carries the
# channel, which is NOT in CCX_PARAM_NAMES and so cannot ride in `u`.
lp_at <- function(ent) {
  bp <- ccx_default_params(); bp$ent_seas_amp_SH <- ent
  bp$pump_mode <- md$pump_mode
  ccx_make_logpost(years = RF_YEARS, base_params = bp)
}
# Cache: rebuilding the forcing per evaluation would dominate the runtime.
.cache <- new.env(parent = emptyenv())
lp_cached <- function(ent) {
  k <- sprintf("%.6f", ent)
  if (is.null(.cache[[k]])) .cache[[k]] <- lp_at(ent)
  .cache[[k]]
}

t0 <- Sys.time()
one <- lp_cached(0)(u0)
el  <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
gap <- one - md$logpost
cat(sprintf("one logpost evaluation: %.2f s\n", el))
cat(sprintf("stored logpost %.4f | recomputed here %.4f | OFFSET %+.4f\n",
            md$logpost, one, gap))

# ⚠ THE OFFSET IS REAL, IT IS PRE-EXISTING, AND IT IS NOT MINE TO ABSORB.
# ccx_make_logpost() does not reproduce the canonical mode's stored logpost at
# ⚠ THE OFFSET IS NOW -1.5805, NOT -3.3223 (2026-08-28). Adopting the mode's
# own h_ml band removes the 1.7418 that was a WRONG DECODE; what remains is
# exactly the bounded refit's narrowed-prior constant, which is additive and
# cancels from every difference. [[ccx_hml_band_decode]]
# the mode's OWN u_mode. Measured 2026-08-27 as -3.3223; -1.5805 since the 08-28 band fix, and IDENTICAL at commit
# fbf4b4c, before the entrainment channel existed -- so it is a property of the
# repo, not of this work. It is entirely in the LIKELIHOOD (the prior + Jacobian
# reproduce to the last decimal), and its signature is an INTERHEMISPHERIC
# REDISTRIBUTION -- the NH and SH rows move in mirror-image pairs:
#
#   d14c_NH -2.78 / d14c_SH +2.44 | d13c_level_MLO -2.65 / d13c_level_SPO +1.97
#
# Ruled out: FORC_USE_LUC_NH_SHARE_TS and FORC_USE_EMIS_SEASONALITY (the shipped
# TRUE/TRUE is the best of the four combinations and is the one that is 3.32
# off), substeps (4 both ways), and the h_ml refit bound (h_ml = 85.729 is
# inside both brackets, and the prior reproduces exactly anyway).
#
# WHY THIS DOES NOT INVALIDATE P2. The comparison here is MATCHED: incumbent and
# challenger are scored by the SAME harness, so a constant offset cancels out of
# every difference read below. What it would invalidate is quoting an ABSOLUTE
# logpost from this script against a number from the mode file -- so this script
# does not do that, and neither should anything reading it. The offset is also
# 3.3 against the ~227 log-units P1 measured on co2_seasonal_SPO alone.
CCX_MODE_OFFSET_KNOWN <- -1.5805         # measured 2026-08-27, at fbf4b4c too
if (abs(gap - CCX_MODE_OFFSET_KNOWN) > 0.5)
  cat(sprintf("  ⚠ THE OFFSET HAS MOVED (known %+.4f). Something changed the\n",
              CCX_MODE_OFFSET_KNOWN),
      "    objective since 2026-08-27. Investigate BEFORE reading this run.\n", sep = "")
# determinism is load-bearing for a Nelder-Mead and is cheap to assert
stopifnot(identical(lp_cached(0)(u0), one))

# ---- INCUMBENT: the stored mode re-optimised over the SAME slice -------
sep("1. INCUMBENT -- ent = 0, the block re-optimised (match_incumbents_optim)")
obj_inc <- function(v) { u <- u0; u[idx] <- v; -lp_cached(0)(u) }
fit_inc <- optim(u0[idx], obj_inc, method = "Nelder-Mead",
                 control = list(maxit = RF_MAXIT, reltol = 1e-10))
u_inc <- u0; u_inc[idx] <- fit_inc$par
# AGAINST THIS HARNESS'S OWN BASELINE, not the stored logpost. Subtracting
# md$logpost here would fold the -3.32 offset above into the reported gain --
# the precise mistake the offset note forbids, made in a print statement.
cat(sprintf("  this harness at u_mode %.3f -> re-optimised %.3f  (gain %+.2f)\n",
            one, -fit_inc$value, -fit_inc$value - one))
cat(sprintf("  (stored logpost %.3f is NOT the baseline for that gain -- offset %+.4f)\n",
            md$logpost, gap))

# ---- CHALLENGER: the same slice, plus the channel ---------------------
sep("2. CHALLENGER -- the same slice, plus ent_seas_amp_SH (log scale, bounded)")
lo <- log(RF_ENT_BOUNDS[1]); hi <- log(RF_ENT_BOUNDS[2])
obj_ch <- function(v) {
  le <- v[length(v)]
  if (le < lo || le > hi) return(1e12)     # BOUNDS, not a prior
  u <- u0; u[idx] <- v[-length(v)]
  -lp_cached(round(exp(le), 6))(u)
}
fit_ch <- optim(c(u0[idx], log(RF_ENT_INIT)), obj_ch, method = "Nelder-Mead",
                control = list(maxit = RF_MAXIT, reltol = 1e-10))
ent_hat <- exp(fit_ch$par[length(fit_ch$par)])
u_ch <- u0; u_ch[idx] <- fit_ch$par[-length(fit_ch$par)]
cat(sprintf("  ent_seas_amp_SH = %.2f umol/kg (bounds %g-%g; the pre-check band is 5-30)\n",
            ent_hat, RF_ENT_BOUNDS[1], RF_ENT_BOUNDS[2]))
cat(sprintf("  logpost %.3f  (incumbent %.3f, gain %+.2f)  -- NOT a model\n",
            -fit_ch$value, -fit_inc$value, -fit_ch$value + fit_inc$value))
cat("  comparison: the\n")
cat("  challenger has one more free parameter and no prior on it.\n")
if (ent_hat < RF_ENT_BOUNDS[1] * 1.05 || ent_hat > RF_ENT_BOUNDS[2] * 0.95)
  cat("  ⚠ RAILED against its bound -- the amplitude is NOT identified here.\n")
if (ent_hat < 5 || ent_hat > 30)
  cat("  ⚠ OUTSIDE the 5-30 physical pre-check band: the channel is doing work\n",
      "    a Southern-Ocean entrainment cycle of that size could not do.\n", sep = "")

# ---- WHERE THE PARAMETERS LAND ---------------------------------------
sep("3. P2 AND P5 -- where the drivers land, against their OBSERVED values")
pv_inc <- ccx_unc_to_par(u_inc); pv_ch <- ccx_unc_to_par(u_ch)
cat(sprintf("  %-16s %10s %10s %10s | %9s %9s %9s\n", "parameter", "mode",
            "incumbent", "challenger", "z mode", "z inc", "z chall"))
for (n in RF_BLOCK) {
  cat(sprintf("  %-16s %10.3f %10.3f %10.3f | %9.2f %9.2f %9.2f\n", n,
              md$par_mode[[n]], pv_inc[[n]], pv_ch[[n]],
              ccx_prior_z(n, md$par_mode[[n]]), ccx_prior_z(n, pv_inc[[n]]),
              ccx_prior_z(n, pv_ch[[n]])))
}
cat("\n  against observation (P5's second scorecard -- % of the observed value):\n")
for (n in names(RF_OBSERVED))
  cat(sprintf("  %-16s obs %6.3f | mode %5.1f %%  incumbent %5.1f %%  challenger %5.1f %%\n",
              n, RF_OBSERVED[[n]], 100 * md$par_mode[[n]] / RF_OBSERVED[[n]],
              100 * pv_inc[[n]] / RF_OBSERVED[[n]], 100 * pv_ch[[n]] / RF_OBSERVED[[n]]))

# ---- WHAT THE SEASONAL ROWS SAY --------------------------------------
sep("4. the scored seasonal rows -- did the amplitude rise by PAYING them?")
streams_at <- function(u, ent) {
  pv <- ccx_unc_to_par(u)
  p <- ccx_default_params(); for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv); p$pump_mode <- md$pump_mode; p$ent_seas_amp_SH <- ent
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", RF_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  unlist(ccx_loglik(o, ccx_prepare_obs(),
                    list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                         grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c),
                    luc = ccx_forcing_eluc_annual(F),
                    deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
}
s_mode <- md$streams; s_inc <- streams_at(u_inc, 0); s_ch <- streams_at(u_ch, ent_hat)
cat(sprintf("  %-22s %10s %10s %10s\n", "stream", "mode", "incumbent", "challenger"))
for (n in RF_SEAS_ROWS)
  cat(sprintf("  %-22s %10.1f %10.1f %10.1f\n", n, s_mode[[n]], s_inc[[n]], s_ch[[n]]))
spo_sum <- function(s) s[["co2_seasonal_SPO"]] + s[["d13c_seasonal_SPO"]]
cat(sprintf("  %-22s %10.1f %10.1f %10.1f\n", "SPO pair (P2's gate)",
            spo_sum(s_mode), spo_sum(s_inc), spo_sum(s_ch)))
cat("\n  every OTHER stream that moved by >= 5 log-units, challenger vs mode:\n")
d <- s_ch[names(s_mode)] - s_mode
for (n in names(sort(d))) if (abs(d[[n]]) >= 5 && !(n %in% RF_SEAS_ROWS))
  cat(sprintf("  %-22s %10.1f -> %10.1f  %+9.1f\n", n, s_mode[[n]], s_ch[[n]], d[[n]]))

# ---- THE VERDICT ------------------------------------------------------
sep("5. P2 -- SCORED")
amp_ch <- pv_ch$sst_seas_amp_SH; z_ch <- ccx_prior_z("sst_seas_amp_SH", amp_ch)
cat(sprintf("  sst_seas_amp_SH  %.3f -> %.3f   (prior z %.2f -> %.2f)\n",
            md$par_mode$sst_seas_amp_SH, amp_ch,
            ccx_prior_z("sst_seas_amp_SH", md$par_mode$sst_seas_amp_SH), z_ch))
cat(sprintf("  SPO pair         %.1f -> %.1f    (gate: not worse than %.1f)\n",
            spo_sum(s_mode), spo_sum(s_ch), RF_P2_SPO_SUM))
verdict <- {
  if (amp_ch < RF_P2_FAIL_AMP) {
    "FALSIFIED -- the amplitude did NOT rise. The weighting account is wrong, and THAT is the finding."
  } else if (amp_ch >= RF_P2_PASS_AMP && z_ch > RF_P2_PASS_Z &&
             spo_sum(s_ch) >= RF_P2_SPO_SUM) {
    "CONFIRMED -- the objection was to the PHASE, not the amplitude."
  } else if (amp_ch >= RF_P2_PASS_AMP) {
    "PARTIAL -- the amplitude rose, but it was PAID FOR. Read section 4 before quoting this."
  } else {
    "INCONCLUSIVE -- between the pass and fail thresholds; neither is claimed."
  }
}
cat(sprintf("\n  P2 -> %s\n", verdict))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(mode = basename(RF_MODE_FILE), block = RF_BLOCK,
             ent_hat = ent_hat, ent_bounds = RF_ENT_BOUNDS,
             logpost = c(stored_mode = md$logpost, harness_at_u_mode = one,
                         incumbent = -fit_inc$value, challenger = -fit_ch$value),
             harness_offset = gap,
             par_mode = md$par_mode[RF_BLOCK], par_inc = pv_inc[RF_BLOCK],
             par_ch = pv_ch[RF_BLOCK],
             # THE FULL VECTORS, not just the block. The first version of this
             # saved only RF_BLOCK, and scoring the inversion at the refitted
             # model then meant reconstructing u_ch from the block by hand.
             # Anything downstream needs the vector the fit actually landed on.
             u_inc = u_inc, u_ch = u_ch, u_mode = u0,
             streams = list(mode = s_mode, incumbent = s_inc, challenger = s_ch),
             verdict = verdict),
        file.path(OUTDIR, "so_entrainment_refit.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n", file.path(OUTDIR, "so_entrainment_refit.rds")))
