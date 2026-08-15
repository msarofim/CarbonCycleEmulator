# =====================================================================
# build_luc_nh_share.R -- REVIEW ITEM 5b.
#
# Turns OSCAR v3.1's REGIONAL land-use-change emission series into
# data/forcing_luc_nh_share.rds: a TIME-VARYING northern-hemisphere share of
# E_LUC, 1750-2018, with a lo/central/hi bracket.
#
# WHY IT MATTERS. ccx_build_forcing() splits E_LUC between hemispheres with a
# CONSTANT FORC_LUC_NH_SHARE = 0.55, carried as "PROVISIONAL" in DATA.md sec.6
# since it was written. It is wrong at BOTH ends of the record, and a constant
# cannot be right at either: land-use clearing moved from temperate NH forests
# to the tropics and the southern tropics over the industrial period, so the NH
# share falls from ~0.84 in the 18th century to ~0.40 today
# (calibration/diag_emission_split_and_season.R part 1, commit ccb3b7d).
# In carbon terms that is ~23 GtC of early land-use carbon put in the wrong
# hemisphere and ~5 GtC of modern carbon put in the wrong hemisphere the other
# way.
#
# WHY IT LANDS NOW AND NOT EARLIER. Until review item 5 adds the
# interhemispheric-gradient likelihood terms, NOTHING IN THE OBJECTIVE CAN SEE
# EITHER SHARE (review sec.2.3): MLO and SPO are scored as two independent
# levels whose difference carries an effective sigma of ~2.5 ppm, larger than
# the model's whole ~1.1 ppm gradient error. 5b is built with 5 because 5 is
# what would score it.
#
# SOURCE
#   OSCAR v3.1 bookkeeping E_LUC, "Regional" sheet of
#   data-raw/downloads/oscar_gcb2020_eluc.xlsx, 11 regions, 1701-2018.
#   Gasser T, et al. (2020), "Historical CO2 emissions from land use and land
#   cover change and their uncertainty", Biogeosciences 17:4075-4101,
#   doi:10.5194/bg-17-4075-2020. The SAME file DATA.md sec.3a already uses for
#   the pre-1850 E_LUC segment; its 1750-2018 total reproduces the paper's
#   206 PgC headline, which is the check that the right column is being read.
#
# =====================================================================
# WHAT IS SOURCED AND WHAT IS NOT -- stated plainly, because the distinction is
# the whole reason this product ships a bracket rather than one number.
#
# SOURCED: the regional E_LUC time series. OSCAR resolves 11 regions.
# NOT SOURCED: the NH fraction WITHIN each straddling region. OSCAR's regions
# are POLITICAL aggregates, not hemispheres, and nothing in this repo resolves
# them to latitude. Three of the eleven straddle the equator and one more
# (Oceania) sits almost entirely south of it. The fractions below are geographic
# judgements, so they are carried as a BRACKET and every year is reported
# lo/central/hi. THE CONCLUSION TO TRUST IS THE ONE THAT SURVIVES THE WHOLE
# BRACKET -- and the direction does: pre-1950 even the LOW bracket is >= 0.60,
# post-1990 even the HIGH bracket is <= 0.53. The two ends do not overlap under
# any admissible judgement, which is what makes "a constant cannot represent
# this" a measurement rather than a preference.
#
# The bracket table is IDENTICAL to calibration/diag_emission_split_and_season.R
# (part 1), deliberately: this file promotes that diagnostic's measurement to a
# data product without re-deciding it. If the judgements are ever revised they
# must be revised in both, and the test suite compares this product against a
# recomputation from the same table.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- named constants; every label and column below derives from these ----
LNS_SOURCE   <- "OSCAR v3.1 (Gasser et al. 2020, doi:10.5194/bg-17-4075-2020), Regional sheet"
LNS_FILE     <- "oscar_gcb2020_eluc.xlsx"
LNS_SHEET    <- "Regional"
LNS_YEARS    <- c(1750, 2018)     # the product's own coverage
LNS_TOTAL_CHK <- 206              # PgC, 1750-2018, the paper's headline
LNS_TOTAL_TOL <- 3                # PgC, tolerance on that check
LNS_OUT      <- ccx_path("data", "forcing_luc_nh_share.rds")

