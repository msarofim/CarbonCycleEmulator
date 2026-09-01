# =====================================================================
# diag_kz_bracket_hml_sensitivity.R -- DOES THE `kz` BRACKET STILL NOT DEPEND
# ON `h_ml`, NOW THAT THE BETTER BASIN SITS AT 144 m?
#
# WHY THIS EXISTS, AND WHY IT RUNS BEFORE THE BRACKET SHIPS. R/calibrate.R's
# whole justification for bounding `kz` ALONE is one measured sentence:
#
#     "the kz -> deep-D14C relation is essentially univariate -- h_ml moves it
#      under 1.5 permil across h_ml 39.7-100 -- so a bound on kz alone is
#      sufficient."
#
# ⛔ THE 08-31e BASIN SITS AT `h_ml` = 143.9 m, OUTSIDE THE RANGE THAT SENTENCE
# WAS MEASURED OVER. The claim may still hold; it has not been checked there,
# and a bracket that is about to become the survey's own coordinate system
# should not rest on an extrapolated one. This is the
# [[ccx_hml_kink]] lesson in a different costume: a verdict measured on one BAND
# is a property of that band until someone re-runs it on the live one.
#
# WHAT IT MEASURES. The k = 3 sigma SOURCED bracket -- the same recipe as
# `diag_kz_bracket_on_the_sourced_target.R` PART 2, against GLODAP's own
# -175.3 +/- 10.3 on the BOTTOM BOX -- re-bisected at several `h_ml`, holding
# everything else at the defaults the incumbent recipe uses. If the bracket
# barely moves, the univariate justification survives onto the live band and the
# shipped numbers are the default-parameter ones. If it moves a lot, the bracket
# is conditional on a parameter the refit is free to move, and that has to be
# said out loud next to the bounds.
#
# ⛔ ADOPTS NOTHING. Asserts the shipped table is untouched at the end.
#
# Usage:  Rscript calibration/diag_kz_bracket_hml_sensitivity.R    # ~4 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants ------------------------------------------------
HS_SIGMAS   <- 3                  # the k the "re-bisect wide" ruling adopts
HS_SEARCH   <- c(1500, 30000)     # = KB_SEARCH, m2/yr
HS_TOL      <- 0.5                # bisection tolerance, m2/yr (= the recipe's)
HS_CLAIM    <- 1.5                # permil; the "under 1.5 permil" claim's own bound
HS_CLAIM_WIN<- c(39.7, 100)       # the h_ml range that claim was measured over
# The h_ml values that matter, each named for WHY it is here.
HS_HML <- c(`shipped default`     = NA_real_,      # filled from the table below
            `incumbent 08-30`     = 35.25,
            `canonical 08-25f`    = 96.47,
            `claim window top`    = 100,
            `NEW BASIN 08-31e`    = 143.92,
            `shipped band top-ish`= 195)

cat(sprintf("\n%s\nIS THE `kz` BRACKET INDEPENDENT OF `h_ml` ON THE LIVE BAND?\n%s\n",
            strrep("=", 78), strrep("=", 78)))

tg <- ccx_deep_d14c_target()
if (is.null(tg))
  stop("GLODAP deep target absent -- data/obs_glodap_deep.rds is gitignored and ",
       "must be rebuilt (data-raw/build_glodap_deep_targets.R).")
z_of <- function(d14) (d14 - tg$target) / tg$sd

OBS_GRAD <- ccx_const("PUMP_GRAD_OBS")
hs_base <- local({ p <- ccx_default_params()
                   p$pump_grad <- OBS_GRAD; p$pump_mode <- "N"; p })
HS_HML[["shipped default"]] <- hs_base$h_ml
HS_SHIPPED <- c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi)

hs_deep <- function(kz, h) {
  q <- hs_base; q$kz <- kz; q$h_ml <- h
  sp <- tryCatch(ccx_spinup(q), error = function(e) NULL)
  if (is.null(sp)) return(NA_real_)
  sp$diagnostics$d14c_bottom_box
}
# Plain bisection on a map GATED as monotone below -- the same recipe, not a
# re-derivation of it.
hs_bisect <- function(target, h) {
  lo <- HS_SEARCH[1]; hi <- HS_SEARCH[2]
  if (hs_deep(lo, h) > target || hs_deep(hi, h) < target) return(NA_real_)
  while (hi - lo > HS_TOL) {
    m <- 0.5 * (lo + hi)
    if (hs_deep(m, h) < target) lo <- m else hi <- m
  }
  0.5 * (lo + hi)
}

