# =====================================================================
# run_modefind_pump_arms.R -- THE REFIT (task 8), run as TWO ARMS: `pump_mode`
# "N" (export mass fixed) and "D" (export scaled by mixed-layer DIC).
#
# WHY TWO ARMS. `pump_mode` is a STRUCTURAL choice, not a fitted parameter, and
# it was deferred to the refit when the pump was ported (DESIGN sec.5.2f). The
# gradient rows cannot tell N and D apart; the only place they differ is the
# TRANSIENT, and at the pre-gradient mode D's apparent +195 was entirely the CO2
# record -- a quantity a refit can reallocate to `beta_max`, `kz` and `k_w`,
# which is exactly why comparing them at an UNREFITTED mode proves nothing.
# Marcus 2026-08-16e: fit both and compare.
#
# THIS IS THE FIRST REFIT AT 20 PARAMETERS. `pump_grad` entered on 2026-08-16d
# and `kz`'s bracket was re-bisected for the pump on 2026-08-16e, so nothing from
# any earlier mode carries across: the likelihood is a different function and its
# feasible region is a different set. DO NOT COMPARE ANY logL ACROSS THE
# 2026-08-16 BOUNDARY.
#
# ---------------------------------------------------------------------
# HOW THE TWO ARMS ARE COMPARED, decided before either was run.
#
#   PRIMARY: the LAPLACE EVIDENCE, log p(y) ~ log p(y, theta_MAP) + (d/2) log 2pi
#   - 0.5 log|-H|. Both arms carry the SAME 20 parameters, the same priors, the
#   same data and the same likelihood -- only the model structure differs -- so
#   the (d/2) log 2pi term cancels exactly and the comparison reduces to
#   Delta logpost(MAP) - 0.5 Delta log|-H|. That second term is the one a
#   MAP-only comparison silently drops, and it is not small when a structural
#   change alters how sharply the data pin the parameters.
#
#   THE HONEST CAVEAT, STATED HERE RATHER THAN DISCOVERED LATER. A Laplace
#   evidence is a GAUSSIAN approximation at a single mode. With `kz` expected to
#   pin against its bracket (sec.5.2h P2) the posterior is NOT locally Gaussian in
#   that direction, and the Hessian there reports curvature of the transformed
#   coordinate, not of a free parameter. So the evidence difference below is
#   INDICATIVE, not a Bayes factor to quote. If the two arms come out close, the
#   answer is "the data do not distinguish them", NOT the sign of a small number.
#
#   SECONDARY, and more informative when the primary is close:
#     * the PER-STREAM logL decomposition -- which rows each arm buys and sells.
#       The pre-mode reading was that D's gain was entirely the CO2 record; a
#       refit either confirms that or shows the gain reallocated.
#     * where each arm puts `pump_grad`, and whether the POSTERIOR is moved from
#       the PRIOR (the prior mildly double-counts GLODAP by construction, so a
#       `pump_grad` that just sits at its prior centre is not "constrained").
#     * whether `kz` still pins at the re-bisected bracket's top, which is the
#       standing question sec.5.2h left open.
#     * the physical-plausibility screen both arms already print.
#
# ---------------------------------------------------------------------
# RUNTIME ~18 h PER ARM AT 21 PARAMETERS -- MEASURED 2026-08-18, and the older
# estimate on the next line was wrong by 3x, so do not plan against it. The
# running 21-parameter refit turned in 100,010 evaluations in 4 h 28 m =
# **0.161 s/eval**, against the 0.060 s/eval below. What changed since that
# figure was taken: 18 -> 21 parameters, two new likelihood streams (the d13C
# seasonal pair), driver seasonality on BOTH land and SST, and observed-SST
# forcing columns re-derived per draw. At 20 restarts x ARM_MAXIT that is
# ~18 h per arm and ~36 h for the pair, run sequentially.
#
# THE SEQUENTIAL CHOICE IS THE ONE TO REVISIT IF THAT IS TOO LONG, and the
# argument below for it does not survive measurement: the running arm's RSS is
# 158 MB, not the near-half-of-16-GB the swap-thrashing worry assumed, so two
# concurrent arms would be ~320 MB and would halve wall-clock. Left sequential
# for the 2026-08-18 run by Marcus's call ("let it run") rather than because
# the reasoning holds.
#
# SUPERSEDED ESTIMATE, kept because the comparison is the point:
# RUNTIME ~5-6 h PER ARM (the 18-parameter refit took 237-294 min at 0.060
# s/eval; 20 parameters and a pump in the derivative will not be faster). The
# arms are INDEPENDENT and are run sequentially here rather than in parallel:
# the machine is a 16 GB Mac, each arm holds its own forcing tables and spinup
# state, and a swap-thrashed pair is slower than two clean runs. Each arm writes
# its own output as it finishes, so a kill after the first arm loses only the
# second.
#
# EVERY ARM USES THE SAME SEED. The mode-finder is derivative-free with a
# deterministic simplex, so this is about the restart geometry being identical
# between arms -- with a different seed per arm, part of any difference would be
# search luck rather than structure.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
ARM_SEED       <- 2026
ARM_MAXIT      <- 20000     # Nelder-Mead default 500 is far too small for 20 par
ARM_RESTARTS   <- 20        # as run_modefind.R; stops early on convergence
ARM_TOL        <- 1e-4      # stop when a restart gains less than this
ARM_PENALTY    <- 1e6       # finite stand-in for -Inf so optim can navigate
# ARM_HESS_EPS RETIRED 2026-08-23 -- the Hessian now sizes one step per
# direction (R/calibrate.R ccx_hessian_per_direction). CCX_HESS_EPS_FRAC is
# the knob that replaced it. Kept named here only so the log can report what
# the old scalar would have been, for comparison with pre-08-23 arm files.
ARM_HESS_EPS   <- 3e-4      # RETIRED: reporting only, not used for stepping
ARM_FLAG_SIGMA <- 3.0       # prior-sd distance at which a parameter is flagged
# ONE ARM FOR THE 2026-08-20r REFIT, and this is a deliberate narrowing.
# The 2026-08-18 two-arm run found the arms INDISTINGUISHABLE -- every coordinate
# within 0.1 sd -- and its evidence margin was explicitly NOT quotable (kz pinned,
# both arms capped, and the 08-18 smoke test had given the OPPOSITE sign). Marcus
# adopted N on physical grounds: nutrient- rather than DIC-limited export, and a
# constant-mass pump changes the ocean sink by EXACTLY zero. Nothing that has
# changed since (the re-anchored seasonal priors 08-20g, npp_frac_NH 08-20k, the
# NEP amplitude factors 08-20r) touches the pump, so re-running D would spend
# ~18 h re-deciding a question the data already declined to answer.
# RESTORE c("N", "D") IF THE PUMP STRUCTURE IS EVER BACK IN PLAY -- the
# comparison block below is guarded and reactivates on its own.
ARM_MODES      <- c("N")
# h_ml IS BOUNDED TO THE GRADIENT ROWS' VALIDITY BAND FOR THIS REFIT (Marcus
# 2026-08-16g). See the block below for what that does and does not buy.
# ⚠ PROVENANCE ONLY since 2026-08-28 -- nothing may bound h_ml with this.
ARM_HML_BOUND  <- LIK_OCEAN_GRAD_HML_OK_RETIRED   # what 16g-to-08-28 pinned
ARM_HML_INIT   <- 100      # m; the pump's own h_ml (DESIGN sec.5.2f, handoff 15d)
                           # and the depth every pump diagnostic scores at. The
                           # SHIPPED init of 75 is outside the new bound and would
                           # make .to_unc() return NaN, so this is not cosmetic.
