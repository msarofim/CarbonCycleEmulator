# =====================================================================
# diag_pump_kz_degeneracy.R -- IS A FITTED `pump_grad` JUST DOING `kz`'s JOB?
# (the prerequisite I asked for before fitting it; Marcus 2026-08-16d decided
#  the pump ships ON and `pump_grad` is FITTED with its prior on the observed
#  233.109, conditional on this check)
#
# THE QUESTION. `diag_pump_grad_profile.R` profiled `pump_grad` with all 19
# parameters HELD. That is exactly the condition under which a new parameter
# looks best: nothing else is allowed to do its job. `kz` is the obvious rival --
# the export field is SOLVED against the model's own diffusion, so the pump's
# size is a statement about `kz` as much as about biology (DESIGN sec.5.2c) --
# and if the two are near-degenerate then fitting `pump_grad` buys a parameter
# that mostly re-expresses one we already have, with all the sampling pathology
# that implies.
#
# WHY THIS IS NOT ALREADY ANSWERED. diag_ocean_candidates.R established that
# TRANSPORT CANNOT MOVE THE DIC AND d13C GRADIENTS -- proved from the structure,
# not measured -- which is why the pump exists at all. If that holds, the two
# rows that constrain `pump_grad` most sharply are rows `kz` cannot touch, and
# the parameters are not degenerate ON THOSE ROWS. But they meet on a THIRD row:
# both move deep D14C. `kz` is hard-bracketed to [3830, 6200] BECAUSE of that row
# (calibrate.R: unbounded it ran to 10,686 and put the deep ocean at -129.9
# permil against an observed -150 to -200), and the pre-gradient mode sits at
# 6119.25 -- 96.6 % up the bracket, i.e. pinned. The pump makes deep water OLDER
# (z_deep14 +1.70 -> +1.08, handoff 15d clause 3). So the real question is
# whether the pump RELIEVES the constraint that pinned `kz`, and that is a
# 2-D question no 1-D profile can answer.
#
# ---------------------------------------------------------------------
# PRE-REGISTERED PREDICTIONS, written before any arm was run.
#
#   P1 (the decision-relevant one). The correlation between `pump_grad` and `kz`
#      in the local Hessian is MODEST, |rho| < 0.5, because the rows that pin
#      `pump_grad` (DIC, d13C, ALK gradients) are rows transport cannot move.
#      If |rho| > 0.8 the parameters ARE near-degenerate and "fit it" should go
#      back to Marcus as a question rather than into calibrate.R.
#
#   P2. With the pump ON, `kz` presses HARDER against its upper bound, not
#      softer. The bracket restrains a likelihood that wants high `kz` for the
#      bomb window and uptake; the deep-D14C row is what resists, and the pump
#      supplies depletion from the other direction. I therefore expect the
#      pump to make the bound MORE binding, which would be an argument for
#      re-deriving the bracket at the refit rather than inheriting it.
#
#   P3. The `pump_grad` optimum moves only weakly with `kz` across the bracket
#      -- under ~15 % end to end -- since the pump delivers the gradient it
#      names by construction and only the pump-OFF baseline gradient is
#      kz-dependent.
#
# ---------------------------------------------------------------------
# WHAT THIS FILE DOES NOT DO. `h_ml` is held at PKZ_H_SCORE throughout, because
# the three gradient rows SKIP outside LIK_OCEAN_GRAD_HML_OK_RETIRED and the mode's own
# 183.95 is outside it. The full question is 3-D (`pump_grad` x `kz` x `h_ml`)
# and belongs to the refit; this is the 2-D slice that decides whether the refit
# should carry `pump_grad` as a free parameter at all. NO MODEL FILE IS TOUCHED.
#
# RUNTIME ~15 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PKZ_YEARS    <- c(1750, 2024)
PKZ_BOMB_REF <- 102
PKZ_H_SCORE  <- 100
PKZ_MODE     <- "N"
PKZ_OBS_GRAD <- 233.109
# The pump grid, spanning the 1-D optimum (274.5) with pump-OFF as the control
# column -- the OFF column is what makes the "does the pump move kz?" question
# answerable rather than assumed.
PKZ_GRAD_GRID <- c(0, 200, 245, 290, 335)
# The kz grid IS the bracket calibrate.R enforces, ends included. Going outside
# it would answer a question the sampler cannot ask.
PKZ_KZ_BRACKET <- c(3830, 6200)     # m2/yr; see calibrate.R's bisection
PKZ_KZ_GRID    <- c(3830, 4620, 5410, 6200)
PKZ_RHO_OK   <- 0.8          # |rho| at or above this = near-degenerate = STOP
PKZ_SINK_WIN <- c(2010, 2019)
PKZ_MODE_PATH <- ccx_path("calibration", "output", "quarantine",
                          "20260815_pre_gradient_terms", "mode_fit.rds")
