# Handoff — CarbonCycleEmulator, 2026-09-02 (third session of the day)
# **ALL FOUR RULINGS LANDED. THE REFIT IS UNBLOCKED.**
# **AND RULING 4's RE-RUN FOUND A LIVE BUG THE MORNING'S HANDOFF HAD**
# **MIS-DIAGNOSED — 49 MORE SITES CARRY IT, THOUGH NOT THE REFIT HARNESS.**
# **NEXT: the 25-parameter refit, and two rulings this session created.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-02i_the_gates_the_contracts_and_a_refuted_argument.md`.
This session is its §7 — Marcus's four rulings — executed in full.

---

## 0. STATE IN TEN LINES

1. ✅ **RULING 1: the ENSO land term is a ONE-WAY GPP MODULATION.** Price **−65.74**, and the
   diagnosis is worth more than the number. §1
2. ✅ **RULING 2: gates 4 and 5 have bounds and BOTH FAIL; gate 7 stops out-judging the fit.** §2
3. ✅ **RULING 3: GATE G ships** — and its obvious design was **partly circular**. §3
4. ⛔ **RULING 4 found a LIVE BUG. The 27n fixture was RIGHT; the code was running at the wrong
   lag.** Its own G0 gate caught it. **49 more sites carry the pattern.** §4
5. ⭐ **THE REFIT HARNESS IS UNAFFECTED** — `R/calibrate.R` migrates. So does `lib_design_gates.R`.
   **No fitted result and no gate number is in question.** §4
6. **Suite 1507 PASS / 6 FAIL / 2 skip**, failure set byte-identical to the standing one. §6
7. ⇒ **THE 25-PARAMETER REFIT IS NOW UNBLOCKED AND IS THE NEXT THING.** §5
8. ⇒ **TWO NEW RULINGS OWED**, both created by this session's measurements. §5
9. ✅ **THE MEMORY CONSOLIDATION PASS RAN.** Nothing over its hard ceiling; **0 orphans, 0 broken
   links, 0 files retired** — the store was not rotting, the indexes were. §7
10. ⭐ **LAUNCH FROM `FaIRtoFrEDI/`, NOT `CarbonCycleEmulator/`** — the memory keyspace follows the
   cwd, and all CCX memory lives under the FaIRtoFrEDI key. §8

Commits: `1df8654` (ruling 1), `c811b82` (ruling 2), `06bdeb5` (ruling 3), `65923bc` (ruling 4).

---

## 1. ✅ RULING 1 — THE ENSO LAND TERM IS ONE-WAY (`1df8654`)

Folded into the two GPP limbs, split by `npp_leaf_frac`, both cores. **No new fitted coordinate;
still 25 parameters.** GPP rather than respiration is a **physics** choice, not a fitted one: the
09-02 pre-check proved the channels isotopically degenerate, and the model already has a respiration
path (`q10` on GMST, 3.2 % of the term) and **no moisture path at all**.

**⭐ THE PRICE IS −65.74 LOG-UNITS AT FIXED PARAMETERS, AND IT IS NOT THE ISOTOPES.** Both structures
put the same net carbon into the same atmosphere at every instant, so the number needed a diagnosis
rather than acceptance. By stream it is paid in **CO₂ LEVELS** (MLO −33.8, SPO −20.2) for a
**0.58 ppm** shift; d13c_NH moved 0.0004 ‰ and the Δ¹⁴C move of **+3.69 ‰** is exactly what the
pre-check predicted.

⛔ **THE CAUSE IS A PROPERTY OF THE FORCING. The ENSO index is NOT ZERO-MEAN** — **−0.218** over
1948-2024, identically 0 before. A sustained anomaly loads onto `soil_fast` alone (**τ = 2.0 yr**) in
the old form and onto the whole land chain (**35.5 yr**) in the new one:
+0.083 GtC/yr × 33.5 yr = **+2.77 GtC = −1.31 ppm** against a measured **−0.58**. Same sign, 2.3×
over — as a full-equilibrium estimate should be after 76 yr against a 36 yr constant with the ocean
and CO₂ fertilization damping it.
⇒ **The same coefficient means something different in the two structures**, so **−65.74 is an UPPER
BOUND** a refit should largely recover.

