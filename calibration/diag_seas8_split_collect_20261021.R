# =====================================================================
# diag_seas8_split_collect_20261021.R -- T8c step 3: read the block fits, apply the
# gate, and report where each seasonal parameter lands and what each tracer loses.
#
# GATE (iii): every B_iii fit (the canonical objective on the block), from EVERY
# start -- the mode and two displaced quadratic points -- must return to the mode's
# seasonal values within S8K_GATE_SD_FRAC of the block-marginal sd (screen, B_iii),
# and must not beat the mode's objective by more than S8K_GATE_GAIN. The displaced
# starts give the gate power: a fit that cannot leave its start would pass from the
# mode and fail from them. If it fails, the read stops (Marcus, T8c brief).
# The default design's (iii), A_iii, is reported as MEASURED, beside the screen's
# prediction that it cannot reproduce the mode.
#
# Usage: Rscript calibration/diag_seas8_split_collect_20261021.R    (no RNG)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8K_DRIVER <- "calibration/diag_seas8_split_collect_20261021.R"
S8K_COMMIT <- ccx_git_stamp()
S8K_GATE_SD_FRAC <- 0.1     # as the screen's S8C_GATE_SD_FRAC
S8K_GATE_GAIN    <- 0.05    # log-units a B_iii fit may beat the mode by before the mode is called unconverged
S8K_AGREE_SD     <- 0.1     # two starts of one solo fit "agree" within this fraction of the B_iii marginal sd
S8K_CHISQ_P      <- 0.95
S8K_STEM <- file.path(S8_OUT_DIR, sprintf("t8c_split_%s", S8_MODE))
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s ===\n", S8K_DRIVER, S8K_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))
S  <- s8_setup(S8K_DRIVER)
say("alpha_photo_eps %.2f permil%s\n", S$eps, if (is.finite(S8_EPS)) " (CCX_SEAS8_EPS override)" else " (the canonical's)")
if (nzchar(S$co2seas)) say("co2_seasonal_MLO scores %s (CCX_SEAS8_CO2SEAS override)\n", S$co2seas)
SC <- readRDS(file.path(S8_SCREEN_DIR, sprintf("t8c_screen_%s.rds", S8_MODE)))
S8K_EPS_CANON <- ccx_mode_base(S$md)$alpha_photo_eps    # fits written before the override recorded no epsilon: they ran this
BLOCK <- SC$block; sdB <- SC$pred$B_iii$marg_sd
fs <- ccx_mode_fit_stats(S$md); sdU <- stats::setNames(fs$sd, S$md$param_names)[BLOCK]
files <- list.files(S8_OUT_DIR, pattern = "^t8c_fit_.*[.]rds$", full.names = TRUE)
files <- files[!grepl("_ckpt[.]rds$", files)]
FITS <- lapply(stats::setNames(files, sub("^t8c_fit_(.*)[.]rds$", "\\1", basename(files))), readRDS)
for (nm in names(FITS)) {
  if (!identical(FITS[[nm]]$provenance$mode_md5, S$mode_md5)) stop(nm, " was fitted at a different mode file")
  fe <- FITS[[nm]]$provenance$alpha_photo_eps; if (is.null(fe)) fe <- S8K_EPS_CANON
  if (!isTRUE(all.equal(fe, S$eps))) stop(nm, " was fitted at alpha_photo_eps ", fe, ", not ", S$eps)
  fc <- FITS[[nm]]$provenance$co2seas; if (is.null(fc)) fc <- ""     # fits before the override scored in situ
  if (!identical(fc, S$co2seas)) stop(nm, " was fitted with co2_seasonal_MLO on '", fc, "', not '", S$co2seas, "'")
}
say("fits read (%d): %s\n", length(FITS), paste(names(FITS), collapse = ", "))
x0 <- S$u0[BLOCK]
p_mode <- S$md$par_mode[BLOCK]
obj_at <- function(set, st, lpr) lpr + sum(st[setdiff(SC$sets[[set]], "logprior")])
mode_st <- unlist(attr(S$v0, "streams")); mode_lp <- attr(S$v0, "logprior")

