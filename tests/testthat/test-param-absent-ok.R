# =====================================================================
# CCX_PARAM_ABSENT_OK (2026-09-13i): a REGISTERED mode file may lack exactly the
# names that entered the table after it was fitted and whose mechanism is absent
# under its own structure -- today the equatorial cell's w_eq / gamma_eq. What
# this file guards, with mutations: the tolerance is by NAME and ORDER, not by
# count; a file missing anything else is REFUSED; the seeded start's logpost
# shift is the prior leg at the seed and nothing more; and once no registered
# file lacks the pair the set must be EMPTIED (a live assertion, not a comment).
# =====================================================================

test_that("carries-build tolerates the listed names ONLY, order preserved, and refuses anything else", {
  md <- readRDS(ccx_mode_file())
  expect_true(ccx_mode_carries_build(md))
  expect_true(all(ccx_mode_absent(md) %in% CCX_PARAM_ABSENT_OK))
  # a file that CARRIES the pair is this build's set outright
  full <- md; full$param_names <- setdiff(CCX_PARAM_NAMES, names(md$pins))
  expect_true(ccx_mode_carries_build(full)); expect_length(ccx_mode_absent(full), 0L)
  # MUTATIONS: drop a name that is NOT tolerated; scramble the order; add a retired name
  m1 <- md; m1$param_names <- setdiff(md$param_names, "h_ml")
  expect_false(ccx_mode_carries_build(m1))
  m2 <- md; m2$param_names <- rev(md$param_names)
  expect_false(ccx_mode_carries_build(m2))
  m3 <- md; m3$param_names <- c(md$param_names, "rho")
  expect_false(ccx_mode_carries_build(m3))
  expect_error(ccx_mode_start(m1), "different parameter set")
  # every registered file passes, and every one's absent set is inside the list
  for (a in names(CCX_MODE_FILES)) {
    m <- readRDS(ccx_mode_file(a))
    expect_true(ccx_mode_carries_build(m), info = a)
    expect_true(all(ccx_mode_absent(m) %in% CCX_PARAM_ABSENT_OK), info = a)
  }
})

test_that("the list is LIVE: every listed name is absent from at least one registered file and has a migration contract", {
  # the day no registered file lacks a listed name, this fails and the name comes off the list
  for (n in CCX_PARAM_ABSENT_OK) {
    expect_true(n %in% CCX_PARAM_NAMES, info = n)
    lacking <- vapply(names(CCX_MODE_FILES), function(a) !(n %in% readRDS(ccx_mode_file(a))$param_names), logical(1))
    expect_true(any(lacking), info = paste(n, "is on CCX_PARAM_ABSENT_OK but every registered file carries it: retire the entry"))
    p <- ccx_unc_to_par(ccx_init_unc()); p[[n]] <- NULL
    expect_true(n %in% attr(ccx_migrate_par_set(p), "migrated"), info = n)
  }
})

test_that("ccx_mode_start: migrated (what it ran), seeded, encoded; the shift is the prior leg at the seed", {
  md <- readRDS(ccx_mode_file())
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  out <- capture.output(st <- ccx_mode_start(md, "test"))
  expect_true(any(grepl("SEEDING", out)))
  expect_setequal(st$absent, c("w_eq", "gamma_eq", "pump_export", "w_vent", "gamma_vent", "w_thc"))   # + O1 arm THC (2026-09-15 d)   # + option D+E's three (2026-09-14 h)
  expect_length(st$u, length(CCX_PARAM_NAMES)); expect_true(all(is.finite(st$u)))
  for (n in st$absent) expect_equal(st$p[[n]], CCX_PARAM_TABLE[[n]]$init)
  hand <- sum(vapply(st$absent, function(n) { s <- CCX_PARAM_TABLE[[n]]
    s$prior(s$init) + .log_jac(.to_unc(s$init, s), s) }, numeric(1)))
  # 2026-09-16 b: the shift also carries the BAND TERM (the file's recorded h_ml band vs the live
  # table's, test-hml-floor.R); the seeding leg is what is asserted here.
  expect_equal(st$logpost_shift - st$band_shift, hand, tolerance = 1e-12)
  expect_lt(st$logpost_shift - st$band_shift, 0)       # -0.8236 on 09-13i: a price, never a credit
  # the file's OWN coordinates are untouched by the start
  for (n in setdiff(md$param_names, st$absent)) expect_identical(st$p[[n]], md$par_mode[[n]])
  # ccx_load_mode() RUNS the file (0 = no loop), it does not seed: the loaded
  # vector is the file's own structure (ccx_mode_base) plus the file's own values
  ccx_unpin_params(rm); rm <- list()
  L <- ccx_load_mode()
  expect_identical(L$p$w_eq, 0); expect_identical(L$p$gamma_eq, 0); expect_false(ccx_eq_on(L$p))
  b <- ccx_mode_base(md)
  expect_identical(L$p$hs_frac, b$hs_frac); expect_identical(L$p$eq_frac_NH, b$eq_frac_NH)
  for (n in intersect(md$param_names, names(L$p))) expect_identical(L$p[[n]], md$par_mode[[n]])   # the error-model names ride in L$err
  expect_identical(L$err$sigma_d14c, md$par_mode$sigma_d14c)
})
