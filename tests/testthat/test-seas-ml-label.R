# =====================================================================
# `seas_ml` as the SECOND AXIS OF THE OBJECTIVE LABEL (2026-09-10).
#
# The 09-10 refit (17318015 + 17325832) was launched as the round-6 test and
# ran both rounds at seas_ml = 0: the switch is a BASE parameter, not a fitted
# name, so it is invisible to `u`, absent from `par_mode`, and silently took
# its default in a driver that built from ccx_default_params()
# ([[ccx_refit_ran_at_seas_ml_0]], [[default_off_hides_the_bug]]). The repair
# routes it through the same function as `struct`, so everything that builds a
# base list -- the driver, make_port_targets.R, the promoter, ccx_mode_base()
# -- carries it, and a mode file RECORDS it. What is asserted here:
#   (1) ccx_apply_structure() sets BOTH the model switch and the label, for
#       both structures, from an explicit value and from CCX_MS_SEAS_ML;
#   (2) it errors BY NAME on anything but 0/1 -- never coerces (1.5, "2", "");
#   (3) ccx_mode_base() honors a file's recorded seas_ml, and reads an
#       ABSENT field as 0 (a fact about every pre-09-10 file, not a default);
#   (4) the label reaches the OBJECTIVE: the same vector scores differently at
#       seas_ml 1 than at 0 (the mechanism is felt), and -Inf above the P8
#       guard, which is why the reference set matters for a seas_ml = 1 array.
# The driver's port gate and make_port_targets' non-finite refusal are
# script-level and were MUTATION-TESTED by hand on 2026-09-10 (unset var ->
# stop; old CSV without the column -> stop; seas_ml 1 run vs seas_ml 0 CSV ->
# stop; seas_ml 0 vs seas_ml 0 -> PORT GATE (a) PASSED; make_port_targets at
# seas_ml 1 -> refused at new_basin, CSV untouched).
# =====================================================================

test_that("ccx_apply_structure() carries seas_ml as switch AND label, under both structures", {
  for (st in c("", "hilda")) for (v in list(0, 1, "0", "1", 0L, 1L)) {
    p <- ccx_apply_structure(ccx_default_params(), st, seas_ml = v)
    expect_identical(p$seas_ml, as.integer(v))
    expect_identical(attr(p, "seas_ml"), as.integer(v))
    expect_identical(attr(p, "struct"), st)
  }
  # the default is the environment, exactly as `struct`'s is
  withr::with_envvar(c(CCX_MS_SEAS_ML = "1"), {
    expect_identical(attr(ccx_apply_structure(ccx_default_params(), "hilda"), "seas_ml"), 1L)
  })
  withr::with_envvar(c(CCX_MS_SEAS_ML = NA), {
    expect_identical(attr(ccx_apply_structure(ccx_default_params(), "hilda"), "seas_ml"), 0L)
  })
})

test_that("seas_ml errors by name on anything but 0/1 -- never a coercion", {
  for (bad in list(2, "2", 1.5, "1.5", "", NA, c(0, 1), "on", TRUE))
    expect_error(ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = bad),
                 "seas_ml.*must be 0 .OFF. or 1 .ON.")
  withr::with_envvar(c(CCX_MS_SEAS_ML = "yes"),
    expect_error(ccx_apply_structure(ccx_default_params(), "hilda"), "CCX_MS_SEAS_ML"))
})

