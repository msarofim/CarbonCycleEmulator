#!/usr/bin/env Rscript
# =====================================================================
# diag_obj18_basins.R -- OBJECTIVE #18's BASINS, decomposed BEFORE promoting (handoff
# notes/handoff_2026-10-07d_obj18_stage2_running.md s. 3.4; Marcus 2026-10-07 k: "Build --id, read both
# (Recommended)"). diag_obj17_basins.R's decomposition, on the WAVE's start files rather than on two promoted files.
#
# WHY. collect and promote rank by the STORED logpost, the density of the UNCONSTRAINED vector u: likelihood + prior
# + the log-Jacobian of each transform. At #17 the best of it (basin A) led by 0.409 only through h_ml's logit
# Jacobian, and basin B was better on LIKELIHOOD by 0.761 ([[basin_rank_by_logit_jacobian]]); Marcus chose B. The
# project compares fits on likelihood.
#
# WHAT. Every basin collect found (its summary.csv; the clustering is collect's, not re-done here) is represented by
# its best stored-logpost member, scored in the wave's OWN space (promote's GATE 4 construction: the recorded
# structure, gate, pins, seas_ml, pump field and the objective's spinup). Per basin: likelihood, priors,
# log-Jacobians, the natural-space density (likelihood + prior), h_ml, and its members -- DISTINCT members counted
# apart, because a seeded start whose seed hits a PINNED name re-runs its reference bit for bit (under the cut's
# pins ids 3 / 4 / 5 duplicate 1 / 2 / 2: [[pinned_name_seed_vanishes]], RULED 10-07 k "Records now, driver
# later"). Then each basin against the logpost-best: the parts, the names, the rows.
# THE DECISION it writes (<out>.ids, read by the landing chain): `LP <id>` = the best stored logpost (what promote
# picks by default) and `NAT <id>` = the representative of the basin best by LIKELIHOOD + PRIOR, the natural-space
# density: the stored logpost minus ONLY the Jacobian, the band's artifact. When they differ, the chain promotes,
# Hessians and reads BOTH; adoption stays Marcus's. ⛔ NOT the likelihood alone (RULED 10-07 k, Marcus: "Likelihood +
# prior (Recommended)"): validated on #17's own wave, the likelihood alone picked basin 3 (id 6), 33.9 below on the
# stored logpost, whose likelihood beats A by +2.38 only because its priors cost -36.6 (seas_lag_p_NH at -2.33).
# The likelihood ranking is still printed for every basin.
# ⭐ AND A NEAR-TIE (RULED 10-07 k, Marcus: "Read both within 0.5 (Recommended)"): `NEAR <id>` = the RUNNER-UP on likelihood
# + prior when it lies within the optimiser's own convergence bound (the starts' recorded `cycle_tol`, 0.5) of the best on
# it; the chain reads it too. Found on the dry run's 8-start preview: the two basins 0.087 apart on likelihood + prior.
# GATES: one structure / pin set / seas_ml / pump field / h_ml band across the wave; each representative reproduces
# its stored logpost (1e-5, the objective's noise floor: memory objective_noise_floor_optimum_on_spike); the three
# parts close each logpost exactly (1e-8); `LP` is the best converged, in-time, live start; collect's basin 1 holds it.
# Usage: Rscript calibration/diag_obj18_basins.R  (CCX_O18_WAVE=<dir> overrides the wave; CCX_O18_TAG=<suffix> tags
#        the outputs). OUTPUTS: outputs/diagnostics/obj18_basins_<date><tag>.{log,rds,ids}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
OB_DRIVER    <- "calibration/diag_obj18_basins.R"
OB_LABEL     <- CCX_MODE_OBJ18_STRUCT                       # "hilda_csl3v0kaidgbemwt"
OB_PINS      <- CCX_MODE_OBJ18_PINS                         # #16's ten + stage 1's four under #18 at basin B
OB_WAVE_GLOB <- "multistart_20261007i_hilda_csl3v0kaidgbemwt_seasml1_pin_obj18_sd1.0452"
OB_REPRO_TOL <- 1e-5          # recompute_hessian.R's GATE 1, promote's GATE 4
OB_CLOSE_TOL <- 1e-8          # the three parts sum to the logpost (diag_obj17_basins.R)
OB_TOP_NAMES <- 10L; OB_TOP_ROWS <- 12L
OB_SHOW      <- c("h_ml", "pump_grad", "kz", "beta_max", "fert_k", "q10")      # printed for every basin
OB_TAG       <- Sys.getenv("CCX_O18_TAG", "")
OB_OUT <- file.path("outputs", "diagnostics", sprintf("obj18_basins_%s%s", format(Sys.Date(), "%Y%m%d"), OB_TAG))
OB_WAVE <- Sys.getenv("CCX_O18_WAVE", "")
if (!nzchar(OB_WAVE)) { m <- Sys.glob(file.path("calibration", "output", OB_WAVE_GLOB))
  if (length(m) != 1L) stop(sprintf("the wave: %d matches for calibration/output/%s; exactly one is required (or set CCX_O18_WAVE)",
                                    length(m), OB_WAVE_GLOB))
  OB_WAVE <- m }
