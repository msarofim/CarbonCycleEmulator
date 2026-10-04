# =====================================================================
# paths.R — resolve repo-relative paths regardless of working directory.
#
# Needed because scripts, testthat (which runs from tests/testthat/), and
# the Shiny app (which runs from app/) all have different working
# directories but must reach the same data/ files.
# =====================================================================

# ⛔ THE ROOT RESOLVER MOVED TO R/aaa_root.R (2026-09-09w). `REPO_MARKER`,
# `ccx_root()` and `ccx_path()` used to live here, but the alphabetical
# `list.files("R", ...)` bootstrap sources `calibrate.R` and `constants.R`
# BEFORE `paths.R`, so a constant that reads a data/ product at source time
# could not resolve a path. They are hoisted to a file that sorts first; see its
# header. Everything else about paths -- the canonical mode, the retired arms,
# mode decoding and the band contract -- stays here.

# =====================================================================
# THE CANONICAL MODE — ONE NAME, RESOLVED HERE (2026-08-27)
#
# WHY THIS EXISTS. Until today the adopted mode's path was a literal,
# `calibration/output/pump_arms/mode_fit_pump<arm>.rds`, written out in
# ccx_load_mode(), in app/global.R, and INDEPENDENTLY in ~35 diagnostics that
# never went through ccx_load_mode() at all. The 2026-08-25f seasonal-NEP
# isotope fix (`6bda464`) changed the OBJECTIVE, so every vector fitted before
# it — arm N included — is in
# `calibration/output/quarantine/20260825_seas_isotope_rectification/`, and the
# post-fix refit landed in a DIFFERENT directory. Repointing 35 literals is 35
# chances to point one of them at the quarantine; repointing one constant is
# one decision.
#
# THE FAILURE MODE THIS IS DEFENDING AGAINST is not a missing file — that is
# loud. It is a diagnostic that still resolves, silently, to a vector fitted on
# a different objective, and reports its numbers as current.
#
# `ref` IS DELIBERATELY NOT RESOLVABLE. `refit_20260825f_ref/mode_fit_pumpN.rds`
# is the PRE-FIX SEED the driver warm-started from, not a result (logpost -1909
# under the current objective); cycle 1's real result is in the `_progress.rds`
# beside it. That arm was abandoned as a worse local optimum. Naming it here
# would hand out the seed as if it were a mode.
# 2026-09-08f: `hilda31` -- the round-5 winner of the HILDA refit (31 parameters,
# structure "hilda": HS/HD boxes, K(z), the HS pump, u_hs and hs_asx_frac under
# their observations). ⚠ THE FIRST CANONICAL FITTED UNDER A STRUCTURE: the file
# carries `struct`, and every consumer builds its base list through
# ccx_mode_base(md) below, never ccx_default_params() (where hs_frac = 0 and the
# vector would run as a column with nothing said).
# 2026-09-10: `hilda31p` -- the SAME 31-parameter HILDA space, REFITTED under the
# PERIODIC spinup adopted 09-09x (`50f0105`) and the 09-09w priors. Torch arrays
# 17318015 + 17325832: 14/14 round-2 starts converged, 8 onto this point to four
# decimals, logpost -1480.540424, +9.0880 over `hilda31` RE-SCORED on the same
# objective (never over its stored -1478.66, which is in another objective's
# units ⇒ [[compare_gaps_not_absolute_logposts]]). ⚠ Fitted at `seas_ml = 0`,
# exactly as `hilda31` was: this is the SHIPPED model's mode under the adopted
# spinup, NOT a round-6 result ⇒ [[ccx_refit_ran_at_seas_ml_0]]. The file records
# `struct`, and ccx_mode_seas_ml() reads its absent `seas_ml` as the 0 it was.
# 2026-09-11 (8): `hilda31s` -- the SAME 31-parameter HILDA space with the SEASONAL
# MIXED LAYER ON (`seas_ml` 1), refitted under the corrected concentration
# observables (annual mean over the box's mass at the time, 09-11 (5)). Torch
# arrays 17367892 + 17379055: 8/24 converged, 18 dispersed reproduced the basin,
# logpost -1475.457904; on LIKELIHOOD equal to `hilda31p` (-0.61 / +0.23 across
# the two h_ml basins, inside the 0.5 convergence bound), priors +5.8, GATE P7
# PASS, P2 inside 2 sigma, P12 1.25x. Hessian PD, cond 3.4e5, NOTHING
# step-unstable (h_ml 64.8 +/- 2.3 m, the P8 wall 4 sigma out). Promoted on
# Marcus's ruling ("Promote 1"). `hilda31p` STAYS REGISTERED as the free
# `seas_ml` = 0 control: every seasonal-ML diagnostic scores against it, and the
# 09-10 rule that the canonical must WIN on today's objective is what keeps the
# pair honest (test-mode-file.R option 2).
# 2026-09-13: `hilda31s2` -- the SAME 31-parameter HILDA / seas_ml 1 space REFITTED
# under the 09-12 objective (annual-mean isotope pins, row-read concentrations,
# IntCal to 1941, no pre-run ice rows, observed-month D14C edge years). Round 7:
# 24 dispersed starts + a checkpoint resume, 12 CONVERGED, ids 1/3/14/20 at
# -1423.5675 to 4 dp (+8.68 over the restamped hilda31s: exactly the two d13C
# level rows the objective change had cost), h_ml UNCHANGED at 64.82 m; a
# second basin at h_ml 49.7 sits 0.35 behind. Hessian PD, cond 3.36e5,
# h_ml 64.82 +/- 2.43. Promoted on Marcus's ruling ("Promote id 1, run the
# Hessian, and repoint"). `hilda31p` STAYS the registered seas_ml = 0 control.
# 2026-09-13 (d): `hilda30c` -- THE FIRST PINNED CANONICAL. The SAME HILDA /
# seas_ml 1 space and the SAME 09-12 objective as `hilda31s2`, with the pCO2-side
# entrainment SHIM `ent_seas_amp_SH` PINNED to 0 (ccx_apply_pins; 30 free names):
# assessment 09-12 option C', asking whether the real seasonal mixed layer carries
# the SH ocean limb's DIC side on its own. It does: Torch job 17681685, 24 starts,
# 4 CONVERGED; promoted start id 3 (= id 1 to 4 dp; ids 0/6 TIME at the same
# point), pinned logpost -1426.242817, streams -1392.0158. ⚠ THAT LOGPOST IS NOT
# COMPARABLE TO A FREE ARM'S (no prior term, no Jacobian for the held name); on
# LIKELIHOOD over the 25 common rows it is -1392.02 vs `hilda31s2` -1389.48
# (-2.53, of which d13c_seasonal_SPO -1.88) and vs `hilda31p` -1396.26 (+4.24).
# The price against the parent is ACCEPTED by the ruling and RECORDED, not gated
# (test-mode-file). h_ml 65.23 +/- 2.40 m (Hessian PD, cond 3.31e5; h_ml's step
# drift 3.81 % over eps/3-3eps -- the plateau 1e-3..1e-2 is flat to 0.5 %, the
# 3 eps leg touches the same roll-off hilda31s2 has); sst_seas_amp_SH 1.288 +/-
# 0.188 -- CONFIDENTLY off its observation 1.746 (2.4 posterior sd), the thing the
# shim was standing in for. Promoted on Marcus's rulings ("Promote C' id 1";
# "Repoint"). `hilda31s2` STAYS REGISTERED as the FREE PARENT (the pinned arm's
# meaning is its likelihood price against that file); `hilda31p` stays the seas_ml
# = 0 control. Nothing is quarantined: the parent is not superseded. The shim is
# PINNED, not RETIRED from the table -- retirement would make `hilda31p` (shim
# 18.7 at seas_ml 0) unscorable; a later ruling.
# 2026-09-17 (h): `hilda30h` -- THE HYGIENE-BATCH REFIT, and the first canonical on
# the `hilda_c` STRUCTURE (hs_frac 0.128 = the ocean's actual fraction poleward of
# 57.14 deg, whole-LS SSTs 22.3/18.7, alpha_photo_eps 15.6; DESIGN sec.6) and the
# first FITTED under OBJECTIVE #12 (the 09-16 e batch: every-box D14C rows, the
# land-sink sigma at GCB's 0.5 with no x3, Naegler's net-uptake correction, the
# pre-1850 SST mean, h_hs under its Holte prior). SAME 30 free names as hilda30c:
# the pin set is the canonical's shim pin + the SIX names inert under this
# structure and the solved field (w_eq, gamma_eq without the cell; pump_export,
# w_vent, gamma_vent, w_thc without the martin field) -- held, not fitted, with
# no prior term. Run on the MAC (Torch fairshare 0.21), 24 starts, 23 CONVERGED;
# promoted start id 20 (ids 1/3/17 to 1e-5), pinned logpost -1434.725087,
# streams -1400.3026 -- vs the restamped hilda30c on ITS OWN structure -1414.77
# (+14.47 on the 25 common rows): the land sink 3.39 -> 3.12 GtC/yr (GCB 2.41;
# the row +59.4) paid by co2_icecore -13.4, d13c_seasonal_MLO -14.0, d13c_level
# -8.3, the bomb rows -8.6; beta_max 1.37, fert_k 855, luc_scale 0.83, kz 13,966
# (x1.27), h_hs 269 m, h_ml 64.67 +/- 2.81. The chain (H / GL / Q FAIL, the DIC
# gradient z +3.1) did NOT move. A second basin at h_ml 49.9 sits 0.45 behind
# (+1.47 on likelihood, -1.9 on priors) -- the round-6b pair again. Hessian PD,
# cond 2.46e5; gamma_enso_ocn_SH sits AT 0 = the KINK between the two limbs
# (ccx_core.cpp: > 0 the downward limb, < 0 the upward), so ITS Laplace sd is
# not a curvature. Promoted on Marcus's ruling ("Promote"). `hilda31s2` STAYS the
# registered free PARENT (on `hilda`: the pinned arm's likelihood price against
# it now straddles the structure change as well as the pin -- it is RECORDED,
# not gated); `hilda31p` stays the seas_ml = 0 control -- its refit under #12 /
# hilda_c is OWED. hilda30c is retired to CCX_MODE_HILDA30C_QUARANTINED below.
# 2026-09-19 (j): `hilda30e` -- THE CANONICAL's REFIT UNDER OBJECTIVE #13 (the GCB ENSO
# ocean-slope row, 09-18 e). SAME structure (hilda_c), SAME seas_ml 1, SAME 30 free
# names and the SAME pin set as hilda30h PLUS the limb's `w_enso_l2` held at 0 (absent
# under hilda_c; CCX_PARAM_ABSENT_OK). Wave id 1 = hilda30h's own re-convergence:
# pinned logpost -1432.393791, streams -1397.9253 on 26 rows; vs hilda30h's #13
# restamp +4.32 = +4.69 on gcb_ocean_enso_slope, -0.37 on the other 25 (every row
# within 0.26). The slope +0.040 -> +0.109 (0.94x GCB, z -0.27) through
# gamma_enso_ocn_NH 0.36 -> 0.45 ALONE (SH 0 -> 0.015): the slope is LINEAR in the
# shim, +0.633 per unit on the solubility term's -0.187, and the #12 objective was
# flat there (diag_enso_slope_gamma_scan.R). h_ml 64.67 +/- 2.81 unmoved; the chain
# (H / GL / Q FAIL, 7 / S PASS) unmoved; GATE V z -4.77. Hessian PD, cond 2.46e5;
# gamma_enso_ocn_SH is now step-STABLE (it sat ON the piecewise kink at 0 in hilda30h)
# but the NH/SH pair is near-degenerate for the row (r -0.990, +/- 0.27 each).
# Promoted on Marcus's ruling (09-19: "follow recommendations"). `hilda31s2` STAYS
# the registered free PARENT (on `hilda`, #13-restamped). THE CONTROL IS NOW
# `hilda31pe` (below) -- and ⛔ IT BEATS THE CANONICAL on likelihood (-1387.71 vs
# -1397.93 on 26 rows, 31 vs 30 names): test-mode-file's "canonical beats the
# control" gate is a NAMED STANDING RED by ruling 2 (09-19), NOT re-ruled -- the
# red IS the open question (the seasonal ML as mechanism vs its ~6-10 log-unit
# price), which the NH/SH split test (ruling 1) is to inform. hilda30h and
# hilda31p are retired to the *_QUARANTINED paths below.
# 2026-09-20 (o): `hilda30s` -- THE SAME 30 names and 8 pins as hilda30e, REFIT under the
# "hilda_cs" STRUCTURE: the seasonal mixed layer's NH cycle FLAT (ml_nh_cycle 0; the
# SH cycle on). Ruling 1's test (09-19 k/l -> 09-20 n) answered H_DRIVER: the ML's
# ~6-10 log-unit price against ML-off was its NH DRIVER, not the mechanism -- with
# the NH cycle flat the refit recovers d13c_seasonal_MLO entirely (200.91 -> 208.07;
# the control 208.12) through sst_seas_amp_NH 2.44 -> 1.68 (= the control's 1.71),
# and lands -1390.2774 on 26 rows / logpost -1425.056641: +7.65 over hilda30e on
# the SAME scale, -2.56 under the control hilda31pe at ONE FEWER name. Slope 0.94x
# kept (pair 0.44/0.04); gate S 0.286 @ 8.98 PASS; chain H / GL / Q FAIL, 7 PASS
# unchanged; GATE V z -4.79. Wave id 0 (21/24 CONVERGED; the h_ml RIDGE 49.9 / 58.0
# / 63.7 within 0.43: Hessian PD cond 2.42e5 but h_ml step-UNSTABLE at 3.0 %,
# +/- 3.25 Laplace understates it -- recorded, not gated, the 09-10 / 09-17 i
# precedent). Promoted on Marcus's ruling (09-20: "yes for all 3"). ⛔ THE NAMED
# RED STANDS at -2.56: the control still beats the canonical on likelihood, by
# ruling 2 (b) the gate is NOT re-cut to an AIC margin after the numbers are in.
# hilda30e is retired to CCX_MODE_HILDA30E_QUARANTINED below.
# 2026-09-20 (r): `hilda29l` -- THE LAYER-3 NINO3.4 RETURN LIMB ON THE SHIPPED STRUCTURE
# (hilda_csl3 = hilda_cs + the limb, k_l2 = 3, w0_l2 = 27 Sv): the physical limb
# `w_enso_l2` FITTED (13.71 +/- 2.13 Sv/index; Meinen's [14, 25] at 1 sd, 0.3 below at the
# point) REPLACES the two-coefficient ocean ENSO shim, gamma_enso_ocn_NH/SH now PINNED at
# 0. 29 names, 9 pins. Wave id 3 (22/24 CONVERGED; the h_ml ridge, w tracking it 12.9 /
# 13.7 / 15.1). likelihood -1391.8051 on 26 rows, logpost -1425.362014; vs hilda30s
# -1390.2774 at 30 names = dAIC +1.06 for the shim (a tie under the < 2 convention);
# the ENSO ocean slope 0.89x GCB (r 0.28); gate S 0.280 @ 8.96 PASS; chain H / GL / Q
# FAIL, 7 PASS unchanged; GATE V z -4.60 (the limb does not buy the variance either).
# Hessian PD cond 2.40e5, NO unstable direction (h_ml 57.3 +/- 3.65 -- the ridge's
# Laplace sd, understated). By prereg 09-17 k s4's letter the fitted value is the
# REFUTED branch (below the bracket); adopted on Marcus's ruling (09-20: "Adopt the
# limb") -- a mechanism at the edge of its observed range at AIC parity over two
# unphysical coefficients. hilda30s is retired to CCX_MODE_HILDA30S_QUARANTINED.
# ⛔ THE AIC GATE: the control hilda31pe (31 names, -1387.7128) leads by 4.09 at two
# extra names -> dAIC = 2*2 - 2*4.09 = -4.18 -> +4.18 for the control: STILL a NAMED RED.
# 2026-10-01 (c): `hilda33d` -- OBJECTIVE #14, D2 + D3 FITTED (Marcus 2026-10-01: "name,
# register, and adopt", conditional on (1) an improvement and (2) no other quick improvement;
# both assessed in CHANGELOG 10-01 c). Label hilda_csl3v0kaidgb = hilda_csl3 with the
# vegetation-capacity loop OFF (phi = 0), the fert_k shape prior, aod_mode anomaly, the inert
# soil carve-out (0-1 m), and the GATE OPEN: N retention (ndep_ret 10.19, 7.0 kg C per kg N),
# greening (npp_tsens -0.0079 +/- 0.0083 /K) and the GCB-imbalance shares (land 0.593, ocean
# 0.085) fitted. 33 names, the SAME 9 pins. 24/24 starts CONVERGED (multistart_20260930q, Mac);
# best -1405.249036, likelihood -1369.1761 on 26 rows; Hessian PD cond 1.7e6.
# ⚠ #14 IS NOT #13: compare on the 24 rows both objectives share (the two GCB sink rows' targets
# move with the shares). There: -1308.60 vs hilda29l -1319.32 (+10.71 at 4 more names, dAIC
# -13.4), vs the control hilda31pe -1313.28 (+4.68 at 2 more, dAIC -5.35: the AIC red, judged on
# the shared rows, TURNS). D4 stays a NAMED TENSION (modern NPP 67.7 vs 56.1 +/- 7.75, z +1.50),
# read EXCLUDING the N-retention flux (Marcus 10-01, review 10-01c B1: "Do the recommendation"),
# with +0.50 GtC/yr retained via N deposition (gross, 2001-2023) quoted beside it.
# Consumers: a mode file under this label opens the gate through its pins (ccx_mode_pins()).
# hilda29l stays REGISTERED (the v1.0-hilda29l product's mode, and #13's limb canonical).
# 2026-10-03 (h): `hilda34g` -- OBJECTIVE #15 WITH THE LAND ENSO LAG FITTED (Marcus 2026-10-03:
# "Adopt the lag arm (Recommended)", "Keep label; mode hilda34g (Recommended)", "Keep
# backward-difference Hermite (Recommended)"). Label hilda_csl3v0kaidgbe = hilda_csl3v0kaidgb +
# the lag gate (enso_lag_free = 1): lag_enso_land = DESIGN's L_MEI, 2.644 +/- 0.387 months; the
# land ENSO term reads Nino 3.4 that much later, the ocean stays on time. Objective #15 = #14 +
# ice-core CO2 cut to pre-1958 + the Law Dome ice d13C row + the cited k_w / tau_ex priors. 34
# names, the SAME 9 pins. The 10-02 ee Mac wave: 21/24 CONVERGED, one basin up to the h_ml ridge;
# best id 4, logpost -1182.991369, likelihood -1143.2508 on 27 rows; Hessian PD cond 1.6e6.
# ⭐ ON LIKELIHOOD vs the lag-0 control refit on #15 (refit_20261003_obj15_hilda_csl3v0kaidgb,
# NOT registered): +14.92 at one more name, dAIC -27.8. Every What-if gain is the lag's (ENSO
# off: -11.0 % here, +0.89 % at the control); gate V slightly worse (-4.60 vs -4.34). CHANGELOG
# 10-03 (b)-(h). hilda33d stays REGISTERED (the #14 canonical, restamped #15; the D2/D3 parent).
CCX_MODE_CANONICAL <- "hilda34g"
# 2026-09-22 (k): `hilda32f` -- THE FREE PARENT OF THE LIMB CANONICAL (Marcus: "Repoint").
# hilda29l's OWN structure (hilda_csl3, seas_ml 1) with only the six inert names held: the
# seasonal shim ent_seas_amp_SH (8.24), the ocean ENSO pair (NH 0.240, SH 0.001) and the
# limb's w_enso_l2 (7.73) all FITTED, 32 names. The 09-21 Mac wave (24/24 converged, 17 on
# this basin), promoted from id 15 (gates 3-5, gap 6e-8, 0 kinks); Hessian PD cond 2.46e5,
# one direction unstable at the derived step (gamma_enso_ocn_SH, at ~0). Likelihood
# -1386.1015 on 26 rows = THE BEST FREE ARM (the control -1387.7128, +1.61; dAIC -1.22);
# the canonical's three pins cost 5.70 against it (dAIC +5.41 -- AIC does not buy the pins;
# the canonical is the pinned arm by RULING, the limb's physicality over the shim's fit:
# with the pair free the limb halves and the NH shim takes 0.24, one observable two
# carriers). It REPLACES hilda31s2 as CCX_MODE_PINNED_PARENT (a `hilda` fit never refit
# under hilda_c / #13, -1411.24 rescored; stays registered as provenance). test-mode-file's
# named red #1 ("the parent is the best free arm") discharges here; red #2 (the AIC gate)
# is untouched.
CCX_MODE_FILES <- c(
  hilda34g = file.path("calibration", "output", "refit_20261003_hilda34g_obj15_hilda_csl3v0kaidgbe",
                       "mode_fit_pumpN.rds"),
  hilda33d = file.path("calibration", "output", "refit_20261001_hilda33d_obj14_hilda_csl3v0kaidgb",
                       "mode_fit_pumpN.rds"),
  hilda29l = file.path("calibration", "output", "refit_20260920_hilda29l_obj13_hilda_csl3",
                       "mode_fit_pumpN.rds"),
  hilda32f = file.path("calibration", "output", "refit_20260922_hilda32f_obj13_hilda_csl3_free_parent",
                       "mode_fit_pumpN.rds"),
  hilda31s2 = file.path("calibration", "output", "refit_20260912_hilda31_seasml1_round7",
                        "mode_fit_pumpN.rds"),
  hilda31pe = file.path("calibration", "output", "refit_20260919_hilda31pe_obj13_hilda_c_seasml0",
                        "mode_fit_pumpN.rds")
)
# THE seas_ml = 0 CONTROL, by name: the diagnostics that compare the seasonal
# mixed layer ON vs OFF read the OFF arm here rather than through the default
# ccx_mode_file(), which from 09-11 (8) is the ON arm.
# 2026-09-19 (j): `hilda31pe` -- the CONTROL's arm (hilda_c, seas_ml 0, the six inert
# pins + w_enso_l2 = 0, the shim FREE at 18.02, 31 names) REFITTED under objective #13
# (wave id 11; 24/24 CONVERGED onto one basin, 16 starts). logpost -1425.015625,
# streams -1387.7128 on 26 rows; the slope 0.94x GCB through gamma_enso_ocn_NH 0.34
# -> 0.42 / SH 0.02 -> 0.06; h_ml 49.49 +/- 2.04; Hessian PD cond 2.45e5. Registered
# on ruling 2 (09-19 b): the refit control REPLACES the stale hilda31p (on `hilda`,
# never refit under hilda_c -- the staleness that manufactured "+11.60"), and the
# gate it fails stays a NAMED RED rather than being re-ruled to pass.
CCX_MODE_SEASML0_CONTROL <- "hilda31pe"

