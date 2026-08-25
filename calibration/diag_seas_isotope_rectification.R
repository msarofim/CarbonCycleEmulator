# =====================================================================
# diag_seas_isotope_rectification.R -- THE SEASONAL NEP FLUX DISCRIMINATES ON
#                                      BOTH HALVES OF ITS CYCLE. (2026-08-25d)
#
# WHAT IS WRONG, IN ONE LINE. R/model.R:1040 emits the seasonal land flux as
#
#     add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo, lab = "seas")
#
# `seas` is ZERO-MEAN by construction (model.R:1030, `npp * (insol/n - 1)`), so
# it is NEGATIVE for half of every year. add_flux (model.R:825) handles a
# negative flux by SWAPPING THE SOURCE BOX -- "for a negative flux the source is
# `to`" -- but it keeps applying `alpha13`. So the carbon coming BACK out of the
# leaf pool in autumn is discriminated a SECOND time, at the leaf's own ratio.
#
# Photosynthesis discriminates. Respiration does not.
#
# THE REST OF THE FILE ALREADY KNOWS THIS. Twelve lines earlier, model.R:980-983
# emits gross photosynthesis and autotrophic respiration as TWO one-way fluxes --
# `add_flux(iatm, ilef, npp_leaf + ra_leaf, alpha13 = alpha_photo)` down and
# `add_flux(ilef, iatm, ra_leaf)` back up with NO alpha, commented "at leaf's
# ratio". Air-sea does the same with its two gross limbs and their two separate
# alphas. `seas` is the ONE alpha-carrying flux in the model that changes sign,
# and it is the one that did not get the two-limb treatment.
#
# ---------------------------------------------------------------------
# PART 1 IS THE RECEIPT AND IT NEEDS NO MODEL AT ALL. A closed two-box system,
# one zero-mean sinusoidal exchange, nothing else: carbon must return exactly,
# and so must d13C. Carbon does (2e-13 GtC). d13C does not -- it is pumped out
# of box 1 at a fixed rate PER CYCLE. That is a rectification artifact of the
# sign handling, not a property of any parameter, and no reading of the flux
# permits it:
#
#   * read `seas` as real bidirectional NEP -- then the autumn limb is
#     respiration, the source ratio is the leaf's (which add_flux gets right)
#     and there must be NO alpha;
#   * read it as a MODULATION of gross photosynthesis -- then alpha is right and
#     the source ratio must be the ATMOSPHERE's, which add_flux does not do.
#
# The two corrections coincide to first order, because the leaf pool sits at
# r_atm * alpha anyway; they differ only by the leaf's own Suess disequilibrium
# (~1 permil today). WHICH ONE TO ADOPT IS A MODELLING CHOICE AND IS MARCUS'S.
# This file implements the first (matching the Ra limb twelve lines above) to
# MEASURE the size of the effect, and changes nothing in R/ or src/.
#
# WHY NO TEST CAUGHT IT, which is the part worth keeping:
#   * 13C CONSERVATION CANNOT SEE IT. add_flux is antisymmetric by construction
#     (`dy[from] -= f13; dy[to] += f13`), so total 13C is conserved for ANY
#     alpha. The bug is a MIS-PARTITION, not a leak, and a conservation gate is
#     structurally blind to it.
#   * R<->C++ PARITY CANNOT SEE IT. src/ccx_core.cpp:258-264 and :370 implement
#     exactly the same rule, so both cores are wrong together.
#   * AND BOTH SUITES SWITCH THE FLUX OFF. test-conservation.R:82 and
#     test-parity.R:72/151 set `seas_drivers <- 0`. The two tests that could
#     have had power over the seasonal isotope path disable it.
#   memory no_power_null / two_statistics_can_be_blind.
#
# RUNTIME ~3 min (two full R-path historical runs; the C++ core cannot be
# patched from here, so PART 2 uses ccx_run()).
#
# Usage:  Rscript calibration/diag_seas_isotope_rectification.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants ------------------------------------------------
REC_R13      <- ccx_const("R13_VPDB")
REC_ALPHA    <- 1 - 18 / 1000        # = model.R:1529 alpha_photo
REC_NCYC     <- 50                   # cycles in the closed-box receipt
REC_NSTEP    <- 12000
REC_F_AMP    <- 60                   # GtC/yr, the toy's exchange amplitude
REC_C0       <- c(atm = 600, leaf = 300)
REC_MODE     <- "calibration/output/pump_arms/mode_fit_pumpN.rds"
REC_YEARS    <- c(1750, 2024)
OUTDIR       <- ccx_path("calibration", "output", "seas_isotope")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

