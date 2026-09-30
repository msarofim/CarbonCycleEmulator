# =====================================================================
# diag_alignment_screen.R -- HOW FAR CAN THE LAND BE BROUGHT INTO LINE WITH WHAT
# WE KNOW ABOUT POOLS, FLUXES AND FERTILISATION, AND WHAT DOES THE RECORD CHARGE?
# (CHANGELOG 2026-09-30 g; Marcus 2026-09-30 item 6: "once 1-4 are implemented,
# do one more check to see how we can bring parameters and model responses into
# better alignment with what we understand the size of pools and fluxes and
# fertilization responses to be.")
#
# STRUCTURE: arm A + the inert soil pool as a state box, label hilda_csl3v0kai.
# CONTROL: the (v) D carve-out re-fit (tau 500, 11 names rebalanced;
# tau_soil_slow_profile_fixedstock_stock8053_20260929.rds), rescored under the
# label (the proxy's exchanging share 0.040265 vs the label's 0.05 x (1 - f)).
#
# TWO PARTS.
#  (1) A SCORECARD, for the control and every arm: every pool (ccx_stock_readout),
#      modern NPP, the historical sinks and E_LUC vs GCB, bulk 0-1 m soil D14C vs
#      Shi 2020, the fertilisation RESPONSES (not parameters) vs the literature,
#      q10, and the SSP5-8.5 land-carbon windows vs Koven 2022.
#  (2) A JOINT SCREEN: the best-supported literature RESPONSES enter as SOFT
#      constraints (Gaussian log-penalties with the literature's own sd) and the
#      11 rebalanced names are re-optimised (NM). ⚠ A SCREEN, NOT AN OBJECTIVE
#      CHANGE, and NOT THE REFIT (which waits, Marcus 09-30): it asks what
#      alignment COSTS the record and WHO pays.
#      Constraints (methodological choices, stated):
#        KEENAN  CO2-driven GPP gain 1981 -> 2020, +13.5 +/- 3.5 % (Keenan 2023 NCC,
#                abstract; 09-28 note row 9) -- observational; end-points are the
#                control run's own annual-mean CO2 in those years.
#        G564    400 -> 564 ppm gain, +16.9 +/- 6.2 % (CMIP6 1pctCO2-bgc GPP, 16 ESMs,
#                our extraction; Walker 2021 theory +17 %, FACE +18-21 % agree).
#        NPP     modern NPP 2001-2023, 56.1 +/- 7.75 GtC/yr (the ruled option-4 row,
#                data/obs_npp_modern_target.rds).
#      ⚠ GPP vs NPP: the gains are GPP numbers applied to CCX's NPP factor
#        (constant CUE assumed; 09-28 note caveat 1). The 2x and 4x gains are
#        reported as OUT-OF-SAMPLE CHECKS, not constrained (same models as G564).
#      Arms: J1 fert (KEENAN + G564); J2 = J1 + NPP; J3 = J2 + NPP_GLOBAL_PI free
#      (option 4); J4 = NPP + NPP_GLOBAL_PI free only (option 4 alone).
# Reported: d_loglik on the RECORD ONLY (the NPP row removed), per-stream
# changes, parameter moves, the scorecard, and the futures of every vector.
# ⚠ Costs are UPPER bounds (NM on 11 of 29, +1). No RNG.
# USAGE: Rscript calibration/diag_alignment_screen.R   (frozen copy; BLAS pinned;
#        AS_SMOKE=1 for a smoke: maxit 10, one arm)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source("calibration/lib_design_gates.R")          # dg_annual_sinks()
AS_DRIVER <- "calibration/diag_alignment_screen.R"
AS_TAG    <- "alignment_screen"
AS_DATE   <- format(Sys.Date(), "%Y%m%d")
AS_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
AS_STRUCT <- "hilda_csl3v0kai"
AS_CTRL_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_stock8053_20260929.rds")
AS_CTRL_VALUE   <- 500
AS_FEX_PROXY    <- 0.8053         # the proxy's exchanging fraction in that profile (09-29 v D)
AS_PREV   <- ccx_path("outputs", "diagnostics", "npp0_scan_20260929.csv")
AS_FREE11 <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
AS_KEENAN <- c(y0 = 1981, y1 = 2020, mean = 0.135, sd = 0.035)
AS_G564   <- c(c0 = 400, c1 = 564, mean = 0.169, sd = 0.062)
AS_CHECK  <- list(g2x = c(mean = 0.429, sd = 0.162), g4x = c(mean = 0.762, sd = 0.310))  # CMIP6 GPP, out-of-sample
AS_SHI    <- c(mean = -244, sd = 48, year = 2000)       # Shi 2020 Table 1, 0-1 m bulk
AS_KOVEN  <- list(w = list(c(2015L, 2100L), c(2100L, 2200L), c(2200L, 2300L)),
                  mean = c(264, -29, -178), sd = c(172, 264, 251))   # Koven 2022 SSP5-8.5 (09-29 notes)
