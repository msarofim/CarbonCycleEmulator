# =====================================================================
# diag_seas_signature_inversion.R -- SPLIT THE OBSERVED SEASONAL CYCLE
#                                    INTO ITS LAND AND OCEAN PARTS,
#                                    FROM THE OBSERVATIONS ALONE
#
# THE QUESTION (prereg 2026-08-27d, amendment). The seasonal partition
# problem has been carried for weeks as a single number -- "the model is
# 1.9x too isotopically depleted per ppm at SPO" -- and a single number
# cannot say WHAT to change. It has no phase, so it cannot distinguish
# "too much land" from "an ocean channel arriving in the wrong season",
# and those two call for opposite fixes.
#
# THE INVERSION. diag_seas_channel_decomp.R measured that every seasonal
# channel's d13C harmonic vector is ANTIPHASE to its own CO2 harmonic
# vector to within a month (6.03 / 5.77 / 5.93 months at SPO). So each
# channel's isotopic signature is a signed SCALAR, not a rotation, and
# two vector equations in two vector unknowns close exactly:
#
#     CO2 = L + O                      (2-D first-harmonic vectors)
#     d13 = s_L L + s_O O              s_L, s_O in permil per ppm, NEGATIVE
#  => L = (d13 - s_O CO2) / (s_L - s_O),   O = CO2 - L
#
# Applied to the OBSERVATIONS this returns the observed land and ocean
# components' amplitude AND PHASE with no model in the loop except the two
# signatures -- which are physical (photosynthetic discrimination against
# air-sea exchange), are measured here from the model's own channels, and
# are carried through with their measured spread.
#
# IT IS SCORED AT MLO FIRST, WHERE THE ANSWER IS KNOWN. MLO's cycle is
# land-driven; if the inversion does not return that, it is broken and the
# SH answer is not read (prereg P7). That control is a gate, not a remark.
#
# ERROR BARS ARE NOT OPTIONAL HERE. The observed SPO d13C harmonic is the
# noisiest series in the problem -- its mean-of-per-year-magnitudes exceeds
# its magnitude-of-mean-vector by 1.33x where every other series in the
# problem sits at 1.00-1.02x -- so an inverted component without a bar
# would be a number with no scale. Bootstrapped over YEARS (which resamples
# the observed harmonics' own scatter) crossed with the signature spread.
#
# Usage:  Rscript calibration/diag_seas_signature_inversion.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
if (!exists("%||%")) `%||%` <- function(a, b) if (is.null(a)) b else a
ccx_load_cpp()

SI_YEARS  <- c(1750, 2024)
SI_NBOOT  <- 2000
SI_SEED   <- 20260827
# The two signatures, MEASURED below from the model's own channels rather
# than typed in. These are the fallbacks used only if a channel is degenerate.
SI_LAND_CH  <- c("NEP NH off", "NEP SH off", "resp NH off", "resp SH off")
SI_OCEAN_CH <- c("air-sea NH off", "air-sea SH off")
SI_CASES <- list(
  `NEP NH off`     = list(seas_npp_amp_NH = 0),
  `NEP SH off`     = list(seas_npp_amp_SH = 0),
  `resp NH off`    = list(seas_T_amp_NH   = 0),
  `resp SH off`    = list(seas_T_amp_SH   = 0),
  `air-sea NH off` = list(sst_seas_amp_NH = 0),
  # ⚠ BOTH SH AIR-SEA LIMBS. With the Southern-Ocean entrainment channel
  # (2026-08-27g) the SH ocean has TWO seasonal limbs, and `sst_seas_amp_SH = 0`
  # alone leaves the entrainment one running -- so the case would isolate the
  # SOLUBILITY limb and label it "air-sea SH". That matters twice over here:
  # the OCEAN SIGNATURE s_O is measured from this case, and sec.6's
  # decomposition cross-check reads it. At ent_seas_amp_SH = 0 this is
  # identical to the old one-parameter case, so nothing pre-27g moves.
  `air-sea SH off` = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))                       # PEAK-TO-PEAK
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
dmo    <- function(a, b) { d <- (a - b) %% 12; min(d, 12 - d) } # months apart, wrapped

md <- readRDS(ccx_mode_file())
p0 <- ccx_default_params(); for (n in names(md$par_mode)) p0[[n]] <- md$par_mode[[n]]
p0$pump_mode <- md$pump_mode