COMMIT <- ccx_git_stamp()
sink(paste0(OB_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n  wave %s\n", OB_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), OB_WAVE))
if (nzchar(OB_TAG)) cat(sprintf("  ⚠ TAGGED '%s': read the provenance before quoting anything below\n", OB_TAG))

# ---- the wave -------------------------------------------------------------------------------------
FS <- sort(list.files(OB_WAVE, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE))
if (!length(FS)) stop("no start files under ", OB_WAVE)
S  <- lapply(FS, readRDS); IDS <- vapply(S, function(s) as.integer(s$id), integer(1))
SM <- file.path(OB_WAVE, "summary.csv")
if (!file.exists(SM)) stop("no summary.csv under the wave: run collect_dispersed_multistart.R first (the basins are ITS clustering)")
SUM <- utils::read.csv(SM, stringsAsFactors = FALSE)
one <- function(f, what) { v <- unique(vapply(S, function(s) paste(format(f(s)), collapse = ","), ""))
  if (length(v) != 1L) stop("the starts disagree on ", what, ": ", paste(v, collapse = " | ")); f(S[[1]]) }
ST <- one(function(s) s$struct, "the structure"); SMl <- one(function(s) s$seas_ml, "seas_ml")
PF <- one(function(s) s$pump_field, "the pump field"); PM <- one(function(s) s$pump_mode, "the pump mode")
HB <- one(function(s) s$hml_bound, "the h_ml band"); PN <- one(function(s) ccx_pin_label(s$pins), "the pins")
OB_NEAR_GAP <- one(function(s) s$cycle_tol, "the optimiser's convergence bound (cycle_tol)")   # the near-tie window, READ
PINS <- S[[1]]$pins
if (!identical(ST, OB_LABEL)) stop("the wave's structure is '", ST, "', not #18's '", OB_LABEL, "'")
if (!setequal(names(PINS), names(OB_PINS)) || !isTRUE(all.equal(unname(unclass(PINS)[names(OB_PINS)]), unname(OB_PINS))))
  stop("the wave's pins are not CCX_MODE_OBJ18_PINS")
if (!isTRUE(all.equal(HB, c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi))))
  stop("the wave's h_ml band [", paste(HB, collapse = ", "), "] is not the table's: this script does not re-impose bands")
cat(sprintf("  %d start files; structure %s, seas_ml %s, pump field %s, pump mode %s, h_ml band [%g, %g]; pins %s\n",
            length(S), ST, SMl, PF, PM, HB[1], HB[2], PN))

# DUPLICATES: a start whose optimum is BIT-IDENTICAL to another's re-ran it (a seed that hit a pinned name)
key  <- vapply(S, function(s) paste(sprintf("%a", unlist(s$par_mode)), collapse = "|"), "")
twin <- match(key, key)                                     # each start's FIRST bit-identical twin (itself if none)
DUP  <- data.frame(id = IDS, same_as = IDS[twin], stringsAsFactors = FALSE)
dups <- DUP[DUP$id != DUP$same_as, ]
cat(sprintf("  DUPLICATES (optimum bit-identical to a lower id): %s\n", if (nrow(dups)) paste(sprintf("id %d = id %d", dups$id,
            dups$same_as), collapse = "; ") else "none"))

# ---- the objective ONCE, in the wave's own space (promote's GATE 4 construction; the gate and pins stay applied for
# the rest of this script, as in promote) ---------------------------------------------------------------------------
invisible(ccx_apply_gate(ST)); invisible(ccx_apply_pins(PINS))
bp <- ccx_apply_structure(ccx_default_params(), ST, seas_ml = ccx_parse_seas_ml(SMl), pump_field = ccx_parse_pump_field(PF))
for (n in names(PINS)) bp[[n]] <- PINS[[n]]
attr(bp, "pins") <- PINS; bp$pump_mode <- PM
OBS <- ccx_prepare_obs()
LPF <- ccx_make_logpost(base_params = bp, by_stream = TRUE, obs = OBS)   # CCX_OBJECTIVE_SPINUP: the wave's own
own <- function(s) { u <- ccx_par_to_unc(s$par_mode); v <- LPF(u)
  par <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(par)) p_pr[[n]] <- par[[n]]
  L <- t(vapply(names(u), function(n) { sp <- CCX_PARAM_TABLE[[n]] %||% CCX_PARAM_GATED_ALL[[n]]
    c(value = par[[n]], prior = .ccx_prior_eval(sp, par[[n]], p_pr), jac = .log_jac(u[[n]], sp)) }, numeric(3)))
  list(id = as.integer(s$id), lp = as.numeric(v), lik = attr(v, "loglik"), st = unlist(attr(v, "streams")), L = L,
       stored = s$logpost) }