AS_LIT_POOLS <- c(vegetation_AR6 = 450, soil_0_1m_JJ = 1502, soil_0_1m_Shi = 1848, soils_AR6_nonpf = 1700)
AS_GCB_WIN <- list(c(1960L, 2023L), c(2010L, 2023L))
AS_NPP0_BOUNDS <- c(0.70, 1.10)   # NPP_GLOBAL_PI scale box for J3/J4 (the 09-29 k scan's range)
AS_ARMS <- list(J1 = list(fert = TRUE,  npp = FALSE, npp0 = FALSE),
                J2 = list(fert = TRUE,  npp = TRUE,  npp0 = FALSE),
                J3 = list(fert = TRUE,  npp = TRUE,  npp0 = TRUE),
                J4 = list(fert = FALSE, npp = TRUE,  npp0 = TRUE),
                # + 09-30 (g), added while J1-J4 ran: the FUTURE only reached Koven's band with
                # literature fertilisation AND q10 2.0 (09-29 v B, FROZEN); these price that
                # combination on the record. q10 PINNED at its prior centre (2.0), not penalised.
                J5 = list(fert = TRUE,  npp = FALSE, npp0 = FALSE, pin = c(q10 = 2.0)),
                J6 = list(fert = TRUE,  npp = TRUE,  npp0 = TRUE,  pin = c(q10 = 2.0)))
