# =====================================================================
# build_hs_export_prior.R -- THE LITERATURE PRIOR ON THE HS PUMP'S EXPORT
# (2026-09-07f, Marcus: "use a literature prior for HS export").
#
# The HS box is the poleward ~16 % of each hemisphere's ocean (|lat| >~ 57):
# in the SH the polar Antarctic zone (PAZ) plus the sea-ice zone (SIZ); in the
# NH the subpolar gyres and the Arctic. `pump_hs_gcm2` is its export per unit
# area in gC m-2 yr-1, out of a box h_hs thick (20-500 m, fitted).
#
# SOURCES (typed here as CITED constants; the center is COMPUTED from them):
#   [L25] Liniger, Moreau, Lannuzel, Carranza & Strutton (2025), Global
#         Biogeochemical Cycles, doi:10.1029/2024GB008193. BGC-Argo, 2014-2022,
#         SO south of 30 S: total 2.69 +/- 1.23 PgC/yr; per-zone export from DO
#         changes over 100-500 m: SIZ 1.11, PAZ 2.01, SAZ 1.40, STZ 1.14
#         molC m-2 yr-1; with the turbulence term: SIZ 5.93, PAZ 2.49,
#         SAZ 1.62, STZ 1.59; over Ed-1000 m the SIZ falls to 0.28.
#   [A19] Arteaga, Pahlow, Bushinsky & Sarmiento (2019), Global Biogeochemical
#         Cycles, doi:10.1029/2019GB006236 (as averaged per zone by L25 sec.4.2):
#         SIZ 0.9, PAZ 1.80, SAZ 1.80, STZ 1.25 molC m-2 yr-1.
#   [N22] Nowicki, DeVries & Siegel (2022), GBC, doi:10.1029/2021GB007083:
#         global export 10.2 PgC/yr (context only; not used in the center).
# CENTER: the PAZ -- the zone the cold box most resembles -- averaged over the
# two float-based estimates. SPREAD: log-sd chosen so that 1 sigma spans the
# PAZ-with-turbulence value above and the SIZ mesopelagic value's order below,
# and to carry the two things the sources do not cover: the NH subpolar half
# of the box, and the export HORIZON (the box's own thickness, not 100-500 m).
# ⚠ A wide prior by design; the data rows are meant to do the narrowing.
# Usage: Rscript data-raw/build_hs_export_prior.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HEP_GC_PER_MOL <- 12.011
HEP_PAZ_MOLC <- c(L25 = 2.01, A19 = 1.80)        # molC m-2 yr-1, 100-500 m DO method
HEP_PAZ_TURB_MOLC <- 2.49                        # L25, with the turbulence term
HEP_SIZ_MOLC <- c(L25_100_500 = 1.11, A19 = 0.9, L25_Ed_1000 = 0.28, L25_turb = 5.93)
HEP_SAZ_MOLC <- c(L25 = 1.40, A19 = 1.80)
HEP_SO_TOTAL_PGC <- c(value = 2.69, sd = 1.23)   # L25, south of 30 S, 2014-2022
HEP_LOG_SD <- 0.6                                # factor 1.8 at 1 sigma, 3.3 at 2 sigma
centre_molc <- mean(HEP_PAZ_MOLC)
centre_gcm2 <- centre_molc * HEP_GC_PER_MOL
prior <- list(
  centre_gcm2 = centre_gcm2, log_sd = HEP_LOG_SD,
  q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre_gcm2), HEP_LOG_SD),
  inputs = list(paz_molc = HEP_PAZ_MOLC, paz_turb_molc = HEP_PAZ_TURB_MOLC, siz_molc = HEP_SIZ_MOLC,
                saz_molc = HEP_SAZ_MOLC, so_total_pgc = HEP_SO_TOTAL_PGC, gc_per_mol = HEP_GC_PER_MOL),
  sources = c(L25 = "Liniger et al. 2025 GBC doi:10.1029/2024GB008193",
              A19 = "Arteaga et al. 2019 GBC doi:10.1029/2019GB006236 (per-zone means as reported by L25)",
              N22 = "Nowicki et al. 2022 GBC doi:10.1029/2021GB007083 (context)"),
  built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("HS export prior: lognormal, median %.1f gC m-2 yr-1 (= %.2f molC m-2 yr-1, the PAZ mean of L25 %.2f and A19 %.2f), log-sd %.2f\n",
            centre_gcm2, centre_molc, HEP_PAZ_MOLC[["L25"]], HEP_PAZ_MOLC[["A19"]], HEP_LOG_SD))
cat(sprintf("  quantiles 2.5/16/50/84/97.5 %%: %s gC m-2 yr-1\n", paste(sprintf("%.1f", prior$q), collapse = " / ")))
cat(sprintf("  for scale: PAZ+turbulence %.1f, SIZ %.1f-%.1f, SAZ %.1f-%.1f gC m-2 yr-1; the 09-07e probe's observation-matched point 60 sits at z = %+.2f\n",
            HEP_PAZ_TURB_MOLC * HEP_GC_PER_MOL, min(HEP_SIZ_MOLC) * HEP_GC_PER_MOL, max(HEP_SIZ_MOLC) * HEP_GC_PER_MOL,
            min(HEP_SAZ_MOLC) * HEP_GC_PER_MOL, max(HEP_SAZ_MOLC) * HEP_GC_PER_MOL, (log(60) - log(centre_gcm2)) / HEP_LOG_SD))
saveRDS(prior, ccx_path("data", "obs_hs_export_prior.rds")); cat("saved data/obs_hs_export_prior.rds\n")
