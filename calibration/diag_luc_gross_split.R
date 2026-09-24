# =====================================================================
# REGROWTH TIER 1 -- UN-NETTING THE PRESCRIBED LAND-USE INPUT
# (Marcus 2026-09-24: "adding forest regrowth as its own number would still be
#  useful (and then assume that it decays to zero in the future)".)
#
# ⭐⭐⭐ THE PREMISE, AND IT IS WHY TIER 1 IS FREE. CCX does not lack forest
# regrowth; it contains it, netted invisibly. The prescribed land-use input is
# GCB's NET bookkeeping flux, which the three bookkeeping models compute as
# gross clearing MINUS gross regrowth before CCX sees a single number. So
# "adding regrowth" is UN-NETTING AN INPUT THE MODEL ALREADY HAS -- an
# arithmetic split of a forcing column, not a new process. Model output is
# bit-identical; there is no refit and objective #13 is untouched.
#
# ⚠⚠ AND THE SPLIT IS ASSERTED FROM GCB's BOOKKEEPING MODELS, NOT MEASURED BY
# CCX. 09-24 (h) showed this record cannot see the split (the discriminating
# test on the early source->sink crossing failed: the excess is FLAT, and
# removing one constant +0.62 GtC/yr offset moves the crossing from 19 yr early
# to 2). Tier 1 does not change that -- it IMPORTS the split. Anything the app
# says about regrowth must carry that sentence.
#
# WHAT THIS SCRIPT DOES: acquires nothing and changes nothing. It establishes
# (a) that the split closes against the model's OWN burnt input, (b) how big
# regrowth is and how much the three bookkeeping models disagree, (c) that
# "regrowth" is convention-dependent BY A FACTOR OF THREE, (d) how much of the
# model's land-use era the observed split actually covers, and (e) that the
# future decay Marcus asked for does NOT fall out for free.
#
# ⛔⛔ (c) AND (e) ARE THE TWO THINGS TO READ BEFORE BUILDING THE PANEL.
#
# Inputs (data-raw/downloads/MANIFEST.csv, keys gcb_luc_components*):
#   data-raw/download_gcb_luc_components.R -- run it first if they are missing.
#
# Run from the repo root:  Rscript calibration/diag_luc_gross_split.R
# =====================================================================

suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
}))

# ---- named constants; every label and filename below derives from these ----
LG_DL        <- "data-raw/downloads"
LG_FILES     <- c(gcb = "gcb2025_luc_components_gcb.csv",
                  BLUE = "gcb2025_luc_components_blue.csv",
                  OSCAR = "gcb2025_luc_components_oscar.csv",
                  LUCE = "gcb2025_luc_components_luce.csv")
LG_OSCAR_XL  <- "oscar_gcb2020_eluc.xlsx"     # OSCAR v3.1, the OTHER convention
LG_REGROW    <- "forest regrowth (total)"     # GCB's own column name; never retyped
LG_PEAT      <- "peat drainage & peat fires"  # mean file only, common to all models
LG_NET       <- "Net"
LG_SPLIT_WIN <- c(1959, 2024)   # the years GCB publishes the decomposition for
LG_MODEL_WIN <- c(1750, 2024)   # the years CCX burns land-use carbon over
LG_WINDOWS   <- list(c(1959, 2024), c(1959, 1968), c(1990, 1999), c(2015, 2024))
LG_OS_WIN    <- c(1959, 2018)   # overlap of OSCAR v3.1's workbook with the GCB sheet
LG_SSP_YRS   <- c(2020, 2050, 2100, 2150)
LG_SSPS      <- c("ssp119", "ssp126", "ssp245", "ssp370", "ssp585")
LG_CLOSE_TOL <- 1e-4    # GtC/yr; the sheet prints to ~5 dp and closes to ~1e-5
LG_IDENT_TOL <- 1e-9    # GtC/yr; GCB's Net vs the model's prescribed net is an
                        # IDENTITY -- the same column -- so it must close to zero,
                        # not to a tolerance
