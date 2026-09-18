# =====================================================================
# diag_free_parent_refit_read.R -- TEST (a) OF THE CONTROL RESULT: the FREE PARENT's
# REFIT READ (the Mac wave of 2026-09-18 11:10 ->; objective #12 on its frozen tree
# 00a6f17, hilda_c, seasonal ML ON, the SHIM FREE, the six inert pins + w_enso_l2 = 0;
# 31 names). THE QUESTION (handoff 09-18 e s2.1): the refit seas_ml-0 control c1 beats
# the canonical hilda30h by +10.31 on the 25 #12 rows. Test (b) showed the shim's
# CONDITIONAL optimum at the canonical's point is 0, so the pin costs nothing there;
# this wave says whether a REFIT with the ML on and the shim free recovers c1's score:
#   H_pin : fp1 ~ c1's -1390 with the shim ~18  => the pin cost it (the shim double-
#           counts only at the canonical's point); the ML + shim arm is the better fit.
#   H_ml  : fp1 ~ the canonical's -1400, shim ~0 => the seasonal ML itself costs ~10
#           (on the NH seasonal d13C); the round-6 adoption rests on a stale control.
#   mixed : between, or the shim intermediate -- read the rows.
# Arms:
#   canonical  hilda30h  (hilda_c, seas_ml 1, 7 pins incl. the shim at 0; 30 free)
#   fp_reg     hilda31s2, the REGISTERED free parent (hilda, seas_ml 1, shim free)
#   c1         the refit CONTROL (09-17 j wave id 18: hilda_c, seas_ml 0, shim 18.03)
#   fp1        this wave's basin-1 rank-1 start (from summary.csv; FP_B1 overrides)
#   fp2..      the rank-1 start of every OTHER basin the collector found (<= 3 read)
# ⚠ LIKE-FOR-LIKE IS #12: the wave was fitted under #12, c1's -1389.99 is #12. The
# registered files are #13-stamped (26 rows) since 09-18 e; the row is ADDITIVE (the 25
# pre-#13 rows are bit-identical under either switch, test-gcb-enso-slope), so every
# total below is reported on the 25 #12 rows AND with the #13 row, side by side.
# Section 0 proves both registered files reproduce their stored streams first.
# Compare on LIKELIHOOD over common rows, never the logposts (31 names/7 pins vs 30/7).
# READ, not gated -- nothing is adopted; which arm becomes the registered control, and
# whether the seasonal ML stays canonical, are RULINGS.
# Usage: Rscript calibration/diag_free_parent_refit_read.R
#   env FP_DIR (the wave's outdir, copied into the repo), FP_B1 (basin-1 id override)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
FP_DIR  <- local({ d <- Sys.getenv("FP_DIR", ""); if (nzchar(d)) d else
  ccx_path("calibration", "output", "multistart_20260918_hilda_c_seasml1_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_w_enso_l2=0_sd1.0452") })
FP_JOB  <- "Mac wave 2026-09-18 11:10 -> (frozen tree ~/ccx_frozen/20260918c_free_parent_refit = the bundle at 00a6f17, objective #12; launcher launch_now.sh)"
C1_DIR  <- ccx_path("calibration", "output", "multistart_20260917_hilda_c_seasml0_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_sd1.0452")
C1_ID   <- 18L                       # the 09-18 a read's c1 (12 starts on one vector)
C1_LIK12 <- -1389.9948               # enso_slope_row_price_20260918.log "lik #12" (= the 09-18 a read, 25 rows)
CAN_LIK12 <- -1400.3026              # hilda30h, the same log (the 09-18 a read prints it as -1400.30)
FP_MAX_BASINS <- 3L
FP_OUT  <- ccx_path("outputs", "diagnostics", sprintf("free_parent_refit_read_%s", format(Sys.Date(), "%Y%m%d")))
FP_REPRO_TOL <- 1e-3
FP_ROW13 <- "gcb_ocean_enso_slope"   # the #13 row: additive, reported beside the #12 total
FP_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_", hs = "^hs_")
FP_NAMES <- c("beta_max", "fert_k", "q10", "kz", "kz_deep_frac", "h_hs", "u_hs", "h_ml", "ent_seas_amp_SH", "sst_seas_amp_NH", "sst_seas_amp_SH", "pump_hs_gcm2", "pump_grad",
              "hs_asx_frac", "k_w", "tau_ex", "rep_dC", "bomb_total", "sigma_d14c", "luc_scale", "grad_off_co2", "grad_off_d13c",
              "gamma_enso_land_NH", "gamma_enso_land_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH")
