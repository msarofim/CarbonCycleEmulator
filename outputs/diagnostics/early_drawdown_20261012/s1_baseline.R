source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/lib_ed.R")
OUT <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/out"
dir.create(OUT, showWarnings = FALSE)
cat("commit:", ccx_git_stamp(), " canonical:", CCX_MODE_CANONICAL, "\n")
t0 <- Sys.time()
v <- dg_vector(CCX_MODE_CANONICAL)
cat("src:", v$src, " migrated:", paste(v$migrated, collapse = ","), "\n")
spin <- dg_spinup(v)
cat(sprintf("spinup %s: %.1f s\n", v$spinup_label, as.numeric(Sys.time() - t0, units = "secs")))

# ---- decoder + overlay self-checks ----
u_dec <- unlist(ccx_unc_to_par(v$md$u_mode))
pm_num <- unlist(v$md$par_mode[names(u_dec)])
cat(sprintf("decoder check max|unc_to_par(u_mode) - par_mode| = %.3g\n", max(abs(u_dec - pm_num))))
v0 <- ed_v_with(v, list())
cat("ed_v_with(v, list()) identical p:", identical(v0$p, v$p), "\n")
aux_re <- ccx_prepare(spin$params, grid = spin$grid)
cat("ccx_prepare(params) == spin$aux:", isTRUE(all.equal(aux_re, spin$aux)), "\n")

# ---- canonical PD100: unrolled vs ccx_pd100 ----
t1 <- Sys.time()
o <- ed_pd100(v, spin)
cat(sprintf("unrolled PD100: %.1f s; climate %s, converged %s (%d iter); hold dev %.3f ppm of %.2f\n",
            as.numeric(Sys.time() - t1, units = "secs"), o$climate, o$converged, o$iter, o$hold_dev, o$target))
o_ref <- ccx_pd100(spin, ED_END, v$bomb_total, v$luc_scale, climate = ED_CLIMATE)
cat(sprintf("max |irf_unrolled - irf_ccx_pd100| = %.3g\n", max(abs(o$irf - o_ref$irf))))
cat(sprintf("IRF 20/100/300 = %.3f / %.3f / %.3f ; TH20/50/100 = %.2f / %.2f / %.2f\n",
            ed_irf_at(o, 20), ed_irf_at(o, 100), ed_irf_at(o, 300), ed_th(o, 20), ed_th(o, 50), ed_th(o, 100)))
cat(sprintf("Joos T5 IRF 20/100/300 = %.3f / %.3f / %.3f\n", joos_irf(20), joos_irf(100), joos_irf(300)))

# ---- partition ----
d <- o$d
sub <- d$ml + d$hs + d$eq + d$tr + d$deep
cat(sprintf("ocean sub-box closure: max|ml+hs+eq+tr+deep - ocean_C| = %.3g GtC\n", max(abs(sub - d$ocean), na.rm = TRUE)))
cat(sprintf("mass closure max |air+ocean+land-100| = %.3g GtC\n", max(abs(d$air + d$ocean + d$land - JOOS_PULSE))))
tab <- do.call(rbind, lapply(ED_MARKS, function(h) { r <- d[ed_at(o, h), ]
  data.frame(t = h, t_row = r$t, air = r$air, ocean = r$ocean, land = r$land,
             ml = r$ml, hs = r$hs, eq = r$eq, tr = r$tr, deep = r$deep,
             J_air = 100 * joos_irf(h), J_ocean = ed_joos_fit("ocean", h), J_land = ed_joos_fit("land", h)) }))
print(format(tab, digits = 3), row.names = FALSE)