# WARM START (added 2026-08-21). The 08-20r run hit the restart cap while still
# gaining and its BFGS polish then gained 16.08 -- two orders of magnitude more
# than any of its last restarts -- so the simplex had collapsed in a direction
# the gradient could still exploit and the mode was NOT located. Set TRUE to
# start from the EXISTING output's `par_mode` instead of the hand-set init, and
# to alternate Nelder-Mead with BFGS until the polish stops paying.
# `par_mode` is band-INDEPENDENT and is re-encoded under this run's table, so a
# warm start is safe where reusing `u_mode` would not be (ccx_hml_band_provenance).
# ⚠ BAND-independent is not SET-independent. `par_mode` still carries the names
# of the parameter set it was fitted under, so a warm start across a set change
# goes through ccx_migrate_par_set() at the site below (2026-08-31).
ARM_WARM       <- TRUE
ARM_CYCLES     <- 6         # NM-then-polish cycles; 1 reproduces the old behaviour
ARM_CYCLE_TOL  <- 0.5       # stop when a whole cycle gains less than this
# ---- SMOKE-TEST OVERRIDES (added 2026-08-22) ------------------------
# This run costs hours, so it must be provable end-to-end for pennies first, and
# a smoke test that writes to the REAL output directory would clobber the mode
# the app ships. These four env vars make a cheap run possible AND make it
# impossible for that run to overwrite anything: point CCX_ARM_OUTDIR somewhere
# else and both the warm-start source and the output follow it, because
# ARM_OUT() is defined from ARM_OUTDIR. Seed the smoke dir with a copy of the
# real mode file to exercise the warm-start path exactly as the real run will.
# Unset, every one of these is the production value -- the defaults below are
# the literals that were here before, so a bare Rscript call is unchanged.
.env_num <- function(nm, default) {
  v <- Sys.getenv(nm, NA_character_)
  if (is.na(v) || !nzchar(v)) return(default)
  n <- suppressWarnings(as.numeric(v))
  if (is.na(n)) stop(nm, " is not numeric: '", v, "'")
  cat(sprintf("OVERRIDE %s = %s (default %s)\n", nm, format(n), format(default)))
  n
}
ARM_RESTARTS   <- .env_num("CCX_ARM_RESTARTS", ARM_RESTARTS)
ARM_CYCLES     <- .env_num("CCX_ARM_CYCLES",   ARM_CYCLES)
ARM_MAXIT      <- .env_num("CCX_ARM_MAXIT",    ARM_MAXIT)
ARM_OUTDIR     <- local({
  d <- Sys.getenv("CCX_ARM_OUTDIR", NA_character_)
  if (is.na(d) || !nzchar(d)) ccx_path("calibration", "output", "pump_arms")
  else { cat(sprintf("OVERRIDE CCX_ARM_OUTDIR = %s\n", d)); d }
})
ARM_OUT        <- function(m) file.path(ARM_OUTDIR, sprintf("mode_fit_pump%s.rds", m))
ARM_KINK_STEP  <- 0.01     # h_ml resolution the kink scan below runs at
ARM_KINK_FACT  <- 20       # a kink = this many times the median slope jump

dir.create(ARM_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

cat(sprintf("REFIT, %d ARM(S) [%s]. %d parameters: %s\n",
            length(ARM_MODES), paste(ARM_MODES, collapse = ", "),
            length(CCX_PARAM_NAMES), paste(CCX_PARAM_NAMES, collapse = ", ")))
cat(sprintf("kz bracket [%g, %g] (re-bisected for the pump 2026-08-16e)\n",
            CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi))
cat(sprintf("pump default %.6f umol/kg = PUMP_GRAD_OBS\n",
            ccx_default_params()$pump_grad))

# =====================================================================
# h_ml IS **UNBOUNDED** FOR THIS REFIT -- Marcus 2026-08-28, option 5 adopted
# =====================================================================
# ⚠ THIS INVERTS THE 2026-08-16g DECISION. From 16g to 08-28 this driver pinned
# h_ml to LIK_OCEAN_GRAD_HML_OK_RETIRED = [85, 120] and renormalised its prior over that
# support, because outside the band all three ocean-gradient rows SKIPPED and an
# unbounded refit would have scored a DIFFERENT objective from the one the pump
# was introduced to be tested against.
#
# THE SKIP IS GONE. The rows are now scored at sigma_eff(h_ml) at EVERY depth
# (R/likelihood.R, LIK_USE_OCEAN_GRAD's block), so the reason for the bound has
# been removed rather than worked around, and h_ml refits over its OWN SHIPPED
# SUPPORT [30, 200] with its OWN prior. No override, and therefore no +1.58
# renormalisation constant to carry.
#
# WHY THE BOUND COULD NOT SIMPLY BE KEPT AS CONSERVATISM. It was measured to be
# LOAD-BEARING, and to be bearing a FREE LUNCH rather than physics: outside the
# band the rows were ABSENT rather than zero, so leaving it bought +7.30
# log-units of un-scored data out of a +7.39 total advantage -- the objective did
# not prefer a shallower mixed layer, it preferred BEING SCORED ON LESS DATA
# (notes/collect_2026-08-28_hml_unbound_profile.md). With inflation on, the pull
# falls to +0.033, both cliffs vanish (+7.30 -> -0.006 at 85, +8.43 -> -0.005 at
# 120), and h_ml has an INTERIOR maximum over the full support -- it no longer
# needs a wall to stay put (notes/collect_2026-08-28b_sigma_inflation_pricing.md).
#
# CONSEQUENCE, LOUDLY: this objective is a DIFFERENT FUNCTION from BOTH the
# pre-16g unbounded one and the 16g-to-08-28 bounded one. Its logpost is NOT
# comparable with any earlier run's. Everything fitted before 2026-08-28 is
# non-comparable and is quarantined.
sep("h_ml UNBOUNDED -- the retired band is NOT re-applied (Marcus 2026-08-28)")
# GATE H1, INVERTED: the shipped parameter table must be UNTOUCHED. The old gate
# asserted that exactly one entry had changed; this asserts that none has, which
# is the property that now matters -- a stray override would silently reinstate
# the retired objective.
.hml_now <- CCX_PARAM_TABLE$h_ml
stopifnot(identical(.hml_now$lo, 30), identical(.hml_now$hi, 200))
cat(sprintf("GATE H1: h_ml on its SHIPPED support [%g, %g], prior NOT renormalised. OK\n",
            .hml_now$lo, .hml_now$hi))
# GATE H2: the shipped init must now be ACCEPTED, where the bounded run rejected
# it. Same round-trip the old gate ran, with the verdict deliberately reversed.
.u_h <- .to_unc(.hml_now$init, .hml_now)
stopifnot(is.finite(.u_h), abs(.from_unc(.u_h, .hml_now) - .hml_now$init) < 1e-9)
cat(sprintf("GATE H2: the shipped init %g round-trips (u = %+.4f) and is ACCEPTED. OK\n",
            .hml_now$init, .u_h))
# GATE H3, INVERTED AND STRENGTHENED: the rows must be LIVE not just at init but
# at BOTH ENDS of the support -- the entire content of the adoption. Asserted on
# ccx_ocean_grad_scored()'s own return, so a change to its internals cannot pass
# this silently, and on sd_eff so a build that lost the sigma_rep table cannot.
.F_h  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                           bomb_total_kmol = 102)
for (.h in c(.hml_now$lo + 1, .hml_now$init, .hml_now$hi - 1)) {
  .sp_h <- ccx_spinup(local({ p <- ccx_default_params(); p$h_ml <- .h; p }))
  .Fh <- .F_h; .Fh$c14_cosmo <- .sp_h$prod_c14
  .og_h <- ccx_ocean_grad_scored(ccx_run_fast(.sp_h, .Fh)$out, .sp_h)
  if (is.null(.og_h) || !all(is.finite(.og_h$sd_eff)))
    stop("GATE H3 FAILED: the gradient rows are ABSENT or carry no sd_eff at ",
         "h_ml = ", .h, " -- the retired band is still gating somewhere, or ",
         "data/obs_glodap_sigma_rep.rds is missing.")
  cat(sprintf("GATE H3: rows LIVE at h_ml %6.1f (DIC %+8.2f, d13C %+.4f, ALK %+7.2f; ",
              .h, .og_h$dic, .og_h$d13c, .og_h$alk))
  cat(sprintf("sd_eff/sd_obs %.3f/%.3f/%.3f). OK\n",
              .og_h$sd_eff[["dic"]]  / ccx_ocean_gradient_target()$dic$sd,
              .og_h$sd_eff[["d13c"]] / ccx_ocean_gradient_target()$d13c$sd,
              .og_h$sd_eff[["alk"]]  / ccx_ocean_gradient_target()$alk$sd))
}

