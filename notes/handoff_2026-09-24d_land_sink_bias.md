# Handoff — 2026-09-24 (d). **The next session's job is THE LAND-SINK BIAS: the model's land sink runs ~0.3–0.6 GtC/yr HIGH across the whole record, and that one level error is what Q3 and Q1 both turned out to be.** Q3's regrowth justification did not survive measurement. F4 and F5 are shipped; the climate module is on calib 1.6.0; the memory tree was split and cleaned.

> ⚠ **IF YOU ARE A FRESH SESSION: every path here is relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** The standing rule
> launches sessions from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare
> `notes/...` will not resolve. Prefix with the absolute path, or `cd` there.
>
> **Read first, in this order:** CHANGELOG **09-24 (h)** (the Q3 measurement — it is the whole
> brief) · then **§2 and §3 below**.
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY. Read
> **`INDEX_ccx_ref.md`** (land/LUC, likelihood) and **`INDEX_ccx_app.md`** (NEW — the app),
> and `INDEX_ccx_gates.md` for gate 7, before answering anything here.

## 1. ⭐⭐ THE BRIEF: one level error, not two mismatches
`calibration/diag_q3_regrowth_vs_fertilisation.R`, anchored on gate 7's own **3.09** before any
arm was read.

Marcus ruled Q3 ("separate forest regrowth from CO₂ fertilisation") worth pursuing on the strength
of a testable hypothesis: the model crosses land net-source→net-sink in 1971 vs the measured 1989,
and an over-strong single fertilization term doing the work of both would make the sink appear too
early. **Measured, the hypothesis does not hold.**

| prediction | result |
|---|---|
| **P1** — model's land turns net-sink too early | ✅ **reproduces**: model **1970**, measured **1989**, **19 yr** |
| **P2** (the DISCRIMINATING one) — the excess should be LARGEST EARLY and shrink, because regrowth was small early and grew later | ⛔ **fails**: residual-sink excess by decade **+0.31, −0.01, +0.51, +0.16, +0.28, +0.30**; mean **+0.32 GtC/yr**, trend **+0.005/yr (CI −0.002…+0.012)** — **flat** |

⭐⭐ **AND P1 IS NOT INDEPENDENT EVIDENCE.** A constant bias shifts a rising series' zero-crossing
by itself. Remove the mean **+0.62 GtC/yr** NET offset and the model crosses **1987** against the
measured **1989** — **2 years, down from 19**. The measured net flux rises **+0.022 GtC/yr per
year** over 1975–2005, so that offset is worth **~29 years of timing on its own**.

⇒ **P1 and P2 are ONE fact and it is a LEVEL error.** Marcus was right that Q1 (#7b/#15, model
high in the last decade) and Q3 are one investigation — the shared cause is a bias at two ends of
the record, not a missing time-varying process.
⚠ **This is NOT a refutation of forest regrowth in nature**, and not a claim that separating the
terms is physically wrong. It is the narrower, cheaper finding: **this record cannot see the
signature that would justify a new fitted name and a refit.**

## 2. What the next session should actually do
**The question is no longer "add regrowth?" It is "why is the land sink uniformly high, and is
that a defect or a convention?"** In rough order:

1. ⭐ **Check the OBSERVATIONAL side before the model side.** GCB's land sink is a **residual** —
   it absorbs the budget imbalance. GCB's own `imbalance` column is in `data/gcb_budget.rds` and
   is **~1.2 GtC/yr** in the early record. **A +0.32 model-minus-GCB excess sits inside that.**
   ⛔ Do this first: a "model too high" claim against a residual with its own ~1 GtC/yr slack may
   not be a model defect at all. `~/.claude/CLAUDE.md`: a curvature needs an error bar before it
   needs an explanation — so does a bias.
2. **Then ask which side of the partition it is.** The model's ocean sink is **3.13** vs GCB
   **3.20** over 2015–2023 — i.e. the ocean is slightly LOW while the land is high. If the model's
   TOTAL uptake is right and only the SPLIT is off, that is a different (and cheaper) problem than
   a land sink that is absolutely too strong. **Measure atmosphere growth first**: if the model
   reproduces observed CO₂ growth, the total is right by construction and only the split is wrong.
   `dg_annual_sinks()` already returns `growth_ppm` — use it.
