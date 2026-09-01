# =====================================================================
# diag_stratosphere.R -- would a stratospheric box help, and with what?
#
# WHY THIS EXISTS. After the four-pool land closed the reservoir PARTITION
# error (diag_bomb_partition.R, 2026-08-12), the only residual left in the
# bomb-14C budget was a "+6-7 % delivery error" -- the model having delivered
# more 14C by each reference year than Naegler & Levin. The obvious reading is
# that the model lacks a stratosphere to hold 14C back. This script tests that
# reading two ways, and the first test says the framing itself is wrong.
#
# [1] IS THE MODEL'S ATMOSPHERE A TROPOSPHERE OR THE WHOLE ATMOSPHERE?
#     diag_bomb_partition.R currently compares the model's atmosphere box to
#     N&L's TROPOSPHERE alone, and removes their stratosphere from their total
#     as well, on the grounds that the bomb source is a delivery RATE to the
#     troposphere so the stratospheric delay is already inside it. That
#     argument is about TIMING. It says nothing about MASS -- and the box
#     carries GtC_PER_PPM = 2.124, which is the whole atmosphere, while the
#     likelihood fits its Delta14C to surface-station observations, which are
#     tropospheric. So its excess-14C INVENTORY is whole-atmosphere mass times
#     tropospheric Delta14C, and the like-for-like target is troposphere PLUS
#     stratosphere. Scored that way the model's 14C budget CLOSES.
#
# [2] IS THE RESIDUAL A DELAY? A stratosphere inserted as a one-way residence
#     time convolves the source with an exponential. If ONE residence time
#     reconciles the delivered sum at BOTH 1975 and 1995, it is a delay error
#     and a stratospheric box fixes it. Runs on the source column alone -- no
#     model integration needed, because the delivered inventory is just the
#     source convolved with decay.
#
# Run from the repo root:  Rscript calibration/diag_stratosphere.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and column below derives from these ----
STR_YEARS      <- c(1750, 2024)
STR_REF_YEARS  <- c(1975, 1995)
STR_BOMB_TOTAL <- 102                 # kmol, as in diag_bomb_partition.R
STR_NL_SOURCE  <- "naegler_levin_2006_t4_YANG"
STR_TAU_GRID   <- c(0.5, 1.0, 1.4, 2.0, 3.0, 5.0)   # yr, candidate residence
STR_TAU_OBS    <- "~1-2"              # observed stratosphere-troposphere exchange

cat("\n=== diag_stratosphere.R ===\n")
cat("Would a stratospheric box help the bomb-14C budget, and with what?\n\n")

p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0))
sp <- ccx_spinup(p)
F_b <- ccx_build_forcing("historical", STR_YEARS, prod_c14 = sp$prod_c14,
                        bomb_total_kmol = STR_BOMB_TOTAL)
F_n <- F_b; F_n$c14_bomb <- 0; F_n$c14_nuclear <- 0
o_b <- ccx_run_fast(sp, F_b)$out
o_n <- ccx_run_fast(sp, F_n)$out
row_at <- function(y) which(floor(o_b$t + 1e-9) == y)[1]

nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nlv <- function(q, y) nl$kmol_14c[nl$source == STR_NL_SOURCE &
                                    nl$quantity == q & nl$year == y][1]

# =====================================================================
# [1] the framing
# =====================================================================
cat("=== [1] which N&L rows is the model's atmosphere box comparable to? ===\n")
cat(sprintf("  the box carries GtC_PER_PPM = %.3f GtC/ppm = the WHOLE atmosphere,\n",
            ccx_const("GtC_PER_PPM")))
cat("  and likelihood.R fits its Delta14C to obs_d14c_zonal (surface stations,\n")
cat("  i.e. TROPOSPHERIC). Its inventory is therefore whole-atmosphere mass x\n")
cat("  tropospheric Delta14C, which is comparable to troposphere + stratosphere.\n\n")

for (y in STR_REF_YEARS) {
  i <- row_at(y)
  m_atm <- ccx_c14_kmol(o_b$atm_C14[i]   - o_n$atm_C14[i])
  m_lnd <- ccx_c14_kmol(o_b$land_C14[i]  - o_n$land_C14[i])
  m_ocn <- ccx_c14_kmol(o_b$ocean_C14[i] - o_n$ocean_C14[i])
  m_sum <- m_atm + m_lnd + m_ocn
  n_tot <- nlv("total_input", y); n_str <- nlv("stratosphere", y)
  n_trp <- nlv("troposphere", y)
  rel <- function(a, b) 100 * (a / b - 1)

  cat(sprintf("  --- %d ---   model sum %.2f kmol, model input %.0f kmol\n",
              y, m_sum, STR_BOMB_TOTAL))
  cat(sprintf("   A (current)  atm vs troposphere   %6.2f vs %6.2f %+7.1f %%",
              m_atm, n_trp, rel(m_atm, n_trp)))
  cat(sprintf("   SUM vs total-strat %+6.1f %%\n", rel(m_sum, n_tot - n_str)))
  cat(sprintf("   B (proposed) atm vs trop + strat  %6.2f vs %6.2f %+7.1f %%",
              m_atm, n_trp + n_str, rel(m_atm, n_trp + n_str)))
  cat(sprintf("   SUM vs total_input %+6.1f %%\n", rel(m_sum, n_tot)))
  cat(sprintf("     biosphere %6.2f vs %6.2f %+7.1f %%   ocean %6.2f vs %6.2f %+7.1f %%\n",
              m_lnd, nlv("biosphere", y), rel(m_lnd, nlv("biosphere", y)),
              m_ocn, nlv("ocean", y), rel(m_ocn, nlv("ocean", y))))
  cat(sprintf("     the model's own input exceeds N&L's total by %+.1f %% -- the FLOOR\n",
              rel(STR_BOMB_TOTAL, n_tot)))
  cat("     on any SUM error, since the model conserves 14C but for decay\n\n")
}
cat("  READ: under B the budget CLOSES -- the SUM error collapses to the input\n")
cat("  difference. That is what a conservative model given a prescribed input MUST\n")
cat("  do, and a +6-7 % 'delivery error' was never physically sensible for one.\n")
cat("  Under B the residual is a DIFFERENT defect: the atmosphere is SHORT and the\n")
cat("  ocean is LONG -- i.e. too much bomb 14C is being taken up by the ocean.\n\n")

