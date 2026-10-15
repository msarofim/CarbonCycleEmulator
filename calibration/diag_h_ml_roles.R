# =====================================================================
# diag_h_ml_roles.R -- ITEM 9's PREREQUISITE. Is h_ml doing CAPACITY work or
# EXPORT work?  (handoff 2026-08-15 sec.4.2, Marcus 2026-08-15)
#
# THE QUESTION, AND WHY IT COMES BEFORE THE PUMP. At the MAP mode h_ml = 184.0 m
# against an observed global-mean mixed layer of ~50-75 m, and kz sits 96.6 % of
# the way up its bracket. The bound-artifact hypothesis was already tested and
# REFUTED -- profiling gives an interior optimum at ~184 m. So the data genuinely
# want a deep mixed layer, and the standing story is that k_w is pinned to +/-2 %
# by bomb-14C, so the model cannot get carbon IN faster and must get it DOWN
# faster, for which a biological pump is the missing export.
#
# Two readings survive and ONLY ONE OF THEM A PUMP FIXES (handoff sec.4.2):
#   1. CAPACITY -- h_ml buys a BIGGER SURFACE RESERVOIR. A deeper mixed layer
#      holds more water, so a given GtC raises its DIC and its pCO2 less, and
#      the ocean absorbs more before it saturates. A pump does NOT do this: it
#      moves carbon down, it does not make the surface box larger.
#   2. EXPORT -- h_ml buys a faster route into the interior. A pump adds exactly
#      that and is the right thing to build.
# Building the pump without separating these risks a 5-6 h refit against the
# wrong mechanism.
#
# ---------------------------------------------------------------------
# THE FIRST DESIGN WAS INVALID AND IS RECORDED HERE RATHER THAN DELETED.
#
# handoff sec.4.2 proposed "hold the mixed-layer carbon inventory fixed while
# varying its depth", which this file first implemented as three arms driving
# aux$ml_mass_kg (capacity) and grid$dz[0] (geometry) at DIFFERENT depths.
# That is not a decomposition. `ml_mass_kg` and `dz[0]` are two encodings of ONE
# quantity -- the mixed layer's carbon per unit depth -- because the core reads
# the chemistry's concentration as y_ml/ml_mass_kg and the diffusion's as
# y_ml/dz[0]. Making them disagree makes "mixed-layer concentration" mean two
# different things inside one timestep.
#
# It announced itself: at h = 184 the arms gave BOTH +425.9, CAPACITY -26,203.8,
# EXPORT -29,035.3, i.e. an INTERACTION OF +55,665 against an effect of +426.
# Full post-mortem and the confirming sign pattern in
# calibration/output/quarantine/20260815_h_ml_inconsistent_grid_arms/README.md.
#
# WHAT REPLACED IT, and why it is sound: every configuration below is a
# CONSISTENT model. Nothing is decomposed by breaking an identity. Instead the
# two channels are separated by their SIGNS, which the grid gives for free, and
# the mechanism is then confirmed POSITIVELY by asking where the extra carbon
# physically ends up.
# ---------------------------------------------------------------------
#
# THE ARGUMENT THIS FILE MAKES, in four steps:
#
#  1. THE SIGNS, off the grid alone. Deepening the mixed layer RAISES capacity
#     and LOWERS the mixed-layer-to-interior diffusive conductance, because
#     dz_mid[0] = (h_ml + dz_int1)/2 grows with h_ml. The two channels have
#     OPPOSITE signs, which is what makes them separable without surgery.
#  2. THE PREFERENCE, on consistent grids only (the old BOTH arm, which was
#     always valid). If the fit improves with depth while the export channel is
#     moving the wrong way, export cannot be what is being bought.
#  3. THE POSITIVE CONFIRMATION. Capacity and export make OPPOSITE predictions
#     about WHERE the extra absorbed carbon sits: capacity puts it in the mixed
#     layer, export puts it in the interior. Read off the final state. This is
#     the step that distinguishes "not export" from "capacity".
#  4. kz AS THE CONTROL. kz is the model's genuine pure-export knob -- it
#     multiplies every interior diffusive flux and touches neither ml_mass_kg
#     nor the chemistry. If the deep-h_ml preference survives re-optimizing kz
#     at every depth, h_ml is supplying something no amount of export can.
#
# PRE-REGISTERED DECISION RULE, written before step 3 and 4 were run:
#   * capacity signature (extra carbon in the ML; preference survives kz)
#       -> a pump does NOT address what h_ml is buying. It would substitute for
#          kz, not for h_ml. Item 9's own pre-registered test needs amending.
#   * export signature (extra carbon in the interior; preference collapses when
#     kz is free)  -> the pump is the right missing mechanism, build it.
#   * mixed or contradictory -> REPORT AS SUCH. Do not force it.
#
# ---------------------------------------------------------------------
# WHAT IT FOUND: THE THIRD BRANCH. The two pre-registered signatures came out
# OPPOSITE, and the resolution is more useful than either would have been.
#
#   * step 3 says CAPACITY. Deepening 75 -> 184 m puts +32 GtC of extra
#     anthropogenic carbon in the MIXED LAYER while the interior LOSES 19 GtC.
#   * step 4 says EXPORT. Hand the model 1.4x the pure export knob and its
#     preferred depth collapses from 184 m to 50 m.
#
# Both hold, at different levels, and the sentence that reconciles them is:
# WHAT THE OBJECTIVE IS SHORT OF IS OCEAN UPTAKE; h_ml = 184 m IS A CAPACITY-
# SIDE WORKAROUND FOR AN EXPORT DEFICIT, REACHED FOR BECAUSE kz IS BRACKET-
# LIMITED. So h_ml is not evidence against the pump -- it is a symptom of the
# same shortage.
#
# AND STEP 5 SAYS WHY kz CANNOT SIMPLY BE FREED, which is the part that matters
# for item 9. Diffusion ventilates 14C in proportion to the carbon it moves, so
# buying uptake with kz drives the deep-D14C term from z +1.70 to z +4.47 --
# away from a target the model already misses on the under-depleted side. A
# biological pump exports carbon as sinking particles and remineralizes it at
# depth, adding uptake WITHOUT mixing surface water down. That is a thing no
# knob currently in the model can do, and it is why the pump case comes out of
# this stronger than handoff sec.4.2 had it, not weaker.
#
# ITEM 9'S PRE-REGISTERED TEST IS AMENDED HERE (see part 5's output): its h_ml
# and kz clauses are now measured-plausible rather than speculative, but they
# are NOT sufficient, and a third clause is added -- does deep D14C move TOWARD
# the target rather than away? That is the clause the kz route fails and the one
# the pump has to beat to be an improvement rather than a re-arrangement.
# ---------------------------------------------------------------------
#
# RUNTIME ~3 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and window below derives from these ----
HR_YEARS    <- c(1750, 2024)
HR_BOMB_REF <- 102
HR_H_REF    <- 75            # m, the model default and the profiles' reference
HR_H_GRID   <- c(50, 75, 100, 140, 184, 220)   # m; 184 = the MAP mode's value
HR_H_MODE   <- 184
HR_MODE_PATH <- ccx_path("calibration", "output", "quarantine",
                         "20260815_pre_gradient_terms", "mode_fit.rds")
