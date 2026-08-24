# =====================================================================
# THE THREE-ARM ISOTOPIC COMPARISON, AT THE ADOPTED MODE
# (handoff 2026-08-23c sec.4e; predictions pre-registered in
#  notes/prereg_2026-08-24_ocean_sink_14c_null.md).
#
# WHY AT THE MODE AND NOT AS THREE REFITS. Every pre-registered prediction --
# the 14C null, the d13C null, and the CO2-leverage ratio -- is a statement
# about what the SAME parameters do under three different isotopic routings.
# None of them needs a refit, and three refits cost ~30 h. Run this first; it
# says whether a refit is worth buying, and if the arms are isotopically
# indistinguishable at the mode then a refit cannot make them distinguishable.
#
# THE THREE ARMS remove the SAME SINK_RATE GtC/yr over the SAME window and
# differ ONLY in the isotopic signature of the removed carbon:
#   foss   -28 permil and 14C-FREE   (the 2026-08-23 incumbent; 14C REJECTED it)
#   luc    the wood pool's own ratio (~-25 permil, not 14C-free)
#   ocean  atmospheric ratio x alpha_as_down; 14C UNFRACTIONATED at source
#
# THE ARMS ARE NOT CO2-MATCHED, and this file measures by how much rather than
# assuming it: `ocean` is the only arm whose carbon stays in the system, so the
# mixed layer hands most of it back (pre-registered at ~10.5 % retained, from
# the buffered-capacity ratio). Handoff sec.4e's "same CO2 trajectory by
# construction" holds for foss-vs-luc and NOT for ocean.
#
# `luc_scale` IS PASSED TO ccx_build_forcing() RATHER THAN APPLIED AFTERWARDS.
# ccx_scaled_forcing()'s column multiply cannot carry the "luc" arm -- the
# columns are affine, not linear, so the multiply would rescale the 2.5 GtC/yr
# perturbation and the arms would stop being magnitude-matched. R/calibrate.R's
# .ccx_assert_luc_arm_safe() errors rather than letting that happen silently.
#
# Usage:  Rscript calibration/diag_sink_three_arms.R [N|D] [rate]
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from named constants (project rule) --------------
.a       <- commandArgs(TRUE)
ARM      <- if (length(.a) >= 1 && .a[1] %in% c("N", "D")) .a[1] else "N"
SINK_RATE <- if (length(.a) >= 2) as.numeric(.a[2]) else 2.5   # GtC/yr
SINK_WIN <- CCX_ARTIFICIAL_SINK_WIN
YEARS    <- c(1750, 2024)
# Pre-bomb Delta14C eras, VERBATIM from handoff 2026-08-23c sec.3 so this
# table can be read against that one. Pre-bomb by construction: the bomb
# spike reaches the troposphere from 1955 and swamps everything after.
ERAS     <- list("1941-1950" = c(1941, 1950), "1950-1956" = c(1950, 1956))
# Where the CO2 leverage is read. The window END is the arm's maximum effect;
# 1960 is a decade of relaxation later; 2024 is whether anything persists.
CO2_EPOCHS <- c(SINK_WIN[2] + 0.5, 1960.5, 2024.5)
OUTDIR   <- ccx_path("calibration", "output", "sink_three_arms")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

M  <- ccx_load_mode(ARM)
pm <- M$md$par_mode
sp <- ccx_spinup(M$p)

cat(sprintf("THREE-ARM ISOTOPIC COMPARISON at the %s mode (%s)\n", ARM, M$file))
cat(sprintf("  rate %.4g GtC/yr over %d-%d = %.2f GtC total\n",
            SINK_RATE, SINK_WIN[1], SINK_WIN[2],
            SINK_RATE * (SINK_WIN[2] - SINK_WIN[1] + 1)))
cat(sprintf("  luc_scale %.6f, bomb_total %.4f (both from the mode file)\n",
            M$luc_scale, M$bomb_total))
