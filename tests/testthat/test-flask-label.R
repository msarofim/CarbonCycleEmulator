# =====================================================================
# LABEL hilda_csl3v0kaidgbemwtcf (2026-10-22): every Mauna Loa CO2 row on Scripps FLASK CO2.
# Marcus: the fits should use "the most consistent source of data"; on the scope, after T8f, "All MLO
# CO2 rows (Recommended)"; the name "hilda_csl3v0kaidgbemwtcf (Recommended)". CHANGELOG 2026-10-22 (f), (g).
# What this file guards:
#   * ABSENT  = the in situ objective, bit for bit (the flask targets are additive in ccx_prepare_obs());
#   * PRESENT = the three MLO CO2 rows score flask by their own construction, and nothing else moves;
#   * the label reproduces T8f's override objective (calibration/lib_seas8_20261021.R, an independent
#     implementation) EXACTLY at three points: the canonical, T8c's block point, T8f's Newton point;
#   * the switch is LIVE (a power check), and ccx_comparable_rows() drops the three rows across it.
# =====================================================================
FL_LABEL <- "hilda_csl3v0kaidgbemwtcf"
FL_T8F   <- file.path(ccx_path(), "outputs", "diagnostics", "seas8_20261021_hilda31w",
                      "t8f_allflask_forecast_hilda31w.rds")
FL_REPRO_TOL <- 1e-8   # the label vs T8f's override: the same arithmetic, so a tolerance only for roundoff

test_that("THE LABEL: ...wtc's block plus exactly co2_mlo_flask = 1; no other label carries the field", {
  b <- ccx_struct_block(FL_LABEL); w <- ccx_struct_block("hilda_csl3v0kaidgbemwtc")
  expect_identical(setdiff(names(b), names(w)), "co2_mlo_flask")
  expect_identical(b[names(w)], w)
  expect_identical(b$co2_mlo_flask, 1)
  for (lab in setdiff(CCX_STRUCT_LABELS, FL_LABEL))
    expect_false("co2_mlo_flask" %in% names(ccx_struct_block(lab)), info = lab)
  # the switch reaches `err`, and only a 0 / 1 value is accepted
  expect_identical(ccx_err_with_struct(list(), b)$co2_mlo_flask, 1)
  expect_null(ccx_err_with_struct(list(), w)$co2_mlo_flask)
  expect_false(ccx_co2_flask_on(list())); expect_true(ccx_co2_flask_on(list(co2_mlo_flask = 1)))
  expect_error(ccx_co2_flask_on(list(co2_mlo_flask = 2)), "must be 0 or 1")
})

test_that("THE TARGETS: the flask ones are built like the in situ ones, from the flask rows; the in situ ones are untouched", {
  obs <- ccx_prepare_obs()
  co2 <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
  f <- co2[co2$station == LIK_CO2_FLASK_STATION, ]; i <- co2[co2$station == "MLO", ]
  s <- co2[co2$station == "SPO", ]
  expect_gt(nrow(f), 600L)
  hf <- ccx_year_harmonic(f$decimal_date, f$co2_ppm); hi <- ccx_year_harmonic(i$decimal_date, i$co2_ppm)
  hs <- ccx_year_harmonic(s$decimal_date, s$co2_ppm)
  expect_identical(obs$co2_ann_flask$MLO, hf)
  expect_identical(obs$co2_seas_flask$MLO, ccx_seasonal_target(hf))
  m <- merge(hf[, c("year", "level")], hs[, c("year", "level")], by = "year", suffixes = c("_n", "_s"))
  expect_identical(obs$co2_grad_flask, data.frame(year = m$year, grad = m$level_n - m$level_s))
  expect_identical(obs$co2_ann$MLO, hi)                                     # the in situ targets, as before
  expect_identical(sort(unique(obs$co2$station)), c("MLO", "SPO"))          # the monthly frame, as before
  expect_identical(obs$co2_flask, f)
  # the swap: off = the same object; on = exactly the three targets; monthly = the MLO rows replaced
  expect_identical(ccx_obs_co2_scored(obs, FALSE), obs)
  o1 <- ccx_obs_co2_scored(obs, TRUE)
  expect_identical(o1$co2_ann$MLO, hf); expect_identical(o1$co2_seas$MLO, obs$co2_seas_flask$MLO)
  expect_identical(o1$co2_grad, obs$co2_grad_flask)
  same <- setdiff(names(obs), c("co2_ann", "co2_seas", "co2_grad"))
  expect_identical(o1[same], obs[same])
  expect_identical(o1$co2_ann$SPO, obs$co2_ann$SPO); expect_identical(o1$co2_seas$SPO, obs$co2_seas$SPO)
  o2 <- ccx_obs_co2_scored(obs, TRUE, monthly = TRUE)
  expect_identical(o2$co2[o2$co2$station == "MLO", "co2_ppm"], f$co2_ppm)
  spo2 <- o2$co2[o2$co2$station == "SPO", ]; spo <- obs$co2[obs$co2$station == "SPO", ]
  rownames(spo2) <- rownames(spo) <- NULL
  expect_identical(spo2, spo)
  expect_error(ccx_obs_co2_scored(obs[setdiff(names(obs), "co2_grad_flask")], TRUE), "no flask targets")
})

