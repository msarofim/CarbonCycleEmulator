# =====================================================================
# diag_q10_stream_direction.R -- WHICH constraint pushes q10 below 1?
#
# Handoff 2026-08-12d sec.0 step 1 proposed fixing the three sigmas first, on
# the stated mechanism that the fit loosens sigma_d13c to escape "the one term
# that would discipline the land sink", and that the d13C constraint therefore
# pushes q10 UP. That mechanism was argued, not measured.
#
# This measures it. q10 is scanned with every other parameter held, at FIXED
# sigmas, and ccx_loglik(by_stream = TRUE) is reported per stream so the
# DIRECTION each constraint pulls is visible rather than inferred from the total.
#
# RESULT (2026-08-12, both parameter vectors): d13C pushes q10 DOWN, not up.
# Relative to q10 = 2.0, moving to q10 = 0.2 GAINS d13C log-units at both
# stations -- +254/+158 at defaults, +346/+294 at the mode's other parameters.
# The premise is inverted: tightening sigma_d13c STRENGTHENS the force driving
# the q10 inversion. See diag_d13c_suess.R for why (the model over-depletes
# atmospheric d13C, and a larger land sink is what relieves that).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
DQ_SIGMAS   <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
DQ_SIG_NOTE <- "prior medians (1.5 ppm / 0.1 permil / 5 permil)"
DQ_Q10_GRID <- c(0.169, 0.3, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0)
DQ_Q10_REF  <- 2.0          # reference row; the prior median and physical center
DQ_YEARS    <- c(1750, 2024)
DQ_BOMB_REF <- 102          # kmol, the reference the bomb column is built at
DQ_STREAMS  <- c("co2_level_MLO", "co2_level_SPO", "d13c_level_MLO",
                 "d13c_level_SPO", "d14c_NH", "d14c_SH", "gcb_ocean_sink",
                 "gcb_land_sink", "excess_c14_ocean", "co2_icecore")

cat(sprintf("q10 scan at fixed sigmas = %s\n", DQ_SIG_NOTE))

obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", DQ_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = DQ_BOMB_REF)

dq_scan <- function(p_base, bomb_total, label) {
  cat(sprintf("\n=========== %s ===========\n", label))
  m <- do.call(rbind, lapply(DQ_Q10_GRID, function(q) {
    p <- p_base; p$q10 <- q
    sp <- ccx_spinup(p)
    F  <- base_forcing
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- base_forcing$c14_bomb * (bomb_total / DQ_BOMB_REF)
    out   <- ccx_run_fast(sp, F)$out
    parts <- ccx_loglik(out, obs, DQ_SIGMAS, by_stream = TRUE)
    ms <- ccx_model_stats(out, obs)
    bias <- function(o, m, col) {
      k <- match(o$year, m$year); g <- !is.na(k)
      mean(o[[col]][g] - m$level[k[g]])
    }
    c(q10 = q, total = sum(parts), parts,
      d13c_bias_MLO = bias(obs$d13_ann$MLO, ms$d13$MLO, "level"),
      co2_bias_MLO  = bias(obs$co2_ann$MLO, ms$co2$MLO, "level"))
  }))
  keep <- c("q10", "total", intersect(DQ_STREAMS, colnames(m)),
            "d13c_bias_MLO", "co2_bias_MLO")
  m <- m[, keep, drop = FALSE]
  cat("\nABSOLUTE log-likelihood by stream:\n"); print(round(m, 1))
  ref <- which.min(abs(m[, "q10"] - DQ_Q10_REF))
  d <- sweep(m, 2, m[ref, ], "-"); d[, "q10"] <- m[, "q10"]
  cat(sprintf("\nRELATIVE to q10 = %.1f -- POSITIVE means that stream PREFERS the LOWER q10:\n",
              DQ_Q10_REF))
  print(round(d, 1))
  invisible(m)
}

dq_scan(ccx_default_params(), DQ_BOMB_REF, "at ccx_default_params()")

mode_path <- ccx_path("calibration", "output", "mode_fit.rds")
if (file.exists(mode_path)) {
  pm <- readRDS(mode_path)$par_mode
  p1 <- ccx_default_params()
  for (n in intersect(names(p1), names(pm))) p1[[n]] <- pm[[n]]
  p1 <- ccx_set_enso(p1, pm)
  dq_scan(p1, pm$bomb_total,
          "at the 16-parameter mode's OTHER parameters (q10 overridden)")
} else {
  cat("\nmode_fit.rds absent -- default-parameter scan only.\n")
}