PKZ_ERR_MODE <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                     grad_off_co2 = -0.549, grad_off_d13c = +0.107)
PKZ_GRAD_STREAMS <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk")
PKZ_OUTDIR   <- ccx_path("calibration", "output", "pump_kz_degeneracy")

dir.create(PKZ_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg), !is.null(tg$alk))
# ⚠ THE OUT-OF-BAND GUARD THAT STOOD HERE IS DELETED, 2026-08-28 (option 5).
# It asserted the scoring depth was inside [85, 120] so the rows would not
# SKIP; the rows are now scored at every h_ml, so the guard was vacuous.
# The depth stays a deliberate CHOICE, not a constraint.
cat(sprintf("GATE A: the rows are scored at h_ml = %g m; since 2026-08-28 they are\n"
            , PKZ_H_SCORE))
cat(sprintf("        LIVE at EVERY h_ml, at sd_eff/sd_obs %.3f / %.3f / %.3f.\n",
            ccx_ocean_sigma_eff("dic",  PKZ_H_SCORE) / tg$dic$sd,
            ccx_ocean_sigma_eff("d13c", PKZ_H_SCORE) / tg$d13c$sd,
            ccx_ocean_sigma_eff("alk",  PKZ_H_SCORE) / tg$alk$sd))

obs <- ccx_prepare_obs()
base_forc <- ccx_build_forcing("historical", PKZ_YEARS, prod_c14 = 0,
                               bomb_total_kmol = PKZ_BOMB_REF)
tg_d14 <- ccx_deep_d14c_target()

pkz_eval <- function(p, grad, kz, bomb_total, luc_scale) {
  p$h_ml <- PKZ_H_SCORE; p$kz <- kz
  p$pump_grad <- grad; p$pump_mode <- PKZ_MODE
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp)) return(NULL)
  F <- base_forc
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forc$c14_bomb * (bomb_total / PKZ_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forc[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forc); eluc$eluc <- eluc$eluc * luc_scale
  r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  og <- ccx_ocean_grad_scored(r$out, sp)
  if (is.null(og)) stop("ocean_grad scored NULL -- the rows skipped")
  ps <- ccx_loglik(r$out, obs, PKZ_ERR_MODE, luc = eluc,
                   deep = sp$diagnostics$d14c_bottom_box, ocean_grad = og,
                   by_stream = TRUE)
  yr <- floor(r$out$t + 1e-9); ann <- tapply(r$out$ocean_C, yr, mean)
  yy <- as.integer(names(ann))
  k  <- which(yy >= PKZ_SINK_WIN[1] & yy <= PKZ_SINK_WIN[2])
  list(grad = grad, kz = kz, total = sum(ps), parts = ps,
       grad_logL = sum(ps[intersect(PKZ_GRAD_STREAMS, names(ps))]),
       deep_logL = if ("d14c_deep_ocean" %in% names(ps)) ps[["d14c_deep_ocean"]] else NA_real_,
       z_dic  = (og$dic  - tg$dic$target)  / tg$dic$sd,
       z_d13c = (og$d13c - tg$d13c$target) / tg$d13c$sd,
       z_alk  = (og$alk  - tg$alk$target)  / tg$alk$sd,
       z_d14  = (sp$diagnostics$d14c_bottom_box - tg_d14$target) / tg_d14$sd,
       deep14 = sp$diagnostics$d14c_bottom_box,
       sink   = if (length(k) > 1) mean(diff(ann[k])) else NA_real_)
}

sep("PART 0. THE OPERATING POINT")
pm <- if (file.exists(PKZ_MODE_PATH)) readRDS(PKZ_MODE_PATH)$par_mode else NULL
if (is.null(pm)) stop("quarantined mode absent -- this file scores at the mode")
pmode <- ccx_default_params()
for (n in intersect(names(pmode), names(pm))) pmode[[n]] <- pm[[n]]
pmode$gamma_enso <- pm$gamma_enso
cat(sprintf("MODE (pre-gradient, quarantined). Its OWN kz = %.2f, which is %.1f %% up\n",
            pm$kz, 100 * (pm$kz - PKZ_KZ_BRACKET[1]) / diff(PKZ_KZ_BRACKET)))