# ---- THE SOUTHERN-OCEAN ENTRAINMENT CHANNEL (2026-08-27g) -------------
# 🐛 FIXED 2026-09-04g. This block used to read:
#
#     `ent_seas_amp_SH` is NOT in CCX_PARAM_TABLE and so is NOT in the mode
#     file -- deliberately... It therefore defaults to 0 here.
#     SI_ENT_AMP <- as.numeric(Sys.getenv("CCX_ENT_AMP", "0"))
#     p0$ent_seas_amp_SH <- SI_ENT_AMP
#
# ⛔ THAT COMMENT WENT STALE ON 2026-09-03 AND THE ASSIGNMENT BECAME A BUG.
# `ent_seas_amp_SH` entered CCX_PARAM_TABLE that day (25 -> 26 parameters) and
# IS in the canonical mode file, at 19.029. The unconditional assignment then
# OVERWROTE a fitted parameter with 0 on every run, so this script reported the
# PRE-CHANNEL model while its own banner printed the canonical mode's filename.
# It is the script that PRODUCED the registered SPO_SEAS_* constants, so the
# blast radius is every ratio quoted against them.
# ⇒ [[default_off_hides_the_bug]]: a mechanism defaulted OFF is untested where
# it matters, and a capability comment goes stale silently.
#
# THE CONTRACT NOW. The mode's own value is used unless CCX_ENT_AMP is set;
# setting it is an EXPLICIT override and is announced. An unset env var can no
# longer silently disable a calibrated mechanism.
#
#   CCX_ENT_AMP=0  Rscript ...   # the pre-27g inversion, ON PURPOSE
#   CCX_ENT_AMP=10 Rscript ...   # prereg 27g's P3/P4 amplitude scan
.si_ent_env <- Sys.getenv("CCX_ENT_AMP", "")
if (nzchar(.si_ent_env)) {
  SI_ENT_AMP <- as.numeric(.si_ent_env)
  stopifnot(is.finite(SI_ENT_AMP), SI_ENT_AMP >= 0)
  cat(sprintf("CCX_ENT_AMP OVERRIDE: ent_seas_amp_SH %g -> %g (the MODE's value is being replaced)\n",
              p0$ent_seas_amp_SH %||% 0, SI_ENT_AMP))
  p0$ent_seas_amp_SH <- SI_ENT_AMP
} else {
  # GATE: if the parameter is fitted, the mode MUST have supplied it. A NULL
  # here would fall through to 0 and restore exactly the bug above.
  if ("ent_seas_amp_SH" %in% names(CCX_PARAM_TABLE) &&
      !is.finite(p0$ent_seas_amp_SH %||% NA_real_))
    stop("ent_seas_amp_SH is FITTED but absent from the resolved parameter set: ",
         "the mode was not applied, and defaulting it to 0 would silently ",
         "disable a calibrated mechanism.")
  SI_ENT_AMP <- p0$ent_seas_amp_SH
}

# ---- PARAMETER OVERRIDES, for scoring a REFITTED vector --------------
# The channel is only half of what a refit produces: the other half is where
# the seasonal drivers moved to pay for it. Scoring P3/P4 at the MODE's drivers
# with only the amplitude changed would answer a question nobody asked -- that
# model is not one any fit landed on. CCX_PAR_RDS names an .rds holding a named
# list of parameter overrides (the refit's own `par_ch`, say), applied on top of
# the mode.
SI_PAR_RDS <- Sys.getenv("CCX_PAR_RDS", "")
if (nzchar(SI_PAR_RDS)) {
  ov <- readRDS(SI_PAR_RDS)
  stopifnot(is.list(ov), length(ov) > 0, !is.null(names(ov)))
  unknown <- setdiff(names(ov), names(p0))
  if (length(unknown))
    stop("CCX_PAR_RDS names parameters the model does not have: ",
         paste(unknown, collapse = ", "))
  for (n in names(ov)) p0[[n]] <- ov[[n]]
  cat(sprintf("PARAMETER OVERRIDES from %s: %s\n", basename(SI_PAR_RDS),
              paste(sprintf("%s=%.4g", names(ov), unlist(ov)), collapse = ", ")))
}

obs <- ccx_prepare_obs()
cat(sprintf("mode %s (arm %s) | seas_drivers %g | nboot %d\n",
            basename(ccx_mode_file()), md$pump_mode, p0$seas_drivers, SI_NBOOT))
