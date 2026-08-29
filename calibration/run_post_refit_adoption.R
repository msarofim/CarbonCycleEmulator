# =====================================================================
# run_post_refit_adoption.R -- ONE COMMAND FOR handoff_2026-08-28c §4.2-4.5.
#
# WHAT THIS IS FOR. The 21-parameter refit onto the post-option-5 objective
# (calibration/output/refit_20260828_sigma_eff/, launched 2026-08-28 19:44) is
# the blocker for FOUR separate follow-ups, and every one of them is a chance to
# leave the project half-migrated: a quarantine that moves the incumbent before
# a replacement exists breaks ccx_mode_file() and the app; a repoint that lands
# without the quarantine leaves a live pre-adoption vector resolvable by name;
# and a gate re-run against the OLD mode reports pre-adoption numbers as current.
# Doing them by hand at the end of an 18 h wait is how one gets skipped. This
# runs them in the only order that is safe, and refuses to start if the refit
# has not actually landed.
#
# WRITTEN 2026-08-28 WHILE THE REFIT WAS STILL RUNNING, deliberately: the work
# is the same either way, and prepared now it is reviewable against a handoff
# that is still in context rather than reconstructed tomorrow.
#
#   Rscript calibration/run_post_refit_adoption.R [--stage=NAME] [--retire-pin90|--keep-pin90]
#
# STAGES, in dependency order. Default runs all of them; --stage runs one.
#   check      preconditions -- the refit finished, nothing is still running
#   read       WHAT THE REFIT ACTUALLY BOUGHT, decomposed (see the warning below)
#   quarantine move the incumbent out, with a README
#   repoint    R/paths.R + tests/testthat/test-mode-file.R, then the suite
#   rerun      the Hessian pair and the design gates at the NEW mode
#
# ⚠ READ `read` BEFORE BELIEVING ANY h_ml NUMBER. The 14.2-min smoke test
# reported h_ml = 35.38 m and "gained" 4.1 log-units, and NONE of that was fit:
# the whole gain was prior credit on sst_seas_amp_SH (+4.145) and _NH (+1.632),
# bought with a WORSE likelihood (-1.201). A refit that moves h_ml a long way is
# therefore NOT self-evidently a finding -- it is the seasonal-amplitude prior
# conflict dragging the softest direction. Stage `read` exists to make that
# decomposition unavoidable rather than optional. It prints prior / jacobian /
# loglik separately and names the per-parameter movers, so the question
# "did the fit improve, or did the prior get paid?" is answered before anything
# is quarantined. [[seas_amps_hemispheric_inversion]]
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from named constants (project rule) --------------
PRA_NEW_NAME    <- "sigeff"     # the name ccx_mode_file() will resolve after this
PRA_NEW_DIRNAME <- "refit_20260828_sigma_eff"
PRA_NEW_DIR     <- ccx_path("calibration", "output", PRA_NEW_DIRNAME)
PRA_NEW_MODE    <- file.path(PRA_NEW_DIR, "mode_fit_pumpN.rds")
PRA_NEW_CMP     <- file.path(PRA_NEW_DIR, "pump_arms_comparison.rds")
PRA_NEW_LOG     <- file.path(PRA_NEW_DIR, "_run.log")
PRA_OLD_NAME    <- "from90"
PRA_OLD_DIRNAME <- "refit_20260825f_from90"
PRA_OLD_DIR     <- ccx_path("calibration", "output", PRA_OLD_DIRNAME)
PRA_OLD_MODE    <- file.path(PRA_OLD_DIR, "mode_fit_pumpN.rds")
PRA_QUAR_TAG    <- "20260828_sigma_inflation_adopted"
PRA_CAUSE_COMMIT<- "2153bd6"    # ADOPT OPTION 5 -- the commit that changed the objective
PRA_QUAR_DIR    <- ccx_path("calibration", "output", "quarantine", PRA_QUAR_TAG)
PRA_PROC_PAT    <- "run_modefind_pump_arms_FROZEN"   # the running refit
PRA_PATHS_R     <- ccx_path("R", "paths.R")
PRA_TEST_R      <- ccx_path("tests", "testthat", "test-mode-file.R")
PRA_LOGDIR      <- file.path(PRA_NEW_DIR, "post_refit_logs")
PRA_MOVERS_N    <- 6            # per-parameter prior movers to name in `read`
PRA_NOISE_FLOOR <- 0.70         # log-units; the h_ml roughness floor (handoff §2)
# The SHIPPED h_ml support, read from the table rather than written as [30, 200]:
# a literal here would silently disagree with R/calibrate.R the day it changes,
# which is the whole class of bug the band-decode incident was.
PRA_HML_SUPPORT <- c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)
PRA_STAGES      <- c("check", "read", "quarantine", "repoint", "rerun")

