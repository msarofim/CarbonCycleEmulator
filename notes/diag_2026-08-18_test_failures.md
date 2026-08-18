# DIAGNOSIS — the 4 test failures (job B), 2026-08-18

**Suite baseline MEASURED, not inherited: `FAIL 4 | WARN 53 | SKIP 2 | PASS 857`** on `main` at
`ea06f1f`. (Last recorded count was 855 pass at 16e.)

**VERDICT: no code bug in any of the four.** Three mis-specified bars, one stale test premise. Every bar below was *derived* against the
protocol it should have been stated at — none was re-baselined to wherever the code lands.

**Nothing was changed.** No test edited, no bar moved, no source touched. §5 is what needs deciding.

---

## How the bars were adjudicated — the Joos re-measurement

> **FRAMING CORRECTED 2026-08-18 (Marcus).** This section is the EVIDENCE that the failing tests'
> numbers are right. An earlier draft promoted it to "a REAL under-gated model bias", which the
> ratios do not support: on the **integrated** IRF the model is **12.7 / 15.5 / 20.0 % low and inside
> all three of Joos's 5–95 % bands** — for a box model tuned only to the historical record, agreeing
> with a 15-model ensemble that closely is a **good result**, not a defect. Marcus: *"matching Joos
> within 25 % at each probability threshold is pretty good."* **Item 6 below is RETRACTED.**

**The model is genuinely on the low-airborne-fraction side, and gate 12 cannot see how far.**
Re-measured `calibration/diag_joos_irf.R` (Joos et al. 2013 PD100 protocol, 100 GtC onto a background
**held** at 389 ppm):

| horizon | this model | Joos Table 5 point | diff |
|---|---|---|---|
| 20 yr | 0.520 | 0.596 | **−0.077** |
| 50 yr | 0.378 | 0.487 | **−0.109** |
| 100 yr | **0.292** | 0.409 | **−0.117** |
| 300 yr | 0.207 | 0.322 | −0.115 |

**Low at every horizon.** The time-integrated IRF *passes* gate 12 — 12.4 / 25.6 / 41.9 yr, inside
Joos Table 4's **5–95 %** bands — but sits near the floor at every one (best estimates 14.2 / 30.3 /
52.4; the TH100 floor is 39.5 and the model reads 41.9).

**AND THE PART THE GATE DOES NOT CHECK.** Joos §4.4.1 gives integrated IRF at TH100 of **34–47 yr on
a preindustrial background** and **45–62 on present-day**. The model:

| background | model int IRF@100 | Joos range | verdict |
|---|---|---|---|
| preindustrial | **25.6** | 34–47 | **BELOW the range** |
| present-day | **44.7** | 45–62 | marginally below |

**Gate 12's secondary check is scoped to the ORDERING only** ("the model must reproduce the PI < PD
ordering"), which the model satisfies (25.6 < 44.7). The PI value is **24.7 % below the floor of its
range** — at the boundary of the same ~25 % tolerance, not clearly outside it. DESIGN already says
"the model remains on the low side of the literature", and **that prose is the right home for this,
not a new gate.**

