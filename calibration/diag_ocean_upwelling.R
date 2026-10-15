# =====================================================================
# diag_ocean_upwelling.R -- can a NON-DIFFUSIVE ocean term close the d13C Suess
# overshoot at a physical parameter value, where k_w cannot?
#
# THE QUESTION. diag_d13c_levers.R found exactly one lever that closes the
# 0.55 permil d13C overshoot without breaking CO2 or Delta14C -- the gas transfer
# velocity k_w, at 4000 m/yr against a Wanninkhof global mean of ~1450 (+2.45
# sigma). Its reading was that k_w is standing in for a process the model does
# not have: the real ocean maintains its isotopic disequilibrium by CIRCULATION,
# continually presenting water that left the surface centuries ago, and a
# pure-diffusion column can only smear the surface signal downward. Handoff
# 2026-08-12d sec.2 reached the same place from the other isotope ("atmosphere
# short / ocean long => ventilation").
#
# So the test is: give the model the missing process, at a value a reader can be
# told, and see whether k_w's job disappears.
#
# THE MECHANISM (R/model.R, `w_up`). Classical upwelling-diffusion: water rises
# through every interface at w_up m/yr and returns from the mixed layer to the
# bottom box in one step. ONE parameter. w_up = 0 is the current model exactly.
#
# WHY kz MUST BE RE-TUNED ALONGSIDE. The sinking limb ventilates the bottom box
# directly, so deep-ocean Delta14C at fixed kz gets YOUNGER (-170 -> -100 permil
# at w_up = 4), straight out of the observed -150/-200 bracket. That is not a
# refutation: kz's job in the pure-diffusion column WAS the deep ventilation, and
# CCX_PARAM_TABLE's [3830, 6200] bracket was bisected on that column. With a
# second ventilation pathway present, kz must fall. Part 2 holds the deep age
# fixed by bisecting kz for every w_up, so the d13C comparison is like-for-like
# and no part of the answer is bought by re-aging the deep ocean.
#
# WHAT WOULD MAKE THIS WORTH ADOPTING: the d13C bias closing at w_up in the
# physical range with k_w AT ITS PRIOR CENTER, at no cost in CO2, Delta14C or the
# sink partition. Anything less and the mechanism is a second knob, not a fix.
#
# PHYSICAL RANGE, and it is a recollection needing a citation before it becomes
# a prior: the classical upwelling-diffusion models (Hoffert et al. 1980; Harvey
# & Schneider 1985; the UD-EBM ocean in MAGICC) use w ~ 4 m/yr. The arithmetic
# anchor is independent and exact: DU_SV_REF Sv spread over this model's ocean
# area is DU_W_FOR_SV_REF m/yr, printed below.
#
# TWO CONFIGURATIONS ARE TESTED, because which limb is non-local is the whole
# question (Marcus, 2026-08-13):
#   `w_up`                  distributed upwelling, non-local SINKING (ml -> bottom)
#   `w_out_NH`/`w_out_SH`   non-local UPWELLING (bottom -> ml, a Southern Ocean
#                           outcrop), distributed descent
# Parts 1-5 are the first, parts 6-9 the second. Part 9 proves they tie.
#
# ---------------------------------------------------------------------
# RESULT (2026-08-13): POSSIBLE, CHEAP, AND IT DOES NOT HELP -- in EITHER
# configuration, and the second one provably. The mechanism is NOT adopted:
# `w_up`, `w_out_NH` and `w_out_SH` all stay 0 in ccx_default_params() and out of
# CCX_PARAM_TABLE. Four measurements, in the order that settles it:
#
# 0. THE TWO CONFIGURATIONS ARE EXACTLY TIED AT THE ATMOSPHERE (part 9). Not
#    similar -- identical to ~1e-10 in CO2, d13C, D14C, ocean and land carbon, at
#    every kz from 10 to 5000. They are the same closed loop run in opposite
#    directions, so their transport operators satisfy A_out = D A_up^T D^-1 with
#    D = diag(dz) (verified to 1.7e-18), and diffusion is self-adjoint in the
#    same weighting (2.2e-16), so it does not break the relation. A transpose
#    preserves diagonal elements of the propagator, and the mixed layer is the
#    ONLY box through which the ocean touches the rest of the model -- air-sea
#    exchange acts at `iml` and nowhere else. So the atmosphere sees the column
#    exclusively through an ml-to-ml response that is invariant under reversing
#    the circulation: |ml->ml difference| = 4e-17 over 100 yr, against a largest
#    difference anywhere in the propagator of 0.27.
#    THE OFF-DIAGONALS ARE NOT TIED, which is why the deep-ocean age does differ
#    and why the outcrop version is the better-behaved one there (at 4 m/yr:
#    -108 permil both-hemispheres, -135 SH-only, against -100 for classic UD).
#    This is what makes the negative result GENERAL rather than one failed
#    parameterization: no reversal or rerouting of a closed vertical loop can
#    change what the atmosphere sees. Only something that changes the MIXED
#    LAYER'S OWN budget can -- a second surface box, or the air-sea flux itself.
#
# The remaining three are stated for `w_up`; by (0) they hold for the outcrop
# configuration too, and parts 6-8 confirm it directly:
#
# 1. IT IS A SECOND KNOB ON THE SAME TRADE, not a new axis (part 3). Both kz and
#    w_up buy d13C damping by making the deep ocean younger, and per permil of
#    deep-ocean D14C spent, upwelling is WORSE:
#       along kz   (w_up 0,  kz 3830 -> 6200) : -0.00220 permil / permil
#       along w_up (kz 5000, w_up 0 -> 2)     : -0.00107  (0.5x)
#       along w_up (kz 500,  w_up 0 -> 2)     : -0.00052  (0.2x)
#    Over the whole (w_up, kz) surface, the best d13C bias among cells whose deep
#    ocean is still in the observed -150/-200 bracket is +0.501 permil, at
#    w_up = 0. Every cell that improves on the current model's +0.548 by more
#    than kz alone can has a deep ocean 40-90 permil too young. Holding the deep
#    age fixed (part 2), adding upwelling makes d13C WORSE: +0.548 -> +0.628 at
#    w_up = 1, because the kz that compensates it (5000 -> 3062) stops burying
#    the depleted carbon faster than the upwelling limb removes it.
#
# 2. WHY, IN ONE NUMBER (part 5). For upwelling to hold the mixed layer out of
#    isotopic equilibrium it must flush the layer faster than the atmosphere
#    re-equilibrates it. Measured here: gross air-sea exchange 27.1 GtC/yr
#    against a 284 GtC NH mixed layer = 10.5 yr equilibration (the textbook ~10
#    yr). Flushing at 4 m/yr through 75 m takes 18.8 yr -- 1.8x too slow. The
#    crossover is w_up ~ 7 m/yr, i.e. ~80 Sv, about 4x the real overturning.
#    A global-mean overturning cannot outrun air-sea exchange. It is not close.
#    CAVEAT ON THIS ARGUMENT, since it was overstated once: the ratio bounds how
#    fast the ml is renewed, NOT how much good the renewal does, and those come
#    apart when the arriving water is very different from the ml. Renewing with
#    FULLY preindustrial water leaves the ml at tau_flush/(tau_flush + tau_eq) of
#    full equilibrium = 0.64 at 4 m/yr, a 36 % cut -- so this argument alone does
#    NOT rule out a non-local deep-to-surface path. Item 0 is what rules it out.
#
# 3. THE MECHANISM DOES WORK, AND STILL LOSES (part 4). At w_up 4 / kz 1000 the
#    upwelled water genuinely arrives old -- the ml-to-oc1 d13C gap widens 0.167
#    -> 0.584 permil -- and the mixed layer still ends up MORE depleted (-1.910
#    vs -1.619 permil) than with no upwelling at all, because the kz needed to
#    let the advective signal survive is the same kz that was burying the
#    depletion. This is the whole finding in one row: no purely VERTICAL
#    rearrangement can decouple "the surface stays undepleted" from "the deep
#    stays old" in a single column. They are the same transport.
#
# WHAT THIS POINTS AT INSTEAD -- untested, and the reason part 4 prints the
# oceanic Suess effect. The model's mixed layer declines 1.619 permil over
# 1750-2024, against an atmospheric 2.834, a ratio of 0.57. My RECOLLECTION of
# the observed oceanic Suess effect is a surface-DIC decline of ~0.6-0.9 permil
# against the atmosphere's ~1.9, a ratio near 0.35-0.45 -- i.e. the model's
# surface ocean tracks the atmosphere roughly twice as closely as the real one
# does. THAT NUMBER IS UNVERIFIED (no source in DATA.md, none in the local
# Papers folder; Quay et al. and Eide et al. 2017 are where I would look). If it
# holds, the gap is not a missing transport term at all: it is the single
# well-mixed surface box. The real ocean keeps its disequilibrium with
# HORIZONTAL structure -- high-latitude water that touches the atmosphere
# briefly and subducts, next to low-latitude water that sits at the surface --
# and a global mean of a product is not the product of the global means. That is
# a second surface box (the outcrop/HILDA structure DESIGN.md section 2
# rejected), not a one-parameter advection term, and it is a bigger decision
# than this diagnostic can take.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
DU_YEARS      <- c(1750, 2024)
DU_BOMB_REF   <- 102
DU_BIAS_WIN   <- c(2015, 2024)   # d13C / CO2 / sink-share window
DU_D14C_WIN   <- c(2000, 2019)   # Delta14C window (Hua ends 2019)
DU_W_GRID     <- c(0, 0.5, 1, 2, 4, 6, 8)      # m/yr
DU_KZ_SEARCH  <- c(50, 8000)     # bisection bracket for the compensated kz
DU_DEEP_OBS   <- c(-150, -200)   # observed deep-ocean D14C bracket (CCX_PARAM_TABLE$kz)
DU_D13_BOTH_WIN <- c(1993, 2014) # window where BOTH MLO and SPO d13C obs exist
DU_SV_REF     <- 20              # Sv, for the overturning arithmetic anchor
DU_SEC_PER_YR <- 365.25 * 86400

