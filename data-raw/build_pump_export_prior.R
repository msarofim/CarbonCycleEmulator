# =====================================================================
# build_pump_export_prior.R -- THE OBSERVATION-CONSTRAINED PRIOR ON THE LOW-
# LATITUDE PUMP'S EXPORT `pump_export` (option D + E; ruling E4, Marcus
# 2026-09-14: "Nowicki if it includes uncertainty bounds" -- it does, in its
# data release, and they are COMPUTED here rather than recalled).
#
# SOURCE: Nowicki, DeVries & Siegel (2022), GBC 36, e2021GB007083,
#   doi:10.1029/2021GB007083 -- satellite + in-situ BGC observations assimilated
#   into a 124-member ensemble of the biological pump. Abstract: ensemble-mean
#   global export 10.2 PgC/yr; gravitational 70 % (85 % fecal / 15 % aggregates),
#   migrant 10 %, mixing 20 %. Data: figshare doi:10.6084/m9.figshare.19074521,
#   manifest key `nowicki2022_bcp` (data-raw/download_nowicki_bcp.R): the
#   ensemble MEAN and the 25th / 75th PERCENTILE of every field on the OCIM 2-deg
#   grid, with the grid-box areas.
#
# WHAT IS COMPUTED. Every export map (mmolC m-2 yr-1) x Area, summed over the
# wet cells, in PgC/yr: the global total (a CHECK against the abstract's 10.2),
# the low-latitude band |lat| < the model's HS boundary (the pump is an
# LS-column mechanism over a_ls -- R/model.R ccx_pump_export(), choice C9), its
# hemispheric halves, and the HS remainder (a cross-check on
# obs_hs_export_prior.rds, which was built from float-based zone estimates).
#
# ⚠ THE BOUNDS ARE AN OUTER BRACKET, NOT THE ENSEMBLE'S OWN IQR OF THE TOTAL.
# The release carries PER-CELL percentiles; integrating the p25 map gives the
# sum of per-cell 25th percentiles, which equals the 25th percentile of the
# global sum only if the members are rank-ordered identically in every cell
# (comonotonic). Any less-than-perfect dependence makes the true IQR of the
# sum NARROWER than [sum p25, sum p75]. So the width used here is CONSERVATIVE
# (too wide, never too narrow) with respect to the ensemble. It is still an
# ENSEMBLE-INTERNAL width: the cross-method literature spread (~5-13 PgC/yr
# global, DESIGN sec.5.2c) is structural and wider; the prior's 2-sigma range
# is where the two meet, and that is stated in the output, not hidden.
#
# PRIOR FORM: lognormal on the LS export in GtC/yr, median = the ensemble-mean
# LS total, log-sd from the bracket's IQR: sd = log(p75/p25) / (2 * 0.6745).
# Usage: Rscript data-raw/build_pump_export_prior.R  (from the repo root)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
suppressMessages(library(ncdf4))
PEP_NC <- "data-raw/downloads/biopump_model_output.nc"
PEP_MANIFEST_KEY <- "nowicki2022_bcp"
PEP_ABSTRACT_GLOBAL <- 10.2                     # PgC/yr, the abstract's ensemble mean (the check)
PEP_ABSTRACT_SHARES <- c(grav = 0.70, mig = 0.10, mix = 0.20)
PEP_HS_FRAC <- CCX_STRUCT_HILDA$hs_frac         # 0.16 -> the boundary latitude below
PEP_HS_LAT <- asin(1 - PEP_HS_FRAC) * 180 / pi  # 57.14 deg: the cap holding 16 % of a hemisphere's area
PEP_GC_PER_MMOL <- 12.011e-3                    # g C per mmol C
PEP_G_PER_PG <- 1e15
PEP_IQR_Z <- stats::qnorm(0.75)                 # 0.6745: half the IQR in sigma units
PEP_EXPORT_VARS <- c(tot = "tot_ex", grav = "grav_ex", fec = "fec_ex", agg = "agg_ex",
                     mig = "mig_ex", mix = "mix_export")
