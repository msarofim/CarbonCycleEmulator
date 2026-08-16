# =====================================================================
# diag_pump_vs_gradient_terms.R -- DOES THE PUMP THAT CLOSES DIC ALSO CLOSE
# d13C?  (handoff 2026-08-16b sec.6 item 2, the cheap half of the pump round)
#
# THE QUESTION, AND WHY IT IS NOT THE ONE diag_dic_gradient.R ANSWERED. The pump
# was designed against the DIC row, at a time when neither row was in the
# objective. Both are now: `ocean_grad_dic` and `ocean_grad_d13c` shipped on
# 2026-08-16 (0f83dfe), and d13C is the STRONGER of the two -- handoff 16b sec.2
# quotes z +16.5 against DIC's -11.0. So a pump that closes DIC while wrecking
# d13C would be scored as a LOSS by the objective it was built to satisfy, and
# nobody has checked which way that lands. This file checks, before any pump is
# ported to src/ccx_core.cpp (task 9) and before the refit (task 8).
#
# WHAT IS SCORED HERE IS EXACTLY WHAT THE LIKELIHOOD SCORES. Not the spinup's
# bottom box against a preindustrial target -- that is what diag_dic_gradient.R
# part 3 did, under the OLD n_eff = 20 convention, and its numbers are NOT
# comparable with these. Here every arm goes through ccx_ocean_grad_scored() and
# ccx_loglik(ocean_grad = ), i.e. the TRANSIENT gradient at the observations'
# own epoch, on the shipped fixed depths, at the shipped block-bootstrap sigma.
#
# ---------------------------------------------------------------------
# THE ARITHMETIC, AND TWO PREDICTIONS WRITTEN BEFORE ANY ARM WAS RUN.
#
# Mixing a quantity dDIC of organic carbon at (surface + eps) into a deep
# reservoir at DIC_deep depletes it by  d(d13C) ~ eps * dDIC / DIC_deep.
# Inverting that against the SHIPPED pair (+233.109 umol/kg, -0.8610 permil)
# with the observed deep DIC of 2273.1 umol/kg gives an EFFECTIVE fractionation
#
#     eps_eff(preindustrial) = -8.40 permil
#
# against soft-tissue's -20. That is diag_dic_gradient.R part 5's finding in one
# number: the observed pair is NOT consistent with a pure soft-tissue pump, and
# the shortfall is the carbonate limb.
#
#   PREDICTION 1 (the naive one, and I expect it to be WRONG). If the terms were
#   scored preindustrially, a soft-tissue pump sized to the observed DIC
#   gradient would overshoot d13C by 20/8.40 = 2.4x, landing d13C at -2.05
#   permil, z = -10.7. Both terms cannot be closed by one epsilon.
#
#   PREDICTION 2 (the one that should hold, because the terms are TRANSIENT).
#   The pump-OFF model does not sit at zero gradient at the observations' epoch:
#   the mixed layer has taken up anthropogenic carbon the bottom box has not
#   seen, so DIC starts NEGATIVE and d13C starts POSITIVE (the Suess signal is a
#   surface signal). From handoff 16b's quoted pump-OFF z values, -11.0 and
#   +16.5, the model's transient gradients are ~ -44.7 umol/kg and ~ +0.98
#   permil, so the pump must supply ~ +278 umol/kg and ~ -1.84 permil. The
#   RATIO of what is needed is therefore NOT the observed ratio, and the
#   effective fractionation the transient terms demand is
#
#       eps_eff(transient) ~ -1.84 * 2273.1 / 278 ~ -15.0 permil,
#
#   i.e. much CLOSER to soft-tissue than the preindustrial arithmetic suggests.
#   Concretely I predict that the g = 1, eps = -20 arm lands BOTH terms around
#   -2 sigma rather than closing one and blowing the other, and that the arm
#   which closes both needs an export ~1.19x the observed gradient and an
#   epsilon near -15, not -8.4.
#
# Prediction 2's inputs are handoff numbers, not measurements taken here. Part 2
# RE-MEASURES the pump-OFF gradients and part 3 scores both predictions against
# what it finds. If the pump-OFF z values disagree with -11.0 / +16.5, that
# disagreement is the finding and everything downstream of it is suspect.
#
# ---------------------------------------------------------------------
# PRE-REGISTERED DECISION RULE, written before part 2 was run.
#
#   * "THE DIC PUMP ALSO CLOSES d13C" is TRUE only if the SAME arm -- one
#     export field, one epsilon, nothing refitted -- puts BOTH |z| below
#     PG_Z_OK = 2. Closing one and missing the other is a FAIL, and the sign of
#     the miss must be reported, not the magnitude alone.
#   * IF IT FAILS BY OVERSHOOTING d13C, the single soft-tissue pump is falsified
#     as a joint fix and the design needs a second (carbonate) limb. Report the
#     epsilon that would close both AS A STAND-IN for that limb, never as a
#     fitted parameter -- the carbonate limb also moves alkalinity, which this
#     model holds FIXED at ALK_SURFACE.
#   * IF IT FAILS BY UNDERSHOOTING BOTH, the pump is the right shape and the
#     wrong size, which is a scaling question and not a structural one.
#   * REPORT THE OBJECTIVE'S VERDICT SEPARATELY FROM THE TWO ROWS. A pump that
#     closes both gradient terms while losing more elsewhere is still a loss;
#     the per-stream table is what says which.
#
# ---------------------------------------------------------------------
# NOTHING HERE IS PROPOSED FOR THE OBJECTIVE AND NO MODEL FILE IS TOUCHED. The
# pump is calibration/pump_shim.R's wrapper over ccx_deriv(), zero fitted
# parameters, and the C++ core does not know about it -- every arm runs through
# the R reference integrator ccx_run().
#
# RUNTIME ~2 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "pump_shim.R"))

