
# =====================================================================
# diag_sigma_inflation_pricing.R -- WHAT DOES σ-INFLATION ACTUALLY COST
# THE OUT-OF-BAND ARGMAX?
#
# PRE-REGISTERED: notes/prereg_2026-08-28b_sigma_inflation_pricing.md, committed
# (15d1906) BEFORE this file existed. Gates copied unchanged.
#
# 08-28 sec.6 proposed re-running the out-of-band profile points with inflation
# ON and reading the argmax. Both sides are boundable EXACTLY from artifacts
# already on disk, so this brackets first and holds the refit in reserve:
#
#   LOWER(h) = lp_shipped(h) - rows_shipped(h) + rows_inflated(h)   [stored vector]
#   UPPER(h) = lp_shipped(h) - rows_shipped(h) + ceiling(h)         [density peak]
#
# Re-optimising the five free parameters with the rows ON can only RAISE the
# objective above its value at the stored vector, and can never raise a row above
# its own density peak. So the value sec.6's refit would report lies in
# [LOWER, UPPER] at every h, and if max UPPER(out) < max LOWER(in) the argmax is
# PROVABLY in-band.
#
# ⚠ NOTHING HERE CHANGES AN OBJECTIVE. LIK_OCEAN_GRAD_HML_OK_RETIRED and the skip stay
# exactly as shipped; inflation is computed in this driver only, and no refit is
# owed by anything it prints. [[ccx_hml_band_discont]] [[hml_cliff_is_the_free_lunch]]
#
# Usage:  Rscript calibration/diag_sigma_inflation_pricing.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

SI_YEARS    <- c(1750, 2024)
SI_BAND     <- LIK_OCEAN_GRAD_HML_OK_RETIRED               # [85, 120], read not typed
SI_PROFILE  <- ccx_path("outputs", "diagnostics", "hml_unbound_profile.rds")
SI_SR_ISO   <- ccx_path("calibration", "output", "hml_band_discontinuity",
                        "hml_band_discontinuity.rds")   # DIC + d13C, 16g part 4
SI_SR_ALK   <- ccx_path("calibration", "output", "alk_sigma_rep",
                        "alk_sigma_rep.rds")             # ALK, 08-18
SI_OUTDIR   <- ccx_path("outputs", "diagnostics")
SI_OUT      <- file.path(SI_OUTDIR, "sigma_inflation_pricing.rds")
SI_ROWS     <- c(dic = "ocean_grad_dic", d13c = "ocean_grad_d13c", alk = "ocean_grad_alk")
SI_H_MODE   <- 96.4737                              # the profile's own anchor point
# ---- PRE-REGISTERED GATES, prereg sec.3. Named so scoring cannot move them.
SI_G2_NOISE <- 0.70    # log-units; the refit's own restart noise floor (08-28 sec.6)
SI_G3_JUMP  <- 1.00    # log-units; "the cliff is gone" bar, against a shipped -7.300
SI_G4_MODE  <- 0.30    # log-units; inflation's cost at the mode
SI_S6_CLAIM <- 1.60    # what 08-28 sec.6 inferred the residual pull would be

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# ---------------------------------------------------------------------
# 1. THE INPUTS
# ---------------------------------------------------------------------
prof <- readRDS(SI_PROFILE)
sr_iso <- readRDS(SI_SR_ISO)$sigma_rep
sr_alk <- readRDS(SI_SR_ALK)$alk
SR <- list(dic = sr_iso$dic, d13c = sr_iso$d13c, alk = sr_alk)
# The three curves must share a grid, or the quadrature mixes h's.
stopifnot(identical(SR$dic$h, SR$d13c$h), identical(SR$dic$h, SR$alk$h))
stopifnot(identical(prof$band, SI_BAND))

md <- readRDS(ccx_mode_file())
pm <- ccx_mode_params(md)                            # ⚠ NOT ccx_unc_to_par(md$u_mode)
tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg$dic), !is.null(tg$d13c), !is.null(tg$alk))

cat(sprintf("mode          : %s | h_ml %.4f m\n", basename(ccx_mode_file()), pm$h_ml))
cat(sprintf("profile       : %s (%d points, band [%g, %g])\n", basename(SI_PROFILE),
            length(prof$res), prof$band[1], prof$band[2]))
cat(sprintf("sigma_rep     : %s + %s (%d h, %g-%g m)\n", basename(SI_SR_ISO),
            basename(SI_SR_ALK), nrow(SR$dic), min(SR$dic$h), max(SR$dic$h)))
cat("⚠ the shipped skip is UNTOUCHED; inflation is computed in this driver only.\n")

