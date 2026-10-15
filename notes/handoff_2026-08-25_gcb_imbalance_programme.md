# Handoff — CarbonCycleEmulator, 2026-08-25: the GCB budget imbalance as the successor program

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `1e11a23`.
**Tests:** 1028 pass, 2 fail — both the **pre-existing by-design** `test-fluxes.R:99/100`.
**One refit RUNNING** — `calibration/output/luc_arm_pin2/`, ~6 h, pre-registered. §3.

**Read with:** `handoff_2026-08-24b_plateau_leverage_settled.md` (the arc this succeeds),
`prereg_2026-08-24c_luc_arm_persistence_vs_isotopes.md`, `prereg_2026-08-25_p3_sigma_pin.md`.

---

## 0. STATE IN NINE LINES

1. **`ocean_deep` NEVER HAD TO BE BUILT** — the existing `luc` arm already carries `foss`'s
   persistence with `ocean`-scale isotopes. §1. No vertical profile was ever chosen.
2. Its refit landed: **Δ`rep_dC` = −5.014 σ**, P1 predicted **at the edge** of its own threshold. §2.
3. **P3 FIRED** (`sigma_d14c` +1.671 σ vs a 1.5 falsifier), so §2's headline is **caveated, not
   clean**, by the pre-registration's own terms.
4. **The cheap contamination tests are VACUOUS and that is MEASURED.** `rep_dC` and `sigma_d14c`
   share no likelihood term; the fixed-state null is worth nothing. §3. A pinned refit is running.
5. **FACE answers a better question than the one asked.** It cannot supply a marginal prior for
   `beta_max` — but it puts a **ceiling on `fert_k` at ~1374–1400**, and the probes sit at 1738/1784. §4.
6. **`beta_max` is not the identified object.** The uniform prior is not merely uninformative. §4.
7. **THE SUCCESSOR PROGRAM IS THE GCB IMBALANCE, AND IT IS AN INPUT PROBLEM.** §5–§7.
8. The imbalance integrates to **37.8 ppm** over 1850–2024, **56 % of it before 1959** — and it is
   **scored nowhere**. §5.
9. Still no posterior. Objective unchanged. All sink switches still default OFF.

---

## 1. `ocean_deep` IS NOT NEEDED — the `luc` arm already is it

08-24b §8 item 1 blocked on choosing `ocean_deep`'s vertical profile. It never had to be chosen.
From 08-24a's numbers, already on disk, all at rate 2.5:

| arm | window-end ΔCO₂ | fraction left 1960 / 2024 | Δ¹⁴C excursion 1941–50 NH |
|---|---|---|---|
| `foss` | −6.512 ppm | 0.736 / **0.432** | **+9.72 ‰** |
| **`luc`** | **−6.531** | 0.745 / **0.501** | **+0.170 ‰** |
| `ocean` | −1.762 | 0.181 / **0.027** | −0.122 ‰ |

`luc` matches `foss`'s window-end CO₂ to **0.3 %**, is *more* persistent at 2024, and its ¹⁴C
excursion is **1.75 %** of `foss`'s. That is verbatim the spec written for `ocean_deep`.
**[[bracket_needs_no_new_run]] firing a second time on this arc: table the arms you already have
before building arm N+1.**

Running it required lifting the `luc_scale` column-multiply **refusal**. The builder applies the
arm *after* `luc_scale`, so the columns are **affine** (`s·L − S`). The refusal said the correction
depends on caller intent; the builder had already **documented** that intent, so it was on record,
not unknown. `.ccx_make_luc_scaler()` composes the closed form exactly, constant-time,
bit-identical with the arm off, and **refuses a base built with the arm off**. Gated to 1e-12 and
mutation-tested both ways.

**Provenance gate:** warm-start logpost **predicted −2691.2, measured −2691.2**.

## 2. THE RESULT, AND ITS CAVEAT

| | predicted | measured | |
|---|---|---|---|
| **P1** Δ`rep_dC` | ≤ −5.0 σ | **−5.014 σ** (5.566 → 4.346) | predicted, **at the edge** |
| **P2** exchange rate | [−8, −5] σ | −5.014 | holds, on the boundary |
| **P3** `sigma_d14c` | ≤ 0.5 σ, falsifier > 1.5 | **+1.671 σ** | **FALSIFIED** |
| **P4** ridge | ≥ +1.0 σ each | **+9.16 / +7.44 σ** | holds, far beyond |
| **P5** `co2_icecore` | stays positive | **+28.22**, largest single gain | holds |

**P1 landing within 0.014 σ of its own threshold is not a decisive pass** and must not be quoted as
one. Persistence is *supported* — −5.014 σ against `ocean`'s +0.18 — but P3 fired, and the
pre-registration's own consequence is that the read is caveated pending §3.