LG_CONVENTIONS <- c("GCB 2025 'forest regrowth (total)'",
                    "OSCAR v3.1 E_negative (gross negative component)")

cat(sprintf("\n%s\nREGROWTH TIER 1: un-netting the prescribed LUC input\nsplit published %d-%d; model burns %d-%d\n%s\n",
            strrep("=", 74), LG_SPLIT_WIN[1], LG_SPLIT_WIN[2],
            LG_MODEL_WIN[1], LG_MODEL_WIN[2], strrep("=", 74)))

rd <- function(f) {
  p <- file.path(LG_DL, f)
  if (!file.exists(p))
    stop(p, " is missing -- run Rscript data-raw/download_gcb_luc_components.R")
  utils::read.csv(p, comment.char = "#", check.names = FALSE)
}
cmp <- lapply(LG_FILES, rd)
win <- function(d, w) d[d$Year >= w[1] & d$Year <= w[2], , drop = FALSE]
mn  <- function(d, col, w) mean(win(d, w)[[col]])
cum <- function(d, col, w) sum(win(d, w)[[col]])

# =====================================================================
# GATE 1 -- the components reproduce Net, for every model
# =====================================================================
# The per-model files omit the peat column but their Net INCLUDES peat: GCB adds
# ONE common peat estimate to each model rather than each model carrying its own.
# Tested with peat added back, which is the only way it closes.
peat <- setNames(cmp$gcb[[LG_PEAT]], cmp$gcb$Year)
g1 <- sapply(names(cmp), function(nm) {
  d <- cmp[[nm]]
  parts <- setdiff(names(d), c("Year", LG_NET))
  s <- rowSums(d[, parts, drop = FALSE])
  if (!(LG_PEAT %in% parts)) s <- s + peat[as.character(d$Year)]
  max(abs(s - d[[LG_NET]]))
})
cat("\n[GATE 1] components (+ common peat) sum to Net:\n")
for (nm in names(g1)) cat(sprintf("         %-6s max |resid| = %.1e GtC/yr\n", nm, g1[[nm]]))
if (max(g1) > LG_CLOSE_TOL)
  stop("the published decomposition does not close; the split is not usable")
cat(sprintf("         all four close within %.0e.\n", LG_CLOSE_TOL))

# MUTATION TEST -- break the closure and confirm GATE 1 sees it.
mut <- cmp$gcb; mut[[LG_REGROW]][1] <- mut[[LG_REGROW]][1] * 0.5
mp <- setdiff(names(mut), c("Year", LG_NET))
mres <- max(abs(rowSums(mut[, mp, drop = FALSE]) - mut[[LG_NET]]))
cat(sprintf("         [mutation] halve one regrowth year -> resid %.3f > %.0e: %s\n",
            mres, LG_CLOSE_TOL, if (mres > LG_CLOSE_TOL) "GATE 1 FAILS as it must" else "GATE 1 IS BLIND"))
if (!(mres > LG_CLOSE_TOL)) stop("GATE 1 does not detect a broken closure")

# =====================================================================
# GATE 2 -- the Net being split IS the net the model burns
# =====================================================================
# Not "is close to". The model's prescribed land-use series comes from GCB's
# HISTORICAL BUDGET sheet; the decomposition comes from the LAND-USE CHANGE
# EMISSIONS sheet of the same workbook. If those two Net columns are the same
# numbers, the split un-nets the model's own input and the whole exercise is
# arithmetic. If they are not, Tier 1 is comparing two products.
eh <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
ov <- intersect(eh$year, cmp$gcb$Year)
d1 <- max(abs(eh$luc_GtC[match(ov, eh$year)] - cmp$gcb[[LG_NET]][match(ov, cmp$gcb$Year)]))
cat(sprintf("\n[GATE 2] LUC-sheet Net vs the model's prescribed net LUC, %d-%d: max |diff| = %.1e GtC/yr\n",
            min(ov), max(ov), d1))
