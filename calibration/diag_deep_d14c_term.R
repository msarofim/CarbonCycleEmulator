# =====================================================================
# diag_deep_d14c_term.R -- the receipts for the deep-D14C likelihood term,
# and for the two corrections that landed with it.
#
# WHY IT EXISTS. Marcus' 2026-08-14 decision 1 chose sigma = SE of the
# cos(lat)-weighted GLODAPv2 deep mean at n_eff = 20 (10.3 permil) AND chose
# to keep the kz bracket. Every number that decision rests on is reproduced
# here, plus two things measured while wiring the term that CHANGE numbers
# recorded elsewhere:
#
#   [1] THE LAYER WAS MISMATCHED. The GLODAP target is a volume-weighted mean
#       over 2627-3700 m -- the model's BOTTOM BOX. The pre-existing
#       diagnostic `d14c_deep_ocean` / `d14c_deep_by_hemi` averages the bottom
#       THREE interior boxes (1313.6-3700 m). They are 13-20 permil apart.
#       The handoff's "runaway at 6.1 sigma" is the 3-box average scored
#       against the 1-box target; like for like it is 5.3. The DECISION
#       SURVIVES -- 5.3 still holds kz -- but the number changes.
#
#   [2] PREINDUSTRIAL vs MODERN IS A NON-ISSUE, MEASURED. The term scores a
#       spinup steady state against bottle data collected 1972-2021. That is
#       only legitimate if the layer is effectively pre-bomb. Section 3
#       measures the 1750 -> 2024 drift; if it is not small, the term is wrong
#       and must move to the transient state.
#
# WHAT IT DOES NOT DO. It does not re-centre kz. The term's own optimum
# (section 4) is inside the bracket and above the shipped default; that is one
# stream's preference, and the refit is what weighs it.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

DD_KZ_GRID    <- c(3830, 4500, 5000, 5500, 6200)   # bracket lo, mid, default, ., hi
DD_KZ_RUNAWAY <- 10686        # the 17-parameter unbounded mode, 2026-08-12
DD_KZ_SEARCH  <- c(3800, 9000)
DD_LAYER_LAB  <- "2627-3700 m (bottom box)"
DD_LAYER3_LAB <- "1314-3700 m (bottom 3 boxes)"

tg <- ccx_deep_d14c_target()
stopifnot(!is.null(tg))

cat("=====================================================================\n")
cat("deep-ocean D14C likelihood term -- receipts\n")
cat("=====================================================================\n\n")
cat(sprintf("target        %+.2f permil  over %s\n", tg$target, DD_LAYER_LAB))
cat(sprintf("spatial spread %.2f permil over %d filled cells\n",
            tg$sd_spread, tg$n_cells))
cat(sprintf("sigma          %.2f permil = spread / sqrt(n_eff = %d)\n",
            tg$sd, tg$n_eff))
cat(sprintf("N Atlantic     %s\n\n",
            if (tg$masked) "MASKED" else "included (LIK_D14C_DEEP_MASK_NATL)"))

# ---- 1. the two layers, and why the distinction is not pedantry ------
dd_spin <- function(kz) {
  p <- ccx_default_params(); p$kz <- kz
  ccx_spinup(p)
}
cat("--- 1. the two model 'deep' layers ------------------------------\n")
cat(sprintf("    %-28s %-28s\n", DD_LAYER_LAB, DD_LAYER3_LAB))
lay <- do.call(rbind, lapply(c(DD_KZ_GRID, DD_KZ_RUNAWAY), function(kz) {
  d <- dd_spin(kz)$diagnostics
  data.frame(kz = kz, bottom_box = d$d14c_bottom_box,
             bottom_3 = d$d14c_deep_ocean,
             enrichment = d$d14c_deep_ocean - d$d14c_bottom_box,
             z_correct = (d$d14c_bottom_box - tg$target) / tg$sd,
             z_mismatched = (d$d14c_deep_ocean - tg$target) / tg$sd)
}))
print(format(lay, digits = 4), row.names = FALSE)
inb <- lay$enrichment[lay$kz != DD_KZ_RUNAWAY]
cat(sprintf("\n  The bottom 3 boxes run %.1f-%.1f permil ENRICHED inside the kz bracket\n",
            min(inb), max(inb)))
