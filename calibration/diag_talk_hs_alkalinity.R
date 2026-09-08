# =====================================================================
# T-ALK (handoff 2026-09-08g §1, §4): per-box alkalinity for the COLD box,
# UNREFITTED, at the canonical hilda31.
#
# WHAT IT DECIDES. Whether salinity/alkalinity is a lever anywhere the
# objective scores. The model has no salinity state and ONE alkalinity
# (ALK_SURFACE 2300 umol/kg) for every box; the real high-latitude surface
# differs (the end-member probe's GLODAP bins). This pins the cold box's
# alkalinity at GLODAP's high-latitude surface value -- GENERATED here from
# the bottles by the end-member probe's own recipe, never typed -- through
# the `alk_hs` switch (2026-09-08g; absent = bit-exact) and reads the HS
# surface DIC and d13C rows, gate Q and gate G.
#
# PRE-REGISTERED (handoff §1): HS DIC moves ~ -40 umol/kg (the SIGN relative
# to the 2163 observation is the question); gate Q moves < 0.2 sigma.
# FALSIFIED IF: Q moves > 0.5 sigma -- then §4's "not a lever" is wrong.
#
# NOTHING IS ADOPTED. Usage: Rscript calibration/diag_talk_hs_alkalinity.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_glodap_obs.R"))
try_or <- function(expr, what) tryCatch(expr, error = function(e) { cat(sprintf("  (%s: %s)\n", what, conditionMessage(e))); NULL })

TA_LAT_HI <- 55; TA_LAT_LO <- 45; TA_SURF_M <- 50; TA_FLAG_OK <- 2      # = diag_hs_endmember_probe.R's bins
TA_CSV    <- ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv")
TA_P_DIC  <- 40      # prediction: |d HS DIC| of this order, umol/kg
TA_P_Q    <- 0.2     # prediction: gate Q moves less than this many sigma...
TA_Q_FALS <- 0.5     # ...and is falsified above this
TA_ROW_SHOW <- 1
TA_OUT <- ccx_path("outputs", "diagnostics", sprintf("talk_hs_alkalinity_%s.rds", format(Sys.Date(), "%Y%m%d")))

# ---- the observation, generated -------------------------------------------
stopifnot(file.exists(TA_CSV))
d  <- read.csv(TA_CSV); dt <- d[d$talkf == TA_FLAG_OK & !is.na(d$talk), ]
band <- function(lat) ifelse(abs(lat) >= TA_LAT_HI, "HI", ifelse(abs(lat) < TA_LAT_LO, "LO", "mid"))
row <- function(sel) { x <- dt$talk[sel]; c(median = stats::median(x), mean = mean(x), sd = stats::sd(x), n = length(x), yr = stats::median(dt$year[sel])) }
surf <- dt$depth <= TA_SURF_M
OBS <- list(talk_hi = row(surf & band(dt$lat) == "HI"), talk_hi_NH = row(surf & band(dt$lat) == "HI" & dt$lat > 0),
            talk_hi_SH = row(surf & band(dt$lat) == "HI" & dt$lat < 0), talk_lo = row(surf & band(dt$lat) == "LO"))
ALK0 <- ccx_const("ALK_SURFACE") * 1e6
cat(sprintf("=== GLODAPv2.2023 surface (<= %d m, flag %d) total alkalinity, umol/kg; the model holds %.0f in EVERY box ===\n", TA_SURF_M, TA_FLAG_OK, ALK0))
for (n in names(OBS)) cat(sprintf("  %-11s median %7.1f mean %7.1f sd %5.1f n %5d yr %.0f  (mean - %.0f = %+.1f)\n", n, OBS[[n]][["median"]], OBS[[n]][["mean"]], OBS[[n]][["sd"]], as.integer(OBS[[n]][["n"]]), OBS[[n]][["yr"]], ALK0, OBS[[n]][["mean"]] - ALK0))

