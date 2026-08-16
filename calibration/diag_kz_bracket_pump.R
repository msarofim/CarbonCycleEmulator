# =====================================================================
# diag_kz_bracket_pump.R -- RE-BISECT the `kz` bracket with the pump ON, before
# spending a two-arm refit on the inherited one.
#
# WHY THIS RUNS FIRST. `CCX_PARAM_TABLE$kz` is hard-bounded to [3830, 6200], and
# calibrate.R records exactly how those numbers were obtained: bisection of the
# kz -> deep-D14C map against an observed [-200, -150] permil bracket, AT THE
# DEFAULT PARAMETERS, ON A MODEL WITH NO PUMP. Two things make that stale rather
# than merely old:
#
#   1. The pump MOVES THE VERY ROW the bisection was done on. DESIGN sec.5.2h
#      measured it making deep water older at every `kz` (at 6200 it moves the
#      deep-D14C row +1.60 -> +1.15, toward target). A bracket bisected without
#      it is bisected on a different map.
#   2. THE BOUND IS BINDING, NOT DECORATIVE. sec.5.2h P2: `kz` pins to the
#      bracket's TOP with the pump both off and on. So whatever this bracket's
#      top is, that is where the refit's `kz` will sit -- the bracket is not a
#      guard rail here, it is the answer.
#
# calibrate.R's own comment asks for exactly this ("Re-bisect if OCEAN_DEPTH, the
# grid, or the observed bracket changes -- these are measured numbers, not
# settings"), and handoff 16d sec.7 item 6 carries it as an open item.
#
# WHAT THIS DECIDES, AND WHAT IT DOES NOT. It decides nothing: moving the bounds
# is Marcus's call and calibrate.R says so in terms ("neither is a reason to move
# the bounds by hand ahead of the refit"). This measures the SIZE of the staleness
# so the call can be taken on numbers. It matters most if the bracket moves by
# more than the refit's own `kz` uncertainty; if it barely moves, the inherited
# bracket is fine and the two-arm refit can proceed on it unchanged.
#
# NOTE THE COMPARISON IS LIKE-FOR-LIKE BY CONSTRUCTION. The original bisection
# used `d14c_deep_ocean` -- the bottom THREE boxes -- against [-200, -150], so
# that is the primary here. The BOTTOM BOX is reported alongside because it is
# what the `d14c_deep_ocean` LIKELIHOOD TERM actually scores, and calibrate.R
# already flags the two as 16.7 permil apart. Reporting one without the other is
# how that gap got missed the first time.
#
# RUNTIME ~3 min: spinups only, no transient runs.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

KBP_DEEP_OBS  <- c(-200, -150)      # the observed bracket the bisection targets
KBP_INCUMBENT <- c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi)
KBP_SEARCH    <- c(1500, 20000)     # bisection search range, m2/yr
KBP_TOL       <- 0.5                # m2/yr
KBP_GRID      <- c(2000, 3000, 3830, 5000, 6200, 8000, 10686)
KBP_MODES     <- c("N", "D")        # BOTH arms -- the refit is running both
KBP_OUTDIR    <- ccx_path("calibration", "output", "kz_bracket_pump")

dir.create(KBP_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# The two deep-D14C readouts, at default parameters with `kz` and the pump set.
kbp_deep <- function(kz, grad, mode = "N") {
  p <- ccx_default_params(); p$kz <- kz
  p$pump_grad <- grad; p$pump_mode <- mode
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp)) return(c(three = NA_real_, bottom = NA_real_))
  c(three  = sp$diagnostics$d14c_deep_ocean,
    bottom = sp$diagnostics$d14c_bottom_box)
}
# Plain bisection on a map that is monotone in `kz` (more mixing -> younger
# deep water). Monotonicity is CHECKED on the grid below rather than assumed --
# if it fails the bisection is meaningless and the script says so.
kbp_solve <- function(target, grad, mode = "N", which = "three") {
  lo <- KBP_SEARCH[1]; hi <- KBP_SEARCH[2]
  f <- function(k) kbp_deep(k, grad, mode)[[which]] - target
  flo <- f(lo); fhi <- f(hi)
  if (!is.finite(flo) || !is.finite(fhi) || flo * fhi > 0) return(NA_real_)
  while (hi - lo > KBP_TOL) {
    mid <- 0.5 * (lo + hi); fm <- f(mid)
    if (!is.finite(fm)) return(NA_real_)
    if (flo * fm <= 0) { hi <- mid; fhi <- fm } else { lo <- mid; flo <- fm }
  }
  0.5 * (lo + hi)
}

