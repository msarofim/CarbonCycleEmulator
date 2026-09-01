# =====================================================================
# diag_land_structure.R -- the two land-structure parameters added
# 2026-08-12, measured rather than argued.
#
#   npp_veg_frac (phi)  fraction of NPP that scales with the standing
#                       vegetation stock, so that clearing a forest reduces
#                       productive capacity and not only carbon.
#   ra_ratio            Ra/NPP routed THROUGH the vegetation pool -- the
#                       equilibrating part of GPP.
#
# THREE CLAIMS, EACH WITH ITS OWN TEST
#
#   [1] IS phi BOUNDED? A decoupled argument predicts divergence once the
#       standing-stock growth term outruns the pool's own loss rate,
#       f = 1 + beta ln(chi/chi0). RUN IT, do not trust the algebra.
#       RESULT: the prediction is WRONG -- see below. Kept as a live test so
#       the bound is not reinstated from the algebra alone. (Under the FOUR-pool
#       land the coefficient is on wood rather than on a single veg pool; same
#       shape, same order of magnitude, same CO2 feedback underneath it.)
#
#   [2] ra_ratio IS ISOTOPES-ONLY. GPP = NPP*(1+ra_ratio) down and Ra =
#       NPP*ra_ratio back up, so the NET atm->veg carbon flux is NPP for any
#       ra_ratio. If the CO2 and land-carbon trajectories move at all, the
#       implementation is wrong.
#
#   [3] WHAT IT BUYS. Asked when the bomb-14C partition put the biosphere
#       51-58 % above Naegler & Levin. RESULT: the gross loop moves it the
#       WRONG WAY at 1975 -- re-confirmed on the four-pool land, where the
#       partition is now closed and ra_ratio would move it back OFF target.
#
#   [4] SUPERSEDED 2026-08-12. It scanned (tau_veg, tau_soil), which the
#       four-pool land removed. Its conclusion -- one responsive soil pool
#       cannot match N&L's carbon stock and their 14C inventory at once -- is
#       what forced that restructure. Successor: diag_land_topology.R.
#
# Run from the repo root:  Rscript calibration/diag_land_structure.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants -------------------------------------------------
LAND_YEARS      <- c(1750, 2024)
LAND_REF_YEARS  <- c(1975, 1995)
LAND_BOMB_TOTAL <- 102                       # N&L citable total, as in
                                             # diag_bomb_partition.R
LAND_PHI_GRID   <- c(0, 0.25, 0.50, 0.75, 0.90, 1.00, 1.10)
LAND_RA_GRID    <- c(0, 0.25, 0.50, 0.75, 1.00, 1.50)
LAND_NL_SOURCE  <- "naegler_levin_2006_t4_YANG"
LAND_DIVERGE_X  <- 3                         # veg/veg0 above this = diverged

cat("\n=== diag_land_structure.R ===\n")
cat("phi = npp_veg_frac (capacity), ra_ratio = the equilibrating part of GPP\n\n")

base_p <- function() { p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0)); p }
run_p  <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", LAND_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = LAND_BOMB_TOTAL)
  list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
}
row_at <- function(o, y) which(floor(o$t + 1e-9) == y)[1]

# =====================================================================
# [1] phi: where does the vegetation pool stop being stable?
# =====================================================================
cat("=== [1] phi stability: is the decoupled bound phi * f < 1 real? ===\n")
p0 <- base_p()
r0 <- run_p(p0)
chi_end <- 0.5 * (r0$out$co2_NH[nrow(r0$out)] + r0$out$co2_SH[nrow(r0$out)])
f_end   <- 1 + p0$beta * log(chi_end / r0$sp$aux$chi0)
cat(sprintf("  at defaults: beta %.2f, chi(2024) %.1f ppm, chi0 %.1f -> f = %.4f\n",
            p0$beta, chi_end, r0$sp$aux$chi0, f_end))
