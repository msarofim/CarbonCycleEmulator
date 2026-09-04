# =====================================================================
# SCOPING: WOULD A SOLAR->PHOTOSYNTHESIS LINK, OR ANTHROPOGENIC AEROSOL ->
# DIFFUSE LIGHT, BUY ANYTHING? (Marcus 2026-09-04)
#
# CONTEXT. GATE V says the model carries 0.70-0.77 of the observed interannual
# CO2 growth variability, and the knockouts say ENSO + temperature + volcanic
# AOD supply 93 % of what it does have [[ccx_gate_v_variability]]. Marcus:
# "I wouldn't expect to capture all of it with just ENSO, volcanoes and
# temperature ... look into the solar insolation/photosynthesis link (which
# isn't only about the 11 year cycle but also the increase in solar activity in
# the early 20th century) or anthropogenic aerosol emissions -> diffuse light to
# see if there is some easy benefit -- but interannual variability is not a
# dealbreaker."
#
# ⛔ THE TWO CANDIDATES ARE NOT SYMMETRIC, AND THE ARITHMETIC SAYS SO BEFORE ANY
# RUN DOES. The model's existing mechanism is NPP *= 1 + gamma_diff * AOD: a
# DIFFUSE-FRACTION effect, high leverage because scattered light reaches shaded
# canopy that direct beam never does (Gu 2003, Mercado 2009 -- the same pair the
# volcanic term cites). The sun does NOT change the diffuse fraction; it changes
# TOTAL irradiance, where the best case is 1:1 and light saturation makes it
# less. So part 1 PRICES the solar path from first principles and part 2 RUNS
# the aerosol one, which is the same high-leverage mechanism with a different
# aerosol source -- and is what Mercado 2009 is actually about.
#
# ⛔ SCOPING ONLY. Nothing here is adopted, fitted, or shipped.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
ASD_ARM        <- CCX_MODE_CANONICAL
ASD_SOLAR_CSV  <- file.path(Sys.getenv("HOME"), "Documents/2026/CodeProjects/FaIRtoFrEDI",
                            "calibration_v160_prod/volcanic_solar_M.csv")
ASD_EMIS_CSV   <- file.path(Sys.getenv("HOME"), "Documents/2026/CodeProjects/FaIRtoFrEDI",
                            "calibration_v160_prod/emissions_v160_cmip7harm_ssp245.csv")
# Both are the CMIP7 / FaIR calib 1.6.0 drivers, i.e. LIKE-FOR-LIKE with the
# stratospheric AOD product this model already uses. [[fair_calib_160_migration]]
ASD_ALBEDO     <- 0.29      # planetary, for ERF -> TSI: ERF = dTSI/4 * (1 - albedo)
ASD_TSI        <- 1361      # W/m2, solar constant
ASD_NPP_PGC    <- ccx_const_exists <- 52.7   # PgC/yr, MOD17 global mean (obs_npp_hemispheric)
ASD_A_PEAK     <- c(0, 0.02, 0.05, 0.10, 0.20)  # scanned peak ANTHROPOGENIC AOD-equivalent
ASD_NH_SHARE   <- 0.90      # of anthropogenic sulfate; industrial emissions are NH-dominated
ASD_NH_SENS    <- c(0.70, 1.00)                 # ...and the sensitivity to that assumption
ASD_OUT        <- ccx_path("calibration", "output", "aerosol_solar_diffuse_scope")
dir.create(ASD_OUT, showWarnings = FALSE, recursive = TRUE)
sep <- function(s) cat(sprintf("\n%s\n%s\n%s\n", strrep("=", 74), s, strrep("=", 74)))

v  <- dg_vector(ASD_ARM)
OV <- dg_gateV_obs()

# =====================================================================
sep("1. THE SOLAR PATH, PRICED FROM FIRST PRINCIPLES BEFORE ANY RUN")
sol <- read.csv(ASD_SOLAR_CSV, check.names = FALSE)
sol <- sol[sol$Variable == "Solar", ]
syr <- as.integer(names(sol)[5:ncol(sol)]); sv <- as.numeric(sol[1, 5:ncol(sol)])
k <- syr >= 1750 & syr <= DG_AF_WIN[2]; syr <- syr[k]; sv <- sv[k]
h  <- stats::lm(sv[syr >= 1900] ~ sin(2 * pi * syr[syr >= 1900] / 11) +
                                  cos(2 * pi * syr[syr >= 1900] / 11))