# within-region NH fraction: lo / central / hi (see the header)
LNS_NH_FRAC <- list(
  `North America`                    = c(1.00, 1.00, 1.00),  # entirely NH
  `Europe`                           = c(1.00, 1.00, 1.00),  # entirely NH
  `Former Soviet Union`              = c(1.00, 1.00, 1.00),  # entirely NH
  `China`                            = c(1.00, 1.00, 1.00),  # entirely NH
  `North Africa and the Middle East` = c(1.00, 1.00, 1.00),  # entirely NH
  `East Asia`                        = c(1.00, 1.00, 1.00),  # Japan/Korea/Mongolia
  # Brazil dominates Latin American clearing and is ~93 % SH; Mexico, Central
  # America, the Caribbean and northern Colombia/Venezuela are NH.
  `Latin America`                    = c(0.15, 0.25, 0.35),
  # Straddles: Sahel, Nigeria, Ethiopia and northern Congo basin NH; southern
  # Congo, Angola, Zambia, southern Tanzania and southern Africa SH.
  `Sub-Saharan Africa`               = c(0.35, 0.50, 0.65),
  # Mainland (India, Indochina, Philippines) NH; Indonesia -- a large share of
  # the region's clearing -- is largely SH (Java, southern Sumatra, Papua).
  `South and Southeast Asia`         = c(0.55, 0.70, 0.85),
  `Oceania`                          = c(0.00, 0.05, 0.10),  # Australia/NZ/PNG
  `Unknown`                          = c(0.50, 0.50, 0.50)   # zero flux anyway
)

# ---------------------------------------------------------------------
xl <- ccx_path("data-raw", "downloads", LNS_FILE)
if (!file.exists(xl))
  stop(sprintf("%s not found -- run data-raw/download_data.R first.", LNS_FILE))

reg <- as.data.frame(readxl::read_excel(xl, sheet = LNS_SHEET))
reg <- reg[reg$year >= LNS_YEARS[1] & reg$year <= LNS_YEARS[2], ]
stopifnot(all(reg$reg_land_long_name %in% names(LNS_NH_FRAC)))

# The headline check: is this the right column of the right sheet?
tot <- sum(reg$E_luc)
cat(sprintf("[1] OSCAR regional E_luc, %d-%d: %.1f PgC (paper headline %d +/- %d)\n",
            LNS_YEARS[1], LNS_YEARS[2], tot, LNS_TOTAL_CHK, LNS_TOTAL_TOL))
if (abs(tot - LNS_TOTAL_CHK) > LNS_TOTAL_TOL)
  stop(sprintf("regional total %.1f PgC is outside %d +/- %d -- wrong sheet or column?",
               tot, LNS_TOTAL_CHK, LNS_TOTAL_TOL))

# ---------------------------------------------------------------------
# The share itself: flux-weighted, per year, once per bracket end.
#
# FLUX-WEIGHTED, NOT REGION-AVERAGED. The quantity the model needs is "what
# fraction of THIS YEAR'S E_LUC entered the northern box", so each region enters
# weighted by its own emission. A plain mean over regions would let a region
# emitting nothing vote.
#
# A YEAR WITH NET-ZERO GLOBAL E_LUC HAS NO DEFINED SHARE. OSCAR's regional
# fluxes can be negative (net regrowth), so the denominator can approach zero
# and the ratio can leave [0, 1] or blow up. Those years are set NA here and
# filled by the accessor's own rule rather than being allowed to emit a share of
# 7.3 that nothing downstream would notice. Measured below, not assumed.
# ---------------------------------------------------------------------
share_of <- function(which_col) {
  f   <- vapply(reg$reg_land_long_name,
                function(n) LNS_NH_FRAC[[n]][which_col], numeric(1))
  num <- tapply(reg$E_luc * f, reg$year, sum)
  den <- tapply(reg$E_luc,     reg$year, sum)
  s   <- as.numeric(num / den)
  s[!is.finite(s) | s < 0 | s > 1] <- NA_real_
  data.frame(year = as.integer(names(den)), share = s, eluc = as.numeric(den))
}
lo <- share_of(1); ce <- share_of(2); hi <- share_of(3)
stopifnot(identical(lo$year, ce$year), identical(hi$year, ce$year))

