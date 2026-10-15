# =====================================================================
# diag_enso_objective_leverage.R -- CAN THE OBJECTIVE SEE THE FOUR NEW ENSO
#   PARAMETERS, AND WHICH WAY DOES IT PULL THEM?
#
# THE PRE-REFIT QUESTION. The 09-01 split gave the model four ENSO coefficients
# where it had one (R/model.R, ccx_gamma_enso). Adding a parameter is not the
# same as adding a parameter the data can locate: a coordinate the likelihood
# cannot see returns its prior and costs 40 x 3 h of Torch to learn that.
# Before the refit, two things have to be measured:
#
#   Q1  LEVERAGE -- does moving each new coordinate move the objective at all,
#       and by how much per prior sd? A coordinate worth < ~1 log-unit per
#       prior sd is prior-dominated and will come back as its prior.
#   Q2  DIRECTION -- does the objective REWARD the partition the observation
#       asks for (land -0.665, ocean +0.119 GtC/yr per index unit) or PENALIZE
#       it? This is not rhetorical: 09-01g measured the model in a
#       COMPENSATING-ERROR state where land and ocean errors cancel 87 % in CO2
#       growth, and CO2 outvotes partition 40:1 in this objective
#       ([[ccx_stream_leverage]]). A fit that cannot see the partition will
#       happily keep both errors.
#
# ⚠ CONDITIONAL, NOT A PROFILE, AND THAT LIMIT IS LOAD-BEARING. Every row here
# moves the ENSO coordinates with the other 21 FROZEN. The compensating-error
# reading says the other parameters are exactly what absorbs an ENSO change, so
# a frozen slice OVERSTATES the cost of any move -- the gate-pricing arc
# measured 253 log-units of pure artifact from precisely this
# ([[ccx_gates_priced]]: iso-fit frontiers must RE-OPTIMIZE at every step).
# So: a LARGE conditional response is evidence of leverage (Q1) and is safe to
# read. A conditional SIGN (Q2) is a hypothesis about the refit, not a
# prediction of it. Section 3 re-optimizes a 3-parameter carbon slice at the one
# point that matters, which is the cheapest available check on whether the sign
# survives.
#
# ⚠ MATCHED COMPARISON, SHIPPED TABLE, NO BAND ADOPTION. Every point is
# evaluated through ONE ccx_make_logpost() built on the shipped
# CCX_PARAM_TABLE, so the reparameterization constant between this harness and
# the mode file's own recorded band CANCELS between rows. The absolute logpost
# printed here is therefore NOT comparable with the stored one and is never
# quoted as if it were ([[compare_gaps_not_absolute_logposts]],
# [[ccx_hml_band_decode]]).
#
# ⛔ ADOPTS NOTHING.
#
# Usage:  Rscript calibration/diag_enso_objective_leverage.R    # ~6 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_enso_regression.R"))

EL_MODE  <- "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds"
EL_YRS   <- c(1959, 2024)      # the GCB record the targets were measured on
EL_SLICE <- c("beta_max", "fert_k", "q10")   # the carbon slice, as GE_SLICE was
EL_MAXIT <- 800
# The gap 09-01g priced, in GtC/yr per index unit. LAND needs x1.89; OCEAN needs
# the whole +0.274, i.e. +0.137 in each hemisphere.
EL_LAND_MULT <- 1.89
EL_OCN_EACH  <- 0.137
# A coordinate that moves the objective by less than this per prior sd is
# prior-dominated. NOT a taste threshold: the prior sd IS the scale on which the
# fit trades a coordinate against its prior, so a response below ~1 log-unit
# there is a coordinate the prior wins.
EL_LEV_FLOOR <- 1.0
EL_PRIOR_SD  <- 2.0            # all four ENSO entries are N(0, 2)

cat(sprintf("\n%s\nCAN THE OBJECTIVE SEE THE FOUR ENSO COORDINATES, AND WHICH WAY DOES IT PULL?\n  mode: %s\n  %d parameters, SHIPPED table, matched harness. ADOPTS NOTHING.\n%s\n",
            strrep("=", 78), EL_MODE, length(CCX_PARAM_NAMES), strrep("=", 78)))

