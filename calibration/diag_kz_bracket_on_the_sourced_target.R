# =====================================================================
# IS `kz` <= 6528 DEFENSIBLE? -- THE BRACKET, RE-DERIVED ON THE SOURCED
# OBSERVATION AND THEN TESTED ON THE AXIS THAT RAILS AGAINST IT.
#
# WHY THIS EXISTS, AND WHY IT RUNS BEFORE THE REFIT. Handoff 2026-08-31b s.1a
# lists the `kz` bracket as BLOCKING: `kz` rails at exactly 6528 (100 % of the
# bracket) at every constrained point of the on-support land axis, so the
# -285 / -298 price that s.8.3 puts to Marcus as a judgement call is SET BY THE
# BRACKET, not by the data. [[ccx_price_measured_off_support]] states the
# consequence: "-232 and -285 BRACKET the truth, and which end is right depends
# on whether `kz` <= 6528 is defensible. Settle the bracket BEFORE the
# judgement call -- it is cheaper and it moves the call."
#
# ⚠ THE MEMORY CALLS THE BRACKET "a numerically-chosen support, neither an
# observation nor a law". THAT IS HALF WRONG, AND THE HALF THAT IS WRONG IS THE
# HALF THAT MATTERS. The bisection recipe in R/calibrate.R IS observational:
# both ends are the `kz` that puts the model's deep ocean at a stated Delta14C.
# What is not sourced is the TARGET it was bisected against -- "[-200, -150]
# permil", recorded in calibrate.R itself as "an uncited recollection", on the
# bottom THREE boxes, while the likelihood term added later scores the BOTTOM
# BOX against GLODAPv2's sourced -175.3 +/- 10.3 permil ([[ccx_glodap_deep]]).
# So the question is not "observation or not". It is: WHICH observation, ON
# WHICH LAYER, AND WITH WHAT SIGMA.
#
# ⚠ AND THE PHYSICAL-LAW ROUTE IS ALREADY CLOSED, WITH A RECEIPT. DESIGN s.3.4
# prices `kz` against Ledwell's NATRE thermocline diffusivity, (1.7 +/- 0.2)e-5
# m2/s = 536 m2/yr: the model runs ~12x that BY CONSTRUCTION, because a 1-D
# column's effective diffusivity is emulating three-dimensional advective
# transport. So [[threshold_from_obs_or_law]]'s law route cannot bound this
# parameter at all, and the deep-Delta14C observation is the only bound
# available. That is a reason to get the observation right, not to shrug.
#
# WHAT THIS MEASURES, in three parts. It ADOPTS NOTHING: the shipped
# CCX_PARAM_TABLE is never mutated (asserted at the end) and no bracket is
# changed. Moving the bounds is Marcus's call, as calibrate.R says in terms.
#
#   PART 1  THE BRACKET IN THE UNITS OF THE OBSERVATION IT ENCODES. Both ends
#           mapped onto the bottom box -- the layer `d14c_deep_ocean` actually
#           scores -- and expressed as z against the GLODAP target. Gated
#           against DESIGN s.5.2j's own published -219.8 / -162.8.
#   PART 2  RE-BISECT ON THE SOURCED TARGET. The same recipe, same monotone
#           map, run against GLODAP's -175.3 +/- 10.3 at k = 1, 2, 3 sigma
#           instead of against the recollection. Where does 6528 fall?
#   PART 3  THE RAIL TEST -- does the OBSERVATION hold `kz`, or only the
#           bracket? The on-support land axis re-run with `kz`'s support
#           REPLACED by PART 2's widest sourced bracket, everything else
#           identical. Three outcomes, all informative:
#             (a) `kz` turns over INSIDE  -> the rail was the bracket's; the
#                 price of gate 7 is smaller than -285 and PART 3 measures it.
#             (b) `kz` rails at the NEW top too -> the observation does not
#                 hold `kz` either; -285 stands as a bracket artifact at any
#                 width and the constraint has to come from somewhere else.
#             (c) it turns over but at a Delta14C the data reject -> the
#                 bracket is doing real work and 6528 is defensible.
#
# ⚠ WHY THE WIDEST BRACKET IS THE RIGHT ONE FOR PART 3. Using k = 3 sigma means
# the "does it turn over" verdict is NOT chosen by me: a turnover inside the
# widest admissible support is a turnover inside every narrower one. The prior
# stays flat (dunif) inside, so within one frontier the posterior ranking is
# the likelihood ranking, and every row -- INCLUDING THE ANCHOR -- is
# re-optimised under the same widened support, which is what makes the deltas
# like-for-like. ⚠ Deltas are comparable WITHIN a frontier only: the incumbent
# and widened frontiers carry different priors and different log-jacobians, so
# their absolute logposts are not on the same scale.
#
# WHAT PART 3 ALSO ANSWERS, for free. R/calibrate.R states the bracket's exit
# condition: "keep the bracket, add the term at n_eff = 20. DELETE IT ONLY
# AFTER A REFIT SHOWS THE TERM HOLDING kz ALONE." `diag_kz_railed.R` asked that
# at the mode with every other parameter FROZEN and found the likelihood turning
# over at 6462, inside. PART 3's anchor row asks it again with kz/fert_k/q10
# RE-OPTIMISED -- a strictly harder version of the same question -- and the
# constrained rows ask it where the axis is actually pressing.
#
# Run:  Rscript calibration/diag_kz_bracket_on_the_sourced_target.R   (~15 min)
# =====================================================================

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- every label, threshold and filename below derives from these ----
KB_MODE     <- file.path("calibration", "output", "refit_20260830_gamma_diff_remap",
                         "from90", "mode_fit_pumpN.rds")
