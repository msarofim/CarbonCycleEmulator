# =====================================================================
# diag_so_entrainment_power.R -- CAN THE SOUTHERN-OCEAN ENTRAINMENT
#                                CHANNEL MOVE THE THING IT IS BEING
#                                ASKED ABOUT?  (prereg 27g, P1)
#
# THIS IS A POWER MEASUREMENT, AND IT IS SCORED BEFORE ANY VERDICT.
#
# WHY IT COMES FIRST. The CO2 seasonal rows are ALREADY MATCHED -- the mode
# reproduces the observed SH seasonal CO2 to ~1 %, by two errors canceling --
# so they are structurally incapable of rejecting a partition error
# ([[no_power_null]], [[seas_right_observable_wrong_drivers]]). A test whose
# null is guaranteed reports "no effect" in exactly the same words as a test
# that looked and found nothing. So before the channel is allowed to answer
# anything, it has to be shown CAPABLE of supplying what the gap requires.
#
# THE THRESHOLD IS AN OBSERVATION, NOT A TOLERANCE CHOSEN TO PASS.
# diag_seas_signature_inversion.R puts the model's SPO ocean component at
# 0.236 ppm at month 3.35 and the observed one at 0.522 ppm at month 8.52 --
# 5.17 months apart, within 0.83 months of exact ANTIPHASE. Closing a
# near-antiphase gap takes the VECTOR difference, ~ 0.236 + 0.522 = 0.76 ppm.
# P1 asks for 0.70, that number with the phase imperfection allowed for.
#
# WHAT IT REPORTS BESIDES THE VERDICT:
#   - the channel's own vector contribution at SPO (size AND peak month), by
#     the same base-minus-off definition diag_seas_channel_decomp.R uses;
#   - the peak month of the model's TOTAL ocean channel, which is what P3 is
#     about -- adding amplitude in the season the model already had would be a
#     reparametrization of sst_seas_amp_SH, not a fix;
#   - the four scored seasonal streams, so the COST is visible next to the
#     capability. A channel that can reach 0.70 ppm only by destroying the
#     rows is not a usable instrument either.
#
# ⚠ THIS SCRIPT DOES NOT RE-OPTIMIZE. Every neighbor is frozen at the mode,
# and seas_T_amp x q10 is an EXACT ridge ([[ccx_seas_q10_ridge]]) while
# beta_max/fert_k absorb 85 % of a frozen cost -- so the Dlogpost column below
# OVERSTATES every cost. Read SHAPE AND DIRECTION from it, not magnitude.
# P2's re-optimization is a separate step and this is not it.
#
# Usage:  Rscript calibration/diag_so_entrainment_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

EP_MODE_FILE <- ccx_mode_file()
EP_YEARS     <- c(1750, 2024)
EP_WINDOW    <- LIK_SEAS_WINDOW
# umol/kg. The pre-check in the prereg puts the physical band at ~5-30 as a
# mean over the SH box; the grid runs past it deliberately, so the script can
# say whether 0.70 ppm is reachable INSIDE the physical range or only outside
# it. Those are different answers and a grid stopping at 30 could not tell them
# apart.
EP_AMPS      <- c(0, 5, 10, 20, 30, 50, 80)
EP_PHYSICAL  <- c(5, 30)          # the pre-check's band, for labeling only
# P1's falsifier, from the observed antiphase gap above. NOT tuned.
EP_POWER_PPM <- 0.70
# Where the model and the observations sit today (diag_seas_signature_inversion.R,
# re-run 2026-08-27 at this same mode). Printed so the grid is read against
# them rather than against nothing.
EP_MODEL_OCEAN <- c(amp = 0.236, mo = 3.35)
EP_OBS_OCEAN   <- c(amp = 0.522, mo = 8.52)
EP_SCORED <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
               "d13c_seasonal_MLO", "d13c_seasonal_SPO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(EP_MODE_FILE)
p0 <- ccx_default_params(); for (n in names(md$par_mode)) p0[[n]] <- md$par_mode[[n]]
p0$pump_mode <- md$pump_mode
stopifnot(p0$seas_drivers > 0)          # the channel is gated by this switch
obs <- ccx_prepare_obs()

vec_of <- function(h) c(mean(h$a), mean(h$b))
amp    <- function(v) 2 * sqrt(sum(v^2))               # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