## 3. P3: THE CHEAP TESTS HAVE NO POWER, MEASURED

`calibration/diag_p3_sigma_d14c_contamination.R`.

- **T1 structural.** `rep_dC` enters the CO₂ and δ¹³C **station** terms only (`likelihood.R:1105,
  1251`); `sigma_d14c` enters the Δ¹⁴C terms only. ρ = **−0.146** (reference) / −0.285 (arm).
  `rep_dC`'s real partners are **`k_w` −0.784** and **`bomb_total` −0.731**, which moved **+5.685**
  and **+4.522 σ**.
- **T3 fixed-state — VACUOUS.** Resetting `sigma_d14c` moves the 1-D `rep_dC` argmax by **exactly
  0.000 ppm**, in both arms. Treated as a code path until disproven, then **mutation-tested**:
  across `sigma_d14c` ∈ {2, 6.13, 7.22, 20, 60} the argmax is **bit-identical to 6 decimals** while
  the peak moves **~200 log-units**. Genuine additive separability. **T3 could never have detected
  contamination**, so its null means nothing — record the *power*, not just the result.
- **T2 covariance-predicted — HAS power.** Conditioning the reference Gaussian on the other 20
  moves predicts **−9.227 σ**; measured **−5.014**; unexplained residual **+4.213 σ**. So the move
  is **not** a pure slide — but T2 cannot separate "the arm did work" from "the arm resisted the slide".

> **The diagnostic caught itself.** Its first draft called `rep_dC`'s prior "flat over this range".
> It is not — **9.4 log-units** across the scanned interval — and the likelihood-only argmax sat
> **0.76 ppm above** the 21-D mode. `profile_beats_optimum` in miniature: a profile disagreeing
> with the optimum usually means the profile is scoring a different object.

**RUNNING:** `calibration/output/luc_arm_pin2/` — identical to `luc_arm_pinluc` **plus**
`sigma_d14c` pinned at the reference 6.125078. Both pins gated and bound (warm start −2682.3).
Predictions in `notes/prereg_2026-08-25_p3_sigma_pin.md`; **P1′: Δ`rep_dC` stays ≤ −3.5 σ,
falsifier > −2.0 σ ⇒ withdraw 08-24c's headline rather than caveat it.**

**The pin is now general:** `CCX_PIN_PARAMS="name=value,..."`. `CCX_PIN_LUC_SCALE` unchanged, so
every existing run reproduces. The near-delta is **lognormal**, so a non-log parameter **errors**
rather than being pinned with the wrong family.

## 4. `beta_max`: FACE CANNOT GIVE IT A PRIOR, AND GIVES SOMETHING BETTER

`calibration/diag_face_prior_for_beta_max.R`. Marcus asked for a FACE-based prior for `beta_max`.

**The evidence, with vintages** (recency is a tie-breaker, not an override):

| source | value | scope |
|---|---|---|
| Norby et al. **2005** PNAS | **+23 %** NPP | 4 **young** temperate plantations |
| Norby & Zak **2011** AREES | setpoints "typically 550–580 ppm" | — |
| Norby et al. **2025** New Phyt (`10.1111/nph.70162`) | **+21.8 %** at **+41 %** enrichment | now incl. 2 **mature** sites |
| — EucFACE (mature, P-limited) | **negligible** | the standing biosphere |
| — BIFoR-FACE (mature *Quercus*) | **+10 %** | "considerably less than … 23 %" |

**The literature does not hand over one number.** Its headline is plantation-weighted and its two
mature-forest sites are its two smallest responses. Collapsing to 21.8 % would be
[[ratio_needs_its_base]] in another costume.

**WHY A MARGINAL PRIOR ON `beta_max` CANNOT WORK.** Under the MM form the FACE observable is
`R(a,e) = (1+enh(e))/(1+enh(a)) − 1`. The same target is met at `beta_max` values differing
**several-fold** as `fert_k` moves (e.g. +21.8 % is met at `beta_max` 1.71 at K = 120, 1.69 at
K = 555, 2.36 at K = 1000). **`beta_max` is not the identified object**, so the evidence has to
enter as a term in `R`, i.e. a **joint** constraint on the pair.

**WHAT IT DOES BUY — a ceiling on `fert_k`.** `R` is **not monotone** in `fert_k`: it peaks at
K ≈ 320–380 and falls away (low K saturates the increment, high K inflates the ambient
denominator). So a high-K cell has a **maximum achievable** FACE response even at `beta_max` = 3:

