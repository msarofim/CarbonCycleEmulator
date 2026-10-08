# =====================================================================
# diag_constraint_map.R -- WHICH PART OF THE MODEL IS HOLDING WHICH
# OBSERVATION? Builds the constraint map the app's "What pins down what?"
# tab draws (Marcus, 2026-09-25).
#
# THE QUESTION. The app can already show that the model matches CO2, d13C,
# d14C, the seasonal cycle, the ocean interior and GCB's sinks. It cannot
# yet show WHY -- which of the model's parts each of those agreements is
# actually testing. That is a statement about LEVERAGE (d logL / d theta),
# not about a stream's logL LEVEL: a stream sitting at a large negative
# level may be pinning nothing, and a stream at a small level may be the
# only thing holding a parameter.
#
# ⛔⛔ THREE METHODOLOGICAL CHOICES, RULED BY MARCUS 2026-09-25, each of
# which changes what the numbers mean. They are named here and in the app's
# own caption, never left implicit.
#   CM1  EVALUATED AT THE CANONICAL MODE, through the SHIPPED objective and
#        its PERIODIC spinup -- not at ccx_default_params(). So the map
#        answers "what is holding THIS FIT in place", and every number is
#        comparable with every current gate. ⚠ The older
#        calibration/diag_stream_leverage.R answered the other question
#        (leverage at the table defaults) and is NOT comparable: it predates
#        the periodic spinup and still names the 21-era parameters.
#   CM2  STEP = ONE CONDITIONAL HESSIAN SD, `1/sqrt(diag(-H))`, in the
#        UNCONSTRAINED coordinates, symmetric. ⚠ It is a LAPLACE sd from the
#        Hessian at the mode, NOT a sampled posterior sd -- there is no sampled
#        posterior (ruling D1). Called "Hessian sd" everywhere.
#        ⛔⛔ MARCUS RULED "one posterior sd" AND THE MARGINAL SD WAS MEASURED
#        AND REJECTED (2026-09-25). The marginal sd -- `md$sd_unc`, i.e.
#        `sqrt(diag(cov))` -- already contains the COMPENSATION the other 28
#        parameters supply, so moving ONE parameter that far ON ITS OWN leaves
#        the bowl entirely. Measured: marginal / conditional is median 3.3 and
#        reaches 92 (`fert_k` 0.5422 vs 0.0059, `beta_max` 0.4610 vs 0.0055),
#        the quadratic's own predicted drop at one marginal sd is median 5.3
#        log-units and up to 4235, and the first build flagged 22 of 29 names
#        as outside the quadratic regime. The conditional sd is instead an
#        EQUAL-DIFFICULTY step: the quadratic drop is 0.5 log-units for every
#        name by construction, so a row of the map compares like with like.
#        ⭐ AND THE REJECTED STEP IS ITSELF A RESULT, kept and reported: the
#        marginal/conditional RATIO is how much freer a parameter is WITH the
#        others compensating than alone, i.e. what the data pin as a
#        COMBINATION rather than individually. `CM_STEP_KIND` switches back.
#   CM3  AGGREGATION IS A SUM OF THE PER-PARAMETER MAP, over named groups.
#        Exact by construction and gated as an identity, but the GROUPING
#        itself is a judgment: it is CM_COMPONENT / CM_FAMILY below, and it
#        is printed so a reader can disagree with it.
#
# ⚠ WHAT THIS IS NOT. It is not a Hessian and not a covariance: it is a
# symmetric finite difference of the LEVEL of each stream. A stream already
# at its own optimum in a direction shows a small number there BY
# CONSTRUCTION, which is the correct reading (it is not being pulled) and
# also the reason the signed halves are kept rather than only the maximum.
#
# Usage:
#   Rscript calibration/diag_constraint_map.R            # build + gates + report
#   Rscript calibration/diag_constraint_map.R gates      # gates only, no write
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- NAMED CONSTANTS: every label, filename and threshold derives from here ----
CM_TAG        <- "constraint_map"
CM_DATE       <- "20261008e"  # the SHIPPED canonical artifact's tag: hilda29e at its adoption (10-08 e; built 10-08 h after Marcus's "Main fit only" ruling; was 20261006a = hilda33p, 20261003h = hilda34g, 20261001k = hilda33d after the 10-01 (k) flip, 20261001 for that adoption build, 20260925 at hilda29l); see CM4. ⚠ MOVE IT AT EVERY ADOPTION: the canonical's log is named by it, so a stale tag overwrites the previous canonical's record (it did, 10-03, and was restored from git)
# ⛔⛔ CM4  THE ARM (2026-09-26). The map used to be canonical-only. A SECOND
#       evaluation point answers a question one point cannot: is the pins/pulls
#       picture a property of the MODEL, or only of THIS FIT?
#       ⚠ A second arm is only like-for-like if it differs in the FIT and NOT in
#       the STRUCTURE. Measured 09-26:
#         hilda32f  seas_ml 1, periodic, names a clean SUPERSET of the canonical's
#                   29 (adds the 3 the canonical PINS) -> the 29 shared names are
#                   directly comparable. THE LIKE-FOR-LIKE ARM.
#         hilda31pe seas_ml **0** -- a different STRUCTURE -- and NOT a superset:
#                   it lacks `w_enso_l2` (28/29 shared). A difference between its
#                   map and the canonical's cannot be attributed to the fit rather
#                   than the structure. It is the seas_ml ON/OFF control and
#                   licenses THAT comparison only
#                   ([[iso_deep_control_licenses_one_comparison]]).
#       ⭐ The step is one CONDITIONAL Hessian sd, an EQUAL-DIFFICULTY step
#       (quadratic drop 0.5 log-units for every name BY CONSTRUCTION), which is
#       what makes a cross-arm comparison of leverage meaningful at all.
#   Usage:  Rscript calibration/diag_constraint_map.R mode=hilda32f
CM_MODE <- local({
  a <- grep("^mode=", commandArgs(trailingOnly = TRUE), value = TRUE)
  if (length(a)) sub("^mode=", "", a[[1]]) else CCX_MODE_CANONICAL
})
CM_IS_CANONICAL <- identical(CM_MODE, CCX_MODE_CANONICAL)
# ⛔ ONLY the canonical arm writes the file the APP reads. A control arm must never
# be able to land in `data/constraint_map.rds` -- a second evaluation point that
# overwrites the shipped one would silently re-point the app's whole tab.
CM_SUFFIX <- if (CM_IS_CANONICAL) "" else paste0("_", CM_MODE)
CM_STEP_SD    <- 1.0          # CM2: the step, in Hessian sds (unconstrained space)
# "conditional" = 1/sqrt(diag(-H)), the equal-difficulty step this map uses.
# "marginal" = sqrt(diag(cov)) = md$sd_unc, measured and rejected -- see CM2.
CM_STEP_KIND  <- "conditional"
CM_STEP_LABEL <- sprintf("%.2f %s Hessian sd (unconstrained), symmetric", CM_STEP_SD, CM_STEP_KIND)
# A step should cost about the quadratic's own prediction. Flag where the
# MEASURED drop exceeds it by this factor -- the coordinate is then nonlinear on
# the scale of its own uncertainty, which is a finding, not a failure.
CM_NONLIN_FLAG<- 5.0
CM_OUT        <- if (CM_IS_CANONICAL) file.path("data", sprintf("%s.rds", CM_TAG)) else
                 file.path("outputs", "diagnostics", sprintf("%s%s.rds", CM_TAG, CM_SUFFIX))
