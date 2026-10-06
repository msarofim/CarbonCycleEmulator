# =====================================================================
# diag_pulse_land_attribution.R -- WHY does the model's CO2 pulse decay faster
# than Joos et al. (2013)? Asked by Marcus 2026-09-27 (d): "I don't want to make
# the carbon-cycle pulse decay a calibration target, but if you can figure out
# why my pulses decay faster than Joos or FaIR, that might guide our next
# improvement."
#
# ⚠ STATUS: an ATTRIBUTION, NOT A PROPOSAL. Every knock-out below changes ONE
# parameter from JOOS_REF_YEAR onward with every other coordinate FROZEN at the
# mode. A refit would move the others -- e.g. with the vegetation loop off the
# optimiser would likely raise beta_max to recover the historical land sink --
# so no row here predicts where a refit lands ([[sens_scan_achievable]]). What
# the table establishes is WHICH mechanism carries the gap, not what fixing it
# would cost.
#
# THE PROTOCOL is Joos PD100, identical to diag_joos_irf.R: historical run to
# 2010, CO2 held by diagnosed emissions, 100 GtC released at 2015 through
# ccx_irf_pd()'s construction. Each knock-out RE-DIAGNOSES its own held
# background, and the realised hold deviation is printed per row.
#
# THE BENCHMARK FOR THE SPLIT is Joos et al. 2013 sec.3.2 ("Response in ocean
# and land carbon"), multi-model mean +/- 1 sd, PD100, ACP 13:2793, pp.2806-2807
# (PDF in ~/Documents/2026/ClaudeDocs/Papers/, read 2026-09-27):
#   ocean 20 +/- 7 GtC by yr 20, 33 +/- 12 by 100, 59 +/- 12 by 1000
#   land  19 +/- 16 GtC by yr 20, 23 +/- 20 by 100, 16 +/- 14 by 1000
# ⚠ Joos's land includes each model's climate-carbon feedback (their Fig. 3b
# has ensemble members that LOSE land carbon to a pulse); the held-GMST rows
# here do not, which is why row B adds the pulse's own warming.
#
# USAGE: Rscript calibration/diag_pulse_land_attribution.R canonical
# RUNTIME ~1 min (eight re-held backgrounds x 1000 yr).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ATTR_COMMIT <- ccx_git_stamp()
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
ATTR_HORIZON <- 1000                      # yr after release
ATTR_MARKS   <- c(20, 100, 300, 1000)     # yr after release, printed columns
ATTR_Q10_BOUND <- 2                       # q10 for the warming-feedback BOUND row;
                                          # an illustrative ceiling, not a proposal
ATTR_FERTK_SAT <- 120                     # ppm; the 2026-08-14 shortlist cell
                                          # (ccx_saturating_fert), not a fit
JOOS_SPLIT <- data.frame(yr = c(20, 100, 1000),
                         ocean = c(20, 33, 59), ocean_sd = c(7, 12, 12),
                         land  = c(19, 23, 16), land_sd  = c(16, 20, 14))
JOOS_SPLIT_SRC <- "Joos et al. 2013 ACP 13:2793, sec.3.2 pp.2806-2807, multi-model mean +/- 1 sd"

# ---- the arm: same contract as diag_joos_irf.R (no default) ----------
ATTR_ARM <- commandArgs(TRUE)[1]
if (is.na(ATTR_ARM) || !nzchar(ATTR_ARM))
  stop("diag_pulse_land_attribution.R needs an ARM ('canonical', or a name in CCX_MODE_FILES); there is no default.")
ATTR_ARM_ASKED <- ATTR_ARM
if (identical(ATTR_ARM, "canonical")) ATTR_ARM <- CCX_MODE_CANONICAL
.md <- readRDS(ccx_mode_file(ATTR_ARM))
.pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(.md))
# ccx_overlay_par() migrates, copies, repairs ENSO and ASSERTS nothing was
# deleted -- the bare intersect() copy loop is linted (test-overlay-idiom-lint.R).
p0  <- ccx_overlay_par(ccx_mode_base(.md), .pm)
p0$pump_mode <- .md$pump_mode

cat(sprintf("=== PROVENANCE ===\n  arm %s [asked '%s', resolved %s], logpost %.2f, commit %s\n",
            ATTR_ARM, ATTR_ARM_ASKED, format(Sys.Date()), .md$logpost,
            ATTR_COMMIT))
cat(sprintf("  protocol: Joos PD100 -- CO2 held from %d, %d GtC released %d, GMST held unless stated\n",
            JOOS_REF_YEAR, JOOS_PULSE, JOOS_PULSE_YR))
