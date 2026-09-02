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
# ⭐ THE SLOPE IS NOT AN ANCHOR-DERIVED GUESS ANY MORE -- IT IS MEASURED.
# Marcus (2026-09-02) pointed at Broecker & Maier-Reimer 1992 or Mook. Neither
# is on disk and AGU refused the fetch; what the search returned instead is the
# LABORATORY measurement both of those rest on:
#
#   Zhang J., Quay P. D., Wilbur D. O. (1995), "Carbon isotope fractionation
#   during gas-water exchange and dissolution of CO2", Geochimica et
#   Cosmochimica Acta 59(1), 107-114.
#
# whose seawater fit is eps_DIC-g = 0.014*T*fCO3 - 0.105*T + 10.53 permil,
# stated for 5 < T < 25 degC and 0.05 < fCO3 < 0.20.
# ⚠ QUOTED FROM SECONDARY SOURCES, NOT FROM THE PAPER -- the PDF is not on disk.
# It is CROSS-CHECKED against an independent application of the same paper
# (Wynn-Edwards / CROCCA-2S 13C Suess-effect study, NSF-PAR 10432989): "an
# average decadal sea surface warming of 0.18 degC per decade ... is expected to
# yield a decrease in surface ocean d13C_DIC of -0.019 permil per decade", i.e.
# a slope of -0.1056 permil/degC. The two agree to 2 %.
# ⛔ GET THE PDF BEFORE ANY OF THIS IS IMPLEMENTED. A cross-checked secondary
# quote is enough to PRICE a mechanism; it is not enough to SHIP a constant.
#
# Usage:  Rscript calibration/diag_alpha_as_up_precheck.R      # ~30 s
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_seas_limbs.R"))

# ---- named constants -------------------------------------------------
AP_MODES <- c("enso25 A" = "calibration/output/multistart_20260901_enso25/start_000.rds")
AP_YEARS <- c(1750, 2024)
# Zhang et al. 1995, seawater fit. ⚠ SECONDARY QUOTE -- see the header.
AP_Z_A   <-  0.014   # permil per degC per unit fCO3
AP_Z_B   <- -0.105   # permil per degC
AP_Z_C   <-  10.53   # permil
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
zhang_eps   <- function(T, f) AP_Z_A * T * f + AP_Z_B * T + AP_Z_C
zhang_slope <- function(f)    AP_Z_A * f + AP_Z_B
cat("\n  Zhang et al. 1995, eps_DIC-g = 0.014*T*fCO3 - 0.105*T + 10.53 permil:\n")
for (h in HEMIS) {
  e <- zhang_eps(st[[h]]$sst, st[[h]]$fco3); s <- zhang_slope(st[[h]]$fco3)
  st[[h]]$eps_dicg <- e; st[[h]]$slope <- -s   # eps_up = -eps_DIC-g
  cat(sprintf("    %s  eps_DIC-g = %+6.3f permil  ⇒ eps_up = %+6.3f  |  d(eps_up)/dT = %+.4f permil/K\n",
              h, e, -e, -s))
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
  "Zhang 1995 (MEASURED)"                = mean(vapply(st, function(x) x$slope, 0)),
  "Mook, as recalled (1/T)"              = AP_MOOK / AP_T_REF^2,
  "boiling anchor, 1/T form"             = inv_slope(AP_TB),
  "boiling anchor, LINEAR form"          = lin_slope(AP_TB),
  "critical anchor, 1/T form"            = inv_slope(AP_TCRIT),
  "critical anchor, LINEAR form"         = lin_slope(AP_TCRIT))
ref <- cand[["Zhang 1995 (MEASURED)"]]
cat(sprintf("  %-32s %12s %10s\n", "law", "d eps/dT", "vs Zhang"))
for (n in names(cand))
  cat(sprintf("  %-32s %+12.4f %9.1f %%\n", n, cand[[n]], 100 * (cand[[n]] - ref) / ref))
zc <- AP_Z_C / -zhang_slope(mean(vapply(st, function(x) x$fco3, 0)))
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
  paste("NOT THE EXPLANATION. The term is 8-15 % of what the model already gets",
        "\n    WRONG on the two rows that carry the veto, and at the derived phase it",
        "\n    moves both residuals the WRONG WAY by ~5 %. A flag worth -12.2 prior-sd",
        "\n    cannot be paid for out of a term this size whichever way it points.",
        "\n    ⇒ IT IS REAL PHYSICS AND IT IS STILL NOT THE ANSWER -- which is exactly",
        "\n      the outcome handoff §5 said was worth an afternoon rather than a refit.")
  else "SAME ORDER AS THE RESIDUAL. The mechanism is a live candidate; implement it."))
cat("\n  ⛔ AND THE MEAN VALUE IS A SEPARATE QUESTION FROM THE SLOPE. Zhang puts\n")
cat(sprintf("     eps_up at %+.2f / %+.2f permil (NH/SH) against the model's hardcoded %+.2f;\n",
            -st$NH$eps_dicg, -st$SH$eps_dicg, eps_up))
cat("     that is a CONSTANT offset on the evasion limb, it moves the steady-state\n")
cat("     d_ml - d_atm, and it is the 5a question. It is NOT priced here.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(state = st, candidates = cand, response = res, zhang_zero_degC = zc,
             model_pair = c(eps_down = eps_dn, eps_up = eps_up),
             xcheck = c(fit = sx, independent = AP_Z_XCHECK)),
        file.path(OUTDIR, "alpha_as_up_precheck.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n",
            file.path(OUTDIR, "alpha_as_up_precheck.rds")))