# A control arm's log carries the date it was actually RUN, not the shipped arm's.
CM_LOG        <- file.path("outputs", "diagnostics",
                           sprintf("%s_%s%s.log", CM_TAG,
                                   if (CM_IS_CANONICAL) CM_DATE else format(Sys.Date(), "%Y%m%d"),
                                   CM_SUFFIX))
# PROVENANCE STAMP (2026-10-01 f): the commit, in the log header, the closing `provenance:` line
# and the artifact's `provenance$commit`. On 2026-10-01 a diagnostic run on an uncommitted tree
# stamped its parent commit. The stamp's forms (<hash>, +dirty, +dirty?, +frozen?, ?) and why it is
# not the bare system("git ...") idiom: R/provenance.R, where this driver's 10-01 (f) block now
# lives as ccx_git_stamp() (10-01 h).
# ⚠ CM_OUT IS EXCLUDED: it is this script's own OUTPUT, never an input, so a second build before
# the first is committed would otherwise stamp ITSELF dirty ([[gate_reads_its_own_output]]).
CM_DRIVER     <- "calibration/diag_constraint_map.R"
CM_COMMIT     <- ccx_git_stamp(exclude = CM_OUT)
# printed by the log's closing line AND stored in the artifact, so the two cannot disagree
CM_UNITS      <- "log-likelihood units per stream"
CM_SEED_NOTE  <- "deterministic: no RNG is used"
CM_HARNESS_TOL<- 1e-3         # the rebuilt objective must reproduce the stored logpost
CM_CLOSE_TOL  <- 1e-9         # sum over streams must equal the total loglik
# CURVATURE FRACTION, in [0, 1]: |dhi + dlo| / (|dhi| + |dlo|).
#   -> 1  both half-steps move the stream the SAME way (a symmetric well or
#         ridge): the stream is AT its own optimum in this direction, so it is
#         PINNING the parameter.
#   -> 0  the halves move it in OPPOSITE directions (a clean slope): the stream
#         would prefer the parameter somewhere else, so it is PULLING on it.
# ⚠ THIS REPLACED AN "ASYMMETRY FLAG" (2026-09-25) which used max|d| as the
# denominator and therefore fired at ratio ~2 in exactly the well-behaved case --
# a stream sitting in a symmetric well. It flagged 11 of 29 names as suspect when
# what it had found was curvature, i.e. the thing the map is FOR. A statistic that
# cannot separate the healthy case from the defect is not a gate; the regime check
# is CM_NONLIN_FLAG on the measured-vs-predicted drop, which passes 29/29.
CM_PIN_CUT    <- 0.5          # curvature fraction above which we call it "pins"

