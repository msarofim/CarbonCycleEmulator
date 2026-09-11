# =====================================================================
# test-seasonal-box-observable.R -- a concentration observable reads a box
# over its mass AT THE TIME, as an ANNUAL MEAN (2026-09-11 (4)/(5); ruled
# "annual mean of the concentration", [[seasonal_box_observable_artefact]]).
#
# THE DEFECT THIS GUARDS. ccx_model_ocean_gradient() and ccx_model_hs_surface()
# divided the INSTANT box carbon at the observation's epoch by the ANNUAL-MEAN
# box mass -- exact for a time-constant box, 157 umol/kg LOW for the seasonal
# mixed layer at the GLODAP epoch (early November, f 0.885 / 0.919). Round 6
# was fitted against that row and its P7 "302 -> 385" was the artefact.
#
# MUTATION-TESTED BY CONSTRUCTION: the synthetic box below has a CONSTANT
# concentration and a SEASONAL mass, so any read that uses the mean mass, or
# a single instant, returns something other than the constant. Test 2 shows
# the old read failing on the same data.
# =====================================================================
.sbo_synth <- function(seasonal) {
  rho <- ccx_const("RHO_SEAWATER"); mol <- 1e15 / 12.011
  grid <- list(dz = c(50, 100, 200))
  a_oc <- list(NH = 1.5e14, SH = 2.1e14)
  aux <- list(a_oc = a_oc, a_ls = lapply(a_oc, function(A) A * (1 - 0.16)),
              mol_per_GtC = mol, grid = grid)
  # a strongly seasonal shape (mean exactly 1) -- the Holte LS shape's own builder
  h_m <- list(NH = c(77, 83, 74, 51, 35, 30, 30, 30, 32, 38, 49, 63),
              SH = c(36, 38, 43, 53, 67, 84, 102, 114, 108, 79, 51, 39))
  if (seasonal) aux$mld_coef <- lapply(h_m, ccx_mld_fourier)
  aux$hs_mass_kg <- list(NH = 1e17, SH = 2e17)
  if (seasonal) aux$mld_hs_coef <- lapply(h_m, ccx_mld_fourier)
  c_ml <- 2000; c_deep <- 2233; c_hs <- 2160
  # DAILY cadence: the read interpolates the (curved) carbon series linearly at
  # its own sample times, so a monthly synthetic grid leaves a 0.02 % chord
  # error that would masquerade as a defect; the model's own monthly output
  # carries the same chord error, and that is what the loose tolerance in
  # ccx_epoch_year_samples' consumers is for.
  t <- seq(1995, 2005, by = 1 / 365)
  out <- data.frame(t = t)
  # The seasonal box's CONCENTRATION also cycles, in phase with its mass (a real
  # mixed layer is DIC-richer when deep). Its annual mean is exactly c_* because
  # f has mean 1 -- but the annual mean of carbon over the MEAN mass is
  # c_* (1 + 0.05 var(f)), so a read that ignores the mass at the time is caught
  # even when averaged over the year. Without this the mutation slips through:
  # annual-mean-over-mean-mass is exact for a CONSTANT concentration.
  for (h in HEMIS) {
    f <- if (seasonal) vapply(t, function(tt) ccx_mld_eval(aux$mld_coef[[h]], tt)$f, 0) else 1
    cyc <- 1 + 0.05 * (f - 1)
    out[[paste0("ml_C_", h)]]   <- c_ml * cyc * 1e-6 * aux$a_ls[[h]] * grid$dz[1] * f * rho / mol
    out[[paste0("deep_C_", h)]] <- c_deep * 1e-6 * aux$a_ls[[h]] * grid$dz[3] * rho / mol
    out[[paste0("hs_C_", h)]]   <- c_hs * cyc * 1e-6 * aux$hs_mass_kg[[h]] * f / mol
    for (b in c("ml", "deep", "hs")) out[[paste0(b, "_C13_", h)]] <- out[[paste0(b, "_C_", h)]] * ccx_const("R13_VPDB")
  }
  list(out = out, aux = aux, grid = grid, c_ml = c_ml, c_deep = c_deep, c_hs = c_hs)
}

test_that("a SEASONAL box with a constant concentration reads back that constant, exactly, in both observables", {
  z <- .sbo_synth(TRUE)
  g <- ccx_model_ocean_gradient(z$out, z$aux, z$grid, list(surf = 1999.836, deep = 2002.369))
  # 0.01 umol/kg ABSOLUTE: the daily chord error is ~0.003; the retired read is off by ~200
  expect_equal(g$dic, z$c_deep - z$c_ml, tolerance = 0.01, scale = 1)
  expect_equal(g$d13c, 0, tolerance = 1e-9)
  hs <- ccx_model_hs_surface(z$out, z$aux, 2002.5, 2002.5)
  expect_equal(hs$dic, z$c_hs, tolerance = 0.01, scale = 1)
  expect_equal(hs$d13c, 0, tolerance = 1e-9)
  # and the shape really is seasonal on this data: the NH ML mass swings 0.6-1.7x
  f <- vapply(1:12, function(m) ccx_mld_eval(z$aux$mld_coef$NH, 2000 + (m - 0.5) / 12)$f, 0)
  expect_gt(max(f), 1.5); expect_lt(min(f), 0.7)
})

test_that("the RETIRED read (instant carbon / annual-mean mass) fails on the same data by ~10 % -- the record's artefact", {
  z <- .sbo_synth(TRUE); rho <- ccx_const("RHO_SEAWATER")
  at <- function(col, tt) stats::approx(z$out$t, z$out[[col]], xout = tt, rule = 2)$y
  old_surf <- sum(vapply(HEMIS, function(h) at(paste0("ml_C_", h), 1999.836), 0)) * z$aux$mol_per_GtC /
    sum(vapply(HEMIS, function(h) ccx_column_area(z$aux, h) * z$grid$dz[1] * rho, 0)) * 1e6
  expect_gt(abs(old_surf - z$c_ml), 0.05 * z$c_ml)       # ~0.9 x c_ml at that epoch
  expect_lt(old_surf, z$c_ml)                             # reads LOW in November, as the record did
})

test_that("a time-constant box is read IDENTICALLY by the annual mean and the instant (the seas_ml = 0 case)", {
  z <- .sbo_synth(FALSE)
  g <- ccx_model_ocean_gradient(z$out, z$aux, z$grid, list(surf = 1999.836, deep = 2002.369))
  expect_equal(g$dic, z$c_deep - z$c_ml, tolerance = 1e-9)
  expect_equal(ccx_model_hs_surface(z$out, z$aux, 2002.5, 2002.5)$dic, z$c_hs, tolerance = 1e-9)
  # mass helper: f = 1 without coefficients, and the deep box never varies
  expect_equal(ccx_box_mass_at(z$aux, z$grid, "ml", "NH", 1999.9),
               ccx_column_area(z$aux, "NH") * z$grid$dz[1] * ccx_const("RHO_SEAWATER"))
  expect_error(ccx_box_mass_at(z$aux, z$grid, "abyss", "NH", 2000), "unknown box")
})

test_that("the epoch-year samples are 12 month-centres, centred on the epoch, mean = epoch", {
  s <- ccx_epoch_year_samples(2000.3)
  expect_length(s, LIK_ANNUAL_MEAN_N)
  expect_equal(mean(s), 2000.3)
  expect_equal(diff(s), rep(1 / 12, 11))
})
