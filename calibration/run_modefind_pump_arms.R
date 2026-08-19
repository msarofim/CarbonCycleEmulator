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
ARM_HESS_EPS   <- 3e-4      # step on the unconstrained scale; see run_modefind.R
ARM_FLAG_SIGMA <- 3.0       # prior-sd distance at which a parameter is flagged
ARM_MODES      <- c("N", "D")
# h_ml IS BOUNDED TO THE GRADIENT ROWS' VALIDITY BAND FOR THIS REFIT (Marcus
# 2026-08-16g). See the block below for what that does and does not buy.
ARM_HML_BOUND  <- LIK_OCEAN_GRAD_HML_OK   # [85, 120]
ARM_HML_INIT   <- 100      # m; the pump's own h_ml (DESIGN sec.5.2f, handoff 15d)
                           # and the depth every pump diagnostic scores at. The
                           # SHIPPED init of 75 is outside the new bound and would
                           # make .to_unc() return NaN, so this is not cosmetic.
ARM_OUTDIR     <- ccx_path("calibration", "output", "pump_arms")
ARM_OUT        <- function(m) file.path(ARM_OUTDIR, sprintf("mode_fit_pump%s.rds", m))
ARM_KINK_STEP  <- 0.01     # h_ml resolution the kink scan below runs at
ARM_KINK_FACT  <- 20       # a kink = this many times the median slope jump

