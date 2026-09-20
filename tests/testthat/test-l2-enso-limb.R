# =====================================================================
# THE NINO3.4 RETURN LIMB (review avenue 1, 2026-09-17 k): `w_enso_l2` [Sv per
# index unit], structure constants `k_l2` (0 = absent) and `w0_l2` (the floor's
# mean), the "hilda_cl2" (k 2) and "hilda_cl3" (k 3; the array's, ruled 09-17 l)
# labels, whose layers live in ONE table (CCX_L2_RETURN_LAYERS).
# notes/prereg_2026-09-17k_l2_enso_limb_refit.md
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
  # the second label (ruled 09-17 l): layer 3, everything else hilda_cl2's; the layer
  # table is the ONE source, and every label in it is a registered structure
  # 2026-09-20 (o): + hilda_csl3, the limb (layer 3) on hilda_cs (the shipped structure since hilda30s)
  expect_identical(CCX_L2_RETURN_LAYERS, c(hilda_cl2 = 2L, hilda_cl3 = 3L, hilda_csl3 = 3L))
  expect_identical(CCX_L2_BASE_STRUCT, c(hilda_cl2 = "hilda_c", hilda_cl3 = "hilda_c", hilda_csl3 = "hilda_cs"))
  q3s <- ccx_apply_structure(p, "hilda_csl3", seas_ml = 1)
  expect_identical(q3s$k_l2, 3L); expect_identical(q3s$ml_nh_cycle, 0L); expect_true(ccx_l2_on(q3s))
  q3s$ml_nh_cycle <- NULL; q3c <- ccx_apply_structure(p, "hilda_cl3", seas_ml = 1); q3c$ml_nh_cycle <- NULL
  expect_identical(q3s[order(names(q3s))], q3c[order(names(q3c))])            # the NH flag is the ONLY difference from hilda_cl3
  expect_true(all(names(CCX_L2_RETURN_LAYERS) %in% CCX_STRUCT_LABELS))
  q3 <- ccx_apply_structure(p, "hilda_cl3", seas_ml = 1)
  expect_identical(attr(q3, "struct"), "hilda_cl3"); expect_identical(q3$k_l2, 3L); expect_true(ccx_l2_on(q3))
  q2 <- ccx_apply_structure(p, "hilda_cl2", seas_ml = 1); q2$k_l2 <- NULL; q3b <- q3; q3b$k_l2 <- NULL
  expect_identical(q2[order(names(q2))], q3b[order(names(q3b))])                  # the layer is the ONLY difference
  for (lab in names(CCX_L2_RETURN_LAYERS)) expect_identical(ccx_struct_block(lab)$k_l2, CCX_L2_RETURN_LAYERS[[lab]])
  expect_error(ccx_struct_hilda_cl("hilda_cl9"), "subscript out of bounds")
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
  # 2026-09-19 (m): the canonical (hilda30e) now HOLDS w_enso_l2 among its pins (inert under hilda_c),
  # so nothing in the table is new to its file; the limb's name is a pin, not an absence
  new_names <- setdiff(CCX_PARAM_NAMES, c(md$param_names, names(md$pins)))
  expect_length(new_names, 0L)
  expect_true("w_enso_l2" %in% names(md$pins)); expect_identical(unname(md$pins[["w_enso_l2"]]), 0)
  pm <- suppressWarnings(ccx_seed_unencodable(ccx_migrate_par_set(md$par_mode), "P0a-l2"))
  expect_identical(pm$w_enso_l2, CCX_PARAM_TABLE$w_enso_l2$init)      # seeded: 0 is on the floor
  u  <- ccx_par_to_unc(pm)
  sc <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(u)
  ccx_unpin_params(rm); rm <- list()
  st <- attr(sc, "streams")
  expect_identical(st[names(md$streams)], md$streams)                  # 25 rows, bit-exact: the seeded name is INERT
})

