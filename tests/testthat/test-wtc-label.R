# =====================================================================
# LABEL hilda_csl3v0kaidgbemwtc (2026-10-12): the cited constants, routed by label.
# Marcus, verbatim: "New label (a) (Recommended)"; the name "…wtc (c = cited)".
# Ledger: notes/citation_rulings_2026-10-12.md. Every changed value enters through a
# structure field whose ABSENCE is the old value, so what this file guards is, per item:
#   * ABSENT  = the legacy objective, bit for bit (every registered mode);
#   * PRESENT = the ruled value, read from its data product, never typed twice;
#   * the switch is LIVE (it moves the number it claims to move) -- a power check.
# =====================================================================

# ---- the column depth: GLODAP target products ------------------------------------------
test_that("GLODAP products: the depth key snaps to a built set, and an unbuilt depth STOPS", {
  expect_identical(ccx_glodap_depth_key(NULL), CCX_GLODAP_DEPTH_LEGACY)
  expect_identical(ccx_glodap_depth_key(3682.2 + 1e-9), 3682.2)
  expect_error(ccx_glodap_depth_key(3690), "no GLODAP target products")
  expect_identical(basename(ccx_glodap_file("obs_glodap_deep", 3700)), "obs_glodap_deep.rds")
  expect_identical(basename(ccx_glodap_file("obs_glodap_deep", 3682.2)), "obs_glodap_deep_3682.2m.rds")
  for (stem in c("obs_glodap_deep", "obs_glodap_intermediate", "obs_glodap_profile_cov", "obs_glodap_sigma_rep"))
    for (d in CCX_GLODAP_DEPTHS) expect_true(file.exists(ccx_glodap_file(stem, d)), info = paste(stem, d))
})

test_that("GLODAP products at 3682.2 m: the layer follows the column, and the targets move by << sigma", {
  a <- ccx_deep_d14c_target(); b <- ccx_deep_d14c_target(depth = 3682.2)
  expect_identical(a$layer, c(top = 2627.2, bottom = 3700))
  expect_identical(b$layer, c(top = 2614.7, bottom = 3682.2))
  g75 <- ccx_ocean_grid(75, total_depth = 3682.2)
  expect_equal(b$layer[["top"]], sum(g75$dz[-length(g75$dz)]), tolerance = 0.05 / 2614.7)
  expect_false(identical(a$target, b$target))                       # LIVE: the product differs
  expect_lt(abs(a$target - b$target), 0.05 * a$sd)                  # ... by far less than its sigma
  m <- ccx_mid_d14c_target(depth = 3682.2)
  expect_identical(m$slabs$bot[2], b$layer[["top"]])                # slab B ends where the deep row begins
  expect_identical(m$slabs$stream[2], "d14c_mid_2000_2615")
  expect_identical(ccx_mid_d14c_target()$slabs$stream[2], "d14c_mid_2000_2627")
  # the profile covariance embeds the three targets of ITS column (the spec's own consistency check)
  expect_silent(ccx_profile_d14c_spec(depth = 3682.2))
  expect_silent(ccx_profile_d14c_spec())
  ga <- ccx_ocean_gradient_target(); gb <- ccx_ocean_gradient_target(3682.2)
  expect_false(identical(ga$dic$target, gb$dic$target))
  expect_lt(abs(ga$dic$target - gb$dic$target), 0.05 * ga$dic$sd)
  expect_false(identical(ccx_ocean_sigma_eff("dic", 64.6), ccx_ocean_sigma_eff("dic", 64.6, depth = 3682.2)))
})

test_that("ccx_loglik refuses an ocean-gradient bundle built on another column", {
  obs <- ccx_prepare_obs()
  err <- list(sigma_d14c = 10, rep_dC = 0.1, grad_off_co2 = 0, grad_off_d13c = 0)   # the mode-file shape
  bundle <- list(dic = 200, d13c = -0.8, alk = 0, sd_eff = c(dic = 26, d13c = 0.12, alk = 19.2), h_ml = 64.6)
  out <- data.frame(year = numeric(0))
  b2 <- bundle; b2$ocean_depth <- 3682.2
  expect_error(ccx_loglik(out, obs, err, ocean_grad = b2), "built on a 3682.2 m column")
  e2 <- err; e2$ocean_depth <- 3682.2
  expect_error(ccx_loglik(out, obs, e2, ocean_grad = bundle), "built on a 3700 m column")
})

