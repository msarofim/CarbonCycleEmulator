# =====================================================================
# LABEL hilda_csl3v0kaidgbemwtc (2026-10-12): the cited constants, routed by label.
# Marcus, verbatim: "New label (a) (Recommended)"; the name "…wtc (c = cited)".
# Ledger: notes/citation_rulings_2026-10-12.md. Every changed value enters through a
# structure field whose ABSENCE is the old value, so what this file guards is, per item:
#   * ABSENT  = the legacy objective, bit for bit (every registered mode);
#   * PRESENT = the ruled value, read from its data product, never typed twice;
#   * the switch is LIVE (it moves the number it claims to move) -- a power check.
# =====================================================================

# ---- the column depth: GLODAP target products ------------------------------------------
test_that("GLODAP products: the depth key snaps to a built set, and an unbuilt depth STOPS", {
  expect_identical(ccx_glodap_depth_key(NULL), CCX_GLODAP_DEPTH_LEGACY)
  expect_identical(ccx_glodap_depth_key(3682.2 + 1e-9), 3682.2)
  expect_error(ccx_glodap_depth_key(3690), "no GLODAP target products")
  expect_identical(basename(ccx_glodap_file("obs_glodap_deep", 3700)), "obs_glodap_deep.rds")
  expect_identical(basename(ccx_glodap_file("obs_glodap_deep", 3682.2)), "obs_glodap_deep_3682.2m.rds")
  for (stem in c("obs_glodap_deep", "obs_glodap_intermediate", "obs_glodap_profile_cov", "obs_glodap_sigma_rep"))
    for (d in CCX_GLODAP_DEPTHS) expect_true(file.exists(ccx_glodap_file(stem, d)), info = paste(stem, d))
})

test_that("GLODAP products at 3682.2 m: the layer follows the column, and the targets move by << sigma", {
  a <- ccx_deep_d14c_target(); b <- ccx_deep_d14c_target(depth = 3682.2)
  expect_identical(a$layer, c(top = 2627.2, bottom = 3700))
  expect_identical(b$layer, c(top = 2614.7, bottom = 3682.2))
  g75 <- ccx_ocean_grid(75, total_depth = 3682.2)
  expect_equal(b$layer[["top"]], sum(g75$dz[-length(g75$dz)]), tolerance = 0.05 / 2614.7)
  expect_false(identical(a$target, b$target))                       # LIVE: the product differs
  expect_lt(abs(a$target - b$target), 0.05 * a$sd)                  # ... by far less than its sigma
  m <- ccx_mid_d14c_target(depth = 3682.2)
  expect_identical(m$slabs$bot[2], b$layer[["top"]])                # slab B ends where the deep row begins
  expect_identical(m$slabs$stream[2], "d14c_mid_2000_2615")
  expect_identical(ccx_mid_d14c_target()$slabs$stream[2], "d14c_mid_2000_2627")
  # the profile covariance embeds the three targets of ITS column (the spec's own consistency check)
  expect_silent(ccx_profile_d14c_spec(depth = 3682.2))
  expect_silent(ccx_profile_d14c_spec())
  ga <- ccx_ocean_gradient_target(); gb <- ccx_ocean_gradient_target(3682.2)
  expect_false(identical(ga$dic$target, gb$dic$target))
  expect_lt(abs(ga$dic$target - gb$dic$target), 0.05 * ga$dic$sd)
  expect_false(identical(ccx_ocean_sigma_eff("dic", 64.6), ccx_ocean_sigma_eff("dic", 64.6, depth = 3682.2)))
})

test_that("ccx_loglik refuses an ocean-gradient bundle built on another column", {
  obs <- ccx_prepare_obs()
  err <- list(sigma_d14c = 10, rep_dC = 0.1, grad_off_co2 = 0, grad_off_d13c = 0)   # the mode-file shape
  bundle <- list(dic = 200, d13c = -0.8, alk = 0, sd_eff = c(dic = 26, d13c = 0.12, alk = 19.2), h_ml = 64.6)
  out <- data.frame(year = numeric(0))
  b2 <- bundle; b2$ocean_depth <- 3682.2
  expect_error(ccx_loglik(out, obs, err, ocean_grad = b2), "built on a 3682.2 m column")
  e2 <- err; e2$ocean_depth <- 3682.2
  expect_error(ccx_loglik(out, obs, e2, ocean_grad = bundle), "built on a 3700 m column")
})

# ---- IntCal: the published D14C sigma -----------------------------------------------------
test_that("IntCal v2: the legacy columns are the shipped table's, and sd_d14c is column 5", {
  leg <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_intcal20.rds")))
  v2  <- readRDS(ccx_path("data", "obs_d14c_intcal20_v2.rds"))
  expect_identical(as.numeric(v2$year), as.numeric(leg$year))
  expect_identical(v2$d14c, leg$d14c)
  expect_identical(as.numeric(v2$err), as.numeric(leg$err))
  sc <- v2$year >= 1750 & v2$year < 1941
  expect_true(all(v2$sd_d14c[sc] >= 1.1 & v2$sd_d14c[sc] <= 1.4))  # permil, IntCal20 column 5
  expect_true(all(v2$err[sc] >= 9))                                 # the age sigma, in YEARS
  expect_identical(attr(v2, "provenance")$file_sha256,
                   "974a66649f2ac8a53e6c99e256b019ac6982f999b12dcf7193162d4c1c09168e")
})
