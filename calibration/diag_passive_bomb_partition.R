# =====================================================================
# diag_passive_bomb_partition.R -- DOES THE PASSIVE POOL'S AGE (or a CARVE-OUT)
# MOVE THE BOMB-14C PARTITION? (CHANGELOG 09-29 v, measurement A; Marcus
# 2026-09-29: "run all the cheap measurements")
#
# Along the fixed-stock tau profile the older passive pool gains d14c_NH /
# d14c_intcal ~+5 each. The O6 read (09-15 f, hilda31 era) put the land's bomb
# share at -17 % of N&L's model. At fixed stock an older pool takes LESS litter,
# so its bomb uptake could fall. This reads, for each profile row's REBALANCED
# vector, the excess 14C per reservoir (atm / land / ocean) in 1975 and 1995.
#
# FRAMING (as diag_o6_bomb_partition_hilda30c.R, which cites Naegler 2009 eq. 1):
# PRIMARY = total minus the 1940-49 mean; secondary = paired (bomb-on minus
# bomb-off). Atmosphere in framing C (whole-atmosphere box at a tropospheric
# ratio; N&L troposphere x (1 + strat/trop mass)).
# ⚠ YARDSTICKS: the LAND row of N&L 2006 Table 4 is THEIR MODEL -- the data file
# says "NO observational estimate exists". Only the TROPOSPHERE (N&L OBS) and
# the OCEAN (Peacock + Key, the objective's own row) are observations. The land
# comparison is model-vs-model and is labeled so.
# Rows are read at N&L's citable input (BP_NL_TOTAL, so the partition is
# compared at a common input) and at each row's FITTED bomb_total.
# GATE (physical law): 14C is a passive tracer on a carbon state the bomb does
# not move, so the PAIRED excess must scale exactly with bomb_total. The ratio
# (fitted / N&L) of every paired reservoir must equal the input ratio to
# BP_LIN_TOL (relative).
# Env BP_PROFILES: comma-separated profile tags (default: the fixed-stock
# profile); every row of each is read.
# No RNG. USAGE: Rscript calibration/diag_passive_bomb_partition.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
BP_DRIVER <- "calibration/diag_passive_bomb_partition.R"
BP_TAG    <- "passive_bomb_partition"
BP_DATE   <- format(Sys.Date(), "%Y%m%d")
BP_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
BP_STRUCT <- "hilda_csl3v0ka"
BP_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
BP_PROFILES <- strsplit(Sys.getenv("BP_PROFILES", "tau_soil_slow_profile_fixedstock_20260929"), ",")[[1]]
BP_FREE   <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
BP_SPAN   <- c(1750L, 2001L)
BP_YEARS  <- c(1975L, 1995L)
BP_PB     <- 1940:1949                       # Naegler 2009 eq. (1)
BP_NL_TOTAL <- 102                           # kmol; N&L 2006 citable 1945-1980 production (as the O6 driver)
BP_NL_MODEL <- "naegler_levin_2006_t4_YANG"
BP_NL_OBS   <- "naegler_levin_2006_t4_OBS"
BP_LIN_TOL  <- 1e-6
BP_CORES  <- 6L
# framing C constants, identical to diag_o6_bomb_partition_hilda30c.R / diag_bomb_partition.R
BP_TROPOPAUSE_LAT <- 30; BP_TROPOPAUSE_HPA <- c(extratropical = 308.0, tropical = 121.1); BP_SURFACE_HPA <- 1013.25
bp_a <- sin(BP_TROPOPAUSE_LAT * pi / 180)
BP_F_TROP <- (1 - bp_a) * (1 - BP_TROPOPAUSE_HPA[["extratropical"]] / BP_SURFACE_HPA) + bp_a * (1 - BP_TROPOPAUSE_HPA[["tropical"]] / BP_SURFACE_HPA)
BP_STRAT_TROP <- (1 - BP_F_TROP) / BP_F_TROP
BP_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", BP_TAG, BP_DATE))
COMMIT    <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(BP_MODE)); invisible(ccx_apply_pins(md$pins))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, BP_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
prev <- utils::read.csv(BP_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in BP_FREE) p0[[n]] <- r1[[n]]
nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nl_val <- function(src, q, y, col = "kmol_14c") { v <- nl[[col]][nl$source == src & nl$quantity == q & nl$year == y]; if (!length(v)) NA_real_ else v[1] }
oc_obs <- ccx_prepare_obs()$excess_c14

jobs <- list()
for (tag in BP_PROFILES) { prof <- readRDS(ccx_path("outputs", "diagnostics", paste0(tag, ".rds")))
  for (x in prof) jobs[[length(jobs) + 1]] <- list(profile = tag, tau = x$value, over = x$over, par = x$par, opt = x$opt, conv = x$conv) }

