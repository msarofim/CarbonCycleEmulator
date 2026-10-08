# =====================================================================
# test-ms-seed.R -- the dispersed multistart's SEEDED SLOTS (ids 3-5) seed only what the arm FITS, and no two starts
# of an array are one vector (CHANGELOG 2026-10-07 m; the driver half of Marcus's "Records now, driver later
# (Recommended)"; calibration/lib_ms_seed.R; memory pinned_name_seed_vanishes).
#   MS1 THE RULE, on the arms that ran (no model run): the FREE table seeds the ocean pair; objective #16 (the ocean pair
#       pinned, the limb on) seeds w_enso_l2 with HEAD's labels BYTE FOR BYTE; objective #18 (w_enso_l2 and the land pair
#       pinned too) makes all three slots UNSEEDABLE, naming every target. Partial and degenerate arms: the land pair
#       pinned under #16 (the obs slot seeds the limb only and SAYS so); a reference already at the seed's value; the
#       limb off.
#   MS2 THE REFUSAL: ms_assert_distinct_start() stops on an identical() start and names both ids; and THE BUG ITSELF,
#       rebuilt under #18 -- the pre-fix seed on w_enso_l2 encodes to the incumbent's vector bit for bit, and the refusal
#       catches it as id 3 = id 1.
#   MS3 THE WIRING (code lines): the driver sources the lib, seeds through ms_seed_slot(free = CCX_PARAM_NAMES), refuses a
#       duplicate right after ms_start(), and records start_class from the start; the collector keeps an unseedable slot
#       out of the benchmark. No seed decision reads names(MS_PINS).
# The DRIVER end to end (old vs new, both arms, ids 0-7, bit for bit) is outputs/diagnostics/ms_seed_fix_20261007/
# (start_harness.R, compare_grid.log); the mutations, its mutate.py and mutation.log.
# =====================================================================
source(ccx_path("calibration", "lib_ms_seed.R"))
MS_TEST_L2  <- ccx_eq_cell_obs()$w0_prior$interannual$per_index_sv
MS_TEST_OPT <- 0.10; MS_TEST_OBS <- 0.326; MS_TEST_LAND <- 1.734     # the driver's MS_ENSO_* constants
# HEAD's (3c0bfd8) labels under #16, read off the driver's own start records in compare_grid.log
MS_HEAD_KIND16 <- c(
  inc_enso = "seeded: INCUMBENT with the ocean ENSO pair PINNED; the limb's w_enso_l2 SET to 25 Sv per index (the HIGH edge of Meinen's bracket)",
  new_enso = "seeded: NEW BASIN with the ocean ENSO pair PINNED; the limb's w_enso_l2 SET to 14 Sv per index (the LOW edge of Meinen's bracket)",
  new_obs  = "seeded: NEW BASIN + the OBSERVATION-implied partition (the ocean ENSO pair PINNED; the limb's w_enso_l2 SET to 25 Sv per index (the HIGH edge of Meinen's bracket); land x1.734)")

# an arm as the driver builds it: the gate, then the pins, then the reference set and its two points
ms_arm_open <- function(struct, pins) {
  g <- ccx_apply_gate(struct); r <- ccx_apply_pins(pins)
  ref <- ccx_ms_reference_set(pins, "1", pump_field = "solved", struct = struct)
  pt <- function(nm) {
    p <- NULL
    utils::capture.output(p <- ccx_seed_unencodable(ccx_migrate_par_set(ccx_mode_par_with_pins(
      readRDS(ccx_path(CCX_MODE_FILES[[nm]])))), nm))
    p
  }
  list(gate = g, pins_h = r, pins = pins, P_INC = pt(ref$incumbent), P_NEW = pt(ref$new_basin),
       limb = ccx_l2_on(ccx_apply_structure(ccx_default_params(), struct, 1L, pump_field = "solved")))
}
ms_arm_close <- function(a) { ccx_unpin_params(a$pins_h); ccx_unapply_gate(a$gate) }
ms_slot <- function(sk, a, p = NULL, free = CCX_PARAM_NAMES)
  ms_seed_slot(sk, if (!is.null(p)) p else if (sk == "inc_enso") a$P_INC else a$P_NEW, free = free,
               pinned = names(a$pins), limb_on = a$limb, l2_edges = MS_TEST_L2,
               ocn_opt = MS_TEST_OPT, ocn_obs = MS_TEST_OBS, land_mult = MS_TEST_LAND)

