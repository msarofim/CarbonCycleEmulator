# =====================================================================
# The INERT SOIL CARVE-OUT (2026-09-30, Marcus: "Go with 0-1 m; build the inert
# pool"). soil_inert_frac = f of the passive pool's stock is radiocarbon-free
# and exchanges with nothing: the exchanging passive pool takes (1 - f) of its
# litter share (ccx_litter_slow_eff()), and the inert remainder is the constant
# aux$soil_inert. CHANGELOG 2026-09-30 (b)/(c).
#
# What must hold, and why each gate can fail:
#   OFF   absent / 0 is BIT-EXACT to the pre-build model (every registered file);
#   EQUIV the carve-out IS litter_slow_frac * (1 - f) -- the 09-29 (v) proxy --
#         in the derivative, the spinup and aux$land0, so the (v) numbers carry;
#   PARITY the two cores agree with it ON (hard rule 1), incl. the pro-rata
#         land-use debit path, which reads the same share;
#   CONSERVE closed-system carbon is conserved with it ON;
#   STOCK exchanging + inert passive = the UNCARVED passive stock, per hemisphere.
#   BOX   (2026-09-30 f) the inert pool is a STATE BOX `soil_inert`, appended last
#         per hemisphere, ABSENT when off; pinned in all three spinup solves;
#         C = aux$soil_inert, 13C at the passive pool's ratio, 14C = 0, zero
#         derivative; counted in land_C (both cores), never in ocean_C.
# =====================================================================

F_ON <- ccx_const("SOIL_INERT_FRAC")

p_off <- local({ p <- ccx_default_params(); ccx_set_enso(p, list(gamma_enso = 0.5)) })
p_on  <- local({ p <- p_off; p$soil_inert_frac <- F_ON; p })
p_prx <- local({ p <- p_off; p$litter_slow_frac <- p_off$litter_slow_frac * (1 - F_ON); p })

forc_open <- function(sp) {
  list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
       cum_luc = list(NH = 120, SH = 80),
       gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
       c14_cosmo = sp$prod_c14, d13c_foss = -27.6)
}

test_that("the constant derives from Copard's printed layer masses (0-1 m)", {
  expect_identical(F_ON, (77 + 216) / (704 + 801))
  expect_equal(F_ON, 0.1947, tolerance = 1e-4)
  expect_identical(CCX_CONSTANTS$SOIL_INERT_FRAC$status, "cited")
})

test_that("OFF: absent and 0 are bit-exact, in the share, the spinup and aux", {
  p_abs <- p_off; p_abs$soil_inert_frac <- NULL
  expect_identical(ccx_litter_slow_eff(p_off), p_off$litter_slow_frac)
  expect_identical(ccx_litter_slow_eff(p_abs), p_off$litter_slow_frac)
  s0 <- ccx_spinup(p_off); sa <- ccx_spinup(p_abs)
  expect_identical(s0$y, sa$y)
  expect_identical(s0$aux$land0, sa$aux$land0)
  expect_identical(unlist(s0$aux$soil_inert), c(NH = 0, SH = 0))
  # OFF means ABSENT: no box, the state is the pre-2026-09-30 layout
  expect_length(ccx_inert_idx(s0$aux), 0L)
  expect_false(any(grepl("soil_inert", rownames(s0$y))))
  expect_identical(nrow(s0$y), length(ccx_box_names(N_INTERIOR)))
  # the C++ core receives the plain litter_slow_frac when off
  skip_if_no_cpp()
  expect_identical(ccx_cpp_par(p_off)[["litter_slow_frac"]], p_off$litter_slow_frac)
})

