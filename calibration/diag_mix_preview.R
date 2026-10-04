#!/usr/bin/env Rscript
# =====================================================================
# diag_mix_preview.R -- THE STRATIFICATION FEEDBACK PREVIEWED (DESIGN §3.4a S; built 10-04 n, 8567ef3).
# Marcus's rulings (10-04 m): thermocline mixing only; obs x law, FIXED; key = GMST minus the lagged
# deep ocean; history + futures, ONE objective-#16 refit with the greening decision. This is the
# build plan's step 6 (notes/proposal_2026-10-04_warming_weakens_mixing.md §6): it PRICES, it does
# not adopt.
#   A  PRICE   every registered mode (CCX_MODE_FILES) under its OWN structure, gate, pins and spinup,
#              scored OFF (must reproduce the stored streams identical() -- the harness check) and ON
#              (its structure + the three constants). A structure that refuses the feedback (uniform
#              K, the martin field, the tropical box) is REPORTED as refused, never skipped silently.
#   B  FUTURES hilda34g, ON (q = 1, and the app's q = 1/2, 2) vs OFF: SSPs unspliced, vv markers
#              spliced on the historical emissions (br_futures()'s convention); CO2, GMST and ocean
#              uptake at 2100 / 2300.
#   C  POWER   the record's opinion of s at hilda34g: the likelihood at s x {0, 1/2, 1, 2, 4}, every
#              name held, and with kz re-optimised (1-D) -- how much of the cost kz alone buys back.
#   D  BENCH   the ocean's climate effect over 2015-24 (warm vs climate held at its 1901-20 mean from
#              1901, GMST AND SST held), OFF vs ON, against GCB 2025's -0.20 +/- 0.05 GtC/yr.
# ⛔ A PREVIEW: no objective changes, no mode file written, nothing adopted. No RNG.
# Usage: Rscript calibration/diag_mix_preview.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
source(file.path("calibration", "lib_block_reopt.R"))    # br_hist_em() (the futures' splice), nothing else
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
MP_DRIVER  <- "calibration/diag_mix_preview.R"
MP_MODE    <- "hilda34g"
MP_LABEL_M <- "hilda_csl3v0kaidgbem"
MP_NAMES   <- c("mix_strat_s", "mix_strat_q", "mix_strat_tau")
MP_FUT     <- c(ssp126 = FALSE, ssp245 = FALSE, ssp585 = FALSE, vvLN = TRUE, vvM = TRUE, vvH = TRUE)   # splice?
MP_FUT_YRS <- c(2100L, 2300L)
MP_Q_ARMS  <- c(central = ccx_const("MIX_STRAT_Q"), lo = ccx_const("MIX_STRAT_Q_LO"), hi = ccx_const("MIX_STRAT_Q_HI"))
MP_S_GRID  <- c(0, 0.5, 1, 2, 4)                      # x MIX_STRAT_S
MP_KZ_HALFWIDTH <- 0.3                                # the kz search, +/- in its u (log) coordinate
MP_GCB_OCEAN <- c(mean = -0.20, sd = 0.05)            # GCB 2025 ESSD 18:3211 p. 3242 (2015-24; "normal year" baseline)
MP_WIN  <- c(2015L, 2024L); MP_CLIM <- c(1901L, 1920L)
MP_OUT  <- ccx_path("outputs", "diagnostics", sprintf("mix_preview_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- local({
  h <- suppressWarnings(tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), error = function(e) character(0)))
  d <- suppressWarnings(tryCatch(system2("git", c("status", "--porcelain", "--", "R", "src", "calibration", "data"), stdout = TRUE), error = function(e) NA_character_))
  if (length(h) != 1L) "?" else paste0(h, if (anyNA(d)) "+dirty?" else if (length(d)) "+dirty" else "") })
