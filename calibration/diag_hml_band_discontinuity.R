# =====================================================================
# diag_hml_band_discontinuity.R -- WHAT IS THE h_ml CLIFF MADE OF, AND WHICH
# OF THE FOUR OPTIONS ACTUALLY REMOVES IT?
# (handoff 2026-08-16f sec.5, the blocker; sec.9 item 1)
#
# THE QUESTION 16f DID NOT ASK. 16f measured the cliff -- -10.07 log-units to
# enter LIK_OCEAN_GRAD_HML_OK at 85, +9.6 to leave at 120 -- and offered four
# options. It did not decompose it. That matters because the cliff is two
# SEPARABLE defects wearing one number, and each option fixes a different one:
#
#   (A) A BARRIER. The objective is DISCONTINUOUS in h_ml. This is what sec.5.4
#       says is worse for the MCMC than for the mode-find: an adaptive-Metropolis
#       proposal sized in one basin cannot cross into the other.
#   (B) AN INCENTIVE. The objective is PAID to discard the rows. A skipped
#       Gaussian row contributes 0 where a live one contributes a NEGATIVE
#       number, so leaving the band is a free gain of exactly |sum of the rows|.
#
# A TAPER (16f sec.5.5 option 3) FIXES (A) AND NOT (B), and that is an identity
# rather than a measurement: for any weight w(h) in [0,1] multiplying a NEGATIVE
# row sum, d/dw < 0, so the objective is still monotonically rewarded for w -> 0.
# It converts a cliff into a ramp and leaves the summit in the same place. Part 3
# demonstrates that numerically rather than asserting it, because an identity
# about the shape of the penalty is still worth seeing against the model's own
# other streams, which move with h_ml too and could in principle outweigh it.
#
# WHAT DOES FIX (B), and it is not on 16f's list of four. The band exists because
# a FIXED-DEPTH target is like-for-like with the model's boxes only near 100 m
# (R/likelihood.R's "THE h_ml GATE" paragraph: 0.09 sigma of mismatch at 100,
# 1.61 sigma at 184). That is a REPRESENTATION ERROR, and the honest way to carry
# a representation error is IN QUADRATURE, not as a switch:
#
#     sigma_eff(h)^2 = sigma_obs^2 + sigma_rep(h)^2
#
# with dnorm's NORMALISATION TERM RETAINED. Inflating sigma then costs
# -log(sigma_eff), so discarding a row is CHARGED FOR rather than free, and the
# gain is bounded (the best any inflation can do is sigma_eff = |miss|, at
# -log(|miss| sqrt(2 pi)) - 1/2). Crucially the inflation is NOT A TUNING KNOB:
# sigma_rep(h) is MEASURABLE as the gap between the shipped fixed-depth target
# and the like-for-like model-box-anchored target at that h_ml -- exactly the
# column diag_gradient_target_and_neff.R part 2b already prints. Part 4 measures
# the curve, on both fields, data-side only.
#
# THIS FILE PROPOSES NOTHING AND CHANGES NO OBJECTIVE. R/likelihood.R is not
# touched. The sigma-inflation arithmetic in part 4 is evaluated OFFLINE, on
# measured misses, so that the choice between the options is Marcus's on numbers
# rather than mine on a framing. Per ~/.claude/CLAUDE.md, a likelihood redesign
# is a methodological choice and is flagged, not resolved.
#
# FIVE PREDICTIONS, WRITTEN BEFORE ANY ARM WAS RUN (scored in part 5):
#
#   P1. Crossing 85 changes ONLY the three ocean_grad_* streams discontinuously.
#       Every other stream is continuous in h_ml and so moves by O(1e-2) or less
#       across a 0.02 m step.
#   P2. The cliff IS the rows appearing: Delta logpost across the crossing =
#       sum(the three rows' logL just inside), to within P1's continuous drift.
#       I expect to reproduce 16f's -10.07 to better than 0.1.
#   P3. Under ANY multiplicative taper the argmax over h_ml stays OUTSIDE the
#       band, and the gain from leaving = (1 - w) |row sum|.
#   P4. Under sigma-inflation with the normalisation retained, the gain from
#       leaving is BOUNDED and smaller than the taper's; I expect it to be a
#       LARGE fraction of the taper's gain rather than a small one, because the
#       rows' misses are several sigma and z^2/2 dominates log(z).
#   P5. sigma_rep(h) is NOT small compared with sigma_obs over the useful h_ml
#       range -- if it were, the band would never have been needed.
#
# RUNTIME ~4 min (a ~40-point h_ml scan at ~0.08 s/eval, plus two gate arms).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label, window and threshold below derives ----
HB_YEARS      <- c(1750, 2024)
HB_BOMB_REF   <- 102          # must match ccx_make_logpost()'s own BOMB_REF
HB_BAND       <- LIK_OCEAN_GRAD_HML_OK        # [85, 120]
HB_EPS        <- 0.01         # m; the half-step used to straddle each edge
HB_H_IN       <- 100          # m; the reference in-band depth (the pump's own)
# The scan. Deliberately DENSE at the two edges (where the cliff is) and coarse
# elsewhere, and it spans h_ml's full prior support [30, 200] so that "the argmax
# is outside the band" is a statement about the whole space, not a local one.
#
# THE LOWER END IS DENSE ON PURPOSE. The first run put the argmax at the scan's
# lowest FINITE point (40 m) -- h_ml = 30 is the prior's own bound, where
# qlogis(0) = -Inf and the eval cannot run -- so whether the objective merely
# prefers a shallow mixed layer or is running hard into its bound is a different
# statement, and 32/35 are what separate them.
HB_H_SCAN     <- sort(unique(c(
  32, 35, seq(40, 80, by = 10), 84, HB_BAND[1] - HB_EPS, HB_BAND[1] + HB_EPS,
  seq(86, 118, by = 4), HB_BAND[2] - HB_EPS, HB_BAND[2] + HB_EPS,
  seq(122, 200, by = 10), 184)))   # 184 = the quarantined mode's h_ml
HB_GRAD_STREAMS <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk")
# Tapers priced in part 3. NOT proposals -- three shapes spanning what "taper the
# terms at the band edges" could reasonably mean, to show the conclusion does not
# depend on which is chosen.
HB_TAPER_W    <- c(30, 15, 60)     # m; half-width of the cosine ramp outside the band
# P1's bar is a RATIO, not an absolute. The first version of this file used an
# absolute 0.05 log-units for "nothing else moves discontinuously" and it FAILED
# at 0.0696 -- on the objective's ordinary ~8 log-units/m slope in h_ml, which
# over a 0.02 m straddle is ~0.16 of legitimate continuous drift. The bar was
# measuring the slope, not a discontinuity. Restated as the claim actually made:
# the jump must dwarf the drift the same step produces.
HB_JUMP_RATIO_MIN <- 20       # x; the discontinuity over the same step's drift
HB_P2_TOL     <- 1e-6         # log-units; P2 is now an EXACT identity, not a bar
HB_REF_CLIFF  <- -10.07       # 16f sec.5.1's measured entry cost, for reproduction
HB_FROZEN_H   <- 75           # the h_ml part 2b's "frozen" target was built on
HB_REF_MISMATCH_184 <- 1.61   # sigma; the HISTORICAL figure this part receipt-
                              # checks. It was R/likelihood.R's own until 2026-08-16g,
                              # when part 5's finding was written back there (the gate's
                              # own quantity is 0.80). Keep 1.61 here -- part 5 divides
                              # by it to recover the sigma it implies, which is the
                              # step that identifies it as part 2b's blk30.
