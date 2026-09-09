# =====================================================================
# DOES RULING 4's PENALTY SURVIVE AN HONEST WIDENING OF THE BOMB-WINDOW
# TARGET UNCERTAINTY?  (2026-09-09d)
#
# Marcus: "Are there any reasons to think that uncertainty in other data is more
# than the original studies reported? I don't want to over fit to data which
# might be flawed."
#
# ⛔ THE PREMISE THAT MOTIVATED THIS HAD THE WRONG DENOMINATOR. DATA.md sec.9c,
# CHANGELOG 09-09 and [[ccx_graven_vs_hua]] all say Graven-vs-Hua shows "Hua's
# 3.6 permil sd understates the systematic uncertainty by 3-11x in exactly the
# years the bomb constraint dominates". THE OBJECTIVE DOES NOT USE 3.6 permil
# THERE. R/likelihood.R design note 3 already adds LIK_D14C_REP_BOMB = 25 permil
# in quadrature over LIK_D14C_BOMB_WIN, for precisely this class of error
# ("aggregating them to two hemispheric boxes has no uniquely right weighting
# ... otherwise the bomb peak would dominate the posterior on the strength of a
# weighting choice"). MEASURED: the scored annual stream carries sigma_eff
# 25.7-25.8 permil in 1963-65 against 6.9-7.4 outside. So the real shortfall at
# the peak is ~40/25.7 = 1.55x, NOT 3-11x. [[verify_the_quantity_not_the_word]]
#
# WHAT THIS MEASURES. The de-biasing's -92.74 rescored at a RANGE of bomb-window
# representation errors, holding everything else fixed. The model run does not
# depend on the sigma, so each arm is run ONCE and rescored under every value.
#
# ⚠ THE CANDIDATE VALUES ARE FLAGGED, NOT CHOSEN -- picking one is a Marcus
# ruling and an OBJECTIVE CHANGE:
#   25  the shipped value (zonal-weighting spread, measured 2026-08)
#   40  the largest Graven-Hua hemispheric disagreement at the peak (1964)
#   47  = sqrt(25^2 + 40^2), IF aggregation and compilation error are treated as
#       INDEPENDENT. ⚠ They are probably NOT: the Graven-Hua difference is
#       ANTISYMMETRIC and is itself a PARTITION disagreement, i.e. the same
#       KIND of error the 25 was calibrated for. 47 is therefore an upper
#       bound, not an estimate.
#
# Usage: CCX_PRE_BOMB=<pre-de-biasing product> Rscript calibration/diag_bomb_rep_sensitivity.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

BR_REPS  <- c(25, 32, 40, 47)          # permil; 25 = shipped. See header.
BR_SHIP  <- LIK_D14C_REP_BOMB
BR_LIVE  <- ccx_path("data", "forcing_bomb_c14.rds")
BR_PRE   <- Sys.getenv("CCX_PRE_BOMB", "")
BR_BACK  <- Sys.getenv("CCX_LIVE_BACKUP", "")
BR_OUT   <- ccx_path("outputs", "diagnostics",
                     sprintf("bomb_rep_sensitivity_%s.rds", format(Sys.Date(), "%Y%m%d")))
stopifnot(nzchar(BR_PRE), file.exists(BR_PRE), nzchar(BR_BACK), file.exists(BR_BACK))
stopifnot(BR_SHIP == 25)               # the header's arithmetic assumes it

md5 <- function(p) as.character(tools::md5sum(p))
md0 <- md5(BR_LIVE)
v   <- dg_vector(CCX_MODE_CANONICAL)
err <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
            grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)

# ---- run each arm ONCE; the model does not depend on the sigma -------
RUNS <- list()
tryCatch({
  RUNS$post <- dg_run(v)                                   # the live (de-biased) tree
  stopifnot(file.copy(BR_PRE, BR_LIVE, overwrite = TRUE))
  RUNS$pre  <- dg_run(v)
}, finally = {
  if (!identical(md5(BR_LIVE), md0)) file.copy(BR_BACK, BR_LIVE, overwrite = TRUE)
  stopifnot(identical(md5(BR_LIVE), md0))                  # ASSERT the restore landed
  cat("restore verified (md5 matches the file this script started with)\n\n")
})

