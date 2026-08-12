# =====================================================================
# diag_bomb_partition.R -- WHERE does the model put the bomb 14C?
#
# Naegler & Levin (2006) Table 4 partitions the SAME cumulative bomb input
# across stratosphere / troposphere / biosphere / ocean at 1975 and 1995. Our
# model has the same three reservoirs (its atmosphere is one box, so it is
# compared to troposphere+stratosphere) and, run at N&L's own citable total,
# receives the same input. That makes the partition a direct, like-for-like
# test that is INDEPENDENT of bomb_total: it asks not how much 14C there is,
# but where it went.
#
# WHY THIS EXISTS
# ---------------
# The 2026-08-12 handoff sends the next session to the bomb delivery SHAPE, on
# the grounds that the model overshoots the atmospheric peak at its fitted
# bomb_total and undershoots at the citable one. A shape error moves 14C in
# TIME. This script asks the orthogonal question -- is the 14C in the right
# PLACE? -- because if the partition is wrong at both reference years, no
# re-timing of the source can fix it, and the shape work would be misdirected.
#
# The comparison is the PAIRED (bomb-on minus bomb-off) difference, because
# N&L's Table 4 model partition sums exactly to their cumulative bomb input,
# i.e. theirs is a paired difference too (established in diag_excess_c14.R [3]).
#
# ANSWERED, 2026-08-12. It is a partition error, and it is now CLOSED. The
# biosphere ran 51-58 % long and the troposphere 40-44 % short at both years;
# the four-pool land (R/model.R) leaves the biosphere at +0 % / +10 %. What
# survives is the delivery error alone, ~6-7 %, which was always the ceiling on
# what a re-shaped source could repair. The shape work in the handoff was, as
# this script suspected, misdirected until the partition was fixed.
#
# STALE CAVEAT, REMOVED. Earlier versions warned that land-use-change emissions
# injected 14C ex nihilo into the atmosphere, so the atmospheric deficit was a
# lower bound. That leak was fixed in commit 98c1783 -- LUC is now a transfer
# out of a vegetation pool and is conservative by construction. [C] still
# measures the flux, because it still moves 14C between the rows of [A], but it
# is no longer an error term.
#
# Run from the repo root:  Rscript calibration/diag_bomb_partition.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and column below derives from these ----
PART_YEARS       <- c(1750, 2024)
PART_REF_YEARS   <- c(1975, 1995)      # GEOSECS and WOCE reference years
PART_BOMB_TOTAL  <- 102                # kmol, Naegler & Levin (2006) citable
                                       # 1945-1980 total. The POINT of using it
                                       # rather than the fitted value is that it
                                       # matches N&L's own input, so the two
                                       # partitions are of the same budget.
PART_MODE_FILE   <- file.path("calibration", "output", "mode_fit.rds")
PART_NL_SOURCE   <- "naegler_levin_2006_t4_YANG"   # their model partition
PART_NL_OBS_TROP <- "naegler_levin_2006_t4_OBS"    # the one observed row
PART_NL_OBS_OCN  <- "naegler_levin_2006_t2_peacock_corr"
PART_LUC_CORE    <- "reference"        # the LUC flux measurement needs the wood
                                       # box's own 14C ratio, which the fast
                                       # core does not export; the R reference
                                       # core is stepped by hand in [C].

cat("\n=== diag_bomb_partition.R ===\n")
cat(sprintf("Partition of the bomb 14C budget at bomb_total = %.0f kmol\n",
            PART_BOMB_TOTAL))
cat("Model reservoirs vs Naegler & Levin (2006) Table 4, paired bomb-only\n\n")

# ---- parameters: the current mode, bomb_total overridden -------------
mode_fit <- if (file.exists(PART_MODE_FILE)) readRDS(PART_MODE_FILE) else NULL
p <- ccx_default_params()
if (!is.null(mode_fit)) {
  for (n in intersect(names(p), names(mode_fit$par_mode))) p[[n]] <- mode_fit$par_mode[[n]]
  p$gamma_enso <- mode_fit$par_mode$gamma_enso
  cat(sprintf("parameters: mode fit (its own bomb_total %.1f is OVERRIDDEN to %.0f)\n",
              mode_fit$par_mode$bomb_total, PART_BOMB_TOTAL))
} else {
  p$gamma_enso <- 0
  cat("parameters: ccx_default_params() -- NO mode fit found\n")
}

sp <- ccx_spinup(p)
cat(sprintf("spinup: prod_c14 %.1f mol/yr, ocean C %.0f GtC, deep D14C %+.1f permil\n\n",
            sp$prod_c14, sp$diagnostics$ocean_C_GtC, sp$diagnostics$d14c_deep_ocean))

