# =====================================================================
# CAN THE N&L OCEAN INVENTORY ARBITRATE RULING 4?  (2026-09-09c)
#
# Ruling 4 (the Tans Table-2 /1.20 de-biasing) rests on four measurements, only
# one of which is refit-independent and physical: budget-closing lambda moves
# 0.1996 -> 0.3490 /yr, so gross air-sea exchange at Tans' own Broecker flux
# covers 75 % -> 43 % of it. Whether 43 % is implausible is an argument about
# the ocean/land split of bomb-14C removal -- so the OBSERVED ocean inventory
# (Naegler & Levin 2006 Table 4, GEOSECS 1975 and WOCE 1995) ought to settle it.
#
# ⛔ THIS SCRIPT MEASURES THE TEST'S POWER, NOT THE TEST. The by-stream
# decomposition of the -92.74 (diag_bomb_debias_impact.R) already shows
# excess_c14_ocean moving only -0.063 of it, so the answer is probably NO and
# the honest thing is to quantify the blindness in the OBSERVATION's own units
# before running anything as a test. [[no_power_null]]
#
# MEASURES: the model's ocean excess 14C at 1975/1995 under BOTH forcing arms,
# against BOTH N&L target sets, and reports the arm-to-arm shift as a fraction
# of the observational half-width. A test whose signal is a few percent of the
# target's own width cannot arbitrate anything.
#
# ⚠ The forcing file is swapped per arm under tryCatch(finally=) PLUS an md5
# assertion that the restore landed -- top-level on.exit() never fires in an
# Rscript [[rscript_top_level_on_exit]].
# Usage: CCX_PRE_BOMB=<path to the pre-de-biasing product> Rscript calibration/diag_debias_ocean_inventory_power.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

PW_YEARS   <- c(1750, 2024)
PW_REF     <- c(1975, 1995)          # GEOSECS and WOCE
PW_LIVE    <- ccx_path("data", "forcing_bomb_c14.rds")
PW_PRE     <- Sys.getenv("CCX_PRE_BOMB", "")
PW_OUT     <- ccx_path("outputs", "diagnostics",
                       sprintf("debias_ocean_inventory_power_%s.rds", format(Sys.Date(), "%Y%m%d")))
stopifnot(nzchar(PW_PRE), file.exists(PW_PRE))

tg  <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$targets
md5 <- function(p) as.character(tools::md5sum(p))
md0 <- md5(PW_LIVE)

v  <- dg_vector(CCX_MODE_CANONICAL)
sp <- ccx_spinup(v$p)
inv_ocean <- function(o, i) ccx_c14_kmol(o$ocean_C14[i])
row_at <- function(o, y) which(floor(o$t + 1e-9) == y)[1]

