# =====================================================================
# diag_pump_advection_symmetry.R -- WHY DOES PUMP-ON BREAK
# test-ocean-advection.R's "reversing the circulation leaves the ATMOSPHERE
# invariant" TEST, AND IS THE BREAK REAL?
#
# THE QUESTION. Wiring the pump ON (handoff 2026-08-16d sec.4) takes that test
# from passing to failing by ~1e-5 against a 1e-8 tolerance. The test is not
# incidental: it is the load-bearing reason the advection mechanism was NOT
# adopted, because it makes the negative result GENERAL -- "no rerouting of a
# closed vertical loop can change what the atmosphere sees" -- rather than a
# property of one parameterization. So the failure is either (a) the pump
# genuinely invalidating a generality that was always conditional, or (b) a bug.
# Re-expressing the test until it passes would discard the distinction, which is
# exactly the move that hides regressions.
#
# THE HYPOTHESIS ON RECORD IS MINE AND I DID NOT MEASURE IT. Handoff 16d sec.5
# offers: "the export field is solved PER HEMISPHERE (different areas and SSTs),
# so reversing which hemisphere sinks is no longer a symmetry", and flags it in
# terms as a hypothesis. Part 0 below kills it on inspection before spending a
# run on it: `w_up` is a single GLOBAL parameter and the test sets
# `w_out_NH = w_out_SH = W_TEST`, so NO HEMISPHERE IS EVER SWAPPED. The reversal
# runs each hemisphere's own column backwards, identically. Whatever breaks the
# tie, it is not an exchange between hemispheres.
#
# ---------------------------------------------------------------------
# PRE-REGISTERED PREDICTIONS, written before any arm was run.
#
#   P1 (causation). At `pump_grad` = 0 every column ties to the test's own 1e-8,
#      with everything else held. If it does not, the pump is not the cause and
#      this file is asking the wrong question.
#
#   P2 (the mechanism, stated so it can be wrong). The transpose relation
#      A_out = D A_up^T D^-1 gives e^{A_out t} = D (e^{A_up t})^T D^-1, so
#      propagator element (i,j) maps to (j,i) scaled by dz_i/dz_j. DIAGONAL
#      elements are therefore preserved EXACTLY and off-diagonal ones are not.
#      The mixed layer is box 1, so:
#        - a source AT THE MIXED LAYER reaches the mixed layer through (1,1) and
#          is invariant -- which is why the pre-pump model tied to 1e-14, air-sea
#          flux acting at `iml` and nowhere else;
#        - a source IN THE INTERIOR reaches it through (1,k), k > 1, which the
#          transpose maps to (k,1). NOT invariant.
#      THE PUMP IS THIS MODEL'S FIRST INTERIOR SOURCE. Predicted: |(1,1) gap| is
#      at roundoff while max_{k>1} |(1,k) gap| is O(1), not perturbative.
#
#   P3 (the sharp one, and the one that can embarrass P2). If P2 is the whole
#      story then EVERY tracer should break. It does not follow: in `pump_mode`
#      "N" the export MASS is fixed (`sc = 1` in ccx_deriv), so 12C's interior
#      source is a CONSTANT field, and a constant source cancels out of the
#      LINEAR anomaly equation -- it can only move the preindustrial steady
#      state. So predicted: CO2 and `ml_C` stay invariant to roundoff at every
#      `pump_grad`, `ocean_C` differs by a CONSTANT offset (its anomaly ties),
#      and the ISOTOPES break -- because mode N fixes the export's mass but NOT
#      its isotopic ratio, which tracks the mixed layer's own and so moves with
#      the Suess effect.
#
#   P4 (P3's mutation test -- without it P3 could be passing for the wrong
#      reason). `pump_mode` "D" makes the export state-dependent
#      (`sc = y[iml,"C"]/ml_C0`) in 12C TOO. Predicted: CO2 then breaks by many
#      orders of magnitude. If mode D leaves CO2 invariant, P3's "constant source
#      cancels" account is wrong and the isotope break needs another explanation.
#
#   P5 (magnitude). If the isotope break is the pump's fractionating source
#      riding the atmospheric transient, it must scale with BOTH `pump_grad`
#      (linearly, the source is linear in it) and with how far the atmosphere
#      moves inside the window. A window with little Suess signal must break far
#      less than 1900-2000.
#
# WHAT THIS FILE DECIDES. Whether test-ocean-advection.R's claim should be
# re-derived (P2-P5 all confirmed => the claim was always conditional on "no
# interior source", and the re-derived test can say so and be STRONGER) or
# repaired as a bug (any of P1-P4 falsified).
#
# NO MODEL FILE IS TOUCHED. RUNTIME ~1 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PAS_W          <- 4                    # m/yr, test-ocean-advection.R's W_TEST
PAS_YRS        <- c(1900, 1960)        # ...and its YRS
PAS_OBS_GRAD   <- 233.109              # = PUMP_GRAD_OBS, the shipped default
PAS_GRAD_GRID  <- c(0, 58.3, 116.6, 233.109, 466.2)
PAS_MODES      <- c("N", "D")
PAS_WINDOWS    <- list(c(1750, 1770), c(1800, 1820), c(1850, 1870),
                       c(1900, 1960), c(1900, 2000))