score <- function(r) {
  o <- ccx_prepare_obs()                                   # re-reads LIK_D14C_REP_BOMB
  unlist(ccx_loglik(r$out, o, err, luc = ccx_forcing_eluc_annual(r$F),
                    deep = r$sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(r$out, r$sp),
                    by_stream = TRUE, d14c_mid = ccx_model_d14c_slabs(r$sp)))
}

cat(sprintf("mode %s; shipped LIK_D14C_REP_BOMB = %g permil over %d-%d\n",
            CCX_MODE_CANONICAL, BR_SHIP, LIK_D14C_BOMB_WIN[1], LIK_D14C_BOMB_WIN[2]))
cat(sprintf("fitted sigma_d14c = %.2f permil (added in quadrature ON TOP of the rep term)\n\n",
            v$sigma_d14c))
cat(sprintf("%-6s %-11s %11s %11s %11s %11s\n",
            "rep", "sigma_eff", "d14c_NH", "d14c_SH", "d14c TOTAL", "ALL streams"))
RES <- list()
for (rep in BR_REPS) {
  LIK_D14C_REP_BOMB <<- rep
  o <- ccx_prepare_obs()
  a <- o$d14_nh_ann; se <- sqrt(a$sd[a$year == 1964]^2 + v$sigma_d14c^2)
  s <- lapply(RUNS, score)
  d <- s$post - s$pre
  k <- c("d14c_NH", "d14c_SH")
  RES[[as.character(rep)]] <- list(delta = d, sigma_eff_1964 = se,
                                   nh = d[["d14c_NH"]], sh = d[["d14c_SH"]],
                                   d14c = sum(d[k]), total = sum(d))
  cat(sprintf("%-6g %8.1f    %11.2f %11.2f %11.2f %11.2f\n",
              rep, se, d[["d14c_NH"]], d[["d14c_SH"]], sum(d[k]), sum(d)))
}
LIK_D14C_REP_BOMB <<- BR_SHIP          # restore the shipped value in-session

cat("\n=== READING ===\n")
b <- RES[[as.character(BR_SHIP)]]; w <- RES[["40"]]; u <- RES[["47"]]
cat(sprintf("  At the SHIPPED 25 permil the de-biasing costs %+.1f log-units.\n", b$total),
    sprintf("  Widening the bomb window to cover the largest Graven-Hua disagreement (40) leaves\n"),
    sprintf("  %+.1f; the independent-errors upper bound (47) leaves %+.1f.\n", w$total, u$total),
    sprintf("  ⇒ the penalty shrinks by only %.0f-%.0f %%. It does NOT vanish, does NOT change\n",
            100 * (1 - w$total / b$total), 100 * (1 - u$total / b$total)),
    "  sign, and stays an order of magnitude larger than any plausible restart noise.\n",
    "  ⇒ RULING 4's PENALTY IS NOT AN ARTIFACT OF AN OVER-TIGHT TARGET. The bomb window was\n",
    "  ALREADY inflated 25/3.6 = 7x over Hua's own sd before Graven was ever acquired, and\n",
    "  widening it to the full Graven-Hua spread removes only a quarter of the cost.\n",
    "  ⚠ WHY SO ROBUST: the -92.7 is dominated by the SH (-69.5), where the de-biasing acts\n",
    "  through the PRE-1963 dump -- and a level shift sustained across many years is not\n",
    "  something a per-observation sigma can absorb the way a single outlying year would be.\n",
    "  ⛔ Choosing a rep value is an OBJECTIVE CHANGE and a Marcus ruling; nothing adopts one.\n")
saveRDS(list(res = RES, reps = BR_REPS, shipped = BR_SHIP, mode = CCX_MODE_CANONICAL,
             sigma_d14c = v$sigma_d14c, date = Sys.time()), BR_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", BR_OUT))