# ---- PLACEMENT NOTE, and it cost a dead run ------------------------
# This block was first written ABOVE the h_ml override and the run died on
# "the h_ml override touched more than h_ml: h_ml, luc_scale". GATE H1 snapshots
# the WHOLE parameter table and asserts that only `h_ml` moved across the
# override -- so ANY other table edit must come AFTER it, not before. The gate
# worked exactly as designed; the block was in the wrong place. Leave it here.
# ---- OPTIONAL PARAMETER PIN (added 2026-08-23) ----------------------
# WHY. The 2026-08-23 sink run showed the model ROUTING AROUND a prescribed
# 1942-49 removal: `luc_scale` moved +5.52 posterior sd (0.8984 -> 1.0852,
# crossing 1.0) and put 54 GtC of land-use emissions back against the sink's
# 20 GtC. `rep_dC` therefore barely moved (5.566 -> 5.126) where a frozen 1-D
# scan had predicted 2.21. A prescribed LOCAL perturbation is absorbed by a free
# GLOBAL rescale, so the experiment could not test the question it was built for
# -- is the fit being bent toward a mid-century the field cannot explain?
#
# HOW. The parameter stays in the 21-name vector (so the mode file, the Hessian
# and every downstream reader keep their shape) but its prior is collapsed to a
# near-delta at the pin and its init moved there. It is pinned in effect, not
# deleted. The Hessian row will be ~1/PIN_SD^2 and its posterior sd ~PIN_SD;
# that is expected, and it means the LAPLACE EVIDENCE OF A PINNED RUN IS NOT
# COMPARABLE to an unpinned one -- read parameters and per-stream logL, not
# evidence.
ARM_PIN_SD <- 1e-4
# GENERALISED 2026-08-25. `CCX_PIN_LUC_SCALE` still works and is unchanged, so
# every existing run reproduces; `CCX_PIN_PARAMS="name=value,name=value"` pins
# any subset. The generalisation exists because P3 of prereg 08-24c fired --
# `sigma_d14c` moved +1.671 sd in the pinned `luc` arm, past its own falsifier --
# and the only test that can settle whether that bought the `rep_dC` move is a
# refit with `sigma_d14c` HELD. `rep_dC` and `sigma_d14c` share no likelihood
# term (measured: the 1-D rep_dC argmax is bit-identical across sigma 2 -> 60
# while the peak moves 200 log-units), so a fixed-state test has NO POWER and
# only a re-optimisation can answer it.
ARM_PINS <- local({
  out <- list()
  v <- Sys.getenv("CCX_PIN_LUC_SCALE", NA_character_)
  if (!is.na(v) && nzchar(v)) {
    x <- as.numeric(v); if (is.na(x)) stop("CCX_PIN_LUC_SCALE not numeric: ", v)
    out$luc_scale <- x
  }
  w <- Sys.getenv("CCX_PIN_PARAMS", NA_character_)
  if (!is.na(w) && nzchar(w)) for (kv in strsplit(w, ",")[[1]]) {
    kv <- trimws(kv); pr <- strsplit(kv, "=")[[1]]
    if (length(pr) != 2L) stop("CCX_PIN_PARAMS entry must be name=value; got: ", kv)
    nm <- trimws(pr[1]); x <- as.numeric(pr[2])
    if (is.na(x)) stop("CCX_PIN_PARAMS value not numeric: ", kv)
    if (!nm %in% CCX_PARAM_NAMES) stop("CCX_PIN_PARAMS names an unfitted parameter: ", nm)
    if (!is.null(out[[nm]]) && !isTRUE(all.equal(out[[nm]], x)))
      stop("parameter ", nm, " pinned twice at different values")
    out[[nm]] <- x
  }
  out
})
# `ARM_PIN` is retained so downstream provenance lines that quote the luc_scale
# pin keep reading the same object.
ARM_PIN <- ARM_PINS$luc_scale
# ---- THE NEAR-DELTA IS FAMILY-GENERAL (2026-08-25) ------------------
# It USED to be hardcoded lognormal, which made it correct only for `tr = "log"`
# and made the driver ERROR on anything else -- deliberately, because a pin that
# binds in the wrong coordinate looks exactly like a parameter that chose to
# stay put. That guard was right and the fix is to supply the missing families,
# not to loosen it. `fert_k` and `beta_max` are BOTH `tr = "logit"`
# (R/calibrate.R:61, 68), so the ridge could not be pinned at all.
#
# WHAT A PIN ACTUALLY IS. ccx_make_logpost() adds `s$prior(x) + .log_jac(u, s)`
# (R/calibrate.R:874), i.e. priors are densities in the NATURAL parameter and
# the Jacobian is applied separately. So a near-delta that is sharp in the
# UNCONSTRAINED coordinate -- which is the coordinate the optimiser moves in,
# and therefore the one a pin must bind in -- is
#
#     prior(x) = dnorm(u(x), u0, PIN_SD) - log_jac(u(x))
#
# whose contribution to the log-posterior is exactly dnorm(u, u0, PIN_SD). One
# expression, all three families, no branching.
#
# AND IT REPRODUCES THE OLD LOGNORMAL EXACTLY. For tr = "log", u = log(x) and
# log_jac = u, so the expression is dnorm(log x, log val, sd) - log(x) =
# dlnorm(x, log val, sd). Every existing pinned run reproduces byte-for-byte;
# test-pin-family.R gates that identity rather than asserting it here.
ARM_PIN_BUMP_U <- log(1.05)   # sharpness-gate perturbation, in UNCONSTRAINED units
                              # log(1.05) is chosen so the log family's gate is
                              # still evaluated at exactly val * 1.05 and its
                              # printed line is unchanged. A fixed *1.05 cannot
                              # serve a logit parameter -- it can leave [lo, hi]
                              # entirely -- so the perturbation is expressed in
                              # the coordinate the pin binds in. Derived from the
                              # transform, not from the value (memory
                              # derive_gate_from_the_thing).
