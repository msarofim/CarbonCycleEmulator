# =====================================================================
# diag_2x2_repriced_at_enso25.R -- RE-PRICE THE 08-27q VERDICT AT THE
#   25-PARAMETER MODE, MATCHED AGAINST THE ARMS IT WAS PRONOUNCED ON.
#
# WHY THIS EXISTS. `handoff_2026-09-01f` §4: 27q concluded that rotating the SH
# ocean limb into phase REMOVES the SH cancellation and OVERSHOOTS the SPO total
# by 18 %. ⭐ That verdict is ARITHMETIC about two limbs ADDING -- and one addend
# has since moved. The prior screen (§2, `900f90b`) found `seas_T_amp_SH` INSIDE
# its measured bracket at the 25-parameter mode, where 27q measured it against an
# SH land limb at 1.26x observed. An arithmetic verdict whose addend changed is
# not a verdict any more; it is an old measurement.
#
# ⇒ SO THIS IS A RE-PRICING, NOT A FRESH 2x2. Every number 27q measured is READ
# from its own stored result and printed BESIDE the new one. A fresh 2x2 would
# produce numbers with nothing to be compared against, which is the failure the
# handoff names explicitly.
#
# WHAT IT IS AND IS NOT. It ADOPTS NOTHING. `CCX_MODE_CANONICAL` and
# `R/constants.R` are untouched; every mode is read BY PATH -- the same contract
# as `diag_gates_in_the_new_basin.R` and `diag_prior_screen_enso25.R`.
#
# ⛔ AND IT DOES NOT REFIT. 27q's headline statistic is an INTERACTION between
# six REFITTED arms; nothing here reproduces that, and no gate below is 27q's P1.
# What is re-priced is the ARITHMETIC verdict -- P4/P5, the limbs and their
# phases -- which is what §4 says has gone out of date. Whether the six-arm
# refit is worth re-running at 25 parameters is a call this file's numbers
# INFORM; it is not a call this file makes.
#
# THE VECTORS, and why each is here:
#   * 27q INCUMBENT -- the from90 mode as 27q measured it. The state the
#                      verdict's baseline was taken in.
#   * 27q LAND_hi   -- SH land PINNED at the bracket high end. 27q's way of
#                      making the land limb small; the 25-par mode got there
#                      by fitting instead.
#   * 27q JOINT_hi  -- THE ARM THE VERDICT WAS PRONOUNCED ON: ocean rotated into
#                      phase, total 1.382 against obs 1.168.
#   * enso25 A / B  -- the two cluster representatives of the 09-01 survey, the
#                      same two the prior screen used, MEASURED here.
#
# ⛔ THE COMMITTED .rds AND .log ARE PRE-2026-09-02 AND MUST STAY THAT WAY.
# On 09-02 the air-sea 13C alphas became temperature-dependent, which CHANGED
# THE OBJECTIVE. Re-running this file today reproduces every CO2 number
# EXACTLY -- a 13C change cannot touch total carbon, and that identity is worth
# knowing -- but it moves the d13C-per-ppm ratios: enso25 A `r_SPO` 2.063 ->
# 2.172, the 27q INCUMBENT 1.933 -> 1.998. The sec.4/sec.5 verdicts are CO2
# arithmetic and are unaffected. `alpha_as_tdep` is recorded in the output so a
# reader can tell which model produced a stored run.
#
# Usage:  Rscript calibration/diag_2x2_repriced_at_enso25.R      # ~1 min
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_seas_limbs.R"))

# ---- named constants: every label below derives from these ----------
RP_OLD_RDS  <- "outputs/diagnostics/admissible_2x2_land_ocean.rds"
RP_OLD_SRC  <- "calibration/diag_admissible_2x2_land_ocean.R"
RP_OLD_LAB  <- "08-27q"
RP_OLD_MODE <- "from90"                 # the mode 27q ran on, by NAME
RP_OLD_ARMS <- c("INCUMBENT", "LAND_hi", "JOINT_hi")   # the verdict's three
RP_NEW_DIR  <- "calibration/output/multistart_20260901_enso25"
RP_NEW_REPS <- c("enso25 A" = "start_000.rds",   # cluster 1, cold init
                 "enso25 B" = "start_005.rds")   # cluster 2, obs-implied partition