test_that("MS1: the FREE table seeds the ocean pair (and the land pair for the obs slot)", {
  p <- ccx_unc_to_par(ccx_init_unc())
  a <- list(pins = numeric(0), limb = TRUE)
  s3 <- ms_slot("inc_enso", a, p); s4 <- ms_slot("new_enso", a, p); s5 <- ms_slot("new_obs", a, p)
  expect_true(s3$seeded && s4$seeded && s5$seeded)
  expect_identical(s3$landed, MS_ENSO_OCN_PAIR)
  expect_identical(s5$landed, c(MS_ENSO_OCN_PAIR, MS_ENSO_LAND_PAIR))
  expect_identical(s3$kind, "seeded: INCUMBENT with the ocean ENSO pair SET to +0.100 each (the 09-01 conditional optimum of the 08-31e basin; a perturbation here)")
  expect_identical(s5$kind, "seeded: NEW BASIN + the OBSERVATION-implied partition (the ocean ENSO pair SET to +0.326 each; land x1.734)")
  # the seed moves EXACTLY the names it lands, in the encoded vector
  u0 <- ccx_par_to_unc(p)
  expect_setequal(names(u0)[s5$u != u0], s5$landed)
  expect_equal(unname(ccx_unc_to_par(s5$u)$gamma_enso_land_NH), p$gamma_enso_land_NH * MS_TEST_LAND)
})

test_that("MS1: objective #16 (ocean pair pinned, limb on) seeds w_enso_l2 with HEAD's labels byte for byte", {
  a <- ms_arm_open(CCX_MODE_OBJ16_STRUCT, CCX_MODE_OBJ16_PINS); on.exit(ms_arm_close(a), add = TRUE)
  expect_true(a$limb)
  for (sk in MS_SEED_SLOTS) {
    s <- ms_slot(sk, a)
    expect_true(s$seeded, info = sk)
    expect_identical(s$kind, MS_HEAD_KIND16[[sk]], info = sk)
    expect_identical(s$landed, if (sk == "new_obs") c(MS_ENSO_L2_NAME, MS_ENSO_LAND_PAIR) else MS_ENSO_L2_NAME, info = sk)
    expect_identical(s$dropped, character(0), info = sk)
  }
  # (equal, not identical: w_enso_l2 round-trips through a logit)
  expect_equal(ccx_unc_to_par(ms_slot("inc_enso", a)$u)$w_enso_l2, max(MS_TEST_L2))
  expect_equal(ccx_unc_to_par(ms_slot("new_enso", a)$u)$w_enso_l2, min(MS_TEST_L2))
})

test_that("MS1: objective #18 (w_enso_l2 and the land pair pinned too) makes ALL THREE slots UNSEEDABLE, by name", {
  a <- ms_arm_open(CCX_MODE_OBJ18_STRUCT, CCX_MODE_OBJ18_PINS); on.exit(ms_arm_close(a), add = TRUE)
  expect_false(MS_ENSO_L2_NAME %in% CCX_PARAM_NAMES)
  for (sk in MS_SEED_SLOTS) {
    s <- ms_slot(sk, a)
    expect_false(s$seeded, info = sk); expect_null(s$u); expect_identical(s$kind, NA_character_)
    expect_identical(s$dropped, c(MS_ENSO_OCN_PAIR, MS_ENSO_L2_NAME, if (sk == "new_obs") MS_ENSO_LAND_PAIR), info = sk)
    expect_match(s$why, "the ENSO seed: gamma_enso_ocn_NH, gamma_enso_ocn_SH, w_enso_l2 not fitted by this arm", fixed = TRUE)
  }
  expect_match(ms_slot("new_obs", a)$why, "the land seed: gamma_enso_land_NH, gamma_enso_land_SH not fitted by this arm", fixed = TRUE)
  k <- ms_unseedable_kind("inc_enso", ms_slot("inc_enso", a), "dispersed about the COLD init, sd 1.0452")
  expect_match(k, "^UNSEEDABLE seeded slot 'inc_enso' \\(the INCUMBENT \\+ the ENSO seed\\): ")
  expect_match(k, "runs a DISPERSED DRAW instead: dispersed about the COLD init, sd 1.0452$")
})