for (.nm in names(ARM_PINS)) {
  .val <- ARM_PINS[[.nm]]
  .spec <- CCX_PARAM_TABLE[[.nm]]
  if (!.spec$tr %in% c("log", "logit", "id"))
    stop("no near-delta family for ", .nm, " with tr = \"", .spec$tr, "\"")
  if (identical(.spec$tr, "log") && !(.val > 0))
    stop("pin for ", .nm, " must be positive on the log scale; got ", .val)
  if (identical(.spec$tr, "logit") && !(.val > .spec$lo && .val < .spec$hi))
    stop("pin for ", .nm, " must be STRICTLY inside [", .spec$lo, ", ", .spec$hi,
         "]; got ", .val, " -- the logit transform is infinite at the bounds")
  .u0 <- .to_unc(.val, .spec)
  if (!is.finite(.u0))
    stop("pin for ", .nm, " does not encode to a finite unconstrained value: ", .val)
  cat(sprintf("\n*** %s PINNED at %.6f (prior sd %.0e) ***\n", .nm, .val, ARM_PIN_SD))
  CCX_PARAM_TABLE[[.nm]]$init  <- .val
  CCX_PARAM_TABLE[[.nm]]$prior <- local({
    u0 <- .u0; sdv <- ARM_PIN_SD; sp <- .spec
    function(x) {
      # suppressWarnings: qlogis() warns and returns NaN outside [lo, hi], which
      # is the CORRECT answer here (-Inf prior) but would spam every optimiser
      # step that proposes outside the support. The NaN is caught, not ignored.
      u <- suppressWarnings(.to_unc(x, sp))
      if (!all(is.finite(u))) return(-Inf)
      stats::dnorm(u, u0, sdv, log = TRUE) - .log_jac(u, sp)
    }
  })
  # GATE: the pin must round-trip through the transform, and the prior must
  # actually be sharp there -- a pin that silently failed to bind would look
  # exactly like "the parameter chose to stay put", which is the conclusion
  # these runs exist to test. The tolerance is DERIVED from the pin's own prior
  # sd rather than hand-picked: 08-24b's hand-picked 1e-6 errored against a pin
  # that had bound perfectly (memory derive_gate_from_the_thing).
  # NB several fitted parameters have no slot in ccx_default_params() (they are
  # FORCING or LIKELIHOOD parameters), so the round-trip is built from the
  # parameter TABLE, not from a params list.
  .pl <- lapply(CCX_PARAM_TABLE[CCX_PARAM_NAMES], `[[`, "init")
  .uv <- unlist(ccx_par_to_unc(.pl))
  .back <- ccx_unc_to_par(.uv)[[.nm]]
  .tol <- 10 * ARM_PIN_SD * abs(.val)
  # The perturbation is a fixed step in the UNCONSTRAINED coordinate, mapped
  # back. For tr = "log" this IS .val * 1.05 and the line below is unchanged.
  .bump <- .from_unc(.u0 + ARM_PIN_BUMP_U, .spec)
  cat(sprintf("    GATE round-trip %.6f -> %.6f (err %.1e, tol %.1e); prior at pin %.1f, at %.6f %.1f\n",
              .val, .back, abs(.back - .val), .tol,
              CCX_PARAM_TABLE[[.nm]]$prior(.val), .bump,
              CCX_PARAM_TABLE[[.nm]]$prior(.bump)))
  stopifnot(abs(.back - .val) < .tol)
  # ...and the prior must actually be SHARP: a step of ARM_PIN_BUMP_U in the
  # coordinate the optimiser moves in must be rejected hard, or the "pin" is a
  # suggestion. The floor is DERIVED, not hand-picked: the near-delta is a
  # normal of sd ARM_PIN_SD in u, so the drop is ARM_PIN_BUMP_U^2 / (2 sd^2)
  # up to the Jacobian, and the gate demands at least half of that.
  .want <- 0.5 * ARM_PIN_BUMP_U^2 / (2 * ARM_PIN_SD^2)
  .drop <- CCX_PARAM_TABLE[[.nm]]$prior(.val) - CCX_PARAM_TABLE[[.nm]]$prior(.bump)
  if (!(.drop > .want))
    stop(sprintf("pin for %s is NOT SHARP: a %.4f step in u drops the prior only %.1f, wanted > %.1f",
                 .nm, ARM_PIN_BUMP_U, .drop, .want))
}
rm(.nm, .val, .spec, .u0, .pl, .uv, .back, .tol, .bump, .want, .drop)

# ⚠ The 2026-08-28 gate rewrite (h_ml unbounded) removed .tab_before/.hml_before/
# .chg/.fld and added the loop's .h/.Fh; this list follows it.
rm(.hml_now, .u_h, .F_h, .h, .sp_h, .Fh, .og_h)

