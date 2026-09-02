# =====================================================================
# diag_prior_screen_enso25.R -- THE PRIOR SCREEN AT THE 25-PARAMETER MODE,
# AT BOTH CLUSTER REPRESENTATIVES, PRICED ON THE RATIO AND NOT ON THE z.
#
# WHY THIS EXISTS. handoff_2026-09-01e §6 makes adoption conditional on a
# prior-z screen that "has not been examined": sst_seas_amp_SH -4.71,
# rep_dC +3.60, sst_seas_amp_NH -2.95, q10 -2.64, npp_frac_NH -2.28.
#
# ⚠ BUT A z-RANKING IS THE WRONG INSTRUMENT HERE, AND THE PROJECT ALREADY
# KNOWS IT. `SST_SEAS_LOGSD` = 0.25 is a JUDGEMENT width, labelled as one at
# R/calibrate.R:23 ("A JUDGEMENT, not a measurement ... Nothing measures that
# gap today"); `NPP_FRAC_NH_SD` = 0.04 carries the same label. `seas_T_amp_*`
# instead get `ccx_bracket_lnorm()`, whose width IS a measured ambiguity. So a
# -4.71 on a judgement width and a -4.71 on a measured bracket are NOT the same
# statement, and sorting the two together ranks an invented width above a
# measured one. (2026-08-27 stated this as "PRICE IT ON THE RATIO, NOT THE z";
# this file is that rule made runnable.)
#
# ⇒ EVERY z IS PRINTED WITH ITS PRIOR'S PROVENANCE, and the provenance is
# DERIVED from the prior closure itself -- deparsed and matched against the
# constants -- never hand-maintained beside it. A hand-kept provenance column
# is the caption-sync bug waiting to happen.
#
# THREE-VALUED, DELIBERATELY: BRACKET (width is a measured ambiguity),
# JUDGEMENT (width is a chosen number the code LABELS as chosen), UNLABELLED
# (everything else). ⚠ UNLABELLED means "the code does not say", NOT "measured".
# Collapsing it into either of the other two would be asserting something the
# source does not.
#
# WHAT IT IS AND IS NOT. It ADOPTS NOTHING. `CCX_MODE_CANONICAL` is untouched
# and every mode is read BY PATH -- the same contract as
# diag_gates_in_the_new_basin.R. Adoption is Marcus's call.
#
# BOTH CLUSTER REPRESENTATIVES, because the survey's ten starts split into two
# micro-clusters 0.069 apart in u whose ONLY meaningful separation is `h_ml`
# (range 0.0654; next is rep_dC 0.0167). That is the documented h_ml
# step-instability reproducing. If the physics screen is the SAME at both, the
# instability costs nothing here and adoption can ignore it; if it DIFFERS,
# that difference is what the instability actually buys or costs, measured
# rather than assumed.
#
# Usage:  Rscript calibration/diag_prior_screen_enso25.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants -------------------------------------------------
# ⛔ THE REPRESENTATIVES ARE THE BEST **CONVERGED** MEMBER OF EACH CLUSTER, not
# the best member. Three of the ten starts are `out_of_time` (ids 3, 7, 8) and
# ids 3 and 7 are the two best logposts overall -- ranking a screen off a point
# the optimiser had not finished moving would report where the clock stopped.
PS_DIR   <- "calibration/output/multistart_20260901_enso25"
PS_REPS  <- c("A: cluster 1 (cold init)"          = "start_000.rds",
              "B: cluster 2 (obs-implied partition)" = "start_005.rds")
