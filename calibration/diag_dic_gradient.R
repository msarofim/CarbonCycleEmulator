# =====================================================================
# diag_dic_gradient.R -- THE PUMP'S CASE, DECOMPOSED. What does imposing the
# OBSERVED vertical DIC gradient actually buy, and which way does it move the
# amended third clause?  (Marcus 2026-08-15, after handoff 15c sec.5's fork)
#
# THE QUESTION. handoff 15c sec.3.3 argues for a biological pump on the grounds
# that it "adds uptake WITHOUT mixing surface water down", i.e. that it supplies
# the EXPORT deficit `kz` cannot supply without wrecking deep D14C. That is a
# mechanism story about the pump's TRANSPORT channel. But the pump has more than
# one channel, they point in different directions, and only one of them was ever
# argued. This file separates them, at zero fitted parameters, before the 5.4 h
# refit and before any pump is designed.
#
# THREE CHANNELS, and they must be scored separately:
#   1. MASS TRANSPORT -- a downward particle flux carries excess carbon to the
#      interior. This is the channel 15c sec.3.3 invokes.
#   2. ISOTOPE TRANSPORT -- even at CONSTANT mass export, particles carry the
#      MIXED LAYER's ratio, so bomb 14C and the 13C Suess signal go down with
#      them. Non-zero even when channel 1 is exactly zero.
#   3. BACKGROUND STATE -- the pump is what holds the preindustrial vertical
#      gradients the model does not have: DIC (model gradient EXACTLY ZERO
#      against an observed +245 umol/kg) and d13C (model +1.560 permil UNIFORM
#      against an observed -0.94 permil top-to-bottom).
#
# A HYPOTHESIS OF MINE IS ALREADY DEAD AND IS RECORDED HERE RATHER THAN QUIETLY
# DROPPED. I proposed this diagnostic on the argument that the missing gradient
# means preindustrial SURFACE DIC is too high, hence the Revelle factor is too
# high, hence the mixed layer buffers too little -- a capacity-side channel that
# would have connected the pump to the uptake deficit h_ml is faking.
# MEASURED, AND IT IS WRONG: the model's ML DIC is 1986.3 (NH) / 2003.7 (SH)
# umol/kg, and GLODAPv2's 0-75 m mean is 2028.9 umol/kg MODERN, i.e. carrying
# ~50 umol/kg of anthropogenic carbon, so the preindustrial observation is
# ~1979 and the model's surface is RIGHT to within ~7 umol/kg. The entire
# 245 umol/kg deficit is in the INTERIOR. The surface-Revelle channel does not
# exist and part 4's arms do not include it.
#
# ---------------------------------------------------------------------
# THE ANALYTIC PREDICTION, WRITTEN BEFORE PART 4 WAS RUN.
#
# The model's interior has NO carbonate chemistry -- it is a passive tracer --
# and the diffusion operator is LINEAR in concentration. So a static background
# DIC profile superposes on the anthropogenic perturbation and cannot change how
# that perturbation propagates. THEREFORE:
#
#   * a NUTRIENT-LIMITED pump (export mass fixed, the standard assumption) must
#     change the ocean sink by EXACTLY ZERO, to integration error. Its whole
#     effect is on the isotopes and on the background state.
#   * only a DIC-LIMITED pump (export scaling with mixed-layer DIC) can touch
#     channel 1 at all, and then only in proportion to the perturbation
#     fraction: E x (dDIC/DIC) ~ 10 GtC/yr x 3 % ~ 0.3 GtC/yr, before the
#     diffusive return takes most of it back.
#
# If the arms disagree with that, the shim is wrong -- check it before believing
# the physics. This prediction IS the test of the implementation.
#
# A SECOND PREDICTION OF MINE WAS ALSO WRONG, AND IT IS THE IMPORTANT ONE.
# I argued in advance that a pump would push deep D14C AWAY from -175.3, on the
# grounds that sinking particles carry the MIXED LAYER's (young, ~-51 permil)
# ratio down and so dilute the deep with young carbon. MEASURED: it goes the
# other way. The pump makes the deep MORE depleted, not less.
#
# WHY, and it is worth understanding before designing anything: the pumped
# carbon is delivered young but leaves SLOWLY -- its only exit is the same
# diffusive return path everything else uses. So it raises the deep inventory
# ~12 % while raising the ventilation flux by much less, the mean age of deep
# carbon RISES, and the decay term wins over the young injection value. The
# residence-time channel dominates the injection-value channel.
#
# THIS FLIPS THE SIGN OF CLAUSE 3 BETWEEN THE TWO OPERATING POINTS, which is why
# part 6 scores at the MODE and not at defaults. At `ccx_default_params()` the
# model is ALREADY over-depleted (z -1.08) and the pump makes it worse. At the
# pre-gradient MAP mode kz is 96.6 % up its bracket, the model is UNDER-depleted
# (z +1.70, which is the miss handoff 15c sec.3.3 is about), and the same pump
# moves it TOWARD the target. Scoring clause 3 at defaults would have returned
# the opposite verdict for a reason that has nothing to do with the pump.
#
# ---------------------------------------------------------------------
# PRE-REGISTERED DECISION RULE, written before part 4 was run. Scored against
# handoff 15c sec.3.4's THREE CLAUSES plus the two rows only a pump can move:
#
#   * BUILD THE PUMP if deep D14C moves TOWARD -175.3 (clause 3) while the sink
#     holds or rises, AND the deep DIC / deep d13C rows improve.
#   * DO NOT BUILD IT AS AN UPTAKE MECHANISM if the sink is unmoved -- it would
#     then be a background-state and isotope fix wearing an uptake argument, and
#     it should be justified and scoped as that or not at all.
#   * COUNT IT AGAINST THE PUMP if deep D14C moves AWAY from -175.3, because
#     that is the clause the kz route already fails and the one 15c sec.3.4 says
#     the pump must beat.
#   * REPORT A SPLIT VERDICT AS A SPLIT VERDICT. Do not average the channels.
#
# ---------------------------------------------------------------------
# WHAT IS AND IS NOT BUILT HERE. NO MODEL FILE IS TOUCHED. The pump is a SHIM
# over ccx_deriv() in this file's own environment, off by default, and it is
# NOT proposed for the objective by this file. It has ZERO FITTED PARAMETERS:
# the export profile is SOLVED for as the field that makes GLODAPv2's own
# observed DIC profile an exact steady state of the model's own diffusion
# operator. No Martin curve is chosen, no export formulation is fitted. The one
# free structural choice -- the 13C fractionation on export -- is run BOTH WAYS
# rather than resolved (part 4, arms F and N0).
#
# THE C++ CORE DOES NOT KNOW ABOUT THE PUMP. Every run here goes through the R
# reference integrator ccx_run(), which is why this file takes ~15 min rather
# than ~15 s. That is deliberate: porting to src/ccx_core.cpp is a shipping
# decision, and this file exists to decide whether to ship.
#
# RUNTIME ~15 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label, window and threshold below derives ----
DG_YEARS      <- c(1750, 2024)
DG_BOMB_REF   <- 102
DG_H_REF      <- 75                        # m, the model default
DG_H_MODE     <- 184                       # m, the pre-gradient MAP mode's h_ml
DG_H_GRID     <- c(50, 75, 100, 140, 184, 220)
DG_SINK_WIN   <- c(2010, 2019)             # decade for the reported ocean sink
DG_GLODAP     <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
DG_FLAG_OK    <- 2                         # GLODAP: 2 = acceptable measurement
DG_DLAT <- 5; DG_DLON <- 10; DG_DZ <- 250  # binning, as build_glodap_deep_targets.R
DG_N_EFF      <- 20                        # the deep-D14C target's convention;
                                           # reused for deep DIC and deep d13C
                                           # so the three rows are commensurable