if (d1 > LG_IDENT_TOL)
  stop("the decomposition is of a DIFFERENT series than the model burns; ",
       "Tier 1 would be a comparison, not a split")
cat("         identical -> the split is of the model's OWN input.\n")

# MUTATION TEST -- perturb one year of the prescribed series.
mm <- eh$luc_GtC[match(ov, eh$year)]; mm[10] <- mm[10] + 0.01
d1m <- max(abs(mm - cmp$gcb[[LG_NET]][match(ov, cmp$gcb$Year)]))
cat(sprintf("         [mutation] +0.01 on one prescribed year -> %.1e > %.0e: %s\n",
            d1m, LG_IDENT_TOL, if (d1m > LG_IDENT_TOL) "GATE 2 FAILS as it must" else "GATE 2 IS BLIND"))
if (!(d1m > LG_IDENT_TOL)) stop("GATE 2 does not detect a perturbed input")

# =====================================================================
# GATE 3 -- the two halves sum to the model's BURNT input, luc_scale and all
# =====================================================================
# ⚠ The model does not burn GCB's E_LUC: `luc_scale` is a FITTED name. The halves
# must therefore be scaled the same way, and the closure must be tested against
# the forcing column the model actually integrates -- not against GCB.
md <- readRDS(ccx_mode_file())
pm <- ccx_mode_par_with_pins(md)
if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
LG_LUC_SCALE <- pm$luc_scale
cat(sprintf("\n[GATE 3] mode %s, luc_scale = %.4f\n", CCX_MODE_CANONICAL, LG_LUC_SCALE))
Fc <- suppressWarnings(ccx_build_forcing("historical", LG_MODEL_WIN,
                                         luc_scale = LG_LUC_SCALE,
                                         emis_method = "constant"))
elc <- ccx_forcing_eluc_annual(Fc)
gp  <- cmp$gcb[[LG_NET]] - cmp$gcb[[LG_REGROW]]          # gross positive half
gr  <- cmp$gcb[[LG_REGROW]]                              # gross regrowth half (negative)
i   <- match(cmp$gcb$Year, elc$year)
d3  <- max(abs(LG_LUC_SCALE * (gp + gr) - elc$eluc[i]))
cat(sprintf("         luc_scale x (gross + regrowth) vs the burnt E_luc, %d-%d: max |diff| = %.1e GtC/yr\n",
            LG_SPLIT_WIN[1], LG_SPLIT_WIN[2], d3))
if (d3 > LG_CLOSE_TOL)
  stop("the scaled halves do not reconstruct the burnt input; the no-refit claim is void")
cat("         closes -> un-netting changes NO forcing the model sees.\n")

# MUTATION TEST -- drop the scaling from one half only.
d3m <- max(abs((gp + LG_LUC_SCALE * gr) - elc$eluc[i]))
cat(sprintf("         [mutation] scale only ONE half -> %.3f > %.0e: %s\n",
            d3m, LG_CLOSE_TOL, if (d3m > LG_CLOSE_TOL) "GATE 3 FAILS as it must" else "GATE 3 IS BLIND"))
if (!(d3m > LG_CLOSE_TOL)) stop("GATE 3 does not detect an unscaled half")

# =====================================================================
# ARM A -- how big is regrowth, on GCB's own convention
# =====================================================================
cat(sprintf("\n[ARM A] GCB 2025 3-model mean, GtC/yr (convention: %s)\n", LG_CONVENTIONS[1]))
cat("        window      net   deforest  REGROWTH   other    peat    wood-harvest\n")
for (w in LG_WINDOWS)
  cat(sprintf("        %d-%d  %+6.2f   %+6.2f   %+7.2f  %+6.2f  %+6.2f   %+6.2f\n",
              w[1], w[2], mn(cmp$gcb, LG_NET, w), mn(cmp$gcb, "deforestation (total)", w),
              mn(cmp$gcb, LG_REGROW, w), mn(cmp$gcb, "other transitions", w),
              mn(cmp$gcb, LG_PEAT, w), mn(cmp$gcb, "wood harvest & other forest management", w)))
