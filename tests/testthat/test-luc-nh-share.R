# =====================================================================
# Gate: time-varying land-use hemispheric share (2026-08-15, review item 5b).
#
# The change replaces a constant NH share of E_LUC (0.55) with an OSCAR-sourced
# per-year series running 0.88 -> 0.35. Like 5c it is a REDISTRIBUTION -- this
# time between hemispheres rather than between months -- so the invariants are
# the same shape and so are the ways it can be silently wrong:
#
#   1. THE GLOBAL ANNUAL TOTAL IS UNTOUCHED. A split cannot create or destroy
#      carbon. (Note the MONTHLY global total is NOT invariant and must not be
#      asserted to be: 5c already redistributes NH and SH into different months,
#      so moving mass between hemispheres moves it between months too. That is
#      5c's behaviour, not this change's, and test 1c pins the distinction.)
#   2. THE SWITCH OFF REPRODUCES THE OLD MODEL EXACTLY, including for a WINDOWED
#      run, which is the only path that exercises the pre-window split.
#   3. THE DIRECTION IS RIGHT AND SURVIVES THE BRACKET. Early clearing is
#      NH-dominated, modern clearing is not, and the two do not overlap under
#      any admissible within-region judgement. This is the measurement the whole
#      product rests on; if a future OSCAR revision breaks it, the product needs
#      re-deciding, not re-baselining.
#   4. THE PRE-WINDOW CARBON TAKES ITS OWN SHARE. A run starting in 1900 must
#      split ~58 GtC of prior clearing on the pre-1900 share (~0.79), not on the
#      window's (~0.49) and not on the retired constant. Getting this wrong
#      misplaces ~14 GtC of converted land and NOTHING ELSE IN THE SUITE WOULD
#      SEE IT -- the flux would still conserve.
#   5. THE PRODUCT REPRODUCES ITS SOURCE. The shipped rds must equal a
#      recomputation from OSCAR's regional sheet under the same bracket table,
#      so the two cannot drift apart silently.
# =====================================================================

skip_if_no_share <- function()
  skip_if(is.null(ccx_luc_nh_share_product()),
          "data/forcing_luc_nh_share.rds absent")

LNS_YEARS <- c(1750, 2024)
LNS_WINDOW_START <- 1900          # the windowed-run case, for tests 2 and 4

# the on/off forcing pair, built once per file (review B4, 2026-09-12): tests
# 1a-1d rebuilt it. ⚠ Keyed on the SEASONALITY flag as well as `on` and the span:
# test 1c's `flat` arm is built under FORC_USE_EMIS_SEASONALITY = FALSE and must
# never be served the default-flag forcing.
lns_memo <- new.env()
lns_forcing <- function(on, years = LNS_YEARS) {
  k <- paste(on, paste(years, collapse = ":"), FORC_USE_EMIS_SEASONALITY)
  if (is.null(lns_memo[[k]])) lns_memo[[k]] <- lns_forcing_raw(on, years)
  lns_memo[[k]]
}
lns_forcing_raw <- function(on, years = LNS_YEARS) {
  old <- FORC_USE_LUC_NH_SHARE_TS
  on.exit(assign("FORC_USE_LUC_NH_SHARE_TS", old, envir = globalenv()))
  assign("FORC_USE_LUC_NH_SHARE_TS", on, envir = globalenv())
  suppressWarnings(ccx_build_forcing("historical", years, prod_c14 = 1))
}
lns_annual <- function(F, v) as.numeric(tapply(v, F$year, mean))

# ---------------------------------------------------------------------
test_that("1a. the global ANNUAL land-use flux is unchanged by the split", {
  skip_if_no_share()
  on <- lns_forcing(TRUE); off <- lns_forcing(FALSE)
  expect_equal(lns_annual(on,  on$e_luc_NH  + on$e_luc_SH),
               lns_annual(off, off$e_luc_NH + off$e_luc_SH),
               tolerance = 1e-12)
})

test_that("1b. the global cumulative land-use carbon is unchanged at year ends", {
  skip_if_no_share()
  on <- lns_forcing(TRUE); off <- lns_forcing(FALSE)
  d <- on$month == 12L
  expect_equal((on$cum_luc_NH  + on$cum_luc_SH)[d],
               (off$cum_luc_NH + off$cum_luc_SH)[d], tolerance = 1e-9)
})

test_that("1c. the MONTHLY global total is NOT invariant, and that is 5c's doing", {
  skip_if_no_share()
  skip_if(is.null(ccx_emission_seasonality()), "seasonality product absent")
  on <- lns_forcing(TRUE); off <- lns_forcing(FALSE)
  # With hemispheric seasonality on, both forcings already break monthly closure
  # against a no-seasonality reference; this test exists so that a future reader
  # meeting the non-closure knows which change owns it.
  old <- FORC_USE_EMIS_SEASONALITY
  on.exit(assign("FORC_USE_EMIS_SEASONALITY", old, envir = globalenv()))
  assign("FORC_USE_EMIS_SEASONALITY", FALSE, envir = globalenv())
  flat <- lns_forcing(FALSE)
  assign("FORC_USE_EMIS_SEASONALITY", old, envir = globalenv())
  expect_gt(max(abs((off$e_luc_NH + off$e_luc_SH) -
                    (flat$e_luc_NH + flat$e_luc_SH))), 0.1)   # 5c alone: ~0.68
  expect_gt(max(abs((on$e_luc_NH + on$e_luc_SH) -
                    (flat$e_luc_NH + flat$e_luc_SH))), 0.1)   # 5b+5c:    ~0.97
})