HB_INFLATE_MAX_FRAC <- 0.5    # P4's bar: inflation recovering MORE than this
                              # fraction of the skip's gain would make it a weak
                              # remedy. Predicted > 0.5; measured 0.21.
HB_H_FIT      <- 184          # the quarantined mode's h_ml (16f sec.5.1)
# Part 4's observation side. Every one of these is copied from
# diag_gradient_target_and_neff.R rather than re-chosen, and GATE D asserts the
# copy still reproduces the shipped target.
HB_GLODAP_FILE   <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
HB_FLAG_OK       <- 2                    # GLODAP: 2 = acceptable
HB_DLAT          <- 5; HB_DLON <- 10; HB_DZ <- 250     # the build script's cells
HB_SHIPPED_SURF  <- c(0, 100)            # build_glodap_deep_targets.R
HB_SHIPPED_DEEP  <- c(2627.2, 1e5)       # ditto -- note the 1e5
HB_GATE_D_TOL    <- 1e-3                 # absolute, in each field's own units
HB_OUTDIR     <- ccx_path("calibration", "output", "hml_band_discontinuity")

dir.create(HB_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

stopifnot(length(HB_BAND) == 2, HB_H_IN > HB_BAND[1], HB_H_IN < HB_BAND[2])
tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg), !is.null(tg$dic), !is.null(tg$d13c), !is.null(tg$alk))

# =====================================================================
# THE REPLICA OBJECTIVE, AND THE GATE THAT MAKES IT SAFE TO USE
# =====================================================================
# ccx_make_logpost() returns a SCALAR. The decomposition needs by_stream, so this
# file rebuilds the same evaluation and asks ccx_loglik() for the parts. A replica
# that has drifted from the objective would answer a different question silently
# -- so GATE B below asserts the replica's total equals the REAL objective's, at
# both an in-band and an out-of-band point, to 1e-9. That is the whole reason the
# replica is allowed to exist.
obs        <- ccx_prepare_obs()
base_forc  <- ccx_build_forcing("historical", HB_YEARS, prod_c14 = 0,
                                bomb_total_kmol = HB_BOMB_REF)
ELUC_BASE  <- ccx_forcing_eluc_annual(base_forc)
LUC_COLS   <- c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")

#' The objective at an unconstrained vector, decomposed.
#' @return list(prior, parts (named per-stream logL), ll, total, grad, h_ml,
#'   rows_live) or NULL if the run failed.
hb_eval <- function(u) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  lp <- 0
  for (n in CCX_PARAM_NAMES) {
    s <- CCX_PARAM_TABLE[[n]]
    lp <- lp + s$prior(pv[[n]]) + .log_jac(u[[n]], s)
  }
  if (!is.finite(lp)) return(NULL)
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(NULL)
  F <- base_forc
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forc$c14_bomb * (pv$bomb_total / HB_BOMB_REF)
  for (cc in LUC_COLS) F[[cc]] <- base_forc[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  eluc <- ELUC_BASE; eluc$eluc <- eluc$eluc * pv$luc_scale
  r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  err <- list(sigma_d13c = pv$sigma_d13c, sigma_d14c = pv$sigma_d14c,
              grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c)
  og <- ccx_ocean_grad_scored(r$out, sp)
  parts <- ccx_loglik(r$out, obs, err, luc = eluc,
                      deep = sp$diagnostics$d14c_bottom_box,
                      ocean_grad = og, by_stream = TRUE)
  list(prior = lp, parts = parts, ll = sum(parts), total = lp + sum(parts),
       grad = og, h_ml = sp$grid$h_ml, rows_live = !is.null(og))
}

#' init in unconstrained space, with h_ml overridden to `h`.
#'
#' Built from ccx_init_unc() -- the PARAMETER TABLE's inits, which is what the
#' mode-finder starts from -- and NOT from ccx_par_to_unc(ccx_default_params()).
#' The latter is what this file tried first and it errors: `bomb_total`,
#' `luc_scale`, the two sigmas and the two gradient offsets are fitted parameters
#' with no field in ccx_default_params(), so .to_unc() gets a NULL.
hb_u_at <- function(h) {
  u <- ccx_init_unc()
  u[["h_ml"]] <- .to_unc(h, CCX_PARAM_TABLE$h_ml)
  names(u) <- CCX_PARAM_NAMES
  u
}

sep("GATE A. THE BAND, THE TARGETS, AND WHERE init SITS RELATIVE TO IT")
h_init <- ccx_default_params()$h_ml
cat(sprintf("LIK_OCEAN_GRAD_HML_OK = [%g, %g] m\n", HB_BAND[1], HB_BAND[2]))
cat(sprintf("h_ml init             = %g m  -> rows %s\n", h_init,
            if (h_init >= HB_BAND[1] && h_init <= HB_BAND[2]) "LIVE" else "*** ABSENT ***"))
cat(sprintf("quarantined mode h_ml = %g m  -> rows %s\n", HB_H_FIT,
            if (HB_H_FIT >= HB_BAND[1] && HB_H_FIT <= HB_BAND[2]) "LIVE" else "*** ABSENT ***"))
cat(sprintf("targets: DIC %+.3f +/- %.3f   d13C %+.4f +/- %.4f   ALK %+.3f +/- %.3f\n",
            tg$dic$target, tg$dic$sd, tg$d13c$target, tg$d13c$sd,
            tg$alk$target, tg$alk$sd))

sep("GATE B. THE REPLICA MUST BE THE OBJECTIVE, NOT A LOOKALIKE")
lp_real <- ccx_make_logpost(years = HB_YEARS, obs = obs)
gate_b <- lapply(c(HB_H_IN, h_init), function(h) {
  u <- hb_u_at(h)
  a <- hb_eval(u); b <- lp_real(u)
  cat(sprintf("h_ml %6.2f  rows %-6s  replica %14.4f   objective %14.4f   |gap| %.3e\n",
              h, if (a$rows_live) "LIVE" else "ABSENT", a$total, b, abs(a$total - b)))
  c(gap = abs(a$total - b))
})
stopifnot(all(vapply(gate_b, `[[`, numeric(1), "gap") < 1e-9))
cat("Replica == objective at an IN-BAND and an OUT-OF-BAND point, to 1e-9.\n")
cat("Everything below is therefore a decomposition of the real objective.\n")

