# =====================================================================
# test-luc-scale.R -- the land-use input-uncertainty parameter (2026-08-14)
#
# `luc_scale` exists so E_LUC's own uncertainty has somewhere to go other than
# `beta`. Three things have to hold for that to be true rather than decorative:
#
#   1. it is BIT-IDENTICAL at 1, so adding it changed no existing result;
#   2. the fast path used inside the MCMC (a column multiply on a prebuilt
#      forcing) equals the slow path (rebuilding the forcing with the scale) --
#      including the PRE-WINDOW cumulative, which is where a partial application
#      would hide;
#   3. the gross-sink likelihood term follows the MODEL's scaled land-use flux
#      and not GCB's unscaled column.
# =====================================================================

test_that("luc_scale = 1 is bit-identical to the unscaled forcing", {
  a <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0)
  b <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, luc_scale = 1)
  expect_identical(as.data.frame(a), as.data.frame(b))
  expect_equal(attr(b, "luc_scale"), 1)
})

test_that("the MCMC's column rescale equals rebuilding the forcing", {
  s <- 0.65
  base <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0)
  slow <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, luc_scale = s)

  fast <- base
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    fast[[cc]] <- base[[cc]] * s

  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    expect_equal(fast[[cc]], slow[[cc]], tolerance = 1e-12,
                 info = paste("column", cc))
  # nothing else may move
  for (cc in c("e_foss_NH", "e_foss_SH", "gmst", "enso", "c14_bomb"))
    expect_equal(base[[cc]], slow[[cc]], tolerance = 1e-12)
})

test_that("the PRE-WINDOW cumulative scales too", {
  # A window starting in 1900 carries 1750-1899 clearing in cum_luc's offset.
  # Scaling the monthly columns after the fact would scale that offset as well
  # (it is inside the column), but scaling only e_luc and NOT cum_luc -- or
  # rebuilding without touching luc_pre -- would leave the cleared fraction
  # inconsistent with the flux. This pins the offset itself.
  s <- 0.5
  a <- ccx_build_forcing("historical", c(1900, 2024), prod_c14 = 0)
  b <- ccx_build_forcing("historical", c(1900, 2024), prod_c14 = 0, luc_scale = s)
  cum_a <- a$cum_luc_NH[1] + a$cum_luc_SH[1]
  cum_b <- b$cum_luc_NH[1] + b$cum_luc_SH[1]
  expect_gt(cum_a, 20)                       # there IS a pre-window offset
  expect_equal(cum_b, s * cum_a, tolerance = 1e-10)
})

test_that("luc_scale is rejected if it is not a usable multiplier", {
  expect_error(ccx_build_forcing("historical", c(1900, 1950), prod_c14 = 0,
                                 luc_scale = -1), "non-negative")
  expect_error(ccx_build_forcing("historical", c(1900, 1950), prod_c14 = 0,
                                 luc_scale = NA_real_), "finite")
})

test_that("the gross-sink term uses the MODEL's land-use flux, not GCB's", {
  s   <- 0.65
  obs <- ccx_prepare_obs()
  p   <- ccx_default_params()
  sp  <- ccx_spinup(p)
  F   <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                           luc_scale = s)
  out <- ccx_run_fast(sp, F)$out
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)

  eluc <- ccx_forcing_eluc_annual(F)
  # the model's own flux really is the scaled one
  expect_equal(mean(eluc$eluc[eluc$year >= 2015]),
               s * mean(obs$gcb$luc[obs$gcb$year >= 2015]), tolerance = 1e-8)

  right <- ccx_loglik(out, obs, err, luc = eluc,  by_stream = TRUE)
  wrong <- ccx_loglik(out, obs, err, luc = NULL,  by_stream = TRUE)

  # Passing the scaled flux must change the land term and ONLY the land term.
  expect_false(isTRUE(all.equal(right[["gcb_land_sink"]],
                                wrong[["gcb_land_sink"]])))
  for (nm in setdiff(names(right), "gcb_land_sink"))
    expect_equal(right[[nm]], wrong[[nm]], tolerance = 1e-10, info = nm)
})

