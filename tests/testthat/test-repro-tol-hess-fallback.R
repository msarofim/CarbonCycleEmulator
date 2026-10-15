# =====================================================================
# THE REPRODUCE-GATE TOLERANCE and THE HESSIAN's NO-PLATEAU STEP (2026-10-13; CHANGELOG 2026-10-13 c).
# Both RULED by Marcus after the WTC landing stopped at fit_iav_module.R GATE 0 (1.18e-5 > 1e-5) and its Hessian lost
# negative-definiteness. Both were the objective's numerical noise floor, ~4-5x #17's under label hilda_csl3v0kaidgbemwtc
# (outputs/diagnostics/objective_noise_floor_20261013_wtc.log):
#   * "5e-5, all three (Recommended)": promote GATE 4, recompute_hessian GATE 1 and fit_iav_module GATE 0 read ONE
#     value, CCX_REPRO_TOL. Promote's GATE 5 (the decomposition) joined it by a second ruling the same day
#     ("Raise to CCX_REPRO_TOL (Recommended)"; CHANGELOG 2026-10-13 e).
#   * "Most-stable step (Recommended)": a direction with no 2 % plateau takes the interior grid step whose curvature
#     disagrees least with its neighbors, instead of the fixed 3e-4 in u.
# =====================================================================

.root_rt <- normalizePath(file.path(testthat::test_path(), "..", ".."))
code_of <- function(rel) paste(ccx_code_lines(readLines(file.path(.root_rt, rel), warn = FALSE)), collapse = "\n")

test_that("CCX_REPRO_TOL is the ruled 5e-5, and the four ruled gates read it (promote GATE 4 + 5, Hessian GATE 1, module GATE 0)", {
  expect_identical(CCX_REPRO_TOL, 5e-5)
  pr <- code_of("calibration/promote_multistart_mode.R")
  expect_match(pr, "PMM_LP_TOL\\s*<-\\s*CCX_REPRO_TOL")
  expect_match(pr, "abs\\(lp0 - best\\$logpost\\) > PMM_LP_TOL")              # GATE 4
  expect_match(pr, "PMM_DECOMP_TOL\\s*<-\\s*CCX_REPRO_TOL")                   # GATE 5 (ruled 10-13 e)
  expect_match(pr, "abs\\(pri - pj\\) > PMM_DECOMP_TOL")
  expect_false(grepl("PMM_DECOMP_TOL\\s*<-\\s*1e-5", pr))
  expect_match(code_of("calibration/recompute_hessian.R"), "abs\\(lp0 - md\\$logpost\\) > CCX_REPRO_TOL")   # GATE 1
  fi <- code_of("calibration/fit_iav_module.R")
  expect_match(fi, "IAV_REPRO_TOL\\s*<-\\s*CCX_REPRO_TOL")
  expect_match(fi, "dmax > IAV_REPRO_TOL")                                     # GATE 0
  # no ruled gate still carries a literal 1e-5
  expect_false(grepl("md\\$logpost\\) > 1e-5", code_of("calibration/recompute_hessian.R")))
  expect_false(grepl("IAV_REPRO_TOL\\s*<-\\s*1e-5", fi))
})

# The three gates left at 1e-5 by 10-13 (c), RULED 2026-10-13 (o) (Marcus: "Use CCX_REPRO_TOL (Recommended)", all three).
test_that("the MCMC start gate, the WTC read and the IAV redesign price read CCX_REPRO_TOL too", {
  mc <- code_of("calibration/run_mcmc_check.R")
  expect_match(mc, "MC_LP_TOL\\s*<-\\s*CCX_REPRO_TOL")
  expect_match(mc, "abs\\(lp0 - md\\$logpost\\) < MC_LP_TOL")
  wr <- code_of("calibration/diag_wtc_refit_read.R")
  expect_match(wr, "WR_REPRO_TOL\\s*<-\\s*CCX_REPRO_TOL")
  ip <- code_of("calibration/diag_iav_redesign_price.R")
  expect_match(ip, "IAV_REPRO_TOL\\s*<-\\s*CCX_REPRO_TOL")
  expect_match(ip, "dmax > IAV_REPRO_TOL")
  for (x in list(mc, wr, ip)) expect_false(grepl("(MC_LP_TOL|WR_REPRO_TOL|IAV_REPRO_TOL)\\s*<-\\s*1e-5", x))
})