# The §4.3-4.4 re-runs. `recompute_hessian.R` is called WITHOUT --update: it
# then writes its own *_hess.rds and does NOT mutate the fresh mode file, which
# is a decision to take deliberately after reading its gates, not as a side
# effect of this script. diag_hess_eps_21par.R is re-run because the kink count
# changed (26 in the full support, against the 3 it was written for) -- but see
# the bound check in stage `rerun`: it mirrors the RETIRED band and its results
# are provenance until that constant is widened.
PRA_RERUN <- list(
  list(script = "calibration/recompute_hessian.R",         why = "§4.3 second-order block at the new mode"),
  list(script = "calibration/diag_hess_eps_21par.R",       why = "§4.3 the kink count changed"),
  list(script = "calibration/diag_design_gates_at_mode.R", why = "§4.4 no gate verdict is current"),
  list(script = "calibration/diag_design_gates_unscored.R",why = "§4.4"),
  list(script = "calibration/diag_joos_irf.R",             why = "§4.4")
)
# §4.5: the four drivers that MIRROR the refit's old bound. They are NOT run
# here. Re-running them as they stand would produce numbers under a band that
# no longer exists and file them beside post-adoption results -- worse than not
# running them, because they would look current. Widening their bound is a
# separate, reviewed edit; stage `rerun` reports which still carry it.
PRA_MIRRORS <- c("calibration/diag_hess_eps_21par.R", "calibration/diag_stream_neff.R",
                 "calibration/diag_ridge_reparam.R",  "calibration/diag_landed_gap_streams.R")

ARGS      <- commandArgs(TRUE)
PRA_STAGE <- local({
  a <- grep("^--stage=", ARGS, value = TRUE)
  if (!length(a)) return(PRA_STAGES)
  s <- sub("^--stage=", "", a[1])
  if (!s %in% PRA_STAGES)
    stop("unknown --stage='", s, "'; one of: ", paste(PRA_STAGES, collapse = ", "))
  s
})
# RETIRING pin90 IS THE DEFAULT since 2026-08-28 (Marcus). It is as
# pre-adoption as `from90` and just as non-comparable, and the cost of retiring
# it was measured to be far smaller than first reported: only TWO files call
# ccx_mode_file("pin90") -- diag_design_gates_unscored.R (already written as an
# OPTIONAL read, and now guarded so it degrades instead of stopping) and
# diag_landed_gap_streams.R, whose every other arm (`ref`, `from90`) is retired
# by the same objective change anyway. The earlier "six diagnostics" count was
# filename matches, not call sites: diag_stream_neff.R and seed_fert_ridge_arms.R
# mean `ridge_pin90`, a DIFFERENT arm, and diag_design_gates_at_mode.R only
# names it in comments. `--keep-pin90` still overrides, and is what to pass if
# you want the +11.6698 pinned-prior offset reproducible from a live run rather
# than only cited in comments.
PRA_PIN90 <- local({
  keep <- "--keep-pin90" %in% ARGS; retire <- "--retire-pin90" %in% ARGS
  if (keep && retire) stop("--keep-pin90 and --retire-pin90 are contradictory")
  if (keep) "keep" else "retire"
})

sep  <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
ok   <- function(...) cat(sprintf("OK    %s\n", sprintf(...)))
warn <- function(...) cat(sprintf("⚠     %s\n", sprintf(...)))

cat(sprintf("POST-REFIT ADOPTION -- handoff_2026-08-28c §4.2-4.5\n"))
cat(sprintf("new mode  %s  (name '%s')\n", PRA_NEW_MODE, PRA_NEW_NAME))
cat(sprintf("incumbent %s  (name '%s') -> quarantine/%s\n",
            PRA_OLD_MODE, PRA_OLD_NAME, PRA_QUAR_TAG))
cat(sprintf("stages    %s\n", paste(PRA_STAGE, collapse = ", ")))