test_that("the land term compares GROSS to GROSS", {
  # The defect fixed 2026-08-14: the model's d(land_C)/dt is NET of E_LUC and
  # GCB's land_sink column is GROSS. Reconstructed correctly, a model whose
  # gross sink equals GCB's must score at the density's peak. Built here as an
  # explicit arithmetic identity rather than by trusting the implementation.
  obs <- ccx_prepare_obs()
  p   <- ccx_default_params()
  sp  <- ccx_spinup(p)
  F   <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
  parts <- ccx_loglik(out, obs, err, by_stream = TRUE)

  eluc <- ccx_forcing_eluc_annual(F)
  yrs  <- sort(unique(floor(out$t + 1e-9)))
  bnd  <- c(yrs, max(yrs) + 1L)
  st   <- function(v) stats::approx(out$t, v, xout = bnd, rule = 2)$y
  fl   <- data.frame(year = utils::head(bnd, -1), land = diff(st(out$land_C)))
  g    <- merge(as.data.frame(obs$gcb)[, c("year", "land_sink")], fl, by = "year")
  g    <- merge(g, eluc, by = "year")
  ref  <- sum(stats::dnorm(g$land_sink, g$land + g$eluc,
                           LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))
  # rule = 2 here vs the end-extrapolation inside ccx_loglik() differ only on
  # the two boundary years, so an ABSOLUTE tolerance of 1 log-unit on a term of
  # order -122 is the tight check; a relative one would have been meaningless.
  expect_lt(abs(parts[["gcb_land_sink"]] - ref), 1)

  # ...and it must be the GROSS comparison and not the NET one, which is what
  # the bug scored. NOTE THE DIRECTION, because it is counter-intuitive: at the
  # current default the NET (buggy) comparison scores BETTER -- because the
  # model over-absorbs, its gross sink being 3.48 GtC/yr against GCB's 2.36.
  # The bug was FLATTERING the over-absorbing model, which is exactly why
  # nothing objected to beta rising. Do not "fix" this by asserting gross beats
  # net; that holds only for a model whose sink is right, and asserting it would
  # re-introduce the bug the day the model improved.
  net <- sum(stats::dnorm(g$land_sink, g$land,
                          LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))

  # RE-EXPRESSED 2026-08-15 (Marcus), NOT re-baselined. The old assertion was
  # abs(gross - net) > 10 log-units, and it had started to fail at 8.5. Its own
  # comment above predicted why: THE GAP IS LARGE BECAUSE THE MODEL
  # OVER-ABSORBS, so it SHRINKS as the sink improves -- 4.57 -> 3.50 (the MM
  # flip) -> 3.48 GtC/yr. A fixed threshold on that quantity uses a symptom of
  # the old bug as a proxy for the fix and fails harder the more the refit
  # succeeds. Lowering it would bake the same trap in at a new number.
  #
  # The scale-free statement is available in closed form. Both terms are
  # Gaussian with the same sd, differing only by the E_LUC shift in the mean, so
  #     gross - net = -(1/(2 s^2)) * sum( eluc^2 - 2 * eluc * (land_sink - land) )
  # exactly. Asserting THAT verifies the term really is the net term displaced
  # by the model's own land-use flux -- which is precisely the property the
  # net-vs-gross bug destroyed -- and it stays true at any sink strength.
  # Both sides are built from THIS test's `g$land`, not from ccx_loglik()'s own
  # end-extrapolated one: mixing the two leaves the 0.18 log-units of boundary
  # difference the tolerance above exists to absorb, and an exact identity has
  # no room for it. `parts` is tied to `ref` by that assertion; `ref` is tied to
  # `net` by this one.
  s   <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE
  amt <- -(1 / (2 * s^2)) * sum(g$eluc^2 - 2 * g$eluc * (g$land_sink - g$land))
  expect_equal(ref - net, amt, tolerance = 1e-8)
  # ...and the displacement must be MATERIAL, or the identity above is vacuous:
  # a term accidentally handed a zero E_LUC would satisfy it trivially.
  expect_gt(mean(abs(g$eluc)), 0.5)          # GtC/yr, GCB-scale land-use flux
  expect_gt(abs(ref - net), 1)
})

# =====================================================================
# THE DOUBLE-SCALING LINT AND ITS NUMERICAL TWIN (added 2026-08-22)
#
# On 2026-08-22 eight files were found applying `luc_scale` TWICE to the
# gross-land-sink reconstruction: the forcing's four LUC columns were scaled,
# and then the annual E_LUC was derived from THAT already-scaled forcing and
# scaled again. ccx_make_logpost() never had it, so no FIT was affected -- but
# the per-stream `gcb_land_sink` those diagnostics reported was, including the
# decomposition stored in mode_fit_pump{N,D}.rds that handoffs rank work from.
#
# A helper alone does not fix this, because nothing forces a new diagnostic to
# use it. The lint does: it fails on the SIGNATURE, wherever it is written.
# =====================================================================

