# =====================================================================
# test-iav-redesign.R -- OBJECTIVE #18, THE REDESIGNED INTERANNUAL CUT (RULED 2026-10-07 f; Marcus: "Full redesign
# (Recommended)", the label "hilda_csl3v0kaidgbemwt (Recommended)"). R/likelihood.R "OBJECTIVE #18"; CHANGELOG
# 2026-10-07 (d)-(f). #18 = #17 (hilda_csl3v0kaidgbemw) + the DETRENDED ENSO index + `gcb_ocean_sink` scored on its
# LOW-PASS part. Every gate is a MUTATION test in the sense of [[mutation_test_gates]]: the property is broken inside
# the test and the gate must then fail.
#   IR1 THE LABEL       #17's block plus exactly the two fields; #17's gates; the detrended index; the ruled df
#   IR2 THE SWITCH      absent = `err` untouched (every other label); the label's block sets it
#   IR3 ABSENT          #17's basin B reproduces its stored logpost and rows BIT FOR BIT under its own label
#   IR4 ON = THE EMULATION  at basin B's vector with its own pins (P0) under #18: the logpost, the likelihood and every
#                       row reproduce the pricing's emulation, as do the reference (#18 minus the index) and B1;
#                       the switch moves ONLY the ocean row, by exactly its high part, on the row's own sd;
#                       MUTATIONS: the switch stripped -> the full row; the index stripped -> the reference
#   IR5 THE INDEX       reaches the objective's forcing and the dg path's; its trend over its own window is gone (the
#                       shipped index's is not); a shipped-index table is refused
#   IR6 THE dg PATH     dg_streams on a #18 vector gives the objective's rows; MUTATION: the switch stripped
#   IR7 THE GUARD       the cut's: under #18 the module's four names must ALL be pinned
# THE FIXTURE IS #17's BASIN B, named and md5-checked: the file the redesign was priced at (RULED 10-07 b, "B: better
# likelihood (Recommended)"), and the parity targets are the pricing's own rds (diag_iav_redesign_price.R @e891fa9),
# which ran the SAME objective path with the index as a base field and the row emulated by wrapping ccx_loglik().
# =====================================================================
skip_if_no_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
IR_LABEL      <- "hilda_csl3v0kaidgbemwt"
IR_PARENT     <- "hilda_csl3v0kaidgbemw"                      # #17
IR_FIELDS     <- c("enso_index", "gcb_ocean_lowpass_df")
IR_INDEX      <- "detrend"                                    # the redesign's index (CCX_ENSO_INDEX_CODES)
IR_ROW        <- "gcb_ocean_sink"
IR_MODE_B     <- ccx_path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds")
IR_MODE_B_MD5 <- "081eb16f4fe718692004fb1cf9645891"          # the file the 10-07 (b)/(d) tables name
IR_PRICE_RDS  <- ccx_path("outputs", "diagnostics", "iav_redesign_price_20261007.rds")
IR_PRICE_COMMIT <- "e891fa9"
# the objective's ~1e-6 NUMERICAL NOISE FLOOR: a reproduce-gate needs >= 1e-5 (memory
# objective_noise_floor_optimum_on_spike). The two effects the gates must see are 4.5 (the switch) and 12.3 (the index).
IR_REPRO_TOL  <- 1e-5
ir_obs <- ccx_prepare_obs()

ir_md <- local({ cache <- NULL; function() {
  if (is.null(cache)) {
    if (!identical(unname(tools::md5sum(IR_MODE_B)), IR_MODE_B_MD5)) stop("the fixture is not the file the pricing read")
    cache <<- readRDS(IR_MODE_B)
  }
  cache } })
