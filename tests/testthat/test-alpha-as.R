# =====================================================================
# The air-sea 13C fractionation pair became TEMPERATURE-DEPENDENT on
# 2026-09-02 (Zhang, Quay & Wilbur 1995). These are the contracts that
# adoption has to keep.
#
# WHAT THIS GUARDS. Before the change the two alphas were LITERALS inside
# ccx_prepare()'s aux, read from nowhere else -- so setting them on a parameter
# list was a SILENT NO-OP that returned an unchanged number with no error. That
# is what these tests exist to stop coming back: every one of them would pass
# trivially if the switch stopped being read, so each asserts a DIFFERENCE
# between the two settings as well as the values themselves.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

AA_T <- c(5, 16, 18, 21)          # inside Zhang's stated 5-25 degC
aa_aux <- function(td) ccx_prepare(within(ccx_default_params(), alpha_as_tdep <- td))

test_that("the legacy path reproduces the retired scalars EXACTLY", {
  # An IDENTITY: alpha_as_tdep = 0 must be the pre-2026-09-02 model, so this is
  # an exact bound and not a tolerance. It is what makes a pre-change vector
  # reproducible at all.
  aux <- aa_aux(0)
  for (T in AA_T) {
    a <- ccx_alpha_as(T, aux)
    expect_identical(a$down, 1 + ccx_const("ALPHA_AS_DOWN_LEGACY") / 1000)
    expect_identical(a$up,   1 + ccx_const("ALPHA_AS_UP_LEGACY")   / 1000)
  }
})

test_that("the legacy path is TEMPERATURE-INDEPENDENT and the shipped one is not", {
  # The mutation test for the switch itself: if `alpha_as_tdep` stopped being
  # read, one of these two assertions has to fail.
  a0 <- lapply(AA_T, ccx_alpha_as, aux = aa_aux(0))
  a1 <- lapply(AA_T, ccx_alpha_as, aux = aa_aux(1))
  expect_equal(length(unique(vapply(a0, function(x) x$up, 0))), 1L)
  expect_gt(length(unique(vapply(a1, function(x) x$up, 0))), 1L)
  expect_false(isTRUE(all.equal(a0[[1]]$up, a1[[1]]$up)))
})

test_that("the shipped pair reproduces Zhang et al. 1995 at its own coefficients", {
  # Recomputed from the REGISTERED constants rather than from a second copy of
  # the fit, so a constants edit moves both sides together and this test cannot
  # silently bless a changed coefficient. What it pins is the STRUCTURE:
  # eps_down = eps_k, eps_up = eps_k - eps_DIC-g (Quay et al. 2003 eq.2).
  aux <- aa_aux(1)
  for (T in AA_T) {
    ek <- ccx_const("ALPHA_AS_KIN_5") +
          (ccx_const("ALPHA_AS_KIN_21") - ccx_const("ALPHA_AS_KIN_5")) / (21 - 5) * (T - 5)
    ed <- ccx_const("ALPHA_AS_ZHANG_A") * T * ccx_const("ALPHA_AS_FCO3") +
          ccx_const("ALPHA_AS_ZHANG_B") * T + ccx_const("ALPHA_AS_ZHANG_C")
    a <- ccx_alpha_as(T, aux)
    expect_equal((a$down - 1) * 1000, ek,      tolerance = 1e-12)
    expect_equal((a$up   - 1) * 1000, ek - ed, tolerance = 1e-12)
  }
})

test_that("the steady-state surface offset the pair implies IS the equilibrium offset", {
  # d_ml - d_atm at steady state = eps_down - eps_up, and the whole point of
  # carrying the kinetic effect on BOTH limbs is that this comes out at
  # eps_DIC-g. If someone "simplifies" the pair to -eps_DIC-g on the evasion
  # limb alone, this is the test that objects.
  aux <- aa_aux(1)
  for (T in AA_T) {
    a  <- ccx_alpha_as(T, aux)
    ed <- ccx_const("ALPHA_AS_ZHANG_A") * T * ccx_const("ALPHA_AS_FCO3") +
          ccx_const("ALPHA_AS_ZHANG_B") * T + ccx_const("ALPHA_AS_ZHANG_C")
    expect_equal(((a$down - 1) - (a$up - 1)) * 1000, ed, tolerance = 1e-12)
  }
})

test_that("the measured slope is what the model actually applies", {
  # ⚠ The number this pins is the one the whole 2026-09-02 arc turns on. It is
  # DERIVED from the registered constants, not typed: dEps_up/dT = dEps_k/dT
  # - dEps_DIC-g/dT.
  aux <- aa_aux(1)
  num <- ((ccx_alpha_as(21, aux)$up - ccx_alpha_as(5, aux)$up) * 1000) / (21 - 5)
  ana <- (ccx_const("ALPHA_AS_KIN_21") - ccx_const("ALPHA_AS_KIN_5")) / (21 - 5) -
         (ccx_const("ALPHA_AS_ZHANG_A") * ccx_const("ALPHA_AS_FCO3") +
          ccx_const("ALPHA_AS_ZHANG_B"))
  expect_equal(num, ana, tolerance = 1e-12)
  expect_gt(num, 0.10); expect_lt(num, 0.13)   # the measured band, both printings
})

test_that("R and C++ agree on the pair, at BOTH settings", {
  skip_if_no_cpp()
  # A PORT IDENTITY, so the bound is the reassociation floor and not a fitted
  # tolerance -- see test-parity.R's derivation of the same idea.
  for (td in c(0, 1)) {
    p  <- within(ccx_default_params(), alpha_as_tdep <- td)
    sp <- ccx_spinup(p)
    F  <- ccx_build_forcing("historical", c(1750, 1850), prod_c14 = sp$prod_c14)
    oR <- ccx_run(sp, F)$out
    oC <- ccx_run_fast(sp, F)$out
    expect_equal(oC$d13c_NH, oR$d13c_NH, tolerance = 1e-10)
    expect_equal(oC$d13c_SH, oR$d13c_SH, tolerance = 1e-10)
  }
})

test_that("GATE Q discriminates: it FAILS the retired pair and PASSES the shipped one", {
  skip_if_no_cpp()
  # ⛔ THE MUTATION TEST FOR THE GATE, not for the model. Its first version read
  # the equilibrium offset off the model's OWN alphas, which made it
  # self-referential -- it passed the retired pair at 1.2 sigma when that pair
  # is 6.4 sigma out. A gate that cannot fail is not a gate.
  source(ccx_path("calibration", "lib_design_gates.R"), local = TRUE)
  res <- lapply(c(0, 1), function(td) {
    v <- dg_vector(CCX_MODE_CANONICAL); v$p$alpha_as_tdep <- td
    dg_gateQ(dg_run(v), v)
  })
  expect_false(res[[1]]$pass)          # retired pair
  expect_true(res[[2]]$pass)           # shipped pair
  expect_gt(res[[1]]$n_sd, 3 * res[[2]]$n_sd)
})
