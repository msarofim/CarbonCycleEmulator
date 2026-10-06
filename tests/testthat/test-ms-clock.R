# The multistart budget's CLOCK (CHANGELOG 2026-10-05 o; Marcus: D1 "CPU on Mac, wall on Torch", D2 "Keep 300
# CPU-min", D3 "Record and warn", D4 "Warn only, at 2x"; calibration/lib_ms_deadline.R).
# C1 the clock is validated, never a silent fallback; the default stays wall, so test-ms-deadline D1-D8 run as before.
# C2 THE SWITCH, on the REAL clocks: a step whose evaluations SLEEP (wall advances, CPU does not) is not stopped by a
#    CPU deadline, the same step IS stopped by a wall deadline (C2's power), and evaluations that BURN CPU are stopped
#    by a CPU deadline.
# C3 the record: a start file without `clock` reads as wall, and a mixed set is named.
# C4 the wiring: one clock from MS_CLOCK through the driver, the start file's fields, the collector's warning,
#    promote's copy, and each runner's clock.
# C5 the lint: nothing in the budget path reads a clock except ms_clock().
source(file.path(.root, "calibration", "lib_ms_deadline.R"))

U0 <- c(3, 3, 3)
bowl <- function(u) sum((u - c(1, -2, 0.5))^2) + 0.1 * sum(u^4)
# the objective as the driver wraps it: check BEFORE, track AFTER; `cost` is what one evaluation spends
make_obj <- function(st, cost) {
  env <- new.env(); env$n <- 0L
  f <- function(u) {
    ms_check_deadline(st)
    env$n <- env$n + 1L
    cost()
    val <- bowl(u); ms_track_best(st, u, val); val
  }
  list(f = f, env = env)
}
nap  <- function() Sys.sleep(0.05)                                       # ~0 CPU, 0.05 s wall
burn <- function() { t <- ms_clock("cpu"); while (ms_clock("cpu") - t < 0.02) NULL }   # 0.02 s of CPU

test_that("C1: the clock is VALIDATED -- an unknown value stops, never falls back -- and the default is wall", {
  expect_identical(ms_clock_kind(""), "wall")
  expect_identical(ms_clock_kind("wall"), "wall")
  expect_identical(ms_clock_kind("cpu"), "cpu")
  for (bad in c("CPU", "Wall", "cpu ", "proc", "elapsed")) expect_error(ms_clock_kind(bad), "CCX_MS_CLOCK must be one of")
  expect_identical(ms_step_state()$clock, "wall")     # test-ms-deadline's D1-D8 call ms_step_state() bare
  expect_identical(ms_step_state("cpu")$clock, "cpu")
  expect_error(ms_step_state("cpu "), "CCX_MS_CLOCK must be one of")
  expect_error(ms_clock("cpu "), "unknown clock")
  expect_identical(ms_clock_label("wall"), "wall"); expect_identical(ms_clock_label("cpu"), "CPU")
})

test_that("C2a: evaluations that SLEEP do not spend a CPU deadline", {
  st <- ms_step_state("cpu"); o <- make_obj(st, nap)
  c0 <- ms_clock("cpu"); w0 <- ms_clock("wall")
  r <- ms_run_step(st, U0, bowl(U0), o$f, "Nelder-Mead", list(maxit = 30, reltol = 1e-14), deadline = c0 + 0.5)
  w_el <- ms_clock("wall") - w0; c_el <- ms_clock("cpu") - c0
  expect_false(isTRUE(r$deadline))                    # the step ran to its maxit ...
  expect_gte(o$env$n, 30L)
  expect_gt(w_el, 0.5)                                # ... although the WALL clock passed the same offset,
  expect_lt(c_el, 0.25)                               # and it spent almost no CPU doing so
})

test_that("C2b: C2a has POWER -- the same sleeping step IS stopped by a WALL deadline", {
  st <- ms_step_state("wall"); o <- make_obj(st, nap)
  r <- ms_run_step(st, U0, bowl(U0), o$f, "Nelder-Mead", list(maxit = 30, reltol = 1e-14), deadline = ms_clock("wall") + 0.5)
  expect_true(isTRUE(r$deadline))
  expect_lt(o$env$n, 30L)
})