KB_INCUMBENT <- c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi)
KB_RECOLL   <- c(-200, -150)      # the UNCITED bracket the incumbent was bisected on
KB_DOC_BOT  <- c(-219.8, -162.8)  # DESIGN s.5.2j's published bottom-box ends -- the gate
KB_DOC_TOL  <- 0.15               # permil; s.5.2j prints 1 dp, so this is its own precision
KB_SIGMAS   <- c(1, 2, 3)         # sourced brackets re-bisected at these k
KB_WIDE_K   <- 3                  # PART 3 runs on the WIDEST -- see the header
KB_SEARCH   <- c(1500, 30000)     # bisection search range, m2/yr
KB_TOL      <- 0.5                # m2/yr, matches diag_kz_bracket_pump.R
KB_GRID     <- c(2000, 3000, 3942.5, 5000, 6528, 8000, 12000, 20000)  # monotonicity check
KB_BETA     <- c(0.5552, 0.50, 0.45, 0.40, 0.35, 0.30)  # = LA_BETA, for comparability
KB_FREE     <- c("kz", "fert_k", "q10")
KB_MAXIT    <- 400
KB_WIN      <- c(2015, 2023)
KB_LL_GATE  <- -1494.871          # the objective's value at the mode's own vector
KB_OUT      <- "outputs/diagnostics/kz_bracket_on_the_sourced_target.rds"
KB_LEDWELL  <- 536                # m2/yr = (1.7 +/- 0.2)e-5 m2/s, DESIGN s.3.4
KB_SEC_PER_YR <- 31557600         # Julian year, for the m2/s conversion only
# the on-support land axis this is the counterfactual to (d loglik / d logpost)
KB_INC_DLL  <- c(0.00, NA, -41.86, NA, -284.86, -621.25)
KB_INC_DLP  <- c(0.00, NA, -57.37, NA, -298.16, -638.23)
KB_INC_SRC  <- "diag_price_the_land_axis_on_support.R (2026-08-31, commit d335152)"

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
KB_TABLE_SNAPSHOT <- CCX_PARAM_TABLE$kz[c("tr", "lo", "hi", "init")]

tg <- ccx_deep_d14c_target()
if (is.null(tg)) stop("GLODAP deep target absent -- data/obs_glodap_deep.rds is gitignored ",
                      "and must be rebuilt (data-raw/build_glodap_deep_targets.R). ",
                      "Every number in this script is measured against it; there is no default.")
z_of <- function(d14) (d14 - tg$target) / tg$sd

cat(sprintf("THE SOURCED TARGET: %.2f permil, sd %.3f (n_eff %d; full spread %.1f), layer %s\n",
            tg$target, tg$sd, tg$n_eff, tg$sd_spread, paste(range(tg$layer), collapse = "-")))
cat(sprintf("THE INCUMBENT BRACKET: [%.1f, %.1f] m2/yr, bisected on the UNCITED [%d, %d] permil\n",
            KB_INCUMBENT[1], KB_INCUMBENT[2], KB_RECOLL[1], KB_RECOLL[2]))
