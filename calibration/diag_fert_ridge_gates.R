# ⛔ HELD-ERA RECORD (2026-10-12). This script builds its Joos PD100 by hand with the climate HELD
# (`gmst <- gmst[1]`), which is no longer the live protocol: card 5, gate L, the scorecard and
# diag_joos_irf.R now run R/joos_irf.R ccx_pd100() with the climate FREE (Marcus 2026-10-12, "free
# everywhere"; scope "Builder + live consumers"). Its hand-held table also leaves the observed-SST
# columns running and restarts T_deep at 0 -- both FIXED in the builder (ccx_pulse_forcings,
# ccx_pulse_ref_state), NOT here. Kept unconverted as the record of what it printed: do not quote its
# IRFs or partitions as the canonical's.
# =====================================================================
# diag_fert_ridge_gates.R -- THE FERTILIZATION RIDGE AGAINST GATES 4, 7 AND 12
#                            AT ONCE, PLUS FACE AND THE LIKELIHOOD.  (2026-08-25)
#
# diag_af_trend_levers.R answered Marcus's gate-4 question and the answer was
# not the lever he named first. Of the six mechanisms he listed, five are
# already in the model and one -- ocean stratification cutting vertical
# exchange -- is genuinely absent (kz is a constant, R/model.R:846). But the
# scan says the missing one is NOT the binding constraint:
#
#   * kz moves the AF LEVEL hard (0.490 at 2000 -> 0.415 at 9000) and its TREND
#     not at all (+-0.0002/decade across that whole range). A time-varying kz
#     would act only through the level, and closing the +0.0156/decade gap that
#     way needs the level to move ~0.11, i.e. kz to fall by more than its own
#     value. Stratification cannot deliver this.
#   * The Revelle buffer is ALREADY the largest working contributor (+0.0084).
#   * Traveling ALONG the (beta_max, fert_k) ridge at fixed present-day NPP
#     enhancement moves the trend by +0.0171 -- more than the whole gap -- and
#     simultaneously takes the decadal sd from 0.019 to 0.040 (target 0.048),
#     r(obs) from -0.06 to +0.57, and the RMSE to its best value.
#
# So gate 4's failure is a statement about the SATURATION SHAPE of CO2
# fertilization, along the one direction the historical CO2 integral cannot
# identify. That is the same direction FACE speaks to, and the same direction
# every pinned probe has run away down.
#
# THIS FILE ASKS MARCUS'S SECOND QUESTION: fix gate 4 first, then see how 7 and
# 12 respond. For each cell on the ridge it reports, from ONE parameter vector:
#
#   GATE 4   AF level, decadal sd, decadal trend, r and RMSE against GCB
#   GATE 7   2015-2024 land and ocean sinks in GCB sigmas
#   GATE 12  time-integrated Joos IRF at TH 20/50/100, PD100 protocol
#   FACE     the predicted 400 -> 564 ppm NPP response, which is how Marcus's
#            2026-08-25 criterion (shape and realistic limits, not exact
#            numbers) actually bites on this ridge
#   logL     the total, so the LIKELIHOOD COST of each cell is visible. A cell
#            that fixes a gate and costs hundreds of log-units is not adoptable
#            by fiat -- it is a REFIT proposal, and the cost is what says so.
#
# NOT A REFIT. Every other parameter is frozen at the arm-N mode, so all costs
# here are UPPER BOUNDS -- memory ccx_seas_q10_ridge measured beta_max/fert_k
# absorbing 85 % of exactly this kind of frozen cost for q10, and here it is
# those two that are being moved, so the rest of the vector has not been given
# its chance to respond. The RANKING is what this establishes.
#
# Usage:  Rscript calibration/diag_fert_ridge_gates.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

FR_MODE_FILE <- ccx_mode_file()
FR_YEARS     <- c(1750, 2024)
FR_AF_WIN    <- c(1959, 2024)
FR_DECADES   <- c(1960, 1970, 1980, 1990, 2000, 2010, 2020)
FR_SINK_WIN  <- c(2015, 2024)
FR_GCB_LAND  <- 2.36; FR_GCB_OCEAN <- 3.22
FR_CHI_NOW   <- 420           # ppm, the enhancement held fixed along the ridge
FR_FACE_AMB  <- 400; FR_FACE_ENR <- 0.41    # matches diag_face_prior_for_beta_max.R
FR_KGRID     <- c(60, 90, 120, 180, 250, 400)
OUTDIR       <- ccx_path("calibration", "output", "fert_ridge_gates")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

GtC_PER_PPM <- ccx_const("GtC_PER_PPM")
CHI0        <- ccx_const("CO2_PI_PPM")

gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$historical)
g59 <- gcb[gcb$year >= FR_AF_WIN[1] & gcb$year <= FR_AF_WIN[2], ]
af_obs <- vapply(FR_DECADES, function(d) { k <- g59$year >= d & g59$year <= min(d + 9, FR_AF_WIN[2])
  sum(g59$atm_growth[k]) / sum((g59$fossil + g59$luc)[k]) }, numeric(1))
AF_OBS_ALL <- sum(g59$atm_growth) / sum(g59$fossil + g59$luc)
AF_OBS_SD  <- stats::sd(af_obs)
AF_OBS_TR  <- unname(stats::coef(stats::lm(af_obs ~ FR_DECADES))[2]) * 10

md <- readRDS(FR_MODE_FILE)
ccx_require_param_set(md, "the fertilisation-ridge gate diagnostic")
P0 <- ccx_default_params()
for (n in intersect(names(P0), CCX_PARAM_NAMES)) P0[[n]] <- md$par_mode[[n]]
P0 <- ccx_set_enso(P0, md$par_mode)
P0$pump_mode  <- md$pump_mode
ERR0 <- list(sigma_d14c = md$par_mode$sigma_d14c, rep_dC = md$par_mode$rep_dC,
             grad_off_co2 = md$par_mode$grad_off_co2, grad_off_d13c = md$par_mode$grad_off_d13c)
LUC0 <- md$par_mode$luc_scale; BOMB0 <- md$par_mode$bomb_total
OBS  <- ccx_prepare_obs()

d_now <- FR_CHI_NOW - CHI0
ENH0  <- P0$beta_max * d_now / (P0$fert_k + d_now)

Rface <- function(bm, K, a = FR_FACE_AMB, e = FR_FACE_AMB * (1 + FR_FACE_ENR)) {
  en <- function(chi) { d <- chi - CHI0; bm * d / (K + d) }
  (1 + en(e)) / (1 + en(a)) - 1
}

# ---- gates 4 and 7, plus logL, from one historical run ---------------
fr_hist <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", FR_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = BOMB0, luc_scale = LUC0)
  o  <- ccx_run_fast(sp, F)$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  atm  <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2 * GtC_PER_PPM, xout = bnd, rule = 2)$y
  grow <- diff(atm)
  el <- ccx_forcing_eluc_annual(F)
  ef <- stats::aggregate(list(efoss = F$e_foss_NH + F$e_foss_SH),
                         by = list(year = F$year), FUN = mean)
  luc <- el$eluc[match(yrs, el$year)]; foss <- ef$efoss[match(yrs, ef$year)]
  af <- function(k) sum(grow[k]) / sum((foss + luc)[k])
  kw <- yrs >= FR_AF_WIN[1] & yrs <= FR_AF_WIN[2]
  dec <- vapply(FR_DECADES, function(d) af(yrs >= d & yrs <= min(d + 9, FR_AF_WIN[2]) & kw), numeric(1))
  st <- ccx_loglik(o, OBS, ERR0, luc = el, deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)
  # GATE 7 -- the SAME construction as diag_design_gates_at_mode.R's dg_gate7
  # (which agrees with diag_app_params.R's independent reconstruction): land is
  # GROSS, i.e. d(land_C)/dt PLUS E_LUC, because GCB's land_sink column is the
  # residual sink alone. Taken from the run's own stocks rather than from the
  # flux trace -- the trace re-evaluates ccx_deriv once per month in R and is
  # ~50x slower, and using a second construction here would risk disagreeing
  # with the gate this file is scored against.
  stock <- function(v) diff(stats::approx(o$t, v, xout = bnd, rule = 2)$y)
  ks <- yrs >= FR_SINK_WIN[1] & yrs <= FR_SINK_WIN[2]
  list(af = af(kw), dec = dec,
       sd = stats::sd(dec), tr = unname(stats::coef(stats::lm(dec ~ FR_DECADES))[2]) * 10,
       r = stats::cor(dec, af_obs), rmse = sqrt(mean((dec - af_obs)^2)),
       land = mean((stock(o$land_C) + luc)[ks]), ocean = mean(stock(o$ocean_C)[ks]),
       logL = sum(unlist(st)), sp = sp)
}