# The 21-parameter ancestor whose screen was measured on 2026-08-27
# (notes/collect_2026-08-27_post_fix_model_quality.md sec.4). Compared on
# SHARED names only, and GATED -- see PRIOR-DRIFT GATE below.
# ⭐ THREE ANCESTORS, IN ORDER, SO THE COMPARISON IS AN ATTRIBUTION AND NOT A
# LUMP. Between from90 and today the parameter set moved TWICE -- `seas_lag_p`
# split 21->22 on 08-31, the ENSO coefficients 22->25 on 09-01 -- so a single
# from90-to-now delta cannot say WHICH change moved a parameter. The two
# 22-parameter modes sit between them and are already on disk; using them costs
# nothing and turns "it moved" into "it moved HERE".
# ⚠ THE PARAMETER COUNT AND THE MECHANISM SIGNATURE ARE **READ FROM THE FILE**,
# never written into the label. `refit_20260831_seas_lag_split/` sounds like the
# post-split refit and is NOT: it holds a 21-parameter vector with the SCALAR
# `seas_lag_p`. I labelled it "22-par, post-lag-split" from its directory name
# and the table said otherwise -- which is the whole reason a label may not
# assert what a file can be asked. Each row below prints n and its lag/ENSO
# field names, so a mislabelled directory cannot mislead the reader either.
# Names are SHORT because they are also the attribution table's column heads.
PS_ANCESTORS <- c(
  "from90"   = "calibration/output/refit_20260825f_from90/mode_fit_pumpN.rds",
  "inc0830"  = "calibration/output/refit_20260831_seas_lag_split/from90/mode_fit_pumpN.rds",
  "bas0831e" = "calibration/output/polish_20260831_probe_basin/from90/mode_fit_pumpN.rds")
# ⛔ AND THE CONFOUND THAT FOLLOWS FROM IT, stated where it is read and not
# buried: the ONLY post-lag-split ancestor on disk is ALSO the new basin. So the
# lag split (21->22) and the 08-31e basin move CANNOT be separated by these
# files -- the column that carries one carries the other. A second variable
# moved inside the comparison; say so rather than attributing to either.
PS_TOPN     <- 12          # rows printed in the ranked tables
PS_ZTOL     <- 1e-3        # recompute-vs-stored agreement, in sd units

# ---- prior provenance, DERIVED from the closure ----------------------
# Matched against the two constants R/calibrate.R itself labels as judgements
# and the bracket helper. Named here so a rename breaks this loudly instead of
# silently reclassifying every row as UNLABELLED.
PS_BRACKET_FN  <- "ccx_bracket_lnorm"
PS_JUDGEMENT_K <- c("SST_SEAS_LOGSD", "NPP_FRAC_NH_SD")

ps_provenance <- function(nm, table = CCX_PARAM_TABLE) {
  s <- table[[nm]]
  if (is.null(s) || is.null(s$prior)) return(c(kind = "NONE", stem = NA))
  body_txt <- paste(deparse(s$prior), collapse = " ")
  if (grepl(PS_BRACKET_FN, body_txt, fixed = TRUE)) {
    stem <- sub('.*ccx_bracket_lnorm\\([^,]*,\\s*"([^"]+)".*', "\\1", body_txt)
    return(c(kind = "BRACKET", stem = if (identical(stem, body_txt)) NA else stem))
  }
  if (any(vapply(PS_JUDGEMENT_K, function(k) grepl(k, body_txt, fixed = TRUE), logical(1))))
    return(c(kind = "JUDGEMENT", stem = NA))
  c(kind = "UNLABELLED", stem = NA)
}

# ---- the prior's own centre, on the NATURAL scale --------------------
# Found by inverting ccx_prior_z rather than by parsing the closure for a
# location argument: the ratio must be against the number the prior ACTUALLY
# centres on, and a dlnorm(log(m), s) / dnorm(mu, s) / bracket_lnorm all put it
# in a different argument slot. One numeric contract covers all three.
ps_prior_centre <- function(nm, x_hint) {
  f <- function(v) tryCatch(ccx_prior_z(nm, v), error = function(e) NA_real_)
  lo <- x_hint; hi <- x_hint
  for (k in 1:60) { if (isTRUE(f(lo) < 0)) break; lo <- lo - max(abs(lo), 1) * 0.25 }
  for (k in 1:60) { if (isTRUE(f(hi) > 0)) break; hi <- hi + max(abs(hi), 1) * 0.25 }
  if (!isTRUE(f(lo) < 0) || !isTRUE(f(hi) > 0)) return(NA_real_)
  tryCatch(stats::uniroot(function(v) f(v), c(lo, hi), tol = 1e-8)$root,
           error = function(e) NA_real_)
}

ps_read <- function(path, label) {
  if (!file.exists(path)) stop("missing mode file: ", path)
  r <- readRDS(path)
  pm <- r$par_mode
  nm <- if (!is.null(r$param_names)) r$param_names else names(pm)
  list(label = label, path = path, par = pm, names = nm,
       logpost = r$logpost, stored_z = r$prior_z,
       converged = isTRUE(r$converged), oot = isTRUE(r$out_of_time))
}

