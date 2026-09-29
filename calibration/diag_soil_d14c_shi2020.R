# =====================================================================
# diag_soil_d14c_shi2020.R -- T2: does the model's SOIL RADIOCARBON in year
# 2000 pin the passive pool's AGE? (Marcus 2026-09-29: "run the soil D14C test
# against Shi 2020"; CHANGELOG 09-29 q/r; notes/lit_2026-09-29_passive_soil_stock.md)
#
# At a fixed 1500 GtC passive stock the record is near-indifferent to tau_soil_slow
# (-1.2 at 1000 yr, -2.4 at 1500) while SSP5-8.5 2300 moves +68/+112 ppm (09-29 r).
# Soil 14C is the one observation that sees the pool's age directly. For each
# profile row (fixed-stock, all tau; default-mode 1000/1500 for contrast) this
# runs the REBALANCED vector 1750-2001 through ccx_run() and reads the soil
# pools (both hemispheres) monthly through its edge_fn hook, then averages
# year TS_OBS_YEAR.
#
# OBSERVATIONAL YARDSTICKS (all from the lit note; numbers restated as named
# constants below, each with its table):
#   O1 bulk Delta14C 0-1 m, Shi 2020 Table 1: -244 +/- 48 permil (yr 2000).
#      Includes any radiocarbon-free carbon.
#   O2 the same with Copard 2025's radiocarbon-free (aOC) fractions REMOVED,
#      per layer: the exchanging-only bulk -- what a model with no inert
#      carbon should match IF Copard is right. ⚠ CROSS-STUDY: Shi's layer
#      stocks and Delta14C with Copard's fractions.
#   O3 Sum C*F14C, 0-1 m = 840*0.903 + 1008*0.609 (Shi Table 1): robust to
#      aOC (F14C = 0 adds nothing). F taken as 1 + Delta/1000, as the note does
#      (the 1950-decay factor, 1.006 at yr 2000, is below the obs error).
# ⚠ LIKE-FOR-LIKE: the model's soil (soil_fast + soil_slow, ~1600 GtC) is not
# depth-resolved and carries no inert carbon; Shi's 0-1 m mineral stock is
# 1848 Pg. O1/O2 bracket the aOC question; O3 compares a MASS whose stock
# bases differ by ~15 %. Read the three together, none alone.
# GATE (physical law, not a model): at the 1750 periodic steady state, the
# passive pool's F14C must equal the decay-in-series value
#   F_slow = F_atm * [f_leaf/(1+lambda tau_leaf) + (1-f_leaf)/(1+lambda tau_wood)] / (1+lambda tau_slow)
# (litter into the passive pool drawn from leaf and wood in proportion to NPP
# allocation). Tolerance SD_GATE_TOL permil.
# No RNG. USAGE: Rscript calibration/diag_soil_d14c_shi2020.R  (~10 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
SD_DRIVER  <- "calibration/diag_soil_d14c_shi2020.R"
SD_TAG     <- "soil_d14c_shi2020"
SD_DATE    <- "20260929"
SD_MODE    <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
SD_STRUCT  <- "hilda_csl3v0ka"
SD_PREV    <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
SD_PROFILES <- c(fixedstock = "tau_soil_slow_profile_fixedstock_20260929.rds",
                 default    = "tau_soil_slow_profile_20260929.rds")
SD_ROWS    <- list(fixedstock = c(250, 500, 750, 1000, 1500, 2000, 3000, 5000), default = c(1000, 1500))
SD_FREE    <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
                "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
