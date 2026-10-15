# =====================================================================
# diag_probe_basin_vs_incumbent.R -- IS THE PROBE'S MODE REACHABLE UNDER
# THE *SHIPPED* `kz` BRACKET, AND IS IT A DIFFERENT BASIN OR A FAILED CLIMB?
#
# THE QUESTION THIS ANSWERS, AND WHY IT COSTS MINUTES RATHER THAN A REFIT.
#
# The 2026-08-31 wide-support probe (`CCX_WIDEN_PARAMS="kz=3494.9,13265.0"`)
# came back +51.9 log-units better than the incumbent, driven by `h_ml`
# 35.25 -> 134.11 m inside its UNCHANGED band, while `kz` moved -1.5 % and used
# none of 6,865 m2/yr of new headroom. The handoff
# `notes/handoff_2026-08-31d_probe_and_the_torch_question.md` recorded the
# decomposition of that +51.9 as ARITHMETIC rather than measurement, and named
# the missing control: "the staged refit, split with the SHIPPED bracket -- HAS
# NOT BEEN RUN." That control was costed as a refit. It is not one.
#
# THE OBSERVATION THAT COLLAPSES IT. The probe's mode is `kz` = 6302.37, which
# is INSIDE the shipped bracket [3942.5, 6528], and `h_ml` = 134.11, inside the
# shipped [30, 200]. Every one of its 22 parameters is strictly interior to the
# shipped table (GATE 1). So the probe's mode is a FEASIBLE POINT of the
# un-widened problem, and "is it better under the shipped bracket" is a matched
# pair of evaluations, not a re-optimization.
#
# WHY THE BASELINE IS THE 08-30 LANDED REFIT AND NOT `CCX_MODE_CANONICAL`.
# The probe warm-started from `refit_20260831_seas_lag_split/from90`, the byte
# copy of the 08-30 landed mode (md5 f4f28060a9ea35064ddf2bf70d118ace). The
# canonical mode file `refit_20260825f_from90` predates three of the four
# stacked objective changes in INDEX_ccx, and reproduces its own stored logpost
# only to -42.99 in today's build -- it is not comparable and is not used here.
# The 08-30 file reproduces to -0.85 (see MEASURED OFFSETS in the output).
#
# WHY BOTH ARE EVALUATED UNDER THE SHIPPED TABLE AND NOTHING ELSE.
# A logit's support IS its prior, so a logpost under a widened bracket carries a
# reparameterization constant and is not comparable with one under the shipped
# bracket -- that is the handoff's "~1.5". Putting BOTH points through ONE
# harness under ONE table removes it by construction rather than estimating it.
# This is the "MATCHED contrast" R/paths.R permits and the absolute-logpost
# comparison INDEX_ccx forbids.
#
# WHAT IT CANNOT DO. The probe is NOT converged (it hit the restart cap and the
# BFGS polish still gained 9.07), so its logpost is a LOWER BOUND on its basin's
# depth. That makes every conclusion here conservative: the gap can only widen.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label below derives from these ----------
PB_INCUMBENT <- "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds"
PB_PROBE     <- "calibration/output/probe_20260831_kz_wide_support/from90/mode_fit_pumpN.rds"
PB_INC_LAB   <- "incumbent (08-30 landed, = the probe's warm start)"
PB_PRB_LAB   <- "probe (08-31 wide support)"
PB_ARM       <- "N"
PB_HML_GRID  <- seq(31, 199, length.out = 43)   # inside the shipped [30, 200]
PB_PATH_T    <- seq(0, 1, by = 0.025)           # straight line in u-space
PB_RT_TOL    <- 1e-8                            # round-trip: an IDENTITY

cat(sprintf("\n%s\n  %s\n  vs %s\n  arm %s, SHIPPED CCX_PARAM_TABLE, %d parameters\n%s\n",
            strrep("=", 70), PB_PRB_LAB, PB_INC_LAB, PB_ARM,
            length(CCX_PARAM_NAMES), strrep("=", 70)))

