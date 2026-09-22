# =====================================================================
# diag_free_parent_csl3_read.R -- THE FREE PARENT OF THE LIMB CANONICAL, READ
# (the Mac wave of 2026-09-21 15:30 -> 09-22 05:04; frozen tree
# ~/ccx_frozen/20260921g_free_parent_refit = 00ead9f + CCX_MODE_FREE_PARENT_PINS;
# objective #13; hilda_csl3, seas_ml 1, the six inert pins only -- the seasonal shim
# ent_seas_amp_SH, the ocean ENSO pair gamma_enso_ocn_NH/SH and the limb's w_enso_l2
# ALL FITTED, 32 names). CHANGELOG 09-21 (h); assessment 09-21 s1 "the stale parent".
# THE QUESTION (test-mode-file's named red #1): the canonical hilda29l is PINNED (29
# names); is it "a PINNED arm whose parent is the best free arm"? That needs a free
# parent on ITS OWN structure that beats the control hilda31pe (31 names) on the 26
# #13 rows. The registered parent hilda31s2 (a `hilda` fit) cannot answer it.
#   H_parent : fp1 >= control on likelihood => the canonical's pins are priced against
#              a live parent; CCX_MODE_PINNED_PARENT repoints to fp1 (a promotion --
#              Marcus's); red #1 discharges. The pins' PRICE = fp1 - canonical.
#   H_control: fp1 < control => the ML + limb arm loses to ML-off even with every
#              shim free; the control stays the best free arm; red #1 stands as ruled.
# Arms: canonical hilda29l (by registry), control hilda31pe (by registry), fp_reg
# hilda31s2 (the registered parent, for the record), fp1.. the rank-1 start of each
# basin the collector found (<= 3). Compare on LIKELIHOOD over common rows, never the
# logposts (32 / 31 / 29 fitted names); AIC beside it (2k - 2L). READ, not gated;
# nothing is adopted here.
# Usage: Rscript calibration/diag_free_parent_csl3_read.R   (env FP_DIR, FP_B1)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
FP_DIR  <- local({ d <- Sys.getenv("FP_DIR", ""); if (nzchar(d)) d else
  ccx_path("calibration", "output", "multistart_20260921_hilda_csl3_seasml1_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_sd1.0452") })
FP_JOB  <- "Mac wave 2026-09-21 15:30 -> 09-22 05:04, 4-wide (frozen tree ~/ccx_frozen/20260921g_free_parent_refit; objective #13; launcher launch_1530.sh)"
FP_MAX_BASINS <- 3L
FP_OUT  <- ccx_path("outputs", "diagnostics", sprintf("free_parent_csl3_read_%s", format(Sys.Date(), "%Y%m%d")))
FP_REPRO_TOL <- 1e-3
FP_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_", hs = "^hs_")
FP_FREED <- c("ent_seas_amp_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "w_enso_l2")   # the names the canonical holds / the control holds, that this arm fits
FP_NAMES <- c(FP_FREED, "h_ml", "sst_seas_amp_NH", "sst_seas_amp_SH", "kz_deep_frac", "k_w", "u_hs", "h_hs", "pump_hs_gcm2", "q10", "beta_max", "rep_dC", "grad_off_d13c", "bomb_total", "sigma_d14c",
              "gamma_enso_land_NH", "gamma_enso_land_SH")
sink_log <- file(paste0(FP_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== THE FREE PARENT OF THE LIMB CANONICAL: the read -- %s -- %s ==\n  %s\n", format(Sys.time()), tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"), FP_JOB))

if (!file.exists(file.path(FP_DIR, "summary.csv")))
  stop("no summary.csv in ", FP_DIR, ": copy the wave's outdir into the repo and run collect_dispersed_multistart.R first.")
sm <- utils::read.csv(file.path(FP_DIR, "summary.csv")); sm <- sm[order(-sm$logpost), ]
cat(sprintf("  collector: %d starts, %d converged, %d basins; best id %d logpost %.4f; basin sizes %s\n", nrow(sm), sum(sm$converged), length(unique(sm$basin)), sm$id[1], sm$logpost[1],
            paste(sprintf("b%s n%d", names(table(sm$basin)), as.integer(table(sm$basin))), collapse = ", ")))
