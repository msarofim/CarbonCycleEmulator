# =====================================================================
# Gate: the Futures tab's uncertainty RIBBONS (data/futures_ribbons.rds).
#
# WHAT IS RULED.
# - 2026-10-01 (review 10-01c B7, "Laplace first, MCMC as the check"): a Laplace band, 1000 draws, 5-95 %.
#   It FAILED its own check (importance ESS 8 / 1000) and was HELD ("Hold the bands"); it is kept as
#   EVIDENCE in outputs/diagnostics/, built at hilda33d.
# - 2026-10-09 (Marcus): "Ship the 200k band (Recommended)". The MCMC band at hilda29e: four chains to
#   200 000 iterations, window (30000, 200000], thin 20, pooled thinned x2 within chain = 17 000 draws,
#   each run through the full model by calibration/build_futures_ribbons.R and PROMOTED into data/ by
#   calibration/promote_futures_ribbons.R (bands untouched, chain seeds recorded, key_draws dropped).
#
# ⛔ THE HOLD IS LIFTED ONLY WITH THE COPY. Three things in the app say there is no band: the band's
# own label (app copy once shown: "Shaded: ... — a <label>."), card 6's title, and the parameter
# panel's "not yet a posterior" clause (app/global.R). All three are Marcus's words. .fr_lift_problems()
# lists what still blocks a lift; it is asserted EMPTY whenever the hold is NULL, and mutation-tested by
# simulating a lift on today's texts.
#
# ⛔ WHAT THIS GUARDS. A band is a claim about the FIT it surrounds. Built at one parameter vector and
# drawn around another's line, it would look exactly as plausible and be wrong -- so the artifact must
# name the vector it was built at, and ccx_ribbons_problems() (the app's loader uses the same function)
# compares the VECTOR, not the mode's name. And the artifact must carry what reproducing it needs (for
# MCMC draws: the chains' seeds, RNG kind and where the seed is applied), per ~/.claude/CLAUDE.md.
#
# ⚠ MUTATION-TESTED below: each failure the check exists for is fed to it.
# =====================================================================

.fr_ship_file <- file.path(.root, "data", "futures_ribbons.rds")
.fr_src_file  <- file.path(.root, "outputs", "diagnostics", "futures_ribbons_mcmc_20261009_hilda29e_200k.rds")
.fr_lap_file  <- file.path(.root, "outputs", "diagnostics", "futures_ribbons_laplace_held_20261001.rds")
.fr_global    <- file.path(.root, "app", "global.R")
.fr_review    <- file.path(.root, "app", "R", "review.R")
# the tab's scenario ids and y-variables, PARSED out of global.R (pure literals; sourcing it would
# compile the core and run a spin-up)
.fr_env <- new.env(parent = baseenv())
if (file.exists(.fr_global))
  for (e in parse(.fr_global))
    if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
        is.name(e[[2]]) && as.character(e[[2]]) %in% c("APP_SCENARIOS", "APP_FUTURE_YVARS", "APP_RIBBONS_HOLD"))
      eval(e, .fr_env)
.fr_ship_have <- file.exists(.fr_ship_file)
.fr_ship <- if (.fr_ship_have) readRDS(.fr_ship_file) else NULL
.fr_lap_have <- file.exists(.fr_lap_file)
.fr_lap <- if (.fr_lap_have) readRDS(.fr_lap_file) else NULL
# THE MODES, by NAME, never read back from the artifacts (a check of an artifact against its own label
# would pass whatever it said). ccx_ribbons_problems() reads each mode file itself.
.fr_ship_md <- "hilda29e"   # the canonical the band was ruled for (10-09); a new canonical must REFUSE it
.fr_lap_md  <- "hilda33d"   # the held Laplace evidence (re-expressed 2026-10-03 h, "Approve all")

FR_PROBS_RULED    <- c(0.05, 0.50, 0.95)   # the ruled band (+ the median), both builds
FR_N_LAPLACE      <- 1000                   # the Laplace evidence's ruled draw count (10-01)
FR_SHIP_CHAINS    <- 4L                     # the MCMC band (10-08 j; "Extend to 200k", "Thin x2", 10-09)
FR_SHIP_WINDOW    <- c(lo = 30000, hi = 200000)
FR_SHIP_THIN      <- 20L
FR_SHIP_POOL_THIN <- 2L
FR_N_SHIP         <- FR_SHIP_CHAINS * diff(FR_SHIP_WINDOW)[[1]] / FR_SHIP_THIN / FR_SHIP_POOL_THIN   # 17 000
FR_NO_BAND_TITLE  <- "There are no uncertainty bands, anywhere"     # card 6's title while no band ships
FR_NO_BAND_PANEL  <- "not yet a posterior — no"                      # the parameter panel's clause

