source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/lib_ed.R")
cat("commit:", ccx_git_stamp(), " mode:", CCX_MODE_CANONICAL, "\n")
v <- dg_vector(CCX_MODE_CANONICAL); spin <- dg_spinup(v); p <- v$p
mod <- function(...) { q <- p; a <- list(...); for (n in names(a)) q[[n]] <- a[[n]]; q }
kw_obs <- ccx_const("KW_PRIOR_CENTRE")
C <- list("canonical" = NULL,
          "k_w 1446 (Naegler centre)" = mod(k_w = kw_obs),
          "k_w x0.5" = mod(k_w = p$k_w * 0.5),
          "kz x0.5" = mod(kz = p$kz * 0.5),
          "HS exchange x0.1 (hs_asx_frac)" = mod(hs_asx_frac = p$hs_asx_frac * 0.1),
          "surface-only ocean" = mod(kz = 1e-3, u_hs = 1e-3),
          "beta_max x0.75" = mod(beta_max = p$beta_max * 0.75),
          "npp_leaf_frac 0.8 [unfitted]" = mod(npp_leaf_frac = 0.8),
          "k_w 1446 + beta_max x0.70" = mod(k_w = kw_obs, beta_max = p$beta_max * 0.70))
rows <- lapply(names(C), function(nm) {
  o <- ed_pd100(v, spin, p_after = C[[nm]])
  data.frame(case = nm, irf1 = ed_irf_at(o, 1), irf2 = ed_irf_at(o, 2), irf20 = ed_irf_at(o, 20), irf100 = ed_irf_at(o, 100),
             oc1 = ed_at(o, 1, "ocean"), ld1 = ed_at(o, 1, "land"), oc2 = ed_at(o, 2, "ocean"), ld2 = ed_at(o, 2, "land"),
             oc20 = ed_at(o, 20, "ocean"), ld20 = ed_at(o, 20, "land"), oc100 = ed_at(o, 100, "ocean"), ld100 = ed_at(o, 100, "land"),
             conv = o$converged)
})
R <- do.call(rbind, rows)
R <- rbind(R, data.frame(case = "Joos T5 fits", irf1 = joos_irf(1), irf2 = joos_irf(2), irf20 = joos_irf(20), irf100 = joos_irf(100),
                         oc1 = ed_joos_fit("ocean", 1), ld1 = ed_joos_fit("land", 1), oc2 = ed_joos_fit("ocean", 2), ld2 = ed_joos_fit("land", 2),
                         oc20 = ed_joos_fit("ocean", 20), ld20 = ed_joos_fit("land", 20), oc100 = ed_joos_fit("ocean", 100), ld100 = ed_joos_fit("land", 100), conv = NA))
print(format(R, digits = 4), row.names = FALSE)
