# =====================================================================
# diag_audit_flags_screen.R -- the five audit flags left UNTESTED by the
# 2026-09-29 (d) phi-like sweep (CHANGELOG 09-29 (d) sec.4), screened with the
# unfitted-screen protocol (calibration/diag_unfitted_screen.R).
#
# PROTOCOL (unchanged from the 09-29 screen). At the canonical (hilda29l, read
# only through ccx_mode_file()):
#   (1) FROZEN cost: the perturbation with all 29 fitted coordinates at the mode.
#   (2) REBALANCED cost: re-optimise beta_max + fert_k + kz (Nelder-Mead from the
#       mode, AF_NM_MAXIT). An UPPER BOUND on what a full refit would charge.
#       Reported as d_logpost AND split into d_loglik / d_logprior, because a
#       row that FIXES a fitted coordinate changes the prior+Jacobian as well
#       (compare on likelihood, not on a pinned logpost).
#   (3) FUTURES at the rebalanced vector: global CO2 (mean of the NH/SH boxes,
#       annual mean, ppm) at 2100 and 2300 under vvH and vvL, GCB history
#       SPLICED here (this driver runs outside the app, so it splices itself).
#
# THE FIVE FLAGS
#   F1 NPP_GLOBAL_PI (constants.R, 60 GtC/yr, uncited): x0.8 and x1.25. Pure
#      sensitivity; no literature value is inserted.
#   F2 f_luc_wood (0 = pro-rata LUC debit): 0.3 and 0.6.
#   F3 kz_deep_frac (FITTED, 0.0073, box floor 0.005): fixed at 0.073 (the ratio
#      the code comment calls HILDA's), at 465/kz_mode (HILDA's K0 465 held as
#      a PRODUCT at the mode's kz; the comment's 0.073 was 465/6356, a
#      different kz), and at the box floor.
#   F4 gamma_diff AOD background: the AOD series (CMIP7, 1850-2024) is used as
#      an ANOMALY although it carries a quiet background (~0.002), so NPP steps
#      at 1850 (0 -> background) and at 2025 (2024 value -> 0). Measured: the
#      steps in NPP (difference of two frozen flux runs, isolating the AOD
#      term), and the cost + futures of a candidate fix that subtracts the
#      quiet background (A) and, for the futures, A plus a relaxation of the
#      post-record anomaly (B). PROPOSED, NOT ADOPTED.
#   F5 rep_dC (FITTED, +3.5 sd): pinned at 0 and at 1 sd with the protocol's
#      rebalance and with a WIDE rebalance (+ its top |cor| Hessian partners);
#      the Hessian correlation row; and a probe of whether its optimum MOVES
#      with the (unfitted) land residence times -- 1-D re-optimisation of
#      rep_dC under each residence-time perturbation, against ocean controls.
#
# IDENTITY CHECKS: every perturbation route is also run at ZERO perturbation
# and must reproduce the canonical logpost (|d| < AF_ID_TOL) and futures
# (exactly). A row whose frozen cost is exactly 0 is flagged as NOT REACHED.
#
# ⚠ A SCREEN, NOT A VERDICT. Nothing here is adopted; nothing is refitted.
# No RNG is used (Nelder-Mead and Brent are deterministic); no seed to record.
#
# USAGE: Rscript calibration/diag_audit_flags_screen.R     (~30 min, AF_CORES forks)
#   run from a FROZEN COPY; BLAS threads pinned to 1 by the caller's env.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
suppressMessages(library(parallel))

