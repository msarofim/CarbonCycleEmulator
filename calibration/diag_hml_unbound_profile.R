# =====================================================================
# diag_hml_unbound_profile.R -- IS THE [85,120] h_ml BOUND LOAD-BEARING?
#
# PRE-REGISTERED: notes/prereg_2026-08-28_hml_unbound_profile.md, committed
# (805e8c4) BEFORE this file existed. Gates copied unchanged.
#
# 08-16g measured the objective's argmax over h_ml at 32 m with a 236 log-unit
# pull against a 10.0 cliff -- WITH 19 PARAMETERS FROZEN. The refit then landed
# h_ml at 96.47 (z -0.28), 11.47 m clear of the lower edge rather than pinned to
# it -- BUT THE BOUND WAS IN FORCE, so it could not have gone below 85 anyway.
# This profile removes the bound and frees the uptake set. [[ccx_hml_band_discont]]
#
# ⚠ NOTHING HERE CHANGES AN OBJECTIVE. No constant, prior, R/ or src/ is touched
# and no refit is owed by anything it prints.
# ⚠ THESE LOGPOSTS USE THE UN-NARROWED h_ml PRIOR and are NOT comparable with the
# bounded runs' (the +1.5805 constant is absent). Everything is within-profile.
#
# Usage:  Rscript calibration/diag_hml_unbound_profile.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

HU_YEARS <- c(1750, 2024)
HU_FREE  <- c("beta_max", "fert_k", "k_w", "kz", "pump_grad")   # prereg sec.2
HU_PROF  <- "h_ml"
HU_BAND  <- LIK_OCEAN_GRAD_HML_OK           # [85, 120], read not typed
HU_GRID  <- c(32, 38, 45, 55, 65, 75, 82, 84.90, 84.99,
              85.01, 85.10, 88, 92, 96.4737, 104, 112, 118, 119.9, 119.99,
              120.01, 120.1, 126, 140, 160, 185, 198)
HU_MAXIT <- 1200; HU_RESTARTS <- 4; HU_RESTOL <- 0.02
# ---- PRE-REGISTERED GATES, prereg sec.3.
HU_H1_JUMP   <- 5.0     # log-units, minimum cliff at 85
HU_H3_RAIL   <- 0.90    # kz fraction up its bracket that counts as "railed"
HU_H4_PUMP   <- 900     # pump_grad above this = unconstrained, 08-16g's 963.6/1431.0
HU_GRAD_ROWS <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(ccx_mode_file())
pm <- ccx_mode_params(md)                   # ⚠ NOT ccx_unc_to_par(md$u_mode)
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
i_h <- match(HU_PROF, CCX_PARAM_NAMES)
idx <- match(HU_FREE, CCX_PARAM_NAMES); stopifnot(!anyNA(idx), !(i_h %in% idx))
tb <- CCX_PARAM_TABLE$h_ml                  # the SHIPPED band, deliberately
stopifnot(tb$lo == 30, tb$hi == 200, tb$tr == "logit")
to_u <- function(h) log((h - tb$lo) / (tb$hi - h))
u0[i_h] <- to_u(pm$h_ml)                    # re-encode under the SHIPPED band
stopifnot(abs(ccx_unc_to_par(u0)$h_ml - pm$h_ml) < 1e-9)   # round-trips

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(years = HU_YEARS, base_params = bp)
cat(sprintf("mode %s | h_ml at the mode %.4f m (par_mode)\n", basename(ccx_mode_file()), pm$h_ml))
cat(sprintf("profiling %s over the SHIPPED band [%g, %g]; refit band was [%g, %g]\n",
            HU_PROF, tb$lo, tb$hi, md$hml_bound[1], md$hml_bound[2]))
cat(sprintf("free (%d): %s\n", length(HU_FREE), paste(HU_FREE, collapse = ", ")))
cat(sprintf("ocean-gradient rows LIVE only for h_ml in [%g, %g]\n", HU_BAND[1], HU_BAND[2]))
cat(sprintf("⚠ un-narrowed h_ml prior: these logposts are NOT comparable with bounded runs.\n"))

obs <- ccx_prepare_obs()
rows_at <- function(pv) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", HU_YEARS, prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / CCX_BOMB_REF)
  for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  unlist(ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                 grad_off_co2 = pv$grad_off_co2,
                                 grad_off_d13c = pv$grad_off_d13c),
                    luc = ccx_forcing_eluc_annual(F), deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
}
fit_at <- function(v0, ua) {
  objf <- function(v) { u <- ua; u[idx] <- v; -lp(u) }
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = HU_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n <- 0; gain <- Inf
  repeat {
    bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 150, reltol = 1e-12)),
              silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = HU_MAXIT, reltol = 1e-12))
    gain <- best - ft$value
    if (ft$value < best) { v <- ft$par; best <- ft$value }
    n <- n + 1
    if (gain < HU_RESTOL || n >= HU_RESTARTS) break
  }
  list(par = v, value = best, restarts = n, gain = gain, converged = gain < HU_RESTOL)
}

