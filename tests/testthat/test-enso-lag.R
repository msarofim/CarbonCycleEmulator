# =====================================================================
# test-enso-lag.R -- W1 (2026-10-02): the LAND ENSO LAG `lag_enso_land`, DESIGN's L_MEI
# (Marcus 10-02: "Do it right. Option 2"; CHANGELOG 10-02 x/z).
# R/model.R ccx_enso_lagged() / ccx_land_enso() / ccx_point_land_enso(); the runners in
# R/forcing.R (ccx_run) and R/cpp.R (ccx_run_prepared, ccx_deriv_fast); src/ccx_core.cpp's
# land term; the SECOND label gate in R/calibrate.R (CCX_PARAM_GATES, "hilda_csl3v0kaidgbe").
#
#   INTERP   exact at integer L; through every node; C1 in L across an integer (with a
#            linear-interpolation control that FAILS it, so the check has power); causal
#            (no row reads a later row, for any L); the history used before row 1.
#   OFF      lag 0 and lag absent are the index itself: identical() runs in both cores.
#   PARITY   R <-> C++ at a single derivative and over a trajectory, lag on and absent; the
#            land term reads `land_enso`, every ocean box keeps reading `enso`.
#   EXACT    at an integer L the run IS a lag-0 run whose index is shifted L months (ocean
#            ENSO coefficients 0, so the shifted column reaches the land only).
#   SEGMENT  a run split MID-RECORD and continued with ccx_enso_hist_after() is the unsplit
#            run, bit for bit, in both cores; without the history it is REFUSED; held, it
#            differs (the history has power).
#   SWITCH   the What-if ENSO switch zeroes the land input too: the lag is inert under it.
#   TRACE    ccx_run(fluxes = TRUE)'s trace reads the lagged input.
#   GUARDS   a bare point forcing, or a flattened nonzero index, under a lag is refused.
#   CONSERVE closed-system carbon is conserved with the lag on.
#   GATE     the lag gate's ledger; the spec tied to CCX_ENSO_LAG_MAX; apply / undo exact;
#            the per-gate logpost guard; a kaidgb file read under the open lag gate.
# ⚠ The land ENSO coefficients DEFAULT TO 0, so every model test here sets them nonzero
# (a test at defaults has no power) and runs a window past 1948, where the index starts.
# =====================================================================

EL_GAMMA_LAND <- c(NH = 0.6, SH = 0.9)      # GtC/yr per index unit, nonzero on purpose
EL_LAG_FRAC   <- 4.3                         # a fractional lag, months
EL_LAG_INT    <- 3                           # an integer lag, months

.el_p <- function(lag = NULL) {
  p <- ccx_default_params()
  p$gamma_enso_land_NH <- EL_GAMMA_LAND[["NH"]]; p$gamma_enso_land_SH <- EL_GAMMA_LAND[["SH"]]
  p$lag_enso_land <- lag                     # NULL deletes the slot: ABSENT
  p
}
.el_spin <- function(sp, lag) { sp$params$lag_enso_land <- lag; sp }
.el_forcing <- function(sp, years = c(1940, 1975))
  suppressWarnings(ccx_build_forcing("historical", years, prod_c14 = sp$prod_c14))
.el_x <- function(n = 200) sin(seq(0, 20, length.out = n)) + 0.3 * cos(seq(0, 77, length.out = n))
.el_lin <- function(x, L, hist) {            # the control: LINEAR interpolation, kinked at integers
  z <- c(hist, x); H <- length(hist); pos <- H + seq_along(x) - L; k <- floor(pos); s <- pos - k
  (1 - s) * z[k] + s * z[pmin(k + 1, length(z))]
}

