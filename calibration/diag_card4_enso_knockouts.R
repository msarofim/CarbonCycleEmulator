#!/usr/bin/env Rscript
# =====================================================================
# diag_card4_enso_knockouts.R -- tests T1 and T2 of notes/handoff_2026-11-15_group_b_bundle.md s. 3 (group B, B19).
#
# WHY. Marcus 2026-11-15 asked why a model tuned to the growth record would respond to El Nino "sooner" than the record.
# On card 4a's measure (annual means differenced, 1980-2024) both series' r with Nino 3.4 peak at the twelve months to
# January (lag 11), but at shorter lags the model's r is the higher one (lag 0: +0.29 vs -0.15), which is why the
# year-by-year miss correlates with the same calendar year's index (+0.48) and not with the lag-11 one (-0.03).
# Hypotheses: (H1) structure -- four ENSO settings place the peak but not the lag shape; (H2) estimator -- the timing
# was fitted on the module's centred 12-month growth sampled monthly, and may look different on annual-mean differences.
#
# WHAT.
#   T1 (knockouts). The canonical's ENSO pathways are TWO: the land term (gamma_enso_land_NH/SH, reading the index
#      lag_enso_land months late) and the ocean's layer-2 upwelling limb (w_enso_l2, reading it with no lag). The ocean
#      direct terms are pinned at 0 and the equatorial cell is off (eq_frac 0), so nothing else reads the index; the
#      gate below proves it (both off == the What-if tab's ENSO switch, which zeroes the index itself). Four arms, each
#      spun up and run under the canonical's own spinup: full, ocean limb off, land off, both off. Not refits: each
#      arm keeps every other parameter at the mode.
#   T2 (the module's estimator). The same lag profile on the estimator the ENSO settings were fitted to:
#      ccx_iav_growth_pair() (R/likelihood.R) -- the centred 12-month growth of the global CO2, sampled monthly,
#      detrended by ns(df = LIK_IAV_TREND_DF) over LIK_IAV_WIN, against data/mbl_global_growth_monthly.rds -- correlated
#      with the observed monthly Nino 3.4 CK_MON_LAGS months earlier. Run on the gate run (DG_YEARS, which reaches six
#      months past 2024 as the module needs), every arm.
# Index throughout: the observed Nino 3.4 anomaly (data/forcing_enso.rds nino34_anom), as card 4a's caption uses. On
# card 4a's measure the annual index is rv_enso_annual(lag) (app/R/review.R): the twelve months ending `lag` months
# before December.
# RNG: only the moving-block bootstrap on the full arm's monthly r difference (seed stamped in log and .rds).
# Usage: Rscript calibration/diag_card4_enso_knockouts.R    (repo root; read-only; changes no app text)
# =====================================================================
t_start <- Sys.time()
ROOT <- normalizePath(getwd()); stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
rv_need_gates()

# ---- named constants (every label and filename derives from these) ----------
CK_DRIVER    <- "calibration/diag_card4_enso_knockouts.R"
CK_ANN_LAGS  <- 0:18                    # card 4a's annual index: months before December the twelve-month mean ends
CK_ANN_SHOW  <- c(0L, 3L, 6L, 11L)      # printed in the summary table (11 = the caption's)
CK_MON_LAGS  <- -6:18                   # the module's estimator: months the monthly index leads the growth
CK_MON_SHOW  <- c(-6L, 0L, 3L, 6L)     # -6 = where card 4a's calendar-year index sits on this lag axis (see below)
CK_PARITY    <- 1e-9                    # roundoff bound for the two identity gates (ppm, and r / ppm per yr)
CK_SEED      <- 20261115L
CK_B         <- 2000L                   # bootstrap replicates
CK_BLOCK_MO  <- 24L                     # moving-block length (months): two years, over the index's ~1-yr memory
CK_CI        <- c(0.05, 0.95)
CK_LAND      <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
CK_OCEAN     <- "w_enso_l2"
CK_ARMS <- list(
  full      = list(label = "full model (the canonical)",                      set = list()),
  ocean_off = list(label = sprintf("ocean upwelling limb off (%s = 0)", CK_OCEAN), set = stats::setNames(list(0), CK_OCEAN)),
  land_off  = list(label = sprintf("land ENSO response off (%s = 0)", paste(CK_LAND, collapse = ", ")),
                   set = stats::setNames(list(0, 0), CK_LAND)),
  both_off  = list(label = "both off", set = stats::setNames(list(0, 0, 0), c(CK_OCEAN, CK_LAND))))
