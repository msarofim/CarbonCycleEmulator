# =====================================================================
# diag_face_check_gamma_diff.R -- 2026-08-29
#
# THE GATE THE 08-29c HANDOFF LEFT OPEN: does the fitted `fert_k` at the
# diffuse-light operating point clear the FACE-informed range?
#
# ⚠ THE HANDOFF FRAMED THIS AS "FACE CAPS fert_k". THAT CEILING IS WITHDRAWN
#   (memory face_ceiling_is_the_headline_in_disguise, Marcus 2026-08-25:
#   "the exact numbers shouldn't be a constraint because FACE is only temperate
#   forests, but FACE can still inform response shape and realistic limits").
#   So this driver does NOT test fert_k against a ceiling. It tests the thing
#   FACE actually constrains -- the RIDGE COORDINATE's implied FACE response
#   R(a -> e) -- against the OBSERVED bracket, and reports the ceiling only to
#   show how far from binding it is.
#
# Estimator is IDENTICAL to diag_face_prior_for_beta_max.R (like-for-like):
#     enh(chi) = beta_max * d / (K + d),   d = chi - chi0
#     R(a, e)  = (1 + enh(e)) / (1 + enh(a)) - 1
#
# Two gates, scored SEPARATELY ([[pair_the_inference_gate_with_a_mechanism_gate]]):
#   GATE-N (number)    : is R at the operating point inside the observed bracket?
#   GATE-M (mechanism) : is the gamma_diff payment actually ON the rho=+0.998
#                        ridge, and is the withdrawn fert_k ceiling anywhere
#                        near binding?
#
# Usage:  Rscript calibration/diag_face_check_gamma_diff.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

## ---- named constants (every label below derives from these) ----------
FACE_CHI0     <- 276.88        # model preindustrial, R/model.R
FACE_ENRICH   <- 0.41          # Norby 2025 normalising enrichment
FACE_AMBIENT  <- c(376, 400)   # Norby-2005-era and recent ambient, ppm
FACE_BMAX_HI  <- 3.0           # hard implausibility bound, calibrate.R:61
FACE_K_LO     <- 20; FACE_K_HI <- 2000

# The OBSERVED bracket. Marcus's ruling: FACE gives a RANGE, not a target.
FACE_MATURE_LO   <- 0.00       # EucFACE, mature P-limited
FACE_MATURE_HI   <- 0.10       # BIFoR-FACE, mature Quercus
FACE_SYNTH       <- 0.218      # Norby 2025 synthesis (PLANTATION-WEIGHTED)
FACE_YOUNG       <- 0.23       # Norby 2005, 4 young plantations
FACE_SRC         <- "Norby et al. 2025 New Phyt 10.1111/nph.70162; Norby et al. 2005 PNAS"

GAMMA_OPERATING <- 0.25        # the candidate operating point (handoff 08-29c s.5)
PRICE_RDS       <- "outputs/diagnostics/price_gamma_diff.rds"
OUT_RDS         <- "outputs/diagnostics/face_check_gamma_diff.rds"

enh   <- function(bm, K, chi) { d <- chi - FACE_CHI0; bm * d / (K + d) }
Rface <- function(bm, K, a, e) (1 + enh(bm, K, e)) / (1 + enh(bm, K, a)) - 1

## ---- the fitted points being tested ----------------------------------
pr <- readRDS(PRICE_RDS)
pts <- do.call(rbind, lapply(names(pr$res), function(g) {
  x <- pr$res[[g]]
  data.frame(gamma = as.numeric(g), cond = x$cond, r = x$s$r,
             beta_max = x$pv$beta_max, fert_k = x$pv$fert_k)
}))
pts$ridge <- pts$beta_max / pts$fert_k

