# =====================================================================
# diag_cfc_power_20261022.R -- could an observed ocean CFC-11 inventory constrain the canonical's ocean?
# Marcus 2026-10-22: "Do the cheap tests for both methane and CFC."
#
# THE QUESTION. CFC-11 is inert and equilibrates with the mixed layer in about two weeks (h_ml / k_w), so its
# uptake is set by ventilation below the surface, with no biology and no carbonate chemistry. The canonical's
# posterior leaves some ocean transport loosely pinned (h_hs, kz_deep_frac) and has u_hs and pump_hs_gcm2 on a
# correlated ridge. This driver measures the test's POWER before anything is built: the posterior spread of the
# predicted inventory, against the observational uncertainty, and the Gaussian update that observation would make.
#
# THE TRACER uses the model's OWN transport. Every month, the C rows of ccx_deriv_fast() are differentiated by
# finite differences with respect to each ocean box's carbon (R/spinup.R's Newton idiom). Interior transport --
# diffusion, HS<->HD exchange, seasonal entrainment, the ENSO and stratification modulations -- is linear in the
# concentrations, so this Jacobian IS the transport operator; the pump's fluxes do not depend on DIC and drop out.
# Off-diagonals within the ocean are kept; each diagonal is rebuilt from conservation (minus the column's other
# ocean entries), which removes the air-sea CO2 chemistry from the surface boxes' diagonals. GATES C/L/S check it.
# The surface boxes (those whose carbon the atmosphere row responds to) then exchange CFC-11 with the atmosphere:
#   flux = k A (c_sat - M / V),   k = k_w (Sc_CFC11 / Sc_CO2)^(-1/2),   c_sat = phi0(T, S) x_CFC11
# with A the box's exchange area (a_ml; a_hs x hs_asx_frac), V its volume at that month, T the model's own SST
# expression for that box. Mid-month operator, piecewise constant over the month, backward Euler substeps.
#
# CHOICES, stated: Bullister's hemispheric NH series on the NH boxes and SH on the SH boxes (no 10S-10N blend);
# surface pressure 1 atm; salinity SALINITY_SURFACE_GLODAP; no sea-ice limitation of exchange; the observation's
# +-1.2e8 mol read as 1 sigma (a 2-sigma reading is reported too); the inventory read at CFC_READ_T.
#
# CONSTANTS NOT IN R/constants.R, because the model does not use them (adoption would move them there):
#   * CFC-11 solubility phi0 (mol L-1 atm-1): Warner & Weiss 1985 Table 5, as printed in Orr et al. 2017,
#     GMD 10:2169, Table 2 (doi:10.5194/gmd-10-2169-2017; PDF sha256 91ba6057...2130, accessed 2026-10-22).
#   * CFC-11 Schmidt number: Wanninkhof 2014 Table 1, as printed in Orr et al. 2017 Table 1. Its CO2 row agrees
#     with R/constants.R SC_CO2_W14_A..E (read there from pySeaFlux), which the driver checks.
#   * The inventory: Willey et al. 2004, GRL 31:L01303 (doi:10.1029/2003GL018816), abstract: 5.5 +- 1.2 x 10^8 mol
#     total oceanic CFC-11, about 1994 (WOCE), 82 % in the upper 1000 m.
#
# Usage: Rscript calibration/diag_cfc_power_20261022.R > outputs/diagnostics/cfc_power_20261022_<mode>/cfc_power_<mode>.log
# =====================================================================
for (.lf in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(.lf)
ccx_load_cpp()

CFC_DRIVER  <- "calibration/diag_cfc_power_20261022.R"
CFC_COMMIT  <- ccx_git_stamp()
CFC_MODE    <- CCX_MODE_CANONICAL
CFC_YEARS   <- c(1750, 2024)                         # the forcing's span (the objective's)
CFC_OUT_DIR <- file.path("outputs", "diagnostics", sprintf("cfc_power_20261022_%s", CFC_MODE))
CFC_STEM    <- file.path(CFC_OUT_DIR, sprintf("cfc_power_%s", CFC_MODE))
CFC_ATM_FILE <- file.path("data-raw", "downloads", "cfc_atm_history_bullister_2023.csv")
CFC_GAS     <- "CFC11"
CFC_READ_T  <- 1994.5                                # the inventory's nominal epoch (WOCE, Willey et al. 2004)
CFC_READ_DT <- 2                                     # +- years: how much the epoch choice moves the inventory
CFC_END_T   <- 2022.5                                # the atmospheric record's last value (base run only)
CFC_OBS_MOL <- 5.5e8                                 # Willey et al. 2004
CFC_OBS_SE  <- 1.2e8                                 # read as 1 sigma; CFC_OBS_SE / 2 reported as the 2-sigma reading
CFC_OBS_UP1000 <- 0.82                               # fraction in the upper 1000 m (Willey et al. 2004)
CFC_UP_DEPTH <- 1000                                 # m, for the model's matching readout
CFC_PHI <- c(a1 = -229.9261, a2 = 319.6552, a3 = 119.4471, a4 = -1.39165,
             b1 = -0.142382, b2 = 0.091459, b3 = -0.0157274)          # Orr 2017 Table 2, CFC-11, mol L-1 atm-1
CFC_SC  <- c(A = 3579.2, B = -222.63, C = 7.5749, D = -0.14595, E = 0.0011874)   # Orr 2017 Table 1, CFC-11
CFC_SC_CO2_ORR <- c(A = 2116.8, B = -136.25, C = 4.7353, D = -0.092307, E = 0.0007555)   # Orr 2017 Table 1, CO2
CFC_L_PER_M3 <- 1000
CFC_PPT     <- 1e-12
CFC_K0C     <- 273.15                                # degC -> K
CFC_NSUB    <- 6                                     # backward Euler substeps per month
CFC_FD_REL  <- 1e-6                                  # Jacobian step, relative to the box's carbon
CFC_FD_CHECK <- 100                                  # GATE L: the step x this must give the same operator
CFC_GATE_TOL <- 1e-6                                 # GATES C/L/S: relative, a roundoff-scale identity tolerance
CFC_DECODE_TOL <- 1e-12                              # GATE D: the u <-> par round trip (log / logit) costs ~1 ulp
CFC_GATE_V_TOL <- 1e-6                               # GATE V: T V = dV/dt, the same roundoff scale as C/L/S
CFC_GATE_MONTHS <- 24                                # months sampled for GATES L and S
CFC_STATE_SCALE <- 1.02                              # GATE S: ocean carbon scaled by this must not move the operator
CFC_K_CHECK <- 0.5                                   # gas-exchange multiplier for the k sensitivity
CFC_PARAMS  <- c("k_w", "h_ml", "kz", "kz_deep_frac", "hs_asx_frac", "h_hs", "u_hs", "pump_hs_gcm2", "pump_grad")
CFC_SHRINK_REPORT <- 0.02                            # report parameters whose posterior sd would shrink by more
say <- function(...) { cat(sprintf(...)); flush.console() }
dir.create(CFC_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
say("=== %s @%s, %s ===\n", CFC_DRIVER, CFC_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- the canonical, gated (lib_seas8's s8_setup sequence) ----
md <- readRDS(ccx_mode_file(CFC_MODE))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
invisible(ccx_apply_pins(ccx_mode_pins(md)))
ccx_require_param_set(md, CFC_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
bp0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp0$pump_mode <- md$pump_mode
P  <- md$param_names
u0 <- unlist(ccx_par_to_unc(md$par_mode[CCX_PARAM_NAMES]))[CCX_PARAM_NAMES]
if (!identical(names(u0), P)) stop("the fitted names are not the mode file's")
if (!all(CFC_PARAMS %in% P)) stop("a CFC_PARAMS name is not fitted: ", paste(setdiff(CFC_PARAMS, P), collapse = ", "))

# the objective's own decode (ccx_make_logpost's closure): u -> the run's parameter list
cfc_params <- function(u) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  p_pr <- bp0; for (n in names(pv)) p_pr[[n]] <- pv[[n]]
  p <- bp0; for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  list(p = ccx_set_enso(p, p_pr), pv = pv)
}
L0 <- ccx_load_mode(CFC_MODE)
d0 <- cfc_params(u0)$p
num <- function(l) unlist(l[vapply(l, function(x) is.numeric(x) && length(x) == 1, logical(1))])
nm0 <- intersect(names(num(d0)), names(num(L0$p)))
rD <- max(abs(num(d0)[nm0] - num(L0$p)[nm0]) / pmax(abs(num(L0$p)[nm0]), .Machine$double.xmin))
gD <- rD <= CFC_DECODE_TOL && setequal(names(num(d0)), names(num(L0$p)))
say("GATE D: the objective's decode at the mode equals ccx_load_mode()'s parameter list (%d scalars, max rel %.1e, tol %g) -> %s\n",
    length(nm0), rD, CFC_DECODE_TOL, if (gD) "PASS" else "FAIL")
if (!gD) stop("the decode path does not reproduce the canonical's parameters")

# ---- constants checks ----
sc_poly <- function(cf, Tc) cf[["A"]] + cf[["B"]] * Tc + cf[["C"]] * Tc^2 + cf[["D"]] * Tc^3 + cf[["E"]] * Tc^4
sc_co2_ccx <- c(A = ccx_const("SC_CO2_W14_A"), B = ccx_const("SC_CO2_W14_B"), C = ccx_const("SC_CO2_W14_C"),
                D = ccx_const("SC_CO2_W14_D"), E = ccx_const("SC_CO2_W14_E"))
gK <- isTRUE(all.equal(unname(sc_co2_ccx), unname(CFC_SC_CO2_ORR), tolerance = 0))
say("GATE K: R/constants.R's CO2 Schmidt coefficients equal Orr et al. 2017 Table 1's CO2 row -> %s (Sc_CO2(20 C) = %.1f; Sc_CFC11(20 C) = %.1f, table 1179)\n",
    if (gK) "PASS" else "FAIL", sc_poly(sc_co2_ccx, 20), sc_poly(CFC_SC, 20))
if (!gK) stop("the CO2 Schmidt coefficients disagree with the source the CFC-11 ones are read from")
SAL <- ccx_const("SALINITY_SURFACE_GLODAP"); RHO <- ccx_const("RHO_SEAWATER")
phi0 <- function(Tc, S = SAL) {                       # mol m-3 atm-1
  TK <- (Tc + CFC_K0C) / 100
  exp(CFC_PHI[["a1"]] + CFC_PHI[["a2"]] / TK + CFC_PHI[["a3"]] * log(TK) + CFC_PHI[["a4"]] * TK^2 +
        S * (CFC_PHI[["b1"]] + CFC_PHI[["b2"]] * TK + CFC_PHI[["b3"]] * TK^2)) * CFC_L_PER_M3
}
say("  phi0(CFC-11, S %.2f): %.4g at 2 C, %.4g at 20 C mol m-3 atm-1 (ratio %.2f)\n", SAL, phi0(2), phi0(20), phi0(2) / phi0(20))

# ---- the atmospheric boundary condition ----
atm <- utils::read.csv(CFC_ATM_FILE, header = FALSE, skip = 3, stringsAsFactors = FALSE)
hdr <- utils::read.csv(CFC_ATM_FILE, header = FALSE, nrows = 2, stringsAsFactors = FALSE)
col <- lapply(c(NH = "NH", SH = "SH"), function(h) which(hdr[1, ] == CFC_GAS & hdr[2, ] == h))
if (any(lengths(col) != 1L)) stop("cannot find the ", CFC_GAS, " NH/SH columns in ", CFC_ATM_FILE)
atm_yr <- as.numeric(atm[[1]])
x_atm <- function(h, t) stats::approx(atm_yr, as.numeric(atm[[col[[h]]]]), t, rule = 2)$y   # ppt, linear (OMIP)
first_nz <- min(atm_yr[as.numeric(atm[[col$NH]]) > 0 | as.numeric(atm[[col$SH]]) > 0])
CFC_T0 <- floor(first_nz) - 1
say("  atmosphere: %s, %s NH/SH, %g-%g; first nonzero %.1f; tracer starts at zero in %d\n",
    basename(CFC_ATM_FILE), CFC_GAS, min(atm_yr), max(atm_yr), first_nz, CFC_T0)
if (CFC_END_T > max(atm_yr)) stop("CFC_END_T is past the atmospheric record")

# ---- the transport operator from the model's own derivative ----
cfc_setup <- function(u) {
  dp <- cfc_params(u); p <- dp$p
  sp <- spf(p)
  F  <- ccx_scaled_forcing(sp, CFC_YEARS, luc_scale = dp$pv$luc_scale, bomb_total = dp$pv$bomb_total)$F
  if (!is.null(F$enso)) F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(p), sp$enso_hist)    # ccx_run()'s two
  F[["mix_g"]] <- if (ccx_mix_on(p)) as.numeric(ccx_mix_g_series(F$gmst, F$t, p, sp$tdeep0)) else NULL  # columns
  aux <- sp$aux; grid <- sp$grid
  ccx_seas_ml_marshal_check(p, aux)
  prep <- list(par = ccx_cpp_par(p), aux = ccx_cpp_aux(aux, grid))
  O <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd)))
  if (isTRUE(aux$eq_on == 1L) || isTRUE(aux$tr_on == 1L)) stop("the eq / tr boxes are not handled by this driver")
  atmI <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  list(p = p, sp = sp, F = F, aux = aux, grid = grid, prep = prep, O = O, atmI = atmI,
       landI = unlist(lapply(HEMIS, function(h) aux$idx[[h]]$land)))
}
cfc_jac <- function(S, i, y = S$sp$y, rel = CFC_FD_REL) {
  fi <- ccx_forcing_at(S$F, i); t <- S$F$t[i] + 1 / 24          # mid-month
  f  <- function(yy) ccx_deriv_fast(yy, t, S$p, fi, S$grid, S$aux, prep = S$prep)[, "C"]
  f0 <- f(y)
  J  <- matrix(0, nrow(y), length(S$O))
  for (k in seq_along(S$O)) {
    j <- S$O[k]; dh <- rel * abs(y[j, "C"]); yp <- y; yp[j, "C"] <- yp[j, "C"] + dh
    J[, k] <- (f(yp) - f0) / dh
  }
  J
}
cfc_transport <- function(J, O) {                     # ocean block, diagonals from conservation
  T <- J[O, , drop = FALSE]; diag(T) <- 0; diag(T) <- -colSums(T); T
}
cfc_months <- function(S, t_end) which(S$F$t >= CFC_T0 & S$F$t + 1 / 12 <= t_end + 1e-9)