sink_log <- file(paste0(FP_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("FREE PARENT REFIT READ (test (a))  %s\n  %s\n  dir %s\n", format(Sys.time()), FP_JOB, FP_DIR))
if (!file.exists(file.path(FP_DIR, "summary.csv")))
  stop("no summary.csv in ", FP_DIR, ": copy the wave's outdir into the repo and run collect_dispersed_multistart.R first.")
sm <- utils::read.csv(file.path(FP_DIR, "summary.csv"))
sm <- sm[order(-sm$logpost), ]
cat(sprintf("  collector: %d starts, %d converged, %d basins; best id %d logpost %.4f\n", nrow(sm), sum(sm$converged), length(unique(sm$basin)), sm$id[1], sm$logpost[1]))
basin_ids <- vapply(split(sm, sm$basin), function(b) { b <- b[order(-b$logpost), ]; as.integer(b$id[1]) }, integer(1))
basin_ids <- basin_ids[order(-vapply(names(basin_ids), function(k) max(sm$logpost[sm$basin == as.integer(k)]), numeric(1)))]
b1_env <- Sys.getenv("FP_B1", ""); if (nzchar(b1_env)) basin_ids[1] <- as.integer(b1_env)
basin_ids <- basin_ids[seq_len(min(FP_MAX_BASINS, length(basin_ids)))]
cat(sprintf("  arms from the collector: %s\n", paste(sprintf("fp%d = id %d (basin %s, logpost %.4f, %s)", seq_along(basin_ids), basin_ids, names(basin_ids),
            sm$logpost[match(basin_ids, sm$id)], ifelse(sm$converged[match(basin_ids, sm$id)], "CONVERGED", "NOT converged")), collapse = "; ")))

start_file <- function(dir, id) readRDS(file.path(dir, sprintf("start_%03d.rds", id)))
start_vector <- function(dir, id) {
  s <- start_file(dir, id); pins <- s$pins
  # pins are applied CUMULATIVELY across arms (c1 holds 6, the fp arms 7): ccx_apply_pins() removes
  # the names from the table, so a second call sees only the new ones; CCX_PINS is merged by hand
  .todo <- pins[names(pins) %in% CCX_PARAM_NAMES]
  if (length(.todo)) { .prev <- CCX_PINS; invisible(ccx_apply_pins(.todo)); assign("CCX_PINS", c(.prev, .todo), envir = environment(ccx_apply_pins)) }
  p <- ccx_default_params(); p$pump_mode <- s$pump_mode
  p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
  for (n in names(pins)) p[[n]] <- pins[[n]]
  pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
       rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins, prior_z = s$prior_z,
       src = sprintf("start_%03d (logpost %.4f, %s, %s)", id, s$logpost, if (isTRUE(s$converged)) "CONVERGED" else "NOT converged", s$kind), s = s)
}
obs <- ccx_prepare_obs(); OH <- dg_gateH_obs(obs)
canon <- dg_vector(CCX_MODE_CANONICAL); canon$prior_z <- canon$md$prior_z
fpreg <- dg_vector(CCX_MODE_PINNED_PARENT); fpreg$prior_z <- fpreg$md$prior_z
ARMS <- list(canonical = canon, fp_reg = fpreg, c1 = start_vector(C1_DIR, C1_ID))
for (i in seq_along(basin_ids)) ARMS[[sprintf("fp%d", i)]] <- start_vector(FP_DIR, basin_ids[[i]])
an <- names(ARMS); fpn <- grep("^fp[0-9]", an, value = TRUE)