cat(sprintf("  so the predicted bound is phi < 1/f = %.3f\n\n", 1 / f_end))
cat(sprintf("  %6s %14s %14s %10s\n", "phi", "land C 2024/1750", "CO2 2024", "verdict"))
phi_co2 <- numeric(0); phi_lnd <- numeric(0)
for (phi in LAND_PHI_GRID) {
  p <- base_p(); p$npp_veg_frac <- phi
  r <- try(run_p(p), silent = TRUE)
  if (inherits(r, "try-error")) { cat(sprintf("  %6.2f %14s\n", phi, "run FAILED")); next }
  o <- r$out; n <- nrow(o)
  vratio <- o$land_C[n] / o$land_C[1]
  co2 <- 0.5 * (o$co2_NH[n] + o$co2_SH[n])
  ok <- is.finite(vratio) && vratio < LAND_DIVERGE_X
  phi_co2 <- c(phi_co2, co2); phi_lnd <- c(phi_lnd, vratio)
  cat(sprintf("  %6.2f %14.3f %14.1f %10s\n", phi, vratio, co2,
              if (ok) "stable" else "DIVERGED"))
}
cat("  (total land C ratio -- soil follows vegetation, so it carries the signal)\n")
cat(sprintf("  -> NOT bounded. Every phi is stable, including phi*f = %.2f.\n",
            max(LAND_PHI_GRID) * f_end))
# THE SIGN FLIPPED WITH THE FOUR-POOL LAND, and the reason matters more than the
# verdict. Under the two-pool land, raising phi grew the vegetation pool and drew
# CO2 DOWN monotonically (413.7 -> 322.2 ppm across this grid): the capacity term
# was mostly amplifying CO2 fertilisation, more veg -> more NPP -> more veg, and
# that positive loop is what over-drained the pulse and broke the Joos airborne
# fraction. Under the four-pool land it goes the OTHER way -- because LUC debits
# WOOD, and wood is most of the vegetation, so a higher phi makes clearing cost
# productive capacity, which is the job the term was added to do. The runaway is
# gone with it, and so is the airborne-fraction failure (test-pulse.R:112/113 now
# pass at phi = 0.5).
cat(sprintf("     CO2 2024 now RISES with phi (%.1f -> %.1f ppm) where it once fell,\n",
            phi_co2[1], phi_co2[length(phi_co2)]))
cat(sprintf("     and land carbon FALLS (%.3f -> %.3f of its 1750 value): with LUC\n",
            phi_lnd[1], phi_lnd[length(phi_lnd)]))
cat("     debiting wood, phi now costs capacity rather than amplifying growth.\n")
cat("     The stabiliser is still the CO2 column -- it just acts in the opposite\n")
cat("     direction. The decoupled algebra held chi fixed; it never is.\n\n")

# =====================================================================
# [2] ra_ratio must not touch the carbon
# =====================================================================
cat("=== [2] ra_ratio is isotopes-only: the carbon must not move ===\n")
ref <- run_p(base_p())
cat(sprintf("  %8s %16s %16s %14s\n", "ra_ratio", "max|dCO2| ppm", "max|dlandC| GtC", "d14c_NH 1975"))
for (ra in LAND_RA_GRID) {
  p <- base_p(); p$ra_ratio <- ra
  o <- run_p(p)$out
  i <- row_at(o, 1975)
  cat(sprintf("  %8.2f %16.3e %16.3e %14.1f\n", ra,
              max(abs(o$co2_NH - ref$out$co2_NH)),
              max(abs(o$land_C - ref$out$land_C)), o$d14c_NH[i]))
}
cat("  -> anything above ~1e-9 in the first two columns is an implementation bug,\n")
cat("     not a modelling result. The 14C column is what the parameter is FOR.\n\n")

# =====================================================================
# [3] what the gross loop buys on the bomb-14C partition
# =====================================================================
cat("=== [3] the bomb-14C partition vs ra_ratio ===\n")
nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nl_val <- function(q, y) nl$kmol_14c[nl$source == LAND_NL_SOURCE &
                                       nl$quantity == q & nl$year == y][1]
cat(sprintf("  target (N&L Table 4): troposphere %.1f / %.1f, biosphere %.1f / %.1f kmol\n",
            nl_val("troposphere", 1975), nl_val("troposphere", 1995),
            nl_val("biosphere", 1975), nl_val("biosphere", 1995)))
cat("  NOTE: this parameter vector is NOT calibrated -- read the DIRECTION and the\n")
cat("  size of the move per unit ra_ratio, not the absolute level.\n\n")
cat(sprintf("  %8s %11s %11s %11s %11s\n", "ra_ratio",
            "trop 1975", "bio 1975", "trop 1995", "bio 1995"))