CK_STEM <- file.path("outputs", "diagnostics", sprintf("card4_enso_knockouts_%s_%s", format(Sys.Date(), "%Y%m%d"),
                                                       CCX_MODE_CANONICAL))
commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
LOG <- paste0(CK_STEM, ".log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("%s | commit %s%s | canonical %s (md5 %s) | %s\n", CK_DRIVER, commit, if (dirty) " (dirty)" else "",
    CCX_MODE_CANONICAL, md5, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- the arm vector and its gates --------------------------------------------
v <- rv_arm(CCX_MODE_CANONICAL)
if (!identical(v$spinup_label, APP_SPINUP_LABEL)) stop("the mode's spinup (", v$spinup_label, ") is not the app's (", APP_SPINUP_LABEL, ")")
nm <- intersect(names(APP_PARAMS), names(v$p))
dp <- vapply(nm, function(n) { a <- APP_PARAMS[[n]]; b <- v$p[[n]]
  if (is.numeric(a) && is.numeric(b) && length(a) == length(b)) max(abs(a - b)) else if (identical(a, b)) 0 else Inf }, 0)
say("GATE: the app's parameters vs the mode's model list, max |difference| %.1e over %d names -> %s\n",
    max(dp), length(dp), if (max(dp) == 0) "PASS" else "FAIL")
if (max(dp) != 0) stop("the app's parameters are not the mode's: ", paste(names(dp)[dp != 0], collapse = ", "))
say("the ENSO settings at the mode: %s; lag_enso_land %.3f months; ocean direct terms %s; equatorial cell %s\n",
    paste(sprintf("%s %.4g", c(CK_LAND, CK_OCEAN), unlist(v$p[c(CK_LAND, CK_OCEAN)])), collapse = ", "),
    v$p$lag_enso_land, paste(sprintf("%g", unlist(v$p[c("gamma_enso_ocn_NH", "gamma_enso_ocn_SH")])), collapse = "/"),
    if (ccx_eq_on(v$p)) "ON" else "off")

# ---- the runs: one spinup per arm, then the app's span and the gate span ------------------
run_arm <- function(set) {
  p <- v$p; for (n in names(set)) p[[n]] <- set[[n]]
  sp <- v$spinup(p)
  Fa <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = sp$prod_c14)
  oa <- ccx_run_fast(sp, Fa)$out
  v2 <- v; v2$p <- p; v2$spinup <- function(pp) sp           # dg_run() as the gates call it, on this arm's spin
  g <- dg_run(v2)
  list(p = p, app = list(out = oa, F = Fa), gate = list(out = g$out, F = g$F))
}
R <- lapply(CK_ARMS, function(a) run_arm(a$set))
say("runs done (%d arms, app span %d-%d and gate span %d-%d) | %.1f min\n", length(R), APP_HIST_YEARS[1], APP_HIST_YEARS[2],
    DG_YEARS[1], DG_YEARS[2], as.numeric(difftime(Sys.time(), t_start, units = "mins")))

# GATE 1: the full arm on the app's span is the app's historical run
d1 <- max(abs(c(R$full$app$out$co2_NH - APP_HIST$out$co2_NH, R$full$app$out$co2_SH - APP_HIST$out$co2_SH)))
say("GATE 1: full arm vs APP_HIST, max |dCO2| %.2e ppm -> %s\n", d1, if (d1 < CK_PARITY) "PASS" else "FAIL")
if (d1 >= CK_PARITY) stop("the full arm does not reproduce the app's run")
# GATE 2: both off == the What-if tab's ENSO switch (the index zeroed): no third pathway reads the index
sw <- app_run_mechanisms("enso")
d2 <- max(abs(c(R$both_off$app$out$co2_NH - sw$out$co2_NH, R$both_off$app$out$co2_SH - sw$out$co2_SH)))
say("GATE 2: both-off arm vs the What-if ENSO switch (index zeroed), max |dCO2| %.2e ppm -> %s\n", d2,
    if (d2 < CK_PARITY) "PASS (the land term and the limb are every path that reads the index)" else "FAIL")