# + 09-30 (g), after J1-J4: the GROSS LAND LOOP. ra_ratio (Ra/NPP cycled THROUGH the
# vegetation pool; 0 = no gross loop, the literature Ra/NPP is an UPPER BOUND -- Marcus
# 2026-08-12, R/model.R) is FREE in [0, AS_GPP_PI / NPP0 - 1]: the AR6 preindustrial GPP
# caps the gross loop. HYPOTHESIS: the land's early bomb-14C uptake scales ~ NPP x (1 +
# ra_ratio), so the record's NPP pull (the NH bomb row, 09-29 k) is a pull on GROSS
# exchange, and a gross loop lets NPP fall to the observed ~56 cheaply.
AS_ARMS$G1 <- list(fert = FALSE, npp = TRUE,  npp0 = TRUE, ra = TRUE)   # NPP row + NPP0 + ra free
AS_ARMS$G2 <- list(fert = FALSE, npp = FALSE, npp0 = TRUE, ra = TRUE)   # the record alone
AS_ARMS$G3 <- list(fert = TRUE,  npp = TRUE,  npp0 = TRUE, ra = TRUE)   # everything
AS_GPP_PI <- 113    # GtC/yr, AR6 WG1 Fig. 5.12 preindustrial GPP, as recorded in R/constants.R (NPP_GLOBAL_PI source)
# + 09-30 (k): D3 ALONE -- the GCB imbalance allocation (R/likelihood.R LIK_IMB_*; CHANGELOG
# 09-30 i/j; predictions P-D3-1..4 registered in notes/prereg_2026-09-30c_nonco2_drivers_imbalance.md
# at 40ca12d, BEFORE this arm ran). The two shares are EXTRA COORDINATES, stick-broken so the
# simplex needs no bound: s_land = plogis(x1), s_ocean = (1 - s_land) * plogis(x2). The ruled prior
# is FLAT on the simplex, so the arm maximises its own #14 likelihood over it (no Jacobian: a
# flat-prior MAP on the natural scale is the ML). `imb` is the I(t) treatment, `cement` whether
# GCB's cement sink is allocated with it -- both PENDING Marcus, so the screen PRICES them.
# ⚠ Compare D3 arms with the control on the COMMON rows (everything except gcb_land_sink /
# gcb_ocean_sink, whose targets the arm moves), never on the arm's own objective alone.
AS_ARMS$D3s  <- list(fert = FALSE, npp = FALSE, npp0 = FALSE, imb = "smooth", cement = FALSE)
AS_ARMS$D3c  <- list(fert = FALSE, npp = FALSE, npp0 = FALSE, imb = "const",  cement = FALSE)
AS_ARMS$D3sc <- list(fert = FALSE, npp = FALSE, npp0 = FALSE, imb = "smooth", cement = TRUE)
AS_IMB_ROWS    <- c("gcb_land_sink", "gcb_ocean_sink")
AS_IMB_PREVIEW <- ccx_path("outputs", "diagnostics", "imb_alloc_preview_20260930.rds")   # start shares
AS_ENH_C       <- 410      # ppm, the enhancement P-D3-2 reads (CHANGELOG 09-30 d's shape-row anchor)
AS_PD3_ENH_TOL <- 0.05     # P-D3-2: enh(410) may not FALL by more than this fraction
AS_PD3_OCN_MIN <- 0.05     # P-D3-3: s_ocean above this
AS_PD3_FUT_TOL <- 20       # P-D3-4: |d SSP5-8.5 2300 CO2| below this (ppm)
AS_PD3_ROW_MIN <- 8        # P-D3-1: the two GCB rows gain at least this (the fixed-vector floor)
AS_ONLY   <- Sys.getenv("AS_ONLY", "J1,J2,J3,J4")          # which arms this process runs
AS_ARMS   <- AS_ARMS[strsplit(AS_ONLY, ",")[[1]]]
stopifnot(!anyNA(names(AS_ARMS)))
AS_MAXIT  <- 3000L
AS_ID_TOL <- 1e-3                 # the label vs the proxy share differ by 2e-5 in f; the (v) D cost of f 0 -> 0.195 was 4.4
AS_CORES  <- 4L
AS_SPLICE <- c(ssp585 = FALSE, vvH = TRUE)
AS_SMOKE  <- identical(Sys.getenv("AS_SMOKE"), "1")
if (AS_SMOKE) { AS_TAG <- paste0(AS_TAG, "_smoke"); AS_MAXIT <- 10L; AS_ARMS <- AS_ARMS[1] }
AS_TAG    <- paste0(AS_TAG, Sys.getenv("AS_TAG_SUFFIX", ""))
AS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", AS_TAG, AS_DATE))
COMMIT    <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
DIRTY     <- tryCatch(length(system("git status --porcelain -- R src data calibration", intern = TRUE)) > 0, error = function(e) NA)

# ---- the objective's pieces ---------------------------------------------------
md <- readRDS(ccx_mode_file(AS_MODE)); invisible(ccx_apply_pins(md$pins))
iF <- match(AS_FREE11, md$param_names); stopifnot(!anyNA(iF))
cp <- readRDS(AS_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == AS_CTRL_VALUE)]]
base_params <- function(npp_row) {
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, AS_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
  for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]
  # the proxy scaled litter_slow_frac by AS_FEX_PROXY; the label carves out itself
  bp$litter_slow_frac <- ctrl$over$litter_slow_frac / AS_FEX_PROXY
  if (npp_row) bp$npp_row <- 1L
  bp
}
bp0 <- base_params(FALSE)
stopifnot(isTRUE(ccx_inert_on(bp0)), abs(bp0$litter_slow_frac - 0.05) < 1e-12)
prev <- utils::read.csv(AS_PREV, check.names = FALSE); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in AS_FREE11) p0[[n]] <- r1[[n]]
for (n in AS_FREE11) p0[[n]] <- ctrl$par[[n]]
u_ctrl <- ccx_par_to_unc(unlist(p0)[md$param_names])

CONST0 <- CCX_CONSTANTS
set_npp0 <- function(s) { cc <- CONST0; cc$NPP_GLOBAL_PI$value <- CONST0$NPP_GLOBAL_PI$value * s
  assign("CCX_CONSTANTS", cc, envir = globalenv()); invisible(s) }

enh  <- function(b, K, c) b * (c - ccx_const("CO2_PI_PPM")) / (K + c - ccx_const("CO2_PI_PPM"))
gain <- function(b, K, c0, c1) (1 + enh(b, K, c1)) / (1 + enh(b, K, c0)) - 1

