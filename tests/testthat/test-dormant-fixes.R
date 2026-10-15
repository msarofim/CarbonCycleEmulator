# =====================================================================
# test-dormant-fixes.R -- the six DORMANT bugs the 2026-10-15 pre-public code review reported
# (CHANGELOG 2026-10-15 (d), "NOT fixed, reported"), each fixed with this file's block as its gate.
#
# "Dormant" = on a path the canonical hilda31w and the app do not run, so no shipped number moves;
# test-canonical-contracts.R and test-parity.R hold that. Each block below FAILS on the pre-fix code
# (measured when written), so each has power. CHANGELOG 2026-10-15 (e).
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
  # the C++ core as the saturating form with NO fertilisation, while the R core stopped on fert_k and
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
