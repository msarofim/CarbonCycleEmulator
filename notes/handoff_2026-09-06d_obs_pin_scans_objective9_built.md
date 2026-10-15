# Handoff — 2026-09-06d. The `hs_asx_frac` pin is PAID from observations and a law (0.65: HILDA's cancellation is real, the Schmidt number is the rest); the three caveat scans are in; objective #9 is BUILT and ships OFF.
# **⛔ NOTHING ADOPTED. `LIK_USE_D14C_PROFILE_MVN` FALSE, `hs_asx_frac` ships 1, `kz_deep_frac` 1, `hs_frac` 0.**
# **⇒ NEXT IS STILL THE RULING — `notes/prereg_2026-09-07_hilda_refit_design.md` §7, now with §8's numbers.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, no remote. Commits this
session are listed in CHANGELOG 09-06d. **Read before this one:** `handoff_2026-09-06c_contrast_decides_the_attachment.md`,
then the design's §8 addendum. ⚠ Sessions launch from `FaIRtoFrEDI/`; use `git -C`.

## 1. WHAT WAS DONE (everything that did NOT need the ruling)
1. **The observational pin on `hs_asx_frac`** (`data-raw/download_hs_exchange_obs.R`,
   `build_hs_exchange_factor.R` → `data/obs_hs_exchange_factor.rds`; `SC_CO2_W14_A..E` in constants):
   ⟨(1−ice)U²Sc^−½⟩_HS / ⟨U²Sc^−½⟩_LL = **0.653** (1981–2010; 0.61–0.66 across windows). Ice × wind =
   **1.064** — HILDA's cancellation is right to 6 %; the Schmidt term 0.549 is what a fitted `k_w`
   cannot carry. **The fitted 0.65–0.8 is the Schmidt number**; the cross-check PASSES (within 1 sd).
   Cold area **0.160** = HILDA's 0.16, measured. NH 0.32 / SH 0.78 (one factor, one `hs_frac` in the model).
2. **The caveat scans** (`calibration/diag_declared_param_scans.R`): every declared window is
   ONE-SIDED (`z_K` 500 / `u_hs` 76 / `tau_q` 269: no deep floor holds the deep); the other side costs
   the SINK (−223 / −517) — except `tau_q` ×2, which GAINS 93 on the transient while failing the
   contrast at +4.3σ. The CO₂ rows reward leaving the conduit; only the contrast objects.
3. **Objective #9 built** (`data-raw/build_glodap_profile_covariance.R` → `data/obs_glodap_profile_cov.rds`;
   `R/likelihood.R` MVN row; `tests/testthat/test-d14c-profile-mvn.R`, 23 pass; mutation
   `calibration/diag_objective9_profile_row.R`): K(z)+bottom arm loses **25.4** extra (gate ≥ 9 PASS);
   uniform-`kz` bottom pin only 2.8 (its contrast is −2.9σ) — **a gate number is per arm**.
4. Register, CHANGELOG, design §8, memories (`ccx_hs_asx_obs_factor`, `ccx_declared_param_scans`,
   `ccx_objective9_mvn_row_built`; `ccx_hs_asx_frac` and `ccx_profile_contrast_is_the_observation`
   updated in place), `INDEX_ccx_ocean_struct` (now ~15.9 KB stripped — over soft 14, under hard 18:
   **the split precedent applies next**), root line rewritten (12.4 KB, over soft by 0.4).

## 2. ⚠ ON THE RECORD
* The Schmidt coefficients are cited at ONE REMOVE (pySeaFlux reproducing Wanninkhof 2014 Table 1;
  Wiley was 403). Sc(20 °C) = 668 checks. Verify against the PDF if one lands in ClaudeDocs/Papers.
* The design's own cross-check statistic (open water alone, 0.651) equals the full factor (0.653) by
  two canceling omissions. It would have "confirmed" the fit for the wrong reason.
* The design's mutation number (≥ 9) was calibrated on the −5σ arm; it fails on the −2.9σ arm. §8
  says which arm the gate names.

## 3. ⇒ NEXT — THE RULING (§7 of the design), then the run
1. #9 on, block 60 or 30. 2. `z_K`/`u_hs`/`tau_q` declared (now with the scan numbers) or one freed.
3. `h_hs` declared or freed. 4. `hs_asx_frac`: cross-check (passes) or prior N(0.65, ~0.05).
5. Torch, 46 starts; `kz` bracket re-bisected on 36 boxes first. Then DESIGN §6 at `ent26`;
   `INDEX_cmp_pulse.md` split; `INDEX_ccx_ocean_struct` split (IS/SHOULD-BE precedent).

## 4. ⚠ NON-OBVIOUS STATE
* Nothing running anywhere. Scans ~4 min, mutation ~2 min, covariance build ~1 min, factor build 50 s.
* `data-raw/downloads/HadISST_ice.nc` (465 MB, gunzipped from the 16 MB .gz) and the NCEP file are
  gitignored; MANIFEST has 40 entries. ERSST v5 (already there) defines the cold area.
* `LIK_USE_D14C_PROFILE_MVN` is toggled in tests via `assign(..., globalenv())` with `on.exit` reset,
  the `LIK_USE_D14C_MID` precedent. Never leave it changed.
* Logs: `outputs/diagnostics/{diag_declared_param_scans,diag_objective9_profile_row,build_glodap_profile_covariance,suite}_20260906*.log` + the `.rds` beside each.

## 5. ⇒ STANDING RULES THIS SESSION ADDED
* ⭐⭐ **PRICE EVERY TERM OF A LAW BEFORE QUOTING THE ONE THAT MATCHES.** Two canceling omissions
  produce a number indistinguishable from the right one.
* ⭐ **A MUTATION-GATE NUMBER IS PER ARM.** Name the arm it was calibrated on, or the gate fails on
  a weaker arm and looks like a defect in the row.
* ⭐ **A ONE-SIDED WINDOW IS A CAVEAT WITH A DIRECTION.** "No solution beyond" is a stronger
  statement than a cost, and the register should say which side is closed.