# Gradient offsets: their absence SKIPS both gradient streams, so they are
# supplied at the values diag_gradient_terms.R part 3 measured. `sigma_co2` is
# RETIRED (item 6b) and is deliberately absent -- the CO2 level sd is
# LIK_CO2_REP_ERR alone.
HR_ERR_DEFAULT <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                       grad_off_co2 = -0.386, grad_off_d13c = +0.099)
HR_ERR_MODE    <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                       grad_off_co2 = -0.549, grad_off_d13c = +0.107)
HR_DEEP_STREAM <- "d14c_deep_ocean"   # the ACTUAL name; the first version of
                                      # this file filtered on "d14c_deep" and
                                      # the confound control silently did nothing
HR_SINK_WIN <- c(2010, 2019)    # decade for the reported ocean sink, GtC/yr
HR_KZ_FAC   <- c(0.5, 0.7, 1.0, 1.4, 2.0, 3.0)  # kz multipliers for step 4
HR_OUTDIR   <- ccx_path("calibration", "output", "h_ml_roles")

dir.create(HR_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", HR_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = HR_BOMB_REF)

#' One CONSISTENT model configuration. h_ml goes through p, so grid, ml_mass_kg
#' and dz all follow it together -- there is no injected grid anywhere in this
#' file, which is the whole difference from the quarantined version.
hr_eval <- function(p, bomb_total, luc_scale, err) {
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp)) return(NULL)
  F  <- base_forcing
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forcing$c14_bomb * (bomb_total / HR_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forcing[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forcing); eluc$eluc <- eluc$eluc * luc_scale
  r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  ps <- ccx_loglik(r$out, obs, err, luc = eluc,
                   deep = sp$diagnostics$d14c_bottom_box, by_stream = TRUE)

  # WHERE THE CARBON WENT. Anthropogenic anomaly = final state minus the
  # preindustrial spinup state, in the SAME boxes, so the split is exact and
  # needs no assumption about what "anthropogenic" means.
  bn  <- ccx_box_names(sp$grid$nl)
  d   <- r$state[, "C"] - sp$y[, "C"]
  iml <- grep("_ml$",  bn); ioc <- grep("_oc[0-9]+$", bn)
  yr  <- floor(r$out$t + 1e-9); ann <- tapply(r$out$ocean_C, yr, mean)
  yy  <- as.integer(names(ann))
  k   <- which(yy >= HR_SINK_WIN[1] & yy <= HR_SINK_WIN[2])

  list(parts = ps, total = sum(ps),
       total_no_deep = sum(ps[names(ps) != HR_DEEP_STREAM]),
       sink = if (length(k) > 1) mean(diff(ann[k])) else NA_real_,
       deep = sp$diagnostics$d14c_bottom_box,
       dC_ml = sum(d[iml]), dC_int = sum(d[ioc]),
       dz_mid0 = (sp$grid$dz[1] + sp$grid$dz[2]) / 2)
}

