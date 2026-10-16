#!/usr/bin/env Rscript
# =====================================================================
# diag_revelle_buffer.R -- the ocean's buffer chemistry in CarboTope, measured (2026-10-16).
#
# Marcus 2026-10-16: "Save the Revelle analysis as a diagnostic. Also calculate the numbers for this statement:
# 'This property alone changes the 2% human addition to total carbon to an equilibrium X% increase in atmospheric
# concentration (or Y ppm).'"
#
# PART A -- the four surface boxes that exchange with the air (mixed layer and cold high-latitude box, per
#   hemisphere; the eq/tr boxes are off at the canonical). For RA_YEARS, annual means: the box's own pCO2 from the
#   run, the temperature it sees (base SST + the observed anomaly; the cold box at its climatological SST + the
#   anomaly times ccx_hs_sst_frac()), the DIC that gives that pCO2 (an exact inversion of the model's chemistry),
#   and at that state pH (total scale: the carbonate tables are Lueker 2000 on pHscale "T") and the Revelle factor.
#   Annual means of a nonlinear quantity: the seasonal cycle is averaged out first.
# PART B -- the equilibrium the statement asks for. "This property alone" = buffer chemistry only, so:
#   * the equilibrium is between the atmosphere and the WHOLE ocean, from the model's own steady-state spin-up at
#     an atmospheric CO2 c (the canonical's spin-up function, `chi0 = c`): circulation, biology, temperature
#     (preindustrial) and alkalinity fixed; NO land response; NO carbonate sediments or weathering (in the real
#     ocean, CaCO3 dissolution over ~10 kyr would lower the answer further);
#   * solve (c - c0) * GtC_per_ppm + [ocean(c) - ocean(c0)] = E for c;
#   * compare with the UNBUFFERED answer: E spread in proportion to carbon mass over the same reservoirs.
#   The "2%" is E over the preindustrial EXCHANGING carbon (atmosphere + land without inert soil + ocean).
#   ⚠ WHICH CARBON IS AN ADDITION (found 2026-10-16 by this script's closure gate): land-use emissions MOVE carbon
#   from land to air, so the system's total grows by the FOSSIL emissions only (1750 -> 2024: +504 GtC in the run
#   against 505 fossil; land use 272 GtC, but the land's NET loss only ~38 GtC, the rest regrown). Three readings of
#   E are reported, and the choice is Marcus's:
#     fossil          the human addition to the system's total carbon (what "addition to total carbon" means);
#     fossil_netland  what the air + ocean have received (fossil + the land's net loss), land held at its 2024 state;
#     all_emissions   fossil + gross land use, i.e. everything emitted to the air (NOT an addition to the total).
#
# GATES (stop on any): the spin-up at c0 reproduces the canonical's own spin-up; the run's carbon closes against E;
# ocean(c) increases with c; the solved budget closes.
# Output: outputs/diagnostics/revelle_buffer_<date>_<canonical>.{rds,log}. No RNG.
# Usage:  Rscript calibration/diag_revelle_buffer.R      (from the repo root)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
suppressWarnings(source(file.path("calibration", "lib_design_gates.R")))

RB_DRIVER  <- "calibration/diag_revelle_buffer.R"
RA_YEARS   <- c(1750L, 2024L)          # Part A: the two states compared
RB_YEAR    <- 2024L                    # Part B: emissions counted through the end of this year
RB_CO2_HI  <- 300                      # ppm above c0 bracketing the equilibrium root
RB_TOL_GTC <- 1e-6                     # identity gates (GtC): the c0 spin-up, the solved budget
RB_OUT <- file.path("outputs", "diagnostics",
                    sprintf("revelle_buffer_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
COMMIT <- ccx_git_stamp(exclude = paste0(RB_OUT, c(".rds", ".log")))

say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = paste0(RB_OUT, ".log"), append = TRUE) }
if (file.exists(paste0(RB_OUT, ".log"))) file.remove(paste0(RB_OUT, ".log"))
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
mode_rel  <- sub(paste0("^", normalizePath(ccx_root()), "/"), "", normalizePath(mode_file))
say("%s @%s | canonical %s (%s, md5 %s) | %s\n\n", RB_DRIVER, COMMIT, CCX_MODE_CANONICAL, mode_rel, md5,
    format(Sys.time(), "%Y-%m-%d %H:%M"))

