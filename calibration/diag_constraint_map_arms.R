# =====================================================================
# diag_constraint_map_arms.R -- IS THE CONSTRAINT MAP A PROPERTY OF THE
# MODEL, OR ONLY OF THIS FIT?  (Marcus's ruling, 2026-09-26)
#
# THE QUESTION. `diag_constraint_map.R` measures the map at ONE point, the
# canonical mode. Every pins/pulls claim in the app therefore rests on a
# single fit with no way to say whether it would survive a different one.
# This script evaluates the SAME map at further arms and compares.
#
# ⛔⛔ THE ARM CHOICE IS THE WHOLE METHOD, AND IT WAS MEASURED (09-26).
#   A2  hilda32f  -- THE LIKE-FOR-LIKE ARM. Same structure (seas_ml 1), same
#       periodic spinup, and its 32 names are a clean SUPERSET of the
#       canonical's 29: it FREES the three the canonical pins. So a difference
#       between its map and the canonical's is about WHERE THE FIT SITS, which
#       is the question asked.
#   A3  hilda31pe -- THE STRUCTURE CONTRAST, reported but NOT an answer to the
#       question. It is seas_ml **0** and NOT a superset (it lacks `w_enso_l2`;
#       28 of 29 shared). A difference could be the fit OR the structure and the
#       comparison cannot separate them. It is the seas_ml ON/OFF control and
#       licenses THAT comparison only -- the standing trap
#       [[iso_deep_control_licenses_one_comparison]]: a control licenses only
#       the comparison it was built for. Kept because the contrast is
#       interesting, labelled because it is not the answer.
#
# ⚠ LIKE-FOR-LIKE: every share is recomputed on the SHARED names and the
# shared streams. A pin share over 29 names is not comparable to one over 32 --
# different denominators, and the three extra names are exactly the ones the
# canonical pins, so they are not a random sample of the space.
#
# ⭐ WHY A CROSS-ARM COMPARISON IS MEANINGFUL AT ALL: the step is one
# CONDITIONAL Hessian sd, an equal-difficulty step by construction (predicted
# quadratic drop 0.5 log-units for EVERY name, at EVERY arm). Leverage is
# therefore already normalised per name per arm.
#
# Usage:  Rscript calibration/diag_constraint_map_arms.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- NAMED CONSTANTS: every label, path and threshold derives from here ----
CA_TAG        <- "constraint_map_arms"
CA_DATE       <- format(Sys.Date(), "%Y%m%d")
CA_REF        <- CCX_MODE_CANONICAL                 # the shipped arm
CA_LIKE       <- "hilda32f"                          # A2, like-for-like
CA_CONTRAST   <- CCX_MODE_SEASML0_CONTROL            # A3, structure contrast
CA_ARMS       <- c(CA_LIKE, CA_CONTRAST)
CA_REF_RDS    <- file.path("data", "constraint_map.rds")
CA_ARM_RDS    <- function(m) file.path("outputs", "diagnostics",
                                       sprintf("constraint_map_%s.rds", m))
CA_LOG        <- file.path("outputs", "diagnostics",
                           sprintf("%s_%s.log", CA_TAG, CA_DATE))
CA_PIN_CUT    <- 0.5     # must match the map's own CM_PIN_CUT; GATED below
CA_NTOP       <- 6L      # rows of the opposed table, = the app's own n
# EXTERNAL ANCHOR (the `ccx_diag_must_use_mode_base` lesson): a multi-arm
# diagnostic must reproduce ONE number the app already prints before any arm is
# read, or every arm can be mutually consistent and still not be what was asked.
CA_ANCHOR_PAR <- "seas_lag_p_NH"
CA_ANCHOR_OPP <- 2.34
CA_ANCHOR_TOL <- 0.01

dir.create(dirname(CA_LOG), showWarnings = FALSE, recursive = TRUE)
ca_say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = CA_LOG, append = TRUE) }

stopifnot(file.exists(CA_REF_RDS))
CM <- list(); CM[[CA_REF]] <- readRDS(CA_REF_RDS)
for (m in CA_ARMS) {
  f <- CA_ARM_RDS(m)
  if (!file.exists(f)) stop(sprintf("missing %s -- run: Rscript calibration/diag_constraint_map.R mode=%s", f, m))
  CM[[m]] <- readRDS(f)
}
ALL <- c(CA_REF, CA_ARMS)

