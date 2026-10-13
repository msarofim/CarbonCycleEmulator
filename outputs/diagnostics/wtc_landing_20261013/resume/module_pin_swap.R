# THE MODULE CHECK's MOVE, SCORED ON THE MAIN OBJECTIVE (2026-10-13; CHANGELOG 2026-10-13 d). The one-pass check moved
# w_enso_l2 by -0.110 sigma (over the ruled 0.1). This scores the WTC objective at id 17's u with the carried module pins
# (hilda29e's) and with the check's stage-1 values swapped in, the 31 free names HELD. A second pass would re-fit the free
# names under the new pins; this is the size of the step it would start from. No RNG.
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
WAVE <- "calibration/output/multistart_20261012ff_hilda_csl3v0kaidgbemwtc_seasml1_pin_wtc_sd1.0452_prior_bomb_share_NH_seas_T_lag"
CK   <- "calibration/output/iav_module_20261013_refit_20261013_wtc_hilda_csl3v0kaidgbemwtc.rds"
MODULE <- c("lag_enso_land", "gamma_enso_land_NH", "gamma_enso_land_SH", "w_enso_l2")
cat(sprintf("module_pin_swap.R @%s, %s\n", ccx_git_stamp(), format(Sys.time(), "%Y-%m-%d %H:%M")))
s <- readRDS(file.path(WAVE, "start_017.rds")); ck <- readRDS(CK)
new <- unlist(ck$pins %||% ck$stage1 %||% ck$result)[MODULE]
if (anyNA(new)) { cat("fields of the check file:", names(ck), "\n"); stop("cannot find the four module values in ", CK) }
# the gate and the pinned SET are applied ONCE per process (ccx_apply_gate() refuses a second); both arms pin the same
# fourteen names, so only the VALUES carried in base_params differ
invisible(ccx_apply_gate(s$struct)); invisible(ccx_apply_pins(s$pins))
build <- function(pins) { stopifnot(identical(sort(names(pins)), sort(names(s$pins))))
  bp <- ccx_apply_structure(ccx_default_params(), s$struct, seas_ml = ccx_parse_seas_ml(s$seas_ml),
                            pump_field = ccx_parse_pump_field(s$pump_field))
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  attr(bp, "pins") <- pins; bp$pump_mode <- s$pump_mode
  list(lp = ccx_make_logpost(base_params = bp), ll = ccx_make_logpost(base_params = bp, by_stream = TRUE)) }
p0 <- s$pins; p1 <- p0; for (n in MODULE) p1[[n]] <- new[[n]]
o0 <- build(p0); a <- o0$lp(s$u_mode); x0 <- o0$ll(s$u_mode); sa <- attr(x0, "loglik")   # the likelihood is an ATTRIBUTE
o1 <- build(p1); b <- o1$lp(s$u_mode); x1 <- o1$ll(s$u_mode); sb <- attr(x1, "loglik")
cat(sprintf("  carried pins: %s\n  check's pins: %s\n", paste(sprintf("%s %.6g", MODULE, unlist(p0[MODULE])), collapse = ", "),
            paste(sprintf("%s %.6g", MODULE, new), collapse = ", ")))
cat(sprintf("  logpost  carried %.6f (stored %.6f) -> swapped %.6f : %+.4f\n", a, s$logpost, b, b - a))
cat(sprintf("  likelihood %.6f -> %.6f : %+.4f (prior + Jacobian %+.2e)\n", sa, sb, sb - sa, (b - sb) - (a - sa)))
d <- unlist(attr(x1, "streams")) - unlist(attr(x0, "streams")); d <- d[order(-abs(d))]
cat(sprintf("  rows that moved by > 0.005: %s\n", paste(sprintf("%s %+.4f", names(d)[abs(d) > 0.005], d[abs(d) > 0.005]), collapse = ", ")))
cat(sprintf("  for scale: the objective's noise floor here ~1e-5 (objective_noise_floor_20261013_wtc.log); the basin's 13 starts span 0.026\n"))