RP_YEARS    <- c(1750, 2024)            # 27q's AQ_YEARS, unchanged
# 27q's own P4 gate on the SPO total, applied unchanged so the column means what
# it meant. ⚠ NOT re-derived here: re-deriving a gate at the state you are
# testing is re-baselining. Its provenance is 27j, via prereg 27q sec.2.
RP_P4       <- c(1.114, 1.222)
# sec.6's walk: FROM this vector TO this one, one parameter GROUP at a time.
RP_WALK_FROM <- "08-27q INCUMBENT"
RP_WALK_TO   <- "enso25 A"
# Split names move TOGETHER or the step is not one parameter's move. Everything
# not listed walks alone.
RP_WALK_GROUPS <- list(seas_lag_p = c("seas_lag_p_NH", "seas_lag_p_SH"),
                       gamma_enso = CCX_ENSO_PARAMS)
RP_WALK_MIN <- 0.005      # ppm of SH-land limb move below which a step is not
                          # printed. A LEGIBILITY threshold, not a gate: every
                          # step is in the saved rds and the sum is over ALL.

# ⚠ AN IDENTITY, SO AN EXACT BOUND. Same parameter vector, same model, same
# estimator ⇒ the same limb, to floating point. This is NOT an optimiser
# comparison and must not borrow an optimiser's tolerance.
# [[gate_bound_matches_its_claim]]
RP_REPRO_TOL <- 1e-8                    # relative

# ⭐ THE ONE MECHANISM THE MODEL GAINED AFTER 27q RAN. Volcanic diffuse-light
# fertilisation was IMPLEMENTED `328cdb8` (2026-08-29) and its coefficient
# ADOPTED at 0.25 in `a2298dc` the same day; 27q ran 2026-08-28 and therefore
# ran at 0. So GATE R below is EXPECTED to fail on today's model, and the
# question is not whether it fails but whether ONE named change accounts for
# ALL of it. The control re-scores the old arms at the pre-adoption value and
# must then reproduce them exactly. ⚠ If a SECOND thing had changed, the
# control fails too -- which is the whole reason it is a control and not a
# widened tolerance.
RP_GDIFF_PREADOPT <- 0                  # ccx_default_params()$gamma_diff before a2298dc

# ⚠ THE FOUR OBSERVED CONSTANTS ARE NOT IN `R/constants.R`. They are the
# 2026-08-27h signature inversion (`diag_seas_signature_inversion.R`, which
# splits the OBSERVED SPO cycle from the observations alone), replicated as
# file-local constants across ~10 diagnostics -- 27q's own AQ_OBS_* among them.
# Declared here for the same reason, and GATED against the obs actually loaded
# (gate O) so a drifted copy cannot pass silently.
RP_OBS_TOTAL <- 1.168      # observed SPO CO2 seasonal peak-to-peak, ppm
RP_OBS_LAND  <- 0.683      # its land limb
RP_OBS_OCEAN <- 0.522      # its ocean limb
RP_OBS_OCN_MO<- 8.52       # the ocean limb's phase, months
RP_OBS_TOL   <- 0.02       # gate O: how far the loaded obs may sit from the
                           # quoted constant before the constant is stale. A
                           # ROUNDING claim -- the constants carry 3 decimals --
                           # so it is scaled to the last printed digit, not to
                           # a spread.

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
cat(sprintf("\n%s\nRE-PRICING THE %s ARITHMETIC VERDICT AT THE 25-PARAMETER MODE\n  old: %s (read from %s)\n  new: %s\n  %d parameters in this build. ADOPTS NOTHING. DOES NOT REFIT.\n%s\n",
            strrep("=", 78), RP_OLD_LAB, RP_OLD_SRC, RP_OLD_RDS, RP_NEW_DIR,
            length(CCX_PARAM_NAMES), strrep("=", 78)))

obs  <- ccx_prepare_obs()
obsv <- sl_obs_vectors(obs)

