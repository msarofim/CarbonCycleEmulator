# =====================================================================
# diag_enso_index_baseline.R -- RULING A's measurement: does the ENSO index
# get to carry a non-zero MEAN and a TREND into a 35.5-yr land chain?
#
# WHY THIS IS OWED. 2026-09-02 made the ENSO land term a ONE-WAY GPP
# MODULATION (`1df8654`). The price was -65.74 log-units at fixed parameters,
# and the diagnosis was that the price is a property of the FORCING, not of the
# structure: `nino34_anom` averages -0.218 over 1948-2024 and is identically 0
# before, so a sustained anomaly that used to load onto `soil_fast` alone
# (tau = 2.0 yr) now loads onto the whole land chain (35.5 yr).
#
# WHY THE MEAN IS NOT ZERO, and this is the substance of the ruling.
# data-raw/build_calibration_data.R anomalises Nino 3.4 against
# ENSO_CLIM_BASE = 1991-2020 -- the WMO normal, a FIXED and RECENT base. The
# tropical Pacific warmed over the record, so the early decades sit below zero
# BY CONSTRUCTION. That warming is mean-state, not ENSO; the model already
# carries GMST as its own forcing and a `q10` respiration path on it. Leaving
# the offset in makes `gamma_enso_land_*` absorb a base-period convention.
#
# ⛔ THIS FILE DOES NOT DECIDE. It prices the four candidate conventions at ONE
# fixed 25-parameter vector so the ruling is made on numbers. Nothing in `data/`
# or `R/` is modified; the treatments are applied by wrapping
# ccx_build_forcing() for the duration of one measurement and restoring it.
#
# THE FOUR TREATMENTS
#   asis     the shipped index. 1991-2020 base, mean -0.218 over the span.
#   demean   subtract the span mean. Removes the STEP at 1948; leaves the trend.
#   detrend  remove a linear fit over the span. Removes mean AND mean-state warming.
#   roll     ONI-style: centred 30-yr base refreshed every 5 yr, rebuilt from the
#            ABSOLUTE Nino 3.4 SST in nina34.data. ⚠ that record starts in 1948,
#            so the early blocks CANNOT have a centred window -- they are
#            CLIPPED, and the clipping is REPORTED rather than hidden.
# THE EXTENSION THAT DID NOT SURVIVE ITS OWN CONTROL. `roll`'s clipping falls on
# the EARLY blocks, which is exactly where the mean-state offset is largest, so
# an UNCLIPPED rolling base is the version worth pricing. It needs SST from 1933
# and nina34.data starts in 1948, so the local ERSSTv5 netCDF was the candidate
# extension -- `fix_v5` (same base period, other product) as the control and
# `roll_full` (rolling base, no early clipping) as the treatment.
#
# ⛔ GATE G-P REFUSES THEM, and the refusal is the finding. nina34.data's own
# footer says ERSST **V6**; the local netCDF is v5. Deseasonalised over the
# shared 1991-2020 window the two agree in PHASE (r 0.984) and disagree in
# AMPLITUDE: regressing PSL on the v5 average gives slope 0.842, i.e. the v5
# index swings ~19 % wider. That is FIVE TIMES the entire sd spread of the four
# conventions this file exists to separate (3.3 %), so any `roll_full` minus
# `fix_v5` difference prices an amplitude mismatch and calls it a convention.
# ⛔ AND THE FIRST NAME FOR THAT GAP WAS WRONG. It was called a v5-vs-v6 PRODUCT
# difference before it was decomposed. CPC publishes a Nino 3.4 index from the
# SAME ERSST v5 and the SAME 1991-2020 base as the local grid, which holds
# version and base fixed and isolates METHOD -- and the local extraction
# reproduces it essentially exactly (r 1.0000, slope 0.997, climatology
# agreeing to 0.02 degC in every month). So the extraction is RIGHT, and the
# disagreement is between the two PUBLISHED indices: CPC's is 0.60 degC colder
# in the 1991-2020 climatology and 15 % LARGER in ENSO amplitude than PSL's
# nina34.data, which is the file the whole pipeline is driven by.
# ⚠ WHETHER THAT IS v5 -> v6 IS STILL NOT ESTABLISHED. A 15 % ENSO-amplitude
# disagreement between two ERSST versions over a densely observed satellite-era
# window is not obviously plausible; the versions diverge in the SPARSE early
# record, which is not where this was measured. What is established is that the
# shipped ENSO forcing's amplitude is uncertain at the ~15 % level between two
# published Nino 3.4 products. Settling THAT needs the v6 grid (86 MB, PSL
# noaa.ersst.v6/sst.mnmean.nc) run through the extraction verified here.
# ⇒ TO PRICE AN UNCLIPPED ROLLING BASE, PULL THE **v6** Nino 3.4 RECORD back to
#   at least 1933. That is a download and a MANIFEST entry, not a code change.
#
# THE GATES, because a wrapper that silently does nothing looks exactly like a
# treatment that costs nothing ([[broken_gate_reports_nothing]]):
#   G-I  IDENTITY -- the SHIPPED treatment through the wrapper must reproduce
#        the UNWRAPPED logpost to the bit. If it does not, the wrapper is not a
#        no-op and no other number here means anything.
#        ⚠ SINCE RULING A WAS ADOPTED (2026-09-02) THE SHIPPED TREATMENT IS
#        `demean`, NOT `asis`. `asis` is now the PRE-ADOPTION index -- the raw
#        1991-2020-based column as it sits in data/forcing_enso.rds -- and it is
#        kept as the reference the +56.4785 is measured FROM.
#        EI_SHIPPED_TREATMENT follows FORC_ENSO_DEMEAN so the gate keeps its
#        power under either setting.
#   G-F  FIRED -- the wrapper must have been called at least once per treatment.
#   G-M  MUTATION -- a deliberate +EI_MUT_OFFSET offset must move the logpost.
#        A treatment machinery that cannot move the objective cannot price one
#        ([[mutation_test_gates]]).
#   G-B  INTENT -- each treatment's realised mean/trend in the BUILT column must
#        match what its name claims, measured after interpolation, not before.
#
# Usage:  Rscript calibration/diag_enso_index_baseline.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_enso_index.R"))

