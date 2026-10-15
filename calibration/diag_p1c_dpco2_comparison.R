# =====================================================================
# diag_p1c_dpco2_comparison.R -- P1c, RUN AS A REPORTED COMPARISON.
#
# RULINGS TAKEN (Marcus, 2026-09-09r):
#   A -> A1: the model's SH `ml` box is compared against the observation
#            aggregated the SAME WAY THE MODEL'S OWN DRIVER WAS -- the whole
#            SH ocean, 0-90 S. It is the only mapping that needs no invented
#            latitude, and `like_for_like_forcing` applied to aggregation.
#            ⭐ A2 (GATE S's 40-90 S band) is reported ALONGSIDE, for
#            reference only -- it was DECLINED as the primary because a gate
#            chosen because the model will pass it is not a gate.
#   B -> B2: the quantity is the AIR-SEA dpCO2 (ocean minus atmosphere),
#            GATE S's own quantity, so amplitude and phase come from ONE
#            quantity rather than two.
#
# ⛔ THIS IS A COMPARISON, NOT A GATE. The expected outcome is that A1 FAILS
# on phase, and that failure would be a true statement about the model's BOX
# STRUCTURE -- one SH surface box cannot carry two antiphase regimes -- and
# NOT a falsification of entrainment. A gate is the wrong instrument for
# reporting that, so nothing here returns a verdict.
#
# ⭐ THE ESTIMATOR IS NOT A FREE CHOICE (2026-09-09q). The model's `ml` is a
# SINGLE WELL-MIXED BOX, whose concentration is the AREA MEAN -- and for a
# box the area mean of the anomaly IS the anomaly of the area mean. So the
# observation is reduced AREA-MEAN-FIRST and only then harmonically, never
# as a mean of per-cell amplitudes (which is phase-blind and would erase the
# very cancellation the box cannot avoid). Same convention as GATE S.
#
# ⚠ THE MODEL SIDE IS RECORDED, NOT RECOMPUTED. `pco2_ml` comes back through
# ccx_deriv(record = TRUE), because reconstructing it outside the deriv would
# be a SECOND ESTIMATOR free to drift (the seasonal SST construction, the
# seasonal mixed-layer mass and the frozen-Revelle branch all feed it).
# ⛔ AND IT IS READ FROM A SETTLED TRANSIENT, NEVER FROM THE SPINUP STATE:
# the spinup is aseasonal, so at a midwinter step its mixed layer is 1.68x
# its mean mass while its carbon is still the annual-mean value, and pCO2
# reads ~138 uatm instead of ~280. That is an initialization transient, not
# the model's seasonal cycle.
#
# Usage:  Rscript calibration/diag_p1c_dpco2_comparison.R
# =====================================================================
suppressPackageStartupMessages(library(ncdf4))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

TAG      <- "20260909"
OUT_RDS  <- file.path("outputs", "diagnostics", paste0("p1c_dpco2_", TAG, ".rds"))
OUT_LOG  <- sub("[.]rds$", ".log", OUT_RDS)
SP_PCO2  <- "data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc"
SPIN_YRS <- c(1900, 1995)     # long enough for the seasonal cycle to settle
READ_YR  <- 1994              # the year actually read, well inside the run
A1_BAND  <- c(-90, 0)         # THE RULING: the whole SH ocean
A2_BAND  <- c(-90, -40)       # GATE S's band, reference only

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

## ---- the one estimator, used on both sides --------------------------------
harm   <- function(x) { tt <- (seq_len(12) - 0.5) / 12
                        c(a = 2 * mean(x * sin(2 * pi * tt)),
                          b = 2 * mean(x * cos(2 * pi * tt))) }
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[["a"]], v[["b"]]) / (2 * pi)) %% 1)
awt    <- function(lat, d) abs(sin((lat + d/2) * pi/180) - sin((lat - d/2) * pi/180))
dmo    <- function(a, b) { d <- (a - b) %% 12; min(d, 12 - d) }

## ---- OBSERVED: ocean pCO2 (area-mean first) minus atmospheric CO2 ----------
nc <- nc_open(SP_PCO2); plat <- ncvar_get(nc, "lat")
pco2 <- ncvar_get(nc, "pco2"); nc_close(nc); dlat <- abs(diff(plat)[1])
band_series <- function(br) {
  sel <- which(plat >= br[1] & plat < br[2]); w <- awt(plat[sel], dlat)
  vapply(seq_len(12), function(m) { sl <- pco2[, sel, m]; ok <- is.finite(sl)
    wm <- matrix(rep(w, each = nrow(sl)), nrow = nrow(sl))
    sum(sl[ok] * wm[ok]) / sum(wm[ok]) }, numeric(1))
}
# ATMOSPHERIC side: the observed SPO CO2 first harmonic, in the SAME (a, b)
# convention -- ccx_prepare_obs()'s own per-year fit, averaged over its record.
obs   <- ccx_prepare_obs()
atm_v <- c(a = obs$co2_seas$SPO$a_mean, b = obs$co2_seas$SPO$b_mean)

say("P1c -- AIR-SEA dpCO2, MODEL vs OBSERVATION. ⛔ A COMPARISON, NOT A GATE.")
say("rulings: A1 (SH 0-90 S, the driver's own aggregation) is PRIMARY; A2 (40-90 S) is REFERENCE.")
say("quantity: dpCO2 = ocean pCO2 - atmospheric CO2, GATE S's own quantity (ruling B2).")
say("estimator: AREA-MEAN first, then ONE harmonic -- a well-mixed box has an area-mean")
say("           concentration, so a per-cell amplitude mean is the WRONG reduction.")
say("")
say("observed atmospheric SPO harmonic: amp %.3f ppm, peak month %.2f (n = %d yr)",
    amp(atm_v), ang_mo(atm_v), obs$co2_seas$SPO$n_years)