PEP_UNCRT_VARS  <- c(tot = "tot_ex_uncrt", grav = "grav_ex_uncrt", fec = "fec_ex_uncrt",
                     agg = "agg_ex_uncrt", mig = "mig_ex_uncrt", mix = "mix_ex_uncrt")

man <- utils::read.csv("data-raw/downloads/MANIFEST.csv", stringsAsFactors = FALSE)
mrow <- man[man$key == PEP_MANIFEST_KEY, ]
if (nrow(mrow) != 1) stop("manifest has no entry ", PEP_MANIFEST_KEY, "; run data-raw/download_nowicki_bcp.R")
if (tools::sha256sum(PEP_NC)[[1]] != mrow$sha256) stop("sha256 of ", PEP_NC, " differs from the manifest")

nc <- nc_open(PEP_NC)
# ncdf4 returns [latitude, longitude, (depth)] -- the reverse of the file's C order.
mask <- ncvar_get(nc, "mask")[, , 1]           # 1 = WET (the file's attribute says the reverse;
area <- ncvar_get(nc, "Area")                  #   the wet area under ==1 is 3.56e14 m2, the ocean's)
lat  <- ncvar_get(nc, "LAT")[, , 1]
wet  <- mask == 1
ocean_area <- sum(area[wet])
if (abs(ocean_area / 3.6e14 - 1) > 0.05) stop("wet-mask area ", ocean_area, " is not the ocean's ~3.6e14 m2")

# PgC/yr over a cell selection, for a 2-D field or the 2-D [p25, p75] pair.
# `sel` is a WEIGHT map (0/1, or 0.5 on the equatorial row, which the grid has
# and which belongs half to each hemisphere).
integrate <- function(v, sel = wet) {
  x <- ncvar_get(nc, v)
  f <- function(m) sum(m * area * sel, na.rm = TRUE) * PEP_GC_PER_MMOL / PEP_G_PER_PG
  if (length(dim(x)) == 2) f(x) else c(p25 = f(x[, , 1]), p75 = f(x[, , 2]))
}
nh_w <- ifelse(lat > 0, 1, ifelse(lat == 0, 0.5, 0)); sh_w <- 1 - nh_w
ls_w <- wet * (abs(lat) < PEP_HS_LAT); hs_w <- wet * (abs(lat) >= PEP_HS_LAT)
bands <- list(global = wet * 1, LS = ls_w, LS_NH = ls_w * nh_w, LS_SH = ls_w * sh_w,
              HS = hs_w, HS_NH = hs_w * nh_w, HS_SH = hs_w * sh_w)
tot <- t(sapply(bands, function(s) c(mean = integrate("tot_ex", s), integrate("tot_ex_uncrt", s),
                                     area_m2 = sum(area * s))))
tot <- cbind(tot, gC_m2_yr = tot[, "mean"] * PEP_G_PER_PG / tot[, "area_m2"])
paths <- t(sapply(names(PEP_EXPORT_VARS), function(k) c(mean = integrate(PEP_EXPORT_VARS[[k]]),
                                                        integrate(PEP_UNCRT_VARS[[k]]))))

# THE CHECK against the abstract, before anything is saved.
g <- tot["global", "mean"]
if (abs(g / PEP_ABSTRACT_GLOBAL - 1) > 0.02)
  stop(sprintf("integrated global export %.2f is not the abstract's %.1f PgC/yr", g, PEP_ABSTRACT_GLOBAL))
shares <- c(grav = paths["grav", "mean"], mig = paths["mig", "mean"], mix = paths["mix", "mean"]) / g
if (any(abs(shares - PEP_ABSTRACT_SHARES) > 0.03))
  stop("pathway shares ", paste(sprintf("%s %.2f", names(shares), shares), collapse = ", "),
       " differ from the abstract's 0.70 / 0.10 / 0.20")

# The gravitational flux profile (a check on the Martin exponent the shape uses).
z <- ncvar_get(nc, "DEPTH")[1, 1, ]
poc <- ncvar_get(nc, "POCflux")
prof <- vapply(seq_along(z), function(k) sum(poc[, , k] * area * wet, na.rm = TRUE) * PEP_GC_PER_MMOL / PEP_G_PER_PG,
               numeric(1))
