# =====================================================================
# diag_seas_npp_sh_power.R -- CAN `seas_npp_amp_SH` CLOSE THE SPO LAND
#                             OVERSHOOT, AND IS THE CLOSURE INSIDE THE
#                             OBSERVATION'S OWN BRACKET?
#
# WHY THIS IS THE NEXT TEST. 27h's pre-check (diag_tau_ex_seasonal_power.R,
# diag_tau_ex_conditional_power.R) showed `tau_ex` has neither the price nor
# the SIGN to fix the SPO land overshoot: the NH import is partly HIDING that
# overshoot, not causing it. What is left standing is the SH-LOCAL land
# channel, ~2x the observed land component at SPO, whose dominant term is
# `seas_npp_amp_SH` -- 1.390 ppm at SPO against `resp SH`'s 0.092.
#
# THAT TERM IS A MEASURED CONSTANT AND IS NOT IN CCX_PARAM_TABLE, so no fit
# can touch it. Which makes the question not "will the fit use it" but "is the
# model's value defensible against the measurement, and would the measurement's
# OWN range close the gap".
#
# ⇒ THE GRID IS THE OBSERVATION'S UNCERTAINTY. NOT A SPAN CHOSEN FOR SHAPE.
# R/constants.R: SEAS_NPP_AMP_SH = 0.5027 is the least-squares scale of the
# CCX_SEAS_PHI_EFF['SH'] = -30 insolation shape onto MOD17A2HGF C6.1 PsnNet,
# sd 0.087; and GPP gives 0.352 as the other end of the bracket, "far wider
# than the NH's, because SH productivity is tropical and water-driven". So
# 0.352 is -1.73 sd, and the bracket is a MEASURED disagreement between two
# products, not a prior. [[threshold_from_obs_or_law]]
#
# ⚠ TWO THINGS THIS CONSTANT IS NOT ALLOWED TO BE READ AS.
#   1. It is HALF OF A (shape, size) UNIT with CCX_SEAS_PHI_EFF['SH'] = -30,
#      and R/constants.R says so: move phi and the amplitude must be re-derived.
#      Nothing here moves phi. A verdict from this script is CONDITIONAL on
#      phi_eff, and [[ccx_phi_eff_amplitude]] already says the LATITUDES are
#      right and the AMPLITUDE is not -- which is the reason to look here.
#   2. Scaling it does NOT change the annual carbon budget. R/model.R:1115
#      applies it to `npp * (insol/n - 1)`, a UNIT-ANNUAL-MEAN factor, so the
#      cycle is zero-mean by construction and this profile is not confounded
#      by a budget shift. Gated in sec.0.
#
# ⚠ NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE -- the harness sits
# ⚠ THE OFFSET IS NOW -1.5805, NOT -3.3223 (2026-08-28). Adopting the mode's
# own h_ml band removes the 1.7418 that was a WRONG DECODE; what remains is
# exactly the bounded refit's narrowed-prior constant, which is additive and
# cancels from every difference. [[ccx_hml_band_decode]]
# -1.5805 below it, pre-existing ([[ccx_mode_logpost_offset]]). Everything is
# a difference against this harness at the SHIPPED constant.
#
# Usage:  Rscript calibration/diag_seas_npp_sh_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

NP_YEARS  <- c(1750, 2024)
# THE MEASUREMENT, from R/constants.R. Typed here as named constants so every
# label below derives from them rather than from a literal in a cat().
NP_PSNNET <- ccx_const("SEAS_NPP_AMP_SH")   # 0.5027, the shipped value
NP_SD     <- 0.087                          # sd of that least-squares scale
NP_GPP    <- 0.352                          # the other end of the measured bracket
# Grid in SD UNITS about PsnNet, so every point carries its own distance from
# the measurement. -1.73 is exactly the GPP end; -2.84 is where a PROPORTIONAL
# response would put the SPO land component on its observed value, included to
# find out whether the response IS proportional (it is not assumed).
NP_Z      <- c(-4, -3, -2.84, -2, -1.73, -1, -0.5, 0, 1, 2)
# The conditional arm is expensive, so it runs at three points only: the
# shipped value (the reference), the GPP end (the far edge of the MEASUREMENT),
# and the proportional-closure point (outside it).
NP_COND_Z <- c(0, -1.73, -2.84)
NP_COND_BLOCK <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH",
                   "seas_T_amp_SH", "seas_lag_p", "q10")
