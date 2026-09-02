# Handoff — CarbonCycleEmulator, 2026-09-02 (fifth session of the day)
# **RULING A IS ADOPTED AND SHIPPED. THE v6 GRID IS PULLED AND §4 IS CLOSED.**
# **THE 25-PARAMETER REFIT IS THE ONLY THING LEFT, AND IT IS OWED.**
# **AND A +43 "FINDING" OF MINE SURVIVED EXACTLY TWO CONTROLS.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-02k_ruling_a_tested_and_the_physics_lost.md`.
This session executed its §8 in order, on two rulings from Marcus.

---

## 0. STATE IN TEN LINES

1. ⭐⭐ **RULING A ADOPTED AND SHIPPED** (Marcus). `FORC_ENSO_DEMEAN` over 1948-2024,
   **+56.4785 = 86 % of the −65.74**, verified through the LIVE builder. §2
2. ⭐ **THE v6 GRID IS PULLED (90 MB) AND §4 IS CLOSED.** The 15 % gap is **partly** the version;
   the **level offset is not**. §4
3. ⛔ **AND MY OWN +43.38 "UNCLIPPED ROLLING BASE WINS" DIED TO TWO CONTROLS** — it was
   **COVERAGE**. Like-for-like the rolling base LOSES by 5.12. **Ruling A stands.** §4
4. ⛔ **TWO OF THE FOUR GATES I WROTE FOR THE ADOPTION WERE BROKEN.** One had **no power**
   (its mutation passed); one **never ran** under `test_dir()`. Both caught, both fixed. §3
5. ✅ **THE FOUR SPO CONSTANTS ARE REGISTERED** and their **34 copies in 14 files are TIED**. §5
6. ⛔ **A CLOSURE GATE CONSIDERED AND REFUSED** — the 1.1 % residual is a bootstrap-median
   artifact, and its only available bound was itself. §5
7. ✅ **THE ENSO BUILDER FOLD IS DONE** and proved behaviour-preserving to the bit. §6
8. ⛔ **ONE HANDOFF NUMBER DOES NOT REPRODUCE:** `roll` clips **6 of 16** scored blocks, not
   09-02k §4's "7 of 17". The run log is authoritative. §6
9. **Suite 1622 PASS / 6 FAIL / 2 skip**, failure set byte-identical to standing. ⚠ Not comparable
   to 09-02k's 1515 — that run quit at the default max-fails. §7
10. ⇒ **NOTHING IS BLOCKING THE 25-PARAMETER REFIT. IT STARTS FROM −1512.02, NOT −1568.49.** §8

Commits: `906bde7`, `763e3fa`, `87b671b`, `ec09707`.

---

## 1. WHAT MARCUS RULED

- **Ruling A** → **"Adopt `demean`, then refit."**
- **The v6 grid** → **"Yes, pull it."**

Both executed. The refit is the remaining item and it is his to launch.

---

## 2. ⭐ RULING A, SHIPPED (`87b671b`)

`R/forcing.R`, the ENSO branch. `FORC_ENSO_DEMEAN = TRUE`,
`FORC_ENSO_DEMEAN_WIN = c(1948, 2024)` — the span the bake-off priced.

**TWO DESIGN DECISIONS THE ONE-LINE SUMMARY HIDES:**
- ⛔ **THE MEAN IS TAKEN OVER THE INDEX'S OWN RECORD, NEVER THE REQUESTED RUN WINDOW.** A mean that
  moved with `yrs` would make a 1750-2300 build and a 1948-2024 build see different ENSO, silently,
  and every stored logpost would depend on the span it was scored over.
- **`FORC_ENSO_DEMEAN = FALSE` reproduces the pre-adoption model BIT FOR BIT** — the same
  reproduction path `ALPHA_AS_*_LEGACY` have. It is not a tuning knob.

**VERIFIED THROUGH THE LIVE BUILDER, NOT THE BAKE-OFF'S WRAPPER** (which overwrote the enso column
wholesale and so could not have caught a builder bug): FALSE **−1568.4936**, TRUE **−1512.0151**,
gain **+56.4785**. Both published numbers back to **3e-5**, inside their own printed precision.

⚠ **`asis` NOW MEANS THE PRE-ADOPTION INDEX**, relabelled in the bake-off and in
`eix_nino34_shipped()`'s header — that function returns the STORED column, not what the model sees.