SD_POOLS   <- c("leaf", "wood", "soil_fast", "soil_slow")
SD_SOIL    <- c("soil_fast", "soil_slow")
SD_SPAN    <- c(1750, 2001)
SD_OBS_YEAR <- 2000
SD_GATE_TOL <- 2          # permil; the smallest passive-pool signal here is ~-30 permil (tau 250)
SD_CORES   <- 6L
# ---- observational yardsticks (lit note, §2 table) ------------------
SHI_STOCK  <- c(top = 840, sub = 1008)          # Pg, 0-0.3 / 0.3-1 m, Shi 2020 Table 1
SHI_D14C   <- c(top = -97, sub = -391)          # permil, yr 2000, Shi 2020 Table 1
SHI_BULK   <- -244; SHI_BULK_SE <- 48           # permil, 0-1 m, Shi 2020 Table 1
COPARD_AOC <- c(top = 0.11, sub = 0.27)         # radiocarbon-free fraction, Copard 2025 Table 3 / Fig 4B
F_of <- function(d) 1 + d / 1000
O3_MASS  <- sum(SHI_STOCK * F_of(SHI_D14C))
exch_C   <- SHI_STOCK * (1 - COPARD_AOC)
O2_BULK  <- 1000 * (sum(SHI_STOCK * F_of(SHI_D14C)) / sum(exch_C) - 1)
SD_OUT   <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", SD_TAG, SD_DATE))
COMMIT   <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")

md <- readRDS(ccx_mode_file(SD_MODE)); invisible(ccx_apply_pins(md$pins))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, SD_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
prev <- utils::read.csv(SD_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in SD_FREE) p0[[n]] <- r1[[n]]
LAM <- ccx_const("LAMBDA_C14")

jobs <- list()
for (m in names(SD_PROFILES)) { prof <- readRDS(ccx_path("outputs", "diagnostics", SD_PROFILES[[m]]))
  pv <- vapply(prof, `[[`, numeric(1), "value")
  for (v in SD_ROWS[[m]]) { x <- prof[[which(pv == v)]]
    ov <- if (!is.null(x$over)) x$over else list(tau_soil_slow = v)
    jobs[[length(jobs) + 1]] <- list(mode = m, tau = v, over = ov, par = x$par,
                                     d_logpost = x$opt - prof[[which(pv == 500)]]$opt) } }

one <- function(j) {
  pr <- p0; for (n in SD_FREE) pr[[n]] <- j$par[[n]]
  u <- ccx_par_to_unc(unlist(pr)[md$param_names]); pu <- ccx_unc_to_par(u)
  b <- bp; for (n in names(j$over)) b[[n]] <- j$over[[n]]; p <- ccx_overlay_par(b, pu)
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- ccx_build_forcing("historical", SD_SPAN, prod_c14 = sp$prod_c14, bomb_total_kmol = pu$bomb_total,
                         luc_scale = pu$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  ix <- lapply(setNames(SD_POOLS, SD_POOLS), function(q) unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]][[q]])))
  ia <- c(sp$aux$idx$NH$atm, sp$aux$idx$SH$atm)
  rd <- ccx_run(sp, F, edge_fn = function(fl, y, t) c(t = t,
          unlist(lapply(SD_POOLS, function(q) c(sum(y[ix[[q]], "C"]), sum(y[ix[[q]], "C14"])))),
          atmC = sum(y[ia, "C"]), atmC14 = sum(y[ia, "C14"])))
  E <- do.call(rbind, rd$edge_trace)
  colnames(E) <- c("t", as.vector(outer(c("C", "C14"), SD_POOLS, function(a, q) paste0(q, "_", a))), "atmC", "atmC14")
  yr <- floor(E[, "t"]); k <- yr == SD_OBS_YEAR; k0 <- yr == SD_SPAN[1]
  d14 <- function(C, C14) 1000 * (C14 / C - 1)
  m <- colMeans(E[k, , drop = FALSE]); m0 <- colMeans(E[k0, , drop = FALSE])
  soilC <- sum(m[paste0(SD_SOIL, "_C")]); soilC14 <- sum(m[paste0(SD_SOIL, "_C14")])
  # GATE: analytic decay-in-series at 1750
  Fa <- m0[["atmC14"]] / m0[["atmC"]]
  F_lit <- p$npp_leaf_frac / (1 + LAM * p$tau_leaf) + (1 - p$npp_leaf_frac) / (1 + LAM * p$tau_wood)
  gate_ana <- 1000 * (Fa * F_lit / (1 + LAM * p$tau_soil_slow) - 1)
  gate_mod <- d14(m0[["soil_slow_C"]], m0[["soil_slow_C14"]])
  data.frame(mode = j$mode, tau = j$tau, litter_slow_frac = p$litter_slow_frac, d_logpost = j$d_logpost,
             slow_C_1750 = m0[["soil_slow_C"]], soil_C = soilC, soil_d14c = d14(soilC, soilC14), soil_sumCF = soilC14,
             fast_d14c = d14(m[["soil_fast_C"]], m[["soil_fast_C14"]]), slow_d14c = d14(m[["soil_slow_C"]], m[["soil_slow_C14"]]),
             atm_d14c = d14(m[["atmC"]], m[["atmC14"]]),
             gate_model = gate_mod, gate_analytic = gate_ana, gate_d = gate_mod - gate_ana, prod_c14 = sp$prod_c14)
}
res <- parallel::mclapply(jobs, one, mc.cores = SD_CORES, mc.preschedule = FALSE)
bad <- vapply(res, inherits, logical(1), "try-error"); if (any(bad)) { print(res[bad]); stop("fork failure") }
R <- do.call(rbind, res)
R$z_O1 <- (R$soil_d14c - SHI_BULK) / SHI_BULK_SE
R$provenance <- sprintf("%s @%s; %s v0k basin1 + profile overrides; ccx_run %d-%d, yr %d mean; no RNG", SD_DRIVER, COMMIT, SD_STRUCT, SD_SPAN[1], SD_SPAN[2], SD_OBS_YEAR)
gate_ok <- all(abs(R$gate_d) < SD_GATE_TOL)