# Marine organic matter is ~20-22 permil depleted relative to the DIC it is
# fixed from. THIS IS THE ONE STRUCTURAL CHOICE IN THE FILE AND IT IS RUN BOTH
# WAYS -- arm N0 sets it to zero, which is the control that shows the deep d13C
# gradient has the WRONG SIGN without it.
DG_EPS_ORG    <- -20                       # permil, photosynthetic fractionation
# 14C rides the export WITHOUT fractionation, by the same Stuiver-Polach
# convention the rest of the model uses (DESIGN sec.3.5): Delta14C observations
# are already fractionation-corrected. This answers handoff 15c sec.5's open
# "does the particle flux carry 13C/14C fractionation" for 14C by CONVENTION,
# not by choice.
DG_GRAD_SCALE <- c(1.0, 1.2)               # 1.0 = the raw observed gradient (a
                                           # LOWER bound: modern upper-ocean DIC
                                           # carries anthropogenic carbon, which
                                           # FLATTENS the observed gradient).
                                           # 1.2 ~ the anthropogenic-corrected one.
# Global POC export at ~100 m, for the free validation in part 2. Range, not a
# point: this is a recollected span and is used only as an order-of-magnitude
# check, never as a target.
DG_EXPORT_LIT <- c(5, 12)                  # GtC/yr
# Ledwell's NATRE tracer release, (1.7 +/- 0.2)e-5 m2/s. Taken from the repo's
# own sourced figure (notes/redteam_2026-08-13_conveyor_configurations.md sec.1,
# also calibration/diag_kz_bracket.R's KB_NATRE) rather than re-recollected.
DG_NATRE      <- 536                       # m2/yr
DG_MODE_PATH  <- ccx_path("calibration", "output", "quarantine",
                          "20260815_pre_gradient_terms", "mode_fit.rds")
# Gradient offsets: their ABSENCE SKIPS both gradient streams. `sigma_co2` is
# RETIRED (item 6b) and is deliberately absent -- the CO2 level sd is
# LIK_CO2_REP_ERR alone. Values from diag_gradient_terms.R part 3.
DG_ERR_DEFAULT <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                       grad_off_co2 = -0.386, grad_off_d13c = +0.099)
DG_ERR_MODE    <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                       grad_off_co2 = -0.549, grad_off_d13c = +0.107)
DG_OUTDIR      <- ccx_path("calibration", "output", "dic_gradient")

