# =====================================================================
# diag_tau_soil_slow_swap.R -- WHY does a bigger passive pool lower 2300 CO2?
# (Marcus 2026-09-29: "run the fert_k swap test"; CHANGELOG 09-29 (o))
#
# At the rebalanced 1000/1500-yr rows, ssp585 2300 is 32-40 ppm below the 500-yr
# control and the land takes up 98-133 GtC more. Two candidates: (1) the
# rebalanced fert_k (868 -> 984/1003) saturates fertilization later; (2) the
# longer passive residence RETAINS extra litter. This walks the control vector
# to each row ONE COMPONENT AT A TIME and attributes the futures change:
#   tau  : tau_soil_slow (the pool itself)
#   fertk: fert_k ALONE (the literal swap asked for)
#   beta : beta_max (with fertk, the pair; cor 0.998 ridge -- fert_k alone is
#          off-ridge, so the pair is the interpretable unit)
#   luc  : luc_scale (also scales the scenario's own LUC -- forcing, not land)
#   kz   : ocean diffusivity
#   rest : the other 7 rebalanced names
# in FORWARD order and REVERSED order; order dependence = interaction.
# Every state is also SCORED (historical logpost vs control), because the
# intermediate states are OFF the fit and their futures are counterfactual.
# Protocol and parameter build identical to diag_tau_soil_slow_futures.R.
# IDENTITY: the all-swapped state reproduces that driver's row futures, and
# the empty state its control (|d| < SW_ID_TOL ppm).
# USAGE: Rscript calibration/diag_tau_soil_slow_swap.R   (~15 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
SW_DRIVER  <- "calibration/diag_tau_soil_slow_swap.R"
SW_TAG     <- "tau_soil_slow_swap"
SW_DATE    <- "20260929"
SW_MODE    <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
SW_STRUCT  <- "hilda_csl3v0ka"
SW_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_20260929.rds")
SW_PREV    <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
SW_FUT     <- ccx_path("outputs", "diagnostics", "tau_soil_slow_futures_20260929.csv")
SW_PARAM   <- "tau_soil_slow"
SW_CTRL    <- 500
SW_ROWS    <- c(1000, 1500)
SW_FREE    <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
                "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
SW_COMP    <- list(tau = SW_PARAM, fertk = "fert_k", beta = "beta_max", luc = "luc_scale", kz = "kz",
                   rest = setdiff(SW_FREE, c("fert_k", "beta_max", "luc_scale", "kz")))
SW_ORDERS  <- list(forward = names(SW_COMP), reverse = rev(names(SW_COMP)))
SW_SCEN    <- c("vvH", "vvL", "ssp585")
SW_SPLICE  <- c(vvH = TRUE, vvL = TRUE, ssp585 = FALSE)
SW_END_YEAR <- 2300L
SW_ID_TOL  <- 0.05
SW_CORES   <- 4L
SW_OUT     <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", SW_TAG, SW_DATE))
COMMIT     <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(SW_MODE)); invisible(ccx_apply_pins(md$pins))
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, SW_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
prof <- readRDS(SW_PROFILE); pv <- vapply(prof, `[[`, numeric(1), "value")
prev <- utils::read.csv(SW_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
FUT  <- utils::read.csv(SW_FUT, check.names = FALSE)
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in SW_FREE) p0[[n]] <- r1[[n]]
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!SW_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
# a STATE = named list of the 11 fitted values + tau
state_of <- function(v) { x <- prof[[which(pv == v)]]; s <- as.list(x$par[SW_FREE]); s[[SW_PARAM]] <- v; s }
eval_state <- function(st) {
  pr <- p0; for (n in SW_FREE) pr[[n]] <- st[[n]]
  u <- ccx_par_to_unc(unlist(pr)[md$param_names]); pu <- ccx_unc_to_par(u)
  b <- bp; b[[SW_PARAM]] <- st[[SW_PARAM]]; p <- ccx_overlay_par(b, pu)
  lp <- as.numeric(ccx_make_logpost(base_params = b)(u))
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p); out <- c(logpost = lp)
  for (s in SW_SCEN) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, SW_END_YEAR), emissions = emis(s),
                                          bomb_total_kmol = pu$bomb_total, luc_scale = pu$luc_scale))$out
    yr <- floor(r$t); co2 <- tapply((r$co2_NH + r$co2_SH) / 2, yr, mean); ld <- tapply(r$land_C, yr, mean)
    out[paste0(s, "_co2_2300")] <- co2[["2300"]]; out[paste0(s, "_dland")] <- ld[["2300"]] - ld[["1750"]]
  }
  out
}
C0 <- state_of(SW_CTRL)
jobs <- list()
for (v in SW_ROWS) { T1 <- state_of(v)
  for (o in names(SW_ORDERS)) { st <- C0; ord <- SW_ORDERS[[o]]
    jobs[[length(jobs) + 1]] <- list(row = v, order = o, step = 0L, comp = "(control)", st = st)
    for (i in seq_along(ord)) { for (n in SW_COMP[[ord[i]]]) st[[n]] <- T1[[n]]
      jobs[[length(jobs) + 1]] <- list(row = v, order = o, step = i, comp = ord[i], st = st) } } }