# THE COLUMN CONTROL. `ent26` (26 parameters, no structure) is retired from the
# registry -- it is not a mode of this space -- but it stays the like-for-like
# COLUMN comparison every HILDA-arc diagnostic scores against. It is resolved
# by PATH (ccx_mode_file() accepts one), migrated on load, and its absent
# `struct` means "" = the column, which is exactly what it was.
CCX_MODE_COLUMN_CONTROL <- file.path("calibration", "output", "quarantine",
                                     "20260908_hilda31_adopted", "refit_20260903_ent26",
                                     "mode_fit_pumpN.rds")

# THE PRE-ADOPTION HILDA CONTROL (2026-09-10). `hilda31` is retired from the
# registry -- its stored logpost is in the ASEASONAL objective's units and may
# not sit beside `hilda31p`'s -- but it is the point Ruling A's demean flag was
# RATIFIED at (43.8367, aseasonal) and where the adoption's apparent re-pricing
# (63.7282) was measured; both stay asserted from this path by
# test-enso-demean.R, as facts about THIS file and not about the canonical.
CCX_MODE_HILDA31_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                          "20260910_periodic_spinup_adopted",
                                          "refit_20260908_hilda31", "mode_fit_pumpN.rds")

# THE 09-11 SEASONAL-ML CANONICAL (2026-09-13). `hilda31s` is retired from the
# registry -- its stored streams are the 09-11 objective's, restamped twice --
# but it is the file the round-6b P7 record and the 09-12 evaluation were read
# at, and stays resolvable by path for any like-for-like read against them.
CCX_MODE_HILDA31S_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260913_round7_adopted",
                                           "refit_20260911_hilda31_seasml1", "mode_fit_pumpN.rds")

