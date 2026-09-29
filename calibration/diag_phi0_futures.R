# =====================================================================
# diag_phi0_futures.R -- do the phi = 0 fits DIFFER from hilda29l anywhere at
# large scale? Asked by Marcus 2026-09-29: "I think phi = zero is the more
# physically sensible structure. Are there any large scale differences between
# the models?"
#
# WHY FUTURES. Over the historical record the arms are indistinguishable (log-lik
# within 2.4, every scorecard gate within noise: whole_model_scorecard_20260929_
# hilda29l_vs_phi0.log). The record pins the land's NET CO2 sensitivity; phi
# changes HOW that sensitivity is built (a 2x vegetation-capacity loop on a weak
# fertilisation vs no loop on a strong one), so the arms can only part company
# where CO2 leaves the historical range or where the loop's 20-yr build-up and
# the instant response separate in time. Emissions-driven SSPs test both.
#
# PROTOCOL. ccx_run_coupled() (interactive temperature: CCX's FaIR-fitted
# climate module, IGCC observed GMST spliced where it exists, standing obs
# convention), each SSP's own non-CO2 forcing, 1750-END_YEAR. Each arm is built
# the app's way (the file's structure, pins and SPINUP label), so its historical
# segment is its fitted one.
# ⚠ A COMPARISON, NOT A GATE. Nothing here scores or adopts.
#
# USAGE: Rscript calibration/diag_phi0_futures.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
FUT_END_YEAR  <- 2300                      # standing end year for all work (Marcus 08-28)
FUT_REF_YEAR  <- 2024                      # last observed year; uptake is counted from here
FUT_MARKS     <- c(2050, 2100, 2200, 2300) # years printed
# ⚠ 2026-09-29 (c): van Vuuren markers (the app's menu since that date), and the
# GCB history SPLICED over each scenario's past exactly as app_splice_history()
# does. The first run (09-29 b, SSPs, unspliced) started 2024 at 410-415 ppm
# because RCMIP's land-use history is 90 GtC short of GCB; its DIFFERENCES held,
# its levels did not. Pass "ssp" as the first argument to reproduce that run.
FUT_SET <- if (length(commandArgs(TRUE)) && commandArgs(TRUE)[1] == "ssp") "ssp" else "vv"
FUT_SCENARIOS <- if (FUT_SET == "ssp") c("ssp119", "ssp126", "ssp245", "ssp370", "ssp585") else
  c("vvVL", "vvLN", "vvL", "vvML", "vvM", "vvHL", "vvH")
FUT_SPLICE <- FUT_SET == "vv"
FUT_PPM_TO_GTC <- ccx_const("GtC_PER_PPM")  # GtC per ppm, global atmosphere (R/constants.R, GCB value)
FUT_ARMS <- c(
  hilda29l      = "hilda29l",
  phi0_free     = ccx_path("calibration", "output",
    "multistart_20260928b_hilda_csl3v0_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
    "promoted_basin1", "mode_fit_pumpN.rds"),
  phi0_shape    = ccx_path("calibration", "output",
    "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
    "promoted_basin1", "mode_fit_pumpN.rds"))

build_arm <- function(a) {
  md <- readRDS(ccx_mode_file(a))
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  p  <- ccx_overlay_par(ccx_mode_base(md), pm)
  p$pump_mode <- md$pump_mode
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  list(md = md, pm = pm, p = p, sp = sp)
}

cat(sprintf("=== PROVENANCE ===\n  driver calibration/diag_phi0_futures.R, commit %s, run %s\n",
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"),
            format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  protocol: ccx_run_coupled, IGCC GMST spliced to the obs record's end, each scenario's own non-CO2, 1750-%d\n",
            FUT_END_YEAR))
cat(sprintf("  scenarios: %s set, emissions %s\n", FUT_SET,
            if (FUT_SPLICE) "GCB history spliced over each scenario's past (as the app)" else "scenario's own, UNSPLICED (the 09-29 b run)"))
cat(sprintf("  units: ppm (global mean); GtC of uptake counted from %d\n", FUT_REF_YEAR))