test_that("P0b SPINUP, P0c CONSERVATION, P0d PARITY with the limb ON at both seasonal states and BOTH return layers; the limb MOVES the transient", {
  skip_if_no_cpp()
  # hilda_cl2 at both seasonal states; hilda_cl3 at the array's (seas_ml 1)
  for (arm in list(c("hilda_cl2", 0), c("hilda_cl2", 1), c("hilda_cl3", 1))) {
    lab <- arm[1]; seas <- as.numeric(arm[2])
    p <- l2_par(struct = lab, seas_ml = seas, w = 25); q <- p; q$w_enso_l2 <- 0
    sp <- ccx_spinup(p); sq <- ccx_spinup(q)
    expect_identical(sp$y, sq$y)                                       # P0b: enso = 0 in the spinup -> no limb
    expect_identical(sp$aux$l2_on, 1L); expect_identical(sp$aux$k_l2, CCX_L2_RETURN_LAYERS[[lab]])
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

test_that("P0e THE FLOOR: sign, the linear regime, the floor at enso >= w0/w_enso, and the k_l2 boxes are the only ones touched -- at BOTH return layers", {
 for (lab in names(CCX_L2_RETURN_LAYERS)) {
  p <- l2_par(struct = lab, seas_ml = 0, w = 25); sp <- ccx_spinup(p); q <- p; q$w_enso_l2 <- 0; aq <- ccx_prepare(q)
  k <- CCX_L2_RETURN_LAYERS[[lab]]; expect_identical(sp$aux$k_l2, k)
  d_at <- function(e, pp = p, aux = sp$aux) ccx_deriv(sp$y, 1900.2, pp, zero_forc_l2(sp$prod_c14, enso = e), sp$grid, aux)
  d0 <- d_at(0, q, aq)
  for (h in HEMIS) {
    ix <- sp$aux$idx[[h]]; iml <- ix$ml; ik <- ix$oc[k]
    dn <- d_at(0.5) - d0; dl <- d_at(-0.5) - d0
    # El Nino: carbon LEAVES the ML for layer k (less supply); La Nina the reverse; nothing else moves
    expect_lt(dn[iml, "C"], 0); expect_gt(dn[ik, "C"], 0); expect_gt(dl[iml, "C"], 0); expect_lt(dl[ik, "C"], 0)
    expect_equal(dn[iml, "C"], -dn[ik, "C"], tolerance = 1e-12)
    touched <- which(abs(dn[, "C"]) > 0); expect_setequal(touched, c(sp$aux$idx$NH$ml, sp$aux$idx$NH$oc[k], sp$aux$idx$SH$ml, sp$aux$idx$SH$oc[k]))
    # the linear regime: the anomaly at 0.5 is exactly half the anomaly at 1.0 (both below the floor 27/25 = 1.08)
    expect_equal(d_at(1.0)[iml, "C"] - d0[iml, "C"], 2 * dn[iml, "C"], tolerance = 1e-12)
    # the physical unit: at enso = 1 the exchange anomaly is -w_enso_l2 Sv split equally, on layer k's gradient
    conc <- sp$y[ik, "C"] / (sp$aux$a_ls[[h]] * sp$grid$dz[k + 1]) - sp$y[iml, "C"] / (sp$aux$a_ml[[h]] * sp$grid$dz[1])
    expect_equal(d_at(1.0)[iml, "C"] - d0[iml, "C"], -25 * CCX_SV_TO_M3YR * 0.5 * conc, tolerance = 1e-12)
    # the FLOOR: beyond enso = w0/w_enso the anomaly is -w0 x share and stops growing
    expect_equal(d_at(1.08)[iml, "C"], d_at(2.0)[iml, "C"], tolerance = 1e-12)
    expect_equal(d_at(2.0)[iml, "C"] - d0[iml, "C"], -27 * CCX_SV_TO_M3YR * 0.5 * conc, tolerance = 1e-12)
  }
  # the isotopes ride the same volumes on their own gradients (a k-ratio anomaly, not the ML's)
  dn <- d_at(0.5) - d0; iml <- sp$aux$idx$NH$ml; ik <- sp$aux$idx$NH$oc[k]
  r13 <- function(i) sp$y[i, "C13"] / sp$y[i, "C"]
  expect_false(isTRUE(all.equal(dn[iml, "C13"] / dn[iml, "C"], r13(iml), tolerance = 1e-6)))   # not the ML's own ratio
  # MUTATION of the floor: with w0_l2 huge the floor never binds and the 2.0 point is linear
  w <- p; w$w0_l2 <- 1e6; aw <- ccx_prepare(w)
  expect_equal(d_at(2.0, w, aw)[iml, "C"] - d0[iml, "C"], 4 * (d_at(0.5, w, aw)[iml, "C"] - d0[iml, "C"]), tolerance = 1e-9)
 }
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
  # 2026-09-19 (m): w_enso_l2 is IN the canonical's pins now, so "extend by it" is the base set; the
  # inert-extension rule is exercised on the canonical's pins WITHOUT it as the base
  cp7 <- CCX_MODE_CANONICAL_PINS[setdiff(names(CCX_MODE_CANONICAL_PINS), "w_enso_l2")]
  expect_true(ccx_pins_extend(c(cp7, w_enso_l2 = 0), cp7, "solved", struct = "hilda_c"))
  expect_false(ccx_pins_extend(c(cp7, w_enso_l2 = 0), cp7, "solved", struct = "hilda_cl2"))
  expect_true(ccx_pins_extend(c(cp7, w_enso_l2 = 5), cp7, "solved", struct = "hilda_c"))    # an INERT name's value cannot matter
  expect_true("w_enso_l2" %in% ccx_inert_names("solved", "hilda_c")); expect_false("w_enso_l2" %in% ccx_inert_names("solved", "hilda_cl2"))
  expect_false(ccx_pins_extend_canonical(CCX_MODE_CANONICAL_PINS, "solved", struct = "hilda_c"))   # the base set itself is not an EXTENSION (same() handles it)
  moved <- CCX_MODE_CANONICAL_PINS; moved[["w_thc"]] <- 5
  expect_false(ccx_pins_extend(c(moved[setdiff(names(moved), "w_enso_l2")], w_enso_l2 = 0), cp7, "solved", struct = "hilda_c"))   # a moved CANONICAL pin is not an extension
})

test_that("a file-HELD name this arm FITS is seeded, not fatal (2026-09-20 o): the canonical holds w_enso_l2 = 0 on the logit floor; the limb's arm fits it", {
  md <- readRDS(ccx_mode_file())
  skip_if_not("w_enso_l2" %in% names(ccx_mode_pins(md)), "the canonical does not hold w_enso_l2")
  arm <- CCX_MODE_L2_ARM_PINS                                  # fits w_enso_l2, pins the ENSO pair
  rm <- ccx_apply_pins(arm); on.exit(ccx_unpin_params(rm), add = TRUE)
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  expect_true("w_enso_l2" %in% attr(pm, "held_by_file"))
  expect_false(is.finite(.to_unc(pm$w_enso_l2, CCX_PARAM_TABLE$w_enso_l2)))   # 0 is on the floor: unencodable
  out <- capture.output(sd <- ccx_seed_unencodable(pm, "test"))
  expect_identical(sd$w_enso_l2, CCX_PARAM_TABLE$w_enso_l2$init)
  expect_true(any(grepl("HELD it at 0", out)))
  expect_true(all(is.finite(ccx_par_to_unc(sd))))
  # a held name this arm ALSO pins is untouched (the shim: held 0 by the file, pinned 0 by the arm)
  expect_identical(sd$ent_seas_amp_SH, 0)
  # MUTATION: a held value that DOES encode is left alone (no seeding message)
  pm2 <- pm; pm2$w_enso_l2 <- 5
  out2 <- capture.output(sd2 <- ccx_seed_unencodable(pm2, "test")); expect_identical(sd2$w_enso_l2, 5); expect_false(any(grepl("HELD", out2)))
})