**AND THE DIAGNOSTIC'S OWN GATE HAD TO FOLLOW THE MODEL.** `diag_enso_index_baseline.R`'s **G-I**
hard-stops unless the wrapper is a no-op on the shipped index. Hardcoded to `asis`, adoption would
have turned it into a permanent refusal. It now reads `EI_SHIPPED_TREATMENT`, which follows
`FORC_ENSO_DEMEAN`, and asserts the priced window equals the shipped one. Re-run post-adoption:
**G-I PASS, bit-identical on `demean`**, every treatment price unchanged, G-M now −792.37.

---

## 3. ⛔ TWO OF THE FOUR NEW GATES WERE BROKEN, AND DIFFERENT MUTATIONS CAUGHT EACH

`tests/testthat/test-enso-demean.R`. **This is the part of the session worth remembering.**

- ⛔ **SPAN-INVARIANCE HAD NO POWER.** It compared a 1750-2024 build against a 1948-2024 one, and
  **that pair cannot fail**: the index starts in 1948, so both windows select the SAME rows. The
  mutation that demeans over the *requested* window **passed unchanged**. The second span now cuts
  INTO the record (1980-2024), and the mutation fails as it must. ⇒ `no_power_null`
- ⛔ **THE PRICED ANCHOR NEVER RAN.** `skip_if(!exists("dg_vector"))` — and under `test_dir()` the
  calibration libs are not on the search path, so it **skipped in every full-suite run** while
  looking like a passing gate. It sources the lib instead. ⇒ `broken_gate_reports_nothing`
- The two that were right first time: **INTENT** and **IDENTITY** (the latter also asserts the
  constant is NON-ZERO, which is what stops it passing vacuously).
- ⚠ The anchor's bound is **the quoting precision, 1e-4** — the references are printed to four
  decimals and anything tighter tests the print format.

---

## 4. ⭐ THE v6 GRID: ONE QUESTION ANSWERED, ONE ANSWER RETRACTED (`ec09707`)

90 MB, `downloads.psl.noaa.gov/Datasets/noaa.ersst.v6/sst.mnmean.nc`. In `MANIFEST.csv` and — for
the first time — in `download_data.R`, **which had never carried the v5 grid either**; it was
fetched by hand, so "re-fetchable from `download_data.R`" was false of it. Both are there now.
Same grid, epoch and variable names as v5 — **gated (V-G), not assumed**.
New file: `calibration/diag_enso_v6_provenance.R`.

### Q1 — IS THE 15 % AMPLITUDE GAP A VERSION EFFECT? **PARTLY, AND ONLY PARTLY.**
| pair, deseasonalised 1991-2020 | r | slope | Δclim |
|---|---|---|---|
| PRODUCT nina34 vs CPC(v5) | 0.9836 | 0.839 | +0.602 |
| **VERSION grid v6 vs grid v5** | 0.9939 | **0.949** | **+0.039** |
| **nina34 vs grid v6** | 0.9910 | **0.888** | +0.558 |
| nina34 vs grid v5 | 0.9840 | 0.842 | +0.597 |
| METHOD grid v5 vs CPC(v5) | 1.0000 | 0.997 | +0.004 |

nina34 IS closer to v6 (|slope−1| **0.1116 vs 0.1577**, 1.41×), so the version naming is **not
wrong** — but the grids differ by only **5.1 %** while nina34 is still **11.2 %** off v6, and
**the +0.60 °C climatology offset barely moves**. ⇒ **the LEVEL offset is essentially NOT a version
effect.** The licensing gate is an **ORDERING** — the two disagreements compared with each other —
because no external number says how much better v6 ought to agree.
⭐ **AND IT MATTERS LESS THAN IT LOOKS: with convention AND span matched, v6 and nina34 land
0.55 log-units apart.**

