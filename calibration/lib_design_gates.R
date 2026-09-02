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
DG_AF_OBS     <- 0.431
DG_AF_DECADES <- c(1960, 1970, 1980, 1990, 2000, 2010, 2020)
DG_AF_OBS_DEC <- c(0.35, 0.43, 0.47, 0.38, 0.42, 0.45, 0.50)

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
  cat(sprintf("  The three distributional gates now share one strictness: DG_G5_NSD %g,\n",
              DG_G5_NSD))
  cat(sprintf("    DG_G7_NSD %g, DG_Q_NSD %g.\n", DG_G7_NSD, DG_Q_NSD))
  cat("  ⚠ NO LAW-DERIVED GATE EXISTS. Candidates, none built: carbonate /\n")
  cat("    Revelle consistency, Henry's-law solubility, and -- most valuable,\n")
  cat("    since gate 12a reports an ocean-CAPACITY defect it cannot localise --\n")
  cat("    an ocean DIC inventory against GLODAP, which is observational and\n")
  cat("    currently ungated.\n")
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
dg_gate4 <- function(r, v) {
  o <- r$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2 * DG_GtC_PER_PPM,
                       xout = bnd, rule = 2)$y
  grow <- diff(atm)
  el <- ccx_forcing_eluc_annual(r$F)
  # No ccx_forcing_efoss_annual() exists; this is the eluc helper's own recipe
  # (FUN = mean over the calendar year, because the columns are GtC/yr RATES,
  # not monthly masses -- summing them would give twelve times the emission).
  ef <- stats::aggregate(list(efoss = r$F$e_foss_NH + r$F$e_foss_SH),
                         by = list(year = r$F$year), FUN = mean)
  luc  <- el$eluc[match(yrs, el$year)]
  foss <- ef$efoss[match(yrs, ef$year)]
  af <- function(k) sum(grow[k]) / sum((foss + luc)[k])
  k <- yrs >= DG_AF_WIN[1] & yrs <= DG_AF_WIN[2]
  dec <- vapply(DG_AF_DECADES, function(d) {
    kk <- yrs >= d & yrs <= min(d + 9, DG_AF_WIN[2]) & k; af(kk)
  }, numeric(1))
  list(all = af(k), dec = dec,
       all_unscaled = sum(grow[k]) / sum((foss + luc / v$luc_scale)[k]))
}

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