cat(sprintf("  = %.1f to %.1f Ledwell NATRE units (%d m2/yr) -- the law route, closed by construction\n",
            KB_INCUMBENT[1] / KB_LEDWELL, KB_INCUMBENT[2] / KB_LEDWELL, KB_LEDWELL))
cat(sprintf("  = %.2e to %.2e m2/s\n", KB_INCUMBENT[1] / KB_SEC_PER_YR,
            KB_INCUMBENT[2] / KB_SEC_PER_YR))

# =====================================================================
# PART 1 -- THE BRACKET IN THE UNITS OF THE OBSERVATION IT ENCODES
# =====================================================================
sep("PART 1 -- the incumbent bracket, expressed on the layer the likelihood scores")

OBS_GRAD <- ccx_const("PUMP_GRAD_OBS")
# The incumbent recipe's configuration: DEFAULT parameters, pump ON at the
# observed gradient, mode N. Reproduced exactly so PART 2 is the same recipe.
kb_defaults <- local({ p <- ccx_default_params()
                       p$pump_grad <- OBS_GRAD; p$pump_mode <- "N"; p })
kb_deep <- function(kz, p) {
  q <- p; q$kz <- kz
  sp <- tryCatch(ccx_spinup(q), error = function(e) NULL)
  if (is.null(sp)) return(c(bottom = NA_real_, three = NA_real_))
  c(bottom = sp$diagnostics$d14c_bottom_box, three = sp$diagnostics$d14c_deep_ocean)
}

# ---- GATE: the map must reproduce DESIGN s.5.2j's published ends -----
# ⚠ This reads a number PUBLISHED ELSEWHERE, not one this script writes
# ([[gate_reads_its_own_output]]). If it fails, the kz -> Delta14C map has moved
# since the re-bisection and PART 2 would be re-deriving on a different model.
d_lo <- kb_deep(KB_INCUMBENT[1], kb_defaults)
d_hi <- kb_deep(KB_INCUMBENT[2], kb_defaults)
cat(sprintf("%10s %12s %8s %12s %8s\n", "kz", "bottom box", "z", "3-box", "(recoll)"))
for (r in list(list(KB_INCUMBENT[1], d_lo), list(KB_INCUMBENT[2], d_hi)))
  cat(sprintf("%10.1f %12.2f %+8.2f %12.2f %8s\n", r[[1]], r[[2]][["bottom"]],
              z_of(r[[2]][["bottom"]]), r[[2]][["three"]], "<- bisected here"))
gate1 <- max(abs(c(d_lo[["bottom"]], d_hi[["bottom"]]) - KB_DOC_BOT))
if (!is.finite(gate1) || gate1 > KB_DOC_TOL)
  stop(sprintf("GATE FAILED: bottom-box ends %.2f / %.2f do not reproduce DESIGN s.5.2j's ",
               d_lo[["bottom"]], d_hi[["bottom"]]),
       sprintf("%.1f / %.1f (max |diff| %.2f > %.2f permil). The map has moved.",
               KB_DOC_BOT[1], KB_DOC_BOT[2], gate1, KB_DOC_TOL))
cat(sprintf("GATE PASSED: reproduces DESIGN s.5.2j's %.1f / %.1f to %.2f permil.\n",
            KB_DOC_BOT[1], KB_DOC_BOT[2], gate1))

cat(sprintf("\nSO THE INCUMBENT BRACKET IS, ON THE SCORED LAYER, z in [%+.2f, %+.2f]:\n",
            z_of(d_lo[["bottom"]]), z_of(d_hi[["bottom"]])))
cat(sprintf("  a box %.2f sigma WIDE, centred %.2f sigma BELOW the sourced target.\n",
            z_of(d_hi[["bottom"]]) - z_of(d_lo[["bottom"]]),
            -0.5 * (z_of(d_lo[["bottom"]]) + z_of(d_hi[["bottom"]]))))

# =====================================================================
# PART 2 -- RE-BISECT ON THE SOURCED TARGET
# =====================================================================
sep("PART 2 -- the same recipe, run against GLODAP instead of the recollection")

# ---- GATE: bisection is meaningless on a non-monotone map ------------
mono <- vapply(KB_GRID, function(k) kb_deep(k, kb_defaults)[["bottom"]], numeric(1))
cat("monotonicity check (more mixing -> younger deep water):\n")
cat(sprintf("  kz    %s\n", paste(sprintf("%8.0f", KB_GRID), collapse = "")))
cat(sprintf("  d14C  %s\n", paste(sprintf("%8.1f", mono), collapse = "")))
if (any(!is.finite(mono)) || any(diff(mono) <= 0))
  stop("GATE FAILED: the kz -> bottom-box map is not strictly increasing on the grid. ",
       "Bisection is meaningless; do not read PART 2.")