# =====================================================================
# THE h_ml DIRECTION IS PIECEWISE-C1, AND THE HESSIAN HAS TO KNOW WHERE.
#
# calibration/diag_hess_eps_21par.R, run before this refit was launched, found
# SUPERSEDED 2026-08-23: this whole justification is about a SCALAR step that is
# no longer taken. It was also right only for the STIFF subspace -- 3e-4 is 250x
# too small for `h_ml`, the very parameter the block below worries about (memory
# ccx_hess_step_sd). Kept as provenance for pre-08-23 arm files. The block reads:
# that `ARM_HESS_EPS = 3e-4` is inside a stable curvature window at both probe
# points for every coordinate EXCEPT `h_ml` -- and that `h_ml`'s failure is not
# a step-size failure at all. Its second difference scales as 1/eps across six
# decades, the signature of a KINK: continuous value, discontinuous slope. The
# one-sided slopes at h_ml = 100 are -16.21 and -17.92.
#
# SOURCE, and it is not a bug: ccx_pump_shape() remaps the 25 m GLODAP DIC bins
# onto the model layers by overlap integration, `pmax(0, pmin(b, bot) -
# pmax(a, top))`. That is the conservative way to do it. But `h_ml` IS the first
# layer boundary, so as it moves the clamp switches against fixed observed bin
# edges, and a clamped overlap is a |x|. It reaches the isotopes and not CO2
# because in `pump_mode = N` the export is constant-mass -- d13c_level_MLO/_SPO
# carry -0.153/-0.115 of the -0.270 slope jump, co2_level -5e-4.
#
# WHY THIS IS A CHECK AND NOT A FIX. The kinks are SPARSE -- three isolated
# points in a 35 m band -- and `ARM_HESS_EPS` maps to about 2e-3 m of h_ml, so
# a mode has to land within ~2 mm of one for the Hessian row to be contaminated.
# Smoothing the remap (PCHIP through bin midpoints instead of overlap averaging)
# would change the pump field, i.e. the model, on the eve of a refit, to remove
# a risk of order 1e-4. NOT DONE. What IS done is refusing to discover it after
# the fact: the kinks are located here and the found mode is checked against
# them, so a contaminated log|-H| is reported rather than quoted.
#
# DERIVED, not typed. Reading the shape function itself means the list cannot
# drift from the code that creates the kinks.
sep("h_ml KINK MAP (see calibration/diag_hess_eps_21par.R)")
ARM_KINKS <- local({
  # ⚠ SWEEPS THE FULL SUPPORT since 2026-08-28: h_ml is no longer bounded to
  # [85, 120], so a scan over the retired band would miss every kink the
  # refit can now actually reach.
  kh <- seq(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi, by = ARM_KINK_STEP)
  KS <- t(sapply(kh, function(h) ccx_pump_shape(ccx_ocean_grid(h))))
  kt <- rowSums(abs(apply(KS, 2, function(v) diff(diff(v)))))
  kb <- which(kt > ARM_KINK_FACT * stats::median(kt) + 1e-14)
  if (!length(kb)) return(numeric(0))
  unname(vapply(split(kb, cumsum(c(TRUE, diff(kb) > 1))),
                function(ix) kh[ix[which.max(kt[ix])] + 1], numeric(1)))
})
cat(sprintf("%d kink(s) in [%g, %g]: h_ml = %s m\n", length(ARM_KINKS),
            CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi,
            paste(sprintf("%.2f", ARM_KINKS), collapse = ", ")))
# The diagnostic found exactly three. A different count means the shape data or
# the grid changed since, and the Hessian caveat was written against the old one.
if (length(ARM_KINKS) != 3)
  cat("*** the kink count has CHANGED since diag_hess_eps_21par.R -- re-run it\n")
cat(sprintf("ARM_HML_INIT = %g is %s. Harmless: Nelder-Mead is derivative-free.\n",
            ARM_HML_INIT,
            if (any(abs(ARM_KINKS - ARM_HML_INIT) < 1e-6)) "EXACTLY ON A KINK" else
              sprintf("%.2f m clear", min(abs(ARM_KINKS - ARM_HML_INIT)))))

# GATE: the two arms must be the same objective except for `pump_mode`, and the
# only way to know that is to check the thing that could go wrong -- the base
# parameter lists differing anywhere ELSE. Cheap, and it fails loudly.
#
# IT IS A TWO-ARM GATE and it must not fire on a ONE-arm run. With ARM_MODES =
# "N", `b$D` is NULL and identical(x, NULL) is FALSE for every name, so the gate
# reported all 48 parameters as differing -- a gate failing because there is
# nothing to compare, which is the most confusing way for a run to die. It is
# now built over the arms that EXIST and skipped, loudly, when there is one.
b <- lapply(ARM_MODES, function(m) { p <- ccx_default_params(); p$pump_mode <- m; p })
names(b) <- ARM_MODES
if (length(ARM_MODES) >= 2L) {
  d <- names(which(!vapply(names(b[[1]]),
                           function(n) identical(b[[1]][[n]], b[[2]][[n]]), logical(1))))
  if (!identical(d, "pump_mode"))
    stop("the two arms differ in more than pump_mode: ", paste(d, collapse = ", "))
  cat(sprintf("GATE: the arms differ in `pump_mode` and nothing else. OK\n"))
} else {
  cat(sprintf("GATE SKIPPED: one arm (%s) -- there is no second arm to differ from.\n",
              paste(ARM_MODES, collapse = ", ")))
}

