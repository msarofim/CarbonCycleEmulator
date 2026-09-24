# Handoff — 2026-09-24 (e). **The next session's job is REGROWTH TIER 1: report forest regrowth as its own number by UN-NETTING the prescribed LUC input, with NO refit.** Marcus ruled Tier 1 (09-24). The land-sink and growth-deficit investigations are CLOSED — both came back "not a model defect" — and two fixes landed (the v160 unit defect, the pulse-lab acausality).

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare `notes/...` will not
> resolve. Prefix with the absolute path, or `cd` there.
>
> **Read first, in this order:** CHANGELOG **09-24 (i)**, **(j)**, **(l)** · then **§1 and §2**.
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY. Read
> **`INDEX_ccx_ref.md`** (land/LUC; the new land-sink entry is there) and **`INDEX_ccx_app.md`**
> before answering anything here.

---

## 1. ⭐⭐⭐ THE BRIEF: regrowth Tier 1, and why it is free

**Marcus, 2026-09-24:** *"I feel like adding forest regrowth as its own number would still be
useful (and then assume that it decays to zero in the future)."*

⚠ **This is NOT the proposal that 09-24 (h) refuted.** That one was a **fitted** regrowth pool
justified by the early source→sink crossing. This one is a **prescribed, reported number** with a
specified future decay. The distinction is the whole cost.

### Why it costs nothing: CCX already contains regrowth, netted invisibly
In GCB's accounting, forest regrowth on abandoned land is **already inside E_LUC** — the bookkeeping
models compute net E_LUC as **gross deforestation emissions − gross regrowth removals**. The
residual land sink is the response of land to CO₂ and climate. **GCB already separates regrowth from
fertilisation**; they just live in different terms. CCX takes GCB's **net** E_LUC as a prescribed
input (`DATA.md:105`, "GCB 2025 bookkeeping").

⇒ **"Adding regrowth" is un-netting an input the model already has**, not adding a process.

| tier | what it is | cost | status |
|---|---|---|---|
| **1. Reported number** | Split the prescribed LUC input into gross emission + gross removal. Report both, plot regrowth, prescribe its future decay. | **Model output bit-identical. NO refit. Objective #13 untouched.** | ⭐ **MARCUS CHOSE THIS** |
| 2. Two signed fluxes | Same split applied as real opposite-signed fluxes with distinct isotopes — deforestation releases old wood, regrowth takes up contemporary atmosphere. | **Moves scored δ¹³C / Δ¹⁴C rows ⇒ REFIT.** Merge `emissions-interp-constant` first. | not chosen |
| 3. Fitted regrowth pool | A new pool and fitted name. | What (h) measured against. | ⛔ still unsupported |

⚠ **Tier 1's number is ASSERTED FROM GCB's BOOKKEEPING MODELS, not measured by CCX.** The app must
say so. (h) showed this record cannot see the split; Tier 1 does not change that, it imports it.

### ⛔⛔ THE FIRST STEP MAY FAIL — GROSS COMPONENTS ARE NOT IN THE REPO
Checked 09-24: `data/gcb_budget.rds$budget` carries **net `luc` only** (columns: year, fossil, luc,
atm_growth, ocean_sink, land_sink, cement_carbonation, imbalance). `data-raw/downloads/MANIFEST.csv`
has **no gross/regrowth entry**; the OSCAR v3.1 workbook already used for pre-1850 E_LUC and the NH
share is also **net**. GCB publishes gross fluxes in its full workbook in recent editions, **but I
have NOT verified which sheet/columns the 2025 edition carries.**
⇒ **Step one is acquisition, and it is the risk.** If the gross split is unavailable at annual
resolution for 1750–2024, Tier 1 as specified cannot be built from observation and the choice goes
back to Marcus (a prescribed regrowth KERNEL driven by past clearing would be the fallback — but
that is a modelling assumption, not an observation, and must be labelled as one).

### Design notes for whoever builds it
- **"Decays to zero in the future" falls out for free** if regrowth is driven by past clearing: as
  LUC emissions go to zero in the SSPs, so does regrowth. **Confirm that is what Marcus means**
  rather than a separately prescribed decay — it is a methodological choice and the standing rule
  says flag it.
- **Both halves must sum to the existing net input, exactly**, and that should be a GATE. If it
  does not close, the model's forcing has changed and the "no refit" claim is void.