### Q2 — DOES AN UNCLIPPED ROLLING BASE BEAT `demean`? **NO — AND MY FIRST ANSWER WAS AN ARTIFACT.**
v6 reaches 1850, so its rolling base clips **3 of 16** blocks against nina34's **6 of 16**. Raw,
the unclipped rolling base beat demeaning **within v6 by +43.38** — which would have reopened a
ruling adopted the same day. **Two controls killed it:**
- **AMPLITUDE** (rescale `demean_v6` to `roll_v6`'s sd, convention unchanged): **+2.76**.
- ⭐ **COVERAGE**: both v6 candidates supply ENSO for **1850-1947**, where the shipped model has
  `FORC_ENSO_PRE1948 = 0`, and the PSL pair they were set against has no such extension. Truncated
  to nina34's own span, roll − demean = **−5.12** — the SAME sign as the PSL pair (−1.91) and
  `detrend` (−1.78). ⇒ `like_for_like_forcing`

### ⭐ TWO RESULTS THAT FELL OUT OF THE CONTROLS
1. **Extending the ENSO forcing to 1850 costs −49.21 under a fixed 1991-2020 base and −0.71 under a
   rolling one.** ⇒ **an extension must use a rolling base.** A price, not a ruling.
   ⚠ The same confound sat **unpriced** in `roll_full`, which gate G-P had refused — *a gate that
   refuses a comparison also hides what was wrong with it.*
2. The shipped configuration is far less exposed to the 15 % gap than §1 suggests (0.55 log-units).

---

## 5. ✅ THE SPO CONSTANTS (`906bde7`) — 09-02k §8.5, DISCHARGED

Seven `SPO_SEAS_*` entries in `R/constants.R`: total **1.168**, land **0.683**, ocean **0.522**,
ocean phase **8.52**, land phase **9.29**, and the phase's 95 % bounds **[7.82, 9.20]** (registered
because `diag_so_pco2_phase.R` scores against them and **a gate's target may not be a literal in the
gate**).

**SIX OF THE SEVEN ARE `provisional`, NOT FOR WANT OF A SOURCE** — they are observations **inverted
through the model's own δ¹³C signatures**, which is `NPP_FRAC_NH_ANCHOR_1750`'s exact standing.
The total is **not** on the ledger, and was **re-measured model-free at 1.1684** rather than copied.

⛔ **A CLOSURE GATE CONSIDERED AND REFUSED.** The limbs' vector sum is **1.181**, 1.1 % above the
total, against a rounding envelope of ±0.002. **Not a defect**: the reported limbs are **bootstrap
medians**, and a median does not commute with `amp()`/`ang_mo()`. Gating it would have meant taking
the bound from the residual itself. The arithmetic is in `R/constants.R` so nobody "fixes" a limb.

**THE COPIES ARE TIED, NOT CONVERTED** — several callers are pre-registered artefacts whose gates
may not move. `test-spo-constants-tie.R` holds **34 copies across 14 files** exactly, fails when a
listed declaration disappears (so the list can only shrink), and fails on a new unlisted copy.
It **parses** rather than sources. Mutation-tested three ways.

---

## 6. ✅ THE BUILDER FOLD (`763e3fa`) — 09-02k §8.4, DISCHARGED

`diag_enso_index_baseline.R`'s four private builders are gone; `lib_enso_index.R` is the one
definition. The three constants the file still quotes in LABELS are assigned FROM the lib.

**PROVED, NOT ASSERTED:** old and new builders run side by side on the real inputs — PSL table,
ERSST box, both fixed bases, both rolling tables **and both clip counters** — all **IDENTICAL**;
then the whole diagnostic re-run from a frozen copy, and the stored rds differs from the pre-fold
one **in its timestamp and nothing else**.

⛔ **ONE RECORDED NUMBER DOES NOT REPRODUCE AND THE HANDOFF IS WRONG:** the rolling base clips
**6 of 16** scored blocks on the PSL series, not 09-02k §4's "7 of 17".

---

## 7. ⚠ NON-OBVIOUS STATE

* **Suite 1622 PASS / 6 FAIL / 2 skip.** Failure set byte-identical to standing (5 × the
  21-parameter-modes-in-a-25-parameter-build mismatch, plus `test-likelihood.R:587`'s
  `kz$hi <= 7000` guard rail left for Marcus since 09-01). ⚠ **The pass count is NOT comparable to
  09-02k's 1515** — that run quit at the default max-fails; these set `max_fails = Inf`.
* **`CCX_MODE_CANONICAL` is STILL `from90`**, a 21-parameter ancestor. Unchanged.
* **No stored-logpost test broke on adoption**, so nothing in the suite pins an absolute logpost
  against a stored mode. Every *quoted* number outside the suite did move by +56.48.
* **`INDEX_ccx.md` is 17,347 B against an 18,000 hard ceiling** — 653 to spare after this session's
  additions and a trim. **The next finding that lands there needs a merge first.**
* **`data-raw/downloads/` is GITIGNORED.** `ersst_v6_sst_mnmean.nc` is 90 MB, in `MANIFEST.csv`
  (sha256 `c35c10c8…`) and re-fetchable from `download_data.R`.
* Scratch controls that are NOT in the repo (they are folded into
  `diag_enso_v6_provenance.R` instead): the sd-matched amplitude control and the 1948-truncation
  control. Both re-run from that one file.

