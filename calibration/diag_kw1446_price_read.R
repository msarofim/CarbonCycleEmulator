#!/usr/bin/env Rscript
# =====================================================================
# diag_kw1446_price_read.R -- READING THE k_w = 1446 PRICE ARM (2026-10-05; handoff
# notes/handoff_2026-10-04c_strat_feedback_kw_running.md §3 step 4, on the model of diag_obj15_refit_read.R).
#
# THE ARM (CHANGELOG 10-04 g; Marcus: "Canonical incumbent, Mac"): the canonical's objective and label
# (hilda_csl3v0kaidgbe, objective #15) with its 9 pins PLUS k_w held at Naegler 2009's 1446 m/yr
# (KW_PRIOR_CENTRE), 33 free, 24 dispersed starts; promoted (GATES 1-5) and its Hessian recomputed. It is the
# PROFILE price of the literature value: every other name re-optimized at fixed k_w.
#
# WHAT IT READS:
#   0. each vector reproduces its stored logpost: the canonical (hilda34g), the arm's promoted mode (basin 1),
#      and the arm's SECOND basin's best start (scored inside the arm's own objective).
#   1. THE PRICE ON LIKELIHOOD, row by row (⛔ never on stored logposts: a pinned arm's carries no prior or
#      Jacobian for the held name).
#   2. THE PRIOR LEDGER: each name's prior log-density and log-Jacobian at each vector, and k_w's own prior
#      at the canonical's value vs 1446 -- so the logpost difference splits into likelihood, the other names'
#      priors, and k_w's term.
#   3. WHAT ABSORBS k_w: every name's move from the canonical, in the canonical's MARGINAL Laplace sd, ranked;
#      and the second basin against the first.
#   4. Beside the earlier estimates of the same price: the CONDITIONAL profile (every other name held) and the
#      LAPLACE marginal (0.5 z^2), both from diag_obj15_refit_read.R (CHANGELOG 10-03 b, memory
#      ccx_kw_hemispheric_balance).
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_kw1446_price_read.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
KR_DRIVER   <- "calibration/diag_kw1446_price_read.R"
KR_CANON    <- "hilda34g"
KR_LABEL    <- "hilda_csl3v0kaidgbe"
KR_KW       <- "k_w"
KR_KW_PIN   <- 1446                                         # Naegler 2009, KW_PRIOR_CENTRE
KR_WAVE     <- file.path("calibration", "output", paste0("multistart_20261004f_", KR_LABEL, "_seasml1_pin_ent_seas_amp_SH=0_w_eq=27",
                         "_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_k_w=1446",
                         "_sd1.0452_sdby_npp_tsens=0.0291"))
KR_MODE     <- file.path("calibration", "output", "refit_20261005_kw1446_hilda_csl3v0kaidgbe", "mode_fit_pumpN.rds")
KR_BASIN_GAP <- 0.05                                        # logpost: starts within this of the best are basin 1 (the collector found 0.224)
KR_REPRO_TOL <- 1e-5                                        # recompute_hessian.R's GATE 1 tolerance
KR_PRICE_COND    <- 1783                                    # CHANGELOG 10-03 (b) §5(b): conditional profile to 1446, others held
KR_PRICE_LAPLACE <- 47                                      # same, §5(c): 0.5 z^2 on the marginal sd (9.7 sds)
KR_TOP <- 12L
KR_OUT <- file.path("outputs", "diagnostics", sprintf("kw1446_price_read_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(KR_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  canonical %s (%s)\n  price arm %s\n  survey    %s\n", KR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            KR_CANON, ccx_mode_file(KR_CANON), KR_MODE, KR_WAVE))