# ---- the basins ------------------------------------------------------------------------------------
live <- vapply(S, function(s) isTRUE(s$converged) && !isTRUE(s$out_of_time) && !isTRUE(s$dead), TRUE)
if (!any(live)) stop("no converged, in-time, live start in the wave")
LP_ID <- IDS[live][which.max(vapply(S[live], `[[`, 0, "logpost"))]
B <- SUM[!is.na(SUM$basin) & SUM$converged & !SUM$out_of_time, ]
B <- B[B$id %in% IDS[live], ]
if (!nrow(B)) stop("collect's summary.csv names no converged, in-time basin member")
if (!(LP_ID %in% B$id[B$basin == min(B$basin)])) stop("the best stored logpost (id ", LP_ID, ") is not in collect's basin ", min(B$basin))
BAS <- sort(unique(B$basin))
REP <- vapply(BAS, function(b) { m <- B[B$basin == b, ]; m$id[which.max(m$logpost)] }, 0L)
X <- lapply(REP, function(id) own(S[[match(id, IDS)]])); names(X) <- paste0("b", BAS)

cat("\n=== 0. GATES ===\n")
for (k in names(X)) { x <- X[[k]]
  cat(sprintf("  basin %s (id %03d): logpost %.6f, stored %.6f, diff %+.1e (tol %g)\n", sub("^b", "", k), x$id, x$lp, x$stored,
              x$lp - x$stored, OB_REPRO_TOL))
  if (!(abs(x$lp - x$stored) <= OB_REPRO_TOL)) stop("basin ", k, "'s representative does not reproduce its stored logpost")
  gap <- x$lp - (x$lik + sum(x$L[, "prior"]) + sum(x$L[, "jac"]))
  if (abs(gap) > OB_CLOSE_TOL) stop("basin ", k, ": likelihood + prior + Jacobian misses the logpost by ", signif(gap, 3)) }