NP_MAXIT     <- 1500
NP_RESTARTS  <- 6
NP_RESTOL    <- 0.02
# The 27g challenger's entire net gain, the budget scale everything is read at.
NP_BUDGET <- 11.62
NP_COST_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO",
                  "d13c_seasonal_SPO", "co2_level_MLO", "co2_level_SPO",
                  "d13c_level_MLO", "d13c_level_SPO", "gcb_land_sink",
                  "co2_gradient", "d13c_gradient")
NP_OBS_SPO_LAND  <- 0.683     # inversion, measured at the mode 2026-08-27h
NP_OBS_SPO_OCEAN <- 0.522

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(ccx_mode_file())
# ⚠ ADOPT THE MODE'S OWN h_ml BAND BEFORE DECODING ANYTHING (2026-08-28).
# The pump refits override h_ml's logit band IN PROCESS, so `ccx_unc_to_par()`
# -- a pure function of the SHIPPED table -- returns 85.73 m where this mode
# actually sits at 96.47 m, an 11 % shallower mixed layer. h_ml is frozen in
# this driver, so the effect is a WRONG CONSTANT in every arm, not a changed
# contrast; the arms below were previously all wrong together.
# See the note above ccx_mode_params() in R/paths.R. [[ccx_hml_band_decode]]
ccx_adopt_mode_band(md)
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
stopifnot(!("seas_npp_amp_SH" %in% CCX_PARAM_NAMES))   # a constant, not a parameter

NP_VALS <- NP_PSNNET + NP_SD * NP_Z
cat(sprintf("mode %s (arm %s)\n", basename(ccx_mode_file()), md$pump_mode))
cat(sprintf("SEAS_NPP_AMP_SH shipped %.4f (PsnNet), sd %.3f | GPP end %.3f = %+.2f sd\n",
            NP_PSNNET, NP_SD, NP_GPP, (NP_GPP - NP_PSNNET) / NP_SD))
cat(sprintf("grid %.4f .. %.4f (%+.2f .. %+.2f sd), %d points\n",
            min(NP_VALS), max(NP_VALS), min(NP_Z), max(NP_Z), length(NP_Z)))
cat(sprintf("CCX_SEAS_PHI_EFF['SH'] = %g -- HELD. The pair is a (shape, size) unit.\n",
            CCX_SEAS_PHI_EFF[["SH"]]))

lp_at <- function(a) {
  bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode; bp$seas_npp_amp_SH <- a
  ccx_make_logpost(years = NP_YEARS, base_params = bp)
}
.cache <- new.env(parent = emptyenv())
lp_cached <- function(a) {
  k <- sprintf("%.6f", a)
  if (is.null(.cache[[k]])) .cache[[k]] <- lp_at(a)
  .cache[[k]]
}
one <- lp_cached(NP_PSNNET)(u0)
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f (known -1.5805)\n",
            one, md$logpost, one - md$logpost))
if (abs((one - md$logpost) - (-1.5805)) > 0.5)
  cat("  ⚠ THE OFFSET HAS MOVED. Investigate BEFORE reading this run.\n")

obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
amp    <- function(v) 2 * sqrt(sum(v^2))          # PEAK-TO-PEAK, always
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). See the twin note in
# diag_tau_ex_seasonal_power.R -- this cost a run on 27h.
run_at <- function(pv, a, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  p$seas_npp_amp_SH <- a
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", NP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o  <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(o, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")),
       d13_SPO = vec_of(pick(ms, "d13_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")),
       d13_MLO = vec_of(pick(ms, "d13_seas.MLO")),
       co2_ann_SPO = ms$co2$SPO)
}
NP_CASES <- list(
  NH_origin = list(seas_npp_amp_NH = 0, seas_T_amp_NH = 0, sst_seas_amp_NH = 0),
  SH_land   = list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0),
  SH_ocean  = list(sst_seas_amp_SH = 0, ent_seas_amp_SH = 0))