# =====================================================================
# STAGE check -- REFUSE TO START ON AN UNFINISHED REFIT
# =====================================================================
# Each of these is a way the run can look done and not be. A mode file EXISTS
# from the moment the directory was seeded -- it was a byte copy of the
# incumbent -- so "the file is there" proves nothing at all, and its mtime
# against the incumbent's is the check that actually discriminates.
if ("check" %in% PRA_STAGE) {
  sep("check -- preconditions")
  running <- suppressWarnings(system2("pgrep", c("-f", PRA_PROC_PAT),
                                      stdout = TRUE, stderr = FALSE))
  if (length(running))
    stop("the refit is STILL RUNNING (pid ", paste(running, collapse = " "), "). ",
         "Every stage below reads or moves the files it is writing. Wait for it.")
  ok("no '%s' process is running", PRA_PROC_PAT)

  for (f in c(PRA_NEW_MODE, PRA_NEW_CMP, PRA_NEW_LOG))
    if (!file.exists(f)) stop("the refit did not finish: missing ", f)
  ok("mode, comparison and log are all on disk")

  if (!isTRUE(file.mtime(PRA_NEW_MODE) > file.mtime(PRA_OLD_MODE)))
    stop("the new mode file is NOT newer than the incumbent -- this is still the ",
         "SEEDED COPY, not a result. The refit wrote nothing.")
  ok("the mode file was rewritten (%s)", format(file.mtime(PRA_NEW_MODE)))

  tl <- tail(readLines(PRA_NEW_LOG, warn = FALSE), 40)
  if (!any(grepl("^written:", tl)))
    stop("the log does not end with the comparison write -- the run was killed ",
         "or errored. Read ", PRA_NEW_LOG)
  ok("the log ends with the comparison write")

  md <- readRDS(PRA_NEW_MODE)
  if (!identical(md$param_names, CCX_PARAM_NAMES))
    stop("the new mode was fitted on a DIFFERENT parameter set")
  # The band the file records is what ccx_mode_params() re-decodes u_mode under.
  # If the refit had written the retired band here, every downstream decode
  # would be corrupted -- handoff §1's warning, checked rather than trusted.
  if (!isTRUE(all.equal(as.numeric(md$hml_bound), as.numeric(PRA_HML_SUPPORT))))
    stop("the new mode records hml_bound = [", paste(md$hml_bound, collapse = ", "),
         "], not the SHIPPED support [", paste(PRA_HML_SUPPORT, collapse = ", "),
         "]. Every ccx_mode_params() decode downstream would be wrong.")
  ok("hml_bound records the shipped support [%g, %g]", PRA_HML_SUPPORT[1], PRA_HML_SUPPORT[2])
}

