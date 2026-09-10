# =====================================================================
# diag_periodic_spinup_adoption.R -- THE THREE CHECKS THE ADOPTION RULING NEEDS.
#
# `notes/handoff_2026-09-09w_rulings_taken.md` sec.6 leaves ONE ruling owed and
# it GATES THE REFIT: should the PERIODIC spinup become **the OBJECTIVE's**
# spinup? Marcus ruled *build it*; adoption is a further step. The handoff lists
# three things to CHECK FIRST, and this script measures all three. It rules
# nothing.
#
#   CHECK 1  COST, inside `ccx_make_logpost()` -- not in a standalone
#            diagnostic. Priced against the LAST REFIT'S OWN `n_eval`/`minutes`
#            off the mode file, so the Torch figure is an extrapolation of a
#            measured run rather than a guess ⇒ [[eta_in_days_is_not_a_slow_run]].
#   CHECK 2  IS IT A NO-OP AT `seas_ml = 0`? The handoff expects BIT-IDENTICAL,
#            "or every column-era result moves".
#            ⛔⛔ IT CANNOT BE, AND THE REASON IS STRUCTURAL, NOT A BUG:
#            `ccx_spinup()` zeroes THREE seasonal paths in its `p0`
#            (`seas_amp_NH`, `seas_amp_SH`, `seas_drivers`) and `seas_ml` is a
#            FOURTH. At the canonical mode the first three are 12, 2 and 1 -- ON.
#            So at `seas_ml = 0` the model still has a substantial seasonal cycle
#            and the aseasonal fixed point is still not a point on its orbit.
#            The bit-identity expectation names `seas_ml` where the code zeroes
#            four things ⇒ [[verify_the_quantity_not_the_word]]. What is MEASURED
#            here is therefore the SIZE of the move, not its presence.
#   CHECK 3  the periodic object's `$diagnostics` -- fixed 09-09x by routing both
#            spinups through `ccx_spinup_diagnostics()`; re-asserted here.
#
# ⛔ NO INVENTED THRESHOLDS. Check 2's comparator is the objective's OWN
# likelihood at the canonical mode, and the reading is reported as a SIGNED
# per-stream shift with both totals, never as a pass/fail
# ⇒ [[threshold_from_obs_or_law]], [[compare_gaps_not_absolute_logposts]].
#
# Usage: Rscript calibration/diag_periodic_spinup_adoption.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
# `ccx_periodic_spinup()` lives in `R/periodic_spinup.R` since its adoption
# 09-09x and is sourced by the R/ bootstrap above -- no second copy.

# ---- named constants: every label and filename derives from these ----
PA_TAG      <- "20260909x"
PA_OUT      <- ccx_path("outputs", "diagnostics", paste0("periodic_adoption_", PA_TAG, ".rds"))
PA_LOG      <- sub("[.]rds$", ".log", PA_OUT)
PA_N_TIME   <- 3L        # repeats per timing arm
PA_STREAM_N <- 8L        # streams listed in the shift table
PA_SEAS_ZEROED <- c("seas_amp_NH", "seas_amp_SH", "seas_drivers")  # what p0 kills

