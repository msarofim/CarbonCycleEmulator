# =====================================================================
# THE LAYER-2 NINO3.4 LIMB (review avenue 1, 2026-09-17 k): `w_enso_l2` [Sv per
# index unit], structure constants `k_l2` (0 = absent) and `w0_l2` (the floor's
# mean), the "hilda_cl2" label. notes/prereg_2026-09-17k_l2_enso_limb_refit.md
# §2, P0 -- the contracts, gated BEFORE any science number is read:
#   P0a ABSENT       the name absent, present at 0, and present with k_l2 = 0
#                    are bit-exact with the canonical's model, both cores; the
#                    canonical's stored streams reproduce row by row.
#   P0b SPINUP       the periodic spinup is bit-identical with the limb on
#                    (enso = 0 there) -- the fixed point is untouched.
#   P0c CONSERVATION every tracer, transient with the limb on.
#   P0d PARITY       R vs C++, derivative and transient, both seasonal states.
#   P0e THE FLOOR    the limb's sign (El Nino = less supply to the ML), the
#                    floor at enso >= w0/w_enso, the linear regime below it.
#   P0f REFUSALS     every guard by name; the cell / E loop exclusion; the
#                    driver-side inert rule (ccx_l2_on, ccx_pins_extend_canonical).
# Every P0 is a MUTATION test in the sense of [[mutation_test_gates]]: the thing
# guarded is broken in the same test and the gate must then fail.
# =====================================================================
l2_par <- function(struct = "hilda_cl2", seas_ml = 1, w = 25, pump_field = "solved") {
  p <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = seas_ml, pump_field = pump_field)
  p$w_enso_l2 <- w
  p
}
zero_forc_l2 <- function(prod = 0, enso = 0)
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = enso, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)

test_that("the name ships OFF (k_l2 = 0), the label sets the two constants from the product, and the table entry is the prereg's", {
  p <- ccx_default_params()
  expect_identical(p$w_enso_l2, 0); expect_identical(p$k_l2, 0L); expect_identical(p$w0_l2, 27)
  expect_false(ccx_l2_on(p)); expect_identical(ccx_prepare(ccx_apply_structure(p, "hilda_c"))$l2_on, 0L)
  q <- ccx_apply_structure(p, "hilda_cl2", seas_ml = 1)
  expect_identical(attr(q, "struct"), "hilda_cl2")
  expect_identical(q$k_l2, 2L)                                                 # ruling R2
  expect_identical(q$w0_l2, unname(ccx_eq_cell_obs()$w0_prior$mean_sv))       # ruling R1: Meinen through the product
  expect_identical(q$hs_frac, ccx_struct_hilda_c()$hs_frac)                   # hilda_c's block rides along
  expect_true(ccx_l2_on(q))
  expect_identical(ccx_prepare(q)$l2_on, 0L)                                   # present but w_enso_l2 = 0 -> OFF
  q$w_enso_l2 <- 25; expect_identical(ccx_prepare(q)$l2_on, 1L)
  s <- CCX_PARAM_TABLE$w_enso_l2
  expect_identical(s$tr, "logit"); expect_identical(c(s$lo, s$hi), c(0, 60))
  expect_identical(s$prior(5), s$prior(55)); expect_identical(s$prior(61), -Inf)   # FLAT (ruling R3)
  expect_equal(s$init, sqrt(14 * 25), tolerance = 1e-2)                          # the bracket's geometric centre
  expect_true("w_enso_l2" %in% CCX_PARAM_NAMES); expect_true("w_enso_l2" %in% CCX_PARAM_ABSENT_OK)
  expect_identical(which(CCX_PARAM_NAMES == "w_enso_l2"), which(CCX_PARAM_NAMES == "w_thc") + 1L)   # appended after w_thc
  expect_true("hilda_cl2" %in% CCX_STRUCT_LABELS)
  # no existing name is a PREFIX of the new one and vice versa (the w_e -> w_eq incident)
  others <- setdiff(CCX_PARAM_NAMES, "w_enso_l2")
  expect_false(any(startsWith("w_enso_l2", others))); expect_false(any(startsWith(others, "w_enso_l2")))
  # a 37-name ancestor migrates to 0 and is SEEDED at init (0 sits on the floor)
  anc <- readRDS(ccx_mode_file())$par_mode; expect_false("w_enso_l2" %in% names(anc))   # hilda30h predates the limb
  mig <- ccx_migrate_par_set(anc); expect_identical(mig$w_enso_l2, 0); expect_true("w_enso_l2" %in% attr(mig, "migrated"))
  sd <- suppressWarnings(ccx_seed_unencodable(mig, "test")); expect_identical(sd$w_enso_l2, s$init)
})