# =====================================================================
# STAGE read -- WHAT THE REFIT BOUGHT, DECOMPOSED. NOT a formality.
# =====================================================================
# THE COMPARISON IS RUN AT A COMMON OBJECTIVE. The incumbent's STORED logpost
# was computed under the pre-adoption objective and is not comparable with the
# new one by subtraction -- so both vectors are re-evaluated HERE, under the
# current likelihood and the shipped band. `par_mode` is band-INDEPENDENT, which
# is why the incumbent can be re-encoded at all; `u_mode` could not
# (memory ccx_hml_band_provenance). Never quote an absolute logpost from a live
# harness against a stored one; a MATCHED pair like this is the honest form.
if ("read" %in% PRA_STAGE) {
  sep("read -- prior / jacobian / loglik, at a COMMON objective")
  md_new <- readRDS(PRA_NEW_MODE); md_old <- readRDS(PRA_OLD_MODE)
  p_new  <- ccx_mode_params(md_new); p_old <- ccx_mode_params(md_old)

  # Re-encode both into the CURRENT table's unconstrained coordinate.
  # ccx_par_to_unc() takes the WHOLE parameter list and returns the named
  # vector, which is also what re-encodes h_ml under the SHIPPED band rather
  # than the band either file was fitted under.
  u_new <- ccx_par_to_unc(p_new); u_old <- ccx_par_to_unc(p_old)

  lp_fun <- ccx_make_logpost()
  tot <- c(old = lp_fun(u_old), new = lp_fun(u_new))

  # The same prior + jacobian sum ccx_make_logpost() forms internally, per
  # parameter, so the movers can be NAMED rather than inferred from the total.
  parts <- function(u) {
    pv <- ccx_unc_to_par(u)
    pr <- vapply(CCX_PARAM_NAMES, function(n)
      CCX_PARAM_TABLE[[n]]$prior(pv[[n]]), numeric(1))
    # `.log_jac` is R/calibrate.R's own internal -- deliberately the SAME
    # function ccx_make_logpost() calls, not a reimplementation of it. A second
    # copy of the Jacobian here could disagree with the objective silently.
    jc <- vapply(CCX_PARAM_NAMES, function(n)
      .log_jac(u[[n]], CCX_PARAM_TABLE[[n]]), numeric(1))
    list(prior = pr, jac = jc)
  }
  a <- parts(u_old); b <- parts(u_new)
  d_prior <- sum(b$prior) - sum(a$prior)
  d_jac   <- sum(b$jac)   - sum(a$jac)
  d_tot   <- tot[["new"]] - tot[["old"]]
  d_ll    <- d_tot - d_prior - d_jac

  cat(sprintf("\nlogpost at a COMMON objective:  old %.3f   new %.3f\n",
              tot[["old"]], tot[["new"]]))
  cat(sprintf("DELTA (new - old): logpost %+.3f = prior %+.3f  jac %+.3f  loglik %+.3f\n",
              d_tot, d_prior, d_jac, d_ll))
  cat(sprintf("(for reference, the STORED values are %.3f and %.3f -- NOT comparable,\n",
              md_old$logpost, md_new$logpost))
  cat( " they were computed under two different objectives; the pair above is.)\n")

  # THE READING RULE, applied rather than left to the reader.
  if (d_ll < 0 && d_tot > 0)
    warn(paste("THE FIT GOT WORSE (loglik %+.3f) AND THE TOTAL ROSE ANYWAY.",
               "This is the smoke test's signature: the gain is being PAID BY",
               "THE PRIOR, not earned on the data. Do not report the new mode",
               "as a better fit."), d_ll)
  if (d_ll > 0) ok("the likelihood improved (%+.3f) -- the gain is not purely prior credit", d_ll)

  mv <- (b$prior + b$jac) - (a$prior + a$jac)
  mv <- sort(mv[order(-abs(mv))][seq_len(min(PRA_MOVERS_N, length(mv)))], decreasing = TRUE)
  cat("\nprior+jac movers (largest |change| first):\n")
  for (n in names(mv)) cat(sprintf("   %-18s %+8.3f\n", n, mv[[n]]))

  cat(sprintf("\nh_ml   %.2f m -> %.2f m   (shipped support [%g, %g])\n",
              p_old$h_ml, p_new$h_ml, PRA_HML_SUPPORT[1], PRA_HML_SUPPORT[2]))
  if (abs(p_new$h_ml - p_old$h_ml) > 10)
    warn(paste("h_ml moved %.1f m. Read the decomposition above BEFORE calling",
               "this a result -- the smoke test moved it 61 m on prior credit",
               "alone. And note the objective is piecewise-C1 in h_ml: 26 kinks",
               "survive in the support against a %.2f log-unit noise floor."),
         p_new$h_ml - p_old$h_ml, PRA_NOISE_FLOOR)

  # The three rows the adoption is ABOUT -- their inflation at the landed depth.
  # ccx_ocean_grad_scored() scores the TRANSIENT at the observations' epoch, so
  # it needs a model run and its spinup -- it cannot be evaluated from the
  # parameter list alone (Marcus 2026-08-16; unlike `deep`, it is not free).
  # THE PARAMETER LIST MUST BE MERGED ONTO THE DEFAULTS FIRST. ccx_mode_params()
  # returns the 21 FITTED names only; ccx_spinup() needs the whole set and dies
  # inside ccx_dic_for_pco2()'s uniroot on a zero-length argument if handed the
  # short list -- a failure that names neither the missing parameter nor this
  # line. ccx_make_logpost() does exactly this merge internally, which is why
  # the objective evaluates fine on the same vector; mirrored here rather than
  # re-derived. Caught by the closure test, not by review.
  # TWO PARAMETER LISTS, AND THEY ARE NOT INTERCHANGEABLE -- this mirrors
  # ccx_make_logpost() rather than re-deriving it, because getting it wrong is
  # silent in one direction and cryptic in the other:
  #   p_full  the MODEL's parameters: the fitted names merged ONTO the defaults.
  #           ccx_spinup() needs the whole set and dies inside ccx_dic_for_pco2()'s
  #           uniroot on a zero-length argument if handed the 21 alone.
  #   p_new   the FITTED list. `bomb_total` and `luc_scale` must come from HERE:
  #           they are not in ccx_default_params(), so the intersect() merge
  #           silently DROPS them and the forcing columns become numeric(0).
  # Both bugs were found by the closure test below, not by reading the code.
  p_full <- local({
    q <- ccx_default_params()
    for (n in intersect(names(q), CCX_PARAM_NAMES)) q[[n]] <- p_new[[n]]
    q$gamma_enso <- p_new$gamma_enso
    q
  })
  og <- local({
    sp <- ccx_spinup(p_full)
    F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                            bomb_total_kmol = 102)
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- F$c14_bomb * (p_new$bomb_total / 102)
    for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * p_new$luc_scale
    attr(F, "luc_scale") <- p_new$luc_scale
    ccx_ocean_grad_scored(ccx_run_fast(sp, F)$out, sp)
  })
  # ccx_ocean_grad_scored() returns a LIST (dic, d13c, alk, sd_eff, h_ml), not a
  # data.frame -- `og[, cols]` fails with "incorrect number of dimensions". The
  # observed sigmas come from ccx_ocean_gradient_target(), as
  # run_modefind_pump_arms.R:228-231 does it.
  if (!is.null(og$sd_eff)) {
    tg <- ccx_ocean_gradient_target()
    cat("\nocean-gradient rows at the landed h_ml (option 5's own rows):\n")
    cat(sprintf("   %-5s model %10.4f   target %10.4f   sd %8.4f   sd_eff %8.4f   ratio %.3f\n",
                c("dic", "d13c", "alk"),
                c(og$dic, og$d13c, og$alk),
                vapply(c("dic","d13c","alk"), function(k) tg[[k]]$target, numeric(1)),
                vapply(c("dic","d13c","alk"), function(k) tg[[k]]$sd,  numeric(1)),
                og$sd_eff[c("dic","d13c","alk")],
                og$sd_eff[c("dic","d13c","alk")] /
                  vapply(c("dic","d13c","alk"), function(k) tg[[k]]$sd, numeric(1))))
  }

  # kz has railed at its bracket top in every run for weeks. State it either way.
  kzb <- CCX_PARAM_TABLE$kz; frac <- (p_new$kz - kzb$lo) / (kzb$hi - kzb$lo)
  cat(sprintf("\nkz  %.1f  = %.1f%% of the bracket [%g, %g]  -- %s\n",
              p_new$kz, 100 * frac, kzb$lo, kzb$hi,
              if (frac > 0.95) "STILL RAILS (unchanged, again)" else "off the rail"))
}