# surface boxes: the ones the ATMOSPHERE row responds to (read from the Jacobian, not assumed)
S0 <- cfc_setup(u0)
m0 <- cfc_months(S0, CFC_END_T)
J1 <- cfc_jac(S0, m0[1])
air <- colSums(abs(J1[S0$atmI, , drop = FALSE])) / pmax(colSums(abs(J1[S0$O, , drop = FALSE])), .Machine$double.xmin)
surfK <- which(air > CFC_GATE_TOL)
bn <- rownames(S0$sp$y)
say("  ocean boxes %d; surface (atmosphere row responds): %s\n", length(S0$O), paste(bn[S0$O[surfK]], collapse = ", "))
expect_surf <- unlist(lapply(HEMIS, function(h) c(S0$aux$idx[[h]]$ml, S0$aux$idx[[h]]$hs)))
if (!setequal(S0$O[surfK], expect_surf)) stop("the surface set read from the Jacobian is not {ml, hs}")

# GATES on the operator
gate_c <- function(J, S) {                            # interior columns: FD diagonal = conservation diagonal;
  T <- cfc_transport(J, S$O); intK <- setdiff(seq_along(S$O), surfK)   # and no atmosphere / land response
  sc <- apply(abs(J[S$O, intK, drop = FALSE]), 2, max)
  c(diag = max(abs(diag(J[S$O, , drop = FALSE])[intK] - diag(T)[intK]) / sc),
    leak = max(abs(J[c(S$atmI, S$landI), intK, drop = FALSE])) / max(sc))
}
sample_months <- m0[unique(round(seq(1, length(m0), length.out = CFC_GATE_MONTHS)))]
gc <- t(vapply(sample_months, function(i) gate_c(cfc_jac(S0, i), S0), numeric(2)))
gl <- vapply(sample_months, function(i) {
  A <- cfc_transport(cfc_jac(S0, i), S0$O); B <- cfc_transport(cfc_jac(S0, i, rel = CFC_FD_REL * CFC_FD_CHECK), S0$O)
  max(abs(A - B)) / max(abs(A)) }, numeric(1))
