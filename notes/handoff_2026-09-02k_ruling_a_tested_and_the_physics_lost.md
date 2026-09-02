# Handoff — CarbonCycleEmulator, 2026-09-02 (fourth session of the day)
# **RULING A HAS A TESTED ANSWER: `demean`. RULING B IS DONE.**
# **AND TWO ARGUMENTS I MADE FROM PHYSICS BOTH LOST TO THEIR OWN TESTS.**
# **NEXT: Marcus adopts (or not), then the 25-parameter refit.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-02j_four_rulings_and_a_gate_that_caught_a_live_bug.md`.
This session is its §5 — the two rulings that handoff created — executed, plus two questions Marcus
asked on top.

---

## 0. STATE IN TEN LINES

1. ⭐ **RULING A ANSWERED BY TEST: `demean`** wins on **BOTH SST products and BOTH spans** with each
   index given its own refitted gammas. **Marcus's call to ADOPT is still outstanding.** §2
2. ✅ **RULING B DONE** — `CONVERT ON TOUCH + a LINT`; the lint ratchets 53 files / 61 occurrences
   and can only go down. §3
3. ⛔ **I LOST TWO PHYSICS ARGUMENTS.** The ONI rolling base and relative SST were both argued from
   mechanism and both lost their tests. §2, §4
4. ⛔ **A CLAIM WITHDRAWN:** I named the G-P gap a "v5-vs-v6 product difference" on no measurement.
   A 67 KB control shows the EXTRACTION is right (**r 1.0000**) and the gap is between two
   **PUBLISHED** indices. §4
5. ⛔ **A RESULT WITHDRAWN BEFORE IT WAS REPORTED** — a detrend fitted 1948-2024 and applied from
   1854 fabricates **+1.39 sd**; it "won" a span by 24.3. Now guarded. §5
6. ⚠ **THE SHIPPED ENSO FORCING'S AMPLITUDE IS UNCERTAIN AT ~15 %** between two published Nino 3.4
   products. This is NEW, unexplained, and affects every ENSO number. §4
7. **Suite 1515 PASS / 6 FAIL / 2 skip** — failure set byte-identical to standing; +8 is the lint. §6
8. ✅ **The memory store was consolidated** — 474 files, **0 orphans**; `INDEX_ccx.md` pulled back
   from **549 bytes off its hard ceiling** to 1,657. §7
9. ⇒ **THE 25-PAR REFIT IS STILL HELD** (Marcus, this session), pending Ruling A adoption. §8
10. ⇒ **ONE DOWNLOAD WOULD CLOSE THE LAST OPEN THREAD** — ERSST **v6** grid, 86 MB. §4, §8

Commits: `982cc96`, `994c03b`, `7a62724`, `a49eab9`, `255c20f`, `4abed13`, `5734cc2`.

---

## 1. WHAT WAS ASKED, IN ORDER

Marcus ruled on 09-02j §5's two open items, then asked two follow-ups:
- **Ruling A** — "Does the ONI rolling base make the most scientific sense?" (a QUESTION, not a ruling)
- **Ruling B** — "Convert on touch + a lint"
- **Refit venue** — "Hold the refit"
- then **"if we have two ENSO forcing options, test and see which gives the better fit"**
- and **"if we need to detrend, can we use FaIR or another source to produce a pattern without ENSO?"**
- and **"clean the memory"**

---

## 2. ⭐ RULING A: THE ANSWER IS `demean` (`982cc96`, `5734cc2`)

**THE MEAN IS A BASE-PERIOD CONVENTION, NOT A SIGNAL.** `build_calibration_data.R` sets
`ENSO_CLIM_BASE <- c(1991, 2020)` — the WMO normal, FIXED and RECENT — so the Nino 3.4 box's own
warming puts the early decades below zero **by construction**: mean **−0.2178**, trend
**+0.082 °C/dec** over 1948-2024, decadal means **1940s −0.56 → 2010s +0.08**.

**THE DECISIVE EVIDENCE IS OBSERVATIONAL, NOT AN INFERENCE FROM THE BUILD SCRIPT.** MEI.ext and
Nino 3.4 correlate **r = 0.896** over the **same 696 months** (1948-2005) and their means have
**OPPOSITE SIGN** — MEI.ext **+0.140**, Nino 3.4 **−0.274** — purely from where each pins its zero.
⇒ Two indices of one phenomenon, agreeing on the variability, disagreeing on the sign of the mean.