MIX_BLK <- ccx_struct_block(MP_LABEL_M)[MP_NAMES]
mix_on_p <- function(p, q = NULL, s_mult = 1) { for (n in MP_NAMES) p[[n]] <- MIX_BLK[[n]]
  p$mix_strat_s <- MIX_BLK$mix_strat_s * s_mult; if (!is.null(q)) p$mix_strat_q <- q; p }
LOGCON <- file(paste0(MP_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | the feedback: s %.6f /K, q %g (app range %g-%g), tau_d %.3f yr (label %s)\n", MP_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), MIX_BLK$mix_strat_s, MIX_BLK$mix_strat_q, MP_Q_ARMS[["lo"]], MP_Q_ARMS[["hi"]],
            MIX_BLK$mix_strat_tau, MP_LABEL_M))

# ---- A. PRICE at every registered mode ------------------------------------------------------
cat("\n=== A. PRICE: every registered mode under its own structure, OFF (must reproduce) and ON ===\n")
PRICE <- do.call(rbind, lapply(names(CCX_MODE_FILES), function(a) {
  md <- readRDS(ccx_mode_file(a))
  gt <- ccx_apply_gate(ccx_mode_struct(md)); rm <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rm); ccx_unapply_gate(gt) }, add = TRUE)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "mix preview")))
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  score <- function(b) ccx_make_logpost(base_params = b, by_stream = TRUE, spinup_fn = spf)(st$u)
  s0 <- unlist(attr(v0 <- score(bp), "streams"))
  repro <- identical(names(s0), names(unlist(md$streams))) && identical(unname(s0), unname(unlist(md$streams)))
  # ⚠ the refusal is read on the FITTED vector, not the bare structure base: a base carries the
  # uniform-K default, and every mode would read "refused" on it -- a false null.
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md)); attr(pm, "migrated_done") <- TRUE
  refused <- tryCatch({ ccx_prepare(mix_on_p(ccx_overlay_par(bp, pm))); "" }, error = function(e) conditionMessage(e))
  if (nzchar(refused)) {
    cat(sprintf("%-10s %-22s OFF reproduces stored: %-5s | ON REFUSED: %s\n", a, ccx_mode_struct(md), repro, substr(refused, 1, 90)))
    return(data.frame(mode = a, struct = ccx_mode_struct(md), repro = repro, refused = TRUE, d_lik = NA, top = NA, stringsAsFactors = FALSE)) }
  s1 <- unlist(attr(score(mix_on_p(bp)), "streams")); d <- s1 - s0
  top <- paste(sprintf("%s %+.2f", names(d)[order(-abs(d))][1:4], d[order(-abs(d))][1:4]), collapse = ", ")
  cat(sprintf("%-10s %-22s OFF reproduces stored: %-5s | ON: likelihood %+.4f | largest rows: %s\n", a, ccx_mode_struct(md), repro, sum(d), top))
  data.frame(mode = a, struct = ccx_mode_struct(md), repro = repro, refused = FALSE, d_lik = sum(d), top = top, stringsAsFactors = FALSE) }))
if (!all(PRICE$repro)) stop("A: a registered mode does not reproduce its stored streams OFF -- the harness is not scoring the file it read")

# ---- B. FUTURES at the canonical --------------------------------------------------------------
cat(sprintf("\n=== B. FUTURES at %s: OFF vs ON (q = %g central; %g / %g bounds) ===\n", MP_MODE, MP_Q_ARMS[["central"]], MP_Q_ARMS[["lo"]], MP_Q_ARMS[["hi"]]))
V0 <- dg_vector(MP_MODE); he <- br_hist_em()
fut_one <- function(v, scen, splice) { sp <- dg_spinup(v)
  em <- if (!splice) NULL else { e <- ccx_scenario_emissions(scen); rbind(he, e[e$year > max(he$year), c("year", "fossil_GtC", "luc_GtC")]) }
  rr <- suppressWarnings(ccx_run_coupled(sp, scen, c(1750L, max(MP_FUT_YRS)), emissions = em, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale))
  yr <- floor(rr$out$t); co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, yr, mean); oc <- tapply(rr$out$ocean_C, yr, mean)
  cl <- rr$climate
  unlist(lapply(MP_FUT_YRS, function(y) stats::setNames(c(co2[[as.character(y)]], cl$gmst[cl$year == y], oc[[as.character(y)]] - oc[["2024"]]),
                                                        paste0(c("co2_", "gmst_", "ocean_uptake_since2024_"), y)))) }
