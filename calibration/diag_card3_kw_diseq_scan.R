#!/usr/bin/env Rscript
# =====================================================================
# diag_card3_kw_diseq_scan.R -- card 3's "about 15%", re-measured at the canonical (group B item B20, 2026-11-11).
#
# WHY. Known-issues card 3: "the ocean bottles and the atmospheric δ¹³C decline disagree by about 15% on how fast the
# air and sea exchange isotopes -- the surface bottles want it slower, the atmospheric δ¹³C decline holds it where it
# is". That is calibration/diag_tau_iso_overdetermined.R at hilda29l (CHANGELOG 2026-09-21 g): k_w x0.85 put BOTH
# mixed-layer disequilibria D on the GLODAP bottles. Card 3's own 10-15 comment records that at hilda31w the
# hemisphere averages miss in OPPOSITE directions (north low, south high), and a uniform change in k_w moves both
# the same way, so "the bottles want it slower" may no longer be one statement. Not re-measured since hilda29l.
#
# WHAT. Stage 1 of the tau_iso driver, re-stated (its read_point() machinery, the dg path, exact zeros): k_w x KS_FAC
# at the canonical, everything else fixed. Per point: gate D's four regional D's and two hemisphere averages against
# the bottles (the numbers card 3's chart draws are the hemisphere averages), and the likelihood change by row
# family against the canonical. Then, per D, the k_w factor at which it meets its observation (linear interpolation
# in log k_w between bracketing points; "none in range" otherwise).
# The tau_iso driver's stage 2 (re-optimized nuisance sets) is NOT re-run: its sets name hilda29l's parameters, and at
# hilda31w the k_w = 1446 profile (CHANGELOG 10-13 q) found the cold-box names (hs_asx_frac, h_hs, u_hs) absorb k_w.
# The re-optimized reading at hilda31fl is the price profile (run_price_profile.R --hold=k_w=1446), read separately.
#
# Usage: Rscript calibration/diag_card3_kw_diseq_scan.R [--profile=<profile_k_w_A.rds>]   # ~2 min, read-only, no RNG
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants (every label and filename derives from these) ----------
KS_DRIVER <- "calibration/diag_card3_kw_diseq_scan.R"
KS_ARM    <- CCX_MODE_CANONICAL
KS_KW_LIT <- 1446                                           # Naegler 2009, card 7's literature value (KW_PRIOR_CENTRE)
KS_FAC    <- c(0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.00, 1.05, 1.10, 1.15, 1.20, 1.30)
KS_TYPED  <- 0.85                                           # card 3's "about 15%": hilda29l's x0.85 (09-21 g)
KS_FAMILIES <- c(d13c_level = "^d13c_level", d13c_seasonal = "^d13c_seasonal", d13c_other = "^d13c_(?!level|seasonal)",
                 d14c_atm = "^d14c_(NH|SH|intcal)$", d14c_ocean = "^(d14c_profile|excess_c14)", co2 = "^co2", gcb = "^gcb",
                 ocean_surface = "^(ocean_grad|hs_surf)")   # every row of the objective in exactly one family (gated below)
# d14c_intcal (tree rings) is ATMOSPHERIC Δ14C, as in diag_price_profile_read.R's FAM. Until 2026-11-11 19:10 the
# d14c_ocean pattern caught it ("d14c_ anything but NH/SH"); pre-fix outputs in outputs/quarantine/20261111_card3_intcal_family/.
KS_GATE_TOL <- 1e-6
KS_STEM <- file.path("outputs", "diagnostics", sprintf("card3_kw_diseq_scan_%s_%s", format(Sys.Date(), "%Y%m%d"), KS_ARM))

commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
mode_file <- ccx_mode_file(KS_ARM); md5 <- unname(tools::md5sum(mode_file))
dir.create(dirname(KS_STEM), showWarnings = FALSE, recursive = TRUE)
LOG <- paste0(KS_STEM, ".log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("%s | commit %s%s | canonical %s (%s, md5 %s) | %s\n", KS_DRIVER, commit, if (dirty) " (dirty)" else "",
    KS_ARM, basename(dirname(mode_file)), md5, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- observations (read, never typed) -------------------------------------------
do_D <- dg_gateD_obs()
OBS <- c(NH_ml = do_D$region$NH_ml$mean, SH_ml = do_D$region$SH_ml$mean, NH_hs = do_D$region$NH_hs$mean,
         SH_hs = do_D$region$SH_hs$mean, NH = do_D$hemi$NH$mean, SH = do_D$hemi$SH$mean, asym = do_D$asym)
SE  <- c(NH_ml = do_D$region$NH_ml$se, SH_ml = do_D$region$SH_ml$se, NH_hs = do_D$region$NH_hs$se,
         SH_hs = do_D$region$SH_hs$se, NH = do_D$hemi$NH$se, SH = do_D$hemi$SH$se, asym = do_D$asym_se)
say("bottles (GLODAP, area-weighted; %s): %s\n", basename(do_D$file),
    paste(sprintf("%s %+.3f +- %.3f", names(OBS), OBS, SE), collapse = "; "))

# ---- the canonical and the harness gates (the tau_iso driver's gates 1 and 2) -----
v0 <- dg_vector(KS_ARM); md <- v0$md; KW0 <- v0$p$k_w
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
g1 <- abs(sum(ref[names(md$streams)]) - sum(md$streams))
say("HARNESS GATE 1: dg streams at the canonical vs stored: sum %.4f vs %.4f (diff %.1e) -> %s\n",
    sum(ref[names(md$streams)]), sum(md$streams), g1, if (g1 < 1e-4) "PASS" else "FAIL")
if (g1 >= 1e-4) stop("harness gate 1 failed")
read_point <- function(fac) {
  v <- v0; v$p$k_w <- KW0 * fac
  r <- dg_run(v); stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  gD <- dg_gateD_verdict(dg_gateD(r, v), do_D)
  fam <- vapply(KS_FAMILIES, function(p) sum(d[grepl(p, cm, perl = TRUE)]), 0)
  list(fac = fac, k_w = v$p$k_w, dlik = sum(d), fam = fam, d = d,
       D = c(gD$region[c("NH_ml", "SH_ml", "NH_hs", "SH_hs")], NH = gD$hemi[["NH"]], SH = gD$hemi[["SH"]], asym = gD$asym))
}
P <- lapply(sort(unique(c(KS_FAC, KS_KW_LIT / KW0))), read_point)
p1 <- P[[which.min(abs(vapply(P, `[[`, 0, "fac") - 1))]]
say("HARNESS GATE 2: k_w x1 reproduces the canonical: dlik %+.1e -> %s\n", p1$dlik, if (abs(p1$dlik) < KS_GATE_TOL) "PASS" else "FAIL")
if (abs(p1$dlik) >= KS_GATE_TOL) stop("harness gate 2 failed")
fam_sum_ok <- max(vapply(P, function(p) abs(sum(p$fam) - p$dlik), 0))
nm_rows <- names(p1$d); n_hit <- rowSums(sapply(KS_FAMILIES, function(p) grepl(p, nm_rows, perl = TRUE)))
if (any(n_hit != 1L)) stop("rows not in exactly one family: ", paste(nm_rows[n_hit != 1L], collapse = ", "))
say("family split: %d rows, each in exactly one of %d families; closes to %.1e\n", length(nm_rows), length(KS_FAMILIES), fam_sum_ok)
if (fam_sum_ok > 1e-8) stop("the family split does not close")

# ---- the table ---------------------------------------------------------------------
tab <- do.call(rbind, lapply(P, function(p) data.frame(fac = p$fac, k_w = p$k_w, t(p$D), dlik = p$dlik, t(p$fam), check.names = FALSE)))
say("\n=== k_w x fac at %s (k_w x1 = %.1f m/yr; x%.3f = %g, the literature value), everything else fixed ===\n", KS_ARM, KW0, KS_KW_LIT / KW0, KS_KW_LIT)
say("  D in permil (bottles: NH_ml %+.3f, SH_ml %+.3f, NH %+.3f, SH %+.3f, asym %+.3f); likelihood change vs the canonical\n",
    OBS[["NH_ml"]], OBS[["SH_ml"]], OBS[["NH"]], OBS[["SH"]], OBS[["asym"]])
say("  %6s %7s | %7s %7s %7s %7s %7s %7s %7s | %8s | %s\n", "fac", "k_w", "NH_ml", "SH_ml", "NH_hs", "SH_hs", "NH", "SH", "asym", "dlik",
    paste(sprintf("%9s", names(KS_FAMILIES)), collapse = " "))
for (i in seq_len(nrow(tab))) say("  %6.3f %7.1f | %+7.3f %+7.3f %+7.3f %+7.3f %+7.3f %+7.3f %+7.3f | %+8.2f | %s\n",
  tab$fac[i], tab$k_w[i], tab$NH_ml[i], tab$SH_ml[i], tab$NH_hs[i], tab$SH_hs[i], tab$NH[i], tab$SH[i], tab$asym[i], tab$dlik[i],
  paste(sprintf("%+9.2f", unlist(tab[i, names(KS_FAMILIES)])), collapse = " "))

# ---- where each D meets its bottles ------------------------------------------------
cross <- vapply(names(OBS), function(k) {
  y <- tab[[k]] - OBS[[k]]; lf <- log(tab$fac); s <- which(diff(sign(y)) != 0)
  if (!length(s)) return(NA_real_)
  i <- s[which.min(abs(lf[s]))]                              # the bracket nearest x1
  exp(lf[i] + (0 - y[i]) * (lf[i + 1] - lf[i]) / (y[i + 1] - y[i]))
}, 0)
say("\n=== the k_w factor at which each D meets its bottles (log-linear between bracketing points) ===\n")
for (k in names(cross)) say("  %-6s %s   (at x1: model %+.3f vs bottles %+.3f +- %.3f, z %+.1f)\n", k,
  if (is.finite(cross[[k]])) sprintf("x%.3f (k_w %.0f)", cross[[k]], KW0 * cross[[k]]) else "none in the scanned range",
  p1$D[[k]], OBS[[k]], SE[[k]], (p1$D[[k]] - OBS[[k]]) / SE[[k]])
say("  card 3's typed factor: x%.2f (hilda29l, both mixed-layer levels)\n", KS_TYPED)

# ---- optional: the RE-FITTED point of a price profile (run_price_profile.R --hold=k_w=...) ---------------------
# --profile=<profile_k_w_<tag>.rds>: the 30 other names at the profile's optimum and k_w at the held value. GATE: the
# dg path at that vector reproduces the profile's own stored likelihood rows (the objective it was optimized on); an
# overlay that missed a name fails here instead of reading a point no one fitted.
KS_PROFILE <- sub("^--profile=", "", grep("^--profile=", commandArgs(trailingOnly = TRUE), value = TRUE))
PROF <- NULL
if (length(KS_PROFILE)) {
  pf <- readRDS(KS_PROFILE); hold <- pf$provenance$hold
  if (!identical(pf$provenance$mode_md5, md5)) stop(KS_PROFILE, " was run at another mode file")
  pm2 <- v0$pm
  for (n in names(pf$result$par)) pm2[[n]] <- pf$result$par[[n]]
  pm2[[names(hold)]] <- hold[[1]]
  v <- v0; v$pm <- pm2; v$p <- ccx_overlay_par(v0$p, pm2)
  for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) v[[n]] <- pm2[[n]]
  r <- dg_run(v); stv <- unlist(dg_streams(r, v))
  gp <- max(abs(stv[names(pf$result$streams)] - pf$result$streams))
  say("\n=== the profile's re-fitted point: %s (%s = %g, start %s) ===\n", basename(KS_PROFILE), names(hold), hold[[1]], pf$provenance$start)
  say("PROFILE GATE: the dg path reproduces the profile's stored likelihood rows, max |diff| %.1e -> %s\n", gp,
      if (gp < 1e-4) "PASS" else "FAIL")
  if (gp >= 1e-4) stop("the profile point does not reproduce its own rows")
  d <- stv[nm_rows] - ref[nm_rows]
  fam <- vapply(KS_FAMILIES, function(p) sum(d[grepl(p, nm_rows, perl = TRUE)]), 0)
  gD <- dg_gateD_verdict(dg_gateD(r, v), do_D)
  Dp <- c(gD$region[c("NH_ml", "SH_ml", "NH_hs", "SH_hs")], NH = gD$hemi[["NH"]], SH = gD$hemi[["SH"]], asym = gD$asym)
  say("  likelihood vs the canonical %+.2f: %s\n", sum(d), paste(sprintf("%s %+.2f", names(fam), fam), collapse = ", "))
  say("  %-6s %9s %9s %9s %18s\n", "D", "canonical", "profile", "bottles", "profile z vs bottles")
  for (k in names(OBS)) say("  %-6s %+9.3f %+9.3f %+9.3f %18.1f\n", k, p1$D[[k]], Dp[[k]], OBS[[k]], (Dp[[k]] - OBS[[k]]) / SE[[k]])
  PROF <- list(file = KS_PROFILE, md5 = unname(tools::md5sum(KS_PROFILE)), gate = gp, dlik = sum(d), fam = fam, D = Dp)
}

saveRDS(list(table = tab, points = P, obs = OBS, se = SE, cross = cross, KW0 = KW0, families = KS_FAMILIES, profile = PROF,
             provenance = list(driver = KS_DRIVER, commit = commit, dirty = dirty, canonical = KS_ARM, mode_file = mode_file,
                               mode_md5 = md5, obs_file = do_D$file, obs_built = do_D$built,
                               method = "dg path (dg_vector/dg_run/dg_streams); k_w scaled, every other name at the mode",
                               rng = "none (deterministic)", date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(KS_STEM, ".rds"))
say("\nprovenance: %s @%s; %s md5 %s; no RNG; saved %s.{log,rds} | %.1f min\n", KS_DRIVER, commit, KS_ARM, md5, KS_STEM,
    as.numeric(difftime(Sys.time(), t_start, units = "mins")))