hr_profile <- function(p0, bomb_total, luc_scale, err, label) {
  cat(sprintf("\n\n##################  %s  ##################\n", label))
  rows <- lapply(HR_H_GRID, function(h) {
    p <- p0; p$h_ml <- h
    e <- hr_eval(p, bomb_total, luc_scale, err)
    if (is.null(e)) return(NULL)
    data.frame(h = h, total = e$total, total_nd = e$total_no_deep,
               sink = e$sink, deep = e$deep, dz_mid0 = e$dz_mid0,
               dC_ml = e$dC_ml, dC_int = e$dC_int)
  })
  tab <- do.call(rbind, rows)
  ref <- tab$total[tab$h == HR_H_REF]
  refnd <- tab$total_nd[tab$h == HR_H_REF]
  tab$d_total <- tab$total - ref
  tab$d_total_nd <- tab$total_nd - refnd
  tab$ml_share <- 100 * tab$dC_ml / (tab$dC_ml + tab$dC_int)

  cat(sprintf("\nCONSISTENT grids only. log-likelihood relative to h = %g m.\n", HR_H_REF))
  cat(sprintf("dC_ml / dC_int = anthropogenic carbon anomaly, GtC, 1750 -> 2024.\n\n"))
  cat(sprintf("%6s %10s %10s %8s %8s %9s %9s %9s %9s\n", "h", "d_total",
              "d_total_nd", "sink", "deep", "dz_mid0", "dC_ml", "dC_int", "ML %"))
  for (i in seq_len(nrow(tab)))
    cat(sprintf("%6g %10.1f %10.1f %8.3f %8.1f %9.1f %9.2f %9.2f %8.1f\n",
                tab$h[i], tab$d_total[i], tab$d_total_nd[i], tab$sink[i],
                tab$deep[i], tab$dz_mid0[i], tab$dC_ml[i], tab$dC_int[i],
                tab$ml_share[i]))

  r0 <- tab[tab$h == HR_H_REF, ]; r1 <- tab[tab$h == HR_H_MODE, ]
  cat(sprintf("\n--- %g m -> %g m ---\n", HR_H_REF, HR_H_MODE))
  cat(sprintf("  fit           %+.1f log-units\n", r1$d_total))
  cat(sprintf("  ocean sink    %.3f -> %.3f GtC/yr  (%+.3f)\n",
              r0$sink, r1$sink, r1$sink - r0$sink))
  cat(sprintf("  dz_mid0       %.1f -> %.1f m  -> interface conductance x%.2f  [EXPORT, WRONG WAY]\n",
              r0$dz_mid0, r1$dz_mid0, r0$dz_mid0 / r1$dz_mid0))
  cat(sprintf("  ML capacity   x%.2f  [CAPACITY, RIGHT WAY]\n", HR_H_MODE / HR_H_REF))
  cat(sprintf("  extra C in ML       %+.2f GtC\n", r1$dC_ml  - r0$dC_ml))
  cat(sprintf("  extra C in interior %+.2f GtC\n", r1$dC_int - r0$dC_int))
  dml <- r1$dC_ml - r0$dC_ml; dint <- r1$dC_int - r0$dC_int
  cat(sprintf("  VERDICT: %s\n", if (dml > 0 && dint <= 0)
      "CAPACITY -- the extra uptake is STORED IN THE MIXED LAYER and the interior gets LESS"
    else if (dint > 0 && dml <= 0)
      "EXPORT -- the extra uptake is passed to the interior"
    else if (dml > 0 && dint > 0) "BOTH RESERVOIRS GAIN -- report the split, do not force it"
    else "NEITHER GAINS -- re-read the sign of the fit change first"))
  invisible(tab)
}