# ---- per-pool land / per-layer ocean: re-run the pair in SEGMENTS, keeping the state ----
mon <- function(a, ny) ccx_annual_to_monthly(seq_len(ny), a, seq_len(ny), method = "constant")
Fp <- o$Fp; ny <- nrow(Fp) / 12
Fq <- Fp; dm <- mon(o$dT, ny)
Fq$gmst <- Fp$gmst + dm
Fq$sst_anom_NH <- Fp$sst_anom_NH + CCX_SST_RATIO_NH * dm
Fq$sst_anom_SH <- Fp$sst_anom_SH + CCX_SST_RATIO_SH * dm
sb <- o$sp_rel; sq <- ccx_pulse_state(o$sp_rel, JOOS_PULSE)
idx <- sb$aux$idx; bn <- rownames(sb$y)
grp <- list(leaf = "leaf", wood = "wood", soil_fast = "soil_fast", soil_slow = "soil_slow")
cuts <- c(0, ED_MARKS)
rows <- list()
for (i in seq_along(ED_MARKS)) {
  k <- which(o$t >= cuts[i] - 1e-9 & o$t < cuts[i + 1] - 1e-9)
  sb <- ccx_pulse_continue(sb, Fp[k, , drop = FALSE]); sq <- ccx_pulse_continue(sq, Fq[k, , drop = FALSE])
  dy <- sq$y[, "C"] - sb$y[, "C"]
  pool <- function(nm) sum(dy[unlist(lapply(HEMIS, function(h) idx[[h]][[nm]]))])
  oc <- unlist(lapply(HEMIS, function(h) idx[[h]]$oc)); nl <- length(idx$NH$oc)
  ocl <- sapply(seq_len(nl), function(j) sum(dy[c(idx$NH$oc[j], idx$SH$oc[j])]))
  hd <- if (!is.null(idx$NH$hd)) sum(dy[c(idx$NH$hd, idx$SH$hd)]) else 0
  land_tot <- sum(dy[unlist(lapply(HEMIS, function(h) idx[[h]]$land))])
  # check against the unsegmented series at the segment's last row
  kk <- max(k)
  rows[[i]] <- data.frame(t = ED_MARKS[i], leaf = pool("leaf"), wood = pool("wood"),
                          soil_fast = pool("soil_fast"), soil_slow = pool("soil_slow"), land = land_tot,
                          land_unseg = d$land[kk], land_unseg_next = d$land[min(kk + 1, nrow(d))],
                          oc_top3 = sum(ocl[1:3]), oc_rest = sum(ocl[-(1:3)]), hd = hd,
                          air_seg = sum(dy[c(idx$NH$atm, idx$SH$atm)]), air_unseg = d$air[kk])
  if (i == 1) { layer_tab <- NULL }
  layer_tab <- rbind(layer_tab, c(t = ED_MARKS[i], ocl))
}
pools <- do.call(rbind, rows)
print(format(pools, digits = 4), row.names = FALSE)
g <- sb$grid
cat("ocean grid: h_ml", g$h_ml, " nl", g$nl, "\n dz:", paste(round(g$dz, 1), collapse = " "), "\n")
if (!is.null(g$z)) cat(" z:", paste(round(g$z, 0), collapse = " "), "\n")
cat("per-interior-layer dC (GtC), rows = t:\n"); print(round(layer_tab, 2))

p <- v$p
cat(sprintf("\nparams: beta_max %.4f fert_k %.2f q10 %.4f k_w %.1f h_ml %.2f kz %.1f kz_deep_frac %.4f hs_asx_frac %.4f h_hs %.1f u_hs %.2f\n",
            p$beta_max, p$fert_k, p$q10, p$k_w, p$h_ml, p$kz, p$kz_deep_frac, p$hs_asx_frac, p$h_hs, p$u_hs))
cat(sprintf("land: npp_veg_frac %s npp_leaf_frac %s tau_leaf %s tau_wood %s tau_soil_fast %s tau_soil_slow %s litter_slow_frac %s soil_inert_frac %s hs_frac %s ndep_ret %s npp_tsens %s\n",
            p$npp_veg_frac, p$npp_leaf_frac, p$tau_leaf, p$tau_wood, p$tau_soil_fast, p$tau_soil_slow,
            p$litter_slow_frac, p$soil_inert_frac, p$hs_frac, p$ndep_ret, p$npp_tsens))
cat("sd_unc:\n"); print(round(v$md$sd_unc, 4))
saveRDS(list(o = o[c("t", "irf", "d", "dT", "hold_dev", "target")], tab = tab, pools = pools,
             layer_tab = layer_tab, commit = ccx_git_stamp(), mode = CCX_MODE_CANONICAL),
        file.path(OUT, "s1_baseline.rds"))
cat(sprintf("total %.1f s\n", as.numeric(Sys.time() - t0, units = "secs")))
