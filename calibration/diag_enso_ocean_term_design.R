# =====================================================================
# diag_enso_ocean_term_design.R -- WHAT WOULD AN ENSO TERM ON SURFACE UPTAKE
# BUY, AND WHAT WOULD IT COST? (Marcus's proposal, priced BEFORE it is built.)
#
# THE PROPOSAL. Add an ENSO flux anomaly to the air-sea exchange in each
# hemisphere, mirroring the land term the model already has
# (`R/model.R:1256`, `gamma_enso * forc$enso * aux$enso_share[[h]]`,
# soil_fast -> atm). Since a two-box model has no tropics, a PARAMETERIZED
# anomaly is arguably the honest representation of a process the structure
# cannot resolve -- which is exactly the argument the land term already rests on.
#
# WHY THIS IS PRICED OFFLINE FIRST. The term is a direct additive perturbation
# to the ocean sink, so its effect on the sink slope, on the atmospheric growth
# slope, and on the partition can all be computed FROM THE EXISTING RUN. Writing
# it needs R and C++ twins, a parity test, an isotopic signature for the new
# flux, and a hemispheric share -- and the last two are where the pump x
# advection work broke ("the reversal ties CO2 exactly and breaks only the
# ISOTOPES"). Price it, then build it. [[ccx_conveyor_not_the_enso_fix]] is the
# same discipline applied to the previous candidate, which it killed.
#
# ⚠ UNITS. GCB's `atm_growth` is **GtC/yr**, not ppm/yr -- confirmed against the
# budget identity (fossil+luc-land-ocean-imbalance = 5.163 vs atm_growth 4.949
# for 2020), not against a mean-magnitude guess, which gets it WRONG. The model's
# growth is ppm/yr and is converted here. Comparing the two raw is a factor-2.124
# error and it inverted this file's first answer.
#
# ⛔ ADOPTS NOTHING; no parameter is added by this file.
# =====================================================================
ccx_load_cpp()
source(ccx_path("calibration","lib_design_gates.R")); source(ccx_path("calibration","lib_enso_regression.R"))
YRS <- 1959:2024; GTC <- ccx_const("GtC_PER_PPM")
g <- as.data.frame(ccx_prepare_obs()$gcb); g <- g[g$year %in% YRS, ]
sl <- function(y, yrs, lag) er_cor(er_index_annual(yrs, ER_INDEX, lag), er_detrend(y, yrs))$slope
LL <- er_best_lag(g$year, er_detrend(g$land_sink, g$year))$lag
LO <- er_best_lag(g$year, er_detrend(g$ocean_sink, g$year))$lag
o_l <- sl(g$land_sink,g$year,LL); o_o <- sl(g$ocean_sink,g$year,LO); o_g <- sl(g$atm_growth,g$year,LL)
v <- dg_vector("calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds")
a <- dg_annual_sinks(dg_run(v)); k <- a$year %in% YRS; yy <- a$year[k]
m_l <- sl(a$land[k],yy,LL); m_o <- sl(a$ocean[k],yy,LO)
m_g <- sl(a$growth_ppm[k],yy,LL) * GTC     # ppm/yr -> GtC/yr, the units atm_growth uses

cat(sprintf("\nALL IN GtC/yr per degC Nino3.4 (atm_growth is GtC/yr; model ppm/yr x %.3f)\n%s\n", GTC, strrep("-",72)))
cat(sprintf("%-24s %10s %10s %12s\n","", "land","ocean","CO2 growth"))
cat(sprintf("%-24s %+10.3f %+10.3f %+12.3f\n","OBSERVED (GCB)", o_l, o_o, o_g))
cat(sprintf("%-24s %+10.3f %+10.3f %+12.3f\n","model (08-31e)", m_l, m_o, m_g))
cat(sprintf("%-24s %9.0f%% %9.0f%% %11.0f%%\n","  %% of observed",100*m_l/o_l,100*m_o/o_o,100*m_g/o_g))
cat(sprintf("\n  budget closure of the SLOPES, -(land+ocean) vs measured growth:\n"))
cat(sprintf("    observed  %+.3f vs %+.3f  (gap %+.3f = the GCB imbalance term)\n", -(o_l+o_o), o_g, o_g+(o_l+o_o)))
cat(sprintf("    model     %+.3f vs %+.3f  (gap %+.3f)\n", -(m_l+m_o), m_g, m_g+(m_l+m_o)))
cat(sprintf("\n%s\nTHE COMPENSATING ERRORS\n%s\n", strrep("-",72), strrep("-",72)))
cat(sprintf("  land short by %+.3f, ocean off by %+.3f -- OPPOSITE effect on growth,\n  so they cancel %.0f%% of each other in the atmosphere.\n",
            o_l-m_l, o_o-m_o, 100*min(abs(o_l-m_l),abs(o_o-m_o))/max(abs(o_l-m_l),abs(o_o-m_o))))
cat(sprintf("\n%s\nTWO WAYS TO ADD THE OCEAN TERM\n%s\n", strrep("-",72), strrep("-",72)))
go <- o_o - m_o
# ⛔ `go` IS A SLOPE GAP, NOT A COEFFICIENT, AND THIS LINE USED TO CALL IT
# `gamma_enso_ocn` (corrected 2026-09-01j). Every number in this file is slope
# arithmetic and is unaffected; what was wrong was the LABEL on two of them.
# The model's measured transfer is slope = -0.1550 + 0.4194 * coef (R2 1.000000,
# diag_enso_objective_leverage.R sec.4), so the COEFFICIENT that delivers this
# slope gap is +0.653 in total -- 2.4x the +0.274 printed here as if it were one.
# [[ratio_needs_its_base]]: a gap in slope-units is not a magnitude in
# parameter-units until it is divided by the transfer.
cat(sprintf("  A. OCEAN ONLY (ocean-sink SLOPE gap to close = %+.3f GtC/yr per index unit;\n     the COEFFICIENT that delivers it is +0.653 total, NOT this number):\n", go))
cat(sprintf("     ocean %+.3f -> %+.3f  OK ;  growth %+.3f -> %+.3f = %.0f%% of observed (was %.0f%%)\n",
            m_o, o_o, m_g, m_g-go, 100*(m_g-go)/o_g, 100*m_g/o_g))
cat(sprintf("     => fixes the partition, WORSENS the better-measured growth rate\n"))
# ⛔ AND THE SAME CORRECTION HERE. `o_l/m_l` is a ratio of SLOPES, and a slope
# ratio is a coefficient ratio only if the transfer passes through the ORIGIN.
# It does not: the land slope at zero ENSO coefficient is +0.0762 (the model's
# residual ENSO response through the SST/q10 path), so the coefficient
# multiplier that delivers this slope is x1.734, not x1.89.
cat(sprintf("\n  B. OCEAN + LAND together (land-sink slope ratio %.2f; the COEFFICIENT\n     multiplier that delivers it is x1.734, NOT this ratio):\n", o_l/m_l))
cat(sprintf("     land %+.3f -> %+.3f ; ocean %+.3f -> %+.3f ; growth %+.3f -> %+.3f = %.0f%% (was %.0f%%)\n",
            m_l, o_l, m_o, o_o, m_g, -(o_l+o_o), 100*(-(o_l+o_o))/o_g, 100*m_g/o_g))
cat(sprintf("     => both partitions right AND the growth rate improves\n"))