ps_screen <- function(M) {
  z <- vapply(M$names, function(n)
    tryCatch(ccx_prior_z(n, M$par[[n]]), error = function(e) NA_real_), numeric(1))
  z
}

cat(sprintf("\n%s\nPRIOR SCREEN AT THE 25-PARAMETER MODE -- BOTH CLUSTER REPRESENTATIVES\n%s\n",
            strrep("=", 78), strrep("=", 78)))
cat("⛔ ADOPTS NOTHING. CCX_MODE_CANONICAL untouched; every mode read by path.\n")

MODES <- lapply(seq_along(PS_REPS), function(i)
  ps_read(file.path(PS_DIR, PS_REPS[[i]]), names(PS_REPS)[i]))

for (M in MODES)
  cat(sprintf("\n  %-38s logpost %14.6f  %s\n", M$label, M$logpost,
              if (M$oot) "*** OUT OF TIME ***" else if (M$converged) "converged" else "cap"))

# ---- GATE 1: the stored prior_z must be reproducible TODAY ------------
# ⛔ A STORED z DESCRIBES THE PRIORS THAT EXISTED WHEN IT WAS WRITTEN. If the
# table has moved since, the stored vector describes a posterior that no longer
# exists (R/calibrate.R:290 says exactly this about an earlier prior change).
# Recomputing from `par_mode` under TODAY's table and comparing is the only way
# to know which case we are in -- and it is the gate that makes the ancestor
# comparison below legitimate rather than assumed.
cat(sprintf("\n%s\nGATE 1 -- stored prior_z vs recomputed under TODAY's priors\n%s\n",
            strrep("-", 78), strrep("-", 78)))
Z <- list()
for (i in seq_along(MODES)) {
  M <- MODES[[i]]; z <- ps_screen(M); Z[[i]] <- z
  sz <- M$stored_z
  cmp <- if (is.null(sz)) NA else max(abs(z - sz[M$names]), na.rm = TRUE)
  cat(sprintf("  %-38s max |recomputed - stored| = %s\n", M$label,
              if (is.na(cmp)) "no stored vector" else sprintf("%.2e  %s", cmp,
                if (cmp <= PS_ZTOL) "OK" else "*** PRIORS HAVE MOVED ***")))
}

# ---- the screen, PROVENANCE-MARKED ------------------------------------
prov <- vapply(MODES[[1]]$names, function(n) ps_provenance(n)[["kind"]], character(1))
stem <- vapply(MODES[[1]]$names, function(n) ps_provenance(n)[["stem"]], character(1))

cat(sprintf("\n%s\nTHE SCREEN -- |z| RANKED, WITH EACH PRIOR'S PROVENANCE\n%s\n",
            strrep("=", 78), strrep("=", 78)))
cat("  BRACKET    = width is a MEASURED ambiguity (ccx_bracket_lnorm)\n")
cat("  JUDGEMENT  = width is a CHOSEN number the code labels as chosen\n")
cat("  UNLABELLED = the code does not say. NOT the same as measured.\n\n")
nms <- MODES[[1]]$names
ord <- order(pmax(abs(Z[[1]]), abs(Z[[2]])), decreasing = TRUE, na.last = TRUE)
cat(sprintf("  %-22s %9s %9s %9s  %s\n", "parameter", "z(A)", "z(B)", "B - A", "prior width"))
for (k in head(ord, PS_TOPN)) {
  n <- nms[k]
  cat(sprintf("  %-22s %9.2f %9.2f %9.2f  %s\n", n, Z[[1]][k], Z[[2]][k],
              Z[[2]][k] - Z[[1]][k], prov[[n]]))
}

# ---- THE FOUNDED TABLE: fitted vs the prior's OWN centre ---------------
cat(sprintf("\n%s\nPRICED ON THE RATIO -- fitted against what the prior centres on\n%s\n",
            strrep("=", 78), strrep("=", 78)))