v  <- dg_vector(CCX_MODE_CANONICAL)
spin_fn <- if (is.null(v$spinup)) ccx_spinup else v$spinup
r  <- dg_run(v); a <- r$sp$aux; o <- r$out; F <- r$F
cc <- ccx_carb_coefs_for(v$p$carb_salinity); alk <- a$alk_ml; frac <- ccx_hs_sst_frac(v$p)
if (!identical(a$alk_hs, alk)) stop("Part A assumes one surface alkalinity; alk_hs differs from alk_ml")
yr <- floor(o$t); yrF <- floor(F$t)

# ---- PART A ------------------------------------------------------------------------------------------------
dic_for <- function(pco2, T) uniroot(function(d) pco2_from_dic(d, alk, T, k = carb_constants(T, cc)) - pco2,
                                     c(1.5e-3, 2.7e-3), tol = 1e-13)$root
rowsA <- list()
for (h in HEMIS) for (box in c("ml", "hs")) for (y in RA_YEARS) {
  an <- mean(F[[paste0("sst_anom_", h)]][yrF == y])
  T  <- if (box == "ml") a$sst[[h]] + an else a$sst_hs + frac * an
  p  <- mean(o[[paste0(box, "_pco2_", h)]][yr == y]); d <- dic_for(p, T)
  rowsA[[length(rowsA) + 1]] <- data.frame(
    box = sprintf("%s %s", h, c(ml = "mixed layer", hs = "cold high-latitude box")[[box]]), year = y,
    T_C = T, pco2_uatm = p, dic_umol_kg = 1e6 * d,
    pH_total = -log10(h_from_dic_alk(d, alk, T, k = carb_constants(T, cc))),
    revelle = revelle_factor(d, alk, T, cc = cc))
}
A <- do.call(rbind, rowsA)
say("PART A -- surface boxes exchanging with the air (annual means; alkalinity %.1f umol/kg, salinity %.2f)\n",
    1e6 * alk, v$p$carb_salinity)
for (i in seq_len(nrow(A))) say("  %-34s %d  T %6.2f C  pCO2 %6.1f  DIC %7.1f  pH %.3f  Revelle %6.3f\n",
                                A$box[i], A$year[i], A$T_C[i], A$pco2_uatm[i], A$dic_umol_kg[i], A$pH_total[i], A$revelle[i])

# ---- PART B ------------------------------------------------------------------------------------------------
gpp <- ccx_const("GtC_PER_PPM"); c0 <- ccx_const("CO2_PI_PPM")
foss <- (F$e_foss_NH + F$e_foss_SH) / 12; luc <- (F$e_luc_NH + F$e_luc_SH) / 12   # GtC per month
E_fossil <- sum(foss[yrF <= RB_YEAR]); E_luc <- sum(luc[yrF <= RB_YEAR])
stock <- function(sp) ccx_stock_readout(sp$y, sp$aux)
s0 <- stock(r$sp)
# GATE: the system's total carbon grows by the FOSSIL emissions (land use is a land -> air transfer). Each row of the
# run is the state at the START of its month (measured: row k closes against the fossil of the rows before it), so
# the end of RB_YEAR is the first row of the next year. Conservation is an identity: tolerance RB_TOL_GTC.
k_end <- min(which(yr == RB_YEAR + 1L))
atm_end <- (o$co2_NH[k_end] + o$co2_SH[k_end]) / 2 * gpp
d_tot <- atm_end + o$land_C[k_end] + o$ocean_C[k_end] - s0[["total"]]
d_land <- o$land_C[k_end] - s0[["land_total"]]
say("\nPART B -- through %d: fossil %.1f GtC; land use %.1f GtC (luc_scale %.4f); the land's net change %+.1f GtC\n",
    RB_YEAR, E_fossil, E_luc, v$luc_scale, d_land)
say("  GATE the system's carbon change 1750 -> end of %d (%.4f GtC) vs fossil (%.4f): %+.2e GtC (tolerance %.0e)\n",
    RB_YEAR, d_tot, E_fossil, d_tot - E_fossil, RB_TOL_GTC)
if (abs(d_tot - E_fossil) > RB_TOL_GTC) stop("the system's carbon does not close against fossil emissions")
E_set <- c(fossil = E_fossil, fossil_netland = E_fossil - d_land, all_emissions = E_fossil + E_luc)

exch0 <- s0[["total"]] - s0[["soil_inert"]]
ocean_at <- local({ memo <- list(); function(c) { key <- format(c, digits = 15)
  if (is.null(memo[[key]])) memo[[key]] <<- stock(spin_fn(v$p, chi0 = c))[["ocean_total"]]; memo[[key]] } })