| `fert_k` | max R at `beta_max` = 3 (ambient 400→564) | reaches 21.8 %? |
|---|---|---|
| 555 | 31.0 % | yes |
| 1000 | 25.6 % | yes |
| 1500 | 20.7 % | **NO** |
| 1784 | 18.6 % | **NO** |

**`fert_k` above ~1374 (ambient 400) / ~1400 (ambient 376) cannot reproduce the 21.8 % synthesis at
ANY `beta_max` in [0, 3]. The pinned probes sit at 1738 and 1784** — i.e. **FACE refutes the corner
the probes run to, and it does so through `fert_k`, not `beta_max`.** The result is robust to the
ambient choice (2 % apart), which is stated rather than silently resolved.

The adopted mode's **13.6 %** sits between the mature end (0–10 %) and the plantation synthesis —
a defensible place for a **global-mean** parameter.

> **WHAT IT DOES NOT SAY.** FACE is temperate **forest** NPP; `beta_max` multiplies **global** NPP
> including grasslands, croplands and the tropics, where **no forest FACE experiment exists**.
> FACE is a step change over years; `beta_max` is an equilibrium asymptote. This is a **prior**,
> not a measurement, and the mapping assumes MM transfers between the two.

**OPEN FOR MARCUS, and it is a methodological choice I have not made:** whether to (a) add a FACE
**likelihood term** on `R(a,e)` with a σ wide enough to span mature-vs-plantation, (b) narrow the
`fert_k` **bound** to ~1400 on the FACE argument and leave the priors uniform, or (c) leave both
alone and simply **report** that the probes' corner is FACE-refuted. (b) is the cheapest and (a) is
the most honest; (c) changes no result but leaves the escape route open.

---

## 5. THE SUCCESSOR PROGRAM: GCB'S OWN BUDGET IMBALANCE

**This is where `rep_dC` work goes, and it is an INPUT problem, not a calibration one.**

GCB 2025 publishes an `imbalance` column its own header calls *"a measure of our imperfect data and
understanding of the contemporary carbon cycle"*. Measured from `data/gcb_budget.rds$historical`
(reproduces [[ccx_swing_not_carbon]] exactly):

| decade | imbalance, GtC/yr | | cumulative to | GtC | **ppm** |
|---|---|---|---|---|---|
| 1900s | +0.188 | | 1900 | 3.03 | 1.43 |
| 1920s | +0.451 | | 1930 | 11.26 | 5.30 |
| 1930s | +0.576 | | 1942 | 20.03 | 9.43 |
| **1940s** | **+1.304** | | 1950 | 30.27 | 14.25 |
| **1950s** | **+1.624** | | **1958** | **44.66** | **21.03** |
| 1960s | +0.931 | | 1980 | 60.80 | 28.63 |
| 2010s | +0.429 | | 2000 | 70.57 | 33.22 |
| 2020s | **−0.072** | | **2024** | **80.29** | **37.80** |

**Three facts that set the program:**

1. **It integrates to 37.8 ppm, and 56 % of that lands before 1959.** `rep_dC` at the mode is
   **5.566 ppm** — **3.8× smaller** than the pre-1959 cumulative alone. The fit is absorbing a
   *fraction* of this, not the whole of it; most of it is being taken up by the model's sinks
   responding to a CO₂ level that is itself partly the imbalance's doing.
2. **It is scored NOWHERE.** `grep imbalance R/` returns two **comments**. The objective scores
   `gcb_land_sink` and `gcb_ocean_sink` from 1959 on and the CO₂ record throughout — i.e. the model
   is fitted to an emissions/sink set **that does not close**, with no term acknowledging the gap.
3. **It does NOT explain the modern land-sink miss.** 2015–24 mean is **+0.0164 GtC/yr**. So gate 7
   (land +2.04 σ) is a *different* problem and must not be folded into this one.

**AND THE BIGGEST CAVEAT, WHICH IS IN GCB'S OWN HEADER AND HAS NEVER BEEN PRICED HERE.** The
historical-budget sheet states: *"The methods used to estimate the historical fluxes presented
below differ from the carbon budget presented from 1959 onwards … the atmospheric growth and ocean
sink do not account for year-to-year variability before 1959."* Pre-1959 atmospheric growth is
**Joos & Spahni 2008**; the pre-1959 ocean sink is the mean of **two diagnostic models** (DeVries
2014, Khatiwala 2013); the land sink is a **22-DGVM mean adjusted for land-cover bias**.

> **So 56 % of the cumulative imbalance sits in an era whose budget is built by a DIFFERENT method
> from the era we score the sinks in. A methodological seam at 1959 would produce exactly this
> shape.** Before attributing the century drift to "GCB's data error", the seam has to be
> separated from the error — this is [[like_for_like_forcing]] and "read the producer before
> indicting the product" applied to an input rather than to one of our own files.