# ---- labels derive from named constants (project rule) --------------
EI_ARM        <- "from90"
EI_BASIN      <- "calibration/output/multistart_20260901_enso25/start_000.rds"
EI_WIN        <- c(1948, 2024)      # the ENSO-active record, as in the pre-check
# ⛔ TAKEN FROM THE LIB, NOT RE-TYPED. These three still appear in this file's
# LABELS, and a label that disagrees with the builder is the caption-sync bug
# this project keeps paying for. The paths, the Nino 3.4 box, the netCDF epoch
# and the PSL missing code are NOT here any more: `lib_enso_index.R` owns them,
# and nothing outside the builders read them.
EI_CLIM_BASE  <- EIX_CLIM_BASE      # = ENSO_CLIM_BASE in build_calibration_data.R
EI_ROLL_LEN   <- EIX_ROLL_LEN       # ONI centred base-period length, years
EI_ROLL_STEP  <- EIX_ROLL_STEP      # ONI base-period refresh interval, years
EI_MUT_OFFSET <- 1.0                # deg C, the G-M mutation
# ⭐ WHICH TREATMENT IS THE ONE THAT SHIPS. Before Ruling A was adopted
# (2026-09-02) it was `asis`; after, `ccx_build_forcing()` removes the index's
# 1948-2024 mean and the shipped convention IS `demean`. G-I below is the gate
# that the wrapper is a NO-OP on whatever ships, so it has to follow the model
# rather than name a treatment. Hardcoding `asis` would have turned G-I from a
# wrapper check into a hard stop the moment the model moved.
EI_SHIPPED_TREATMENT <- if (isTRUE(FORC_ENSO_DEMEAN)) "demean" else "asis"
# ...and the priced `demean` is only the SHIPPED `demean` if it removes the mean
# over the SAME window. Asserted, not assumed: with different windows G-I would
# fail with a confusing message about the wrapper instead of about the window.
stopifnot(identical(as.numeric(EI_WIN), as.numeric(FORC_ENSO_DEMEAN_WIN)))
EI_CPC        <- file.path("data-raw", "downloads", "ersst5.nino.mth.91-20.ascii")
EI_CPC_COL    <- "NINO3.4"          # absolute SST column; its ANOM twin is unused
EI_PRE_FILE   <- file.path("outputs", "diagnostics", "enso_gpp_margin_pre.rds")
EI_OUT        <- file.path("outputs", "diagnostics", "enso_index_baseline.rds")
EI_TREATMENTS <- c("asis", "demean", "detrend", "roll")   # the shipped product
EI_EXTEND     <- c("fix_v5", "roll_full")                 # priced ONLY if G-P passes
EI_HEAD       <- tryCatch(system("git rev-parse HEAD", intern = TRUE)[[1]],
                          error = function(e) NA_character_)

