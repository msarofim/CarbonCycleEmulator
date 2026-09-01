# Handoff — CarbonCycleEmulator, 2026-09-01b
# **THE FOUR-PARAMETER ENSO DESIGN IS BUILT. 22 → 25 PARAMETERS.**
# **Nothing is fitted; the default is behaviour-preserving to the BIT.**
# **The riskiest thing here was not the physics — it was one name becoming four.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**

**Reads before this one:** `handoff_2026-09-01_enso_arc.md` (the measurement and the design —
§2 the regression, §5 the compensating-error state, §6 the specification this implements) and
`handoff_2026-08-31f_gates_repriced_and_torch_ready.md` §8/§9, which still stand unchanged.

---

## 0. STATE IN SIX LINES

1. ✅ **`gamma_enso` → `gamma_enso_land_NH/_SH` + `gamma_enso_ocn_NH/_SH`.** R core, C++ twin,
   parameter table, migration, app, tests. **22 → 25 fitted parameters.** §1
2. ✅ **The default is BEHAVIOUR-PRESERVING TO THE BIT** — the thing the `gamma_diff` adoption did
   not have. A legacy list reproduces the old model at `tolerance = 0`. §2
3. ⛔ **THE REAL HAZARD WAS THE RENAME, NOT THE PHYSICS.** `p$gamma_enso <- …` existed at ~110 call
   sites and would have become a line assigning a field NOTHING READS — every one of them running
   with ENSO **switched off**, silently. A guard turned all of them into a loud stop. §3
4. ⭐ **The isotope choice is implemented and TESTED**, not just asserted: the ocean term's applied
   fractionation is pinned to `alpha_as_down`. That is what makes the four identifiable. §4
5. ⚠ **ONE METHODOLOGICAL CHOICE WANTS MARCUS'S RATIFICATION**: each of the four keeps the original
   N(0, 2), which WIDENS the implied prior on the land total by √2. §5
6. ⚠ **A 25-PARAMETER REFIT IS NOW OWED, AND IT STACKS with the 22-parameter one.** Nothing is
   adopted; `CCX_MODE_CANONICAL` is untouched. §6

---

## 1. WHAT LANDED

| file | what |
|---|---|
| `R/model.R` | `ccx_gamma_enso()` (the ONE resolver + absence contract), `ccx_set_enso()`, `CCX_ENSO_PARAMS`, `CCX_ENSO_SHARE_LEGACY`, `CCX_GAMMA_ENSO_DEFAULT`; the land flux per hemisphere; **the new ocean flux**; `aux$enso_share` REMOVED |
| `src/ccx_core.cpp` | `Par.gamma_enso_land[2]` / `gamma_enso_ocn[2]`, both fluxes, `Aux.enso_share` removed |
| `R/cpp.R` | resolves the four **through `ccx_gamma_enso()`**, never a second literal |
| `R/calibrate.R` | four table entries; the migration contract; `ccx_load_mode()` overlay + refusal hint |
| `tests/testthat/test-enso-split.R` | **new, 56 assertions** |
| ~110 call sites | `p$gamma_enso <- src$gamma_enso` → `p <- ccx_set_enso(p, src)` |