cat("GATE PASSED: strictly increasing, so every bisection below is well posed.\n\n")

kb_solve <- function(target, p) {
  lo <- KB_SEARCH[1]; hi <- KB_SEARCH[2]
  f <- function(k) kb_deep(k, p)[["bottom"]] - target
  flo <- f(lo); fhi <- f(hi)
  if (!is.finite(flo) || !is.finite(fhi) || flo * fhi > 0) return(NA_real_)
  while (hi - lo > KB_TOL) {
    mid <- 0.5 * (lo + hi); fm <- f(mid)
    if (!is.finite(fm)) return(NA_real_)
    if (flo * fm <= 0) { hi <- mid; fhi <- fm } else { lo <- mid; flo <- fm }
  }
  0.5 * (lo + hi)
}

sourced <- do.call(rbind, lapply(KB_SIGMAS, function(k) {
  lo <- kb_solve(tg$target - k * tg$sd, kb_defaults)
  hi <- kb_solve(tg$target + k * tg$sd, kb_defaults)
  data.frame(k = k, d14_lo = tg$target - k * tg$sd, d14_hi = tg$target + k * tg$sd,
             kz_lo = lo, kz_hi = hi)
}))
cat(sprintf("%4s %22s %20s %14s\n", "k", "target +/- k sigma", "-> kz bracket",
            "top vs 6528"))
for (i in seq_len(nrow(sourced)))
  cat(sprintf("%4d   [%8.2f, %8.2f]   [%8.1f, %8.1f]   %+8.1f (%+.0f%%)\n",
              sourced$k[i], sourced$d14_lo[i], sourced$d14_hi[i],
              sourced$kz_lo[i], sourced$kz_hi[i],
              sourced$kz_hi[i] - KB_INCUMBENT[2],
              100 * (sourced$kz_hi[i] - KB_INCUMBENT[2]) / KB_INCUMBENT[2]))

# the sourced bracket PART 3 runs on
KB_WIDE <- c(sourced$kz_lo[sourced$k == KB_WIDE_K], sourced$kz_hi[sourced$k == KB_WIDE_K])
if (any(!is.finite(KB_WIDE)))
  stop("PART 2 could not bracket the k = ", KB_WIDE_K, " sigma target inside the search range [",
       KB_SEARCH[1], ", ", KB_SEARCH[2], "] m2/yr. Widen KB_SEARCH or reduce KB_WIDE_K.")
cat(sprintf("\nPART 3 RUNS ON THE k = %d SIGMA BRACKET: [%.1f, %.1f] m2/yr",
            KB_WIDE_K, KB_WIDE[1], KB_WIDE[2]))
cat(sprintf(" (%.1f-%.1f Ledwell units)\n", KB_WIDE[1] / KB_LEDWELL, KB_WIDE[2] / KB_LEDWELL))

# ⚠ SENSITIVITY, NOT THE RECIPE. The bisection above is at DEFAULT parameters
# because that is what the incumbent recipe does and PART 2 is a like-for-like
# re-run of it. The FRONTIER sits at the mode's parameters, where `pump_grad`
# and `h_ml` are fitted, so the map is not identical there. Reported so the
# difference is visible rather than assumed away.
md <- readRDS(KB_MODE); ccx_adopt_mode_band(md)
p0 <- ccx_migrate_par_set(ccx_mode_params(KB_MODE))
p0_fitted <- p0
base <- ccx_default_params()
for (n in intersect(names(base), names(p0))) base[[n]] <- p0[[n]]
stopifnot(identical(base$seas_lag_p_NH, p0$seas_lag_p),
          identical(base$seas_lag_p_SH, p0$seas_lag_p))
base <- ccx_set_enso(base, p0)
base$pump_mode  <- md$pump_mode

sourced_at_mode <- do.call(rbind, lapply(KB_SIGMAS, function(k) {
  data.frame(k = k,
             kz_lo = kb_solve(tg$target - k * tg$sd, base),
             kz_hi = kb_solve(tg$target + k * tg$sd, base))
}))
cat("\nSENSITIVITY -- the same bisection at the MODE's parameters, not the defaults:\n")
for (i in seq_len(nrow(sourced_at_mode)))
  cat(sprintf("%4d sigma: [%8.1f, %8.1f]  (defaults: [%8.1f, %8.1f])\n",
              sourced_at_mode$k[i], sourced_at_mode$kz_lo[i], sourced_at_mode$kz_hi[i],
              sourced$kz_lo[i], sourced$kz_hi[i]))

