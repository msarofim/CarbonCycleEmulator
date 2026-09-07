# =====================================================================
# diag_hilda28_basins.R -- THE BASIN FAMILIES OF THE HILDA REFIT, and the
# objective-#9 mechanism test (2026-09-07). For the best start of every
# distinct basin: the interior profile (levels and contrast), the HS/HD ages,
# the sink, and the likelihood split into the profile row and everything
# else -- under the objective AS FITTED (#9, 60 deg), and RE-SCORED under
# (a) the independent rows (#8 only) and (b) #9 at the 30-deg block. The
# hypothesis under test: #9's 0.98 correlation makes a COMMON level shift one
# event, so a deep ocean 50 permil too young costs ~5 log-units instead of ~24,
# and that is what let the winner abandon the deep. Adopts nothing.
# Usage: Rscript calibration/diag_hilda28_basins.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
HB_DIR <- ccx_path("calibration", "output", "multistart_20260907_hilda28")
HB_OUT <- ccx_path("outputs", "diagnostics", "hilda28_basins_20260907.rds")
HB_PROFILE_ROWS <- c("d14c_profile_mvn", "d14c_mid_1500_2000", "d14c_mid_2000_2627", "d14c_deep_ocean")
fs <- list.files(HB_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
R <- lapply(fs, readRDS); lp <- vapply(R, `[[`, 0, "logpost"); bas <- round(lp, 2)
fam <- lapply(split(seq_along(R), bas), function(ix) R[[ix[which.max(lp[ix])]]])
fam <- fam[order(-vapply(fam, `[[`, 0, "logpost"))]
tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target(); pc60 <- ccx_profile_d14c_cov(60); pc30 <- ccx_profile_d14c_cov(30)
mu <- c(tgm$slabs$target, tgd$target); sd_ind <- c(tgm$slabs$sd, tgd$sd)
mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c,
                              rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(st) { pm <- st$par_mode; p <- ccx_apply_structure(ccx_default_params(), "hilda"); p$pump_mode <- st$pump_mode
  mk_v(ccx_overlay_par(p, pm), pm) }   # migrates, copies, asserts nothing deleted (the lint's idiom)
with_obj <- function(mvn, block, expr) { o1 <- LIK_USE_D14C_PROFILE_MVN; o2 <- LIK_D14C_PROFILE_BLOCK
  assign("LIK_USE_D14C_PROFILE_MVN", mvn, envir = globalenv()); assign("LIK_D14C_PROFILE_BLOCK", block, envir = globalenv())
  on.exit({ assign("LIK_USE_D14C_PROFILE_MVN", o1, envir = globalenv()); assign("LIK_D14C_PROFILE_BLOCK", block <- o2, envir = globalenv()) }, add = TRUE)
  force(expr) }
tg7 <- dg_gcb_target(DG_SINK_WIN)
score <- function(v, lbl) { r <- dg_run(v); sp <- r$sp; sl <- ccx_model_d14c_slabs(sp); lev <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  st60 <- with_obj(TRUE, 60, dg_streams(r, v)); st30 <- with_obj(TRUE, 30, dg_streams(r, v)); stI <- with_obj(FALSE, 60, dg_streams(r, v))
  split <- function(st) c(total = sum(st), row = sum(st[intersect(HB_PROFILE_ROWS, names(st))]), rest = sum(st[setdiff(names(st), HB_PROFILE_ROWS)]))
  g7 <- dg_gate7(r)
  list(lbl = lbl, lev = lev, z_ind = (lev - mu) / sd_ind, z_bd60 = ((lev[2] - lev[3]) - pc60$contrast_obs[["BD"]]) / pc60$se[["BD"]],
       common = mean(lev - mu), hs = sp$diagnostics$d14c_hs[["NH"]], hd = sp$diagnostics$d14c_hd[["NH"]], sink = g7$ocean,
       s60 = split(st60), s30 = split(st30), sI = split(stI), st60 = st60, stI = stI) }
cat(sprintf("\n=== HILDA REFIT BASIN FAMILIES: best start of each of %d basins ===\n", length(fam)))
cat(sprintf("  %-9s %3s %6s %6s %6s %5s | %7s %7s %7s %7s %6s | %6s %6s %5s | %8s %7s %7s | %8s %7s | %8s %7s\n",
            "logpost", "id", "f", "K_deep", "asx", "h_ml", "A", "B", "deep", "HS", "HD", "zA", "zdeep", "zBD", "lik60", "row60", "rest60", "likIND", "rowIND", "lik30", "row30"))
OUT <- list()
for (k in seq_along(fam)) { st <- fam[[k]]; pm <- st$par_mode; S <- score(v_of(st), sprintf("%.2f", st$logpost)); OUT[[k]] <- c(list(id = st$id, logpost = st$logpost, pm = pm), S)
  cat(sprintf("  %9.2f %3d %6.3f %6.0f %6.3f %5.1f | %7.1f %7.1f %7.1f %7.1f %6.1f | %+6.2f %+6.2f %+5.2f | %8.1f %7.1f %7.1f | %8.1f %7.1f | %8.1f %7.1f\n",
              st$logpost, st$id, pm$kz_deep_frac, pm$kz_deep_frac * pm$kz, pm$hs_asx_frac, pm$h_ml, S$lev[1], S$lev[2], S$lev[3], S$hs, S$hd,
              S$z_ind[1], S$z_ind[3], S$z_bd60, S$s60[["total"]], S$s60[["row"]], S$s60[["rest"]], S$sI[["total"]], S$sI[["row"]], S$s30[["total"]], S$s30[["row"]])) }
v0 <- dg_vector(CCX_MODE_CANONICAL); v0$p$hs_frac <- 0; S0 <- score(v0, "ent26"); pm0 <- v0$p
cat(sprintf("  %-9s %3s %6s %6s %6s %5.1f | %7.1f %7.1f %7.1f %7s %6s | %+6.2f %+6.2f %+5.2f | %8.1f %7.1f %7.1f | %8.1f %7.1f | %8.1f %7.1f\n",
            "ent26 OFF", "-", "-", "-", "-", pm0$h_ml, S0$lev[1], S0$lev[2], S0$lev[3], "-", "-", S0$z_ind[1], S0$z_ind[3], S0$z_bd60,
            S0$s60[["total"]], S0$s60[["row"]], S0$s60[["rest"]], S0$sI[["total"]], S0$sI[["row"]], S0$s30[["total"]], S0$s30[["row"]]))
cat("\n  zA/zdeep are against the INDEPENDENT row sds (13.5 / 10.3); zBD the 60-deg contrast se (4.0). lik = the likelihood\n")
cat("  (no prior), row = the profile rows only, rest = everything else. IND = the independent rows (#8), 30 = #9 at 30 deg.\n")
W <- OUT[[1]]
cat(sprintf("\n  WINNER vs ent26 (OFF), rest-of-likelihood only: %+.2f under #9-60, %+.2f under independent rows (same number by construction)\n",
            W$s60[["rest"]] - S0$s60[["rest"]], W$sI[["rest"]] - S0$sI[["rest"]]))
cat(sprintf("  WINNER's profile row: %.1f under #9-60, %.1f under independent rows => the common shift of %+.1f permil costs %.1f more when counted three times\n",
            W$s60[["row"]], W$sI[["row"]], W$common, W$s60[["row"]] - W$sI[["row"]]))
strc <- Filter(function(o) o$pm$kz_deep_frac < 0.3, OUT)
if (length(strc)) { Sx <- strc[[1]]
  cat(sprintf("  BEST STRUCTURAL basin (f %.3f, id %d): lik %.1f (#9-60) / %.1f (IND) vs winner %.1f / %.1f => under independent rows the winner leads by %+.1f\n",
              Sx$pm$kz_deep_frac, Sx$id, Sx$s60[["total"]], Sx$sI[["total"]], W$s60[["total"]], W$sI[["total"]], W$sI[["total"]] - Sx$sI[["total"]])) }
cat("\n  ⛔ Nothing adopted.\n"); saveRDS(list(fam = OUT, ent26 = S0), HB_OUT); cat(sprintf("  saved %s\n", HB_OUT))