cat(sprintf("  rep_dC %.4f, sigma_d14c %.4f\n\n", M$err$rep_dC, M$err$sigma_d14c))

obs <- ccx_prepare_obs()

run_arm <- function(mode, rate) {
  # bomb_total goes into the BUILD rather than being applied as a column
  # rescale afterwards: the bomb column is linear in the total, so the two are
  # identical, and building it once removes a place for the two to disagree.
  F <- suppressWarnings(ccx_build_forcing(
    "historical", YEARS, prod_c14 = sp$prod_c14,
    bomb_total_kmol = M$bomb_total, luc_scale = M$luc_scale,
    sink_rate = rate, sink_mode = mode))
  el <- ccx_forcing_eluc_annual(F)      # the MODEL's own scaled E_LUC
  r  <- ccx_run_fast(sp, F)
  ll <- ccx_loglik(r$out, obs, M$err, luc = el,
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp),
                   by_stream = TRUE)
  list(F = F, out = r$out, state = r$state, ll = ll,
       sink = attr(F, "sink"), eluc = el)
}

ARMS <- list(off = list(mode = "foss", rate = 0),
             foss = list(mode = "foss", rate = SINK_RATE),
             luc  = list(mode = "luc",  rate = SINK_RATE),
             ocean = list(mode = "ocean", rate = SINK_RATE))
R <- lapply(ARMS, function(a) run_arm(a$mode, a$rate))

for (nm in names(R)) cat(sprintf("  arm %-6s forcing stamp: %s\n", nm, R[[nm]]$sink))
cat("\n")

# GATE: the OFF arm must reproduce the plain forcing exactly. If it does not,
# every difference below is measuring the instrument rather than the arms.
F_plain <- suppressWarnings(ccx_build_forcing(
  "historical", YEARS, prod_c14 = sp$prod_c14,
  bomb_total_kmol = M$bomb_total, luc_scale = M$luc_scale))
stopifnot(identical(R$off$F[, CCX_FORCING_COLS], F_plain[, CCX_FORCING_COLS]))
cat("GATE the OFF arm is bit-identical to a forcing built with no sink: PASS\n")

# GATE: the three live arms remove the SAME CARBON. `foss` and `luc` remove it
# from an emission stream; `ocean` moves it across an interface, so it is read
# off the sink column. All three must equal SINK_RATE * n_years.
tot_win <- SINK_RATE * (SINK_WIN[2] - SINK_WIN[1] + 1)
rm_foss <- sum((R$off$F$e_foss_NH + R$off$F$e_foss_SH) -
               (R$foss$F$e_foss_NH + R$foss$F$e_foss_SH)) / 12
rm_luc  <- sum((R$off$F$e_luc_NH + R$off$F$e_luc_SH) -
               (R$luc$F$e_luc_NH + R$luc$F$e_luc_SH)) / 12
rm_oc   <- sum(R$ocean$F$sink_ocean) / 12
cat(sprintf("GATE magnitude-matched: foss %.4f / luc %.4f / ocean %.4f GtC (target %.4f)\n",
            rm_foss, rm_luc, rm_oc, tot_win))
stopifnot(max(abs(c(rm_foss, rm_luc, rm_oc) - tot_win)) < 1e-8)

# ---------------------------------------------------------------------
# P3 -- CO2 LEVERAGE. Reported as the arm's atmospheric drawdown against OFF,
# and as the RATIO to the `foss` arm, which is the pre-registered quantity.
# ---------------------------------------------------------------------
at <- function(o, col, tt) stats::approx(o$t, o[[col]], xout = tt, rule = 2)$y
co2g <- function(o, tt) (at(o, "co2_NH", tt) + at(o, "co2_SH", tt)) / 2