cat("\n=== A. THE BASINS IN u-SPACE ===\n")
s1 <- start_file(FP_DIR, basin_ids[[1]])
du <- function(a, b) { d <- a$u_mode - b$u_mode; names(d) <- a$param_names; d }
inc <- start_file(FP_DIR, 1L)   # id 1 = the incumbent reference (hilda31s2's point)
if (isTRUE(inc$converged)) { d1 <- du(s1, inc); cat(sprintf("  fp1 (id %d) vs id 1 (the incumbent's own convergence): RMS |du| %.4f, max |du| %.4f at %s -> %s\n", basin_ids[[1]], sqrt(mean(d1^2)), max(abs(d1)), names(which.max(abs(d1))), if (max(abs(d1)) < 0.2) "SAME basin" else "different")) }
for (i in seq_along(basin_ids)[-1]) { si <- start_file(FP_DIR, basin_ids[[i]]); d <- du(s1, si)
  cat(sprintf("  fp1 vs fp%d (id %d, %+.2f): RMS |du| %.4f; the coordinates that separate them (|du| > 0.3):\n", i, basin_ids[[i]], si$logpost - s1$logpost, sqrt(mean(d^2))))
  big <- sort(abs(d), decreasing = TRUE); big <- big[big > 0.3]
  for (n in names(big)) cat(sprintf("    %-20s du %+.3f   fp1 %10.4g   fp%d %10.4g\n", n, d[[n]], s1$par_mode[[n]], i, si$par_mode[[n]])) }
# fp1 vs c1 in parameter space (different arms: ML on/off -- u-space is not shared; compare values)
sc1 <- start_file(C1_DIR, C1_ID)
cat("  fp1 vs c1 (the refit control), the fitted values that differ by > 10 %:\n")
for (n in intersect(names(s1$par_mode), names(sc1$par_mode))) { a <- s1$par_mode[[n]]; b <- sc1$par_mode[[n]]
  if (is.numeric(a) && is.numeric(b) && length(a) == 1 && is.finite(a) && is.finite(b) && abs(a - b) > 0.1 * max(abs(a), abs(b), 1e-9)) cat(sprintf("    %-20s fp1 %10.4g   c1 %10.4g\n", n, a, b)) }

cat("\n=== B. PARAMETERS (value, prior z) ===\n")
cat(sprintf("  %-20s %s\n", "name", paste(sprintf("%28s", an), collapse = " ")))
zfmt <- function(v, n) { z <- v$prior_z; if (is.null(z) || is.na(z[n])) "" else sprintf("z %+.2f", z[[n]]) }
for (n in FP_NAMES) {
  vals <- vapply(ARMS, function(v) { x <- v$pm[[n]]; if (is.null(x)) x <- v$p[[n]]; if (is.null(x)) NA_real_ else x }, numeric(1))
  cat(sprintf("  %-20s %s\n", n, paste(vapply(an, function(a) sprintf("%18.5g %9s", vals[[a]], zfmt(ARMS[[a]], n)), ""), collapse = " ")))
}
for (a in an) cat(sprintf("  %-10s struct '%s' seas_ml %s pins %s\n", a, attr(ARMS[[a]]$p, "struct"), attr(ARMS[[a]]$p, "seas_ml"), ccx_pin_label(ARMS[[a]]$pins)))
shim <- vapply(ARMS, function(v) { x <- v$pm$ent_seas_amp_SH; if (is.null(x)) v$p$ent_seas_amp_SH else x }, numeric(1))
cat(sprintf("  THE SHIM ent_seas_amp_SH (the tell): %s\n", paste(sprintf("%s %.3f", an, shim), collapse = ", ")))
cat(sprintf("  h_ml: %s (box floor %.1f)\n", paste(sprintf("%s %.1f", an, vapply(ARMS, function(v) v$p$h_ml, numeric(1))), collapse = ", "), CCX_PARAM_TABLE$h_ml$lo))
cat(sprintf("  sst_seas_amp_NH (c1's 1.71 vs the canonical's 2.44 carried the +7.25 on d13c_seasonal_MLO): %s\n", paste(sprintf("%s %.3f", an, vapply(ARMS, function(v) v$p$sst_seas_amp_NH, numeric(1))), collapse = ", ")))
for (a in an) { z <- ARMS[[a]]$prior_z; if (is.null(z)) next; s <- names(z)[abs(z) > 2]; cat(sprintf("  strained priors (|z| > 2) %-10s %s\n", a, if (length(s)) paste(sprintf("%s %+.2f", s, z[s]), collapse = ", ") else "none")) }

