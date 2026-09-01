# =====================================================================
# diag_landed_gap_streams.R -- WHERE DO THE 86.7 LOG-UNITS ACTUALLY LIVE?
#                              (2026-08-25c)
#
# WHAT THIS REPLACES, AND IT IS A PREMISE, NOT A NUMBER.
#
# handoff_2026-08-25b sec.4 states the inherited question as:
#
#     "the frozen stream decomposition showed 93 % of that cost lives in
#      co2_level_MLO + co2_level_SPO ... should two station-level streams,
#      fitted through a 5.6 sigma nuisance offset, outvote the pulse response
#      and the airborne-fraction record by two orders of magnitude?"
#
# and names "price the station-level streams' effective n" the single
# highest-value unrun diagnostic.
#
# THAT 93 % IS A FROZEN-VECTOR NUMBER. It comes from diag_fert_ridge_streams.R,
# which walked the (beta_max, fert_k) ridge with the other 19 parameters HELD.
# The same handoff's sec.7 says, in terms:
#
#     "Frozen-vector costs are upper bounds and this session proved how badly.
#      The refit recovered 15-19x more than the frozen scan predicted. Never
#      read a frozen conditional optimum as a prediction of where a refit
#      lands."
#
# Its sec.4 did not apply that warning to itself. THE ARMS HAVE SINCE LANDED,
# so the decomposition can be taken AT THE LANDED MODES instead of inferred,
# and nothing had done that. This file does it.
#
# ---------------------------------------------------------------------
# THE h_ml BAND IS A GATE HERE, NOT HOUSEKEEPING. run_modefind_pump_arms.R:217
# ⚠ RETIRED BAND, 2026-08-28. This file was written when the three
# ocean-gradient rows SKIPPED outside [85, 120]. They are now scored at
# sigma_eff at every h_ml (option 5). What it reads below is PROVENANCE:
# results produced under it are NOT comparable with post-adoption fits.
# overrides CCX_PARAM_TABLE$h_ml to LIK_OCEAN_GRAD_HML_OK_RETIRED = [85, 120] IN THE
# RUNNING PROCESS, and the .rds does not record it (memory
# ccx_hml_band_provenance). Two consequences, both live:
#
#   * `u_mode` DOES NOT DECODE under the default [30, 200] band -- max |u -
#     u(par_mode)| = 1.7 across every arm here. `par_mode` is the authority.
#   * a logpost recomputed under the default band is off by ~1.1 log-units, in
#     the same direction for every arm, so it silently gives right DELTAS and
#     wrong LEVELS.
#
# GATE 1 below reproduces all five stored logposts to GAP_REPRO_TOL and stops
# if it cannot. That is what licenses reading the decomposition as the
# objective's own.
#
# THIS FILE CHANGES NOTHING. It reports.
#
# RUNTIME ~10 s.  Usage: Rscript calibration/diag_landed_gap_streams.R
# =====================================================================
# =====================================================================
# ⚠⚠ QUARANTINED 2026-08-29 -- THIS DRIVER IS PRE-ADOPTION AND HARD-STOPS.
#
# Marcus's decision, 2026-08-29, closing the item owed since handoff 08-28d §5:
# QUARANTINE, not re-point. `2153bd6` ("ADOPT OPTION 5") rescored the ocean-
# gradient rows at sigma_eff, and EVERY arm this driver reads (`ref`, `from90`,
# `pin90`) was fitted BEFORE it. Its whole method is differences of STORED
# logposts, and across that change a stored logpost moves by 0.081 -- measured
# at four points spanning 60 log units, collect 2026-08-29.
#
# It is NOT repairable by widening a band: GATE 1 reproduces logposts STORED by
# band-fitted arms, so widening fails it BY CONSTRUCTION. That is why it was the
# one mirror deliberately left un-widened on 08-28i.
#
#   outputs   -> outputs/quarantine/20260829_preadoption_landed_gap/
#   nearest live reader -> calibration/diag_stream_neff.R (band-widened)
#   replacement -> NONE. The question must be RE-ASKED post-adoption, not
#                  re-pointed; re-pointing silently changes what GATE 1 checks.
#
# Kept in place, and readable, as PROVENANCE. Delete nothing.
# =====================================================================
stop("diag_landed_gap_streams.R is QUARANTINED (2026-08-29).\n",
     "  Every arm it reads (ref / from90 / pin90) was fitted BEFORE the option-5\n",
     "  objective change `2153bd6`, and its method is differences of STORED\n",
     "  logposts, which that change moves by ~0.081.\n",
     "  Its outputs: outputs/quarantine/20260829_preadoption_landed_gap/\n",
     "  There is NO re-pointed replacement -- the question must be re-asked\n",
     "  against post-adoption vectors. Nearest live reader: diag_stream_neff.R.")

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants ------------------------------------------------
GAP_YEARS      <- c(1750, 2024)
GAP_REPRO_TOL  <- 1e-2      # log-units; stored logposts are printed to 2 dp
GAP_SHOW_MIN   <- 0.50      # log-units; smaller movers are folded into "other"
GAP_REF        <- "ref"
GAP_FOCUS      <- "from90"  # the arm that falsified P3 -- where does its +15.43 come from?
OUTDIR         <- ccx_path("calibration", "output", "landed_gap")
OUTFILE        <- file.path(OUTDIR, "landed_gap_streams.rds")
# The claim under test, from handoff_2026-08-25b sec.4 and the collect note.
GAP_CLAIM_STREAMS <- c("co2_level_MLO", "co2_level_SPO")
GAP_CLAIM_SHARE   <- 0.93
# ARMS RE-POINTED 2026-08-25g at the POST-FIX refit. The pre-fix arms this file
# was written against are in
# calibration/output/quarantine/20260825_seas_isotope_rectification/ and are
# NOT comparable across the objective change -- do not add them back here.
# GATE 1 below stops if a stored logpost cannot be reproduced, which is what
# keeps a quarantined file from being read as current.
# `ref` is the ONE literal here, and deliberately so: it names the PROGRESS
# file, because `refit_20260825f_ref/mode_fit_pumpN.rds` is the PRE-FIX SEED the
# driver warm-started from, not a result (-1909 under the current objective).
# ccx_mode_file() refuses the name `ref` for exactly that reason, so this arm
# cannot be resolved through it. The other two go through it.
GAP_ARMS <- c(ref    = ccx_path("calibration", "output", "refit_20260825f_ref",
                                "mode_fit_pumpN_progress.rds"),
              from90 = ccx_mode_file("from90"),
              pin90  = ccx_mode_file("pin90"))