# =====================================================================
# PART 1 -- the closed-box receipt. No model, no parameters, no fitting.
# =====================================================================
rec_closed_box <- function(shipped) {
  C   <- REC_C0
  C13 <- C * REC_R13 * c(1, REC_ALPHA)      # leaf starts AT photosynthetic equilibrium
  dt  <- REC_NCYC / REC_NSTEP
  for (i in seq_len(REC_NSTEP)) {
    F   <- REC_F_AMP * sin(2 * pi * (i - 0.5) * dt)     # ZERO MEAN, closes exactly
    src <- if (F > 0) 1L else 2L                        # add_flux's own rule
    a   <- if (shipped) REC_ALPHA else if (F > 0) REC_ALPHA else 1
    f13 <- F * (C13[src] / C[src]) * a
    C   <- C   + dt * c(-F, F)
    C13 <- C13 + dt * c(-f13, f13)
  }
  d13 <- (C13 / C / REC_R13 - 1) * 1000
  c(dC_atm = unname(C[1] - REC_C0[[1]]), d13c_atm = unname(d13[1]),
    d13c_leaf = unname(d13[2]))
}
cat("=== PART 1: CLOSED TWO-BOX RECEIPT (no model, no parameters) ===\n")
cat(sprintf("%g GtC/yr zero-mean sinusoid between two boxes, %d cycles, nothing else.\n",
            REC_F_AMP, REC_NCYC))
cat("Carbon must return to its start. So must d13C.\n\n")
cat(sprintf("%-24s %14s %14s %14s\n", "", "dC_atm (GtC)", "d13C_atm", "d13C_leaf"))
REC <- list()
for (sh in c(TRUE, FALSE)) {
  r <- rec_closed_box(sh); REC[[if (sh) "shipped" else "fixed"]] <- r
  cat(sprintf("%-24s %+14.2e %+14.3f %+14.3f\n",
              if (sh) "AS SHIPPED" else "alpha on uptake only",
              r[["dC_atm"]], r[["d13c_atm"]], r[["d13c_leaf"]]))
}
cat(sprintf("\nSHIPPED DRIFT: %+.4f permil per cycle, with carbon closing to %.0e GtC.\n",
            REC$shipped[["d13c_atm"]] / REC_NCYC, abs(REC$shipped[["dC_atm"]])))
cat("The atmosphere is pumped light and the leaf pool heavy, every year, forever.\n")

# =====================================================================
# PART 2 -- what it costs the real model, at the adopted mode
# =====================================================================
# The C++ core carries the same rule and cannot be patched from R, so both arms
# run through ccx_run(). Its equality with ccx_run_fast() on the SHIPPED arm is
# GATE 1: if the R path did not reproduce the C++ numbers this comparison would
# be measuring the integrator, not the fix.
rec_patch_globally <- function() {
  src <- readLines(ccx_path("R", "model.R"))
  k <- grep('add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo, lab = "seas")',
            src, fixed = TRUE)
  if (length(k) != 1L)
    stop("R/model.R seasonal-flux anchor not found (", length(k), " matches) -- the line ",
         "moved; re-read it before trusting anything below.")
  src[k] <- sub("alpha13 = aux$alpha_photo",
                "alpha13 = if (seas > 0) aux$alpha_photo else 1", src[k], fixed = TRUE)
  tf <- tempfile(fileext = ".R"); writeLines(src, tf)
  # INTO THE GLOBAL ENV, deliberately, and therefore ONE-WAY: ccx_run() resolves
  # ccx_deriv() through its own enclosure, so sourcing the patch into a private
  # environment does NOT reach it. The first draft did exactly that, both arms
  # silently ran the SHIPPED code, and the "CO2 must be identical" gate passed
  # for the wrong reason -- a gate that cannot fail (memory mutation_test_gates).
  # Hence GATE 2 below, which asserts the arms DIFFER.
  sys.source(tf, envir = globalenv())
  invisible(tf)
}
rec_run <- function() {
  md <- readRDS(ccx_path(REC_MODE)); pv <- md$par_mode
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", REC_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale)
  o  <- ccx_run(sp, F)$out
  err <- list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
              grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c)
  list(out = o, streams = unlist(ccx_loglik(o, OBS, err,
        luc = ccx_forcing_eluc_annual(F), deep = sp$diagnostics$d14c_bottom_box,
        ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)))
}
OBS <- ccx_prepare_obs()
cat("\n\n=== PART 2: THE REAL MODEL AT THE ADOPTED MODE ===\n")
cat("(both arms via ccx_run(); the C++ core shares the rule and cannot be patched here)\n\n")
S <- list()
S$shipped <- rec_run()            # SHIPPED FIRST -- the patch below is one-way
rec_patch_globally()
S$fixed <- rec_run()