yS <- S0$sp$y; yS[S0$O, "C"] <- yS[S0$O, "C"] * CFC_STATE_SCALE
gsv <- vapply(sample_months, function(i) {
  A <- cfc_transport(cfc_jac(S0, i), S0$O); B <- cfc_transport(cfc_jac(S0, i, y = yS), S0$O)
  max(abs(A - B)) / max(abs(A)) }, numeric(1))
say("GATE C (conservation, %d months): interior diagonal FD vs conservation max rel %.2e; atmosphere/land response to interior max rel %.2e -> %s\n",
    length(sample_months), max(gc[, "diag"]), max(gc[, "leak"]), if (max(gc) <= CFC_GATE_TOL) "PASS" else "FAIL")
say("GATE L (linearity): the operator at step x%d vs x1, max rel %.2e -> %s\n", CFC_FD_CHECK, max(gl),
    if (max(gl) <= CFC_GATE_TOL) "PASS" else "FAIL")
say("GATE S (state independence): ocean carbon x%.2f moves the operator by max rel %.2e -> %s\n", CFC_STATE_SCALE,
    max(gsv), if (max(gsv) <= CFC_GATE_TOL) "PASS" else "FAIL")
if (max(gc) > CFC_GATE_TOL || max(gl) > CFC_GATE_TOL || max(gsv) > CFC_GATE_TOL)
  stop("the transport operator failed a gate: the Jacobian is not a pure linear transport here")