A_OCEAN <- ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")
DU_W_FOR_SV_REF <- DU_SV_REF * 1e6 * DU_SEC_PER_YR / A_OCEAN

obs <- ccx_prepare_obs()
gcb <- as.data.frame(obs$gcb)
base_forcing <- ccx_build_forcing("historical", DU_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = DU_BOMB_REF)

# ---- metrics: the same set diag_d13c_levers.R reports, plus the ocean
# structure diagnostics this mechanism is expected to move -----------------
du_metrics <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  out <- ccx_run_fast(s, F)$out
  if (anyNA(out$co2_NH)) return(NULL)
  ms <- ccx_model_stats(out, obs)
  lev <- function(o, m, col) {
    k <- match(o$year, m$year)
    g <- !is.na(k) & o$year >= DU_BIAS_WIN[1] & o$year <= DU_BIAS_WIN[2]
    mean(o[[col]][g] - m$level[k[g]])
  }
  o14 <- obs$d14_nh_ann; k14 <- match(o14$year, ms$d14$NH$year)
  g14 <- !is.na(k14) & o14$year >= DU_D14C_WIN[1] & o14$year <= DU_D14C_WIN[2]
  yr  <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  kk  <- ann$yr[-1] >= DU_BIAS_WIN[1]
  ld  <- mean(diff(ann$land_C)[kk]); oc <- mean(diff(ann$ocean_C)[kk])
  c(d13c = lev(obs$d13_ann$MLO, ms$d13$MLO, "level"),
    co2  = lev(obs$co2_ann$MLO, ms$co2$MLO, "level"),
    d14c = mean(o14$value[g14] - ms$d14$NH$mean[k14[g14]]),
    land = ld, ocean = oc, land_share = 100 * ld / (ld + oc),
    deep_d14c = s$diagnostics$d14c_deep_ocean,
    prod_ratio = s$diagnostics$prod_ratio,
    ocean_C = s$diagnostics$ocean_C_GtC)
}