dir.create(dirname(PA_OUT), recursive = TRUE, showWarnings = FALSE)
con <- file(PA_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

md    <- readRDS(ccx_mode_file())
base  <- ccx_mode_base(md)
p_mode <- ccx_overlay_par(base, ccx_mode_params(md))

say("PERIODIC SPINUP -- ADOPTION CHECKS (cost, the seas_ml = 0 no-op, diagnostics)")
say("mode %s | h_ml %.3f | seas_ml %d", CCX_MODE_CANONICAL, p_mode$h_ml, p_mode$seas_ml)
say("stored logpost %.6f  (STALE by the 09-09w prior shift -- compare on LIKELIHOOD)", md$logpost)

# ⚠ ONE timing helper, and it WARMS FIRST. The 09-09x first cut timed the
# periodic solve ONCE, cold, and compared it against a WARM per-evaluation
# average -- which printed "the solve alone was 130 % of the evaluation", an
# impossibility that is the tell of two different quantities wearing one label
# ⇒ [[verify_the_quantity_not_the_word]]. Everything timed below goes through here.
tt <- function(f, n = PA_N_TIME) {
  f()                                     # warm the caches once, untimed
  t <- Sys.time(); for (i in seq_len(n)) f()
  as.numeric(difftime(Sys.time(), t, units = "secs")) / n
}

# =====================================================================
say("\n== CHECK 2 (first, because it decides what CHECK 1 is even pricing) ==")
say("What `ccx_spinup()` zeroes in its p0, at THIS mode:")
for (n in PA_SEAS_ZEROED) say("  %-14s = %s   (zeroed in p0)", n, format(p_mode[[n]]))
say("  %-14s = %s   (zeroed in p0 -- and the only one the handoff names)", "seas_ml", format(p_mode$seas_ml))
n_on <- sum(vapply(PA_SEAS_ZEROED, function(n) p_mode[[n]] != 0, logical(1)))
say("  ⇒ %d of the 3 OTHER seasonal paths are ON at seas_ml = 0.", n_on)
say("  ⇒ the periodic solve at seas_ml = 0 is NOT the same problem as the")
say("    aseasonal one, so bit-identity is structurally unavailable. Measure the size.")

sp_ase <- ccx_spinup(p_mode)
sp_per <- ccx_periodic_spinup(p_mode, seed = sp_ase, verbose = FALSE)
# WARM, and seeded -- so it is the INCREMENT over the aseasonal spinup, which is
# what adoption actually adds to an evaluation.
t_per_solve <- tt(function() ccx_periodic_spinup(p_mode, seed = sp_ase, verbose = FALSE))
t_ase_solve <- tt(function() ccx_spinup(p_mode))
say("\nperiodic solve at seas_ml = 0: %d Newton iterations, %.3f s warm, max|Phi(y)-y| = %.3e",
    sp_per$periodic$iterations, t_per_solve, sp_per$periodic$resid_state)
say("  the aseasonal spinup it is seeded from: %.3f s warm", t_ase_solve)

dy   <- max(abs(sp_per$y - sp_ase$y))
dyr  <- max(abs((sp_per$y - sp_ase$y) / pmax(abs(sp_ase$y), 1e-12)))
say("  max|dy|            %.6e GtC   (BIT-IDENTICAL would be 0)", dy)
say("  max relative       %.6e", dyr)
say("  CO2 ppm   aseasonal %.6f -> periodic %.6f  (delta %+.6f ppm)",
    sp_ase$diagnostics$co2_ppm, sp_per$diagnostics$co2_ppm,
    sp_per$diagnostics$co2_ppm - sp_ase$diagnostics$co2_ppm)
say("  ocean GtC aseasonal %.4f -> periodic %.4f  (delta %+.4f)",
    sp_ase$diagnostics$ocean_C_GtC, sp_per$diagnostics$ocean_C_GtC,
    sp_per$diagnostics$ocean_C_GtC - sp_ase$diagnostics$ocean_C_GtC)
say("  prod_c14  aseasonal %.6f -> periodic %.6f", sp_ase$prod_c14, sp_per$prod_c14)

# ---- and what it is worth to the OBJECTIVE, on the objective's own call ----
say("\n-- what adoption costs the OBJECTIVE at this mode, by stream --")
lp_ase <- ccx_make_logpost(base_params = base, by_stream = TRUE)
lp_per <- ccx_make_logpost(base_params = base, by_stream = TRUE,
                           spinup_fn = function(p) ccx_periodic_spinup(p, verbose = FALSE))
v_ase <- lp_ase(md$u_mode)
v_per <- lp_per(md$u_mode)
ll_ase <- attr(v_ase, "loglik"); ll_per <- attr(v_per, "loglik")
say("  likelihood  aseasonal %.6f -> periodic %.6f   (delta %+.6f)",
    ll_ase, ll_per, ll_per - ll_ase)
say("  log-prior   %.6f on BOTH arms (the prior does not read the spinup): %s",
    attr(v_ase, "logprior"),
    if (isTRUE(all.equal(attr(v_ase, "logprior"), attr(v_per, "logprior")))) "confirmed" else "DIFFERS -- investigate")
s_ase <- attr(v_ase, "streams"); s_per <- attr(v_per, "streams")
stopifnot(setequal(names(s_ase), names(s_per)))   # a substitution must not hide here
d_st <- s_per[names(s_ase)] - s_ase
ord  <- order(-abs(d_st))
say("  the %d largest per-stream shifts (periodic - aseasonal):", PA_STREAM_N)
for (k in head(ord, PA_STREAM_N))
  say("    %-26s %+10.3f   (%.2f -> %.2f)", names(s_ase)[k], d_st[k], s_ase[k], s_per[k])
say("  sum of all shifts %+.6f  (= the likelihood delta above: %s)", sum(d_st),
    if (isTRUE(all.equal(sum(d_st), ll_per - ll_ase))) "reconciles" else "DOES NOT RECONCILE")

# =====================================================================
say("\n== CHECK 1 -- COST, inside the objective ==")
PER_SPINUP <- function(p) ccx_periodic_spinup(p, verbose = FALSE)
lp_ase_q <- ccx_make_logpost(base_params = base)
lp_per_q <- ccx_make_logpost(base_params = base, spinup_fn = PER_SPINUP)
s_a <- tt(function() lp_ase_q(md$u_mode))
s_p <- tt(function() lp_per_q(md$u_mode))
say("  per evaluation   aseasonal %.4f s   periodic %.4f s   FACTOR %.2fx", s_a, s_p, s_p / s_a)
say("  decomposition, all WARM: aseasonal spinup %.4f + periodic increment %.4f",
    t_ase_solve, t_per_solve - t_ase_solve)
say("    the periodic solve is %.0f %% of the periodic evaluation (must be < 100)",
    100 * t_per_solve / s_p)
stopifnot(t_per_solve < s_p)      # a part cannot exceed its whole

# ⚠ AND AT `seas_ml = 1`, WHICH IS THE ARM A ROUND-6 REFIT WOULD ACTUALLY RUN.
# The aseasonal seed is ~20 ppm off the orbit there against ~0.7 GtC here, so the
# Newton has further to travel and the iteration count -- hence the cost -- need
# not carry over. Measured, not extrapolated.
say("\n  -- the same cost at seas_ml = 1 (the refit's own arm) --")
p_ml <- p_mode; p_ml$seas_ml <- 1
u_ml <- md$u_mode
if ("seas_ml" %in% CCX_PARAM_NAMES) {
  say("    ⚠ `seas_ml` IS a fitted name, so the objective sets it from `u`, not from")
  say("      base_params -- this arm would need a moved coordinate and is NOT run here.")
  s_a1 <- NA_real_; s_p1 <- NA_real_; it_ml <- NA_integer_
} else {
  sp_ase1 <- ccx_spinup(p_ml)
  sp_per1 <- ccx_periodic_spinup(p_ml, seed = sp_ase1, verbose = FALSE)
  it_ml <- sp_per1$periodic$iterations
  base_ml1 <- base; base_ml1$seas_ml <- 1
  lp_a1 <- ccx_make_logpost(base_params = base_ml1)
  lp_p1 <- ccx_make_logpost(base_params = base_ml1, spinup_fn = PER_SPINUP)
  s_a1 <- tt(function() lp_a1(u_ml))
  s_p1 <- tt(function() lp_p1(u_ml))
  say("    Newton iterations %d (vs %d at seas_ml = 0)", it_ml, sp_per$periodic$iterations)
  say("    per evaluation   aseasonal %.4f s   periodic %.4f s   FACTOR %.2fx",
      s_a1, s_p1, s_p1 / s_a1)
}
nb <- nrow(sp_ase$y)
# the count is PER ARM, because the iteration count is (3 vs 6) -- a single
# "integrations per spinup" figure would silently be one arm's
# ⇒ [[verify_the_quantity_not_the_word]].
for (arm in c("seas_ml = 0", "seas_ml = 1")) {
  nit <- if (arm == "seas_ml = 0") sp_per$periodic$iterations else it_ml
  if (!is.finite(nit)) next
  say("  arithmetic at %s: %d boxes ⇒ %d one-year runs per Newton iteration, %d iterations,",
      arm, nb, nb + 1L, nit)
  say("    + 2 x %d for the two isotope monodromies (FIXED, outside the loop) = %d integrations",
      nb + 1L, nit * (nb + 1L) + 2L * (nb + 1L) + 2L)
}

# ---- price a refit off the LAST REFIT'S OWN measured cost -------------
if (!is.null(md$n_eval) && !is.null(md$minutes)) {
  say("\n  the mode file's OWN refit cost: %d evaluations in %.1f minutes (%.4f s/eval)",
      md$n_eval, md$minutes, 60 * md$minutes / md$n_eval)
  fac <- if (is.finite(s_p1)) s_p1 / s_a1 else s_p / s_a
  say("  ⇒ the SAME search under the periodic spinup, at the REFIT'S OWN arm's factor")
  say("    (x%.2f%s): %.1f minutes = %.2f h",
      fac, if (is.finite(s_p1)) " measured at seas_ml = 1" else " at seas_ml = 0 -- the only arm measured",
      md$minutes * fac, md$minutes * fac / 60)
  say("  ⚠ that is ONE start. A Torch ARRAY multiplies it by the start count,")
  say("    and the measured s/eval above differs from the refit's own %.4f s/eval",
      60 * md$minutes / md$n_eval)
  say("    because that run predates the C++ core and this machine -- read the FACTOR, not the absolute.")
} else {
  say("\n  ⚠ the mode file carries no n_eval/minutes; a refit cannot be priced off it here.")
}

# =====================================================================
say("\n== CHECK 3 -- the periodic object's diagnostics are its OWN ==")
say("  Both spinups now route through ccx_spinup_diagnostics() (09-09x).")
say("  The sharpest previously-stale pair, production, must agree with $prod_c14:")
say("    $prod_c14 %.6f   vs  $diagnostics$prod_c14_mol_yr %.6f  -> %s",
    sp_per$prod_c14, sp_per$diagnostics$prod_c14_mol_yr,
    if (identical(sp_per$prod_c14, sp_per$diagnostics$prod_c14_mol_yr)) "AGREE" else "STALE")
stopifnot(identical(sp_per$prod_c14, sp_per$diagnostics$prod_c14_mol_yr))
# MUTATION: the old inherit-and-overwrite form must FAIL this, or it has no power.
d_stale <- sp_ase$diagnostics
d_stale$prod_c14_mol_yr <- sp_ase$prod_c14
say("    MUTATION (the pre-09-09x inherited list): %.6f vs %.6f -> %s (want STALE)",
    sp_per$prod_c14, d_stale$prod_c14_mol_yr,
    if (identical(sp_per$prod_c14, d_stale$prod_c14_mol_yr)) "AGREE" else "STALE")
stopifnot(!identical(sp_per$prod_c14, d_stale$prod_c14_mol_yr))
say("  ⇒ the check HAS POWER: it separates the two forms.")
say("  every field recomputed, none inherited: %d fields, and d13c_atm/land differ from the seed:",
    length(sp_per$diagnostics))
say("    d13c_atm   seed %+.6f -> periodic %+.6f", sp_ase$diagnostics$d13c_atm, sp_per$diagnostics$d13c_atm)
say("    land_C_GtC seed %.4f -> periodic %.4f", sp_ase$diagnostics$land_C_GtC, sp_per$diagnostics$land_C_GtC)

# =====================================================================
# CHECK 4 -- WHICH SEASONAL PATH PUTS THE ASEASONAL SEED OFF THE ORBIT?
# The -10.16 is not diffuse: 25 streams and TWO carry it, with OPPOSITE signs
# (d13c_level_SPO -16.73, d13c_level_MLO +8.28) -- an INTERHEMISPHERIC d13C shift.
#
# ⛔⛔ THE FIRST CUT OF THIS CHECK WAS A NULL WITH NO POWER, and it is kept here
# as a GATE rather than deleted. It "tested" the hemispheric asymmetry by
# symmetrising `seas_amp_NH`/`seas_amp_SH` (12 / 2 -> 7 / 7) and got a result
# IDENTICAL to the as-fitted arm in every printed digit. That is not a physical
# null: at `seas_drivers = 1` those two are DEAD PARAMETERS -- R/model.R:1291-1296
# calls them "THE SINE'S KNOBS, live only at seas_drivers = 0". A test that moves
# a parameter the model ignores reports "no effect" identically to one that looked
# ⇒ [[no_power_null]]. Turned into an assertion of the inertness instead, which is
# a claim model.R states and nothing tested.
say("\n== CHECK 4 -- which seasonal path is it, and one dead-knob gate ==")
PA_D13C_ROWS <- c("d13c_level_MLO", "d13c_level_SPO")

arm_shift <- function(bp, label) {
  la <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = PER_SPINUP)
  va <- la(md$u_mode); vp <- lp(md$u_mode)
  sa <- attr(va, "streams"); sp <- attr(vp, "streams")
  d  <- sp[names(sa)] - sa
  say("  %-36s dLL %+9.3f | d13C rows %+8.3f (SPO %+8.3f, MLO %+8.3f)",
      label, attr(vp, "loglik") - attr(va, "loglik"), sum(d[PA_D13C_ROWS]),
      d[["d13c_level_SPO"]], d[["d13c_level_MLO"]])
  list(dll = attr(vp, "loglik") - attr(va, "loglik"), d13c = sum(d[PA_D13C_ROWS]),
       ll_aseasonal = attr(va, "loglik"))
}

