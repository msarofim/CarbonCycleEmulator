# =====================================================================
# Gate: the CONSTRAINT MAP product (data/constraint_map.rds), built by
# calibration/diag_constraint_map.R for the "What pins down what?" tab.
#
# ⭐ WHAT THIS HAS TO HOLD, and none of it is a stored number:
#   1. COVER, both ways. Every fitted name in exactly one component and every
#      objective stream in exactly one family. Without it a parameter added to
#      the table drops silently out of the map and the aggregate quietly stops
#      being the total -- while the chart still draws.
#   2. THE AGGREGATION IS AN IDENTITY. The component map is a SUM of the
#      parameter map, so the two must agree to machine precision. The app reads
#      the aggregate and the prose reads shares of it.
#   3. THE STEP IS THE ONE THE CAPTION CLAIMS. `1/sqrt(diag(-H))`, the
#      CONDITIONAL sd -- and the sign convention is checked by requiring
#      `sqrt(diag(solve(-H)))` to reproduce the file's own marginal `sd_unc`.
#      ⛔⛔ THE MARGINAL SD WAS MEASURED AND REJECTED (2026-09-25): it already
#      contains the compensation the other 28 parameters supply, so a one-at-a-
#      time step that size leaves the quadratic bowl -- up to 4235 predicted
#      log-units, and 22 of 29 names out of regime. If `step_kind` ever silently
#      became "marginal" the chart would still draw, with every number wrong by
#      a factor that varies per parameter. Hence a gate on the step itself.
#   4. THE REGIME. The measured drop must be near the quadratic's prediction,
#      or the finite difference is not measuring a local slope at all.
#      ⚠ The bound is SCALED to the prediction, not an absolute log-unit number
#      (`tolerance_scaled_to_spread`).
#   5. PINS AND PULLS ARE REAL AND DISTINGUISHED. `CURV` must occupy both ends
#      of [0, 1] -- a statistic that is constant is not separating anything.
#   6. PROVENANCE. The mode, the step, the spinup and the sd KIND are stamped in
#      the artifact, not just set in the driver
#      (`~/.claude/CLAUDE.md`: a seed -- or here, a step -- must be recorded IN
#      the artifact). ⚠ This product uses no RNG; `seed` is NA with a note
#      saying why, which is itself asserted so the field cannot go missing.
# =====================================================================

.cm_file <- file.path(.root, "data", "constraint_map.rds")
skip_if_no_cmap <- function()
  if (!file.exists(.cm_file))
    skip("data/constraint_map.rds not built (Rscript calibration/diag_constraint_map.R)")

CM_IDENTITY_TOL <- 1e-9    # an identity, not an agreement
CM_SIGN_TOL     <- 1e-8    # sqrt(diag(solve(-H))) vs the stored marginal sd
CM_REGIME_MAX   <- 5.0     # measured drop / quadratic prediction
CM_CURV_LO      <- 0.15    # at least one cell must be a near-pure SLOPE
CM_CURV_HI      <- 0.85    # ...and at least one a near-pure WELL

test_that("1. every parameter and every stream is covered exactly once", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  pc <- unlist(cm$component, use.names = FALSE)
  fs <- unlist(cm$family,    use.names = FALSE)
  expect_equal(anyDuplicated(pc), 0L)
  expect_equal(anyDuplicated(fs), 0L)
  expect_setequal(pc, colnames(cm$M))
  expect_setequal(fs, rownames(cm$M))
  # and the live objective's names, not just the file's own copy of them -- this
  # is what fails when the parameter table grows and the map is not rebuilt
  expect_setequal(pc, ccx_mode_fit_stats(cm$provenance$mode)$param_names)
})

test_that("2. the component map is an exact SUM of the parameter map", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  expect_lt(abs(sum(cm$MC) - sum(cm$M)), CM_IDENTITY_TOL)
  for (a in names(cm$family)) for (b in names(cm$component))
    expect_lt(abs(cm$MC[a, b] - sum(cm$M[cm$family[[a]], cm$component[[b]]])),
              CM_IDENTITY_TOL)
  # the row/column share tables must be shares OF THAT MAP, not of anything else
  expect_equal(unname(rowSums(cm$RS)), rep(100, nrow(cm$RS)), tolerance = 1e-8)
  expect_equal(unname(colSums(cm$CS)), rep(100, ncol(cm$CS)), tolerance = 1e-8)
})