# CM3: the grouping. A judgment, printed so a reader can disagree with it.
# ⚠ EVERY fitted name must appear exactly once -- gated below, so a parameter
# added to the table cannot fall out of the map silently.
# ⚠ 09-26: this is now the UNION over REGISTERED ARMS, intersected down to the arm
# actually being mapped (CM4). The per-arm COVER gate below stays exactly as strict
# -- every fitted name of THIS arm exactly once -- and a SECOND gate requires every
# union entry absent from this arm to be a name some other registered arm really
# has. So a MISSPELLED or retired name cannot hide in the union, which is the
# failure mode that widening a coverage table normally introduces
# ([[retiring_an_arm_unlints_its_path]]: "is it covered?" and "does it still
# EXIST?" are two questions and need two tests).
CM_COMPONENT_ALL <- list(
  # + N retention and greening (D2; the gated names fitted from hilda33d, 2026-10-01)
  "Land uptake"            = c("beta_max", "fert_k", "q10", "ndep_ret", "npp_tsens"),
  "Air-sea gas exchange"   = c("k_w"),
  "Mixed layer & vertical mixing" = c("h_ml", "kz", "kz_deep_frac", "tau_ex"),
  "High-latitude structure"= c("hs_asx_frac", "h_hs", "u_hs"),
  "Biological pump"        = c("pump_hs_gcm2", "pump_grad"),
  "Seasonal cycle"         = c("npp_frac_NH", "seas_T_amp_NH", "seas_T_amp_SH",
                               "seas_lag_p_NH", "seas_lag_p_SH",
                               "sst_seas_amp_NH", "sst_seas_amp_SH",
                               "ent_seas_amp_SH"),
  # + the land ENSO lag (DESIGN's L_MEI; the lag label, fitted from hilda34g, 2026-10-03)
  "ENSO response"          = c("w_enso_l2", "gamma_enso_land_NH", "gamma_enso_land_SH",
                               "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "lag_enso_land"),
  # + the GCB-imbalance shares (D3, objective #14; from hilda33d, 2026-10-01): a target choice
  "Input scalings & reporting" = c("bomb_total", "luc_scale", "sigma_d14c",
                                   "rep_dC", "grad_off_co2", "grad_off_d13c",
                                   "imb_share_land", "imb_share_ocean_rest")
)
# Names that a REGISTERED arm other than this one carries. Listed explicitly, by
# hand, so the union cannot quietly absorb a typo. Gated below (GATE UNION).
CM_ARM_ONLY_NAMES <- c("w_enso_l2",                                  # canonical / hilda32f
                       "ent_seas_amp_SH",                            # hilda32f / hilda31pe
                       "gamma_enso_ocn_NH", "gamma_enso_ocn_SH",     # hilda32f / hilda31pe
                       # the GATED names: only an arm whose structure opens the gate fits them
                       # (the canonical hilda33d, 2026-10-01). npp_tsens is fitted by hilda33d / hilda34g
                       # and PINNED at 0 by the canonical hilda33p (objective #16, 2026-10-06)
                       "ndep_ret", "npp_tsens", "imb_share_land", "imb_share_ocean_rest",
                       # the LAG gate's name: only the lag label fits it (the canonical hilda34g, 2026-10-03)
                       "lag_enso_land",
                       # the interannual CUT's module (objectives #17 / #18; the canonical hilda29e, 2026-10-08): fitted
                       # by hilda33p and every earlier canonical, HELD at stage 1's values at a cut arm. With
                       # w_enso_l2 and lag_enso_land above, that is all of CCX_IAV_MODULE_NAMES (GATE MODULE).
                       "gamma_enso_land_NH", "gamma_enso_land_SH")

# The observation families. ⚠ Same rule: every stream exactly once, gated.
# ⚠ 2026-10-08 (h): like the components, this is now the UNION over registered arms (CM_FAMILY_ALL), restricted
# below to the streams THIS arm's objective has (CM_FAMILY). The cut (iav_cut 1) moved `gcb_ocean_enso_slope` out
# of the main objective into the stage-1 module, so at hilda29e its family is empty. COVER stays per-arm and
# strict; GATE UNION now also requires every union stream absent from this arm to be in CM_ARM_ONLY_STREAMS.
# ⚠ THESE STRINGS ARE READER-FACING: they are the app's own axis labels and
# the subject of its computed prose, so they are typeset here rather than
# mapped to pretty names in the app. A second naming table in `global.R` is
# exactly the caption-sync bug class this project keeps hitting.
CM_FAMILY_ALL <- list(
  "CO₂ level"                 = c("co2_level_MLO", "co2_level_SPO"),
  "CO₂ seasonal cycle"        = c("co2_seasonal_MLO", "co2_seasonal_SPO"),
  "CO₂ north–south gradient"  = c("co2_gradient"),
  "CO₂ in ice cores"           = c("co2_icecore"),
  # objective #15's Law Dome ice-core d13C row (2026-10-02 bb): its own family, parallel to the CO2 one
  "δ¹³C in ice cores"          = c("d13c_icecore"),
  "δ¹³C level & gradient"     = c("d13c_level_MLO", "d13c_level_SPO", "d13c_gradient"),
  "δ¹³C seasonal cycle"       = c("d13c_seasonal_MLO", "d13c_seasonal_SPO"),
  "Δ¹⁴C in the air (bomb)"    = c("d14c_NH", "d14c_SH"),
  "Δ¹⁴C in the air (pre-bomb)" = c("d14c_intcal"),
  "Δ¹⁴C in the ocean"         = c("excess_c14_ocean", "d14c_profile_level",
                               "d14c_profile_ab", "d14c_profile_bd"),
  "Ocean interior chemistry"    = c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk",
                                 "hs_surf_dic", "hs_surf_d13c"),
  "Measured land & ocean sinks" = c("gcb_ocean_sink", "gcb_land_sink"),
  "ENSO–sink covariance"       = c("gcb_ocean_enso_slope")
)
# Streams a REGISTERED arm other than this one scores in its MAIN objective. Listed by hand, like the names.
CM_ARM_ONLY_STREAMS <- c("gcb_ocean_enso_slope")   # hilda33p and earlier; the cut's stage-1 module at hilda29e