# =====================================================================
# STAGE quarantine -- MOVE THE INCUMBENT, WITH ITS REASON
# =====================================================================
# Order matters and is the reason this is a script. The incumbent may NOT be
# moved before a replacement exists (it would break ccx_mode_file(), the app and
# every diagnostic at once) and may NOT be left at its canonical path after one
# does (silent retrieval of a pre-adoption vector). `git mv` rather than file
# copy: the directory is TRACKED, and a copy would leave the original staged for
# deletion in a way that reads as data loss in review.
if ("quarantine" %in% PRA_STAGE) {
  sep("quarantine -- the incumbent out, with a README")
  if (!dir.exists(PRA_OLD_DIR)) {
    ok("already quarantined (%s is gone)", PRA_OLD_DIRNAME)
  } else {
    dir.create(PRA_QUAR_DIR, recursive = TRUE, showWarnings = FALSE)
    dest <- file.path(PRA_QUAR_DIR, PRA_OLD_DIRNAME)
    st <- system2("git", c("mv", shQuote(PRA_OLD_DIR), shQuote(dest)))
    if (st != 0) stop("git mv failed; the tree is untouched")
    ok("git mv %s -> quarantine/%s/", PRA_OLD_DIRNAME, PRA_QUAR_TAG)

    writeLines(c(
      sprintf("# QUARANTINE %s -- superseded by the option-5 (sigma-inflation) refit", PRA_QUAR_TAG),
      "",
      "## 1. WHICH BUG / CHANGE APPLIES",
      "",
      "NOT a bug -- a deliberate OBJECTIVE CHANGE. Option 5 was adopted 2026-08-28",
      "(handoff_2026-08-28c): the three ocean-gradient rows are now scored at",
      "`sigma_eff(h_ml)` at EVERY `h_ml`, and the `[85, 120]` skip that made them",
      "vanish outside the band is RETIRED. The skip was worth **+7.3005 and +8.4257**",
      "log-units at the two edges -- a cliff in the posterior's SOFTEST direction,",
      "which is why there has never been a converged posterior.",
      "",
      "⇒ **Everything here was fitted on a DIFFERENT objective and is NOT comparable**",
      "with anything fitted since. Its logpost cannot be subtracted from a",
      "post-adoption one. Its per-stream table describes rows that no longer skip.",
      "",
      "## 2. WHAT IS IN HERE",
      "",
      sprintf("`%s/` -- the arm-N mode file (logpost -1544.615, `fert_k` 154.85,", PRA_OLD_DIRNAME),
      "`h_ml` 96.47 m), its progress file, its Hessian/comparison rds, run log and README.",
      "It was the CANONICAL mode from 2026-08-26 to 2026-08-28 and is the vector the",
      sprintf("replacement was WARM-STARTED from (`par_mode` is band-independent)."),
      "",
      "## 3. THE CANONICAL POST-CHANGE REPLACEMENT",
      "",
      sprintf("`calibration/output/%s/mode_fit_pumpN.rds`", PRA_NEW_DIRNAME),
      sprintf("resolved as `ccx_mode_file(\"%s\")`, which is `CCX_MODE_CANONICAL`.", PRA_NEW_NAME),
      "Do not point anything here except a deliberate before/after comparison",
      "(`diag_gates_at_landed_modes.R` is the one driver allowed to name a quarantined path).",
      "",
      sprintf("Moved by `calibration/run_post_refit_adoption.R` on %s.", format(Sys.Date()))
    ), file.path(PRA_QUAR_DIR, "README.md"))
    ok("wrote %s/README.md", PRA_QUAR_TAG)
  }
}

