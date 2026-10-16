#!/usr/bin/env Rscript
# =====================================================================
# diag_schwartz_3ccdm.R -- does Schwartz's 2025 ocean model match CarboTope's ocean, and if not, why not (2026-10-16)
#
# Marcus 2026-10-16: "On Schwartz's 2024 & 2025 papers ... I can't actually find any claims in either of them for a
# short lifetime. Maybe we can determine whether his simple model matches CarboTope or not, and if not, why not."
#
# THE MODEL: Schwartz (2025), "Three-compartment, two-parameter concentration-driven model for uptake of excess
# atmospheric CO2 by the global ocean", Biogeosciences 22:2979-3009, doi:10.5194/bg-22-2979-2025 ("3C-CDM").
#   Atmosphere (prescribed CO2) -> mixed layer (ML, 100 m) <-> deep ocean (DO, 3583 m, well mixed). Excess stocks.
#   Net air -> ML:   k_am * GtC_per_ppm * (chi_air - pCO2_ML(DIC_ML))     k_am = 0.119 /yr (Sarmiento & Gruber 2002)
#   ML <-> DO:       k_md * S_ML - k_dm * S_DO,  k_md = v_p / z_m, k_dm = v_p / z_d, v_p = 7.5 m/yr (from heat uptake)
#   ML chemistry at 18 C and alkalinity 2349 umol/kg (his CO2SYS settings).
#   ⚠ RE-IMPLEMENTED FROM THE PAPER'S TEXT, not his code. Two choices, stated: (1) the net air-sea flux uses the
#   exact equilibrium pCO2 of the ML DIC (his Eq. 24 linearizes it with a DIC-dependent K'_ma; same physics);
#   (2) chemistry is CarboTope's carbonate code (Lueker 2000 constants via seacarb, salinity 34.76) at his T and
#   alkalinity, not CO2SYS. Ocean area 3.619e14 m2 and depths are his; seawater density 1025 kg/m3 (not in the
#   excerpt read).
#
# LIKE FOR LIKE: both oceans see the SAME atmosphere -- CarboTope's own global-mean CO2 (Schwartz drives his with
# the GCB record; CarboTope's tracks it). Test A: the historical gate run 1750 -> RB_END (dg_run). Test B: the Pulse
# lab pair (Medium background vvM, 100 GtC in 2050, to 2300); the ocean's share of the pulse is pulse minus base.
# VARIANTS separate the candidate reasons for a difference: the deep-ocean exchange (v_p x0.5, x2, x2.9 = the
# AR6-implied value the paper names), the ML temperature (2 C and 22 C), and the gas-exchange rate (k_am x2).
# Output: outputs/diagnostics/schwartz_3ccdm_<date>_<canonical>.{rds,log}. No RNG.
# Usage (repo root):  Rscript calibration/diag_schwartz_3ccdm.R
# =====================================================================
suppressMessages({ library(shiny); old <- setwd("app"); source("global.R")
  for (f in sort(list.files("R", pattern = "\\.R$", full.names = TRUE))) source(f); setwd(old) })

SD_DRIVER <- "calibration/diag_schwartz_3ccdm.R"
S25 <- list(area_m2 = 3.619e14, z_m = 100, z_d = 3683 - 100, rho = 1025, k_am = 0.119, v_p = 7.5,
            T_C = 18, alk = 2349e-6)                         # Schwartz (2025), as read
DT_YR <- 1 / 48                                              # integration step (forcing is monthly)
RB_END <- 2024L                                              # Test A: uptake through the end of this year
GCB_WIN <- c(1959L, 2024L)                                   # the GCB ocean-sink comparison window
PULSE_BG <- "vvM"; PULSE_YEAR <- 2050L; PULSE_GTC <- 100     # Test B: the Pulse lab default
HORIZONS <- c(20L, 50L, 100L, 250L)
S25_2022_PUB <- 2.84                                         # his published 2022 net ocean uptake, PgC/yr (+-0.6)
VP_SEARCH <- c(0.5, 60)                                      # m/yr bracket for the effective piston velocity
VARIANTS <- list(base = list(), vp_x0.5 = list(v_p = 7.5 * 0.5), vp_x2 = list(v_p = 7.5 * 2),
                 vp_x2.9 = list(v_p = 7.5 * 2.9), T_2C = list(T_C = 2), T_22C = list(T_C = 22),
                 kam_x2 = list(k_am = 0.119 * 2))
OUT <- file.path("outputs", "diagnostics", sprintf("schwartz_3ccdm_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
COMMIT <- ccx_git_stamp(exclude = paste0(OUT, c(".rds", ".log")))
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = paste0(OUT, ".log"), append = TRUE) }
if (file.exists(paste0(OUT, ".log"))) file.remove(paste0(OUT, ".log"))
say("%s @%s | canonical %s | %s\n", SD_DRIVER, COMMIT, CCX_MODE_CANONICAL, format(Sys.time(), "%Y-%m-%d %H:%M"))