# ---- arms -------------------------------------------------------------------
v <- dg_vector(CCX_MODE_CANONICAL); obs <- ccx_prepare_obs(); tg <- ccx_hs_surface_target(); tg7 <- dg_gcb_target(DG_SINK_WIN)
# ⚠ The bottles say the SH high-latitude surface (the DIC row's hemisphere) is at ~2296, i.e. AT the
# model's 2300; the handoff's "2256" is the ALL-high-latitude MEDIAN, carried by NH freshwater (NH ~2198).
# One scalar `alk_hs` serves both hemispheres' cold boxes, so the arms bracket what a per-hemisphere
# constant would do: hs_SH (the SH value), hs_all, hs_NH, and the mirror of hs_all (sign and linearity).
ARMS <- list(control = NULL, explicit = ALK0, hs_SH = OBS$talk_hi_SH[["mean"]], hs_all = OBS$talk_hi[["mean"]],
             hs_NH = OBS$talk_hi_NH[["mean"]], mirror = 2 * ALK0 - OBS$talk_hi[["mean"]])
read_arm <- function(alk_umol) {
  va <- v; if (!is.null(alk_umol)) va$p$alk_hs <- alk_umol * 1e-6
  r  <- dg_run(va); aux <- r$sp$aux; y <- r$sp$y
  d13 <- function(i) 1000 * (sum(y[i, "C13"]) / sum(y[i, "C"]) / ccx_const("R13_VPDB") - 1)
  pi <- setNames(lapply(HEMIS, function(h) { i <- aux$idx[[h]]
    c(hs = y[i$hs, "C"] * aux$mol_per_GtC / aux$hs_mass_kg[[h]] * 1e6, hd = y[i$hd, "C"] * aux$mol_per_GtC / (aux$a_hs[[h]] * aux$dz_hd * ccx_const("RHO_SEAWATER")) * 1e6,
      ml = y[i$ml, "C"] * aux$mol_per_GtC / aux$ml_mass_kg[[h]] * 1e6, d13_hs = d13(i$hs), d13_hd = d13(i$hd)) }), HEMIS)
  st <- dg_streams(r, va)
  gG <- try_or({ gr <- ccx_ocean_grid(va$p$h_ml); og <- dg_gateG_obs(gr); dg_gateG_verdict(dg_gateG(va, og), og) }, "gate G")
  list(alk = alk_umol, out = r$out, dic0_hs = aux$dic0_hs * 1e6, revelle0_hs = aux$revelle0_hs, pi = pi, st = st, lik = sum(unlist(st)),
       Q = dg_gateQ(r, va), G = gG, g7 = local({ g7v <- dg_gate7(r); c(g7v[c("ocean", "land")], dg_gate7_verdict(g7v, tg7)) }), hs = ccx_hs_surface_scored(r$out, r$sp))
}
RES <- lapply(ARMS, read_arm)
# GATE: the switch at the global constant reproduces the control BIT-EXACTLY
stopifnot(identical(RES$control$out, RES$explicit$out), identical(unlist(RES$control$st), unlist(RES$explicit$st)))
cat("\nGATE: alk_hs = ALK_SURFACE reproduces the canonical bit-exactly (out and every stream identical) -- PASS\n")

C0 <- RES$control
cat("\n=== 1. THE COLD BOX by arm (umol/kg; d13C permil) ===\n")
cat(sprintf("  %-9s %7s %7s %7s | %7s %7s %7s %7s | %8s %8s | %7s %6s | %8s %8s\n", "arm", "alk", "dic0_hs", "Revelle", "PI HS", "PI HD", "d13 HS", "d13 HD", "HS DIC@ep", "z(2163)", "HS d13C", "z", "GATE Q", "n_sd"))
for (a in names(RES)) { R <- RES[[a]]
  cat(sprintf("  %-9s %7.1f %7.1f %7.2f | %7.1f %7.1f %+7.2f %+7.2f | %8.1f %+8.2f | %+7.2f %+6.2f | %+8.3f %8.2f %s\n", a, if (is.null(R$alk)) ALK0 else R$alk, R$dic0_hs, R$revelle0_hs,
    R$pi$SH[["hs"]], R$pi$SH[["hd"]], R$pi$SH[["d13_hs"]], R$pi$SH[["d13_hd"]], R$hs$dic, (R$hs$dic - tg$dic$target) / R$hs$sd_eff[["dic"]],
    R$hs$d13c, (R$hs$d13c - tg$d13c$target) / R$hs$sd_eff[["d13c"]], R$Q$mean, R$Q$n_sd, if (R$Q$pass) "PASS" else "FAIL")) }