cat("\n=== P3  ATMOSPHERIC CO2 DRAWDOWN vs the OFF arm (ppm, global mean) ===\n")
cat(sprintf("%-10s %10s %10s %10s\n", "arm", sprintf("%.1f", CO2_EPOCHS[1]),
            sprintf("%.1f", CO2_EPOCHS[2]), sprintf("%.1f", CO2_EPOCHS[3])))
d_co2 <- sapply(c("foss", "luc", "ocean"), function(nm)
  co2g(R[[nm]]$out, CO2_EPOCHS) - co2g(R$off$out, CO2_EPOCHS))
for (nm in colnames(d_co2))
  cat(sprintf("%-10s %10.4f %10.4f %10.4f\n", nm, d_co2[1, nm], d_co2[2, nm], d_co2[3, nm]))
cat(sprintf("%-10s %10.4f %10.4f %10.4f   <- PRE-REGISTERED 0.08-0.25 at the window end\n",
            "ocean/foss", d_co2[1, "ocean"] / d_co2[1, "foss"],
            d_co2[2, "ocean"] / d_co2[2, "foss"], d_co2[3, "ocean"] / d_co2[3, "foss"]))

# Where the ocean arm's carbon actually went, at the end of the window: the
# property the negative-emission arm could not report at all.
cat("\n--- where the removed carbon is at the window end (GtC vs OFF) ---\n")
tt <- CO2_EPOCHS[1]
for (nm in c("foss", "luc", "ocean")) {
  atmC <- (co2g(R[[nm]]$out, tt) - co2g(R$off$out, tt)) * ccx_const("GtC_PER_PPM")
  ocC  <- at(R[[nm]]$out, "ocean_C", tt) - at(R$off$out, "ocean_C", tt)
  lnC  <- at(R[[nm]]$out, "land_C",  tt) - at(R$off$out, "land_C",  tt)
  cat(sprintf("  %-6s atm %+8.3f  ocean %+8.3f  land %+8.3f  SUM %+8.3f (of %.2f removed)\n",
              nm, atmC, ocC, lnC, atmC + ocC + lnC, tot_win))
}

# WHY THE OCEAN ARM IS WEAK: how much of the injected carbon got BELOW the
# mixed layer. A surface uptake anomaly only holds carbon down to the extent
# the model's own transport (diffusion + upwelling + pump) ventilates it; what
# stays in the mixed layer is re-exposed to the atmosphere on the ~1 yr air-sea
# time and comes back. No mechanism choice is made here -- this is read off the
# run at the fitted transport parameters.
cat("\n--- ocean arm: where the injected carbon sits (GtC vs OFF) ---\n")
mlcol <- function(o, tt) at(o, "ml_C_NH", tt) + at(o, "ml_C_SH", tt)
cat(sprintf("%8s %10s %10s %10s %10s\n", "epoch", "mixed", "interior", "ocean tot", "injected"))
for (ei in seq_along(CO2_EPOCHS)) {
  tt <- CO2_EPOCHS[ei]
  inj <- SINK_RATE * (min(tt, SINK_WIN[2] + 1) - SINK_WIN[1])
  dml <- mlcol(R$ocean$out, tt) - mlcol(R$off$out, tt)
  doc <- at(R$ocean$out, "ocean_C", tt) - at(R$off$out, "ocean_C", tt)
  cat(sprintf("%8.1f %+10.3f %+10.3f %+10.3f %10.2f\n", tt, dml, doc - dml, doc, inj))
}
cat(paste0("  NOTE the perfectly-ventilated limit needs no extra run: an ocean sink\n",
           "  that buried its carbon instantly would have the `foss` arm's CO2\n",
           "  trajectory (same removal, never returned) and the `ocean` arm's\n",
           "  isotopes (removal at the atmosphere's own ratio). The two arms below\n",
           "  therefore BRACKET every ocean routing.\n"))