# ---- the tracer run ----
cfc_surface <- function(S, i, kscale) {
  t <- S$F$t[i] + 1 / 24; fi <- ccx_forcing_at(S$F, i); p <- S$p; aux <- S$aux
  out <- list()
  for (h in HEMIS) {
    sa  <- fi[[paste0("sst_anom_", h)]]
    anom <- if (isTRUE(p$sst_obs > 0) && !is.null(sa) && is.finite(sa)) sa else p$sst_scale * fi$gmst
    sst <- aux$sst[[h]] + anom                         # ccx_deriv()'s mixed-layer expression
    if (isTRUE(p$seas_drivers > 0)) {
      a_s <- if (h == "NH") p$sst_seas_amp_NH else p$sst_seas_amp_SH
      sst <- sst + (if (h == "NH") 1 else -1) * a_s * sin(2 * pi * (t - (3.5 + ccx_sst_seas_lag(p)[[h]]) / 12))
    }
    sst_hs <- aux$sst_hs + ccx_hs_sst_frac(p) * anom   # and its HS expression
    f_ml <- if (ccx_seas_ml_ls_on(p)) ccx_mld_eval(aux$mld_coef[[h]], t)$f else 1
    f_hs <- if (ccx_seas_ml_hs_on(p)) ccx_mld_eval(aux$mld_hs_coef[[h]], t)$f else 1
    x <- x_atm(h, t) * CFC_PPT
    for (b in c("ml", "hs")) {
      Tc <- if (b == "ml") sst else sst_hs
      A  <- if (b == "ml") aux$a_ml[[h]] else aux$a_hs[[h]] * (if (is.null(p$hs_asx_frac)) 1 else p$hs_asx_frac)
      V  <- (if (b == "ml") aux$ml_mass_kg[[h]] * f_ml else aux$hs_mass_kg[[h]] * f_hs) / RHO
      k  <- kscale * p$k_w * sqrt(sc_poly(sc_co2_ccx, Tc) / sc_poly(CFC_SC, Tc))
      out[[paste0(h, "_", b)]] <- c(idx = aux$idx[[h]][[b]], kA = k * A, V = V, csat = phi0(Tc) * x)
    }
  }
  out
}
cfc_run <- function(S, t_end, kscale = 1, keep_boxes_at = NULL) {
  ms <- cfc_months(S, t_end); nO <- length(S$O)
  x <- numeric(nO); inv <- numeric(length(ms)); boxes <- NULL
  dt <- 1 / 12 / CFC_NSUB; I <- diag(nO)
  for (q in seq_along(ms)) {
    i <- ms[q]
    A <- cfc_transport(cfc_jac(S, i), S$O); b <- numeric(nO)
    for (s in cfc_surface(S, i, kscale)) {
      k <- match(s[["idx"]], S$O); A[k, k] <- A[k, k] - s[["kA"]] / s[["V"]]; b[k] <- s[["kA"]] * s[["csat"]]
    }
    M <- I - dt * A
    for (r in seq_len(CFC_NSUB)) x <- solve(M, x + dt * b)
    inv[q] <- sum(x)
    if (!is.null(keep_boxes_at) && abs(S$F$t[i] + 1 / 12 - keep_boxes_at) < 1e-6) boxes <- stats::setNames(x, rownames(S$sp$y)[S$O])
  }
  list(t = S$F$t[ms] + 1 / 12, inv = inv, boxes = boxes)
}
read_inv <- function(r, tq) stats::approx(r$t, r$inv, tq)$y