o0 <- ocean_at(c0)
say("  GATE spin-up at c0 = %.2f ppm reproduces the canonical's ocean: %.3e GtC\n", c0, o0 - s0[["ocean_total"]])
if (abs(o0 - s0[["ocean_total"]]) > RB_TOL_GTC) stop("the c0 spin-up is not the canonical's")
grid_c <- c0 + c(0, 25, 50, 100, 200)
grid_o <- vapply(grid_c, ocean_at, numeric(1))
if (any(diff(grid_o) <= 0)) stop("ocean(c) is not increasing")
say("  ocean steady state vs atmospheric CO2: %s\n",
    paste(sprintf("%.0f ppm %.1f GtC", grid_c, grid_o), collapse = "; "))

atm_ocn0 <- s0[["atmosphere"]] + o0
say("\n  preindustrial exchanging carbon %.0f GtC (total %.0f less inert soil %.0f); air + ocean %.0f GtC\n",
    exch0, s0[["total"]], s0[["soil_inert"]], atm_ocn0)
equilibrium <- function(E) {
  budget <- function(c) (c - c0) * gpp + (ocean_at(c) - o0) - E
  c_eq <- uniroot(budget, c(c0, c0 + RB_CO2_HI), tol = 1e-9)$root
  if (abs(budget(c_eq)) > RB_TOL_GTC * 1e3) stop("the solved budget does not close")
  d_atm <- (c_eq - c0) * gpp; d_ocn <- ocean_at(c_eq) - o0
  prop_pct <- 100 * E / atm_ocn0                    # unbuffered: E in proportion to mass over air + ocean
  list(E_GtC = E, share_of_exchanging_pct = 100 * E / exch0, share_of_air_plus_ocean_pct = prop_pct,
       unbuffered = c(pct = prop_pct, ppm = c0 * prop_pct / 100),
       buffered = c(co2_eq_ppm = c_eq, d_ppm = c_eq - c0, pct = 100 * (c_eq - c0) / c0,
                    d_atm_GtC = d_atm, d_ocean_GtC = d_ocn, airborne_share_pct = 100 * d_atm / E),
       effective_revelle_whole_ocean = ((c_eq - c0) / c0) / (d_ocn / o0),
       ratio_buffered_to_unbuffered = (100 * (c_eq - c0) / c0) / prop_pct)
}
res <- lapply(E_set, equilibrium)
for (nm in names(res)) { x <- res[[nm]]
  say("\n  [%s] E %.1f GtC = %.2f %% of exchanging carbon (%.2f %% of air + ocean)\n", nm, x$E_GtC,
      x$share_of_exchanging_pct, x$share_of_air_plus_ocean_pct)
  say("    UNBUFFERED (E spread by mass over air + ocean): +%.2f %% = +%.1f ppm\n", x$unbuffered[["pct"]], x$unbuffered[["ppm"]])
  say("    BUFFERED equilibrium (the model's chemistry): %.1f ppm = +%.1f ppm = +%.1f %%; air %.1f GtC (%.1f %% of E), ocean %.1f GtC\n",
      x$buffered[["co2_eq_ppm"]], x$buffered[["d_ppm"]], x$buffered[["pct"]], x$buffered[["d_atm_GtC"]],
      x$buffered[["airborne_share_pct"]], x$buffered[["d_ocean_GtC"]])
  say("    ratio buffered / unbuffered %.1f; whole-ocean effective Revelle factor (dc/c)/(dO/O) %.2f\n",
      x$ratio_buffered_to_unbuffered, x$effective_revelle_whole_ocean) }
res <- list(equilibria = res, E_fossil = E_fossil, E_land_use = E_luc, land_net_change = d_land,
            closure_GtC = d_tot - E_fossil, stocks0 = s0, grid = data.frame(co2_ppm = grid_c, ocean_GtC = grid_o))

saveRDS(list(partA = A, partB = res,
             provenance = list(driver = RB_DRIVER, commit = COMMIT, mode = CCX_MODE_CANONICAL, mode_file = mode_rel,
                               mode_md5 = md5, built = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
                               r_version = R.version.string, rng = "none", c0_ppm = c0, gtc_per_ppm = gpp,
                               years_A = RA_YEARS, emissions_through = RB_YEAR,
                               assumptions = paste("Part B: atmosphere + whole ocean at steady state (the canonical's",
                                                   "spin-up at chi0); circulation, biology, preindustrial temperature",
                                                   "and alkalinity fixed; no land response; no CaCO3 sediments or weathering"),
                               units = "GtC, ppm, umol/kg, pH total scale")),
        paste0(RB_OUT, ".rds"))
say("\nwrote %s.{rds,log}\n", RB_OUT)