# READ FROM p0, NOT FROM THE ENV VAR. CCX_PAR_RDS is applied after CCX_ENT_AMP
# and can set the amplitude too; a label printed from SI_ENT_AMP then said
# "channel OFF" over a run with the channel at 4.16. Labels derive from the
# value that is actually used.
cat(sprintf("ent_seas_amp_SH = %g umol/kg%s\n", p0$ent_seas_amp_SH,
            if (p0$ent_seas_amp_SH == 0) "  (channel OFF -- the pre-27g inversion)" else
              sprintf("  (channel ON, peak month %.2f)", CCX_ENT_SEAS_PEAK_MO)))

si_run <- function(mods = list()) {
  p <- p0; for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", SI_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (p$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * p$luc_scale
  ccx_model_stats(ccx_run_fast(sp, F)$out, obs)
}
# Window-mean harmonic vector, on the OBSERVATIONS' own years so model and
# obs are reduced over exactly the same set.
vec <- function(h, yr) { k <- match(yr, h$year); c(mean(h$a[k]), mean(h$b[k])) }
grab <- function(ms, st, sp_, yr)
  vec(if (sp_ == "co2") ms$co2_seas[[st]] else ms$d13_seas[[st]], yr)

# THE INTERSECTION, not the CO2 record's years: the d13C record starts later at
# both stations, and reducing the two species over different year sets would
# invert a CO2 vector against a d13C vector that never saw the same years.
YR   <- lapply(c(MLO = "MLO", SPO = "SPO"), function(st)
  intersect(obs$co2_seas[[st]]$year, obs$d13_seas[[st]]$year))
base <- si_run()
cases <- lapply(SI_CASES, si_run)

# ---------------------------------------------------------------------
sep("1. THE TWO SIGNATURES, measured from the model's own channels")
cat("  A channel's signature is a SIGNED SCALAR only if its d13C vector is\n")
cat("  ANTIPHASE to its CO2 vector. That is GATED, not assumed: any channel\n")
cat("  more than 1.0 month off antiphase is dropped from the average.\n\n")
cat(sprintf("  %-16s %-4s %9s %9s %8s %8s %10s %s\n", "channel", "stn",
            "dCO2", "dd13C", "CO2 mo", "d13 mo", "antiphase", "sig"))
sig_rows <- list()
for (nm in names(SI_CASES)) for (st in c("MLO", "SPO")) {
  dc <- grab(base, st, "co2", YR[[st]]) - grab(cases[[nm]], st, "co2", YR[[st]])
  dd <- grab(base, st, "d13", YR[[st]]) - grab(cases[[nm]], st, "d13", YR[[st]])
  if (amp(dc) < 1e-3) next                       # too small to read a phase off
  off <- abs(dmo(ang_mo(dc), ang_mo(dd)) - 6)    # 0 = perfectly antiphase
  ok  <- off <= 1.0
  cat(sprintf("  %-16s %-4s %9.4f %9.5f %8.2f %8.2f %10s %8.5f%s\n", nm, st,
              amp(dc), amp(dd), ang_mo(dc), ang_mo(dd),
              sprintf("%.2f mo", off), amp(dd) / amp(dc), if (ok) "" else "   DROPPED"))
  if (ok) sig_rows[[length(sig_rows) + 1]] <-
    data.frame(ch = nm, st = st, kind = if (nm %in% SI_LAND_CH) "land" else "ocean",
               sig = amp(dd) / amp(dc))
}
S <- do.call(rbind, sig_rows)
sL <- -mean(S$sig[S$kind == "land"]);  sL_r <- -range(S$sig[S$kind == "land"])
sO <- -mean(S$sig[S$kind == "ocean"]); sO_r <- -range(S$sig[S$kind == "ocean"])
cat(sprintf("\n  s_L = %.5f permil/ppm  (range %.5f .. %.5f, n=%d)\n",
            sL, min(sL_r), max(sL_r), sum(S$kind == "land")))
cat(sprintf("  s_O = %.5f permil/ppm  (range %.5f .. %.5f, n=%d)\n",
            sO, min(sO_r), max(sO_r), sum(S$kind == "ocean")))