# ---- labels derive from constants (project rule) --------------------
AF_DRIVER      <- "calibration/diag_audit_flags_screen.R"
AF_TAG         <- "audit_flags_screen"
AF_DATE        <- "20260929"
AF_MODE        <- "hilda29l"
AF_COMP        <- c("beta_max", "fert_k", "kz")      # the 09-29 screen's rebalance
AF_NM_MAXIT    <- 120                                # as the 09-29 screen
AF_NM_MAXIT_WIDE <- 400                              # the wider rep_dC rebalance
AF_WIDE_NPARTNER <- 3                                # extra |cor| partners for rep_dC
AF_SCEN        <- c("vvH", "vvL")
AF_YEARS       <- c(2100L, 2300L)
AF_REF_YEAR    <- 2024L
AF_END_YEAR    <- 2300L
AF_ID_TOL      <- 1e-9
AF_CORES       <- 6L
AF_UNITS       <- "logpost: natural-log units; CO2: ppm, mean of NH/SH boxes, annual mean"
AF_SPLICE_NOTE <- "GCB historical emissions (data/forcing_emissions_historical.rds) spliced over each marker's past"
# F1
AF_NPP_NAME    <- "NPP_GLOBAL_PI"
AF_NPP_FACTORS <- c(0.8, 1.25)                       # symmetric in log: 1/1.25 = 0.8
# F2
AF_FLUC_VALUES <- c(0.3, 0.6)
# F3
AF_KZDF_HILDA_RATIO <- 0.073                         # code comment, R/calibrate.R kz_deep_frac block
AF_KZDF_HILDA_K0    <- 465                           # same comment: HILDA's own K0, m2/yr
AF_KZDF_FLOOR_EPS   <- 1e-3                          # relative step above the box floor (logit is -Inf AT it)
# F4
AF_AOD_FILE    <- "forcing_volcanic_aod.rds"
AF_AOD_BG_YEARS <- c(1850, 1852)                     # the record's quiet head, before the 1853 eruption
AF_AOD_RELAX_EFOLD <- 1                              # yr, post-record relaxation of the anomaly (variant B)
AF_AOD_STEP_YEARS  <- c(1850, 2025)                  # the two seams
AF_AOD_FLUX_SPAN   <- c(1750L, 2030L)
AF_AOD_FLUX_SCEN   <- "vvH"
# F5
AF_REPDC_VALUES <- c(0, 1)                           # in units of LIK_CO2_REP_ERR (the prior sd)
AF_REPDC_PROBE  <- c("tau_leaf", "tau_wood", "tau_soil_fast", "tau_soil_slow", "litter_slow_frac")
AF_REPDC_CTRL   <- c("pump_carb_frac", "kz_zscale", "tau_q")   # ocean controls
AF_REPDC_PROBE_FACTORS <- c(0.5, 2)
AF_REPDC_RANGE  <- c(-4, 10)                         # ppm, Brent bracket
AF_FRAC_CAP     <- 0.95
AF_FRACTIONS    <- c("litter_slow_frac", "pump_carb_frac")
# SMOKE mode (AF_SMOKE=1): the same code path at trivial size, written under a
# _smoke tag -- for checking the driver end to end before the real run.
AF_SMOKE <- identical(Sys.getenv("AF_SMOKE"), "1")
# CONVERGED pass (AF_CONV=1): the protocol's maxit 120 is hit by most rows
# (convergence code 1 in the protocol CSV). This pass runs the SAME rows to
# Nelder-Mead's own tolerance with restarts, to show how loose the protocol's
# upper bound is -- and, since beta_max/fert_k sit on a cor 0.998 ridge, how
# much of each futures shift is an unfinished slide along it.
AF_NM_RESTARTS <- 0L
if (identical(Sys.getenv("AF_CONV"), "1")) { AF_TAG <- paste0(AF_TAG, "_converged")
  AF_NM_MAXIT <- 3000; AF_NM_MAXIT_WIDE <- 6000; AF_NM_RESTARTS <- 2L }
if (AF_SMOKE) { AF_TAG <- paste0(AF_TAG, "_smoke"); AF_NM_MAXIT <- 2; AF_NM_MAXIT_WIDE <- 2
  AF_REPDC_PROBE <- "tau_leaf"; AF_REPDC_CTRL <- "tau_q"; AF_REPDC_PROBE_FACTORS <- 2 }

OUT_CSV  <- ccx_path("outputs", "diagnostics", sprintf("%s_%s.csv", AF_TAG, AF_DATE))
OUT_RDS  <- ccx_path("outputs", "diagnostics", sprintf("%s_%s.rds", AF_TAG, AF_DATE))
COMMIT   <- ccx_git_stamp()
DIRTY    <- ccx_stamp_dirty(COMMIT)   # the rds keeps `dirty`: TRUE / FALSE / NA = git could not tell
RUN_AT   <- format(Sys.time(), "%Y-%m-%d %H:%M")

