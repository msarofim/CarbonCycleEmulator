#!/usr/bin/env Rscript
# =====================================================================
# diag_ocean_climate_gobm.R -- THE OCEAN'S CLIMATE EFFECT, LIKE-FOR-LIKE WITH GCB 2025's OCEAN MODELS
# (2026-10-04 p; the open item of CHANGELOG 10-04 (o) D, handoff 10-04c §4 item 3.)
#
# THE TRIGGER. diag_mix_preview.R §D read CCX's ocean climate effect, 2015-24, as -0.430 GtC/yr against
# GCB 2025's -0.20 +/- 0.05 (z -4.6) and flagged it NOT like-for-like: GCB's baseline is a "normal
# year" whose year was unverified, its ocean models carry winds, and CO2 is interactive here.
#
# GCB 2025, VERIFIED (ESSD 18:3211; main text p. 3242; Supplement S.3.2 and Table S2, printed pp. 14
# and 32-33, Supplement PDF md5 in OC_SUPP_MD5):
#   - the effect is sim A minus sim C. A: historical climate and CO2. C: historical CO2 under "repeated
#     year or normal year atmospheric climate forcing". CO2 is PRESCRIBED, the same in A and C.
#   - "reducing the ocean sink globally by 0.20 ± 0.05 GtC yr−1 (−7.1 % relative to the simulation
#     that only accounts for the effect of atmospheric CO2 increase) during 2015–2024 (all models
#     simulate a weakening ..., range −4.2 % to −10.7 %)". The ± is 1 sigma over the 10 models (p. 3213:
#     "All uncertainties are reported as ± 1σ").
#   - THERE IS NO SINGLE NORMAL YEAR. Each model has its own (OC_PROTO, transcribed from Table S2): six
#     sit in 1957-1969, two in 1990, two are climatologies (1958-2000, 1958-2024). A's transient
#     climate starts in 1940, 1948 or 1958; before that A runs its normal year, or a loop.
#   - The 10 % upscaling applies to S_OCEAN only (S.3.2, l. 565-572), not to the climate effect.
#
# THE EMULATION, per protocol p, on CCX's own record:
#   - ONLY the climate columns CCX's ocean READS differ between A_p and C_p (OC_OCEAN_COLS): the two
#     HadSST4 hemispheric SST anomalies AND the Nino3.4 index, which drives the L2 ENSO limb
#     (w_enso_l2: El Nino suppresses an upwelling limb). CHECK 0 PROVES the list complete -- every
#     listed column held, everything else historical, CO2 matched: the ocean must not move -- and
#     mutation-tests itself. ⚠ The first version of this driver varied SST alone on a zero-coefficient
#     guard that could not see the L2 limb; the CO2-effect control's wrong-signed sink exposed it.
#   - GMST, AOD and N deposition stay HISTORICAL in both, and the land (which also reads ENSO) is
#     neutralized by the prescribed CO2 below: a CO2 difference cannot reach the ocean.
#   - A_p: the protocol's pre-transient climate from the run start (1750) to t_r, historical after.
#     C_p: the protocol's normal year from 1750 on. Both leave the periodic spinup at the same instant,
#     so the step onto the normal year is common to both and cancels in A - C (CHECK 2).
#   - Repeat years: SST is annual data interpolated monthly, so it repeats as the year's annual mean;
#     the Nino3.4 index is real monthly data, so it repeats month by month (a loop cycles the months,
#     a climatology is the calendar-month mean).
#   - CO2 PRESCRIBED, EXACTLY: C_p's fossil emissions carry an extra term per hemisphere, iterated
#     until both hemispheres' CO2 match A_p's to OC_MATCH_TOL in every month. B_p, the CO2-effect
#     control (zero fossil and land-use emissions), is matched the same way to the pre-industrial
#     orbit.
#   - effect = sink(A) - sink(C); % = effect / (sink(C) - sink(B)), GCB's denominator.
#   - sink = the 2015-24 mean rate of change of ocean_C (the §D convention).
# ROWS. R0 reproduces §D exactly (an identity gate against its stored value); R1 SST only, CO2
# interactive; R2 SST only, prescribed; R3 SST + ENSO, prescribed: the decomposition of what moved.
# Then the ten protocols (SST + ENSO, prescribed; the SST-only and interactive twins beside them),
# their UNWEIGHTED mean and 1-sigma spread (GCB's multi-model mean is unweighted), one interpretation
# sensitivity, and the annual A - C series.
# CHECKS (the like-for-like gap came out WIDER than §D's; implausible = bug until shown otherwise):
# 0 completeness of OC_OCEAN_COLS, with its mutation; 1 the chemistry's d ln pCO2/dT against Takahashi
# 1993; 2 linearity (a shared normal year vs a shared history before t_r); 3 one GOBM's own
# wind/warming split under the same protocol (Bunsen 2024, FESOM-REcoM, 2000-2019); 4 the effect's
# elasticity to each ocean pathway (kz, u_hs, w_enso_l2; spinup re-run, NOT a refit).
# ⚠ STILL NOT LIKE: GOBMs carry winds and every other atmospheric field; CCX carries SST and one ENSO
# limb. In Bunsen 2024's model wind is 0.17 of a 0.25 PgC/yr effect (2000-2019), warming 0.09.
# No RNG. Output: outputs/diagnostics/ocean_climate_gobm_<date>.{log,rds}.
# Usage: Rscript calibration/diag_ocean_climate_gobm.R
#   CCX_OC_HS_FRAC=<f> sets the HS box's share of the SST anomaly (DESIGN §3.4a T; the H1 test, Marcus 2026-10-05
#   "Yes, test") on the canonical, UNREFITTED; the outputs are tagged _hsfrac<f>, R0's identity gate applies only at
#   f = 1, and a section R prints the record's opinion (the canonical's likelihood at f, unrefitted).
#   CCX_OC_MODE="<name>=<path>" (or a registered mode name) reads ANOTHER mode (2026-10-05 g, for objective #16's
#   landing; the scorecard's CCX_SC_EXTRA_MODE convention, since every promoted file is "mode_fit_pumpN.rds"). The
#   outputs are tagged _<name>, and R0's identity gate applies only to OC_MODE_DEFAULT: §D's stored value is its.
#   ⭐ UNDER THE STRATIFICATION FEEDBACK (DESIGN §3.4a S; ccx_mix_on()) THE OCEAN ALSO READS GMST, so GMST joins
#   OC_OCEAN_COLS. CHECK 0 measured the need: at the unrefitted #16 incumbent, with GMST historical and zero
#   emissions, the ocean leaves the orbit at 2.4e-3 GtC/yr, 11x the gate's tolerance.
#   ⭐ RULED (Marcus 2026-10-05: "Held + spun-up lag, both shown"):
#   - THE HEADLINE holds GMST in C, because a GOBM's climate-held run has no climate-driven stratification change.
#   - T_deep is INITIALIZED at each run's own pre-transient GMST (the spec's mean): an ocean spun up under its
#     normal year, as the GOBMs are. The naive hold (T_deep from 0 at 1750) differed by 0.0003 GtC/yr at FESOM.
#   - The GMST-HISTORICAL TWIN is printed beside every protocol and in the ensemble. There the feedback acts alike
#     in A and C, so it measures SST + ENSO in a weakened ocean: the definition every OFF mode's number has.
#   With the feedback OFF nothing here changes; the ocean does not read GMST (CHECK 0 holds as before).
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
OC_DRIVER   <- "calibration/diag_ocean_climate_gobm.R"
OC_MODE_DEFAULT <- "hilda34g"                          # §D's mode: R0's identity gate is its stored value
OC_MODE_ARG <- Sys.getenv("CCX_OC_MODE", "")           # "<name>=<path>" or a registered name; unset = the default
OC_MODE_KV  <- strsplit(OC_MODE_ARG, "=", fixed = TRUE)[[1]]
OC_MODE      <- if (!nzchar(OC_MODE_ARG)) OC_MODE_DEFAULT else if (length(OC_MODE_KV) == 2L) OC_MODE_KV[2] else OC_MODE_ARG
OC_MODE_NAME <- if (!nzchar(OC_MODE_ARG)) OC_MODE_DEFAULT else if (length(OC_MODE_KV) == 2L) OC_MODE_KV[1] else OC_MODE_ARG
OC_MODE_SET  <- !identical(OC_MODE_NAME, OC_MODE_DEFAULT)
if (nzchar(OC_MODE_ARG) && length(OC_MODE_KV) != 2L && !(OC_MODE_ARG %in% names(CCX_MODE_FILES)))
  stop("CCX_OC_MODE: give '<name>=<path>' or a registered mode name (", paste(names(CCX_MODE_FILES), collapse = ", "),
       "); got '", OC_MODE_ARG, "'")
