# =====================================================================
# promote_multistart_mode.R -- turn a MULTISTART start file into a MODE FILE.
#
# WHY THIS EXISTS. Every mode the project has ever adopted was written by
# run_modefind_pump_arms.R, which emits `mode_fit_pump<arm>.rds` directly. The
# dispersed multistart driver emits `start_NNN.rds` instead -- a different
# field set, one file per start -- because its question is "how many BASINS",
# not "what is the mode". Until 2026-09-03 no multistart result had ever been
# adopted (09-01 enso25 and 09-02 demean25 both landed and were both ruled DO
# NOT ADOPT), so the conversion had never been needed and does not exist.
#
# ⛔ ADOPTS NOTHING. It writes a mode file into a NEW directory. Repointing
# `CCX_MODE_CANONICAL` is a SEPARATE, later decision -- doing both here would
# mean a script that changes what every diagnostic in the repo resolves to as a
# side effect of building a file.
#
# ⚠ THE CHOICE OF START IS DERIVED, NOT PICKED. Gate 3 recomputes the best
# CONVERGED start from the directory and refuses to promote anything else. A
# hand-typed id is exactly the drift `[[derived_must_mean_computed]]` warns
# about: 39 of these 40 starts agree to 4e-4, so "the best one" is a fact about
# the directory that must be READ from it, not remembered.
#
#   Rscript calibration/promote_multistart_mode.R [--outdir=DIR] [--dest=DIR] [--force]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
source(ccx_path("calibration", "lib_ms_deadline.R"))   # ms_start_clock(): the clock `minutes` is on (2026-10-05 o)
ccx_load_cpp()

args <- commandArgs(trailingOnly = TRUE)
.arg <- function(k, d) {
  h <- grep(paste0("^--", k, "="), args, value = TRUE)
  if (length(h)) sub(paste0("^--", k, "="), "", h[1]) else d
}
# ---- labels derive from named constants (project rule) --------------
PMM_SRC_NAME   <- .arg("name", "ent26")            # the arc this mode comes from
# THE STRUCTURE (2026-09-08f). Start files record `struct` from 09-08f on; older
# ones do not, and for those the label MUST be given on the command line and is
# then ASSERTED by GATE 4 (a wrong label does not reproduce the logpost).
PMM_STRUCT     <- .arg("struct", NA_character_)
PMM_SRC_DIR    <- .arg("outdir", ccx_path("calibration", "output",
                                          "multistart_20260903_ent26"))
PMM_DEST_DIR   <- .arg("dest",   ccx_path("calibration", "output",
                                          "refit_20260903_ent26"))
PMM_ARM        <- "N"                              # the pump arm; free, not pinned
PMM_DEST_FILE  <- file.path(PMM_DEST_DIR, sprintf("mode_fit_pump%s.rds", PMM_ARM))
PMM_FORCE      <- "--force" %in% args
PMM_LP_TOL     <- 1e-5      # matches recompute_hessian.R's GATE 1 -- the same
                            # question ("does this point reproduce?") answered
                            # to the same precision, deliberately not tighter.
PMM_N_PAR      <- length(CCX_PARAM_NAMES)

sep <- function(s) cat(sprintf("\n%s\n%s\n", s, strrep("-", nchar(s))))
cat(sprintf("\n==== PROMOTE a %s multistart start to a mode file ====\n", PMM_SRC_NAME))
cat(sprintf("source  %s\ndest    %s\n", PMM_SRC_DIR, PMM_DEST_FILE))

fs <- sort(list.files(PMM_SRC_DIR, pattern = "^start_[0-9]+\\.rds$", full.names = TRUE))
if (!length(fs)) stop("no start_*.rds under ", PMM_SRC_DIR)
S <- lapply(fs, readRDS)

