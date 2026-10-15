# =====================================================================
# diag_constraint_map_arms.R -- IS THE CONSTRAINT MAP A PROPERTY OF THE
# MODEL, OR ONLY OF THIS FIT?  (Marcus's ruling, 2026-09-26)
#
# THE QUESTION. `diag_constraint_map.R` measures the map at ONE point, the
# canonical mode. Every pins/pulls claim in the app therefore rests on a
# single fit with no way to say whether it would survive a different one.
# This script evaluates the SAME map at further arms and compares.
#
# ⛔⛔ THE ARM CHOICE IS THE WHOLE METHOD, AND IT WAS MEASURED (09-26; re-chosen 10-12).
#   A2  hilda29a6 -- THE LIKE-FOR-LIKE ARM (2026-10-12, Marcus: "hilda29a6 (Recommended)").
#       Objective #18's OTHER landed basin: the SAME structure as the canonical
#       (hilda_csl3v0kaidgbemwt, seas_ml 1, periodic spinup) and the SAME 29 names,
#       h_ml 50.0 against 64.6. Its four module pins are pass 1's values (w_enso_l2
#       16.61 vs 16.79, lag_enso_land 5.85 vs 5.93). So a difference between its map
#       and the canonical's is about WHERE THE FIT SITS, which is the question asked.
#       No free SUPERSET exists at #18: the module holds those four names by design.
#       ⚠ WAS hilda32f (09-26), the free parent of hilda29l. At hilda29e it is
#       neither the same structure (hilda_csl3) nor a superset: it lacks ndep_ret,
#       imb_share_land and imb_share_ocean_rest. Measured 10-12, not assumed.
#   A3  hilda31pe -- THE STRUCTURE CONTRAST, reported but NOT an answer to the
#       question. It is seas_ml **0** and NOT a superset (it lacks `w_enso_l2`;
#       28 of 29 shared). A difference could be the fit OR the structure and the
#       comparison cannot separate them. It is the seas_ml ON/OFF control and
#       licenses THAT comparison only -- the standing trap
#       [[iso_deep_control_licenses_one_comparison]]: a control licenses only
#       the comparison it was built for. Kept because the contrast is
#       interesting, labeled because it is not the answer.
#
# ⚠ LIKE-FOR-LIKE: every share is recomputed on the SHARED names and the
# shared streams. A pin share over 29 names is not comparable to one over 32 --
# different denominators, and the three extra names are exactly the ones the
# canonical pins, so they are not a random sample of the space.
# ⚠ STREAMS (2026-10-12): at hilda29e the ENSO-slope row is scored by the module,
# not the main fit, so hilda31pe carries one stream more (27). An arm's extra
# streams are DROPPED only if every one is DECLARED arm-only (CA_ARM_ONLY_STREAMS)
# and forms a family of its own, so that no shared row's share changes. Anything
# else stops the script.
#
# ⭐ WHY A CROSS-ARM COMPARISON IS MEANINGFUL AT ALL: the step is one
# CONDITIONAL Hessian sd, an equal-difficulty step by construction (predicted
# quadratic drop 0.5 log-units for EVERY name, at EVERY arm). Leverage is
# therefore already normalized per name per arm.
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
CA_LIKE       <- "hilda29a6"                         # A2, like-for-like (was hilda32f to 10-12)
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
# app_cmap_tensions(APP_CMAP)'s top row at hilda29e, read 2026-10-12 from the app loaded by
# shiny::loadSupport() (2.3159883). It was 2.34 at hilda29l (09-26). It MOVES AT EVERY ADOPTION.
CA_ANCHOR_OPP <- 2.316
CA_ANCHOR_TOL <- 0.01
# streams an arm may carry and the reference does not: diag_constraint_map.R's CM_ARM_ONLY_STREAMS
CA_ARM_ONLY_STREAMS <- c("gcb_ocean_enso_slope")
CA_ROLE <- c(ref      = "<- REFERENCE (the shipped arm)",
             like     = "<- A2 like-for-like: same structure and names, objective #18's other basin",
             contrast = "<- A3 STRUCTURE contrast: NOT an answer to the fit question")
# the shipped tie rule (app/global.R; since 2026-10-14 posterior winner stability, not a margin cut), and the
# matrices a stream restriction must subset
CA_TIE_CONSTS <- c("APP_CMAP_TIE_LOST_MAX", "APP_CMAP_TIE_SRC")
CA_STREAM_MATS <- c("M", "DHI", "DLO", "CURV", "SLOPE", "PINS")
CA_FAMILY_MATS <- c("MC", "RS", "CS")

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
         if (m == CA_REF) CA_ROLE[["ref"]] else if (m == CA_LIKE) CA_ROLE[["like"]] else CA_ROLE[["contrast"]])
}

