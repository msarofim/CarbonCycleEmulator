# =====================================================================
# diag_kw_naegler_pin.R -- THE k_w TEST (Marcus, 2026-09-15 f): is the
# air-sea RATE a lever on the 1995 ocean bomb inventory?
#
# WHY. The O6 read (diag_o6_bomb_partition_hilda30c.R) found the canonical's
# ocean share of the bomb 14C 12-19 % above Naegler & Levin 2006 at the same
# input, and the canonical's k_w = 1637 m/yr = 18.7 cm/h is +13 % over Naegler
# 2009's best global-mean piston velocity <k> = 16.5 cm/h (four-study average
# 15.9 +- 3.2; Tellus B 61:372, read 09-15). Naegler has I_E ~ k, less than
# proportionally (Krakauer 2006). If the surface rate carries the partition
# excess, pinning k_w at 16.5 cm/h should drop the inventory by ~10 kmol
# (13 % of 79); if sub-ML diffusion is the bottleneck (PK-1: 70 % of the bomb
# 14C crosses the ML base by diffusion), the drop is much smaller and the fit
# restores the inventory through kz / bomb_total.
#
# STATED BEFORE THE RUN. Prediction: the drop is LESS than proportional (a few
# kmol), because the model's ML equilibrates with the air in ~0.3 yr while the
# sub-ML delivery is the slower step. Decision rule: k_w IS a lever iff, with
# k_w pinned at 16.5 cm/h and the PK-2 surface + land names re-optimised, the
# 1995 inventory falls by >= 5 kmol (>= 0.65 sigma of the objective's row) at
# a cost <= 20 log-units on the 25 rows; it is NOT a lever if the drop is
# < 5 kmol or the fit pays > 20 to keep it. Comparability caveat: Naegler's
# <k> is a wind-weighted global mean at a fixed Schmidt convention; the model's
# k_w is per ice-free area with the HS Schmidt factor -- comparable to ~10 %.
# The canonical's 18.7 is z +0.9 on Naegler's own spread, so this is a test at
# the centre of the bracket, not a refutation of the fitted value.
#
# Arms (all on the canonical's solved field, its pins, the periodic spinup):
#   RAW    k_w pinned at 16.5 cm/h, nothing else moved.
#   ARM C  + {beta_max, fert_k, q10, kz_deep_frac, h_ml, bomb_total, sigma_d14c}
#          re-optimised (the PK-2 names minus k_w); kz HELD.
#   ARM C+ the same with kz FREE as well (does the fit buy the rate back with kz?).
#   The same three at k_w pinned at the canonical's own value (the harness:
#   ARM C must find no improvement, the PK-2g gate), and a k_w PROFILE at
#   {15, 16.5, 18.7, 21} cm/h raw.
# Run from the repo root:  Rscript calibration/diag_kw_naegler_pin.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

