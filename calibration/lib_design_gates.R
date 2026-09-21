# =====================================================================
# lib_design_gates.R -- the DESIGN sec.6 GATE KERNELS, in one place.
#   LIVE gates (DG_LEDGER, 2026-09-12): V, H, GL, 5, G, Q, 7, S, P7.
#   COMPARISONS, not gates: 12 (the Joos IRF) and L (the pulse partition).
#   RETIRED: 4 (2026-09-04; dg_gate4_verdict() errors by name, the AF is still
#   printed). The 'gate 4 / 5 / 7' this header named until 09-12 is the 08-31f
#   founding set, kept in the paragraph below as history.
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
DG_YEARS     <- c(1750, 2025)   # ⭐ RULED 2026-09-12 (Marcus): the gate run extends
                                 # through 2025 so the 2025.0 year boundary is INTERIOR
                                 # and the 2024 stock increments are interpolated, not
                                 # extrapolated (flat growth vs linear stocks disagreed by
                                 # 0.97 GtC/yr in 2024 -- the December seasonal slope).
                                 # 2025 is a FORCING-HELD year (emissions/GMST end 2024)
                                 # and is never a year of the annual series:
DG_SINK_LAST <- DG_YEARS[2] - 1L # the last calendar year the annual readers report.

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
# ⭐ RULING 1 (Marcus, 2026-09-09): GATE 5's NH STATISTIC IS THE TROUGH DEPTH,
# and the first-peak time is REPORTED rather than gated. WHY: the observed NH
# aggregate is DOUBLE-PEAKED (the 1963 and 1964 spring stratospheric intrusions)
# and its two maxima differ by 2.4 %, so `dg_peak()`'s argmax flips between lumps
# under a trivial perturbation of either curve. The model reproduces the double
# peak and merely picks the OTHER lump, which is where the old "+2.17 sigma late"
# came from -- an argmax on a bimodal curve, not a timing error
# ([[ccx_gate5_argmax_on_bimodal]], diag_gate5_bimodal.R 2026-09-08h). The trough
# DEPTH is the same curve's shape read by a statistic that cannot flip.
# ⚠ THE WINDOWS ARE THE ONES THE 09-08h MEASUREMENT WAS MADE ON, carried over
# unchanged so the promoted gate reports the number that diagnostic reported.
# They deliberately OVERLAP at the shoulders: each is a bracket for its own
# extremum, not a partition of the interval.
DG_G5_W1 <- c(1963.3, 1964.05)       # first (1963 intrusion) peak, yr
DG_G5_WT <- c(1963.9, 1964.45)       # the inter-peak trough
DG_G5_W2 <- c(1964.3, 1965.1)        # second (1964 intrusion) peak

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
  list(id = "4", what = "airborne fraction 1959-2024 -- ⛔ RETIRED 2026-09-04",
       class = "OBSERVATION", src = "GCB 2025",
       bound = paste("NONE. The verdict is GONE; the AF is still PRINTED.",
         "
            `dg_gate4_verdict()` ERRORS with DG_G4_RETIRED."),
       scored = "YES, and that is why it went: numerator = a scored stream,",
       power  = paste("⛔ NONE, MEASURED [[ccx_gate4_no_power]]. Its 2020s signal",
         "
            reappears in co2_level_MLO at mean z -0.96 / max |z| 1.63;",
         "
            70 % of its target's variance was sampling noise; and its",
         "
            sd() ranked the UNCALIBRATED DEFAULTS above the adopted",
         "
            mode because it cannot tell a drift from a wiggle.",
         "
            ⇒ REPLACED BY GATE V.")),
  list(id = "V", what = "interannual CO2 growth variability 1959-2024",
       class = "OBSERVATION", src = "GCB 2025 annual budget",
       bound = paste("DISTRIBUTIONAL, |z| <= DG_V_NSD (2), TWO-SIDED, against",
         "
            the OBSERVED sd's OWN sampling error sd/sqrt(2 nu), nu the",
         "
            RESIDUAL dof n - (DG_V_DF + 1) = 62 (dg_v_sd, 09-12; both",
         "
            used n - 1 = 65 until then, 0.080) = 0.084 GtC/yr -- derived",
         "
            from the observation, not chosen, and MC-validated."),
       scored = "NO. co2_level_* scores LEVELS at a soft 1.0 ppm sigma; nothing",
       power  = paste("REAL, and it is the only gate that tests a SECOND-ORDER",
         "
            observation. On the 09-12 cut (run to 2025, dof se) ent26",
         "
            reads -2.53 (0.721 vs 0.933 GtC/yr), hilda31p -2.57,",
         "
            hilda31s -2.48; it read -2.67 (0.698 vs 0.911), defaults",
         "
            -3.42, on the 09-04 cut. The model's variability should",
         "
            come from observed TEMPERATURE, VOLCANIC AOD via diffuse",
         "
            light, and the ENSO land+ocean links -- all already wired,",
         "
            so this bounds their COMBINED amplitude.")),
  list(id = "H", what = "interhemispheric gradient CONTRAST (CO2 vs d13C)",
       class = "OBSERVATION", src = paste(
         "The observed MLO-SPO gradients themselves -- CO2 1962-2023",
         "
            (n 59) and d13C 1980-2023 (n 43). Both means and both",
         "
            standard errors are COMPUTED at source time from the obs",
         "
            bundle, never typed."),
       bound = paste("|z| <= DG_H_NSD on the CONTRAST of the two ratios,",
         "
            R_d13c - R_co2, against the OBSERVED means' OWN sampling",
         "
            error se = sd_resid/sqrt(n_eff) propagated in quadrature,",
         "
            BOTH from the DETRENDED series (the gradients trend as",
         "
            emissions grow). ⭐ RE-CUT 2026-09-12: until then the sd was",
         "
            of the RAW trended gradient over a residual n_eff -- 3.4x",
         "
            too wide for CO2 (0.927 vs 0.273), 1.6x for d13C. ⚠ The",
         "
            model side is",
         "
            DETERMINISTIC and contributes no error term."),
       scored = paste("NO -- and this is the whole point. Both gradient streams",
         "
            are scored THROUGH A FITTED ADDITIVE OFFSET, so the",
         "
            objective constrains their year-to-year VARIATION and not",
         "
            their LEVEL. At ent26 each offset sits on the discrepancy",
         "
            it absorbs to 4 dp (grad_off_d13c +0.06464 vs an error of",
         "
            -0.06470), so the d13C gradient is 1.97x observed while",
         "
            d13c_gradient still scores +106 log-units."),
       power  = paste("REAL, and it has an INTERNAL CONTROL. A transport or",
         "
            representation error acts on the interhemispheric exchange,",
         "
            which is TRACER-INDEPENDENT, so it scales both gradients",
         "
            alike and cancels in the contrast; the CO2 arm absorbs it.",
         "
            ⚠ WITHDRAWN 2026-09-12: 'that control PASSES on its own level",
         "
            at ent26 (-1.06 se)' was the raw-sd reading; on the residual",
         "
            se the CO2 control is ITSELF out at z_level -3.5 to -3.6 at",
         "
            every arm (0.913-0.916x observed) -- an 8 % transport /",
         "
            representation miss, significant at the station record's",
         "
            precision -- so the contrast isolates the part of the d13C",
         "
            miss that is NOT that. ent26 reads z +11.65, hilda31s +11.59",
         "
            (+6.55 / +6.56 defaults on the raw sd) -- calibration moved",
         "
            the contrast 1.473 -> 1.056 but not its significance.",
         "
            ⇒ Rejecting it says the miss is NOT transport: it is in",
         "
            the isotopic source or the air-sea disequilibrium, which is",
         "
            what a pure-diffusion ocean cannot hold.")),
  list(id = "5", what = "bomb 14C peak, hemispheric lag, e-fold",
       class = "OBSERVATION", src = "Hua et al. 2022, hemispheric aggregate",
       bound = paste("TWO KINDS (2026-09-02). ORDERINGS, no threshold:",
         "
            SH peaks AFTER NH, NH peak HIGHER than SH -- the bomb source",
         "
            was northern. DISTRIBUTIONAL: |z| <= DG_G5_NSD, against a sigma",
         "
            DERIVED by leave-one-zone-out on the observed aggregate (Hua",
         "
            publishes none). ⭐ RULING 1 (2026-09-09): the NH member of that",
         "
            set is the inter-peak TROUGH DEPTH (obs 111.3 permil, sigma",
         "
            33.8), NOT the argmax peak time, which on a double-peaked curve",
         "
            flips lumps; the SH peak time is unchanged. ⭐ THE LAG IS SH",
         "
            PEAK TIME MINUS THE NH FIRST-PEAK TIME (2026-09-12, review",
         "
            A4): on the argmax it inherited the lump flip ruling 1 removed",
         "
            from nh_t (z -0.95 on the 1964 lump vs +1.7 on the first",
         "
            peak). The NH first-peak time is REPORTED. ⭐ The ruling's premise is",
         "
            MEASURED by this same spread: the argmax time's zonal sd is",
         "
            0.444 yr against the first peak's 0.042 yr, 10x tighter.",
         "
            ⚠ That sigma is the aggregate's sensitivity to its own zonal",
         "
            composition, not a measurement error, and rests on few draws --",
         "
            33.8 on 111.3 is a 30 % tolerance from 4 draws, an ORDER OF",
         "
            MAGNITUDE, not a calibrated standard error."),
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
       bound = paste("n_sd <= DG_Q_NSD, a distributional claim on the stated sigma.",
         "
            ⭐ RE-WEIGHTED 2026-09-21 (f): the four surface boxes' 1995 D's",
         "
            (gate D's regions) combined with the GLODAP bottles' NCEP-wind^2",
         "
            k-weights per box (Quay's 0.60 is exchange-weighted; the bottles",
         "
            give 0.545 k-weighted, 0.846 area-weighted). The ML-only",
         "
            area-weighted read below is returned as mean_area_ml, not scored.",
         "
            ⭐ RE-CUT 2026-09-12 (Marcus): the statistic is the CALENDAR-YEAR",
         "
            MEAN over the 12 monthly rows of DG_Q_YEAR, the two boxes",
         "
            AREA-WEIGHTED (ccx_column_area; a_oc NH 0.429). Until then it",
         "
            read ONE instant (t = 1995.000 = Dec 1994) and the verdict was",
         "
            phase-dependent: over the year hilda31s n_sd 2.18-3.62 (instant",
         "
            2.63), ent26 0.85-2.29 -- across the PASS line."),
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
       class = "OBSERVATION + LAW", src = paste(
         "SO_DPCO2_PEAK_MO = 7.41 months: the Southern Ocean (40-90 S)",
         "
            air-sea pCO2 DIFFERENCE, first harmonic. Ocean side is the",
         "
            Landschutzer/Laruelle SOM-FFN climatology (NCEI 0209633),",
         "
            atmospheric side the observed SPO CO2 harmonic.",
         "
            \u2b50 NO MODEL IN THE LOOP.",
         "
            \u26d4 REBASED 2026-09-04h. The old target,",
         "
            SPO_SEAS_OCEAN_PHASE_INV = 8.52 [7.82, 9.20], came from the",
         "
            two-signature inversion and is RETIRED: the 09-02",
         "
            T-dependent air-sea alphas make the ocean signature rotate",
         "
            seasonally, so it is not a signed SCALAR and the inversion",
         "
            no longer runs at all."),
       bound = paste("INTERVAL MEMBERSHIP, not a sigma -- the bound's KIND",
         "
            follows its source. A first-order box lags its sinusoidal",
         "
            forcing by arctan(omega*tau), bounded above by a QUARTER",
         "
            CYCLE, so the admissible arc is [7.41, 10.41].",
         "
            \u26a0 WIDER THAN THE RETIRED BOUND AND HONESTLY SO: 3.00",
         "
            months vs 1.41, i.e. 25 % of the circle, p(random pass)",
         "
            = 0.25. \u2b50 Its POWER was measured before adoption and it",
         "
            EXCLUDES the pre-fix limb (4.16 and 3.35), the defect this",
         "
            gate exists to catch; test-gate-bounds.R fails if that is",
         "
            ever lost. \u26a0 The limb AMPLITUDE is now printed BARE:",
         "
            pCO2 is not flux, so this route supplies no amplitude",
         "
            comparator, and the retired one is provenance."),
       scored = paste("NO, in the sense that matters. co2_seasonal_SPO IS a",
         "
            fitted stream -- but it scores the TOTAL, which the model",
         "
            matches to ~2 % while nothing scores the PARTITION beneath",
         "
            it. \u26a0 The '2.55x land / 0.45x ocean' this line used to",
         "
            quote was measured at a PRE-ent26 mode AND on an ORIGIN",
         "
            split, not the land/ocean one; like-for-like at ent26 the",
         "
            limbs are 1.05x and 0.77x. Retracted 2026-09-04h."),
       power  = paste("REAL, and it is the gate the seasonal arc was missing:",
         "
            a 5.17-month limb error survived weeks of fitting because",
         "
            the matched total has no power over the partition beneath",
         "
            it. \u26a0 The observed ocean phase rests on a pCO2 product,",
         "
            which omits the seasonality of gas transfer and K0.",
         "
            \u2b50 THE KNOCKOUT HAS THREE LIMBS since 2026-09-12: the SST",
         "
            sine, the entrainment shim, and the seasonal mixed layer",
         "
            itself (`seas_ml` 0 in SL_CASES$SH_ocean). Two limbs alone at",
         "
            hilda31s read 0.410 ppm @ 4.53 mo -- OUTSIDE the arc -- for a",
         "
            whole limb of 0.465 @ 8.96. \u26a0 `seas_ml` is a WHOLE-MODEL",
         "
            switch, so the knockout also removes the NH mixed layer's leak",
         "
            into SPO (0.107 ppm @ 6.43; hemisphere-clean the limb is 0.451",
         "
            @ 9.41): a per-hemisphere MLD handle is OWED, and until it",
         "
            exists the three-limb decomposition is not complete at",
         "
            seas_ml = 1.")),
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
       power  = "REAL, and 12b carries its OWN in-run mutation test."),
  list(id = "L", what = "LAND share of a 100 GtC pulse at 1000 yr (T-L, 2026-09-08g) -- ⛔ A COMPARISON, NOT A GATE (Marcus 2026-09-08h)",
       class = "MODEL ENSEMBLE -- and that is why it is not a gate: 'do not use Joos as a scoring mechanism; the long lifetime is meant to be an EMERGENT property, not something we fit to'. dg_gateL_verdict() ERRORS; dg_compareL() reports the z's.",
       src = "Joos et al. 2013 ACP 13:2793, abstract: at 1000 yr land 16 +/- 14 %, ocean 59 +/- 12 %, air 25 +/- 9 %",
       bound = paste("|z_land| <= DG_L_NSD (1) against the MULTI-MODEL SPREAD, two-sided:",
         "
            the band is [2, 30] %. 1 sd, not 2, because the sd is a spread of",
         "
            models, not a measurement's sampling error -- a CHOICE, stated."),
       scored = "NO -- no stream sees a pulse; the land sink rows see 2015-2023 only",
       power  = paste("REAL in both directions: the canonical's land share at 100 yr",
         "
            (0.41, option H) is 2.5x the ensemble's 1000-yr share; a land-off",
         "
            arm (beta_max 0) must fail the LOWER edge. Kernel mutation-tested.")),
  list(id = "GL", what = "interhemispheric d13C gradient LEVEL (T-G, 2026-09-08g), beside H",
       class = "OBSERVATION", src = "MLO minus SPO annual d13C, 1980-2023, ccx_prepare_obs()",
       bound = paste("|z| <= DG_GL_NSD (= DG_H_NSD, 2) on the RAW model gradient,",
         "
            NEVER the fitted grad_off_d13c. ⭐ RULING 3 (2026-09-09): the",
         "
            se is the AUGMENTED one -- the observed mean's own sampling",
         "
            error se = sd/sqrt(n_eff) (dg_gateH_obs) with the CO2 control's",
         "
            measured representation allowance |1 - R_co2| x |obs| added in",
         "
            QUADRATURE, DERIVED from the same (g, ho) and never typed. The",
         "
            bare-se z (the bound until 09-09) is REPORTED as z_bare. ⚠ The",
         "
            canonical moves z -13 -> z -9 (on the residual se of 09-12:",
         "
            bare -21.6 -> -10.1) and still FAILS: an allowance that",
         "
            could not change the verdict is the honest kind."),
       scored = "PARTLY: d13c_gradient scores the SHAPE through a fitted offset, so the LEVEL is unscored",
       power  = paste("REAL: the offset absorbs a 1.97x gradient invisibly (z +0.43 on the",
         "
            offset's prior); this gate gives that a threshold. Mutation-tested",
         "
            both ways on the kernel.")),
  list(id = "P7", what = "a SURFACE mechanism must not be a VERTICAL-GRADIENT lever (round-6 prereg P7, promoted 2026-09-11)",
       class = "OBSERVATION-DERIVED sigma, ORDERING on the model's own move",
       src = "the ocean_grad_d13c row's sigma_eff (GLODAP gradient target, option-5 inflation), ccx_ocean_grad_scored()",
       bound = paste("|d13C gradient(mechanism ON) - d13C gradient(OFF)| <= sd_eff at the OFF arm;",
         "
            both gradients MODERN and like-for-like (same vector, same spinup, the",
         "
            objective's own scorer). The DIC gradient's move is REPORTED beside it",
         "
            in the same units (its own sd_eff) and not gated -- one bound, one claim."),
       scored = "YES (the rows are in the objective) -- which is why a refit can BUY prior relief by moving them; this gate asks the move by name",
       power  = paste("REAL, and it decided a round TWICE. 09-11 (2): the seas_ml = 1 refit",
         "
            read as moving the gradient +0.327 against sd_eff 0.163 and was",
         "
            'REFUTED' -- ⛔ RETRACTED: that read was an OBSERVABLE ARTEFACT, a",
         "
            seasonal box read over its annual-mean mass rather than its mass",
         "
            at the time ([[seasonal_box_observable_artefact]]). 09-11 (7),",
         "
            round 6b, like-for-like: hilda31s PASSES at -0.028 (-0.029 after",
         "
            the 09-12 restamp; OFF -0.301 -> ON -0.330) vs bound 0.163,",
         "
            target -0.861, while the artefact-fitted 09-10 mode still FAILS",
         "
            it -- that is the gate's POWER. DIC 300 -> 306 (target 233),",
         "
            reported. Any future re-test of seas_ml passes this gate or does",
         "
            not ship. Mutation-tested on the kernel."))
)

#' GATE P7 -- the verdict kernel. `g_off` / `g_on` are the scored gradient lists
#' from ccx_ocean_grad_scored() at the mechanism-OFF and mechanism-ON arms of the
#' SAME vector (or the two modes of a before/after refit, stated as such).
#' The bound is the OFF arm's own sd_eff for d13c -- an observation-derived
#' sigma, never a typed number. DIC is reported in its own sd_eff, not gated.
dg_gateP7_verdict <- function(g_off, g_on) {
  sd13 <- g_off$sd_eff[["d13c"]]; sddic <- g_off$sd_eff[["dic"]]
  d13 <- g_on$d13c - g_off$d13c; ddic <- g_on$dic - g_off$dic
  list(d13c_off = g_off$d13c, d13c_on = g_on$d13c, move_d13c = d13, sd_eff_d13c = sd13,
       ratio_d13c = abs(d13) / sd13,
       dic_off = g_off$dic, dic_on = g_on$dic, move_dic = ddic, sd_eff_dic = sddic,
       ratio_dic = abs(ddic) / sddic,
       pass = is.finite(d13) && is.finite(sd13) && sd13 > 0 && abs(d13) <= sd13)
}

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
  cat(sprintf("    DG_G7_NSD %g, DG_Q_NSD %g, DG_GD_NSD %g.  GATE S no longer has one.\n",
              DG_G7_NSD, DG_Q_NSD, DG_GD_NSD))
  cat(sprintf("  GATE S is now an INTERVAL, not a sigma: [%.3f, %.3f], width %.2f mo,\n",
              DG_S_LO, DG_S_HI, DG_S_LAG_MAX))
  cat(sprintf("    = SO_DPCO2_PEAK_MO %.4f + a quarter-cycle lag bound. The retired\n",
              DG_S_PCO2_MO))
  cat(sprintf("    inversion target was %.2f; it is kept by name for matched comparison only.\n",
              DG_S_OBS_RETIRED))
  cat("  ⭐ GATE S IS NOW PART LAW-DERIVED -- its CONVERSION is a quarter-cycle\n")
  cat("    bound, not a fitted or chosen sigma. GATE G remains OBSERVATIONAL.\n")
  cat("    Still unbuilt, and still worth building: carbonate / Revelle\n")
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
                spinup = ccx_spinup, spinup_label = "aseasonal",
                src = "uncalibrated defaults", migrated = character(0), md = NULL))
  f  <- ccx_mode_file(arm)
  md <- readRDS(f)
  # THE BASE IS THE FILE'S OWN STRUCTURE (2026-09-08f), not the column default.
  p  <- ccx_mode_base(md)
  # ⚠ MIGRATE, THEN SAY SO. `ccx_migrate_par_set()` reads the model's own
  # absence contract (`ccx_seas_lag_p()`); it never hand-fills, and it ERRORS on
  # a name no stored field can supply. A migrated vector is a legitimate thing
  # to MEASURE a gate at -- it is not a mode of this build's space, and every
  # caller must print `$migrated` so the reader knows which it is looking at.
  # ⚠ A PINNED name is HELD, not absent (2026-09-13): fill it from the file's
  # own `pins` BEFORE the migration looks, or a pinned canonical prints
  # "MIGRATED 30->31" on every scorecard line. ccx_mode_base(md) already carries
  # the same value in `p`; `pm` here carries it too, so the two lists agree.
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
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
  # ⭐ THE SPINUP IS THE FILE'S OWN (2026-09-12). A mode promoted since 09-09x
  # was fitted under the PERIODIC spinup, and its `streams` reproduce only under
  # it: at `hilda31s` (seas_ml 1) the aseasonal ccx_spinup() puts the vector
  # 2447 log-units off its own mode (-3889.6 vs the stored -1442.4) -- the
  # 09-09t leak's exact mechanism, a seasonal mixed layer started from an
  # aseasonal equilibrium. Every gate that spins up takes dg_spinup(v) below, so
  # an arm is always measured where it was fitted ([[like_for_like_forcing]]);
  # an absent field means the aseasonal spinup, as ccx_mode_spinup() says.
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
       grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = ccx_spinup_from_label(ccx_mode_spinup(md)),
       spinup_label = ccx_mode_spinup(md),
       md = md, migrated = mig, pins = ccx_mode_pins(md),
       src = sprintf("%s (logpost %.2f%s%s)", basename(dirname(f)), md$logpost,
                     # a PINNED arm's stored logpost carries no prior/Jacobian for
                     # the held name: comparable on LIKELIHOOD only ([[ccx_pinned_arms]])
                     if (length(md$pins)) sprintf(", PINNED %s -- logpost not comparable to a free arm",
                                                  paste(sprintf("%s=%g", names(md$pins), md$pins), collapse = ",")) else "",
                     if (length(mig)) sprintf(", MIGRATED %d->%d",
                                              length(md$param_names),
                                              length(CCX_PARAM_NAMES)) else ""))
}

#' The spinup an arm was FITTED under, applied to its own parameter list. A
#' vector built by hand (no `spinup` field) gets the aseasonal ccx_spinup(),
#' which is what every such vector meant before 09-09x.
dg_spinup <- function(v) {
  fn <- if (is.null(v$spinup)) ccx_spinup else v$spinup
  fn(v$p)
}

dg_run <- function(v) {
  sp <- dg_spinup(v)
  # the final DG_YEARS year is forcing-held BY DESIGN (see DG_SINK_LAST); the
  # builder's "held FLAT" warning is muffled here and nowhere else.
  F  <- withCallingHandlers(
    ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                      bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale),
    warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
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
# ⭐ RULED 2026-09-12 (Marcus): the statistic is the CALENDAR-YEAR MEAN over
# the model's own 12 monthly rows of DG_Q_YEAR, and the two boxes are combined
# with their AREA weights. Until then it read ONE instant (t = 1995.000, i.e.
# December 1994) and the verdict moved with the month: at hilda31s n_sd ranged
# 2.18-3.62 over the year (instant 2.63), and at ent26 it crossed the PASS
# line (0.85-2.29) -- the surface d13C cycle is 0.17 permil p2p against a
# sigma of 0.10. The hemispheric pair is returned so a caller can see the
# spread. Quay's estimate is a global one, so the boxes are weighted by the
# area each represents (ccx_column_area).
#
# ⭐ RE-WEIGHTED 2026-09-21 (f) (handoff (d) s3's "gate Q's weighting", Marcus:
# "do the housekeeping in s6.4"). Quay's global mean is EXCHANGE-weighted (k x
# area per region), and the GLODAP bottles reproduce his 0.60 only under that
# weighting (0.545 k-weighted vs 0.846 area-weighted, data/obs_hemi_diseq.rds).
# The 09-12 statistic -- two warm ML boxes, area-weighted, NO cold box -- was
# compared to it like-for-unlike, which is why the 09-20 v loop could move every
# regional level TOWARD the bottles while gate Q WORSENED (n_sd 2.75 -> 4.37).
# The gate now scores gate D's four regional D's for DG_Q_YEAR under the bottles'
# own band k-weights per box (dg_gateQ_k_weights); the cold boxes are 16 % of the
# area and 37 % of the exchange. The old read is returned as mean_area_ml.
DG_Q_YEAR <- ccx_const("AIRSEA_D13C_DISEQ_YEAR")
DG_Q_OBS  <- ccx_const("AIRSEA_D13C_DISEQ_OBS")
DG_Q_SD   <- ccx_const("AIRSEA_D13C_DISEQ_SD")
DG_Q_NSD  <- 2      # how many observational sigma the gate allows. A DISTRIBUTIONAL
                    # claim against a stated +- , so it is scaled to that sigma and
                    # to nothing else. [[gate_bound_matches_its_claim]]

dg_gateQ <- function(r, v, do = dg_gateD_obs()) {
  o <- r$out; aux <- r$sp$aux
  # the 12 month-centre rows of calendar year DG_Q_YEAR, on the model's own grid
  tt <- ccx_epoch_year_samples(DG_Q_YEAR + 0.5)
  j  <- vapply(tt, function(t1) which.min(abs(o$t - t1)), integer(1))
  if (max(abs(o$t[j] - tt)) > 1e-6)
    stop("GATE Q: the run has no monthly rows over calendar year ", DG_Q_YEAR, ".")
  d <- vapply(HEMIS, function(h) {
    # surface DIC d13C, from the state, month by month
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
    mean((d_ml - eps_dicg) - o[[paste0("d13c_", h)]][j])
  }, 0)
  w <- vapply(HEMIS, function(h) ccx_column_area(aux, h), 0); w <- w / sum(w)
  m_area_ml <- sum(w * d)
  # ⭐ RE-WEIGHTED 2026-09-21 (f): Quay's 0.60 is a GAS-EXCHANGE-WEIGHTED global mean
  # (his eq. for the global disequilibrium weights each region by k x area), and the
  # GLODAP bottles reproduce it ONLY under that weighting (0.545 k-weighted vs 0.846
  # area-weighted, data/obs_hemi_diseq.rds $global). The statistic above -- the two
  # warm ML boxes, area-weighted, no cold box -- was compared to it like-for-unlike,
  # which is why every regional level could IMPROVE while gate Q WORSENED (09-20 v,
  # CHANGELOG). The gate now takes gate D's four regional D's (the ML region = ml + eq
  # + tr area-weighted within the hemisphere; the HS box) for DG_Q_YEAR and weights
  # them by the bottles' own NCEP-wind^2 band weights summed over each box's latitude
  # range (the cold boxes are 16 % of the area but 37 % of the exchange). The old
  # ML-only area read is RETURNED beside it (mean_area_ml), never scored. The
  # area-weighted all-box mean is compared to the bottles' area global as a second read.
  bx <- dg_gateD_box_years(r, v)
  reg <- list(); for (h in HEMIS) {
    ml_boxes <- bx[vapply(bx, function(x) x$hemi == h && x$box != "hs", TRUE)]
    Dy <- function(x) { k <- match(DG_Q_YEAR, x$years); if (is.na(k)) stop("GATE Q: no ", DG_Q_YEAR, " row for ", h); x$D[k] }
    a_ml <- sum(vapply(ml_boxes, `[[`, 0, "area"))
    reg[[paste0(h, "_ml")]] <- sum(vapply(ml_boxes, function(x) x$area * Dy(x), 0)) / a_ml
    hs_box <- bx[[paste(h, "hs", sep = "_")]]
    reg[[paste0(h, "_hs")]] <- if (is.null(hs_box)) NA_real_ else Dy(hs_box)
  }
  kw <- dg_gateQ_k_weights(do)
  have <- vapply(names(reg), function(k) is.finite(reg[[k]]), TRUE)
  if (!all(have)) {   # no cold box (hs_frac 0): its k-weight goes to the hemisphere's ML region, which then covers the band
    for (h in HEMIS) if (!have[[paste0(h, "_hs")]]) { kw[[paste0(h, "_ml")]] <- kw[[paste0(h, "_ml")]] + kw[[paste0(h, "_hs")]]; kw[[paste0(h, "_hs")]] <- 0; reg[[paste0(h, "_hs")]] <- 0 }
  }
  wk <- unlist(kw[names(reg)]); wk <- wk / sum(wk); m_k <- sum(wk * unlist(reg))
  wa <- unlist(dg_gateQ_area_weights(do, have)[names(reg)]); wa <- wa / sum(wa); m_area_all <- sum(wa * unlist(reg))
  n_sd <- abs(m_k - DG_Q_OBS) / DG_Q_SD
  list(year = DG_Q_YEAR, months = o$t[j], by_hemi = d, w = w,
       mean = m_k, w_k = wk, region = unlist(reg),               # THE GATE: k-weighted over the four surface boxes vs Quay
       mean_area_ml = m_area_ml,                                  # the pre-09-21 f statistic, for continuity (never scored)
       mean_area_all = m_area_all, obs_area_all = do$global_area, # the second read: area-weighted vs the bottles' area global
       obs_k_bottles = do$global_k,                               # the bottles under the gate's weighting (reproduces Quay)
       mean_unweighted = mean(d), obs = DG_Q_OBS,
       sd = DG_Q_SD, n_sd = n_sd, pass = n_sd <= DG_Q_NSD)
}

#' The bottles' NCEP-wind^2 k-weights per model surface box (2026-09-21 f): the band
#' weights of data/obs_hemi_diseq.rds summed over each box's latitude range --
#' |lat| < lat_hi is the hemisphere's ML region, >= lat_hi its cold box. READ from
#' the file, never typed; the area column gives the like-for-like area weights.
dg_gateQ_k_weights <- function(do = dg_gateD_obs(), col = "k") {
  bw <- do$band_weights; lat <- as.numeric(rownames(bw))
  out <- list()
  for (h in HEMIS) { s <- if (h == "NH") lat > 0 else lat < 0
    out[[paste0(h, "_ml")]] <- sum(bw[s & abs(lat) <  do$lat_hi, col])
    out[[paste0(h, "_hs")]] <- sum(bw[s & abs(lat) >= do$lat_hi, col]) }
  out
}
dg_gateQ_area_weights <- function(do = dg_gateD_obs(), have = NULL) {
  aw <- dg_gateQ_k_weights(do, col = "area")
  if (!is.null(have)) for (h in HEMIS) if (!isTRUE(have[[paste0(h, "_hs")]])) { aw[[paste0(h, "_ml")]] <- aw[[paste0(h, "_ml")]] + aw[[paste0(h, "_hs")]]; aw[[paste0(h, "_hs")]] <- 0 }
  aw
}

# ---- GATE D: the HEMISPHERIC air-sea d13C disequilibrium (2026-09-20 t) ----
# WHY IT EXISTS. The MLO-SPO d13C gradient miss is a CONSTANT -0.0668 permil
# offset, not a ratio ([[ccx_d13c_gradient_offset_additive]]): the real NH
# atmosphere is heavier than the SH by that much independent of fossil fuel,
# which needs a persistent NH-minus-SH ISOFLUX the model lacks. The ocean's
# air-sea disequilibrium D (Quay 2003's definition: the d13C of air in
# equilibrium with the surface water, minus the air) has a strong meridional
# structure -- positive in the subtropics, NEGATIVE poleward of ~55 deg -- and
# gate Q scores only its GLOBAL mean, so the model can (and does) sit at the
# right global level with the hemispheres wrong. This gate scores the
# HEMISPHERIC ASYMMETRY D_NH - D_SH, the quantity that drives the gradient.
#
# THE OBSERVATION is data/obs_hemi_diseq.rds, built by
# data-raw/build_hemi_diseq_targets.R from GLODAPv2.2023 surface bottles on
# Quay's definition (Zhang 1995 eps as the model carries it; the Scripps
# station of the bottle's hemisphere in the bottle's year), band means
# weighted by the ERSST ocean-area mask, cluster-bootstrap se. Its global
# area x k mean reproduces Quay's 0.60 (0.545), which is what licenses it.
# ⛔ NEVER TYPED HERE: every number comes from the artifact.
#
# THE CLAIM IS THE ASYMMETRY, AND ONLY THE ASYMMETRY, AREA-WEIGHTED -- the
# like-for-like statistic against a model whose surface boxes ARE areas
# (the ML column = |lat| < 55, the HS box = poleward; the eq/tr cells sit
# inside the ML region). The four regional LEVELS are REPORTED beside it with
# their own z and are NOT bounded: the global level is gate Q's claim, and a
# one-box column's regional level carries representation error this gate
# does not price. The k-weighted (isoflux) asymmetry is reported too, because
# it is what the gradient actually feels; not gated, since the model's own
# exchange weighting is its box areas x one k_w.
#
# LIKE-FOR-LIKE IN TIME: D drifts with the Suess rate, so the model's D is
# averaged over the SAME YEARS the bottles sample, with the bottle-year
# weights the artifact carries per region; each calendar year is the mean of
# its 12 monthly rows (as gate Q, ruled 09-12).
# BOUND: |z| <= DG_D_NSD on the observation's own bootstrap se of the
# asymmetry. The model side is deterministic and contributes no error term.
DG_D_NSD <- 2                  # harmonised with DG_Q_NSD across the family
DG_D_OBS_FILE <- ccx_path("data", "obs_hemi_diseq.rds")

dg_gateD_obs <- function(file = DG_D_OBS_FILE) {
  if (!file.exists(file))
    stop("GATE D: ", file, " is absent; run data-raw/build_hemi_diseq_targets.R")
  o <- readRDS(file)
  tg <- o$targets
  list(hemi = list(NH = tg$NH_all_area, SH = tg$SH_all_area),
       region = list(NH_ml = tg$NH_ml_area, NH_hs = tg$NH_hs_area,
                     SH_ml = tg$SH_ml_area, SH_hs = tg$SH_hs_area),
       hemi_k = list(NH = tg$NH_all_k, SH = tg$SH_all_k),
       asym = o$asym$area, asym_se = o$asym$se_area,
       asym_k = o$asym$k, asym_k_se = o$asym$se_k,
       global_area = o$global$area, global_k = o$global$k,     # the bottles' GLOBAL mean under each weighting (gate Q reads both, 2026-09-21 f)
       band_weights = o$band_weights,                           # 5-deg bands x {area, k}: the k column is NCEP wind^2 x area
       lat_hi = o$consts$lat_hi, built = o$provenance$built, file = file)
}

#' The model's D per surface box per calendar year (12-row means), Quay's definition
dg_gateD_box_years <- function(r, v) {
  o <- r$out; aux <- r$sp$aux
  eps <- function(sst) ccx_const("ALPHA_AS_ZHANG_A") * sst * ccx_const("ALPHA_AS_FCO3") +
                       ccx_const("ALPHA_AS_ZHANG_B") * sst + ccx_const("ALPHA_AS_ZHANG_C")
  yr <- floor(o$t + 1e-9); full <- names(which(table(yr) == 12L)); years <- as.integer(full)
  boxes <- c(ml = "asx", hs = "asx_hs", eq = "asx_eq", tr = "asx_tr")
  res <- list()
  for (h in HEMIS) for (b in names(boxes)) {
    ax <- aux[[boxes[[b]]]]; if (is.null(ax) || is.null(ax[[h]]) || !isTRUE(ax[[h]] > 0)) next
    cC <- o[[paste0(b, "_C_", h)]]; c13 <- o[[paste0(b, "_C13_", h)]]; if (is.null(cC)) next
    sst_b <- if (b == "ml") aux$sst[[h]] else { x <- aux[[paste0("sst_", b)]]; if (is.list(x)) x[[h]] else x }
    d_box <- 1000 * (c13 / (cC * ccx_const("R13_VPDB")) - 1)
    D <- d_box - eps(sst_b) - o[[paste0("d13c_", h)]]
    res[[paste(h, b, sep = "_")]] <- list(hemi = h, box = b, years = years,
      D = vapply(years, function(y) mean(D[yr == y]), 0),
      # the box's AREA share of its hemisphere's ocean (the ML region = ml + eq + tr)
      area = if (b == "hs") aux$a_hs[[h]] else if (b == "ml") ccx_ml_area(aux, h)
             else if (b == "eq") aux$a_eq[[h]] else aux$a_tr[[h]])
  }
  res
}

#' GATE D's model side: the two regional D's per hemisphere and the area-weighted
#' hemispheric D, each averaged over the OBSERVATION's bottle years with its weights
dg_gateD <- function(r, v, do = dg_gateD_obs()) {
  bx <- dg_gateD_box_years(r, v)
  wmean_years <- function(D, years, tg) {
    w <- tg$year_weights[match(years, tg$years)]; ok <- is.finite(w) & w > 0
    if (!any(ok)) stop("GATE D: the run has none of the observation's years.")
    sum(D[ok] * w[ok]) / sum(w[ok])
  }
  region <- list(); hemi <- list()
  for (h in HEMIS) {
    ml_boxes <- bx[vapply(bx, function(x) x$hemi == h && x$box != "hs", TRUE)]
    hs_box   <- bx[[paste(h, "hs", sep = "_")]]
    tg_ml <- do$region[[paste0(h, "_ml")]]; tg_hs <- do$region[[paste0(h, "_hs")]]
    a_ml <- sum(vapply(ml_boxes, `[[`, 0, "area"))
    D_ml <- sum(vapply(ml_boxes, function(x) x$area * wmean_years(x$D, x$years, tg_ml), 0)) / a_ml
    D_hs <- if (is.null(hs_box)) NA_real_ else wmean_years(hs_box$D, hs_box$years, tg_hs)
    a_hs <- if (is.null(hs_box)) 0 else hs_box$area
    region[[paste0(h, "_ml")]] <- D_ml; region[[paste0(h, "_hs")]] <- D_hs
    hemi[[h]] <- if (a_hs > 0) (a_ml * D_ml + a_hs * D_hs) / (a_ml + a_hs) else D_ml
  }
  list(region = region, hemi = hemi, asym = hemi$NH - hemi$SH, lat_hi = do$lat_hi)
}

dg_gateD_verdict <- function(g, do = dg_gateD_obs(), n_sd = DG_D_NSD) {
  z <- (g$asym - do$asym) / do$asym_se
  zr <- vapply(names(g$region), function(k) if (is.finite(g$region[[k]])) (g$region[[k]] - do$region[[k]]$mean) / do$region[[k]]$se else NA_real_, 0)
  zh <- vapply(HEMIS, function(h) (g$hemi[[h]] - do$hemi[[h]]$mean) / do$hemi[[h]]$se, 0)
  list(asym = g$asym, obs_asym = do$asym, se = do$asym_se, z = z, n_sd = n_sd,
       pass = is.finite(z) && abs(z) <= n_sd,
       # REPORTED BESIDE IT, not bounded: the levels
       hemi = unlist(g$hemi), obs_hemi = vapply(HEMIS, function(h) do$hemi[[h]]$mean, 0), z_hemi = zh,
       region = unlist(g$region), obs_region = vapply(names(g$region), function(k) do$region[[k]]$mean, 0), z_region = zr,
       obs_asym_k = do$asym_k, obs_asym_k_se = do$asym_k_se)
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
  yrs <- sort(unique(floor(o$t + 1e-9))); yrs <- yrs[yrs <= DG_SINK_LAST]; bnd <- c(yrs, max(yrs) + 1L)
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
#' The NH double-peak shape: peak 1, the trough, peak 2, and the DROP between.
#'
#' ⭐ PROMOTED from diag_gate5_bimodal.R 2026-09-09 under ruling 1. It was that
#' diagnostic's local `feat()`; the moment the gate scores the same quantity, a
#' second copy is the caption-sync bug class this file exists to prevent, so the
#' diagnostic now calls THIS. Plain windowed extrema, NOT `dg_peak()`'s parabolic
#' refinement: the refinement is for a peak TIME, and what the gate reads here is
#' a DEPTH, whose sub-sample interpolation would be a different estimator on the
#' model and the observation (the two are on different time grids).
#' @return named numeric: p1_t, p1_v, tr_t, tr_v, p2_t, p2_v, drop, p2_minus_p1
dg_nh_shape <- function(t, v) {
  w <- function(win, f) {
    k <- t >= win[1] & t <= win[2]
    if (!any(k)) return(c(t = NA_real_, v = NA_real_))
    i <- which(k)[f(v[k])]
    c(t = t[i], v = v[i])
  }
  p1 <- w(DG_G5_W1, which.max)
  tr <- w(DG_G5_WT, which.min)
  p2 <- w(DG_G5_W2, which.max)
  c(p1_t = p1[["t"]], p1_v = p1[["v"]], tr_t = tr[["t"]], tr_v = tr[["v"]],
    p2_t = p2[["t"]], p2_v = p2[["v"]],
    drop = p1[["v"]] - tr[["v"]], p2_minus_p1 = p2[["v"]] - p1[["v"]])
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
  # RULING 1: the NH shape rides ALONG the NH peak entry, so every caller that
  # already indexes pk$NH[["t"]] keeps working and nothing needs a second lookup.
  pk$NH <- c(pk$NH, dg_nh_shape(o$t, o$d14c_NH))
  # ⭐ RULED 2026-09-12 (Marcus): the LAG is SH peak minus the NH FIRST-PEAK time,
  # not minus the NH argmax -- the argmax picks whichever lump is higher (the
  # 1964 one in the model, the 1963 one in the observation), so the lag's z
  # flipped sign with the lump (-0.95 argmax / +1.7 first peak on 09-12).
  list(pk = pk, lag = pk$SH[["t"]] - pk$NH[["p1_t"]])
}
#' The observed hemispheric bomb peaks, under the SAME estimator as the model
dg_obs_gate5 <- function() {
  ob <- lapply(dg_obs_bomb, function(x) {
    p <- dg_peak(x$t, x$v); c(p, efold = dg_efold(x$t, x$v, p[["t"]]))
  })
  ob$NH <- c(ob$NH, dg_nh_shape(dg_obs_bomb$NH$t, dg_obs_bomb$NH$v))
  ob
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
  # years through DG_SINK_LAST only: a DG_YEARS run carries one forcing-held year
  # past it so that the final boundary is interior (2026-09-12); a shorter run
  # still gets its last year by the linear end extrapolation below.
  yrs <- sort(unique(floor(o$t + 1e-9))); yrs <- yrs[yrs <= DG_SINK_LAST]; bnd <- c(yrs, max(yrs) + 1L)
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

# =====================================================================
# ⛔⛔ GATE 4 IS RETIRED (2026-09-04, Marcus). IT IS NOW A PRINTED COMPARISON.
#
# `dg_gate4()` still computes the airborne fraction and callers still print it --
# the LEVEL is a useful sanity number (0.4246 model vs 0.4313 GCB). What is gone
# is the VERDICT, and the reason is not that the source was wrong. The AF is a
# GCB observation. The reason is that the gate carried no information the
# objective did not already have, and reported it through a statistic that cannot
# be read [[ccx_gate4_no_power]]:
#
#   * ITS NUMERATOR IS A SCORED STREAM AND ITS DENOMINATOR IS A MODEL INPUT.
#     AF = model atmospheric growth / model emissions. Emissions are prescribed;
#     growth is what `co2_level_MLO/SPO` scores. Measured, the one signal gate 4
#     had -- the 2020s -- appears in `co2_level_MLO` at MLO 2020-24 mean z -0.96,
#     max |z| 1.63, the largest decadal excursion in that stream's record. Same
#     sign, same size, already in the objective.
#   * 70 % OF ITS TARGET'S VARIANCE WAS SAMPLING NOISE. Observed decadal spread
#     0.0483 against a per-decade noise floor of 0.0404 (analytic, MC-validated).
#   * AND sd() OVER SEVEN DECADES CANNOT TELL A DRIFT FROM A WIGGLE, so the gate
#     ranked the UNCALIBRATED DEFAULTS above the adopted mode; detrended, the two
#     arms are identical (0.617 vs 0.613).
#
# ⇒ REPLACED BY GATE V BELOW, which tests the second-order observation gate 4 was
# reaching for -- the interannual variability itself -- where it IS resolved.
DG_G4_RETIRED <- paste(
  "GATE 4 (airborne fraction) was RETIRED 2026-09-04: its numerator is a scored",
  "stream and its denominator a model input, so it restated `co2_level`; 70 % of",
  "its target was sampling noise; and its sd() conflated a trend with a wiggle.",
  "The AF is still PRINTED. The variability claim it was reaching for is GATE V.")
dg_gate4_verdict <- function(g4) stop(DG_G4_RETIRED, call. = FALSE)

# =====================================================================
# ⭐ GATE V: THE INTERANNUAL CO2 GROWTH VARIABILITY (2026-09-04, Marcus)
#
# WHAT IT IS. The model must reproduce the OBSERVED year-to-year variability of
# atmospheric CO2 growth, not merely its trend. That is a second-order
# observation, it is resolved (66 annual values, not 7 decadal ones), and NOTHING
# in the objective asks for it: `co2_level_*` scores LEVELS at a deliberately soft
# 1.0 ppm, which the year-to-year anomaly barely moves. The variability gap has
# been a recorded finding with no test since 2026-08-29 [[ccx_variability_gap]];
# this is that finding turned into a gate.
#
# THE ESTIMATOR, APPLIED IDENTICALLY TO MODEL AND OBSERVATION. Regress annual
# atmospheric growth on emissions with a smoothly time-varying airborne fraction,
#     grow_y = AF(y) * emis_y + eps_y,   AF(y) a natural spline of DG_V_DF dof,
# and take sd(eps). The smooth part is the decadal signal; `eps` is the
# interannual anomaly in GtC/yr. ⚠ DG_V_DF IS A SMOOTHING CHOICE, so the
# diagnostic WALKS it: obs 0.907-0.933 and the arms 0.627-0.698 across df 2-5,
# i.e. the verdict does not turn on it.
#
# THE BOUND IS DERIVED FROM THE OBSERVATION ITSELF, not chosen. The sampling
# error of a residual sd on nu degrees of freedom is sd / sqrt(2 nu), and nu is
# the RESIDUAL dof of the AF(t) regression, n - (DG_V_DF + 1) = 62 -- see
# dg_v_sd() -- giving 0.084 GtC/yr here. ⚠ Until 2026-09-12 (review A7) both
# the sd and the se used n - 1 = 65 (0.080), which understates a residual sd by
# sqrt(65/62) and its se by 65/62; the matched Monte Carlo that returned 0.080
# was matched to THAT form (white draws, no regression). So the gate is a
# DISTRIBUTIONAL claim at the observation's own sigma, |z| <= DG_V_NSD, two-sided:
# too MUCH interannual variance is as wrong as too little.
# ⚠ The observed anomaly is white (lag-1 rho +0.014), which is what makes
# sqrt(2(n-1)) the right denominator; the MODEL's is not (rho +0.19 to +0.26), and
# that inflates the model's own sampling error rather than the bound's. Stated
# because it means a model arm sitting just inside the bound is not thereby safe.
#
# WHAT SHOULD DRIVE IT, IN THE MODEL (Marcus 2026-09-04): observed TEMPERATURE
# variability, VOLCANIC AEROSOL (the AOD -> diffuse-light -> NPP path), and the
# direct ENSO links to land and ocean uptake. All three are already wired, so the
# gate is a claim about their COMBINED amplitude, and
# `diag_gateV_variability_drivers.R` decomposes it by knockout.
# ⚠⚠ STATUS (Marcus 2026-09-04, the same day it was created): A GATE V FAILURE IS
# NOT A BLOCKER. "I wouldn't expect to be able to capture all of the interannual
# variability with just ENSO, volcanoes, and temperature ... interannual
# variability is not a dealbreaker." The gate is here because it MEASURES a real
# observation the objective never asks for, and because its knockouts say WHERE
# the model's variability comes from -- not because the model must pass it.
# ⇒ Report it; do not chase it, and do not read a FAIL here as a defect that
# blocks a headline claim. The two candidate mechanisms for closing it were
# scoped and BOTH DECLINED: `diag_aerosol_solar_diffuse_scope.R`.
DG_V_WIN <- DG_AF_WIN     # 1959-2024: where GCB's annual budget exists
DG_V_DF  <- 3             # dof of the smooth AF(t) the anomaly is taken about
DG_V_NSD <- 2             # harmonised with DG_Q_NSD / DG_G5_NSD / DG_G7_NSD / DG_GD_NSD
                          # (GATE S left the family 2026-09-04h: its bound is an
                          #  INTERVAL from a law, so it has no sigma to harmonise.)
DG_V_CLAIM <- paste("|sd(model interannual growth anomaly) - sd(observed)| <=",
                    "DG_V_NSD x the OBSERVED sd's own sampling error")

#' The interannual growth anomaly of an annual series, in GtC/yr.
dg_v_anom <- function(a, df = DG_V_DF, win = DG_V_WIN) {
  k <- a$year >= win[1] & a$year <= win[2]
  yr <- a$year[k]; gr <- a$grow[k]; em <- (a$foss + a$luc)[k]
  stats::residuals(stats::lm(gr ~ 0 + em + I(em * splines::ns(yr, df = df))))
}

#' The residual sd of dg_v_anom() on its DEGREES OF FREEDOM, and that dof
#'
#' ⭐ 2026-09-12 (review A7). `dg_v_anom()` is the residual of a least-squares
#' fit with DG_V_DF + 1 coefficients (`em`, and the DG_V_DF columns of
#' `em * ns(yr)`), so E[sum(e^2)] = sigma^2 * nu with nu = n - (DG_V_DF + 1)
#' = 62 on 1959-2024 -- not the n - 1 = 65 that stats::sd() divides by. Hence
#' sigma_hat = sqrt(sum(e^2) / nu) (the lm's own `sigma`; the residual mean is
#' not removed -- there is no intercept, and mean(e) is -0.002 GtC/yr on the
#' obs) and, for Gaussian residuals, se(sigma_hat) = sigma_hat / sqrt(2 nu).
#' With n - 1 the sd was understated by sqrt(65/62) (2.4 %) and the se by
#' 65/62 (4.8 %). Applied IDENTICALLY to the model and the observation, so the
#' z's shrink by the ratio, ~2.4 % (hilda31s -2.54 -> -2.48).
dg_v_dof <- function(n, df = DG_V_DF) n - (df + 1)
dg_v_sd  <- function(e, df = DG_V_DF) sqrt(sum(e^2) / dg_v_dof(length(e), df))

dg_gateV <- function(r, df = DG_V_DF) {
  e <- dg_v_anom(dg_af_annual_model(r), df = df)
  list(sd = dg_v_sd(e, df), rho = stats::acf(e, plot = FALSE, lag.max = 1)$acf[2],
       n = length(e), dof = dg_v_dof(length(e), df), df = df)
}

dg_gateV_obs <- function(df = DG_V_DF) {
  e <- dg_v_anom(DG_AF_OBS_ANNUAL, df = df)
  n <- length(e); nu <- dg_v_dof(n, df); sd <- dg_v_sd(e, df)
  list(sd = sd, se = sd / sqrt(2 * nu), n = n, dof = nu,
       rho = stats::acf(e, plot = FALSE, lag.max = 1)$acf[2], df = df)
}

dg_gateV_verdict <- function(gv, ov) {
  z <- (gv$sd - ov$sd) / ov$se
  list(sd_model = gv$sd, sd_obs = ov$sd, se_obs = ov$se,
       ratio = gv$sd / ov$sd, z = z, pass = abs(z) <= DG_V_NSD)
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
  # `shape` is NH-only ON PURPOSE: DG_G5_W1/WT/W2 bracket the NH double peak, and
  # the SH curve has no second lump for them to bracket. Computing it there would
  # ship a number with no referent, which is how an unread field becomes a quoted
  # one.
  agg <- function(ww, shape = FALSE) {
    zz <- z[z$zone %in% names(ww), ]
    tt <- sort(unique(zz$decimal_date))
    m <- vapply(names(ww), function(nm) {
      s <- zz[zz$zone == nm, ]
      stats::approx(s$decimal_date, s$d14c, xout = tt, rule = 2)$y
    }, numeric(length(tt)))
    v <- as.vector(m %*% (ww[colnames(m)] / sum(ww)))
    p <- dg_peak(tt, v)
    c(p, efold = dg_efold(tt, v, p[["t"]]), if (shape) dg_nh_shape(tt, v))
  }
  # ⚠ EACH HEMISPHERE'S SPREAD IS TAKEN OVER ITS OWN DISTINCT DRAWS, and that
  # matters. Pooling the NH quantities over all (NH-drop x SH-drop) COMBINATIONS
  # repeats each NH value once per SH drop; the mean is unchanged but the n-1
  # denominator is not, and the sd comes out ~10 % LOW -- which would make the
  # gate stricter than the data warrants, silently. Only the LAG is a genuine
  # function of both, so only the lag is taken over the combinations.
  drop_sets <- function(ww) c(list(ww), lapply(names(ww), function(nm)
    ww[setdiff(names(ww), nm)]))
  nh <- lapply(drop_sets(w$NH), agg, shape = TRUE)
  sh <- lapply(drop_sets(w$SH), agg)
  get <- function(l, f) vapply(l, function(x) x[[f]], numeric(1))
  lag <- as.vector(outer(get(sh, "t"), get(nh, "p1_t"), `-`))   # first-peak time (09-12)
  list(sd = c(nh_t = stats::sd(get(nh, "t")), nh_v = stats::sd(get(nh, "v")),
              sh_t = stats::sd(get(sh, "t")), sh_v = stats::sd(get(sh, "v")),
              lag  = stats::sd(lag),
              nh_efold = stats::sd(get(nh, "efold")),
              # RULING 1: the trough DEPTH's tolerance comes from the SAME
              # leave-one-zone-out construction as every other gate-5 sigma --
              # observation first, and scaled to the quantity it tests.
              nh_drop = stats::sd(get(nh, "drop")),
              nh_p1_t = stats::sd(get(nh, "p1_t"))),
       n = c(nh = length(nh), sh = length(sh), lag = length(lag)),
       nh = nh, sh = sh)
}

#' Gate 5's verdict: two orderings with no threshold, and three z-scores
#' @param g5 the list from dg_gate5()
#' @param ob the list from dg_obs_gate5()
#' @param sp the list from dg_obs_gate5_spread()
dg_gate5_verdict <- function(g5, ob, sp) {
  lag_obs <- ob$SH[["t"]] - ob$NH[["p1_t"]]   # first-peak time (09-12), as dg_gate5()
  # ⭐ RULING 1 (2026-09-09): the NH z is the TROUGH DEPTH, not the argmax time.
  # `nh_t` is GONE from the judged set -- an argmax on a bimodal curve is not a
  # timing measurement, and keeping it alongside would let the gate fail on the
  # artifact the ruling exists to remove.
  z <- c(nh_drop = (g5$pk$NH[["drop"]] - ob$NH[["drop"]]) / sp$sd[["nh_drop"]],
         sh_t    = (g5$pk$SH[["t"]]    - ob$SH[["t"]])    / sp$sd[["sh_t"]],
         lag     = (g5$lag - lag_obs)                     / sp$sd[["lag"]])
  # REPORTED, NOT GATED (ruling 1's second half). The first-peak time is the
  # timing statistic that survives the bimodality; the argmax is kept beside it
  # only so a reader of an older handoff can see which lump each curve chose.
  rep <- c(nh_p1_t_model = g5$pk$NH[["p1_t"]], nh_p1_t_obs = ob$NH[["p1_t"]],
           nh_p1_t_z     = (g5$pk$NH[["p1_t"]] - ob$NH[["p1_t"]]) /
                           sp$sd[["nh_p1_t"]],
           nh_argmax_model = g5$pk$NH[["t"]], nh_argmax_obs = ob$NH[["t"]],
           nh_drop_model = g5$pk$NH[["drop"]], nh_drop_obs = ob$NH[["drop"]])
  ord <- c(sh_after_nh = g5$lag > 0,
           nh_peak_higher = g5$pk$NH[["v"]] > g5$pk$SH[["v"]])
  list(z = z, ord = ord, reported = rep,
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
#' @param r an existing dg_run(v) of the SAME v (2026-09-12, review B5). With it
#'   the SPINUP is reused (deterministic; identical to the bit, measured) and
#'   the surface reads come off the long run's own epoch-year rows, which equal
#'   the short run's exactly (diff 0.0 at all three arms, 09-12). ⚠ The short
#'   run to the epoch year is STILL made when `r` is given: `inv`, `inv_1750`
#'   and `uptake` are END-OF-RUN INSTANT states (the state matrix at t = yr + 1)
#'   and the output holds only month-centred rows, so the long run cannot
#'   supply them; an annual-mean inventory would be a DIFFERENT estimator, and
#'   this item's contract is bit-identity. What `r` saves is the spinup.
dg_gateG <- function(v, obs, r = NULL) {
  sp   <- if (is.null(r)) dg_spinup(v) else r$sp
  aux  <- sp$aux
  grid <- ccx_ocean_grid(v$p$h_ml)
  yr   <- round(obs$epoch_mean)
  F  <- ccx_build_forcing("historical", c(DG_YEARS[1], yr), prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  rs <- ccx_run_fast(sp, F); st <- rs$state
  out <- if (is.null(r)) rs$out else r$out     # the epoch year's rows are the same rows
  rho <- ccx_const("RHO_SEAWATER")
  # Over the LOW-LATITUDE column's area: the ML box spans a_ls, not a_oc, once
  # the HILDA boxes are on (2026-09-07d; read 16 percent low before).
  # ⛔ AND AS AN ANNUAL MEAN OVER THE FINAL YEAR, each box over its mass AT THE
  # TIME (2026-09-11 (4)): the Dec-31 STATE over the annual-mean mass read a
  # seasonal mixed layer ~50 % high (NH f ~ 1.5 in January). The 1750 value
  # (REPORTED only, never in the verdict) is the FIRST OUTPUT YEAR's annual
  # mean by the same reader (2026-09-12): under the periodic spinup the spinup
  # state is one PHASE of a seasonal box, and an instant read over the mean mass
  # there is the same construction the epoch read retired.
  ml <- function(y, h) y[aux$idx[[h]]$ml, "C"] * aux$mol_per_GtC /
          (ccx_column_area(aux, h) * grid$dz[1] * rho) * 1e6
  ml_ann <- function(h) ccx_box_annual_conc(out, aux, grid, "ml", yr + 0.5, hemis = h)[["dic"]]   # the EPOCH year's 12 month-centres, on the output grid (= the short run's final year)
  # AREA-WEIGHTED, because the observation is a global volume-weighted mean and
  # the two hemispheres differ by ~15 umol/kg (the model's solubility pump).
  aw <- function(nh, sh) (nh * aux$a_oc$NH + sh * aux$a_oc$SH) / (aux$a_oc$NH + aux$a_oc$SH)
  ix   <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)))
  # the OBSERVED profile integrated over the same column area the model's `inv`
  # spans (ml + oc boxes = the low-latitude column); a_oc before 2026-09-07d.
  mass <- (ccx_column_area(aux, "NH") + ccx_column_area(aux, "SH")) * grid$dz * rho
  surf_NH <- ml_ann("NH"); surf_SH <- ml_ann("SH")
  ml_1750 <- function(h) ccx_box_annual_conc(out, aux, grid, "ml", floor(min(out$t)) + 0.5, hemis = h)[["dic"]]
  list(year = yr, surf = aw(surf_NH, surf_SH), surf_1750 = aw(ml_1750("NH"), ml_1750("SH")),
       surf_NH = surf_NH, surf_SH = surf_SH,
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
#' @param obs the obs bundle. The default re-reads it (cached); a caller that
#'   holds several arms passes its own once (2026-09-12, review B5).
dg_streams <- function(r, v, obs = ccx_prepare_obs()) {
  # ⛔ SCORE THE OBJECTIVE'S OWN SPAN. DG_YEARS runs one forcing-held year past
  # the record (2026-09-12) so the annual readers' final boundary is interior;
  # the objective was fitted to DG_SINK_LAST, and scoring the held year with it
  # moved every arm ~-2.6 log-units off its stored streams (the scorecard's §0
  # guard caught it). Truncate BOTH the output and the forcing to that span.
  keep <- r$out$t < DG_SINK_LAST + 1
  o <- r$out[keep, ]
  Fk <- r$F[r$F$t < DG_SINK_LAST + 1, ]
  eluc <- ccx_forcing_eluc_annual(Fk)
  err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
              grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
  ccx_loglik(o, obs, err, luc = eluc,
             deep = ccx_d14c_deep_read(r$sp),
             ocean_grad = ccx_ocean_grad_scored(o, r$sp), by_stream = TRUE,
             d14c_mid = ccx_model_d14c_slabs(r$sp))
}

# =====================================================================
# GATE H -- THE INTERHEMISPHERIC GRADIENT CONTRAST (2026-09-04h)
#
# WHY IT EXISTS. The objective scores both MLO-SPO gradients through a FITTED
# ADDITIVE OFFSET (`grad_off_co2`, `grad_off_d13c`), so it constrains each
# gradient's YEAR-TO-YEAR VARIATION and not its LEVEL. Measured at `ent26`, each
# offset sits on the discrepancy it can absorb to four decimals:
#
#     grad_off_co2  = +0.2098  vs a CO2  gradient error of -0.2120 ppm
#     grad_off_d13c = +0.06464 vs a d13C gradient error of -0.06470 permil
#
# ⇒ the model's d13C interhemispheric gradient is **1.97x observed** and the
# `d13c_gradient` stream still scores +106 log-units, among the model's best.
# ⚠ THIS IS NOT A SILENT GATE: nothing is broken and no check is blind. The
# COMPENSATOR IS SIMPLY NOT STRAINED -- prior z +0.43 -- so no prior screen can
# find it. What finds it is putting the offset next to the residual it absorbs.
# ⚠ AND IT WAS PARTLY KNOWN: R/likelihood.R's own block says grad_off_d13c is
# "absorbing the known STRUCTURAL d13C misfit ... in effect the d13C gradient
# term is a SHAPE term". This gate does not discover that. IT GIVES IT A
# THRESHOLD, which is what was missing.
#
# ⭐⭐ WHAT IS SCORED, AND WHY IT IS A CONTRAST RATHER THAN A LEVEL.
# A two-box model's BOX gradient is legitimately not the STATION gradient, so a
# gate that demanded model == observed would be asserting something the repo has
# already argued is wrong. But a REPRESENTATION or TRANSPORT error acts on the
# interhemispheric exchange, which is TRACER-INDEPENDENT: gradient ~ (net
# hemispheric source) x (exchange time / atmospheric mass), and the last two are
# shared. So a common transport error SCALES BOTH GRADIENTS ALIKE, and
#
#     R_co2 = model_co2 / obs_co2   and   R_d13c = model_d13c / obs_d13c
#
# must AGREE. The CO2 gradient is therefore an INTERNAL CONTROL that absorbs
# whatever transport/representation error the two tracers share, and the gate
# isolates the part that is ISOTOPIC. Rejecting it says: the discrepancy is NOT
# transport -- it is in the isotopic source or the air-sea disequilibrium.
#
# THE BOUND IS THE OBSERVATIONS' OWN SAMPLING ERROR, NOT A CHOSEN TOLERANCE.
# Each observed mean carries se = sd_resid / sqrt(n_eff): BOTH the sd and the
# n_eff come from the DETRENDED series (the gradients trend as emissions grow,
# and charging that trend to the noise would inflate n_eff's correction).
# ⭐ RULED 2026-09-12 (Marcus): until then the sd was of the RAW trended series
# while n_eff was from the residual -- 3.4x too wide for CO2 (0.927 vs 0.273)
# and 1.6x for d13C. With the consistent se the CO2 CONTROL is itself out at
# -3.6 se (0.916x observed), so the "control passes" claim below is WITHDRAWN:
# the control is an 8 % transport/representation miss, significant at the
# station record's precision, and what the CONTRAST then isolates is the part
# of the d13C miss that is not that. The raw sd is kept as `sd` for reporting.
# The two ratios' errors propagate in quadrature. ⚠ The model side is
# DETERMINISTIC at a fixed vector and contributes no term -- said out loud
# because a missing error bar on one side is easy to forget.
#
# ⚠ THE CO2 ARM'S OWN LEVEL is REPORTED (z_level_co2): -3.6 se at every arm
# under the residual se (it read -1.06 under the raw sd). It is far smaller
# than the d13C arm's (-22), which test-gate-bounds.R asserts; it no longer
# "passes".
#
# ⛔ IT READS THE **RAW** MODEL GRADIENT AND NEVER THE FITTED OFFSET. Adding the
# offset would feed the compensator back in and the gate could never fail
# ([[gate_reads_its_own_output]]).
# =====================================================================
DG_H_NSD <- 2      # harmonised with DG_Q_NSD / DG_G5_NSD / DG_G7_NSD / DG_GD_NSD

#' n_eff of a series from its DETRENDED lag-1 autocorrelation
#' @param x the series; @param t its time coordinate
dg_neff_ar1 <- function(x, t) {
  r  <- stats::residuals(stats::lm(x ~ t))
  rho <- stats::acf(r, lag.max = 1, plot = FALSE)$acf[2]
  # a NEGATIVE rho would inflate n_eff above n; clamp at n, which is the
  # independent upper bound and the incumbent convention.
  min(length(x), length(x) * (1 - rho) / (1 + rho))
}

#' The observed side of GATE H, COMPUTED at source time from the obs bundle
#'
#' ⛔ Not typed. The gate-4 audit's finding was that a hand-typed target and a
#' computed model side can drift into being different estimators; both sides
#' here come from the same two lines.
dg_gateH_obs <- function(obs = ccx_prepare_obs()) {
  f <- function(g) {
    ok <- is.finite(g$grad)
    x <- g$grad[ok]; t <- g$year[ok]
    n_eff <- dg_neff_ar1(x, t)
    sd_resid <- stats::sd(stats::residuals(stats::lm(x ~ t)))
    list(mean = mean(x), sd = stats::sd(x), sd_resid = sd_resid, n = length(x),
         n_eff = n_eff, se = sd_resid / sqrt(n_eff), year = t)
  }
  list(co2 = f(obs$co2_grad), d13c = f(obs$d13c_grad))
}

#' GATE H's model side: the RAW MLO-SPO gradient means, on the observed years
#' @param v a dg_vector(); @param obs a ccx_prepare_obs(); @param ho a dg_gateH_obs()
#' @param r an existing dg_run(v) of the SAME v, reused instead of re-run
#'   (2026-09-12, review B5); NULL runs it. The run is deterministic, so the
#'   two paths are bit-identical (the scorecard's logs were diffed).
dg_gateH <- function(v, obs, ho = dg_gateH_obs(obs), r = NULL) {
  if (is.null(r)) r <- dg_run(v)
  ms <- ccx_model_stats(r$out, obs)
  f <- function(mod, g) {
    mg <- mod$MLO$level[match(g$year, mod$MLO$year)] -
          mod$SPO$level[match(g$year, mod$SPO$year)]
    if (!all(is.finite(mg)))
      stop("GATE H: the model has no gradient on some observed years.")
    mean(mg)
  }
  list(co2 = f(ms$co2, ho$co2), d13c = f(ms$d13, ho$d13c))
}

#' GATE H's verdict: the two gradients' RATIOS must agree
dg_gateH_verdict <- function(g, ho, n_sd = DG_H_NSD) {
  r  <- function(m, o) m / o$mean
  sr <- function(m, o) abs(m / o$mean) * (o$se / abs(o$mean))  # model has no error
  R_co2  <- r(g$co2,  ho$co2);  s_co2  <- sr(g$co2,  ho$co2)
  R_d13c <- r(g$d13c, ho$d13c); s_d13c <- sr(g$d13c, ho$d13c)
  d  <- R_d13c - R_co2
  se <- sqrt(s_co2^2 + s_d13c^2)
  z  <- d / se
  list(R_co2 = R_co2, R_d13c = R_d13c, se_co2 = s_co2, se_d13c = s_d13c,
       d = d, se = se, z = z, n_sd = n_sd, pass = abs(z) <= n_sd,
       # REPORTED BESIDE IT: each arm's own level miss, in its own se. ⚠ The
       # CO2 arm is the control, and on the residual se (2026-09-12) it is
       # itself out at -3.6 se at every arm: the "control passes" claim is
       # WITHDRAWN -- see the header.
       z_level_co2  = (g$co2  - ho$co2$mean)  / ho$co2$se,
       z_level_d13c = (g$d13c - ho$d13c$mean) / ho$d13c$se,
       mod_co2 = g$co2, mod_d13c = g$d13c,
       obs_co2 = ho$co2$mean, obs_d13c = ho$d13c$mean)
}

# =====================================================================
# GATE S -- THE SPO **OCEAN** SEASONAL LIMB'S **PHASE** (2026-09-03)
#
# WHY IT EXISTS, AND WHY IT IS OWED. The model's only active SH ocean seasonal
# limb peaks at month 3.35 against an observed 8.52 -- a 5.17 MONTH error, i.e.
# very nearly antiphase -- and NOTHING IN THE OBJECTIVE OR IN THIS GATE SET
# SCORED IT. That is how an error of that size survived for weeks: the SPO CO2
# seasonal rows ARE in the likelihood, but they score the TOTAL, which the model
# matches to ~2 % while nothing scores the PARTITION beneath it. ⚠ The
# '2.55x land / 0.45x ocean' this comment used to quote was measured at a
# PRE-ent26 mode AND on an ORIGIN split rather than the land/ocean one;
# like-for-like at ent26 the limbs are 1.05x and 0.77x (retracted 09-04h)
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
# ⭐ WHAT THE TARGET DEPENDS ON, STATED BEFORE IT IS USED. Nothing in the model.
# The ocean side is a pCO2 CLIMATOLOGY and the atmospheric side an observed
# station harmonic; the conversion between them is a physical law. This is a
# deliberate change of kind from the retired target, which was an observation
# inverted through the model's own d13C signatures.
#
# ⚠ AND THE ROUTE'S OWN CAVEAT, REPEATED AT ITS USE: pCO2 IS NOT FLUX.
# F = k*K0*dpCO2, and neither the wind seasonality in k nor the temperature
# seasonality in K0 is in the number. Both modulate AMPLITUDE strongly; their
# effect on PHASE is second-order but not zero. That is part of why the bound
# is a 3-month INTERVAL and not a sigma.
# =====================================================================
# ONE ESTIMATOR, not a second copy. `lib_seas_limbs.R` is THE SPO limb estimator
# for this project and every file that quotes a limb sources it; a gate carrying
# its own peak-to-peak / peak-month arithmetic is the caption-sync bug class, and
# peak-to-peak vs semi-amplitude has already inverted a conclusion on this arc
# ([[amp_definition_mismatch]]).
source(ccx_path("calibration", "lib_seas_limbs.R"))

# ⛔⛔ REBASED 2026-09-04h. GATE S USED TO READ `SPO_SEAS_OCEAN_PHASE_INV`
# = 8.52 [7.82, 9.20], an observation inverted through the model's own d13C
# SIGNATURES, and judged |z| <= 2 against a sigma derived from that CI. That
# target is now RETIRED: the 2026-09-02 temperature-dependent air-sea alphas
# make the ocean limb's isotopic signature rotate seasonally, so it is not the
# signed SCALAR the inversion assumes, and the inversion no longer runs at all
# (all four ocean channels fail its own antiphase gate).
#
# ⭐ THE REPLACEMENT USES NO MODEL OUTPUT. The SOM-FFN surface-ocean pCO2
# climatology gives the phase of the air-sea FLUX; a PHYSICAL LAW bounds the
# lag from flux to atmospheric limb at a QUARTER CYCLE. The admissible interval
# is therefore [SO_DPCO2_PEAK_MO, SO_DPCO2_PEAK_MO + SO_DPCO2_LAG_MAX_MO].
#
# ⭐ THE BOUND'S KIND CHANGED WITH ITS SOURCE, deliberately
# ([[gate_bound_matches_its_claim]]): a law that says "somewhere in this arc"
# is an INTERVAL, not a Gaussian. There is no sigma here and none is invented.
#
# ⚠ IT IS WIDER AND THAT IS THE HONEST COST: 3.00 months against the retired
# 1.41, i.e. 25 % of the circle, so a phase drawn at random passes with
# p = 0.25. ⭐ BUT ITS POWER WAS MEASURED BEFORE IT WAS ADOPTED, and it retains
# the power that matters: it EXCLUDES both readings of the pre-fix SH ocean
# limb (4.16 on the channel decomposition, 3.35 on lib_seas_limbs.R) -- the
# defect this gate was created to catch. A wider gate that still rejects the
# thing it exists to reject is a real gate; see test-gate-bounds.R, which
# asserts exactly that and fails if the exclusion is ever lost.
DG_S_PCO2_MO <- ccx_const("SO_DPCO2_PEAK_MO")
DG_S_LAG_MAX <- ccx_const("SO_DPCO2_LAG_MAX_MO")
DG_S_LO      <- DG_S_PCO2_MO
DG_S_HI      <- (DG_S_PCO2_MO + DG_S_LAG_MAX) %% 12
# The RETIRED target, kept by name so a matched comparison against any result
# fitted before 2026-09-04h is still possible without a git blame.
DG_S_OBS_RETIRED <- ccx_const("SPO_SEAS_OCEAN_PHASE_INV")
# ⚠ THE LIMB AMPLITUDE NO LONGER HAS AN OBSERVED COMPARATOR. It used to be
# reported (never bounded) against SPO_SEAS_AMP_OCEAN_INV, which is retired
# with the rest of the inversion. The pCO2 route CANNOT supply one: pCO2 is not
# flux, and the wind seasonality in k and temperature seasonality in K0 both
# modulate amplitude strongly. The amplitude is therefore printed BARE, with no
# ratio, rather than kept against a number that is now provenance.
DG_S_KO <- SL_CASES$SH_ocean

#' Signed CIRCULAR difference between two months of year, in [-6, +6)
#' Months are an angle: 11.9 and 0.1 are 0.2 months apart, not 11.8. ⚠ A
#' HALF-CYCLE returns -6, not +6 (`(a - b + 6) %% 12` is 0 there). The doc said
#' (-6, +6] until 2026-09-12; the CODE is what is kept, because
#' dg_gateS_verdict()'s d_lo / d_hi use the same arithmetic and moving the
#' boundary here alone would leave the two disagreeing at exactly one angle.
dg_mo_diff <- function(a, b) ((a - b + 6) %% 12) - 6

#' The SPO CO2 first-harmonic vector at one dg_vector(), as (a, b)
dg_spo_vec <- function(v, obs, r = NULL) {
  if (is.null(r)) r <- dg_run(v)     # reuse a held run of the SAME v (09-12, B5)
  ms <- ccx_model_stats(r$out, obs)
  h  <- ms$co2_seas$SPO
  if (is.null(h)) stop("GATE S: the run returned no SPO seasonal harmonic.")
  c(mean(h$a), mean(h$b))
}

#' GATE S's model side: the SH-OCEAN limb of SPO, by knockout
#'
#' The limb is BASE MINUS the run with EVERY SH ocean seasonal driver zeroed
#' (the SST sine, the entrainment shim, and -- since 2026-09-12 -- the seasonal
#' mixed layer itself, `seas_ml`; see SL_CASES$SH_ocean for why and for the
#' hemisphere caveat) -- the
#' contribution those drivers make to SPO, as a VECTOR. Limbs are vectors: an
#' amplitude that grows while the phase stays antiphase makes the cancellation
#' WORSE, not better ([[ccx_seas_2x2_admissible]]).
#' @param v a dg_vector(); @param obs a ccx_prepare_obs()
#' @param r an existing dg_run(v) for the BASE arm (2026-09-12, review B5); the
#'   knockout arm is always run
dg_gateS <- function(v, obs, r = NULL) {
  base <- dg_spo_vec(v, obs, r)
  vk   <- v
  for (n in names(DG_S_KO)) vk$p[[n]] <- DG_S_KO[[n]]
  ko   <- dg_spo_vec(vk, obs)
  d    <- base - ko
  list(v_ocean = d, amp = sl_amp(d), mo = sl_ang_mo(d),
       v_total = base, amp_total = sl_amp(base), mo_total = sl_ang_mo(base),
       ent = v$p$ent_seas_amp_SH, sst_amp_SH = v$p$sst_seas_amp_SH)
}

#' GATE S's verdict: INTERVAL membership on the limb PHASE alone
#'
#' The claim is "the atmospheric ocean-signatured limb lags the observed
#' air-sea pCO2 difference by between 0 and a quarter cycle". That is an arc,
#' so the test is arc membership and `d_mo` reports the SIGNED distance to the
#' nearer edge (0 when inside). No z, because there is no sigma to divide by.
dg_gateS_verdict <- function(g, lo = DG_S_LO, w = DG_S_LAG_MAX) {
  inside <- ((g$mo - lo) %% 12) <= w
  # signed miss: negative = early of the lower edge, positive = late of the upper
  d_lo <- ((g$mo - lo + 6) %% 12) - 6
  d_hi <- ((g$mo - (lo + w) + 6) %% 12) - 6
  d    <- if (inside) 0 else if (abs(d_lo) < abs(d_hi)) d_lo else d_hi
  list(mo = g$mo, lo = lo, hi = (lo + w) %% 12, width = w,
       d_mo = d, pass = inside,
       # the retired inversion target, for matched comparison ONLY
       obs_mo_retired = DG_S_OBS_RETIRED,
       d_mo_vs_retired = ((g$mo - DG_S_OBS_RETIRED + 6) %% 12) - 6,
       # PRINTED BARE -- the pCO2 route supplies no amplitude comparator
       amp = g$amp)
}


# =====================================================================
# GATE L: the LAND share of a 100 GtC pulse at 1000 yr, against Joos et al.
# 2013's multi-model split (T-L, 2026-09-08g; option H's finding made a gate).
#
# Same protocol as the IRF comparison (gate 12): the historical run to
# JOOS_REF_YEAR, the background CO2 HELD there by diagnosed emissions
# (ccx_hold_forcing), the pulse added to the held state at its own isotopic
# ratios (ccx_pulse_state), and the partition read as the PAIRED DIFFERENCE
# pulse - baseline in each reservoir. The pulse is added at the reference
# year's state (t = 0 of the series); the horizon counts from there.
#
# WHY A GATE ON THE LAND SHARE. The IRF miss is a comparison, not a gate
# (09-04e). But option H (assessment 09-08f) found the model's 100-yr land
# share 0.41 against an ensemble 1000-yr share of 0.16 +/- 0.14, and read the
# short lifetime as a LAND-saturation question. A gate on the share makes the
# next land change judged on it. The source class is the last-resort one --
# another model's ensemble -- and the ledger says so.
#
# ⚠ THE BOUND IS 1 sd OF THE MULTI-MODEL SPREAD, two-sided. Not the 2 x se
# every observational gate uses: this sd is a spread of models, not a sampling
# error, and 2 sd of it ([-12, 44] %) would admit the canonical. A CHOICE,
# stated here and in the ledger, for Marcus to ratify or move.
# =====================================================================
DG_L_HORIZON <- 1000
DG_L_JOOS <- list(land  = c(mean = 16, sd = 14),
                  ocean = c(mean = 59, sd = 12),
                  air   = c(mean = 25, sd = 9),
                  src = "Joos et al. 2013 ACP 13:2793, abstract (SOURCED, notes/assessment_2026-09-08_acceptable_state.md)")
DG_L_NSD <- 1            # kept for the comparison's z-band label only
DG_L_RES <- c("land", "ocean", "air")
DG_L_COMPARISON <- paste("COMPARISON, NOT A GATE (Marcus 2026-09-08h): 'Do not use Joos as a scoring",
                         "mechanism: the long lifetime is meant to be an emergent property, not something",
                         "we fit to.' Use dg_compareL() for the reported z's; nothing passes or fails here.")
DG_L_EXTRA_YR <- 10   # forcing built this far past the horizon so the read is interior

dg_gateL_partition <- function(v, horizon = DG_L_HORIZON, pulse = JOOS_PULSE) {
  spin <- dg_spinup(v)
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14,
                              bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, F_hist)$state
  F_fwd <- suppressWarnings(ccx_build_forcing("historical",
             c(JOOS_REF_YEAR, JOOS_REF_YEAR + horizon + DG_L_EXTRA_YR),
             prod_c14 = spin$prod_c14, bomb_total_kmol = 0, luc_scale = v$luc_scale))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso", "c14_bomb", "c14_nuclear"))
    F_fwd[[cc]] <- 0
  F_fwd$gmst <- F_fwd$gmst[1]
  F_hold <- ccx_hold_forcing(sp_ref, F_fwd, verbose = FALSE)
  b <- ccx_run_fast(sp_ref, F_hold)$out
  q <- ccx_run_fast(ccx_pulse_state(sp_ref, pulse), F_hold)$out
  gpp <- ccx_const("GtC_PER_PPM")
  d <- data.frame(t = b$t - b$t[1],
                  air   = ((q$co2_NH + q$co2_SH) - (b$co2_NH + b$co2_SH)) / 2 * gpp,
                  ocean = q$ocean_C - b$ocean_C,
                  land  = q$land_C  - b$land_C)
  d$closure <- (d$air + d$ocean + d$land) / pulse
  at <- function(h) d[which.min(abs(d$t - h)), ]
  share_at <- function(h) { r <- at(h); 100 * c(land = r$land, ocean = r$ocean, air = r$air) / pulse }
  list(series = d, horizon = horizon, pulse = pulse, hold_dev = attr(F_hold, "dev"),
       share = share_at(horizon), share_at = share_at, closure = at(horizon)$closure)
}

# The REPORTED comparison: where the model's pulse partition sits against the
# ensemble's, in the ensemble's own sd units. No `pass` field, by ruling.
dg_compareL <- function(g, joos = DG_L_JOOS) {
  z <- vapply(DG_L_RES, function(k) (g$share[[k]] - joos[[k]][["mean"]]) / joos[[k]][["sd"]], numeric(1))
  list(share = g$share, z = z, joos = joos, src = joos$src)
}
# A verdict must ERROR WITH THE REASON, the way gate 4 and a retired mode name
# do, not return a plausible pass/fail (the silent-gate family).
dg_gateL_verdict <- function(...) stop("GATE L: ", DG_L_COMPARISON)

# =====================================================================
# GATE GL: the interhemispheric d13C gradient LEVEL (T-G, 2026-09-08g).
#
# Beside gate H, which gates the CONTRAST R_d13c - R_co2 (transport cancels).
# The d13c_gradient stream scores the gradient's SHAPE through a fitted
# offset, so a 1.97x level miss costs the objective nothing visible
# ([[ccx_offsets_absorb_the_errors]]). This gate reads the SAME raw model
# gradient dg_gateH() reads (never grad_off_d13c) against the observed mean's
# own sampling error from dg_gateH_obs(): the observation's number, not a
# typed one. `rep_frac` adds a representation allowance rep_frac x |obs| in
# quadrature -- the CO2 control's |1 - R_co2| is the measured size of what a
# two-box gradient legitimately is not.
#
# ⭐ RULING 3 (Marcus, 2026-09-09): THE GATE PROPER IS THE AUGMENTED FORM, and
# the bare-se z is what gets REPORTED beside it -- the exact reverse of the
# 09-08g arrangement, which shipped with the choice explicitly deferred ("CHOICE
# for Marcus" in diag_tg_gradient_level_gate.R). Bounding on the observation's
# sampling error ALONE asks a two-box model to reproduce an MLO-minus-SPO
# gradient to the precision of the station record, which charges the model for
# something no two-box gradient can be: a station pair is not a hemispheric
# mean. The CO2 arm MEASURES that discrepancy on a tracer whose gradient the
# model has no isotopic freedom to bend, so |1 - R_co2| is a representation
# allowance taken from an OBSERVATION under the same estimator, not a typed
# tolerance ([[threshold_from_obs_or_law]], [[tolerance_scaled_to_spread]]).
# ⚠ IT IS AN ALLOWANCE, NOT AN EXCUSE: it moves the canonical from z -13 to
# z -9. The gate still FAILS, and by a wide margin -- which is the point. A
# weakening that cannot change the verdict is the honest kind.
# ⚠ AND IT IS DERIVED, NEVER TYPED ([[derived_must_mean_computed]]): rep_frac
# is COMPUTED from the same (g, ho) the gate is reading. Passing rep_frac
# explicitly overrides it, which is what the report and the mutation tests do.
# =====================================================================
DG_GL_NSD <- DG_H_NSD

#' The CO2 control's measured representation size, |1 - R_co2|.
#' @return a non-negative scalar; NA if the control's CO2 arm is absent.
dg_gl_rep_frac <- function(g, ho) abs(1 - g$co2 / ho$co2$mean)

dg_gateGL_verdict <- function(g, ho, n_sd = DG_GL_NSD, rep_frac = NULL) {
  o <- ho$d13c; m <- g$d13c
  derived <- is.null(rep_frac)
  if (derived) rep_frac <- dg_gl_rep_frac(g, ho)
  se <- sqrt(o$se^2 + (rep_frac * o$mean)^2)
  z  <- (m - o$mean) / se
  list(model = m, obs = o$mean, se_obs = o$se, se = se, rep_frac = rep_frac,
       rep_frac_derived = derived, R_co2 = g$co2 / ho$co2$mean,
       ratio = m / o$mean, z = z, n_sd = n_sd,
       # REPORTED BESIDE IT (ruling 3's second half): the bare-se z, which was
       # the gate until 2026-09-09. Printed so the size of the allowance is
       # always visible next to the verdict it produced.
       z_bare = (m - o$mean) / o$se,
       pass = is.finite(z) && abs(z) <= n_sd)
}