c4_ref <- arm_shift(base, sprintf("as fitted -- DRIVER path (seas_drivers %g)", p_mode$seas_drivers))

# (a) THE OTHER SEASONAL PATH, on its own. `seas_drivers = 0` does NOT remove
# seasonality -- it hands it to the legacy SINE (R/model.R:1291, "the escape
# hatch"), whose amplitudes are the 12 / 2 sitting in this base list. So this arm
# swaps ONE seasonal path for the OTHER; it does not switch seasonality off, and
# reading it as an identity was this check's second error.
b_sine <- base; b_sine$seas_drivers <- 0
c4_sine <- arm_shift(b_sine, "SINE path instead (seas_drivers = 0, amps 12/2)")

# (b) NOW THE IDENTITY: BOTH paths off. With no seasonal cycle at all there is
# nothing to rectify, so the one-year map's fixed point and the instantaneous
# fixed point are THE SAME STATE -- an identity at the solver's tolerance, not a
# judgement ⇒ [[threshold_from_obs_or_law]].
b_off <- b_sine; b_off$seas_amp_NH <- 0; b_off$seas_amp_SH <- 0
c4_off <- arm_shift(b_off, "BOTH paths off (the identity)")
say("  ⇒ identity arm |d13C shift| %.3e; the two live arms are %+.3f and %+.3f",
    abs(c4_off$d13c), c4_ref$d13c, c4_sine$d13c)
