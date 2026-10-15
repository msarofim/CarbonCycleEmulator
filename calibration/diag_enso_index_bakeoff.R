# =====================================================================
# diag_enso_index_bakeoff.R -- Marcus, 2026-09-02: "if we have two ENSO forcing
# options, test and see which gives the better fit."
#
# ⛔ WHY A FIXED-VECTOR COMPARISON WOULD BE MEANINGLESS. The candidates are in
# DIFFERENT UNITS and different amplitudes: Nino 3.4 is degC with sd 0.75, MEI is
# dimensionless with sd ~1, relative SST is degC with sd 0.71. At a gamma fitted
# to one of them, another simply delivers more or less forcing, and the logpost
# would rank AMPLITUDE, not the index. That is precisely the trap gate G-P caught
# in diag_enso_index_baseline.R, one comparison earlier.
# ⇒ EVERY CANDIDATE GETS ITS OWN BEST GAMMAS. The four gamma_enso coordinates are
#   re-optimized per index with all 21 other parameters FROZEN at the 09-01
#   basin vector. That absorbs units and amplitude and gives each index its best
#   shot, which is the only fair question.
#
# ⛔ AND A NATIVE-SPAN COMPARISON WOULD ALSO BE UNFAIR. The candidates cover
# different years (Nino 3.4 1948-, MEI.ext 1871-2005, MEIv2 1979-, relative SST
# 1854-), so a native-span winner could simply be the one that supplies ENSO over
# more of the scored record -- a COVERAGE result wearing an INDEX result's
# clothes ([[like_for_like_forcing]]). So both are reported:
#   COMMON span EB_COMMON -- every candidate truncated to the SAME years. The
#                            like-for-like question: which index is BETTER?
#   NATIVE span            -- each over all it covers. The practical question:
#                            which index would we actually GET more from?
#
# ⚠ OUTSIDE ITS TABLE, AN INDEX IS ZERO -- NOT FLAT-HELD. ccx_build_forcing()'s
# approx(rule = 2) holds the last value flat past the end of the record, which is
# harmless for the shipped index (it runs past 2024) and badly wrong for a
# truncated one: it would hold one ENSO month across two decades. Both ends are
# zeroed here, exactly as FORC_ENSO_PRE1948 does for the front.
#
# Usage:  Rscript calibration/diag_enso_index_bakeoff.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_enso_index.R"))

EB_ARM     <- "from90"
EB_BASIN   <- "calibration/output/multistart_20260901_enso25/start_000.rds"
EB_COMMON  <- c(1948, 2005)          # Nino 3.4 ∩ MEI.ext, the only shared window
EB_SCORED  <- c(1948, 2024)          # where index statistics are reported
EB_GAMMA   <- grep("gamma_enso", CCX_PARAM_NAMES)
EB_MAXIT   <- 1500
EB_RESTART <- 2                      # Nelder-Mead restarts from its own optimum
EB_OUT     <- file.path("outputs", "diagnostics", "enso_index_bakeoff.rds")
EB_ASIS_REF <- -1568.4936            # diag_enso_index_baseline.R, same vector
EB_REF_TOL  <- 1e-3

stopifnot(length(EB_GAMMA) == 4L)
cat(sprintf("\n%s\nENSO INDEX BAKE-OFF: each candidate with its OWN best gammas\n  arm %s, basin %s; 4 of %d params free, %d frozen\n%s\n",
            strrep("=", 78), EB_ARM, basename(dirname(EB_BASIN)), length(CCX_PARAM_NAMES),
            length(CCX_PARAM_NAMES) - 4L, strrep("=", 78)))

# ---- the candidates, all through lib_enso_index.R --------------------
CAND <- list(
  # ⚠ `asis` IS THE PRE-ADOPTION INDEX. Ruling A was adopted 2026-09-02 on this
  # very bake-off, so the stored column is no longer what the model sees --
  # `demean` below is. `asis` stays as the reference the +56.4785 is measured
  # FROM, which is what a price needs.
  asis    = list(d = eix_nino34_shipped(),               note = "stored Nino 3.4 (PSL, v6), PRE-adoption, degC"),
  demean  = list(d = eix_demean(eix_nino34_shipped(), EB_SCORED),
                                                         note = "shipped, span mean removed"),
  detrend = list(d = eix_detrend(eix_nino34_shipped(), EB_SCORED),
                                                         note = "shipped, linear trend removed (in-window)"),
  relsst  = list(d = eix_relative_sst(),                  note = "Nino3.4 − tropical mean, ERSSTv5, degC"),
  relsst_lf = list(d = eix_relative_sst(lowpass = TRUE),  note = "⭐ Nino3.4 − LOW-PASS tropical mean (21 yr)"),
  n34_v5  = list(d = eix_fixed_base(eix_ersst_box(EIX_BOX_N34)),
                                                         note = "relsst's PRODUCT control (v5, no rel.)"),
  mei_ext = list(d = eix_mei_ext(),                       note = "MEI.ext 1871-2005, sd units"),
  meiv2   = list(d = eix_meiv2(),                         note = "MEIv2 1979-, sd units"))

cat(sprintf("\n%-9s %-40s %9s %8s %9s %s\n", "index", "what", "mean", "sd", "trend/dec", "span"))
for (nm in names(CAND)) {
  d <- CAND[[nm]]$d; s <- eix_stats(d, EB_SCORED)
  cat(sprintf("%-9s %-40s %+9.4f %8.3f %+9.4f  %d-%d\n", nm, CAND[[nm]]$note,
              s[["mean"]], s[["sd"]], s[["trend"]], min(d$year), max(d$year)))
}