dir.create(dirname(CM_LOG), showWarnings = FALSE, recursive = TRUE)
cm_say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = CM_LOG, append = TRUE) }
# the closing line of every run's section of the log -- a gates-only run's too
cm_provenance <- function()
  cm_say("provenance: %s @%s; mode %s, spinup %s, struct %s; step %s; %s; %s\n",
         CM_DRIVER, CM_COMMIT, CM_MODE, ccx_mode_spinup(md), ccx_mode_struct(md),
         CM_STEP_LABEL, CM_UNITS, CM_SEED_NOTE)

# ---------------------------------------------------------------------
# The harness, mirroring diag_rep_dc_product_ladder.R's: pins applied, the
# file's own structure and spinup, `by_stream = TRUE`.
# ---------------------------------------------------------------------
md    <- readRDS(ccx_mode_file(CM_MODE))
pins  <- ccx_mode_pins(md)
rmp   <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rmp), add = TRUE)
bp    <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
for (n in names(pins)) bp[[n]] <- pins[[n]]
st    <- ccx_mode_start(md, CM_TAG)
spin  <- ccx_spinup_from_label(ccx_mode_spinup(md))
lp    <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spin)
u0    <- st$u
NAMES <- md$param_names
# CM4: the arm's own component table = the union restricted to this arm's names.
CM_COMPONENT <- Filter(length, lapply(CM_COMPONENT_ALL, function(v) intersect(v, NAMES)))
# ⚠ `md$hessian` is the Hessian of the LOG-posterior, so it is NEGATIVE
# definite and the precision matrix is its negation. Checked, not assumed:
# sqrt(diag(solve(-H))) reproduces the stored `md$sd_unc` exactly.
NEGH  <- -md$hessian
SD_MARG <- setNames(md$sd_unc, NAMES)
SD_COND <- setNames(1 / sqrt(diag(NEGH)), NAMES)
SD    <- switch(CM_STEP_KIND, conditional = SD_COND, marginal = SD_MARG,
                stop("CM_STEP_KIND must be \"conditional\" or \"marginal\""))