amp11 <- sqrt(sum(stats::coef(h)[2:3]^2))
sec   <- mean(sv[syr >= 1950 & syr <= 1969]) - mean(sv[syr >= 1900 & syr <= 1919])
cat(sprintf("  Solar ERF (CMIP7/FaIR 1.6.0): 11-yr amplitude %.4f W/m2, and the\n", amp11))
cat(sprintf("  EARLY-20TH-CENTURY RISE Marcus named IS THERE: 1900-19 -> 1950-69 = %+.4f W/m2.\n", sec))
to_tsi <- function(erf) erf / ((1 - ASD_ALBEDO) / 4)
frac   <- function(erf) to_tsi(erf) / ASD_TSI
cat(sprintf("\n  ERF -> TSI (ERF = dTSI/4 x (1 - %.2f)) -> fraction of %d W/m2:\n", ASD_ALBEDO, ASD_TSI))
cat(sprintf("    11-yr, peak-to-trough  %.3f W/m2 TSI = %.4f %% of TSI\n",
            to_tsi(2 * amp11), 100 * frac(2 * amp11)))
cat(sprintf("    secular 1900s->1950s   %.3f W/m2 TSI = %.4f %% of TSI\n",
            to_tsi(sec), 100 * frac(sec)))
cat(sprintf("\n  UPPER BOUND on NPP, taking NPP PROPORTIONAL to irradiance (it is not --\n"))
cat(sprintf("  photosynthesis saturates with light, so 1:1 is a CEILING), on %.1f PgC/yr:\n", ASD_NPP_PGC))
npp11 <- frac(amp11) * ASD_NPP_PGC; nppsec <- frac(sec) * ASD_NPP_PGC
cat(sprintf("    11-yr amplitude  %.4f GtC/yr   = %.2f %% of the observed anomaly sd (%.3f)\n",
            npp11, 100 * npp11 / OV$sd, OV$sd))
cat(sprintf("                                   = %.4f %% of its VARIANCE\n",
            100 * (npp11^2 / 2) / OV$sd^2))
cat(sprintf("    secular shift    %.4f GtC/yr   -> %.2f GtC over the 50 yr it takes\n",
            nppsec, nppsec * 50))
cat(sprintf("\n  FOR SCALE, the mechanism the model ALREADY HAS: gamma_diff %.2f x Pinatubo\n",
            v$p$gamma_diff))
F0 <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = 0, bomb_total_kmol = v$bomb_total)
pin <- max((F0$aod_NH + F0$aod_SH) / 2)
cat(sprintf("  AOD %.3f = %.2f %% of NPP = %.3f GtC/yr -- %.0fx the solar 11-yr bound.\n",
            pin, 100 * v$p$gamma_diff * pin, v$p$gamma_diff * pin * ASD_NPP_PGC,
            (v$p$gamma_diff * pin * ASD_NPP_PGC) / npp11))
cat("\n  ⇒ THE STRUCTURAL REASON, not just the arithmetic: aerosols change the\n")
cat("    DIFFUSE FRACTION, which redistributes light into shaded canopy; the sun\n")
cat("    changes TOTAL irradiance, which is 1:1 at best. The high-leverage\n")
cat("    channel is UNAVAILABLE to solar by physics, and the low-leverage one is\n")
cat("    three orders of magnitude down in VARIANCE. No run can rescue that.\n")

# =====================================================================
sep("2. ANTHROPOGENIC AEROSOL -> DIFFUSE LIGHT: THE SHAPE FIRST")
em <- read.csv(ASD_EMIS_CSV, check.names = FALSE)
so2 <- em[em$variable == "Sulfur", ]
eyr <- floor(as.numeric(names(em)[5:ncol(em)])); ev <- as.numeric(so2[1, 5:ncol(em)])
k <- eyr >= DG_YEARS[1] & eyr <= DG_YEARS[2]; eyr <- eyr[k]; ev <- ev[k]
pk <- which.max(ev)
cat(sprintf("  CMIP7 SO2: 1750 %.1f -> PEAK %.1f Mt SO2/yr in %d -> %.1f in %d.\n",
            ev[1], ev[pk], eyr[pk], ev[length(ev)], eyr[length(eyr)]))