# THE PRE-HYGIENE-BATCH CANONICAL (2026-09-17 h). `hilda30c` is retired from the
# registry -- it is a mode of the `hilda` structure under objective #11, restamped
# (not refit) under #12, and the canonical is now on `hilda_c` -- but it is the
# point every 09-13 -> 09-16 read was taken at (the O1/O5/O6/k_w probes, the
# whole-model review, the batch's own pricing) and stays resolvable by path for a
# like-for-like read against them. Its stored streams are objective #12's.
CCX_MODE_HILDA30C_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260917_hilda30h_adopted",
                                           "refit_20260913_hilda30_cprime_pin_ent0", "mode_fit_pumpN.rds")

# THE PRE-#13 CANONICAL AND CONTROL (2026-09-19 j). `hilda30h` (canonical 09-17 i ->
# 09-19, #13-RESTAMPED, not refit) and `hilda31p` (the seas_ml-0 control 09-10 ->
# 09-19, a `hilda` mode restamped through four objectives) are retired from the
# registry but stay resolvable by path: every 09-17 i -> 09-19 i read was taken at
# one of them. Their stored streams are objective #13's (the 09-18 e restamp).
CCX_MODE_HILDA30H_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260919_hilda30e_adopted",
                                           "refit_20260917_hilda30h_obj12_hilda_c", "mode_fit_pumpN.rds")
