# =====================================================================
# diag_pump_grad_profile.R -- WHAT DOES THE FOUR-ROW OBJECTIVE WANT `pump_grad`
# TO BE, AND IS IT SHARP ENOUGH TO FIT?  (handoff 2026-08-16c sec.7 item 1)
#
# THE DECISION THIS FILE FEEDS, AND THE ONE IT DOES NOT TAKE. The port shipped
# with `pump_grad = 0` deliberately: its value is a design decision nobody has
# taken, and whether it becomes a FITTED parameter at the refit is the same
# decision. This file does not take it. It measures the profile the decision
# needs -- where the objective puts the pump, how sharp the optimum is, and
# whether the three ocean rows agree about it -- and reports the per-row
# disagreement rather than a single recommended number.
#
# WHY IT IS A NEW QUESTION AND NOT diag_pump_vs_gradient_terms.R AGAIN. That
# file ran the SHIM: ONE limb at eps = -20, and it found the DIC and d13C rows
# wanting export scales 1.37x apart, which is exactly 20/14.55 -- the
# fractionation gap. The SHIPPED pump has TWO limbs with the carbonate share
# pinned at 0.23 by GLODAP's alkalinity gradient, so its effective fractionation
# is 0.77*(-20) + 0.23*(+1) = -15.2 permil, close to the -14.55 the transient
# rows demanded. THE STRUCTURAL GAP THAT FILE FOUND SHOULD THEREFORE BE MOSTLY
# CLOSED, and the remaining question is a SIZE question -- which is a profile.
# There is also a third row now (`ocean_grad_alk`) which did not exist when the
# 1.37x was measured, and it is the row that sizes the carbonate limb.
#
# ---------------------------------------------------------------------
# PRE-REGISTERED PREDICTIONS, written before any arm was run.
#
#   P1 (a PROPERTY, not a guess). In mode "N" the pump is constant-mass and adds
#      EXACTLY ZERO uptake -- handoff 16c sec.4, now tests/testthat/test-pump.R.
#      So the CO2-LEVEL streams must be IDENTICAL at every `pump_grad` on this
#      grid. Not "close": identical to integrator noise. If they move, the
#      zero-uptake property is broken and NOTHING else in this file is readable.
#      The isotope streams SHOULD move -- the pump fractionates, so surface d13C
#      rises, and air-sea exchange carries that into the atmosphere.
#
#   P2 (LINEARITY). The DIC row is a mass gradient under a linear transport with
#      a fixed source, so it must be EXACTLY linear in `pump_grad`; the
#      alkalinity row is a steady-state solve of the same linear operator and
#      must be too. The d13C row is a RATIO and is only approximately linear.
#      Predicted: DIC and ALK linear to < 1e-6 relative, d13C to ~1 %.
#
#   P3 (THE PER-ROW SCALES). From the as-shipped z at pump_grad = 233.109
#      (handoff 16c sec.4: DIC -1.79, d13C +2.02, ALK +0.21) I predict the DIC
#      row demands ~1.19x, the d13C row ~1.15x -- i.e. the two-limb pump closes
#      the shim's 1.37x gap to ~1.03x, and the failure diagnosed as
#      FRACTIONATION in 16b sec.2 is then repaired by the carbonate limb rather
#      than by a scale. I predict the ALK row is the DISSENTER, demanding ~0.95x.
#
#   P4 (IDENTIFIABILITY, the one that answers the fitted-or-fixed half). I
#      predict a joint optimum near 1.15x (pump_grad ~ 268) and an implied sd of
#      15-25 umol/kg, ~8 % -- sharp enough that fitting it would be informative
#      rather than a free parameter chasing a flat direction.
#
# ---------------------------------------------------------------------
# THE COMPARISON IS AN ISO-OBSERVABLE SLICE, AND ITS LIMIT IS STATED HERE.
# Every arm below -- including pump OFF -- runs at the SAME quarantined
# pre-gradient mode with h_ml forced to PGP_H_SCORE. The arms differ in
# `pump_grad` and in nothing else, so d logL ALONG the profile is a fair
# within-slice comparison. It is NOT a fair answer to "should the pump ship
# ON?", because the incumbent no-pump model would be REFIT if the pump were
# rejected, and this slice gives it no such chance (the artifact that cost 309
# log-units in the ocean-candidate round). Read the profile's SHAPE and its
# per-row scales as decision-grade; read the OFF-to-optimum margin as an upper
# bound on what a refit would have to beat.
#
# NOTHING HERE IS PROPOSED FOR THE OBJECTIVE AND NO MODEL FILE IS TOUCHED.
# `pump_grad` stays 0 in R/model.R whatever this file finds.
#
# RUNTIME ~8 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label, window and threshold below derives ----
PGP_YEARS    <- c(1750, 2024)
PGP_BOMB_REF <- 102
PGP_H_SCORE  <- 100          # m; inside LIK_OCEAN_GRAD_HML_OK, and the depth the
                             # pump delivers (handoff 15d). The MODE's own h_ml
                             # is 184, which would SKIP all three rows.
