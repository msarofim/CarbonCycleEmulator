for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
ccx_load_cpp()
md <- readRDS(ccx_mode_file())
invisible(ccx_apply_gate(ccx_mode_struct(md)))
PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(PINS))
invisible(ccx_adopt_mode_band(md))
u0 <- ccx_par_to_unc(md$par_mode); pv <- ccx_unc_to_par(u0)
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
p <- bp; for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
p_pr <- bp; for (n in names(pv)) p_pr[[n]] <- pv[[n]]; p <- ccx_set_enso(p, p_pr)
sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
base_forcing <- ccx_build_forcing("historical", c(1750,2024), prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF,
   enso_index = ccx_enso_index_of(bp), aod_mode = ccx_aod_mode_of(bp))
LS <- .ccx_make_luc_scaler(base_forcing, "historical", c(1750,2024))
F <- base_forcing; F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- base_forcing$c14_bomb * (pv$bomb_total / CCX_BOMB_REF)
cols <- LS$cols(pv$luc_scale); for (cc in CCX_LUC_COLS) F[[cc]] <- cols[[cc]]; attr(F, "luc_scale") <- pv$luc_scale
eluc <- LS$eluc_tbl; eluc$eluc <- LS$eluc(pv$luc_scale)
r <- ccx_run_fast(sp, F)
obs <- ccx_prepare_obs()
err <- list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC, grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c)
sh <- ccx_imb_shares(p_pr); err$imb_share_land <- sh[["land"]]; err$imb_share_ocean <- sh[["ocean"]]
err <- ccx_err_with_struct(err, bp)
st <- ccx_loglik(r$out, obs, err, luc = eluc, deep = ccx_d14c_deep_read(sp), ocean_grad = ccx_ocean_grad_scored(r$out, sp),
                 d14c_mid = ccx_model_d14c_slabs(sp), by_stream = TRUE)
cat(sprintf("rebuilt loglik %.6f vs mode streams sum %.6f\n", sum(st), sum(md$streams)))

## (1) IntCal err units
ic <- obs$intcal; ic_end <- min(obs$d14_nh_ann$year); ic <- ic[ic$year >= 1750 & ic$year < ic_end, ]
cat("\n[1] IntCal rows scored:", nrow(ic), " years", min(ic$year), "-", max(ic$year), "; err range", range(ic$err), "\n")
# the err column is the 1-sigma of the conventional 14C AGE (yr): convert to permil exactly
calBP <- 1950 - ic$year
F14 <- (ic$d14c/1000 + 1) * exp(-calBP/8267); age <- -8033 * log(F14)
d_plus  <- 1000 * (exp(-(age - ic$err)/8033) * exp(calBP/8267) - 1) - ic$d14c
d_minus <- ic$d14c - 1000 * (exp(-(age + ic$err)/8033) * exp(calBP/8267) - 1)
err_pm <- (d_plus + d_minus)/2
cat(sprintf("    err as 14C-yr -> D14C permil: mean %.3f (range %.3f-%.3f)\n", mean(err_pm), min(err_pm), max(err_pm)))
mod <- stats::approx(r$out$t, r$out$d14c_NH, xout = ic$year + 0.5, rule = 2)$y
res <- ic$d14c - mod
sd_code <- sqrt(ic$err^2 + LIK_D14C_REP_OTHER^2); sd_pm <- sqrt(err_pm^2 + LIK_D14C_REP_OTHER^2)
cat(sprintf("    residual rms %.3f permil; sd used %.2f (mean) vs permil-consistent %.2f\n", sqrt(mean(res^2)), mean(sd_code), mean(sd_pm)))
cat(sprintf("    row as coded %.4f (stream %.4f); with err converted to permil %.4f; chi2/n coded %.3f, converted %.3f\n",
    sum(dnorm(ic$d14c, mod, sd_code, log=TRUE)), st[["d14c_intcal"]], sum(dnorm(ic$d14c, mod, sd_pm, log=TRUE)),
    mean((res/sd_code)^2), mean((res/sd_pm)^2)))
cat(sprintf("    gradient weight (1/sd^2) ratio converted/coded: %.2f\n", mean(1/sd_pm^2)/mean(1/sd_code^2)))

## (2) seasonal rows: model instant month-centre vs obs monthly means; first-harmonic attenuation sinc(pi/12)
sincf <- sin(pi/12)/(pi/12)
ms <- ccx_model_stats(r$out, obs)
seas_row <- function(o, m, f) { k <- match(o$year, m$year); g <- !is.na(k)
  sum(dnorm(o$a[g], f*m$a[k[g]], o$sd_a, log=TRUE)) + sum(dnorm(o$b[g], f*m$b[k[g]], o$sd_b, log=TRUE)) }
cat(sprintf("\n[2] sinc(pi/12) = %.5f (monthly-mean attenuation of the first harmonic)\n", sincf))
for (nm in c("co2","d13")) for (s in c("MLO","SPO")) {
  o <- obs[[paste0(nm,"_seas")]][[s]]; m <- ms[[paste0(nm,"_seas")]][[s]]
  amp_m <- sqrt(mean(m$a[match(o$year,m$year)])^2 + mean(m$b[match(o$year,m$year)])^2); amp_o <- sqrt(o$a_mean^2+o$b_mean^2)
  cat(sprintf("    %s_%s: obs semi-amp %.4f, model %.4f (ratio %.4f); sd_a %.4f sd_b %.4f; row as coded %.3f, model monthly-meaned %.3f (delta %+.3f)\n",
      nm, s, amp_o, amp_m, amp_m/amp_o, o$sd_a, o$sd_b, seas_row(o, m, 1), seas_row(o, m, sincf), seas_row(o, m, sincf)-seas_row(o, m, 1)))
}

## (3) sigma_d14c absent -> silent zero rows
err2 <- err; err2$sigma_d14c <- NULL
st2 <- ccx_loglik(r$out, obs, err2, luc = eluc, by_stream = TRUE)
cat(sprintf("\n[3] err without sigma_d14c: d14c_NH = %s, d14c_SH = %s (with it: %.3f, %.3f)\n", format(st2[["d14c_NH"]]), format(st2[["d14c_SH"]]), st[["d14c_NH"]], st[["d14c_SH"]]))