sep("O. GATE O -- ARE THE QUOTED OBSERVED CONSTANTS STILL THE OBSERVATIONS?")
obs_total_v <- obsv$co2_SPO
obs_ocn_v   <- sl_vec(RP_OBS_OCEAN, RP_OBS_OCN_MO)
obs_land_v  <- obs_total_v - obs_ocn_v          # DERIVED, not a fourth constant
g_tot  <- abs(sl_amp(obs_total_v) - RP_OBS_TOTAL)
g_land <- abs(sl_amp(obs_land_v)  - RP_OBS_LAND)
cat(sprintf("  loaded obs SPO total      %8.4f ppm @ %5.2f mo   vs quoted %.3f   |d| %.4f  %s\n",
            sl_amp(obs_total_v), sl_ang_mo(obs_total_v), RP_OBS_TOTAL, g_tot,
            if (g_tot <= RP_OBS_TOL) "ok" else "⚠ STALE"))
cat(sprintf("  IMPLIED obs land = total - ocean  %8.4f ppm @ %5.2f mo   vs quoted %.3f   |d| %.4f  %s\n",
            sl_amp(obs_land_v), sl_ang_mo(obs_land_v), RP_OBS_LAND, g_land,
            if (g_land <= RP_OBS_TOL) "ok" else "⚠ INCONSISTENT"))
GO <- g_tot <= RP_OBS_TOL && g_land <= RP_OBS_TOL
cat(sprintf("\n  ⇒ the three quoted observed limbs are %s as VECTORS.\n",
            if (GO) "MUTUALLY CONSISTENT" else
              "NOT mutually consistent -- sec.3's arithmetic inherits that"))

# ---- assemble the vectors -------------------------------------------
old <- readRDS(RP_OLD_RDS)
stopifnot(all(RP_OLD_ARMS %in% names(old$res)))
old_md <- readRDS(ccx_mode_file(RP_OLD_MODE))   # for its pump ARM, read not assumed
V <- list()
for (a in RP_OLD_ARMS)
  V[[paste(RP_OLD_LAB, a)]] <- list(
    pv = old$res[[a]]$pv, ent = old$res[[a]]$ent, pump = old_md$pump_mode,
    src = sprintf("%s arm %s (%d par, ent %.3f)", RP_OLD_LAB, a,
                  length(old$res[[a]]$pv), old$res[[a]]$ent),
    stored = old$res[[a]]$s)
for (nm in names(RP_NEW_REPS)) {
  s <- readRDS(file.path(RP_NEW_DIR, RP_NEW_REPS[[nm]]))
  # ⚠ THE BAND, BEFORE ANYTHING IS BELIEVED. `par_mode` is what the refit FOUND;
  # `u_mode` decodes to it only under the band in force at the time. These files
  # record both -- assert they agree rather than trusting either.
  stopifnot(identical(s$param_names, CCX_PARAM_NAMES))
  V[[nm]] <- list(pv = s$par_mode, ent = 0, pump = s$pump_mode,
                  src = sprintf("survey id %d, %s, logpost %.3f, converged=%s%s",
                                s$id, s$kind, s$logpost, s$converged,
                                if (isTRUE(s$out_of_time)) " ⚠ OUT OF TIME" else ""),
                  stored = NULL, band = list(hml = s$hml_bound, kz = s$kz_bracket))
}
cat("\n  vectors:\n")
for (nm in names(V)) cat(sprintf("    %-16s %s\n", nm, V[[nm]]$src))

sep("1. GATE R -- DOES TODAY'S HARNESS REPRODUCE 27q's STORED LIMBS?")
cat("  Same parameter vector, same model, same estimator: an IDENTITY. If this\n")
cat("  fails, the old and new columns are NOT like-for-like and nothing below\n")
cat("  may be read as a change in the physics.\n")
cat(sprintf("\n  %-16s %-10s %10s %10s %11s %11s   %10s\n", "arm", "limb",
            "amp 27q", "amp now", "rel now", "rel CTRL", "d mo now"))