OC_WIN      <- c(2015L, 2024L)
OC_GCB      <- c(mean = -0.20, sd = 0.05)              # GCB 2025 p. 3242, 2015-24; 1 sigma over the 10 GOBMs
OC_GCB_PCT  <- c(mean = -7.1, lo = -10.7, hi = -4.2)   # the same sentence: % of (C - B), and the model range
OC_SUPP_MD5 <- "93a7e289fb61849d31a0163ddbec8f45"     # GCB 2025 Supplement PDF the protocol table was read from
OC_D_CLIM   <- c(1901L, 1920L)                         # §D's held window (diag_mix_preview.R MP_CLIM)
OC_D_RDS    <- ccx_path("outputs", "diagnostics", "mix_preview_20261004.rds")   # §D's stored value: R0's gate
OC_SST      <- c(NH = "sst_anom_NH", SH = "sst_anom_SH")
OC_OCEAN_COLS   <- c(OC_SST, enso = "enso")            # every climate column the ocean reads at OC_MODE (CHECK 0)
OC_GMST_COL     <- c(gmst = "gmst")                    # read by the ocean ONLY under the stratification feedback: appended once V is read
OC_COL_LAB      <- c(sst_anom_NH = "SST", sst_anom_SH = "SST", enso = "ENSO", gmst = "GMST")   # labels derive from the held set
cols_lab        <- function(cols) paste(unique(OC_COL_LAB[unname(cols)]), collapse = " + ")
OC_MONTHLY_COLS <- "enso"                              # real monthly data: repeated month by month
OC_MATCH_TOL   <- 1e-4                                 # ppm, each hemisphere, every month
OC_MATCH_MAXIT <- 80L
OC_GATE_MARGIN <- 100                                  # CHECK 0: allowed sink = margin x OC_MATCH_TOL x the ocean's CO2 sensitivity
OC_SERIES_YRS  <- 1950:2024                            # the annual A - C series (GCB Fig. S10 starts 1959)
OC_DECADES     <- seq(1960L, 2010L, by = 10L)
OC_CHEM_T       <- c(2, 10, 18, 26)                    # degC
OC_CHEM_DIC_ALK <- c(dic = 2050e-6, alk = 2300e-6)     # mol/kg, a typical surface pair
OC_LIN_PROTOS   <- c("CNRM", "PlankTOM12", "Princeton")   # PA == N, so "shared history" is the same climate difference
OC_BUNSEN       <- c(total = 0.25, warming = 0.09, wind = 0.17)  # Bunsen, Nissen & Hauck 2024 GRL 51:e2023GL107030, §3.1 (A-C split)
OC_BUNSEN_WIN   <- c(2000L, 2019L)
OC_PATH_PROTO   <- "CNRM"
OC_PATH_NAMES   <- c("kz", "u_hs", "w_enso_l2")
OC_PATH_ARMS    <- c(list(base = list()), unlist(lapply(OC_PATH_NAMES, function(n)
                     setNames(list(setNames(list(0.5), n), setNames(list(2), n)), paste0(n, c("_half", "_double")))), recursive = FALSE))
OC_HS_FRAC  <- suppressWarnings(as.numeric(Sys.getenv("CCX_OC_HS_FRAC", "")))   # NA = unset = the shipped model
OC_HS_SET   <- is.finite(OC_HS_FRAC)
OC_OUT <- ccx_path("outputs", "diagnostics", sprintf("ocean_climate_gobm_%s%s%s", format(Sys.Date(), "%Y%m%d"),
                                                     if (OC_MODE_SET) paste0("_", OC_MODE_NAME) else "",
                                                     if (OC_HS_SET) sprintf("_hsfrac%g", OC_HS_FRAC) else ""))

# climate specs: a single repeated year, a loop of years (calendar-aligned), a climatology, a month window
yr    <- function(y) list(kind = "year", y = as.integer(y))
loop  <- function(a, b) list(kind = "loop", y = as.integer(c(a, b)))
clim  <- function(a, b) list(kind = "mean", y = as.integer(c(a, b)))
mwin  <- function(a, b) list(kind = "window", t = c(a, b))
spec_lab <- function(s) switch(s$kind, year = sprintf("year %d", s$y), loop = sprintf("loop %d-%d", s$y[1], s$y[2]),
                               mean = sprintf("mean %d-%d", s$y[1], s$y[2]),
                               window = sprintf("months %s-%s", format(s$t[1], nsmall = 3), format(s$t[2], nsmall = 3)))

