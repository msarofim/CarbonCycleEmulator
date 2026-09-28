# Handoff — 2026-09-28. **Two Torch arrays are running: collect them, then read the shape-prior arm against its pre-registration.**

> Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never a bare `cd` in a
> Bash call: it moves the session's working directory. Use `git -C` or absolute paths.
> **Read first:** this file, then `notes/prereg_2026-09-28_fert_k_shape_prior.md`, then CHANGELOG
> **2026-09-27 (e)** and **2026-09-28 (a)–(d)**. Memory: `ccx_pulse_decay_is_the_veg_loop` (in the
> `INDEX_ccx_ref.md` routing) carries the running state.

---

## 1. What we were doing
Marcus asked why CCX's CO₂ pulse decays faster than Joos 2013 / FaIR, **without making Joos a
calibration target** (ruled 09-04, reaffirmed 09-27 and 09-28: *"We don't need to reach Joos… but we
should implement the saturation mechanisms that have good support"*).

The arc, in order:
1. **A bug, first (09-27 e).** Every PD100 IRF was read 5 yr late: `ccx_irf()` pulses at 2010 and 11
   callers shifted the clock by 5 yr, which discarded the first five years instead. Fixed once in
   `ccx_irf_pd()` + `joos_release_check()` (mutation-tested). At `hilda29l`, TH 20/50/100 went
   11.41/23.51/39.15 → **13.04/25.80/41.80, inside Joos at all three**. Pre-fix logs are in
   `outputs/quarantine/20260927_joos_release_shift/`. **Any TH/IRF number recorded before 09-27 (e) is shifted.**
2. **The physics (09-27 e).** At 100 yr the ocean holds 31.8 GtC (Joos 33 ± 12, on the mean) and the
   land 39.4 (Joos 23 ± 20). The cause is the unfitted **vegetation-capacity loop `npp_veg_frac` (φ 0.5)**,
   which doubles the land's equilibrium CO₂ response. A frozen knock-out φ → 0 put the atmosphere on Joos.
   Driver: `calibration/diag_pulse_land_attribution.R`.
3. **φ = 0 refit (09-28 a–b).** New label `hilda_csl3v0`. One local warm start **converged at −1424.63,
   vs `hilda29l` −1425.36 (+0.73)**, so the record cannot tell φ 0.5 from 0. But the fit compensates:
   `beta_max` 1.31 → 2.72 (its bound is 3), `fert_k` 825 → 938, FACE-equivalent (400→564) 14.4 → 24.5 %.
   Pulse IRF@100 0.289 → **0.344** (Joos 0.409). Archived:
   `calibration/output/multistart_20260928a_hilda_csl3v0_seasml1_canonpins/`.
4. **Saturation research (09-28 c).** `notes/lit_2026-09-28_co2_fert_saturation.md`. Shape metric
   R = gain(4×)/gain(2×) (log 2, linear 3); for CCX's MM form **K = 3·C0·(R−1)/(3−R)**, so a log shape
   equals K ≈ 834. **CCX's fits (825–940) are log-like.** Evidence: CMIP6 GPP median R 1.81 (our own
   extraction), Varney 2024 NPP 1.82, Walker 2021 theory. All point to K ≈ 500–600.
5. **The shape-prior arm (09-28 d).** Label `hilda_csl3v0k` = φ 0 + a lognormal prior on `fert_k`.

## 2. Decisions and rulings (all Marcus, 2026-09-27/28)
- **Symlink harness test DROPPED.** Launch from FaIRtoFrEDI, then `change_directory`.
- **φ = 0 only** — Marcus's CO₂-adjusted-equilibrium variant was set aside (it halves the FACE-step
  response; "clearing and regrowth cancel" double-counts regrowth under GCB **net** E_LUC at `f_luc_perm` 1).
- **Shape, not size.** The shape comes from **Varney 2024 + Walker 2021 + physiology, with CMIP6 as a
  comparison**. The SIZE of the response stays free for the record. **No FACE cap** (FACE informs limits;
  keep it as an out-of-sample check).
- **Prior width "moderate", log-sd 0.35.** It applies to the φ = 0 arm only.
- Nothing is registered or adopted. **The canonical is still `hilda29l`.** Adoption is Marcus's call.

## 3. Files
**Committed (CCX `main`, pushed; last commits `8e10639`, `1c6d894`):**
- `R/joos_irf.R` — `ccx_irf_pd()`, `joos_release_check()`, `JOOS_IRF0_TOL`.
- `R/calibrate.R` — labels `hilda_csl3v0`, `hilda_csl3v0k`; `ccx_fert_k_prior()`; `fert_k`'s
  two-argument prior (FLAT unless `p$fert_k_prior == 1`).
- `data-raw/build_fert_k_prior.R` → `data/prior_fert_k.rds` (median 545.7, log-sd 0.35; Walker K 510.8, Varney K 582.9).
- `calibration/diag_pulse_land_attribution.R`, `calibration/diag_fert_profile_phi.R` (+ logs in `outputs/diagnostics/`).
- `tests/testthat/test-struct-v0.R` (new); `test-pulse.R` (release gate); label-list locks in
  `test-tr-box.R` and `test-constants-batch.R` extended.
