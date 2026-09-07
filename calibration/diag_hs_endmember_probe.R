# =====================================================================
# diag_hs_endmember_probe.R -- THE HS BOX AGAINST GLODAP'S HIGH-LATITUDE SURFACE
# (2026-09-07d). Round 2 of the HILDA refit held the D14C profile and broke the
# DIC/d13C gradients; the diagnosis was that the conduit's HS water has "no
# biology". This reads the HS box's DIC and d13C DIRECTLY against the observed
# high-latitude surface bottles -- the observation the structure has never been
# compared with -- so the design ruling (HS pump / preformed end-member / stop)
# starts from a measured end-member error, not an inferred one. Adopts nothing.
# Usage: Rscript calibration/diag_hs_endmember_probe.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
HE_DIR      <- ccx_path("calibration", "output", "multistart_20260907b_hilda29")
HE_LAT_HI   <- 55       # |lat| >= this = high-latitude surface (HILDA's cold box ~16 % of area)
HE_LAT_LO   <- 45       # |lat| <  this = low-latitude surface
HE_SURF_M   <- 50       # bottle depth <= this = surface
HE_DEEP_M   <- 2000     # bottle depth >  this = deep
HE_FLAG_OK  <- 2        # WOCE flag 2 = good
HE_DIC_CSV  <- ccx_path("data-raw", "downloads", "glodap_dic_talk_subset.csv")
HE_C13_CSV  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
HE_OUT      <- ccx_path("outputs", "diagnostics", "hs_endmember_probe_20260907.rds")

# ---- observation: GLODAPv2.2023 bottles, GENERATED here, not typed ----------
d  <- read.csv(HE_DIC_CSV); c13 <- read.csv(HE_C13_CSV); c13 <- c13[c13$c13f == HE_FLAG_OK, ]
band <- function(lat) ifelse(abs(lat) >= HE_LAT_HI, "HI", ifelse(abs(lat) < HE_LAT_LO, "LO", "mid"))
row <- function(df, col, sel) { sel <- sel & !is.na(df[[col]]); x <- df[[col]][sel]
  c(median = stats::median(x), mean = mean(x), sd = stats::sd(x), n = length(x), yr = stats::median(df$year[sel])) }
dd <- d[d$tco2f == HE_FLAG_OK, ]; dt <- d[d$talkf == HE_FLAG_OK, ]
OBS <- list(
  dic_hi     = row(dd, "tco2", dd$depth <= HE_SURF_M & band(dd$lat) == "HI"),
  dic_hi_NH  = row(dd, "tco2", dd$depth <= HE_SURF_M & band(dd$lat) == "HI" & dd$lat > 0),
  dic_hi_SH  = row(dd, "tco2", dd$depth <= HE_SURF_M & band(dd$lat) == "HI" & dd$lat < 0),
  dic_lo     = row(dd, "tco2", dd$depth <= HE_SURF_M & band(dd$lat) == "LO"),
  dic_deep   = row(dd, "tco2", dd$depth >  HE_DEEP_M),
  talk_hi    = row(dt, "talk", dt$depth <= HE_SURF_M & band(dt$lat) == "HI"),
  talk_lo    = row(dt, "talk", dt$depth <= HE_SURF_M & band(dt$lat) == "LO"),
  talk_deep  = row(dt, "talk", dt$depth >  HE_DEEP_M),
  d13c_hi    = row(c13, "c13", c13$depth <= HE_SURF_M & band(c13$lat) == "HI"),
  d13c_lo    = row(c13, "c13", c13$depth <= HE_SURF_M & band(c13$lat) == "LO"),
  d13c_deep  = row(c13, "c13", c13$depth >  HE_DEEP_M))
cat(sprintf("\n=== GLODAPv2.2023 bottles, flag %d, surface <= %d m, deep > %d m, HI |lat| >= %d, LO |lat| < %d ===\n",
            HE_FLAG_OK, HE_SURF_M, HE_DEEP_M, HE_LAT_HI, HE_LAT_LO))