GAP_ARMS <- GAP_ARMS[file.exists(GAP_ARMS)]

dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

# ---- restore the REFIT's h_ml band ----------------------------------
# Exactly run_modefind_pump_arms.R:216-222, so the prior term this file adds up
# is the one the arms were fitted against. Without it GATE 1 fails by ~1.1.
#
# ⚠ THIS IS THE ONE BAND MIRROR THAT MUST **NOT** BE WIDENED, and the reason is
# in the line above. GATE 1 reproduces each arm's STORED logpost, and every arm
# this file reads (`ref`, `from90`, `pin90`) was FITTED under [85, 120]. The band
# is not a scoring choice here -- it is part of those vectors' provenance, and
# scoring them on the shipped support would shift every logpost by exactly
# log(170/35) = 1.5805 and fail GATE 1 BY CONSTRUCTION. The other three mirrors
# were widened on 2026-08-28; this one deliberately was not.
#
# ⇒ WHAT THAT MEANS FOR THIS FILE: it is a PRE-ADOPTION driver. Its subjects are
# being quarantined by the option-5 objective change, not by anything about the
# band, and it cannot be made current by editing this constant. It needs to be
# re-pointed at post-adoption arms -- of which there will be exactly ONE, so a
# gap-between-arms driver may have nothing left to compare and may belong in the
# quarantine itself. That is a decision, not a rename.
GAP_HML_BAND <- LIK_OCEAN_GRAD_HML_OK_RETIRED   # PROVENANCE, deliberately not widened
cat(paste0("\n⚠ PRE-ADOPTION DRIVER. h_ml is scored on the RETIRED band [",
           GAP_HML_BAND[1], ", ", GAP_HML_BAND[2], "] because GATE 1 reproduces\n",
           "  logposts STORED by arms fitted under it. These numbers are NOT comparable\n",
           "  with post-adoption fits, and widening the band would fail GATE 1 by 1.5805.\n\n"))
