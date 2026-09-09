# Handoff — 2026-09-09. The isotopic-data audit: four rulings taken, ONLY #4 implemented and IT IS IN DOUBT (it invalidates `hilda31`); GRAVEN ACQUIRED and it says Hua's bomb-window sd is 3–11× too small; `INDEX_ccx` SPLIT. **The repo work is on branch `isotopic-audit-20260909`, NOT on `main`, because the suite is RED by exactly the thing awaiting a ruling.**

Read first: `notes/handoff_2026-09-08j_next_step_recommendation.md` (the round-6 plan, still the plan),
**DATA.md §9c** (the audit itself), CHANGELOG 2026-09-09.
Memory: [[ccx_debias_invalidates_hilda31]], [[ccx_graven_vs_hua]], [[rscript_top_level_on_exit]].

## 0. ⚠ STATE OF THE TREE — READ BEFORE TOUCHING ANYTHING
- **`main` is UNCHANGED and GREEN.** All of this session's repo work is on
  **`isotopic-audit-20260909`**, one commit.
- On that branch the suite is **5 fail / 2226 pass / 4 skip**. The pre-existing 3 are
  `test-alpha-as.R:116,117` (gate Q, deliberate) and `test-seas-lag-split.R:199` (error).
  **The 2 NEW ones are `test-enso-demean.R:144` and `:162`** — and they are NOT bugs, they are the
  provenance guard working: ruling 4 changed a model INPUT, so `hilda31`'s stored logpost no longer
  reproduces (off by −92.7) and the ENSO-demean gap moved 43.8367 → 41.9.
- ⛔ **Do not "fix" those two tests.** They are the ledger telling you a refit is owed.
- `data/forcing_bomb_c14.rds` on that branch is **de-biased** (`t2_high_bias_divisor = 1.20`).
  `git checkout main` restores the pre-de-biasing product.

## 1. The four rulings (Marcus, 2026-09-09)
| # | ruling | status |
|---|---|---|
| 1 | gate 5's NH statistic → **the TROUGH DEPTH**; first-peak time reported | **NOT IMPLEMENTED** |
| 2 | the σ_rep table → **RE-BIN on the model's own layer edges** | **NOT IMPLEMENTED** |
| 3 | GL's bound → the **AUGMENTED (CO₂-control) form, z −9** | **NOT IMPLEMENTED** |
| 4 | Tans' ~20 % Telegadas high-bias caveat → **APPLY it** | **IMPLEMENTED — and in doubt** |
Bounds/straddlers for 1–3 are now in **`INDEX_ccx_gates.md`**, not `INDEX_ccx`.

## 2. Ruling 4 is implemented, and four measurements cut against it
`BOMB_T2_HIGH_BIAS` (env `CCX_BOMB_T2_BIAS`, default **1.20**) divides Tans Table 2 at the point of
conversion. Split 35.4 → 46.1 %; burden 65.92 → 54.94 kmol; tail 14.28 → 11.90; **τ unchanged** at
6.87 (a uniform scale moves a log-linear intercept, not its slope).

1. **−92.74 loglik at `hilda31`**, entirely in `d14c_SH` (−69.45) and `d14c_NH` (−23.22).
   `diag_bomb_debias_impact.R`. ⚠ **A matched evaluation at a FIXED VECTOR, not a refit.**
2. **It invalidates the canonical** — the 2 red tests above; independently reproduces (1) at −92.7.
   Under the project's ledger this is **objective change #8**: refit + re-promote before anything.
3. **The newly-ruled gate-5 trough gets WORSE**: drop **51 → 25** vs an observed 111. (The
   inter-peak tilt improves, +68 → +37 vs obs −13.)
4. **λ 0.1996 → 0.3490 /yr (5.01 → 2.87 yr)**, so gross air-sea exchange at Tans' own Broecker flux
   covers **75 % → 43 %** — and DATA.md §9 names that agreement as *"the main evidence that the
   budget-closure step is sound."*

**Why it can act at all.** De-biasing is a **NO-OP** unless Table 2 and the 102 kmol Naegler & Levin
total come from different sources — scale both and the unit-integral shape is unchanged. The whole
effect is the **Telegadas-vs-N&L disagreement dumped into the pre-1963 troposphere** (hence SH, with
little bomb signal then, hit 3× harder than NH). **No isotopic record in that window can arbitrate.**