stopifnot(abs(c4_off$d13c) < 1e-6, abs(c4_ref$d13c) > 1, abs(c4_sine$d13c) > 1)
say("  ⇒ THE GATE HAS POWER (it separates the arms by >8 orders), and the answer is")
say("    SEASONALITY ITSELF, not a particular path: the two paths give %+.2f and %+.2f, within %.0f %% of each other.",
    c4_ref$dll, c4_sine$dll, 100 * abs(c4_sine$dll - c4_ref$dll) / abs(c4_ref$dll))
say("  ⛔ SO THIS DEFECT PREDATES ROUND 6 **AND** THE 2026-08-18 DRIVER PATH.")
say("    It is a property of seeding a SEASONAL model from an ASEASONAL fixed point.")

# (c) THE DEAD-KNOB GATE. `seas_amp_*` must be INERT at seas_drivers = 1 and LIVE
# at seas_drivers = 0. Both halves, or it is not a gate ⇒ [[mutation_test_gates]].
amp_sym <- (p_mode$seas_amp_NH + p_mode$seas_amp_SH) / 2
b_sym <- base; b_sym$seas_amp_NH <- amp_sym; b_sym$seas_amp_SH <- amp_sym
ll_ref <- ccx_make_logpost(base_params = base)(md$u_mode)
ll_sym <- ccx_make_logpost(base_params = b_sym)(md$u_mode)
say("  dead-knob gate: seas_amp 12/2 -> %g/%g at seas_drivers = 1", amp_sym, amp_sym)
say("    logpost %.9f -> %.9f (delta %.3e) -> %s", ll_ref, ll_sym, ll_sym - ll_ref,
    if (identical(ll_ref, ll_sym)) "INERT, as model.R:1295 claims" else "LIVE -- model.R:1295 is WRONG")