say("\n=== 0. EVERY FIT: convergence, objective, distance from the mode (block-marginal sd of B_iii) ===\n")
tab <- do.call(rbind, lapply(names(FITS), function(nm) {
  F <- FITS[[nm]]; d <- (F$result$x[BLOCK] - x0) / sdB
  data.frame(fit = nm, set = F$provenance$set, start = F$provenance$start, converged = F$converged,
             n_eval = F$n_eval, cpu_min = round(F$provenance$cpu_min, 1), obj = F$result$obj,
             obj_mode = obj_at(F$provenance$set, mode_st, mode_lp), max_abs_dsd = max(abs(d)),
             worst = BLOCK[which.max(abs(d))])
}))
print(tab, row.names = FALSE, digits = 7)

say("\n=== 1. GATE (iii): B_iii from every start returns to the mode ===\n")
G3 <- tab[tab$set == "B_iii", ]
for (i in seq_len(nrow(G3))) say("  %-24s max |dx|/sd %.4f (%s), obj - mode %+.5f, converged %s\n", G3$fit[i],
                                 G3$max_abs_dsd[i], G3$worst[i], G3$obj[i] - G3$obj_mode[i], G3$converged[i])
if (s8_override()) {
  # Under an epsilon (or CO2SEAS) override the joint optimum is NOT the mode, so the gate is that the joint fit agrees with
  # ITSELF from every start (two of them far from the mode), within the same tolerance.
  xs <- lapply(G3$fit, function(n) FITS[[n]]$result$x[BLOCK])
  pair <- if (length(xs) > 1) max(vapply(seq_along(xs), function(i) max(vapply(seq_along(xs), function(j)
    max(abs((xs[[i]] - xs[[j]]) / sdB)), 0)), 0)) else Inf
  say("  (override: the gate is the starts' mutual agreement, max pairwise |dx|/sd %.4f)\n", pair)
  gate_ok <- nrow(G3) >= 3 && pair <= S8K_GATE_SD_FRAC && all(G3$converged)
} else
  gate_ok <- nrow(G3) >= 3 && all(G3$max_abs_dsd <= S8K_GATE_SD_FRAC) && all(G3$obj - G3$obj_mode <= S8K_GATE_GAIN) &&
    all(G3$converged)
say("  GATE (iii): %s (tolerance %.2f sd, gain <= %.2f, %d starts)\n", if (gate_ok) "PASS" else "FAIL",
    S8K_GATE_SD_FRAC, S8K_GATE_GAIN, nrow(G3))
A3 <- tab[tab$set == "A_iii", ]
for (i in seq_len(nrow(A3))) say("  default design %s (seasonal rows + priors only): max |dx|/sd %.3f (%s) -> %s (screen predicted 1.86 sd)\n",
                                 A3$fit[i], A3$max_abs_dsd[i], A3$worst[i],
                                 if (A3$max_abs_dsd[i] <= S8K_GATE_SD_FRAC) "reproduces the mode" else "does NOT reproduce the mode")
if (!gate_ok) { say("\n  GATE (iii) FAILED: the solo fits are not read. STOP.\n"); quit(save = "no", status = 0) }

say("\n=== 2. DO THE STARTS OF EACH SOLO FIT AGREE? (best start kept) ===\n")
best <- list()
for (s in c("B_i", "B_ii", "B_iii", "A_iii")) {
  T_ <- tab[tab$set == s, ]; if (!nrow(T_)) next
  b <- T_$fit[which.max(T_$obj)]; best[[s]] <- FITS[[b]]
  if (nrow(T_) > 1) {
    xs <- lapply(T_$fit, function(n) FITS[[n]]$result$x[BLOCK])
    dd <- max(abs((xs[[1]] - xs[[2]]) / sdB))
    say("  %-5s starts %s: objectives %s; max |dx|/sd between them %.3f -> %s; kept %s\n", s,
        paste(T_$start, collapse = " / "), paste(sprintf("%.4f", T_$obj), collapse = " / "), dd,
        if (dd <= S8K_AGREE_SD) "AGREE" else "DISAGREE", b)
  } else say("  %-5s one start (%s); kept %s\n", s, T_$start, b)
}