# ---- THE TEN PROTOCOLS: GCB 2025 Supplement Table S2, rows "Atmospheric forcing for (i) pre-industrial
# spin-up, (ii) spin-up 1850-1958 for simulation B, (iii) simulation B" (N: C is assumed to run B's
# climate, as the S.3.2 text defines it) and "Atmospheric forcing for historical spin-up 1850-1958 for
# simulation A (i) and for simulation A (ii)" (PA, t_r). ⚠ = an interpretation, stated.
OC_PROTO <- list(
  PlankTOM12 = list(model = "NEMO-PlankTOM12", N = yr(1990), PA = yr(1990), t_r = 1948L,
                    src = "B: looping ERA5 year 1990 | A: 1750-1947 looping ERA5 1990; 1948-2023 ERA5"),
  IPSL       = list(model = "NEMO4.2-PISCES (IPSL)", N = loop(1958, 1967), PA = loop(1958, 1967), t_r = 1940L,
                    src = "B(iii): looping 1958-1967 of ERA5 | A: JRA55-do 1958-1967 loop to 1939; full ERA5 1940-2024"),
  NorESM     = list(model = "MICOM-HAMOCC (NorESM-OCv1.2)", N = clim(1958, 2000), PA = clim(1958, 2000), t_r = 1948L,
                    src = paste("B: CORE-I normal year, derived from the 43 yr (1958-2000) of interannual forcing",
                                "(Griffies 2009, Ocean Modelling 26:1, p. 4) | A: CORE-I to 1947; NCEP-R1 + CORE-II corrections from 1948")),
  MPIOM      = list(model = "MPIOM-HAMOCC6", N = yr(1957), PA = loop(1948, 1957), t_r = 1948L,
                    src = "B(ii,iii): NCEP year 1957 | A: NCEP cyclic, 10 yr from 1948; transient NCEP 1948-2021"),
  FESOM      = list(model = "FESOM-2.1-REcoM3", N = yr(1961), PA = yr(1961), t_r = 1958L,
                    src = "B: JRA55-do repeated year 1961 (i, ii), 'ERA5 hourly' (iii) -- read as year 1961 ⚠ | A: repeated 1961; ERA5 hourly"),
  CNRM       = list(model = "NEMO3.6-PISCESv2-gas (CNRM)", N = yr(1958), PA = yr(1958), t_r = 1958L,
                    src = "B(ii,iii): JRA55-do cycling year 1958 | A: cycling 1958; JRA55-do-v1.5.0 1958-2023 (+2024)"),
  Princeton  = list(model = "MOM6-COBALTv3 (Princeton)", N = loop(1958, 1969), PA = loop(1958, 1969), t_r = 1958L,
                    src = "B: ERA5 hourly loop over 1958-1969 | A: the same loop; ERA5 hourly"),
  CESM_ETHZ  = list(model = "CESM-ETHZ", N = clim(1958, 2024), PA = loop(1958, 2024), t_r = 1958L,
                    src = "B: ERA5 NYF, 'mean of 1958-2024 with 2001 anomalies' -- read as the 1958-2024 climatology ⚠ | A: ERA5 repeat cycle 1958-2024; ERA5"),
  MRI        = list(model = "MRI-ESM2-4", N = mwin(1990 + 4 / 12, 1991 + 4 / 12), PA = loop(1948, 2024), t_r = 1958L,
                    src = "B: JRA-3Q repeat year 1990/91 (01May1990-30Apr1991) | A: repeated cycle JRA-3Q 1948-2024 to 1957; 1958-2024"),
  ACCESS     = list(model = "ACCESS (CSIRO)", N = yr(1958), PA = yr(1958), t_r = 1958L,
                    src = "B(ii,iii): cycling ERA5 1958 | A: cycling ERA5 1958; ERA5 1958-2024")
)
# the one interpretation that moves a protocol's baseline materially: CESM-ETHZ's NYF read as year 2001
OC_SENS <- list(CESM_ETHZ_as2001 = modifyList(OC_PROTO$CESM_ETHZ, list(N = yr(2001),
                src = "CESM-ETHZ with its NYF read as year 2001 (the other reading of '2001 anomalies')")))

COMMIT <- ccx_git_stamp()
MODE_FILE <- ccx_mode_file(OC_MODE)
MODE_MD5  <- unname(tools::md5sum(MODE_FILE))
LOGCON <- file(paste0(OC_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | mode %s (%s, md5 %s) | window %d-%d | GCB 2025 %+.2f +/- %.2f GtC/yr (%+.1f %%, range %+.1f to %+.1f %%)\n",
            OC_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), OC_MODE_NAME, MODE_FILE, MODE_MD5, OC_WIN[1], OC_WIN[2],
            OC_GCB[["mean"]], OC_GCB[["sd"]], OC_GCB_PCT[["mean"]], OC_GCB_PCT[["lo"]], OC_GCB_PCT[["hi"]]))

# ---- the canonical, its spinup and its historical forcing (§D's construction) ----------------
V <- dg_vector(OC_MODE)
if (OC_HS_SET) { V$p$hs_sst_anom_frac <- OC_HS_FRAC
  cat(sprintf("⚠ H1 ARM: hs_sst_anom_frac = %g on %s, UNREFITTED (DESIGN §3.4a T); the HS box feels %g of its hemisphere's SST anomaly\n",
              OC_HS_FRAC, OC_MODE, OC_HS_FRAC)) }