# =====================================================================
# PART 3 -- DOES THE OBSERVATION HOLD `kz`, OR ONLY THE BRACKET?
# =====================================================================
sep(sprintf("PART 3 -- the land axis on the SOURCED k = %d sigma support", KB_WIDE_K))

obs <- ccx_prepare_obs()
gcb <- local({ g <- as.data.frame(obs$gcb); k <- g$year >= KB_WIN[1] & g$year <= KB_WIN[2]
               list(land = mean(g$land_sink[k]), ocean = mean(g$ocean_sink[k])) })
GCB_LAND_SD <- 0.50; GCB_OCEAN_SD <- 0.40    # GCB 2025 stated 1 sigma
JOOS_100 <- with(JOOS_T5, a0 + sum(a * exp(-100 / tau)))
cat(sprintf("GATE 7 targets on %d-%d: land %.3f +/- %.2f, ocean %.3f +/- %.2f\n",
            KB_WIN[1], KB_WIN[2], gcb$land, GCB_LAND_SD, gcb$ocean, GCB_OCEAN_SD))
cat(sprintf("GATE 12a target: IRF(100) = %.3f (Joos T5 multi-model mean)\n", JOOS_100))

# ⚠ THE OBJECTIVE'S OWN err, replicated from R/calibrate.R -- passing diagnostic
# default sigmas is 253 log-units of construction artifact ([[ccx_gates_priced]]).
err <- list(sigma_d14c = p0$sigma_d14c, rep_dC = p0$rep_dC,
            grad_off_co2 = p0$grad_off_co2, grad_off_d13c = p0$grad_off_d13c)

sinks_of <- function(r) {
  o <- r$out; yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  tt <- o$t; n <- length(tt)
  stock <- function(v) {
    y <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    if (any(hi)) y[hi] <- v[n] + (bnd[hi] - tt[n]) * (v[n] - v[n-1]) / (tt[n] - tt[n-1])
    diff(y)
  }
  el <- ccx_forcing_eluc_annual(r$F); k <- yrs >= KB_WIN[1] & yrs <= KB_WIN[2]
  list(ocean = mean(stock(o$ocean_C)[k]),
       land  = mean((stock(o$land_C) + el$eluc[match(yrs, el$year)])[k]))
}
# replicated EXACTLY from diag_joos_irf.R, including the arm's own fitted
# luc_scale / bomb_total -- the literals would score a different background.
JOOS_HORIZON    <- 300
JOOS_LUC_SCALE  <- p0$luc_scale
JOOS_BOMB_TOTAL <- p0$bomb_total
joos_build_forcing <- function(scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- JOOS_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- JOOS_LUC_SCALE
  do.call(ccx_build_forcing, c(list(scenario, years), args))
}
irf100_of <- function(p) {
  sp <- ccx_spinup(p)
  Fh <- joos_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = sp$prod_c14)
  spr <- sp; spr$y <- ccx_run_fast(sp, Fh)$state
  Ff <- suppressWarnings(joos_build_forcing("historical",
        c(JOOS_REF_YEAR, JOOS_REF_YEAR + JOOS_HORIZON + 10),
        prod_c14 = sp$prod_c14, bomb_total_kmol = 0))
  for (cc in c("e_foss_NH","e_foss_SH","e_luc_NH","e_luc_SH","enso",
               "c14_bomb","c14_nuclear")) Ff[[cc]] <- 0
  Ff$gmst <- Ff$gmst[1]
  o <- ccx_irf(spr, ccx_hold_forcing(spr, Ff, verbose = FALSE))
  o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR)
  o$irf[which.min(abs(o$t - 100))]
}
eval_of <- function(p) {
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(list(ll = -Inf))
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                         bomb_total_kmol = p0$bomb_total, luc_scale = p0$luc_scale)
  r <- ccx_run_fast(sp, F); r$F <- F
  if (anyNA(r$out$co2_NH)) return(list(ll = -Inf))
  ll <- ccx_loglik(r$out, obs, err, luc = ccx_forcing_eluc_annual(F),
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp))
  list(ll = ll, r = r, deep = sp$diagnostics$d14c_bottom_box)
}

