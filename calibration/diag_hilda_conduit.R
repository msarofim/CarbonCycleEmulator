# =====================================================================
# diag_hilda_conduit.R -- DOES A HILDA-STYLE HIGH-LATITUDE CONDUIT FIX
#   THE INTERMEDIATE-DEPTH D14C PROFILE?
#
# Pre-registered in notes/prereg_2026-09-04k_hilda_conduit.md.
#
# THE GEOMETRY UNDER TEST, AND WHY IT IS NOT `w_out`. `w_out` lifts bottom
# water to the mixed layer and returns it DISTRIBUTED DOWNWARD through
# every layer, injecting surface water straight into the intermediate
# boxes -- which is why it over-ventilates them and failed in August.
# HILDA's HD exchanges with the Interior as a reservoir; the Interior's
# intermediate layers are never injected with surface water. So the form
# here is a TWO-WAY EXCHANGE BETWEEN THE MIXED LAYER AND THE BOTTOM BOX
# ONLY, with NO distributed return -- the one conduit geometry never
# measured in this repo.
#
# ⚠ A REDUCED FORM, NOT HILDA. HS and HD are real boxes in HILDA and a
# shim cannot add state. What is tested is the conduit's GEOMETRY -- a
# surface-to-deep pathway bypassing the interior -- NOT its temperature,
# its 16 %-of-area surface, or the poorly equilibrated D14C its HS box
# carries (-120 permil, against LS's -40). A positive result licenses
# building it properly; it does NOT license quoting these as HILDA's.
#
# Usage:  Rscript calibration/diag_hilda_conduit.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

HC_U     <- c(0, 0.5, 1, 2, 5, 10)     # conduit rate, m/yr
HC_NEFF  <- LIK_D14C_DEEP_NEFF
HC_SCORED_MIN_DEPTH <- 1500            # bomb <= 4.5 permil below this

# ---- THE SHIM: ML <-> BOTTOM BOX, two-way, no distributed return -------
.hc <- new.env(parent = emptyenv()); .hc$on <- FALSE; .hc$u <- 0
.hc_base <- ccx_deriv_fast
ccx_deriv_fast <- function(y, t, p, forc, grid, aux) {
  dy <- .hc_base(y, t, p, forc, grid, aux)
  if (!.hc$on || .hc$u == 0) return(dy)
  for (h in HEMIS) {
    col <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
    a <- col[1]; b <- col[length(col)]          # mixed layer, bottom box
    for (tr in CCX_TRACERS) {
      # volumetric exchange: u m/yr through the column's area, carrying the
      # SOURCE box's concentration each way. Symmetric, so it conserves mass.
      up   <- .hc$u * y[b, tr] / grid$dz[length(col)]
      down <- .hc$u * y[a, tr] / grid$dz[1]
      dy[a, tr] <- dy[a, tr] + up   - down
      dy[b, tr] <- dy[b, tr] + down - up
    }
  }
  dy
}

v0   <- dg_vector(CCX_MODE_CANONICAL)
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2