### THE BAKE-OFF (`calibration/diag_enso_index_bakeoff.R`)
⛔ **A FIXED-VECTOR COMPARISON WOULD HAVE RANKED AMPLITUDE, NOT INDEX** (°C sd 0.75 vs MEI's
dimensionless 1.0) — the same trap gate G-P caught one comparison earlier. So **each candidate got
its own four `gamma_enso` coordinates re-optimised**, the other 21 parameters frozen at the 09-01
basin vector. Reported on a COMMON span and a NATIVE span, because a native-span winner could be
the index that simply covers more years — coverage wearing an index result's clothes.

| | v6 1948-2005 | v6 native | v5 1948-2005 (product-matched) |
|---|---|---|---|
| **`demean`** | **−1494.32** | **−1490.86** | **−1493.13** |
| `detrend` | −1501.71 | −1495.92 | −1501.42 |
| `asis` | −1508.72 | −1504.26 | −1504.92 |
| `mei_ext` | −1500.14 | — | — |
| `relsst_lf` / `relsst` | — | — | −1507.93 / −1511.93 |

⇒ **`demean` WINS ON BOTH PRODUCTS AND BOTH SPANS, WITH THE SAME ORDERING EACH TIME.** Two
independent SST products agreeing is what makes it a result rather than a run. **Removing the mean
is worth +14.4; additionally removing the trend COSTS 5-7.** `mei_ext` is 2nd (−5.8) — competitive,
and its being a different index in different units means the answer is not a Nino-3.4-family artifact.

⚠ **`meiv2`'s common-span rank is a COVERAGE handicap, not an index verdict** — it covers only
1979-2005 of that window. A design limitation of my `EB_COMMON`, stated rather than hidden.
⚠ At FIXED gammas (the earlier, weaker test in `diag_enso_index_baseline.R`) `demean` recovered
**+56.48 = 86 %** of the −65.74. The refitted test agrees in direction and widens the gap.

**WHAT ADOPTING IT COSTS:** one line in the ENSO branch of `ccx_build_forcing()` (R/forcing.R:661-665)
plus a refit. **NOT YET DONE — it is Marcus's call.**

---

## 3. ✅ RULING B: THE LINT (`7a62724`)

`tests/testthat/test-overlay-idiom-lint.R`. A live scan finds **61 occurrences across 53 files**;
`R/model.R` is the one exemption (it IS `ccx_overlay_par()`). **Three assertions, and the second is
the load-bearing one:**
- **SUBSET** — an unlisted offender fails. Catches a new site.
- ⭐ **NO-STALE** — a LISTED file that no longer offends **also fails**, so converting one FORCES its
  removal. Without this the baseline decays into a list of files that *used to be* wrong while
  SUBSET keeps passing and guards nothing.
- **NO-GROWTH** — the total may not exceed 61; SUBSET alone is blind to a second loop in a listed file.
⇒ **The count is a RATCHET.** Mutation-tested in both directions. ⚠ It caught its OWN fixtures on
first run — they are now split across source lines; that was the lint working, not a reason to
exempt a second file. ⇒ [[baseline_list_must_shrink]]

---

## 4. ⛔ THE PROVENANCE HOLE I OPENED AND HALF-CLOSED (`994c03b`, `a49eab9`, `255c20f`)

**GATE G-P** (in `diag_enso_index_baseline.R`) refuses to difference the local ERSST**v5** grid
against the shipped index: deseasonalised over 1991-2020 they agree in PHASE (**r 0.984**) and
disagree in AMPLITUDE (**slope 0.842**), **4.8×** a bound DERIVED from the sd spread of the four
conventions it must separate. Mutation-tested BOTH ways inline.

⛔ **I CALLED THAT GAP "v5-vs-v6" WITHOUT MEASURING IT. WITHDRAWN.** A **67 KB** CPC download
(`ersst5.nino.mth.91-20.ascii`, same ERSST **v5**, same 1991-2020 base) holds version and base fixed
and isolates METHOD:

| | r | slope | Δclim |
|---|---|---|---|
| **METHOD** local grid vs CPC, same v5 | **1.0000** | **0.997** | **+0.004** |
| **PRODUCT** CPC vs PSL `nina34.data`, both published | 0.9836 | 1.153 | −0.602 |

Monthly climatologies match CPC to **0.02 °C in all twelve months**.
⇒ **THE EXTRACTION IS RIGHT.** ⭐ **AND THE SHIPPED FORCING'S AMPLITUDE IS UNCERTAIN AT ~15 %**:
PSL's `nina34.data` — the file the whole pipeline runs on — is **0.60 °C warmer** in climatology and
**15 % WEAKER in ENSO amplitude** than CPC's published ERSSTv5 Nino 3.4.
⚠ **STILL NOT SHOWN TO BE v5→v6.** The window is 1991-2020, densely observed, where two ERSST
versions should agree BEST — they diverge in the SPARSE early record, which is not where this was
measured. ⇒ **OPEN. Closing it needs the v6 grid** —
`downloads.psl.noaa.gov/Datasets/noaa.ersst.v6/sst.mnmean.nc`, **86 MB**, probed live, through the
extraction `a49eab9` verifies. ⚠ **There is NO small published v6 Nino 3.4 index reaching back far
enough** — the `nina34.long.*` paths are **404**; five candidates checked.