# ---- GATE: the frontier's likelihood must BE the objective's ---------
.chk <- eval_of(base)$ll
cat(sprintf("\nGATE: loglik at the mode's own vector = %.3f (objective's %.3f)\n",
            .chk, KB_LL_GATE))
if (abs(.chk - KB_LL_GATE) > 0.5)
  stop("the frontier's likelihood is NOT the objective's -- off by ",
       round(.chk - KB_LL_GATE, 3), " log-units. Fix before reading any price.")
cat("GATE PASSED.\n")

# ---- the widened kz spec. LOCAL. The shipped table is NOT mutated. ---
KB_KZ_WIDE <- list(tr = "logit", lo = KB_WIDE[1], hi = KB_WIDE[2],
                   prior = function(x) dunif(x, KB_WIDE[1], KB_WIDE[2], log = TRUE))
spec_of <- function(n) if (identical(n, "kz")) KB_KZ_WIDE else CCX_PARAM_TABLE[[n]]

# ---- GATE: no reported point may leave the support being tested ------
on_support <- function(p, nms) {
  bad <- character(0)
  for (n in nms) {
    s <- spec_of(n)
    u <- suppressWarnings(.to_unc(p[[n]], s))
    if (!is.finite(u) || !is.finite(suppressWarnings(s$prior(p[[n]]))))
      bad <- c(bad, sprintf("%s=%.4g (support [%s, %s])", n, p[[n]],
                            format(s$lo), format(s$hi)))
  }
  bad
}
logprior_of <- function(moved) {
  pp <- p0_fitted
  for (n in names(moved)) pp[[n]] <- moved[[n]]
  s <- 0
  for (n in CCX_PARAM_NAMES) {
    sp <- spec_of(n); v <- pp[[n]]
    if (is.null(v)) stop("logprior_of(): no value for fitted parameter ", n)
    s <- s + sp$prior(v) + .log_jac(.to_unc(v, sp), sp)
  }
  s
}

cat(sprintf("\n%s\n", strrep("=", 96)))
rows <- list()
for (bm in KB_BETA) {
  pb <- base; pb$beta_max <- bm
  u0  <- vapply(KB_FREE, function(n) .to_unc(base[[n]], spec_of(n)), numeric(1))
  put <- function(u) { q <- pb
    for (i in seq_along(KB_FREE)) q[[KB_FREE[i]]] <- .from_unc(u[i], spec_of(KB_FREE[i]))
    q }
  neg <- function(u) { v <- eval_of(put(u))$ll; if (!is.finite(v)) 1e6 else -v }
  op  <- stats::optim(u0, neg, method = "Nelder-Mead",
                      control = list(maxit = KB_MAXIT, reltol = 1e-10))
  pb_opt <- put(op$par)
  bad <- on_support(pb_opt, KB_FREE)
  if (length(bad))
    stop("GATE FAILED -- a reported point is off-support: ", paste(bad, collapse = "; "))

  L <- eval_of(pb_opt); sk <- sinks_of(L$r)
  rows[[length(rows) + 1]] <- data.frame(
    beta_max = bm, loglik = L$ll,
    logprior = logprior_of(c(list(beta_max = bm), pb_opt[KB_FREE])),
    kz = pb_opt$kz, kz_pct = 100 * (pb_opt$kz - KB_WIDE[1]) / diff(KB_WIDE),
    deep = L$deep, z_deep = z_of(L$deep),
    fert_k = pb_opt$fert_k, q10 = pb_opt$q10,
    land = sk$land, ocean = sk$ocean,
    z_land = (sk$land - gcb$land) / GCB_LAND_SD,
    z_ocean = (sk$ocean - gcb$ocean) / GCB_OCEAN_SD,
    irf100 = irf100_of(pb_opt))
  x <- rows[[length(rows)]]
  cat(sprintf("beta_max %.4f | loglik %10.2f | kz %7.1f (%3.0f%% of the SOURCED bracket) | deep %7.2f (z %+5.2f) | land %+5.2f sd  ocean %+5.2f sd | IRF100 %.3f\n",
              x$beta_max, x$loglik, x$kz, x$kz_pct, x$deep, x$z_deep,
              x$z_land, x$z_ocean, x$irf100))
}
res <- do.call(rbind, rows)
res$dloglik  <- res$loglik - res$loglik[1]
res$dlogpost <- (res$loglik + res$logprior) - (res$loglik[1] + res$logprior[1])

