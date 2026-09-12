# test-u-hs-fitted.R -- u_hs (the cold box's flush) is FITTED since 2026-09-08d
# (30 -> 31) under an OBSERVATION prior, and h_ml's flat prior became the
# Holte-2017 mean/max lognormal the same day. Modelled on test-pump-hs.R and
# test-ent-seas-fitted.R.
uh_par <- function(u = NULL) {
  p <- ccx_default_params(); p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  if (!is.null(u)) p$u_hs <- u
  p
}

test_that("u_hs is in the table, adjacent to h_hs, with the ruled box and the product-tied init", {
  expect_true("u_hs" %in% CCX_PARAM_NAMES)
  expect_identical(match("u_hs", CCX_PARAM_NAMES), match("h_hs", CCX_PARAM_NAMES) + 1L)
  s <- CCX_PARAM_TABLE$u_hs
  expect_identical(s$tr, "logit"); expect_equal(s$lo, 5); expect_equal(s$hi, 150)
  pr <- readRDS(ccx_path("data", "obs_u_hs_prior.rds"))
  expect_equal(s$init, pr$centre_m_yr, tolerance = 0.05 / pr$centre_m_yr)   # literal vs computed, to 0.05
  for (x in c(10, 21.84, 38)) expect_equal(s$prior(x), dlnorm(x, log(pr$centre_m_yr), pr$log_sd, log = TRUE))
  expect_gt(s$prior(pr$centre_m_yr), s$prior(CCX_U_HS_DECLARED))             # 38 is the old declared value, not the centre
  expect_equal(pr$z_hilda, (log(CCX_U_HS_DECLARED) - log(pr$centre_m_yr)) / pr$log_sd)
  expect_false("u_hs" %in% names(CCX_STRUCT_HILDA))                          # a fitted structure parameter is not declared
  expect_equal(CCX_U_HS_DECLARED, 38)
})

test_that("h_ml's prior is centred on the Holte ANNUAL MEAN, tied to the product", {
  # ⭐⭐ RE-CENTRED 2026-09-09w (ruled by Marcus). Until then the centre was the
  # GEOMETRIC MEAN of the two readings (83.94 m), a deliberate encoding of the
  # mean-vs-max ambiguity that a seasonal mixed layer would resolve. ROUND 6
  # BUILT that mixed layer, so the ambiguity is DISCHARGED and the constant is
  # the annual MEAN. This test asserted the RETIRED encoding and is updated to
  # the ruled one -- the assertions below are the same three in kind (centre,
  # width, and the prior actually wired to the product), re-pointed.
  pr <- readRDS(ccx_path("data", "obs_h_ml_prior.rds")); s <- CCX_PARAM_TABLE$h_ml
  expect_equal(pr$centre_m, pr$readings_m[["mean"]])
  expect_equal(pr$centre_retired_m, sqrt(pr$readings_m[["mean"]] * pr$readings_m[["max"]]))
  # ⚠ THE WIDTH IS UNCHANGED AND THAT IS A FLAGGED CHOICE, NOT A DERIVATION --
  # it still spans an ambiguity that no longer exists, and the 23.8 % exposure
  # Marcus ruled on was computed at THIS width. Asserted so a future re-derivation
  # is a deliberate act rather than a drift.
  expect_equal(pr$log_sd, log(pr$readings_m[["max"]] / pr$readings_m[["mean"]]) / 2)
  for (x in c(40, 59.7, 118)) expect_equal(s$prior(x), dlnorm(x, log(pr$centre_m), pr$log_sd, log = TRUE))
  # ⛔ THE POINT OF THE RE-CENTRING, ASSERTED: exposure past P8's stopping
  # condition. This replaces the 16/84 % symmetry the geometric mean gave, and it
  # is the property the ruling was actually about -- ~3 starts in 5 were dying at
  # the guard. Both numbers COMPUTED by data-raw/build_h_ml_prior.R.
  expect_equal(pr$p8_stop_m, 76.146)
  expect_equal(pr$p8_exposure, 1 - plnorm(pr$p8_stop_m, log(pr$centre_m), pr$log_sd), tolerance = 1e-12)
  expect_lt(pr$p8_exposure, 0.30)                       # was 0.613 at the retired centre
  expect_gt(pr$p8_exposure_retired, 0.55)               # and the retired centre still fails it
  # MUTATION: the exposure check must reject the retired centre, or it has no
  # power over the very change it was written for ([[mutation_test_gates]]).
  expect_gt(1 - plnorm(pr$p8_stop_m, log(pr$centre_retired_m), pr$log_sd), 0.30)
  expect_equal(s$lo, 30); expect_equal(s$hi, 200)                              # the box is unchanged
})

test_that("a 30-parameter ancestor migrates u_hs to the declared 38 -- what it RAN -- and still ENCODES", {
  full <- ccx_unc_to_par(ccx_init_unc())
  anc  <- full; anc$u_hs <- NULL                       # the pre-2026-09-08d shape
  mig  <- ccx_migrate_par_set(anc)
  expect_equal(mig$u_hs, CCX_U_HS_DECLARED)
  expect_true("u_hs" %in% attr(mig, "migrated"))
  for (n in setdiff(CCX_PARAM_NAMES, "u_hs")) expect_equal(mig[[n]], full[[n]], info = n)
  # 38 is interior to [5, 150], so unlike pump_hs_gcm2's 0 it encodes and the seeder is a no-op
  expect_true(all(is.finite(ccx_par_to_unc(mig))))
  expect_equal(ccx_seed_unencodable(mig, "test")$u_hs, CCX_U_HS_DECLARED)
})

test_that("MUTATION: the flush moves the deep 14C and the HS end-member, in both cores", {
  skip_if_no_cpp()
  a <- ccx_spinup(uh_par(38)); b <- ccx_spinup(uh_par(19))
  expect_gt(abs(a$diagnostics$d14c_bottom_box - b$diagnostics$d14c_bottom_box), 0.5)
  expect_gt(abs(a$diagnostics$d14c_hs[["NH"]] - b$diagnostics$d14c_hs[["NH"]]), 0.5)
  # the C++ transient honours the per-draw value: two runs differ, and neither is NA
  Fa <- ccx_build_forcing("historical", c(1750, 1800), prod_c14 = a$prod_c14); Fb <- ccx_build_forcing("historical", c(1750, 1800), prod_c14 = b$prod_c14)
  oa <- ccx_run_fast(a, Fa)$out; ob <- ccx_run_fast(b, Fb)$out
  expect_false(anyNA(oa$co2_NH)); expect_false(anyNA(ob$co2_NH))
  expect_gt(max(abs(oa$d14c_NH - ob$d14c_NH)), 0)
})

test_that("the objective reads u_hs from the vector, not from the structure", {
  skip_if_no_cpp()
  bp <- ccx_apply_structure(ccx_default_params(), "hilda"); bp$pump_mode <- "N"
  lp <- ccx_make_logpost(years = c(1750, 1800), base_params = bp)
  u0 <- ccx_init_unc(); pm <- ccx_unc_to_par(u0)
  pm2 <- pm; pm2$u_hs <- 38                                   # the old declared value
  expect_true(is.finite(lp(u0))); expect_true(is.finite(lp(ccx_par_to_unc(pm2))))
  expect_false(isTRUE(all.equal(lp(u0), lp(ccx_par_to_unc(pm2)))))
})