# =====================================================================
# [2] is the residual a delay?
# =====================================================================
cat("=== [2] can ONE stratospheric residence time reconcile both years? ===\n")
LAM <- ccx_const("LAMBDA_C14"); DT <- 1 / 12
S <- F_b$c14_bomb + F_b$c14_nuclear       # mol/yr into the troposphere
deliv <- function(x) { acc <- 0; out <- numeric(length(x))
  for (i in seq_along(x)) { acc <- acc * (1 - LAM * DT) + x[i] * DT; out[i] <- acc }
  out / 1000 }
# a one-way stratospheric reservoir of residence tau between source and troposphere
delay <- function(x, tau) { st <- 0; out <- numeric(length(x))
  for (i in seq_along(x)) { rel <- st / tau
    st <- st + (x[i] - rel - LAM * st) * DT; out[i] <- rel }
  out }
at <- function(v, y) v[row_at(y)]
tgt <- vapply(STR_REF_YEARS, function(y) nlv("total_input", y) - nlv("stratosphere", y),
              numeric(1))
cat(sprintf("  target delivered (N&L total_input - stratosphere): %.2f / %.2f kmol\n\n",
            tgt[1], tgt[2]))
cat(sprintf("  %8s %11s %11s %10s %10s %11s %11s\n", "tau_yr",
            "deliv1975", "deliv1995", "rel1975", "rel1995", "aloft1975", "aloft1995"))
d0 <- deliv(S)
for (tau in c(0, STR_TAU_GRID)) {
  dd <- if (tau == 0) d0 else deliv(delay(S, tau))
  al <- d0 - dd
  cat(sprintf("  %8.1f %11.2f %11.2f %+9.1f%% %+9.1f%% %11.2f %11.2f\n",
              tau, at(dd, 1975), at(dd, 1995),
              100 * (at(dd, 1975) / tgt[1] - 1), 100 * (at(dd, 1995) / tgt[2] - 1),
              at(al, 1975), at(al, 1995)))
}
cat(sprintf("  %8s %11.2f %11.2f %10s %10s %11.2f %11.2f  <- N&L\n", "-",
            tgt[1], tgt[2], "-", "-",
            nlv("stratosphere", 1975), nlv("stratosphere", 1995)))

s75 <- nlv("stratosphere", 1975); s95 <- nlv("stratosphere", 1995)
cat("\n  NO -- and the reason is instructive. The 1995 column barely moves at any tau,\n")
cat("  because the source is essentially over by 1980 and a one-way reservoir has\n")
cat("  emptied 15 years later. tau ~ 3 yr fixes 1975 and does nothing for 1995;\n")
cat("  tau ~ 5 yr overshoots 1975 badly and STILL does nothing for 1995.\n")
cat(sprintf("  A one-way reservoir starting at %.1f kmol in 1975 would need tau = %.0f yr\n",
            s75, -diff(STR_REF_YEARS) / log(s95 / s75)))
cat(sprintf("  to still hold %.1f kmol in 1995. Observed exchange is %s yr.\n",
            s95, STR_TAU_OBS))
cat(sprintf("  N&L's own stratosphere/troposphere ratio FALLS %.3f -> %.3f, relaxing\n",
            s75 / nlv("troposphere", 1975), s95 / nlv("troposphere", 1995)))
cat("  toward a MASS ratio. Their stratosphere is a CO-EQUILIBRATING reservoir\n")
cat("  carrying its share of the excess, not a delay line holding it back.\n\n")

cat("=== bottom line ===\n")
cat("  A stratospheric box is NOT a fix for a delivery error, because there is no\n")
cat("  delivery error to fix once [1] is settled -- the budget closes.\n")
cat("  What it WOULD buy is [1]'s residual. The model must satisfy TROPOSPHERIC\n")
cat("  Delta14C observations with a box holding WHOLE-atmosphere carbon, so during\n")
cat("  the spike -- when the real stratosphere was far more enriched than the\n")
cat("  troposphere -- it cannot hold the atmosphere's true 14C inventory, and the\n")
cat("  surplus is pushed into the ocean. Splitting the box lets the troposphere\n")
cat("  match observations while the stratosphere holds the enriched remainder.\n")
cat("  That mechanism predicts exactly [1]'s signature: atmosphere short, ocean long.\n\n")
cat("  WHAT IT WOULD NOT TOUCH: the land carbon-climate feedback (gamma_L, see\n")
cat("  diag_land_topology.R [4]); the ocean carbon inventory; and the natural 14C\n")
cat("  production ratio -- a stratosphere adds well under 1 % of total system 14C\n")
cat("  inventory, against a production shortfall of ~34 %.\n")
cat("  COST: NB 32 -> 34, and the bomb source must be REBUILT as an injection rate\n")
cat("  rather than a delivery rate, or the stratospheric delay is double-counted.\n")
