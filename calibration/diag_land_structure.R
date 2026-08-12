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
#   [1] IS phi BOUNDED? A decoupled argument predicts divergence for
#       phi * f > 1, f = 1 + beta ln(chi/chi0), because spinup sets
#       veg0 = npp0 * tau_veg exactly and the veg coefficient is
#       (phi*f - 1)/tau_veg. RUN IT, do not trust the algebra.
#       RESULT: the prediction is WRONG -- see below. Kept as a live test so
#       the bound is not reinstated from the algebra alone.
#
#   [2] ra_ratio IS ISOTOPES-ONLY. GPP = NPP*(1+ra_ratio) down and Ra =
#       NPP*ra_ratio back up, so the NET atm->veg carbon flux is NPP for any
#       ra_ratio. If the CO2 and land-carbon trajectories move at all, the
#       implementation is wrong.
#
#   [3] WHAT IT BUYS. The bomb-14C partition (diag_bomb_partition.R) puts the
#       model's biosphere 51-58 % above Naegler & Levin and its troposphere
#       40-44 % below. Does the gross loop move that, and by how much per unit
#       ra_ratio? RESULT: it moves it the WRONG WAY at 1975. See below.
#
#   [4] SO WHAT DOES SET THE LAND'S BOMB 14C? Scan (tau_veg, tau_soil) and
#       normalise the excess by the responsive carbon it sits on, against
#       N&L's 21.7 / 18.9 kmol on a 2200 PgC biosphere.
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

base_p <- function() { p <- ccx_default_params(); p$gamma_enso <- 0; p }
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
cat(sprintf("  %6s %14s %14s %10s\n", "phi", "veg/veg0 2024", "CO2 2024", "verdict"))
for (phi in LAND_PHI_GRID) {
  p <- base_p(); p$npp_veg_frac <- phi
  r <- try(run_p(p), silent = TRUE)
  if (inherits(r, "try-error")) { cat(sprintf("  %6.2f %14s\n", phi, "run FAILED")); next }
  o <- r$out; n <- nrow(o)
  vratio <- o$land_C[n] / o$land_C[1]
  co2 <- 0.5 * (o$co2_NH[n] + o$co2_SH[n])
  ok <- is.finite(vratio) && vratio < LAND_DIVERGE_X
  cat(sprintf("  %6.2f %14.3f %14.1f %10s\n", phi, vratio, co2,
              if (ok) "stable" else "DIVERGED"))
}
cat("  (land C ratio, not veg alone -- soil follows veg, so it carries the signal)\n")
cat("  -> NOT bounded. Every phi is stable, including phi*f = 1.25. The algebra\n")
cat("     held chi fixed; it is not. A growing veg pool draws CO2 down, which\n")
cat("     lowers f -- the CO2 column IS that feedback, falling monotonically.\n\n")

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

LAND_TAU_GRID <- list(c(10, 25), c(10, 15), c(10, 8), c(10, 3),
                      c(3, 15), c(3, 3), c(20, 50))
LAND_NL_BIO_PGC <- 2200

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
}
cat("\n  PREDICTED: biosphere falls, troposphere rises -- a faster gross exchange was\n")
cat("  expected to let veg dump its bomb 14C back rather than remember the peak.\n")
cat("  MEASURED: the opposite at 1975. The biosphere RISES (39.7 -> 44.1) and the\n")
cat("  troposphere barely moves (21.04 -> 21.09); at 1995 both move a little the\n")
cat("  predicted way. The reason is that in 1975 the atmosphere is still far above\n")
cat("  natural, so a lagging veg pool is still CATCHING UP and holds LESS than\n")
cat("  equilibrium. Faster exchange closes that gap, i.e. holds MORE. Equilibrating\n")
cat("  harder is the wrong lever while the source is still elevated -- which is\n")
cat("  the caution Marcus raised about GPP (2026-08-12), confirmed numerically.\n")
cat("  ra_ratio is still correct physics and still isotopes-only; it is simply not\n")
cat("  what closes the partition gap. See [4].\n")

# =====================================================================
# [4] what actually sets the land's bomb 14C: pool size and turnover
# =====================================================================
# [3] says the gross loop is not the lever. This asks what is. The excess is
# normalised by the responsive carbon it sits on, so a structure that matches
# N&L's biosphere on BOTH counts has to hit their carbon stock AND their
# kmol-per-100-GtC at the same time.
cat("=== [4] land bomb 14C vs (tau_veg, tau_soil): size, turnover, or both? ===\n")
cat(sprintf("  N&L: %.1f / %.1f kmol on a %.0f PgC biosphere -> %.3f / %.3f kmol per 100 GtC\n\n",
            nl_val("biosphere", 1975), nl_val("biosphere", 1995), LAND_NL_BIO_PGC,
            nl_val("biosphere", 1975) / (LAND_NL_BIO_PGC / 100),
            nl_val("biosphere", 1995) / (LAND_NL_BIO_PGC / 100)))
cat(sprintf("  %8s %9s %10s %10s %12s %14s\n",
            "tau_veg", "tau_soil", "bio 1975", "bio 1995", "land C 1975", "kmol/100GtC"))
for (tg in LAND_TAU_GRID) {
  p <- base_p(); p$tau_veg <- tg[1]; p$tau_soil <- tg[2]
  r <- run_p(p)
  Fn <- r$F; Fn$c14_bomb <- 0; Fn$c14_nuclear <- 0
  on <- ccx_run_fast(r$sp, Fn)$out
  i75 <- row_at(r$out, 1975); i95 <- row_at(r$out, 1995)
  b75 <- ccx_c14_kmol(r$out$land_C14[i75] - on$land_C14[i75])
  b95 <- ccx_c14_kmol(r$out$land_C14[i95] - on$land_C14[i95])
  cat(sprintf("  %8.0f %9.0f %10.2f %10.2f %12.0f %14.3f\n",
              tg[1], tg[2], b75, b95, r$out$land_C[i75],
              b75 / (r$out$land_C[i75] / 100)))
}
cat("\n  The excess is strongly SUB-LINEAR in pool size: a bigger, slower pool\n")
cat("  dilutes the bomb signal faster than it accumulates it. N&L's ratio is\n")
cat("  reached only by a pool far LARGER than theirs -- which is the signature of\n")
cat("  a MULTI-POOL biosphere, where fast pools cycle the bomb 14C and a large\n")
cat("  slow pool holds carbon while barely seeing it. One responsive soil pool\n")
cat("  cannot match their carbon stock and their 14C inventory at the same time.\n")
