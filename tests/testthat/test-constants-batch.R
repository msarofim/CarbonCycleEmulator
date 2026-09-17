# =====================================================================
# THE CONSTANTS BATCH (2026-09-14 h): the "hilda_c" structure = "hilda" with the
# whole-LS mixed-layer SST (22.3/18.7 re-based), the ocean's measured hs_frac
# (0.128) and the biosphere-wide alpha_photo_eps (15.6, ruled), every value read
# from data/obs_tr_box.rds or a named constant; `alpha_photo_eps` a BASE
# parameter whose absence is the ledger's 18. What this file guards:
#   * every registered mode's base is UNTOUCHED (bit-exact under "hilda");
#   * the block's values DERIVE from the product (no typed number drifts);
#   * the batch is LIVE (each item moves the state) -- a mutation per item;
#   * the ledger's ALPHA_PHOTO_EPS is still 18 / provisional (the refit adopts).
# =====================================================================

test_that("hilda_c is a registered label, its block derives from the product, and hilda's block is untouched", {
  expect_identical(CCX_STRUCT_LABELS, c("", "hilda", "hilda_eq", "hilda_tr", "hilda_c"))
  blk <- ccx_struct_block("hilda_c"); o <- ccx_tr_box_obs(); g <- o$geom
  expect_identical(CCX_STRUCT_HILDA$hs_frac, 0.16)                         # the registered modes' base
  expect_identical(CCX_STRUCT_HILDA$sst_NH, NULL)                          # hilda declares no SST
  expect_equal(blk$sst_NH, g$NH$sst_ls_clim + o$rebase_C[["NH"]], tolerance = 1e-12)
  expect_equal(blk$sst_SH, g$SH$sst_ls_clim + o$rebase_C[["SH"]], tolerance = 1e-12)
  expect_gt(blk$sst_NH, 22); expect_lt(blk$sst_NH, 23); expect_gt(blk$sst_SH, 18); expect_lt(blk$sst_SH, 19.5)
  a <- c(g$NH$hemi_ocean_m2, g$SH$hemi_ocean_m2)
  expect_equal(blk$hs_frac, sum(a * c(g$NH$hs_frac, g$SH$hs_frac)) / sum(a), tolerance = 1e-12)
  expect_gt(blk$hs_frac, 0.125); expect_lt(blk$hs_frac, 0.131)
  expect_identical(blk$alpha_photo_eps, CCX_ALPHA_PHOTO_EPS_BIOSPHERE)
  expect_gte(blk$alpha_photo_eps, 14.8); expect_lte(blk$alpha_photo_eps, 16.5)  # inside the sourced bracket
  # everything hilda declares is carried unchanged
  for (n in setdiff(names(CCX_STRUCT_HILDA), "hs_frac")) expect_identical(blk[[n]], CCX_STRUCT_HILDA[[n]], info = n)
  # the ledger did NOT move
  expect_identical(ccx_const("ALPHA_PHOTO_EPS"), 18); expect_identical(CCX_CONSTANTS$ALPHA_PHOTO_EPS$status, "provisional")
  # the residual-ML pair is hilda_tr's, NOT hilda_c's (the wrong box for a structure without tr)
  expect_lt(ccx_struct_block("hilda_tr")$sst_NH, blk$sst_NH - 4)
})

test_that("alpha_photo_eps: absent = the ledger's 18 (bit-exact for every registered file); set = read", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  expect_false("alpha_photo_eps" %in% names(p))
  expect_identical(ccx_prepare(p)$alpha_photo, 1 - 18 / 1000)
  q <- p; q$alpha_photo_eps <- 15.6
  expect_identical(ccx_prepare(q)$alpha_photo, 1 - 15.6 / 1000)
  md <- readRDS(ccx_mode_file()); bp <- ccx_mode_base(md)
  # 2026-09-17 (h): the canonical is hilda30h on `hilda_c`, which SETS the constant (15.6); a hilda
  # file leaves it absent (= the ledger's 18). Either way the base says which structure it is.
  expect_identical(attr(bp, "struct"), ccx_mode_struct(md))
  if (identical(ccx_mode_struct(md), "hilda_c")) expect_identical(bp$alpha_photo_eps, 15.6) else expect_false("alpha_photo_eps" %in% names(bp))
})

test_that("the batch is LIVE: each item moves the PI state on its own, and all three together", {
  ph <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 0)
  pc <- ccx_apply_structure(ccx_default_params(), "hilda_c", seas_ml = 0)
  yh <- ccx_spinup(ph)$y; yc <- ccx_spinup(pc)$y
  expect_gt(max(abs(yc[, "C"] - yh[, "C"])), 1)
  blk <- ccx_struct_block("hilda_c")
  for (item in list(c("sst_NH", "sst_SH"), "hs_frac", "alpha_photo_eps")) {
    q <- ph; for (n in item) q[[n]] <- blk[[n]]
    yq <- ccx_spinup(q)$y
    moved <- if (identical(item, "alpha_photo_eps")) max(abs(yq[, "C13"] / yq[, "C"] - yh[, "C13"] / yh[, "C"])) > 1e-6
             else max(abs(yq[, "C"] - yh[, "C"])) > 1e-3
    expect_true(moved, info = paste(item, collapse = "+"))
  }
})

test_that("the C++ core runs hilda_c and agrees with R; the canonical's streams still reproduce under hilda", {
  skip_if_no_cpp()
  pc <- ccx_apply_structure(ccx_default_params(), "hilda_c", seas_ml = 1)
  sp <- ccx_spinup(pc)
  F  <- ccx_build_forcing("historical", c(1900, 1902), prod_c14 = sp$prod_c14)
  r  <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
  expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "batch"))
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(ccx_par_to_unc(pm))
  ccx_unpin_params(rm); rm <- list()
  expect_identical(attr(sc, "streams")[names(md$streams)], md$streams)
})
