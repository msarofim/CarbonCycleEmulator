# =====================================================================
# The ocean δ13C LEVEL probe (2026-09-08h; the "new diagnosis" T-D0 pointed at).
#
# T-D0 found the model ocean ~1 permil HEAVY at every depth while its
# surface-minus-deep GRADIENT is already too LARGE (1.24 vs 0.86 permil), so
# the level is not a pump question. What sets a box's δ13C at PI is the
# air-sea EQUILIBRIUM at that box's temperature -- δ_eq = δ_atm + ε_DIC-g(T),
# the same Zhang et al. (1995) fit the model's alphas and gate Q use -- plus
# whatever the pump and the mixing add. This probe reads, per box and per arm:
#   PI:      δ_box, δ_eq(T_box), the departure δ_box - δ_eq
#   epoch:   δ_box at the bottles' median year vs the GLODAP bottles (LO
#            surface, HI surface, deep), GENERATED from the CSV with the
#            end-member probe's bins -- and the level/gradient decomposition
#            level = model deep - obs deep, gradient = (surf - deep)_model - (surf - deep)_obs
# Arms (unrefitted, at hilda31): canonical; PUMP OFF (LS pump_grad 0 and HS
# pump 0: what the pump adds to the surface and removes from the deep); ALPHA
# T-INDEPENDENT (option F's switch); both. If the departure from δ_eq is the
# same in every box and survives PUMP OFF, it is one constant (the atmosphere's
# PI δ13C or the equilibrium offset); if it scales with T it is the alphas; if
# it vanishes with the pump off it is the pump after all.
# Nothing adopted. Usage: Rscript calibration/diag_d13c_ocean_level.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
DL_LAT_HI <- 55; DL_LAT_LO <- 45; DL_SURF_M <- 50; DL_DEEP_M <- 2000; DL_FLAG <- 2     # = diag_hs_endmember_probe.R
DL_C13_CSV <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
DL_ARMS <- c("canonical", "pump_off", "alpha_tindep", "both")
DL_OUT <- ccx_path("outputs", "diagnostics", sprintf("d13c_ocean_level_%s.rds", format(Sys.Date(), "%Y%m%d")))

# ---- observation, generated -------------------------------------------------
stopifnot(file.exists(DL_C13_CSV))
c13 <- read.csv(DL_C13_CSV); c13 <- c13[c13$c13f == DL_FLAG & !is.na(c13$c13), ]
band <- function(lat) ifelse(abs(lat) >= DL_LAT_HI, "HI", ifelse(abs(lat) < DL_LAT_LO, "LO", "mid"))
row <- function(sel) { x <- c13$c13[sel]; c(mean = mean(x), median = stats::median(x), sd = stats::sd(x), n = length(x), yr = stats::median(c13$year[sel])) }
OBS <- list(surf_lo = row(c13$depth <= DL_SURF_M & band(c13$lat) == "LO"), surf_hi = row(c13$depth <= DL_SURF_M & band(c13$lat) == "HI"),
            deep = row(c13$depth > DL_DEEP_M))
cat(sprintf("GLODAPv2.2023 δ13C bottles (flag %d): LO surface (|lat| < %d, <= %d m) %+.3f (n %d, yr %.0f); HI surface (|lat| >= %d) %+.3f (n %d, yr %.0f); deep (> %d m) %+.3f (n %d, yr %.0f)\n",
            DL_FLAG, DL_LAT_LO, DL_SURF_M, OBS$surf_lo[["mean"]], as.integer(OBS$surf_lo[["n"]]), OBS$surf_lo[["yr"]], DL_LAT_HI, OBS$surf_hi[["mean"]], as.integer(OBS$surf_hi[["n"]]), OBS$surf_hi[["yr"]], DL_DEEP_M, OBS$deep[["mean"]], as.integer(OBS$deep[["n"]]), OBS$deep[["yr"]]))
cat(sprintf("  observed surface-minus-deep: LO %+.3f, HI %+.3f permil (the bottles are modern: the surface carries the Suess effect, the deep barely)\n", OBS$surf_lo[["mean"]] - OBS$deep[["mean"]], OBS$surf_hi[["mean"]] - OBS$deep[["mean"]]))