CCX_MODE_HILDA31P_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260919_hilda30e_adopted",
                                           "refit_20260910_hilda31_periodic", "mode_fit_pumpN.rds")
# THE hilda_c CANONICAL (2026-09-20 o). `hilda30e` (09-19 j -> 09-20; the ML cycling
# in BOTH hemispheres) is retired but resolvable by path: the 09-19 h -> 09-20 n reads
# were taken at it, and it is the like-for-like "NH cycle on" arm of hilda30s.
CCX_MODE_HILDA30E_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260920_hilda30s_adopted",
                                           "refit_20260919_hilda30e_obj13_hilda_c", "mode_fit_pumpN.rds")
# THE hilda_cs CANONICAL WITH THE SHIM (2026-09-20 r). `hilda30s` (09-20 o -> r) is retired
# but resolvable by path: the like-for-like "shim" arm of hilda29l (the same structure less
# the limb, the ocean ENSO pair fitted), and the point of the 09-20 (o)-(q) reads.
CCX_MODE_HILDA30S_QUARANTINED <- file.path("calibration", "output", "quarantine",
                                           "20260920_hilda29l_adopted",
                                           "refit_20260920_hilda30s_obj13_hilda_cs", "mode_fit_pumpN.rds")

# WHICH ARMS ARE PINNED -- AND WHY THE STORED logpost IS A TRAP ACROSS THEM.
# A stored logpost is a number in the units of the objective that produced it,
# and a PINNED arm's objective is not a free arm's: compare PINNED vs FREE on
# LIKELIHOOD (the stream rows), never on the stored value.
#
# WHAT A PIN IS (2026-09-13, ccx_apply_pins in R/calibrate.R): a fitted name
# REMOVED from the fitted set and HELD at a stated value in the base list. It has
# NO prior term and NO Jacobian for the held name, so the pinned objective is
# the full objective's conditional slice at the pinned value minus the held
# name's own prior -- a constant, which is exactly why the stored logposts of a
# pinned and a free arm are in different units. The file records `pins`;
# ccx_mode_base() carries the value; ccx_mode_pins() reads it.
#
# WHAT A PIN IS NOT: `pin90` (2026-08, retired). That was a near-delta PRIOR on
# `fert_k`, worth +11.6698 at fert_k = 90; its stored logpost -1544.50 read
# HIGHER than the then-canonical -1544.615 and was 11.56 BELOW on the comparable
# scale. The trap is the same in both cases -- a stored number never decides an
# arm -- but a real pin has no prior credit to subtract; it has a likelihood
# price to measure (test-mode-file measures it and prints it).
#
# 2026-09-04 -> 2026-09-11 (8) this registry held one arm, then two free arms;
# the free-vs-pinned comparison it exists to express had no power
# ([[no_power_null]]). It has power from 09-13 (d): the canonical is PINNED.
CCX_MODE_PINNED <- c(hilda34g = TRUE, hilda33d = TRUE, hilda29l = TRUE, hilda32f = FALSE, hilda31s2 = FALSE, hilda31pe = FALSE)
# A PINNED CANONICAL (2026-09-13). When the canonical is a pinned arm, the
# registry names WHAT it pins (the file's own `pins` must agree -- test-mode-file)
# and its free PARENT: the same space with the pinned names free, kept
# registered because the pinned arm's meaning is its LIKELIHOOD price against
# that file. Both NULL while the canonical is free. The pin is a
# RETIREMENT-IN-WAITING: `ent_seas_amp_SH` leaves the table only once the
# seas_ml 0 control can be scored without it.
# 2026-09-17 (h): the shim pin + the six names INERT under hilda_c / the solved
# field. They are pinned so that the fitted set is the canonical's 30 (the
# driver refuses a free w_eq/gamma_eq without the cell); their values are the
# table's off-state / prior centres and move nothing in the model.
# 2026-09-19 (j): + the layer-2 limb's `w_enso_l2` at 0 -- absent under hilda_c
# (k_l2 = 0), pinned so the ENSO-seeded starts and the encoder never see a free
# name the structure does not read (the 09-17 l seed defect). Eight pins, 30 free.
# 2026-09-20 (r): the canonical is the LIMB arm -- w_enso_l2 is FITTED (dropped from the pins)
# and the ocean ENSO shim pair gamma_enso_ocn_NH/SH is PINNED at 0 (the limb replaces it).
# Nine pins, 29 free. The CONTROL's pins are named EXPLICITLY below (no longer "the canonical's
# minus the shim"): the control has no limb, so it holds w_enso_l2 = 0 and FITS the pair.
CCX_MODE_CANONICAL_PINS  <- c(ent_seas_amp_SH = 0, w_eq = 27, gamma_eq = 1, pump_export = 9.08,
                              w_vent = 0, gamma_vent = 0, w_thc = 0,
                              gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0)
# ⚠ RE-DOCUMENTED 2026-10-01 (Marcus, review 10-01c B3b: option (i), "follow recommendations").
# `hilda32f` is the free parent of the v1.0 canonical, hilda29l (structure hilda_csl3,
# objective #13). It is NOT a parent of the current canonical: hilda33d (objective #14, the
# D2/D3 label hilda_csl3v0kaidgb) has NO registered free parent, and none is being fitted
# (a #14 free-parent wave, ~36 names, would be option (ii), not ruled). What that means for
# the readers of this constant:
#   - test-mode-file's (b) ranks #13 arms only, and its printed "parent price" (5.70 at
#     hilda29l) is a #13 number -- it does not price hilda33d's pins;
#   - ccx_mode_free_name() returns it whenever the canonical is pinned, which is fine for
#     fixtures (a 31-name vector encodable on the full table), not for a comparison;
#   - ccx_ms_reference_set() would seed any FUTURE free wave from it: a #14 wave must name
#     its own reference set.
# 2026-10-03 (h): the same holds for the canonical hilda34g (objective #15, the lag label
# hilda_csl3v0kaidgbe): no registered free parent; its comparison arm is the lag-0 control
# refit on #15 (unregistered), read in calibration/diag_obj15_refit_read.R.
CCX_MODE_PINNED_PARENT   <- "hilda32f"   # 2026-09-22 (k): hilda29l's (v1.0's) free parent; the canonicals hilda33d / hilda34g have none (10-01 B3b; 10-03 h)
# THE seas_ml-0 CONTROL AND ITS ARM (2026-09-17 j). The registered control `hilda31p`
# has the shim FREE (18.69): the seasonal mixed layer is what REPLACED the shim, so
# the canonical pins it and the control keeps it. Its arm is therefore the canonical's
# INERT pins WITHOUT the shim pin (31 free). ⛔ A control with the shim pinned AND the
# ML off has no mechanism for the SPO seasonal amplitude at all -- measured at
# hilda31p's point: -368 on co2_seasonal_SPO by construction -- and "the canonical
# beats it" would have no power on the seasonal question ([[no_power_null]]). An
# array under these pins at seas_ml 0 takes the control as its incumbent
# (ccx_ms_reference_set); at seas_ml 1 it is the free parent's arm.
# (The control's NAME is CCX_MODE_SEASML0_CONTROL above -- one name, not two; a duplicate
# CCX_MODE_CONTROL lived here for a morning on 09-17 j.)
CCX_MODE_CONTROL_PINS    <- c(w_eq = 27, gamma_eq = 1, pump_export = 9.08, w_vent = 0, gamma_vent = 0, w_thc = 0,
                              w_enso_l2 = 0)     # hilda31pe's file: the six inert + the limb's name held OFF; shim and pair FREE
