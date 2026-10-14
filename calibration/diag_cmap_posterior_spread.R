#!/usr/bin/env Rscript
# =====================================================================
# diag_cmap_posterior_spread.R -- THE TIE CUT FROM THE POSTERIOR: how far does each constraint-map row's top-two
# margin move across MCMC posterior draws? (Marcus 2026-10-14, verbatim: "Posterior spread, 100 draws
# (Recommended)". Deferred to the MCMC read at 10-13 k, "Defer to the MCMC (Recommended)".)
#
# WHY. The app's takeaway calls a row a TIE when its top-two margin is at most APP_CMAP_TIE_PP. Since 10-12 (h) that
# cut is a measured spread: the largest margin change between the canonical and its like-for-like basin. At
# hilda31w no near basin exists (10-13 k: the runner-up is 3.49 log-units below, on the other side of the lag trade),
# so the spread is measured over the posterior instead.
#
# WHAT IT COMPUTES. The constraint map (calibration/diag_constraint_map.R) re-evaluated at N_DRAWS posterior draws:
#   - the SAME objective harness the MCMC sampled (gate, pins, band, spin-up), with by-stream likelihoods;
#   - the SAME step: the shipped map's conditional Hessian sd at the mode, one per name (CM2). A draw has no Hessian,
#     and a fixed step keeps every map an equal-difficulty-at-the-mode comparison;
#   - the SAME aggregation: the shipped map's own component and family tables (no second naming table).
# Per row: the SIGNED margin of the canonical's winner over the best other component, in pp of the row (the
# definition test-cmap-tie.R's .cm_signed uses), at every draw.
# THE RULED STATISTIC: the cut = the largest 5-95 % range of any row's signed margin over the draws.
# Printed beside it, NOT ruled: each row's one-sided excursion from the canonical's margin (the closer analogue of
# 10-12 h's "change from the canonical"), and the share of draws in which the row's winner differs.
#
# GATES, before a draw is read:
#   MAP   at the mode, this harness reproduces the SHIPPED map's MC (data/constraint_map.rds): an identity, so its
#         tolerance is the build's own closure tolerance, CM_CLOSE_TOL (1e-9 log-units).
#   STEP  the shipped conditional sds equal 1/sqrt(diag(-H)) of the mode file's Hessian.
#   JOIN  each chosen pooled row is the chain sample it claims to be (chain, kept index), exactly.
#   LP    at each draw, the harness's logpost equals the chain's stored logpost, to CCX_REPRO_TOL.
# IT REPORTS; IT DOES NOT RULE. APP_CMAP_TIE_* and test-cmap-tie.R are not touched: the numbers come back to Marcus
# first.
# Usage (repo root): Rscript calibration/diag_cmap_posterior_spread.R --draws=<pooled_u_thin*.rds> --chains=<snapshot dir>
#   [--n=100] [--cores=1] [--out-dir=outputs/diagnostics]
# No RNG: the draws are evenly spaced rows of the pooled file.
# =====================================================================
PS_ARGS <- commandArgs(trailingOnly = TRUE)
ps_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), PS_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants: every label and filename derives from these --------
PS_DRIVER   <- "calibration/diag_cmap_posterior_spread.R"
PS_DRAWS    <- ps_arg("draws", "")
PS_CHAINS   <- ps_arg("chains", "")
PS_N        <- as.integer(ps_arg("n", 100L))
PS_CORES    <- as.integer(ps_arg("cores", 1L))
PS_OUT_DIR  <- ps_arg("out-dir", file.path("outputs", "diagnostics"))
PS_MAP      <- file.path("data", "constraint_map.rds")   # the SHIPPED canonical map: tables, step, reference MC
PS_PROBS    <- c(0.05, 0.50, 0.95)                       # the ruled range is PS_PROBS[3] - PS_PROBS[1]
CM_CLOSE_TOL <- 1e-9                                     # diag_constraint_map.R's identity tolerance (log-units)
PS_COMMIT   <- ccx_git_stamp()
stopifnot(nzchar(PS_DRAWS), file.exists(PS_DRAWS), nzchar(PS_CHAINS), dir.exists(PS_CHAINS), file.exists(PS_MAP),
          PS_N >= 2L, PS_CORES >= 1L)
