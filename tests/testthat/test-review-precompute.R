# =====================================================================
# Gate: the Known-issues tab's PRECOMPUTED values (2026-10-15; Marcus: "Precompute the known issues").
#
# data/review_precompute.rds stores the rv_memo() value of each key in RV_PRE_KEYS (app/R/review.R) at the
# canonical; calibration/build_review_precompute.R makes it. It can go stale two ways:
#   (1) an ADOPTION that does not rebuild it. The app refuses it on the md5 (and computes live, as before);
#       test 1 FAILS rather than skips, so the suite says so.
#   (2) a CODE change that moves a value at the same mode file. Test 2 recomputes every key live and requires
#       IDENTITY with the stored value: the same functions on the same inputs, so an identity gate, exact.
# Tests 3-4 are the mutation half: the refusal check and rv_memo()'s use of the product, each broken on purpose.
# =====================================================================

.pre_file <- file.path(.root, "data", "review_precompute.rds")
.pre_env <- function() {
  e <- new.env(parent = globalenv())
  sys.source(file.path(.root, "app", "R", "review.R"), envir = e)
  e
}

test_that("1. the product exists, is the canonical's, and holds no failure", {
  expect_true(file.exists(.pre_file))
  x <- readRDS(.pre_file); e <- .pre_env()
  expect_identical(e$rv_pre_problems(x, ccx_mode_file()), character(0))
  expect_identical(x$provenance$rng, "none")
  expect_identical(x$provenance$keys, e$RV_PRE_KEYS)
  expect_false(grepl("^/", x$provenance$mode_file))   # repo-relative: the product ships publicly
  for (k in names(x$values)) expect_false(e$rv_failed(x$values[[k]]), info = k)
})

test_that("2. every stored value is what the live computation returns now", {
  skip_if_no_cpp()
  x <- readRDS(.pre_file)
  withr::local_options(ccx.rv_precompute = FALSE)
  e <- .pre_env()
  live <- list()
  for (k in names(e$RV_PRE_KEYS)) {
    live[[k]] <- get(e$RV_PRE_KEYS[[k]], envir = e)()
    expect_false(e$rv_failed(live[[k]]), info = k)
    expect_identical(x$values[[k]], live[[k]], info = k)
  }
  # the comparison has power at roundoff: one stored number moved by 1e-12 (relative) is caught
  m <- x$values$enso_slope; m$ratio <- m$ratio * (1 + 1e-12)
  expect_false(identical(m, live$enso_slope))
})

test_that("3. MUTATION: the refusal check rejects another mode, another md5 and a missing key", {
  x <- readRDS(.pre_file); e <- .pre_env(); mf <- ccx_mode_file()
  m <- x; m$provenance$mode <- paste0(CCX_MODE_CANONICAL, "_old")
  expect_length(e$rv_pre_problems(m, mf), 1L)
  m <- x; m$provenance$mode_md5 <- strrep("0", 32)
  expect_length(e$rv_pre_problems(m, mf), 1L)
  m <- x; m$values$pulse <- NULL
  expect_match(e$rv_pre_problems(m, mf), "lacks pulse")
})

test_that("4. MUTATION: rv_memo() serves a stored value without computing; computes when refused or off", {
  sentinel <- list(sentinel = TRUE)
  e <- .pre_env(); assign("values", list(pulse = sentinel), envir = e$RV_PRE)
  called <- FALSE
  expect_identical(e$rv_memo("pulse", function() { called <<- TRUE; "live" }), sentinel)
  expect_false(called)
  e <- .pre_env(); assign("values", NULL, envir = e$RV_PRE)          # absent or refused product
  expect_identical(e$rv_memo("pulse", function() "live"), "live")
  e <- .pre_env(); assign("values", list(rep_dc = sentinel), envir = e$RV_PRE)
  expect_identical(e$rv_memo("rep_dc", function() "live"), "live")  # a key outside RV_PRE_KEYS
  withr::local_options(ccx.rv_precompute = FALSE)
  e <- .pre_env(); assign("values", list(pulse = sentinel), envir = e$RV_PRE)
  expect_identical(e$rv_memo("pulse", function() "live"), "live")   # switched off
})