say("\n=== 3. WHERE EACH SEASONAL PARAMETER LANDS ===\n")
say("  natural value | move from the mode in the B_iii block-marginal sd [and in the canonical's marginal sd] | prior z\n")
pz <- function(n, x) ccx_prior_z(n, x)
land <- list()
for (n in BLOCK) {
  vals <- c(mode = p_mode[[n]], vapply(c("B_i", "B_ii", "B_iii"), function(s) best[[s]]$result$natural[[n]], 0))
  dx <- vapply(c("B_i", "B_ii", "B_iii"), function(s) (best[[s]]$result$x[[n]] - x0[[n]]), 0)
  z  <- vapply(vals, function(v) pz(n, v), 0)
  sep_ <- (best$B_i$result$x[[n]] - best$B_ii$result$x[[n]]) / sdB[[n]]
  say("  %-16s mode %9.4g (z %+5.2f) | CO2-only %9.4g %+6.2f [%+6.2f] z %+5.2f | d13C-only %9.4g %+6.2f [%+6.2f] z %+5.2f | joint %9.4g %+6.2f z %+5.2f | CO2-d13C sep %+6.2f sd\n",
      n, vals[["mode"]], z[["mode"]], vals[["B_i"]], dx[["B_i"]] / sdB[[n]], dx[["B_i"]] / sdU[[n]], z[["B_i"]],
      vals[["B_ii"]], dx[["B_ii"]] / sdB[[n]], dx[["B_ii"]] / sdU[[n]], z[["B_ii"]],
      vals[["B_iii"]], dx[["B_iii"]] / sdB[[n]], z[["B_iii"]], sep_)
  land[[n]] <- c(vals, dsd = dx / sdB[[n]], dsdU = dx / sdU[[n]], z = z, sep_sd = sep_)
}
# Mahalanobis separation of the two solo optima under the B_iii block Hessian
Hb <- SC$pred$B_iii$H
dsep <- best$B_i$result$x[BLOCK] - best$B_ii$result$x[BLOCK]
dI <- best$B_i$result$x[BLOCK] - x0; dII <- best$B_ii$result$x[BLOCK] - x0
say("\n  Mahalanobis distances under the joint objective's block curvature (sqrt(dx' (-H) dx)):\n")
say("    CO2-only vs mode %.2f | d13C-only vs mode %.2f | CO2-only vs d13C-only %.2f\n",
    sqrt(drop(t(dI) %*% (-Hb) %*% dI)), sqrt(drop(t(dII) %*% (-Hb) %*% dII)), sqrt(drop(t(dsep) %*% (-Hb) %*% dsep)))

say("\n=== 4. WHAT EACH TRACER LOSES IN THE JOINT FIT (log-units; seasonal rows of that tracer) ===\n")
rs <- function(F, rows) sum(F$result$streams[rows])
CO2 <- S8_SEAS_ROWS$co2; D13 <- S8_SEAS_ROWS$d13
loss <- c(co2 = rs(best$B_iii, CO2) - rs(best$B_i, CO2), d13 = rs(best$B_iii, D13) - rs(best$B_ii, D13))
cost_other <- c(d13_in_co2fit = rs(best$B_i, D13) - rs(best$B_iii, D13),
                co2_in_d13fit = rs(best$B_ii, CO2) - rs(best$B_iii, CO2))
for (r in c(CO2, D13)) say("  %-18s CO2-only %9.3f | d13C-only %9.3f | joint %9.3f | mode %9.3f\n", r,
                           best$B_i$result$streams[[r]], best$B_ii$result$streams[[r]],
                           best$B_iii$result$streams[[r]], mode_st[[r]])
say("  CO2 seasonal rows:  joint - CO2-only = %+.3f  (2 dL = %.2f)\n", loss[["co2"]], -2 * loss[["co2"]])
say("  d13C seasonal rows: joint - d13C-only = %+.3f  (2 dL = %.2f)\n", loss[["d13"]], -2 * loss[["d13"]])
say("  ... and what each SOLO fit costs the OTHER tracer: d13C rows in the CO2-only fit %+.3f; CO2 rows in the d13C-only fit %+.3f\n",
    cost_other[["d13_in_co2fit"]], cost_other[["co2_in_d13fit"]])