test_that("COMPARABLE ROWS: the three MLO CO2 rows drop between arms that differ in the switch, and only those", {
  rows <- c("co2_level_MLO", "co2_level_SPO", "co2_seasonal_MLO", "co2_gradient", "d13c_seasonal_MLO")
  w <- "hilda_csl3v0kaidgbemwtc"
  expect_identical(ccx_comparable_rows(list(rows, rows), c(w, FL_LABEL)),
                   setdiff(rows, LIK_CO2_FLASK_ROWS))
  expect_identical(ccx_comparable_rows(list(rows, rows), c(FL_LABEL, FL_LABEL)), rows)
  expect_identical(ccx_comparable_rows(list(rows, rows), c(w, w)), rows)
})

# the canonical's vector, its pins live, and the objective under a given label (restores the pins)
fl_score <- function(label, at = NULL) {
  md <- readRDS(ccx_mode_file())
  rm_ <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_), add = TRUE)
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  if (!is.null(label)) bp <- ccx_apply_structure(bp, label, seas_ml = ccx_mode_seas_ml(md),
                                                 pump_field = ccx_mode_pump_field(md))
  st <- ccx_mode_start(md, "test-flask-label")
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
  u <- st$u; if (!is.null(at)) u[names(at)] <- at
  v <- lp(u)
  list(v = as.numeric(v), rows = c(unlist(attr(v, "streams")), logprior = attr(v, "logprior")), md = md, u = u)
}

test_that("REPRODUCTION: the label scores T8f's override objective exactly, at the canonical, T8c's point and T8f's Newton point", {
  skip_if_no_cpp()
  skip_if_not(file.exists(FL_T8F), "T8f's output is not in this checkout")
  T8F <- readRDS(FL_T8F)
  md <- readRDS(ccx_mode_file())
  expect_identical(T8F$provenance$mode_md5, unname(tools::md5sum(ccx_mode_file())))
  expect_identical(c(T8F$provenance$co2seas, T8F$provenance$co2level), rep(LIK_CO2_FLASK_STATION, 2))
  a0 <- fl_score(FL_LABEL)
  expect_identical(a0$u[names(T8F$points$u0)], T8F$points$u0)
  expect_equal(a0$v, sum(T8F$rows_canonical$all), tolerance = FL_REPRO_TOL, scale = 1)
  expect_equal(a0$rows[names(T8F$rows_canonical$all)], T8F$rows_canonical$all, tolerance = FL_REPRO_TOL, scale = 1)
  aB <- fl_score(FL_LABEL, at = T8F$points$uB)
  expect_equal(aB$v, T8F$forecast$block$base, tolerance = FL_REPRO_TOL, scale = 1)
  aN <- fl_score(FL_LABEL, at = T8F$points$uN_all)
  expect_equal(aN$v, sum(T8F$rows$all_at_allN), tolerance = FL_REPRO_TOL, scale = 1)
  # ABSENT = the in situ objective: the canonical's own label reproduces its stored logpost
  i0 <- fl_score(NULL)
  expect_equal(i0$v, md$logpost, tolerance = CCX_REPRO_TOL, scale = 1)
  # LIVE: the switch moves exactly the three rows, each by more than a log-unit at the canonical
  d <- a0$rows - i0$rows[names(a0$rows)]
  expect_identical(sort(names(d)[abs(d) > 0]), sort(LIK_CO2_FLASK_ROWS))
  expect_true(all(abs(d[LIK_CO2_FLASK_ROWS]) > 1))
})