ir_px <- local({ cache <- NULL; function() { if (is.null(cache)) cache <<- readRDS(IR_PRICE_RDS); cache } })
ir_p0 <- function(md = ir_md()) { p <- ccx_mode_pins(md); stats::setNames(as.numeric(unclass(p)), names(p)) }
#' basin B's vector scored under `struct` with `pins` (written onto the base, the convention every caller follows);
#' `strip` removes structure fields from the base (the MUTATIONS). Gate and pins are undone on exit, pins FIRST.
ir_eval <- function(struct, pins = ir_p0(), strip = NULL) {
  md <- ir_md()
  g <- ccx_apply_gate(struct); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);   on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  for (n in strip) bp[[n]] <- NULL
  bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), obs = ir_obs)
  v  <- lp(ccx_par_to_unc(ccx_mode_par_with_pins(md)))
  list(logpost = as.numeric(v), lik = attr(v, "loglik"), streams = unlist(attr(v, "streams")),
       forcing_index = attr(environment(lp)$base_forcing, "enso_index"))
}
ir_cache <- local({ cache <- list(); function(key, expr) {
  if (is.null(cache[[key]])) cache[[key]] <<- force(expr); cache[[key]] } })
ir_on   <- function() ir_cache("on",   ir_eval(IR_LABEL))
ir_ref  <- function() ir_cache("ref",  ir_eval(IR_LABEL, strip = "enso_index"))            # = the emulation's REF
ir_full <- function() ir_cache("full", ir_eval(IR_LABEL, strip = "gcb_ocean_lowpass_df"))  # #18's index, the row year by year
ir_own  <- function() ir_cache("own",  ir_eval(IR_PARENT))                                  # B under its own label

test_that("IR1 THE LABEL: #17's block plus exactly the two fields; #17's gates; the detrended index; the ruled df", {
  expect_true(IR_LABEL %in% CCX_STRUCT_LABELS)
  b_t <- ccx_struct_block(IR_LABEL); b_w <- ccx_struct_block(IR_PARENT)
  expect_identical(setdiff(names(b_t), names(b_w)), IR_FIELDS)
  expect_identical(b_t[names(b_w)], b_w)                                    # nothing else differs: the cut is #17's
  expect_identical(b_t$enso_index, CCX_ENSO_INDEX_CODES[[IR_INDEX]])
  expect_identical(b_t$enso_index, 1L)                                      # RULED: the 09-29 f axis's "detrend"
  expect_identical(b_t$gcb_ocean_lowpass_df, LIK_LAND_LOWPASS_DF)          # the land row's projector, unchanged
  expect_identical(b_t$gcb_ocean_lowpass_df, 6L)
  expect_identical(b_t$iav_cut, 1L)
  expect_identical(ccx_gates_open(IR_LABEL), ccx_gates_open(IR_PARENT))     # opens no gate
  # the labels built ON #18 carry its two fields unchanged; extending this is a DELIBERATE edit
  # 2026-10-22: + hilda_csl3v0kaidgbemwtcf, the flask label (...wtc's model and blocks, plus a likelihood switch)
  IR_CARRIERS <- c("hilda_csl3v0kaidgbemwtc", "hilda_csl3v0kaidgbemwtcf")  # + the citation batch (2026-10-12; Marcus: "New label (a) (Recommended)", the name "…wtc (c = cited)")
  for (lab in IR_CARRIERS) expect_identical(ccx_struct_block(lab)[IR_FIELDS], b_t[IR_FIELDS], info = lab)
  for (lab in setdiff(CCX_STRUCT_LABELS, c(IR_LABEL, IR_CARRIERS)))         # every other label: neither field
    expect_false(any(IR_FIELDS %in% names(ccx_struct_block(lab))), info = lab)
  p <- ccx_apply_structure(ccx_default_params(), IR_LABEL, seas_ml = "1")
  expect_identical(attr(p, "struct"), IR_LABEL)
  expect_identical(ccx_enso_index_of(p), IR_INDEX)
  expect_identical(ccx_enso_index_of(ccx_apply_structure(ccx_default_params(), IR_PARENT, seas_ml = "1")), "demean")
  expect_true(ccx_mix_on(p))                                                # it inherits #16's feedback
})