# the quadratic's own predicted drop at the chosen step, per name
DROP_PRED <- 0.5 * diag(NEGH) * (CM_STEP_SD * SD)^2

cm_streams <- function(u) {
  v  <- lp(u)
  st <- attr(v, "streams")
  list(streams = st, loglik = as.numeric(attr(v, "loglik")),
       logpost = as.numeric(v) - .Machine$double.xmax * 0)   # kept raw; shift applied by caller
}

# ---------------------------------------------------------------------
# GATES, before a single number is read.
# ---------------------------------------------------------------------
cm_gates <- function(b) {
  ok <- TRUE
  got <- as.numeric(lp(u0)) - st$logpost_shift
  p1 <- abs(got - md$logpost) < CM_HARNESS_TOL
  cm_say("=== GATE HARNESS === rebuilt %.4f (shift %+.4f) vs stored %.4f -> %s\n",
         got, st$logpost_shift, md$logpost, if (p1) "PASS" else "*** FAIL ***")
  ok <- ok && p1

  # CLOSURE: the by-stream decomposition must be COMPLETE, or every share below
  # is a share of the wrong denominator.
  d <- abs(sum(b$streams) - b$loglik)
  p2 <- d < CM_CLOSE_TOL
  cm_say("=== GATE CLOSURE === |sum(streams) - loglik| = %.3e (tol %.1e) -> %s\n",
         d, CM_CLOSE_TOL, if (p2) "PASS" else "*** FAIL ***")
  ok <- ok && p2

  # COVER: every fitted name in exactly one component, every stream in exactly
  # one family. Without this a name added to the table drops out of the map and
  # the aggregate quietly stops being the total.
  pc <- unlist(CM_COMPONENT, use.names = FALSE)
  fs <- unlist(CM_FAMILY,    use.names = FALSE)
  p3 <- setequal(pc, NAMES) && !anyDuplicated(pc)
  p4 <- setequal(fs, names(b$streams)) && !anyDuplicated(fs)
  cm_say("=== GATE COVER === %d names in %d components -> %s ; %d streams in %d families -> %s\n",
         length(pc), length(CM_COMPONENT), if (p3) "PASS" else "*** FAIL ***",
         length(fs), length(CM_FAMILY),    if (p4) "PASS" else "*** FAIL ***")
  if (!p3) cm_say("    name mismatch: only in table = %s ; only in CM_COMPONENT = %s\n",
                  paste(setdiff(NAMES, pc), collapse = ", "),
                  paste(setdiff(pc, NAMES), collapse = ", "))
  if (!p4) cm_say("    stream mismatch: only in objective = %s ; only in CM_FAMILY = %s\n",
                  paste(setdiff(names(b$streams), fs), collapse = ", "),
                  paste(setdiff(fs, names(b$streams)), collapse = ", "))
  ok <- ok && p3 && p4

  # UNION (09-26, CM4): the component table is a union over arms, so the per-arm
  # COVER gate above can no longer catch a name that is simply WRONG -- it would
  # just be intersected away. Require every union entry missing from THIS arm to be
  # a hand-declared name of another registered arm.
  stray <- setdiff(setdiff(unlist(CM_COMPONENT_ALL, use.names = FALSE), NAMES),
                   CM_ARM_ONLY_NAMES)
  p4b <- length(stray) == 0L
  cm_say("=== GATE UNION === union entries absent from this arm and NOT declared arm-only: %d -> %s%s\n",
         length(stray), if (p4b) "PASS" else "*** FAIL ***",
         if (length(stray)) paste0(" {", paste(stray, collapse = ", "), "}") else "")
  ok <- ok && p4b
  # ... and the same for STREAMS (2026-10-08 h): a union stream this arm does not score must be a declared one
  stray_s <- setdiff(setdiff(unlist(CM_FAMILY_ALL, use.names = FALSE), names(b$streams)), CM_ARM_ONLY_STREAMS)
  p4c <- length(stray_s) == 0L
  cm_say("=== GATE UNION (streams) === union streams absent from this arm and NOT declared arm-only: %d -> %s%s\n",
         length(stray_s), if (p4c) "PASS" else "*** FAIL ***",
         if (length(stray_s)) paste0(" {", paste(stray_s, collapse = ", "), "}") else "")
  ok <- ok && p4c

  # MODULE (2026-10-08 h, Marcus: "Main fit only"): at a CUT arm the app says the El Nino settings are fitted in a
  # separate step and are not on this map. That has to be TRUE of the arm: every module name held, none fitted,
  # and the rows the main objective lost are declared ones. At an arm without the cut there is nothing to say.
  # ⚠ The structure's flag is CROSS-CHECKED against the likelihood itself: the cut is exactly the arm whose main
  # objective has no `gcb_ocean_enso_slope` stream (ccx_enso_slope_row_on). Without this, a wrongly-unset flag
  # passed the gate trivially and dropped the caption in silence (mutation m4, 10-08 h).
  slope_in_main <- "gcb_ocean_enso_slope" %in% names(b$streams)
  p4d <- identical(CM_IAV_CUT, !slope_in_main) && (if (CM_IAV_CUT)
    setequal(CM_MODULE$names, CCX_IAV_MODULE_NAMES) && !length(intersect(CCX_IAV_MODULE_NAMES, NAMES)) &&
      length(CM_MODULE$rows) > 0L && all(CM_MODULE$rows %in% CM_ARM_ONLY_STREAMS) else is.null(CM_MODULE))
  cm_say("=== GATE MODULE === iav_cut %s, slope row in the main objective %s; held module names {%s}; rows scored by the module {%s} -> %s\n",
         CM_IAV_CUT, slope_in_main, paste(CM_MODULE$names, collapse = ", "), paste(CM_MODULE$rows, collapse = ", "),
         if (p4d) "PASS" else "*** FAIL ***")
  ok <- ok && p4d

  # SD: the step must exist and be usable for every name.
  # STEP: the sign convention is CHECKED, not assumed -- sqrt(diag(solve(-H)))
  # must reproduce the file's own stored marginal sd, or NEGH is not a precision
  # matrix and every step below is a step of unknown size.
  dmarg <- max(abs(sqrt(diag(solve(NEGH))) - SD_MARG))
  p5 <- isTRUE(md$pd) && all(is.finite(SD)) && all(SD > 0) && dmarg < 1e-8
  cm_say(paste0("=== GATE STEP === Hessian pd = %s, %s sd finite and positive for ",
                "%d/%d names, sqrt(diag(solve(-H))) reproduces md$sd_unc to %.2e -> %s\n"),
         md$pd, CM_STEP_KIND, sum(is.finite(SD) & SD > 0), length(SD), dmarg,
         if (p5) "PASS" else "*** FAIL ***")
  ok <- ok && p5

  if (!ok) stop("constraint-map gates failed; the map would be uninterpretable")
  invisible(TRUE)
}