PGP_MODE     <- "N"          # export law. "D" is deferred to the refit by
                             # decision (16c sec.7 item 3) and is NOT scanned
                             # here: the gradient rows cannot tell N from D, so a
                             # D column would duplicate these rows while
                             # re-opening a question already deferred.
# The scan, in umol/kg of PREINDUSTRIAL surface-to-bottom DIC gradient held.
# 233.109 is the OBSERVED gradient (the shipped DIC target) and is on the grid so
# the as-shipped z of handoff 16c sec.4 can be reproduced as a gate.
PGP_GRID     <- c(0, 100, 160, 200, 233.109, 260, 280, 300, 340, 400)
PGP_OBS_GRAD <- 233.109      # umol/kg; scales below are quoted RELATIVE to this
PGP_CARB_ALT <- c(0.12, 0.34)  # carbonate shares for the part-4 sensitivity,
                             # bracketing the pinned 0.23 by about +/- half
PGP_SINK_WIN <- c(2010, 2019)
PGP_Z_OK     <- 2            # |z| below this = "the row is closed"
PGP_LIN_TOL  <- 1e-6         # relative; the linearity gate for DIC and ALK
# THE ZERO-UPTAKE GATE IS ON PPM, NOT ON logL, and the first version of this file
# had it on logL at 1e-6 log-units -- a threshold TIGHTER THAN THE SPINUP'S OWN
# CONVERGENCE, which duly "failed" at 2.16e-6 and would have been explained away
# by loosening it. The physical claim is that atmospheric CO2 cannot see a
# constant-mass pump at all, so measure THAT. Scale of a meaningful violation:
# the pump moves ~25 GtC/yr at the optimum, so a 0.1 % leak would be ~7 GtC over
# the run, ~3 ppm. The tolerance below is six orders of magnitude inside that and
# still two orders above the Newton spinup's ~1e-7 GtC footprint on the ML.
PGP_CO2_PPM_TOL <- 1e-6      # ppm at 2024, across the whole scan
PGP_MODE_PATH <- ccx_path("calibration", "output", "quarantine",
                          "20260815_pre_gradient_terms", "mode_fit.rds")
# Carried from diag_pump_vs_gradient_terms.R's PG_ERR_MODE. `grad_off_*` are the
# MLO-SPO ATMOSPHERIC offsets -- NOT the ocean rows (16c sec.8 name collision).
PGP_ERR_MODE <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                     grad_off_co2 = -0.549, grad_off_d13c = +0.107)
PGP_GRAD_STREAMS <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk")
PGP_CO2_STREAMS  <- c("co2_level_MLO", "co2_level_SPO", "co2_icecore")
PGP_OUTDIR   <- ccx_path("calibration", "output", "pump_grad_profile")

dir.create(PGP_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# =====================================================================
# GATE A. THE ROWS MUST BE LIVE AT THE DEPTH EVERYTHING IS SCORED AT
# =====================================================================
# A skipped term reports as ABSENT, not as zero, so an arm run outside the band
# would silently compare two runs never scored on these streams at all.
tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg), !is.null(tg$dic), !is.null(tg$d13c), !is.null(tg$alk))
if (PGP_H_SCORE < LIK_OCEAN_GRAD_HML_OK[1] || PGP_H_SCORE > LIK_OCEAN_GRAD_HML_OK[2])
  stop(sprintf("PGP_H_SCORE = %g is outside LIK_OCEAN_GRAD_HML_OK [%g, %g] -- the rows would SKIP",
               PGP_H_SCORE, LIK_OCEAN_GRAD_HML_OK[1], LIK_OCEAN_GRAD_HML_OK[2]))
