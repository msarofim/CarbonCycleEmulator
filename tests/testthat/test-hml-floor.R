# =====================================================================
# h_ml's BOX FLOOR = the Holte prior's 16 % point (2026-09-16 b, Marcus), and the
# BAND TERM in ccx_mode_start() that keeps every stored logpost reproducible
# across a logit-band change without restamping the files.
#   F1 the floor IS the prior's 16 % point (the two cannot drift apart)
#   F2 every registered mode's h_ml lies inside the live box
#   F3 every registered mode's stored logpost reproduces through the shift
#   F4 MUTATION: without the band term the canonical's reproduction FAILS by
#      the Jacobian difference -- the term has power
# =====================================================================
test_that("F1: the table's h_ml floor is the named constant, and that is the prior's 16 % point", {
  expect_identical(CCX_PARAM_TABLE$h_ml$lo, CCX_HML_FLOOR_M)
  expect_identical(CCX_PARAM_TABLE$h_ml$tr, "logit")
  pr <- ccx_h_ml_prior()
  q16 <- exp(log(pr$centre_m) + stats::qnorm(0.16) * pr$log_sd)
  expect_lt(abs(CCX_HML_FLOOR_M - q16), 0.1)
  expect_lt(abs(CCX_HML_FLOOR_M - pr$q[2]), 0.1)
})

test_that("F2: every registered mode's h_ml lies inside the live box", {
  for (m in names(CCX_MODE_FILES)) {
    md <- readRDS(ccx_mode_file(m))
    h <- md$par_mode[["h_ml"]]
    expect_true(is.finite(h) && h > CCX_PARAM_TABLE$h_ml$lo && h < CCX_PARAM_TABLE$h_ml$hi,
                info = sprintf("%s: h_ml %.2f outside [%g, %g]", m, h, CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi))
  }
})

test_that("F3 + F4: every registered mode's logpost reproduces through ccx_mode_start()'s shift; the band term has power", {
  skip_if_no_cpp()
  for (m in names(CCX_MODE_FILES)) {
    md <- readRDS(ccx_mode_file(m))
    rm <- ccx_apply_pins(ccx_mode_pins(md))
    bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
    st <- ccx_mode_start(md, sprintf("hml-floor %s", m))
    lp <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
    v <- as.numeric(lp(st$u))
    ccx_unpin_params(rm)
    expect_lt(abs(v - st$logpost_shift - md$logpost), 1e-4, label = sprintf("%s logpost reproduction", m))
    rec <- md$hml_bound
    if (!is.null(rec) && !isTRUE(all.equal(rec, c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)))) {
      # the file was fitted under another band: the term is non-zero, and WITHOUT it the gate fails
      expect_gt(abs(st$band_shift), 0.1, label = sprintf("%s band_shift", m))
      expect_gt(abs(v - (st$logpost_shift - st$band_shift) - md$logpost), 0.1, label = sprintf("%s naive reproduction must FAIL", m))
    } else {
      expect_identical(st$band_shift, 0)
    }
  }
})