---

## 8. ⇒ WHAT IS NEXT

1. ⭐⭐ **THE 25-PARAMETER REFIT. NOTHING IS BLOCKING IT.** Arm `from90`, 09-01 basin, 25 params.
   ⚠ **It starts from the `demean` vector, −1512.02, NOT −1568.49.** Torch verdict: **RUNNABLE**
   (the 09-01 survey ran there, job 16732800); submission is Marcus's call, and
   `consider_torch_first` says to say the verdict out loud, which this does.
2. **STILL OWED, unchanged from 09-02j:** four observed SPO constants → **DONE this session**; what
   remains is converting the 34 tied copies **on touch**, and the bare-overlay sites under
   Ruling B's lint.
3. **OPEN, and now cheap:** the ~11 % of the nina34-vs-v6 amplitude gap that the version does NOT
   explain. It is PSL's own processing. Nobody has asked, and the shipped configuration is only
   0.55 log-units exposed to it.
4. ⚠ **`test-likelihood.R:587`'s `kz$hi <= 7000` guard rail has been failing for Marcus since
   09-01.** Still his.

**Memory written this session:** `ccx_enso_demean_shipped`, `ccx_enso_pre1948_extension`,
`ccx_spo_constants_registry`; `ccx_enso_index_baseline` updated to ADOPTED, `INDEX_ccx.md` and
`MEMORY.md` re-pointed and two stale lines fixed.

---

## 9. ⭐ ADDENDUM — THE REFIT IS RUNNING (added same day, after the review Marcus asked for)

**Torch job `16805561`**, `sbatch --array=0-45%10`, outputs in
`calibration/output/multistart_20260902_demean25/`, bundle at commit `5c35033`.
Preflight `16805527` (ids 0-5, 25, 45): **all 8 LAUNCHABLE**, port VERIFIED **rel 2.5e-13** against
a 1e-8 tolerance, **0.32 s/eval** ⇒ a 6000-eval restart projects to ~32 min of a 180 min budget.

### ⛔ THE REVIEW FOUND TWO HAZARDS, BOTH SILENT, BOTH CREATED BY THIS SAME DAY'S WORK
1. ⭐ **A 09-01 CHECKPOINT WOULD HAVE BEEN RESUMED INTO A DIFFERENT OBJECTIVE.** The resume guard
   refused stale checkpoints on `param_names` — written 09-01j because the parameter SET had moved
   twice in three days. But 09-02 moved the **OBJECTIVE** three times at a **constant 25 names**.
   Verified against the real file: `start_000_ckpt.rds` carries 25 matching names and no objective
   stamp, so it would have been **waved through** with a pre-adoption `best` of −1495.795.
   **Fixed**: every checkpoint now stamps the fixed reference point's own value and the resume
   re-reads it. Mutation-tested three ways, including that a correct stamp still RESUMES.
   ⇒ **A name that pins the PARAMETER SET does not pin the OBJECTIVE.** Hence `_demean25`.
2. **`port_targets.csv` was stale** (09-01, `53ef03d`) and would have failed every task — the gate
   working, not a bug. Regenerated at `eae5d92`.

### ⭐ AND THE KNOWN POINTS REORDERED
`start_000` −1495.7950 → **−1512.0151**; `new_basin` −1500.0507 → **−1496.2524**; `incumbent`
−1551.1222 → −1543.6880. **09-01 had `start_000` ahead by 4.26; today `new_basin` leads by 15.76.**
⇒ §8's "the refit starts from −1512.02" names where Ruling A was **priced**, not the best available
start — and a ranking that flips under an objective change is the argument for the **dispersed
survey**, which is what was launched. Best point at preflight: **id 4 (new_basin + ENSO seeding),
−1491.5671.**

### ⇒ WHAT TO DO WHEN IT LANDS
- `squeue -u ms17839 -j 16805561`; logs in `/scratch/ms17839/CarbonCycleEmulator/logs/`.
- ⚠ **"OUT OF TIME" is a NORMAL exit**, not a SLURM kill — tasks checkpoint at the 180 min budget
  and a re-submit RESUMES them (and the new stamp now proves the objective has not moved under them).
- ⚠ **ROUND 2 IS NOT THE SAME ARRAY AGAIN** — re-submit only the fixed starts and round 1's best
  dispersed ids. Resuming all 40 spends three times the fairshare on tasks already 50+ behind.
- ⛔ **THE DRIVER ADOPTS NOTHING.** Ranking and adoption are separate, and adoption is Marcus's.