# The d13C-per-ppm partition ratio, built EXACTLY as diag_seas_channel_decomp.R
# sec.1 builds it -- (model d13/model CO2) / (obs d13/obs CO2) -- so the number
# here is comparable to the 1.93x that arc has been quoting.
obsv <- list(co2_SPO = vec_of(pick(obs, "co2_seas.SPO")),
             d13_SPO = vec_of(pick(obs, "d13_seas.SPO")),
             co2_MLO = vec_of(pick(obs, "co2_seas.MLO")),
             d13_MLO = vec_of(pick(obs, "d13_seas.MLO")))
ratio_at <- function(b, st) {
  ao <- amp(obsv[[paste0("co2_", st)]]); do_ <- amp(obsv[[paste0("d13_", st)]])
  am <- amp(b[[paste0("co2_", st)]]);    dm  <- amp(b[[paste0("d13_", st)]])
  (dm / am) / (do_ / ao)
}

sep("0. GATE -- the driver factor is zero-annual-mean (STRUCTURAL, exact)")
pv0 <- ccx_unc_to_par(u0)
# R/model.R:1115 multiplies this constant onto npp * (insol/n - 1). THAT FACTOR
# is what must integrate to zero over a year; assert it directly rather than
# asserting an invariant annual-mean CO2, which would be WRONG -- a zero-mean
# flux CAN rectify through the q10 nonlinearity, and this project has already
# been bitten by exactly that ([[seas_isotope_rectification]]). So: gate the
# structure, MEASURE the rectification, claim neither from the other.
p_g <- ccx_default_params()
for (n in intersect(names(p_g), CCX_PARAM_NAMES)) p_g[[n]] <- pv0[[n]]
nrm <- ccx_seas_norms(p_g)[["SH"]]
tt  <- seq(0, 1, length.out = 4001)[-4001]
fac <- ccx_insol(CCX_SEAS_PHI_EFF[["SH"]], tt - p_g$seas_lag_p / 12) / nrm$n - 1
cat(sprintf("  mean of the SH NPP seasonal factor over one year: %.3e (pk-pk %.4f)\n",
            mean(fac), diff(range(fac))))
