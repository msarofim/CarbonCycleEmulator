# =====================================================================
# diag_d13c_isoflux_budget.R -- THE ATMOSPHERE'S 13C BUDGET BY HEMISPHERE AND PROCESS (2026-09-20 t)
#
# The MLO-SPO d13C gradient miss is a constant -0.0668 permil that needs +64 GtC-permil/yr of
# NH-minus-SH isoflux the model lacks ([[ccx_d13c_gradient_offset_additive]]). This reads WHICH
# processes carry the model's hemispheric isoflux, from the derivative's own 13C edge tap
# (R/model.R `.edges13`, 09-20 t; test-fluxes.R proves it closes dy[, "C13"] exactly), so the
# +64 can be located rather than guessed. Every number is the model's; the observation side of
# each class is named where one exists.
#
# DEFINITION. For the atmosphere box of hemisphere h with d13C d_a, an edge carrying F GtC/yr at
# d13C d_c contributes an ISOFLUX I = +F (d_c - d_a) if it enters the box and -F (d_c - d_a) if it
# leaves (GtC-permil/yr). C_atm d(d_a)/dt = sum of I over all edges (mixing included), and the
# two-box steady gradient is (I_NH - I_SH excluding the mixing edges) / (2 k C_hemi), i.e. the
# asymmetry x the GAIN measured 09-20 s (0.00105 permil per GtC-permil/yr).
# CLASSES: fossil (external row), land_in (veg + soil -> atm: Ra, Rh, LUC, the seasonal return),
# land_out (atm -> veg: GPP, the seasonal draw), ocean_in (surface boxes -> atm: evasion),
# ocean_out (invasion), exchange (the other atmosphere box, both ways).
# The run is the R core (ccx_run with the edge hook) from the canonical's own spinup; the R and
# C++ cores are twins (test-cpp-parity), so the trajectory is the canonical's.
# Output: outputs/diagnostics/d13c_isoflux_budget_<date>.{log,rds}
# Usage: Rscript calibration/diag_d13c_isoflux_budget.R   (~5-10 min: the R core over 1750-2025)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
IB_OUT   <- ccx_path("outputs", "diagnostics", sprintf("d13c_isoflux_budget_%s", format(Sys.Date(), "%Y%m%d")))
IB_WIN   <- c(1980, 2023)      # the years both stations have d13C -- the offset's window
IB_GAIN  <- 0.00105            # permil per GtC-permil/yr, MEASURED 09-20 s (d13c_gradient_offset_20260920.log [3])
IB_NEED  <- 0.0668 / IB_GAIN   # the offset's isoflux requirement
IB_CLASSES <- c("fossil", "land_in", "land_out", "ocean_in", "ocean_out", "exchange")
sink_log <- file(paste0(IB_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
can <- dg_vector(CCX_MODE_CANONICAL)
# 2026-09-21 d (scoping 09-21 c, option A's second scan): an optional SH gas-exchange factor on the canonical's vector,
# IB_KW_FAC_SH (NCEP wind^2 says 1.14); the output name carries it so the canonical's own budget is never overwritten.
IB_KW_FAC_SH <- as.numeric(Sys.getenv("IB_KW_FAC_SH", "1"))
if (IB_KW_FAC_SH != 1) { can$p$k_w_fac_SH <- IB_KW_FAC_SH; IB_OUT <- sprintf("%s_kwSH%g", IB_OUT, IB_KW_FAC_SH); sink(); close(sink_log)
  sink_log <- file(paste0(IB_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE) }
sp <- dg_spinup(can)
F <- withCallingHandlers(ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = can$bomb_total, luc_scale = can$luc_scale),
                         warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
cat(sprintf("THE ATMOSPHERE'S HEMISPHERIC 13C BUDGET at %s  %s\n  %s\n  window %d-%d; gain %.5f; the offset needs %+.0f GtC-permil/yr%s\n",
            CCX_MODE_CANONICAL, format(Sys.time()), can$src, IB_WIN[1], IB_WIN[2], IB_GAIN, IB_NEED,
            if (IB_KW_FAC_SH != 1) sprintf("\n  ** k_w_fac_SH = %g on the canonical's vector (option A scan, 09-21 d) **", IB_KW_FAC_SH) else ""))
aux <- sp$aux; nb <- nrow(sp$y); cls <- ccx_flux_boxclass(aux, nb); R13 <- ccx_const("R13_VPDB")
atm <- c(NH = aux$idx$NH$atm, SH = aux$idx$SH$atm)
hook <- function(fl, y, t) {
  E <- fl$edges; E13 <- fl$edges13
  out <- matrix(0, 2, length(IB_CLASSES), dimnames = list(HEMIS, IB_CLASSES))
  Fc  <- out                                                # the CARBON flux per class, signed INTO the atmosphere
  for (h in HEMIS) {
    ia <- atm[[h]]; d_a <- 1000 * (y[ia, "C13"] / (y[ia, "C"] * R13) - 1)
    dcar <- function(F, F13) ifelse(F != 0, 1000 * (F13 / (F * R13) - 1), 0)
    # edges INTO the box: column ia + 1; rows = sources (row 1 external)
    Fin <- E[, ia + 1L]; Din <- dcar(Fin, E13[, ia + 1L]); Iin <- Fin * (Din - d_a)
    Fout <- E[ia + 1L, ]; Dout <- dcar(Fout, E13[ia + 1L, ]); Iout <- -Fout * (Dout - d_a)
    src <- c("ext", cls)                                   # row/col index -> class
    out[h, "fossil"]    <- sum(Iin[src == "ext"])
    out[h, "land_in"]   <- sum(Iin[src %in% c("veg", "soil")])
    out[h, "land_out"]  <- sum(Iout[src %in% c("veg", "soil")])
    out[h, "ocean_in"]  <- sum(Iin[src %in% c("ml", "int")])
    out[h, "ocean_out"] <- sum(Iout[src %in% c("ml", "int")])
    out[h, "exchange"]  <- sum(Iin[src == "atm"]) + sum(Iout[src == "atm"])
    Fc[h, "fossil"] <- sum(Fin[src == "ext"]); Fc[h, "land_in"] <- sum(Fin[src %in% c("veg", "soil")]); Fc[h, "land_out"] <- -sum(Fout[src %in% c("veg", "soil")])
    Fc[h, "ocean_in"] <- sum(Fin[src %in% c("ml", "int")]); Fc[h, "ocean_out"] <- -sum(Fout[src %in% c("ml", "int")]); Fc[h, "exchange"] <- sum(Fin[src == "atm"]) - sum(Fout[src == "atm"])
  }
  # the tendency this month, from the SAME edges (they close dy exactly): C d(d_a)/dt
  tend <- vapply(HEMIS, function(h) { ia <- atm[[h]] + 1L
    dC <- sum(E[, ia]) - sum(E[ia, ]); dC13 <- sum(E13[, ia]) - sum(E13[ia, ])
    C <- y[atm[[h]], "C"]; C13 <- y[atm[[h]], "C13"]
    1000 / R13 * (dC13 * C - C13 * dC) / C^2 * C }, 0)
  list(I = out, Fc = Fc, tend = tend, d_a = vapply(HEMIS, function(h) 1000 * (y[atm[[h]], "C13"] / (y[atm[[h]], "C"] * R13) - 1), 0))
}
t0 <- Sys.time(); r <- suppressWarnings(ccx_run(sp, F, edge_fn = hook)); cat(sprintf("  R-core run with the edge hook: %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
yr <- floor(r$out$t + 1e-9); k <- yr >= IB_WIN[1] & yr <= IB_WIN[2]
I <- Reduce(`+`, lapply(r$edge_trace[k], `[[`, "I")) / sum(k)          # window mean, GtC-permil/yr
tend <- Reduce(`+`, lapply(r$edge_trace[k], `[[`, "tend")) / sum(k)
Fc <- Reduce(`+`, lapply(r$edge_trace[k], `[[`, "Fc")) / sum(k)               # window-mean carbon flux per class, GtC/yr into the atmosphere
# the gradient the model actually has over the window, from the same run
grad <- mean((r$out$d13c_NH - r$out$d13c_SH)[k]); grad_cpp <- NULL
cat(sprintf("\n[1] WINDOW-MEAN ISOFLUX BY CLASS (GtC-permil/yr); asymmetry x gain = the class's share of the gradient\n  %-10s %9s %9s %9s %10s\n", "class", "NH", "SH", "NH-SH", "-> permil"))
asym <- I["NH", ] - I["SH", ]
for (cl in IB_CLASSES) cat(sprintf("  %-10s %+9.2f %+9.2f %+9.2f %+10.4f\n", cl, I["NH", cl], I["SH", cl], asym[[cl]], asym[[cl]] * IB_GAIN))
noex <- setdiff(IB_CLASSES, "exchange")
cat(sprintf("  %-10s %+9.2f %+9.2f %+9.2f %+10.4f   (the model's gradient over the window: %+.4f; obs %+.4f)\n", "SUM(no ex)", sum(I["NH", noex]), sum(I["SH", noex]), sum(asym[noex]), sum(asym[noex]) * IB_GAIN, grad, -0.0668))
cat(sprintf("  closure: sum over ALL classes NH %+.3f SH %+.3f vs C d(delta)/dt NH %+.3f SH %+.3f (identical by construction of the tap)\n", sum(I["NH", ]), sum(I["SH", ]), tend[["NH"]], tend[["SH"]]))
cat(sprintf("  two-box check: (asymmetry excl. exchange) x gain = %+.4f vs the model's gradient %+.4f -- %s\n", sum(asym[noex]) * IB_GAIN, grad,
            if (abs(sum(asym[noex]) * IB_GAIN - grad) < 0.01) "AGREE (< 0.01 permil; the tendency term is the rest)" else "DISAGREE: the gain or the classification is off"))
cat("\n[1b] THE CARBON FLUXES BEHIND THEM (GtC/yr, signed INTO the atmosphere; the net land / ocean SINK per hemisphere = -(in + out))\n")
for (cl in IB_CLASSES) cat(sprintf("  %-10s %+9.2f %+9.2f\n", cl, Fc["NH", cl], Fc["SH", cl]))
sinks <- list(land = -(Fc[, "land_in"] + Fc[, "land_out"]), ocean = -(Fc[, "ocean_in"] + Fc[, "ocean_out"]))
cat(sprintf("  net LAND sink  NH %+.2f SH %+.2f (NH share %.2f);  net OCEAN sink NH %+.2f SH %+.2f (NH share %.2f)  [window mean %d-%d]\n",
            sinks$land[["NH"]], sinks$land[["SH"]], sinks$land[["NH"]] / sum(sinks$land), sinks$ocean[["NH"]], sinks$ocean[["SH"]], sinks$ocean[["NH"]] / sum(sinks$ocean), IB_WIN[1], IB_WIN[2]))
cat(sprintf("  the land's isotopic DISEQUILIBRIUM per unit gross flux (net isoflux / gross in): NH %+.3f SH %+.3f permil; the ocean's (net isoflux / gross evasion): NH %+.3f SH %+.3f\n",
            (I["NH", "land_in"] + I["NH", "land_out"]) / Fc["NH", "land_in"], (I["SH", "land_in"] + I["SH", "land_out"]) / Fc["SH", "land_in"],
            (I["NH", "ocean_in"] + I["NH", "ocean_out"]) / Fc["NH", "ocean_in"], (I["SH", "ocean_in"] + I["SH", "ocean_out"]) / Fc["SH", "ocean_in"]))
cat(sprintf("  moving 1 GtC/yr of NH sink from the ocean to the land at eps %.1f is worth %+.0f GtC-permil/yr (%+.4f permil) at a FIXED CO2 gradient\n", ccx_const("ALPHA_PHOTO_EPS"), ccx_const("ALPHA_PHOTO_EPS"), ccx_const("ALPHA_PHOTO_EPS") * IB_GAIN))
cat(sprintf("\n[2] WHERE +%.0f GtC-permil/yr COULD COME FROM. Each class's NH-SH asymmetry above is what the model has; the offset is what the real atmosphere has beyond it.\n", IB_NEED))
cat(sprintf("  fossil:    %+.1f -- E_NH-E_SH at (d13c_foss - d_atm); FORC_FOSS_NH_SHARE 0.920 is measured; only the signature moves it (+-2 permil = +-%.0f)\n", asym[["fossil"]], mean(F$e_foss_NH[k] - F$e_foss_SH[k]) * 2))
cat(sprintf("  land:      in %+.1f out %+.1f net %+.1f -- the NH-heavy land (npp_frac_NH %.2f) returns old (heavier) carbon and draws at -eps; a NET land sink S_h contributes ~+eps x S_h (eps %.1f): the model's NH-SH land-sink asymmetry is IN this number\n",
            asym[["land_in"]], asym[["land_out"]], asym[["land_in"]] + asym[["land_out"]], can$p$npp_frac_NH, ccx_const("ALPHA_PHOTO_EPS")))
cat(sprintf("  ocean:     in %+.1f out %+.1f net %+.1f -- the air-sea disequilibrium isoflux by hemisphere (obs: data/obs_hemi_diseq.rds, GATE D)\n", asym[["ocean_in"]], asym[["ocean_out"]], asym[["ocean_in"]] + asym[["ocean_out"]]))
saveRDS(list(I = I, Fc = Fc, sinks = sinks, asym = asym, tend = tend, grad = grad, window = IB_WIN, gain = IB_GAIN, need = IB_NEED, canonical = CCX_MODE_CANONICAL,
             monthly = lapply(r$edge_trace, `[[`, "I"), t = r$out$t, built = format(Sys.time())), paste0(IB_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", IB_OUT))