# ---- IntCal: the published D14C sigma -----------------------------------------------------
test_that("IntCal v2: the legacy columns are the shipped table's, and sd_d14c is column 5", {
  leg <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_intcal20.rds")))
  v2  <- readRDS(ccx_path("data", "obs_d14c_intcal20_v2.rds"))
  expect_identical(as.numeric(v2$year), as.numeric(leg$year))
  expect_identical(v2$d14c, leg$d14c)
  expect_identical(as.numeric(v2$err), as.numeric(leg$err))
  sc <- v2$year >= 1750 & v2$year < 1941
  expect_true(all(v2$sd_d14c[sc] >= 1.1 & v2$sd_d14c[sc] <= 1.4))  # permil, IntCal20 column 5
  expect_true(all(v2$err[sc] >= 9))                                 # the age sigma, in YEARS
  expect_identical(attr(v2, "provenance")$file_sha256,
                   "974a66649f2ac8a53e6c99e256b019ac6982f999b12dcf7193162d4c1c09168e")
})

# ---- the structure block -------------------------------------------------------------------
WTC_LABEL  <- "hilda_csl3v0kaidgbemwtc"
WTC_PARENT <- "hilda_csl3v0kaidgbemwt"
WTC_FIELDS <- c("alk_surface", "carb_salinity", "ocean_depth", "sst_seas_lag_NH", "sst_seas_lag_SH",
                "nuc_share_ts", "pump_eps13_org", "intcal_sd_published", "wtc_free")

test_that("THE BLOCK: #18's plus the ruled fields, every value read from its product or the registry", {
  b <- ccx_struct_block(WTC_LABEL); b0 <- ccx_struct_block(WTC_PARENT)
  expect_identical(setdiff(names(b), names(b0)), WTC_FIELDS)
  expect_identical(setdiff(names(b0), "alpha_photo_eps"), setdiff(names(b0), "alpha_photo_eps"))
  for (n in setdiff(names(b0), "alpha_photo_eps")) expect_identical(b[[n]], b0[[n]], info = n)
  sa <- readRDS(ccx_path("data", "obs_glodap_surface_alk_sal.rds"))
  expect_identical(b$alk_surface, ccx_const("ALK_SURFACE_GLODAP"))
  expect_equal(ccx_const("ALK_SURFACE_GLODAP"), sa$alk_ruled_umolkg * 1e-6, tolerance = 1e-15)
  expect_lt(abs(sa$alk_umolkg - 2303.4), 0.05)                       # the measurement rounds to the ruling
  expect_identical(b$carb_salinity, ccx_const("SALINITY_SURFACE_GLODAP"))
  expect_identical(ccx_const("SALINITY_SURFACE_GLODAP"), sa$salinity_ruled)
  expect_identical(ccx_carb_coefs_for(b$carb_salinity)$salinity, 34.760)
  expect_identical(b$ocean_depth, ccx_const("OCEAN_DEPTH_CS2010"))
  expect_true(b$ocean_depth %in% CCX_GLODAP_DEPTHS)                  # its target products exist
  expect_identical(unname(c(b$sst_seas_lag_NH, b$sst_seas_lag_SH)), unname(ccx_sst_seas_lag_obs()))
  expect_equal(b$sst_seas_lag_SH, 1.536, tolerance = 5e-4)            # the ledger's verified value
  expect_equal(b$sst_seas_lag_NH, 1.325, tolerance = 5e-4)
  expect_identical(b$alpha_photo_eps, ccx_const("ALPHA_PHOTO_EPS_STILL2003"))
  expect_identical(b$pump_eps13_org, ccx_const("PUMP_EPS13_ORG_CLARET2021"))
  expect_identical(ccx_nuc_share_of(b), "per_year")
  expect_identical(ccx_gated_names(WTC_LABEL), c(ccx_gated_names(WTC_PARENT), names(CCX_PARAM_GATED_WTC)))
  # the gate's literals are the registry's, and its inits are the box midpoints
  expect_identical(CCX_PARAM_GATED_WTC$bomb_share_NH$lo, ccx_const("BOMB_NH_SHARE_PRIOR_LO"))
  expect_identical(CCX_PARAM_GATED_WTC$bomb_share_NH$hi, ccx_const("BOMB_NH_SHARE_PRIOR_HI"))
  for (g in CCX_PARAM_GATED_WTC) expect_equal(g$init, (g$lo + g$hi) / 2)
  # the legacy registry values did NOT move (the absent-field defaults)
  expect_identical(ccx_const("ALK_SURFACE"), 2300e-6); expect_identical(ccx_const("OCEAN_DEPTH"), 3700)
  expect_identical(ccx_const("ALPHA_PHOTO_EPS"), 18); expect_identical(ccx_const("PUMP_EPS13_ORG"), -20)
  expect_identical(ccx_default_params()$bomb_share_NH, FORC_BOMB_NH_SHARE)
  expect_identical(ccx_default_params()$seas_T_lag, CCX_SEAS_T_LAG)
  # the ledger: every other label carries none of the fields
  for (lab in setdiff(CCX_STRUCT_LABELS, WTC_LABEL))
    expect_false(any(WTC_FIELDS %in% names(ccx_struct_block(lab))), info = lab)
})