dir.create(ARM_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

cat(sprintf("REFIT, TWO ARMS. %d parameters: %s\n",
            length(CCX_PARAM_NAMES), paste(CCX_PARAM_NAMES, collapse = ", ")))
cat(sprintf("kz bracket [%g, %g] (re-bisected for the pump 2026-08-16e)\n",
            CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi))
cat(sprintf("pump default %.6f umol/kg = PUMP_GRAD_OBS\n",
            ccx_default_params()$pump_grad))

# =====================================================================
# h_ml BOUNDED TO [85, 120] FOR THIS REFIT -- Marcus 2026-08-16g
# =====================================================================
# WHY, in one line: outside LIK_OCEAN_GRAD_HML_OK all three ocean-gradient rows
# SKIP, so an unbounded refit scores a DIFFERENT OBJECTIVE from the one the pump
# was introduced to be tested against -- and the smoke test found BOTH arms
# landing there and diverging to unrelated corners (handoff 16f sec.5.3). Bounded,
# both arms are scored on all three rows and the N-vs-D contrast is a comparison
# rather than noise.
#
# WHAT THE DECOMPOSITION SAYS THIS COSTS, AND WHAT IT DOES NOT SAY
# (calibration/diag_hml_band_discontinuity.R, DESIGN sec.5.2k):
#
#  * The band's cliff is EXACTLY "the three rows appeared", to 1e-12 -- h_ml = 85
#    is not a worse FIT than 84.99, it is scored on MORE DATA.
#  * The rows are NOT why h_ml leaves the band. At init the objective pulls h_ml
#    to its lower bound with 236 log-units against the cliff's 10.0, and deleting
#    the three rows entirely moves the argmax 32 -> 32 m. So this bound is not
#    settling a close call; it is OVERRIDING a real preference.
#  * That 236 IS AN UPPER BOUND AND PROBABLY A LARGE OVERSTATEMENT of what it
#    costs a refit: 96 % of it sits on co2_level_SPO, co2_level_MLO and d14c_SH,
#    and `kz`, `k_w` and `beta_max` move ocean and land uptake directly. This run
#    is the test of whether they absorb it.
#
# THE THING TO WATCH, AND IT IS THE REASON THIS RUN IS INFORMATIVE EITHER WAY:
# if the CO2-level streams recover at h_ml in-band, the bound was cheap and the
# refit is clean. IF THEY DO NOT -- if co2_level_SPO/MLO stay large in both arms
# -- then `h_ml` was absorbing a CO2-level misfit that no other parameter can
# take, both modes are bad, and N-vs-D is uninformative AGAIN. The per-stream
# table at (b3) is where that is read, and it must be read BEFORE the evidence.
#
# HOW IT IS DONE: by overriding CCX_PARAM_TABLE's `h_ml` entry IN THIS PROCESS
# ONLY. R/calibrate.R is NOT edited -- the bound is a property of this refit, not
# of the model, and every diagnostic that runs tomorrow must still see [30, 200].
# The prior is narrowed WITH the bounds: leaving dunif(30, 200) would keep a
# density normalised over a support the sampler can no longer reach. That changes
# the log-prior by a CONSTANT log(170/35) = +1.58, identical in both arms, so it
# cancels from the evidence contrast -- but it is stated because a constant that
# is not identical between arms would not.
#
# CONSEQUENCE, LOUDLY: this objective is a DIFFERENT FUNCTION from the unbounded
# one. Its logpost is NOT comparable with any earlier run's, on either side of the
# 2026-08-16 boundary. Only the N-vs-D contrast WITHIN this run is meaningful.
sep("h_ml BOUNDED FOR THIS REFIT (Marcus 2026-08-16g)")
# The snapshot is of the WHOLE table, not of the h_ml entry. GATE H1's first draft
# compared each entry against itself for every name but h_ml -- a tautology that
# could never have detected a change to a second parameter, which is the only
# thing it exists to detect.
.tab_before <- CCX_PARAM_TABLE
.hml_before <- CCX_PARAM_TABLE$h_ml
CCX_PARAM_TABLE$h_ml$lo    <- ARM_HML_BOUND[1]
CCX_PARAM_TABLE$h_ml$hi    <- ARM_HML_BOUND[2]
CCX_PARAM_TABLE$h_ml$init  <- ARM_HML_INIT
CCX_PARAM_TABLE$h_ml$prior <-
  local({ lo <- ARM_HML_BOUND[1]; hi <- ARM_HML_BOUND[2]
          function(x) stats::dunif(x, lo, hi, log = TRUE) })
cat(sprintf("h_ml: [%g, %g] init %g   ->   [%g, %g] init %g\n",
            .hml_before$lo, .hml_before$hi, .hml_before$init,
            CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi,
            CCX_PARAM_TABLE$h_ml$init))
cat(sprintf("prior renormalised over the new support: log-prior shifts by %+.4f\n",
            log((.hml_before$hi - .hml_before$lo) /
                (ARM_HML_BOUND[2] - ARM_HML_BOUND[1]))))

# GATE H1: ONLY h_ml changed, and it changed in exactly the four documented ways.
.chg <- names(which(!vapply(CCX_PARAM_NAMES, function(n)
  identical(CCX_PARAM_TABLE[[n]], .tab_before[[n]]), logical(1))))
if (!identical(.chg, "h_ml"))
  stop("the h_ml override touched more than h_ml: ", paste(.chg, collapse = ", "))
# and it must have changed h_ml in exactly the four documented fields
.fld <- names(which(!vapply(names(.hml_before), function(f)
  identical(CCX_PARAM_TABLE$h_ml[[f]], .hml_before[[f]]), logical(1))))
if (!setequal(.fld, c("lo", "hi", "init", "prior")))
  stop("h_ml changed in unexpected fields: ", paste(.fld, collapse = ", "))
# GATE H2: the new init must be strictly inside the new bound and round-trip
# finitely through the transform. The SHIPPED init of 75 fails this, which is the
# whole reason ARM_HML_INIT exists -- qlogis of a negative number is NaN and the
# mode-find would have started from a non-finite point.
.u_h <- .to_unc(ARM_HML_INIT, CCX_PARAM_TABLE$h_ml)
stopifnot(ARM_HML_INIT > ARM_HML_BOUND[1], ARM_HML_INIT < ARM_HML_BOUND[2],
          is.finite(.u_h),
          abs(.from_unc(.u_h, CCX_PARAM_TABLE$h_ml) - ARM_HML_INIT) < 1e-9)
stopifnot(!is.finite(suppressWarnings(.to_unc(.hml_before$init, CCX_PARAM_TABLE$h_ml))))
cat(sprintf("GATE H1: only `h_ml` changed. GATE H2: init %g round-trips (u = %+.4f);\n",
            ARM_HML_INIT, .u_h))
cat(sprintf("         the shipped init %g is correctly REJECTED by the new bound. OK\n",
            .hml_before$init))
# GATE H3: the gradient rows must actually be LIVE at the new init -- the entire
# point of the bound. Asserted on ccx_ocean_grad_scored()'s own return, not on the
# band arithmetic, so a change to the gate's internals cannot pass this silently.
.sp_h <- ccx_spinup(local({ p <- ccx_default_params(); p$h_ml <- ARM_HML_INIT; p }))
.F_h  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                           bomb_total_kmol = 102)
.F_h$c14_cosmo <- .sp_h$prod_c14
.og_h <- ccx_ocean_grad_scored(ccx_run_fast(.sp_h, .F_h)$out, .sp_h)
if (is.null(.og_h))
  stop("GATE H3 FAILED: the gradient rows are ABSENT at h_ml = ", ARM_HML_INIT,
       " -- the bound does not do what it was chosen to do")