k100 <- which.min(abs(z - 100)); k1000 <- which.min(abs(z - 1000))
b_eff <- -log(prof[k1000] / prof[k100]) / log(z[k1000] / z[k100])
nc_close(nc)

ls_med <- tot["LS", "mean"]
log_sd <- log(tot["LS", "p75"] / tot["LS", "p25"]) / (2 * PEP_IQR_Z)
prior <- list(
  centre_gtc = ls_med, log_sd = log_sd,
  q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(ls_med), log_sd),
  hemi_share = c(NH = tot["LS_NH", "mean"], SH = tot["LS_SH", "mean"]) / ls_med,
  band_totals = tot, pathway_totals = paths, hs_lat = PEP_HS_LAT, hs_frac = PEP_HS_FRAC,
  poc_profile = data.frame(z_m = z, PgC_yr = prof), martin_b_effective = b_eff,
  bounds_note = paste("p25/p75 are integrals of the release's PER-CELL percentile maps: an OUTER",
                      "bracket of the ensemble's IQR of the total (equal to it only if the members",
                      "are comonotonic across cells). Ensemble-internal; the cross-method literature",
                      "spread (~5-13 PgC/yr global) is wider."),
  source = c(N22 = "Nowicki, DeVries & Siegel 2022 GBC doi:10.1029/2021GB007083; data figshare doi:10.6084/m9.figshare.19074521",
             manifest = PEP_MANIFEST_KEY, sha256 = mrow$sha256),
  built = format(Sys.time(), "%Y-%m-%d %H:%M"))

cat(sprintf("Nowicki 2022 ensemble, integrated on its own grid (wet area %.3fe14 m2, HS boundary %.2f deg):\n", ocean_area / 1e14, PEP_HS_LAT))
cat(sprintf("  global export %.2f PgC/yr [sum-of-p25 %.2f, sum-of-p75 %.2f]  (abstract 10.2: CHECK PASSED)\n", g, tot["global", "p25"], tot["global", "p75"]))
cat(sprintf("  pathways: grav %.2f (fec %.2f + agg %.2f), migrant %.2f, mixing %.2f  -> shares %.2f / %.2f / %.2f (abstract 0.70 / 0.10 / 0.20)\n",
            paths["grav", "mean"], paths["fec", "mean"], paths["agg", "mean"], paths["mig", "mean"], paths["mix", "mean"],
            shares[["grav"]], shares[["mig"]], shares[["mix"]]))
for (b in rownames(tot))
  cat(sprintf("  %-7s %6.2f PgC/yr [%5.2f, %5.2f]  %5.1f gC m-2 yr-1 over %.3fe14 m2\n", b, tot[b, "mean"], tot[b, "p25"], tot[b, "p75"], tot[b, "gC_m2_yr"], tot[b, "area_m2"] / 1e14))
cat(sprintf("  gravitational POC flux %.2f at %.0f m -> %.2f at %.0f m: effective Martin b = %.3f (the shape's sourced 0.858 is steeper)\n",
            prof[k100], z[k100], prof[k1000], z[k1000], b_eff))
cat(sprintf("PRIOR on pump_export (LS, GtC/yr): lognormal median %.2f, log-sd %.3f (from the IQR bracket); hemispheric share NH %.3f / SH %.3f\n",
            ls_med, log_sd, prior$hemi_share[["NH"]], prior$hemi_share[["SH"]]))
cat(sprintf("  quantiles 2.5/16/50/84/97.5 %%: %s GtC/yr;  today's solved field 45.5 sits at z = %+.1f\n",
            paste(sprintf("%.2f", prior$q), collapse = " / "), (log(45.5) - log(ls_med)) / log_sd))
cat(sprintf("  HS cross-check: %.1f gC m-2 yr-1 here vs obs_hs_export_prior.rds median %.1f\n",
            tot["HS", "gC_m2_yr"], ccx_hs_export_prior()$centre_gcm2))
saveRDS(prior, ccx_path("data", "obs_pump_export_prior.rds")); cat("saved data/obs_pump_export_prior.rds\n")