**Reverting is ONE LINE** (`BOMB_T2_HIGH_BIAS` default → `1.0`, then re-run the builder) and makes
the suite green with every piece of machinery, every diagnostic and every finding kept.

## 3. Graven ACQUIRED — and the answer to "is it now the best source" is **NO, not as a replacement**
`data-raw/download_graven_isotopes.R`; both files SHA256-verified against ESGF's published checksums.
`data-raw/downloads/` is gitignored, so **the downloader IS the provenance** (it upserts MANIFEST.csv).

⚠ **VINTAGE.** DATA.md claimed since 2026-08-10 that Graven was "retained as a δ¹³C cross-check" —
**no file ever existed**. What ESGF serves now is the SUCCESSOR: input4MIPs **CMIP7/C4MIP
ImperialCollege-3-0 v20250502, 1700–2023**, Δ¹⁴C on **4 equal-area bands**, δ¹³C **global-mean only**.
**Never label it "Graven et al. 2017 data."**

| axis | Hua 2022 (in use) | Graven IC-3-0 | verdict |
|---|---|---|---|
| Δ¹⁴C time | **monthly** | annual | ⛔ cannot serve any seasonal/monthly stream |
| Δ¹⁴C space | **5 zones** | 4 bands | comparable, different partition |
| per-obs σ | **yes (`d14c_sd`)** | none in file | Hua carries its own error |
| Δ¹⁴C span | 1941–2019 | **1700–2023** | Graven longer at both ends |
| δ¹³C | flask 1977–2024, 2 stations | **global mean 1700–2023** | fills 1850–1977, but global-mean |

⇒ **RETIRE NOTHING.** Graven is more recent and longer but strictly COARSER on the axes the model
scores. It is a cross-check and an uncertainty estimator, not a target. ⛔ And its pre-bomb section
is almost certainly derived from the same tree-ring/IntCal material as the scored `d14c_intcal`
stream (1700–1950) — **adding Graven there would DOUBLE-COUNT.** Verify that derivation before ever
using Graven pre-1950 as a stream.

### 3a. THE FINDING (`diag_graven_vs_hua.R`)
Area-weighted hemispheres, calendar-year means, 1950–1980. Outside the peak the two agree to ~2–3 ‰;
in **1963–65 they diverge to 40 ‰ = 11× Hua's own median zonal sd (3.6 ‰)**.

| Graven − Hua (‰) | 1962 | 1963 | 1964 | 1965 | 1968 | 1976 |
|---|---|---|---|---|---|---|
| NH | −1.1 | **+29.2** | **+39.9** | **+17.9** | +3.1 | +3.3 |
| SH | −1.6 | **−28.6** | **−40.3** | **−28.5** | −6.0 | +1.4 |

**ANTISYMMETRIC** (NH mean +4.91, SH −4.87), debiased shape correlation **0.999** ⇒ the two
compilations **agree on the transient and disagree on the HEMISPHERIC PARTITION**. At 1963 the NH−SH
gradient is **361.4 vs 303.7 — 19 %**, precisely what constrains the bomb source's NH/SH split.
⛔ Graven is an independent **COMPILATION**, not an independent observing system.

## 4. RECOMMENDED SCOPE for using Graven (three roles, ranked; none is "replace Hua")
**Role 1 — a REPRESENTATION-ERROR term for the bomb window. Highest value, follows directly from §3a.**
The measured Graven−Hua hemispheric spread IS an estimate of compilation systematic error. Add it as
a year-dependent variance on `d14c_NH`/`d14c_SH`, exactly analogous to the existing
`LIK_EXCESS_C14_REP_FRAC = 0.15`. ⚠ **OBJECTIVE CHANGE — every stored logpost moves.** Marcus's call.
Build: `data-raw/build_graven_targets.R` → `data/obs_graven_isotopes.rds`; a rep-σ table; a
likelihood hook; tests incl. a **mutation test** on the table; DATA.md + CHANGELOG.