sep("THE PROFILE -- h_ml fixed, the uptake set re-optimised at every point")
kzb <- md$kz_bracket
cat(sprintf("  %9s %5s | %11s | %9s %6s | %9s %9s %9s | %2s %8s\n", "h_ml", "rows",
            "cond dlp", "kz", "%brkt", "pump_grad", "beta_max", "fert_k", "re", "gain"))
# ⚠ WALK OUTWARD FROM THE MODE, not left-to-right. Each point is warm-started
# from its NEIGHBOUR, so the optimiser never has to cross the whole parameter
# range in one step. The first attempt started at h_ml = 32 -- the far end -- and
# its warm start was the mode's uptake vector, 64 m away.
HU_ANCHOR <- HU_GRID[which.min(abs(HU_GRID - pm$h_ml))]
HU_DOWN <- rev(sort(HU_GRID[HU_GRID <= HU_ANCHOR]))     # anchor first, then down
HU_UP   <- sort(HU_GRID[HU_GRID > HU_ANCHOR])
res <- list(); ref <- NA
run_leg <- function(hs, v_start) {
  v_warm <- v_start
  for (h in hs) {
    ua <- u0; ua[i_h] <- to_u(h)
    t0 <- Sys.time()
    ft <- try(fit_at(v_warm, ua), silent = TRUE)
    if (inherits(ft, "try-error")) {                  # one bad point must not kill the run
      cat(sprintf("  %9.4f  ⚠ FIT FAILED: %s\n", h, sub("\n.*", "", as.character(ft))))
      flush.console(); next
    }
    v_warm <- ft$par
    uh <- ua; uh[idx] <- ft$par; pv <- ccx_unc_to_par(uh)
    stopifnot(abs(pv$h_ml - h) < 1e-8)
    if (is.na(ref)) ref <<- -ft$value
    live <- h >= HU_BAND[1] && h <= HU_BAND[2]
    res[[sprintf("%.4f", h)]] <<- list(h = h, lp = -ft$value, pv = pv, live = live,
                                       u_free = ft$par, converged = ft$converged)
    cat(sprintf("  %9.4f %5s | %+11.2f | %9.1f %5.1f%% | %9.1f %9.4f %9.2f | %2d %8.4f%s  [%.0fs]\n",
                h, if (live) "LIVE" else "off", -ft$value - ref, pv$kz,
                100*(pv$kz - kzb[1])/diff(kzb), pv$pump_grad, pv$beta_max, pv$fert_k,
                ft$restarts, ft$gain, if (!ft$converged) " ⚠MOVING" else "",
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    flush.console()                                   # buffered rows were LOST to a kill
  }
  v_warm
}
invisible(run_leg(HU_DOWN, u0[idx]))
# the up-leg restarts from the ANCHOR's fit, not from the bottom of the down-leg
invisible(run_leg(HU_UP, res[[sprintf("%.4f", HU_ANCHOR)]]$u_free))
res <- res[order(vapply(res, function(x) x$h, 0))]

sep("THE PRE-REGISTERED GATES")
L <- vapply(res, function(x) x$lp, 0); H <- vapply(res, function(x) x$h, 0)
lo_out <- res[["84.9900"]]$lp; lo_in <- res[["85.0100"]]$lp
hi_in  <- res[["119.9900"]]$lp; hi_out <- res[["120.0100"]]$lp
cat(sprintf("  H1  cliff at  85: %+8.3f  (84.99 -> 85.01)   gate |jump| >= %.1f  -> %s\n",
            lo_in - lo_out, HU_H1_JUMP, if (abs(lo_in - lo_out) >= HU_H1_JUMP) "PASS" else "FAIL"))
cat(sprintf("  H1  cliff at 120: %+8.3f  (119.99 -> 120.01)\n", hi_out - hi_in))
am <- which.max(L); hmax <- H[am]
inb <- hmax >= HU_BAND[1] && hmax <= HU_BAND[2]
cat(sprintf("\n  H2  conditional ARGMAX over h_ml = %.4f m  (%+.2f above the mode's %.2f)\n",
            hmax, L[[am]] - res[[sprintf("%.4f", 96.4737)]]$lp, 96.4737))
cat(sprintf("      gate: INSIDE [%g, %g] -> %s\n", HU_BAND[1], HU_BAND[2],
            if (inb) "PASS -- the bound is NOT load-bearing" else
              "FAIL -- THE BOUND IS LOAD-BEARING; option 5 becomes NECESSARY"))
kz_below <- vapply(res[H < HU_BAND[1]], function(x) (x$pv$kz - kzb[1])/diff(kzb), 0)
cat(sprintf("\n  H3  kz fraction up its bracket, h_ml BELOW the band: %.3f - %.3f\n",
            min(kz_below), max(kz_below)))
cat(sprintf("      gate: comes off the rail (< %.2f somewhere) -> %s\n", HU_H3_RAIL,
            if (min(kz_below) < HU_H3_RAIL) "PASS" else "FAIL -- the rail is INDEPENDENT of h_ml"))
pg_off <- vapply(res[!vapply(res, function(x) x$live, TRUE)], function(x) x$pv$pump_grad, 0)
cat(sprintf("\n  H4  pump_grad where the rows are OFF: %.1f - %.1f (gate: > %g somewhere) -> %s\n",
            min(pg_off), max(pg_off), HU_H4_PUMP,
            if (max(pg_off) > HU_H4_PUMP) "PASS" else "FAIL -- something else identifies it"))
pg_on <- vapply(res[vapply(res, function(x) x$live, TRUE)], function(x) x$pv$pump_grad, 0)
cat(sprintf("      pump_grad where the rows are LIVE: %.1f - %.1f\n", min(pg_on), max(pg_on)))

# ⚠ WRITE THE ARTIFACT BEFORE THE PRETTY-PRINTING. The first complete run of this
# driver lost 45 minutes of fits because the section below errored and saveRDS came
# after it. A reporting bug must not be able to destroy a run's output.
OUT <- ccx_path("outputs", "diagnostics"); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(grid = HU_GRID, free = HU_FREE, band = HU_BAND, res = res,
             argmax = hmax, in_band = inb, kz_bracket = kzb),
        file.path(OUT, "hml_unbound_profile.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUT, "hml_unbound_profile.rds")))

sep("THE THREE OCEAN-GRADIENT ROWS, across the edge")
for (k in c("84.9900", "85.0100", "96.4737", "119.9900", "120.0100")) {
  s <- rows_at(res[[k]]$pv)
  # ⚠ the rows are ABSENT from ccx_loglik's output when skipped -- not zero, ABSENT.
  # That absence IS defect (B): a skipped Gaussian pays 0 where a live one pays
  # negative, so leaving the band is a free gain. Print it as "skipped", not 0.
  vals <- vapply(HU_GRAD_ROWS, function(n) if (is.null(s[[n]])) NA_real_ else s[[n]], 0)
  cat(sprintf("  h_ml %9s (%4s): %s   sum %s\n", k, if (res[[k]]$live) "LIVE" else "off",
              paste(sprintf("%s %s", sub("ocean_grad_", "", HU_GRAD_ROWS),
                            ifelse(is.na(vals), " skipped", sprintf("%+8.3f", vals))),
                    collapse = "  "),
              if (all(is.na(vals))) "0 (FREE)" else sprintf("%+.3f", sum(vals, na.rm = TRUE))))
}

sep("SCORED")
cat(sprintf("  H1 %s | H2 %s | H3 %s | H4 %s\n",
            if (abs(lo_in-lo_out) >= HU_H1_JUMP) "PASS" else "FAIL",
            if (inb) "PASS" else "FAIL", if (min(kz_below) < HU_H3_RAIL) "PASS" else "FAIL",
            if (max(pg_off) > HU_H4_PUMP) "PASS" else "FAIL"))
cat(sprintf("\n  ⇒ %s\n", if (inb)
  paste0("THE BOUND IS NOT LOAD-BEARING. With the uptake set free the objective's own\n",
         "    argmax is INSIDE the band, so the bound is holding h_ml where the data already\n",
         "    wants it. 5 free is conservative and one-way, so this generalises to 20.\n",
         "    ⚠ That makes the bound HARMLESS AT THE MODE -- it does NOT make it RIGHT.") else
  paste0("THE BOUND IS LOAD-BEARING -- it holds h_ml somewhere the data does not want it.\n",
         "    A hard bound is then doing the fit's work, and option 5 is NECESSARY.")))
cat("\n  ⚠ This prices neither option. 08-16g's 21 % sigma-inflation recovery is\n")
cat("    OBSERVATION-SIDE ONLY and still needs the model's gradient. Open either way.\n")

cat("\n\n=== DONE ===\n")
