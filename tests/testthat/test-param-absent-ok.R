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
  # 2026-09-17 (h): the canonical (hilda30h) PINS the six inert names, so nothing is absent there and
  # ccx_mode_start() has nothing to seed. The property under test -- a registered file that LACKS
  # names is migrated, seeded at the table init, and shifted by exactly their prior leg -- is read
  # at the registered FREE PARENT (hilda31s2, a hilda file that lacks all six).
  # 2026-09-22 (k): the free parent is now hilda32f, a CURRENT-build file that lacks nothing -- the
  # property needs a file WITH absent names, so the fixture is hilda31s2 BY NAME (still registered,
  # as provenance). A test that reads "the free parent" for its migration behaviour breaks the day
  # the parent is refit; a fixture named for what it IS (an old-build file) does not.
  md <- readRDS(ccx_mode_file("hilda31s2"))
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  out <- capture.output(st <- ccx_mode_start(md, "test"))
  expect_true(any(grepl("SEEDING", out)))
  expect_setequal(st$absent, c("w_eq", "gamma_eq", "pump_export", "w_vent", "gamma_vent", "w_thc", "w_enso_l2"))   # + O1 arm THC (2026-09-15 d)   # + option D+E's three (2026-09-14 h)
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
  # ccx_load_mode() loads the CANONICAL (hilda30h since 09-17 h), so the comparison below is against
  # ITS file, not the parent read above. At hilda30h w_eq / gamma_eq are PINNED at 27 / 1 in the
  # base -- INERT without the cell (measured: the logpost is bit-identical at 0/0 and at 60/3), so
  # the model must still be OFF; a canonical that lacks them instead runs the migration's 0.
  md_c <- readRDS(ccx_mode_file())
  expect_false(ccx_eq_on(L$p))
  if (is.null(md_c$pins[["w_eq"]])) { expect_identical(L$p$w_eq, 0); expect_identical(L$p$gamma_eq, 0) }
  md <- md_c; b <- ccx_mode_base(md)
  expect_identical(L$p$hs_frac, b$hs_frac); expect_identical(L$p$eq_frac_NH, b$eq_frac_NH)
  for (n in intersect(md$param_names, names(L$p))) expect_identical(L$p[[n]], md$par_mode[[n]])   # the error-model names ride in L$err
  expect_identical(L$err$sigma_d14c, md$par_mode$sigma_d14c)
})

test_that("f_luc_perm ABSENT resolves to CCX_F_LUC_PERM_DEFAULT in the R core, as in the C++ (09-16 c review, finding 2)", {
  skip_if_no_cpp()
  p <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = 1)
  sp <- suppressWarnings(ccx_spinup(p))
  F  <- ccx_build_forcing("historical", c(1990, 1992), prod_c14 = sp$prod_c14)   # cum_luc is large here
  fr <- ccx_forcing_at(F, 3L)
  q <- p; q$f_luc_perm <- NULL
  dR <- ccx_deriv(sp$y, F$t[3], q, fr, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, F$t[3], q, fr, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10)
  # and the absent read equals the explicit default -- never the 0.9 ceiling
  r <- p; r$f_luc_perm <- CCX_F_LUC_PERM_DEFAULT
  expect_identical(dR, ccx_deriv(sp$y, F$t[3], r, fr, sp$grid, sp$aux))
})

