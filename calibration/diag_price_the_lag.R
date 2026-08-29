# =====================================================================
# diag_price_the_lag.R -- WHAT DOES `seas_lag_p` COST, WHO PAYS, AND DOES IT
#   BUY ANYTHING ON ITS OWN?
#
# PRE-REGISTERED: notes/prereg_2026-08-29d_price_the_lag.md, committed (1f3731c)
# BEFORE this file existed. Every gate below is copied from it unchanged.
# Do not edit a gate here without amending that note.
#
# WHY. 29c identified the pair as (gross, seas_lag_p): theta must reach 164.8 deg
# and the lag is the only free parameter that gets there, against a mode at
# 1.7677 -> 152.4 deg. But the lag is GLOBAL -- it moves the NH too -- and the
# fit chose 1.7677 against its own init of 2.25. Something is paying.
#
# ⚠ THE LAG BUYS NOTHING BY ITSELF AND THAT IS PRE-REGISTERED (Q2). At the mode
# the respiration channel is 0.0923 ppm against NEP's 1.3896, so rotating them
# moves the SUM by at most ~0.09. THE FLOOR moves; the NET does not. The lag
# opens the door; respiration walks through it; the gross sets the scale.
#
# ⚠ FROZEN COSTS ARE UPPER BOUNDS -- "the refit recovered 15-19x more than the
# frozen scan predicted" (handoff 08-25b sec.7). The CONDITIONAL is the price.
#
# ⚠ THE OFFSET IS -1.5805. NEVER QUOTE AN ABSOLUTE LOGPOST AGAINST THE MODE FILE.
#
# Usage:  Rscript calibration/diag_price_the_lag.R          # ~20 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PL_YEARS <- c(1750, 2024)
PL_SLICE <- c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_T_amp_SH")
PL_LAG   <- "seas_lag_p"
PL_FROZEN_GRID <- c(1.50, 1.7677, 1.90, 2.00, 2.10, 2.25, 2.40, 2.50, 2.75)
PL_ARM_LAGS    <- c(2.00, 2.25, 2.50)      # INCUMBENT is the mode's own lag
PL_MAXIT <- 1500; PL_RESTARTS <- 6; PL_RESTOL <- 0.02
# ---- Q0-Q6, copied from prereg 29d sec.2.
PL_Q0 <- c(total = 1.140, shland = 1.308, nep = 1.3896, resp = 0.0923,
           theta = 152.9, rspo = 1.93)