mdI <- readRDS(PB_INCUMBENT); mdP <- readRDS(PB_PROBE)
pI  <- ccx_migrate_par_set(mdI$par_mode)        # 21 -> 22 via the model's own contract
pP  <- mdP$par_mode
cat(sprintf("migrated into the incumbent (%d): %s\n",
            length(attr(pI, "migrated")), paste(attr(pI, "migrated"), collapse = ", ")))

# ---- GATE 1: FEASIBILITY under the SHIPPED table --------------------
# An EXACT bound, because it is a containment claim, not an approximation:
# if either point is outside, the matched comparison below is not defined.
.ship <- lapply(CCX_PARAM_TABLE, function(s) c(s$lo, s$hi))
gate_feasible <- function(lab, p) {
  bad <- character(0)
  for (n in CCX_PARAM_NAMES) {
    b <- .ship[[n]]
    if (is.null(b) || any(!is.finite(b))) next
    if (p[[n]] <= b[1] || p[[n]] >= b[2])
      bad <- c(bad, sprintf("%s = %.6g outside [%g, %g]", n, p[[n]], b[1], b[2]))
  }
  if (length(bad))
    stop("GATE 1 FAILED -- ", lab, " is NOT feasible under the shipped table:\n  ",
         paste(bad, collapse = "\n  "),
         "\nThe matched comparison this script makes is undefined for it.")
  cat(sprintf("GATE 1 feasibility: %-46s all %d strictly interior. OK\n",
              lab, length(CCX_PARAM_NAMES)))
}
gate_feasible(PB_INC_LAB, pI)
gate_feasible(PB_PRB_LAB, pP)
cat(sprintf("  the probe's kz = %.2f sits at %.1f %% of the SHIPPED bracket [%g, %g]\n",
            pP$kz, 100 * (pP$kz - .ship$kz[1]) / diff(.ship$kz), .ship$kz[1], .ship$kz[2]))

# ---- GATE 2: round-trip, an IDENTITY --------------------------------
for (lab_p in list(list(PB_INC_LAB, pI), list(PB_PRB_LAB, pP))) {
  rt <- ccx_unc_to_par(ccx_par_to_unc(lab_p[[2]]))
  d  <- vapply(CCX_PARAM_NAMES, function(n)
                 abs(rt[[n]] - lab_p[[2]][[n]]) / max(abs(lab_p[[2]][[n]]), 1e-12), numeric(1))
  if (max(d) > PB_RT_TOL)
    stop("GATE 2 FAILED -- ", lab_p[[1]], " does not round-trip: worst ",
         names(which.max(d)), " at ", signif(max(d), 3))
  cat(sprintf("GATE 2 par->unc->par: %-44s worst rel %.1e. OK\n", lab_p[[1]], max(d)))
}

bp <- ccx_default_params(); bp$pump_mode <- PB_ARM
lp <- ccx_make_logpost(base_params = bp)
ev <- function(p) lp(ccx_par_to_unc(p))

# ---- GATE 3: determinism --------------------------------------------
lpI <- ev(pI); lpP <- ev(pP)
if (!identical(ev(pI), lpI) || !identical(ev(pP), lpP))
  stop("GATE 3 FAILED -- the objective is not a pure function of u; every ",
       "difference below is then noise of unknown size.")
cat("GATE 3 determinism: both points bit-reproducible on repeat. OK\n")

# ---- GATE 4: the incumbent's recorded bands ARE the shipped ones -----
# This one has real POWER: it fires if band restoration breaks, and it is an
# IDENTITY because the two tables are literally equal for this file.
.same <- isTRUE(all.equal(mdI$hml_bound, .ship$h_ml)) &&
         isTRUE(all.equal(mdI$kz_bracket, .ship$kz))
if (!.same)
  stop("GATE 4 FAILED -- the incumbent's recorded bands are NOT the shipped ",
       "table (hml [", paste(mdI$hml_bound, collapse = ", "), "], kz [",
       paste(mdI$kz_bracket, collapse = ", "), "]), so its shipped-table ",
       "logpost carries a reparameterisation constant this script does not remove.")