# =====================================================================
# PART 1 + 2. WHAT IS THE CLIFF MADE OF?
# =====================================================================
sep("PART 1. STRADDLE EACH EDGE -- WHICH STREAMS MOVE DISCONTINUOUSLY?")
edges <- list(lo = HB_BAND[1], hi = HB_BAND[2])
straddle <- lapply(names(edges), function(nm) {
  h <- edges[[nm]]
  out <- lapply(c(h - HB_EPS, h + HB_EPS), function(hh) hb_eval(hb_u_at(hh)))
  names(out) <- c("below", "above")
  stopifnot(!is.null(out$below), !is.null(out$above))
  keys <- union(names(out$below$parts), names(out$above$parts))
  # ccx_loglik(by_stream = TRUE) returns a NAMED NUMERIC VECTOR, not a list, so
  # `[[missing_name]]` ERRORS rather than returning NULL. An absent stream must
  # read as NA here -- that absence is the whole subject of this file.
  g <- function(o, k) if (k %in% names(o$parts)) o$parts[[k]] else NA_real_
  d <- data.frame(stream = keys,
                  below  = vapply(keys, function(k) g(out$below, k), numeric(1)),
                  above  = vapply(keys, function(k) g(out$above, k), numeric(1)),
                  row.names = NULL)
  d$delta <- d$above - d$below
  # An ABSENT stream is NA on one side. Its "delta" is the whole row.
  d$appears <- is.na(d$below) & !is.na(d$above)
  d$vanishes <- !is.na(d$below) & is.na(d$above)
  cat(sprintf("\n--- edge %s: h_ml %.2f -> %.2f (rows %s -> %s) ---\n", nm,
              h - HB_EPS, h + HB_EPS,
              if (out$below$rows_live) "LIVE" else "ABSENT",
              if (out$above$rows_live) "LIVE" else "ABSENT"))
  cat(sprintf("%-22s %14s %14s %12s  %s\n", "stream", "below", "above", "delta", "note"))
  ord <- order(-abs(ifelse(is.na(d$delta), 1e9, d$delta)))
  for (i in ord) {
    note <- if (d$appears[i]) "APPEARS" else if (d$vanishes[i]) "VANISHES" else ""
    cat(sprintf("%-22s %14s %14s %12s  %s\n", d$stream[i],
                if (is.na(d$below[i])) "ABSENT" else sprintf("%.4f", d$below[i]),
                if (is.na(d$above[i])) "ABSENT" else sprintf("%.4f", d$above[i]),
                if (is.na(d$delta[i])) "--" else sprintf("%+.4f", d$delta[i]), note))
  }
  cont <- d[!d$appears & !d$vanishes, ]
  cat(sprintf("\nprior  %14.4f %14.4f %+12.4f\n",
              out$below$prior, out$above$prior, out$above$prior - out$below$prior))
  cat(sprintf("total  %14.4f %14.4f %+12.4f\n",
              out$below$total, out$above$total, out$above$total - out$below$total))
  cat(sprintf("CONTINUOUS streams: %d, sum of deltas = %+.4f, max |delta| = %.4f\n",
              nrow(cont), sum(cont$delta), max(abs(cont$delta))))
  cat(sprintf("DISCONTINUOUS streams: %s\n",
              paste(d$stream[d$appears | d$vanishes], collapse = ", ")))
  # THE DRIFT IS NOT NOISE TO BE TOLERATED, IT IS A SLOPE TO BE DERIVED. The
  # objective's own gradient in h_ml is ~8 log-units per metre near the edges, so
  # a 0.02 m straddle MUST move the continuous part by ~0.16 -- which is what
  # P1's first bar (0.05) collided with. The physical claim is not "nothing else
  # moves"; it is "the jump is not a slope", so the quantity to measure is the
  # RATIO of the discontinuity to the drift the same step produces.
  drift <- sum(cont$delta) + (out$above$prior - out$below$prior)
  list(edge = nm, h = h, d = d, below = out$below, above = out$above,
       d_total = out$above$total - out$below$total,
       max_cont = max(abs(cont$delta)), drift = drift,
       jumpers = d$stream[d$appears | d$vanishes],
       row_sum = sum(d$above[d$appears], -d$below[d$vanishes]))
})
names(straddle) <- names(edges)

sep("PART 2. IS THE CLIFF EXACTLY 'THE ROWS APPEARED'?")
cat("If it is, then h_ml = 85 does not FIT WORSE than 84.99 -- it is SCORED ON\n")
cat("MORE DATA. Those are different defects and only one of them is about h_ml.\n\n")
cat("The identity being tested is EXACT, not approximate:\n")
cat("  Delta total  =  (the rows that appeared)  +  (the continuous drift)\n")
cat("where the drift is the sum of the 16 continuous streams' deltas plus the\n")
cat("prior's. There is nothing else in the objective, so the residual on that\n")
cat("identity must be ZERO to machine precision -- and a nonzero one would mean a\n")
cat("stream is moving that this file has not accounted for.\n\n")
cat(sprintf("%-6s %14s %14s %12s %14s %8s\n", "edge", "Delta total",
            "rows", "drift", "residual", "P2"))
for (s in straddle) {
  resid <- s$d_total - s$row_sum - s$drift
  cat(sprintf("%-6s %+14.4f %+14.4f %+12.4f %14.2e %8s\n", s$edge, s$d_total,
              s$row_sum, s$drift, resid,
              if (abs(resid) <= HB_P2_TOL) "PASS" else "FAIL"))
}
cat(sprintf("\nRATIO of the discontinuity to the drift the SAME step produces:\n"))
for (s in straddle)
  cat(sprintf("  edge %-3s  rows %+8.4f  /  drift %+8.4f  =  %6.1fx\n",
              s$edge, s$row_sum, s$drift, abs(s$row_sum / s$drift)))
cat(sprintf("\n16f sec.5.1 measured the ENTRY cost as %.2f log-units; here %+.2f.\n",
            HB_REF_CLIFF, straddle$lo$d_total))
in_band <- straddle$lo$above
rows_now <- in_band$parts[intersect(HB_GRAD_STREAMS, names(in_band$parts))]
cat(sprintf("\nThe three rows just INSIDE the band (h_ml = %.2f):\n", HB_BAND[1] + HB_EPS))
z_of <- function(fld, v) (v - tg[[fld]]$target) / tg[[fld]]$sd
zs <- c(dic = z_of("dic", in_band$grad$dic), d13c = z_of("d13c", in_band$grad$d13c),
        alk = z_of("alk", in_band$grad$alk))
for (k in names(rows_now))
  cat(sprintf("   %-22s %+9.4f log-units\n", k, rows_now[[k]]))