cat("  This is the founded comparison for a JUDGEMENT width, where the z is\n")
cat("  partly a statement about a number someone chose.\n\n")
# ⛔ A RATIO AGAINST A PRIOR CENTRED ON ZERO IS NOT A NUMBER. `rep_dC` and the
# four `gamma_enso_*` are LOCATION parameters centred at 0; dividing by that
# centre produced 1e13-scale garbage that looked like a result. Ratios are
# reported ONLY for a multiplicative (positive-scale) prior; a zero-centred one
# gets its OFFSET in natural units, which is the statement that means something
# there. [[gate_bound_matches_its_claim]] -- the STATISTIC has to match the kind
# of parameter too, not only the bound.
ps_ratio_ok <- function(ctr, x) is.finite(ctr) && abs(ctr) > 1e-6 * max(abs(x), 1)
# ⭐ THE FOUNDED ROWS ARE ALWAYS SHOWN, not only the top-|z| ones. A BRACKET
# parameter that has come back INSIDE its bracket is exactly the row a z-ranking
# hides -- and `seas_T_amp_SH` went -4.64 -> -0.64 doing precisely that.
founded <- nms[prov[nms] %in% c("BRACKET", "JUDGEMENT")]
show <- nms[nms %in% union(nms[head(ord, PS_TOPN)], founded)]
cat(sprintf("  %-22s %11s %11s %9s %9s  %s\n",
            "parameter", "fitted(A)", "prior centre", "ratio(A)", "ratio(B)", "provenance"))
for (n in show) {
  xa <- MODES[[1]]$par[[n]]; xb <- MODES[[2]]$par[[n]]
  ctr <- ps_prior_centre(n, xa)
  rok <- ps_ratio_ok(ctr, xa)
  cat(sprintf("  %-22s %11.4f %11s %9s %9s  %s\n", n, xa,
              if (!is.finite(ctr)) "--" else sprintf("%.4f", ctr),
              if (rok) sprintf("%.3f", xa / ctr) else sprintf("%+.3f", xa - ctr),
              if (rok) sprintf("%.3f", xb / ctr) else sprintf("%+.3f", xb - ctr),
              paste0(if (!is.na(stem[[n]])) sprintf("BRACKET %s [%.3f, %.3f]", stem[[n]],
                                                    ccx_const(paste0(stem[[n]], "_LO")),
                                                    ccx_const(paste0(stem[[n]], "_HI")))
                     else prov[[n]],
                     if (!rok) "  (OFFSET, prior centred 0 -- no ratio exists)" else "")))
}

# ---- the four ENSO coordinates, against their own N(0, 2) --------------
# ⭐ THE NEW COORDINATES ARE SCREENED SEPARATELY because they are the reason
# this parameter set exists. If they sit at the prior they are not identified
# by the data and the survey's "one basin" says less than it appears to.
cat(sprintf("\n%s\nTHE FOUR ENSO COEFFICIENTS -- the new coordinates, prior N(0, 2)\n%s\n",
            strrep("-", 78), strrep("-", 78)))
enso <- grep("^gamma_enso", nms, value = TRUE)
cat(sprintf("  %-22s %10s %10s %9s %9s\n", "parameter", "fitted(A)", "fitted(B)", "z(A)", "z(B)"))
for (n in enso)
  cat(sprintf("  %-22s %10.4f %10.4f %9.2f %9.2f\n", n,
              MODES[[1]]$par[[n]], MODES[[2]]$par[[n]],
              Z[[1]][match(n, nms)], Z[[2]][match(n, nms)]))

# ---- the ancestor, GATED ----------------------------------------------
cat(sprintf("\n%s\nAGAINST THE ANCESTORS -- shared names only, EACH GATED SEPARATELY\n%s\n",
            strrep("=", 78), strrep("=", 78)))
