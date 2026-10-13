# =====================================================================
# test-canonical-contracts.R -- DESIGN sec.6 gates 1-2 and the R <-> C++ parity, run ON THE
# CANONICAL (2026-10-12; Marcus: "§6 canonical-path tests").
#
# WHY. The pre-beta code review (notes/code_review_2026-10-12.md sec.6) found that the
# conservation, parity and spin-up tests all run the 32-box DEFAULTS: no HS/HD boxes, no inert
# soil, no seasonal mixed layer or entrainment, no L2 limb, no N deposition, no ENSO terms, no
# lagged land ENSO, no stratification feedback -- none of what the canonical runs. The reviewers
# measured each contract CLEAN at the canonical; nothing pinned it. These tests pin it, at the
# canonical named by ccx_mode_file() (so they follow the next adoption without an edit).
#
# BOUNDS. Conservation and drift use DESIGN sec.6 gate 1's "~1e-10 relative" contract (and the
# 1e-12-relative-to-the-largest-tendency form test-conservation.R already uses); parity uses
# test-parity.R's tolerances unchanged. None is fitted to these measurements; each was measured
# at least 10x inside (CHANGELOG 2026-10-12 (aa)), and each has a power check below.
# =====================================================================

cc_fix <- local({ f <- NULL; function() {
  if (is.null(f)) {
    md <- readRDS(ccx_mode_file())
    pm <- ccx_mode_par_with_pins(md)
    if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
    rp <- ccx_mode_run_params(md, pm, base = ccx_mode_base(md)); p <- rp$p
    sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
    F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                            bomb_total_kmol = rp$bomb_total, luc_scale = rp$luc_scale,
                            enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p), nuc_share = ccx_nuc_share_of(p))
    f <<- list(md = md, p = p, sp = sp, F = F)
  }
  f } })

# The point forcing a RUNNER would hand ccx_deriv(): the lagged land ENSO input and the
# stratification factor are runner-written columns (R/forcing.R ccx_forcing_at()).
cc_point <- function(fx, i, zero_sources) {
  F <- fx$F; p <- fx$p
  F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(p), fx$sp$enso_hist)
  if (ccx_mix_on(p)) F[["mix_g"]] <- as.numeric(ccx_mix_g_series(F$gmst, F$t, p, fx$sp$tdeep0))
  fi <- ccx_forcing_at(F, i)
  if (zero_sources) {
    fi$e_foss <- list(NH = 0, SH = 0); fi$e_luc <- list(NH = 0, SH = 0)
    fi$c14_bomb <- 0; fi$c14_nuclear <- 0; fi$c14_cosmo <- 0; fi$sink_ocean <- 0
  }
  fi
}

test_that("GATE 1 AT THE CANONICAL: every tracer closes in ccx_deriv() with the sources off", {
  skip_if_no_cpp()
  fx <- cc_fix(); p <- fx$p; sp <- fx$sp; F <- fx$F
  lam <- ccx_const("LAMBDA_C14")
  i98 <- which(F$t >= 1998)[1]
  y98 <- ccx_run_fast(sp, F[seq_len(i98 - 1L), ])$state            # a realistic transient state
  pts <- list(spun_up_1750 = list(y = sp$y, i = 1L),
              el_nino_dec1997 = list(y = y98, i = i98 - 1L),
              min_enso_month = list(y = y98, i = which.min(F$enso)))
  for (nm in names(pts)) {
    y <- pts[[nm]]$y; i <- pts[[nm]]$i
    d <- ccx_deriv(y, F$t[i], p, cc_point(fx, i, TRUE), sp$grid, sp$aux)
    expect_lt(abs(sum(d[, "C"]))   / max(abs(d[, "C"])),   1e-12, label = paste(nm, "12C"))
    expect_lt(abs(sum(d[, "C13"])) / max(abs(d[, "C13"])), 1e-12, label = paste(nm, "13C"))
    # 14C closes INCLUDING decay: sum(dC14) = -lambda sum(C14) with production off
    expect_lt(abs(sum(d[, "C14"]) + lam * sum(y[, "C14"])) / max(abs(d[, "C14"])), 1e-12,
              label = paste(nm, "14C"))
  }
  # POWER: with the sources ON the 12C sum is exactly the fossil source (land use is a transfer),
  # so the same sum sees a source of known size
  i <- i98 - 1L; fi <- cc_point(fx, i, FALSE)
  d <- ccx_deriv(y98, F$t[i], p, fi, sp$grid, sp$aux)
  ef <- fi$e_foss$NH + fi$e_foss$SH
  expect_gt(ef, 1)
  expect_lt(abs(sum(d[, "C"]) - ef) / ef, 1e-12)
})