- `f_luc_perm` defaults to **1** (`CCX_F_LUC_PERM_DEFAULT`, `R/model.R:125`) and is **not fitted** —
  cleared land stays cleared, so there is no existing regrowth flux to read off the model. There IS
  a post-clearing internal redistribution (`src/ccx_core.cpp:557`, wood below its new equilibrium
  vs soils above) but it **nets to zero in total carbon** and is not the quantity wanted.

---

## 2. What CLOSED this session (do not re-open)

### (i) The land-sink "bias" is NOT a model defect ⇒ [[ccx_land_sink_is_gcb_imbalance]]
`calibration/diag_land_sink_bias_budget.R`. Both budgets close, so the difference is an **exact
identity** (closes 3.2e-14), not a comparison. Over 1959–2024 the **+0.32 GtC/yr** decomposes as
GCB's own **unclosed imbalance +0.54**, plus the **cement sink the model lacks +0.09**, less the
fitted **`luc_scale` −0.30**; growth and ocean ±0.05. **Nothing unexplained.**
⛔⛔ **The 09-24 (d) handoff's premise was backwards**: GCB's land sink is **not** the residual — the
**IMBALANCE** is (tested; the land sink is an independent DGVM estimate). And the imbalance is
**POSITIVE**, so GCB's own sinks are too small to close its budget and a **larger** model sink moves
**toward** closure.
⭐ **Transferable: when two budgets each close, decompose the difference — do not compare one term.**

### (j) The growth deficit is ~1.6 se, and is DECADAL ⇒ same memory file
`calibration/diag_growth_deficit.R`. Against the deficit's **own** scatter (sd 0.864, lag-1 ρ
−0.051): **2015–2023 = 1.6 se**, 2020–2024 = 2.4 se. ⚠ (i)'s "persistent, median ≈ mean" was
robustness to outliers, **not significance**. What signal there is is **decadal** (−0.48 vs +0.04
interannual) and the **GATE V shortfall cannot produce it** (β = 0.261; it could manufacture at most
+0.09 — an order of magnitude too small **and the wrong sign**). The decadal term is an **AF
difference that FLIPS SIGN** (+0.09 full record, −0.37 in 2015–23), which is why nothing accumulates.
⛔⛔ **The 1980s (−0.44) are NOT a precedent** — same size, but interannual not decadal.
⚠ **2020–24 is NOT attributable** (unstable across the smoother; 2024 carries half).
⭐ Incidental: **β 0.261 vs sd ratio 0.59 ⇒ GATE V's sd statistic is BLIND TO PHASE.** Recorded, not
acted on — a gate is a DESIGN decision and Marcus takes those.

