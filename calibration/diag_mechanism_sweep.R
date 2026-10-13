# =====================================================================
# diag_mechanism_sweep.R -- every What-if switch combination at the canonical (2026-10-13 g)
#
# WHY. test-mechanisms.R's POWER check asserts that the OLD construction (the ocean switch
# acting INSIDE the spin-up) still fails "singular" on the minimal pair
# warming_feedback + ocean_sink -- else the test of the fix passes vacuously. At hilda31w
# that pair CONVERGES (suite ledger 10-13 g), and the test's own comment says: re-measure
# before deleting it. The 10-11 (a) sweep that found the crash (16 of 127 at hilda29e) was
# run ad hoc; this is it as a driver.
#
# WHAT. At the canonical (the test's own construction: pins applied, structure base, the
# label's ENSO index / AOD mode / nuclear 14C share on the forcing):
#   1. OLD construction, the 64 combinations WITH ocean_sink: spin up with every switch
#      applied (sp_fn(ccx_apply_mechanisms(p, F0, off)$p)); record error / warning / ok.
#   2. NEW construction (the app's, ccx_mechanism_spinup + ccx_run_fast), all 127: spin up,
#      run 1750-2024, require finite CO2 in both hemispheres.
# No RNG. Output: outputs/diagnostics/mechanism_sweep_<date>_<mode>.{log,rds} (provenance in the rds).
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

MS_MODE  <- CCX_MODE_CANONICAL
MS_YEARS <- c(1750, 2024)
MS_DATE  <- format(Sys.Date(), "%Y%m%d")
MS_OUT   <- file.path("outputs", "diagnostics", sprintf("mechanism_sweep_%s_%s", MS_DATE, MS_MODE))

md <- readRDS(ccx_mode_file(MS_MODE))
rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
p  <- ccx_overlay_par(bp, md$par_mode)
sp_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
F0 <- suppressWarnings(ccx_build_forcing("historical", MS_YEARS, prod_c14 = 0,
        bomb_total_kmol = md$par_mode$bomb_total, luc_scale = md$par_mode$luc_scale,
        enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p), nuc_share = ccx_nuc_share_of(p)))

mech <- names(CCX_MECHANISMS)
combos <- unlist(lapply(seq_along(mech), function(k) combn(mech, k, simplify = FALSE)), recursive = FALSE)
stopifnot(length(combos) == 2^length(mech) - 1L)

classify <- function(expr) {
  w <- character(0)
  r <- tryCatch(withCallingHandlers(expr, warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") }),
                error = function(e) structure(conditionMessage(e), class = "ms_err"))
  if (inherits(r, "ms_err")) list(status = "error", msg = substr(unclass(r), 1, 160), value = NULL)
  else list(status = if (length(w)) "warning" else "ok", msg = if (length(w)) substr(w[1], 1, 160) else "", value = r)
}

cat(sprintf("=== mechanism sweep at %s (%s), %d combinations, %s ===\n", MS_MODE, ccx_mode_struct(md), length(combos), ccx_git_stamp()))
old <- do.call(rbind, lapply(Filter(function(o) "ocean_sink" %in% o, combos), function(off) {
  r <- classify(sp_fn(ccx_apply_mechanisms(p, F0, off)$p))
  data.frame(off = paste(off, collapse = "+"), n = length(off), status = r$status, msg = r$msg)
}))
cat(sprintf("\n1. OLD construction (switch inside the spin-up), %d combinations with ocean_sink: %s\n",
            nrow(old), paste(names(table(old$status)), table(old$status), sep = " ", collapse = ", ")))
print(old[old$status != "ok", c("off", "status", "msg")], row.names = FALSE)

new <- do.call(rbind, lapply(combos, function(off) {
  r <- classify({
    ms <- ccx_mechanism_spinup(p, F0, off, sp_fn)
    FF <- ms$m$F; FF$c14_cosmo <- ms$spin$prod_c14
    out <- ccx_run_fast(ms$spin, FF)$out
    if (!(all(is.finite(out$co2_NH)) && all(is.finite(out$co2_SH)))) stop("non-finite CO2")
    out
  })
  data.frame(off = paste(off, collapse = "+"), n = length(off), status = r$status, msg = r$msg)
}))
cat(sprintf("\n2. NEW construction (the app's), all %d: %s\n", nrow(new),
            paste(names(table(new$status)), table(new$status), sep = " ", collapse = ", ")))
print(new[new$status != "ok", c("off", "status", "msg")], row.names = FALSE)

saveRDS(list(old = old, new = new,
             provenance = list(driver = "calibration/diag_mechanism_sweep.R", commit = ccx_git_stamp(), date = MS_DATE,
                               mode = MS_MODE, mode_md5 = unname(tools::md5sum(ccx_mode_file(MS_MODE))),
                               struct = ccx_mode_struct(md), years = MS_YEARS, rng = "none",
                               forcing = "historical, the label's enso_index / aod_mode / nuc_share")),
        paste0(MS_OUT, ".rds"))
cat("\nwrote", paste0(MS_OUT, ".rds"), "\n")