# ---- the scorecard of one vector ------------------------------------------------
gcb <- readRDS(ccx_path("data", "gcb_budget.rds"))$budget
tg_npp <- ccx_npp_modern_target()
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!AS_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
params_of <- function(u, npp0 = 1, ra = 0) { set_npp0(npp0); pv <- ccx_unc_to_par(u)
  p <- ccx_overlay_par(bp0, pv); p$ra_ratio <- ra; list(p = p, pv = pv) }
score <- function(u, npp0 = 1, keen_c = NULL, ra = 0) {
  q <- params_of(u, npp0, ra); p <- q$p; pv <- q$pv
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  st <- ccx_stock_readout(sp$y, sp$aux)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  r <- ccx_run_fast(sp, F); r$F <- F
  n <- r$npp; kn <- floor(n$t) >= tg_npp$win[1] & floor(n$t) <= tg_npp$win[2]
  a <- dg_annual_sinks(r); el <- ccx_forcing_eluc_annual(F)
  sinks <- unlist(lapply(AS_GCB_WIN, function(w) { k <- a$year >= w[1] & a$year <= w[2]; kg <- gcb$year >= w[1] & gcb$year <= w[2]
    ke <- el$year >= w[1] & el$year <= w[2]; tag <- sprintf("%d_%d", w[1], w[2])
    stats::setNames(c(mean(a$land[k]) - mean(gcb$land_sink[kg]), mean(a$ocean[k]) - mean(gcb$ocean_sink[kg]),
                      mean(el$eluc[ke]) - mean(gcb$luc[kg])), paste0(c("dLand_", "dOcean_", "dEluc_"), tag)) }))
  co2y <- tapply((r$out$co2_NH + r$out$co2_SH) / 2, floor(r$out$t), mean)
  # bulk 0-1 m soil D14C at the end of AS_SHI year: soil_fast + soil_slow + soil_inert, both hemispheres
  F2 <- ccx_build_forcing("historical", c(1750, AS_SHI[["year"]]), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                          luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  y2 <- ccx_run_fast(sp, F2)$state
  soil <- unlist(lapply(HEMIS, function(h) unlist(sp$aux$idx[[h]][c("soil_fast", "soil_slow", CCX_LAND_INERT)])))
  soil_d14 <- 1000 * (sum(y2[soil, "C14"]) / sum(y2[soil, "C"]) - 1)
  fut <- lapply(names(AS_SPLICE), function(s) {
    rr <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, 2300L), emissions = emis(s), bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale))
    o <- rr$out; yr <- floor(o$t); land <- tapply(o$land_C, yr, mean); co2 <- tapply((o$co2_NH + o$co2_SH) / 2, yr, mean)
    dl <- vapply(AS_KOVEN$w, function(w) land[[as.character(w[2])]] - land[[as.character(w[1])]], 0)
    stats::setNames(c(co2[["2300"]], dl, land[["2300"]] / land[["1750"]]), paste0(s, c("_co2_2300", "_dL1521", "_dL2122", "_dL2223", "_landxPI"))) })
  b <- pv$beta_max; K <- pv$fert_k
  kc <- if (is.null(keen_c)) co2y[as.character(AS_KEENAN[c("y0", "y1")])] else keen_c
  set_npp0(1)
  npp_mod <- mean(n$npp_NH[kn] + n$npp_SH[kn])
  c(st, npp_modern = npp_mod, npp0 = CONST0$NPP_GLOBAL_PI$value * npp0, ra_ratio = ra,
    gpp_pi = CONST0$NPP_GLOBAL_PI$value * npp0 * (1 + ra), gpp_modern = npp_mod * (1 + ra), sinks,
    soil_d14c_2000 = soil_d14, keenan_c0 = unname(kc[1]), keenan_c1 = unname(kc[2]),
    # unname(): gain() inherits the year names of its CO2 end-points (smoke 09-30)
    g_keenan = unname(gain(b, K, kc[[1]], kc[[2]])), g_400_564 = unname(gain(b, K, AS_G564[["c0"]], AS_G564[["c1"]])),
    g_2x = unname(enh(b, K, 2 * ccx_const("CO2_PI_PPM"))), g_4x = unname(enh(b, K, 4 * ccx_const("CO2_PI_PPM"))),
    beta_max = unname(b), fert_k = unname(K), q10 = unname(pv$q10), luc_scale = unname(pv$luc_scale), unlist(fut))
}

