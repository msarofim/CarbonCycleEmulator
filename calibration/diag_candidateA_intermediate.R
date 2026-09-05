# =====================================================================
# diag_candidateA_intermediate.R -- DOES A DEPTH-DEPENDENT K_z FIX THE
#   INTERMEDIATE-DEPTH D14C PROFILE?
#
# DESIGN sec.3.4a licenses new ocean STRUCTURE "exactly when the cheaper
# candidates are measured and shown insufficient". Candidate A -- K(z)
# decaying with depth, ONE parameter, no new box -- was scored on
# 2026-08-15 on the DEEP row only. 2026-09-04j measured that the model's
# ventilation error is concentrated at INTERMEDIATE depth (mean z +3.30
# over 500-2500 m, max +4.49 at 1160 m) with the deep row nearly on
# target. So candidate A has never been scored where the problem is.
# Marcus, 2026-09-04j: "Test the depth-dependent K."
#
# ⛔ WHY THE EXISTING SHIM COULD NOT DO THIS. diag_ocean_candidates.R
# overrides `ccx_deriv`; `ccx_spinup()` calls `ccx_deriv_fast`, and its
# isotope state comes from iso_operator(), which builds its matrix by
# numerically differentiating `ccx_deriv_fast` column by column. So that
# shim is INERT on the preindustrial state -- mutation-tested 2026-09-04j,
# deep D14C identical to 3 dp with it on and off. THIS file shims
# `ccx_deriv_fast` instead, which iso_operator() then picks up for free.
#
# ⭐ THE CONTROL IS ISO-DEEP, NOT ISO-SINK. The August run held the ocean
# SINK because it compared logL. The question here is profile SHAPE, and
# the confound is that changing z_K at fixed kz changes total mixing. So
# kz is RE-SOLVED per z_K to hold the bottom box's D14C at the incumbent
# value, and the question becomes: AT THE SAME DEEP AGE, does the
# intermediate profile improve? ⚠ 2026-09-04i also measured that the
# ocean SINK cannot discriminate ocean structures at all (w_up and w_out
# differ hugely in deep D14C and agree to 1e-12 on the sink), so an
# iso-sink control would have had no power here anyway.
#
# ⚠ PREINDUSTRIAL STEADY STATE ONLY, so the scored band is restricted to
# layers where BOMB 14C is negligible. Measured bomb addition at the 2002
# bottle epoch: 4.5 permil at 1622 m, 0.5 at 2268 m, 0.0 at 3172 m --
# against an observed sd of 52-60, i.e. under 10 % of the noise. Layers
# shallower than that are PRINTED but NOT SCORED, and the peak of the
# error (1160 m, bomb +17.5) is deliberately outside the scored band.
#
# Usage:  Rscript calibration/diag_candidateA_intermediate.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

# ⚠⚠ TWO FAMILIES, because the repo's inherited form is NOT HILDA's.
# `oc_shape()` in diag_ocean_candidates.R uses K(z) = kz*exp(-(z-h_ml)/z_K):
# NO FLOOR (K -> 0 at depth) and the August grid swept z_K over 1200-5000 m.
# Siegenthaler & Joos (1992, Tellus 44B:186), sec.3(3) eq.1, fitted
#     K(z) = K0 + K1*exp(-(z - z_LS)/z0),  z_LS = 75 m
#     K0 = 465, K1 = 7096 m2/yr, z0 = 253 m
# -- a FLOOR plus a decay scale 5-20x SHORTER than the August grid. Their K
# runs 7561 at the mixed-layer base, 1788 at 500 m, 648 at 1000 m. So the
# August form is a much gentler, floorless decay and testing it does NOT test
# HILDA's. BOTH are scanned here and reported separately.
CA_ZK    <- c(Inf, 5000, 3000, 2000, 1200)   # the August (floorless) grid
# HILDA-form: (z0, floor fraction K0/(K0+K1)). The floor is expressed as a
# FRACTION so it survives kz being re-solved by the iso-deep control.
CA_HILDA_Z0   <- c(253, 253, 500, 1000)
CA_HILDA_FLOOR<- c(465 / (465 + 7096), 0.02, 465 / (465 + 7096), 465 / (465 + 7096))
CA_NEFF  <- LIK_D14C_DEEP_NEFF
CA_SCORED_MIN_DEPTH <- 1500                  # bomb <= 4.5 permil below this

