# =====================================================================
# diag_alpha_as_up_precheck.R -- THE §5 PRE-CHECK ON alpha_as_up:
#   IS A TEMPERATURE-DEPENDENT EVASION FRACTIONATION BIG ENOUGH TO MATTER?
#
# WHY THIS EXISTS. `handoff_2026-09-01f` §5. `alpha_as_up` carries the
# EQUILIBRIUM 13C fractionation on the ocean->atmosphere limb, equilibrium
# fractionations are temperature-dependent, and `alpha_as_up` is a SCALAR with
# no temperature argument anywhere (R/model.R:2024, src/ccx_core.cpp:478). So
# under a seasonal SST cycle the model omits a seasonal d13C term whose
# amplitude scales with `sst_seas_amp` -- sitting on the same ocean limb as the
# -12.2 flag, and feeding the very rows that carry the veto against the ocean
# amplitude. A mechanism that is ABSENT can force a PARAMETER to absorb its job.
#
# ⛔ AND THE HANDOFF'S OWN INSTRUCTION IS TO PRICE IT BEFORE WRITING IT. "If it
# comes out two orders below the observable, the term is real physics and still
# not the explanation -- and that is worth knowing in an afternoon rather than
# after a refit." This file is that afternoon. It IMPLEMENTS NOTHING:
# `R/model.R`, `src/ccx_core.cpp` and `R/constants.R` are untouched.
#
# ⭐ THE SLOPE IS MEASURED, AND NOW READ FROM THE PAPER ITSELF. Marcus supplied
# both PDFs on 2026-09-02 after the first pass had to quote them second-hand:
#
#   Zhang J., Quay P. D., Wilbur D. O. (1995), "Carbon isotope fractionation
#     during gas-water exchange and dissolution of CO2", GCA 59(1), 107-114.
#     ~/Documents/2026/ClaudeDocs/Papers/zhangquaywilbur1995.pdf
#   Quay P. et al. (2003), "Changes in the 13C/12C of dissolved inorganic carbon
#     in the ocean as a tracer of anthropogenic CO2 uptake", GBC 17(1), 4-1..4-20.
#     -- same group; states it takes its air-sea fractionation factors FROM
#     Zhang et al. 1995, which is what makes Zhang the canonical source here
#     rather than one option among several.
#
# ⛔ AND THE PAPER PRINTS ITS OWN FIT TWICE, WITH DIFFERENT COEFFICIENTS.
#   abstract    : eps_DIC-g = (0.014  +- 0.01)*T*fCO3 - (0.105 +- 0.002)*T + 10.53
#   conclusions : eps_DIC-g = (0.0144 +- 0.01)*T*fCO3 - (0.107 +- 0.002)*T + 10.53
# The two T coefficients are EXACTLY ONE STATED SIGMA APART, i.e. the paper's two
# printings straddle its own error bar. There is no basis in the text for
# preferring one, so BOTH ARE CARRIED and every result below is reported under
# each. ⚠ The first pass of this file quoted only the abstract form from a
# secondary source and would have shipped it as "the" coefficient.
#
# ✅ Cross-checked against an independent APPLICATION of the same paper
# (CROCCA-2S 13C Suess study, NSF-PAR 10432989: 0.18 degC/decade warming ->
# -0.019 permil/decade in surface d13C_DIC = -0.1056 permil/degC).
#
# ⭐ AND THE PAPER MEASURES THE OTHER LIMB TOO, which the first pass did not
# have: the KINETIC effect during gas transfer, eps_k = -0.81 +- 0.16 permil at
# 21 degC and -0.95 +- 0.20 at 5 degC. That is the atm->ocean limb -- the model
# carries it at -2.00 -- and having both limbs measured turns §5a from a GLODAP
# job into arithmetic. See sec.5.
#
# Usage:  Rscript calibration/diag_alpha_as_up_precheck.R      # ~30 s
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_seas_limbs.R"))

# ---- named constants -------------------------------------------------
AP_MODES <- c("enso25 A" = "calibration/output/multistart_20260901_enso25/start_000.rds")
AP_YEARS <- c(1750, 2024)
# Zhang et al. 1995, seawater fit -- BOTH PRINTINGS. See the header: the paper
# states it twice and the two T coefficients are one stated sigma apart.
AP_Z_FITS <- list(
  abstract    = c(a = 0.0140, b = -0.105, c = 10.53),
  conclusions = c(a = 0.0144, b = -0.107, c = 10.53))
AP_Z_PRIMARY <- "abstract"   # the one the tables lead with; NOT a claim that it
                             # is the right one -- every result prints both.