test_that("P0a ABSENT: the name absent, at 0, or at 25 under k_l2 = 0 is BIT-EXACT with the canonical's model, both cores", {
  p <- ccx_apply_structure(ccx_default_params(), "hilda_c", seas_ml = 1)
  q <- p; q$w_enso_l2 <- NULL; q$k_l2 <- NULL; q$w0_l2 <- NULL          # absent
  r <- p; r$w_enso_l2 <- 25                                             # present, INERT (k_l2 = 0)
  z <- ccx_apply_structure(ccx_default_params(), "hilda_cl2", seas_ml = 1)   # the limb's structure at w = 0
  a <- ccx_spinup(p); b <- ccx_spinup(q); d <- ccx_spinup(r); e <- ccx_spinup(z)
  expect_identical(a$y, b$y); expect_identical(a$y, d$y); expect_identical(a$y, e$y)
  expect_identical(d$aux$l2_on, 0L); expect_identical(e$aux$l2_on, 0L)
  expect_identical(ccx_substeps_for(p), ccx_substeps_for(r)); expect_identical(ccx_substeps_for(p), ccx_substeps_for(z))
  F0 <- zero_forc_l2(a$prod_c14, enso = 0.7)
  dp <- ccx_deriv(a$y, 1900.2, p, F0, a$grid, a$aux)
  expect_identical(ccx_deriv(a$y, 1900.2, q, F0, b$grid, b$aux), dp)
  expect_identical(ccx_deriv(a$y, 1900.2, r, F0, d$grid, d$aux), dp)
  expect_identical(ccx_deriv(a$y, 1900.2, z, F0, e$grid, e$aux), dp)
  # MUTATION: the limb ON is NOT the canonical's model
  w <- z; w$w_enso_l2 <- 25; sw <- ccx_spinup(w)
  expect_identical(sw$y, a$y)                                          # the spinup still is (P0b)
  expect_false(identical(ccx_deriv(a$y, 1900.2, w, F0, sw$grid, sw$aux), dp))
  skip_if_no_cpp()
  F <- ccx_build_forcing("historical", c(1960, 1962), prod_c14 = a$prod_c14)   # inside the ENSO record
  ra <- ccx_run_fast(a, F); rb <- ccx_run_fast(b, F); rd <- ccx_run_fast(d, F); re <- ccx_run_fast(e, F)
  expect_identical(ra$state, rb$state); expect_identical(ra$state, rd$state); expect_identical(ra$state, re$state)
  expect_identical(ra$out, rb$out); expect_identical(ra$out, rd$out); expect_identical(ra$out, re$out)
  rw <- ccx_run_fast(sw, F); expect_false(identical(rw$state, ra$state))
})

test_that("P0a (canonical): the canonical's stored LIKELIHOOD reproduces row by row; w_enso_l2 is the ONLY new fitted name", {
  skip_if_no_cpp()
  md <- readRDS(ccx_mode_file())
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  expect_false(ccx_l2_on(bp))                                          # every registered structure: k_l2 = 0
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  new_names <- setdiff(CCX_PARAM_NAMES, c(md$param_names, names(md$pins)))
  expect_identical(new_names, "w_enso_l2")
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-l2"))
  expect_identical(pm$w_enso_l2, CCX_PARAM_TABLE$w_enso_l2$init)      # seeded: 0 is on the floor
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  st <- attr(sc, "streams")
  expect_identical(st[names(md$streams)], md$streams)                  # 25 rows, bit-exact: the seeded name is INERT
})