# ---------------------------------------------------------------------
# One arm. Lifted from run_modefind.R rather than sourced, because that script
# runs at load and writes a single fixed output path; the ONLY changes are the
# `base_params` injection, the output path, and the arm label in the prints.
# ---------------------------------------------------------------------
arm_fit <- function(mode) {
  sep(sprintf("ARM pump_mode = %s", mode))
  set.seed(ARM_SEED)
  bp <- ccx_default_params(); bp$pump_mode <- mode
  lp_fun <- ccx_make_logpost(base_params = bp)

  n_eval <- 0L
  neg_lp <- function(u) {
    n_eval <<- n_eval + 1L
    v <- lp_fun(u)
    if (!is.finite(v)) return(ARM_PENALTY)
    -v
  }
  u0 <- ccx_init_unc(); lp0 <- lp_fun(u0)
  cat(sprintf("start: log-post at hand-set init = %.1f\n", lp0))
  if (ARM_WARM && file.exists(ARM_OUT(mode))) {
    prev <- readRDS(ARM_OUT(mode))
    # Re-encode from par_mode, NOT prev$u_mode: u_mode is a function of the
    # bounds in force when it was written, and this run's h_ml band may differ.
    # ⚠ AND par_mode is only as current as the parameter SET it was written
    # under. The 2026-08-31 seas_lag_p split makes every stored file a
    # 21-parameter list in a 22-parameter build; migrate it through the model's
    # own absence contract and SAY what was filled, because a warm start that
    # quietly invented a coordinate is worse than one that refused.
    pw <- ccx_migrate_par_set(prev$par_mode)
    if (length(attr(pw, "migrated")))
      cat(sprintf("WARM START MIGRATED from a %d-parameter file: filled %s\n",
                  length(prev$param_names),
                  paste(attr(pw, "migrated"), collapse = ", ")))
    uw <- ccx_par_to_unc(pw); lpw <- lp_fun(uw)
    cat(sprintf("WARM START from %s: log-post there = %.1f (its file says %.1f)\n",
                basename(ARM_OUT(mode)), lpw, prev$logpost))
    if (!is.finite(lpw)) {
      cat("*** warm start is NOT FINITE under this objective -- using the cold init\n")
    } else if (lpw <= lp0) {
      cat("*** warm start is WORSE than the cold init -- using the cold init\n")
    } else { u0 <- uw; lp0 <- lpw }
  }
  t0 <- Sys.time()

  # ---- (a) Nelder-Mead restarts, ALTERNATED WITH BFGS ----------------
  # The 08-20r run is the argument for the alternation: NM gains decayed to
  # 0.07-0.27 per restart and BFGS then found 16.08 in one pass. Neither method
  # alone locates this mode -- NM's simplex collapses in the narrow directions
  # BFGS handles, and BFGS alone would not have crossed the 16,437 the first NM
  # restart bought. So they take turns until a whole cycle stops paying.
  u <- u0; best <- -lp0
  trace <- data.frame(restart = 0L, logpost = lp0, evals = 0L)
  hit_cap <- FALSE
  for (cyc in seq_len(ARM_CYCLES)) {
    cyc_start <- best
    for (i in seq_len(ARM_RESTARTS)) {
      fit <- optim(u, neg_lp, method = "Nelder-Mead",
                   control = list(maxit = ARM_MAXIT, reltol = 1e-12))
      gain <- best - fit$value
      u <- fit$par; best <- fit$value
      cat(sprintf("[%s] cycle %d restart %2d: log-post = %12.1f  (gain %10.4f)  evals %d\n",
                  mode, cyc, i, -best, gain, n_eval))
      trace <- rbind(trace, data.frame(restart = nrow(trace), logpost = -best, evals = n_eval))
      if (i > 1 && gain < ARM_TOL) { cat("  NM converged: gain below ARM_TOL\n"); break }
    }
    # FLAGGED, not silently accepted: a cycle that used every restart while
    # still gaining is a truncated climb, and the 2026-08-12 and 08-20r refits
    # both did exactly that.
    # BOTH conditions: the loop used every restart AND the last one was still
    # paying. Testing exhaustion alone cries wolf on a cycle that used its
    # restarts and gained nothing, which is convergence, not truncation -- the
    # smoke run fired exactly that false alarm at gain 0.0000.
    if (i >= ARM_RESTARTS && gain >= ARM_TOL) {
      hit_cap <- TRUE
      cat(sprintf("*** [%s] cycle %d HIT THE RESTART CAP WHILE STILL GAINING\n", mode, cyc))
    }
    pc <- tryCatch(optim(u, neg_lp, method = "BFGS",
                         control = list(maxit = 500, reltol = 1e-14)),
                   error = function(e) NULL)
    if (!is.null(pc) && pc$value < best) {
      cat(sprintf("[%s] cycle %d polish: log-post = %.1f (gain %.4f)\n",
                  mode, cyc, -pc$value, best - pc$value))
      u <- pc$par; best <- pc$value
    } else cat(sprintf("[%s] cycle %d polish: no improvement\n", mode, cyc))
    cyc_gain <- cyc_start - best
    cat(sprintf("[%s] === cycle %d total gain %.4f (log-post %.1f, %d evals) ===\n",
                mode, cyc, cyc_gain, -best, n_eval))
    # WRITTEN EVERY CYCLE, deliberately: this run may take hours and a kill must
    # leave the best-so-far on disk rather than nothing. The pre-continuation
    # file is in git at be86760, so overwriting is recoverable.
    saveRDS(list(pump_mode = mode, par_mode = ccx_unc_to_par(setNames(u, CCX_PARAM_NAMES)),
                 logpost = -best, cycle = cyc, trace = trace, n_eval = n_eval,
                 # ⚠ ccx_mode_params() RE-DECODES u_mode under this. It must be the
                 # bound actually in force -- since 2026-08-28 that is the SHIPPED
                 # table's, so the re-decode is correctly a no-op. Writing the
                 # retired [85,120] here would corrupt every downstream decode.
                 hml_bound = c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi),
                 in_progress = TRUE, seed = ARM_SEED),
            file.path(ARM_OUTDIR, sprintf("mode_fit_pump%s_progress.rds", mode)))
    if (cyc_gain < ARM_CYCLE_TOL) {
      cat(sprintf("[%s] CONVERGED: cycle gain below ARM_CYCLE_TOL (%g)\n", mode, ARM_CYCLE_TOL))
      hit_cap <- FALSE
      break
    }
  }
  if (hit_cap)
    cat(sprintf("*** [%s] LAST CYCLE HIT THE RESTART CAP -- this mode is NOT converged\n", mode))
  names(u) <- CCX_PARAM_NAMES
  lp_mode <- -best
  pm <- ccx_unc_to_par(u)

  # ---- (b2) physical-plausibility screen ----------------------------
  # ccx_prior_z() SINCE 2026-08-21. This block used to carry its own copy that
  # integrated the prior on a linear grid spanning x/1e3 to x*1e3 -- one grid
  # point inside a tight lognormal -- and it mis-stated this very file's output:
  # seas_T_amp_NH +3.29 (truly +2.65) and bomb_total +3.08 (truly +1.81), both
  # of which it then FLAGGED at |z| > 3. See R/calibrate.R.
  zs <- vapply(CCX_PARAM_NAMES,
               function(n) tryCatch(ccx_prior_z(n, pm[[n]]), error = function(e) NA_real_),
               numeric(1))
  cat(sprintf("\n[%s] prior-tail position (normal sds; |z| > %g flagged):\n", mode, ARM_FLAG_SIGMA))
  print(round(zs, 2))
  fl <- which(abs(zs) > ARM_FLAG_SIGMA)
  if (length(fl)) cat("*** FLAGGED: ", paste(CCX_PARAM_NAMES[fl], collapse = ", "), "\n")

  # BRACKET PRESSURE, printed rather than inferred later from a stuck sampler.
  # sec.5.2h P2 predicted `kz` pins at the top; this is where that is checked
  # against the RE-BISECTED bracket.
  for (n in CCX_PARAM_NAMES) {
    s <- CCX_PARAM_TABLE[[n]]
    if (!identical(s$tr, "logit")) next
    fr <- (pm[[n]] - s$lo) / (s$hi - s$lo)
    if (fr < 0.02 || fr > 0.98)
      cat(sprintf("*** [%s] %s PINNED at %.1f %% of [%g, %g] -- value %.4g\n",
                  mode, n, 100 * fr, s$lo, s$hi, pm[[n]]))
  }

  p_mode <- bp
  for (n in intersect(names(p_mode), CCX_PARAM_NAMES)) p_mode[[n]] <- pm[[n]]

  # ---- (b3) per-stream decomposition at the mode ---------------------
  # The secondary comparison, and the one that says WHICH rows an arm buys.
  # Computed here rather than post hoc so it cannot drift from the mode it
  # describes.
  streams <- tryCatch({
    sp <- ccx_spinup(p_mode)
    F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                           bomb_total_kmol = 102)
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- F$c14_bomb * (pm$bomb_total / 102)
    for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
      F[[cc]] <- F[[cc]] * pm$luc_scale
    attr(F, "luc_scale") <- pm$luc_scale
    # NO SECOND luc_scale HERE. `F`'s four LUC columns were already multiplied
    # three lines up, so deriving `el` from it and scaling again applied
    # luc_scale SQUARED to the gross-land-sink reconstruction. FIXED 2026-08-22.
    # ccx_make_logpost() does not have the bug -- it derives ELUC_BASE once from
    # a forcing built at luc_scale = 1, OUTSIDE the closure, and scales that. So
    # the OBJECTIVE was always right and every logpost/hessian/evidence number
    # stands; what was wrong is the per-stream DECOMPOSITION stored in
    # mode_fit_pump{N,D}.rds, which is the only per-stream table the project has
    # and the one handoffs rank work from.
    # MEASURED at the shipped mode: stored gcb_land_sink -93.71 is exactly the
    # double-scaled value; the correct one is -95.62, so arm N's sink row was
    # flattered by 1.91 log-units. It is NOT common-mode across the arms
    # (luc_scale 0.8902 vs 0.8575), so the N-vs-D per-stream comparison built at
    # line ~594 -- the "sinks + 14C favour D" reading -- inherits a differential
    # error of the same order as the 5.62 evidence margin it sits next to.
    # calibration/diag_design_gates_at_mode.R's provenance gate detects this
    # class by recomputing the stored streams; it is what found it.
    el <- ccx_forcing_eluc_annual(F)
    r <- ccx_run_fast(sp, F)
    # NOTE: sigma_d13c retired 2026-08-18 and rep_dC added in its place -- this
    # list must track CCX_PARAM_NAMES or the per-stream decomposition silently
    # describes a DIFFERENT objective from the one that was optimised.
    ccx_loglik(r$out, ccx_prepare_obs(),
               list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
                    grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c),
               luc = el, deep = sp$diagnostics$d14c_bottom_box,
               ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)
  }, error = function(e) { cat("per-stream decomposition failed:", conditionMessage(e), "\n"); NULL })

  # ---- (c) numerical Hessian ----------------------------------------
  # PER-DIRECTION STEPS SINCE 2026-08-23, via R/calibrate.R's
  # ccx_hessian_per_direction(). This block used to take ONE step,
  # ARM_HESS_EPS = 3e-4, in all 21 directions -- measured at the 2026-08-23 mode
  # that is 250x too small for `h_ml`, 167x for `kz` and 67x for `gamma_enso`,
  # so `sd_unc`, `cov`, `logdet_negH` and this arm's Laplace evidence were wrong
  # precisely in the soft directions the evidence is most sensitive to, and
  # nothing flagged it (memory ccx_hess_step_sd). The correct version existed
  # only in calibration/recompute_hessian.R, as a manual second step someone had
  # to remember -- forgetting it silently shipped the scalar Hessian. Both now
  # call the same function, so there is one implementation to be right.
  # Costs ~5 min on top of a multi-hour refit.
  cat(sprintf("[%s] hessian: per-direction central differences, %d parameters\n",
              mode, length(u)))
  HD <- ccx_hessian_per_direction(lp_fun, u, verbose = TRUE)
  H  <- HD$H
  ARM_HESS_EPS_V <- HD$eps          # named vector, replaces the scalar below
  dimnames(H) <- list(CCX_PARAM_NAMES, CCX_PARAM_NAMES)

  # ---- (c2) is this mode's Hessian trustworthy where we know it might not be?
  # Two checks, both cheap against the 5-6 h that produced the mode, and both
  # reported into the rds so a later reader does not have to take log|-H| on
  # faith.
  #
  # KINK PROXIMITY. ARM_HESS_EPS is a step on the unconstrained scale; what
  # matters is how far that reaches in METRES, which depends on where in the
  # logit band the mode sits. Converted rather than assumed.
  h_mode <- pm$h_ml
  # h_ml's OWN step now, not the global scalar -- and this matters here more than
  # anywhere: h_ml is the softest direction, so its correct step is ~250x the old
  # 3e-4 and its reach into the kink map is ~250x larger. A kink-straddle check
  # run at the scalar step was reassuring about a step the Hessian did not take.
  h_reach <- abs(.from_unc(u[["h_ml"]] + ARM_HESS_EPS_V[["h_ml"]],
                           CCX_PARAM_TABLE$h_ml) - h_mode)
  h_gap <- if (length(ARM_KINKS)) min(abs(ARM_KINKS - h_mode)) else Inf
  kink_hit <- h_gap <= h_reach
  cat(sprintf("[%s] h_ml mode %.4f m; nearest kink %.2f m away; the Hessian step reaches %.2e m\n",
              mode, h_mode, h_gap, h_reach))
  if (kink_hit)
    cat(sprintf("*** [%s] THE HESSIAN'S h_ml ROW STRADDLES A KINK -- log|-H| and therefore\n*** [%s] this arm's Laplace evidence are NOT reliable. See diag_hess_eps_21par.R.\n",
                mode, mode))

  # DIAGONAL STEP-STABILITY AT THE MODE ITSELF. The pre-refit sweep could only
  # be run at points that were not modes; this is the same test at the point
  # that actually carries the evidence. A coordinate whose curvature moves with
  # the step is named here rather than silently entering the determinant.
  # RE-USES ccx_hessian_per_direction()'s OWN verification (2026-08-23) rather
  # than repeating it. This block used to re-run the eps x (1/3, 1, 3) sweep at
  # the retired SCALAR step -- so it certified the stability of a step the
  # Hessian did not take, which is worse than not checking. HD$verify is the
  # same sweep around each direction's ACTUAL step, and HD$unstable applies the
  # tighter CCX_HESS_STABLE_TOL (0.02) than the 0.25 used here before.
  dstab    <- HD$verify
  unstable <- HD$unstable
  cat(sprintf("[%s] curvature step-stability at the mode (eps x 1/3, 1, 3): %s\n", mode,
              if (length(unstable)) paste("UNSTABLE at", paste(unstable, collapse = ", "))
              else "all 21 coordinates stable"))

  Sigma <- tryCatch(solve(-H), error = function(e) NULL)
  ok_pd <- !is.null(Sigma) && all(is.finite(Sigma)) && all(diag(Sigma) > 0)
  # The Laplace evidence's second term. NA when the Hessian is not PD, which is
  # reported rather than patched -- a non-PD Hessian means this arm has no
  # Laplace evidence, not that it should be given one.
  ldet <- tryCatch({
    ch <- chol(-H); 2 * sum(log(diag(ch)))
  }, error = function(e) NA_real_)
  Cor <- sdv <- ev <- NULL
  if (ok_pd) {
    sdv <- sqrt(diag(Sigma)); Cor <- Sigma / outer(sdv, sdv)
    ev <- eigen(Sigma, symmetric = TRUE)
    cat(sprintf("[%s] Laplace covariance: PD, condition number %.3g\n",
                mode, max(abs(ev$values)) / min(abs(ev$values))))
  } else {
    cat(sprintf("[%s] Laplace covariance: NOT PD -- no evidence for this arm\n", mode))
  }
  el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  cat(sprintf("[%s] mode log-post = %.1f  (gain over init %.1f)\n", mode, lp_mode, lp_mode - lp0))
  cat(sprintf("[%s] elapsed %.1f min, %d evaluations (%.3f s/eval)\n",
              mode, el, n_eval, el * 60 / n_eval))
  cat(sprintf("\n[%s] mode, natural scale:\n", mode)); print(round(unlist(pm), 4))

  out <- list(pump_mode = mode, u_mode = u, par_mode = pm, logpost = lp_mode,
              logpost_init = lp0, hessian = H, cov = Sigma, cor = Cor, sd_unc = sdv,
              eigen = ev, pd = ok_pd, logdet_negH = ldet, trace = trace,
              hess_eps = ARM_HESS_EPS_V, hess_eps_verify = dstab,
              hess_unstable = unstable, hml_kinks = ARM_KINKS,
              hml_kink_gap = h_gap, hml_hess_reach = h_reach, hml_kink_hit = kink_hit,
              hit_cap = hit_cap, streams = streams, n_eval = n_eval, minutes = el,
              hess_eps_frac = HD$eps_frac, hess_sd_diag = HD$sd_diag,
              hess_eps_grid = HD$curvature_by_step, hess_eps_no_plateau = HD$no_plateau,
              seed = ARM_SEED, param_names = CCX_PARAM_NAMES, prior_z = zs,
              kz_bracket = c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi),
              # RECORDED FROM 2026-08-20r, and it should have been from the
              # start: the refit OVERRIDES h_ml's bounds in-process, and the
              # 08-18 files did not say so -- decoding their `u_mode` under the
              # default [30, 200] gave 81.75 / 46.46 m and flipped the arm margin
              # to -34.63 before the producer was read (ccx_hml_band_provenance).
              # `par_mode` is band-independent; `u_mode`, `hessian` and `cov` are
              # NOT, and cannot be decoded without this field.
              hml_bound = c(CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi),
              substeps = ccx_substeps_for(p_mode))
  saveRDS(out, ARM_OUT(mode))
  cat(sprintf("[%s] wrote %s\n", mode, ARM_OUT(mode)))
  out
}