# ---- THE SHIM, on ccx_deriv_fast --------------------------------------
.ca <- new.env(parent = emptyenv()); .ca$on <- FALSE; .ca$f <- NULL
.ca_base <- ccx_deriv_fast
ccx_deriv_fast <- function(y, t, p, forc, grid, aux) {
  dy <- .ca_base(y, t, p, forc, grid, aux)
  if (!.ca$on) return(dy)
  fk <- .ca$f
  for (h in HEMIS) {
    col <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
    for (k in seq_len(grid$nl)) {
      if (fk[k] == 1) next
      a <- col[k]; b <- col[k + 1]
      for (tr in CCX_TRACERS) {
        dF <- p$kz * (fk[k] - 1) *
          (y[a, tr] / grid$dz[k] - y[b, tr] / grid$dz[k + 1]) / aux$dz_mid[k]
        dy[a, tr] <- dy[a, tr] - dF
        dy[b, tr] <- dy[b, tr] + dF
      }
    }
  }
  dy
}
# floor = 0 reproduces the August form exactly; f is normalised to 1 at the ML
# base either way, so `kz` keeps its NATRE-comparable meaning in both families.
ca_shape <- function(grid, z_K, floor = 0) {
  z <- cumsum(grid$dz)[seq_len(grid$nl)]
  if (!is.finite(z_K)) return(rep(1, grid$nl))
  floor + (1 - floor) * exp(-(z - grid$h_ml) / z_K)
}

v0   <- dg_vector(CCX_MODE_CANONICAL)
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2