b_sine_sym <- b_sine; b_sine_sym$seas_amp_NH <- amp_sym; b_sine_sym$seas_amp_SH <- amp_sym
ll_s_ref <- ccx_make_logpost(base_params = b_sine)(md$u_mode)
ll_s_sym <- ccx_make_logpost(base_params = b_sine_sym)(md$u_mode)
say("    MUTATION at seas_drivers = 0: %.6f -> %.6f (delta %+.6f) -> %s",
    ll_s_ref, ll_s_sym, ll_s_sym - ll_s_ref,
    if (identical(ll_s_ref, ll_s_sym)) "STILL INERT -- NO POWER" else "LIVE (want LIVE)")
stopifnot(identical(ll_ref, ll_sym), !identical(ll_s_ref, ll_s_sym))
say("  ⇒ CONFIRMED both ways: `seas_amp_NH = 12` / `seas_amp_SH = 2` in the canonical")
say("    mode's base list are DEAD VALUES at seas_drivers = 1. Read as the model's")
say("    seasonal amplitude they are wrong ⇒ [[verify_the_quantity_not_the_word]].")

# ⚠ WHAT IS STILL OPEN. Whether the interhemispheric d13C shift is the DRIVER
# CLIMATOLOGY'S OWN hemispheric asymmetry cannot be tested from `base_params`:
# the live asymmetric knobs (`seas_T_amp_*`, `seas_lag_p_*`, `sst_seas_amp_*`)
# are FITTED names, so the objective sets them from `u` and a base_params
# override is silently discarded. Testing it means moving `u` coordinates, which
# is a separate design question and is NOT attempted here.
say("  ⚠ OPEN: whether the d13C split is the driver climatology's own hemispheric")
say("    asymmetry. The live knobs are FITTED, so base_params cannot move them.")