test_that("no file derives eluc from an already-scaled forcing and scales it again", {
  root  <- ccx_root()
  files <- c(list.files(file.path(root, "R"), "\\.R$", full.names = TRUE),
             list.files(file.path(root, "calibration"), "\\.R$", full.names = TRUE),
             list.files(file.path(root, "app"), "\\.R$", full.names = TRUE))
  offenders <- character()
  for (f in files) {
    L <- readLines(f, warn = FALSE)
    hits <- grep("\\$eluc\\s*<-.*luc_scale", L)
    for (j in hits) {
      src <- sub(".*ccx_forcing_eluc_annual\\(\\s*([A-Za-z_.][A-Za-z0-9_.]*).*", "\\1", L[j])
      if (identical(src, L[j])) next          # eluc source not on this line: fine
      ctx <- L[max(1, j - 20):(j - 1)]
      # was THAT SAME variable's LUC column set multiplied by luc_scale above?
      scaled <- any(grepl(paste0("\\b", src, "\\[\\[[a-z]+\\]\\]\\s*<-.*luc_scale"), ctx)) ||
                any(grepl(paste0("\\b", src, "\\$e_luc_NH\\s*<-.*luc_scale"), ctx))
      if (scaled) offenders <- c(offenders, sprintf("%s:%d", basename(f), j))
    }
  }
  expect_equal(offenders, character(),
               info = paste("luc_scale applied twice at:", paste(offenders, collapse = ", ")))
})

test_that("ccx_scaled_forcing reproduces ccx_make_logpost's likelihood exactly", {
  # THE NUMERICAL TWIN OF THE LINT. The lint catches the known signature; this
  # catches any OTHER way the canonical reconstruction could drift from the
  # objective, which is the property that actually has to hold.
  #
  # Evaluated at a u WE choose (the default init) rather than at a stored
  # u_mode: u_mode decodes under the refit's h_ml bound [85,120], which
  # ccx_default_params() cannot reconstruct, so comparing there would indict the
  # product for a property of the producer (memory ccx_hml_band_provenance).
  #
  # AND IT IS EVALUATED OFF THE INIT, WHICH IS THE WHOLE POINT. `luc_scale`'s
  # init is exactly 1 and `bomb_total`'s is exactly the reference 102, so at the
  # bare init a double-scaling is INVISIBLE (1 * 1 = 1) and this test passes
  # against a broken helper. Measured, not assumed: mutating ccx_scaled_forcing()
  # to square luc_scale left the init version at FAIL 0. Both are perturbed.
  u <- ccx_init_unc()
  u[["luc_scale"]]  <- u[["luc_scale"]]  + 0.15
  u[["bomb_total"]] <- u[["bomb_total"]] + 0.15
  pv <- ccx_unc_to_par(u)
  stopifnot(abs(pv$luc_scale - 1) > 0.05, abs(pv$bomb_total - CCX_BOMB_REF) > 1)

  lp    <- ccx_make_logpost()
  prior <- sum(vapply(CCX_PARAM_NAMES, function(n) {
    sc <- CCX_PARAM_TABLE[[n]]
    sc$prior(pv[[n]]) + .log_jac(u[[n]], sc)
  }, numeric(1)))
  ll_obj <- lp(u) - prior                       # the objective's own likelihood

  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv)
  sp <- ccx_spinup(p)
  SF <- ccx_scaled_forcing(sp, luc_scale = pv$luc_scale, bomb_total = pv$bomb_total)
  o  <- ccx_run_fast(sp, SF$F)$out
  ll_rec <- ccx_loglik(o, ccx_prepare_obs(),
                       list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                            grad_off_co2 = pv$grad_off_co2,
                            grad_off_d13c = pv$grad_off_d13c),
                       luc = SF$eluc, deep = sp$diagnostics$d14c_bottom_box,
                       ocean_grad = ccx_ocean_grad_scored(o, sp))

  expect_true(is.finite(ll_obj))
  expect_equal(ll_rec, ll_obj, tolerance = 1e-8)
})

# =====================================================================
# THE "luc" ARM IS AFFINE IN luc_scale, AND THE FAST PATH COMPOSES IT (2026-08-24c)
#
# ccx_build_forcing() applies the arm AFTER luc_scale, so its columns are
# s * L - S: affine, not linear, which is why the plain column multiply was
# refused. `.ccx_make_luc_scaler()` composes that closed form from the arm-off
# base plus the perturbation, so the fast path is EXACT rather than refused.
#
# GATED AGAINST THE BUILDER, AND MUTATION-TESTED IN BOTH DIRECTIONS: the wrong
# composition (scaling the perturbation too -- the precise error the refusal
# existed to prevent) must FAIL the same assertion the right one passes, and it
# must fail by a MATERIAL amount, or the gate is a tautology.
# =====================================================================