# GATE V: a transport on CONCENTRATIONS carries a uniform concentration with the water, so T(t) V(t) = dV/dt,
# V the box volumes (the seasonal mixed layer and its layer-1 compensation move them; a null-vector form of this
# gate, T V = 0, FAILED at 4-45 % on exactly that term and was replaced, CHANGELOG 2026-10-22 j). The V here is
# the one the air-sea exchange divides by (cfc_surface), so the gate checks the exchange against the transport.
vol_now <- function(S, i) {
  t <- S$F$t[i] + 1 / 24; aux <- S$aux; g <- S$grid; p <- S$p
  V <- dV <- stats::setNames(numeric(length(S$O)), rownames(S$sp$y)[S$O])
  for (h in HEMIS) {
    e  <- if (ccx_seas_ml_ls_on(p)) ccx_mld_eval(aux$mld_coef[[h]], t) else list(f = 1, dfdt = 0)
    eh <- if (ccx_seas_ml_hs_on(p)) ccx_mld_eval(aux$mld_hs_coef[[h]], t) else list(f = 1, dfdt = 0)
    vml <- aux$ml_mass_kg[[h]] / RHO; vhs <- aux$hs_mass_kg[[h]] / RHO
    V[paste0(h, "_ml")] <- vml * e$f; dV[paste0(h, "_ml")] <- vml * e$dfdt
    for (k in seq_len(g$nl)) V[paste0(h, "_oc", k)] <- aux$a_ls[[h]] * g$dz[k + 1]
    V[paste0(h, "_oc1")] <- V[paste0(h, "_oc1")] - vml * (e$f - 1); dV[paste0(h, "_oc1")] <- -vml * e$dfdt
    V[paste0(h, "_hs")] <- vhs * eh$f; dV[paste0(h, "_hs")] <- vhs * eh$dfdt
    V[paste0(h, "_hd")] <- aux$a_hs[[h]] * aux$thick_hd[[h]] - vhs * (eh$f - 1); dV[paste0(h, "_hd")] <- -vhs * eh$dfdt
  }
  sf <- cfc_surface(S, i, 1)
  for (nm in names(sf)) if (abs(sf[[nm]][["V"]] / V[[nm]] - 1) > CFC_DECODE_TOL)       # same formula, ~1 ulp
    stop("GATE V: cfc_surface()'s ", nm, " volume is not vol_now()'s")
  list(V = V, dV = dV)
}
gv <- vapply(sample_months, function(i) {
  T <- cfc_transport(cfc_jac(S0, i), S0$O); vv <- vol_now(S0, i)
  c(with = max(abs(drop(T %*% vv$V) - vv$dV) / drop(abs(T) %*% vv$V)),
    without = max(abs(drop(T %*% vv$V)) / drop(abs(T) %*% vv$V))) }, numeric(2))