res <- stats::residuals(stats::lm(ev ~ splines::ns(eyr, df = 12)))
cat(sprintf("  ⛔ AND IT IS SMOOTH: interannual sd about a 12-dof spline is %.2f Mt,\n", stats::sd(res)))
cat(sprintf("     %.1f %% of the peak. Sulfate lifetime is days, so anthropogenic AOD\n",
            100 * stats::sd(res) / ev[pk]))
cat("     inherits the emissions' shape -- a TREND driver, not an interannual one.\n")
cat("     ⇒ Predicted before running: this helps GATE V hardly at all. What it\n")
cat("       could move is the AF TREND and the decadal profile.\n")

# ---- the runner: anthropogenic AOD added to the diffuse-light column
asd_run <- function(a_peak, nh_share = ASD_NH_SHARE, beta_max = NULL, fert_k = NULL) {
  p <- v$p
  if (!is.null(beta_max)) p$beta_max <- beta_max
  if (!is.null(fert_k))   p$fert_k   <- fert_k
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  if (a_peak > 0) {
    shape <- stats::approx(eyr + 0.5, ev / ev[pk], xout = F$t, rule = 2)$y
    F$aod_NH <- F$aod_NH + a_peak * shape * (2 * nh_share)
    F$aod_SH <- F$aod_SH + a_peak * shape * (2 * (1 - nh_share))
  }
  r <- list(out = ccx_run_fast(sp, F)$out, F = F)
  ll <- ccx_loglik(r$out, ccx_prepare_obs(), v$pm,
                   luc = ccx_forcing_eluc_annual(F), deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)
  a <- dg_af_annual_model(r); d <- dg_af_dec(a)
  yrw <- a$year[a$year >= DG_AF_WIN[1] & a$year <= DG_AF_WIN[2]]
  tr <- stats::coef(stats::lm(a$grow[a$year %in% yrw] ~ 0 +
          I((a$foss + a$luc)[a$year %in% yrw]) +
          I((a$foss + a$luc)[a$year %in% yrw] * (yrw - mean(yrw)))))[2]
  list(gv = dg_gateV(r), af = d, trend = unname(tr), ll = ll, g7 = dg_gate7(r))
}

sep("3. THE SCAN")
t0 <- Sys.time()
S <- lapply(ASD_A_PEAK, asd_run)
names(S) <- sprintf("%.2f", ASD_A_PEAK)
cat(sprintf("  %d runs in %.1f s\n\n", length(S), as.numeric(Sys.time() - t0, units = "secs")))
ll0 <- sum(unlist(S[["0.00"]]$ll))
cat(sprintf("  %-9s %8s %8s %9s %10s %10s %9s %10s\n", "A_peak", "NPP+%", "sd(V)", "z(V)",
            "AF(all)", "AF trend", "d(logL)", "land sink"))
cat(sprintf("  %-9s %8s %8.3f %9s %10.4f %10s %9s %10.3f\n", "OBSERVED", "--", OV$sd, "--",
            DG_AF_OBS, sprintf("%+.4f", 0.0147), "--", dg_gcb_target(DG_SINK_WIN)$land))
for (nm in names(S)) {
  s <- S[[nm]]; a <- as.numeric(nm)
  cat(sprintf("  %-9s %8.2f %8.3f %9.2f %10.4f %10.4f %9.1f %10.3f\n", nm,
              100 * v$p$gamma_diff * a, s$gv$sd, dg_gateV_verdict(s$gv, OV)$z,
              s$af$all, 10 * s$trend, sum(unlist(s$ll)) - ll0, s$g7$land))
}
cat("\n  DECADAL AF (GCB in the first row):\n")
cat(sprintf("  %-9s %s\n", "obs", paste(sprintf("%7.3f", DG_AF_OBS_DEC), collapse = "")))
for (nm in names(S)) cat(sprintf("  %-9s %s\n", nm, paste(sprintf("%7.3f", S[[nm]]$af$dec), collapse = "")))