test_that("ccx_mode_base() honours a recorded seas_ml and reads an absent one as 0", {
  md0 <- list(struct = "hilda")                     # every pre-09-10 file
  md1 <- list(struct = "hilda", seas_ml = 1L)
  mdc <- list(seas_ml = 1)                          # column, numeric field
  expect_identical(ccx_mode_seas_ml(md0), 0L)
  expect_identical(ccx_mode_seas_ml(md1), 1L)
  expect_identical(ccx_mode_seas_ml(mdc), 1L)
  b0 <- ccx_mode_base(md0); b1 <- ccx_mode_base(md1); bc <- ccx_mode_base(mdc)
  expect_identical(b0$seas_ml, 0L); expect_identical(attr(b0, "seas_ml"), 0L)
  expect_identical(b1$seas_ml, 1L); expect_identical(attr(b1, "seas_ml"), 1L)
  expect_identical(attr(b1, "struct"), "hilda")
  expect_identical(bc$seas_ml, 1L); expect_identical(attr(bc, "struct"), "")
  # everything else in the hilda base is untouched by the switch
  b0$seas_ml <- NULL; b1$seas_ml <- NULL; attr(b1, "seas_ml") <- attr(b0, "seas_ml")
  expect_identical(b0, b1)
  # the mode files on disk record what they were fitted at: the canonical
  # `hilda31s` (09-11 (8)) at 1, the seas_ml = 0 CONTROL `hilda31p` at 0 (an
  # absent field, read as the 0 it was)
  md <- readRDS(ccx_mode_file())
  expect_identical(ccx_mode_seas_ml(md), 1L)
  expect_identical(ccx_mode_base(md)$seas_ml, 1L)
  # 2026-09-19 (m): the control is hilda31pe, which RECORDS seas_ml 0; the absent-field case
  # (read as the 0 it was) is the quarantined hilda31p, by path
  md0 <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL))
  expect_identical(md0$seas_ml, 0L); expect_identical(ccx_mode_seas_ml(md0), 0L)
  expect_identical(ccx_mode_base(md0)$seas_ml, 0L)
  md_old <- readRDS(ccx_path(CCX_MODE_HILDA31P_QUARANTINED))
  expect_null(md_old$seas_ml); expect_identical(ccx_mode_seas_ml(md_old), 0L)
  expect_error(ccx_mode_seas_ml(list(seas_ml = "2")), "must be 0")
})

test_that("the label reaches the objective: seas_ml = 1 is felt at the mode and is -Inf above the P8 guard", {
  skip_if_no_cpp()
  # the seas_ml = 0 CONTROL, by name: from 09-11 (8) the canonical is the ON arm,
  # and ON-vs-ON would feel nothing
  md <- readRDS(ccx_mode_file(CCX_MODE_SEASML0_CONTROL))
  b0 <- ccx_mode_base(md); b0$pump_mode <- md$pump_mode
  b1 <- b0; b1 <- ccx_apply_structure(b1, ccx_mode_struct(md), seas_ml = 1); b1$pump_mode <- md$pump_mode
  for (n in names(ccx_mode_pins(md))) b1[[n]] <- ccx_mode_pins(md)[[n]]   # apply_structure rebuilt the list; the held names go back
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)   # hilda31pe holds seven inert names (09-19 m)
  lp0 <- ccx_make_logpost(base_params = b0); lp1 <- ccx_make_logpost(base_params = b1)
  st <- ccx_mode_start(md, "seas-ml-label")   # migrated + seeded (the cell's pair, 09-13i); inert under "hilda"
  u <- st$u
  v0 <- lp0(u); v1 <- lp1(u)
  # ⚠ v0 is NOT asserted against md$logpost: a stored logpost is in the units of
  # the objective that produced it, and the file read here is `hilda31p` -- fitted
  # under the PERIODIC spinup, and restamped since as the objective moved (the
  # 09-11 (5) annual-mean read, the 09-12 rulings)
  # ([[compare_gaps_not_absolute_logposts]]). Reproduction is test-mode-file.R's
  # business.
  expect_true(is.finite(v0)); expect_true(is.finite(v1))
  expect_false(isTRUE(all.equal(v0, v1)))              # the mechanism is FELT
  # above the geometry guard the objective is -Inf: the 08-31e new-basin
  # reference (143.9 m) and the 09-10 second basin (164 m) are INFEASIBLE here
  pm <- st$p; pm$h_ml <- 143.9
  expect_identical(lp1(ccx_par_to_unc(pm)), -Inf)
  expect_true(is.finite(lp0(ccx_par_to_unc(pm))))
})