CCX_PARAM_TABLE$h_ml$lo    <- GAP_HML_BAND[1]
CCX_PARAM_TABLE$h_ml$hi    <- GAP_HML_BAND[2]
CCX_PARAM_TABLE$h_ml$prior <-
  local({ lo <- GAP_HML_BAND[1]; hi <- GAP_HML_BAND[2]
          function(x) stats::dunif(x, lo, hi, log = TRUE) })

OBS <- ccx_prepare_obs()
LP  <- ccx_make_logpost(GAP_YEARS, OBS)

# ---- decompose one landed mode --------------------------------------
# Priors are evaluated from the STOCK table (with the band restored), NOT with
# any pin in place, so the pinned arms' near-delta offset is removed by
# construction and every arm is priced on the same objective. That is the
# "pin-offset removed" column of the collect note.
gap_decompose <- function(file) {
  md <- readRDS(file)          # GAP_ARMS entries are already absolute
  # A PROGRESS FILE CARRIES NO `param_names` -- the driver's per-cycle saveRDS
  # omits it (run_modefind_pump_arms.R:575). So the identity is asserted on
  # whichever field the file actually has, rather than skipped for progress
  # files: a mis-ordered par_mode is exactly the failure this guards against
  # (memory nameless_matrix_order).
  if (!is.null(md$param_names)) stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
  else stopifnot(identical(names(md$par_mode)[seq_along(CCX_PARAM_NAMES)], CCX_PARAM_NAMES))
  pv <- md$par_mode
  u  <- ccx_par_to_unc(pv)
  pri <- vapply(CCX_PARAM_NAMES, function(n) {
    s <- CCX_PARAM_TABLE[[n]]; s$prior(pv[[n]]) + .log_jac(u[[n]], s)
  }, numeric(1))

  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv)
  p$pump_mode  <- md$pump_mode
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GAP_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale)
  o  <- ccx_run_fast(sp, F)$out
  err <- list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
              grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c)
  st <- unlist(ccx_loglik(o, OBS, err, luc = ccx_forcing_eluc_annual(F),
                          deep = sp$diagnostics$d14c_bottom_box,
                          ocean_grad = ccx_ocean_grad_scored(o, sp),
                          by_stream = TRUE))
  list(streams = st, prior = pri, ll = sum(st), lp = sum(pri) + sum(st),
       stored = md$logpost, lp_closure = LP(u), par = pv, u = u)
}

A <- lapply(GAP_ARMS, gap_decompose)

# ---- GATE 1: the recomputation IS the objective ---------------------
# Two independent routes must agree with each other AND with the stored value:
# the hand-assembled prior + by_stream sum, and ccx_make_logpost() evaluated at
# the same u. The pinned arms' STORED logpost carries the near-delta, so it is
# compared only after the pin offset it implies is accounted for -- which is
# why the check is "closure == hand-assembled" for all five and "== stored" for
# the two unpinned arms, where no pin was ever applied.
cat("=== GATE 1: reproduce the objective at the landed modes ===\n")
cat(sprintf("h_ml band restored to [%g, %g] (run_modefind_pump_arms.R:217)\n\n",
            GAP_HML_BAND[1], GAP_HML_BAND[2]))
cat(sprintf("%-7s %12s %12s %12s %10s\n",
            "arm", "stored", "closure", "hand-sum", "pin offset"))