# What still blocks lifting the hold: each a string, empty when a lift is consistent with the app's copy.
.fr_lift_problems <- function(ship, global_txt, review_txt) {
  bad <- character(0)
  if (is.null(ship)) return("no shipped band in data/")
  if (!isTRUE(ship$provenance$label_ruled)) bad <- c(bad, "the band's label (app copy) is not yet ruled")
  if (grepl(FR_NO_BAND_PANEL, global_txt, fixed = TRUE)) bad <- c(bad, "the parameter panel still says no ranges are shown")
  if (grepl(FR_NO_BAND_TITLE, review_txt, fixed = TRUE)) bad <- c(bad, "card 6 still says there are no bands")
  bad
}

test_that("the HOLD: the loader draws nothing while it is set, and it is lifted only with the copy", {
  skip_if_not(file.exists(.fr_global) && file.exists(.fr_review), "app sources are not present")
  g <- paste(readLines(.fr_global, warn = FALSE), collapse = "\n")
  rv <- paste(readLines(.fr_review, warn = FALSE), collapse = "\n")
  # the loader returns before it reads any file while the hold is set
  expect_true(grepl("if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE", g, fixed = TRUE))
  # MUTATION: a loader without the guard is caught by the same match
  g2 <- sub("if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE", "", g, fixed = TRUE)
  expect_false(grepl("if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE", g2, fixed = TRUE))
  if (is.null(.fr_env$APP_RIBBONS_HOLD)) {
    p <- .fr_lift_problems(.fr_ship, g, rv)
    expect_equal(p, character(0), info = paste("APP_RIBBONS_HOLD was lifted, but:", paste(p, collapse = " | ")))
  } else {
    expect_true(is.character(.fr_env$APP_RIBBONS_HOLD) && nzchar(.fr_env$APP_RIBBONS_HOLD))
  }
  # MUTATION (the lift gate's POWER): simulated on today's texts, a lift is blocked on every count still open
  skip_if_not(.fr_ship_have, "no shipped band")
  unruled <- .fr_ship; unruled$provenance$label_ruled <- FALSE
  expect_true(any(grepl("label", .fr_lift_problems(unruled, "", ""), fixed = TRUE)))
  expect_true(any(grepl("parameter panel", .fr_lift_problems(.fr_ship, FR_NO_BAND_PANEL, ""), fixed = TRUE)))
  expect_true(any(grepl("card 6", .fr_lift_problems(.fr_ship, "", FR_NO_BAND_TITLE), fixed = TRUE)))
  ruled <- .fr_ship; ruled$provenance$label_ruled <- TRUE
  expect_equal(.fr_lift_problems(ruled, "", ""), character(0))
})

test_that("the shipped band passes the app's own check at the canonical, built for the mode it was ruled for", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  expect_identical(.fr_ship$provenance$mode, .fr_ship_md)
  p <- ccx_ribbons_problems(.fr_ship, CCX_MODE_CANONICAL, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)
  expect_equal(p, character(0), info = paste(p, collapse = " | "))
})

test_that("the shipped band IS the landing's: its bands are the committed source's, untouched", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  skip_if_not(file.exists(.fr_src_file), "the landed source artifact is absent")
  pr <- .fr_ship$provenance$promoted
  expect_identical(pr$driver, "calibration/promote_futures_ribbons.R")
  expect_identical(pr$from_md5, unname(tools::md5sum(.fr_src_file)))
  src <- readRDS(.fr_src_file)
  expect_identical(.fr_ship$bands, src$bands)
  expect_identical(.fr_ship$provenance$n_ok, src$provenance$n_ok)
  # key_draws (~22 MB in memory) stays in the source; the app never reads it
  expect_null(.fr_ship$key_draws)
  expect_false(is.null(src$key_draws))
})

test_that("the shipped band records the ruled method and what reproducing it needs", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  pv <- .fr_ship$provenance
  dp <- pv$draws_provenance
  expect_match(pv$method, "^SUPPLIED draws ")
  expect_equal(pv$n_draws, FR_N_SHIP)
  expect_equal(pv$probs, FR_PROBS_RULED)
  expect_equal(pv$n_held, length(ccx_mode_pins(.fr_ship_md)))
  expect_equal(length(dp$chain_seeds), FR_SHIP_CHAINS)
  expect_true(all(is.finite(dp$chain_seeds)) && !anyDuplicated(dp$chain_seeds))
  expect_length(dp$chain_rng_kind, 3L)
  expect_match(dp$chain_seed_applied, "immediately before", fixed = TRUE)
  expect_equal(unname(dp$window), unname(FR_SHIP_WINDOW))
  expect_equal(dp$thin, FR_SHIP_THIN)
  expect_equal(dp$pool_thin, FR_SHIP_POOL_THIN)
  expect_equal(dp$per_chain * FR_SHIP_CHAINS, FR_N_SHIP)
  # the band was built from the draws it names
  expect_true(grepl(sprintf("(md5 %s)", dp$draws_md5), pv$method, fixed = TRUE))
  # a censored sample would draw a band from the draws that happened to run
  expect_lt(pv$n_failed, 0.01 * pv$n_draws)
  # the draw machinery reproduced the app's own central line before it drew
  expect_lt(pv$central_check_max_abs, pv$central_check_tol)
  expect_true(all(is.finite(.fr_ship$bands$central)))
})