test_that("IR2 THE SWITCH: absent = err untouched; the label's block sets it beside #17's two", {
  err0 <- list(sigma_d14c = 1.5, rep_dC = 0.2, grad_off_co2 = 0, grad_off_d13c = 0)
  expect_identical(ccx_err_with_struct(err0, ccx_default_params()), err0)
  e17 <- ccx_err_with_struct(err0, ccx_apply_structure(ccx_default_params(), IR_PARENT, seas_ml = "1"))
  expect_null(e17$gcb_ocean_lowpass_df)                                     # #17: the ocean row year by year
  e18 <- ccx_err_with_struct(err0, ccx_apply_structure(ccx_default_params(), IR_LABEL, seas_ml = "1"))
  expect_identical(e18[names(e17)], e17)                                    # #17's switches, untouched
  expect_identical(setdiff(names(e18), names(e17)), "gcb_ocean_lowpass_df")
  expect_identical(e18$gcb_ocean_lowpass_df, 6L)
  expect_false(ccx_enso_slope_row_on(e18))                                  # the slope row stays in the module
})

test_that("IR3 ABSENT = BIT-IDENTICAL: #17's basin B reproduces its stored logpost and rows exactly under its own label", {
  md <- ir_md(); own <- ir_own()
  expect_identical(ccx_mode_struct(md), IR_PARENT)
  expect_identical(own$logpost, md$logpost)
  st <- unlist(md$streams)
  expect_identical(sort(names(own$streams)), sort(names(st)))
  expect_identical(own$streams[names(st)], st)
  expect_identical(own$forcing_index, "demean")
})

