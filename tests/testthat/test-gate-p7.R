# =====================================================================
# GATE P7 -- a surface mechanism must not be a vertical-gradient lever.
# Promoted from round 6's prereg on 2026-09-11, when the seas_ml = 1 refit
# moved the modern surface-deep d13C gradient by 2x the row's sigma_eff and
# was REFUTED on it (CHANGELOG 2026-09-11; diag_round6_p7_gradient.R).
#   (1) the kernel is mutation-tested: identity passes, a move at the bound
#       passes, a move just past it fails, a non-finite move fails;
#   (2) the DIC move is reported in its own units and never decides `pass`;
#   (3) POWER, measured on the record: the round-6 mode (start_004.rds, seas_ml
#       1) against the canonical hilda31p (seas_ml 0), scored through the
#       objective's own ccx_ocean_grad_scored(), FAILS the gate -- and the
#       numbers reproduce the ones the ruling was taken on.
# =====================================================================
source(ccx_path("calibration", "lib_design_gates.R"))

gp7 <- function(d13c, dic, sd13 = 0.163, sddic = 32.9)
  list(d13c = d13c, dic = dic, sd_eff = c(dic = sddic, d13c = sd13))

test_that("GATE P7 kernel: identity passes, the bound passes, past it fails, DIC never decides", {
  off <- gp7(-0.309, 302)
  expect_true(dg_gateP7_verdict(off, off)$pass)
  expect_true(dg_gateP7_verdict(off, gp7(-0.309 + 0.163, 302))$pass)      # AT the bound
  expect_false(dg_gateP7_verdict(off, gp7(-0.309 + 0.164, 302))$pass)     # just past it
  expect_false(dg_gateP7_verdict(off, gp7(-0.309 - 0.164, 302))$pass)     # either direction
  expect_false(dg_gateP7_verdict(off, gp7(NA_real_, 302))$pass)
  # a large DIC move alone does not fail the gate; it is REPORTED
  v <- dg_gateP7_verdict(off, gp7(-0.309, 385))
  expect_true(v$pass); expect_equal(v$move_dic, 83); expect_gt(v$ratio_dic, 2)
  # the bound is the OFF arm's sd_eff, never the ON arm's
  expect_false(dg_gateP7_verdict(off, gp7(-0.309 + 0.2, 302, sd13 = 10))$pass)
})

test_that("GATE P7 has POWER: the round-6 seas_ml = 1 mode FAILS it against hilda31p, and the numbers reproduce", {
  skip_if_no_cpp()
  r6 <- ccx_path("calibration", "output", "multistart_20260910_round6_seasml1_sd1.0452", "start_004.rds")
  skip_if_not(file.exists(r6), "round-6 start file not present")
  # each file's OWN structure and seas_ml through the one resolver (test-mode-struct-lint.R)
  grad_at <- function(mdx) {
    pm <- mdx$par_mode
    bp <- ccx_mode_base(mdx); bp$pump_mode <- mdx$pump_mode
    p <- ccx_overlay_par(bp, pm); sp <- CCX_OBJECTIVE_SPINUP(p)
    F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
    F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pm$bomb_total / 102)
    for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
    attr(F, "luc_scale") <- pm$luc_scale
    ccx_ocean_grad_scored(ccx_run_fast(sp, F)$out, sp)
  }
  md <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL)); s4 <- readRDS(r6)
  expect_identical(ccx_mode_seas_ml(md), 0L); expect_identical(ccx_mode_seas_ml(s4), 1L)
  expect_identical(ccx_mode_struct(md), "hilda"); expect_identical(ccx_mode_struct(s4), "hilda")
  g0 <- grad_at(md); g1 <- grad_at(s4)
  v <- dg_gateP7_verdict(g0, g1)
  expect_false(v$pass)
  expect_gt(v$ratio_d13c, 1.5)                         # 2.0x on 2026-09-11
  # RE-PINNED 2026-09-11 (5) to the ANNUAL-MEAN read ([[seasonal_box_observable_artefact]]).
  # The 09-11 (2) record (-0.309 -> +0.018, DIC 302 -> 385) was the instant-over-mean-mass
  # artefact. Under the corrected observable the round-6 DIC gradient is AT the target
  # (226 vs 233) and only the d13C half fails -- and that half is the UNREFIT mode's deep
  # box, moved by the fit to cancel the artefact, not a property of the mechanism. This
  # pins the RECORD at that mode; it is re-pinned again when round 6 is refit.
  # RE-PINNED 2026-09-12 (rulings 4+5): the reader takes the model's own rows and
  # the periodic spinup pins annual means; -0.300/+0.031/300/227 -> the values below.
  expect_equal(v$d13c_off, -0.301, tolerance = 2e-3, scale = 1)
  expect_equal(v$d13c_on,   0.029, tolerance = 2e-3, scale = 1)
  expect_equal(v$dic_off,  300,    tolerance = 1,    scale = 1)
  expect_equal(v$dic_on,   229,    tolerance = 1,    scale = 1)
  # and the target, for the reader: the model was already too weak on d13c
  tg <- ccx_ocean_gradient_target()
  expect_lt(abs(v$d13c_off - tg$d13c$target), abs(v$d13c_on - tg$d13c$target))   # ON is FURTHER from obs
})

test_that("THE VERDICT ON THE RECORD (2026-09-11 (7)): the round-6b mode -- the same arm REFITTED under the corrected observable -- PASSES GATE P7", {
  skip_if_no_cpp()
  r6b <- ccx_path("calibration", "output", "multistart_20260911_round6b_seasml1_sd1.0452", "start_005.rds")
  skip_if_not(file.exists(r6b), "round-6b start file not present")
  grad_at <- function(mdx) {
    pm <- mdx$par_mode
    bp <- ccx_mode_base(mdx); bp$pump_mode <- mdx$pump_mode
    p <- ccx_overlay_par(bp, pm); sp <- CCX_OBJECTIVE_SPINUP(p)
    F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
    F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pm$bomb_total / 102)
    for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * pm$luc_scale
    attr(F, "luc_scale") <- pm$luc_scale
    ccx_ocean_grad_scored(ccx_run_fast(sp, F)$out, sp)
  }
  md <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL)); s5 <- readRDS(r6b)
  expect_identical(ccx_mode_seas_ml(s5), 1L)
  v <- dg_gateP7_verdict(grad_at(md), grad_at(s5))
  expect_true(v$pass)
  expect_lt(v$ratio_d13c, 0.25)                        # 0.17x on 2026-09-11 (7)
  expect_equal(v$d13c_on, -0.330, tolerance = 2e-3, scale = 1)   # TOWARD the target (-0.861), from -0.301 (re-pinned 09-12; was -0.327 / 304)
  expect_equal(v$dic_on,  306,    tolerance = 1,    scale = 1)
  # the same gate, same read, still FAILS the artefact-fitted 09-10 mode (the test above):
  # that is the gate's power, and this is its verdict on the mechanism.
})
