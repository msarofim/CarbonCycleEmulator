# =====================================================================
# THE HIGH-LATITUDE BOXES (HILDA HS/HD, built 2026-09-05)
#
# Siegenthaler & Joos (1992), Tellus 44B:186-207 -- a cold surface box over its
# own well-mixed deep box, BESIDE the low-latitude column rather than under it.
# Specified in notes/prereg_2026-09-05_hilda_boxes.md, scored in
# notes/collect_2026-09-05_hilda_boxes.md.
#
# WHAT THESE TESTS GUARD, and why each one exists rather than being obvious:
#   * "off" means ABSENT, not present-and-empty -- 32 boxes, not 36 with zeros.
#     Zero-mass boxes would make ccx_spinup()'s Newton Jacobian and both isotope
#     operators singular, and would change the incumbent's state vector.
#   * the box count is therefore RUNTIME on both sides, and the C++ stride is
#     set from aux$hs_on. A disagreement there is silent garbage, not an error.
#   * every limb is MUTATION-TESTED: break what it carries and confirm the model
#     moves. A structure that is wired but inert reports "no effect" identically
#     to one that was measured and found nothing.
# =====================================================================

test_that("the structure ships OFF, and off means ABSENT", {
  p <- ccx_default_params()
  expect_identical(p$hs_frac, 0)
  expect_false(ccx_hs_on(p))
  expect_length(ccx_box_names(N_INTERIOR), 32L)
  expect_length(ccx_box_names(N_INTERIOR, TRUE), 36L)
  # a parameter list from before 2026-09-05 has no hs_frac at all, and absence
  # must mean the same thing as zero or a stored mode would silently gain boxes
  p$hs_frac <- NULL
  expect_false(ccx_hs_on(p))
  # the HL parameters may be set and still emit nothing: hs_frac is the switch
  p <- ccx_default_params(); p$u_hs <- 38; p$tau_q <- 538
  expect_false(ccx_hs_on(p))
  expect_identical(nrow(ccx_prepare(p)$idx$NH$hs), NULL)   # no such index
})

test_that("hs_frac = 0 is BIT-EXACT, with every HL parameter set", {
  # The contract pump_grad = 0 and alpha_as_tdep = 0 already carry. This is the
  # one that makes every result before 2026-09-05 reproducible.
  p <- ccx_default_params()
  q <- p; q$hs_frac <- 0; q$u_hs <- 38; q$tau_q <- 538; q$sst_hs <- 2
  a <- ccx_spinup(p); b <- ccx_spinup(q)
  expect_identical(nrow(a$y), 32L)
  expect_identical(nrow(b$y), 32L)
  expect_identical(a$y, b$y)
  expect_identical(a$diagnostics$d14c_bottom_box, b$diagnostics$d14c_bottom_box)
  expect_identical(a$prod_c14, b$prod_c14)
})

test_that("the boxes appear, are named, and carry carbon when the switch is on", {
  p <- ccx_default_params()
  p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  aux <- ccx_prepare(p)
  expect_identical(aux$hs_on, 1L)
  bn <- ccx_box_names(aux$grid$nl, TRUE)
  expect_identical(bn[aux$idx$NH$hs], "NH_hs")
  expect_identical(bn[aux$idx$SH$hd], "SH_hd")
  # ORDER IS LOAD-BEARING: the C++ derives its stride from this layout, so the
  # two new boxes must come AFTER the interior column, not anywhere else.
  expect_identical(aux$idx$NH$hs, max(aux$idx$NH$oc) + 1L)
  expect_identical(aux$idx$NH$hd, aux$idx$NH$hs + 1L)
  expect_identical(aux$idx$SH$hs - aux$idx$NH$hs, 18L)   # the stride
  # the area partition, and that the TOTAL is conserved
  expect_equal(aux$a_ls$NH + aux$a_hs$NH, aux$a_oc$NH)
  expect_equal(aux$a_hs$NH / aux$a_oc$NH, 0.16)
  sp <- ccx_spinup(p)
  expect_identical(nrow(sp$y), 36L)
  expect_gt(sp$y[aux$idx$NH$hs, "C"], 0)
  expect_gt(sp$y[aux$idx$NH$hd, "C"], 0)
})