with_u <- function(u, f) { .hc$u <- u; .hc$on <- (u != 0); on.exit(.hc$on <- FALSE); f() }
deep_of <- function(p, u) with_u(u, function() ccx_spinup(p)$diagnostics$d14c_bottom_box)
sp_of   <- function(p, u) with_u(u, function() ccx_spinup(p))
prof_of <- function(p, u) {
  sp <- sp_of(p, u); aux <- sp$aux
  lay <- function(h) { ix <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
                       1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (lay("NH") * aux$a_oc$NH + lay("SH") * aux$a_oc$SH) / (aux$a_oc$NH + aux$a_oc$SH)
}

# ---- P0: CONSERVATION + a mutation gate, scored FIRST -----------------
cat("=== P0: CONSERVATION AND THE MUTATION GATE ===\n")
d0 <- deep_of(v0$p, 0); d1 <- deep_of(v0$p, 5)
cat(sprintf("  u = 0 is a NO-OP        : %.6f vs %.6f   %s\n", d0,
            ccx_spinup(v0$p)$diagnostics$d14c_bottom_box,
            if (identical(d0, ccx_spinup(v0$p)$diagnostics$d14c_bottom_box))
              "PASS (bit-exact)" else "FAIL"))
cat(sprintf("  u = 5 BITES             : %.6f vs %.6f   %s\n", d0, d1,
            if (abs(d0 - d1) > 1e-6) "PASS" else "FAIL -- the shim is INERT"))
sp5 <- sp_of(v0$p, 5)
# ⚠ ccx_forcing_at(), not a data-frame row: ccx_deriv_fast() needs the LIST
# form and errors loudly on a flat row rather than running a different model.
F5   <- ccx_build_forcing("historical", c(1750, 1751), prod_c14 = sp5$prod_c14)
res5 <- with_u(5, function()
  ccx_deriv_fast(sp5$y, 1750, sp5$params, ccx_forcing_at(F5, 1L), grid, sp5$aux))
tot <- sum(sp5$y[, "C"])
cat(sprintf("  carbon closure at u = 5 : sum|dC/dt| / total C = %.3e   %s\n",
            sum(abs(res5[, "C"])) / tot,
            if (sum(abs(res5[, "C"])) / tot < 1e-9) "PASS" else "see note"))
if (abs(d0 - d1) <= 1e-6) stop("HILDA conduit shim failed its mutation gate")

# ---- ISO-DEEP -----------------------------------------------------------
cat(sprintf("\n=== ISO-DEEP: kz re-solved per u to hold deep D14C at %.3f ===\n", d0))
solve_kz <- function(u) {
  if (u == 0) return(v0$p$kz)
  f <- function(lk) { p <- v0$p; p$kz <- exp(lk); deep_of(p, u) - d0 }
  lo <- log(v0$p$kz); hi <- log(v0$p$kz)
  n <- 0; while (f(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (f(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (f(lo) > 0 || f(hi) < 0) return(NA_real_)
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
res <- list()
for (u in HC_U) {
  kz <- solve_kz(u)
  if (is.na(kz)) { cat(sprintf("  u = %-5g  NO kz holds the deep age -- skipped\n", u)); next }
  p <- v0$p; p$kz <- kz
  res[[as.character(u)]] <- list(kz = kz, deep = deep_of(p, u), prof = prof_of(p, u))
}
US <- names(res)
cat(sprintf("  %8s %12s %12s %12s\n", "u m/yr", "kz solved", "kz / kz(0)", "deep D14C"))
for (u in US) cat(sprintf("  %8s %12.0f %12.3f %12.3f\n", u, res[[u]]$kz,
                          res[[u]]$kz / res[["0"]]$kz, res[[u]]$deep))

# ---- THE PROFILE --------------------------------------------------------
cat(sprintf("\n=== PREINDUSTRIAL D14C z AGAINST GLODAP (scored band > %d m) ===\n\n",
            HC_SCORED_MIN_DEPTH))
cat(sprintf("  %8s", "depth m")); for (u in US) cat(sprintf(" %9s", paste0("u=", u)))
cat("  scored\n")
zs <- list()
for (i in seq_along(zmid)) {
  cat(sprintf("  %8.0f", zmid[i]))
  for (u in US) {
    z <- (res[[u]]$prof[i] - op$d14[i]) / (op$d14_sd[i] / sqrt(HC_NEFF))
    zs[[u]][i] <- z; cat(sprintf(" %+9.2f", z))
  }
  cat(sprintf("  %s\n", if (zmid[i] > HC_SCORED_MIN_DEPTH) "YES" else "no"))
}
sc <- which(zmid > HC_SCORED_MIN_DEPTH)
cat(sprintf("\n  %-8s", "mean|z|")); for (u in US) cat(sprintf(" %9.2f", mean(abs(zs[[u]][sc])))); cat("\n")
cat(sprintf("  %-8s", "max|z|"));  for (u in US) cat(sprintf(" %9.2f", max(abs(zs[[u]][sc])))); cat("\n")

# ---- SCORED PREDICTIONS -------------------------------------------------
cat("\n=== THE SCORED PREDICTIONS (prereg 2026-09-04k) ===\n")
kzr <- vapply(US, function(u) res[[u]]$kz, 0)
cat(sprintf("  P1 -- does the conduit RELIEVE kz?  kz(0) %.0f -> kz(max u) %.0f  (%.2fx)  -> %s\n",
            kzr[1], kzr[length(kzr)], kzr[length(kzr)] / kzr[1],
            if (kzr[length(kzr)] < kzr[1]) "CONFIRMED" else "FALSIFIED -- P2 is uninterpretable"))
ms <- vapply(US, function(u) mean(abs(zs[[u]][sc])), 0)
cat(sprintf("  P2 -- does the intermediate profile IMPROVE?  mean|z| %.2f -> %.2f (best %.2f at u=%s)\n",
            ms[1], ms[length(ms)], min(ms), US[which.min(ms)]))
cat(sprintf("        -> %s\n", if (min(ms) < ms[1]) "CONFIRMED" else "FALSIFIED"))
cat(sprintf("  P3 -- concentrated at 1622/2268 m?  z there: %+.2f/%+.2f -> %+.2f/%+.2f\n",
            zs[[US[1]]][sc[1]], zs[[US[1]]][sc[2]],
            zs[[US[which.min(ms)]]][sc[1]], zs[[US[which.min(ms)]]][sc[2]]))
cat("        ⚠ weakest row, three scored layers only.\n")