basin_ids <- vapply(split(sm, sm$basin), function(b) { b <- b[order(-b$logpost), ]; as.integer(b$id[1]) }, integer(1))
basin_ids <- basin_ids[order(-vapply(names(basin_ids), function(k) max(sm$logpost[sm$basin == as.integer(k)]), numeric(1)))]
b1_env <- Sys.getenv("FP_B1", ""); if (nzchar(b1_env)) basin_ids[1] <- as.integer(b1_env)
basin_ids <- basin_ids[seq_len(min(FP_MAX_BASINS, length(basin_ids)))]
cat(sprintf("  arms from the collector: %s\n", paste(sprintf("fp%d = id %d (basin %s, logpost %.4f, %s)", seq_along(basin_ids), basin_ids, names(basin_ids),
            sm$logpost[match(basin_ids, sm$id)], ifelse(sm$converged[match(basin_ids, sm$id)], "CONVERGED", "NOT converged")), collapse = "; ")))

start_file <- function(dir, id) readRDS(file.path(dir, sprintf("start_%03d.rds", id)))
start_vector <- function(dir, id) {   # the 09-18 reader's helper, verbatim: pins applied cumulatively, CCX_PINS merged by hand
  s <- start_file(dir, id); pins <- s$pins
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
       spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins, prior_z = s$prior_z, n_fit = length(s$param_names),
       src = sprintf("start_%03d (logpost %.4f, %s, %s)", id, s$logpost, if (isTRUE(s$converged)) "CONVERGED" else "NOT converged", s$kind), s = s)
}
obs <- ccx_prepare_obs(); OH <- dg_gateH_obs(obs); DO <- dg_gateD_obs()
canon <- dg_vector(CCX_MODE_CANONICAL); canon$prior_z <- canon$md$prior_z; canon$n_fit <- length(canon$md$param_names)
ctrl  <- dg_vector(CCX_MODE_SEASML0_CONTROL); ctrl$prior_z <- ctrl$md$prior_z; ctrl$n_fit <- length(ctrl$md$param_names)
fpreg <- dg_vector(CCX_MODE_PINNED_PARENT); fpreg$prior_z <- fpreg$md$prior_z; fpreg$n_fit <- length(fpreg$md$param_names)
ARMS <- list(canonical = canon, control = ctrl, fp_reg = fpreg)
for (i in seq_along(basin_ids)) ARMS[[sprintf("fp%d", i)]] <- start_vector(FP_DIR, basin_ids[[i]])
an <- names(ARMS); fpn <- grep("^fp[0-9]", an, value = TRUE)
for (a in an) cat(sprintf("  %-10s struct '%s' seas_ml %s  %d fitted names  pins %s\n", a, attr(ARMS[[a]]$p, "struct"), attr(ARMS[[a]]$p, "seas_ml"), ARMS[[a]]$n_fit, ccx_pin_label(ARMS[[a]]$pins)))

cat("\n=== A. THE BASINS IN u-SPACE ===\n")
s1 <- start_file(FP_DIR, basin_ids[[1]])
du <- function(a, b) { d <- a$u_mode - b$u_mode; names(d) <- a$param_names; d }
for (i in seq_along(basin_ids)[-1]) { si <- start_file(FP_DIR, basin_ids[[i]]); d <- du(s1, si)
  cat(sprintf("  fp1 vs fp%d (id %d, %+.2f): RMS |du| %.4f; the coordinates that separate them (|du| > 0.3):\n", i, basin_ids[[i]], si$logpost - s1$logpost, sqrt(mean(d^2))))
  big <- sort(abs(d), decreasing = TRUE); big <- big[big > 0.3]
  for (n in names(big)) cat(sprintf("    %-20s du %+.3f   fp1 %10.4g   fp%d %10.4g\n", n, d[[n]], s1$par_mode[[n]], i, si$par_mode[[n]])) }

cat("\n=== B. PARAMETERS (value, prior z); the FREED names first ===\n")
cat(sprintf("  %-20s %s\n", "name", paste(sprintf("%26s", an), collapse = " ")))
zfmt <- function(v, n) { z <- v$prior_z; if (is.null(z) || is.na(z[n])) "" else sprintf("z %+.2f", z[[n]]) }
for (n in FP_NAMES) {
  vals <- vapply(ARMS, function(v) { x <- v$pm[[n]]; if (is.null(x)) x <- v$p[[n]]; if (is.null(x)) NA_real_ else x }, numeric(1))
  cat(sprintf("  %-20s %s%s\n", n, paste(vapply(an, function(a) sprintf("%16.5g %9s", vals[[a]], zfmt(ARMS[[a]], n)), ""), collapse = " "), if (n %in% FP_FREED) "   <- freed" else ""))
}
for (a in an) { z <- ARMS[[a]]$prior_z; if (is.null(z)) next; s <- names(z)[abs(z) > 2]; cat(sprintf("  strained priors (|z| > 2) %-10s %s\n", a, if (length(s)) paste(sprintf("%s %+.2f", s, z[s]), collapse = ", ") else "none")) }