**PREDICTION SCORING — I got both halves WRONG, and said so before looking.** I predicted the pump
(shipped 08-16e, after gate 12's status line was last measured 08-14) would have lowered the integrated
IRF, possibly below the 39.5 floor. **It reproduced 12.4 / 25.6 / 41.9 exactly — the line is NOT
stale.** I also predicted PD100 af(100) ≈ 0.33–0.36; measured **0.292**, below my range.

---

## 1. `test-pulse.R:113` — af(100) = 0.213 vs bar > 0.30 — **BAR MIS-SPECIFIED**

The test's own comment convicts it: *"Recalled Joos et al. (2013) multi-model values … roughly 0.59 /
0.47 / 0.41 at 20 / 50 / 100 yr — **NOT verified against the paper**."* Those are **PD100** values
(background held at 389 ppm). The test measures on **SSP1-1.9**, a declining background.

Derived from the model's own diagnostic, §5 of `diag_joos_irf.R`:

| background | IRF@100 |
|---|---|
| PD, held | 0.297 |
| PD, decaying | 0.244 |
| ssp126 (2050 pulse) | 0.267 |
| PI, held | 0.152 |

**0.213 on ssp119 sits exactly where a background below ssp126 belongs.** Not a code defect.

## 2. `test-luc-permanence.R:88` — `af_foss` = 0.151 vs bar > 0.2 — **BAR MIS-SPECIFIED, and the match is exact**

`lp_background()` is a **zero-emission, GMST- and ENSO-frozen** control — i.e. a **preindustrial**
background. `LP_PULSE` = 100 GtC, `LP_LAG` = 100 yr: the Joos pulse shape, on the PI background.

**`diag_joos_irf.R` says "PI, background HELD" IRF@100 = 0.152. The test measures 0.151.**
Agreement to 0.001, from an independent diagnostic. The bar ">0.2" is a present-day expectation
applied to a preindustrial measurement. Not a code defect.

## 3. `test-mechanisms.R:32` — ENSO moves CO₂ 0.30 ppm at 2100 vs bar > 0.5 — **WRONG STATISTIC**

The test is a **wiring** test ("every switch is wired up and changes the answer") and applies one
endpoint bar to all six mechanisms. Measured |Δ CO₂| vs base:

| switch | @2100 | max over series | year of max |
|---|---|---|---|
| emissions | 212.158 | 225.341 | 2083 |
| fertilisation | 200.496 | 201.185 | 2101 |
| ocean_sink | 116.054 | 116.211 | 2100 |
| revelle | 33.986 | 34.107 | 2100 |
| warming_feedback | 18.103 | 18.140 | 2100 |
| **enso** | **0.300** | **0.537** | **2032** |

**Five mechanisms are monotone and cumulative — max ≈ endpoint, and they clear the bar by 36–450×.
ENSO is the only OSCILLATORY one**, so its endpoint reads the *phase at 2100*, not whether it is
wired. Its max is 0.537, above the bar. **ENSO is wired; the endpoint is the wrong statistic for it.**
Not a code defect.

## 4. `test-luc-permanence.R:104` — |af| = 0.074 vs bar < 0.02 — **STALE TEST PREMISE (+ a real stale comment)**

The test asserts `f_luc_perm = 0` reproduces the pre-2026-08-13 behaviour (recorded signature:
0.072 @50 → 0.002 @100 → −0.003 @150). It sets **one** knob. Reproducing that model needs **two**:

| `f_luc_perm` | `f_luc_wood` | af@50 | af@100 | af@150 | |
|---|---|---|---|---|---|
| 1 | 0 | 0.1996 | 0.1561 | 0.1353 | shipped default |
| 0 | 0 | 0.1171 | **0.0744** | 0.0542 | **what the test sets** |
| 1 | 1 | 0.0977 | 0.0745 | 0.0754 | |
| **0** | **1** | 0.0187 | **−0.0032** | **−0.0026** | **the full pre-08-13 config** |

**With both knobs the recorded signature reproduces** (−0.0032 @100, −0.0026 @150 vs the recorded
0.002 / −0.003) **and the bar passes.** `CCX_F_LUC_WOOD_DEFAULT` was flipped 1 → 0 after this test was
written and the test was never updated. **16f's triage — "a case needing `f_luc_wood = 1`" — was
RIGHT; nobody acted on it.**

**REAL DEFECT FOUND ALONGSIDE (minor, but in a load-bearing place).** `R/cpp.R:104-105` reads:

> *"WHERE the debit comes from. Unlike `f_luc_perm` this default IS the old behaviour, because
> `f_luc_wood` = 1 is the incumbent decision, not a bug."*

**`R/model.R:159` sets `CCX_F_LUC_WOOD_DEFAULT <- 0`.** The comment asserts a default the code does
not have — **in the exact block whose stated purpose is preventing the R and C++ cores from silently
running different models** ("which is exactly what `gamma_enso` did"). Behaviour is fine (both sides
read the same constant); the comment is stale and actively misleading.

---

## 5. What needs deciding — NOTHING WAS CHANGED

Per `~/.claude/CLAUDE.md`: *"If a previously passing test fails, do not modify or skip the test to
make it pass — report the failure and stop."* These were already failing, and the repairs below are
**derivations, not re-baselines** — but they still edit tests, so they wait for Marcus.

1. **`test-pulse.R:113`** — restate against the background actually used, or move the test to the
   PD100 protocol where Joos's numbers apply. **Do not simply lower 0.30.**
2. **`test-luc-permanence.R:88`** — restate the bar as a **preindustrial** expectation (the model's
   own PI IRF@100 is 0.152). **Do not simply lower 0.2.**
3. **`test-mechanisms.R:32`** — assert wiring on `max|Δ|` over the series (or RMS), not the endpoint.
   A wiring test should ask "≠ 0", not "big at one year".
4. **`test-luc-permanence.R:104`** — set `f_luc_wood = 1` alongside `f_luc_perm = 0`. One line.
5. **`R/cpp.R:104-105`** — correct the stale comment to match `CCX_F_LUC_WOOD_DEFAULT = 0`.
6. ~~Decide whether gate 12 gains a level check on Joos §4.4.1.~~ **RETRACTED 2026-08-18 (Marcus).**
   Scoring the integrated IRF against a 5–95 % band is a reasonable scope for this model, and a level
   check would manufacture a failure out of agreement that is decent. **Repairs 1–5 are unaffected** —
   they rest on wrong background, wrong statistic, a premise needing two knobs, and a stale comment.