cat(sprintf("   %-22s %+9.4f\n", "SUM", sum(unlist(rows_now))))
cat(sprintf("\nmodel gradients / z:  DIC %+8.2f (z %+6.2f)  d13C %+7.4f (z %+6.2f)  ALK %+8.2f (z %+6.2f)\n",
            in_band$grad$dic, zs["dic"], in_band$grad$d13c, zs["d13c"],
            in_band$grad$alk, zs["alk"]))

# =====================================================================
# PART 3. THE SCAN, AND WHAT A TAPER DOES AND DOES NOT FIX
# =====================================================================
sep("PART 3. THE h_ml SCAN -- AS SHIPPED, AND UNDER THREE TAPERS")
cat(sprintf("Scanning h_ml over [%g, %g] at %d points, every other parameter at init.\n",
            min(HB_H_SCAN), max(HB_H_SCAN), length(HB_H_SCAN)))
t0 <- Sys.time()
scan <- lapply(HB_H_SCAN, function(h) {
  e <- hb_eval(hb_u_at(h))
  if (is.null(e)) return(NULL)
  rs <- sum(unlist(e$parts[intersect(HB_GRAD_STREAMS, names(e$parts))]))
  list(h = h, total = e$total, live = e$rows_live,
       row_sum = if (e$rows_live) rs else NA_real_,
       # the objective with the rows REMOVED -- the common baseline every
       # variant below is built on, and it is CONTINUOUS in h_ml by construction
       other = e$total - (if (e$rows_live) rs else 0),
       grad = e$grad)
})
scan <- Filter(Negate(is.null), scan)
cat(sprintf("%d/%d points ran, %.1f s (%.3f s/eval)\n", length(scan), length(HB_H_SCAN),
            as.numeric(difftime(Sys.time(), t0, units = "secs")),
            as.numeric(difftime(Sys.time(), t0, units = "secs")) / length(scan)))

hs    <- vapply(scan, `[[`, numeric(1), "h")
tot   <- vapply(scan, `[[`, numeric(1), "total")
oth   <- vapply(scan, `[[`, numeric(1), "other")
liv   <- vapply(scan, `[[`, logical(1), "live")
rsum  <- vapply(scan, `[[`, numeric(1), "row_sum")

# The row sum is only DEFINED in-band as shipped. To price a taper we need it
# everywhere, so it is re-derived OUT of band from the same
# ccx_model_ocean_gradient() the likelihood uses, with the gate bypassed. This is
# the counterfactual "what WOULD the rows have said", not a proposal.
sep("PART 3a. WHAT THE ROWS WOULD HAVE SAID OUTSIDE THE BAND")
cat("The gate returns NULL out of band, so the counterfactual row values are\n")
cat("recomputed here with the SAME functions and the gate bypassed. Nothing in\n")
cat("R/likelihood.R changes; this is the input a taper or an inflation needs.\n")
hb_rows_ungated <- function(h) {
  # `bomb_total` and `luc_scale` are FITTED parameters that are NOT fields of
  # ccx_default_params() -- they live only in CCX_PARAM_TABLE and reach the model
  # through the forcing. Reading them off `p` would have given NULL and silently
  # dropped the bomb and land-use rescales, so they are taken from the same
  # ccx_unc_to_par() hb_eval() uses.
  u <- hb_u_at(h); pv <- ccx_unc_to_par(u)
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp)) return(NULL)
  # The forcing is assembled EXACTLY as hb_eval() does it, not approximately.
  # DIC and d13C do not read the 14C columns, so the bomb rescale is a no-op for
  # these three rows -- but GATE C is what proves that rather than assumes it,
  # and it can only prove it if the two paths are otherwise identical.
  F <- base_forc
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forc$c14_bomb * (pv$bomb_total / HB_BOMB_REF)
  for (cc in LUC_COLS) F[[cc]] <- base_forc[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  gd <- ccx_model_ocean_gradient(r$out, sp$aux, sp$grid,
                                 list(surf = tg$dic$epoch_surf, deep = tg$dic$epoch_deep))
  g3 <- ccx_model_ocean_gradient(r$out, sp$aux, sp$grid,
                                 list(surf = tg$d13c$epoch_surf, deep = tg$d13c$epoch_deep))
  pump <- if (!is.null(sp$aux$pump))
    list(S_org = lapply(sp$aux$pump, `[[`, "org"),
         S_carb = lapply(sp$aux$pump, `[[`, "carb")) else NULL
  ak <- ccx_model_ocean_alk_gradient(sp, pump = pump)
  v <- list(dic = gd$dic, d13c = g3$d13c, alk = ak)
  ll <- vapply(names(v), function(k)
    stats::dnorm(tg[[k]]$target, v[[k]], tg[[k]]$sd, log = TRUE), numeric(1))
  list(v = v, ll = ll, sum = sum(ll))
}
ung <- lapply(hs, hb_rows_ungated)
ok  <- !vapply(ung, is.null, logical(1))
rsum_cf <- rep(NA_real_, length(hs))
rsum_cf[ok] <- vapply(ung[ok], `[[`, numeric(1), "sum")
# GATE C: in-band, the ungated recomputation must reproduce the gated row sum.
gc_i <- which(liv & ok)
gapC <- max(abs(rsum_cf[gc_i] - rsum[gc_i]))
cat(sprintf("GATE C: in-band, ungated row sum reproduces the gated one to %.3e (%d points)\n",
            gapC, length(gc_i)))
stopifnot(gapC < 1e-8)

cat(sprintf("\n%6s %6s %14s %14s %14s %14s\n", "h_ml", "rows",
            "objective", "rows removed", "rows (cf)", "obj + cf rows"))
for (i in seq_along(hs))
  cat(sprintf("%6.2f %6s %14.2f %14.2f %14s %14s%s\n", hs[i],
              if (liv[i]) "LIVE" else "ABS", tot[i], oth[i],
              if (is.na(rsum_cf[i])) "--" else sprintf("%.2f", rsum_cf[i]),
              if (is.na(rsum_cf[i])) "--" else sprintf("%.2f", oth[i] + rsum_cf[i]),
              if (hs[i] == HB_H_FIT) "  <- quarantined mode" else
              if (abs(hs[i] - HB_H_IN) < 1e-9) "  <- pump's own h_ml" else ""))

sep("PART 3b. THE THREE TAPERS -- EACH REMOVES THE CLIFF, NONE MOVES THE SUMMIT")
# w(h) = 1 in-band, cosine ramp to 0 over HB_TAPER_W metres outside it.
hb_taper <- function(h, w) {
  d <- pmax(0, pmax(HB_BAND[1] - h, h - HB_BAND[2]))
  ifelse(d <= 0, 1, ifelse(d >= w, 0, 0.5 * (1 + cos(pi * d / w))))
}
argmax_row <- function(v) which.max(ifelse(is.na(v), -Inf, v))
cat(sprintf("%-26s %10s %10s %12s %10s\n", "variant", "argmax h", "in band?",
            "max total", "gain OUT"))