ep_run <- function(mods = list()) {
  p <- p0; for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", EP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (p$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * p$luc_scale
  attr(F, "luc_scale") <- p$luc_scale
  r  <- ccx_run_fast(sp, F)
  ms <- ccx_model_stats(r$out, obs)
  ll <- ccx_loglik(r$out, obs, list(sigma_d14c = p$sigma_d14c, rep_dC = p$rep_dC,
                                    grad_off_co2 = p$grad_off_co2,
                                    grad_off_d13c = p$grad_off_d13c),
                   luc = ccx_forcing_eluc_annual(F),
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)
  list(co2_SPO = vec_of(ms$co2_seas$SPO), d13_SPO = vec_of(ms$d13_seas$SPO),
       co2_MLO = vec_of(ms$co2_seas$MLO), ll = ll)
}

cat(sprintf("mode %s (arm %s) | window %d-%d | estimator %s\n",
            basename(EP_MODE_FILE), md$pump_mode, EP_WINDOW[1], EP_WINDOW[2],
            CCX_SEAS_AMP_ESTIMATOR))
cat(sprintf("phase constant CCX_ENT_SEAS_PEAK_MO = %.2f (MEASURED, 40-90 S pCO2)\n",
            CCX_ENT_SEAS_PEAK_MO))
cat(sprintf("sst_seas_amp_SH at the mode = %.3f (observed 1.746 = %.1f %%)\n",
            p0$sst_seas_amp_SH, 100 * p0$sst_seas_amp_SH / 1.746))

# ---------------------------------------------------------------------
sep("1. THE SCAN -- what the channel delivers at SPO, and what it costs")
cat(sprintf("  Contribution = |(a,b)_amp - (a,b)_0|, peak-to-peak, the same\n"))
cat(sprintf("  base-minus-off definition diag_seas_channel_decomp.R uses.\n"))
cat(sprintf("  TOTAL ocean = the whole air-sea contribution (SST + entrainment),\n"))
cat(sprintf("  by turning ALL of it off; that is the quantity P3 is about.\n\n"))

R <- lapply(EP_AMPS, function(a) ep_run(list(ent_seas_amp_SH = a)))
names(R) <- as.character(EP_AMPS)
b0 <- R[["0"]]
# THE WHOLE air-sea channel off. It must switch off the ENTRAINMENT limb too,
# not just the SST one -- a version of this that left `ent_seas_amp_SH` at the
# scan value reported a dead-flat 0.247 ppm at month 3.68 for every amplitude,
# because it was isolating the SST limb and calling it the ocean.
Roff <- lapply(EP_AMPS, function(a) ep_run(list(ent_seas_amp_SH = 0,
                                                sst_seas_amp_NH = 0,
                                                sst_seas_amp_SH = 0)))
names(Roff) <- as.character(EP_AMPS)

cat(sprintf("  %6s %11s %8s | %11s %8s | %10s %10s\n", "amp", "chan ppm", "peak mo",
            "ocean ppm", "peak mo", "d13c_SPO", "dlogpost"))
tab <- NULL
for (a in as.character(EP_AMPS)) {
  dch <- R[[a]]$co2_SPO - b0$co2_SPO                    # the channel's own part
  doc <- R[[a]]$co2_SPO - Roff[[a]]$co2_SPO             # SST limb + entrainment
  row <- data.frame(amp = as.numeric(a), chan_ppm = amp(dch), chan_mo = ang_mo(dch),
                    ocean_ppm = amp(doc), ocean_mo = ang_mo(doc),
                    d13c_SPO = R[[a]]$ll[["d13c_seasonal_SPO"]],
                    dlogpost = sum(R[[a]]$ll) - sum(b0$ll))
  tab <- rbind(tab, row)
  cat(sprintf("  %6s %11.3f %8.2f | %11.3f %8.2f | %10.1f %+10.1f\n",
              a, row$chan_ppm, if (row$chan_ppm > 1e-6) row$chan_mo else NA,
              row$ocean_ppm, row$ocean_mo, row$d13c_SPO, row$dlogpost))
}
cat(sprintf("\n  for reference: model SPO ocean %.3f ppm at mo %.2f, observed %.3f at %.2f\n",
            EP_MODEL_OCEAN["amp"], EP_MODEL_OCEAN["mo"],
            EP_OBS_OCEAN["amp"], EP_OBS_OCEAN["mo"]))

