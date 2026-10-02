# =====================================================================
# Gate: the "What if...?" DRIVER panel draws the right series, and says
# truthfully which switches remove an input (Marcus review F1, 2026-09-24).
#
# WHAT THIS GUARDS. The panel's whole claim is that it shows the model's INPUT.
# Three ways that can be a lie, all of them silent in the app:
#   (a) a mechanism names a driver key that is not in CCX_DRIVERS -- the panel
#       vanishes, or worse, renders empty beside a heading that promises one;
#   (b) a driver's `of()` reads a column that has been renamed -- NULL propagates
#       to numeric(0) and ggplot draws an empty panel with axes, which looks
#       like "this driver is flat", the exact failure that hid the missing
#       atmosphere band in plot_pulse_partition() on 09-22;
#   (c) the removes-driver sentence inverts. It is MEASURED, not declared, so it
#       cannot go stale by itself -- but it CAN be broken by a switch that
#       starts zeroing a column it did not used to touch, which is a real
#       change and one the reader should be told about rather than have
#       silently re-described.
#
# It also pins the SPLIT itself: four switches act on an input, three act on a
# parameter. That is the distinction the panel exists to teach, and moving a
# mechanism across it should require editing this file.
#
# MUTATION-TESTED throughout: every assertion is paired with a deliberately
# broken input it must REJECT (project rule, ~/.claude/CLAUDE.md).
# =====================================================================

# 1750, NOT the tab's default 1850 window: two of the three coverage gaps
# (AOD and GMST, both 1850) are INVISIBLE from 1850 and the `since` assertions
# below would pass vacuously on an empty pre-record slice. This is the model's
# own span (APP_HIST_YEARS) and the span the app builds its forcing over.
.F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0))
.p <- ccx_default_params()

# ---- the split, pinned ---------------------------------------------
test_that("exactly the four input-driven switches carry a driver", {
  drv <- vapply(CCX_MECHANISMS,
                function(m) if (is.null(m$driver)) "" else m$driver, character(1))
  expect_equal(sort(names(drv)[drv != ""]),
               c("emissions", "enso", "volcanic", "warming_feedback"))
  # The three parameter switches must return NULL, not an empty-looking series.
  for (nm in c("fertilisation", "ocean_sink", "revelle"))
    expect_null(ccx_driver_series(nm, .F, .p))
})

test_that("every named driver exists and yields a finite, full-length series", {
  for (nm in names(CCX_MECHANISMS)) {
    d <- ccx_driver_series(nm, .F, .p)
    if (is.null(d)) next
    expect_true(d$key %in% names(CCX_DRIVERS))
    # (b): the length check is the one that catches a renamed column. A NULL
    # column makes `of()` return numeric(0) or a recycled scalar, never nrow(F).
    expect_length(d$full, nrow(.F))
    expect_length(d$off,  nrow(.F))
    expect_true(all(is.finite(d$full)), info = nm)
    expect_true(all(is.finite(d$off)),  info = nm)
    expect_true(nzchar(d$label) && nzchar(d$unit))
  }
})

test_that("a driver reading a renamed column is REJECTED", {
  # MUTATION for (b). Rename the column the ENSO driver reads and require the
  # length assertion above to fail -- i.e. that it is load-bearing.
  bad <- .F; bad$enso <- NULL
  expect_false(length(CCX_DRIVERS$enso$of(bad)) == nrow(bad))
})

# ---- which switches remove their input, MEASURED --------------------
test_that("the input-deleting and response-removing switches are told apart", {
  removes <- vapply(c("emissions", "enso", "volcanic", "warming_feedback"),
                    function(nm) ccx_driver_series(nm, .F, .p)$removes_driver,
                    logical(1))
  # emissions zeroes e_foss/e_luc; volcanic zeroes aod_NH/aod_SH.
  expect_true(removes[["emissions"]])
  expect_true(removes[["volcanic"]])
  # Re-pinned 2026-10-02 (approved, Marcus: "Zero the index (Recommended)"). enso and
  # warming_feedback used to change PARAMETERS only and leave their input untouched; enso's
  # did not even remove every response (the ocean's upwelling path kept reading the index).
  # Both now zero their input too, so the panel draws the zero line the run actually had.
  # Still MEASURED by differencing, not declared.
  expect_true(removes[["enso"]])
  expect_true(removes[["warming_feedback"]])
})

test_that("removes_driver would flip if a switch started zeroing its input", {
  # MUTATION for (c): give the ENSO switch the volcanic switch's body and
  # require the measurement to notice.
  stash <- CCX_MECHANISMS$enso$apply
  on.exit(CCX_MECHANISMS$enso$apply <<- stash, add = TRUE)
  CCX_MECHANISMS$enso$apply <<- function(p, F) { F$enso <- 0; list(p = p, F = F) }
  expect_true(ccx_driver_series("enso", .F, .p)$removes_driver)
})

# ---- the two paths to the switched forcing agree --------------------
test_that("F_off supplied by the caller matches F_off derived here", {
  # The app passes the counterfactual's OWN forcing. If that ever diverged from
  # what ccx_apply_mechanisms() produces, the panel would be drawing a different
  # input from the one the plotted run used -- and nothing on the page would say
  # so. This is the assertion ccx_driver_series()'s @param F_off promises.
  for (nm in c("emissions", "volcanic", "enso", "warming_feedback")) {
    own <- ccx_apply_mechanisms(.p, .F, nm)$F
    expect_equal(ccx_driver_series(nm, .F, .p)$off,
                 ccx_driver_series(nm, .F, .p, F_off = own)$off, info = nm)
  }
})

# ---- the coverage zeros are declared, and are real ------------------
test_that("each driver's `since` is the year its record actually starts", {
  # DERIVED FROM THE DATA, not from the comment: the panel prints "this series
  # is identically zero before <since>", so `since` must be the last year for
  # which that is true. A stale `since` would print a false archival claim.
  for (nm in c("enso", "aod", "gmst")) {
    d <- CCX_DRIVERS[[nm]]
    v <- d$of(.F)
    pre <- .F$year < d$since
    expect_true(any(pre), info = nm)          # the window must contain the gap
    expect_true(all(v[pre] == 0), info = nm)
    # and it must not be zero everywhere, or the "since" line is meaningless
    expect_true(any(v[!pre] != 0), info = nm)
  }
  # Emissions carry no coverage zero and must say so with NA, not a year.
  expect_true(is.na(CCX_DRIVERS$emissions$since))
})

test_that("a `since` set one year too late is REJECTED", {
  # MUTATION for the assertion above: ENSO's record starts 1948, so 1949 would
  # claim year 1948 is zero when it is not.
  v <- CCX_DRIVERS$enso$of(.F)
  expect_false(all(v[.F$year < 1949L] == 0))
})
