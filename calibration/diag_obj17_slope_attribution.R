#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_slope_attribution.R -- WHICH of stage 2's moves drops the interannual module's ENSO slope row at a FIXED
# w_enso_l2, and so pushes the one-pass check's w_enso_l2 up? (notes/handoff_2026-10-07_obj17_finished.md §3.4, the
# test asked for before framing the w_enso_l2 choice; CHANGELOG 2026-10-07 a.)
#
# THE TWO VECTORS. They differ ONLY in the 29 names stage 2 fits:
#   B1  = hilda33p's 29 free names + stage 1's four module values (where stage 1 fitted the limb);
#   #17 = a stage-2 vector (the same four module values, PINNED).
# PER NAME THAT MOVED (B1 -> #17), the model's ENSO ocean slope (ccx_enso_slope(), the row's own estimator):
#   SWAP  that ONE name set back to B1's value, the others at #17's (exact, one at a time);
#   LIN   d(slope)/d(name) at #17 by central difference (step 0.1 x the move), times the move.
# The handoff's hypothesis (UNTESTED there): a weaker solved pump (pump_grad) leaves less DIC contrast for the limb to
# move per unit exchange. This attributes the drop; it does not test the mechanism (the fast runner exposes only the
# mixed layer, not the interior layers the limb draws from).
# GATES: the slope row at #17 IS ccx_iav_module_loglik()'s slope row on the same run (the module's own number, read on
# the objective's span); the CONTROL names (no dynamic role for the 12C ocean flux) give EXACTLY 0 in both columns.
# Usage: Rscript calibration/diag_obj17_slope_attribution.R --mode=<#17 mode file> [--tag=<suffix>]
# OUTPUTS: outputs/diagnostics/obj17_slope_attribution_<date><tag>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
SA_DRIVER   <- "calibration/diag_obj17_slope_attribution.R"
SA_ARGS     <- commandArgs(trailingOnly = TRUE)
sa_arg <- function(key, default) { h <- grep(sprintf("^--%s=", key), SA_ARGS, value = TRUE)
  if (length(h)) sub(sprintf("^--%s=", key), "", h[1]) else default }
SA_MODE     <- sa_arg("mode", "")
SA_TAG      <- sa_arg("tag", "")
SA_CANON    <- "hilda33p"                       # B1's other names
SA_LIMB     <- "w_enso_l2"
SA_LIMB_H   <- 0.25                             # Sv: the limb's central-difference half-step (fit_iav_module.R's IAV_H_STEP w)
SA_LIN_FRAC <- 0.1                              # LIN's half-step, as a fraction of the name's move
SA_CONTROL  <- c("bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c", "imb_share_land",
                 "imb_share_ocean_rest")        # no dynamic role for the 12C ocean flux: must give EXACTLY 0
if (!nzchar(SA_MODE)) stop("give --mode=<a stage-2 mode file of objective #17>")
SA_OUT  <- file.path("outputs", "diagnostics", sprintf("obj17_slope_attribution_%s%s", format(Sys.Date(), "%Y%m%d"), SA_TAG))
COMMIT  <- ccx_git_stamp()
sink(paste0(SA_OUT, ".log"), split = TRUE)
OBS <- ccx_prepare_obs()
V17 <- dg_vector(SA_MODE); VC <- dg_vector(SA_CANON)
cat(sprintf("%s @%s, %s\n  #17 %s (md5 %s)\n  B1  = %s's free names + stage 1's module values (the #17 file's pins)\n", SA_DRIVER,
            COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), SA_MODE, unname(tools::md5sum(SA_MODE)), SA_CANON))
stopifnot(identical(ccx_mode_struct(V17$md), CCX_MODE_OBJ17_STRUCT))
FREE <- V17$md$param_names
stopifnot(!any(CCX_IAV_MODULE_NAMES %in% FREE), all(FREE %in% VC$md$param_names), all(SA_CONTROL %in% FREE))
FS_C <- ccx_mode_fit_stats(VC$md); sdC <- stats::setNames(as.numeric(FS_C$sd), FS_C$param_names)
stopifnot(identical(V17$md$hml_bound, VC$md$hml_bound))
ZMV <- (V17$md$u_mode[FREE] - VC$md$u_mode[FREE]) / sdC[FREE]   # the move in hilda33p's marginal sd (the read's section 4)

set_name <- function(v, n, x) { if (n %in% names(v$p)) v$p[[n]] <- x; v$pm[[n]] <- x
  v$p <- ccx_set_enso(v$p, v$pm); v$luc_scale <- v$pm$luc_scale; v$bomb_total <- v$pm$bomb_total; v }