test_that("the spinup still converges, and carbon still closes, with the boxes on", {
  p <- ccx_default_params()
  p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  sp <- ccx_spinup(p)
  # the analytic 12C equilibrium is NOT a fixed point once HS sits at a
  # different temperature from the mixed layer, so this also asserts that the
  # full-state Newton is actually being entered
  expect_lt(sp$diagnostics$max_abs_dCdt, 1e-8)
  expect_lt(sp$diagnostics$max_abs_dC13dt, 1e-8)
  zf <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
             gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0,
             c14_cosmo = sp$prod_c14)
  p0 <- ccx_set_enso(p, list(gamma_enso = 0))
  p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
  d <- ccx_deriv_fast(sp$y, 1750, p0, zf, sp$grid, sp$aux)
  expect_lt(sum(abs(d[, "C"])) / sum(sp$y[, "C"]), 1e-9)
})

test_that("R and C++ agree with the boxes on", {
  # The port gate, for the new structure specifically. test-parity.R covers the
  # 32-box model; this is the 36-box one, and the two cores index it
  # independently -- a stride disagreement is silent garbage, not an error.
  p <- ccx_default_params()
  p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1850, 1851), prod_c14 = sp$prod_c14)
  fr <- ccx_forcing_at(F, 1L)
  dR <- ccx_deriv(sp$y, 1850, p, fr, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, 1850, p, fr, sp$grid, sp$aux)
  expect_equal(dR, dC, tolerance = 1e-10)
  # and the transient integrates without falling over -- AND the R path
  # agrees with it on the stocks (audit 2026-09-06d: ccx_run() had excluded
  # HS/HD from ocean_C / ocean_C14 while the C++ core counted them)
  r  <- ccx_run_fast(sp, F)
  # the R path re-evaluates the carbonate constants at the HS temperature every
  # substep and warns each time it dips below 2 C (the documented extrapolation,
  # handoff 09-06b); the C++ path does not. Silenced HERE only -- the stocks are the test.
  rR <- suppressWarnings(ccx_run(sp, F))
  expect_false(anyNA(r$out))
  for (cc in c("ocean_C", "ocean_C14", "co2_NH", "co2_SH"))
    expect_lt(max(abs(rR$out[[cc]] - r$out[[cc]])) / max(abs(r$out[[cc]])), 1e-12)
  expect_identical(rownames(r$state)[sp$aux$idx$NH$hs], "NH_hs")
})