cat(sprintf("  SEPARATION s_L/s_O = %.1fx -- the inversion is well conditioned only\n", sL / sO))
cat("  because these differ by an order of magnitude. It is NOT conditioned on\n")
cat("  their exact values, which is why the spread is propagated below.\n")
stopifnot(sL < 0, sO < 0, sL / sO > 3)

# ---------------------------------------------------------------------
# THE INVERSION, with its bar. Bootstrap resamples YEARS of the observed
# per-year harmonics; the signatures are drawn independently and uniformly
# across their measured ranges, so a component's bar carries BOTH.
invert <- function(co2, d13, s_L, s_O) {
  L <- (d13 - s_O * co2) / (s_L - s_O)
  list(L = L, O = co2 - L)
}
boot_one <- function(st, src) {
  hc <- if (src == "obs") obs$co2_seas[[st]] else base$co2_seas[[st]]
  hd <- if (src == "obs") obs$d13_seas[[st]] else base$d13_seas[[st]]
  yr <- YR[[st]]
  kc <- match(yr, hc$year); kd <- match(yr, hd$year)
  n  <- length(yr)
  out <- matrix(NA_real_, SI_NBOOT, 4)
  for (i in seq_len(SI_NBOOT)) {
    j  <- sample.int(n, n, replace = TRUE)
    c2 <- c(mean(hc$a[kc][j]), mean(hc$b[kc][j]))
    d3 <- c(mean(hd$a[kd][j]), mean(hd$b[kd][j]))
    r  <- invert(c2, d3, runif(1, min(sL_r), max(sL_r)), runif(1, min(sO_r), max(sO_r)))
    out[i, ] <- c(amp(r$L), ang_mo(r$L), amp(r$O), ang_mo(r$O))
  }
  out
}
q <- function(x) stats::quantile(x, c(0.025, 0.5, 0.975), names = FALSE)
# Angles are circular: take the median of the bootstrap VECTORS' angle, not
# of the wrapped scalar, or the Dec/Jan seam produces a nonsense interval.
qang <- function(a) { v <- c(mean(sin(a * pi / 6)), mean(cos(a * pi / 6)))
  m <- 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
  d <- ((a - m + 6) %% 12) - 6; c(m + stats::quantile(d, 0.025, names = FALSE), m,
                                  m + stats::quantile(d, 0.975, names = FALSE)) %% 12 }

set.seed(SI_SEED)   # the bootstrap below is the only stochastic thing here, and
                    # an unseeded bar moves by ~0.5 pp between runs -- enough to
                    # walk a share across a prediction's boundary.

sep("2. THE INVERSION -- observed and modelled, land and ocean, WITH BARS")
cat("  Amplitudes PEAK-TO-PEAK ppm; peak month; 95 % bootstrap interval over\n")
cat("  years x signature range. 'share' = component amp / total amp.\n")
res <- list()
for (st in c("MLO", "SPO")) {
  cat(sprintf("\n  --- %s\n", st))
  cat(sprintf("  %-9s %-6s %22s %16s %8s\n", "source", "part",
              "amplitude ppm (95%)", "peak mo (95%)", "share"))
  for (src in c("obs", "model")) {
    tot <- amp(if (src == "obs") grab(obs, st, "co2", YR[[st]])
               else grab(base, st, "co2", YR[[st]]))
    B <- boot_one(st, src)
    for (k in c(land = 1, ocean = 3)) {
      a <- q(B[, k]); m <- qang(B[, k + 1])
      cat(sprintf("  %-9s %-6s  %6.3f [%6.3f,%6.3f] %6.2f [%5.2f,%5.2f] %7.1f%%\n",
                  src, names(which(c(land = 1, ocean = 3) == k)), a[2], a[1], a[3],
                  m[2], m[1], m[3], 100 * a[2] / tot))
      res[[paste(st, src, names(which(c(land = 1, ocean = 3) == k)))]] <-
        list(amp = a, mo = m, share = a[2] / tot)
    }
    cat(sprintf("  %-9s %-6s  %6.3f  (total CO2 harmonic)\n", src, "TOTAL", tot))
  }
}

