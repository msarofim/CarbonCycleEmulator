# =====================================================================
# Gate: the integrator's explicit-diffusion stability limit is CONTROLLED,
# not discovered at runtime as a wall of NAs.
#
# Why this gate exists. Before 2026-08-11 the substep count was hard-coded at 4,
# which caps kz at ~155,000 m2/yr. The mode-finder walked straight into that cap
# (kz = 175,790, i.e. ~1 % from the boundary) and every caller's `anyNA` -> -Inf
# guard turned "the integrator diverged" into "this parameter has zero posterior
# probability". The posterior was being truncated by the solver.
#
# So there are two things to hold: (1) the criterion actually predicts where the
# old scheme broke -- otherwise we have fixed the wrong thing; and (2) with the
# criterion wired in, no parameter value in or beyond the prior's support
# produces NA. Test 4 is a MUTATION TEST of test 3: with the controller forced
# back to the old fixed 4, the same case MUST fail. Without it, test 3 could
# pass for the trivial reason that the case was never unstable.
# =====================================================================

# analytic kz at which a FIXED substep count goes unstable, from the same
# eigenvalue the controller uses (safety margin removed, so this is the edge)
kz_wall <- function(h_ml, substeps) {
  g <- ccx_ocean_grid(h_ml)
  lam1 <- ccx_diffusion_eigmax(1, g)              # eigenvalue is linear in kz
  CCX_RK4_STAB_LIMIT / ((1 / 12) / substeps * lam1)
}

run_at <- function(kz, h_ml = 75, substeps = "auto", retry_na = TRUE,
                   years = c(1900, 1960)) {
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); p$kz <- kz; p$h_ml <- h_ml
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", years, prod_c14 = sp$prod_c14)
  ccx_run_fast(sp, F, substeps = substeps, retry_na = retry_na)
}

# hs_* columns are NA BY CONTRACT with the HILDA boxes off (2026-09-07f); a
# blow-up is read off the PHYSICS columns, as ccx_run_fast()'s own guard does.
# ... and the eq_* columns likewise with the equatorial cell off (2026-09-13g).
ccx_phys <- function(out) out[, grep("^(hs|eq|tr)_", names(out), invert = TRUE, value = TRUE)]   # NA by contract when off (+ tr, 2026-09-14f)

test_that("the controller is a no-op at every ordinary parameter value", {
  # The whole point of flooring at CCX_SUBSTEPS_MIN: switching the default to
  # "auto" must not change a single existing result. kz has to clear ~155,000
  # (+6.2 sigma on its lnorm(log 4000, 0.6) prior) before the count moves.
  p <- ccx_default_params()
  expect_identical(ccx_substeps_for(p), CCX_SUBSTEPS_MIN)
  # across the prior's central 99.99 % and both ends of the h_ml range
  for (q in c(1e-4, 0.5, 0.9999)) {
    for (hm in c(30, 75, 200)) {
      pp <- p; pp$kz <- qlnorm(q, log(4000), 0.6); pp$h_ml <- hm
      expect_identical(ccx_substeps_for(pp), CCX_SUBSTEPS_MIN,
                       info = sprintf("kz q=%g h_ml=%g", q, hm))
    }
  }
})

test_that("the criterion predicts where the OLD fixed-substep scheme broke", {
  skip_if_no_cpp()
  # This is the diagnosis, held as a test: the -Inf wall was the RK4 limit on
  # the negative real axis, not anything about the data or the physics.
  for (hm in c(30, 75)) {
    w <- kz_wall(hm, 4)
    expect_false(anyNA(ccx_phys(run_at(0.95 * w, hm, substeps = 4L, retry_na = FALSE)$out)),
                 info = sprintf("h_ml %g: 0.95x the analytic wall must be stable", hm))
    expect_true(anyNA(ccx_phys(run_at(1.10 * w, hm, substeps = 4L, retry_na = FALSE)$out)),
                info = sprintf("h_ml %g: 1.10x the analytic wall must diverge", hm))
  }
})

test_that("no NAs anywhere in or far beyond the prior's support", {
  skip_if_no_cpp()
  # 175790 is the 2026-08-10 mode, which the old scheme could not evaluate.
  for (kz in c(4000, 37200, 175790, 4e5, 1e6)) {
    r <- run_at(kz)
    expect_false(anyNA(ccx_phys(r$out)), info = sprintf("kz = %g", kz))
    expect_gt(min(r$out$co2_NH), 0)
    expect_true(r$substeps >= CCX_SUBSTEPS_MIN)
  }
})

test_that("MUTATION: with the controller disabled, the same cases DO fail", {
  skip_if_no_cpp()
  # Guards against an inert gate. If forcing the old fixed 4 (and disabling the
  # NA retry) still produced finite output, the test above would be proving
  # nothing.
  fails <- vapply(c(175790, 4e5, 1e6),
                  function(kz) anyNA(ccx_phys(run_at(kz, substeps = 4L, retry_na = FALSE)$out)),
                  logical(1))
  expect_true(all(fails))
})