if (d2 >= CK_PARITY) stop("an ENSO pathway other than the land term and the limb exists")

# ---- T1 on card 4a's measure (annual means differenced, the What if...? tab's window) ---------------------------
ob <- app_obs_growth(APP_OBS_GROWTH)
win <- app_growth_window(APP_CF_YEARS_DEFAULT, range(ob$year))
ANN <- lapply(stats::setNames(CK_ANN_LAGS, paste0("lag", CK_ANN_LAGS)), rv_enso_annual)
ann_mean <- function(t, x) { a <- stats::aggregate(list(x = x), list(year = floor(t + 1e-9)), mean); stats::setNames(a$x, a$year) }
card4a <- function(r) {
  d <- merge(app_annual_growth(r$app$out), ob, by = "year", suffixes = c("_mod", "_obs"))
  d <- d[d$year >= win[1] & d$year <= win[2], ]
  ma <- unname(app_growth_anom(data.frame(year = d$year, g = d$g_mod)))
  oa <- unname(app_growth_anom(data.frame(year = d$year, g = d$g_obs)))
  en <- ann_mean(r$app$F$t, r$app$F$enso)[as.character(d$year)]
  prof <- t(vapply(CK_ANN_LAGS, function(L) { x <- ANN[[paste0("lag", L)]][as.character(d$year)]; ok <- is.finite(x)
    c(model = stats::cor(ma[ok], x[ok]), obs = stats::cor(oa[ok], x[ok]), miss = stats::cor((ma - oa)[ok], x[ok])) }, c(0, 0, 0)))
  list(year = d$year, ma = ma, oa = oa, sd_model = stats::sd(ma), sd_obs = stats::sd(oa),
       r_miss_driver = stats::cor(ma - oa, en), prof = data.frame(lag = CK_ANN_LAGS, prof))
}
A <- lapply(R, card4a)
v4 <- rv_growth_variability()
d3 <- max(abs(c(A$full$ma - v4$model_anom, A$full$sd_model - v4$sd_model,
                A$full$prof$model[A$full$prof$lag == RV_GROWTH_ENSO_LAG_MO] - v4$enso$r_model)))
say("GATE 3: full arm's card 4a numbers vs rv_growth_variability(), max |difference| %.2e -> %s\n", d3,
    if (d3 < CK_PARITY) "PASS" else "FAIL")
if (d3 >= CK_PARITY) stop("the full arm does not reproduce card 4a")

say("\n=== T1 on card 4a's measure (%d-%d, n %d; annual means differenced, anomaly about ns df %d) ===\n",
    win[1], win[2], length(A$full$year), GROWTH_ANOM_DF)
say("  r with Nino 3.4, the twelve months ending LAG months before December (LAG %d = the caption's)\n", RV_GROWTH_ENSO_LAG_MO)
say("  %-10s %8s  %s  %9s  %s\n", "arm", "sd ratio", paste(sprintf("r@%-2d  ", CK_ANN_SHOW), collapse = ""), "peak(lag)",
    "| miss: r with driver (cal. yr), r@0, r@11")
