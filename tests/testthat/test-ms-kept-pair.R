# =====================================================================
# test-ms-kept-pair.R -- the multistart's (u, best) is a PAIR by construction (CHANGELOG 2026-10-08 c; Marcus: "Build the
# bookkeeping fix"; calibration/lib_ms_deadline.R ms_kept_pair()). #18's id 13 was stopped DEAD because the driver kept
# optim()'s `par` beside optim()'s `value`, and at normal convergence R's BFGS returns a `par` it never evaluated
# (CHANGELOG 2026-10-08 a; outputs/diagnostics/obj18_vmmin_synthetic.log).
#   KP1 THE DEFECT, in R itself: on a smooth bowl with a deterministic ulp-sensitive floor, BFGS run to convergence returns
#       an UNEVALUATED par in most seeded starts, and its `value` is not f(par) in some; ms_kept_pair() returns
#       f(par) exactly, every time, and the claim gap beside it.
#   KP2 THE PATH IS UNCHANGED: re-evaluating after optim() returns cannot move the point optim() returned.
#   KP3 THE WIRING (code lines): both optimizer steps go through ms_kept_pair(); the polish is accepted on the kept value;
#       a resumed checkpoint is re-paired; the DEAD gate has two branches and the identity branch is EXACT; the start
#       file records the branch, the claim gaps and the pairing.
# =====================================================================
source(file.path(.root, "calibration", "lib_ms_deadline.R"))
KP_NOISE <- 1e-6; KP_N <- 12L; KP_REPS <- 12L; KP_SEED <- 20261008L
kp_f <- function(u) sum((u - seq_len(KP_N) / KP_N)^2) + KP_NOISE * sin(1e17 * sum(u * sqrt(seq_len(KP_N))))
kp_starts <- function() { set.seed(KP_SEED)                      # the only RNG use, immediately before the draws
  lapply(seq_len(KP_REPS), function(i) seq_len(KP_N) / KP_N + stats::rnorm(KP_N, 0, 1e-3)) }

test_that("KP1: R's BFGS returns unevaluated points; ms_kept_pair() returns f(par) exactly, with the claim gap", {
  R <- lapply(kp_starts(), function(u0) {
    E <- new.env(); E$u <- list()
    fn <- function(u) { E$u[[length(E$u) + 1L]] <- u; kp_f(u) }
    o <- stats::optim(u0, fn, method = "BFGS", control = list(maxit = 100L, reltol = 1e-14))
    kp <- ms_kept_pair(o, kp_f)
    list(evaluated = any(vapply(E$u, function(x) identical(x, o$par), TRUE)), claim_is_f = identical(o$value, kp_f(o$par)),
         kp = kp, o = o)
  })
  # the defect is real here: most returned points were never evaluated, and some claims are not f(par)
  expect_gt(sum(!vapply(R, `[[`, TRUE, "evaluated")), KP_REPS / 2)
  expect_gt(sum(!vapply(R, `[[`, TRUE, "claim_is_f")), 0)
  for (r in R) {
    expect_identical(r$kp$value, kp_f(r$o$par))              # the kept value IS the objective at the kept point
    expect_identical(r$kp$par, r$o$par)
    expect_identical(r$kp$claimed, r$o$value)
    expect_identical(r$kp$gap, r$kp$value - r$o$value)
  }
})

test_that("KP2: re-pairing never moves the point, and a consistent step comes back with a zero gap", {
  o <- stats::optim(c(0.3, -0.2), function(u) sum((u - c(1, 2))^2), method = "Nelder-Mead")
  kp <- ms_kept_pair(o, function(u) sum((u - c(1, 2))^2))
  expect_identical(kp$par, o$par); expect_identical(kp$gap, 0)  # NM's best vertex IS an evaluated point
  st <- list(par = c(a = 1, b = 2), value = 5)
  kp <- ms_kept_pair(st, function(u) 7)
  expect_identical(kp$value, 7); expect_identical(kp$claimed, 5); expect_identical(kp$gap, 2)
})

test_that("KP3: the driver keeps PAIRS at both steps and on resume, and its DEAD gate is two EXACT branches", {
  drv <- ccx_code_lines(readLines(file.path(.root, "calibration", "run_dispersed_multistart.R")))
  code <- paste(drv, collapse = "\n")
  # both steps, and the resume, go through ms_kept_pair()
  expect_equal(sum(grepl("ms_kept_pair(fit, neg_lp)", drv, fixed = TRUE)), 1L)
  expect_equal(sum(grepl("ms_kept_pair(pc, neg_lp)", drv, fixed = TRUE)), 1L)
  expect_equal(sum(grepl("ms_kept_pair(list(par = u, value = best), neg_lp)", drv, fixed = TRUE)), 1L)
  # no `best` is ever taken from an optimizer's claim, and the polish is not accepted on one
  expect_false(grepl("best <- fit$value", code, fixed = TRUE))
  expect_false(grepl("best <- pc$value", code, fixed = TRUE))
  expect_false(grepl("pc$value < best", code, fixed = TRUE))
  expect_true(grepl("if (.kp$value < best) {", code, fixed = TRUE))
  # the DEAD gate: two branches, the identity one exact; the old relative bound is gone from it
  expect_true(grepl("dead_unpaired  <- !dead_nonfinite && !identical(.final_lp, -best)", code, fixed = TRUE))
  expect_false(grepl("abs(.final_lp - (-best)) > MS_EVAL_TOL", code, fixed = TRUE))
  expect_true(grepl("if (dead_nonfinite)\n  stop(\"DEAD TASK id ", code, fixed = TRUE))
  expect_true(grepl("if (dead_unpaired)\n  stop(\"UNPAIRED BEST, id ", code, fixed = TRUE))
  # recorded: the branch, the gaps, the pairing; the checkpoint carries the gaps
  expect_true(grepl("dead_branch = if (dead_nonfinite) \"nonfinite\" else if (dead_unpaired) \"unpaired\" else \"none\"", code, fixed = TRUE))
  expect_true(grepl("claim_gaps = claim_gaps, pairing = \"kept_pair\",", code, fixed = TRUE))
  expect_true(grepl("trace = trace, claim_gaps = claim_gaps,", code, fixed = TRUE))
})