### (k) The figure ⇒ `calibration/fig_land_sink_vs_gcb.R`
Both conventions drawn (residual sink + net land flux), 5-yr centred smooth (**Marcus's request —
NOT the app's `APP_LUC_SMOOTH_YR` = 11**), GCB's imbalance as a band. ⚠ Band containment measured,
**not eyeballed**: **4 of 7 decades inside** (1970s misses by 0.01, 1980s by 0.20, **2020–24 by
1.04** — the one real excursion). Colours **computed** — the repo's `#B03060`/`#1F4E79` scored
protan ΔE 7.9, re-stepped to `#C2185B`/`#12395C`.

---

## 3. The two fixes that landed

### ⭐ The `calibration_v160` unit defect — FIXED, but ON THE WRONG BRANCH
⇒ **[[fair_unknown_unit_mutates_global]]** (a memory that **already existed** and anticipated the
alias-list trap — read it before touching this).
⛔ **The (d) handoff misattributed it twice**: `setup_calibration_v160.py` **does not exist**, and
the file it named was **already clean**. It was `emissions_v160_cmip7_ssp245_harmonized.csv`, from
`scripts/build_emissions_v160_ssp245.py`.
⛔⛔ **The canonical spelling is NOT one side of the alias pair** — FaIR wants `kt HFC4310mee/yr`
(second) but `Mt NO2/yr` for NOx (**first**). Normalising to one side would have broken the other.
⚠ **Commit `b1889af` is on branch `heat-ed-morbidity`, not `main`** — unrelated to that branch's
topic; **may want cherry-picking**, and it is **not pushed**.
⚠ `calibration_v160/` is gitignored ⇒ re-run the builder to reproduce the corrected CSV.
⚠ **`scripts/fair_units.py` is NOT on the working tree** — only on `claude/calib160-migration`
(worktree `.claude/worktrees/optimistic-swartz-112637`). The memory used to name it as if available.

### ⭐⭐ The pulse lab is now CAUSAL — and there were **TWO** ringing paths
⇒ **[[ccx_pulse_spline_ringing]]**. Commit `040d9af`, pushed. Marcus chose **app-only**.
Opt-in via `ccx_build_forcing(emis_method=)` / `ccx_run_coupled(interp_method=)`, both defaulting to
`CCX_EMIS_METHOD_DEFAULT = "spline"` ⇒ **no stored logpost moves, other tabs' numbers stand**.
⭐ **`emissions-interp-constant` is now a DEFAULT change, not a code change** — same switch.
⛔⛔ **Fixing the emissions was only HALF.** The residual fell to 3.48e-3 ppm, which looks like
convergence noise — **and the first draft of the gate tried to measure a noise floor and pass it.**
It did **not** move when `tol` was tightened 100×. The second path is `R/climate.R`'s
`F$gmst <- ccx_annual_to_monthly(...)` — the **same global spline**, ringing the post-pulse warming
backwards. With both fixed: **1.24e-07 ppm** at the shipped tol, **exactly 0** at tighter ones.
⭐⭐⭐ **ASSERT A LIMIT, NOT A SIZE.** Convergence noise shrinks with the solver's tolerance; an
acausal path does not. "The residual is small" **would have passed the half-fixed model**.

---

## 4. Non-obvious state
- **Branches.** CCX `main` is at `040d9af`, **pushed** to `msarofim/CarbonCycleEmulator` (private).
  FaIRtoFrEDI is on **`heat-ed-morbidity`** at `b1889af`, **NOT pushed**.
- ⚠ **MARCUS IS EDITING IN PARALLEL.** `deliverables/egu_sprm/*` (`.docx`, `.md`) are dirty in
  **FaIRtoFrEDI** and are **HIS** — left untouched. ⛔ Per [[marcus_edits_docx_directly]], **diff any
  returned `.docx` against HEAD and pull his prose into the SOURCE before rebuilding.**
- **Suite.** CCX filter `climate|app|review|driver|growth|future|mechanisms|luc|forcing|stability`:
  **518 / 0** across 124 files (25 warnings, all the pre-existing 1900-start transient).
  ⛔ **DO NOT READ A GREEN FILTER AS A GREEN SUITE** — it does not touch the **four known reds**
  (`test-mode-file.R`, `test-overlay-idiom-lint.R` ×2, `test-seas-lag-split.R`).
- **Machine was CONTENDED** all session: load 6.5–9.6 with four Julia processes at 99 % (Marcus's,
  likely BRICK). Time anything long against that, and read `uptime` first.
- **`node` is NOT installed** — the `dataviz` skill's palette validator cannot run. The OKLab +
  Viénot-Brettel dichromat check was reimplemented in Python; re-use that rather than eyeballing.
- **Memory budgets.** `INDEX_ccx_ref.md` is now **15,389 B** — over its 14 KB soft, under the 18,432
  hard. `INDEX_diag.md` 17,291 is the next split candidate. ⛔ Per [[memory_index_split_beats_trim]]
  **split rather than trim**, and **Marcus asks for splits explicitly** — do not restructure unprompted.
- **Still unmerged, still owed**: `emissions-interp-constant` (`35f38dc`) should ride with the next
  refit so the ledger is paid once. Tier 1 does not trigger one.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), a start-up re-time on an **IDLE** machine, the hosting
  plan's limits. W4's ratchet entry still unratified.

## 5. Recommended order for the next session
1. **Acquire GCB's gross LUC components** (the risk — may not exist as needed). If they do not,
   stop and ask Marcus; do not substitute a kernel silently.
2. **Build Tier 1** as a diagnostic + gate (the two halves must sum to the existing net input
   exactly), then the app panel.
3. **An app panel for the imbalance band** — the strongest app addition from (i)/(k); it answers
   "is the model's land sink too high?" visually and pairs naturally with the regrowth panel.
4. Cherry-pick `b1889af` somewhere sensible, and consider merging `fair_units.py` to main.