# ---- canonical ------------------------------------------------------
md <- readRDS(ccx_mode_file(AF_MODE))
invisible(ccx_apply_pins(md$pins))
base0 <- ccx_default_params(); base0$pump_mode <- md$pump_mode
base0 <- ccx_apply_structure(base0, md$struct, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) base0[[n]] <- md$pins[[n]]
stopifnot(!anyNA(match(AF_COMP, md$param_names)))
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
spliced <- function(s) { e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
mk_lp <- function(over) { bp <- base0; for (n in names(over)) bp[[n]] <- over[[n]]
  ccx_make_logpost(base_params = bp, by_stream = TRUE) }
u_at <- function(u, name, value) { p <- as.list(ccx_unc_to_par(u)); p[[name]] <- value
  ccx_par_to_unc(unlist(p)[md$param_names]) }

# ---- global-state switches (each row runs in its own fork) ----------
NPP_BASE <- ccx_const(AF_NPP_NAME)
CONST0   <- CCX_CONSTANTS
set_npp  <- function(v) { cc <- CONST0; cc[[AF_NPP_NAME]]$value <- v
  assign("CCX_CONSTANTS", cc, envir = globalenv()) }
reset_npp <- function() assign("CCX_CONSTANTS", CONST0, envir = globalenv())

AOD0 <- readRDS(ccx_path("data", AF_AOD_FILE))
AOD_COLS <- c("aod_NH", "aod_SH", "aod_global")
AOD_BG <- vapply(AOD_COLS, function(cc)
  mean(AOD0[[cc]][AOD0$year >= AF_AOD_BG_YEARS[1] & AOD0$year <= AF_AOD_BG_YEARS[2]]), numeric(1))
aod_bgsub <- function(bg) { a <- AOD0; for (cc in AOD_COLS) a[[cc]] <- pmax(a[[cc]] - bg[[cc]], 0); a }
aod_relax <- function(a) {             # extend the LAST month's anomaly, decaying, to the end year
  tl <- max(a$t); tt <- seq(tl + 1 / 12, AF_END_YEAR + 1, by = 1 / 12)
  ext <- data.frame(year = floor(tt), month = round((tt - floor(tt)) * 12 + 0.5), t = tt)
  for (cc in AOD_COLS) ext[[cc]] <- a[[cc]][which.max(a$t)] * exp(-(tt - tl) / AF_AOD_RELAX_EFOLD)
  rbind(a[, names(ext)], ext) }
AOD_TABLES <- list(canonical = AOD0,
                   identity  = aod_bgsub(setNames(as.list(rep(0, 3)), AOD_COLS)),
                   A_bgsub   = aod_bgsub(as.list(AOD_BG)),
                   B_bgsub_relax = aod_relax(aod_bgsub(as.list(AOD_BG))))
set_aod <- function(key) assign(".cache", AOD_TABLES[[key]], envir = environment(ccx_aod_at))

# ---- control --------------------------------------------------------
lp_ctrl_fn <- mk_lp(list())
v_ctrl <- lp_ctrl_fn(md$u_mode)
LP0 <- as.numeric(v_ctrl); ST0 <- attr(v_ctrl, "streams")
LL0 <- attr(v_ctrl, "loglik"); PR0 <- attr(v_ctrl, "logprior")
cat("=== PROVENANCE ===\n")
cat(sprintf("  driver %s | commit %s | run %s | no RNG used\n", AF_DRIVER, COMMIT, RUN_AT))
cat(sprintf("  mode %s via ccx_mode_file() = %s\n", AF_MODE, sub(".*/calibration/", "calibration/", ccx_mode_file(AF_MODE))))
cat(sprintf("  struct %s, spinup %s | stored logpost %.6f, re-scored %.6f -> %s\n", md$struct,
            ccx_mode_spinup(md), md$logpost, LP0,
            if (abs(LP0 - md$logpost) < AF_ID_TOL) "CONTROL REPRODUCES" else "*** CONTROL FAILS ***"))
if (abs(LP0 - md$logpost) >= AF_ID_TOL) stop("the unperturbed objective does not reproduce the mode")
cat(sprintf("  rebalance %s (Nelder-Mead maxit %d, wide %d, restarts %d) | futures %s to %d | %s\n  units: %s\n\n",
            paste(AF_COMP, collapse = "+"), AF_NM_MAXIT, AF_NM_MAXIT_WIDE, AF_NM_RESTARTS,
            paste(AF_SCEN, collapse = ", "),
            AF_END_YEAR, AF_SPLICE_NOTE, AF_UNITS))

futures <- function(over, u) {
  m2 <- md; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  for (n in names(over)) p[[n]] <- over[[n]]
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  unlist(lapply(AF_SCEN, function(s) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, AF_END_YEAR), emissions = spliced(s),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))$out
    co2 <- tapply((r$co2_NH + r$co2_SH) / 2, floor(r$t), mean)
    setNames(as.numeric(co2[as.character(c(AF_REF_YEAR, AF_YEARS))]),
             paste0(s, "_", c(AF_REF_YEAR, AF_YEARS)))
  }))
}
top_streams <- function(st, k = 3) { d <- st - ST0[names(st)]; d <- d[order(-abs(d))][seq_len(k)]
  paste(sprintf("%s %+.2f", names(d), d), collapse = "; ") }

