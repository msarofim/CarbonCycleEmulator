# =====================================================================
# test-ms-file.R -- the dispersed multistart's FILE STARTS (ids 6-9) and the bound they share with PORT GATE (a)
# (CHANGELOG 2026-10-23 e; refit item 2 of notes/handoff_2026-10-23_flask_refit_item2.md; calibration/lib_ms_file.R).
#   MF1 THE READER: no file is no starts; a good file comes back in slot order with each u in the run's name order;
#       every refusal names its cause (a missing file, no starts, unnamed or repeated names, more starts than slots, a
#       label field absent or different -- struct, seas_ml, pump field, pins -- a u named by other names or non-finite,
#       a bad logpost or source). The two labels.
#   MF2 THE BOUND: ms_identity_bound() is PORT GATE (a)'s arithmetic; ms_roundoff_floor() returns what the driver's inline
#       measurement returned before the move, draw for draw, and leaves the caller's RNG stream as it found it (present
#       or absent).
#   MF3 THE WIRING (code lines): the driver sources the lib, dispatches the file slots in BOTH ms_fixed_u() and ms_start()
#       before the gap guard, gates a file start's value before the preflight exits, measures port gate (a)'s floor
#       through the lib, and records the file; its slots equal the collector's, and MS_DISPERSED_FROM is the first id past
#       them.
#   MF4 THE FLASK FILE: calibration/torch/file_starts_hilda_csl3v0kaidgbemwtcf.rds holds T8f's uB and uN_all with T8f's
#       values under the flask arm's label, passes the reader under that arm, and the DRIVER's objective construction
#       (ccx_default_params + the structure + the pins) scores both to T8f's values.
# The gate end to end (the preflight on ids 1, 6-9, and a corrupted target refused) is in CHANGELOG 2026-10-23 (e).
# =====================================================================
source(ccx_path("calibration", "lib_ms_file.R"))
MF_FLASK_FILE <- file.path("calibration", "torch", "file_starts_hilda_csl3v0kaidgbemwtcf.rds")
MF_T8F <- file.path(ccx_path(), "outputs", "diagnostics", "seas8_20261021_hilda31w", "t8f_allflask_forecast_hilda31w.rds")
MF_REPRO_TOL <- 1e-8   # the driver's construction vs T8f's override at the same point: a tolerance for roundoff only

mf_label <- list(struct = "lab", seas_ml = 1L, pump_field = "solved", pins = c(a = 1, b = 2.5))
mf_names <- c("x", "y", "z")
mf_good <- function()
  list(starts = list(p1 = list(u = c(z = 3, x = 1, y = 2), logpost = -10, source = "test point 1"),
                     p2 = list(u = c(x = 4, y = 5, z = 6), logpost = -11, source = "test point 2")),
       struct = "lab", seas_ml = 1L, pump_field = "solved", pins = c(a = 1, b = 2.5), provenance = list())
mf_read <- function(x, n_slots = 4L, label = mf_label) {
  f <- tempfile(fileext = ".rds"); saveRDS(x, f); on.exit(unlink(f))
  ms_read_file_starts(f, n_slots, label, mf_names)
}

test_that("MF1: no file is no starts; a good file comes back in slot order, each u in the run's name order", {
  expect_identical(ms_read_file_starts("", 4L, mf_label, mf_names), list())
  expect_identical(ms_read_file_starts(NA_character_, 4L, mf_label, mf_names), list())
  r <- mf_read(mf_good())
  expect_identical(vapply(r, `[[`, "", "name"), c("p1", "p2"))
  expect_identical(r[[1]]$u, c(x = 1, y = 2, z = 3))
  expect_identical(r[[2]]$logpost, -11); expect_identical(r[[1]]$source, "test point 1")
  expect_length(mf_read(mf_good(), n_slots = 2L), 2L)
  # a FREE arm: pins recorded as NULL, and none in the run
  x <- mf_good(); x["pins"] <- list(NULL)
  expect_length(mf_read(x, label = list(struct = "lab", seas_ml = 1L, pump_field = "solved", pins = NULL)), 2L)
  # the labels
  expect_identical(ms_file_kind("file1", r[[1]]), "file start 'p1' (slot file1): test point 1; it scored -10.000000 there")
  expect_identical(ms_empty_file_kind("file3", "no CCX_MS_FILE_STARTS", "dispersed about the COLD init, sd 1.0452"),
                   "EMPTY file slot file3 (no CCX_MS_FILE_STARTS) -- so this id runs a DISPERSED DRAW instead: dispersed about the COLD init, sd 1.0452")
})

