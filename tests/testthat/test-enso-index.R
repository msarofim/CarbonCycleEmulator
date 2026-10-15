# =====================================================================
# test-enso-index.R -- the ENSO index structure axis (2026-09-29, Marcus)
#
# `enso_index` exists so the index's +0.0082 degC/yr trend can be removed in an
# arm without touching the shipped model. For that to be true:
#   1. the default stamps "demean" and is the shipped index (ruling A);
#   2. "detrend" removes the in-window trend and nothing is fabricated outside
#      the ENSO-active span; "relsst_lp" keeps the same span;
#   3. a run whose forcing carries a different index than its parameters name
#      FAILS -- mutation-tested both ways and for an unstamped table.
# =====================================================================

enso_trend <- function(F, win = FORC_ENSO_DEMEAN_WIN) {
  k <- F$year >= win[1] & F$year <= win[2]
  unname(stats::coef(stats::lm(F$enso[k] ~ F$t[k]))[2])
}
FI <- lapply(setNames(nm = names(CCX_ENSO_INDEX_CODES)), function(i)
  ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, enso_index = i))

test_that("the default is 'demean', stamped, and carries the shipped trend", {
  d <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0)
  expect_identical(attr(d, "enso_index"), "demean")
  expect_identical(d$enso, FI$demean$enso)
  expect_identical(ccx_enso_index_of(ccx_default_params()), "demean")
  # the audit's number (09-29 d): the thing the switch exists to remove
  expect_gt(enso_trend(d), 0.005)
})

test_that("detrend removes the in-window trend; every index keeps the 1948+ span", {
  expect_lt(abs(enso_trend(FI$detrend)), 1e-10)
  for (i in names(FI)) {
    k <- FI[[i]]$year >= FORC_ENSO_DEMEAN_WIN[1] & FI[[i]]$year <= FORC_ENSO_DEMEAN_WIN[2]
    expect_lt(abs(mean(FI[[i]]$enso[k])), 1e-10, label = paste(i, "in-window mean"))
    expect_true(all(FI[[i]]$enso[FI[[i]]$year < 1948] == 0), label = paste(i, "pre-1948 zero"))
    expect_identical(attr(FI[[i]], "enso_index"), i)
  }
  # nothing else may move
  for (cc in setdiff(names(FI$demean), "enso"))
    expect_identical(FI$detrend[[cc]], FI$demean[[cc]], label = cc)
})

test_that("a params/forcing index mismatch refuses to run (mutation tests)", {
  p0 <- ccx_default_params(); p1 <- p0; p1$enso_index <- CCX_ENSO_INDEX_CODES[["detrend"]]
  expect_error(ccx_enso_index_check(p1, FI$demean), "ENSO index mismatch")
  expect_error(ccx_enso_index_check(p0, FI$detrend), "ENSO index mismatch")
  un <- FI$detrend; attr(un, "enso_index") <- NULL
  expect_error(ccx_enso_index_check(p1, un), "unstamped")
  expect_true(ccx_enso_index_check(p1, FI$detrend))
  expect_true(ccx_enso_index_check(p0, un))          # legacy unstamped tables run as demean
  q <- FI$demean; attr(q, "enso_index") <- "none"
  expect_true(ccx_enso_index_check(p1, q))
  p9 <- p0; p9$enso_index <- 9L
  expect_error(ccx_enso_index_of(p9), "not one of")
  # and the stamp survives marshaling, where the run path checks it
  expect_identical(attr(ccx_cpp_forcing_prep(FI$detrend), "enso_index"), "detrend")
  # the ONE run path checks before the core is reached (a prep naming detrend,
  # a demean table: must stop at the guard, not in C++)
  expect_error(ccx_run_prepared(NULL, list(enso_index = "detrend"), FI$demean),
               "ENSO index mismatch")
})
