# =====================================================================
# test-iav-cut.R -- OBJECTIVE #17, THE INTERANNUAL CUT (RULED 2026-10-06 n; Marcus: "Build: land + ocean
# module (Recommended)", the label "hilda_csl3v0kaidgbemw (Recommended)"). R/likelihood.R "OBJECTIVE #17";
# notes/proposal_2026-10-06_iav_cut.md. Every gate is a MUTATION test in the sense of [[mutation_test_gates]]:
# the property is broken inside the test and the gate must then fail, or the mutation was run by hand on the
# source and is recorded in CHANGELOG 2026-10-06 (o).
#   IC1  THE LABEL       kaidgbem's block plus exactly the three cut fields; kaidgbem's gates; the ruled df
#   IC2  THE PROJECTOR   symmetric, idempotent, keeps the intercept, rank df + 1; the split is EXACT;
#                        MUTATION: an oblique projector splits inexactly; bad df refused
#   IC3  THE SWITCHES    absent = `err` untouched; the label's block sets both; junk refused
#   IC4  ABSENT          hilda33p reproduces its stored logpost and streams BIT FOR BIT under its own label
#   IC5  ON              at hilda33p's vector, module pinned at its own values: the land row IS the pricing
#                        preview's low-pass row; the slope row leaves; the other 25 rows bit-identical;
#                        the dg_streams path agrees
#   IC6  THE GUARD       under the cut the module's four names must ALL be pinned
#   IC7  THE ENSO PIN    (the fix found building #17) a pinned ENSO amplitude is READ: pinned at its own value
#                        = free, bit for bit; pinned at 0 moves the likelihood
#   IC8  THE DATA        the monthly product reproduces its estimator; its checksum is the manifest's
#   IC9  THE ESTIMATOR   at the fixture (IC_MODE): the preview's detrended series, SSR, r and n_eff reproduce; the
#                        module's slope row IS the main objective's row
#   IC10 REFUSALS        a run that stops at the record, ssr_ref <= 0, a slope row absent
#   IC11 A HAND-BUILT PINNED BASE (found by the 10-06 landing dry run: promote's GATE 5 gap 39.1): ccx_overlay_par()
#                        keeps the PROCESS's pins over a start's fitted-only par_mode, for #16's ten and #17's fourteen
# THE FIXTURE IS hilda33p, NAMED: the canonical the cut was previewed and priced on (10-06 l / m). When the
# canonical moves, these stay on hilda33p: the pricing outputs they read are hilda33p's.
# =====================================================================
skip_if_no_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
IC_MODE        <- "hilda33p"
IC_LABEL       <- "hilda_csl3v0kaidgbemw"
IC_PARENT      <- "hilda_csl3v0kaidgbem"
IC_FIELDS      <- c("iav_cut", "gcb_land_lowpass_df", "gcb_enso_slope_row")
IC_PREVIEW_RDS <- ccx_path("outputs", "diagnostics", "iav_cut_preview_20261006_hilda33p.rds")         # @54d85e5
IC_PRICE_RDS   <- ccx_path("outputs", "diagnostics", "iav_cut_smoothed_land_20261006_hilda33p.rds")   # @565aa92
IC_MODE_MD5    <- "525404989a20ece51ec8bd088c7d4638"     # the file both previews read (their provenance)
ic_obs <- ccx_prepare_obs()

ic_md <- local({ cache <- NULL; function() {
  if (is.null(cache)) {
    f <- ccx_mode_file(IC_MODE)
    if (!identical(unname(tools::md5sum(f)), IC_MODE_MD5)) stop("the fixture is not the file the previews read")
    cache <<- readRDS(f)
  }
  cache } })