OBS_GRAD <- ccx_const("PUMP_GRAD_OBS")

sep("PART 1 -- the kz -> deep-D14C map, pump OFF vs ON")
cat(sprintf("%8s | %19s | %19s | %19s\n", "kz",
            "OFF (3-box/bottom)", "ON mode N", "ON mode D"))
mono <- list(off = numeric(0), N = numeric(0), D = numeric(0))
for (k in KBP_GRID) {
  a <- kbp_deep(k, 0)
  b <- kbp_deep(k, OBS_GRAD, "N")
  d <- kbp_deep(k, OBS_GRAD, "D")
  mono$off <- c(mono$off, a[["three"]]); mono$N <- c(mono$N, b[["three"]])
  mono$D <- c(mono$D, d[["three"]])
  cat(sprintf("%8.0f | %8.1f /%8.1f | %8.1f /%8.1f | %8.1f /%8.1f\n",
              k, a[["three"]], a[["bottom"]], b[["three"]], b[["bottom"]],
              d[["three"]], d[["bottom"]]))
}
ok_mono <- all(vapply(mono, function(v) all(diff(v) > 0), logical(1)))
cat(sprintf("\nmonotone in kz on this grid (required for the bisection): %s\n",
            if (ok_mono) "YES" else "NO -- the bisection below is NOT valid"))

sep("PART 2 -- the re-bisected bracket")
res <- list()
cat(sprintf("%-22s %10s %10s %10s %10s\n",
            "arm", "lo(-200)", "hi(-150)", "d lo", "d hi"))
for (lab in c("OFF", KBP_MODES)) {
  gr <- if (lab == "OFF") 0 else OBS_GRAD
  md <- if (lab == "OFF") "N" else lab
  lo <- kbp_solve(KBP_DEEP_OBS[1], gr, md)
  hi <- kbp_solve(KBP_DEEP_OBS[2], gr, md)
  res[[lab]] <- c(lo = lo, hi = hi)
  cat(sprintf("%-22s %10.1f %10.1f %+10.1f %+10.1f\n",
              paste0("pump ", lab), lo, hi,
              lo - KBP_INCUMBENT[1], hi - KBP_INCUMBENT[2]))
}
cat(sprintf("\nincumbent (shipped)    %10.1f %10.1f\n",
            KBP_INCUMBENT[1], KBP_INCUMBENT[2]))
cat("\nThe OFF row is the CONTROL: it should reproduce the shipped bracket, and\n")
cat("if it does not, the map has moved for some reason OTHER than the pump and\n")
cat("that is the finding rather than anything about the pump.\n")

sep("PART 3 -- the same bracket expressed on the BOTTOM BOX")
cat("...which is the layer the `d14c_deep_ocean` likelihood term scores.\n")
cat("calibrate.R already records the incumbent as -220.4 / -163.5 there.\n\n")
cat(sprintf("%-22s %10s %10s\n", "arm", "at lo", "at hi"))
for (lab in names(res)) {
  gr <- if (lab == "OFF") 0 else OBS_GRAD
  md <- if (lab == "OFF") "N" else lab
  bl <- kbp_deep(res[[lab]][["lo"]], gr, md)[["bottom"]]
  bh <- kbp_deep(res[[lab]][["hi"]], gr, md)[["bottom"]]
  cat(sprintf("%-22s %10.1f %10.1f\n", paste0("pump ", lab), bl, bh))
}

sep("VERDICT")
dhi_N <- res$N[["hi"]] - KBP_INCUMBENT[2]
cat(sprintf("The bracket's TOP is what matters -- sec.5.2h P2 measured kz pinning\n"))
cat(sprintf("there with the pump both off and on, so the top IS the refit's kz.\n"))
cat(sprintf("Mode N moves it by %+.1f m2/yr (%.1f %%).\n",
            dhi_N, 100 * dhi_N / KBP_INCUMBENT[2]))
cat("Read that against the refit's own kz uncertainty before deciding whether\n")
cat("the inherited bracket is fit to run the two-arm refit on. THIS SCRIPT\n")
cat("DECIDES NOTHING -- moving the bounds is Marcus's call, and calibrate.R says\n")
cat("so in terms.\n")

saveRDS(list(map = mono, grid = KBP_GRID, brackets = res,
             incumbent = KBP_INCUMBENT, deep_obs = KBP_DEEP_OBS,
             monotone = ok_mono, obs_grad = OBS_GRAD),
        file.path(KBP_OUTDIR, "diag_kz_bracket_pump.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(KBP_OUTDIR, "diag_kz_bracket_pump.rds")))
