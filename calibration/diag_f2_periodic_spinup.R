# =====================================================================
# diag_f2_periodic_spinup.R -- REVIEW LEAD F2: is the ASEASONAL spinup a
# point on the SEASONAL ORBIT, or does the seasonal mixed layer need a
# PERIODIC (limit-cycle) spinup?
#
# WHY THIS IS OWED. 09-09j/k concluded "no periodic spinup is needed", and
# argued it BY CONSTRUCTION from `ccx_spinup()` setting seas_drivers = 0.
# The 09-09t review showed the C++ core IGNORED that zeroing, so the
# argument's premise was false in the core that actually solves the
# equilibrium. The conclusion does not survive its premise and must be
# RE-DERIVED, not re-confirmed. Review §8 lead F2 further claims a real
# +19.6 ppm shock at 1750 remains AFTER the gate fix, because the
# mechanism changes the state->concentration map (ml_mass * f(t)), not
# just a rate.
#
# THE MEASUREMENT. A QUIET run (zero fossil, zero LUC flux AND stock, held
# climate, zero bomb/nuclear 14C, zero AOD) started from the aseasonal
# spinup. With no anthropogenic forcing there is no "the mechanism changes
# uptake" hypothesis to confound the reading: any excursion IS spin-in.
# `quiet_forcing()` is lifted from tests/testthat/test-conveyor.R, the
# repo's own established construction, including the cum_luc and AOD
# zeroing whose absence that file documents as a false drift signal.
#
# THE THRESHOLD IS NOT INVENTED (threshold_from_obs_or_law):
#   * the NOISE FLOOR is the SAME quantity measured on the seas_ml = 0 arm
#     -- a co-located instrument on the same estimator, not a guessed
#     tolerance. seas_ml = 0 is the configuration whose quiet-run flatness
#     test-conveyor.R already gates.
#   * the SCALE that makes an excursion matter is an OBSERVATION: the
#     seasonal CO2 amplitude the likelihood scores (co2_seasonal_MLO /
#     co2_seasonal_SPO). A spin-in transient smaller than the model's own
#     aseasonal drift is invisible; one comparable to the signal being
#     fitted is not.
#   ⛔ No pass/fail verdict is returned on an invented number. The script
#     reports an ORDERING between measured quantities and states what each
#     ordering would mean.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

TAG      <- "20260909"
OUT_RDS  <- file.path("outputs", "diagnostics", paste0("f2_periodic_spinup_", TAG, ".rds"))
OUT_LOG  <- sub("[.]rds$", ".log", OUT_RDS)
YEARS    <- c(1750, 2250)          # 500 yr: long enough to see a "centuries" decay
PROBE_YR <- c(1750, 1751, 1755, 1760, 1770, 1800, 1850, 1950, 2050, 2150, 2249)

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

md <- readRDS(ccx_mode_file())
p0 <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))
# ent_seas_amp_SH = 0 on BOTH arms, so the shim cannot confound the reading:
# the contrast is the seasonal mixed layer ALONE.
arm <- function(seas_ml) { p <- p0; p$ent_seas_amp_SH <- 0; p$seas_ml <- seas_ml; p }

# lifted verbatim in substance from tests/testthat/test-conveyor.R
quiet_forcing <- function(s, years = YEARS) {
  F <- ccx_build_forcing("historical", years, prod_c14 = 0, bomb_total_kmol = 0)
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F <- ccx_hold_climate(F, value = 0); F$c14_bomb <- 0; F$c14_nuclear <- 0
  F$c14_cosmo <- s$prod_c14
  F$aod_NH <- 0; F$aod_SH <- 0
  F
}

say("REVIEW LEAD F2 -- is a PERIODIC spinup owed for the seasonal mixed layer?")
say("mode file : %s", ccx_mode_file())
say("h_ml %.3f m | ent_seas_amp_SH forced to 0 on BOTH arms | quiet run %d-%d",
    p0$h_ml, YEARS[1], YEARS[2])
say("substeps: seas_ml 0 / 1 = %d / %d", ccx_substeps_for(arm(0)), ccx_substeps_for(arm(1)))

res <- list()
for (sm in c(0, 1)) {
  p  <- arm(sm)
  sp <- ccx_spinup(p)
  F  <- quiet_forcing(sp)
  o  <- ccx_run(sp, F)$out
  co2 <- (o$co2_NH + o$co2_SH) / 2
  yr  <- floor(F$t)
  ann <- tapply(co2, yr, mean)                   # ANNUAL means kill the cycle itself
  res[[as.character(sm)]] <- list(ann = ann, co2 = co2, t = F$t,
                                  ocean_C = tapply(o$ocean_C, yr, mean))
}
a0 <- res[["0"]]$ann; a1 <- res[["1"]]$ann
pi_ppm <- ccx_const("CO2_PI_PPM")

say("")
say("ANNUAL-MEAN GLOBAL CO2 IN A QUIET RUN, ppm (anomaly from CO2_PI_PPM = %.3f)", pi_ppm)
say("  %6s %14s %14s %14s", "year", "seas_ml = 0", "seas_ml = 1", "on - off")
for (y in PROBE_YR) {
  k <- as.character(y)
  if (!k %in% names(a0)) next
  say("  %6d %14.4f %14.4f %14.4f", y, a0[[k]] - pi_ppm, a1[[k]] - pi_ppm, a1[[k]] - a0[[k]])
}

exc <- function(a) { d <- a - a[[1]]; d[which.max(abs(d))] }
say("")
say("THE TWO ORDERINGS")
say("  (i) EXCURSION from the run's own first year, ppm")
say("      seas_ml = 0 : %+9.4f   <- the model's aseasonal drift = the NOISE FLOOR",
    exc(a0))
say("      seas_ml = 1 : %+9.4f", exc(a1))
say("      ratio on/off = %.2f", abs(exc(a1)) / max(abs(exc(a0)), 1e-12))
say("  (ii) START-OF-RUN OFFSET the mechanism imposes at t0, ppm")
say("      annual mean %d, on minus off : %+9.4f", YEARS[1], a1[[1]] - a0[[1]])
say("      annual mean %d, on minus off : %+9.4f", YEARS[2] - 1,
    a1[[length(a1)]] - a0[[length(a0)]])
say("      the CHANGE in that offset across %d yr : %+9.4f",
    YEARS[2] - YEARS[1], (a1[[length(a1)]] - a0[[length(a0)]]) - (a1[[1]] - a0[[1]]))
say("")
say("⚠ F2 AS REPORTED claims '+19.6 ppm shock at 1750 decaying over centuries'.")
say("  Read the (i) ratio and the (ii) change together:")
say("   * on/off ratio ~1 AND a near-zero change  -> the aseasonal spinup IS on the")
say("     seasonal orbit; 09-09j/k's conclusion SURVIVES its premise being fixed.")
say("   * a large excursion decaying over the window -> SPIN-IN; a periodic")
say("     (limit-cycle) spinup is owed and round 6's cost changes.")
say("   * a large but FLAT offset -> a rectified LEVEL shift, not spin-in: real")
say("     physics the refit must absorb, not a spinup defect.")
dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode = ccx_mode_file(), years = YEARS, ann_off = a0, ann_on = a1,
             ocean_off = res[["0"]]$ocean_C, ocean_on = res[["1"]]$ocean_C,
             built = Sys.time()), OUT_RDS)
say("wrote %s", OUT_RDS)
close(con)