cat(sprintf("GATE H3: all three rows LIVE at init (DIC %+.2f, d13C %+.4f, ALK %+.2f). OK\n",
            .og_h$dic, .og_h$d13c, .og_h$alk))
rm(.tab_before, .hml_before, .chg, .fld, .u_h, .sp_h, .F_h, .og_h)

# =====================================================================
# THE h_ml DIRECTION IS PIECEWISE-C1, AND THE HESSIAN HAS TO KNOW WHERE.
#
# calibration/diag_hess_eps_21par.R, run before this refit was launched, found
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
  kh <- seq(ARM_HML_BOUND[1], ARM_HML_BOUND[2], by = ARM_KINK_STEP)
  KS <- t(sapply(kh, function(h) ccx_pump_shape(ccx_ocean_grid(h))))
  kt <- rowSums(abs(apply(KS, 2, function(v) diff(diff(v)))))
  kb <- which(kt > ARM_KINK_FACT * stats::median(kt) + 1e-14)
  if (!length(kb)) return(numeric(0))
  unname(vapply(split(kb, cumsum(c(TRUE, diff(kb) > 1))),
                function(ix) kh[ix[which.max(kt[ix])] + 1], numeric(1)))
})
cat(sprintf("%d kink(s) in [%g, %g]: h_ml = %s m\n", length(ARM_KINKS),
            ARM_HML_BOUND[1], ARM_HML_BOUND[2],
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
b <- lapply(ARM_MODES, function(m) { p <- ccx_default_params(); p$pump_mode <- m; p })
names(b) <- ARM_MODES
d <- names(which(!vapply(names(b$N), function(n) identical(b$N[[n]], b$D[[n]]), logical(1))))
if (!identical(d, "pump_mode"))
  stop("the two arms differ in more than pump_mode: ", paste(d, collapse = ", "))
cat(sprintf("GATE: the arms differ in `pump_mode` and nothing else. OK\n"))

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
  t0 <- Sys.time()

  # ---- (a) Nelder-Mead restarts -------------------------------------
  u <- u0; best <- -lp0
  trace <- data.frame(restart = 0L, logpost = lp0, evals = 0L)
  for (i in seq_len(ARM_RESTARTS)) {
    fit <- optim(u, neg_lp, method = "Nelder-Mead",
                 control = list(maxit = ARM_MAXIT, reltol = 1e-12))
    gain <- best - fit$value
    u <- fit$par; best <- fit$value
    cat(sprintf("[%s] restart %2d: log-post = %12.1f  (gain %10.4f)  evals %d\n",
                mode, i, -best, gain, n_eval))
    trace <- rbind(trace, data.frame(restart = i, logpost = -best, evals = n_eval))
    if (i > 1 && gain < ARM_TOL) { cat("converged: gain below ARM_TOL\n"); break }
  }
  # FLAGGED, not silently accepted: a run that used every restart while still
  # gaining is a truncated climb, and the 2026-08-12 refit did exactly that.
  hit_cap <- nrow(trace) - 1L >= ARM_RESTARTS &&
    (trace$logpost[nrow(trace)] - trace$logpost[nrow(trace) - 1L]) >= ARM_TOL
  if (hit_cap)
    cat(sprintf("*** [%s] HIT THE RESTART CAP WHILE STILL GAINING -- this mode is NOT converged\n",
                mode))

  # ---- (b) BFGS polish ----------------------------------------------
  pol <- tryCatch(
    optim(u, neg_lp, method = "BFGS", control = list(maxit = 500, reltol = 1e-14)),
    error = function(e) { cat("BFGS polish failed:", conditionMessage(e), "\n"); NULL })
  if (!is.null(pol) && pol$value < best) {
    cat(sprintf("[%s] BFGS polish: log-post = %.1f (gain %.4f)\n",
                mode, -pol$value, best - pol$value))
    u <- pol$par; best <- pol$value
  } else cat(sprintf("[%s] BFGS polish: no improvement\n", mode))
  names(u) <- CCX_PARAM_NAMES
  lp_mode <- -best
  pm <- ccx_unc_to_par(u)

  # ---- (b2) physical-plausibility screen ----------------------------
  prior_z <- function(n) {
    s <- CCX_PARAM_TABLE[[n]]; x <- pm[[n]]; g <- s$prior
    lo <- x / 1e3; hi <- x * 1e3
    if (s$tr == "logit") { lo <- s$lo + 1e-9; hi <- s$hi - 1e-9 }
    xs <- seq(lo, hi, length.out = 4001)
    dd <- exp(vapply(xs, function(z) g(z), numeric(1)))
    dd[!is.finite(dd)] <- 0
    if (sum(dd) <= 0) return(NA_real_)
    cdf <- cumsum(dd) / sum(dd)
    qnorm(min(max(approx(xs, cdf, xout = x, rule = 2)$y, 1e-12), 1 - 1e-12))
  }
  zs <- vapply(CCX_PARAM_NAMES,
               function(n) tryCatch(prior_z(n), error = function(e) NA_real_), numeric(1))
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
    el <- ccx_forcing_eluc_annual(F); el$eluc <- el$eluc * pm$luc_scale
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
  cat(sprintf("[%s] hessian: central differences, %d parameters\n", mode, length(u)))
  H <- local({
    n <- length(u); M <- matrix(NA_real_, n, n); eps <- ARM_HESS_EPS
    for (a in seq_len(n)) for (bb in a:n) {
      ea <- eb <- numeric(n); ea[a] <- eps; eb[bb] <- eps
      M[a, bb] <- M[bb, a] <-
        (lp_fun(u + ea + eb) - lp_fun(u + ea - eb) -
           lp_fun(u - ea + eb) + lp_fun(u - ea - eb)) / (4 * eps^2)
    }
    M
  })
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
  h_reach <- abs(.from_unc(u[["h_ml"]] + ARM_HESS_EPS, CCX_PARAM_TABLE$h_ml) - h_mode)
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
  dstab <- local({
    es <- ARM_HESS_EPS * c(1/3, 1, 3)
    D <- sapply(es, function(e) vapply(seq_along(u), function(k2) {
      ee <- numeric(length(u)); ee[k2] <- e
      fp <- lp_fun(u + ee); fm <- lp_fun(u - ee)
      if (!is.finite(fp) || !is.finite(fm)) return(NA_real_)
      (fp - 2 * lp_mode + fm) / e^2
    }, numeric(1)))
    rownames(D) <- CCX_PARAM_NAMES; colnames(D) <- format(es, scientific = TRUE)
    D
  })
  spread <- apply(dstab, 1, function(r) { r <- r[is.finite(r)]
    if (length(r) < 2) Inf else (max(r) - min(r)) / abs(mean(r)) })
  unstable <- names(which(spread > 0.25))
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
              hess_eps = ARM_HESS_EPS, hess_diag_by_step = dstab,
              hess_unstable = unstable, hml_kinks = ARM_KINKS,
              hml_kink_gap = h_gap, hml_hess_reach = h_reach, hml_kink_hit = kink_hit,
              hit_cap = hit_cap, streams = streams, n_eval = n_eval, minutes = el,
              seed = ARM_SEED, param_names = CCX_PARAM_NAMES, prior_z = zs,
              kz_bracket = c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi),
              substeps = ccx_substeps_for(p_mode))
  saveRDS(out, ARM_OUT(mode))
  cat(sprintf("[%s] wrote %s\n", mode, ARM_OUT(mode)))
  out
}