PL_Q0_TOL <- 0.01; PL_Q0_MOTOL <- 0.05
PL_Q0_NEP_MO <- 10.15; PL_Q0_RESP_MO <- 5.05
PL_Q1_NHSHARE <- 0.50                      # NH rows' share of the FROZEN cost at 2.25
PL_Q2_NETTOL  <- 0.05                      # frozen SH-land net stays within 5 % of 1.308
PL_Q3_TAMULT  <- 2.0                       # fitted seas_T_amp_SH below 2x the mode's
PL_Q4_CHEAP   <- 20; PL_Q4_PROHIB <- 100   # the price bands; 27n's lever cost -204/-35
PL_Q5_RSPO    <- 0.05                      # r_SPO improves by <= 5 % without respiration
PL_THETA_NEED <- 164.8                     # 29c, at the CMIP6 gross
PL_OBS_TOTAL <- 1.168; PL_OBS_LAND <- 0.683; PL_OBS_OCEAN <- 0.522
PL_A_SHIP  <- ccx_const("SEAS_NPP_AMP_SH")
PL_A_CMIP6 <- 0.94                         # ⚠ DIAGNOSTIC ONLY (Marcus authorisation 1)
PL_SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")
PL_NH_ROWS   <- c("co2_seasonal_MLO", "d13c_seasonal_MLO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
amp    <- function(v) 2 * sqrt(sum(v^2))
ang_mo <- function(v) 12 * ((atan2(v[1], v[2]) / (2 * pi)) %% 1)
sep_mo <- function(u, v) { d <- abs(ang_mo(u) - ang_mo(v)); min(d, 12 - d) }
sep_dg <- function(u, v) sep_mo(u, v) * 30
floor_of <- function(a, th) a * sin(pi * (180 - th) / 180)

md <- readRDS(ccx_mode_file()); ccx_adopt_mode_band(md)
pv0 <- ccx_mode_params(md)
u0  <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
i_slice <- match(PL_SLICE, CCX_PARAM_NAMES); i_lag <- match(PL_LAG, CCX_PARAM_NAMES)
i_q     <- match("q10", CCX_PARAM_NAMES)
stopifnot(!anyNA(i_slice), !is.na(i_lag), !(i_lag %in% i_slice), !(i_q %in% i_slice),
          CCX_PARAM_TABLE[[PL_LAG]]$tr == "id")
Q10_PIN <- pv0$q10; LAG0 <- pv0$seas_lag_p
cat(sprintf("mode %s | lag at the mode %.4f | q10 PINNED %.5f | slice (%d): %s\n",
            basename(ccx_mode_file()), LAG0, Q10_PIN, length(PL_SLICE),
            paste(PL_SLICE, collapse = ", ")))
cat(sprintf("shipped seas_npp_amp_SH %.4f | CMIP6 %.2f (⚠ DIAGNOSTIC ONLY)\n", PL_A_SHIP, PL_A_CMIP6))

obs <- ccx_prepare_obs()
pick   <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
obsv <- list(co2_SPO = vec_of(pick(obs, "co2_seas.SPO")), d13_SPO = vec_of(pick(obs, "d13_seas.SPO")),
             co2_MLO = vec_of(pick(obs, "co2_seas.MLO")), d13_MLO = vec_of(pick(obs, "d13_seas.MLO")))

# ⚠ bomb_total / luc_scale come off `pv`: seven of the 21 calibrated names are
# likelihood-side and absent from ccx_default_params(). Cost a run on 27h.
run_at <- function(pv, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", PL_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out; ms <- ccx_model_stats(o, obs)
  list(co2_SPO = vec_of(pick(ms, "co2_seas.SPO")), d13_SPO = vec_of(pick(ms, "d13_seas.SPO")),
       co2_MLO = vec_of(pick(ms, "co2_seas.MLO")), d13_MLO = vec_of(pick(ms, "d13_seas.MLO")),
       ll = unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                           grad_off_co2 = pv$grad_off_co2,
                                           grad_off_d13c = pv$grad_off_d13c),
                              luc = ccx_forcing_eluc_annual(F),
                              deep = sp$diagnostics$d14c_bottom_box,
                              ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)))
}
ratio_at <- function(b, st) {
  ao <- amp(obsv[[paste0("co2_", st)]]); do_ <- amp(obsv[[paste0("d13_", st)]])
  (amp(b[[paste0("d13_", st)]]) / amp(b[[paste0("co2_", st)]])) / (do_ / ao)
}
# the SH land geometry at a parameter vector: NEP and respiration as VECTORS
geom <- function(pv, mods = list()) {
  b   <- run_at(pv, mods)$co2_SPO
  nep <- b - run_at(pv, utils::modifyList(mods, list(seas_npp_amp_SH = 0)))$co2_SPO
  res <- b - run_at(pv, utils::modifyList(mods, list(seas_T_amp_SH   = 0)))$co2_SPO
  lnd <- b - run_at(pv, utils::modifyList(mods,
             list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0)))$co2_SPO
  th  <- sep_dg(nep, res)
  list(nep = amp(nep), nep_mo = ang_mo(nep), resp = amp(res), resp_mo = ang_mo(res),
       land = amp(lnd), land_mo = ang_mo(lnd), theta = th, floor = floor_of(amp(nep), th),
       total = amp(b), total_mo = ang_mo(b))
}
lp <- ccx_make_logpost(years = PL_YEARS,
                       base_params = local({ b <- ccx_default_params()
                                             b$pump_mode <- md$pump_mode; b }))
lp_gross <- function(A) ccx_make_logpost(years = PL_YEARS,
  base_params = local({ b <- ccx_default_params(); b$pump_mode <- md$pump_mode
                        b$seas_npp_amp_SH <- A; b }))
one <- lp(u0)
cat(sprintf("harness at u_mode %.4f vs stored %.4f -> offset %+.4f\n", one, md$logpost, one - md$logpost))