# ---------------------------------------------------------------------
# SHARED STREAMS (2026-10-12): an arm's extra streams are dropped only if each is
# DECLARED arm-only and sits in a family of its own; otherwise STOP.
# ---------------------------------------------------------------------
S0 <- rownames(CM[[CA_REF]]$M)
for (m in CA_ARMS) {
  cm <- CM[[m]]
  extra <- setdiff(rownames(cm$M), S0); missing <- setdiff(S0, rownames(cm$M))
  if (length(missing)) stop(sprintf("%s lacks reference streams: %s", m, paste(missing, collapse = ", ")))
  if (!length(extra)) next
  undeclared <- setdiff(extra, CA_ARM_ONLY_STREAMS)
  if (length(undeclared)) stop(sprintf("%s carries UNDECLARED extra streams: %s", m, paste(undeclared, collapse = ", ")))
  drop_fam <- names(cm$family)[vapply(cm$family, function(s) any(s %in% extra), logical(1))]
  mixed <- drop_fam[!vapply(cm$family[drop_fam], function(s) all(s %in% extra), logical(1))]
  if (length(mixed)) stop(sprintf("%s: family %s mixes shared and arm-only streams; its share cannot be restricted",
                                  m, paste(mixed, collapse = ", ")))
  for (nm in CA_STREAM_MATS) cm[[nm]] <- cm[[nm]][S0, , drop = FALSE]
  for (nm in CA_FAMILY_MATS) cm[[nm]] <- cm[[nm]][setdiff(rownames(cm[[nm]]), drop_fam), , drop = FALSE]
  cm$family <- cm$family[setdiff(names(cm$family), drop_fam)]
  CM[[m]] <- cm
  ca_say("  %-10s compared on the %d shared streams: dropped arm-only %s (family %s)\n",
         m, length(S0), paste(extra, collapse = ", "), paste(drop_fam, collapse = ", "))
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

# ---------------------------------------------------------------------
# THE ARMS' VIEW OF THE TIES (2026-10-12; the shipped rule moved 2026-10-14). The margin is the REFERENCE
# row's top-two share gap; a row FLIPS if its winner differs at an arm. Two definitions: A2 only (the
# like-for-like answer) and every arm (09-26's). ⚠ REPORT ONLY since 10-14: the app's tie rule is now the
# posterior winner-loss share (calibration/diag_cmap_posterior_spread.R, promote_cmap_stability.R), because
# at hilda31w the mode's margin did not predict whether a winner holds across the posterior.
# ---------------------------------------------------------------------
TIE <- new.env()
for (e in parse(ccx_path("app", "global.R")))
  if (is.call(e) && identical(as.character(e[[1]]), "<-") && is.name(e[[2]]) &&
      as.character(e[[2]]) %in% CA_TIE_CONSTS) eval(e, TIE)
ca_margin <- function(r) { v <- sort(100 * r / sum(r), decreasing = TRUE); v[[1]] - v[[2]] }
ca_winner <- function(r) names(which.max(r))
MC0 <- CM[[CA_REF]]$MC
mg  <- apply(MC0, 1, ca_margin)
win <- sapply(ALL, function(m) apply(CM[[m]]$MC[rownames(MC0), , drop = FALSE], 1, ca_winner))
flip_like <- win[, CA_LIKE] != win[, CA_REF]
flip_any  <- apply(win[, CA_ARMS, drop = FALSE] != win[, CA_REF], 1, any)
ca_say("\n-- THE TIE CUT, RE-MEASURED: the reference's top-two margin per row, and whether the winner FLIPS --\n")
ca_say("   shipped rule: a tie when the winner loses in > %.0f %% of posterior draws (%s)\n",
       100 * TIE$APP_CMAP_TIE_LOST_MAX, TIE$APP_CMAP_TIE_SRC)
o <- order(mg)
for (i in o)
  ca_say("   %-30s margin %6.2f pp  %s%s\n", rownames(MC0)[i], mg[[i]],
         paste(sprintf("%s: %-18s", ALL, substr(win[i, ], 1, 18)), collapse = " "),
         if (flip_like[[i]]) "  FLIPS at A2" else if (flip_any[[i]]) "  flips at A3 only" else "")
ca_endpoints <- function(flip, lab) {
  fm <- if (any(flip)) max(mg[flip]) else NA_real_
  sm <- if (any(!flip)) min(mg[!flip]) else NA_real_
  sep <- !is.na(fm) && !is.na(sm) && fm < sm
  ca_say("   %-12s flippers %2d, largest margin %s; stable %2d, smallest %s -> %s%s\n", lab,
         sum(flip), if (is.na(fm)) "  - " else sprintf("%.3f", fm), sum(!flip),
         if (is.na(sm)) "  - " else sprintf("%.3f", sm),
         if (sep) "SEPARATED" else if (is.na(fm)) "NO FLIPPER: the cut has no lower endpoint" else "*** NOT SEPARATED ***",
         if (sep) sprintf(", geometric-mean cut %.3f pp", sqrt(fm * sm)) else "")
  invisible(c(flip_max = fm, stable_min = sm))
}
EP_LIKE <- ca_endpoints(flip_like, "A2 only")
EP_ANY  <- ca_endpoints(flip_any, "every arm")
# THE SPREAD (Marcus 2026-10-12, "Scale to basin spread"): the SIGNED change, at A2, of each reference
# row's margin of its OWN winner over the best other component. The shipped cut is its largest |value|.
ca_signed <- function(r, w) { s <- 100 * r / sum(r); s[[w]] - max(s[names(s) != w]) }
w0 <- apply(MC0, 1, ca_winner)
shift <- vapply(rownames(MC0), function(f) ca_signed(CM[[CA_LIKE]]$MC[f, ], w0[[f]]) - ca_signed(MC0[f, ], w0[[f]]), numeric(1))
ca_say("   SPREAD at A2 (%s): |margin shift| median %.3f, max %.3f pp (%s) -- the retired 10-12 rule's cut, reported only\n",
       CA_LIKE, median(abs(shift)), max(abs(shift)), names(which.max(abs(shift))))

ca_say("\nwrote %s\n", CA_LOG)