test_that("INTERP: exact at integer L, through the nodes, the history before row 1", {
  x <- .el_x(); h <- seq(-1.3, -0.1, length.out = CCX_ENSO_HIST_N)
  expect_identical(ccx_enso_lagged(x, 0, h), x)                                  # OFF = the input
  for (L in 1:CCX_ENSO_LAG_MAX) {
    v <- ccx_enso_lagged(x, L, h)
    expect_identical(v[(L + 1):length(x)], x[1:(length(x) - L)], info = L)     # an exact SHIFT
    expect_identical(v[1:L], utils::tail(h, L), info = L)                        # ... into the history
  }
  # no history = the first value held back in time
  expect_identical(ccx_enso_lagged(x, 2), c(x[1], x[1], x[1:(length(x) - 2)]))
  # a short history is padded with its own first value
  expect_identical(ccx_enso_lagged(x, 3, c(7, 8)), c(7, 7, 8, x[1:(length(x) - 3)]))
  # past the history is an error, not a silent read
  expect_error(ccx_enso_lagged(x, CCX_ENSO_LAG_MAX + 0.5, h), "outside the history")
})

test_that("INTERP: C1 in L across an integer, and CAUSAL for every L (with a control that fails C1)", {
  x <- .el_x(); h <- seq(-1.3, -0.1, length.out = CCX_ENSO_HIST_N); e <- 1e-6
  for (L0 in c(1, 4, 11)) {
    left  <- (ccx_enso_lagged(x, L0, h) - ccx_enso_lagged(x, L0 - e, h)) / e
    right <- (ccx_enso_lagged(x, L0 + e, h) - ccx_enso_lagged(x, L0, h)) / e
    expect_lt(max(abs(left - right)), 1e-3, label = paste("Hermite kink at", L0))
    # POWER: the same probe on LINEAR interpolation sees the kink this scheme removes
    lk <- (.el_lin(x, L0, h) - .el_lin(x, L0 - e, h)) / e - (.el_lin(x, L0 + e, h) - .el_lin(x, L0, h)) / e
    expect_gt(max(abs(lk)), 1e-2, label = paste("linear kink at", L0))
    # continuous in value too
    expect_lt(max(abs(ccx_enso_lagged(x, L0 + 1e-9, h) - ccx_enso_lagged(x, L0, h))), 1e-6)
  }
  # CAUSAL: moving rows after i never moves row i -- including 0 < L < 1, where a
  # central-difference (Catmull-Rom) stencil would read row i + 1
  for (L in c(0.25, 0.5, 0.999, 1.5, EL_LAG_FRAC, 11.9)) {
    v <- ccx_enso_lagged(x, L, h); x2 <- x; x2[101:200] <- x2[101:200] + 5
    expect_identical(ccx_enso_lagged(x2, L, h)[1:100], v[1:100], info = L)
    expect_false(isTRUE(all.equal(ccx_enso_lagged(x2, L, h)[101:200], v[101:200])), info = L)
  }
})

test_that("OFF: lag 0 and lag absent are the index itself, identical() in both cores", {
  skip_if_no_cpp()
  sp <- ccx_spinup(.el_p()); F <- .el_forcing(sp)
  expect_null(.el_p()$lag_enso_land)                                             # truly absent
  expect_identical(ccx_default_params()$lag_enso_land, 0)                        # the MODEL_SLOTS slot
  expect_identical(ccx_land_enso(F$enso, 0), F$enso)
  sa <- sp; s0 <- .el_spin(sp, 0)
  expect_identical(ccx_run_fast(sa, F)$out, ccx_run_fast(s0, F)$out)
  expect_identical(ccx_run_fast(sa, F)$state, ccx_run_fast(s0, F)$state)
  Fr <- .el_forcing(sp, c(1955, 1958))
  expect_identical(ccx_run(sa, Fr)$out, ccx_run(s0, Fr)$out)
})