S <- list(); SC <- list(); GR <- TRUE; GRC <- TRUE
CTRL <- list(gamma_diff = RP_GDIFF_PREADOPT)
for (nm in names(V)) {
  v <- V[[nm]]
  S[[nm]] <- sl_score(v$pv, v$ent, v$pump, obs, obsv, RP_YEARS)
  if (is.null(v$stored)) next
  SC[[nm]] <- sl_score(v$pv, v$ent, v$pump, obs, obsv, RP_YEARS, base_mods = CTRL)
  rows <- c(list(total = S[[nm]]$total),  S[[nm]]$dec)
  ctl  <- c(list(total = SC[[nm]]$total), SC[[nm]]$dec)
  ref  <- c(list(total = v$stored$total), v$stored$dec)
  for (k in names(ref)) {                      # over the STORED limbs, not today's
    rel <- abs(rows[[k]][["amp"]] - ref[[k]][["amp"]]) / abs(ref[[k]][["amp"]])
    rlc <- abs(ctl[[k]][["amp"]] - ref[[k]][["amp"]]) / abs(ref[[k]][["amp"]])
    dmo <- rows[[k]][["mo"]] - ref[[k]][["mo"]]
    GR  <- GR  && rel <= RP_REPRO_TOL
    GRC <- GRC && rlc <= RP_REPRO_TOL
    cat(sprintf("  %-16s %-10s %10.5f %10.5f %11.2e %11.2e   %10.2e %s\n",
                nm, k, ref[[k]][["amp"]], rows[[k]][["amp"]], rel, rlc, abs(dmo),
                if (rlc <= RP_REPRO_TOL) "attributed" else "⚠ UNEXPLAINED"))
  }
}
cat(sprintf("\n  on TODAY's model            -> %s\n", if (GR) "PASS" else "FAIL"))
cat(sprintf("  with gamma_diff = %g (27q's) -> %s\n", RP_GDIFF_PREADOPT,
            if (GRC) "PASS" else "FAIL"))
cat(sprintf("\n  GATE R -> %s\n  (bound %.0e relative, an IDENTITY -- not widened, ATTRIBUTED)\n",
            if (GRC && !GR)
              paste("ATTRIBUTED. The old arms reproduce EXACTLY once the one mechanism",
                    "\n            adopted after 27q is switched off, so the whole gap is that",
                    "\n            mechanism and nothing else moved. ⇒ sec.2-4 compare every",
                    "\n            vector through TODAY's model, which is like-for-like BETWEEN",
                    "\n            COLUMNS; the STORED 27q numbers are the historical record and",
                    "\n            differ from their re-scored selves by the amounts above.")
            else if (GR) "PASS -- nothing moved at all."
            else "⚠ FAIL AND UNATTRIBUTED -- a SECOND change is in here. Do not read sec.2-4.",
            RP_REPRO_TOL))

sep("2. WHERE EVERY VECTOR LANDS -- 27q's TABLE, WITH THE NEW MODE IN IT")
cat(sprintf("  %-16s %8s %6s | %8s %6s | %8s %6s | %8s %6s | %7s %7s | %8s %8s\n",
            "vector", "total", "mo", "SH-land", "mo", "SH-ocn", "mo", "NH-orig", "mo",
            "SPO r", "MLO r", "sstSH", "sTaSH"))
for (nm in names(V)) { s <- S[[nm]]; p <- V[[nm]]$pv
  cat(sprintf("  %-16s %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %7.3f %7.3f | %8.4f %8.3f\n",
              nm, s$total[["amp"]], s$total[["mo"]], s$dec$SH_land[["amp"]], s$dec$SH_land[["mo"]],
              s$dec$SH_ocean[["amp"]], s$dec$SH_ocean[["mo"]], s$dec$NH_origin[["amp"]],
              s$dec$NH_origin[["mo"]], s$r_SPO, s$r_MLO,
              p$sst_seas_amp_SH, p$seas_T_amp_SH)) }
cat(sprintf("  %-16s %8.3f %6.2f | %8.3f %6.2f | %8.3f %6.2f | %8s %6s | %7.3f %7.3f\n",
            "OBSERVED", sl_amp(obs_total_v), sl_ang_mo(obs_total_v),
            sl_amp(obs_land_v), sl_ang_mo(obs_land_v), RP_OBS_OCEAN, RP_OBS_OCN_MO,
            "", "", 1.000, 1.000))
cat("\n  ⚠ the OBSERVED land row is total MINUS the inversion's ocean limb, so it\n")
cat("    carries the NH-origin contribution too; the model's SH-land column does\n")
cat("    NOT. 27q compared them anyway and its 1.26x is that comparison -- kept\n")
cat("    here so the columns mean the same thing they did, flagged so the ratio\n")
cat("    is not read as like-for-like between model limb and observed limb.\n")

