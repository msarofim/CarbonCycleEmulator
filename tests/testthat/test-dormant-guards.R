# =====================================================================
# test-dormant-guards.R -- the pre-beta code review's sec.5 DORMANT bugs, each turned from a
# silent wrong answer into an error or a warning (2026-10-12; Marcus: "§5 dormant-bug guards").
#
# "Dormant" = on a path the canonical and the app do not run, so no shipped number moves; that is
# also why no other test could see them. Each block below FAILS on the pre-fix code (measured when
# written), so each has power. The guards that live beside their own subjects are tested there:
#   k-hat with one surviving draw            -> test-importance.R
#   a NULL / non-finite sigma_d14c           -> test-likelihood.R
#   the comparable rows' low-pass switch     -> test-mode-file.R
#   ccx_run_coupled() not converging          -> test-climate.R
# Review record: notes/code_review_2026-10-12.md sec.5. CHANGELOG 2026-10-12 (z).
# =====================================================================

test_that("kz's prior reads the table's OWN box, so an adopted band moves it", {
  # It was the literal dunif(x, 1161.6, 27808.0): ccx_adopt_mode_band() moves lo/hi and could not
  # move a literal, so a mode fitted under a wider bracket decoded kz outside the literal box and
  # scored -Inf. Every registered mode records exactly the literal box, so the VALUE is unchanged.
  env <- environment(ccx_make_logpost)
  tab <- get("CCX_PARAM_TABLE", envir = env)
  on.exit(assign("CCX_PARAM_TABLE", tab, envir = env), add = TRUE)
  expect_identical(tab$kz$prior(5000), dunif(5000, 1161.6, 27808.0, log = TRUE))   # unchanged at the shipped box
  wide <- tab; wide$kz$lo <- 1000; wide$kz$hi <- 40000
  assign("CCX_PARAM_TABLE", wide, envir = env)
  expect_equal(tab$kz$prior(30000), -log(39000))          # outside the old literal box: finite now
  expect_true(is.finite(tab$kz$prior(30000)))
})

test_that("the C++ core REFUSES a state with the wrong row count", {
  # y0 is copied by POSITION into an NB x 3 state; two extra rows ran silently with every tracer
  # column shifted (d13c_NH -734 permil), and one too few read out of bounds.
  skip_if_no_cpp()
  sp <- ccx_spinup(ccx_default_params())
  F  <- ccx_build_forcing("historical", c(1750, 1751), prod_c14 = sp$prod_c14)
  expect_silent(r <- ccx_run_fast(sp, F))                  # the right shape runs
  nb <- nrow(sp$y)
  big <- sp; big$y <- rbind(sp$y, sp$y[1:2, , drop = FALSE])
  expect_error(ccx_run_fast(big, F), sprintf("state is %d x 3; the prepared structure needs %d x 3", nb + 2L, nb))
  sml <- sp; sml$y <- sp$y[-1, , drop = FALSE]
  expect_error(ccx_run_fast(sml, F), sprintf("state is %d x 3; the prepared structure needs %d x 3", nb - 1L, nb))
  # the single-derivative entry point carries the same guard
  fp <- ccx_forcing_at(F, 1L)
  expect_error(ccx_deriv_fast(big$y, 1750, sp$params, fp, sp$grid, sp$aux), "ccx_deriv_cpp\\(\\): state is")
})

test_that("the SST seam REFUSES a forcing outside its window, and is bit-identical inside it", {
  # Before: a start after the seam window took mean(empty) = NaN, so the SST was NaN and the core
  # silently used sst_scale x gmst instead.
  so <- as.data.frame(readRDS(ccx_path("data", "forcing_sst.rds"))); last <- max(so$year)
  expect_error(suppressWarnings(ccx_build_forcing("vvM", c(last + 1L, last + 5L), prod_c14 = 360)),
               "seam window")
  # FULL coverage: the covered years are the whole window, so the fixed arithmetic must equal the
  # pre-fix formula BIT FOR BIT (the window computed here exactly as the old line did).
  F <- suppressWarnings(ccx_build_forcing("vvM", c(1750, last + 15L), prod_c14 = 360))
  beyond <- F$year > last
  for (h in c("NH", "SH")) {
    ratio <- if (h == "NH") CCX_SST_RATIO_NH else CCX_SST_RATIO_SH
    ocol <- so[[paste0("sst_anom_", h)]]
    old <- mean(ocol[so$year > last - CCX_SST_SPLICE_YR]) +
      ratio * (F$gmst[beyond] - mean(F$gmst[F$year > last - CCX_SST_SPLICE_YR & F$year <= last]))
    expect_identical(F[[paste0("sst_anom_", h)]][beyond], old, info = h)
    expect_false(anyNA(F[[paste0("sst_anom_", h)]]), info = h)
  }
})