# deep-ocean Delta14C is a SPINUP diagnostic, so the kz bisection needs no
# transient run -- ~1 s per evaluation instead of ~4
du_deep <- function(p) ccx_spinup(p)$diagnostics$d14c_deep_ocean

du_kz_for_deep <- function(p, target) {
  f <- function(kz) { q <- p; q$kz <- kz; du_deep(q) - target }
  lo <- f(DU_KZ_SEARCH[1]); hi <- f(DU_KZ_SEARCH[2])
  if (lo * hi > 0) return(NA_real_)        # target unreachable at this w_up
  uniroot(f, interval = DU_KZ_SEARCH, tol = 1)$root
}

hdr <- function() cat(sprintf(
  "%-6s %7s | %8s %9s %10s | %6s%% | %8s %6s\n",
  "w_up", "kz", "d13C", "CO2 ppm", "D14C pm", "land", "deep D14C", "prod"))
row <- function(w, kz, m, tag = "") cat(sprintf(
  "%-6g %7.0f | %+8.3f %+9.2f %+10.2f | %5.0f%% | %+8.1f %6.2f%s\n",
  w, kz, m[["d13c"]], m[["co2"]], m[["d14c"]], m[["land_share"]],
  m[["deep_d14c"]], m[["prod_ratio"]], tag))