3. **Only then consider structure.** If the split IS wrong, the candidates are the fertilization
   strength, the ocean uptake, and `rep_dC`/the LUC scale — all of which are **already fitted
   names**, so re-pricing them is cheaper than a new pool.
4. ⛔ **Do NOT start with a regrowth pool.** §1 is the reason.

## 3. Non-obvious state to carry
- ⭐ **The diagnostic is the brief.** `calibration/diag_q3_regrowth_vs_fertilisation.R` reports
  BOTH conventions separately and never mixes them, because conflating them is this project's own
  32 % bug ([[ccx_app_luc_budget_convention]]): **NET land flux** has land-use emissions INSIDE it
  (model = raw `land_C` change; measured = GCB `land_sink − luc`) and is what crosses zero;
  **RESIDUAL sink** has them OUTSIDE (model = `land_C` change **+ eluc**; measured = GCB
  `land_sink`) and is what gate 7 scores. ⚠ **Ask which one before quoting any number.**
- ⚠ **The 2020–2024 excess is +1.04 (residual) / +1.27 (net)**, far above any earlier decade.
  Five years, on GCB's least-constrained years. **Flagged, NOT interpreted** — do not build on it.
- ⚠ **Gate 7 still PASSES** (land 3.09, z +1.36). This is not a gate failure, so nothing is
  blocking; it is the app's own GCB panel and the recent decade.
- ⛔ **A refit is still expensive but less so than believed.** The emissions-interpolation branch
  measured the objective's sensitivity: a forcing-path change worth **−0.137 log-units** at the
  canonical parameters and **≤0.020 ppm** on the historical CO₂ record. **Every stored logpost
  becomes non-comparable regardless of size** — that is the real cost, and it is a ledger cost.
- ⭐⭐ **BRANCH `emissions-interp-constant` (`35f38dc`) IS NOT MERGED AND SHOULD RIDE WITH THE
  NEXT REFIT.** It makes fossil/LUC emissions piecewise-constant within a year, fixing an acausal
  pulse (3.06 ppm of CO₂ appearing in the 26 years BEFORE a 2050 pulse). Marcus chose it. It
  re-baselines **26 stored-value assertions across 15 files** — all stored logposts/streams, **zero
  real regressions** (verified: 4300 pass / 29 fail / 1 error against a 4-red baseline). ⇒ **If
  the land-sink work triggers a refit, merge this FIRST so the ledger is paid once.**
- ✅ **The climate module is on calib 1.6.0** (`1c5656b`). ECS-equiv 3.243 → 3.060 K, F2× 3.851 →
  3.959, fit RMSE 0.0291 → 0.0220, fitted range top 1687 → **1797 ppm**, span now **1750–2301**.
  ⚠ On the app's own ssp585 path this is **+0.035 °C at 2150 — WARMER, not cooler**, despite the
  lower ECS, because F2× rose and the slow timescale shortened (261→195 yr) and they partly
  cancel. **Do not report "lower ECS ⇒ cooler app".** 2024 is unchanged (the obs splice).
- ⛔⛔ **A DEFECT IN `calibration_v160/` THAT IS STILL UNFIXED AND WILL BITE OTHER DRIVERS.**
  `emissions_v160_cmip7harm_rffsp_central.csv` spells HFC-4310mee's unit **`kt HFC4310/yr`**;
  v145, FaIR and RCMIP all use **`kt HFC4310mee/yr`**. FaIR does not know that compound, so
  `fill_from_csv` takes its novel-compound branch (`fair/io/fill_from.py:95-101`) and **writes
  FaIR's MODULE-LEVEL unit tables**; the **NEXT** scenario's `fill_from_rcmip()` then dies with
  `KeyError: 'HFC4310'`. ⚠ **Scenario 1 passes and scenario 2 fails**, so a single-scenario smoke
  test cannot see it. ⚠ **No number changes** (factor 1.0 either way). **Root cause is the
  payload; the fix belongs in `FaIRtoFrEDI/scripts/setup_calibration_v160.py`.** Not patched,
  because that directory is shared with Ladrillo and the SPRM/EGU work — **any of them that loops
  over scenarios in one process is exposed.** `run_fair_ssps_for_ccx.py` snapshots and restores
  the three tables so it is immune meanwhile.