sep("0. Q0 -- METHOD CONTROL. If this fails, nothing below is read.")
t0 <- Sys.time()
b0 <- run_at(pv0); g0 <- geom(pv0)
got <- c(total = g0$total, shland = g0$land, nep = g0$nep, resp = g0$resp,
         theta = g0$theta, rspo = ratio_at(b0, "SPO"))
Q0 <- c()
for (n in names(PL_Q0)) {
  ok <- abs(got[[n]] - PL_Q0[[n]]) <= PL_Q0_TOL * abs(PL_Q0[[n]])
  cat(sprintf("  %-8s %9.4f  expected %9.4f  %s\n", n, got[[n]], PL_Q0[[n]],
              if (ok) "ok" else "⚠ MOVED")); Q0[n] <- ok
}
mo_ok <- abs(g0$nep_mo - PL_Q0_NEP_MO) <= PL_Q0_MOTOL && abs(g0$resp_mo - PL_Q0_RESP_MO) <= PL_Q0_MOTOL
cat(sprintf("  %-8s NEP %.2f mo, resp %.2f mo (expected %.2f / %.2f)  %s\n", "phases",
            g0$nep_mo, g0$resp_mo, PL_Q0_NEP_MO, PL_Q0_RESP_MO, if (mo_ok) "ok" else "⚠ MOVED"))
Q0["phases"] <- mo_ok
cat(sprintf("\n  Q0 -> %s\n", if (all(Q0)) "PASS" else "FAIL -- STOP"))
stopifnot(all(Q0))

sep("1. THE FROZEN PROFILE -- shape and WHO PAYS, not price")
cat(sprintf("  %8s %10s %8s %8s %8s %8s %8s | %9s %9s\n", "lag", "d logpost", "theta",
            "SH-land", "floor", "total", "r_SPO", "NH rows", "SH rows"))
FR <- lapply(PL_FROZEN_GRID, function(x) {
  u <- u0; u[i_lag] <- x
  pv <- ccx_unc_to_par(u); g <- geom(pv); b <- run_at(pv)
  nh <- sum(vapply(PL_NH_ROWS, function(r) b$ll[[r]], 0))
  sh <- sum(vapply(setdiff(PL_SEAS_ROWS, PL_NH_ROWS), function(r) b$ll[[r]], 0))
  list(x = x, dlp = lp(u) - one, g = g, r = ratio_at(b, "SPO"), nh = nh, sh = sh, ll = b$ll) })
nh0 <- FR[[which.min(abs(PL_FROZEN_GRID - LAG0))]]$nh
sh0 <- FR[[which.min(abs(PL_FROZEN_GRID - LAG0))]]$sh
for (f in FR)
  cat(sprintf("  %8.4f %10.2f %8.1f %8.3f %8.3f %8.3f %8.3f | %+9.2f %+9.2f%s\n", f$x, f$dlp,
              f$g$theta, f$g$land, f$g$floor, f$g$total, f$r, f$nh - nh0, f$sh - sh0,
              if (abs(f$x - LAG0) < 1e-3) "   <- THE MODE" else
              if (f$g$theta >= PL_THETA_NEED) "   <- theta reaches 164.8" else ""))
f225 <- FR[[which.min(abs(PL_FROZEN_GRID - 2.25))]]
nh_share <- (f225$nh - nh0) / f225$dlp
Q1 <- nh_share >= PL_Q1_NHSHARE
cat(sprintf("\n  Q1  at lag 2.25 the FROZEN cost is %+.2f, of which the NH rows carry %+.2f = %.0f %%\n",
            f225$dlp, f225$nh - nh0, 100 * nh_share))
cat(sprintf("      (gate >= %.0f %%) -> %s\n", 100 * PL_Q1_NHSHARE, if (Q1) "PASS" else "FAIL"))
Q2 <- abs(f225$g$land - PL_Q0[["shland"]]) <= PL_Q2_NETTOL * PL_Q0[["shland"]]
cat(sprintf("  Q2  SH-land net at 2.25 %.3f vs %.3f at the mode (%.1f %%), while the FLOOR fell\n",
            f225$g$land, PL_Q0[["shland"]], 100 * (f225$g$land / PL_Q0[["shland"]] - 1)))