test_that("MS1: a PARTIAL seed says what it dropped; a reference already at the seed, and the limb off, are unseedable", {
  # #16 + the land pair pinned: the obs slot seeds the limb and drops the land, and the label says which
  a <- ms_arm_open(CCX_MODE_OBJ16_STRUCT, CCX_MODE_OBJ16_PINS); on.exit(ms_arm_close(a), add = TRUE)
  s <- ms_slot("new_obs", a, free = setdiff(CCX_PARAM_NAMES, MS_ENSO_LAND_PAIR))
  expect_true(s$seeded); expect_identical(s$landed, MS_ENSO_L2_NAME); expect_identical(s$dropped, MS_ENSO_LAND_PAIR)
  expect_match(s$kind, "; the land seed NOT applied (gamma_enso_land_NH, gamma_enso_land_SH not fitted by this arm))", fixed = TRUE)
  # the incumbent already AT the high edge: the encoder sees nothing move
  p <- a$P_INC; p$w_enso_l2 <- max(MS_TEST_L2)
  s <- ms_slot("inc_enso", a, p = p)
  expect_false(s$seeded)
  expect_match(s$why, "w_enso_l2 already at the seed's value at the reference", fixed = TRUE)
  # the limb off and the ocean pair not fitted: nothing to seed, and the reason says the limb
  a2 <- a; a2$limb <- FALSE
  s <- ms_slot("new_enso", a2)
  expect_false(s$seeded)
  expect_match(s$why, "gamma_enso_ocn_NH, gamma_enso_ocn_SH not fitted by this arm; the limb is off", fixed = TRUE)
})

test_that("MS2: the refusal stops on an identical() start, names both ids, and skips NULL slots and itself", {
  u <- c(a = 1, b = 2); v <- c(a = 1, b = 2 + 2^-40)
  expect_true(ms_assert_distinct_start(3L, u, list(`0` = v, `1` = NULL, `3` = u)))
  expect_error(ms_assert_distinct_start(3L, u, list(`0` = v, `1` = unname(u))),
               "DUPLICATE START: id 3's start vector is identical() to id 1's", fixed = TRUE)
  expect_error(ms_assert_distinct_start(3L, u, list(v)), "NAMED by start id")
})

test_that("MS2: THE BUG, rebuilt under #18 -- the pre-fix seed encodes to the incumbent bit for bit, and is refused", {
  a <- ms_arm_open(CCX_MODE_OBJ18_STRUCT, CCX_MODE_OBJ18_PINS); on.exit(ms_arm_close(a), add = TRUE)
  U_INC <- ccx_par_to_unc(a$P_INC); U_NEW <- ccx_par_to_unc(a$P_NEW)
  old3 <- a$P_INC; old3$w_enso_l2 <- max(MS_TEST_L2)            # HEAD's ms_seed_ocn(): pair pinned + limb on
  old5 <- a$P_NEW; old5$w_enso_l2 <- max(MS_TEST_L2)
  old5$gamma_enso_land_NH <- old5$gamma_enso_land_NH * MS_TEST_LAND; old5$gamma_enso_land_SH <- old5$gamma_enso_land_SH * MS_TEST_LAND
  expect_identical(ccx_par_to_unc(old3), U_INC)                  # the seed VANISHED at the encoder
  expect_identical(ccx_par_to_unc(old5), U_NEW)
  fixed <- list(`0` = ccx_init_unc(), `1` = U_INC, `2` = U_NEW)
  expect_error(ms_assert_distinct_start(3L, ccx_par_to_unc(old3), fixed), "id 3's start vector is identical() to id 1's", fixed = TRUE)
  expect_error(ms_assert_distinct_start(5L, ccx_par_to_unc(old5), fixed), "id 5's start vector is identical() to id 2's", fixed = TRUE)
})

test_that("MS3: the driver and the collector are wired to the rule, and no seed decision reads the pins", {
  drv <- ccx_code_lines(readLines(ccx_path("calibration", "run_dispersed_multistart.R")))
  expect_true(any(grepl('source(ccx_path("calibration", "lib_ms_seed.R"))', drv, fixed = TRUE)))
  expect_true(any(grepl("ms_seed_slot(sk,", drv, fixed = TRUE)))
  expect_true(any(grepl("free = CCX_PARAM_NAMES", drv, fixed = TRUE)))
  expect_false(any(grepl("%in% names(MS_PINS)", drv, fixed = TRUE)), info = "the 09-17 list-of-pinned-cases test")
  i <- which(drv == "st <- ms_start(MS_ID)")
  expect_length(i, 1L)
  nxt <- drv[(i + 1L):length(drv)]; nxt <- nxt[nzchar(trimws(nxt))][1]
  expect_match(nxt, "^ms_assert_distinct_start\\(MS_ID, st\\$u, ")
  expect_true(any(grepl("start_class = st$class,", drv, fixed = TRUE)))
  expect_false(any(grepl("MS_ID %in% MS_SEED_IDS", drv, fixed = TRUE)), info = "the class comes from the start, not the id")
  co <- ccx_code_lines(readLines(ccx_path("calibration", "collect_dispersed_multistart.R")))
  expect_true(any(grepl("kB <- which(ids %in% CO_BENCH_IDS & !co_drawn)", co, fixed = TRUE)))
  expect_true(any(grepl("UNSEEDABLE under this arm (id %d ran a dispersed draw)", co, fixed = TRUE)))
})
