# Handoff — CarbonCycleEmulator, 2026-09-02 (second session of the day)
# **THE CODE REVIEW RAN. THE MODEL CODE WAS RIGHT EVERY TIME IT WAS SUSPECTED;**
# **THE CHECKS WERE NOT. TWO DIAGNOSTICS HAD BEEN REPORTING WITH THEIR**
# **MECHANISM SILENTLY OFF, AND MY OWN BEST ARGUMENT WAS REFUTED BY ITS**
# **OWN PRE-CHECK.**
# **NEXT: Marcus's four rulings (§6), THEN the refit.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at **`d597a60`**.
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Reads before this one:** `handoff_2026-09-02_the_limb_the_pair_and_the_shipped_alphas.md` — this
session is its §6 (code review) executed, plus four things Marcus asked for on top. Its §7 (the
refit) is **still not started, and is now blocked on a ruling it did not anticipate.**
**Suite 1457 PASS / 6 FAIL / 2 skip** throughout, failure set byte-identical to the morning's.

---

## 0. STATE IN NINE LINES

1. ⚠ **A SECOND SESSION WAS LIVE IN THIS REPO WHEN THIS ONE STARTED.** Marcus ruled hold; it
   finished (`be0397b`) and released. §1
2. ⛔ **GATE Q WAS IN NO GATE REPORT** — the refit's own acceptance criterion could not be run. §2
3. ⛔ **GATES 4 AND 5 HAVE NO BOUND AND CANNOT FAIL.** Line 135 was the report's only verdict. §2
4. ⭐ **GATE 7's STANDING FAILURE IS A SIGMA MISMATCH, NOT A DEFECT** — 0.5 here vs 1.5 in the
   likelihood. **Do not chase it in the refit.** §2
5. ⛔ **TWO DIAGNOSTICS RAN WITH THEIR MECHANISM OFF**, both verified by running them. §3
6. ✅ **BOTH SPLIT CONTRACTS NOW HARD-ERROR** — and "both active" is NARROWER than it sounds. §4
7. ⛔ **MY IDENTIFIABILITY ARGUMENT FOR THE ENSO SPLIT IS DEAD.** `soil_fast` IS old
   photosynthate. The recommendation changed as a result. §5
8. ⭐ **THE ALPHA REVIEW CAME BACK CLEAN** — all four sites, marshalling, spinup, ¹⁴C. §5
9. ⇒ **FOUR RULINGS OWED before the refit.** §6

---

## 1. ⚠ THE COORDINATION FACT, BECAUSE IT WILL RECUR

At session start, **another Claude session (PID 51869, started 06:07) was mid-work in this same
repo** and had run the suite six times that morning; `run_tests.R` was executing as this session's
first commands landed. Marcus ruled **hold**. That session then committed `be0397b` (the
`alpha_as_tdep` declaration + the morning handoff) and went idle.
⚠ **`ps` is how this was caught, not the git status** — the working tree looked like a normal
uncommitted change. Two agents in one repo is the `never_edit_a_running_script` hazard plus a git
index race. **Check for a live interpreter before editing a shared repo.**

---

## 2. THE GATE DEBUG (`1143744`) AND THE LEDGER (`d597a60`)

Ran every gate at every arm and mutation-tested the two that have bounds.

| gate | source class | bound | scored? | POWER | at `from90` |
|---|---|---|---|---|---|
| 4 AF | OBSERVATION | **NONE** | yes | **~none**, near-algebraic | 0.411 vs 0.431 |
| 5 bomb ¹⁴C | **OBSERVATION** (Hua 2022) | **NONE** | stream yes, functional no | moderate, best-sourced | lag **0.97 vs 1.34** |
| 7 sinks | OBS **+ MODEL** | `\|z\|<=DG_G7_NSD` | **yes** | **none out-of-sample** | land **+2.33σ** |
| Q air-sea δ¹³C | **OBSERVATION** (Quay 2003) | `n_sd<=DG_Q_NSD`=2 | **NO** | **REAL — the only one** | **0.80σ PASS** |
| 12/12b IRF | **MODEL** (Joos 2013) | published / constructed | no | real, last-resort source | TH20 BELOW |

⛔ **GATE Q HAD NO DIAGNOSTIC CALLER.** It shipped with the alphas (`6263bf6`); its only caller was
`test-alpha-as.R:113`. So the morning handoff's §7 acceptance criterion — *"GATE Q must still
PASS"* — **could not be checked by running either gate report.** Now measured per arm:
**defaults 1.37 / from90 0.80 / pin90 0.76**, all PASS; retired pair 6.02 / 6.59 FAIL.
⚠ **AND THE QUOTED σ REPRODUCES AT NO ARM.** The morning handoff §3 and
[[alpha_as_t_dependent_shipped]] both say **"6.4σ → 1.0σ"**. Nothing gives 1.0. The PASS and the
discrimination are unaffected; **the number is wrong and should be corrected when next quoted.**

