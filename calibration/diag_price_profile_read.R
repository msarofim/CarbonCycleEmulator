#!/usr/bin/env Rscript
# =====================================================================
# diag_price_profile_read.R -- READING A PRICE PROFILE (calibration/run_price_profile.R) at the canonical: the price
# of holding one fitted name at a value, on LIKELIHOOD row by row, and the PRIOR LEDGER that splits the logpost
# difference exactly. 2026-10-13, for card 7's k_w sentence (Marcus: "Yes, copy the results and compute the prior
# ledger").
#
# THE SAME ARITHMETIC AS calibration/diag_kw1446_price_read.R (10-05 a), which stays as written for its record: each
# free name's prior log-density and log-Jacobian (the objective's own two terms) at each point; the held name's own
# term at the canonical; the split
#   logpost(profile) - logpost(canonical) = d likelihood + d other priors + d other Jacobians - (held name's prior +
#                                           Jacobian at the canonical)                [a pinned name carries neither]
# and the posterior price on the NATURAL scale (no Jacobians): d likelihood + d other priors + (held prior at the
# held value - at the canonical's value). ⛔ Stored logposts of the two objectives are never compared directly.
# What differs from 10-05: the profile is two STARTS of one held objective (A, B), not a promoted wave; their
# agreement is the convergence check, read in section 3.
#
# Usage: Rscript calibration/diag_price_profile_read.R [--dir=outputs/diagnostics/price_profile_20261013_hilda31w]
#        [--hold=k_w] [--ref=outputs/diagnostics/kw1446_price_read_20261005.rds]
# ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
PR_ARGS <- commandArgs(trailingOnly = TRUE)
pr_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), PR_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
PR_DRIVER <- "calibration/diag_price_profile_read.R"
PR_DIR    <- pr_arg("dir", file.path("outputs", "diagnostics", "price_profile_20261013_hilda31w"))
PR_HOLD   <- pr_arg("hold", "k_w")
PR_REF    <- pr_arg("ref", file.path("outputs", "diagnostics", "kw1446_price_read_20261005.rds"))  # the 10-05 read, beside
PR_TOP    <- 12L
PR_AGREE_SD <- 0.1   # descriptive: the two starts' largest u-space separation is reported against this, in marginal sds
PR_OUT    <- file.path(PR_DIR, sprintf("read_%s_%s", PR_HOLD, format(Sys.Date(), "%Y%m%d")))
COMMIT    <- ccx_git_stamp()
FS <- sort(list.files(PR_DIR, pattern = sprintf("^profile_%s_[A-Za-z0-9]+[.]rds$", PR_HOLD), full.names = TRUE))
if (length(FS) < 1L) stop("no profile_", PR_HOLD, "_<tag>.rds in ", PR_DIR)
PF <- lapply(FS, readRDS); names(PF) <- sub(sprintf("^profile_%s_(.*)[.]rds$", PR_HOLD), "\\1", basename(FS))
HOLD <- PF[[1]]$provenance$hold
stopifnot(identical(names(HOLD), PR_HOLD), all(vapply(PF, function(p) identical(p$provenance$hold, HOLD) &&
            identical(p$provenance$mode, CCX_MODE_CANONICAL) && identical(p$provenance$mode_md5, unname(tools::md5sum(ccx_mode_file()))), TRUE)))