# THE STRATIFICATION FEEDBACK (2026-10-05 g): under it the ocean reads GMST, so GMST joins the held set. The RULED
# headline holds it in C with T_deep spun up at each spec's mean GMST (proto_forcings() below; see the header).
OC_MIX <- ccx_mix_on(V$p)
if (OC_MIX) {
  OC_OCEAN_COLS <- c(OC_OCEAN_COLS, OC_GMST_COL)
  cat(sprintf(paste0("⭐ STRATIFICATION FEEDBACK ON (s %g /K, q %g, tau_d %g yr): the ocean reads GMST, so it is held with %s; T_deep ",
                     "starts at each run's own pre-transient GMST (RULED 2026-10-05); the GMST-historical twin is printed beside\n"),
              V$p[["mix_strat_s"]], V$p[["mix_strat_q"]], V$p[["mix_strat_tau"]], cols_lab(setdiff(OC_OCEAN_COLS, "gmst"))))
}
SP <- dg_spinup(V)
F  <- withCallingHandlers(ccx_build_forcing("historical", DG_YEARS, prod_c14 = SP$prod_c14, bomb_total_kmol = V$bomb_total,
                                            luc_scale = V$luc_scale, enso_index = ccx_enso_index_of(V$p), aod_mode = ccx_aod_mode_of(V$p),
                                            nuc_share = ccx_nuc_share_of(V$p)),   # 2026-10-12: label ...wtc
                          warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
cat(sprintf("forcing %d-%d, %d monthly rows; spinup %s; the ocean's climate columns: %s (w_enso_l2 %.3f Sv per index unit)\n",
            DG_YEARS[1], DG_YEARS[2], nrow(F), V$spinup_label, paste(OC_OCEAN_COLS, collapse = " + "), V$p$w_enso_l2))

# A forcing whose ENSO varies from its first row carries the CCX_ENSO_HIST_N months before it as the attribute
# "enso_hist" (the land ENSO term is lagged; R/model.R ccx_land_enso() refuses a varying opening with no history).
# A protocol forcing that holds GMST under the stratification feedback carries "tdeep0", T_deep at its first row
# (the spun-up lag, RULED 2026-10-05; proto_forcings()). Absent = the spinup's 0, every other run.
run  <- function(Fx) { sp <- SP; h <- attr(Fx, "enso_hist"); if (!is.null(h)) sp$enso_hist <- h
  td <- attr(Fx, "tdeep0"); if (!is.null(td)) sp$tdeep0 <- td; ccx_run_fast(sp, Fx)$out }
at_t <- function(out, col, t) stats::approx(out$t, out[[col]], xout = t)$y
sink_win <- function(out) (at_t(out, "ocean_C", OC_WIN[2] + 1) - at_t(out, "ocean_C", OC_WIN[1])) / (OC_WIN[2] + 1 - OC_WIN[1])
sink_ann <- function(out, yrs) at_t(out, "ocean_C", yrs + 1) - at_t(out, "ocean_C", yrs)
co2_win  <- function(out) { k <- out$t >= OC_WIN[1] & out$t < OC_WIN[2] + 1; mean((out$co2_NH[k] + out$co2_SH[k]) / 2) }
sst_win  <- function(Fx) { k <- Fx$year >= OC_WIN[1] & Fx$year <= OC_WIN[2]; mean(vapply(OC_SST, function(cc) mean(Fx[[cc]][k]), 0)) }

# a column's climate under a spec, for every row of F
clim_series <- function(spec, col) {
  x <- F[[col]]; mo <- F$month
  if (col %in% OC_MONTHLY_COLS) {
    key <- paste(F$year, F$month)
    return(switch(spec$kind,
      year   = x[F$year == spec$y][mo],
      loop   = { n <- spec$y[2] - spec$y[1] + 1L; x[match(paste(spec$y[1] + (F$year - spec$y[1]) %% n, mo), key)] },
      mean   = { k <- F$year >= spec$y[1] & F$year <= spec$y[2]; unname(tapply(x[k], F$month[k], mean)[as.character(mo)]) },
      window = { k <- F$t >= spec$t[1] & F$t < spec$t[2]; stopifnot(sum(k) == 12L); unname(setNames(x[k], F$month[k])[as.character(mo)]) }))
  }
  a <- tapply(x, F$year, mean); ay <- as.integer(names(a))
  v <- switch(spec$kind,
    year = a[[as.character(spec$y)]],
    mean = mean(a[ay >= spec$y[1] & ay <= spec$y[2]]),
    window = { k <- F$t >= spec$t[1] & F$t < spec$t[2]; stopifnot(sum(k) == 12L); mean(x[k]) },
    loop = { n <- spec$y[2] - spec$y[1] + 1L; unname(a[as.character(spec$y[1] + (F$year - spec$y[1]) %% n)]) })
  if (length(v) == 1L) rep(v, nrow(F)) else v
}
# the spec's value of a MONTHLY column at calendar (y, m), and the CCX_ENSO_HIST_N months before the run's first
# row under the same spec, oldest first: the protocol's cycle continued back past the run start, which is what
# the GOBM spin-ups ran under (a repeat year or loop before 1750 as after it)
spec_month <- function(spec, col, y, m) { x <- F[[col]]
  switch(spec$kind,
    year   = x[F$year == spec$y & F$month == m],
    loop   = { n <- spec$y[2] - spec$y[1] + 1L; x[F$year == spec$y[1] + (y - spec$y[1]) %% n & F$month == m] },
    mean   = mean(x[F$year >= spec$y[1] & F$year <= spec$y[2] & F$month == m]),
    window = { k <- F$t >= spec$t[1] & F$t < spec$t[2] & F$month == m; stopifnot(sum(k) == 1L); x[k] }) }
clim_hist <- function(spec, col) {
  vapply(CCX_ENSO_HIST_N:1, function(j) { mm <- -j; spec_month(spec, col, DG_YEARS[1] + floor(mm / 12), mm %% 12 + 1) }, 0) }
# an ANNUAL column's own mean under a spec (a loop or a climatology over its years; a window over its 12 months):
# the GMST an ocean spun up under that spec has equilibrated its T_deep to -- the spun-up lag, RULED 2026-10-05
spec_mean <- function(spec, col) { a <- tapply(F[[col]], F$year, mean); ay <- as.integer(names(a))
  switch(spec$kind,
    year   = a[[as.character(spec$y)]],
    loop   = , mean = mean(a[ay >= spec$y[1] & ay <= spec$y[2]]),
    window = { k <- F$t >= spec$t[1] & F$t < spec$t[2]; stopifnot(sum(k) == 12L); mean(F[[col]][k]) }) }

# extra fossil emissions per hemisphere, iterated until both hemispheres' CO2 equal `target`'s every month.
# TIMING (measured: a one-month pulse first shows at the NEXT row): an output row is the state at the START
# of its month, so the update moves the cumulative extra through month i by the residual at row i + 1 (row 1
# is the shared initial state; the last month reaches no row). Without the lead an alternating residual flips
# sign each pass and doubles: the first version diverged.
# TWO MODES. The global mean takes a one-off cumulative shift. The hemispheric DIFFERENCE G = NH - SH does
# not: the gross exchange (R/model.R, rate 1/tau_ex both ways) gives dG/dt = (e_NH - e_SH)/kh - 2G/tau_ex,
# so holding a G correction takes a SUSTAINED flux kh (dG/dt + 2G/tau_ex). A per-hemisphere shift alone
# left a gradient residual that mixing undid each pass (stalled at 0.023 ppm after 80 iterations).
match_co2 <- function(Fbase, target) {
  kh <- ccx_const("GtC_PER_PPM") / 2; dt <- 1 / 12; n <- nrow(Fbase); k_ex <- 1 / V$p$tau_ex
  ex <- list(NH = numeric(n), SH = numeric(n))
  lead_ <- function(r) c(r[-1], r[n])
  for (it in seq_len(OC_MATCH_MAXIT)) {
    Fx <- Fbase; Fx$e_foss_NH <- Fbase$e_foss_NH + ex$NH; Fx$e_foss_SH <- Fbase$e_foss_SH + ex$SH
    out <- run(Fx)
    res <- list(NH = target$co2_NH - out$co2_NH, SH = target$co2_SH - out$co2_SH)
    mx <- max(abs(unlist(res)))
    if (mx < OC_MATCH_TOL) break
    rM <- lead_((res$NH + res$SH) / 2); rG <- lead_(res$NH - res$SH)
    d_sum  <- 2 * kh * c(rM[1], diff(rM)) / dt
    d_diff <- kh * (c(rG[1], diff(rG)) / dt + 2 * k_ex * rG)
    ex$NH <- ex$NH + (d_sum + d_diff) / 2; ex$SH <- ex$SH + (d_sum - d_diff) / 2
  }
  if (mx >= OC_MATCH_TOL) stop(sprintf("the CO2 match did not converge: max |dCO2| %.3g ppm after %d iterations", mx, it))
  list(out = out, iters = it, maxres = mx, extra_GtC = sum(ex$NH + ex$SH) * dt)
}

# the pre-industrial orbit (B's CO2 target): no emissions, the climate held at the run's first row, no AOD,
# no N deposition (ccx_hold_climate() holds neither, by design)
zero_em <- function(Fx) { for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) Fx[[cc]] <- 0 * Fx[[cc]]; Fx }
F_ORBIT <- zero_em(ccx_hold_climate(F, 1L))
for (cc in c("aod_NH", "aod_SH", "ndep_NH", "ndep_SH")) F_ORBIT[[cc]] <- 0 * F_ORBIT[[cc]]
ORBIT <- run(F_ORBIT)
cat(sprintf("pre-industrial orbit (B's target): CO2 %.3f ppm in %d-%d (first year %.3f; drift %+.2e ppm)\n", co2_win(ORBIT),
            OC_WIN[1], OC_WIN[2], mean(((ORBIT$co2_NH + ORBIT$co2_SH) / 2)[1:12]),
            co2_win(ORBIT) - mean(((ORBIT$co2_NH + ORBIT$co2_SH) / 2)[1:12])))