ca_say("\n=== %s (%s) ===\n", CA_TAG, CA_DATE)
ca_say("\n-- the arms, and what each one differs from the reference BY --\n")
for (m in ALL) {
  p <- CM[[m]]$provenance
  md <- readRDS(ccx_mode_file(m)); bp <- ccx_mode_base(md)
  ca_say("  %-10s names %2d  seas_ml %-2s  spinup %-9s logpost %12.6f  pins %2d  %s\n",
         m, ncol(CM[[m]]$M), as.character(bp$seas_ml), p$spinup, p$stored_logpost,
         length(p$pins),
         if (m == CA_REF) "<- REFERENCE (the shipped arm)"
         else if (m == CA_LIKE) "<- A2 like-for-like: same structure, frees 3 pins"
         else "<- A3 STRUCTURE contrast: NOT an answer to the fit question")
}

# ---------------------------------------------------------------------
# GATES, before a single number is compared.
# ---------------------------------------------------------------------
ok <- TRUE
# G1 the pin cut must be the same in every arm, or "pins" means different things
cuts <- vapply(ALL, function(m) CM[[m]]$pin_cut, numeric(1))
g1 <- all(cuts == CA_PIN_CUT)
ca_say("\n=== GATE CUT === pin cut %s in all %d arms (this script assumes %.2f) -> %s\n",
       paste(unique(cuts), collapse = "/"), length(ALL), CA_PIN_CUT,
       if (g1) "PASS" else "*** FAIL ***"); ok <- ok && g1
# G2 the step KIND must match, or the steps are not equal-difficulty
kinds <- vapply(ALL, function(m) CM[[m]]$step_kind, character(1))
g2 <- length(unique(kinds)) == 1L && unique(kinds) == "conditional"
ca_say("=== GATE STEP === step kind %s in all arms -> %s\n",
       paste(unique(kinds), collapse = "/"), if (g2) "PASS" else "*** FAIL ***"); ok <- ok && g2
# G3 identical stream sets, or a row share is a share of a different objective
S0 <- rownames(CM[[CA_REF]]$M)
g3 <- all(vapply(ALL, function(m) setequal(rownames(CM[[m]]$M), S0), logical(1)))
ca_say("=== GATE STREAMS === all arms carry the same %d streams -> %s\n",
       length(S0), if (g3) "PASS" else "*** FAIL ***"); ok <- ok && g3
if (!ok) stop("arm-comparison gates failed; the comparison would be uninterpretable")

# ---------------------------------------------------------------------
# The app's own opposed-pull definition, mirrored (app/global.R
# `app_cmap_tensions`). ⚠ Mirrored, not re-derived: the ANCHOR gate below
# proves it reproduces what the app prints.
# ---------------------------------------------------------------------
ca_tensions <- function(cm, keep = NULL) {
  fam <- cm$family
  SL  <- cm$SLOPE
  if (!is.null(keep)) SL <- SL[, intersect(colnames(SL), keep), drop = FALSE]
  S <- vapply(fam, function(ss) colSums(SL[ss, , drop = FALSE]), numeric(ncol(SL)))
  if (is.null(dim(S))) S <- matrix(S, nrow = ncol(SL), dimnames = list(colnames(SL), names(fam)))
  out <- do.call(rbind, lapply(rownames(S), function(par) {
    v <- S[par, ]
    hi <- names(which.max(v)); lo <- names(which.min(v))
    if (v[[hi]] <= 0 || v[[lo]] >= 0) return(NULL)
    data.frame(par = par, up = hi, down = lo,
               opposed = min(v[[hi]], -v[[lo]]), stringsAsFactors = FALSE)
  }))
  if (is.null(out) || !nrow(out)) return(NULL)
  out[order(-out$opposed), , drop = FALSE]
}

TREF <- ca_tensions(CM[[CA_REF]])
a_ok <- identical(TREF$par[[1]], CA_ANCHOR_PAR) &&
        abs(TREF$opposed[[1]] - CA_ANCHOR_OPP) < CA_ANCHOR_TOL
