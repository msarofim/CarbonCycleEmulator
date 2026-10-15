
# =====================================================================
# diag_sigma_inflation_profile.R -- STAGE B: THE h_ml PROFILE WITH
# σ-INFLATION ON, AND THE ARGMAX READ DIRECTLY.
#
# PRE-REGISTERED: notes/prereg_2026-08-28b_sigma_inflation_pricing.md, the
# AMENDMENT, committed (672dd8b) BEFORE this file existed. Gates copied unchanged.
#
# Stage A (diag_sigma_inflation_pricing.R, 1ea4922) bracketed every point. G1
# FAILED on the shallow side: max UPPER(out) -1543.817 at 82 m against max
# LOWER(in) -1544.358 at 85.01 m, an overlap of 0.541 against widths of ~0.5-0.65.
# This is the prereg's own remedy -- refit all 26 points with the rows ON.
#
# ⚠ NOTHING HERE CHANGES THE SHIPPED OBJECTIVE. LIK_OCEAN_GRAD_HML_OK_RETIRED and the
# skip are untouched on disk. ccx_ocean_grad_scored() is overridden IN THIS
# DRIVER'S ENVIRONMENT ONLY, via an exact algebraic identity (prereg B.1), so the
# shipped ccx_loglik/ccx_make_logpost path does the scoring. No refit is owed by
# anything it prints. [[hml_cliff_is_the_free_lunch]] [[match_incumbents_optim]]
#
# Usage:  Rscript calibration/diag_sigma_inflation_profile.R
# ⚠ ~45-90 min. Run from a FROZEN COPY and HOLD THE PROCESS -- buffered rows have
# been lost to a reaper twice on this arc.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

SB_YEARS  <- c(1750, 2024)
SB_FREE   <- c("beta_max", "fert_k", "k_w", "kz", "pump_grad")   # 08-28 prereg sec.2
SB_PROF   <- "h_ml"
SB_BAND   <- LIK_OCEAN_GRAD_HML_OK_RETIRED
SB_GRID   <- c(32, 38, 45, 55, 65, 75, 82, 84.90, 84.99,
               85.01, 85.10, 88, 92, 96.4737, 104, 112, 118, 119.9, 119.99,
               120.01, 120.1, 126, 140, 160, 185, 198)      # §5's grid, unchanged
SB_MAXIT  <- 1200; SB_RESTARTS <- 4; SB_RESTOL <- 0.02
SB_STAGEA <- ccx_path("outputs", "diagnostics", "sigma_inflation_pricing.rds")
SB_OUT    <- ccx_path("outputs", "diagnostics", "sigma_inflation_profile.rds")
# ---- PRE-REGISTERED GATES, prereg amendment sec.B.2.
SB_B2_NOISE  <- 0.70     # log-units; the refit's own restart noise floor
SB_B3_TOL    <- 1e-6     # bracket-containment tolerance
SB_GUARD_TOL <- 1e-6     # the override must reproduce Stage A's LOWER at the mode
SB_S6_CLAIM  <- 1.60     # what 08-28 sec.6 inferred
SB_SKIP_PULL <- 7.39     # the shipped skip's own pull (08-28 sec.5)

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

A  <- readRDS(SB_STAGEA)
SR <- A$sigma_rep
md <- readRDS(ccx_mode_file())
pm <- ccx_mode_params(md)                    # ⚠ NOT ccx_unc_to_par(md$u_mode)
tg <- ccx_ocean_gradient_target()
ROWS <- c("dic", "d13c", "alk")

sb_sigma_rep <- function(row, h) stats::splinefun(SR[[row]]$h, SR[[row]]$sigma_rep,
                                                  method = "monoH.FC")(h)
sb_sd_obs <- function(row) tg[[row]]$sd
sb_sd_eff <- function(row, h) sqrt(sb_sd_obs(row)^2 + pmax(0, sb_sigma_rep(row, h))^2)
# The additive constant the identity leaves behind. CONSTANT WITHIN A POINT
# because h_ml is fixed there, so it cannot influence the optimization.
sb_const <- function(h) sum(vapply(ROWS, function(r)
  -log(sb_sd_eff(r, h) / sb_sd_obs(r)), numeric(1)))