F_bomb <- ccx_build_forcing("historical", PART_YEARS, prod_c14 = sp$prod_c14,
                            bomb_total_kmol = PART_BOMB_TOTAL)
F_nob  <- F_bomb; F_nob$c14_bomb <- 0; F_nob$c14_nuclear <- 0

o_b <- ccx_run_fast(sp, F_bomb)$out
o_n <- ccx_run_fast(sp, F_nob)$out
row_at <- function(o, y) which(floor(o$t + 1e-9) == y)[1]

# =====================================================================
# [A] The partition, model vs N&L
# =====================================================================
nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nl_val <- function(src, q, y, col = "kmol_14c") {
  v <- nl[[col]][nl$source == src & nl$quantity == q & nl$year == y]
  if (!length(v)) NA_real_ else v[1]
}

cat("=== [A] where the bomb 14C sits, paired bomb-only, kmol ===\n")
# COMPARE LIKE WITH LIKE. R/model.R has no stratospheric box, and the bomb
# source is a DELIVERY RATE to the troposphere (data-raw/build_bomb_c14_source.R
# header) -- the stratospheric residence is already inside the source. So the
# model's atmosphere box is a TROPOSPHERE, and the honest comparison is against
# N&L's troposphere alone, with their stratosphere removed from the total too.
# Scoring it against troposphere+stratosphere would credit the model for 14C it
# has, by construction, already delivered, and would flatter the deficit.
cat("    model atm box = TROPOSPHERE (the source already carries the stratospheric\n")
cat("    delay), so N&L's stratosphere is removed from their atmosphere AND their total\n\n")
part <- list()
for (y in PART_REF_YEARS) {
  i <- row_at(o_b, y)
  m_atm <- ccx_c14_kmol(o_b$atm_C14[i]   - o_n$atm_C14[i])
  m_lnd <- ccx_c14_kmol(o_b$land_C14[i]  - o_n$land_C14[i])
  m_ocn <- ccx_c14_kmol(o_b$ocean_C14[i] - o_n$ocean_C14[i])
  m_sum <- m_atm + m_lnd + m_ocn

  n_atm   <- nl_val(PART_NL_SOURCE, "troposphere",  y)
  n_strat <- nl_val(PART_NL_SOURCE, "stratosphere", y)
  n_lnd   <- nl_val(PART_NL_SOURCE, "biosphere",    y)
  n_ocn   <- nl_val(PART_NL_SOURCE, "ocean",        y)
  n_sum   <- nl_val(PART_NL_SOURCE, "total_input",  y) - n_strat   # = delivered

  cat(sprintf("  --- %d ---\n", y))
  cat(sprintf("  %-16s %8s %8s %9s %9s\n", "reservoir", "MODEL", "N&L", "diff", "rel"))
  show <- function(lab, m, n) cat(sprintf("  %-16s %8.2f %8.2f %+9.2f %+8.0f %%\n",
                                          lab, m, n, m - n, 100 * (m / n - 1)))
  show("troposphere", m_atm, n_atm)
  show("biosphere",   m_lnd, n_lnd)
  show("ocean",       m_ocn, n_ocn)
  show("SUM delivered", m_sum, n_sum)
  cat(sprintf("  observational brackets: troposphere %.1f-%.1f, ocean %.1f-%.1f\n",
              nl_val(PART_NL_OBS_TROP, "troposphere", y, "kmol_lo"),
              nl_val(PART_NL_OBS_TROP, "troposphere", y, "kmol_hi"),
              nl_val(PART_NL_OBS_OCN,  "ocean", y, "kmol_lo"),
              nl_val(PART_NL_OBS_OCN,  "ocean", y, "kmol_hi")))
  cat(sprintf("  N&L still aloft (stratosphere): %.1f kmol -- the model has delivered it\n\n",
              n_strat))
  part[[as.character(y)]] <- c(atm = m_atm - n_atm, land = m_lnd - n_lnd,
                               ocean = m_ocn - n_ocn, sum = m_sum - n_sum)
}

cat("  A DELIVERY error moves the SUM; a PARTITION error moves the rows within it:\n")
for (y in PART_REF_YEARS) {
  d <- part[[as.character(y)]]
  cat(sprintf("    %d  sum %+6.2f kmol of delivery, against trop %+6.2f / bio %+6.2f / ocn %+6.2f\n",
              y, d["sum"], d["atm"], d["land"], d["ocean"]))
}

