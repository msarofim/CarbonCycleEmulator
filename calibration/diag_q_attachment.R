# =====================================================================
# diag_q_attachment.R -- WHERE SHOULD HD ATTACH TO THE COLUMN?
#
# Pre-registered in notes/prereg_2026-09-05f_q_attachment_depth.md. Scores
# P0-P5 in order and stops at the first P0 failure.
#
# THE QUESTION. HILDA's `q` exchanges with the Interior "assumed independent of
# depth". 2026-09-05 built that and it FAILED (P4, mean|z| 2.05 against the
# 09-04k2 reduced form's 1.81) for a diagnosed reason: HD sits at ~-109 permil
# and the interior crosses -109 at ~1000 m, so a SINGLE-ENDMEMBER bulk exchange
# ages the column above that depth and YOUNGENS it below -- and the whole
# scored band is below, already too young against GLODAP.
#
# Marcus 2026-09-05: "We don't need to stay true to HILDA, but we should stay
# true to the conceptual way that the simplified model's ocean works." CCX's
# ocean is a PURE-DIFFUSION column in which the interior is reached by mixing
# from above; deep water formation, which is what HS/HD represents, fills the
# DEEP. So HD attaches at the bottom. That is a departure from HILDA and NOT
# from CCX -- see the prereg section 1.
#
# ⛔ THE ARM TESTED HERE IS NOT "HILDA's MODEL". Label every number.
#
# THE CONTROL IS ISO-DEEP, as in 2026-09-04k and 2026-09-05: `kz` is re-solved
# per arm to hold the LS bottom box at the incumbent's D14C, so the question is
# purely whether the intermediate profile improves AT THE SAME DEEP AGE.
#
# ⚠ EVERY REFERENCE IS RECOMPUTED IN THIS RUN. The 09-05 depth-independent arm
# is an arm here, not a typed constant -- see the standing rule "never gate on a
# threshold typed from another run's rounded output" (handoff 2026-09-05 sec.8),
# which was added because a gate in this same arc did exactly that.
#
# Usage:  Rscript calibration/diag_q_attachment.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

# ---- named constants (labels below derive from these) -----------------
QA_HS_FRAC   <- 0.16         # HILDA: 16 % of the global ocean surface
QA_U_HILDA   <- 38           # m/yr over the HS area; HILDA Table 1, 38 +/- 17
QA_TAU_Q     <- 538          # HILDA Table 1: q^-1 = 538 +/- 510 yr
QA_SST_HS    <- 2.0          # degC; the carbonate tables' floor (Lueker 2000)
QA_NEFF      <- LIK_D14C_DEEP_NEFF
QA_SCORED_MIN_DEPTH <- 1500  # bomb addition <= 4.5 permil below this
QA_GEOSECS_LS <- c(-40, 20)  # HILDA Table 2, attributed to GEOSECS
# The attachment arms. 1 = every layer = HILDA's depth-independent q = the
# 09-05 structure. NL is the BOTTOM BOX ONLY -- the declared arm, the boxed
# analogue of 09-04k2's ML<->bottom conduit, chosen with NO free boundary.
QA_ATTACH_ARMS <- c(1, 10)
QA_ATTACH_REF  <- 1          # the arm every delta below is measured AGAINST
QA_ATTACH_TEST <- 10
# tau_q scan. The pre-check says the bottom-attached arm needs ~2.7x MORE
# exchange (= shorter tau_q) because HD is a 2.69x weaker ventilation source
# than the mixed layer. HILDA's own prior is 538 +/- 510, so 28 is its floor;
# anything below 28 is OUTSIDE HILDA's prior and must be labelled so.
QA_TAU_Q_SCAN  <- c(28, 100, 200, 538, 1048)
QA_TAU_Q_PRIOR <- c(28, 1048)   # HILDA 538 +/- 510

v0   <- dg_vector(CCX_MODE_CANONICAL)
grid <- ccx_ocean_grid(v0$p$h_ml)
op   <- dg_obs_profile(grid)
zmid <- cumsum(grid$dz) - grid$dz / 2