# ---- one row --------------------------------------------------------
# spec: flag, label, param, base, value, over (base-param overrides), fix
# (list(name, value) for a FITTED coordinate), setup/teardown (global state),
# comp (NULL = no rebalance), maxit, u_start (optional; futures-only rows).
run_row <- function(spec) {
  t0 <- Sys.time()
  if (!is.null(spec$setup)) spec$setup()
  lp <- mk_lp(spec$over)
  u0 <- if (!is.null(spec$u_start)) spec$u_start else md$u_mode
  if (!is.null(spec$fix)) u0 <- u_at(u0, spec$fix$name, spec$fix$value)
  v0 <- lp(u0)
  u <- u0; conv <- NA_integer_; nev <- 0L
  if (length(spec$comp)) {
    ic <- match(spec$comp, md$param_names); stopifnot(!anyNA(ic))
    f <- function(x) { uu <- u0; uu[ic] <- x; v <- as.numeric(lp(uu)); if (!is.finite(v)) 1e12 else -v }
    o <- stats::optim(u0[ic], f, method = "Nelder-Mead", control = list(maxit = spec$maxit))
    nev <- o$counts[["function"]]
    for (k in seq_len(AF_NM_RESTARTS)) {       # fresh simplex from the last solution
      o2 <- stats::optim(o$par, f, method = "Nelder-Mead", control = list(maxit = spec$maxit))
      nev <- nev + o2$counts[["function"]]
      if (o2$value <= o$value) o <- o2
    }
    u[ic] <- o$par; conv <- o$convergence
  }
  v1 <- lp(u); pr <- ccx_unc_to_par(u)
  fut <- if (isTRUE(spec$no_futures)) NULL else futures(spec$over, u)
  if (!is.null(spec$teardown)) spec$teardown()
  list(flag = spec$flag, label = spec$label, param = spec$param, base = spec$base, value = spec$value,
       rebalanced = if (length(spec$comp)) paste(spec$comp, collapse = "+") else "none",
       d_frozen = as.numeric(v0) - LP0, d_rebal = as.numeric(v1) - LP0,
       d_loglik = attr(v1, "loglik") - LL0, d_logprior = attr(v1, "logprior") - PR0,
       nm_conv = conv, nm_evals = nev,
       beta_max = pr[["beta_max"]], fert_k = pr[["fert_k"]], kz = pr[["kz"]],
       kz_deep_frac = pr[["kz_deep_frac"]], K_deep = pr[["kz_deep_frac"]] * pr[["kz"]],
       rep_dC = pr[["rep_dC"]], bomb_total = pr[["bomb_total"]],
       hs_asx_frac = pr[["hs_asx_frac"]], u_hs = pr[["u_hs"]],
       top_streams = top_streams(attr(v1, "streams")),
       futures = fut, u = u, minutes = as.numeric(difftime(Sys.time(), t0, units = "mins")))
}

# ---- row specs ------------------------------------------------------
kz_mode <- md$par_mode$kz
kzdf_lo <- CCX_PARAM_TABLE$kz_deep_frac$lo
cr <- md$cor; dimnames(cr) <- list(md$param_names, md$param_names)
rep_cor <- cr["rep_dC", setdiff(md$param_names, "rep_dC")]
rep_cor <- rep_cor[order(-abs(rep_cor))]
AF_COMP_WIDE <- c(AF_COMP, head(setdiff(names(rep_cor), AF_COMP), AF_WIDE_NPARTNER))