ca_say("=== GATE ANCHOR === reference top-opposed = %s at %.3f; the app prints %s at %.2f -> %s\n",
       TREF$par[[1]], TREF$opposed[[1]], CA_ANCHOR_PAR, CA_ANCHOR_OPP,
       if (a_ok) "PASS" else "*** FAIL ***")
if (!a_ok) stop("the mirrored tension definition does not reproduce the app's own number")

# ---------------------------------------------------------------------
# LIKE-FOR-LIKE: restrict to the names shared with the reference.
# ---------------------------------------------------------------------
N0 <- colnames(CM[[CA_REF]]$M)
pin_share <- function(cm, keep) {
  M <- cm$M[, intersect(colnames(cm$M), keep), drop = FALSE]
  P <- cm$PINS[, colnames(M), drop = FALSE]
  w <- M / max(M)
  100 * sum(w * P) / sum(w)
}
ca_say("\n-- PINS vs PULLS: the headline, on each arm's FULL name set and on the SHARED names --\n")
ca_say("   %-10s %8s %8s %10s   %s\n", "arm", "n_full", "n_shared", "pin_full", "pin_shared")
for (m in ALL) {
  sh <- intersect(colnames(CM[[m]]$M), N0)
  ca_say("   %-10s %8d %8d %9.1f %% %9.1f %%\n", m, ncol(CM[[m]]$M), length(sh),
         pin_share(CM[[m]], colnames(CM[[m]]$M)), pin_share(CM[[m]], sh))
}
ca_say("   ⭐ the claim under test is that PULLS dominate, i.e. the fitted values sit where\n")
ca_say("      opposing pulls cancel. It survives if every arm is far below 50 %%.\n")

# per-parameter total leverage: does the ORDERING survive?
ca_say("\n-- TOTAL LEVERAGE per parameter: does the ordering survive the arm? --\n")
tot <- lapply(ALL, function(m) colSums(CM[[m]]$M)); names(tot) <- ALL
for (m in CA_ARMS) {
  sh <- intersect(names(tot[[m]]), names(tot[[CA_REF]]))
  a <- tot[[CA_REF]][sh]; b <- tot[[m]][sh]
  ca_say("   %-10s n=%2d  Spearman %.3f  Pearson %.3f  | argmax: %s (ref) vs %s (%s)\n",
         m, length(sh), suppressWarnings(cor(a, b, method = "spearman")),
         suppressWarnings(cor(a, b)), names(which.max(a)), names(which.max(b)), m)
}
ca_say("   ⚠ `k_w` having the HIGHEST total leverage of all names is a shipped claim\n")
ca_say("     (`ccx_constraint_map_tab`): the argmax column above is that claim, per arm.\n")

# the opposed table: does the RANKING survive?
ca_say("\n-- THE OPPOSED PAIRS (the informative cells), top %d, on the SHARED names --\n", CA_NTOP)
for (m in ALL) {
  sh <- intersect(colnames(CM[[m]]$M), N0)
  tt <- ca_tensions(CM[[m]], keep = sh)
  ca_say("   %s:\n", m)
  if (is.null(tt)) { ca_say("      (none)\n"); next }
  for (i in seq_len(min(CA_NTOP, nrow(tt))))
    ca_say("      %-20s %6.2f   wants HIGHER: %-26s wants LOWER: %s\n",
           tt$par[[i]], tt$opposed[[i]], tt$up[[i]], tt$down[[i]])
}

# the shipped row-share headlines, per arm
ca_say("\n-- ROW SHARES: who holds each observation family (%%), reference vs arms --\n")
fams <- rownames(CM[[CA_REF]]$RS)
comps <- colnames(CM[[CA_REF]]$RS)
for (f in fams) {
  ca_say("   %-30s", f)
  for (m in ALL) {
    RS <- CM[[m]]$RS
    if (!(f %in% rownames(RS))) { ca_say("  %22s", "-"); next }
    v <- RS[f, ]; k <- names(which.max(v))
    ca_say("  %-18s %5.1f", substr(k, 1, 18), max(v))
  }
  ca_say("\n")
}
ca_say("   (each cell: the component holding the LARGEST share of that row, and that share)\n")

ca_say("\nwrote %s\n", CA_LOG)