# =====================================================================
# STAGE repoint -- R/paths.R, ITS TEST, AND THEN THE WHOLE SUITE
# =====================================================================
if ("repoint" %in% PRA_STAGE) {
  sep("repoint -- ccx_mode_file()")

  # ---- THE CHOICE THIS SCRIPT REFUSES TO MAKE SILENTLY --------------
  # `pin90` is the PINNED arm of the same 2026-08-25f refit. It is exactly as
  # pre-adoption as `from90` and exactly as non-comparable -- but unlike
  # `from90` nothing is replacing it, and six diagnostics name it
  # (diag_design_gates_at_mode, _unscored, diag_stream_neff, diag_landed_gap_streams,
  # diag_gates_at_landed_modes, seed_fert_ridge_arms). So:
  #   --retire-pin90  correct semantics; those six then fail LOUDLY, which is
  #                   the outcome R/paths.R's own header argues for, and the
  #                   `+11.6698` pinned-prior offset that diag_landed_gap_streams
  #                   computes stops being available until they are re-fitted.
  #   --keep-pin90    nothing breaks today, and a vector fitted on a retired
  #                   objective stays resolvable BY NAME -- precisely the silent
  #                   failure the mode registry exists to prevent.
  # There is no default. Methodological choices are explicit.
  cat(sprintf("pin90: %s%s\n", PRA_PIN90,
              if (any(c("--keep-pin90", "--retire-pin90") %in% ARGS)) " (explicit)"
              else " (DEFAULT -- pass --keep-pin90 to override)"))
  if (PRA_PIN90 == "retire")
    cat(paste0("  ⇒ ccx_mode_file(\"pin90\") will ERROR with its reason. The one live\n",
               "    reader left is diag_landed_gap_streams.R, a PRE-ADOPTION driver whose\n",
               "    other arms are retired by the same change; it needs a decision, not a\n",
               "    rename. The +11.6698 pinned-prior offset stops being reproducible from\n",
               "    a live run -- if that matters, STORE it rather than keeping the arm.\n"))

  sub1 <- function(path, old, new) {           # exactly-one-match or it stops
    s <- readLines(path, warn = FALSE); txt <- paste(s, collapse = "\n")
    n <- length(gregexpr(old, txt, fixed = TRUE)[[1]])
    if (!nzchar(old) || n != 1L || attr(gregexpr(old, txt, fixed = TRUE)[[1]], "match.length")[1] < 0)
      stop("refusing to edit ", basename(path), ": the anchor matched ",
           if (n == 1L) 0L else n, " times, not once.\nANCHOR:\n", old)
    writeLines(strsplit(sub(old, new, txt, fixed = TRUE), "\n", fixed = TRUE)[[1]], path)
    ok("%s: replaced one block", basename(path))
  }

  files_new <- if (PRA_PIN90 == "keep")
    sprintf(paste0('CCX_MODE_FILES <- c(\n',
      '  %s = file.path("calibration", "output", "%s",\n',
      '                     "mode_fit_pumpN.rds"),\n',
      '  pin90  = file.path("calibration", "output", "refit_20260825f_pin90",\n',
      '                     "mode_fit_pumpN.rds")\n)'), PRA_NEW_NAME, PRA_NEW_DIRNAME)
  else
    sprintf(paste0('CCX_MODE_FILES <- c(\n',
      '  %s = file.path("calibration", "output", "%s",\n',
      '                     "mode_fit_pumpN.rds")\n)'), PRA_NEW_NAME, PRA_NEW_DIRNAME)

  sub1(PRA_PATHS_R,
       'CCX_MODE_CANONICAL <- "from90"',
       sprintf('CCX_MODE_CANONICAL <- "%s"', PRA_NEW_NAME))
  sub1(PRA_PATHS_R,
       paste0('CCX_MODE_FILES <- c(\n',
              '  from90 = file.path("calibration", "output", "refit_20260825f_from90",\n',
              '                     "mode_fit_pumpN.rds"),\n',
              '  pin90  = file.path("calibration", "output", "refit_20260825f_pin90",\n',
              '                     "mode_fit_pumpN.rds")\n)'),
       files_new)
  sub1(PRA_PATHS_R,
       'CCX_MODE_PINNED <- c(from90 = FALSE, pin90 = TRUE)',
       if (PRA_PIN90 == "keep")
         sprintf('CCX_MODE_PINNED <- c(%s = FALSE, pin90 = TRUE)', PRA_NEW_NAME)
       else sprintf('CCX_MODE_PINNED <- c(%s = FALSE)', PRA_NEW_NAME))

  # ---- the retirement entries ---------------------------------------
  # Mechanical since 2026-08-28: CCX_MODE_RETIRED carries a reason PER ARM, so
  # an arm retired by option 5 states option 5's cause commit and option 5's
  # quarantine directory instead of inheriting the isotope fix's. Before that
  # refactor this was a hand edit to a shared error string, which is why it was
  # done first. test-mode-file.R asserts each entry names a quarantine path and
  # a cause commit, so a malformed addition here fails the suite below.
  ret_entry <- function(nm, what) sprintf(paste0(
    '  %s = paste("%s, retired by the 2026-08-28 adoption of option 5",\n',
    '              "(sigma-inflation, `%s`), which changed the objective:",\n',
    '              "the ocean-gradient rows are now scored at every h_ml.",\n',
    '              "Quarantined under",\n',
    '              "calibration/output/quarantine/%s/")'),
    nm, what, PRA_CAUSE_COMMIT, PRA_QUAR_TAG)

  # The LAST entry's closing line plus the vector's closing paren. That path
  # string appears three times (N, D and ref all name it); only ref's is
  # followed by the paren, so this two-line form is what makes the anchor unique
  # and sub1() would refuse it otherwise.
  tail_last  <- '              "calibration/output/quarantine/20260825_seas_isotope_rectification/")'
  tail_anchor <- paste0(tail_last, "\n)")
  adds <- ret_entry(PRA_OLD_NAME,
                    "the FREE arm of refit_20260825f and the canonical mode 2026-08-26 to 2026-08-28")
  if (PRA_PIN90 == "retire")
    adds <- paste(adds, ret_entry("pin90",
      "the fert_k-PINNED arm of refit_20260825f (its stored logpost carries a +11.6698 near-delta prior)"),
      sep = ",\n")
  sub1(PRA_PATHS_R, tail_anchor, paste0(tail_last, ",\n", adds, "\n)"))

  cat("\n⚠ ONE EDIT IS NOT MECHANICAL AND IS LEFT TO YOU:\n")
  cat("  tests/testthat/test-mode-file.R's last test asserts\n",
      "    expect_gt(lp[['pin90']], lp[[CCX_MODE_CANONICAL]])\n",
      "  -- comparing two STORED logposts. Across the objective change that\n",
      "  comparison is MEANINGLESS, not merely false, and under --retire-pin90\n",
      "  pin90 is not resolvable at all. Rewrite the test's PREMISE (the trap it\n",
      "  encodes is that a stored number decides an arm; that is still worth\n",
      "  asserting, just not across two objectives). Do NOT relax it to green.\n")

  sep("repoint -- the suite")
  st <- system2("Rscript", "tests/run_tests.R")
  if (st != 0) stop("THE SUITE FAILED after the repoint. Do not proceed to `rerun`, ",
                    "and do not edit a test to make it pass -- report it.")
  ok("suite green")
}