test_that("EVERY limb is mutation-tested: break it and the model must move", {
  # A wired-but-inert mechanism reports "no effect" identically to one that was
  # measured and found nothing -- the standing no_power_null discipline. Each
  # limb is switched off ON ITS OWN and the deep Delta14C must respond.
  base <- ccx_default_params()
  base <- ccx_apply_structure(base, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  d_on <- ccx_spinup(base)$diagnostics$d14c_bottom_box

  # (a) the conduit
  q <- base; q$u_hs <- 0
  expect_gt(abs(ccx_spinup(q)$diagnostics$d14c_bottom_box - d_on), 1)
  # (b) the HD <-> interior exchange. With it off the high-latitude column is
  #     isolated from the low-latitude one HYDROGRAPHICALLY -- but NOT
  #     completely, and the residual is worth pinning rather than hiding.
  #
  #     ⭐ THE TWO COLUMNS STILL SHARE AN ATMOSPHERE. HS exchanges CO2 with it,
  #     so switching tau_q off leaves HS + HD as an extra 14C reservoir that the
  #     natural-production solve has to fill; `prod_c14` moves, and the LS
  #     column feels it through the atmosphere. MEASURED at the defaults:
  #     3.9e-04 permil on the bottom box, i.e. real but four orders below the
  #     conduit's own effect. Asserting EXACT equality here would be asserting
  #     that an air-sea flux does nothing.
  q <- base; q$tau_q <- 0
  dq <- ccx_spinup(q)$diagnostics$d14c_bottom_box
  d_none <- ccx_spinup(ccx_default_params())$diagnostics$d14c_bottom_box
  expect_false(identical(dq, d_none))          # the atmospheric path is real
  expect_lt(abs(dq - d_none), 0.01)            # and it is FOUR ORDERS smaller
  # (c) HS's own temperature: a colder HS holds more carbon and a different
  #     pCO2, so the whole column must move
  q <- base; q$sst_hs <- 10
  expect_gt(abs(ccx_spinup(q)$diagnostics$d14c_hs[["NH"]] -
                ccx_spinup(base)$diagnostics$d14c_hs[["NH"]]), 1)
})

test_that("HS under-equilibrates, which is the whole reason it is a box", {
  # P1 of the pre-registration. HS is fed old water from HD and only partly
  # re-equilibrates with the atmosphere before sinking again, so it must come
  # out substantially DEPLETED relative to the low-latitude mixed layer. This is
  # emergent: no HS observable is in the likelihood and nothing is fitted to one.
  p <- ccx_default_params()
  p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  d <- ccx_spinup(p)$diagnostics
  sp <- ccx_spinup(p)
  ml <- 1000 * (sp$y[sp$aux$idx$NH$ml, "C14"] / sp$y[sp$aux$idx$NH$ml, "C"] - 1)
  expect_lt(d$d14c_hs[["NH"]], ml - 20)      # the prereg's own falsifier
  expect_lt(d$d14c_hd[["NH"]], d$d14c_hs[["NH"]])   # HD is older than HS
  # with the conduit OFF, HS has no supply of old water and must equilibrate
  # with the atmosphere instead -- the control that says the depletion above is
  # the conduit's doing and not a boundary condition
  q <- p; q$u_hs <- 0
  expect_gt(ccx_spinup(q)$diagnostics$d14c_hs[["NH"]], -20)
})

test_that("the diagnostics are NA when the structure is off, never a stale zero", {
  d <- ccx_spinup(ccx_default_params())$diagnostics
  expect_true(all(is.na(d$d14c_hs)))
  expect_true(all(is.na(d$d14c_hd)))
})

test_that("h_hs = 0 means FOLLOW h_ml, and absence means the same thing", {
  # The absence contract, for the parameter added 2026-09-05b. A list written
  # before it existed must reach both cores as the 09-05 structure.
  p <- ccx_default_params()
  p <- ccx_apply_structure(p, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  expect_identical(p$h_hs, 0)
  q <- p; q$h_hs <- NULL
  r <- p; r$h_hs <- ccx_ocean_grid(p$h_ml)$h_ml
  expect_identical(ccx_spinup(p)$y, ccx_spinup(q)$y)
  expect_identical(ccx_spinup(p)$y, ccx_spinup(r)$y)
  expect_identical(ccx_prepare(p)$h_hs, ccx_prepare(p)$grid$h_ml)
})

test_that("HS's Delta14C is INVARIANT to its thickness, because the h cancels", {
  # ⛔ THIS PINS A RETRACTION. notes/collect_2026-09-05_hilda_boxes.md sec.2
  # explained HS's shortfall against HILDA with TWO terms, one of them a 1.79x
  # thickness ratio. There is no such term: in steady state HS's isotope ratio
  # is a balance of rates PER UNIT VOLUME, and both the HS<->HD limbs (u/h_hs)
  # and air-sea equilibration (gx/(A h_hs)) carry the same 1/h_hs, so the ratio
  # -- and hence the steady state -- does not depend on it. Thickness sets the
  # box's INVENTORY, i.e. how fast it REACHES steady state, not what it is.
  #
  # Held as a test because the algebra is easy to forget and the next person to
  # reach for "make HS thinner" deserves to be told in one second rather than
  # after a spinup sweep. See notes/collect_2026-09-05bc_hs_endmember.md sec.1.
  base <- ccx_default_params()
  base <- ccx_apply_structure(base, "hilda")   # the declared HILDA block, through the ONE resolver (2026-09-12)
  thick <- base; thick$h_hs <- 150
  thin  <- base; thin$h_hs  <- 50
  hs <- function(p) ccx_spinup(p)$diagnostics$d14c_hs[["NH"]]
  # 3x the thickness, and HS must not move by more than a fraction of a permil
  expect_lt(abs(hs(thick) - hs(thin)), 0.5)
  # ...while the INVENTORY does move, which is what thickness actually sets --
  # the control that says the invariance above is physics and not an inert knob
  m <- function(p) { sp <- ccx_spinup(p); sp$y[sp$aux$idx$NH$hs, "C"] }
  expect_gt(m(thick) / m(thin), 2.5)
})