deep_of <- function(p, z_K, floor = 0) {
  if (is.finite(z_K)) { .ca$f <- ca_shape(grid, z_K, floor); .ca$on <- TRUE }
  on.exit(.ca$on <- FALSE)
  ccx_spinup(p)$diagnostics$d14c_bottom_box
}
prof_of <- function(p, z_K, floor = 0) {
  if (is.finite(z_K)) { .ca$f <- ca_shape(grid, z_K, floor); .ca$on <- TRUE }
  on.exit(.ca$on <- FALSE)
  sp <- ccx_spinup(p); aux <- sp$aux
  lay <- function(h) { ix <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
                       1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (lay("NH") * aux$a_oc$NH + lay("SH") * aux$a_oc$SH) / (aux$a_oc$NH + aux$a_oc$SH)
}

# ---- MUTATION GATE, before any result is read -------------------------
cat("=== MUTATION GATE ===\n")
d_off <- deep_of(v0$p, Inf)
.ca$f <- rep(1, grid$nl); .ca$on <- TRUE
d_one <- ccx_spinup(v0$p)$diagnostics$d14c_bottom_box; .ca$on <- FALSE
d_pert <- deep_of(v0$p, 1500)
cat(sprintf("  f == 1 is a NO-OP        : %.6f vs %.6f   %s\n", d_off, d_one,
            if (identical(d_off, d_one)) "PASS (bit-exact)" else "FAIL"))
cat(sprintf("  f = exp(-z/1500) BITES   : %.6f vs %.6f   %s\n", d_off, d_pert,
            if (abs(d_off - d_pert) > 1e-6) "PASS" else "FAIL -- the shim is INERT"))
if (!identical(d_off, d_one) || abs(d_off - d_pert) <= 1e-6)
  stop("candidate-A shim failed its mutation gate")

# ---- ISO-DEEP: re-solve kz per z_K -----------------------------------
cat(sprintf("\n=== ISO-DEEP CONTROL: kz re-solved to hold deep D14C at %.3f ===\n", d_off))
solve_kz <- function(z_K, floor = 0) {
  if (!is.finite(z_K)) return(v0$p$kz)
  f <- function(lk) { p <- v0$p; p$kz <- exp(lk); deep_of(p, z_K, floor) - d_off }
  lo <- log(v0$p$kz); hi <- log(v0$p$kz)
  while (f(lo) > 0) lo <- lo - 0.25
  while (f(hi) < 0) hi <- hi + 0.25
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
ARMS <- list(list(lab = "Inf", zk = Inf, fl = 0))
for (i in seq_along(CA_ZK)[-1])
  ARMS[[length(ARMS)+1]] <- list(lab = sprintf("A:%g", CA_ZK[i]), zk = CA_ZK[i], fl = 0)
for (i in seq_along(CA_HILDA_Z0))
  ARMS[[length(ARMS)+1]] <- list(lab = sprintf("H:%g/%.0f%%", CA_HILDA_Z0[i],
                                 100*CA_HILDA_FLOOR[i]), zk = CA_HILDA_Z0[i],
                                 fl = CA_HILDA_FLOOR[i])
res <- list()
for (a in ARMS) {
  kz <- solve_kz(a$zk, a$fl); p <- v0$p; p$kz <- kz
  res[[a$lab]] <- list(kz = kz, deep = deep_of(p, a$zk, a$fl),
                       prof = prof_of(p, a$zk, a$fl))
}
cat(sprintf("  %-14s %10s %10s %10s %10s\n", "arm", "kz solved", "K(ML base)", "K(bottom)", "deep D14C"))
for (a in ARMS) { r <- res[[a$lab]]; fs <- ca_shape(grid, a$zk, a$fl)
  cat(sprintf("  %-14s %10.0f %10.0f %10.0f %10.3f\n", a$lab, r$kz,
              r$kz * fs[1], r$kz * fs[grid$nl], r$deep)) }
cat("  (A: = the August floorless form. H: = HILDA's floor+short-scale form,\n")
cat("   labelled z0/floor%. H:253/6% is Siegenthaler & Joos's OWN fitted shape.)\n")

# ---- THE PROFILE ------------------------------------------------------
cat("\n=== PREINDUSTRIAL D14C z AGAINST GLODAP, BY LAYER ===\n")
cat(sprintf("  (scored band: depth > %d m, where the bomb addition is <= 4.5 permil)\n\n",
            CA_SCORED_MIN_DEPTH))
cat(sprintf("  %8s", "depth m")); for (a in ARMS) cat(sprintf(" %11s", a$lab)); cat("  scored\n")
zs <- list()
for (i in seq_along(zmid)) {
  cat(sprintf("  %8.0f", zmid[i]))
  for (a in ARMS) {
    z <- (res[[a$lab]]$prof[i] - op$d14[i]) / (op$d14_sd[i] / sqrt(CA_NEFF))
    zs[[a$lab]][i] <- z; cat(sprintf(" %+11.2f", z))
  }
  cat(sprintf("  %s\n", if (zmid[i] > CA_SCORED_MIN_DEPTH) "YES" else "no"))
}
sc <- which(zmid > CA_SCORED_MIN_DEPTH)
cat(sprintf("\n  %-8s", "mean|z|")); for (a in ARMS) cat(sprintf(" %11.2f", mean(abs(zs[[a$lab]][sc])))); cat("\n")
cat(sprintf("  %-8s", "max|z|"));  for (a in ARMS) cat(sprintf(" %11.2f", max(abs(zs[[a$lab]][sc])))); cat("\n")

cat("\n=== VERDICT ===\n")
base_m <- mean(abs(zs[["Inf"]][sc]))
ms <- vapply(ARMS, function(a) mean(abs(zs[[a$lab]][sc])), 0)
bi <- which.min(ms); best_m <- ms[bi]
cat(sprintf("  incumbent (constant K) scored mean |z| = %.2f\n", base_m))
cat(sprintf("  best arm: %s, scored mean |z| = %.2f (%+.0f%%)\n",
            ARMS[[bi]]$lab, best_m, 100 * (best_m / base_m - 1)))
cat(sprintf("  ⇒ DESIGN sec.3.4a's gate: does the CHEAPER candidate reach |z| < 1 in the\n"))
cat(sprintf("    scored band while holding the deep age?  %s\n",
            if (best_m < 1) "YES -- a new box is NOT indicated on this row"
            else "NO -- the cheaper candidate is INSUFFICIENT here"))