# =====================================================================
# STAGE rerun -- §4.3-4.4 AT THE NEW MODE
# =====================================================================
if ("rerun" %in% PRA_STAGE) {
  sep("rerun -- the Hessian pair and the design gates")
  dir.create(PRA_LOGDIR, recursive = TRUE, showWarnings = FALSE)

  # §4.5, reported rather than run. A mirror still carrying the retired band
  # would file pre-adoption numbers beside post-adoption ones.
  # COMMENT LINES DO NOT COUNT. Three of the four were widened on 2026-08-28 and
  # each still NAMES the retired constant in a comment explaining what it used to
  # do -- which is provenance, and is the thing to keep. What makes a file stale
  # is reading it on a LIVE line to configure a run. A grep that cannot tell those
  # apart would report all four forever and the warning would stop being read.
  # EXEMPTIONS, DECLARED rather than pattern-matched, so a third one is a visible
  # decision -- same construction as test-mode-file.R's `allowed`. Both of these
  # read the retired band on a LIVE line and both are CORRECT to:
  #   diag_ridge_reparam.R      derives its logpost ladder's -1.5805 shift FROM
  #                             the retired band. It cannot compute the offset
  #                             between two supports without naming both.
  #   diag_landed_gap_streams.R is deliberately NOT widened -- its GATE 1
  #                             reproduces logposts STORED by arms fitted under
  #                             that band, so widening fails it by construction.
  exempt <- c("calibration/diag_ridge_reparam.R", "calibration/diag_landed_gap_streams.R")
  still <- Filter(function(f) {
    if (f %in% exempt) return(FALSE)
    L <- readLines(ccx_path(f), warn = FALSE)
    any(grepl("LIK_OCEAN_GRAD_HML_OK_RETIRED", L) & !grepl("^\\s*#", L))
  }, PRA_MIRRORS)
  cat(sprintf("mirror band sweep: %d of %d still configure on the retired band",
              length(still), length(PRA_MIRRORS)))
  cat(sprintf(" (%d declared exempt)\n", length(exempt)))
  cat("  ⚠ diag_landed_gap_streams.R is a PRE-ADOPTION driver: every arm it reads\n",
      "   is retired by the objective change, so it needs a DECISION (re-point or\n",
      "   quarantine), not a band edit. Its numbers are not current either way.\n")
  if (length(still)) {
    warn("%d of the 4 mirror diagnostics still read the RETIRED band:", length(still))
    for (f in still) cat(sprintf("        %s\n", f))
    cat("      Their results are PROVENANCE until that constant is widened to the\n",
        "     shipped support. Widening it is a reviewed edit, not this script's.\n")
  }

  for (job in PRA_RERUN) {
    lg <- file.path(PRA_LOGDIR, sub("\\.R$", ".log", basename(job$script)))
    cat(sprintf("\n--- %s  (%s)\n    -> %s\n", job$script, job$why, lg))
    t0 <- Sys.time()
    st <- system2("Rscript", job$script, stdout = lg, stderr = lg)
    cat(sprintf("    %s in %.1f min\n", if (st == 0) "done" else sprintf("FAILED (status %d)", st),
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
    if (st != 0) warn("%s failed -- read %s. Later jobs still run.", job$script, lg)
  }
  cat(sprintf("\nlogs in %s\n", PRA_LOGDIR))
}

sep("done")
cat("Remaining by hand: the two paths.R/test edits stage `repoint` names, the\n")
cat("four mirror diagnostics (§4.5), CHANGELOG.md, and the memory sub-index.\n")