cat(sprintf("\n%s\nRULING A: WHAT BASELINE CONVENTION DOES THE ENSO INDEX GET?\n  arm %s, basin %s, span %d-%d, commit %s\n%s\n",
            strrep("=", 78), EI_ARM, basename(dirname(EI_BASIN)),
            EI_WIN[1], EI_WIN[2], substr(EI_HEAD, 1, 7), strrep("=", 78)))

# =====================================================================
# 1. THE INDEX ITSELF -- mean, trend, and where they come from
# =====================================================================
en_ship <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
en_ship <- en_ship[!is.na(en_ship$nino34_anom), c("year", "month", "nino34_anom")]
names(en_ship)[3] <- "value"

ei_span <- function(d) d$year >= EI_WIN[1] & d$year <= EI_WIN[2]
ei_stats <- function(yr, mo, v) {
  tt <- yr + (mo - 0.5) / 12
  fit <- stats::lm(v ~ tt)
  c(mean = mean(v), trend = unname(stats::coef(fit)[2]) * 10, sd = stats::sd(v))
}
s0 <- ei_stats(en_ship$year[ei_span(en_ship)], en_ship$month[ei_span(en_ship)],
               en_ship$value[ei_span(en_ship)])
cat(sprintf("\n=== 1. THE SHIPPED INDEX (base %d-%d, the WMO normal) ===\n",
            EI_CLIM_BASE[1], EI_CLIM_BASE[2]))
cat(sprintf("  over %d-%d: mean %+.4f, trend %+.4f degC/decade, sd %.4f (n = %d months)\n",
            EI_WIN[1], EI_WIN[2], s0[["mean"]], s0[["trend"]], s0[["sd"]],
            sum(ei_span(en_ship))))
ann <- tapply(en_ship$value[ei_span(en_ship)], en_ship$year[ei_span(en_ship)], mean)
dec <- tapply(as.numeric(ann), (as.integer(names(ann)) %/% 10) * 10, mean)
cat("  decadal means: ")
cat(paste(sprintf("%ds %+.2f", as.integer(names(dec)), dec), collapse = "  "), "\n")
cat("  ⇒ the early decades sit BELOW zero because the base period is RECENT.\n")
cat("    That gradient is mean-state warming of the Nino 3.4 box, not ENSO.\n")