rec_amp <- function(o) {
  ms <- ccx_model_stats(o, OBS)
  do.call(rbind, lapply(c("MLO", "SPO"), function(st) {
    oc <- OBS$co2_seas[[st]]; mc <- ms$co2_seas[[st]]
    od <- OBS$d13_seas[[st]]; mm <- ms$d13_seas[[st]]
    Am <- mean(sqrt(mc$a[match(oc$year, mc$year)]^2 + mc$b[match(oc$year, mc$year)]^2))
    Dm <- mean(sqrt(mm$a[match(od$year, mm$year)]^2 + mm$b[match(od$year, mm$year)]^2))
    Ao <- mean(sqrt(oc$a^2 + oc$b^2)); Do <- mean(sqrt(od$a^2 + od$b^2))
    data.frame(station = st, co2 = Am / Ao, d13c = Dm / Do, perppm = (Dm / Am) / (Do / Ao))
  }))
}
AS <- rec_amp(S$shipped$out); AF <- rec_amp(S$fixed$out)
cat(sprintf("%-10s %-5s %12s %12s %12s\n", "arm", "stn", "CO2 mod/obs", "d13C mod/obs",
            "per-ppm m/o"))
for (nm in c("shipped", "fixed")) { a <- if (nm == "shipped") AS else AF
  for (i in seq_len(nrow(a))) with(a[i, ],
    cat(sprintf("%-10s %-5s %11.2fx %11.2fx %11.2fx\n", nm, station, co2, d13c, perppm))) }

# ---- GATE 1: the fix touches NO carbon -------------------------------
cat("\nGATE 1: the fix moves no carbon, so the CO2 column must be IDENTICAL.\n")
stopifnot(isTRUE(all.equal(AS$co2, AF$co2, tolerance = 1e-10)))
cat("GATE 1 PASS.\n")
# ---- GATE 2: ... and the patch must actually have taken effect --------
cat("GATE 2: the d13C column must DIFFER, or the patch never ran.\n")
stopifnot(max(abs(AS$d13c - AF$d13c)) > 1e-6)
cat(sprintf("GATE 2 PASS (max |d13C shipped - fixed| = %.3f).\n",
            max(abs(AS$d13c - AF$d13c))))

d <- S$fixed$streams[names(S$shipped$streams)] - S$shipped$streams
cat(sprintf("\nPER-STREAM logL change from the fix (total %+.1f):\n", sum(d)))
for (nm in names(sort(d, decreasing = TRUE))) if (abs(d[[nm]]) >= 0.5)
  cat(sprintf("  %-22s %10.1f -> %10.1f  %+9.1f\n", nm, S$shipped$streams[[nm]],
              S$fixed$streams[[nm]], d[[nm]]))

saveRDS(list(closed_box = REC, streams_shipped = S$shipped$streams,
             streams_fixed = S$fixed$streams,
             amp_shipped = rec_amp(S$shipped$out), amp_fixed = rec_amp(S$fixed$out)),
        file.path(OUTDIR, "seas_isotope_rectification.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "seas_isotope_rectification.rds")))