FUT <- do.call(rbind, lapply(names(MP_FUT), function(scen) {
  arms <- c(list(OFF = V0), lapply(MP_Q_ARMS, function(q) { v <- V0; v$p <- mix_on_p(V0$p, q = q); v }))
  names(arms) <- c("OFF", paste0("ON_q", names(MP_Q_ARMS)))
  do.call(rbind, lapply(names(arms), function(k) data.frame(scenario = scen, arm = k, t(fut_one(arms[[k]], scen, MP_FUT[[scen]])), check.names = FALSE))) }))
for (scen in names(MP_FUT)) { x <- FUT[FUT$scenario == scen, ]; off <- x[x$arm == "OFF", ]
  for (k in setdiff(x$arm, "OFF")) { on <- x[x$arm == k, ]
    cat(sprintf("%-7s %-11s CO2 2100 %7.1f (%+5.2f)  2300 %7.1f (%+6.2f) ppm | GMST 2300 %5.2f (%+.3f) K | ocean uptake 2024-2300 %7.1f (%+6.1f) GtC\n",
                scen, k, on$co2_2100, on$co2_2100 - off$co2_2100, on$co2_2300, on$co2_2300 - off$co2_2300, on$gmst_2300, on$gmst_2300 - off$gmst_2300,
                on$ocean_uptake_since2024_2300, on$ocean_uptake_since2024_2300 - off$ocean_uptake_since2024_2300)) } }

# ---- C. POWER: the record's opinion of s ------------------------------------------------------
cat(sprintf("\n=== C. POWER at %s: likelihood vs s (x %.6f), every name held | and with kz re-optimised (1-D, +/- %.1f in u) ===\n", MP_MODE, MIX_BLK$mix_strat_s, MP_KZ_HALFWIDTH))
POW <- local({ md <- readRDS(ccx_mode_file(MP_MODE))
  gt <- ccx_apply_gate(ccx_mode_struct(md)); rm <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(rm); ccx_unapply_gate(gt) }, add = TRUE)
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md)); u0 <- ccx_par_to_unc(ccx_mode_par_with_pins(md))
  lik_at <- function(b, u) { v <- ccx_make_logpost(base_params = b, by_stream = TRUE, spinup_fn = spf)(u)
    c(logpost = as.numeric(v), lik = sum(unlist(attr(v, "streams")))) }
  base <- lik_at(bp, u0)
  do.call(rbind, lapply(MP_S_GRID, function(m) {
    b <- if (m == 0) bp else mix_on_p(bp, s_mult = m)
    held <- lik_at(b, u0)
    f <- function(x) { u <- u0; u[["kz"]] <- x; -lik_at(b, u)[["logpost"]] }
    o <- stats::optimize(f, u0[["kz"]] + c(-1, 1) * MP_KZ_HALFWIDTH, tol = 1e-4)
    u <- u0; u[["kz"]] <- o$minimum; re <- lik_at(b, u)
    kz_nat <- ccx_unc_to_par(u)[["kz"]]
    cat(sprintf("  s x %-4g (%.4f /K): held  d_lik %+8.4f | kz re-optimised -> %8.1f m2/yr: d_lik %+8.4f, d_logpost %+8.4f\n",
                m, MIX_BLK$mix_strat_s * m, held[["lik"]] - base[["lik"]], kz_nat, re[["lik"]] - base[["lik"]], re[["logpost"]] - base[["logpost"]]))
    data.frame(s_mult = m, s = MIX_BLK$mix_strat_s * m, d_lik_held = held[["lik"]] - base[["lik"]], kz_opt = kz_nat,
               d_lik_kz = re[["lik"]] - base[["lik"]], d_logpost_kz = re[["logpost"]] - base[["logpost"]]) })) })

