# =====================================================================
# Gate: Known-issues card 8, the ocean's climate effect (2026-10-08 j).
#
# The card's numbers are not typed: they are printed under its two charts from data/ocean_climate_card.rds, which
# calibration/build_ocean_climate_card.R collects from three committed diagnostics at the canonical. What can go
# stale is (1) the PRODUCT -- an adoption that does not rebuild it (this FAILS, by design, rather than skipping:
# memory skip_guard_silent_on_adoption) -- and (2) the card's two QUALITATIVE words, which are tied to the product
# here with tolerances read off the product's own uncertainty, never hand-picked:
#   "about twice"     2 lies inside the 2015-24 ratio's range over GCB's 1 sigma AND inside the per-K ratio +- 1 se;
#   "decades earlier" the emergence lead is at least two decades (the word's own meaning, plural).
# =====================================================================

.oc_file <- file.path(.root, "data", "ocean_climate_card.rds")
.oc_rv   <- new.env(parent = globalenv())
sys.source(file.path(.root, "app", "R", "review.R"), envir = .oc_rv)
.oc_card <- function() Filter(function(c) identical(c$id, 8), .oc_rv$RV_CARDS)[[1]]

oc_about_twice <- function(x) {
  r <- x$effect$ratio_range; k <- x$shape$per_K_ratio
  2 >= min(r) && 2 <= max(r) && abs(k[["ratio"]] - 2) <= k[["se"]]
}
oc_decades_earlier <- function(x) x$shape$emergence[["lead"]] >= 20

test_that("1. the product is the CANONICAL's, built from the committed inputs it names", {
  expect_true(file.exists(.oc_file))
  x <- readRDS(.oc_file)
  expect_identical(.oc_rv$rv_oclim_problems(x, ccx_mode_file()), character(0))
  for (nm in names(x$provenance$inputs)) {
    p <- x$provenance$inputs[[nm]]
    expect_true(file.exists(file.path(.root, p[["path"]])), info = nm)
    expect_identical(unname(tools::md5sum(file.path(.root, p[["path"]]))), p[["md5"]], info = nm)
  }
  expect_identical(x$provenance$rng, "none")
})

test_that("2. the card's qualitative words follow from the product", {
  x <- readRDS(.oc_file)
  c8 <- .oc_card()
  expect_true(oc_about_twice(x))
  expect_true(grepl("about twice", c8$title, fixed = TRUE) && grepl("about twice", c8$plain, fixed = TRUE))
  expect_true(oc_decades_earlier(x))
  # 2026-10-15 (Marcus, "Update the pins"): his plain no longer says "decades earlier", so the text is held to
  # the claim only WHERE it makes it -- if the phrase returns, the product must still support it.
  expect_false(grepl("decades earlier", c8$plain, fixed = TRUE) && !oc_decades_earlier(x))
  # the futures chart's arm is the GCB-sized one, and the +-1 sd arms bracket it
  f <- x$stake$f
  expect_true(f[["f_T_lo"]] < f[["f_T"]] && f[["f_T"]] < f[["f_T_hi"]] && f[["f_T_hi"]] < 1)
  t <- x$stake$table
  expect_true(all(pmin(t$d_2300_gcb_lo_sd, t$d_2300_gcb_hi_sd) <= t$d_2300 &
                  t$d_2300 <= pmax(t$d_2300_gcb_lo_sd, t$d_2300_gcb_hi_sd)))
})

test_that("3. both charts RENDER from the product", {
  skip_if_not_installed("ggplot2")
  x <- readRDS(.oc_file)
  env <- new.env(parent = globalenv())
  assign("app_params", list(source = "posterior mode", status = "beta"), envir = env)
  ok <- tryCatch({
    local({ library(ggplot2)
      sys.source(file.path(.root, "app", "R", "plots.R"), envir = env)
      sys.source(file.path(.root, "app", "R", "review.R"), envir = env)
      sys.source(file.path(.root, "app", "R", "plots_review.R"), envir = env) })
    TRUE }, error = function(e) { message(conditionMessage(e)); FALSE })
  expect_true(ok)
  assign("rv_ocean_climate", function() x, envir = env)
  for (f in c("rv_plot_oclim", "rv_plot_oclim_stake")) {
    g <- env[[f]]()
    expect_s3_class(g, "ggplot")
    expect_silent(ggplot2::ggplot_build(g))
  }
})

test_that("MUTATION: each check fails when what it guards is broken", {
  x <- readRDS(.oc_file)
  bad <- x; bad$provenance$mode <- "hilda33p"
  expect_gt(length(.oc_rv$rv_oclim_problems(bad, ccx_mode_file())), 0L)
  bad <- x; bad$provenance$mode_md5 <- strrep("0", 32)
  expect_gt(length(.oc_rv$rv_oclim_problems(bad, ccx_mode_file())), 0L)
  bad <- x; bad$effect$ratio_range <- c(1.2, 1.6)                       # "about twice" would be false
  expect_false(oc_about_twice(bad))
  bad <- x; bad$shape$per_K_ratio <- c(ratio = 1.3, se = 0.2)
  expect_false(oc_about_twice(bad))
  bad <- x; bad$shape$emergence[["lead"]] <- 12                        # one decade is not "decades"
  expect_false(oc_decades_earlier(bad))
})