- `notes/lit_2026-09-28_co2_fert_saturation.md` + `notes/lit_2026-09-28_cmip6_gpp/*.csv`. The Python
  that produced the CSVs is OUTSIDE the repo (R-only rule): `~/Documents/2026/ClaudeDocs/ccx_lit_scripts/20260928_cmip6_gpp/`.
- `notes/prereg_2026-09-28_fert_k_shape_prior.md`.
- `calibration/torch/make_bundle.sh` — now ships `hilda32f` (`c751e10`).

**Frozen worktrees (git worktrees, detached; leave until the arrays are collected):**
`~/ccx_frozen/20260928a_phi0` (at `9c0350f`) and `~/ccx_frozen/20260928b_v0k` (at `8e10639`). Each holds
its label's `calibration/torch/port_targets.csv` — **not** the repo's canonical one.

## 4. Running now — the next steps
| array | job | Torch dir | label | outdir tag |
|---|---|---|---|---|
| φ = 0 free | **18723994** | `/scratch/ms17839/ccx_20260928_phi0` | `hilda_csl3v0` | `20260928b` |
| shape prior | **18729847** (queued behind it) | `/scratch/ms17839/ccx_20260928_v0k` | `hilda_csl3v0k` | `20260928c` |

Both use canonical pins, seas_ml 1, the solved field, the `cs` partition, a 300-min budget and 24 starts.
Torch runs at ~0.40–0.45 s/eval (3× the Mac), so allow 4–5 h per task. Preflights 18723155 and
18729635 passed 8/8 port gates. Check with
`ssh torch 'sacct -j <job> -X --noheader -o JobID,State,ExitCode,Elapsed'`.

1. **Collect each array** with `calibration/collect_dispersed_multistart.R` (read its header for the
   env and outdir; run it on Torch or rsync the start files back from the laptop side — never rsync
   FROM Torch inside an ssh session). Archive the start files and logs into `calibration/output/`.
2. **φ = 0 array:** does the best start beat the single Mac start (−1424.63)? Where do `beta_max` and
   `fert_k` land, and does `beta_max` sit on its bound of 3?
3. **Shape-prior array, against the prereg:**
   - **P1 (exact, a gate):** its log-LIKELIHOOD is ≤ 1.74 below the free φ = 0 best. If not, stop and debug.
   - **P2:** `fert_k` in [546, 938]. The lean is 700–900, meaning the record wins.
   - **P3:** `beta_max` ≤ 2.72, FACE-equivalent ≤ 24.5 %, IRF@100 ≥ 0.344.
   - **Compare on likelihood, not logpost** (the priors differ).
4. For each best mode: build a scratch mode file (as `calibration/output/.../start_001.rds` was turned
   into one on 09-28 b) and run `diag_pulse_land_attribution.R <path>`. Report the FACE-equivalent
   against FACE (+10–23 %) and CMIP6 (+16.9 ± 6.2 %).
5. Then bring Marcus the three-way comparison (`hilda29l` / φ 0 free / φ 0 + shape) and let him rule.

## 5. Non-obvious state and traps
- **The shape prior is weak against the record:** its full pull from 938 to 546 is only +1.74 log
  units, while a frozen profile priced `fert_k` 500 at −54 under φ 0. Read the arm as a MEASUREMENT of
  the record's resistance. If the record wins, the options are Marcus's (report the tension; tighten;
  look for a missing process — the 08-25 `fert_k`/`rep_dC` tie is the first suspect).
- **Frozen-vector numbers are upper bounds on cost** (`diag_fert_profile_phi.R`, the 2-D shortcut). On
  09-28 the 2-D shortcut said −7.27 and the full refit found +0.73.
- **The physiology bracket is pending:** Bernacchi 2001 (PCE 24:253) is paywalled; Marcus may add the
  PDF to `~/Documents/2026/ClaudeDocs/Papers/`. Walker's canopy values ARE the physiology line meanwhile.
- **Suite:** 4916 pass / 1 fail at 09-27 (e). The one failure is the NAMED STANDING RED
  (`test-mode-file.R`, the AIC gate, ruling 2 of 09-19) — do not "fix" it. The files touched since pass
  on their own (32 + 254 + 33), but the FULL suite has not been re-run since `8e10639`.
- `cmip6` GPP numbers are our own extraction (not published). Only Varney and Walker enter code.
- The FaIRtoFrEDI answer-key removal (`e4133a8`) is committed on `heat-ed-morbidity` there and NOT
  pushed — that branch has Marcus's other work in progress.
- `carbotopecomment.9.26.26.docx` is untracked in CCX — it is Marcus's; leave it alone.
- The app still runs the canonical `hilda29l`; nothing here has touched it except the review panel's
  Joos IRF call (now `ccx_irf_pd`).