## 6. THE PROGRAM, IN THE ORDER IT SHOULD RUN

**Nothing here needs a refit until step 4**, which is deliberate: the plateau arc spent six refits
to learn something four at-mode measurements could have ranked first.

- **G1 — SEPARATE THE SEAM FROM THE ERROR (at-mode, hours).** The 1959 methodology change is a
  candidate generator of the whole shape. Test: fit the imbalance's own trend **separately** on
  1850–1958 and 1959–2024 and test for a step at the seam; and compare GCB's pre-1959 atmospheric
  growth (Joos & Spahni 2008) against the Law Dome/firn record **we already score**. If the
  pre-1959 imbalance is largely a seam artifact, the century drift's input explanation shrinks by
  more than half and the program changes shape immediately. **Run this first.**
- **G2 — PRICE THE TRANSFER, DON'T ASSUME IT.** [[ccx_swing_not_carbon]] establishes
  r = 0.771 / slope 0.781 on **growth rates**. The quantity `rep_dC` absorbs is a **level**. The
  transfer from a GtC/yr imbalance to an atmospheric ppm offset is **damped by the sinks' response**
  and is not the naive `cum/2.124` used in §5's table. Measure it: run the model with emissions
  perturbed by the imbalance series and read the CO₂ **level** response. §5's ppm column is an
  **upper bound**, and is labeled as one.
- **G3 — DECIDE WHOSE ERROR IT IS, WITH THE ISOTOPES.** The imbalance is a residual: it could be
  emissions too high, sinks too low, or growth too low. **These have different δ¹³C signatures** and
  the isotopes already discriminated once on this arc (the 5.1 σ terrestrial rejection). Reuse the
  three-arm machinery — it now runs any of `foss`/`luc`/`ocean` at any rate over any window and the
  `luc` arm's affine path is exact.
- **G4 — ONLY THEN, A REFIT**, with `luc_scale` **and** `sigma_d14c` **and** (per §4) the `fert_k`
  ceiling in place, so all three known escape routes are closed and the arm tests what it claims.

**DO NOT** re-run the plateau arms; **do not** attribute `rep_dC` to the plateau; **do not** quote
12.7 σ (it is ~5.1); **do not** ship `ocean_probe_scan/`, `pump_arms_SINK25*`, `luc_arm_pin*`.

## 7. OPEN FOR MARCUS

1. **§4's FACE choice** — likelihood term, narrowed bound, or report-only. I have not made it.
2. **Pinning `beta_max`/`fert_k`** — carried from 23c and 08-24b §8. §4 changes this question:
   FACE gives a *reasoned* ceiling where before there was only a hand-set implausibility bound, so
   "pinning crosses from testing the model into constraining it to an answer" is now weaker.
3. **Whether G1 outranks everything.** If the pre-1959 imbalance is mostly a methodology seam, the
   century-drift program is much smaller than §5 makes it look.

## 8. NON-OBVIOUS STATE

- **`obs$gcb` STARTS IN 1959.** The long series is `readRDS("data/gcb_budget.rds")$historical`
  (1750–2024), and its `imbalance` is **NA before 1850** — 100 of 275 rows. A bare `cumsum()`
  returns NA for every year and prints as if the data were missing. Subset on `!is.na` first.
- **The three-arm machinery reads `CCX_SINK_MODE` / `CCX_SINK_RATE` from the ENVIRONMENT**, but
  `ccx_build_forcing()` takes them as **arguments**; diagnostics pass them explicitly so the label
  cannot drift from the run.
- **`.ccx_make_luc_scaler()` REFUSES a base built with the arm off** when the arm is active — that
  failure mode would report a run as an arm it never carried.
- **Pinned arms' logposts and Laplace evidence are NOT comparable to free ones.** Read parameters
  and per-stream logL only.
- **SEED-COPY TRAP.** Every arm dir is seeded with a copy of the adopted mode, so
  `mode_fit_pumpN.rds` exists before the run starts and **is the unperturbed reference**.
  Completion keys on `pump_arms_comparison.rds`.
- Everything in 24b §9, 23c §6, 23b §5 and 24a §7 still applies.

---

## 9. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-25_gcb_imbalance_programme.md`.
>
> First: collect `calibration/output/luc_arm_pin2/` against
> `notes/prereg_2026-08-25_p3_sigma_pin.md` — **P1′ falsified means WITHDRAW 08-24c's headline**,
> not caveat it. Then **G1**: separate the 1959 methodology seam from the budget error before any
> of the rest of §6. §7 carries three decisions that are Marcus's, not mine.