test_that("MF1: every refusal names its cause", {
  expect_error(ms_read_file_starts(file.path(tempdir(), "no_such_file.rds"), 4L, mf_label, mf_names), "does not exist")
  x <- mf_good(); x$starts <- list(); expect_error(mf_read(x), "carry no `starts` list")
  x <- mf_good(); names(x$starts) <- NULL; expect_error(mf_read(x), "must be NAMED, each name once")
  x <- mf_good(); names(x$starts) <- c("p1", "p1"); expect_error(mf_read(x), "must be NAMED, each name once")
  expect_error(mf_read(mf_good(), n_slots = 1L), "hold 2 starts, but the driver reserves 1 file slots")
  # THE LABEL: absent (pins too: a free arm records NULL, it does not omit the field), then different, field by field
  for (f in c("struct", "seas_ml", "pump_field", "pins")) {
    x <- mf_good(); x[[f]] <- NULL
    expect_error(mf_read(x), paste0("record no ", f), info = f)
  }
  x <- mf_good(); x$struct <- "other"; expect_error(mf_read(x), "scored with struct 'other'; this run has 'lab'")
  x <- mf_good(); x$seas_ml <- 0L; expect_error(mf_read(x), "scored with seas_ml '0'; this run has '1'")
  x <- mf_good(); x$pump_field <- "martin"; expect_error(mf_read(x), "scored with pump_field 'martin'")
  x <- mf_good(); x$pins <- c(a = 1, b = 2.6); expect_error(mf_read(x), "scored with pins '_pin_a=1.0_b=2.6'")
  x <- mf_good(); x["pins"] <- list(NULL); expect_error(mf_read(x), "scored with pins ''")
  # THE STARTS
  x <- mf_good(); x$starts$p2$u <- c(x = 4, y = 5); expect_error(mf_read(x), "file start 'p2'.*missing z")
  x <- mf_good(); x$starts$p2$u <- c(x = 4, y = 5, z = 6, w = 7); expect_error(mf_read(x), "not fitted here w")
  x <- mf_good(); x$starts$p1$u <- unname(x$starts$p1$u); expect_error(mf_read(x), "unique names")
  x <- mf_good(); x$starts$p1$u[["y"]] <- NaN; expect_error(mf_read(x), "non-finite")
  for (bad in list(NA_real_, c(-1, -2), "-10", NULL)) {
    x <- mf_good(); x$starts$p1["logpost"] <- list(bad)
    expect_error(mf_read(x), "`logpost` must be one finite number", info = deparse(bad))
  }
  x <- mf_good(); x$starts$p1$source <- ""; expect_error(mf_read(x), "`source` must say")
})

# the driver's inline floor measurement at 9d6d06d5 (calibration/run_dispersed_multistart.R), verbatim but for its inputs
mf_floor_old <- function(lp_fun, u_ref, here, MS_PORT_FLOOR_N, MS_PORT_FLOOR_EPS, MS_PORT_FLOOR_SEED) {
  .had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  .saved <- if (.had_seed) get(".Random.seed", envir = globalenv()) else NULL
  set.seed(MS_PORT_FLOOR_SEED)
  .floor_d <- vapply(seq_len(MS_PORT_FLOOR_N), function(k) {
    du <- u_ref; j <- sample(length(du), 1L)
    du[j] <- du[j] * (1 + sample(c(-1, 1), 1L) * MS_PORT_FLOOR_EPS)
    lp_fun(du) - here
  }, numeric(1))
  if (.had_seed) assign(".Random.seed", .saved, envir = globalenv()) else rm(".Random.seed", envir = globalenv())
  .floor_d
}