# ---------------------------------------------------------------------
# P1 / P2 -- THE ISOTOPIC EXCURSIONS. Two tables: the arm-minus-OFF EXCURSION
# (the pre-registered quantity, model-only, no observations involved) and the
# model-minus-obs RESIDUAL by era (comparable to handoff sec.3's table).
# ---------------------------------------------------------------------
era_mean <- function(o, col, era) {
  k <- o$t >= era[1] & o$t < era[2]
  mean(o[[col]][k])
}
cat("\n=== P1/P2  ISOTOPIC EXCURSION, arm minus OFF (model only) ===\n")
cat(sprintf("%-10s %-6s %10s %10s\n", "era", "hemi", "dD14C", "dd13C"))
exc <- list()
for (en in names(ERAS)) for (h in HEMIS) {
  row <- sapply(c("foss", "luc", "ocean"), function(nm) c(
    d14 = era_mean(R[[nm]]$out, paste0("d14c_", h), ERAS[[en]]) -
          era_mean(R$off$out,   paste0("d14c_", h), ERAS[[en]]),
    d13 = era_mean(R[[nm]]$out, paste0("d13c_", h), ERAS[[en]]) -
          era_mean(R$off$out,   paste0("d13c_", h), ERAS[[en]])))
  exc[[paste(en, h)]] <- row
  for (nm in colnames(row))
    cat(sprintf("%-10s %-6s %-6s %+10.4f %+10.4f\n", en, h, nm, row["d14", nm], row["d13", nm]))
}
cat("\n--- P1: |ocean| / |foss| in D14C, per cell.  PRE-REGISTERED <= 0.20 ---\n")
r14 <- sapply(exc, function(m) abs(m["d14", "ocean"]) / abs(m["d14", "foss"]))
r13 <- sapply(exc, function(m) abs(m["d13", "ocean"]) / abs(m["d13", "foss"]))
for (k in names(r14))
  cat(sprintf("  %-16s D14C %6.4f   d13C %6.4f\n", k, r14[k], r13[k]))
cat(sprintf("  WORST CELL: D14C %.4f, d13C %.4f\n", max(r14), max(r13)))
cat(sprintf("  P1 %s ; P2 %s\n",
            if (max(r14) <= 0.20) "HOLDS" else "FAILS",
            if (max(r13) <= 0.20) "HOLDS" else "FAILS"))
cat(sprintf("  absolute ocean-arm D14C excursion, worst cell: %.4f permil (pre-reg < 1)\n",
            max(sapply(exc, function(m) abs(m["d14", "ocean"])))))

cat("\n=== PRE-BOMB D14C RESIDUAL, model - obs (permil), as handoff 23c sec.3 ===\n")
cat(sprintf("%-10s %-4s %8s %8s %8s %8s\n", "era", "hemi", "off", "foss", "luc", "ocean"))
for (en in names(ERAS)) for (h in HEMIS) {
  # obs$d14_nh / obs$d14_sh -- the MONTHLY zonal-aggregate frames, columns
  # (t, d14c, sd_meas, sd). NOT obs$d14$NH: ccx_prepare_obs() has no such field
  # and indexing it gave NaN in every cell of this table on the first run.
  o <- obs[[paste0("d14_", tolower(h))]]
  k <- o$t >= ERAS[[en]][1] & o$t < ERAS[[en]][2]
  v <- sapply(names(R), function(nm)
    mean(stats::approx(R[[nm]]$out$t, R[[nm]]$out[[paste0("d14c_", h)]],
                       xout = o$t[k], rule = 2)$y - o$d14c[k]))
  cat(sprintf("%-10s %-4s %8.2f %8.2f %8.2f %8.2f  (n=%d)\n",
              en, h, v["off"], v["foss"], v["luc"], v["ocean"], sum(k)))
}

# ---------------------------------------------------------------------
# THE LIKELIHOOD, per stream. At the mode, un-refitted -- so this is the
# IMMEDIATE cost of each arm, before any parameter is allowed to absorb it.
# ---------------------------------------------------------------------
cat("\n=== PER-STREAM logL AT THE MODE (arm minus OFF; + = the arm is better) ===\n")
nms <- names(R$off$ll)
tab <- sapply(c("foss", "luc", "ocean"), function(nm)
  unlist(R[[nm]]$ll)[nms] - unlist(R$off$ll)[nms])
