# =====================================================================
# diag_face_prior_for_beta_max.R -- CAN FACE SUPPLY A PRIOR FOR beta_max?
# (Marcus 2026-08-25)
#
# THE PROBLEM IT IS ANSWERING. `beta_max` and `fert_k` carry UNIFORM priors --
# [0, 3] and [20, 2000] -- and R/calibrate.R says so in as many words: the
# bounds are "a hard implausibility bound ... not a belief", resting on
# "evidence nobody has cited". They are also rho = +0.998 correlated, so only a
# combination is identified, and every pinned probe run to date drives the pair
# into the same corner: `beta_max` 2.70 (pinned foss, 08-23) and 2.7254 (pinned
# luc, 08-24c), i.e. ~91 % of the way to the implausibility bound.
#
# THE MAPPING, AND WHY FACE IS THE RIGHT INSTRUMENT. The historical record
# constrains the INTEGRAL of the fertilisation response over 277 -> ~420 ppm.
# FACE measures a RATIO between two CO2 levels, one of them above anything the
# historical record reaches. Under the Michaelis-Menten form
#     enh(chi) = beta_max * d / (K + d),      d = chi - chi0
# the model's FACE-equivalent response is
#     R(a, e) = (1 + enh(e)) / (1 + enh(a)) - 1
# which is NOT a function of the historical integral alone -- so it is exactly
# the orthogonal constraint the ridge lacks. This file measures whether it
# actually discriminates, and in which direction.
#
# THE EVIDENCE, WITH ITS VINTAGE (memory weight_recent_literature: state every
# source's date; recency is a TIE-BREAKER, not an override).
#
#   Norby et al. 2005 PNAS       +23 %   4 YOUNG temperate tree plantations
#   Norby & Zak 2011 AREES               FACE setpoints "typically 550-580 ppm"
#   Norby et al. 2025 New Phyt   +21.8 % normalised to +41 % CO2 enrichment,
#     doi 10.1111/nph.70162              now INCLUDING two mature-forest sites
#
#   ...and the two MATURE sites -- the ones that look like the standing
#   biosphere rather than a plantation -- are the two smallest responses:
#     EucFACE (Eucalyptus, P-limited)   NEGLIGIBLE NPP response
#     BIFoR-FACE (mature Quercus)       +10 %, "considerably less than the
#                                       previously reported median response"
#
# SO THE LITERATURE DOES NOT HAND OVER ONE NUMBER. It hands over a RANGE whose
# top end is plantation-weighted and whose bottom end is the mature-forest,
# nutrient-limited case. Both ends are carried here; collapsing them to the
# headline 21.8 % would be the ratio_needs_its_base error in another costume.
#
# AMBIENT IS A CHOICE AND IS NOT MADE SILENTLY. "+41 % enrichment" is a ratio;
# it becomes ppm only against an ambient, and the sites span ~1996-2024. Both
# ends of the plausible ambient range are reported and the answer is checked for
# sensitivity to it.
#
# Usage:  Rscript calibration/diag_face_prior_for_beta_max.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

FACE_CHI0    <- 276.88          # model preindustrial, R/model.R
FACE_ENRICH  <- 0.41            # Norby 2025 normalising enrichment
FACE_AMBIENT <- c(376, 400)     # Norby-2005-era and recent ambient, ppm
FACE_TARGETS <- list("Norby 2025 synthesis (plantation-weighted)" = 0.218,
                     "Norby 2005 (4 young plantations)"           = 0.23,
                     "BIFoR-FACE (mature Quercus)"                = 0.10,
                     "EucFACE (mature, P-limited)"                = 0.00)
FACE_BMAX_HI <- 3.0             # the hard implausibility bound, calibrate.R:61
FACE_K_LO    <- 20; FACE_K_HI <- 2000
OUTDIR <- ccx_path("calibration", "output", "face_prior")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