obs_rows <- lapply(list(A1 = A1_BAND, A2 = A2_BAND), function(br) {
  oc <- harm(band_series(br))
  dp <- c(a = oc[["a"]] - atm_v[["a"]], b = oc[["b"]] - atm_v[["b"]])
  list(band = br, ocean = oc, dpco2 = dp)
})

## ---- MODEL: pco2_ml recorded from a SETTLED transient ---------------------
md <- readRDS(ccx_mode_file())
p0 <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))
p0$seas_drivers <- 1
model_dpco2 <- function(seas_ml) {
  p  <- p0; p$seas_ml <- seas_ml
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", SPIN_YRS, prod_c14 = sp$prod_c14)
  i0 <- which(floor(F$t) == READ_YR)[1]
  # integrate up to the read year with the model's own stepper, then walk 12
  # months recording at each OPENING state (the flux-trace convention).
  y  <- sp$y; ns <- ccx_resolve_substeps("auto", p, sp$grid)
  for (i in seq_len(i0 - 1L))
    y <- ccx_step_rk4(y, F$t[i], 1/12, p, ccx_forcing_at(F, i), sp$grid, sp$aux, ns)
  out <- lapply(HEMIS, function(h) numeric(12)); names(out) <- HEMIS
  chi <- out
  for (k in seq_len(12)) {
    i <- i0 + k - 1L
    d <- ccx_deriv(y, F$t[i], p, ccx_forcing_at(F, i), sp$grid, sp$aux, record = TRUE)
    fx <- attr(d, "fluxes")
    for (h in HEMIS) {
      out[[h]][k] <- fx$pco2_ml[[h]]
      chi[[h]][k] <- y[sp$aux$idx[[h]]$atm, "C"] / sp$aux$gtc_per_ppm_hemi
    }
    y <- ccx_step_rk4(y, F$t[i], 1/12, p, ccx_forcing_at(F, i), sp$grid, sp$aux, ns)
  }
  lapply(HEMIS, function(h) list(pco2 = out[[h]], chi = chi[[h]],
                                 dpco2 = harm(out[[h]] - chi[[h]])))
}
say("")
say("running the model (spinup + %d yr, R core, both arms) ...", diff(SPIN_YRS))
m_off <- model_dpco2(0); names(m_off) <- HEMIS
m_on  <- model_dpco2(1); names(m_on)  <- HEMIS

## ---- the comparison --------------------------------------------------------
say("")
say("SH dpCO2 -- amplitude (uatm) and peak month")
say("  %-34s %10s %10s", "", "amp", "peak mo")
say("  %-34s %10.2f %10.2f", "MODEL, seas_ml = 0", amp(m_off$SH$dpco2), ang_mo(m_off$SH$dpco2))
say("  %-34s %10.2f %10.2f", "MODEL, seas_ml = 1", amp(m_on$SH$dpco2),  ang_mo(m_on$SH$dpco2))
for (k in names(obs_rows)) {
  o <- obs_rows[[k]]
  say("  %-34s %10.2f %10.2f",
      sprintf("OBS %s (%d to %d S)%s", k, abs(o$band[2]), abs(o$band[1]),
              if (k == "A1") "  <- THE RULING" else "  (reference)"),
      amp(o$dpco2), ang_mo(o$dpco2))
}
a1 <- obs_rows$A1$dpco2; a2 <- obs_rows$A2$dpco2
say("")
say("AGAINST THE RULED TARGET (A1, the whole SH ocean):")
say("  amplitude  model %.2f vs obs %.2f  -> ratio %.2f", amp(m_on$SH$dpco2), amp(a1),
    amp(m_on$SH$dpco2) / amp(a1))
say("  phase      model %.2f vs obs %.2f  -> %.2f months apart",
    ang_mo(m_on$SH$dpco2), ang_mo(a1), dmo(ang_mo(m_on$SH$dpco2), ang_mo(a1)))
say("FOR REFERENCE ONLY (A2, GATE S's 40-90 S band):")
say("  amplitude  ratio %.2f | phase %.2f months apart",
    amp(m_on$SH$dpco2) / amp(a2), dmo(ang_mo(m_on$SH$dpco2), ang_mo(a2)))
say("")
say("⛔ NO VERDICT IS RETURNED. If the model sits close to A2 and far from A1, that is the")
say("   STRUCTURAL finding the ruling was expected to expose: a LOW-LATITUDE box (84 %% of")
say("   the SH ocean) carrying a HIGH-LATITUDE seasonal cycle, because the MLD climatology")
say("   driving it is an SH-wide mean dominated by high-latitude winter mixing. It would")
say("   NOT be a falsification of entrainment.")
say("⚠ The two observed regimes are ANTIPHASE (subtropics peak Jan, Southern Ocean Jul-Aug),")
say("   so A1's amplitude is a 4.4x CANCELLATION of A2's and is fragile by construction.")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode = CCX_MODE_CANONICAL, read_year = READ_YR, obs = obs_rows,
             atm = atm_v, model_off = m_off, model_on = m_on, built = Sys.time()), OUT_RDS)
say("")
say("wrote %s", OUT_RDS)
close(con)