**The ocean term.** Positive coefficient × positive index = **more uptake**, which is the observed
sign (GCB's ocean sink is r = +0.535 with Niño3.4; the model gives −0.51 through SST alone).
Emitted as **TWO EXPLICIT LIMBS with alpha resolved per direction** — invasion carries
`alpha_as_down`, the La Niña reversal carries `alpha_as_up`. One signed flux with a single alpha is
the 08-25e seasonal-NEP bug exactly, and no conservation gate can see it. Both limbs are
**unlabelled**, so the trace classifies them `as_down`/`as_up` and `ocean_net` counts them — the
same call, and the same reason, as the artificial mid-century sink.

## 2. THE ABSENCE CONTRACT — AND WHY THE OCEAN GETS ZERO

```
field present                     -> use it
absent, legacy `gamma_enso` present -> LAND = scalar x the retired 0.5/0.5 share
                                       OCEAN = 0
neither                           -> CCX_GAMMA_ENSO_DEFAULT (= 0)
```

⭐ **The ocean pair gets 0 rather than a share of the land coefficient because THE MECHANISM DID NOT
EXIST.** A fitted ancestor holds no opinion about it; inventing one would smuggle in a response —
and one of the wrong sign at that. That is the same rule `ccx_migrate_par_set()` already enforced
for the lag: a name no stored field can supply is an ERROR, never a fill from a named default.

## 3. ⛔ THE PART WORTH CARRYING FORWARD: ONE NAME BECAME FOUR

`p$gamma_enso <- pv$gamma_enso` was written at **~110 sites** (70 `calibration/`, 37 `tests/`, the
rest `R/` + `app/`). After the split, every one of them assigns a field **nothing reads**, onto a
list that already carries four explicit zeros. Under any precedence rule ("split wins") each script
would have run with the ENSO response **off** and printed a number.

✅ **The fix is a REFUSAL, not a precedence rule**: `ccx_gamma_enso()` errors when a list carries
BOTH the retired scalar and any split field. It named every stale site on the first suite run — the
suite went from 6 known failures to dozens of loud ones, and each was mechanical to repair.

⇒ **STANDING: when a parameter splits, make the OLD name a hard error on a list that carries the new
ones.** A silent precedence rule converts a rename into a silent physics change.
[[intersect_is_a_silent_default]] [[recorded_but_never_restored]]

⚠ Two consequences of that guard to know about:
- `ccx_set_enso()` **drops the retired scalar off its target**. Without that, `ccx_spinup()` — which
  writes the four onto its caller's list — hands a both-names list to the very guard.
- `ccx_migrate_par_set()` drops it too, for the same reason.

## 4. ⭐ THE ISOTOPE CHOICE IS TESTED, NOT ASSERTED

`test-enso-split.R` pins the ocean term's **applied fractionation** to `aux$alpha_as_down` (and
asserts it is ≠ 1) by reading the ¹³C/C ratio of the carbon the term moves against the atmosphere's
own. If the term were emitted unfractionated, the test fails.

That is the load-bearing half of the design: land is **−0.0172 ‰ per GtC** and ocean **+0.0022 ‰**,
~8× weaker and OPPOSITE, so **δ¹³C identifies the land pair and CO₂ identifies the ocean pair by
difference**. With a generic fractionation the four collapse into two.
⚠ **Structural identifiability, NOT demonstrated precision** — that still needs a profile or Hessian
AFTER a fit. Nothing here measures it.

## 5. ⚠ THE ONE CHOICE THAT WANTS RATIFICATION — THE PRIOR