# one A/C/B triple, CO2 interactive and prescribed
triple <- function(FA, FC) {
  oA <- run(FA); oCi <- run(FC)
  mC <- match_co2(FC, oA); mB <- match_co2(zero_em(FC), ORBIT)
  sA <- sink_win(oA); sCi <- sink_win(oCi); sC <- sink_win(mC$out); sB <- sink_win(mB$out)
  list(row = c(sink_A = sA, sink_C_interactive = sCi, effect_interactive = sA - sCi, dco2_interactive = co2_win(oA) - co2_win(oCi),
               sink_C = sC, sink_B = sB, effect = sA - sC, pct = 100 * (sA - sC) / (sC - sB), dsst = sst_win(FA) - sst_win(FC),
               per_K_sst = (sA - sC) / (sst_win(FA) - sst_win(FC)), iters_C = mC$iters, maxres_C = mC$maxres, extra_C_GtC = mC$extra_GtC,
               iters_B = mB$iters, maxres_B = mB$maxres),
       series = sink_ann(oA, OC_SERIES_YRS) - sink_ann(mC$out, OC_SERIES_YRS))
}
proto_forcings <- function(p, cols = OC_OCEAN_COLS) {
  FA <- F; FC <- F; pre <- F$year < p$t_r
  for (cc in cols) { FA[[cc]][pre] <- clim_series(p$PA, cc)[pre]; FC[[cc]] <- clim_series(p$N, cc) }
  if ("enso" %in% cols) { attr(FA, "enso_hist") <- clim_hist(p$PA, "enso"); attr(FC, "enso_hist") <- clim_hist(p$N, "enso") }
  # GMST held (only under the feedback): each run's T_deep starts at its own pre-transient GMST (RULED 2026-10-05)
  if ("gmst" %in% cols) { attr(FA, "tdeep0") <- spec_mean(p$PA, "gmst"); attr(FC, "tdeep0") <- spec_mean(p$N, "gmst") }
  list(FA = FA, FC = FC)
}

# ---- R0-R3: the decomposition of §D ----------------------------------------------------------
cat(sprintf("\n=== R0-R3: §D decomposed (climate held at its %d-%d mean from %d) ===\n", OC_D_CLIM[1], OC_D_CLIM[2], OC_D_CLIM[1]))
held_from <- function(cols) { Fh <- F; sel <- F$year >= OC_D_CLIM[1]; inclim <- F$year >= OC_D_CLIM[1] & F$year <= OC_D_CLIM[2]
  for (cc in cols) Fh[[cc]][sel] <- mean(F[[cc]][inclim]); Fh }
o_full <- run(F); o_R0 <- run(held_from(c("gmst", OC_SST)))
R0 <- sink_win(o_full) - sink_win(o_R0)
D_STORED <- readRDS(OC_D_RDS)$bench["OFF", "effect"]
cat(sprintf("  R0 GMST + SST held, CO2 interactive: effect %+.6f GtC/yr | §D stored %+.6f (%s) -> %s\n", R0, D_STORED, basename(OC_D_RDS),
            if (identical(R0, D_STORED)) "IDENTICAL" else sprintf("DIFFERS by %.3g", R0 - D_STORED)))
# R0's identity gate holds only where §D's stored value is the SAME object: OC_MODE_DEFAULT at frac 1
R0_WHY <- c(if (OC_MODE_SET) sprintf("the mode is %s, not §D's %s", OC_MODE_NAME, OC_MODE_DEFAULT),
            if (OC_HS_SET && OC_HS_FRAC != 1) sprintf("the HS box feels %g of the anomaly; the gate applies at 1", OC_HS_FRAC))
if (!length(R0_WHY)) {
  if (!identical(R0, D_STORED)) stop("R0 does not reproduce §D: the harness differs from the preview's, so nothing below is comparable with it")
} else cat(sprintf("  (R0 differs from §D BY CONSTRUCTION here: %s)\n", paste(R0_WHY, collapse = "; ")))
TR_S  <- triple(F, held_from(OC_SST))
TR_SE <- triple(F, held_from(OC_OCEAN_COLS))
cat(sprintf("  R1 SST only held, CO2 interactive:  effect %+.4f GtC/yr (warm-run CO2 %+.2f ppm)\n", TR_S$row[["effect_interactive"]], TR_S$row[["dco2_interactive"]]))
cat(sprintf("  R2 SST only held, CO2 PRESCRIBED:   effect %+.4f GtC/yr = %+.2f %% of the CO2 effect; %+.3f per K of SST (dSST %+.3f K); match %d iters, max |dCO2| %.1e ppm\n",
            TR_S$row[["effect"]], TR_S$row[["pct"]], TR_S$row[["per_K_sst"]], TR_S$row[["dsst"]], TR_S$row[["iters_C"]], TR_S$row[["maxres_C"]]))
cat(sprintf("  R3 %s held, CO2 PRESCRIBED: effect %+.4f GtC/yr = %+.2f %% (%s share %+.4f; the index's %d-%d mean is %.3f, 0 before 1948)\n",
            cols_lab(OC_OCEAN_COLS), TR_SE$row[["effect"]], TR_SE$row[["pct"]],
            if (OC_MIX) "the ENSO limb's + the feedback's (GMST, T_deep continuing its history)" else "the ENSO limb's",
            TR_SE$row[["effect"]] - TR_S$row[["effect"]], OC_D_CLIM[1], OC_D_CLIM[2],
            mean(F$enso[F$year >= OC_D_CLIM[1] & F$year <= OC_D_CLIM[2]])))