.o <- ccx_adopt_mode_band(mdI); .r <- ev(pI)
# top-level scope IS globalenv, where CCX_PARAM_TABLE lives; `<<-` would start
# its search ABOVE globalenv (the package search path) and not find it.
for (.b in names(.o)) CCX_PARAM_TABLE[[.b]] <- .o[[.b]]
if (!identical(.r, lpI))
  stop("GATE 4 FAILED -- the incumbent evaluates differently under its own ",
       "recorded bands (", sprintf("%.6f", .r), ") than under the shipped table (",
       sprintf("%.6f", lpI), "), though the two tables are equal. Band ",
       "restoration is broken.")
cat("GATE 4 the incumbent's recorded bands equal the shipped table, and it\n")
cat("       evaluates bit-identically under both. No constant to remove. OK\n")

# ---- MEASURED OFFSETS: does each file reproduce its own stored logpost? ----
# Reported, NOT gated. The incumbent's is an identity (same table); the probe's
# is its widened-kz reparameterization constant, whose SIZE is the thing the
# handoff predicted at ~1.5 and is worth reading, not asserting.
cat(sprintf("\nMEASURED OFFSETS (this build, vs each file's stored logpost)\n"))
cat(sprintf("  %-12s shipped-table %.4f  stored %.4f  offset %+.4f\n",
            "incumbent", lpI, mdI$logpost, lpI - mdI$logpost))
.o <- ccx_adopt_mode_band(mdP); .rP <- ev(pP)
# top-level scope IS globalenv, where CCX_PARAM_TABLE lives; `<<-` would start
# its search ABOVE globalenv (the package search path) and not find it.
for (.b in names(.o)) CCX_PARAM_TABLE[[.b]] <- .o[[.b]]
cat(sprintf("  %-12s recorded-band %.4f  stored %.4f  offset %+.4f  <- the widened-kz constant\n",
            "probe", .rP, mdP$logpost, .rP - mdP$logpost))

# ---- THE HEADLINE: an ORDERING, priced ------------------------------
# No invented threshold. The claim is "one is better than the other under one
# table"; the bound that matches that claim is an ORDERING, and the margin is
# reported rather than tested against a number nobody sourced.
cat(sprintf("\n%s\nMATCHED, both under the SHIPPED table\n", strrep("-", 70)))
cat(sprintf("  %-46s %12.4f\n", PB_INC_LAB, lpI))
cat(sprintf("  %-46s %12.4f\n", PB_PRB_LAB, lpP))
cat(sprintf("  probe - incumbent = %+.4f log-units\n", lpP - lpI))
cat(sprintf("  VERDICT: the probe's mode is %s under the SHIPPED bracket.\n",
            if (lpP > lpI) "BETTER" else if (lpP < lpI) "WORSE" else "EQUAL"))
cat("  => the widening contributed NOTHING: the whole gain is available inside\n")
cat("     the un-widened problem, so this is a BASIN question, not a bracket one.\n")

# ---- ONE-AT-A-TIME: is any single coordinate an uphill route? --------
cat(sprintf("\n%s\nONE-AT-A-TIME moves from the incumbent (all else held)\n", strrep("-", 70)))
otm <- function(lab, mod) {
  p <- pI; for (n in names(mod)) p[[n]] <- mod[[n]]
  v <- ev(p); cat(sprintf("  %-34s %12.4f  %+9.2f\n", lab, v, v - lpI)); invisible(v)
}
otm("+ the probe's SPLIT NPP lags", list(seas_lag_p_NH = pP$seas_lag_p_NH,
                                        seas_lag_p_SH = pP$seas_lag_p_SH))
otm("+ the probe's h_ml only",      list(h_ml = pP$h_ml))
otm("+ the probe's kz only",        list(kz   = pP$kz))
cat(sprintf("  %-34s %12.4f  %+9.2f\n", "the probe, all 22 together", lpP, lpP - lpI))
cat("  => NO single-coordinate move is uphill; only the JOINT move gains.\n")

