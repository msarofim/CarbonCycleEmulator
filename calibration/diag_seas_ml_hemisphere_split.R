# =====================================================================
# diag_seas_ml_hemisphere_split.R -- RULING 1's TEST (Marcus, 2026-09-19: "do the test").
# The seasonal mixed layer (round 6, option A) costs ~6 log-units against the ML-off
# arm at equal names (test (a), 09-18 g) and ~10 against the pinned canonical, under
# objectives #12 and #13 alike -- and ALL of it lands on the NH seasonal rows
# (d13c_seasonal_MLO, co2_seasonal_MLO), while the mechanism was motivated by the SH
# (the SPO amplitude; P1c's "a low-latitude box given a high-latitude cycle"). THE
# QUESTION: is it the MECHANISM that costs, or its NH DRIVER? Two hypotheses:
#   H_driver : with the NH excursion FLATTENED (mean-preserving, f = 1, no entrainment)
#              and the SH cycle kept, the NH seasonal rows recover most of the ~6 => the
#              ML is right in the SH and wrong in the NH => option B (latitude structure
#              / a hemisphere-split driver) is the ruling, not keep-as-built or drop.
#   H_mech   : NH-off recovers little; the cost is the entrainment itself (or the SH
#              cycle bleeding into the NH rows through the gradient) => keep (mechanism
#              vs fit) or drop is the ruling.
# A CONDITIONAL scan at two fitted points (no refit): the canonical hilda30e (ML on,
# shim pinned 0) and fp1, test (a)'s point (ML on, shim free 9.13) -- each with the
# cycle full / NH flat / SH flat / both flat. The control hilda31pe (ML off, shim
# 18.02, ITS OWN point) is the reference row. ⚠ Conditional: a flattened hemisphere at
# a point fitted with it on is not a refit of that arm (the 09-18 b lesson: "the
# shim's optimum is 0" was conditional on h_ml 64.7). It separates the hypotheses; a
# refit under the winning form is the next step, not this one.
# Mechanism of the knock-out: ccx_mld_shape() is replaced in the session by a wrapper
# that returns the flat Fourier set (a0 = 1, a = b = 0, f_min = f_max = 1) for the
# named hemisphere -- the LS climatology's other hemisphere is untouched, and the
# guard/aux/C++ path is the production one (ccx_seas_ml_guard reads the shape by name).
# Output: outputs/diagnostics/seas_ml_hemisphere_split_<date>.{log,rds}
# Usage: Rscript calibration/diag_seas_ml_hemisphere_split.R   (~2 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
HS_OUT <- ccx_path("outputs", "diagnostics", sprintf("seas_ml_hemisphere_split_%s", format(Sys.Date(), "%Y%m%d")))
HS_TA_DIR <- ccx_path("calibration", "output", "multistart_20260918_hilda_c_seasml1_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_w_enso_l2=0_sd1.0452")
HS_TA_ID  <- 18L                       # fp1 (09-18 g)
HS_ROWS_NH <- c("d13c_seasonal_MLO", "co2_seasonal_MLO"); HS_ROWS_SH <- c("d13c_seasonal_SPO", "co2_seasonal_SPO")
HS_ROWS_GRAD <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk", "d13c_gradient", "co2_gradient")
HS_REPRO_TOL <- 1e-3
sink_log <- file(paste0(HS_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("SEASONAL ML HEMISPHERE SPLIT  %s\n  canonical %s (ML on, shim pinned), fp1 = test (a) id %d (ML on, shim free), control %s (ML off)\n",
            format(Sys.time()), CCX_MODE_CANONICAL, HS_TA_ID, CCX_MODE_SEASML0_CONTROL))

# ---- the knock-out: a per-hemisphere flat shape through the production entry point ----
.mld_shape_prod <- ccx_mld_shape
.flat_co <- function(co) { z <- co; z$a[] <- 0; z$b[] <- 0; z$a0 <- 1; z$f_month[] <- 1; z$f_min <- 1; z$f_max <- 1; z }
HS_FLAT <- character(0)                # which hemispheres are flattened, set per arm below
ccx_mld_shape <- function(box = "ls") { co <- .mld_shape_prod(box); for (h in HS_FLAT) co[[h]] <- .flat_co(co[[h]]); co }
# prove the knock-out is what it says: flat => f = 1, dfdt = 0 at every t; untouched hemisphere bit-identical
HS_FLAT <- "NH"; co_t <- ccx_mld_shape("ls"); tt <- (seq_len(48) - 0.5) / 48
stopifnot(all(abs(vapply(tt, function(t) ccx_mld_eval(co_t$NH, t)$f, numeric(1)) - 1) < 1e-12),
          all(abs(vapply(tt, function(t) ccx_mld_eval(co_t$NH, t)$dfdt, numeric(1))) < 1e-12),
          identical(co_t$SH, .mld_shape_prod("ls")$SH))
HS_FLAT <- character(0)
cat("  knock-out verified: a flattened hemisphere evaluates to f = 1, dfdt = 0 at 48 phases; the other hemisphere is bit-identical to production\n")
co_p <- .mld_shape_prod("ls")
cat(sprintf("  the LS climatology's excursion: NH f in [%.3f, %.3f] (max at tau %.2f), SH f in [%.3f, %.3f] (max at tau %.2f)\n",
            co_p$NH$f_min, co_p$NH$f_max, co_p$NH$t_max, co_p$SH$f_min, co_p$SH$f_max, co_p$SH$t_max))

# ---- arms ----
start_vector <- function(dir, id) {
  s <- readRDS(file.path(dir, sprintf("start_%03d.rds", id))); pins <- s$pins
  .todo <- pins[names(pins) %in% CCX_PARAM_NAMES]
  if (length(.todo)) { .prev <- CCX_PINS; invisible(ccx_apply_pins(.todo)); assign("CCX_PINS", c(.prev, .todo), envir = environment(ccx_apply_pins)) }
  p <- ccx_default_params(); p$pump_mode <- s$pump_mode
  p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
  for (n in names(pins)) p[[n]] <- pins[[n]]
  pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
       grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c, spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic",
       pins = pins, prior_z = s$prior_z, src = sprintf("start_%03d (logpost %.4f)", id, s$logpost), s = s)
}
obs <- ccx_prepare_obs()
canon <- dg_vector(CCX_MODE_CANONICAL); ctl <- dg_vector(CCX_MODE_SEASML0_CONTROL); fp1 <- start_vector(HS_TA_DIR, HS_TA_ID)
POINTS <- list(canonical = canon, fp1 = fp1)
VARIANTS <- list(full = character(0), NH_flat = "NH", SH_flat = "SH", both_flat = c("NH", "SH"))