KW_ARM       <- CCX_MODE_CANONICAL
KW_NAEGLER   <- 16.5                      # cm/h, Naegler 2009 best estimate (unnormalised, global mean)
KW_NAEGLER_SD <- 3.2                      # cm/h, the four-study spread (15.9 +- 3.2)
KW_PROFILE   <- c(15, 16.5, 18.7, 21)     # cm/h, raw profile
KW_HOURS_PER_YEAR <- 365.25 * 24
cmh_to_myr <- function(x) x * KW_HOURS_PER_YEAR / 100
myr_to_cmh <- function(x) x * 100 / KW_HOURS_PER_YEAR
KW_LAND    <- c("beta_max", "fert_k", "q10")
KW_SURF    <- c("kz_deep_frac", "h_ml", "bomb_total", "sigma_d14c")
KW_ARMC    <- c(KW_LAND, KW_SURF)
KW_NM_MAXIT <- 1500; KW_BFGS_MAXIT <- 100
KW_GATE_TOL <- 1e-4
KW_RULE_DROP <- 5; KW_RULE_COST <- 20    # kmol; log-units
KW_OUT <- ccx_path("outputs", "diagnostics", sprintf("kw_naegler_pin_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(KW_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== the k_w test at %s -- commit %s ==\n", KW_ARM, tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")))

obs <- ccx_prepare_obs(); exc_obs <- obs$excess_c14; i95 <- which(exc_obs$year == 1995)
v0 <- dg_vector(KW_ARM); md <- v0$md; kw0 <- v0$p$k_w
cat(sprintf("canonical k_w %.1f m/yr = %.2f cm/h; Naegler 2009 %.1f (spread %.1f): z %+.2f; pin at %.1f cm/h = %.1f m/yr (x%.4f)\n",
            kw0, myr_to_cmh(kw0), KW_NAEGLER, KW_NAEGLER_SD, (myr_to_cmh(kw0) - KW_NAEGLER) / KW_NAEGLER_SD, KW_NAEGLER, cmh_to_myr(KW_NAEGLER), cmh_to_myr(KW_NAEGLER) / kw0))
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: dg streams vs stored: %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams), if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < KW_GATE_TOL) "PASS" else "FAIL"))
read_point <- function(v) {
  r <- dg_run(v); out <- r$out; yr <- floor(out$t + 1e-9)
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  exc <- vapply(exc_obs$year, function(Y) ccx_c14_kmol(mean(out$ocean_C14[yr == Y]) - out$ocean_C14[1]), numeric(1))
  rows <- function(pat) sum(d[grep(pat, cm)])
  list(d = d, dlik = sum(d), exc = exc, z95 = (exc[2] - exc_obs$centre[i95]) / exc_obs$half_width[i95],
       bomb = rows("^d14c_(NH|SH)$"), co2 = rows("^co2"), d14prof = rows("^d14c_profile"), d13 = rows("^d13c"), sink = dg_gate7(r)$ocean,
       excrow = d[["excess_c14_ocean"]])
}
fmt <- function(lab, rp) sprintf("%-34s | dlik %+7.1f | exc75/95 %5.1f/%5.1f (z95 %+4.1f; row %+5.1f) | bomb %+6.1f co2 %+6.1f d14prof %+5.1f d13 %+5.1f | sink %.2f",
                                lab, rp$dlik, rp$exc[1], rp$exc[2], rp$z95, rp$excrow, rp$bomb, rp$co2, rp$d14prof, rp$d13, rp$sink)
g0 <- read_point(v0); cat(fmt("canonical", g0), "\n")
cat("\n== the k_w PROFILE, raw ==\n"); PR <- list()
for (kc in KW_PROFILE) { v <- v0; v$p$k_w <- cmh_to_myr(kc); rp <- read_point(v); PR[[as.character(kc)]] <- rp
  cat(fmt(sprintf("k_w %.1f cm/h (x%.3f) raw", kc, cmh_to_myr(kc) / kw0), rp), "\n") }
raw_n <- PR[[as.character(KW_NAEGLER)]]
el <- log(raw_n$exc[2] / g0$exc[2]) / log(cmh_to_myr(KW_NAEGLER) / kw0)
cat(sprintf("raw elasticity of the 1995 inventory to k_w: %.2f (1 = proportional; Naegler's I_E ~ k would be ~1, Krakauer < 1)\n", el))

