# The multistart's IN-RESTART DEADLINE (option A; Marcus 2026-10-05 on
# notes/proposal_2026-10-04_multistart_inrestart_wall.md; calibration/lib_ms_deadline.R).
# D1 a deadline stops a slowing step within an evaluation or two and returns the best EVALUATED point;
# D2 with no deadline the step is identical() to plain optim() (Nelder-Mead AND BFGS);
# D3 a deadline before the first evaluation returns the start; D4 any OTHER error propagates;
# D5 the polish is sized at the OBSERVED rate; D6 a restart's minutes are normalised by the evals it made;
# D7 the driver routes BOTH its steps through the stepper and records the stops; D8 val0 is forced before the
# deadline is set. Mutations M1-M7 (CHANGELOG 10-05) are each caught by their own test.
source(file.path(.root, "calibration", "lib_ms_deadline.R"))

# a smooth bowl, minimised; `slow_after` evaluations in, each one sleeps (the near-wall slowdown, scripted)
make_obj <- function(slow_after = Inf, nap = 0.02) {
  env <- new.env(); env$n <- 0L; env$vals <- numeric(0); env$us <- list()
  st <- ms_step_state()
  f <- function(u) {
    ms_check_deadline(st)
    env$n <- env$n + 1L
    if (env$n > slow_after) Sys.sleep(nap)
    val <- sum((u - c(1, -2, 0.5))^2) + 0.1 * sum(u^4)
    env$vals <- c(env$vals, val); env$us[[env$n]] <- u
    ms_track_best(st, u, val)
    val
  }
  list(f = f, st = st, env = env)
}
U0 <- c(3, 3, 3)

test_that("D1: a deadline stops a slowing step promptly and keeps the best EVALUATED point", {
  o <- make_obj(slow_after = 5, nap = 0.02)
  t_start <- as.numeric(Sys.time())
  r <- ms_run_step(o$st, U0, o$f(U0), o$f, "Nelder-Mead", list(maxit = 500, reltol = 1e-14), deadline = t_start + 0.25)
  el <- as.numeric(Sys.time()) - t_start
  expect_true(isTRUE(r$deadline))
  expect_lt(el, 2)                                  # unguarded: 500 x 0.02 s = 10 s
  expect_identical(r$value, min(o$env$vals))        # the best of everything evaluated ...
  expect_true(any(vapply(o$env$us, function(u) identical(u, r$par), logical(1))))   # ... and an evaluated point
  expect_identical(o$st$deadline, Inf)              # the step's deadline is cleared on exit
})

test_that("D2: with no deadline the step is identical() to plain optim(), Nelder-Mead and BFGS", {
  for (m in c("Nelder-Mead", "BFGS")) {
    ctl <- if (m == "BFGS") list(maxit = 50, reltol = 1e-14) else list(maxit = 400, reltol = 1e-12)
    o1 <- make_obj(); r <- ms_run_step(o1$st, U0, Inf, o1$f, m, ctl, deadline = Inf)
    plain <- function(u) sum((u - c(1, -2, 0.5))^2) + 0.1 * sum(u^4)
    p <- stats::optim(U0, plain, method = m, control = ctl)
    expect_false(isTRUE(r$deadline))
    for (k in c("par", "value", "counts", "convergence")) expect_identical(r[[k]], p[[k]], info = paste(m, k))
  }
})

test_that("D3: a deadline that passed before the first evaluation returns the start and its value", {
  o <- make_obj()
  r <- ms_run_step(o$st, U0, 42, o$f, "Nelder-Mead", list(maxit = 100), deadline = as.numeric(Sys.time()) - 1)
  expect_true(isTRUE(r$deadline)); expect_identical(r$par, U0); expect_identical(r$value, 42)
  expect_identical(o$env$n, 0L)
})

test_that("D8: val0 is FORCED before the deadline is set (a lazily evaluated fn(u0) must not re-trigger it)", {
  o <- make_obj()
  r <- ms_run_step(o$st, U0, o$f(U0), o$f, "Nelder-Mead", list(maxit = 100), deadline = as.numeric(Sys.time()) - 1)
  expect_true(isTRUE(r$deadline)); expect_identical(r$par, U0); expect_identical(r$value, o$env$vals[1])
})

test_that("D4: any OTHER error propagates -- it is not mistaken for a deadline", {
  st <- ms_step_state()
  bad <- function(u) { ms_check_deadline(st); stop("an objective failure, not a deadline") }
  expect_error(ms_run_step(st, U0, 1, bad, "BFGS", list(maxit = 5), deadline = Inf), "objective failure")
})

test_that("D5: the polish is sized at the OBSERVED per-evaluation rate once restarts have run", {
  # 0.3 s/eval measured at the start; a restart that took 250 min per 6000 evals = 2.5 s/eval
  args <- list(left_min = 60, n_par = 33, sec_per_eval = 0.3, maxit_full = 6000, safety = 1.5, floor_ = 5, cap = 500)
  fast <- do.call(ms_polish_maxit, c(args, list(restart_min = numeric(0))))
  slow <- do.call(ms_polish_maxit, c(args, list(restart_min = c(30, 250))))
  expect_identical(fast, as.integer(floor(60 / (1.5 * 67 * 0.3 / 60))))       # 119
  expect_identical(slow, as.integer(floor(60 / (1.5 * 67 * 2.5 / 60))))       # 14
  expect_identical(do.call(ms_polish_maxit, c(modifyList(args, list(left_min = 5)), list(restart_min = c(250)))), 0L)
})

test_that("D6: a restart's minutes are normalised by the evaluations it actually made", {
  expect_identical(ms_restart_minutes(10, 6000, 3000), 20)    # stopped early: twice the per-eval cost of 10/6000
  expect_identical(ms_restart_minutes(250, 6000, 6002), 250 * 6000 / 6002)
  expect_null(ms_restart_minutes(1, 6000, 0))
})

test_that("D7: the driver routes BOTH optimiser steps through the stepper and records the stops", {
  src <- readLines(file.path(.root, "calibration", "run_dispersed_multistart.R"))
  code <- src[!grepl("^\\s*#", src)]
  expect_true(any(grepl("source\\(ccx_path\\(\"calibration\", \"lib_ms_deadline.R\"\\)\\)", code)))
  expect_true(any(grepl("ms_run_step\\(MS_STEP, u, best, neg_lp, \"Nelder-Mead\"", code)))
  expect_true(any(grepl("ms_run_step\\(MS_STEP, u, best, neg_lp, \"BFGS\"", code)))
  expect_false(any(grepl("\\boptim\\(u, neg_lp", code)))     # no unguarded step left
  expect_true(any(grepl("ms_check_deadline\\(MS_STEP\\)", code)))
  expect_true(any(grepl("deadline_stops = deadline_stops", code)))
  expect_true(any(grepl("ms_polish_maxit\\(", code)) && any(grepl("ms_restart_minutes\\(", code)))
})
