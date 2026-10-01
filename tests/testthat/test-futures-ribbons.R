# =====================================================================
# Gate: the Futures tab's uncertainty RIBBONS (data/futures_ribbons.rds).
#
# WHAT IS RULED (Marcus 2026-10-01, review 10-01c B7: "Laplace first, MCMC as
# the check"): a Laplace (Gaussian-at-the-mode) band from 1000 draws, 5-95 %,
# on the van Vuuren futures, labelled "Gaussian approximation at the best fit,
# conditional on the nine held values". calibration/build_futures_ribbons.R
# builds it; the app only reads it.
#
# ⛔ HELD (Marcus 2026-10-01: "Hold the bands (Recommended)"): the band FAILED its own
# check (the draws a median 25 log-units below the Gaussian, importance ESS 8 / 1000;
# calibration/diag_ribbons_linearity.R, diag_laplace_axes.R), so nothing ships in data/
# and the app draws no band while APP_RIBBONS_HOLD is set. What is tested here is (i) the
# hold itself and (ii) the machinery, on the HELD EVIDENCE artifact in outputs/diagnostics/
# -- so the day the MCMC posterior goes through the same driver, its checks already exist.
#
# ⛔ WHAT THIS GUARDS. A band is a claim about the FIT it surrounds. Built at one
# parameter vector and drawn around another's line, it would look exactly as
# plausible and be wrong -- so the artifact must name the vector it was built
# at, and ccx_ribbons_problems() (the app's loader uses the same function)
# compares the VECTOR, not the mode's name: a refit that kept the name would
# otherwise pass. And the artifact must carry what reproducing it needs (the
# seed, the RNG kind, where the seed is applied), per ~/.claude/CLAUDE.md.
#
# ⚠ MUTATION-TESTED below: each failure the check exists for is fed to it.
# =====================================================================

.fr_file   <- file.path(.root, "outputs", "diagnostics", "futures_ribbons_laplace_held_20261001.rds")
.fr_global <- file.path(.root, "app", "global.R")
# the tab's scenario ids and y-variables, PARSED out of global.R (pure literals;
# sourcing it would compile the core and run a spin-up)
.fr_env <- new.env(parent = baseenv())
if (file.exists(.fr_global))
  for (e in parse(.fr_global))
    if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
        is.name(e[[2]]) && as.character(e[[2]]) %in% c("APP_SCENARIOS", "APP_FUTURE_YVARS", "APP_RIBBONS_HOLD"))
      eval(e, .fr_env)
.fr_have <- file.exists(.fr_file)
.fr <- if (.fr_have) readRDS(.fr_file) else NULL
.fr_md <- CCX_MODE_CANONICAL   # by NAME: ccx_ribbons_problems() reads the file itself

FR_N_RULED     <- 1000                       # the ruled draw count
FR_PROBS_RULED <- c(0.05, 0.50, 0.95)        # the ruled band (+ the median)

test_that("the band is HELD: the app draws none, whatever sits in data/", {
  skip_if_not(file.exists(.fr_global), "app/global.R is not present")
  expect_true(is.character(.fr_env$APP_RIBBONS_HOLD) && nzchar(.fr_env$APP_RIBBONS_HOLD),
              info = "APP_RIBBONS_HOLD was lifted: that needs a ruling (and the MCMC check)")
  g <- paste(readLines(.fr_global, warn = FALSE), collapse = "\n")
  # the loader returns before it reads any file while the hold is set
  expect_true(grepl("if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE", g, fixed = TRUE))
  # MUTATION: a loader without the guard is caught by the same match
  g2 <- sub("if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE", "", g, fixed = TRUE)
  expect_false(grepl("if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE", g2, fixed = TRUE))
})

test_that("the held evidence was built for THIS fit (the app's own validity check)", {
  skip_if_not(.fr_have, "the held Laplace evidence artifact is absent")
  p <- ccx_ribbons_problems(.fr, .fr_md, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)
  expect_equal(p, character(0), info = paste(p, collapse = " | "))
})

test_that("the artifact records the ruled method and what reproducing it needs", {
  skip_if_not(.fr_have, "no ribbons artifact")
  pv <- .fr$provenance
  expect_equal(pv$n_draws, FR_N_RULED)
  expect_equal(pv$probs, FR_PROBS_RULED)
  expect_match(pv$label, "^Gaussian approximation at the best fit, conditional on the .+ held values$")
  expect_equal(pv$n_held, length(ccx_mode_pins(.fr_md)))
  expect_true(is.numeric(pv$seed) && length(pv$seed) == 1L && is.finite(pv$seed))
  expect_length(pv$rng_kind, 3L)
  expect_match(pv$seed_applied, "immediately before", fixed = TRUE)
  # a censored sample would draw a band from the draws that happened to run
  expect_lt(pv$n_failed, 0.01 * pv$n_draws)
  # the draw machinery reproduced the app's own central line before it drew
  expect_lt(pv$central_check_max_abs, pv$central_check_tol)
  # the bands' central column IS that line: the median and the mode need not agree, the line must
  expect_true(all(is.finite(.fr$bands$central)))
})

test_that("every scenario's band has width at the end of the run, in both variables", {
  skip_if_not(.fr_have, "no ribbons artifact")
  b <- .fr$bands
  last <- b[b$year == max(b$year), ]
  expect_equal(nrow(last), length(.fr_env$APP_SCENARIOS) * length(.fr_env$APP_FUTURE_YVARS))
  expect_true(all(last$q95 - last$q05 > 0),
              info = "a zero-width band at the run's end means the draws did not move the future")
})

# ---------------------------------------------------------------------
# MUTATION TESTS -- feed the check each failure it exists for
# ---------------------------------------------------------------------
test_that("MUTATION: bands built at a DIFFERENT parameter vector are rejected", {
  skip_if_not(.fr_have, "no ribbons artifact")
  bad <- .fr; bad$provenance$par_mode$q10 <- bad$provenance$par_mode$q10 * 1.01
  p <- ccx_ribbons_problems(bad, .fr_md, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)
  expect_true(any(grepl("different parameter vector", p, fixed = TRUE)))
})

test_that("MUTATION: a missing scenario, a missing seed and disordered quantiles are each rejected", {
  skip_if_not(.fr_have, "no ribbons artifact")
  chk <- function(r) ccx_ribbons_problems(r, .fr_md, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)
  b1 <- .fr; b1$bands <- b1$bands[b1$bands$scenario != .fr_env$APP_SCENARIOS[[1]], ]
  expect_true(any(grepl("no bands for scenario", chk(b1), fixed = TRUE)))
  b2 <- .fr; b2$provenance$seed <- NULL
  expect_true(any(grepl("seed", chk(b2), fixed = TRUE)))
  b3 <- .fr; i <- which(b3$bands$year == max(b3$bands$year))[1]
  b3$bands$q05[i] <- b3$bands$q95[i] + 1
  expect_true(any(grepl("out of order", chk(b3), fixed = TRUE)))
  b4 <- .fr; b4$provenance$mode <- "hilda29l"
  expect_true(any(grepl("built for mode 'hilda29l'", chk(b4), fixed = TRUE)))
})