cat("\n  WHICH STREAMS PAY, at the largest A_peak:\n")
d <- S[[length(S)]]$ll - S[["0.00"]]$ll
d <- d[order(-abs(d))][1:6]
for (i in seq_along(d)) cat(sprintf("    %-20s %+9.2f\n", names(d)[i], d[i]))

cat("\n  SENSITIVITY to the NH share assumption (at A_peak = 0.10):\n")
for (ns in ASD_NH_SENS) { s <- asd_run(0.10, ns)
  cat(sprintf("    NH share %.2f: sd(V) %.3f, AF %.4f, d(logL) %+.1f\n",
              ns, s$gv$sd, s$af$all, sum(unlist(s$ll)) - ll0)) }

# =====================================================================
sep("4. CONDITIONAL PRICING -- because the frozen column is NOT the price")
# ⛔ THE 2026-08-29h LESSON, APPLIED IN ADVANCE. When `gamma_diff` itself was
# priced, the FROZEN-parameter cost OVERSTATED the real one by 82 % at every
# gamma [[ccx_diffuse_light]]: a new NPP term is absorbed by whatever else sets
# NPP. Here that is the FERTILISATION PAIR (`beta_max`, `fert_k`) -- and the
# degeneracy is close to exact, because both an anthropogenic-AOD term and CO2
# fertilisation raise NPP monotonically over the industrial period.
# ⇒ SO THE IDENTIFIABLE PART IS THE SHAPE, NOT THE LEVEL: what fertilisation
# CANNOT imitate is the PEAK-THEN-DECLINE after 1979 -- the global-brightening
# signature. This section re-optimises the pair at each A_peak and re-prices.
asd_ll <- function(a_peak, bm, fk) sum(unlist(asd_run(a_peak, beta_max = bm, fert_k = fk)$ll))
tb <- CCX_PARAM_TABLE
cat(sprintf("  re-optimising (beta_max, fert_k) from (%.4f, %.2f) at each A_peak\n",
            v$p$beta_max, v$p$fert_k))
t0 <- Sys.time()
COND <- lapply(ASD_A_PEAK, function(a) {
  o <- stats::optim(c(v$p$beta_max, v$p$fert_k),
                    function(z) -asd_ll(a, z[1], z[2]), method = "L-BFGS-B",
                    lower = c(tb$beta_max$lo + 1e-6, tb$fert_k$lo),
                    upper = c(tb$beta_max$hi - 1e-6, tb$fert_k$hi),
                    control = list(factr = 1e9))
  list(par = o$par, ll = -o$value) })
names(COND) <- names(S)
cat(sprintf("  done in %.0f s\n\n", as.numeric(Sys.time() - t0, units = "secs")))
ll0c <- COND[["0.00"]]$ll
cat(sprintf("  %-9s %10s %9s %10s %12s %12s\n", "A_peak", "beta_max", "fert_k",
            "d(logL)", "frozen d", "absorbed"))
for (nm in names(S)) {
  c1 <- COND[[nm]]; fz <- sum(unlist(S[[nm]]$ll)) - ll0
  cat(sprintf("  %-9s %10.4f %9.1f %10.1f %12.1f %11.0f %%\n", nm, c1$par[1], c1$par[2],
              c1$ll - ll0c, fz, if (fz < 0) 100 * (1 - (c1$ll - ll0c) / fz) else NA))
}
cat("\n  ⇒ read the FIRST number, not the fourth. A term that costs a lot frozen\n")
cat("    and little re-optimised is DEGENERATE with what absorbed it, not wrong.\n")
cat("\n  AND AT THE CONDITIONAL OPTIMUM, what the AF and gate V do:\n")
cat(sprintf("  %-9s %8s %9s %10s %10s\n", "A_peak", "sd(V)", "z(V)", "AF(all)", "AF trend"))
CONDR <- list()
for (nm in names(S)) { c1 <- COND[[nm]]
  r <- asd_run(as.numeric(nm), beta_max = c1$par[1], fert_k = c1$par[2]); CONDR[[nm]] <- r
  cat(sprintf("  %-9s %8.3f %9.2f %10.4f %10.4f\n", nm, r$gv$sd,
              dg_gateV_verdict(r$gv, OV)$z, r$af$all, 10 * r$trend)) }