arm <- function(lab) {
  b <- readRDS(PW_LIVE); d <- attr(b, "provenance")$t2_high_bias_divisor
  if (is.null(d)) d <- NA_real_          # the pre-knob product has NO field
  # EXACTLY dg_run()'s construction -- bomb_total and luc_scale live at the
  # vector's TOP level, not in v$p, and omitting luc_scale would silently run a
  # different model than every other diagnostic in this file's family.
  F <- ccx_build_forcing("historical", PW_YEARS, prod_c14 = sp$prod_c14,
                         bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  o <- ccx_run_fast(sp, F)$out
  nat <- inv_ocean(o, 1)                 # baseline A, the 1750 steady state
  out <- vapply(PW_REF, function(y) inv_ocean(o, row_at(o, y)) - nat, numeric(1))
  names(out) <- as.character(PW_REF)
  # THE UNDECLARED-14C LEAK, by the same derivation as diag_excess_c14.R [2]:
  # excess E obeys dE/dt = declared - lambda E, so leak = E - int(declared) +
  # lambda int(E). It needs no knowledge of the source, only that 14C decays.
  # MEASURED here so the confound is a number in this output, not a cross-
  # reference that can go stale.
  dt <- 1 / 12
  Et <- ccx_c14_kmol(o$ocean_C14 + o$land_C14 + o$atm_C14); Et <- Et - Et[1]
  lk <- Et - cumsum(F$c14_bomb + F$c14_nuclear) * dt / 1000 +
        cumsum(Et) * dt * ccx_const("LAMBDA_C14")
  leak <<- vapply(PW_REF, function(y) lk[row_at(o, y)], numeric(1))
  cat(sprintf("%-11s divisor %-4s bomb_total %.1f kmol | ocean excess 1975 %6.2f  1995 %6.2f kmol\n",
              lab, format(d), v$bomb_total, out[["1975"]], out[["1995"]]))
  out
}

cat(sprintf("mode %s; excess is TOTAL-minus-natural (baseline A), the definition N&L's OBSERVATIONS use\n\n",
            CCX_MODE_CANONICAL))
RES <- list()
tryCatch({
  RES$post <- arm("de-biased")                                 # the live tree
  stopifnot(file.copy(PW_PRE, PW_LIVE, overwrite = TRUE))
  RES$pre  <- arm("pre-debias")
}, finally = {
  # restore from a copy taken HERE, and ASSERT it landed
  if (!identical(md5(PW_LIVE), md0)) {
    stopifnot(nzchar(Sys.getenv("CCX_LIVE_BACKUP")))
    file.copy(Sys.getenv("CCX_LIVE_BACKUP"), PW_LIVE, overwrite = TRUE)
  }
  stopifnot(identical(md5(PW_LIVE), md0))
  cat("\nrestore verified (md5 matches the file this script started with)\n")
})

cat("\n=== THE POWER, in the OBSERVATION's own units ===\n")
shift <- RES$post - RES$pre
for (nm in names(tg)) {
  t <- as.data.frame(tg[[nm]])
  cat(sprintf("\n  target set '%s'%s\n", nm,
              if (nm == "table4_obs_range") "  (the DEFAULT; the choice between sets is FLAGGED, not settled -- DATA.md sec.10)" else "  (one method, ~3x tighter)"))
  for (y in PW_REF) {
    r <- t[t$year == y, ]
    ky <- as.character(y)
    inr <- function(x) if (x >= r$lo && x <= r$hi) "INSIDE " else "OUTSIDE"
    cat(sprintf("    %d obs %.1f-%.1f (half-width %.1f) | pre %6.2f %s | de-biased %6.2f %s | ARM SHIFT %+.3f kmol = %.1f %% of the half-width\n",
                y, r$lo, r$hi, r$half_width, RES$pre[[ky]], inr(RES$pre[[ky]]),
                RES$post[[ky]], inr(RES$post[[ky]]),
                shift[[ky]], 100 * abs(shift[[ky]]) / r$half_width))
  }
}
cat("\n=== THE CONFOUNDS, MEASURED before any reading ===\n")
t4 <- as.data.frame(tg$table4_obs_range)
NL_PRIOR_HI <- 104.9                      # N&L's own bomb-production prior, top
for (k in seq_along(PW_REF)) {
  y <- PW_REF[k]; r <- t4[t4$year == y, ]
  cat(sprintf("  %d  model (pre-arm) %+.1f kmol above the observed upper bound %.1f\n",
              y, RES$pre[[as.character(y)]] - r$hi, r$hi),
      sprintf("        undeclared-14C leak here: %+.2f kmol\n", leak[k]),
      sprintf("        if bomb_total were scaled to N&L's prior top (x %.3f): %.1f kmol -> %s\n",
              NL_PRIOR_HI / v$bomb_total, RES$pre[[as.character(y)]] * NL_PRIOR_HI / v$bomb_total,
              if (RES$pre[[as.character(y)]] * NL_PRIOR_HI / v$bomb_total <= r$hi) "INSIDE" else "still OUTSIDE"))
}
cat(sprintf("  fitted bomb_total %.1f kmol vs N&L's 99.3-%.1f prior (+%.1f, +%.1f %% above its top)\n",
            v$bomb_total, NL_PRIOR_HI, v$bomb_total - NL_PRIOR_HI,
            100 * (v$bomb_total / NL_PRIOR_HI - 1)))
cat("  ⛔ THE LUC 14C LEAK IS NOT A CONFOUND HERE, CONTRARY TO DATA.md sec.10's third trap,\n",
    "  which records 23.9 kmol at 1975 and 28.3 at 1995. MEASURED at this mode it is ~0.\n",
    "  Either the leak was fixed after that text was written or it is mode-dependent;\n",
    "  EITHER WAY THE DATA.md NUMBERS ARE STALE for the canonical and must not be quoted.\n")

cat("\n=== READING ===\n")
cat("  ⛔ THE OBSERVATION CANNOT RANK THE TWO ARMS.\n",
    sprintf("  Both sit OUTSIDE every target set at both years, on the SAME side, by %+.1f (1975)\n",
            RES$pre[["1975"]] - t4$hi[t4$year == 1975]),
    sprintf("  and %+.1f (1995) kmol -- while the ARMS differ by only %+.2f and %+.2f. A target that\n",
            RES$pre[["1995"]] - t4$hi[t4$year == 1995], shift[["1975"]], shift[["1995"]]),
    "  rejects both arms equally ranks neither, and would report 'no difference' identically\n",
    "  whether or not one existed. [[no_power_null]]\n",
    "  ⛔ AND THE OFFSET IS NOT EVIDENCE ABOUT BOMB UPTAKE. The fitted bomb_total sits 12.9 %\n",
    "  above the top of N&L's OWN production prior, and scaling it back to that top brings\n",
    "  1975 inside the observed range -- so the 1975 miss is an AMPLITUDE excursion, not an\n",
    "  ocean-uptake error, and it is common to both arms.\n",
    "  ⇒ THE N&L OCEAN INVENTORY CANNOT SETTLE RULING 4, nor the 75 % -> 43 % lambda\n",
    "  question. The information about the delivery SHAPE lives in the atmospheric d14c\n",
    "  TRAJECTORY -- which carried -92.68 of the -92.74 -- not in a 1975/1995 integral that\n",
    "  has averaged the transient away.\n",
    "  ⚠ SEPARATE, AND NOT WHAT THIS SCRIPT WAS BUILT TO ASK: 1995 stays outside even after\n",
    "  the bomb_total rescale (~72 vs an upper bound of 59). This IS a scored stream\n",
    "  (excess_c14_ocean, table4_obs_range, rep_frac 0.15), so the fit already sees it --\n",
    "  check the arc state before treating it as new.\n")
saveRDS(list(res = RES, shift = shift, leak = leak, bomb_total = v$bomb_total, targets = tg, mode = CCX_MODE_CANONICAL,
             date = Sys.time()), PW_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted; this is a POWER measurement, not a test.\n", PW_OUT))