# THE FREE PARENT OF THE LIMB CANONICAL (2026-09-21 g; Marcus: "follow the recommendations" --
# the stale-parent red). hilda29l holds NINE pins; its free parent is hilda29l's OWN structure
# (hilda_csl3, seas_ml 1) with only the SIX INERT names held -- the seasonal shim, the ocean ENSO
# pair AND the limb's w_enso_l2 all FITTED (31 names). It prices the canonical's three real pins
# under the live structure and objective, which the registered parent hilda31s2 (a `hilda` fit,
# never refit under hilda_c / #13) cannot. Reference set: incumbent the canonical (its three
# held names seeded from the table init, as the csl3 wave seeded w_enso_l2), new basin the
# control (w_enso_l2 seeded). ONLY under a structure WITH the limb at seas_ml 1.
CCX_MODE_FREE_PARENT_PINS <- c(w_eq = 27, gamma_eq = 1, pump_export = 9.08, w_vent = 0, gamma_vent = 0, w_thc = 0)
# THE LAYER-2 LIMB'S ARM (2026-09-17 k, prereg notes/prereg_2026-09-17k_l2_enso_limb_refit.md
# s4 PA): the canonical's 7 pins PLUS the ocean ENSO shim `gamma_enso_ocn_NH/SH` held at 0
# (29 free + w_enso_l2 = 29 fitted names), under a structure WITH the limb (k_l2 > 0:
# `hilda_cl2`, or a sibling label at another return layer) at seas_ml 1. The limb
# REPLACES the shim, so the shim is pinned OFF and the limb's one name is fitted.
# An array under these pins takes the canonical as its incumbent (the canonical's own
# point with the shim zeroed and w_enso_l2 seeded at the table init -- a start, not a
# mode of the arm) and the seas_ml-0 control as its new basin, likewise
# (ccx_ms_reference_set). Under a structure WITHOUT the limb these pins are an
# UNRULED arm (the shim off and nothing in its place) and are refused.
# (2026-09-19 j: the canonical's pins now hold `w_enso_l2` at 0; the limb's arm FITS
# that name, so it is dropped from the pin set here -- the limb's 9 pins are unchanged.)
# (2026-09-20 r: the limb's arm IS the canonical's now; kept as a name so the 09-17/18/20 array
# records and ccx_ms_reference_set()'s limb branch read unchanged -- identical to CANONICAL_PINS.)
CCX_MODE_L2_ARM_PINS     <- CCX_MODE_CANONICAL_PINS
#' The registered FREE mode nearest the canonical: the canonical itself when it
#' is free, its parent when it is pinned. For a consumer that needs a vector
#' ENCODABLE on the full table (an ancestor constructed by dropping names, a
#' template for a 31-name start) -- a pinned canonical's held name is 0 under
#' `tr = "log"` and cannot be encoded without its pins.
ccx_mode_free_name <- function() {
  if (isTRUE(CCX_MODE_PINNED[[CCX_MODE_CANONICAL]])) CCX_MODE_PINNED_PARENT else CCX_MODE_CANONICAL
}

# The retired names, kept ONLY so that asking for one gets the reason rather
# than a file-not-found. Everything here is quarantined and not comparable.
#
# EACH ENTRY CARRIES ITS OWN CAUSE AND ITS OWN QUARANTINE PATH, and that is not
# decoration. Until 2026-08-28 the reason lived in ccx_mode_file()'s error
# string as ONE hardcoded sentence -- the 2026-08-25f isotope fix (`6bda464`),
# quarantined under 20260825_seas_isotope_rectification/ -- which was correct
# while every retired arm had been retired by that one change. The project has
# since had a SECOND objective change (option 5, sigma-inflation, 2026-08-28),
# so the shared sentence would have told a reader the wrong cause and pointed
# at the wrong directory for anything retired by it. A registry whose entries
# cannot express why they are here has to be edited under pressure the first
# time a second reason exists; this one is a one-line addition instead.
CCX_MODE_RETIRED <- c(
  N   = paste("arm N of the 2026-08-18/20 pump refit, retired by the 2026-08-25f",
              "seasonal-NEP isotope fix (`6bda464`), which changed the objective.",
              "Quarantined under",
              "calibration/output/quarantine/20260825_seas_isotope_rectification/"),
  D   = paste("arm D of the 2026-08-18 pump refit, retired by the 2026-08-25f",
              "seasonal-NEP isotope fix (`6bda464`), which changed the objective.",
              "Quarantined under",
              "calibration/output/quarantine/20260825_seas_isotope_rectification/"),
  ref = paste("the ABANDONED reference arm of refit_20260825f (its mode file is the",
              "PRE-FIX SEED, not a result), retired by the 2026-08-25f seasonal-NEP",
              "isotope fix (`6bda464`), which changed the objective. Quarantined under",
              "calibration/output/quarantine/20260825_seas_isotope_rectification/"),
  from90 = paste("the FREE arm of refit_20260825f and the canonical mode from 2026-08-26",
              "to 2026-09-04, a TWENTY-ONE-parameter vector. Retired by the",
              "2026-09-03 freeing of `ent_seas_amp_SH` (`88ee23c`), the last of",
              "three splits that took the fitted set 21 -> 22 -> 25 -> 26. It is",
              "not a mode of this space: `ccx_migrate_par_set()` can say what it",
              "RAN, but under `tr = \"log\"` its own state has prior probability",
              "ZERO and cannot be encoded at all. Quarantined under",
              "calibration/output/quarantine/20260903_ent26_adopted/"),
  pin90  = paste("the fert_k-PINNED comparison arm of refit_20260825f, retired by the",
              "same 2026-09-03 freeing of `ent_seas_amp_SH` (`88ee23c`) and equally",
              "not a mode of this space. Its +11.6698 near-delta prior credit was",
              "never an observational or physical quantity -- it is the value of a",
              "prior this project chose, at a fert_k this project chose -- so it is",
              "NOT preserved here; a pinned comparison needs a new 26-parameter",
              "pinned refit. Quarantined under",
              "calibration/output/quarantine/20260903_ent26_adopted/"),
  ent26  = paste("the 26-parameter COLUMN canonical from 2026-09-04 to 2026-09-08,",
              "retired by the HILDA refit's parameter set (kz_deep_frac, hs_asx_frac,",
              "h_hs, pump_hs_gcm2, u_hs: 26 -> 31; `81d164c`, `d65b299`) and the",
              "adoption of the round-5 winner as `hilda31`. Not a mode of this space",
              "and fitted under NO structure. It remains the like-for-like COLUMN",
              "CONTROL, resolvable by path as CCX_MODE_COLUMN_CONTROL. Quarantined under",
              "calibration/output/quarantine/20260908_hilda31_adopted/"),
  hilda31 = paste("the 31-parameter HILDA canonical from 2026-09-08f to 2026-09-10, fitted",
              "under the ASEASONAL spinup and the pre-09-09w priors. Retired by the",
              "adoption of the PERIODIC spinup as the objective's (`50f0105`, 09-09x,",
              "Marcus's ruling) and the refit under it, promoted as `hilda31p`. SUPERSEDED,",
              "not defective: its stored logpost -1478.66 is in another objective's units",
              "and beats -1480.54 only on paper; re-scored like-for-like it is -1489.63,",
              "9.088 behind. Still the pre-adoption control, resolvable by path as",
              "CCX_MODE_HILDA31_QUARANTINED. Quarantined under",
              "calibration/output/quarantine/20260910_periodic_spinup_adopted/"),
  hilda31s = paste("the 31-parameter HILDA / seas_ml 1 canonical from 2026-09-11 (8) to",
              "2026-09-13, fitted under the 09-11 objective and RESTAMPED twice on 09-12",
              "(-1475.46 -> -1453.36 -> -1432.25; annual-mean isotope pins, row-read",
              "concentrations, IntCal to 1941, no pre-run ice rows, observed-month D14C",
              "edge years). Retired by the ROUND-7 refit under that objective, promoted as",
              "`hilda31s2` (`9bc7031`; -1423.5675, +8.68, same h_ml). SUPERSEDED, not defective. Still",
              "resolvable by path as CCX_MODE_HILDA31S_QUARANTINED. Quarantined under",
              "calibration/output/quarantine/20260913_round7_adopted/")
)

#' Absolute path to a fitted mode file, by name
#'
#' @param mode one of `names(CCX_MODE_FILES)`, or an existing path (returned
#'   unchanged, so callers can point a diagnostic at any arm on the command
#'   line without going around this function).
ccx_mode_file <- function(mode = CCX_MODE_CANONICAL) {
  if (length(mode) != 1L || !is.character(mode))
    stop("ccx_mode_file() takes ONE mode name or path; got ",
         class(mode)[1], " of length ", length(mode), ".")
  if (file.exists(mode)) return(mode)
  if (mode %in% names(CCX_MODE_FILES)) return(ccx_path(CCX_MODE_FILES[[mode]]))
  if (mode %in% names(CCX_MODE_RETIRED))
    stop("mode '", mode, "' is RETIRED: ", CCX_MODE_RETIRED[[mode]],
         ". It is NOT comparable with anything fitted since. The canonical mode ",
         "is '", CCX_MODE_CANONICAL, "'; see ccx_mode_file().")
  stop("unknown mode '", mode, "': expected a path, or one of ",
       paste(sprintf("'%s'", names(CCX_MODE_FILES)), collapse = ", "), ".")
}