# ---------------------------------------------------------------------
# PINS (2026-09-13): a pinned arm's starts record `pins`; apply them so that GATE 1
# compares against the REDUCED set, and carry them into the mode file (ccx_mode_base
# holds them in the base; ccx_mode_params does not fit them).
# THE GATE FIRST (2026-09-30; CCX_PARAM_GATED): a structure that OPENS it fits four more
# names, so GATE 1 must compare against the OPEN table. The starts' own recorded structure
# decides it (a start that predates labels records none and cannot be open); a directory
# whose starts disagree is refused at GATE 4 below.
.gate_rec <- unique(vapply(S, function(s) if (is.null(s$struct)) NA_character_ else s$struct, character(1)))
PMM_GATE <- if (length(.gate_rec) == 1L && !is.na(.gate_rec)) ccx_apply_gate(.gate_rec) else character(0)
if (length(PMM_GATE)) cat(sprintf("GATE OPEN (structure '%s'): %s are fitted names\n", .gate_rec, paste(PMM_GATE, collapse = ", ")))
pin_rec <- unique(vapply(S, function(s) ccx_pin_label(s$pins), ""))
if (length(pin_rec) != 1L) stop("the starts disagree on their pins: ", paste(pin_rec, collapse = " | "))
PMM_PINS <- S[[1]]$pins
invisible(ccx_apply_pins(PMM_PINS)); PMM_N_PAR <- length(CCX_PARAM_NAMES)
if (length(PMM_PINS)) cat(sprintf("PINNED arm: %s (%d free parameters)\n", ccx_pin_label(PMM_PINS), PMM_N_PAR))
sep("GATE 1: every start in this directory is on THIS build's parameter set")
# ⚠ A 21- or 25-parameter start would promote silently into a 26-parameter
# build and only fail later, at whichever diagnostic decoded it first.
bad <- Filter(function(s) !identical(s$param_names, CCX_PARAM_NAMES), S)
cat(sprintf("build fits %d parameters; %d of %d starts match\n",
            PMM_N_PAR, length(S) - length(bad), length(S)))
if (length(bad))
  stop(length(bad), " start(s) carry a different parameter set, e.g. id ",
       bad[[1]]$id, " with ", length(bad[[1]]$param_names), " names.")

# ---------------------------------------------------------------------
sep("GATE 2: one arm, one objective -- or a ranking across them is meaningless")
arms <- unique(vapply(S, function(s) as.character(s$pump_mode), character(1)))
cat(sprintf("pump arms present: %s\n", paste(arms, collapse = ", ")))
if (length(arms) != 1L) stop("mixed pump arms: ", paste(arms, collapse = ", "))
if (!identical(arms, PMM_ARM))
  stop("this directory is arm '", arms, "', not the free arm '", PMM_ARM, "'")

# ---------------------------------------------------------------------
sep("GATE 3: the start to promote is COMPUTED from the directory")
fin <- Filter(function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time), S)
if (!length(fin)) stop("no CONVERGED, in-time start in ", PMM_SRC_DIR)
lp  <- vapply(fin, function(s) s$logpost, numeric(1))
best <- fin[[which.max(lp)]]
cat(sprintf("%d of %d starts CONVERGED in time\n", length(fin), length(S)))
cat(sprintf("best is id %d at %.6f\n", best$id, best$logpost))
# The runners-up are quoted because the SPREAD is the honest statement: when 39
# starts agree to 4e-4, "the best" is a label on a tie, not a distinguished
# point, and the file records that rather than implying a precision it lacks.
o <- order(lp, decreasing = TRUE)
# ⚠ With ONE finished start, `o[2:min(4, 1)]` is `o[2:1]` = c(NA, id) and the
# vapply died on the NA (2026-09-28, promoting a single-basin scratch dir).
# seq_len() gives the empty set instead, and the file says so rather than crashing.
ru <- o[-1][seq_len(min(3L, length(o) - 1L))]
cat(sprintf("runners-up: %s\n",
            if (!length(ru)) "none (only one finished start)" else
              paste(sprintf("id %d %.6f", vapply(fin[ru], function(s) s$id, integer(1)),
                            lp[ru]), collapse = "; ")))
tie <- sum(lp > max(lp) - best$cycle_tol)
cat(sprintf("%d of %d finished starts lie within the optimiser's own convergence\n",
            tie, length(fin)))
cat(sprintf("bound of %.2f log-units, spanning %.2e log-units\n",
            best$cycle_tol, max(lp) - min(lp[lp > max(lp) - best$cycle_tol])))