S_OCEAN_CO2 <- (TR_S$row[["effect_interactive"]] - TR_S$row[["effect"]]) / TR_S$row[["dco2_interactive"]]   # GtC/yr per ppm
DECOMP <- stats::setNames(c(R0, TR_S$row[["effect_interactive"]], TR_S$row[["effect"]], TR_SE$row[["effect"]]),
                          c("R0_gmst_sst_interactive", "R1_sst_interactive", "R2_sst_prescribed",
                            paste0("R3_", gsub(" + ", "_", tolower(cols_lab(OC_OCEAN_COLS)), fixed = TRUE), "_prescribed")))

# ---- CHECK 0: is OC_OCEAN_COLS everything the ocean reads? ---------------------------------------
# Every listed column held at row 1, zero emissions, EVERY OTHER column historical (AOD, ndep, and GMST unless the
# feedback put it on the list), CO2 matched to the orbit: an ocean that reads nothing else stays on the orbit.
# Allowed: OC_GATE_MARGIN x the matching tolerance x the ocean's own CO2 sensitivity (measured above from R1/R2).
# The MUTATION drops the ENSO index from the held set (the first version's premise) and must FAIL. Under the
# feedback a SECOND mutation drops GMST and must fail too (2026-10-05 g: the measurement that put it on the list).
cat(sprintf("\n=== CHECK 0. COMPLETENESS: %s held, everything else historical, CO2 matched to the orbit ===\n", paste(OC_OCEAN_COLS, collapse = " + ")))
gate_sink <- function(cols) { Fg <- zero_em(F); for (cc in cols) Fg[[cc]] <- rep(F_ORBIT[[cc]][1], nrow(F))
  m <- match_co2(Fg, ORBIT); c(sink = sink_win(m$out), max_dC = max(abs(m$out$ocean_C - ORBIT$ocean_C))) }
GATE_TOL <- OC_GATE_MARGIN * OC_MATCH_TOL * S_OCEAN_CO2
G0 <- gate_sink(OC_OCEAN_COLS); G0m <- gate_sink(setdiff(OC_OCEAN_COLS, "enso"))
G0g <- if (OC_MIX) gate_sink(setdiff(OC_OCEAN_COLS, "gmst")) else NULL
cat(sprintf("  the ocean's CO2 sensitivity %.4f GtC/yr per ppm -> allowed |sink| %.2e GtC/yr\n", S_OCEAN_CO2, GATE_TOL))
cat(sprintf("  listed columns held:      sink %+.2e GtC/yr, max |ocean_C - orbit| %.2e GtC -> %s\n", G0[["sink"]], G0[["max_dC"]],
            if (abs(G0[["sink"]]) <= GATE_TOL) "PASS" else "FAIL"))
for (mu in Filter(Negate(is.null), list(list("ENSO", G0m), if (OC_MIX) list("GMST", G0g))))
  cat(sprintf("  MUTATION (%s not held): sink %+.2e GtC/yr, max |ocean_C - orbit| %.2e GtC -> %s\n", mu[[1]], mu[[2]][["sink"]], mu[[2]][["max_dC"]],
              if (abs(mu[[2]][["sink"]]) > GATE_TOL) "the gate FAILS it, as it must" else "the gate PASSES it: the gate has no power"))
if (abs(G0[["sink"]]) > GATE_TOL) stop("CHECK 0 FAILED: the ocean reads a climate column the emulation does not vary")
if (abs(G0m[["sink"]]) <= GATE_TOL) stop("CHECK 0's mutation passed: the gate cannot see a missing column")
if (OC_MIX && abs(G0g[["sink"]]) <= GATE_TOL) stop("CHECK 0's GMST mutation passed: the gate cannot see the feedback's column")

# ---- THE TEN PROTOCOLS ------------------------------------------------------------------------
cat(sprintf("\n=== THE TEN GCB 2025 GOBM PROTOCOLS, emulated (A: pre-transient climate to t_r, historical after; C: the normal year from %d; CO2 prescribed) ===\n", DG_YEARS[1]))
one_proto <- function(nm, p) {
  fz <- proto_forcings(p); tr <- triple(fz$FA, fz$FC)
  fs <- proto_forcings(p, OC_SST); ts <- triple(fs$FA, fs$FC)
  tr$row <- c(tr$row, effect_sst_only = ts$row[["effect"]], pct_sst_only = ts$row[["pct"]])
  tr$series_sst_only <- ts$series
  # under the feedback, the GMST-HISTORICAL twin (the feedback alike in A and C; "both shown", RULED 2026-10-05)
  if (OC_MIX) { fh <- proto_forcings(p, setdiff(OC_OCEAN_COLS, "gmst")); th <- triple(fh$FA, fh$FC)
    tr$row <- c(tr$row, effect_gmst_historical = th$row[["effect"]], pct_gmst_historical = th$row[["pct"]])
    tr$series_gmst_historical <- th$series }
  parts <- if (OC_MIX) sprintf("SST %+.4f + ENSO %+.4f + GMST %+.4f", ts$row[["effect"]], th$row[["effect"]] - ts$row[["effect"]],
                               tr$row[["effect"]] - th$row[["effect"]]) else
             sprintf("SST %+.4f + ENSO %+.4f", ts$row[["effect"]], tr$row[["effect"]] - ts$row[["effect"]])
  cat(sprintf("  %-17s N %-26s PA %-15s t_r %d | effect %+.4f GtC/yr (%+.2f %%) = %s | dSST %+.3f K | interactive %+.4f (dCO2 %+.2f ppm) | match %d/%d\n",
              nm, spec_lab(p$N), spec_lab(p$PA), p$t_r, tr$row[["effect"]], tr$row[["pct"]], parts,
              tr$row[["dsst"]], tr$row[["effect_interactive"]], tr$row[["dco2_interactive"]], tr$row[["iters_C"]], tr$row[["iters_B"]]))
  tr
}
RES  <- Map(one_proto, names(OC_PROTO), OC_PROTO)
TAB  <- do.call(rbind, lapply(RES, `[[`, "row"))
SER  <- do.call(cbind, lapply(RES, `[[`, "series")); rownames(SER) <- OC_SERIES_YRS
SERS <- do.call(cbind, lapply(RES, `[[`, "series_sst_only")); rownames(SERS) <- OC_SERIES_YRS
ens  <- function(x) c(mean = mean(x), sd = stats::sd(x), min = min(x), max = max(x))
ENS  <- ens(TAB[, "effect"]); ENSS <- ens(TAB[, "effect_sst_only"]); ENSP <- ens(TAB[, "pct"])
cat(sprintf("\n  ENSEMBLE (unweighted, as GCB): effect %+.4f +/- %.4f GtC/yr (1 sigma over the ten; range %+.4f to %+.4f)\n",
            ENS[["mean"]], ENS[["sd"]], ENS[["min"]], ENS[["max"]]))
