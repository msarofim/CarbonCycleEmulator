# =====================================================================
# Gate: the F2 residual NUMBERS on the growth panel (Marcus 2026-09-24,
# "can the F2 residual numbers be a part of the 2nd panel?").
#
# WHAT THIS GUARDS, and every one of these fails SILENTLY in the app:
#   (a) THE LIKE-FOR-LIKE WINDOW. The model runs from 1750 and GCB's
#       atmospheric growth starts 1959. A residual taken over the slider's
#       range rather than the INTERSECTION would compare 174 model years
#       against 66 observed ones -- the exact bug the scatter sentence beside
#       it already had and fixed. A merge() on year hides it: the answer is
#       still a number, just of a different window than the one printed.
#   (b) THE ANNUALISATION DRIFTING FROM THE CHART'S. The residual must be
#       measured against EXACTLY the series plot_growth_rate() draws. That is
#       why app_annual_growth() was extracted from three hand-copies; this
#       asserts the chart and the number still share it.
#   (c) THE PARTIAL-YEAR GUARD. A year with 7 months has a mean that is a
#       seasonal phase, not an annual mean, and differencing it manufactures
#       an outlier at each end of every window -- which would land straight in
#       `worst_year`, the one statistic here meant to be read as physics.
#
# MUTATION-TESTED: each assertion is paired with a broken input it must reject.
# =====================================================================

.gr_years <- c(1750, 2024)
.gr_F <- suppressWarnings(ccx_build_forcing("historical", .gr_years, prod_c14 = 0))
# ⛔ gamma_enso MUST BE SEEDED. `ccx_default_params()` has ALL FOUR ENSO gammas
# at 0 (the table's inits are 0.25/0.25/0/0), so on bare defaults the `enso`
# knockout is a genuine NO-OP and the counterfactual arm below is bit-identical
# to the base. This gate's own first draft did not seed it and "the knockout
# moves the residual" failed -- correctly, against a model where it cannot.
# test-mechanisms.R seeds 0.5 for exactly this reason; matched here.
.gr_p <- ccx_set_enso(ccx_default_params(), list(gamma_enso = 0.5))
.gr_sp <- ccx_spinup(.gr_p)
.gr_F$c14_cosmo <- .gr_sp$prod_c14
.gr_base <- ccx_run_fast(.gr_sp, .gr_F)$out
.gr_gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)

# the app sources its plot helpers from app/R; setup.R only sources R/
.gr_env <- new.env(parent = environment())
local({
  assign("app_params", list(source = "test", status = "test"), envir = .gr_env)
  suppressMessages(library(ggplot2))
  sys.source(file.path(.root, "app", "R", "plots.R"), envir = .gr_env)
})
ann   <- get("app_annual_growth",   envir = .gr_env)
obsg  <- get("app_obs_growth",      envir = .gr_env)
resid <- get("app_growth_residuals", envir = .gr_env)
MINY  <- get("GROWTH_RESID_MIN_YEARS", envir = .gr_env)

test_that("(c) the annualisation drops partial years at both ends", {
  g <- ann(.gr_base)
  # every year it keeps must have had all 12 months
  keep <- table(floor(.gr_base$t))
  expect_true(all(keep[as.character(g$year)] == 12))
  # and a run truncated mid-year must lose that year, not report it
  cut <- .gr_base[.gr_base$t < max(.gr_base$t) - 0.5, ]
  expect_false(max(ann(cut)$year) == max(floor(cut$t)))
})

test_that("(b) the chart and the number share one annualisation", {
  # The chart's own series, pulled back out of the built plot, must equal the
  # helper's. If plot_growth_rate() ever grows a private copy again, this fails.
  pg <- get("plot_growth_rate", envir = .gr_env)
  PAL <- get("PAL", envir = .gr_env)
  d <- ggplot2::ggplot_build(pg(.gr_base, NULL, .gr_gcb, c(1960, 2024)))$data[[1]]
  # ⚠ layer 1 holds BOTH drawn series (model and observed) -- 130 rows, not 65.
  # Select the MODEL one by its palette colour rather than by position, which
  # would silently follow a reordering of the legend.
  d <- d[d$colour == PAL[["model"]], ]
  mine <- ann(.gr_base)
  mine <- mine[mine$year >= 1960 & mine$year <= 2024, ]
  expect_equal(nrow(d), nrow(mine))
  expect_equal(sort(round(d$y, 9)), sort(round(mine$g, 9)))
})

test_that("(a) the residual is taken over the window it is HANDED", {
  yr <- c(1980L, 2000L)
  r <- resid(.gr_base, NULL, .gr_gcb, yr)
  expect_false(is.null(r))
  # n must be the overlap of the window with BOTH records, never the model's own
  ob <- obsg(.gr_gcb); mo <- ann(.gr_base)
  expect_equal(r$full$n,
               length(intersect(ob$year[ob$year >= yr[1] & ob$year <= yr[2]],
                                mo$year[mo$year >= yr[1] & mo$year <= yr[2]])))
  expect_true(r$full$worst_year >= yr[1] && r$full$worst_year <= yr[2])
})

test_that("(a) a pre-observational window is REFUSED, not answered", {
  # MUTATION for the like-for-like trap: 1850-1900 has model years and NO
  # observed ones. A function that silently returned the model's own numbers
  # here is exactly the failure mode; it must return NULL.
  expect_null(resid(.gr_base, NULL, .gr_gcb, c(1850L, 1900L)))
  # and a window shorter than the stated floor is refused too
  expect_null(resid(.gr_base, NULL, .gr_gcb, c(1990L, 1990L + MINY - 2L)))
})

test_that("bias, rms and worst are internally consistent", {
  r <- resid(.gr_base, NULL, .gr_gcb, c(1959L, 2024L))$full
  expect_true(r$rms >= abs(r$bias))          # RMS can never be below |mean|
  expect_true(abs(r$worst) >= r$rms)         # the worst is at least typical
  expect_gt(r$n, MINY)
})

test_that("a counterfactual arm is reported separately and can differ", {
  m <- ccx_apply_mechanisms(.gr_p, .gr_F, "enso")
  sp <- ccx_spinup(m$p); Fa <- m$F; Fa$c14_cosmo <- sp$prod_c14
  alt <- ccx_run_fast(sp, Fa)$out
  r <- resid(.gr_base, alt, .gr_gcb, c(1959L, 2024L))
  expect_false(is.null(r$alt))
  expect_equal(r$full$n, r$alt$n)            # both arms, same years
  # the ENSO knockout must actually move the residual, or the sentence the
  # panel prints about it is decorative
  expect_true(abs(r$alt$rms - r$full$rms) > 1e-6)
})
