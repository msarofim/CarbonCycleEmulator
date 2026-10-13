# =====================================================================
# THE FLUX TRACE IS THE INTEGRAL THE INTEGRATOR TOOK -- AT THE CANONICAL.
#
# ⛔⛔ WHY THIS FILE EXISTS (2026-10-12, pre-beta code review, notes/code_review_2026-10-12.md §2 A5).
# test-fluxes.R runs at ccx_default_params(), where the structures that broke the trace are OFF.
# At the canonical (hilda29e: HS/HD, the seasonal mixed layer, the L2 ENSO limb, `mix`) it had
# three defects, and the app's box diagram printed two of them:
#   (b) the L2 limb wrote dy OUTSIDE the tap, so the trace missed up to 1.9 GtC/yr in an ENSO month;
#   (c) the trace was ONE snapshot per month at the opening state, which aliased the SH seasonal
#       mixed layer's entrainment (mixed-layer budget 1.208 GtC/yr in 2024 against an integrated 0.431);
#   (a) the warm "to the deep" arrow drew ml_int + pump, which include the cold route its cold
#       arrow draws again (ccx_flux_warm_route()).
# The windows straddle the 1997-98 El Nino, where the L2 limb's floor binds.
#
# THE TOLERANCE is an IDENTITY bound, derived rather than picked: the integrated flux and the state
# change are the same RK4 sum, so they differ only by the roundoff of differencing two stocks.
# FTX_ULPS ulps of the largest stock compared is that roundoff with a wide margin; the defects
# above were 1e6-1e7 times larger.
# =====================================================================
skip_if_no_cpp()
skip_if_no_climate()
source(ccx_path("calibration", "lib_design_gates.R"))

FTX_YEARS  <- c(1750, 1999)   # forcing built over the full record; the R-path window is the tail
FTX_SPLIT  <- 1996            # the traced window opens here (1996-1999: the 1997-98 El Nino)
FTX_ULPS   <- 1000
FTX_ENSO_MO <- c(1997, 12)    # an El Nino month (the reviewer's 1.565 GtC/yr tap gap was Dec 1997)