n_bad <- sum(is.na(ce$share))
cat(sprintf("[2] %d of %d years have no well-defined share (|E_luc| ~ 0 or ratio outside [0,1])%s\n",
            n_bad, nrow(ce),
            if (n_bad) sprintf(": %s", paste(ce$year[is.na(ce$share)], collapse = ", ")) else ""))

# Fill any such year by linear interpolation in time between defined neighbours,
# holding at the ends. Stated rather than silent; it is a gap rule on a
# well-behaved monotone-ish series, not a fabrication of missing data.
fill <- function(d) {
  k <- !is.na(d$share)
  if (!any(k)) stop("no defined shares at all")
  d$share <- stats::approx(d$year[k], d$share[k], xout = d$year, rule = 2)$y
  d
}
lo <- fill(lo); ce <- fill(ce); hi <- fill(hi)
stopifnot(all(lo$share <= ce$share + 1e-12), all(ce$share <= hi$share + 1e-12))

out <- data.frame(year = ce$year, share_lo = lo$share, share = ce$share,
                  share_hi = hi$share, eluc = ce$eluc)

# ---------------------------------------------------------------------
# Report, in the same periods the diagnostic used, so the two are comparable.
# ---------------------------------------------------------------------
cat(sprintf("\n[3] NH share of E_LUC by period, against the incumbent constant %.2f\n\n",
            FORC_LUC_NH_SHARE))
cat(sprintf("%14s %11s %9s %9s %9s\n", "period", "E_luc GtC", "lo", "central", "hi"))
per <- list(c(1750, 1849), c(1850, 1899), c(1900, 1949), c(1950, 1989), c(1990, 2018))
wmean <- function(x, w) sum(x * w) / sum(w)
for (p in c(per, list(LNS_YEARS))) {
  k <- out$year >= p[1] & out$year <= p[2]
  w <- out$eluc[k]
  cat(sprintf("%14s %11.1f %9.3f %9.3f %9.3f\n", sprintf("%d-%d", p[1], p[2]),
              sum(w), wmean(out$share_lo[k], w), wmean(out$share[k], w),
              wmean(out$share_hi[k], w)))
}

# The whole-record flux-weighted central share is the ONE number a constant
# could have been set to, and it is reported so that "0.55 is wrong" is a
# statement about the trajectory rather than about the mean.
w_all <- out$eluc
cat(sprintf("\n[4] flux-weighted mean over the whole record: %.3f (incumbent constant %.2f)\n",
            wmean(out$share, w_all), FORC_LUC_NH_SHARE))
cat(sprintf("    and the point of the product is that no constant works: %.3f (1750s) -> %.3f (2010s)\n",
            wmean(out$share[out$year < 1760], out$eluc[out$year < 1760]),
            wmean(out$share[out$year >= 2010], out$eluc[out$year >= 2010])))

saveRDS(list(
  share      = out,
  nh_frac    = LNS_NH_FRAC,
  source     = LNS_SOURCE,
  sheet      = LNS_SHEET,
  file       = LNS_FILE,
  years      = LNS_YEARS,
  total_PgC  = tot,
  n_undefined = n_bad,
  built      = as.character(Sys.Date()),
  note = paste(
    "TIME-VARYING NH share of E_LUC, flux-weighted over OSCAR's 11 regions.",
    "The regional E_LUC series is sourced; the within-region NH fractions are",
    "geographic judgements carried as the lo/hi bracket. Coverage is",
    "1750-2018: OUTSIDE that range ccx_luc_nh_share() HOLDS THE END VALUE,",
    "which is a stated extrapolation and not a measurement -- it is the reason",
    "any SSP run's land-use hemispheric split is a held 2018 share.")
), LNS_OUT)
cat(sprintf("\nwrote %s\n", LNS_OUT))