say("GATE V (T V = dV/dt, %d months): max rel residual %.2e (tol %g) -> %s; dropping dV/dt it is %.2e (the gate can fail)\n",
    ncol(gv), max(gv["with", ]), CFC_GATE_V_TOL, if (max(gv["with", ]) <= CFC_GATE_V_TOL) "PASS" else "FAIL",
    max(gv["without", ]))
if (max(gv["with", ]) > CFC_GATE_V_TOL) stop("GATE V: the exchange's box volumes disagree with the transport operator's")

# where the tracer sits at the read time: the low-latitude column by depth (uniform within a layer), HS whole,
# HD uniform over its depth (annual-mean geometry)
box_readouts <- function(bx, S) {
  g <- S$grid; up <- 0
  for (h in HEMIS) {
    ls <- c(paste0(h, "_ml"), paste0(h, "_oc", seq_len(g$nl)))
    ztop <- cumsum(c(0, g$dz))[seq_along(g$dz)]
    frac <- pmin(pmax((CFC_UP_DEPTH - ztop) / g$dz, 0), 1)
    up <- up + sum(bx[ls] * frac) + bx[[paste0(h, "_hs")]]
    up <- up + bx[[paste0(h, "_hd")]] * min(max((CFC_UP_DEPTH - S$aux$thick_hs[[h]]) / S$aux$thick_hd[[h]], 0), 1)
  }
  c(upper = up / sum(bx), hs_share = sum(bx[paste0(HEMIS, "_hs")] + bx[paste0(HEMIS, "_hd")]) / sum(bx),
    nh_share = sum(bx[grep("^NH_", names(bx))]) / sum(bx))
}

