# =====================================================================
# diag_conveyor_enso_lever.R -- IS THE CONVEYOR A BIG ENOUGH LEVER, AND OF THE
# RIGHT SIGN, TO FIX THE OCEAN'S ENSO RESPONSE?
#
# THE QUESTION AND WHY IT IS ASKED THIS WAY. `diag_enso_model_vs_obs.R` measured
# the model's ocean sink ANTI-correlated with Nino3.4 (slope -0.109 GtC/yr per
# degC, r ~ -0.50) where the GCB product is +0.119. Reading the code explained
# it: ENSO enters ONLY as a land flux, the ocean feels it ONLY through SST, and
# the conveyor -- the one mechanism that could supply an upwelling response --
# is BUILT BUT OFF (`q_conv = 0`, not in CCX_PARAM_TABLE).
#
# ⛔ THE OBVIOUS NEXT STEP IS TO MAKE `q_conv` TIME-VARYING, AND IT IS THE WRONG
# ONE TO TAKE FIRST. `cg <- ccx_conveyor_geom(p, grid)` is resolved ONCE per run
# and `q_conv` lives in BOTH cores, so an ENSO-modulated conveyor means a new
# forcing column, R and C++ twins, a parity test, and an N_FORCING bump -- the
# exact change whose last instance read PAST the buffer with nothing raised
# ([[ccx_diffuse_light]]). MEASURE THE LEVER BEFORE BUILDING THE MACHINERY: a
# STATIC scan over `q_conv` gives d(ocean sink)/dQ, and that plus the slope gap
# says how large an ENSO modulation would have to be. If the answer is
# implausible, or the SIGN is wrong, no amount of plumbing helps.
#
# ⚠ THE MODEL'S CONVEYOR IS NOT THE CIRCULATION ENSO ACTUALLY MODULATES. It is
# an interhemispheric, NADW-style overturning (one hemisphere sinks, the other
# upwells); ENSO modulates EQUATORIAL Pacific upwelling. A two-box hemispheric
# model has no tropics, so this is a SURROGATE. It can answer "can an upwelling
# modulation of this magnitude flip the sign", which is a sufficiency question.
# It CANNOT establish that this is the right mechanism, and must not be reported
# as if it had.
#
# ⚠ AND THE COMBINATION UNDER TEST IS ITSELF UNTESTED: test-conveyor.R never
# sets `pump_grad` and test-pump.R never sets `q_conv`, so pump-and-conveyor
# together has no coverage. Carbon conservation is therefore CHECKED HERE at
# every point rather than assumed ([[default_off_hides_the_bug]]).
#
# ⛔ ADOPTS NOTHING. `q_conv` stays 0 in the shipped table.
#
# Usage:  Rscript calibration/diag_conveyor_enso_lever.R    # ~1 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_enso_regression.R"))

CL_MODE  <- "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds"
CL_Q     <- c(0, 1, 2, 5, 10, 15, 20)   # Sv; global overturning is ~20-30 Sv
CL_WIN   <- c(2015, 2023)               # = DG_SINK_WIN, so this is gate 7's quantity
# ⚠ 1750, NOT 1959. Starting the forcing at 1959 leaves 165.8 GtC of land-use
# carbon already emitted against preindustrial spinup stocks -- ccx_build_forcing()
# warns of exactly that -- and the resulting start-up transient would land inside
# the window being measured. This matches DG_YEARS, so the sinks here are the
# same construction the gates and the ENSO regression use.
CL_YRS   <- DG_YEARS
CL_CONS  <- 1e-6                        # GtC, carbon-conservation tolerance
# The gap to be closed, from diag_enso_model_vs_obs.R at this same mode:
CL_SLOPE_MODEL <- -0.155                # GtC/yr per degC, new basin
CL_SLOPE_OBS   <- +0.119                # GtC/yr per degC, GCB

cat(sprintf("\n%s\nIS THE CONVEYOR A BIG ENOUGH LEVER, AND OF THE RIGHT SIGN?\n  static scan over q_conv at the 08-31e mode. ADOPTS NOTHING.\n%s\n",
            strrep("=", 78), strrep("=", 78)))

v <- dg_vector(CL_MODE)
cat(sprintf("  vector: %s\n  conveyor geometry: conv_sink %s, reverse %s, descent %s\n",
            v$src, v$p$conv_sink, v$p$conv_reverse, v$p$conv_descent))