one <- function(j) {
  pr <- p0; for (n in BP_FREE) pr[[n]] <- j$par[[n]]
  u <- ccx_par_to_unc(unlist(pr)[md$param_names]); pu <- ccx_unc_to_par(u)
  b <- bp; for (n in names(j$over)) b[[n]] <- j$over[[n]]; p <- ccx_overlay_par(b, pu)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  bf <- function(bt) withCallingHandlers(
    ccx_build_forcing("historical", BP_SPAN, prod_c14 = sp$prod_c14, bomb_total_kmol = bt, luc_scale = pu$luc_scale,
                      enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p)),
    warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
  F_nl <- bf(BP_NL_TOTAL); F_fit <- bf(pu$bomb_total); F_off <- F_nl; F_off$c14_bomb <- 0
  o_nl <- ccx_run_fast(sp, F_nl)$out; o_fit <- ccx_run_fast(sp, F_fit)$out; o_off <- ccx_run_fast(sp, F_off)$out
  yr <- floor(o_nl$t + 1e-9)
  inv <- function(o, i) c(atm = ccx_c14_kmol(mean(o$atm_C14[i])), land = ccx_c14_kmol(mean(o$land_C14[i])), ocean = ccx_c14_kmol(mean(o$ocean_C14[i])))
  out <- list(profile = j$profile, tau = j$tau, litter_slow_frac = b$litter_slow_frac, passive_stock = ccx_const("NPP_GLOBAL_PI") * b$litter_slow_frac * b$tau_soil_slow,
              logpost = j$opt, conv = j$conv, bomb_total = pu$bomb_total)
  lin <- c()
  for (y in BP_YEARS) {
    pb <- function(o) inv(o, yr == y) - inv(o, yr %in% BP_PB)
    e_nl <- pb(o_nl); e_fit <- pb(o_fit)
    pr_nl <- inv(o_nl, yr == y) - inv(o_off, yr == y); pr_fit <- inv(o_fit, yr == y) - inv(o_off, yr == y)
    lin <- c(lin, pr_fit / pr_nl / (pu$bomb_total / BP_NL_TOTAL) - 1)
    for (k in names(e_nl)) { out[[sprintf("%s_%d_nl", k, y)]] <- e_nl[[k]]; out[[sprintf("%s_%d_fit", k, y)]] <- e_fit[[k]]
      out[[sprintf("%s_%d_paired_nl", k, y)]] <- pr_nl[[k]] }
    out[[sprintf("land_share_%d_nl", y)]] <- e_nl[["land"]] / sum(e_nl)
  }
  out$lin_max_rel <- max(abs(lin))
  as.data.frame(out)
}
res <- parallel::mclapply(jobs, one, mc.cores = BP_CORES, mc.preschedule = FALSE)
bad <- vapply(res, inherits, logical(1), "try-error"); if (any(bad)) { print(res[bad]); stop("fork failure") }
R <- do.call(rbind, res)
gate_ok <- all(R$lin_max_rel < BP_LIN_TOL)
ref <- R[R$profile == BP_PROFILES[1] & R$tau == 500, ][1, ]
R$d_logpost_vs_ref <- R$logpost - ref$logpost
R$provenance <- sprintf("%s @%s; %s v0k basin1 + profile overrides {%s}; ccx_run_fast %d-%d; total-minus-1940s; no RNG",
  BP_DRIVER, COMMIT, BP_STRUCT, paste(BP_PROFILES, collapse = ","), BP_SPAN[1], BP_SPAN[2])

sink(paste0(BP_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", BP_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  profiles {%s}; rebalanced vectors; excess 14C kmol, total minus %d-%d mean; atm framing C (x%.4f)\n",
  paste(BP_PROFILES, collapse = ", "), min(BP_PB), max(BP_PB), 1 + BP_STRAT_TROP))
cat(sprintf("  [GATE, linearity of a passive tracer] max |paired(fit)/paired(N&L) / input ratio - 1| = %.1e (tol %.0e) -> %s\n",
  max(R$lin_max_rel), BP_LIN_TOL, if (gate_ok) "PASS" else "FAIL"))
for (y in BP_YEARS) {
  n_atm <- nl_val(BP_NL_MODEL, "troposphere", y) * (1 + BP_STRAT_TROP)
  cat(sprintf("\n--- %d, at N&L's input %g kmol ---  N&L MODEL: atm %.1f land %.1f ocean %.1f  (land = model, NO obs)\n", y, BP_NL_TOTAL,
    n_atm, nl_val(BP_NL_MODEL, "biosphere", y), nl_val(BP_NL_MODEL, "ocean", y)))
  cat(sprintf("  OBS: troposphere x%.4f = %.1f-%.1f; ocean (objective row) %s\n", 1 + BP_STRAT_TROP,
    nl_val(BP_NL_OBS, "troposphere", y, "kmol_lo") * (1 + BP_STRAT_TROP), nl_val(BP_NL_OBS, "troposphere", y, "kmol_hi") * (1 + BP_STRAT_TROP),
    if (any(oc_obs$year == y)) sprintf("%.1f +- %.1f", oc_obs$centre[oc_obs$year == y], oc_obs$half_width[oc_obs$year == y]) else "n/a"))
  cat(sprintf("  %-44s %5s %6s %6s | %6s %6s %6s %6s | %7s %7s\n", "profile", "tau", "stock", "dlp", "atm", "land", "ocean", "land%", "land_fit", "ocn_fit"))
  for (i in seq_len(nrow(R))) cat(sprintf("  %-44s %5g %6.0f %+6.2f | %6.2f %6.2f %6.2f %5.1f%% | %7.2f %7.2f\n", R$profile[i], R$tau[i], R$passive_stock[i],
    R$d_logpost_vs_ref[i], R[[sprintf("atm_%d_nl", y)]][i], R[[sprintf("land_%d_nl", y)]][i], R[[sprintf("ocean_%d_nl", y)]][i],
    100 * R[[sprintf("land_share_%d_nl", y)]][i], R[[sprintf("land_%d_fit", y)]][i], R[[sprintf("ocean_%d_fit", y)]][i]))
}
utils::write.csv(R, paste0(BP_OUT, ".csv"), row.names = FALSE)
cat(sprintf("\n  saved %s.{log,csv}\n", BP_OUT)); sink()
if (!gate_ok) stop("linearity gate FAILED -- read lin_max_rel before any interpretation")
