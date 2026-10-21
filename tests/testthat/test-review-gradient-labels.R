# =====================================================================
# Gate: Known issue 2's two panels carry their OWN labels (2026-10-21).
#
# Both facet strips read "CO₂ gradient (ppm)": facet_wrap's as_labeller() hands the labeller every panel's label
# at once, and app_plotmath_str() (app/R/plots.R) read only the first, so the δ¹³C panel was labelled CO₂. Found
# by the phone-layout session (outputs/diagnostics/mobile_layout_20261020/README.md); present at every width.
# The chart is built from the stored gradients (data/review_precompute.rds), as the live tab serves them.
# =====================================================================

.gl_env <- function(plotmath_str = NULL) {
  env <- new.env(parent = globalenv())
  assign("app_params", list(source = "posterior mode", status = "beta"), envir = env)
  local({ library(ggplot2)
    sys.source(file.path(.root, "app", "R", "plots.R"), envir = env)
    sys.source(file.path(.root, "app", "R", "review.R"), envir = env)
    sys.source(file.path(.root, "app", "R", "plots_review.R"), envir = env) })
  pre <- readRDS(file.path(.root, "data", "review_precompute.rds"))$values$gradients
  assign("rv_gradients", function() pre, envir = env)
  if (!is.null(plotmath_str)) assign("app_plotmath_str", plotmath_str, envir = env)
  env
}

#' The strip labels the chart draws, as plotmath source strings: what the labeller returns (`raw`), and one per
#' panel as drawn (`strips`; a labeller that returns fewer labels than panels has them recycled, which is how the
#' first label reached the second panel)
gl_strips <- function(env) {
  g <- env$rv_plot_gradient()
  lay <- ggplot2::ggplot_build(g)$layout$layout
  labs <- g$facet$params$labeller(lay[, "what", drop = FALSE])
  raw <- vapply(labs[[1]], function(e) paste(deparse(e), collapse = ""), "")
  list(raw = raw, strips = rep_len(raw, nrow(lay)))
}

test_that("1. each panel of Known issue 2 is labelled with its own quantity", {
  skip_if_not_installed("ggplot2")
  env <- .gl_env()
  x <- gl_strips(env); s <- x$strips
  expect_length(x$raw, 2L)                           # one label per panel, none recycled
  expect_false(identical(s[[1]], s[[2]]))
  expect_match(s[[1]], "CO", fixed = TRUE)
  expect_match(s[[2]], "13", fixed = TRUE)          # δ¹³C: the 13 is set as a plotmath superscript
  expect_identical(env$app_plotmath_str(c("CO₂ (ppm)", "δ¹³C (‰)")),
                   c(env$app_plotmath_str("CO₂ (ppm)"), env$app_plotmath_str("δ¹³C (‰)")))
})

test_that("MUTATION: the pre-fix app_plotmath_str (first element only) puts one label on both panels", {
  skip_if_not_installed("ggplot2")
  env <- .gl_env()
  first_only <- env$app_plotmath_str
  body(first_only) <- body(first_only)[-2]           # drop the vectorizing line
  environment(first_only) <- env
  menv <- .gl_env(plotmath_str = first_only)
  x <- gl_strips(menv)
  expect_length(x$raw, 1L)
  expect_identical(x$strips[[1]], x$strips[[2]])
})