test_that("C2c: evaluations that BURN CPU are stopped by a CPU deadline, with the best EVALUATED point kept", {
  st <- ms_step_state("cpu"); o <- make_obj(st, burn)
  c0 <- ms_clock("cpu")
  r <- ms_run_step(st, U0, bowl(U0), o$f, "Nelder-Mead", list(maxit = 500, reltol = 1e-14), deadline = c0 + 0.25)
  expect_true(isTRUE(r$deadline))
  expect_lt(ms_clock("cpu") - c0, 2)                  # unguarded: 500 x 0.02 s = 10 s of CPU
  expect_identical(st$deadline, Inf)                  # cleared on exit, as on the wall clock
  expect_true(is.finite(r$value) && r$value <= bowl(U0))
})

test_that("C3: a start file without `clock` reads as wall, and a set on two clocks is NAMED", {
  expect_identical(ms_start_clock(list(id = 3L)), "wall")
  expect_identical(ms_start_clock(list(clock = "cpu")), "cpu")
  expect_null(ms_clock_mix_note(c("wall", "wall"), c(1L, 2L)))
  expect_null(ms_clock_mix_note(c("cpu", "cpu"), c(1L, 2L)))
  m <- ms_clock_mix_note(c("wall", "cpu", "wall"), c(3L, 7L, 9L))
  expect_match(m, "MIXED CLOCKS"); expect_match(m, "cpu [7]", fixed = TRUE); expect_match(m, "wall [3, 9]", fixed = TRUE)
})

test_that("C4: ONE clock is wired from MS_CLOCK through the driver, the record, the collector, promote and the runners", {
  rd <- function(...) ccx_code_lines(readLines(file.path(.root, ...)))
  drv <- rd("calibration", "run_dispersed_multistart.R")
  has <- function(code, pat) any(grepl(pat, code, fixed = TRUE))
  expect_true(any(grepl("^MS_CLOCK\\s*<-\\s*ms_clock_kind\\(\\)", drv)))
  expect_true(has(drv, "MS_STEP <- ms_step_state(MS_CLOCK)"))          # the deadlines are read on MS_CLOCK ...
  expect_true(has(drv, "ms_now <- function() ms_clock(MS_STEP$clock)")) # ... and so is the budget's origin
  expect_true(has(drv, "t0 <- ms_now()"))
  expect_true(has(drv, "deadline = t0 + 60 * (MS_BUDGET_MIN - polish_reserve_min())"))
  expect_true(has(drv, "deadline = t0 + 60 * MS_BUDGET_MIN"))
  expect_true(has(drv, "clock = MS_CLOCK, budget_min = MS_BUDGET_MIN, minutes_wall = elapsed_wall_min()"))
  expect_true(has(drv, "wall_warned = wall_warned"))
  col <- rd("calibration", "collect_dispersed_multistart.R")
  expect_true(has(col, "vapply(R, ms_start_clock, character(1))"))
  expect_true(has(col, "ms_clock_mix_note(clk, ids)"))
  expect_true(has(rd("calibration", "promote_multistart_mode.R"), "clock = ms_start_clock(best)"))
  mac <- readLines(file.path(.root, "calibration", "mac", "run_multistart_mac.sh"))
  expect_true(any(grepl('^export CCX_MS_CLOCK="\\$\\{CCX_MS_CLOCK:-cpu\\}"', mac)))       # D1: CPU on the Mac
  sb <- readLines(file.path(.root, "calibration", "torch", "multistart.sbatch"))
  expect_true(any(grepl("^export CCX_MS_CLOCK=wall$", sb)))                              # D1: wall on Torch ...
  expect_true(any(grepl('"\\$CCX_MS_CLOCK" != "wall"', sb, fixed = FALSE)))             # ... and nothing else
})

test_that("C5: nothing in the budget path reads a clock except ms_clock()", {
  pat <- "Sys\\.time\\(|difftime\\(|proc\\.time\\("
  drv <- ccx_code_lines(readLines(file.path(.root, "calibration", "run_dispersed_multistart.R")))
  expect_identical(grep(pat, drv, value = TRUE), character(0))
  # in the library, ONLY ms_clock()'s body may read one
  ex <- parse(file.path(.root, "calibration", "lib_ms_deadline.R"), keep.source = FALSE)
  readers <- character(0)
  for (e in ex) {
    txt <- paste(deparse(e), collapse = "\n")
    if (!grepl(pat, txt)) next
    is_fn <- is.call(e) && identical(e[[1]], as.name("<-")) && is.call(e[[3]]) && identical(e[[3]][[1]], as.name("function"))
    readers <- c(readers, if (is_fn) as.character(e[[2]]) else "<top level>")
  }
  expect_identical(readers, "ms_clock")
})
