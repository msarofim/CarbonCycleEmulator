# Handoff — CarbonCycleEmulator, 2026-08-13 (i)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
at **`ea7c70b`** (still **not merged**; tagged `checkpoint/pre-phase1-2026-08-13` at the
pre-session state). Suite **10 fail** — up from 2, all of the new ones caused deliberately
by fixture changes and **left failing on purpose**; see §4 and **the ADDENDUM's §A1, which
corrects §4's count from six to ten and is the more important half of this note**.

**This works handoff 13h's PHASE 1 and stops where 13h says it must stop.** Every
blocking item is now MEASURED. **Nothing in PHASE 2 has been started, and it should not
be until §5's decisions land.** 13h §§3–4 stand unchanged as the plan for what comes next.

---

## 0. START HERE

1. **PHASE 1 is measured, not decided.** Four of the five decisions in 13h §5 now have
   numbers attached. The decisions are still Marcus'.
2. **Two of 13h's own claims are withdrawn on measurement** (§1, §3). Neither was a
   careless claim; both were measured against a stale `beta` default, and re-measuring
   them like-for-like reverses one of them.
3. **A NEW structural misfit was found, and it is not the δ¹³C one** (§2). The CO₂ record
   and GCB's sink partition want different `beta`s, ~20–30 ppm apart, and **the LUC debit
   choice does not relieve it.**
4. **A units trap was live in a shipped diagnostic** and I walked into it before the
   CHANGELOG's own record of it caught me (`cc3abd5`). Any land-sink number written
   before that commit is suspect — check whether it is net or gross.
5. **The refit is still blocked**, and by the same three items 13h named. None of them is
   the one-line change 13h expected.

---

## 1. WITHDRAWN: "the fix makes δ¹³C 7.1 % worse"

13h §2.2d says the converted-land term moves the 1900→2020 Suess decline
−2.209 → −2.366 ‰ on a model already ~25 % too fast, and asks for the ocean decisions to
be re-taken on that basis. **That comparison holds `beta` fixed at 0.38 across a change
that moved the CO₂-consistent `beta`, so it is confounded.**

Like for like — each model at **its own** CO₂-consistent β — the 2015-2024 MLO δ¹³C bias:

| | β where CO₂ bias = 0 | δ¹³C bias there |
|---|---|---|
| pre-`404d66d` | 0.358 | **+0.580 ‰** |
| post (shipped) | 0.591 | **+0.529 ‰** |

**The converted-land term improved the δ¹³C misfit by 0.05 ‰.** And the ocean was never at
risk from it at all: `diag_conveyor.R`'s deep-Δ¹⁴C columns are **bit-identical** across the
fix at every `kz` and every `q_conv` tested.

Re-measured at the re-centered default (β 0.60), the ocean picture is **better than 13c
recorded**, not worse:

| | at β 0.38 (stale) | at β 0.60 (shipped) | obs |
|---|---|---|---|
| mixed-layer Suess rate | 0.171 (+0.5 sd) | **0.153 (−0.4 sd)** | Quay 0.160 ± 0.020 |
| atmospheric Suess rate | 0.294 (+30 %) | **0.267 (+18 %)** | Law Dome 0.226 |
| δ¹³C bias MLO | +0.784 | **+0.519** | 0 |
| MLO−SPO δ¹³C gradient | −0.208 | −0.210 | −0.074 |

13c §3's headline — "the mixed layer is right, the atmosphere is 21–25 % too fast" —
becomes **the mixed layer is right and the atmosphere is 18 % too fast**. The direction
survives; the size shrinks.

---

## 2. NEW, AND THE BIGGEST THING IN THIS SESSION: CO₂ level vs the GCB budget

`diag_luc_prorata.R` §5. Scanning (β, debit) against the CO₂ record and against GCB's
budget, 2015-2024 gross land sink **2.36** and ocean **3.22** GtC/yr:

| debit | β | CO₂ bias | cum land 1750-2024 | gross land sink | ocean sink |
|---|---|---|---|---|---|
| wood only | 0.38 | −20.0 ppm | −52.2 (GCB −57.4) | 2.74 | 2.87 |
| wood only | **0.60** | **+0.8 ppm** | **+21.7** | **3.99 (+69 %)** | 2.52 (−22 %) |
| pro rata | 0.38 | −35.0 ppm | −108.8 | 2.36 | 3.00 |
| pro rata | 0.70 | −1.0 ppm | +11.1 | 4.31 | 2.45 |