test_that("PARITY: R <-> C++ at one derivative and over a trajectory; land reads land_enso, the ocean enso", {
  skip_if_no_cpp()
  p <- .el_p(EL_LAG_FRAC); p$gamma_enso_ocn_NH <- 0.18; p$gamma_enso_ocn_SH <- -0.09   # ocean ON, signed
  sp <- ccx_spinup(p); F <- .el_forcing(sp); i <- which(F$year == 1958)[1]
  f <- ccx_forcing_at(F, i); f$enso <- -0.4; f$land_enso <- 1.7                    # SET, distinct
  dR <- ccx_deriv(sp$y, F$t[i], p, f, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, F$t[i], p, f, sp$grid, sp$aux)
  for (tr in CCX_TRACERS)
    expect_lt(max(abs(dR[, tr] - dC[, tr])), 1e-9 * max(abs(dR[, tr])) + 1e-12, label = tr)
  # the land term moves with land_enso and the ocean boxes do not; the ocean moves with enso
  f2 <- f; f2$land_enso <- -1.1
  oc <- unlist(lapply(HEMIS, function(h) c(sp$aux$idx[[h]]$ml, sp$aux$idx[[h]]$oc)))
  ld <- unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]][c("leaf", "wood")]))
  for (d in list(ccx_deriv, ccx_deriv_fast)) {
    a <- d(sp$y, F$t[i], p, f, sp$grid, sp$aux); b <- d(sp$y, F$t[i], p, f2, sp$grid, sp$aux)
    expect_identical(a[oc, ], b[oc, ])
    expect_gt(max(abs(a[ld, "C"] - b[ld, "C"])), 0.5)
    f3 <- f; f3$enso <- 1.2; c3 <- d(sp$y, F$t[i], p, f3, sp$grid, sp$aux)
    expect_gt(max(abs(a[oc, "C"] - c3[oc, "C"])), 1e-3)
    expect_identical(a[ld, ], c3[ld, ])
  }
  # trajectory, lag on and absent (a window that opens before the index, 1946)
  for (lag in list(NULL, EL_LAG_FRAC, EL_LAG_INT)) {
    s <- .el_spin(sp, lag); Ft <- .el_forcing(sp, c(1946, 1956))
    rR <- suppressWarnings(ccx_run(s, Ft)); rC <- suppressWarnings(ccx_run_fast(s, Ft))
    for (cc in c("co2_NH", "co2_SH", "d13c_NH", "d13c_SH", "d14c_NH", "land_C", "ocean_C"))
      expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) / max(abs(rR$out[[cc]])), 1e-13,
                label = paste(cc, "lag", format(lag)))
    expect_lt(max(abs(rR$state - rC$state)) / max(abs(rR$state)), 1e-13)
  }
})

test_that("EXACT: at an integer L the run IS a lag-0 run on the index shifted L months", {
  skip_if_no_cpp()
  sp <- ccx_spinup(.el_p()); F <- .el_forcing(sp)                     # 1940: 8 index-free years first
  expect_true(all(F$enso[F$year < 1948] == 0))
  Fs <- F; Fs$enso <- c(rep(F$enso[1], EL_LAG_INT), utils::head(F$enso, -EL_LAG_INT))
  rL <- ccx_run_fast(.el_spin(sp, EL_LAG_INT), F); r0 <- ccx_run_fast(.el_spin(sp, 0), Fs)
  expect_identical(rL$out, r0$out); expect_identical(rL$state, r0$state)
  # POWER: the lag moves the run by far more than roundoff
  expect_gt(max(abs(rL$out$co2_NH - ccx_run_fast(.el_spin(sp, 0), F)$out$co2_NH)), 0.05)
  # the R core, on a short window
  Fw <- .el_forcing(sp, c(1946, 1952)); Fws <- Fw
  Fws$enso <- c(rep(Fw$enso[1], EL_LAG_INT), utils::head(Fw$enso, -EL_LAG_INT))
  expect_identical(ccx_run(.el_spin(sp, EL_LAG_INT), Fw)$out, ccx_run(.el_spin(sp, 0), Fws)$out)
})