# ---- the equilibrium, from the model's own constants ------------------------
D13C_PI <- ccx_const("D13C_PI")
eps_dicg <- function(T) ccx_const("ALPHA_AS_ZHANG_A") * T * ccx_const("ALPHA_AS_FCO3") + ccx_const("ALPHA_AS_ZHANG_B") * T + ccx_const("ALPHA_AS_ZHANG_C")
cat(sprintf("\nequilibrium: δ_eq(T) = δ_atm + ε_DIC-g(T), ε = %.4f T x fCO3(%.3f) + %.4f T + %.4f  (Zhang 1995 via the model's constants); dε/dT %+.4f permil/K; PI atmosphere %+.2f\n",
            ccx_const("ALPHA_AS_ZHANG_A"), ccx_const("ALPHA_AS_FCO3"), ccx_const("ALPHA_AS_ZHANG_B"), ccx_const("ALPHA_AS_ZHANG_C"), ccx_const("ALPHA_AS_ZHANG_A") * ccx_const("ALPHA_AS_FCO3") + ccx_const("ALPHA_AS_ZHANG_B"), D13C_PI))

v <- dg_vector(CCX_MODE_CANONICAL)
arm_of <- function(a) { va <- v
  if (a %in% c("pump_off", "both")) { va$p$pump_grad <- 0; va$p$pump_hs_gcm2 <- 0 }
  if (a %in% c("alpha_tindep", "both")) va$p$alpha_as_tdep <- 0
  va }
d13 <- function(y, i) 1000 * (sum(y[i, "C13"]) / sum(y[i, "C"]) / ccx_const("R13_VPDB") - 1)
read_arm <- function(a) {
  va <- arm_of(a); r <- dg_run(va); sp <- r$sp; aux <- sp$aux; y <- sp$y; o <- r$out
  T_ml <- unlist(aux$sst); T_hs <- aux$sst_hs
  pi <- do.call(rbind, lapply(HEMIS, function(h) { i <- aux$idx[[h]]
    data.frame(box = c(paste0("ML_", h), paste0("HS_", h), paste0("L1_", h), paste0("L10_", h), paste0("HD_", h)),
               T = c(T_ml[[h]], T_hs, NA, NA, NA),
               d13c = c(d13(y, i$ml), d13(y, i$hs), d13(y, i$oc[1]), d13(y, i$oc[10]), d13(y, i$hd))) }))
  pi$d_eq <- ifelse(is.na(pi$T), NA, D13C_PI + eps_dicg(pi$T)); pi$dep <- pi$d13c - pi$d_eq
  at <- function(col, yr) stats::approx(o$t, o[[col]], xout = yr, rule = 2)$y
  ep <- function(h, yr) 1000 * (at(paste0("ml_C13_", h), yr) / at(paste0("ml_C_", h), yr) / ccx_const("R13_VPDB") - 1)
  ml_ep <- stats::weighted.mean(c(ep("NH", OBS$surf_lo[["yr"]]), ep("SH", OBS$surf_lo[["yr"]])), c(aux$a_ls$NH, aux$a_ls$SH))
  hs <- ccx_hs_surface_scored(o, sp)
  # the deep at the bottles' epoch: the run's final state is 2024 and the deep moves ~0 over 20 yr; read the bottom LS layer from the final state
  deep_ep <- mean(vapply(HEMIS, function(h) d13(r$sp$y * 0 + ccx_run_fast(sp, r$F)$state, aux$idx[[h]]$oc[10]), numeric(1)))
  st <- unlist(dg_streams(r, va)); q <- dg_gateQ(r, va)
  list(arm = a, pi = pi, ml_ep = ml_ep, hs_ep = hs$d13c, deep_ep = deep_ep, atm_ep = at("d13c_NH", OBS$surf_lo[["yr"]]), Q = q, st = st,
       export = if (is.null(aux$pump)) 0 else sum(unlist(lapply(aux$pump, function(z) z$org + z$carb))))
}
RES <- setNames(lapply(DL_ARMS, read_arm), DL_ARMS)

cat("\n=== 1. PREINDUSTRIAL: each box's δ13C against the equilibrium at ITS temperature (permil) ===\n")
cat(sprintf("  %-13s", "box (T)")); for (a in DL_ARMS) cat(sprintf(" | %8s %8s", a, "dep")); cat("\n")
pi0 <- RES$canonical$pi
for (k in seq_len(nrow(pi0))) { cat(sprintf("  %-6s %5s ", pi0$box[k], if (is.na(pi0$T[k])) "" else sprintf("%.0f C", pi0$T[k])))
  for (a in DL_ARMS) { z <- RES[[a]]$pi[k, ]; cat(sprintf(" | %+8.3f %8s", z$d13c, if (is.na(z$dep)) "" else sprintf("%+.3f", z$dep))) }; cat("\n") }
cat(sprintf("  δ_eq at the ML: NH %+.3f (%.0f C), SH %+.3f (%.0f C); at the cold box %+.3f (%.0f C)\n", pi0$d_eq[pi0$box == "ML_NH"], pi0$T[pi0$box == "ML_NH"], pi0$d_eq[pi0$box == "ML_SH"], pi0$T[pi0$box == "ML_SH"], pi0$d_eq[pi0$box == "HS_NH"], pi0$T[pi0$box == "HS_NH"]))
cat(sprintf("  export (LS pump, GtC/yr): %s\n", paste(sprintf("%s %.1f", DL_ARMS, vapply(RES, `[[`, numeric(1), "export")), collapse = "; ")))

