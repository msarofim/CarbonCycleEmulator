# =====================================================================
# test-gates-w4.R -- W4 (2026-10-02): the gate repairs ruled before the objective-#15 mode is
# scored (Marcus 10-02 z: "Restore gates 6 and 11, Fix P7's comparison, Align gate 7's target,
# Restore gate 5's sub-checks"; audit notes/audit_2026-10-02_design_vs_build.md B6, B7, C4, C5).
#   GATE 7  the target is GCB + the arm's OWN D3 shares x I(t), as the objective scores it; an arm
#           with no shares gets bare GCB, unchanged.
#   P7      the OFF arm is the SAME fitted vector with the seasonal mixed layer relabelled off,
#           not another file.
# (Gates 5, 6, 11 and gate D's ledger row follow, each with its own block.)
# Each block is mutation-tested (CHANGELOG 10-02).
# =====================================================================
source(ccx_path("calibration", "lib_design_gates.R"))

test_that("GATE 7: bare GCB without shares, GCB + s x I(t) with them -- the objective's own targets", {
  g <- as.data.frame(ccx_prepare_obs()$gcb)
  k <- g$year >= DG_SINK_WIN[1] & g$year <= DG_SINK_WIN[2]
  t0 <- dg_gcb_target(DG_SINK_WIN)
  expect_identical(t0$land, mean(g$land_sink[k])); expect_identical(t0$ocean, mean(g$ocean_sink[k]))
  expect_null(t0$shares)
  # the canonical fits shares (objective #14+): its target moves by exactly s x mean(I) over the window
  md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
  sh <- ccx_imb_shares(ccx_mode_base(md)); if (is.null(sh)) sh <- ccx_imb_shares(md$par_mode)
  expect_false(is.null(sh))
  t1 <- dg_gcb_target(DG_SINK_WIN, shares = sh)
  im <- ccx_imb_series(g); I <- im$I[match(g$year[k], im$year)]
  expect_equal(t1$land - t0$land, sh[["land"]] * mean(I), tolerance = 1e-12)
  expect_equal(t1$ocean - t0$ocean, sh[["ocean"]] * mean(I), tolerance = 1e-12)
  expect_gt(abs(t1$land - t0$land) + abs(t1$ocean - t0$ocean), 0.01)          # POWER: the move is real
  # the shares are the OBJECTIVE's: the same I(t) treatment the likelihood reads
  expect_identical(im, ccx_imb_series(g, LIK_IMB_TREATMENT, LIK_IMB_WITH_CEMENT))
  # half a pair is refused by the likelihood's own check
  expect_error(dg_gcb_target(DG_SINK_WIN, shares = c(land = 0.2, ocean = NA)), "")
})

test_that("P7: the OFF arm is the SAME vector with only the seasonal mixed layer switched off", {
  skip_if_no_cpp()
  v <- dg_vector(CCX_MODE_CANONICAL)
  g <- dg_gateP7_same_vector(v)
  # the OFF vector differs from the ON one in seas_ml ONLY (every fitted value and pin identical)
  p_on <- v$p; p_off <- g$v_off$p
  expect_identical(as.integer(p_on$seas_ml), 1L); expect_identical(as.integer(p_off$seas_ml), 0L)
  same <- setdiff(union(names(p_on), names(p_off)), "seas_ml")
  for (n in same) expect_identical(p_off[[n]], p_on[[n]], info = n)
  # the ON arm IS the file's own run, read by the objective's scorer
  r <- dg_run(v); expect_identical(g$on, ccx_ocean_grad_scored(r$out, r$sp))
  # POWER: the mechanism moves the gradient (a test whose arms are identical has none)
  expect_gt(abs(g$on$d13c - g$off$d13c), 1e-4)
  vd <- dg_gateP7_verdict(g$off, g$on)
  expect_true(is.finite(vd$ratio_d13c))
  # a seas_ml-0 file cannot be P7's ON arm
  expect_error(dg_gateP7_same_vector(dg_vector(CCX_MODE_SEASML0_CONTROL)), "seas_ml")
})

test_that("GATE 5: the e-fold and both peak heights are IN the verdict, on their LOO spreads; no silent skip", {
  ob <- dg_obs_gate5(); sp <- dg_obs_gate5_spread()
  # the synthetic TRUTH, built from the observation, now carrying every judged field
  mk <- function(d_ef = 0, d_nhv = 0, d_shv = 0)
    list(pk = list(NH = c(t = ob$NH[["t"]], v = ob$NH[["v"]] + d_nhv, drop = ob$NH[["drop"]],
                          p1_t = ob$NH[["p1_t"]], efold = ob$NH[["efold"]] + d_ef),
                   SH = c(t = ob$SH[["t"]], v = ob$SH[["v"]] + d_shv, efold = ob$SH[["efold"]])),
         lag = ob$SH[["t"]] - ob$NH[["p1_t"]])
  v <- dg_gate5_verdict(mk(), ob, sp)
  expect_true(all(c("nh_efold", "nh_v", "sh_v") %in% names(v$z)))
  expect_true(v$pass); expect_true(all(v$z == 0))
  for (case in list(list(d_ef  = (DG_G5_NSD + 1) * sp$sd[["nh_efold"]], z = "nh_efold"),
                    list(d_nhv = (DG_G5_NSD + 1) * sp$sd[["nh_v"]],     z = "nh_v"),
                    list(d_shv = -(DG_G5_NSD + 1) * sp$sd[["sh_v"]],    z = "sh_v"))) {
    zname <- case$z; case$z <- NULL
    vv <- dg_gate5_verdict(do.call(mk, case), ob, sp)
    expect_false(vv$pass, info = zname); expect_gt(abs(vv$z[[zname]]), DG_G5_NSD)
  }
  # a fixture WITHOUT the e-fold is an error, never a skip
  bad <- mk(); bad$pk$NH <- bad$pk$NH[setdiff(names(bad$pk$NH), "efold")]
  expect_error(dg_gate5_verdict(bad, ob, sp))
})