gpp <- ccx_const("GtC_PER_PPM"); c0 <- ccx_const("CO2_PI_PPM")
cc  <- ccx_carb_coefs_for(APP_PARAMS$carb_salinity)
MOL_PER_PGC <- 1e15 / 12.011

#' Schwartz's 3C-CDM driven by an atmospheric CO2 path (t in years, chi in ppm). Returns excess stocks (PgC).
s25_run <- function(t, chi, par = list()) {
  p <- utils::modifyList(S25, par)
  M_m <- p$area_m2 * p$z_m * p$rho                           # ML mass, kg
  k <- carb_constants(p$T_C, cc)
  dic0 <- ccx_dic_for_pco2(chi[1], p$alk, p$T_C, cc = cc)     # ML in equilibrium with the starting atmosphere
  k_md <- p$v_p / p$z_m; k_dm <- p$v_p / p$z_d
  tt <- seq(t[1], t[length(t)], by = DT_YR); ch <- stats::approx(t, chi, xout = tt)$y
  Sm <- Sd <- numeric(length(tt)); Fas <- numeric(length(tt))
  rhs <- function(sm, sd, x) {
    pco2 <- pco2_from_dic(dic0 + sm * MOL_PER_PGC / M_m, p$alk, p$T_C, k = k)
    f <- p$k_am * gpp * (x - pco2)
    c(f - k_md * sm + k_dm * sd, k_md * sm - k_dm * sd, f)
  }
  for (i in seq_len(length(tt) - 1L)) {                      # Heun (RK2); the forcing is linear within a step
    a1 <- rhs(Sm[i], Sd[i], ch[i])
    a2 <- rhs(Sm[i] + DT_YR * a1[1], Sd[i] + DT_YR * a1[2], ch[i + 1])
    Sm[i + 1] <- Sm[i] + DT_YR / 2 * (a1[1] + a2[1]); Sd[i + 1] <- Sd[i] + DT_YR / 2 * (a1[2] + a2[2])
    Fas[i] <- (a1[3] + a2[3]) / 2
  }
  data.frame(t = tt, S_ml = Sm, S_do = Sd, S_ocean = Sm + Sd)
}
at_t <- function(d, col, tq) stats::approx(d$t, d[[col]], xout = tq)$y
co2g <- function(o) (o$co2_NH + o$co2_SH) / 2

# ---- Test A: history ----------------------------------------------------------------------------------------
# The gate run (lib_design_gates.R dg_run), not APP_HIST: it carries the state to Jan 1 of RB_END + 1, which
# RB_END's uptake needs, and its carbon closes against fossil emissions to 4e-11 GtC (2026-10-16 e).
suppressWarnings(source(file.path("calibration", "lib_design_gates.R")))
h <- dg_run(dg_vector(CCX_MODE_CANONICAL))$out
stopifnot(h$t[1] < 1750.1, max(h$t) > RB_END + 1)
# CarboTope rows are START-of-month states (measured 2026-10-16 e); year y's uptake = Jan 1 (y+1) - Jan 1 (y)
jan1 <- function(o, col) { k <- which(abs(o$t - floor(o$t) - 1 / 24) < 1e-6); data.frame(year = floor(o$t[k]), v = o[[col]][k]) }
oc <- jan1(h, "ocean_C"); ccx_up <- data.frame(year = oc$year[-nrow(oc)], up = diff(oc$v))
ccx_up <- ccx_up[ccx_up$year <= RB_END, ]
tA <- h$t - 1 / 24                                           # a start-of-month state sits at the month's start
resA <- lapply(VARIANTS, function(par) {
  s <- s25_run(tA, co2g(h), par)
  yrs <- seq(1750L, RB_END)
  data.frame(year = yrs, up = at_t(s, "S_ocean", yrs + 1) - at_t(s, "S_ocean", yrs))
})
gcb <- as.data.frame(APP_OBS$gcb)[, c("year", "ocean_sink")]
win <- function(d) d[d$year >= GCB_WIN[1] & d$year <= GCB_WIN[2], ]
cum <- function(d, col = "up") sum(d[[col]])
say("\nTEST A -- ocean uptake under CarboTope's own atmosphere (GtC)\n")
say("  %-10s %12s %12s %12s %12s\n", "", "1750-2024", "1959-2024", "2015-2024/yr", "2024")
row <- function(nm, d) say("  %-10s %12.1f %12.1f %12.2f %12.2f\n", nm, cum(d[d$year <= RB_END, ]), cum(win(d)),
                           mean(d$up[d$year >= 2015 & d$year <= 2024]), d$up[d$year == 2024])
row("CarboTope", ccx_up)
for (nm in names(resA)) row(paste0("S25 ", nm), resA[[nm]])
say("  %-10s %12s %12.1f %12.2f %12.2f   (GCB 2025 ocean sink)\n", "GCB", "--", sum(win(gcb)$ocean_sink),
    mean(gcb$ocean_sink[gcb$year >= 2015]), gcb$ocean_sink[gcb$year == 2024])