test_that("EQUIV: the carve-out IS the scaled-litter proxy, bit for bit", {
  sp_on <- ccx_spinup(p_on); sp_px <- ccx_spinup(p_prx)
  ii <- ccx_inert_idx(sp_on$aux)
  expect_length(ii, 2L)
  expect_identical(sp_on$y[-ii, ], sp_px$y)           # every EXCHANGING row, bit for bit
  expect_identical(sp_on$aux$land0, sp_px$aux$land0)
  expect_identical(ccx_luc_pool_shares(p_on), ccx_luc_pool_shares(p_prx))
  dR_on <- ccx_deriv(sp_on$y, 1980.5, p_on,  forc_open(sp_on), sp_on$grid, sp_on$aux)
  dR_px <- ccx_deriv(sp_px$y, 1980.5, p_prx, forc_open(sp_px), sp_px$grid, sp_px$aux)
  expect_identical(dR_on[-ii, ], dR_px)
  expect_true(all(dR_on[ii, ] == 0))                  # no fluxes, and nothing to decay
  # POWER: the carve-out is a different model from OFF (else EQUIV passes vacuously)
  sp_off <- ccx_spinup(p_off)
  expect_gt(abs(sp_off$y[sp_off$aux$idx$NH$soil_slow, "C"] -
                sp_on$y[sp_on$aux$idx$NH$soil_slow, "C"]), 1)
})

test_that("STOCK: exchanging + inert passive = the uncarved passive stock", {
  sp_on <- ccx_spinup(p_on); sp_off <- ccx_spinup(p_off)
  for (h in HEMIS) {
    ex  <- sp_on$y[sp_on$aux$idx[[h]]$soil_slow, "C"]
    unc <- sp_off$y[sp_off$aux$idx[[h]]$soil_slow, "C"]
    expect_equal(ex + sp_on$aux$soil_inert[[h]], unc, tolerance = 1e-12, info = h)
    expect_equal(sp_on$aux$soil_inert[[h]] / unc, F_ON, tolerance = 1e-12, info = h)
  }
  # the global inert mass at the defaults (NPP 60, 0.05, 500 yr): f * 1500
  expect_equal(sum(unlist(sp_on$aux$soil_inert)),
               F_ON * ccx_const("NPP_GLOBAL_PI") * p_on$litter_slow_frac * p_on$tau_soil_slow,
               tolerance = 1e-12)
  # NPP and total litter are unchanged: the vegetation pools agree to roundoff
  # (measured: leaf differs by 1 ulp, 3.6e-15 on 21.6 GtC, from the spinup's
  # own solve; wood is identical)
  for (h in HEMIS) for (pool in c("leaf", "wood"))
    expect_equal(sp_on$y[sp_on$aux$idx[[h]][[pool]], "C"],
                 sp_off$y[sp_off$aux$idx[[h]][[pool]], "C"], tolerance = 1e-13, info = paste(h, pool))
})

test_that("refuses a fraction outside [0, 1)", {
  for (bad in list(-0.1, 1, NA_real_, c(0.1, 0.2))) {
    p <- p_off; p$soil_inert_frac <- bad
    expect_error(ccx_litter_slow_eff(p), "soil_inert_frac", info = format(bad))
  }
})

test_that("PARITY: derivative, pro-rata LUC debit and trajectories agree with f ON", {
  skip_if_no_cpp()
  for (fw in c(1, 0)) {                       # wood-only and the pro-rata debit path
    p <- p_on; p$f_luc_wood <- fw
    sp <- ccx_spinup(p)
    dR <- ccx_deriv(sp$y, 1980.5, p, forc_open(sp), sp$grid, sp$aux)
    dC <- ccx_deriv_fast(sp$y, 1980.5, p, forc_open(sp), sp$grid, sp$aux)
    expect_lt(max(abs(dR - dC)) / max(abs(dR)), 5e-14)   # test-parity.R's PARITY_REL_TOL
  }
  sp <- ccx_spinup(p_on)
  F  <- ccx_build_forcing("historical", c(1900, 1980), prod_c14 = sp$prod_c14)
  rR <- suppressWarnings(ccx_run(sp, F)); rC <- suppressWarnings(ccx_run_fast(sp, F))
  for (cc in c("co2_NH", "co2_SH", "land_C", "ocean_C", "land_C14"))
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13, label = cc)
  expect_lt(max(abs(rR$out$d14c_NH - rC$out$d14c_NH)), 1e-8)
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
  # MUTATION: a C++ core that ignored the carve-out would run the OFF model.
  # The OFF trajectory must be far outside the parity tolerance of the ON one.
  rOff <- suppressWarnings(ccx_run_fast(ccx_spinup(p_off), F))
  expect_gt(max(abs(rOff$out$land_C - rC$out$land_C)) / max(abs(rC$out$land_C)), 1e-4)
})