# ---------------------------------------------------------------------
sep("GATE 4: the point reproduces its own logpost, under the band it RECORDS")
# ⚠ NEVER `best$u_mode` -- `u_mode` is band-dependent and `par_mode` is not
# ([[ccx_hml_band_provenance]]). Re-encode from par_mode under the file's own
# hml_bound, exactly as recompute_hessian.R does, and refuse if it disagrees.
# ⚠ ONLY when the recorded band DIFFERS from the shipped one (the from90 [85, 120]
# case). Re-imposing a UNIFORM prior on the shipped band would replace h_ml's
# observation prior (09-08d) and change the objective -- and then nothing reproduces.
if (!is.null(best$hml_bound) && !isTRUE(all.equal(best$hml_bound, c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)))) {
  CCX_PARAM_TABLE$h_ml$lo    <- best$hml_bound[1]
  CCX_PARAM_TABLE$h_ml$hi    <- best$hml_bound[2]
  CCX_PARAM_TABLE$h_ml$init  <- mean(best$hml_bound)
  CCX_PARAM_TABLE$h_ml$prior <-
    local({ b <- best$hml_bound; function(x) stats::dunif(x, b[1], b[2], log = TRUE) })
}
st_rec <- unique(vapply(S, function(s) if (is.null(s$struct)) NA_character_ else s$struct, character(1)))
if (length(st_rec) != 1L) stop("the starts disagree on their structure label: ", paste(st_rec, collapse = ", "))
if (is.na(st_rec)) {
  if (is.na(PMM_STRUCT)) stop("these starts record no structure; pass --struct=\"\" (column) or --struct=hilda")
  cat(sprintf("structure ASSERTED from --struct='%s' (the starts predate the label; GATE 4 checks it)\n", PMM_STRUCT))
} else {
  if (!is.na(PMM_STRUCT) && !identical(PMM_STRUCT, st_rec)) stop("--struct='", PMM_STRUCT, "' but the starts record '", st_rec, "'")
  PMM_STRUCT <- st_rec; cat(sprintf("structure RECORDED in the starts: '%s'\n", PMM_STRUCT))
}
# THE SEASONAL MIXED LAYER (2026-09-10). Start files record `seas_ml` from
# 09-10 on; older ones do not, and for those 0 is a FACT, not a default: the
# driver had no way to set it before 09-10 ⇒ [[ccx_refit_ran_at_seas_ml_0]].
# GATE 4 (the logpost reproduces) checks the label either way.
sm_rec <- unique(vapply(S, function(s) if (is.null(s$seas_ml)) NA_integer_ else ccx_parse_seas_ml(s$seas_ml), integer(1)))
if (length(sm_rec) != 1L) stop("the starts disagree on seas_ml: ", paste(sm_rec, collapse = ", "))
PMM_SEAS_ML <- if (is.na(sm_rec)) 0L else sm_rec
cat(sprintf("seas_ml %s: %d (%s)\n", if (is.na(sm_rec)) "INFERRED from the starts' age" else "RECORDED in the starts",
            PMM_SEAS_ML, if (PMM_SEAS_ML == 1L) "the seasonal mixed layer ON -- round 6" else "OFF -- the shipped model"))
# THE PUMP FIELD (2026-09-14 h). Start files record `pump_field` from 09-14 h on;
# older ones do not, and for those "solved" is a FACT (no other field existed),
# the ccx_mode_pump_field() contract. Carried into the mode file below.
pf_rec <- unique(vapply(S, function(s) if (is.null(s$pump_field)) NA_character_ else ccx_parse_pump_field(s$pump_field), character(1)))
if (length(pf_rec) != 1L) stop("the starts disagree on pump_field: ", paste(pf_rec, collapse = ", "))
PMM_PUMP_FIELD <- if (is.na(pf_rec)) "solved" else pf_rec
cat(sprintf("pump_field %s: '%s'\n", if (is.na(pf_rec)) "INFERRED from the starts' age" else "RECORDED in the starts", PMM_PUMP_FIELD))
bp <- ccx_apply_structure(ccx_default_params(), PMM_STRUCT, seas_ml = PMM_SEAS_ML, pump_field = PMM_PUMP_FIELD)
for (n in names(PMM_PINS)) bp[[n]] <- PMM_PINS[[n]]
bp$pump_mode <- best$pump_mode
lpf <- ccx_make_logpost(base_params = bp)
u   <- ccx_par_to_unc(best$par_mode)
lp0 <- lpf(u)
lpf_by_stream <- ccx_make_logpost(base_params = bp, by_stream = TRUE)   # the objective's OWN decomposition, stored below (09-19 m)
cat(sprintf("h_ml band  [%g, %g] (from the start file)\n",
            best$hml_bound[1], best$hml_bound[2]))