cat(sprintf("the bracket [%g, %g] that calibrate.R enforces. h_ml %.2f -> %g forced.\n",
            PKZ_KZ_BRACKET[1], PKZ_KZ_BRACKET[2], pm$h_ml, PKZ_H_SCORE))
cat(sprintf("grid: pump_grad %s  x  kz %s\n",
            paste(PKZ_GRAD_GRID, collapse = ", "), paste(PKZ_KZ_GRID, collapse = ", ")))

sep("PART 1. THE 2-D SURFACE")
cells <- expand.grid(grad = PKZ_GRAD_GRID, kz = PKZ_KZ_GRID)
res <- vector("list", nrow(cells))
for (i in seq_len(nrow(cells))) {
  t0 <- Sys.time()
  res[[i]] <- pkz_eval(pmode, cells$grad[i], cells$kz[i], pm$bomb_total, pm$luc_scale)
  cat(sprintf("  pump_grad %6.1f  kz %6.0f   %5.0f s\n", cells$grad[i], cells$kz[i],
              as.numeric(Sys.time() - t0, units = "secs")))
}
keep <- !vapply(res, is.null, logical(1))
res <- res[keep]; cells <- cells[keep, ]
tot <- vapply(res, `[[`, numeric(1), "total")

mat <- function(f) {
  m <- matrix(vapply(res, `[[`, numeric(1), f), nrow = length(PKZ_GRAD_GRID))
  dimnames(m) <- list(sprintf("%g", PKZ_GRAD_GRID), sprintf("%g", PKZ_KZ_GRID))
  m
}
show <- function(f, lab, fmt = "%9.1f") {
  m <- mat(f)
  cat(sprintf("\n%s   (rows = pump_grad, cols = kz)\n", lab))
  cat(sprintf("%10s", "")); for (cn in colnames(m)) cat(sprintf("%9s", cn)); cat("\n")
  for (rn in rownames(m)) {
    cat(sprintf("%10s", rn))
    for (cn in colnames(m)) cat(sprintf(fmt, m[rn, cn]))
    cat("\n")
  }
  m
}
M   <- show("total", "FULL logL")
Mg  <- show("grad_logL", "the THREE gradient rows only")
Md  <- show("z_d14", "z of deep D14C -- the row kz's bracket exists to protect", "%9.2f")
invisible(show("z_dic", "z_DIC", "%9.2f"))
invisible(show("z_d13c", "z_d13C", "%9.2f"))
invisible(show("z_alk", "z_ALK", "%9.2f"))
invisible(show("sink", "ocean sink 2010-2019, GtC/yr", "%9.3f"))

sep("PART 2. THE RIDGE -- P3")
# For each kz, the pump_grad the objective prefers (quadratic through the best
# interior triple of the PUMPED arms; the OFF column is a control, not a point
# on the pump's own profile).
ridge <- lapply(seq_along(PKZ_KZ_GRID), function(j) {
  x <- PKZ_GRAD_GRID[PKZ_GRAD_GRID > 0]
  y <- M[as.character(x), j]
  i <- which.max(y)
  if (i == 1 || i == length(x)) return(list(kz = PKZ_KZ_GRID[j], g = x[i], edge = TRUE))
  cf <- coef(lm(y[(i-1):(i+1)] ~ poly(x[(i-1):(i+1)], 2, raw = TRUE)))
  list(kz = PKZ_KZ_GRID[j], g = -cf[2] / (2 * cf[3]), edge = FALSE)
})
cat(sprintf("%10s %14s %10s\n", "kz", "best pump_grad", "as a scale"))
for (r in ridge)
  cat(sprintf("%10.0f %14.1f %10.3f%s\n", r$kz, r$g, r$g / PKZ_OBS_GRAD,
              if (r$edge) "   AT A GRID EDGE" else ""))