# ---------------------------------------------------------------------
base <- cm_streams(u0)
# CM4 for STREAMS (2026-10-08 h): the arm's own family table = the union restricted to the streams it scores
CM_FAMILY <- Filter(length, lapply(CM_FAMILY_ALL, function(v) intersect(v, names(base$streams))))
# The interannual cut: stage 1 fits CCX_IAV_MODULE_NAMES to the monthly detrended global growth (LIK_IAV_WIN) and
# the rows the main objective dropped; stage 2 (this map) holds them. Recorded for the app's caption, gated above.
CM_IAV_CUT <- isTRUE(bp[["iav_cut"]] == 1)
CM_MODULE  <- if (!CM_IAV_CUT) NULL else
  list(names = intersect(CCX_IAV_MODULE_NAMES, names(pins)),
       rows = setdiff(unlist(CM_FAMILY_ALL, use.names = FALSE), names(base$streams)),
       growth_window = LIK_IAV_WIN)
cm_say("\n%s @%s, %s\n", CM_DRIVER, CM_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))
cm_say("[%s] mode %s, %d fitted names, %d streams, step = %.2f Hessian sd\n",
       CM_TAG, CM_MODE, length(NAMES), length(base$streams), CM_STEP_SD)
cm_gates(base)

# "gates" in ANY position (2026-10-08 h): as the first argument only, `mode=hilda33p gates` ran the full build
if ("gates" %in% commandArgs(trailingOnly = TRUE)) { cm_provenance(); quit(save = "no") }