S <- list()
add <- function(...) S[[length(S) + 1]] <<- list(...)
# identity rows (zero perturbation through each route); the first also runs
# the rebalance, to measure the optimiser's own floor from the mode
add(flag = "ID", label = "identity: NPP route x1 (+rebalance floor)", param = AF_NPP_NAME, base = NPP_BASE,
    value = NPP_BASE, setup = function() set_npp(NPP_BASE), teardown = reset_npp,
    comp = AF_COMP, maxit = AF_NM_MAXIT)
add(flag = "ID", label = "identity: f_luc_wood override at base", param = "f_luc_wood",
    base = base0$f_luc_wood, value = base0$f_luc_wood, over = list(f_luc_wood = base0$f_luc_wood))
add(flag = "ID", label = "identity: kz_deep_frac fixed at mode", param = "kz_deep_frac",
    base = md$par_mode$kz_deep_frac, value = md$par_mode$kz_deep_frac,
    fix = list(name = "kz_deep_frac", value = md$par_mode$kz_deep_frac))
add(flag = "ID", label = "identity: AOD table swapped, bg = 0", param = "aod_background",
    base = 0, value = 0, setup = function() set_aod("identity"), teardown = function() set_aod("canonical"))
add(flag = "ID", label = "identity: rep_dC fixed at mode", param = "rep_dC",
    base = md$par_mode$rep_dC, value = md$par_mode$rep_dC,
    fix = list(name = "rep_dC", value = md$par_mode$rep_dC))
# F1
for (fa in AF_NPP_FACTORS) local({ v <- NPP_BASE * fa
  add(flag = "F1", label = sprintf("NPP_GLOBAL_PI x%.2f", fa), param = AF_NPP_NAME, base = NPP_BASE,
      value = v, setup = function() set_npp(v), teardown = reset_npp, comp = AF_COMP, maxit = AF_NM_MAXIT) })
# F2
for (v in AF_FLUC_VALUES) add(flag = "F2", label = sprintf("f_luc_wood %.1f", v), param = "f_luc_wood",
                              base = base0$f_luc_wood, value = v, over = list(f_luc_wood = v),
                              comp = AF_COMP, maxit = AF_NM_MAXIT)
# F3
kzdf_vals <- c(hilda_ratio = AF_KZDF_HILDA_RATIO, hilda_K0_product = AF_KZDF_HILDA_K0 / kz_mode,
               box_floor = kzdf_lo * (1 + AF_KZDF_FLOOR_EPS))
for (k in names(kzdf_vals)) add(flag = "F3", label = sprintf("kz_deep_frac %.4g (%s)", kzdf_vals[[k]], k),
                                param = "kz_deep_frac", base = md$par_mode$kz_deep_frac, value = kzdf_vals[[k]],
                                fix = list(name = "kz_deep_frac", value = kzdf_vals[[k]]),
                                comp = AF_COMP, maxit = AF_NM_MAXIT)
# F4: the cost row (A), plus FROZEN futures rows that isolate the AOD term
add(flag = "F4", label = "AOD A: quiet background subtracted", param = "aod_background",
    base = 0, value = AOD_BG[["aod_global"]], setup = function() set_aod("A_bgsub"),
    teardown = function() set_aod("canonical"), comp = AF_COMP, maxit = AF_NM_MAXIT)
add(flag = "F4", label = "AOD A frozen (no rebalance)", param = "aod_background", base = 0,
    value = AOD_BG[["aod_global"]], setup = function() set_aod("A_bgsub"), teardown = function() set_aod("canonical"))
add(flag = "F4", label = sprintf("AOD B frozen: A + post-record relax e-fold %g yr", AF_AOD_RELAX_EFOLD),
    param = "aod_background", base = 0, value = AOD_BG[["aod_global"]],
    setup = function() set_aod("B_bgsub_relax"), teardown = function() set_aod("canonical"))
add(flag = "F4", label = sprintf("AOD canonical + post-record relax e-fold %g yr (no bg change)", AF_AOD_RELAX_EFOLD),
    param = "aod_background", base = 0, value = 0,
    setup = function() { AOD_TABLES$relax_only <<- aod_relax(AOD0); set_aod("relax_only") },
    teardown = function() set_aod("canonical"))