fits <- list()
for (m in ARM_MODES) fits[[m]] <- arm_fit(m)

# ---------------------------------------------------------------------
# The comparison is BETWEEN arms, so it runs only when there are two. With one
# arm it is skipped explicitly rather than left to fail on `fits$D` being NULL --
# a single-arm run must end by writing its mode, not by erroring after 18 hours
# of fitting.
ev_d <- NA_real_
if (length(ARM_MODES) < 2L) {
  sep("COMPARISON SKIPPED -- ONE ARM")
  cat(sprintf("ARM_MODES = %s. See the ARM_MODES block for why D is not re-run.\n",
              paste(ARM_MODES, collapse = ", ")))
} else {
sep("COMPARISON")
N <- fits$N; D <- fits$D
cat(sprintf("%-28s %14s %14s %14s\n", "", "N", "D", "D - N"))
cat(sprintf("%-28s %14.2f %14.2f %+14.2f\n", "log-posterior at MAP",
            N$logpost, D$logpost, D$logpost - N$logpost))
cat(sprintf("%-28s %14.2f %14.2f %+14.2f\n", "0.5 log|-H|",
            0.5 * N$logdet_negH, 0.5 * D$logdet_negH,
            0.5 * (D$logdet_negH - N$logdet_negH)))
ev_d <- (D$logpost - N$logpost) - 0.5 * (D$logdet_negH - N$logdet_negH)
cat(sprintf("%-28s %14s %14s %+14.2f\n", "LAPLACE log-evidence D-N", "", "", ev_d))
cat("\n(The (d/2) log 2pi term cancels: both arms carry the same 20 parameters.)\n")
cat("READ THIS AS INDICATIVE, NOT AS A BAYES FACTOR -- see the header. A pinned\n")
cat("`kz` makes the posterior non-Gaussian in that direction, and the Hessian\n")
cat("there reports the transformed coordinate's curvature, not a free one's.\n")
}