test_that("the auto substep count is accurate, not merely stable", {
  skip_if_no_cpp()
  # Stability is necessary but not sufficient: a barely-stable step can still be
  # inaccurate. Doubling the substeps beyond the controller's choice must not
  # move the answer more than RK4 truncation error.
  for (kz in c(175790, 1e6)) {
    p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); p$kz <- kz
    ss <- ccx_substeps_for(p)
    a <- run_at(kz, substeps = ss)$out
    b <- run_at(kz, substeps = 2L * ss)$out
    expect_lt(max(abs(a$co2_NH - b$co2_NH)) / max(a$co2_NH), 1e-6,
              label = sprintf("kz = %g CO2 relative change on doubling substeps", kz))
    expect_lt(max(abs(a$d14c_NH - b$d14c_NH)), 1e-3)
  }
})

# =====================================================================
# THE SEASONAL MIXED LAYER (2026-10-04; Marcus: "Apply A+B+C (Recommended)").
#
# Every test above runs at seas_ml = 0, so none of them could see what broke at
# seas_ml = 1. Near the P8 wall layer 1's winter thickness is a small difference
# (base - h_ml f). The controller read (A) the 12 SAMPLED monthly MLD values and
# (B) the K profile re-evaluated on the moved grid. Together these under-read the
# stiffness the integrator meets: at the #15 wave's start 017 (h_ml 74.44) 426/yr
# against 730/yr. RK4 ran at z = 4.06 against its 2.785 limit for ~10 days a
# year, and the objective there was integrator artefact (+273.2; CHANGELOG
# 10-03 j and 10-04 a, calibration/diag_seasml_substep_controller.R). Each test
# below holds the fix with a MUTATION: `ss_pre_20261004()` puts the old bound back
# and must fail. The thresholds are this file's own accuracy bar (the test above)
# and RK4's limit; neither is tuned to the fix.
# =====================================================================

# the canonical's model list with h_ml moved: the geometry is a function of h_ml
# alone, so this walks the canonical's own column towards its P8 wall
seasml_at <- function(hm) { p <- ccx_load_mode()$p; p$h_ml <- hm; p }

# The stiffness the INTEGRATOR meets: its own diffusion Jacobian as
# src/ccx_core.cpp builds it (dzl, dzml; layer 1 at its effective thickness on
# the ML interface under D1; the HELD kz_int), at each carried shape's continuous
# extremes, where it peaks (diag_seasml_substep_controller.R section 2 checks the
# extremes against a 1200-point year).
true_stiffness <- function(p) {
  grid <- ccx_grid_of(p); aux <- ccx_prepare(p, grid); K <- aux$kz_int
  rho <- function(h, f) {
    sh <- aux$a_ml[[h]] / aux$a_ls[[h]]; ht <- grid$h_ml * f; dzl <- grid$dz
    dzl[2] <- dzl[2] + (dzl[1] - ht) * sh; dzl[1] <- ht
    n <- length(dzl); dzm <- (dzl[-n] + dzl[-1]) / 2; A <- matrix(0, n, n)
    for (k in seq_len(n - 1)) {
      dzb <- if (k == 1 && isTRUE(aux$d1_on == 1L)) dzl[2] / sh else dzl[k + 1]
      ra <- K[k] / (dzl[k] * dzm[k]); rb <- K[k] / (dzb * dzm[k])
      A[k, k] <- A[k, k] - ra; A[k, k + 1] <- A[k, k + 1] + rb
      A[k + 1, k] <- A[k + 1, k] + ra; A[k + 1, k + 1] <- A[k + 1, k + 1] - rb
    }
    max(Mod(eigen(A, only.values = TRUE)$values))
  }
  max(vapply(HEMIS, function(h) max(rho(h, aux$mld_coef[[h]]$f_max), rho(h, aux$mld_coef[[h]]$f_min)), 0))
}

# THE MUTATION: the bound as it stood before 2026-10-04 -- sampled extremes, K
# re-evaluated on the moved grid, a silent clamp at the cap
ss_pre_20261004 <- function(p, grid = ccx_grid_of(p), dt = 1 / 12) {
  .sh <- ccx_mld_shape("ls")
  .fs <- c(min(vapply(HEMIS, function(h) min(.sh[[h]]$f_month), 0)),
           max(vapply(HEMIS, function(h) max(.sh[[h]]$f_month), 0)))
  lam <- max(vapply(.fs, function(f) { g <- ccx_grid_at_h_ml(grid, grid$h_ml * f)
    ccx_diffusion_eigmax(max(ccx_kz_profile(p, g)), g) +
      ccx_advection_eigbound(c(p$w_up, p$w_out_NH, p$w_out_SH), g, p) +
      ccx_tr_box_eigbound(p, g) + ccx_e_loop_eigbound(p, g) + ccx_thc_eigbound(p, g) }, 0)) +
    ccx_eq_cell_eigbound(p)
  as.integer(min(max(CCX_SUBSTEPS_MIN, ceiling(dt * lam / (CCX_STAB_SAFETY * CCX_RK4_STAB_LIMIT))),
                 CCX_SUBSTEPS_MAX))
}