cat(sprintf("GATE A: h_ml = %g m is inside the gate [%g, %g]. All THREE rows are LIVE.\n",
            PGP_H_SCORE, LIK_OCEAN_GRAD_HML_OK[1], LIK_OCEAN_GRAD_HML_OK[2]))
cat(sprintf("targets: DIC %+.3f +/- %.3f   d13C %+.4f +/- %.4f   ALK %+.3f +/- %.3f\n",
            tg$dic$target, tg$dic$sd, tg$d13c$target, tg$d13c$sd,
            tg$alk$target, tg$alk$sd))

obs <- ccx_prepare_obs()
base_forc <- ccx_build_forcing("historical", PGP_YEARS, prod_c14 = 0,
                               bomb_total_kmol = PGP_BOMB_REF)
tg_d14 <- ccx_deep_d14c_target()

# =====================================================================
# EVALUATION -- the SHIPPED pump, through the C++ core
# =====================================================================
# No shim. `p$pump_grad` is the shipped parameter, `aux$pump` is what the
# derivative integrates, and ccx_ocean_grad_scored() reads the alkalinity row off
# that SAME field -- so no arm here can be scored against a pump it did not run.
pgp_eval <- function(p, grad, carb_frac, bomb_total, luc_scale) {
  p$h_ml <- PGP_H_SCORE
  p$pump_grad <- grad
  p$pump_carb_frac <- carb_frac
  p$pump_mode <- PGP_MODE
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp)) return(NULL)
  F <- base_forc
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forc$c14_bomb * (bomb_total / PGP_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forc[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forc); eluc$eluc <- eluc$eluc * luc_scale
  r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  og <- ccx_ocean_grad_scored(r$out, sp)
  if (is.null(og)) stop("ocean_grad scored NULL -- the rows skipped; gate A should have caught this")
  ps <- ccx_loglik(r$out, obs, PGP_ERR_MODE, luc = eluc,
                   deep = sp$diagnostics$d14c_bottom_box, ocean_grad = og,
                   by_stream = TRUE)
  yr  <- floor(r$out$t + 1e-9); ann <- tapply(r$out$ocean_C, yr, mean)
  yy  <- as.integer(names(ann))
  k   <- which(yy >= PGP_SINK_WIN[1] & yy <= PGP_SINK_WIN[2])
  list(grad = grad, carb = carb_frac, parts = ps, total = sum(ps), og = og,
       grad_logL = sum(ps[intersect(PGP_GRAD_STREAMS, names(ps))]),
       export = if (is.null(sp$aux$pump)) 0 else
         sum(vapply(HEMIS, function(h)
           sum(sp$aux$pump[[h]]$org + sp$aux$pump[[h]]$carb), numeric(1))),
       z_dic  = (og$dic  - tg$dic$target)  / tg$dic$sd,
       z_d13c = (og$d13c - tg$d13c$target) / tg$d13c$sd,
       z_alk  = (og$alk  - tg$alk$target)  / tg$alk$sd,
       z_d14  = (sp$diagnostics$d14c_bottom_box - tg_d14$target) / tg_d14$sd,
       deep14 = sp$diagnostics$d14c_bottom_box,
       sink   = if (length(k) > 1) mean(diff(ann[k])) else NA_real_,
       # The PHYSICAL quantity the zero-uptake property is about: end-of-run
       # atmospheric CO2. The logL footprint on the CO2 rows is a proxy for it
       # and is reported alongside, but this is what the gate reads.
       co2_end = 0.5 * (tail(r$out$co2_NH, 1) + tail(r$out$co2_SH, 1)),
       ocean  = sp$diagnostics$ocean_C_GtC)
}