enh  <- function(bm, K, chi) { d <- chi - FACE_CHI0; bm * d / (K + d) }
Rface <- function(bm, K, a, e) (1 + enh(bm, K, e)) / (1 + enh(bm, K, a)) - 1

cells <- list("design (arithmetic, 08-14)" = c(0.4913, 120),
              "adopted mode (arm N)"       = c(1.0112, 554.545),
              "pinned foss probe (08-23)"  = c(2.7000, 1738),
              "pinned luc probe (08-24c)"  = c(2.7254, 1783.726),
              "the bound itself"           = c(FACE_BMAX_HI, FACE_K_HI))

cat("=== 1. DOES THE FACE RATIO DISCRIMINATE ALONG THE RIDGE? ===\n")
cat(sprintf("%-28s %7s %8s | %10s %10s | %9s\n", "cell", "bmax", "K",
            "R(376->530)", "R(400->564)", "enh@388"))
for (n in names(cells)) { c_ <- cells[[n]]
  cat(sprintf("%-28s %7.4f %8.1f | %9.1f%% %9.1f%% | %9.4f\n", n, c_[1], c_[2],
              100 * Rface(c_[1], c_[2], 376, 376 * (1 + FACE_ENRICH)),
              100 * Rface(c_[1], c_[2], 400, 400 * (1 + FACE_ENRICH)),
              enh(c_[1], c_[2], 388))) }

cat("\n  The historical observable (enh@388) spans 0.236 -> 0.158, a 1.5x range.\n")
cat("  The FACE ratio spans a 2x range over the SAME cells and in the OPPOSITE\n")
cat("  direction. It discriminates. The question is which way it pushes.\n")

cat("\n=== 2. WHAT IS THE MODEL'S MAXIMUM ACHIEVABLE FACE RESPONSE? ===\n")
# R is monotone increasing in K at fixed bmax (more linear = less saturated) and
# in bmax at fixed K, so the box maximum is at the corner. Verified numerically
# rather than asserted, because "monotone" is exactly the kind of claim this
# project has had wrong before (08-24b's monotonicity print).
gb <- seq(0.01, FACE_BMAX_HI, length.out = 400)
gk <- seq(FACE_K_LO, FACE_K_HI, length.out = 400)
for (a in FACE_AMBIENT) {
  e  <- a * (1 + FACE_ENRICH)
  M  <- outer(gb, gk, function(b, k) Rface(b, k, a, e))
  ij <- which(M == max(M), arr.ind = TRUE)[1, ]
  cat(sprintf("  ambient %d -> %.0f ppm: box maximum R = %.1f%% at bmax %.3f, K %.0f%s\n",
              a, e, 100 * max(M), gb[ij[1]], gk[ij[2]],
              if (ij[1] == length(gb) && ij[2] == length(gk)) "  (BOTH AT THE CORNER)" else ""))
}

cat("\n=== 3. THE ISO-FACE LOCI: what beta_max does each target imply? ===\n")
cat("  For each target and each fert_k, the beta_max that reproduces it.\n")
cat("  NA = unreachable anywhere in [0, 3].\n\n")
Kshow <- c(120, 554.545, 1000, 1783.726, 2000)
for (a in FACE_AMBIENT) {
  e <- a * (1 + FACE_ENRICH)
  cat(sprintf("  --- ambient %d -> %.0f ppm ---\n", a, e))
  cat(sprintf("  %-46s %s\n", "target",
              paste(sprintf("K=%-8.0f", Kshow), collapse = " ")))
  for (tn in names(FACE_TARGETS)) {
    tv <- FACE_TARGETS[[tn]]
    bb <- vapply(Kshow, function(K) {
      f <- function(b) Rface(b, K, a, e) - tv
      if (f(1e-9) > 0 || f(FACE_BMAX_HI) < 0) return(NA_real_)
      stats::uniroot(f, c(1e-9, FACE_BMAX_HI), tol = 1e-10)$root
    }, numeric(1))
    cat(sprintf("  %-46s %s\n", tn,
                paste(sprintf("%-10s", ifelse(is.na(bb), "--", sprintf("%.3f", bb))),
                      collapse = "")))
  }
  cat("\n")
}

