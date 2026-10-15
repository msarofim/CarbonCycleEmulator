# =====================================================================
# build_emission_seasonality.R -- REVIEW ITEM 5c.
#
# Turns the two small csvs written by data-raw/extract_emission_seasonality.py
# into data/forcing_emission_seasonality.rds: hemispheric monthly weights for
# the fossil and land-use emission inputs, plus the one scale factor that makes
# the land-use weight usable.
#
# WHY IT MATTERS. ccx_build_forcing() had NO within-year seasonal cycle on
# either emission input. The model's single free NEP amplitude absorbs the
# omission: seas_amp_NH 12 -> 13 GtC/yr is 101 log-units in the objective, and
# the MAP mode fits seas_amp_NH to 19.66 against a default of 12. Some of that
# is a real biosphere signal and some is an input error wearing its clothes.
#
# SOURCES
#   FIRE   GFED4.1s, van der Werf GR, et al. (2017), "Global fire emissions
#          estimates during 1997-2016", Earth Syst. Sci. Data 9:697-720,
#          doi:10.5194/essd-9-697-2017. Monthly 0.25 deg, 2001-2016.
#   FOSSIL EDGAR v4.3.2 monthly, Crippa M, et al. (2020), "High resolution
#          temporal profiles in the Emissions Database for Global Atmospheric
#          Research", Sci. Data 7:121, doi:10.1038/s41597-020-0462-2.
#          Monthly by country and IPCC-1996 sector, 1970-2012.
#
# =====================================================================
# THE DECISION THIS FILE EXISTS TO MAKE: E_LUC IS NOT FIRE.
#
# GFED's deforestation-and-peat carbon is 0.367 PgC/yr over 2001-2016 against
# GCB's E_LUC of 1.699 GtC/yr for the same years, so **only 21.6 % of E_LUC is
# fire**. The rest is wood harvest, product decay, soil-carbon loss and
# regrowth debits -- fluxes with no sharp seasonal cycle at this model's
# resolution. Applying the raw fire shape to the whole of E_LUC would impose a
# 5x seasonal swing on a flux that is 78 % aseasonal, i.e. it would be wrong by
# about 4.6x IN THE DIRECTION THAT LOOKS LIKE SUCCESS -- a larger input
# seasonality would pull seas_amp_NH further from its current value and could be
# mistaken for a bigger correction.
#
# So the applied weight is DAMPED:
#     w_eff(m) = 1 + f_fire * (w_fire(m) - 1)
# with f_fire measured here rather than assumed. At f_fire = 0 this reduces to
# the incumbent no-seasonality model exactly, which is the property that makes
# the change auditable.
#
# THE DAMPING IS THE LARGEST UNCERTAINTY IN THIS PRODUCT, larger than either
# input dataset. It is stored alongside the weights so a sensitivity is one
# argument away, and the undamped shape is stored too.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants; every label below derives from these ----------
BES_FIRE_CSV   <- ccx_path("data-raw", "downloads", "seasonality_fire.csv")
BES_FOSS_CSV   <- ccx_path("data-raw", "downloads", "seasonality_fossil.csv")
BES_OUT        <- ccx_path("data", "forcing_emission_seasonality.rds")
BES_FIRE_YEARS <- c(2001, 2016)   # GFED4.1s MODIS era, excluding the beta years
BES_FOSS_YEARS <- c(1970, 2012)   # EDGAR v4.3.2's full monthly record
BES_LUC_PART   <- "DEFO+PEAT"     # the land-use-change subset of fire

if (!file.exists(BES_FIRE_CSV) || !file.exists(BES_FOSS_CSV))
  stop("run data-raw/extract_emission_seasonality.py first (needs the ",
       "gitignored GFED hdf5 files and the EDGAR xlsx; see MANIFEST.csv)")

# ---- climatological monthly weight, normalized to mean 1 ------------
# Mean 1 rather than sum 1 so that a weight of exactly 1 in every month is the
# no-seasonality case and the damping formula above is a clean interpolation.
bes_weight <- function(d, col, years) {
  d <- d[d$year >= years[1] & d$year <= years[2], ]
  m <- tapply(d[[col]], d$month, sum)
  stopifnot(length(m) == 12L, all(is.finite(m)), all(m >= 0))
  as.numeric(m / mean(m))
}

fire <- utils::read.csv(BES_FIRE_CSV)
foss <- utils::read.csv(BES_FOSS_CSV)