fits <- list()
for (m in ARM_MODES) fits[[m]] <- arm_fit(m)

# ---------------------------------------------------------------------
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

if (!is.null(N$streams) && !is.null(D$streams)) {
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
  cat(sprintf("[%s] h_ml = %.2f -- gradient rows LIVE only inside [%g, %g]: %s\n",
              m, f$par_mode$h_ml, LIK_OCEAN_GRAD_HML_OK[1], LIK_OCEAN_GRAD_HML_OK[2],
              if (f$par_mode$h_ml >= LIK_OCEAN_GRAD_HML_OK[1] &&
                  f$par_mode$h_ml <= LIK_OCEAN_GRAD_HML_OK[2]) "LIVE" else "*** ABSENT ***"))
  cat(sprintf("[%s] pump_grad = %.2f  (prior centre %.2f, 1-D optimum at the old mode 274.5)\n",
              m, f$par_mode$pump_grad, ccx_const("PUMP_GRAD_OBS")))
}

saveRDS(list(fits = fits, evidence_D_minus_N = ev_d, seed = ARM_SEED,
             modes = ARM_MODES, param_names = CCX_PARAM_NAMES),
        file.path(ARM_OUTDIR, "pump_arms_comparison.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(ARM_OUTDIR, "pump_arms_comparison.rds")))