test_that("SEGMENT: a run split mid-record and continued with its history IS the unsplit run", {
  skip_if_no_cpp()
  sp <- .el_spin(ccx_spinup(.el_p()), EL_LAG_FRAC); F <- .el_forcing(sp)
  k <- which(F$year == 1960)[1] - 1L; n <- nrow(F)
  F1 <- F[seq_len(k), ]; F2 <- F[(k + 1L):n, ]
  expect_false(isTRUE(all(utils::head(F2$enso, CCX_ENSO_HIST_N) == F2$enso[1])))   # MID-record
  full <- ccx_run_fast(sp, F)
  r1 <- ccx_run_fast(sp, F1)
  s2 <- sp; s2$y <- r1$state; s2$enso_hist <- ccx_enso_hist_after(F1$enso, sp$enso_hist)
  r2 <- ccx_run_fast(s2, F2)
  expect_identical(r2$state, full$state)
  expect_identical(unname(as.matrix(r2$out)), unname(as.matrix(full$out[(k + 1L):n, ])))
  # without the history: REFUSED, not held
  s2n <- s2; s2n$enso_hist <- NULL
  expect_error(ccx_run_fast(s2n, F2), "OPENS MID-RECORD")
  # held on purpose: it runs, and it differs -- the history has power
  s2h <- s2; s2h$enso_hist <- "hold"
  expect_gt(max(abs(ccx_run_fast(s2h, F2)$out$co2_NH - full$out$co2_NH[(k + 1L):n])), 1e-4)
  # the R core: the same continuation on a short window (1946 opens index-free; split 1950)
  Fw <- .el_forcing(sp, c(1946, 1952)); kw <- which(Fw$year == 1950)[1] - 1L; nw <- nrow(Fw)
  fw <- ccx_run(sp, Fw); w1 <- ccx_run(sp, Fw[seq_len(kw), ])
  sw <- sp; sw$y <- w1$state; sw$enso_hist <- ccx_enso_hist_after(Fw$enso[seq_len(kw)], sp$enso_hist)
  w2 <- ccx_run(sw, Fw[(kw + 1L):nw, ])
  expect_identical(w2$state, fw$state)
  expect_identical(unname(as.matrix(w2$out)), unname(as.matrix(fw$out[(kw + 1L):nw, ])))
  sw$enso_hist <- NULL
  expect_error(ccx_run(sw, Fw[(kw + 1L):nw, ]), "OPENS MID-RECORD")
})

test_that("SWITCH: the What-if ENSO switch zeroes the land input too -- the lag is inert under it", {
  skip_if_no_cpp()
  sp <- ccx_spinup(.el_p()); F <- .el_forcing(sp)
  run_off <- function(lag) {
    m <- ccx_apply_mechanisms(.el_p(lag), F, "enso"); s <- sp; s$params <- m$p
    ccx_run_fast(s, m$F)
  }
  a <- run_off(EL_LAG_FRAC); b <- run_off(0)
  expect_identical(a$out, b$out)
  # POWER: with the switch NOT applied the same two lags differ
  expect_gt(max(abs(ccx_run_fast(.el_spin(sp, EL_LAG_FRAC), F)$out$co2_NH -
                    ccx_run_fast(.el_spin(sp, 0), F)$out$co2_NH)), 0.05)
})

test_that("TRACE: the flux trace reads the lagged land input", {
  sp <- ccx_spinup(.el_p()); Fw <- .el_forcing(sp, c(1946, 1950))
  Fws <- Fw; Fws$enso <- c(rep(Fw$enso[1], EL_LAG_INT), utils::head(Fw$enso, -EL_LAG_INT))
  tL <- ccx_run(.el_spin(sp, EL_LAG_INT), Fw, fluxes = TRUE)$fluxes
  tS <- ccx_run(.el_spin(sp, 0), Fws, fluxes = TRUE)$fluxes
  expect_identical(tL, tS)                                       # the trace sees the SHIFT
  t0 <- ccx_run(.el_spin(sp, 0), Fw, fluxes = TRUE)$fluxes
  expect_gt(max(abs(tL$gpp - t0$gpp)), 0.1)                      # ... and it has power
})