cat(sprintf("  likelihood + prior + Jacobian close every logpost to <= %g\n", OB_CLOSE_TOL))

cat("\n=== 1. THE BASINS (collect's clustering; each by its best stored-logpost member) ===\n")
TAB <- do.call(rbind, lapply(seq_along(BAS), function(i) { x <- X[[i]]; mem <- B$id[B$basin == BAS[i]]
  dis <- unique(DUP$same_as[match(mem, DUP$id)])
  data.frame(basin = BAS[i], id = x$id, n = length(mem), n_distinct = length(dis), logpost = x$lp, lik = x$lik,
             prior = sum(x$L[, "prior"]), jac = sum(x$L[, "jac"]), natural = x$lik + sum(x$L[, "prior"]),
             members = paste(sort(mem), collapse = " "), stringsAsFactors = FALSE) }))
for (n in OB_SHOW) TAB[[n]] <- vapply(X, function(x) x$L[n, "value"], 0)
for (i in seq_len(nrow(TAB))) with(TAB[i, ], cat(sprintf(paste0("  basin %d  id %03d  x%d (%d distinct)  logpost %.4f  likelihood %.4f  prior %+.4f  ",
                                                                 "Jacobian %+.4f  lik+prior %.4f\n            %s\n            members: %s\n"),
  basin, id, n, n_distinct, logpost, lik, prior, jac, natural,
  paste(sprintf("%s %.5g", OB_SHOW, unlist(TAB[i, OB_SHOW])), collapse = ", "), members)))

LIK_ID <- TAB$id[which.max(TAB$lik)]; NAT_ID <- TAB$id[which.max(TAB$natural)]
ON <- order(-TAB$natural)                                       # the runner-up on likelihood + prior, if within the bound
NEAR_ID <- if (length(ON) > 1L && TAB$natural[ON[1]] - TAB$natural[ON[2]] <= OB_NEAR_GAP) TAB$id[ON[2]] else NA_integer_
cat(sprintf("\n  BEST by stored logpost: id %03d (basin %d) | by LIKELIHOOD: id %03d (basin %d) | by likelihood + prior: id %03d (basin %d)\n",
            LP_ID, TAB$basin[TAB$id == LP_ID], LIK_ID, TAB$basin[TAB$id == LIK_ID], NAT_ID, TAB$basin[TAB$id == NAT_ID]))
cat(if (identical(LP_ID, NAT_ID)) "  ⇒ the stored logpost and likelihood + prior AGREE on the best basin\n"
    else "  ⇒ the stored logpost and likelihood + prior DISAGREE: the chain promotes, Hessians and reads BOTH (RULED 10-07 k); the basin choice is Marcus's\n")
if (length(ON) > 1L) cat(sprintf("  the runner-up on likelihood + prior: basin %d (id %03d), %.4f below the best: %s the near-tie bound %g (the starts' cycle_tol)%s\n",
  TAB$basin[ON[2]], TAB$id[ON[2]], TAB$natural[ON[1]] - TAB$natural[ON[2]], if (is.na(NEAR_ID)) "OUTSIDE" else "INSIDE", OB_NEAR_GAP,
  if (is.na(NEAR_ID)) "" else " -- the chain reads it too (RULED 10-07 k: \"Read both within 0.5\")"))
if (!LIK_ID %in% c(LP_ID, NAT_ID)) {
  pk <- TAB[TAB$id == LIK_ID, ]; p0 <- TAB[TAB$id == NAT_ID, ]
  cat(sprintf("  ⚠ the likelihood ALONE picks basin %d (id %03d): likelihood %+.3f but priors %+.3f against basin %d's. NOT promoted (RULED 10-07 k: likelihood + prior)\n",
              pk$basin, pk$id, pk$lik - p0$lik, pk$prior - p0$prior, p0$basin))
}