STREAMS <- names(base$streams)
DHI <- DLO <- matrix(NA_real_, length(STREAMS), length(NAMES),
                     dimnames = list(STREAMS, NAMES))
DROP_OBS <- setNames(rep(NA_real_, length(NAMES)), NAMES)
t0 <- Sys.time()
for (j in seq_along(NAMES)) {
  h <- CM_STEP_SD * SD[[j]]
  uh <- u0; uh[j] <- u0[[j]] + h
  ul <- u0; ul[j] <- u0[[j]] - h
  DHI[, j] <- cm_streams(uh)$streams[STREAMS] - base$streams[STREAMS]
  DLO[, j] <- cm_streams(ul)$streams[STREAMS] - base$streams[STREAMS]
  DROP_OBS[j] <- max(-sum(DHI[, j]), -sum(DLO[, j]))
  cm_say("  %2d/%2d %-20s step %+.4f u -> max |d logL| %8.2f | drop %7.2f vs %5.2f predicted\n",
         j, length(NAMES), NAMES[[j]], h, max(pmax(abs(DHI[, j]), abs(DLO[, j]))),
         DROP_OBS[j], DROP_PRED[[j]])
}
cm_say("  %d evaluations in %.1f s\n", 2 * length(NAMES),
       as.numeric(Sys.time() - t0, units = "secs"))

# THE MAP: the larger of the two half-steps, per stream per parameter.
M <- pmax(abs(DHI), abs(DLO))

# PINS or PULLS, per cell: the curvature fraction, and the central slope's sign.
CURV <- abs(DHI + DLO) / pmax(abs(DHI) + abs(DLO), .Machine$double.eps)
SLOPE <- (DHI - DLO) / 2            # signed: > 0 means the stream prefers HIGHER
PINS  <- CURV >= CM_PIN_CUT
nonlin <- names(which(DROP_OBS > CM_NONLIN_FLAG * DROP_PRED))
cm_say("\n=== NONLINEARITY === measured drop > %.0fx the quadratic's prediction for %d of %d names%s\n",
       CM_NONLIN_FLAG, length(nonlin), length(NAMES),
       if (length(nonlin)) paste0(": ", paste(nonlin, collapse = ", ")) else "")
# Weight the verdict by leverage: a cell that moves nothing has no opinion.
w  <- M / max(M)
sh <- sum(w * PINS) / sum(w)
cm_say("=== PINS vs PULLS === leverage-weighted share of cells with curvature >= %.2f: %.1f %%\n",
       CM_PIN_CUT, 100 * sh)