test_that("GUARDS: a lag meeting a bare point forcing or a flattened nonzero index is refused", {
  skip_if_no_cpp()
  p <- .el_p(EL_LAG_FRAC); sp <- ccx_spinup(p); F <- .el_forcing(sp); i <- which(F$year == 1958)[1]
  f <- ccx_forcing_at(F, i)
  expect_null(f$land_enso)                                       # a table no runner touched
  expect_error(ccx_deriv(sp$y, F$t[i], p, f, sp$grid, sp$aux), "LAGGED")
  expect_error(ccx_deriv_fast(sp$y, F$t[i], p, f, sp$grid, sp$aux), "LAGGED")
  fv <- ccx_cpp_forcing_vec(f); fv[match("enso", CCX_FORCING_COLS)] <- 0.8
  expect_error(ccx_deriv_fast(sp$y, F$t[i], p, fv, sp$grid, sp$aux), "FLATTENED")
  fv[match("enso", CCX_FORCING_COLS)] <- 0                       # the spinup's quiet constant: fine
  expect_error(ccx_deriv_fast(sp$y, F$t[i], p, fv, sp$grid, sp$aux), NA)
  # unlagged, the same bare forcing is the index itself (the pre-W1 contract)
  expect_error(ccx_deriv(sp$y, F$t[i], .el_p(0), f, sp$grid, sp$aux), NA)
  # the parameter's own range
  for (bad in list(-0.1, CCX_ENSO_LAG_MAX + 0.1, NA_real_, c(1, 2)))
    expect_error(ccx_enso_lag_of(list(lag_enso_land = bad)), "not one number")
  # the land series' mid-record guard, and its two answers
  Fm <- .el_forcing(sp, c(1960, 1965))
  expect_error(ccx_land_enso(Fm$enso, EL_LAG_FRAC), "OPENS MID-RECORD")
  expect_identical(ccx_land_enso(Fm$enso, EL_LAG_FRAC, "hold"), ccx_enso_lagged(Fm$enso, EL_LAG_FRAC))
  expect_identical(ccx_land_enso(Fm$enso, 0), Fm$enso)           # unlagged needs no history
})

test_that("CONSERVE: closed-system carbon is conserved with the lag on", {
  p <- .el_p(EL_LAG_FRAC); sp <- ccx_spinup(p)
  closed <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
                 gmst = 0, enso = 0.3, land_enso = 1.9, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
  d <- ccx_deriv(sp$y, 1960, p, closed, sp$grid, sp$aux)
  expect_lt(abs(sum(d[, "C"])) / max(abs(d[, "C"])), 1e-12)
  y <- sp$y; tot0 <- ccx_total(y); t <- 1960
  for (m in seq_len(12 * 10)) { y <- ccx_step_rk4(y, t, 1 / 12, p, closed, sp$grid, sp$aux); t <- t + 1 / 12 }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
})

# the ledger: the labels that OPEN THE LAG GATE. Extending it is a DELIBERATE edit.
EL_LAG_OPEN_LABELS <- c("hilda_csl3v0kaidgbe", "hilda_csl3v0kaidgbem", "hilda_csl3v0kaidgbemw", "hilda_csl3v0kaidgbemwt")  # + the redesigned cut (2026-10-07, objective #18; Marcus: "Full redesign (Recommended)", the name "hilda_csl3v0kaidgbemwt (Recommended)")   # + the interannual cut's main half (2026-10-06, objective #17; Marcus: "Build: land + ocean module (Recommended)", the name "hilda_csl3v0kaidgbemw (Recommended)")   # + the stratification feedback (2026-10-04; DESIGN §3.4a S; extension authorised by Marcus's ruling "History + futures, one #16 refit")