tab <- rbind(tab, TOTAL = colSums(tab))
# TOTAL first, then by |foss| -- ranked on the arm with the largest effect so
# the ordering does not change when the near-null arm's roundoff reorders.
# (The first version indexed `ord` by POSITION and printed row 1 twice while
# never printing TOTAL at all.)
ord <- c("TOTAL", setdiff(rownames(tab)[order(-abs(tab[, "foss"]))], "TOTAL"))
cat(sprintf("%-22s %10s %10s %10s\n", "stream", "foss", "luc", "ocean"))
for (i in ord)
  cat(sprintf("%-22s %+10.2f %+10.2f %+10.2f\n", i,
              tab[i, "foss"], tab[i, "luc"], tab[i, "ocean"]))

# ---------------------------------------------------------------------
# WHAT RATE WOULD THE OCEAN ARM NEED TO MATCH THE `foss` ARM'S CO2 EFFECT?
# This is the sec.4e "matched" question made quantitative, and it is the number
# that decides whether the ocean hypothesis is viable at all: the literature
# sizes the plateau at 2-3 GtC/yr, and today's ENTIRE global ocean sink is
# ~3 GtC/yr. Solved by bisection on the model, not by extrapolating the ratio,
# because the mixed layer's buffer is nonlinear in the perturbation.
# ---------------------------------------------------------------------
cat("\n=== THE RATE AN OCEAN ARM WOULD NEED, per epoch ===\n")
cat(sprintf("(today's whole global ocean sink is ~3 GtC/yr; the literature sizes\n"))
cat(sprintf(" the plateau at 2-3 GtC/yr AFTER firn smoothing)\n"))
SOLVE_TOL <- 1e-3      # ppm
SOLVE_MAX <- 24        # bisection steps; the bracket is doubled up to this many
for (ei in seq_along(CO2_EPOCHS)) {
  tt <- CO2_EPOCHS[ei]
  target <- d_co2[ei, "foss"]                     # negative ppm
  f <- function(rate) {
    o <- run_arm("ocean", rate)$out
    co2g(o, tt) - co2g(R$off$out, tt) - target
  }
  lo <- 0; flo <- -target                          # rate 0 -> shortfall
  hi <- SINK_RATE; fhi <- f(hi); k <- 0
  while (fhi > 0 && k < 12) { hi <- hi * 2; fhi <- f(hi); k <- k + 1 }
  if (fhi > 0) { cat(sprintf("  %.1f  NO RATE FOUND below %.4g GtC/yr\n", tt, hi)); next }
  for (i in seq_len(SOLVE_MAX)) {
    mid <- (lo + hi) / 2; fm <- f(mid)
    if (fm > 0) { lo <- mid } else { hi <- mid; fhi <- fm }
    if (abs(fm) < SOLVE_TOL) break
  }
  cat(sprintf("  at %.1f: matching %+.4f ppm needs %.3f GtC/yr = %.1fx the %.4g GtC/yr arm\n",
              tt, target, hi, hi / SINK_RATE, SINK_RATE))
}

saveRDS(list(arms = ARMS, rate = SINK_RATE, win = SINK_WIN, arm = ARM,
             mode_file = M$file, d_co2 = d_co2, excursion = exc,
             r14 = r14, r13 = r13, logl = tab,
             ll_raw = lapply(R, `[[`, "ll")),
        file.path(OUTDIR, sprintf("three_arms_%s_rate%s.rds", ARM,
                                  format(SINK_RATE))))
cat(sprintf("\nwritten: %s\n",
            file.path(OUTDIR, sprintf("three_arms_%s_rate%s.rds", ARM, format(SINK_RATE)))))