sep("3. THE ARITHMETIC, RE-PRICED -- WHAT THE OCEAN LIMB WOULD HAVE TO BE")
cat("  27q's verdict was ARITHMETIC: land 1.26x obs and ocean 0.53x, rotated into\n")
cat("  phase, ADD to 1.382 against obs 1.168. Re-priced as the sharper question --\n")
cat("  GIVEN this vector's NH-origin and SH-land limbs, what must the SH ocean limb\n")
cat("  BE for the SPO total to be right, and how far is that from the observed one?\n\n")
cat("  ⚠ THE THREE LIMBS DO NOT SUM TO THE TOTAL -- the model is nonlinear and each\n")
cat("    limb is a zeroing DIFFERENCE. The gap is carried as a fixed REMAINDER and\n")
cat("    printed; every counterfactual below holds it. That is an assumption, and\n")
cat("    it is the size of the printed remainder.\n")
cat(sprintf("\n  %-16s %9s %8s | %6s %6s | %8s %8s %7s | %9s %6s %8s\n", "vector",
            "remaindr", "of which", "land/", "ocn/", "d phase", "total/", "P4?",
            "REQ ocn", "@ mo", "REQ/obs"))
cat(sprintf("  %-16s %9s %8s | %6s %6s | %8s %8s %7s | %9s %6s %8s\n", "",
            "ppm", "ENSO", "obs", "obs", "land-ocn", "obs", "", "ppm", "", ""))
A <- list()
for (nm in names(V)) {
  s <- S[[nm]]
  # ⚠ 27q's THREE limbs, deliberately: the remainder is what they leave, and on
  # the new mode the ENSO limb is INSIDE it. Printed separately below.
  rem  <- s$total_v - Reduce(`+`, s$dec_v[SL_CASES_27Q])
  # what the ocean limb must be, holding NH-origin, SH-land and the remainder
  req  <- obs_total_v - s$dec_v$NH_origin - s$dec_v$SH_land - rem
  dph  <- ((s$dec$SH_land[["mo"]] - s$dec$SH_ocean[["mo"]] + 6) %% 12) - 6
  # 27q's own P4 gate, applied unchanged
  p4   <- s$total[["amp"]] >= RP_P4[1] && s$total[["amp"]] <= RP_P4[2]
  A[[nm]] <- list(rem = rem, req = req, dph = dph)
  cat(sprintf("  %-16s %9.4f %8.4f | %6.3f %6.3f | %+8.2f %8.3f %7s | %9.4f %6.2f %8.3f\n",
              nm, sl_amp(rem), s$dec$ENSO[["amp"]],
              s$dec$SH_land[["amp"]] / RP_OBS_LAND,
              s$dec$SH_ocean[["amp"]] / RP_OBS_OCEAN, dph,
              s$total[["amp"]] / RP_OBS_TOTAL, if (p4) "PASS" else "FAIL",
              sl_amp(req), sl_ang_mo(req), sl_amp(req) / RP_OBS_OCEAN))
}
cat(sprintf("  %-16s %9s %8s | %6.3f %6.3f | %8s %8.3f %7s | %9.4f %6.2f %8.3f\n",
            "OBSERVED", "", "", sl_amp(obs_land_v) / RP_OBS_LAND, 1.000, "", 1.000, "--",
            RP_OBS_OCEAN, RP_OBS_OCN_MO, 1.000))

sep("4. THE COUNTERFACTUAL 27q ACTUALLY RAN -- ROTATE THE OCEAN INTO PHASE")
cat("  Hold NH-origin, SH-land and the remainder; move the SH ocean limb, first to\n")
cat("  the SH LAND phase at its own amplitude (27q's rotation), then to the\n")
cat("  OBSERVED limb entirely. The overshoot 27q reported is the first column.\n")
cat(sprintf("\n  %-16s %10s %8s | %10s %8s | %10s %8s\n", "vector",
            "as measured", "/obs", "ocn ROTATED", "/obs", "ocn = OBS", "/obs"))