row_of <- function(nm_, a, which = "model") {
  pr <- a$prof; r <- pr[[which]]
  say("  %-10s %8s  %s  %+.2f (%2d)  | %+.2f, %+.2f, %+.2f\n", nm_,
      if (which == "model") sprintf("%.3f", a$sd_model / a$sd_obs) else "1",
      paste(sprintf("%+.2f  ", r[match(CK_ANN_SHOW, pr$lag)]), collapse = ""), max(r), pr$lag[which.max(r)],
      if (which == "model") a$r_miss_driver else NA_real_, if (which == "model") pr$miss[pr$lag == 0] else NA_real_,
      if (which == "model") pr$miss[pr$lag == RV_GROWTH_ENSO_LAG_MO] else NA_real_)
}
for (k in names(A)) row_of(k, A[[k]])
row_of("record", A$full, "obs")
for (k in names(CK_ARMS)) say("    %-10s = %s\n", k, CK_ARMS[[k]]$label)
# each pathway's own contribution: the full run minus the run without it (interaction measured, not assumed away)
contrib_ann <- list(land = A$full$ma - A$land_off$ma, ocean = A$full$ma - A$ocean_off$ma)
inter <- A$full$ma - A$both_off$ma - contrib_ann$land - contrib_ann$ocean
say("  each pathway's contribution (full minus that arm): sd land %.3f, ocean %.3f ppm/yr; interaction sd %.3f\n",
    stats::sd(contrib_ann$land), stats::sd(contrib_ann$ocean), stats::sd(inter))
for (k in names(contrib_ann)) {
  rr <- vapply(CK_ANN_LAGS, function(L) { x <- ANN[[paste0("lag", L)]][as.character(A$full$year)]; ok <- is.finite(x)
    stats::cor(contrib_ann[[k]][ok], x[ok]) }, 0)
  say("    %-5s contribution: %s; peak %+.2f at lag %d, trough %+.2f at lag %d\n", k,
      paste(sprintf("r@%d %+.2f", CK_ANN_SHOW, rr[match(CK_ANN_SHOW, CK_ANN_LAGS)]), collapse = ", "),
      max(rr), CK_ANN_LAGS[which.max(rr)], min(rr), CK_ANN_LAGS[which.min(rr)])
}

# ---- T2: the module's own estimator (centred 12-month growth, monthly, detrended) -------------------------------
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en <- en[order(en$year, en$month), ]
en_k <- en$year * 12L + en$month
nino_at <- function(k) en$nino34_anom[match(k, en_k)]
module <- function(r) {
  gp <- ccx_iav_growth_pair(r$gate$out, r$gate$F)
  prof <- t(vapply(CK_MON_LAGS, function(L) { x <- nino_at(gp$k - L); ok <- is.finite(x)
    c(model = stats::cor(gp$mod[ok], x[ok]), obs = stats::cor(gp$obs[ok], x[ok]),
      miss = stats::cor((gp$mod - gp$obs)[ok], x[ok])) }, c(0, 0, 0)))
  list(k = gp$k, mod = gp$mod, obs = gp$obs, sd_model = stats::sd(gp$mod), sd_obs = stats::sd(gp$obs),
       r_mo = stats::cor(gp$mod, gp$obs), prof = data.frame(lag = CK_MON_LAGS, prof))
}
M <- lapply(R, module)
say("\n=== T2 on the module's estimator (centred 12-month growth, monthly, %d-%d, n %d; detrended ns df %d) ===\n",
    LIK_IAV_WIN[1], LIK_IAV_WIN[2], length(M$full$k), LIK_IAV_TREND_DF)
say("  r with the monthly Nino 3.4 LAG months earlier; r(model, record) is the module's fit statistic\n")
say("  %-10s %8s %8s  %s  %9s  %s\n", "arm", "sd ratio", "r(m,rec)", paste(sprintf("r@%-2d  ", CK_MON_SHOW), collapse = ""),
    "peak(lag)", "| miss r@0, r@peak-of-record")
pk_obs <- M$full$prof$lag[which.max(M$full$prof$obs)]
# (`arm`, not `k`: inside with(M[[arm]], ...) a `k` would resolve to the run's month index, 11-15 first run)
for (arm in names(M)) with(M[[arm]], say("  %-10s %8.3f %+8.3f  %s  %+.2f (%2d)  | %+.2f, %+.2f\n", arm, sd_model / sd_obs, r_mo,
  paste(sprintf("%+.2f  ", prof$model[match(CK_MON_SHOW, prof$lag)]), collapse = ""), max(prof$model),
  prof$lag[which.max(prof$model)], prof$miss[prof$lag == 0], prof$miss[prof$lag == pk_obs]))