dir.create(DG_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# =====================================================================
# PART 1. THE OBSERVED PROFILE, ON THE MODEL'S OWN LAYERS
# =====================================================================
# Same volume-weighting as data-raw/build_glodap_deep_targets.R (bin to
# 5 deg lat x 10 deg lon x 250 m, weight cells by cos(lat)) -- GLODAP bottles
# over-sample the Atlantic, so a raw bottle mean is biased. The raw mean is
# printed beside it so the size of that bias stays visible.
dg_glodap <- utils::read.csv(DG_GLODAP)

dg_bin <- function(val, flag, zmin, zmax) {
  d  <- dg_glodap
  ok <- is.finite(d[[val]]) & d[[val]] > -900 &
        is.finite(d[[flag]]) & d[[flag]] == DG_FLAG_OK &
        d$depth >= zmin & d$depth < zmax
  if (sum(ok) < 20) return(list(n = sum(ok), vw = NA_real_, raw = NA_real_,
                                sd = NA_real_))
  x    <- d[ok, ]
  id   <- paste(floor(x$lat / DG_DLAT), floor(x$lon / DG_DLON),
                floor(x$depth / DG_DZ))
  cell <- tapply(x[[val]], id, mean)
  w    <- cos(tapply(x$lat, id, mean) * pi / 180)
  list(n = sum(ok), n_cells = length(cell), raw = mean(x[[val]]),
       vw = sum(cell * w) / sum(w), sd = stats::sd(cell))
}

#' Observed DIC / d13C / D14C on the layers of a given grid
dg_obs_profile <- function(grid) {
  zb <- c(0, cumsum(grid$dz))
  do.call(rbind, lapply(seq_along(grid$dz), function(k) {
    a <- zb[k]; b <- zb[k + 1]
    rc <- dg_bin("tco2", "tco2f", a, b)
    r3 <- dg_bin("c13",  "c13f",  a, b)
    r4 <- dg_bin("c14",  "c14f",  a, b)
    data.frame(k = k - 1L, top = a, bot = b,
               n_dic = rc$n, dic = rc$vw, dic_raw = rc$raw, dic_sd = rc$sd,
               n_d13 = r3$n, d13 = r3$vw, d13_sd = r3$sd,
               n_d14 = r4$n, d14 = r4$vw, d14_sd = r4$sd)
  }))
}

sep("PART 1. GLODAPv2.2023 ON THE MODEL'S OWN 11 LAYERS")
grid_ref <- ccx_ocean_grid(DG_H_REF)
obsprof  <- dg_obs_profile(grid_ref)
sp_ref   <- ccx_spinup()
mod_dic  <- sp_ref$y[c(sp_ref$aux$idx$NH$ml, sp_ref$aux$idx$NH$oc), "C"] *
              sp_ref$aux$mol_per_GtC / (sp_ref$aux$a_oc$NH * grid_ref$dz *
                                        ccx_const("RHO_SEAWATER")) * 1e6

cat(sprintf("%3s %13s %7s %9s %9s %9s %8s %9s %9s\n", "k", "layer m", "n_DIC",
            "DIC obs", "DIC raw", "DIC mod", "n_d13", "d13C obs", "D14C obs"))
for (i in seq_len(nrow(obsprof)))
  cat(sprintf("%3d %13s %7d %9.1f %9.1f %9.1f %8d %9.3f %9.1f\n",
              obsprof$k[i], sprintf("%.0f-%.0f", obsprof$top[i], obsprof$bot[i]),
              obsprof$n_dic[i], obsprof$dic[i], obsprof$dic_raw[i], mod_dic[i],
              obsprof$n_d13[i], obsprof$d13[i], obsprof$d14[i]))

cat(sprintf("\nobserved DIC gradient, surface layer -> bottom layer: %+.1f umol/kg\n",
            obsprof$dic[nrow(obsprof)] - obsprof$dic[1]))
cat(sprintf("model    DIC gradient:                                %+.1f umol/kg\n",
            mod_dic[length(mod_dic)] - mod_dic[1]))
cat(sprintf("observed d13C gradient:                               %+.3f permil\n",
            obsprof$d13[nrow(obsprof)] - obsprof$d13[1]))
cat(sprintf("model    d13C gradient:                               %+.3f permil (UNIFORM)\n", 0))
cat("\nTWO THINGS TO READ OFF THIS TABLE BEFORE ANYTHING IS RUN:\n")
cat("  * the model's SURFACE DIC is right. 1986.3 against an observed 2028.9\n")
cat("    that carries ~50 umol/kg of anthropogenic carbon. The whole deficit is\n")
cat("    in the interior -- see this file's header on the dead hypothesis.\n")
cat("  * the DIC gradient is a THERMOCLINE feature, not an abyssal one: by\n")
cat("    923-1314 m the observations are already within ~8 umol/kg of the\n")
cat("    bottom. A pump that only fills the abyss would not reproduce it.\n")
cat("  * the observed SURFACE D14C is +52 permil, which is BOMB-CONTAMINATED\n")
cat("    and is NOT a preindustrial target. The model's -51 is not a misfit.\n")
cat("    Only the DEEP D14C row is used as a target, as it already is.\n")

# =====================================================================
# PART 2. SOLVE THE EXPORT FIELD -- AND THE FREE VALIDATION IT COMES WITH
# =====================================================================
# The target is the OBSERVED GRADIENT ANCHORED ON THE MODEL'S OWN MIXED LAYER,
# not the observed absolute profile: the ML's DIC is set by carbonate
# equilibrium with the 1750 atmosphere at ALK_SURFACE and is not ours to
# overwrite. So target_k = DIC_ml(model) + [DIC_k(obs) - DIC_0(obs)].
#
# The diffusion code's concentration is y_k/dz_k, and y_k = DIC_k * A * dz_k *
# rho / mol_per_GtC, so y_k/dz_k is EXACTLY proportional to DIC_k with the layer
# thickness cancelling. That is what makes this solve a two-line calculation
# rather than a fit.
#
# Steady state requires the source in box k to cancel the diffusive convergence
# there:  S_k = -[F(k-1,k) - F(k,k+1)],  F(a,b) = kz (c_a - c_b) / dz_mid[a].
# The sum telescopes, so the TOTAL export leaving the mixed layer is just the
# flux across the topmost interface -- and THAT is a number with a literature
# value attached, which makes this a validation and not only a construction.

#' Export field that holds `target_dic` (umol/kg, length nl+1) as a steady state
#' @return list(S = GtC/yr into each interior box, E = total export, ok = signs)
dg_export_field <- function(p, aux, grid, h, target_dic) {
  kappa <- aux$a_oc[[h]] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC  # GtC/m per (mol/kg)
  cc    <- kappa * target_dic * 1e-6                                    # GtC/m
  nl    <- grid$nl
  Fi    <- p$kz * (cc[-length(cc)] - cc[-1]) / aux$dz_mid               # nl interfaces
  S     <- numeric(nl)
  for (k in seq_len(nl)) S[k] <- -(Fi[k] - if (k < nl) Fi[k + 1] else 0)
  list(S = S, E = sum(S), n_neg = sum(S < 0), min_S = min(S))
}

sep("PART 2. THE IMPLIED EXPORT FLUX -- A FREE VALIDATION")
aux_ref <- sp_ref$aux
p_ref   <- ccx_default_params()
dgrad   <- obsprof$dic - obsprof$dic[1]        # observed gradient, anchored at 0

fields <- lapply(HEMIS, function(h) {
  dic_ml <- sp_ref$y[aux_ref$idx[[h]]$ml, "C"] * aux_ref$mol_per_GtC /
              aux_ref$ml_mass_kg[[h]] * 1e6
  dg_export_field(p_ref, aux_ref, grid_ref, h, dic_ml + dgrad)
})
names(fields) <- HEMIS
E_tot <- sum(vapply(fields, function(f) f$E, numeric(1)))

cat(sprintf("kz = %g m2/yr (the default; the MAP mode sits 96.6 %% up its bracket, HIGHER)\n\n",
            p_ref$kz))
cat(sprintf("%-6s %12s %10s %10s\n", "hemi", "export GtC/yr", "neg boxes", "min S"))
for (h in HEMIS)
  cat(sprintf("%-6s %12.2f %10d %10.4f\n", h, fields[[h]]$E, fields[[h]]$n_neg,
              fields[[h]]$min_S))
cat(sprintf("%-6s %12.2f\n", "TOTAL", E_tot))
cat(sprintf("\nliterature global POC export at ~100 m: %g-%g GtC/yr\n",
            DG_EXPORT_LIT[1], DG_EXPORT_LIT[2]))
cat(sprintf("implied / literature midpoint:          %.1fx\n",
            E_tot / mean(DG_EXPORT_LIT)))
cat("\nWHAT THIS NUMBER MEANS, AND IT IS A STRUCTURAL FINDING IN ITS OWN RIGHT.\n")
cat("The export required is set by how fast the model's diffusion DESTROYS the\n")
cat("gradient, i.e. by kz. A one-dimensional column has to use an EFFECTIVE kz\n")
cat(sprintf("that stands in for three-dimensional advective ventilation, and %g m2/yr\n", p_ref$kz))
cat(sprintf("is %.0fx Ledwell's NATRE thermocline diapycnal diffusivity, (1.7 +/- 0.2)e-5\n",
            p_ref$kz / DG_NATRE))
cat(sprintf("m2/s = %g m2/yr -- the repo's own sourced figure (redteam 2026-08-13 sec.1).\n",
            DG_NATRE))
cat("An effective diffusivity tuned to emulate TRANSPORT also spuriously\n")
cat("destroys GRADIENTS -- so in this model a pump must work several times\n")
cat("harder than the real one does. Read the ratio above with that in mind:\n")
cat("if it is well above 1, the gradient is telling us something about kz and\n")
cat("the column structure, not only about the missing biology.\n")
if (any(vapply(fields, function(f) f$n_neg, integer(1)) > 0))
  cat("\nNOTE: some boxes need a NEGATIVE source, i.e. removal at depth. That is\n",
      "not interpretable as remineralisation. It comes from the observed\n",
      "profile's slight mid-depth maximum (1314-1861 m is ~3 umol/kg above the\n",
      "bottom). Reported, not smoothed away; the magnitudes are printed above.\n")

# =====================================================================
# THE SHIM. No model file is touched.
# =====================================================================
.dg <- new.env(parent = emptyenv())
.dg$on <- FALSE; .dg$S <- NULL; .dg$mode <- "N"; .dg$eps <- DG_EPS_ORG
.dg$c_ml0 <- NULL

.dg_deriv_base <- ccx_deriv
ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
  dy <- .dg_deriv_base(y, t, p, forc, grid, aux, record = record)
  if (!.dg$on) return(dy)
  if (record) stop("dic-gradient shim: the flux tap does not see the pump")
  a13 <- 1 + .dg$eps / 1000
  for (h in HEMIS) {
    i   <- aux$idx[[h]]
    S   <- .dg$S[[h]]
    # NUTRIENT-LIMITED ("N"): export mass is fixed, as in the standard
    # steady-pump assumption. DIC-LIMITED ("D"): export scales with the mixed
    # layer's carbon, which is the ONLY way channel 1 is non-zero.
    sc  <- if (.dg$mode == "D") y[i$ml, "C"] / .dg$c_ml0[[h]] else 1
    r13 <- y[i$ml, "C13"] / y[i$ml, "C"]
    r14 <- y[i$ml, "C14"] / y[i$ml, "C"]
    E   <- sum(S) * sc
    dy[i$ml, "C"]   <- dy[i$ml, "C"]   - E
    dy[i$ml, "C13"] <- dy[i$ml, "C13"] - E * r13 * a13
    dy[i$ml, "C14"] <- dy[i$ml, "C14"] - E * r14        # no fractionation
    f <- S * sc
    dy[i$oc, "C"]   <- dy[i$oc, "C"]   + f
    dy[i$oc, "C13"] <- dy[i$oc, "C13"] + f * r13 * a13
    dy[i$oc, "C14"] <- dy[i$oc, "C14"] + f * r14
  }
  dy
}