⭐ **GATE 7 IS A STRICTNESS MISMATCH, AND THIS IS THE ONE THAT CHANGES THE REFIT.** The likelihood
scores the land sink at `LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE` = 0.5 × 3.0 = **1.50 GtC/yr**;
the gate judges the **same stream on the same data** at **0.50**. At the likelihood's own sigma the
shipped mode sits at **+0.78σ — a PASS.** ⛔ **So gate 7's failure is NOT a model defect to chase.**
✅ Mutation-tested and it does have power *as a bound*: `beta_max` ×0.5→×2.0 walks land
1.663 → 6.697, z −1.49 → +8.57, monotone, failing both sides and **PASSING at ×0.80**
(land 2.819 z+0.82, ocean 3.208 z+0.01).
⚠ Gate 7's source is also MIXED: GCB's ocean sink is a **model product**, its land sink a **budget
residual**. Not a clean observation.

⛔ **GATES 4 AND 5 PRINT TABLES, NOT VERDICTS**, and both misses are real and unbounded: gate 5's
NH→SH lag is 28 % low and its peaks ~0.95 yr late; gate 4's decadal spread is 0.030 against GCB's
0.051 under a stated *"must not be SMOOTHER than this"* test. **Giving them bounds is a design
decision and was NOT made here.**

⚠ **"GATE 4" IS TWO DIFFERENT GATES.** `diag_gates_in_the_new_basin.R` defines its own GATE 1/2/3/4
as hard `stop()` guards (feasibility, encoding, bands, objective-purity) in the same file that
reports DESIGN gate 4/5/7. Flagged, not renamed.

✅ **Fixed, no judgement required:** `DG_G7_NSD` now names gate 7's bound in the library (it was a
bare literal `1` duplicated into BOTH callers' verdict lines, while the library header claims "one
kernel, two callers" — the kernel was centralised 08-31f, the verdict was not).
⚠ It is **1 where `DG_Q_NSD` is 2**, both distributional claims on a stated sigma. Recorded at the
constant, **NOT ruled on**.