# F5
for (v in AF_REPDC_VALUES * LIK_CO2_REP_ERR) {
  add(flag = "F5", label = sprintf("rep_dC pinned %.1f ppm, protocol rebalance", v), param = "rep_dC",
      base = md$par_mode$rep_dC, value = v, fix = list(name = "rep_dC", value = v),
      comp = AF_COMP, maxit = AF_NM_MAXIT)
  add(flag = "F5", label = sprintf("rep_dC pinned %.1f ppm, WIDE rebalance", v), param = "rep_dC",
      base = md$par_mode$rep_dC, value = v, fix = list(name = "rep_dC", value = v),
      comp = AF_COMP_WIDE, maxit = AF_NM_MAXIT_WIDE)
}
# F5 probe: does rep_dC's optimum move with the land residence times?
probe_row <- function(nm, fa) {
  b <- base0[[nm]]; v <- if (is.na(fa)) b else b * fa
  if (nm %in% AF_FRACTIONS) v <- min(v, AF_FRAC_CAP)
  over <- if (is.na(fa)) list() else setNames(list(v), nm)
  lp <- mk_lp(over); fr <- as.numeric(lp(md$u_mode))
  o <- stats::optimize(function(r) as.numeric(lp(u_at(md$u_mode, "rep_dC", r))),
                       AF_REPDC_RANGE, maximum = TRUE, tol = 1e-4)
  data.frame(param = if (is.na(fa)) "(none)" else nm,
             class = if (is.na(fa)) "identity" else if (nm %in% AF_REPDC_PROBE) "land" else "ocean_ctrl",
             base = b, value = v, d_frozen = fr - LP0, rep_dC_hat = o$maximum,
             d_rep_dC = o$maximum - md$par_mode$rep_dC, d_reopt = o$objective - LP0)
}
P <- list(list(nm = "tau_leaf", fa = NA))
for (nm in c(AF_REPDC_PROBE, AF_REPDC_CTRL)) for (fa in AF_REPDC_PROBE_FACTORS) P[[length(P) + 1]] <- list(nm = nm, fa = fa)

# F4 NPP steps: frozen flux runs, difference isolates the AOD term
flux_npp <- function(key) {
  set_aod(key)
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  p <- ccx_overlay_par(ccx_mode_base(md), pm); p$pump_mode <- md$pump_mode
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F <- suppressWarnings(ccx_build_forcing(AF_AOD_FLUX_SCEN, AF_AOD_FLUX_SPAN, emissions = spliced(AF_AOD_FLUX_SCEN),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))
  fl <- suppressWarnings(ccx_run(sp, F, fluxes = TRUE))$fluxes
  set_aod("canonical")
  data.frame(t = fl$t, npp = fl$gpp - fl$ra, aod_NH = F$aod_NH, aod_SH = F$aod_SH)
}

# ---- run ------------------------------------------------------------
t_all <- Sys.time()
cat(sprintf("  %d screen rows, %d rep_dC probe rows, 4 flux runs, on %d forks\n\n", length(S), length(P), AF_CORES))
jobs <- c(lapply(S, function(s) list(kind = "row", s = s)),
          lapply(P, function(p) list(kind = "probe", p = p)),
          lapply(c("canonical", "A_bgsub", "B_bgsub_relax", "identity"), function(k) list(kind = "flux", k = k)))
res <- mclapply(jobs, function(j) tryCatch(switch(j$kind,
  row = run_row(j$s), probe = probe_row(j$p$nm, j$p$fa), flux = flux_npp(j$k)),
  error = function(e) structure(conditionMessage(e), class = "af_error")),
  mc.cores = AF_CORES, mc.preschedule = FALSE)
errs <- vapply(res, function(r) inherits(r, "af_error") || inherits(r, "try-error") || is.null(r), logical(1))
if (any(errs)) { print(res[errs]); stop(sum(errs), " job(s) failed") }
nS <- length(S); nP <- length(P)
rows <- res[seq_len(nS)]; probes <- do.call(rbind, res[nS + seq_len(nP)])
flx <- setNames(res[nS + nP + 1:4], c("canonical", "A_bgsub", "B_bgsub_relax", "identity"))

# ---- canonical futures (reference) ----------------------------------
f_can <- futures(list(), md$u_mode)