p0 <- ccx_default_params()
g <- gcb$year >= DU_BIAS_WIN[1] & gcb$year <= DU_BIAS_WIN[2]
GCB_SHARE <- 100 * mean(gcb$land_sink[g]) /
  (mean(gcb$land_sink[g]) + mean(gcb$ocean_sink[g]))

cat(sprintf("biases are obs - model, %d-%d (D14C %d-%d); target 0\n",
            DU_BIAS_WIN[1], DU_BIAS_WIN[2], DU_D14C_WIN[1], DU_D14C_WIN[2]))
cat(sprintf("GCB %d-%d land share %.0f %%\n", DU_BIAS_WIN[1], DU_BIAS_WIN[2],
            GCB_SHARE))
cat(sprintf("overturning anchor: %g Sv over %.2e m2 of ocean = %.2f m/yr\n",
            DU_SV_REF, A_OCEAN, DU_W_FOR_SV_REF))
cat(sprintf("k_w held at its PRIOR CENTRE %g m/yr throughout\n\n", p0$k_w))

# ---- PART 1: w_up alone, kz at its default --------------------------
cat(sprintf("== PART 1: overturning added, kz left at %g ==\n", p0$kz))
cat("   the deep-age cost is the point of part 2, not a refutation\n")
hdr()
for (w in DU_W_GRID) {
  p <- p0; p$w_up <- w
  m <- du_metrics(p)
  if (is.null(m)) { cat(sprintf("%-6g   run failed (NA)\n", w)); next }
  row(w, p$kz, m, if (w == 0) "   <- current model" else "")
}

# ---- PART 2: kz compensated to hold the deep-ocean age --------------
DEEP_TARGET <- du_deep(p0)
cat(sprintf("\n== PART 2: kz bisected to hold deep-ocean D14C at %+.1f permil ==\n",
            DEEP_TARGET))
cat(sprintf("   (the current model's value; CCX_PARAM_TABLE brackets kz on %s)\n",
            "-150/-200, which was bisected on the pure-diffusion column"))
hdr()
for (w in DU_W_GRID) {
  p <- p0; p$w_up <- w
  kz <- if (w == 0) p0$kz else du_kz_for_deep(p, DEEP_TARGET)
  if (is.na(kz)) {
    cat(sprintf("%-6g       - | deep age unreachable within kz [%g, %g]\n",
                w, DU_KZ_SEARCH[1], DU_KZ_SEARCH[2]))
    next
  }
  p$kz <- kz
  m <- du_metrics(p)
  if (is.null(m)) { cat(sprintf("%-6g %7.0f | run failed (NA)\n", w, kz)); next }
  row(w, kz, m, if (w == 0) "   <- current model" else "")
}

# ---- PART 3: the whole (w_up, kz) surface ---------------------------
# Part 2 walks ONE contour of a two-dimensional surface. If the mechanism has a
# working corner at all it is at LOW kz -- upwelling can only deliver old water
# if the top interior layer is not diffusively slaved to the mixed layer -- and
# that corner is off the contour. This prints the surface so the answer is not
# an artifact of which slice was taken. Cells are d13C bias / deep D14C.
cat("\n== PART 3: d13C bias (permil) and deep-ocean D14C (permil) over the surface ==\n")
cat("   the current model is the w_up = 0, kz = 5000 cell\n")
cat(sprintf("   deep D14C inside the observed %g/%g bracket is marked *\n",
            DU_DEEP_OBS[1], DU_DEEP_OBS[2]))