sep("PART 1. THE TWO CHANNELS HAVE OPPOSITE SIGNS -- READ OFF THE GRID ALONE")
# Nothing is run here. dz_mid[0] = (h_ml + dz_int1)/2 is the distance across
# which the mixed layer talks to the interior, so it GROWS with h_ml and the
# diffusive conductance kz/dz_mid[0] FALLS. Capacity (A*h*rho) rises. This is
# what makes the two channels separable without breaking any identity.
cat(sprintf("%6s %10s %10s %14s %16s\n", "h", "dz_int1", "dz_mid0",
            "capacity rel", "conductance rel"))
g0 <- ccx_ocean_grid(HR_H_REF); dzm0 <- (g0$dz[1] + g0$dz[2]) / 2
for (h in HR_H_GRID) {
  g <- ccx_ocean_grid(h); dzm <- (g$dz[1] + g$dz[2]) / 2
  cat(sprintf("%6g %10.1f %10.1f %13.2fx %15.2fx\n", h, g$dz[2], dzm,
              h / HR_H_REF, dzm0 / dzm))
}
cat("\nDeepening the mixed layer RAISES capacity and LOWERS export conductance.\n")
cat("So a fit that IMPROVES with depth cannot be buying export -- the export\n")
cat("channel is moving against it. That is the whole logic of parts 2 and 3.\n")

sep("PART 2 & 3. THE PREFERENCE, AND WHERE THE CARBON ACTUALLY GOES")
out <- list()
out$default <- hr_profile(ccx_default_params(), HR_BOMB_REF, 1.0,
                          HR_ERR_DEFAULT, "at ccx_default_params()")

pm <- NULL
if (file.exists(HR_MODE_PATH)) {
  md <- readRDS(HR_MODE_PATH); pm <- md$par_mode
  p2 <- ccx_default_params()
  for (n in intersect(names(p2), names(pm))) p2[[n]] <- pm[[n]]
  p2 <- ccx_set_enso(p2, pm)
  out$mode <- hr_profile(p2, pm$bomb_total, pm$luc_scale, HR_ERR_MODE,
    "at the pre-gradient MAP mode's OTHER parameters (h_ml overridden)")
}