par_q <- function(attach, tau_q = QA_TAU_Q, u = QA_U_HILDA) {
  p <- v0$p
  p$hs_frac <- QA_HS_FRAC; p$u_hs <- u; p$tau_q <- tau_q
  p$sst_hs <- QA_SST_HS;   p$q_attach_from <- attach
  p
}
deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
prof_of <- function(sp) {
  aux <- sp$aux
  lay <- function(h) { ix <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
                       1000 * (sp$y[ix, "C14"] / sp$y[ix, "C"] - 1) }
  (lay("NH") * aux$a_ls$NH + lay("SH") * aux$a_ls$SH) / (aux$a_ls$NH + aux$a_ls$SH)
}
zs_of <- function(prof) (prof - op$d14) / (op$d14_sd / sqrt(QA_NEFF))
SC <- which(zmid > QA_SCORED_MIN_DEPTH)

cat(sprintf(paste0("\n=== q ATTACHMENT DEPTH -- mode %s, hs_frac %.0f%%, ",
                   "sst_hs %.1f C, u_hs %g ===\n"),
            CCX_MODE_CANONICAL, 100 * QA_HS_FRAC, QA_SST_HS, QA_U_HILDA))
cat(sprintf("  attachment arms (1-based layer): %s   NL = %d\n",
            paste(QA_ATTACH_ARMS, collapse = ", "), grid$nl))

# ---- P0: identity, parity, conservation, mutation ---------------------
cat("\n=== P0: THE SWITCH IS WIRED AND ITS OFF STATE IS THE 09-05 STRUCTURE ===\n")
p_ref <- par_q(QA_ATTACH_REF)
p_abs <- p_ref; p_abs$q_attach_from <- NULL      # a list from before 2026-09-05f
s_ref <- ccx_spinup(p_ref); s_abs <- ccx_spinup(p_abs)
ok_id <- identical(s_abs$y, s_ref$y)
cat(sprintf("  P0a  absent == 1 (the 09-05 structure) : %s   max|d| %.3e\n",
            ok_id, max(abs(s_abs$y - s_ref$y))))

zf <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
           cum_luc = list(NH = 0, SH = 0), gmst = 0, enso = 0,
           c14_bomb = 0, c14_nuclear = 0, d13c_foss = -27.6,
           c14_cosmo = s_ref$prod_c14)
p0 <- ccx_set_enso(par_q(QA_ATTACH_TEST), list(gamma_enso = 0))
p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
s_t <- ccx_spinup(p0)
dC <- ccx_deriv_fast(s_t$y, 1750, p0, zf, s_t$grid, s_t$aux)
dR <- ccx_deriv(s_t$y, 1750, p0, zf, s_t$grid, s_t$aux)
clo <- sum(abs(dC[, "C"])) / sum(s_t$y[, "C"])
par_abs <- max(abs(dR - dC))
cat(sprintf("  P0a2 carbon closure at the TEST arm    : %.3e   %s\n",
            clo, if (clo < 1e-9) "PASS" else "FAIL"))
cat(sprintf("  P0a2 R vs C++ single deriv, TEST arm   : %.3e\n", par_abs))

# P0b MUTATION: moving the set by ONE layer must move the deep.
mut <- vapply(c(QA_ATTACH_TEST - 1L, QA_ATTACH_TEST), function(k)
              deep_of(par_q(k)), numeric(1))
ok_mut <- abs(diff(mut)) > 1e-6
cat(sprintf("  P0b  MUTATION, layer %d vs %d           : %.4f vs %.4f  %s\n",
            QA_ATTACH_TEST - 1L, QA_ATTACH_TEST, mut[1], mut[2],
            if (ok_mut) "PASS" else "FAIL -- the switch is INERT"))
if (!ok_id || clo >= 1e-9 || !ok_mut)
  stop("P0 FAILED -- nothing below this line is interpretable")

