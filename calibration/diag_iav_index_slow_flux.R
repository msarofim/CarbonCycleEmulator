#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_index_slow_flux.R -- WHAT THE SHIPPED ENSO INDEX's TREND PUTS INTO THE CARBON BUDGET at basin B (#17), and through
# which consumer: the land ENSO term or the ocean limb. The companion of calibration/diag_iav_redesign_price.R (CHANGELOG
# 2026-10-07 d), whose B1 prices switching to the detrended index at B, unrefitted. The 09-29 (d) audit measured the land
# term's slow source (-0.26 -> +0.31 GtC/yr) at an older mode with the canonical's amplitude; #17 pins the land pair x1.30
# and the lag at 5.84 months, and the limb at w 14.73.
# RUNS, all at B's vector and its own module pins (P0), on DG_YEARS: {shipped, detrended} x {as fitted, the land ENSO pair
# zeroed}. The difference shipped - detrended is the index trend's (and mean's) whole effect; with the land pair zeroed it is
# the limb's alone (the only other consumer of the index); the land term's is the difference of the two.
# Read: the calendar-year land and ocean fluxes (ccx_calendar_flux(), GtC/yr, positive = uptake) by decade, and the global
# CO2 (ppm) at three years. GATE: the shipped run as fitted is dg_run() of B's own vector (its stored rows reproduce through
# dg_streams(), tol 1e-5).
# Usage: Rscript calibration/diag_iav_index_slow_flux.R
# OUTPUTS: outputs/diagnostics/iav_index_slow_flux_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
SF_DRIVER  <- "calibration/diag_iav_index_slow_flux.R"
SF_MODE_B  <- file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds")
SF_INDICES <- c(shipped = "demean", redesign = "detrend")
SF_LAND    <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
SF_DECADES <- seq(1950L, 2020L, by = 10L)        # the index is zero before 1948 (FORC_ENSO_PRE1948)
SF_CO2_YRS <- c(1960L, 1990L, 2024L)
SF_TOL     <- 1e-5
SF_OUT <- file.path("outputs", "diagnostics", sprintf("iav_index_slow_flux_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(SF_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | basin B %s (md5 %s)\n", SF_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), SF_MODE_B,
            unname(tools::md5sum(SF_MODE_B))))
OBS <- ccx_prepare_obs()
V0 <- dg_vector(SF_MODE_B)
variant <- function(index, land_off) { V <- V0
  if (index != "demean") V$p$enso_index <- CCX_ENSO_INDEX_CODES[[index]]
  if (land_off) { for (n in SF_LAND) { V$p[[n]] <- 0; V$pm[[n]] <- 0 }; V$p <- ccx_set_enso(V$p, V$pm) }
  stopifnot(identical(ccx_enso_index_of(V$p), index)); V }
RUNS <- list()
for (ix in names(SF_INDICES)) for (lo in c(FALSE, TRUE)) {
  k <- paste0(ix, if (lo) "_landoff" else ""); V <- variant(SF_INDICES[[ix]], lo); R <- dg_run(V)
  if (!identical(attr(R$F, "enso_index"), SF_INDICES[[ix]])) stop(k, ": the forcing does not carry the index")
  RUNS[[k]] <- list(v = V, r = R) }
st <- unlist(dg_streams(RUNS$shipped$r, RUNS$shipped$v, obs = OBS)); g <- max(abs(st[names(V0$md$streams)] - unlist(V0$md$streams)))
cat(sprintf("GATE: the shipped run as fitted reproduces B's stored rows through dg_streams(): max |diff| %.1e (tol %g)\n", g, SF_TOL))
if (g > SF_TOL) stop("the shipped run is not B's own vector")
lp <- V0$p[SF_LAND]; cat(sprintf("B's land ENSO pair %s, lag %.4f months; w_enso_l2 %.4f\n", paste(sprintf("%s %.5f", SF_LAND, unlist(lp)), collapse = ", "),
                                 V0$p[["lag_enso_land"]], V0$p[["w_enso_l2"]]))
flux <- function(R) ccx_calendar_flux(R$out[R$out$t < DG_SINK_LAST + 1, , drop = FALSE])
co2  <- function(R) tapply((R$out$co2_NH + R$out$co2_SH) / 2, floor(R$out$t), mean)
dec  <- function(x, yr) vapply(SF_DECADES, function(d) mean(x[yr >= d & yr < d + 10L]), 0)
FL <- lapply(RUNS, function(z) flux(z$r))
yr <- FL$shipped$year; stopifnot(all(vapply(FL, function(f) identical(f$year, yr), TRUE)))
D <- list(all = list(land = FL$shipped$land - FL$redesign$land, ocean = FL$shipped$ocean - FL$redesign$ocean),
          limb = list(land = FL$shipped_landoff$land - FL$redesign_landoff$land, ocean = FL$shipped_landoff$ocean - FL$redesign_landoff$ocean))
D$landterm <- list(land = D$all$land - D$limb$land, ocean = D$all$ocean - D$limb$ocean)
TAB <- do.call(rbind, lapply(names(D), function(k) rbind(
  stats::setNames(dec(D[[k]]$land, yr), paste0(SF_DECADES, "s")), stats::setNames(dec(D[[k]]$ocean, yr), paste0(SF_DECADES, "s")))))
rownames(TAB) <- c("all: land", "all: ocean", "limb only: land", "limb only: ocean", "land term: land", "land term: ocean")
cat("\nSHIPPED minus DETRENDED: the calendar-year fluxes (GtC/yr, positive = more UPTAKE under the shipped index), decadal means\n")
print(round(TAB, 3))
C <- lapply(RUNS, function(z) co2(z$r))
CO2 <- rbind(all = C$shipped[as.character(SF_CO2_YRS)] - C$redesign[as.character(SF_CO2_YRS)],
             limb_only = C$shipped_landoff[as.character(SF_CO2_YRS)] - C$redesign_landoff[as.character(SF_CO2_YRS)])
CO2 <- rbind(CO2, land_term = CO2["all", ] - CO2["limb_only", ])
cat("\nSHIPPED minus DETRENDED: global CO2 (ppm), annual mean\n"); print(round(CO2, 3))
saveRDS(list(table = TAB, co2 = CO2, diffs = D, years = yr, provenance = list(driver = SF_DRIVER, commit = COMMIT, mode_b = SF_MODE_B,
             mode_b_md5 = unname(tools::md5sum(SF_MODE_B)), indices = SF_INDICES, land_names = SF_LAND, decades = SF_DECADES,
             date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none", units = "GtC/yr (fluxes, + = uptake), ppm")), paste0(SF_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", SF_OUT))
sink()