cl_run <- function(q) {
  p <- v$p; p$q_conv <- q
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", CL_YRS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  r  <- list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
  a  <- dg_annual_sinks(r)
  k  <- a$year >= CL_WIN[1] & a$year <= CL_WIN[2]
  # CARBON CONSERVATION, checked because this combination has no test coverage.
  o <- r$out
  tot <- o$co2_NH * 0 + rowSums(cbind(o$land_C, o$ocean_C))   # land + ocean stocks
  gtc <- ccx_const("GtC_PER_PPM")
  atm <- (o$co2_NH + o$co2_SH) / 2 * gtc
  el  <- ccx_forcing_eluc_annual(r$F)
  ef  <- stats::aggregate(list(e = r$F$e_foss_NH + r$F$e_foss_SH),
                          by = list(year = r$F$year), FUN = mean)
  emit <- sum(ef$e[ef$year >= min(a$year) & ef$year <= max(a$year)]) +
          sum(el$eluc[el$year >= min(a$year) & el$year <= max(a$year)])
  dstock <- (atm[length(atm)] - atm[1]) + (tot[length(tot)] - tot[1])
  list(q = q, ocean = mean(a$ocean[k]), land = mean(a$land[k]),
       deep = sp$diagnostics$d14c_bottom_box,
       co2 = (o$co2_NH[nrow(o)] + o$co2_SH[nrow(o)]) / 2,
       imbalance = dstock - emit,
       ocean_series = a$ocean, land_series = a$land, year = a$year)
}

S <- lapply(CL_Q, cl_run)
cat(sprintf("\n%-8s %11s %11s %12s %11s %13s\n",
            "q_conv", "ocean sink", "land sink", "deep D14C", "CO2 2024", "C imbalance"))
for (s in S)
  cat(sprintf("%6.1f Sv %11.3f %11.3f %12.2f %11.2f %13.2e\n",
              s$q, s$ocean, s$land, s$deep, s$co2, s$imbalance))

# ---- GATE: carbon must conserve with BOTH mechanisms on ---------------
# The imbalance is a DIFFERENCE of large stocks, so it is judged against the
# no-conveyor case rather than against zero: what must not change is the closure.
base_imb <- S[[1]]$imbalance
drift <- vapply(S, function(s) abs(s$imbalance - base_imb), numeric(1))
cat(sprintf("\nGATE carbon closure: worst departure from the q=0 case %.3e GtC over %d yr.\n",
            max(drift), diff(CL_YRS)))
# ⚠ BRACED. At TOP LEVEL R parses `if (...) expr` as complete and then meets a
# bare `else` -- "unexpected 'else'". I hit this earlier the same day, wrote the
# warning into run_dispersed_multistart.R, and then repeated it here.
if (max(drift) > CL_CONS) {
  cat("*** WARNING: the conveyor changes the carbon closure. The pump+conveyor\n    combination has NO test coverage; treat every number above as suspect.\n")
} else {
  cat("  within tolerance -- the untested pump+conveyor combination conserves.\n")
}

# ---- THE LEVER -------------------------------------------------------
q  <- vapply(S, `[[`, numeric(1), "q")
oc <- vapply(S, `[[`, numeric(1), "ocean")
d_dq <- coef(lm(oc ~ q))[[2]]
cat(sprintf("\n%s\nTHE LEVER\n%s\n", strrep("-", 78), strrep("-", 78)))
cat(sprintf("  d(ocean sink)/d(q_conv) = %+.4f GtC/yr per Sv   (linear fit over 0-%g Sv)\n",
            d_dq, max(CL_Q)))
cat(sprintf("  sign: MORE conveyor => %s ocean uptake\n",
            if (d_dq > 0) "MORE" else "LESS"))
cat(sprintf("\n  For an ENSO modulation q(t) = q0 (1 - k * NINO), El Nino SUPPRESSES the\n  overturning, so the induced ocean-sink response per degC is  -k * q0 * %+.4f.\n", d_dq))
cat(sprintf("  To close the gap the response must go %+.3f -> %+.3f, i.e. %+.3f GtC/yr per degC.\n",
            CL_SLOPE_MODEL, CL_SLOPE_OBS, CL_SLOPE_OBS - CL_SLOPE_MODEL))
need <- CL_SLOPE_OBS - CL_SLOPE_MODEL
cat(sprintf("\n  %-10s %14s %s\n", "q0 (Sv)", "k needed", "= modulation per degC Nino3.4"))
for (q0 in c(5, 10, 15, 20)) {
  k_need <- -need / (q0 * d_dq)
  cat(sprintf("  %-10.0f %14.3f %s\n", q0, k_need,
              sprintf("%.0f %% of q0 per degC%s", 100 * abs(k_need),
                      if (abs(k_need) > 1) "   *** IMPLAUSIBLE: exceeds the whole circulation ***"
                      else if (abs(k_need) > 0.5) "   ** very large **" else "")))
}
cat("\n  ⚠ SIGN FIRST, MAGNITUDE SECOND. If d(ocean sink)/dQ has the sign that makes\n")
cat("    k NEGATIVE, then closing the gap needs El Nino to STRENGTHEN the\n")
cat("    overturning -- the opposite of the physical story -- and the mechanism is\n")
cat("    refuted regardless of how large the lever is.\n")
cat("  ⚠ SURROGATE: this is an interhemispheric cell, not equatorial upwelling.\n")
cat(sprintf("\n⛔ NOTHING ADOPTED; q_conv stays 0 in CCX_PARAM_TABLE.\n%s\n", strrep("=", 78)))