ic_pins <- function(md) { p <- stats::setNames(as.numeric(md$pins), names(md$pins)); p }
#' hilda33p's vector scored under `struct`, with `pins` applied in-process (and written onto the base,
#' the convention every caller follows). Gate and pins are undone on exit, pins FIRST.
ic_eval <- function(struct, pins) {
  md <- ic_md()
  g <- ccx_apply_gate(struct); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);   on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  v  <- lp(ccx_par_to_unc(ccx_mode_par_with_pins(md)))
  list(logpost = as.numeric(v), lik = attr(v, "loglik"), streams = unlist(attr(v, "streams")))
}
ic_own <- local({ cache <- NULL; function() {
  if (is.null(cache)) cache <<- ic_eval(ccx_mode_struct(ic_md()), ic_pins(ic_md())); cache } })
ic_pins17 <- function(md = ic_md()) c(ic_pins(md), unlist(md$par_mode[CCX_IAV_MODULE_NAMES]))
ic_run <- local({ cache <- NULL; function() {
  if (is.null(cache)) { v <- dg_vector(IC_MODE); cache <<- list(v = v, r = dg_run(v)) }
  cache } })

test_that("IC1 THE LABEL: kaidgbem's block plus exactly the three cut fields; kaidgbem's gates; the ruled df", {
  expect_true(IC_LABEL %in% CCX_STRUCT_LABELS)
  b_w <- ccx_struct_block(IC_LABEL); b_m <- ccx_struct_block(IC_PARENT)
  expect_identical(setdiff(names(b_w), names(b_m)), IC_FIELDS)
  expect_identical(b_w[names(b_m)], b_m)                                    # nothing else differs
  expect_identical(b_w$iav_cut, 1L)
  expect_identical(b_w$gcb_land_lowpass_df, LIK_LAND_LOWPASS_DF)
  expect_identical(b_w$gcb_enso_slope_row, 0L)
  expect_identical(LIK_LAND_LOWPASS_DF, 6L)                                 # RULED: the df priced 10-06 (m)
  expect_identical(ccx_gates_open(IC_LABEL), ccx_gates_open(IC_PARENT))     # the cut opens no gate
  # the ledger: the labels that CARRY the cut's three fields. Extending it is a DELIBERATE edit.
  # + the redesigned cut (2026-10-07, objective #18; Marcus: "Full redesign (Recommended)", the name
  #   "hilda_csl3v0kaidgbemwt (Recommended)"): #17's block + two fields, so the three at #17's values
  # 2026-10-22: + hilda_csl3v0kaidgbemwtcf, the flask label (...wtc's model and blocks, plus a likelihood switch)
  IC_CUT_LABELS <- c(IC_LABEL, "hilda_csl3v0kaidgbemwt",
                     "hilda_csl3v0kaidgbemwtc", "hilda_csl3v0kaidgbemwtcf")  # + the citation batch (2026-10-12; Marcus: "New label (a) (Recommended)", the name "…wtc (c = cited)")
  for (lab in setdiff(IC_CUT_LABELS, IC_LABEL))                             # the cut's own three, unchanged
    expect_identical(ccx_struct_block(lab)[IC_FIELDS], b_w[IC_FIELDS], info = lab)
  for (lab in setdiff(CCX_STRUCT_LABELS, IC_CUT_LABELS))                    # every other label: none of the three
    expect_false(any(IC_FIELDS %in% names(ccx_struct_block(lab))), info = lab)
  expect_identical(CCX_IAV_MODULE_NAMES, c("lag_enso_land", "gamma_enso_land_NH", "gamma_enso_land_SH", "w_enso_l2"))
  p <- ccx_apply_structure(ccx_default_params(), IC_LABEL, seas_ml = "1")
  expect_identical(attr(p, "struct"), IC_LABEL)
  expect_true(ccx_mix_on(p))                                                # it inherits #16's feedback
})