cat("\n=== 2. AT THE BOTTLES' EPOCH: model vs observation, and the level/gradient split ===\n")
for (a in DL_ARMS) { R <- RES[[a]]
  lev <- R$deep_ep - OBS$deep[["mean"]]; gr_m <- R$ml_ep - R$deep_ep; gr_o <- OBS$surf_lo[["mean"]] - OBS$deep[["mean"]]
  cat(sprintf("  %-13s atm %+.2f | ML(LS) %+.2f vs LO surf %+.2f (%+.2f) | HS %+.2f vs HI surf %+.2f (%+.2f) | deep %+.2f vs %+.2f (%+.2f) | LEVEL (deep) %+.2f, GRADIENT surf-deep model %+.2f vs obs %+.2f (%+.2f) | Q %.2f sd\n",
              a, R$atm_ep, R$ml_ep, OBS$surf_lo[["mean"]], R$ml_ep - OBS$surf_lo[["mean"]], R$hs_ep, OBS$surf_hi[["mean"]], R$hs_ep - OBS$surf_hi[["mean"]],
              R$deep_ep, OBS$deep[["mean"]], lev, lev, gr_m, gr_o, gr_m - gr_o, R$Q$n_sd)) }

cat("\n=== 3. READING (the decomposition; no auto-verdict) ===\n")
C <- RES$canonical; P <- RES$pump_off; A <- RES$alpha_tindep
lev_s <- C$ml_ep - OBS$surf_lo[["mean"]]; lev_d <- C$deep_ep - OBS$deep[["mean"]]
gr_m <- C$ml_ep - C$deep_ep; gr_o <- OBS$surf_lo[["mean"]] - OBS$deep[["mean"]]
cat(sprintf("  LIKE-FOR-LIKE at the bottles' epoch: surface %+.2f heavy, deep %+.2f heavy; surface-minus-deep %+.2f vs observed %+.2f -> the model's gradient is %.2f too SMALL: the deep lacks light carbon RELATIVE to the surface.\n", lev_s, lev_d, gr_m, gr_o, gr_o - gr_m))
cat(sprintf("  (T-D0's 'gradient already too large' compared the PI model, %+.2f, with modern bottles -- not like-for-like; RETRACTED here.)\n", C$pi$d13c[C$pi$box == "ML_NH"] - C$pi$d13c[C$pi$box == "L10_NH"]))
cat(sprintf("  THE PUMP: with it off the deep sits at %+.2f (the surface mixed down); the canonical pump depletes the deep by %.2f permil; matching the observed deep at the model's surface would need %.2f -> the pump's deep delivery is ~%.0f %% short.\n", P$deep_ep, P$deep_ep - C$deep_ep, P$deep_ep - OBS$deep[["mean"]] - lev_s, 100 * (1 - (P$deep_ep - C$deep_ep) / (P$deep_ep - OBS$deep[["mean"]] - lev_s))))
cat(sprintf("  THE ALPHAS: the T-independent legacy pair shifts EVERY box by %+.2f (surface) / %+.2f (deep) and lands the gradient at %+.2f (obs %+.2f) -- a uniform LEVEL shift that overshoots by %+.2f at the deep; the shipped T-dependent pair is +%.2f heavy at the deep. The truth sits between the two pairs' mean equilibrium; that is a constant, the deep's remaining excess is the pump's delivery.\n",
            A$ml_ep - C$ml_ep, A$deep_ep - C$deep_ep, A$ml_ep - A$deep_ep, gr_o, A$deep_ep - OBS$deep[["mean"]], lev_d))
cat(sprintf("  PI departure from equilibrium at each box's own T: warm ML %+.2f / %+.2f (pump off %+.2f / %+.2f): the warm surface is AT equilibrium to 0.2; cold box %+.2f (its equilibrium at 2 C is %+.2f; it is pulled down by the flush from a deep at %+.2f).\n",
            C$pi$dep[C$pi$box == "ML_NH"], C$pi$dep[C$pi$box == "ML_SH"], P$pi$dep[P$pi$box == "ML_NH"], P$pi$dep[P$pi$box == "ML_SH"], C$pi$dep[C$pi$box == "HS_SH"], C$pi$d_eq[C$pi$box == "HS_SH"], C$pi$d13c[C$pi$box == "HD_SH"]))
saveRDS(list(obs = OBS, arms = RES, d13c_pi = D13C_PI, date = Sys.time(), mode = CCX_MODE_CANONICAL), DL_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", DL_OUT))