# ---- iso-deep solve ---------------------------------------------------
d0 <- ccx_spinup(local({ p <- v0$p; p$hs_frac <- 0; p }))$diagnostics$d14c_bottom_box
cat(sprintf("\n=== ISO-DEEP: kz re-solved per arm to hold the LS bottom box at %.3f ===\n", d0))
solve_kz <- function(mk) {
  f <- function(lk) { p <- mk(); p$kz <- exp(lk); deep_of(p) - d0 }
  lo <- log(v0$p$kz); hi <- log(v0$p$kz)
  n <- 0; while (f(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }
  n <- 0; while (f(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (f(lo) > 0 || f(hi) < 0) return(NA_real_)
  exp(stats::uniroot(f, c(lo, hi), tol = 1e-6)$root)
}
arm <- function(lbl, mk) {
  kz <- solve_kz(mk)
  if (is.na(kz)) { cat(sprintf("  %-28s NO kz holds the deep age -- CEILING\n", lbl))
                   return(NULL) }
  p <- mk(); p$kz <- kz
  sp <- ccx_spinup(p)
  pr <- prof_of(sp)
  list(lbl = lbl, kz = kz, sp = sp, prof = pr, z = zs_of(pr),
       meanz = mean(abs(zs_of(pr)[SC])), d = sp$diagnostics)
}

res <- list()
for (k in QA_ATTACH_ARMS) {
  lbl <- sprintf("attach from layer %d%s", k,
                 if (k == 1) " (HILDA, depth-indep)" else " (BOTTOM ONLY)")
  a <- arm(lbl, local({ kk <- k; function() par_q(kk) }))
  if (!is.null(a)) res[[as.character(k)]] <- a
}

cat("\n  arm                                    kz     kz/kz0     HS       HD     LS ml   mean|z|\n")
for (r in res)
  cat(sprintf("  %-34s %7.0f  %6.3f  %7.1f  %7.1f  %6.1f   %6.3f\n",
              r$lbl, r$kz, r$kz / v0$p$kz, r$d$d14c_hs[["NH"]],
              r$d$d14c_hd[["NH"]], r$prof[1], r$meanz))

ref <- res[[as.character(QA_ATTACH_REF)]]
tst <- res[[as.character(QA_ATTACH_TEST)]]
if (is.null(ref) || is.null(tst)) stop("an attachment arm did not solve -- cannot score")

# ---- P1 / P2 / P3 / P4 / P5 -------------------------------------------
cat("\n=== SCORING (every reference RECOMPUTED in this run) ===\n")
cat(sprintf("  P1  kz relief   : %7.0f (bottom) vs %7.0f (depth-indep)  %s\n",
            tst$kz, ref$kz, if (tst$kz < ref$kz) "PASS" else "FAIL"))
cat(sprintf("  P2  scored band : %6.3f vs %6.3f                        %s\n",
            tst$meanz, ref$meanz, if (tst$meanz < ref$meanz) "PASS" else "FAIL"))

# ⚠ THE BOTTOM BOX IS THE ISO-DEEP CONTROL AND CANNOT MOVE. It is pinned to
# d0 in EVERY arm by construction, so it contributes an IDENTICAL |z| to every
# arm and has NO POWER to discriminate between them -- a third of the scored
# statistic is a constant. Requiring it to age would be requiring the control
# to move: a test whose null is structurally guaranteed. P3 is therefore scored
# on the FREE scored layers only, and mean|z| is left on the full band so it
# stays comparable with 2.55 / 2.048 / 1.81 across this whole arc.
SC_FREE <- setdiff(SC, length(zmid))
cat("\n  P3  the crossover -- does the youngening go away?\n")
cat("      depth    interior(indep)  interior(bottom)   change   HD-interior(bottom)\n")
for (i in SC)
  cat(sprintf("    %7.0f m  %10.1f     %10.1f     %+7.1f     %+7.1f%s\n",
              zmid[i], ref$prof[i], tst$prof[i], tst$prof[i] - ref$prof[i],
              tst$d$d14c_hd[["NH"]] - tst$prof[i],
              if (i %in% SC_FREE) "" else "   <- ISO-DEEP CONTROL, no power"))
aged <- all(tst$prof[SC_FREE] < ref$prof[SC_FREE])
cat(sprintf("      every FREE scored layer AGES relative to depth-independent: %s\n",
            if (aged) "PASS" else "FAIL"))

# ⛔ P4 MUST BE READ AT MATCHED kz, NOT OFF THE TWO ISO-DEEP ARMS. The control
# solves a DIFFERENT kz per arm, so an HD read across arms confounds the
# attachment with kz -- and kz is by far the larger term. Reading it the wrong
# way attributes ~10 permil to the attachment when it owns ~2.
hd_at <- function(a, kz) { p <- par_q(a); p$kz <- kz
                           ccx_spinup(p)$diagnostics$d14c_hd[["NH"]] }
hd_attach <- hd_at(QA_ATTACH_TEST, ref$kz) - hd_at(QA_ATTACH_REF, ref$kz)
hd_kz     <- hd_at(QA_ATTACH_REF, tst$kz) - hd_at(QA_ATTACH_REF, ref$kz)
cat(sprintf("\n  P4  HD, DECONFOUNDED at kz = %.0f:\n", ref$kz))
cat(sprintf("        attachment alone : %+6.2f permil\n", hd_attach))
cat(sprintf("        kz alone (%.0f->%.0f): %+6.2f permil\n", ref$kz, tst$kz, hd_kz))
cat(sprintf("      => HD is set by kz, not by the attachment (ratio %.1fx).\n",
            abs(hd_kz / hd_attach)))
cat(sprintf("      The pre-check predicted HD would AGE; at matched kz it %s.\n",
            if (hd_attach < 0) "does, but by ~2 permil, not enough to matter" else
              "does NOT -- the predicted direction is wrong"))
cat("      ⚠ The iso-deep arms' HD must NOT be differenced.\n")
cat(sprintf("        (they read %.1f and %.1f, at DIFFERENT kz)\n",
            tst$d$d14c_hd[["NH"]], ref$d$d14c_hd[["NH"]]))
ls_ml <- tst$prof[1]
cat(sprintf("  P5  LS mixed layer %.1f vs GEOSECS %g +/- %g  : %s\n",
            ls_ml, QA_GEOSECS_LS[1], QA_GEOSECS_LS[2],
            if (abs(ls_ml - QA_GEOSECS_LS[1]) <= QA_GEOSECS_LS[2]) "inside" else "OUTSIDE"))

# ---- tau_q scan on the declared arm -----------------------------------
cat(sprintf(paste0("\n=== tau_q SCAN at the BOTTOM-ONLY arm (HILDA prior %g-%g yr) ===\n"),
            QA_TAU_Q_PRIOR[1], QA_TAU_Q_PRIOR[2]))
cat("  tau_q      in prior?      kz    kz/kz0       HD    mean|z|\n")
for (tq in QA_TAU_Q_SCAN) {
  a <- arm(sprintf("tau_q = %g", tq),
           local({ t <- tq; function() par_q(QA_ATTACH_TEST, tau_q = t) }))
  if (is.null(a)) next
  inpri <- tq >= QA_TAU_Q_PRIOR[1] && tq <= QA_TAU_Q_PRIOR[2]
  cat(sprintf("  %6g   %-12s %7.0f  %6.3f  %7.1f   %6.3f\n", tq,
              if (inpri) "yes" else "OUTSIDE", a$kz, a$kz / v0$p$kz,
              a$d$d14c_hd[["NH"]], a$meanz))
}
cat("\n  Reminder: any arm on this table is HILDA HS/HD boxes with q attached at\n")
cat("  the BOTTOM -- a deliberate departure from HILDA. It is NOT HILDA's model.\n")

# ---- THE DECOMPOSITION P1's FAILURE FORCED (NOT PRE-REGISTERED) -------
# P1 predicted bottom attachment would RELIEVE kz and it does the OPPOSITE:
# ageing the column so strongly that the iso-deep control has to RAISE kz to
# bring the deep back to target. So the pre-registered mechanism is refuted,
# and the question becomes whether the P2 gain is attributable to the
# attachment at all. This separates them: hold kz FIXED and vary only the
# attachment. ⚠ POST HOC -- it was written after seeing P1 fail, and it needs
# its own pre-registration before anything is built on it.
cat("\n=== DECOMPOSITION at MATCHED kz (POST HOC -- not pre-registered) ===\n")
cat("   kz     attach    bottom box   ")
cat(paste(sprintf("%7.0fm", zmid[SC]), collapse = "  "))
cat("   mean|z|\n")
for (kz in c(ref$kz, tst$kz)) for (a in QA_ATTACH_ARMS) {
  p <- par_q(a); p$kz <- kz
  sp <- ccx_spinup(p); pr <- prof_of(sp)
  cat(sprintf("  %5.0f   %-8s  %9.1f   %s   %6.3f\n", kz,
              if (a == QA_ATTACH_REF) "indep" else "bottom",
              sp$diagnostics$d14c_bottom_box,
              paste(sprintf("%8.1f", pr[SC]), collapse = ""),
              mean(abs(zs_of(pr)[SC]))))
}
cat(sprintf("  iso-deep target for the bottom box: %.3f -- an arm that misses it\n", d0))
cat("  is OFF the control and its mean|z| is NOT a comparable score.\n")
cat(sprintf("  GLODAP at the scored depths: %s\n",
            paste(sprintf("%.1f", op$d14[SC]), collapse = ", ")))