cat(sprintf("    vs GCB 2025 %+.2f +/- %.2f: difference %+.4f = %+.2f GCB sigmas; ratio %.2f | as %% of the CO2 effect: %+.2f %% (range %+.2f to %+.2f) vs GCB %+.1f %% (range %+.1f to %+.1f)\n",
            OC_GCB[["mean"]], OC_GCB[["sd"]], ENS[["mean"]] - OC_GCB[["mean"]], (ENS[["mean"]] - OC_GCB[["mean"]]) / OC_GCB[["sd"]], ENS[["mean"]] / OC_GCB[["mean"]],
            ENSP[["mean"]], ENSP[["min"]], ENSP[["max"]], OC_GCB_PCT[["mean"]], OC_GCB_PCT[["lo"]], OC_GCB_PCT[["hi"]]))
ENSH <- ENSHP <- NULL
if (!OC_MIX) {
  cat(sprintf("    of it SST (the thermal part) %+.4f +/- %.4f, the ENSO limb %+.4f; the interactive twins' mean %+.4f (CO2 interactivity's share %+.4f)\n",
              ENSS[["mean"]], ENSS[["sd"]], ENS[["mean"]] - ENSS[["mean"]], mean(TAB[, "effect_interactive"]), ENS[["mean"]] - mean(TAB[, "effect_interactive"])))
} else {
  ENSH <- ens(TAB[, "effect_gmst_historical"]); ENSHP <- ens(TAB[, "pct_gmst_historical"])
  cat(sprintf("    of it SST (the thermal part) %+.4f +/- %.4f, the ENSO limb %+.4f, the STRATIFICATION FEEDBACK (GMST held, T_deep spun up) %+.4f; the interactive twins' mean %+.4f (CO2 interactivity's share %+.4f)\n",
              ENSS[["mean"]], ENSS[["sd"]], ENSH[["mean"]] - ENSS[["mean"]], ENS[["mean"]] - ENSH[["mean"]], mean(TAB[, "effect_interactive"]),
              ENS[["mean"]] - mean(TAB[, "effect_interactive"])))
  cat(sprintf("  GMST HISTORICAL in A and C (the feedback alike in both: %s in a weakened ocean, every OFF mode's definition): %+.4f +/- %.4f GtC/yr (range %+.4f to %+.4f); ratio %.2f to GCB; %+.2f %% of the CO2 effect\n",
              cols_lab(setdiff(OC_OCEAN_COLS, "gmst")), ENSH[["mean"]], ENSH[["sd"]], ENSH[["min"]], ENSH[["max"]], ENSH[["mean"]] / OC_GCB[["mean"]], ENSHP[["mean"]]))
}

# ---- the interpretation sensitivity --------------------------------------------------------------
cat("\n=== SENSITIVITY (not in the ensemble) ===\n")
SENS <- Map(one_proto, names(OC_SENS), OC_SENS)
d_sens <- (SENS[[1]]$row[["effect"]] - TAB["CESM_ETHZ", "effect"]) / length(OC_PROTO)
cat(sprintf("  swapping it in moves the ensemble mean by %+.4f GtC/yr\n", d_sens))

# ---- the annual series (GCB Fig. S10's red curve is the GOBMs' version) ------------------------------
SERH <- if (OC_MIX) { s <- do.call(cbind, lapply(RES, `[[`, "series_gmst_historical")); rownames(s) <- OC_SERIES_YRS; s } else NULL
cat(sprintf("\n=== THE ANNUAL A - C SERIES, prescribed CO2, ensemble mean by decade (GtC/yr): %s | SST only%s ===\n",
            cols_lab(OC_OCEAN_COLS), if (OC_MIX) " | GMST historical" else ""))
ens_ser <- rowMeans(SER); ens_sers <- rowMeans(SERS); ens_serh <- if (OC_MIX) rowMeans(SERH) else NULL
for (d0 in OC_DECADES) { k <- OC_SERIES_YRS >= d0 & OC_SERIES_YRS <= d0 + 9L
  cat(sprintf("  %ds: %+.4f (protocol range %+.4f to %+.4f) | %+.4f%s\n", d0, mean(ens_ser[k]), min(colMeans(SER[k, , drop = FALSE])),
              max(colMeans(SER[k, , drop = FALSE])), mean(ens_sers[k]), if (OC_MIX) sprintf(" | %+.4f", mean(ens_serh[k])) else "")) }
k <- OC_SERIES_YRS >= OC_WIN[1] & OC_SERIES_YRS <= OC_WIN[2]
cat(sprintf("  %d-%d: %+.4f | %+.4f%s (the window's annual means; the table's rate uses year-boundary interpolation)\n", OC_WIN[1], OC_WIN[2],
            mean(ens_ser[k]), mean(ens_sers[k]), if (OC_MIX) sprintf(" | %+.4f", mean(ens_serh[k])) else ""))

# ---- CHECKS 1-4: is a 2x gap an implementation artifact? ------------------------------------------------
cat("\n=== CHECK 1. CHEMISTRY: d ln pCO2 / dT at fixed DIC and ALK (Takahashi 1993's 0.0423 /K) ===\n")
CHEM <- t(vapply(OC_CHEM_T, function(T) { p0 <- pco2_from_dic(OC_CHEM_DIC_ALK[["dic"]], OC_CHEM_DIC_ALK[["alk"]], T)
  p1 <- pco2_from_dic(OC_CHEM_DIC_ALK[["dic"]], OC_CHEM_DIC_ALK[["alk"]], T + 1); c(T = T, pco2 = p0, dlnp_dT = log(p1 / p0)) }, numeric(3)))
for (i in seq_len(nrow(CHEM))) cat(sprintf("  T %4.1f C: pCO2 %.1f uatm, d ln pCO2/dT %.4f /K\n", CHEM[i, "T"], CHEM[i, "pco2"], CHEM[i, "dlnp_dT"]))

cat("\n=== CHECK 2. LINEARITY: shared normal year before t_r (literal) vs shared HISTORY before t_r (A = the standard run) ===\n")
LIN <- t(vapply(OC_LIN_PROTOS, function(nm) { p <- OC_PROTO[[nm]]; stopifnot(identical(p$PA, p$N))
  FC2 <- F; post <- F$year >= p$t_r; for (cc in OC_OCEAN_COLS) FC2[[cc]][post] <- clim_series(p$N, cc)[post]
  c(literal = TAB[nm, "effect"], shared_history = triple(F, FC2)$row[["effect"]]) }, numeric(2)))
for (nm in rownames(LIN)) cat(sprintf("  %-11s literal %+.4f | shared history %+.4f | difference %+.5f\n", nm, LIN[nm, "literal"], LIN[nm, "shared_history"],
                                       LIN[nm, "shared_history"] - LIN[nm, "literal"]))

cat(sprintf("\n=== CHECK 3. ONE GOBM's OWN SPLIT (Bunsen 2024 GRL, FESOM1.4-REcoM2, repeat year 1961; %d-%d: total %.2f, warming %.2f, wind %.2f PgC/yr less uptake) ===\n",
            OC_BUNSEN_WIN[1], OC_BUNSEN_WIN[2], OC_BUNSEN[["total"]], OC_BUNSEN[["warming"]], OC_BUNSEN[["wind"]]))