say("\n=== 1. THE CANONICAL'S INVENTORY ===\n")
t_box <- S0$F$t[cfc_months(S0, CFC_READ_T)][length(cfc_months(S0, CFC_READ_T))] + 1 / 12
r0 <- cfc_run(S0, CFC_END_T, keep_boxes_at = t_box)
I0 <- read_inv(r0, CFC_READ_T)
say("  modelled CFC-11 inventory %.1f: %.3e mol vs observed %.2e +- %.1e (model/obs %.2f; ln-ratio %+.2f = %+.2f obs sd)\n",
    CFC_READ_T, I0, CFC_OBS_MOL, CFC_OBS_SE, I0 / CFC_OBS_MOL, log(I0 / CFC_OBS_MOL),
    log(I0 / CFC_OBS_MOL) / (CFC_OBS_SE / CFC_OBS_MOL))
dI <- (read_inv(r0, CFC_READ_T + CFC_READ_DT) - read_inv(r0, CFC_READ_T - CFC_READ_DT)) / (2 * CFC_READ_DT)
say("  epoch sensitivity: %+.2f %% per year around %.1f (so +-%g yr is +-%.0f %%)\n", 100 * dI / I0, CFC_READ_T,
    CFC_READ_DT, 100 * abs(dI) * CFC_READ_DT / I0)
for (tt in c(1980.5, 2000.5, 2010.5)) say("  inventory %.1f: %.3e mol\n", tt, read_inv(r0, tt))
say("  inventory %.2f (the last month): %.3e mol\n", max(r0$t), r0$inv[length(r0$inv)])
q0 <- box_readouts(r0$boxes, S0)
say("  at %.2f: upper %g m holds %.0f %% (observed %.0f %%); the high-latitude HS+HD column holds %.0f %%; NH %.0f %% of the total\n",
    t_box, CFC_UP_DEPTH, 100 * q0[["upper"]], 100 * CFC_OBS_UP1000, 100 * q0[["hs_share"]], 100 * q0[["nh_share"]])
rk <- cfc_run(S0, CFC_READ_T + CFC_READ_DT, kscale = CFC_K_CHECK)
say("  gas exchange x%.1f moves the %.1f inventory by %+.1f %% (the k / Schmidt approximation's reach)\n",
    CFC_K_CHECK, CFC_READ_T, 100 * (read_inv(rk, CFC_READ_T) / I0 - 1))

say("\n=== 2. SENSITIVITY: d ln(inventory) / du by central differences at md$hess_eps ===\n")
h <- md$hess_eps[P]
READOUTS <- c("ln_inventory", names(q0))
G <- matrix(0, length(P), length(READOUTS), dimnames = list(P, READOUTS))
readout_at <- function(u) {
  S <- cfc_setup(u); r <- cfc_run(S, CFC_READ_T + CFC_READ_DT, keep_boxes_at = t_box)
  c(ln_inventory = log(read_inv(r, CFC_READ_T)), box_readouts(r$boxes, S))
}
for (nm in CFC_PARAMS) {
  up_u <- u0; dn_u <- u0; up_u[nm] <- up_u[nm] + h[[nm]]; dn_u[nm] <- dn_u[nm] - h[[nm]]
  G[nm, ] <- (readout_at(up_u) - readout_at(dn_u)) / (2 * h[[nm]])
}
g <- G[, "ln_inventory"]
sdU <- md$sd_unc[P]
say("  per posterior sd of each parameter (d readout / du x sd); ln_inventory in ln units, the shares as fractions\n")
say("  %-14s %s\n", "", paste(sprintf("%13s", READOUTS), collapse = ""))
for (nm in CFC_PARAMS) say("  %-14s %s\n", nm, paste(sprintf("%+13.4f", G[nm, ] * sdU[[nm]]), collapse = ""))

say("\n=== 3. POWER: the posterior spread of the prediction vs the observation ===\n")
Sig <- md$cov[P, P]
sd_pred <- sqrt(drop(t(g) %*% Sig %*% g))
s_obs <- c(one_sigma = CFC_OBS_SE / CFC_OBS_MOL, two_sigma = CFC_OBS_SE / 2 / CFC_OBS_MOL)
say("  posterior sd of ln(inventory) %.4f (%.1f %%) vs observation %.3f (1 sigma reading) / %.3f (2 sigma reading)\n",
    sd_pred, 100 * sd_pred, s_obs[[1]], s_obs[[2]])