for (nm in names(A)) {
  a <- A[[nm]]
  cat(sprintf("%-7s %12.2f %12.2f %12.2f %10s\n", nm, a$stored, a$lp_closure, a$lp,
              if (abs(a$stored - a$lp) < GAP_REPRO_TOL) "-  (none)"
              else sprintf("%+.2f", a$stored - a$lp)))
  stopifnot(abs(a$lp_closure - a$lp) < GAP_REPRO_TOL)
}
# The UNPINNED arms must match their stored logpost exactly; `pin90` carries the
# near-delta and is expected to differ by the pin offset, which is PRINTED above
# rather than assumed -- +11.6698 at fert_k = 90, computed from the transform.
unpinned <- intersect(c("ref", "from90"), names(A))
for (nm in unpinned) stopifnot(abs(A[[nm]]$stored - A[[nm]]$lp) < GAP_REPRO_TOL)
cat(sprintf("GATE 1 PASS: both routes agree; the %d unpinned arm(s) match their stored logpost.\n",
            length(unpinned)))

# ---- the decomposition ----------------------------------------------
nms  <- names(A[[GAP_REF]]$streams)
alt  <- setdiff(names(A), GAP_REF)
D    <- vapply(A[alt], function(x) x$streams[nms] - A[[GAP_REF]]$streams[nms],
               numeric(length(nms)))
rownames(D) <- nms
Dp   <- vapply(A[alt], function(x) x$prior - A[[GAP_REF]]$prior,
               numeric(length(CCX_PARAM_NAMES)))
rownames(Dp) <- CCX_PARAM_NAMES
GAP  <- colSums(D) + colSums(Dp)

hdr <- function(what) cat(sprintf("\n%-24s %10s | %s\n", what, "ref logL",
                                  paste(sprintf("%9s", alt), collapse = "")))
row <- function(lab, ref, v) cat(sprintf("%-24s %10.1f | %s\n", lab, ref,
                                  paste(sprintf("%+9.2f", v), collapse = "")))

cat(sprintf("\n\n=== DELTA LOG-POSTERIOR vs the %s mode, AT THE LANDED MODES ===\n", GAP_REF))
hdr("likelihood stream")
small <- rownames(D)[apply(abs(D), 1, max) < GAP_SHOW_MIN]
for (nm in rownames(D)[order(D[, GAP_FOCUS])])
  if (!nm %in% small) row(nm, A[[GAP_REF]]$streams[[nm]], D[nm, ])
row(sprintf("other (%d streams)", length(small)),
    sum(A[[GAP_REF]]$streams[small]), colSums(D[small, , drop = FALSE]))
row("LIKELIHOOD TOTAL", A[[GAP_REF]]$ll, colSums(D))

hdr("prior term")
smallp <- rownames(Dp)[apply(abs(Dp), 1, max) < GAP_SHOW_MIN]
for (nm in rownames(Dp)[order(Dp[, GAP_FOCUS])])
  if (!nm %in% smallp) row(nm, A[[GAP_REF]]$prior[[nm]], Dp[nm, ])
row(sprintf("other (%d params)", length(smallp)),
    sum(A[[GAP_REF]]$prior[smallp]), colSums(Dp[smallp, , drop = FALSE]))
row("PRIOR TOTAL", sum(A[[GAP_REF]]$prior), colSums(Dp))
row("LOG-POSTERIOR TOTAL", A[[GAP_REF]]$lp, GAP)

# ---- WHERE DOES THE FOCUS ARM'S GAIN COME FROM? ---------------------
cat(sprintf("\n\nWHAT MAKES UP %s's %+.2f vs %s, ranked:\n", GAP_FOCUS, GAP[[GAP_FOCUS]], GAP_REF))
allrows <- c(setNames(D[, GAP_FOCUS], rownames(D)),
             setNames(Dp[, GAP_FOCUS], paste0("prior:", rownames(Dp))))
allrows <- allrows[order(-allrows)]
cum <- 0
for (nm in names(allrows)) {
  if (abs(allrows[[nm]]) < GAP_SHOW_MIN) next
  cum <- cum + allrows[[nm]]
  cat(sprintf("  %-24s %+8.2f   cum %+8.2f\n", nm, allrows[[nm]], cum))
}

saveRDS(list(arms = A, D = D, Dprior = Dp, gap = GAP, hml_band = GAP_HML_BAND,
             claim_streams = GAP_CLAIM_STREAMS, files = GAP_ARMS),
        OUTFILE)
cat(sprintf("\nwritten: %s\n", OUTFILE))