# A synthetic, SEPARABLE log-posterior whose diagonal curvature at every grid step is a DESIGNED value:
# f_k(x) = c_k(|x|) x^2 / 2, with c_k interpolated in log10 |x| through the table, so the central difference at a grid
# step returns the table entry exactly (up to roundoff). NA in a table = the step leaves the feasible region (-Inf).
synth_lp <- function(tab) {
  g <- log10(CCX_HESS_EPS_GRID)
  cf <- lapply(tab, function(cv) { ok <- is.finite(cv); c1 <- cv[ok][1]
    list(f = if (sum(ok) >= 2L) stats::approxfun(g[ok], cv[ok], rule = 2) else function(z) c1,
         xmax = if (all(ok)) Inf else max(CCX_HESS_EPS_GRID[ok]) * 1.5) })
  function(u) { s <- 0
    for (k in seq_along(cf)) { x <- abs(u[[k]]); if (x > cf[[k]]$xmax) return(-Inf)
      if (x > 0) s <- s + cf[[k]]$f(log10(x)) * x^2 / 2 }
    s }
}
# the two rows of the WTC landing's id-17 Hessian that had no plateau (outputs/diagnostics/wtc_landing_20261013/hessian_id017.log)
ROW_KZDF <- c(-1.183e4, -2.561e3, -3.896e2, 46.86, -7.452, -2.582, -2.424, -2.348, -2.356, -2.415)
ROW_HML  <- c(-5.642e4, -3.328e3, -3.148e2, -1.185e2, -1.528e2, -1.494e2, -1.498e2, -1.604e2, -1.401e2, NA)

test_that("no plateau: the MOST-STABLE grid step (id 17's kz_deep_frac -> 1e-1, h_ml -> 3e-3), still flagged", {
  tab <- list(flat = rep(-100, 10), kzdf = ROW_KZDF, hml = ROW_HML, pos = rep(5, 10),
              none = c(-1, rep(NA, 9)))
  u <- stats::setNames(numeric(length(tab)), names(tab))
  # "NaNs produced" is expected here: ccx_hessian_per_direction()'s ifelse() evaluates sqrt(-d) for the POSITIVE
  # plateau too ("pos") and then discards it (pre-existing, unchanged by the ruling)
  HD <- expect_warning(ccx_hessian_per_direction(synth_lp(tab), u, verbose = FALSE), "NaNs produced")
  # the table is what the function measured (a sanity check on the synthetic, not on the code)
  expect_equal(unname(HD$curvature_by_step["kzdf", ]), ROW_KZDF, tolerance = 1e-6)
  # a plateau: eps = 0.10 x sd, sd = 1 / sqrt(100) -- unchanged by the ruling
  expect_equal(HD$eps[["flat"]], CCX_HESS_EPS_FRAC * 0.1, tolerance = 1e-9)
  expect_false("flat" %in% HD$no_plateau)
  # the ruled case
  expect_identical(HD$eps[["kzdf"]], 1e-1)                 # 2.5 % beats 3e-2's 3.2 %
  expect_identical(HD$eps[["hml"]], 3e-3)                  # 2.28 %, just over the 2 % test
  expect_true(all(c("kzdf", "hml") %in% HD$no_plateau))     # still FLAGGED as no-plateau
  expect_identical(unname(HD$fallback_how[c("kzdf", "hml")]), c("most_stable", "most_stable"))
  # outside the ruling, unchanged: a stable NON-NEGATIVE plateau and a direction with no finite step keep 3e-4
  expect_identical(HD$eps[["pos"]], CCX_HESS_FALLBACK)
  expect_identical(HD$fallback_how[["pos"]], "fixed_nonneg_plateau")
  expect_identical(HD$eps[["none"]], CCX_HESS_FALLBACK)
  expect_identical(HD$fallback_how[["none"]], "fixed_none_finite")
  expect_identical(CCX_HESS_FALLBACK, 3e-4)
})

test_that("POWER: the old fixed 3e-4 step reads the floor; the most-stable step reads the curvature", {
  # at the WTC floor (~1e-5 in logpost) a 3e-4 step's curvature noise is ~1e-5 / (3e-4)^2 ~ 110, larger than kz_deep_frac's
  # own -2.4: the synthetic's row at 3e-4 is +46.86 (wrong sign), at the chosen step -2.356
  idx <- match(c(3e-4, 1e-1), CCX_HESS_EPS_GRID)
  expect_gt(ROW_KZDF[idx[1]], 0)
  expect_lt(ROW_KZDF[idx[2]], 0)
  expect_gt(1e-5 / 3e-4^2, 10 * abs(ROW_KZDF[idx[2]]))
})