# =====================================================================
# THE OPERATING POINT
# =====================================================================
sep("PART 0. THE OPERATING POINT")
# AT THE MODE, not at defaults: the export field is solved against the model's
# own diffusion, so the pump's size scales with `kz`, and the mode's kz sits
# 96.6 % up its bracket. calibration/output/mode_fit.rds is still EMPTY, so the
# quarantined pre-gradient mode is the only one available -- and it is the SAME
# one diag_pump_vs_gradient_terms.R used, which is what makes the two comparable.
pm <- if (file.exists(PGP_MODE_PATH)) readRDS(PGP_MODE_PATH)$par_mode else NULL
if (is.null(pm)) stop("quarantined mode absent -- this file scores at the mode")
pmode <- ccx_default_params()
for (n in intersect(names(pmode), names(pm))) pmode[[n]] <- pm[[n]]
pmode$gamma_enso <- pm$gamma_enso
CARB_PIN <- ccx_default_params()$pump_carb_frac
cat(sprintf("MODE (pre-gradient, quarantined)   kz = %g m2/yr   h_ml %g -> %g m forced\n",
            pmode$kz, pm$h_ml, PGP_H_SCORE))
cat(sprintf("pump: mode \"%s\", carbonate share %.2f (pinned by the ALK gradient)\n",
            PGP_MODE, CARB_PIN))
cat(sprintf("scan: pump_grad = %s umol/kg\n",
            paste(sprintf("%g", PGP_GRID), collapse = ", ")))

# =====================================================================
# PART 1. THE PROFILE
# =====================================================================
sep("PART 1. THE PROFILE OVER pump_grad")
res <- lapply(PGP_GRID, function(g) {
  t0 <- Sys.time()
  e  <- pgp_eval(pmode, g, CARB_PIN, pm$bomb_total, pm$luc_scale)
  cat(sprintf("  pump_grad %7.3f   %5.0f s\n", g,
              as.numeric(Sys.time() - t0, units = "secs")))
  e
})
names(res) <- sprintf("%g", PGP_GRID)
ok  <- !vapply(res, is.null, logical(1))
res <- res[ok]
gg  <- vapply(res, `[[`, numeric(1), "grad")
ref <- res[[which.min(abs(gg - 0))]]        # the pump-OFF arm

cat(sprintf("\n%9s %7s %8s %8s %7s %9s %7s %8s %7s %9s %9s %9s\n",
            "pump_grad", "scale", "export", "DIC grad", "z_DIC", "d13C grad",
            "z_d13C", "ALK grad", "z_ALK", "3-row logL", "logL", "d logL"))
for (e in res)
  cat(sprintf("%9.3f %7.3f %8.2f %8.1f %+7.2f %9.4f %+7.2f %8.2f %+7.2f %9.1f %9.1f %+9.1f\n",
              e$grad, e$grad / PGP_OBS_GRAD, e$export, e$og$dic, e$z_dic,
              e$og$d13c, e$z_d13c, e$og$alk, e$z_alk, e$grad_logL, e$total,
              e$total - ref$total))
cat(sprintf("%9s %7s %8s %8.1f %7s %9.4f %7s %8.2f\n", "TARGET", "", "",
            tg$dic$target, "", tg$d13c$target, "", tg$alk$target))
cat(sprintf("%9s %7s %8s %8.1f %7s %9.4f %7s %8.2f\n", "sigma", "", "",
            tg$dic$sd, "", tg$d13c$sd, "", tg$alk$sd))

# =====================================================================
# PART 2. THE PRE-REGISTERED GATES
# =====================================================================
sep("PART 2. P1 (ZERO UPTAKE) AND P2 (LINEARITY), SCORED")
# P1. In mode N the pump moves MASS from the mixed layer and the diffusive return
# balances it exactly, so atmospheric CO2 cannot know the pump is there. The
# ISOTOPE streams are expected to move and are printed alongside as the contrast.
co2s  <- intersect(PGP_CO2_STREAMS, names(ref$parts))
dco2L <- vapply(res, function(e) max(abs(e$parts[co2s] - ref$parts[co2s])), numeric(1))
dppm  <- vapply(res, function(e) abs(e$co2_end - ref$co2_end), numeric(1))
p1 <- max(dppm) < PGP_CO2_PPM_TOL
cat(sprintf("P1  max |d CO2(2024)| across the whole scan: %.3e ppm\n", max(dppm)))
cat(sprintf("    %s\n", if (p1)
    sprintf("PASS (< %.0e ppm) -- the constant-mass pump adds no uptake, as the property says",
            PGP_CO2_PPM_TOL)
  else "FAIL -- mode N is moving atmospheric CO2. STOP: the zero-uptake property is broken."))