# ---- assemble -------------------------------------------------------
R <- do.call(rbind, lapply(rows, function(r) {
  d <- as.data.frame(r[setdiff(names(r), c("futures", "u"))], stringsAsFactors = FALSE)
  f <- r$futures; for (k in names(f_can)) d[[k]] <- f[[k]]
  for (k in names(f_can)) d[[paste0("d_", k)]] <- f[[k]] - f_can[[k]]
  d }))
# REACHED = the perturbation moved the objective OR the futures (a post-record
# change, e.g. the AOD relaxation, cannot move the 1750-2024 objective)
R$reached <- ifelse(R$flag == "ID", NA,
                    R$d_frozen != 0 | apply(R[, paste0("d_", names(f_can))] != 0, 1, any))
R$mode <- AF_MODE; R$mode_logpost <- md$logpost; R$commit <- COMMIT; R$driver <- AF_DRIVER
R$run_at <- RUN_AT; R$scenarios <- paste(AF_SCEN, collapse = "/"); R$splice <- AF_SPLICE_NOTE; R$units <- AF_UNITS

# identity verdicts
ID <- R[R$flag == "ID", ]
fut_cols <- paste0("d_", names(f_can))
id_ok <- abs(ID$d_frozen) < AF_ID_TOL & apply(abs(ID[, fut_cols]), 1, max) == 0
cat("=== IDENTITY CHECKS (zero perturbation through each route) ===\n")
for (i in seq_len(nrow(ID))) cat(sprintf("  %-44s d_frozen %+.3e  max|dCO2| %.3e  -> %s\n", ID$label[i],
                                         ID$d_frozen[i], max(abs(unlist(ID[i, fut_cols]))),
                                         if (id_ok[i]) "PASS" else "*** FAIL ***"))
cat(sprintf("  rebalance floor from the mode (row 1): d_rebal %+.4f after %d evals\n",
            ID$d_rebal[1], ID$nm_evals[1]))

cat("\n=== SCREEN (d_* vs canonical; futures = CO2 change, ppm) ===\n")
cat(sprintf("%-4s %-52s %10s %9s %9s %9s | %7s %8s %6s | %7s %7s %7s %7s\n", "flag", "row", "d_frozen",
            "d_rebal", "d_loglik", "d_prior", "b_max", "fert_k", "kz", "H2100", "H2300", "L2100", "L2300"))
for (i in which(R$flag != "ID")) with(R[i, ], cat(sprintf(
  "%-4s %-52s %+10.2f %+9.2f %+9.2f %+9.2f | %7.3f %8.1f %6.0f | %+7.1f %+7.1f %+7.1f %+7.1f%s\n",
  flag, label, d_frozen, d_rebal, d_loglik, d_logprior, beta_max, fert_k, kz,
  d_vvH_2100, d_vvH_2300, d_vvL_2100, d_vvL_2300, if (isFALSE(reached)) "  *** NOT REACHED ***" else "")))
cat("  futures to 3 decimals for the F4 rows (the AOD terms are small):\n")
for (i in which(R$flag == "F4")) with(R[i, ], cat(sprintf("   %-60s H %+.3f %+.3f  L %+.3f %+.3f\n",
  label, d_vvH_2100, d_vvH_2300, d_vvL_2100, d_vvL_2300)))
cat(sprintf("\n  canonical: vvH 2024/2100/2300 %.1f/%.1f/%.1f, vvL %.1f/%.1f/%.1f ppm\n",
            f_can[["vvH_2024"]], f_can[["vvH_2100"]], f_can[["vvH_2300"]],
            f_can[["vvL_2024"]], f_can[["vvL_2100"]], f_can[["vvL_2300"]]))
cat("\n  top stream moves at the rebalanced point (loglik units):\n")
for (i in which(R$flag != "ID")) cat(sprintf("   %-52s %s\n", R$label[i], R$top_streams[i]))
cat("\n  F3 deep diffusivity K_deep = kz_deep_frac * kz (m2/yr) at the rebalanced point:\n")
for (i in which(R$flag %in% c("F3") | R$label == "identity: kz_deep_frac fixed at mode"))
  cat(sprintf("   %-52s f %.4g  kz %.0f  K_deep %.0f\n", R$label[i], R$kz_deep_frac[i], R$kz[i], R$K_deep[i]))