cat("\n=== 0. BOTH REGISTERED FILES REPRODUCE THEIR STORED STREAMS (the like-for-like guard) ===\n")
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS, MoreArgs = list(obs = obs))
for (a in c("canonical", "fp_reg")) { st0 <- ARMS[[a]]$md$streams; cm0 <- intersect(names(st0), names(ST[[a]])); d0 <- sum(ST[[a]][cm0]) - sum(unlist(st0[cm0]))
  cat(sprintf("  %-10s stored %.4f recomputed %.4f diff %+.2e over %d rows -> %s\n", a, sum(unlist(st0[cm0])), sum(ST[[a]][cm0]), d0, length(cm0), if (abs(d0) <= FP_REPRO_TOL) "REPRODUCES" else "DOES NOT REPRODUCE -- read nothing below")) }
for (a in c("c1", fpn)) { s <- ARMS[[a]]$s
  cat(sprintf("  %-4s start file logpost %.4f (#12 on its tree; final_lp_check %s); the LIKELIHOOD below is recomputed under today's build\n", a, s$logpost, if (is.null(s$final_lp_check)) "n/a" else format(s$final_lp_check))) }
has13 <- vapply(ST, function(s) FP_ROW13 %in% names(s), logical(1))
cat(sprintf("  the #13 row %s is present in: %s\n", FP_ROW13, paste(an[has13], collapse = ", ")))

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP -- the 25 #12 rows (common, the #13 row set aside) ===\n")
common13 <- Reduce(intersect, lapply(ST, names)); common <- setdiff(common13, FP_ROW13)
cat(sprintf("  %-14s %s %9s %9s   rows\n", "group", paste(sprintf("%10s", an), collapse = ""), "fp1-can", "fp1-c1"))
G <- lapply(FP_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(vapply(ST, function(s) sum(s[rows]), numeric(1)), n = length(rows)) })
for (g in names(G)) { x <- G[[g]]; if (x[["n"]] == 0) next
  cat(sprintf("  %-14s %s %+9.2f %+9.2f   %s\n", g, paste(sprintf("%10.2f", x[an]), collapse = ""), x[["fp1"]] - x[["canonical"]], x[["fp1"]] - x[["c1"]], paste(grep(FP_GROUPS[[g]], common, value = TRUE), collapse = " "))) }
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
cat(sprintf("  %-14s %s %+9.2f %+9.2f   (%d rows, #12)\n", "TOTAL #12", paste(sprintf("%10.2f", tot), collapse = ""), tot[["fp1"]] - tot[["canonical"]], tot[["fp1"]] - tot[["c1"]], length(common)))
row13 <- vapply(ST, function(s) if (FP_ROW13 %in% names(s)) s[[FP_ROW13]] else NA_real_, numeric(1))
cat(sprintf("  %-14s %s   (the #13 row alone; NA = absent)\n", FP_ROW13, paste(sprintf("%10.2f", row13), collapse = "")))
tot13 <- tot + ifelse(is.na(row13), 0, row13)
cat(sprintf("  %-14s %s %+9.2f %+9.2f   (%d rows, #13)\n", "TOTAL #13", paste(sprintf("%10.2f", tot13), collapse = ""), tot13[["fp1"]] - tot13[["canonical"]], tot13[["fp1"]] - tot13[["c1"]], length(common13)))
for (a in an) { extra <- setdiff(names(ST[[a]]), common13); if (length(extra)) cat(sprintf("  %s-only rows: %s\n", a, paste(sprintf("%s %.2f", extra, ST[[a]][extra]), collapse = ", "))) }
cat(sprintf("  cross-check against the 09-18 a read (#12, 25 rows): canonical %.4f (was %.4f), c1 %.4f (was %.4f)\n", tot[["canonical"]], CAN_LIK12, tot[["c1"]], C1_LIK12))
cat("\n  every #12 row, fp1 (the refit free parent) minus canonical (sorted):\n"); print(round(sort(ST$fp1[common] - ST$canonical[common]), 2))
cat("\n  every #12 row, fp1 minus c1 (the refit control; what the ML arm still lacks, or has gained, vs ML-off):\n"); print(round(sort(ST$fp1[common] - ST$c1[common]), 2))
cat("\n  every #12 row, fp1 minus the REGISTERED free parent hilda31s2 (what the refit bought):\n"); print(round(sort(ST$fp1[common] - ST$fp_reg[common]), 2))
d_can <- tot[["fp1"]] - tot[["canonical"]]; d_c1 <- tot[["fp1"]] - tot[["c1"]]
verdict <- if (abs(d_c1) <= 2 && shim[["fp1"]] > 5) "H_pin: the refit ML+shim arm reaches the refit control; the pin cost it" else
           if (abs(d_can) <= 2 && shim[["fp1"]] < 2) "H_ml: ML-on-shim-free stays at the canonical with the shim at ~0; the seasonal ML itself costs ~10" else
           "MIXED: read the rows above (neither hypothesis's letter)"