test_that("GATE 6: the estimator recovers a known growth; the bootstrap se is seeded and recorded; the bound is two-sided", {
  # a synthetic MLO: a trend plus an annual sinusoid whose amplitude is 3.00 in the 1960s and 3.45 in the 2010s
  t <- seq(1955 + 0.5 / 12, 2025 - 0.5 / 12, by = 1 / 12)
  A <- ifelse(t < 1990, 3.00, 3.45)
  d <- dg_g6_seasonal(t, 320 + 1.5 * (t - 1955) + A * sin(2 * pi * t))
  r <- dg_g6_ptt(d, DG_G6_DECADES[[2]]) / dg_g6_ptt(d, DG_G6_DECADES[[1]])
  expect_equal(r, 3.45 / 3.00, tolerance = 1e-3)
  # the observed ratio, its se, and the provenance it carries
  o1 <- dg_gate6_obs(); o2 <- dg_gate6_obs()
  expect_identical(o1, o2)                                   # the seed makes it REPRODUCIBLE, byte for byte
  expect_identical(o1$seed, DG_G6_SEED); expect_identical(o1$boot, DG_G6_BOOT)
  expect_equal(o1$ratio, o1$ptt[[2]] / o1$ptt[[1]])
  expect_gt(o1$se, 0); expect_lt(o1$se, 0.2)
  # two-sided at DG_G6_NSD
  at <- function(k) dg_gate6_verdict(list(ratio = o1$ratio + k * o1$se), o1)
  expect_true(at(0)$pass); expect_true(at(DG_G6_NSD)$pass); expect_true(at(-DG_G6_NSD)$pass)
  expect_false(at(DG_G6_NSD + 0.01)$pass); expect_false(at(-DG_G6_NSD - 0.01)$pass)
  # the canonical runs it
  skip_if_no_cpp()
  vd <- dg_gate6_verdict(dg_gate6(dg_run(dg_vector(CCX_MODE_CANONICAL))), o1)
  expect_true(is.finite(vd$z))
})

test_that("GATE 11: the capture is the objective's own residuals, bit-identical streams, and the screen has power", {
  # the screen on synthetic series
  set.seed(7L)                                              # the noise below; recorded here
  expect_identical(dg_g11_screen(rep(0.3, 30) + abs(rnorm(30, 0, 0.01)))$flag, "ALL-SAME-SIGN")
  expect_identical(dg_g11_screen(seq(-1, 1, length.out = 40))$flag, "LINEAR")
  expect_identical(dg_g11_screen(rnorm(60))$flag, "")
  expect_false(dg_g11_screen(rnorm(DG_G11_MINN - 1))$screened)
  skip_if_no_cpp()
  v <- dg_vector(CCX_MODE_CANONICAL); r <- dg_run(v); obs <- ccx_prepare_obs()
  rm <- ccx_apply_pins(ccx_mode_pins(v$md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  s0 <- dg_streams(r, v, obs = obs); s1 <- dg_streams(r, v, obs = obs, residuals = TRUE)
  expect_identical(unname(unclass(s0)), unname(as.numeric(s1)))   # OFF and ON score the SAME objective
  res <- attr(s1, "residuals")
  expect_true(all(names(res) %in% names(s0)))
  # the residuals ARE the scored ones: the ice CO2 row, by hand on the same run
  o <- r$out[r$out$t < DG_SINK_LAST + 1, ]; ic <- obs$ice
  k <- ic$year >= floor(min(o$t) + 1e-9) & ic$year < LIK_ICE_CO2_END
  expect_equal(res$co2_icecore[[1]], ic$CO2ppm[k] - stats::approx(o$t, o$co2_SH, xout = ic$year[k], rule = 2)$y,
               tolerance = 1e-12)
  # the whole screen runs, and says which rows it could not see
  g <- dg_gate11(r, v, obs); vd <- dg_gate11_verdict(g)
  expect_gt(vd$n_screened, 15L)
  expect_true(all(vd$uncaptured %in% names(s0)))
  expect_error(ccx_loglik(o, obs, list(), by_stream = FALSE, residuals = TRUE), "by_stream")
})

test_that("THE LEDGER carries rows for 6, 11 and D, each with all seven fields", {
  ids <- vapply(DG_LEDGER, `[[`, "", "id")
  expect_true(all(c("6", "11", "D") %in% ids))
  for (g in DG_LEDGER[ids %in% c("5", "6", "11", "D")])
    expect_true(all(c("id", "what", "class", "src", "bound", "scored", "power") %in% names(g)), info = g$id)
  expect_match(DG_LEDGER[[which(ids == "5")]]$bound, "RESTORED 2026-10-02")
})