gr   <- vapply(ridge, function(r) as.numeric(r$g), numeric(1))
edge <- vapply(ridge, function(r) isTRUE(r$edge), logical(1))
spread <- (max(gr) - min(gr)) / mean(gr)
# A RIDGE POINT AT A GRID EDGE IS NOT A MEASUREMENT, and the first run of this
# file reported a bare "FAIL -- entangled" off exactly that: three of the four
# kz columns peaked at the TOP of PKZ_GRAD_GRID, so their optima are unresolved
# lower bounds and the spread computed from them is a property of my grid.
if (any(edge)) {
  cat(sprintf("\nP3: UNRESOLVED. %d of %d kz columns peak at the top of the pump grid (%g),\n",
              sum(edge), length(edge), max(PKZ_GRAD_GRID)))
  cat("    so their optima are LOWER BOUNDS and the spread below is my grid's, not\n")
  cat("    the model's. Part 5 measures WHY they run away; the resolved column is\n")
  cat(sprintf("    kz = %g, and it is the one the posterior actually occupies (P2).\n",
              PKZ_KZ_GRID[!edge][length(PKZ_KZ_GRID[!edge])]))
  cat(sprintf("    apparent spread across the bracket: %.1f %% (NOT a verdict)\n", 100 * spread))
} else {
  cat(sprintf("\nP3: the optimum moves %.1f %% across the whole kz bracket. %s\n",
              100 * spread,
              if (spread < 0.15) "PASS (< 15 %) -- pump_grad is nearly kz-independent"
              else "FAIL -- the two are entangled more than predicted"))
}

sep("PART 3. THE HESSIAN AND THE CORRELATION -- P1, THE DECISION")
# A full 2-D quadratic in (pump_grad, kz) over the PUMPED cells. The correlation
# implied by its Hessian is the degeneracy statement: rho -> +/-1 means the two
# parameters trade off along a ridge and fitting both buys one direction.
d <- data.frame(g = vapply(res, `[[`, numeric(1), "grad"),
                k = vapply(res, `[[`, numeric(1), "kz"),
                y = tot)
d <- d[d$g > 0, ]
# CENTRE AND SCALE, or the quadratic is fitted on columns 25 orders apart in
# magnitude and the Hessian is numerical noise dressed as a result.
gs <- sd(d$g); ks <- sd(d$k)
d$gc <- (d$g - mean(d$g)) / gs; d$kc <- (d$k - mean(d$k)) / ks
fit <- lm(y ~ gc + kc + I(gc^2) + I(kc^2) + gc:kc, data = d)
cf <- coef(fit)
H <- matrix(c(2 * cf[["I(gc^2)"]], cf[["gc:kc"]],
              cf[["gc:kc"]],       2 * cf[["I(kc^2)"]]), 2, 2)
cat(sprintf("quadratic fit R^2 = %.4f on %d pumped cells\n", summary(fit)$r.squared, nrow(d)))
neg_def <- all(eigen(H)$values < 0)
cat(sprintf("Hessian negative definite: %s  (eigenvalues %s)\n", neg_def,
            paste(sprintf("%.2f", eigen(H)$values), collapse = ", ")))
if (neg_def) {
  V   <- solve(-H)                       # covariance in the SCALED coordinates
  rho <- V[1, 2] / sqrt(V[1, 1] * V[2, 2])
  sd_marg <- sqrt(V[1, 1]) * gs          # marginal sd of pump_grad, umol/kg
  sd_cond <- gs / sqrt(-H[1, 1])         # conditional on kz held
  cat(sprintf("\nrho(pump_grad, kz) = %+.3f\n", rho))
  cat(sprintf("sd(pump_grad):  conditional on kz  %.1f   marginal  %.1f  (inflation %.2fx)\n",
              sd_cond, sd_marg, sd_marg / sd_cond))
  cat(sprintf("\nP1 VERDICT: %s\n", if (abs(rho) < PKZ_RHO_OK)
      sprintf("|rho| = %.2f < %g -- NOT near-degenerate. Fitting pump_grad buys a\n  direction kz cannot supply, which is what the decision assumed.", abs(rho), PKZ_RHO_OK)
    else sprintf("|rho| = %.2f >= %g -- NEAR-DEGENERATE. Take this back to Marcus\n  before pump_grad goes into calibrate.R: a fitted pump_grad would mostly\n  re-express kz, with the sampling pathology that implies.", abs(rho), PKZ_RHO_OK)))
} else {
  rho <- NA_real_; sd_marg <- NA_real_; sd_cond <- NA_real_
  cat("\nThe quadratic is not negative definite on this grid -- the optimum is not\ninterior. Report the surface, NOT a correlation.\n")
}