test_that("IR4 ON = THE EMULATION: at basin B under #18 the logpost, likelihood, every row, the reference and B1 reproduce the pricing", {
  px <- ir_px(); on <- ir_on(); ref <- ir_ref(); full <- ir_full(); own <- ir_own()
  expect_identical(px$provenance$commit, IR_PRICE_COMMIT); expect_false(px$provenance$smoke)
  expect_identical(px$provenance$mode_b_md5, IR_MODE_B_MD5)
  expect_identical(px$provenance$index, IR_INDEX); expect_identical(px$provenance$ocean_df, LIK_LAND_LOWPASS_DF)
  expect_identical(px$provenance$ocean_sd, LIK_GCB_OCEAN_SD)
  # the pricing's B1 IS #18 at B's own pins: logpost -1173.052374, likelihood -1137.127378 (handoff 10-07c s. 3.3)
  expect_lt(abs(on$logpost - px$b1$logpost_lp), IR_REPRO_TOL)
  expect_lt(abs(on$lik - px$b1$lik_lp), IR_REPRO_TOL)
  expect_identical(sort(names(on$streams)), sort(names(px$b1$st_lp)))
  expect_lt(max(abs(on$streams[names(px$b1$st_lp)] - px$b1$st_lp)), IR_REPRO_TOL)
  expect_lt(abs(on$streams[[IR_ROW]] - (-3.745088)), 1e-6)                 # the handoff's printed value (6 d.p.)
  expect_equal(on$lik, sum(on$streams), tolerance = 1e-13)
  # the REFERENCE (#18 minus the index = #17 + the low-pass ocean row, the shipped index) and B1 = -12.342383
  expect_lt(abs(ref$logpost - px$ref$logpost_lp), IR_REPRO_TOL)
  expect_lt(abs(ref$lik - px$ref$lik_lp), IR_REPRO_TOL)
  expect_lt(abs(ref$streams[[IR_ROW]] - px$ref$st_lp[[IR_ROW]]), IR_REPRO_TOL)
  expect_lt(abs((on$lik - ref$lik) - (px$b1$lik_lp - px$ref$lik_lp)), IR_REPRO_TOL)
  expect_lt(abs((on$lik - ref$lik) - (-12.342383)), 1e-6)
  # THE SWITCH MOVES ONLY THE OCEAN ROW, by exactly its high part, under either index
  oth <- setdiff(names(on$streams), IR_ROW)
  expect_identical(on$streams[oth], full$streams[oth])
  hp <- on$streams[[IR_ROW]] - full$streams[[IR_ROW]]                       # what the row's high part cost (added back)
  expect_lt(abs(full$streams[[IR_ROW]] - px$b1$st_full[[IR_ROW]]), IR_REPRO_TOL)   # -8.256639
  expect_lt(abs(hp - px$b1$high_cost), IR_REPRO_TOL)                        # 4.511551
  expect_gt(hp, 1)                                                          # MUTATION: the switch stripped -> the full row
  oth17 <- setdiff(names(own$streams), IR_ROW)                              # under the shipped index: #17's own rows
  expect_identical(ref$streams[oth17], own$streams[oth17])
  expect_lt(abs((ref$streams[[IR_ROW]] - own$streams[[IR_ROW]]) - px$ref$high_cost), IR_REPRO_TOL)   # 4.514590
  # MUTATION: the index stripped moves the likelihood by B1 -- the gate above has power
  expect_gt(abs(on$lik - ref$lik), 10)
  # THE SPLIT IS EXACT ON THE ROW'S OWN sd: the low-pass row = -n/2 log(2 pi sd^2) - |P e|^2 / (2 sd^2), from the
  # row's residuals as scored (ccx_loglik(residuals = TRUE)) over the row's own years (ccx_loglik()'s merge)
  v <- dg_vector(IR_MODE_B); for (f in IR_FIELDS) v$p[[f]] <- ccx_struct_block(IR_LABEL)[[f]]
  r <- dg_run(v); st <- dg_streams(r, v, obs = ir_obs, residuals = TRUE)
  e <- attr(st, "residuals")[[IR_ROW]][[1]]
  keep <- r$out$t < DG_SINK_LAST + 1
  g <- merge(merge(as.data.frame(ir_obs$gcb)[, c("year", "ocean_sink", "land_sink")], ccx_calendar_flux(r$out[keep, ]), by = "year"),
             ccx_forcing_eluc_annual(r$F[r$F$t < DG_SINK_LAST + 1, ]), by = "year")
  expect_identical(length(e), nrow(g))
  P <- ccx_lowpass_projector(g$year, LIK_LAND_LOWPASS_DF); s <- LIK_GCB_OCEAN_SD; n <- length(e)
  lo <- -n / 2 * log(2 * pi * s^2) - sum(as.numeric(P %*% e)^2) / (2 * s^2)
  expect_lt(abs(st[[IR_ROW]] - lo), 1e-9)
  expect_lt(abs(st[[IR_ROW]] - on$streams[[IR_ROW]]), IR_REPRO_TOL)
  # MUTATION: at the LAND row's sd the same construction misses by far more than the gate
  expect_gt(abs(st[[IR_ROW]] - (-n / 2 * log(2 * pi * (2 * s)^2) - sum(as.numeric(P %*% e)^2) / (2 * (2 * s)^2))), 1)
})

test_that("IR5 THE INDEX reaches every forcing build; its trend over its own window is gone; a shipped table is refused", {
  expect_identical(ir_on()$forcing_index, IR_INDEX)                         # the objective's own table
  expect_identical(ir_ref()$forcing_index, "demean")                        # MUTATION: the field stripped
  v <- dg_vector(IR_MODE_B); for (f in IR_FIELDS) v$p[[f]] <- ccx_struct_block(IR_LABEL)[[f]]
  r <- dg_run(v)
  expect_identical(attr(r$F, "enso_index"), IR_INDEX)                      # the dg path's table
  # the index's linear trend over FORC_ENSO_DEMEAN_WIN, the window its fit was taken on: gone (a law -- the residual of
  # a least-squares line has no slope), while the shipped index's is the +0.0083 K/yr that started this (10-07 b)
  slope <- function(index, win) { Fx <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                                                                           bomb_total_kmol = CCX_BOMB_REF, enso_index = index))
    k <- Fx$year >= win[1] & Fx$year <= win[2]; tt <- Fx$t[k]; unname(stats::coef(stats::lm(Fx$enso[k] ~ tt))[2]) }
  expect_lt(abs(slope(IR_INDEX, FORC_ENSO_DEMEAN_WIN)), 1e-10)
  expect_gt(abs(slope("demean", FORC_ENSO_DEMEAN_WIN)), 1e-3)              # MUTATION: the shipped index fails it
  # over the module's scored window (1959-2024) the pricing's recorded values reproduce
  tr <- ir_px()$trend
  expect_lt(abs(slope(IR_INDEX, c(1959, 2024)) - tr["redesign", "trend"]), 1e-12)
  expect_lt(abs(slope("demean", c(1959, 2024)) - tr["shipped", "trend"]), 1e-12)
  # a #18 parameter list refuses a table built with the shipped index (a missed consumer STOPS)
  F_s <- suppressWarnings(ccx_build_forcing("historical", c(1950, 1960), prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF))
  expect_error(ccx_enso_index_check(v$p, F_s), "ENSO index mismatch")
  expect_true(ccx_enso_index_check(v$p, r$F))
})