OBS <- ccx_prepare_obs()
# one arm's own space (diag_obj15_refit_read.R's in_arm): its pins, base, spinup and objective
in_arm <- function(md, f) {
  r <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit(ccx_unpin_params(r), add = TRUE)
  stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  lp  <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spf, obs = OBS)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "kw1446 read")))
  stopifnot(length(st$absent) == 0L, st$logpost_shift == 0)
  f(lp, st$u, bp)
}
ev <- function(lp, u) { v <- lp(u); s <- unlist(attr(v, "streams")); list(logpost = as.numeric(v), streams = s, lik = sum(s)) }
# each free name's prior log-density and log-Jacobian at u (the objective's own two terms, R/calibrate.R)
ledger <- function(u, bp) { par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  t(vapply(names(u), function(n) { s <- CCX_PARAM_TABLE[[n]]
    c(value = par[[n]], prior = .ccx_prior_eval(s, par[[n]], p_pr), jac = .log_jac(u[[n]], s),
      z = tryCatch(ccx_prior_z(n, par[[n]], p = p_pr), error = function(e) NA_real_)) }, numeric(4))) }

MD_C <- readRDS(ccx_mode_file(KR_CANON)); MD_P <- readRDS(KR_MODE)
stopifnot(identical(ccx_mode_struct(MD_C), KR_LABEL), identical(ccx_mode_struct(MD_P), KR_LABEL),
          isTRUE(all.equal(unname(ccx_mode_pins(MD_P)[KR_KW]), KR_KW_PIN)), !(KR_KW %in% names(ccx_mode_pins(MD_C))))

# ---- 0. reproduction ----------------------------------------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST (tol %g) ===\n", KR_REPRO_TOL))
starts <- lapply(sort(list.files(KR_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)), readRDS)
conv   <- Filter(function(s) isTRUE(s$converged), starts)
lps    <- vapply(conv, `[[`, 0, "logpost"); best <- max(lps)
b2     <- conv[lps < best - KR_BASIN_GAP]; b2 <- b2[[which.max(vapply(b2, `[[`, 0, "logpost"))]]
cat(sprintf("  survey: %d converged of %d; basin 1 = %d starts within %.2f of %.6f; basin 2's best = id %03d at %.6f\n",
            length(conv), length(starts), sum(lps >= best - KR_BASIN_GAP), KR_BASIN_GAP, best, b2$id, b2$logpost))
EC <- in_arm(MD_C, function(lp, u, bp) c(ev(lp, u), list(u = u, led = ledger(u, bp),
        kw_prior = { s <- CCX_PARAM_TABLE[[KR_KW]]; p <- ccx_unc_to_par(u)
          c(at_mode = .ccx_prior_eval(s, p[[KR_KW]], bp), at_pin = .ccx_prior_eval(s, KR_KW_PIN, bp),
            jac_at_mode = .log_jac(u[[KR_KW]], s), jac_at_pin = .log_jac(ccx_par_to_unc(modifyList(p, setNames(list(KR_KW_PIN), KR_KW)))[[KR_KW]], s),
            u_at_mode = u[[KR_KW]], u_at_pin = ccx_par_to_unc(modifyList(p, setNames(list(KR_KW_PIN), KR_KW)))[[KR_KW]]) })))
EP <- in_arm(MD_P, function(lp, u, bp) {
  e1 <- ev(lp, u); stopifnot(identical(names(b2$u_mode), names(u)))
  e2 <- ev(lp, b2$u_mode)
  list(b1 = c(e1, list(u = u, led = ledger(u, bp))), b2 = c(e2, list(u = b2$u_mode, led = ledger(b2$u_mode, bp)))) })