cat(sprintf("        cumulative %d-%d: gross source %+.1f, regrowth %+.1f, NET %+.1f GtC\n",
            LG_SPLIT_WIN[1], LG_SPLIT_WIN[2],
            cum(cmp$gcb, LG_NET, LG_SPLIT_WIN) - cum(cmp$gcb, LG_REGROW, LG_SPLIT_WIN),
            cum(cmp$gcb, LG_REGROW, LG_SPLIT_WIN), cum(cmp$gcb, LG_NET, LG_SPLIT_WIN)))
cat(sprintf("        regrowth offsets %.0f%% of the gross source over the whole window, %.0f%% over %d-%d\n",
            -100 * cum(cmp$gcb, LG_REGROW, LG_SPLIT_WIN) /
              (cum(cmp$gcb, LG_NET, LG_SPLIT_WIN) - cum(cmp$gcb, LG_REGROW, LG_SPLIT_WIN)),
            -100 * cum(cmp$gcb, LG_REGROW, c(2015, 2024)) /
              (cum(cmp$gcb, LG_NET, c(2015, 2024)) - cum(cmp$gcb, LG_REGROW, c(2015, 2024))),
            2015, 2024))

# ⚠ THE SPREAD IS NOT DECORATION. The number the app would report is a
# three-model mean whose members disagree; report the spread with it.
cat("\n        per bookkeeping model (regrowth, GtC/yr):\n")
for (nm in c("BLUE", "OSCAR", "LUCE", "gcb"))
  cat(sprintf("        %-6s %d-%d %+6.3f   %d-%d %+6.3f\n", nm,
              LG_SPLIT_WIN[1], LG_SPLIT_WIN[2], mn(cmp[[nm]], LG_REGROW, LG_SPLIT_WIN),
              2015, 2024, mn(cmp[[nm]], LG_REGROW, c(2015, 2024))))
sp <- sapply(c("BLUE", "OSCAR", "LUCE"), function(nm) mn(cmp[[nm]], LG_REGROW, c(2015, 2024)))
cat(sprintf("        3-model range over %d-%d: %.3f to %.3f = %.0f%% of the mean\n",
            2015, 2024, min(sp), max(sp), 100 * (max(sp) - min(sp)) / abs(mean(sp))))

# =====================================================================
# ARM B -- ⛔⛔ "REGROWTH" IS CONVENTION-DEPENDENT BY A FACTOR OF THREE
# =====================================================================
# OSCAR v3.1's workbook -- ALREADY in this repo, and already the source of the
# pre-1850 land-use segment -- splits E_luc into E_positive / E_negative and
# covers 1701-2018. It is the obvious way to get a split before 1959. It is also
# a DIFFERENT QUANTITY. GCB reports "wood harvest & other forest management" NET
# of its own post-harvest regrowth, so regrowth inside the harvest rotation never
# reaches GCB's regrowth column; OSCAR's E_negative counts every negative flux in
# the bookkeeping. The two are not vintages of one number.
osx <- as.data.frame(readxl::read_excel(file.path(LG_DL, LG_OSCAR_XL), sheet = "Global"))
osx$Year <- osx$year
cat(sprintf("\n[ARM B] %s, GtC/yr\n", LG_CONVENTIONS[2]))
cat(sprintf("        E_pos + E_neg vs E_luc: max |resid| = %.1e (it closes)\n",
            max(abs(osx$E_positive + osx$E_negative - osx$E_luc))))
for (w in list(c(1750, 1849), c(1850, 1958), LG_OS_WIN, c(2009, 2018)))
  cat(sprintf("        %d-%d  E_luc %+6.3f  E_pos %+6.3f  E_neg %+6.3f   |neg|/pos %.3f\n",
              w[1], w[2], mn(osx, "E_luc", w), mn(osx, "E_positive", w),
              mn(osx, "E_negative", w), -cum(osx, "E_negative", w) / cum(osx, "E_positive", w)))