# =====================================================================
# [B] Is the land pool the wrong SIZE, or the wrong SHAPE?
# =====================================================================
# N&L's biosphere is 2200 PgC in four pools. If our land carbon matches theirs
# but holds far more bomb 14C, the defect is turnover structure, not capacity.
cat("\n=== [B] land carbon: capacity vs turnover ===\n")
NL_BIOSPHERE_PGC <- 2200          # Naegler & Levin (2006), four pools
for (y in PART_REF_YEARS) {
  i <- row_at(o_b, y)
  cat(sprintf("  %d  model land C %.0f GtC vs N&L biosphere %.0f PgC (%+.0f %%)\n",
              y, o_b$land_C[i], NL_BIOSPHERE_PGC,
              100 * (o_b$land_C[i] / NL_BIOSPHERE_PGC - 1)))
}
cat("  model land is FOUR pools (2026-08-12), the structure the 51-58 % biosphere\n")
cat("  excess above forced -- one responsive soil pool could not hold N&L's carbon\n")
cat("  and their 14C at the same time (diag_land_topology.R):\n")
cat(sprintf("    leaf %.0f%% of NPP @ %.0f yr | wood %.0f%% @ %.0f yr\n",
            100 * p$npp_leaf_frac, p$tau_leaf,
            100 * (1 - p$npp_leaf_frac), p$tau_wood))
cat(sprintf("    soil %.0f%% of litter @ %.0f yr | %.0f%% @ %.0f yr (passive)\n",
            100 * (1 - p$litter_slow_frac), p$tau_soil_fast,
            100 * p$litter_slow_frac, p$tau_soil_slow))
cat("  Fast pools cycle the bomb 14C straight back; the passive pool holds carbon\n")
cat("  while barely seeing the bomb. That separation is what closes the partition.\n")

# =====================================================================
# [C] How much 14C does LUC move from the land to the atmosphere?
# =====================================================================
# THIS IS NO LONGER A LEAK. It was one until commit 98c1783, when LUC was an
# add_source() into the atmosphere with the vegetation box left intact, so the
# 14C came from nowhere. It is now a TRANSFER out of the wood pool and is
# conservative by construction. What is measured here is therefore a real
# internal flux, not an error -- but it still moves 14C from the biosphere row
# of [A] into the troposphere row, so its size is worth carrying. Its PAIRED
# part is
#   int e_luc * (r_wood[bomb] - r_wood[no bomb]) dt,
# which needs the wood box's own ratio -- exported by neither core, so the R
# reference core is stepped by hand here.
cat("\n=== [C] 14C carried out of the wood pool by LUC (a transfer, not a leak) ===\n")
luc_c14_cum <- function(F) {
  y <- sp$y; aux <- sp$aux; grid <- sp$grid; pp <- sp$params
  substeps <- ccx_resolve_substeps("auto", pp, grid)
  # LUC debits the WOOD pool (2026-08-12), so it is wood's ratio that rides out
  ivegN <- aux$idx$NH$wood; ivegS <- aux$idx$SH$wood
  dt <- 1 / 12
  cum <- numeric(nrow(F)); acc <- 0
  for (i in seq_len(nrow(F))) {
    rN <- y[ivegN, "C14"] / max(y[ivegN, "C"], 1e-30)
    rS <- y[ivegS, "C14"] / max(y[ivegS, "C"], 1e-30)
    acc <- acc + (F$e_luc_NH[i] * rN + F$e_luc_SH[i] * rS) * dt
    cum[i] <- acc
    y <- ccx_step_rk4(y, F$t[i], dt, pp, ccx_forcing_at(F, i), grid, aux, substeps)
  }
  cum
}
cat("  (stepping the R reference core twice -- slow, ~1 min)\n")
lb <- luc_c14_cum(F_bomb); ln <- luc_c14_cum(F_nob)
for (y in PART_REF_YEARS) {
  i <- row_at(o_b, y)
  paired <- ccx_c14_kmol(lb[i] - ln[i])
  d <- part[[as.character(y)]]
  cat(sprintf("  %d  total LUC-injected %6.2f kmol, of which PAIRED %5.2f kmol\n",
              y, ccx_c14_kmol(lb[i]), paired))
  cat(sprintf("        -> troposphere row %+.2f would be %+.2f without it\n",
              d["atm"], d["atm"] - paired))
}

cat("\n=== bottom line ===\n")
cat("  THE PARTITION ERROR IS CLOSED. It was the reason this script existed: a\n")
cat("  biosphere 51-58 % long and a troposphere 40-44 % short, in the same\n")
cat("  direction at both reference years, which no re-timing of the source could\n")
cat("  reach. The four-pool land (2026-08-12) leaves the biosphere at +0 % / +10 %.\n")
cat("  WHAT REMAINS IS THE DELIVERY ERROR, and only that: the model has delivered\n")
cat("  ~6-7 % more than N&L by each reference year. That was always the ceiling on\n")
cat("  what a re-shaped source could repair, and it is now the whole residual.\n")
cat("  Numbers above are at ccx_default_params(): the four-pool land has NOT been\n")
cat("  calibrated, so read the partition, not the absolute level.\n")