test_that("IC2 THE PROJECTOR: orthogonal, idempotent, keeps the intercept; the split is EXACT; MUTATION: oblique splits inexactly", {
  yr <- 1959:2024; n <- length(yr); P <- ccx_lowpass_projector(yr, LIK_LAND_LOWPASS_DF)
  expect_equal(P, t(P), tolerance = 1e-12)
  expect_equal(P %*% P, P, tolerance = 1e-10)
  expect_equal(as.numeric(P %*% rep(1, n)), rep(1, n), tolerance = 1e-12)  # a level shift is all low-pass
  expect_equal(sum(diag(P)), LIK_LAND_LOWPASS_DF + 1, tolerance = 1e-10)   # rank = the spline + the intercept
  e <- sin(seq_len(n)) + (seq_len(n) %% 7 - 3) / 3
  lo <- as.numeric(P %*% e); hi <- e - lo
  expect_equal(sum(e^2), sum(lo^2) + sum(hi^2), tolerance = 1e-13)
  s <- 0.5
  expect_equal(ccx_land_highpass_cost(e, yr, 6L, s), sum(hi^2) / (2 * s^2), tolerance = 1e-14)
  expect_lt(ccx_land_highpass_cost(lo, yr, 6L, s), 1e-20)                  # a smooth residual costs nothing
  expect_gt(ccx_land_highpass_cost(e, yr, 6L, s), 1)
  # MUTATION: an OBLIQUE projector (idempotent, not symmetric) does not split the row exactly -- the
  # exactness gate above has power. ⚠ The perturbation must leave span(X): a first version added a LINEAR
  # trend, which the natural spline already spans, so the "oblique" projector was the orthogonal one and
  # the mutation passed (caught on its first run). A high-frequency cosine is outside the spline space.
  X <- stats::model.matrix(~ splines::ns(yr, df = 6L)); Z <- X; Z[, 2] <- Z[, 2] + 0.3 * cos(2.5 * seq_len(n))
  Po <- X %*% solve(t(Z) %*% X, t(Z))
  expect_equal(Po %*% Po, Po, tolerance = 1e-8)
  lo_o <- as.numeric(Po %*% e)
  expect_gt(abs(sum(e^2) - sum(lo_o^2) - sum((e - lo_o)^2)), 1e-3)
  # the df is one whole number in [1, n - 2]
  for (bad in list(0, 1.5, n - 1, NA_real_, c(4, 6))) expect_error(ccx_lowpass_projector(yr, bad), "df")
  expect_error(ccx_land_highpass_cost(e[-1], yr, 6L, s), "one residual per year")
})

test_that("IC3 THE SWITCHES: absent = err untouched; the label's block sets both; junk refused", {
  err0 <- list(sigma_d14c = 1.5, rep_dC = 0.2, grad_off_co2 = 0, grad_off_d13c = 0)
  expect_identical(ccx_err_with_struct(err0, ccx_default_params()), err0)
  expect_identical(ccx_err_with_struct(err0, ccx_apply_structure(ccx_default_params(), IC_PARENT, seas_ml = "1")), err0)
  e2 <- ccx_err_with_struct(err0, ccx_apply_structure(ccx_default_params(), IC_LABEL, seas_ml = "1"))
  expect_identical(e2[names(err0)], err0)
  expect_identical(e2$gcb_land_lowpass_df, 6L); expect_identical(e2$gcb_enso_slope_row, 0L)
  expect_true(ccx_enso_slope_row_on(err0)); expect_false(ccx_enso_slope_row_on(e2))
  expect_true(ccx_enso_slope_row_on(list(gcb_enso_slope_row = 1L)))
  for (bad in list(2, -1, NA_real_, c(0, 1))) expect_error(ccx_enso_slope_row_on(list(gcb_enso_slope_row = bad)), "0 or 1")
})

test_that("IC4 ABSENT = BIT-IDENTICAL: hilda33p reproduces its stored logpost and streams exactly under its own label", {
  md <- ic_md(); own <- ic_own()
  expect_identical(ccx_mode_struct(md), IC_PARENT)
  expect_identical(own$logpost, md$logpost)
  st <- unlist(md$streams)
  expect_identical(sort(names(own$streams)), sort(names(st)))
  expect_identical(own$streams[names(st)], st)
  expect_true("gcb_ocean_enso_slope" %in% names(own$streams))
})