test_that("P0b SPINUP, P0c CONSERVATION, P0d PARITY with the limb ON at both seasonal states; the limb MOVES the transient", {
  skip_if_no_cpp()
  for (seas in c(0, 1)) {
    p <- l2_par(seas_ml = seas, w = 25); q <- p; q$w_enso_l2 <- 0
    sp <- ccx_spinup(p); sq <- ccx_spinup(q)
    expect_identical(sp$y, sq$y)                                       # P0b: enso = 0 in the spinup -> no limb
    expect_identical(sp$aux$l2_on, 1L); expect_identical(sp$aux$k_l2, 2L)
    expect_equal(sp$aux$l2_share$NH + sp$aux$l2_share$SH, 1, tolerance = 1e-14)
    F  <- ccx_build_forcing("historical", c(1996, 1999), prod_c14 = sp$prod_c14)   # the 1997-98 event
    for (i in c(1L, 19L)) { fr <- ccx_forcing_at(F, i)
      dR <- ccx_deriv(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      dC <- ccx_deriv_fast(sp$y, F$t[i], p, fr, sp$grid, sp$aux)
      expect_lt(max(abs(dR - dC)) / max(abs(dR)), 1e-10) }              # P0d, derivative
    r <- ccx_run_fast(sp, F); rR <- suppressWarnings(ccx_run(sp, F))
    expect_lt(max(abs(rR$state - r$state)) / max(abs(r$state)), 1e-12)   # P0d, transient
    expect_identical(r$substeps, ccx_substeps_for(p))
    F0 <- F; for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F0[[cc]][] <- 0
    r0 <- ccx_run_fast(sp, F0)
    for (tr in c("C", "C13"))                                           # P0c (C14 decays and is produced; its limb half is in the derivative check below)
      expect_lt(abs(sum(r0$state[, tr]) - sum(sp$y[, tr])) / sum(sp$y[, tr]), 1e-10)
    # the limb is LIVE across the event: the transient differs from w = 0
    r_off <- ccx_run_fast(sq, F)
    expect_gt(max(abs(r$state[, "C"] - r_off$state[, "C"])), 1e-4)
    # MUTATION of P0c: a one-sided edit (drop the ML's half) would not conserve --
    # asserted through the derivative's column sums, which the limb leaves at 0
    fr <- ccx_forcing_at(F, 19L)
    d1 <- ccx_deriv(sp$y, F$t[19L], p, fr, sp$grid, sp$aux); d0 <- ccx_deriv(sq$y, F$t[19L], q, fr, sq$grid, sq$aux)
    for (tr in CCX_TRACERS) expect_lt(abs(sum(d1[, tr] - d0[, tr])), 1e-9 * max(abs(d1[, tr])))
  }
})

test_that("P0e THE FLOOR: sign, the linear regime, the floor at enso >= w0/w_enso, and the k_l2 boxes are the only ones touched", {
  p <- l2_par(seas_ml = 0, w = 25); sp <- ccx_spinup(p); q <- p; q$w_enso_l2 <- 0; aq <- ccx_prepare(q)
  d_at <- function(e, pp = p, aux = sp$aux) ccx_deriv(sp$y, 1900.2, pp, zero_forc_l2(sp$prod_c14, enso = e), sp$grid, aux)
  d0 <- d_at(0, q, aq)
  for (h in HEMIS) {
    ix <- sp$aux$idx[[h]]; iml <- ix$ml; ik <- ix$oc[2]
    dn <- d_at(0.5) - d0; dl <- d_at(-0.5) - d0
    # El Nino: carbon LEAVES the ML for layer 2 (less supply); La Nina the reverse; nothing else moves
    expect_lt(dn[iml, "C"], 0); expect_gt(dn[ik, "C"], 0); expect_gt(dl[iml, "C"], 0); expect_lt(dl[ik, "C"], 0)
    expect_equal(dn[iml, "C"], -dn[ik, "C"], tolerance = 1e-12)
    touched <- which(abs(dn[, "C"]) > 0); expect_setequal(touched, c(sp$aux$idx$NH$ml, sp$aux$idx$NH$oc[2], sp$aux$idx$SH$ml, sp$aux$idx$SH$oc[2]))
    # the linear regime: the anomaly at 0.5 is exactly half the anomaly at 1.0 (both below the floor 27/25 = 1.08)
    expect_equal(d_at(1.0)[iml, "C"] - d0[iml, "C"], 2 * dn[iml, "C"], tolerance = 1e-12)
    # the physical unit: at enso = 1 the exchange anomaly is -w_enso_l2 Sv split equally
    conc <- sp$y[ik, "C"] / (sp$aux$a_ls[[h]] * sp$grid$dz[3]) - sp$y[iml, "C"] / (sp$aux$a_ml[[h]] * sp$grid$dz[1])
    expect_equal(d_at(1.0)[iml, "C"] - d0[iml, "C"], -25 * CCX_SV_TO_M3YR * 0.5 * conc, tolerance = 1e-12)
    # the FLOOR: beyond enso = w0/w_enso the anomaly is -w0 x share and stops growing
    expect_equal(d_at(1.08)[iml, "C"], d_at(2.0)[iml, "C"], tolerance = 1e-12)
    expect_equal(d_at(2.0)[iml, "C"] - d0[iml, "C"], -27 * CCX_SV_TO_M3YR * 0.5 * conc, tolerance = 1e-12)
  }
  # the isotopes ride the same volumes on their own gradients (a k-ratio anomaly, not the ML's)
  dn <- d_at(0.5) - d0; iml <- sp$aux$idx$NH$ml; ik <- sp$aux$idx$NH$oc[2]
  r13 <- function(i) sp$y[i, "C13"] / sp$y[i, "C"]
  expect_false(isTRUE(all.equal(dn[iml, "C13"] / dn[iml, "C"], r13(iml), tolerance = 1e-6)))   # not the ML's own ratio
  # MUTATION of the floor: with w0_l2 huge the floor never binds and the 2.0 point is linear
  w <- p; w$w0_l2 <- 1e6; aw <- ccx_prepare(w)
  expect_equal(d_at(2.0, w, aw)[iml, "C"] - d0[iml, "C"], 4 * (d_at(0.5, w, aw)[iml, "C"] - d0[iml, "C"]), tolerance = 1e-9)
})

test_that("P0f REFUSALS by name, the exclusions, and the driver-side inert rule", {
  p <- l2_par()
  q <- p; q$w_enso_l2 <- -1;            expect_error(ccx_prepare(q), "w_enso_l2")
  q <- p; q$w_enso_l2 <- NA_real_;      expect_error(ccx_prepare(q), "w_enso_l2")
  q <- p; q$k_l2 <- 11L;                expect_error(ccx_prepare(q), "k_l2")
  q <- p; q$k_l2 <- -1L;                expect_error(ccx_prepare(q), "k_l2")
  q <- p; q$w0_l2 <- 0;                 expect_error(ccx_prepare(q), "w0_l2")
  q <- p; q$w0_l2 <- 0; q$k_l2 <- 0L;   expect_identical(ccx_prepare(q)$l2_on, 0L)   # absent: w0 unread
  # two upwelling representations on one column
  e <- ccx_apply_structure(ccx_default_params(), "hilda_eq", seas_ml = 1); e$w_eq <- 27; e$k_l2 <- 2L; e$w_enso_l2 <- 25
  expect_error(ccx_prepare(e), "equatorial cell")
  v <- l2_par(pump_field = "martin"); v$pump_export <- 9.08; v$w_vent <- 20
  expect_error(ccx_prepare(v), "ventilation loop")
  # the inert rule the reference set and the driver read
  expect_true(ccx_pins_extend_canonical(c(CCX_MODE_CANONICAL_PINS, w_enso_l2 = 0), "solved", struct = "hilda_c"))
  expect_false(ccx_pins_extend_canonical(c(CCX_MODE_CANONICAL_PINS, w_enso_l2 = 0), "solved", struct = "hilda_cl2"))
  expect_true(ccx_pins_extend_canonical(c(CCX_MODE_CANONICAL_PINS, w_enso_l2 = 5), "solved", struct = "hilda_c"))    # an INERT name's value cannot matter
  moved <- CCX_MODE_CANONICAL_PINS; moved[["w_thc"]] <- 5
  expect_false(ccx_pins_extend_canonical(c(moved, w_enso_l2 = 0), "solved", struct = "hilda_c"))                     # a moved CANONICAL pin is not an extension
})