Each of the four keeps the original **N(0, 2)**, following the `seas_lag_p` precedent ("both entries
keep the ORIGINAL prior, so the split adds a degree of freedom without smuggling in a new belief").

⚠ **That is not scale-preserving on the SUM.** Two independent N(0, 2) halves imply **N(0, 2√2)** on
the land total where the scalar had N(0, 2) — the land prior is **wider by √2**. It is a WIDENING,
not a shift, and at a fitted 0.85 the prior is weak either way. **The alternative is 2/√2 on each
half**, which preserves the total exactly. Revisit if the land pair ever runs to the prior rather
than to the data. Ocean entries are centred on **0** = the incumbent model, so the prior does not
presume the mechanism exists; the measurement says each should land near **+0.137**.

## 6. ⚠ NON-OBVIOUS STATE

- ⚠ **A 25-PARAMETER REFIT IS OWED AND IT STACKS with the 22-parameter one.** Every stored mode is a
  **21-parameter** file in a 25-parameter build. `par_mode` still overlays through the legacy branch;
  `u_mode` does not decode. Warm-start from `par_mode` via `ccx_migrate_par_set()`, never by decoding
  `u_mode`. `ccx_load_mode()` refuses with exactly this text.
- ⚠ The **same 6 suite failures** as before, in the same family and saying the same true thing —
  stored modes are on an older parameter set. The count in their messages moved 22 → 25.
- ⚠ **`calibration/diag_gamma_enso_profile.R` now REFUSES with the reason.** It profiled a retired
  scalar. Its ANSWER is unchanged and is what the split was built on: more amplitude is LOUDER, not
  righter. To re-ask it, profile the LAND PAIR jointly — and note its 3.05 target was computed
  against a land-only response.
- ⚠ `diag_stream_leverage.R` now perturbs all four at their own prior sd (2.0 each), so its
  "one prior sd" column stays comparable with the rest of that table.
- ⚠ **`aux$enso_share` is gone from BOTH cores in the same commit.** A field the R side stops sending
  and the C++ still reads unpacks as garbage, not as an error.
- **Everything in `handoff_2026-08-31f` §8/§9 still stands**: the `kz` bracket is
  **[4379.1, 8109.9]**; `test-likelihood.R:578` fails deliberately; Torch is bundled and ready with
  **Marcus to submit**.

## 7. NEXT

1. **Ratify the prior choice** (§5) — it is the only open methodological decision in the change.
2. **Fit the four.** ⚠ Ship any remaining structural changes FIRST: shipping `seas_lag_p` after the
   refit already cost 14 h once.
3. **Profile or Hessian the four AFTER fitting** — identifiability is structural until measured.
4. ~~Promote the pump+conveyor carbon-closure check to a real test~~ **DONE — and the claim behind
   it was half wrong.** `tests/testthat/test-pump-conveyor.R`, 23 assertions. See §8.
5. **Cross-check the +0.119 ocean target against a genuine observation** — pCO₂ products or O₂/N₂ —
   to escape model-vs-model. Still the weakest link in the target itself.
6. Still open from 08-31f: adopt the polished mode (after the survey), and the Torch survey itself.

---

## 8. ⛔ TWO CORRECTIONS FROM THE PUMP+CONVEYOR ITEM

**The 09-01 arc §4 said "pump+conveyor had NO coverage". The premise is true and the conclusion is
not.** `test-conveyor.R` really never sets `pump_grad` — but `ccx_default_params()` ships
`pump_grad = PUMP_GRAD_OBS = 233.1094`, ON since 08-16d, so `conv_p()` has been running BOTH
mechanisms all along: the derivative-conservation test, the quiet-run drift gate, the spinup
fixed-point test and the R↔C++ parity test are already pump+conveyor tests.

⚠ **The real defect is that the coverage is INCIDENTAL** — it exists only because a default happens
to be non-zero, and that default HAS moved once (0 from the port until 08-16d). ⇒ **"never sets X"
is a statement about the TEST; "is not covered" is a statement about the DEFAULT. Read the default
before turning one into the other.**

**And the first closure gate I wrote for it was VACUOUS.** The obvious form — a closed run with no
emissions, asserting total carbon does not move — passes for the wrong reason: from an exact fixed
point under a constant forcing every box's carbon comes back **BIT-IDENTICAL** after 3300 RK4 months
(`max |dC| = 0` exactly). Measuring it is what showed that. The shipped gate is **DRIVEN** (1 GtC/yr,
43 GtC through the boxes, closes to **1.0e−10 GtC** over 274 yr), its tolerance comes from the
roundoff arithmetic (floor ≈ 4.8e−10, gate at 1e−8), and **its power is asserted**: a 1e−6 GtC
misstatement of the input must trip it.

What is now covered that was not, even incidentally: an EXPLICIT pin on both mechanisms, the
**DIC-limited** pump with the conveyor on — the corner where the pump's export reads the mixed-layer
carbon the conveyor is moving, i.e. the only place the two genuinely interact — and integrated
closure.