**THE MARGIN:** peak |anomaly| is **1.42 % (NH) / 14.45 % (SH)** of the hemisphere's own
preindustrial gross GPP limb ⇒ it would take a gamma about **7×** the fitted one to shut
photosynthesis off. `ra_ratio` is 0 in this arm, so the gross limb IS `npp` and adds no headroom.

⭐ **`calibration/diag_enso_gpp_margin.R` runs TWICE** (a git worktree at the pre-change source) and
refuses to report if the two share a **model-source fingerprint**. Its first attempt **caught
itself**: the commit hash was identical because the change was uncommitted. **A commit is not the
identity of the code** — the guard hashes `R/model.R` + `src/ccx_core.cpp`.

The **`enso` flux channel is retired** (`R/fluxes.R`); `land_net` drops its `- ch[["enso"]]`.
`test-fluxes.R`'s `any(fl$enso != 0)` pinned the design being changed and was replaced
**deliberately**, by a stronger pair.

---

## 2. ✅ RULING 2 — THE GATES GET BOUNDS (`c811b82`)

**GATE 7** now judges at the **objective's own sigmas** — land 1.50, ocean **0.40 uninflated** (the
asymmetry is the objective's, `R/likelihood.R:1608-1612`) — and `DG_G7_NSD` 1 → **2**, harmonized
with `DG_Q_NSD` / `DG_G5_NSD` / `DG_GD_NSD`. **All arms PASS** (from90 land **+0.72**; the bare-σ
+2.15 is still printed). ⚠ **Still not independent** — aligning a sigma cannot make a restatement
out-of-sample, so **do not chase it in the refit**. ⭐ `dg_gate7_verdict()` finally centralizes the
verdict, which had been INLINE in both callers.

**GATE 4** gets an **ORDERING and no threshold** (its claim is "must not be SMOOTHER than this").
Decadal AF spread **0.032-0.041 vs GCB 0.051 ⇒ FAIL everywhere.** ⚠ Its **LEVEL stays deliberately
UNBOUNDED**: near-algebraic in fitted quantities.

**GATE 5** gets **two orderings** (SH peaks AFTER NH; NH peak HIGHER — no sigma needed) **plus a
DERIVED sigma**, because ⛔ **Hua publishes none**: leave one zone out of the observed aggregate ⇒
**NH 0.444 yr (4 draws), SH 0.338 (3), lag 0.494 (12)**.
⚠ **Pooling the hemispheric quantities over all 12 combinations repeats each value and biases the sd
~10 % LOW** — silently stricter than the data warrant. Each hemisphere uses its own draws.
Result: **FAIL on the NH PEAK TIME (+2.11 to +2.15σ, ~0.95 yr late)**; the lag is comfortably inside
at −0.45 to −0.75. ⇒ **The gate LOCALIZES the miss: it is the peak TIME, not the lag.**

✅ All bounds **mutation-tested permanently**, in BOTH directions — gates 4 and 5 fail everywhere,
and **a gate that can only fail is as uninformative as one that can only pass**.

---

## 3. ✅ RULING 3 — GATE G, AND THE OBVIOUS DESIGN WAS PARTLY CIRCULAR (`06bdeb5`)

⛔ **The whole-column INVENTORY would have been partly circular** — the pump's export field was
**SOLVED** to hold the OBSERVED gradient anchored on the model's own mixed layer, so the profile's
SHAPE is GLODAP-derived by construction. Not wholly (the model's gradient is ~13 % larger than
observed), so the inventory is **REPORTED, NOT BOUNDED**, and a test asserts that wrecking it leaves
the verdict untouched.

✅ **The out-of-sample part is the MIXED-LAYER LEVEL**, checked rather than assumed: every ocean row
in the likelihood is a **GRADIENT with a fitted offset**, `d14c_deep_ocean` is Δ¹⁴C, `gcb_ocean_sink`
is a FLUX, and the model's surface DIC is carbonate equilibrium at `ALK_SURFACE`.

**PASS at every arm.** At the bottles' own epoch (**2002.4**, derived not typed) observed
**2034.9 µmol/kg** against from90's **2045.7 = +0.61σ**. ⚠ Comparing the **1750 spinup column
(1996.3)** would have shown the anthropogenic increment as a **−38.6 µmol/kg "defect"**.
⚠ The sigma **borrows** `LIK_D14C_DEEP_NEFF` = 20, ruled 08-14 for the abyss, which is
**conservative = more lenient** at the surface. The report walks it: z **+0.30 / +0.61 / +1.35 /
+3.03** at n_eff 5/20/100/500 ⇒ **the verdict flips at n_eff ≈ 500.**