**Matching GCB's cumulative land costs ~21 ppm of CO₂ bias under BOTH debits.** The debit
choice moves where β sits on that line; it does not relieve the line. So this is a second
structural misfit, independent of the isotopes and independent of the LUC decision.

**Its size is explained rather than hand-waved.** The model closes its own budget exactly
(E_foss 504.7 = Δatm 303.8 + Δland 21.7 + Δocean 178.3, residual 0.9 GtC) while **GCB's own
table carries a +35.6 GtC cumulative imbalance over 1959-2024 alone**. A model that closes
has to put that carbon somewhere, and it puts it in the land.

**PROVENANCE FLAG.** The −57.4 / +209.8 GtC GCB figures are carried from `404d66d`'s commit
message and **cannot be recomputed from the repo** — `data/obs_gcb.rds` starts in 1959.
By project rule 2/3 they need a source before anything leans on them harder than this.

**This is the residual PHASE 3 is aimed at** (13h §4.2 predicted land-too-strong /
ocean-too-weak at the slice optimum; it is now confirmed at the default parameter set,
and larger than 13h's numbers because those were the net-vs-gross trap).

---

## 3. The three PHASE 1 blockers, measured

### 3.1 `beta` re-centered 0.38 → 0.60 — DONE (`9200bc2`, `cc3abd5`)

Not one criterion's answer; four agree to within 0.02 (`diag_recentre_beta.R`):

| criterion | β |
|---|---|
| zero of the 2015-2024 MLO CO₂ bias | 0.591 |
| CO₂ stream's own 1-D optimum | 0.597–0.599 |
| full 1-D log-posterior at `mode_fit`'s σ | 0.597 |
| full 1-D log-posterior at the table's σ | 0.617 |

That last row is the useful one: **the answer moves by less than the grid when `sigma_d13c`
moves 0.44 → 0.10**, so the default could be set while §3.3 is still open. 13h's "0.50"
was a coarse-grid point at the mode's other parameters; it is superseded, not contradicted.

### 3.2 The LUC debit — MEASURED, still Marcus' (`b3108d7`)

`f_luc_wood` added to both cores as a switch, default 1 = the shipped wood-only behavior,
bit-identical, with a parity gate on the new branch.

| LUC airborne fraction ÷ fossil's | 50 yr | 100 yr | 150 yr | 200 yr |
|---|---|---|---|---|
| wood only (shipped) | 0.549 | 0.496 | 0.569 | 0.647 |
| **pro rata** | **1.025** | **1.024** | **1.023** | **1.024** |

Pro rata closes it at every horizon. Pool equilibrium shares: leaf 1.7 %, wood 22.5 %,
soil_fast 5.4 %, **soil_slow 70.4 %**.

**What it costs** — the emitted carbon stops carrying wood's ¹⁴C:

| | wood-only debit Δ¹⁴C | pro-rata debit Δ¹⁴C |
|---|---|---|
| 1900 | −4.2 ‰ | −40.9 ‰ |
| 2024 | **+57.1 ‰** | **−10.1 ‰** |

In the bomb era it flips from bomb-**enriched** to depleted. δ¹³C moves +0.6 to +1.9 ‰.

**Correction to 13h §2.1b and to `404d66d`'s message:** the debit does not land on
"wood (37 yr)". `tau_wood` is **20 yr**; 35.5 yr is `land0/npp0`, the whole land's bulk
turnover. The two were conflated. The "70 % in a 500-yr pool" half of the argument is right.

### 3.3 `sigma_d13c` — still open, now with the kz interaction priced

13h §2.1c measured δ¹³C to be nearly inert for the LAND parameters at 0.44 ‰. Two things
to add:

- On the re-centered model it is nearly inert for **β** too: the 1-D β optimum moves 0.597
  → 0.617 between σ 0.44 and σ 0.10.
- But it is **NOT** inert for `kz`. δ¹³C is the one stream that pulls `kz` upward,
  monotonically to 16,000, and how hard it pulls is set entirely by σ. So the σ decision
  and the `kz` decision are coupled, which was not previously stated.

### 3.4 The `kz` bracket — 13h §2.1a's REASON does not survive (`5743ef2`)

13h §2.1a says delete `[3830, 6200]` because it is "conditional on the pure-diffusion
column it was bisected on". **PHASE 2 is conveyor-OFF, i.e. that exact column** — which is
the same fact 13h §3.2 uses to argue the deep-Δ¹⁴C target is not blocking here. Both
sections cannot be right about the same column.

What survives is 12d §8's different reason — the bound leaks — and **its prescription is a
likelihood term, not a bare deletion**. Measured on the current model:

1. **The bracket has not moved.** Re-bisected: Δ¹⁴C −200 at kz **3828.9**, −150 at
   **6201.0**, against the incumbent [3830, 6200]. Neither `404d66d` nor the β re-centering
   touched it.
2. **The leak is +7.0 to +8.1 ‰**, uniform over kz 1000–10686. At the hi bound the deep
   ocean is −150.0 at the defaults and −142.7 at `mode_fit`'s vector; the bracket
   re-bisects to [3601, 5703] there. It is a property of (model, parameter vector).
3. **The bound is not binding.** The 1-D log-posterior in kz has an **interior maximum at
   kz = 5000** — the bracket's own init and center — under **both** candidate σ_d13c.
   CO₂ alone peaks there too. Only δ¹³C pulls up, and it is outvoted in both σ sets.
   *Stated with its limit:* 12d's runaway to 10,686 was a 16-parameter conditional optimum
   on the pre-`404d66d` model at β 0.088. A 1-D profile cannot rule that out.
4. **Bare deletion is priced:** on today's model kz = 10,686 gives deep Δ¹⁴C **−112.7 ‰**.

There is still **no deep-Δ¹⁴C term in `R/likelihood.R`**, which is what 12d §§8–9 proposed
to replace the bracket with and which was never built.

---

## 4. Six failing tests, three of them new and DELIBERATELY left failing

Project rule: a newly failing test is **reported, not edited**. All three new failures are
caused by the β re-centering and each has been re-derived rather than labeled.

| test | reads | diagnosis |
|---|---|---|
| `test-likelihood.R:114/117` | `cost(+1 ppm)` = −4.7, wants > 100 | **The fixture's bias is gone, not the property.** The symmetric curvature `(cost(+1)+cost(−1))/2` is **+26.40 at BOTH β**, and `cost(+50)` = 64,439. The AR(1) loophole is still shut; the test reads it through an offset that no longer exists. Station CO₂ residuals went RMS **13.28 → 1.09 ppm**, mean −0.02. |
| `test-likelihood.R:135` | σ_co2 0.0744 now BEATS 5 | At RMS 1.09 ppm with `LIK_CO2_REP_ERR` = 1.0, the ML σ_co2 is ≈ 0.4 and **5 is no longer a "sane" comparator**. The profile argmax moved 15 → 0.2, one grid index off the bottom, so the neighboring interior-maximum assertion is fragile too. |
| `test-climate.R:121` (new) + `:122` (old) | 26.4 ppm vs > 30; 0.086 °C vs > 0.1 | **One phenomenon, not two.** Higher β damps the carbon-climate loop gain. The test header quotes ~111 ppm / ~0.3 °C, which this model has never produced — so both thresholds were always aspirational. |
| `test-mechanisms.R:32` (old) | ENSO switch moves CO₂ at 2100 by 0.20 ppm, wants > 0.5 | **Re-derived, and it is not only the statistic.** The ENSO flux is an internal soil↔atmosphere transfer, so it changes variability, not level — but the mechanism is also weak: at `gamma_enso` = 0.5 the model's 1960-2024 CO₂ growth-rate sd is **0.584 vs observed 0.712 (82 %)**; it matches at γ ≈ 1.5–2, and `mode_fit` chose **0.927**. The log-posterior is nearly flat 0.5 → 1.0 (−4028.4 vs −4030.4). |

**Not suspiciously good:** the 1.09 ppm residual is structured, not noise — a
+0.036 / +0.051 ppm/yr trend at MLO / SPO (p 3e-14 / 4e-20), a ~1.1 ppm interhemispheric
gradient error, and a 2020s low bias in both hemispheres.

---

## 5. Decisions that are Marcus', now with numbers

| | decision | the measurement it now rests on |
|---|---|---|
| 1 | **`kz`: keep the bracket / delete + add a deep-Δ¹⁴C likelihood term / delete bare** | §3.4. Bare deletion is priced at −112.7 ‰. The bracket is currently decorative in 1-D. |
| 2 | **pro-rata vs wood-only LUC debit** | §3.2. Pro rata closes the airborne fraction (0.50 → 1.02) and costs 67 ‰ of Δ¹⁴C on the emitted carbon in the bomb era. |
| 3 | **`sigma_d13c`** | §3.3. Nearly inert for β and the land; **not** inert for `kz`. |
| 4 | **whether the four failing-test re-derivations in §4 may be written** | §4. Each has its evidence; none has been edited. |
| 5 | **is the CO₂ level the right criterion for the `beta` default at all**, given §2 | §2. It costs a +69 % land sink and a −22 % ocean. |
| 6 | whether the pump ships with a return path | unchanged from 13h §4.3 |

---

## 6. Non-obvious state (additions to 13h §6)

- **`f_luc_wood` exists in both cores**, default 1 (= shipped, bit-identical), with a
  parity gate. It is NOT in `CCX_PARAM_TABLE` and nothing samples it.
- **`ccx_luc_pool_shares()` (R) and the `w4[]` block in `ccx_core.cpp` are independently
  derived from the same six land parameters.** That is deliberate — the parity test is
  what catches a disagreement — but it means a land-structure change must be checked
  against `test-parity.R`'s pro-rata case, not only the default one.
- **`ccx_default_params()$beta` is 0.60.** Every "at default parameters" number written
  before 2026-08-13 evening is at 0.38 and does not carry over. This is the second time
  a default has moved under recorded numbers (`kz` 4000 → 5000 was the first).
- **The net-vs-gross land-sink trap was live in `diag_d13c_suess.R` until `cc3abd5`.**
  Its §3 table in any older output compares the model's NET land flux to GCB's GROSS sink.
- `mode_fit.rds` is now stale in **five** ways: 13g §0.5's four, plus the β re-centering.
- New diagnostics: `diag_recentre_beta.R`, `diag_luc_prorata.R`, `diag_kz_bracket.R`.

## 7. Commits (this session)

| | |
|---|---|
| `9200bc2` | Re-center the default beta 0.38 → 0.60 on the converted-land model |
| `b3108d7` | The pro-rata land-use debit, as a switch, and what it would cost |
| `5743ef2` | diag_kz_bracket: the bracket is not binding, and 13h §2.1a's reason is not the one that survives |
| `cc3abd5` | Units: the model's land flux is NET, GCB's land_sink is GROSS — fix four sites |

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13i_phase1_measured.md`. **PHASE 1 is measured; the refit is
> still blocked on §5's decisions 1–3.** Do not start the conveyor-OFF refit until they
> land, and do not build the pump before the refit. If the decisions are in hand, §3.4
> item 3 says the `kz` bound is not binding at the defaults — but check that in the 16-D
> conditional optimum before relying on it, because 12d's runaway was 16-D. The
> pre-registered prediction in 13h §3.1 (β 0.088 → ~0.5, q10 0.169 → ~1.5) is unchanged
> and still the point of the refit; note that the 1-D CO₂-consistent β is now measured at
> **0.591**, so the prediction's "~0.5" is if anything conservative.

---

# ADDENDUM, 2026-08-14 — Marcus' decisions, and a CORRECTION to §4

## A1. CORRECTION: it was TEN failing tests at β 0.60, not six

§4 above says six. **That was a bad grep on my part** — `test-pulse.R:83, 100, 101, 113`
were in the same suite output and I did not read past the first hundred lines. The β
re-centering broke the **Pulse Lab** too, and that is the most consequential of the ten
because it is a claim the app teaches.

**`test-pulse.R:100/101` — "the airborne fraction depends on the background — Revelle
saturation". It REVERSES.** An identical 100 GtC pulse at 2050, read at 2150:

| β | ssp119 frac | ssp585 frac | hi − lo | test wants > +0.05 |
|---|---|---|---|---|
| 0.38 | 0.336 | 0.540 | **+0.204** | pass |
| 0.50 | 0.283 | 0.368 | **+0.085** | pass |
| 0.60 | 0.248 | 0.237 | **−0.011** | FAIL |
| 0.75 | 0.209 | 0.100 | **−0.109** | FAIL |

**The LUC debit is irrelevant to this** — wood-only and pro rata agree to three decimals at
every β. It is purely β.

**Mechanism, and it is a model limitation rather than a threshold problem.** `NPP = NPP0(1 +
β ln(χ/χ0))` has **no saturation**. On SSP5-8.5 the model passes 1998 ppm, where
`ln(1998/278) = 1.97`, so NPP runs at **2.48× preindustrial at β 0.75** (1.75× at 0.38).
That unsaturated land sink overwhelms the ocean's Revelle buffer and flips the sign of the
background dependence. So above β ≈ 0.53 **the Pulse Lab teaches the opposite of the lesson
it is written to teach.**

This is a real constraint on the β default that none of the four calibration criteria sees,
and it deserves to be weighed against them. Two ways out, neither taken:
- keep the default at a β where the app's claim survives (≲ 0.53), and accept a CO₂ bias;
- give the fertilization a saturating form, which is a **model-structure** change and
  therefore PHASE-3-class work, not a fixture tweak.

*A methods note on how this was nearly missed twice.* A first attempt to scan β by
monkey-patching `ccx_default_params()` and calling `test_file()` returned **byte-identical
numbers at β 0.38, 0.50, 0.55 and 0.60** — the override never reached the tests. That is
the "suspicious uniformity ≈ bug signal" rule doing its job; the standalone probe
(`probe_revelle.R`, agreeing with the test to 0.01 at β 0.75) is what the table above uses.

## A2. Decisions taken

| | decision | outcome |
|---|---|---|
| 1 | `kz` bracket | **delete + add a deep-Δ¹⁴C likelihood term** — *BLOCKED, see A3* |
| 2 | LUC debit | **delegated to me on physical realism → PRO RATA**, `f_luc_wood` default 1 → 0. Reasoning written out at `CCX_F_LUC_WOOD_DEFAULT`. |
| 3 | `sigma_d13c` | **left free**, as now. No code change. |
| 4 | the failing-test re-derivations | **none written.** All left failing. |

The pro-rata switch forced a second β re-centering: **0.60 → 0.75**, by the 1-D
log-posterior optimum (the criterion the default has always tracked). Under pro rata the
four criteria spread more than they did under wood-only — 0.712 (decade CO₂ bias) against
0.753–0.770 (the three whole-record ones) — and the default follows the cluster. **Note
this sits well above A1's ≈0.53 ceiling.**

## A3. THE kz DECISION IS BLOCKED ON PROVENANCE, and it should not be forced

The chosen option needs the `[−150, −200] ‰` deep-Δ¹⁴C target to become a likelihood term
with a central value and an error bar. **That range is uncited.** It appears once in the
repo, in `DATA.md` §5, as *"roughly −150 to −200 ‰"* — no paper, no dataset, no access
date. Project hard rule 2 forbids using an uncited value in code, and a term in the
**objective function** is a far stronger use than the bound it replaces.

**Do not delete the bracket until the term exists**, because bare deletion is the option
that was measured and rejected (kz → 10,686, deep Δ¹⁴C −112.7 ‰).

**The source to pull is GLODAPv2** — natural/pre-bomb Δ¹⁴C, volume-weighted below the
mixed layer, which gives both a central value and a real spatial spread for the σ. 13h
§4.3 already names GLODAPv2 as the pull needed for PHASE 3's deep DIC and δ¹³C targets, so
**one data-raw pull serves both**, and doing it before the refit rather than after is the
cheaper ordering.

## A4. State at the end of this addendum

- `f_luc_wood` default **0** (pro rata); `beta` default **0.75**; `CCX_PARAM_TABLE$beta$init`
  tracks it.
- `test-parity.R:57` was **my own bug** — it compared the pro-rata derivative against
  `pf$p`, which became the same thing when the default flipped. Fixed to compare against an
  explicit `f_luc_wood = 1`. That is a correction to a test written this session, not a
  weakening of an inherited one.
- `test-luc-permanence.R:104` (`f_luc_perm = 0 reproduces the pre-2026-08-13 behaviour`)
  now fails: reproducing that behavior needs **both** `f_luc_perm = 0` **and**
  `f_luc_wood = 1`, and the test only sets the first. Left failing, per decision 4 —
  but it is a one-line fixture correction whenever that decision is revisited.
- `test-luc-permanence.R:88` fails at 0.189 against a > 0.2 threshold on the FOSSIL
  reference arm — i.e. the gate's own control, moved by β, not by the debit.

## A5. Final suite state (10 fail), and what each is

```
test-climate.R:121, :122        carbon-climate loop gain, weakened further by beta 0.75
test-likelihood.R:114           CO2-bias cost, fixture-dependent (curvature unchanged)
test-luc-permanence.R:88        the FOSSIL reference arm, 0.189 vs > 0.2 -- moved by beta
test-luc-permanence.R:104       needs f_luc_perm = 0 AND f_luc_wood = 1; sets only the first
test-mechanisms.R:32            ENSO switch, weak on the level and on growth-rate sd
test-pulse.R:83, :100, :101, :112   THE PULSE LAB -- see A1; :100/:101 is the reversed lesson
```

`test-likelihood.R:117` and `:135` now PASS again at beta 0.75, and `test-parity.R:57` is
fixed. Nothing else was edited.

**Reading order for whoever picks this up: A1 first.** The Pulse Lab reversal is the only
one of the ten that is a statement about the model rather than about a fixture.
