# =====================================================================
# diag_obj16_row_split.R -- objective #16 (hilda33p) minus hilda34g, ROW BY ROW, split into its two causes
# (CHANGELOG 2026-10-06 a; asked by Marcus 2026-10-06: "Likelihood is worse: what are the largest other changes?").
#   feedback   = #16 with the stratification feedback ON minus OFF, at #16's own vector (mix_strat_s = 0 is
#                OFF bit for bit, R/model.R ccx_mix_on());
#   pin_refit  = #16 OFF minus hilda34g: the greening pin (npp_tsens = 0) and the refit's re-arrangement.
# Each arm in its own space, exactly as calibration/diag_obj16_refit_read.R's in_arm(). The two parts sum to
# the total by construction; the feedback part is measured at #16's point, not at hilda34g's.
# Output: outputs/diagnostics/obj16_row_split_<date>.log. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RS_A    <- "hilda34g"                 # the canonical before (objective #15)
RS_B    <- "hilda33p"                 # objective #16, adopted 2026-10-06
RS_OFF  <- list(mix_strat_s = 0)      # the feedback OFF
RS_TOL  <- 1e-6                       # each vector must reproduce its stored logpost
RS_OUT  <- file.path("outputs", "diagnostics", sprintf("obj16_row_split_%s.log", format(Sys.Date(), "%Y%m%d")))
RS_COMMIT <- ccx_git_stamp()
LOGCON <- file(RS_OUT, open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("calibration/diag_obj16_row_split.R @%s, %s | %s - %s, row by row; the feedback OFF = %s\n",
            RS_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), RS_B, RS_A,
            paste(sprintf("%s = %g", names(RS_OFF), unlist(RS_OFF)), collapse = ", ")))

OBS <- ccx_prepare_obs()
in_arm <- function(md, f) {
  r <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(r), add = TRUE)
  stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  invisible(utils::capture.output(st <- ccx_mode_start(md, "row split")))
  stopifnot(length(st$absent) == 0L, st$logpost_shift == 0)
  f(bp, spf, st$u)
}
ev <- function(bp, spf, u) {
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spf, obs = OBS)
  v <- lp(u); list(logpost = as.numeric(v), streams = unlist(attr(v, "streams")), mix_on = ccx_mix_on(bp))
}
MD_A <- readRDS(ccx_mode_file(RS_A)); MD_B <- readRDS(ccx_mode_file(RS_B))
A    <- in_arm(MD_A, function(bp, spf, u) ev(bp, spf, u))
Bon  <- in_arm(MD_B, function(bp, spf, u) ev(bp, spf, u))
Boff <- in_arm(MD_B, function(bp, spf, u) { for (n in names(RS_OFF)) bp[[n]] <- RS_OFF[[n]]; ev(bp, spf, u) })
stopifnot(!A$mix_on, Bon$mix_on, !Boff$mix_on,
          abs(A$logpost - MD_A$logpost) < RS_TOL, abs(Bon$logpost - MD_B$logpost) < RS_TOL)
cat(sprintf("reproduction: %s logpost %.6f (stored %.6f); %s %.6f (stored %.6f)\n\n",
            RS_A, A$logpost, MD_A$logpost, RS_B, Bon$logpost, MD_B$logpost))
rows <- names(A$streams); stopifnot(setequal(rows, names(Bon$streams)), setequal(rows, names(Boff$streams)))
d <- data.frame(row = rows, total = Bon$streams[rows] - A$streams[rows],
                feedback = Bon$streams[rows] - Boff$streams[rows], pin_refit = Boff$streams[rows] - A$streams[rows])
d <- d[order(-abs(d$total)), ]
print(format(d, digits = 3), row.names = FALSE)
cat(sprintf("\nSUM: total %.4f = the feedback at %s %.4f + the pin and the refit %.4f\n",
            sum(d$total), RS_B, sum(d$feedback), sum(d$pin_refit)))
sink(); close(LOGCON)
cat(sprintf("saved %s\n", RS_OUT))