# ---- D. BENCHMARK: the ocean's climate effect, 2015-24 ------------------------------------------
cat(sprintf("\n=== D. THE OCEAN'S CLIMATE EFFECT, %d-%d: warm vs climate (GMST + SST) held at its %d-%d mean from %d ===\n",
            MP_WIN[1], MP_WIN[2], MP_CLIM[1], MP_CLIM[2], MP_CLIM[1]))
ocean_climate <- function(v) { sp <- dg_spinup(v)
  F <- withCallingHandlers(ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale,
                                             enso_index = ccx_enso_index_of(v$p), aod_mode = ccx_aod_mode_of(v$p)),
                           warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
  F0 <- F; sel <- F0$year >= MP_CLIM[1]; inclim <- F$year >= MP_CLIM[1] & F$year <= MP_CLIM[2]
  for (cc in intersect(c("gmst", "sst_anom_NH", "sst_anom_SH"), names(F0))) F0[[cc]][sel] <- mean(F[[cc]][inclim])
  win <- function(r, col) { at <- function(t) stats::approx(r$out$t, r$out[[col]], xout = t)$y; (at(MP_WIN[2] + 1) - at(MP_WIN[1])) / (MP_WIN[2] + 1 - MP_WIN[1]) }
  co2 <- function(r) { k <- r$out$t >= MP_WIN[1] & r$out$t < MP_WIN[2] + 1; mean((r$out$co2_NH[k] + r$out$co2_SH[k]) / 2) }
  rf <- ccx_run_fast(sp, F); rh <- ccx_run_fast(sp, F0)
  c(sink_full = win(rf, "ocean_C"), sink_held = win(rh, "ocean_C"), effect = win(rf, "ocean_C") - win(rh, "ocean_C"), dco2 = co2(rf) - co2(rh)) }
VON <- V0; VON$p <- mix_on_p(V0$p)
BEN <- rbind(OFF = ocean_climate(V0), ON = ocean_climate(VON))
for (k in rownames(BEN)) cat(sprintf("  %-3s: ocean sink %.4f (warm) vs %.4f (held) -> climate effect %+.4f GtC/yr (z %+.2f vs GCB %+.2f +/- %.2f); warm-run CO2 %+.2f ppm above held\n",
                                     k, BEN[k, "sink_full"], BEN[k, "sink_held"], BEN[k, "effect"], (BEN[k, "effect"] - MP_GCB_OCEAN[["mean"]]) / MP_GCB_OCEAN[["sd"]],
                                     MP_GCB_OCEAN[["mean"]], MP_GCB_OCEAN[["sd"]], BEN[k, "dco2"]))
cat(sprintf("  the feedback's own share of the effect: %+.4f GtC/yr\n", BEN["ON", "effect"] - BEN["OFF", "effect"]))
cat("  ⚠ NOT like-for-like with GCB: its baseline is a repeated 'normal year', not 1901-20; its ocean models carry WINDS\n",
    "    (in one model ~2/3 of the effect; Bunsen 2024) that CCX lacks; and CO2 is interactive here (the warm run's CO2 differs).\n", sep = "")

sink(); close(LOGCON)
saveRDS(list(price = PRICE, futures = FUT, power = POW, bench = BEN,
             provenance = sprintf("%s @%s; label %s (s %.6f, q %g, tau %.3f); registered modes CCX_MODE_FILES; futures at %s; no RNG; %s",
                                  MP_DRIVER, COMMIT, MP_LABEL_M, MIX_BLK$mix_strat_s, MIX_BLK$mix_strat_q, MIX_BLK$mix_strat_tau, MP_MODE,
                                  format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(MP_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", MP_OUT))