test_that("MF2: the bound is PORT GATE (a)'s; the floor is the old measurement draw for draw and keeps the caller's RNG", {
  b <- ms_identity_bound(-1000, 1e-6, 1e-8, 3, 1e-6)
  expect_equal(b$tol, 1e-5); expect_equal(b$ceil, 1e-3)
  expect_equal(ms_identity_bound(-1000, 1e-5, 1e-8, 3, 1e-6)$tol, 3e-5)
  expect_equal(ms_identity_bound(0, 0, 1e-8, 3, 1e-6)$tol, 1e-20)
  lp <- function(u) -sum(exp(u) * seq_along(u))           # nonlinear in every coordinate, so every draw moves it
  u <- c(a = 0.3, b = -1.2, c = 2.1, d = 0.05); here <- lp(u)
  old_seed <- get0(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit(if (is.null(old_seed)) suppressWarnings(rm(".Random.seed", envir = globalenv()))
          else assign(".Random.seed", old_seed, envir = globalenv()), add = TRUE)
  set.seed(7); s0 <- get(".Random.seed", envir = globalenv())
  d_new <- ms_roundoff_floor(lp, u, here, 12L, 1e-12, 20260915L)
  expect_identical(get(".Random.seed", envir = globalenv()), s0)       # the caller's stream, untouched
  d_old <- mf_floor_old(lp, u, here, 12L, 1e-12, 20260915L)
  expect_identical(d_new, d_old)                                        # the same perturbations, the same deltas
  expect_true(all(d_new != 0)); expect_lt(max(abs(d_new)), 1e-9)
  rm(".Random.seed", envir = globalenv())                               # and with NO stream: it leaves none
  expect_identical(ms_roundoff_floor(lp, u, here, 12L, 1e-12, 20260915L), d_old)
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
})

test_that("MF3: the driver dispatches the file slots in both functions, gates them, and agrees with the collector", {
  drv <- ccx_code_lines(readLines(ccx_path("calibration", "run_dispersed_multistart.R")))
  co  <- ccx_code_lines(readLines(ccx_path("calibration", "collect_dispersed_multistart.R")))
  expect_true(any(grepl('source(ccx_path("calibration", "lib_ms_file.R"))', drv, fixed = TRUE)))
  one <- function(lines, pat) { i <- grep(pat, lines); expect_length(i, 1L); i }
  e <- new.env()
  for (p in c("^MS_SEED_IDS +<- ", "^MS_FILE_IDS +<- ", "^MS_DISPERSED_FROM <- ")) eval(parse(text = drv[one(drv, p)]), e)
  eval(parse(text = co[one(co, "^CO_FILE_IDS <- ")]), e)
  expect_identical(e$MS_FILE_IDS, e$CO_FILE_IDS)
  expect_identical(min(e$MS_FILE_IDS), max(e$MS_SEED_IDS) + 1L)
  expect_identical(unname(e$MS_FILE_IDS), seq.int(min(e$MS_FILE_IDS), max(e$MS_FILE_IDS)))
  expect_identical(e$MS_DISPERSED_FROM, max(e$MS_FILE_IDS) + 1L)
  # ms_fixed_u() and ms_start() both dispatch a file slot, ms_start() before the gap guard
  fx <- one(drv, "^ms_fixed_u <- function"); st <- one(drv, "^ms_start <- function"); gap <- one(drv, "^  if \\(id < MS_DISPERSED_FROM\\)$")
  expect_true(any(grepl("fk <- match(id, MS_FILE_IDS)", drv[fx:st], fixed = TRUE)))
  fk <- one(drv, "^  \\.fk <- match\\(id, MS_FILE_IDS\\)$")
  expect_true(st < fk && fk < gap)
  expect_true(any(grepl('class = "file", target = e$logpost', drv[fk:gap], fixed = TRUE)))
  # the value gate runs after the start is built and before the preflight exits; port gate (a) uses the lib's floor
  g <- one(drv, '^if \\(identical\\(st\\$class, "file"\\)\\) local\\(\\{$')
  expect_true(one(drv, "^st <- ms_start\\(MS_ID\\)$") < g && g < one(drv, "^if \\(MS_PREFLIGHT\\) \\{$"))
  expect_true(any(grepl("ms_roundoff_floor(lp_fun, u_ref, here, MS_PORT_FLOOR_N", drv, fixed = TRUE)))
  expect_true(any(grepl("ms_roundoff_floor(lp_fun, st$u, MS_REF_LP, MS_PORT_FLOOR_N", drv, fixed = TRUE)))
  expect_false(any(grepl(".had_seed", drv, fixed = TRUE)), info = "one floor measurement, in the lib")
  expect_true(any(grepl("file_starts_md5 = MS_FILE_STARTS_MD5", drv, fixed = TRUE)))
  expect_true(any(grepl("file_gate = MS_FILE_GATE,", drv, fixed = TRUE)))
  # the collector: only FILLED slots are known-basin starts
  expect_true(any(grepl('CO_BENCH_IDS <- c(CO_REF_IDS[c("incumbent", "new_basin")], CO_SEED_IDS, CO_FILE_IDS[seq_len(CO_FILE_N)])',
                        co, fixed = TRUE)))
})

test_that("MF4: THE FLASK FILE holds T8f's two points and values under the flask arm, and the driver's objective scores them", {
  skip_if_not(file.exists(MF_T8F), "T8f's output is not in this checkout")
  x <- readRDS(ccx_path(MF_FLASK_FILE)); T8F <- readRDS(MF_T8F)
  expect_identical(names(x$starts), c("t8c_block", "t8f_newton"))
  expect_identical(x$starts$t8c_block$u, T8F$points$uB)
  expect_identical(x$starts$t8f_newton$u, T8F$points$uN_all)
  expect_identical(x$starts$t8c_block$logpost, T8F$forecast$block$base)
  expect_identical(x$starts$t8f_newton$logpost, sum(T8F$rows$all_at_allN))
  expect_identical(x$provenance$from_md5, unname(tools::md5sum(MF_T8F)))
  md <- CCX_MODE_FLASK_INCUMBENT   # the labels are read through the registry name (test-mode-struct-lint.R's rule)
  expect_identical(x$struct, CCX_MODE_FLASK_STRUCT)
  expect_identical(x$seas_ml, ccx_mode_seas_ml(md)); expect_identical(x$pump_field, ccx_mode_pump_field(md))
  expect_identical(ccx_pin_label(x$pins), ccx_pin_label(CCX_MODE_FLASK_PINS))
  # the reader, under the arm the run fits (the gate, then the pins)
  g <- ccx_apply_gate(CCX_MODE_FLASK_STRUCT); h <- ccx_apply_pins(CCX_MODE_FLASK_PINS)
  on.exit({ ccx_unpin_params(h); ccx_unapply_gate(g) }, add = TRUE)
  r <- ms_read_file_starts(ccx_path(MF_FLASK_FILE), 4L,
                           list(struct = CCX_MODE_FLASK_STRUCT, seas_ml = ccx_mode_seas_ml(md),
                                pump_field = ccx_mode_pump_field(md), pins = CCX_MODE_FLASK_PINS), CCX_PARAM_NAMES)
  expect_identical(vapply(r, `[[`, "", "name"), c("t8c_block", "t8f_newton"))
  expect_identical(names(r[[1]]$u), CCX_PARAM_NAMES)
  # the DRIVER's construction of the objective (ccx_default_params, the structure, the pins in the base) at both points
  skip_if_no_cpp()
  bp <- ccx_default_params(); bp$pump_mode <- "N"
  bp <- ccx_apply_structure(bp, CCX_MODE_FLASK_STRUCT, "1", pump_field = "solved")
  for (n in names(CCX_MODE_FLASK_PINS)) bp[[n]] <- CCX_MODE_FLASK_PINS[[n]]
  lp <- ccx_make_logpost(base_params = bp)
  for (e in r) expect_equal(lp(e$u), e$logpost, tolerance = MF_REPRO_TOL, scale = 1, info = e$name)
})