with(M$full, say("  %-10s %8s %8s  %s  %+.2f (%2d)\n", "record", "1", "", paste(sprintf("%+.2f  ", prof$obs[match(CK_MON_SHOW, prof$lag)]),
  collapse = ""), max(prof$obs), pk_obs))
contrib_mon <- list(land = M$full$mod - M$land_off$mod, ocean = M$full$mod - M$ocean_off$mod)
for (k in names(contrib_mon)) {
  rr <- vapply(CK_MON_LAGS, function(L) { x <- nino_at(M$full$k - L); ok <- is.finite(x); stats::cor(contrib_mon[[k]][ok], x[ok]) }, 0)
  say("    %-5s contribution: sd %.3f ppm/yr; %s; peak %+.2f at lag %d, trough %+.2f at lag %d\n", k, stats::sd(contrib_mon[[k]]),
      paste(sprintf("r@%d %+.2f", CK_MON_SHOW, rr[match(CK_MON_SHOW, CK_MON_LAGS)]), collapse = ", "),
      max(rr), CK_MON_LAGS[which.max(rr)], min(rr), CK_MON_LAGS[which.min(rr)])
}

# the full arm's model-minus-record r difference, with an error bar: at lag 0 and at the record's peak lag; and the
# difference of the two peak lags (moving-block bootstrap over months; seed set immediately before the resampling)
blk <- function(n, L) { s <- sample.int(n - L + 1L, ceiling(n / L), replace = TRUE)
  as.vector(unlist(lapply(s, function(a) a:(a + L - 1L))))[seq_len(n)] }
X <- vapply(CK_MON_LAGS, function(L) nino_at(M$full$k - L), numeric(length(M$full$k)))
stopifnot(!anyNA(X))
set.seed(CK_SEED)
bs <- t(replicate(CK_B, { i <- blk(nrow(X), CK_BLOCK_MO)
  rm <- stats::cor(M$full$mod[i], X[i, ]); ro <- stats::cor(M$full$obs[i], X[i, ])
  c(dm6 = rm[CK_MON_LAGS == -6] - ro[CK_MON_LAGS == -6],
    d0 = rm[CK_MON_LAGS == 0] - ro[CK_MON_LAGS == 0], dpk = rm[CK_MON_LAGS == pk_obs] - ro[CK_MON_LAGS == pk_obs],
    dlag = CK_MON_LAGS[which.max(rm)] - CK_MON_LAGS[which.max(ro)]) }))
ci <- apply(bs, 2, stats::quantile, probs = CK_CI, names = FALSE)
pf <- M$full$prof
say("  full arm, model minus record (90%% interval, block %d mo, B %d, seed %d):\n", CK_BLOCK_MO, CK_B, CK_SEED)
say("    r at lag -6 (card 4a's calendar year): %+.3f  [%+.3f, %+.3f]\n", pf$model[pf$lag == -6] - pf$obs[pf$lag == -6],
    ci[1, "dm6"], ci[2, "dm6"])
say("    r at lag 0:  %+.3f  [%+.3f, %+.3f]\n", pf$model[pf$lag == 0] - pf$obs[pf$lag == 0], ci[1, "d0"], ci[2, "d0"])
say("    r at lag %d (the record's peak): %+.3f  [%+.3f, %+.3f]\n", pk_obs, pf$model[pf$lag == pk_obs] - pf$obs[pf$lag == pk_obs],
    ci[1, "dpk"], ci[2, "dpk"])
say("    peak lag:    %+d months  [%+.0f, %+.0f]\n", pf$lag[which.max(pf$model)] - pk_obs, ci[1, "dlag"], ci[2, "dlag"])