test_that("GATE: the ledger, the spec tied to its constants, apply / undo exact", {
  opened <- CCX_STRUCT_LABELS[vapply(CCX_STRUCT_LABELS, ccx_gate_open, logical(1),
                                     flag = CCX_GATE_FLAG_ENSO_LAG)]
  expect_identical(opened, EL_LAG_OPEN_LABELS)
  expect_identical(ccx_gates_open("hilda_csl3v0kaidgbe"), c(CCX_GATE_FLAG, CCX_GATE_FLAG_ENSO_LAG))
  expect_identical(ccx_gates_open("hilda_csl3v0kaidgb"), CCX_GATE_FLAG)
  expect_identical(ccx_gates_open("hilda_csl3v0kai"), character(0))
  expect_identical(ccx_gated_names("hilda_csl3v0kaidgbe"), c(names(CCX_PARAM_GATED), "lag_enso_land"))
  expect_true(ccx_gate_open("hilda_csl3v0kaidgbe"))             # the default flag: D2/D3
  # the new label is kaidgb's block plus its flag, nothing else
  a <- ccx_struct_block("hilda_csl3v0kaidgb"); b <- ccx_struct_block("hilda_csl3v0kaidgbe")
  expect_identical(b[names(a)], a)
  expect_identical(setdiff(names(b), names(a)), CCX_GATE_FLAG_ENSO_LAG)
  # the spec: logit on (0, CCX_ENSO_LAG_MAX), init the prior MIDPOINT, the prior FLAT on it
  s <- CCX_PARAM_GATED_ENSO_LAG$lag_enso_land
  expect_identical(s$tr, "logit")
  expect_identical(c(s$lo, s$hi), c(0, CCX_ENSO_LAG_MAX))
  expect_identical(s$init, CCX_ENSO_LAG_MAX / 2)
  expect_equal(vapply(c(0.5, 6, 11.5), s$prior, 0), rep(-log(CCX_ENSO_LAG_MAX), 3), tolerance = 1e-12)
  expect_identical(s$prior(13), -Inf)
  expect_identical(CCX_PARAM_GATED_ALL$lag_enso_land, s)
  expect_false(anyDuplicated(names(CCX_PARAM_GATED_ALL)) > 0)
  # apply / undo: the lag label appends the four AND the lag, in order, and undoes exactly
  tab0 <- CCX_PARAM_TABLE; nm0 <- CCX_PARAM_NAMES
  h <- ccx_apply_gate("hilda_csl3v0kaidgbe"); on.exit(ccx_unapply_gate(h), add = TRUE)
  expect_identical(h, c(names(CCX_PARAM_GATED), "lag_enso_land"))
  expect_identical(CCX_PARAM_NAMES, c(nm0, h))
  expect_error(ccx_apply_gate("hilda_csl3v0kaidgbe"), "applied ONCE")
  expect_error(ccx_apply_gate("hilda_csl3v0kaidgb"), "applied ONCE")   # a PARTIAL re-apply too
  ccx_unapply_gate(h); h <- character(0)
  expect_identical(CCX_PARAM_TABLE, tab0); expect_identical(CCX_PARAM_NAMES, nm0)
  # the order a pinned lag returns to
  expect_identical(utils::tail(.CCX_PARAM_ORDER, 1), "lag_enso_land")
})