# a fixture: the canonical's vector under the NEW label, the two new names OFF their legacy values
wtc_fix <- local({ f <- NULL; function() {
  if (is.null(f)) {
    md <- readRDS(ccx_mode_file()); md2 <- md; md2$struct <- WTC_LABEL
    pm <- ccx_mode_par_with_pins(md)
    if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
    pm[["bomb_share_NH"]] <- 0.85; pm[["seas_T_lag"]] <- 2.7
    rp <- ccx_mode_run_params(md2, pm, base = ccx_mode_base(md2)); p <- rp$p
    sp <- suppressWarnings(ccx_spinup_from_label(ccx_mode_spinup(md2))(p))
    F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = rp$bomb_total,
                           luc_scale = rp$luc_scale, enso_index = ccx_enso_index_of(p),
                           aod_mode = ccx_aod_mode_of(p), nuc_share = ccx_nuc_share_of(p))
    f <<- list(p = p, sp = sp, F = F, rp = rp)
  }
  f } })

test_that("THE RUN: the label's run carries every field into the prepared model", {
  skip_if_no_cpp()
  fx <- wtc_fix(); p <- fx$p; a <- fx$sp$aux
  expect_identical(attr(p, "struct"), WTC_LABEL)
  expect_identical(p$bomb_share_NH, 0.85); expect_identical(ccx_seas_t_lag(p), 2.7)
  expect_identical(a$bomb_share_NH, 0.85)
  expect_equal(sum(fx$sp$grid$dz), 3682.2, tolerance = 1e-12)
  expect_identical(ccx_aux_alk(a), ccx_const("ALK_SURFACE_GLODAP"))
  expect_identical(ccx_aux_carb(a)$salinity, 34.760)
  expect_identical(ccx_aux_pump_eps13_org(a), -22)
  expect_identical(a$alpha_photo, 1 - 16.2 / 1000)
  expect_identical(attr(fx$F, "nuc_share"), "per_year")
  ns <- readRDS(ccx_path("data", "forcing_nuc_nh_share.rds"))
  expect_identical(unique(fx$F$nuc_share_NH[fx$F$year == 1984]), ns$nh_share[ns$year == 1984])
  # a 'constant' table is REFUSED under this label (the stamp check)
  Fc <- ccx_build_forcing("historical", c(1750, 1760), prod_c14 = fx$sp$prod_c14,
                          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  expect_error(ccx_run_fast(fx$sp, Fc), "nuclear 14C share mismatch")
  # a grid that is not the structure's column is refused
  expect_error(ccx_prepare(p, ccx_ocean_grid(p$h_ml)), "structure's column")
})

test_that("R <-> C++ PARITY UNDER THE LABEL: 1983-2003, the per-year nuclear share and both fitted names live", {
  skip_if_no_cpp()
  fx <- wtc_fix(); p <- fx$p; sp <- fx$sp; F <- fx$F
  i0 <- which(F$t >= 1983)[1]
  Fa <- F[seq_len(i0 - 1L), ]; Fb <- F[i0:(i0 + 20L * 12L - 1L), ]
  s2 <- sp; s2$y <- ccx_run_fast(sp, Fa)$state
  s2$enso_hist <- ccx_enso_hist_after(Fa$enso, sp$enso_hist)
  s2$tdeep0    <- ccx_mix_tdeep_after(Fa$gmst, Fa$t, p, sp$tdeep0)
  rC <- ccx_run_fast(s2, Fb)
  rR <- withCallingHandlers(ccx_run(s2, Fb), warning = function(w)
    if (grepl("Temperature outside fitted range [2.0, 35.0] degC; extrapolating.",
              conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))
  expect_false(isTRUE(rC$retried))
  rel <- function(a, b) max(abs(a - b)) / max(abs(a))
  # test-parity.R's tolerances, unchanged
  expect_lt(rel(rR$out$co2_NH, rC$out$co2_NH), 1e-13); expect_lt(rel(rR$out$co2_SH, rC$out$co2_SH), 1e-13)
  expect_lt(max(abs(rR$out$d13c_NH - rC$out$d13c_NH)), 1e-9); expect_lt(max(abs(rR$out$d13c_SH - rC$out$d13c_SH)), 1e-9)
  expect_lt(max(abs(rR$out$d14c_NH - rC$out$d14c_NH)), 1e-8); expect_lt(max(abs(rR$out$d14c_SH - rC$out$d14c_SH)), 1e-8)
  for (tr in CCX_TRACERS) expect_lt(rel(rR$state[, tr], rC$state[, tr]), 1e-13, label = paste("final state", tr))
  # POWER: the per-year share moves the SH D14C far above the parity bound over this window
  Fk <- Fb; Fk$nuc_share_NH <- NaN; attr(Fk, "nuc_share") <- "per_year"
  expect_gt(max(abs(ccx_run_fast(s2, Fk)$out$d14c_SH - rC$out$d14c_SH)), 1e-6)
})

test_that("EACH FIELD IS LIVE: removing it moves the derivative (or the row) it claims to move", {
  skip_if_no_cpp()
  fx <- wtc_fix(); p <- fx$p; sp <- fx$sp; F <- fx$F
  # 1964, not later: the bomb delivery series (Tans 1981) is ZERO by the 1980s, so the bomb share is
  # dead there by construction; 1964 has the bomb, nuclear (NH-only years) and every other channel
  i <- which(F$t >= 1964)[1]
  y <- ccx_run_fast(sp, F[seq_len(i - 1L), ])$state
  pt <- function(pp, FF = F) {
    FF$land_enso <- ccx_land_enso(FF$enso, ccx_enso_lag_of(pp), sp$enso_hist)
    if (ccx_mix_on(pp)) FF[["mix_g"]] <- as.numeric(ccx_mix_g_series(FF$gmst, FF$t, pp, sp$tdeep0))
    ccx_forcing_at(FF, i)
  }
  d <- function(pp, FF = F) suppressWarnings(ccx_deriv(y, F$t[i], pp, pt(pp, FF), sp$grid, ccx_prepare(pp, sp$grid)))
  d0 <- d(p)
  legacy <- list(alk_surface = NULL, carb_salinity = NULL, sst_seas_lag_NH = NULL, sst_seas_lag_SH = NULL,
                 alpha_photo_eps = 15.6, pump_eps13_org = NULL, bomb_share_NH = FORC_BOMB_NH_SHARE,
                 seas_T_lag = CCX_SEAS_T_LAG)
  for (n in names(legacy)) {
    q <- p; q[n] <- list(legacy[[n]])
    expect_gt(max(abs(d(q) - d0)), 0, label = n)
  }
  # the per-year nuclear share at a year with a SH source (1964's share is 1.0: SH reports begin 1983)
  j <- which(F$t >= 1990)[1]; yj <- ccx_run_fast(sp, F[seq_len(j - 1L), ])$state
  Fk <- F; Fk$nuc_share_NH <- NaN                                   # the per-year share, removed
  dj <- function(FF) { i <<- j; on.exit(i <<- which(F$t >= 1964)[1])
    suppressWarnings(ccx_deriv(yj, F$t[j], p, pt(p, FF), sp$grid, ccx_prepare(p, sp$grid))) }
  expect_gt(max(abs(dj(Fk)[, "C14"] - dj(F)[, "C14"])), 0, label = "nuc_share_ts")
  # the column depth: the grid IS the structure's
  expect_false(isTRUE(all.equal(sum(ccx_grid_of(p)$dz), sum(ccx_ocean_grid(p$h_ml)$dz))))
})