**Role 2 — fill the δ¹³C gap 1850–1977 with a GLOBAL-MEAN level stream.** There is currently **no
δ¹³C observation of ANY kind in 1950–1980** (flask starts 1977.2; ice cores have zero samples there).
⚠ Global-mean only ⇒ it can NOT serve `d13c_gradient` or gate GL/H, which are hemispheric. ⚠ And the
model's δ¹³C is already strained (GL z −13, Q 2.44σ), so this could be highly informative or just a
large constant penalty. **PROBE UNREFITTED at `hilda31` before adopting.**

**Role 3 — cross-check IntCal20 (1700–1950) against Graven for version drift.** A check, not a stream.
Cheap. Do it before Role 2 so the pre-bomb baseline convention is known to agree.

⛔⛔ **SEQUENCING.** Role 1 and ruling 4 BOTH change the objective. Doing them in one round makes
them unattributable — the project's own repeated lesson is ONE QUESTION PER ROUND. **Settle ruling 4
first** (revert, or refit as change #8), then Role 1.

## 5. Bugs found and fixed on the way
- ⛔ **Top-level `on.exit()` NEVER FIRES in an Rscript** ⇒ [[rscript_top_level_on_exit]]. The restore
  in `diag_bomb_debias_impact.R` was a silent no-op and left the live forcing file swapped; it hid
  because that arm matched HEAD, so `git status` was CLEAN. Now `tryCatch(finally=)` **plus a SHA256
  assertion that the restore landed**. Verified against an in-function `on.exit` in the same script.
  **Candidate for promotion to `~/.claude/CLAUDE.md` execution hygiene.**
- **`tests/testthat/test-bomb-source-provenance.R`** (new, **mutation-tested**): the builder declared
  /1.20 while the shipped product carried no divisor at all, and nothing could see it — the product is
  internally consistent either way, so a check reading only the product is BLIND. It compares the
  product's recorded divisor against the **builder script's declared default**, parsed from source.
- **Three stale-doc corrections in `build_bomb_c14_source.R`**: two comments described the first-point
  replacement as "a backward extrapolation of the tail fit" — the code never did that, and it would be
  wrong (it gives 36.23 kmol, **39 % BELOW** the floor Tans says 356 is). The header and the `method`
  string also credited Table 1 for the pre-1963 apportionment; **Table 1 is never read**.
- A typed `(14.28 kmol)` removed from the builder header before the divisor could make it drift.

## 6. Memory tree: `INDEX_ccx` SPLIT (2026-09-09)
It was at **17,358 B of its 18 KB hard ceiling** with findings owed ⇒ **SPLIT, don't trim**.
- **New `INDEX_ccx_gates.md` (6,726 B)** = the GATE LEDGER: what each gate tests, its bound and that
  bound's provenance, its verdict, its pricing.
- **`INDEX_ccx.md` (14,581 B)** = the ARC STATE: canonical, blocker, next step, parameter space,
  objective-change ledger.
- **Split line stated in BOTH files.** Straddlers named in `_gates`: **gate 5** (bound there, live
  verdict in `INDEX_ccx`), **gate 12/Joos**, **gate GL**. Generic gate CRAFT stays in `INDEX_diag.md`.
- Orphan sweep run: no missing link targets, no link lost across the cut.
- Registered in `MEMORY.md` and in `FaIRtoFrEDI/CLAUDE.md`.
- ⚠ **OWED TIDY:** `INDEX_ccx` is **245 B over its 14 KB SOFT target** (hard ceiling is fine). The
  natural next move is the stale **"LIVE STATE (2026-09-04)" 26-par / `ent26` refit history** →
  `INDEX_ccx_arch`; the migration warnings in that block are still live and must STAY.
  `MEMORY.md` is 15,315 B against a 12 KB soft target — pre-existing, not caused here.

## 7. What I would do first next session
1. **Settle ruling 4** (§2). Revert is one line and makes the suite green; keeping it commits you to
   a refit as objective change #8 before round 6 can be judged.
2. Then **rulings 1–3**, which are still unimplemented and are what round 6's prereg depends on.
3. Then **Role 3 → Role 1** for Graven (§4), one question per round.
4. Round 6 = **C alone** remains the plan of handoff 09-08j; nothing this session changed that.