# ---------------------------------------------------------------------
sep("2. P1 -- THE POWER VERDICT, scored before anything else is read")
reach   <- max(tab$chan_ppm)
at_amp  <- tab$amp[which.max(tab$chan_ppm)]
inband  <- tab[tab$amp >= EP_PHYSICAL[1] & tab$amp <= EP_PHYSICAL[2], ]
reach_p <- if (nrow(inband)) max(inband$chan_ppm) else NA_real_
cat(sprintf("  threshold %.2f ppm, from the observed antiphase gap (%.3f + %.3f)\n",
            EP_POWER_PPM, EP_MODEL_OCEAN["amp"], EP_OBS_OCEAN["amp"]))
cat(sprintf("  best over the whole grid   : %.3f ppm at amp %g\n", reach, at_amp))
cat(sprintf("  best inside the physical %g-%g: %.3f ppm\n",
            EP_PHYSICAL[1], EP_PHYSICAL[2], reach_p))
cat(sprintf("\n  P1 -- channel can deliver >= %.2f ppm at SPO: %s\n", EP_POWER_PPM,
            if (reach >= EP_POWER_PPM) "PASS -- the instrument has power" else
              "FAILED -- TOO WEAK TO ANSWER THE QUESTION; no null from it is reportable"))
if (reach >= EP_POWER_PPM && !is.na(reach_p) && reach_p < EP_POWER_PPM)
  cat("  ⚠ but ONLY OUTSIDE the physical 5-30 band -- the channel would be a\n",
      "    fudge factor at the amplitude it needs. Report it as one.\n", sep = "")

sep("3. WHAT PAYS -- per stream, at the amplitude that best closes the gap")
cat("  ⚠ EVERY NEIGHBOUR IS FROZEN AT THE MODE, so these costs are UPPER\n")
cat("  BOUNDS: seas_T_amp x q10 is an exact ridge and beta_max/fert_k absorb\n")
cat("  85 %% of a frozen cost. READ DIRECTION AND WHICH ROW PAYS, not size.\n\n")
# the amplitude whose TOTAL ocean vector lands closest to the observed one,
# in size -- chosen by the observation, not by the objective
best <- tab$amp[which.min(abs(tab$ocean_ppm - EP_OBS_OCEAN["amp"]))]
cat(sprintf("  amplitude picked BY THE OBSERVATION (ocean ppm nearest %.3f): %g\n\n",
            EP_OBS_OCEAN["amp"], best))
d <- R[[as.character(best)]]$ll - b0$ll
for (nm in names(sort(d))) if (abs(d[[nm]]) >= 0.5)
  cat(sprintf("  %-22s %10.1f -> %10.1f  %+9.1f\n", nm, b0$ll[[nm]],
              R[[as.character(best)]]$ll[[nm]], d[[nm]]))

sep("4. PHASE -- is this a fix, or a reparametrisation of sst_seas_amp_SH?")
cat("  P3 asks whether the model's OCEAN component moves toward 8.52. A channel\n")
cat("  that only added amplitude in the season the model already had would show\n")
cat("  a FLAT 'ocean peak mo' column in section 1 -- that is the failure mode,\n")
cat("  and it is visible there without any refit.\n\n")
cat(sprintf("  ocean peak month, amp 0 -> %g: %.2f -> %.2f (moved %+.2f mo)\n",
            max(EP_AMPS), tab$ocean_mo[1], tab$ocean_mo[nrow(tab)],
            ((tab$ocean_mo[nrow(tab)] - tab$ocean_mo[1] + 6) %% 12) - 6))
cat(sprintf("  the CHANNEL itself arrives at month %.2f, against the inversion's\n",
            tab$chan_mo[2]))
cat(sprintf("  observed ocean component at %.2f -- a %+.2f mo difference.\n",
            EP_OBS_OCEAN["mo"], ((tab$chan_mo[2] - EP_OBS_OCEAN["mo"] + 6) %% 12) - 6))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(mode = basename(EP_MODE_FILE), table = tab, best_amp = best,
             streams_base = b0$ll, streams_best = R[[as.character(best)]]$ll,
             threshold = EP_POWER_PPM, reach = reach, reach_physical = reach_p,
             peak_mo = CCX_ENT_SEAS_PEAK_MO, amps = EP_AMPS),
        file.path(OUTDIR, "so_entrainment_power.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "so_entrainment_power.rds")))
cat("\n\n=== DONE ===\n")
