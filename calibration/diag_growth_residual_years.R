# =====================================================================
# diag_growth_residual_years.R -- N7 (Marcus 2026-09-22): "can we identify any
# commonalities between the years the model overshoots the growth rate, and/or
# between the years it undershoots?"
#
# WHAT IT IS. The model reproduces about 60 % of the observed interannual CO2
# growth variability (GATE V, review card 4). That is a statement about the
# VARIANCE. This asks the sharper question: are the misses STRUCTURED -- do they
# fall on El Nino years, on volcanic years, on a particular decade -- or are
# they noise?
#
# ⚠ THE RESIDUAL IS TAKEN ABOUT A SMOOTH, NOT RAW. Model minus observed growth
# contains a slow component (the model's sink is a little strong; the land
# crosses to a net sink ~18 yr early). A raw difference would be dominated by
# that trend and would answer a question about the SINK, not about interannual
# structure. Both are reported, separately, because they are different findings.
#
# ⚠ AND THE DRIVERS ARE PRESCRIBED, WHICH IS WHAT MAKES THIS A FAIR TEST. ENSO
# and volcanic aerosol are INPUTS to this model, not things it predicts. So a
# correlation between the residual and the ENSO index is not "the model missed
# an El Nino it could not have known about" -- it is the model being given the
# index and still getting the response wrong, which is a mechanism statement.
#
# ⛔ WHAT THIS CANNOT DO. n = 66 annual values. A correlation of 0.24 is the
# 5 % point, so anything under ~0.3 is not distinguishable from noise here, and
# the composites below rest on a handful of years each. Every number carries its
# p-value and its n, and the verdict is stated in those terms.
#
# Usage:  Rscript calibration/diag_growth_residual_years.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

GR_WIN     <- c(1959, 2024)   # where GCB's annual budget exists
GR_DF      <- 3               # dof of the smooth the anomaly is taken about (= DG_V_DF)
GR_TOP     <- 8               # how many extreme years to name at each end
GR_ENSO_Q  <- 0.25            # quantile defining "El Nino" / "La Nina" composites
GR_AOD_YRS <- 2               # years after a large eruption counted as volcanic

md <- ccx_load_mode(CCX_MODE_CANONICAL)
sp <- ccx_spinup_from_label(ccx_mode_spinup(md$md))(md$p)
# the forcing's ENSO index and AOD mode are the STRUCTURE's (2026-10-08), as in dg_run() and the
# objective. The builder's defaults ("demean", "legacy") were refused at hilda29e ("detrend",
# "anomaly") by ccx_enso_index_check(). A structure that names neither resolves to those defaults, so
# its run is unchanged. At hilda29e this run is dg_run()'s bit for bit through 2024 (CHANGELOG 10-08 (k)).
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                        bomb_total_kmol = md$bomb_total, luc_scale = md$luc_scale,
                        enso_index = ccx_enso_index_of(md$p), aod_mode = ccx_aod_mode_of(md$p))
o  <- ccx_run_fast(sp, F)$out
o$co2_global <- (o$co2_NH + o$co2_SH) / 2

ann <- function(t, v) {
  a <- stats::aggregate(list(v = v), list(year = floor(t)), mean)
  n <- stats::aggregate(list(n = v), list(year = floor(t)), length)
  a[n$n == 12, ]
}
mg <- ann(o$t, o$co2_global); mg <- data.frame(year = mg$year[-1], model = diff(mg$v))
g  <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
ob <- data.frame(year = g$year, obs = g$atm_growth / ccx_const("GtC_PER_PPM"))
en <- ann(F$t, F$enso); names(en)[2] <- "enso"
ao <- ann(F$t, (F$aod_NH + F$aod_SH) / 2); names(ao)[2] <- "aod"

d <- Reduce(function(a, b) merge(a, b, by = "year"), list(mg, ob, en, ao))
d <- d[d$year >= GR_WIN[1] & d$year <= GR_WIN[2], ]
d$raw <- d$model - d$obs
# the interannual part of each series, about its own smooth
anom <- function(v, yr) stats::residuals(stats::lm(v ~ splines::ns(yr, df = GR_DF)))
d$m_a <- anom(d$model, d$year); d$o_a <- anom(d$obs, d$year)
d$res <- d$m_a - d$o_a          # + = the model grew FASTER than observed that year

cat(sprintf("=== N7: where the model's CO2 growth misses, %d-%d (n = %d) ===\n",
            GR_WIN[1], GR_WIN[2], nrow(d)))