top <- order(-as.vector(M))[1:8]
cm_say("    the 8 cells with most leverage, and which of the two they are:\n")
for (k in top) {
  i <- ((k - 1) %% nrow(M)) + 1; j <- ((k - 1) %/% nrow(M)) + 1
  cm_say("      %-22s x %-20s %8.2f  curv %.2f  %s, prefers %s\n",
         rownames(M)[i], colnames(M)[j], M[i, j], CURV[i, j],
         if (PINS[i, j]) "PINS" else "PULLS",
         if (SLOPE[i, j] > 0) "higher" else "lower")
}

# AGGREGATION (CM3): a sum, and the identity is gated.
agg <- function(X, rows, cols) {
  out <- matrix(0, length(rows), length(cols), dimnames = list(names(rows), names(cols)))
  for (a in seq_along(rows)) for (b in seq_along(cols))
    out[a, b] <- sum(X[rows[[a]], cols[[b]], drop = FALSE])
  out
}
MC <- agg(M, CM_FAMILY, CM_COMPONENT)
stopifnot(abs(sum(MC) - sum(M)) < CM_CLOSE_TOL)
cm_say("=== GATE AGGREGATE === sum(component map) - sum(parameter map) = %.3e -> PASS\n",
       sum(MC) - sum(M))

# ---------------------------------------------------------------------
cm_say("\n== the component map: log-units a family moves per one-Hessian-sd step ==\n")
print(round(MC, 1)); capture.output(print(round(MC, 1)), file = CM_LOG, append = TRUE)

cm_say("\n== who holds each observation family (row share, %%) ==\n")
RS <- sweep(MC, 1, pmax(rowSums(MC), .Machine$double.eps), "/") * 100
print(round(RS, 1)); capture.output(print(round(RS, 1)), file = CM_LOG, append = TRUE)

cm_say("\n== what holds each part of the model (column share, %%) ==\n")
CS <- sweep(MC, 2, pmax(colSums(MC), .Machine$double.eps), "/") * 100
print(round(CS, 1)); capture.output(print(round(CS, 1)), file = CM_LOG, append = TRUE)

# The weakest link, MEASURED: a parameter whose whole row of leverage is small is
# not identified by the data at all. Reported as an ORDERING, not against an
# invented log-unit bound (`threshold_from_obs_or_law`).
tot <- colSums(M)
cm_say("\n== parameters ordered by TOTAL leverage (least identified first) ==\n")
for (n in names(sort(tot))) {
  best <- STREAMS[[which.max(M[, n])]]
  cm_say("  %-20s total %8.2f   strongest single stream: %-22s %8.2f\n",
         n, tot[[n]], best, M[best, n])
}

saveRDS(list(
  M = M, DHI = DHI, DLO = DLO, CURV = CURV, SLOPE = SLOPE, PINS = PINS,
  MC = MC, RS = RS, CS = CS, pin_share = sh,
  base_streams = base$streams, base_loglik = base$loglik,
  sd_unc = SD, sd_marginal = SD_MARG, sd_conditional = SD_COND,
  sd_ratio = SD_MARG / SD_COND,
  drop_pred = DROP_PRED, drop_obs = DROP_OBS,
  step_sd = CM_STEP_SD, step_kind = CM_STEP_KIND,
  pin_cut = CM_PIN_CUT,
  nonlin_flag = CM_NONLIN_FLAG, nonlin_flagged = nonlin,
  component = CM_COMPONENT, family = CM_FAMILY, module = CM_MODULE,
  provenance = list(
    tag = CM_TAG, built = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    driver = CM_DRIVER, commit = CM_COMMIT,
    mode = CM_MODE, mode_file = ccx_mode_file(CM_MODE),
    stored_logpost = md$logpost, spinup = ccx_mode_spinup(md),
    struct = md$struct, pump_field = ccx_mode_pump_field(md),
    pins = names(pins), iav_cut = CM_IAV_CUT, n_eval = 2L * length(NAMES),
    step = CM_STEP_LABEL,
    sd_kind = paste("Laplace/Hessian at the mode -- NOT a sampled posterior;",
                    "conditional = 1/sqrt(diag(-H)), marginal = sqrt(diag(cov))"),
    units = CM_UNITS,
    seed = NA_integer_, seed_note = CM_SEED_NOTE)
), CM_OUT)
cm_say("\nwrote %s (%d streams x %d names)\n", CM_OUT, nrow(M), ncol(M))
cm_provenance()
