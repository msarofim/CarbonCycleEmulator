# test-u-hs-fitted.R -- u_hs (the cold box's flush) is FITTED since 2026-09-08d
# (30 -> 31) under an OBSERVATION prior, and h_ml's flat prior became the
# Holte-2017 mean/max lognormal the same day. Modelled on test-pump-hs.R and
# test-ent-seas-fitted.R.
skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}
uh_par <- function(u = NULL) {
  p <- ccx_default_params(); p$hs_frac <- 0.16; p$u_hs <- 38; p$tau_q <- 538; p$sst_hs <- 2
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

test_that("h_ml's prior is the Holte mean/max lognormal, tied to the product", {
  pr <- readRDS(ccx_path("data", "obs_h_ml_prior.rds")); s <- CCX_PARAM_TABLE$h_ml
  expect_equal(pr$centre_m, sqrt(pr$readings_m[["mean"]] * pr$readings_m[["max"]]))
  expect_equal(pr$log_sd, log(pr$readings_m[["max"]] / pr$readings_m[["mean"]]) / 2)
  for (x in c(40, 59.7, 118)) expect_equal(s$prior(x), dlnorm(x, log(pr$centre_m), pr$log_sd, log = TRUE))
  # the two readings are the 16 % / 84 % points BY CONSTRUCTION
  expect_equal(s$prior(pr$readings_m[["mean"]]) - s$prior(pr$centre_m), s$prior(pr$readings_m[["max"]]) - s$prior(pr$centre_m) + log(pr$readings_m[["max"]] / pr$readings_m[["mean"]]), tolerance = 1e-10)
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