say("  scale: chi-square(%d) %.0f %% point = %.2f (a 2 dL above it on one tracer's rows is not noise-sized);\n",
    length(BLOCK), 100 * S8K_CHISQ_P, stats::qchisq(S8K_CHISQ_P, length(BLOCK)))
say("         the mean-vector headroom of each row (T8a sec.5) is the size of that row's whole first-harmonic misfit.\n")
for (s in c("B_i", "B_ii")) {
  oth <- setdiff(names(mode_st), c(CO2, D13))
  say("  %s: non-seasonal rows %+.3f vs the joint fit; log-prior %+.3f\n", s,
      sum(best[[s]]$result$streams[oth]) - sum(best$B_iii$result$streams[oth]),
      best[[s]]$result$logprior - best$B_iii$result$logprior)
}

say("\n=== 5. THE CYCLES AT EACH LANDING (peak-to-peak; peak month; d13C-per-ppm) ===\n")
L <- ccx_load_mode(S8_MODE); obs <- S$obs     # = ccx_prepare_obs() unless CCX_SEAS8_CO2SEAS is set
YR <- lapply(stats::setNames(nm = S8_STATIONS), function(st) intersect(obs$co2_seas[[st]]$year, obs$d13_seas[[st]]$year))
ov <- list(); for (st in S8_STATIONS) {
  k <- match(YR[[st]], obs$co2_seas[[st]]$year); j <- match(YR[[st]], obs$d13_seas[[st]]$year)
  ov[[paste0("co2_", st)]] <- c(mean(obs$co2_seas[[st]]$a[k]), mean(obs$co2_seas[[st]]$b[k]))
  ov[[paste0("d13_", st)]] <- c(mean(obs$d13_seas[[st]]$a[j]), mean(obs$d13_seas[[st]]$b[j])) }
cyc <- list(obs = ov)
for (s in c("mode", "B_i", "B_ii", "B_iii")) {
  mods <- if (s == "mode") list() else as.list(best[[s]]$result$natural[BLOCK])
  r <- s8_run(L, S$spf, obs, mods, YR); cyc[[s]] <- r$v
  if (s != "mode") { chk <- max(abs(unlist(r$ll)[names(best[[s]]$result$streams)] - best[[s]]$result$streams))
    say("  [re-run check %s: streams reproduce to %.1e]\n", s, chk) }
}
for (st in S8_STATIONS) {
  say("  --- %s\n", st)
  for (s in names(cyc)) {
    c_ <- cyc[[s]][[paste0("co2_", st)]]; d_ <- cyc[[s]][[paste0("d13_", st)]]
    say("  %-6s CO2 %7.4f @ %5.2f | d13C %8.5f @ %5.2f | sig %.5f | d13C - antiphase(CO2) %+.3f mo\n", s,
        s8_amp(c_), s8_ang_mo(c_), s8_amp(d_), s8_ang_mo(d_), s8_amp(d_) / s8_amp(c_),
        s8_dmo(s8_ang_mo(d_), s8_ang_mo(-c_)))
  }
}

saveRDS(list(table = tab, gate_iii = gate_ok, best = lapply(best, `[[`, "result"), landing = land,
             loss = loss, cost_other = cost_other, cycles = cyc, block = BLOCK, sd_block = sdB, sd_canonical = sdU,
             rows_used = lapply(SC$sets, function(s) setdiff(s, "logprior")),
             provenance = list(driver = S8K_DRIVER, commit = S8K_COMMIT, mode = S8_MODE, mode_file = S$mode_file,
                               mode_md5 = S$mode_md5, gate_sd_frac = S8K_GATE_SD_FRAC, gate_gain = S8K_GATE_GAIN,
                               alpha_photo_eps = S$eps, eps_override = is.finite(S8_EPS), co2seas = S$co2seas,
                               fits = vapply(FITS, function(F) F$provenance$start, ""),
                               rng = "none", units = "u-space sd; log-units; ppm; permil; months",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8K_STEM, ".rds"))
say("\nwrote %s.rds\n=== DONE ===\n", S8K_STEM)