# the row on the OBJECTIVE's span, exactly as ccx_iav_module_loglik() reads it: the gate run reaches DG_YEARS[2], and
# on the full run 2024's end boundary is interpolated where the objective extrapolates it (+1.8925 vs the module's
# +1.8519 at basin B -- found by the gate below on this driver's first draft)
slope_of <- function(v, run = dg_run(v)) {
  fl <- ccx_calendar_flux(run$out[run$out$t < LIK_IAV_SPAN_END + 1, , drop = FALSE])
  ms <- ccx_enso_slope(fl$year, fl$ocean, OBS$enso_idx)
  c(slope = ms[["slope"]], row = stats::dnorm(OBS$enso_slope[["slope"]], ms[["slope"]], OBS$enso_slope[["se"]], log = TRUE)) }
B1 <- V17; for (n in FREE) B1 <- set_name(B1, n, VC$pm[[n]])
R17 <- dg_run(V17); s17 <- slope_of(V17, R17); sB1 <- slope_of(B1)

cat("\n=== GATE: the row at #17 is the module's own slope row ===\n")
ML17 <- ccx_iav_module_loglik(R17$out, R17$F, OBS, ssr_ref = 1)   # the slope row does not read ssr_ref
cat(sprintf("  this driver %+.10f | ccx_iav_module_loglik() %+.10f\n", s17[["row"]], ML17[["slope_row"]]))
if (!identical(unname(s17[["row"]]), unname(ML17[["slope_row"]]))) stop("the slope row is not the module's")

cat(sprintf("\n=== THE DROP ===\n  obs slope %.5f (se %.5f) GtC/yr per unit Nino3.4\n", OBS$enso_slope[["slope"]], OBS$enso_slope[["se"]]))
cat(sprintf("  B1  slope %.5f  row %+.4f\n  #17 slope %.5f  row %+.4f   (the drop: slope %+.5f, row %+.4f)\n",
            sB1[["slope"]], sB1[["row"]], s17[["slope"]], s17[["row"]], s17[["slope"]] - sB1[["slope"]], s17[["row"]] - sB1[["row"]]))
w17 <- V17$pm[[SA_LIMB]]
DW  <- (slope_of(set_name(V17, SA_LIMB, w17 + SA_LIMB_H))[["slope"]] -
        slope_of(set_name(V17, SA_LIMB, w17 - SA_LIMB_H))[["slope"]]) / (2 * SA_LIMB_H)
W_RESTORE <- (sB1[["slope"]] - s17[["slope"]]) / DW
cat(sprintf("  d(slope)/d(%s) at #17 %.6f per Sv -> restoring B1's slope needs %s %+.3f (linear; at %.4f)\n", SA_LIMB, DW,
            SA_LIMB, W_RESTORE, w17))

cat("\n=== PER NAME, B1 -> #17 ===\n")
RES <- do.call(rbind, lapply(FREE, function(n) {
  x17 <- V17$pm[[n]]; xb <- VC$pm[[n]]; mv <- x17 - xb
  if (mv == 0) return(data.frame(name = n, move_sd = 0, swap = 0, lin = 0))
  sw <- s17[["slope"]] - slope_of(set_name(V17, n, xb))[["slope"]]          # this name's share of the drop
  h  <- SA_LIN_FRAC * mv
  d  <- (slope_of(set_name(V17, n, x17 + h))[["slope"]] - slope_of(set_name(V17, n, x17 - h))[["slope"]]) / (2 * h)
  data.frame(name = n, move_sd = ZMV[[n]], swap = sw, lin = d * mv) }))
RES <- RES[order(-abs(RES$swap)), ]
TOT <- s17[["slope"]] - sB1[["slope"]]
cat(sprintf("  %-22s %9s %12s %12s %8s\n", "name", "move/sd", "SWAP share", "LIN share", "% drop"))
for (i in seq_len(nrow(RES))) cat(sprintf("  %-22s %+9.2f %+12.6f %+12.6f %7.1f%%\n", RES$name[i], RES$move_sd[i],
                                          RES$swap[i], RES$lin[i], 100 * RES$swap[i] / TOT))
cat(sprintf("  %-22s %9s %+12.6f %+12.6f   (the drop itself %+.6f; non-additivity %+.6f)\n", "SUM", "", sum(RES$swap),
            sum(RES$lin), TOT, TOT - sum(RES$swap)))
CTL <- RES[RES$name %in% SA_CONTROL, ]
cat(sprintf("  CONTROL (%s): %d of %d exactly 0 in both columns\n", paste(SA_CONTROL, collapse = ", "),
            sum(CTL$swap == 0 & CTL$lin == 0), nrow(CTL)))
if (any(CTL$swap != 0 | CTL$lin != 0)) stop("a CONTROL name moved the 12C ocean slope: the swap does not do what it says")
saveRDS(list(res = RES, s17 = s17, sB1 = sB1, dslope_dw = DW, w_restore = W_RESTORE, mode = SA_MODE,
             provenance = list(driver = SA_DRIVER, commit = COMMIT, canon = SA_CANON, mode_md5 = unname(tools::md5sum(SA_MODE)),
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none")), paste0(SA_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", SA_OUT))
sink()