test_that("CONSERVE: closed-system carbon is conserved with the carve-out ON", {
  closed <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
                 gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
  p <- ccx_set_enso(p_on, list(gamma_enso = 0))
  sp <- ccx_spinup(p)
  y <- sp$y
  # push it OUT of balance, as test-conservation.R does: move 200 GtC of
  # passive soil into the atmosphere
  for (h in HEMIS) {
    i <- sp$aux$idx[[h]]
    y[i$soil_slow, ] <- y[i$soil_slow, ] - 100 * y[i$soil_slow, ] / y[i$soil_slow, "C"]
    y[i$atm, ]       <- y[i$atm, ] + 100 * y[i$soil_slow, ] / y[i$soil_slow, "C"]
  }
  d <- ccx_deriv(y, 1900, p, closed, sp$grid, sp$aux)
  expect_lt(abs(sum(d[, "C"])) / max(abs(d[, "C"])), 1e-12)
  tot0 <- ccx_total(y); t <- 1900
  for (m in seq_len(12 * 50)) {
    y <- ccx_step_rk4(y, t, 1 / 12, p, closed, sp$grid, sp$aux); t <- t + 1 / 12
  }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
})

test_that("BOX: the inert box is pinned in the aseasonal spinup and carries C, 13C, 14C correctly", {
  sp <- ccx_spinup(p_on); ii <- ccx_inert_idx(sp$aux)
  expect_identical(rownames(sp$y)[ii], c("NH_soil_inert", "SH_soil_inert"))
  # appended LAST in each hemisphere: every other box keeps its pool-off name order
  expect_identical(rownames(sp$y)[-ii], ccx_box_names(N_INTERIOR))
  expect_equal(unname(sp$y[ii, "C"]), unname(unlist(sp$aux$soil_inert)), tolerance = 1e-14)
  expect_true(all(sp$y[ii, "C14"] == 0))
  for (h in HEMIS) {
    i <- sp$aux$idx[[h]]
    expect_equal(sp$y[i$soil_inert, "C13"] / sp$y[i$soil_inert, "C"],
                 sp$y[i$soil_slow, "C13"] / sp$y[i$soil_slow, "C"], tolerance = 1e-14, info = h)
  }
  d <- sp$diagnostics
  expect_lt(max(d$max_abs_dCdt, d$max_abs_dC13dt, d$max_abs_dC14dt), 1e-9)
  expect_equal(d$soil_inert_C_GtC, sum(sp$y[ii, "C"]))
  expect_equal(d$land_C_GtC, sum(sp$y[unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]]$land)), "C"]))
  expect_true(all(ii %in% unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]]$land))))
})

test_that("BOX: the periodic spinup pins it too, and its fixed point is the proxy's", {
  skip_if_no_cpp()
  ps_on <- ccx_periodic_spinup(p_on); ps_px <- ccx_periodic_spinup(p_prx)
  ii <- ccx_inert_idx(ps_on$aux)
  expect_equal(unname(ps_on$y[ii, "C"]), unname(unlist(ps_on$aux$soil_inert)), tolerance = 1e-12)
  expect_true(all(ps_on$y[ii, "C14"] == 0))
  expect_equal(ps_on$y[-ii, ], ps_px$y, tolerance = 1e-10)   # same orbit, solved independently
  r <- ps_on$diagnostics
  expect_lt(max(r$max_abs_dCdt, r$max_abs_dC13dt, r$max_abs_dC14dt), 1e-6)
})