# ---- named constants: every label, window and threshold below derives ----
PG_YEARS     <- c(1750, 2024)
PG_BOMB_REF  <- 102
PG_H_SCORE   <- 100        # m. INSIDE LIK_OCEAN_GRAD_HML_OK by assertion below,
                           # and the depth handoff 15d says the pump delivers.
PG_EPS_ORG   <- PUMP_EPS_ORG          # -20 permil, soft-tissue
PG_EPS_NONE  <- 0                     # the control arm
PG_D13C_CARB <- 2.0        # permil, marine biogenic CaCO3, for the split
PG_Z_OK      <- 2          # |z| below this = "closes it". The decision rule.
PG_SINK_WIN  <- c(2010, 2019)
# Global POC export at ~100 m. A RANGE, not a point: a recollected span, used
# only as an order-of-magnitude check and never as a target. Carried from
# calibration/diag_dic_gradient.R's DG_EXPORT_LIT.
PG_EXPORT_LIT <- c(5, 12)  # GtC/yr
PG_MODE_PATH <- ccx_path("calibration", "output", "quarantine",
                         "20260815_pre_gradient_terms", "mode_fit.rds")
# Gradient offsets: their ABSENCE SKIPS the two ATMOSPHERIC gradient streams
# (`grad_off_*` are MLO-SPO, review item 5 -- NOT these ocean terms; handoff 16b
# sec.7 flags the name collision). `sigma_co2` is RETIRED and deliberately
# absent. Values carried from calibration/diag_dic_gradient.R.
PG_ERR_DEFAULT <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                       grad_off_co2 = -0.386, grad_off_d13c = +0.099)
PG_ERR_MODE    <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                       grad_off_co2 = -0.549, grad_off_d13c = +0.107)
PG_OUTDIR    <- ccx_path("calibration", "output", "pump_vs_gradient")

dir.create(PG_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# =====================================================================
# GATE A. THE TERMS MUST BE LIVE AT THE DEPTH EVERYTHING IS SCORED AT
# =====================================================================
# The gradient terms SKIP outside LIK_OCEAN_GRAD_HML_OK. A skipped term reports
# as absent, not as zero -- so an arm run outside the band would silently
# compare two runs that were never scored on these streams at all.
tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg), !is.null(tg$dic), !is.null(tg$d13c))
if (PG_H_SCORE < LIK_OCEAN_GRAD_HML_OK[1] || PG_H_SCORE > LIK_OCEAN_GRAD_HML_OK[2])
  stop(sprintf("PG_H_SCORE = %g is outside LIK_OCEAN_GRAD_HML_OK [%g, %g] -- the terms would SKIP",
               PG_H_SCORE, LIK_OCEAN_GRAD_HML_OK[1], LIK_OCEAN_GRAD_HML_OK[2]))