# ---- GATE: monotone in kz at EVERY h_ml, or no bisection is well posed ----
cat(sprintf("\nGATE -- kz -> bottom-box D14C must be strictly increasing at every h_ml:\n"))
for (nm in names(HS_HML)) {
  v <- vapply(c(2000, 3942.5, 6528, 12000), hs_deep, numeric(1), h = HS_HML[[nm]])
  if (any(!is.finite(v)) || any(diff(v) <= 0))
    stop("GATE FAILED at h_ml = ", HS_HML[[nm]], ": the map is not monotone (",
         paste(round(v, 1), collapse = ", "), "). Bisection is undefined there.")
  cat(sprintf("  h_ml %6.2f  %s  OK\n", HS_HML[[nm]],
              paste(sprintf("%8.1f", v), collapse = "")))
}

# ---- THE MEASUREMENT ------------------------------------------------
tgt <- c(tg$target - HS_SIGMAS * tg$sd, tg$target + HS_SIGMAS * tg$sd)
cat(sprintf("\nSOURCED TARGET %.2f +/- %d x %.3f permil = [%.2f, %.2f], layer %s\n",
            tg$target, HS_SIGMAS, tg$sd, tgt[1], tgt[2],
            paste(range(tg$layer), collapse = "-")))
cat(sprintf("\n%-22s %8s %11s %11s %10s %10s\n",
            "h_ml (m)", "", "kz lo", "kz hi", "width", "vs default"))
res <- list()
for (nm in names(HS_HML)) {
  h <- HS_HML[[nm]]
  b <- c(hs_bisect(tgt[1], h), hs_bisect(tgt[2], h))
  res[[nm]] <- b
  d <- res[["shipped default"]]
  cat(sprintf("%-22s %8.2f %11.1f %11.1f %10.1f %10s\n", nm, h, b[1], b[2], diff(b),
              if (identical(nm, "shipped default")) "--"
              else sprintf("%+.0f/%+.0f", b[1] - d[1], b[2] - d[2])))
}

# ---- THE CLAIM, TESTED WHERE IT WAS NEVER TESTED --------------------
# The claim is about the D14C the SAME kz delivers, so that is what is measured:
# hold kz at the shipped bracket's ends and sweep h_ml.
cat(sprintf("\n%s\nTHE ORIGINAL CLAIM: 'h_ml moves it under %.1f permil across h_ml %g-%g'\n",
            strrep("-", 78), HS_CLAIM, HS_CLAIM_WIN[1], HS_CLAIM_WIN[2]))
cat(sprintf("%-22s %12s %12s\n", "h_ml (m)", "at kz lo", "at kz hi"))
sw <- t(vapply(names(HS_HML), function(nm)
  c(hs_deep(HS_SHIPPED[1], HS_HML[[nm]]), hs_deep(HS_SHIPPED[2], HS_HML[[nm]])),
  numeric(2)))
for (i in seq_along(HS_HML))
  cat(sprintf("%-22s %12.2f %12.2f\n", names(HS_HML)[i], sw[i, 1], sw[i, 2]))

in_win  <- HS_HML >= HS_CLAIM_WIN[1] & HS_HML <= HS_CLAIM_WIN[2]
span    <- function(k) max(sw[k, ], na.rm = TRUE) - min(sw[k, ], na.rm = TRUE)
sp_win  <- max(apply(sw[in_win, , drop = FALSE], 2, function(v) diff(range(v))))
sp_all  <- max(apply(sw, 2, function(v) diff(range(v))))
cat(sprintf("\n  span WITHIN the claim's own window (h_ml %g-%g):  %.2f permil %s\n",
            HS_CLAIM_WIN[1], HS_CLAIM_WIN[2], sp_win,
            if (sp_win <= HS_CLAIM) "-- the claim REPRODUCES" else "*** the claim does NOT reproduce"))
cat(sprintf("  span across the LIVE band, incl. the new basin's 143.9 m: %.2f permil\n", sp_all))
cat(sprintf("  = %.2f sigma of the sourced target, and the k = %d box is %.1f permil wide\n",
            sp_all / tg$sd, HS_SIGMAS, diff(tgt)))
# THE BOUND MATCHES THE CLAIM: this is not a pass/fail on an invented number, it
# is the ORIGINAL claim's own bound (1.5 permil) applied outside the window it
# was measured in, plus the RATIO to the box the bracket is bisected against --
# which is what says whether the dependence matters for the bracket at all.
cat(sprintf("\n  VERDICT: across the live band the D14C at a FIXED kz moves %.2f permil,\n",
            sp_all))
cat(sprintf("           which is %.1f%% of the %d-sigma box. The bracket ends move\n",
            100 * sp_all / diff(tgt), HS_SIGMAS))
cat(sprintf("           %+.0f / %+.0f m2/yr between the default and the new basin's h_ml.\n",
            res[["NEW BASIN 08-31e"]][1] - res[["shipped default"]][1],
            res[["NEW BASIN 08-31e"]][2] - res[["shipped default"]][2]))

stopifnot(identical(c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi), HS_SHIPPED))
cat("\nMUTATION GUARD PASSED: CCX_PARAM_TABLE$kz untouched. Nothing adopted.\n")
cat(sprintf("%s\n", strrep("=", 78)))