cat("\n=== 0. THE TWO REGISTERED FILES REPRODUCE THEIR STORED STREAMS (with the production shape) ===\n")
ST <- list(); R <- list()
run_arm <- function(v, flat) { HS_FLAT <<- flat; r <- dg_run(v); st <- dg_streams(r, v, obs = obs); HS_FLAT <<- character(0); list(r = r, st = st) }
for (a in c("canonical", "control")) { v <- if (a == "canonical") canon else ctl; x <- run_arm(v, character(0)); ST[[a]] <- x$st; R[[a]] <- x$r
  st0 <- v$md$streams; cm <- intersect(names(st0), names(x$st)); d0 <- sum(x$st[cm]) - sum(unlist(st0[cm]))
  cat(sprintf("  %-10s stored %.4f recomputed %.4f diff %+.2e over %d rows -> %s\n", a, sum(unlist(st0[cm])), sum(x$st[cm]), d0, length(cm), if (abs(d0) <= HS_REPRO_TOL) "REPRODUCES" else "DOES NOT REPRODUCE -- read nothing below")) }

cat("\n=== 1. THE SCAN: each fitted point x {full, NH flat, SH flat, both flat}; likelihood on the 26 rows ===\n")
for (pn in names(POINTS)) for (vn in names(VARIANTS)) { lab <- paste(pn, vn, sep = ":"); if (pn == "canonical" && vn == "full") { ST[[lab]] <- ST$canonical; R[[lab]] <- R$canonical; next }
  x <- run_arm(POINTS[[pn]], VARIANTS[[vn]]); ST[[lab]] <- x$st; R[[lab]] <- x$r }
common <- Reduce(intersect, lapply(ST, names)); others <- setdiff(common, c(HS_ROWS_NH, HS_ROWS_SH, HS_ROWS_GRAD))
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
sumrows <- function(s, rows) sum(s[intersect(rows, common)])
cat(sprintf("  %-22s %10s %9s %9s %9s %9s %9s %9s %9s\n", "arm", "total", "NH seas", "SH seas", "grad rows", "other", "d13c_MLO", "co2_MLO", "d13c_SPO"))
row <- function(lab) cat(sprintf("  %-22s %10.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f\n", lab, tot[[lab]], sumrows(ST[[lab]], HS_ROWS_NH), sumrows(ST[[lab]], HS_ROWS_SH), sumrows(ST[[lab]], HS_ROWS_GRAD), sumrows(ST[[lab]], others),
                             ST[[lab]][["d13c_seasonal_MLO"]], ST[[lab]][["co2_seasonal_MLO"]], ST[[lab]][["d13c_seasonal_SPO"]]))
row("control")
for (pn in names(POINTS)) for (vn in names(VARIANTS)) row(paste(pn, vn, sep = ":"))
cat(sprintf("  (%d common rows; 'other' = the %d rows outside the seasonal and gradient sets)\n", length(common), length(others)))