DU_KZ_GRID <- c(500, 1000, 2000, 3830, 5000, 6200)
S_D13 <- S_DEEP <- matrix(NA_real_, length(DU_W_GRID), length(DU_KZ_GRID),
                          dimnames = list(DU_W_GRID, DU_KZ_GRID))
cat(sprintf("%-6s", "w_up\\kz"))
for (kz in DU_KZ_GRID) cat(sprintf(" %14g", kz)); cat("\n")
for (iw in seq_along(DU_W_GRID)) {
  cat(sprintf("%-6g", DU_W_GRID[iw]))
  for (ik in seq_along(DU_KZ_GRID)) {
    p <- p0; p$w_up <- DU_W_GRID[iw]; p$kz <- DU_KZ_GRID[ik]
    m <- du_metrics(p)
    if (is.null(m)) { cat(sprintf(" %14s", "NA")); next }
    S_D13[iw, ik] <- m[["d13c"]]; S_DEEP[iw, ik] <- m[["deep_d14c"]]
    ok <- m[["deep_d14c"]] <= DU_DEEP_OBS[1] && m[["deep_d14c"]] >= DU_DEEP_OBS[2]
    cat(sprintf(" %+6.3f/%+5.0f%s", m[["d13c"]], m[["deep_d14c"]],
                if (ok) "*" else " "))
  }
  cat("\n")
}

# ---- the verdict, computed from the grid rather than asserted -------
# Both knobs buy d13C damping by making the deep ocean younger. The only
# question that matters is the EXCHANGE RATE: permil of d13C bias removed per
# permil of deep-ocean D14C spent. If upwelling's rate is no better than kz's,
# it is a second knob on the same trade, not the missing mechanism.
rate <- function(d13, deep) (d13[2] - d13[1]) / (deep[2] - deep[1])
iw0 <- match(0, DU_W_GRID)
r_kz <- rate(S_D13[iw0, c("3830", "6200")], S_DEEP[iw0, c("3830", "6200")])
r_w  <- rate(S_D13[c(iw0, match(2, DU_W_GRID)), "5000"],
             S_DEEP[c(iw0, match(2, DU_W_GRID)), "5000"])
r_wlo <- rate(S_D13[c(iw0, match(2, DU_W_GRID)), "500"],
              S_DEEP[c(iw0, match(2, DU_W_GRID)), "500"])
cat(sprintf(
  "\nexchange rate, permil of d13C bias per permil of deep-ocean D14C spent:\n"))
cat(sprintf("  along kz   (w_up 0,   kz 3830 -> 6200) : %.5f\n", r_kz))
cat(sprintf("  along w_up (kz 5000,  w_up 0 -> 2)     : %.5f  (%.1fx kz's)\n",
            r_w, r_w / r_kz))
cat(sprintf("  along w_up (kz 500,   w_up 0 -> 2)     : %.5f  (%.1fx kz's)\n",
            r_wlo, r_wlo / r_kz))
feas <- S_DEEP <= DU_DEEP_OBS[1] & S_DEEP >= DU_DEEP_OBS[2] & !is.na(S_DEEP)
cat(sprintf("best d13C bias among cells with a defensible deep age: %+.3f at %s\n",
            min(S_D13[feas]),
            paste0("w_up ", rownames(S_D13)[which(feas, TRUE)[which.min(S_D13[feas]), 1]],
                   ", kz ", colnames(S_D13)[which(feas, TRUE)[which.min(S_D13[feas]), 2]])))

# ---- PART 4: does the upwelled water actually ARRIVE old? -----------
# The mechanism claim is that the upwelling limb presents water last in contact
# with a preindustrial atmosphere. That claim is testable directly: print the
# 2024 d13C of the mixed layer and of the layer that feeds it. If the top
# interior layer has followed the mixed layer down, the advective renewal is
# delivering water that is already loaded and the mechanism cannot work no
# matter what w_up is -- which is a statement about kz, not about w_up.
cat("\n== PART 4: is the water the upwelling limb delivers actually old? ==\n")
cat("   NH column d13C, permil. `ml drop` is the modelled OCEANIC SUESS EFFECT,\n")
cat("   1750 -> 2024, alongside the atmosphere's own drop over the same span.\n")
cat("   The oceanic Suess effect is OBSERVED, so this column is an independent\n")
cat("   check the model is not currently scored on -- see the note at the top.\n")
cat(sprintf("%-6s %7s | %9s %9s %9s | %8s %8s\n",
            "w_up", "kz", "ml 2024", "oc1 2024", "ml-oc1", "ml drop", "atm drop"))
