# Handoff — 2026-09-06c. "How many can we afford?" became "which statistic is the observation": the deep profile's CONTRAST decides the attachment, and it is HILDA's.
# **✅ Suite green after the last commit (see the CHANGELOG line for the count).**
# **⛔ NOTHING ADOPTED. `hs_asx_frac` ships 1, `kz_deep_frac` ships 1, `hs_frac` ships 0. The two intermediate rows ARE in the objective (#8).**
# **⇒ NEXT IS A RULING: objective change #9 and the refit design in `notes/prereg_2026-09-07_hilda_refit_design.md`.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, no remote. Commits this
session (after `8b5052b`): `7a52443` (objective #8 + `hs_asx_frac` + the first identifiability run), then
the 09-06c commit. **Read before this one:** `handoff_2026-09-06b_kz_profile_and_obs_pin.md`, then the
collect `collect_2026-09-06c_structure_identifiability.md` (§6–§8 are the point).
⚠ Sessions launch from `FaIRtoFrEDI/`; use `git -C`. ⚠ This session ran very long (five diagnostics,
two objective-side changes); a fresh session should start from this note and the refit design.

## 1. WHAT MARCUS ASKED, AND WHAT WAS DONE
*"How many of the 5 variables can we afford to free? … use observations and known physical laws;
document HILDA's numbers as caveats."* Then: *"Move forward with your recommendations."*
- **`h_hs` read as the HS air–sea EXCHANGE** (09-05b measured thickness to cancel at steady state);
  built as `hs_asx_frac` (exchange area factor, ships 1, bit-exact). ⚠ 09-06c then found thickness
  HAS transient power (bomb capacity) — corrected in the register and the memory.
- **The two intermediate GLODAP rows are in the objective** (#8): 1500–2000 m −168.6, 2000–2627 m
  −175.6, se 13.5 / 13.6; their n_eff was MEASURED afterwards at 21.1 / 20.0 (the reuse of 20 was
  right). Every stored logpost lacks them; two fixtures were repaired by derivation.
- **Four identifiability runs** (pre-registered with amendments before each): Hessian at the arm
  (indefinite — not a count), free optimum (removes the conduit), declared-conduit optimum
  (removes K(z)), and the profile-price frontier (price ZERO, but held by a 200 m mixed layer with
  the conduit off). ⇒ the LEVELS decide nothing.
- **The contrast measurement** — the finding: se(B − deep) = 3.5–4 ‰, observed −0.4. Columns and
  bottom-attached arms rejected at 3–5σ; HILDA's attachment inside 2σ. With `hs_asx_frac` 0.8,
  HILDA's configuration solves at K_deep 309 with every interior row inside 1σ and the best
  matched-parameter transient of the arc (−193 to −255, mostly the recoverable pump-δ¹³C artefact).

## 2. ⭐⭐ THE ANSWER
- **Through the bomb rows: one** — `hs_asx_frac` (0.65–0.8, marginal sd ≤ 0.10 wherever free).
- **Through the profile levels: none.** A fit removes whichever structure it may.
- **Through the profile CONTRAST: the attachment (HILDA's) and, with it, the deep floor** (f 0.05–0.10).
- Declared with caveats (one remove): `z_K` 253, `u_hs` 38, `tau_q` 538 — each with a sensitivity scan
  owed as the caveat's number. Declared from observation: `hs_frac`, `sst_hs`, the attachment.
  Register: `notes/caveats_declared_parameters.md`.

## 3. ⚠ MY ERRORS THIS SESSION, ON THE RECORD
1. The first identifiability run measured curvature at a non-optimum and reported marginal sds off an
   indefinite matrix ⇒ [[hessian_at_non_optimum_is_not_a_count]].
2. I predicted the slabs' n_eff would differ from 20 by > 2×; it is 21 / 20.
3. I over-generalised 09-05b's steady-state "h_hs is not a term" to the transient.
4. The 09-05f departure to bottom attachment, which I argued from CCX's structure, is rejected by
   the contrast at −3σ; the level-based "control-dependent, second-order" reading of 09-06 was the
   wrong statistic. Both memories carry the supersession in place and the indexes were updated in
   the same edit ([[retraction_in_place_does_not_propagate]]).

## 4. ⇒ NEXT (the ruling, then the run) — `notes/prereg_2026-09-07_hilda_refit_design.md`
1. **Objective change #9**: the three interior levels as ONE MVN row with the measured 3×3 covariance
   (60° block recommended). Mutation gate: the bottom arm must lose ≥ 9 on the row.
2. Declared: attachment 1 (observation), `hs_frac` 0.16, `sst_hs` 2, `h_hs` = `h_ml`, `z_K` 253,
   `u_hs` 38, `tau_q` 538 (the last three with caveats + scans). Free: f, `hs_asx_frac`, the 26; the
   `kz` bracket re-bisected on 36 boxes.
3. Sea-ice open-water fraction over the HS area as a CROSS-CHECK on `hs_asx_frac` (needs a
   `data-raw/` download script).
4. Torch, 46-start harness. Then DESIGN §6 at `ent26`; `INDEX_cmp_pulse.md` split.

## 5. ⚠ NON-OBVIOUS STATE
* Nothing running anywhere. All diagnostics local, 2–15 min each; the suite ~14 min.
* **Objective #8 is live**: `ccx_make_logpost` and `dg_streams` pass `d14c_mid`; ~60 diagnostic
  scripts that call `ccx_loglik` directly do NOT and show the rows ABSENT — by design, visibly.
* `LIK_D14C_MID_NEFF` is assigned in `globalenv()` by two scripts as a device (frontier, fixture);
  never leave it changed.
* Memory budgets: `INDEX_ccx_ocean_struct` ~15.3 KB (over soft, under hard — the split precedent
  applies next); `INDEX_ccx` ~17.1 KB (near hard, split soon); root 12,3xx (measure with comments
  stripped). New memories: `ccx_intermediate_d14c_rows`, `ccx_hs_asx_frac`,
  `hessian_at_non_optimum_is_not_a_count`, `ccx_profile_contrast_is_the_observation`.
* Logs: `outputs/diagnostics/diag_structure_*_20260906.log`, `diag_mid_d14c_neff_20260906.log`,
  `diag_d14c_profile_covariance_20260906.log`, and the `.rds` beside each.

## 6. ⇒ STANDING RULES THIS SESSION ADDED
* ⭐⭐ **WHEN A FIT TRADES AN OBSERVATION AWAY FOR FREE, ASK WHICH STATISTIC CARRIES ITS INFORMATION.**
  Correlated means carry their CONTRAST; independent rows discard it.
* ⭐⭐ **A HESSIAN AT A NON-OPTIMUM IS NOT A COUNT.** Optimise the coupled block first; read the
  conditionals and correlations even so.
* ⭐ **"HOW MANY CAN WE AFFORD" IS ANSWERED PER STATISTIC**, not per parameter: the same parameter can
  be unidentified by the levels and pinned by the contrast.
* ⭐ **A STEADY-STATE "NO LEVER" IS NOT A TRANSIENT "NO LEVER."** Measure both before retiring a knob.
