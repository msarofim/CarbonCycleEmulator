# =====================================================================
# test-dormant-fixes.R -- the six DORMANT bugs the 2026-10-15 pre-public code review reported
# (CHANGELOG 2026-10-15 (d), "NOT fixed, reported"), each fixed with this file's block as its gate.
#
# "Dormant" = on a path the canonical hilda31w and the app do not run, so no shipped number moves;
# test-canonical-contracts.R and test-parity.R hold that. Each block below FAILS on the pre-fix code
# (measured when written), so each has power. CHANGELOG 2026-10-15 (j).
# =====================================================================

test_that("a PINNED name with no model slot (bomb_total, luc_scale, the four likelihood names) is scored at its pinned value", {
  # ccx_make_logpost() read these six from `pv`, the FITTED names only, so a pinned one was NULL:
  # rep_dC scored as 0 (co2_level_MLO -70.84 -> -662.42 at hilda31w), a pinned grad_off_* dropped
  # its gradient row with nothing said, and a pinned bomb_total stopped in the forcing rebuild.
  skip_if_no_cpp()
  # the six ARE the fitted names the model list has no slot for; a seventh would need the same read
  expect_identical(CCX_NUISANCE_NAMES, setdiff(CCX_PARAM_NAMES, names(ccx_default_params())))
  md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
  expect_false(any(CCX_NUISANCE_NAMES %in% names(md$pins)))   # the canonical pins none of them
  score <- function(extra, in_base = TRUE) {
    pins <- c(md$pins, unlist(md$par_mode[extra]))
    attr(pins, "gate_struct") <- attr(ccx_mode_pins(md), "gate_struct")
    rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
    bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
    if (in_base) for (n in extra) bp[[n]] <- md$par_mode[[n]]
    invisible(utils::capture.output(u <- ccx_mode_start(md, "dormant-fixes")$u))   # its SEEDING notes
    v <- ccx_make_logpost(base_params = bp, by_stream = TRUE,
                          spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(u)
    attr(v, "streams")
  }
  st0 <- unlist(md$streams)
  # all six pinned AT the canonical's fitted values: every stored stream row reproduces, and none is lost
  st <- score(CCX_NUISANCE_NAMES)
  expect_true(all(names(st0) %in% names(st)))
  expect_lt(max(abs(st[names(st0)] - st0)), 1e-6)
  expect_true(all(c("co2_gradient", "d13c_gradient") %in% names(st)))
  # rep_dC alone, the case the review measured: the level row is the fitted one, not the rep_dC = 0 one
  st_r <- score("rep_dC")
  expect_equal(st_r[["co2_level_MLO"]], st0[["co2_level_MLO"]], tolerance = 1e-6, scale = 1)
  expect_gt(st_r[["co2_level_MLO"]], -100)
  # a pin whose value the base list does not carry is refused BY NAME, not scored as NULL
  expect_error(score("rep_dC", in_base = FALSE), "rep_dC")
  expect_true(all(CCX_NUISANCE_NAMES %in% CCX_PARAM_NAMES))   # the fitted set is restored
})

test_that("a list without the saturating form's names STOPS in both cores, not only in R", {
  # ccx_cpp_par() filled fert_form = MM, beta_max = 0 and fert_k = 1, so a list lacking them reached
  # the C++ core as the saturating form with NO fertilization, while the R core stopped on fert_k and
  # returned numeric(0) on beta_max.
  p <- ccx_default_params()
  expect_identical(p$fert_form, CCX_FERT_MM)                    # the default form IS the saturating one
  expect_identical(CCX_FERT_FORM_DEFAULT, CCX_FERT_MM)
  drop <- function(p, nm) { for (n in nm) p[[n]] <- NULL; p }
  for (nm in list(c("fert_form", "beta_max", "fert_k"), c("fert_form", "beta_max"), "beta_max", "fert_k")) {
    q <- drop(p, nm)
    miss <- intersect(c("beta_max", "fert_k"), nm)
    expect_error(ccx_fert_factor(400, q), miss[length(miss)])
    expect_error(ccx_cpp_par(q), miss[1])
  }
  # ...and `fert_k_prior` does not stand in for an absent `fert_k` (`$` would partial-match it)
  q <- drop(p, "fert_k"); q$fert_k_prior <- 1
  expect_error(ccx_cpp_par(q), "needs `fert_k`")
  # an absent FORM alone is the default form with the list's own pair, in both cores
  q <- drop(p, "fert_form")
  expect_identical(ccx_fert_factor(400, q), ccx_fert_factor(400, p))
  x <- ccx_cpp_par(q)
  expect_identical(x[["fert_form"]], CCX_FERT_MM)
  expect_identical(c(x[["beta_max"]], x[["fert_k"]]), c(p$beta_max, p$fert_k))
  # the LOG form needs neither name: both cores run it, the C++ with the inert fillers its unpack reads
  q <- drop(p, c("beta_max", "fert_k")); q$fert_form <- CCX_FERT_LOG
  expect_equal(ccx_fert_factor(400, q), 1 + q$beta * log(400 / ccx_const("CO2_PI_PPM")))
  x <- ccx_cpp_par(q)
  expect_identical(x[["fert_form"]], CCX_FERT_LOG)
  expect_true(is.finite(x[["beta_max"]]) && is.finite(x[["fert_k"]]))
})

test_that("the D3 ocean share is read EXACTLY: the stick-breaking coordinate does not stand in for it", {
  # ccx_loglik() read `err$imb_share_ocean`, and `$` partial-matches: an `err` carrying the
  # PARAMETER pair (imb_share_land, imb_share_ocean_rest) scored the rest coordinate as the ocean
  # SHARE, where the pair check exists to refuse a half-built allocation.
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  sp  <- ccx_spinup(ccx_default_params())
  F   <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  eluc <- ccx_forcing_eluc_annual(F)
  err <- list(sigma_d14c = 5)
  par_pair <- list(imb_share_land = 0.4, imb_share_ocean_rest = 0.5)
  expect_error(ccx_loglik(out, obs, c(err, par_pair), luc = eluc), "PAIR")
  # the share itself, beside the coordinate, is the one scored: the same rows as the share alone
  sh <- ccx_imb_shares(par_pair)
  alone <- ccx_loglik(out, obs, c(err, imb_share_land = sh[["land"]], imb_share_ocean = sh[["ocean"]]),
                      luc = eluc, by_stream = TRUE)
  both  <- ccx_loglik(out, obs, c(err, imb_share_land = sh[["land"]], imb_share_ocean = sh[["ocean"]],
                                  imb_share_ocean_rest = 0.5), luc = eluc, by_stream = TRUE)
  expect_identical(both, alone)
})

test_that("ccx_unc_to_par() decodes an UNNAMED vector as the live fitted set, and refuses a wrong length", {
  # With names(u) NULL it took the build's names and then indexed `u` by them, which an unnamed
  # vector cannot answer: "subscript out of bounds".
  u <- ccx_init_unc()
  expect_identical(ccx_unc_to_par(unname(u)), ccx_unc_to_par(u))
  expect_error(ccx_unc_to_par(unname(u)[-1]), "UNNAMED")
  expect_error(ccx_unc_to_par(c(unname(u), 0)), "UNNAMED")
})

test_that("the IntCal row scores only the years inside the run, as the ice-core rows do", {
  # The window started at a typed 1750, and `interp()` reads approx(rule = 2): a run starting in
  # 1850 scored IntCal's 1750-1849 rows against its own first row (191 rows where 91 are in the run;
  # -644.57 against -305.22 at the default parameters, measured). A 1750 start is unchanged.
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  sp  <- ccx_spinup(ccx_default_params())
  ic_end <- min(obs$d14_nh_ann$year)
  hand <- function(out, from) {
    ic  <- obs$intcal[obs$intcal$year >= from & obs$intcal$year < ic_end, ]
    mod <- stats::approx(out$t, out$d14c_NH, xout = ic$year + 0.5, rule = 2)$y
    sum(stats::dnorm(ic$d14c, mod, sqrt(ic$err^2 + LIK_D14C_REP_OTHER^2), log = TRUE))
  }
  row <- function(y0) {
    F <- suppressWarnings(ccx_build_forcing("historical", c(y0, 2024), prod_c14 = sp$prod_c14))
    out <- ccx_run_fast(sp, F)$out
    st <- suppressWarnings(ccx_loglik(out, obs, list(sigma_d14c = 5), luc = ccx_forcing_eluc_annual(F),
                                      by_stream = TRUE))
    list(out = out, ll = st[["d14c_intcal"]])
  }
  expect_lt(min(obs$intcal$year), 1750)                  # the record reaches before the canonical's start
  r0 <- row(1750)
  expect_identical(r0$ll, hand(r0$out, 1750))           # the canonical's start: the same rows, bit for bit
  r1 <- row(1850)
  expect_identical(r1$ll, hand(r1$out, 1850))           # a later start: its own years only
  expect_gt(abs(hand(r1$out, 1750) - r1$ll), 100)       # POWER: the pre-fix window is far off
})

test_that("the ENSO e-folding time interpolates from lag 0 when the ACF is below 1/e at lag 1", {
  # The k == 1 branch was k (r1 - 1/e) / (r1 - 1/e), which is 1 month whatever r1 is. The bracket
  # there is lag 0 (ACF 1) to lag 1, so the crossing is (1 - 1/e) / (1 - r1) months.
  x <- sin(1.3 * seq_len(2000))                 # deterministic; lag-1 ACF ~ cos(1.3) = 0.27 < 1/e
  r <- stats::acf(x, lag.max = 60, plot = FALSE)$acf[-1]
  expect_lt(r[1], exp(-1))                       # the k == 1 case
  expect_equal(ccx_enso_efold_yr(x) * 12, (1 - exp(-1)) / (1 - r[1]), tolerance = 1e-12)
  expect_gt(abs(ccx_enso_efold_yr(x) * 12 - 1), 0.1)   # POWER: not the old constant 1 month
  # the shipped record takes the k > 1 branch, so the forcing's taper is unchanged
  en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en <- en[!is.na(en$nino34_anom), ]
  r <- stats::acf(en$nino34_anom, lag.max = 60, plot = FALSE)$acf[-1]
  k <- which(r < exp(-1))[1]
  expect_gt(k, 1L)
  expect_identical(ccx_enso_efold_yr(en$nino34_anom), ((k - 1) + (r[k - 1] - exp(-1)) / (r[k - 1] - r[k])) / 12)
})