cat(sprintf("\n  THE QUESTION (25 #12 rows): fp1 minus canonical %+.2f; fp1 minus c1 %+.2f; the shim at fp1 %.3f (c1 %.3f, canonical pinned 0)\n  -> %s\n", d_can, d_c1, shim[["fp1"]], shim[["c1"]], verdict))
cat("  AIC-style: fp1 and c1 fit 31 names, the canonical 30 -- one log-unit per name is the conventional allowance\n")

cat("\n=== 2. THE LAND SINK (gate 7) ===\n")
tg7 <- dg_gcb_target(DG_SINK_WIN)
cat(sprintf("  GCB target over %d-%d (n %d): ocean %.2f (gate sd %.2f), land %.2f (gate sd %.2f) GtC/yr; gate bound %g sd\n", DG_SINK_WIN[1], DG_SINK_WIN[2], tg7$n, tg7$ocean, DG_G7_OCEAN_SD, tg7$land, DG_G7_LAND_SD, DG_G7_NSD))
G7 <- list(); for (a in an) { g7 <- dg_gate7(R[[a]]); vd <- dg_gate7_verdict(g7, tg7); G7[[a]] <- list(g = g7, v = vd)
  cat(sprintf("  GATE 7  %-10s ocean %.2f (z %+.2f) land %.2f (z %+.2f; %+.2f GtC/yr vs GCB) ; rows gcb_land_sink %.2f gcb_ocean_sink %.2f  -> %s\n", a, g7$ocean, vd$z_ocean, g7$land, vd$z_land, g7$land - tg7$land,
              ST[[a]][["gcb_land_sink"]], ST[[a]][["gcb_ocean_sink"]], if (isTRUE(vd$pass)) "PASS" else "FAIL")) }