for (nm in names(V)) {
  s <- S[[nm]]; rem <- A[[nm]]$rem
  fixed <- s$dec_v$NH_origin + s$dec_v$SH_land + rem
  rot   <- fixed + sl_vec(s$dec$SH_ocean[["amp"]], s$dec$SH_land[["mo"]])
  obsq  <- fixed + obs_ocn_v
  cat(sprintf("  %-16s %10.3f %8.3f | %10.3f %8.3f | %10.3f %8.3f\n", nm,
              s$total[["amp"]], s$total[["amp"]] / RP_OBS_TOTAL,
              sl_amp(rot), sl_amp(rot) / RP_OBS_TOTAL,
              sl_amp(obsq), sl_amp(obsq) / RP_OBS_TOTAL))
  A[[nm]]$rot <- sl_amp(rot); A[[nm]]$obsq <- sl_amp(obsq)
}
cat("\n  ⚠ THE FIRST ROW IS THE CONTROL. 27q's JOINT_hi had ALREADY rotated its\n")
cat("    ocean limb by refitting, so its `as measured` and `ocn ROTATED` columns\n")
cat("    must nearly agree; if they do not, this arithmetic is not reproducing\n")
cat("    what the refit did and the new rows inherit that.\n")

sep("5. SCORED")
jh <- paste(RP_OLD_LAB, "JOINT_hi")
cat(sprintf("  %s's overshoot, as it stood: total %.3f = %.1f %% of obs %.3f\n",
            jh, S[[jh]]$total[["amp"]], 100 * S[[jh]]$total[["amp"]] / RP_OBS_TOTAL,
            RP_OBS_TOTAL))
cat(sprintf("  its rotation self-check: measured %.3f vs arithmetic %.3f (%+.3f)\n",
            S[[jh]]$total[["amp"]], A[[jh]]$rot, A[[jh]]$rot - S[[jh]]$total[["amp"]]))
cat("\n  the same arithmetic at the 25-parameter mode:\n")
for (nm in names(RP_NEW_REPS))
  cat(sprintf("    %-10s land %.3fx obs, ocean %.3fx | put the ocean at OBSERVED and the\n                 total becomes %.3f = %.1f %% of obs (27q: %.1f %%)\n",
              nm, S[[nm]]$dec$SH_land[["amp"]] / RP_OBS_LAND,
              S[[nm]]$dec$SH_ocean[["amp"]] / RP_OBS_OCEAN, A[[nm]]$obsq,
              100 * A[[nm]]$obsq / RP_OBS_TOTAL, 100 * A[[jh]]$obsq / RP_OBS_TOTAL))
cat("\n  ⛔ NOTHING HERE IS AN ADOPTION AND NOTHING HERE IS 27q's P1. The interaction\n")
cat("     statistic needs six REFITTED arms; this file refits none. What it says is\n")
cat("     whether the ARITHMETIC the verdict rested on still gives the same answer.\n")

sep("6. WHICH MOVE DID IT -- A ONE-AT-A-TIME WALK ON THE SH-LAND LIMB")
cat(sprintf("  %s -> %s, one parameter group at a time, each from the FROM vector.\n",
            RP_WALK_FROM, RP_WALK_TO))
cat("  ⚠ ONE-AT-A-TIME IS NOT A DECOMPOSITION. The two vectors sit in different\n")
cat("    basins and the parameters interact; the sum of the singles is printed\n")
cat("    against the ACTUAL end-to-end move, and the gap between them is the\n")
cat("    interaction this device cannot see. Read the ORDERING, not the shares.\n")
wf <- V[[RP_WALK_FROM]]; wt <- V[[RP_WALK_TO]]
# every name that differs, grouped
wnames <- union(names(wf$pv), names(wt$pv))
grp <- setNames(as.list(wnames), wnames)
for (g in names(RP_WALK_GROUPS)) {
  mem <- intersect(RP_WALK_GROUPS[[g]], wnames)
  if (length(mem)) { grp[mem] <- NULL; grp[[g]] <- mem }
}
# the legacy scalar a group replaces travels WITH the group, or the step
# half-moves and the walk silently measures a state neither vector is in
grp$seas_lag_p <- union(grp$seas_lag_p, intersect("seas_lag_p", wnames))
grp$gamma_enso <- union(grp$gamma_enso, intersect("gamma_enso", wnames))
base_land <- S[[RP_WALK_FROM]]$dec$SH_land[["amp"]]
end_land  <- S[[RP_WALK_TO]]$dec$SH_land[["amp"]]
steps <- list()
for (g in names(grp)) {
  mem <- grp[[g]]
  same <- all(vapply(mem, function(n) isTRUE(all.equal(wf$pv[[n]], wt$pv[[n]])), TRUE))
  if (same) next
  pv <- wf$pv
  for (n in mem) pv[[n]] <- wt$pv[[n]]
  # a name the TO vector has and the FROM one does not is an ADDED coordinate;
  # one the FROM has and TO does not is a RETIRED one and must be dropped, not
  # left behind to be picked up by a precedence rule
  for (n in mem) if (is.null(wt$pv[[n]])) pv[[n]] <- NULL
  sc <- sl_score(pv, wf$ent, wf$pump, obs, obsv, RP_YEARS)
  steps[[g]] <- c(land = sc$dec$SH_land[["amp"]] - base_land,
                  total = sc$total[["amp"]] - S[[RP_WALK_FROM]]$total[["amp"]])
}
ord <- names(steps)[order(-abs(vapply(steps, function(x) x[["land"]], 0)))]
cat(sprintf("\n  %-14s %12s %12s | %10s %10s\n", "parameter", "from", "to",
            "d SH-land", "d total"))