# ---- identity + the control's own scorecard ------------------------------------
lp0 <- ccx_make_logpost(base_params = bp0, by_stream = TRUE)
l_ctrl <- lp0(u_ctrl)
id_d <- as.numeric(l_ctrl) - ctrl$opt
stopifnot(abs(id_d) < AS_ID_TOL)
sc_ctrl <- score(u_ctrl)
KEEN_C <- sc_ctrl[c("keenan_c0", "keenan_c1")]          # fixed for every arm's penalty

pen_fert <- function(pv) stats::dnorm(gain(pv$beta_max, pv$fert_k, KEEN_C[[1]], KEEN_C[[2]]), AS_KEENAN[["mean"]], AS_KEENAN[["sd"]], log = TRUE) +
                         stats::dnorm(gain(pv$beta_max, pv$fert_k, AS_G564[["c0"]], AS_G564[["c1"]]), AS_G564[["mean"]], AS_G564[["sd"]], log = TRUE)

# D3 start shares: the fixed-vector optimum of the preview for this arm's treatment (09-30 i)
imb_start <- function(arm) {
  pv <- readRDS(AS_IMB_PREVIEW)$shares
  key <- paste0(toupper(arm$imb), if (isTRUE(arm$cement)) "_CEM" else "")
  r <- pv[pv$treat == key, ]; stopifnot(nrow(r) == 1L)
  sl <- min(max(r$s_land, 0.02), 0.98); rest <- min(max(r$s_ocean / (1 - sl), 0.02), 0.98)
  c(sl, rest)
}
one <- function(nm) {
  arm <- AS_ARMS[[nm]]
  lp <- ccx_make_logpost(base_params = base_params(arm$npp), by_stream = TRUE)
  # PINNED names (J5/J6): set in the start vector and removed from the free set
  u_start <- u_ctrl
  if (!is.null(arm$pin)) { pv0 <- as.list(ccx_unc_to_par(u_ctrl)); for (n in names(arm$pin)) pv0[[n]] <- arm$pin[[n]]
    u_start <- ccx_par_to_unc(unlist(pv0)[md$param_names]) }
  iF <- match(setdiff(AS_FREE11, names(arm$pin)), md$param_names)
  # D3 arms: the I(t) treatment is a GLOBAL the likelihood reads at call time; this runs in
  # a FORKED child (mclapply), so the assignment is this arm's alone.
  if (!is.null(arm$imb)) { assign("LIK_IMB_TREATMENT", arm$imb, envir = globalenv())
    assign("LIK_IMB_WITH_CEMENT", isTRUE(arm$cement), envir = globalenv()) }
  # extra coordinates after the free names: [NPP0 logit], [ra logit], [s_land logit, rest logit]
  nF <- length(iF); k_n0 <- if (arm$npp0) nF + 1L else NA_integer_
  k_ra <- if (isTRUE(arm$ra)) nF + as.integer(arm$npp0) + 1L else NA_integer_
  k_im <- if (!is.null(arm$imb)) nF + as.integer(arm$npp0) + as.integer(isTRUE(arm$ra)) + 1:2 else NA_integer_
  im_of <- function(x) if (!is.null(arm$imb)) stats::plogis(x[k_im]) else NULL        # (s_land, rest)
  set_im <- function(v) { e <- environment(lp); b <- get("base_params", envir = e)
    b$imb_share_land <- v[1]; b$imb_share_ocean_rest <- v[2]; assign("base_params", b, envir = e) }
  s_of  <- function(x) if (arm$npp0) AS_NPP0_BOUNDS[1] + diff(AS_NPP0_BOUNDS) * stats::plogis(x[k_n0]) else 1
  ra_of <- function(x, s) if (isTRUE(arm$ra)) (AS_GPP_PI / (CONST0$NPP_GLOBAL_PI$value * s) - 1) * stats::plogis(x[k_ra]) else 0
  set_ra <- function(r) { e <- environment(lp); b <- get("base_params", envir = e); b$ra_ratio <- r
    assign("base_params", b, envir = e) }
  obj <- function(x) {
    u <- u_start; u[iF] <- x[seq_along(iF)]
    s <- s_of(x); set_ra(ra_of(x, s)); if (!is.null(arm$imb)) set_im(im_of(x))
    set_npp0(s); w <- lp(u); set_npp0(1)
    if (!is.finite(w)) return(1e12)
    pen <- if (arm$fert) pen_fert(ccx_unc_to_par(u)) else 0
    -(as.numeric(w) + pen)
  }
  x0 <- c(u_start[iF], if (arm$npp0) stats::qlogis((1 - AS_NPP0_BOUNDS[1]) / diff(AS_NPP0_BOUNDS)),
          if (isTRUE(arm$ra)) stats::qlogis(0.05),      # start the gross loop small, not at 0 (logit)
          if (!is.null(arm$imb)) stats::qlogis(imb_start(arm)))   # the fixed-vector optimum (09-30 i)
  o <- stats::optim(x0, obj, method = "Nelder-Mead", control = list(maxit = AS_MAXIT))
  u <- u_start; u[iF] <- o$par[seq_along(iF)]
  s <- s_of(o$par); ra <- ra_of(o$par, s); set_ra(ra)
  im <- im_of(o$par); if (!is.null(im)) set_im(im)
  set_npp0(s); l1 <- lp(u); set_npp0(1)
  st <- attr(l1, "streams"); rec <- as.numeric(attr(l1, "loglik")) - (if ("npp_modern" %in% names(st)) st[["npp_modern"]] else 0)
  list(arm = nm, spec = arm, u = u, npp0 = s, ra_ratio = ra, conv = o$convergence, evals = o$counts[["function"]],
       imb_share = if (is.null(im)) c(land = NA_real_, ocean = NA_real_) else c(land = im[1], ocean = (1 - im[1]) * im[2]),
       loglik_common = sum(st[setdiff(names(st), c("npp_modern", AS_IMB_ROWS))]),
       loglik_record = rec, streams = st[setdiff(names(st), "npp_modern")],
       pen_fert = pen_fert(ccx_unc_to_par(u)), npp_row = if ("npp_modern" %in% names(st)) st[["npp_modern"]] else NA_real_,
       score = score(u, s, KEEN_C, ra))
}
res <- parallel::mclapply(names(AS_ARMS), one, mc.cores = AS_CORES, mc.preschedule = FALSE)
bad <- vapply(res, inherits, logical(1), "try-error"); if (any(bad)) { print(res[bad]); stop("fork failure") }
ref_rec <- as.numeric(attr(l_ctrl, "loglik")); ref_st <- attr(l_ctrl, "streams")

