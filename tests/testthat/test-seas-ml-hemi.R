# =====================================================================
# test-seas-ml-hemi.R -- the "hilda_cs" structure (2026-09-19 l): the seasonal mixed
# layer with its NH CYCLE FLAT (ml_nh_cycle = 0), ruling 1's test in its refit form.
#   (1) the label is registered and its block differs from hilda_c's by ml_nh_cycle only
#   (2) the flat shape: f = 1 and dfdt = 0 at every phase; the continuous extremes 1
#   (3) under hilda_cs / seas_ml 1 the aux's NH coefficients ARE the flat set and the
#       SH's are BIT-IDENTICAL to hilda_c's; under hilda_c both are the production shape
#   (4) INERT where it should be: at seas_ml 0 the hilda_cs and hilda_c runs are
#       bit-identical (nothing reads the flag with the ML off)
#   (5) the label REPRODUCES the session knock-out: the canonical's point under
#       hilda_cs scores what diag_seas_ml_hemisphere_split.R measured with
#       ccx_mld_shape() wrapped (canonical:NH_flat, 26 rows) -- so the diagnostic's
#       number is reproducible by LABEL, and the label does exactly the knock-out
#   (6) the substep bound is UNCHANGED by the flag (it reads the production extremes
#       deliberately: a substep change would move every trajectory)
# =====================================================================
for (f in list.files(ccx_path("R"), pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

SMH_KNOCKOUT_LOG <- ccx_path("outputs", "diagnostics", "seas_ml_hemisphere_split_20260919.rds")
SMH_PHASES <- (seq_len(48) - 0.5) / 48

test_that("(1) hilda_cs is registered and is hilda_c + ml_nh_cycle = 0, nothing else", {
  expect_true("hilda_cs" %in% CCX_STRUCT_LABELS)
  b0 <- ccx_struct_block("hilda_c"); b1 <- ccx_struct_block("hilda_cs")
  expect_identical(setdiff(names(b1), names(b0)), "ml_nh_cycle")
  expect_identical(b1$ml_nh_cycle, 0L)
  for (n in names(b0)) expect_identical(b1[[n]], b0[[n]], info = n)
  expect_identical(ccx_default_params()$ml_nh_cycle, 1L)      # every registered file: the NH cycle ON
  expect_error(ccx_apply_structure(ccx_default_params(), "hilda_csx"), "unknown structure label")
  # THE PARTIAL-MATCH TRAP (09-19 m): the flag was first named `seas_ml_nh`, and on a list with
  # `seas_ml` removed `p$seas_ml` partial-matched it and turned the mechanism ON. No parameter
  # name may extend `seas_ml` as a prefix; and a list WITHOUT seas_ml must read the ML as OFF.
  nm <- names(ccx_default_params())
  expect_false(any(nm != "seas_ml" & startsWith(nm, "seas_ml")))
  p_bare <- ccx_default_params(); p_bare$seas_drivers <- 1; p_bare$seas_ml <- NULL
  expect_true(is.null(p_bare$seas_ml)); expect_false(ccx_seas_ml_on(p_bare))
})

test_that("(2) the flat shape evaluates to f = 1, dfdt = 0 at every phase", {
  co <- ccx_mld_shape("ls")
  fl <- ccx_mld_flat(co$NH)
  f  <- vapply(SMH_PHASES, function(t) ccx_mld_eval(fl, t)$f, numeric(1))
  d  <- vapply(SMH_PHASES, function(t) ccx_mld_eval(fl, t)$dfdt, numeric(1))
  expect_true(all(abs(f - 1) < 1e-12)); expect_true(all(abs(d) < 1e-12))
  expect_identical(c(fl$f_min, fl$f_max, fl$a0), c(1, 1, 1))
  expect_identical(fl$k, co$NH$k)                              # the same harmonic set, zeroed -- the C++ packing sees the same lengths
  # the production shape is NOT flat (the test has power)
  expect_gt(co$NH$f_max, 1.5); expect_lt(co$NH$f_min, 0.7)
})

test_that("(3) under hilda_cs / seas_ml 1 the aux carries the flat NH and the production SH", {
  p1 <- ccx_apply_structure(ccx_default_params(), "hilda_cs", seas_ml = "1")
  p0 <- ccx_apply_structure(ccx_default_params(), "hilda_c",  seas_ml = "1")
  a1 <- ccx_prepare(p1); a0 <- ccx_prepare(p0)          # ccx_prepare() RETURNS the aux
  prod <- ccx_mld_shape("ls")
  expect_identical(a1$mld_coef$SH, a0$mld_coef$SH)
  expect_identical(a0$mld_coef$NH, prod$NH); expect_identical(a0$mld_coef$SH, prod$SH)
  expect_identical(a1$mld_coef$NH, ccx_mld_flat(prod$NH))
  expect_false(identical(a1$mld_coef$NH, a0$mld_coef$NH))
})

test_that("(4) at seas_ml 0 the flag is inert: hilda_cs and hilda_c runs are bit-identical", {
  run0 <- function(struct) { p <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = "0"); p$pump_mode <- "N"
    r <- dg_run(list(p = p, luc_scale = 1, bomb_total = DG_BOMB_REF, spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", src = struct)); r$out }
  o0 <- run0("hilda_c"); o1 <- run0("hilda_cs")
  expect_identical(o1$co2_NH, o0$co2_NH); expect_identical(o1$ocean_C, o0$ocean_C)
})

test_that("(5) the label reproduces the session knock-out at the canonical's point (26 rows)", {
  skip_if_not(file.exists(SMH_KNOCKOUT_LOG), "the 09-19 knock-out record is absent")
  ko <- readRDS(SMH_KNOCKOUT_LOG)
  target <- ko$tot[["canonical:NH_flat"]]; full <- ko$tot[["canonical:full"]]
  # 2026-09-20 (o): the canonical is now hilda30s, ITSELF on hilda_cs; the knock-out was measured at
  # hilda30e's point (hilda_c, both cycles), which is the quarantined file by path
  obs <- ccx_prepare_obs(); v <- dg_vector(ccx_path(CCX_MODE_HILDA30E_QUARANTINED))   # by ABSOLUTE path (testthat runs from tests/testthat)
  # hilda30e's OWN point, re-labelled hilda_cs: the same numbers, the NH cycle flat
  v$p <- ccx_apply_structure(v$p, "hilda_cs", seas_ml = "1", pump_field = ccx_mode_pump_field(v$md))
  v$p <- ccx_overlay_par(v$p, v$pm)                                   # the fitted values back over the re-labelled base (the lint-enforced idiom)
  for (n in names(ccx_mode_pins(v$md))) v$p[[n]] <- ccx_mode_pins(v$md)[[n]]
  st <- dg_streams(dg_run(v), v, obs = obs)
  got <- sum(st[ko$common])
  expect_equal(got, target, tolerance = 1e-6)
  expect_lt(got, full - 10)                                   # the knock-out costs, as measured: the test has power
})

test_that("(6) the substep bound reads the production extremes under either label", {
  p1 <- ccx_apply_structure(ccx_default_params(), "hilda_cs", seas_ml = "1")
  p0 <- ccx_apply_structure(ccx_default_params(), "hilda_c",  seas_ml = "1")
  expect_identical(ccx_substeps_for(p1), ccx_substeps_for(p0))
})