cat(sprintf("GATE A: h_ml = %g m is inside the gate [%g, %g]. Both terms are LIVE.\n",
            PG_H_SCORE, LIK_OCEAN_GRAD_HML_OK[1], LIK_OCEAN_GRAD_HML_OK[2]))
dg_parity_gate()

# =====================================================================
# PART 1. THE ARITHMETIC, FROM THE SHIPPED TARGETS
# =====================================================================
sep("PART 1. WHAT THE OBSERVED PAIR IMPLIES, BEFORE ANY MODEL IS RUN")
obs_deep_dic <- dg_bin("tco2", "tco2f", tg$dic$layer_deep[1], tg$dic$layer_deep[2])$vw
obs_surf_d13 <- dg_bin("c13",  "c13f",  tg$d13c$layer_surf[1], tg$d13c$layer_surf[2])$vw
eps_pi <- tg$d13c$target * obs_deep_dic / tg$dic$target

cat(sprintf("shipped targets   DIC %+.3f +/- %.3f umol/kg   d13C %+.4f +/- %.4f permil\n",
            tg$dic$target, tg$dic$sd, tg$d13c$target, tg$d13c$sd))
cat(sprintf("layers            surf %g-%g m,  deep >%g m   (fixed depths)\n",
            tg$dic$layer_surf[1], tg$dic$layer_surf[2], tg$dic$layer_deep[1]))
cat(sprintf("epochs            DIC surf %.1f deep %.1f   d13C surf %.1f deep %.1f\n",
            tg$dic$epoch_surf, tg$dic$epoch_deep, tg$d13c$epoch_surf, tg$d13c$epoch_deep))
cat(sprintf("observed deep DIC %.1f umol/kg\n\n", obs_deep_dic))
cat(sprintf("EFFECTIVE FRACTIONATION the observed PAIR implies: %+.2f permil\n", eps_pi))
cat(sprintf("soft-tissue value:                                 %+.2f permil\n", PG_EPS_ORG))
cat(sprintf("=> a pure soft-tissue pump sized to the DIC gradient overshoots d13C %.2fx\n",
            PG_EPS_ORG / eps_pi))
x_org <- (tg$d13c$target * obs_deep_dic -
            tg$dic$target * (PG_D13C_CARB - obs_surf_d13)) /
           (PG_EPS_ORG - (PG_D13C_CARB - obs_surf_d13))
cat(sprintf("\ntwo-component split of the OBSERVED gradient (CaCO3 at %+.1f permil):\n", PG_D13C_CARB))
cat(sprintf("   soft-tissue %+7.1f umol/kg  (%.0f %%)\n", x_org, 100 * x_org / tg$dic$target))
cat(sprintf("   carbonate   %+7.1f umol/kg  (%.0f %%)\n", tg$dic$target - x_org,
            100 * (tg$dic$target - x_org) / tg$dic$target))
cat("This split also absorbs preformed-d13C and air-sea disequilibrium structure\n")
cat("that a two-layer contrast cannot separate. Treat it as an ORDER, not a\n")
cat("partition -- the same caveat diag_dic_gradient.R part 5 carries.\n")

# =====================================================================
# THE ARMS
# =====================================================================
obs_all  <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", PG_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = PG_BOMB_REF)

#' Configure the shim. The export field is solved so that the PREINDUSTRIAL
#' surface-to-bottom DIC gradient equals `gscale` x the SHIPPED target, with the
#' SHAPE taken from GLODAP on this grid's own layers. gscale = 1 therefore means
#' "the pump that reproduces the observed gradient", exactly.
pg_arm_setup <- function(p, aux, grid, mode, eps, gscale) {
  if (is.na(mode)) { .dg$on <- FALSE; return(NULL) }
  op    <- dg_obs_profile(grid)
  shape <- op$dic - op$dic[1]
  # RESCALE THE SHAPE ONTO THE SHIPPED TARGET. The profile's own endpoint
  # difference is not the shipped target: the shipped deep layer is >2627.2 m
  # with no upper bound, this grid's bottom box is 2634.6-3700 m, and the two
  # differ by ~0.8 %. Small, and NOT assumed away -- the ratio is printed.
  shape <- shape * (tg$dic$target * gscale / shape[length(shape)])
  fl <- lapply(HEMIS, function(h) {
    dic_ml <- ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                               aux$sst[[h]]) * 1e6
    dg_export_field(p, aux, grid, h, dic_ml + shape)$S
  })
  names(fl) <- HEMIS
  .dg$S <- fl; .dg$mode <- mode; .dg$eps <- eps; .dg$on <- TRUE
  .dg$c_ml0 <- lapply(HEMIS, function(h)
    ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                     aux$sst[[h]]) * aux$ml_mass_kg[[h]] / aux$mol_per_GtC)
  names(.dg$c_ml0) <- HEMIS
  fl
}