⚠ **THE `roll` (ONI) RESULT IS THEREFORE A LOWER BOUND**: it clips **7 of 17** scored blocks, and the
clipped ones are the EARLY blocks where the offset is largest. Unclipping needs that same 86 MB file.

---

## 5. ⛔ THE DETRENDING QUESTION — FaIR CANNOT, AND THE THING THAT CAN, LOSES (`4abed13`, `5734cc2`)

**FaIR CANNOT DO THIS.** It is a globally averaged energy-balance model: no spatial pattern, no
tropical Pacific, no Nino 3.4 box. It emits GMST. Getting a forced Nino 3.4 trend from it needs
pattern scaling on a CMIP-derived coefficient — a model-derived quantity, which
[[threshold_from_obs_or_law]] makes a last resort.

⭐ **NO MODEL IS NEEDED. RELATIVE SST** — Nino 3.4 anomaly minus the tropical-mean (20°S-20°N)
anomaly, same product, same base — removes the forced warming **observationally**, because the
tropical mean IS the forced signal, measured rather than estimated:

| over 1948-2024 | mean | sd | trend/dec |
|---|---|---|---|
| Nino 3.4 anomaly | −0.1962 | 0.877 | **+0.0774** |
| tropical mean 20S-20N | −0.2223 | 0.335 | **+0.1178** |
| **relative SST** | **+0.0261** | 0.707 | **−0.0403** |

Decadal means go from a monotone **−0.90 → +0.04** ramp to **−0.20 → −0.09** of wiggle. Mean and
trend both leave with no statistical fit and no chosen window. It spans **1854-2026**.

⛔ **AND IT RANKED LAST.** The reason is MEASURED, not a bug: **the tropical mean is ITSELF 44 % ENSO**
(**r 0.667** against Nino 3.4 at **+1 month**), so subtracting it whole removes the lagged tropical
response along with the forced warming — **19 % of the index sd** (0.877 → 0.707).
✅ **The low-pass fix works and is still not enough**: subtracting only the **21-yr** low-pass
tropical mean (above the 2-7 yr ENSO band) restores amplitude to within **1 %** (sd 0.866) and
recovers **+4.0** — and still sits **14.8 behind plain demeaning in its own product**.
⇒ **Tried, measured, not adopted.** `eix_relative_sst(lowpass = TRUE)` is kept in the lib.

⛔ **A RESULT WITHDRAWN BEFORE IT WAS REPORTED.** `n34_v5_detrend` "won" the native span by **24.3**.
That is an artifact of **my own `eix_detrend`**: fitted on 1948-2024 and applied to 1854-2026, it
imposes **+1.22 °C (+1.39 sd) at 1854**, over a span **54 % of which is outside the fitting window**.
The model was exploiting a fabricated 19th-century ENSO ramp.
✅ **`eix_detrend()` now REFUSES to extrapolate** past `EIX_EXTRAP_MAX = 0.05` unless the caller
passes `allow_extrap` and says so. ⚠ **A DETREND IS ONLY VALID INSIDE ITS FITTING WINDOW.**

⚠ **THE CAUTIONARY NOTE ON ME.** I argued from physics for the ONI rolling base, then for relative
SST. **Both lost.** The physics said what the index *ought* to represent; the fit said what the
model can *use*. Neither argument survived contact with its own test — and each test was cheap.

---

## 6. ⚠ NON-OBVIOUS STATE

* **Suite 1515 PASS / 6 FAIL / 2 skip.** Failure set byte-identical to the standing one — 5 are the
  21-par-modes-in-a-25-par-build mismatch (`test-mode-decode.R:15`/`:29`, `test-mode-file.R:109`×2,
  `:203`), the 6th is `test-likelihood.R:587`'s `kz$hi <= 7000` guard rail left failing for Marcus
  since 09-01. **+8 over 1507 is the new lint.** `INDEX_ccx.md`'s stale "1507" was corrected.