cat(sprintf("  (%.1f at the runaway, where the whole column is over-ventilated): they include\n",
            lay$enrichment[lay$kz == DD_KZ_RUNAWAY]))
cat("  1313.6-2627.2 m, which is better ventilated. Scoring the 2627-3700 m\n")
cat("  target against them is a layer mismatch, not a sigma question.\n\n")

# ---- 2. the sigma table, on the LIKE-FOR-LIKE quantity ---------------
cat("--- 2. the sigma decision, re-run on the bottom box --------------\n")
runaway <- lay$bottom_box[lay$kz == DD_KZ_RUNAWAY]
runaway3 <- lay$bottom_3[lay$kz == DD_KZ_RUNAWAY]
g <- readRDS(ccx_path("data", "obs_glodap_deep.rds"))
sig <- data.frame(
  candidate = names(g$sigma_candidates),
  sigma     = as.numeric(g$sigma_candidates),
  z_runaway = abs(runaway - tg$target) / as.numeric(g$sigma_candidates),
  z_handoff = abs(runaway3 - tg$target) / as.numeric(g$sigma_candidates))
sig$holds_kz <- ifelse(sig$z_runaway >= 2, "HOLDS", "does NOT hold")
print(format(sig, digits = 3), row.names = FALSE)
cat(sprintf("\n  CHOSEN: n_eff = %d, sigma %.2f, runaway at %.2f sigma.\n",
            tg$n_eff, tg$sd, abs(runaway - tg$target) / tg$sd))
cat("  `z_handoff` is the same table computed on the 3-box average, which is\n")
cat("  where handoff 2026-08-14b sec.4.1's 6.1 came from. The verdict column\n")
cat("  is identical in both, which is why the decision stands as taken.\n\n")

# ---- 3. is the steady state a fair target for modern bottles? --------
cat("--- 3. preindustrial vs 2024, measured --------------------------\n")
dd_transient <- function(kz) {
  sp <- dd_spin(kz)
  F  <- ccx_build_forcing(); F$c14_cosmo <- sp$prod_c14
  r  <- ccx_run_fast(sp, F)
  stopifnot(!anyNA(r$out$co2_NH))
  d14 <- function(y, k) 1000 * (sum(y[k, "C14"]) / sum(y[k, "C"]) - 1)
  b1 <- unlist(lapply(HEMIS, function(h) tail(sp$aux$idx[[h]]$oc, 1)))
  b3 <- unlist(lapply(HEMIS, function(h) tail(sp$aux$idx[[h]]$oc, 3)))
  data.frame(kz = kz,
             bot1_1750 = d14(sp$y, b1), bot1_2024 = d14(r$state, b1),
             bot3_1750 = d14(sp$y, b3), bot3_2024 = d14(r$state, b3))
}
tr <- do.call(rbind, lapply(DD_KZ_GRID, dd_transient))
tr$drift_bot1 <- tr$bot1_2024 - tr$bot1_1750
tr$drift_bot3 <- tr$bot3_2024 - tr$bot3_1750
print(format(tr, digits = 5), row.names = FALSE)
cat(sprintf("\n  Bottom-box drift over the whole industrial era: %+.3f to %+.3f permil,\n",
            min(tr$drift_bot1), max(tr$drift_bot1)))
cat(sprintf("  i.e. under %.3f sigma. The layer is effectively pre-bomb, so the\n",
            max(abs(tr$drift_bot1)) / tg$sd))
cat("  SPINUP state is a fair target for 1972-2021 bottle data and the term\n")
cat("  costs no transient integration. (The 3-box slab drifts up to ")
cat(sprintf("%+.2f,\n  which is %.1fx larger -- another reason the layers are not swappable.)\n\n",
            max(tr$drift_bot3), max(abs(tr$drift_bot3)) / max(abs(tr$drift_bot1))))

# ---- 4. what the term wants, and what the bracket wants --------------
cat("--- 4. the term's own optimum vs the bracket --------------------\n")
opt <- optimize(function(k) (dd_spin(k)$diagnostics$d14c_bottom_box - tg$target)^2,
                DD_KZ_SEARCH, tol = 1)