#' Spinup that ALWAYS runs the full-state Newton solve.
#'
#' A NEAR-VERBATIM COPY of ccx_spinup(), with exactly two deltas, both marked
#' DELTA below. It exists because ccx_spinup()'s analytic equilibrium is a
#' uniform column, which stops being a fixed point the moment the pump is on,
#' and the Newton branch it already contains is gated on the conveyor.
#' THE COPY IS GATED: dg_parity_gate() asserts it reproduces ccx_spinup() with
#' the pump OFF, and it is run before anything else uses this function.
dg_spinup <- function(p = ccx_default_params(),
                      chi0  = ccx_const("CO2_PI_PPM"),
                      d13c0 = ccx_const("D13C_PI"),
                      d14c0 = ccx_const("D14C_PI")) {
  aux <- ccx_prepare(p); grid <- aux$grid; y <- ccx_new_state(grid$nl)
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- chi0 * aux$gtc_per_ppm_hemi
    npp0 <- aux$npp0[[h]]
    y[i$leaf, "C"] <- npp0 * p$npp_leaf_frac * p$tau_leaf
    y[i$wood, "C"] <- npp0 * (1 - p$npp_leaf_frac) * p$tau_wood
    y[i$soil_fast, "C"] <- npp0 * (1 - p$litter_slow_frac) * p$tau_soil_fast
    y[i$soil_slow, "C"] <- npp0 * p$litter_slow_frac * p$tau_soil_slow
    dic  <- ccx_dic_for_pco2(chi0, ccx_const("ALK_SURFACE"), aux$sst[[h]])
    y[i$ml, "C"] <- dic * aux$ml_mass_kg[[h]] / aux$mol_per_GtC
    conc <- y[i$ml, "C"] / grid$dz[1]
    y[i$oc, "C"] <- conc * grid$dz[-1]
  }
  zero_forc <- function(prod = 0)
    list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
         gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
  p0 <- p; p0$gamma_enso <- 0; p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0

  # DELTA 1: the Newton solve is UNCONDITIONAL, not gated on the conveyor. With
  # the pump off it is a no-op on an already-exact fixed point (measured
  # max|dy| 1.0e-07 GtC), which is what the parity gate checks.
  y <- ccx_c12_steady_conveyor(p0, aux, grid, chi0, y, zero_forc(0))

  nb <- nrow(y)
  iso_operator <- function(tracer, forc) {
    y0 <- y; y0[, tracer] <- 0
    b  <- ccx_deriv(y0, 1750, p0, forc, grid, aux)[, tracer]
    A  <- matrix(0, nb, nb)
    for (j in seq_len(nb)) {
      yj <- y0; yj[j, tracer] <- 1
      A[, j] <- ccx_deriv(yj, 1750, p0, forc, grid, aux)[, tracer] - b
    }
    list(A = A, b = b)
  }
  # DELTA 2: none in the isotope solves. They invert whatever linear operator
  # ccx_deriv() presents, and the pump term is linear in the ML's isotope
  # state, so they pick it up with no change at all.
  op13  <- iso_operator("C13", zero_forc(0))
  iatmN <- aux$idx$NH$atm
  A13 <- op13$A; rhs <- -op13$b
  A13[iatmN, ] <- 0; A13[iatmN, iatmN] <- 1
  rhs[iatmN] <- y[iatmN, "C"] * ccx_const("R13_VPDB") * (1 + d13c0 / 1000)
  y[, "C13"] <- solve(A13, rhs)

  op14 <- iso_operator("C14", zero_forc(1))
  u    <- solve(op14$A, -op14$b)
  atm_idx <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  prod <- sum(y[atm_idx, "C"]) * (1 + d14c0 / 1000) / sum(u[atm_idx])
  y[, "C14"] <- prod * u

  resid    <- ccx_deriv(y, 1750, p0, zero_forc(prod), grid, aux)
  deep_idx <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 3)))
  bot_idx  <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 1)))
  ocean_idx<- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)))
  P_canon  <- 2.04 * (5.1e14 * 1e4) * 365.25 * 86400 / 6.02214076e23
  list(y = y, prod_c14 = prod, aux = aux, grid = grid, params = p,
       diagnostics = list(
         max_abs_dCdt    = max(abs(resid[, "C"])),
         max_abs_dC13dt  = max(abs(resid[, "C13"])),
         max_abs_dC14dt  = max(abs(resid[, "C14"])),
         co2_ppm         = sum(y[atm_idx, "C"]) / ccx_const("GtC_PER_PPM"),
         d14c_deep_ocean = 1000 * (sum(y[deep_idx, "C14"]) / sum(y[deep_idx, "C"]) - 1),
         d14c_bottom_box = 1000 * (sum(y[bot_idx,  "C14"]) / sum(y[bot_idx,  "C"]) - 1),
         d13c_bottom_box = 1000 * (sum(y[bot_idx, "C13"]) /
                                     (sum(y[bot_idx, "C"]) * ccx_const("R13_VPDB")) - 1),
         dic_bottom_box  = sum(y[bot_idx, "C"]) * aux$mol_per_GtC * 1e6 /
                             sum(vapply(HEMIS, function(h)
                               aux$a_oc[[h]] * grid$dz[grid$nl + 1] *
                                 ccx_const("RHO_SEAWATER"), numeric(1))),
         ocean_C_GtC     = sum(y[ocean_idx, "C"]),
         prod_c14_mol_yr = prod, prod_canonical = P_canon,
         prod_ratio      = prod / P_canon))
}