cat(sprintf("    its logL footprint on the CO2-LEVEL rows: %.3e log-units (context, NOT the gate)\n",
            max(dco2L)))
# A REAL leak would scale with the pump; spinup residue would not. Measured, so
# the reader is not asked to take "it is just noise" on my word.
if (max(dppm) > 0)
  cat(sprintf("    correlation of |d CO2| with pump_grad: %+.3f  (%s)\n",
              suppressWarnings(cor(dppm, gg)),
              "a real leak would be ~+1 and would scale; spinup residue would not"))
iso <- intersect(c("d13c_atm", "d13c_MLO", "d14c_atm"), names(ref$parts))
if (length(iso))
  cat(sprintf("    contrast, the ISOTOPE rows (expected to move): max |d logL| = %.2f\n",
              max(vapply(res, function(e) max(abs(e$parts[iso] - ref$parts[iso])),
                         numeric(1)))))

# P2. Linear fits through the two extreme arms, predicting the interior ones.
lin_err <- function(field) {
  x <- gg; y <- vapply(res, function(e) e$og[[field]], numeric(1))
  i1 <- which.min(x); i2 <- which.max(x)
  pred <- y[i1] + (x - x[i1]) * (y[i2] - y[i1]) / (x[i2] - x[i1])
  max(abs(pred - y)) / max(abs(y - y[i1]))
}
e_dic <- lin_err("dic"); e_alk <- lin_err("alk"); e_d13 <- lin_err("d13c")
cat(sprintf("\nP2  worst relative departure from a straight line through the endpoints:\n"))
cat(sprintf("      DIC  %.3e   %s\n", e_dic,
            if (e_dic < PGP_LIN_TOL) "PASS (exactly linear)" else "FAIL"))
cat(sprintf("      ALK  %.3e   %s\n", e_alk,
            if (e_alk < PGP_LIN_TOL) "PASS (exactly linear)" else "FAIL"))
cat(sprintf("      d13C %.3e   (a RATIO -- approximate linearity is expected)\n", e_d13))

# =====================================================================
# PART 3. WHAT EACH ROW DEMANDS, AND WHETHER THEY AGREE
# =====================================================================
sep("PART 3. THE PER-ROW SCALES -- P3")
# THE TEST IS THE REQUIRED SCALE PER ROW, NOT THE SIGNS OF z. The sign test
# returned the WRONG verdict in diag_pump_vs_gradient_terms.R part 4 and the
# reason is kept there: the DIC and ALK targets are POSITIVE, the d13C target
# NEGATIVE, so equal signs of z are OPPOSITE corrections.
# THE SECANT IS LOCAL, AND THAT IS NOT A DETAIL. A line through the two extreme
# arms is the right estimator only for a row that is exactly linear, which DIC
# and ALK are (P2) and d13C is NOT -- it is a ratio, and P2 measures a 4.6 %
# departure. On the first run the endpoint line put the d13C demand at 287.8
# against the 272 the bracketing pair gives: a 6 % error, larger than the
# disagreement between rows that this part exists to measure. So interpolate
# between the two grid arms that BRACKET the target crossing, and take the sd
# from that same local slope.
demand <- function(field, key) {
  x <- gg; y <- vapply(res, function(e) e$og[[field]], numeric(1))
  o <- order(x); x <- x[o]; y <- y[o]
  tgt <- tg[[key]]$target
  j <- which(diff(sign(y - tgt)) != 0)[1]        # the bracketing pair
  if (is.na(j)) {                                # no crossing on the grid
    i1 <- 1L; i2 <- length(x)                    # fall back and SAY SO
  } else { i1 <- j; i2 <- j + 1L }
  sl <- (y[i2] - y[i1]) / (x[i2] - x[i1])
  list(g = (tgt - y[i1]) / sl + x[i1], sd = tg[[key]]$sd / abs(sl),
       bracketed = !is.na(j), lo = x[i1], hi = x[i2])
}
d_dic <- demand("dic", "dic"); d_d13 <- demand("d13c", "d13c")
d_alk <- demand("alk", "alk")
cat(sprintf("%-12s %14s %10s %12s %16s\n", "row", "pump_grad it", "as a",
            "its sd in", "secant"))