- ⚠ **A PREVIEW SERVER MAY STILL BE RUNNING** on `http://127.0.0.1:7788` (`lsof -nP -iTCP:7788
  -sTCP:LISTEN -t`; kill THAT, never `pkill -f`). ⭐ `preview_start` still resolves `launch.json`
  from the SESSION root and silently starts the wrong server — start it from Bash with
  `Rscript -e "shiny::runApp('app', port=7788, host='127.0.0.1', launch.browser=FALSE)"`.
  Start-up was **70 s and 140 s** this session at load ~2.5.
- ⚠ **`get_page_text` returns the WRONG TAB**; use
  `javascript_tool: document.querySelector('.tab-pane.active').innerText`. ⭐ `s_kind` is a
  **selectize** input: `el.value=` does nothing, use `$('#s_kind')[0].selectize.setValue('rate')`.
- ⚠ **MARCUS IS EDITING IN PARALLEL.** At the end of this session `deliverables/egu_sprm/
  egu_sprm_memo_draft.docx`, `egu_sprm_memo_skeleton.md` and `egu_deliverables.R` were all dirty
  in **FaIRtoFrEDI** and are **HIS, not this session's** — left untouched and uncommitted.
  ⛔ Per [[marcus_edits_docx_directly]], **diff any returned `.docx` against HEAD and pull his
  prose into the SOURCE before rebuilding**; a rebuild destroys it silently.
- **The three DEPLOY blockers are unchanged and all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs
  (⚠ update `test-review-cards.R` when set, do not delete it), a start-up re-time on an **IDLE**
  machine, and the hosting plan's limits. **W4's ratchet entry is still unratified.**

## 4. Suite state
`main` is at its **4 known reds**, all pre-session and unchanged: `test-mode-file.R` (dAIC, NAMED
RED by ruling), `test-overlay-idiom-lint.R` ×2, `test-seas-lag-split.R` (an encode ERROR, not a
failure). ⛔ **DO NOT READ A GREEN FILTER AS A GREEN SUITE** — this session's
`climate|app|review|driver|growth|future|mechanisms` ran **322 / 0** and touches none of the four.
⚠ The overlay lint still has its blind spot for the `intersect(names(P0), names(pm))` spelling.

## 5. Memory: SPLIT AND CLEANED THIS SESSION (Marcus asked for it explicitly)
- ⭐ **`INDEX_ccx_ref.md` SPLIT → `INDEX_ccx_app.md`** at **18,413 B of its 18,432 hard ceiling**
  (19 bytes). `_ref` is now **13,744 B**, `_app` **7,125 B**. ⚠ **The split line is "would this
  still be true if the app were deleted tomorrow?"** — yes → `_ref`, no → `_app`. **Three items
  moved the OTHER way** because they had been filed by the PANEL that exposed them rather than by
  what they are: `rep_dC`'s tie and prior (likelihood parameters) and the land-sink single term
  (model structure). Straddlers named in `_app`'s header. **Gated**: 57 links in, 57 out, none
  lost, none dangling.
- ⭐ **Root `MEMORY.md` compressed 15,709 → 13,467 B of CONTENT** (soft 12,288, hard 18,432) by
  returning the READ-FIRST block to **pointers**, which is its own stated rule — the accreted
  numbers and parameter counts were each a stale-number risk in an auto-loaded file. **Gated on
  losing no route**; the first attempt dropped two and was corrected. **All 38 sub-indexes on disk
  are reachable from the root, and none is referenced but missing.**
- ⚠ **Still over SOFT, none over hard**: `INDEX_diag.md` 17,291 · `INDEX_ais.md` 16,657 ·
  `INDEX_cmp_pulse.md` 16,642 · `INDEX_ccx_arch_modes.md` 16,010 · `INDEX_ccx.md` 15,716. ⛔ Per
  [[memory_index_split_beats_trim]] **split rather than trim**, and **Marcus asks for splits
  explicitly** — do not restructure unprompted. `INDEX_diag` is the next candidate.
- **Memory written/corrected**: `ccx_pulse_spline_ringing` (new), `ccx_land_sink_single_term`
  (**substantially corrected** — it had asserted the regrowth signature that the measurement
  overturned), `INDEX_ccx_ref`, `INDEX_ccx_app` (new), root `MEMORY.md`, and the sub-index list in
  `FaIRtoFrEDI/CLAUDE.md`.