# ---- report --------------------------------------------------------------------
z <- function(x, m, s) (x - m) / s
sink(paste0(AS_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s%s, run %s; no RNG\n", AS_DRIVER, COMMIT, if (isTRUE(DIRTY)) " (DIRTY)" else "", format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  structure %s (inert pool f %.6f) at v0k basin 1; control = %s value %g, rescored under the label: d %.2e (tol %.0e)\n",
            AS_STRUCT, bp0$soil_inert_frac, basename(AS_CTRL_PROFILE), AS_CTRL_VALUE, id_d, AS_ID_TOL))
cat(sprintf("  NM maxit %d on {%s} (+ NPP_GLOBAL_PI scale in [%.2f, %.2f] for J3/J4); costs are UPPER bounds\n",
            AS_MAXIT, paste(AS_FREE11, collapse = ", "), AS_NPP0_BOUNDS[1], AS_NPP0_BOUNDS[2]))
cat(sprintf("  constraints: KEENAN %d->%d (CO2 %.1f->%.1f ppm) %+.3f +/- %.3f; G564 %+.3f +/- %.3f; NPP %.2f +/- %.2f (%d-%d)\n\n",
            AS_KEENAN[["y0"]], AS_KEENAN[["y1"]], KEEN_C[[1]], KEEN_C[[2]], AS_KEENAN[["mean"]], AS_KEENAN[["sd"]],
            AS_G564[["mean"]], AS_G564[["sd"]], tg_npp$centre, tg_npp$sd, tg_npp$win[1], tg_npp$win[2]))
S <- rbind(control = sc_ctrl, do.call(rbind, lapply(res, `[[`, "score"))); rownames(S) <- c("control", vapply(res, `[[`, "", "arm"))
cat("=== THE ARMS: record cost (likelihood WITHOUT the NPP row), penalties, moves ===\n")
cat(sprintf("  %-8s %10s %9s %9s %6s %6s %8s %8s %6s %6s %7s %6s %5s\n", "arm", "d_ll_rec", "pen_fert", "npp_row",
            "beta", "K", "NPP0", "NPPmod", "q10", "luc", "kz", "conv", "evals"))