cat("\n=== 2. EACH BASIN AGAINST THE LOGPOST-BEST (other - best) ===\n")
x0 <- X[[match(LP_ID, TAB$id)]]
PAIRS <- list()
for (k in names(X)) { x <- X[[k]]; if (identical(x$id, LP_ID)) next
  d_lik <- x$lik - x0$lik; d_pri <- sum(x$L[, "prior"] - x0$L[, "prior"]); d_jac <- sum(x$L[, "jac"] - x0$L[, "jac"])
  cat(sprintf("  basin %s (id %03d) - basin %d (id %03d): logpost %+.4f = likelihood %+.4f + priors %+.4f + Jacobians %+.4f; lik+prior %+.4f\n",
              sub("^b", "", k), x$id, TAB$basin[TAB$id == LP_ID], LP_ID, x$lp - x0$lp, d_lik, d_pri, d_jac, d_lik + d_pri))
  DN <- data.frame(name = rownames(x$L), other = x$L[, "value"], best = x0$L[rownames(x$L), "value"],
                   dprior = x$L[, "prior"] - x0$L[rownames(x$L), "prior"], djac = x$L[, "jac"] - x0$L[rownames(x$L), "jac"], row.names = NULL)
  DN <- DN[order(-abs(DN$dprior + DN$djac)), ]
  for (i in seq_len(min(OB_TOP_NAMES, nrow(DN)))) cat(sprintf("    %-20s %12.5g vs %12.5g   prior %+8.4f  Jacobian %+8.4f\n",
                                                           DN$name[i], DN$other[i], DN$best[i], DN$dprior[i], DN$djac[i]))
  DS <- x$st - x0$st[names(x$st)]; DS <- DS[order(-abs(DS))]
  for (i in seq_len(min(OB_TOP_ROWS, length(DS)))) cat(sprintf("    row %-22s %+8.4f\n", names(DS)[i], DS[[i]]))
  cat(sprintf("    rows favouring the other basin %+.4f; rows favouring the best %+.4f (%d rows)\n", sum(DS[DS > 0]), sum(DS[DS < 0]), length(DS)))
  PAIRS[[k]] <- list(d_logpost = x$lp - x0$lp, d_lik = d_lik, d_prior = d_pri, d_jac = d_jac, names = DN, rows = DS) }
if (!length(PAIRS)) cat("  one basin: nothing to compare\n")

writeLines(c(sprintf("LP %d", LP_ID), sprintf("NAT %d", NAT_ID), if (!is.na(NEAR_ID)) sprintf("NEAR %d", NEAR_ID)), paste0(OB_OUT, ".ids"))
saveRDS(list(table = TAB, duplicates = DUP, lp_id = LP_ID, lik_id = LIK_ID, nat_id = NAT_ID, near_id = NEAR_ID, near_gap = OB_NEAR_GAP, pairs = PAIRS,
             scored = lapply(X, function(x) x[c("id", "lp", "lik", "st", "L", "stored")]),
             provenance = list(driver = OB_DRIVER, commit = COMMIT, wave = OB_WAVE, summary_csv = SM,
                               summary_md5 = unname(tools::md5sum(SM)), n_starts = length(S), struct = ST, pins = PN,
                               seas_ml = SMl, pump_field = PF, hml_bound = HB, tag = OB_TAG,
                               tols = c(repro = OB_REPRO_TOL, close = OB_CLOSE_TOL),
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none",
                               units = "log-density units (stored logpost = likelihood + prior + log-Jacobian)")),
        paste0(OB_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds,ids}: LP %d, NAT %d%s\n⛔ ADOPTS NOTHING.\n", OB_OUT, LP_ID, NAT_ID, if (is.na(NEAR_ID)) "" else sprintf(", NEAR %d", NEAR_ID)))
sink()