cat("\n=== 3. THE ENSO OCEAN SLOPE (the #13 row's quantity, read at every arm) ===\n")
ES <- list()
for (a in an) { s <- dg_annual_sinks(R[[a]]); es <- ccx_enso_slope(s$year, s$ocean, obs$enso_idx); ES[[a]] <- es   # THE one estimator (R/likelihood.R), on the dg annual sinks
  cat(sprintf("  %-10s slope %+.4f +- %.4f (%.2fx obs %+.4f +- %.4f; z %+.2f)  r %+.3f  n %d\n", a, es[["slope"]], es[["se"]], es[["slope"]] / obs$enso_slope[["slope"]],
              obs$enso_slope[["slope"]], obs$enso_slope[["se"]], (es[["slope"]] - obs$enso_slope[["slope"]]) / obs$enso_slope[["se"]], es[["r"]], as.integer(es[["n"]]))) }

cat("\n=== 4. GATES H / GL / Q / S (the ledger's idioms) ===\n")
verd <- list(); GH <- list()
for (a in an) { gh <- dg_gateH(ARMS[[a]], obs, OH, r = R[[a]]); GH[[a]] <- gh; vd <- dg_gateH_verdict(gh, OH); verd[[a]]$H <- vd
  cat(sprintf("  GATE H  %-10s R_co2 %.3f (z_level %+.2f) R_d13c %.3f (z_level %+.2f)  contrast z %+.2f  -> %s\n", a, vd$R_co2, vd$z_level_co2, vd$R_d13c, vd$z_level_d13c, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- dg_gateGL_verdict(GH[[a]], OH); verd[[a]]$GL <- vd
  cat(sprintf("  GATE GL %-10s d13C gradient %.4f vs obs %.4f +- %.4f (ratio %.2f) z %+.2f  -> %s\n", a, vd$model, vd$obs, vd$se_obs, vd$ratio, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { q <- dg_gateQ(R[[a]], ARMS[[a]]); verd[[a]]$Q <- q
  cat(sprintf("  GATE Q  %-10s air-sea d13C diseq mean %+.3f vs %.2f +- %.2f  n_sd %.2f  -> %s\n", a, q$mean, DG_Q_OBS, DG_Q_SD, q$n_sd, if (q$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- tryCatch({ g <- dg_gateS(ARMS[[a]], obs, r = R[[a]]); dg_gateS_verdict(g) }, error = function(e) { cat(sprintf("  GATE S  %-10s FAILED TO RUN: %s\n", a, conditionMessage(e))); NULL }); verd[[a]]$S <- vd
  if (!is.null(vd)) cat(sprintf("  GATE S  %-10s SPO ocean limb %.3f ppm @ month %.2f, bracket [%.2f, %.2f]  -> %s\n", a, vd$amp, vd$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else sprintf("FAIL (%+.2f mo)", vd$d_mo))) }
GR <- lapply(R, function(r) ccx_ocean_grad_scored(r$out, r$sp)); tgP <- ccx_ocean_gradient_target()
for (a in an) cat(sprintf("  (gradient rows) %-10s d13C %.3f (target %.3f) DIC %.1f (target %.1f +- %.1f, z %+.2f)\n", a, GR[[a]]$d13c, tgP$d13c$target, GR[[a]]$dic, tgP$dic$target, tgP$dic$sd, (GR[[a]]$dic - tgP$dic$target) / tgP$dic$sd))

cat("\n=== 5. OWED, NOT READ HERE ===\n")
cat("  the RULING: which arm is the registered seas_ml-0 control (c1?) and whether the seasonal ML stays canonical; the #13 refits (canonical, control) are chained on the Mac.\n")
saveRDS(list(job = FP_JOB, dir = FP_DIR, ids = c(c1 = C1_ID, fp = basin_ids), summary = sm,
             params = lapply(ARMS, function(v) list(p = v$p, pm = v$pm, prior_z = v$prior_z, src = v$src)), streams = ST, groups = G, tot12 = tot, tot13 = tot13, row13 = row13, enso_slope = ES,
             shim = shim, verdict = verdict, gate7 = G7, verdicts = verd, gradients = GR, built = format(Sys.time())), paste0(FP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ NOTHING IS ADOPTED; no mode is promoted.\n", FP_OUT))