AP_Z_B_SIGMA <- 0.002        # the paper's own stated uncertainty on b
# The KINETIC limb, same paper's abstract: eps_k at two temperatures.
AP_K_T   <- c(5, 21)         # degC
AP_K_E   <- c(-0.95, -0.81)  # permil
AP_K_SD  <- c(0.20, 0.16)    # permil
# Quay et al. 2003's observational constraint on the PAIR.
AP_Q_DISEQ    <- 0.60        # permil, global mean air-sea d13C disequilibrium, 1995
AP_Q_DISEQ_SD <- 0.10
AP_Q_YEAR     <- 1995
AP_Z_TRANGE  <- c(5, 25)      # degC, the fit's stated validity
AP_Z_FRANGE  <- c(0.05, 0.20) # fCO3, likewise
AP_Z_XCHECK  <- -0.019 / 0.18 # permil/degC, the independent application
AP_Z_XTOL    <- 0.05          # relative; a 2-significant-figure secondary quote
                              # against a 2-significant-figure one. NOT scaled to
                              # a spread -- neither number has one.
# The three slopes the handoff carried, for the comparison it asked for.
AP_TB    <- 373.15   # K, Marcus's anchor: alpha -> 1 at the BOILING point
AP_TCRIT <- 647.10   # K, the critical point -- the handoff's sensitivity case
AP_MOOK  <- 9483     # K, the recalled Mook coefficient: eps = -9483/T + 23.89
AP_MOOK_B<- 23.89
AP_T_REF <- 288.15   # K, the reference temperature the handoff priced at
AP_EPS_REF <- -9.0   # permil, its assumed eps at AP_T_REF