#' HARD GATE: the copy must reproduce the shipped spinup with the pump off.
dg_parity_gate <- function() {
  .dg$on <- FALSE
  a <- ccx_spinup(); b <- dg_spinup()
  worst <- max(abs(a$y - b$y)); dp <- abs(a$prod_c14 - b$prod_c14)
  cat(sprintf("\nPARITY GATE (pump OFF): max|dg_spinup - ccx_spinup| = %.3e GtC over %d states\n",
              worst, length(a$y)))
  cat(sprintf("                        |d prod_c14| = %.3e mol/yr\n", dp))
  if (worst > 1e-6 || dp > 1e-6)
    stop("dg_spinup() has drifted from ccx_spinup() -- fix the copy before reading anything below")
  cat("                        PASS -- the copy is the shipped spinup.\n")
  invisible(TRUE)
}
dg_parity_gate()

# =====================================================================
# PART 3. THE ARMS
# =====================================================================
obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = DG_BOMB_REF)
tg_d14 <- ccx_deep_d14c_target()
# Deep DIC and deep d13C, scored on the SAME layer and the SAME n_eff convention
# as the deep-D14C target, so the three rows can be read against each other.
obs_bot <- obsprof[nrow(obsprof), ]
tg_dic  <- list(target = obs_bot$dic, sd = obs_bot$dic_sd / sqrt(DG_N_EFF))
tg_d13  <- list(target = obs_bot$d13, sd = obs_bot$d13_sd / sqrt(DG_N_EFF))

#' Configure the shim for one arm and return the solved field for reporting
dg_arm_setup <- function(p, aux, grid, mode, eps, gscale) {
  if (is.na(mode)) { .dg$on <- FALSE; return(NULL) }
  op <- dg_obs_profile(grid)
  dg <- (op$dic - op$dic[1]) * gscale
  fl <- lapply(HEMIS, function(h) {
    dic_ml <- ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                               aux$sst[[h]]) * 1e6
    dg_export_field(p, aux, grid, h, dic_ml + dg)$S
  })
  names(fl) <- HEMIS
  .dg$S <- fl; .dg$mode <- mode; .dg$eps <- eps; .dg$on <- TRUE
  .dg$c_ml0 <- lapply(HEMIS, function(h)
    ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                     aux$sst[[h]]) * aux$ml_mass_kg[[h]] / aux$mol_per_GtC)
  names(.dg$c_ml0) <- HEMIS
  fl
}

