#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_basins.R -- OBJECTIVE #17's TWO BASINS, decomposed: what carries basin A's logpost lead over basin B?
# (CHANGELOG 2026-10-07 a.) Stage 2 converged into two basins, A (8 cold starts; promoted id 10) and B (8 starts, the
# incumbent seed among them), A ahead by 0.409 in the stored logpost. The stored logpost is the density of the
# UNCONSTRAINED vector u: likelihood + prior + the log-Jacobian of each name's transform. The project compares fits on
# LIKELIHOOD, never on stored logposts; this splits the lead into those three parts, per name and per row, each vector
# scored in #17's OWN space (its file's base, structure and pins; diag_obj17_refit_read.R's score_on() and ledger(),
# verbatim). Also printed: the natural-space density (likelihood + prior, no Jacobian), which a re-parametrization
# leaves unchanged.
# GATE: each vector reproduces its stored logpost (tol 1e-5, recompute_hessian.R's GATE 1), and the three parts sum to
# the logpost difference exactly.
# Usage: Rscript calibration/diag_obj17_basins.R
# OUTPUTS: outputs/diagnostics/obj17_basins_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
OB_DRIVER <- "calibration/diag_obj17_basins.R"
OB_FILES  <- c(A = file.path("calibration", "output", "refit_20261007_obj17_hilda_csl3v0kaidgbemw", "mode_fit_pumpN.rds"),
               B = file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds"))
OB_REPRO_TOL <- 1e-5          # recompute_hessian.R's GATE 1, promote's GATE 4
OB_TOP_NAMES <- 10L; OB_TOP_ROWS <- 12L
OB_OUT <- file.path("outputs", "diagnostics", sprintf("obj17_basins_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(OB_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n", OB_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
for (k in names(OB_FILES)) cat(sprintf("  basin %s  %s (md5 %s)\n", k, OB_FILES[[k]], unname(tools::md5sum(OB_FILES[[k]]))))
OBS <- ccx_prepare_obs()

# one file in its OWN space: its base, structure and pins; the per-name prior and log-Jacobian at its u
own <- function(F) { md <- readRDS(F); lab <- ccx_mode_struct(md); pins <- ccx_mode_pins(md)
  g <- ccx_apply_gate(lab); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_mode_base(md); for (n in names(pins)) bp[[n]] <- pins[[n]]; bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)), obs = OBS)
  u <- ccx_par_to_unc(ccx_mode_par_with_pins(md)); v <- lp(u)
  par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  L <- t(vapply(names(u), function(n) { s <- CCX_PARAM_TABLE[[n]] %||% CCX_PARAM_GATED_ALL[[n]]
    c(value = par[[n]], prior = .ccx_prior_eval(s, par[[n]], p_pr), jac = .log_jac(u[[n]], s)) }, numeric(3)))
  list(struct = lab, lp = as.numeric(v), lik = attr(v, "loglik"), st = unlist(attr(v, "streams")), L = L,
       stored = md$logpost, hml_bound = md$hml_bound) }
A <- own(OB_FILES[["A"]]); B <- own(OB_FILES[["B"]])

cat("\n=== 0. GATES ===\n")
for (k in c("A", "B")) { x <- get(k)
  cat(sprintf("  basin %s (%s): logpost %.6f, stored %.6f, diff %+.1e (tol %g); h_ml band [%g, %g]\n", k, x$struct, x$lp, x$stored,
              x$lp - x$stored, OB_REPRO_TOL, x$hml_bound[1], x$hml_bound[2]))
  if (!(abs(x$lp - x$stored) <= OB_REPRO_TOL)) stop("basin ", k, " does not reproduce its stored logpost") }
stopifnot(identical(A$struct, B$struct), identical(rownames(A$L), rownames(B$L)), identical(A$hml_bound, B$hml_bound),
          setequal(names(A$st), names(B$st)))
D_LIK <- A$lik - B$lik; D_PRI <- sum(A$L[, "prior"] - B$L[, "prior"]); D_JAC <- sum(A$L[, "jac"] - B$L[, "jac"])
GAP <- (A$lp - B$lp) - (D_LIK + D_PRI + D_JAC)
cat(sprintf("  the three parts close the logpost difference to %.1e\n", GAP))
if (abs(GAP) > 1e-8) stop("likelihood + prior + Jacobian does not sum to the logpost difference")

cat("\n=== 1. A - B ===\n")
cat(sprintf("  stored logpost        %+.4f\n  likelihood            %+.4f\n  priors                %+.4f\n  log-Jacobians         %+.4f\n",
            A$lp - B$lp, D_LIK, D_PRI, D_JAC))
cat(sprintf("  likelihood + prior (the natural-space density, no Jacobian)  %+.4f\n", D_LIK + D_PRI))

cat(sprintf("\n=== 2. PER NAME, A - B (the %d largest |prior + Jacobian|) ===\n", OB_TOP_NAMES))
DN <- data.frame(name = rownames(A$L), A = A$L[, "value"], B = B$L[, "value"], dprior = A$L[, "prior"] - B$L[, "prior"],
                 djac = A$L[, "jac"] - B$L[, "jac"], row.names = NULL)
DN <- DN[order(-abs(DN$dprior + DN$djac)), ]
for (i in seq_len(min(OB_TOP_NAMES, nrow(DN)))) cat(sprintf("  %-20s A %12.5g  B %12.5g   prior %+8.4f  Jacobian %+8.4f\n",
                                                         DN$name[i], DN$A[i], DN$B[i], DN$dprior[i], DN$djac[i]))

cat(sprintf("\n=== 3. PER ROW, likelihood A - B (the %d largest) ===\n", OB_TOP_ROWS))
DS <- A$st - B$st[names(A$st)]; DS <- DS[order(-abs(DS))]
for (i in seq_len(min(OB_TOP_ROWS, length(DS)))) cat(sprintf("  %-22s %+8.4f\n", names(DS)[i], DS[[i]]))
cat(sprintf("  rows favouring B %+.4f; rows favouring A %+.4f (%d rows)\n", sum(DS[DS < 0]), sum(DS[DS > 0]), length(DS)))
saveRDS(list(d_logpost = A$lp - B$lp, d_lik = D_LIK, d_prior = D_PRI, d_jac = D_JAC, names = DN, rows = DS,
             provenance = list(driver = OB_DRIVER, commit = COMMIT, files = OB_FILES,
                               md5 = vapply(OB_FILES, function(f) unname(tools::md5sum(f)), ""),
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none")), paste0(OB_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", OB_OUT))
sink()