report <- function(lab, v) {
  i <- argmax_row(v)
  inb <- hs[i] >= HB_BAND[1] && hs[i] <= HB_BAND[2]
  ib  <- which(liv); best_in <- if (length(ib)) max(v[ib], na.rm = TRUE) else NA_real_
  cat(sprintf("%-26s %10.2f %10s %12.2f %10s\n", lab, hs[i],
              if (inb) "YES" else "*** NO ***", v[i],
              if (is.na(best_in)) "--" else sprintf("%+.2f", v[i] - best_in)))
  list(lab = lab, argmax = hs[i], in_band = inb, max = v[i],
       gain_out = v[i] - best_in)
}
res_variants <- list()
res_variants$shipped <- report("AS SHIPPED (hard skip)", tot)
res_variants$norows  <- report("rows deleted entirely", oth)
res_variants$always  <- report("rows ALWAYS live (no gate)", oth + rsum_cf)
for (w in HB_TAPER_W) {
  v <- oth + hb_taper(hs, w) * rsum_cf
  res_variants[[paste0("taper", w)]] <-
    report(sprintf("taper, %g m ramp", w), v)
}
cat("\nThe taper's gain from leaving the band is (1 - w(h)) |row sum| by\n")
cat("construction: a weight on a NEGATIVE sum is monotone the wrong way. The\n")
cat("cliff becomes a ramp and the summit does not move.\n")

# =====================================================================
# PART 4. sigma_rep(h), MEASURED -- AND WHAT INFLATION WOULD COST
# =====================================================================
sep("PART 4. THE REPRESENTATION ERROR, MEASURED ON THE OBSERVATIONS")
cat("sigma_rep(h) = |shipped fixed-depth target - like-for-like target on the\n")
cat("model's own boxes at h_ml = h|, per field. This is data-side only -- the\n")
cat("same quantity diag_gradient_target_and_neff.R part 2b prints as 'FREEZING\n")
cat("costs', re-read here as a SIGMA rather than as a bias.\n")