cat("\n=== 2. WHAT EACH KNOCK-OUT RECOVERS, against the control (ML off, its own point) ===\n")
gap <- function(lab, rows = common) sum(ST[[lab]][rows]) - sum(ST$control[rows])
for (pn in names(POINTS)) {
  g_full <- gap(paste0(pn, ":full")); cat(sprintf("  at %s's point: full ML minus control = %+.2f on 26 rows (NH seasonal %+.2f, SH seasonal %+.2f, gradients %+.2f)\n", pn, g_full,
                                                   gap(paste0(pn, ":full"), HS_ROWS_NH), gap(paste0(pn, ":full"), HS_ROWS_SH), gap(paste0(pn, ":full"), HS_ROWS_GRAD)))
  for (vn in c("NH_flat", "SH_flat", "both_flat")) { lab <- paste(pn, vn, sep = ":"); d <- tot[[lab]] - tot[[paste0(pn, ":full")]]
    cat(sprintf("    %-10s vs full: %+7.2f total; NH seasonal %+6.2f (d13c_MLO %+6.2f, co2_MLO %+6.2f); SH seasonal %+6.2f; gradients %+6.2f; other %+6.2f -> %s of the gap to the control recovered on the NH rows\n", vn, d,
                sumrows(ST[[lab]], HS_ROWS_NH) - sumrows(ST[[paste0(pn, ":full")]], HS_ROWS_NH), ST[[lab]][["d13c_seasonal_MLO"]] - ST[[paste0(pn, ":full")]][["d13c_seasonal_MLO"]], ST[[lab]][["co2_seasonal_MLO"]] - ST[[paste0(pn, ":full")]][["co2_seasonal_MLO"]],
                sumrows(ST[[lab]], HS_ROWS_SH) - sumrows(ST[[paste0(pn, ":full")]], HS_ROWS_SH), sumrows(ST[[lab]], HS_ROWS_GRAD) - sumrows(ST[[paste0(pn, ":full")]], HS_ROWS_GRAD), sumrows(ST[[lab]], others) - sumrows(ST[[paste0(pn, ":full")]], others),
                { gN <- gap(paste0(pn, ":full"), HS_ROWS_NH); if (abs(gN) < 0.5) "n/a (no NH gap)" else sprintf("%.0f %%", 100 * (sumrows(ST[[lab]], HS_ROWS_NH) - sumrows(ST[[paste0(pn, ":full")]], HS_ROWS_NH)) / (-gN)) })) } }

cat("\n=== 3. GATE S and the SPO ocean limb (the mechanism's own product) ===\n")
for (lab in c("control", paste("canonical", names(VARIANTS), sep = ":"), paste("fp1", names(VARIANTS), sep = ":"))) {
  v <- if (lab == "control") ctl else POINTS[[sub(":.*", "", lab)]]; HS_FLAT <- if (lab == "control") character(0) else VARIANTS[[sub(".*:", "", lab)]]
  vd <- tryCatch(dg_gateS_verdict(dg_gateS(v, obs, r = R[[lab]])), error = function(e) NULL); HS_FLAT <- character(0)
  if (!is.null(vd)) cat(sprintf("  GATE S  %-22s SPO ocean limb %.3f ppm @ month %.2f  -> %s\n", lab, vd$amp, vd$mo, if (vd$pass) "PASS" else sprintf("FAIL (%+.2f mo)", vd$d_mo))) }

cat("\n=== 4. VERDICT (conditional; a refit under the winning form is the next step) ===\n")
recN <- function(pn) { gN <- gap(paste0(pn, ":full"), HS_ROWS_NH); if (abs(gN) < 0.5) NA_real_ else (sumrows(ST[[paste0(pn, ":NH_flat")]], HS_ROWS_NH) - sumrows(ST[[paste0(pn, ":full")]], HS_ROWS_NH)) / (-gN) }
rc <- recN("canonical"); rf <- recN("fp1")
verdict <- if (all(is.finite(c(rc, rf))) && rc >= 0.5 && rf >= 0.5) "H_driver: flattening the NH cycle recovers >= half the NH gap at both points -- the ML is right in the SH and wrong in the NH; a hemisphere-split / latitude-structured driver (option B) is the form to refit" else
           if (all(is.finite(c(rc, rf))) && rc < 0.25 && rf < 0.25) "H_mech: the NH knock-out recovers little -- the cost is the entrainment itself; the ruling is keep (mechanism) vs drop (fit)" else "MIXED -- read section 2"
cat(sprintf("  NH gap recovered by NH_flat: canonical %s, fp1 %s\n  -> %s\n", if (is.na(rc)) "n/a" else sprintf("%.0f %%", 100 * rc), if (is.na(rf)) "n/a" else sprintf("%.0f %%", 100 * rf), verdict))
saveRDS(list(streams = ST, tot = tot, common = common, verdict = verdict, rec = c(canonical = rc, fp1 = rf), shape = co_p, built = format(Sys.time())), paste0(HS_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ NOTHING IS ADOPTED.\n", HS_OUT))