* **`CCX_MODE_CANONICAL` is STILL `from90`**, a 21-parameter ancestor. Unchanged.
* **`calibration/lib_enso_index.R` is the ONE definition of every candidate index.**
  `diag_enso_index_baseline.R` still carries its OWN private copies of `ei_read_psl` /
  `ei_fixed_base` / `ei_nino34_ersst` — ⚠ **THE PLANNED REFACTOR TO SOURCE THE LIB WAS NOT DONE.**
  Two definitions of the same builders now exist. **Do this on the next touch of either file.**
* **`data-raw/downloads/` is GITIGNORED.** The two new inputs (`ersst5.nino.mth.91-20.ascii`,
  `mei_ext_table.html`) are recorded in `MANIFEST.csv` AND re-fetchable from `download_data.R`.
  ⚠ MEI.ext's **flat file is 404 upstream** — only the HTML table survives, so it is parsed from
  HTML and the tracked copy matters more than usual.
* **`EB_COMMON = 1948-2005` is not common to `meiv2`** (1979+). Its common-span rank is coverage.
* **Nothing was adopted.** `data/forcing_enso.rds` and `R/forcing.R` are UNCHANGED; every result
  here comes from wrapping `ccx_build_forcing()` for one measurement and restoring it.

---

## 7. ✅ THE MEMORY CONSOLIDATION (Marcus: "clean the memory")

**474 files, 0 ORPHANS, 0 real broken links** (the 2 flagged are R's `[[ ]]` syntax inside code
spans — audit-regex false positives). **Nothing retired: 474 in, 474 out.** The rot was in ONE index
and it was mostly mine.

**`INDEX_ccx.md` 17,451 → 16,343 B**, i.e. from **549 bytes off the hard ceiling to 1,657**.
- My own 09-02 additions were the two worst lines in the file (**473 and 388 B/link** against a
  **99 B median**). Rule 2: a single-link line over 300 chars is a memory summary, not a pointer.
- **The ENSO arc was being told THREE times** — ledger item 5, the four-way bullet, and my new
  lines. Now ONE ordered arc under "Interannual variability" with a pointer from the gates section.
- Ledger items 1-4 merged; commit hashes dropped (rule 3 licenses exactly that).
- **GATE G demoted to `INDEX_ccx_ocean.md`** (10,744 → 11,207) — it is an ocean finding, and rule 4
  puts a finding in its sub-index. Moved WHOLE; not one number dropped.
- Two header paragraphs that restated bullets beneath them, cut. One literally ended
  "`INDEX_ccx_ocean` has it".
- **STALE FACT FIXED:** the suite line read 1507; re-measured 1515.

**`MEMORY.md` NEEDED NOTHING** — content **12,023 B against a 12,000 soft target**, median 99 B/link.
Left alone rather than manufacture work.

⚠ **STILL OVER SOFT, DELIBERATELY:** `INDEX_ccx_arch` **16,621** (1,379 from hard), `INDEX_slr`
15,168, `INDEX_cmp` 14,912. Over-soft is "merge when convenient". **`INDEX_ccx_arch` is the one to
watch** — it is now the fattest, and unlike `INDEX_ccx` it has no obvious internal duplication left
after the 09-02j merge. If it crosses hard, the honest fix is a **second archive tier**, not another
compression pass.

---

## 8. ⇒ WHAT IS NEXT

1. ⭐ **MARCUS ADOPTS `demean` (or not).** One line in `ccx_build_forcing()`'s ENSO branch. Everything
   else is queued behind this.
2. **THEN THE 25-PARAMETER REFIT.** Arm N, 09-01 basin, 25 params. **HELD by Marcus this session.**
   ⚠ Its starting point depends on (1): at the same vector, `asis` scores **−1568.49** and `demean`
   **−1512.02**. Torch verdict when it goes: **RUNNABLE** (the 09-01 survey ran there, job 16732800);
   submission is Marcus's call.
3. **OPTIONAL, and the only way to close §4:** pull the **ERSST v6 grid, 86 MB**. It answers TWO
   things at once — whether the 15 % amplitude gap is a version effect, and whether an UNCLIPPED
   ONI rolling base beats `demean`.
4. **ON TOUCH:** fold `diag_enso_index_baseline.R`'s private builders into `lib_enso_index.R` (§6),
   and convert bare-overlay sites under Ruling B's lint.
5. **STILL OWED, unchanged from 09-02j:** the four observed SPO constants (total 1.168 / land 0.683 /
   ocean 0.522 / phase 8.52) are not in `R/constants.R` and are replicated across ~10 diagnostics.

**Memory written this session:** `ccx_enso_index_baseline` (Ruling A, the bake-off, the withdrawals),
`ccx_mei_ext_option` (MEI.ext as evidence not forcing), `baseline_list_must_shrink` (the ratchet
lesson). All three reachable from `INDEX_ccx.md`; the second also from `MEMORY.md`.