cat(sprintf("  %-8s %+10.2f %9s %9s %6.3f %6.0f %8.1f %8.2f %6.3f %6.3f %7.0f %6s %5s\n", "control", 0, "-", "-",
            sc_ctrl[["beta_max"]], sc_ctrl[["fert_k"]], sc_ctrl[["npp0"]], sc_ctrl[["npp_modern"]], sc_ctrl[["q10"]], sc_ctrl[["luc_scale"]],
            ccx_unc_to_par(u_ctrl)$kz, "-", "-"))
for (r in res) cat(sprintf("  %-8s %+10.2f %9.2f %9s %6.3f %6.0f %8.1f %8.2f %6.3f %6.3f %7.0f %6d %5d\n", r$arm, r$loglik_record - ref_rec,
  r$pen_fert, if (is.na(r$npp_row)) "-" else sprintf("%.2f", r$npp_row), r$score[["beta_max"]], r$score[["fert_k"]], r$score[["npp0"]],
  r$score[["npp_modern"]], r$score[["q10"]], r$score[["luc_scale"]], ccx_unc_to_par(r$u)$kz, r$conv, r$evals))
# ---- D3 arms: like-for-like on the COMMON rows, and the pre-registered predictions ----
d3 <- Filter(function(r) !is.null(r$spec$imb), res)
if (length(d3)) {
  ref_common <- sum(ref_st[setdiff(names(ref_st), c("npp_modern", AS_IMB_ROWS))])
  enh_c <- enh(sc_ctrl[["beta_max"]], sc_ctrl[["fert_k"]], AS_ENH_C)
  cat("\n=== D3 ARMS (imbalance allocation; predictions P-D3-1..4 registered at 40ca12d) ===\n")
  cat(sprintf("  control: common-row loglik %.3f; GCB rows %+.2f (land) %+.2f (ocean) under #13; enh(%d) %.4f; luc_scale %.4f; SSP5-8.5 2300 %.1f ppm\n",
              ref_common, ref_st[["gcb_land_sink"]], ref_st[["gcb_ocean_sink"]], AS_ENH_C, enh_c, sc_ctrl[["luc_scale"]], sc_ctrl[["ssp585_co2_2300"]]))
  for (r in d3) {
    e_a  <- enh(r$score[["beta_max"]], r$score[["fert_k"]], AS_ENH_C)
    rows <- sum(r$streams[AS_IMB_ROWS]) - sum(ref_st[AS_IMB_ROWS])
    dfut <- r$score[["ssp585_co2_2300"]] - sc_ctrl[["ssp585_co2_2300"]]
    cat(sprintf("  %-5s I(t) %-6s cement %-5s | s_land %.3f s_ocean %.3f rest %.3f | d_ll common %+7.2f, own objective %+7.2f, GCB rows %+6.2f\n",
                r$arm, r$spec$imb, isTRUE(r$spec$cement), r$imb_share[["land"]], r$imb_share[["ocean"]], 1 - sum(r$imb_share),
                r$loglik_common - ref_common, r$loglik_record - ref_rec, rows))
    cat(sprintf("        enh(%d) %.4f (%+.1f %%), beta %.3f K %.0f, luc_scale %.4f, q10 %.3f, kz %.0f; SSP5-8.5 2300 %+.1f ppm; conv %d evals %d\n",
                AS_ENH_C, e_a, 100 * (e_a / enh_c - 1), r$score[["beta_max"]], r$score[["fert_k"]], r$score[["luc_scale"]], r$score[["q10"]],
                ccx_unc_to_par(r$u)$kz, dfut, r$conv, r$evals))
    v <- c(`P-D3-1 GCB rows gain >= floor` = rows >= AS_PD3_ROW_MIN,
           `P-D3-2 enh does not fall > tol` = e_a >= (1 - AS_PD3_ENH_TOL) * enh_c,
           `P-D3-3 s_ocean > min`           = r$imb_share[["ocean"]] > AS_PD3_OCN_MIN,
           `P-D3-4 |d 2300 CO2| < tol`      = abs(dfut) < AS_PD3_FUT_TOL)
    cat(sprintf("        %s\n", paste(sprintf("%s: %s", names(v), ifelse(v, "PASS", "FAIL")), collapse = "; ")))
  }
}
cat("\n=== WHO PAYS (record streams vs control, 8 largest |max|) ===\n")
D <- do.call(rbind, lapply(res, function(r) r$streams - ref_st)); rownames(D) <- vapply(res, `[[`, "", "arm")
big <- names(sort(apply(abs(D), 2, max), decreasing = TRUE))[1:min(8, ncol(D))]; print(round(D[, big, drop = FALSE], 2))
cat("\n=== SCORECARD: pools (PI, GtC) ===\n")
print(round(S[, c("vegetation", "soil_fast", "soil_slow", "soil_inert", "soil_total", "land_total", "ocean_total", "atmosphere")], 1))
cat(sprintf("  literature: vegetation %g (AR6 WG1 Fig 5.12, PI); soil 0-1 m %g (Jobbagy & Jackson 2000) / %g (Shi 2020); AR6 soils outside permafrost %g\n",
            AS_LIT_POOLS[["vegetation_AR6"]], AS_LIT_POOLS[["soil_0_1m_JJ"]], AS_LIT_POOLS[["soil_0_1m_Shi"]], AS_LIT_POOLS[["soils_AR6_nonpf"]]))