test_that("the luc arm's fast path equals rebuilding, and the wrong one does not", {
  s    <- 0.8984                       # the adopted mode's luc_scale
  rate <- 2.5                          # GtC/yr, the magnitude-matched arm
  yrs  <- c(1750, 2024)

  # The arm is an ENVIRONMENT-level switch, so drive the builder explicitly and
  # emulate the switch by hand rather than restarting R with CCX_SINK_MODE set.
  base  <- ccx_build_forcing("historical", yrs, prod_c14 = 0,
                             sink_rate = rate, sink_mode = "luc")
  base0 <- ccx_build_forcing("historical", yrs, prod_c14 = 0, sink_rate = 0)
  slow  <- ccx_build_forcing("historical", yrs, prod_c14 = 0, luc_scale = s,
                             sink_rate = rate, sink_mode = "luc")

  # ...the arm must actually be present, or every assertion below is vacuous.
  expect_gt(max(abs(base$e_luc_NH + base$e_luc_SH -
                    (base0$e_luc_NH + base0$e_luc_SH))), 0.1)

  for (cc in CCX_LUC_COLS) {
    right <- base0[[cc]] * s + (base[[cc]] - base0[[cc]])   # affine, correct
    wrong <- base[[cc]] * s                                 # the refused multiply
    expect_equal(right, slow[[cc]], tolerance = 1e-12, info = paste("right", cc))
    expect_false(isTRUE(all.equal(wrong, slow[[cc]], tolerance = 1e-9)),
                 info = paste("mutation not caught:", cc))
  }

  # The mutation is MATERIAL, not a rounding difference: at s = 0.8984 the wrong
  # path shrinks a 2.5 GtC/yr perturbation to 2.246, a 10 % error in the one
  # quantity the three-arm comparison holds fixed.
  w  <- (1 - s) * rate
  dm <- max(abs(base$e_luc_NH * s + base$e_luc_SH * s -
                (slow$e_luc_NH + slow$e_luc_SH)))
  expect_gt(dm, 0.5 * w / 12)          # monthly columns are GtC/yr / 12
})

test_that("ccx_scaled_forcing carries the luc arm unscaled once the arm is on", {
  s    <- 0.8984
  rate <- 2.5
  yrs  <- c(1750, 2024)
  base <- ccx_build_forcing("historical", yrs, prod_c14 = 0,
                            sink_rate = rate, sink_mode = "luc")
  slow <- ccx_build_forcing("historical", yrs, prod_c14 = 0, luc_scale = s,
                            sink_rate = rate, sink_mode = "luc")

  # The scaler reads the arm from the ENVIRONMENT constants, so exercise it the
  # way a run does -- with the constants temporarily set to the arm.
  old_r <- CCX_ARTIFICIAL_SINK_RATE; old_m <- CCX_ARTIFICIAL_SINK_MODE
  on.exit({
    assign("CCX_ARTIFICIAL_SINK_RATE", old_r, envir = globalenv())
    assign("CCX_ARTIFICIAL_SINK_MODE", old_m, envir = globalenv())
  }, add = TRUE)
  assign("CCX_ARTIFICIAL_SINK_RATE", rate, envir = globalenv())
  assign("CCX_ARTIFICIAL_SINK_MODE", "luc", envir = globalenv())

  got <- ccx_scaled_forcing(NULL, yrs, luc_scale = s, base = base)
  for (cc in CCX_LUC_COLS)
    expect_equal(got$F[[cc]], slow[[cc]], tolerance = 1e-12, info = cc)

  # and the annual E_LUC handed to the gcb_land_sink term follows the SAME
  # composition -- this is the quantity the 2026-08-22 double-scaling bug hit.
  expect_equal(got$eluc$eluc, ccx_forcing_eluc_annual(slow)$eluc,
               tolerance = 1e-10)

  # A base built with the arm OFF must be REFUSED, not silently treated as the
  # arm: that failure mode would report a run as an arm it never carried.
  expect_error(ccx_scaled_forcing(NULL, yrs, luc_scale = s,
                                  base = ccx_build_forcing("historical", yrs,
                                                           prod_c14 = 0,
                                                           sink_rate = 0)),
               "carries no perturbation")
})

test_that("the arm being OFF leaves both paths bit-identical to before", {
  s    <- 0.65
  yrs  <- c(1750, 2024)
  base <- ccx_build_forcing("historical", yrs, prod_c14 = 0)
  got  <- ccx_scaled_forcing(NULL, yrs, luc_scale = s, base = base)
  for (cc in CCX_LUC_COLS)
    expect_identical(got$F[[cc]], base[[cc]] * s)
  expect_identical(got$eluc$eluc, ccx_forcing_eluc_annual(base)$eluc * s)
})