# the canonical column's P8 wall: where the continuous winter maximum reaches layer 1's base
p8_wall <- function() {
  fmax <- max(vapply(HEMIS, function(h) ccx_mld_shape("ls")[[h]]$f_max, 0))
  .dep <- ccx_ocean_depth(seasml_at(75))   # the canonical's own column
  stats::uniroot(function(h) cumsum(ccx_ocean_grid(h, total_depth = .dep)$dz)[2] - h * fmax, c(60, 100), tol = 1e-10)$root
}

test_that("seas_ml = 1: the count keeps the integrator's own stiffness inside RK4's limit up to the P8 wall (MUTATION: the pre-10-04 bound breaks it)", {
  p0 <- seasml_at(75); skip_if_not(ccx_seas_ml_ls_on(p0), "the canonical does not run the LS seasonal mixed layer")
  # from the canonical's own h_ml to 0.3 m short of its wall (the bound's stop
  # sits closer; see the next test)
  hs <- c(ccx_load_mode()$p$h_ml, 60, 70, 72, 72.75, 73, 74, 74.4384, 75, p8_wall() - 0.3)
  z_now <- z_old <- numeric(length(hs))
  for (i in seq_along(hs)) {
    p <- seasml_at(hs[i]); r <- true_stiffness(p)
    z_now[i] <- r / 12 / ccx_substeps_for(p); z_old[i] <- r / 12 / ss_pre_20261004(p)
  }
  lab <- paste(sprintf("h_ml %.2f: z %.3f (pre-10-04 %.3f)", hs, z_now, z_old), collapse = "; ")
  # inside the SAFETY target, not merely the limit: with the held K the bound is conservative
  expect_true(all(z_now <= CCX_STAB_SAFETY * CCX_RK4_STAB_LIMIT), info = lab)
  expect_true(any(z_old > CCX_RK4_STAB_LIMIT), info = lab)       # the mutation: power on this very scan
})

test_that("seas_ml = 1: near the P8 wall the count STOPS rather than clamp, and past it there is no bound", {
  w <- seasml_at(75); skip_if_not(ccx_seas_ml_ls_on(w), "the canonical does not run the LS seasonal mixed layer")
  wall <- p8_wall()
  p <- seasml_at(wall - 0.02)                                   # 2 cm (of h_ml) short of the wall
  expect_error(ccx_substeps_for(p), "CCX_SUBSTEPS_MAX")
  # MUTATION: the old bound handed back an ordinary count there, past RK4's limit
  expect_lt(ss_pre_20261004(p), CCX_SUBSTEPS_MAX)
  expect_gt(true_stiffness(p) / 12 / ss_pre_20261004(p), CCX_RK4_STAB_LIMIT)
  expect_error(ccx_substeps_for(seasml_at(wall + 0.01)), "P8")
})

test_that("seas_ml = 1: near the P8 wall the auto count is ACCURATE, and the pre-10-04 count was not (MUTATION)", {
  skip_if_no_cpp()
  p <- seasml_at(74.4384)                         # start 017's h_ml on the canonical's column
  skip_if_not(ccx_seas_ml_ls_on(p), "the canonical does not run the LS seasonal mixed layer")
  sp <- ccx_spinup(p)                             # a state to integrate from; the orbit is not under test
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p), nuc_share = ccx_nuc_share_of(p))
  run <- function(ss) ccx_run_fast(sp, F, substeps = ss, retry_na = FALSE)$out
  moved <- function(ss) { a <- run(ss); b <- run(2L * ss)
    c(co2 = max(abs(a$co2_SH - b$co2_SH)) / max(a$co2_SH), d14c = max(abs(a$d14c_SH - b$d14c_SH))) }
  # the same bar as "the auto substep count is accurate, not merely stable" above
  m <- moved(ccx_substeps_for(p))
  expect_lt(m[["co2"]], 1e-6, label = "SH CO2 relative change on doubling the auto count")
  expect_lt(m[["d14c"]], 1e-3, label = "SH D14C change on doubling the auto count")
  m0 <- moved(ss_pre_20261004(p))
  expect_gt(m0[["co2"]], 1e-6, label = "MUTATION: the pre-10-04 count's SH CO2 change on doubling")
})