cat(sprintf("  units: GtC of the pulse in each reservoir (pulse run minus its own paired base run)\n"))
cat(sprintf("  split benchmark: %s\n", JOOS_SPLIT_SRC))
cat(sprintf("  land params at mode: beta_max %.4f fert_k %.1f q10 %.3f | UNFITTED: npp_veg_frac %.2f litter_slow_frac %.3f tau_wood %.0f tau_soil_slow %.0f\n",
            p0$beta_max, p0$fert_k, p0$q10, p0$npp_veg_frac, p0$litter_slow_frac, p0$tau_wood, p0$tau_soil_slow))

spin <- ccx_spinup(p0)
F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14,
                            bomb_total_kmol = .pm$bomb_total, luc_scale = .pm$luc_scale)
sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, F_hist)$state
F_fwd <- suppressWarnings(ccx_build_forcing("historical",
           c(JOOS_REF_YEAR, JOOS_PULSE_YR + ATTR_HORIZON + 1), prod_c14 = spin$prod_c14,
           bomb_total_kmol = 0, luc_scale = .pm$luc_scale))
for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso", "c14_bomb", "c14_nuclear"))
  F_fwd[[cc]] <- 0
F_fwd$gmst <- F_fwd$gmst[1]
mod <- ccx_climate_module()
co2_of <- function(o) (o$co2_NH + o$co2_SH) / 2

# The pulse's own warming: annual dERF -> the FaIR-fitted 3-timescale IRF.
# A ZERO year is prepended so the response starts from rest; without it
# ccx_temperature_from_erf()'s T - T[1] fallback subtracts the first year's
# response from every year (a 2.7x understatement, caught in the 09-27 probe).
pulse_dT <- function(t_abs, co2b, co2q) {
  yrs <- floor(t_abs); uy <- unique(yrs); ann <- function(v) as.numeric(tapply(v, yrs, mean))
  dE  <- c(0, ccx_erf_co2(ann(co2q), mod) - ccx_erf_co2(ann(co2b), mod))
  dTa <- ccx_temperature_from_erf(dE, c(uy[1] - 1, uy), mod, baseline = c(-Inf, -Inf))[-1]
  dTa[match(yrs, uy)]
}

run_case <- function(over = list(), warm = FALSE, pools = FALSE) {
  s <- sp_ref; for (n in names(over)) s$params[[n]] <- over[[n]]
  Fh  <- ccx_hold_forcing(s, F_fwd)
  pre <- Fh$t < JOOS_PULSE_YR
  s$y <- ccx_run_fast(s, Fh[pre, , drop = FALSE])$state
  Fr  <- Fh[!pre, , drop = FALSE]; t <- Fr$t - Fr$t[1]
  sq  <- ccx_pulse_state(s, JOOS_PULSE)
  b <- ccx_run_fast(s, Fr)$out; q <- ccx_run_fast(sq, Fr)$out
  dT <- rep(0, length(t))
  if (warm) { dT <- pulse_dT(Fr$t, co2_of(b), co2_of(q)); Fq <- Fr; Fq$gmst <- Fq$gmst + dT
              q <- ccx_run_fast(sq, Fq)$out }
  r <- list(t = t, atm = (co2_of(q) - co2_of(b)) * JOOS_PPM_PER,
            ocn = q$ocean_C - b$ocean_C, lnd = q$land_C - b$land_C, dT = dT,
            dev = attr(Fh, "dev"))
  joos_release_check(list(t = t, irf = r$atm / JOOS_PULSE))
  if (pools) r$pools <- t(sapply(ATTR_MARKS, function(y) {
    k <- t <= y
    pl <- function(sp) { st <- ccx_run_fast(sp, Fr[k, , drop = FALSE])$state
      sapply(CCX_LAND_POOLS, function(p) sum(st[unlist(lapply(c("NH", "SH"), function(h) sp$aux$idx[[h]][[p]])), "C"])) }
    pl(sq) - pl(s) }))
  r
}
at <- function(r, v, y) r[[v]][which.min(abs(r$t - y))]
show <- function(lab, r) {
  cat(sprintf("%-36s", lab))
  for (y in ATTR_MARKS) cat(sprintf(" | %5.1f %5.1f %5.1f", at(r, "atm", y), at(r, "ocn", y), at(r, "lnd", y)))
  cat(sprintf("  hold %.2f ppm\n", r$dev))
}