s22 <- resA$base$up[resA$base$year == 2022]
say("  CHECK the re-implementation: S25 base in 2022 %.2f PgC/yr vs his published %.2f (+-0.6); GCB 2025 gives %.2f, CarboTope %.2f\n",
    s22, S25_2022_PUB, gcb$ocean_sink[gcb$year == 2022], ccx_up$up[ccx_up$year == 2022])

# ---- Test B: the pulse ---------------------------------------------------------------------------------------
yrs <- APP_PULSE_YEARS; y <- seq(yrs[1], yrs[2])
bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == PULSE_BG, ]
base_em <- data.frame(year = y, fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
                      luc_GtC = stats::approx(bg$year, bg$luc_GtC, xout = y, rule = 2)$y)
pulse_em <- base_em
pulse_em$fossil_GtC[pulse_em$year == PULSE_YEAR] <- pulse_em$fossil_GtC[pulse_em$year == PULSE_YEAR] + PULSE_GTC
runp <- function(em) app_run_coupled(APP_SPIN, PULSE_BG, yrs, PULSE_BG, emissions = em, interp_method = APP_PULSE_EMIS_METHOD)
rb <- runp(base_em)$out; rp <- runp(pulse_em)$out
stopifnot(identical(rb$t, rp$t))
tq <- PULSE_YEAR + HORIZONS
ccx_ocean_share <- 100 * (at_t(rp, "ocean_C", tq) - at_t(rb, "ocean_C", tq)) / PULSE_GTC
ccx_air_share   <- 100 * (at_t(cbind(rp, g = co2g(rp)), "g", tq) - at_t(cbind(rb, g = co2g(rb)), "g", tq)) * gpp / PULSE_GTC
tB <- rb$t - 1 / 24
resB <- lapply(VARIANTS, function(par) {
  sb <- s25_run(tB, co2g(rb), par); sp <- s25_run(tB, co2g(rp), par)
  100 * (at_t(sp, "S_ocean", tq) - at_t(sb, "S_ocean", tq)) / PULSE_GTC
})
say("\nTEST B -- ocean uptake of a %g GtC pulse in %d (%s), same atmosphere for both, %% of the pulse\n",
    PULSE_GTC, PULSE_YEAR, PULSE_BG)
say("  %-14s %s\n", "+years", paste(sprintf("%7d", HORIZONS), collapse = ""))
say("  %-14s %s\n", "CarboTope", paste(sprintf("%7.1f", ccx_ocean_share), collapse = ""))
for (nm in names(resB)) say("  %-14s %s\n", paste0("S25 ", nm), paste(sprintf("%7.1f", resB[[nm]]), collapse = ""))
say("  (CarboTope's air share of the pulse: %s)\n", paste(sprintf("%.1f", ccx_air_share), collapse = " / "))

# The piston velocity at which S25 matches CarboTope's ocean share at each horizon. A constant structure would give
# one value at every horizon; a value that falls with the horizon is the signature of a diffusive / ventilated
# interior that a single well-mixed deep box with a constant v_p cannot reproduce.
s25_share <- function(v_p, hz) {
  sb <- s25_run(tB, co2g(rb), list(v_p = v_p)); sp <- s25_run(tB, co2g(rp), list(v_p = v_p))
  100 * (at_t(sp, "S_ocean", PULSE_YEAR + hz) - at_t(sb, "S_ocean", PULSE_YEAR + hz)) / PULSE_GTC
}
vp_eff <- vapply(seq_along(HORIZONS), function(i)
  uniroot(function(v) s25_share(v, HORIZONS[i]) - ccx_ocean_share[i], VP_SEARCH, tol = 0.01)$root, numeric(1))
say("  piston velocity at which S25 matches CarboTope (m/yr; his 7.5): %s\n",
    paste(sprintf("+%d: %.1f", HORIZONS, vp_eff), collapse = "; "))

saveRDS(list(testA = list(carbotope = ccx_up, s25 = resA, gcb = gcb),
             testB = list(horizons = HORIZONS, carbotope_ocean_pct = ccx_ocean_share, carbotope_air_pct = ccx_air_share,
                          s25_ocean_pct = resB, vp_effective = vp_eff),
             check = list(s25_2022 = s22, published_2022 = S25_2022_PUB),
             provenance = list(driver = SD_DRIVER, commit = COMMIT, mode = CCX_MODE_CANONICAL, s25 = S25, variants = VARIANTS,
                               dt_yr = DT_YR, rng = "none", source = "Schwartz 2025, Biogeosciences 22:2979, doi:10.5194/bg-22-2979-2025",
                               forcing = "CarboTope global-mean CO2: the canonical gate run dg_run (Test A); Pulse lab vvM pair (Test B)")),
        paste0(OUT, ".rds"))
say("\nwrote %s.{rds,log}\n", OUT)
