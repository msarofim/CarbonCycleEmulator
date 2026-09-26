# Handoff — 2026-09-26 (c). **"Fossil" added where the control is fossil-only; `INDEX_ccx_ref` split (no index is in split territory now); the app restarted on current code — which immediately found a shipped feature that drew NOTHING while its own gate passed.**

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/`. Use absolute paths.
> ⛔ **`cd X && ...` in a Bash call MOVES the session's primary working directory** — a subshell
> `( cd X && ... )` or `git -C` is required. It happened twice this session even with the warning in
> front of me. Recover with `change_directory`; it lands at the END of the turn.
>
> **Read first:** CHANGELOG **09-26 (g)**, then **§1** (what is owed) and **§4** (non-obvious state).
> This supersedes `handoff_2026-09-26b_pulse_fair_tcre.md` for STATE; that file keeps the
> pulse/FaIR/TCRE **measurements**, which are unchanged.

---

## 1. What is owed

### (a) ⛔ TWO RULINGS — unchanged, and both explained at length to Marcus on 09-26
1. **`diag_joos_irf.R`'s default arm.** No argument ⇒ `ccx_default_params()`, which is not the
   shipped model (pulse AF@100 **0.445** vs the canonical's **0.314**); and `hilda29l` **errors
   outright**. Gate 12 is Marcus's ruled territory (09-04: *a COMPARISON, not a strict test*), and
   changing the default changes what every past gate-12 number meant ⇒
   [[ccx_joos_diag_default_arm]]. **Not touched.**
2. **`cm_takeaway`'s near-ties.** Two of its three sentences name a single holder on **0.1 pp** and
   **0.8 pp** margins that FLIP between arms. The copy is Marcus's; the tie threshold is a
   methodological choice and should come from the MEASURED cross-arm spread, not an invented pp
   constant ⇒ [[ccx_cmap_second_point]].

### (b) Carried over, still unverified
⛔ **The `CarbonCycleEmulator` memory symlink has never been tested against the harness** (owed since
09-26 a). **One-line test**: start a session in `CarbonCycleEmulator/` and ask what `INDEX_ccx.md`
gives as the canonical mode; an answer without reading a file means it loaded. Until then, **keep
launching from `FaIRtoFrEDI/`**.

### (c) NOT owed any more
The memory tree is clear: `INDEX_ccx_ref` was split (§3) and **the tightest index is now
`INDEX_ais.md` at 1,775 B — nothing is in split territory.**

---

## 2. ⛔⛔ THE LESSON OF THE DAY: the app was restarted, and LOOKING found what the suite could not

The FaIR overlay shipped earlier the same day **drew no line at all**. `future_runs()` names its runs
with the DISPLAY labels (`"SSP2-4.5  (middle of the road)"`) while `APP_FAIR` is keyed on the ids
(`"ssp245"`); the server passed `names(rs)`, nothing matched, the helper returned NULL.
⭐ **On screen that is indistinguishable from "FaIR agrees perfectly."**

⛔⛔ **ITS OWN 21-ASSERTION GATE, WRITTEN FOR EXACTLY THAT FAILURE, PASSED** — because it asserted
`app_fair_overlay(c("ssp126", …))` returns rows, i.e. it **tested the HELPER's contract and the bug
was in the CALLER's**. A gate that chooses its own inputs tests the function it points at, not the
feature. Fixed, and the gate now (1) drives the server's own expression, read out of `global.R`
rather than retyped, and (2) **reads the call site** — (1) alone still passes on a revert.
Mutation-tested: the original bug fails 2.

⚠⚠ **AND THE RENDERED PNG WAS NOT INDEPENDENT EVIDENCE.** Rendering the plot to a file and inspecting
it FEELS like looking at the thing; it was driven from my own call with the ids, so it reproduced the
wrong assumption faithfully and in colour. **A picture built from the same wrong input proves
nothing.** The defect surfaced in the first thirty seconds of the app actually running
⇒ [[gate_tested_the_helper_not_the_caller]].

---

## 3. What shipped (CCX `main` + FaIRtoFrEDI `heat-ed-morbidity`)

| commit | what |
|---|---|
| `1e962ff` | **the overlay fix** + the gate that now tests the caller |
| `fd2d645` | CHANGELOG 09-26 (g), and the 09-26 (b) handoff corrected |
| `ac01687` | **"fossil emissions"** where the control is fossil-only |
| (FaIRtoFrEDI) `d426889` | register `INDEX_ccx_inputs` |
| (FaIRtoFrEDI) `93e28d2` | a MANAGED launch target for the app |

**The "fossil" pass (Marcus's instruction).** Two places overstated the controls' reach:
- `app_stylised_tail_clause()`'s **`to_zero`** branch — his own sentence, flagged and left verbatim
  last round — said *"even when emissions stop"*. Only **fossil** emissions stop:
  `app_stylised_emissions()` always takes land use from the background scenario, so the pathway's
  TOTAL CO₂ emissions never reach zero. The slider is already labelled *"Fossil emissions after
  today"*, so the sentence now matches its own control.
- The futures tab's *"Where the future temperature comes from"* box said the pulse lab and
  build-your-own *"only allow changes to carbon emissions"*. Both change **fossil** CO₂ only, so it
  claimed a wider reach than either has. Now "fossil carbon emissions", with **land-use change named
  in the list of what the user cannot move**.
- ⚠ **Left alone deliberately**: *"the model's inputs are emissions, …"* (true of both) and *"the
  natural land sink grew until it outweighed those emissions"* (that passage IS about land use).
- A new test asserts **all four** pathway branches scope the claim to fossil — the SCOPE, not the
  wording, so it survives Marcus editing the prose. Mutation-tested: dropping "fossil" fails 1.

**The index split.** `INDEX_ccx_ref` 17,019 B (1,413 B of headroom) → **`INDEX_ccx_inputs.md`**.
Line: **"how is the model SCORED?"** (`_ref`: likelihood, the two parameter lists, what each stream
constrains) vs **"what is FED to it, and which tracer separates what?"** (`_inputs`: the emissions
and LUC drivers, the GCB budget conventions, the ¹⁴C partition). ⭐ **The two moved sections travel
TOGETHER on purpose** — `ccx_emis_input`'s whole point is that fossil and LUC are **not** degenerate
BECAUSE Δ¹⁴C separates them, so filing the emissions split away from the tracer that resolves it
would be routing by panel rather than by subject. 11,899 B / 9,266 B after, both under soft.
Six straddlers named in `_inputs`'s header. Conservation 29/29; orphan sweep 0/0 on 775 topics.

---

## 4. Non-obvious state

- **Suite: pass 4876 / fail 1 / error 0** before the "fossil" pass (which added assertions and ran
  clean on its own file). ⚠ **The one failure is the NAMED STANDING RED** `paths.R` documents
  (`test-mode-file`'s canonical-beats-the-control AIC gate, ruling 2 of 09-19). **Do not "fix" it.**
- ⭐ **The app is a MANAGED launch target**: `ccx-app`, port **7793**, in
  **`FaIRtoFrEDI/.claude/launch.json`** with an ABSOLUTE path (sessions always start from
  FaIRtoFrEDI). It had been a stray `nohup` from an earlier session — 7 h old, on stale code, nothing
  tracking it. **Cold start 110–111 s**, consistent with the 115–128 s on record; still **not** the
  idle re-time that is a deploy blocker. `CarbonCycleEmulator/.claude/launch.json` keeps its own
  entry on port 7788 for sessions that do start there.
- ⚠ **The running instance predates the "fossil" commit** (`ac01687`) — restart it before reading
  that copy on screen.
- **Gates added today, all mutation-tested**: `test-stylised-takeaway.R` (49),
  `test-pulse-linearity.R` (13), `test-fair-overlay.R` (29).
- ⚠ `APP_PULSE_LIN_*` / `APP_PULSE_PER1000_BY_HORIZON` in `global.R` are LABELS for a measurement
  made in `calibration/diag_pulse_vs_tcre.R`. The gate re-reads the driver's CSV — but **SKIPS if
  the CSV is absent**, so a fresh clone will not catch a drift until the driver has been run once.
- **The AR6 TCRE is VERIFIED and the UNITS are the trap**: AR6 states it **per 1000 GtCO₂** (0.45,
  likely 0.27–0.63); the model works in **GtC**; the factor is **3.664**, bigger than the gap under
  investigation. The conversion is done IN CODE with a `GATE UNITS` reproducing AR6's own printed
  per-GtC range. Sources: AR6 WG1 SPM D.1.1; Forster et al. 2026, ESSD 18, 3889.
- **No refit, no objective change, no mode file written.** `emissions-interp-constant` (`35f38dc`)
  still rides with the next refit.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.

---

## 5. Recommended order for the next session
1. **The two rulings in §1(a).** Both were explained in full on 09-26; he has what he needs.
2. **Verify the memory symlink** (§1b) — one session start, one question.
3. **Restart the app** before judging any copy on screen (§4).
4. Still open and unstarted: whether the carbon-cycle gap is ever to be CHASED rather than reported.
   ⚠ It is the **marginal** response that is wrong, not the scenario level (the emulator tracks FaIR
   to ~0.05 °C on ssp245 at 2100), so the target is the pulse decay — and gate 12 needs a working
   implementation first (§1a). Marcus ruled 09-04 that the long lifetime *should be an emergent
   behaviour*, so this is a deliberate open question, **not a bug queue item**.