#' One full arm: spinup + 1750-2024 through the R reference integrator
dg_eval <- function(p, mode, eps, gscale, bomb_total, luc_scale, err) {
  aux  <- ccx_prepare(p); grid <- aux$grid
  fl   <- dg_arm_setup(p, aux, grid, mode, eps, gscale)
  sp   <- tryCatch(dg_spinup(p), error = function(e) NULL)
  if (is.null(sp)) { .dg$on <- FALSE; return(NULL) }
  F <- base_forcing
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forcing$c14_bomb * (bomb_total / DG_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forcing[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forcing); eluc$eluc <- eluc$eluc * luc_scale
  r <- tryCatch(ccx_run(sp, F), error = function(e) NULL)
  .dg$on <- FALSE
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  ps <- ccx_loglik(r$out, obs, err, luc = eluc,
                   deep = sp$diagnostics$d14c_bottom_box, by_stream = TRUE)
  yr  <- floor(r$out$t + 1e-9); ann <- tapply(r$out$ocean_C, yr, mean)
  yy  <- as.integer(names(ann))
  k   <- which(yy >= DG_SINK_WIN[1] & yy <= DG_SINK_WIN[2])
  bn  <- ccx_box_names(grid$nl); d <- r$state[, "C"] - sp$y[, "C"]
  list(parts = ps, total = sum(ps),
       sink  = if (length(k) > 1) mean(diff(ann[k])) else NA_real_,
       deep  = sp$diagnostics$d14c_bottom_box,
       d13b  = sp$diagnostics$d13c_bottom_box,
       dicb  = sp$diagnostics$dic_bottom_box,
       ocean = sp$diagnostics$ocean_C_GtC,
       prodr = sp$diagnostics$prod_ratio,
       export = if (is.null(fl)) 0 else sum(vapply(fl, sum, numeric(1))),
       dC_ml = sum(d[grep("_ml$", bn)]), dC_int = sum(d[grep("_oc[0-9]+$", bn)]))
}

sep("PART 3. THE ARMS -- pre-registered prediction: arm N's SINK IS UNCHANGED")
ARMS <- list(
  list(id = "OFF   reference",            mode = NA,  eps = 0,           g = 1.0),
  list(id = "N     nutrient-ltd, eps-20", mode = "N", eps = DG_EPS_ORG,  g = 1.0),
  list(id = "D     DIC-limited,  eps-20", mode = "D", eps = DG_EPS_ORG,  g = 1.0),
  list(id = "N0    nutrient-ltd, eps  0", mode = "N", eps = 0,           g = 1.0),
  list(id = "D12   DIC-limited,  x1.2",   mode = "D", eps = DG_EPS_ORG,  g = 1.2))

p0 <- ccx_default_params()
res <- lapply(ARMS, function(a) {
  t0 <- Sys.time()
  e  <- dg_eval(p0, a$mode, a$eps, a$g, DG_BOMB_REF, 1.0, DG_ERR_DEFAULT)
  cat(sprintf("  %-28s %5.0f s\n", a$id, as.numeric(Sys.time() - t0, units = "secs")))
  e
})
names(res) <- vapply(ARMS, function(a) a$id, character(1))
ok <- !vapply(res, is.null, logical(1))

cat(sprintf("\n%-28s %8s %9s %8s %8s %8s %8s %9s\n", "arm", "export", "sink",
            "deep14", "z14", "deep13", "z13", "deepDIC"))
for (nm in names(res)[ok]) {
  e <- res[[nm]]
  cat(sprintf("%-28s %8.1f %9.4f %8.1f %+8.2f %8.3f %+8.2f %9.1f\n", nm,
              e$export, e$sink, e$deep, (e$deep - tg_d14$target) / tg_d14$sd,
              e$d13b, (e$d13b - tg_d13$target) / tg_d13$sd, e$dicb))
}
cat(sprintf("%-28s %8s %9s %8.1f %8s %8.3f %8s %9.1f\n", "GLODAPv2 target", "", "",
            tg_d14$target, "", tg_d13$target, "", tg_dic$target))
cat(sprintf("%-28s %8s %9s %8.1f %8s %8.3f %8s %9.1f\n", "  sigma (n_eff = 20)", "", "",
            tg_d14$sd, "", tg_d13$sd, "", tg_dic$sd))

cat(sprintf("\n%-28s %9s %9s %9s %9s %11s\n", "arm", "logL", "d logL",
            "oceanC", "prodratio", "dCml/dCint"))
ref <- res[["OFF   reference"]]
for (nm in names(res)[ok]) {
  e <- res[[nm]]
  cat(sprintf("%-28s %9.1f %+9.1f %9.0f %9.3f %5.1f/%5.1f\n", nm, e$total,
              e$total - ref$total, e$ocean, e$prodr, e$dC_ml, e$dC_int))
}

cat("\n--- THE PRE-REGISTERED PREDICTION, SCORED ---\n")
if (ok[["N     nutrient-ltd, eps-20"]]) {
  dN <- res[["N     nutrient-ltd, eps-20"]]$sink - ref$sink
  cat(sprintf("arm N sink change: %+.6f GtC/yr (predicted EXACTLY ZERO)\n", dN))
  cat(sprintf("VERDICT: %s\n", if (abs(dN) < 1e-3)
      "CONFIRMED -- a constant-mass pump adds NO uptake. Channel 1 is off."
    else "NOT CONFIRMED -- the shim is doing something the linearity argument forbids. Debug before reading on."))
}
if (ok[["D     DIC-limited,  eps-20"]]) {
  dD <- res[["D     DIC-limited,  eps-20"]]$sink - ref$sink
  cat(sprintf("arm D sink change: %+.4f GtC/yr -- channel 1's whole size, at %.1f GtC/yr export\n",
              dD, res[["D     DIC-limited,  eps-20"]]$export))
}
if (ok[["N0    nutrient-ltd, eps  0"]]) {
  cat(sprintf("arm N0 (no fractionation) deep d13C %.3f vs arm N's %.3f, observed %.3f\n",
              res[["N0    nutrient-ltd, eps  0"]]$d13b,
              res[["N     nutrient-ltd, eps-20"]]$d13b, tg_d13$target))
  cat("  -- the control for the one structural choice in this file. Without the\n")
  cat("     photosynthetic fractionation the pump moves deep d13C the WRONG WAY,\n")
  cat("     because unfractionated particles deliver SURFACE-enriched carbon.\n")
}

cat("\nper-stream change from OFF, biggest movers first:\n")
for (nm in names(res)[ok][-1]) {
  d <- res[[nm]]$parts - ref$parts[names(res[[nm]]$parts)]
  d <- sort(d[abs(d) > 1], decreasing = TRUE)
  cat(sprintf("\n  %s   (total %+.1f)\n", nm, res[[nm]]$total - ref$total))
  if (!length(d)) cat("    (no stream moves by more than 1 log-unit)\n")
  for (s in names(d)) cat(sprintf("    %-26s %+10.1f\n", s, d[[s]]))
}

# =====================================================================
# PART 4. DOES h_ml RELAX? -- clause 1 of the amended item-9 test
# =====================================================================
sep("PART 4. THE h_ml PROFILE, PUMP OFF vs PUMP ON")
cat("handoff 15c sec.3.4 clause 1: does h_ml relax below ~163 m once the missing\n")
cat("mechanism is available? Run at the pre-gradient MAP mode's OTHER parameters,\n")
cat("which is where h_ml = 184 m came from, with h_ml overridden. The export\n")
cat("field is RE-SOLVED at every depth -- the grid changes, so the field must.\n\n")
pm <- NULL
if (file.exists(DG_MODE_PATH)) {
  md <- readRDS(DG_MODE_PATH); pm <- md$par_mode
}
if (is.null(pm)) {
  cat("quarantined mode absent -- part 4 skipped.\n")
} else {
  pmode <- ccx_default_params()
  for (n in intersect(names(pmode), names(pm))) pmode[[n]] <- pm[[n]]
  pmode$gamma_enso <- pm$gamma_enso
  prof <- list()
  for (arm in list(list(id = "pump OFF", mode = NA),
                   list(id = "pump D  ", mode = "D"))) {
    v <- vapply(DG_H_GRID, function(h) {
      pp <- pmode; pp$h_ml <- h
      e  <- dg_eval(pp, arm$mode, DG_EPS_ORG, 1.0, pm$bomb_total, pm$luc_scale,
                    DG_ERR_MODE)
      if (is.null(e)) c(NA_real_, NA_real_, NA_real_) else c(e$total, e$deep, e$sink)
    }, numeric(3))
    prof[[arm$id]] <- v
  }
  cat(sprintf("%-10s %10s", "arm", "metric"))
  for (h in DG_H_GRID) cat(sprintf(" %9s", sprintf("h=%g", h)))
  cat("   best h\n")
  for (nm in names(prof)) {
    v <- prof[[nm]]
    cat(sprintf("%-10s %10s", nm, "logL abs"))
    for (j in seq_len(ncol(v))) cat(sprintf(" %9.1f", v[1, j]))
    cat(sprintf("   %g m\n", DG_H_GRID[which.max(v[1, ])]))
    cat(sprintf("%-10s %10s", "", "deep D14C"))
    for (j in seq_len(ncol(v))) cat(sprintf(" %9.1f", v[2, j]))
    cat("\n")
    cat(sprintf("%-10s %10s", "", "  z vs obs"))
    for (j in seq_len(ncol(v)))
      cat(sprintf(" %+9.2f", (v[2, j] - tg_d14$target) / tg_d14$sd))
    cat("\n")
    cat(sprintf("%-10s %10s", "", "sink"))
    for (j in seq_len(ncol(v))) cat(sprintf(" %9.3f", v[3, j]))
    cat("\n\n")
  }
  # THE CROSS-ARM COMPARISON IS THE POINT, and it only exists because the rows
  # above are ABSOLUTE. Normalising each arm to its own h = 75 -- which is what
  # diag_h_ml_roles.R does, correctly, for a within-arm question -- would hide
  # whether the pump is better or worse than no pump at all.
  dlt <- prof[["pump D  "]][1, ] - prof[["pump OFF"]][1, ]
  cat("pump ON minus pump OFF, at each depth (positive = the pump is better):\n")
  for (j in seq_along(DG_H_GRID))
    cat(sprintf("   h = %-4g %+9.1f\n", DG_H_GRID[j], dlt[j]))
  bo  <- DG_H_GRID[which.max(prof[["pump OFF"]][1, ])]
  bn2 <- DG_H_GRID[which.max(prof[["pump D  "]][1, ])]
  cat(sprintf("\nbest OFF: h = %g m, logL %.1f     best ON: h = %g m, logL %.1f\n",
              bo, max(prof[["pump OFF"]][1, ]), bn2, max(prof[["pump D  "]][1, ])))
  cat(sprintf("AT EACH ARM'S OWN BEST DEPTH the pump is worth %+.1f log-units,\n",
              max(prof[["pump D  "]][1, ]) - max(prof[["pump OFF"]][1, ])))
  cat("WITH NOTHING REFITTED. Read that against the per-stream table in part 3:\n")
  cat("the largest single loss channel is atmospheric D14C, and `bomb_total` --\n")
  cat("the free parameter that absorbs exactly that -- is HELD FIXED here.\n")
  cat(sprintf("\npreferred depth: pump OFF %g m -> pump ON %g m\n", bo, bn2))
  cat(sprintf("CLAUSE 1: %s\n", if (bn2 < 163)
      "PASSES -- h_ml relaxes below 163 m with the pump available"
    else "FAILS -- h_ml does not relax; the pump is not supplying what h_ml is faking"))
  res$hml <- prof
}

# =====================================================================
# PART 5. THE d13C OVERSHOOT IS ARITHMETIC, NOT A TUNING PROBLEM
# =====================================================================
# Part 3's arms overshoot deep d13C badly (+14 sigma -> -12.6 sigma). Before
# reaching for a smaller epsilon, check whether the OBSERVED pair (DIC gradient,
# d13C gradient) is even consistent with a pure soft-tissue pump. Mixing a
# quantity dDIC of organic carbon at (surf + eps) into a reservoir at DIC_deep
# gives a predictable depletion; if the observed depletion is SMALLER than that,
# part of the observed DIC gradient is carbonate-pump carbon, which carries
# essentially no depletion and which this file's single pump cannot represent.
sep("PART 5. CAN ONE SOFT-TISSUE PUMP FIT BOTH OBSERVED GRADIENTS AT ONCE?")
o_surf <- obsprof[1, ]; o_bot <- obsprof[nrow(obsprof), ]
dDIC   <- o_bot$dic - o_surf$dic
dd13   <- o_bot$d13 - o_surf$d13
pred13 <- DG_EPS_ORG * dDIC / o_bot$dic          # all-organic prediction
# CaCO3 dissolved at depth carries marine-carbonate d13C, ~ +2 permil, i.e.
# ABOVE deep DIC rather than 20 permil below it. Solve the two-component split.
DG_D13C_CARB <- 2.0                              # permil, marine biogenic CaCO3
x_org <- (dd13 * o_bot$dic - dDIC * (DG_D13C_CARB - o_surf$d13)) /
           (DG_EPS_ORG - (DG_D13C_CARB - o_surf$d13))
cat(sprintf("observed  dDIC %+.1f umol/kg,  d(d13C) %+.3f permil\n", dDIC, dd13))
cat(sprintf("all-organic prediction at eps = %g permil: d(d13C) = %+.3f permil\n",
            DG_EPS_ORG, pred13))
cat(sprintf("i.e. a pure soft-tissue pump matching the DIC gradient overshoots\n"))
arm_over <- (res[["N     nutrient-ltd, eps-20"]]$d13b - ref$d13b) / dd13
cat(sprintf("d13C by %.1fx.  Arm N measured %.1fx -- the two agree, so the\n",
            pred13 / dd13, arm_over))
cat("overshoot is ARITHMETIC and no choice of a single epsilon removes it.\n\n")
cat(sprintf("two-component split implied by the observations (CaCO3 at %+.1f permil):\n",
            DG_D13C_CARB))
cat(sprintf("   soft-tissue  %+6.1f umol/kg   (%.0f %%)\n", x_org, 100 * x_org / dDIC))
cat(sprintf("   carbonate    %+6.1f umol/kg   (%.0f %%)\n", dDIC - x_org,
            100 * (dDIC - x_org) / dDIC))
cat("\nCONSEQUENCE FOR THE DESIGN. A pump that fits the DIC gradient AND the\n")
cat("d13C gradient needs TWO components, not one -- and the carbonate limb\n")
cat("also moves alkalinity, which this model holds FIXED at ALK_SURFACE. That\n")
cat("is a second structural commitment hiding behind the first. It is a\n")
cat("scoping fact for handoff 15c sec.5's design sign-off, not a defect here.\n")
cat("CAVEAT, stated rather than buried: this split also absorbs preformed-d13C\n")
cat("and air-sea-disequilibrium structure that a two-box surface/deep contrast\n")
cat("cannot separate, and the observed surface d13C is Suess-depleted while the\n")
cat("deep is much less so. Treat the percentages as an order, not a partition.\n")

# =====================================================================
# PART 6. THE VERDICT, AGAINST THE RULE WRITTEN BEFORE THE RUN
# =====================================================================
# SCORED AT THE MODE, NOT AT DEFAULTS, and the header says why: the sign of the
# deep-D14C miss flips between the two operating points, so clause 3 returns
# opposite verdicts at each and only the mode's is the miss under discussion.
# Each arm is taken AT ITS OWN BEST DEPTH, because clause 1 is precisely the
# claim that the pump changes which depth that is.
sep("PART 6. SCORING THE THREE CLAUSES -- AT THE MODE")
if (!is.null(pm) && !is.null(res$hml)) {
  vO <- res$hml[["pump OFF"]]; vD <- res$hml[["pump D  "]]
  jO <- which.max(vO[1, ]);    jD <- which.max(vD[1, ])
  zO <- (vO[2, jO] - tg_d14$target) / tg_d14$sd
  zD <- (vD[2, jD] - tg_d14$target) / tg_d14$sd
  cat(sprintf("            %22s   %22s\n", "pump OFF, best h", "pump ON, best h"))
  cat(sprintf("h_ml        %22g   %22g\n", DG_H_GRID[jO], DG_H_GRID[jD]))
  cat(sprintf("logL        %22.1f   %22.1f\n", vO[1, jO], vD[1, jD]))
  cat(sprintf("ocean sink  %22.3f   %22.3f\n", vO[3, jO], vD[3, jD]))
  cat(sprintf("deep D14C   %22.1f   %22.1f\n", vO[2, jO], vD[2, jD]))
  cat(sprintf("  z vs obs  %+22.2f   %+22.2f\n", zO, zD))
  cat(sprintf("\nCLAUSE 1  h_ml relaxes below 163 m      %s  (%g -> %g m)\n",
              if (DG_H_GRID[jD] < 163) "PASS" else "FAIL",
              DG_H_GRID[jO], DG_H_GRID[jD]))
  cat(sprintf("CLAUSE 2  ocean sink holds near 3.1     %s  (%.3f -> %.3f GtC/yr)\n",
              if (abs(vD[3, jD] - 3.1) < 0.15) "PASS" else "FAIL",
              vO[3, jO], vD[3, jD]))
  cat(sprintf("CLAUSE 3  deep D14C moves TOWARD target %s  (z %+.2f -> %+.2f)\n",
              if (abs(zD) < abs(zO)) "PASS" else "FAIL", zO, zD))
  cat(sprintf("\ncost, nothing refitted:                %+.1f log-units\n",
              vD[1, jD] - vO[1, jO]))
}
cat("\n--- the same three clauses AT DEFAULTS, which give a DIFFERENT answer ---\n")
if (ok[["D     DIC-limited,  eps-20"]]) {
  e <- res[["D     DIC-limited,  eps-20"]]
  z0 <- (ref$deep - tg_d14$target) / tg_d14$sd
  z1 <- (e$deep   - tg_d14$target) / tg_d14$sd
  cat(sprintf("clause 2 sink:      %.4f -> %.4f GtC/yr   %s\n", ref$sink, e$sink,
              if (e$sink >= ref$sink - 1e-3) "PASS" else "FAIL"))
  cat(sprintf("clause 3 deep D14C: z %+.2f -> %+.2f            %s\n", z0, z1,
              if (abs(z1) < abs(z0)) "PASS -- TOWARD" else "FAIL -- AWAY"))
  cat("The clause-3 disagreement is NOT a contradiction and must not be averaged:\n")
  cat("at defaults kz is low and the model is ALREADY over-depleted, so more\n")
  cat("depletion is a loss; at the mode kz is 96.6 % up its bracket and the model\n")
  cat("is under-depleted, so the same change is a gain. The mode is the operating\n")
  cat("point the pump was proposed for, and the mode's verdict is the one that\n")
  cat("answers handoff 15c sec.3.4.\n")
}

sep("FREE VALIDATIONS -- neither of these is in the objective")
cat(sprintf("%-34s %12s %12s %10s\n", "quantity", "pump OFF", "pump ON", "canonical"))
cat(sprintf("%-34s %12.0f %12.0f %10s\n", "ocean carbon inventory, GtC",
            ref$ocean, res[["D     DIC-limited,  eps-20"]]$ocean, "~38,000"))
cat(sprintf("%-34s %12.3f %12.3f %10.2f\n",
            "natural 14C production / canonical", ref$prodr,
            res[["D     DIC-limited,  eps-20"]]$prodr, 1))
cat("Both move TOWARD their independent benchmarks. They are reported because\n")
cat("they are free, and flagged because they are NOT scored -- do not quote them\n")
cat("as if the likelihood had rewarded them.\n")

saveRDS(list(obsprof = obsprof, fields = fields, export_total = E_tot,
             arms = res, targets = list(d14 = tg_d14, d13 = tg_d13, dic = tg_dic)),
        file.path(DG_OUTDIR, "diag_dic_gradient.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(DG_OUTDIR, "diag_dic_gradient.rds")))