#' One arm: spinup + 1750-2024, scored through the SHIPPED gradient streams.
pg_eval <- function(p, mode, eps, gscale, bomb_total, luc_scale, err) {
  p$h_ml <- PG_H_SCORE
  aux <- ccx_prepare(p); grid <- aux$grid
  fl  <- pg_arm_setup(p, aux, grid, mode, eps, gscale)
  sp  <- tryCatch(dg_spinup(p), error = function(e) NULL)
  if (is.null(sp)) { .dg$on <- FALSE; return(NULL) }
  F <- base_forcing
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forcing$c14_bomb * (bomb_total / PG_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forcing[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forcing); eluc$eluc <- eluc$eluc * luc_scale
  r <- tryCatch(ccx_run(sp, F), error = function(e) NULL)
  .dg$on <- FALSE
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  og <- ccx_ocean_grad_scored(r$out, sp)
  # A NULL here would mean the terms SKIPPED, which gate A exists to prevent.
  if (is.null(og)) stop("ocean_grad scored NULL -- the terms skipped; check h_ml and the target build")
  ps <- ccx_loglik(r$out, obs_all, err, luc = eluc,
                   deep = sp$diagnostics$d14c_bottom_box, ocean_grad = og,
                   by_stream = TRUE)
  yr  <- floor(r$out$t + 1e-9); ann <- tapply(r$out$ocean_C, yr, mean)
  yy  <- as.integer(names(ann))
  k   <- which(yy >= PG_SINK_WIN[1] & yy <= PG_SINK_WIN[2])
  # The deep-D14C LEVEL term is a different quantity from these gradients and is
  # carried alongside them because it is the row handoff 15c's clause 3 is about
  # -- a pump that closes the gradients while wrecking it is not a win.
  td <- ccx_deep_d14c_target()
  list(parts = ps, total = sum(ps), grad = og,
       z_dic  = (og$dic  - tg$dic$target)  / tg$dic$sd,
       z_d13c = (og$d13c - tg$d13c$target) / tg$d13c$sd,
       z_deep14 = (sp$diagnostics$d14c_bottom_box - td$target) / td$sd,
       export = if (is.null(fl)) 0 else sum(vapply(fl, sum, numeric(1))),
       sink   = if (length(k) > 1) mean(diff(ann[k])) else NA_real_,
       deep14 = sp$diagnostics$d14c_bottom_box,
       ocean  = sp$diagnostics$ocean_C_GtC)
}

pg_row <- function(nm, e, ref = NULL) {
  cat(sprintf("%-30s %8.1f %9.1f %+7.2f %9.4f %+7.2f %+8.2f %8.1f %9.3f",
              nm, e$export, e$grad$dic, e$z_dic, e$grad$d13c, e$z_d13c,
              e$z_deep14, e$total, e$sink))
  if (!is.null(ref)) cat(sprintf(" %+9.1f", e$total - ref$total))
  cat("\n")
}
pg_head <- function(dref = TRUE) {
  cat(sprintf("\n%-30s %8s %9s %7s %9s %7s %8s %8s %9s%s\n", "arm", "export",
              "DIC grad", "z_DIC", "d13C grad", "z_d13C", "z_deep14", "logL",
              "sink", if (dref) "    d logL" else ""))
}

# =====================================================================
# PART 2. THE ARMS, AT THE MODE'S PARAMETERS WITH h_ml = 100
# =====================================================================
# AT THE MODE, not at defaults, and for the same reason diag_dic_gradient.R
# part 6 gives: the export field is SOLVED against the model's own diffusion, so
# its magnitude scales with `kz`, and the mode's kz sits 96.6 % up its bracket.
# Defaults would size the pump against a diffusivity the posterior rejects.
sep("PART 2. ARMS AT THE MODE (h_ml OVERRIDDEN TO 100 m)")
pm <- NULL
if (file.exists(PG_MODE_PATH)) pm <- readRDS(PG_MODE_PATH)$par_mode
if (is.null(pm)) {
  cat("QUARANTINED MODE ABSENT -- part 2 cannot run at the mode.\n")
  cat("calibration/output/mode_fit.rds is still empty (handoff 16b sec.7), so\n")
  cat("this is the only mode available. Falling back to DEFAULTS, and every\n")
  cat("number below is then at a kz the posterior does not prefer.\n")
  pmode <- ccx_default_params(); bomb_m <- PG_BOMB_REF; luc_m <- 1
  err_m <- PG_ERR_DEFAULT; mode_label <- "DEFAULTS (mode absent)"
} else {
  pmode <- ccx_default_params()
  for (n in intersect(names(pmode), names(pm))) pmode[[n]] <- pm[[n]]
  pmode$gamma_enso <- pm$gamma_enso
  bomb_m <- pm$bomb_total; luc_m <- pm$luc_scale
  err_m <- PG_ERR_MODE; mode_label <- "MODE (pre-gradient, quarantined)"
}
cat(sprintf("operating point: %s   kz = %g m2/yr,  h_ml forced to %g m\n",
            mode_label, pmode$kz, PG_H_SCORE))

ARMS <- list(
  list(id = "OFF   no pump",              mode = NA,  eps = 0,           g = 1),
  list(id = "P20   eps -20, g = 1",       mode = "N", eps = PG_EPS_ORG,  g = 1),
  list(id = "PEFF  eps -8.4, g = 1",      mode = "N", eps = eps_pi,      g = 1),
  list(id = "P0    eps   0, g = 1",       mode = "N", eps = PG_EPS_NONE, g = 1),
  list(id = "D20   eps -20, g = 1, DIC-l",mode = "D", eps = PG_EPS_ORG,  g = 1))

res <- lapply(ARMS, function(a) {
  t0 <- Sys.time()
  e  <- pg_eval(pmode, a$mode, a$eps, a$g, bomb_m, luc_m, err_m)
  cat(sprintf("  %-30s %5.0f s\n", a$id, as.numeric(Sys.time() - t0, units = "secs")))
  e
})
names(res) <- vapply(ARMS, function(a) a$id, character(1))
ref <- res[[1]]

pg_head()
for (nm in names(res)) if (!is.null(res[[nm]])) pg_row(nm, res[[nm]], ref)
cat(sprintf("%-30s %8s %9.1f %7s %9.4f %7s\n", "TARGET", "",
            tg$dic$target, "", tg$d13c$target, ""))
cat(sprintf("%-30s %8s %9.1f %7s %9.4f %7s\n", "  sigma_Delta (shipped)", "",
            tg$dic$sd, "", tg$d13c$sd, ""))

# =====================================================================
# PART 3. THE PUMP THAT CLOSES BOTH -- SOLVED, THEN CONFIRMED
# =====================================================================
# The mass pump is LINEAR: in mode "N" the export field is a fixed source and
# the transport is linear in DIC, so the transient DIC gradient must be
#   grad(g) = grad_OFF + g * (grad_1 - grad_OFF).
# That gives the scale which closes the DIC term in ONE line rather than a scan
# -- and running the resulting arm is then a TEST of the linearity, not just a
# convenience. The isotope side is a ratio and is only approximately linear, so
# its epsilon is a first guess and the confirmation arm is where it is scored.
sep("PART 3. SOLVE FOR THE ARM THAT CLOSES BOTH, THEN RUN IT")
gstar <- (tg$dic$target - ref$grad$dic) /
           (res[["P20   eps -20, g = 1"]]$grad$dic - ref$grad$dic)
# d13C supplied by the g = 1, eps = -20 arm, scaled to g*, must equal what is
# needed; epsilon scales inversely.
d13_need <- tg$d13c$target - ref$grad$d13c
d13_got  <- res[["P20   eps -20, g = 1"]]$grad$d13c - ref$grad$d13c
epsstar  <- PG_EPS_ORG * d13_need / (d13_got * gstar)
cat(sprintf("pump-OFF transient gradients:   DIC %+.1f umol/kg   d13C %+.4f permil\n",
            ref$grad$dic, ref$grad$d13c))
cat(sprintf("the pump must SUPPLY:           DIC %+.1f umol/kg   d13C %+.4f permil\n",
            tg$dic$target - ref$grad$dic, d13_need))
cat(sprintf("g = 1, eps = -20 supplies:      DIC %+.1f umol/kg   d13C %+.4f permil\n",
            res[["P20   eps -20, g = 1"]]$grad$dic - ref$grad$dic, d13_got))
cat(sprintf("\n=> export scale that closes DIC:      g*   = %.4f\n", gstar))
cat(sprintf("=> fractionation that then closes d13C: eps* = %+.2f permil\n", epsstar))
cat(sprintf("   (the PREINDUSTRIAL arithmetic asked for %+.2f -- part 1)\n", eps_pi))

t0 <- Sys.time()
res[["BOTH  eps*, g*"]] <- pg_eval(pmode, "N", epsstar, gstar, bomb_m, luc_m, err_m)
cat(sprintf("\n  %-30s %5.0f s\n", "BOTH  eps*, g*",
            as.numeric(Sys.time() - t0, units = "secs")))
both <- res[["BOTH  eps*, g*"]]
pg_head()
pg_row("OFF   no pump", ref, ref)
pg_row("P20   eps -20, g = 1", res[["P20   eps -20, g = 1"]], ref)
pg_row("BOTH  eps*, g*", both, ref)

lin_pred <- ref$grad$dic + gstar * (res[["P20   eps -20, g = 1"]]$grad$dic - ref$grad$dic)
cat(sprintf("\nLINEARITY CHECK (mode N): predicted DIC gradient %.3f, measured %.3f, |diff| %.2e umol/kg\n",
            lin_pred, both$grad$dic, abs(lin_pred - both$grad$dic)))
cat(sprintf("  %s\n", if (abs(lin_pred - both$grad$dic) < 1e-6)
    "CONFIRMED -- the constant-mass pump is exactly linear in the export scale."
  else "NOT CONFIRMED -- something in the shim is not linear. Debug before reading on."))

# =====================================================================
# PART 4. THE VERDICT, AGAINST THE RULE WRITTEN BEFORE THE RUN
# =====================================================================
sep("PART 4. SCORING THE PRE-REGISTERED RULE")
p20 <- res[["P20   eps -20, g = 1"]]
cat(sprintf("%-34s %10s %10s\n", "", "z_DIC", "z_d13C"))
cat(sprintf("%-34s %+10.2f %+10.2f\n", "pump OFF", ref$z_dic, ref$z_d13c))
cat(sprintf("%-34s %+10.2f %+10.2f\n", "the DIC pump (eps -20, g = 1)", p20$z_dic, p20$z_d13c))
cat(sprintf("%-34s %+10.2f %+10.2f\n", "eps*, g* (solved for both)", both$z_dic, both$z_d13c))
closes_both <- abs(p20$z_dic) < PG_Z_OK && abs(p20$z_d13c) < PG_Z_OK
cat(sprintf("\nRULE: both |z| < %g for the SAME arm, nothing refitted.\n", PG_Z_OK))
cat(sprintf("VERDICT: the pump that closes DIC %s close d13C.\n",
            if (closes_both) "ALSO DOES" else "DOES NOT"))
if (!closes_both) {
  # THE TEST IS THE TWO REQUIRED SCALES, NOT THE TWO SIGNS OF z, and the
  # difference is not cosmetic -- I wrote the sign test first and it returned
  # the WRONG verdict on this very run. Both z came out NEGATIVE here, which a
  # sign test reads as "same-sign miss, one scale fixes both". It does not: the
  # DIC target is POSITIVE (+233) so z < 0 means the pump is TOO SMALL, while
  # the d13C target is NEGATIVE (-0.861) so z < 0 means it supplied TOO MUCH
  # depletion. Equal signs of z are OPPOSITE corrections. Ask instead what
  # scale each row demands of the SAME export field; a single scale fixes both
  # only if the two agree.
  g_dic  <- (tg$dic$target  - ref$grad$dic)  / (p20$grad$dic  - ref$grad$dic)
  g_d13c <- (tg$d13c$target - ref$grad$d13c) / (p20$grad$d13c - ref$grad$d13c)
  one_scale <- abs(g_dic / g_d13c - 1) < 0.05
  cat(sprintf("  the DIC row demands export x %.3f;  the d13C row demands x %.3f\n",
              g_dic, g_d13c))
  cat(sprintf("  failure mode: %s\n", if (one_scale)
      "the two rows want the SAME export scale -- the mix is right and the SIZE is wrong."
    else sprintf(paste0("the two rows want export scales %.2fx apart -- NO single scale ",
                        "fixes both, so the FRACTIONATION is what is wrong."),
                 g_dic / g_d13c)))
  cat(sprintf("  size of the structural gap: eps* = %+.2f permil against soft-tissue's %+.2f,\n",
              epsstar, PG_EPS_ORG))
  cat(sprintf("  i.e. %.0f %% less depleted -- and only %+.1f log-units separate the two arms.\n",
              100 * (1 - epsstar / PG_EPS_ORG), both$total - p20$total))
  # The same two-component split as part 1, but solved against the fractionation
  # the TRANSIENT terms actually demand rather than the preindustrial pair's.
  f_org <- (epsstar - (PG_D13C_CARB - obs_surf_d13)) /
             (PG_EPS_ORG - (PG_D13C_CARB - obs_surf_d13))
  cat(sprintf("  implied soft-tissue share at eps*: %.0f %%, against %.0f %% from the\n",
              100 * f_org, 100 * x_org / tg$dic$target))
  cat("  PREINDUSTRIAL pair (part 1). The transient scoring more than halves the\n")
  cat("  carbonate limb the observed pair alone appears to demand.\n")
}
cat("\nWHAT THE OBJECTIVE SAYS, WHICH IS NOT THE SAME QUESTION:\n")
cat(sprintf("  logL   OFF %.1f   DIC pump %+.1f   eps*/g* %+.1f  (nothing refitted)\n",
            ref$total, p20$total - ref$total, both$total - ref$total))
cat("  A pump that closes both gradient rows while losing more elsewhere is\n")
cat("  still a loss. The per-stream table below is what says which.\n")

cat("\nper-stream change from OFF, biggest movers first:\n")
for (nm in names(res)[-1]) {
  e <- res[[nm]]; if (is.null(e)) next
  d <- e$parts - ref$parts[names(e$parts)]
  d <- sort(d[abs(d) > 1], decreasing = TRUE)
  cat(sprintf("\n  %s   (total %+.1f)\n", nm, e$total - ref$total))
  if (!length(d)) cat("    (no stream moves by more than 1 log-unit)\n")
  for (s in names(d)) cat(sprintf("    %-26s %+10.1f\n", s, d[[s]]))
}

# NUTRIENT-LIMITED vs DIC-LIMITED IS NOT A FREE CHOICE, and this is the one
# result here that was not asked for. diag_dic_gradient.R part 3 established
# that a constant-mass pump adds EXACTLY ZERO uptake, so the two modes differ
# only through channel 1 -- and channel 1 turns out to be worth more than both
# gradient rows put together at this operating point.
d20 <- res[["D20   eps -20, g = 1, DIC-l"]]
if (!is.null(d20)) {
  co2s <- intersect(c("co2_level_MLO", "co2_level_SPO", "co2_icecore"), names(ref$parts))
  cat(sprintf("\nMODE N vs MODE D, same epsilon and same export field:\n"))
  cat(sprintf("  d logL from OFF:        N %+.1f      D %+.1f      (D - N = %+.1f)\n",
              p20$total - ref$total, d20$total - ref$total, d20$total - p20$total))
  cat(sprintf("  of which CO2 streams:   N %+.1f        D %+.1f\n",
              sum(p20$parts[co2s] - ref$parts[co2s]),
              sum(d20$parts[co2s] - ref$parts[co2s])))
  cat(sprintf("  ocean sink 2010-2019:   N %.3f   D %.3f GtC/yr\n", p20$sink, d20$sink))
  cat("  The two gradient rows cannot tell N from D -- they move identically.\n")
  cat("  The CO2 RECORD can, and it prefers D by a wide margin with nothing\n")
  cat("  refitted. Flagged, NOT banked: a refit has `beta_max` and `kz` free and\n")
  cat("  could reallocate all of it. It does mean the N/D choice has to be made\n")
  cat("  deliberately in the port (task 9), not inherited from the shim.\n")
}

# =====================================================================
# PART 5. THE TWO PREDICTIONS, SCORED
# =====================================================================
sep("PART 5. THE HEADER'S TWO PREDICTIONS, SCORED")
cat(sprintf("PREDICTION 1 said the pump would overshoot d13C to z ~ -10.7 if the terms\n"))
cat(sprintf("were PREINDUSTRIAL. Measured on the TRANSIENT terms: z_d13C = %+.2f.\n", p20$z_d13c))
cat(sprintf("PREDICTION 2 said both rows land near -2 sigma, g* ~ 1.19, eps* ~ -15.\n"))
cat(sprintf("Measured: z_DIC %+.2f, z_d13C %+.2f, g* %.3f, eps* %+.2f.\n",
            p20$z_dic, p20$z_d13c, gstar, epsstar))
cat("\nhandoff 16b sec.2 quotes pump-OFF z of -11.0 (DIC) and +16.5 (d13C).\n")
cat(sprintf("MEASURED HERE at h_ml = %g: %+.2f and %+.2f.\n", PG_H_SCORE, ref$z_dic, ref$z_d13c))
cat(sprintf("  %s\n", if (abs(ref$z_dic + 11.0) < 1 && abs(ref$z_d13c - 16.5) < 1)
    "consistent -- the operating point does not move the pump-OFF rows much."
  else "NOT consistent with the handoff's numbers. THAT is the finding; everything above is downstream of it."))

# =====================================================================
# PART 6. DEFAULTS, TO SHOW HOW MUCH kz SETS THE PUMP'S SIZE
# =====================================================================
# The export field is solved against the model's own diffusion, so its magnitude
# is proportional to kz. This is the sensitivity, not a second verdict.
sep("PART 6. THE SAME TWO ARMS AT DEFAULTS -- kz SENSITIVITY ONLY")
pdef <- ccx_default_params()
res_def <- list()
for (a in list(list(id = "OFF   no pump", mode = NA,  eps = 0),
               list(id = "P20   eps -20, g = 1", mode = "N", eps = PG_EPS_ORG))) {
  t0 <- Sys.time()
  res_def[[a$id]] <- pg_eval(pdef, a$mode, a$eps, 1, PG_BOMB_REF, 1, PG_ERR_DEFAULT)
  cat(sprintf("  %-30s %5.0f s\n", a$id, as.numeric(Sys.time() - t0, units = "secs")))
}
pg_head(FALSE)
for (nm in names(res_def)) if (!is.null(res_def[[nm]])) pg_row(nm, res_def[[nm]])
cat(sprintf("\nexport required: %.2f GtC/yr at defaults (kz %g) vs %.2f at the mode (kz %g)\n",
            res_def[["P20   eps -20, g = 1"]]$export, pdef$kz, p20$export, pmode$kz))
cat("The pump's SIZE is a statement about kz, not only about biology -- the same\n")
cat("point diag_dic_gradient.R part 2 makes against Ledwell's NATRE diffusivity.\n")
cat(sprintf("\nAND IT IS NOT A SMALL STATEMENT. Literature global POC export at ~100 m is\n"))
cat(sprintf("%g-%g GtC/yr; the arm that CLOSES BOTH ROWS needs %.1f GtC/yr, i.e. %.1fx the\n",
            PG_EXPORT_LIT[1], PG_EXPORT_LIT[2], both$export,
            both$export / mean(PG_EXPORT_LIT)))
cat("midpoint. A 1-D effective kz that stands in for 3-D ventilation also destroys\n")
cat("GRADIENTS, so the pump must work that much harder than the real one. Read the\n")
cat("ratio as a statement about the column, not as a falsification of the pump --\n")
cat("and do NOT quote the required export as an estimate of real POC export.\n")

saveRDS(list(targets = tg, eps_pi = eps_pi, x_org = x_org, arms = res,
             arms_default = res_def, gstar = gstar, epsstar = epsstar,
             h_score = PG_H_SCORE, mode_label = mode_label),
        file.path(PG_OUTDIR, "diag_pump_vs_gradient_terms.rds"))
cat(sprintf("\n\nwritten: %s\n",
            file.path(PG_OUTDIR, "diag_pump_vs_gradient_terms.rds")))
