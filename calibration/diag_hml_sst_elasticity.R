# =====================================================================
# diag_hml_sst_elasticity.R -- DOES A SHALLOW MIXED LAYER DECOUPLE
# sst_seas_amp_SH FROM THE SPO OCEAN LIMB?
#
# THE CLAIM UNDER TEST, from diag_hml_seasonal_limbs.R (924711d): between the
# two fitted modes sst_seas_amp_SH rose 20% and gained 0.73 sigma of prior
# credit while the SH ocean limb it drives moved only 3.9%. The reading offered
# there was that h_ml = 35.38 m DAMPS the transfer, so the fit could buy prior
# credit by neutering the parameter rather than by improving physics. That was
# an INFERENCE, not a measurement -- the two modes differ in all 21 coordinates,
# so nothing in it was attributable to h_ml.
#
# ⚠ THIS IS THE WHOLE POINT OF THIS FILE'S DESIGN. Everything is held at ONE
# base vector and ONLY h_ml and sst_seas_amp_SH are varied. Comparing "the
# sensitivity at the old mode" with "the sensitivity at the new mode" would
# confound h_ml with the other twenty parameters and could not attribute
# anything ([[decompose_channels]]).
#
# ⚠ NOTHING HERE CHANGES AN OBJECTIVE. No constant, prior, R/ or src/ touched;
# no refit is owed by anything it prints.
#
# METHOD as diag_admissible_2x2_land_ocean.R: same SH_ocean knockout (BOTH SH
# limbs -- zeroing sst_seas_amp_SH alone leaves entrainment running), same
# PEAK-TO-PEAK amp(), same ang_mo() ([[amp_definition_mismatch]]).
# The knockout run does not depend on sst_seas_amp_SH (it is zeroed there), so
# it is computed ONCE per h_ml rather than per grid point.
#
# ---------------------------------------------------------------------
# PREDICTIONS, WRITTEN BEFORE THE RUN.
#   P1  DECOUPLING: the elasticity d ln(SH_ocean amp) / d ln(sst_seas_amp_SH)
#       is LOWER at h_ml = 35.38 than at 96.47. Confirms the reading.
#   P2  THE KILL: if the two elasticities agree within the grid's own spread,
#       the decoupling reading is WRONG -- the small limb response is then
#       explained by the OTHER twenty parameters, not by h_ml, and 924711d's
#       last paragraph must be withdrawn.
#   ⚠ P2 IS THE LIVE OUTCOME, NOT A FORMALITY. State it before seeing it.
#   P3  POWER: a +-20% perturbation must move the limb by more than the grid's
#       numerical reproducibility. If it does not, neither P1 nor P2 is
#       readable and this test has no power ([[no_power_null]]).
# ---------------------------------------------------------------------
# Usage:  Rscript calibration/diag_hml_sst_elasticity.R   (~6-10 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

EL_YEARS  <- c(1750, 2024)
EL_BASE   <- "calibration/output/refit_20260828_sigma_eff/mode_fit_pumpN.rds"
EL_HML    <- c(new = 35.38, old = 96.47)      # the two fitted depths
EL_FACT   <- c(0.8, 1.0, 1.2)                 # +-20%, matching the observed move
EL_ENT    <- 0                                # shipped default, not fitted
EL_OBS_OCEAN <- 0.522; EL_OBS_OCEAN_MO <- 8.52

sep    <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
obs    <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))

md <- readRDS(ccx_path(EL_BASE))
PV <- ccx_mode_params(md)                     # never ccx_unc_to_par(md$u_mode)
S0 <- PV$sst_seas_amp_SH

run_at <- function(mods) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- PV[[n]]
  p$gamma_enso <- PV$gamma_enso; p$pump_mode <- md$pump_mode
  p$ent_seas_amp_SH <- EL_ENT
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", EL_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (PV$bomb_total / 102)
  for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * PV$luc_scale
  attr(F, "luc_scale") <- PV$luc_scale
  vec_of(pick(ccx_model_stats(ccx_run_fast(sp, F)$out, obs), "co2_seas.SPO"))
}

cat("SH-OCEAN LIMB ELASTICITY vs sst_seas_amp_SH, AT TWO MIXED-LAYER DEPTHS\n")
cat(sprintf("base vector: %s (all 21 held here except the two varied)\n", basename(dirname(EL_BASE))))
cat(sprintf("sst_seas_amp_SH at base = %.4f; grid = %s x base\n",
            S0, paste(EL_FACT, collapse = ", ")))

RES <- list()
for (hn in names(EL_HML)) {
  h  <- EL_HML[[hn]]
  ko <- run_at(list(h_ml = h, sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))
  sep(sprintf("h_ml = %.2f m (%s)", h, hn))
  cat(sprintf("  %10s %10s %10s %8s\n", "sst_amp_SH", "limb amp", "%% of obs", "mo"))
  rows <- lapply(EL_FACT, function(f) {
    s <- S0 * f
    v <- run_at(list(h_ml = h, sst_seas_amp_SH = s)) - ko
    cat(sprintf("  %10.4f %10.4f %10.1f %8.2f\n", s, amp(v), 100*amp(v)/EL_OBS_OCEAN, ang_mo(v)))
    c(s = s, a = amp(v), mo = ang_mo(v))
  })
  M <- do.call(rbind, rows)
  # elasticity from the two-sided endpoints, in logs
  el <- (log(M[3,"a"]) - log(M[1,"a"])) / (log(M[3,"s"]) - log(M[1,"s"]))
  cat(sprintf("  ELASTICITY d ln(limb)/d ln(sst_seas_amp_SH) = %.4f\n", el))
  RES[[hn]] <- list(h = h, M = M, el = el)
}

sep("THE PREDICTIONS, SCORED")
e_new <- RES$new$el; e_old <- RES$old$el
cat(sprintf("  elasticity at 35.38 m = %.4f\n", e_new))
cat(sprintf("  elasticity at 96.47 m = %.4f\n", e_old))
cat(sprintf("  ratio new/old         = %.4f   (<1 = shallow layer DAMPS the transfer)\n",
            e_new / e_old))
# P3 first: without power neither P1 nor P2 is readable.
span_new <- RES$new$M[3,"a"] / RES$new$M[1,"a"]; span_old <- RES$old$M[3,"a"] / RES$old$M[1,"a"]
cat(sprintf("\n  P3 POWER: a +-20%% perturbation moves the limb by %.1f%% (35 m) and %.1f%% (96 m).\n",
            100*(span_new-1), 100*(span_old-1)))
cat(sprintf("     %s\n", if (min(span_new, span_old) - 1 > 0.01)
            "both >> numerical noise -- the test HAS power." else
            "*** TOO SMALL TO READ -- neither P1 nor P2 is interpretable. ***"))
cat(sprintf("\n  P1/P2: %s\n", if (e_new < 0.9 * e_old)
  "P1 -- the shallow layer DAMPS the transfer; the decoupling reading STANDS." else
  if (e_new > 1.1 * e_old)
  "*** the shallow layer AMPLIFIES the transfer -- the reading is INVERTED. ***" else
  "P2 -- the elasticities AGREE; h_ml does NOT decouple the parameter, and the\n         decoupling paragraph of 924711d must be WITHDRAWN."))
saveRDS(list(res = RES, base = EL_BASE, s0 = S0, fact = EL_FACT, ent = EL_ENT),
        ccx_path("outputs", "diagnostics", "hml_sst_elasticity.rds"))
cat("\nwritten: outputs/diagnostics/hml_sst_elasticity.rds\n")