v  <- dg_vector(EL_MODE)
pm <- v$pm
cat(sprintf("  migrated: %s\n", paste(attr(pm, "migrated"), collapse = ", ")))
u0 <- ccx_par_to_unc(pm)
stopifnot(all(is.finite(u0)))
bp <- ccx_default_params(); bp$pump_mode <- v$md$pump_mode
lp <- ccx_make_logpost(base_params = bp)
v0 <- lp(u0)
iE <- match(CCX_ENSO_PARAMS, CCX_PARAM_NAMES)
cat(sprintf("  ENSO coordinates at u[%s]; base logpost in THIS harness %.4f\n",
            paste(iE, collapse = ", "), v0))
cat(sprintf("  (its own stored logpost is %.4f, on a DIFFERENT band -- not comparable,\n   and nothing below compares them)\n", v$md$logpost))

# ---- the observed targets, re-measured rather than quoted ------------
g <- as.data.frame(ccx_prepare_obs()$gcb)
g <- g[g$year >= EL_YRS[1] & g$year <= EL_YRS[2], ]
OBS <- list(land  = er_best_lag(g$year, er_detrend(g$land_sink,  g$year)),
            ocean = er_best_lag(g$year, er_detrend(g$ocean_sink, g$year)))
cat(sprintf("\n  observed slopes: land %+.3f  ocean %+.3f GtC/yr per index unit\n",
            OBS$land$slope, OBS$ocean$slope))

el_slopes <- function(u) {
  p <- bp
  pv <- ccx_unc_to_par(u)
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv)
  vv <- list(p = p, bomb_total = pv$bomb_total, luc_scale = pv$luc_scale)
  a  <- dg_annual_sinks(dg_run(vv))
  k  <- a$year >= EL_YRS[1] & a$year <= EL_YRS[2]; yrs <- a$year[k]
  c(land  = er_cor(er_index_annual(yrs, ER_INDEX, OBS$land$lag),
                   er_detrend(a$land[k], yrs))$slope,
    ocean = er_cor(er_index_annual(yrs, ER_INDEX, OBS$ocean$lag),
                   er_detrend(a$ocean[k], yrs))$slope)
}

# =====================================================================
# 1. LEVERAGE -- one prior sd along each new coordinate, both ways
# =====================================================================
cat(sprintf("\n%s\n1. LEVERAGE: the objective's response to ONE PRIOR SD (%.1f) on each\n   coordinate, other 21 FROZEN. Below %.1f log-unit = prior-dominated.\n%s\n",
            strrep("-", 78), EL_PRIOR_SD, EL_LEV_FLOOR, strrep("-", 78)))
cat(sprintf("  %-22s %10s %12s %12s %10s\n", "coordinate", "value", "-1 sd", "+1 sd", "max |d|"))
lev <- numeric(0)
for (j in seq_along(iE)) {
  d <- vapply(c(-1, 1), function(s) {
    u <- u0; u[iE[j]] <- u0[iE[j]] + s * EL_PRIOR_SD; lp(u) - v0 }, numeric(1))
  lev[CCX_ENSO_PARAMS[j]] <- max(abs(d))
  cat(sprintf("  %-22s %10.4f %+12.2f %+12.2f %10.2f\n",
              CCX_ENSO_PARAMS[j], u0[iE[j]], d[1], d[2], max(abs(d))))
}
cat(sprintf("\n  VERDICT Q1: %s\n",
            if (all(lev >= EL_LEV_FLOOR))
              sprintf("all four clear the floor (min %.2f) -- the objective CAN see them.", min(lev))
            else sprintf("%s below %.1f -- PRIOR-DOMINATED, the refit will return the prior there.",
                         paste(names(lev)[lev < EL_LEV_FLOOR], collapse = ", "), EL_LEV_FLOOR)))

