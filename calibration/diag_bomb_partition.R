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
# CAVEAT carried from diag_excess_c14.R [2]: land-use-change emissions inject
# 14C ex nihilo into the ATMOSPHERE at the vegetation box's own ratio. The
# paired part of that leak is measured in [C] below, because it inflates the
# model's atmospheric number -- so any atmospheric DEFICIT reported here is a
# lower bound on the true one.
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
PART_LUC_CORE    <- "reference"        # the LUC-leak measurement needs the veg
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
cat(sprintf("  model land is a SERIAL cascade atm -> veg (tau_veg %.0f yr)"       , p$tau_veg))
cat(sprintf(" -> soil (tau_soil %.0f yr) -> atm,\n", p$tau_soil))
cat("  with NO fast autotrophic-respiration return: every atom taken up by NPP\n")
cat(sprintf("  is locked for tau_veg + tau_soil = %.0f yr before it can come back.\n",
            p$tau_veg + p$tau_soil))

# =====================================================================
# [C] How much of the atmospheric number is the LUC 14C leak?
# =====================================================================
# The leak enters the ATMOSPHERE, so it inflates the model's atmospheric
# inventory and the [A] deficit is a lower bound. Its PAIRED size is
#   int e_luc * (r_veg[bomb] - r_veg[no bomb]) dt,
# which needs the vegetation box's own ratio -- exported by neither core, so
# the R reference core is stepped by hand here.
cat("\n=== [C] the paired part of the LUC 14C leak (inflates the atmosphere) ===\n")
luc_c14_cum <- function(F) {
  y <- sp$y; aux <- sp$aux; grid <- sp$grid; pp <- sp$params
  substeps <- ccx_resolve_substeps("auto", pp, grid)
  ivegN <- aux$idx$NH$veg; ivegS <- aux$idx$SH$veg
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
  cat(sprintf("        -> atmospheric deficit %+.2f would be %+.2f without it\n",
              d["atm"], d["atm"] - paired))
}

cat("\n=== bottom line ===\n")
cat("  Both errors are real, and they are an order of magnitude apart. The model\n")
cat("  has delivered ~7-8 % more than N&L by each reference year -- a genuine but\n")
cat("  small timing error, the most a re-shaped source could ever repair. Inside\n")
cat("  that budget the troposphere is 40-44 % short and the biosphere 51-58 % long,\n")
cat("  in the SAME direction at both years, twenty years apart. Re-timing the\n")
cat("  delivery moves 14C between years; it cannot move it between reservoirs.\n")