w <- list(
  fossil_NH = bes_weight(foss, "fossil_NH_Gg", BES_FOSS_YEARS),
  fossil_SH = bes_weight(foss, "fossil_SH_Gg", BES_FOSS_YEARS),
  luc_NH    = bes_weight(fire, "luc_NH", BES_FIRE_YEARS),
  luc_SH    = bes_weight(fire, "luc_SH", BES_FIRE_YEARS),
  # sensitivity only -- ALL fire, including savanna and agricultural burning,
  # which are recurring cycles rather than land-use change. Not what E_LUC is.
  allfire_NH = bes_weight(fire, "all_NH", BES_FIRE_YEARS),
  allfire_SH = bes_weight(fire, "all_SH", BES_FIRE_YEARS))

# ---- f_fire: how much of E_LUC actually burns ------------------------
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
gcb <- gcb[gcb$year >= BES_FIRE_YEARS[1] & gcb$year <= BES_FIRE_YEARS[2], ]
ny  <- diff(BES_FIRE_YEARS) + 1
luc_fire_PgC <- sum(fire$luc_NH + fire$luc_SH) / 1e15 / ny
eluc_GtC     <- mean(gcb$luc)
f_fire       <- luc_fire_PgC / eluc_GtC

out <- list(
  weights = w, f_fire = f_fire,
  luc_fire_PgC_yr = luc_fire_PgC, eluc_GtC_yr = eluc_GtC,
  fire_years = BES_FIRE_YEARS, foss_years = BES_FOSS_YEARS,
  luc_partition = BES_LUC_PART,
  source_fire = paste("GFED4.1s, van der Werf et al. 2017, ESSD 9:697-720,",
                      "doi:10.5194/essd-9-697-2017; www.globalfiredata.org"),
  source_foss = paste("EDGAR v4.3.2 monthly, Crippa et al. 2020, Sci Data 7:121,",
                      "doi:10.1038/s41597-020-0462-2"),
  built = Sys.Date())
saveRDS(out, BES_OUT)

# ---- receipts --------------------------------------------------------
mn <- c("J","F","M","A","M","J","J","A","S","O","N","D")
cat("=====================================================================\n")
cat("emission seasonality, monthly weights (mean = 1)\n")
cat("=====================================================================\n")
cat(sprintf("%12s %s\n", "", paste(sprintf("%6s", mn), collapse = "")))
for (k in names(w))
  cat(sprintf("%12s %s\n", k, paste(sprintf("%6.2f", w[[k]]), collapse = "")))
cat("\n")
for (k in names(w))
  cat(sprintf("%12s  peak %2d  trough %2d  peak-to-peak %5.2f\n",
              k, which.max(w[[k]]), which.min(w[[k]]),
              max(w[[k]]) - min(w[[k]])))

cat(sprintf("\nPHASE CHECK (these are the falsifiable ones):\n"))
cat(sprintf("  fossil NH peaks in month %d, fossil SH in month %d -- must be\n",
            which.max(w$fossil_NH), which.max(w$fossil_SH)))
cat("  opposed, because the driver is winter heating.\n")
cat(sprintf("  LUC fire SH peaks in month %d -- the southern-Africa / Amazon /\n",
            which.max(w$luc_SH)))
cat("  Indonesia dry season, which is Aug-Oct.\n")

cat(sprintf("\nf_fire = %.3f  (GFED %s %.3f PgC/yr / GCB E_LUC %.3f GtC/yr, %d-%d)\n",
            f_fire, BES_LUC_PART, luc_fire_PgC, eluc_GtC,
            BES_FIRE_YEARS[1], BES_FIRE_YEARS[2]))
cat("  So the LUC weight is damped to 1 + f_fire * (w - 1): the applied\n")
cat(sprintf("  peak-to-peak on E_LUC becomes %.2f (NH) and %.2f (SH), not %.2f / %.2f.\n",
            f_fire * (max(w$luc_NH) - min(w$luc_NH)),
            f_fire * (max(w$luc_SH) - min(w$luc_SH)),
            max(w$luc_NH) - min(w$luc_NH), max(w$luc_SH) - min(w$luc_SH)))
cat("  FOSSIL IS NOT DAMPED -- all of it is combustion, all of it is seasonal.\n")
cat(sprintf("\nwrote %s\n", BES_OUT))