test_that("every scenario's shipped band has width at the end of the run, in both variables", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  b <- .fr_ship$bands
  last <- b[b$year == max(b$year), ]
  expect_equal(nrow(last), length(.fr_env$APP_SCENARIOS) * length(.fr_env$APP_FUTURE_YVARS))
  expect_true(all(last$q95 - last$q05 > 0),
              info = "a zero-width band at the run's end means the draws did not move the future")
})

test_that("the held Laplace EVIDENCE: built for the fit it names, by its ruled method, and REFUSED at any other", {
  skip_if_not(.fr_lap_have, "the held Laplace evidence artifact is absent")
  p <- ccx_ribbons_problems(.fr_lap, .fr_lap_md, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)
  expect_equal(p, character(0), info = paste(p, collapse = " | "))
  pv <- .fr_lap$provenance
  expect_equal(pv$n_draws, FR_N_LAPLACE)
  expect_equal(pv$probs, FR_PROBS_RULED)
  expect_match(pv$label, "^Gaussian approximation at the best fit, conditional on the .+ held values$")
  expect_true(is.numeric(pv$seed) && length(pv$seed) == 1L && is.finite(pv$seed))
  expect_match(pv$seed_applied, "immediately before", fixed = TRUE)
  # the guard's POWER: at the canonical (another fit since 2026-10-03) the app's own call must refuse it,
  # on BOTH counts -- the name and the vector
  if (!identical(.fr_lap_md, CCX_MODE_CANONICAL)) {
    pc <- ccx_ribbons_problems(.fr_lap, CCX_MODE_CANONICAL, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)
    expect_true(any(grepl(sprintf("built for mode '%s', the canonical is '%s'", .fr_lap_md, CCX_MODE_CANONICAL), pc, fixed = TRUE)),
                info = paste(pc, collapse = " | "))
    expect_true(any(grepl("different parameter vector", pc, fixed = TRUE)), info = paste(pc, collapse = " | "))
  }
})

# ---------------------------------------------------------------------
# MUTATION TESTS -- feed the check each failure it exists for (on the SHIPPED band)
# ---------------------------------------------------------------------
.fr_chk <- function(r) ccx_ribbons_problems(r, .fr_ship_md, .fr_env$APP_SCENARIOS, .fr_env$APP_FUTURE_YVARS)

test_that("MUTATION: bands built at a DIFFERENT parameter vector are rejected", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  bad <- .fr_ship; bad$provenance$par_mode$q10 <- bad$provenance$par_mode$q10 * 1.01
  expect_true(any(grepl("different parameter vector", .fr_chk(bad), fixed = TRUE)))
})

test_that("MUTATION: a missing scenario, a missing seed, disordered quantiles and another mode are each rejected", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  b1 <- .fr_ship; b1$bands <- b1$bands[b1$bands$scenario != .fr_env$APP_SCENARIOS[[1]], ]
  expect_true(any(grepl("no bands for scenario", .fr_chk(b1), fixed = TRUE)))
  b2 <- .fr_ship; b2$provenance$seed <- NULL
  expect_true(any(grepl("seed", .fr_chk(b2), fixed = TRUE)))
  b3 <- .fr_ship; i <- which(b3$bands$year == max(b3$bands$year))[1]
  b3$bands$q05[i] <- b3$bands$q95[i] + 1
  expect_true(any(grepl("out of order", .fr_chk(b3), fixed = TRUE)))
  b4 <- .fr_ship; b4$provenance$mode <- "hilda29l"
  expect_true(any(grepl("built for mode 'hilda29l'", .fr_chk(b4), fixed = TRUE)))
})

test_that("MUTATION: MCMC draws without the chains' seeds, RNG kind or seed placement are rejected", {
  skip_if_not(.fr_ship_have, "no shipped band in data/")
  msg <- "supplied draws: the chains' seeds"
  m1 <- .fr_ship; m1$provenance$draws_provenance$chain_seeds <- NULL
  expect_true(any(grepl(msg, .fr_chk(m1), fixed = TRUE)))
  m2 <- .fr_ship; m2$provenance$draws_provenance$chain_seeds[2] <- NA_integer_
  expect_true(any(grepl(msg, .fr_chk(m2), fixed = TRUE)))
  m3 <- .fr_ship; m3$provenance$draws_provenance$chain_rng_kind <- NULL
  expect_true(any(grepl(msg, .fr_chk(m3), fixed = TRUE)))
  m4 <- .fr_ship; m4$provenance$draws_provenance$chain_seed_applied <- ""
  expect_true(any(grepl(msg, .fr_chk(m4), fixed = TRUE)))
  m5 <- .fr_ship; m5$provenance$draws_provenance <- NULL
  expect_true(any(grepl(msg, .fr_chk(m5), fixed = TRUE)))
})