sep("PART 4. kz IS THE PURE EXPORT KNOB -- CAN IT SUBSTITUTE?")
# kz multiplies every interior diffusive flux and touches neither ml_mass_kg nor
# the carbonate chemistry, so it is export and nothing else. If h_ml's benefit
# were export, raising kz would deliver it and the deep-h_ml preference would
# collapse. Run the h_ml profile at each kz multiplier and see whether the
# preferred depth moves.
if (!is.null(pm)) {
  cat(sprintf("Laplace correlation at the mode: r(h_ml, kz) = %.3f",
              md$cor["h_ml", "kz"]))
  cat("  -- weak, i.e. they are NOT strong substitutes\n")
  cat(sprintf("kz at the mode = %.0f, bracket [%g, %g] -- %.1f %% of the way up\n\n",
              pm$kz, CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi,
              100 * (pm$kz - CCX_PARAM_TABLE$kz$lo) /
                (CCX_PARAM_TABLE$kz$hi - CCX_PARAM_TABLE$kz$lo)))
  p2 <- ccx_default_params()
  for (n in intersect(names(p2), names(pm))) p2[[n]] <- pm[[n]]
  p2 <- ccx_set_enso(p2, pm)
  cat("log-likelihood relative to (h = 75, this row's kz). BEST h per row marked *.\n")
  cat("kz factors run PAST the calibration bracket on purpose: if the answer\n")
  cat("changed only outside it, the bracket would be creating the result.\n\n")
  cat(sprintf("%10s %9s", "kz factor", "kz"))
  for (h in HR_H_GRID) cat(sprintf(" %9s", sprintf("h=%g", h)))
  cat("   best\n")
  kzrows <- list()
  for (fac in HR_KZ_FAC) {
    p3 <- p2; p3$kz <- pm$kz * fac
    v <- vapply(HR_H_GRID, function(h) {
      pp <- p3; pp$h_ml <- h
      e <- hr_eval(pp, pm$bomb_total, pm$luc_scale, HR_ERR_MODE)
      if (is.null(e)) NA_real_ else e$total
    }, numeric(1))
    v <- v - v[HR_H_GRID == HR_H_REF]
    cat(sprintf("%9.1fx %9.0f", fac, p3$kz))
    for (j in seq_along(v)) cat(sprintf(" %9.1f", v[j]))
    cat(sprintf("   %g m%s\n", HR_H_GRID[which.max(v)],
                if (p3$kz > CCX_PARAM_TABLE$kz$hi) "  (kz past bracket)" else ""))
    kzrows[[as.character(fac)]] <- v
  }
  out$kz <- kzrows
  best <- vapply(kzrows, function(v) HR_H_GRID[which.max(v)], numeric(1))
  cat(sprintf("\nPreferred depth across a %.0fx range of the pure export knob: %s\n",
              max(HR_KZ_FAC) / min(HR_KZ_FAC),
              paste(sprintf("%g", best), collapse = ", ")))
  cat(sprintf("VERDICT: %s\n", if (length(unique(best)) == 1L)
      "UNMOVED -- export cannot substitute for what h_ml supplies"
    else "the preferred depth MOVES with kz -- export is at least part of it"))
} else cat("quarantined mode absent -- part 4 skipped.\n")