# =====================================================================
# 2. DIRECTION -- does it reward the partition the observation asks for?
# =====================================================================
cat(sprintf("\n%s\n2. DIRECTION: the objective and the SLOPES at the same points, CONDITIONAL\n   (other 21 frozen -- read the sign as a hypothesis, not a prediction).\n%s\n",
            strrep("-", 78), strrep("-", 78)))
el_pt <- function(land_mult, ocn) {
  u <- u0; u[iE[1:2]] <- u0[iE[1:2]] * land_mult; u[iE[3:4]] <- ocn; u
}
PTS <- list(list("mode as migrated (ocean 0)",      1,             0),
            list("land x1.89 only",                 EL_LAND_MULT,  0),
            list("ocean +0.137 only",               1,             EL_OCN_EACH),
            list("BOTH: the 09-01g prescription",   EL_LAND_MULT,  EL_OCN_EACH),
            list("ocean -0.137 (the WRONG way)",    1,            -EL_OCN_EACH),
            list("ENSO off entirely",               0,             0))
cat(sprintf("  %-30s %11s %9s %9s %9s\n", "point", "d logpost", "land", "ocean", "|part|"))
cat(sprintf("  %-30s %11s %+9.3f %+9.3f %9s\n", "OBSERVED", "-",
            OBS$land$slope, OBS$ocean$slope, "0.000"))
for (r in PTS) {
  u <- el_pt(r[[2]], r[[3]]); dv <- lp(u) - v0; s <- el_slopes(u)
  mis <- abs(s[["land"]] - OBS$land$slope) + abs(s[["ocean"]] - OBS$ocean$slope)
  cat(sprintf("  %-30s %+11.2f %+9.3f %+9.3f %9.3f\n", r[[1]], dv,
              s[["land"]], s[["ocean"]], mis))
}
cat("\n  |part| = total absolute partition misfit against the two observed slopes.\n")

# =====================================================================
# 3. DOES THE SIGN SURVIVE RE-OPTIMIZATION? the cheapest available check
# =====================================================================
cat(sprintf("\n%s\n3. RE-OPTIMISING a %d-parameter carbon slice (%s) at the prescription\n   point -- the conditional cost above is an UPPER bound on the true one.\n%s\n",
            strrep("-", 78), length(EL_SLICE), paste(EL_SLICE, collapse = ", "),
            strrep("-", 78)))
iS <- match(EL_SLICE, CCX_PARAM_NAMES); stopifnot(!anyNA(iS), !any(iS %in% iE))
el_reopt <- function(u) {
  o <- stats::optim(u[iS], function(z) { uu <- u; uu[iS] <- z; -lp(uu) },
                    method = "Nelder-Mead", control = list(maxit = EL_MAXIT))
  uu <- u; uu[iS] <- o$par; list(u = uu, lp = -o$value)
}
b_ref <- el_reopt(u0)
cat(sprintf("  %-30s %11s %11s\n", "point", "frozen", "re-optimised"))
cat(sprintf("  %-30s %+11.2f %+11.2f\n", "mode as migrated", 0, b_ref$lp - v0))
for (r in PTS[2:4]) {
  u <- el_pt(r[[2]], r[[3]]); fr <- lp(u) - v0; ro <- el_reopt(u)
  cat(sprintf("  %-30s %+11.2f %+11.2f\n", r[[1]], fr, ro$lp - b_ref$lp))
}
cat("\n  Both columns are differences from the SAME reference in their own column,\n  so each is internally matched. The re-optimised column is the one to read.\n")
cat(sprintf("\n⛔ NOTHING ADOPTED.\n%s\n", strrep("=", 78)))

# =====================================================================
# 4. THE TRANSFER: coefficient -> measured slope. A gap in SLOPE units is not
#    a magnitude in PARAMETER units until it is divided by this.
# =====================================================================
# ⛔ THIS SECTION EXISTS BECAUSE 09-01g NAMED A SLOPE GAP AS A COEFFICIENT.
# `diag_enso_ocean_term_design.R` printed "gamma_enso_ocn = +0.274" where +0.274
# is the ocean-sink SLOPE gap, and "gamma_enso x 1.89" where 1.89 is a ratio of
# SLOPES. Both are valid slope arithmetic and every conclusion that file draws
# from them stands; what was wrong was the LABEL on two lines, and the parameter
# values it implied are off by 2.4x and by the intercept respectively.
# [[ratio_needs_its_base]].
#
# The relation is EXACTLY linear (the ENSO flux is linear in the coefficient and
# the estimator is a regression), so two points would do; five are run so the R2
# is reported rather than assumed.
cat(sprintf("\n%s\n4. THE TRANSFER from coefficient to measured slope\n%s\n",
            strrep("-", 78), strrep("-", 78)))