# F4 steps
cat("\n=== F4: AOD background and the NPP steps ===\n")
cat(sprintf("  quiet background (mean %d-%d): NH %.5f  SH %.5f  global %.5f; gamma_diff %.2f\n",
            AF_AOD_BG_YEARS[1], AF_AOD_BG_YEARS[2], AOD_BG[["aod_NH"]], AOD_BG[["aod_SH"]],
            AOD_BG[["aod_global"]], base0$gamma_diff))
stopifnot(max(abs(flx$identity$npp - flx$canonical$npp)) == 0)
cat("  flux-run identity (bg = 0 table): NPP identical to canonical -> PASS\n")
step_at <- function(x, y0) { i <- which(x$t > y0)[1]; x$npp[i] - x$npp[i - 1] }
seam <- function(a, b, y0) step_at(data.frame(t = a$t, npp = a$npp - b$npp), y0)
STEPS <- data.frame(
  seam = AF_AOD_STEP_YEARS,
  canonical_step_GtC = sapply(AF_AOD_STEP_YEARS, function(y) seam(flx$canonical, flx$B_bgsub_relax, y)),
  A_step_GtC = sapply(AF_AOD_STEP_YEARS, function(y) seam(flx$A_bgsub, flx$B_bgsub_relax, y)),
  canonical_raw_mom_GtC = sapply(AF_AOD_STEP_YEARS, function(y) step_at(flx$canonical, y)),
  npp_level_GtC = sapply(AF_AOD_STEP_YEARS, function(y) flx$canonical$npp[which(flx$canonical$t > y)[1] - 1]))
cat("  AOD-attributable NPP step at each seam, GtC/yr (month before -> month after), from a\n",
    " difference of frozen flux runs against B, which has no step at either seam:\n")
for (i in seq_len(nrow(STEPS))) with(STEPS[i, ], cat(sprintf(
  "   %d: canonical %+.4f  | fix A %+.4f | canonical raw month-on-month %+.4f | NPP %.2f\n",
  seam, canonical_step_GtC, A_step_GtC, canonical_raw_mom_GtC, npp_level_GtC)))
cat("  (A and B differ only after the record, so A's 1850 step is B's, ~0 by construction; A's\n",
    " 2025 step remains because 2024 AOD sits above the quiet background -- B relaxes it away.)\n")

# F5
cat("\n=== F5: rep_dC ===\n")
cat(sprintf("  mode rep_dC %.3f ppm = %+.2f prior sd (sd %.1f ppm); Hessian sd_unc %.3f\n",
            md$par_mode$rep_dC, md$par_mode$rep_dC / LIK_CO2_REP_ERR, LIK_CO2_REP_ERR, md$sd_unc[["rep_dC"]]))
cat("  Hessian correlation row (top 8 |cor|):\n")
print(round(rep_cor[1:8], 3))
cat(sprintf("  WIDE rebalance set: %s\n", paste(AF_COMP_WIDE, collapse = "+")))
cat("  (the land residence times are UNFITTED, so they have no Hessian row; the probe below\n",
    "  measures instead whether rep_dC's own optimum moves when they are perturbed)\n")
print(probes, digits = 4, row.names = FALSE)

# ---- save -----------------------------------------------------------
utils::write.csv(R, OUT_CSV, row.names = FALSE)
saveRDS(list(screen = R, probes = probes, steps = STEPS, futures_canonical = f_can,
             aod_bg = AOD_BG, rep_cor = rep_cor, comp_wide = AF_COMP_WIDE,
             u = lapply(rows, `[[`, "u"),
             provenance = list(driver = AF_DRIVER, commit = COMMIT, dirty = DIRTY, run_at = RUN_AT,
                               mode = AF_MODE, mode_file = ccx_mode_file(AF_MODE), mode_logpost = md$logpost,
                               scenarios = AF_SCEN, splice = AF_SPLICE_NOTE, units = AF_UNITS,
                               nm_maxit = AF_NM_MAXIT, nm_maxit_wide = AF_NM_MAXIT_WIDE, rng = "none")),
        OUT_RDS)
cat(sprintf("\n  saved %s\n        %s\n  total %.1f min\n  ⛔ A screen: nothing adopted, nothing refitted.\n",
            OUT_CSV, OUT_RDS, as.numeric(difftime(Sys.time(), t_all, units = "mins"))))