# ---- the full profiles, for the record ------------------------------------------------------------------
say("\n=== full profiles: model (full arm) and record ===\n")
say("  card 4a's measure  lag: %s\n", paste(sprintf("%5d", CK_ANN_LAGS), collapse = ""))
say("                    model: %s\n", paste(sprintf("%+5.2f", A$full$prof$model), collapse = ""))
say("                   record: %s\n", paste(sprintf("%+5.2f", A$full$prof$obs), collapse = ""))
say("  module estimator   lag: %s\n", paste(sprintf("%5d", CK_MON_LAGS), collapse = ""))
say("                    model: %s\n", paste(sprintf("%+5.2f", M$full$prof$model), collapse = ""))
say("                   record: %s\n", paste(sprintf("%+5.2f", M$full$prof$obs), collapse = ""))
say("            ocean_off model: %s\n", paste(sprintf("%+5.2f", M$ocean_off$prof$model), collapse = ""))
say("             land_off model: %s\n", paste(sprintf("%+5.2f", M$land_off$prof$model), collapse = ""))
say("             both_off model: %s\n", paste(sprintf("%+5.2f", M$both_off$prof$model), collapse = ""))
say("    miss (full minus record): %s\n", paste(sprintf("%+5.2f", M$full$prof$miss), collapse = ""))
say("  card 4a's measure, miss:   %s\n", paste(sprintf("%+5.2f", A$full$prof$miss), collapse = ""))
# THE TWO LAG AXES. Card 4a's growth for year y (annual mean of y minus that of y - 1) is centred on 1 January of y;
# its index for LAG L is the twelve months ending L months before December of y, centred on 1 July of y minus L
# months. So card 4a's LAG L sits at L - CK_HALFYEAR on the module's axis (the index leading the growth by that many
# months); the caption's lag 11 is +5 there, and the calendar year (lag 0) is -6: an index centred six months AFTER
# the growth. Checked on the profiles rather than asserted: each series' peak on one axis against the other.
CK_HALFYEAR <- 6L
pk <- c(model_ann = A$full$prof$lag[which.max(A$full$prof$model)], obs_ann = A$full$prof$lag[which.max(A$full$prof$obs)],
        model_mon = M$full$prof$lag[which.max(M$full$prof$model)], obs_mon = pk_obs)
say("  the two lag axes: card 4a's LAG L = the module's L - %d. Peaks: model %d -> %d (module %d), record %d -> %d (module %d)\n",
    CK_HALFYEAR, pk[["model_ann"]], pk[["model_ann"]] - CK_HALFYEAR, pk[["model_mon"]], pk[["obs_ann"]],
    pk[["obs_ann"]] - CK_HALFYEAR, pk[["obs_mon"]])

prov <- list(driver = CK_DRIVER, commit = commit, dirty = dirty, canonical = CCX_MODE_CANONICAL, mode_file = mode_file, mode_md5 = md5,
             arms = lapply(CK_ARMS, `[[`, "label"), spinup = v$spinup_label,
             card4a = "app_annual_growth() vs app_obs_growth(APP_OBS_GROWTH), app_growth_window(APP_CF_YEARS_DEFAULT), app_growth_anom(); index rv_enso_annual(lag)",
             module = "ccx_iav_growth_pair() on dg_run() (DG_YEARS) vs data/mbl_global_growth_monthly.rds; index data/forcing_enso.rds nino34_anom, monthly",
             rng = sprintf("set.seed(%d) immediately before the moving-block bootstrap (B %d, block %d months), full arm only", CK_SEED, CK_B, CK_BLOCK_MO),
             gates = c(full_vs_app = d1, both_off_vs_switch = d2, card4a = d3), date = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(list(card4a = A, module = M, contrib_ann = contrib_ann, contrib_mon = contrib_mon, bootstrap_ci = ci,
             seed = CK_SEED, provenance = prov), paste0(CK_STEM, ".rds"))
say("\nprovenance: %s @%s%s; %s md5 %s; seed %d (bootstrap); saved %s.{log,rds} | %.1f min\n", CK_DRIVER, commit,
    if (dirty) " (dirty)" else "", CCX_MODE_CANONICAL, md5, CK_SEED, CK_STEM, as.numeric(difftime(Sys.time(), t_start, units = "mins")))