test_that("GATE: the objective refuses the lag fitted under kaidgb, and missing under kaidgbe", {
  skip_if_no_cpp()
  bd <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kaidgb", seas_ml = "1")
  be <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0kaidgbe", seas_ml = "1")
  hd <- ccx_apply_gate("hilda_csl3v0kaidgb"); on.exit(ccx_unapply_gate(hd), add = TRUE)
  # kaidgbe with only the D2/D3 gate applied: the lag is not fitted -> refused, by the flag
  expect_error(ccx_make_logpost(base_params = be, spinup_fn = ccx_spinup),
               "OPENS the gate \\(enso_lag_free")
  ccx_unapply_gate(hd); hd <- character(0)
  he <- ccx_apply_gate("hilda_csl3v0kaidgbe"); on.exit(ccx_unapply_gate(he), add = TRUE)
  # kaidgb with the lag fitted -> refused: a holding structure with a fitted lag
  expect_error(ccx_make_logpost(base_params = bd, spinup_fn = ccx_spinup),
               "lag_enso_land are in the fitted set .* HOLDS them \\(no enso_lag_free")
  # the open label builds, and a draw at the init runs the lag at its init
  lp <- ccx_make_logpost(base_params = be, spinup_fn = ccx_spinup, by_stream = TRUE)
  u <- ccx_init_unc()
  expect_identical(ccx_unc_to_par(u)$lag_enso_land, CCX_ENSO_LAG_MAX / 2)
  a <- lp(u)
  expect_true(is.finite(a))
  # THE FITTED LAG REACHES THE MODEL (MODEL_SLOTS needs ccx_default_params()'s slot): a
  # different lag moves the land-carrying rows. The table's land ENSO inits are nonzero.
  expect_gt(abs(ccx_unc_to_par(u)$gamma_enso_land_SH), 0.1)
  u1 <- u; u1[["lag_enso_land"]] <- .to_unc(1, CCX_PARAM_GATED_ENSO_LAG$lag_enso_land)
  b <- lp(u1)
  expect_gt(max(abs(unlist(attr(a, "streams")) - unlist(attr(b, "streams")))), 1e-3)
  # ... and the overlay copies it WITH THE GATE CLOSED (CCX_PARAM_GATED_ALL): a vector fitted under
  # the open label, read in a process that never opened it, must still run its own lag. (With the
  # gate open the table loop copies it anyway, so the check is only meaningful closed -- the first
  # cut of this test ran it open and SURVIVED the mutation that drops the lag from the gated loop.)
  pm <- ccx_unc_to_par(u1)
  ccx_unapply_gate(he); he <- character(0)
  expect_false("lag_enso_land" %in% CCX_PARAM_NAMES)
  expect_identical(ccx_overlay_par(ccx_default_params(), pm)$lag_enso_land, pm$lag_enso_land)
})

test_that("GATE: a kaidgb file read under the open lag gate lacks only the lag, filled 0, seeded at init", {
  md <- readRDS(ccx_mode_file("hilda33d"))
  expect_identical(ccx_mode_struct(md), "hilda_csl3v0kaidgb")
  # its BASE (the one resolver, ccx_mode_base(); test-mode-struct-lint) opens the D2/D3 gate only
  expect_identical(ccx_gates_open(ccx_mode_base(md)), CCX_GATE_FLAG)
  he <- ccx_apply_gate("hilda_csl3v0kaidgbe"); on.exit(ccx_unapply_gate(he), add = TRUE)
  expect_identical(intersect(ccx_param_absent_ok(md), "lag_enso_land"), "lag_enso_land")
  expect_identical(ccx_mode_absent(md), "lag_enso_land")         # the process fits it; the file lacks it
  expect_true(ccx_mode_carries_build(md))                        # ... and may: its OWN structure held it
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  expect_identical(pm$lag_enso_land, 0)                          # what the file RAN
  expect_true("lag_enso_land" %in% attr(pm, "migrated"))
  r <- ccx_apply_pins(ccx_mode_pins(md))
  invisible(utils::capture.output(st <- ccx_mode_start(md, "test")))
  ccx_unpin_params(r)
  expect_identical(st$p$lag_enso_land, CCX_ENSO_LAG_MAX / 2)     # 0 is the logit floor: SEEDED
  for (n in md$param_names) expect_identical(st$p[[n]], md$par_mode[[n]], info = n)
  # a file whose OWN structure opens the lag gate must carry the lag
  md_e <- md; md_e$struct <- "hilda_csl3v0kaidgbe"
  expect_identical(ccx_mode_absent(md_e), "lag_enso_land")
  expect_false(ccx_mode_carries_build(md_e))
  # ... and read with the lag gate CLOSED it is refused for the right reason
  ccx_unapply_gate(he); he <- character(0)
  hd <- ccx_apply_gate("hilda_csl3v0kaidgb"); on.exit(ccx_unapply_gate(hd), add = TRUE)
  expect_error(ccx_gate_require(md_e, "test"), "OPENS the gate \\(d2d3_free, enso_lag_free\\).*lag_enso_land")
})