# ---------------------------------------------------------------------
sep("2b. CROSS-VALIDATION -- the inversion against the DIRECT channel sum")
cat("  On the MODEL side both routes are available: the inversion above, and the\n")
cat("  vector sum of the channels that actually generated the cycle. They are\n")
cat("  independent -- the inversion never sees which channel did what, only the\n")
cat("  two summary harmonics. Agreement here is what licenses reading the\n")
cat("  OBSERVED rows, where only the inversion exists.\n\n")
vsum <- function(st, chs) Reduce(`+`, lapply(chs, function(nm)
  grab(base, st, "co2", YR[[st]]) - grab(cases[[nm]], st, "co2", YR[[st]])))
cat(sprintf("  %-4s %-6s %10s %8s | %10s %8s | %8s %8s\n", "stn", "part",
            "inverted", "peak mo", "channels", "peak mo", "d amp", "d mo"))
for (st in c("MLO", "SPO")) for (kind in c("land", "ocean")) {
  iv <- res[[paste(st, "model", kind)]]
  dv <- vsum(st, if (kind == "land") SI_LAND_CH else SI_OCEAN_CH)
  cat(sprintf("  %-4s %-6s %10.3f %8.2f | %10.3f %8.2f | %+8.1f%% %+8.2f\n",
              st, kind, iv$amp[2], iv$mo[2], amp(dv), ang_mo(dv),
              100 * (iv$amp[2] / amp(dv) - 1), ((iv$mo[2] - ang_mo(dv) + 6) %% 12) - 6))
}
cat("\n  The residual is emission seasonality -- a GLOBAL forcing flag that is in\n")
cat("  neither channel set, carries fossil carbon at -27.9 permil and so inverts\n")
cat("  as LAND -- plus the model's nonlinearity, which sec.2 of the channel\n")
cat("  decomposition measures at 0.0-0.1 %.\n")

# ---------------------------------------------------------------------
sep("3. THE SCORED PREDICTIONS (prereg 2026-08-27d, amendment)")
cat("  FIRST, THE TABLE THE WHOLE DIAGNOSTIC EXISTS TO PRODUCE:\n\n")
cat(sprintf("  %-4s %-6s %9s %9s %7s | %8s %8s %9s\n", "stn", "part",
            "obs amp", "mod amp", "ratio", "obs mo", "mod mo", "phase err"))
for (st in c("MLO", "SPO")) for (kind in c("land", "ocean")) {
  o <- res[[paste(st, "obs", kind)]]; m <- res[[paste(st, "model", kind)]]
  cat(sprintf("  %-4s %-6s %9.3f %9.3f %6.2fx | %8.2f %8.2f %+9.2f\n", st, kind,
              o$amp[2], m$amp[2], m$amp[2] / o$amp[2], o$mo[2], m$mo[2],
              ((m$mo[2] - o$mo[2] + 6) %% 12) - 6))
}
cat("\n")
p7 <- res[["MLO obs land"]]$share
cat(sprintf("  P7 CONTROL -- MLO observed LAND share >= 80%%: %.1f%%  ->  %s\n",
            100 * p7, if (p7 >= 0.80) "PASS, inversion is read" else "FAIL, STOP"))
if (p7 < 0.80) { cat("\n  P5/P6 ARE NOT READ. The control failed.\n"); sep("DONE"); quit(save = "no") }
p5 <- res[["SPO obs ocean"]]$share
cat(sprintf("  P5 -- SPO observed OCEAN share predicted 40-50%%: %.1f%%  ->  %s\n",
            100 * p5, if (p5 >= 0.40 && p5 <= 0.50) "CONFIRMED" else "MISSED"))
mo_obs <- res[["SPO obs ocean"]]$mo
sh_ch  <- grab(base, "SPO", "co2", YR$SPO) - grab(cases[["air-sea SH off"]], "SPO", "co2", YR$SPO)
mo_mod <- ang_mo(sh_ch)
gap    <- dmo(mo_obs[2], mo_mod)
cat(sprintf("  P6 -- observed SPO ocean peak %.2f [%.2f,%.2f] vs the model's SH air-sea\n",
            mo_obs[2], mo_obs[1], mo_obs[3]))
cat(sprintf("        channel at %.2f: %.2f months apart, predicted >= 3  ->  %s\n",
            mo_mod, gap, if (gap >= 3) "CONFIRMED" else "FAILED"))
cat(sprintf("  (model SPO total cycle peaks %.2f; observed %.2f)\n",
            ang_mo(grab(base, "SPO", "co2", YR$SPO)), ang_mo(grab(obs, "SPO", "co2", YR$SPO))))

sep("DONE")