test_that("BOX: both cores count it as LAND, never ocean, and carry it unchanged", {
  skip_if_no_cpp()
  sp <- ccx_spinup(p_on); ii <- ccx_inert_idx(sp$aux); inert <- sum(sp$y[ii, "C"])
  F  <- ccx_build_forcing("historical", c(1900, 1950), prod_c14 = sp$prod_c14)
  rR <- suppressWarnings(ccx_run(sp, F)); rC <- suppressWarnings(ccx_run_fast(sp, F))
  sq <- ccx_spinup(p_prx); rq <- suppressWarnings(ccx_run_fast(sq, F))
  for (r in list(rR, rC)) {
    expect_equal(r$out$land_C, rq$out$land_C + inert, tolerance = 1e-13)
    expect_equal(r$out$ocean_C, rq$out$ocean_C, tolerance = 1e-13)
    expect_equal(r$out$land_C14, rq$out$land_C14, tolerance = 1e-13)
    expect_identical(unname(r$state[ii, "C"]), unname(sp$y[ii, "C"]))
    expect_true(all(r$state[ii, "C14"] == 0))
  }
  expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
})

test_that("READOUT: ccx_stock_readout() covers every box once and matches the run columns", {
  skip_if_no_cpp()
  for (pp in list(p_off, p_on, local({ q <- p_on; q$hs_frac <- 0.1; q }))) {
    sp <- ccx_spinup(pp); st <- ccx_stock_readout(sp$y, sp$aux)
    expect_equal(st[["total"]], sum(sp$y[, "C"]), tolerance = 1e-12)
    expect_equal(st[["soil_inert"]], sum(sp$y[ccx_inert_idx(sp$aux), "C"]))
    F <- ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sp$prod_c14)
    r <- suppressWarnings(ccx_run_fast(sp, F)); se <- ccx_stock_readout(r$state, sp$aux)
    # the end state's readout vs the run's own last-month columns (the out row is the
    # month's OPENING state, so compare the readout of the state that produced it)
    expect_equal(ccx_stock_readout(sp$y, sp$aux)[["land_total"]], r$out$land_C[1], tolerance = 1e-12)
    expect_equal(ccx_stock_readout(sp$y, sp$aux)[["ocean_total"]], r$out$ocean_C[1], tolerance = 1e-12)
    expect_equal(se[["soil_inert"]], st[["soil_inert"]])
  }
  # MUTATION: a box the map does not classify must be REFUSED, not dropped
  sp <- ccx_spinup(p_on); aux <- sp$aux; aux$idx$NH[[CCX_LAND_INERT]] <- NULL
  expect_error(ccx_stock_readout(sp$y, aux), "does not cover the state")
})

test_that("the structure label switches it on at the cited value, and only there", {
  expect_identical(ccx_struct_block("hilda_csl3v0kai")$soil_inert_frac, F_ON)
  a <- ccx_struct_block("hilda_csl3v0ka"); b <- ccx_struct_block("hilda_csl3v0kai")
  expect_identical(setdiff(names(b), names(a)), "soil_inert_frac")
  expect_identical(b[names(a)], a)
  # the labels that carry the carve-out: kai, and the D2 / D3 label chained from it
  # (2026-09-30, objective #14; the 09-30c handoff's "extend the label ledgers deliberately")
  # + the land ENSO lag label chained from that (2026-10-02, objective #15; the 10-02 plan's
  #   "extend the four label ledgers")
  INERT_ON <- c("hilda_csl3v0kai", "hilda_csl3v0kaidgb", "hilda_csl3v0kaidgbe", "hilda_csl3v0kaidgbem", "hilda_csl3v0kaidgbemw", "hilda_csl3v0kaidgbemwt", "hilda_csl3v0kaidgbemwtc")  # + the redesigned cut (2026-10-07, objective #18; Marcus: "Full redesign (Recommended)", the name "hilda_csl3v0kaidgbemwt (Recommended)")   # + the interannual cut's main half (2026-10-06, objective #17; Marcus: "Build: land + ocean module (Recommended)", the name "hilda_csl3v0kaidgbemw (Recommended)")   # + the stratification feedback (2026-10-04; DESIGN §3.4a S; extension authorised by Marcus's ruling "History + futures, one #16 refit")
  for (lab in INERT_ON) expect_identical(ccx_struct_block(lab)$soil_inert_frac, F_ON, info = lab)
  for (lab in setdiff(CCX_STRUCT_LABELS, INERT_ON))
    expect_null(ccx_struct_block(lab)$soil_inert_frac, info = lab)
})