cat("\n=== 0. THE REGISTERED FILES REPRODUCE THEIR STORED STREAMS (the like-for-like guard) ===\n")
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS, MoreArgs = list(obs = obs)); ST <- lapply(ST, unlist)
for (a in c("canonical", "control", "fp_reg")) { st0 <- ARMS[[a]]$md$streams; cm0 <- intersect(names(st0), names(ST[[a]])); d0 <- sum(ST[[a]][cm0]) - sum(unlist(st0[cm0]))
  cat(sprintf("  %-10s stored %.4f recomputed %.4f diff %+.2e over %d rows -> %s\n", a, sum(unlist(st0[cm0])), sum(ST[[a]][cm0]), d0, length(cm0),
              if (abs(d0) <= FP_REPRO_TOL) "REPRODUCES" else if (a == "fp_reg") "DOES NOT (a `hilda` file restamped, never refit: expected)" else "DOES NOT -- STOP")) }
for (a in fpn) { s <- ARMS[[a]]$s; cat(sprintf("  %-4s start file logpost %.4f (on its frozen tree; the LIKELIHOOD below is recomputed under today's build)\n", a, s$logpost)) }

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP on the 26 #13 rows (common rows) ===\n")
common <- Reduce(intersect, lapply(ST, names))
cat(sprintf("  %-14s %s %9s %9s   rows\n", "group", paste(sprintf("%10s", an), collapse = ""), "fp1-can", "fp1-ctl"))
G <- lapply(FP_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(vapply(ST, function(s) sum(s[rows]), numeric(1)), n = length(rows)) })
for (g in names(G)) { x <- G[[g]]; if (x[["n"]] == 0) next
  cat(sprintf("  %-14s %s %+9.2f %+9.2f   %s\n", g, paste(sprintf("%10.2f", x[an]), collapse = ""), x[["fp1"]] - x[["canonical"]], x[["fp1"]] - x[["control"]], paste(grep(FP_GROUPS[[g]], common, value = TRUE), collapse = " "))) }
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
cat(sprintf("  %-14s %s %+9.2f %+9.2f   (%d rows)\n", "TOTAL", paste(sprintf("%10.2f", tot), collapse = ""), tot[["fp1"]] - tot[["canonical"]], tot[["fp1"]] - tot[["control"]], length(common)))
for (a in an) { extra <- setdiff(names(ST[[a]]), common); if (length(extra)) cat(sprintf("  %s-only rows: %s\n", a, paste(sprintf("%s %.2f", extra, ST[[a]][extra]), collapse = ", "))) }
cat("\n  every row, fp1 minus the canonical (the PRICE of the canonical's three pins, by row; sorted):\n"); print(round(sort(ST$fp1[common] - ST$canonical[common]), 2))
cat("\n  every row, fp1 minus the control (ML + limb + every shim free, vs ML-off; sorted):\n"); print(round(sort(ST$fp1[common] - ST$control[common]), 2))
k <- vapply(ARMS, function(v) v$n_fit, numeric(1)); aic <- 2 * k - 2 * tot
cat(sprintf("\n  AIC = 2k - 2L on the %d common rows: %s\n", length(common), paste(sprintf("%s %.2f (k %d)", an, aic, k), collapse = "; ")))
cat(sprintf("  dAIC fp1 - control %+.2f (negative = fp1 preferred); dAIC canonical - control %+.2f (test-mode-file's red #2, unchanged by this wave); dAIC canonical - fp1 %+.2f (the pins: k -%d, L %+.2f)\n",
            aic[["fp1"]] - aic[["control"]], aic[["canonical"]] - aic[["control"]], aic[["canonical"]] - aic[["fp1"]], k[["fp1"]] - k[["canonical"]], tot[["canonical"]] - tot[["fp1"]]))
d_can <- tot[["fp1"]] - tot[["canonical"]]; d_ctl <- tot[["fp1"]] - tot[["control"]]
verdict <- if (d_ctl >= 0) "H_parent: the free parent of the limb canonical is the best free arm (>= the control on likelihood); red #1 discharges on a PINNED_PARENT repoint (a promotion -- Marcus's)" else
           "H_control: the ML + limb arm with every shim free still trails ML-off; the control stays the best free arm; red #1 stands as ruled 09-19 (b)"
cat(sprintf("\n  THE QUESTION: fp1 minus the canonical %+.2f (the pins' price); fp1 minus the control %+.2f\n  -> %s\n", d_can, d_ctl, verdict))

