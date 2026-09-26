# Handoff — 2026-09-26. **Marcus's 09-25 comment doc is 10/13 shipped; then chasing his Pinatubo question found a LIKE-FOR-LIKE DEFECT in the growth panel that RETRACTS most of the 09-25 (j) finding.** The global-growth objective row he asked for is **NOT built, deliberately** — its premise dissolved. Memory consolidated: the root was split twice and is back under budget.

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/`. Use absolute paths.
> ⛔ **A bare `cd` into CCX in a Bash call MOVES the session's primary working directory.** It
> happened **three times** this session despite the warning in the last handoff. Use
> `git -C <abspath>` and `(cd <abspath> && …)` subshells. Recover with the `change_directory`
> tool — it takes effect at the END of the turn.
> ⭐ **NEW 09-26: a `CarbonCycleEmulator` memory key now exists**, symlinked to the FaIRtoFrEDI
> store — but the HARNESS side is UNVERIFIED (see §5). Keep launching from `FaIRtoFrEDI/` until
> someone tests it.
>
> **Read first:** CHANGELOG **09-26 (a)**, then **§1** (what is owed) and **§4** (non-obvious state).
> Before touching the app: `INDEX_ccx_app.md`. Before quoting any 1991 number:
> `pinatubo_miss_is_the_gcb_imbalance.md` — it is **half retraction**.

---

## 1. What is owed

### (a) ⛔ MARCUS'S RULING ON THE GLOBAL-GROWTH OBJECTIVE ROW
He asked (09-26): *"Add the global growth objective and refit the model."* **I did not build it,
and stopped before the refit.** The premise was "a big 1991 error the objective cannot see";
measured like-for-like there is **no big 1991 error** (+0.428, 1.1 σ). Three objections stand and
are his to rule on:

1. **Near-redundant** — growth = emissions − ocean − land, and `gcb_ocean_sink` / `gcb_land_sink`
   are already scored. Adding growth **over-determines a system GCB does not close** (imbalance
   up to 2.1 GtC/yr).
2. **Very loud** — the observation is ±0.07–0.12 ppm/yr against sink sigmas of 0.4–0.5 GtC/yr,
   over 45 points. `likelihood.R` already notes the CO₂ stream outvotes the partition rows 40:1.
3. **Fights a known shortfall** — model interannual scatter **0.27** vs observed **0.44** (review
   card 4 / GATE V). Likely outcome: the partition sacrificed to buy growth, reversing the
   09-16 (d) `LIK_LAND_SINK_INFLATE` 3.0 → 1.0 decision.

**If he says build it anyway**, settle FIRST (they change the refit's answer, and the refit is the
expensive part): the **sigma** (representation error for a 2-box global), whether the **sink rows
get downweighted** alongside it, and the **estimator** (now unambiguous — annual-mean differences).
⭐ **Torch verdict, already stated out loud:** YES for the refit. It is the 24-start dispersed
multistart, and `run_dispersed_multistart.R`'s own header says a serial port is *measured to lose*
while the array "is what makes Torch win".

### (b) ⚠ TWO PLACEHOLDER TEXTS STILL AWAIT HIS COPY
1. **`server.R`, the *Build your own* takeaway, non-`to_zero` branches** — unchanged since
   handoff (b). Correct but the pedagogy is mine.
2. **NEW: the pulse-lab permanence box** (`output$f_pulse_permanence`). He ruled *"I draft, you
   edit"*, so the prose is mine and flagged; **the numbers are measured from the run** (0.108 °C
   a century later from 100 GtC = **1.08 °C per 1000 GtC**, 70 % of peak still at 2300).
   ⚠ **Worth his eye**: 1.08 is low-side. My *recollection* — not a citation — is AR6 TCRE ≈ 1.65
   (likely 1.0–2.3) per 1000 GtC. It is also **not the same quantity** (pulse-on-scenario, not
   cumulative-along-a-pathway), which is why the copy deliberately never says "TCRE".

### (c) Owed to the memory tree, not to Marcus
**`INDEX_diag.md` is at 17,291 B of an 18,432 hard ceiling — 1,141 B of headroom.** Per
[[memory_index_split_beats_trim]] that is SPLIT territory, and it is now the most at-risk file in
the tree. It has been split twice already (`_design` 09-08, `_conv` 09-23), so a third split line
needs choosing with care — **route on the SUBJECT, not the finder**, which is the lesson from the
09-23 split.

---

## 2. What shipped (6 commits, CCX `main`, **ALL PUSHED**, tree clean at `ebb4cca`)

| commit | what |
|---|---|
| `a6ddf96` | reframe "What pins down what?" from *testing* to *influence* (his paras 10–16) |
| `b0ee385` | ENSO switch: say the temperature half keeps running (para 4) |
| `a68633b` | multi-select switches + residual strip + pulse-permanence box (paras 2, 3, 8) |
| `2ddda51` | a zero LEVEL difference is not a zero effect |
| `ad8cbca` | CLAUDE.md: the shared memory keyspace |
| `f6742f0` + `ebb4cca` | **the growth panel's estimator mismatch** + CHANGELOG |

⭐ **10 of Marcus's 13 comment items are in.** Not done: the objective row (§1a), and nothing else
outstanding from the doc.

---

## 3. ⛔⛔ THE FINDING, AND WHAT IT RETRACTS

`app_annual_growth()` differences **annual means**. GCB's `atm_growth` is NOAA's published
`co2_gr_gl` (GCB's header cites NOAA/ESRL for the column) and is a **Jan-to-Jan** difference of the
**deseasonalised** series. The panel compared one to the other; its caption said *"annual means
differenced"* while half its data was not.

⚠ **Not a bias — a RESHUFFLE.** Model RMS **0.397 either way**. What moves is which year is worst:

| 1991 | model | obs | resid |
|---|---|---|---|
| mismatched (shipped) | 1.768 | 0.750 | **+1.018 — "worst year"** |
| matched | 1.768 | **1.340** | **+0.428 — 1.1 σ** |

⭐ **Gate the RANKING, not just the aggregate** ⇒ [[two_estimators_of_one_quantity]].

**RETRACTED from 09-25 (j)**: *"the 1991 residual IS GCB's unclosed imbalance"* (matched: corr
0.482, slope 0.526 ± 0.146, R² 0.232 — not 0.781/0.819/0.610), and *"Mauna Loa runs 0.50 ppm/yr
above the global"* (on one estimator MLO 1.252, SPO 1.332, NOAA 1.340 — they agree).
**SURVIVES**: every volcanic-timing number, because those are knockout differences *within* one
estimator. Marcus's three original readings are all confirmed.

⭐ **The fix direction was NOT obvious and measurement chose it.** I argued for moving the MODEL to
calendar-year boundary differencing (matching the objective's `gcb_*_sink` rows and GATE 4).
**Measured: worse** — RMS 0.397 → 0.491, worst year 2024 −1.600 (end-extrapolation) — because it
re-injects the model's seasonal-cycle error. `app_annual_growth()`'s own header had already said so.
Marcus's instinct was right.

---

## 4. Non-obvious state

- ⭐ **EVERYTHING IS PUSHED.** `main` = `ebb4cca`, 0 ahead of `origin/main`, tree clean. (The 13
  commits the last handoff left unpushed went up on his say-so this session.)
- **ONE app instance, `:7793`**, on the current code, HTTP 200. ⚠ Cold start **~128 s** at load
  2.8 — consistent with the ~115–120 s already recorded, and still **not** the idle re-time that
  is a deploy blocker.
- **New data artefact**: `data/mbl_global_growth.rds`, built by
  `data-raw/build_mbl_global_growth.R`. ⭐ **No new download** — NOAA's MBL global reference was
  already in the repo (manifest key `mbl_zonal_gl`); the build **verifies its sha256 against the
  MANIFEST**. Cross-checked against NOAA's `co2_annmean_gl`: levels agree to −0.012 ppm, growth to
  sd 0.026 ppm/yr.
- ⚠ **The growth panel now starts 1980, not 1959** — the MBL reference begins 1979. Stated in the
  chart caption. GCB calls its own growth uncertainty *"variable … around 0.2 GtC/yr FROM 1980"*,
  so the lost years are the least certain — but they are lost.
- **Signature change**: `gcb` → `obs` in `plot_growth_rate()`, `plot_growth_resid()`,
  `app_growth_residuals()`. Every caller grepped **and the app driven**.
- **Gates**: `test-growth-residuals.R` gained block (d) — the observed series is re-derived from
  the levels the object ships; the retired wiring must return NULL (`[[` not `$`); and a POWER test
  requires the two estimators to stay far apart. **Mutation-tested: 6 assertions fail.**
  ⚠ The suite's own counterfactual test was still passing the GCB table — the new guard caught it.
- **New shared test helper**: `tests/testthat/helper-code-lines.R`, one quote-aware comment
  stripper, replacing two byte-alike copies. Carries its own test 0 including the hex-colour case.
- **No refit, no objective change, no mode file written.** `emissions-interp-constant` (`35f38dc`)
  still rides with the next refit.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.

---

## 5. The memory tree (consolidated 09-26)

- **Snapshot before the pass**: `../memory_backup_20260926/` (806 files), outside `memory/` as usual.
- **TWO SPLITS.** Root content was **17,268 B against an 18,432 hard ceiling** — 1,164 B of
  headroom, i.e. split territory, not trim territory.
  1. ⭐ **NEW `INDEX_fredi_vehicle.md`** — FrEDI, the vehicle rule, SC-CO2, the SPRM mirror, county
     heat. **It was the only major domain with no sub-index**, so its bullets grew in the
     auto-loaded root where every session in every project pays for them. Registered in both the
     root and `FaIRtoFrEDI/CLAUDE.md`.
  2. **Nine gate-incident bullets → `INDEX_conv.md`** — the root had re-accumulated exactly what
     the 09-10 split created that file to hold.
  **Root: 17,268 → 11,995 B**, under its 12,288 soft. **Orphan sweep: 767 topic files, 0 orphaned**
  (the rule requires proving nothing was lost).
- ⚠ **`INDEX_conv.md` is now 15,483 B, over its 14 KB soft.** Deliberate: it does not auto-load and
  the root does.
- ⛔⛔ **A MEASUREMENT TRAP, newly recorded**: my first survey counted **characters**, not bytes,
  and understated every index by 2–4 % on its ⭐/⛔/⚠ glyphs — enough to report `INDEX_ccx_app.md`
  as under soft when it was over. **Count `len(s.encode('utf-8'))` after stripping `<!-- -->`.**
  ⇒ [[memory_budget_is_content_not_file]], which now carries both halves of the trap.
- **`pinatubo_miss_is_the_gcb_imbalance.md` restructured** so the current reading leads and the
  superseded one is quarantined at the bottom under "do not re-quote".
- **New memories**: [[two_estimators_of_one_quantity]], [[memory_keyspace_follows_launch_cwd]].
- ⛔ **The CarbonCycleEmulator memory symlink is UNVERIFIED against the harness.** Filesystem
  checks all pass (same inode, 803 files, write-through, snapshots resolve). Whether Claude Code
  follows the symlink when it loads `MEMORY.md` at session start has NOT been tested. **One-line
  test:** start a session in `CarbonCycleEmulator/` and ask what `INDEX_ccx.md` gives as the
  canonical mode; an answer without reading a file means it loaded.

---

## 6. Recommended order for the next session
1. **Get Marcus's ruling on §1(a)** — the objective row. One question, and it decides whether the
   next big block of work is a refit.
2. **His copy for the two placeholders** (§1b), and a glance at the 1.08 °C/1000 GtC figure.
3. **Split `INDEX_diag.md`** (§1c) — 1,141 B from its hard ceiling, the most at-risk file.
4. **Verify the memory symlink** (§5) — one session start, one question.
5. Still open and unstarted since 09-25 (b): whether the constraint map wants a **SECOND evaluation
   point** (e.g. the quarantined `hilda31pe` control, ~50 s) to say whether the pins/pulls picture
   is a property of the MODEL or of THIS fit. **A real choice, not a chore.**