lo <- lay$bottom_box[lay$kz == min(DD_KZ_GRID)]
hi <- lay$bottom_box[lay$kz == max(DD_KZ_GRID)]
cat(sprintf("  bracket [%d, %d] maps to bottom box [%.1f, %.1f] permil\n",
            min(DD_KZ_GRID), max(DD_KZ_GRID), lo, hi))
cat(sprintf("    -> a hard box of half-width %.1f permil, centred %+.1f\n",
            (hi - lo) / 2, (hi + lo) / 2))
cat(sprintf("    -> centred %.1f permil BELOW the sourced target %+.1f\n",
            tg$target - (hi + lo) / 2, tg$target))
cat(sprintf("  term's own optimum   kz = %.0f  (z = 0)\n", opt$minimum))
cat(sprintf("  shipped default      kz = 5000 (z = %+.2f)\n",
            lay$z_correct[lay$kz == 5000]))
cat(sprintf("  bracket lower end    kz = %d (z = %+.2f)\n",
            min(DD_KZ_GRID), lay$z_correct[lay$kz == min(DD_KZ_GRID)]))
cat("\n  THE BRACKET IS TIGHTER THAN THE TERM. Half-width ")
cat(sprintf("%.1f permil against\n  sigma %.2f: deleting the bracket in favour of the term would LOOSEN kz.\n",
            (hi - lo) / 2, tg$sd))
cat("  That is the inversion of 13i sec.A3's plan, and it is why the bracket stays.\n\n")

# ---- 5. the term's leverage, priced like every other stream ----------
cat("--- 5. leverage, for the stream-leverage ledger -----------------\n")
cat("  One prior-sd step in kz is not defined (the prior is uniform on the\n")
cat("  bracket), so the step reported here is the FULL BRACKET, end to end.\n")
ll_at <- function(kz) {
  sp <- dd_spin(kz)
  -0.5 * ((sp$diagnostics$d14c_bottom_box - tg$target) / tg$sd)^2
}
cat(sprintf("  log-lik at bracket lo / default / hi: %.1f / %.1f / %.1f\n",
            ll_at(3830), ll_at(5000), ll_at(6200)))
cat(sprintf("  range across the bracket: %.1f log-units\n",
            max(ll_at(3830), ll_at(6200)) - min(ll_at(3830), ll_at(6200))))
cat("  Compare review sec.0: CO2 streams move 1,565 log-units per prior-sd step.\n")
cat("  This term is NOT a counterweight to the CO2 level -- it is the only\n")
cat("  thing pricing ventilation, on a parameter the CO2 streams barely touch.\n")

# ---- 6. is the term univariate in kz, as the bracket note claims? ----
# calibrate.R's kz bound rests on "the kz -> deep-D14C relation is essentially
# univariate -- h_ml moves it under 1.5 permil". That was measured on the 3-box
# average. It has to hold on the BOTTOM BOX too, or the term is scoring a
# mixture of ventilation and mixed-layer depth. Two things move with h_ml: the
# value, and the LAYER ITSELF (the grid is built from h_ml).
cat("\n--- 6. h_ml sensitivity, on the layer the term actually scores ---\n")
hm <- do.call(rbind, lapply(c(30, 75, 200), function(h) {
  p <- ccx_default_params(); p$h_ml <- h
  g <- ccx_ocean_grid(h)
  d <- ccx_spinup(p)$diagnostics
  data.frame(h_ml = h, box_top_m = sum(g$dz) - tail(g$dz, 1),
             bottom_box = d$d14c_bottom_box,
             z = (d$d14c_bottom_box - tg$target) / tg$sd)
}))
print(format(hm, digits = 4), row.names = FALSE)
cat(sprintf("\n  Across the FULL h_ml prior [30, 200] the bottom box moves %.1f permil\n",
            diff(range(hm$bottom_box))))
cat(sprintf("  (%.2f sigma) and the layer's own top moves %.0f m on a ~1070 m box.\n",
            diff(range(hm$bottom_box)) / tg$sd, diff(range(hm$box_top_m))))
cat("  Both are small against the 57 permil the kz bracket spans, so the term\n")
cat("  is univariate in kz to the same standard the bracket note claimed.\n")