# ---- gate 12, PD100, exactly the protocol in diag_joos_irf.R ---------
fr_irf <- function(p, spin) {
  Fh <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14,
                          bomb_total_kmol = BOMB0, luc_scale = LUC0)
  sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, Fh)$state
  Ff <- suppressWarnings(ccx_build_forcing("historical",
        c(JOOS_REF_YEAR, JOOS_REF_YEAR + 310), prod_c14 = spin$prod_c14,
        bomb_total_kmol = 0, luc_scale = LUC0))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
               "c14_bomb", "c14_nuclear")) Ff[[cc]] <- 0
  Ff$gmst <- Ff$gmst[1]
  o <- ccx_irf_pd(sp_ref, ccx_hold_forcing(sp_ref, Ff))
  k <- o$t >= 0
  tt <- o$t[k]; vv <- o$irf[k]
  vapply(JOOS_T4$th, function(th) { kk <- tt <= th
    sum(diff(tt[kk]) * (utils::head(vv[kk], -1) + utils::tail(vv[kk], -1)) / 2) }, numeric(1))
}

cat(sprintf("\n=== THE FERTILISATION RIDGE AGAINST GATES 4, 7, 12 ===\n"))
cat(sprintf("mode arm %s: beta_max %.4f  fert_k %.1f  (logpost %.2f)\n",
            CCX_MODE_CANONICAL, P0$beta_max, P0$fert_k, md$logpost))
cat(sprintf("ridge held at enh(%d ppm) = %.4f; beta_max solved for each fert_k\n", FR_CHI_NOW, ENH0))
cat(sprintf("TARGETS: AF %.3f, dec sd %.4f, trend %+.4f | land %.2f+-0.50, ocean %.2f+-0.40 | IRF floors %s\n\n",
            AF_OBS_ALL, AF_OBS_SD, AF_OBS_TR, FR_GCB_LAND, FR_GCB_OCEAN,
            paste(JOOS_T4$lo, collapse = "/")))

cells <- c(list(list(K = P0$fert_k, lab = "MODE")),
           lapply(FR_KGRID, function(K) list(K = K, lab = "")))
res <- list()
cat(sprintf("%7s %8s %6s | %7s %8s %6s %6s | %6s %6s | %5s %5s %5s | %6s | %9s\n",
            "fert_k", "beta_max", "FACE", "AF", "dec sd", "trend", "r", "land", "ocean",
            "TH20", "TH50", "TH100", "d logL", ""))
for (ce in cells) {
  K <- ce$K; p <- P0; p$fert_k <- K; p$beta_max <- ENH0 * (K + d_now) / d_now
  if (p$beta_max > 3) { cat(sprintf("%7.1f %8.3f  beta_max exceeds the [0,3] bound -- skipped\n", K, p$beta_max)); next }
  h <- fr_hist(p); ir <- fr_irf(p, h$sp)
  if (ce$lab == "MODE") L0 <- h$logL
  res[[length(res) + 1L]] <- list(K = K, beta_max = p$beta_max, face = Rface(p$beta_max, K),
                                  af = h$af, sd = h$sd, tr = h$tr, r = h$r, rmse = h$rmse,
                                  land = h$land, ocean = h$ocean, irf = ir, logL = h$logL)
  cat(sprintf("%7.1f %8.3f %5.1f%% | %7.3f %8.4f %+6.4f %+6.2f | %+5.2fs %+5.2fs | %5.2f %5.2f %5.2f | %+6.1f | %s\n",
              K, p$beta_max, 100 * Rface(p$beta_max, K), h$af, h$sd, h$tr, h$r,
              (h$land - FR_GCB_LAND) / LIK_GCB_LAND_SD, (h$ocean - FR_GCB_OCEAN) / LIK_GCB_OCEAN_SD,
              ir[1], ir[2], ir[3], h$logL - L0, ce$lab))
}
cat(sprintf("%7s %8s %5s  | %7.3f %8.4f %+6.4f %6s | %+5.2fs %+5.2fs | %5.1f %5.1f %5.1f |\n",
            "TARGET", "--", "--", AF_OBS_ALL, AF_OBS_SD, AF_OBS_TR, "--", 0, 0,
            JOOS_T4$lo[1], JOOS_T4$lo[2], JOOS_T4$lo[3]))
cat("\n  FACE column = predicted 400 -> 564 ppm NPP response. Marcus 2026-08-25: the\n")
cat("  literature's RANGE is the constraint (mature forests 0-10 %, plantation-\n")
cat("  weighted synthesis 21.8-23 %), not any single number.\n")
cat("  d logL is FROZEN-VECTOR and therefore an UPPER BOUND on the true cost.\n")

saveRDS(list(res = res, mode = list(beta_max = P0$beta_max, fert_k = P0$fert_k, logpost = md$logpost),
             targets = list(af = AF_OBS_ALL, sd = AF_OBS_SD, tr = AF_OBS_TR,
                            land = FR_GCB_LAND, ocean = FR_GCB_OCEAN, irf_lo = JOOS_T4$lo),
             enh0 = ENH0, chi_now = FR_CHI_NOW),
        file.path(OUTDIR, "fert_ridge_gates.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "fert_ridge_gates.rds")))
