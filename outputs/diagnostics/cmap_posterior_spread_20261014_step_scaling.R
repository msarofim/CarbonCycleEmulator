# Is the MLVM leverage on the two widest rows SMOOTH in the step (bug test for integrator jumps)?
# Smooth: |d(h/2)| ~ |d(h)|/2 (slope-dominated) to /4 (curvature-dominated). A jump: |d(h/2)| ~ |d(h)|.
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
invisible(ccx_apply_gate(ccx_mode_struct(md))); pins <- ccx_mode_pins(md); invisible(ccx_apply_pins(pins))
invisible(ccx_adopt_mode_band(md))
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
for (n in names(pins)) bp[[n]] <- pins[[n]]
st <- ccx_mode_start(md, "step_scaling")
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
cm <- readRDS("data/constraint_map.rds"); r <- readRDS("outputs/diagnostics/cmap_posterior_spread_20261014_hilda31w_n100.rds")
U <- readRDS("outputs/mcmc_check_20261014_hilda31w_200k/pooled_u_thin2.rds")
NM <- cm$component[["Mixed layer & vertical mixing"]]; ROWS <- c("Δ¹⁴C in the ocean", "CO₂ north–south gradient")
SS <- unlist(cm$family[ROWS])
pts <- list(mode = st$u[md$param_names], draw86 = U[r$join$row[86], ], draw41 = U[r$join$row[41], ], draw46 = U[r$join$row[46], ])
specs <- c(CCX_PARAM_TABLE, CCX_PARAM_GATED_ALL)
for (p in names(pts)) {
  u <- pts[[p]]; s0 <- attr(lp(u), "streams")
  cat(sprintf("\n== %s: h_ml %.2f m, kz %.0f ==\n", p, .from_unc(u[["h_ml"]], specs$h_ml), .from_unc(u[["kz"]], specs$kz)))
  for (n in NM) for (fr in c(1, 0.5, 0.25)) {
    h <- fr * cm$sd_conditional[[n]]
    d <- sapply(c(1, -1), function(sg) { uu <- u; uu[[n]] <- u[[n]] + sg * h
      v <- tryCatch(attr(lp(uu), "streams")[SS] - s0[SS], error = function(e) rep(NA, length(SS))); v })
    rowsum <- sapply(ROWS, function(R) { k <- cm$family[[R]]; c(plus = sum(abs(d[k, 1])), minus = sum(abs(d[k, 2]))) })
    cat(sprintf("  %-13s step x%.2f  d14C-ocean |d+| %.4f |d-| %.4f   CO2-grad |d+| %.4f |d-| %.4f\n", n, fr,
                rowsum[1, 1], rowsum[2, 1], rowsum[1, 2], rowsum[2, 2]))
  }
}
