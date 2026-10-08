#!/usr/bin/env Rscript
# =====================================================================
# diag_card4_audit.R -- every MEASURED claim typed into Known-issues card 4 ("Year-to-year variability"),
# re-measured at the CURRENT canonical (2026-10-08 g).
#
# WHY. hilda29e's adoption (10-08 e) left card 4's "2.5 months" stale, and its guard
# (test-review-card-numbers.R) SKIPPED rather than failed because the canonical PINS the lag. Checking the rest of
# the card found more: the "a little below the range" word was described in review.R as recomputed by a test that
# was never written, and two numbers had gone stale at an EARLIER adoption with nothing watching them. Card 4's
# copy is Marcus's; this driver only puts the numbers beside the typed words. It changes nothing.
#
# WHAT. Each claim is measured through the app's OWN functions (rv_variability, rv_enso_slope, rv_arm + dg_run:
# the structure's ENSO index and AOD mode), except two that already have a committed driver, whose outputs at
# this canonical are READ and gated on their mode file:
#   diag_enso_growth_fit.R   -> T2(b), the CO2 growth peak's lag after Nino 3.4 (the card's "a month ... five")
#   diag_app_wobble_shares.R -> the app estimator's scatter (the title's "about 60%")
# ⚠ calibration/diag_growth_residual_years.R (the N7 paragraph's driver) builds its forcing with the builder's
# DEFAULTS and is REFUSED at a detrended-index canonical by ccx_enso_index_check(). Section 7 reruns its
# arithmetic unchanged on the structure's run; the driver itself is left as it is.
# (FIXED 2026-10-08 (k): the driver now builds the structure's ENSO index and AOD mode, and at hilda29e
# reproduces section 7's correlations and decade means bit for bit.)
#
# GATES (stop on any): the module check file's base_md5 is the canonical's mode file; the lag it was fitted at is
# the lag the canonical RUNS; both read outputs name the canonical's mode file and a clean commit; the gamma_diff
# knockout at hilda29l reproduces N8's recorded 2024 value (-0.73 ppm) to its printed digits.
#
# Usage:  Rscript calibration/diag_card4_audit.R      # ~3 min, read-only
# =====================================================================

t_start <- Sys.time()
ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
rv_need_gates()

