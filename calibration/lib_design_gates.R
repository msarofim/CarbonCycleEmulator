# =====================================================================
# lib_design_gates.R -- the DESIGN sec.6 gate 4 / 5 / 7 KERNELS, in one place.
#
# WHY THIS FILE EXISTS (2026-08-31f). These estimators were written inside
# `diag_design_gates_at_mode.R` and were about to be written a SECOND time, in
# the file that re-prices the same three gates in the 08-31e basin. Two copies
# of a gate is the caption-sync bug class the project rule against free-floating
# labels exists to kill: the day one copy's window, target or estimator moves,
# the two files report the same gate name at two different measurements and
# nothing says so. One kernel, two callers, one set of named constants.
#
# ⛔ SOURCE THIS, DO NOT RUN IT. It defines constants and functions and reads
# the zonal 14C observations once; it prints and gates nothing on its own.
#
# EVERY DESIGN DECISION BELOW IS INHERITED VERBATIM from the 2026-08-27 file and
# its comments are kept with it, because each one is a ruling that was paid for:
#   * the two FORCING parameters (`bomb_total`, `luc_scale`) are carried;
#   * gate 5 is scored on the HEMISPHERIC aggregate, never Hua's Zone 1;
#   * gate 7's window ends at 2023 and its targets are RECOMPUTED on that
#     window rather than quoted against a different one;
#   * gate 7's year boundaries extrapolate LINEARLY, matching the objective.
#
# WHAT IS NEW HERE, AND ONLY THIS: `dg_vector()` accepts a mode PATH as well as
# a mode NAME, and it MIGRATES a stored 21-parameter ancestor onto this build's
# 22 through `ccx_migrate_par_set()` instead of refusing it. The refusal it
# replaces (`stopifnot(identical(md$param_names, CCX_PARAM_NAMES))`) made this
# whole harness unrunnable the moment `seas_lag_p` split on 08-31 -- and a gate
# that cannot run reports nothing, which is worse than a gate that runs and says
# out loud that its input was migrated. It says so: `$migrated` is returned and
# every caller prints it.
# =====================================================================

# ---- labels derive from named constants (project rule) --------------
DG_BOMB_REF  <- 102                  # = BOMB_REF in ccx_make_logpost()
DG_YEARS     <- c(1750, 2024)

# GATE 4 -- GCB 2025 airborne fraction (DESIGN sec.6 gate 4)
DG_AF_WIN     <- c(1959, 2024)
DG_AF_DECADES <- c(1960, 1970, 1980, 1990, 2000, 2010, 2020)
# ⭐ 2026-09-04: THE OBSERVED SIDE IS COMPUTED, NOT TYPED -- AND RECOMPUTING IT
# FOUND THE TWO SIDES WERE USING DIFFERENT ESTIMATORS.
# `DG_AF_OBS_DEC` was seven typed two-decimal literals with no provenance line,
# while the MODEL side was an estimator -- so the gate compared an estimator with
# a copy, and a typed value with prose arithmetic drifts
# ([[derived_must_mean_computed]]). Recomputing from the SAME GCB budget the
# likelihood reads identifies where the literals came from, because only ONE of
# the two natural estimators reproduces all seven to 2 dp:
#     MEAN OF ANNUAL AF   0.3534 0.4265 0.4661 0.3807 0.4245 0.4482 0.4970
#                         -> rounds to 0.35 0.43 0.47 0.38 0.42 0.45 0.50, ALL SEVEN
#     RATIO OF SUMS       0.3568 0.4303 0.4684 0.3840 0.4228 0.4483 0.4984
#                         -> 0.3568 rounds to 0.36, NOT the typed 0.35
# and the RATIO OF SUMS is what `dg_gate4()` has always computed for the model.
# ⛔ So this gate compared a model ratio-of-sums against an observed
# mean-of-annual-ratios -- a LIKE-FOR-LIKE violation ([[like_for_like_forcing]])
# that 2 dp of rounding hid in six of the seven decades. Both sides now go
# through `dg_af_dec()`, which defaults to the model's own estimator.
# ⚠ AND IT MOVES THE BOUND, which IS the sd of this vector: 0.0515 typed ->
# 0.0491 mean-of-annual -> 0.0483 like-for-like, i.e. the model was being asked
# to beat a spread 6.6 % larger than the observations have. (No verdict flips.)
# The literals are kept as `*_TYPED` and their provenance is pinned in
# test-gate-bounds.R, so a GCB vintage change has to break something.
DG_AF_OBS_TYPED     <- 0.431
DG_AF_OBS_DEC_TYPED <- c(0.35, 0.43, 0.47, 0.38, 0.42, 0.45, 0.50)
# DG_AF_OBS and DG_AF_OBS_DEC are assigned below, once dg_af_dec() exists.

# GATE 5 -- Hua et al. 2022, HEMISPHERIC AGGREGATE (DESIGN's own like-for-like
# benchmark, not the Zone 1 numbers it warns against)
DG_BOMB_NH_PEAK <- 853.2; DG_BOMB_NH_YR <- 1963.708
DG_BOMB_SH_PEAK <- 659.4; DG_BOMB_SH_YR <- 1965.042
DG_BOMB_LAG     <- 1.33
DG_EFOLD_FLOOR  <- 20                # permil, the > 20 permil window DESIGN names

# GATE 7 -- GCB 2025 decade means and stated 1 sigma.
#
# THE WINDOW ENDS AT 2023, NOT 2024, AND THAT IS A DECISION (Marcus, 2026-08-27).
# The historical run ends at 2024-12 (t[n] = 2024.958), so the 2025 year boundary
# this gate differences the stock against sits HALF A MONTH past the last model
# state. That half month lands entirely on 2024, and it lands there at the moment
# in the seasonal cycle when the land stock's slope is at its most NEGATIVE (NH
# December respiration) -- so how the end is extrapolated is worth 0.65 GtC/yr on
# the 2024 annual increment alone, against sub-0.001 in every other year.
DG_SINK_WIN  <- c(2015, 2023)
# THE TARGETS ARE RECOMPUTED ON DG_SINK_WIN, NOT QUOTED. GCB's published decade
# means are 2.36 (land) / 3.22 (ocean) over 2015-2024 -- verified: recomputing
# them from the obs series over that window returns 2.363 / 3.221. But they are
# means over a WINDOW, so quoting them against a different window would compare
# nine model years with ten observed ones. Over 2015-2023 the observed means are
# 2.410 / 3.202. Both sides move together; the like-for-like rule decides it.
DG_GCB_LAND_SD  <- LIK_GCB_LAND_SD
DG_GCB_OCEAN_SD <- LIK_GCB_OCEAN_SD
# ⭐ RULED 2026-09-02 (Marcus): GATE 7 NOW JUDGES AT THE OBJECTIVE'S OWN SIGMAS.
# The 09-02 ledger found its standing FAIL was a STRICTNESS MISMATCH, not a model
# defect: the likelihood scores the land sink at LIK_GCB_LAND_SD *
# LIK_LAND_SINK_INFLATE = 1.50 GtC/yr and this gate judged the SAME stream on the
# SAME data at 0.50, where the shipped mode reads +2.33 sigma. At the sigma the
# fit was actually scored at it reads +0.78 -- a PASS. A gate that re-judges a
# fitted stream three times more strictly than the objective is not measuring the
# model; it is measuring the discrepancy between two sigmas.
# ⚠ THE OCEAN SIGMA IS *NOT* INFLATED IN THE LIKELIHOOD (R/likelihood.R:1608-1612
# -- ocean at LIK_GCB_OCEAN_SD bare, land at LIK_GCB_LAND_SD * the inflate), so
# the two halves take DIFFERENT sigmas here and that asymmetry is the objective's,
# not this file's.
# ⚠ DG_GCB_*_SD STAY GCB's STATED sigmas: they are what the report PRINTS beside
# the target, and printing 1.50 as "GCB's stated 1 sigma" would be false. The
# gate's judging sigmas are the DG_G7_*_SD pair below, and both are shown.
DG_G7_LAND_SD  <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE   # 0.5 x 3.0 = 1.50
DG_G7_OCEAN_SD <- LIK_GCB_OCEAN_SD                          # 0.40, uninflated
DG_G7_NSD <- 2      # how many of the OBJECTIVE's sigma gate 7 allows.
                    # ⭐ 1 -> 2 on 2026-09-02 (Marcus), harmonising with GATE Q's
                    # DG_Q_NSD and DG_G5_NSD: all three are distributional claims
                    # against a stated sigma and there was no reason for this one
                    # to be twice as strict. The 09-02 ledger recorded the
                    # inconsistency; this resolves it.
                    # ⚠ NAMED HERE 2026-09-02: it
                    # was a BARE LITERAL 1 duplicated in the verdict line of BOTH
                    # callers (diag_design_gates_at_mode.R, diag_gates_in_the_new_
                    # basin.R) while this file's own header claims "one kernel, two
                    # callers". The KERNEL was centralised in 08-31f; the VERDICT was
                    # not, so the one number that decides pass/fail could move in one
                    # caller and not the other -- the caption-sync class this file
                    # exists to kill, one level up. [[gate_bound_matches_its_claim]]
                    # (was a bare literal 1 duplicated into both callers' verdict
                    # lines; the VERDICT itself is now centralised too, below.)