sep("PART 5. THE TWO TESTS DISAGREE -- WHICH CONSTRAINT IS DRIVING THE FLIP?")
# Parts 2-3 and part 4 give OPPOSITE verdicts under their own pre-registered
# rules, and that is the finding rather than a failure:
#   * part 3 -- deepening puts the extra carbon IN THE MIXED LAYER (+32 GtC)
#     while the interior LOSES (-19 GtC). That is the capacity signature.
#   * part 4 -- give the model more of the pure export knob and it stops wanting
#     a deep mixed layer at all. That is the export signature.
# Both are true, at different levels: what the objective is short of is total
# ocean UPTAKE, h_ml is a CAPACITY route to it, and the model reaches for that
# route because kz is bracket-limited. The remaining question is what pays for
# it, because that decides whether a pump is an improvement or a re-arrangement.
if (!is.null(pm)) {
  p2 <- ccx_default_params()
  for (n in intersect(names(p2), names(pm))) p2[[n]] <- pm[[n]]
  p2 <- ccx_set_enso(p2, pm)
  corners <- list(
    `mode (kz x1.0, h 184)`      = list(kz = pm$kz * 1.0, h = 184),
    `deeper kz  (x1.4, h 184)`   = list(kz = pm$kz * 1.4, h = 184),
    `pump-like  (x1.4, h  50)`   = list(kz = pm$kz * 1.4, h =  50))
  ev <- lapply(corners, function(cc) {
    pp <- p2; pp$kz <- cc$kz; pp$h_ml <- cc$h
    hr_eval(pp, pm$bomb_total, pm$luc_scale, HR_ERR_MODE)
  })
  ok <- !vapply(ev, is.null, logical(1))
  if (all(ok)) {
    cat(sprintf("%-26s %8s %8s %9s %9s\n", "configuration", "sink", "deep",
                "dC_ml", "dC_int"))
    for (nm in names(ev))
      cat(sprintf("%-26s %8.3f %8.1f %9.2f %9.2f\n", nm, ev[[nm]]$sink,
                  ev[[nm]]$deep, ev[[nm]]$dC_ml, ev[[nm]]$dC_int))
    ref <- ev[[1]]$parts
    cat("\nper-stream change from the mode, biggest movers first:\n")
    for (nm in names(ev)[-1]) {
      d <- ev[[nm]]$parts - ref[names(ev[[nm]]$parts)]
      d <- sort(d[abs(d) > 1], decreasing = TRUE)
      cat(sprintf("\n  %s   (total %+.1f)\n", nm, sum(ev[[nm]]$parts) - sum(ref)))
      for (s in names(d)) cat(sprintf("    %-24s %+10.1f\n", s, d[[s]]))
    }
    # ---- what the export route COSTS, against the deep target ---------
    # The target and its sigma are read from the likelihood's own accessor, not
    # copied, so this cannot go stale against LIK_D14C_DEEP_NEFF.
    tg <- ccx_deep_d14c_target()
    if (!is.null(tg)) {
      cat(sprintf("\ndeep-D14C target %.1f permil, sigma %.1f (n_eff %d, layer %s m)\n",
                  tg$target, tg$sd, tg$n_eff,
                  paste(round(tg$layer), collapse = "-")))
      cat(sprintf("%-26s %10s %8s\n", "configuration", "deep", "z"))
      for (nm in names(ev))
        cat(sprintf("%-26s %10.1f %8.2f\n", nm, ev[[nm]]$deep,
                    (ev[[nm]]$deep - tg$target) / tg$sd))
      cat("\nTHE BINDING CONSTRAINT ON THE EXPORT ROUTE. The model is ALREADY on the\n")
      cat("under-depleted side of this target at the mode, and buying export with\n")
      cat("kz moves it FURTHER that way -- because diffusion ventilates 14C in\n")
      cat("proportion to the carbon it moves. That is what a pump does NOT do: it\n")
      cat("exports carbon as sinking particles and remineralises it at depth,\n")
      cat("raising deep DIC without mixing surface water down. So the pump is not\n")
      cat("merely another export knob -- it is the only one that can add uptake\n")
      cat("WITHOUT paying this term. Item 9's case is better motivated than the\n")
      cat("h_ml decomposition alone suggests.\n")
      cat("\nAMENDMENT TO ITEM 9'S PRE-REGISTERED TEST. handoff 2026-08-15 sec.4.2\n")
      cat("set it as: does h_ml relax below ~163 m and kz off the top of its\n")
      cat("bracket, while the ocean sink holds near 3.1? Part 4 shows h_ml DOES\n")
      cat("relax once export is available, so that clause is now measured-\n")
      cat("plausible rather than speculative -- but it is not sufficient. ADD A\n")
      cat("THIRD CLAUSE: does deep D14C move TOWARD the target rather than away?\n")
      cat("That is the clause the kz route fails, and so the one the pump must\n")
      cat("beat to be an improvement rather than a re-arrangement.\n")
    }
  }
}

saveRDS(out, file.path(HR_OUTDIR, "diag_h_ml_roles.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(HR_OUTDIR, "diag_h_ml_roles.rds")))