# THE CELLS ARE THE BUILD SCRIPT'S, NOT A NEW ESTIMATOR. Copied from
# diag_gradient_target_and_neff.R's gn_cells()/gn_vw(), which part 1 of that file
# already gates against data-raw/build_glodap_deep_targets.R. GATE D below
# reproduces the SHIPPED target from these cells before any h_ml is varied, so a
# drifted recipe cannot pass itself off as a representation error.
if (!file.exists(HB_GLODAP_FILE)) {
  cat(sprintf("\n*** %s absent -- part 4 SKIPPED.\n", HB_GLODAP_FILE))
  sig_rep <- NULL
} else {
  d <- utils::read.csv(HB_GLODAP_FILE)
  hb_cells <- function(val, flag, zmin, zmax, closed) {
    v <- d[[val]]; f <- d[[flag]]
    ok <- is.finite(v) & v > -900 & is.finite(f) & f == HB_FLAG_OK &
          d$depth >= zmin & (if (closed) d$depth <= zmax else d$depth < zmax)
    if (sum(ok) < 20) return(NULL)
    x  <- d[ok, ]
    id <- paste(floor(x$lat / HB_DLAT), floor(x$lon / HB_DLON),
                floor(x$depth / HB_DZ))
    cl <- data.frame(v   = as.numeric(tapply(x[[val]], id, mean)),
                     lat = as.numeric(tapply(x$lat,    id, mean)))
    cl$w <- cos(cl$lat * pi / 180)
    cl
  }
  hb_vw   <- function(cl) if (is.null(cl)) NA_real_ else sum(cl$w * cl$v) / sum(cl$w)
  hb_grad <- function(val, flag, surf, deep, closed)
    hb_vw(hb_cells(val, flag, deep[1], deep[2], closed)) -
    hb_vw(hb_cells(val, flag, surf[1], surf[2], closed))

  flds <- list(dic = c("tco2", "tco2f"), d13c = c("c13", "c13f"))
  cat("\nGATE D: reproduce the SHIPPED targets from these cells on the shipped\n")
  cat("fixed depths (0-100 m / >2627.2 m, upper edge CLOSED), before varying h_ml.\n")
  cat(sprintf("%-6s %14s %14s %12s\n", "field", "from cells", "shipped rds", "|gap|"))
  gate_d <- vapply(names(flds), function(fn) {
    v <- hb_grad(flds[[fn]][1], flds[[fn]][2], HB_SHIPPED_SURF, HB_SHIPPED_DEEP, TRUE)
    cat(sprintf("%-6s %14.4f %14.4f %12.2e\n", fn, v, tg[[fn]]$target,
                abs(v - tg[[fn]]$target)))
    abs(v - tg[[fn]]$target)
  }, numeric(1))
  # A LOOSE bar, and deliberately: the shipped rds may carry a different upper-
  # edge or minimum-count convention. What must hold is that this recipe lands on
  # the shipped target rather than near it, and 1e-3 of a 233 umol/kg target is
  # 4e-6 relative -- tight enough that a different recipe cannot pass.
  stopifnot(all(gate_d < HB_GATE_D_TOL))
  cat(sprintf("Both reproduced to < %g. The recipe is the build script's.\n", HB_GATE_D_TOL))

  sig_rep <- lapply(names(flds), function(fn) {
    v <- vapply(hs, function(h) {
      gr <- ccx_ocean_grid(h); zb <- c(0, cumsum(gr$dz)); n <- length(gr$dz)
      # `closed = FALSE`, as the model-box variant in
      # diag_gradient_target_and_neff.R part 2 uses -- adjacent boxes must not
      # both claim the shared interface depth.
      hb_grad(flds[[fn]][1], flds[[fn]][2], c(0, zb[2]), c(zb[n], zb[n + 1]), FALSE)
    }, numeric(1))
    data.frame(h = hs, like_for_like = v,
               shipped = tg[[fn]]$target, sd_obs = tg[[fn]]$sd,
               sigma_rep = abs(tg[[fn]]$target - v))
  })
  names(sig_rep) <- names(flds)
  cat("\nNOTE: ALKALINITY IS NOT MEASURABLE HERE. The GLODAP subset carries only\n")
  cat("tco2/c13/c14 -- no talk column -- so sigma_rep for the third row would need\n")
  cat("a new download. Its target came from the same build, so the same\n")
  cat("representation question applies to it and is simply UNQUANTIFIED.\n")
  for (fn in names(sig_rep)) {
    s <- sig_rep[[fn]]
    cat(sprintf("\n--- %s: shipped target %+.4f, sigma_obs %.4f ---\n",
                fn, s$shipped[1], s$sd_obs[1]))
    cat(sprintf("%6s %14s %12s %12s %14s\n", "h_ml", "like-for-like",
                "sigma_rep", "/sigma_obs", "inflation"))
    for (i in seq_len(nrow(s)))
      cat(sprintf("%6.2f %14.4f %12.4f %12.2f %14.2fx%s\n", s$h[i], s$like_for_like[i],
                  s$sigma_rep[i], s$sigma_rep[i] / s$sd_obs[i],
                  sqrt(1 + (s$sigma_rep[i] / s$sd_obs[i])^2),
                  if (s$h[i] == HB_H_FIT) "  <- quarantined mode" else
                  if (abs(s$h[i] - HB_H_IN) < 1e-9) "  <- pump's h_ml" else ""))
  }
  # ---------------------------------------------------------------
  # THE GATE'S OWN JUSTIFICATION, CHECKED. R/likelihood.R's "THE h_ml GATE"
  # paragraph justifies the band with "the mismatch is 0.09 sigma at h_ml = 100
  # but 1.61 sigma at the fitted 184". The first reproduces here (0.04 at 102,
  # 0.09 at 106). THE SECOND DOES NOT: against the SHIPPED target and the SHIPPED
  # sigma, h_ml = 184 is 0.80 sigma, not 1.61 -- a factor of 2. Rather than assume
  # the comment is wrong, the two candidate quantities are computed side by side,
  # because 1.61 is the number diag_gradient_target_and_neff.R part 2b prints and
  # that column is a DIFFERENT contrast: frozen-at-h_ml-75 minus like-for-like, on
  # part 3's block-bootstrap sigma rather than on the shipped rds's.
  cat("\n--- RECEIPT CHECK on R/likelihood.R's '0.09 sigma at 100, 1.61 at 184' ---\n")
  hb_lfl <- function(h, fn) {
    gr <- ccx_ocean_grid(h); zb <- c(0, cumsum(gr$dz)); n <- length(gr$dz)
    hb_grad(flds[[fn]][1], flds[[fn]][2], c(0, zb[2]), c(zb[n], zb[n + 1]), FALSE)
  }
  frozen75 <- hb_lfl(HB_FROZEN_H, "dic")
  cat(sprintf("shipped fixed-depth target        %+9.4f  (sigma %.4f)\n",
              tg$dic$target, tg$dic$sd))
  cat(sprintf("like-for-like at h_ml = %-3g        %+9.4f\n", HB_FROZEN_H, frozen75))
  cat(sprintf("like-for-like at h_ml = %-3g        %+9.4f\n", HB_H_IN, hb_lfl(HB_H_IN, "dic")))
  cat(sprintf("like-for-like at h_ml = %-3g        %+9.4f\n", HB_H_FIT, hb_lfl(HB_H_FIT, "dic")))
  cat(sprintf("\n%-52s %8s\n", "candidate quantity for '1.61 sigma at 184'", "sigma"))
  cat(sprintf("%-52s %8.2f\n", "(shipped - lfl@184) / shipped sd  <- WHAT THE GATE GUARDS",
              abs(tg$dic$target - hb_lfl(HB_H_FIT, "dic")) / tg$dic$sd))
  cat(sprintf("%-52s %8.2f\n", sprintf("(frozen@%g - lfl@184) / shipped sd", HB_FROZEN_H),
              abs(frozen75 - hb_lfl(HB_H_FIT, "dic")) / tg$dic$sd))
  sd_implied <- abs(frozen75 - hb_lfl(HB_H_FIT, "dic")) / HB_REF_MISMATCH_184
  # THE RECEIPT, not a reading. The shipped rds carries BOTH block sigmas:
  # sd_by_block = c(blk30 = 20.2, blk60 = 25.2), and `sd` ships the CONSERVATIVE
  # (larger) one. diag_gradient_target_and_neff.R's part2b() was called with
  # min(...) over the valid blocks -- i.e. the TIGHTER blk30 -- so 1.61 is the
  # frozen@75 contrast divided by 20.2, while the gate guards the shipped 25.2.
  sd_blk <- tg$dic$sd_by_block
  cat(sprintf("%-52s %8.2f\n", sprintf("(frozen@%g - lfl@184) / blk30 sd = %.1f", HB_FROZEN_H,
                                       sd_blk[["blk30"]]),
              abs(frozen75 - hb_lfl(HB_H_FIT, "dic")) / sd_blk[["blk30"]]))
  cat(sprintf("\nsd_by_block in the shipped rds: %s\n",
              paste(sprintf("%s = %.2f", names(sd_blk), sd_blk), collapse = ", ")))
  cat(sprintf("shipped `sd` = %.2f, i.e. the CONSERVATIVE of the two.\n", tg$dic$sd))
  cat(sprintf("1.61 implies sigma = %.2f, which is blk30 (%.2f) to %.0f %%.\n",
              sd_implied, sd_blk[["blk30"]], 100 * abs(sd_implied / sd_blk[["blk30"]] - 1)))
  cat("SO: 1.61 is the FROZEN-at-75 contrast divided by the TIGHTER blk30 sigma --\n")
  cat("part 2b's column, on part 2b's sigma. The gate's OWN quantity, on the sigma\n")
  cat("the gate's own term actually uses, is 0.80 sigma at h_ml = 184. NOT a code\n")
  cat("defect: the band still guards a real mismatch, and the '0.09 sigma at 100'\n")
  cat("half reproduces exactly (0.07 here). But the severity of the band has been\n")
  cat("argued from 1.61 in three handoffs, and it is ~2x overstated.\n")

  bandrows <- sig_rep$dic$h >= HB_BAND[1] & sig_rep$dic$h <= HB_BAND[2]
  cat(sprintf("\nIN-BAND, DIC sigma_rep/sigma_obs spans %.2f-%.2f; OUT of band %.2f-%.2f.\n",
              min(sig_rep$dic$sigma_rep[bandrows] / sig_rep$dic$sd_obs[bandrows]),
              max(sig_rep$dic$sigma_rep[bandrows] / sig_rep$dic$sd_obs[bandrows]),
              min(sig_rep$dic$sigma_rep[!bandrows] / sig_rep$dic$sd_obs[!bandrows]),
              max(sig_rep$dic$sigma_rep[!bandrows] / sig_rep$dic$sd_obs[!bandrows])))
  cat("THAT CONTRAST IS WHAT THE BAND ENCODES, and it is what an inflation would\n")
  cat("carry continuously instead of as a switch.\n")
}

sep("PART 4b. THE THREE WAYS TO SPEND A ROW, PRICED AT THE SAME MISS")
cat("For a row missing by z sigma_obs, what does each formulation contribute?\n")
cat("  live      : -log(sigma sqrt(2 pi)) - z^2/2\n")
cat("  skipped   :  0                                  <- a FREE gain of the above\n")
cat("  inflated  : -log(sigma_eff sqrt(2 pi)) - (z sigma/sigma_eff)^2/2,\n")
cat("              sigma_eff^2 = sigma^2 + sigma_rep^2  <- CHARGED for, and bounded\n")
cat("The inflated row's best case over all sigma_eff is sigma_eff = |miss|, i.e.\n")
cat("-log(|miss| sqrt(2 pi)) - 1/2 -- so inflation can never buy the whole row.\n\n")
price <- function(z, sd) {
  live <- stats::dnorm(z * sd, 0, sd, log = TRUE)
  best <- stats::dnorm(z * sd, 0, abs(z * sd), log = TRUE)   # sigma_eff = |miss|
  c(live = live, skipped = 0, best_inflated = best,
    gain_skip = -live, gain_inflate_max = best - live)
}
cat(sprintf("%-22s %6s %10s %10s %14s %12s %14s\n", "row", "z", "live",
            "skipped", "best inflated", "gain skip", "gain inflate"))
