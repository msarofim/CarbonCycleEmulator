# =====================================================================
# diag_o6_bomb_partition_hilda30c.R -- O6: WHERE does the canonical put the
# bomb 14C, and is the ocean overshoot the INPUT or the PARTITION?
#
# WHY (2026-09-15 e/f). The O1 probe found the 1995 ocean bomb inventory at
# z ~ +4 in EVERY configuration including the canonical (81.4 vs 51.4 +- 10.8
# kmol). A criterion that fails in the control is a property of the objective,
# not of any candidate. Two things could produce it: (i) the fitted bomb_total
# (118.4 kmol) is ABOVE the citable production (N&L 2006: 99.3-104.9), so
# every reservoir is over by the same factor; (ii) the PARTITION puts too large
# a share into the ocean -- the land (or the atmosphere) holds too little.
# Only (ii) is a structural finding. The 08-12 read (diag_bomb_partition.R)
# closed the land share at +0/+10 % on the four-pool build; the model has
# changed since (HILDA boxes, periodic spinup, seasonal ML, LUC debit). This
# re-reads it at the canonical, on the dg machinery, at N&L's own total.
#
# ⚠ TWO FRAMINGS, and the 08-12 choice was made on a test with no power.
# diag_excess_c14.R [3] inferred that N&L's model partition is a PAIRED
# (bomb-on minus bomb-off) difference because its rows "sum exactly to the
# cumulative bomb input". Both framings do: total-minus-pre-bomb also sums to
# input minus decay, because natural production balances natural decay and the
# Suess redistribution only moves atoms BETWEEN rows (measured below: the two
# sums agree to 0.03 kmol). The sum test cannot tell them apart. What the
# source says: Naegler (2009, Tellus B 61:372, doi:10.1111/j.1600-0889.2008.
# 00408.x, open access, read 2026-09-15) eq. (1) defines EXCESS radiocarbon for
# every quantity as Q_E(t) = Q(t) - Q_PB with PB = the 1940-1949 mean, and
# states that "the excess radiocarbon inventory defined in that manner
# corresponds to the 'bomb' radiocarbon as used in most previous studies"; the
# Peacock (2004) / Key (2004) ocean inventories are defined the same way, and
# the observed troposphere row in N&L's Table 4 can only be total-minus-
# pre-bomb (a paired difference is not observable). So the PRIMARY comparison
# here is TOTAL-minus-1940s, per reservoir, the paired difference is printed as
# the secondary framing, and the two are reported side by side because the
# Suess redistribution (land -> atmosphere in the no-bomb world) moves ~11 kmol
# between the atmosphere and land rows and ~1 kmol on the ocean row. The ocean
# verdict is framing-independent; the land verdict is NOT.
#
# N&L 2006's own Table 4 (JGR 111 D12311) is paywalled here; the framing of its
# MODEL rows is inferred from the 2009 definition, not read. Recorded as such.
#
# Framing C (diag_bomb_partition.R, 2026-08-12): the model's one atmosphere box
# is WHOLE-atmosphere mass at a TROPOSPHERIC ratio, so N&L's troposphere is
# scaled by the GRACE strat/trop mass ratio. Nuclear-industry 14C is in every
# run (both framings isolate the bomb: the paired pair shares it; the 1940s
# reference predates it, and it is 0.09 kmol by 1995).
#
# Linearity check: 14C is a passive tracer on a carbon state the bomb does not
# move, so the paired excess must scale exactly with bomb_total; the fitted
# 118.4 row is printed as a check on that, not as a second finding.
#
# Run from the repo root:  Rscript calibration/diag_o6_bomb_partition_hilda30c.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
O6_COMMIT <- ccx_git_stamp()
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

