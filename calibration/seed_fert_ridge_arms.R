# =====================================================================
# seed_fert_ridge_arms.R -- place each ridge arm's WARM-START SEED at its own
#                           cell.  (2026-08-25)
#
# The driver warm-starts from `mode_fit_pump<mode>.rds` in its own outdir and
# REJECTS a warm start worse than the cold init (run_modefind_pump_arms.R:472).
# Seeding these arms with an unmodified copy of the adopted mode would therefore
# throw the warm start away -- the adopted mode has fert_k 554.5, which under a
# pin at 90 carries a prior of about -1.2e5 -- and every arm would cold-start
# from -23610 instead of near its own cell.
#
# So each seed is the adopted mode with THREE coordinates moved to the cell:
#   fert_k    the ridge position under test
#   beta_max  solved so enh(420 ppm) is UNCHANGED from the adopted mode --
#             travel ALONG the ridge, which is the whole experiment
#   rep_dC    its 1-D conditional optimum at that cell, from
#             diag_fert_ridge_repdc.R (exact: rep_dC enters only the station
#             terms, additively)
#
# `logpost` in each seed is set to NA_real_ ON PURPOSE. The driver prints it as
# a cross-check against the value it recomputes; carrying the adopted mode's
# -1859.32 forward would put a number in that line that was never this cell's,
# and the seed-copy trap (08-24b) is exactly the failure of reading a seeded
# file as a fitted one. NA cannot be misread.
#
# Usage:  Rscript calibration/seed_fert_ridge_arms.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

SD_SRC   <- ccx_mode_file()
SD_CHI   <- 420
SD_CELLS <- list(
  ridge_free_from90 = list(K = 90,  rep = 0.150,  pin = NA),
  ridge_pin60       = list(K = 60,  rep = -1.750, pin = 60),
  ridge_pin90       = list(K = 90,  rep = 0.150,  pin = 90),
  ridge_pin120      = list(K = 120, rep = 1.370,  pin = 120))

md <- readRDS(SD_SRC)
ccx_require_param_set(md, "the fertilisation-ridge arm seeder")
CHI0  <- ccx_const("CO2_PI_PPM"); d_now <- SD_CHI - CHI0
ENH0  <- md$par_mode$beta_max * d_now / (md$par_mode$fert_k + d_now)
cat(sprintf("source %s  (logpost %.2f)\n", SD_SRC, md$logpost))
cat(sprintf("ridge invariant enh(%d ppm) = %.6f, from beta_max %.4f / fert_k %.2f\n\n",
            SD_CHI, ENH0, md$par_mode$beta_max, md$par_mode$fert_k))

for (nm in names(SD_CELLS)) {
  ce <- SD_CELLS[[nm]]
  out <- ccx_path("calibration", "output", nm)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  s <- md
  s$par_mode$fert_k   <- ce$K
  s$par_mode$beta_max <- ENH0 * (ce$K + d_now) / d_now
  s$par_mode$rep_dC   <- ce$rep
  # GATE: the seed must sit ON the ridge, or the arm is not the experiment.
  enh <- s$par_mode$beta_max * d_now / (s$par_mode$fert_k + d_now)
  stopifnot(abs(enh - ENH0) < 1e-10, s$par_mode$beta_max < 3, s$par_mode$beta_max > 0)
  s$u_mode  <- NULL          # stale under any bound change; the driver re-encodes
  s$logpost <- NA_real_      # see the header -- NA cannot be misread as fitted
  s$streams <- NULL; s$cov <- NULL; s$cor <- NULL; s$hessian <- NULL
  s$seeded_from <- SD_SRC; s$seeded_cell <- ce; s$seeded_enh <- ENH0
  saveRDS(s, file.path(out, "mode_fit_pumpN.rds"))
  cat(sprintf("  %-18s fert_k %6.1f  beta_max %.4f  rep_dC %+.3f  pin %s\n",
              nm, ce$K, s$par_mode$beta_max, ce$rep,
              if (is.na(ce$pin)) "NONE (free arm)" else sprintf("fert_k=%g", ce$pin)))
}
cat("\nseeds written. logpost is NA in every one -- they are SEEDS, not fits.\n")