cat(sprintf("log-post   %.6f   file %.6f   diff %.3e\n",
            lp0, best$logpost, lp0 - best$logpost))
if (abs(lp0 - best$logpost) > PMM_LP_TOL)
  stop("the start does not reproduce -- promoting it would name the wrong point")

# ---------------------------------------------------------------------
sep("the per-stream decomposition at the mode")
# Computed HERE, from the promoted vector, for the same reason the refit driver
# computes it inline: a decomposition assembled later can drift from the mode it
# claims to describe. diag_design_gates_at_mode.R's provenance gate recomputes
# this and is what caught the luc_scale-squared bug in the 08-18 files.
pm <- best$par_mode
# ⛔ ccx_overlay_par(), NOT the bare `intersect()` loop this was first written
# with (copied from run_modefind_pump_arms.R, and caught by
# test-overlay-idiom-lint.R on its first run -- Ruling B, convert on touch).
# The loop is inert HERE, because `pm` already carries all 26 names, but that is
# exactly how it stayed invisible in 53 other files until a split made it live:
# it assigns NULL for any name the fitted set lacks, which DELETES the element
# and drops the run on a named default with nothing said.
p_mode <- ccx_overlay_par(bp, pm)
p_mode$pump_mode <- best$pump_mode
streams <- local({
  # ⛔ `CCX_OBJECTIVE_SPINUP`, NOT `ccx_spinup` (2026-09-09x). This reconstruction
  # must score the SAME STATE the objective does, or GATE 5 below -- which
  # compares `lp0 - sum(st)` against the recomputed prior -- fails on a correct
  # arm, and every promoted `streams` field is written from the wrong spinup.
  # ⚠⚠ ONLY the spinup is shared. The REST of this block stays a HAND-BUILT
  # reconstruction on purpose: GATE 5's power is that `streams` reaches the
  # likelihood by a DIFFERENT PATH than the objective does, and that is the check
  # the luc_scale-squared bug failed. Routing it through
  # `ccx_make_logpost(by_stream = TRUE)` would make GATE 5 a SELF-COMPARISON
  # ⇒ [[gate_reads_its_own_output]]. Same state, different path.
  sp <- CCX_OBJECTIVE_SPINUP(p_mode)
  # the forcing's ENSO index and AOD mode are the STRUCTURE's, as in the objective (2026-09-30):
  # without them every aod_mode-"anomaly" label (hilda_csl3v0ka and every label chained from
  # it) stopped here at ccx_run_prepared()'s AOD mismatch. The defaults ("demean", "legacy")
  # are what every older label resolves to, so the older labels' forcing is unchanged.
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                         bomb_total_kmol = 102,
                         enso_index = ccx_enso_index_of(p_mode), aod_mode = ccx_aod_mode_of(p_mode))
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pm$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pm$luc_scale
  attr(F, "luc_scale") <- pm$luc_scale
  el <- ccx_forcing_eluc_annual(F)
  r  <- ccx_run_fast(sp, F)
  err <- list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
              grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
  # the D3 shares (2026-09-30, objective #14): a fitted pair moves the two GCB sink rows'
  # targets. Absent (every older label) = NULL = objective #13's rows, as before.
  .sh <- ccx_imb_shares(pm)
  if (!is.null(.sh)) { err$imb_share_land <- .sh[["land"]]; err$imb_share_ocean <- .sh[["ocean"]] }
  # the structure's likelihood switches (objective #17, 2026-10-06): absent under every other label
  err <- ccx_err_with_struct(err, p_mode)
  ccx_loglik(r$out, ccx_prepare_obs(), err,
             luc = el, deep = ccx_d14c_deep_read(sp),
             # the modern-NPP row, where the structure carries it (npp_row, 2026-09-29)
             npp = if (isTRUE(p_mode$npp_row == 1)) r$npp else NULL,
             ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE,
             # the profile D14C bundle (#8/#9, 2026-09-06): its three rows REPLACE
             # the bottom-box row `d14c_deep_ocean` (23 -> 25 streams). Absent
             # until 2026-09-08g, so every promoted `streams` field before that
             # carried the old row instead, and GATE 5's printed residual
             # silently absorbed the 4.75 log-unit difference at hilda31.
             d14c_mid = ccx_model_d14c_slabs(sp))
})
st <- unlist(streams)
cat(sprintf("%d streams, total %.4f\n", length(st), sum(st)))
print(round(sort(st), 3))