O6_ARM        <- "hilda30c"
O6_REF_YEARS  <- c(1975L, 1995L)
O6_PB_YEARS   <- 1940:1949                # Naegler 2009 eq. (1): the pre-bomb reference is the 1940s mean
O6_NL_TOTAL   <- 102                      # kmol; N&L 2006 citable 1945-1980 production
O6_NL_MODEL   <- "naegler_levin_2006_t4_YANG"
O6_NL_OBS_TR  <- "naegler_levin_2006_t4_OBS"
O6_NL_OBS_OC  <- "naegler_levin_2006_t4_OBS"   # Peacock + Key, area-corrected (the objective's own row)
# framing C constants, identical to diag_bomb_partition.R (2026-08-12)
O6_TROPOPAUSE_LAT <- 30; O6_TROPOPAUSE_HPA <- c(extratropical = 308.0, tropical = 121.1); O6_SURFACE_HPA <- 1013.25
o6_a <- sin(O6_TROPOPAUSE_LAT * pi / 180)
O6_F_TROP <- (1 - o6_a) * (1 - O6_TROPOPAUSE_HPA[["extratropical"]] / O6_SURFACE_HPA) + o6_a * (1 - O6_TROPOPAUSE_HPA[["tropical"]] / O6_SURFACE_HPA)
O6_STRAT_TROP_MASS <- (1 - O6_F_TROP) / O6_F_TROP
O6_OUT <- ccx_path("outputs", "diagnostics", sprintf("o6_bomb_partition_%s_%s", O6_ARM, format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(O6_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== O6 bomb-14C partition at %s -- commit %s ==\n", O6_ARM, O6_COMMIT))

v0 <- dg_vector(O6_ARM)
cat(sprintf("mode %s: fitted bomb_total %.2f kmol (N&L citable %.0f; prior bracket 99.3-104.9); migrated: %s\n",
            O6_ARM, v0$bomb_total, O6_NL_TOTAL, if (length(v0$migrated)) paste(v0$migrated, collapse = ",") else "none"))
nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nl_val <- function(src, q, y, col = "kmol_14c") { v <- nl[[col]][nl$source == src & nl$quantity == q & nl$year == y]; if (!length(v)) NA_real_ else v[1] }

# one spinup (bomb-independent), three forcings: off / N&L total / fitted total
sp <- dg_spinup(v0)
build_F <- function(bt) withCallingHandlers(
  ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = bt, luc_scale = v0$luc_scale),
  warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
F_on  <- build_F(O6_NL_TOTAL); F_fit <- build_F(v0$bomb_total)
F_off <- F_on; F_off$c14_bomb <- 0                # nuclear stays in both: the pair isolates the BOMB
stopifnot(max(abs(F_off$c14_nuclear - F_on$c14_nuclear)) == 0)
run <- function(F) ccx_run_fast(sp, F)$out
o_off <- run(F_off); o_on <- run(F_on); o_fit <- run(F_fit)
yr <- floor(o_on$t + 1e-9)
inv <- function(o, i) c(atm = ccx_c14_kmol(mean(o$atm_C14[i])), land = ccx_c14_kmol(mean(o$land_C14[i])), ocean = ccx_c14_kmol(mean(o$ocean_C14[i])))
excess <- function(o_b, o_0, y) inv(o_b, yr == y) - inv(o_0, yr == y)          # PAIRED: bomb-on minus bomb-off, annual mean of y
excess_pb <- function(o_b, y) inv(o_b, yr == y) - inv(o_b, yr %in% O6_PB_YEARS) # TOTAL-minus-1940s: Naegler 2009 eq. (1)
pb_on <- inv(o_on, yr %in% O6_PB_YEARS); pb_off <- inv(o_off, yr %in% O6_PB_YEARS)
cat(sprintf("1940s reference (kmol): atm %.2f land %.2f ocean %.2f; bomb already in it by then %.2f kmol (on - off), as in N&L's own reference\n",
            pb_on[["atm"]], pb_on[["land"]], pb_on[["ocean"]], sum(pb_on - pb_off)))
cat(sprintf("framing C: N&L troposphere x (1 + strat/trop mass %.4f); troposphere = %.1f %% of atmospheric mass\n\n", O6_STRAT_TROP_MASS, 100 * O6_F_TROP))
res <- list()
for (y in O6_REF_YEARS) {
  mp <- excess(o_on, o_off, y); mpf <- excess(o_fit, o_off, y)      # paired (secondary)
  m  <- excess_pb(o_on, y);     mf  <- excess_pb(o_fit, y)          # total-minus-1940s (PRIMARY)
  n_trop <- nl_val(O6_NL_MODEL, "troposphere", y); n_strat <- nl_val(O6_NL_MODEL, "stratosphere", y)
  n_lnd <- nl_val(O6_NL_MODEL, "biosphere", y); n_ocn <- nl_val(O6_NL_MODEL, "ocean", y); n_tot <- nl_val(O6_NL_MODEL, "total_input", y)
  n_atm <- n_trop * (1 + O6_STRAT_TROP_MASS); n_sum <- n_tot - (n_strat - n_trop * O6_STRAT_TROP_MASS)
  n <- c(atm = n_atm, land = n_lnd, ocean = n_ocn); msum <- sum(m); nsum <- n_sum
  cat(sprintf("--- %d --- excess 14C, kmol, at bomb_total %.0f (N&L's input); PRIMARY = total minus the 1940s, secondary = paired\n", y, O6_NL_TOTAL))
  cat(sprintf("  %-11s %8s %8s %8s %7s   %8s %8s  | %8s %8s %7s\n", "reservoir", "MODEL", "N&L", "diff", "rel", "share_M", "share_NL", "paired", "diff", "rel"))
  for (k in names(m)) cat(sprintf("  %-11s %8.2f %8.2f %+8.2f %+6.0f %%   %7.1f %% %7.1f %%  | %8.2f %+8.2f %+6.0f %%\n", k, m[[k]], n[[k]], m[[k]] - n[[k]], 100 * (m[[k]] / n[[k]] - 1), 100 * m[[k]] / msum, 100 * n[[k]] / nsum,
                                  mp[[k]], mp[[k]] - n[[k]], 100 * (mp[[k]] / n[[k]] - 1)))
  cat(sprintf("  %-11s %8.2f %8.2f %+8.2f %+6.0f %%                       | %8.2f   (the two framings' sums agree to %.2f kmol: the sum test has no power)\n", "SUM", msum, nsum, msum - nsum, 100 * (msum / nsum - 1), sum(mp), abs(msum - sum(mp))))
  cat(sprintf("  observed brackets: troposphere %.1f-%.1f (x%.4f whole-atm -> %.1f-%.1f); ocean %.1f-%.1f\n",
              nl_val(O6_NL_OBS_TR, "troposphere", y, "kmol_lo"), nl_val(O6_NL_OBS_TR, "troposphere", y, "kmol_hi"), 1 + O6_STRAT_TROP_MASS,
              nl_val(O6_NL_OBS_TR, "troposphere", y, "kmol_lo") * (1 + O6_STRAT_TROP_MASS), nl_val(O6_NL_OBS_TR, "troposphere", y, "kmol_hi") * (1 + O6_STRAT_TROP_MASS),
              nl_val(O6_NL_OBS_OC, "ocean", y, "kmol_lo"), nl_val(O6_NL_OBS_OC, "ocean", y, "kmol_hi")))
  cat(sprintf("  at the FITTED bomb_total %.2f: atm %.2f land %.2f ocean %.2f  [paired %.2f / %.2f / %.2f = x%.4f / x%.4f / x%.4f of the %.0f-kmol paired row; input ratio %.4f]\n\n",
              v0$bomb_total, mf[["atm"]], mf[["land"]], mf[["ocean"]], mpf[["atm"]], mpf[["land"]], mpf[["ocean"]],
              mpf[["atm"]] / mp[["atm"]], mpf[["land"]] / mp[["land"]], mpf[["ocean"]] / mp[["ocean"]], O6_NL_TOTAL, v0$bomb_total / O6_NL_TOTAL))
  res[[as.character(y)]] <- list(model = m, model_paired = mp, nl = n, model_fit = mf, model_fit_paired = mpf, sum_model = msum, sum_nl = nsum)
}
# the decomposition of the 1995 ocean overshoot: input factor vs partition factor
m95 <- res[["1995"]]; oc_obs <- ccx_prepare_obs()$excess_c14
i95 <- which(oc_obs$year == 1995)
cat("== the 1995 ocean overshoot, decomposed ==\n")
cat(sprintf("  objective row: %.1f +- %.1f kmol (Peacock + Key, area-corrected; Naegler 2009 says these NEGLECT the net-CO2-uptake component, +8 %% at 1995 -- not applied here); canonical (total minus 1940s) %.1f (z %+.1f)\n", oc_obs$centre[i95], oc_obs$half_width[i95], m95$model_fit[["ocean"]], (m95$model_fit[["ocean"]] - oc_obs$centre[i95]) / oc_obs$half_width[i95]))
cat(sprintf("  = N&L's ocean %.1f  x input (%.2f/%.0f = %.3f)  x partition (%.3f: model ocean share %.1f %% vs N&L %.1f %%)  [x the SUM residual %.3f]\n",
            m95$nl[["ocean"]], v0$bomb_total, O6_NL_TOTAL, v0$bomb_total / O6_NL_TOTAL,
            (m95$model[["ocean"]] / m95$sum_model) / (m95$nl[["ocean"]] / m95$sum_nl), 100 * m95$model[["ocean"]] / m95$sum_model, 100 * m95$nl[["ocean"]] / m95$sum_nl,
            m95$sum_model / m95$sum_nl))
cat(sprintf("  at N&L's input AND N&L's partition the ocean would be %.1f (z %+.1f); at N&L's input with the MODEL's partition %.1f (z %+.1f)\n",
            m95$nl[["ocean"]], (m95$nl[["ocean"]] - oc_obs$centre[i95]) / oc_obs$half_width[i95],
            m95$model[["ocean"]], (m95$model[["ocean"]] - oc_obs$centre[i95]) / oc_obs$half_width[i95]))
saveRDS(list(arm = O6_ARM, bomb_total_fit = v0$bomb_total, nl_total = O6_NL_TOTAL, res = res, strat_trop_mass = O6_STRAT_TROP_MASS,
             commit = O6_COMMIT), paste0(O6_OUT, ".rds"))
cat(sprintf("\nwritten %s.{log,rds}\n", O6_OUT))