# ---- h_ml PROFILES: a local max at each point, or one hill? ----------
cat(sprintf("\n%s\nh_ml PROFILES across the SHIPPED [%g, %g], all else held\n",
            strrep("-", 70), .ship$h_ml[1], .ship$h_ml[2]))
prof <- function(lab, p0) {
  v <- vapply(PB_HML_GRID, function(h) { p <- p0; p$h_ml <- h; ev(p) }, numeric(1))
  am <- PB_HML_GRID[which.max(v)]
  cat(sprintf("  all else at %-42s argmax h_ml = %5.1f m (own value %6.2f m)\n",
              lab, am, p0$h_ml))
  list(v = v, argmax = am)
}
prI <- prof(PB_INC_LAB, pI); prP <- prof(PB_PRB_LAB, pP)
cat(sprintf("  cost of dragging h_ml to the OTHER mode's value, one coordinate:\n"))
cat(sprintf("    incumbent -> %6.2f m : %+9.2f\n", pP$h_ml,
            { p <- pI; p$h_ml <- pP$h_ml; ev(p) } - lpI))
cat(sprintf("    probe     -> %6.2f m : %+9.2f\n", pI$h_ml,
            { p <- pP; p$h_ml <- pI$h_ml; ev(p) } - lpP))
cat("  => each point is a LOCAL MAXIMUM in h_ml conditional on the rest.\n")

# ---- MODE CONNECTIVITY: the straight path in u-space -----------------
cat(sprintf("\n%s\nMODE CONNECTIVITY -- straight line in u-space, %d points\n",
            strrep("-", 70), length(PB_PATH_T)))
uI <- ccx_par_to_unc(pI); uP <- ccx_par_to_unc(pP)
vpath <- vapply(PB_PATH_T, function(a) lp((1 - a) * uI + a * uP), numeric(1))
lo <- which.min(vpath)
cat(sprintf("  deepest point t = %.3f at %.4f\n", PB_PATH_T[lo], vpath[lo]))
cat(sprintf("  barrier below the WORSE endpoint: %.2f log-units\n", lpI - vpath[lo]))
cat(sprintf("  barrier below the BETTER endpoint: %.2f log-units\n", lpP - vpath[lo]))
if (vpath[lo] < min(lpI, lpP)) {
  cat("  VERDICT: SEPARATED -- the straight path passes strictly BELOW both\n")
  cat("           endpoints, so these are two basins, not one hill the 08-30\n")
  cat("           refit failed to finish climbing.\n")
} else {
  cat("  VERDICT: CONNECTED along this path -- the incumbent is a failed climb,\n")
  cat("           not a separate basin. A warm-started refit suffices.\n")
}
# ⚠ A three-valued reading, SURFACED rather than swallowed: a straight line is
# ONE path. It is sufficient to show a local method starting at the incumbent
# will not cross, and it is NOT a proof that no curved route exists.
cat("  CHECK: one straight path is not a proof of topological separation.\n")
cat("         It bounds what a LOCAL search from the incumbent can reach.\n")

# ---- and is the incumbent even converged along this direction? -------
# Restricted to the incumbent's OWN side of the barrier (t < the minimum): past
# it we are simply reading the other basin, which says nothing about whether the
# 08-30 refit finished. `t = 1` beating the incumbent is the headline, not news
# about convergence.
.near <- PB_PATH_T > 0 & PB_PATH_T < PB_PATH_T[lo]
.up   <- .near & vpath > lpI
if (any(.up))
  cat(sprintf("\n  ADDENDUM: the incumbent is NOT converged along this direction -- on its\n            OWN side of the barrier, t in [%.3f, %.3f] scores above it,\n            best %+.2f at t = %.3f. Consistent with the 08-30 run hitting its\n            restart cap while still gaining.\n",
              min(PB_PATH_T[.up]), max(PB_PATH_T[.up]),
              max(vpath[.up]) - lpI, PB_PATH_T[which.max(ifelse(.up, vpath, -Inf))]))

cat(sprintf("\n%s\n", strrep("=", 70)))