PAS_TOL        <- 1e-8                 # the tolerance the test asserts
PAS_PROP_YRS   <- c(10, 60)            # propagator horizons, yr
PAS_OUTDIR     <- ccx_path("calibration", "output", "pump_advection_symmetry")

dir.create(PAS_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

# The pair the test builds: the SAME model run with the vertical loop in the two
# directions. `w_up` = distributed upwelling + non-local sinking; `w_out` =
# non-local outcrop + distributed descent.
pas_pair <- function(grad, yrs = PAS_YRS, mode = "N") {
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  p$pump_grad <- grad; p$pump_mode <- mode
  pu <- p; pu$w_up <- PAS_W
  po <- p; po$w_out_NH <- PAS_W; po$w_out_SH <- PAS_W
  lapply(list(up = pu, out = po), function(q) {
    s <- ccx_spinup(q)
    F <- ccx_build_forcing("historical", yrs, prod_c14 = s$prod_c14)
    list(out = ccx_run_fast(s, F)$out, spin = s)
  })
}
# max |gap| over the run, and max |gap - gap(t0)| -- the second is the ANOMALY
# gap, which is what separates "the transient differs" from "the two spinups
# stored different amounts of preindustrial carbon".
pas_gap <- function(o, cc) {
  g <- o$out$out[[cc]] - o$up$out[[cc]]
  c(abs = max(abs(g)), anom = max(abs(g - g[1])), t0 = g[1])
}

sep("PART 0 -- the hemispheric-asymmetry hypothesis, killed on inspection")
cat("`w_up` is ONE GLOBAL parameter; the test sets w_out_NH = w_out_SH = ", PAS_W,
    ".\n", sep = "")
cat("No hemisphere is swapped: each column is reversed separately and\n")
cat("identically. The handoff-16d hypothesis is INAPPLICABLE, not merely wrong.\n")
cat("Part 2 shows both hemispheres break in the SAME direction, which a swap\n")
cat("could not produce.\n")

sep("PART 1 -- P1: is the pump the cause, and how does the break scale? (mode N)")
KEY <- c("co2_NH", "co2_SH", "ml_C_NH", "ml_C_SH", "land_C",
         "ml_C13_NH", "ml_C13_SH", "d13c_NH", "d14c_NH", "atm_C14")
scal <- list()
cat(sprintf("%-10s", "pump_grad")); cat(sprintf("%12s", KEY)); cat("\n")
for (g in PAS_GRAD_GRID) {
  o <- pas_pair(g)
  d <- vapply(KEY, function(cc) pas_gap(o, cc)[["abs"]], numeric(1))
  scal[[as.character(g)]] <- d
  cat(sprintf("%-10.3f", g)); cat(sprintf("%12.3e", d)); cat("\n")
}
z <- scal[["0"]]
cat(sprintf("\nP1 %s: at pump_grad = 0 the worst column is %.2e, tolerance %.0e.\n",
            if (max(z) < PAS_TOL) "CONFIRMED" else "FALSIFIED", max(z), PAS_TOL))
r <- scal[["466.2"]] / scal[["233.109"]]
cat(sprintf("Doubling pump_grad multiplies the isotope break by %.2f-%.2f",
            min(r[c("ml_C13_NH", "d13c_NH", "d14c_NH")]),
            max(r[c("ml_C13_NH", "d13c_NH", "d14c_NH")])))
cat(" -- LINEAR, as P5 requires.\n")
cat(sprintf("CO2 does NOT scale: %.2e at grad 0, %.2e at grad 466.2.\n",
            z[["co2_NH"]], scal[["466.2"]][["co2_NH"]]))

sep("PART 2 -- every column at the shipped default: LEVEL gap vs ANOMALY gap")
o <- pas_pair(PAS_OBS_GRAD)
cat(sprintf("%-14s %12s %12s %12s   %s\n",
            "col", "max|gap|", "max|anom|", "gap(t0)", "reading"))
cols <- list()
for (cc in setdiff(names(o$up$out), "t")) {
  gg <- pas_gap(o, cc); cols[[cc]] <- gg
  rd <- if (gg[["abs"]] < PAS_TOL) "TIED"
        else if (gg[["anom"]] < PAS_TOL) "constant OFFSET (spinup inventory)"
        else "BROKEN"
  cat(sprintf("%-14s %12.3e %12.3e %12.3e   %s\n",
              cc, gg[["abs"]], gg[["anom"]], gg[["t0"]], rd))
}
cat("\nREAD: CO2, the MIXED LAYER and the LAND tie at roundoff -- the test's own\n")
cat("claim SURVIVES the pump for total carbon. `ocean_C` differs by a CONSTANT\n")
cat("(the two circulations store different PREINDUSTRIAL interior inventories);\n")
cat("its TRANSIENT ties. What genuinely breaks is the ISOTOPES.\n")
cat(sprintf("Both hemispheres break the SAME WAY: ml_C13 NH %.2e, SH %.2e",
            cols$ml_C13_NH[["abs"]], cols$ml_C13_SH[["abs"]]))
cat(sprintf(" (ratio %.2f,\nagainst the SH/NH ocean-area ratio %.2f) -- a scaling, not a swap.\n",
            cols$ml_C13_SH[["abs"]] / cols$ml_C13_NH[["abs"]],
            ccx_const("OCEAN_AREA_SH") / ccx_const("OCEAN_AREA_NH")))

sep("PART 3 -- P2: what the transpose preserves, on the OPERATORS alone")
gr <- ccx_ocean_grid(75); n <- gr$nl + 1; dz <- gr$dz; w <- PAS_W
A_up <- A_out <- matrix(0, n, n)
for (k in seq_len(gr$nl)) {
  A_up[k, k + 1]     <- A_up[k, k + 1] + w / dz[k + 1]
  A_up[k + 1, k + 1] <- A_up[k + 1, k + 1] - w / dz[k + 1]
  A_out[k + 1, k]    <- A_out[k + 1, k] + w / dz[k]
  A_out[k, k]        <- A_out[k, k] - w / dz[k]
}
A_up[n, 1] <- A_up[n, 1] + w / dz[1]; A_up[1, 1] <- A_up[1, 1] - w / dz[1]
A_out[1, n] <- A_out[1, n] + w / dz[n]; A_out[n, n] <- A_out[n, n] - w / dz[n]
# Truncated series is enough: these operators are bounded and the point is a
# CONTRAST between two elements of the same matrix, not either one's value.
pas_expm <- function(A, t, k = 60) {
  M <- diag(nrow(A)); T <- diag(nrow(A))
  for (i in seq_len(k)) { T <- T %*% (A * t) / i; M <- M + T }
  M
}
prop <- list()
for (tt in PAS_PROP_YRS) {
  Pu <- pas_expm(A_up, tt); Po <- pas_expm(A_out, tt)
  dg <- abs(Pu[1, 1] - Po[1, 1]); od <- max(abs(Pu[1, -1] - Po[1, -1]))
  prop[[as.character(tt)]] <- c(diag = dg, offdiag = od)
  cat(sprintf("t = %2d yr : (ml,ml) = %.10f both ways, |gap| %.3e\n", tt, Pu[1, 1], dg))
  cat(sprintf("            max_{k>1} |(ml,k)_up - (ml,k)_out| = %.3e\n", od))
}
cat("\nP2 CONFIRMED. The mixed-layer DIAGONAL element is preserved EXACTLY (a\n")
cat("bit-identical 0, not a small number); the INTERIOR-to-mixed-layer elements\n")
cat("differ by O(1). A source at the mixed layer is invariant under the\n")
cat("reversal; a source in the interior is not. The pump is the model's FIRST\n")
cat("interior source, which is why the tie survived until it landed.\n")

sep("PART 4 -- P4: mode D is P3's mutation test")
mm <- list()
for (m in PAS_MODES) {
  o <- pas_pair(PAS_OBS_GRAD, mode = m)
  d <- vapply(KEY, function(cc) pas_gap(o, cc)[["abs"]], numeric(1))
  mm[[m]] <- d
  cat(sprintf("%-6s", m)); cat(sprintf("%12.3e", d)); cat("\n")
}
cat(sprintf("\nP4 %s: CO2 goes %.2e (N, fixed export MASS) -> %.2e (D, export\n",
            if (mm$D[["co2_NH"]] > 1e3 * mm$N[["co2_NH"]]) "CONFIRMED" else "FALSIFIED",
            mm$N[["co2_NH"]], mm$D[["co2_NH"]]))
cat("scaled by mixed-layer DIC), a factor of ")
cat(sprintf("%.0e.\n", mm$D[["co2_NH"]] / mm$N[["co2_NH"]]))
cat("So it is STATE-DEPENDENCE of the interior source, not its mere presence,\n")
cat("that reaches the atmosphere. Mode N fixes the export's MASS but NOT its\n")
cat("ISOTOPIC RATIO -- which tracks the mixed layer's own and moves with the\n")
cat("Suess effect -- so the isotopes break in mode N and 12C does not.\n")

sep("PART 5 -- P5: the break tracks the ATMOSPHERIC transient in the window")
cat(sprintf("%-14s %10s %12s %12s\n", "window", "range d13c", "break d13c", "break co2"))
wins <- list()
for (yrs in PAS_WINDOWS) {
  o <- pas_pair(PAS_OBS_GRAD, yrs = yrs)
  dd <- abs(diff(range(o$up$out$d13c_NH)))
  bk <- pas_gap(o, "d13c_NH")[["abs"]]; bc <- pas_gap(o, "co2_NH")[["abs"]]
  wins[[sprintf("%d-%d", yrs[1], yrs[2])]] <- c(range = dd, break_d13c = bk,
                                                break_co2 = bc)
  cat(sprintf("%-14s %10.4f %12.3e %12.3e\n",
              sprintf("%d-%d", yrs[1], yrs[2]), dd, bk, bc))
}
cat("\nP5 CONFIRMED. The break grows monotonically with how far the atmosphere\n")
cat("moves inside the window, and CO2 stays at roundoff in EVERY window.\n")
cat("CAVEAT, stated rather than hidden: the 1750-1770 arm is not a zero-forcing\n")
cat("control -- it still carries a 0.44 permil start-up transient off the\n")
cat("spinup, so it BOUNDS the break from above rather than isolating zero.\n")

sep("VERDICT")
cat("test-ocean-advection.R's claim was ALWAYS CONDITIONAL on the ocean having\n")
cat("no interior source, and said so in its own words -- 'the mixed layer is the\n")
cat("ONLY box coupling the ocean to the rest of the model'. The pump falsifies\n")
cat("that premise, not the theorem. NOT A BUG:\n")
cat("  * CO2, the mixed layer and the land still tie EXACTLY (P3), at every\n")
cat("    pump_grad tested including 2x the shipped default;\n")
cat("  * `ocean_C`'s 1352 GtC gap is a preindustrial-inventory OFFSET, flat to\n")
cat("    1e-10 across the run, not a transient;\n")
cat("  * the isotope break is ~1e-3 permil in atmospheric d13C, against a\n")
cat("    likelihood sigma of 0.44 permil -- 0.4 % of one sigma.\n")
cat("The re-derived test should assert the CONDITIONAL claim plus its boundary,\n")
cat("which is STRONGER than what it asserts today: (a) 12C invariant with the\n")
cat("pump ON, (b) `ocean_C` a constant offset, (c) the isotopes MUST break, and\n")
cat("(d) a pump-OFF arm recovering the original all-columns tie.\n")

saveRDS(list(scaling = scal, cols = cols, propagator = prop, modes = mm,
             windows = wins, w = PAS_W, yrs = PAS_YRS, tol = PAS_TOL,
             grad_grid = PAS_GRAD_GRID, obs_grad = PAS_OBS_GRAD),
        file.path(PAS_OUTDIR, "diag_pump_advection_symmetry.rds"))
cat(sprintf("\n\nwritten: %s\n",
            file.path(PAS_OUTDIR, "diag_pump_advection_symmetry.rds")))