saveRDS(list(tag = PA_TAG, mode = CCX_MODE_CANONICAL,
             cost = list(aseasonal_s = s_a, periodic_s = s_p, factor = s_p / s_a,
                         aseasonal_s_ml1 = s_a1, periodic_s_ml1 = s_p1,
                         factor_ml1 = s_p1 / s_a1, iterations_ml1 = it_ml,
                         aseasonal_solve_s = t_ase_solve,
                         solve_s = t_per_solve, iterations = sp_per$periodic$iterations,
                         boxes = nb),
             noop = list(max_dy = dy, max_rel = dyr,
                         ll_aseasonal = ll_ase, ll_periodic = ll_per,
                         d_loglik = ll_per - ll_ase, d_streams = d_st,
                         seas_paths_on = n_on),
             mechanism = list(as_fitted = c4_ref, sine_path = c4_sine, both_off = c4_off,
                              amp_inert = list(amp_sym = amp_sym, ll_ref = ll_ref,
                                               ll_sym = ll_sym, ll_sine_ref = ll_s_ref,
                                               ll_sine_sym = ll_s_sym)),
             spinups = list(aseasonal = sp_ase$diagnostics, periodic = sp_per$diagnostics)),
        PA_OUT)
say("\nwrote %s", PA_OUT)
close(con)