DG_GCB_PUB_WIN  <- c(2015, 2024)     # the window GCB's published means are over
DG_GCB_PUB_LAND <- 2.36; DG_GCB_PUB_OCEAN <- 3.22

DG_GtC_PER_PPM <- ccx_const("GtC_PER_PPM")

# =====================================================================
# THE GATE LEDGER (2026-09-02, Marcus asked "are these the tests we want?")
#
# Every gate carries FOUR properties and until today only the first was written
# down anywhere. The one that changes how a result READS is the last:
#
#   SOURCE CLASS  OBSERVATION > LAW > MODEL, the hierarchy in ~/.claude/CLAUDE.md.
#                 A model-derived threshold is a LAST RESORT and must name the
#                 model and its vintage. [[threshold_from_obs_or_law]]
#   BOUND         and what KIND of claim it is. An identity gets an exact bound;
#                 a distributional claim gets the stated sigma; an ordering gets
#                 no threshold at all. [[gate_bound_matches_its_claim]]
#   SCORED?       whether the LIKELIHOOD already scores this quantity. A gate on
#                 a scored stream is a RESTATEMENT, not an out-of-sample test:
#                 it can only tell you the optimiser did its job.
#   POWER         what a PASS is actually worth, given the three above.
#                 [[no_power_null]] -- a test whose null is structurally
#                 guaranteed reports "no effect" identically to one that looked.
#
# ⛔ WHAT THIS LEDGER MADE VISIBLE, AND NOBODY HAD WRITTEN IT DOWN:
#   * GATE Q IS THE ONLY GENUINELY OUT-OF-SAMPLE GATE. Everything else either
#     restates a scored stream or rests on another model.
#   * GATE 7 IS NOT AN INDEPENDENT TEST AND ITS STANDING FAILURE WAS A SIGMA
#     MISMATCH, not a model defect. The likelihood scores the land sink at
#     LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE = 0.5 * 3.0 = 1.5 GtC/yr; the gate
#     judged the SAME stream against the SAME data at 0.5. ✅ ALIGNED 2026-09-02
#     (Marcus): it now judges at the objective's own sigmas. It is STILL not an
#     independent test -- aligning a sigma cannot make a restatement out-of-sample
#     -- so a refit should not chase it.
#   * GATES 4 AND 5 HAD NO BOUND AT ALL, so neither could fail. ✅ RESOLVED
#     2026-09-02 (Marcus): gate 4 gets an ORDERING on its decadal spread and its
#     LEVEL stays deliberately unbounded; gate 5 gets two orderings plus a
#     leave-one-zone-out sigma on its peak times and lag.
#   * THERE IS NOT ONE LAW-DERIVED GATE IN THE SET. Every gate here is
#     observational or model-derived; nothing tests the model against a
#     conservation law, Henry's law, or carbonate equilibrium.
#     ⚠ STILL TRUE after GATE G (2026-09-02), which is OBSERVATIONAL. What G
#     does is put an observation ON the surface carbonate state, which is the
#     quantity a Revelle or Henry's-law gate would test -- so it narrows the
#     hole without closing it. Candidates remain: carbonate/Revelle consistency
#     and Henry's-law solubility.
# =====================================================================
DG_LEDGER <- list(
  list(id = "4", what = "airborne fraction 1959-2024",
       class = "OBSERVATION", src = "GCB 2025",
       bound = paste("ORDERING, no threshold (2026-09-02):",
         "
            sd(model decadal AF) >= sd(GCB decadal AF). The gate's own",
         "
            stated claim is 'must not be SMOOTHER than this', and an",
         "
            ordering gets no threshold. ⚠ The AF LEVEL stays UNBOUNDED",
         "
            on purpose -- see POWER."),
       scored = "YES (CO2 growth is fitted; emissions are inputs)",
       power  = paste("~NONE on the LEVEL -- near-algebraic in quantities the fit",
         "
            already matches, so a bound there would test the optimiser.",
         "
            REAL on the VARIABILITY: nothing in the objective asks the",
         "
            decadal AF to vary, and the model is currently too smooth.")),
  list(id = "5", what = "bomb 14C peak, hemispheric lag, e-fold",
       class = "OBSERVATION", src = "Hua et al. 2022, hemispheric aggregate",
       bound = paste("TWO KINDS (2026-09-02). ORDERINGS, no threshold:",
         "
            SH peaks AFTER NH, NH peak HIGHER than SH -- the bomb source",
         "
            was northern. DISTRIBUTIONAL: |z| <= DG_G5_NSD on peak times",
         "
            and lag, against a sigma DERIVED by leave-one-zone-out on the",
         "
            observed aggregate (Hua publishes none). ⚠ That sigma is the",
         "
            aggregate's sensitivity to its own zonal composition, not a",
         "
            measurement error, and rests on few draws."),
       scored = "STREAM yes, FUNCTIONAL no (likelihood scores levels)",
       power  = paste("MODERATE, and the best-sourced gate here: a different",
         "
            functional of a scored stream. It now HAS a bound.")),
  list(id = "7", what = "land / ocean sinks 2015-2023",
       class = "OBSERVATION + MODEL", src = paste(
         "GCB 2025. ⚠ MIXED: the ocean sink is a product of ocean",
         "
            biogeochemistry MODELS and the land sink is a RESIDUAL of the",
         "
            budget, so this is not a clean observation."),
       bound = paste("|z| <= DG_G7_NSD (2 since 2026-09-02), against the",
         "
            OBJECTIVE'S OWN sigmas: land 1.50 = LIK_GCB_LAND_SD x",
         "
            LIK_LAND_SINK_INFLATE, ocean 0.40 uninflated. ⚠ Until",
         "
            2026-09-02 it judged land at 0.50, three times stricter than",
         "
            the fit, which is where its standing FAIL came from."),
       scored = "YES -- gcb_land_sink and gcb_ocean_sink are BOTH fitted",
       power  = paste("STILL NONE out-of-sample -- same streams, same data, and",
         "
            aligning the sigma does not change that. What it now tests is",
         "
            whether the optimiser did its job, which is worth stating and",
         "
            is not worth chasing in a refit.")),
  list(id = "Q", what = "air-sea d13C disequilibrium, 1995",
       class = "OBSERVATION", src = "Quay et al. 2003 (0.60 +- 0.10 permil)",
       bound = "n_sd <= DG_Q_NSD, a distributional claim on the stated sigma",
       scored = "NO -- ocean d13C is scored as a GRADIENT; d13c_level_* are atmospheric",
       power  = paste("REAL, AND THE ONLY ONE. Nothing constrains absolute",
         "
            surface-ocean d13C, which is why it caught a 6.4-sigma",
         "
            wrong-sign error that no stream had ever objected to.")),
  list(id = "G", what = "ocean mixed-layer DIC level at the GLODAP epoch",
       class = "OBSERVATION", src = paste("GLODAPv2.2023, doi:10.25921/z7hc-v261;",
         "
            Lauvset et al. 2024 ESSD 16:2047. Volume-weighted on the",
         "
            MODEL's own top layer, at the bottles' own mean year."),
       bound = paste("|z| <= DG_GD_NSD on the SURFACE LEVEL only. ⚠ The column",
         "
            INVENTORY is reported and NOT bounded: the pump's export was",
         "
            solved to hold the OBSERVED gradient, so an inventory gate",
         "
            would partly read back what built it."),
       scored = paste("NO -- the three ocean rows are GRADIENTS with fitted",
         "
            offsets, d14c_deep_ocean is Delta14C, gcb_ocean_sink is a FLUX.",
         "
            Nothing that set the model's surface DIC saw this number."),
       power  = paste("REAL and OUT-OF-SAMPLE, and it LOCALISES: the surface",
         "
            Revelle factor is a function of surface DIC and alkalinity, so",
         "
            a level that is right bounds gate 12a's ocean-capacity defect",
         "
            AWAY from the surface carbonate state. ⚠ Its sigma borrows the",
         "
            ABYSSAL n_eff = 20, which is conservative at the surface.")),
  list(id = "S", what = "SPO seasonal cycle: the OCEAN limb's PHASE",
       class = "OBSERVATION", src = paste(
         "SPO_SEAS_OCEAN_PHASE_INV = 8.52 months, 95 % CI [7.82, 9.20].",
         "
            The observed SPO CO2 and d13C first harmonics, split by the",
         "
            two-signature inversion (diag_seas_signature_inversion.R).",
         "
            \u26a0 PROVISIONAL: the split uses the model's own d13C",
         "
            SIGNATURES -- two signed SCALARS. The model's seasonal PHASE",
         "
            never enters, and the CI is bootstrapped over years CROSSED",
         "
            WITH the signature spread, so that dependence is inside it."),
       bound = paste("|z| <= DG_S_NSD on the PHASE, against a sigma DERIVED",
         "
            from the registered CI as (HI - LO) / (2 x 1.96). At NSD = 2",
         "
            that reproduces [LO, HI] to 0.02 months. \u26a0 The limb",
         "
            AMPLITUDE is REPORTED and NOT bounded: the registered",
         "
            SPO_SEAS_AMP_OCEAN_INV carries no interval, so no bound is",
         "
            derivable and inventing one would be choosing a number",
         "
            after seeing the answer."),
       scored = paste("NO, in the sense that matters. co2_seasonal_SPO IS a",
         "
            fitted stream -- but it scores the TOTAL, which the model",
         "
            already matches to ~1 % by cancelling a 2.55x land limb",
         "
            against a 0.45x ocean one. Nothing scores the PARTITION."),
       power  = paste("REAL, and it is the gate the seasonal arc was missing:",
         "
            a 5.17-month limb error survived weeks of fitting because",
         "
            the matched total has no power over the partition beneath",
         "
            it. \u26a0 The observed ocean phase rests on a pCO2 product,",
         "
            which omits the seasonality of gas transfer and K0.")),
  list(id = "12/12b", what = "Joos IRF: integrated pulse response, and the tail",
       class = "MODEL", src = paste(
         "Joos et al. 2013 multi-model mean, vintage 2013.",
         "
            ⚠ LAST-RESORT source class: a threshold from another model.",
         "
            Named here rather than discovered. 12b's band is CONSTRUCTED",
         "
            (Joos publishes no 5-95 % at TH 300) and says so."),
       bound = "12a: Joos published 5-95 %. 12b: constructed band, stated.",
       scored = "NO -- the IRF is not a stream",
       power  = "REAL, and 12b carries its OWN in-run mutation test.")
)

#' Print the ledger. Called by the gate REPORTS so the numbers and their
#' provenance never drift apart -- the caption-sync rule applied to gates.
dg_print_ledger <- function() {
  cat(sprintf("\n%s\nTHE GATE LEDGER -- source class, bound, and whether the gate has POWER\n%s\n",
              strrep("=", 74), strrep("=", 74)))
  for (g in DG_LEDGER) {
    cat(sprintf("\nGATE %s -- %s\n", g$id, g$what))
    cat(sprintf("  class : %s\n  source: %s\n  bound : %s\n  scored: %s\n  POWER : %s\n",
                g$class, g$src, g$bound, g$scored, g$power))
  }
  cat(sprintf("\n  GATE 7's sigmas, computed not quoted: it JUDGES at land %.2f / ocean %.2f\n",
              DG_G7_LAND_SD, DG_G7_OCEAN_SD))
  cat(sprintf("    (= LIK_GCB_LAND_SD %.2f x LIK_LAND_SINK_INFLATE %.1f, and the ocean\n",
              LIK_GCB_LAND_SD, LIK_LAND_SINK_INFLATE))
  cat(sprintf("    UNINFLATED at %.2f -- the objective's own asymmetry). GCB's STATED\n",
              LIK_GCB_OCEAN_SD))
  cat(sprintf("    sigmas, which the report prints beside the target, are %.2f / %.2f.\n",
              DG_GCB_LAND_SD, DG_GCB_OCEAN_SD))
  cat(sprintf("  The distributional gates share one strictness: DG_G5_NSD %g,\n",
              DG_G5_NSD))
  cat(sprintf("    DG_G7_NSD %g, DG_Q_NSD %g, DG_GD_NSD %g, DG_S_NSD %g.\n",
              DG_G7_NSD, DG_Q_NSD, DG_GD_NSD, DG_S_NSD))
  cat(sprintf("  GATE S's sigma is DERIVED, not chosen: (%.2f - %.2f) / (2 x 1.96) = %.4f mo,\n",
              DG_S_OBS_HI, DG_S_OBS_LO, DG_S_SD))
  cat(sprintf("    so |z| <= %g is months [%.3f, %.3f] against the registered [%.2f, %.2f].\n",
              DG_S_NSD, DG_S_OBS - DG_S_NSD * DG_S_SD, DG_S_OBS + DG_S_NSD * DG_S_SD,
              DG_S_OBS_LO, DG_S_OBS_HI))
  cat("  ⚠ STILL NO LAW-DERIVED GATE. GATE G (2026-09-02) is OBSERVATIONAL; it\n")
  cat("    puts an observation ON the surface carbonate state, which narrows the\n")
  cat("    hole without closing it. Candidates, none built: carbonate / Revelle\n")
  cat("    consistency, and Henry's-law solubility.\n")
}

# ---- resolve one arm to (params, luc_scale, bomb_total) -------------
#' @param arm "defaults", a name ccx_mode_file() knows, or a path to a mode file
#' @return list(p = model params, pm = fitted params, luc_scale, bomb_total,
#'   ..., src, migrated, md)
dg_vector <- function(arm) {
  p <- ccx_default_params()
  if (identical(arm, "defaults"))
    return(list(p = p, luc_scale = 1, bomb_total = DG_BOMB_REF,
                src = "uncalibrated defaults", migrated = character(0), md = NULL))
  f  <- ccx_mode_file(arm)
  md <- readRDS(f)
  # ⚠ MIGRATE, THEN SAY SO. `ccx_migrate_par_set()` reads the model's own
  # absence contract (`ccx_seas_lag_p()`); it never hand-fills, and it ERRORS on
  # a name no stored field can supply. A migrated vector is a legitimate thing
  # to MEASURE a gate at -- it is not a mode of this build's space, and every
  # caller must print `$migrated` so the reader knows which it is looking at.
  pm <- ccx_migrate_par_set(md$par_mode)
  mig <- attr(pm, "migrated")
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  p$pump_mode  <- md$pump_mode
  # ⚠ TWO LISTS, NOT ONE ([[ccx_two_param_lists]]). `p` is the MODEL's list --
  # ccx_default_params() overlaid with the fitted names it has slots for -- and
  # it is what ccx_spinup()/ccx_run_fast() take. `pm` is the FITTED list, all 22
  # names including the six nuisances (`bomb_total`, `luc_scale`, `sigma_d14c`,
  # `rep_dC`, `grad_off_*`) that have no model slot at all, and it is what
  # ccx_par_to_unc()/the objective take. Handing `p` to the objective raises
  # "lacks parameters this build fits"; handing `pm` to ccx_spinup() dies
  # cryptically. Both are returned, named for what they are.
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
       grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       md = md, migrated = mig,
       src = sprintf("%s (logpost %.2f%s)", basename(dirname(f)), md$logpost,
                     if (length(mig)) sprintf(", MIGRATED %d->%d",
                                              length(md$param_names),
                                              length(CCX_PARAM_NAMES)) else ""))
}

dg_run <- function(v) {
  sp <- ccx_spinup(v$p)
  F  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
}

# ---- GATE Q: air-sea d13C disequilibrium (2026-09-02) ----------------
# WHY IT EXISTS. It scores the ONE air-sea isotope quantity the likelihood does
# NOT: the ocean d13C stream is `ocean_grad_d13c`, a SURFACE-MINUS-DEEP
# gradient, and both `d13c_level_*` rows are ATMOSPHERIC. So nothing constrains
# the ABSOLUTE surface-ocean d13C, and this gate is an out-of-sample test of the
# air-sea fractionation pair rather than a restatement of a fitted stream.
# That is exactly what gave it power: before the 2026-09-02 pair it read
# -0.04 permil against an observed 0.60 +- 0.10, i.e. 6.4 sigma out AND THE
# WRONG SIGN, and no stream had ever objected.
#
# ⚠ WHAT IT IS NOT. The target comes from Quay et al. (2003), which takes its
# OWN fractionation factors from Zhang et al. (1995) -- the same paper the
# adopted constants come from. So this is NOT an independent check of the
# COEFFICIENTS; it is a check of the model STATE they produce. Said here rather
# than discovered later. [[threshold_from_obs_or_law]]
#
# ⚠ AND IT IS AN AREA-UNWEIGHTED TWO-BOX MEAN against a global observational
# estimate. The hemispheric pair is returned so a caller can see the spread,
# which is comparable to the observational sigma.
DG_Q_YEAR <- ccx_const("AIRSEA_D13C_DISEQ_YEAR")
DG_Q_OBS  <- ccx_const("AIRSEA_D13C_DISEQ_OBS")
DG_Q_SD   <- ccx_const("AIRSEA_D13C_DISEQ_SD")
DG_Q_NSD  <- 2      # how many observational sigma the gate allows. A DISTRIBUTIONAL
                    # claim against a stated +- , so it is scaled to that sigma and
                    # to nothing else. [[gate_bound_matches_its_claim]]

dg_gateQ <- function(r, v) {
  o <- r$out; aux <- r$sp$aux
  j <- which.min(abs(o$t - DG_Q_YEAR))
  d <- vapply(HEMIS, function(h) {
    # surface DIC d13C, from the state
    d_ml  <- 1000 * (o[[paste0("ml_C13_", h)]][j] /
                     (o[[paste0("ml_C_", h)]][j] * ccx_const("R13_VPDB")) - 1)
    # ⛔ THE EQUILIBRIUM OFFSET COMES FROM THE MEASUREMENT, NOT FROM THE MODEL.
    # The first version of this gate read it off the model's OWN alphas
    # (`ccx_alpha_as()`), which made it self-referential: it measured the
    # departure from whatever equilibrium the model happened to believe in, so
    # it PASSED the retired -2/-10 pair at 1.2 sigma when that pair is in fact
    # 6.4 sigma out. A gate derived from the code under test can never reject
    # it -- re-baselining in disguise. [[gate_reads_its_own_output]],
    # [[threshold_from_obs_or_law]]. Caught because BOTH settings passed, when
    # the legacy one was known to fail.
    eps_dicg <- ccx_const("ALPHA_AS_ZHANG_A") * aux$sst[[h]] * ccx_const("ALPHA_AS_FCO3") +
                ccx_const("ALPHA_AS_ZHANG_B") * aux$sst[[h]] + ccx_const("ALPHA_AS_ZHANG_C")
    (d_ml - eps_dicg) - o[[paste0("d13c_", h)]][j]
  }, 0)
  n_sd <- abs(mean(d) - DG_Q_OBS) / DG_Q_SD
  list(year = DG_Q_YEAR, by_hemi = d, mean = mean(d), obs = DG_Q_OBS,
       sd = DG_Q_SD, n_sd = n_sd, pass = n_sd <= DG_Q_NSD)
}

# ---- GATE 4: airborne fraction --------------------------------------
# AF = atmospheric growth / total emissions, both from THIS run: the model's own
# E_LUC carries luc_scale, so a fit that shrinks land use by 11 % shrinks the
# DENOMINATOR too. Scoring the model's growth against GCB's unscaled emissions
# would credit it with an AF it never produced. The scaled denominator is the
# self-consistent quantity; the unscaled one is printed beside it because
# luc_scale is a fitted nuisance and the reader is owed both.

# THE ANNUAL SERIES, ONE PER SIDE. Split out 2026-09-04 so that the decadal
# estimator below can be applied to the OBSERVATIONS with the same code path.
dg_af_annual_model <- function(r) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2 * DG_GtC_PER_PPM,
                       xout = bnd, rule = 2)$y
  el <- ccx_forcing_eluc_annual(r$F)
  # No ccx_forcing_efoss_annual() exists; this is the eluc helper's own recipe
  # (FUN = mean over the calendar year, because the columns are GtC/yr RATES,
  # not monthly masses -- summing them would give twelve times the emission).
  ef <- stats::aggregate(list(efoss = r$F$e_foss_NH + r$F$e_foss_SH),
                         by = list(year = r$F$year), FUN = mean)
  list(year = yrs, grow = diff(atm),
       foss = ef$efoss[match(yrs, ef$year)], luc = el$eluc[match(yrs, el$year)])
}

# ⚠ GCB's OWN AF USES fossil + luc AND EXCLUDES cement_carbonation, matching the
# model's numerator/denominator pair above; the carbonation sink is inside the
# model's ocean, not its emissions.
dg_af_annual_obs <- function() {
  g <- as.data.frame(ccx_prepare_obs()$gcb)
  list(year = g$year, grow = g$atm_growth, foss = g$fossil, luc = g$luc)
}

# ONE DECADAL ESTIMATOR, TWO CALLERS -- the whole point of this file.
# ⚠ `how` EXISTS ONLY SO THE RETIRED LITERALS' PROVENANCE STAYS TESTABLE. The
# gate is scored at the default, "ratio_of_sums", which is what the model side
# has always used; "mean_of_annual" is the estimator the typed observed vector
# turned out to have been built with, and nothing but the provenance test calls it.
dg_af_dec <- function(a, decades = DG_AF_DECADES, win = DG_AF_WIN,
                      how = c("ratio_of_sums", "mean_of_annual")) {
  how  <- match.arg(how)
  emis <- a$foss + a$luc
  af <- if (how == "ratio_of_sums") function(k) sum(a$grow[k]) / sum(emis[k])
        else                        function(k) mean(a$grow[k] / emis[k])
  k <- a$year >= win[1] & a$year <= win[2]
  dec <- vapply(decades, function(d) {
    kk <- a$year >= d & a$year <= min(d + 9, win[2]) & k; af(kk)
  }, numeric(1))
  list(all = af(k), dec = dec)
}

dg_gate4 <- function(r, v) {
  a <- dg_af_annual_model(r)
  g <- dg_af_dec(a)
  k <- a$year >= DG_AF_WIN[1] & a$year <= DG_AF_WIN[2]
  c(g, list(annual = a,
            all_unscaled = sum(a$grow[k]) /
                           sum((a$foss + a$luc / v$luc_scale)[k])))
}

# ---- the observed side, COMPUTED (see the constants block) -----------
DG_AF_OBS_ANNUAL <- dg_af_annual_obs()
local({
  o <- dg_af_dec(DG_AF_OBS_ANNUAL)
  DG_AF_OBS     <<- o$all
  DG_AF_OBS_DEC <<- o$dec
})

# ---- GATE 5: bomb curve, hemispheric aggregate ----------------------
# One estimator, applied to model and observations alike: parabolic refinement
# of the peak on the monthly series (the raw argmax is quantised to the sampling
# interval, which for the observations is 1/12 yr -- big enough to move the
# NH->SH lag by a tenth of its value), then a log-linear fit of the post-peak
# decline over Delta14C > DG_EFOLD_FLOOR.
dg_peak <- function(t, v) {
  i <- which.max(v)
  if (i <= 1 || i >= length(v)) return(c(t = t[i], v = v[i]))
  y1 <- v[i - 1]; y2 <- v[i]; y3 <- v[i + 1]
  d  <- 0.5 * (y1 - y3) / (y1 - 2 * y2 + y3)          # in samples
  c(t = t[i] + d * (t[i + 1] - t[i]), v = y2 - 0.25 * (y1 - y3) * d)
}
dg_efold <- function(t, v, tpk) {
  k <- t > tpk & v > DG_EFOLD_FLOOR
  if (sum(k) < 5) return(NA_real_)
  -1 / stats::coef(stats::lm(log(v[k]) ~ t[k]))[[2]]
}
dg_obs_bomb <- local({
  z <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
  w <- ccx_zone_weights()
  hemi <- function(h) {
    ww <- w[[h]]
    zz <- z[z$zone %in% names(ww), ]
    tt <- sort(unique(zz$decimal_date))
    m <- vapply(names(ww), function(nm) {
      s <- zz[zz$zone == nm, ]
      stats::approx(s$decimal_date, s$d14c, xout = tt, rule = 2)$y
    }, numeric(length(tt)))
    list(t = tt, v = as.vector(m %*% ww[colnames(m)]))
  }
  lapply(c(NH = "NH", SH = "SH"), hemi)
})
dg_gate5 <- function(r) {
  o <- r$out
  pk <- lapply(c(NH = "NH", SH = "SH"), function(h) {
    v <- o[[paste0("d14c_", h)]]
    p <- dg_peak(o$t, v)
    c(p, efold = dg_efold(o$t, v, p[["t"]]))
  })
  list(pk = pk, lag = pk$SH[["t"]] - pk$NH[["t"]])
}
#' The observed hemispheric bomb peaks, under the SAME estimator as the model
dg_obs_gate5 <- function() {
  lapply(dg_obs_bomb, function(x) {
    p <- dg_peak(x$t, x$v); c(p, efold = dg_efold(x$t, x$v, p[["t"]]))
  })
}

# ---- GATE 7: sinks (same construction as diag_app_params.R) ---------
# END HANDLING MATCHES THE OBJECTIVE, 2026-08-27. This used approx(rule = 2),
# which holds the stock FLAT across the half month the year boundaries fall
# outside the run at each end. R/likelihood.R rejected exactly that for the
# objective's own gcb_* streams and extrapolates LINEARLY instead: flat "would
# silently under-count the first and last year's flux ... which is the shape of
# a bug". Aligning it is what makes the two reconstructions agree at ANY window
# boundary -- dropping 2024 only hides today's instance.
#' Annual land / ocean sinks and CO2 growth from one run
#'
#' ⭐ EXTRACTED 2026-09-01 because `dg_gate7()` was not the only caller any more:
#' `diag_elnino_2023_sink_response.R` had copied this construction to get the
#' same quantity YEAR BY YEAR, and a second copy of an estimator is the
#' caption-sync bug class -- the day the end handling changes in one, the two
#' report the same sink at two values and nothing says so. Gate 7 is now the
#' WINDOW MEAN of this series, which is exactly what it always was.
#'
#' @return list(year, land, ocean, growth_ppm)
dg_annual_sinks <- function(r) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  tt <- o$t; n <- length(tt)
  stock <- function(v) {
    y  <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    if (any(hi)) y[hi] <- v[n] + (bnd[hi] - tt[n]) * (v[n] - v[n - 1]) / (tt[n] - tt[n - 1])
    diff(y)
  }
  el  <- ccx_forcing_eluc_annual(r$F)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2, xout = bnd, rule = 2)$y
  list(year = yrs, ocean = stock(o$ocean_C),
       land = stock(o$land_C) + el$eluc[match(yrs, el$year)],
       growth_ppm = diff(atm))
}

dg_gate7 <- function(r) {
  a <- dg_annual_sinks(r)
  k <- a$year >= DG_SINK_WIN[1] & a$year <= DG_SINK_WIN[2]
  list(ocean = mean(a$ocean[k]), land = mean(a$land[k]))
}

# ---- GATE 7 VERDICT, centralised 2026-09-02 -------------------------
#' The gate-7 z-scores and pass/fail, in ONE place
#'
#' ⭐ WHY THIS FUNCTION EXISTS. Until 2026-09-02 the z-scores and the verdict were
#' computed INLINE in both callers, while this file's header claimed "one kernel,
#' two callers". The kernel was centralised on 08-31f; the verdict was not, so the
#' one number that decides pass/fail could move in one caller and not the other.
#' That is the caption-sync bug class, one level up.
#'
#' @param g7 the list from dg_gate7()
#' @param tgt the list from dg_gcb_target()
dg_gate7_verdict <- function(g7, tgt) {
  zl <- (g7$land  - tgt$land)  / DG_G7_LAND_SD
  zo <- (g7$ocean - tgt$ocean) / DG_G7_OCEAN_SD
  list(z_land = zl, z_ocean = zo,
       # ALSO at GCB's bare stated sigma, because that is what every result
       # before 2026-09-02 reported and a reader comparing to one needs it.
       z_land_bare  = (g7$land  - tgt$land)  / DG_GCB_LAND_SD,
       z_ocean_bare = (g7$ocean - tgt$ocean) / DG_GCB_OCEAN_SD,
       pass = max(abs(c(zl, zo))) <= DG_G7_NSD)
}

# =====================================================================
# GATE 4 AND GATE 5 GET BOUNDS (2026-09-02, Marcus)
#
# Both printed tables and no verdict, so neither could fail -- the 09-02 ledger's
# starkest finding. Giving them bounds is a DESIGN decision, and the two need
# DIFFERENT KINDS of bound because they make different kinds of claim
# ([[gate_bound_matches_its_claim]]).
# =====================================================================

# ---- GATE 4: an ORDERING, so it gets NO THRESHOLD -------------------
# The gate's own stated test is "the model must not be SMOOTHER than this": its
# decadal airborne fraction must vary at least as much as GCB's does. That is an
# ORDERING between two MEASURED quantities, and the rule for an ordering is that
# it gets no threshold at all -- inventing one here would be choosing the physics.
# ⚠ THE AF *LEVEL* DELIBERATELY STAYS UNBOUNDED. It is near-algebraic in
# quantities the objective already fits (atmospheric growth is a scored stream and
# emissions are inputs), so a bound on it would test the optimiser, not the model.
# The ledger says so; this is that sentence turned into code.
DG_G4_CLAIM <- "sd(model decadal AF) >= sd(observed decadal AF) -- an ORDERING"
dg_gate4_verdict <- function(g4) {
  sm <- stats::sd(g4$dec); so <- stats::sd(DG_AF_OBS_DEC)
  list(sd_model = sm, sd_obs = so, ratio = sm / so, pass = sm >= so)
}

# ---- GATE 5: a DISTRIBUTIONAL claim, so it needs a SIGMA ------------
# ⛔ AND HUA 2022 PUBLISHES NO SIGMA ON A HEMISPHERIC PEAK TIME OR ON THE NH->SH
# LAG, so one has to be DERIVED, not typed. The rule is observation first, law
# second, another model last ([[threshold_from_obs_or_law]]), and the observation
# can supply it: the hemispheric aggregate is a weighted mean over Hua's ZONES, so
# recomputing the same estimator with one zone left out at a time gives the
# spread the aggregate's own spatial composition carries. That is a tolerance
# SCALED TO THE QUANTITY IT TESTS ([[tolerance_scaled_to_spread]]), not a
# hand-picked gate.
# ⚠ WHAT IT IS AND IS NOT. It is the sensitivity of the aggregate to its zonal
# composition. It is NOT a measurement error on the underlying Delta14C, and with
# 3 NH zones and 2 SH zones it rests on few draws -- so it is reported with its n,
# and it should be read as an ORDER OF MAGNITUDE for the tolerance rather than a
# calibrated standard error.
# ⚠ A SECOND, THRESHOLD-FREE CLAIM RIDES ALONGSIDE, and it is the stronger one
# because it needs no sigma at all: the bomb source was NORTHERN, so the SH peak
# must come AFTER the NH peak and the NH peak must be HIGHER. Those are orderings
# and are bounded as orderings.
DG_G5_NSD <- 2      # harmonised with DG_Q_NSD and DG_G7_NSD, 2026-09-02

#' Leave-one-zone-out spread of the observed gate-5 quantities
#'
#' Same estimator as dg_obs_gate5(), re-run with each contributing zone dropped
#' (weights renormalised over the survivors). Returns the sd across those
#' re-runs for each quantity, plus the number of draws behind it.
dg_obs_gate5_spread <- function() {
  w  <- ccx_zone_weights()
  z  <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
  agg <- function(ww) {
    zz <- z[z$zone %in% names(ww), ]
    tt <- sort(unique(zz$decimal_date))
    m <- vapply(names(ww), function(nm) {
      s <- zz[zz$zone == nm, ]
      stats::approx(s$decimal_date, s$d14c, xout = tt, rule = 2)$y
    }, numeric(length(tt)))
    v <- as.vector(m %*% (ww[colnames(m)] / sum(ww)))
    p <- dg_peak(tt, v)
    c(p, efold = dg_efold(tt, v, p[["t"]]))
  }
  # ⚠ EACH HEMISPHERE'S SPREAD IS TAKEN OVER ITS OWN DISTINCT DRAWS, and that
  # matters. Pooling the NH quantities over all (NH-drop x SH-drop) COMBINATIONS
  # repeats each NH value once per SH drop; the mean is unchanged but the n-1
  # denominator is not, and the sd comes out ~10 % LOW -- which would make the
  # gate stricter than the data warrants, silently. Only the LAG is a genuine
  # function of both, so only the lag is taken over the combinations.
  drop_sets <- function(ww) c(list(ww), lapply(names(ww), function(nm)
    ww[setdiff(names(ww), nm)]))
  nh <- lapply(drop_sets(w$NH), agg)
  sh <- lapply(drop_sets(w$SH), agg)
  get <- function(l, f) vapply(l, function(x) x[[f]], numeric(1))
  lag <- as.vector(outer(get(sh, "t"), get(nh, "t"), `-`))
  list(sd = c(nh_t = stats::sd(get(nh, "t")), nh_v = stats::sd(get(nh, "v")),
              sh_t = stats::sd(get(sh, "t")), sh_v = stats::sd(get(sh, "v")),
              lag  = stats::sd(lag),
              nh_efold = stats::sd(get(nh, "efold"))),
       n = c(nh = length(nh), sh = length(sh), lag = length(lag)),
       nh = nh, sh = sh)
}

#' Gate 5's verdict: two orderings with no threshold, and three z-scores
#' @param g5 the list from dg_gate5()
#' @param ob the list from dg_obs_gate5()
#' @param sp the list from dg_obs_gate5_spread()
dg_gate5_verdict <- function(g5, ob, sp) {
  lag_obs <- ob$SH[["t"]] - ob$NH[["t"]]
  z <- c(nh_t = (g5$pk$NH[["t"]] - ob$NH[["t"]]) / sp$sd[["nh_t"]],
         sh_t = (g5$pk$SH[["t"]] - ob$SH[["t"]]) / sp$sd[["sh_t"]],
         lag  = (g5$lag - lag_obs)              / sp$sd[["lag"]])
  ord <- c(sh_after_nh = g5$lag > 0,
           nh_peak_higher = g5$pk$NH[["v"]] > g5$pk$SH[["v"]])
  list(z = z, ord = ord,
       pass = all(abs(z) <= DG_G5_NSD) && all(ord),
       pass_z = all(abs(z) <= DG_G5_NSD), pass_ord = all(ord))
}

# ---- the gate-7 TARGETS, recomputed on DG_SINK_WIN from the obs series -------
dg_gcb_target <- function(win) {
  g <- as.data.frame(ccx_prepare_obs()$gcb)
  k <- g$year >= win[1] & g$year <= win[2]
  list(land = mean(g$land_sink[k]), ocean = mean(g$ocean_sink[k]), n = sum(k))
}

# =====================================================================
# GATE G: OCEAN DIC LEVEL AGAINST GLODAPv2.2023  (2026-09-02, Marcus)
#
# WHY IT EXISTS. The 09-02 ledger found NOT ONE law-derived gate in the set and
# named this as the most valuable candidate that could be built: gate 12a reports
# an ocean-CAPACITY defect it cannot LOCALISE, and nothing in the repo tests the
# ocean's absolute DIC against an observation.
#
# ⛔ AND THE FIRST DESIGN -- "the whole-column inventory" -- IS PARTLY CIRCULAR,
# which is why the BOUND is not on it. The biological pump's export field was
# SOLVED to hold `DIC_ml(model) + [DIC_k(obs) - DIC_0(obs)]` as an exact steady
# state: the observed GRADIENT, anchored on the model's own mixed layer. So the
# profile's SHAPE is GLODAP-derived by construction, and a gate on the inventory
# would be partly reading back what built it -- [[gate_reads_its_own_output]].
# (Not WHOLLY circular: the pump's magnitude carries a prior and the model's
# gradient comes out ~13 % larger than observed, so the shape is informed by
# GLODAP rather than equal to it. The inventory is therefore REPORTED, with this
# said, and not bounded.)
#
# ✅ WHAT *IS* OUT-OF-SAMPLE, AND IT WAS CHECKED RATHER THAN ASSUMED: the
# MIXED-LAYER DIC LEVEL.
#   * The likelihood's three ocean rows are GRADIENTS (`ocean_grad_dic`,
#     `_d13c`, `_alk` -- surface MINUS deep, R/likelihood.R:1541), and the CO2
#     and d13C gradient rows carry FITTED offsets. A gradient with a fitted
#     offset is blind to the level.
#   * `d14c_deep_ocean` is Delta14C, not DIC. `gcb_ocean_sink` is a FLUX, not a
#     stock.
#   * The model's mixed-layer DIC is set by carbonate equilibrium with the 1750
#     atmosphere at `ALK_SURFACE`, a FIXED constant whose own status string says
#     it still "NEEDS a cited global-mean surface value" -- it is not from GLODAP.
#   ⇒ Nothing that produced the model's surface DIC level saw this observation.
#
# AND IT IS THE RIGHT PLACE TO LOOK FOR AN OCEAN-CAPACITY DEFECT: the surface
# Revelle factor, which sets how much of a pulse the ocean can take, is a
# function of surface DIC and alkalinity. A level that is right bounds the defect
# AWAY from the surface carbonate state.
#
# ⚠ LIKE-FOR-LIKE IN TIME, and it is not free: GLODAP bottles are MODERN, so the
# model is run to the bottles' OWN MEAN YEAR rather than to 2024 or compared at
# the 1750 spinup. The epoch is DERIVED from the data (mean sampling year of the
# accepted DIC bottles), never typed. Comparing a preindustrial model column with
# a modern observation would show the anthropogenic increment as a model defect.
#
# ⚠ THE SIGMA IS AN SE, NOT THE SPREAD, and it uses the n_eff convention Marcus
# already ruled for the deep Delta14C target on 2026-08-14 (`LIK_D14C_DEEP_NEFF`)
# rather than a new number chosen here. "The spread is NOT the sigma"
# ([[ccx_glodap_deep]]): a one-box model is scored against the volume-weighted
# MEAN, whose uncertainty is the spread over an effective sample size. ⚠ n_eff =
# 20 was chosen for the ABYSS, where water masses are basin-coherent; the surface
# is better sampled and less coherent, so borrowing it is CONSERVATIVE -- it
# makes this gate more lenient than the surface data warrant, in the direction
# that weakens a gate. Said out loud rather than silently exploited, and the
# report walks z across a range of n_eff so the reader can see the sensitivity.
# =====================================================================
DG_GD_NSD  <- 2                      # harmonised with DG_Q_NSD / DG_G5_NSD / DG_G7_NSD
DG_GD_NEFF <- LIK_D14C_DEEP_NEFF     # the ruled convention, not a new number
DG_GD_NEFF_WALK <- c(5, 20, 100, 500)   # sensitivity, printed not chosen

#' The observed side of GATE G: epoch, surface DIC, spread, column inventory
#'
#' ⛔ HARD-ERRORS if the GLODAP helpers are not loaded, rather than skipping. A
#' gate that quietly does not run reports nothing while looking like a pass
#' ([[broken_gate_reports_nothing]]).
#' @param grid an ccx_ocean_grid() for the arm under test -- the layers must be
#'   the MODEL's own, or the surface row compares two different slabs.
dg_gateG_obs <- function(grid) {
  if (!exists("dg_obs_profile") || !exists("dg_glodap_bottles"))
    stop("GATE G needs the GLODAP helpers. source(ccx_path(\"calibration\", ",
         "\"lib_glodap_obs.R\")) first. ⛔ Do NOT source pump_shim.R for them: ",
         "it wraps ccx_deriv() and would change the model being gated.")
  d  <- dg_glodap_bottles()
  ok <- is.finite(d$tco2) & d$tco2 > -900 & is.finite(d$tco2f) & d$tco2f == PUMP_FLAG_OK
  op <- dg_obs_profile(grid)
  list(epoch_mean = mean(d$year[ok]), epoch_median = stats::median(d$year[ok]),
       epoch_range = range(d$year[ok]), n_bottles = sum(ok),
       surf = op$dic[1], surf_sd = op$dic_sd[1], surf_n = op$n_dic[1],
       profile = op)
}

#' The model side of GATE G at one arm, AT THE OBSERVATION'S OWN EPOCH
#' @param v a dg_vector(); @param obs a dg_gateG_obs()
dg_gateG <- function(v, obs) {
  sp   <- ccx_spinup(v$p)
  aux  <- sp$aux
  grid <- ccx_ocean_grid(v$p$h_ml)
  yr   <- round(obs$epoch_mean)
  F  <- ccx_build_forcing("historical", c(DG_YEARS[1], yr), prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  st <- ccx_run_fast(sp, F)$state
  rho <- ccx_const("RHO_SEAWATER")
  ml <- function(y, h) y[aux$idx[[h]]$ml, "C"] * aux$mol_per_GtC /
          (aux$a_oc[[h]] * grid$dz[1] * rho) * 1e6
  # AREA-WEIGHTED, because the observation is a global volume-weighted mean and
  # the two hemispheres differ by ~15 umol/kg (the model's solubility pump).
  aw <- function(y) (ml(y, "NH") * aux$a_oc$NH + ml(y, "SH") * aux$a_oc$SH) /
          (aux$a_oc$NH + aux$a_oc$SH)
  ix   <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)))
  mass <- (aux$a_oc$NH + aux$a_oc$SH) * grid$dz * rho
  list(year = yr, surf = aw(st), surf_1750 = aw(sp$y),
       surf_NH = ml(st, "NH"), surf_SH = ml(st, "SH"),
       inv = sum(st[ix, "C"]), inv_1750 = sum(sp$y[ix, "C"]),
       inv_obs = sum(obs$profile$dic * 1e-6 * mass / aux$mol_per_GtC))
}

#' GATE G's verdict: a distributional claim on the SURFACE LEVEL only
dg_gateG_verdict <- function(g, obs, n_eff = DG_GD_NEFF) {
  se <- obs$surf_sd / sqrt(n_eff)
  z  <- (g$surf - obs$surf) / se
  list(se = se, z = z, n_eff = n_eff, pass = abs(z) <= DG_GD_NSD,
       d_umol = g$surf - obs$surf,
       # REPORTED, NOT BOUNDED -- see the header on why the inventory is partly
       # constructed from the observation it would be tested against.
       inv_d = g$inv - g$inv_obs, inv_pct = 100 * (g$inv - g$inv_obs) / g$inv_obs,
       uptake = g$inv - g$inv_1750)
}

# ---- per-stream logL at a vector, for provenance and for pricing ----
# The LIKELIHOOD is recomputed, not the posterior: a refit's h_ml band
# renormalises the PRIOR and is not reconstructible from ccx_default_params()
# (memory ccx_hml_band_provenance), so a logpost comparison would indict the
# product for a property of the producer. par_mode is band-safe.
dg_streams <- function(r, v) {
  o <- r$out
  eluc <- ccx_forcing_eluc_annual(r$F)
  err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
              grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
  ccx_loglik(o, ccx_prepare_obs(), err, luc = eluc,
             deep = r$sp$diagnostics$d14c_bottom_box,
             ocean_grad = ccx_ocean_grad_scored(o, r$sp), by_stream = TRUE)
}

# =====================================================================
# GATE S -- THE SPO **OCEAN** SEASONAL LIMB'S **PHASE** (2026-09-03)
#
# WHY IT EXISTS, AND WHY IT IS OWED. The model's only active SH ocean seasonal
# limb peaks at month 3.35 against an observed 8.52 -- a 5.17 MONTH error, i.e.
# very nearly antiphase -- and NOTHING IN THE OBJECTIVE OR IN THIS GATE SET
# SCORED IT. That is how an error of that size survived for weeks: the SPO CO2
# seasonal rows ARE in the likelihood, but they score the TOTAL, which the model
# matches to ~1 % by cancelling a 2.55x land limb against a 0.45x ocean one
# ([[seas_right_observable_wrong_drivers]]). A matched total has no power over
# the partition that produced it. This gate scores the partition's PHASE, which
# is the functional that does.
#
# ⭐ THE CLAIM IS THE PHASE, AND ONLY THE PHASE. The limb AMPLITUDE is REPORTED
# beside it and is NOT bounded, for the same reason GATE G reports the column
# inventory unbounded: `SPO_SEAS_AMP_OCEAN_INV` is registered with NO interval,
# so no bound is derivable from it and inventing one would be choosing a number
# after seeing the result. [[gate_bound_matches_its_claim]]
#
# ⭐ WHAT THE TARGET DEPENDS ON, STATED BEFORE IT IS USED. `SPO_SEAS_OCEAN_PHASE_INV`
# is on the PROVISIONAL ledger because it is an observation inverted through the
# model's own d13C SIGNATURES ([[ccx_spo_constants_registry]]). That dependence
# is real and it is bounded: the inversion (diag_seas_signature_inversion.R) takes
# the OBSERVED SPO CO2 and d13C first-harmonic vectors and two signed SCALARS
# s_L, s_O (permil per ppm). The model's own seasonal PHASE does not enter it at
# any point -- so this gate is NOT reading back the quantity it tests
# ([[gate_reads_its_own_output]]) -- and the registered 95 % CI was bootstrapped
# over YEARS **crossed with the signature spread**, so the signature dependence
# is already inside the interval this gate judges against.
#
# THE SIGMA IS DERIVED FROM THE REGISTERED CI, NOT CHOSEN. sd = (HI - LO) /
# (2 * 1.96). At DG_S_NSD = 2 -- the one strictness the distributional gates
# share -- the resulting interval reproduces the registered [LO, HI] to 0.02
# months, so harmonising with the family costs nothing and invents nothing.
#
# ⚠ AND THE OBSERVED PHASE ITSELF RESTS ON A pCO2 PRODUCT on the ocean side
# (data-raw/download_data.R sec.6c), which omits the seasonality of gas transfer
# and K0. That caveat belongs to the constant and is repeated at its use.
# =====================================================================
# ONE ESTIMATOR, not a second copy. `lib_seas_limbs.R` is THE SPO limb estimator
# for this project and every file that quotes a limb sources it; a gate carrying
# its own peak-to-peak / peak-month arithmetic is the caption-sync bug class, and
# peak-to-peak vs semi-amplitude has already inverted a conclusion on this arc
# ([[amp_definition_mismatch]]).
source(ccx_path("calibration", "lib_seas_limbs.R"))

DG_S_OBS     <- ccx_const("SPO_SEAS_OCEAN_PHASE_INV")
DG_S_OBS_LO  <- ccx_const("SPO_SEAS_OCEAN_PHASE_INV_LO")
DG_S_OBS_HI  <- ccx_const("SPO_SEAS_OCEAN_PHASE_INV_HI")
DG_S_AMP_OBS <- ccx_const("SPO_SEAS_AMP_OCEAN_INV")   # REPORTED, NOT BOUNDED
DG_S_SD      <- (DG_S_OBS_HI - DG_S_OBS_LO) / (2 * stats::qnorm(0.975))
DG_S_NSD     <- 2    # harmonised with DG_Q_NSD / DG_G5_NSD / DG_G7_NSD / DG_GD_NSD
# ⚠ THE KNOCKOUT MUST KILL **BOTH** SH OCEAN LIMBS. `sst_seas_amp_SH = 0` alone
# leaves the entrainment limb running -- the bug the channel exposed on 27g --
# and this gate exists precisely to be run with that channel switched ON, so the
# one-limb form would silently gate the wrong thing. Taken from SL_CASES rather
# than retyped, so it cannot drift from the estimator's own definition.
DG_S_KO <- SL_CASES$SH_ocean

#' Signed CIRCULAR difference between two months of year, in (-6, +6]
#' Months are an angle: 11.9 and 0.1 are 0.2 months apart, not 11.8.
dg_mo_diff <- function(a, b) ((a - b + 6) %% 12) - 6

#' The SPO CO2 first-harmonic vector at one dg_vector(), as (a, b)
dg_spo_vec <- function(v, obs) {
  r  <- dg_run(v)
  ms <- ccx_model_stats(r$out, obs)
  h  <- ms$co2_seas$SPO
  if (is.null(h)) stop("GATE S: the run returned no SPO seasonal harmonic.")
  c(mean(h$a), mean(h$b))
}

#' GATE S's model side: the SH-OCEAN limb of SPO, by knockout
#'
#' The limb is BASE MINUS the run with both SH ocean drivers zeroed -- the
#' contribution those drivers make to SPO, as a VECTOR. Limbs are vectors: an
#' amplitude that grows while the phase stays antiphase makes the cancellation
#' WORSE, not better ([[ccx_seas_2x2_admissible]]).
#' @param v a dg_vector(); @param obs a ccx_prepare_obs()
dg_gateS <- function(v, obs) {
  base <- dg_spo_vec(v, obs)
  vk   <- v
  for (n in names(DG_S_KO)) vk$p[[n]] <- DG_S_KO[[n]]
  ko   <- dg_spo_vec(vk, obs)
  d    <- base - ko
  list(v_ocean = d, amp = sl_amp(d), mo = sl_ang_mo(d),
       v_total = base, amp_total = sl_amp(base), mo_total = sl_ang_mo(base),
       ent = v$p$ent_seas_amp_SH, sst_amp_SH = v$p$sst_seas_amp_SH)
}

#' GATE S's verdict: a DISTRIBUTIONAL claim on the limb PHASE alone
dg_gateS_verdict <- function(g, obs_mo = DG_S_OBS, sd = DG_S_SD, n_sd = DG_S_NSD) {
  d <- dg_mo_diff(g$mo, obs_mo)
  z <- d / sd
  list(mo = g$mo, obs_mo = obs_mo, d_mo = d, sd = sd, z = z,
       n_sd = n_sd, pass = abs(z) <= n_sd,
       lo = obs_mo - n_sd * sd, hi = obs_mo + n_sd * sd,
       # REPORTED, NOT BOUNDED -- the registered amplitude carries no interval.
       amp = g$amp, amp_obs = DG_S_AMP_OBS, amp_ratio = g$amp / DG_S_AMP_OBS)
}