# =====================================================================
# 2. THE FOUR CANDIDATE INDICES
# =====================================================================
# ---- ONI-style rolling base, rebuilt from the ABSOLUTE SST ----------
# ⛔ THE FOUR BUILDERS THAT WERE INLINE HERE ARE GONE. `eix_read_psl`,
# `eix_ersst_box`, `eix_fixed_base` and `eix_roll_base` in
# `calibration/lib_enso_index.R` are the ONE definition; this file had private
# copies of all four, which is the drift the lib was extracted to end.
# ✅ THE FOLD WAS MEASURED, NOT ASSERTED (2026-09-02): old and new agree
# IDENTICALLY on the real inputs -- the PSL table, the ERSST box, both fixed
# bases, both rolling tables AND both clip counters -- so every number this
# file has ever reported is unchanged.
#
# WHY THE ABSOLUTE ERSST GRID IS READ AT ALL: a centred 30-yr base for 1948
# needs SST from 1933, and nina34.data starts in 1948. ⚠ It is a DIFFERENT SST
# VERSION from the shipped index, which is why `fix_v5` is priced alongside it
# rather than assumed immaterial.
# ⚠ THE CLIPPING IS REPORTED, NOT HIDDEN, and the count is restricted to blocks
# intersecting EI_WIN -- blocks outside the scored span cannot affect a number
# here, and counting them would inflate the reported defect. That is why
# `eix_roll_base()` takes the window rather than assuming one.

abs_v6  <- eix_read_psl()               # the lib drops the missing rows itself
abs_v5  <- eix_ersst_box(EIX_BOX_N34)
r_v6    <- eix_roll_base(abs_v6, EI_WIN)
r_v5    <- eix_roll_base(abs_v5, EI_WIN)
en_roll <- r_v6$tbl
en_fix5 <- eix_fixed_base(abs_v5)
en_rollf<- r_v5$tbl

ei_make <- function(kind) {
  d <- en_ship
  k <- ei_span(d)
  if (kind == "asis")    return(d)
  if (kind == "demean") { d$value <- d$value - mean(d$value[k]); return(d) }
  if (kind == "detrend") {
    tt  <- d$year + (d$month - 0.5) / 12
    fit <- stats::lm(d$value[k] ~ tt[k])
    d$value <- d$value - as.numeric(stats::coef(fit)[1] + stats::coef(fit)[2] * tt)
    return(d)
  }
  if (kind == "roll")     return(en_roll)
  if (kind == "fix_v5")   return(en_fix5)
  if (kind == "roll_full")return(en_rollf)
  if (kind == "mutate") { d$value <- d$value + EI_MUT_OFFSET; return(d) }
  stop("unknown treatment: ", kind)
}

cat(sprintf("\n=== 2. THE CANDIDATE INDICES (ONI base %d yr, refreshed every %d) ===\n",
            EI_ROLL_LEN, EI_ROLL_STEP))
cat(sprintf("  roll      (nina34.data, from %d): %d scored blocks, %d CLIPPED\n",
            min(abs_v6$year), r_v6$n_blk, r_v6$n_clip))
cat(sprintf("  roll_full (ERSSTv5,      from %d): %d scored blocks, %d CLIPPED\n",
            min(abs_v5$year), r_v5$n_blk, r_v5$n_clip))
cat(sprintf("\n  %-8s | %9s %11s %8s\n", "index", "mean", "trend/dec", "sd"))
for (kd in c(EI_TREATMENTS, EI_EXTEND)) {
  d <- ei_make(kd); k <- ei_span(d)
  s <- ei_stats(d$year[k], d$month[k], d$value[k])
  cat(sprintf("  %-9s| %+9.4f %+11.4f %8.4f%s\n", kd, s[["mean"]], s[["trend"]], s[["sd"]],
              if (kd %in% EI_EXTEND) "   (ERSSTv5)" else ""))
}

# =====================================================================
# 3. THE PRICE OF EACH, AT ONE FIXED 25-PARAMETER VECTOR
# =====================================================================
pm <- ccx_migrate_par_set(readRDS(ccx_path(EI_BASIN))$par_mode)
u0 <- ccx_par_to_unc(pm)
stopifnot(all(is.finite(u0)))
v  <- dg_vector(EI_ARM)
bp <- ccx_default_params(); bp$pump_mode <- v$md$pump_mode