for (r in list(list("canonical", EC, MD_C$logpost), list("price arm, basin 1", EP$b1, MD_P$logpost), list(sprintf("price arm, basin 2 (id %03d)", b2$id), EP$b2, b2$logpost))) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-28s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows  prior+Jacobian %.4f\n",
              r[[1]], r[[2]]$logpost, r[[3]], d, r[[2]]$lik, length(r[[2]]$streams), r[[2]]$logpost - r[[2]]$lik))
  if (!(abs(d) <= KR_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}
rows <- names(EC$streams); stopifnot(setequal(rows, names(EP$b1$streams)), setequal(rows, names(EP$b2$streams)))

# ---- 1. the price on likelihood ----------------------------------------------------------------------
cat(sprintf("\n=== 1. THE PRICE OF k_w = %g ON LIKELIHOOD (the same %d rows; > 0 = the price arm fits BETTER) ===\n", KR_KW_PIN, length(rows)))
ST <- data.frame(row = rows, canonical = EC$streams[rows], basin1 = EP$b1$streams[rows], basin2 = EP$b2$streams[rows], row.names = NULL)
ST$d1 <- ST$basin1 - ST$canonical; ST$d2 <- ST$basin2 - ST$canonical
ST <- ST[order(-abs(ST$d1)), ]
for (i in seq_len(nrow(ST))) cat(sprintf("  %-22s canonical %10.3f | basin 1 %+8.3f | basin 2 %+8.3f\n", ST$row[i], ST$canonical[i], ST$d1[i], ST$d2[i]))
D_LIK <- c(basin1 = EP$b1$lik - EC$lik, basin2 = EP$b2$lik - EC$lik)
cat(sprintf("  TOTAL: basin 1 %+.4f, basin 2 %+.4f (canonical %.4f)\n", D_LIK[["basin1"]], D_LIK[["basin2"]], EC$lik))
grp <- function(pat) sum(ST$d1[grepl(pat, ST$row)])
FAM <- c(CO2 = "^co2", d13C = "^d13c", atm_d14C = "^d14c_(intcal|NH|SH)$", ocean_14C = "^excess_c14|^d14c_profile", GCB = "^gcb",
         ocean_grad_surface = "^ocean_grad|^hs_surf")
fam_hit <- vapply(FAM, function(pat) grepl(pat, ST$row), logical(nrow(ST)))
stopifnot(all(rowSums(fam_hit) == 1L))                      # every row in exactly one family
cat(sprintf("  basin 1 by family: %s\n", paste(sprintf("%s %+.3f", names(FAM), vapply(FAM, grp, 0)), collapse = " | ")))

# ---- 2. the prior ledger -----------------------------------------------------------------------------
cat("\n=== 2. THE PRIOR LEDGER (natural-scale prior log-density + log-Jacobian, the objective's own terms) ===\n")
common <- intersect(rownames(EC$led), rownames(EP$b1$led))
dP <- EP$b1$led[common, "prior"] - EC$led[common, "prior"]; dJ <- EP$b1$led[common, "jac"] - EC$led[common, "jac"]
o <- order(-abs(dP))
cat(sprintf("  %-18s %12s %12s %9s %9s %9s %9s\n", "name", "canonical", "basin 1", "z canon", "z b1", "d prior", "d jac"))
for (n in common[o][seq_len(min(KR_TOP, length(common)))])
  cat(sprintf("  %-18s %12.5g %12.5g %9.2f %9.2f %+9.3f %+9.3f\n", n, EC$led[n, "value"], EP$b1$led[n, "value"], EC$led[n, "z"],
              EP$b1$led[n, "z"], dP[[n]], dJ[[n]]))
KW_TERM <- EC$kw_prior
cat(sprintf("  k_w's own term at the canonical: prior %.4f at %.1f vs %.4f at %g (difference %+.4f); Jacobian %.4f vs %.4f\n",
            KW_TERM[["at_mode"]], EC$led[KR_KW, "value"], KW_TERM[["at_pin"]], KR_KW_PIN, KW_TERM[["at_mode"]] - KW_TERM[["at_pin"]],
            KW_TERM[["jac_at_mode"]], KW_TERM[["jac_at_pin"]]))
SPLIT <- c(d_logpost_stored = MD_P$logpost - MD_C$logpost, d_likelihood = D_LIK[["basin1"]], d_other_priors = sum(dP), d_other_jac = sum(dJ),
           kw_term_at_canonical = EC$led[KR_KW, "prior"] + EC$led[KR_KW, "jac"])
cat(sprintf("  logpost difference %+.4f = likelihood %+.4f + the other names' priors %+.4f + their Jacobians %+.4f - k_w's own term at the canonical (%.4f)  [check %+.1e]\n",
            SPLIT[["d_logpost_stored"]], SPLIT[["d_likelihood"]], SPLIT[["d_other_priors"]], SPLIT[["d_other_jac"]], SPLIT[["kw_term_at_canonical"]],
            SPLIT[["d_logpost_stored"]] - (SPLIT[["d_likelihood"]] + SPLIT[["d_other_priors"]] + SPLIT[["d_other_jac"]] - SPLIT[["kw_term_at_canonical"]])))
POST_PRICE <- SPLIT[["d_likelihood"]] + SPLIT[["d_other_priors"]] + (KW_TERM[["at_pin"]] - KW_TERM[["at_mode"]])
cat(sprintf("  ⇒ on the NATURAL scale (no Jacobians): likelihood %+.4f, the other names' priors %+.4f, k_w's prior %+.4f => the posterior price of %g is %+.4f\n",
            SPLIT[["d_likelihood"]], SPLIT[["d_other_priors"]], KW_TERM[["at_pin"]] - KW_TERM[["at_mode"]], KR_KW_PIN, POST_PRICE))

# ---- 3. what absorbs k_w -----------------------------------------------------------------------------
cat("\n=== 3. WHAT ABSORBS k_w: each name's move from the canonical, in the canonical's MARGINAL Laplace sd (u-space) ===\n")
fs <- ccx_mode_fit_stats(MD_C); sdC <- stats::setNames(as.numeric(fs$sd), fs$param_names)
mv <- function(Eb) { du <- Eb$u[common] - EC$u[common]; z <- du / sdC[common]; z[order(-abs(z))] }
Z1 <- mv(EP$b1); Z2 <- mv(EP$b2)
cat(sprintf("  k_w itself: %.1f -> %g = %+.2f marginal sd\n", EC$led[KR_KW, "value"], KR_KW_PIN,
            (EC$kw_prior[["u_at_pin"]] - EC$kw_prior[["u_at_mode"]]) / sdC[[KR_KW]]))
for (n in names(Z1)[seq_len(KR_TOP)]) cat(sprintf("  %-18s %12.5g -> %12.5g  %+6.2f sd   (basin 2 %12.5g, %+6.2f sd)\n", n, EC$led[n, "value"],
                                                  EP$b1$led[n, "value"], Z1[[n]], EP$b2$led[n, "value"], Z2[[n]]))
B12 <- (EP$b2$u[common] - EP$b1$u[common]) / sdC[common]; B12 <- B12[order(-abs(B12))]
cat(sprintf("  basin 2 vs basin 1 (the two are %.4f apart on logpost, %.4f on likelihood): %s\n", EP$b2$logpost - EP$b1$logpost, EP$b2$lik - EP$b1$lik,
            paste(sprintf("%s %+.2f sd", names(B12)[1:6], B12[1:6]), collapse = ", ")))

# ---- 4. beside the earlier estimates ------------------------------------------------------------------
cat(sprintf("\n=== 4. THE SAME PRICE, THREE WAYS (log-units; < 0 = 1446 costs) ===\n  conditional profile, every other name held (10-03 b)  %+.0f\n  Laplace marginal, 0.5 z^2 (10-03 b)                    %+.0f\n  PROFILE (this arm), likelihood                         %+.4f\n  PROFILE, posterior on the natural scale                %+.4f\n",
            -KR_PRICE_COND, -KR_PRICE_LAPLACE, D_LIK[["basin1"]], POST_PRICE))

sink()
saveRDS(list(streams = ST, d_lik = D_LIK, ledger_canonical = EC$led, ledger_basin1 = EP$b1$led, ledger_basin2 = EP$b2$led, kw_term = KW_TERM,
             split = SPLIT, posterior_price = POST_PRICE, moves_basin1 = Z1, moves_basin2 = Z2, basin2_vs_1 = B12, basin2_id = b2$id,
             provenance = sprintf("%s @%s; canonical %s (%s); price arm %s; survey %s; no RNG; %s", KR_DRIVER, COMMIT, KR_CANON,
                                  ccx_mode_file(KR_CANON), KR_MODE, KR_WAVE, format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(KR_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", KR_OUT))