# ⛔ THE PRIOR-DRIFT GATE. `prior_z` is comparable across two fits ONLY where the
# prior is UNCHANGED (2026-08-27 relied on exactly that: "Priors did NOT change
# across the fix, so prior_z is comparable as 'where each mode sits'").
# Recomputing each ancestor's z from its own `par_mode` under TODAY's table and
# diffing against its STORED z MEASURES the drift per parameter instead of
# assuming it away. ⚠ ABSENCE ASSERTS: a shared name whose drift cannot be
# evaluated is NAMED, never silently dropped [[intersect_is_a_silent_default]].
ANC <- list()
for (ai in seq_along(PS_ANCESTORS)) {
  lab <- names(PS_ANCESTORS)[ai]; path <- PS_ANCESTORS[[ai]]
  cat(sprintf("\n%s\n%s   <- %s\n%s\n", strrep("-", 78), lab, path, strrep("-", 78)))
  if (!file.exists(path)) { cat(sprintf("  ⚠ ABSENT (%s) -- no comparison.\n", path)); next }
  A <- ps_read(path, lab)
  za_now <- ps_screen(A); za_old <- A$stored_z
  shared <- intersect(nms, A$names)
  drift <- if (is.null(za_old)) rep(NA_real_, length(shared))
           else abs(za_now[shared] - za_old[shared])
  ok <- !is.na(drift) & drift <= PS_ZTOL
  cat(sprintf("  %d parameters; %d shared with the 25-par set.\n", length(A$names), length(shared)))
  cat(sprintf("  lag field(s): %s   |   ENSO field(s): %s\n",
              paste(grep("seas_lag", A$names, value = TRUE), collapse = ", "),
              paste(grep("gamma_enso", A$names, value = TRUE), collapse = ", ")))
  cat(sprintf("  prior UNCHANGED for %d; MOVED for %d; unevaluable for %d.\n",
              sum(ok), sum(!is.na(drift) & drift > PS_ZTOL), sum(is.na(drift))))
  if (any(!is.na(drift) & drift > PS_ZTOL))
    cat(sprintf("    ⛔ PRIOR MOVED (delta z at the SAME value): %s\n",
                paste(sprintf("%s %.2f", shared[!is.na(drift) & drift > PS_ZTOL],
                              drift[!is.na(drift) & drift > PS_ZTOL]), collapse = ", ")))
  if (any(is.na(drift)))
    cat(sprintf("    ⚠ UNEVALUABLE (no stored z): %s\n", paste(shared[is.na(drift)], collapse = ", ")))
  ANC[[lab]] <- list(z = za_now, ok = shared[ok])
}

# ---- the attribution table -------------------------------------------
# ⭐ ONE ROW PER PARAMETER, ONE COLUMN PER STAGE, so a move lands in the stage
# that made it. A cell is blank where THAT stage's drift gate did not pass --
# blank means "not comparable here", never "no change".
cat(sprintf("\n%s\nATTRIBUTION -- z by stage. A BLANK cell = that stage's prior GATE failed,\nwhich means NOT COMPARABLE, not 'no change'.\n⚠ 08-30 -> 08-31e MOVES TWO THINGS AT ONCE (the lag split AND the basin), so a\n  change in that column attributes to NEITHER on its own.\n%s\n",
            strrep("=", 78), strrep("=", 78)))
labs <- names(ANC)
zcell <- function(lab, n) {
  a <- ANC[[lab]]; if (is.null(a) || !(n %in% a$ok)) return("       .")
  sprintf("%8.2f", a$z[[n]])
}
# ⚠ THE HEADER IS DERIVED FROM `labs`, not typed. It was typed once and went
# stale within the hour when the ancestor list changed -- the caption-sync bug
# this project has a rule against [[figure_captions]].
cat(sprintf("  %-22s %8s %8s %8s %8s  %s\n", "parameter",
            labs[1], labs[2], labs[3], "NOW(25)", "prior width"))
rank_by <- vapply(nms, function(n) {
  v <- c(vapply(labs, function(l) {
    a <- ANC[[l]]; if (is.null(a) || !(n %in% a$ok)) NA_real_ else a$z[[n]] }, numeric(1)),
    Z[[1]][match(n, nms)])
  if (all(is.na(v))) 0 else diff(range(v, na.rm = TRUE)) }, numeric(1))
for (n in nms[order(rank_by, decreasing = TRUE)][1:PS_TOPN])
  cat(sprintf("  %-22s %8s %8s %8s %8.2f  %s\n", n,
              zcell(labs[1], n), zcell(labs[2], n), zcell(labs[3], n),
              Z[[1]][match(n, nms)], prov[[n]]))

cat(sprintf("\n%s\n⛔ ADOPTS NOTHING. A screen says where a mode SITS against its priors;\n   it does not say the mode is wrong, and a JUDGEMENT width cannot say it.\n%s\n",
            strrep("=", 78), strrep("=", 78)))
