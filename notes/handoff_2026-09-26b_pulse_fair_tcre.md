# Handoff — 2026-09-26 (b). **The pulse lab is ~22 % low against standard FaIR at +100 yr and a third low by 2300, and the gap IS the carbon cycle — the climate half is exonerated. The AR6 TCRE is now VERIFIED (the recollection was right). Two placeholder texts replaced, one of which was FALSE on the app's own default. And the whole test suite had been dead for a day.**

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/`. Use absolute paths.
> ⛔ **A bare `cd` into CCX in a Bash call MOVES the session's primary working directory.** It
> happened **twice more this session** despite the last handoff saying so. `cd X && ...` is enough
> to do it — only a `( cd X && ... )` SUBSHELL or `git -C` is safe. Recover with
> `change_directory`; it takes effect at the END of the turn.
>
> **Read first:** CHANGELOG **09-26 (e)**, then **§1** (what is owed) and **§5** (non-obvious state).

---

## 1. What is owed

### (a) ⛔ TWO RULINGS, BOTH SMALL, BOTH BLOCKING SOMETHING
1. **`diag_joos_irf.R`'s default arm.** It runs `ccx_default_params()` when given no argument and
   **cannot run at the canonical at all** (§4b). The fix is to make absence an ERROR — but gate 12
   is Marcus's ruled territory (09-04: *a post-model COMPARISON, not a strict test*) and changing
   the default changes what every past gate-12 number meant. **Not touched.**
2. **`cm_takeaway`'s near-ties** (from 09-26 (b), still open). Two of its three sentences name a
   single holder on **0.1 pp** and **0.8 pp** margins that FLIP between arms. The copy is Marcus's
   and the tie threshold is a methodological choice — derive it from the MEASURED cross-arm spread,
   not an invented pp constant. ⇒ [[ccx_cmap_second_point]].

### (b) ⚠ ONE PLACEHOLDER STILL MARCUS'S
`server.R`'s **`to_zero` sentence is VERBATIM his** and was deliberately not edited. ⚠ It says
*"even when emissions stop"*, and only **FOSSIL** emissions stop: `app_stylised_emissions()` always
takes land use from the background scenario. Flagged for him, not changed.

### (c) Owed to the memory tree
**`INDEX_ccx_ref.md` is 17,019 B of an 18,432 hard ceiling — 1,413 B of headroom**, and is now the
most at-risk file in the tree (it took two additions this session, both since trimmed to pointers).
That is split territory by [[memory_index_split_beats_trim]]. `INDEX_diag.md` was split this
session and is comfortable again at 4,642 B of headroom.

---

## 2. What shipped (CCX `main`, ALL PUSHED except the last commit — check `git status`)

| commit | what |
|---|---|
| `1a457e6` | **the test harness fix** — the suite had been dead since `a6ddf96` |
| `b9de010` | build-your-own takeaway: one branch per pathway, gated |
| `7d9726f` | the pulse-vs-FaIR-vs-TCRE analysis |
| `bb297d8` | CHANGELOG 09-26 (e) |
| `0ff31ed` | **standard FaIR on the futures tab** + the AR6 TCRE **verified** |

Earlier the same day (09-26 a/c/d): the growth-panel estimator fix, the memory consolidation, the
`INDEX_diag` split, and the constraint map's second evaluation point.

FaIRtoFrEDI `heat-ed-morbidity`: `a7e92ce` (the FaIR pulse driver), `7958c59` (CHANGELOG 09-26 f).

---

## 3. ⭐⭐ THE MAIN RESULT: the gap is the carbon cycle

**Why FaIR is the tightest available test, and why it is NOT a validation.** CCX's climate module
**IS** FaIR's 841-config ensemble mean — ERF law fitted to FaIR's Meinshausen-2020 CO₂ forcing,
3-timescale IRF fitted to FaIR's GMST (implied **ECS = Σq·F_2x = 3.06 °C**). So it cannot validate
CCX. What it buys is a **DECOMPOSITION**: with the climate half shared, ΔT ≈ ∝ ΔCO₂, so **compare
ΔCO₂ first** and a matching gap in both is a carbon-cycle result.

Matched, **100 GtC in 2050 on ssp245**, FaIR 2.2.4 calib 1.6.0, 841 configs:

| year | AF ccx | AF fair | ratio | K/1000 ccx | fair | ratio |
|---|---|---|---|---|---|---|
| 2080 (+30) | 0.5088 | 0.5468 | 0.931 | 1.339 | 1.366 | **0.981** |
| **2150 (+100)** | **0.3141** | **0.4687** | **0.670** | **1.082** | **1.390** | **0.779** |
| 2230 | 0.2539 | 0.4376 | 0.580 | 1.025 | 1.447 | 0.709 |
| 2300 | 0.2249 | 0.4130 | 0.545 | 1.005 | 1.489 | 0.675 |

**The two ratio columns track ⇒ the temperature gap IS the airborne-fraction gap.** The temperature
ratio sits slightly ABOVE the carbon ratio at every horizon, which is expected, not a discrepancy:
the thermal IRF integrates the whole forcing HISTORY and CCX's ΔCO₂ was closer early on.

⛔ **Not a constant offset.** FaIR's per-1000 **RISES** with horizon; CCX's **FALLS**. 2 % at
+30 yr, a third by 2300. Quoting the gap at one horizon understates it.

⭐⭐ **IT RUNS THE CONSERVATIVE WAY, and this is the part to lead with.** The app's lesson is that
pulse warming is *permanent rather than borrowed*. **FaIR says it is MORE permanent than CCX shows**
(FaIR still rising at 2300; CCX down to 70 % of peak). The defect **weakens** the app's own argument
rather than inflating it — the same direction `diag_joos_irf.R` reported in August. **It is not a
credibility risk for the app**, which is why it is not a blocker.

**The same shortfall appears in the SCENARIOS**, now visible on the futures tab: the emulator runs
below FaIR by **−0.03 / −0.03 / −0.17 °C** at 2100 and **−0.07 / −0.18 / −0.75 °C** at 2150 for
ssp126/245/585 — a cool bias that **grows with forcing**, i.e. where more carbon is being taken up.
⭐ But at the SCENARIO level the emulation is good (0.05 °C on ssp245 at 2100); the gap is specific
to the **marginal** response, which is consistent — the scenario level is pinned by the CO₂ record
the model is fitted to, and the pulse marginal is not.

⚠ **Two caveats carried, NOT resolved**: the FaIR arm is on **RCMIP-native** ssp245 emissions, not
the CMIP7-harmonized set the 1.6.0 posterior was jointly conditioned on (deliberate — it is what the
CCX module was built from; expected to largely cancel in a MARGINAL, **not measured**). And FaIR's
per-config marginal is **right-skewed**: `median(pulse−base)` runs ~5 % BELOW the mean, so the median
would NARROW this gap, not widen it.

---

## 4. Defects found along the way

### (a) ⛔⛔ THE WHOLE TEST SUITE HAD BEEN DEAD SINCE `a6ddf96`
`Rscript tests/run_tests.R` aborted **during helper sourcing, before any test file ran**.
`helper-code-lines.R`'s own "test 0" read `.root`, which every test FILE defines and no HELPER does,
and helpers are sourced first. **The output read like ONE failing test** — a testthat backtrace
ending *"1 failure and 6 successes"*, which is also what this suite's one legitimate standing red
looks like. Baselines: **4773 → zero tests reached → 4868**, same single documented red.
⭐ **Read the PASS COUNT, not the verdict.** ⇒ [[broken_harness_hides_the_whole_suite]].

### (b) ⛔ GATE 12'S ONLY IMPLEMENTATION MEASURES A MODEL NOBODY SHIPS
`diag_joos_irf.R` with no argument uses `ccx_default_params()`. Pulse AF@100 on ssp245:
**`defaults` 0.445** vs **`hilda32f` 0.304** vs the app's canonical **0.314** — a 42 % overstatement.
`hilda29l` **errors outright** (the canonical pins the ocean ENSO shim and fits `w_enso_l2`; the
migrator does not know that shape). ⭐ The script says *"absence must ASSERT"* two lines above
`if (!length(a)) return(JOOS_ARM_DEFAULT)`: **the typo case was fixed, the missing case was not.**
⇒ [[ccx_joos_diag_default_arm]]. **Awaiting a ruling (§1a).**

### (c) The takeaway clause was FALSE on the app's own default
*"a fixed rate only ever approaches zero"* — `s_rate` spans −5…+5 and **defaults to +1**, so the
default pathway grows. One string covered three pathways by disjunction. Now one branch per pathway
on the SIGN of the rate, extracted to a pure function so it can be gated at all (it was unreachable
inside a `renderText`). Mutation-tested: the old clause fails **37 of 45**.

---

## 5. Non-obvious state

- **Suite: pass 4868 / fail 1 / error 0.** The one failure is the **NAMED STANDING RED** that
  `paths.R` documents (`test-mode-file`'s canonical-beats-the-control AIC gate, ruling 2 of 09-19).
  ⚠ **Do not "fix" it.**
- **New gates, all mutation-tested**: `test-stylised-takeaway.R` (45), `test-pulse-linearity.R` (13),
  `test-fair-overlay.R` (21). The overlay gate exists for the **FLATTERING NULL** — `APP_FAIR`
  carries `gmst_C` where a run carries `gmst`, so one wrong lookup draws no line, which on screen is
  indistinguishable from "FaIR agrees perfectly".
- **The AR6 TCRE is VERIFIED and the units are the trap.** AR6 states it **per 1000 GtCO₂**
  (0.45, likely 0.27–0.63); this model works in **GtC**; the factor is **3.664**, bigger than the gap
  under investigation. The conversion is now done IN CODE from the AR6-native numbers with a
  **GATE UNITS** requiring it to reproduce AR6's own printed per-GtC range (0.99–2.31 vs 1.0–2.3).
  Sources: AR6 WG1 SPM D.1.1; corroborated locally by Forster et al. 2026, ESSD 18, 3889.
- **New artifacts**: `data-raw/downloads/fair_v160_pulse/` (the FaIR pulse CSV + provenance sidecar +
  MANIFEST with sha256), `outputs/diagnostics/pulse_vs_tcre_20260926.{csv,log}`,
  `outputs/diagnostics/constraint_map_{hilda32f,hilda31pe}.rds`.
- **The FaIR driver lives in FaIRtoFrEDI**, not CCX — CCX's CLAUDE.md makes "no FaIR dependency" a
  hard rule, so it crosses the boundary as a provenance-stamped CSV, exactly as the climate module
  does. Its **pulse year is now a CLI argument** (`--pulse-year`, default 2050); it was 2030, which
  was NOT like-for-like with the tab.
- **The FaIR overlay is WITHHELD from "Build your own"** — FaIR was never run on an invented pathway.
- ⚠ **`APP_PULSE_LIN_*` and `APP_PULSE_PER1000_BY_HORIZON` in `global.R` are labels for a measurement
  made in `diag_pulse_vs_tcre.R`.** `test-pulse-linearity.R` re-reads the driver's CSV and fails if
  they drift — but it SKIPS if the CSV is absent, so a fresh clone will not catch a drift until the
  driver has been run once.
- **No refit, no objective change, no mode file written.** `emissions-interp-constant` (`35f38dc`)
  still rides with the next refit.
- ⭐ **The app WAS restarted on current code and driven** (`:7793`, cold start **110-111 s**, HTTP
  200, no load errors). It is now a MANAGED launch target: `ccx-app` in
  **`FaIRtoFrEDI/.claude/launch.json`** with an absolute path, because sessions always start from
  FaIRtoFrEDI. It had been a stray `nohup` from a previous session, 7 h old and on stale code.
- ⛔⛔ **AND DRIVING IT IMMEDIATELY FOUND A BUG THE WHOLE SUITE MISSED.** The FaIR overlay drew
  **nothing** -- `future_runs()` names its runs with display LABELS and `APP_FAIR` is keyed on IDS --
  which on screen is indistinguishable from "FaIR agrees perfectly". Its own 21-assertion gate,
  written for exactly that failure, passed, **because it fed the helper ids while the app passed
  labels: it tested the HELPER's contract, not the CALLER's.** Fixed (`1e962ff`) and the gate now
  drives the server's own expression AND reads the call site (mutation: 2 fail).
  ⚠ **The rendered PNG in the previous handoff was NOT independent evidence** -- it was built from my
  own call with the ids, so it reproduced the wrong assumption faithfully and in color
  ⇒ [[gate_tested_the_helper_not_the_caller]].
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.
- ⛔ **The CarbonCycleEmulator memory symlink is STILL UNVERIFIED against the harness** (owed since
  09-26 a). One-line test: start a session in `CarbonCycleEmulator/` and ask what `INDEX_ccx.md`
  gives as the canonical mode; an answer without reading a file means it loaded.

---

## 6. Recommended order for the next session
1. **The two rulings in §1(a)** — each is one question and each unblocks a concrete edit.
2. **Marcus's eye on the two new copy blocks** (the pulse permanence box and the build-your-own
   clause), and on the `to_zero` fossil-only wording in §1(b).
3. **Split `INDEX_ccx_ref.md`** (§1c) — 1,413 B from its hard ceiling, now the most at-risk file.
4. **Verify the memory symlink** — one session start, one question.
5. If the carbon-cycle gap is ever to be CHASED rather than reported: it is the **marginal** response
   that is wrong, not the scenario level, so the target is the pulse decay, and gate 12 needs a
   working implementation first (§1a). ⚠ Marcus ruled 09-04 that the long lifetime *should be an
   emergent behavior*, so this is a deliberate open question, not a bug queue item.