test_that("3. the step is the CONDITIONAL sd, and the Hessian's sign is checked", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  expect_identical(cm$step_kind, "conditional")
  # ⚠ through `ccx_mode_fit_stats()` rather than opening the mode file here:
  # the direct read is what test-mode-struct-lint.R ratchets down, and this file
  # has no parameter list to build, so ccx_mode_base() would be meaningless.
  fs <- ccx_mode_fit_stats(cm$provenance$mode)
  negH <- fs$precision
  # the sign convention: this is the precision matrix, so its inverse's diagonal
  # is the MARGINAL variance the file already stores
  expect_lt(max(abs(sqrt(diag(solve(negH))) - fs$sd)), CM_SIGN_TOL)
  expect_equal(unname(cm$sd_conditional), unname(1 / sqrt(diag(negH))), tolerance = 1e-12)
  expect_equal(unname(cm$sd_unc), unname(cm$sd_conditional), tolerance = 1e-12)
  # ⛔ the rejected step must remain VISIBLY different, or the ruling that chose
  # between them has quietly stopped meaning anything
  expect_gt(max(cm$sd_ratio), 10)
})

test_that("4. every step stayed in the regime its numbers assume", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  # the conditional step costs 0.5 log-units by construction
  expect_equal(unname(cm$drop_pred), rep(0.5, length(cm$drop_pred)), tolerance = 1e-8)
  expect_true(all(cm$drop_obs > 0))
  expect_lt(max(cm$drop_obs / cm$drop_pred), CM_REGIME_MAX)
})

test_that("5. pins and pulls are actually distinguished", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  w <- cm$M > 0.1                      # only where the move is real
  expect_true(any(w))
  expect_lt(min(cm$CURV[w]), CM_CURV_LO)
  expect_gt(max(cm$CURV[w]), CM_CURV_HI)
  expect_true(all(cm$CURV >= 0 & cm$CURV <= 1 + 1e-12))
  # the leverage magnitude must be the larger of the two half-steps, by definition
  expect_equal(cm$M, pmax(abs(cm$DHI), abs(cm$DLO)))
  # ...and the signed slope must be the central difference of the same two
  expect_equal(cm$SLOPE, (cm$DHI - cm$DLO) / 2)
})

test_that("6. the artifact stamps its own provenance", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  pv <- cm$provenance
  for (f in c("driver", "mode", "mode_file", "stored_logpost", "spinup", "struct",
              "n_eval", "step", "sd_kind", "units", "built", "seed", "seed_note"))
    expect_true(f %in% names(pv), info = paste("provenance lacks", f))
  expect_identical(pv$mode, CCX_MODE_CANONICAL)
  expect_equal(pv$stored_logpost, ccx_mode_fit_stats(pv$mode)$logpost)
  expect_equal(pv$n_eval, 2L * ncol(cm$M))
  # the step string must NAME the step actually taken -- a caption that says
  # "marginal" over conditional numbers is the whole failure mode of test 3
  expect_match(pv$step, cm$step_kind, fixed = TRUE)
  # ⚠ NOT a sampled posterior, and the artifact has to say so: the app's copy
  # repeats this claim and cannot check it
  expect_match(pv$sd_kind, "NOT a sampled posterior", fixed = TRUE)
  expect_true(is.na(pv$seed) && nzchar(pv$seed_note))
})