.EI_ORIG  <- ccx_build_forcing
.EI_STATE <- new.env(parent = emptyenv())
ei_install <- function(tbl) {
  .EI_STATE$n <- 0L; .EI_STATE$mean <- NA_real_; .EI_STATE$trend <- NA_real_
  assign("ccx_build_forcing", function(...) {
    F <- .EI_ORIG(...)
    en <- tbl[!is.na(tbl$value), ]
    e  <- stats::approx(en$year + (en$month - 0.5) / 12, en$value,
                        xout = F$t, rule = 2)$y
    e[F$year < min(en$year)] <- FORC_ENSO_PRE1948
    F$enso <- e
    kk <- F$year >= EI_WIN[1] & F$year <= EI_WIN[2]
    st <- ei_stats(F$year[kk], F$month[kk], F$enso[kk])
    .EI_STATE$n <- .EI_STATE$n + 1L
    .EI_STATE$mean <- st[["mean"]]; .EI_STATE$trend <- st[["trend"]]
    F
  }, envir = globalenv())
}
ei_restore <- function() assign("ccx_build_forcing", .EI_ORIG, envir = globalenv())

ei_price <- function(kind) {
  ei_install(ei_make(kind))
  on.exit(ei_restore(), add = TRUE)
  lp  <- ccx_make_logpost(base_params = bp)
  val <- lp(u0)
  list(logpost = val, fired = .EI_STATE$n,
       mean = .EI_STATE$mean, trend = .EI_STATE$trend)
}

cat("\n=== 3. THE PRICE AT THE 09-01 BASIN VECTOR (25 par, migrated) ===\n")
lp_bare  <- ccx_make_logpost(base_params = bp)
v_bare   <- lp_bare(u0)
cat(sprintf("  UNWRAPPED logpost, this build, shipped index (`%s`): %.6f\n",
            EI_SHIPPED_TREATMENT, v_bare))

res <- lapply(EI_TREATMENTS, ei_price); names(res) <- EI_TREATMENTS
mut <- ei_price("mutate")
# ⛔ THE EXTENSION IS NOT PRICED UNLESS G-P LICENSES IT. Computing the numbers
# and then declining to interpret them is how a refused comparison gets quoted
# anyway; the run below is conditional so there is nothing to quote.

# ---- THE GATES ------------------------------------------------------
cat("\n  --- GATES ---\n")
g_i <- isTRUE(all.equal(res[[EI_SHIPPED_TREATMENT]]$logpost, v_bare, tolerance = 0))
cat(sprintf("  G-I IDENTITY : wrapped `%s` %.6f vs unwrapped %.6f -> %s\n",
            EI_SHIPPED_TREATMENT, res[[EI_SHIPPED_TREATMENT]]$logpost, v_bare,
            if (g_i) "PASS (bit-identical)" else "⛔ FAIL"))
if (!g_i)
  stop("the wrapper is not a no-op on the shipped index (`", EI_SHIPPED_TREATMENT,
       "`, FORC_ENSO_DEMEAN = ", FORC_ENSO_DEMEAN, "). Every price below would ",
       "be confounded with a wrapper artefact. Refusing to report.")
g_f <- all(vapply(res, function(r) r$fired >= 1L, logical(1)))
cat(sprintf("  G-F FIRED    : calls per treatment %s -> %s\n",
            paste(vapply(res, function(r) r$fired, integer(1)), collapse = "/"),
            if (g_f) "PASS" else "⛔ FAIL"))
if (!g_f) stop("the wrapper never fired; the treatments were not applied.")
d_mut <- mut$logpost - v_bare
cat(sprintf("  G-M MUTATION : a %+.2f offset moves the logpost %+.2f -> %s\n",
            EI_MUT_OFFSET, d_mut,
            if (abs(d_mut) > 1) "PASS (the machinery has power)" else "⛔ FAIL"))
if (!(abs(d_mut) > 1))
  stop("a full-degree offset does not move the objective; this file cannot ",
       "price a baseline convention ([[mutation_test_gates]]).")