# sigma_rep(h) by PCHIP through the MEASURED points -- never a parametric fit.
# [[use real data when you have it]]
si_sigma_rep <- function(row, h) {
  d <- SR[[row]]
  stats::splinefun(d$h, d$sigma_rep, method = "monoH.FC")(h)
}
si_sd_obs <- function(row) tg[[row]]$sd
si_sd_eff <- function(row, h) sqrt(si_sd_obs(row)^2 + pmax(0, si_sigma_rep(row, h))^2)
# The density PEAK: the most a row can EVER score at this h. UPPER's whole content.
si_ceiling <- function(h) sum(vapply(names(SI_ROWS), function(r)
  -log(sqrt(2 * pi) * si_sd_eff(r, h)), numeric(1)))

sep("σ_eff AND THE CEILING ACROSS THE PROFILE'S OWN GRID")
cat(sprintf("%9s %6s | %8s %8s %8s | %10s\n", "h_ml", "rows",
            "sr/so DIC", "d13C", "ALK", "ceiling"))
for (h in prof$grid)
  cat(sprintf("%9.4f %6s | %8.3f %8.3f %8.3f | %+10.4f\n", h,
              if (h >= SI_BAND[1] && h <= SI_BAND[2]) "LIVE" else "off",
              si_sigma_rep("dic", h) / si_sd_obs("dic"),
              si_sigma_rep("d13c", h) / si_sd_obs("d13c"),
              si_sigma_rep("alk", h) / si_sd_obs("alk"), si_ceiling(h)))

# ---------------------------------------------------------------------
# 2. THE MODEL GRADIENT AT EACH STORED VECTOR -- the band gate BYPASSED
#    ccx_ocean_grad_scored() returns NULL out of band by design. The gate lives
#    in that wrapper alone, so the underlying gradient is computable at any h_ml
#    and this reads it directly. That is a DIAGNOSTIC bypass, not an edit.
# ---------------------------------------------------------------------
si_grad_at <- function(pv) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", SI_YEARS, prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / CCX_BOMB_REF)
  for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  gd <- ccx_model_ocean_gradient(o, sp$aux, sp$grid,
                                 list(surf = tg$dic$epoch_surf, deep = tg$dic$epoch_deep))
  g3 <- ccx_model_ocean_gradient(o, sp$aux, sp$grid,
                                 list(surf = tg$d13c$epoch_surf, deep = tg$d13c$epoch_deep))
  pump <- if (!is.null(sp$aux$pump))
    list(S_org = lapply(sp$aux$pump, `[[`, "org"),
         S_carb = lapply(sp$aux$pump, `[[`, "carb")) else NULL
  list(dic = gd$dic, d13c = g3$d13c,
       alk = ccx_model_ocean_alk_gradient(sp, pump = pump))
}
# A row's logL at a stated sd. `sd = obs` reproduces the shipped in-band term.
si_row <- function(row, v, sd) stats::dnorm(tg[[row]]$target, v, sd, log = TRUE)

sep("THE BRACKET -- one model evaluation per stored vector")
cat(sprintf("%9s %6s | %11s | %10s %10s | %11s %11s | %8s\n", "h_ml", "rows",
            "lp_shipped", "rows_ship", "rows_infl", "LOWER", "UPPER", "width"))
flush.console()
rows <- list()
for (k in names(prof$res)) {
  r <- prof$res[[k]]; h <- r$h
  t0 <- Sys.time()
  g <- si_grad_at(r$pv)
  live <- h >= SI_BAND[1] && h <= SI_BAND[2]
  # rows_shipped is EXACTLY 0 out of band -- that is the skip, and it is the
  # whole free lunch. In band it is the sigma_obs term the objective already has.
  rs <- if (live) sum(vapply(names(SI_ROWS), function(n)
                              si_row(n, g[[n]], si_sd_obs(n)), numeric(1))) else 0
  ri <- sum(vapply(names(SI_ROWS), function(n)
                   si_row(n, g[[n]], si_sd_eff(n, h)), numeric(1)))
  lo <- r$lp - rs + ri
  up <- r$lp - rs + si_ceiling(h)
  rows[[k]] <- list(h = h, live = live, lp = r$lp, rows_ship = rs, rows_infl = ri,
                    ceiling = si_ceiling(h), lower = lo, upper = up, grad = g,
                    secs = as.numeric(difftime(Sys.time(), t0, units = "secs")))
  cat(sprintf("%9.4f %6s | %+11.2f | %+10.4f %+10.4f | %+11.2f %+11.2f | %8.4f\n",
              h, if (live) "LIVE" else "off", r$lp, rs, ri, lo, up, up - lo))
  flush.console()
}
# ⚠ WRITE THE ARTIFACT BEFORE ANY PRETTY-PRINTING. A reporting bug destroyed 45
# minutes of fits on 08-28 because saveRDS came after it.
dir.create(SI_OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(rows = rows, band = SI_BAND, grid = prof$grid, sigma_rep = SR,
             gates = c(G2 = SI_G2_NOISE, G3 = SI_G3_JUMP, G4 = SI_G4_MODE,
                       s6_claim = SI_S6_CLAIM),
             mode_file = ccx_mode_file(), profile = SI_PROFILE), SI_OUT)