A <- lapply(FUT_ARMS, build_arm)
for (n in names(A)) with(A[[n]], cat(sprintf(
  "  arm %-10s %s | logpost %.4f | spinup %s | npp_veg_frac %.2f beta_max %.4f fert_k %.1f q10 %.3f\n",
  n, basename(dirname(ccx_mode_file(FUT_ARMS[[n]]))), md$logpost, ccx_mode_spinup(md),
  p$npp_veg_frac, p$beta_max, p$fert_k, p$q10)))

# Mirrors app_splice_history(): GCB through its last year, the scenario after.
fut_emissions <- function(s) {
  if (!FUT_SPLICE) return(NULL)
  h <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  h <- h[, c("year", "fossil_GtC", "luc_GtC")]
  e <- ccx_scenario_emissions(s)
  rbind(h, e[e$year > max(h$year), c("year", "fossil_GtC", "luc_GtC")])
}
ann <- function(o, col) { v <- tapply(o[[col]], floor(o$t), mean); setNames(as.numeric(v), names(v)) }
res <- list()
for (s in FUT_SCENARIOS) for (n in names(A)) {
  a <- A[[n]]
  r <- ccx_run_coupled(a$sp, scenario = s, years = c(1750, FUT_END_YEAR),
                       emissions = fut_emissions(s),
                       bomb_total_kmol = a$pm$bomb_total, luc_scale = a$pm$luc_scale)
  co2 <- (ann(r$out, "co2_NH") + ann(r$out, "co2_SH")) / 2
  lnd <- ann(r$out, "land_C"); ocn <- ann(r$out, "ocean_C")
  k   <- as.character(c(FUT_REF_YEAR, FUT_MARKS))
  res[[length(res) + 1]] <- data.frame(
    scenario = s, arm = n, year = c(FUT_REF_YEAR, FUT_MARKS),
    co2 = co2[k],
    d_atm  = (co2[k] - co2[as.character(FUT_REF_YEAR)]) * FUT_PPM_TO_GTC,
    d_land = lnd[k] - lnd[as.character(FUT_REF_YEAR)],
    d_ocn  = ocn[k] - ocn[as.character(FUT_REF_YEAR)])
}
R <- do.call(rbind, res); rownames(R) <- NULL
R$af <- with(R, d_atm / (d_atm + d_land + d_ocn))

cat(sprintf("\n=== 1. CO2 (ppm) and uptake since %d (GtC), per scenario ===\n", FUT_REF_YEAR))
for (s in FUT_SCENARIOS) {
  cat(sprintf("\n  %s\n  %-6s %-11s %8s %9s %9s %9s %7s\n", s, "year", "arm", "CO2", "dAtm", "dLand", "dOcean", "AF"))
  x <- R[R$scenario == s, ]
  for (y in c(FUT_REF_YEAR, FUT_MARKS)) for (n in names(A)) {
    z <- x[x$year == y & x$arm == n, ]
    cat(sprintf("  %-6d %-11s %8.1f %9.1f %9.1f %9.1f %7s\n", y, n, z$co2, z$d_atm, z$d_land, z$d_ocn,
                if (y == FUT_REF_YEAR) "--" else sprintf("%.3f", z$af)))
  }
}

cat("\n=== 2. phi0 arms minus hilda29l: CO2 (ppm) | land uptake (GtC) ===\n")
cat(sprintf("  %-7s %-11s %s\n", "", "arm", paste(sprintf("%16d", FUT_MARKS), collapse = "")))
for (s in FUT_SCENARIOS) for (n in setdiff(names(A), "hilda29l")) {
  x <- R[R$scenario == s, ]
  d <- vapply(FUT_MARKS, function(y) {
    b <- x[x$year == y & x$arm == "hilda29l", ]; z <- x[x$year == y & x$arm == n, ]
    sprintf("%+7.1f |%+7.1f", z$co2 - b$co2, z$d_land - b$d_land) }, "")
  cat(sprintf("  %-7s %-11s %s\n", s, n, paste(sprintf("%16s", d), collapse = "")))
}
out <- ccx_path("outputs", "diagnostics", sprintf("phi0_futures_%s_%s.rds", FUT_SET, format(Sys.Date(), "%Y%m%d")))
saveRDS(list(table = R, arms = FUT_ARMS, end_year = FUT_END_YEAR, ref_year = FUT_REF_YEAR,
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")), out)
cat(sprintf("\n  saved %s\n  ⛔ A comparison; nothing adopted.\n", out))