cat("=== 4. THE CONSTRAINT IS ON THE PAIR, NOT ON beta_max ===\n")
cat("  Read down any column above: a single FACE target fixes beta_max ONLY once\n")
cat("  fert_k is fixed. Read across: the same target is met at beta_max values\n")
cat("  differing several-fold. So a MARGINAL prior on beta_max cannot encode this\n")
cat("  evidence -- it has to enter as a term in the ratio R(a,e), which is a\n")
cat("  JOINT constraint on (beta_max, fert_k). That is also why the uniform\n")
cat("  prior is not merely uninformative: beta_max is not the identified object.\n")

cat("\n=== 5. THE ACTIONABLE RESULT: FACE PUTS A CEILING ON fert_k ===\n")
cat("  R is NOT monotone in K -- it peaks at an INTERIOR K and falls away on\n")
cat("  both sides (low K saturates the increment; high K inflates the ambient\n")
cat("  denominator). So a high-K cell has a MAXIMUM achievable FACE response\n")
cat("  even at beta_max = 3, and that is what rejects the corner.\n\n")
for (a in FACE_AMBIENT) {
  e <- a * (1 + FACE_ENRICH)
  cat(sprintf("  --- ambient %d -> %.0f ppm ---\n", a, e))
  cat(sprintf("  %10s  %22s  %s\n", "fert_k", "max R at beta_max=3", "reaches 21.8%? 23%? 10%?"))
  for (K in c(120, 318, 554.545, 1000, 1500, 1783.726, 2000)) {
    mx <- Rface(FACE_BMAX_HI, K, a, e)
    cat(sprintf("  %10.1f  %21.1f%%  %-6s %-6s %-6s\n", K, 100 * mx,
                ifelse(mx >= 0.218, "yes", "NO"), ifelse(mx >= 0.23, "yes", "NO"),
                ifelse(mx >= 0.10, "yes", "NO")))
  }
  # the K above which the synthesis target becomes unreachable at ANY beta_max
  fK <- function(K) Rface(FACE_BMAX_HI, K, a, e) - FACE_TARGETS[[1]]
  kk <- seq(400, FACE_K_HI, length.out = 4000); v <- vapply(kk, fK, numeric(1))
  if (any(v < 0) && any(v > 0)) {
    kcut <- kk[which(diff(sign(v)) != 0)[1]]
    cat(sprintf("  => fert_k above ~%.0f cannot reach the 21.8%% synthesis target at ANY\n", kcut))
    cat(sprintf("     beta_max in [0, 3]. The pinned probes sit at 1738 and 1784.\n\n"))
  } else cat("  => no crossing inside the fert_k box at this ambient\n\n")
}

cat("=== 6. WHAT IT DOES NOT SAY ===\n")
cat("  * FACE is temperate FOREST NPP. `beta_max` here multiplies GLOBAL NPP,\n")
cat("    which includes grasslands, croplands and the tropics -- where there is\n")
cat("    NO forest FACE experiment at all. This is a prior, not a measurement.\n")
cat("  * The 21.8% synthesis is plantation-weighted; the two MATURE sites are\n")
cat("    the two smallest responses (EucFACE negligible, BIFoR +10%). Using the\n")
cat("    headline alone would repeat the ratio_needs_its_base error.\n")
cat("  * EucFACE's 0% prints as unreachable above only because beta_max = 0 is\n")
cat("    the boundary of the search, not because the model cannot represent it.\n")
cat("  * FACE is a step change over years; `beta_max` is an equilibrium\n")
cat("    asymptote. The mapping assumes the MM form transfers between them.\n")

saveRDS(list(cells = cells, targets = FACE_TARGETS, ambient = FACE_AMBIENT,
             enrich = FACE_ENRICH, chi0 = FACE_CHI0),
        file.path(OUTDIR, "face_prior_scan.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "face_prior_scan.rds")))