cat(sprintf("%-12s %14s %10s %12s %16s\n", "", "demands", "scale", "pump_grad", ""))
for (r in list(list("DIC", d_dic), list("d13C", d_d13), list("ALK", d_alk)))
  cat(sprintf("%-12s %14.1f %10.3f %12.1f %16s\n", r[[1]], r[[2]]$g,
              r[[2]]$g / PGP_OBS_GRAD, r[[2]]$sd,
              if (r[[2]]$bracketed) sprintf("%g-%g", r[[2]]$lo, r[[2]]$hi)
              else "ENDPOINTS (no crossing on the grid)"))
spread <- max(c(d_dic$g, d_d13$g, d_alk$g)) / min(c(d_dic$g, d_d13$g, d_alk$g))
cat(sprintf("\nthe three rows' demands span %.2fx", spread))
cat(sprintf("  (the SHIM's DIC-vs-d13C gap was 1.37x, one limb at eps -20)\n"))
cat(sprintf("DIC vs d13C alone: %.2fx  %s\n", d_dic$g / d_d13$g,
            if (abs(d_dic$g / d_d13$g - 1) < 0.05)
              "-- the carbonate limb CLOSED the fractionation gap"
            else "-- a fractionation gap SURVIVES the carbonate limb"))

# The precision-weighted combination of the three rows: the value the ocean rows
# alone would put on `pump_grad`, and the sd they would give it.
w   <- 1 / c(d_dic$sd, d_d13$sd, d_alk$sd)^2
gW  <- sum(w * c(d_dic$g, d_d13$g, d_alk$g)) / sum(w)
sdW <- 1 / sqrt(sum(w))
cat(sprintf("\nprecision-weighted over the three rows: pump_grad = %.1f +/- %.1f umol/kg (%.3fx)\n",
            gW, sdW, gW / PGP_OBS_GRAD))
cat("NOT a posterior -- it holds all 19 parameters at the mode. It is the ocean\n")
cat("rows' own statement, which is the half of the decision they can speak to.\n")

# =====================================================================
# PART 4. THE OPTIMUM AND ITS CURVATURE -- P4, the fitted-or-fixed half
# =====================================================================
sep("PART 4. WHERE THE OBJECTIVE PUTS IT, AND HOW SHARPLY")
# A quadratic through the three arms bracketing the best grid point: the profile
# is smooth here (the DIC and ALK rows are exactly linear in pump_grad, so their
# contributions are exactly quadratic), and the curvature is what says whether
# fitting it would be informative.
quad_opt <- function(vals) {
  i <- which.max(vals)
  if (i == 1 || i == length(vals)) return(list(g = gg[i], sd = NA_real_, edge = TRUE))
  x <- gg[(i - 1):(i + 1)]; y <- vals[(i - 1):(i + 1)]
  cf <- coef(lm(y ~ poly(x, 2, raw = TRUE)))
  a <- unname(cf[3]); b <- unname(cf[2])
  list(g = -b / (2 * a), sd = if (a < 0) 1 / sqrt(-2 * a) else NA_real_, edge = FALSE)
}
o_grad <- quad_opt(vapply(res, `[[`, numeric(1), "grad_logL"))
o_all  <- quad_opt(vapply(res, `[[`, numeric(1), "total"))
cat(sprintf("%-26s %10s %10s %10s\n", "objective", "pump_grad", "scale", "implied sd"))
cat(sprintf("%-26s %10.1f %10.3f %10.1f%s\n", "the THREE ocean rows", o_grad$g,
            o_grad$g / PGP_OBS_GRAD, o_grad$sd, if (o_grad$edge) "  AT A GRID EDGE" else ""))
cat(sprintf("%-26s %10.1f %10.3f %10.1f%s\n", "the FULL objective", o_all$g,
            o_all$g / PGP_OBS_GRAD, o_all$sd, if (o_all$edge) "  AT A GRID EDGE" else ""))
best <- res[[which.max(vapply(res, `[[`, numeric(1), "total"))]]
cat(sprintf("\nbest arm ON THE GRID: pump_grad %.3f, %+.1f log-units from OFF\n",
            best$grad, best$total - ref$total))