cat(sprintf("  canonical %s (%s) | ENSO index %s | AOD mode %s | commit %s | no RNG\n",
            CCX_MODE_CANONICAL, basename(dirname(ccx_mode_file())), attr(F, "enso_index"),
            attr(F, "aod_mode"), ccx_git_stamp()))
cat(sprintf("  raw model-minus-observed growth: mean %+.3f ppm/yr, sd %.3f\n",
            mean(d$raw), stats::sd(d$raw)))
cat(sprintf("  interannual residual (about a %d-dof smooth): mean %+.3f, sd %.3f\n",
            GR_DF, mean(d$res), stats::sd(d$res)))
cat(sprintf("  model interannual sd %.3f vs observed %.3f (%.0f %% of observed)\n",
            stats::sd(d$m_a), stats::sd(d$o_a), 100 * stats::sd(d$m_a) / stats::sd(d$o_a)))

cat(sprintf("\n=== the %d biggest OVERSHOOTS (model grew faster than observed) ===\n", GR_TOP))
top <- d[order(-d$res), ][seq_len(GR_TOP), ]
cat(sprintf("  %6s %10s %10s %10s\n", "year", "residual", "ENSO", "AOD"))
for (i in seq_len(nrow(top)))
  cat(sprintf("  %6d %+10.3f %10.2f %10.4f\n", top$year[i], top$res[i], top$enso[i], top$aod[i]))
cat(sprintf("\n=== the %d biggest UNDERSHOOTS ===\n", GR_TOP))
bot <- d[order(d$res), ][seq_len(GR_TOP), ]
cat(sprintf("  %6s %10s %10s %10s\n", "year", "residual", "ENSO", "AOD"))
for (i in seq_len(nrow(bot)))
  cat(sprintf("  %6d %+10.3f %10.2f %10.4f\n", bot$year[i], bot$res[i], bot$enso[i], bot$aod[i]))

cat("\n=== is the residual STRUCTURED? correlations, with p and n ===\n")
rep_cor <- function(lab, x, y) {
  ct <- stats::cor.test(x, y)
  cat(sprintf("  %-34s r %+.3f  p %.4f  n %d  %s\n", lab, unname(ct$estimate), ct$p.value,
              length(x), if (ct$p.value < 0.05) "<- significant at 5 %" else ""))
  invisible(ct)
}
rep_cor("residual vs ENSO index",            d$res, d$enso)
rep_cor("residual vs volcanic AOD",          d$res, d$aod)
rep_cor("residual vs year",                  d$res, d$year)
rep_cor("|residual| vs |ENSO|",              abs(d$res), abs(d$enso))
cat("  -- for reference, the two series the residual is built from:\n")
rep_cor("  observed anomaly vs ENSO",        d$o_a, d$enso)
rep_cor("  model anomaly vs ENSO",           d$m_a, d$enso)

cat("\n=== composites ===\n")
q <- stats::quantile(d$enso, c(GR_ENSO_Q, 1 - GR_ENSO_Q))
nino <- d$enso >= q[2]; nina <- d$enso <= q[1]
big <- d$aod > stats::quantile(d$aod[d$aod > 0], 0.75)
comp <- function(lab, k) if (sum(k) >= 3)
  cat(sprintf("  %-28s n %2d   mean residual %+.3f  (all years %+.3f)\n",
              lab, sum(k), mean(d$res[k]), mean(d$res)))
comp(sprintf("El Nino (top %.0f %%)", 100 * GR_ENSO_Q), nino)
comp(sprintf("La Nina (bottom %.0f %%)", 100 * GR_ENSO_Q), nina)
comp("high volcanic AOD", big)
for (dec in seq(1960, 2020, by = 10)) comp(sprintf("the %ds", dec),
                                           d$year >= dec & d$year < dec + 10)

cat("\n=== VERDICT ===\n")
ct <- stats::cor.test(d$res, d$enso)
cat(sprintf("  n = %d, so |r| below ~%.2f is not distinguishable from noise at 5 %%.\n",
            nrow(d), stats::qt(0.975, nrow(d) - 2) / sqrt(nrow(d) - 2 + stats::qt(0.975, nrow(d) - 2)^2)))
cat(sprintf("  The ENSO association of the residual is r %+.3f (p %.3f).\n",
            unname(ct$estimate), ct$p.value))
cat("  Read the composites above for the sign and the decade structure; a single\n")
cat("  correlation is not the finding on 66 points.\n")