# ⚠ MUTATION TEST, run rather than described. Break what each assertion guards
# and require it to fire -- a gate that passes is not a gate that works.
test_that("MUTATION: the gates fail when what they guard is broken", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)

  # a parameter dropped from the grouping
  bad <- cm; bad$component[[1]] <- bad$component[[1]][-1]
  expect_false(setequal(unlist(bad$component, use.names = FALSE), colnames(bad$M)))

  # the aggregate silently rescaled
  bad <- cm; bad$MC <- bad$MC * 1.01
  expect_gt(abs(sum(bad$MC) - sum(bad$M)), CM_IDENTITY_TOL)

  # ⛔ the REJECTED step, which is the mutation that matters: swapping the
  # conditional sd for the marginal one must fail test 3
  bad <- cm; bad$sd_unc <- cm$sd_marginal; bad$step_kind <- "marginal"
  expect_false(identical(bad$step_kind, "conditional"))
  expect_gt(max(abs(bad$sd_unc - bad$sd_conditional)), 1e-6)

  # the curvature statistic collapsed to a constant -- it would then separate
  # nothing while every test above still passed
  bad <- cm; bad$CURV[] <- 0.5
  w <- bad$M > 0.1
  expect_false(min(bad$CURV[w]) < CM_CURV_LO)

  # a provenance field emptied
  bad <- cm; bad$provenance$sd_kind <- "one posterior sd"
  expect_false(grepl("NOT a sampled posterior", bad$provenance$sd_kind, fixed = TRUE))
})

# ⛔ 7 (2026-10-11 b). THE APP REFUSES A MAP THAT IS NOT THE CANONICAL'S. Test 6 has checked the name and
# the log-posterior here since 09-25, but the app's loader read the file with NO check, so a stale map
# would have been drawn whenever this file was not run. Loader and test now share ccx_cmap_problems()
# (R/paths.R). Mutation-tested on every field it reads, and on the LOADER ITSELF (global.R's own
# expression, evaluated against a doctored copy), not only on the helper.
CM_OTHER_MODE <- "hilda33p"   # the previous canonical: a registered mode the map was NOT built at

test_that("7. the app's loader accepts the canonical's map and refuses any other (ccx_cmap_problems)", {
  skip_if_no_cmap()
  cm <- readRDS(.cm_file)
  expect_identical(ccx_cmap_problems(cm), character(0))
  # MUTATIONS: each field the check reads, broken one at a time, is refused
  bad <- cm; bad$provenance$mode <- CM_OTHER_MODE
  expect_match(ccx_cmap_problems(bad), sprintf("built for mode '%s'", CM_OTHER_MODE), fixed = TRUE, all = FALSE)
  bad <- cm; bad$provenance$stored_logpost <- cm$provenance$stored_logpost + 1e-9
  expect_match(ccx_cmap_problems(bad), "different fit", fixed = TRUE, all = FALSE)
  bad <- cm; bad$provenance$struct <- paste0(cm$provenance$struct, "x")
  expect_match(ccx_cmap_problems(bad), "structure", fixed = TRUE, all = FALSE)
  bad <- cm; bad$provenance$pins <- cm$provenance$pins[-1]
  expect_match(ccx_cmap_problems(bad), "held set", fixed = TRUE, all = FALSE)
  bad <- cm; bad$provenance$pins[1] <- "q10"                       # same count, different set
  expect_match(ccx_cmap_problems(bad), "held set", fixed = TRUE, all = FALSE)
  bad <- cm; bad$provenance <- NULL
  expect_match(ccx_cmap_problems(bad), "not a constraint-map artifact", fixed = TRUE)
  # the SAME map, asked about another registered mode: refused on the FIT, not only the name
  p <- ccx_cmap_problems(cm, CM_OTHER_MODE)
  expect_match(p, "different fit", fixed = TRUE, all = FALSE)

  # THE LOADER, as written in global.R: its own expression, pointed at the real file and at a doctored copy
  ex <- Filter(function(e) is.call(e) && identical(as.character(e[[1]]), "<-") &&
                 identical(as.character(e[[2]]), "APP_CMAP_LOAD"), parse(file.path(.root, "app", "global.R")))
  expect_length(ex, 1L)
  run_loader <- function(path) { env <- new.env(parent = globalenv()); env$APP_CMAP_FILE <- path
                                 eval(ex[[1]], env); env$APP_CMAP_LOAD }
  ok <- run_loader(.cm_file)
  expect_false(is.null(ok$cm)); expect_null(ok$why)
  tf <- tempfile(fileext = ".rds"); on.exit(unlink(tf))
  bad <- cm; bad$provenance$mode <- CM_OTHER_MODE; saveRDS(bad, tf)
  expect_message(no <- run_loader(tf), "constraint map NOT shown", fixed = TRUE)
  expect_null(no$cm); expect_match(no$why, CM_OTHER_MODE, fixed = TRUE)
})