sink(paste0(SD_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", SD_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  rows: fixed-stock {%s}, default-mode {%s}; rebalanced vectors; soil = %s (both hemispheres); yr %d monthly mean\n",
  paste(SD_ROWS$fixedstock, collapse = ","), paste(SD_ROWS$default, collapse = ","), paste(SD_SOIL, collapse = "+"), SD_OBS_YEAR))
cat(sprintf("  O1 Shi 2020 bulk 0-1 m: %.0f +/- %.0f permil (incl. any radiocarbon-free C)\n", SHI_BULK, SHI_BULK_SE))
cat(sprintf("  O2 exchanging-only bulk, Shi layers with Copard 2025 aOC {%s} removed: %.0f permil  ⚠ cross-study\n", paste(COPARD_AOC, collapse = ", "), O2_BULK))
cat(sprintf("  O3 Sum C*F14C 0-1 m (Shi): %.0f GtC (robust to aOC; stock base 1848 Pg vs model soil ~1600)\n", O3_MASS))
cat(sprintf("  [GATE] 1750 passive-pool D14C vs analytic decay-in-series: max |d| %.3f permil (tol %g) -> %s\n\n",
  max(abs(R$gate_d)), SD_GATE_TOL, if (gate_ok) "PASS" else "FAIL"))
cat(sprintf("  %-10s %5s %6s %7s | %6s %8s %8s %8s | %7s %7s %6s | %6s\n", "mode", "tau", "lsf", "dlogp", "soilC", "soilD14C", "z(O1)", "sumCF",
  "fastD14", "slowD14", "atmD14", "slow1750"))
for (i in seq_len(nrow(R))) with(R[i, ], cat(sprintf("  %-10s %5g %6.4f %+7.2f | %6.0f %8.1f %+8.2f %8.0f | %7.1f %7.1f %6.1f | %6.1f\n",
  mode, tau, litter_slow_frac, d_logpost, soil_C, soil_d14c, z_O1, soil_sumCF, fast_d14c, slow_d14c, atm_d14c, gate_model)))
utils::write.csv(R, paste0(SD_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", SD_OUT)); sink()
if (!gate_ok) stop("analytic steady-state gate FAILED -- read the gate columns before any interpretation")