dir.create(PS_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
PS_STEM <- file.path(PS_OUT_DIR, sprintf("cmap_posterior_spread_%s_%s_n%d", format(Sys.Date(), "%Y%m%d"),
                                         CCX_MODE_CANONICAL, PS_N))
sink(paste0(PS_STEM, ".log"), split = TRUE)
cat(sprintf("=== %s @%s, %s ===\n", PS_DRIVER, PS_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))

# ---- the harness: run_mcmc_check.R's space (as diag_mcmc_identifiability.R), with by-stream likelihoods ----
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
pins <- ccx_mode_pins(md); invisible(ccx_apply_pins(pins))
ccx_require_param_set(md, PS_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
for (n in names(pins)) bp[[n]] <- pins[[n]]
st <- ccx_mode_start(md, PS_DRIVER)
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
NAMES <- md$param_names

# ---- the shipped map: its tables, its step, and the reference it must reproduce ----
cm <- readRDS(PS_MAP)
stopifnot(identical(cm$provenance$mode, CCX_MODE_CANONICAL), identical(cm$step_kind, "conditional"),
          setequal(names(cm$sd_conditional), NAMES))
SD_H <- 1 / sqrt(diag(-md$hessian)); names(SD_H) <- NAMES
d_step <- max(abs(cm$sd_conditional[NAMES] - SD_H))
cat(sprintf("GATE STEP: shipped conditional sd vs 1/sqrt(diag(-H)) of %s: max |diff| %.2e -> %s\n",
            CCX_MODE_CANONICAL, d_step, if (d_step == 0) "PASS (exact)" else "*** FAIL ***"))
if (d_step != 0) stop("the shipped map's step is not this mode's Hessian")
STEP <- cm$step_sd * cm$sd_conditional[NAMES]
STREAMS <- unlist(cm$family, use.names = FALSE)

# one map at u: the stream deltas of +/- one step per name, aggregated exactly as diag_constraint_map.R (CM3).
# ⚠ A HALF-STEP THE OBJECTIVE REFUSES (a METHOD CHOICE, flagged to Marcus 2026-10-14). The h_ml step is ~2 m at the
# mode, and the wall is the substep cap at 75.02 m, so from a draw above ~73 m (about 5 % of the posterior) the upward
# half is refused. The map's cell is then the finite half alone (pmax with na.rm). Every refusal is recorded per
# draw, and the cut is reported with and without the draws that had one. At the mode no half is refused (GATE MAP).
ps_half <- function(uu, s0) {
  v <- tryCatch(lp(uu), error = function(e) NULL)
  s <- if (is.null(v)) NULL else attr(v, "streams")
  if (is.null(s) || !is.finite(as.numeric(v)) || !all(is.finite(s[STREAMS]))) return(rep(NA_real_, length(STREAMS)))
  s[STREAMS] - s0[STREAMS]
}
# DIAGNOSTIC SPLIT (not the map; 2026-10-14). The map's cell is max(|d+|, |d-|). Its CURVATURE part |d+ + d-| / 2 and
# SLOPE part |d+ - d-| / 2 are kept too: at the mode the TOTAL gradient is zero, at a draw it is not, so a row's
# margin can move across draws through the slope part alone. Same aggregation; no extra evaluations.
ps_agg <- function(X) {
  MC <- matrix(0, length(cm$family), length(cm$component), dimnames = list(names(cm$family), names(cm$component)))
  for (a in seq_along(cm$family)) for (k in seq_along(cm$component))
    MC[a, k] <- sum(X[cm$family[[a]], cm$component[[k]], drop = FALSE])
  MC
}
ps_map <- function(u) {
  b <- lp(u); s0 <- attr(b, "streams")
  if (!setequal(names(s0), STREAMS)) stop("the objective's streams are not the map's families")
  M <- MCV <- MSL <- matrix(NA_real_, length(STREAMS), length(NAMES), dimnames = list(STREAMS, NAMES))
  refused <- character(0)
  for (j in seq_along(NAMES)) {
    uh <- u; uh[j] <- u[[j]] + STEP[[j]]
    ul <- u; ul[j] <- u[[j]] - STEP[[j]]
    dh <- ps_half(uh, s0); dl <- ps_half(ul, s0)
    if (anyNA(dh)) refused <- c(refused, paste0(NAMES[[j]], "+"))
    if (anyNA(dl)) refused <- c(refused, paste0(NAMES[[j]], "-"))
    if (anyNA(dh) && anyNA(dl)) stop("both half-steps refused for ", NAMES[[j]])
    M[, j] <- pmax(abs(dh), abs(dl), na.rm = TRUE)
    MCV[, j] <- abs(dh + dl) / 2; MSL[, j] <- abs(dh - dl) / 2   # NA where a half was refused
  }
  list(MC = ps_agg(M), MC_curv = ps_agg(MCV), MC_slope = ps_agg(MSL), logpost = as.numeric(b), refused = refused)
}

# ---- GATE MAP: at the mode, the shipped MC exactly (to the build's closure tolerance) ----
u0 <- st$u[NAMES]
t0 <- Sys.time()
m0 <- ps_map(u0)
sec_map <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
d_map <- max(abs(m0$MC - cm$MC[rownames(m0$MC), colnames(m0$MC)]))
cat(sprintf("GATE MAP: this harness's map at %s vs %s (commit %s): max |diff| %.2e log-units (tol %.0e) -> %s; %.1f s per map\n",
            CCX_MODE_CANONICAL, PS_MAP, cm$provenance$commit, d_map, CM_CLOSE_TOL,
            if (d_map < CM_CLOSE_TOL) "PASS" else "*** FAIL ***", sec_map))
if (!(d_map < CM_CLOSE_TOL)) stop("this harness does not reproduce the shipped constraint map at the mode")
if (length(m0$refused)) stop("a half-step is refused AT THE MODE (", paste(m0$refused, collapse = ", "), ")")

# ---- the draws: evenly spaced rows of the pooled file, joined back to their chain samples ----
U <- readRDS(PS_DRAWS); pu <- attr(U, "provenance")
stopifnot(identical(colnames(U), NAMES), identical(pu$mode, CCX_MODE_CANONICAL), !is.null(pu$pool_thin))
PS_ROWS <- unique(round(seq(1, nrow(U), length.out = PS_N)))
stopifnot(length(PS_ROWS) == PS_N)
per <- pu$per_chain                                       # pooled rows per chain, chain by chain in iteration order
fs <- file.path(PS_CHAINS, pu$chains)
stopifnot(all(file.exists(fs)), identical(unname(tools::md5sum(fs)), pu$chain_md5))
S <- lapply(fs, readRDS)
JOIN <- data.frame(row = PS_ROWS, chain = (PS_ROWS - 1L) %/% per + 1L)
JOIN$kept <- ((PS_ROWS - 1L) %% per + 1L) * pu$pool_thin  # pool rule: kept sample j is pooled when j mod k == 0
JOIN$iter <- vapply(seq_len(nrow(JOIN)), function(i) S[[JOIN$chain[i]]]$samples_iter[JOIN$kept[i]], integer(1))
JOIN$lp_chain <- vapply(seq_len(nrow(JOIN)), function(i) S[[JOIN$chain[i]]]$samples_lp[JOIN$kept[i]], numeric(1))
same <- vapply(seq_len(nrow(JOIN)), function(i)
  identical(unname(U[JOIN$row[i], ]), unname(S[[JOIN$chain[i]]]$samples[JOIN$kept[i], ])), logical(1))
cat(sprintf("GATE JOIN: %d of %d chosen pooled rows are exactly the chain sample they claim -> %s\n",
            sum(same), nrow(JOIN), if (all(same)) "PASS" else "*** FAIL ***"))
if (!all(same)) stop("the pooled draws do not join back to their chains")
cat(sprintf("draws: %s (md5 %s), %d of %d rows, every %.1f-th; per chain %s\n", PS_DRAWS,
            unname(tools::md5sum(PS_DRAWS)), PS_N, nrow(U), (nrow(U) - 1) / (PS_N - 1),
            paste(tabulate(JOIN$chain, length(S)), collapse = " / ")))
cat(sprintf("--- %d maps x %d evaluations on %d core(s), ~%.0f min ---\n", PS_N, 2L * length(NAMES) + 1L, PS_CORES,
            PS_N * sec_map / 60 / PS_CORES))

t1 <- Sys.time()
maps <- parallel::mclapply(JOIN$row, function(r) tryCatch(ps_map(U[r, ]),
                           error = function(e) list(error = conditionMessage(e))),
                           mc.cores = PS_CORES, mc.preschedule = FALSE)
ok <- vapply(maps, function(m) is.null(m$error), logical(1))
cat(sprintf("%d of %d maps ran (%.1f min)\n", sum(ok), PS_N, as.numeric(difftime(Sys.time(), t1, units = "mins"))))
if (!all(ok)) stop("maps failed: ", paste(unique(unlist(lapply(maps[!ok], `[[`, "error"))), collapse = " | "))
JOIN$lp_harness <- vapply(maps, `[[`, numeric(1), "logpost") - st$logpost_shift
d_lp <- max(abs(JOIN$lp_harness - JOIN$lp_chain))
cat(sprintf("GATE LP: at every draw the harness's logpost vs the chain's stored one: max |diff| %.2e (tol %g = CCX_REPRO_TOL; shift %+.4f) -> %s\n",
            d_lp, CCX_REPRO_TOL, st$logpost_shift, if (d_lp < CCX_REPRO_TOL) "PASS" else "*** FAIL ***"))
if (!(d_lp < CCX_REPRO_TOL)) stop("the draws are not being evaluated in the space the MCMC sampled")

# ---- the margins: test-cmap-tie.R's definitions, verbatim ----
ps_signed <- function(r, w) { s <- 100 * r / sum(r); s[[w]] - max(s[names(s) != w]) }
ps_winner <- function(r) names(which.max(r))
FAM <- rownames(cm$MC)
W0  <- apply(cm$MC, 1, ps_winner)
MG0 <- vapply(FAM, function(f) ps_signed(cm$MC[f, ], W0[[f]]), numeric(1))
MG  <- vapply(maps, function(m) vapply(FAM, function(f) ps_signed(m$MC[f, ], W0[[f]]), numeric(1)),
              numeric(length(FAM)))                       # rows = families, cols = draws
WIN <- vapply(maps, function(m) apply(m$MC[FAM, , drop = FALSE], 1, ps_winner), character(length(FAM)))
Q <- t(apply(MG, 1, stats::quantile, probs = PS_PROBS, names = FALSE, type = 7))
TOT <- rowSums(cm$MC)
tab <- data.frame(family = FAM, winner = unname(W0), margin_mode = unname(MG0),
                  q05 = Q[, 1], q50 = Q[, 2], q95 = Q[, 3], range_5_95 = Q[, 3] - Q[, 1],
                  excursion = pmax(MG0 - Q[, 1], Q[, 3] - MG0),
                  share_other_winner = rowMeans(WIN != W0), total_rank = rank(-TOT)[FAM],
                  stringsAsFactors = FALSE)
CUT <- max(tab$range_5_95); CUT_ROW <- tab$family[which.max(tab$range_5_95)]
cat(sprintf("\n=== each row's signed margin of the canonical's winner, pp of the row, over %d draws ===\n", PS_N))
print(tab[order(-tab$range_5_95), ], row.names = FALSE, digits = 3)
cat(sprintf("\nTHE RULED STATISTIC: the largest %.0f-%.0f %% range of any row's margin = %.3f pp (%s)\n",
            100 * PS_PROBS[1], 100 * PS_PROBS[3], CUT, CUT_ROW))
cat(sprintf("  beside it, NOT ruled: largest one-sided excursion from the mode's margin %.3f pp (%s)\n",
            max(tab$excursion), tab$family[which.max(tab$excursion)]))
cat(sprintf("  the carried cut today: APP_CMAP_TIE_PP 1.923 pp (hilda29e vs hilda29a6, 10-12 h)\n"))
top3 <- tab[order(tab$total_rank), ][1:3, ]
cat(sprintf("the app's top three rows by total leverage, at the mode: %s\n",
            paste(sprintf("%s (margin %.2f -> %s at %.3f)", top3$family, top3$margin_mode,
                          ifelse(top3$margin_mode <= CUT, "TIE", "winner"), CUT), collapse = "; ")))
above <- tab$family[tab$margin_mode > CUT & tab$share_other_winner > 0]
cat(sprintf("rows whose mode margin EXCEEDS the cut but whose winner differs in some draw: %d%s\n", length(above),
            if (length(above)) paste0(" {", paste(sprintf("%s %.0f %%", above,
                                                         100 * tab$share_other_winner[match(above, tab$family)]),
                                                 collapse = "; "), "}") else ""))
cat(sprintf("rows that are TIES at the mode under this cut: %d of %d\n", sum(tab$margin_mode <= CUT), nrow(tab)))
# the refused half-steps (the method choice above), and the cut without the draws that had one
JOIN$refused <- vapply(maps, function(m) paste(m$refused, collapse = ","), character(1))
clean <- !nzchar(JOIN$refused)
CUT_CLEAN <- max(apply(MG[, clean, drop = FALSE], 1, function(x)
  diff(stats::quantile(x, PS_PROBS[c(1, 3)], names = FALSE, type = 7))))
cat(sprintf("\nREFUSED HALF-STEPS: %d of %d draws had one {%s}; the cut over the other %d draws: %.3f pp (all draws %.3f)\n",
            sum(!clean), PS_N, paste(sort(unique(unlist(lapply(maps, `[[`, "refused")))), collapse = ", "),
            sum(clean), CUT_CLEAN, CUT))

# the diagnostic split: the same ruled statistic on the curvature and slope parts alone (draws with no refusal)
split_cut <- function(key) {
  w0 <- apply(m0[[key]], 1, ps_winner)
  mg <- vapply(maps[clean], function(m) vapply(FAM, function(f) ps_signed(m[[key]][f, ], w0[[f]]), numeric(1)),
               numeric(length(FAM)))
  rg <- apply(mg, 1, function(x) diff(stats::quantile(x, PS_PROBS[c(1, 3)], names = FALSE, type = 7)))
  data.frame(part = key, cut = max(rg), row = FAM[which.max(rg)], median_row_range = stats::median(rg),
             share_other_winner = mean(vapply(maps[clean], function(m)
               mean(apply(m[[key]][FAM, , drop = FALSE], 1, ps_winner) != w0), numeric(1))))
}
SPLIT <- do.call(rbind, lapply(c("MC", "MC_curv", "MC_slope"), split_cut))
cat(sprintf("\nDIAGNOSTIC SPLIT (not the map): the ruled statistic on each part of the cell, over the %d draws with no refusal\n",
            sum(clean)))
print(SPLIT, row.names = FALSE, digits = 4)

saveRDS(list(table = tab, cut = CUT, cut_row = CUT_ROW, cut_without_refusals = CUT_CLEAN, split = SPLIT,
             margins = MG, winners = WIN, join = JOIN,
             MC = lapply(maps, `[[`, "MC"), MC_curv = lapply(maps, `[[`, "MC_curv"),
             MC_slope = lapply(maps, `[[`, "MC_slope"), MC_mode = m0[c("MC", "MC_curv", "MC_slope")],
             provenance = list(driver = PS_DRIVER, commit = PS_COMMIT, mode = CCX_MODE_CANONICAL,
                               map = PS_MAP, map_commit = cm$provenance$commit, draws = PS_DRAWS,
                               draws_md5 = unname(tools::md5sum(PS_DRAWS)), draws_provenance = pu,
                               rows = PS_ROWS, n = PS_N, probs = PS_PROBS, step = cm$provenance$step,
                               statistic = "max over rows of the 5-95 % range of the canonical winner's signed margin",
                               ruling = "Marcus 2026-10-14: \"Posterior spread, 100 draws (Recommended)\"",
                               gates = c(step = d_step, map = d_map, lp = d_lp), seed = NA_integer_,
                               seed_note = "no RNG: evenly spaced rows of the pooled draws")),
        paste0(PS_STEM, ".rds"))
cat(sprintf("\nprovenance: %s @%s; mode %s; map %s @%s; draws %s (%d); no RNG\nwrote %s.{log,rds}\n",
            PS_DRIVER, PS_COMMIT, CCX_MODE_CANONICAL, PS_MAP, cm$provenance$commit, PS_DRAWS, PS_N, PS_STEM))
sink()