⭐ **DEMONSTRATED POWER ON THE MODEL:** walking `ALK_SURFACE` fails the gate at **±2 %** and passes
within ±1 %, with elasticity **R = 0.932 % DIC per % ALK** — near the 1 carbonate equilibrium
predicts at fixed pCO₂, so the mutation reaches the gate through the physics the header claims.
⇒ **GATE G bounds a PROVISIONAL constant observationally at ±2 %** — the first quantitative handle
on `ALK_SURFACE`.

⭐ **AN EXTRACTION THE GATE FORCED:** `calibration/lib_glodap_obs.R`. ⛔ `pump_shim.R` **cannot** be
sourced for its GLODAP helpers — it wraps `ccx_deriv()` in the global env and would change the model
being gated.

⚠ **"NOT ONE LAW-DERIVED GATE" STILL STANDS.** G is observational; it narrows the hole without
closing it. Revelle-consistency and Henry's-law remain unbuilt.

---

## 4. ⛔ RULING 4 — THE RE-RUN FOUND A LIVE BUG, AND THE HANDOFF HAD MIS-DIAGNOSED IT

`diag_gamma_iav.R` fixed (all four ENSO names had been deleted ⇒ **every scan ran with ENSO OFF**).
Quarantine landed in `outputs/quarantine/20260902_mechanism_off/` with its README.

**THEN `diag_gross_cancellation_geometry.R` REFUSED TO RUN — its own G0 reproduction gate stopped
it**, at NEP **1.3807 @ 10.66 mo** against 08-27n's **1.3950 @ 10.15** (0.51 months on a 0.05
tolerance).

* **Did today's ENSO change cause it? NO** — measured on the pre-change worktree: **1.3777 @ 10.66**.
  G0 was already failing.
* **Was the fixture stale? NO.** Forcing `seas_lag_p_NH = _SH = 1.7677` reproduces 27n at
  **1.3970 @ 10.15** — **0.14 %, 0.00 months** — and the reported numbers are **exactly the lag-2.25
  row**. ⇒ **THE FIXTURE WAS RIGHT AND THE CODE WAS WRONG.** [[explained_away_test]]

**THE DEFECT.** `ccx_mode_params()` returns `par_mode` RAW; `from90` is pre-split, so the
`intersect()` copy loop **DELETED both split lag names** (assigning NULL drops the element) from a
`ccx_default_params()` carrying no legacy scalar, and `ccx_seas_lag_p()` fell through to the **NAMED
DEFAULT 2.25** — while the file's own header printed **1.7677**, read off the fitted set rather than
the parameters the model got. **A caption-sync bug on top of a silent-default bug.**

⚠ **AND `95e97ab`'s FIX WAS PARTIAL:** it fixed section 5b's grid and **missed G5's lever list**,
which still named the retired scalar. G5's levers are now **SETTERS, not names**, and 5b reuses G5's
setter so there is one definition of "sweep the lag".

**⭐ THE RESULT CHANGED.** The lag axis runs **115.2° at 0.50 to 176.1° at 2.75** (mode at 1.75)
against a needed **164.8°** ⇒ **"`seas_lag_p` CAN reach the needed separation — it is the second
member of the pair."** The pre-fix file read its maximum off a flat curve. All gates now score:
**G0/G1/G2 PASS, G3 UNREACHABLE, G5 lever exists.**

### ⛔⛔ THE BLAST RADIUS, MEASURED — 49 SITES

| | sites |
|---|---|
| **MIGRATES (safe)** | **8** — incl. **`R/calibrate.R`** (the refit harness) and `lib_design_gates.R` ⇒ **no fitted result and no gate number is in question** |
| does NOT migrate, calls `ccx_set_enso` | **37** |
| does NOT migrate, repairs nothing | **12** |

⚠ **`ccx_set_enso()` IS NOT A FIX FOR THIS** — it repairs the ENSO names only, so those 37 files
**look safe and still run at lag 2.25**. A partial repair is worse than none: it removes the symptom.
⚠ **49 is an UPPER BOUND**; a site bites only if it loads a pre-split mode file through the idiom.
`CCX_MODE_CANONICAL` **is** `from90`, so most will.