cat(sprintf("\nwrote %s\n", SI_OUT))

# ---------------------------------------------------------------------
# 3. THE PRE-REGISTERED GATES
# ---------------------------------------------------------------------
H  <- vapply(rows, function(x) x$h, 0)
LV <- vapply(rows, function(x) x$live, TRUE)
LO <- vapply(rows, function(x) x$lower, 0)
UP <- vapply(rows, function(x) x$upper, 0)
LP <- vapply(rows, function(x) x$lp, 0)
at <- function(h) which.min(abs(H - h))

sep("THE PRE-REGISTERED GATES")
best_in_lo  <- max(LO[LV]);  h_in_lo  <- H[LV][which.max(LO[LV])]
best_out_up <- max(UP[!LV]); h_out_up <- H[!LV][which.max(UP[!LV])]
resid <- best_out_up - best_in_lo
g1 <- best_out_up < best_in_lo
cat(sprintf("G1  argmax provably IN-BAND     : max LOWER(in)  %+.3f at %.4f m\n",
            best_in_lo, h_in_lo))
cat(sprintf("                                  max UPPER(out) %+.3f at %.4f m\n",
            best_out_up, h_out_up))
cat(sprintf("    %s -- the bracket %s\n", if (g1) "PASS" else "FAIL",
            if (g1) "SEPARATES; Stage B is NOT owed" else
              "OVERLAPS; STAGE B IS OWED (the 26-point refit with inflation ON)"))

g2 <- resid <= SI_G2_NOISE
cat(sprintf("\nG2  residual pull <= %.2f        : %+.3f log-units   %s\n", SI_G2_NOISE,
            resid, if (g2) "PASS" else "FAIL"))
cat(sprintf("    08-28 sec.6 inferred ~%.2f; measured here %+.3f (%s)\n", SI_S6_CLAIM, resid,
            if (resid < SI_S6_CLAIM) "sec.6 OVERSTATED the residual" else
              "sec.6's magnitude STANDS"))
cat(sprintf("    the shipped skip's own pull was +7.39 (08-28 sec.5)\n"))

jump85  <- abs(LO[at(85.01)]  - LO[at(84.99)])
jump120 <- abs(LO[at(120.01)] - LO[at(119.99)])
g3 <- jump85 < SI_G3_JUMP && jump120 < SI_G3_JUMP
cat(sprintf("\nG3  cliff gone (< %.2f)          : 85 %.4f | 120 %.4f   %s\n", SI_G3_JUMP,
            jump85, jump120, if (g3) "PASS" else "FAIL"))
cat(sprintf("    shipped, same straddles      : 85 %.4f | 120 %.4f\n",
            abs(LP[at(85.01)] - LP[at(84.99)]), abs(LP[at(120.01)] - LP[at(119.99)])))

i_m <- at(SI_H_MODE); cost_mode <- LO[i_m] - LP[i_m]
g4 <- abs(cost_mode) <= SI_G4_MODE
cat(sprintf("\nG4  inflation cheap in band      : %+.4f at %.4f m (bar %.2f)   %s\n",
            cost_mode, H[i_m], SI_G4_MODE, if (g4) "PASS" else "FAIL"))

sep("VERDICT")
cat(sprintf("G1 %s  G2 %s  G3 %s  G4 %s\n",
            ifelse(g1,"✓","✗"), ifelse(g2,"✓","✗"),
            ifelse(g3,"✓","✗"), ifelse(g4,"✓","✗")))
if (g1 && g2) {
  cat(strwrap(paste(
    "⇒ σ-INFLATION CLOSES THE FREE LUNCH. With the rows scored at σ_eff at every",
    "h_ml, the objective's argmax is provably inside [85, 120] with no hard bound,",
    "so the bound stops being load-bearing. 08-28 sec.6's ~1.6 residual was 16g's",
    "21 % ratio applied to a base that is not 16g's."), 92), sep = "\n")
} else if (!g1) {
  cat(strwrap(paste(
    "⇒ THE BRACKET DOES NOT SEPARATE. STAGE B IS OWED: re-run the 26 profile",
    "points with inflation ON and read the argmax directly. Nothing here decides",
    "the option; the bracket only failed to be decisive."), 92), sep = "\n")
} else {
  cat(strwrap(paste(
    "⇒ THE ARGMAX IS IN BAND BUT THE RESIDUAL EXCEEDS THE NOISE FLOOR. Inflation",
    "reduces the pull without erasing it; sec.6's caution stands in magnitude."), 92),
    sep = "\n")
}
cat("\n⚠ This prices ONE variant. Correcting the TARGET to its like-for-like value\n")
cat("  at h_ml is a DIFFERENT and more aggressive remedy, measurable from the same\n")
cat("  curves, NOT priced here, and NOT proposed. Marcus's call. (prereg sec.4)\n")