test_that("1d. mean_year(luc_NH) is EXACTLY share(y) * mean_year(luc)", {
  skip_if_no_share()
  F  <- lns_forcing(TRUE)
  sh <- ccx_luc_nh_share(sort(unique(F$year)))
  expect_equal(lns_annual(F, F$e_luc_NH),
               sh * lns_annual(F, F$e_luc_NH + F$e_luc_SH), tolerance = 1e-14)
})

# ---------------------------------------------------------------------
test_that("2. the switch OFF reproduces the constant-share forcing exactly", {
  skip_if_no_share()
  old <- FORC_USE_LUC_NH_SHARE_TS
  on.exit(assign("FORC_USE_LUC_NH_SHARE_TS", old, envir = globalenv()))
  assign("FORC_USE_LUC_NH_SHARE_TS", FALSE, envir = globalenv())
  for (yy in list(LNS_YEARS, c(LNS_WINDOW_START, LNS_YEARS[2]))) {
    F <- suppressWarnings(ccx_build_forcing("historical", yy, prod_c14 = 1))
    luc <- F$e_luc_NH + F$e_luc_SH
    expect_equal(ccx_luc_nh_share(unique(F$year)),
                 rep(FORC_LUC_NH_SHARE, length(unique(F$year))))
    # the split is the constant, to machine precision, at ANNUAL resolution
    expect_equal(lns_annual(F, F$e_luc_NH),
                 FORC_LUC_NH_SHARE * lns_annual(F, luc), tolerance = 1e-14)
  }
})

# ---------------------------------------------------------------------
test_that("3. the share falls, and the two ends do not overlap under the bracket", {
  skip_if_no_share()
  p <- ccx_luc_nh_share_product()
  s <- p$share
  early <- s$year <= 1849; late <- s$year >= 1990
  w <- function(x, k) sum(x[k] * s$eluc[k]) / sum(s$eluc[k])
  # central: NH-dominated early, minority late
  expect_gt(w(s$share, early), 0.80)
  expect_lt(w(s$share, late),  0.45)
  # and it survives the WHOLE bracket -- the low end of the early period still
  # beats the high end of the late one. This is what makes "no constant works"
  # a measurement rather than a preference.
  expect_gt(w(s$share_lo, early), w(s$share_hi, late))
  expect_true(all(s$share_lo <= s$share & s$share <= s$share_hi))
  expect_true(all(s$share >= 0 & s$share <= 1))
})

test_that("3b. outside the product's coverage the END VALUE is held", {
  skip_if_no_share()
  p <- ccx_luc_nh_share_product()
  s <- p$share
  expect_equal(ccx_luc_nh_share(min(s$year) - 50), s$share[1])
  expect_equal(ccx_luc_nh_share(max(s$year) + 82), s$share[nrow(s)])   # an SSP run
})

# ---------------------------------------------------------------------
test_that("4. a windowed run splits its PRE-WINDOW carbon on the pre-window share", {
  skip_if_no_share()
  F <- lns_forcing(TRUE, c(LNS_WINDOW_START, LNS_YEARS[2]))
  # cum_luc at the first month is the pre-window carbon, already split, PLUS one
  # month of in-window flux -- cumsum() includes its own first element. Removing
  # it is what makes the comparison exact rather than 3e-5 loose; leaving it in
  # is the kind of near-miss a generous tolerance would have hidden.
  pre_NH <- F$cum_luc_NH[1] - F$e_luc_NH[1] / 12
  pre_SH <- F$cum_luc_SH[1] - F$e_luc_SH[1] / 12
  pre    <- pre_NH + pre_SH
  skip_if(pre < 1, "no pre-window land-use carbon in this build")
  got <- pre_NH / pre
  e   <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  k   <- e$year < LNS_WINDOW_START & is.finite(e$luc_GtC)
  want <- sum(ccx_luc_nh_share(e$year[k]) * e$luc_GtC[k]) / sum(e$luc_GtC[k])
  expect_equal(got, want, tolerance = 1e-6)
  # and it is materially NOT the window's own share, nor the retired constant --
  # which is the whole reason this is a separate calculation
  win <- mean(ccx_luc_nh_share(LNS_WINDOW_START:LNS_YEARS[2]))
  expect_gt(abs(got - win), 0.15)
  expect_gt(abs(got - FORC_LUC_NH_SHARE), 0.15)
})

# ---------------------------------------------------------------------
test_that("5. the shipped product reproduces OSCAR's regional sheet", {
  skip_if_no_share()
  skip_if_not_installed("readxl")
  p  <- ccx_luc_nh_share_product()
  xl <- ccx_path("data-raw", "downloads", p$file)
  skip_if_not(file.exists(xl), "OSCAR workbook not downloaded")
  reg <- as.data.frame(readxl::read_excel(xl, sheet = p$sheet))
  reg <- reg[reg$year >= p$years[1] & reg$year <= p$years[2], ]
  expect_true(all(reg$reg_land_long_name %in% names(p$nh_frac)))
  f   <- vapply(reg$reg_land_long_name, function(n) p$nh_frac[[n]][2], numeric(1))
  num <- tapply(reg$E_luc * f, reg$year, sum)
  den <- tapply(reg$E_luc,     reg$year, sum)
  expect_equal(as.numeric(num / den), p$share$share, tolerance = 1e-10)
  # and the headline the source check rests on
  expect_equal(sum(reg$E_luc), 206, tolerance = 3)
})