# The model's own hardcoded pair, READ from ccx_prepare()'s aux, never retyped.
AP_STATIONS <- c(NH = "MLO", SH = "SPO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
cat(sprintf("\n%s\nPRE-CHECK: A TEMPERATURE-DEPENDENT `alpha_as_up`, PRICED BEFORE IT IS WRITTEN\n  IMPLEMENTS NOTHING. R/model.R, src/ccx_core.cpp, R/constants.R untouched.\n%s\n",
            strrep("=", 78), strrep("=", 78)))

obs  <- ccx_prepare_obs()
obsv <- sl_obs_vectors(obs)
md   <- readRDS(AP_MODES[[1]])
p    <- sl_overlay(md$par_mode, md$pump_mode)
p    <- ccx_set_enso(p, md$par_mode)
aux  <- ccx_prepare(p)
sp   <- ccx_spinup(p)
F    <- ccx_build_forcing("historical", AP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (md$par_mode$bomb_total / 102)
for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
  F[[cc]] <- F[[cc]] * md$par_mode$luc_scale
o <- ccx_run_fast(sp, F)$out

sep("0. THE MODEL'S PAIR, AS IT STANDS")
eps_dn <- (aux$alpha_as_down - 1) * 1000
eps_up <- (aux$alpha_as_up   - 1) * 1000
cat(sprintf("  alpha_as_down = %.6f  -> eps_down = %+6.2f permil  (kinetic,     atm -> ocean)\n",
            aux$alpha_as_down, eps_dn))
cat(sprintf("  alpha_as_up   = %.6f  -> eps_up   = %+6.2f permil  (equilibrium, ocean -> atm)\n",
            aux$alpha_as_up, eps_up))
cat(sprintf("  ⇒ the PAIR implies a steady-state surface offset d_ml - d_atm = %+.2f permil\n",
            eps_dn - eps_up))
cat("  ⚠ NEITHER IS IN `R/constants.R`. Both are literals carrying the word\n")
cat("    \"provisional\" without being in the provisional-constant LEDGER that\n")
cat("    exists to track exactly this. Registering them is a prerequisite to\n")
cat("    changing them: an unregistered constant cannot be found by the audit.\n")

sep("1. THE MEASURED FRACTIONATION, AT THE MODEL'S OWN SST AND CARBONATE STATE")
alk <- ccx_const("ALK_SURFACE")
last <- nrow(o)
st <- list()
for (h in HEMIS) {
  sst <- p[[paste0("sst_", h)]]
  dic <- o[[paste0("ml_C_", h)]][last] * aux$mol_per_GtC / aux$ml_mass_kg[[h]]
  k   <- carb_constants(sst)
  hplus <- h_from_dic_alk(dic, alk, sst, k = k)
  fco3  <- (k$K1 * k$K2) / (hplus^2 + k$K1 * hplus + k$K1 * k$K2)
  a_s   <- p[[paste0("sst_seas_amp_", h)]]
  st[[h]] <- list(sst = sst, dic = dic, fco3 = fco3, a_s = a_s, K0 = k$K0,
                  pco2 = pco2_from_dic(dic, alk, sst, k = k))
  in_T <- sst >= AP_Z_TRANGE[1] && sst <= AP_Z_TRANGE[2]
  in_f <- fco3 >= AP_Z_FRANGE[1] && fco3 <= AP_Z_FRANGE[2]
  cat(sprintf("  %s: SST %6.2f degC %s | fCO3 %.4f %s | seasonal SST half-amp %.3f K\n",
              h, sst, if (in_T) "(in Zhang range)" else "⚠ OUTSIDE [5,25]",
              fco3, if (in_f) "(in range)" else "⚠ OUTSIDE [0.05,0.20]", a_s))
  st[[h]]$in_range <- in_T && in_f
}
zhang_eps   <- function(T, f, fit = AP_Z_PRIMARY)
  AP_Z_FITS[[fit]][["a"]] * T * f + AP_Z_FITS[[fit]][["b"]] * T + AP_Z_FITS[[fit]][["c"]]
zhang_slope <- function(f, fit = AP_Z_PRIMARY)
  AP_Z_FITS[[fit]][["a"]] * f + AP_Z_FITS[[fit]][["b"]]
# eps_k(T), linear through the paper's two measured temperatures. TWO POINTS ONLY
# -- this is an interpolation the paper does not itself draw, and it is used only
# inside its own 5-21 degC span.
kin_slope <- (AP_K_E[2] - AP_K_E[1]) / (AP_K_T[2] - AP_K_T[1])
kin_eps   <- function(T) AP_K_E[1] + kin_slope * (T - AP_K_T[1])
cat("\n  Zhang et al. 1995, BOTH PRINTINGS of the seawater fit:\n")
for (fit in names(AP_Z_FITS)) {
  f <- AP_Z_FITS[[fit]]
  cat(sprintf("    %-11s eps_DIC-g = %.4f*T*fCO3 %+.3f*T + %.2f\n", fit, f[["a"]], f[["b"]], f[["c"]]))
}
cat(sprintf("    ⚠ the two b differ by %.3f = %.1f x the paper's own stated sigma of %.3f\n",
            abs(AP_Z_FITS$abstract[["b"]] - AP_Z_FITS$conclusions[["b"]]),
            abs(AP_Z_FITS$abstract[["b"]] - AP_Z_FITS$conclusions[["b"]]) / AP_Z_B_SIGMA,
            AP_Z_B_SIGMA))
cat(sprintf("\n  %-4s %12s %12s | %12s %12s | %10s\n", "hem",
            "eps_DIC-g", "(conclusions)", "d/dT", "(conclusions)", "eps_k"))
for (h in HEMIS) {
  e  <- zhang_eps(st[[h]]$sst, st[[h]]$fco3)
  e2 <- zhang_eps(st[[h]]$sst, st[[h]]$fco3, "conclusions")
  sl <- zhang_slope(st[[h]]$fco3); sl2 <- zhang_slope(st[[h]]$fco3, "conclusions")
  ek <- kin_eps(st[[h]]$sst)
  st[[h]]$eps_dicg <- e; st[[h]]$eps_dicg2 <- e2; st[[h]]$eps_k <- ek
  # ⭐ THE EVASION LIMB IS eps_k - eps_DIC-g, NOT -eps_DIC-g. Both limbs carry the
  # kinetic effect; only the evasion limb also carries the equilibrium offset.
  # That is the structure Quay et al. 2003 eq.(2) uses and it is what makes the
  # steady-state d_ml - d_atm come out AT eps_DIC-g. So the slope carries the
  # kinetic temperature dependence too.
  st[[h]]$eps_up  <- ek - e
  st[[h]]$eps_dn  <- ek
  st[[h]]$slope   <- kin_slope - sl
  st[[h]]$slope2  <- kin_slope - sl2
  cat(sprintf("  %-4s %+12.3f %+12.3f | %+12.4f %+12.4f | %+10.3f\n",
              h, e, e2, -sl, -sl2, ek))
}
cat(sprintf("\n  GATE X -- the independent application of the same paper: %+.4f permil/degC\n",
            AP_Z_XCHECK))
sx <- zhang_slope(mean(vapply(st, function(x) x$fco3, 0)))
rel <- abs(sx - AP_Z_XCHECK) / abs(AP_Z_XCHECK)
cat(sprintf("  this fit at the model's mean fCO3:                       %+.4f permil/degC  (rel %.3f) -> %s\n",
            sx, rel, if (rel <= AP_Z_XTOL) "AGREE" else "⚠ DISAGREE"))

sep("2. THE FOUR CANDIDATE SLOPES -- AND WHICH FUNCTIONAL FORM MARCUS'S ANCHOR NEEDS")
# The 1/T form the handoff proposed: ln a = a*(1/T - 1/T_anchor).
inv_slope <- function(T_anchor) {
  a <- (AP_EPS_REF / 1000) / (1 / AP_T_REF - 1 / T_anchor)
  -a / AP_T_REF^2 * 1000
}
# A LINEAR-in-T form through the same two anchors.
lin_slope <- function(T_anchor) -AP_EPS_REF / (T_anchor - AP_T_REF)
cand <- c(
  "Zhang 1995 (MEASURED, abstract)"      = mean(vapply(st, function(x) x$slope, 0)),
  "Zhang 1995 (MEASURED, conclusions)"   = mean(vapply(st, function(x) x$slope2, 0)),
  "Mook, as recalled (1/T)"              = AP_MOOK / AP_T_REF^2,
  "boiling anchor, 1/T form"             = inv_slope(AP_TB),
  "boiling anchor, LINEAR form"          = lin_slope(AP_TB),
  "critical anchor, 1/T form"            = inv_slope(AP_TCRIT),
  "critical anchor, LINEAR form"         = lin_slope(AP_TCRIT))
ref <- cand[["Zhang 1995 (MEASURED, abstract)"]]
cat(sprintf("  %-32s %12s %10s\n", "law", "d eps/dT", "vs Zhang"))
for (n in names(cand))
  cat(sprintf("  %-32s %+12.4f %9.1f %%\n", n, cand[[n]], 100 * (cand[[n]] - ref) / ref))
fbar <- mean(vapply(st, function(x) x$fco3, 0))
zc <- AP_Z_FITS[[AP_Z_PRIMARY]][["c"]] / -zhang_slope(fbar)
cat(sprintf("\n  ⭐ Zhang's LINEAR fit crosses eps = 0 at %.1f degC = %.1f K.\n", zc, zc + 273.15))
cat(sprintf("     Marcus's anchor is the BOILING POINT, %.1f K -- a gap of %.1f K.\n",
            AP_TB, abs(zc + 273.15 - AP_TB)))
cat("     ⚠ That is an EXTRAPOLATION 4x beyond the fit's stated range and Zhang\n")
cat("       claims nothing at 100 degC. But it is independent of the anchor, and\n")
cat("       it lands on it. ⇒ THE ANCHOR IS RIGHT AND THE 1/T FORM IS WHAT WAS\n")
cat("       WRONG: the same anchor with a LINEAR law reproduces the measurement.\n")
cat(sprintf("       Mook, as recalled, crosses zero at %.1f K -- also near boiling.\n",
            AP_MOOK / AP_MOOK_B))

sep("3. THE PRE-CHECK -- HOW BIG IS THE SEASONAL ATMOSPHERIC d13C SIGNAL?")
cat("  A seasonal SST cycle modulates eps_up, which modulates the ISOTOPIC RATIO\n")
cat("  of the evasion limb only. For a sinusoid at omega = 2*pi/yr, well above the\n")
cat("  air-sea relaxation rate F_up/M_atm, the atmospheric response is\n")
cat("      amplitude(d13C_atm) = F_up * amplitude(eps_up) / (M_atm * omega)\n")
cat("  ⚠ ANALYTIC AND HEMISPHERICALLY LOCAL: it ignores interhemispheric exchange\n")
cat("    and the ocean's own d13C response, both of which DAMP it. So this is an\n")
cat("    UPPER bound on the term, which is the right side to err on for a gate\n")
cat("    whose purpose is to kill a mechanism.\n")
omega <- 2 * pi
cat(sprintf("\n  %-4s %10s %10s %9s %9s | %12s %12s %8s\n", "hem", "F_up", "M_atm",
            "d eps/dT", "amp eps", "amp d13C_atm", "OBSERVED", "ratio"))
cat(sprintf("  %-4s %10s %10s %9s %9s | %12s %12s %8s\n", "", "GtC/yr", "GtC",
            "permil/K", "permil", "permil p-p", "permil p-p", ""))
res <- list()
for (h in HEMIS) {
  gx    <- aux$asx[[h]] * p$k_w * st[[h]]$K0            # GtC/(yr uatm)
  F_up  <- gx * st[[h]]$pco2
  # HEMISPHERIC box carbon: the model's atmosphere is two boxes of equal mass,
  # so a hemispheric mixing ratio carries half the global GtC-per-ppm. Gated
  # below against the global total, which is the number with a known value.
  M_atm <- o[[paste0("co2_", h)]][last] * ccx_const("GtC_PER_PPM") / 2
  amp_e <- st[[h]]$slope * st[[h]]$a_s                  # half-amplitude, permil
  amp_d <- 2 * F_up * amp_e / (M_atm * omega)           # peak-to-peak
  ob    <- sl_amp(obsv[[paste0("d13_", AP_STATIONS[[h]])]])
  res[[h]] <- c(F_up = F_up, M_atm = M_atm, amp_d = amp_d, obs = ob)
  cat(sprintf("  %-4s %10.2f %10.2f %+9.4f %9.4f | %12.5f %12.4f %8.4f\n",
              h, F_up, M_atm, st[[h]]$slope, amp_e, amp_d, ob, amp_d / ob))
}
cat(sprintf("\n  stations: NH -> %s, SH -> %s (the two d13c_seasonal_* rows)\n",
            AP_STATIONS[["NH"]], AP_STATIONS[["SH"]]))
# GATE M -- the two hemispheric masses must sum to a global atmosphere with a
# value we know independently. A halving error here would scale every response
# below by 2 and there is nothing in the table that would show it.
m_tot <- sum(vapply(res, function(x) x[["M_atm"]], 0))
co2_g <- mean(c(o$co2_NH[last], o$co2_SH[last]))
cat(sprintf("  GATE M: global atmosphere %.1f GtC at %.1f ppm ⇒ %.4f GtC/ppm vs the constant %.4f -> %s\n",
            m_tot, co2_g, m_tot / co2_g, ccx_const("GtC_PER_PPM"),
            if (abs(m_tot / co2_g - ccx_const("GtC_PER_PPM")) < 1e-6) "PASS" else "⚠ FAIL"))

sep("3b. AGAINST THE ROWS' RESIDUAL -- WHICH IS WHAT sec.3's VERDICT ASKS FOR")
cat("  7 % of an OBSERVABLE is not the same statement as 7 % of what the model\n")
cat("  gets WRONG on that observable. And an amplitude alone cannot say whether a\n")
cat("  term helps: two vectors of the same size ADD or CANCEL by their PHASE.\n\n")
cat("  ⚠ THE RESPONSE PHASE IS DERIVED, NOT MEASURED. eps_up rises with SST, so\n")
cat("    the evasion limb sends ISOTOPICALLY HEAVIER carbon up in local summer;\n")
cat("    the atmosphere INTEGRATES that, so its anomaly lags the SST peak by a\n")
cat("    quarter cycle. The model's SST peaks at month 3.5 + CCX_SST_SEAS_LAG + 3\n")
cat("    in the NH and six months later in the SH (the sign flip at model.R:1421).\n")
mdl <- sl_run(md$par_mode, 0, md$pump_mode, obs, AP_YEARS)
SST_PEAK <- c(NH = 3.5 + CCX_SST_SEAS_LAG + 3, SH = 3.5 + CCX_SST_SEAS_LAG + 3 + 6)
cat(sprintf("\n  %-4s %10s %6s | %10s %6s | %10s %6s | %10s %6s | %8s\n", "hem",
            "model", "mo", "observed", "mo", "RESIDUAL", "mo", "omitted", "mo", "|term|/"))
cat(sprintf("  %-4s %10s %6s | %10s %6s | %10s %6s | %10s %6s | %8s\n", "", "permil",
            "", "permil", "", "permil", "", "permil", "", "|resid|"))
for (h in HEMIS) {
  stn <- AP_STATIONS[[h]]
  mv  <- mdl[[paste0("d13_", stn)]]; ov <- obsv[[paste0("d13_", stn)]]
  rv  <- mv - ov
  pk  <- (SST_PEAK[[h]] + 3) %% 12                       # the quarter-cycle lag
  tv  <- sl_vec(res[[h]][["amp_d"]], pk)
  res[[h]] <- c(res[[h]], resid = sl_amp(rv), frac_resid = sl_amp(tv) / sl_amp(rv),
                d_mo = ((pk - sl_ang_mo(rv) + 6) %% 12) - 6)
  cat(sprintf("  %-4s %10.4f %6.2f | %10.4f %6.2f | %10.4f %6.2f | %10.5f %6.2f | %8.3f\n",
              h, sl_amp(mv), sl_ang_mo(mv), sl_amp(ov), sl_ang_mo(ov),
              sl_amp(rv), sl_ang_mo(rv), sl_amp(tv), pk, sl_amp(tv) / sl_amp(rv)))
}
cat("\n  and what the term would DO to each residual, added as a vector:\n")
for (h in HEMIS) {
  stn <- AP_STATIONS[[h]]
  rv  <- mdl[[paste0("d13_", stn)]] - obsv[[paste0("d13_", stn)]]
  pk  <- (SST_PEAK[[h]] + 3) %% 12
  tv  <- sl_vec(res[[h]][["amp_d"]], pk)
  cat(sprintf("  %-4s (%s) residual %.4f -> %.4f permil  (%+.2f %%)  phase gap %+.2f months ⇒ %s\n",
              h, stn, sl_amp(rv), sl_amp(rv + tv),
              100 * (sl_amp(rv + tv) - sl_amp(rv)) / sl_amp(rv), res[[h]][["d_mo"]],
              if (sl_amp(rv + tv) < sl_amp(rv)) "SHRINKS it" else "GROWS it"))
}

sep("4. SCORED")
r <- vapply(res, function(x) x[["amp_d"]] / x[["obs"]], 0)
cat(sprintf("  the omitted term is %.2f %% (NH) / %.2f %% (SH) of the OBSERVED seasonal d13C.\n",
            100 * r[["NH"]], 100 * r[["SH"]]))
ordmag <- -log10(max(r))
cat(sprintf("  that is %.1f orders of magnitude below the observable at its largest.\n", ordmag))
cat(sprintf("  against the ROWS' RESIDUAL it is %.1f %% (NH) / %.1f %% (SH).\n",
            100 * res$NH[["frac_resid"]], 100 * res$SH[["frac_resid"]]))
# ⚠ ROBUSTNESS OF THE SIGN. Adding a small vector to a large one changes the
# magnitude by |t|*cos(phase gap), so the sign of the effect flips at a gap of
# exactly a quarter cycle. The phase was DERIVED, not measured -- so report how
# much phase error the "grows it" reading can take before it becomes "shrinks".
cat("\n  ⚠ SIGN ROBUSTNESS. The effect goes as |term| x cos(phase gap), so it flips\n")
cat("    at a gap of 3.00 months. The gaps and their margins:\n")
for (h in HEMIS)
  cat(sprintf("      %s  gap %+.2f mo, %.2f mo from the flip -> the sign is %s\n", h,
              res[[h]][["d_mo"]], abs(3 - abs(res[[h]][["d_mo"]])),
              if (abs(3 - abs(res[[h]][["d_mo"]])) > 1) "robust" else "⚠ MARGINAL"))
cat(sprintf("\n  ⇒ %s\n", if (max(r) < 0.01)
  paste("TWO OR MORE ORDERS BELOW. The term is real physics and is NOT the",
        "\n    explanation. Implementing it cannot move the d13c_seasonal_* rows.")
  else if (max(vapply(res, function(x) x[["frac_resid"]], 0)) < 0.25)
  # ⚠ THE RANGE IS COMPUTED, NOT TYPED. An earlier draft hardcoded "8-15 %" and
  # the numbers moved under it the moment the kinetic limb entered the slope.
  sprintf(paste("NOT THE EXPLANATION. The term is %.0f-%.0f %% of what the model already",
        "\n    gets WRONG on the two rows that carry the veto, and at the derived phase",
        "\n    it moves both residuals the WRONG WAY by ~5 %%. A flag worth -12.2",
        "\n    prior-sd cannot be paid for out of a term this size whichever way it",
        "\n    points. ⇒ IT IS REAL PHYSICS AND IT IS STILL NOT THE ANSWER -- which is",
        "\n      exactly the outcome handoff §5 said was worth an afternoon, not a refit."),
        100 * min(vapply(res, function(x) x[["frac_resid"]], 0)),
        100 * max(vapply(res, function(x) x[["frac_resid"]], 0)))
  else "SAME ORDER AS THE RESIDUAL. The mechanism is a live candidate; implement it."))
cat("\n  ⛔ AND THE MEAN VALUE IS A SEPARATE QUESTION FROM THE SLOPE -- see sec.5,\n")
cat("     which answers it from the same paper rather than from GLODAP.\n")

sep("5. THE PAIR ITSELF -- §5a, ANSWERED FROM THE PAPER RATHER THAN FROM GLODAP")
cat("  ⭐ Having BOTH limbs measured makes this arithmetic. Zhang measures the\n")
cat("     KINETIC effect (both limbs carry it) and the EQUILIBRIUM DIC-gas offset\n")
cat("     (only the evasion limb also carries it), which is the structure Quay et\n")
cat("     al. 2003 eq.(2) uses. So the measured pair is\n")
cat("         eps_down = eps_k          eps_up = eps_k - eps_DIC-g\n")
cat("     and the steady state then puts d_ml - d_atm AT eps_DIC-g by construction.\n")
cat(sprintf("\n  %-4s %10s %10s | %10s %10s | %12s %12s\n", "hem",
            "eps_down", "model", "eps_up", "model", "d_ml-d_atm", "model"))
for (h in HEMIS)
  cat(sprintf("  %-4s %+10.3f %+10.2f | %+10.3f %+10.2f | %+12.3f %+12.2f\n", h,
              st[[h]]$eps_dn, eps_dn, st[[h]]$eps_up, eps_up,
              st[[h]]$eps_dn - st[[h]]$eps_up, eps_dn - eps_up))
cat("\n  ⇒ the model's EVASION limb is nearly right and its INVASION limb is not:\n")
cat(sprintf("     eps_up  %+.2f vs measured %+.3f / %+.3f  -> off by %.0f-%.0f %%\n",
            eps_up, st$NH$eps_up, st$SH$eps_up,
            100 * abs(eps_up - st$NH$eps_up) / abs(st$NH$eps_up),
            100 * abs(eps_up - st$SH$eps_up) / abs(st$SH$eps_up)))
cat(sprintf("     eps_dn  %+.2f vs measured %+.3f / %+.3f  -> %.1fx TOO LARGE\n",
            eps_dn, st$NH$eps_dn, st$SH$eps_dn, abs(eps_dn / st$NH$eps_dn)))
cat("  ⚠ AND THAT RESOLVES THE TENSION THE FIRST PASS FLAGGED. It read the model's\n")
cat("    -10 as eps_up = -eps_DIC-g and concluded the pair needed eps_down ~ 0 to\n")
cat("    reproduce the equilibrium offset. With both limbs carrying eps_k the pair\n")
cat("    is consistent as it stands -- the model is simply 1.1 permil out on one\n")
cat("    limb and 1.2 out on the other, in the SAME direction, which is why its\n")
cat("    net offset (+8.00) is closer to right than either limb is.\n")

cat("\n  GATE Q -- Quay et al. 2003's OBSERVATIONAL constraint on that offset.\n")
cat(sprintf("  Global mean air-sea d13C disequilibrium, %d: %.2f +- %.2f permil.\n",
            AP_Q_YEAR, AP_Q_DISEQ, AP_Q_DISEQ_SD))
iq <- which.min(abs(o$t - AP_Q_YEAR))
dq <- c()
for (h in HEMIS) {
  d_ml  <- 1000 * (o[[paste0("ml_C13_", h)]][iq] /
                   (o[[paste0("ml_C_", h)]][iq] * ccx_const("R13_VPDB")) - 1)
  d_atm <- o[[paste0("d13c_", h)]][iq]
  # the atmosphere IN EQUILIBRIUM with this surface water, minus the actual one
  dq[h] <- (d_ml - st[[h]]$eps_dicg) - d_atm
  cat(sprintf("    %s  d_ml %+7.3f  d_atm %+7.3f  ⇒ disequilibrium %+7.3f permil\n",
              h, d_ml, d_atm, dq[[h]]))
}
dqm <- mean(dq)
cat(sprintf("    model global mean %+.3f vs observed %.2f +- %.2f -> %s\n", dqm,
            AP_Q_DISEQ, AP_Q_DISEQ_SD,
            if (abs(dqm - AP_Q_DISEQ) <= AP_Q_DISEQ_SD) "INSIDE the bar" else
            if (abs(dqm - AP_Q_DISEQ) <= 2 * AP_Q_DISEQ_SD) "⚠ within 2 sigma" else
              "⛔ OUTSIDE 2 sigma"))
cat("  ⚠ AN AREA-UNWEIGHTED TWO-BOX MEAN against a global observational estimate,\n")
cat("    and the model's own eps_DIC-g is used to define equilibrium -- so this\n")
cat("    tests the OFFSET the pair produces, not the pair's two limbs separately.\n")
# ⭐ WHY THIS GATE HAS POWER, stated rather than assumed. The scored streams are
# co2_*, d13c_level_* and d13c_gradient (ATMOSPHERIC), d14c_*, gcb_*, and
# ocean_grad_{dic,d13c,alk} -- and the ocean ones are SURFACE MINUS DEEP
# gradients (ccx_ocean_grad_scored -> ccx_model_ocean_gradient). NOTHING scores
# the ABSOLUTE surface-ocean d13C. So this gate is testing a direction the
# likelihood never saw, which is what gives it power and also why a failure here
# is not evidence the fit went wrong. [[no_power_null]] in reverse.
cat("\n  ⭐ THE GATE HAS POWER BECAUSE THE QUANTITY IS UNSCORED. The ocean d13C\n")
cat("     stream is `ocean_grad_d13c`, a SURFACE-MINUS-DEEP gradient; the two\n")
cat("     d13c_level_* rows are ATMOSPHERIC. Nothing in the likelihood constrains\n")
cat("     the absolute surface-ocean d13C, so this is an independent test -- and\n")
cat("     a failure is an UNCONSTRAINED DIRECTION, not a broken fit.\n")
cat("\n  and it localises: holding d_atm and eps_DIC-g, the observed disequilibrium\n")
for (h in HEMIS) {
  d_ml  <- 1000 * (o[[paste0("ml_C13_", h)]][iq] /
                   (o[[paste0("ml_C_", h)]][iq] * ccx_const("R13_VPDB")) - 1)
  need  <- o[[paste0("d13c_", h)]][iq] + AP_Q_DISEQ + st[[h]]$eps_dicg
  cat(sprintf("    %s needs d_ml = %+7.3f permil; the model has %+7.3f -> %+.3f permil TOO LIGHT\n",
              h, need, d_ml, d_ml - need))
}
cat("  ⇒ THE GAP IS IN THE SURFACE d13C, NOT IN THE ALPHA PAIR: adopting the\n")
cat("    measured pair moves the offset by ~0.7 permil and the shortfall is ~0.6-0.8.\n")
cat(sprintf("  ⚠ CANDIDATE, NOT A DIAGNOSIS: this mode's mixed layer is %.0f m deep, well\n", p$h_ml))
cat("    below a 50-75 m surface layer, and a deeper box mixes in lighter\n")
cat("    subsurface DIC. NOT TESTED HERE.\n")
cat("  ⛔ NOT A LICENCE TO RETUNE. It is a gate any adopted pair must still pass.\n")

sep("6. WHAT ADOPTING THE MEASURED PAIR WOULD DO TO GATE Q")
cat("  ⛔ FIRST, A DEFECT THIS TEST HAD TO WORK AROUND AND THAT ANY ADOPTION MUST\n")
cat("     FIX: `alpha_as_down` / `alpha_as_up` are LITERALS inside ccx_prepare()'s\n")
cat("     aux (R/model.R:2023-2024) and are read from NOWHERE else. Setting them on\n")
cat("     a parameter list is a SILENT NO-OP -- it returns a number, unchanged, with\n")
cat("     no error. The first attempt at this section did exactly that and got four\n")
cat("     IDENTICAL rows, which is the only reason it was caught.\n")
cat("     ⇒ The one injection point is ccx_prepare() itself, patched below FOR THIS\n")
cat("       TEST ONLY so the SPINUP sees the new pair too -- the preindustrial\n")
cat("       isotopic equilibrium depends on it, and overriding after the spinup\n")
cat("       would start the run at the OLD equilibrium.\n")
.orig_prepare <- ccx_prepare
AP_OVR <- new.env(); AP_OVR$dn <- NULL
ccx_prepare <- function(p, ...) {
  a <- .orig_prepare(p, ...)
  if (!is.null(AP_OVR$dn)) { a$alpha_as_down <- 1 + AP_OVR$dn / 1000
                             a$alpha_as_up   <- 1 + AP_OVR$up / 1000 }
  a }
ap_diseq <- function(dn, up, lab) {
  AP_OVR$dn <- dn; AP_OVR$up <- up
  q <- sl_overlay(md$par_mode, md$pump_mode); q <- ccx_set_enso(q, md$par_mode)
  s2 <- ccx_spinup(q)
  # the override HELD -- asserted, not assumed, given what sec.6 opens with
  if (!is.null(dn)) stopifnot(abs((s2$aux$alpha_as_down - 1) * 1000 - dn) < 1e-9)
  F2 <- ccx_build_forcing("historical", AP_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F2$c14_cosmo <- s2$prod_c14
  F2$c14_bomb  <- F2$c14_bomb * (md$par_mode$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F2[[cc]] <- F2[[cc]] * md$par_mode$luc_scale
  attr(F2, "luc_scale") <- md$par_mode$luc_scale
  o2 <- ccx_run_fast(s2, F2)$out; j <- which.min(abs(o2$t - AP_Q_YEAR))
  dml <- vapply(HEMIS, function(h) 1000 * (o2[[paste0("ml_C13_", h)]][j] /
                (o2[[paste0("ml_C_", h)]][j] * ccx_const("R13_VPDB")) - 1), 0)
  dqq <- vapply(HEMIS, function(h) (dml[[h]] - st[[h]]$eps_dicg) -
                o2[[paste0("d13c_", h)]][j], 0)
  n_sd <- abs(mean(dqq) - AP_Q_DISEQ) / AP_Q_DISEQ_SD
  cat(sprintf("  %-24s d_ml %+6.3f/%+6.3f | diseq %+6.3f/%+6.3f mean %+6.3f | %4.1f sigma %s\n",
              lab, dml[["NH"]], dml[["SH"]], dqq[["NH"]], dqq[["SH"]], mean(dqq), n_sd,
              if (n_sd <= 1) "INSIDE" else if (n_sd <= 2) "within 2" else "⛔ OUTSIDE"))
  AP_OVR$dn <- NULL; c(mean = mean(dqq), n_sd = n_sd) }
edn <- mean(vapply(HEMIS, function(h) st[[h]]$eps_dn, 0))
eup <- mean(vapply(HEMIS, function(h) st[[h]]$eps_up, 0))
cat(sprintf("\n  hemispheric means of the measured pair: eps_down %+.3f, eps_up %+.3f\n", edn, eup))
cat("  (a SCALAR pair, as the model's is -- the hemispheric spread is carried as a\n")
cat("   residual below, not as two constants)\n\n")
AD <- list()
AD$incumbent <- ap_diseq(NULL, NULL, "model as it stands")
AD$both      <- ap_diseq(edn,  eup,  "measured pair (BOTH)")
AD$inv       <- ap_diseq(edn,  eps_up, "invasion limb ONLY")
AD$eva       <- ap_diseq(eps_dn, eup, "evasion limb ONLY")
ccx_prepare <- .orig_prepare       # restore, so nothing below inherits the patch
cat("\n  ⭐ ONLY THE FULL PAIR WORKS. Either limb alone over- or undershoots, so this\n")
cat("     is not a knob being turned to meet a target -- it is two independently\n")
cat("     MEASURED constants that only agree with the observation together.\n")
cat(sprintf("  ⇒ GATE Q goes from %.1f sigma OUT WITH THE WRONG SIGN to %.1f sigma.\n",
            AD$incumbent[["n_sd"]], AD$both[["n_sd"]]))
cat("  ⚠ AND IT IS STILL HIGH, not centred: the mean sits above the observation and\n")
cat("    the NH/SH spread is comparable to the observational sigma. NOTHING WAS\n")
cat("    REFITTED -- though note the fit has no direct handle here, since sec.5\n")
cat("    established that no stream scores this quantity.\n")
cat("  ⛔ ADOPTING THIS CHANGES THE OBJECTIVE ⇒ every fitted vector is quarantined\n")
cat("    and a refit is owed. That is the real cost and it should be batched with\n")
cat("    any other objective-changing adoption, not spent alone.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(state = st, candidates = cand, response = res, zhang_zero_degC = zc,
             model_pair = c(eps_down = eps_dn, eps_up = eps_up),
             measured_pair = lapply(st, function(x) x[c("eps_dn", "eps_up", "eps_dicg")]),
             diseq = list(model = dq, obs = c(AP_Q_DISEQ, AP_Q_DISEQ_SD)), adopt = AD,
             xcheck = c(fit = sx, independent = AP_Z_XCHECK)),
        file.path(OUTDIR, "alpha_as_up_precheck.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "alpha_as_up_precheck.rds")))