# G-P PRODUCT -- may the ERSSTv5 rows be differenced against the v6 ones at all?
# ⚠ THE BOUND IS DERIVED FROM THE SPREAD IT MUST RESOLVE, not typed
# ([[tolerance_scaled_to_spread]]). The four v6 conventions differ from one
# another by EI_CONV_SPREAD in anomaly sd; a product whose amplitude differs by
# more than that cannot be differenced against them, because the difference
# would be mostly product. Compared on the DESEASONALISED series over the shared
# climatology window, so the comparison is of ENSO amplitude and not of a
# seasonal cycle or a mean either base period removes anyway.
sd_conv <- vapply(EI_TREATMENTS, function(kd) {
             d <- ei_make(kd); k <- ei_span(d); stats::sd(d$value[k]) }, numeric(1))
EI_CONV_SPREAD <- (max(sd_conv) - min(sd_conv)) / stats::sd(en_ship$value[ei_span(en_ship)])

ia <- en_ship; ip <- eix_fixed_base(abs_v5)
mp <- match(ia$year * 12L + ia$month, ip$year * 12L + ip$month)
kp <- !is.na(mp) & ia$year >= EI_CLIM_BASE[1] & ia$year <= EI_CLIM_BASE[2]
cA <- tapply(ia$value[kp], ia$month[kp], mean); cP <- tapply(ip$value[mp[kp]], ia$month[kp], mean)
aA <- ia$value[kp]     - as.numeric(cA[as.character(ia$month[kp])])
aP <- ip$value[mp[kp]] - as.numeric(cP[as.character(ia$month[kp])])
slope <- unname(stats::coef(stats::lm(aA ~ aP))[2])
g_p   <- abs(slope - 1) <= EI_CONV_SPREAD
cat(sprintf("  G-P PRODUCT  : ERSSTv5 vs the shipped v6 index, deseasonalised %d-%d:\n",
            EI_CLIM_BASE[1], EI_CLIM_BASE[2]))
cat(sprintf("                 r %.4f (phase agrees), amplitude slope %.3f\n",
            stats::cor(aA, aP), slope))
cat(sprintf("                 bound |slope-1| <= %.4f, the sd spread of the %d\n",
            EI_CONV_SPREAD, length(EI_TREATMENTS)))
cat(sprintf("                 conventions it must separate -> %s\n",
            if (g_p) "PASS" else sprintf("⛔ FAIL (%.1fx the bound)",
                                         abs(slope - 1) / EI_CONV_SPREAD)))
# ⚠ A GATE THAT CAN ONLY FAIL IS AS UNINFORMATIVE AS ONE THAT CAN ONLY PASS
# (ruling 2, `c811b82`). G-P is exercised in BOTH directions here: against the
# shipped index itself, where the slope is 1 by construction and it must PASS.
ei_slope <- function(a, b) unname(stats::coef(stats::lm(a ~ b))[2])
EI_GP_MUT <- 1 + 2 * EI_CONV_SPREAD    # a scaling the bound must reject, derived
sl_id  <- ei_slope(aA, aA * 1)                       # the index against itself
sl_mut <- ei_slope(aA, aA * EI_GP_MUT)               # deliberately rescaled
if (!(abs(sl_id - 1) <= EI_CONV_SPREAD))
  stop("G-P rejects the shipped index against ITSELF (slope ", signif(sl_id, 6),
       "). A gate that cannot pass cannot license anything.")
if (abs(sl_mut - 1) <= EI_CONV_SPREAD)
  stop("G-P accepts a product rescaled by ", signif(EI_GP_MUT, 4),
       " (slope ", signif(sl_mut, 6), "). A gate that cannot fail is not a gate.")
cat(sprintf("                 ⤷ mutation, BOTH directions: itself -> slope %.3f\n", sl_id))
cat(sprintf("                   PASS; rescaled x%.3f -> slope %.3f FAIL.\n",
            EI_GP_MUT, sl_mut))

