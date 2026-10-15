# =====================================================================
# build_u_hs_prior.R -- the OBSERVATION prior for `u_hs`, the cold box's flush
# (HS <-> HD exchange velocity, m/yr over the HS area), from the observed
# deep-water formation (2026-09-08d; Marcus: "free u_hs").
#
# WHY. HILDA declared u = 38 +/- 17 m/yr (their K(z) fit to 1970s GEOSECS 14C);
# over the model's HS area that is a 70 Sv two-way flush. The 09-08c tests
# showed the CO2 rows, not the deep, hold it there. Freeing it under a prior
# centered on what the ocean actually forms lets round 4 READ whether the fit
# runs back to 38 (the model NEEDS the flush for the sink) or settles near
# the observation (the deep is bought at half the export).
#
# THE NUMBERS (every one read from the source text, overturning_and_mld_literature):
#   NADW across 32 S  18 Sv       Talley 2013, Oceanography 26(1):80-97
#   AABW formation    29 Sv       Talley 2013 ("consistent with various independent estimates")
#   AABW formation    21 +/- 7 Sv Lumpkin & Speer 2007 JPO 37:2550, as quoted by Cessi 2019 ARMS 11:249
#   of Talley's 29 Sv AABW, 13 Sv is RECYCLED NADW -- a "formation" sum double-counts it.
# The cold box is BOTH hemispheres' high latitudes and u_hs is its GROSS exchange
# with the deep, so the comparable observation is NADW + AABW formation:
#   low  = 18 + (29 - 13) = 34 Sv  (net of the recycled NADW)
#   high = 18 + 29        = 47 Sv  (gross)
# Converted with the model's OWN HS area (OCEAN_AREA_NH + _SH) x hs_frac and
# 1 Sv = 3.156e13 m3/yr. Center = geometric mean of the bracket. Width: the
# bracket's half-width in log, plus the AABW estimate's own relative error
# (7/21) scaled by AABW's share of the total, in quadrature -- DERIVED, not typed.
# ⚠ The bracket is an interpretive reading of a schematic (Talley Fig. 6a);
# mode-water subduction (SAMW/AAIW) is deliberately NOT included: it ventilates
# the LS column, which the model represents by kz.
# Usage: Rscript data-raw/build_u_hs_prior.R   -> data/obs_u_hs_prior.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
UH_NADW_SV <- 18; UH_AABW_TALLEY_SV <- 29; UH_AABW_RECYCLED_SV <- 13; UH_AABW_LS_SV <- 21; UH_AABW_LS_SE_SV <- 7
UH_SV_M3YR <- 3.156e13
UH_HS_FRAC <- CCX_STRUCT_HILDA$hs_frac
UH_A_HS <- (ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")) * UH_HS_FRAC
UH_HILDA_U <- CCX_U_HS_DECLARED; UH_HILDA_SD <- 17   # the former declared value (HILDA Table 1)
sv_lo <- UH_NADW_SV + (UH_AABW_TALLEY_SV - UH_AABW_RECYCLED_SV); sv_hi <- UH_NADW_SV + UH_AABW_TALLEY_SV
to_m_yr <- function(sv) sv * UH_SV_M3YR / UH_A_HS
u_lo <- to_m_yr(sv_lo); u_hi <- to_m_yr(sv_hi); centre <- sqrt(u_lo * u_hi)
sd_bracket <- log(u_hi / u_lo) / 2
sd_aabw    <- (UH_AABW_LS_SE_SV / UH_AABW_LS_SV) * (UH_AABW_LS_SV / (UH_NADW_SV + UH_AABW_LS_SV))   # AABW's relative error x its share
log_sd <- sqrt(sd_bracket^2 + sd_aabw^2)
out <- list(centre_m_yr = centre, log_sd = log_sd, bracket_m_yr = c(u_lo, u_hi), bracket_sv = c(sv_lo, sv_hi), a_hs_m2 = UH_A_HS, hs_frac = UH_HS_FRAC,
            components = list(sd_bracket = sd_bracket, sd_aabw = sd_aabw), hilda = c(u = UH_HILDA_U, sd = UH_HILDA_SD), z_hilda = (log(UH_HILDA_U) - log(centre)) / log_sd,
            q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre), log_sd),
            source = "Talley 2013 Oceanography 26(1):80-97 (NADW 18 Sv, AABW 29 Sv of which 13 recycled); Lumpkin & Speer 2007 JPO 37:2550 via Cessi 2019 ARMS 11:249 (AABW 21 +/- 7 Sv)",
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("u_hs prior: NADW + AABW = %g-%g Sv over a_hs %.3e m2 (hs_frac %.2f) = %.1f-%.1f m/yr\n", sv_lo, sv_hi, UH_A_HS, UH_HS_FRAC, u_lo, u_hi))
cat(sprintf("  lognormal median %.2f m/yr, log-sd %.3f (bracket %.3f, AABW error %.3f in quadrature); 2.5/16/50/84/97.5 %%: %s\n", centre, log_sd, sd_bracket, sd_aabw, paste(sprintf("%.1f", out$q), collapse = " / ")))
cat(sprintf("  HILDA's declared %g m/yr (%.1f Sv) sits at z %+.2f\n", UH_HILDA_U, UH_HILDA_U * UH_A_HS / UH_SV_M3YR, out$z_hilda))
saveRDS(out, ccx_path("data", "obs_u_hs_prior.rds")); cat("saved data/obs_u_hs_prior.rds\n")