cat(sprintf("  %-10s %8s %8s %6s %6s %6s\n", "row", "median", "mean", "sd", "n", "yr"))
for (n in names(OBS)) cat(sprintf("  %-10s %8.2f %8.2f %6.2f %6d %6.0f\n", n, OBS[[n]][1], OBS[[n]][2], OBS[[n]][3], as.integer(OBS[[n]][4]), OBS[[n]][5]))
cat(sprintf("  => observed HI - LO surface DIC %+.0f (SH %+.0f); deep - HI %+.0f; deep - LO %+.0f umol/kg\n",
            OBS$dic_hi[1] - OBS$dic_lo[1], OBS$dic_hi_SH[1] - OBS$dic_lo[1], OBS$dic_deep[1] - OBS$dic_hi[1], OBS$dic_deep[1] - OBS$dic_lo[1]))
cat(sprintf("  => observed HI - LO surface d13C %+.2f; deep - HI %+.2f; deep - LO %+.2f permil\n",
            OBS$d13c_hi[1] - OBS$d13c_lo[1], OBS$d13c_deep[1] - OBS$d13c_hi[1], OBS$d13c_deep[1] - OBS$d13c_lo[1]))

# ---- model: the round-2 winner, its second family, and ent26 (structure OFF) -
fs <- list.files(HE_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
R <- lapply(fs, readRDS); lp <- vapply(R, `[[`, 0, "logpost"); basin <- round(lp, 2)
ag <- do.call(rbind, lapply(split(seq_along(R), basin), function(ix) data.frame(logpost = basin[ix[1]], n = length(ix), i = ix[which.max(lp[ix])])))
ag <- ag[order(-ag$logpost), ][1:2, ]
mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c,
                              rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(st) { p <- ccx_apply_structure(ccx_default_params(), "hilda"); p$pump_mode <- st$pump_mode; mk_v(ccx_overlay_par(p, st$par_mode), st$par_mode) }
yr_dic <- round(OBS$dic_hi[["yr"]]); yr_c13 <- round(OBS$d13c_hi[["yr"]])
rho <- ccx_const("RHO_SEAWATER")
read_boxes <- function(v, yr) {
  sp <- ccx_spinup(v$p); aux <- sp$aux; grid <- sp$grid; nl <- grid$nl
  F  <- ccx_build_forcing("historical", c(DG_YEARS[1], yr), prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  r  <- ccx_run_fast(sp, F); st <- r$state; pco2 <- mean(c(utils::tail(r$out$co2_NH, 1), utils::tail(r$out$co2_SH, 1)))
  conc <- function(y, i, m) y[i, "C"] * aux$mol_per_GtC / m * 1e6
  d13  <- function(y, i) 1000 * (sum(y[i, "C13"]) / sum(y[i, "C"]) / ccx_const("R13_VPDB") - 1)
  one <- function(y) {
    out <- list()
    for (h in HEMIS) { ix <- aux$idx[[h]]
      out[[h]] <- c(ml = conc(y, ix$ml, aux$ml_mass_kg[[h]]), bot = conc(y, utils::tail(ix$oc, 1), aux$a_ls[[h]] * grid$dz[nl + 1] * rho),
                    hs = if (aux$hs_on == 1L) conc(y, ix$hs, aux$hs_mass_kg[[h]]) else NA, hd = if (aux$hs_on == 1L) conc(y, ix$hd, aux$a_hs[[h]] * aux$dz_hd * rho) else NA,
                    ml13 = d13(y, ix$ml), bot13 = d13(y, utils::tail(ix$oc, 1)), hs13 = if (aux$hs_on == 1L) d13(y, ix$hs) else NA, hd13 = if (aux$hs_on == 1L) d13(y, ix$hd) else NA) }
    out }
  eq <- tryCatch(c(hs = ccx_dic_for_pco2(pco2, ccx_const("ALK_SURFACE"), aux$sst_hs) * 1e6, ml_NH = ccx_dic_for_pco2(pco2, ccx_const("ALK_SURFACE"), aux$sst$NH) * 1e6), error = function(e) c(hs = NA, ml_NH = NA))
  list(pi = one(sp$y), now = one(st), yr = yr, pco2 = pco2, eq_dic = eq, sst_hs = aux$sst_hs, sst_ml = unlist(aux$sst))
}
arms <- list(); v0 <- dg_vector(CCX_MODE_CANONICAL); v0$p$hs_frac <- 0
arms[["ent26 OFF"]] <- v0
for (k in seq_len(nrow(ag))) arms[[sprintf("basin %.2f (n %d)", ag$logpost[k], ag$n[k])]] <- v_of(R[[ag$i[k]]])
RES <- lapply(arms, read_boxes, yr = yr_dic)
cat(sprintf("\n=== MODEL BOXES at %d (the DIC bottles' median year); umol/kg and permil; NH / SH ===\n", yr_dic))
cat(sprintf("  %-22s | %13s %13s %13s %13s | %11s %11s %11s %11s | %s\n", "arm", "ML DIC", "HS DIC", "HD DIC", "bottom DIC", "ML d13C", "HS d13C", "HD d13C", "bot d13C", "HS eq. DIC @sst_hs"))
fmt2 <- function(x, a, b) sprintf("%6.0f/%6.0f", x$NH[[a]], x$SH[[a]])
fmt3 <- function(x, a) sprintf("%+5.2f/%+5.2f", x$NH[[a]], x$SH[[a]])
for (n in names(RES)) { x <- RES[[n]]$now
  cat(sprintf("  %-22s | %13s %13s %13s %13s | %11s %11s %11s %11s | %6.0f (ML eq %6.0f)\n", n, fmt2(x, "ml"), fmt2(x, "hs"), fmt2(x, "hd"), fmt2(x, "bot"),
              fmt3(x, "ml13"), fmt3(x, "hs13"), fmt3(x, "hd13"), fmt3(x, "bot13"), RES[[n]]$eq_dic[["hs"]], RES[[n]]$eq_dic[["ml_NH"]])) }
cat(sprintf("  OBS (median)           | %13s %13s %13s %13s | %11s %11s %11s %11s |\n",
            sprintf("%6.0f (LO)", OBS$dic_lo[1]), sprintf("%6.0f/%6.0f", OBS$dic_hi_NH[1], OBS$dic_hi_SH[1]), "-", sprintf("%6.0f (deep)", OBS$dic_deep[1]),
            sprintf("%+5.2f (LO)", OBS$d13c_lo[1]), sprintf("%+5.2f (HI)", OBS$d13c_hi[1]), "-", sprintf("%+5.2f (deep)", OBS$d13c_deep[1])))
cat("\n  READ IT AS: HS DIC vs the HI row (is the end-member's DIC too low?); HS d13C vs the HI row (is it too heavy?);\n")
cat("  HS eq. DIC = full air-sea equilibrium at sst_hs with ALK_SURFACE -- HS above it means upwelled/undegassed water, below it means over-stripped.\n")
cat("  d13C bottles are Suess-shifted and centred later than the DIC bottles; compare CONTRASTS (HI - LO, deep - HI) before levels.\n")
for (n in names(RES)) { x <- RES[[n]]$now; w <- function(a) mean(c(x$NH[[a]], x$SH[[a]]))
  cat(sprintf("  %-22s model contrasts: HS-ML DIC %+6.0f  bot-HS DIC %+6.0f  bot-ML DIC %+6.0f | HS-ML d13C %+5.2f  bot-HS d13C %+5.2f  bot-ML d13C %+5.2f\n", n,
              w("hs") - w("ml"), w("bot") - w("hs"), w("bot") - w("ml"), w("hs13") - w("ml13"), w("bot13") - w("hs13"), w("bot13") - w("ml13"))) }
cat(sprintf("  %-22s obs   contrasts: HI-LO DIC %+6.0f  deep-HI DIC %+6.0f  deep-LO DIC %+6.0f | HI-LO d13C %+5.2f  deep-HI d13C %+5.2f  deep-LO d13C %+5.2f\n", "GLODAP",
            OBS$dic_hi[1] - OBS$dic_lo[1], OBS$dic_deep[1] - OBS$dic_hi[1], OBS$dic_deep[1] - OBS$dic_lo[1], OBS$d13c_hi[1] - OBS$d13c_lo[1], OBS$d13c_deep[1] - OBS$d13c_hi[1], OBS$d13c_deep[1] - OBS$d13c_lo[1]))
cat("\n  ⛔ Nothing adopted; a probe for the design ruling.\n")
saveRDS(list(obs = OBS, model = RES, consts = list(lat_hi = HE_LAT_HI, lat_lo = HE_LAT_LO, surf_m = HE_SURF_M, deep_m = HE_DEEP_M)), HE_OUT); cat(sprintf("  saved %s\n", HE_OUT))