# ---- the harness ----------------------------------------------------
pm <- ccx_migrate_par_set(readRDS(ccx_path(EB_BASIN))$par_mode)
u0 <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u0)))
v  <- dg_vector(EB_ARM)
bp <- ccx_default_params(); bp$pump_mode <- v$md$pump_mode

.EB_ORIG <- ccx_build_forcing
eb_install <- function(tbl, win) {
  tb <- tbl[!is.na(tbl$value), ]
  if (!is.null(win)) tb <- tb[tb$year >= win[1] & tb$year <= win[2], ]
  stopifnot(nrow(tb) > 24)
  assign("ccx_build_forcing", function(...) {
    F <- .EB_ORIG(...)
    e <- stats::approx(tb$year + (tb$month - 0.5) / 12, tb$value, xout = F$t, rule = 2)$y
    e[F$year < min(tb$year) | F$year > max(tb$year)] <- FORC_ENSO_PRE1948   # BOTH ends
    F$enso <- e
    F
  }, envir = globalenv())
  tb
}
eb_restore <- function() assign("ccx_build_forcing", .EB_ORIG, envir = globalenv())

# Re-optimize ONLY the four gammas. Nelder-Mead: the objective is a full model
# run, so a numerical gradient would cost 4x per step for a surface this small.
eb_fit <- function(tbl, win) {
  tb <- eb_install(tbl, win); on.exit(eb_restore(), add = TRUE)
  lp <- ccx_make_logpost(base_params = bp)
  obj <- function(g) { u <- u0; u[EB_GAMMA] <- g; val <- lp(u)
                       if (!is.finite(val)) 1e9 else -val }
  frozen <- -obj(u0[EB_GAMMA])
  par <- u0[EB_GAMMA]; best <- Inf
  for (i in seq_len(EB_RESTART + 1L)) {
    o <- stats::optim(par, obj, method = "Nelder-Mead",
                      control = list(maxit = EB_MAXIT, reltol = 1e-10))
    par <- o$par; if (o$value >= best - 1e-8) { best <- o$value; break }
    best <- o$value
  }
  list(frozen = frozen, fitted = -best, gamma = par,
       gain = -best - frozen, sd_idx = stats::sd(tb$value),
       span = range(tb$year), n = nrow(tb))
}

run_span <- function(win, label) {
  cat(sprintf("\n=== %s ===\n", label))
  cat(sprintf("  %-9s %12s %12s %9s | %s\n", "index", "frozen", "REFIT", "gain",
              "gammas land_NH/SH, ocn_NH/SH  (x sd = effective)"))
  out <- list()
  for (nm in names(CAND)) {
    r <- eb_fit(CAND[[nm]]$d, win); out[[nm]] <- r
    cat(sprintf("  %-9s %12.3f %12.3f %+9.3f | %+.3f %+.3f %+.3f %+.3f  (%+.3f %+.3f %+.3f %+.3f)\n",
                nm, r$frozen, r$fitted, r$gain, r$gamma[1], r$gamma[2], r$gamma[3], r$gamma[4],
                r$gamma[1]*r$sd_idx, r$gamma[2]*r$sd_idx, r$gamma[3]*r$sd_idx, r$gamma[4]*r$sd_idx))
  }
  best <- names(out)[which.max(vapply(out, function(r) r$fitted, numeric(1)))]
  cat(sprintf("  ⇒ BEST: %s at %.3f; the field spans %.3f log-units.\n", best,
              max(vapply(out, function(r) r$fitted, numeric(1))),
              diff(range(vapply(out, function(r) r$fitted, numeric(1))))))
  out
}

# GATE -- the harness must reproduce the number the baseline file published for
# this very vector and index, or nothing below is about ENSO indices.
tb <- eb_install(CAND$asis$d, NULL); lp0 <- ccx_make_logpost(base_params = bp)
a0 <- lp0(u0); eb_restore()
cat(sprintf("\n  GATE  asis at FROZEN gammas, native span: %.4f vs published %.4f -> %s\n",
            a0, EB_ASIS_REF, if (abs(a0 - EB_ASIS_REF) < EB_REF_TOL) "PASS" else "⛔ FAIL"))
if (abs(a0 - EB_ASIS_REF) >= EB_REF_TOL)
  stop("the bake-off harness does not reproduce diag_enso_index_baseline.R's ",
       "number for the SAME vector and the SAME index. Fix that before ranking.")

res_c <- run_span(EB_COMMON, sprintf("COMMON SPAN %d-%d — the LIKE-FOR-LIKE question",
                                     EB_COMMON[1], EB_COMMON[2]))
res_n <- run_span(NULL,      "NATIVE SPAN — each index over all it covers")

cat("\n=== WHAT MOVED BETWEEN THE TWO SPANS (native − common) ===\n")
for (nm in names(CAND))
  cat(sprintf("  %-9s %+9.3f   %s\n", nm, res_n[[nm]]$fitted - res_c[[nm]]$fitted,
              sprintf("covers %d-%d natively", res_n[[nm]]$span[1], res_n[[nm]]$span[2])))
cat("  ⚠ a large positive move is COVERAGE, not index quality.\n")

dir.create(dirname(ccx_path(EB_OUT)), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(common = res_c, native = res_n, cand = lapply(CAND, function(x) x$note),
             win_common = EB_COMMON, arm = EB_ARM, basin = EB_BASIN,
             when = Sys.time()), ccx_path(EB_OUT))
cat(sprintf("\n  written: %s\n", EB_OUT))