# =====================================================================
# DECODING A MODE FILE — `u_mode` IS MEANINGLESS WITHOUT ITS BAND (2026-08-28)
#
# THE DEFECT THIS EXISTS TO KILL. `h_ml` is transformed with a LOGIT onto
# [lo, hi], and the pump refits override that band IN PROCESS
# (`run_modefind_pump_arms.R`, `recompute_hessian.R:112-113` both set
# `CCX_PARAM_TABLE$h_ml$lo/hi <- md$hml_bound`). The band is a property of the
# REFIT, not of the model, so `R/calibrate.R` is deliberately left alone — but
# that means the SAME `u_mode` decodes to a DIFFERENT `h_ml` depending on which
# band is in force, and `ccx_unc_to_par()` is a pure function of the SHIPPED
# table and cannot know. At the canonical mode:
#
#     ccx_unc_to_par(md$u_mode)$h_ml   85.7292 m   <- shipped [30, 200]
#     md$par_mode[["h_ml"]]            96.4737 m   <- what the refit FOUND
#
# an 11.1 % error. `h_ml` was the ONLY one of the 21 that moved -- ⚠ NO LONGER
# TRUE since 2026-08-31c: `CCX_WIDEN_PARAMS` lets the refit override `kz`'s
# bracket too, and the driver records it as `kz_bracket`. The recorded-band
# fields are listed ONCE in CCX_MODE_BAND_FIELDS below so a third one cannot
# be recorded-but-never-restored the way `kz_bracket` was for a day. Every
# diagnostic using the standard `pv <- ccx_unc_to_par(md$u_mode)` idiom has
# been running an 11 % shallower mixed layer than the mode it names. It also
# accounts for most of the long-standing "the mode's logpost is not
# reproducible" offset: decoding under the recorded band takes it from
# -3.3223 to -1.5805, and -1.5805 is exactly the narrowed-prior constant the
# bounded refit adds. [[ccx_hml_band_provenance]] [[ccx_mode_logpost_offset]]
#
# ⚠ A MATCHED CONTRAST BETWEEN ARMS OF ONE DRIVER SURVIVES THIS — every arm
# shares the same wrong `h_ml`, so differences are unaffected. What does NOT
# survive is any ABSOLUTE quantity, and any cross-session "reproduces the
# earlier control values" check: those agree because the sessions share the
# defect, not because the value is right. [[mutation_test_gates]]

# WHICH FIELDS OF A MODE FILE RECORD AN OVERRIDDEN BRACKET, in one place.
# ⚠ ADD A PARAMETER HERE THE SAME DAY THE DRIVER LEARNS TO OVERRIDE IT. The
# `kz_bracket` field was WRITTEN by run_modefind_pump_arms.R from 2026-08-16 and
# CONSUMED by nothing until 2026-08-31c -- invisible for the whole of that time
# because every file's `kz_bracket` happened to equal the shipped table, so the
# missing restore could not produce a wrong number until a run finally widened
# it ([[default_off_hides_the_bug]]: a mechanism that is off by default is
# untested exactly where it matters).
CCX_MODE_BAND_FIELDS <- c(h_ml = "hml_bound", kz = "kz_bracket")

#' The parameter brackets a mode file records having been fitted under
#'
#' @param md a loaded mode file
#' @return named list of `c(lo, hi)`, one per recorded-and-present field
#' @keywords internal
ccx_mode_bands <- function(md) {
  out <- list()
  for (nm in names(CCX_MODE_BAND_FIELDS)) {
    v <- md[[CCX_MODE_BAND_FIELDS[[nm]]]]
    if (is.null(v)) next
    if (!is.numeric(v) || length(v) != 2L || any(!is.finite(v)) || v[1] >= v[2])
      stop("mode file's ", CCX_MODE_BAND_FIELDS[[nm]], " is not a finite [lo, hi] pair")
    out[[nm]] <- v
  }
  out
}

#' Parameters at a fitted mode, decoded under the band that FOUND it
#'
#' Use this instead of `ccx_unc_to_par(md$u_mode)` whenever the parameters are
#' meant to BE the mode. Returns the refit's own `par_mode` when present, which
#' is already correct by construction, and otherwise falls back to decoding
#' `u_mode` under `md$hml_bound` if that is recorded.
#'
#' @param md a loaded mode file, or a mode name/path for `ccx_mode_file()`
#' The STRUCTURE a mode file was fitted under, and the base list it needs
#'
#' `struct` is recorded by run_dispersed_multistart.R (from 2026-09-08f) and
#' carried by promote_multistart_mode.R; a file without it was fitted under no
#' structure ("" = the 32-box column), which is what every pre-09-08f file was.
#' `ccx_mode_base()` is the ONE place a consumer turns a mode file into the
#' base parameter list -- the precedent is `pump_mode`, which every consumer
#' already carries out of the file by hand; `struct` is the same kind of thing.
ccx_mode_struct <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$struct)) "" else md$struct
}
#' `seas_ml` is recorded by run_dispersed_multistart.R from 2026-09-10 on and
#' carried by promote_multistart_mode.R. A file without it was fitted with the
#' seasonal mixed layer OFF -- which is a FACT about every earlier file (the
#' driver had no way to switch it on until 09-10, [[ccx_refit_ran_at_seas_ml_0]]),
#' not a default being trusted. `hilda31` and the 09-10 `hilda31p` are both 0.
ccx_mode_seas_ml <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$seas_ml)) 0L else ccx_parse_seas_ml(md$seas_ml)
}
#' The SPINUP a mode file's `streams` and `logpost` were computed under. Recorded
#' by promote_multistart_mode.R from 2026-09-10 on; an absent field means the
#' aseasonal `ccx_spinup` -- a FACT about every file promoted before 09-09x's
#' adoption, not a default (the one post-adoption file promoted without the
#' field, `hilda31p`, had it stamped in by calibration/stamp_mode_spinup.R after
#' GATE 5 had already proved its streams periodic).
ccx_mode_spinup <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$spinup)) "aseasonal" else md$spinup
}
#' The pump field's construction a mode file was fitted under (option D + E,
#' 2026-09-14 h). A file without the field was fitted with the SOLVED field --
#' a FACT about every file promoted before 09-14 h (no other field existed),
#' not a default being trusted.
ccx_mode_pump_field <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$pump_field)) "solved" else ccx_parse_pump_field(md$pump_field)
}
ccx_mode_base <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  p <- ccx_apply_structure(ccx_default_params(), ccx_mode_struct(md),
                           seas_ml = ccx_mode_seas_ml(md),
                           pump_field = ccx_mode_pump_field(md))
  # PINNED arms (2026-09-13): the held values live in the BASE, by the file's own
  # record; a consumer that wants to SCORE such a file must also ccx_apply_pins()
  # first, or ccx_par_to_unc() will look for a name the fit never carried.
  for (n in names(md$pins)) p[[n]] <- md$pins[[n]]
  # ... and the base CARRIES the pins as an attribute, so the canonical idiom
  # `ccx_overlay_par(ccx_mode_base(md), md$par_mode)` (lint-enforced) can tell a
  # HELD name from an ABSENT one without every caller repeating it.
  if (length(md$pins)) attr(p, "pins") <- md$pins
  p
}
#' Is a mode file a PINNED arm -- does it hold a name its own structure / pump field
#' READS? (2026-09-19 m.) A file whose pins are all INERT (ccx_inert_names: the six
#' unread names + the limb's, under hilda_c / solved) is a FREE arm of the reduced
#' space: nothing the objective sees is held, its likelihood is the free arm's, and
#' CCX_MODE_PINNED says FALSE for it (hilda31pe: seven inert pins, the shim fitted).
#' The canonical hilda30e holds the shim, which the model reads -- PINNED. test-mode-file
#' compares this to CCX_MODE_PINNED; a consumer still APPLIES a file's pins to encode it.
ccx_mode_pinned <- function(md) {
  pins <- ccx_mode_pins(md)
  if (is.null(pins) || !length(pins)) return(FALSE)
  inert <- ccx_inert_names(ccx_mode_pump_field(md), ccx_mode_struct(md))
  any(!names(pins) %in% inert)
}
#' The pins a mode file was fitted under (NULL = a free arm). Read, never inferred.
#' The file's FIT DIAGNOSTICS: the Hessian at the mode and what derives from it
#'
#' ⚠ THE SIGN CONVENTION IS THE POINT OF THIS ACCESSOR. `md$hessian` is the
#' Hessian of the LOG-POSTERIOR, so it is NEGATIVE definite and the PRECISION
#' matrix is its negation. Discovered by experiment on 2026-09-25 -- the first
#' attempt at the constraint map took `1/sqrt(diag(md$hessian))` and got NaN for
#' all 29 names -- and now stated once, here, rather than rediscovered.
#'
#' `sd` is the MARGINAL standard deviation, `sqrt(diag(solve(-H)))`, which is
#' what the file already stores as `sd_unc`. ⛔ It is NOT the right step for a
#' ONE-AT-A-TIME perturbation: it already contains the compensation the other
#' parameters supply, so moving one parameter that far alone leaves the
#' quadratic bowl (measured: marginal/conditional reaches 92, and the predicted
#' drop 4235 log-units). For that, use `sd_conditional = 1/sqrt(diag(-H))`,
#' which costs every coordinate the same 0.5 log-units.
#'
#' ⚠ Exists so that consumers which need the FIT's statistics -- and not a
#' parameter list, so `ccx_mode_base()` would be meaningless to them -- do not
#' have to `readRDS(ccx_mode_file())` by hand. That read is what
#' test-mode-struct-lint.R ratchets down, and satisfying that lint by calling
#' `ccx_mode_base()` for a list nobody uses would be gaming it.
ccx_mode_fit_stats <- function(md = CCX_MODE_CANONICAL) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  negH <- -md$hessian
  list(hessian = md$hessian, precision = negH,
       sd = md$sd_unc, sd_conditional = 1 / sqrt(diag(negH)),
       cov = md$cov, pd = md$pd, eigen = md$eigen,
       param_names = md$param_names, logpost = md$logpost)
}