# ---------------------------------------------------------------------
sep("GATE 5: the streams sum to the likelihood half of the logpost")
# ⚠ NOT a self-comparison: the streams come from ccx_loglik(by_stream = TRUE)
# and the reference comes from the OBJECTIVE, which reaches the likelihood by a
# different path. This is the check the luc_scale-squared bug failed.
pri <- lp0 - sum(st)
# The prior + Jacobian, RECOMPUTED from the table the objective was built on
# (the same formula ccx_make_logpost() sums; the band re-imposition above, when
# it applies, has already replaced h_ml's prior there). Until 2026-09-08g this
# residual was only PRINTED, so a missing stream could hide in it -- and the
# three profile rows did, for two adoptions.
# ⚠ AT THE STRUCTURE THE OBJECTIVE READ (2026-09-17). ccx_make_logpost() evaluates
# every prior at `base_params` + the draw, because u_hs's Sv-to-m/yr centre
# converts at the LIVE hs_frac (09-16 d). A bare `s$prior(x)` here converts at the
# built 0.16, and under `hilda_c` (0.128) this gate then FAILED a correct point
# by 0.27 -- the first hilda_c promotion, 09-17 (h). Same list, same dispatch.
p_pr <- bp; for (n in names(pm)) p_pr[[n]] <- pm[[n]]
pj <- sum(vapply(CCX_PARAM_NAMES, function(n) { s <- CCX_PARAM_TABLE[[n]]
  .ccx_prior_eval(s, pm[[n]], p_pr) + .log_jac(u[[match(n, CCX_PARAM_NAMES)]], s) }, numeric(1)))
cat(sprintf("sum(streams) %.6f ; logpost %.6f ; implied prior+jacobian %.6f ; recomputed prior+jacobian %.6f ; gap %.3e (tol %g)\n",
            sum(st), lp0, pri, pj, pri - pj, PMM_LP_TOL))
if (!is.finite(pri)) stop("non-finite prior residual -- the decomposition is wrong")
if (abs(pri - pj) > PMM_LP_TOL)
  stop("GATE 5: the streams do not sum to the likelihood half of the logpost (gap ",
       format(pri - pj, digits = 3), "): a stream is missing from the decomposition ",
       "or the prior is not the one the objective used.")

# ---------------------------------------------------------------------
sep("the h_ml KINK MAP -- derived from the shape function, not typed")
# Same derivation as run_modefind_pump_arms.R's ARM_KINKS: read the shape
# function so the list cannot drift from the code that creates the kinks.
PMM_KINK_STEP <- 0.25    # m; the sweep resolution
PMM_KINK_FACT <- 10      # x median second difference = a kink
PMM_KINK_EXPECT <- 0     # post-C1-remap (2026-08-29k); non-zero means a regression
PMM_KINKS <- local({
  kh <- seq(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi, by = PMM_KINK_STEP)
  KS <- t(sapply(kh, function(h) ccx_pump_shape(ccx_ocean_grid(h))))
  kt <- rowSums(abs(apply(KS, 2, function(v) diff(diff(v)))))
  kb <- which(kt > PMM_KINK_FACT * stats::median(kt) + 1e-14)
  if (!length(kb)) return(numeric(0))
  unname(vapply(split(kb, cumsum(c(TRUE, diff(kb) > 1))),
                function(ix) kh[ix[which.max(kt[ix])] + 1], numeric(1)))
})
cat(sprintf("%d kink(s) in [%g, %g]%s\n", length(PMM_KINKS),
            CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi,
            if (length(PMM_KINKS))
              sprintf(": h_ml = %s m", paste(sprintf("%.2f", PMM_KINKS), collapse = ", "))
            else " -- as expected post-C1-remap"))
if (length(PMM_KINKS) != PMM_KINK_EXPECT)
  cat(sprintf("*** the kink count is %d, not the expected %d -- the C1 remap may have regressed\n",
              length(PMM_KINKS), PMM_KINK_EXPECT))