for (k in c("dic", "d13c", "alk")) {
  pr <- price(zs[[k]], tg[[k]]$sd)
  cat(sprintf("%-22s %6.2f %10.2f %10.2f %14.2f %12.2f %14.2f\n",
              paste0("ocean_grad_", k), zs[[k]], pr["live"], 0,
              pr["best_inflated"], pr["gain_skip"], pr["gain_inflate_max"]))
}
tot_skip <- sum(vapply(c("dic", "d13c", "alk"),
                       function(k) price(zs[[k]], tg[[k]]$sd)["gain_skip"], numeric(1)))
tot_infl <- sum(vapply(c("dic", "d13c", "alk"),
                       function(k) price(zs[[k]], tg[[k]]$sd)["gain_inflate_max"], numeric(1)))
cat(sprintf("\n%-22s %6s %10s %10s %14s %12.2f %14.2f\n", "TOTAL", "", "", "", "",
            tot_skip, tot_infl))
cat(sprintf("Inflation's best case recovers %.0f %% of what the skip gives away.\n",
            100 * tot_infl / tot_skip))

# =====================================================================
# PART 5. THE FIVE PREDICTIONS, SCORED
# =====================================================================
sep("PART 5. PREDICTIONS SCORED")
verdict <- function(n, claim, pass, detail) {
  cat(sprintf("%-4s %-8s %s\n     %s\n", n, if (pass) "PASS" else "*** FAIL ***",
              claim, detail))
  pass
}
p1 <- verdict("P1.", "only the three ocean_grad_* streams jump; the rest is slope",
  all(vapply(straddle, function(s)
    setequal(s$jumpers, HB_GRAD_STREAMS) &&
    abs(s$row_sum / s$drift) >= HB_JUMP_RATIO_MIN, logical(1))),
  sprintf("jumpers: %s | jump/drift = %.0fx and %.0fx (bar %gx)",
          paste(unique(unlist(lapply(straddle, `[[`, "jumpers"))), collapse = ", "),
          abs(straddle$lo$row_sum / straddle$lo$drift),
          abs(straddle$hi$row_sum / straddle$hi$drift), HB_JUMP_RATIO_MIN))
p2 <- verdict("P2.", "the cliff IS the rows appearing (exact identity)",
  all(vapply(straddle, function(s)
    abs(s$d_total - s$row_sum - s$drift) <= HB_P2_TOL, logical(1))),
  sprintf("residual: lo %.2e, hi %.2e (bar %g); entry cost %+.2f vs 16f's %.2f",
          straddle$lo$d_total - straddle$lo$row_sum - straddle$lo$drift,
          straddle$hi$d_total - straddle$hi$row_sum - straddle$hi$drift, HB_P2_TOL,
          straddle$lo$d_total, HB_REF_CLIFF))
p3 <- verdict("P3.", "no taper moves the argmax inside the band",
  !any(vapply(res_variants[grep("^taper", names(res_variants))], `[[`,
              logical(1), "in_band")),
  paste(vapply(res_variants[grep("^taper", names(res_variants))], function(r)
    sprintf("%s -> %.1f m", r$lab, r$argmax), character(1)), collapse = " | "))
p4 <- verdict("P4.", "inflation's gain is a LARGE fraction of the skip's",
  tot_infl < tot_skip && tot_infl > HB_INFLATE_MAX_FRAC * tot_skip,
  sprintf("skip gives %.2f, inflation's best case %.2f = %.0f %% (predicted > %.0f %%)",
          tot_skip, tot_infl, 100 * tot_infl / tot_skip, 100 * HB_INFLATE_MAX_FRAC))
cat("     FAILED IN THE DIRECTION THAT STRENGTHENS INFLATION, and the reasoning\n")
cat("     behind the prediction was wrong rather than the bar. I expected z^2/2 to\n")
cat("     dominate each row's logL; it does not, because the misses are only ~1.8\n")
cat("     sigma (z^2/2 ~ 1.6) while -log(sigma sqrt(2 pi)) carries the bulk. So\n")
cat("     inflation caps the give-away at ~1/5 of the skip's, not ~4/5.\n")
p5 <- if (is.null(sig_rep)) {
  cat("P5.  SKIPPED  sigma_rep not measurable from the shipped rds\n"); NA
} else verdict("P5.", "sigma_rep is not small compared with sigma_obs",
  any(sig_rep$dic$sigma_rep / sig_rep$dic$sd_obs > 1),
  sprintf("DIC sigma_rep/sigma_obs spans %.2f-%.2f over h_ml [%g, %g]; d13C %.2f-%.2f",
          min(sig_rep$dic$sigma_rep / sig_rep$dic$sd_obs),
          max(sig_rep$dic$sigma_rep / sig_rep$dic$sd_obs), min(hs), max(hs),
          min(sig_rep$d13c$sigma_rep / sig_rep$d13c$sd_obs),
          max(sig_rep$d13c$sigma_rep / sig_rep$d13c$sd_obs)))
cat("     ALSO FAILED, and this is the one that reframes the band. The\n")
cat("     representation error the band exists to prevent NEVER EXCEEDS ~1 sigma\n")
cat("     anywhere in h_ml's prior support. A mismatch that modest is being\n")
cat("     enforced with a 10-log-unit switch.\n")

# =====================================================================
# PART 6. THE MAGNITUDES SIDE BY SIDE -- WHICH IS THE BLOCKER?
# =====================================================================
sep("PART 6. THE CLIFF IS NOT WHY h_ml LEAVES THE BAND")
i_best   <- argmax_row(tot)
i_bestin <- which(liv)[which.max(tot[liv])]
cat(sprintf("objective's argmax over h_ml       %6.2f m   %12.2f\n", hs[i_best], tot[i_best]))
cat(sprintf("best IN-BAND h_ml                  %6.2f m   %12.2f\n", hs[i_bestin], tot[i_bestin]))
cat(sprintf("the cliff at the band's floor                    %12.2f\n", straddle$lo$row_sum))
cat(sprintf("\nTHE PULL IS %.0fx THE CLIFF: %.0f log-units of h_ml preference against\n",
            abs((tot[i_best] - tot[i_bestin]) / straddle$lo$row_sum),
            tot[i_best] - tot[i_bestin]))
cat(sprintf("%.1f log-units of discarded rows. Deleting the three rows entirely\n",
            abs(straddle$lo$row_sum)))