test_that("IC5 ON: the land row IS the pricing preview's low-pass row; the slope row leaves; the other rows bit-identical", {
  own <- ic_own(); on <- ic_eval(IC_LABEL, ic_pins17())
  pr <- readRDS(IC_PRICE_RDS)                                              # $gate: raw row, objective row, high part
  expect_identical(pr$provenance$mode_md5, IC_MODE_MD5)
  expect_identical(pr$provenance$lp_df, LIK_LAND_LOWPASS_DF)
  expect_equal(own$streams[["gcb_land_sink"]], pr$gate[["objective_row"]], tolerance = 1e-13)
  expect_equal(on$streams[["gcb_land_sink"]], pr$gate[["objective_row"]] - pr$gate[["high_part"]], tolerance = 1e-10)
  expect_equal(on$streams[["gcb_land_sink"]] - own$streams[["gcb_land_sink"]], -pr$gate[["high_part"]], tolerance = 1e-10)
  expect_false("gcb_ocean_enso_slope" %in% names(on$streams))
  expect_identical(sort(names(on$streams)), sort(setdiff(names(own$streams), "gcb_ocean_enso_slope")))
  com <- setdiff(names(on$streams), "gcb_land_sink")
  expect_identical(on$streams[com], own$streams[com])                       # the module pinned at its own values
  expect_equal(on$lik, sum(on$streams), tolerance = 1e-13)
  # THE dg_streams PATH (calibration/lib_design_gates.R) reads the switches off the model list: the same run,
  # scored as a #17 vector, gives the same rows
  R <- ic_run(); v17 <- R$v
  for (f in IC_FIELDS) v17$p[[f]] <- ccx_struct_block(IC_LABEL)[[f]]
  s17 <- unlist(dg_streams(R$r, v17, obs = ic_obs)); s16 <- unlist(dg_streams(R$r, R$v, obs = ic_obs))
  expect_equal(s17[["gcb_land_sink"]], on$streams[["gcb_land_sink"]], tolerance = 1e-9)
  expect_false("gcb_ocean_enso_slope" %in% names(s17))
  expect_true("gcb_ocean_enso_slope" %in% names(s16))
  # MUTATION: the switches stripped from the model list -> #16's rows come back
  v_m <- v17; for (f in IC_FIELDS) v_m$p[[f]] <- NULL
  expect_identical(unlist(dg_streams(R$r, v_m, obs = ic_obs)), s16)
})