if (length(ARM_MODES) >= 2L && !is.null(fits$N$streams) && !is.null(fits$D$streams)) {
  N <- fits$N; D <- fits$D
  sep("PER-STREAM: which rows does D buy, and which does it sell?")
  nm <- union(names(N$streams), names(D$streams))
  nm <- setdiff(nm, "total")
  dd <- vapply(nm, function(s) {
    a <- N$streams[[s]]; bq <- D$streams[[s]]
    if (is.null(a) || is.null(bq)) return(NA_real_)
    as.numeric(bq) - as.numeric(a)
  }, numeric(1))
  dd <- sort(dd[is.finite(dd) & abs(dd) > 0.5], decreasing = TRUE)
  for (s in names(dd)) cat(sprintf("  %-26s %+10.2f\n", s, dd[[s]]))
  cat("\nThe pre-refit reading was that D's gain was ENTIRELY the CO2 record.\n")
  cat("This table either confirms that or shows a refit reallocating it.\n")
}

sep("THE STANDING QUESTIONS THIS RUN WAS ALSO MEANT TO ANSWER")
for (m in ARM_MODES) {
  f <- fits[[m]]; kb <- f$kz_bracket
  cat(sprintf("[%s] kz = %.1f (%.1f %% up the re-bisected bracket [%g, %g])\n",
              m, f$par_mode$kz, 100 * (f$par_mode$kz - kb[1]) / (kb[2] - kb[1]), kb[1], kb[2]))
  cat(sprintf("[%s] h_ml = %.2f -- rows SCORED (option 5); sd_eff/sd_obs %.3f / %.3f / %.3f
",
              m, f$par_mode$h_ml,
              ccx_ocean_sigma_eff("dic",  f$par_mode$h_ml) / ccx_ocean_gradient_target()$dic$sd,
              ccx_ocean_sigma_eff("d13c", f$par_mode$h_ml) / ccx_ocean_gradient_target()$d13c$sd,
              ccx_ocean_sigma_eff("alk",  f$par_mode$h_ml) / ccx_ocean_gradient_target()$alk$sd))
  cat(sprintf("[%s] pump_grad = %.2f  (prior centre %.2f, 1-D optimum at the old mode 274.5)\n",
              m, f$par_mode$pump_grad, ccx_const("PUMP_GRAD_OBS")))
}

saveRDS(list(fits = fits, evidence_D_minus_N = ev_d, seed = ARM_SEED,
             modes = ARM_MODES, param_names = CCX_PARAM_NAMES),
        file.path(ARM_OUTDIR, "pump_arms_comparison.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(ARM_OUTDIR, "pump_arms_comparison.rds")))