cat(sprintf("moves the argmax from %.0f m to %.0f m -- i.e. NOT AT ALL.\n",
            hs[i_best], hs[argmax_row(oth)]))
cat("\nSo the rows are not what drives h_ml out of the band, and no formulation of\n")
cat("them can pull it back in. That is a measurement about which of 16f sec.5.5's\n")
cat("options addresses the blocker, and it says: option 1 is not a tie-breaker\n")
cat("between formulations, it is a HARD CONSTRAINT worth the number below.\n")
cat(sprintf("\nCOST OF BOUNDING h_ml TO [%g, %g], at init parameters: %.0f log-units.\n",
            HB_BAND[1], HB_BAND[2], tot[i_best] - tot[i_bestin]))
cat("AN UPPER BOUND, and the same caveat class as 16f sec.5.2g's pump margin:\n")
cat("beta_max, kz and k_w can reallocate some of it in a refit, which is exactly\n")
cat("what a refit is for. It is NOT a claim about the refit's answer.\n")

# =====================================================================
# PART 7. WHO PAYS THE 236 LOG-UNITS?
# =====================================================================
# Part 6 makes the h_ml PULL the blocker rather than the cliff, which moves the
# question from "how should the three rows be carried" to "why does the objective
# want a 32 m mixed layer at all". A parameter running into its own prior bound is
# a flag in this repo's own history (kz did it, and it was numerics wearing a
# prior's clothes -- R/calibrate.R's note on the substep wall). And 32 m is THIN:
# the observed global-mean mixed-layer depth is ~50-80 m. So the pull is either a
# real constraint from a specific stream or a misfit h_ml is absorbing for
# something else, and the per-stream split is what separates those.
sep("PART 7. WHICH STREAMS WANT A 32 m MIXED LAYER?")
HB_H_ATTRIB <- c(32, 50, 75, HB_H_IN, 140, HB_H_FIT)
attrib <- lapply(HB_H_ATTRIB, function(h) hb_eval(hb_u_at(h)))
names(attrib) <- as.character(HB_H_ATTRIB)
ok7 <- !vapply(attrib, is.null, logical(1))
attrib <- attrib[ok7]
keys7 <- Reduce(union, lapply(attrib, function(a) names(a$parts)))
keys7 <- setdiff(keys7, HB_GRAD_STREAMS)   # the rows are part 2's subject, not this one
cat("The three ocean_grad_* rows are EXCLUDED here -- part 2 already accounts for\n")
cat("them, and they are absent at four of these six depths anyway.\n\n")
cat(sprintf("%-22s %s %12s\n", "stream",
            paste(sprintf("%11s", names(attrib)), collapse = ""), "32 - 100"))
gv <- function(a, k) if (k %in% names(a$parts)) a$parts[[k]] else NA_real_
tab7 <- t(vapply(keys7, function(k) vapply(attrib, gv, numeric(1), k), numeric(length(attrib))))
ref <- as.character(HB_H_IN)
delta7 <- tab7[, "32"] - tab7[, ref]
for (i in order(-delta7)) {
  cat(sprintf("%-22s %s %+12.1f\n", keys7[i],
              paste(sprintf("%11.1f", tab7[i, ]), collapse = ""), delta7[i]))
}
cat(sprintf("%-22s %s %+12.1f\n", "SUM (excl. rows)",
            paste(sprintf("%11.1f", colSums(tab7)), collapse = ""), sum(delta7)))
pri7 <- vapply(attrib, `[[`, numeric(1), "prior")
cat(sprintf("%-22s %s %+12.1f\n", "prior (incl. Jacobian)",
            paste(sprintf("%11.1f", pri7), collapse = ""), pri7[["32"]] - pri7[[ref]]))
top <- order(-delta7)[1:3]
cat(sprintf("\nTHE PULL IS CONCENTRATED: %s carry %+.0f of the %+.0f log-units\n",
            paste(keys7[top], collapse = " + "), sum(delta7[top]), sum(delta7)),
    sep = "")
cat(sprintf("(%.0f %%) between h_ml = %g and %g.\n",
            100 * sum(delta7[top]) / sum(delta7), HB_H_IN, 32))
opp <- order(delta7)[1:3]
cat(sprintf("AND IT IS OPPOSED, by %s (%+.0f together) -- the d13C LEVELS and the\n",
            paste(keys7[opp], collapse = " + "), sum(delta7[opp])))
cat("ocean sink want a DEEP mixed layer. So h_ml is not being pulled by consensus;\n")
cat("it is being pulled by the CO2 LEVEL record against the d13C level record.\n")

cat("\nTHE READING, AND IT DISCOUNTS PART 6's 236. A thinner mixed layer takes up\n")
cat("less carbon, so airborne CO2 rises: the CO2-level streams want h_ml small\n")
cat("because the model at init OVER-ABSORBS. Look at their absolute size -- SPO is\n")
cat(sprintf("%.0f log-units at h_ml = %g. Init is a BAD FIT to the CO2 record, and h_ml is\n",
            tab7["co2_level_SPO", ref], HB_H_IN))
cat("simply the cheapest single knob that patches it while the other 19 are frozen.\n")
cat("kz, k_w and beta_max all move ocean and land uptake directly, i.e. they serve\n")
cat("EXACTLY the three streams carrying 96 % of the pull.\n")
cat("\nSO: part 6's 236 log-units is an upper bound AND probably a large\n")
cat("overstatement of what bounding h_ml would really cost a refit. What survives\n")
cat("unconditionally is the NEGATIVE result -- the three gradient rows are\n")
cat("irrelevant to where h_ml goes (deleting them moves the argmax 32 -> 32 m), so\n")
cat("no re-formulation of them is a fix for the pull. Whether the pull itself\n")
cat("survives a refit is the refit's question and this file cannot answer it.\n")

saveRDS(list(straddle = straddle, scan = scan, variants = res_variants,
             attrib = list(h = HB_H_ATTRIB, parts = tab7, prior = pri7,
                           delta_32_minus_ref = delta7),
             sigma_rep = sig_rep, zs = zs, band = HB_BAND,
             predictions = c(P1 = p1, P2 = p2, P3 = p3, P4 = p4, P5 = p5),
             constants = list(HB_H_SCAN = HB_H_SCAN, HB_TAPER_W = HB_TAPER_W,
                              HB_EPS = HB_EPS, HB_BAND = HB_BAND)),
        file.path(HB_OUTDIR, "hml_band_discontinuity.rds"))
cat(sprintf("\nwrote %s\n", file.path(HB_OUTDIR, "hml_band_discontinuity.rds")))
cat("\nNOTHING HERE IS A PROPOSAL. R/likelihood.R is unchanged; the four options\n")
cat("in handoff 16f sec.5.5 are Marcus's call, and this file exists so that the\n")
cat("call is made on the decomposition rather than on the total.\n")