**✅ `ccx_overlay_par(p, pm)` (R/model.R)** — migrate, copy, repair, **ASSERT THE OVERLAY DELETED
NOTHING**. The two fixed files use it; `test-gate-bounds.R` carries the regression.
⛔ **THE OTHER 49 ARE NOT CONVERTED — that is a ruling, not a silent refactor.**

---

## 5. ⇒ WHAT IS NEXT, AND THE TWO RULINGS THIS SESSION CREATED

**THE 25-PARAMETER REFIT IS UNBLOCKED AND IS THE NEXT THING.** Arm N, from the 09-01 basin, 25
parameters. Every structural change the morning handoff was waiting on has landed, and no further
one is queued. Torch verdict out loud before launching ([[consider_torch_first]]).
⚠ Its starting point now costs **−65.74** relative to the pre-change structure at the same vector;
that is the number to beat, not the old logpost.

**RULING A — SHOULD THE ENSO INDEX BE DEMEANED over its non-zero span?** Its mean is **−0.218** over
1948-2024 and 0 before. Under the old structure that was nearly inert; under the new one it is a
**~1 ppm lever** on the land's 35.5 yr chain, and it is most of the −65.74. Demeaning changes what
`gamma_enso_land_*` MEANS. **My recommendation: decide this BEFORE the refit**, because the refit
will otherwise spend the four ENSO coordinates absorbing a property of the forcing.

**RULING B — CONVERT THE 49 SITES TO `ccx_overlay_par()`?** Mechanical, but it will change printed
numbers in any diagnostic that was running at lag 2.25, and each such change needs a look rather
than a bulk commit. **My recommendation: convert on touch, plus a lint that fails a NEW bare-idiom
site** — not a 49-file sweep.

**STILL OWED, unchanged:** the four observed SPO constants (total 1.168 / land 0.683 / ocean 0.522 /
phase 8.52) are **not in `R/constants.R`** and are replicated across ~10 diagnostics.

---

## 6. ⚠ NON-OBVIOUS STATE

* **`CCX_MODE_CANONICAL` is STILL `from90`**, a 21-parameter ancestor. **5 of the 6 standing suite
  failures are that mismatch**; the 6th is `test-likelihood.R:587`'s `kz$hi <= 7000` guard rail,
  left failing for Marcus since 09-01.
* **The pre/post pricing worktree at `b9f183d` HAS BEEN REMOVED** (`git worktree list` shows only
  the repo). To re-price anything, re-create it — `calibration/diag_enso_gpp_margin.R`'s header
  carries the four-line recipe, and `outputs/diagnostics/enso_gpp_margin_pre.rds` records the
  model-source fingerprint its `pre` half was measured at.
* **`GATE 4` still names two different gates** — `diag_gates_in_the_new_basin.R` has its own `stop()`
  guards GATE 1/2/3/4 in the file that also reports DESIGN gate 4/5/7. Flagged, not renamed.
* **`NB_Z` in `diag_gates_in_the_new_basin.R` is now on the OBJECTIVE's sigmas**, so its numbers are
  not comparable with any stored one.
* **The memory consolidation pass RAN — see §7.** Nothing is over its hard ceiling any more.
* **The 09-02 note that contradicted itself is fixed** (+18.7 % → +42.4 % in its title line), and
  the **"6.4σ → 1.0σ" GATE Q figure is corrected in memory** to the measured per-arm 1.37 / 0.80 /
  0.76 — that "1.0" reproduces at no arm.

---

## 7. THE MEMORY CONSOLIDATION PASS (2026-09-02, after the four rulings)

**THE STORE IS NOT ROTTING, AND THAT WAS THE FIRST THING MEASURED.** 469 files, **0 orphans**
(every memory is reachable from an index), 3 broken links, and **no line violating the index's own
300-chars-per-link rule**. So **nothing was retired** — 469 files in, 469 out. The rot was entirely
in the indexes, and `INDEX_ccx.md` was **279 bytes from its 18 KB hard ceiling**.

**⚠ THREE CAPTION-SYNC ERRORS, one of them made earlier the same day.** This is the class the index's
own rules exist to prevent, and it still bit:
* `INDEX_ccx.md` said "**FIVE** OBJECTIVE/SPACE CHANGES NOW STACK" while listing **six** — the ENSO
  one-way change was appended without touching the count.