ccx_mode_pins <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  p <- md$pins
  # THE GATE RIDES WITH THE PINS (2026-10-01): a file fitted under a structure that OPENS it
  # (R/calibrate.R CCX_PARAM_GATED) fits four more names, and ccx_apply_pins() of these pins applies
  # the gate first. An attribute, so names / values / ccx_pin_label() are unchanged.
  # ANY gate since 2026-10-02 (CCX_PARAM_GATES: the lag gate too); ccx_apply_gate() opens them all.
  if (length(ccx_gates_open(ccx_mode_struct(md)))) {
    if (is.null(p)) p <- stats::setNames(numeric(0), character(0))
    attr(p, "gate_struct") <- ccx_mode_struct(md)
  }
  p
}
#' The file's `par_mode` with its PINNED names filled in from `pins` (2026-09-13).
#'
#' A pinned name is HELD, not ABSENT. `ccx_migrate_par_set()` tests absence
#' against the build's full table, so a 30-name pinned `par_mode` handed to it
#' under the 31-name table would be MIGRATED: the absence contract for
#' `ent_seas_amp_SH` fills 0 (the pre-09-03 meaning) and flags the file
#' "MIGRATED 30->31" -- which for C' happens to be the pinned value, and for any
#' other pin would be WRONG. Every consumer that overlays a mode file's vector on
#' a model list (dg_vector, sl_overlay, the scorecard's extra arm) goes through
#' this, so the held value comes from the file's own record and the migration
#' sees nothing absent. ⚠ The result is NOT encodable on the reduced space (it
#' carries the held name); to ENCODE, ccx_apply_pins(ccx_mode_pins(md)) first and
#' hand ccx_par_to_unc() the bare `md$par_mode`.
ccx_mode_par_with_pins <- function(md) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  pm <- md$par_mode
  for (n in names(md$pins)) {
    if (!is.null(pm[[n]]) && !isTRUE(all.equal(pm[[n]], md$pins[[n]])))
      stop("ccx_mode_par_with_pins(): `par_mode` carries ", n, " = ", pm[[n]],
           " but the file pins it at ", md$pins[[n]], " -- the file is internally inconsistent.")
    pm[[n]] <- md$pins[[n]]
  }
  # the names the FILE held, carried so a consumer that FITS one of them (an arm whose
  # pins are not the file's -- the limb's arm at a canonical that holds w_enso_l2 = 0,
  # 2026-09-20 o) can seed an unencodable held value instead of dying on it
  attr(pm, "held_by_file") <- names(md$pins)
  pm
}

#' The model list a RUN uses, from a mode file and a PHYSICAL parameter vector
#' (2026-10-01, for the Laplace ribbons).
#'
#' ⭐ ONE MAPPING for the app's central fit (app/global.R app_params()) and every
#' draw of calibration/build_futures_ribbons.R, so a band and the line it
#' surrounds cannot come from two copies of this arithmetic. The lines are
#' app_params()'s own, moved here unchanged: the file's structure as the base
#' (ccx_mode_base), every name the vector carries overlaid, the ENSO block set
#' from the vector, the file's pump mode, and the two FORCING parameters
#' `ccx_default_params()` has no slot for returned beside the list.
#' @param md a loaded mode file
#' @param pm a physical vector carrying the file's held values -- the caller's
#'   ccx_mode_par_with_pins(md) (migrated if the file lacks a name), or a
#'   decoded draw with the pins added
#' @param base the file's own structure, ccx_mode_base(md); a driver that maps many draws
#'   resolves it ONCE and passes it (the mode-struct lint then sees the resolver it uses)
#' @return list(p, bomb_total, luc_scale)
ccx_mode_run_params <- function(md, pm, base = ccx_mode_base(md)) {
  p <- base
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  # `pump_mode` is a STRUCTURAL choice, not a fitted parameter, so it is not
  # in par_mode and the loop above cannot carry it. It matches the default
  # today (both "N"); setting it explicitly is what keeps that a fact rather
  # than a coincidence if the default ever moves.
  p$pump_mode <- md$pump_mode
  list(p = p, bomb_total = pm$bomb_total, luc_scale = pm$luc_scale)
}

#' Is a futures-ribbons artifact (calibration/build_futures_ribbons.R) valid for
#' THIS fit? (2026-10-01, B7.)
#'
#' ONE check, shared by the app's loader (which then draws no band and says so)
#' and test-futures-ribbons.R (which then fails): bands built at a different
#' parameter vector would shade the wrong uncertainty around the right line,
#' silently. The vector, not the mode NAME, is compared -- a refit that kept the
#' name would otherwise pass.
#' @param r the artifact (readRDS of data/futures_ribbons.rds)
#' @param mode the mode the bands must describe (a name for ccx_mode_file())
#' @param scenarios the scenario ids the tab offers; @param vars its y-variables
#' @return character(0) if valid, else one string per problem
ccx_ribbons_problems <- function(r, mode = CCX_MODE_CANONICAL, scenarios, vars) {
  # the mode is read HERE, in the resolver file: the check needs the STORED vector, not a
  # parameter list, and a caller that read it by hand would trip the mode-struct lint for no reason
  md <- readRDS(ccx_mode_file(mode))
  bad <- character(0)
  pv <- r$provenance
  if (is.null(pv) || is.null(r[["bands"]])) return("not a ribbons artifact (no provenance or no bands)")
  # ⛔ [[ ]], NEVER $, on the provenance: `$` PARTIAL-MATCHES, so with `seed` removed `pv$seed`
  # silently returned `seed_applied` and a missing seed passed (caught by the mutation test, 2026-10-01).
  # the NAME is checked against the `mode` argument, as the vector below always was (2026-10-03 h: it
  # read CCX_MODE_CANONICAL, so the check could not be asked about any other mode -- the held evidence,
  # built at hilda33d, could not be validated once hilda34g was adopted). The app passes the canonical.
  if (!identical(pv[["mode"]], mode))
    bad <- c(bad, sprintf("built for mode '%s', %s '%s'", pv[["mode"]],
                          if (identical(mode, CCX_MODE_CANONICAL)) "the canonical is" else "checked against", mode))
  if (!identical(pv[["par_mode"]], md$par_mode))
    bad <- c(bad, "built at a different parameter vector from the canonical's par_mode")
  if (is.null(pv[["seed"]]) || is.null(pv[["rng_kind"]]) || is.null(pv[["seed_applied"]]))
    bad <- c(bad, "the seed, the RNG kind or where it is applied is not recorded")
  miss <- setdiff(as.character(scenarios), unique(r$bands$scenario))
  if (length(miss)) bad <- c(bad, sprintf("no bands for scenario(s) %s", paste(miss, collapse = ", ")))
  missv <- setdiff(as.character(vars), unique(r$bands$var))
  if (length(missv)) bad <- c(bad, sprintf("no bands for variable(s) %s", paste(missv, collapse = ", ")))
  b <- r$bands
  if (any(!is.finite(b$q05) | !is.finite(b$q95) | !is.finite(b$q50)))
    bad <- c(bad, "non-finite quantiles")
  else if (any(b$q05 > b$q50 | b$q50 > b$q95))
    bad <- c(bad, "quantiles out of order (q05 <= q50 <= q95 fails)")
  bad
}