cat(sprintf("  %-9s %8.3f %9s %10.4f %10.4f\n", "OBSERVED", OV$sd, "--", DG_AF_OBS, 0.0147))

# =====================================================================
sep("5. ⭐ WHAT BREAKS THE DEGENERACY: FACE, NOT THE CO2 RECORD")
# The CO2 record cannot separate an anthropogenic-AOD NPP term from CO2
# fertilisation -- section 4 shows the fit absorbs ~100 % of the former into the
# latter. But `beta_max` is not free: it is ALSO the model's predicted response
# to a FACE enrichment, and THAT is an independent observation.
# ⚠ Closed form, no runs: R(400 -> 564) = (1 + en(564)) / (1 + en(400)) - 1 with
# en(chi) = beta_max * (chi - CO2_PI) / (fert_k + chi - CO2_PI), the same
# expression `diag_fert_ridge_gates.R` and `diag_face_prior_for_beta_max.R` use.
ASD_FACE_AMB <- 400; ASD_FACE_ENR <- 0.41     # Norby 2025 normalising enrichment
ASD_FACE_OBS <- c("Norby 2025 synthesis" = 0.218, "Norby 2005 (young plantations)" = 0.23)
CHI0 <- ccx_const("CO2_PI_PPM")
Rface <- function(bm, K) {
  en <- function(chi) { d <- chi - CHI0; bm * d / (K + d) }
  (1 + en(ASD_FACE_AMB * (1 + ASD_FACE_ENR))) / (1 + en(ASD_FACE_AMB)) - 1
}
cat(sprintf("  FACE observations, %d -> %d ppm: %s\n", ASD_FACE_AMB,
            round(ASD_FACE_AMB * (1 + ASD_FACE_ENR)),
            paste(sprintf("%s %.1f %%", names(ASD_FACE_OBS), 100 * ASD_FACE_OBS), collapse = "; ")))
cat(sprintf("  ⚠ Those are YOUNG PLANTATIONS; the mature-forest end is lower, so this\n"))
cat(sprintf("    reads as a CEILING on the model's response, not a target.\n\n"))
cat(sprintf("  %-9s %10s %9s %10s %14s\n", "A_peak", "beta_max", "fert_k", "R(400-564)", "vs Norby 21.8%"))
for (nm in names(S)) { c1 <- COND[[nm]]; rf <- Rface(c1$par[1], c1$par[2])
  cat(sprintf("  %-9s %10.4f %9.1f %9.1f %% %13s\n", nm, c1$par[1], c1$par[2], 100 * rf,
              sprintf("%+.1f pp", 100 * (rf - ASD_FACE_OBS[[1]])))) }
cat("\n  ⇒ FACE NARROWS IT BUT DOES NOT DECIDE IT, and saying so is the point. The\n")
cat("    compensated response moves +4 pp, which stays INSIDE a FACE envelope that\n")
cat("    runs from 0 % (EucFACE, mature and P-limited) to 23 % (young plantations)\n")
cat("    -- an envelope too wide to reject anything here. So the honest reading is:\n")
cat("    the CO2 record cannot identify the term, and neither can FACE.\n")
cat("  ⚠ WHAT IS STILL TRUE, AND IS THE ARGUMENT AGAINST ADDING IT NOW: buying the\n")
cat("    aerosol term RELOCATES `beta_max` by a factor of 2.3 while changing nothing\n")
cat("    measurable -- and `beta_max` is what the pulse IRF and every fertilisation\n")
cat("    result rest on. An unidentifiable term that silently moves an identified\n")
cat("    parameter is a bad trade. [[ccx_saturating_fert]], [[ccx_beta_recentred]]\n")


saveRDS(list(arm = v$src, obs = OV, scan = S, a_peak = ASD_A_PEAK, cond = COND, condr = CONDR,
             solar = list(amp11 = amp11, secular = sec, npp11 = npp11, nppsec = nppsec),
             so2 = data.frame(year = eyr, so2 = ev), when = Sys.time()),
        file.path(ASD_OUT, "aerosol_solar_diffuse_scope.rds"))
cat(sprintf("\nwrote %s\n", file.path(ASD_OUT, "aerosol_solar_diffuse_scope.rds")))