stopifnot(abs(mean(fac)) < 1e-10)
cat("  ⇒ PASS: scaling the constant redistributes carbon WITHIN the year and
")
cat("    cannot shift the annual budget directly.\n\n")
cat("  MEASURED rectification (final annual-mean SPO CO2), reported not gated:\n")
for (a in c(min(NP_VALS), NP_GPP, NP_PSNNET, max(NP_VALS))) {
  ca <- run_at(pv0, a)$co2_ann_SPO
  # length(), NOT nrow(). ccx_model_stats() returns a LIST of columns, not a
  # data.frame, so nrow() is NULL -> sprintf() returns character(0) -> cat()
  # prints NOTHING and the whole rectification report vanishes silently. It did.
  n <- length(ca$mean); stopifnot(n > 0)
  cat(sprintf("    amp %.4f -> %.4f ppm (%d)\n", a, ca$mean[n], ca$year[n]))
}
cat("  Any drift here is REAL rectification, and sec.2's co2_level rows price it.\n")

sep("1. THE PROFILE -- cost of moving the constant, everything else at the mode")
cat(sprintf("  %8s %7s %9s | %10s | %9s %6s | %9s %6s | %9s | %8s\n", "amp", "sd",
            "vs GPP", "raw dlp", "SH-land", "mo", "SPO tot", "mo", "NH-orig", "SPO d13/ppm"))
rows <- list()
for (i in seq_along(NP_Z)) {
  a <- NP_VALS[i]
  l <- lp_cached(a)(u0)
  b <- run_at(pv0, a)
  d <- lapply(NP_CASES, function(m) { v <- b$co2_SPO - run_at(pv0, a, m)$co2_SPO
                                      c(amp = amp(v), mo = ang_mo(v)) })
  k <- sprintf("%+.2f", NP_Z[i])
  rows[[k]] <- list(z = NP_Z[i], amp = a, lp = l, dec = d,
                    tot = c(amp = amp(b$co2_SPO), mo = ang_mo(b$co2_SPO)),
                    r_SPO = ratio_at(b, "SPO"), r_MLO = ratio_at(b, "MLO"))
  cat(sprintf("  %8.4f %+7.2f %9s | %+10.2f | %9.3f %6.2f | %9.3f %6.2f | %9.3f | %8.3f\n",
              a, NP_Z[i], if (a >= NP_GPP) "inside" else "OUTSIDE", l - one,
              d$SH_land[["amp"]], d$SH_land[["mo"]],
              amp(b$co2_SPO), ang_mo(b$co2_SPO), d$NH_origin[["amp"]],
              rows[[k]]$r_SPO))
}
cat(sprintf("\n  'inside' = at or above the GPP end %.3f, i.e. within the MEASURED\n", NP_GPP))
cat("  PsnNet-vs-GPP bracket. 'OUTSIDE' = the model would need a value no\n")
cat("  product supports.\n")

sep("2. WHICH ROWS PAY")
streams_at <- function(a) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv0[[n]]
  p$gamma_enso <- pv0$gamma_enso; p$pump_mode <- md$pump_mode; p$seas_npp_amp_SH <- a
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", NP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv0$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv0$luc_scale
  attr(F, "luc_scale") <- pv0$luc_scale
  o <- ccx_run_fast(sp, F)$out
  unlist(ccx_loglik(o, obs, list(sigma_d14c = pv0$sigma_d14c, rep_dC = pv0$rep_dC,
                                 grad_off_co2 = pv0$grad_off_co2,
                                 grad_off_d13c = pv0$grad_off_d13c),
                    luc = ccx_forcing_eluc_annual(F),
                    deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
}
s_ref <- streams_at(NP_PSNNET)
cat(sprintf("  %8s", "sd"))
for (n in NP_COST_ROWS) cat(sprintf(" %10s", substr(n, 1, 10)))
cat("\n")
for (k in names(rows)) {
  s <- streams_at(rows[[k]]$amp); rows[[k]]$streams <- s
  cat(sprintf("  %+8.2f", rows[[k]]$z))
  for (n in NP_COST_ROWS) cat(sprintf(" %+10.2f", s[[n]] - s_ref[[n]]))
  cat("\n")
}

sep("3. CONDITIONAL -- the constant fixed, the seasonal slice re-optimised")
cat(sprintf("  slice (%d free): %s\n\n", length(NP_COND_BLOCK),
            paste(NP_COND_BLOCK, collapse = ", ")))
idx <- match(NP_COND_BLOCK, CCX_PARAM_NAMES); stopifnot(!anyNA(idx))
fit_block <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead",
              control = list(maxit = NP_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS",
                    control = list(maxit = 200, reltol = 1e-12)), silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead",
                control = list(maxit = NP_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < NP_RESTOL || n_re >= NP_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, last_gain = gain,
       converged = gain < NP_RESTOL)
}
cat(sprintf("  %8s %7s | %11s %11s | %9s %9s | %2s %8s\n", "amp", "sd",
            "cond dlp", "raw dlp", "SH-land", "SPO d13/ppm", "re", "lastgain"))
cond <- list(); v_warm <- u0[idx]
for (z in NP_COND_Z) {
  a <- NP_PSNNET + NP_SD * z
  objf <- function(v) { u <- u0; u[idx] <- v; -lp_cached(round(a, 6))(u) }
  ft <- fit_block(objf, v_warm); v_warm <- ft$par
  u_h <- u0; u_h[idx] <- ft$par; pv <- ccx_unc_to_par(u_h)
  b <- run_at(pv, a)
  sl <- b$co2_SPO - run_at(pv, a, NP_CASES$SH_land)$co2_SPO
  k <- sprintf("%+.2f", z)
  cond[[k]] <- list(z = z, amp = a, lp = -ft$value, u = u_h, pv = pv,
                    sl = amp(sl), r_SPO = ratio_at(b, "SPO"),
                    tot = amp(b$co2_SPO), converged = ft$converged)
  cat(sprintf("  %8.4f %+7.2f | %+11.2f %+11.2f | %9.3f %11.3f | %2d %8.4f%s\n",
              a, z, -ft$value - one, rows[[k]]$lp - one, amp(sl),
              cond[[k]]$r_SPO, ft$restarts, ft$last_gain,
              if (!ft$converged) "  ⚠ STILL MOVING" else ""))
}
ref <- cond[[sprintf("%+.2f", 0)]]$lp
cat(sprintf("\n  Reference = the slice's own optimum at the SHIPPED %.4f: %+.2f vs u_mode.\n",
            NP_PSNNET, ref - one))
for (k in names(cond))
  cat(sprintf("  amp %.4f (%+.2f sd) : cost vs ref %+.2f | slice buy-back %.2fx\n",
              cond[[k]]$amp, cond[[k]]$z, cond[[k]]$lp - ref,
              if (abs(rows[[k]]$lp - one) > 1e-6)
                (cond[[k]]$lp - ref) / (rows[[k]]$lp - one) else NA))

sep("4. THE VERDICT -- does the MEASUREMENT'S OWN BRACKET close the gap?")
kg <- sprintf("%+.2f", -1.73); k0 <- sprintf("%+.2f", 0)
sl0 <- rows[[k0]]$dec$SH_land[["amp"]]; slg <- rows[[kg]]$dec$SH_land[["amp"]]
cat(sprintf("  SH-LOCAL land at SPO, observed comparator %.3f ppm (inversion):\n",
            NP_OBS_SPO_LAND))
cat(sprintf("    at PsnNet %.4f : %.3f ppm = %.2fx observed\n", NP_PSNNET, sl0,
            sl0 / NP_OBS_SPO_LAND))
cat(sprintf("    at GPP    %.4f : %.3f ppm = %.2fx observed   (cost %+.2f raw, %+.2f conditional)\n",
            NP_GPP, slg, slg / NP_OBS_SPO_LAND, rows[[kg]]$lp - one,
            cond[[kg]]$lp - ref))
cat(sprintf("    ⇒ the measured bracket closes %.0f %% of the excess.\n",
            100 * (sl0 - slg) / (sl0 - NP_OBS_SPO_LAND)))
# ⚠ BOTH ARMS, because they move in OPPOSITE DIRECTIONS and quoting the raw one
# alone would report the partition as getting WORSE when a fit that is allowed
# to respond makes it better. The raw arm holds the rest of the seasonal block
# frozen, so the amplitude the land reduction removes is not replaced by
# anything; the conditional arm lets the ocean limb take some of it up.
cat(sprintf("\n  SPO d13C-per-ppm partition ratio, PsnNet -> GPP:\n"))
cat(sprintf("    raw         %.3f -> %.3f   (%s)\n", rows[[k0]]$r_SPO, rows[[kg]]$r_SPO,
            if (rows[[kg]]$r_SPO < rows[[k0]]$r_SPO) "better" else "WORSE"))
cat(sprintf("    conditional %.3f -> %.3f   (%s)\n", cond[[k0]]$r_SPO, cond[[kg]]$r_SPO,
            if (cond[[kg]]$r_SPO < cond[[k0]]$r_SPO) "better" else "WORSE"))
cat(sprintf("  (MLO control, raw %.3f -> %.3f -- invariant means the SH move is not\n",
            rows[[k0]]$r_MLO, rows[[kg]]$r_MLO))
cat("   contaminating the NH station.)\n")

cat("\n  ⚠ WHERE THE WHOLE BILL SITS, and it is one row:\n")
for (k in c(kg, sprintf("%+.2f", -2.84))) {
  st <- rows[[k]]$streams
  cat(sprintf("    %+.2f sd: total %+.2f | co2_seasonal_SPO %+.2f | d13c_seasonal_SPO %+.2f\n",
              rows[[k]]$z, rows[[k]]$lp - one,
              st[["co2_seasonal_SPO"]] - s_ref[["co2_seasonal_SPO"]],
              st[["d13c_seasonal_SPO"]] - s_ref[["d13c_seasonal_SPO"]]))
}
cat("  The CO2 amplitude row vetoes the land reduction; the d13C row WANTS it.\n")
cat("  [[seas_right_observable_wrong_drivers]] -- that CO2 row is already matched\n")
cat("  to ~1 %, so it has no power to identify drivers, only to punish moving them.\n")
cat(sprintf("\n  Budget scale: the 27g challenger's entire net gain was %+.2f.\n", NP_BUDGET))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(psnnet = NP_PSNNET, sd = NP_SD, gpp = NP_GPP, z = NP_Z,
             phi_eff_SH = CCX_SEAS_PHI_EFF[["SH"]],
             harness_at_u_mode = one, rows = rows, cond = cond, cond_ref = ref,
             obs_spo_land = NP_OBS_SPO_LAND),
        file.path(OUTDIR, "seas_npp_sh_power.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "seas_npp_sh_power.rds")))