vals <- parallel::mclapply(jobs, function(j) eval_state(j$st), mc.cores = SW_CORES, mc.preschedule = FALSE)
bad <- vapply(vals, inherits, logical(1), "try-error"); if (any(bad)) { print(vals[bad]); stop("fork failure") }
R <- do.call(rbind, lapply(seq_along(jobs), function(k) data.frame(row = jobs[[k]]$row, order = jobs[[k]]$order,
  step = jobs[[k]]$step, comp = jobs[[k]]$comp, t(vals[[k]]), check.names = FALSE)))
# identities vs diag_tau_soil_slow_futures.R
ctl <- R[R$step == 0, ]; fin <- R[R$step == length(SW_COMP), ]
id1 <- max(abs(ctl$ssp585_co2_2300 - FUT$ssp585_co2_2300[FUT$tau_soil_slow == SW_CTRL]))
id2 <- max(abs(fin$ssp585_co2_2300 - FUT$ssp585_co2_2300[match(fin$row, FUT$tau_soil_slow)]))
stopifnot(id1 < SW_ID_TOL, id2 < SW_ID_TOL)
lp0 <- ctl$logpost[1]
R <- do.call(rbind, lapply(split(R, list(R$row, R$order), drop = TRUE), function(d) { d <- d[order(d$step), ]
  for (m in c("ssp585_co2_2300", "vvH_co2_2300", "vvL_co2_2300", "ssp585_dland")) d[[paste0("inc_", m)]] <- c(0, diff(d[[m]]))
  d$d_logpost <- d$logpost - lp0; d }))
R$provenance <- sprintf("%s @%s; %s v0k basin1; profile rows; coupled 1750-%d; ssp585 unspliced, vv spliced", SW_DRIVER, COMMIT, SW_STRUCT, SW_END_YEAR)
sink(paste0(SW_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s, run %s\n", SW_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  control tau %g -> rows {%s}; components %s; orders forward / reverse; ppm global mean; GtC\n",
  SW_CTRL, paste(SW_ROWS, collapse = ", "), paste(sprintf("%s={%s}", names(SW_COMP), sapply(SW_COMP, paste, collapse = ",")), collapse = " ")))
cat(sprintf("  [identity] control vs futures driver %.3f ppm; full swap vs futures driver %.3f ppm (tol %.2f)\n", id1, id2, SW_ID_TOL))
for (v in SW_ROWS) for (o in names(SW_ORDERS)) { d <- R[R$row == v & R$order == o, ]; d <- d[order(d$step), ]
  cat(sprintf("\n  row tau %g, %s order        (increment per step; d_logpost = state's historical fit vs control)\n", v, o))
  cat(sprintf("    %-10s %9s | %9s %9s %8s %9s\n", "step", "d_logpost", "ssp585", "vvH", "vvL", "dLand585"))
  for (i in seq_len(nrow(d))) cat(sprintf("    %-10s %+9.1f | %+9.1f %+9.1f %+8.1f %+9.1f\n", d$comp[i], d$d_logpost[i],
    d$inc_ssp585_co2_2300[i], d$inc_vvH_co2_2300[i], d$inc_vvL_co2_2300[i], d$inc_ssp585_dland[i]))
  cat(sprintf("    %-10s %9s | %+9.1f %+9.1f %+8.1f %+9.1f\n", "TOTAL", "", sum(d$inc_ssp585_co2_2300), sum(d$inc_vvH_co2_2300),
    sum(d$inc_vvL_co2_2300), sum(d$inc_ssp585_dland))) }
utils::write.csv(R, paste0(SW_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", SW_OUT)); sink()