kb <- OC_SERIES_YRS >= OC_BUNSEN_WIN[1] & OC_SERIES_YRS <= OC_BUNSEN_WIN[2]
BUN <- c(sst_only = mean(SERS[kb, "FESOM"]), sst_enso = mean(SER[kb, "FESOM"]),
         if (OC_MIX) c(gmst_historical = mean(SERH[kb, "FESOM"])))
cat(sprintf("  CCX under the FESOM protocol, %d-%d annual means: SST only %+.4f GtC/yr = %.1f x his WARMING part | %s %+.4f = %.1f x his TOTAL%s\n",
            OC_BUNSEN_WIN[1], OC_BUNSEN_WIN[2], BUN[["sst_only"]], -BUN[["sst_only"]] / OC_BUNSEN[["warming"]], cols_lab(OC_OCEAN_COLS), BUN[["sst_enso"]],
            -BUN[["sst_enso"]] / OC_BUNSEN[["total"]],
            if (OC_MIX) sprintf(" | GMST historical %+.4f = %.1f x his TOTAL", BUN[["gmst_historical"]], -BUN[["gmst_historical"]] / OC_BUNSEN[["total"]]) else ""))

cat(sprintf("\n=== CHECK 4. PATHWAYS: the effect (%s) off the %s, one name scaled at a time (spinup and orbit re-run; NOT a refit), %s protocol ===\n",
            cols_lab(OC_OCEAN_COLS), if (OC_MODE_SET) paste("mode", OC_MODE_NAME) else "canonical", OC_PATH_PROTO))
V0 <- V; SP0 <- SP; ORBIT0 <- ORBIT
PATH <- do.call(rbind, lapply(names(OC_PATH_ARMS), function(a) {
  arm <- OC_PATH_ARMS[[a]]; V <<- V0
  for (n in names(arm)) V$p[[n]] <<- V0$p[[n]] * arm[[n]]
  SP <<- dg_spinup(V); ORBIT <<- run(F_ORBIT)
  fz <- proto_forcings(OC_PROTO[[OC_PATH_PROTO]]); r <- triple(fz$FA, fz$FC)$row
  cat(sprintf("  %-17s effect %+.4f GtC/yr | sink_A %.3f | %+.2f %% of the CO2 effect\n", a, r[["effect"]], r[["sink_A"]], r[["pct"]]))
  data.frame(arm = a, effect = r[["effect"]], sink_A = r[["sink_A"]], pct = r[["pct"]]) }))
V <- V0; SP <- SP0; ORBIT <- ORBIT0
el <- function(nm) { lo <- PATH[PATH$arm == paste0(nm, "_half"), ]; hi <- PATH[PATH$arm == paste0(nm, "_double"), ]
  c(effect = log(hi$effect / lo$effect) / log(4), sink = log(hi$sink_A / lo$sink_A) / log(4)) }
for (nm in OC_PATH_NAMES) { e <- el(nm); cat(sprintf("  elasticity to %-9s: effect %.3f, sink %.3f\n", nm, e[["effect"]], e[["sink"]])) }

# ---- R. THE RECORD'S OPINION of the H1 arm (unrefitted; only when CCX_OC_HS_FRAC is set) -------------------
REC <- NULL
if (OC_HS_SET) {
  cat(sprintf("\n=== R. THE RECORD'S OPINION: the canonical's likelihood with hs_sst_anom_frac = %g vs absent, UNREFITTED ===\n", OC_HS_FRAC))
  md <- V$md; bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  g <- ccx_apply_gate(ccx_mode_struct(md)); rp <- ccx_apply_pins(ccx_mode_pins(md))
  u <- ccx_par_to_unc(ccx_mode_par_with_pins(md))
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  sc <- lapply(list(absent = bp, h1 = within(bp, hs_sst_anom_frac <- OC_HS_FRAC)), function(b) {
    v <- ccx_make_logpost(base_params = b, by_stream = TRUE, spinup_fn = spf)(u); unlist(attr(v, "streams")) })
  ccx_unpin_params(rp); ccx_unapply_gate(g)
  stopifnot(identical(sc$absent[names(md$streams)], md$streams))       # the absent arm IS the canonical
  d <- sc$h1 - sc$absent; d <- d[order(-abs(d))]
  REC <- list(d_lik = sum(sc$h1) - sum(sc$absent), by_row = d)
  cat(sprintf("  likelihood %+.4f on %d rows; the rows that move most: %s\n", REC$d_lik, length(d),
              paste(sprintf("%s %+.3f", names(d)[1:6], d[1:6]), collapse = ", ")))
}

sink(); close(LOGCON)
saveRDS(list(table = TAB, ensemble = ENS, ensemble_sst_only = ENSS, ensemble_pct = ENSP, decomposition = DECOMP,
             sensitivity = lapply(SENS, `[[`, "row"), series = SER, series_sst_only = SERS, protocols = OC_PROTO,
             gate = rbind(listed = G0, mutation_enso_free = G0m, mutation_gmst_free = G0g), gate_tol = GATE_TOL, ocean_co2_sensitivity = S_OCEAN_CO2,
             chemistry = CHEM, linearity = LIN, bunsen_window = BUN, pathways = PATH, hs_sst_anom_frac = OC_HS_FRAC, record = REC,
             mode_name = OC_MODE_NAME, mix_on = OC_MIX, ensemble_gmst_historical = ENSH, ensemble_pct_gmst_historical = ENSHP,
             series_gmst_historical = SERH,
             provenance = sprintf(paste("%s @%s; mode %s (%s, md5 %s), spinup %s; forcing %d-%d historical; window %d-%d; ocean climate columns %s;",
                                        paste0(if (OC_HS_SET) sprintf("H1 ARM hs_sst_anom_frac = %g, unrefitted;", OC_HS_FRAC) else "hs_sst_anom_frac absent;",
                                               if (OC_MIX) paste(" stratification feedback ON: GMST held in C with T_deep spun up at each spec's mean GMST",
                                                                 "(RULED 2026-10-05), GMST-historical twins beside;") else ""),
                                        "GCB 2025 ESSD 18:3211 p. 3242 (%+.2f +/- %.2f, 1 sigma) + Supplement Table S2 (PDF md5 %s);",
                                        "CO2 prescribed by matching to %.0e ppm; sink = window-mean d(ocean_C)/dt; no RNG; %s"),
                                  OC_DRIVER, COMMIT, OC_MODE_NAME, MODE_FILE, MODE_MD5, V$spinup_label, DG_YEARS[1], DG_YEARS[2], OC_WIN[1], OC_WIN[2],
                                  paste(OC_OCEAN_COLS, collapse = "+"), OC_GCB[["mean"]], OC_GCB[["sd"]], OC_SUPP_MD5, OC_MATCH_TOL,
                                  format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(OC_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", OC_OUT))