cat(sprintf("  (HS DIC observation %g +/- %.1f (sd_eff) at epoch %g, hemis %s; d13C %g +/- %.2f at %g)\n", tg$dic$target, C0$hs$sd_eff[["dic"]], tg$dic$epoch, tg$dic$hemis, tg$d13c$target, C0$hs$sd_eff[["d13c"]], tg$d13c$epoch))

cat("\n=== 2. GATES G and 7, and the likelihood ===\n")
for (a in names(RES)) { R <- RES[[a]]
  cat(sprintf("  %-9s GATE G z %+.2f d_umol %+.1f %s | GATE 7 ocean %.2f land %.2f %s | lik %+.2f (%.2f)\n", a, if (is.null(R$G)) NA else R$G$z, if (is.null(R$G)) NA else R$G$d_umol, if (is.null(R$G)) "n/a" else if (R$G$pass) "PASS" else "FAIL",
              R$g7$ocean, R$g7$land, if (R$g7$pass) "PASS" else "FAIL", R$lik - C0$lik, R$lik)) }
cat(sprintf("  rows with |d logL| > %g vs control:\n", TA_ROW_SHOW))
for (a in setdiff(names(RES), c("control", "explicit"))) { d <- unlist(RES[[a]]$st) - unlist(C0$st)
  cat(sprintf("    %-9s ", a)); for (n in names(d)[order(-abs(d))][abs(sort(-abs(d))) > TA_ROW_SHOW]) cat(sprintf("%s %+.2f; ", n, d[[n]])); cat("\n") }

cat("\n=== 3. VERDICT against the pre-registered predictions (arm hs_SH: the cold box at the SH high-latitude surface alkalinity) ===\n")
V <- list()
for (a in c("hs_SH", "hs_all", "hs_NH", "mirror")) { R <- RES[[a]]
  d_dic <- R$hs$dic - C0$hs$dic; d_alk <- R$alk - ALK0; dq <- (R$Q$mean - C0$Q$mean) / DG_Q_SD
  toward <- abs(R$hs$dic - tg$dic$target) < abs(C0$hs$dic - tg$dic$target)
  V[[a]] <- c(d_alk = d_alk, d_dic = d_dic, d_dic_per_alk = d_dic / d_alk, d_Q_sigma = dq, toward = toward, d_lik = R$lik - C0$lik)
  cat(sprintf("  %-7s alk %+6.1f -> HS DIC@epoch %+6.1f umol/kg (%.2f per unit alk; PI HS %+.1f) %s the 2163 observation | Q %+.3f sigma: %s | d13C HS %+.2f | lik %+.2f\n", a, d_alk, d_dic, d_dic / d_alk, R$pi$SH[["hs"]] - C0$pi$SH[["hs"]],
              if (toward) "TOWARD" else "AWAY FROM", dq, if (abs(dq) < TA_P_Q) "CONFIRMED (< 0.2 sigma: not a lever on Q)" else if (abs(dq) > TA_Q_FALS) "FALSIFIED (> 0.5 sigma: Q IS moved -- a lever)" else "between 0.2 and 0.5 sigma: neither",
              R$hs$d13c - C0$hs$d13c, R$lik - C0$lik)) }
saveRDS(list(obs = OBS, arms = lapply(RES, function(R) R[setdiff(names(R), "out")]), verdict = V, consts = list(p_dic = TA_P_DIC, p_q = TA_P_Q, q_fals = TA_Q_FALS, lat_hi = TA_LAT_HI, surf_m = TA_SURF_M), mode = CCX_MODE_CANONICAL, date = Sys.time()), TA_OUT)
cat(sprintf("\nsaved %s\n⛔ Nothing adopted: alk_hs stays ABSENT (= ALK_SURFACE, bit-exact) in every mode file.\n", TA_OUT))