ccx_mode_params <- function(md = CCX_MODE_CANONICAL) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  # WITH the file's pins (2026-09-13): the vector the mode RAN at, held names
  # included, so a consumer that overlays or migrates it sees nothing absent. To
  # ENCODE a pinned file, ccx_apply_pins(ccx_mode_pins(md)) first -- under the
  # reduced table ccx_par_to_unc() ignores the held name it carries.
  if (!is.null(md$par_mode)) return(ccx_mode_par_with_pins(md))
  # same rule as ccx_adopt_mode_band(): the file's own names, not the build's
  u <- md$u_mode
  .nm <- if (!is.null(md$param_names)) md$param_names else CCX_PARAM_NAMES
  if (length(u) != length(.nm))
    stop("mode file's u_mode has ", length(u), " values but its param_names has ",
         length(.nm), " -- the file is internally inconsistent.")
  names(u) <- .nm
  bands <- ccx_mode_bands(md)
  bands <- bands[names(bands) %in% .nm]   # a band for a parameter this file lacks
  if (!length(bands)) return(ccx_unc_to_par(u))
  # ⚠ SNAPSHOT BEFORE THE LOOP, RESTORE IN ONE on.exit. An on.exit() registered
  # INSIDE the loop would capture the loop variable, which R evaluates at EXIT --
  # so it would restore the last band twice and leak every other one.
  .orig <- CCX_PARAM_TABLE[names(bands)]
  on.exit(for (.b in names(.orig)) CCX_PARAM_TABLE[[.b]] <<- .orig[[.b]], add = TRUE)
  for (bn in names(bands)) {
    CCX_PARAM_TABLE[[bn]]$lo <<- bands[[bn]][1]
    CCX_PARAM_TABLE[[bn]]$hi <<- bands[[bn]][2]
  }
  ccx_unc_to_par(u)
}

#' Gate a mode file's `u_mode` decoding against its own stored `par_mode`
#'
#' Call this in any diagnostic that decodes `u_mode` itself. It ERRORS rather
#' than warns: a silently-wrong `h_ml` is exactly the failure this file
#' documents, and it survived weeks because nothing checked.
#'
#' @param md a loaded mode file, or a mode name/path
#' @param tol relative tolerance per parameter
ccx_check_mode_decode <- function(md = CCX_MODE_CANONICAL, tol = 1e-8) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  if (is.null(md$par_mode)) return(invisible(TRUE))   # nothing to check against
  # THIRD SITE of the same defect (2026-08-31): a STORED u_mode named with the
  # LIVE CCX_PARAM_NAMES. ccx_adopt_mode_band() and ccx_unc_to_par() were fixed
  # the same day; this one was found by its own test, which caught the raw
  # "'names' attribute [22] must be the same length as the vector [21]" instead
  # of the decode message it asserts. A file from ANOTHER parameter set is a
  # different question from a file that mis-decodes, and this function answers
  # only the second -- so say the first plainly and decline.
  u <- md$u_mode
  .nm <- if (!is.null(md$param_names)) md$param_names else CCX_PARAM_NAMES
  # a PINNED file (2026-09-13) carries the build's set MINUS its pins, and every
  # name it does carry is in the table, so it decodes on its own names
  # ... and a file lacking only CCX_PARAM_ABSENT_OK names (2026-09-13i) decodes
  # on the names it carries; ccx_unc_to_par() honours a partial named u.
  if (!ccx_mode_carries_build(md))
    stop("this mode file was fitted on a DIFFERENT parameter set (",
         length(.nm), " names vs this build's ", length(CCX_PARAM_NAMES),
         "), so 'does it decode to its own par_mode' is not a question this ",
         "build can answer. Refit, or read it with ccx_mode_params().")
  names(u) <- .nm
  pv <- ccx_unc_to_par(u)
  bad <- character(0)
  for (n in intersect(names(pv), names(md$par_mode))) {
    a <- pv[[n]]; b <- md$par_mode[[n]]
    if (!is.numeric(a) || !is.numeric(b) || length(a) != 1L || length(b) != 1L) next
    if (abs(a - b) > tol * max(abs(b), 1e-12)) bad <- c(bad, sprintf(
      "%s: ccx_unc_to_par gives %.6g but par_mode stores %.6g (%.2f %%)",
      n, a, b, 100 * abs(a - b) / max(abs(b), 1e-12)))
  }
  if (length(bad))
    stop("this mode file does NOT decode to its own stored par_mode under the ",
         "CURRENT CCX_PARAM_TABLE:\n  ", paste(bad, collapse = "\n  "),
         "\nUse ccx_mode_params(), or ccx_adopt_mode_band() BEFORE this check -- see the ",
         "note above ccx_mode_params() in R/paths.R. For h_ml this is the band the ",
         "refit ran under (md$hml_bound = ", paste(md$hml_bound, collapse = ", "),
         "); since 2026-09-16 (b) the shipped floor is CCX_HML_FLOOR_M, so every ",
         "file fitted before it differs here.")
  invisible(TRUE)
}

#' Adopt a mode file's own `h_ml` band for the rest of this session
#'
#' The uniform fix for the defect documented above. `ccx_mode_params()` repairs
#' ONE decode; this repairs ALL of them, including the ones inside
#' `ccx_make_logpost()`, by putting the shipped `CCX_PARAM_TABLE` into the state
#' the refit was run in. Call it ONCE, immediately after reading the mode, in
#' any driver that decodes `u_mode` or perturbations of it.
#'
#' This is what `run_modefind_pump_arms.R`, `recompute_hessian.R`,
#' `diag_hess_eps_21par.R` and `diag_seas_T_amp_q10_ridge.R` already do by hand;
#' those files are correct and need no change.
#'
#' ⚠ IT ALSO NARROWS THE PRIOR, by construction — that is the same +1.5805
#' additive constant the bounded refit carries. It cancels from every DIFFERENCE
#' and must never be read as a change in fit. ⚠ It confines `h_ml` to the band,
#' so do not call it in a driver that profiles `h_ml` across the edge.
#'
#' @param md a loaded mode file, or a mode name/path
#' @return invisibly, the previous `h_ml` table entry, for restoring
ccx_adopt_mode_band <- function(md = CCX_MODE_CANONICAL) {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))
  # EVERY recorded band, not just h_ml. `kz_bracket` was written from
  # 2026-08-16 and adopted by nothing until 2026-08-31c; see
  # CCX_MODE_BAND_FIELDS for why that stayed invisible.
  bands <- ccx_mode_bands(md)
  old <- CCX_PARAM_TABLE[names(bands)]
  if (!length(bands)) return(invisible(CCX_PARAM_TABLE[character(0)]))
  for (bn in names(bands)) {
    CCX_PARAM_TABLE[[bn]]$lo <<- bands[[bn]][1]
    CCX_PARAM_TABLE[[bn]]$hi <<- bands[[bn]][2]
  }
  if (!is.null(md$par_mode)) {
    # ⚠ NAME A STORED VECTOR WITH THE NAMES IT WAS STORED WITH, not the live
    # ones. This read `names(u) <- CCX_PARAM_NAMES`, which is the live build's
    # list -- correct only while the parameter SET never changes, and it broke
    # the moment `seas_lag_p` was split on 2026-08-31 (22 names onto a 21-vector,
    # a bare 'names attribute must be the same length' from inside a band
    # adopter, which says nothing about the real cause). Same defect class as
    # the CCX_FORCING_COLS length trap: a stored artifact indexed by a constant
    # that is free to move underneath it.
    u <- md$u_mode
    .nm <- if (!is.null(md$param_names)) md$param_names else CCX_PARAM_NAMES
    if (length(u) != length(.nm))
      stop("mode file's u_mode has ", length(u), " values but its param_names has ",
           length(.nm), " -- the file is internally inconsistent.")
    names(u) <- .nm
    # DECODE ONLY THE BANDED PARAMETERS, which is all this check verifies.
    # Decoding the WHOLE vector made the check fail on any mode file whose
    # parameter set differs from the build's -- even though the band question it
    # exists to answer is perfectly well posed for such a file. A gate should
    # need no more of its input than the property it gates.
    for (bn in names(bands)) {
      if (!bn %in% .nm)
        stop("mode file records a band for ", bn, " but has no ", bn,
             " in its param_names.")
      got <- .from_unc(u[[bn]], CCX_PARAM_TABLE[[bn]])
      if (abs(got - md$par_mode[[bn]]) > 1e-8 * max(abs(md$par_mode[[bn]]), 1e-12))
        stop("adopting ", bn, "'s recorded band [", paste(bands[[bn]], collapse = ", "),
             "] still does not reproduce par_mode's ", bn, " (", md$par_mode[[bn]],
             "); got ", got, ". This mode file was fitted under some OTHER band.")
    }
  }
  cat(sprintf("[ccx_adopt_mode_band] %s\n", paste(vapply(names(bands), function(bn)
    sprintf("%s -> [%g, %g] (mode %.4f)", bn, bands[[bn]][1], bands[[bn]][2],
            if (is.null(md$par_mode)) NA_real_ else md$par_mode[[bn]]),
    character(1)), collapse = "; ")))
  invisible(old)
}