sink(paste0(PR_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  canonical %s (md5 %s)\n  profile %s = %g: starts %s, from %s\n", PR_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            CCX_MODE_CANONICAL, PF[[1]]$provenance$mode_md5, PR_HOLD, HOLD, paste(names(PF), collapse = ", "), PR_DIR))
for (k in names(PF)) cat(sprintf("    %s: start %s; converged %s; %.1f CPU-min; driver @%s\n", k, PF[[k]]$provenance$start, PF[[k]]$converged,
                                 PF[[k]]$provenance$cpu_min, PF[[k]]$provenance$commit))

# ---- the two objectives: the canonical's, and the same with the held name pinned --------------
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
PINS0 <- ccx_mode_pins(md)
SPF <- ccx_spinup_from_label(ccx_mode_spinup(md))
bp0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp0$pump_mode <- md$pump_mode
spec <- function(n) if (!is.null(CCX_PARAM_TABLE[[n]])) CCX_PARAM_TABLE[[n]] else CCX_PARAM_GATED_ALL[[n]]
ev <- function(lp, u) { v <- lp(u); s <- unlist(attr(v, "streams")); list(logpost = as.numeric(v), streams = s, lik = sum(s)) }
# each free name's prior log-density and log-Jacobian at u (the objective's own two terms; diag_kw1446_price_read.R's)
ledger <- function(u, bp) { par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  t(vapply(names(u), function(n) { s <- spec(n)
    c(value = par[[n]], prior = .ccx_prior_eval(s, par[[n]], p_pr), jac = .log_jac(u[[n]], s),
      z = tryCatch(ccx_prior_z(n, par[[n]], p = p_pr), error = function(e) NA_real_)) }, numeric(4))) }

r0 <- ccx_apply_pins(PINS0)
invisible(ccx_adopt_mode_band(md)); ccx_check_mode_decode(md)
lp_c <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = SPF)
u_c  <- unlist(ccx_par_to_unc(md$par_mode))[CCX_PARAM_NAMES]
EC <- c(ev(lp_c, u_c), list(u = u_c, led = ledger(u_c, bp0)))
s_h <- spec(PR_HOLD); p_c <- ccx_unc_to_par(u_c)
u_pin <- unlist(ccx_par_to_unc(modifyList(p_c, stats::setNames(list(HOLD[[1]]), PR_HOLD))))[[PR_HOLD]]
KW <- c(value_at_mode = p_c[[PR_HOLD]], prior_at_mode = .ccx_prior_eval(s_h, p_c[[PR_HOLD]], bp0),
        prior_at_pin = .ccx_prior_eval(s_h, HOLD[[1]], bp0), jac_at_mode = .log_jac(u_c[[PR_HOLD]], s_h),
        jac_at_pin = .log_jac(u_pin, s_h), u_at_mode = u_c[[PR_HOLD]], u_at_pin = u_pin)
fsC <- ccx_mode_fit_stats(md); sdC <- stats::setNames(sqrt(diag(fsC$cov)), md$param_names)
ccx_unpin_params(r0)

invisible(ccx_apply_pins(c(stats::setNames(as.numeric(PINS0), names(PINS0)), HOLD)))
bpH <- bp0; bpH[[PR_HOLD]] <- HOLD[[1]]
lp_h <- ccx_make_logpost(base_params = bpH, by_stream = TRUE, spinup_fn = SPF)
EP <- lapply(PF, function(p) { u <- p$result$u[CCX_PARAM_NAMES]; c(ev(lp_h, u), list(u = u, led = ledger(u, bpH))) })

# ---- 0. reproduction ----------------------------------------------------------------------------------
cat(sprintf("\n=== 0. EACH POINT REPRODUCES ITS STORED LOGPOST IN ITS OWN OBJECTIVE (tol %g = CCX_REPRO_TOL) ===\n", CCX_REPRO_TOL))
rep_rows <- c(list(list("canonical", EC, md$logpost)), lapply(names(PF), function(k) list(sprintf("profile %s", k), EP[[k]], PF[[k]]$result$logpost)))
for (r in rep_rows) {
  d <- r[[2]]$logpost - r[[3]]
  cat(sprintf("  %-12s logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows  prior+Jacobian %.4f\n",
              r[[1]], r[[2]]$logpost, r[[3]], d, r[[2]]$lik, length(r[[2]]$streams), r[[2]]$logpost - r[[2]]$lik))
  if (!(abs(d) <= CCX_REPRO_TOL)) stop(r[[1]], " does NOT reproduce its stored logpost")
}
rows <- names(EC$streams); stopifnot(all(vapply(EP, function(e) setequal(rows, names(e$streams)), TRUE)))
A <- names(PF)[1]

# ---- 1. the price on likelihood ----------------------------------------------------------------------
cat(sprintf("\n=== 1. THE PRICE OF %s = %g ON LIKELIHOOD (the same %d rows; > 0 = the held point fits BETTER) ===\n", PR_HOLD, HOLD, length(rows)))
ST <- data.frame(row = rows, canonical = EC$streams[rows], row.names = NULL)
for (k in names(PF)) ST[[paste0("d_", k)]] <- EP[[k]]$streams[rows] - ST$canonical
ST <- ST[order(-abs(ST[[paste0("d_", A)]])), ]
for (i in seq_len(nrow(ST))) cat(sprintf("  %-22s canonical %10.3f | %s\n", ST$row[i], ST$canonical[i],
                                         paste(sprintf("%s %+8.3f", names(PF), unlist(ST[i, paste0("d_", names(PF))])), collapse = " | ")))
D_LIK <- vapply(EP, function(e) e$lik - EC$lik, 0)
cat(sprintf("  TOTAL: %s (canonical %.4f)\n", paste(sprintf("%s %+.4f", names(D_LIK), D_LIK), collapse = ", "), EC$lik))
FAM <- c(CO2 = "^co2", d13C = "^d13c", atm_d14C = "^d14c_(intcal|NH|SH)$", ocean_14C = "^excess_c14|^d14c_profile", GCB = "^gcb",
         ocean_grad_surface = "^ocean_grad|^hs_surf")
fam_hit <- vapply(FAM, function(pat) grepl(pat, ST$row), logical(nrow(ST)))
stopifnot(all(rowSums(fam_hit) == 1L))                      # every row in exactly one family
FAMD <- vapply(FAM, function(pat) sum(ST[[paste0("d_", A)]][grepl(pat, ST$row)]), 0)
cat(sprintf("  %s by family: %s\n", A, paste(sprintf("%s %+.3f", names(FAMD), FAMD), collapse = " | ")))

# ---- 2. the prior ledger -----------------------------------------------------------------------------
cat(sprintf("\n=== 2. THE PRIOR LEDGER at %s (natural-scale prior log-density + log-Jacobian, the objective's own terms) ===\n", A))
common <- intersect(rownames(EC$led), rownames(EP[[A]]$led))
dP <- EP[[A]]$led[common, "prior"] - EC$led[common, "prior"]; dJ <- EP[[A]]$led[common, "jac"] - EC$led[common, "jac"]
o <- order(-abs(dP))
cat(sprintf("  %-20s %12s %12s %9s %9s %9s %9s\n", "name", "canonical", A, "z canon", paste("z", A), "d prior", "d jac"))
for (n in common[o][seq_len(min(PR_TOP, length(common)))])
  cat(sprintf("  %-20s %12.5g %12.5g %9.2f %9.2f %+9.3f %+9.3f\n", n, EC$led[n, "value"], EP[[A]]$led[n, "value"], EC$led[n, "z"],
              EP[[A]]$led[n, "z"], dP[[n]], dJ[[n]]))
cat(sprintf("  %s's own term at the canonical: prior %.4f at %.1f vs %.4f at %g (difference %+.4f); Jacobian %.4f vs %.4f\n", PR_HOLD,
            KW[["prior_at_mode"]], KW[["value_at_mode"]], KW[["prior_at_pin"]], HOLD, KW[["prior_at_mode"]] - KW[["prior_at_pin"]],
            KW[["jac_at_mode"]], KW[["jac_at_pin"]]))
SPLIT <- c(d_logpost = EP[[A]]$logpost - EC$logpost, d_likelihood = D_LIK[[A]], d_other_priors = sum(dP), d_other_jac = sum(dJ),
           held_term_at_canonical = EC$led[PR_HOLD, "prior"] + EC$led[PR_HOLD, "jac"])
CLOSE <- SPLIT[["d_logpost"]] - (SPLIT[["d_likelihood"]] + SPLIT[["d_other_priors"]] + SPLIT[["d_other_jac"]] - SPLIT[["held_term_at_canonical"]])
cat(sprintf("  logpost difference %+.4f = likelihood %+.4f + the other names' priors %+.4f + their Jacobians %+.4f - %s's own term at the canonical (%.4f)  [check %+.1e]\n",
            SPLIT[["d_logpost"]], SPLIT[["d_likelihood"]], SPLIT[["d_other_priors"]], SPLIT[["d_other_jac"]], PR_HOLD, SPLIT[["held_term_at_canonical"]], CLOSE))
if (abs(CLOSE) > CCX_REPRO_TOL) stop("the split does not close: ", CLOSE)
POST_PRICE <- SPLIT[["d_likelihood"]] + SPLIT[["d_other_priors"]] + (KW[["prior_at_pin"]] - KW[["prior_at_mode"]])
cat(sprintf("  => on the NATURAL scale (no Jacobians): likelihood %+.4f, the other names' priors %+.4f, %s's prior %+.4f => the posterior price of %g is %+.4f\n",
            SPLIT[["d_likelihood"]], SPLIT[["d_other_priors"]], PR_HOLD, KW[["prior_at_pin"]] - KW[["prior_at_mode"]], HOLD, POST_PRICE))
top1 <- common[o][1]
cat(sprintf("  the largest single prior move: %s %+.3f, i.e. %.0f %% of the other names' net prior change (%+.3f)\n", top1, dP[[top1]],
            100 * dP[[top1]] / sum(dP), sum(dP)))

# ---- 3. what absorbs the held name, and do the starts agree ---------------------------------------
cat("\n=== 3. WHAT ABSORBS IT: each name's move from the canonical, in the canonical's MARGINAL Laplace sd (u-space) ===\n")
cat(sprintf("  %s itself: %.1f -> %g = %+.2f marginal sd\n", PR_HOLD, KW[["value_at_mode"]], HOLD,
            (KW[["u_at_pin"]] - KW[["u_at_mode"]]) / sdC[[PR_HOLD]]))
Z <- lapply(EP, function(e) (e$u[common] - EC$u[common]) / sdC[common]); ZA <- Z[[A]][order(-abs(Z[[A]]))]
for (n in names(ZA)[seq_len(PR_TOP)]) cat(sprintf("  %-20s %12.5g -> %12.5g  %+6.2f sd%s\n", n, EC$led[n, "value"], EP[[A]]$led[n, "value"],
                                                 ZA[[n]], paste(vapply(setdiff(names(PF), A), function(k) sprintf("   (%s %+6.2f sd)", k, Z[[k]][[n]]), ""), collapse = "")))
if (length(PF) > 1L) for (k in setdiff(names(PF), A)) {
  sep <- (EP[[k]]$u[common] - EP[[A]]$u[common]) / sdC[common]
  cat(sprintf("  START AGREEMENT %s vs %s: logpost %+.2e, likelihood %+.2e; largest u-space separation %.3f marginal sd (%s) [descriptive bin %g]\n",
              k, A, EP[[k]]$logpost - EP[[A]]$logpost, EP[[k]]$lik - EP[[A]]$lik, max(abs(sep)), names(which.max(abs(sep))), PR_AGREE_SD))
}

# ---- 4. beside the 10-05 read (a different canonical and objective: hilda34g, label hilda_csl3v0kaidgbe) ----------
if (file.exists(PR_REF)) {
  R5 <- readRDS(PR_REF)
  hs5 <- R5$ledger_basin1["hs_asx_frac", "prior"] - R5$ledger_canonical["hs_asx_frac", "prior"]
  cat(sprintf("\n=== 4. BESIDE THE 10-05 READ (%s; its canonical hilda34g) ===\n", basename(PR_REF)))
  cat(sprintf("  likelihood %+.4f then, %+.4f now | other names' priors %+.4f then, %+.4f now | hs_asx_frac's prior %+.3f then, %+.3f now | posterior price %+.4f then, %+.4f now\n",
              R5$d_lik[["basin1"]], D_LIK[[A]], R5$split[["d_other_priors"]], SPLIT[["d_other_priors"]], hs5,
              if ("hs_asx_frac" %in% common) dP[["hs_asx_frac"]] else NA, R5$posterior_price, POST_PRICE))
}

sink()
saveRDS(list(streams = ST, d_lik = D_LIK, family = FAMD, ledger_canonical = EC$led, ledger_profile = lapply(EP, `[[`, "led"),
             held_term = KW, split = SPLIT, split_check = CLOSE, posterior_price = POST_PRICE, moves = Z,
             provenance = list(driver = PR_DRIVER, commit = COMMIT, mode = CCX_MODE_CANONICAL, mode_md5 = PF[[1]]$provenance$mode_md5,
                               hold = HOLD, profiles = stats::setNames(basename(FS), names(PF)),
                               profile_md5 = stats::setNames(unname(tools::md5sum(FS)), names(PF)), ref = PR_REF, rng = "none",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(PR_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", PR_OUT))