test_that("emissions held flat past their data end are WARNED about, and only then", {
  e_end <- max(readRDS(ccx_path("data", "forcing_emissions_historical.rds"))$year)
  w_of <- function(expr) { w <- character(0)
    withCallingHandlers(expr, warning = function(c) { w <<- c(w, conditionMessage(c)); invokeRestart("muffleWarning") })
    w }
  w_in  <- w_of(ccx_build_forcing("historical", c(1750, e_end), prod_c14 = 360))
  w_out <- w_of(ccx_build_forcing("historical", c(1750, e_end + 2L), prod_c14 = 360))
  expect_false(any(grepl("held FLAT at the", w_in)))
  expect_true(any(grepl(sprintf("fossil_GtC .* ends %d; years %d-%d are held FLAT", e_end, e_end + 1L, e_end + 2L), w_out)))
  expect_true(any(grepl("luc_GtC .* held FLAT", w_out)))
})

test_that("ccx_temperature_from_erf() FLAGS a start after its baseline, as its docs say", {
  skip_if_no_climate()
  mod <- ccx_climate_module(); b <- mod$baseline
  expect_warning(ccx_temperature_from_erf(rep(1, 10), seq(b[2] + 1L, b[2] + 10L)), "SINGLE year")
  expect_silent(ccx_temperature_from_erf(rep(1, 80), seq(b[1] - 10L, b[1] + 69L)))
})

test_that("the retired conveyor sinking into layer 1 is REFUSED under the seasonal mixed layer", {
  # Its interhemispheric deep limb divides by the STATIC grid$dz[s + 1], and under the seasonal ML
  # layer 1 (dz[2]) moves with h_ml(t). Deeper sink layers are static and stay allowed.
  p <- ccx_default_params()
  p$seas_ml <- 1; p$seas_drivers <- 1
  skip_if_not(ccx_seas_ml_ls_on(p), "the defaults cannot switch the seasonal mixed layer on here")
  p$q_conv <- 5; p$conv_sink <- 1L
  expect_error(ccx_prepare(p), "conv_sink = 1 cannot be combined with the seasonal mixed")
  p$conv_sink <- 2L
  expect_type(ccx_prepare(p), "list")                      # one layer deeper prepares
})

test_that("ccx_fert_factor() reads `fert_k` EXACTLY: absent is an error, not the prior switch", {
  # `fert_k` prefixes `fert_k_prior`, so `p$fert_k` with `fert_k` absent partial-matched the switch
  # and ran K = 1 silently (code review 2026-10-12 sec.4, demonstrated there).
  p <- ccx_default_params()
  p[["fert_form"]] <- CCX_FERT_FORM_DEFAULT
  skip_if(identical(as.integer(p$fert_form), as.integer(CCX_FERT_LOG)), "the default form is LOG")
  v <- ccx_fert_factor(400, p)
  expect_equal(v, max(1 + p$beta_max * (400 - ccx_const("CO2_PI_PPM")) /
                        max(p$fert_k + 400 - ccx_const("CO2_PI_PPM"), 1e-6), 0))   # unchanged when present
  q <- p; q$fert_k <- NULL; q$fert_k_prior <- 1
  expect_error(ccx_fert_factor(400, q), "needs `fert_k`")
})

test_that("the NA-retry guard sees a NaN made in the FINAL month", {
  # `out` holds month-OPENING states, so a NaN created during the last month reached only the
  # final state: no retry, `retried` FALSE, and a NaN state handed back as a normal run.
  skip_if_no_cpp()
  sp <- ccx_spinup(ccx_default_params())
  F  <- ccx_build_forcing("historical", c(1750, 1751), prod_c14 = sp$prod_c14)
  F$e_foss_NH[nrow(F)] <- NaN                              # poisons only the last month's step
  r <- ccx_run_fast(sp, F)
  expect_false(anyNA(r$out[, c("co2_NH", "co2_SH")]))     # precondition: the openings are clean
  expect_true(anyNA(r$state))
  expect_true(r$retried)                                   # the guard saw it (it was FALSE)
})