cat("=====================================================================\n")
cat(sprintf("FACE CHECK ON THE gamma_diff OPERATING POINT (gamma = %.2f)\n", GAMMA_OPERATING))
cat(sprintf("Estimator: Michaelis-Menten enhancement, chi0 = %.2f ppm\n", FACE_CHI0))
cat(sprintf("Evidence : %s\n", FACE_SRC))
cat(sprintf("Bracket  : mature %.0f-%.0f%%  |  synthesis %.1f%%  |  young %.1f%%\n",
            100*FACE_MATURE_LO, 100*FACE_MATURE_HI, 100*FACE_SYNTH, 100*FACE_YOUNG))
cat("=====================================================================\n\n")

## ---- 1. implied FACE response along the gamma grid --------------------
cat("1. IMPLIED FACE RESPONSE AT EACH gamma's CONDITIONAL REFIT\n")
cat(sprintf("   (enrichment +%.0f%%, so e = a * %.2f; both ambients reported)\n\n",
            100*FACE_ENRICH, 1 + FACE_ENRICH))
hdr <- sprintf("  %6s %10s %9s %10s %11s %11s", "gamma", "cond", "beta_max",
               "fert_k", sprintf("R(%d)", FACE_AMBIENT[1]), sprintf("R(%d)", FACE_AMBIENT[2]))
cat(hdr, "\n"); cat("  ", strrep("-", nchar(hdr) - 2), "\n", sep = "")
for (i in seq_len(nrow(pts))) {
  R1 <- Rface(pts$beta_max[i], pts$fert_k[i], FACE_AMBIENT[1], FACE_AMBIENT[1]*(1+FACE_ENRICH))
  R2 <- Rface(pts$beta_max[i], pts$fert_k[i], FACE_AMBIENT[2], FACE_AMBIENT[2]*(1+FACE_ENRICH))
  pts$R_lo[i] <- R1; pts$R_hi[i] <- R2
  cat(sprintf("  %6.3f %10.2f %9.4f %10.2f %10.2f%% %10.2f%%\n",
              pts$gamma[i], pts$cond[i], pts$beta_max[i], pts$fert_k[i], 100*R1, 100*R2))
}
op <- which(abs(pts$gamma - GAMMA_OPERATING) < 1e-9)
base <- which(pts$gamma == 0)

## ---- 2. box maximum: what the model can reach at all ------------------
gb <- seq(0, FACE_BMAX_HI, length.out = 601)
gk <- exp(seq(log(FACE_K_LO), log(FACE_K_HI), length.out = 601))
boxmax <- sapply(FACE_AMBIENT, function(a)
  max(outer(gb, gk, function(b, k) Rface(b, k, a, a*(1+FACE_ENRICH)))))
cat(sprintf("\n2. BOX MAXIMUM over beta_max in [0,%.0f] x fert_k in [%.0f,%.0f]: %.1f%% / %.1f%%\n",
            FACE_BMAX_HI, FACE_K_LO, FACE_K_HI, 100*boxmax[1], 100*boxmax[2]))

## ---- 3. how far is the withdrawn ceiling from binding? ----------------
kcut <- sapply(FACE_AMBIENT, function(a) {
  f <- function(K) Rface(FACE_BMAX_HI, K, a, a*(1+FACE_ENRICH)) - FACE_SYNTH
  pk <- optimize(function(K) Rface(FACE_BMAX_HI, K, a, a*(1+FACE_ENRICH)),
                 c(FACE_K_LO, FACE_K_HI), maximum = TRUE)$maximum
  if (f(FACE_K_HI) > 0) return(NA_real_)          # no ceiling in the box
  tryCatch(uniroot(f, c(pk, FACE_K_HI))$root, error = function(e) NA_real_)
})
cat(sprintf("3. WITHDRAWN CEILING (only exists if you adopt the %.1f%% plantation-weighted\n",
            100*FACE_SYNTH))
cat(sprintf("   headline): fert_k above ~%.0f / ~%.0f. Operating point fert_k = %.1f\n",
            kcut[1], kcut[2], pts$fert_k[op]))
cat(sprintf("   => the operating point is %.1fx / %.1fx BELOW that ceiling.\n",
            kcut[1]/pts$fert_k[op], kcut[2]/pts$fert_k[op]))