cat(sprintf("\n=== 1. THE SPLIT, AND WHAT CARRIES THE GAP (atm ocean land, GtC) ===\n%-36s", ""))
for (y in ATTR_MARKS) cat(sprintf(" | %17s", sprintf("yr %d", y))); cat("\n")
r0 <- run_case(pools = TRUE); show("A  shipped mode (GMST held)", r0)
rn <- run_case(list(npp_veg_frac = p0$npp_veg_frac))
stopifnot(max(abs(rn$lnd - r0$lnd)) < 1e-9)     # re-setting a param to itself is a no-op
show("A' null: npp_veg_frac re-set to itself", rn)
rw <- run_case(warm = TRUE); show("B  + the pulse's own warming", rw)
rq <- run_case(list(q10 = ATTR_Q10_BOUND), warm = TRUE)
show(sprintf("B2 + warming, q10 = %g (a BOUND)", ATTR_Q10_BOUND), rq)
rv <- run_case(list(npp_veg_frac = 0)); show("C  vegetation-capacity loop OFF", rv)
rs <- run_case(list(litter_slow_frac = 0)); show("D  no litter to the slow soil", rs)
chi_ref <- mean(co2_of(ccx_run_fast(sp_ref, ccx_hold_forcing(sp_ref, F_fwd))$out)[1:12]) - ccx_const("CO2_PI_PPM")
enh  <- p0$beta_max * chi_ref / (p0$fert_k + chi_ref)
bmS  <- enh * (ATTR_FERTK_SAT + chi_ref) / chi_ref
re <- run_case(list(fert_k = ATTR_FERTK_SAT, beta_max = bmS))
show(sprintf("E  fert_k %g, beta_max %.3f", ATTR_FERTK_SAT, bmS), re)
cat(sprintf("%-36s", "   Joos 2013 multi-model mean"))
for (y in ATTR_MARKS) { j <- JOOS_SPLIT[JOOS_SPLIT$yr == y, ]
  cat(if (nrow(j)) sprintf(" | %5.1f %5.1f %5.1f", 100 * joos_irf(y), j$ocean, j$land) else sprintf(" | %5.1f %11s", 100 * joos_irf(y), "")) }
cat(sprintf("\n%-36s", "   (+/- 1 sd)"))
for (y in ATTR_MARKS) { j <- JOOS_SPLIT[JOOS_SPLIT$yr == y, ]
  cat(if (nrow(j)) sprintf(" | %5s %5.0f %5.0f", "", j$ocean_sd, j$land_sd) else sprintf(" | %17s", "")) }
cat("\n   (Joos atm = 100 x the Table 5 IRF fit; the split and the IRF are different\n")
cat("    model subsets, so atm + ocean + land need not sum to 100 on that row)\n")
cat(sprintf("\n   B's warming, dT @ %s yr = %s K (CCX's FaIR-fitted module)\n",
            paste(ATTR_MARKS, collapse = "/"),
            paste(sprintf("%.3f", sapply(ATTR_MARKS, function(y) at(rw, "dT", y))), collapse = " / ")))
cat(sprintf("   E holds the NPP enhancement at the held %.1f ppm fixed (%.4f); its slope there is %.2fx A's\n",
            chi_ref + ccx_const("CO2_PI_PPM"), enh,
            (bmS * ATTR_FERTK_SAT / (ATTR_FERTK_SAT + chi_ref)^2) / (p0$beta_max * p0$fert_k / (p0$fert_k + chi_ref)^2)))

cat("\n=== 2. WHERE THE LAND'S SHARE SITS, shipped mode (GtC) ===\n")
cat(sprintf("%6s %s %8s\n", "yr", paste(sprintf("%10s", CCX_LAND_POOLS), collapse = ""), "total"))
for (i in seq_along(ATTR_MARKS))
  cat(sprintf("%6d %s %8.2f\n", ATTR_MARKS[i], paste(sprintf("%10.2f", r0$pools[i, ]), collapse = ""), sum(r0$pools[i, ])))

cat("\n=== 3. THE LOOP'S GAIN, from the model's own structure ===\n")
cat("  NPP = npp0 [(1 - phi) + phi veg/veg0] f(CO2). At equilibrium veg ∝ NPP, so a\n")
cat("  sustained fertilisation factor f = 1 + e gives dNPP/NPP0 = e / (1 - phi):\n")
cat(sprintf("  phi = %.2f  =>  the land's equilibrium CO2 response is x%.2f what fertilisation alone gives,\n",
            p0$npp_veg_frac, 1 / (1 - p0$npp_veg_frac)))
cat(sprintf("  and it builds on the vegetation timescale (tau_wood = %.0f yr).\n", p0$tau_wood))