.v  <- dg_vector(CCX_MODE_CANONICAL)
.sp <- dg_spinup(.v)
.F  <- withCallingHandlers(
  ccx_build_forcing("historical", FTX_YEARS, prod_c14 = .sp$prod_c14,
                    bomb_total_kmol = .v$bomb_total, luc_scale = .v$luc_scale,
                    enso_index = ccx_enso_index_of(.v$p), aod_mode = ccx_aod_mode_of(.v$p), nuc_share = ccx_nuc_share_of(.v$p)),
  warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
.k  <- which(floor(.F$t + 1e-9) == FTX_SPLIT)[1] - 1L
.F1 <- .F[seq_len(.k), ]; .F2 <- .F[(.k + 1L):nrow(.F), ]
# the app's own continuation (app/global.R APP_FLUX): the C++ core to the split, the R core after,
# carrying the ENSO history and the deep-ocean temperature
.s2 <- .sp
.s2$y <- ccx_run_fast(.sp, .F1)$state
.s2$enso_hist <- ccx_enso_hist_after(.F1$enso, .sp$enso_hist)
if (ccx_mix_on(.sp$params)) .s2$tdeep0 <- ccx_mix_tdeep_after(.F1$gmst, .F1$t, .sp$params, .sp$tdeep0)
# ccx_deriv needs the columns ccx_run() adds to its forcing (the lagged land ENSO input, the
# stratification g). The identities below hold for ANY forcing carrying them, so this mirrors
# ccx_run() only to have them, not to reproduce its numbers.
.F2d <- ccx_fill_prod_c14(.F2, .s2)
.F2d$land_enso <- ccx_land_enso(.F2d$enso, ccx_enso_lag_of(.s2$params), .s2$enso_hist)
.F2d[["mix_g"]] <- if (ccx_mix_on(.s2$params)) as.numeric(ccx_mix_g_series(.F2d$gmst, .F2d$t, .s2$params, .s2$tdeep0)) else NULL
.r <- ccx_run(.s2, .F2, fluxes = TRUE, flux_method = "rk4",
              edge_fn = function(fl, y, t) list(ch = fl$channels, y = y, t = t))
.tr <- .r$fluxes; .o <- .r$out
.n  <- nrow(.o)
# month-end values: the next month's opening state, and the run's final state for the last month
.aux <- .s2$aux
.ocean_idx <- unlist(lapply(HEMIS, function(h) c(.aux$idx[[h]]$ml, .aux$idx[[h]]$oc, .aux$idx[[h]]$hs, .aux$idx[[h]]$hd)))
.land_idx  <- unlist(lapply(HEMIS, function(h) .aux$idx[[h]]$land))
.surf_idx  <- unlist(lapply(HEMIS, function(h) c(.aux$idx[[h]]$ml, .aux$idx[[h]]$hs)))
.stock <- function(col_out, idx) c(.o[[col_out]], sum(.r$state[idx, "C"]))
.surf  <- c(rowSums(sapply(HEMIS, function(h) .o[[paste0("ml_C_", h)]] + .o[[paste0("hs_C_", h)]])),
            sum(.r$state[.surf_idx, "C"]))
.tol <- function(s) FTX_ULPS * .Machine$double.eps * max(abs(s))

test_that("the canonical runs the structures the trace broke on (else this file has no power)", {
  # 2026-10-13 (g): re-expressed to hilda31w (Marcus: "Approve all (Recommended)"); the structure checks below are the power
  expect_identical(CCX_MODE_CANONICAL, "hilda31w")
  expect_true(isTRUE(.aux$hs_on == 1L))
  expect_true(isTRUE(.aux$l2_on == 1L))
  expect_true(ccx_seas_ml_on(.sp$params))
  expect_equal(length(.surf), .n + 1L)
})

test_that("the RK4 trace leaves the trajectory bit-identical (it records; it does not integrate)", {
  r0 <- ccx_run(.s2, .F2)
  expect_identical(.r$out, r0$out)
  expect_identical(.r$state, r0$state)
})

test_that("each month's integrated fluxes ARE its state change: ocean, land, and the surface boxes", {
  dt <- 1 / 12
  d_ocean <- diff(.stock("ocean_C", .ocean_idx))
  d_land  <- diff(.stock("land_C", .land_idx))
  d_surf  <- diff(.surf)
  expect_lt(max(abs(.tr$ocean_net * dt - d_ocean)), .tol(.o$ocean_C))
  expect_lt(max(abs(.tr$land_net  * dt - d_land)),  .tol(.o$land_C))
  # the surface boxes (low-latitude mixed layer + cold surface) gain air-sea and lose ml_int + pump:
  # the split the aliasing broke, and the one the box diagram prints
  surf_flux <- .tr$as_down - .tr$as_up - .tr$ml_int - .tr$pump
  expect_lt(max(abs(surf_flux * dt - d_surf)), .tol(.surf))
})

test_that("POWER: the old opening-state snapshot fails the surface identity by far more than the bound", {
  # the snapshot the trace used to be, read through the run's own edge hook at each opening state
  snap <- t(vapply(.r$edge_trace, function(e)
    c(e$ch[["as_down"]] - e$ch[["as_up"]] - e$ch[["ml_int"]] - e$ch[["pump"]]), numeric(1)))
  expect_gt(max(abs(as.numeric(snap) / 12 - diff(.surf))), 1e6 * .tol(.surf))
})

test_that("the tap is COMPLETE at the canonical in an El Nino month (the L2 limb records)", {
  i <- which(floor(.F2$t + 1e-9) == FTX_ENSO_MO[1])[FTX_ENSO_MO[2]]
  e <- .r$edge_trace[[i]]
  expect_gt(abs(.F2$enso[i]), 1)                       # an ENSO month, so the limb is live
  dy <- ccx_deriv(e$y, e$t, .s2$params, ccx_forcing_at(.F2d, i),
                  .s2$grid, .aux, record = TRUE)
  expect_equal(attr(dy, "fluxes")$boxnet, unname(dy[, "C"]), tolerance = 0)
})

test_that("the warm route equals a direct sum over the low-latitude edges", {
  i <- which(floor(.F2$t + 1e-9) == FTX_ENSO_MO[1])[FTX_ENSO_MO[2]]
  e <- .r$edge_trace[[i]]
  dy <- ccx_deriv(e$y, e$t, .s2$params, ccx_forcing_at(.F2d, i),
                  .s2$grid, .aux, record = TRUE)
  fl <- attr(dy, "fluxes")
  snap <- c(ccx_flux_derive(fl$channels, e$y, .aux), ccx_flux_hs_derive(fl$edges, fl$pump_edges, .aux))
  E <- fl$edges; P <- fl$pump_edges; U <- E - P        # unlabelled = everything but the pump
  pump_w <- 0; mlint_w <- 0
  for (h in HEMIS) {
    ml <- .aux$idx[[h]]$ml + 1L; oc <- .aux$idx[[h]]$oc + 1L
    pump_w  <- pump_w  + sum(P[ml, oc]) - sum(P[oc, ml])
    mlint_w <- mlint_w + sum(U[ml, oc]) - sum(U[oc, ml])
  }
  wr <- ccx_flux_warm_route(snap)
  scale <- max(abs(c(snap[["pump"]], snap[["ml_int"]])))
  expect_lt(abs(wr[["pump"]]   - pump_w),  1e-12 * scale)
  expect_lt(abs(wr[["ml_int"]] - mlint_w), 1e-12 * scale)
  # and the cold route is non-trivial here, or the subtraction was never tested
  expect_gt(abs(snap[["hs_pump"]]), 1)
})