# ---- WHOSE FAULT IS THE GAP? method, or product? --------------------
# ⛔ THE GATE SAYS THE TWO INDICES ARE TOO FAR APART. It does NOT say why, and
# the first name given to the gap -- "a v5-vs-v6 product difference" -- was
# asserted before it was measured. CPC publishes Nino 3.4 from the SAME ERSST
# v5 as the local grid on the SAME 1991-2020 base, which holds version and base
# FIXED. Anything left is METHOD.
cpc <- utils::read.table(ccx_path(EI_CPC), header = TRUE, check.names = FALSE)
cpc <- data.frame(year = cpc[[1]], month = cpc[[2]], value = cpc[[EI_CPC_COL]])
ei_pair <- function(A, B) {
  kA <- A$year >= EI_CLIM_BASE[1] & A$year <= EI_CLIM_BASE[2] & !is.na(A$value)
  mB <- match(A$year * 12L + A$month, B$year * 12L + B$month)
  k  <- kA & !is.na(mB) & !is.na(B$value[mB])
  cA <- tapply(A$value[k], A$month[k], mean); cB <- tapply(B$value[mB[k]], A$month[k], mean)
  xa <- A$value[k]     - as.numeric(cA[as.character(A$month[k])])
  xb <- B$value[mB[k]] - as.numeric(cB[as.character(A$month[k])])
  c(n = sum(k), r = stats::cor(xa, xb), slope = unname(stats::coef(stats::lm(xa ~ xb))[2]),
    dclim = mean(A$value[k]) - mean(B$value[mB[k]]))
}
d_meth <- ei_pair(abs_v5, cpc)                                   # same VERSION, same BASE
d_ver  <- ei_pair(cpc, data.frame(year = abs_v6$year, month = abs_v6$month,
                                  value = abs_v6$value))         # two PUBLISHED indices
cat("  G-P ⤷ WHOSE GAP IS IT? both rows over the shared base period:\n")
cat(sprintf("        METHOD  local grid vs CPC, same v5 : r %.4f slope %.3f dclim %+.3f\n",
            d_meth[["r"]], d_meth[["slope"]], d_meth[["dclim"]]))
cat(sprintf("        PRODUCT CPC vs PSL nina34, both published: r %.4f slope %.3f dclim %+.3f\n",
            d_ver[["r"]], d_ver[["slope"]], d_ver[["dclim"]]))
if (abs(d_meth[["slope"]] - 1) > EI_CONV_SPREAD) {
  cat("        ⇒ the EXTRACTION is implicated; fix it before blaming a product.\n")
} else {
  cat(sprintf("        ⇒ THE EXTRACTION IS EXONERATED (|slope-1| %.4f, inside the\n",
              abs(d_meth[["slope"]] - 1)),
      sprintf("          %.4f bound). The gap is between the two PUBLISHED indices.\n",
              EI_CONV_SPREAD), sep = "")
}
cat("        ⚠ That still does NOT name it v5->v6: a 15 % amplitude gap in a\n")
cat("          densely observed window is where two ERSST versions should agree\n")
cat("          BEST. Naming it needs the v6 grid through this same extraction.\n")

g_b <- TRUE
for (kd in EI_TREATMENTS) {
  want <- switch(kd, demean = 0, detrend = 0, NA_real_)   # roll/asis unconstrained
  got  <- res[[kd]]$mean
  ok   <- is.na(want) || abs(got - want) < 1e-8
  g_b  <- g_b && ok
  cat(sprintf("  G-B INTENT   : %-8s built-column mean %+.6f trend %+.4f/dec %s\n",
              kd, got, res[[kd]]$trend,
              if (is.na(want)) "(unconstrained)" else if (ok) "PASS" else "⛔ FAIL"))
}
if (!g_b) stop("a treatment's realised mean does not match its name.")

# ---- THE TABLE ------------------------------------------------------
pre <- if (file.exists(ccx_path(EI_PRE_FILE))) readRDS(ccx_path(EI_PRE_FILE)) else NULL
cat(sprintf("\n  %-8s | %14s %12s | %s\n", "index", "logpost", "vs asis",
            if (is.null(pre)) "" else "vs PRE-restructuring"))