cat("\n=== 2. THE ENSO OCEAN SLOPE and the freed names' physics ===\n")
ES <- list()
for (a in an) { s <- dg_annual_sinks(R[[a]]); es <- ccx_enso_slope(s$year, s$ocean, obs$enso_idx); ES[[a]] <- es
  cat(sprintf("  %-10s slope %+.4f +- %.4f (%.2fx obs; z %+.2f)  r %+.3f  [w_enso_l2 %.2f, gamma_enso_ocn NH %+.3f SH %+.3f]\n", a, es[["slope"]], es[["se"]], es[["slope"]] / obs$enso_slope[["slope"]],
              (es[["slope"]] - obs$enso_slope[["slope"]]) / obs$enso_slope[["se"]], es[["r"]], ARMS[[a]]$p$w_enso_l2, ARMS[[a]]$p$gamma_enso_ocn_NH, ARMS[[a]]$p$gamma_enso_ocn_SH)) }
cat("  (Meinen's bracket for w_enso_l2: [14, 25] Sv per index; the canonical's 13.71 +- 2.13 sits at its low edge)\n")

cat("\n=== 3. GATES V / H / GL / Q / D / S (the ledger's idioms) ===\n")
verd <- list(); GH <- list()
OV <- dg_gateV_obs()
for (a in an) { vd <- tryCatch(dg_gateV_verdict(dg_gateV(R[[a]]), OV), error = function(e) NULL); verd[[a]]$V <- vd
  if (!is.null(vd)) cat(sprintf("  GATE V  %-10s sd %.3f vs obs %.3f  ratio %.2f  z %+.2f  -> %s\n", a, vd$sd_model, vd$sd_obs, vd$ratio, vd$z, if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in an) { gh <- dg_gateH(ARMS[[a]], obs, OH, r = R[[a]]); GH[[a]] <- gh; vd <- dg_gateH_verdict(gh, OH); verd[[a]]$H <- vd
  cat(sprintf("  GATE H  %-10s R_co2 %.3f R_d13c %.3f  contrast z %+.2f  -> %s\n", a, vd$R_co2, vd$R_d13c, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- dg_gateGL_verdict(GH[[a]], OH); verd[[a]]$GL <- vd
  cat(sprintf("  GATE GL %-10s d13C gradient %.4f vs obs %.4f (ratio %.2f) z %+.2f  -> %s\n", a, vd$model, vd$obs, vd$ratio, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { q <- dg_gateQ(R[[a]], ARMS[[a]]); verd[[a]]$Q <- q
  cat(sprintf("  GATE Q  %-10s k-weighted %+.3f vs %.2f +- %.2f  n_sd %.2f  -> %s\n", a, q$mean, DG_Q_OBS, DG_Q_SD, q$n_sd, if (q$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- tryCatch(dg_gateD_verdict(dg_gateD(R[[a]], ARMS[[a]], DO), DO), error = function(e) NULL); verd[[a]]$D <- vd
  if (!is.null(vd)) cat(sprintf("  GATE D  %-10s asym %+.3f vs obs %+.3f  z %+.2f (NH ml %+.2f hs %+.2f | SH ml %+.2f hs %+.2f)  -> %s\n", a, vd$asym, vd$obs_asym, vd$z, vd$region[["NH_ml"]], vd$region[["NH_hs"]], vd$region[["SH_ml"]], vd$region[["SH_hs"]], if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in an) { vd <- tryCatch({ g <- dg_gateS(ARMS[[a]], obs, r = R[[a]]); dg_gateS_verdict(g) }, error = function(e) NULL); verd[[a]]$S <- vd
  if (!is.null(vd)) cat(sprintf("  GATE S  %-10s SPO ocean limb %.3f ppm @ month %.2f, bracket [%.2f, %.2f]  -> %s\n", a, vd$amp, vd$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else "FAIL")) }

cat("\n=== 4. OWED, NOT READ HERE ===\n")
cat("  the RULING: whether CCX_MODE_PINNED_PARENT repoints to fp1 (a promotion: promote_multistart_mode.R + the Hessian), and the tag v1.0-hilda29l after it.\n")
saveRDS(list(job = FP_JOB, dir = FP_DIR, ids = basin_ids, summary = sm,
             params = lapply(ARMS, function(v) list(p = v$p, pm = v$pm, prior_z = v$prior_z, src = v$src, n_fit = v$n_fit)), streams = ST, groups = G, tot = tot, aic = aic, k = k,
             enso_slope = ES, verdict = verdict, verdicts = verd, built = format(Sys.time()),
             provenance = list(commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"), seed = "none (a read; the wave's draws are seeded per id in its start files)")), paste0(FP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ NOTHING IS ADOPTED; no mode is promoted.\n", FP_OUT))