# ---------------------------------------------------------------------
# THE OVERRIDE. R/ files are source()d into globalenv here, so assigning the
# name rebinds what ccx_loglik() calls -- deliberately, visibly, and only in
# this process. The shipped definition is captured first and restored at exit so
# a sourced session cannot leak the override.
# ---------------------------------------------------------------------
.sb_shipped <- ccx_ocean_grad_scored
on.exit(assign("ccx_ocean_grad_scored", .sb_shipped, envir = globalenv()), add = TRUE)
ccx_ocean_grad_scored <- function(out, spin, pump = NULL) {
  tgt <- ccx_ocean_gradient_target()
  if (is.null(tgt)) return(NULL)
  h <- spin$grid$h_ml
  # ⚠ THE BAND GATE IS DELIBERATELY ABSENT -- that is the whole experiment.
  gd <- ccx_model_ocean_gradient(out, spin$aux, spin$grid,
                                 list(surf = tgt$dic$epoch_surf, deep = tgt$dic$epoch_deep))
  g3 <- ccx_model_ocean_gradient(out, spin$aux, spin$grid,
                                 list(surf = tgt$d13c$epoch_surf, deep = tgt$d13c$epoch_deep))
  if (is.null(gd) || is.null(g3)) return(NULL)
  if (is.null(pump) && !is.null(spin$aux$pump))
    pump <- list(S_org  = lapply(spin$aux$pump, `[[`, "org"),
                 S_carb = lapply(spin$aux$pump, `[[`, "carb"))
  v <- list(dic = gd$dic, d13c = g3$d13c,
            alk = ccx_model_ocean_alk_gradient(spin, pump = pump))
  # v' = t - (t - v) * sd_obs / sd_eff  =>  scoring v' at sd_obs equals scoring
  # v at sd_eff, up to the per-h constant sb_const(h) added by the caller.
  for (r in ROWS) {
    t_r <- tgt[[r]]$target
    v[[r]] <- t_r - (t_r - v[[r]]) * sb_sd_obs(r) / sb_sd_eff(r, h)
  }
  v
}

u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
i_h <- match(SB_PROF, CCX_PARAM_NAMES)
idx <- match(SB_FREE, CCX_PARAM_NAMES); stopifnot(!anyNA(idx), !(i_h %in% idx))
tb <- CCX_PARAM_TABLE$h_ml
stopifnot(tb$lo == 30, tb$hi == 200, tb$tr == "logit")
to_u <- function(h) log((h - tb$lo) / (tb$hi - h))
u0[i_h] <- to_u(pm$h_ml)
stopifnot(abs(ccx_unc_to_par(u0)$h_ml - pm$h_ml) < 1e-9)

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp_raw <- ccx_make_logpost(years = SB_YEARS, base_params = bp)
lp_inf <- function(u) lp_raw(u) + sb_const(ccx_unc_to_par(u)$h_ml)

cat(sprintf("mode %s | h_ml %.4f m\n", basename(ccx_mode_file()), pm$h_ml))
cat(sprintf("Stage A: %s\n", basename(SB_STAGEA)))
cat("⚠ ccx_ocean_grad_scored() is OVERRIDDEN in this process: no band gate, shrunk\n")
cat("  residuals, and the normalisation carried as a per-point constant.\n")

# ---------------------------------------------------------------------
# THE GUARD. Stage A computed LOWER by a completely different route -- a direct
# dnorm at sd_eff on a separately-run gradient. Agreement to 1e-6 cross-checks
# BOTH. The run ABORTS if it fails.
# ---------------------------------------------------------------------
sep("GUARD -- the override must reproduce Stage A's LOWER at the mode")
k_m  <- names(A$rows)[which.min(abs(vapply(A$rows, function(x) x$h, 0) - pm$h_ml))]
a_m  <- A$rows[[k_m]]
prof <- readRDS(ccx_path("outputs", "diagnostics", "hml_unbound_profile.rds"))
pv_m <- prof$res[[k_m]]$pv
u_m  <- vapply(CCX_PARAM_NAMES, function(n) NA_real_, 0)
# rebuild u from the STORED parameter vector, so the guard tests the same vector
# Stage A used rather than a re-optimized neighbor of it
u_m  <- ccx_par_to_unc(pv_m)
got  <- lp_inf(u_m)
cat(sprintf("  Stage A LOWER(%.4f) = %+.6f\n", a_m$h, a_m$lower))
cat(sprintf("  override      lp    = %+.6f     |diff| = %.3e\n", got, abs(got - a_m$lower)))
if (!isTRUE(abs(got - a_m$lower) < SB_GUARD_TOL))
  stop(sprintf("GUARD FAILED: the override does not reproduce Stage A (%.3e > %.1e). ",
               abs(got - a_m$lower), SB_GUARD_TOL),
       "One of the two routes is wrong; do NOT interpret a profile built on it.")