du_profile <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  r <- ccx_run_fast(s, F)
  d13 <- function(y, i) 1000 * (y[i, "C13"] / (y[i, "C"] * ccx_const("R13_VPDB")) - 1)
  i <- s$aux$idx$NH
  c(ml0 = d13(s$y, i$ml), ml = d13(r$state, i$ml), oc1 = d13(r$state, i$oc[1]),
    atm0 = d13(s$y, i$atm), atm = d13(r$state, i$atm))
}
for (cfg in list(c(0, 5000), c(1, 3830), c(4, 5000), c(4, 1000), c(8, 500))) {
  p <- p0; p$w_up <- cfg[1]; p$kz <- cfg[2]
  v <- du_profile(p)
  cat(sprintf("%-6g %7g | %+9.3f %+9.3f %+9.3f | %8.3f %8.3f\n",
              cfg[1], cfg[2], v[["ml"]], v[["oc1"]], v[["ml"]] - v[["oc1"]],
              v[["ml"]] - v[["ml0"]], v[["atm"]] - v[["atm0"]]))
}

# ---- PART 5: the two timescales, which is why the answer is what it is
# For the upwelling limb to hold the mixed layer OUT of isotopic equilibrium
# with the atmosphere, it has to flush the mixed layer FASTER than the
# atmosphere can re-equilibrate it. Both timescales are computable from the
# spinup, so this is measured, not argued:
#   flush  = h_ml / w_up                     (how fast overturning renews the ml)
#   equil  = C_ml / F_gross                  (isotopic exchange time with the atm;
#                                             the ~10 yr textbook number)
cat("\n== PART 5: can overturning outrun air-sea equilibration? ==\n")
s <- ccx_spinup(p0)
i <- s$aux$idx$NH
k <- carb_constants(s$aux$sst$NH)
F_gross <- s$aux$asx$NH * p0$k_w * k$K0 * ccx_const("CO2_PI_PPM")   # GtC/yr
C_ml    <- s$y[i$ml, "C"]
tau_eq  <- C_ml / F_gross
cat(sprintf("NH mixed layer %.0f GtC, gross air-sea exchange %.1f GtC/yr\n",
            C_ml, F_gross))
cat(sprintf("isotopic equilibration time C_ml / F_gross = %.1f yr\n", tau_eq))
cat(sprintf("%-8s %10s %10s\n", "w_up", "flush yr", "flush/equil"))
for (w in DU_W_GRID[DU_W_GRID > 0]) {
  cat(sprintf("%-8g %10.1f %10.1f\n", w, p0$h_ml / w, (p0$h_ml / w) / tau_eq))
}
cat(sprintf("a flush/equil ratio above 1 means the atmosphere wins: the ml\n"))
cat(sprintf("re-equilibrates faster than overturning can renew it.\n"))
cat("BUT this ratio is only half the story -- it says how FAST the ml is renewed,\n")
cat("not how DIFFERENT the arriving water is. Under w_up the arriving water is\n")
cat("oc1, only 0.167 permil from the ml, so a slow flush of nearly-identical\n")
cat("water does nothing. Parts 6-8 renew the ml from the BOTTOM box instead.\n")