cat(sprintf("      %.3f -> %.3f. gate: net within %.0f %% -> %s%s\n", g0$floor, f225$g$floor,
            100 * PL_Q2_NETTOL, if (Q2) "PASS" else "FAIL",
            if (Q2) "  ⇒ the lag OPENS the door, it does not walk through it." else ""))
Q5 <- abs(f225$r - PL_Q0[["rspo"]]) <= PL_Q5_RSPO * PL_Q0[["rspo"]]
cat(sprintf("  Q5  r_SPO %.3f -> %.3f (%.1f %%; obs 1.00). gate <= %.0f %% -> %s\n",
            PL_Q0[["rspo"]], f225$r, 100 * (f225$r / PL_Q0[["rspo"]] - 1), 100 * PL_Q5_RSPO,
            if (Q5) "PASS" else "FAIL"))
cat("\n  the scored seasonal rows, each lag minus the mode:\n")
cat(sprintf("  %8s", "lag")); for (n in PL_SEAS_ROWS) cat(sprintf(" %14s", substr(n, 1, 14))); cat("\n")
llm <- FR[[which.min(abs(PL_FROZEN_GRID - LAG0))]]$ll
for (f in FR) { cat(sprintf("  %8.4f", f$x))
  for (n in PL_SEAS_ROWS) cat(sprintf(" %+14.2f", f$ll[[n]] - llm[[n]])); cat("\n") }

# 27j's fit_arm, unchanged.
fit_arm <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = PL_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n_re <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200, reltol = 1e-12)),
              silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = PL_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n_re <- n_re + 1
    if (gain < PL_RESTOL || n_re >= PL_RESTARTS) break
  }
  list(par = v, value = best, restarts = n_re, converged = gain < PL_RESTOL)
}
arm_at <- function(lag_val, A) {
  LP <- if (isTRUE(all.equal(A, PL_A_SHIP))) lp else lp_gross(A)
  ua <- u0; ua[i_q] <- log(Q10_PIN); ua[i_lag] <- lag_val
  objf <- function(v) { u <- ua; u[i_slice] <- v; -LP(u) }
  ft <- fit_arm(objf, ua[i_slice])
  u_h <- ua; u_h[i_slice] <- ft$par; pv <- ccx_unc_to_par(u_h)
  stopifnot(abs(pv$q10 - Q10_PIN) < 1e-9, abs(pv$seas_lag_p - lag_val) < 1e-9)
  mods <- if (isTRUE(all.equal(A, PL_A_SHIP))) list() else list(seas_npp_amp_SH = A)
  b <- run_at(pv, mods)
  list(lag = lag_val, A = A, lp = -ft$value, pv = pv, g = geom(pv, mods),
       r = ratio_at(b, "SPO"), ll = b$ll, converged = ft$converged)
}
price_block <- function(A, label) {
  cat(sprintf("\n  --- seas_npp_amp_SH = %.4f  (%s) ---\n", A, label))
  inc <- arm_at(LAG0, A)
  cat(sprintf("  %8s %10s %8s %8s %8s %8s %8s %9s %s\n", "lag", "d logpost", "theta",
              "SH-land", "floor", "total", "r_SPO", "sTaSH", ""))
  out <- list(inc)
  cat(sprintf("  %8.4f %10.2f %8.1f %8.3f %8.3f %8.3f %8.3f %9.4f   <- INCUMBENT\n", LAG0, 0,
              inc$g$theta, inc$g$land, inc$g$floor, inc$g$total, inc$r, inc$pv$seas_T_amp_SH))
  for (x in PL_ARM_LAGS) {
    a <- arm_at(x, A); out[[length(out) + 1]] <- a
    cat(sprintf("  %8.4f %10.2f %8.1f %8.3f %8.3f %8.3f %8.3f %9.4f%s%s\n", x, a$lp - inc$lp,
                a$g$theta, a$g$land, a$g$floor, a$g$total, a$r, a$pv$seas_T_amp_SH,
                if (a$g$theta >= PL_THETA_NEED) "   theta ok" else "",
                if (!a$converged) "  ⚠ STILL MOVING" else ""))
  }
  out
}
sep("2. Q4/Q3/Q6 -- THE CONDITIONAL PRICE, on the SHIPPED gross")
SH_ARMS <- price_block(PL_A_SHIP, "SHIPPED, status=data")
a225 <- SH_ARMS[[which(vapply(SH_ARMS, function(a) isTRUE(all.equal(a$lag, 2.25)), TRUE))]]
cond <- a225$lp - SH_ARMS[[1]]$lp
Q3 <- a225$pv$seas_T_amp_SH < PL_Q3_TAMULT * pv0$seas_T_amp_SH
band <- if (abs(cond) <= PL_Q4_CHEAP) "CHEAP" else if (abs(cond) <= PL_Q4_PROHIB) "MODERATE" else "PROHIBITIVE"
cat(sprintf("\n  Q4  CONDITIONAL price of lag 2.25 = %+.2f log units -> **%s**\n", cond, band))
cat(sprintf("      bands: CHEAP <= %g | MODERATE <= %g | PROHIBITIVE > %g  (27n's lever: -204 frozen / -35 conditional)\n",
            PL_Q4_CHEAP, PL_Q4_PROHIB, PL_Q4_PROHIB))