* `MEMORY.md`'s rules header said "ROOT INDEX + **EIGHT** on-demand sub-indexes" and named eight.
  There are **ten** (`ccx_ocean` and `cmp` were missing).
* A stale suite count (1365 → **1507**) and a stale "LIVE STATE (2026-09-01)".

**MERGED AND MOVED.** Two `INDEX_ccx_arch.md` sections were the SAME `h_ml` arc under different
headers, with one bullet appearing **verbatim twice**. Five closed/superseded arcs moved from the
live CCX index into the archive tier — the 08-28 band decode, the off-support −232, the 08-31f
re-pricing, the pre-09-02 gate table, the withdrawn FACE ceiling — each under a banner reading
**"every gate-7 sigma below is on the RETIRED 0.50"**. Header prose in `INDEX_ccx.md` that restated
bullets sitting directly beneath it was collapsed to pointers.

**STALE FACTS CORRECTED.** `ccx_app_beta_blockers.md`'s gate-7 line — the VALUES (land 3.50, ocean
2.61 GtC/yr) stand and re-measure at 3.54; the "+2.28 sd / −1.52 sd" were on the retired sigma and
now read **+0.75 / −1.44 ⇒ PASS**. That discharged a TODO `INDEX_ccx.md` had been carrying. Also one
relative date ("yesterday's 1.94≈1.9 match" → **2026-06-03**, from the file's own dateline) and the
three broken links (two were a function name and a `~/.claude/CLAUDE.md` rule written as wikilinks;
the third was a false positive from R code inside a fence).

**RESULT — verified with `wc -c`, which is the unit the budget rule specifies:**

| | bytes | vs budget |
|---|---|---|
| `MEMORY.md` | 15,664 (13,164 content) | over **soft** by 876 |
| `INDEX_ccx.md` | **16,221** | over soft by 1,885 — **2,211 of HARD headroom**, was 279 |
| `INDEX_ccx_arch.md` | 16,621 | over soft by 2,285 |
| `INDEX_cmp.md` / `INDEX_slr.md` | 14,912 / 14,749 | over soft by 576 / 413 |
| the other five | 5,083–12,773 | ok |

⚠ **A UNIT TRAP WORTH KNOWING: `wc -c` counts BYTES, Python's `len()` counts CHARACTERS.** These
files are dense with `⚠ ⛔ ⭐ → σ ×`, so a Python-measured size runs several hundred bytes LOW —
i.e. it flatters the file against a budget denominated in bytes. **Measure with `wc -c`.**

⛔ **WHAT WAS DELIBERATELY NOT DONE.** No deep duplicate-content audit across the 469 topic files —
the graph metrics said that was not where the problem lived, and reading all of them was not worth
the context. And the four indexes still over SOFT were left there: the rules define over-soft as
"merge when convenient", and **rule 3 is explicit that length is not a reason to delete a number**.
⚠ `INDEX_ccx_arch` is now the fattest index. It is provenance-only and rarely read, so it is the
cheapest place for that weight — but it is the next candidate if it keeps growing.

---

## 8. ⭐ AN OPERATIONAL FACT WORTH MORE THAN THIS SESSION

**THE MEMORY DIRECTORY IS KEYED TO THE LAUNCH cwd, AND ALL CCX MEMORY LIVES UNDER THE FaIRtoFrEDI
KEY.** The only directory under `~/.claude/projects/*/memory` is
`-Users-MarcusMarcus-Documents-2026-CodeProjects-FaIRtoFrEDI/memory/`, and its slug matches this
session's cwd exactly.
⇒ **Launch from `FaIRtoFrEDI/`, even though every line of CCX code is in `CarbonCycleEmulator/`.**
A session started from `CarbonCycleEmulator/` would pick up that repo's own `CLAUDE.md` but land on
a **different, empty memory keyspace** — `INDEX_ccx.md` and its nine siblings would simply not be
there. Prefer `/clear` in a `FaIRtoFrEDI/`-launched window over opening a new session elsewhere.
⚠ The cwd-keying is INFERRED from the slug matching and from only one such directory existing; the
mechanism was not read out of the harness. The practical instruction stands either way.
