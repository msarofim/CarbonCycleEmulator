# Handoff — 2026-09-27. **Gate 12's diagnostic can read the shipped model at last — and fixing it uncovered a silent defect that had been deleting every arm's pinned parameters. The constraint map's near-ties now read as ties, on a threshold the data chose.**

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/`. Use absolute paths.
> ⛔ **`cd X && ...` in a Bash call MOVES the session's primary working directory** — only a
> subshell `( cd X && ... )` or `git -C` is safe. Recover with `change_directory`; it lands at the
> END of the turn.
>
> **Read first:** CHANGELOG **2026-09-27 (a)**, then **§1** (what is owed) and **§4** (non-obvious
> state). Supersedes `handoff_2026-09-26c_*` for STATE; the pulse/FaIR/TCRE **measurements** live in
> `handoff_2026-09-26b_*` and are unchanged.

---

## 1. What is owed

### (a) ⛔ ONE RULING — the last of the pair, and it is now UNBLOCKED
**`diag_joos_irf.R`'s DEFAULT arm is still `"defaults"`** — the uncalibrated table. A bare run still
reports a model nobody ships (pulse AF@100 **0.445** vs the canonical's **0.307**). It was left
because changing it re-means every past gate-12 number, and gate 12 is Marcus's ruled territory
(09-04: *a COMPARISON, not a strict test*).
⭐ **What changed on 09-27: the canonical now RUNS** (§2), so the blocker is gone and all three
options are live — make absence an ERROR, default to the canonical, or leave it and print the arm
beside the verdict. ⇒ [[ccx_joos_diag_default_arm]].

### (b) Carried over, still unverified
⛔ **The `CarbonCycleEmulator` memory symlink has never been tested against the harness** (owed since
09-26 a). **One-line test**: start a session in `CarbonCycleEmulator/` and ask what `INDEX_ccx.md`
gives as the canonical mode; an answer without reading a file means it loaded. Until then, **keep
launching from `FaIRtoFrEDI/`**.

### (c) NOT owed
The near-ties are resolved (§3). The memory tree is clear — tightest index is `INDEX_ais.md` at
1,775 B; nothing is in split territory.

---

## 2. ⛔⛔ THE FINDING: `par_mode` is the FREE set, and reading it as the parameter set broke two things

`diag_joos_irf.R` ran `ccx_migrate_par_set(.md$par_mode)`. A **pinned** name is absent from
`par_mode` by construction. **One wrong accessor, two failures — and the loud one hid the silent one.**

1. **LOUD** — the canonical `hilda29l` could not be read **at all**. It pins the ocean ENSO shim at 0
   and fits the layer-3 limb `w_enso_l2` instead, so the migrator saw `gamma_enso_ocn_*` absent,
   found no legacy `gamma_enso`, and refused: *"this list carries no ENSO response at all."*
   **It carries one — the limb IS the response.** The migrator's premise was written when the
   coefficients were the only ENSO mechanism and was never revisited when the limb replaced them.
2. ⛔ **SILENT, and long-standing** — the overlay assigned `.pm[[n]]` for every param name in `p0`,
   and for a pinned name that is **NULL**. **Assigning NULL to a list element DELETES it.** Every arm
   ran with `w_eq`, `gamma_eq`, `pump_export`, `w_vent`, `gamma_vent`, `w_thc` (and per arm
   `w_enso_l2`, `ent_seas_amp_SH`, `gamma_enso_ocn_*`) stripped out of the vector `ccx_mode_base()`
   had correctly supplied them in. Same trap as [[intersect_is_a_silent_default]], same codebase.

⭐ **BLAST RADIUS, MEASURED: no number moved.** `hilda32f` is byte-identical before and after, so (2)
was numerically inert on the arms that could run. ⚠ **Which is itself a finding**: the pins genuinely
differ from the defaults (`w_eq` **27 vs 0**, `gamma_eq` **1 vs 0**, `pump_export` **9.08 vs 0**), so
**those three are inert under the shipped `hilda_csl3` structure**. Recorded, **not chased** — but do
not assume a pin is doing work. ⇒ [[free_set_is_not_the_parameter_set]].

**The fix is an accessor, not a patch**: `ccx_mode_par_with_pins()` merges the file's pins into
`par_mode` and errors if they disagree — nothing absent, nothing migrated, nothing deleted, and the
canonical needs **no migration at all**. The overlay additionally **errors** on an absent name rather
than deleting it, so the guarantee does not rest on the line above staying correct.

⭐⭐ **MARCUS'S CONSTRAINT WAS HONOURED — nothing here scores anything.** No band, no threshold, no
pass/fail; the script's own *"reported, not gated"* framing is untouched. **Joos and FaIR remain
comparisons, not targets.**

**Gate 12's comparison AT THE SHIPPED MODEL, obtainable for the first time** (reported, never scored):

| | PI background | PD background |
|---|---|---|
| integrated IRF @TH100, `hilda29l` | **35.1 yr** | **41.8 yr** |
| Joos sec 4.4.1, across 10 models | 34–47 | 45–62 |

**The PI < PD ordering Joos requires HOLDS** (35.1 < 41.8) — the sign-level claim survives; the
present-day LEVEL sits below Joos's range. ssp245, 100 GtC in 2050: IRF@20 **0.571**, @50 **0.411**,
@100 **0.307** — agreeing with the **0.314** measured independently through the app's own path in
`diag_pulse_vs_tcre.R`, which is the cross-check that this is the same model the app runs.

---

## 3. The near-ties, resolved on a threshold the data chose

Marcus: *"I like 'influenced about equally by X and Y'."*

| row | now reads |
|---|---|
| δ¹³C level & gradient | **influenced about equally by** High-latitude structure (22 %) **and** Input scalings & reporting (21 %) |
| CO₂ level | mostly influenced by Land uptake (25 %) |
| Δ¹⁴C in the air (bomb) | **influenced about equally by** High-latitude structure (30 %) **and** Input scalings & reporting (29 %) |

⭐ **THE THRESHOLD IS MEASURED.** Across all 12 rows the behaviours separate with a gap and nothing
in it:

| | margins |
|---|---|
| winner **FLIPS** between arms | 0.13, 0.85 pp |
| winner **STABLE** | 3.02, 4.94, 6.78, 6.94, 24.4, … pp |

The cut is the **geometric mean of the two endpoints, 1.597 pp** — equidistant in RATIO (1.9× either
way), the right centring for a separation spanning two orders of magnitude. **Both endpoints are
stored beside it** (`APP_CMAP_TIE_FLIP_MAX`, `APP_CMAP_TIE_STABLE_MIN`) so the cut can be
**re-derived rather than trusted**.

⚠ **It rests on 3 arms × 12 rows.** If a fourth arm lands a row in the gap, **re-derive from the
endpoints; do not nudge the cut** — and the gate asserts the gap is still a gap, so that is what
fails. Re-measure with `calibration/diag_constraint_map_arms.R`.

---

## 4. Non-obvious state

- **Suite: pass 4903 / fail 1 / error 0.** ⚠ The one failure is the **NAMED STANDING RED** that
  `paths.R` documents (`test-mode-file`'s canonical-beats-the-control AIC gate, ruling 2 of 09-19).
  **Do not "fix" it.**
- **New gates, all mutation-tested**: `test-cmap-tie.R` (23; never reporting a tie fails 5, typing
  the threshold outside the gap fails 3). Earlier in the arc: `test-stylised-takeaway.R` (49),
  `test-fair-overlay.R` (29), `test-pulse-linearity.R` (13).
- ⭐ **Two gates now read their CALL SITE, not just their helper** (`test-fair-overlay.R`,
  `test-cmap-tie.R`). That is the 09-26 lesson: a FaIR overlay's gate, written for the
  flattering-NULL failure, passed while the feature drew nothing, because it fed the helper its own
  inputs instead of the caller's ⇒ [[gate_tested_the_helper_not_the_caller]].
- ⚠ **The app on `:7793` predates today's commits** — restart before judging any copy on screen. It
  is a MANAGED launch target: `ccx-app` in **`FaIRtoFrEDI/.claude/launch.json`**, absolute path,
  cold start ~110 s.
- ⚠ `APP_PULSE_LIN_*` and `APP_CMAP_TIE_*` in `global.R` are LABELS for measurements made in
  `calibration/diag_pulse_vs_tcre.R` and `calibration/diag_constraint_map_arms.R`. Their gates
  re-read the drivers' artifacts — but **skip if those are absent**, so a fresh clone will not catch
  a drift until each driver has been run once.
- **No refit, no objective change, no mode file written.** `emissions-interp-constant` (`35f38dc`)
  still rides with the next refit.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.

---

## 5. Recommended order for the next session
1. **The default-arm ruling** (§1a) — now unblocked, and it is the last of the two that have been
   open since 09-26.
2. **Verify the memory symlink** (§1b) — one session start, one question.
3. **Restart the app** before judging any copy on screen.
4. Still open and unstarted: whether the carbon-cycle gap is ever CHASED rather than reported.
   ⚠ It is the **marginal** response that is low, not the scenario level (the emulator tracks FaIR to
   ~0.05 °C on ssp245 at 2100), so the target would be the pulse decay. Marcus ruled 09-04 that the
   long lifetime *should be an emergent behaviour*, and reaffirmed on 09-27 that **FaIR and Joos are
   comparisons, not targets to meet** — so this is a deliberate open question, **not a bug queue
   item**, and any work here must not turn either model into a scoring target.