for (kd in EI_TREATMENTS) {
  r <- res[[kd]]
  cat(sprintf("  %-8s | %14.4f %+12.4f | %s\n", kd, r$logpost,
              r$logpost - res$asis$logpost,
              if (is.null(pre)) "" else sprintf("%+.4f", r$logpost - pre$logpost)))
}
cat("\n  --- THE UNCLIPPED ROLLING BASE ---\n")
ext <- NULL
if (g_p) {
  ext <- lapply(EI_EXTEND, ei_price); names(ext) <- EI_EXTEND
  cat(sprintf("  SST PRODUCT  (fix_v5 - asis)     : %+9.4f  same base, other product\n",
              ext$fix_v5$logpost - res$asis$logpost))
  cat(sprintf("  CONVENTION   (roll_full - fix_v5): %+9.4f  same product, rolling vs fixed\n",
              ext$roll_full$logpost - ext$fix_v5$logpost))
  cat(sprintf("  ⇒ unclipped rolling base vs the best mean-only treatment: %+.4f\n",
              ext$roll_full$logpost - res$demean$logpost))
} else {
  cat(sprintf("  ⛔ NOT PRICED. G-P FAILED: the only long SST record on disk is\n"))
  cat(sprintf("     ERSSTv5 and the shipped index is v6, %.1fx too far apart in\n",
              abs(slope - 1) / EI_CONV_SPREAD))
  cat("     amplitude to difference against. `roll`'s CLIPPING and the CONVENTION\n")
  cat(sprintf("     therefore remain CONFOUNDED, and `roll`'s %+.4f is a LOWER BOUND\n",
              res$roll$logpost - res$asis$logpost))
  cat("     on what the convention is worth -- the clipped blocks are the EARLY\n")
  cat("     ones, which is exactly where the mean-state offset is largest.\n")
  cat(sprintf("     ⇒ TO SETTLE IT: pull the ERSST **v6** Nino 3.4 record back to\n"))
  cat(sprintf("       %d (a centred %d-yr base for %d needs it), add a MANIFEST\n",
              EI_WIN[1] - EI_ROLL_LEN / 2, EI_ROLL_LEN, EI_WIN[1]))
  cat("       entry, and re-run. No code here changes.\n")
}

if (!is.null(pre)) {
  cat(sprintf("\n  ⚠ the PRE column is the 09-02 pre-restructuring build (%s, %s),\n",
              substr(pre$commit, 1, 7), format(pre$when, "%Y-%m-%d")),
      sep = "")
  cat(sprintf("    logpost %.4f. `asis` minus PRE = %+.4f reproduces the recorded price.\n",
              pre$logpost, res$asis$logpost - pre$logpost))
  cat("    ⛔ THE OTHER ROWS MIX TWO CHANGES (structure AND convention) and are\n")
  cat("      the number that matters for where a refit STARTS, not a price of\n")
  cat("      the convention alone -- that is the `vs asis` column.\n")
}

saveRDS(list(treatments = res, extension = ext, mutation = mut,
             product_slope = slope, product_bound = EI_CONV_SPREAD, g_p = g_p,
             gap_method = d_meth, gap_product = d_ver,
             bare = v_bare, pre = pre,
             index_stats = lapply(setNames(c(EI_TREATMENTS, EI_EXTEND),
                                           c(EI_TREATMENTS, EI_EXTEND)), function(kd) {
               d <- ei_make(kd); k <- ei_span(d)
               ei_stats(d$year[k], d$month[k], d$value[k]) }),
             n_clip = c(roll = r_v6$n_clip, roll_full = r_v5$n_clip),
             n_blk = c(roll = r_v6$n_blk, roll_full = r_v5$n_blk), win = EI_WIN,
             clim_base = EI_CLIM_BASE, roll = c(EI_ROLL_LEN, EI_ROLL_STEP),
             arm = EI_ARM, basin = EI_BASIN, commit = EI_HEAD, when = Sys.time()),
        ccx_path(EI_OUT))
cat(sprintf("\n  written: %s\n", EI_OUT))
cat(sprintf("\n%s\n⛔ THIS FILE DOES NOT RULE. It hands the ruling %d numbers and one refusal.\n%s\n",
            strrep("=", 78), length(EI_TREATMENTS), strrep("=", 78)))