upd <- lapply(s_obs, function(so) {
  k <- drop(Sig %*% g) / (sd_pred^2 + so^2)
  Sig - outer(k, drop(t(g) %*% Sig))
})
cr <- function(S, a, b) S[a, b] / sqrt(S[a, a] * S[b, b])
for (nmS in names(upd)) {
  S1 <- upd[[nmS]]; shr <- 1 - sqrt(diag(S1)) / sqrt(diag(Sig))
  say("  %s: parameters whose sd shrinks by > %.0f %%: %s\n", nmS, 100 * CFC_SHRINK_REPORT,
      if (any(shr > CFC_SHRINK_REPORT)) paste(sprintf("%s %.1f %%", names(shr)[shr > CFC_SHRINK_REPORT],
                                                    100 * shr[shr > CFC_SHRINK_REPORT]), collapse = ", ") else "none")
  say("    corr(u_hs, pump_hs_gcm2) %+.3f -> %+.3f; corr(kz, kz_deep_frac) %+.3f -> %+.3f; corr(kz, u_hs) %+.3f -> %+.3f\n",
      cr(Sig, "u_hs", "pump_hs_gcm2"), cr(S1, "u_hs", "pump_hs_gcm2"), cr(Sig, "kz", "kz_deep_frac"),
      cr(S1, "kz", "kz_deep_frac"), cr(Sig, "kz", "u_hs"), cr(S1, "kz", "u_hs"))
}

# THE CEILING: what a PERFECT observation of each readout could do. A parameter's sd can shrink at most to
# sqrt(1 - rho^2), rho its posterior correlation with the predicted readout, however precise the observation.
say("\n  THE CEILING (a perfect observation): posterior sd of each readout, and each parameter's best possible sd shrink\n")
ceil <- sapply(READOUTS, function(q) {
  gq <- G[, q]; v <- drop(t(gq) %*% Sig %*% gq); c_ <- drop(Sig %*% gq)
  rho <- c_ / sqrt(diag(Sig) * v); c(sd = sqrt(v), 1 - sqrt(pmax(1 - rho^2, 0)))
})
rownames(ceil) <- c("sd", P)
say("  %-14s %s\n", "", paste(sprintf("%13s", READOUTS), collapse = ""))
say("  %-14s %s\n", "readout sd", paste(sprintf("%13.4f", ceil["sd", ]), collapse = ""))
for (nm in CFC_PARAMS) say("  %-14s %s\n", nm, paste(sprintf("%12.1f%%", 100 * ceil[nm, ]), collapse = ""))
Gall <- G[, READOUTS, drop = FALSE]
Sall <- Sig - Sig %*% Gall %*% solve(t(Gall) %*% Sig %*% Gall) %*% t(Gall) %*% Sig
shr_all <- 1 - sqrt(pmax(diag(Sall), 0)) / sqrt(diag(Sig))
say("  all %d readouts observed perfectly at once: %s\n", length(READOUTS),
    paste(sprintf("%s %.1f %%", CFC_PARAMS, 100 * shr_all[CFC_PARAMS]), collapse = ", "))
say("    corr(u_hs, pump_hs_gcm2) %+.3f -> %+.3f\n", cr(Sig, "u_hs", "pump_hs_gcm2"), cr(Sall, "u_hs", "pump_hs_gcm2"))

out <- list(
  provenance = list(driver = CFC_DRIVER, commit = CFC_COMMIT, run = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                    mode = CFC_MODE, mode_file = ccx_mode_file(CFC_MODE),
                    mode_md5 = unname(tools::md5sum(ccx_mode_file(CFC_MODE))),
                    atm_file = CFC_ATM_FILE, atm_sha256 = tools::sha256sum(CFC_ATM_FILE)[[1]], gas = CFC_GAS,
                    solubility = "Warner & Weiss 1985 Table 5 via Orr et al. 2017 GMD Table 2",
                    schmidt = "Wanninkhof 2014 Table 1 via Orr et al. 2017 GMD Table 1",
                    obs = "Willey et al. 2004 GRL 31:L01303, abstract", read_t = CFC_READ_T, t0 = CFC_T0,
                    salinity = SAL, nsub = CFC_NSUB, fd_rel = CFC_FD_REL, step = "md$hess_eps", rng = "none",
                    units = "inventory mol CFC-11; sensitivities per unit of the unconstrained coordinate u"),
  gates = list(C = gc, L = gl, S = gsv, V = gv, D = gD, K = gK),
  surface = bn[S0$O[surfK]], base = r0, inv0 = I0, readouts0 = q0, t_box = t_box,
  k_check = read_inv(rk, CFC_READ_T) / I0, G = G, sd_pred = sd_pred, s_obs = s_obs, cov_update = upd,
  ceiling = ceil, perfect_all = Sall)
saveRDS(out, paste0(CFC_STEM, ".rds"))
say("\nwrote %s.rds\n", CFC_STEM)