test_that("IC6 THE GUARD: under the cut the module's four names must ALL be pinned", {
  md <- ic_md()
  build <- function(pins) {
    g <- ccx_apply_gate(IC_LABEL); on.exit(ccx_unapply_gate(g), add = TRUE)
    r <- ccx_apply_pins(pins);     on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
    bp <- ccx_apply_structure(ccx_default_params(), IC_LABEL, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
    for (n in names(pins)) bp[[n]] <- pins[[n]]
    bp$pump_mode <- md$pump_mode
    ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  }
  expect_error(build(ic_pins(md)), "INTERANNUAL CUT.*FITTED here")         # the module free
  p17 <- ic_pins17(md)
  for (n in CCX_IAV_MODULE_NAMES)                                          # any ONE left free
    expect_error(build(p17[setdiff(names(p17), n)]), "INTERANNUAL CUT", info = n)
  expect_true(is.function(build(p17)))                                     # all four pinned: it builds
})

test_that("IC7 A PINNED ENSO AMPLITUDE IS READ (the 2026-10-06 fix): pinned at its own value = free; pinned at 0 moves", {
  md <- ic_md(); own <- ic_own(); lab <- ccx_mode_struct(md)
  land <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
  at_own <- ic_eval(lab, c(ic_pins(md), unlist(md$par_mode[land])))
  expect_identical(at_own$streams, own$streams)                            # the same model, bit for bit
  at_0 <- ic_eval(lab, c(ic_pins(md), stats::setNames(c(0, 0), land)))
  # MUTATION: before the fix the pin was overwritten with CCX_GAMMA_ENSO_DEFAULT (0), so these two were EQUAL
  expect_gt(abs(at_0$lik - own$lik), 1)
  expect_false(isTRUE(all.equal(at_0$streams, at_own$streams)))
})

test_that("IC8 THE DATA: the monthly product reproduces its estimator; its checksum is the manifest's", {
  pr <- ccx_iav_growth_obs(); m <- pr$monthly
  expect_identical(m$g, ccx_cen12(m$co2))
  expect_identical(m$k, m$year * 12L + m$month)
  expect_true(all(diff(m$k) == 1L))
  man <- utils::read.csv(ccx_path("data-raw", "downloads", "MANIFEST.csv"), stringsAsFactors = FALSE)
  expect_identical(pr$provenance$manifest, "mbl_zonal_gl")
  expect_identical(pr$provenance$sha256, man$sha256[man$key == "mbl_zonal_gl"])
  # the RAW file's own sha256 is IC8b, which skips when the download is absent (Marcus 2026-10-14)
  # the window is covered, with g defined over every month of it
  w <- m[m$year >= LIK_IAV_WIN[1] & m$year <= LIK_IAV_WIN[2], ]
  expect_identical(nrow(w), 12L * (LIK_IAV_WIN[2] - LIK_IAV_WIN[1] + 1L)); expect_true(all(is.finite(w$g)))
  # ccx_cen12 is CENTERED: x[t + 6] - x[t - 6]; NA within six months of either end
  x <- (1:30)^2; g <- ccx_cen12(x)
  expect_identical(g[7], x[13] - x[1]); expect_identical(g[24], x[30] - x[18])
  expect_true(all(is.na(g[c(1:6, 25:30)]))); expect_true(all(is.finite(g[7:24])))
  expect_identical(ccx_cen12(1:12), rep(NA_real_, 12))
})

test_that("IC8b THE RAW FILE: the download's sha256 is the one the product records", {
  # Split out of IC8 so ONLY this expectation skips in a tree without data-raw/downloads
  # (a frozen worktree, a bundle); the four sibling provenance tests skip the same way.
  raw <- ccx_path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
  skip_if_not(file.exists(raw), "NOAA MBL zonal CO2 download not present")
  expect_identical(unname(tools::sha256sum(raw)), ccx_iav_growth_obs()$provenance$sha256)
})

test_that(sprintf(paste("IC9 THE ESTIMATOR at the fixture %s (where LIK_IAV_NEFF was measured and is held): the preview's",
                        "series, SSR, r and n_eff reproduce; the slope row is the main objective's"), IC_MODE), {
  R <- ic_run(); pv <- readRDS(IC_PREVIEW_RDS)
  expect_identical(pv$provenance$mode_md5, IC_MODE_MD5)
  expect_identical(pv$provenance$window, LIK_IAV_WIN); expect_identical(pv$provenance$trend_df, LIK_IAV_TREND_DF)
  gp <- ccx_iav_growth_pair(R$r$out, R$r$F)
  expect_equal(as.numeric(gp$k), as.numeric(pv$series$k))
  expect_equal(gp$obs, pv$series$obs, tolerance = 1e-12)
  expect_equal(gp$mod, pv$series$canonical, tolerance = 1e-12)
  ssr <- sum((gp$mod - gp$obs)^2)
  expect_equal(ssr, pv$canonical[["ssr_m"]], tolerance = 1e-12)
  # n_eff: Bretherton et al. 1999 eq. 31, recomputed from the series, IS the constant
  r1 <- function(x) stats::acf(x, lag.max = 1, plot = FALSE)$acf[2]
  ne <- length(gp$mod) * (1 - r1(gp$mod) * r1(gp$obs)) / (1 + r1(gp$mod) * r1(gp$obs))
  expect_equal(ne, LIK_IAV_NEFF, tolerance = 1e-12)
  expect_identical(LIK_IAV_NEFF, pv$n_eff[["m"]])
  ml <- ccx_iav_module_loglik(R$r$out, R$r$F, ic_obs, ssr_ref = ssr)
  expect_identical(ml[["growth"]], 0)                                     # at its own reference
  expect_equal(ml[["r"]], pv$canonical[["r_m"]], tolerance = 1e-12)
  expect_identical(ml[["n"]], 540)
  # THE ONE DEFINITION: the module's slope row is the main objective's row, bit for bit
  st <- unlist(dg_streams(R$r, R$v, obs = ic_obs))
  expect_identical(ml[["slope_row"]], st[["gcb_ocean_enso_slope"]])
  # ... and the STORED row (the objective's own run, 1750-2024) to the dg path's known reproduction level
  # (dg_run's 2025 extension, truncated, differs by <= 2.7e-10 on any row; 6e-12 on this one)
  expect_equal(ml[["slope_row"]], unlist(ic_md()$streams)[["gcb_ocean_enso_slope"]], tolerance = 1e-10)
  expect_identical(ml[["loglik"]], ml[["growth"]] + ml[["slope_row"]])
  # the growth term moves the right way: a worse fit (the land ENSO term doubled) scores lower
  v2 <- R$v; v2$p$gamma_enso_land_NH <- 2 * v2$p$gamma_enso_land_NH; v2$p$gamma_enso_land_SH <- 2 * v2$p$gamma_enso_land_SH
  r2 <- dg_run(v2)
  expect_lt(ccx_iav_module_loglik(r2$out, r2$F, ic_obs, ssr_ref = ssr)[["growth"]], 0)
})

test_that("IC10 REFUSALS: a run that stops at the record, ssr_ref <= 0, a slope row absent", {
  R <- ic_run(); k <- R$r$out$t < LIK_IAV_WIN[2] + 1
  expect_error(ccx_iav_growth_pair(R$r$out[k, ], R$r$F[k, ]), "matched months")
  expect_error(ccx_iav_growth_pair(R$r$out, R$r$F[-1, ]), "align")
  for (bad in list(0, -1, NA_real_, c(1, 2))) expect_error(ccx_iav_module_loglik(R$r$out, R$r$F, ic_obs, ssr_ref = bad), "ssr_ref")
  o2 <- ic_obs; o2$enso_slope <- NULL
  expect_error(ccx_iav_module_loglik(R$r$out, R$r$F, o2, ssr_ref = 1), "ABSENT")
})

test_that("IC11 A HAND-BUILT PINNED BASE (the 10-06 landing dry run): ccx_overlay_par() keeps the process's pins, not their absent defaults", {
  md <- ic_md()
  overlay_on <- function(label, pins) {          # promote_multistart_mode.R's OLD base: pins WRITTEN, no attribute
    g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
    r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
    bp <- ccx_apply_structure(ccx_default_params(), label, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
    for (n in names(pins)) bp[[n]] <- pins[[n]]
    pm <- md$par_mode[setdiff(names(md$par_mode), names(pins))]   # a start file's par_mode: the FITTED names only
    ccx_overlay_par(bp, pm)
  }
  for (case in list(list(ccx_mode_struct(md), ic_pins(md)), list(IC_LABEL, ic_pins17(md)))) {
    p <- overlay_on(case[[1]], case[[2]])
    for (n in intersect(names(case[[2]]), names(p))) expect_identical(p[[n]], case[[2]][[n]], info = paste(case[[1]], n))
  }
  # the hand-built path is the canonical path: hilda33p under its own ten pins, overlaid both ways, is the same model list
  p_hand <- overlay_on(ccx_mode_struct(md), ic_pins(md))
  p_can  <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_par_with_pins(md))
  expect_identical(unclass(p_hand)[sort(names(p_hand))], unclass(p_can)[sort(names(p_can))])
})