# =====================================================================
# PARTS 6-8: THE OTHER CONFIGURATION (Marcus 2026-08-13)
#
# `w_out_NH` / `w_out_SH`: deep box -> mixed layer in ONE step, with the return
# flow distributed down through every interface. The mirror image of w_up, and
# the two differ in both directions:
#   * what arrives at the surface is bottom water carrying the FULL
#     preindustrial contrast, not oc1 water that is diffusively slaved to the ml;
#   * the descending limb has to traverse the whole column (~depth/w years), so
#     the anthropogenic signal never reaches the bottom box over the industrial
#     period -- where w_up injected it there directly.
# Per hemisphere, because the real outcrop is a Southern Ocean feature.
#
# The steady-state prediction, for reference: renewing the ml with FULLY
# preindustrial water at 1/tau_flush against air-sea relaxation at 1/tau_eq
# leaves the ml at tau_flush / (tau_flush + tau_eq) of full equilibrium. At
# 4 m/yr that is 18.8 / 29.3 = 0.64, i.e. a 36 % cut in ml depletion -- so the
# part-5 timescale argument does NOT rule this configuration out.
# =====================================================================
cat("\n== PART 6: outcropping -- deep water reaching the surface in one step ==\n")
DU_OUT_GRID <- c(0, 0.5, 1, 2, 4, 8)
hdr()
for (w in DU_OUT_GRID) {
  p <- p0; p$w_out_SH <- w
  m <- du_metrics(p)
  if (is.null(m)) { cat(sprintf("%-6g   run failed (NA)\n", w)); next }
  row(w, p$kz, m, if (w == 0) "   <- current model" else "   SH only")
}
for (w in DU_OUT_GRID[DU_OUT_GRID > 0]) {
  p <- p0; p$w_out_SH <- w; p$w_out_NH <- w
  m <- du_metrics(p)
  if (is.null(m)) next
  row(w, p$kz, m, "   both hemispheres")
}

cat(sprintf("\n== PART 7: outcropping with kz bisected to hold deep D14C at %+.1f ==\n",
            DEEP_TARGET))
hdr()
for (w in DU_OUT_GRID) {
  p <- p0; p$w_out_SH <- w
  kz <- if (w == 0) p0$kz else du_kz_for_deep(p, DEEP_TARGET)
  if (is.na(kz)) {
    cat(sprintf("%-6g       - | deep age unreachable within kz [%g, %g]\n",
                w, DU_KZ_SEARCH[1], DU_KZ_SEARCH[2]))
    next
  }
  p$kz <- kz
  m <- du_metrics(p)
  if (is.null(m)) { cat(sprintf("%-6g %7.0f | run failed (NA)\n", w, kz)); next }
  row(w, kz, m, if (w == 0) "   <- current model" else "   SH only")
}

# ---- PART 8: an SH-only mechanism is a claim about the GRADIENT -----
# The model is scored at MLO and SPO separately. A southern-hemisphere outcrop
# that fixes the global level by breaking the north-south difference has not
# fixed anything, so the two stations are reported separately, over the window
# where SPO d13C observations actually exist (they end in 2014).
cat("\n== PART 8: does an SH-only outcrop break the MLO-SPO gradient? ==\n")
cat(sprintf("   d13C biases over %d-%d, where SPO observations exist\n",
            DU_D13_BOTH_WIN[1], DU_D13_BOTH_WIN[2]))
cat(sprintf("%-6s %-8s %7s | %8s %8s %10s | %9s\n",
            "w_out", "hemis", "kz", "MLO", "SPO", "MLO-SPO", "obs MLO-SPO"))
du_stations <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  out <- ccx_run_fast(s, F)$out
  if (anyNA(out$co2_NH)) return(NULL)
  ms <- ccx_model_stats(out, obs)
  st <- function(stn) {
    o <- obs$d13_ann[[stn]]; m <- ms$d13[[stn]]
    k <- match(o$year, m$year)
    g <- !is.na(k) & o$year >= DU_D13_BOTH_WIN[1] & o$year <= DU_D13_BOTH_WIN[2]
    c(bias = mean(o$level[g] - m$level[k[g]]),
      obs = mean(o$level[g]), mod = mean(m$level[k[g]]))
  }
  list(MLO = st("MLO"), SPO = st("SPO"))
}
for (cfg in list(list(0, "-", 0, 0), list(4, "SH only", 0, 4),
                 list(4, "both", 4, 4), list(8, "SH only", 0, 8))) {
  p <- p0; p$w_out_NH <- cfg[[3]]; p$w_out_SH <- cfg[[4]]
  v <- du_stations(p)
  if (is.null(v)) next
  cat(sprintf("%-6g %-8s %7g | %+8.3f %+8.3f %+10.3f | %+9.3f\n",
              cfg[[1]], cfg[[2]], p$kz, v$MLO[["bias"]], v$SPO[["bias"]],
              v$MLO[["mod"]] - v$SPO[["mod"]], v$MLO[["obs"]] - v$SPO[["obs"]]))
}

