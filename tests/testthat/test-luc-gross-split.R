# =====================================================================
# Gate: the gross / forest-regrowth split of the prescribed land-use input
# (REGROWTH TIER 1, Marcus 2026-09-24; data-raw/build_luc_gross_split.R).
#
# THE CLAIM THE PRODUCT MAKES is that "adding forest regrowth" to CCX is
# ARITHMETIC ON A FORCING COLUMN -- the model already contains regrowth, netted
# inside GCB's bookkeeping flux before CCX sees it -- so reporting it costs no
# refit and moves no model output. Everything that claim rests on is here:
#
#   1. THE TWO HALVES SUM TO THE PRESCRIBED NET, EVERY YEAR, TO MACHINE
#      PRECISION. If they do not, the model's forcing has changed and the
#      "no refit" claim is void. This is the load-bearing test.
#   2. IT IS THE MODEL'S OWN NET, NOT A SECOND PRODUCT. The net column of the
#      split must equal data/forcing_emissions_historical.rds exactly -- the
#      series the forcing builder reads -- not merely resemble it.
#   3. `luc_scale` SCALES BOTH HALVES OR NEITHER. The model burns a FITTED
#      multiple of GCB's E_LUC, so a consumer that scales one half silently
#      breaks the closure by ~0.6 GtC/yr. Asserted on the real forcing column.
#   4. REGROWTH IS A REMOVAL AND THE SOURCE IS A SOURCE. A sign flip anywhere
#      in the chain would still close test 1, because the split is a difference.
#   5. THE ASSUMED YEARS ARE LABELLED AS ASSUMED. 57 % of the cumulative
#      regrowth comes from the pre-1959 back-extension, which is a construction
#      and not an observation; a product that lost that label would let the app
#      present it as measured. ⚠ The GCB-observed window must carry the observed
#      label for exactly the years GCB publishes, no more.
#   6. THE FUTURE PATH DECAYS AND IS LABELLED PRESCRIBED. It does NOT fall out
#      of the scenarios: the prescribed net LUC goes NEGATIVE in four of five
#      SSPs, which in bookkeeping accounting is gross regrowth OVERTAKING gross
#      clearing. Test 6b pins that fact so nobody re-derives the wrong design.
#   7. THE TIMESCALE'S BRACKET CARRIES THE EFFECTIVE-SAMPLE CORRECTION. The fit
#      residuals are almost perfectly red (lag-1 rho ~ 0.9); the uncorrected
#      interval is ~5x too tight and would assert 1.25-yr precision on a
#      66-point record.
# =====================================================================

LGT_FILE      <- ccx_path("data", "forcing_luc_gross_split.rds")
LGT_TOL       <- 1e-12     # GtC/yr; the split is arithmetic
LGT_OBS_YEARS <- c(1959, 2024)   # the years GCB publishes the decomposition for
LGT_MIN_RHO   <- 0.5       # below this the effective-sample correction would be moot
LGT_MIN_NSSP  <- 4         # SSPs whose net LUC must go negative (measured: 4 of 5)

skip_if_no_split <- function()
  skip_if(!file.exists(LGT_FILE), "data/forcing_luc_gross_split.rds absent")

test_that("1. the two halves sum to the prescribed net, every year", {
  skip_if_no_split()
  p <- readRDS(LGT_FILE); h <- p$historical
  expect_lt(max(abs(h$gross_GtC + h$regrowth_GtC - h$net_GtC)), LGT_TOL)
})

test_that("2. the net being split is the model's OWN prescribed series", {
  skip_if_no_split()
  p  <- readRDS(LGT_FILE); h <- p$historical
  eh <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  expect_identical(h$year, eh$year)
  expect_equal(h$net_GtC, eh$luc_GtC, tolerance = 0)
})

test_that("3. luc_scale scales both halves or neither", {
  skip_if_no_split()
  p  <- readRDS(LGT_FILE); h <- p$historical
  # `ccx_mode_params()` rather than a direct readRDS -- see the note in
  # calibration/diag_luc_gross_split.R at the same read (2026-09-25).
  pm <- ccx_migrate_par_set(ccx_mode_params(CCX_MODE_CANONICAL))
  ls <- pm$luc_scale
  F  <- suppressWarnings(ccx_build_forcing("historical", range(h$year),
                                           luc_scale = ls, emis_method = "constant"))
  el <- ccx_forcing_eluc_annual(F)
  i  <- match(el$year, h$year)
  expect_lt(max(abs(ls * (h$gross_GtC[i] + h$regrowth_GtC[i]) - el$eluc)), 1e-10)
  # MUTATION: scale only one half and the closure must break by a visible amount
  expect_gt(max(abs((h$gross_GtC[i] + ls * h$regrowth_GtC[i]) - el$eluc)), 0.1)
})

test_that("4. regrowth is a removal and the gross source is a source", {
  skip_if_no_split()
  p <- readRDS(LGT_FILE); h <- p$historical
  expect_true(all(h$regrowth_GtC < 0))
  expect_true(all(h$gross_GtC > 0))
  expect_true(all(h$gross_GtC > h$net_GtC))   # netting can only reduce the source
})

test_that("5. the assumed years are labelled assumed, and only those", {
  skip_if_no_split()
  p <- readRDS(LGT_FILE); h <- p$historical
  obs <- grepl("observed", h$source, fixed = TRUE)
  expect_equal(range(h$year[obs]), LGT_OBS_YEARS)
  expect_true(all(grepl("ASSUMED", h$source[!obs], fixed = TRUE)))
  # the labels are load-bearing: the majority of cumulative regrowth is assumed
  expect_gt(abs(sum(h$regrowth_GtC[!obs])), abs(sum(h$regrowth_GtC[obs])))
})

test_that("6a. the future path decays to zero and says it is prescribed", {
  skip_if_no_split()
  p <- readRDS(LGT_FILE); f <- p$futures
  expect_true(all(grepl("ASSUMED", f$source, fixed = TRUE)))
  expect_lt(max(abs(f$gross_GtC + f$regrowth_GtC - f$net_GtC)), LGT_TOL)
  for (sc in unique(f$scenario)) {
    d <- f[f$scenario == sc, ]
    d <- d[order(d$year), ]
    expect_true(all(diff(abs(d$regrowth_GtC)) < 0))        # monotonically decaying
    expect_lt(abs(d$regrowth_GtC[nrow(d)]), 1e-3)          # and it reaches zero
  }
})

test_that("6b. the scenarios' net LUC goes NEGATIVE, so the decay cannot be inherited", {
  skip_if_no_split()
  p <- readRDS(LGT_FILE); f <- p$futures
  neg <- sapply(split(f$net_GtC, f$scenario), function(v) any(v < 0))
  expect_gte(sum(neg), LGT_MIN_NSSP)
})

test_that("7. the timescale bracket carries the effective-sample correction", {
  skip_if_no_split()
  p <- readRDS(LGT_FILE)
  expect_gt(p$tau_resid_rho, LGT_MIN_RHO)
  expect_lt(p$tau_n_eff, p$tau_n_fit)
  # the stored bracket must be the WIDE one -- wider than 1/n would have given.
  # A naive interval on 66 points was 19.00-20.25; anything that narrow is the
  # uncorrected one leaking back in.
  expect_gt(diff(p$tau_bracket), 2)
  expect_true(p$tau_yr > p$tau_bracket[1] && p$tau_yr < p$tau_bracket[2])
})
