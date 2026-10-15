# =====================================================================
# Gate: the fast in-repo carbonate solver must reproduce seacarb's full
# system for BOTH pCO2 and the Revelle factor across the range of DIC and
# temperature the model actually visits. seacarb is the cited authority;
# if this test fails, the fast solver is wrong, not seacarb.
# =====================================================================

test_that("carbonate constants load and cover the model range", {
  cc <- carb_coefs()
  expect_true(all(c("K0", "K1", "K2", "Kb") %in% names(cc$coefs)))
  expect_gt(cc$boron_total, 3e-4)
  expect_lt(cc$boron_total, 5e-4)
  expect_equal(cc$salinity, 34.7)
})

test_that("pCO2 matches seacarb across the DIC x T operating range", {
  skip_if_not_installed("seacarb")
  suppressMessages(library(seacarb))

  grid <- expand.grid(
    dic = seq(1900, 2400, by = 50) * 1e-6,   # mol/kg; PI ~2000 to high-emission futures
    T   = seq(10, 30, by = 5)                 # degC; brackets hemispheric-mean SST
  )
  alk <- 2300e-6

  ours <- pco2_from_dic(grid$dic, alk, grid$T)
  ref  <- carb(flag = 15, var1 = alk, var2 = grid$dic, S = 34.7, T = grid$T, P = 0,
               k1k2 = "l", kf = "pf", pHscale = "T", b = "u74")$pCO2

  rel <- abs(ours / ref - 1)
  # Actual error is ~2e-5; this gates at 1e-4 so a real regression trips it.
  expect_lt(max(rel), 1e-4)
})

test_that("Revelle factor matches seacarb and rises with DIC", {
  skip_if_not_installed("seacarb")
  suppressMessages(library(seacarb))

  # DIC range stops at 2250 umol/kg, below the alkalinity of 2300. The Revelle
  # factor is NOT monotonic all the way up: once DIC approaches ALK the carbonate
  # ion is nearly exhausted (pH ~7.1) and the buffer factor turns over. seacarb
  # does exactly the same thing, so that turnover is physics, not a solver bug --
  # but DIC > ALK is not a state surface seawater occupies, so the monotonicity
  # assertion below is restricted to the range the model actually visits.
  dic_vals <- seq(1950, 2250, by = 75) * 1e-6
  alk <- 2300e-6
  T   <- 18

  ours <- revelle_factor(dic_vals, alk, T)

  # seacarb reference: centered difference on its own full solver
  step <- dic_vals * 1e-4
  p1 <- carb(flag = 15, var1 = alk, var2 = dic_vals - step, S = 34.7, T = T, P = 0,
             k1k2 = "l", kf = "pf", pHscale = "T", b = "u74")$pCO2
  p2 <- carb(flag = 15, var1 = alk, var2 = dic_vals + step, S = 34.7, T = T, P = 0,
             k1k2 = "l", kf = "pf", pHscale = "T", b = "u74")$pCO2
  ref <- ((p2 - p1) / (p2 + p1)) / ((2 * step) / (2 * dic_vals))

  expect_lt(max(abs(ours / ref - 1)), 1e-4)   # actual ~1.3e-6

  # The physics the app is built to show: buffering weakens as DIC rises.
  expect_true(all(diff(ours) > 0))
})

test_that("Newton refinement has converged (more iterations change nothing)", {
  dic <- seq(1900, 2400, by = 100) * 1e-6
  a <- pco2_from_dic(dic, 2300e-6, 18, iter = 6L)
  b <- pco2_from_dic(dic, 2300e-6, 18, iter = 12L)
  expect_lt(max(abs(a / b - 1)), 1e-10)
})

test_that("Kw fit error is immaterial to pCO2", {
  # The Kw polynomial is allowed a 5e-3 tolerance (vs 1e-6 for the others)
  # because seacarb's own Kw carries ~1.7e-3 numerical wiggle. That waiver is
  # only legitimate if the error cannot reach the answer -- so measure it.
  k     <- carb_constants(18)
  k_hi  <- k; k_hi$Kw <- k$Kw * 1.005     # a full tolerance-width perturbation
  p_ref <- pco2_from_dic(2000e-6, 2300e-6, 18, k = k)
  p_hi  <- pco2_from_dic(2000e-6, 2300e-6, 18, k = k_hi)
  expect_lt(abs(p_hi / p_ref - 1), 1e-4)
})

test_that("borate matters enough to justify including it", {
  # Documents WHY the Newton refinement exists: the carbonate-only quadratic
  # seed alone is not accurate enough, so this is not gold-plating.
  dic <- 2000e-6; alk <- 2300e-6; T <- 18
  seed_only <- pco2_from_dic(dic, alk, T, iter = 0L)
  refined   <- pco2_from_dic(dic, alk, T, iter = 6L)
  expect_gt(abs(seed_only / refined - 1), 0.02)
})