cat(sprintf("  Q6  buy-back at 2.25: frozen %+.2f -> conditional %+.2f = %.0f %% recovered\n",
            f225$dlp, cond, 100 * (1 - cond / f225$dlp)))
cat(sprintf("  Q3  fitted seas_T_amp_SH %.4f vs the mode's %.4f (gate < %.1fx = %.4f) -> %s\n",
            a225$pv$seas_T_amp_SH, pv0$seas_T_amp_SH, PL_Q3_TAMULT,
            PL_Q3_TAMULT * pv0$seas_T_amp_SH, if (Q3) "PASS (as predicted)" else
            "⚠ FAIL -- THE FIT WANTS THE GEOMETRY. That is a bigger result than this run sought."))

sep("3. THE SAME ARMS AT THE CMIP6 GROSS -- ⚠ DIAGNOSTIC ONLY (authorisation 1)")
cat("  ⚠ seas_npp_amp_SH = 0.94 is a CMIP6 ENSEMBLE value. It may NOT be shipped, adopted, or\n")
cat("    called an observational constraint. The shipped constant remains 0.5027, status=\"data\".\n")
CM_ARMS <- price_block(PL_A_CMIP6, "CMIP6 ENSEMBLE -- DIAGNOSTIC ONLY")

sep("4. SCORED")
cat(sprintf("  Q0 %s | Q1 %s | Q2 %s | Q3 %s | Q5 %s\n",
            ifelse(all(Q0), "PASS", "FAIL"), ifelse(Q1, "PASS", "FAIL"), ifelse(Q2, "PASS", "FAIL"),
            ifelse(Q3, "PASS", "FAIL"), ifelse(Q5, "PASS", "FAIL")))
cat(sprintf("  Q4 the lag at 2.25 costs %+.2f conditionally -> **%s**\n", cond, band))
cat(sprintf("\n  ⇒ %s\n", if (band == "PROHIBITIVE")
  "THE LAG IS UNAFFORDABLE. The (gross, lag) 2x2 is not worth writing as posed." else
  sprintf("THE LAG IS %s. The (gross, lag) 2x2 is worth writing -- and Q3 says the fit will NOT ask for it unprompted.", band)))
cat("\n  ⚠ NOTHING ADOPTED. seas_lag_p stays at the mode; seas_npp_amp_SH stays 0.5027;\n")
cat("    ccx_mode_file() still resolves from90.\n")

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(lag0 = LAG0, q10_pin = Q10_PIN, slice = PL_SLICE, frozen = FR,
             shipped = SH_ARMS, cmip6 = CM_ARMS, conditional_225 = cond, band = band,
             nh_share = nh_share, harness_at_u_mode = one,
             verdicts = list(Q0 = Q0, Q1 = Q1, Q2 = Q2, Q3 = Q3, Q5 = Q5)),
        file.path(OUTDIR, "price_the_lag.rds"))
cat(sprintf("\nwall clock %.1f min\nwritten: %s\n\n\n=== DONE ===\n",
            as.numeric(difftime(Sys.time(), t0, units = "mins")),
            file.path(OUTDIR, "price_the_lag.rds")))