sep("PART 4. DOES THE PUMP MOVE WHERE kz WANTS TO SIT? -- P2")
# The column-wise question, which is the one the kz bracket cares about.
off <- M["0", ]; best_pumped <- apply(M[rownames(M) != "0", , drop = FALSE], 2, max)
cat(sprintf("%10s %12s %12s %12s %12s\n", "kz", "logL OFF", "logL best", "z_d14 OFF", "z_d14 best"))
for (j in seq_along(PKZ_KZ_GRID)) {
  ib <- which.max(M[rownames(M) != "0", j])
  cat(sprintf("%10.0f %12.1f %12.1f %12.2f %12.2f\n", PKZ_KZ_GRID[j], off[j],
              best_pumped[j], Md["0", j], Md[rownames(Md) != "0", j][ib]))
}
kz_off  <- PKZ_KZ_GRID[which.max(off)]
kz_pump <- PKZ_KZ_GRID[which.max(best_pumped)]
cat(sprintf("\nkz preferred with the pump OFF: %g   with the pump ON: %g\n", kz_off, kz_pump))
cat(sprintf("P2 said the pump makes the UPPER bound MORE binding. %s\n",
            if (kz_pump >= kz_off && kz_pump == max(PKZ_KZ_GRID))
              "CONSISTENT -- kz still pins to the top of the bracket."
            else if (kz_pump < kz_off)
              "MEASURED FALSE -- the pump RELEASES kz downward. That is a finding about the bracket, not about the pump."
            else "neither -- read the columns."))
cat("\nEITHER WAY THE BRACKET IS A REFIT QUESTION: it was bisected at the DEFAULT\n")
cat("parameters on a model with NO pump, and the pump moves the very row\n")
cat("(deep D14C) the bisection was built on. Re-derive it at the refit rather\n")
cat("than inherit it -- calibrate.R's own comment asks for exactly that.\n")

sep("PART 5. WHY THE LOW-kz COLUMNS RUN AWAY -- the stream that pays")
# P3 came back UNRESOLVED, so ask what the runaway is BUYING rather than leave
# it as a loose end. Top of the pump grid against the arm below it, per stream,
# at the bracket's two ends.
pkz_get <- function(g, k) {
  i <- which(vapply(res, function(e) e$grad == g && e$kz == k, logical(1)))
  if (length(i)) res[[i[1]]] else NULL
}
gtop <- max(PKZ_GRAD_GRID); gsub_ <- sort(PKZ_GRAD_GRID)[length(PKZ_GRAD_GRID) - 1]
for (k in range(PKZ_KZ_GRID)) {
  a <- pkz_get(gsub_, k); b <- pkz_get(gtop, k)
  if (is.null(a) || is.null(b)) next
  dd <- b$parts - a$parts[names(b$parts)]
  dd <- sort(dd[abs(dd) > 0.5], decreasing = TRUE)
  cat(sprintf("\nkz %g : pump_grad %g -> %g, total %+.1f\n", k, gsub_, gtop,
              b$total - a$total))
  for (s in names(dd)) cat(sprintf("   %-24s %+9.1f\n", s, dd[[s]]))
}
cat("\nREAD: at the bracket's BOTTOM the extra pump is bought by ATMOSPHERIC\n")
cat("RADIOCARBON, not by the gradient rows -- which LOSE. Mode N moves no carbon\n")
cat("into the ocean (the sink row is identical down every column above), but it\n")
cat("does carry 14C down, so an under-ventilated column uses the pump as a bomb-14C\n")
cat("sink. That is a real entanglement and it is OFF THE POSTERIOR'S SUPPORT: kz\n")
cat("pins to the bracket's TOP (P2), and there the same channel changes sign.\n")

saveRDS(list(cells = cells, res = res, M = M, Mg = Mg, Md = Md,
             ridge = ridge, rho = rho, sd_marg = sd_marg, sd_cond = sd_cond,
             kz_off = kz_off, kz_pump = kz_pump, kz_bracket = PKZ_KZ_BRACKET,
             h_score = PKZ_H_SCORE, pump_mode = PKZ_MODE),
        file.path(PKZ_OUTDIR, "diag_pump_kz_degeneracy.rds"))
cat(sprintf("\n\nwritten: %s\n",
            file.path(PKZ_OUTDIR, "diag_pump_kz_degeneracy.rds")))