cat("\n=== SCORECARD: fluxes and radiocarbon (z where the literature gives a sd) ===\n")
print(round(cbind(S[, c("npp0", "npp_modern", "ra_ratio", "gpp_pi", "gpp_modern")], z_npp = z(S[, "npp_modern"], tg_npp$centre, tg_npp$sd),
                  S[, grep("^d(Land|Ocean|Eluc)_", colnames(S))], soil_d14c_2000 = S[, "soil_d14c_2000"],
                  z_shi = z(S[, "soil_d14c_2000"], AS_SHI[["mean"]], AS_SHI[["sd"]])), 3))
cat("\n=== SCORECARD: fertilisation RESPONSES (GPP literature applied to NPP) and q10 ===\n")
print(round(cbind(S[, c("g_keenan", "g_400_564", "g_2x", "g_4x")],
                  z_keenan = z(S[, "g_keenan"], AS_KEENAN[["mean"]], AS_KEENAN[["sd"]]), z_564 = z(S[, "g_400_564"], AS_G564[["mean"]], AS_G564[["sd"]]),
                  z_2x_oos = z(S[, "g_2x"], AS_CHECK$g2x[["mean"]], AS_CHECK$g2x[["sd"]]), z_4x_oos = z(S[, "g_4x"], AS_CHECK$g4x[["mean"]], AS_CHECK$g4x[["sd"]]),
                  q10 = S[, "q10"]), 3))
cat("\n=== SCORECARD: futures (SSP5-8.5 unspliced, vvH spliced; land-carbon windows GtC vs Koven 2022 +/- 1 sd) ===\n")
fc <- c("ssp585_co2_2300", "ssp585_dL1521", "ssp585_dL2122", "ssp585_dL2223", "ssp585_landxPI", "vvH_co2_2300", "vvH_landxPI")
print(round(cbind(S[, fc], zK1 = z(S[, "ssp585_dL1521"], AS_KOVEN$mean[1], AS_KOVEN$sd[1]),
                  zK2 = z(S[, "ssp585_dL2122"], AS_KOVEN$mean[2], AS_KOVEN$sd[2]), zK3 = z(S[, "ssp585_dL2223"], AS_KOVEN$mean[3], AS_KOVEN$sd[3])), 2))
cat("  (land x PI uses TOTAL land incl. the inert pool -- the ESM-style convention, CHANGELOG 09-30 f)\n")
sink()
S_df <- data.frame(row = rownames(S), S, check.names = FALSE,
                   provenance = sprintf("%s @%s; %s; control %s tau %g; NM %d; no RNG", AS_DRIVER, COMMIT, AS_STRUCT, basename(AS_CTRL_PROFILE), AS_CTRL_VALUE, AS_MAXIT))
utils::write.csv(S_df, paste0(AS_OUT, ".csv"), row.names = FALSE)
saveRDS(list(control = list(u = u_ctrl, score = sc_ctrl, logpost = as.numeric(l_ctrl), loglik = ref_rec, streams = ref_st),
             arms = res, constraints = list(keenan = AS_KEENAN, keenan_c = KEEN_C, g564 = AS_G564, npp = tg_npp[c("centre", "sd", "win")])),
        paste0(AS_OUT, ".rds"))
cat(sprintf("saved %s.{log,csv,rds}\n", AS_OUT))