# ---- PART 9: WHY the two configurations tie, exactly ----------------
# Parts 6-7 do not merely come out similar to parts 1-2 -- at equal w the
# atmosphere is identical to ~1e-10, at every kz from 10 to 5000. That is a
# symmetry, not a coincidence, and it is worth stating exactly because it closes
# off a whole family of alternatives rather than one of them:
#
#   The two circulations are the SAME closed loop traversed in opposite
#   directions, so their transport operators are related by
#       A_out = D A_up^T D^-1,    D = diag(dz)
#   a similarity transform of the TRANSPOSE. Interior diffusion satisfies
#   K = D K^T D^-1 in the same weighting, so it does not break the relation.
#   A transpose preserves DIAGONAL elements of every matrix power, hence of the
#   propagator: (exp A_out t)[ml,ml] = (exp A_up t)[ml,ml] exactly.
#
#   And the mixed layer is the ONLY box through which the ocean touches the rest
#   of the model -- air-sea exchange acts at `iml` and nowhere else. So the
#   atmosphere, the land and the sink partition see the column exclusively
#   through its ml-to-ml response, which is invariant. The OFF-diagonal
#   elements are not invariant, which is why the interior profile and the
#   deep-ocean age do differ.
#
# CONSEQUENCE, and it is the answer to "would a more direct deep-to-surface
# path help?": no reversal or rerouting of a closed vertical loop can change
# what the atmosphere sees. Only something that changes the MIXED LAYER's own
# budget can -- a second surface box, or the air-sea flux itself.
cat("\n== PART 9: the two configurations are exactly tied, and here is why ==\n")
gg <- ccx_ocean_grid(p0$h_ml); nn <- gg$nl + 1; dzv <- gg$dz; WW <- 4
A_up <- A_out <- KK <- matrix(0, nn, nn)
for (k in seq_len(gg$nl)) {
  A_up[k, k + 1] <- A_up[k, k + 1] + WW / dzv[k + 1]
  A_up[k + 1, k + 1] <- A_up[k + 1, k + 1] - WW / dzv[k + 1]
  A_out[k + 1, k] <- A_out[k + 1, k] + WW / dzv[k]
  A_out[k, k] <- A_out[k, k] - WW / dzv[k]
}
A_up[nn, 1] <- A_up[nn, 1] + WW / dzv[1]; A_up[1, 1] <- A_up[1, 1] - WW / dzv[1]
A_out[1, nn] <- A_out[1, nn] + WW / dzv[nn]
A_out[nn, nn] <- A_out[nn, nn] - WW / dzv[nn]
dzm <- (dzv[-nn] + dzv[-1]) / 2
for (k in seq_len(nn - 1)) {
  a <- p0$kz / (dzv[k] * dzm[k]); b <- p0$kz / (dzv[k + 1] * dzm[k])
  KK[k, k] <- KK[k, k] - a; KK[k, k + 1] <- KK[k, k + 1] + b
  KK[k + 1, k] <- KK[k + 1, k] + a; KK[k + 1, k + 1] <- KK[k + 1, k + 1] - b
}
D <- diag(dzv); Di <- solve(D)
cat(sprintf("max |A_out - D A_up^T D^-1| = %.2e  (operator scale %.2e)\n",
            max(abs(A_out - D %*% t(A_up) %*% Di)), max(abs(A_up))))
cat(sprintf("max |K     - D K^T     D^-1| = %.2e  (diffusion does not break it)\n",
            max(abs(KK - D %*% t(KK) %*% Di))))
if (requireNamespace("Matrix", quietly = TRUE)) {
  E1 <- as.matrix(Matrix::expm((A_up + KK) * 100))
  E2 <- as.matrix(Matrix::expm((A_out + KK) * 100))
  cat(sprintf("100-yr propagator: |ml->ml difference| %.2e ; largest difference anywhere %.2e\n",
              abs(E1[1, 1] - E2[1, 1]), max(abs(E1 - E2))))
  cat(sprintf("                   |deep->ml difference| %.2e  <- the interior is NOT tied\n",
              abs(E1[nn, 1] - E2[nn, 1])))
}