test_that("IR6 THE dg PATH: dg_streams on a #18 vector gives the objective's rows; MUTATION: the switch stripped", {
  on <- ir_on(); full <- ir_full()
  v <- dg_vector(IR_MODE_B); for (f in IR_FIELDS) v$p[[f]] <- ccx_struct_block(IR_LABEL)[[f]]
  r <- dg_run(v); s18 <- unlist(dg_streams(r, v, obs = ir_obs))
  expect_identical(sort(names(s18)), sort(names(on$streams)))
  expect_lt(max(abs(s18[names(on$streams)] - on$streams)), IR_REPRO_TOL)
  expect_false("gcb_ocean_enso_slope" %in% names(s18))
  v_m <- v; v_m$p$gcb_ocean_lowpass_df <- NULL
  s_m <- unlist(dg_streams(r, v_m, obs = ir_obs))
  expect_lt(abs(s_m[[IR_ROW]] - full$streams[[IR_ROW]]), IR_REPRO_TOL)
  expect_gt(abs(s_m[[IR_ROW]] - s18[[IR_ROW]]), 1)
  expect_identical(s_m[setdiff(names(s_m), IR_ROW)], s18[setdiff(names(s18), IR_ROW)])
})

test_that("IR7 THE GUARD: under #18 the module's four names must ALL be pinned", {
  md <- ir_md(); p0 <- ir_p0(md); ten <- p0[setdiff(names(p0), CCX_IAV_MODULE_NAMES)]
  build <- function(pins) {
    g <- ccx_apply_gate(IR_LABEL); on.exit(ccx_unapply_gate(g), add = TRUE)
    r <- ccx_apply_pins(pins);     on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
    bp <- ccx_apply_structure(ccx_default_params(), IR_LABEL, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
    for (n in names(pins)) bp[[n]] <- pins[[n]]
    bp$pump_mode <- md$pump_mode
    ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), obs = ir_obs)
  }
  expect_error(build(ten), "INTERANNUAL CUT.*FITTED here")                 # the module free
  for (n in CCX_IAV_MODULE_NAMES)                                          # any ONE left free
    expect_error(build(p0[setdiff(names(p0), n)]), "INTERANNUAL CUT", info = n)
  expect_true(is.function(build(p0)))
  # the launch side: #18's label with the module free is refused by the reference set, by name
  withr::local_envvar(CCX_MS_STRUCT = IR_LABEL, CCX_MS_PUMP_FIELD = "solved")
  # 2026-10-08 (e; Marcus: "Approve all five"): #16's ten match no ruled set since hilda29e, so they are refused BEFORE the
  # cut's check ("no registered incumbent"); the cut's refusal of a REGISTERED set that leaves the module free is NULL's
  expect_error(ccx_ms_reference_set(ten, "1"), "no registered incumbent")
  expect_error(ccx_ms_reference_set(NULL, "1"), "interannual CUT.*lag_enso_land")
})
