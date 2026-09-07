# =====================================================================
# Gate: the ocean gradient rows convert box carbon to concentration over the
# area the box actually spans (2026-09-07d).
#
# WHY. Since the HILDA boxes (2026-09-05) the low-latitude column occupies
# a_ls = a_oc * (1 - hs_frac); ccx_model_ocean_gradient() and the ALK profile
# solve divided by a_oc, so every HILDA-arm DIC / ALK gradient was read
# (1 - hs_frac) = 16 percent low while ent26 (hs_frac 0) was exact. These
# tests are MUTATION-TESTED: replacing ccx_column_area() with a_oc makes
# every one fail (checked 2026-09-07d before commit).
# =====================================================================
test_that("ccx_model_ocean_gradient reads a known concentration back exactly at hs_frac 0.16", {
  rho <- ccx_const("RHO_SEAWATER"); mol <- 1e15 / 12.011
  grid <- list(dz = c(75, 100, 200))
  a_oc <- list(NH = 1.5e14, SH = 2.1e14)
  aux <- list(a_oc = a_oc, a_ls = lapply(a_oc, function(A) A * (1 - 0.16)),
              mol_per_GtC = mol)
  c_ml <- 2000; c_deep <- 2233                       # umol/kg, target-like
  gtc <- function(conc, A, dz) conc * 1e-6 * A * dz * rho / mol
  out <- data.frame(t = c(1990, 2010))
  for (h in HEMIS) {
    out[[paste0("ml_C_", h)]]     <- gtc(c_ml,   aux$a_ls[[h]], grid$dz[1])
    out[[paste0("deep_C_", h)]]   <- gtc(c_deep, aux$a_ls[[h]], grid$dz[3])
    out[[paste0("ml_C13_", h)]]   <- out[[paste0("ml_C_", h)]]   * ccx_const("R13_VPDB")
    out[[paste0("deep_C13_", h)]] <- out[[paste0("deep_C_", h)]] * ccx_const("R13_VPDB")
  }
  g <- ccx_model_ocean_gradient(out, aux, grid, list(surf = 2000, deep = 2000))
  expect_equal(g$dic, c_deep - c_ml, tolerance = 1e-9)   # a_oc would give 0.84x
  expect_equal(g$d13c, 0, tolerance = 1e-9)
})

test_that("ccx_column_area is a_ls when present and a_oc otherwise", {
  aux <- list(a_oc = list(NH = 10, SH = 20), a_ls = list(NH = 8.4, SH = 16.8))
  expect_equal(ccx_column_area(aux, "NH"), 8.4)
  expect_equal(ccx_column_area(list(a_oc = list(NH = 10, SH = 20)), "SH"), 20)
})

test_that("the ALK steady profile scales as 1/area: halving the column area doubles it", {
  rho <- ccx_const("RHO_SEAWATER"); mol <- 1e15 / 12.011
  grid <- list(nl = 3L, dz = c(75, 100, 200, 400))
  S <- c(-0.5, 0.3, 0.2)                                # GtC/yr, sums to zero
  aux <- list(a_oc = list(NH = 1.5e14), a_ls = list(NH = 1.5e14),
              mol_per_GtC = mol, dz_mid = c(87.5, 150, 300), kz_int = rep(3000, 3))
  p <- list(kz = 3000)
  full <- ccx_steady_profile_from_source(S, p, aux, grid, "NH")
  aux$a_ls$NH <- 0.5 * aux$a_oc$NH
  half <- ccx_steady_profile_from_source(S, p, aux, grid, "NH")
  expect_equal(half, 2 * full, tolerance = 1e-12)       # a_oc would give 1x
})