for (g in ord) {
  if (abs(steps[[g]][["land"]]) < RP_WALK_MIN) next
  # show the member each vector ACTUALLY carries -- a split group's FROM value
  # lives under the retired name and printing "--" for it would hide the move
  fv <- wf$pv[[Find(function(n) !is.null(wf$pv[[n]]), grp[[g]])]]
  tv <- wt$pv[[Find(function(n) !is.null(wt$pv[[n]]), grp[[g]])]]
  cat(sprintf("  %-14s %12s %12s | %+10.4f %+10.4f\n", g,
              if (is.null(fv)) "--" else sprintf("%.4g", fv),
              if (is.null(tv)) "--" else sprintf("%.4g", tv),
              steps[[g]][["land"]], steps[[g]][["total"]]))
}
ssum <- sum(vapply(steps, function(x) x[["land"]], 0))
cat(sprintf("\n  sum of ALL %d singles %+8.4f   vs the ACTUAL move %+8.4f   interaction %+8.4f\n",
            length(steps), ssum, end_land - base_land, end_land - base_land - ssum))
cat(sprintf("  SH-land limb: %.3f -> %.3f ppm  (obs land %.3f)\n",
            base_land, end_land, RP_OBS_LAND))

# ⭐ QUANTITATIVE PRE-CHECK on the dominant step, before it is believed.
# `npp_frac_NH` is the NH share of global NPP, so the SH land limb should scale
# with the SH share (1 - npp_frac_NH) to first order -- everything else held.
# If the measured step is far from that, the step is doing something other than
# moving productivity across the equator and the reading is wrong.
fN <- wf$pv$npp_frac_NH; tN <- wt$pv$npp_frac_NH
pred <- base_land * (1 - tN) / (1 - fN)
meas <- base_land + steps$npp_frac_NH[["land"]]
cat(sprintf("\n  pre-check on the dominant step: SH NPP share %.4f -> %.4f (x%.4f)\n",
            1 - fN, 1 - tN, (1 - tN) / (1 - fN)))
cat(sprintf("  a pure share rescaling predicts SH-land %.3f; measured %.3f (%+.1f %%)\n",
            pred, meas, 100 * (meas - pred) / pred))
cat(sprintf("  ⇒ the step %s a productivity shift across the equator.\n",
            if (abs(meas - pred) / pred < 0.10) "IS, to within 10 %," else
              "is NOT simply"))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(vectors = lapply(V, function(v) v[c("src", "ent", "pump")]),
             scores = S, arith = A, obs = list(total = obs_total_v, ocean = obs_ocn_v,
                                               land = obs_land_v),
             walk = list(from = RP_WALK_FROM, to = RP_WALK_TO, steps = steps,
                         base_land = base_land, end_land = end_land),
             # PROVENANCE: which air-sea alpha model produced these numbers.
             alpha_as_tdep = ccx_prepare(ccx_default_params())$alpha_as_tdep,
             control = SC, gates = list(O = GO, R = GR, R_ctrl = GRC),
             gdiff_preadopt = RP_GDIFF_PREADOPT, tol = c(repro = RP_REPRO_TOL, obs = RP_OBS_TOL)),
        file.path(OUTDIR, "2x2_repriced_at_enso25.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "2x2_repriced_at_enso25.rds")))
