# =====================================================================
# diag_seas_ml_spinup_leak_probe.R -- HOW BIG WAS THE 2026-09-09t SPINUP
# LEAK, at the configuration P12 actually used?
#
# ⭐ RUN IT TWICE, IN TWO FROZEN TREES that differ ONLY by the documented
# one-line mutation in `ccx_cpp_par()` (see the quarantine README §5):
#     post-fix : p$seas_ml_on <- as.integer(ccx_seas_ml_on(p))
#     pre-fix  : p$seas_ml_on <- as.integer(!is.null(p$seas_ml) && p$seas_ml > 0)
# The difference between the two columns IS the bug's size. Running it in the
# live tree gives the post-fix column only.
#
# ⚠ WHY THE P12 CONFIGURATION SPECIFICALLY. P12's own log asserts the two
# spinups were bit-identical (`stopifnot(all.equal(..., tolerance = 0))`,
# printed 0.000e+00) -- which is IMPOSSIBLE under the leak. This probe was
# written to settle that contradiction, and it did: under the pre-fix
# mutation the same assertion evaluates FALSE, so P12 cannot have run on
# leaking code. The C++ core had no seasonal mixed layer at all until
# 4189ff9 (16:33); P12 ran at 15:18.
# =====================================================================
source("calibration/lib_design_gates.R")

v  <- dg_vector(CCX_MODE_CANONICAL)
mk <- function(ent, seas_ml) { p <- v$p; p$ent_seas_amp_SH <- ent; p$seas_ml <- seas_ml; p }

cat(sprintf("mode          : %s\n", CCX_MODE_CANONICAL))
cat(sprintf("seas_drivers  : %s\n", format(v$p$seas_drivers)))
cat(sprintf("h_ml          : %.4f m\n", v$p$h_ml))
cat(sprintf("R gate ccx_seas_ml_on(mk(21.2,1)) : %s\n", ccx_seas_ml_on(mk(21.2, 1))))
cat(sprintf("marshalled seas_ml_on             : %d\n", ccx_cpp_par(mk(21.2,1))$seas_ml_on))
aux1 <- ccx_prepare(mk(21.2, 1))
cat(sprintf("aux$mld_coef present              : %s  -> A.seas_ml = %d\n",
            !is.null(aux1$mld_coef), as.integer(!is.null(aux1$mld_coef))))

oc <- function(y) {
  bn <- rownames(y)
  sum(y[grepl("_(ml|oc[0-9]+|hs|hd)$", bn), "C"])
}
atm <- function(y) sum(y[grepl("_atm$", rownames(y)), "C"])

arms <- list("P12 sp0: ent=0,  seas_ml=0" = mk(0, 0),
             "P12 sp1: ent=21.2, seas_ml=1" = mk(21.2, 1),
             "isolate: ent=0,  seas_ml=1" = mk(0, 1),
             "isolate: ent=21.2, seas_ml=0" = mk(21.2, 0))
sp <- lapply(arms, ccx_spinup)

cat("\nSPINUP EQUILIBRIUM BY ARM\n")
cat(sprintf("  %-30s %14s %12s\n", "arm", "ocean C (GtC)", "atm C"))
for (nm in names(sp))
  cat(sprintf("  %-30s %14.3f %12.3f\n", nm, oc(sp[[nm]]$y), atm(sp[[nm]]$y)))

ref <- sp[[1]]$y
cat("\nDIFFERENCE FROM P12's sp0 (the arm the assertion compares against)\n")
for (nm in names(sp)[-1])
  cat(sprintf("  %-30s max|dy| = %12.6e   d(ocean C) = %+12.4f\n",
              nm, max(abs(sp[[nm]]$y - ref)), oc(sp[[nm]]$y) - oc(ref)))

cat("\nP12's OWN ASSERTION, re-evaluated: all.equal(sp0$y, sp1$y, tolerance=0) -> ")
cat(sprintf("%s\n", isTRUE(all.equal(sp[[1]]$y, sp[[2]]$y, tolerance = 0))))