r_os <- mn(osx, "E_negative", LG_OS_WIN)
r_gc <- mn(cmp$OSCAR, LG_REGROW, LG_OS_WIN)
cat(sprintf("\n        ⛔ SAME MODEL, SAME YEARS (%d-%d): OSCAR v3.1 E_negative %+.3f vs\n",
            LG_OS_WIN[1], LG_OS_WIN[2], r_os))
cat(sprintf("           GCB 2025's OSCAR 'forest regrowth (total)' %+.3f  ->  ratio %.2fx\n",
            r_gc, r_os / r_gc))
cat("           This is a CONVENTION difference, not a vintage one. Any reported\n")
cat("           regrowth number must name which convention it is on.\n")

# =====================================================================
# ARM C -- coverage: the observed split covers a QUARTER of the model's LUC era
# =====================================================================
ela <- ccx_forcing_eluc_annual(Fc)
tot_all <- sum(ela$eluc[ela$year >= LG_MODEL_WIN[1] & ela$year <= LG_MODEL_WIN[2]])
tot_spl <- sum(ela$eluc[ela$year >= LG_SPLIT_WIN[1] & ela$year <= LG_SPLIT_WIN[2]])
cat(sprintf("\n[ARM C] coverage of the observed split\n"))
cat(sprintf("        model burns %.1f GtC of net LUC over %d-%d (luc_scale %.4f applied)\n",
            tot_all, LG_MODEL_WIN[1], LG_MODEL_WIN[2], LG_LUC_SCALE))
cat(sprintf("        of which %.1f GtC (%.0f%%) falls in %d-%d, where the split EXISTS\n",
            tot_spl, 100 * tot_spl / tot_all, LG_SPLIT_WIN[1], LG_SPLIT_WIN[2]))
cat(sprintf("        %d of %d land-use years (%.0f%%) have NO published split.\n",
            (LG_SPLIT_WIN[1] - LG_MODEL_WIN[1]),
            (LG_MODEL_WIN[2] - LG_MODEL_WIN[1] + 1),
            100 * (LG_SPLIT_WIN[1] - LG_MODEL_WIN[1]) / (LG_MODEL_WIN[2] - LG_MODEL_WIN[1] + 1)))

# =====================================================================
# ARM D -- ⛔⛔ THE FUTURE DECAY DOES NOT FALL OUT FOR FREE
# =====================================================================
# The design note in handoff 09-24 (e) said "decays to zero in the future falls
# out for free if regrowth is driven by past clearing: as LUC emissions go to
# zero in the SSPs, so does regrowth". MEASURED, that is wrong for four of the
# five scenarios: the prescribed NET land-use flux does not go to zero, it goes
# NEGATIVE -- which in bookkeeping accounting means precisely that gross regrowth
# OVERTAKES gross clearing. A net series that is going negative cannot be read as
# a regrowth term that is decaying away.
ssp <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
cat("\n[ARM D] prescribed NET land-use flux in the futures, GtC/yr\n")
cat(sprintf("        scenario %s\n", paste(sprintf("%8d", LG_SSP_YRS), collapse = "")))
for (sc in LG_SSPS) {
  d <- ssp[ssp$scenario == sc, ]
  v <- d$luc_GtC[match(LG_SSP_YRS, d$year)]
  cat(sprintf("        %-8s %s   %s\n", sc, paste(sprintf("%+8.3f", v), collapse = ""),
              if (any(v < 0, na.rm = TRUE)) "<- goes NEGATIVE" else ""))
}
cat("        ⇒ a future regrowth path is a PRESCRIBED ASSUMPTION in every scenario,\n")
cat("          not something the net input hands over. It must be labelled as one.\n")

cat(sprintf("\n%s\nDONE. Three gates passed and were mutation-tested.\n%s\n",
            strrep("=", 74), strrep("=", 74)))