test_that("GATE 2 AT THE CANONICAL: no drift in any box or isotope over 50 quiet years on its periodic orbit", {
  skip_if_no_cpp()
  fx <- cc_fix(); p <- fx$p; sp <- fx$sp
  expect_identical(sp$periodic$kind, "periodic")                    # the objective's spinup
  Fq <- ps_year_forcing(sp$prod_c14)
  drift <- function(y0, n = 50L) {
    y <- y0
    for (k in seq_len(n)) y <- ps_phi(y, p, sp$aux, sp$grid, Fq)$state
    # per box and per tracer, relative to that box's own content: covers every reservoir AND
    # every isotope ratio (a ratio drifts by at most the sum of its two tracers' drifts)
    max(vapply(CCX_TRACERS, function(tr) {
      nz <- y0[, tr] != 0
      max(abs(y[nz, tr] - y0[nz, tr]) / abs(y0[nz, tr]))
    }, numeric(1)))
  }
  expect_lt(drift(sp$y), 1e-10)                                      # DESIGN gate 1's contract
  # POWER: the ASEASONAL fixed point is NOT on the seasonal orbit (the 09-09v/F2 defect this gate
  # exists for: a +2.45 ppm rectified offset), and from it the same 50 years MUST drift
  sa <- ccx_spinup(p)
  expect_gt(drift(sa$y), 1e-6)
})

test_that("R <-> C++ PARITY AT THE CANONICAL: 1955-1975 from one transient state", {
  skip_if_no_cpp()
  fx <- cc_fix(); p <- fx$p; sp <- fx$sp; F <- fx$F
  i0 <- which(F$t >= 1955)[1]
  Fa <- F[seq_len(i0 - 1L), ]; Fb <- F[i0:(i0 + 20L * 12L - 1L), ]
  s2 <- sp; s2$y <- ccx_run_fast(sp, Fa)$state
  s2$enso_hist <- ccx_enso_hist_after(Fa$enso, sp$enso_hist)         # the lagged land term's memory
  s2$tdeep0    <- ccx_mix_tdeep_after(Fa$gmst, Fa$t, p, sp$tdeep0)   # the stratification feedback's
  rC <- ccx_run_fast(s2, Fb)
  # The R core warns once per evaluation that the HS box (1.6-3.3 degC at the canonical, review
  # sec.4) is below the [2, 35] degC fitted range of a temperature fit -- 480 times here. A KNOWN,
  # documented extrapolation that both cores share (only R says so); muffled by its exact text only.
  rR <- withCallingHandlers(ccx_run(s2, Fb), warning = function(w)
    if (grepl("Temperature outside fitted range [2.0, 35.0] degC; extrapolating.",
              conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))
  expect_false(isTRUE(rC$retried))                                   # no NA-retry: one integrator
  rel <- function(a, b) max(abs(a - b)) / max(abs(a))
  # test-parity.R's tolerances, unchanged
  expect_lt(rel(rR$out$co2_NH, rC$out$co2_NH), 1e-13)
  expect_lt(rel(rR$out$co2_SH, rC$out$co2_SH), 1e-13)
  expect_lt(max(abs(rR$out$d13c_NH - rC$out$d13c_NH)), 1e-9)
  expect_lt(max(abs(rR$out$d13c_SH - rC$out$d13c_SH)), 1e-9)
  expect_lt(max(abs(rR$out$d14c_NH - rC$out$d14c_NH)), 1e-8)
  expect_lt(max(abs(rR$out$d14c_SH - rC$out$d14c_SH)), 1e-8)
  expect_lt(rel(rR$out$ocean_C, rC$out$ocean_C), 1e-13)
  expect_lt(rel(rR$out$land_C,  rC$out$land_C),  1e-13)
  for (tr in CCX_TRACERS)
    expect_lt(rel(rR$state[, tr], rC$state[, tr]), 1e-13, label = paste("final state", tr))
  # POWER: the window is long enough to separate the cores if one integrated a different model --
  # one month of difference in the start state is many orders above the bound
  s3 <- s2; s3$y <- ccx_run_fast(s2, Fb[1, , drop = FALSE])$state
  expect_gt(rel(rC$state[, "C"], ccx_run_fast(s3, Fb)$state[, "C"]), 1e-9)
})