sep("writing the mode file")
# The second-order block is DELIBERATELY ABSENT. A multistart start carries no
# Hessian, and inventing one here would hand out a Laplace covariance nobody
# measured. `recompute_hessian.R --update` fills it in, after its own gates.
out <- list(
  pump_mode = best$pump_mode, struct = PMM_STRUCT, seas_ml = PMM_SEAS_ML,
  pump_field = PMM_PUMP_FIELD,   # (2026-09-14 h) read back by ccx_mode_pump_field() / ccx_mode_base()
  # THE SPINUP VINTAGE (2026-09-10): `streams` below and `lp0` are computed under
  # CCX_OBJECTIVE_SPINUP, and a consumer reproducing them like-for-like needs to
  # know which one that was ⇒ ccx_mode_spinup(), [[like_for_like_forcing]].
  spinup = ccx_spinup_label(CCX_OBJECTIVE_SPINUP),
  u_mode = u, par_mode = pm, logpost = lp0,
  logpost_init = best$logpost_start, trace = best$trace,
  # ⚠ THE STORED `streams` ARE THE OBJECTIVE'S OWN (2026-09-19 m), not the hand-built
  # reconstruction GATE 5 checked them against. The hand path is gate 5's POWER
  # (a different route to the same likelihood) and stays above; but every consumer
  # that pins md$streams bit-for-bit -- the P0a tests, edm_crosscheck, test-mode-file,
  # the restamp tool -- compares against ccx_make_logpost(by_stream = TRUE)'s
  # attr, and the two paths agree only to ~1e-9 relative (6e-6 on a row at
  # hilda30e). Both 09-19 j promotions had to be re-recorded by the restamp tool
  # for that reason; a file written from the objective's path needs no restamp.
  streams = attr(lpf_by_stream(u), "streams"), n_eval = best$n_eval, minutes = best$minutes,
  # COPIED THROUGH (2026-10-05 o): the clock `minutes` is on ("wall" for a start file that predates the field).
  # The budget and the wall minutes beside it are added below the list, only when the start file recorded them.
  clock = ms_start_clock(best),
  seed = best$seed, param_names = CCX_PARAM_NAMES, prior_z = best$prior_z,
  kz_bracket = c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi),
  hml_bound = best$hml_bound,
  substeps = ccx_substeps_for(p_mode),
  # ⚠ DERIVED HERE, and it must be present even when EMPTY. `hml_kinks` is a
  # property of the pump SHAPE, not of the fit, and post-C1-remap (2026-08-29k)
  # the expected count is ZERO. Omitting the field would make recompute_hessian's
  # h_ml kink check silently skip -- "no kinks, checked" and "never looked" must
  # not look the same ([[default_off_hides_the_bug]]).
  hml_kinks = PMM_KINKS,
  # the pins this arm was fitted under (NULL = free); READ by ccx_mode_base()
  pins = PMM_PINS,
  # PROVENANCE -- what this file is, so a reader never has to reconstruct it.
  promoted_from = list(dir = PMM_SRC_DIR, file = fs[which.max(
                         vapply(S, function(s) if (identical(s$id, best$id)) 1 else 0, numeric(1)))],
                       id = best$id, kind = best$kind,
                       n_converged = length(fin), n_starts = length(S),
                       n_within_cycle_tol = tie, cycle_tol = best$cycle_tol,
                       spread_measured = best$spread_measured,
                       port_target = best$port_target, port_rel = best$port_rel,
                       host = best$host, r_version = best$r_version),
  promoted_by = "calibration/promote_multistart_mode.R",
  promoted_on = format(Sys.Date()))
# the start file's budget and wall minutes (2026-10-05 o); assigning NULL adds nothing, so an older start adds neither
out$budget_min <- best$budget_min; out$minutes_wall <- best$minutes_wall
dir.create(PMM_DEST_DIR, showWarnings = FALSE, recursive = TRUE)
if (file.exists(PMM_DEST_FILE) && !PMM_FORCE)
  stop(PMM_DEST_FILE, " exists; pass --force to overwrite")
saveRDS(out, PMM_DEST_FILE)
cat(sprintf("wrote %s\n", PMM_DEST_FILE))
cat("\n⛔ ADOPTS NOTHING. CCX_MODE_CANONICAL is still '", CCX_MODE_CANONICAL,
    "'.\n   Next: recompute_hessian.R --update, then the repoint.\n", sep = "")