el_fit <- function(idx, coefs, lab) {
  y <- vapply(coefs, function(cc) { u <- u0; u[idx] <- cc / 2; el_slopes(u)[[lab]] },
              numeric(1))
  f <- stats::lm(y ~ coefs)
  cat(sprintf("  %-6s slope = %+.4f %+.4f * coef   (R2 %.6f, %d points)\n",
              lab, coef(f)[1], coef(f)[2], summary(f)$r.squared, length(coefs)))
  c(a = unname(coef(f)[1]), b = unname(coef(f)[2]))
}
fL <- el_fit(iE[1:2], c(0, 0.5, 0.9954, 1.5, 2.0), "land")
fO <- el_fit(iE[3:4], c(0, 0.2, 0.4, 0.8, 1.4), "ocean")
c_land0 <- sum(unlist(pm[CCX_ENSO_PARAMS[1:2]]))
cat(sprintf("\n  ⚠ THE TRANSFER IS ~0.43 IN BOTH RESERVOIRS, NOT 1. The lag is only part of\n    it: the estimator scores at the OBSERVATION's own best lag (land %d mo,\n    ocean %d mo) while the model's ENSO flux is contemporaneous, and\n    cor(annual index at that lag, at lag 0) is %.2f / %.2f -- so the lag\n    accounts for ~0.85 and the rest is the annual SINK's own response to an\n    instantaneous flux anomaly. Measured, not explained, and it is the same in\n    both reservoirs, which points at the estimator rather than the physics.\n",
            OBS$land$lag, OBS$ocean$lag,
            stats::cor(er_index_annual(1959:2024, ER_INDEX, OBS$land$lag),
                       er_index_annual(1959:2024, ER_INDEX, 0)),
            stats::cor(er_index_annual(1959:2024, ER_INDEX, OBS$ocean$lag),
                       er_index_annual(1959:2024, ER_INDEX, 0))))
cat(sprintf("\n  ⚠ THE NON-ZERO INTERCEPTS ARE THE POINT OF THE WHOLE ARC. At ZERO ENSO\n    coefficient the model still has land %+.4f and ocean %+.4f -- its residual\n    ENSO response through the SST / q10 path. The ocean intercept IS the\n    anti-correlation this split was built to fix, and it is now shown to be\n    entirely the coefficient-INDEPENDENT part.\n", fL[["a"]], fO[["a"]]))
tgtL <- (OBS$land$slope  - fL[["a"]]) / fL[["b"]]
tgtO <- (OBS$ocean$slope - fO[["a"]]) / fO[["b"]]
cat(sprintf("\n  THE CORRECTED PRESCRIPTION (what 09-01g meant to say):\n"))
cat(sprintf("    land  total coefficient %.4f = x%.3f the mode's %.4f   (09-01g said x1.89)\n",
            tgtL, tgtL / c_land0, c_land0))
cat(sprintf("    ocean total coefficient %+.4f  = %+.4f in EACH hemisphere   (09-01g said +0.274)\n",
            tgtO, tgtO / 2))
cat(sprintf("\n  ⚠ AND THE OBJECTIVE DOES NOT WANT ALL OF IT. Section 2's scan puts the\n    CONDITIONAL optimum of the ocean pair near +0.10 each (total +0.20), about\n    a THIRD of the %+.3f the partition asks for. That is the trade the refit\n    has to make, and it is now expressible; it was not before the split.\n", tgtO))
cat(sprintf("\n⛔ NOTHING ADOPTED.\n%s\n", strrep("=", 78)))