cat("  PASS -- two independent routes agree; the override is the identity it claims.\n")
flush.console()

# ---------------------------------------------------------------------
# THE PROFILE. §5's machinery verbatim, on §5's grid, with lp_inf.
# ---------------------------------------------------------------------
fit_at <- function(v0, ua) {
  objf <- function(v) { u <- ua; u[idx] <- v; -lp_inf(u) }
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = SB_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 150, reltol = 1e-12)),
              silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = SB_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n <- n + 1
    if (gain < SB_RESTOL || n >= SB_RESTARTS) break
  }
  list(par = v, value = best, restarts = n, gain = gain, converged = gain < SB_RESTOL)
}

sep("THE INFLATED PROFILE -- h_ml fixed, the uptake set re-optimised at every point")
kzb <- md$kz_bracket
cat(sprintf("  %9s %5s | %11s | %9s %6s | %9s | %11s %11s %3s | %2s %8s\n", "h_ml", "rows",
            "cond dlp", "kz", "%brkt", "pump_grad", "A LOWER", "A UPPER", "in", "re", "gain"))
flush.console()
SB_ANCHOR <- SB_GRID[which.min(abs(SB_GRID - pm$h_ml))]
res <- list(); ref <- NA
run_leg <- function(hs, v_start) {
  v_warm <- v_start
  for (h in hs) {
    ua <- u0; ua[i_h] <- to_u(h)
    t0 <- Sys.time()
    ft <- try(fit_at(v_warm, ua), silent = TRUE)
    if (inherits(ft, "try-error")) {
      cat(sprintf("  %9.4f  ⚠ FIT FAILED: %s\n", h, sub("\n.*", "", as.character(ft))))
      flush.console(); next
    }
    v_warm <- ft$par
    uh <- ua; uh[idx] <- ft$par; pv <- ccx_unc_to_par(uh)
    stopifnot(abs(pv$h_ml - h) < 1e-8)
    if (is.na(ref)) ref <<- -ft$value
    live <- h >= SB_BAND[1] && h <= SB_BAND[2]
    ka <- sprintf("%.4f", h); aa <- A$rows[[ka]]
    inb <- !is.null(aa) && -ft$value >= aa$lower - SB_B3_TOL && -ft$value <= aa$upper + SB_B3_TOL
    res[[ka]] <<- list(h = h, lp = -ft$value, pv = pv, live = live, u_free = ft$par,
                       converged = ft$converged, a_lower = if (is.null(aa)) NA else aa$lower,
                       a_upper = if (is.null(aa)) NA else aa$upper, in_bracket = inb)
    cat(sprintf("  %9.4f %5s | %+11.2f | %9.1f %5.1f%% | %9.1f | %+11.2f %+11.2f %3s | %2d %8.4f%s  [%.0fs]\n",
                h, if (live) "LIVE" else "off", -ft$value - ref, pv$kz,
                100*(pv$kz - kzb[1])/diff(kzb), pv$pump_grad,
                if (is.null(aa)) NA else aa$lower, if (is.null(aa)) NA else aa$upper,
                if (inb) "ok" else "⚠", ft$restarts, ft$gain,
                if (!ft$converged) " ⚠MOVING" else "",
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    flush.console()
    # ⚠ WRITE THE ARTIFACT EVERY ROW, BEFORE ANY PRETTY-PRINTING. 45 minutes of
    # fits were destroyed on 08-28 because saveRDS came after a reporting bug.
    saveRDS(list(res = res, grid = SB_GRID, band = SB_BAND, free = SB_FREE,
                 gates = c(B2 = SB_B2_NOISE, B3 = SB_B3_TOL),
                 mode_file = ccx_mode_file(), stage_a = SB_STAGEA), SB_OUT)
  }
  v_warm
}
invisible(run_leg(rev(sort(SB_GRID[SB_GRID <= SB_ANCHOR])), u0[idx]))
invisible(run_leg(sort(SB_GRID[SB_GRID > SB_ANCHOR]),
                  res[[sprintf("%.4f", SB_ANCHOR)]]$u_free))
res <- res[order(vapply(res, function(x) x$h, 0))]
saveRDS(list(res = res, grid = SB_GRID, band = SB_BAND, free = SB_FREE,
             gates = c(B2 = SB_B2_NOISE, B3 = SB_B3_TOL),
             mode_file = ccx_mode_file(), stage_a = SB_STAGEA), SB_OUT)
cat(sprintf("\nwrote %s\n", SB_OUT))

# ---------------------------------------------------------------------
# THE PRE-REGISTERED GATES
# ---------------------------------------------------------------------
H  <- vapply(res, function(x) x$h, 0); LV <- vapply(res, function(x) x$live, TRUE)
LP <- vapply(res, function(x) x$lp, 0); IB <- vapply(res, function(x) x$in_bracket, TRUE)
at <- function(h) which.min(abs(H - h))

sep("THE PRE-REGISTERED GATES")
h_arg <- H[which.max(LP)]
b1 <- h_arg >= SB_BAND[1] && h_arg <= SB_BAND[2]
cat(sprintf("B1  argmax IN-BAND               : %.4f m   %s\n", h_arg,
            if (b1) "PASS" else "FAIL (predicted -- see prereg B.2)"))
best_in <- max(LP[LV]); best_out <- max(LP[!LV]); resid <- best_out - best_in
b2 <- resid <= SB_B2_NOISE
cat(sprintf("\nB2  residual pull <= %.2f        : %+.3f   %s\n", SB_B2_NOISE, resid,
            if (b2) "PASS" else "FAIL"))
cat(sprintf("    best in-band %+.3f at %.4f m | best out %+.3f at %.4f m\n",
            best_in, H[LV][which.max(LP[LV])], best_out, H[!LV][which.max(LP[!LV])]))
cat(sprintf("    shipped skip's pull %+.2f -> %+.3f  (%.0f%% reduction)\n",
            SB_SKIP_PULL, resid, 100 * (1 - resid / SB_SKIP_PULL)))
cat(sprintf("    08-28 sec.6 inferred ~%.2f: %s\n", SB_S6_CLAIM,
            if (resid < SB_S6_CLAIM) "OVERSTATED" else "STANDS"))
b3 <- all(IB[!is.na(IB)])
cat(sprintf("\nB3  Stage A's bracket held       : %d/%d in   %s\n", sum(IB), length(IB),
            if (b3) "PASS" else "FAIL -- A BOUND IS NOT RIGOROUS"))
if (!b3) for (k in names(res)[!IB])
  cat(sprintf("    ⚠ %s: %+.4f not in [%+.4f, %+.4f]\n", k, res[[k]]$lp,
              res[[k]]$a_lower, res[[k]]$a_upper))
j85 <- LP[at(84.99)] - LP[at(85.01)]; j120 <- LP[at(120.01)] - LP[at(119.99)]
b4 <- j85 <= 0 && j120 <= 0
cat(sprintf("\nB4  signed jump OUT of band <= 0 : 85 %+.4f | 120 %+.4f   %s\n",
            j85, j120, if (b4) "PASS" else "FAIL"))
cat(sprintf("    shipped, same straddles      : 85 %+.4f | 120 %+.4f\n", 7.3005, 8.4257))

sep("VERDICT")
cat(sprintf("B1 %s  B2 %s  B3 %s  B4 %s\n", ifelse(b1,"✓","✗"), ifelse(b2,"✓","✗"),
            ifelse(b3,"✓","✗"), ifelse(b4,"✓","✗")))
cat("\n⚠ This prices ONE variant. Correcting the TARGET to its like-for-like value at\n")
cat("  h_ml is a DIFFERENT, more aggressive remedy: NOT priced, NOT proposed.\n")