cat(sprintf("  z at that arm: DIC %+.2f   d13C %+.2f   ALK %+.2f   deep D14C %+.2f\n",
            best$z_dic, best$z_d13c, best$z_alk, best$z_d14))
cat(sprintf("  rows closed (|z| < %g): %s\n", PGP_Z_OK,
            paste(c("DIC", "d13C", "ALK")[abs(c(best$z_dic, best$z_d13c, best$z_alk)) < PGP_Z_OK],
                  collapse = ", ")))
cat("\nREAD THE OFF-TO-OPTIMUM MARGIN AS AN UPPER BOUND, NOT A VERDICT: the no-pump\n")
cat("incumbent is not refit in this slice, and a refit with beta_max, kz and h_ml\n")
cat("free could recover part of it. The SHAPE and the per-row scales are what is\n")
cat("decision-grade here.\n")

cat("\nper-stream change from OFF at the best arm, biggest movers first:\n")
d <- best$parts - ref$parts[names(best$parts)]
d <- sort(d[abs(d) > 1], decreasing = TRUE)
if (!length(d)) cat("  (no stream moves by more than 1 log-unit)\n")
for (s in names(d)) cat(sprintf("    %-26s %+10.1f\n", s, d[[s]]))
cat(sprintf("\n  ocean sink %d-%d: OFF %.3f -> best %.3f GtC/yr (mode N adds no uptake,\n",
            PGP_SINK_WIN[1], PGP_SINK_WIN[2], ref$sink, best$sink))
cat("  so any difference here is spinup state, not the pump's flux)\n")

# =====================================================================
# PART 5. IS THE PINNED CARBONATE SHARE CONSISTENT WITH THE TRANSIENT ROWS?
# =====================================================================
sep("PART 5. THE CARBONATE SHARE, AT THE BEST pump_grad")
# `pump_carb_frac` = 0.23 is PINNED by the OBSERVED alkalinity gradient, not
# fitted. Handoff 16c sec.3's whole argument is that alkalinity adjudicates
# transient-vs-preindustrial from an observation not used to decide it -- so if
# the TRANSIENT rows now want a different share, that is a finding about the
# argument, not a licence to fit the share. Two arms, reported, never adopted.
res5 <- lapply(PGP_CARB_ALT, function(cf) {
  t0 <- Sys.time()
  e  <- pgp_eval(pmode, best$grad, cf, pm$bomb_total, pm$luc_scale)
  cat(sprintf("  carb_frac %.2f   %5.0f s\n", cf,
              as.numeric(Sys.time() - t0, units = "secs")))
  e
})
res5 <- c(list(best), res5[!vapply(res5, is.null, logical(1))])
cat(sprintf("\n%10s %8s %7s %9s %7s %8s %7s %9s %9s\n", "carb_frac", "DIC grad",
            "z_DIC", "d13C grad", "z_d13C", "ALK grad", "z_ALK", "3-row logL", "logL"))
for (e in res5)
  cat(sprintf("%10.2f %8.1f %+7.2f %9.4f %+7.2f %8.2f %+7.2f %9.1f %9.1f\n",
              e$carb, e$og$dic, e$z_dic, e$og$d13c, e$z_d13c, e$og$alk, e$z_alk,
              e$grad_logL, e$total))
cat(sprintf("\nall three arms hold pump_grad = %.3f. The DIC row should barely move\n",
            best$grad))
cat("(both limbs carry the same carbon); d13C and ALK are what the share trades.\n")

saveRDS(list(grid = PGP_GRID, res = res, ref = ref, best = best,
             carb_scan = res5, carb_pin = CARB_PIN,
             demands = list(dic = d_dic, d13c = d_d13, alk = d_alk,
                            weighted = list(g = gW, sd = sdW)),
             opt = list(grad_rows = o_grad, full = o_all),
             gates = list(p1_zero_uptake = p1, lin_dic = e_dic, lin_alk = e_alk,
                          lin_d13c = e_d13),
             h_score = PGP_H_SCORE, pump_mode = PGP_MODE,
             mode_label = "MODE (pre-gradient, quarantined)"),
        file.path(PGP_OUTDIR, "diag_pump_grad_profile.rds"))
cat(sprintf("\n\nwritten: %s\n",
            file.path(PGP_OUTDIR, "diag_pump_grad_profile.rds")))