⭐ **THE LEDGER** (`DG_LEDGER` + `dg_print_ledger()`, printed by the canonical report) gives each
gate a source class, bound + claim kind, scored?, and power. **The power column is what nobody had
written down**, and it re-reads the whole set.
⛔ **NOT ONE LAW-DERIVED GATE EXISTS.** Everything is observational or model-derived. Candidates
named, none built: carbonate/Revelle consistency, Henry's-law solubility, and — **most valuable,
since gate 12a reports an ocean-CAPACITY defect it cannot localise** — an **ocean DIC inventory vs
GLODAP**, observational and currently ungated.
⇒ **Verdict on "rewrite the gates from scratch": NO, restructure.** The estimators are the
expensive part and they are sound (gate 5's parabolic peak refinement, gate 7's linear end
extrapolation matched to the objective, gate 4's self-consistent scaled denominator). The
deficiencies are **bounds, provenance and power — not sources.**

---

## 3. ⛔ TWO DIAGNOSTICS RAN WITH THEIR MECHANISM OFF (both verified by running them)

**(a) `diag_gamma_iav.R:62` — [[intersect_is_a_silent_default]], live.** It reads the canonical mode
raw, then `for (n in intersect(names(p0), CCX_PARAM_NAMES)) p0[[n]] <- pm[[n]]`. `from90` is a
**pre-split 21-parameter** vector, so `pm[["gamma_enso_land_NH"]]` is `NULL` — and **assigning NULL
DELETES the element.** All four ENSO names vanish, `ccx_gamma_enso()` sees neither split names nor
scalar, returns zeros, and the fitted `gamma_enso = 0.8512` is dropped on the floor.
**MEASURED COST: 3.68 ppm of CO₂_NH over 1960-2000** against the correctly-migrated vector. Its
whole `q10` scan ran with ENSO OFF. ⛔ **NOT FIXED — needs a re-run and possibly a quarantine.**
⚠ `dg_vector()` in the gate library uses the SAME idiom and is safe **only because the next line
calls `ccx_set_enso(p, pm)`** and repairs the deletion. That ordering is load-bearing and was
undocumented.

**(b) `diag_gross_cancellation_geometry.R:237` — a 15-point sweep of a dead knob.** ✅ **FIXED**
(`95e97ab`). It set the RETIRED scalar `seas_lag_p`, which lost to the split fields by silent
precedence. Verified: setting 0.5 / 1.75 / 4.0 **all returned 2.25**. The `GC_LAG_GRID` sweep ran at
constant lag and its printed maximum was read off a flat curve.
⚠ **THAT FILE'S LAG-AXIS NUMBERS THEREFORE CHANGE.** Deliberately NOT re-run: the old ones were
meaningless, so it is a re-measurement to make on purpose, possibly with a quarantine. Its other
sections do not go through that assignment and are unaffected.

---

## 4. ✅ BOTH SPLIT CONTRACTS HARD-ERROR (`95e97ab`) — AND "BOTH ACTIVE" IS NARROWER

Marcus: add a hard error where a legacy and a current branch are both active, after checking no
legacy branch is in use.

⛔ **THE AUDIT FOUND WHAT MADE IT NON-TRIVIAL: `ccx_migrate_par_set()` NEVER DROPPED THE
`seas_lag_p` SCALAR** while its `gamma_enso` branch always had. Every migrated ancestor carried
BOTH names, so a naive error fires on `from90` immediately. ⭐ **The tell was the parameter COUNT:
migration returned 26 names against `CCX_PARAM_NAMES`' 25**, and the extra one was that scalar.
Dropping it is numerically inert (split filled FROM it): 1.7677/1.7677 preserved, gate 7 land
3.5774, gate Q 0.8025, AF 0.41128 all unchanged.

⛔ **MY FIRST ATTEMPT WAS TOO COARSE AND A TEST CAUGHT IT** (suite 6 → 7).
`test-seas-lag-split.R:47` pins `lag_p(sh = 2.4, legacy = 1.9)` → `c(1.9, 2.4)` **on purpose**,
commented *"an explicit field WINS over the legacy scalar"*. **The test was right; my contract was
wrong; the test was NOT touched.** A legacy scalar beside a **PARTIAL** split is not an ambiguity —
it is what FILLS the absent half, and `ccx_migrate_par_set()` calls the resolver for exactly that,
so an `any()` rule breaks the migration **from inside itself**.

⇒ **"BOTH ACTIVE" = THE SCALAR IS SHADOWED BY A COMPLETE SET:**

| shape | result |
|---|---|
| complete split + legacy | **ERROR** — nothing to fill, two answers |
| partial split + legacy | resolves (migration's own fill path) |
| legacy only | resolves, pre-split ancestor bit for bit |
| neither | the named default |

⭐ **`ccx_gamma_enso()` HAD THE IDENTICAL LATENT BUG, `any()` → `all()`.** A legacy scalar beside a
partially split list errored, and that error came out of `ccx_migrate_par_set()` itself. Dormant
only because every stored ancestor has all four names absent; it would have fired the first time one
carried three of four.

✅ **LEGACY-BRANCH AUDIT, the answer to the question asked: nothing live uses one.** The
25-parameter survey vectors carry neither retired name; `ccx_default_params()` carries neither;
`alpha_as_tdep` is 1. The scalar-only branch stays reachable and correct for pre-split ancestors,
which is its purpose. The only live writer of a retired name was §3(b).

---

## 5. THE §6 REVIEW ITSELF

**(b) THE T-DEPENDENT ALPHAS: CLEAN.** Formula identity R↔C++ term for term, both in **Celsius**;
**all four application sites** (invasion, evasion, both ENSO ocean limbs, prescribed sink) call
`ccx_alpha_as` once per hemisphere per step on the **seasonal** SST and reuse it — no site reads
`aux$sst`; marshalling **set-difference empty both directions** (nine fields); spinup correct via
`R/spinup.R:125`, evaluated at the annual mean as a fixed point must be; ¹⁴C inheritance verified
(`f14 = F_C * r14`, no fractionation, both cores, header now states the reasoning).
⚠ Two documentation gaps, no numerical defect: **`ALPHA_AS_FCO3` box-averaging** is undocumented
(0.082 is the mean of measured NH 0.0856 / SH 0.0786, which survive only inside the constant's
`source` string), and **GATE Q re-implements the `eps_dicg` polynomial** rather than calling
`ccx_alpha_as` — deliberately, to stay non-self-referential, but a **structural** change to the
alphas would desynchronise it silently.
⛔ **A CLAIM WALKED BACK:** the review flagged silent extrapolation past Zhang's 21 °C kinetic
anchor at ~21.2 °C. It used a seasonal half-amplitude of ~2.0-2.24; the **fitted** value is 0.937 at
`from90` and **1.069 across all ten survey starts**. Measured peaks **20.23** and **20.07 °C** —
inside the anchor with 0.8-0.9 °C margin. **Not a defect.** Still worth a range warning like
`carb_constants` has, since `sst_seas_amp_NH` is free in the refit and the margin is under 1 °C.
⚠ **A PREMISE CORRECTED:** `R/cpp.R:110,115,126` justify defensive defaults by saying a missing
field "unpacks as garbage". For **named** reads that is wrong — `Rcpp::List::operator[](const char*)`
**throws**. The morning handoff's "uninitialised memory" framing rests on this. Audit was clean
either way; the stated *reason* is inaccurate.

**(a) THE ENSO SPLIT: sound where it matters.** One resolver, both cores through it, R/C++ parity
clean, and the **sign logic is correct** — `ge_ocn > 0` → `iatm → iml` carrying `a_as$down`, the
invasion alpha, in both cores, resolved from the seasonal SST ahead of both call sites.
⚠ **The four coefficients are strongly ANTIsymmetric** (land −0.2457 / +1.3583, ocean −0.9502 /
+1.1870) where both seeds assumed symmetry, so it is data-driven — but the totals fall short of the
design's ask (land 1.113 vs 1.726; ocean +0.237 vs +0.653). **The fit spent the four coordinates on
an interhemispheric GRADIENT lever, not on ENSO amplitude.** Nobody has ruled on that.

---

## 6. ⛔ THE ENSO LAND LIMB — AND THE ARGUMENT I MADE FOR IT WAS REFUTED (`d597a60`)

**THE DEFECT.** The ENSO land term is ONE SIGNED FLUX out of `soil_fast` at `alpha13 = 1`. It is
**not** a correction to NEP — NEP runs `atm ↔ leaf/wood` then litter → soil; this is an independent
draw on a different pool. It reverses simply because `γ × enso` changes sign, and the reverse limb
moves carbon **atm → `soil_fast`: a land uptake that never passes through vegetation.**
⛔ **`add_flux`'s guard is STRUCTURALLY BLIND to it** — it fires only on `alpha13 != 1`, so it can
never see a reversing flux that *should* carry fractionation and does not. [[no_power_null]]
Measured at the 25-par basin over the ENSO-active record (1948-2024, 924 months, 39 % El Niño):

| | γ | reverse limb | gross C forward | gross C REVERSE |
|---|---|---|---|---|
| NH | −0.2457 | 39 % of active months | 8.05 GtC | 3.92 GtC |
| SH | **+1.3583** | **61 %** | 21.69 GtC | **44.47 GtC** |

**For the SH the undesigned direction is the MAJORITY direction and moves twice the carbon.**
⭐ All three limbs sit in the same function and the other two already resolve per direction: the
seasonal NEP limb nine lines earlier (`alpha13 = if (seas > 0) aux$alpha_photo else 1`) and the ENSO
**ocean** limb ~100 lines later (two explicit limbs, whose comment cites the 08-25e bug as its
reason). **The ocean half got directional treatment on 09-02; the land half did not.**

⛔ **AND THE PRE-CHECK REFUTED MY OWN ARGUMENT FOR THE FIX.**
`calibration/diag_enso_two_channel_precheck.R`, ~40 s, **IMPLEMENTS NOTHING**. I argued a
productivity limb and a respiration limb would be **isotopically identifiable**. They are not:

* A respiration limb draws `soil_fast` at **−24.9 to −26.4 ‰**; a GPP limb withholds carbon at
  `δ_atm + ε_photo` = **−25.2 to −26.8 ‰**. **They differ by 0.32-0.48 ‰, because SOIL_FAST *IS*
  OLD PHOTOSYNTHATE** — the only contrast is Suess drift over its ~2 yr turnover.
* On whole-record gross carbon: **0.04 ‰** of atmospheric δ¹³C against a **0.05 ‰** representation
  error — **BELOW NOISE**. ¹⁴C is the larger contrast (**+35 to +52 ‰** post-bomb) and still comes
  to **3.6 ‰** against a fitted `sigma_d14c` of **6.1** — **ALSO BELOW NOISE**.
* ⇒ **The data CANNOT apportion the term.** A fitted partition would be a judgement width wearing a
  fitted coefficient's name — the [[ccx_npp_frac_anchor]] / `npp_frac_NH` failure mode.

⛔ **NOR IS IT A DOUBLE-COUNTING FIX.** GMST does carry ENSO (**r = +0.41**, **+0.53 at the 3-month
lag**), but 1 sd of ENSO moves GMST only **0.042 °C**, which at the mode's `q10 = 1.136` is
**+0.054 %** of respiration = 0.032 GtC/yr against the explicit SH term's 1.025 — **3.2 %**. Weak
because q10 rides **global** mean temperature where the physics is **tropical land** temperature and
moisture. ⚠ **The model has NO moisture variable at all** — no precipitation, soil water, drought or
aridity anywhere in `R/model.R`.

⇒ **REVISED RECOMMENDATION (Marcus's call): make the term ONE-WAY, but do NOT split it into two
FITTED channels.** One coefficient per hemisphere as now, **no new coordinate**. A one-way limb
removes the unphysical pathway and **dissolves** the alpha question instead of ruling on it. Since
the channels are near-degenerate, which one carries the term barely moves the fit — but it decides
physical fidelity, and the **GPP/moisture limb is the one the model LACKS ENTIRELY**.
⚠ **Fire — the third observed limb (Liu et al. 2017 attributed the 2015-16 anomaly across three
tropical continents by GPP, respiration and fire) — stays unrepresented either way.**
⚠ My recollection of that attribution is that the three were comparable, not that one dominated.
**Check the paper before it is load-bearing.**

---

## 7. ⇒ FOUR RULINGS OWED BEFORE THE REFIT

1. **Implement the one-way ENSO land term?** It changes what gets fitted, so **§7's refit should not
   start first.** Recommendation in §6.
2. **Gates 4 and 5 bounds**, and **`DG_G7_NSD`=1 vs `DG_Q_NSD`=2**.
3. **The GLODAP ocean-inventory gate** — my pick if only one thing is built: it targets a known open
   defect, is observational not model-derived, and nothing currently tests it.
4. **`diag_gamma_iav.R`** (fix + re-run + quarantine?) and **`diag_gross_cancellation_geometry.R`'s
   lag axis** (re-measure + quarantine?).

**THE REFIT (morning handoff §7) IS OTHERWISE UNCHANGED** and still owed: 25-parameter set, arm N,
from the 09-01 basin. ⭐ **This session independently corroborated the one-basin finding** — all ten
starts at **−1495.795/797** with parameters identical to three decimals — which is the evidence the
polish-vs-dispersed-multistart judgement rests on. Torch verdict out loud before launching
([[consider_torch_first]]); the traps in that handoff still apply.

---

## 8. ⚠ NON-OBVIOUS STATE

* **`CCX_MODE_CANONICAL` is STILL `from90`**, a 21-parameter ancestor; 5 of the 6 standing suite
  failures are that mismatch. Migration now yields **25** names (was 26).
* **A memory description carried a wrong number and was corrected**:
  `ccx_land_limb_worse_at_enso25`'s frontmatter said the overshoot grew **+18.7 % → +62.1 %**. The
  source table's "put ocean AT obs" column reads **1.424 → 1.621 = +42.4 % → +62.1 %**, which the
  body, the handoff and the CHANGELOG all state. The 1.187 behind "+18.7 %" is JOINT_hi's *SPO
  total/obs* — a different row of a different table. ⛔ **The upstream cause is still there:**
  `notes/collect_2026-09-02_..._land_limb_got_worse.md` **contradicts itself**, title line 3 saying
  +18.7 % and body line 74 saying +42.4 %. One-line fix, not made (committed artifact).
* **Still owed, unchanged from the morning:** the four observed SPO constants (total 1.168 / land
  0.683 / ocean 0.522 / phase 8.52) are **not in `R/constants.R`** and are replicated across ~10
  diagnostics.
* The gate-7 `beta_max`×0.80 pass is a **mutation-test artefact, not a proposal.** It says the gate
  is satisfiable; it is not a suggestion to move `beta_max`.

---

## 9. WHAT LANDED

`1143744` the gate debug + `DG_G7_NSD` + GATE Q in the report; `95e97ab` both split contracts
hard-erroring, the migration drop, and the fixed lag sweep; `d597a60` the ENSO pre-check + the gate
ledger. (`be0397b`, the morning session's, precedes them.)
**New file:** `calibration/diag_enso_two_channel_precheck.R`.

**⚠ THE PATTERN, AND IT SHOULD WEIGHT HOW THIS SESSION IS READ.** The morning handoff closed by
noting all three of its errors were **in checks, not in the code they checked**. That held all day.
Every defect found today was in a gate, a diagnostic, a doc comment, or a memory description — **the
model code was correct every time it was suspected.** And my own two errors were the same shape: a
blanket `any()` contract that a test caught within one suite run, and a pre-check that **printed an
empty table instead of erroring** because `alpha_photo` lives in aux and `(NULL - 1) * 1000` is
`numeric(0)`, which `sprintf` turns into `character(0)`. Both now guarded.
