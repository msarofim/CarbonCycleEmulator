# =====================================================================
# test-npp-tsens.R -- D2 (b), the NPP temperature sensitivity (Marcus 2026-09-30,
# ruled SIGN-FREE; R/model.R CCX_NPP_TSENS_DEFAULT, src/ccx_core.cpp)
#
#   NPP x exp(npp_tsens * gmst),  gmst = the annual-mean GMST forcing column that
#   q10 also reads (MAGICC6's F = F0 exp(sigma dT), Meinshausen 2011 Eq. A21).
#
#   OFF      npp_tsens 0 is bit-exact on a real warming record.
#   PARITY   both cores agree at explicit values of BOTH signs, and a parameter list
#            WITHOUT the field means the default in both (the gamma_diff lesson).
#   TRAJ     an 80-yr trajectory agrees between the cores with it ON.
#   CONSERVE carbon is conserved with it ON.
#   SIGN     a positive value raises NPP-fed uptake on warming, a negative one lowers
#            it (the direction the literature's evidence decides between).
# Mutation-tested 2026-09-30 (CHANGELOG 09-30 l).
# =====================================================================

TSENS_TEST_VALUES <- c(-0.06, 0, 0.029, 0.06)     # MAGICC6 Table B4's range, and its SD

test_that("OFF: npp_tsens 0 is bit-exact on a real warming record", {
  # ⚠ WEAK ON ITS OWN: default vs explicit 0 cannot differ unless absence were
  # mis-resolved. The LOAD-BEARING bit-identity evidence is the suite's
  # registered-file tests ("stored streams reproduce"), which run the canonical
  # modes through this code with the field at its default.
  skip_if_no_cpp()
  sp <- ccx_spinup(ccx_default_params())
  F  <- suppressWarnings(ccx_build_forcing("historical", c(1900, 2020), prod_c14 = sp$prod_c14))
  expect_gt(max(F$gmst), 1)                                   # the gate has warming to bite on
  p0 <- ccx_default_params(); p0$npp_tsens <- 0
  a <- suppressWarnings(ccx_run_fast(sp, F))
  sp0 <- sp; sp0$params$npp_tsens <- 0
  b <- suppressWarnings(ccx_run_fast(sp0, F))
  expect_identical(a$out, b$out)
})

test_that("PARITY: both cores agree at explicit values of both signs, and at absence", {
  skip_if_no_cpp()
  p  <- ccx_default_params(); sp <- ccx_spinup(p)
  F  <- suppressWarnings(ccx_build_forcing("historical", c(1900, 2020), prod_c14 = sp$prod_c14))
  i  <- nrow(F) - 6L; f <- ccx_forcing_at(F, i); t <- F$t[i]
  expect_gt(f$gmst, 1)
  for (v in TSENS_TEST_VALUES) {
    p$npp_tsens <- v
    expect_equal(ccx_deriv(sp$y, t, p, f, sp$grid, sp$aux),
                 ccx_deriv_fast(sp$y, t, p, f, sp$grid, sp$aux), tolerance = 1e-12, info = v)
  }
  # POWER: the core really sees it
  p$npp_tsens <- 0.06; p0 <- p; p0$npp_tsens <- 0
  expect_gt(max(abs(ccx_deriv_fast(sp$y, t, p, f, sp$grid, sp$aux) -
                    ccx_deriv_fast(sp$y, t, p0, f, sp$grid, sp$aux))), 0.5)
  # ABSENCE = the default, in both cores
  pa <- p; pa$npp_tsens <- NULL
  pe <- p; pe$npp_tsens <- CCX_NPP_TSENS_DEFAULT
  expect_equal(ccx_deriv(sp$y, t, pa, f, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, t, pa, f, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv_fast(sp$y, t, pa, f, sp$grid, sp$aux),
               ccx_deriv_fast(sp$y, t, pe, f, sp$grid, sp$aux), tolerance = 1e-12)
  expect_equal(ccx_deriv(sp$y, t, pa, f, sp$grid, sp$aux),
               ccx_deriv(sp$y, t, pe, f, sp$grid, sp$aux), tolerance = 1e-12)
})

test_that("TRAJ: an 80-yr trajectory agrees between the cores with it ON", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$npp_tsens <- 0.029
  sp <- ccx_spinup(p)
  F  <- suppressWarnings(ccx_build_forcing("historical", c(1940, 2020), prod_c14 = sp$prod_c14))
  rR <- suppressWarnings(ccx_run(sp, F)); rC <- suppressWarnings(ccx_run_fast(sp, F))
  for (cc in c("co2_NH", "co2_SH", "land_C", "ocean_C", "land_C14"))
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13, label = cc)
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
  rOff <- suppressWarnings(ccx_run_fast(ccx_spinup(ccx_default_params()), F))
  expect_gt(max(abs(rOff$out$land_C - rC$out$land_C)) / max(abs(rC$out$land_C)), 1e-4)
})

test_that("CONSERVE: closed-system carbon is conserved with it ON", {
  p <- ccx_set_enso(ccx_default_params(), list(gamma_enso = 0)); p$npp_tsens <- 0.06
  sp <- ccx_spinup(p)
  closed <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
                 gmst = 3, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
  y <- sp$y
  d <- ccx_deriv(y, 1900, p, closed, sp$grid, sp$aux)
  expect_gt(max(abs(d[, "C"])), 1)
  expect_lt(abs(sum(d[, "C"])) / max(abs(d[, "C"])), 1e-12)
  tot0 <- ccx_total(y); t <- 1900
  for (m in seq_len(12 * 30)) { y <- ccx_step_rk4(y, t, 1 / 12, p, closed, sp$grid, sp$aux); t <- t + 1 / 12 }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
})

test_that("SIGN: positive raises the land's uptake over a warming record, negative lowers it", {
  skip_if_no_cpp()
  F <- NULL; land_end <- c()
  for (v in c(-0.03, 0, 0.03)) {
    p <- ccx_default_params(); p$npp_tsens <- v; sp <- ccx_spinup(p)
    if (is.null(F)) F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2020), prod_c14 = sp$prod_c14))
    r <- suppressWarnings(ccx_run_fast(sp, F))
    land_end[as.character(v)] <- tail(r$out$land_C, 1) - r$out$land_C[1]
  }
  expect_lt(land_end[["-0.03"]], land_end[["0"]]); expect_gt(land_end[["0.03"]], land_end[["0"]])
})