# ---- arm C machinery (the O1/O5 scans' idiom) ----------------------------
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "kw_pin"); pm0 <- st$p
lp0 <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp0(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < KW_GATE_TOL) "PASS" else "FAIL"))
ccx_unpin_params(rm_pins); rm_pins <- list()
reopt <- function(kw_pin, free) {
  pins <- c(ccx_mode_pins(md), c(k_w = kw_pin))
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(free, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u)
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = KW_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = KW_BFGS_MAXIT, reltol = 1e-12))
  bst <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- bst$par
  v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  vv <- v0; vv$p$k_w <- kw_pin; for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
  for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
  list(kw = kw_pin, free = free, pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]), d = st_c[cm] - ref_st[cm],
       n_eval = o1$counts[1] + o2$counts[1], read = read_point(vv))
}
say <- function(lab, r) { cat(fmt(sprintf("%s (armC %+.1f raw %+.1f)", lab, r$dlik, r$dlik_raw), r$read), sprintf(" | %d evals; kz %.0f kz_deep_frac %.4f h_ml %.1f bomb_total %.1f sigma_d14c %.2f beta_max %.3f\n",
    r$n_eval, if (is.null(r$pm$kz)) v0$p$kz else r$pm$kz, r$pm$kz_deep_frac, r$pm$h_ml, r$pm$bomb_total, r$pm$sigma_d14c, r$pm$beta_max))
  cat(sprintf("        largest rows: %s\n", paste(sprintf("%s %+.1f", names(sort(r$d))[1:5], sort(r$d)[1:5]), collapse = ", "))) }
cat("\n== ARM C ==\n"); S <- list()
t0 <- proc.time()[["elapsed"]]; S$harness <- reopt(kw0, KW_ARMC); say("k_w canonical, armC (PK-2g harness)", S$harness); cat(sprintf("        [%.0f s] PK-2g: |armC - raw| = %.2e -> %s\n", proc.time()[["elapsed"]] - t0, abs(S$harness$dlik - S$harness$dlik_raw), if (abs(S$harness$dlik - S$harness$dlik_raw) < 0.05) "PASS" else "FAIL (the optimiser improves on the mode: a stale mode or a broken harness)"))
t0 <- proc.time()[["elapsed"]]; S$naegler <- reopt(cmh_to_myr(KW_NAEGLER), KW_ARMC); say(sprintf("k_w %.1f cm/h, armC (kz held)", KW_NAEGLER), S$naegler); cat(sprintf("        [%.0f s]\n", proc.time()[["elapsed"]] - t0))
t0 <- proc.time()[["elapsed"]]; S$naegler_kz <- reopt(cmh_to_myr(KW_NAEGLER), c(KW_ARMC, "kz")); say(sprintf("k_w %.1f cm/h, armC+ (kz free)", KW_NAEGLER), S$naegler_kz); cat(sprintf("        [%.0f s]\n", proc.time()[["elapsed"]] - t0))

# ---- THE DECISION RULE ------------------------------------------------------
drop_raw <- g0$exc[2] - raw_n$exc[2]; drop_c <- g0$exc[2] - S$naegler$read$exc[2]; drop_ckz <- g0$exc[2] - S$naegler_kz$read$exc[2]
cat(sprintf("\n== THE DECISION RULE: k_w IS a lever iff the 1995 inventory drops >= %.0f kmol at a cost <= %.0f log-units after arm C ==\n", KW_RULE_DROP, KW_RULE_COST))
cat(sprintf("raw: drop %.1f kmol (cost %+.1f); armC kz held: drop %.1f kmol (cost %+.1f); armC+ kz free: drop %.1f kmol (cost %+.1f; kz %.0f -> %.0f)\n",
            drop_raw, raw_n$dlik, drop_c, S$naegler$dlik, drop_ckz, S$naegler_kz$dlik, v0$p$kz, S$naegler_kz$pm$kz))
lever <- drop_c >= KW_RULE_DROP && S$naegler$dlik >= -KW_RULE_COST
cat(sprintf("VERDICT: k_w at Naegler's 16.5 cm/h is %s (armC drop %.1f kmol, cost %+.1f).\n", if (lever) "A LEVER on the 1995 inventory" else "NOT a lever on the 1995 inventory under this rule", drop_c, S$naegler$dlik))
saveRDS(list(canonical = g0, profile = PR, elasticity = el, S = S, rule = c(drop_raw = drop_raw, drop_c = drop_c, drop_ckz = drop_ckz, lever = lever),
             kw0 = kw0, naegler = KW_NAEGLER, ref = ref, ref_st = ref_st, commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA), built = format(Sys.time())), paste0(KW_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", KW_OUT))