dir.create(dirname(KB_OUT), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(sourced_bracket = sourced, sourced_at_mode = sourced_at_mode,
             incumbent = KB_INCUMBENT, incumbent_bottom = c(d_lo[["bottom"]], d_hi[["bottom"]]),
             target = tg, wide = KB_WIDE, wide_k = KB_WIDE_K,
             land_axis_sourced = res, gcb = gcb, joos100 = JOOS_100,
             mode = KB_MODE, counterfactual = KB_INC_SRC), KB_OUT)

# =====================================================================
sep("THE VERDICT")
cat(sprintf("%9s %10s %10s %10s %10s %9s %9s %9s\n", "beta_max", "d loglik",
            "(incumbt)", "d logpost", "(incumbt)", "kz % wide", "z_deep", "IRF100"))
for (i in seq_len(nrow(res)))
  cat(sprintf("%9.4f %10.2f %10s %10.2f %10s %9.0f %+9.2f %9.3f\n",
              res$beta_max[i], res$dloglik[i],
              ifelse(is.na(KB_INC_DLL[i]), "-", sprintf("%.2f", KB_INC_DLL[i])),
              res$dlogpost[i],
              ifelse(is.na(KB_INC_DLP[i]), "-", sprintf("%.2f", KB_INC_DLP[i])),
              res$kz_pct[i], res$z_deep[i], res$irf100[i]))
cat(sprintf("\n(incumbent columns: %s -- on the [%.1f, %.1f] bracket.\n",
            KB_INC_SRC, KB_INCUMBENT[1], KB_INCUMBENT[2]))
cat(" ⚠ Comparable as a SHAPE, not level-for-level: different prior, different jacobian.)\n")

RAIL_TOL <- 1.0   # % of the widened bracket; the optimiser's own resolution in kz
railed <- res$kz_pct > (100 - RAIL_TOL)
cat("\nDOES THE OBSERVATION HOLD kz, OR ONLY THE BRACKET?\n")
if (!any(railed)) {
  cat(sprintf("  (a) kz TURNS OVER INSIDE the sourced k=%d sigma support at EVERY row",
              KB_WIDE_K))
  cat(sprintf(" (max %.0f%%).\n", max(res$kz_pct)))
  cat("      The 6528 rail was the BRACKET's, not the data's. The prices in the\n")
  cat("      'd loglik' column above are the ones the s.8.3 judgement call is about.\n")
} else if (all(railed[-1])) {
  cat(sprintf("  (b) kz RAILS at the new top too (%d of %d rows at >%.0f%% of the widened\n",
              sum(railed), nrow(res), 100 - RAIL_TOL))
  cat("      bracket). Widening does not release it: the deep-Delta14C observation does\n")
  cat("      NOT hold kz either, and the price is a bracket artifact at any width.\n")
  cat("      ⇒ The constraint on kz has to come from somewhere other than this term.\n")
} else {
  cat(sprintf("  MIXED: rows %s rail, the rest turn over. Read the table.\n",
              paste(which(railed), collapse = ", ")))
}
g7 <- which(abs(res$z_land) < 1 & abs(res$z_ocean) < 1)
if (length(g7)) {
  i <- g7[1]
  cat(sprintf("\nGATE 7 first closes at beta_max %.4f for %.1f loglik / %.1f logpost,\n",
              res$beta_max[i], res$dloglik[i], res$dlogpost[i]))
  cat(sprintf("with the deep ocean at %.1f permil (z %+.2f) -- %s.\n", res$deep[i],
              res$z_deep[i],
              if (abs(res$z_deep[i]) < KB_WIDE_K) "INSIDE the data's own envelope"
              else "OUTSIDE it"))
} else {
  cat("\nGATE 7 NEVER CLOSES on this axis even on the sourced support.\n")
}

# ---- MUTATION GUARD: the shipped table must be untouched -------------
if (!identical(CCX_PARAM_TABLE$kz[c("tr", "lo", "hi", "init")], KB_TABLE_SNAPSHOT))
  stop("CCX_PARAM_TABLE$kz WAS MUTATED by this script. It measures; it must not adopt.")
cat(sprintf("\nMUTATION GUARD PASSED: CCX_PARAM_TABLE$kz is still [%.1f, %.1f]. Nothing adopted.\n",
            CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi))
cat(sprintf("Saved: %s\n", KB_OUT))