# ---- named constants (every label below derives from these) ----------------
CA_DRIVER       <- "calibration/diag_card4_audit.R"
# the canonical's OWN stage-1 module check (R/paths.R; fit_iav_module.R --check at the adopted basin). Gated on md5.
CA_MODULE_CHECK <- CCX_MODE_CANONICAL_MODULE_CHECK
CA_TYPED_LAG    <- 2.5             # card 4: "defined to occur 2.5 months after the index"
CA_TYPED_SHARE  <- 0.60            # card 4's title: "about 60% of observed"
CA_TYPED_PEAK   <- c(model = 1L, observed = 5L)   # "peaking a month after ... rather than five months"
CA_TYPED_DIFF   <- 1.5             # "moves CO2 by about one and a half parts per million" after Pinatubo
CA_PINATUBO     <- c(1991L, 1995L) # N8's window for that knockout
CA_N8_MODE      <- "hilda29l"      # the mode N8 (Marcus 2026-09-22) measured the knockout at
CA_N8_2024      <- -0.73           # N8's recorded 2024 value (review.R card 4 comment), the reproduction gate
CA_GR_WIN       <- c(1959L, 2024L) # = diag_growth_residual_years.R GR_WIN
CA_GR_DF        <- 3L              # = its GR_DF (= DG_V_DF)
CA_GR_TOP       <- 3L              # extreme years printed at each end
CA_STEM <- file.path("outputs", "diagnostics",
                     sprintf("card4_audit_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))

commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
mode_file <- ccx_mode_file()
dir.create(dirname(CA_STEM), showWarnings = FALSE, recursive = TRUE)
LOG <- paste0(CA_STEM, ".log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("%s | commit %s | canonical %s (%s) | %s\n", CA_DRIVER, commit, CCX_MODE_CANONICAL,
    basename(dirname(mode_file)), format(Sys.time(), "%Y-%m-%d %H:%M"))
claims <- list()
claim <- function(id, typed, measured, verdict) {
  claims[[length(claims) + 1L]] <<- data.frame(id = id, typed = typed, measured = measured, verdict = verdict)
}

# ---- 1. the land ENSO lag the canonical RUNS, fitted OR pinned ---------------
md  <- readRDS(mode_file)
run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
mc  <- readRDS(CA_MODULE_CHECK)
md5 <- unname(tools::md5sum(mode_file))
if (!identical(mc$provenance$base_md5, md5))
  stop("the module check's base (md5 ", mc$provenance$base_md5, ") is not the canonical's mode file (", md5, ")")
if (abs(mc$base_values[["L"]] - run$lag_enso_land) > 1e-12)
  stop("the module check was not taken at the lag the canonical runs")
how <- if ("lag_enso_land" %in% md$param_names) "FITTED" else if ("lag_enso_land" %in% names(md$pins)) "PINNED" else "DEFAULT"
sd_L <- mc$laplace$sd[["L"]]
say("\n=== 1. LAND ENSO LAG ===\n  runs %.4f months (%s); module Laplace sd %.3f; profile 1-sigma %.2f-%.2f, 2-sigma %.2f-%.2f\n",
    run$lag_enso_land, how, sd_L, mc$lag_1sigma[1], mc$lag_1sigma[2], mc$lag_2sigma[1], mc$lag_2sigma[2])
say("  typed %.1f sits %.2f Laplace sd away; inside the profile 2-sigma range: %s\n",
    CA_TYPED_LAG, abs(run$lag_enso_land - CA_TYPED_LAG) / sd_L,
    CA_TYPED_LAG >= mc$lag_2sigma[1] && CA_TYPED_LAG <= mc$lag_2sigma[2])
claim("land lag", sprintf("%.1f months", CA_TYPED_LAG), sprintf("%.2f +/- %.2f months (%s)", run$lag_enso_land, sd_L, how),
      if (abs(run$lag_enso_land - CA_TYPED_LAG) < sd_L) "holds (within 1 sd)" else "STALE (> 1 sd)")

# ---- 2. the ocean limb's strength against the observed bracket ----------------
s <- rv_enso_slope()
rel <- rv_enso_l2_relation(s$w_enso_l2, s$w_obs)
say("\n=== 2. OCEAN LIMB STRENGTH ===\n  w_enso_l2 %.3f Sv per index unit vs observed [%s] -> '%s'; card's word (RV_ENSO_L2_VS_OBS) '%s'\n",
    s$w_enso_l2, paste(s$w_obs, collapse = ", "), rel, RV_ENSO_L2_VS_OBS)
claim("limb vs range", sprintf("'a little %s'", RV_ENSO_L2_VS_OBS),
      sprintf("%.2f vs [%s] = %s", s$w_enso_l2, paste(s$w_obs, collapse = ", "), rel),
      if (identical(rel, RV_ENSO_L2_VS_OBS)) "holds" else "STALE")

# ---- 3. the ENSO sensitivity and the solubility path's sign -------------------
say("\n=== 3. OCEAN SINK vs NINO3.4 (%d-%d) ===\n  GCB %.4f +/- %.4f GtC/yr per unit; model %.4f (ratio %.3f); solubility only %.4f\n",
    RV_ENSO_WIN[1], RV_ENSO_WIN[2], s$obs$slope, s$obs$se, s$full$slope, s$ratio, s$sol$slope)
claim("ENSO sensitivity", "'close to right'", sprintf("%.2fx GCB (GCB 1 se = %.2fx)", s$ratio, s$obs$se / s$obs$slope),
      if (abs(s$full$slope - s$obs$slope) < s$obs$se) "holds (within GCB's 1 se)" else "check")
claim("solubility sign", "'still has the wrong sign'", sprintf("%.3f vs GCB %+.3f", s$sol$slope, s$obs$slope),
      if (sign(s$sol$slope) != sign(s$obs$slope)) "holds" else "STALE")

# ---- 4. the total wobble: the title's share, and how ENSO-driven it is --------
read_today <- function(stem, driver) {
  f <- file.path("outputs", "diagnostics", sprintf("%s_%s_%s.rds", stem, format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
  if (!file.exists(f)) stop(f, " is missing: run Rscript ", driver, " first (today, at this canonical)")
  readRDS(f)
}
ws <- read_today("app_wobble_shares", "calibration/diag_app_wobble_shares.R")
eg <- read_today("enso_growth_fit",   "calibration/diag_enso_growth_fit.R")
for (p in list(ws$provenance, eg$provenance)) {
  if (!identical(normalizePath(p$mode_file), normalizePath(mode_file))) stop("a read output was made at another mode file")
  if (!isFALSE(p$dirty)) stop("a read output was made on a dirty or unknown tree")
}
share <- ws$scatter[["full"]] / ws$observed
v <- rv_variability()
say("\n=== 4. TOTAL WOBBLE ===\n  app estimator (%d-%d): model %.3f vs observed %.3f ppm/yr = %.0f %%; GATE V estimator: ratio %.3f (%s)\n",
    ws$window[1], ws$window[2], ws$scatter[["full"]], ws$observed, 100 * share, v$verdict$ratio,
    if (isTRUE(v$verdict$pass)) "PASS" else "FAIL")
claim("title share", sprintf("about %.0f%%", 100 * CA_TYPED_SHARE), sprintf("%.0f%% (app estimator)", 100 * share),
      "for Marcus (wording)")

# ---- 5. the timing of the growth peak (diag_enso_growth_fit.R T2(b)) -----------
pk <- eg$T2b_peak
say("\n=== 5. GROWTH PEAK AFTER NINO3.4 (T2(b), monthly) ===\n  model %d months, observed %d months\n",
    pk[["model_full"]], pk[["observed"]])
claim("growth peak timing", sprintf("model %d mo vs observed %d", CA_TYPED_PEAK[["model"]], CA_TYPED_PEAK[["observed"]]),
      sprintf("model %d mo vs observed %d", pk[["model_full"]], pk[["observed"]]),
      if (pk[["model_full"]] == CA_TYPED_PEAK[["model"]] && pk[["observed"]] == CA_TYPED_PEAK[["observed"]]) "holds" else "STALE")

# ---- 6. the diffuse-light path after Pinatubo (gamma_diff knockout) ------------
ko <- function(m) {
  a1 <- rv_arm(m); r1 <- dg_run(a1)$out
  a0 <- a1; a0$p$gamma_diff <- 0; r0 <- dg_run(a0)$out
  d <- ccx_global_co2(r1) - ccx_global_co2(r0); yr <- floor(r1$t)
  an <- tapply(d, yr, mean); k <- as.integer(names(an))
  w <- k >= CA_PINATUBO[1] & k <= CA_PINATUBO[2]
  list(gamma_diff = a1$p$gamma_diff, ann = max(abs(an[w])), ann_year = names(an[w])[which.max(abs(an[w]))],
       mon = max(abs(d[yr >= CA_PINATUBO[1] & yr <= CA_PINATUBO[2]])), y2024 = an[[which(k == 2024)]])
}
k8 <- ko(CA_N8_MODE); kc <- ko(CCX_MODE_CANONICAL)
say("\n=== 6. DIFFUSE LIGHT (gamma_diff -> 0), |CO2 change| over %d-%d ===\n", CA_PINATUBO[1], CA_PINATUBO[2])
for (x in list(c(CA_N8_MODE, k8), c(CCX_MODE_CANONICAL, kc)))
  say("  %-9s gamma_diff %.2f | annual max %.3f ppm (%s), monthly max %.3f | 2024 annual %+.3f\n",
      x[[1]], x$gamma_diff, x$ann, x$ann_year, x$mon, x$y2024)
if (round(k8$y2024, 2) != CA_N8_2024) stop("the knockout does not reproduce N8's recorded 2024 value at ", CA_N8_MODE)
say("  reproduction gate: %s 2024 %+.3f vs N8's recorded %+.2f -> REPRODUCES\n", CA_N8_MODE, k8$y2024, CA_N8_2024)
claim("diffuse light", sprintf("about %.1f ppm", CA_TYPED_DIFF), sprintf("%.2f ppm (monthly max; %s %.2f)", kc$mon, CA_N8_MODE, k8$mon),
      "for Marcus (wording)")

# ---- 7. the N7 paragraph, on the STRUCTURE's run --------------------------------
# diag_growth_residual_years.R's arithmetic unchanged; only the run and forcing are the gates' (dg_run).
rr <- dg_run(rv_arm(CCX_MODE_CANONICAL)); F <- rr$F; o <- rr$out
ann <- function(t, x) {
  a <- stats::aggregate(list(v = x), list(year = floor(t)), mean)
  n <- stats::aggregate(list(n = x), list(year = floor(t)), length)
  a[n$n == 12, ]
}
mg <- ann(o$t, ccx_global_co2(o)); mg <- data.frame(year = mg$year[-1], model = diff(mg$v))
g  <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
ob <- data.frame(year = g$year, obs = g$atm_growth / ccx_const("GtC_PER_PPM"))
en <- ann(F$t, F$enso); names(en)[2] <- "enso"
ao <- ann(F$t, (F$aod_NH + F$aod_SH) / 2); names(ao)[2] <- "aod"
d <- Reduce(function(a, b) merge(a, b, by = "year"), list(mg, ob, en, ao))
d <- d[d$year >= CA_GR_WIN[1] & d$year <= CA_GR_WIN[2], ]
anom <- function(x, yr) stats::residuals(stats::lm(x ~ splines::ns(yr, df = CA_GR_DF)))
d$m_a <- anom(d$model, d$year); d$o_a <- anom(d$obs, d$year); d$res <- d$m_a - d$o_a
ct <- function(x, y) { z <- stats::cor.test(x, y); c(r = unname(z$estimate), p = z$p.value) }
cs <- rbind(enso = ct(d$res, d$enso), aod = ct(d$res, d$aod), year = ct(d$res, d$year))
dec <- vapply(seq(1960, 2020, by = 10), function(y0) mean(d$res[d$year >= y0 & d$year < y0 + 10]), numeric(1))
top <- d[order(-d$res), ][seq_len(CA_GR_TOP), ]; bot <- d[order(d$res), ][seq_len(CA_GR_TOP), ]
say("\n=== 7. N7: WHERE THE GROWTH MISSES (%d-%d, n %d; residual about a %d-dof smooth, ppm/yr) ===\n",
    CA_GR_WIN[1], CA_GR_WIN[2], nrow(d), CA_GR_DF)
for (nm in rownames(cs)) say("  residual vs %-5s r %+.3f  p %.3f\n", nm, cs[nm, "r"], cs[nm, "p"])
say("  decade means %s; one year's scatter (sd) %.3f\n",
    paste(sprintf("%+.3f", dec), collapse = " "), stats::sd(d$res))
say("  largest overshoots %s; largest undershoots %s\n",
    paste(sprintf("%d (%+.2f)", top$year, top$res), collapse = ", "),
    paste(sprintf("%d (%+.2f)", bot$year, bot$res), collapse = ", "))
say("  1991 %+.3f, 1983 %+.3f\n", d$res[d$year == 1991], d$res[d$year == 1983])
claim("no pattern in misses", "none of 3 significant", sprintf("min p %.3f", min(cs[, "p"])),
      if (all(cs[, "p"] >= 0.05)) "holds" else "STALE")
claim("decades inside scatter", "all well inside one year's", sprintf("max |decade| %.3f vs sd %.3f", max(abs(dec)), stats::sd(d$res)),
      if (max(abs(dec)) < stats::sd(d$res)) "holds" else "STALE")
claim("1991 largest overshoot", "1991", sprintf("%d", top$year[1]), if (top$year[1] == 1991L) "holds" else "STALE")
claim("1983 the other way", "1983 undershoots", sprintf("%+.3f", d$res[d$year == 1983]),
      if (d$res[d$year == 1983] < 0) "holds" else "STALE")

# ---- 8. "more El Nino-driven than the real record's": TWO estimators ------------
# The card's caption prints r on the GATE V estimator (rv_variability); the N7 paragraph's own is section 7's.
r2 <- function(a, b) { k <- is.finite(a) & is.finite(b); stats::cor(a[k], b[k]) }
say("\n=== 8. ANOMALY vs NINO3.4, r (model / observed) ===\n  GATE V estimator (the caption's): %.3f / %.3f\n  N7 estimator (section 7): %.3f / %.3f\n",
    v$enso$r_model, v$enso$r_obs, r2(d$m_a, d$enso), r2(d$o_a, d$enso))
gate_says <- v$enso$r_model > v$enso$r_obs; n7_says <- r2(d$m_a, d$enso) > r2(d$o_a, d$enso)
claim("more ENSO-driven than record", "model > record",
      sprintf("gate est %.2f vs %.2f; N7 est %.2f vs %.2f", v$enso$r_model, v$enso$r_obs, r2(d$m_a, d$enso), r2(d$o_a, d$enso)),
      if (gate_says && n7_says) "holds on both" else if (gate_says || n7_says) "ESTIMATOR-DEPENDENT" else "STALE")

# ---- the ledger ------------------------------------------------------------------
tab <- do.call(rbind, claims)
say("\n=== CARD 4 LEDGER at %s ===\n", CCX_MODE_CANONICAL)
op <- options(width = 250); for (ln in utils::capture.output(print(tab, row.names = FALSE, right = FALSE))) say("%s\n", ln); options(op)
prov <- list(driver = CA_DRIVER, commit = commit, dirty = dirty, canonical = CCX_MODE_CANONICAL, mode_file = mode_file,
             mode_md5 = md5, module_check = CA_MODULE_CHECK, rng = "none",
             read = c(wobble = ws$provenance$driver, growth_fit = eg$provenance$script),
             date = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(list(ledger = tab, lag = list(run = run$lag_enso_land, how = how, sd = sd_L, p1 = mc$lag_1sigma, p2 = mc$lag_2sigma),
             slope = s[c("ratio", "w_enso_l2", "w_obs")], share = share, peak = pk,
             diffuse = list(n8 = k8, canonical = kc), n7 = list(cor = cs, decades = dec), provenance = prov),
        paste0(CA_STEM, ".rds"))
say("provenance: %s @%s; canonical %s md5 %s; module check %s; no RNG\n", CA_DRIVER, commit, CCX_MODE_CANONICAL,
    md5, basename(CA_MODULE_CHECK))
say("saved %s.{log,rds} | %.1f min\n", CA_STEM, as.numeric(difftime(Sys.time(), t_start, units = "mins")))