ra_grid_v <- matrix(NA_real_, nrow = length(LAND_RA_GRID), ncol = 4)
ri <- 0
for (ra in LAND_RA_GRID) {
  p <- base_p(); p$ra_ratio <- ra
  r <- run_p(p)
  Fn <- r$F; Fn$c14_bomb <- 0; Fn$c14_nuclear <- 0
  on <- ccx_run_fast(r$sp, Fn)$out
  v <- vapply(LAND_REF_YEARS, function(y) {
    i <- row_at(r$out, y)
    c(ccx_c14_kmol(r$out$atm_C14[i]  - on$atm_C14[i]),
      ccx_c14_kmol(r$out$land_C14[i] - on$land_C14[i]))
  }, numeric(2))
  cat(sprintf("  %8.2f %11.2f %11.2f %11.2f %11.2f\n", ra, v[1,1], v[2,1], v[1,2], v[2,2]))
  ri <- ri + 1; ra_grid_v[ri, ] <- c(v[1,1], v[2,1], v[1,2], v[2,2])
}
# Endpoints printed from the measured grid, not restated -- the two-pool numbers
# that used to be written into this paragraph (39.7 -> 44.1) survived a
# structural change that invalidated them.
lo <- ra_grid_v[1, ]; hi <- ra_grid_v[nrow(ra_grid_v), ]
cat("\n  PREDICTED: biosphere falls, troposphere rises -- a faster gross exchange was\n")
cat("  expected to let vegetation dump its bomb 14C back rather than remember the peak.\n")
cat(sprintf("  MEASURED, at 1975: the biosphere RISES (%.2f -> %.2f kmol) and the\n",
            lo[2], hi[2]))
cat(sprintf("  troposphere FALLS (%.2f -> %.2f). The prediction is falsified, and in the\n",
            lo[1], hi[1]))
cat(sprintf("  same direction the two-pool land showed. At 1995 the troposphere moves the\n"))
cat(sprintf("  predicted way (%.2f -> %.2f) while the biosphere is nearly flat (%.2f -> %.2f).\n",
            lo[3], hi[3], lo[4], hi[4]))
cat("  The reason is that in 1975 the atmosphere is still far above natural, so a\n")
cat("  lagging vegetation pool is still CATCHING UP and holds LESS than equilibrium.\n")
cat("  Faster exchange closes that gap, i.e. holds MORE. Equilibrating harder is the\n")
cat("  wrong lever while the source is still elevated -- which is the caution Marcus\n")
cat("  raised about GPP (2026-08-12), confirmed numerically and now twice, on two\n")
cat("  different land structures. ra_ratio is still correct physics and still\n")
cat("  isotopes-only; it is simply not what closed the partition gap.\n")
cat("  NOTE the level has moved: the biosphere now STARTS at the N&L target rather\n")
cat("  than 51 % above it, so a large ra_ratio would now push it OFF a value that is\n")
cat("  currently right. That is an argument for keeping the default at 0.\n")

# =====================================================================
# [4] SUPERSEDED 2026-08-12 -- see calibration/diag_land_topology.R
# =====================================================================
# [4] scanned (tau_veg, tau_soil) and showed the land's bomb-14C excess is
# strongly SUB-LINEAR in pool size: N&L's kmol-per-100-GtC was reached only by a
# pool twice theirs, their absolute inventory only by a pool six times too
# small. That finding is what forced the four-pool land, and it is preserved in
# CHANGELOG.md (2026-08-12) and in diag_land_topology.R's header.
#
# The scan itself CANNOT be re-run: `tau_veg` and `tau_soil` no longer exist.
# Its successor is diag_land_topology.R, which asks the same question over
# arbitrary pool structures and without rebuilding the core.
cat("=== [4] SUPERSEDED -- run calibration/diag_land_topology.R instead ===\n")
cat("  The (tau_veg, tau_soil) scan cannot be re-run: those parameters were\n")
cat("  replaced by the four-pool land on 2026-08-12. Its conclusion -- that one\n")
cat("  responsive soil pool cannot match N&L's carbon stock and their 14C\n")
cat("  inventory at once -- is what forced that restructure, and is carried in\n")
cat("  CHANGELOG.md and in diag_land_topology.R.\n")