## ---- 4. THE TWO GATES -------------------------------------------------
Rop <- pts$R_hi[op]; Rbase <- pts$R_hi[base]
gate_n <- (Rop >= FACE_MATURE_LO) && (Rop <= FACE_SYNTH) && (Rop <= boxmax[2])
# mechanism: does the pair move along the ridge (both up, correlated), and does
# the ceiling story apply at all?
d_bm <- pts$beta_max[op]/pts$beta_max[base] - 1
d_fk <- pts$fert_k[op]  /pts$fert_k[base]   - 1
on_ridge   <- (d_bm > 0) && (d_fk > 0)
ceil_binds <- !is.na(kcut[2]) && pts$fert_k[op] > 0.5 * kcut[2]

cat("\n4. GATES (scored separately)\n")
cat(sprintf("   GATE-N  R(%d->%d) at gamma=%.2f = %.2f%%  (was %.2f%% at gamma=0, +%.2f pt)\n",
            FACE_AMBIENT[2], round(FACE_AMBIENT[2]*(1+FACE_ENRICH)), GAMMA_OPERATING,
            100*Rop, 100*Rbase, 100*(Rop - Rbase)))
cat(sprintf("           inside [%.0f%%, %.1f%%] and under the %.1f%% box max?  %s\n",
            100*FACE_MATURE_LO, 100*FACE_SYNTH, 100*boxmax[2], if (gate_n) "PASS" else "FAIL"))
cat(sprintf("           position in bracket: %s\n",
            if (Rop <= FACE_MATURE_HI) "at the MATURE-forest end (EucFACE..BIFoR)"
            else if (Rop <= FACE_SYNTH) "between mature forest and the plantation-weighted synthesis"
            else "ABOVE the plantation-weighted synthesis"))
cat(sprintf("   GATE-M  beta_max %+.1f%%, fert_k %+.1f%% -> moves ALONG the ridge? %s\n",
            100*d_bm, 100*d_fk, if (on_ridge) "yes" else "NO"))
cat(sprintf("           is the (withdrawn) fert_k ceiling anywhere near binding? %s\n",
            if (ceil_binds) "YES -- it would bind" else "no -- not the operative constraint"))

## ---- 5. MUTATION TEST: break what the gate guards ---------------------
cat("\n5. MUTATION TEST (a gate that passes is not a gate that works)\n")
mut <- list("pinned luc probe (08-24c), bm 2.7254 / K 1783.7" = c(2.7254, 1783.726),
            "young-plantation cell, bm 3.0 / K 340"           = c(3.0, 340),
            "genuine operating point"                          = c(pts$beta_max[op], pts$fert_k[op]))
for (nm in names(mut)) {
  cc <- mut[[nm]]
  Rm <- Rface(cc[1], cc[2], FACE_AMBIENT[2], FACE_AMBIENT[2]*(1+FACE_ENRICH))
  pass <- (Rm >= FACE_MATURE_LO) && (Rm <= FACE_SYNTH) && (Rm <= boxmax[2])
  cat(sprintf("   %-50s R = %6.2f%%  GATE-N %s\n", nm, 100*Rm, if (pass) "PASS" else "FAIL"))
}

saveRDS(list(points = pts, boxmax = boxmax, kcut = kcut,
             gate_n = gate_n, gate_m = list(on_ridge = on_ridge, ceil_binds = ceil_binds),
             constants = list(chi0 = FACE_CHI0, enrich = FACE_ENRICH, ambient = FACE_AMBIENT,
                              bracket = c(FACE_MATURE_LO, FACE_MATURE_HI, FACE_SYNTH, FACE_YOUNG),
                              source = FACE_SRC, gamma_operating = GAMMA_OPERATING),
             provenance = list(price_rds = PRICE_RDS, when = "2026-08-29",
                               commit = system("git rev-parse --short HEAD", intern = TRUE))),
        OUT_RDS)
cat(sprintf("\nWrote %s\n", OUT_RDS))
